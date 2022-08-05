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
  class Location

    #
    include(Mixin::Location)

    #
    def describe(**kwargs)
      result	= "You're in %s\n" % [ self.desc ]
      self.inventory.features.each do |f|
        next unless (f.visible?)
        result	+= "  You see %s." % [f.name]
        #
        # @todo
        #   This needs to be worked; if the preposition is 'on' then
        #   the container is always open and transparent.
        #
        if (f.is_open? || f.transparent?)
          if (f.is_empty?)
            if (f.preposition == 'in')
              result += "  It is empty.\n"
            else
              result += "  There is nothing on it.\n"
            end
          end
        end
      end                       # self.inventory.features.each
      return result
    end                         # def describe(**kwargs)

    #
    # @!macro doc.TAF.formal.kwargs
    # @return [Location] self
    #
    def initialize(*args, **kwargs)
      if (debugging?(:initialize))
        warn('[%s]->%s running' \
             % [self.class.name, __method__.to_s])
      end
      debugger
      self.paths	||= {}
      self.initialize_thing(*args, **kwargs)
      self.initialize_container(*args, **kwargs)
      self.initialize_location(*args, **kwargs)
      self.game.add(self)
    end                         # def initialize

    nil
  end                           # class Location

  #
  class Connexion

    #
    include(Mixin::Thing)

    #
    # @!macro doc.TAF.classmethod.flag.use
    flag(:reversible)

    #
    attr_accessor(:source)

    #
    attr_accessor(:destination)

    #
    def initialize(*args, **kwargs)
      warn('[%s]->%s running' % [self.class.name, __method__.to_s])
      self.initialize_thing(*args, **kwargs)
    end                         # def initialize(*args, **kwargs)

    nil
  end                           # class Connexion

  nil
end                             # module TAF

# Local Variables:
# mode: ruby
# indent-tabs-mode: nil
# eval: (if (intern-soft "fci-mode") (fci-mode 1))
# End:
