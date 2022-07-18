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

  # @!macro doc.Thing
  module Thing

    #
    class << self

      include(::TAF::ClassMethods::Thing)

      #
      def included(klass)
        warn('%s<included> called for %s' % [self.name, klass.name])
        warn('TAF::Thing<included> extending ::TAF::ClassMethods::Thing')
        klass.extend(::TAF::ClassMethods::Thing)
      end                       # def included

      nil
    end                         # Thing module eigenclass

    #
    class Description < ::String

      #
      def wordwrap(right_margin: 72, indent: 0, bullets: %q[o * •])
        return self
      end                       # def wordwrap

    end                         # class Description

    include(::TAF)

    #
    attr_accessor(:game)

    #
    attr_reader(:slug)

    #
    attr_accessor(:owned_by)

    #
    attr_accessor(:name)

    #
    attr_accessor(:desc)

    #
    attr_accessor(:shortdesc)

    #
    flag(:static)

    ONCE_AND_DONE	= %i[ game slug owned_by ]

    #
    def has_inventory?
      cond		= (self.respond_to?(:inventory) \
                           && self.inventory.kind_of?(::TAF::Inventory))
      return cond ? true : false
    end                         # def has_inventory?

    #
    def is_container?
      return self.class.ancestors.include?(::TAF::ContainerMixin) \
             ? true \
             : false
    end                         # def is_container?

    #
    flag(:in_setup)

    #
    def superego(meth)
      result		= self.method(meth).super_method.owner.name
      return result
    end                         # def superego

    #
    def object_setup(&block)
      self.in_setup!
      yield(self)
      self.in_setup	= false
      return self
    end                         # def object_setup

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
        self.raise_exception(MasterInventory, self, kwargs)
      end
      if (self.static?)
        self.raise_exception(ImmovableObject, self, kwargs)
      end
      newowner		= args[0] unless (newowner = kwargs[:owned_by])
      self.owned_by.inventory.delete(self.slug)
      newowner.inventory.add(self)
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
      warn('[%s] %s' % [self.class.name, __method__.to_s])
      inits		= self.mixin_supers(:initialize)
      debugger
      @slug		||= kwargs[:slug] || self.object_id
      if (self.owned_by.nil? \
          && ((! kwargs.key?(:owned_by)) \
              || kwargs[:owned_by].nil?))
        self.raise_exception(NoObjectOwner, self)
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
          self.raise_exception(SettingLocked, attrib)
        end
        if (self.respond_to?(attrib_setter))
          self.send(attrib_setter, newval)
        else
          self.instance_variable_set(attrib_ivar, newval)
        end
      end                       # kwargs.each

      if (self.game.nil? && self.owned_by.respond_to?(:game))
        @game			||= self.owned_by.game
      end

      unless (self.respond_to?(:game) && (! self.game.nil?))
        self.raise_exception(NoGameContext)
      end
      self.game.add(self) unless (self.game.in_setup?)
      self.owned_by.add(self) unless (self.owned_by.in_setup?)
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
