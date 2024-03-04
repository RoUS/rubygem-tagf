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

=begin
require('versionomy')
=end

# @!macro doc.TAGF.module
module TAGF

  #
  # We're going with a minimum version of the `ruby` engine 2.7.0
  # because that's when `**kwargs` were introduced.
  #
  RUBY_VERSION_MIN		= '2.7.0'
  #
  # The minimum Ruby version as a Gem comparison string.
  #
  RUBY_VERSION_MIN_GEMSPEC	= ">= #{RUBY_VERSION_MIN}"

=begin
  @version			= Versionomy.parse('0.1.0')
=end
  @version			= '0.1.0'
  @version.freeze
  #
  # Frozen string representation of the module version number.
  #
  VERSION		= @version.to_s.freeze

  #
  # Returns the {http://rubygems.org/gems/versionomy Versionomy}
  # representation of the package version number.
  #
  # @return [Versionomy]
  #
  def version
    return @version
  end
  module_function(:version)

  #
  # Returns the package version number as a string.
  #
  # @return [String]
  #
  def VERSION
    return self::VERSION
  end
  module_function(:VERSION)

end                             # module TAGF

# Local Variables:
# mode: ruby
# indent-tabs-mode: nil
# eval: (if (intern-soft "fci-mode") (fci-mode 1))
# eval: (auto-fill-mode 1)
# End:
