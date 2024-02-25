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
#require('tagf')
require('tagf/mixin/container')
require('tagf/mixin/dtypes')
require('tagf/exceptions')
require('tagf/location')
require('byebug')

# @!macro doc.TAGF.module
module TAGF

  # @!macro doc.TAGF.Mixin.module
  module Mixin

    # @!macro doc.TAGF.Mixin.Actor.module
    module Actor

      #
      include(TAGF::Exceptions)
      include(Mixin::DTypes)
      include(Mixin::Container)

      #
      # Eigenclass for the Actor module.  Simply provides an
      # `included` method to propagate the class methods to the
      # including class.
      #
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

        nil
      end                         # module TAGF::Mixin::Actors eigenclass

      # @!macro TAGF.constant.Loadable_Fields
      Loadable_Fields		= [
        'maxhp',
        'hp',
        'faction',
        'attitude',
        'breadcrumbs',
      ]

      # @!macro TAGF.constant.Abstracted_Fields
      Abstracted_Fields		= {
        breadcrumbs:		Array[TAGF::Location],
        whereami:		EID,
      }

      #
      # @!macro doc.TAGF.classmethod.int_accessor.invoke
      int_accessor(:maxhp)

      #
      # @!macro doc.TAGF.classmethod.float_accessor.invoke
      float_accessor(:hp)

      #
      # @return [Faction]
      # @todo
      #   Need to define the faction stuff.
      #
      attr_accessor(:faction)

      #
      # @return [Attitude]
      # @todo
      #   Need to define the attitude stuff.
      #
      attr_accessor(:attitude)

      # @!attribute [rw] whereami
      # @return [Location]
      attr_accessor(:whereami)

      # @!attribute [r] breadcrumbs
      # A list of the locations in which the actor has been located.
      # Each time an actor moves, other than to its previous location,
      # the new location is pushed on the end of this array.  (If it
      # moves to its previous location, the current location is popped
      # off the list.)
      #
      # @return [Array<Location>]
      attr_reader(:breadcrumbs)

      #
      # @!macro doc.TAGF.formal.kwargs
      # @return [???] self
      #
      def initialize_actor(*args, **kwargs)
        TAGF::Mixin::Debugging.invocation
        @breadcrumbs	= []
        kwargs_defaults	= {
          maxhp:	0,
          hp:		0.0,
          attitude:	:neutral
        }
        self.initialize_element(*args, kwargs_defaults.merge(kwargs))
        self.initialize_container(*args, kwargs_defaults.merge(kwargs))
        return self
      end                         # def initialize_actor

      #
      # @!macro doc.TAGF.formal.kwargs
      # @return [???] self
      #
      def add(*args, **kwargs)
        begin
          super if (self.inventory.nil? \
                    || self.inventory.can_add?(*args, **kwargs))
        rescue InventoryLimitExceeded => e
          warn("Inventory limit exception: #{e.to_s}")
        end
        return self
      end                       # def add(*args, **kwargs)

      nil
    end                         # module TAGF::Mixin::Actor

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
