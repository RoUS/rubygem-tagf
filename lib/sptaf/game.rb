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

require('rubygems')
require('byebug')
require_relative('thing')
require_relative('container')
require_relative('location')


# @!macro ModuleDoc
module TAF

  #
  class Game

    include(::TAF::Thing)

    #
    attr_accessor(:all_objects)

    #
    def items
      return self.all_objects.select { |o| o.kind_of?(::TAF::Item) }
    end                         # def items

    #
    def locations
      return self.all_objects.select { |o| o.kind_of?(::TAF::Location) }
    end                         # def locations

    def initialize(*args, **kwargs)
      warn('[%s] initialize running' % [ self.class.name ])
      self.game		= self
      self.all_objects	= ::TAF::Inventory.new(game:	self,
                                               owner:	self,
                                               master:	true)
      super
    end

  end                           # class Game

end                             # module TAF

# Local Variables:
# mode: ruby
# indent-tabs-mode: nil
# eval: (if (intern-soft "fci-mode") (fci-mode 1))
# End:
