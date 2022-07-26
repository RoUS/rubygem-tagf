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
require('byebug')

# @!macro doc.TAF.module
module TAF

  #
  # :direction
  # :go :direction
  # :get {Item}
  # :drop {Item}
  # :throw {Item}
  # :throw {Item} at {ActorMixin}
  # :give {Item}
  # :give {Item} to {ActorMixin}
  DEFAULTS		= {
    noun:		{
    },
    verb:		{
      go:		nil,
      get:		%i! take !,
      drop:		nil,
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
  }    

  #
  # Directions, possibly prefixed with `go` (as in `south` or
  # `go south`), and other actions (like `get`, `take`, `drop`,
  # `throw`, and so forth).
  #
  class Verb

    include(::TAF::Thing)

    #
    def initialize(*args, **kwargs)
      warn('[%s]->%s running' % [self.class.name, __method__.to_s])
      self.initialize_thing(*args, **kwargs)
    end                         # def initialize(*args, **kwargs)

    nil
  end                           # class Verb

  #
  # Like `xyzzy`, `plugh`, and `y2` in ADVENT.
  #
  class Imperative

    include(::TAF::Thing)

    #
    def initialize(*args, **kwargs)
      warn('[%s]->%s running' % [self.class.name, __method__.to_s])
      self.initialize_thing(*args, **kwargs)
    end                         # def initialize(*args, **kwargs)

    nil
  end                           # class Imperative

  #
  class Noun

    include(::TAF::Thing)

    #
    def initialize(*args, **kwargs)
      warn('[%s]->%s running' % [self.class.name, __method__.to_s])
      self.initialize_thing(*args, **kwargs)
    end                         # def initialize(*args, **kwargs)

    nil
  end                           # class Noun

  nil
end                             # module TAF

# Local Variables:
# mode: ruby
# indent-tabs-mode: nil
# eval: (if (intern-soft "fci-mode") (fci-mode 1))
# End:
