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

#require('tagf/debugging')
#warn(__FILE__) if (TAGF.debugging?(:file))
#require('tagf')
require_relative('mixin/dtypes')
require_relative('mixin/universal')

# @!macro doc.TAGF.module
module TAGF

  # @!macro doc.TAGF.Exceptions.module
  module Exceptions

    #
    include(TAGF::Mixin::UniversalMethods)

    #
    class ErrorBase < StandardError

      #
      extend(TAGF::Mixin::DTypes)

      #
      include(TAGF::Mixin::UniversalMethods)

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

      #
      def _dbg_exception_start(msym)
        TAGF::Mixin::Debugging.invocation
        return nil
      end                       # def _dbg_exception_start

      nil
    end                         # class ErrorBase

    # @!macro doc.TAGF.Exceptions.InventoryLimitExceeded.module
    module InventoryLimitExceeded

      #
      extend(TAGF::Mixin::DTypes)

      #
      include(TAGF::Mixin::UniversalMethods)

      #
      class LimitItems < ::TAGF::Exceptions::ErrorBase

        #
        # @!macro doc.TAGF.formal.kwargs
        # @return [InventoryLimitExceeded::LimitItems] self
        #
        def initialize(*args, **kwargs)
          _dbg_exception_start(__method__)
          inv		= args[0]
          newitem	= args[1]
          if (inv.kind_of?(String))
            msg		= inv
          else
            owner	= inv.owned_by
            owner_klass	= owner.class.name
            owner_name	= owner.name
            owner_eid	= owner.eid
            msg		= format('inventory for %s:"%s" is full; ' \
                                 + '%i/%i %s, cannot add "%s"',
                                 owner_klass,
                                 (owner_name || owner_eid).to_s,
                                 owner.items_current,
                                 owner.capacity_items,
                                 pluralise('item',
                                           owner.capacity_items),
                                 (newitem.name || newitem.eid).to_s)
          end
          self._set_message(msg)
        end                     # def initialize

        nil
      end                       # class LimitItems

      nil
    end                         # module InventoryLimitExceeded

    #
    # Bring a more deeply nested definition up to this level.
    # @see TAGF::Exceptions::InventoryLimitExceeded::LimitItems
    #
    LimitItems		= InventoryLimitExceeded::LimitItems

    #
    class NoLoadFile < ErrorBase

      #
      # @!macro doc.TAGF.formal.kwargs
      # @return [NoLoadFile] self
      #
      def initialize(*args, **kwargs)
        _dbg_exception_start(__method__)
        arg		= args[0]
        if ((args.count == 1) && arg.kind_of?(String))
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
      # @!macro doc.TAGF.formal.kwargs
      # @return [BadLoadFile] self
      #
      def initialize(*args, **kwargs)
        _dbg_exception_start(__method__)
        arg		= args[0]
        if ((args.count == 1) && arg.kind_of?(String))
          msg		= arg
        else
          if ((loadfile = kwargs[:file]).nil?)
            msg		= 'invalid file specified for game load'
          else
            if ((exc = kwargs[:exception]) && exc.kind_of?(Exception))
              msg	= format('invalid file "%s" specified: %s',
                                 loadfile,
                                 exc.to_s)
            else
              msg	= format('invalid file "%s" specified',
                                 loadfile)
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
      # @!macro doc.TAGF.formal.kwargs
      # @return [NotExceptionClass] self
      #
      def initialize(*args, **kwargs)
        _dbg_exception_start(__method__)
        arg		= args[0]
        if ((args.count == 1) && arg.kind_of?(String))
          msg		= arg
        else
          objtype	= arg.class.name
          msg		= format('not an exception class: %s:%s',
                                 objtype,
                                 arg.to_s)
        end
        self._set_message(msg)
      end                       # def initialize

      nil
    end                         # class NotExceptionClass

    #
    class NotGameElement < ErrorBase

      #
      # @!macro doc.TAGF.formal.kwargs
      # @return [NotGameElement] self
      #
      def initialize(*args, **kwargs)
        _dbg_exception_start(__method__)
        arg		= args[0]
        if ((args.count == 1) && arg.kind_of?(String))
          msg		= arg
        else
          objtype	= arg.class.name
          msg		= format('not a game object: <%s>[%s]',
                                 objtype,
                                 arg.to_s)
        end
        self._set_message(msg)
      end                       # def initialize

      nil
    end                         # class NotGameElement

    #
    class NoObjectOwner < ErrorBase

      #
      # @!macro doc.TAGF.formal.kwargs
      # @return [NoObjectOwner] self
      #
      def initialize(*args, **kwargs)
        _dbg_exception_start(__method__)
        arg		= args[0]
        if ((args.count == 1) && arg.kind_of?(String))
          msg		= arg
        else
          objtype	= arg.class.name
          msg		= format('no owner specified ' \
                                 + 'on creation of: %s:%s',
                                 objtype,
                                 arg.to_s)
        end
        self._set_message(msg)
      end                       # def initialize

      nil
    end                         # class NoObjectOwner

    #
    class KeyObjectMismatch < ErrorBase

      #
      # @!macro doc.TAGF.formal.kwargs
      # @return [KeyObjectMismatch] self
      #
      def initialize(oeid=nil, obj=nil, ckobj=nil, iname=nil, **kwargs)
        _dbg_exception_start(__method__)
        oeid		= args[0] || kwargs[:eid]
        obj		= args[1] || kwargs[:object]
        ckobj		= args[2] || kwargs[:ckobject]
        iname		= args[3] || kwargs[:inventory_name]

        msg		= format("value for key '%s' in %s " \
                                 + "fails to match: %s:'%s' " \
                                 + "instead of %s:'%s'",
                                 oeid.to_s,
                                 iname,
                                 (ckobj.name || ckobj.eid).to_s,
                                 (obj.name || obj.eid).to_s)
        self._set_message(msg)
      end                       # def initialize

      nil
    end                         # class KeyObjectMismatch

    #
    class NoGameContext < ErrorBase

      #
      # @!macro doc.TAGF.formal.kwargs
      # @return [NoGameContext] self
      #
      def initialize(*args, **kwargs)
        _dbg_exception_start(__method__)
        if ((args.count == 1) && args[0].kind_of?(String))
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
      # @!macro doc.TAGF.formal.kwargs
      # @return [SettingLocked] self
      #
      def initialize(*args, **kwargs)
        _dbg_exception_start(__method__)
        arg	= args[0]
        if ((args.count == 1) && arg.kind_of?(String))
          msg	= arg
        elsif (arg.kind_of?(Symbol))
          msg	= format("attribute '%s' is already set " \
                         + 'and cannot be changed',
                         arg.to_s)
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
      # @!macro doc.TAGF.formal.kwargs
      # @return [ImmovableObject] self
      #
      def initialize(*args, **kwargs)
        _dbg_exception_start(__method__)
        arg	= args[0]
        if ((args.count == 1) && arg.kind_of?(String))
          msg	= arg
        else
          obj	= args[0]
          objtype = obj.class.name.sub(%r!^.*::!, '')
          name	= obj.name || obj.eid
          if (name)
            msg	= format("%s object '%s' is static " \
                         + 'and cannot be relocated',
                         objtype,
                         name)
          else
            msg	= format('%s object is static ' \
                         + 'and cannot be relocated',
                         objtype)
          end
        end
        self._set_message(msg)
      end                       # def initialize

      nil
    end                         # class ImmovableObject

    #
    class NotAContainer < ErrorBase

      #
      # @!macro doc.TAGF.formal.kwargs
      # @return [NotAContainer] self
      #
      def initialize(*args, **kwargs)
        _dbg_exception_start(__method__)
        arg		= args[0]
        name		= nil
        if ((args.count == 1) && arg.kind_of?(String))
          msg		= arg
        else
          obj		= args[0]
          objtype	= obj.class.name
          name		= format('<%s>[%s]', objtype, obj.eid.to_s)
          msg		= format('element %s is not a container',
                                 name ? name : objtype)
        end
        self._set_message(msg)
      end                       # def initialize

      nil
    end                         # class NotAContainer

    #
    # In-game language syntax errors.
    #

    #
    class AliasRedefinition < ErrorBase

      #
      # @!macro doc.TAGF.formal.kwargs
      # @return [AliasRedefinition] self
      #
      def initialize(*args, **kwargs)
        _dbg_exception_start(__method__)
        arg		= args[0]
        name		= nil
        if ((args.count == 1) && arg.kind_of?(String))
          msg		= arg
        else
          obj		= args[0]
          objtype	= obj.class.name
          name		= format('<%s>[%s]', objtype, obj.eid.to_s)
          msg		= format('element %s is not a container',
                                 name ? name : objtype)
        end
        self._set_message(msg)
      end                       # def initialize

      nil
    end                         # class AliasRedefined

    #
    class UnscrewingInscrutable < ErrorBase

      extend(Contracts::Core)
      
      Contract([Class,
                Class,
                Symbol,
                Object,
                Class,
                Class,
                Symbol,
                Object] => Contracts::Builtin::Any)

      #
      # @!macro doc.TAGF.formal.kwargs
      # @return [UnscrewingInscrutable] self
      #
      def initialize(*args, **kwargs)
        _dbg_exception_start(__method__)
        arg		= args[0]
        name		= nil
        if ((args.count == 1) && arg.kind_of?(String))
          msg		= arg
        else
          msgargs	= []
          msgargs.push(args[0].class.name)
          msgargs.push(args[0].eid.to_s)
          msgargs.push(args[1].to_s.sub(%r![^[:alnum:]]$!, ''))
          msgargs.push(args[2].to_s)
          msgargs.push(args[3].class.name)
          msgargs.push(args[3].eid.to_s)
          msgargs.push(args[4].to_s.sub(%r![^[:alnum:]]$!, ''))
          msgargs.push(args[5].to_s)
          msg		= format('<%s>[%s].%s cannot be set to %s ' \
                                 + 'if <%s>[%s].%s is %s',
                                 *msgargs)
        end
        self._set_message(msg)
      end                       # def initialize

      nil
    end                         # class UnscrewingInscrutable

    #
    class MasterInventory < ErrorBase

      #
      # @!macro doc.TAGF.formal.kwargs
      # @return [MasterInventory] self
      #
      def initialize(*args, **kwargs)
        _dbg_exception_start(__method__)
        arg	= args[0]
        if ((args.count == 1) && arg.kind_of?(String))
          msg	= arg
        else
          obj	= args[0]
          objtype	= obj.class.name.sub(%r!^.*::!, '')
          name	= obj.name || obj.eid
          if (name)
            msg	= format("cannot remove %s object '%s' " \
                         + 'from the master inventory',
                         objtype,
                         name)
          else
            msg	= format('cannot remove %s object ' \
                         + 'from the master inventory',
                         objtype)
          end
        end
        self._set_message(msg)
      end                       # def initialize

      nil
    end                         # class MasterInventory

    #
    class HasNoInventory < ErrorBase

      #
      # @!macro doc.TAGF.formal.kwargs
      # @return [HasNoInventory] self
      #
      def initialize(*args, **kwargs)
        _dbg_exception_start(__method__)
        if ((args.count == 1) && args[0].kind_of?(String))
          msg		= args[0]
        elsif (args[0].kind_of?(Mixin::Element))
          name		= args[0].name || args[0].eid.to_s
          case(args.count)
          when 0
            msg		= 'object has no inventory'
          when 1
            msg		= format("%s object '%s' has no inventory",
                                 args[0].class.name,
                                 name)
          else
            msg		= format('unforeseen arguments to ' \
                                 + 'exception: %s',
                                 args.inspect)
          end                   # case(args.count)
        end
        self._set_message(msg)
      end                       # def initialize

      nil
    end                         # class HasNoInventory

    #
    class AlreadyHasInventory < ErrorBase

      #
      # @!macro doc.TAGF.formal.kwargs
      # @return [AlreadyHasInventory] self
      #
      def initialize(*args, **kwargs)
        _dbg_exception_start(__method__)
        if ((args.count >= 1) && args[0].kind_of?(String))
          msg		= args[0]
        else
          target	= arg[0]
          unless (target.has_inventory?)
            raise_exception(RuntimeError,
                            format('%s called against ' \
                                   + 'an element (<%s>[%s]) ' \
                                   + "which *doesn't* have " \
                                   + 'an inventory',
                                   self.class.name,
                                   target.class.name,
                                   target.eid.to_s),
                            levels: -1)
          end
          msg		= format('cannot replace ' \
                                 + 'existing inventory for <%s>[%s]',
                                 target.class.name,
                                 target.eid.to_s)
        end
        self._set_message(msg)
      end                       # def initialize

      nil
    end                         # class AlreadyHasInventory

    #
    class AlreadyInInventory < ErrorBase

      #
      # @!macro doc.TAGF.formal.kwargs
      # @return [AlreadyInInventory] self
      #
      def initialize(*args, **kwargs)
        _dbg_exception_start(__method__)
        type		= self.class.name.sub(%r!^.*Duplicate!, '')
        if ((args.count >= 1) && args[0].kind_of?(String))
          msg		= args[0]
        elsif (args[0..[args.count-1,1].min].all? { |o| o.kind_of?(Mixin::Element) })
          case(args.count)
          when 0
            msg		= 'object already in inventory'
          when 1
            msg		= format("%s object '%s' " \
                                 + 'already in inventory',
                                 args[0].class.name,
                                 (args[0].name || args[0].eid).to_s)
          when 2
            msg		= format("%s object '%s' " \
                                 + 'already in inventory, ' \
                                 + 'cannot add %s with same eid',
                                 args[0].class.name,
                                 (args[0].name || args[0].eid).to_s,
                                 args[1].class.name)
          else
            msg		= format('unforeseen arguments ' \
                                 + 'to exception: %s',
                                 args.inspect)
          end                   # case(args.count)
        end
        self._set_message(msg)
      end                       # def initialize

      nil
    end                         # class AlreadyInInventory

    #
    class ImmovableElementDestinationError < ErrorBase

      #
      # @!macro doc.TAGF.formal.kwargs
      # @return [ImmovableElementDestinationError] self
      #
      def initialize(*args, **kwargs)
        _dbg_exception_start(__method__)
        if ((args.count >= 1) && args[0].kind_of?(String))
          msg		= args[0]
        else
          target	= args[0]
          newcontent	= args[1]
          if (newcontent.kind_of?(Class))
            newobject	= format('<%s>', newcontent.class.name)
          else
            newobject	= format('<%s>[%s]',
                                 newcontent.class.name,
                                 newcontent.eid.to_s)
          end
          msg		= format('element %s is static and cannot be ' \
                                 + 'stored in inventory of %s',
                                 target,
                                 newcontent)
        end
        self._set_message(msg)
      end                       # def initialize

      nil
    end                         # class ImmovableElementDestinationError

    #
    class DuplicateObject < ErrorBase

      #
      # @!macro doc.TAGF.formal.kwargs
      # @return [DuplicateObject] self
      #
      def initialize(*args, **kwargs)
        _dbg_exception_start(__method__)
        type	= self.class.name.sub(%r!^.*Duplicate!, '')
        if ((args.count == 1) && args[0].kind_of?(String))
          msg	= args[0]
        elsif (args[0].respond_to?(:eid))
          msg	= format('attempt to register ' \
                         'new %s using existing UID %s',
                         type,
                         args[0].eid)
        else
          msg	= format('attempt to register new %s ' \
                         + 'with existing UID',
                         type)
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
  end                           # module TAGF::Exceptions

  nil
end                             # module TAGF

# Local Variables:
# mode: ruby
# indent-tabs-mode: nil
# eval: (if (intern-soft "fci-mode") (fci-mode 1))
# eval: (auto-fill-mode 1)
# End:
