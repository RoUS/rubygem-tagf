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
  class Item
    
    #
    TAF.mixin(Mixin::Thing)

    #
    # @!macro doc.TAF.classmethod.flag.use
    flag(:living)

    #
    def initialize(*args, **kwargs)
      warn('[%s]->%s running' % [self.class.name, __method__.to_s])
      self.static	= false
      self.initialize_thing(*args, **kwargs)
      if (kwargs[:is_container])
        #
        # @todo
        #   Reconcile this with TAF.mixin, its super, and
        #   self.include.
        #
        if (TAF.debugging?(:include))
          warn('%s.%s including %s' \
               % [ self.name, __method__.to_s, Mixin::Container.name ])
        end
        self.include(Mixin::Container)
        self.initialize_container(*args, **kwargs)
      end
      self.game.add(self)
      if (self.is_container?)
        self.game.create_inventory_on(self,
                                      game:	self.game,
                                      owned_by:	self,
                                      master:	false)
        self.game.add(self.inventory)
      end
    end                         # def initialize

    #
    def inspect
      debugger
      result		= ('#<%s:"%s" ' \
                           + 'game="%s"' \
                           + ', name="%s"' \
                           + ', static=%s' \
                           + ', %s' \
                           + '>') \
                          % [
        self.class.name,
        self.slug.to_s,
        self.game.slug.to_s,
        self.name.to_s,
        self.static?.inspect,
        (self.is_container? \
         ? (self.inventory.empty? \
            ? 'container (empty)' \
            : 'container ([...])') \
         : 'no inventory')
      ]
      return result
    end                         # def inspect

    nil
  end                           # class Item

end                             # module TAF

# Local Variables:
# mode: ruby
# indent-tabs-mode: nil
# eval: (if (intern-soft "fci-mode") (fci-mode 1))
# End:
