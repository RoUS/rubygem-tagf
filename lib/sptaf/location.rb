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

require_relative('version')
require_relative('classmethods')
require_relative('container')
require_relative('exceptions')

# @!macro TAFDoc
module TAF

  # @!macro LocationMixinDoc
  module LocationMixin

    class << self

      def included(klass)
        klass.include(::TAF::ContainerMixin)
      end                       # def included

    end                         # module LocationMixin eigenclass

    attr_accessor(:paths)

    #
    def initialize(*args, **kwargs)
      warn('[TAF::LocationMixin] initialize')
      self.paths	||= {}
      super
    end                         # def initialize

    nil
  end                           # module LocationMixin

  #
  class Location

    include(::TAF::Thing)
    include(::TAF::LocationMixin)

    #
    def initialize(*args, **kwargs)
      self.object_setup do
        warn('[%s] initialize' % [self.class.name])
        self.inventory	= ::TAF::Inventory.new(game:	self,
                                               owner:	self)
        super
      end
    end                         # def initialize

    nil
  end                           # class Location

  nil
end                             # module TAF

# Local Variables:
# mode: ruby
# indent-tabs-mode: nil
# eval: (if (intern-soft "fci-mode") (fci-mode 1))
# End:
