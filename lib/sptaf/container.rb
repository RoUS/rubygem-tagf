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

require_relative('../sptaf')
require('byebug')

# @!macro doc.TAF.module
module TAF

  # @!macro doc.TAF.Mixins.module
  module Mixins

    #
    # Mixin module defining methods specific to objects that have
    # inventories, such as locations, player and NPC objects, and some
    # items.
    #
    module Container

      # @!macro doc.TAF.Mixin.module.eigenclass Container
      class << self

        include(ClassMethods)

        # @!macro doc.TAF.module.classmethod.included
        def included(klass)
          whoami	= '%s eigenclass.%s' \
                          % [self.name, __method__.to_s]
          warn('%s called for %s' \
               % [whoami, klass.name])
          super
          return nil
        end                     # def included(klass)

        nil
      end                       # module Container eigenclass

      include(Mixins::Thing)

      # 
      flag(:allow_containers)

      #
      # Instance variable accessor for a container's inventory (list
      # of things owned or contained).
      #
      # @overload inventory
      #   @!attribute [r] inventory
      #   @return [Inventory]
      #     the object's inventory.
      #   @return [nil]
      #     if the inventory hasn't yet been created.
      attr_reader(:inventory)
      #
      # @overload inventory=(value)
      #   @!attribute [w] inventory
      #   @param [Inventory] value
      #     instance of Inventory class to install as the
      #     object's [new] inventory list.
      #   @raise [TypeError]
      #     if the argument is not an instance of Inventory;
      #       attribute 'inventory' requires an instance of class
      #       TAF::Inventory
      #   @return [Inventory] object's new inventory object.
      #
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
      int_accessor(:capacity_items)

      #
      # Count of things currently in the object's inventory.
      #
      int_accessor(:items_current)

      #
      float_accessor(:capacity_mass)
      
      #
      float_accessor(:mass_current)

      #
      float_accessor(:volume_current)
      
      #
      float_accessor(:capacity_volume)

      #
      float_accessor(:volume_current)
      
      #
      def contains_item?(*args, **kwargs)
        
      end                       # def contains_item?

      #
      def add(arg, **kwargs)
        unless (self.respond_to?(:inventory))
          raise_exception(HasNoInventory, self)
        end
        return self.inventory.add(arg, **kwargs)
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
      def initialize_container(*args, **kwargs)
        warn('[%s]->%s running' % [self.class.name, __method__.to_s])
        return self
      end                       # def initialize_container

      nil
    end                         # module Container

    nil
  end                           # module Mixins

  #
  class Container

    include(Mixins::Container)

    #
    def initialize(*args, **kwargs)
      warn('[%s]->%s running' % [self.class.name, __method__.to_s])
      self.initialize_thing(*args, **kwargs)
      args		= args.dup
      self.game		||= kwargs[:game]
      if (kwargs[:owned_by] && kwargs[:owned_by].respond_to?(:game))
        self.game	||= kwargs[:owned_by].game
      end
      unless (self.game \
              || (args[0].kind_of?(::TAF::Game) \
                  && (self.game ||= args[0].game)))
        raise_exception(NoGameContext)
      end
      #
      # We're a container, so create our own inventory and add it to
      # our, erm, inventory.
      #
      self.game.create_inventory_on(self,
                                    game:	self.game,
                                    owned_by:	self)
      self.add(self.inventory)
      #
      # Add this object to our owner's inventory.
      #
      if (self.owned_by && self.owned_by.has_inventory?)
        self.owned_by.add(self)
      end
      self.game.add(self)
    end                         # def initialize

    nil
  end                           # class Container

  nil
end                             # module TAF

# Local Variables:
# mode: ruby
# indent-tabs-mode: nil
# eval: (if (intern-soft "fci-mode") (fci-mode 1))
# End:
