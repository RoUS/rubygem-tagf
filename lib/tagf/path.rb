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
require('tagf/mixin/universal')
require('byebug')

# @!macro doc.TAGF.module
module TAGF

  #
  class Path

    #
    include(Mixin::UniversalMethods)
    include(Mixin::DTypes)
    include(Mixin::Element)

    # @!macro TAGF.constant.Loadable_Fields
    Loadable_Fields		= [
      'origin',
      'destination',
      'via',
      'must_possess',
      'reversible',
    ]

    # @!macro TAGF.constant.Abstracted_Fields
    Abstracted_Fields		= {
      origin:			EID,
      destination:		EID,
    }

    # @!attribute [rw] reversible
    # @!macro doc.TAGF.classmethod.flag.invoke
    # @return [Boolean]
    #   whether or not the path can be followed in reverse.
    flag(:reversible)

    # @!attribute [rw] origin
    # @see #destination
    # @see #via
    # @return [TAGF::Location]
    #   The Location at which the path originates.
    attr_accessor(:origin)

    # @!attribute [rw] destination
    # @see #origin
    # @see #via
    # @return [TAGF::Location]
    #   The Location at which the path terminates.
    attr_accessor(:destination)

    # @!attribute [rw] via
    # @see #origin
    # @see #destination
    # @return [Array<String>]
    #   The direction keywords (such as `"se"`) that leave the origin
    #   and follow the path to the destination.
    attr_reader(:via)
    def via=(val)
      if (! val.kind_of?(Array))
        val		= [ *val ]
      end
      @via		= val
    end                         # def via=(val)

    attr_accessor(:must_possess)

    # @!method conflicts(*args, **kwargs)
    #
    def conflicts(*args, **kwargs)
      result		= []
      args.each do |other|
        other_via	= [ *other.via ]
        unless ((self.via & other_via).empty?)
          result.push(other)
        end
      end
      result		= nil if (result.empty?)
      return result
    end                         # def conflicts

    # @!method initialize(*args, **kwargs)
    def initialize(*args, **kwargs)
      TAGF::Mixin::Debugging.invocation
      self.is_visible!
      self.initialize_element(*args, **kwargs)
    end                         # def initialize(*args, **kwargs)

    nil
  end                           # class Path

  nil
end                             # module TAGF

# Local Variables:
# mode: ruby
# indent-tabs-mode: nil
# eval: (if (intern-soft "fci-mode") (fci-mode 1))
# eval: (auto-fill-mode 1)
# End:
