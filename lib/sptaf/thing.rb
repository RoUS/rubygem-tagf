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

  # @!macro doc.TAF::Thing.module
  module Thing

    #
    class Description < ::String

      #
      def wordwrap(right_margin: 72, indent: 0, bullets: %q[o * •])
        return self
      end                       # def wordwrap

    end                         # class Description

    extend(::TAF::ClassMethods)
    include(::TAF)

    #
    # The <em>`slug`</em> is the unique game-wide identifier for each
    # object.  As such, it only has a reader/getter defined so it
    # can't be accidentally altered.  To change it, use the
    # #change_slug method.
    #
    # @return [Object]
    #  the slug can be any sort of object, not just a string or a
    #  number.
    #
    attr_reader(:slug)

    #
    attr_accessor(:game)

    #
    attr_accessor(:owned_by)

    #
    attr_accessor(:name)

    #
    attr_accessor(:desc)

    #
    attr_accessor(:shortdesc)

    #
    float_accessor(:mass)

    #
    # The volume used by the current object, in cubic
    # (whatever-units-are-in-use).  This is only meaningful when an
    # attempt might be made to place the object into a container with
    # a volume limitation.  (See mass, ContainerMixin max_items)
    #
    float_accessor(:volume)

    #
    # Boolean attribute indicating whether the object can be moved
    # between inventories (<em>e.g.</em>, being picked up by the
    # player).  Things like rooms (Location-class objects) never
    # move; things like the player (Player) or any NPCs (NPC) are
    # moved using specific semantics.
    #
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
    flag(:static)

    #
    # List of attributes that are considered essentially immutable,
    # once set, by automatic attribute hash value processing
    # (typically by iterating over `kwargs`).
    #
    # These typically do <strong>not</strong> has setter
    # (<em>`sym`</em>`=`) methods, and so if a value MUST be changed,
    # there are special semantics for making it happen.
    #
    ONCE_AND_DONE	= %i[ game slug owned_by ]

    #
    def has_inventory?
      cond		= (self.is_container? \
                           && self.inventory.kind_of?(::TAF::Inventory))
      return cond ? true : false
    end                         # def has_inventory?

    #
    def has_items?
      cond		= (self.has_inventory? \
                           && (! self.inventory.empty?))
      return cond ? true : false
    end                         # def has_items?

    #
    def add_inventory(**kwargs)
      return nil if (self.has_inventory?)
      kwargs_new	= kwargs.merge({ game: self.game, owned_by: self })
      self.inventory	= Inventory.new(**kwargs)
      return self.inventory
    end                         # def add_inventory

    #
    # Move the associated object from one object's inventory to
    # another's.
    #
    def move_to(*args, **kwargs)
      if (self.owned_by.inventory.master?)
        raise_exception(MasterInventory, self, kwargs)
      elsif (self.static?)
        raise_exception(ImmovableObject, self, kwargs)
      end
      begin
        if (args[0].inventory.can_add?(self))
          newowner = args[0] unless (newowner = kwargs[:owned_by])
          self.owned_by.inventory.delete(self.slug)
          newowner.inventory.add(self)
        end
      rescue InventoryLimitError => e
        args[0].inventory_is_full(e)
      rescue StandardError => e
        raise
      end
      return self
    end                         # def move_to

    #
    def contained_in
      inventories	= self.game.inventory.select { |o|
        o.kind_of?(::TAF::Inventory) && (! o.master?)
      }
      inlist		= inventories.select { |i| i.include?(self) }
      return inlist
    end                         # def contained_in

    #
    def initialize_thing(*args, **kwargs)
      warn('[%s]->%s running' % [self.class.name, __method__.to_s])
      @slug		||= kwargs[:slug] || self.object_id
      if (self.owned_by.nil? \
          && ((! kwargs.key?(:owned_by)) \
              || kwargs[:owned_by].nil?))
        raise_exception(NoObjectOwner, self)
      end
      kwargs.each do |attrib,newval|
        attrib		= attrib.to_sym
        attrib_s	= attrib.to_s
        attrib_setter	= "#{attrib_s}=".to_sym
        attrib_ivar	= "@#{attrib_s}".to_sym
        curval		= nil
        if (self.respond_to?(attrib))
          curval	= self.instance_variable_get(attrib_ivar)
        end
        if (ONCE_AND_DONE.include?(attrib) \
            && (! curval.nil?) \
            && (newval != curval))
          raise_exception(SettingLocked, attrib)
        end
        if (self.respond_to?(attrib_setter))
          self.send(attrib_setter, newval)
        else
          self.instance_variable_set(attrib_ivar, newval)
        end
      end                       # kwargs.each

      unless (self.respond_to?(:game) && (! self.game.nil?))
        raise_exception(NoGameContext)
      end
#      self.game.add(self) unless (self.game.in_setup?)
#      self.owned_by.add(self) unless (self.owned_by.in_setup?)
      return self
    end                         # def initialize_thing

    nil
  end                           # module Thing

  nil
end                             # module TAF

# Local Variables:
# mode: ruby
# indent-tabs-mode: nil
# eval: (if (intern-soft "fci-mode") (fci-mode 1))
# End:
