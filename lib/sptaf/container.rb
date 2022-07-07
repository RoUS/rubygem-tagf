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

require_relative('version')
require_relative('classmethods')
require_relative('exceptions')

# @!macro ModuleDoc
module TAF

  module Container

    class << self

      def included(klass)
        klass.extend(::TAF::Thing)
        klass.include(::TAF::Thing)
      end                       # def included

    end                         # module Container eigenclass

    def mass_max
      return (@mass_max ||= 0)
    end                         # def mass_max

    def mass_current
      return (@mass_current ||= 0)
    end                         # mass_current

    def volume_max
      return (@volume_max ||= 0)
    end                         # def volume_max

    def volume_current
      return (@volume_current ||= 0)
    end                         # volume_current

  end                           # module Container

end                             # module TAF

# Local Variables:
# mode: ruby
# indent-tabs-mode: nil
# eval: (if (intern-soft "fci-mode") (fci-mode 1))
# End:
