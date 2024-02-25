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
require('tagf/mixin/dtypes')
require('tagf/mixin/element')
require('tagf/mixin/universal')
require('tagf/exceptions')
require('tagf/game')
require('tagf/item')
require('tagf/keyword')
require('tagf/location')
require('tagf/npc')
require('tagf/path')
require('tagf/player')
require('byebug')

require('pathname')

# @!macro doc.TAGF.module
module TAGF

  #
  # Class for loading game milieus, or reconstituting saved games,
  # from `YAML` files.
  #
  # Some game objects include direct references, or 'contain,' others;
  # for example, inventories or the connexions between locations.
  # Relationships are <em>via</em> EIDs (Element IDs).  We can't put
  # something into an object until the thing has been created, so we
  # store all these in 'pending' lists until all the objects have been
  # reified.  Then we stitch them together from the 'pending' BOM
  # lists.
  #
  # What an absolutely horrible explanation.
  #
  class Filer

    include(TAGF)
    include(TAGF::Exceptions)
    include(TAGF::Mixin::DTypes)
    include(TAGF::Mixin::UniversalMethods)

    Loadables           = {
      'faction'         => Faction,
      'factions'        => Array[Faction],
      'feature'         => Feature,
      'features'        => Array[Feature],
      'game'            => Game,
      'item'            => Item,
      'items'           => Array[Item],
      'keyword'		=> Keyword,
      'keywords'	=> Array[Keyword],
      'location'        => Location,
      'locations'       => Array[Location],
      'container'       => Container,
      'containers'      => Array[Container],
      'path'            => Path,
      'paths'           => Array[Path],
      'npc'             => NPC,
      'npcs'            => Array[NPC],
      'player'          => Player,
    }

    # @!attribute [r] game
    # Stores the TAGF::Game object that is being [re]loaded, for use
    # elsewhere in the process.
    #
    # @return [TAGF::Game]
    #   the game object created from the `YAML` dataset.
    attr_reader(:game)

    # @!attribute [r] elements
    # A hash of the game element objects created by the #load_game
    # method, keyed by their EIDs.
    #
    # @return [Hash<String=>TAGF::Mixin::Element>]
    attr_reader(:elements)

    # @!attribute [r] elements_processed
    # A hash of
    attr_reader(:elements_processed)

    # @!attribute [r] source
    # Absolute path to the `YAML` file associated with this load
    # sequence.
    #
    # @return [String]
    #   Fully-qualified (absolute) path to `YAML` file from which
    #   definitions are read.  See #load_game.
    attr_reader(:source)

    # @!attribute [r] yamldata
    # Results of parsing the `YAML`-formatted data read from
    # `#source`.
    #
    # @see #source
    # @see #load_game
    #
    # @return [Hash]
    #   The Ruby Hash data structure representing the information
    #   read from the source file.
    attr_reader(:yamldata)

    # @!method load_generic(klass, ekwargs)
    # Create a game element from a class identifier and a set of
    # keyword arguments.  This works for most TAGF objects, but some
    # (like Game itself) require special handling.
    #
    # @param [Class]	klass
    #   The Class used to construct the object.
    # @param [Hash]	ekwargs
    #   Hash of keyword arguments appropriate to the `klass`
    #   constructor.  Keys may be either Symbols (as is usual kwargs
    #   semantics) or Strings.  It is converted to having all-Symbol
    #   keys in order to pass it to the constructor.
    # @return [Object]
    #   the constructed object of class `klass`.
    def load_generic(klass, ekwargs)
      kwargs		= symbolise_kwargs(ekwargs)
=begin
      warn(format("%s: %s(%s,\n  %s",
                  __callee__.to_s,
                  __callee__.to_s,
                  klass.klassname,
                  PP.pp(kwargs, String.new).gsub(%r!\n!, "\n  ")))
=end
      eid		= kwargs[:eid]
      if (self.elements.has_key?(eid))
        raise_exception(TAGF::Exceptions::DuplicateObject,
                        klass.to_s,
                        eid)
      end
      #
      # If there's no :game keyword, or it's a string (EID) and
      # matches our current game context, put the latter into the
      # `kwargs` hash as a cheat/shortcut.
      #
      if (kwargs[:game].nil? \
          || (kwargs[:game] == self.game.eid))
        kwargs[:game]	= self.game
      end
      #
      # Similarly, if there's no :owned_by keyword, or it's a string
      # and matches the game's EID, force the game object into that
      # slot in the kwargs hash.  In other words, any object that
      # doesn't have an explicit owner gets assigned to the game
      # object.
      #
      if (kwargs[:owned_by].nil? \
          || (kwargs[:owned_by] == self.game.eid))
        kwargs[:owned_by]= self.game
      end
      #
      # Okey, call Emmett to do the construction.
      #
      result		= klass.new(**kwargs)
      return result
    end                         # def load_generic

    # @!method load_Location(klass, ekwargs)
    # Create a Location object from a set of keyword arguments.  This
    # type of object requires additional special handling for
    # abstracted fields which aren't simply EID strings.
    #
    # @param [Class]	klass
    #   The Class used to construct the object.  Ignored.
    # @param [Hash]	ekwargs
    #   Hash of keyword arguments appropriate to the `klass`
    #   constructor.  Keys may be either Symbols (as is usual kwargs
    #   semantics) or Strings.  It is converted to having all-Symbol
    #   keys in order to pass it to the constructor.
    # @return [Object]
    #   the constructed Location object.
    def load_Location(klass, ekwargs)
      kwargs		= symbolise_kwargs(ekwargs)
=begin
      warn(format("%s: %s(%s,\n  %s",
                  __callee__.to_s,
                  __callee__.to_s,
                  klass.klassname,
                  PP.pp(kwargs, String.new).gsub(%r!\n!, "\n  ")))
=end
      #
      # Call the generic loader to handle the normal scalar EID string
      # abstractions.
      #
      obj		= load_generic(klass, ekwargs)
      #
      # Now do any :paths we were passed.
      #
      if ((paths = kwargs[:paths]) \
          && (! paths.empty?))
        obj.instance_variable_set(:@paths, paths)
      end
      return obj
    end                         # def load_Location

    # @!method process_definition(klass, ekwargs)
    # Create a game element from a class identifier and a set of
    # keyword arguments.  This works for most TAGF objects, but some
    # (like Game itself) require special handling.
    #
    # @param [Class]	klass
    #   The Class used to construct the object.
    # @param [Hash]	ekwargs
    #   Hash of keyword arguments appropriate to the `klass`
    #   constructor.  Keys may be either Symbols (as is usual kwargs
    #   semantics) or Strings.  It is converted to having all-Symbol
    #   keys in order to pass it to the constructor.
    # @raise [TAGF::Exceptions::NoElementId]
    #   `"missing required :eid keyword argument for element
    #   creation"`
    # @raise [TAGF::Exceptions::DuplicateObject]
    #   EID of element definition matches one that has already been
    #   processed by the loader.
    # @return [Object]
    #   the constructed object of class `klass`.
    def process_definition(klass, ekwargs)
=begin
      warn(format('%s: instantiating a %s',
                  __callee__.to_s,
                  klass.name))
=end
      #
      # Turn a hash that might have String keys into one with Symbol
      # keys so we can use `kwargs` semantics.
      #
      kwargs		= symbolise_kwargs(ekwargs)
      eid		= kwargs[:eid]
      unless (eid.kind_of?(String))
        raise_exception(TAGF::Exceptions::NoElementID,
                        levels: 2)
      end
      #
      # See if any EID in the specification matches one we've
      # already processed.
      #
      if (self.elements.has_key?(eid))
        raise_exception(TAGF::Exceptions::DuplicateObject,
                        self.elements[eid],
                        levels: 2)
      end
      #
      # If there's no :game keyword, or it's a string (EID) and
      # matches our current game context, put the latter into the
      # `kwargs` hash as a cheat/shortcut.
      #
      if (kwargs[:game].nil? \
          || (kwargs[:game] == self.game.eid))
        kwargs[:game]	= self.game
      end
      #
      # Similarly, if there's no :owned_by keyword, or it's a string
      # and matches the game's EID, force the game object into that
      # slot in the kwargs hash.  In other words, any object that
      # doesn't have an explicit owner gets assigned to the game
      # object.
      #
      if (kwargs[:owned_by].nil? \
          || (kwargs[:owned_by] == self.game.eid))
        kwargs[:owned_by]= self.game
      end

      #
      # Figure out how to create the object.
      #
      klassname		= klass.klassname
      loader		= format('load_%s', klassname).to_sym
      if (! self.respond_to?(loader))
        loader		= :load_generic
      end
      #
      # Okey, do it and record our success.  Save the object we
      # created in the #elements hash (keyed by EID) and the
      # definition we used in the #elements_processed array (pushed
      # on the end).
      #
      obj		= self.send(loader, klass, **kwargs)
      self.elements_processed.push(ekwargs)
      self.elements[eid]= obj
      return obj
    end                         # def process_definition

    # @!method reify_generic(obj, flist)
    # Replace abstracted fields in `obj` (<em>i.e.</em>, those
    # containing an EID rather than an object reference) with the
    # appropriate values.  Fields are set with `instance_variable_set`
    # in order to avoid any unknown side-effects.
    #
    # This method should work for most types of game element.
    #
    # @param [TAGF::Mixin::Element] obj
    #   The game element to have its abstracted attributes reified.
    # @param [Hash<Symbol=>Symbol>] flist
    #   A hash of abstracted field symbols and the corresponding
    #   instance-variable symbols.
    # @raise [TAGF::Exceptions::MemberNotFound]
    # @return [TAGF::Mixin::Element]
    #   the original element with all known abstractions replaced.
    def reify_generic(obj, flist)
=begin
      warn(format("%s: %s(%s,\n  %s)",
                  __callee__.to_s,
                  __callee__.to_s,
                  obj.to_key,
                  PP.pp(flist, String.new).gsub(%r!\n!, "\n  ")))
=end
      ahash		= obj.abstracted_fields
      flist.each do |fgetter,fivar|
        ftype		= ahash[fgetter]
        if (ftype != EID)
=begin
          warn(format('%s: abstract field %s of object %s ' \
                      + 'is not an EID; needs refining',
                      __callee__.to_s,
                      fgetter.inspect,
                      obj.to_key))
=end
          next
        end
        fval		= nil
        getter_exc	= nil
        begin
          fval		= obj.send(fgetter)
        rescue NoMethodError => getter_exc
        end
        if (! getter_exc.nil?)
          raise_exception(TAGF::Exceptions::UnknownAttribute,
                          raiser:  __callee__,
                          field:   fgetter,
                          element: obj)
        end
        if (fval.kind_of?(String))
          reifobj	= self.elements[fval]
          if (reifobj.nil?)
            raise_exception(TAGF::Exceptions::MemberNotFound,
                            element:	obj,
                            member:	fval,
                            field:	fgetter)
          end
          obj.instance_variable_set(fivar, reifobj)
        end
      end                       # flist.each
      return obj
    end                         # def reify_generic

    # @!method reify_Path(obj, flist)
    # Replace abstracted fields in `obj` (<em>i.e.</em>, those
    # containing an EID rather than an object reference) with the
    # appropriate values.  Fields are set with `instance_variable_set`
    # in order to avoid any unknown side-effects.
    #
    # This method should work for most types of game element.
    #
    # @param [TAGF::Mixin::Element] obj
    #   The game element to have its abstracted attributes reified.
    # @param [Hash<Symbol=>Symbol>] flist
    #   A hash of abstracted field symbols and the corresponding
    #   instance-variable symbols.
    # @raise [TAGF::Exceptions::MemberNotFound]
    # @return [TAGF::Mixin::Element]
    #   the original element with all known abstractions replaced.
    def reify_Path(obj, flist)
=begin
      warn(format("%s: %s(%s,\n  %s)",
                  __callee__.to_s,
                  __callee__.to_s,
                  obj.to_key,
                  PP.pp(flist, String.new).gsub(%r!\n!, "\n  ")))
=end
      flist.each do |fgetter,fivar|
        fval		= nil
        getter_exc	= nil
        begin
          fval		= obj.send(fgetter)
        rescue NoMethodError => getter_exc
        end
        if (! getter_exc.nil?)
          raise_exception(TAGF::Exceptions::UnknownAttribute,
                          field:   fgetter,
                          element: obj)
        end
        if (fval.kind_of?(String))
          reifobj	= self.elements[fval]
          if (reifobj.nil?)
            raise_exception(TAGF::Exceptions::MemberNotFound,
                            raiser:	__callee__,
                            element:	obj,
                            member:	fval,
                            field:	fgetter)
          end
          obj.instance_variable_set(fivar, reifobj)
        end
      end                       # flist.each
      #
      # Re-own Path objects from the game to the origin
      # Location.
      #
      if (obj.owned_by == self.game)
        obj.owned_by	= obj.origin
      end
      return obj
    end                         # def reify_Path

    # @!method reify_Location(obj, flist)
    # Replace abstracted fields in `obj` (<em>i.e.</em>, those
    # containing an EID rather than an object reference) with the
    # appropriate values.  Fields are set with `instance_variable_set`
    # in order to avoid any unknown side-effects.
    #
    # This method should work for most types of game element.
    #
    # @param [TAGF::Mixin::Element] obj
    #   The game element to have its abstracted attributes reified.
    # @param [Hash<Symbol=>Symbol>] flist
    #   A hash of abstracted field symbols and the corresponding
    #   instance-variable symbols.
    # @raise [TAGF::Exceptions::MemberNotFound]
    # @return [TAGF::Mixin::Element]
    #   the original element with all known abstractions replaced.
    def reify_Location(obj, flist)
=begin
      warn(format("%s: %s(%s,\n  %s)",
                  __callee__.to_s,
                  __callee__.to_s,
                  obj.to_key,
                  PP.pp(flist, String.new).gsub(%r!\n!, "\n  ")))
=end
      #
      # We're reconsituting the paths to other locations.  It's an
      # array rather than a scalar, which is why we have this
      # Location-specific reification method.
      #
      fgetter		= :paths
      fivar		= flist[fgetter]
      vlist		= obj.send(fgetter) || []
      varray		= []
      vlist.each do |cxeid|
        cxobj		= self.elements[cxeid]
        if (cxobj.nil?)
          raise_exception(TAGF::Exceptions::MemberNotFound,
                          element:	obj,
                          member:	cxeid,
                          field:	fgetter)
        end
        varray.push(cxobj)
      end                       # vlist.each do

      #
      # We've restored what we can of the paths, so update the
      # location's field and move on to the next field to reify.
      #
      obj.instance_variable_set(:@paths, varray)
      return obj
    end                         # def reify_Location

    # @!method reify_elements
    # Go through the game element objects in #elements and fill in
    # abstracted fields containing EIDs with references to the actual
    # objects.  If there is an element-specific reifier method, invoke
    # that after calling the one that handles the usual EID
    # abstractions.
    def reify_elements
=begin
      warn(format('%s: beginning',
                  __callee__.to_s))
=end
      elist		= self.elements.values.sort { |a,b|
        a.to_key <=> b.to_key
      }
      etype		= nil
      #
      # @todo
      #   This section does a lot of unnecessary repetition; abstract
      #   it out.
      # @todo
      #   Raise an exception if there's no object matching the EID
      #   string in any of the abstracted fields.
      #
      absfields		= nil
      reifier		= nil
      elist.each do |obj|
        ahash		= obj.abstracted_fields
        if (obj.class != etype)
          absfields	= ahash.keys.inject({}) { |memo,f|
            memo[f.to_sym]= format('@%s', f.to_s).to_sym
            memo
          }
          reifier	= format('reify_%s', obj.klassname).to_sym
          if (! self.respond_to?(reifier))
            reifier	= nil
          end
          etype		= obj.class
        end
        #
        # Do the EIDs, since *we* know how.
        #
        self.reify_generic(obj, absfields)
        #
        # If there are element-specific abstractions to reify, call
        # the appropriate method.
        #
        self.send(reifier, obj, absfields) if (reifier)
      end                       # self.elements.each do
      return self.elements
    end                         # def reify_elements

    # @!method load_game(file)
    # Primary method for loading a game from its original
    # definition, or a saved game.
    #
    # @param [String] file
    #   Filesystem path to the `YAML` file from which to load
    #   definitions.
    # @raise [TAGF::Exceptions::DataError]
    #   if `YAML.load` raised an exception parsing the source.  The
    #   parsing exception message is included in the message.
    # @raise [TAGF::Exceptions::DataError]
    #   `'…no "game" key found'`
    #   if the `YAML` file doesn't have a top-level `"game"` key.
    # @raise [TAGF::Exceptions::DataError]
    #   <tt>'…unknown game element "<em>YAML-key</em>"'</tt>
    #   if a top-level key is found in the `YAML` file which is
    #   <strong>not</em> in the {Loadables} keyword list.
    # @return [TAGF::Game]
    #   the game object, which is the root of all objects comprising
    #   the game environment.
    def load_game(file)
=begin
      warn(format('%s: %s(%s)',
                  __callee__.to_s,
                  __callee__.to_s,
                  file))
=end
      #
      # Invoking this method discards anything from any previous
      # invocation, starting a new game context.
      #
      @game		= nil
      @elements		= {}
      @elements_processed= []
      @yamldata		= nil
      #
      # Figure out the full path to the source file.  Makes
      # reporting problems less fraught with "what the hell?"
      # moments.
      #
      fname		= Pathname.new(file).expand_path
      @source		= File.absolute_path(fname)
      #
      # Time to load the doughnuts..  instance variable `@yamldata`
      # will hold the parsed data.  Local variable `ydata` will hold
      # a copy, which will be edited to remove processed definitions
      # as we walk through it.
      #
      fdata		= nil
      File.open(self.source, 'r') do |fio|
        fdata		= fio.read
      end
      #
      # This weird stuff is because raising an exception in a rescue
      # block automatically attaches the original exception in the
      # #cause attribute, which makes the output really messy and
      # confusing.  All we want is the basic parse error, so we make
      # it available outside the begin/end block so it won't be
      # auto-attached.
      #
      parse_exc		= nil
      begin
        @yamldata	= YAML.load(fdata)
      rescue StandardError => parse_exc
        debugger
      end
      #
      # Now, if there was a parse error, report it under our own
      # exception.
      #
      if (parse_exc)
        raise_exception(TAGF::Exceptions::DataError,
                        source: self.source,
                        error:  parse_exc.to_s)
      end
      #
      # We're good to go!
      #
      ydata		= @yamldata.dup
      #
      # Find the game definition, from which all else follows.
      #
      gamedef		= ydata.delete('game')
      if (gamedef.nil?)
        raise_exception(TAGF::Exceptions::DataError,
                        source: self.source,
                        error:  'no "game" key found')
      end
      #
      # YAML keys are strings; convert them to symbols, since that's
      # what we use internally.
      #
      kwargs		= symbolise_kwargs(gamedef)
=begin
      warn(format('%s: instantiating game [%s]<%s>',
                  __callee__.to_s,
                  kwargs[:eid].to_s,
                  kwargs[:name].to_s))
=end
      @game		= TAGF::Game.new(**kwargs,
                                         loadfile: @source)
      self.elements_processed.push(gamedef)
      self.elements[@game.eid]= @game
      #
      # Now do the rest..
      #
      while ((defkey,defobj) = ydata.first) do
        etype		= Loadables[defkey]
#        debugger if (%w[ factions locations ].include?(defkey))
        if (etype.nil?)
          raise_exception(DataError,
                          source: self.source,
                          error:  format('unknown game element "%s"',
                                         defkey))
        end
        #
        # `etype` might be a class, an array, or a hash.  If an
        # array, `etype.first` describes how each element of the
        # array should be handled.  If `etype` is a hash.. well, it
        # gets handled specially.
        #
        if (etype.kind_of?(Array) \
            && defobj.kind_of?(Array) \
            && defobj.empty?)
          #
          # Got a keyword that takes an array, but the array of
          # definitions is empty.  Skip by doing nothing and advancing
          # to the next key in the `ydata` hash.
          #
          nil
        elsif (etype.kind_of?(Class) \
               && defobj.kind_of?(Hash))
          #
          # A singleton instance definition.
          #
          klass		= etype
=begin
          warn(format('loading: element is an instance of %s',
                      klass.name))
=end
          self.process_definition(klass, defobj)
        elsif (etype.kind_of?(Array) \
               && defobj.kind_of?(Array) \
               && defobj[0].kind_of?(Hash))
          #
          # An array of instance definition hashes for class
          # `etype[0]`.
          #
          klass		= etype.first
=begin
          warn(format('loading: element is an array of %s',
                      klass.to_s))
=end
          #
          # Loop through the array of definitions, instantiating
          # each in turn.
          #
          defobj.each do |elt|
            self.process_definition(klass, elt)
          end
        elsif (etype.kind_of?(Hash))
          warn(format('%s: skipping element "%s": Hash: %s',
                      __callee__.to_s,
                      defkey,
                      etype.inspect))
        else
          warn(format('%s: skipping element "%s": UNKNOWN: %s => %s',
                      __callee__.to_s,
                      defkey,
                      etype.inspect,
                      defobj.class.to_s))
        end
        #
        # We're done with this definition; remove it from the hash of
        # objects to do.  `ydata` is a hash, so we have to use #delete
        # rather than #shift.
        #
        ydata.delete(defkey)
      end                       # while ((defkey,defobj) = ydata.first)

      #
      # Now go through the elements we created and replace any string
      # EIDs with the objects, as described by the result from
      # #abstracted_fields for each object.
      #
      self.reify_elements
      return self.game
    end                         # load_game(file)

    nil
  end                           # class Filer

  nil
end                             # module TAGF

# Local Variables:
# mode: ruby
# indent-tabs-mode: nil
# eval: (if (intern-soft "fci-mode") (fci-mode 1))
# eval: (auto-fill-mode 1)
# End:
