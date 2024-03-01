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
require('tagf')
require('byebug')

# @!macro doc.TAGF.module
module TAGF

  # @!macro doc.TAGF.Refinement.module
  module Refinement

    # @!macro doc.TAGF.Refinement.Description.module
    module Description

      refine(::String) do
        #
        # Allow a decription to be formatted as to width and proper
        # bullet indentation.
        #
        # @todo
        #   This needs thinking out; it may be too much work.
        #
        # @return [String]
        def wordwrap(right_margin: 72, indent: 0, bullets: %q[o * •])
          return self
        end                     # def wordwrap

        nil
      end                       # refine(::String)

      nil
    end                         # module TAGF::Refinement::Description

    nil
  end                           # module TAGF::Refinement

  # @!macro doc.TAGF.Mixin.module
  module Mixin

    # @!macro doc.TAGF.Mixin.Element.module
    module Element

      #
      using(Refinement::Description)

      #
      include(Mixin::UniversalMethods)
      include(Mixin::DTypes)

      #
      if (TAGF.debugging?(:include))
        warn(format('%s extending itself with %s',
                    self.name,
                    Mixin::DTypes.name))
      end
      include(Mixin::DTypes)

      # @!macro TAGF.constant.Loadable_Fields
      Loadable_Fields		= [
        #
        # Unique fields tying an element record to a particular game
        # instance.  When stored in YAML, what's actually stored is
        # the EID of any relevant object rather than the object
        # itself.
        #
        'eid',
        'game',
        'owned_by',
        #
        # Modules that potentially should be mixed in to instances.
        #
        'mixins',
        #
        # Attributes describing the element (description,
        # singular/plural article, &c.).
        #
        'name',
        'desc',
        'shortdesc',
        'article',
        'preposition',
        #
        # Array of identifers for marking relationships between
        # elements.  For example, if keyword `"xyzzy"` is supposed to
        # teleport the player to a particular location, that
        # location's element would include `"xyzzy"` as one of its
        # tags so that the interpreter could find it.
        #
        'tags',
        #
        # Mostly for game features, like rooms, furniture, invisible
        # walls, &c.
        #
        'is_static',
        'visible',
      ]

      # @!macro TAGF.constant.Abstracted_Fields
      Abstracted_Fields		= {
        game:			EID,
        owned_by:		EID,
      }

      # @!attribute [r] tags
      # Array of identifers for marking relationships between
      # elements.  For example, if keyword `"xyzzy"` is supposed to
      # teleport the player to a particular location, that location's
      # element would include `"xyzzy"` as one of its tags so that the
      # interpreter could find it.
      #
      # @return [Array<(String,Symbol)>]
      attr_reader(:tags)

      # @!attribute [r] abstractions
      # This attribute is a hash used during load or import.
      # Attributes which reference actual complex objects (such as
      # `#game` or `#owned_by`) have only their EIDs stored in
      # `YAML`.  As the dataset is loaded, all objects are created
      # with the EIDs that are part of their stored definition; after
      # they have all been created, all of them are processed to store
      # the actual object references, rather than just the EIDs, in
      # the attribute fields.
      #
      # @see TAGF::Loader
      #
      # @return [Hash<String=>String>]
      #   each element in the returned hash consists of an attribute
      #   name and the EID of the object that should be stored in that
      #   attributed as part of final [re]construction.
      attr_reader(:abstractions)

      #
      # The <em>`eid`</em> is the unique game-wide identifier for each
      # object.  As such, it only has a reader/getter defined so it
      # can't be accidentally altered, and is `nil` until set during
      # game object initialisation.  To change it, use the
      # {Game#change_eid} method.
      #
      # <strong>N.B.</strong>:
      # An object's eid can be any sort of non-`nil` object, but
      # strings or numbers are recommended.  In game data files, strings
      # should be used when defining objects such as rooms, items,
      # <em>&.</em>
      #
      # @return [Object,nil]
      #  the current value of the object's eid.
      attr_reader(:eid)

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
      attr_accessor(:owned_by)

      #
      # @return [String]
      attr_accessor(:name)

      #
      # @return [String]
      attr_accessor(:desc)

      #
      # @return [String]
      attr_accessor(:shortdesc)

      #
      # Boolean attribute indicating whether the object can be moved
      # between inventories (<em>e.g.</em>, being picked up by the
      # player).  Things like rooms (Location-class objects) never
      # move; things like the player (Player) or any NPCs (NPC) are
      # moved using specific semantics.
      #
      # @!macro doc.TAGF.classmethod.flag.invoke
      flag(:is_static)

      # @!attribute [rw] visible
      # @!macro doc.TAGF.classmethod.flag.invoke
      # For discernable objects, such as Location, Feature, and Item
      # elements, this controls whether or not they are perceptible to
      # the player; <em>i.e.</em>, whether their existence is even
      # acknowledged in any user-readable output.  Secret passages can
      # be implemented by marking a Path as invisible.
      #
      # @see #invisible
      #
      # @return [Boolean]
      #   `true` if the receiver is considered visible to the player.
      flag(:visible)

      # @!attribute [rw] invisible
      # This is an inversion of the #visible attribute, rather than an
      # attribute in its own right.  It modifies the `:@visible`
      # instance variable through the #visible accessors, and has no
      # instance variable of its own.
      #
      # @see #visible
      #
      # @return [Boolean]
      #   `true` if the receiver is considered imperceptible to the
      #   player.
      # @overload invisible
      #   Returns the inverse of the setting of the #visible flag.
      def invisible
        result		= (! self.visible?)
        return result
      end                       # def invisible
      alias_method(:invisible?, :invisible)
      # @overload invisible=(val)
      #   Sets the #visible flag to the inverse of `val`.
      def invisible=(val)
        self.visible	= (! truthify(val))
        result		= (! self.visible?)
        return result
      end                       # def invisible=(val)
      # @overload invisible!
      #   Sets the #visible flag to `false`.
      def invisible!
        result		= true
        self.visible	= false
        return result
      end                       # def invisible!

      #
      # List of attributes that are considered essentially immutable,
      # once set, by automatic attribute hash value processing
      # (typically by iterating over `kwargs`).
      #
      # These typically do <strong>not</strong> have setter
      # (<em>`sym`</em>`=`) methods, and so if a value MUST be changed,
      # there are special semantics for making it happen.
      #
      ONCE_AND_DONE	= %i[ game eid owned_by ]

      #
      # How to refer to the element as a singular, such as "**a**
      # knife", "**some** coins", "**an** ocarina", and so forth.
      #
      # @return [String]
      #   "`a`", "`an`", or "`some`", or whatever is appropriate.  The
      #   default is determined from the first letter of the element's
      #   #desc value..
      attr_accessor(:article)

      attr_accessor(:mixins)

      #
      # How to refer to contents when displayed.  Are they 'in' the
      # container (like a backpack), or 'on' it (like a desk)?  For a
      # location, is the player 'in' it or 'at' it?
      #
      # @return [String]
      #   "`on`" or "`in`" as appropriate.  The default is "`in`".
      attr_accessor(:preposition)

      # @!method has_tags?(*values, **kwargs)
      # Check to see if the receiver's #tags array attribute contains
      # <strong>all</strong> of the items in the `tagvalues` array.
      #
      # @param [Array<Any>]		values
      #   List of values that must be found in the receiver's #tags
      #   (or other if overridden by `kwargs[:field]`) field in order
      #   for this method to return `true`.
      # @param [Hash<Symbol=>Any>]	kwargs
      #   Hash of keyword arguments.
      # @option kwargs [Symbol]		field
      #   Override the field (default `:tags`) to check for inclusion
      #   of all items in `values`.
      #
      # @return [Boolean]
      #   `true` if the element's #tags attribute (or the one
      #   specified by `kwargs[:field]`) includes `tagvalue`.
      def has_tags?(*values, **kwargs)
        field		= (kwargs[:field] || :tags).to_sym
        assigned_values	= [ *self.send(field) ]
        result		= (assigned_values & values) == values
        return result
      end                       # def has_tags?(*values)

      #
      def describe(**kwargs)
        unless (kwargs[:level])
          kwargs[:level] = 0
          result	= ''
        else
          result	= "\n"
        end
        result		+= (kwargs[:level] * ' ') + self.desc
        return result unless (self.is_container?)

        self.inventory.features.each do |f|
          next unless (f.visible?)
          result	+= format("  You see %s.", f.name)
          #
          # @todo
          #   This needs to be worked; if the preposition is 'on' then
          #   the container is always open and transparent.
          #
          if (f.is_open? || f.transparent?)
            if (f.is_empty?)
              if (f.preposition == 'in')
                result += "  It is empty.\n"
              else
                result += "  There is nothing on it.\n"
              end
            end
          end
        end                     # self.inventory.features.each
        return result
      end                       # def describe(**kwargs)

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
        return self.singleton_class.ancestors.include?(Mixin::Container) \
               ? true \
               : false
      end                       # def is_container?

      # @!attribute [rw] sealable
      # Any class, instance, or module that includes Mixin::Sealable
      # will get the is considered sealable (which means it gets
      # additional attributes like #openable, #opened, #lockable,
      # <em>&c.</em>).  It can be tested by checking its #sealable?
      # attribute, defined here.
      # @return [Boolean]
      #   `true` if the receiver includes the Mixin::Sealable module
      #   and therefore has openable/lockable/needs-a-key features.
      def sealable
        return self.kind_of?(TAGF::Mixin::Sealable) ? true : false
      end                       # def sealable
      alias_method(:sealable?, :sealable)

      #
      # @return [Boolean]
      def has_inventory?
        cond		= (self.is_container? \
                           && self.inventory.kind_of?(Inventory))
        return cond ? true : false
      end                       # def has_inventory?

      #
      # @return [Boolean]
      def has_items?
        cond		= (self.has_inventory? \
                           && (! self.inventory.empty?))
        return cond ? true : false
      end                       # def has_items?

      #
      # @return [Inventory]
      def add_inventory(**kwargs)
        return self.inventory if (self.has_inventory?)
        kwargs_new	= kwargs.merge({ game: self.game, owned_by: self })
        self.inventory	= Inventory.new(**kwargs_new)
        return self.inventory
      end                       # def add_inventory

      #
      # Move the associated object from one object's inventory to
      # another's.
      #
      # @return [Container] self
      def move_to(*args, **kwargs)
        if (self.owned_by.inventory.master?)
          raise_exception(TAGF::Exceptions::MasterInventory,
                          self,
                          **kwargs)
        elsif (self.is_static?)
          raise_exception(TAGF::Exceptions::ImmovableObject,
                          self,
                          **kwargs)
        end
        begin
          if (args[0].inventory.can_add?(self))
            newowner = args[0] unless (newowner = kwargs[:owned_by])
            self.owned_by.inventory.delete(self.eid)
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
      def contained_in
        inventories	= self.game.inventory.select { |o|
          o.kind_of?(Inventory) && (! o.master?)
        }
        inlist		= inventories.select { |i| i.include?(self) }
        return inlist
      end                       # def contained_in

      # @!method to_key
      # Similar to `#inspect`, #to_key returns a human-readable
      # reference for the receiver.  By default it is formed from the
      # name of the receiver's class and its EID, but overriding is
      # encouraged.
      #
      # @return [String]
      #   by default, <tt><em>classname</em>[<em>EID</em>]</tt>
      #   (<em>e.g.</em>, `"Game[Advent]"` or
      #   `"Path[Loc1-Loc2-via-SW]"`.
      def to_key
        result		= format('%s[%s]',
                                 self.klassname,
                                 self.eid.to_s)
        return result
      end                       # def to_key

      # @param [Hash<Symbol=>Any>]	kwargs
      # @option kwargs [Integer]	:level
      # @option kwargs [String]		:format
      # @option kwargs [StringIO]	:sio
      #
      # @return [void]
      def look(**kwargs)
        level			= kwargs[:level].to_i
        indent			= ' ' * level
        sio			= kwargs[:sio] || StringIO.new
        #
        # Format our own description.
        #
        desc			= self.desc
        if (level > 0)
          desc			= indent + desc
          desc.gsub!(%r!\n!, "\n" + indent)
        end
        format_def		= '%<desc>s'
        format_c		= 'InventoryItemFormat'
        if (self.class.const_defined?(format_c, false))
          format_def		= self.class.const_get(format_c, false)
        end
        format_s		= kwargs[:format] || format_def
        #
        header_def		= nil
        header_c		= 'InventoryHeader'
        if (self.class.const_defined?(header_c, false))
          header_def		= self.class.const_get(header_c, false)
        end
        header_s		= kwargs[:header] || header_def
        sio.puts(desc)
        #
        # If this is a Location, report on any exits.
        #
        if (self.kind_of?(TAGF::Location))
          self.paths.each do |cxobj|
            sio.puts(cxobj.desc)
          end
        end
        #
        # Now process any visible things in the inventory.
        #
        if (self.has_inventory?)
          iheader		= nil
          self.inventory.each do |eid,iobj|
            if ((! iobj.visible?) \
                || iobj.kind_of?(TAGF::Path))
              next
            end
            if (header_def)
              if (iheader.nil?)
                iheader		= true
                sio.puts(indent + header_s)
              end
            end
=begin
            sio.puts(format(format_s,
                            {
                              desc:	cxobj.desc,
                              article:	cxobj.article,
                              Article:	cxobj.article.capitalize,
                            }))
=end
            debugger
            iobj.look(**kwargs,
                      sio:	sio,
                      format:	format_s,
                      level:	level + 1
                     )
          end
        end
        if (level.zero?)
          sio.rewind
          puts(sio.read)
        end
        return nil
      end                         # def look

      # @!method export
      # Uses the #loadable_fields method to determine all the fields
      # we should include in an export hash.  Fields that are simple
      # (<em>i.e.</em>, don't appear as keys in the hash returned by
      # #abstracted_fields) are stored directly into the result hash
      # by this method.  Once the simple fields have been processed,
      # #abstractify is invoked to handle any fields that require
      # additional processing, and its return value merged into the
      # ultimate result.  Most abstracted fields will be simple
      # EID-instead-of-object strings which the default #abstractify
      # method will handle simply, but anything more complex than that
      # can be processed by overriding #abstractify on a
      # <em>per</em>-class or -module basis and calling `super`.
      #
      # @see Loadable_Fields
      # @see Abstracted_Fields
      # @see #abstractify
      #
      # @return [Hash<String=>Any>]
      def export
        result			= {}
        flist			= self.loadable_fields
        alist			= self.abstracted_fields.keys
        flist.each do |fname|
          #
          # If this is an abstracted field, skip.
          #
          next if (alist.include?(fname.to_sym))
          fivar			= format('@%s', fname).to_sym
          fvalue		= nil
          #
          # Try to get the value through an attribute getter method.
          # If that fails, fetch the instance variable directly.
          #
          begin
            fvalue		= self.send(fname.to_sym)
          rescue NoMethodError
            fvalue		= self.instance_variable_get(fivar)
          end
          result[fname]		= fvalue
        end
        #
        # Now call #abstractify and merge in any result.
        #
        ahash			= self.abstractify
        return result.merge(ahash)
      end                       # def export

      # @!method abstractify
      # Use the return values from #loadable_fields and
      # #abstracted_fields to determine what attributes require
      # special processing for exporting.  {Loadable_Fields} and {Abstracted_Fields} constants to
      # record all of the exportable details of the receiver in a hash
      # that can  be used to re-create it later.
      #
      # @see #export
      #
      # @return [Hash<String=>Any>]
      def abstractify
        #
        # Figure out exactly what fields require abstraction, and
        # narrow that down to just those that are EIDs.  Anything more
        # involved should be done with an overriding #abstractify
        # method that calls this <em>via</em> `super` and merges its
        # result into that return value.
        #
        flist			= self.loadable_fields
        ahash			= self.abstracted_fields
        ahash			= ahash.select { |k,v|
          (v == EID) \
          && flist.include?(k.to_s)
        }
        alist			= ahash.keys
        #
        # Preset our return value to a hash of nil, then fill it in
        # with the actual attribute settings.
        #
        alist			= alist.map { |o| o.to_s }
        result			= {}
        alist.each do |fname|
          fgetter		= fname.to_sym
          fivar			= format('@%s', fname).to_sym
          result[fname]		= self.instance_variable_get(fivar).eid
        end
        return result
      end                       # def abstractify

      # @param [Array] args
      # @!macro doc.TAGF.formal.kwargs
      # @option kwargs [Symbol]	:eid		(nil)
      # @option kwargs [Symbol] :owned_by	(nil)
      # @option kwargs [Symbol] :game		(nil)
      # @raise [TAGF::Exceptions::NoObjectOwner]
      # @raise [TAGF::Exceptions::SettingLocked]
      # @raise [RuntimeError]
      # @raise [TAGF::Exceptions::NoGameContext]
      #
      # @return [Element] self
      def initialize_element(*args, **kwargs)
        TAGF::Mixin::Debugging.invocation
        @eid		||= kwargs[:eid] || self.object_id.to_s
        @game		||= kwargs[:game]
        kwargs.delete(:eid)
        kwargs.delete(:game)
        @tags		||= []
        if (self.owned_by.nil? \
            && ((! kwargs.has_key?(:owned_by)) \
                || kwargs[:owned_by].nil?))
          raise_exception(TAGF::Exceptions::NoObjectOwner, self)
        end
        #
        # If this element is supposed to be/have a seal (something
        # openable/closable, like a door or a box), and isn't already,
        # add the Mixin::Sealable module to its singleton class.
        #
        # We need to do this early so that any seal-specific fields
        # in `kwargs` will be processed properly.
        #
        if ((mixins = kwargs[:mixins]) \
            && mixins.kind_of?(Array))
          self.mixins	= [ *mixins ].compact.uniq
          mixins.each do |mixin_s|
            mixin_s	= mixin_s.downcase.sub(%r!^.*::!, '')
            mixin	= format('TAGF::Mixin::%s',
                                 mixin_s.capitalize)
            if (TAGF.const_defined?(mixin))
              mixin	= TAGF.const_get(mixin)
              if (! self.class.ancestors.include?(mixin))
                self.singleton_class.include(mixin)
                mixin_init = format('initialize_%s', mixin_s).to_sym
                if (self.respond_to?(mixin_init))
                  self.send(mixin_init, *args, **kwargs)
                  warn(format('%s: mixed %s into %s',
                              __callee__.to_s,
                              mixin.to_s,
                              self.to_key))
                end
              end
            else
              raise_exception(RuntimeError,
                              format('%s: cannot locate mixin "%s" ' \
                                     + 'for element %s',
                                     __callee__.to_s,
                                     mixin,
                                     self.to_key))
            end                 # if (TAGF.const_defined?(mixin))
          end                   # mixins.each do
        else
          #
          # No explicit mixins, so make the attribute an empty array.
          #
          self.mixins	= []
        end                     # if (kwargs[:mixins])
        kwargs.delete(:mixins)
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
            raise_exception(TAGF::Exceptions::SettingLocked,
                            attr_f.attrib)
          end
          if (self.respond_to?(attr_f.setter))
            self.send(attr_f.setter, newval)
          elsif (self.respond_to?(attr_f.getter))
            self.instance_variable_set(attr_f.ivar, newval)
          else
            raise_exception(RuntimeError,
                            format('(kwargs) attempt to set ' \
                                   + 'non-attribute "%s"',
                                   attr_f.str))
          end
        end                     # kwargs.each

        #
        # Now check for validity..
        #
        unless (self.respond_to?(:game) && (! self.game.nil?))
          raise_exception(TAGF::Exceptions::NoGameContext)
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
        #
        # If we're loading in a non-serial order from a `YAML` file,
        # some fields will contain string EIDs rather than the objects
        # having those EIDs (since the objects won't have been created
        # yet).  So don't treat them as element yet.
        #
        if (self.owned_by.kind_of?(TAGF::Mixin::Element))
          debugger if (self.kind_of?(Player))
          self.owned_by.add(self)
        end
        return self
      end                       # def initialize_element

      nil
    end                         # module TAGF::Mixin::Element

    nil
  end                           # module TAGF::Mixin
  nil
end                             # module TAGF

# Local Variables:
# mode: ruby
# indent-tabs-mode: nil
# eval: (if (intern-soft "fci-mode") (fci-mode 1))
# eval: (auto-fill-mode 1)
# End:
