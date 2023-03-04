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

require('tagf')

# @!macro doc.TAGF.module
module TAGF

  #
  class << self
=begin
    UNIVERSAL_MODULES	= [
      Contracts::Core,
      TAGF::ClassMethods,
      TAGF::Exceptions,
    ]
=end

    #
    # We can either `include` the classmethods module in the
    # eigenclass, or `extend` it from the main module body.  Six of
    # one..  Do the `include` because that makes Yard understand a
    # little better what's going on.
    #
    def invasion_force(klass=self)
=begin
      UNIVERSAL_MODULES.each do |xmodule|
        next unless (defined?(xmodule))
        unless (klass.included_modules.include?(xmodule))
          if (TAGF.debugging?(:include))
            warn('<%s>[eigenclass] including module <%s>' \
                 % [ klass.name, xmodule.name ])
          end
          klass.include(xmodule)
        end
        unless (klass.singleton_class.included_modules.include?(xmodule))
          if (TAGF.debugging?(:extend))
            warn('<%s>[eigenclass] extending module <%s>' \
                 % [ klass.name, xmodule.name ])
          end
          klass.extend(xmodule)
        end
      end
=end
    end                         # def invasion_force

#    invasion_force(self)

    # @!macro doc.TAGF.module.classmethod.included
    def included(klass)
      whoami            = '<%s>[eigenclass.%s]' \
                          % [self.name, __method__.to_s]
#      invasion_force(klass)
      return nil
    end                         # def included(klass)

    nil
  end                           # module TAGF eigenclass

  nil
end

require('tagf/mixin/debugging')

# @!macro doc.TAGF.module
module TAGF

  #
  include(Mixin::Debugging)

  nil
end                             # module TAGF

warn(__FILE__) if (TAGF.debugging?(:file))

# Local Variables:
# mode: ruby
# indent-tabs-mode: nil
# eval: (if (intern-soft "fci-mode") (fci-mode 1))
# End:
