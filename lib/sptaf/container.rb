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
require_relative('thing')
require_relative('classmethods')
require_relative('exceptions')

# @!macro ModuleDoc
module TAF

  class Inventory

    include(::TAF::Thing)
    include(Enumerable)

    #
    attr_reader(:master)

    #
    def initialize(*args, **kwargs)
      @contents		= {}
      @master		= kwargs[:master] ? true : false
      super
    end                         # def initialize

    #
    def push(obj)
      
    end                         # def push
    alias_method(:<<, :push)

    #
    def delete(thing)
      
    end                         # def delete

    #
    def +(args)
      
    end                         # def +
    alias_method(:add, :+)

    #
    def each(&block)
      return @contents.values.each(&block)
    end                         # def each

    nil
  end                           # class Inventory

  module Container

    class << self

      def included(klass)
        klass.include(::TAF::Thing)
      end                       # def included

    end                         # module Container eigenclass

    extend ::TAF::ClassMethods::Thing

    flag(:allow_containers)

    # overload
    def items_max=(int)
      unless (int.kind_of?(Integer))
        raise(ArgumentError,
              __method__.to_s + ' requires an integer')
      end
      @items_max	= int
    end
    # overload
    def items_max
      return (@items_max ||= 0)
    end                         # def items_max

    def items_current
      return (@items_current ||= 0)
    end                         # items_current

    def mass_max
      return (@mass_max ||= 0)
    end                         # def mass_max

    def mass_current
      return (@mass_current ||= 0)
    end                         # mass_current

    def volume_max
      return (@volume_max ||= 0)
    end                         # def volume_max

    def volume_current
      return (@volume_current ||= 0)
    end                         # volume_current

    nil
  end                           # module Container

  nil
end                             # module TAF

# Local Variables:
# mode: ruby
# indent-tabs-mode: nil
# eval: (if (intern-soft "fci-mode") (fci-mode 1))
# End:
