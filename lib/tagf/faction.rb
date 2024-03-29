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
require('tagf/mixin/dtypes')
require('tagf/mixin/element')
require('tagf/exceptions')
require('byebug')

# @!macro doc.TAGF.module
module TAGF

  #
  # Every actor is a member of a Faction, even if it's the
  # <strong>only</strong> member.  Factions are how 'reputation' and
  # inter-actor compatibility are managed in large; any racial
  # attitude between elves and humans, for instance, would be
  # represented at the faction level.  Individual actor objects can
  # have more fine-tuned attitudes.
  #
  class Faction

    #
    include(Mixin::DTypes)
    include(Mixin::Element)
    include(Exceptions)

    # @!macro TAGF.constant.Loadable_Fields
    Loadable_Fields		= {
      'attitude'		=> FieldDef.new(
        name:			'attitude',
        datatype:		String,
        description:		'TBS'
      ),
    }

    # @!attribute [rw] attitude
    # Provides a default attitude for all members of a faction.
    # Changing this will change all members' attitudes.
    #
    # @see C_Attitudes
    #
    attr_reader(:attitude)
    def attitude=(newattitude)
      unless (C_Attitudes.include?(newattitude))
        raise_exception(InvalidAttitude, newattitude)
      end
      @attitude		= newattitude
      self.update_all_members!
      return newattitude
    end                         # attitude=(newattitude)

    #
    def update_all_members!
      newattitude	= self.attitude
      actorenum		= @game.filter(klass: TAGF::Mixin::Actor,
                                       faction: self)
      if (actorenum)
        actorenum.each do |actor|
          actor.attitude = newattitude
        end
      end
    end                         # def update_all_members!

    #
    # @!macro doc.TAGF.formal.kwargs
    # @return [Faction] self
    #
    def initialize(*args, **kwargs)
      TAGF::Mixin::Debugging.invocation
      initialize_element(*args, **kwargs)
      if (self.name.nil?)
        raise_exception(NameRequired,
                        element: self)
      end
      return self
    end                         # def initialize(*args, **kwargs)

    nil
  end                           # class Faction

  nil
end                             # module TAGF

# Local Variables:
# mode: ruby
# indent-tabs-mode: nil
# eval: (if (intern-soft "fci-mode") (fci-mode 1))
# eval: (auto-fill-mode 1)
# End:
