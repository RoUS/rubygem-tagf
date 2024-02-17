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

source('https://rubygems.org/')
require('versionomy')

#
# All the dependencies *were* in the gemspec file, but Bundler is
# remarkably stupid about gems needed *by* the gemspec.
#
# gemspec
#
# Use the following to install `versionomy` into the `vendor` subtree
# so Bundler can find and use it:
#
#	gem install \
#	    --no-user-install \
#	    --install-dir vendor/bundle/ruby/3.0.0 \
#	    versionomy
#

RUBY_ENGINE     = 'ruby' unless (defined?(RUBY_ENGINE))
ruby('>= 2.7')

plugin('bundler-graph')

# Add dependencies required to use your gem here.
# Example:
#   gem "activesupport", ">= 2.3.5"

group(:default, :development, :test) do
  gem('abbrev')
  gem('bundler',	'>= 1.0.7')
  gem('binding_of_caller')
  gem('contracts',	'< 0.17.0')
  gem('cri')
  gem('gettext')
  gem('linguistics')
  gem('logger')
  gem('ostruct',	'>= 0.5.5')
  gem('pathname',	'>= 0.2.0')
  gem('psych')
  gem('readline')
  gem('tagf',
      path:		'.')
  gem('thor')
  gem('yaml',		'>= 0.2.0')
  gem('versionomy')
end

#
# Add dependencies to develop your gem here.
# Include everything needed to run rake, tests, features, etc.
#
group(:development, :test) do
  #
  # Pick the right debugging gem.
  #
  if (Versionomy.ruby_version < Versionomy.parse('1.9.0'))
    gem('ruby-debug')
  elsif (Versionomy.ruby_version >= Versionomy.parse('2.0.0'))
    gem('byebug')
  else
    gem('debugger')
  end

  gem('rdiscount')
  gem('coveralls')
  gem('cucumber')
  gem('github-markup')
  #
  # Needed for Yard, of all things
  #
  gem('irb')
  gem('mocha')
  gem('pp')
  gem('rake',		'~> 13.0')
  gem('rdoc')
  gem('rspec',		'~> 3.0')
  gem('rubocop',	'~> 1.21')
  gem('rubocop-rake')
  gem('simplecov')
  gem('test-unit',	'~> 3.0')
  gem('yard', 		'~> 0.9.11')
end

# Local Variables:
# mode: ruby
# indent-tabs-mode: nil
# eval: (if (intern-soft "fci-mode") (fci-mode 1))
# End:
