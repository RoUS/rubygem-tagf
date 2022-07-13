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
  class NotGameElement < ErrorBase

    #
    def initialize(*args, **kwargs)
      arg		= args[0]
      if (arg.kind_of?(String))
        msg		= arg
      else
        objtype		= arg.class.name
        msg		= 'not a game object: %s:%s' \
                          % [objtype, arg.to_s]
      end
      self._set_message(msg)
    end                         # def initialize

    nil
  end                           # class NotGameElement

  #
  class NoObjectOwner < ErrorBase

    #
    def initialize(*args, **kwargs)
      arg		= args[0]
      if (arg.kind_of?(String))
        msg		= arg
      else
        objtype		= arg.class.name
        msg		= 'no owner specified on creation of: %s:%s' \
                          % [objtype, arg.to_s]
      end
      self._set_message(msg)
    end                         # def initialize

    nil
  end                           # class NoObjectOwner

  #
  class KeyObjectMismatch < ErrorBase

    #
    def initialize(oslug=nil, obj=nil, ckobj=nil, iname=nil, **kwargs)
      oslug		= args[0] || kwargs[:slug]
      obj		= args[1] || kwargs[:object]
      ckobj		= args[2] || kwargs[:ckobject]
      iname		= args[3] || kwargs[:inventory_name]

      msg		= ("value for key '%s' in %s fails to match: " \
                          + "%s:'%s' instead of %s:'%s'") \
                          % [oslug.to_s,
                             iname,
                             (ckobj.name || ckobj.slug).to_s,
                             (obj.name || obj.slug).to_s]
      self._set_message(msg)
    end                         # def initialize

    nil
  end                           # class KeyObjectMismatch

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
  class ImmovableObject < ErrorBase

    #
    def initialize(*args, **kwargs)
      arg	= args[0]
      if (arg.kind_of?(String))
        msg	= arg
      else
        obj	= args[0]
        objtype	= obj.class.name.sub(%r!^.*::!, '')
        name	= obj.name || obj.slug
        if (name)
          msg	= "%s object '%s' is static and cannot be relocated" \
                  % [objtype, name]
        else
          msg	= "%s object is static and cannot be relocated" \
                  % [objtype]
        end
      end
      self._set_message(msg)
    end                         # def initialize

    nil
  end                           # class ImmovableObject

  #
  class MasterInventory < ErrorBase

    #
    def initialize(*args, **kwargs)
      arg	= args[0]
      if (arg.kind_of?(String))
        msg	= arg
      else
        obj	= args[0]
        objtype	= obj.class.name.sub(%r!^.*::!, '')
        name	= obj.name || obj.slug
        if (name)
          msg	= ("cannot remove %s object '%s' from " \
                  + 'the master inventory') \
                  % [objtype, name]
        else
          msg	= "cannot remove %s object from the master inventory" \
                  % [objtype]
        end
      end
      self._set_message(msg)
    end                         # def initialize

    nil
  end                           # class MasterInventory

  #
  class HasNoInventory < ErrorBase
    
    #
    def initialize(*args, **kwargs)
      if ((args.count == 1) && args[0].kind_of?(String))
        msg		= args[0]
      elsif (args[0].kind_of?(::TAF::Thing))
        name		= args[0].name || args[0].slug.to_s
        case(args.count)
        when 0
          msg		= 'object has no inventory'
        when 1
          msg		= ("%s object '%s' has no inventory") \
                          % [args[0].class.name,name]
        else
          msg		= 'unforeseen arguments to exception: %s' \
                          % args.inspect
        end                     # case(args.count)
      end
      self._set_message(msg)
    end                         # def initialize

    nil
  end                           # class HasNoInventory

  #
  class AlreadyInInventory < ErrorBase
    
    #
    def initialize(*args, **kwargs)
      type		= self.class.name.sub(%r!^.*Duplicate!, '')
      if ((args.count >= 1) && args[0].kind_of?(String))
        msg		= args[0]
      elsif (args[0..[args.count-1,1].min].all? { |o| o.kind_of?(::TAF::Thing) })
        case(args.count)
        when 0
          msg		= 'object already in inventory'
        when 1
          msg		= ("%s object '%s' already in inventory") \
                          % [args[0].class.name,
                             (args[0].name || args[0].slug).to_s]
        when 2
          msg		= ("%s object '%s' already in inventory, " \
                           + 'cannot add %s with same slug') \
                          % [args[0].class.name,
                             (args[0].name || args[0].slug).to_s,
                             args[1].class.name]
        else
          msg		= 'unforeseen arguments to exception: %s' \
                          % args.inspect
        end                     # case(args.count)
      end
      self._set_message(msg)
    end                         # def initialize

    nil
  end                           # class AlreadyInInventory

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
