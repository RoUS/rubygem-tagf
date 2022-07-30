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
require_relative('classmethods')
require('ostruct')
require('byebug')

# @!macro doc.TAF.module
module TAF

  #
  # Directions, possibly prefixed with `go` (as in `south` or
  # `go south`), and other actions (like `get`, `take`, `drop`,
  # `throw`, and so forth).
  #
  class Verb

    include(Mixins::Thing)

    #
    attr_accessor(:name)

    #
    attr_accessor(:type)

    #
    attr_accessor(:objects)

    #
    attr_accessor(:prepositions)

    #
    attr_accessor(:target)

    #
    def initialize(*args, **kwargs)
      warn('[%s]->%s running' % [self.class.name, __method__.to_s])
      kwargs[:type] = :intransitive unless (kwargs[:type])
      self.initialize_thing(*args, **kwargs)
    end                         # def initialize(*args, **kwargs)

    nil
  end                           # class Verb

  #
  # Like `xyzzy`, `plugh`, and `y2` in ADVENT.
  #
  class Imperative

    include(Mixins::Thing)

    #
    def initialize(*args, **kwargs)
      warn('[%s]->%s running' % [self.class.name, __method__.to_s])
      self.initialize_thing(*args, **kwargs)
    end                         # def initialize(*args, **kwargs)

    nil
  end                           # class Imperative

  #
  class Noun

    include(Mixins::Thing)

    #
    def initialize(*args, **kwargs)
      warn('[%s]->%s running' % [self.class.name, __method__.to_s])
      self.initialize_thing(*args, **kwargs)
    end                         # def initialize(*args, **kwargs)

    nil
  end                           # class Noun

  #
  # :look
  # :inventory
  # :direction
  # :go :direction
  # :go :handed (if we know facing)
  # :turn [:around|:left|:right] (if we know facing; this changes it)
  # :get {Item}
  # :get all
  # :drop {Item}
  # :drop all
  # :throw {Item}
  # :throw {Item} at {Actor}
  # :give {Item}
  # :give {Item} to {Actor}
  # :attack
  # :attack with {Item}
  # :attack {Actor}
  # :attack {Actor} with {Item}
  # :kill {Item}
  # :kill {Item} with {Item}
  DEFAULTS		= {
    noun:		{
    },
    verb:		{
      look:		Verb.new(alii:		%i[ l ],
                                 type:		:intransitive),
      inventory:	Verb.new(alii:		%i[ i invent ],
                                 type:		:intransitive),
      go:		Verb.new(objects:	:direction,
                                 type:		:transitive),
      get:		Verb.new(alii:		%i[ g take ],
                                 type:		:transitive,
                                 object:	[ :all, Item ],
                                 :clause =>	{
                                   :optional =>	{ :from => [ Actor,
                                                             Item,
                                                             Feature
                                                           ]
                                                }
                                 }),
      drop:		Verb.new(type:		:transitive,
                                 object:	[ :all, Item ]),
      place:		Verb.new(alii:		%i[ put ],
                                 type:		:transitive,
                                 object:	[ :all, Item ],
                                 :clause =>	{
                                   :required =>	{ in: [ Item ],
                                                  on: [ Feature ]
                                                }
                                 }),
      #
      # `throw` is a Ruby keyword, so beware..
      #
      throw:		nil,
    },
    direction:		{
      #
      # Special direction: return to previous location if possible.
      #
      back:		nil,
      north:		%i! n    !,
      northeast:	%i! ne   !,
      east:		%i! e    !,
      southeast:	%i! se   !,
      south:		%i! s    !,
      west:		%i! w    !,
      up:		%i! u    !,
      down:		%i! d    !,
    },
    #
    # These assume the player is facing a particular direction, and we
    # can figure out to which compass direction they refer.
    #
    handed:		{
      left:		nil,
      right:		nil,
      forward:		%i! straight !,
    },
  }    

  nil
end                             # module TAF

# Local Variables:
# mode: ruby
# indent-tabs-mode: nil
# eval: (if (intern-soft "fci-mode") (fci-mode 1))
# End:
