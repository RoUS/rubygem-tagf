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
require('tagf/mixin/container')
require('tagf/mixin/graphable')
require('tagf/mixin/universal')
require('tagf/path')
require('rgl/adjacency')
require('rgl/edge_properties_map')
require('byebug')

# @!macro doc.TAGF.module
module TAGF

  #
  class Location

    #
    include(Mixin::UniversalMethods)
    include(Mixin::DTypes)
    include(Mixin::Container)
    include(Mixin::Graphable)

    # @!macro TAGF.constant.Loadable_Fields
    Loadable_Fields		= {
      'paths'			=> FieldDef.new(
        name:			'paths',
        datatype:		Array[TAGF::Path],
        description:		'Paths to/from this location',
        internal:		true
      ),
      'light_level'		=> FieldDef.new(
        name:			'light_level',
        datatype:		Float,
        description:		'Light level for location'
      ),
    }

    # @!macro TAGF.constant.Abstracted_Fields
    Abstracted_Fields		= {
      paths:			Array[TAGF::Path],
    }

    # @!attribute [r] paths
    # Connexions between Locations are called paths and are described
    # by {Path} objects in the `#paths` array.  Each Path object
    # identifies whence it originates (the origin), where the path
    # leads (the destination), and whether the player can 'back up.'
    # Every Path object in a Location's #paths array should have a
    # Path#origin referencing this Location object.
    #
    # @see TAGF::Path
    #
    # @return [Array<TAGF::Path>]
    attr_reader(:paths)

    # @!attribute [rw] light_level
    # @!macro doc.TAGF.classmethod.float_accessor.invoke
    #
    # @return [Float]
    #   the current ambient light level, from 0.0 to 100.0.
    float_accessor(:light_level)

    # @!method distance_to(loc, **kwargs)
    # Return the smallest number of moves from this location to
    # `loc`.
    #
    # @return [Integer]
    def distance_to(loc)

    end                       # def distance_to(loc, **kwargs)

    # @!method add_path(*args, **kwargs)
    # Add a path from the current location to another.  Keyword
    # argument values override any corresponding order-dependent
    # ones.  Any acceptable argument combination that conflicts with
    # the value of the `via` field in the Path object will
    # override it, and cause the latter to be overwritten with a
    # warning.
    #
    # 1. `add_path(Path)`
    #    : The `via` direction for the path is extracted from the
    #      Path object.
    # 2. `add_path("up", Path)`
    #    : The `"up"` argument overrides <strong>and
    #      overwrites</strong> any `:via` field in the Path
    #      object.  If this occurs, a warning is issued.
    #
    # @param [Array]			args
    #   One or more Path objects.
    # @param [Hash<Symbol=>Any>]	kwargs
    #   Currently ignored.
    # @return [Location] self
    def add_path(*args, **kwargs)
      args.each do |path|
        if (! path.kind_of?(TAGF::Path))
          raise_exception(UnsupportedObject,
                          object:	path,
                          operation:	__callee__)
        end
        all_paths	= self.paths
        if (estpaths = path.conflicts(*all_paths))
          raise_exception(TAGF::Exceptions::ConflictingPath,
                          newpath:	path,
                          paths:	estpaths)
        end
        self.paths.push(path) unless (self.paths.include?(path))
      end
      return self
    end                       # def add_path

    # @!method incoming
    # Return an array of all Path elements that list the receiver as
    # the origin.
    #
    # @return [Array<TAGF::Path>]
    def incoming
      result		= game.filter(klass: Path).select { |o|
        (o.destination == self)
      }
      return result
    end                         # def incoming

    # @!method outgoing
    # Return an array of all Path elements that list the receiver as
    # the origin.
    #
    # @return [Array<TAGF::Path>]
    def outgoing
      result		= game.filter(klass: Path).select { |o|
        (o.origin == self)
      }
      return result
    end                         # def outgoing

    # @!method export
    # `Location`-specific export method, responsible for adding any
    # unusual fields that need to be abstracted to the export hash.
    # That is, things that can't be simply boiled down to a string
    # EID.
    #
    # @return [Hash<String=>Any>]
    #   the updated export hash.
    def export
      result			= nil
      begin
        result			= super
      rescue NoMethodError
        result			= {}
      end
      pathlist			= [] | self.paths.map { |p| p.eid }
      result['paths']		= pathlist
      return result
    end                         # def export

    InventoryItemFormat		= 'There is %<article>s %<desc>s here.'

    #
    # @!macro doc.TAGF.formal.kwargs
    # @return [Location] self
    #
    def initialize(*args, **kwargs)
      TAGF::Mixin::Debugging.invocation
      @paths			= []
      self.static!
      self.visible!
      self.initialize_element(*args, **kwargs)
      self.initialize_container(*args, **kwargs)
      self.game.add(self)
    end                         # def initialize

    nil
  end                           # class Location

  nil
end                             # module TAGF

# Local Variables:
# mode: ruby
# indent-tabs-mode: nil
# eval: (if (intern-soft "fci-mode") (fci-mode 1))
# eval: (auto-fill-mode 1)
# End:
