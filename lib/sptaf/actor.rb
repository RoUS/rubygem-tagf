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

# @!macro doc.TAF
module TAF

  #
  module ActorMixin

    #
    class << self

      #
      # @return [void]
      #
      def included(klass)
        whoami		= '%s eigenclass.%s' \
                          % [self.name, __method__.to_s]
        warn('%s called for %s' \
             % [whoami, klass.name])
        [ TAF::ClassMethods, TAF::ClassMethods::Thing].each do |xmodule|
          warn('%s extending %s with %s' \
               % [whoami, klass.name, xmodule.name])
          klass.extend(xmodule)
        end
        return nil
      end                       # def included

      nil
    end                         # module ActorMixin eigenclass

    #
    include(::TAF::ContainerMixin)

    #
    int_accessor(:maxhp)

    #
    int_accessor(:hp)

    #
    attr_accessor(:attitude)
    
    #
    attr_reader(:breadcrumbs)

    #
    def initialize_actor(*args, **kwargs)
      warn('[%s]->%s running' % [self.class.name, __method__.to_s])
      @breadcrumbs	= []
      kwargs_defaults	= {
        maxhp:		0,
        hp:		0,
        attitude:	:neutral
      }
      self.initialize_thing(*args, kwargs_defaults.merge(kwargs))
    end                         # def initialize_actor

    nil
  end                           # module ActorMixin

  #
  class NPC

    #
    attr_accessor(:maxhp)

    #
    attr_accessor(:hp)

    #
    attr_accessor(:attitude)
    
    include(::TAF::ContainerMixin)

    #
    attr_reader(:breadcrumbs)

    #
    def initialize(*args, **kwargs)
      warn('[%s]->%s running' % [self.class.name, __method__.to_s])
      @breadcrumbs	= []
      self.initialize_thing(*args, **kwargs)
      self.initialize_container(*args, **kwargs)
      unless (self.inventory)
        self.game.create_inventory_on(self,
                                      game:	self.game,
                                      owned_by:	self)
      end

    end                         # def initialize

    nil
  end                           # class Player

  nil
end                             # module TAF

# Local Variables:
# mode: ruby
# indent-tabs-mode: nil
# eval: (if (intern-soft "fci-mode") (fci-mode 1))
# End:
