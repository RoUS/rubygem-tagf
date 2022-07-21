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

# @!macro doc.TAF
module TAF

  #
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
                          % [self.owned_by.class.name,
                             (self.owned_by.name || self.owned_by.slug).to_s]
      return text
    end                         # def name

    #
    def initialize(**kwargs)
      warn('[%s]->%s running' % [self.class.name, __method__.to_s])
      @contents		= {}
      unless (owned_by = kwargs[:owned_by])
        raise_exception(NoObjectOwner, self)
      end
      #
      # Use the inventory key of the owner to make navigation
      # simpler.
      #
      @slug		= '%s[%s].inventory' \
                          % [owned_by.class.name,
                             owned_by.slug.to_s]
      @master		= kwargs[:master] ? true : false
      self.initialize_thing([], **kwargs)
    end                         # def initialize

    #
    def inspect
      result		= ('#<%s:"%s" ' \
                           + ' game="%s"' \
                           + ', name="%s"' \
                           + ', %i item(s)' \
                           + '>') \
                          % [
        self.class.name,
        self.slug.to_s,
        self.game.slug.to_s,
        self.name.to_s,
        @contents.size
      ]
      return result
    end                         # def inspect
    #
    def subordinate_inventories
      results		= [ self ]
      self.select { |o| o.has_inventory? }.each do |i|
        results		|= i.subordinate_inventories
      end
      return results.flatten.uniq
    end                         # def subordinate_inventories

    #
    def include?(arg, **kwargs)
      ilist		= [ self ]
      if (kwargs[:recurse])
        ilist		|= self.subordinate_inventories
      end
      ilist		= ilist.select { |i| i.contains_item?(arg) }
      return ilist
    end                         # def include?

    #
    def keys
      return @contents.keys
    end

    #
    def select(&block)
      results		= @contents.values.select(&block)
      return results
    end

    #
    def [](*args, **kwargs)
      if (kwargs[:select] == :objects)
        results		= @contents.values.send(:[], *args)
      else
        results		= @contents.send(:[], *args)
      end
      return results
    end

    #
    def []=(*args)
      gameobjs		= args.select { |o| o.kind_of?(::TAF::Thing) }
      unless ((args - gameobjs).empty?)
        self.raise_exception(NotGameElement,
                             'only game elements ' \
                             + 'can be put in inventories')
      end
      return @contents.send(:[]=, *args)
    end                         # def []=

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

  # @!macro doc.ContainerMixin
  module ContainerMixin

    # @!macro doc.ContainerMixin.eigenclass
    class << self

      #
      # @return [void]
      #
      def included(klass)
        whoami		= '%s eigenclass.%s' \
                          % [self.name, __method__.to_s]
        warn('%s called for %s' \
             % [whoami, klass.name])
        [ TAF::ClassMethods, TAF::ClassMethods::Thing].each do |xmodule|
          warn('%s extending %s with %s' \
               % [whoami, klass.name, xmodule.name])
          klass.extend(xmodule)
        end
        return nil
      end                       # def included

      nil
    end                         # module ContainerMixin eigenclass

    include(::TAF)
    include(::TAF::Thing)

    #
    flag(:allow_containers)

    #
    attr_accessor(:inventory)

    # overload
    int_reader(:items_max)
    # overload
    def items_max=(arg)
      unless (arg.kind_of?(Integer))
        raise(ArgumentError,
              __method__.to_s \
              + ' requires an integer')
      end
      @items_max	= arg
    end                         # def items_max=

    #
    int_reader(:items_current)
    # overload
    def items_current=(arg)
      unless (arg.kind_of?(Integer))
        raise(ArgumentError,
              __method__.to_s \
              + ' requires an integer')
      end
      @items_current	= arg
    end                         # def items_current=

    #
    float_reader(:mass_max)
    # overload
    def mass_max=(arg)
      unless (arg.kind_of?(Numeric))
        raise(ArgumentError,
              __method__.to_s \
              + ' requires a float or something coercible')
      end
      @mass_max		= Float(arg)
    end                         # def mass_max=

    #
    float_reader(:mass_current)
    # overload
    def mass_current=(arg)
      unless (arg.kind_of?(Numeric))
        raise(ArgumentError,
              __method__.to_s \
              + ' requires a float or something coercible')
      end
      @mass_current		= Float(arg)
    end                         # def max_current=

    #
    float_reader(:volume_current)
    # overload
    def volume_current=(arg)
      unless (arg.kind_of?(Numeric))
        raise(ArgumentError,
              __method__.to_s \
              + ' requires a float or something coercible')
      end
      @volume_current	= Float(arg)
    end                         # def volume_current=

    #
    float_reader(:volume_max)
    # overload
    def volume_max=(arg)
      unless (arg.kind_of?(Numeric))
        raise(ArgumentError,
              __method__.to_s \
              + ' requires a float or something coercible')
      end
      @volume_max	= Float(arg)
    end                         # def volume_max=


    #
    float_reader(:volume_current)

    def contains_item?(*args, **kwargs)

    end                         # def contains_item?

    #
    def add(arg, **kwargs)
      unless (self.respond_to?(:inventory))
        self.raise_exception(HasNoInventory, self)
      end
      return self.inventory.add(arg, **kwargs)
    end                         # def add(arg, **kwargs)

    #
    def initialize_container(*args, **kwargs)
    end                         # def initialize_container

    nil
  end                           # module ContainerMixin

  class Container

    include(::TAF)
    include(::TAF::Thing)
    include(::TAF::ContainerMixin)

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
        self.raise_exception(NoGameContext)
      end
      #
      # We're a container, so create our own inventory and add it to
      # our, erm, inventory.
      #
      self.inventory	= Inventory.new(game: self.game, owned_by: self)
      self.add(self.inventory)
      #
      # Add this object to our owner's inventory.
      #
      if (self.owned_by && self.owned_by.has_inventory?)
        self.owned_by.add(self)
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
