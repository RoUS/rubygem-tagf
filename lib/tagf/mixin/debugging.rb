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

# @!macro doc.TAGF.module
module TAGF

  # @!macro doc.TAGF.Mixin.module
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
      # Check the list of deugging options (all symbols) to see if the
      # requested one is in the current set.  Return `true` if so.
      # Typically used options are method names like `:initialize`.
      #
      # @todo
      #   Allow multiple options (like `[:include, :extend]`).
      # @param [Symbol] item
      # @return [Boolean]
      def debugging?(*items)
        isyms		= Set.new(items.map(&:to_sym))
        return ((DEBUG_OPTIONS & isyms) == isyms) ? true : false
      end                       # def debugging?(*items)
      module_function(:debugging?)

      # Display a method on `stderr` about a particular method or
      # class of method beginning execution.  By default, the method
      # described is the one that invoked #invocation, but this
      # can be overridden by passing an actual method symbol (such as
      # `:initialize`).
      #
      # The format of the message written to `stderr` is:
      #
      #    <1>[2].3 invocation beginning
      #
      # where
      #
      # #. is the name of the class or module in which the method
      #    resides
      # #. is the EID (element ID) of the object in which the
      #    method is being invoked, and
      # #. is the name of the method itself.
      #
      # @param [Symbol,nil] altmethod(nil)
      # @return [void]
      def invocation(altmethod=nil, altmessage=nil, frame=1)
        scope		= binding.of_caller(frame)
        elem		= scope.eval('self')
        invmethod	= altmethod || scope.eval('__method__')
        invmessage	= altmessage || 'beginning invocation'
        return unless (TAGF.debugging?(invmethod))
        warn(format('<%s>[%s].%s %s',
                    elem.class.name,
                    elem.eid.to_s,
                    invmethod.to_s,
                    invmessage))
        return
      end                       # def invocation
      module_function(:invocation)

      # @!macro doc.TAGF.Mixin.module.eigenclass Debugging
      class << self

        #
        def set_debugging_options(*args, **kwargs)
          report	= debugging?(:debugging)
          if (report)
            warn(format('<%s>.%s existing debugging options: %s',
                        self.class.name,
                        __method__.to_s,
                        DEBUG_OPTIONS.to_a.sort.inspect))
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
            warn(format('<%s>.%s new debugging options: %s',
                        self.class.name,
                        __method__.to_s,
                        DEBUG_OPTIONS.to_a.sort.inspect))
          end
          return new_settings
        end                         # def set_debugging_options(*args, **kwargs)

        # @!macro doc.TAGF.module.classmethod.included
        def included(klass)
          whoami	= format('%s eigenclass.%s',
                                 self.name,
                                 __method__.to_s)
=begin
             warn(format('%s called for %s',
                  	 whoami,
			 klass.name))
=end
          super
          return nil
        end                     # def included(klass)

        nil
      end                       # module Debugging eigenclass

      nil
    end                         # modulle TAGF::Mixin::Debugging

    nil
  end                           # module TAGF::Mixin

  #
  def debugging?(item)
    return Mixin::Debugging.send(__method__, item)
  end
  module_function(:debugging?)
    

  nil
end                             # module TAGF

if ((! Kernel.const_defined?('TAGF')) \
    || (! TAGF.ancestors.include?(Contracts::Core)))
  require('tagf/debugging')
end
#require('tagf/debugging')
#require('tagf')
TAGF.include(TAGF::Mixin::Debugging)
require('tagf/classmethods')
TAGF::Mixin::Debugging.extend(TAGF::ClassMethods)

# Local Variables:
# mode: ruby
# indent-tabs-mode: nil
# eval: (if (intern-soft "fci-mode") (fci-mode 1))
# End:
