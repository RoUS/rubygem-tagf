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

    # Module providing mixed-in aspects for elements that can be
    # picked up, dropped, or moved between inventories.
    module Portable

      include(Mixin::DTypes)
      include(Mixin::UniversalMethods)

      # @!macro TAGF.constant.Loadable_Fields
      Loadable_Fields		= [
        #
        # Attributes controlling how the element affects appearance in
        # an inventory.
        #
        'mass',
        'volume',
      ]

      # @!attribute [rw] mass
      # @!macro doc.TAGF.classmethod.float_accessor.invoke
      # How much this element weighs by itself.  If it has an
      # inventory and contains other elements, their masses are
      # <em>not</em> included in this value.
      #
      # @!macro [new] doc.TAGF.InventoryLimits
      #   <strong>N.B.: This is only meaningful if inventory limits
      #   (such as maximum number of items, maximum weight, or maximum
      #   size) are in effect.</strong>
      #
      # @return [Float]
      #
      float_accessor(:mass)

      # @!attribute [rw] volume
      # The volume consumed by the current object, in cubic
      # (whatever-units-are-in-use).  This does <em>not</em> include
      # the volume of anything in its inventory (if it has one), and
      # is only meaningful when an attempt might be made to place the
      # object into a container with a volume limitation.  (See #mass,
      # {Mixin::Container#capacity_items}.)
      #
      # @!macro doc.TAGF.classmethod.float_accessor.invoke
      # @!macro doc.TAGF.InventoryLimits
      #
      # @return [Float]
      #   the volume consumed by this element as it may count against
      #   whatever it's in.
      float_accessor(:volume)

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
