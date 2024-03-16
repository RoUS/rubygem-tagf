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
    SEVERITY            = OpenStruct.new(
      #
      # Not an error; used to report something that has functioned
      # exactly as designed.
      #
      success:          1,
      #
      # Not necessarily a problem; things didn't go <em>exactly</em>
      # as intended, but result/behaviour should be correct.
      #
      info:             3,
      warning:          4,
      error:            6,
      #
      # Catastropic failure of some sort; generally results in
      # application termination.
      #
      severe:           8
    )
    #
    # Alternate spellings for some of the severities.
    #
    SEVERITY.warn       = SEVERITY.warning
    SEVERITY.informational = SEVERITY.info
    SEVERITY.fatal      = SEVERITY.severe
    SEVERITY.freeze

    #
    # List of all integer severity values, used for validation.
    #
    SEVERITY_LEVELS     = SEVERITY.to_h.values.sort.freeze

    #
    # List of all severity level names, as strings, used for
    # validation.
    #
    SEVERITY_NAMES      = SEVERITY.to_h.keys
                            .map { |l| l.to_s }
                            .sort
                            .map { |s| s.to_sym }
                            .freeze

    #
    # Single-character identifiers for the various severity levels;
    # used when constructing messages (such as for logging).
    #
    SEVERITY_CHAR       = [
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
    # Array of all acceptable severity values, integers and
    # symbols.
    #
    VALID_SEVERITIES	= (SEVERITY_NAMES + SEVERITY_LEVELS)

    #
    # Hash mapping exceptions in the TAGF::Exceptions module to unique
    # integer identifiers.  The exception names (keys in the hash) are
    # represented as symbols, and the values are determined and stored
    # as part of exception class declaration.
    #
    # @see ErrorBase.assign_ID
    #
    EXCEPTION_IDS	= {}

    # Base class for this package's custom exceptions.  It enhances
    # `StandardError` by adding a bunch of functionality, and all of
    # our exceptions subclass it.
    #
    # @todo
    #   Need to add:
    #   * GameAlreadyLoaded (see game.rb)
    #   * InvalidAttitude (see faction.rb)
    #   * LimitMass (see inventory.rb)
    #   * LimitVolume (see inventory.rb)
    #   * NameRequired (see faction.rb)
    class ErrorBase < StandardError

      #
      include(TAGF::Mixin::DTypes)
      include(TAGF::Mixin::UniversalMethods)

      # ErrorBase eigenclass, declaring class methods for ErrorBase
      # and all classes that subclass it.
      class << self

        # @!attribute [r] exception_id
        # Each TAGF exception class has a unique integer value
        # assigned to it by the {ErrorBase#assign_ID} method.
        #
        # @see #errorcode
        #
        # @return [Integer]
        #   Unique integer identifier specific to the class.
        attr_reader(:exception_id)

        # Assign a unique integer ID for the receiving class, and
        # store it in the {Exceptions::EXCEPTION_IDS} hash.  Multiple
        # invocations within the same class will always return the
        # same value.
        #
        # @see EXCEPTION_IDS
        # @see #exception_id
        # @see #errorcode
        #
        # @param [Integer]	idnum		(nil)
        #   Unique identifying integer value to be assigned to this
        #   exception class.  If omitted, a value is generated by
        #   adding 1 to the highest ID assigned at the time this class
        #   is declared.
        # @raise [TypeError]
        #   "exception IDs must be positive integers:
        #   <em><u>class</u></em>:<em><u>value</u></em>"
        # @raise [IndexError]
        #   "exception ID <em><u>num</u></em> already assigned to
        #   <em><u>exception</u></em>"
        # @raise [ArumentError]
        #   "exception <em><u>name</u></em> has already been assigned
        #   ID <em><u>integer</u></em>"
        # @return [Integer]
        #   integer identifier unique to this class.
        def assign_ID(idnum=nil)
          exc_by_name	= Exceptions::EXCEPTION_IDS
          exc_by_id	= exc_by_name.inject({}) { |memo,(exc,id)|
            memo[id]	= exc
            memo
          }
          next_id	= exc_by_name.values.max || 1
          our_name	= self.klassname
          our_id	= exc_by_name[our_name]
          #
          # At the end of this catch block, `our_id` has the ID number
          # assigned to this exception class.
          #
          catch(:assigned) do
            #
            # Background info gathered; find out if we're a new
            # exception, an existing one being assigned our own ID, or
            # a an existing one being assigned an already-assigned ID.
            # The last is a failure condition.
            #
            if (idnum.nil?)
              #
              # Either return our existing ID assignment, or make a
              # new one.
              #
              if (our_id.nil?)
                our_id	= next_id
                Exceptions::EXCEPTION_IDS[our_name] = our_id
              end
              throw(:assigned)
            else
              #
              # We were given an explicit identifier.  Vet it and then
              # see if it's useable.
              #
              unless (idnum.kind_of?(Integer))
                raise_exception(TypeError,
                                format('exception IDs must ' +
                                       'be positive integers: %s:%s',
                                       idnum.class.name,
                                       idnum.inspect))
              end
              #
              # If we don't have an ID yet, this is it.
              #
              if (our_id.nil?)
                our_id	= idnum
                Exceptions::EXCEPTION_IDS[our_name] = our_id
                throw(:assigned)
              end
              #
              # See if we're being [re]assigned our own ID.
              #
              if (idnum == our_id)
                #
                # Yup.  Woo-hoo.
                #
                throw(:assigned)
              end
              #
              # Now to more problematic alternatives.  See if it's
              # already been assigned to a different exception.
              #
              if (exc_name = exc_by_id[idnum])
                #
                # Yup, complain.
                #
                raise_exception(ArgumentError,
                                format('ID %i has already been ' +
                                       'assigned to exception %s',
                                       idnum,
                                       exc_name))
              end
            end
          end
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
        #   @raise [TypeError]
        #   @raise [InvalidSeverity]
        #   @return [Integer]
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
        # @raise [TypeError]
        # @raise [InvalidSeverity]
        # @return [Integer]
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

        # @!attribute [r] errorcode
        # Each TAGF exception class has an errorcode value, which is
        # constructed from the exception class' unique integer ID and
        # the class' severity.  Severity value are 4-bit integers
        # (0..8), so the `errorcode` value is the class'
        # `#exception_id` left-shifted four bits and bitwise ORed with
        # the class' `#severity`.
        #
        # @note that this is the class-level version of the
        #   <em>per</em>-instance #errorcode attribute.
        #
        # @return [Integer]
        #   an integer identifying the exception class and the
        #   severity.
        def errorcode
          return (self.exception_id << 4) | self.severity
        end                     # def errorcode

        # @!method unpack_errorcode
        # Disassemble the value of {#errorcode} into a two-element
        # structure containing its parts.
        #
        # @return [OpenStruct]
        #   a structure with attributes
        #     * `.exception_id:` the value of the class' #exception_id
        #     * `.severity:`     the class' (current) severity
        def unpack_errorcode
          result	= OpenStruct.new(
            exception_id: self.exception_id,
            severity:	self.severity
          )
          return result.freeze
        end                     # def unpack_errorcode

        nil
      end                       # ErrorBase eigenclass

      #
      #
      include(TAGF::Mixin::UniversalMethods)

      # @!attribute [r] failure?
      # An exception instance is considered to represent a failure
      # status if
      # 1. Its integer value is even, <strong>OR</strong>
      # 1. Its integer value isn't one of the defined severity levels.
      #
      # @return [Boolean]
      #   `true` if either the receiver's `#severity` value is even,
      #   or isn't a defined severity level.
      def failure?
        sev		= self.severity
        return ((! SEVERITY_LEVELS.include?(sev)) \
                || sev.even?)
      end		        # def failure?

      # @!attribute [r] is_success?
      # Tests the receiver's {#severity} value against
      # `SEVERITY.success`.
      # @return [Boolean]
      #   `true` if the exception's severity level is equal to
      #   `SEVERITY.success`.
      def is_success?
        result		= self.severity == SEVERITY.success
        return result
      end                       # def is_success?

      # @!attribute [r] is_warning?
      # Tests the receiver's {#severity} value against
      # `SEVERITY.warning`.
      # @return [Boolean]
      #   `true` if the exception's severity level is equal to
      #   `SEVERITY.warning`.
      def is_warning?
        result		= self.severity == SEVERITY.warning
        return result
      end                       # def is_warning?

      # @!attribute [r] is_info?
      # Tests the receiver's {#severity} value against
      # `SEVERITY.info`.
      # @return [Boolean]
      #   `true` if the exception's severity level is equal to
      #   `SEVERITY.info`.
      def is_info?
        result		= self.severity == SEVERITY.info
        return result
      end                       # def is_info?
      alias_method(:is_informational?, :is_info?)

      # @!attribute [r] is_error?
      # Tests the receiver's {#severity} value against
      # `SEVERITY.error`.
      # @return [Boolean]
      #   `true` if the exception's severity level is equal to
      #   `SEVERITY.error`.
      def is_error?
        result		= self.severity == SEVERITY.error
        return result
      end                       # def is_error?

      # @!attribute [r] is_severe?
      # Tests the receiver's {#severity} value against
      # `SEVERITY.severe`.
      # @return [Boolean]
      #   `true` if the exception's severity level is equal to
      #   `SEVERITY.severe`.
      def is_severe?
        result		= self.severity == SEVERITY.severe
        return result
      end                       # def is_severe?
      alias_method(:is_fatal?, :is_severe?)

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

      # @!attribute [r] errorcode
      # Each TAGF exception has an errorcode value, which is
      # constructed from the exception class' unique integer ID and
      # the exception instance's severity.  Severity value are 4-bit
      # integers (0..8), so the `errorcode` value is the class'
      # `#exception_id` left-shifted four bits and bitwise ORed with
      # the instance's `#severity`.
      # @return [Integer]
      #   an integer identifying the exception class and the severity.
      def errorcode
        return (self.class.exception_id << 4) | self.severity
      end                       # def errorcode

      # @!method unpack_errorcode
      # Disassemble the value of {#errorcode} into a two-element
      # structure containing its parts.
      #
      # @return [OpenStruct]
      #   a structure with attributes
      #     * `.exception_id:` the value of the class' #exception_id
      #     * `.severity:`     the instance's (current) severity
      def unpack_errorcode
        result	= OpenStruct.new(
          exception_id: self.class.exception_id,
          severity:	self.severity
        )
        return result.freeze
      end                     # def unpack_errorcode

      # @private
      # @!method set_message(text)
      # Internal method to allow our classes to set their message text
      # at runtime, since the `Exception` superclass doesn't.
      # @return [void]
      def set_message(text)
        self.define_singleton_method(:message) {
          return %Q[#{text}]
        }
        return nil
      end                       # def set_message(text)
      protected(:set_message)

      # @private
      # @!method _dbg_exception_start(msym)
      # Portected internal method for logging & debugging exception
      # processing.
      # @return [void]
      def _dbg_exception_start(msym)
#        TAGF::Mixin::Debugging.invocation
        return nil
      end                       # def _dbg_exception_start(msym)
      protected(:_dbg_exception_start)

      # @!method render
      # Format the exception information into a standard
      # human-readable string:
      #
      # <em>X-Y [Z], text</em>
      #
      # where <strong>X</strong> is a single character representing
      # the severity level (see {SEVERITY_CHAR}), <strong>Y</strong>
      # is the name of the exception (such as `"AliasRedefinition"`),
      # <strong>Z</strong> is the exception's #errorcode value in
      # hexadecimal, and <strong>text</strong> is the exception's
      # message text.
      #
      # @return [String]
      #   the formatted exception information.
      def render
        result		= format('%s-%s [%08x], %s',
                                 SEVERITY_CHAR[self.severity] || '?',
                                 self.klassname,
                                 self.errorcode,
                                 self.message)
        return result
      end                       # def render

      # @!method inspect
      # Returns a string representaion of the exception in standar
      # format.
      # @return [String]
      #   "<em>exception-class</em>: <em>exception-message</em>"
      def inspect
        return format('%s: %s',
                      self.class.name,
                      self.message)
      end                       # def inspect

      # @!macro doc.TAGF.formal.kwargs
      # @!macro [new] ErrorBase.initialize
      #   @param [Array]		   args		([])
      #   @option kwargs [String]          :message	(nil)
      #     Optional explicit string for the exception message text.
      #     This also overrides any string value of `args[0]`.
      #   @option kwargs [Symbol,Integer]  :severity	(nil)
      #     Explicit severity for constructed instance of the
      #     exception.  If omitted, the default is taken from the
      #     severity set for the class itself, or `:severe`.  See
      #     {SEVERITY}, {ErrorBase.assign_ID}, and {#severity}.
      def initialize(*args, **kwargs)
        @msg		= nil
        #
        # If the first order-dependent argument (if any) is a string,
        # use it for to override the default message text.  This in
        # turn can be overridden by an explicit `:message` keyword
        # argument.
        #
        if ((args.count > 0) && args[0].kind_of?(String))
          @msg		= args[0]
        end
        if ((kwmsg = kwargs[:message]) \
            && kwmsg.kind_of?(String))
          @msg		= kwmsg
        end
        #
        # Set the instance severity according to the arguments, the
        # class default severity, or a final resort of 'severe.'
        #
        self.severity	= kwargs[:severity] \
                          || self.class.severity \
                          || SEVERITY.severe
      end                       # def initialize(*args, **kwargs)

      nil
    end                         # class ErrorBase

    # @!macro doc.TAGF.Exceptions.InventoryLimitExceeded.module
    module InventoryLimitExceeded

      #
      include(Mixin::DTypes)

      #
      include(Mixin::UniversalMethods)

      #
      class LimitItems < ::TAGF::Exceptions::ErrorBase

        #
        # Assign this exception class a unique ID number
        #
        self.assign_ID(0x101)

        self.severity	= :warning

        #
        # @todo add LimitVolume and LimitMass exceptions
        # @!macro doc.TAGF.formal.kwargs
        # @!macro ErrorBase.initialize
        # @raise [UnsupportedObject]
        #   if args[0] doesn't respond to `:owned_by`
        # @return [InventoryLimitExceeded::LimitItems] self
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
            @msg	= format('inventory for %s:"%s" is full; ' \
                                 + '%i/%i %s, cannot add "%s"',
                                 owner_klass,
                                 (owner_name || owner_eid).to_s,
                                 owner.items_current,
                                 owner.capacity_items,
                                 pluralise('item',
                                           owner.capacity_items),
                                 (newitem.name || newitem.eid).to_s)
          end
          self.set_message(@msg)
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
      self.assign_ID(0x001)

      self.severity	= :warning

      # Constructor for InvalidSeverity exception.
      # @!macro doc.TAGF.formal.kwargs
      # @!macro ErrorBase.initialize
      # @param [Array]			args		([])
      #   If the first element of `args` is an Integer or a Symbol, it
      #   is used to calculate the exception object's message text.
      #   If it's a String, it is used <em>verbatim</em> as the
      #   exception text.
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
        self.set_message(@msg)
      end                       # def initialize

      nil
    end                         # class InvalidSeverity

    #
    class BadHistoryFile < ErrorBase

      #
      # Assign this exception class a unique ID number
      #
      self.assign_ID(0x002)

      self.severity	= :warning

      #
      # @!macro doc.TAGF.formal.kwargs
      # @!macro ErrorBase.initialize
      # @return [NoLoadFile] self
      #
      def initialize(*args, **kwargs)
        _dbg_exception_start(__callee__)
        super
        if (@msg.nil?)
          if ((! kwargs.has_key?(:file)) \
              && (! kwargs.has_key?(:exception)))
            @msg	= 'cannot open/read command history file'
          else
            @msg	= format("cannot restore history from %s\n" \
                                 + "\t%s",
                                 kwargs[:file] || '<not specified>',
                                 kwargs[:exception] || 'unknown reason')
          end
        end
        self.set_message(@msg)
      end                       # def initialize

      nil
    end                         # class BadHistoryFile

    #
    class NoLoadFile < ErrorBase

      #
      # Assign this exception class a unique ID number
      #
      self.assign_ID(0x002)

      self.severity	= :error

      #
      # @!macro doc.TAGF.formal.kwargs
      # @!macro ErrorBase.initialize
      # @return [NoLoadFile] self
      #
      def initialize(*args, **kwargs)
        _dbg_exception_start(__callee__)
        super
        if (@msg.nil?)
          @msg		= 'no "file" keyword specified for game load'
        end
        self.set_message(@msg)
      end                       # def initialize

      nil
    end                         # class NoLoadFile

    #
    class BadLoadFile < ErrorBase

      #
      # Assign this exception class a unique ID number.
      #
      self.assign_ID(0x003)

      self.severity	= :severe

      #
      # @!macro doc.TAGF.formal.kwargs
      # @!macro ErrorBase.initialize
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
        self.set_message(@msg)
      end                       # def initialize

      nil
    end                         # class BadLoadFile

    #
    class NotExceptional < ErrorBase

      #
      # Assign this exception class a unique ID number
      #
      self.assign_ID(0x014)

      self.severity	= :error

      #
      # @!macro doc.TAGF.formal.kwargs
      # @!macro ErrorBase.initialize
      # @option kwargs [Any]		:offender
      #   offending object; use this for strings
      # @return [NotExceptional]	self
      #
      def initialize(*args, **kwargs)
        _dbg_exception_start(__callee__)
        super
        if (@msg.nil?)
          offender	= kwargs[:offender] || args[0]
          @msg		= format('not an exception or ' +
                                 'exception class: %s:%s',
                                 offender.class.name \
                                 || offender.class.to_s,
                                 offender.inspect)
        end
        self.set_message(@msg)
      end                       # def initialize

      nil
    end                         # class NotExceptional

    #
    class NotGameElement < ErrorBase

      #
      # Assign this exception class a unique ID number
      #
      self.assign_ID(0x005)

      self.severity	= :severe

      #
      # @!macro doc.TAGF.formal.kwargs
      # @!macro ErrorBase.initialize
      # @return [NotGameElement] self
      #
      def initialize(*args, **kwargs)
        _dbg_exception_start(__callee__)
        super
        if (@msg.nil?)
          obj		= kwargs[:object] || args[0]
          objtype	= obj.class.name || obj.class.to_s
          @msg		= format('not a game object: %s:%s',
                                 objtype,
                                 obj.inspect)
        end
        self.set_message(@msg)
      end                       # def initialize

      nil
    end                         # class NotGameElement

    #
    class NoObjectOwner < ErrorBase

      #
      # Assign this exception class a unique ID number
      #
      self.assign_ID(0x006)

      self.severity	= :severe

      #
      # @!macro doc.TAGF.formal.kwargs
      # @!macro ErrorBase.initialize
      # @return [NoObjectOwner] self
      #
      def initialize(*args, **kwargs)
        _dbg_exception_start(__callee__)
        super
        if (@msg.nil?)
          objtype	= args[0].class.name
          @msg		= format('no owner specified ' \
                                 + 'on creation of: %s:%s',
                                 objtype,
                                 args[0].to_s)
        end
        self.set_message(@msg)
      end                       # def initialize

      nil
    end                         # class NoObjectOwner

    #
    class KeyObjectMismatch < ErrorBase

      #
      # Assign this exception class a unique ID number
      #
      self.assign_ID(0x007)

      self.severity	= :severe

      #
      # @!macro doc.TAGF.formal.kwargs
      # @!macro ErrorBase.initialize
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
        self.set_message(@msg)
      end                       # def initialize

      nil
    end                         # class KeyObjectMismatch

    #
    class NoGameContext < ErrorBase

      #
      # Assign this exception class a unique ID number
      #
      self.assign_ID(0x008)

      self.severity	= :severe

      #
      # @!macro doc.TAGF.formal.kwargs
      # @!macro ErrorBase.initialize
      # @return [NoGameContext] self
      #
      def initialize(*args, **kwargs)
        _dbg_exception_start(__callee__)
        super
        if (@msg.nil?)
          @msg		= 'attempt to create in-game object ' \
                          + 'failed (#game not set)'
        end
        self.set_message(@msg)
      end                       # def initialize

      nil
    end                         # class NoGameContext

    #
    class SettingLocked < ErrorBase

      #
      # Assign this exception class a unique ID number
      #
      self.assign_ID(0x009)

      self.severity	= :warning

      #
      # @!macro doc.TAGF.formal.kwargs
      # @!macro ErrorBase.initialize
      # @return [SettingLocked] self
      #
      def initialize(*args, **kwargs)
        _dbg_exception_start(__callee__)
        super
        if (@msg.nil?)
          if (args[0].kind_of?(Symbol))
            @msg		= format("attribute '%s' is already set " \
                                         + 'and cannot be changed',
                                         args[0].to_s)
          else
            @msg		= 'specific attribute cannot be changed ' \
                                  + 'once set'
          end
        end
        self.set_message(@msg)
      end                       # def initialize

      nil
    end                         # class SettingLocked

    #
    class ImmovableObject < ErrorBase

      #
      # Assign this exception class a unique ID number
      #
      self.assign_ID(0x00a)

      self.severity	= :error

      #
      # @!macro doc.TAGF.formal.kwargs
      # @!macro ErrorBase.initialize
      # @return [ImmovableObject] self
      #
      def initialize(*args, **kwargs)
        _dbg_exception_start(__callee__)
        super
        if (@msg.nil?)
          obj		= args[0]
          objtype	= self.klassname(obj)
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
        self.set_message(@msg)
      end                       # def initialize

      nil
    end                         # class ImmovableObject

    #
    class NotAContainer < ErrorBase

      #
      # Assign this exception class a unique ID number
      #
      self.assign_ID(0x00b)

      self.severity	= :error

      #
      # @!macro doc.TAGF.formal.kwargs
      # @!macro ErrorBase.initialize
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
        self.set_message(@msg)
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
      self.assign_ID(0x00c)

      self.severity	= :warning

      #
      # @!macro doc.TAGF.formal.kwargs
      # @!macro ErrorBase.initialize
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
        self.set_message(@msg)
      end                       # def initialize

      nil
    end                         # class AliasRedefined

    #
    class UnscrewingInscrutable < ErrorBase

      #
      # Assign this exception class a unique ID number
      #
      self.assign_ID(0x00d)

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
      # @!macro ErrorBase.initialize
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
        self.set_message(@msg)
      end                       # def initialize

      nil
    end                         # class UnscrewingInscrutable

    #
    class MasterInventory < ErrorBase

      #
      # Assign this exception class a unique ID number
      #
      self.assign_ID(0x00e)

      self.severity	= :error

      #
      # @!macro doc.TAGF.formal.kwargs
      # @!macro ErrorBase.initialize
      # @return [MasterInventory] self
      #
      def initialize(*args, **kwargs)
        _dbg_exception_start(__callee__)
        super
        if (@msg.nil?)
          obj		= args[0]
          objtype	= self.klassname(obj)
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
        self.set_message(@msg)
      end                       # def initialize

      nil
    end                         # class MasterInventory

    #
    class HasNoInventory < ErrorBase

      #
      # Assign this exception class a unique ID number
      #
      self.assign_ID(0x00f)

      self.severity	= :error

      #
      # @!macro doc.TAGF.formal.kwargs
      # @!macro ErrorBase.initialize
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
        self.set_message(@msg)
      end                       # def initialize

      nil
    end                         # class HasNoInventory

    #
    class AlreadyHasInventory < ErrorBase

      #
      # Assign this exception class a unique ID number
      #
      self.assign_ID(0x010)

      self.severity	= :warning

      #
      # @!macro doc.TAGF.formal.kwargs
      # @!macro ErrorBase.initialize
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
        self.set_message(@msg)
      end                       # def initialize

      nil
    end                         # class AlreadyHasInventory

    #
    class AlreadyInInventory < ErrorBase

      #
      # Assign this exception class a unique ID number
      #
      self.assign_ID(0x011)

      self.severity	= :warning

      #
      # @!macro doc.TAGF.formal.kwargs
      # @!macro ErrorBase.initialize
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
                                 + 'already in inventory of %s, ' \
                                 + 'cannot add %s with same eid',
                                 args[0].klassname,
                                 (args[0].name || args[0].eid).to_s,
                                 args[0].to_key,
                                 args[1].klassname)
            else
              @msg	= format('unforeseen arguments ' \
                                 + 'to exception: %s',
                                 args.inspect)
            end                 # case(args.count)
          end
        end
        self.set_message(@msg)
      end                       # def initialize

      nil
    end                         # class AlreadyInInventory

    #
    class ImmovableElementDestinationError < ErrorBase

      #
      # Assign this exception class a unique ID number
      #
      self.assign_ID(0x012)

      self.severity	= :error

      #
      # @!macro doc.TAGF.formal.kwargs
      # @!macro ErrorBase.initialize
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
        self.set_message(@msg)
      end                       # def initialize

      nil
    end                         # class ImmovableElementDestinationError

    #
    class DuplicateObject < ErrorBase

      #
      # Assign this exception class a unique ID number
      #
      self.assign_ID(0x013)

      self.severity	= :warning

      #
      # @!macro doc.TAGF.formal.kwargs
      # @!macro ErrorBase.initialize
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
        self.set_message(@msg)
      end                       # def initialize

      nil
    end                         # class DuplicateObject

    #
    class DuplicateItem < DuplicateObject

      #
      # Assign this exception class a unique ID number
      #
      self.assign_ID(0x014)

      self.severity	= :warning

    end                         # class DuplicateItem

    #
    class DuplicateLocation < DuplicateObject

      #
      # Assign this exception class a unique ID number
      #
      self.assign_ID(0x015)

      self.severity	= :warning

    end                         # class DuplicateLocation

    class UnterminatedHeredoc < ErrorBase

      #
      # Assign this exception class a unique ID number
      #
      self.assign_ID(0x016)

      self.severity	= :error

      #
      # @!macro doc.TAGF.formal.kwargs
      # @!macro ErrorBase.initialize
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
        self.set_message(@msg)
      end                       # def initialize

      nil
    end                         # class UnterminatedHeredoc

    class UnsupportedObject < ErrorBase

      #
      # Assign this exception class a unique ID number
      #
      self.assign_ID(0x017)

      self.severity	= :fatal

      #
      # @!macro doc.TAGF.formal.kwargs
      # @!macro ErrorBase.initialize
      # @return [UnsupportedObject] self
      #
      def initialize(*args, **kwargs)
        _dbg_exception_start(__callee__)
        super
        if (@msg.nil?)
          @msg			= 'object unsupported ' \
                                  + 'for this operation'
          if (kwargs.has_key?(:operation))
            @msg		= format('%s (%s)',
                                         @msg,
                                         kwargs[:operation].to_sym)
          end
          if (kwargs.has_key?(:object))
            obj			= kwargs[:object]
            @msg		= format('%s: %s:%s',
                                         @msg,
                                         obj.class.name,
                                         obj.inspect)
          end
        end
        self.set_message(@msg)
      end                       # def initialize

      nil
    end                         # class UnsupportedObject

    # Exception raised when an object needs to be invoked like a
    # `proc`, but doesn't respond to `:call`.
    class UncallableObject < ErrorBase

      #
      # Assign this exception class a unique ID number
      #
      self.assign_ID(0x018)

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
      # @!macro ErrorBase.initialize
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
        self.set_message(@msg)
      end                       # def initialize

      nil
    end                         # class UncallableObject

    #
    class NoElementID < ErrorBase

      #
      # Assign this exception class a unique ID number
      #
      self.assign_ID(0x019)

      self.severity	= :severe

      #
      # @!macro doc.TAGF.formal.kwargs
      # @!macro ErrorBase.initialize
      # @return [NoElementID] self
      #
      def initialize(*args, **kwargs)
        _dbg_exception_start(__callee__)
        super
        if (@msg.nil?)
          @msg		= 'missing required :eid keyword argument ' \
                          + 'for element creation'
        end
        self.set_message(@msg)
      end                       # def initialize

      nil
    end                         # class NoElementID

    #
    class DataError < ErrorBase

      #
      # Assign this exception class a unique ID number
      #
      self.assign_ID(0x01a)

      self.severity	= :severe

      #
      # @!macro doc.TAGF.formal.kwargs
      # @!macro ErrorBase.initialize
      # @option kwargs [String]	:source
      #   filesystem path of the file which had the problem
      # @option kwargs [String] :error
      #   the message from the parsing exception that was raised
      # @return [DataError] self
      #
      def initialize(*args, **kwargs)
        _dbg_exception_start(__callee__)
        super
        if (@msg.nil?)
          @msg		= 'error processing input data'
          if (source = kwargs[:source])
            @msg	+= format("\n  file:      %s", source)
          end
          if (error = kwargs[:error])
            @msg	+= format("\n  exception: %s", error)
          end
        end
        self.set_message(@msg)
      end                       # def initialize

      nil
    end                         # class DataError

    #
    class MemberNotFound < ErrorBase

      #
      # Assign this exception class a unique ID number
      #
      self.assign_ID(0x01b)

      self.severity	= :severe

      #
      # @!macro doc.TAGF.formal.kwargs
      # @!macro ErrorBase.initialize
      # @option kwargs [TAGF::Mixin::Element]	:element
      #   Object being re-instantiated by the `YAML` loader tools.
      # @option kwargs [String]			:member
      #   The EID (or other string) identifying the
      # @option kwargs [Symbol]			:field
      #   The attribute of the `:element` argument that is being
      #   restored, such as `:paths` for a Connexion, or `:owned_by`
      #   for an Item.
      # @return [MemberNotFound] self
      #
      def initialize(*args, **kwargs)
        _dbg_exception_start(__callee__)
        super
        if (@msg.nil?)
          if (element = kwargs[:element])
            @msg	= format('error restoring element "%s"; ' \
                                 + 'component object not found',
                                 element.to_key)
            if (raiser = kwargs[:raiser])
              @msg	= format('%s: %s', raiser.to_s, @msg)
            end
            if (member_eid = kwargs[:member])
              @msg	= format("%s\n\tEID of missing object = '%s'",
                                 @msg,
                                 member_eid)
            end
            if (fattr = kwargs[:field])
              @msg	= format("%s\n\treferencing field    = %s",
                                 @msg,
                                 fattr.inspect)
            end
          else
            @msg	= 'error restoring element; ' \
                          + 'component object not found'
          end
        end                     # if (@msg.nil?)
        self.set_message(@msg)
      end                       # def initialize

      nil
    end                         # class MemberNotFound

    #
    class UnknownAttribute < ErrorBase

      #
      # Assign this exception class a unique ID number
      #
      self.assign_ID(0x01c)

      self.severity	= :severe

      #
      # @!macro doc.TAGF.formal.kwargs
      # @!macro ErrorBase.initialize
      # @option kwargs [Symbol]			:field
      #   The attribute that <em>should</em> be part of the target
      #   object, but apparently isn't.
      # @option kwargs [TAGF::Mixin::Element]	:element
      #   The game element object that should have the specified
      #   attribute.
      # @return [UnknownAttribute] self
      #
      def initialize(*args, **kwargs)
        _dbg_exception_start(__callee__)
        super
        if (@msg.nil?)
          if (fattr = kwargs[:field])
            @msg	= format('unknown attribute "%s"',
                                 fattr.to_sym.inspect)
            if (element = kwargs[:element])
              @msg	= format('%s for object %s:%s',
                                 @msg,
                                 element.klassname,
                                 element.to_key)
            end
          else
            @msg	= 'unknown attribute for object'
          end
        end                     # if (@msg.nil?)
        self.set_message(@msg)
      end                       # def initialize

      nil
    end                         # class UnknownAttribute

    # Report that two different Path objects use one (or more) of the
    # same Path#via motion keywords, raising an irreconcilable
    # conflict.
    class ConflictingPath < ErrorBase

      #
      # Assign this exception class a unique ID number
      #
      self.assign_ID(0x01d)

      self.severity	= :severe

      #
      # @!macro doc.TAGF.formal.kwargs
      # @!macro ErrorBase.initialize
      # @option kwargs [Symbol]			:newpath
      #   The Path object which would add a conflicting entry.
      # @option kwargs [TAGF::Mixin::Element]	:paths
      #   Existing linked paths with which the new one would conflict.
      # @return [ConflictingPath] self
      #
      def initialize(*args, **kwargs)
        _dbg_exception_start(__callee__)
        super
        if (@msg.nil?)
          if ((newpath = kwargs[:newpath]) \
              && (estpaths = kwargs[:paths]))
            @msg	= format('new path %s conflicts with ' \
                                 + 'existing path(s): %s',
                                 newpath.to_key,
                                 estpaths.map { |p|
                                   p.to_key
                                 }.join(', '))
          else
            @msg	= 'new path conflicts with ' \
                          + 'existing path(s)'
          end
        end                     # if (@msg.nil?)
        self.set_message(@msg)
      end                       # def initialize

      nil
    end                         # class ConflictingPath

    # Report that an element hasn't been supplied with a required
    # #name value.
    class NameRequired < ErrorBase

      #
      # Assign this exception class a unique ID number
      #
      self.assign_ID(0x01e)

      self.severity	= :severe

      #
      # @!macro doc.TAGF.formal.kwargs
      # @!macro ErrorBase.initialize
      # @option kwargs [Symbol]			:element
      #   The game element object which needs a name but wasn't given
      #   one.
      # @return [NameRequired] self
      #
      def initialize(*args, **kwargs)
        _dbg_exception_start(__callee__)
        super
        if (@msg.nil?)
          if (element = kwargs[:element])
            @msg	= format('game element %s requires a name, ' +
                                 'none supplied',
                                 element.to_key)
          else
            @msg	= ('game element requires a name, ' +
                           'none supplied')
          end
        end                     # if (@msg.nil?)
        self.set_message(@msg)
      end                       # def initialize

      nil
    end                         # class NameRequired

    # Exceptions for issues with the structure of the game, such as
    # locations which are inaccessible, or which cannot be exited once
    # entered.
    module MapError

      #
      include(Mixin::DTypes)

      #
      include(Mixin::UniversalMethods)

      # Report that a specific Location is completely inaccessible.
      class NoAccess < ErrorBase

        #
        # Assign this exception class a unique ID number
        #
        self.assign_ID(0x01f)

        self.severity	= :severe

        #
        # @!macro doc.TAGF.formal.kwargs
        # @!macro ErrorBase.initialize
        # @option kwargs [Symbol]	:location
        #   The game location object which has limited access.
        # @return [NoAccess] self
        #
        def initialize(*args, **kwargs)
          _dbg_exception_start(__callee__)
          super
          if (@msg.nil?)
            msgformat	= ('location %<location>sis inaccessible ' +
                           '(except perhaps by use of a shortcut)')
            msgargs	= {
              location:	'',
            }
            if (loc = kwargs[:location])
              msgargs[:location] = format('"%s" ', loc.to_key)
            end
            @msg	 = format(msgformat, **msgargs)
          end                   # if (@msg.nil?)
          self.set_message(@msg)
        end                     # def initialize

        nil
      end                       # class NoExit

      # Report that a specific Location can be entered, but there's no
      # way to walk out again.
      class NoExit < ErrorBase

        #
        # Assign this exception class a unique ID number
        #
        self.assign_ID(0x020)

        self.severity	= :severe

        #
        # @!macro doc.TAGF.formal.kwargs
        # @!macro ErrorBase.initialize
        # @option kwargs [Symbol]	:location
        #   The game location object which has limited access.
        # @return [NoExit] self
        #
        def initialize(*args, **kwargs)
          _dbg_exception_start(__callee__)
          super
          if (@msg.nil?)
            msgformat	= ('location %<location>scan be entered, ' +
                           'but not left except by "go back" '+
                           '(or perhaps by use of a shortcut)')
            msgargs	= {
              location:	'',
            }
            if (loc = kwargs[:location])
              msgargs[:location] = format('"%s" ', loc.to_key)
            end
            @msg	= format(msgformat, **msgargs)
          end                   # if (@msg.nil?)
          self.set_message(@msg)
        end                     # def initialize

        nil
      end                       # class NoExit

      # An element which is lockable should have a `:seal_key`
      # identifier, which is something (like a key or a magic item)
      # that a player must have in inventory in order to unlock the
      # seal.  Seal keys are Item objects which are Portable.  Items
      # are accessible by the player by keyword.  This exception is
      # used when an element's seal_key is not actually defined as a
      # keyword.
      class NoSealKeyword < ErrorBase

        #
        # Assign this exception class a unique ID number
        #
        self.assign_ID(0x021)

        # The lack of a seal_key might be deliberate, allowing the
        # path to be sealed and unopenable.
        self.severity	= :warning

        #
        # @!macro doc.TAGF.formal.kwargs
        # @!macro ErrorBase.initialize
        # @option kwargs [Symbol]	:path
        #   The game object which requires an unregistered seal_key.
        # @option kwargs [Symbol]	:seal_key
        #   The EID of the (missing) seal_key from the Sealable
        #   object.
        # @return [NoSealKey] self
        #
        def initialize(*args, **kwargs)
          _dbg_exception_start(__callee__)
          super
          if (@msg.nil?)
            # 'sealable requires key; none registered'
            # 'sealable "%s" requires key; no keyword registered'
            # 'sealable requires key "%s"; no keyword registered'
            # 'sealable "%s" requires key "%s"; no keyword registered'
            msgformat	= ('sealable%<sealable>s requires ' +
                           'key%<seal_key>s; no keyword registered')
            msgargs	= {
              sealable:	'',
              seal_key:	'',
            }
            if (seal_EID = kwargs[:seal_key])
              msgargs[:seal_key] = format(' "%s"', seal_EID.to_s)
            end
            if (sealable = kwargs[:sealable])
              msgargs[:sealable] = format(' "%s" ("%s")',
                                          sealable.eid,
                                          sealable.shortdesc)
            end
            @msg	= format(msgformat, **msgargs)
          end                   # if (@msg.nil?)
          self.set_message(@msg)
        end                     # def initialize

        nil
      end                       # class NoSealKeyword

      # A Sealable element which is lockable should have a `:seal_key`
      # identifier, which is something (like a key or a magic item)
      # that a player must have in inventory in order to unlock the
      # seal.  Seal keys are Item objects which are Portable.  This
      # exception is used when the seal_key is not actually defined in
      # the game database as an item
      class NoSealKeyItem < ErrorBase

        #
        # Assign this exception class a unique ID number
        #
        self.assign_ID(0x022)

        # The lack of a seal_key might be deliberate, allowing the
        # path to be sealed and unopenable.
        self.severity	= :warning

        #
        # @!macro doc.TAGF.formal.kwargs
        # @!macro ErrorBase.initialize
        # @option kwargs [Symbol]	:sealable
        #   The game object which requires an unregistered seal_key.
        # @option kwargs [Symbol]	:seal_key
        #   The EID of the (missing) seal_key from the Sealable object.
        # @return [NoSealKeyItem] self
        #
        def initialize(*args, **kwargs)
          _dbg_exception_start(__callee__)
          super
          if (@msg.nil?)
            # 'sealable requires key; no item registered'
            # 'sealable "%s" requires key; no item registered'
            # 'sealable requires key "%s"; no item registered'
            # 'sealable "%s" requires key "%s"; no item registered'
            msgformat	= ('sealable%<sealable>s requires ' +
                           'key%<seal_key>s; no item registered')
            msgargs	= {
              sealable:	'',
              seal_key:	'',
            }
            if (seal_EID = kwargs[:seal_key])
              msgargs[:seal_key] = format(' "%s"', seal_EID.to_s)
            end
            if (sealable = kwargs[:sealable])
              msgargs[:sealable] = format(' "%s" ("%s")',
                                          sealable.eid,
                                          sealable.shortdesc)
            end
            @msg	= format(msgformat, **msgargs)
          end                   # if (@msg.nil?)
          self.set_message(@msg)
        end                     # def initialize

        nil
      end                       # class NoSealKeyItem

      nil
    end                         # module MapError

    #
    # Bring the Exceptions::MapError::NoAccess exception declaration
    # up to the top level (Exceptions::NoAccess).
    #
    NoAccess		= MapError::NoAccess
    #
    # Bring the Exceptions::MapError::NoExit exception declaration
    # up to the top level (Exceptions::NoExit).
    #
    NoExit		= MapError::NoExit
    #
    # Bring the Exceptions::MapError::NoSealKeyword exception
    # declaration up to the top level (Exceptions::NoSealKeyword).
    #
    NoSealKeyword	= MapError::NoSealKeyword
    #
    # Bring the Exceptions::MapError::NoSealKeyItem exception
    # declaration up to the top level (Exceptions::NoSealKeyItem).
    #
    NoSealKeyItem	= MapError::NoSealKeyItem

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
