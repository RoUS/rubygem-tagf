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

require('sptaf/debugging')
warn(__FILE__) if (TAF.debugging?(:file))
require('sptaf')
require('byebug')

# @!macro doc.TAF.module
module TAF

  # @!macro doc.TAF.Mixin.module
  module Mixin

    #
    # Mixin module for active objects, like the PC and NPCs.  They get
    # moved around by the player and/or game logic with specific
    # semantics.
    #
    module Actor

      #
      include(Mixin::Container)

      #
      # Eigenclass for the Actor module.  Simply provides an
      # `included` method to propagate the class methods to the
      # including class.
      #
      class << self

        # @!macro doc.TAF.module.classmethod.included
        def included(klass)
          whoami		= '%s eigenclass.%s' \
                                  % [self.name, __method__.to_s]
=begin
          warn('%s called for %s' \
               % [whoami, klass.name])
=end
          super
          return nil
        end                       # def included(klass)

        nil
      end                         # module TAF::Mixin::Actors eigenclass

      #
      # @!macro doc.TAF.classmethod.int_accessor.use
      int_accessor(:maxhp)

      #
      # @!macro doc.TAF.classmethod.float_accessor.use
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

      #
      # @return [Array<Location>]
      #
      attr_reader(:breadcrumbs)

      #
      # @!macro doc.TAF.formal.kwargs
      # @return [???] self
      #
      def initialize_actor(*args, **kwargs)
        warn('[%s]->%s running' % [self.class.name, __method__.to_s])
        @breadcrumbs	= []
        kwargs_defaults	= {
          maxhp:	0,
          hp:		0.0,
          attitude:	:neutral
        }
        self.initialize_thing(*args, kwargs_defaults.merge(kwargs))
        return self
      end                         # def initialize_actor

      #
      # @!macro doc.TAF.formal.kwargs
      # @return [???] self
      #
      def add(*args, **kwargs)
        begin
          super if (self.inventory.can_add?(*args, **kwargs))
        rescue InventoryLimitError => e
          warn("Inventory limit exception: #{e.to_s}")
        end
        return self
      end                       # def add(*args, **kwargs)

      nil
    end                         # module TAF::Mixin::Actor

    nil
  end                           # module TAF::Mixin

  nil
end                             # module TAF

# Local Variables:
# mode: ruby
# indent-tabs-mode: nil
# eval: (if (intern-soft "fci-mode") (fci-mode 1))
# End:
