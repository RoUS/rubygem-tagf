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
require('psych')
require('yaml')
require('byebug')

# @!macro doc.TAGF.module
module TAGF

  #
  class Game

    #
    include(Mixin::Container)

    #
    include(Exceptions)
    include(Mixin::Debugging)

    #
    attr_accessor(:author)

    #
    attr_accessor(:copyright)

    #
    attr_accessor(:licence)
    alias_method(:license, :licence)
    alias_method(:license=, :licence=)

    #
    attr_accessor(:version)

    #
    attr_accessor(:date)

    #
    # This is the game's master inventory.  All objects (including
    # inventories) created for this game are registered in this
    # inventory.  While things can be deleted from it, they cannot be
    # moved from it to another inventory.  Game elements can be in one
    # inventory or two -- the master and possibly some container.
    #
    # @see Inventory
    #
    # @return [Inventory]
    #   the master inventory of the current game.
    #
    attr_reader(:inventory)

    #
    # @!macro doc.TAGF.classmethod.flag.invoke
    flag(:loaded)

    #
    attr_accessor(:loadfile)

    #
    attr_accessor(:savefile)

    #
    attr_reader(:creation_overrides)
    private(:creation_overrides)

    #
    # Constructor for the main element of this entire project -- the
    # <strong>Game</strong> object.  Every element, including this
    # one, <em>must</em> have the following attributes:
    #
    # * `#game` --
    #   a link to the main Game object (an instance of this class).
    # * `#eid` --
    #   a unique identifier that is used to locate the element in the
    #   various inventories -- particularly the master, which is the
    #   inventory of the Game object.  The <em>`eid`</em> can be any
    #   class of object, but short strings without any whitespace are
    #   recommended.  See Mixin::Element#eid
    # * `#owned_by` --
    #   the object in whose inventory the element is listed.
    #   <em>Every</em> element is listed in the master inventory, but
    #   each may also appear in one additional inventory -- such as
    #   that of a pouch, or a backpack, or a Location or Feature.
    #
    # The arguments to Game#initialize are passed down to other
    # constructors and methods.  They may be modified slightly by each
    # callee in turn, so the order of invocation can be important.
    #
    # @param [Array] args ([])
    #   an optional array of order-dependent arguments.  Not used by
    #   Game#initialize.
    # @param [Hash<Symbol=>Object>] kwargs ({})
    #   a hash with symbolic keys that are either used to identify
    #   attributes to be set to the corresponding values, flags,
    #   control instructions, or other tuples intended for methods and
    #   constructors Game#initialize may invoke.
    # @option kwargs [Symbol] :eid (nil)
    #   This should be a simple string; it is recommended that you use
    #   a word or portmanteau that identifies the game itself (such as
    #   `adventure` or `zork`), since the eid can be used to pick the
    #   appropriate set of definitions out of a YAML file.  (See
    #   #load)
    # @option kwargs [Symbol] :owned_by (nil)
    #   For a Game object, the <em>`owned_by`</em> attribute is
    #   unequivocally set to the Game object itself.  That is, the
    #   game owns itself.  For other objects created by this
    #   constructor, this tupe may be passed through from the caller,
    #   or overridden by Game#initialize as appropriate.
    # @option kwargs [Symbol] :loadfile (nil)
    #   The filesystem path to the default YAML file from which the
    #   game's definitions will be loaded.  If this isn't set as part
    #   of the constructor invocation, it will need to be set
    #   explicitly or specified on a call to the #load method.
    # @option kwargs [Symbol] :name (nil)
    # @option kwargs [Symbol] :desc (nil)
    # @option kwargs [Symbol] :shortdesc (nil)
    # @return [Game]
    #   self
    def initialize(*args, **kwargs)
      debugger
      TAGF::Mixin::Debugging.invocation
      @creation_overrides = {
        game:		self,
        owned_by:	self,
        is_visible:	false,  # Everything we create here is metadata
      }
      kwargs		= kwargs.merge(self.creation_overrides)
      self.game		= kwargs[:game]
      self.owned_by	= kwargs[:game]
      kwargs.delete(:eid) if (@eid = kwargs[:eid])
      kwargs.delete(:name) if (self.name = kwargs[:name])
      @eid		||= self.object_id
      self.name		||= ''
      self.is_static!
      self.initialize_element(*args, **kwargs)
      self.initialize_container(*args, **kwargs)
      self.add(self)
      self.allow_containers!
    end                         # def initialize

    inventory_niladics	= %i[
      keys
      actors
      containers
      inventories
      items
      locations
      npcs
    ]
    inventory_niladics.each do |meth|
      define_method(meth) {
        self.inventory.send(meth)
      }
    end

    #
    def [](*args)
      return @inventory.send(__method__, *args)
    end                         # def []

    #
    def each(*args, **kwargs, &block)
      return @inventory.send(__method__, *args, **kwargs, &block)
    end                         # def each(*args, **kwargs, &block)

    #
    def find(*args, **kwargs, &block)
      return @inventory.send(__method__, *args, **kwargs, &block)
    end                         # def find(*args, **kwargs, &block)

    #
    def map(*args, **kwargs, &block)
      return @inventory.send(__method__, *args, **kwargs, &block)
    end                         # def map(*args, **kwargs, &block)

    #
    def select(*args, **kwargs, &block)
      return @inventory.send(__method__, *args, **kwargs, &block)
    end                         # def select(*args, **kwargs, &block)

    # @param [Object] target
    #   the game element being tested for containerness.
    # @raise [NotAContainer]
    #   if <em>target</em> isn't a container but something
    #   containerish is being attempted on it.
    # @raise [AlreadyHasInventory]
    # @raise [ImmovableElementDestinationError]
    # @return [void]
    def validate_container(target, newcontent, **kwargs)
      debugger
      unless (TAGF.is_game_element?(target))
        raise_exception(NotGameElement, target)
      end
      unless (target.is_container?)
        raise_exception(NotAContainer, target)
      end
      #
      # @todo
      #   FLAWED! Need to allow check for class hierarchy (like
      #   Inventory on container, Item on container, Feature *only* on
      #   Location
      #
      if ((newcontent == Inventory) && target.has_inventory?)
        raise_exception(AlreadyHasInventory, target)
      end
      unless (TAGF.is_game_element?(newcontent))
        raise_exception(NotGameElement, newcontent)
      end
      if (newcontent.is_static? && (! target.is_static?))
        raise_exception(ImmovableElementDestinationError,
                        target,
                        newcontent)
      end
      return nil
    end                         # def validate_container(target, newcontent, **kwargs)
    private(:validate_container)

    #
    def create_inventory_on(target, **kwargs)
      self.validate_container(target, Inventory)
      kwargs		= kwargs.merge(self.creation_overrides)
      kwargs[:owned_by]	= target
      target.inventory	= Inventory.new(**kwargs)
      self.add(target.inventory)
      return target.inventory
    end                         # def create_inventory_on

    #
    def create_item(**kwargs)
      kwargs		= kwargs.merge(self.creation_overrides)
      item		= Item.new([], **kwargs)
      self.add(item)
      return item      
    end                         # def create_item

    #
    def create_item_on(target, **kwargs)
      self.validate_container(target, Item)
      kwargs		= kwargs.merge(owned_by: target)
      item		= self.create_item(**kwargs)
      target.add(item)
      return item
    end                         # def create_item_on

    #
    def create_container(**kwargs)
      override		= {
        game:		self.game
      }
      kwargs		= override.merge(kwargs.merge(owned_by: self.game))
      item		= Container.new([], **kwargs)
      self.game.add(item)
      return item      
    end                         # def create_container

    #
    def create_container_on(target, **kwargs)
      self.validate_container(target, Container)
      kwargs		= kwargs.merge(owned_by: target)
      item		= self.create_container(**kwargs)
      target.add(item)
      return item
    end                         # def create_container_on

    #
    def create_feature(**kwargs)
      kwargs		= kwargs.merge(self.creation_overrides)
      feature		= Feature.new([], **kwargs)
      self.add(feature)
      return feature
    end                         # def create_feature(*args, **kwargs)

    #
    def create_feature_on(target, **kwargs)
      self.validate_container(target, Feature)
      kwargs		= kwargs.merge(owned_by: target)
      item		= self.create_feature(**kwargs)
      target.add(item)
      return item
    end                         # def create_feature_on

    #
    def create_location(**kwargs)
      override		= {
        game:		self.game
      }
      kwargs		= override.merge(kwargs.merge(owned_by: self.game))
      item		= Location.new([], **kwargs)
      self.game.add(item)
      return item      
    end                         # def create_location

    #
    def create_location_on(target, **kwargs)
      self.validate_container(target, Location)
      kwargs		= kwargs.merge(owned_by: target)
      item		= self.create_location(**kwargs)
      target.add(item)
      return item
    end                         # def create_location_on

    #
    def inspect
      result		= format('#<%s:"%s" name="%s">',
                                 self.class.name,
                                 self.eid.to_s,
                                 self.name.to_s)
      return result
    end                         # def inspect

    #
    # @todo
    #   * Really need to mutex or threadlock the inventories..
    #
    def change_eid(obj=nil, oldeid=nil, neweid=nil, **kwargs)
      obj		||= kwargs[:object]
      oldeid		||= kwargs[:oldeid]
      neweid		||= kwargs[:neweid]
      unless (obj.respond_to?(:eid))
        raise_exception(NotGameElement, obj)
      end
      g			= self.game
      inventories	= g.inventory.select(only: :objects) { |o|
        o.kind_of?(Inventory) && o.keys.include?(oldeid)
      }
      inventories.unshift(self.game.inventory)
      inventories_edited = []
      if (inventories.empty?)
        warn(format("No inventories found containing eid '%s'", oldeid))
      else
        obj.instance_variable_set(:@eid, neweid)
        inventories.each do |i|
          ckobj		= i[oldeid]
          if (ckobj != obj)
            raise_exception(KeyObjectMismatch,
                            oldeid,
                            obj,
                            ckobj,
                            i.name)
          end
          i.delete(oldeid)
          i.add(obj)
          inventories_edited <<	i
        end                     # inventories.each do
      end
      return inventories_edited
    end                         # def change_eid

    #
    def load(*args, **kwargs)
      @elements		||= {}
      if (self.loaded?)
        raise_exception(GameAlreadyLoaded, self)
      end
      if ((loadfile = kwargs[:file]).nil?)
        raise_exception(NoLoadFile)
      end
      begin
        @elements	= YAML.load(File.read(loadfile))
      rescue StandardError => e
        raise_exception(BadLoadFile,
                        file:		loadfile,
                        exception:	e)
      end
      return @elements
    end                         # def load

    nil
  end                           # class Game

  nil
end                             # module TAGF

# Local Variables:
# mode: ruby
# indent-tabs-mode: nil
# eval: (if (intern-soft "fci-mode") (fci-mode 1))
# eval: (auto-fill-mode 1)
# End:
