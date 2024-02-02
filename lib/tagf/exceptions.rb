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
require('tagf/mixin/dtypes')
require('tagf/mixin/universal')
#require('contracts')
require('ostruct')

# @!macro doc.TAGF.module
module TAGF

  # @!macro doc.TAGF.Exceptions.module
  module Exceptions

    #
    include(TAGF::Mixin::UniversalMethods)

    # Mapping of severity names to severity levels.  Loosely modeled
    # after the OpenVMS status code structure.  The higher the number,
    # the more severe the condition.  LBS (odd number) severities are
    # actually reports rathe than problems; success or informational
    # messages.
    #
    # @see ErrorBase#severity
    SEVERITY		= OpenStruct.new(
      #
      # Not an error; used to report something that has functioned
      # exactly as designed.
      #
      success:		1,
      #
      # Not necessarily a problem; things didn't go <em>exactly</em>
      # as intended, but result/behaviour should be correct.
      #
      info:		3,
      warning:		4,
      error:		6,
      #
      # Catastropic failure of some sort; generally results in
      # application termination.
      #
      severe:		8
    )
    #
    # Alternate spellings for some of the severities.
    #
    SEVERITY.warn	= SEVERITY.warning
    SEVERITY.informational = SEVERITY.info
    SEVERITY.fatal	= SEVERITY.severe
    SEVERITY.freeze
    #
    # List of all severity values, used for validation.
    #
    SEVERITY_LEVELS	= SEVERITY.to_h.values.sort.freeze
    SEVERITY_NAMES	= SEVERITY.to_h.keys
                            .map { |l| l.to_s }
                            .sort
                            .map { |s| s.to_sym }
                            .freeze
    SEVERITY_CHAR	= [
      '0',                      # 0 = undefined
      'S',                      # 1 = success
      '2',                      # 2 = undefined
      'I',                      # 3 = informational
      'W',                      # 4 = warning
      '5',                      # 5 = undefined
      'E',                      # 6 = error
      '7',                      # 7 = undefined
      'F',                      # 8 = fatal/severe
    ]

    #
    # Hash mapping exceptions in the TAGF::Exceptions module to unique
    # integer identifiers.  The exception names (keys in the hash) are
    # represented as symbols, and the values are determined and stored
    # as part of exception class declaration.
    # @see #assign_ID
    EXCEPTION_IDS	= {}

    # Base class for this package's custom exceptions.  It enhances
    # StandardError by adding a bunch of functionality, and all of our
    # exceptions subclass it.
    class ErrorBase < StandardError

      #
      extend(TAGF::Mixin::DTypes)

      # ErrorBase eigenclass, declaring class methods for ErrorBase
      # and all classes that subclass it.
      class << self

        # @!method assign_ID
        # Assign a unique integer ID for the receiving class, and
        # store it in the Exceptions::EXCEPTION_IDS hash.  Multiple
        # invocations within the same class will always return the
        # same value.
        # @see EXCEPTION_IDS
        # @return [Integer]
        #   integer identifier unique to this class.
        def assign_ID
          our_name	= self.name.sub(%r!^.*::!, '')
          unless ((our_id = Exceptions::EXCEPTION_IDS[our_name]).nil?)
            return our_id
          end
          last_id	= Exceptions::EXCEPTION_IDS.values.max.to_i
          our_id	= last_id + 1
          Exceptions::EXCEPTION_IDS[our_name] = our_id
          #
          # Don't know why 'self.define_method(:exception_id)' isn't
          # working..
          #
          self.instance_eval(<<-EOMETH)
            def exception_id
              return #{our_id}
            end
          EOMETH
          return our_id
        end                     # def assign_id

        #
        # Array of all acceptable severity values, integers and
        # symbols.
        #
        VALID_SEVERITIES = (SEVERITY_NAMES + SEVERITY_LEVELS)

        # Given a method name symbol (<em>e.g.</em>, `:severity`),
        # return the symbol for an instance variable with the same
        # name (<em>e.g.</em>, `:@severity`.
        # @param [Symbol] msym
        # @return [Symbol]
        def _method2syms(msym)
          basevar	= msym.to_s.gsub(%r!=$!, '')
          symstruct	= OpenStruct.new(
            ivar:	format('@%s', basevar).to_sym,
            getter:	basevar.to_sym,
            setter:	format('%s=', basevar).to_sym
          )
          return symstruct
        end                     # def _method2syms(msym)

        # @!attribute [rw] severity
        # Accessors for the class-wide severity setting.
        # @overload severity
        #   @return [Integer]
        def severity
          msyms		= _method2syms(__callee__)
          unless (self.instance_variable_defined?(msyms.ivar) \
                  && self.instance_variable_get(msyms.ivar))
            warn(format('%s.%s not set, setting to :severe',
                        self.class.name,
                        msyms.getter.to_s))
            self.send(msyms.setter, SEVERITY.severe)
          end
          return @severity
        end                     # def severity

        # @overload severity=(sevlevel)
        #   @param [Symbol,Integer] sevlevel
        #   @return [Integer]
        #   @raise [TypeError]
        #   @raise [InvalidSeverity]
        def severity=(sevlevel)
          msyms		= _method2syms(__callee__)
          sevlevel	= self.validate_severity(sevlevel)
          self.instance_variable_set(msyms.ivar, sevlevel)
        end                     # def severity=

        # Verify that the given argument is a valid severity
        # indicator; namely, either a key into the {SEVERITY}
        # structure or one of the integer values to which the keys
        # map.  If the argument <em>is</em> valid, we return the
        # numeric value.
        # @param [Symbol,Integer] sevlevel
        # @return [Integer]
        # @raise [TypeError]
        # @raise [InvalidSeverity]
        def validate_severity(sevlevel)
          unless (sevlevel.kind_of?(Integer) \
                  || sevlevel.kind_of?(Symbol))
            raise_exception(TypeError,
                            format('severity level must be a ' \
                                   'symbol or integer; ' \
                                   '%s:%s is invalid',
                                   sevlevel.class.name,
                                   sevlevel.inspect),
                            levels: 2)
          end
          unless (VALID_SEVERITIES.include?(sevlevel))
            raise_exception(Exceptions::InvalidSeverity,
                            sevlevel,
                            levels: 2)
          end
          if (sevlevel.kind_of?(Symbol))
            sevlevel	= SEVERITY.send(sevlevel)
          end
          return sevlevel
        end                     # def validate_severity(sevlevel)

        nil
      end                       # ErrorBase eigenclass

      #
      #
      include(TAGF::Mixin::UniversalMethods)

      # @!attribute [rw] severity
      #   Per-exception severity level.  Separating this out allows
      #   any particular exception's severity to be altered
      #   appropriately at the time it's raised rather than be
      #   immutably defined here.
      # @overload severity
      #   @return [Integer]
      def severity
        msyms		= self.class._method2syms(__callee__)
        unless (self.instance_variable_defined?(msyms.ivar) \
                && self.instance_variable_get(msyms.ivar))
          self.send(msyms.setter, self.class.send(msyms.getter))
        end
        return self.instance_variable_get(msyms.ivar)
      end                       # def severity
      # @overload severity=(level)
      #   @param [Symbol,Integer]
      #   @return [Integer]
      def severity=(sevlevel)
        msyms		= self.class._method2syms(__callee__)
        sevlevel	= self.singleton_class.validate_severity(sevlevel)
        self.instance_variable_set(msyms.ivar, sevlevel)
      end                       # def severity=(level)

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
#        TAGF::Mixin::Debugging.invocation
        return nil
      end                       # def _dbg_exception_start

      #
      def render
        debugger
        result		= format('%s-%s, %s',
                                 SEVERITY_CHAR[self.severity] || '?',
                                 self.class.name.sub(%r!^.*::!, ''),
                                 self.message)
        return result
      end                       # def render

      # @!macro [new] superinitialize
      #   @param [Array]		   args		([])
      #   @param [Hash<Symbol=>Object>]	   kwargs	({})
      #   @option kwargs [Symbol,Integer]  :severity	(nil)
      def initialize(*args, **kwargs)
        @msg		= nil
        if ((args.count > 0) && args[0].kind_of?(String))
          @msg		||= args[0]
        end
        self.severity	||= kwargs[:severity] || SEVERITY.severe
      end                       # def initialize(*args, **kwargs)

      nil
    end                         # class ErrorBase

    # @!macro doc.TAGF.Exceptions.InventoryLimitExceeded.module
    module InventoryLimitExceeded

      #
      extend(Mixin::DTypes)

      #
      include(Mixin::UniversalMethods)

      #
      class LimitItems < ::TAGF::Exceptions::ErrorBase

        #
        # Assign this exception class a unique ID number
        #
        self.assign_ID

        self.severity	= :warning

        #
        # @!macro doc.TAGF.formal.kwargs
        # @!macro superinitialize
        # @return [InventoryLimitExceeded::LimitItems] self
        # @raise [UnsupportedObject]
        #   if args[0] doesn't respond to `:owned_by`
        def initialize(*args, **kwargs)
          _dbg_exception_start(__callee__)
          super
          inv		= args[0]
          newitem	= args[1]
          if (@msg.nil?)
            #
            # Work around the object not having an #owned_by method.
            #
            unless (inv.respond_to?(:owned_by))
              raise_exception(UnsupportedObject,
                              format('%s:%s is inappropriate ' \
                                     'for a %s exception',
                                     inv.class.name,
                                     inv.inspect,
                                     self.class.name))
            end
            owner	= inv.owned_by
            owner_klass	= owner.class.name
            owner_name	= owner.name
            owner_eid	= owner.eid
            @msg		= format('inventory for %s:"%s" is full; ' \
                                         + '%i/%i %s, cannot add "%s"',
                                         owner_klass,
                                         (owner_name || owner_eid).to_s,
                                         owner.items_current,
                                         owner.capacity_items,
                                         pluralise('item',
                                                   owner.capacity_items),
                                         (newitem.name || newitem.eid).to_s)
          end
          self._set_message(@msg)
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

    # Exception raised when an attempt is made to set the severity of
    # a TAGF exception class (or instance) to an invalid value.  Use
    # is internal to the TAGF::Exceptions module.
    #
    # @see SEVERITY
    class InvalidSeverity < ErrorBase

      #
      # Assign this exception class a unique ID number
      #
      self.assign_ID

      self.severity	= :warning

      # Constructor for InvalidSeverity exception.
      # @!macro superinitialize
      # @param [Array]			args		([])
      #   If the first element of `args` is an Integer or a Symbol, it
      #   is used to calculate the exception object's message text.
      #   If it's a String, it is used <em>verbatim</em> as the
      #   exception text.
      # @!macro doc.TAGF.formal.kwargs
      # @return [InvalidSeverity]
      #   exception object
      #
      def initialize(*args, **kwargs)
        _dbg_exception_start(__callee__)
        super
        if (@msg.nil?)
          @msg		= format('invalid severity level: %s:%s',
                                 args[0].class.name,
                                 args[0].inspect)
        end
        self._set_message(@msg)
      end                       # def initialize

      nil
    end                         # class InvalidSeverity

    #
    class BadHistoryFile < ErrorBase

      #
      # Assign this exception class a unique ID number
      #
      self.assign_ID

      self.severity	= :warning

      #
      # @!macro doc.TAGF.formal.kwargs
      # @return [NoLoadFile] self
      #
      def initialize(*args, **kwargs)
        _dbg_exception_start(__callee__)
        super
        if (@msg.nil?)
          if (args[0].nil?)
            @msg	= 'cannot open/read command history file'
          else
            @msg	= format("cannot restore history from %s\n" \
                                 + "\t%s",
                                 kwargs[:file] || '<not specified>',
                                 kwargs[:exception] || 'unknown reason')
          end
        end
        self._set_message(@msg)
      end                       # def initialize

      nil
    end                         # class BadHistoryFile

    #
    class NoLoadFile < ErrorBase

      #
      # Assign this exception class a unique ID number
      #
      self.assign_ID

      self.severity	= :error

      #
      # @!macro doc.TAGF.formal.kwargs
      # @return [NoLoadFile] self
      #
      def initialize(*args, **kwargs)
        _dbg_exception_start(__callee__)
        super
        if (@msg.nil?)
          @msg		= 'no "file" keyword specified for game load'
        end
        self._set_message(@msg)
      end                       # def initialize

      nil
    end                         # class NoLoadFile

    #
    class BadLoadFile < ErrorBase

      #
      # Assign this exception class a unique ID number
      #
      self.assign_ID

      self.severity	= :severe

      #
      # @!macro doc.TAGF.formal.kwargs
      # @return [BadLoadFile] self
      #
      def initialize(*args, **kwargs)
        _dbg_exception_start(__callee__)
        super
        if (@msg.nil?)
          if ((loadfile = kwargs[:file]).nil?)
            @msg		= 'invalid file specified for game load'
          else
            if ((exc = kwargs[:exception]) && exc.kind_of?(Exception))
              @msg	= format('invalid file "%s" specified: %s',
                                 loadfile,
                                 exc.to_s)
            else
              @msg	= format('invalid file "%s" specified',
                                 loadfile)
            end
          end
        end
        self._set_message(@msg)
      end                       # def initialize

      nil
    end                         # class BadLoadFile

    #
    class NotExceptionClass < ErrorBase

      #
      # Assign this exception class a unique ID number
      #
      self.assign_ID

      self.severity	= :error

      #
      # @!macro doc.TAGF.formal.kwargs
      # @return [NotExceptionClass] self
      #
      def initialize(*args, **kwargs)
        _dbg_exception_start(__callee__)
        super
        if (@msg.nil?)
          objtype	= args[0].class.name
          @msg		= format('not an exception class: %s:%s',
                                 objtype,
                                 arg[0].to_s)
        end
        self._set_message(@msg)
      end                       # def initialize

      nil
    end                         # class NotExceptionClass

    #
    class NotGameElement < ErrorBase

      #
      # Assign this exception class a unique ID number
      #
      self.assign_ID

      self.severity	= :severe

      #
      # @!macro doc.TAGF.formal.kwargs
      # @return [NotGameElement] self
      #
      def initialize(*args, **kwargs)
        _dbg_exception_start(__callee__)
        super
        if (@msg.nil?)
          objtype	= arg[0].class.name
          @msg		= format('not a game object: <%s>[%s]',
                                 objtype,
                                 arg[0].to_s)
        end
        self._set_message(@msg)
      end                       # def initialize

      nil
    end                         # class NotGameElement

    #
    class NoObjectOwner < ErrorBase

      #
      # Assign this exception class a unique ID number
      #
      self.assign_ID

      self.severity	= :severe

      #
      # @!macro doc.TAGF.formal.kwargs
      # @return [NoObjectOwner] self
      #
      def initialize(*args, **kwargs)
        _dbg_exception_start(__callee__)
        super
        if (@msg.nil?)
          objtype	= arg[0].class.name
          @msg		= format('no owner specified ' \
                                 + 'on creation of: %s:%s',
                                 objtype,
                                 arg[0].to_s)
        end
        self._set_message(@msg)
      end                       # def initialize

      nil
    end                         # class NoObjectOwner

    #
    class KeyObjectMismatch < ErrorBase

      #
      # Assign this exception class a unique ID number
      #
      self.assign_ID

      self.severity	= :severe

      #
      # @!macro doc.TAGF.formal.kwargs
      # @return [KeyObjectMismatch] self
      #
      def initialize(*args, **kwargs)
        _dbg_exception_start(__callee__)
        super
        if (@msg.nil?)
          oeid		= args[0] || kwargs[:eid]
          obj		= args[1] || kwargs[:object]
          ckobj		= args[2] || kwargs[:ckobject]
          iname		= args[3] || kwargs[:inventory_name]

          @msg		= format("value for key '%s' in %s " \
                                 + "fails to match: %s:'%s' " \
                                 + "instead of %s:'%s'",
                                 oeid.to_s,
                                 iname,
                                 (ckobj.name || ckobj.eid).to_s,
                                 (obj.name || obj.eid).to_s)
        end
        self._set_message(@msg)
      end                       # def initialize

      nil
    end                         # class KeyObjectMismatch

    #
    class NoGameContext < ErrorBase

      #
      # Assign this exception class a unique ID number
      #
      self.assign_ID

      self.severity	= :severe

      #
      # @!macro doc.TAGF.formal.kwargs
      # @return [NoGameContext] self
      #
      def initialize(*args, **kwargs)
        _dbg_exception_start(__callee__)
        super
        if (@msg.nil?)
          @msg		= 'attempt to create in-game object ' \
                          + 'failed (#game not set)'
        end
        self._set_message(@msg)
      end                       # def initialize

      nil
    end                         # class NoGameContext

    #
    class SettingLocked < ErrorBase

      #
      # Assign this exception class a unique ID number
      #
      self.assign_ID

      self.severity	= :warning

      #
      # @!macro doc.TAGF.formal.kwargs
      # @return [SettingLocked] self
      #
      def initialize(*args, **kwargs)
        _dbg_exception_start(__callee__)
        super
        if (@msg.nil?)
          if (arg[0].kind_of?(Symbol))
            @msg		= format("attribute '%s' is already set " \
                                         + 'and cannot be changed',
                                         arg.to_s)
          else
            @msg		= 'specific attribute cannot be changed ' \
                                  + 'once set'
          end
        end
        self._set_message(@msg)
      end                       # def initialize

      nil
    end                         # class SettingLocked

    #
    class ImmovableObject < ErrorBase

      #
      # Assign this exception class a unique ID number
      #
      self.assign_ID

      self.severity	= :error

      #
      # @!macro doc.TAGF.formal.kwargs
      # @return [ImmovableObject] self
      #
      def initialize(*args, **kwargs)
        _dbg_exception_start(__callee__)
        super
        if (@msg.nil?)
          obj		= args[0]
          objtype	= obj.class.name.sub(%r!^.*::!, '')
          name		= obj.name || obj.eid
          if (name)
            @msg		= format("%s object '%s' is static " \
                                         + 'and cannot be relocated',
                                         objtype,
                                         name)
          else
            @msg		= format('%s object is static ' \
                                         + 'and cannot be relocated',
                                         objtype)
          end
        end
        self._set_message(@msg)
      end                       # def initialize

      nil
    end                         # class ImmovableObject

    #
    class NotAContainer < ErrorBase

      #
      # Assign this exception class a unique ID number
      #
      self.assign_ID

      self.severity	= :error

      #
      # @!macro doc.TAGF.formal.kwargs
      # @return [NotAContainer] self
      #
      def initialize(*args, **kwargs)
        _dbg_exception_start(__callee__)
        super
        if (@msg.nil?)
          obj		= args[0]
          objtype	= obj.class.name
          name		= format('<%s>[%s]', objtype, obj.eid.to_s)
          @msg		= format('element %s is not a container',
                                 name ? name : objtype)
        end
        self._set_message(@msg)
      end                       # def initialize

      nil
    end                         # class NotAContainer

    #
    # In-game language syntax errors.
    #

    #
    class AliasRedefinition < ErrorBase

      #
      # Assign this exception class a unique ID number
      #
      self.assign_ID

      self.severity	= :warning

      #
      # @!macro doc.TAGF.formal.kwargs
      # @return [AliasRedefinition] self
      #
      def initialize(*args, **kwargs)
        _dbg_exception_start(__callee__)
        super
        if (@msg.nil?)
          obj		= args[0]
          objtype	= obj.class.name
          name		= format('<%s>[%s]', objtype, obj.eid.to_s)
          @msg		= format('element %s is not a container',
                                 name ? name : objtype)
        end
        self._set_message(@msg)
      end                       # def initialize

      nil
    end                         # class AliasRedefined

    #
    class UnscrewingInscrutable < ErrorBase

      #
      # Assign this exception class a unique ID number
      #
      self.assign_ID

      self.severity	= :error

#      extend(Contracts::Core)

#      Contract([Class,
#                Class,
#                Symbol,
#                Object,
#                Class,
#                Class,
#                Symbol,
#                Object] => Contracts::Builtin::Any)

      #
      # @!macro doc.TAGF.formal.kwargs
      # @return [UnscrewingInscrutable] self
      #
      def initialize(*args, **kwargs)
        _dbg_exception_start(__callee__)
        super
        if (@msg.nil?)
          msgargs	= []
          msgargs.push(args[0].class.name)
          msgargs.push(args[0].eid.to_s)
          msgargs.push(args[1].to_s.sub(%r![^[:alnum:]]$!, ''))
          msgargs.push(args[2].to_s)
          msgargs.push(args[3].class.name)
          msgargs.push(args[3].eid.to_s)
          msgargs.push(args[4].to_s.sub(%r![^[:alnum:]]$!, ''))
          msgargs.push(args[5].to_s)
          @msg		= format('<%s>[%s].%s cannot be set to %s ' \
                                 + 'if <%s>[%s].%s is %s',
                                 *msgargs)
        end
        self._set_message(@msg)
      end                       # def initialize

      nil
    end                         # class UnscrewingInscrutable

    #
    class MasterInventory < ErrorBase

      #
      # Assign this exception class a unique ID number
      #
      self.assign_ID

      self.severity	= :error

      #
      # @!macro doc.TAGF.formal.kwargs
      # @return [MasterInventory] self
      #
      def initialize(*args, **kwargs)
        _dbg_exception_start(__callee__)
        super
        if (@msg.nil?)
          obj		= args[0]
          objtype	= obj.class.name.sub(%r!^.*::!, '')
          name		= obj.name || obj.eid
          if (name)
            @msg		= format("cannot remove %s object '%s' " \
                                         + 'from the master inventory',
                                         objtype,
                                         name)
          else
            @msg		= format('cannot remove %s object ' \
                                         + 'from the master inventory',
                                         objtype)
          end
        end
        self._set_message(@msg)
      end                       # def initialize

      nil
    end                         # class MasterInventory

    #
    class HasNoInventory < ErrorBase

      #
      # Assign this exception class a unique ID number
      #
      self.assign_ID

      self.severity	= :error

      #
      # @!macro doc.TAGF.formal.kwargs
      # @return [HasNoInventory] self
      #
      def initialize(*args, **kwargs)
        _dbg_exception_start(__callee__)
        super
        if (@msg.nil?)
          if (args[0].kind_of?(Mixin::Element))
            name	= args[0].name || args[0].eid.to_s
            case(args.count)
            when 0
              @msg	= 'object has no inventory'
            when 1
              @msg	= format("%s object '%s' has no inventory",
                                 args[0].class.name,
                                 name)
            else
              @msg	= format('unforeseen arguments to ' \
                                 + 'exception: %s',
                                 args.inspect)
            end                 # case(args.count)
          end
        end
        self._set_message(@msg)
      end                       # def initialize

      nil
    end                         # class HasNoInventory

    #
    class AlreadyHasInventory < ErrorBase

      #
      # Assign this exception class a unique ID number
      #
      self.assign_ID

      self.severity	= :warning

      #
      # @!macro doc.TAGF.formal.kwargs
      # @return [AlreadyHasInventory] self
      #
      def initialize(*args, **kwargs)
        _dbg_exception_start(__callee__)
        super
        if (@msg.nil?)
          target	= args[0]
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
          @msg		= format('cannot replace ' \
                                 + 'existing inventory for <%s>[%s]',
                                 target.class.name,
                                 target.eid.to_s)
        end
        self._set_message(@msg)
      end                       # def initialize

      nil
    end                         # class AlreadyHasInventory

    #
    class AlreadyInInventory < ErrorBase

      #
      # Assign this exception class a unique ID number
      #
      self.assign_ID

      self.severity	= :warning

      #
      # @!macro doc.TAGF.formal.kwargs
      # @return [AlreadyInInventory] self
      #
      def initialize(*args, **kwargs)
        _dbg_exception_start(__callee__)
        super
        type		= self.class.name.sub(%r!^.*Duplicate!, '')
        if (@msg.nil?)
          if (args[0..[args.count-1,1].min].all? { |o| o.kind_of?(Mixin::Element) })
            case(args.count)
            when 0
              @msg	= 'object already in inventory'
            when 1
              @msg	= format("%s object '%s' " \
                                 + 'already in inventory',
                                 args[0].class.name,
                                 (args[0].name || args[0].eid).to_s)
            when 2
              @msg	= format("%s object '%s' " \
                                 + 'already in inventory, ' \
                                 + 'cannot add %s with same eid',
                                 args[0].class.name,
                                 (args[0].name || args[0].eid).to_s,
                                 args[1].class.name)
            else
              @msg	= format('unforeseen arguments ' \
                                 + 'to exception: %s',
                                 args.inspect)
            end                 # case(args.count)
          end
        end
        self._set_message(@msg)
      end                       # def initialize

      nil
    end                         # class AlreadyInInventory

    #
    class ImmovableElementDestinationError < ErrorBase

      #
      # Assign this exception class a unique ID number
      #
      self.assign_ID

      self.severity	= :error

      #
      # @!macro doc.TAGF.formal.kwargs
      # @return [ImmovableElementDestinationError] self
      #
      def initialize(*args, **kwargs)
        _dbg_exception_start(__callee__)
        super
        if (@msg.nil?)
          target	= args[0]
          newcontent	= args[1]
          if (newcontent.kind_of?(Class))
            newobject	= format('<%s>', newcontent.class.name)
          else
            newobject	= format('<%s>[%s]',
                                 newcontent.class.name,
                                 newcontent.eid.to_s)
          end
          @msg		= format('element %s is static and cannot be ' \
                                 + 'stored in inventory of %s',
                                 target,
                                 newcontent)
        end
        self._set_message(@msg)
      end                       # def initialize

      nil
    end                         # class ImmovableElementDestinationError

    #
    class DuplicateObject < ErrorBase

      #
      # Assign this exception class a unique ID number
      #
      self.assign_ID

      self.severity	= :warning

      #
      # @!macro doc.TAGF.formal.kwargs
      # @return [DuplicateObject] self
      #
      def initialize(*args, **kwargs)
        _dbg_exception_start(__callee__)
        super
        type		= self.class.name.sub(%r!^.*Duplicate!, '')
        if (@msg.nil?)
          if (args[0].respond_to?(:eid))
            @msg		= format('attempt to register ' \
                                         'new %s using existing UID %s',
                                         type,
                                         args[0].eid)
          else
            @msg		= format('attempt to register new %s ' \
                                         + 'with existing UID',
                                         type)
          end
        end
        self._set_message(@msg)
      end                       # def initialize

      nil
    end                         # class DuplicateObject

    #
    class DuplicateItem < DuplicateObject

      #
      # Assign this exception class a unique ID number
      #
      self.assign_ID

      self.severity	= :warning

    end                         # class DuplicateItem

    #
    class DuplicateLocation < DuplicateObject

      #
      # Assign this exception class a unique ID number
      #
      self.assign_ID

      self.severity	= :warning

    end                         # class DuplicateLocation

    class UnterminatedHeredoc < ErrorBase

      #
      # Assign this exception class a unique ID number
      #
      self.assign_ID

      self.severity	= :error

      #
      # @!macro doc.TAGF.formal.kwargs
      # @return [UnterminatedHeredoc] self
      #
      def initialize(*args, **kwargs)
        _dbg_exception_start(__callee__)
        super
        if (@msg.nil?)
          @msg			= 'EOF encountered while ' \
                                  + 'reading here-doc'
          if (args[0].kind_of?(UI::HereDoc))
            @msg		= format("%s\n\t%s",
                                         @msg,
                                         args[0].intro_line)
          end
        end
        self._set_message(@msg)
      end                       # def initialize

      nil
    end                         # class UnterminatedHeredoc

    class UnsupportedObject < ErrorBase

      #
      # Assign this exception class a unique ID number
      #
      self.assign_ID

      self.severity	= :fatal

      #
      # @!macro doc.TAGF.formal.kwargs
      # @return [UnsupportedObject] self
      #
      def initialize(*args, **kwargs)
        _dbg_exception_start(__callee__)
        super
        if (@msg.nil?)
          @msg			= 'object unsupported ' \
                                  + 'for this operation'
          if (kwargs.has_key?(:object))
            obj			= kwargs[:object]
            @msg		= format('%s: %s:%s',
                                         @msg,
                                         obj.class.name,
                                         obj.inspect)
          end
        end
        self._set_message(@msg)
      end                       # def initialize

      nil
    end                         # class UnsupportedObject

    # Exception raised when an object needs to be invoked like a
    # `proc`, but doesn't respond to `:call`.
    class UncallableObject < ErrorBase

      #
      # Assign this exception class a unique ID number
      #
      self.assign_ID

      self.severity	= :severe

      # Constructor for the `UncallableObject` exception, which is
      # raised when an object should be invocable but doesn't respond
      # to the `:call` method.
      # @note
      #   It is <strong>STRONGLY RECOMMENDED</strong> that exception
      #   instances of this class be created solely using keyword
      #   arguments, and never using the order-dependent `args` array.
      #   If the offending object is a String, it will be treated as
      #   the custom text of the exception message, rather than the
      #   object which needs to be callable, if it is passed through
      #   `args`.  Pass it as the value of the `:object` keyword
      #   argument instead.
      # @!macro doc.TAGF.formal.kwargs
      # @!macro exsuperinitialize
      # @param [Array]		args
      #   `args[0]` is used as the offending object if the `:object`
      #   keyword argument is omitted.
      # @option kwargs [Any]	:object
      #   The object that needs to be callable, but isn't.  `args[0]`
      #   will be used if this keyword argument is omitted.
      # @option kwargs [String]	:prefix
      #   An optional string to prefix to the exception message, such
      #   as `"invalid render_proc"`.  If specified, it will be
      #   separated from the rest of the exception message by a colon
      #   and a space (`": "`).
      # @return [UncallableObject] self
      #
      def initialize(*args, **kwargs)
        _dbg_exception_start(__callee__)
        super
        if (@msg.nil?)
          offender	= kwargs[:object] || args[0] || 'unspecified'
          if (prefix = kwargs[:prefix])
            prefix	<< ': '
          else
            prefix	= ''
          end
          @msg		= format('%s%s:%s is not a callable object',
                                 prefix,
                                 offender.class.name,
                                 offender.inspect)
        end
        self._set_message(@msg)
      end                       # def initialize

      nil
    end                         # class UncallableObject

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
