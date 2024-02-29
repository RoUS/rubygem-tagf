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
require('tagf/mixin/universal')
require('tagf/exceptions')
require('tagf/mixin/element')
require('forwardable')
require('byebug')

# @!macro doc.TAGF.module
module TAGF

  #
  class Inventory

    #
    include(Mixin::DTypes)
    include(Mixin::Element)
    extend(Mixin::Element)
    include(Mixin::UniversalMethods)
    extend(Forwardable)
    include(Exceptions)

    #
    include(Enumerable)

    # @!macro [attach] doc.TAGF.classmethod.flag
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

    # @!attribute [r] master
    #   Boolean flag indicating whether this is the game's master
    #   inventory or not.
    def master?
      result		= (self.game.inventory == self)
      return result ? true : false
    end                         # def master

    #
    # Adaptive name for an object's inventory.
    #
    def name
      text		= format('Inventory for %s',
                                 self.owned_by.to_key)
      return text
    end                         # def name

    # @!method to_key
    # Overrides Element#to_key.
    # Similar to `#inspect`, #to_key returns a human-readable
    # reference for the receiver.  By default it is formed from the
    # name of the receiver's class and its EID, but overriding is
    # encouraged.
    #
    # @return [String]
    #   <tt>"Inventory[<em>inventory-owner-key</em>]"</tt>
    def to_key
      result		= format('%s[%s]',
                                 self.klassname,
                                 self.owned_by.to_key)
      return result
    end                       # def to_key

    def_delegator(:@contents, :keys)
    def_delegator(:@contents, :values)

    # @!method filter(**kwargs, &block)
    # Apply an iterative #select to objects in this inventory.
    # `kwargs` is a hash of attribute names and values used to refine
    # the results.  The special key `:klass` allows narrowing the
    # selection to object of the specified class or classes.
    #
    # @example
    #   .filter(eid: 'SomeEID')
    #   => # nil or an array of objects whose `eid` was "SomeEID"
    #   .filter(eid: ['SomeEID', 'SomeOtherEID'])
    #   => # nil or an array of objects whose `eid`s matched
    # @example
    #   .filter(klass: TAGF::Location) { |o|
    #     o.paths.empty?
    #   }
    #   => # an array of Location objects with no departing paths
    #
    # Objects which do not have the named attribute are automatically
    # excluded.
    #
    # @param [Hash<Symbol=>Any>]	kwargs
    # @option kwargs [Object]		:klass
    #   Refines selection to object whose #class (<em>not</em> class
    #   NAME!) is included in the comparison value.  <strong>N.B.:
    #   This is an <em>exact</em> match, not an inheritance one.
    #   Think `#is_a?` as opposed to `#kind_of?`.</strong>
    # @option kwargs [Object]		symbol
    #   Any symbol matching an attribute for objects in the selection
    #   list.  If an object in the list doesn't have the attribute, it
    #   is automatically excluded.
    #
    # @return [Array<Object>]
    #   `nil` if no matching objects were found, or an array of the
    #   matches otherwise.
    def filter(**kwargs, &block)
      result		= self.values
      if (block_given?)
        result		= result.select(&block)
      end
      catch(:filtered) do
        if (klass = kwargs[:klass])
          klasses	= [ *klass ].flatten.uniq
          result	= result.select { |iobject|
            klasses.include?(iobject.class)
          }
          throw(:filtered) if (result.nil? || result.empty?)
          kwargs.delete(:klass)
        end
        kwargs.each do |fsym,testval|
          testval	= [ *testval ].flatten.uniq
          result	= result.select { |iobject|
            iobject.respond_to?(fsym) \
            && testval.include?(iobject.send(fsym))
          }
          throw(:filtered) if (result.nil? || result.empty?)
        end
      end                       # catch(:filtered) do
      return result
    end                         # def filter(**kwargs)

    #
    # @param [Hash<Symbol=>Any>]	kwargs
    # @option kwargs [String]		:inventory_eid
    #   Override the calculated EID for the inventory object created
    #   (used to create the master inventory).
    def initialize(**kwargs)
      TAGF::Mixin::Debugging.invocation
      @contents		= {}
      unless (owner = kwargs[:owned_by])
        raise_exception(TAGF::Exceptions::NoObjectOwner, self)
      end
      self.is_static!
      #
      # Use the inventory key of the owner to make navigation
      # simpler.
      #
      #
      # For some unknown reason, `self.class.name` for an Inventory
      # instance is coming up `nil`, so we need to work around it.
      #
      @eid		= kwargs[:inventory_eid] \
                          || format('%s[%s]',
                                    self.klassname,
                                    owner.to_key)
      self.initialize_element(**kwargs, eid: @eid)
      self.game.add(self)
    end                         # def initialize

    #
    def inspect
      result		= format('#<%s:' \
                                 + ' game="%s"' \
                                 + ', name="%s"' \
                                 + ', %i %s' \
                                 + ', %i %s' \
                                 + '>',
                                 self.to_key,
                                 self.game.eid.to_s,
                                 self.name.to_s,
                                 @contents.count,
                                 pluralise('object', @contents.count),
                                 self.items.count,
                                 pluralise('item', self.items.count))
      return result
    end                         # def inspect

    # @!method subordinate_inventories
    # @return [Array<Inventory>]
    #   An array of the current inventory object and any owned by
    #   objects in it, recursively.
    def subordinate_inventories
      debugger
      results		= [ self ]
      @contents.select { |k,o| o.has_inventory? }.each do |k,i|
        results		|= i.inventory.subordinate_inventories
      end
      return results.flatten.uniq
    end                         # def subordinate_inventories

    # @!method include?(arg, **kwargs)
    # @param [Any] 			arg
    # @param [Hash<Symbol=>Any>]	kwargs
    # @option kwargs [Boolean]		:recurse	false
    # @return [Boolean]
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
      gameobjs		= args.select { |o| o.kind_of?(Mixin::Element) }
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
    # @raise [TAGF::Exceptions::LimitMass]
    # @raise [TAGF::Exceptions::LimitItems]
    # @raise [TAGF::Exceptions::LimitVolume]
    # @return [Object] self
    def can_add?(newobj, **kwargs)
      return true if (kwargs[:ignorelimits])
      owned_by		= self.owned_by
      if ((items_max = owned_by.capacity_items) > 0)
        if ((owned_by.items_current + 1) > items_max)
          raise_exception(LimitItems, self, newobj, levels: 2)
        end
      elsif ((mass_max = owned_by.capacity_mass) > 0.0)
        if ((owned_by.mass_current + newobj.mass) > mass_max)
          raise_exception(LimitMass, self, newobj, levels: 2)
        end
      elsif ((volume_max = owned_by.capacity_volume) > 0.0)
        if ((owned_by.volume_current + newobj.volume) > volume_max)
          raise_exception(LimitVolume, self, newobj, levels: 2)
        end
      end
      return true
    end                         # can_add?(newobj, **kwargs)

    # @!method insert(arg, **kwargs)
    # Adds an object to this object's inventory.  Doesn't change the
    # object's owner (see {Mixin::Element#move_to}), and will raise an
    # exception if
    #
    # a. the object is already in the new inventory
    #    <strong>AND</strong> the new inventory isn't the master
    #    inventory for the game.
    #
    # @param [Mixin::Element] arg
    # @raise [TAGF::Exceptions::NotGameElement]
    # @raise [TAGF::Exceptions::AlreadyInInventory]
    #
    def insert(arg, **kwargs)
      return self if (arg == self)
      unless (arg.class.ancestors.include?(Mixin::Element))
        raise_exception(NotGameElement, arg)
      end
      key		= arg.eid
      if (@contents.keys.include?(key))
        oldobj		= @contents[key]
        if ((arg != oldobj) || (! self.master? ))
          raise_exception(AlreadyInInventory, arg, oldobj)
        end
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
                    self.eid))
      end
      @contents[key]	= arg
      return self
    end                         # def insert(arg, **kwargs)
    alias_method(:+, :insert)

    #
    # @param [Array] args
    #   Optional list of arguments to pass to the `each` method of
    #   the `@contents` hash.
    # @param [Hash] kwargs
    #   Optional hash of keywords/values, used only by this method and
    #   not passed on to anything invoked by it.
    # @option kwargs [Symbol] :only (nil)
    #   Allows iterating over either the eids or the objects in the
    #   inventory.  If `:eids` or `:keys`, only the eids will be
    #   passed to the block iterator; if `:objects`, then the actual
    #   objects.  If omitted altogether, then the block is passed a
    #   two-element array [<em>eid</em>, <em>object</em>] at each
    #   iteration.
    # @return [Array<eid>]
    #   when invoked with `only: :keys` or `only: :eids`.
    # @return [Array<gameobject>]
    #   when invoked with `only: :objects`.
    # @return [Hash{eid=>gameobject}]
    #   when `:only` is something other than `:keys`, `:eids`, or
    #   `:objects`, or is omitted entirely.
    def each(*args, **kwargs, &block)
      list		= @contents
      result		= []
      if (%i[ eids keys ].include?(kwargs[:only]))
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
    # @option kwargs [Symbol] :only (nil)
    #   Allows iterating over either the eids or the objects in the
    #   inventory.  If the value is either `:eids` or `:keys`, only
    #   the eids will be passed to the block iterator; if the value
    #   is `:objects`, then only the actual objects are passed.  If
    #   this option is omitted altogether, then the block is passed a
    #   two-element array [<em>eid</em>, <em>object</em>] at each
    #   iteration.
    # @return [Array<eid>]
    #   when invoked with `only: :keys` or `only: :eids`.
    # @return [Array<gameobject>]
    #   when invoked with `only: :objects`.
    # @return [Hash{eid=>gameobject}]
    #   when `:only` is something other than `:keys`, `:eids`, or
    #   `:objects`, or is omitted entirely.
    def select(*args, **kwargs, &block)
      list		= @contents
      result		= []
      if (%i[ eids keys ].include?(kwargs[:only]))
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
        o.kind_of?(Actor)
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
    def features
      result		= self.select(only: :objects) { |o|
        o.kind_of?(Feature)
      }
      return result
    end                         # def features

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
end                             # module TAGF

# Local Variables:
# mode: ruby
# indent-tabs-mode: nil
# eval: (if (intern-soft "fci-mode") (fci-mode 1))
# eval: (auto-fill-mode 1)
# End:
