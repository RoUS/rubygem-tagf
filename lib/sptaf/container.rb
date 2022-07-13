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

require_relative('version')
require_relative('thing')
require_relative('classmethods')
require_relative('exceptions')

# @!macro ModuleDoc
module TAF

  class Inventory

    include(::TAF::Thing)
    include(Enumerable)

    #
    flag(:master)

    #
    # Adaptive name for an object's inventory.
    #
    def name
      text		= "Inventory for %s '%s'" \
                          % [self.owner.class.name,
                             (self.owner.name || self.owner.slug).to_s]
      return text
    end                         # def name

    #
    def keys
      return @contents.keys
    end

    #
    def [](*args)
      return @contents.send(:[], *args)
    end

    #
    def []=(*args)
      return @contents.send(:[]=, *args)
    end

    #
    def initialize(*args, **kwargs)
      self.object_setup do
        @contents	= {}
        if (owned_by = kwargs[:owner])
          @slug		= '%s[%s].inventory' \
                          % [owned_by.class.name,
                             (owned_by.name || owned_by.slug).to_s]
        end
        @master		= kwargs[:master] ? true : false
        super
      end                       # self.object_setup do
    end                         # def initialize

    #
    def push(obj)

    end                         # def push
    alias_method(:<<, :push)

    #
    def delete(key)
      return @contents.delete(key)
    end                         # def delete

    #
    # Adds an object to this object's inventory.  Doesn't change the
    # object's owner (see TAF::Thing#move_to), and will raise an
    # exception if
    #
    # a. the object is already in the new inventory
    #    <strong>AND</strong> the new inventory isn't the master
    #    inventory for the game.
    #
    # @param [TAF::Thing] arg
    # @raise [TAF::NotGameObject]
    # @raise [TAF::AlreadyInInventory]
    #
    def +(arg, **kwargs)
      unless (arg.class.ancestors.include?(::TAF::Thing))
        self.raise_exception(NotGameObject, arg)
      end
      key		= arg.slug
      if (@contents.keys.include?(key))
        oldobj		= @contents[key]
        if ((arg != oldobj) || (! self.master? ))
          self.raise_exception(AlreadyInInventory, arg, oldobj)
        end
      end
      @contents[key]	= arg
      return arg
    end                         # def +
    alias_method(:add, :+)

    #
    def each(&block)
      return @contents.values.each(&block)
    end                         # def each

    nil
  end                           # class Inventory

  # @!macro ContainMixinDoc
  module ContainerMixin

    #
    class << self

      #
      def included(klass)
        klass.include(::TAF::Thing)
      end                       # def included

      nil
    end                         # module Container eigenclass

    extend ::TAF::ClassMethods::Thing

    #
    flag(:allow_containers)

    #
    attr_accessor(:inventory)

    # overload
    def items_max=(int)
      unless (int.kind_of?(Integer))
        raise(ArgumentError,
              __method__.to_s + ' requires an integer')
      end
      @items_max	= int
    end
    # overload
    def items_max
      return (@items_max ||= 0)
    end                         # def items_max

    #
    def items_current
      return (@items_current ||= 0)
    end                         # items_current

    #
    def mass_max
      return (@mass_max ||= 0)
    end                         # def mass_max

    #
    def mass_current
      return (@mass_current ||= 0)
    end                         # mass_current

    #
    def volume_max
      return (@volume_max ||= 0)
    end                         # def volume_max

    #
    def volume_current
      return (@volume_current ||= 0)
    end                         # volume_current

    def contains_item?(*args, **kwargs)

    end                         # def contains_item?

    #
    def add(arg, **kwargs)
      unless (self.respond_to?(:inventory))
        self.raise_exception(HasNoInventory, self)
      end
      if (self.game.in_setup?)
        return nil
      end
      return self.inventory.add(arg, **kwargs)
    end                         # def add(arg, **kwargs)

    nil
  end                           # module ContainerMixin

  class Container

    include(::TAF::Thing)
    include(::TAF::ContainerMixin)

    #
    def initialize(*args, **kwargs)
      self.object_setup do
        args		= args.dup
        self.game	||= kwargs[:game]
        if (kwargs[:owner] && kwargs[:owner].respond_to?(:game))
          self.game	||= kwargs[:owner].game
        end
        unless (self.game \
                || (args[0].kind_of?(::TAF::Game) \
                    && (self.game ||= args[0].game)))
          self.raise_exception(NoGameContext)
        end
        super
      end                       # self.object_setup
      #
      # We're a container, so create our own inventory and add it to
      # our, erm, inventory.
      #
      self.inventory	= Inventory.new(game: self.game, owner: self)
      self.add(self.inventory)
      #
      # Add this object to our owner's inventory.
      #
      if (self.owner && self.owner.has_inventory?)
        self.owner.add(self)
      end
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
