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

require('sptaf/debugging')
warn(__FILE__) if (TAF.debugging?(:file))
TAF.require_file('sptaf')
TAF.require_file('byebug')

# @!macro doc.TAF.module
module TAF

  #
  class Feature

    #
    TAF.mixin(Mixin::Container)

    #
    # @!macro doc.TAF.formal.kwargs
    # @return [Feature] self
    #
    def initialize(*args, **kwargs)
      self.initialize_thing(*args, **kwargs)
      self.static!
    end                         # def initialize(*args, **kwargs)

  end                           # class Feature

  nil
end                             # module TAF

# Local Variables:
# mode: ruby
# indent-tabs-mode: nil
# eval: (if (intern-soft "fci-mode") (fci-mode 1))
# End:
