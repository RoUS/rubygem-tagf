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
require('tagf/exceptions')
require('tagf/mixin/container')
require('tagf/mixin/debugging')
require('tagf/mixin/dtypes')
require('rgl/adjacency')
require('psych')
require('yaml')
require('byebug')

# @!macro doc.TAGF.module
module TAGF

  #
  class Game

    #
    include(Mixin::DTypes)
    #
    include(Mixin::Container)

    #
    extend(Forwardable)
    include(Exceptions)
    include(Mixin::Debugging)
    include(Mixin::Graphable)

    # @!macro TAGF.constant.Loadable_Fields
    Loadable_Fields		= {
      'author'			=> FieldDef.new(
        name:			'author',
        datatype:		String,
        description:		"Author's name"
      ),
      'copyright'		=> FieldDef.new(
        name:			'copyright',
        datatype:		String,
        description:		('Explicit copyright ' +
                                 '(else calculated)')
      ),
      'copyright_year'		=> FieldDef.new(
        name:			'copyright_year',
        datatype:		String,
        description:		('Explicit copyright year or years ' +
                                 '(else calculated)')
      ),
      'licence'			=> FieldDef.new(
        name:			'licence',
        datatype:		String,
        description:		'Name of the licence for the game'
      ),
      'version'			=> FieldDef.new(
        name:			'version',
        datatype:		String,
        description:		"This game's version"
      ),
      'date'			=> FieldDef.new(
        name:			'date',
        datatype:		String,
        description:		'Date or version release'
      ),
      'start_pos'		=> FieldDef.new(
        name:			'start_pos',
        datatype:		String,
        description:		'EID of starting location'
      ),
    }

    # @!macro TAGF.constant.Abstracted_Fields
    Abstracted_Fields		= {
      start:			EID,
    }

    # Make all the TAGF::Settings instance attributes accessible
    # through the Game object.
    [*GAME_FLAGS, *GAME_FLAG_GROUPS.keys].uniq.compact.each do |fsym|
      fstr		= fsym.to_s
      getter		= fsym
      query		= format('%s?', fstr).to_sym
      forcer		= format('%s!', fstr).to_sym
      setter		= format('%s=', fstr).to_sym
      def_delegators(:@settings, getter, query, forcer, setter)
    end
    GAME_SETTINGS.keys.each do |ssym|
      sstr		= ssym.to_s
      getter		= ssym
      setter		= format('%s=', sstr).to_sym
      def_delegators(:@settings, getter, setter)
    end

    # Eigenclass for the main Game class.
    class << self

      # @!method load(file)
      # Loads a game's components from a `YAML` definition file and
      # returns the [re]constituted game object.
      #
      # Basically front-ends TAGF::Filer#load_game.
      #
      # @return [TAGF::Game]
      def load(file)
        filer		= TAGF::Filer.new
        game		= filer.load_game(file)
        return game
      end                       # def load(file)

    end                         # Eigenclass for TAGF::Game

    # @!attribute [rw] author
    # The game's author's identity, in free-form text.  Name,
    # pseudonym, eddress, galactic coödinates, whatever — all are
    # grist here.
    #
    # @return [String]
    #   the identity of the game's author.
    attr_accessor(:author)

    # @!attribute [rw] copyright_year
    # The year (or years) for which copyright has been asserted for
    # this game content.  Can be an integer or a string; multiple
    # years or a span can be specified with commas and brackets.
    #
    # @return [String]
    attr_accessor(:copyright_year)
    def copyright_year
      result		= @copyright_year
      if (result.nil?)
        result		= format('%04i', Time.new.year)
      end
      return result
    end                         # def copyright_year
    def copyright_year=(value)
      if (value.kind_of?(Integer))
        value		= format('%04s', value)
      end
      unless (value.kind_of?(String))
        raise_exception(ArgumentError,
                        'copyright year must be a string ' \
                        + 'or an integer')
      end
      @copyright_year	= value
    end                         # def copyright_year=(value)

    # @!attribute [rw] copyright
    # The copyright notice for this game.  If not set, attempts to
    # read it will return a string calculated from the values of
    # #author and #copyright_year.
    #
    # @return [String]
    #   the explicit or calculated copyright notice line.
    attr_accessor(:copyright)
    def copyright
      return @copyright if (@copyright)
      author		= self.author || '<unknown>'
      result		= format('Copyright © %s by %s',
                                 self.copyright_year,
                                 author)
      return result
    end                         # def copyright

    #
    attr_accessor(:licence)
    alias_method(:license, :licence)
    alias_method(:license=, :licence=)

    #
    attr_accessor(:version)

    #
    attr_accessor(:date)

    attr_reader(:settings)

    attr_reader(:graphinfo)

    attr_accessor(:keywords)

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

    # @!attribute start
    # @return [TAGF::Location]
    #   the nominal starting location for new players in a new game.
    attr_accessor(:start)

    #
    attr_reader(:creation_overrides)
    protected(:creation_overrides)

    # This is the game object; its inventory is the master registry
    # for all elements in the game.  Make Inventory#filter available
    # directly so we don't have to do all sorts of
    # `game.inventory.filter` nonsense.
    def_delegator(:@inventory, :filter)

    # @!method export_game
    # @return [Hash<String=>Any>]
    def export_game
      xsettings		= self.settings.export_settings
      result		= {
        'game'		=> self.export.merge(xsettings),
      }
      elements		= {}
      TAGF::Filer::Loadables.each do |k,v|
        if (v.kind_of?(Array))
          elements[v[0]] = k
          result[k]	= []
        end
      end
      #
      # Now go through the master inventory and export all exportable
      # elements to the result hash.
      #
      self.inventory.each(only: :objects) do |obj|
        etype		= elements[obj.class]
        next if (etype.nil?)
        result[etype].push(obj.export)
      end
      return result
    end                         # def export_game

    # @!method keyword(kw, **kwargs)
    #
    # @param [String]			kw
    #   The string for which to search the keyword list.  A keyword
    #   element matches if `kw` either equals its `:root` attribute or
    #   is included in its `:alii` array.
    # @param [Hash<Symbol=>Any>]	kwargs
    #   Keyword arguments hash.
    # @option kwargs [Boolean]		:required
    #   If `true`, an exception will be raised if no match can be
    #   found.  If `false`, the return value will be `nil` to signify
    #   that `kw` wasn't found.
    # @raise [RuntimeError]
    #   if more than one registered keyword element claims ownership
    #   of `kw`
    # @return [nil]
    #   if no keyword element was found that 'owns' the keyword (or
    #   alias)
    # @return [TAGF::Keyword]
    #   the keyword element that 'owns', as the definitive keyword or
    #   as an alias, the word in `kw`
    def keyword(kw, **kwargs)
      keywords		= self.filter(klass: TAGF::Keyword)
      keywords		= keywords.select { |o|
        [ o.root, *o.alii ].include?(kw)
      }
      if (keywords.nil? || keywords.empty?)
        if (kwargs[:required])
          #
          # Is the expectation that this keyword must already be
          # defined?  If so, it ain't there, so complain.
          #
          raise_exception(RuntimeError,
                          format('%s: cannot find keyword "%s"',
                                 __callee__.to_s,
                                 kw))
        else
          return nil
        end
      elsif (keywords.count != 1)
        raise_exception(RuntimeError,
                        format('%s: multiple (%i) keywords ' \
                               + 'define "%s"',
                               __callee__.to_s,
                               keywords.count,
                               kw))
      end
      return [ *keywords ][0]
    end                         # def keyword(kw)

    #
    # Constructor for the main element of this entire project -- the
    # <strong>Game</strong> object.  Every element, including this
    # one, <em>must</em> have the following attributes:
    #
    # * `#game`
    #   : a link to the main Game object (an instance of this class).
    # * `#eid`
    #   : a unique identifier that is used to locate the element in
    #     the various inventories -- particularly the master, which is
    #     the inventory of the Game object.  The <em>`eid`</em> can be
    #     any class of object, but short strings without any
    #     whitespace are recommended.  See Mixin::Element#eid
    # * `#owned_by`
    #   : the object in whose inventory the element is listed.
    #     <em>Every</em> element is listed in the master inventory,
    #     but each may also appear in one additional inventory -- such
    #     as that of a pouch, or a backpack, or a Location or Feature.
    #
    # The arguments to Game#initialize are passed down to other
    # constructors and methods.  They may be modified slightly by each
    # callee in turn, so the order of invocation can be important.
    #
    # @param [Array]			args		([])
    #   an optional array of order-dependent arguments.  Not used by
    #   Game#initialize.
    # @param [Hash<Symbol=>Object>]	kwargs		({})
    #   a hash with symbolic keys that are either used to identify
    #   attributes to be set to the corresponding values, flags,
    #   control instructions, or other tuples intended for methods and
    #   constructors Game#initialize may invoke.
    # @option kwargs [Symbol]		:eid		(nil)
    #   This should be a simple string; it is recommended that you use
    #   a word or portmanteau that identifies the game itself (such as
    #   `adventure` or `zork`), since the eid can be used to pick the
    #   appropriate set of definitions out of a YAML file.  (See
    #   #load)
    # @option kwargs [Symbol]		:owned_by	(nil)
    #   For a Game object, the <em>`owned_by`</em> attribute is
    #   unequivocally set to the Game object itself.  That is, the
    #   game owns itself.  For other objects created by this
    #   constructor, this tupe may be passed through from the caller,
    #   or overridden by Game#initialize as appropriate.
    # @option kwargs [Symbol]		:loadfile	(nil)
    #   The filesystem path to the default YAML file from which the
    #   game's definitions will be loaded.  If this isn't set as part
    #   of the constructor invocation, it will need to be set
    #   explicitly or specified on a call to the #load method.
    # @option kwargs [Symbol]		:name		(nil)
    # @option kwargs [Symbol]		:desc		(nil)
    # @option kwargs [Symbol]		:shortdesc	(nil)
    # @return [Game]
    #   self
    def initialize(*args, **kwargs)
      TAGF::Mixin::Debugging.invocation
      #
      # Set up the game-wide settings..
      #
      settings		= kwargs.delete(:settings) || {}
      @settings		= TAGF::Settings.new(**settings)
      #
      # Set up the descriptive digraph object.  We don't need to have
      # any particular attributes set in order to do this; just the
      # game instance itself.
      #
      @graphinfo	= GraphInfo.new(self)
      #
      # Now start filling in our attributes from the method arguments.
      #
      @creation_overrides = {
        game:		self,
        owned_by:	self,
        visible:	false,  # Everything we create here is metadata
      }
      kwargs		= kwargs.merge(self.creation_overrides)
      self.game		= kwargs[:game] || self
      self.owned_by	= kwargs[:game] || self
      kwargs.delete(:eid) if (@eid = kwargs[:eid])
      kwargs.delete(:name) if (self.name = kwargs[:name])
      @eid		||= format('game-%i', self.object_id.to_i)
      self.name		||= ''
      self.static!
      self.initialize_element(*args, **kwargs)
      self.initialize_container(*args,
                                **kwargs,
                                inventory_eid: 'master_inventory')
      self.add(self)
      self.allow_containers!
=begin
      @graph		= GraphViz.new(:TAGF,
                                       type:	:digraph,
                                       label:	format('Game: %s',
                                                       self.name))
=end
    end                         # def initialize

    # @todo
    #   See about doing this with Forwardable instead?
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

    # @todo
    #   See about replacing this with Forwardable.
    def [](*args)
      return @inventory.send(__method__, *args)
    end                         # def []

    # @todo
    #   See about replacing this with Forwardable.
    def each(*args, **kwargs, &block)
      return @inventory.send(__method__, *args, **kwargs, &block)
    end                         # def each(*args, **kwargs, &block)

    # @todo
    #   See about replacing this with Forwardable.
    def find(*args, **kwargs, &block)
      return @inventory.send(__method__, *args, **kwargs, &block)
    end                         # def find(*args, **kwargs, &block)

    # @todo
    #   See about replacing this with Forwardable.
    def map(*args, **kwargs, &block)
      return @inventory.send(__method__, *args, **kwargs, &block)
    end                         # def map(*args, **kwargs, &block)

    # @todo
    #   See about replacing this with Forwardable.
    def select(*args, **kwargs, &block)
      return @inventory.send(__method__, *args, **kwargs, &block)
    end                         # def select(*args, **kwargs, &block)

    # @param [Object] target
    #   the game element being tested for containerness.
    # @raise [TAGF::Exceptions::NotAContainer]
    #   if <em>target</em> isn't a container but something
    #   containerish is being attempted on it.
    # @raise [TAGF::Exceptions::AlreadyHasInventory]
    # @raise [TAGF::Exceptions::ImmovableElementDestinationError]
    # @return [void]
    def validate_container(target, newcontent, **kwargs)
      unless (TAGF.game_element?(target))
        raise_exception(NotGameElement, target)
      end
      unless (target.container?)
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
      unless (TAGF.game_element?(newcontent))
        raise_exception(NotGameElement, newcontent)
      end
      if (newcontent.static? && (! target.static?))
        raise_exception(ImmovableElementDestinationError,
                        target,
                        newcontent)
      end
      return nil
    end                         # def validate_container(target, newcontent, **kwargs)
    protected(:validate_container)

    #
    def create_inventory_on(target, **kwargs)
=begin
      warn(format("%s#%s(%s,\n  %s)",
                  self.klassname,
                  __callee__.to_s,
                  target.to_key,
                  PP.pp(kwargs, String.new).gsub(%r!\n!, "\n  ")))
=end
      self.validate_container(target, Inventory)
      kwargs		= kwargs.merge(self.creation_overrides)
      kwargs[:owned_by]	= target
      inventory_eid	= format('Inventory[%s]', target.to_key)
      target.inventory	= Inventory.new(**kwargs,
                                        inventory_eid: inventory_eid)
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
