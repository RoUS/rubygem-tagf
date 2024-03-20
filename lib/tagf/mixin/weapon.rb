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

    # Module providing mixed-in aspects for weapons and things that
    # can deal damage.
    module Weapon

      include(Mixin::DTypes)
      include(Mixin::UniversalMethods)

      # @!macro TAGF.constant.Loadable_Fields
      Loadable_Fields		= [
        #
        # If this element has any lighting attributes, what are they?
        #
        'damage',
      ]

      # @!attribute [rw] damage
      # @!macro doc.TAGF.classmethod.float.invoke
      # Amount of damage (in HP) done to an opponent upon a hit.
      #
      # @return [Float]
      #   Amount of damage inflicted on a hit.
      float_accessor(:damage)

      nil
    end                         # module Weapon

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
