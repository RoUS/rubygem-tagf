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

# @!macro doc.TAF.module
module TAF

  #
  # Defines exception classes specific to the {TAF} module.  All are
  # namespaced under `TAF::Exceptions`.
  #
  # Some exceptions are used internally for signalling conditions,
  # such as attempts to put more into a container than it can hold.
  #
  module Exceptions

    #
    class ErrorBase < StandardError

      #
      include(::TAF)

      #
      def _set_message(text)
        self.define_singleton_method(:message) {
          return %Q[#{text}]
        }
        self.define_singleton_method(:inspect) {
          return %Q[#<#{self.class.name}: #{self.message}>]
        }
      end                       # def _set_message
      protected(:_set_message)

      nil
    end                         # class ErrorBase

    #
    # Define excpetions that are used to signal problems with trying
    # to put more into an object's inventory than it can hold.  These
    # are `rescue`d in the normal flow of things.
    #
    module InventoryLimitExceeded
      
      #
      class LimitItems < ::TAF::Exceptions::ErrorBase

        #
        # @!macro doc.TAF.formal.kwargs
        def initialize(*args, **kwargs)
          inv		= args[0]
          newitem	= args[1]
          if (inv.kind_of?(String))
            msg		= inv
          else
            owner	= inv.owned_by
            owner_klass	= owner.class.name
            owner_name	= owner.name
            owner_slug	= owner.slug
            msg		= ('inventory for %s:"%s" is full; ' \
                           + '%i/%i %s, cannot add "%s"') \
                          % [owner_klass,
                             (owner_name || owner_slug).to_s,
                             owner.items_current,
                             owner.capacity_items,
                             pluralise('item', owner.capacity_items),
                             (newitem.name || newitem.slug).to_s]
          end
          self._set_message(msg)
        end                     # def initialize

        nil
      end                       # class LimitItems

    end                         # module InventoryLimitExceeded

    LimitItems		= InventoryLimitExceeded::LimitItems

    #
    class NoLoadFile < ErrorBase

      #
      # @!macro doc.TAF.formal.kwargs
      def initialize(*args, **kwargs)
        arg		= args[0]
        if (arg.kind_of?(String))
          msg		= arg
        else
          objtype	= arg.class.name
          msg		= 'no "file" keyword specified for game load'
        end
        self._set_message(msg)
      end                       # def initialize

      nil
    end                         # class NoLoadFile

    #
    class BadLoadFile < ErrorBase

      #
      # @!macro doc.TAF.formal.kwargs
      def initialize(*args, **kwargs)
        arg		= args[0]
        if (arg.kind_of?(String))
          msg		= arg
        else
          if ((loadfile = kwargs[:file]).nil?)
            msg		= 'invalid file specified for game load'
          else
            if ((exc = kwargs[:exception]) && exc.kind_of?(Exception))
              msg	= 'invalid file "%s" specified: %s' \
                          % [loadfile, exc.to_s]
            else
              msg	= 'invalid file "%s" specified' \
                          % [loadfile]
            end
          end
        end
        self._set_message(msg)
      end                       # def initialize

      nil
    end                         # class BadLoadFile

    #
    class NotExceptionClass < ErrorBase

      #
      # @!macro doc.TAF.formal.kwargs
      def initialize(*args, **kwargs)
        arg		= args[0]
        if (arg.kind_of?(String))
          msg		= arg
        else
          objtype	= arg.class.name
          msg		= 'not an exception class: %s:%s' \
                          % [objtype, arg.to_s]
        end
        self._set_message(msg)
      end                       # def initialize

      nil
    end                         # class NotExceptionClass

    #
    class NotGameElement < ErrorBase

      #
      # @!macro doc.TAF.formal.kwargs
      def initialize(*args, **kwargs)
        arg		= args[0]
        if (arg.kind_of?(String))
          msg		= arg
        else
          objtype	= arg.class.name
          msg		= 'not a game object: %s:%s' \
                          % [objtype, arg.to_s]
        end
        self._set_message(msg)
      end                       # def initialize

      nil
    end                         # class NotGameElement

    #
    class NoObjectOwner < ErrorBase

      #
      # @!macro doc.TAF.formal.kwargs
      # @return [NoObjectOwner] self
      #
      def initialize(*args, **kwargs)
        arg		= args[0]
        if (arg.kind_of?(String))
          msg		= arg
        else
          objtype	= arg.class.name
          msg		= 'no owner specified on creation of: %s:%s' \
                          % [objtype, arg.to_s]
        end
        self._set_message(msg)
      end                       # def initialize

      nil
    end                         # class NoObjectOwner

    #
    class KeyObjectMismatch < ErrorBase

      #
      # @!macro doc.TAF.formal.kwargs
      # @return [KeyObjectMismatch] self
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
      end                       # def initialize

      nil
    end                         # class KeyObjectMismatch

    #
    class NoGameContext < ErrorBase

      #
      # @!macro doc.TAF.formal.kwargs
      # @return [NoGameContext] self
      #
      def initialize(*args, **kwargs)
        if (args[0].kind_of?(String))
          msg	= args[0]
        else
          msg	= 'attempt to create in-game object failed (#game not set)'
        end
        self._set_message(msg)
      end                       # def initialize

      nil
    end                         # class NoGameContext

    #
    class SettingLocked < ErrorBase

      #
      # @!macro doc.TAF.formal.kwargs
      # @return [SettingLocked] self
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
      end                       # def initialize

      nil
    end                         # class SettingLocked

    #
    class ImmovableObject < ErrorBase

      #
      # @!macro doc.TAF.formal.kwargs
      # @return [ImmovableObject] self
      #
      def initialize(*args, **kwargs)
        arg	= args[0]
        if (arg.kind_of?(String))
          msg	= arg
        else
          obj	= args[0]
          objtype = obj.class.name.sub(%r!^.*::!, '')
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
      end                       # def initialize

      nil
    end                         # class ImmovableObject

    #
    class MasterInventory < ErrorBase

      #
      # @!macro doc.TAF.formal.kwargs
      # @return [MasterInventory] self
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
      end                       # def initialize

      nil
    end                         # class MasterInventory

    #
    class HasNoInventory < ErrorBase

      #
      # @!macro doc.TAF.formal.kwargs
      # @return [HasNoInventory] self
      #
      def initialize(*args, **kwargs)
        if ((args.count == 1) && args[0].kind_of?(String))
          msg		= args[0]
        elsif (args[0].kind_of?(Mixin::Thing))
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
          end                   # case(args.count)
        end
        self._set_message(msg)
      end                       # def initialize

      nil
    end                         # class HasNoInventory

    #
    class AlreadyInInventory < ErrorBase

      #
      # @!macro doc.TAF.formal.kwargs
      # @return [AlreadyInInventory] self
      #
      def initialize(*args, **kwargs)
        type		= self.class.name.sub(%r!^.*Duplicate!, '')
        if ((args.count >= 1) && args[0].kind_of?(String))
          msg		= args[0]
        elsif (args[0..[args.count-1,1].min].all? { |o| o.kind_of?(Mixin::Thing) })
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
          end                   # case(args.count)
        end
        self._set_message(msg)
      end                       # def initialize

      nil
    end                         # class AlreadyInInventory

    #
    class DuplicateObject < ErrorBase

      #
      # @!macro doc.TAF.formal.kwargs
      # @return [DuplicateObject] self
      #
      def initialize(*args, **kwargs)
        type	= self.class.name.sub(%r!^.*Duplicate!, '')
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
      end                       # def initialize

      nil
    end                         # class DuplicateObject

    #
    class DuplicateItem < DuplicateObject ; end

    #
    class DuplicateLocation < DuplicateObject ; end

    nil
  end                           # module Exceptions

  nil
end                             # module TAF

# Local Variables:
# mode: ruby
# indent-tabs-mode: nil
# eval: (if (intern-soft "fci-mode") (fci-mode 1))
# End:
