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
require('tagf/mixin/universal')
require('tagf/exceptions')
require('tagf/mixin/element')
require('forwardable')
require('byebug')

# @!macro doc.TAGF.module
module TAGF

  # @!macro doc.TAGF.Mixin.module
  module Mixin

    # Module providing mixed-in aspects for elements that can provide
    # light.
    module LightSource

      include(Mixin::DTypes)
      include(Mixin::UniversalMethods)

      # @!macro TAGF.constant.Loadable_Fields
      Loadable_Fields		= [
        #
        # If this element has any lighting attributes, what are they?
        #
        'illumination',
        'pct_dim_per_turn',
        'only_dim_near_player',
      ]

      # @!attribute [rw] lit
      # @!macro doc.TAGF.classmethod.flag.invoke
      # Whether or not this light source is actually illuminated and
      # shedding light.  Light sources which are not lit don't consume
      # fuel, nor are they affected by the 'amount to dim <em>perM
      #
      # @return [Boolean]
      #   `true` if this element is actually currently providing
      #   light.
      flag(:lit)

      # @!attribute [rw] illumination
      # @!macro doc.TAGF.classmethod.float_accessor.invoke
      # Whether or not this light source is actually illuminated and
      # shedding light.  Light sources which are not lit don't consume
      # fuel, nor are they affected by the 'amount to dim <em>perM
      # The amount of illumination provided by this element, based on
      # a 0.0—100.0 scale.  Values less than 0.0 are maxed to zero,
      # but values can be larger than 100.0 to indicate really, really
      # bright lighting.
      #
      # @return [Float]
      #   the level of light currently being provided.
      float_accessor(:illumination)
      alias_method(:_illumination=, :illumination=)
      private(:_illumination=)
      def illumination=(fval)
        if (fval.respond_to?(:to_f))
          fval		= [0.0, fval].max
        end
        return self._illumination=(fval)
      end                       # def illumination=(fval)

      # @!attribute [rw] pct_dim_per_turn
      # @!macro doc.TAGF.classmethod.float_accessor.invoke
      # Intended for use with elements that gradually grow dimmer over
      # time, in a linear progression.  The value is how much,
      # percentage-wise, that the value of #illumination is
      # automatically decreased on each turn.  The percentage is a
      # fixed value by which #illumination will be descreased, not a
      # percentage of its current value.  That way lies Zeno.
      #
      # @see #fuel
      # @see #fuel_consumed_per_turn
      # @see #pct_dim_by_fuel
      #
      # @return [Float]
      #   The amount #illumination will be reduced at the end of each
      #   turn.
      float_accessor(:pct_dim_per_turn)

      # @!attribute [rw] fuel_max
      # @!macro doc.TAGF.classmethod.float_accessor.invoke
      # The maximum total amount of fuel that this light source (such
      # as a lantern) can hold.  This attribute shouldn't be altered,
      # since it represents a 'full tank.'  Instead, the #fuel field
      # tracks how much fuel is actually available, and is the one
      # affected by the #fuel_consumed_per_turn calculation.
      #
      # @return [Float]
      #   the maximum amount of fuel (whatever it might be) that this
      #   light source can have stored.
      float_accessor(:fuel_max)

      # @!attribute [rw] fuel
      # @!macro doc.TAGF.classmethod.float_accessor.invoke
      # The amount of ful currently available to this consumable
      # (possibly renewable) light source (such as a torch or
      # lantern).  This is the attribute that might be affected by
      # #fuel_consumed_per_turn.
      #
      # @return [Float]
      #   The amount of fuel currently available to this light source.
      float_accessor(:fuel_consumed_per_turn)

      # @!attribute [rw] only_dim_near_player
      # @!macro doc.TAGF.classmethod.flag.invoke
      # Boolean value indicating whether or not any automatic decrease
      # in #illumation only applies if the current item is near the
      # player's current location.  This is intended to keep remote
      # locations that the player has never visited from dimming to
      # darkness before the player ever gets there.
      #
      # @return [Boolean]
      #   `true` if the #pct_dim_per_turn and #fuel_consumed_per_turn
      #   values are only applied to this light source if it's near
      #   the player.
      flag(only_dim_near_player: true)

      nil
    end                         # module LightSource

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
