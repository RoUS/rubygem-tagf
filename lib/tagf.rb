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
#require('contracts')
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

  # @!method debugging?(*args, **kwargs)
  # Dummy method for debugging before any real methods are defined.
  #
  # @param [Array] args ([])
  #   Dummy argument.
  # @param [Hash] kwargs ({})
  #   Dummy hash of keyword arguments.
  # @return [Boolean]		false
  def debugging?(*args, **kwargs)
    return false
  end                           # def debugging?(*args, **kwargs)
  module_function(:debugging?)

  nil
end                             # module TAGF

#
# We're about to test that we're running on a sufficiently advanced
# version of Ruby, so pull in the versioning information — and our
# exception module, since any problems will be reported using our
# specific exceptions.
#
require('tagf/version')

unless ((RUBY_ENGINE == 'ruby') \
        && (RUBY_VERSION >= ::TAGF::RUBY_VERSION_MIN))
  warn(__class__.name \
       + ' requires the ruby engine version ' \
       + "#{::TAGF::RUBY_VERSION_MIN_GEMSPEC}")
  exit(1)
end                             # Ruby version check


#
# Start requiring the different files comprising the package.
#
#require('tagf/debugging')

#warn(__FILE__) if (TAGF.debugging?(:file))

#
# Something we use for debugging.
#
require('binding_of_caller')

#
# Pull in all the mixin module definitions first.
#
require('tagf/mixin/actor')
require('tagf/mixin/classmethods')
require('tagf/mixin/container')
#require('tagf/mixin/debugging')
require('tagf/mixin/dtypes')
require('tagf/mixin/element')
require('tagf/mixin/events')
require('tagf/mixin/location')
require('tagf/mixin/universal')

#
# Now the 'top-level' modules.
#
require('tagf/cli')
require('tagf/connexion')
require('tagf/container')
#require_relative('tagf/debugging')
require('tagf/exceptions')
require('tagf/faction')
require('tagf/feature')
require('tagf/game')
require('tagf/inventory')
require('tagf/item')
require('tagf/loader')
require('tagf/location')
require('tagf/npc')
require('tagf/player')
require('tagf/reality')
require('tagf/ui')
require('tagf/version')

# @!macro doc.TAGF.module
module TAGF

  #
  # And now to complete the configuration of the top-level namespace
  # module..
  #
#  include(Contracts::Core)
  include(Mixin::UniversalMethods)
  extend(Mixin::DTypes)
  #
  # ..and the mostly-universal ancillary modules.
  #
#  Mixin::ClassMethods.include(Mixin::UniversalMethods)
#  Mixin::UniversalMethods.extend(Mixin::ClassMethods)

  #
  # Extend the top-level module's eigenclass with methods universal to
  # the entire package (such as access to game options, *&c.*
  #
  extend(Mixin::PackageClassMethods)

  nil
end                             # module TAGF

Linguistics.use(:en)

# Local Variables:
# mode: ruby
# indent-tabs-mode: nil
# eval: (if (intern-soft "fci-mode") (fci-mode 1))
# eval: (auto-fill-mode 1)
# End:
