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
require('tagf/mixin/dtypes')
require('tagf/mixin/container')
require('byebug')

# @!macro doc.TAGF.module
module TAGF

  #
  # Class for actual container objects.  A container is something with
  # an inventory.
  #
  # @todo
  #   This class may actually be obviated, because there really aren't
  #   any standalone containers.  Locations, features, and items can
  #   have inventories, so what's the use of/need for a Container
  #   object?
  #
  class Container

    #
    include(Mixin::DTypes)
    include(Mixin::Container)

    #
    # @!macro doc.TAGF.formal.kwargs
    # @return [Container] self
    #
    def initialize(*args, **kwargs)
      TAGF::Mixin::Debugging.invocation
      self.initialize_element(*args, **kwargs)
      args		= args.dup
      self.game		||= kwargs[:game]
      if (kwargs[:owned_by] && kwargs[:owned_by].respond_to?(:game))
        self.game	||= kwargs[:owned_by].game
      end
      unless (self.game \
              || (args[0].kind_of?(::TAGF::Game) \
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
=begin
      #
      # Add this object to our owner's inventory.
      #
      if (self.owned_by && self.owned_by.has_inventory?)
        self.owned_by.add(self)
      end
=end
      self.game.add(self)
    end                         # def initialize

    nil
  end                           # class Container

  nil
end                             # module TAGF

# Local Variables:
# mode: ruby
# indent-tabs-mode: nil
# eval: (if (intern-soft "fci-mode") (fci-mode 1))
# eval: (auto-fill-mode 1)
# End:
