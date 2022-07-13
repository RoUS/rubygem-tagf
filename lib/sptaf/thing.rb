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

require_relative('classmethods')

# @!macro TAFDoc
module TAF

  # @!macro ThingDoc
  module Thing

    class << self

      include(::TAF::ClassMethods::Thing)

      #
      def included(klass)
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

    #
    attr_accessor(:game)

    #
    attr_reader(:slug)

    #
    attr_accessor(:owner)

    #
    attr_accessor(:name)

    #
    attr_accessor(:desc)

    #
    attr_accessor(:shortdesc)

    #
    flag(:static)

    ONCE_AND_DONE	= %i[ game slug owner ]

    #
    def raise_exception(exc_class, *args, **kwargs)
      kwargs[:levels]	||= 1
      bt		= caller
      #
      # Add ourself to what's being elided.
      #
      (kwargs[:levels] + 1).times { bt.pop }
      kwargs.delete(:levels)
      exc		= exc_class.new(exc_class, *args, **kwargs)
      exc.set_backtrace(bt)
      raise(exc)
    end                         # def raise_exception
    private(:raise_exception)

    #
    def has_inventory?
      return self.respond_to?(:inventory) ? true : false
    end                         # def has_inventory?

    #
    def is_container?
      return self.class.ancestors.include?(::TAF::Container) \
             ? true \
             : false
    end                         # def is_container?

    #
    flag(:in_setup)

    #
    def object_setup(&block)
      self.in_setup!
      yield(self)
      self.in_setup	= false
      return self
    end                         # def object_setup

    #
    # Move the associated object from one object's inventory to
    # another's.
    #
    def move_to(*args, **kwargs)
      if (self.owner.inventory.master?)
        self.raise_exception(MasterInventory, self, kwargs)
      end
      if (self.static?)
        self.raise_exception(ImmovableObject, self, kwargs)
      end
      newowner		= args[0] unless (newowner = kwargs[:owner])
      self.owner.inventory.delete(self.slug)
      newowner.inventory.add(self)
    end                         # def move_to

    #
    def initialize(*args, **kwargs)
      warn('[TAF::Thing] initialize running')
      @slug		||= kwargs[:slug] || self.object_id
      if (self.owner.nil? \
          && ((! kwargs.key?(:owner)) \
              || kwargs[:owner].nil?))
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
      debugger
      if (self.game.nil? && self.owner.respond_to?(:game))
        @game			||= self.owner.game
      end
      unless (self.respond_to?(:game) && (! self.game.nil?))
        self.raise_exception(NoGameContext)
      end
      self.game.add(self) unless (self.game.in_setup?)
      self.owner.add(self) unless (self.owner.in_setup?)
    end                         # def initialize

    nil
  end                           # module Thing

  nil
end                             # module TAF

# Local Variables:
# mode: ruby
# indent-tabs-mode: nil
# eval: (if (intern-soft "fci-mode") (fci-mode 1))
# End:
