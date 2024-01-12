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
#require('tagf')
require('tagf/mixin/actor')
require('tagf/mixin/dtypes')
require('byebug')

# @!macro doc.TAGF.module
module TAGF

  #
  class NPC

    #
    extend(Mixin::DTypes)
    include(Mixin::Actor)

    #
    # @!macro doc.TAGF.formal.kwargs
    # @return [NPC] self
    #
    def initialize(*args, **kwargs)
      TAGF::Mixin::Debugging.invocation
      @breadcrumbs	= []
      self.initialize_element(*args, **kwargs)
      self.initialize_container(*args, **kwargs)
      self.initialize_actor(*args, **kwargs)
      unless (self.inventory)
        self.game.create_inventory_on(self,
                                      game:	self.game,
                                      owned_by:	self)
      end
      self.is_static!
      self.game.add(self)
    end                         # def initialize

    nil
  end                           # class NPC

  nil
end                             # module TAGF

# Local Variables:
# mode: ruby
# indent-tabs-mode: nil
# eval: (if (intern-soft "fci-mode") (fci-mode 1))
# eval: (auto-fill-mode 1)
# End:
