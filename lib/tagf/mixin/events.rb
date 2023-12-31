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

# @!macro doc.TAGF.module
module TAGF

  # @!macro doc.TAGF.Mixin.module
  module Mixin

    #
    #
    # Defines exception classes specific to the {TAF} module.  All are
    # namespaced under `TAGF::Exceptions`.
    #
    # Some exceptions are used internally for signalling conditions,
    # such as attempts to put more into a container than it can hold.
    #
    module Events

      #
      include(::TAGF::Mixin::UniversalMethods)

      EventList			= {
        EventTurnBegin:		:turn_begin,
        EventTurnEnd:		:turn_end,
        EventDestruction:	:turn_end,
        EventDeath:		:turn_end,
        EventOpen:		:immediate,
        EventClose:		:immediate,
        EventLight:		:turn_begin,
        EventBrighten:		:turn_end,
        EventDark:		:turn_end,
        EventDim:		:turn_end,
        EventAttacked:		:turn_begin,
        EventMove:		:turn_begin,
        EventAttack:		:turn_end,
        EventTaken:		:turn_begin,
        EventDropped:		:turn_begin,
      }

      #
      attr_accessor(:events_heard)

      #
      attr_reader(:event_queue)

      # @abstract
      def onTurnBegin(*args, **kwargs)
        return nil
      end                       # def onTurnBegin

      # @abstract
      def onTurnEnd(*args, **kwargs)
        return nil
      end                       # def onTurnEnd

      # @abstract
      def onDestruction(*args, **kwargs)
        return nil
      end                       # def onDestruction

      # @abstract
      def onDeath(*args, **kwargs)
        return nil
      end                       # def onDeath

      # @abstract
      def onOpen(*args, **kwargs)
        return nil
      end                       # def onOpen

      # @abstract
      def onClose(*args, **kwargs)
        return nil
      end                       # def onClose

      # @abstract
      def onLight(*args, **kwargs)
        return nil
      end                       # def onLight

      # @abstract
      def onBrighten(*args, **kwargs)
        return nil
      end                       # def onBrighten

      # @abstract
      def onDark(*args, **kwargs)
        return nil
      end                       # def onDark

      # @abstract
      def onDim(*args, **kwargs)
        return nil
      end                       # def onDim

      # @abstract
      def onAttack(*args, **kwargs)
        return nil
      end                       # def onAttack

      # @abstract
      def onAttacked(*args, **kwargs)
        return nil
      end                       # def onAttacked

      # @abstract
      def onMove(*args, **kwargs)
        return nil
      end                       # def onMove

      # @abstract
      def onTaken(*args, **kwargs)
        return nil
      end                       # def onTaken

      # @abstract
      def onDropped(*args, **kwargs)
        return nil
      end                       # def onDropped

      nil
    end                         # module TAGF::Mixin::Events

    nil
  end                           # module TAGF::Mixin

  nil
end                             # module TAGF

# Local Variables:
# mode: ruby
# indent-tabs-mode: nil
# eval: (if (intern-soft "fci-mode") (fci-mode 1))
# End:
