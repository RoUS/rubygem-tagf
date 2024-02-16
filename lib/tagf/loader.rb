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
require('byebug')

# @!macro doc.TAGF.module
module TAGF

  Loadables		= {
    'faction'		=> Faction,
    'factions'		=> Array[Faction],
    'feature'		=> Feature,
    'features'		=> Array[Feature],
    'game'		=> Game,
    'item'		=> Item,
    'items'		=> Array[Item],
    'location'		=> Location,
    'locations'		=> Array[Location],
    'connexion'		=> Connexion,
    'connexions'	=> Array[Connexion],
    'path'		=> Hash[String,Connexion],
    'paths'		=> Array[Hash[String,Connexion]],
    'npc'		=> NPC,
    'npcs'		=> Array[NPC],
    'player'		=> Player,
  }

  #
  # Objects which are referenced in YAML by EID, but which need to be
  # reconstituted to the objects <em>with</em> those EIDs on load.
  # Connexions (links between locations) and inventories are handled
  # explicitly due to their complexity.
  #
  Dessicates		= %Q[
    faction
    game
    owned_by
  ]

  #
  # Class for loading game milieus, or reconstituting saved games,
  # from YAML files.
  #
  # Some game objects include direct references, or 'contain,' others.
  # For example, inventories or the connexions between locations.
  # Relationships are via EIDs (Element IDs).  We can't put something
  # into an object until the thing has been created, so we store all
  # these in 'pending' lists until all the objects have been reified.
  # Then we stitch them together from the 'pending' BOM lists.
  #
  # What an absolutely horrible explanation.
  #
  class Loader

    extend(TAGF::Mixin::DTypes)
    include(TAGF::Mixin::UniversalMethods)

    # @!attribute [r] game
    # Stores the TAGF::Game object that is being [re]loaded, for use
    # elsewhere in the process.
    # @return [TAGF::Game]
    attr_reader(:game)

    attr_reader(:elements)

    attr_reader(:elements_created)

    def load_generic(klass, **kwargs)
      kwargs		= symbolise_kwargs(**kwargs)
      result		= klass.new(**kwargs)
      return result
    end                         # def load_generic

    def load_game(file)
      @game		= nil
      @elements		= []
      @elements_created	= {}
      @ydata		= nil
      fdata		= nil
      File.open(file, 'r') do |fio|
        fdata		= fio.read
      end
      @ydata		= YAML.load(fdata)
      #
      # Find the game definition, from which all else follows.
      #
      debugger
      gamedef		= @ydata.delete('game')
      if (gamedef.nil?)
        raise_exception(RuntimeError,
                        format('no game key for file %s',
                               file))
      end
      #
      # YAML keys are strings; convert them to symbols, since that's
      # what we use internally.
      #
      kwargs		= symbolise_kwargs(gamedef)
      @game		= TAGF::Game.new(**kwargs)
      self.elements_created[@game.eid] = gamedef
      self.elements.push(@game)
      #
      # Now do the rest..
      #
      while ((defkey,defobj) = @ydata.first) do
        etype		= Loadables[defkey]
        if (etype.nil?)
          raise_exception(RuntimeError,
                          format('unknown game element "%s" ' \
                                 + 'in file %s',
                                 defkey,
                                 file))
        end
        #
        # `etype` might be a class, an array, or a hash.  If an array,
        # `etype.first` describes how each element of the array should
        # be handled.  If `etype` is a hash.. well, it gets handled
        # specially.
        #
        if (etype.kind_of?(Class))
          warn(format('loading: element is an instance of %s',
                      etype.name))
          if (self.elements_created.has_key?(defobj['eid']))
            raise_exception(TAGF::Exceptions::DuplicateObject,
                            self.elements_created[defobj['eid']])
          end
          obj		= nil
          kwargs	= symbolise_kwargs(defobj)
          debugger
          if (kwargs[:game].nil? \
              || (kwargs[:game] == self.game.eid))
            kwargs[:game]= self.game
          end
          if (kwargs[:owned_by].nil? \
              || (kwargs[:owned_by] == self.game.eid))
            kwargs[:owned_by]= self.game
          end
          klassname	= etype.name.sub(%r!^.*::!, '')
          loader	= format('load_%s', klassname).to_sym
          if (self.respond_to?(loader))
            obj		= self.send(loader, **kwargs)
          else
            obj		= self.load_generic(etype, **kwargs)
          end
          self.elements_created[kwargs[:eid]] = defobj
          self.elements.push(obj)
        elsif (etype.kind_of?(Array))
          warn(format('skipping: element is an array of %s',
                      etype.first.name))
        elsif (etype.kind_of?(Hash))
          warn(format('skipping: element is a hash: %s',
                      etype.inspect))
        else
          warn(format('skipping: element is UNKNOWN: %s',
                      etype.inspect))
        end
        @ydata.delete(defkey)
      end

      #
      # For each type of object we load, check loadable fields, merged
      # from
      #   object.class.ancestors.select { |o|
      #     o.const_defined?('Loadable_Fields', false)
      #   }
      #     .map { |k| k.const_get('Loadable_Fields', false) }
      #     .reduce(&:|) # (or .flatten.uniq ?)
      #
    end
  end                           # class TAGF::Loader

  nil
end                             # module TAGF

# Local Variables:
# mode: ruby
# indent-tabs-mode: nil
# eval: (if (intern-soft "fci-mode") (fci-mode 1))
# eval: (auto-fill-mode 1)
# End:
