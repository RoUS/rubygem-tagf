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
require('tagf')
require('byebug')

# @!macro doc.TAGF.module
module TAGF

  #
  # Pull all the tangible attributes together into a single structure:
  #
  # * <em>Per</em> thing: mass and volume
  # * <em>Per</em> container, max capacities for mass, volume, and
  #   items, and the actual consumption of same.  Note that item count
  #   will always be a 1st-order value, whereas mass and volume may
  #   want to examined as 1st-order values (things in the container
  #   itself) or as cumulative ones (the things <em>plus anything they
  #   might contain</em>).
  #
  # @todo
  #   Some of this can probably be deferred to Inventory.. or the
  #   whole mess moved to Mixin::Element, Mixin::Container, and
  #   Inventory.
  #
  class Reality

    #
    include(Mixin::Element)

    #
    # @!macro doc.TAGF.formal.kwargs
    # @return [Reality] self
    #
    def initialize(*args, **kwargs)
      if (TAGF.debugging?(:initialize))
        warn(format('[%s]->%s running',
                    self.class.name,
                    __method__.to_s))
      end
      initialize_element(*args, **kwargs)
      return self
    end                         # def initialize(*args, **kwargs)

    nil
  end                           # class Reality

  nil
end                             # module TAGF

# Local Variables:
# mode: ruby
# indent-tabs-mode: nil
# eval: (if (intern-soft "fci-mode") (fci-mode 1))
# End:
