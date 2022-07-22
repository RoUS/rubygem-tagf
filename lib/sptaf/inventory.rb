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

  #
  class Inventory

    include(::TAF::Thing)
    include(Enumerable)

    # @!macro [attach] doc.TAF::ClassMethods.classmethod.flag
    #   @overload $1
    #     Return the current value of `$1`, which is always either
    #     `true` or `false`.  It will have no other values.
    #     @return [Boolean]
    #       `true` if the `$1` flag is set, or `false` otherwise.
    #   @overload $1=(arg)
    #     Sets `$1` to the 'truthy' value of `arg`.  <em>I.e.</em>, if
    #     Ruby would regard `arg` as `true`, then that's how `$1` will
    #     be set.  <strong>Exception:</strong> Any numeric value that
    #     coerces to `Integer(0)` will be regarded as
    #     <strong>`false`</strong>.
    #     @param [Object] arg
    #     @return [Object] the value of `arg` that was passed.
    #   @overload $1?
    #     @return [Boolean]
    #       `true` if `$1` is set, or `false` otherwise.
    #   @overload $1!
    #     Unconditionally sets `$1` to `true`.
    #     @return [Boolean] `true`.
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
    def [](*args, **kwargs)
      if (kwargs[:only] == :objects)
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
        raise_exception(NotGameElement,
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
    # object's owner (see {TAF::Thing#move_to}), and will raise an
    # exception if
    #
    # a. the object is already in the new inventory
    #    <strong>AND</strong> the new inventory isn't the master
    #    inventory for the game.
    #
    # @param [TAF::Thing] arg
    # @raise [TAF::NotGameElement]
    # @raise [TAF::AlreadyInInventory]
    #
    def +(arg, **kwargs)
      unless (arg.class.ancestors.include?(::TAF::Thing))
        raise_exception(NotGameElement, arg)
      end
      key		= arg.slug
      if (@contents.keys.include?(key))
        oldobj		= @contents[key]
        if ((arg != oldobj) || (! self.master? ))
          raise_exception(AlreadyInInventory, arg, oldobj)
        end
      end
      @contents[key]	= arg
      return self
    end                         # def +
    alias_method(:add, :+)

    #
    # @param [Array] args
    #   Optional list of arguments to pass to the `each` method of
    #   the `@contents` hash.
    # @param [Hash] kwargs
    #   Optional hash of keywords/values, used only by this method and
    #   not passed on to anything invoked by it.
    # @option kwargs [Symbol] `:only` (nil)
    #   Allows iterating over either the slugs or the objects in the
    #   inventory.  If `:slugs` or `:keys`, only the slugs will be
    #   passed to the block iterator; if `:objects`, then the actual
    #   objects.  If omitted altogether, then the block is passed a
    #   two-element array [<em>slug</em>, <em>object</em>] at each
    #   iteration.
    # @return [Array<slug>]
    #   when invoked with `only: :keys` or `only: :slugs`.
    # @return [Array<gameobject>]
    #   when invoked with `only: :objects`.
    # @return [Hash<slug=>gameobject>]
    #   when `:only` is something other than `:keys`, `:slugs`, or
    #   `:objects`, or is omitted entirely.
    def each(*args, **kwargs, &block)
      list		= @contents
      result		= []
      if (%i[ slugs keys ].include?(kwargs[:only]))
        list		= @contents.keys
      elsif (kwargs[:only] == :objects)
        list		= @contents.values
      end
      result		= list.send(__method__, *args, &block)
      return result
    end                         # def each

    # @param [Array] args
    #   Optional list of arguments to pass to the `select` method of
    #   the `@contents` hash.
    # @param [Hash] kwargs
    #   Optional hash of keywords/values, used only by this method and
    #   not passed on to anything invoked by it.
    # @option kwargs [Symbol] `:only` (nil)
    #   Allows iterating over either the slugs or the objects in the
    #   inventory.  If `:slugs` or `:keys`, only the slugs will be
    #   passed to the block iterator; if `:objects`, then the actual
    #   objects.  If omitted altogether, then the block is passed a
    #   two-element array [<em>slug</em>, <em>object</em>] at each
    #   iteration.
    # @return [Array<slug>]
    #   when invoked with `only: :keys` or `only: :slugs`.
    # @return [Array<gameobject>]
    #   when invoked with `only: :objects`.
    # @return [Hash<slug=>gameobject>]
    #   when `:only` is something other than `:keys`, `:slugs`, or
    #   `:objects`, or is omitted entirely.
    def select(*args, **kwargs, &block)
      list		= @contents
      result		= []
      if (%i[ slugs keys ].include?(kwargs[:only]))
        list		= @contents.keys
      elsif (kwargs[:only] == :objects)
        list		= @contents.values
      end
      result		= list.send(__method__, *args, &block)
      return result
    end                         # def select(*args, **kwargs, &block)

    #
    def actors
      result		= self.select(only: :objects) { |o|
        o.kind_of?(ActorMixin)
      }
      return result
    end                         # def actors

    #
    def containers
      result		= self.select(only: :objects) { |o|
        o.kind_of?(Container)
      }
      return result
    end                         # def containers

    #
    def inventories
      result		= self.select(only: :objects) { |o|
        o.kind_of?(Inventory)
      }
      return result
    end                         # def inventories

    #
    def items
      result		= self.select(only: :objects) { |o|
        o.kind_of?(Item)
      }
      return result
    end                         # def items

    #
    def locations
      result		= self.select(only: :objects) { |o|
        o.kind_of?(Location)
      }
      return result
    end                         # def locations

    #
    def npcs
      result		= self.select(only: :objects) { |o|
        o.kind_of?(NPC)
      }
      return result
    end                         # def npcs

    nil
  end                           # class Inventory

  nil
end                             # module TAF

# Local Variables:
# mode: ruby
# indent-tabs-mode: nil
# eval: (if (intern-soft "fci-mode") (fci-mode 1))
# End:
