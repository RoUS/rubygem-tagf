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
require('sptaf')
require('byebug')

# @!macro doc.TAF.module
module TAF

  #
  class Container

    #
    include(Mixin::Container)

    #
    # @!macro doc.TAF.formal.kwargs
    # @return [Container] self
    #
    def initialize(*args, **kwargs)
      warn('[%s]->%s running' % [self.class.name, __method__.to_s])
      self.initialize_thing(*args, **kwargs)
      args		= args.dup
      self.game		||= kwargs[:game]
      if (kwargs[:owned_by] && kwargs[:owned_by].respond_to?(:game))
        self.game	||= kwargs[:owned_by].game
      end
      unless (self.game \
              || (args[0].kind_of?(::TAF::Game) \
                  && (self.game ||= args[0].game)))
        raise_exception(NoGameContext)
      end
      #
      # We're a container, so create our own inventory and add it to
      # our, erm, inventory.
      #
      self.game.create_inventory_on(self,
                                    game:	self.game,
                                    owned_by:	self)
      self.add(self.inventory)
      #
      # Add this object to our owner's inventory.
      #
      if (self.owned_by && self.owned_by.has_inventory?)
        self.owned_by.add(self)
      end
      self.game.add(self)
    end                         # def initialize

    nil
  end                           # class Container

  nil
end                             # module TAF

# Local Variables:
# mode: ruby
# indent-tabs-mode: nil
# eval: (if (intern-soft "fci-mode") (fci-mode 1))
# End:
