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

#require('tagf/debugging')
#warn(__FILE__) if (TAGF.debugging?(:file))
require('tagf/mixin/dtypes')
require('tagf/mixin/lightsource')
require('tagf/mixin/universal')
require('tagf/path')
require('byebug')

# @!macro doc.TAGF.module
module TAGF

  # @!macro doc.TAGF.Mixin.module
  module Mixin

    # @!macro doc.TAGF.Mixin.Location.module
    module Location

      include(Mixin::UniversalMethods)
      include(Mixin::DTypes)
      include(Mixin::LightSource)

      # @!macro doc.TAGF.Mixin.module.eigenclass Location
      class << self

        # @!macro doc.TAGF.module.classmethod.included
        def included(klass)
=begin
          whoami		= format('%s eigenclass.%s',
                                         self.name,
                                         __method__.to_s)
          warn(format('%s called for %s',
              	      whoami,
		      klass.name))
=end
          super
          return nil
        end                       # def included(klass)

      end                       # module Location eigenclass

      #
      include(Mixin::Container)

      # @!macro TAGF.constant.Loadable_Fields
      Loadable_Fields		= [
        'paths',
        'light_level',
      ]

      # @!macro TAGF.constant.Abstracted_Fields
      Abstracted_Fields		= {
        paths:			Array[TAGF::Path],
      }

      # @!attribute [r] paths
      # Connexions between Locations are called paths and are
      # described by {Path} objects in the `#paths` hash.  A path
      # hash key is a direction keyword, such as `se` or `down`; the
      # value is the `Path` object that marks where the path
      # leads (the destination), whence it originates (the origin),
      # and whether the player can 'back up.'  (If the destination is
      # at the bottom of a cliff, it's probably not reversible.)
      #
      # @see TAGF::Path
      # @see TAGF::Location
      attr_reader(:paths)

      #
      # @!macro doc.TAGF.classmethod.float_accessor.invoke
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
                            newpath:	self,
                            paths:	estpaths)
          end
        end
        return self
      end                       # def add_path

      #
      def initialize_location(*args, **kwargs)
        TAGF::Mixin::Debugging.invocation
        @paths			= []
        self.is_static!
        self.initialize_container(*args, **kwargs)
        #      self.inventory	= ::TAGF::Inventory.new(game:	self,
        #                                              owned_by: self)
      end                       # def initialize_location

      nil
    end                         # module TAGF::Mixin::Location

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
