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
    # Define class methods and constants that will be added to all
    # object classes in the TAF namespace.
    #
    module Thing

      #
      class Description < ::String

        #
        # Allow a decription to be formatted as to width and proper
        # bullet indentation.
        #
        # @todo
        #   This needs thinking out; it may be too much work.
        #
        # @return [String]
        #
        def wordwrap(right_margin: 72, indent: 0, bullets: %q[o * •])
          return self
        end                     # def wordwrap

      end                       # class Description

      #
      include(::TAF)

      #
      if (TAF.debugging?(:extend))
        warn('%s extending itself with %s' \
             % [ self.name, ClassMethods.name ])
      end
      extend(ClassMethods)

      #
      # The <em>`slug`</em> is the unique game-wide identifier for each
      # object.  As such, it only has a reader/getter defined so it
      # can't be accidentally altered, and is `nil` until set during
      # game object initialisation.  To change it, use the
      # {Game#change_slug} method.
      #
      # <strong>N.B.</strong>:
      # An object's slug can be any sort of non-`nil` object, but
      # strings or numbers are recommended.  In game data files, strings
      # should be used when defining objects such as rooms, items,
      # <em>&.</em>
      #
      # @return [Object,nil]
      #  the current value of the object's slug.
      #
      attr_reader(:slug)

      # @!attribute [rw] game
      #
      # Instance variable referencing the game object which ultimately
      # 'owns' every object instance created.
      #
      # @return [nil]
      #   if not yet set.
      # @return [Game]
      #   game object for the caller, and presumably all other objects
      #   in the game as well.
      #
      attr_accessor(:game)

      #
      # @return [nil,Container]
      #
      attr_accessor(:owned_by)

      #
      # @return [String]
      #
      attr_accessor(:name)

      #
      # @return [String]
      #
      attr_accessor(:desc)

      #
      # @return [String]
      #
      attr_accessor(:shortdesc)

      #
      # @!macro doc.TAF.classmethod.float_accessor.use
      float_accessor(:mass)

      #
      # The volume used by the current object, in cubic
      # (whatever-units-are-in-use).  This is only meaningful when an
      # attempt might be made to place the object into a container with
      # a volume limitation.  (See #mass,
      # {Mixin::Container#capacity_items}.)
      #
      # @!macro doc.TAF.classmethod.float_accessor.use
      float_accessor(:volume)

      #
      # Boolean attribute indicating whether the object can be moved
      # between inventories (<em>e.g.</em>, being picked up by the
      # player).  Things like rooms (Location-class objects) never
      # move; things like the player (Player) or any NPCs (NPC) are
      # moved using specific semantics.
      #
      # @!macro doc.TAF.classmethod.flag.use
      flag(:static)

      #
      # @!macro doc.TAF.classmethod.flag.use
      flag(:visible)

      #
      # List of attributes that are considered essentially immutable,
      # once set, by automatic attribute hash value processing
      # (typically by iterating over `kwargs`).
      #
      # These typically do <strong>not</strong> have setter
      # (<em>`sym`</em>`=`) methods, and so if a value MUST be changed,
      # there are special semantics for making it happen.
      #
      ONCE_AND_DONE	= %i[ game slug owned_by ]

      #
      # How to refer to the element as a singular, such as "**a**
      # knife", "**some** coins", "**an** ocarina", and so forth.
      #
      # @return [String]
      #   "`a`", "`an`", or "`some`", or whatever is appropriate.  The
      #   default is determined from the first letter of the element's
      #   #desc value..
      attr_accessor(:article)
      
      #
      # How to refer to contents when displayed.  Are they 'in' the
      # container (like a backpack), or 'on' it (like a desk)?  For a
      # location, is the player 'in' it or 'at' it?
      #
      # @return [String]
      #   "`on`" or "`in`" as appropriate.  The default is "`in`".
      attr_accessor(:preposition)
      
      #
      # Checks to see if the object is a container according to the
      # game mechanics (basically, its class has included the
      # {Mixin::Container} module).
      #
      # @return [Boolean] `true`
      #   if the current object (`self`) has included the
      #   `Mixin::Container` module and has all the related methods
      #   and attributes.
      # @return [Boolean] `false`
      #   if the object is not a container.
      #
      def is_container?
        return self.class.ancestors.include?(Mixin::Container) \
               ? true \
               : false
      end                       # def is_container?

      #
      # @return [Boolean]
      #
      def has_inventory?
        cond		= (self.is_container? \
                           && self.inventory.kind_of?(Inventory))
        return cond ? true : false
      end                       # def has_inventory?

      #
      # @return [Boolean]
      #
      def has_items?
        cond		= (self.has_inventory? \
                           && (! self.inventory.empty?))
        return cond ? true : false
      end                       # def has_items?

      #
      # @return [Inventory]
      #
      def add_inventory(**kwargs)
        return self.inventory if (self.has_inventory?)
        kwargs_new	= kwargs.merge({ game: self.game, owned_by: self })
        self.inventory	= Inventory.new(**kwargs)
        return self.inventory
      end                       # def add_inventory

      #
      # Move the associated object from one object's inventory to
      # another's.
      #
      # @return [Container] self
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
      end                       # def move_to

      #
      # @return [Array<Container>]
      #
      def contained_in
        inventories	= self.game.inventory.select { |o|
          o.kind_of?(Inventory) && (! o.master?)
        }
        inlist		= inventories.select { |i| i.include?(self) }
        return inlist
      end                       # def contained_in

      #
      # @param [Array] args
      # @!macro doc.TAF.formal.kwargs
      # @option kwargs [Symbol] :slug (nil)
      # @option kwargs [Symbol] :owned_by (nil)
      # @option kwargs [Symbol] :game (nil)
      # @raise [NoObjectOwner]
      # @raise [SettingLocked]
      # @raise [RuntimeError]
      # @raise [NoGameContext]
      # @return [Thing] self
      #
      def initialize_thing(*args, **kwargs)
        if (debugging?(:initialize))
          warn('[%s]->%s running' \
               % [self.class.name, __method__.to_s])
        end
        @slug		||= kwargs[:slug] || self.object_id
        if (self.owned_by.nil? \
            && ((! kwargs.key?(:owned_by)) \
                || kwargs[:owned_by].nil?))
          raise_exception(NoObjectOwner, self)
        end
        #
        # Default to things being visible; it takes an explicit change
        # or a `visible: false` tuple in `kwargs` to make something
        # hidden.
        #
        self.visible!
        #
        # Now set attributes according to the keyword arguments hash.
        #
        kwargs.each do |attrib,newval|
          attr_f	= decompose_attrib(attrib, newval)
          next unless (self.respond_to?(attr_f.getter))
          curval	= nil
          if (self.respond_to?(attr_f.getter))
            curval	= self.instance_variable_get(attr_f.ivar)
          end
          if (ONCE_AND_DONE.include?(attr_f.attrib) \
              && (! curval.nil?) \
              && (newval != curval))
            raise_exception(SettingLocked, attr_f.attrib)
          end
          if (self.respond_to?(attr_f.setter))
            self.send(attr_f.setter, newval)
          elsif (self.respond_to?(attr_f.getter))
            self.instance_variable_set(attr_f.ivar, newval)
          else
            raise_exception(RuntimeError,
                            (('(kwargs) attempt to set ' \
                              + 'non-attribute "%s"') \
                             % attr_f.str))
          end
        end                     # kwargs.each

        #
        # Now check for validity..
        #
        unless (self.respond_to?(:game) && (! self.game.nil?))
          raise_exception(NoGameContext)
        end
        if (self.article.nil? && (! self.desc.nil?))
          self.article	= ('aeiou'.include?(self.desc.downcase[0]) \
                           ? 'an' \
                           : 'a')
        end
        if (self.is_container?)
          @pending_inventory ||= []
        end
        self.game.add(self)
        self.owned_by.add(self)
        return self
      end                       # def initialize_thing

      nil
    end                         # module TAF::Mixin::Thing

    nil
  end                           # module TAF::Mixin
  nil
end                             # module TAF

# Local Variables:
# mode: ruby
# indent-tabs-mode: nil
# eval: (if (intern-soft "fci-mode") (fci-mode 1))
# End:
