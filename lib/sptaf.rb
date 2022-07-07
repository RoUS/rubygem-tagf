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

require_relative('sptaf/version')
require_relative('sptaf/exceptions')
require_relative('sptaf/classmethods')
require_relative('sptaf/container')
require_relative('sptaf/location')

# @!macro ModuleDoc
module TAF

  unless ((RUBY_ENGINE == 'ruby') \
          && (RUBY_VERSION >= ::TAF::RUBY_VERSION_MIN))
    warn(__class__.name \
         + ' requires the ruby engine version ' \
         + "#{::TAF::RUBY_VERSION_MIN_GEMSPEC}")
    exit(1)
  end                           # Ruby version check

  module Thing

    class << self

      include ::TAF::Thing::ClassMethods
      
      def included(klass)
        klass.extend(::TAF::Thing::ClassMethods)
      end

    end

    extend ::TAF::Thing::ClassMethods

    class Description < ::String

      def wordwrap(right_margin: 72, indent: 0, bullets: %q[o * •])
        return self
      end                       # def wordwrap

    end                         # class Description

    attr_accessor(:slug)
    attr_accessor(:name)
    attr_accessor(:desc)
    attr_accessor(:shortdesc)
    flag(:static)
    
  end                           # module Thing

end                             # module TAF

# Local Variables:
# mode: ruby
# indent-tabs-mode: nil
# eval: (if (intern-soft "fci-mode") (fci-mode 1))
# End:
