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

  # @!macro doc.LocationMixin
  module LocationMixin

    # @!macro doc.LocationMixin.eigenclass
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

    end                         # module LocationMixin eigenclass

    include(::TAF::ContainerMixin)

    #
    attr_accessor(:paths)

    #
    def initialize(*args, **kwargs)
      warn('[%s]->%s running' % [self.class.name, __method__.to_s])
      debugger
      self.paths	||= {}
      super
    end                         # def initialize

    #
    def initialize_location(*args, **kwargs)
      warn('[%s]->%s running' % [self.class.name, __method__.to_s])
#      self.initialize_container(*args, **kwargs)
#      self.inventory	= ::TAF::Inventory.new(game:	self,
#                                              owned_by: self)
    end                         # def initialize_location

    nil
  end                           # module LocationMixin

  #
  class Location

    include(::TAF::LocationMixin)

    nil
  end                           # class Location

  nil
end                             # module TAF

# Local Variables:
# mode: ruby
# indent-tabs-mode: nil
# eval: (if (intern-soft "fci-mode") (fci-mode 1))
# End:
