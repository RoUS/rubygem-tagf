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
require('tagf/mixin/element')
require('readline')
require('thor')
require('byebug')

# @!macro doc.TAGF.module
module TAGF

  #
  # Prototype command-line interface class for development
  # (creating/modifying games, listing interconnexions, <em>&c.</em>
  #
  class CLI < ::Thor

    package_name('TAGF')

    #
    include(Mixin::Element)
    include(Mixin::UniversalMethods)
    include(Mixin::DTypes)

    #
    desc('list', 'List game definitions')
    def list
      
    end                         # def list

    #
    desc('version', format('Shows the %s version', @package_name))
    def version
      puts(format('%s %s', 'TAGF', ::TAGF::VERSION.to_s))
    end                         # def version
           
    nil
  end                           # class TAGF::CLI

  nil
end                             # module TAGF

# Local Variables:
# mode: ruby
# indent-tabs-mode: nil
# eval: (if (intern-soft "fci-mode") (fci-mode 1))
# eval: (auto-fill-mode 1)
# End:
