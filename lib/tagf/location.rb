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
require('tagf/mixin/location')
require('tagf/mixin/graphable')
require('tagf/mixin/universal')
require('ruby-graphviz')
require('byebug')

# @!macro doc.TAGF.module
module TAGF

  #
  class Location

    #
    include(Mixin::UniversalMethods)
    include(Mixin::DTypes)
    include(Mixin::Location)
    include(Mixin::Graphable)

    # @!method export
    # `Location`-specific export method, responsible for adding any
    # unusual fields that need to be abstracted to the export hash.
    # That is, things that can't be simply boiled down to a string
    # EID.
    #
    # @return [Hash<String=>Any>]
    #   the updated export hash.
    def export
      result			= super
      pathlist			= [] | self.paths.map { |p| p.eid }
      result['paths']		= pathlist
      return result
    end                         # def export

    InventoryItemFormat		= 'There is %<article>s %<desc>s here.'

    #
    # @!macro doc.TAGF.formal.kwargs
    # @return [Location] self
    #
    def initialize(*args, **kwargs)
      TAGF::Mixin::Debugging.invocation
      @paths		||= []
      self.initialize_element(*args, **kwargs)
      self.initialize_location(*args, **kwargs)
      self.game.add(self)
    end                         # def initialize

    nil
  end                           # class Location

  nil
end                             # module TAGF

# Local Variables:
# mode: ruby
# indent-tabs-mode: nil
# eval: (if (intern-soft "fci-mode") (fci-mode 1))
# eval: (auto-fill-mode 1)
# End:
