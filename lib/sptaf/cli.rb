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
TAF.require_file('ostruct')
TAF.require_file('byebug')

# @!macro doc.TAF.module
module TAF

  #
  # Directions, possibly prefixed with `go` (as in `south` or
  # `go south`), and other actions (like `get`, `take`, `drop`,
  # `throw`, and so forth).
  #
  class Verb

    #
    TAF.mixin(Mixin::Thing)

    #
    # @return [String]
    #
    attr_accessor(:name)

    #
    # @return [???]
    #
    attr_accessor(:type)

    #
    # @return [???]
    #
    attr_accessor(:objects)

    #
    # @return [???]
    #
    attr_accessor(:prepositions)

    #
    # @return [???]
    #
    attr_accessor(:target)

    #
    # @!macro doc.TAF.formal.kwargs
    # @return [Verb] self
    #
    def initialize(*args, **kwargs)
      warn('[%s]->%s running' % [self.class.name, __method__.to_s])
      kwargs[:type] = :intransitive unless (kwargs[:type])
      self.initialize_thing(*args, **kwargs)
      return self
    end                         # def initialize(*args, **kwargs)

    nil
  end                           # class Verb

  #
  # Like `xyzzy`, `plugh`, and `y2` in ADVENT.
  #
  class Imperative

    #
    TAF.mixin(Mixin::Thing)

    #
    # @!macro doc.TAF.formal.kwargs
    # @return [Imperative] self
    def initialize(*args, **kwargs)
      warn('[%s]->%s running' % [self.class.name, __method__.to_s])
      self.initialize_thing(*args, **kwargs)
      return self
    end                         # def initialize(*args, **kwargs)

    nil
  end                           # class Imperative

  #
  class Noun

    #
    TAF.mixin(Mixin::Thing)

    #
    # @!macro doc.TAF.formal.kwargs
    # @return [Noun] self
    #
    def initialize(*args, **kwargs)
      warn('[%s]->%s running' % [self.class.name, __method__.to_s])
      self.initialize_thing(*args, **kwargs)
    end                         # def initialize(*args, **kwargs)

    nil
  end                           # class Noun

  #
  # :l
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
  # :throw {Item} at {Mixin::Actor}
  # :give {Item}
  # :give {Item} to {Mixin::Actor}
  # :attack
  # :attack with {Item}
  # :attack {Mixin::Actor}
  # :attack {Mixin::Actor} with {Item}
  # :kill {Item}
  # :kill {Item} with {Item}
=begin
  DEFAULTS              = {
    noun:               {
    },
    verb:               {
      l:                Verb.new(type:          :intransitive),
      look:             Verb.new(type:          :intransitive),
      inventory:        Verb.new(alii:          %i[ i invent ],
                                 type:          :intransitive),
      go:               Verb.new(objects:       :direction,
                                 type:          :transitive),
      get:              Verb.new(alii:          %i[ g take ],
                                 type:          :transitive,
                                 object:        [ :all, Item ],
                                 :clause =>     {
                                   :optional => { :from => [ Mixin::Actor,
                                                             Item,
                                                             Feature
                                                           ]
                                                }
                                 }),
      drop:             Verb.new(type:          :transitive,
                                 object:        [ :all, Item ]),
      place:            Verb.new(alii:          %i[ put ],
                                 type:          :transitive,
                                 object:        [ :all, Item ],
                                 :clause =>     {
                                   :required => { in: [ Item ],
                                                  on: [ Feature ]
                                                }
                                 }),
      #
      # `throw` is a Ruby keyword, so beware..
      #
      throw:            nil,
    },
    direction:          {
      #
      # Special direction: return to previous location if possible.
      #
      back:             nil,
      north:            %i! n    !,
      northeast:        %i! ne   !,
      east:             %i! e    !,
      southeast:        %i! se   !,
      south:            %i! s    !,
      west:             %i! w    !,
      up:               %i! u    !,
      down:             %i! d    !,
    },
    #
    # These assume the player is facing a particular direction, and we
    # can figure out to which compass direction they refer.
    #
    handed:             {
      left:             nil,
      right:            nil,
      forward:          %i! straight !,
    },
  }
=end

  nil
end                             # module TAF

# Local Variables:
# mode: ruby
# indent-tabs-mode: nil
# eval: (if (intern-soft "fci-mode") (fci-mode 1))
# End:
