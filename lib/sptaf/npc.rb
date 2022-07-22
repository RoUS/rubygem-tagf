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

require_relative('../sptaf')
require('byebug')

# @!macro doc.TAF.module
module TAF

  #
  class NPC

    include(::TAF::ActorMixin)

    #
    def initialize(*args, **kwargs)
      warn('[%s]->%s running' % [self.class.name, __method__.to_s])
      @breadcrumbs	= []
      self.initialize_thing(*args, **kwargs)
      self.initialize_container(*args, **kwargs)
      self.initialize_actor(*args, **kwargs)
      unless (self.inventory)
        self.game.create_inventory_on(self,
                                      game:	self.game,
                                      owned_by:	self)
      end

    end                         # def initialize

    nil
  end                           # class NPC

  nil
end                             # module TAF

# Local Variables:
# mode: ruby
# indent-tabs-mode: nil
# eval: (if (intern-soft "fci-mode") (fci-mode 1))
# End:
