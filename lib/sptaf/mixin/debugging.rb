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

require('byebug')
require('binding_of_caller')

# @!macro doc.TAF.module
module TAF

  # @!macro doc.TAF.Mixin.module
  module Mixin

    #
    # Mixin module defining methods specific to objects that have
    # inventories, such as locations, player and NPC objects, and some
    # items.
    #
    module Debugging

      #
      # Debug options are:
      #
      # * `debugging`
      # * `extend`
      # * `file`
      # * `include`
      # * `initialize`
      # * `inventory`
      # * `require`
      #
      DEBUG_OPTIONS		= Set.new

      #
      def debugging?(item)
        return (DEBUG_OPTIONS.include?(item.to_sym)) ? true : false
      end                       # def debugging?(item)
      module_function(:debugging?)

      #
      def notify_initialising
        scope		= binding.of_caller(1)
        elem		= scope.eval('self')
        if (debugging?(:initialize))
          warn('<%s>[%s].%s running' \
               % [elem.class.name,
                  elem.eid.to_s,
                  scope.eval('__method__.to_s')])
        end
      end                       # def notify_initialising

      # @!macro doc.TAF.Mixin.module.eigenclass Debugging
      class << self

        #
        def set_debugging_options(*args, **kwargs)
          report	= debugging?(:debugging)
          if (report)
            warn('<%s>.%s existing debugging options: %s' \
                 % [ self.class.name,
                     __method__.to_s,
                     DEBUG_OPTIONS.to_a.sort.inspect
                   ])
          end
          enable	= args \
                          | [ [*kwargs[:set]] \
                              |  [*kwargs[:on]] \
                              | [*kwargs[:enable]] ].flatten
          enable	= enable.map { |o| o.to_sym }.uniq
          disable	= [ [*kwargs[:clear]] \
                            | [*kwargs[:off]] \
                            | [*kwargs[:disable]] ].flatten
          disable	= disable.map { |o| o.to_sym }.uniq
          new_settings	= DEBUG_OPTIONS.union(enable) - disable

          DEBUG_OPTIONS.replace(new_settings)
          if (report || debugging?(:debugging))
            warn('<%s>.%s new debugging options: %s' \
                 % [self.class.name,
                    __method__.to_s,
                    DEBUG_OPTIONS.to_a.sort.inspect
                   ])
          end
          return new_settings
        end                         # def set_debugging_options(*args, **kwargs)

        # @!macro doc.TAF.module.classmethod.included
        def included(klass)
          whoami	= '%s eigenclass.%s' \
                          % [self.name, __method__.to_s]
=begin
             warn('%s called for %s' \
                  % [whoami, klass.name])
=end
          super
          return nil
        end                     # def included(klass)

        nil
      end                       # module Debugging eigenclass

      nil
    end                         # modulle Debugging

    nil
  end                           # module Mixin

  #
  def debugging?(item)
    return Mixin::Debugging.send(__method__, item)
  end
  module_function(:debugging?)
    

  nil
end                             # module TAF

require('sptaf/debugging')
require('sptaf')
TAF.include(TAF::Mixin::Debugging)
require('sptaf/classmethods')
TAF::Mixin::Debugging.extend(TAF::ClassMethods)

# Local Variables:
# mode: ruby
# indent-tabs-mode: nil
# eval: (if (intern-soft "fci-mode") (fci-mode 1))
# End:
