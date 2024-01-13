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

#require('tagf/debugging')
#warn(__FILE__) if (TAGF.debugging?(:file))
require('tagf/mixin/dtypes')
require('tagf/mixin/universal')
require('byebug')

# @!macro doc.TAGF.module
module TAGF

  # @!macro doc.TAGF.Mixin.module
  module Mixin

    # @!macro doc.TAGF.Mixin.Location.module
    module Location

      include(Mixin::UniversalMethods)
      extend(Mixin::DTypes)

      # @!macro doc.TAGF.Mixin.module.eigenclass Location
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

      end                       # module Location eigenclass

      #
      include(Mixin::Container)

      #
      attr_accessor(:paths)

      #
      # @!macro doc.TAGF.classmethod.float_accessor.invoke
      float_accessor(:light_level)

      #
      def initialize_location(*args, **kwargs)
        TAGF::Mixin::Debugging.invocation
        self.paths	= {}
        #      self.initialize_container(*args, **kwargs)
        #      self.inventory	= ::TAGF::Inventory.new(game:	self,
        #                                              owned_by: self)
      end                       # def initialize_location

      nil
    end                         # module TAGF::Mixin::Location

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
