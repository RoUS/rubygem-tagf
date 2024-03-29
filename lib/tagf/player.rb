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
#if ((! Kernel.const_defined?('TAGF')) \
#    || (! TAGF.ancestors.include?(Contracts::Core)))
#  require('tagf')
#end
require('tagf/mixin/actor')
require('tagf/mixin/dtypes')
require('set')
require('byebug')

# @!macro doc.TAGF.module
module TAGF

  #
  class Player

    #
    include(Mixin::DTypes)
    include(Mixin::Actor)

    # @!macro TAGF.constant.Loadable_Fields
    Loadable_Fields		= {
      'locations'		=> FieldDef.new(
        name:			'locations',
        datatype:		Array[TAGF::Location],
        description:		'Places the player has been',
        internal:		true
      ),
      'facing'			=> FieldDef.new(
        name:			'facing',
        datatype:		String,
        description:		'Which way the player is facing',
        internal:		true
      ),
    }

    # @!macro TAGF.constant.Abstracted_Fields
    Abstracted_Fields		= {
      locations:		Hash[TAGF::Location,Integer],
    }

    #
    # Hash of locations to which the player has been.  The key for
    # each tuple is the location object, and the value is the integer
    # number of times shi's been there.
    #
    # @return [Hash{Location=>Integer}]
    attr_reader(:locations)

    
    #
    # Optional feature if the player faces in a particular direction.
    # Some TAGs give hir a basically 360° panoramic perspective where
    # this doesn't matter or is even considered.
    #
    attr_accessor(:facing)

    # @!method export
    # `Player`-specific export method, responsible for adding any
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
      lochash			= {}
      result['locations']	= lochash
      self.locations.each do |loc,visits|
        pathhash[loc.eid]	= visits
      end
      return result
    end                         # def export

    #
    # Update things when the player moves to a new location.  Update
    # the breadcrumbs (for purposes of returning), add the location to
    # the list of those visited (if necessary), and update the number
    # of visits (useful for occasionally displaying the long
    # description again).
    #
    # @param [Location] place
    #  The {Location} the player has just entered.
    # @option kwargs [Symbol] :nowayback
    #   If set to `true`, the breadcrumb trail is cleared; the player
    #   has gone down a one-way chute or passage and cannot `go back`.
    # @raise [TypeError]
    #   `<class>:<string> is not a location`
    # @return [Location] place
    #
    def visiting(place, **kwargs)
      unless (place.kind_of?(Location))
        raise_exception(TypeError,
                        format('%s:%s is not a location',
                               place.class.name,
                               place.to_s))
      end
      visit_count		= @locations[place].to_i + 1
      @locations[place]		= visit_count
      if (kwargs[:nowayback])
        @breadcrumbs.clear
      end
      @breadcrumbs.push(place) unless (@breadcrumbs.last == place)
      return place
    end                         # def visiting(place)

    # Allows the game to take action depending upon the number of
    # times the player has visited the specified Location.
    #
    # @raise [TypeError]
    #   `<class>:<string> is not a location`
    # @return [Integer]
    #   the number of times (possibly zero) that the player has
    #   visited this location.
    #
    def visits_to(place)
      unless (place.kind_of?(Location))
        raise_exception(TypeError,
                        format('%s:%s is not a location',
                               place.class.name,
                               place.to_s))
      end
      visit_count		= @locations[place].to_i
      return visit_count
    end                         # def visits_to

    #
    def initialize(*args, **kwargs)
      TAGF::Mixin::Debugging.invocation
      @breadcrumbs	= []
      @locations	= {}
      self.initialize_element(*args, **kwargs)
      self.initialize_actor(*args, **kwargs)
      self.game.add(self)
    end                         # def initialize

    nil
  end                           # class Player

  nil
end                             # module TAGF

# Local Variables:
# mode: ruby
# indent-tabs-mode: nil
# eval: (if (intern-soft "fci-mode") (fci-mode 1))
# eval: (auto-fill-mode 1)
# End:
