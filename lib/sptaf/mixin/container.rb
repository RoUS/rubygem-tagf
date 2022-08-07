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

require('sptaf/debugging')
warn(__FILE__) if (TAF.debugging?(:file))
require('sptaf')
require('byebug')

# @!macro doc.TAF.module
module TAF

  # @!macro doc.TAF.Mixin.module
  module Mixin

    #
    # Mixin module defining methods specific to objects that have
    # inventories, such as locations, player and NPC objects, and some
    # items.
    #
    module Container

      # @!macro doc.TAF.Mixin.module.eigenclass Container
      class << self

        #
        include(ClassMethods)

        # @!macro doc.TAF.module.classmethod.included
        def included(klass)
          whoami	= '%s eigenclass.%s' \
                          % [self.name, __method__.to_s]
=begin
          warn('%s called for %s' \
               % [whoami, klass.name])
=end
          super
          return nil
        end                     # def included(klass)

        nil
      end                       # module Containers eigenclass

      #
      # All Containers are Things.
      #
      include(Mixin::Thing)

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

      #
      # Whether or not this container is permitted to have others
      # nested inside it.
      #
      # @!macro doc.TAF.classmethod.flag.use
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
      # Does the container have the option of being open or closed?
      # Think about a birdcage, which would want a door to keep any
      # birds from escaping.
      #
      # @!macro doc.TAF.classmethod.flag.use
      flag(is_openable: false)

      #
      # If the container is openable, is it actually open?  We
      # overrides some of the standard attribute accessors added by
      # the ClassMethods#flag method to provide correct results if the
      # element can't even be opened.
      #
      # @!macro doc.TAF.classmethod.flag.use
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
        @is_open = false unless (self.is_openable?)
        result		= @is_open
        return result
      end                       # def is_open
      alias_method(:is_open?, :is_open)
      def is_open=(value)
        value		= truthify(value)
        if (self.is_openable?)
          @is_open	= value
        elsif (game_option?(:RaiseOnInvalidValues) && value)
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
      # @!macro doc.TAF.classmethod.flag.use
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
      #     TAF::Inventory` if the argument is not an actual instance
      #     of Inventory.
      #   @return [Inventory] object's new inventory object.
      #
      attr_reader(:inventory)
      def inventory=(value)
        unless (value.kind_of?(Inventory))
          raise_exception(TypeError,
                          ("attribute '#s' requires an instance " \
                           + 'of class TAF::Inventory') \
                          % [__method__.to_s.sub(%r!=$!, '')])
        end
        unless (@inventory.nil?)
          bt		= caller
          bt.pop
          bt.pop
          warn(('%s <slug=%s, name="%s"> already has an inventory, ' \
                + "overwriting\n  %s") \
               % [self.class.name,
                  self.slug,
                  self.name,
                  bt.join("\n  ")])
        end
        @inventory	= value
        return @inventory
      end                       # def inventory=(value)

      #
      # Maximum number of items permitted in the container (default
      # 0).  Zero means no limit.  Items are game objects that are
      # non-static instances of {Container} or {Item}.
      #
      # @!macro doc.TAF.classmethod.int_accessor.use
      int_accessor(:capacity_items)

      #
      # Count of things currently in the object's inventory.
      #
      # @!macro doc.TAF.classmethod.int_accessor.use
      int_accessor(:current_items)

      #
      # @!macro doc.TAF.classmethod.float_accessor.use
      float_accessor(:capacity_mass)
      
      #
      # @!macro doc.TAF.classmethod.float_accessor.use
      float_accessor(:current_mass)

      #
      # @!macro doc.TAF.classmethod.float_accessor.use
      float_accessor(:capacity_volume)

      #
      # @!macro doc.TAF.classmethod.float_accessor.use
      float_accessor(:current_volume)

      #
      attr_reader(:pending_inventory)

      #
      # @!macro doc.TAF.formal.kwargs
      # @return [Boolean]
      #
      def contains_item?(*args, **kwargs)
        
      end                       # def contains_item?

      #
      def update_inventory!
        if (debugging?(:inventory))
          warn('Updating inventory for <%s>[%s]' \
               % [ self.class.name, self.slug.to_s ])
          if (self.pending_inventory.empty?)
            warn('No pending inventory updates for <%s>[%s]' \
                 % [ self.class.name, self.slug.to_s ])
            return self.inventory
          elsif (self.inventory.nil?)
            warn('Inventory for <%s>[%s] not yet ready' \
                 % [ self.class.name, self.slug.to_s ])
            return nil
          end
        end
        while (invobj = self.pending_inventory.pop)
          if (debugging?(:inventory))
            warn('Dequeuing and adding <%s>[%s] to <%s>[%s] inventory' \
                 % [invobj.class.name,
                    invobj.slug.to_s,
                    self.class.name,
                    self.slug.to_s
                   ])
          end
          result	= self.inventory.add(invobj)
        end
        return self.inventory
      end                       # def update_inventory!

      #
      # Method to add a game element to the current object's
      # inventory.
      #
      # @param [Thing] arg
      # @!macro doc.TAF.formal.kwargs
      # @option kwargs [Symbol] :duh (nil)
      #   No options defined at this time.
      # @raise [HasNoInventory]
      # @return [@todo]
      def add(arg, **kwargs)
        result		= nil
        unless (self.respond_to?(:inventory))
          raise_exception(HasNoInventory, self)
        end
        if (self.inventory.nil?)
          unless (self.pending_inventory.include?(arg))
            if (debugging?(:inventory))
              warn('<%s>[%s].%s: Enqueuing <%s>[%s] for addition to <%s>[%s] inventory' \
                   % [self.class.name,
                      self.slug.to_s,
                      __method__.to_s,
                      arg.class.name,
                      arg.slug.to_s,
                      self.class.name,
                      self.slug.to_s
                     ])
            end
            self.pending_inventory.push(arg)
          end
          return self.inventory
        else
          self.update_inventory! unless (self.pending_inventory.empty?)
        end
        if (debugging?(:inventory))
          warn('<%s>[%s].%s: Adding <%s>[%s] to <%s>[%s] inventory' \
               % [self.class.name,
                  self.slug.to_s,
                  __method__.to_s,
                  arg.class.name,
                  arg.slug.to_s,
                  self.class.name,
                  self.slug.to_s
                 ])
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
        warn((msg + suffix) % [self.name, exc.to_s])
        return nil
      end                       # def inventory_is_full(exc=nil)

      #
      # @!macro doc.TAF.formal.kwargs
      # @return [Container] self
      #
      def initialize_container(*args, **kwargs)
        if (debugging?(:initialize))
          warn('<%s>[%s].%s running' \
               % [self.class.name,
                  self.slug.to_s,
                  __method__.to_s])
        end
        @pending_inventory	||= []
        self.game.create_inventory_on(self, owned_by: self)
        return self
      end                       # def initialize_container

      nil
    end                         # module Container

    nil
  end                           # module Mixin

  nil
end                             # module TAF

# Local Variables:
# mode: ruby
# indent-tabs-mode: nil
# eval: (if (intern-soft "fci-mode") (fci-mode 1))
# End:
