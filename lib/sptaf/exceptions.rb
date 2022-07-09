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

require_relative('classmethods')
require_relative('container')

# @!macro TAFDoc
module TAF

  #
  class ErrorBase < StandardError

    #
    def _set_message(text)
      self.define_singleton_method(:message) {
        return %Q[#{text}]
      }
      self.define_singleton_method(:inspect) {
        return %Q[#<#{self.class.name}: #{self.message}>]
      }
    end                         # def _set_message
    protected(:_set_message)

    nil
  end                           # class ErrorBase

  #
  class NoGameContext < ErrorBase

    #
    def initialize(*args, **kwargs)
      if (args[0].kind_of?(String))
        msg	= args[0]
      else
        msg	= 'attempt to create in-game object failed (#game not set)'
      end
      self._set_message(msg)
    end                         # def initialize

    nil
  end                           # class NoGameContext

  #
  class SettingLocked < ErrorBase

    #
    def initialize(*args, **kwargs)
      arg	= args[0]
      if (arg.kind_of?(String))
        msg	= arg
      elsif (arg.kind_of?(Symbol))
        msg	= "attribute '#{arg.to_s}' is already set " \
                  + 'and cannot be changed'
      else
        msg	= 'specific attribute cannot be changed once set'
      end
      self._set_message(msg)
    end                         # def initialize

    nil
  end                           # class SettingLocked

  #
  class DuplicateObject < ErrorBase
    
    #
    def initialize(*args, **kwargs)
      type		= self.class.name.sub(%r!^.*Duplicate!, '')
      if ((args.count == 1) && args[0].kind_of?(String))
        msg	= args[0]
      elsif (args[0].respond_to?(:slug))
        msg	= 'attempt to register new %s using existing UID %s' \
                  % [type,args[0].slug]
      else
        msg	= 'attempt to register new %s with existing UID' \
                  % type
      end
      self._set_message(msg)
    end                         # def initialize

    nil
  end                           # class DuplicateObject

  #
  class DuplicateItem < DuplicateObject ; end

  #
  class DuplicateLocation < DuplicateObject ; end

  nil
end                             # module TAF

# Local Variables:
# mode: ruby
# indent-tabs-mode: nil
# eval: (if (intern-soft "fci-mode") (fci-mode 1))
# End:
