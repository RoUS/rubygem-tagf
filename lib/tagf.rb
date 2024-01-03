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

require('rubygems')
require('bundler')
Bundler.setup
require('byebug')
require('contracts')
require('linguistics')
require('ostruct')
require('set')

#
# Declare the TAGF namespace module before pulling in anything that
# actually references it.  Since it can be re-opened (thank you,
# Ruby!), we can add more to it later.
#

# @!macro doc.TAGF.module
module TAGF

  #
  include(Contracts::Core)

  nil
end                             # module TAGF


#
# Start requiring the different files comprising the package.
#
require('tagf/debugging')

warn(__FILE__) if (TAGF.debugging?(:file))

require('tagf/mixin/universal')
require('tagf/classmethods')
require('tagf/exceptions')

# @!macro doc.TAGF.module
module TAGF

  #
  extend(PackageClassMethods)

  nil
end                             # module TAGF

require('tagf/version')
require('tagf/exceptions')

unless ((RUBY_ENGINE == 'ruby') \
        && (RUBY_VERSION >= ::TAGF::RUBY_VERSION_MIN))
  warn(__class__.name \
       + ' requires the ruby engine version ' \
       + "#{::TAGF::RUBY_VERSION_MIN_GEMSPEC}")
  exit(1)
end                             # Ruby version check

require('tagf/mixin/events')

# @!macro doc.TAGF.module
module TAGF

  #
  include(Mixin::UniversalMethods)

  #
  extend(ClassMethods)

  #
  include(Contracts::Core)

  #
  include(Mixin::Events)

  nil
end                             # module TAGF

require('binding_of_caller')
debugger

require('tagf/exceptions')
require('tagf/mixin/element')
require('tagf/inventory')
require('tagf/mixin/container')
require('tagf/container')
require('tagf/item')
require('tagf/ui')
require('tagf/mixin/location')
require('tagf/location')
require('tagf/feature')
require('tagf/game')
require('tagf/mixin/actor')
require('tagf/faction')
require('tagf/player')
require('tagf/npc')

Linguistics.use(:en)

# Local Variables:
# mode: ruby
# indent-tabs-mode: nil
# eval: (if (intern-soft "fci-mode") (fci-mode 1))
# End:
