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

    # Module providing mixed-in aspects for things that can only be
    # used a certain number of times before disintegrating or becoming
    # useless.
    module Consumable

      include(Mixin::DTypes)
      include(Mixin::UniversalMethods)

      # @!macro TAGF.constant.Loadable_Fields
      Loadable_Fields		= [
        #
        # If this element has any lighting attributes, what are they?
        #
        'durability',
        'cost_per_use',
        'max_uses',
        'uses',
      ]

      # @!attribute [rw] durability
      # @!macro doc.TAGF.classmethod.float.invoke
      # Current durability of this item.  This goes down with
      # usage, and up with restoration.  minimum durability is 0.0,
      # maximum is 100.0%.  These limits are imposed on the attribute.
      #
      # @return [Float]
      #   Current durability of the item.
      float_accessor(:durability)
      alias_method(:_durability=, :durability)
      def durability=(val)
        val		= self._durability=(val)
        val		= [0.0, [100.0, val].min ].max
        @durability	= val
      end

      float_accessor(:cost_per_use)
      integer_accessor(:max_uses)
      integer_accessor(:uses)

      # @!attribute depleted?
      #
      # @return [Boolean]
      #   `true` if the item has lost all its durability, or all of
      #   its uses have been consumed.
      def depleted?
        result		= (self.uses.zero? || self.durability.zero?)
        return result
      end                       # def depleted?

      nil
    end                         # module Consumable

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
