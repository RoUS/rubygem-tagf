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
require('tagf/mixin/element')
require('tagf/mixin/portable')
require('tagf/mixin/universal')
require('byebug')

# @!macro doc.TAGF.module
module TAGF

  #
  # Items are portable objects.  They may or may not be containers,
  # but they're intended to represent things that actors can put in
  # <em>their</em> inventories can carry around with them.  In the
  # Adventure/Colossal Cave game, both the bird and the birdcage would
  # be considered items, but only the birdcage is a container (since
  # it can contain the bird).
  #
  class Item
    
    #
    include(Mixin::DTypes)
    include(Mixin::UniversalMethods)
    include(Mixin::Container)
    include(Mixin::Element)
    include(Mixin::Portable)

    #
    # If the item is a container, we'll mix in Mixin::Container during
    # initialisation.
    #

    #
    # Identify all the instance methods specific to the
    # Mixin::Container module by subtracting all those mixed into from
    # other modules.  We do this so we can essentially remove all
    # aspects of container-ness from an Item.
    #
    CONTAINER_METHODS	=
      Mixin::Container.instance_methods \
      - (Mixin::Container.included_modules.map { |m|
           m.instance_methods
         }.flatten.uniq)

    # @!macro TAGF.constant.Loadable_Fields
    Loadable_Fields		= {
      'living'			=> FieldDef.new(
        name:			'living',
        datatype:		Boolean,
        description:		'Item is a living creature'
      ),
    }

    #
    # Is this item alive, like a bird or lizard?  If so, it may leave
    # loot or a corpse behind if it dies.  Whatever remains might be
    # an Item (or multiple Items), or it may be a Feature and
    # therefore not acquirable.
    #
    # @!macro doc.TAGF.classmethod.flag.invoke
    flag(:living)

    #
    def initialize(*args, **kwargs)
      TAGF::Mixin::Debugging.invocation
      self.static	= false
      self.initialize_element(*args, **kwargs)
      if (kwargs[:is_container])
        #
        # @todo
        #   Reconcile this with TAGF.mixin, its super, and
        #   self.include.
        #
        self.singleton_class.include(Mixin::Container)
        self.initialize_container(*args, **kwargs)
      end
      self.game.add(self)
    end                         # def initialize

    #
    def inspect
      result		= format('#<%s:"%s" ' \
                                 + 'game="%s"' \
                                 + ', name="%s"' \
                                 + ', static=%s' \
                                 + ', %s' \
                                 + '>',
                                 self.class.name,
                                 self.eid.to_s,
                                 self.game.eid.to_s,
                                 self.name.to_s,
                                 self.static.inspect,
                                 (self.container? \
                                  ? (self.inventory.empty? \
                                     ? 'container (empty)' \
                                     : 'container ([...])') \
                                  : 'no inventory'))
      return result
    end                         # def inspect

    nil
  end                           # class Item

end                             # module TAGF

# Local Variables:
# mode: ruby
# indent-tabs-mode: nil
# eval: (if (intern-soft "fci-mode") (fci-mode 1))
# eval: (auto-fill-mode 1)
# End:
