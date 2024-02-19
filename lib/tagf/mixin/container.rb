#--
# Copyright © 2022 Ken Coar
#
# Licensed under the Apache License, Version 2.0 (the "License"); you
# may not use this file except in compliance with the License.  You
# may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or
# implied.  See the License for the specific language governing
# permissions and limitations under the License.
#++
# frozen_string_literal: true

require('tagf/debugging')
warn(__FILE__) if (TAGF.debugging?(:file))
require('tagf/mixin/dtypes')
require('tagf/mixin/element')
require('tagf/mixin/universal')
require('byebug')

# @!macro doc.TAGF.module
module TAGF

  # @!macro doc.TAGF.Mixin.module
  module Mixin

    # @!macro doc.TAGF.Mixin.Container.module
    module Container

      include(Mixin::UniversalMethods)
      include(Mixin::DTypes)
      #
      # All Containers are Elements.
      #
      include(Mixin::Element)

      #
      # List of all the instance variables used by attributes supplied
      # by the Mixin::Container module.  This is used when cloning a
      # duplicate or converting to a different type of element.
      #
      INSTANCE_VARIABLES	= %i[
                        	     @allow_containers
				     @is_openable
                                     @is_open
                                     @is_transparent
                                     @inventory
                                     @capacity_items
                                     @current_items
                                     @capacity_mass
                                     @current_mass
                                     @capacity_volume
                                     @current_volume
                                     @pending_inventory
				    ]

      # @!macro TAGF.constant.Loadable_Fields
      Loadable_Fields		= [
        'allow_containers',
        'is_surface',
        'is_openable',
        'is_open',
        'is_transparent',
        'capacity_items',
        'current_items',
        'capacity_mass',
        'current_mass',
        'capacity_volume',
        'current_volume',
      ]

      #
      # Whether or not this container is permitted to have others
      # nested inside it.
      #
      # @!macro doc.TAGF.classmethod.flag.invoke
      flag(:allow_containers)

      #
      # @return [Boolean]
      #   `true` if the container's inventory has no Item, Container,
      #   or Feature elements in it.
      #
      def is_empty?(*args, **kwargs)
        args = %i[ items containers features ] if (args.empty?)
        args		= args.map { |o| o.to_sym }
        result		= 0
        args.each { |type| result += self.inventory.send(type).count }
        return result.zero? ? true : false
      end                       # def is_empty?

      #
      # Is the container a surface, like a desk or table?  If so, it's
      # always open.
      #
      # @!macro doc.TAGF.classmethod.flag.invoke
      flag(:is_surface)

      #
      # Does the container have the option of being open or closed?
      # Think about a birdcage, which would want a door to keep any
      # birds from escaping.
      #
      # @!macro doc.TAGF.classmethod.flag.invoke
      flag(is_openable: false)

      #
      # If the container is openable, is it actually open?  We
      # overrides some of the standard attribute accessors added by
      # the Mixin::ClassMethods#flag method to provide correct results
      # if the element can't even be opened.
      #
      # @!macro doc.TAGF.classmethod.flag.invoke
      # @overload is_open
      #   @return `true` or `false` if the element can be opened
      #   (#is_openable), otherwise `false`.
      # @overload is_open?
      #   @return `true` or `false` if the element can be opened
      #   (#is_openable), otherwise `false`.
      # @overload is_open!
      #   Sets the flag to `true` if the element is openable,
      #   otherwise always `false`.
      #   @return `true` or `false` if the element can be opened
      #   (#is_openable), otherwise `false`.
      # @overload is_open=(value)
      #   Sets the flag to the `truthy` (see #truthify) value of the
      #   argument, but only if the current element is openable.
      #   Otherwise, the value is always `false`.
      #   @param [Boolean] value
      #     The new setting for the attribute, either `true` or
      #     `false` according to its truthiness (see #truthify), or
      #     unconditionally `false` if the element cannot be opened
      #     (see #is_openable).
      #   @return `true` or `false` if the element can be opened
      #     (#is_openable), otherwise `false`.
      flag(is_open: false)
      def is_open
        if (self.is_surface?)
          @is_open	= true
        elsif (! self.is_openable?)
          @is_open	= false
        end
        result		= @is_open
        return result
      end                       # def is_open
      alias_method(:is_open?, :is_open)
      def is_open=(value)
        value		= truthify(value)
        #
        # @todo
        #   Need to handle trying to close an always-open surface with
        #   an exception.
        #
        if (self.is_openable?)
          @is_open	= value
        elsif (game_options?(:RaiseOnInvalidValues) && value)
          raise_exception(UnscrewingInscrutable,
                          self,
                          __method__,
                          true,
                          self,
                          :is_openable,
                          false)
        else
          value		= false
        end
        @is_open	= value
        return @is_open
      end                       # def is_open=(value)

      #
      # Can you see through the container and identify what's inside?
      # Default is `false`.
      #
      # @!macro doc.TAGF.classmethod.flag.invoke
      flag(is_transparent: false)

      # @!attribute [rw] inventory
      # Instance variable accessor for a container's inventory (list
      # of things owned or contained).
      #
      # @overload inventory
      #   @return [Inventory]
      #     the object's inventory.
      #   @return [nil]
      #     if the inventory hasn't yet been created.
      # @overload inventory=(value)
      #   @param [Inventory] value
      #     instance of Inventory class to install as the
      #     object's [new] inventory list.
      #   @raise [TypeError]
      #     `attribute 'inventory' requires an instance of class
      #     TAGF::Inventory` if the argument is not an actual instance
      #     of Inventory.
      #   @return [Inventory] object's new inventory object.
      #
      attr_reader(:inventory)
      def inventory=(value)
        unless (value.kind_of?(Inventory))
          raise_exception(TypeError,
                          format("attribute '#s' requires " \
                                 + "an instance of " \
                                 + 'class TAGF::Inventory',
                                 __method__.to_s.sub(%r!=$!, '')))
        end
        unless (@inventory.nil?)
          bt		= caller
          bt.pop
          bt.pop
          warn(format('%s <eid=%s, name="%s"> ' \
                      + 'already has an inventory, ' \
                      + "overwriting\n  %s",
                      self.class.name,
                      self.eid,
                      self.name,
                      bt.join("\n  ")))
        end
        @inventory	= value
        return @inventory
      end                       # def inventory=(value)

      #
      # Maximum number of items permitted in the container (default
      # 0).  Zero means no limit.  Items are game objects that are
      # non-static instances of {Container} or {Item}.
      #
      # @!macro doc.TAGF.classmethod.int_accessor.invoke
      int_accessor(:capacity_items)

      #
      # Count of things currently in the object's inventory.
      #
      # @!macro doc.TAGF.classmethod.int_accessor.invoke
      int_accessor(:current_items)

      #
      # @!macro doc.TAGF.classmethod.float_accessor.invoke
      float_accessor(:capacity_mass)
      
      #
      # @!macro doc.TAGF.classmethod.float_accessor.invoke
      float_accessor(:current_mass)

      #
      # @!macro doc.TAGF.classmethod.float_accessor.invoke
      float_accessor(:capacity_volume)

      #
      # @!macro doc.TAGF.classmethod.float_accessor.invoke
      float_accessor(:current_volume)

      #
      attr_reader(:pending_inventory)

      #
      # @!macro doc.TAGF.formal.kwargs
      # @return [Boolean]
      #
      def contains_item?(*args, **kwargs)
        
      end                       # def contains_item?

      #
      def update_inventory!
        if (TAGF.debugging?(:inventory))
          warn(format('Updating inventory for <%s>[%s]',
                      self.class.name,
                      self.eid.to_s))
          if (self.pending_inventory.empty?)
            warn(format('No pending inventory updates for <%s>[%s]',
                        self.class.name,
                        self.eid.to_s))
            return self.inventory
          elsif (self.inventory.nil?)
            warn(format('Inventory for <%s>[%s] not yet ready',
                        self.class.name,
                        self.eid.to_s))
            return nil
          end
        end
        while (invobj = self.pending_inventory.pop)
          if (TAGF.debugging?(:inventory))
            warn(format('Dequeuing and adding <%s>[%s] ' \
                        + 'to <%s>[%s] inventory',
                        invobj.class.name,
                        invobj.eid.to_s,
                        self.class.name,
                        self.eid.to_s))
          end
          self.inventory.add(invobj)
        end
        return self.inventory
      end                       # def update_inventory!

      #
      # Method to add a game element to the current object's
      # inventory.
      #
      # @param [Element] arg
      # @!macro doc.TAGF.formal.kwargs
      # @option kwargs [Symbol] :duh (nil)
      #   No options defined at this time.
      # @raise [TAGF::Exceptions::HasNoInventory]
      # @return [@todo]
      def add(arg, **kwargs)
        result		= nil
        unless (self.respond_to?(:inventory))
          raise_exception(HasNoInventory, self)
        end
        if (self.inventory.nil?)
          unless (self.pending_inventory.include?(arg))
            if (TAGF.debugging?(:inventory))
              warn(format('<%s>[%s].%s: Enqueuing <%s>[%s] ' \
                          + 'for addition to <%s>[%s] inventory',
                          self.class.name,
                          self.eid.to_s,
                          __method__.to_s,
                          arg.class.name,
                          arg.eid.to_s,
                          self.class.name,
                          self.eid.to_s))
            end
            self.pending_inventory.push(arg)
          end
          return self.inventory
        else
          self.update_inventory! unless (self.pending_inventory.empty?)
        end
        if (TAGF.debugging?(:inventory))
          warn(format('<%s>[%s].%s: Adding <%s>[%s] ' \
                      + 'to <%s>[%s] inventory',
                      self.class.name,
                      self.eid.to_s,
                      __method__.to_s,
                      arg.class.name,
                      arg.eid.to_s,
                      self.class.name,
                      self.eid.to_s))
        end
        result		= self.inventory.add(arg)
        return result
      end                       # def add(arg, **kwargs)

      #
      # @return [void]
      def inventory_is_full(exc=nil)
        suffix		= exc.nil? ? '' : "\n  %s"
        if (exc.kind_of?(LimitItems))
          msg		= "%s can't hold any more items."
        elsif (exc.kind_of?(LimitVolume))
          msg		= "%.0sIt's too big."
        elsif (exc.kind_of?(LimitMass))
          msg		= "%.0sThat's too heavy."
        else
          msg		= "%s's inventory is full."
        end
        warn(format(msg + suffix, self.name, exc.to_s))
        return nil
      end                       # def inventory_is_full(exc=nil)

      #
      # @!macro doc.TAGF.formal.kwargs
      # @return [Container] self
      #
      def initialize_container(*args, **kwargs)
        TAGF::Mixin::Debugging.invocation
        @pending_inventory	||= []
        kwargs[:owned_by]	= self
        self.game.create_inventory_on(self, **kwargs)
        return self
      end                       # def initialize_container

      nil
    end                         # module TAGF::Mixin::Container

    nil
  end                           # module TAGF::Mixin

  nil
end                             # module TAGF

# Local Variables:
# mode: ruby
# indent-tabs-mode: nil
# eval: (if (intern-soft "fci-mode") (fci-mode 1))
# eval: (auto-fill-mode 1)
# End:
