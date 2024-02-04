#--
# Copyright © 2022 Ken Coar
#
# Licensed under the Apache License, Version 2.0 (the "License"); you
# may not use this file except in compliance with the License.	You
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

$LOAD_PATH.unshift(File.expand_path('../lib', __dir__))
require('tagf')

require('test/unit')
require('mocha/test_unit')

#
# Deduce the absolute path to the `fixtures/` directory so that none
# of the tests or test classes needs to do it.  DRY.
#
FixturesDir		= File.join(Pathname(__FILE__).dirname,
                                    'fixtures')

# Module for personal functions, customisations, and other bits that
# aren't project/package-specific.
module RoUS

  # Module defining helper methods and other assistive bits for
  # `Test::Unit` test classes and methods.
  module TestHelpers

    # Eigenclass for module RoUS::TestHelpers
    class << self

      # Invoked when `RoUS::TestHelpers` is included; add it to the
      # includer's eigenclass as well (making instance methods class
      # methods as well).
      #
      # @param [Class] klass
      #   The receiver that invoked `include(RoUS::TestHelpers)`.
      # @return [void]
      def included(klass)
        klass.extend(RoUS::TestHelpers)
        nil
      end                       # def included(klass)

      nil
    end                         # module RoUS::TestHelpers eigenclass

    # @!method setup
    # Global setup method called before each test method is invoked.
    # Individual test classes that override this should invoke `super`
    # to make sure this gets executed.
    #
    # @return [void]
    def setup
      begin
        super
      rescue NoMethodError
        #
        # There's nothing there to `super` so we're done
        #
      end

      nil
    end                         # def setup

    # @!method setup
    # Global setup method called after each test method completes.
    # Individual test classes that override this should invoke `super`
    # to make sure this gets executed.
    #
    # @return [void]
    def teardown
      begin
        super
      rescue NoMethodError
        #
        # There's nothing there to `super` so we're done
        #
      end

      nil
    end                         # def teardown

    # Coerce a String into another class.  Helper designed to allow us
    # to display a value in a canonical form rather than the one to
    # which Ruby might reduce it.  For example, `'00' ~= 00.to_s`.
    #
    # @param [Class,Method,Proc]	coercer
    #   Class to which the value should be cast, or a method/proc
    #   that will do the coercion.
    # @param [String]			val
    #   The string representation of the item to be coerced.
    # @return [Any]
    #   The value returned by the coercing method or class, or the
    #   unmodified input value if `coercer` is `nil`.
    # @raise [ArgumentError]
    #   `coerce_to requires an object of type Class, Proc, or Method`
    # @raise [ArgumentError]
    #   `only String objects are supported for coercion: `
    #   <em>`val.class`</em>`:`<em>`val.inspect`</em>
    # @raise [ArgumentError]
    #   `object `<em>`coercer-class`</em>`:`<em>`coercer.inspect`</em> `
    #   `does not support casting/coercion`
    def coerce_to(coercer, val)
      result		= val
      if (coercer)
        #
        # Coercion requires an actual class that supports
        # casting/coercion, or else a Proc or Method object.
        #
        unless (coercer.kind_of?(Class) ||
                coercer.kind_of?(Proc) ||
                coercer.kind_of?(Method))
          raise(ArgumentError,
                format('%s requires ' +
                       'an object of type Class, Proc, or Method',
                       __callee__.to_s))
        end
        unless (val.kind_of?(String))
          raise(ArgumentError,
                format('only String objects are supported ' +
                       'for coercion: %s:%s',
                       val.class.name,
                       val.inspect))
        end
        if (coercer.kind_of?(Class))
          begin
            coercer_m	= coercer.method(coercer.name.to_sym)
          rescue NameError => exc
            raise(ArgumentError,
                  format('object %s:%s does not support ' +
                         'casting/coercion',
                         coercer.class.name,
                         coercer.inspect))
          end
        else
          coercer_m	= coercer
        end
        rawval		= val.dup
        if (coercer == Complex)
          #
          # @note
          #   Meh.  The Complex converter doesn't handle parenthesised
          #   complex numbers.  WTH?
          #
          rawval.sub!(%r!^\((.*)\)$!, '\1')
        end
        result		= coercer_m.call(rawval)
      end                       # if (coercer)
      return result
    end                         # def coerce_to(coercer, val)

    #
    # Helper method to generate a dynamic test name (symbol).  Since
    # `Unit::Test` invokes test methods using `__send__`, names are
    # <em>not</em> limited to `[_[:alnum:]]*` and we don't have to
    # pussyfoot around things like floating-point or complex number
    # representations.
    #
    # @param [Hash<Symbol=>Object>] kwargs
    #   All arguments are passed by position-independent keyword.
    # @option kwargs [Object]       :testval
    #   The value under test, which will be built into the test name.
    # @option kwargs [Class]	    :coerce
    #   Sometimes the `:testval` is passed as a string representation
    #   to retain syntax, but needs to be coerced back to the original
    #   class in order to derive its class.  As an example,
    #   `(0.0-1.1i).to_s` evaluates to `"0.0-1.1i"`.  If we want the
    #   test name to include the original, we would use
    #```
    #    testval: '(0.0-1.1i)', coerce: Complex
    #```
    # @option kwargs [Boolean]      :expected     (true)
    #   The result expectation for the test being named.
    # @option kwargs [String]       :prefix       ("for")
    #   Any additional explanatory text between the prefix and the
    #   test value.
    # @option kwargs [String]       :suffix       (kwargs[:testval].inspect)
    #   Text to use as the suffix of the test name, overriding the
    #   calculation of a derived value
    #   ("<em>`testval-class`</em>`_`<em>`testval.inspect`</em>").
    # @return [Symbol]
    #   A symbol suitable for use as a `Test::Unit` test method name,
    #   built from
    #   "`test_`<em>`prefix`</em>`_`<em>`expected`</em>`_`<em>`suffix`</em>" 
    def mktestname(**kwargs)
      unless (kwargs.has_key?(:testval))
        raise(ArgumentError,
              format('%s keyword arg :testval required but omitted',
                     __callee__.to_s))
      end
      testval		= kwargs[:testval]
      coercer		= kwargs[:coerce]
      testval		= coerce_to(coercer, testval)
      suffix		||= coercer ? elt : testval.inspect
      expected		= kwargs[:expected] ? true : false
      prefix		= kwargs[:prefix] || 'for'
      if (suffix = kwargs[:suffix])
        unless (suffix[0,1] == '_')
          suffix	= format('%s_%s',
				 testval.class.name.sub(%r!^.*::!, ''),
				 suffix)
        else
          suffix	= suffix[1,suffix.length]
        end
      else
        suffix		= coercer ? elt : testval.inspect
      end
      testname		= format('test_%s_%s_%s',
				 prefix,
				 expected.to_s,
				 suffix)
      return testname.to_sym
    end                         # def mktestname(**kwargs)

    # Primitive subclassable prototype class for storing a value to be
    # used for testing, and metadata about it.  Default supported
    # attributes include:
    #
    # * `:value` — the actual value to be tested
    # * `:render` — how the test value should be rendered as a string.
    #   By default, this is built from `:value`'s class name and
    #   `#inspect` result.
    # * `:suffix` — for use in assertion messages and potentially
    #   generated test method names
    #   @see #value
    #   @see #update_rendition
    #   @see #render=
    #
    class TestElement

      extend(Forwardable)

      class << self

        # @private
        # Array of attributes that have been dynamically added
        # class-wide.
        # @return [Array<Symbol>]
        attr_accessor(:klass_attributes)

        nil
      end                       # Eigenclass for class TestElement

      #
      # Point the instance accessors for these to the class-wide ones.
      #
      def_delegator(self, :klass_attributes)
      def_delegator(self, :klass_attributes=)
      protected(:klass_attributes)
      protected(:klass_attributes=)
      
      # @private
      # @!attribute [rw] value_set
      # Control whether the #value= accessor will allow the variable
      # to be changed.  By default, once it has been set, it's flagged
      # to raise an exception if an attempt is made to change or set
      # it again.  This is controlled by #value_set, which must be
      # `false` to allow #value= to change the variable.
      # @see #value_set?
      # @see #value_set!
      # @overload value_set
      #   @return [Boolean]
      #     `true` if the test value has been set with `#value=`,
      #     `false` otherwise.
      def value_set
        unless (self.instance_variable_defined?(:@value_set))
          @value_set	= false
        end
        return @value_set ? true : false
      end                       # def value_set
      # @overload value_set=(val)
      #   @see #value_set
      #   @see #value_set?
      #   @see #value_set!
      #   @param [Any] val
      #     Any object of any kind; it will be evaluated using Ruby's
      #     rules for truthiness, and the `@value_set` instance
      #     variable set to `true` or `false` accordingly.
      #   @return [Boolean]
      #     `true` if the test value has been set with `#value=`,
      #     `false` otherwise.
      def value_set=(val)
        @value_set	= val ? true : false
        return @value_set
      end                       # def value_set=(val)
      # @overload value_set!
      #   Unconditionally sets `@value_set` to `true`.
      #   @see #value_set
      #   @see #value_set?
      #   @return [Boolean]
      #     `true`.
      def value_set!
        self.value_set	= true
        return @value_set
      end                       # def value_set!
      # @overload value_set?
      #   @see #value_set
      #   @see #value_set!
      #   @return [Boolean]
      #     `true` if the test value has been set with `#value=`,
      #     `false` otherwise.
      def value_set?
        return @value_set ? true : false
      end                       # def value_set?

      # The `value_set` bits are part of the class' internal
      # management, and not for outsiders to invoke.
      protected(:value_set, :value_set=, :value_set!, :value_set?)

      # @!attribute [rw] value
      # The actual value to be used in testing.  This attribute can
      # only be set if the internal #value_set flag is `false`, and
      # storing something in #value automatically sets that flag.  If
      # the #value_set flag is `true`, attempts to store new contents
      # in #value will result in a `RuntimeErorr` exception being
      # raised.
      # @return [Any]
      #   The actual value to be used in testing.
      attr_reader(:value)
      # @overload value=val
      #   Set the value to be tested.
      #   @note
      #     A one-time operation: once set, the `:value=` method is
      #     disabled. 
      #   @param [Any] val
      #     Whatever object is the focus of this instance of the
      #     class. 
      #   @raise [RuntimeError]
      #     if an attempt is made to change the test value for an
      #     existing instance of the class.
      def value=(val)
        if (self.value_set)
          raise(RuntimeError,
                'test value has already been set ' +
                'and cannot be changed')
        end
        @value		= val
        self.value_set!
        self.update_rendition
        return val
      end                       # def value=(val)

      # @attribute [rw] render
      # How the test value should be rendered as a string.  Must be a
      # string.
      #
      # @see #value
      # @see #update_rendition
      # @raise [TypeError]
      #   if an attempt is made to set to a non-String value.
      attr_reader(:render)
      def render=(val)
        unless (val.kind_of?(String))
          raise(TypeError,
                format('%s :render value can only be strings',
                       self.class.name))
        end
        @render		= val
        #
        # We've done it through the setter method, so deductive
        # updating (via #update_rendition) is now disabled.
        #
        @explicit_rendition = true
        return val
      end                       # def render=(val)

      # @private
      # Array of attributes that have been dynamically added to the
      # current instance.
      # @return [Array<Symbol>
      attr_accessor(:local_attributes)
      protected(:local_attributes=)

      # @!attribute [rw] suffix
      # Optional string intended to be appended to assertion messages
      # and test method names that apply to this test element.
      # @return [String,nil]
      #   the current suffix string, or `nil` if none is set.
      # @overload suffix=(val)
      #   Set the suffix string.  Ordinarily this is done by the
      #   constructor, but the suffix for an existing instance may be
      #   subsequently modified.
      #   @param [String] val
      #     New value for the suffix string.
      attr_accessor(:suffix)

      # Default `Proc` used to render a test value into a string
      # representation.
      Default_Render_Proc = Proc.new { |testval|
        format('%s_%s', testval.class.name, testval.inspect)
      }

      # @!attribute [rw] render_proc
      # @overload render_proc
      #   Return the current `Proc` or `Method` responsible for
      #   rendering a test value into a string representation.
      #   @return [Proc,Method]
      def render_proc
        unless (self.instance_variable_defined?(:@render_proc))
          self.render_proc = Default_Render_Proc
        end
        return @render_proc
      end
      # @overload render_proc=(val)
      #   Install a `Proc` or `Method` (or anything that responds to
      #   `:call`) to deduce default string representations of test
      #   values.
      #   @param [Proc,Method] val
      #   @raise [TypeError]
      #     if the `val` object isn't callable (doesn't respond to
      #     `:call`).
      #   @return [Proc,Method]
      #     the newly-installed rendering procedure.
      #   @see Default_Render_Proc for an example.
      def render_proc=(val)
        unless (val.respond_to?(:call))
          raise(UncallableObject,
                object:	val,
                prefix: 'invalid render_proc')
        end
        @render_proc	= val
        return @render_proc
      end                       # def render_proc=(val)

      # @private
      attr_accessor(:explicit_rendition)
      protected(:explicit_rendition, :explicit_rendition=)

      # @private
      # Try to deduce an appropriate string representation of the test
      # value.
      # Unless a rendition has been explicitly set with #render=,
      # changes to the test value <em>via</em> #value= will invoke
      # this method.
      def update_rendition
        #
        # If the `:render` attribute is `nil`, or we haven't set
        # it with the `#render=` method, we can perform our
        # deduction.  Otherwise it's been done explicitly so we make
        # no changes and just return what's there.
        #
        if (! self.explicit_rendition)
          @render	= self.render_proc.call(self.value)
        end
        return @render
      end                       # def update_rendition
      protected(:update_rendition)

      # @!attribute [rw] attrscope
      # Where to define dynamic attributes — for the instance, or
      # class-wide?
      # @overload attrscope
      #   Return the current scope of dynamic attributes.
      #   @return [Symbol]
      #     `:instance` or `:class`.
      def attrscope
        unless (self.instance_variable_defined?(:@attrscope))
          self.attrscope = Object.new
        end
        return @attrscope
      end
      # @overload attrscope=(val)
      #   Set the scope of new dynamic attributes.  Default is
      #  `:instance`.
      #   @param [Any] val
      #     If `val` is either `:instance` or an object whose class is
      #     a Class object (meaning `val` is an instance), set the
      #     scope to `:instance`.  If `val` is `:class` or is itself a
      #     Class object, the scope is set to `:class`.  In all other
      #     cases, the scope is set to `:instance`, but a warning is
      #     displayed.
      #   @return [Symbol]
      #     `:instance` or `:class`.
      def attrscope=(val)
        if (%i[ class instance ].include?(val))
          @attrscope	= val
        elsif (val.kind_of?(Class))
          @attrscope	= :class
        elsif (val.class.class ==  Class)
          @attrscope	= :instance
        else
          warn(format('%s(%s:%s) being treated as :instance',
                      __callee__.inspect,
                      val.class.name,
                      val.inspect))
          @attrscope	= :instance
        end
        return @attrscope
      end                       # def attrscope=(val)

      # When an attempt is made to set a value for an arbitrary
      # undefined attribute, that attribute will be dynamically
      # created for the class.  <em>Not</em> just for the specific
      # instance.
      # @param [Symbol] meth_sym
      #   The symbollic name of the method being invoked but not
      #   found.
      # @param [Array] 		args
      #   The order-dependent list of actuals passed as part of the
      #   original method invocation.
      # @param [Hash<Symbol=>Any>] kwargs
      #   Hash of any keyword arguments passed as part of the original
      #   method invocation.
      # @return [Any]
      # @raise [NoMethodError]
      #   if the method being invoked is anything other than an
      #   attribute setter ("<em>name</em>=").
      def method_missing(meth_sym, *args, **kwargs)
=begin
        warn(format('%s#%s(%s, %s, %s)',
                    self.class.name,
                    __callee__.to_s,
                    meth_sym.inspect,
                    args.inspect,
                    kwargs.inspect))
=end
        if (@defining_attribute)
          begin
            raise(RuntimeError,
                  format('%s#%s(%s) called while already defining %s',
                         self.class.name,
                         __callee__.to_s,
                         meth_sym.inspect,
                         @defining_attribute.inspect))
          ensure
            @defining_attribute = nil
          end
        end
        result		= nil
        #
        # Turn the method symbol into a String so we can manipulate
        # it.
        #
        meth_sym_s	= meth_sym.to_s
        if (meth_sym_s[-1,1] == '=')
          @defining_attribute = meth_sym_s.to_sym
          #
          # We've been asked to set an attribute value.  Dynamically
          # invoke `attr_accessor` for the base name of the method
          # being invoked.
          #
          scope		= self.attrscope
          receiver	= (scope == :instance) \
                          ? self.singleton_class \
                          : self.class.singleton_class
          attr_getter	= (meth_sym_s[0,meth_sym_s.length-1]).to_sym
          attr_setter	= format('%s=', attr_getter.to_s).to_sym
          receiver.send(:attr_accessor, attr_getter)
          attributes_added = [ attr_getter ]
          if (scope == :instance)
            self.local_attributes |= attributes_added
          else
            self.klass_attributes |= attributes_added
            self.class.send(:def_delegator, self.class, attr_getter)
            self.class.send(:def_delegator, self.class, attr_setter)
          end
          #
          # Now invoke the new accessor with the original arguments.
          #
          @defining_attribute = nil
          result	= self.send(meth_sym, *args, **kwargs)
        else
          #
          # Not a request to set a value, so claim total ignorance.
          #
          raise(NoMethodError,
                format("undefined method `%s' for %s:%s",
                       meth_sym.to_s,
                       self.class.name,
                       self.class.class.name))
        end
        return result
      end                       # def method_missing

      # Constructor for TestElement instances.
      #
      # @note The test value may only be set <strong>once</strong>.
      #   Trying to change the test value after it has already been
      #   set will raise an exception (see #value=).
      # @param  [Array]			args		[]
      #   Order-dependent arguments.  Only the first element is used,
      #   and then only if `kwargs[:value]` is omitted.  In that case,
      #   <strong>and</strong> `args` is not an empty array, `args[0]`
      #   is inserted as the value of `kwargs[:value]`.
      # @param  [Hash<Symbol=>Any>]	kwargs
      # @option kwargs [Any]		:value
      # @option kwargs [String]		:suffix
      # @option kwargs [String]		:render
      # @option kwargs [Any]		any
      # @return [void]
      def initialize(*args, **kwargs)
        #
        # If we were given both something in `args` and a keyword
        # argument `:value`, the latter dominates.  If `args` is
        # specifed with no `:value` keyword, the first element of the
        # former gets loaded into `kwargs`.  When we're done, `kwargs`
        # will contain any testvalue however specified, and that's
        # where we'll look for it henceforth.
        #
        # This allows the simplest syntax of `TestElement.new("val")`.
        #
        if ((! kwargs.has_key?(:value)) && (! args.empty?))
          kwargs[:value]	= args[0]
        end
        #
        # Now everything specified is in the `kwargs` hash.  Moving
        # on..
        #
        # Set up things so we can track dynamic attribute changes.
        #
        self.local_attributes	= []
        unless (self.class.respond_to?(:klass_attributes))
          self.class.singleton_class.send(:attr_accessor,
                                          :klass_attributes)
          self.class.instance_eval('protected(:klass_attributes)')
        end
        unless (self.respond_to?(:klass_attributes))
          self.class.send(:def_delegator,
                          self.class,
                          :klass_attributes)
        end
        self.klass_attributes	||= []
        #
        # Now start processing the keyword arguments.  Remove any that
        # match methods we don't permit to be frobbed externally.
        #
        invalid_kws		= %i[
          explicit_rendition
          klass_attributes
          local_attributes
          value_set
        ]
        invalid_kws.each do |kw_sym|
          kw_regex		= Regexp.new(format('^%s[?=1]?$',
                                                    kw_sym.to_s))
          kwargs.keys.grep(kw_regex).each do |kw_key|
            warn(format('illegal keyword: %s', kw_key.to_s))
            kwargs.delete(kw_key)
          end
        end
        #
        # Now to work on *real* keywords.  Start with ones that affect
        # subsequent processing.
        #
        preproc_kw		= %i[
          render_proc
        ]
        preproc_kw.each do |kw_sym|
          kw_val		= kwargs[kw_sym]
          next if (kw_val.nil?)
          kw_setter		= format('%s=', kw_sym.to_s).to_sym
          self.send(kw_setter, kw_val)
          kwargs.delete(kw_sym)
        end
        #
        # Save any setting for the :value keyword for later
        # processing, since setting it can trigger other behaviour.
        #
        if (value_specified = kwargs.has_key?(:value))
          value_val		= kwargs[:value]
          kwargs.delete(:value)
        end
        #
        # Now our statically defined attributes.
        #
        %i[
          render
          suffix
          value
        ].each do |attr|
          #
          # Directly preset all the attributes to nil; don't go
          # through the getter/setter methods because they're trapped.
          #
          ivar		= format('@%s', attr.to_s).to_sym
          self.instance_variable_set(ivar, nil)
        end
        #
        # Now we're ready to go through the list of keyword
        # arguments.  Any requiring special processing have been
        # removed from the hash.
        #
        kwargs.each do |kw_sym,kw_val|
          #
          # We have a value, even if it's nil.
          #
          kw_setter		= format('%s=', kw_sym.to_s).to_sym
          self.send(kw_setter, kw_val)
        end
        #
        # Now is the time to set the test value.
        #
        if (value_specified)
          self.value		= value_val
        end
        nil
      end                       # def initialize(**kwargs)

      nil
    end                         # class TestElement

    nil
  end                           # module RoUS::TestHelpers

  nil
end                             # module RoUS

# @!macro doc.TAGF.module
module TAGF

  #
  # Types of assertions (see Test::Unit::Assertions):
  #
  # flunk(message="Flunked")
  #   Always fails.
  #
  # assert_block(message='assert_block failed.')
  #   @example Example Custom Assertion
  #
  #	def deny(boolean, message=nil)
  #	  message = build_message(message, '<?> is not false or nil.',
  #				  boolean)
  #	  assert_block(message) do
  #	    not boolean
  #	  end
  #	end
  #
  # assert(object=NOT_SPECIFIED, message=nil, &block)
  #
  # assert_equal(expected, actual, message=nil)
  #
  # assert_raise(*args, &block)
  #
  # assert_raise_with_message(expected_exception_class,
  #			      expected_message,
  #			      message=nil,
  #			      &block)
  #   `expected_message` can be a String or a Regexp.
  #
  # assert_raise_kind_of(*args, &block)
  #
  # assert_instance_of(klass, object, message=nil)
  #
  # assert_not_instance_of(klass, object, message=nil)
  #
  # assert_nil(object, message=nil)
  #
  # assert_kind_of(klass, object, message=nil)
  #
  # assert_not_kind_of(klass, object, message=nil)
  #
  # assert_respond_to(object, method, message=nil)
  #
  # assert_not_respond_to(object, method, message=nil)
  #
  # assert_match(pattern, string, message=nil)
  #
  # assert_same(expected, actual, message=nil)
  #
  # assert_operator(object1, operator, object2, message=nil)
  #
  # assert_not_operator(object1, operator, object2, message=nil)
  #
  # assert_nothing_raised(*args)
  #
  # assert_not_same(expected, actual, message=nil)
  #
  # assert_not_equal(expected, actual, message=nil)
  #
  # assert_not_nil(object, message=nil)
  #
  # assert_not_match(pattern, string, message=nil)
  #
  # assert_no_match(regexp, string, message="")
  #
  # assert_throw(expected_object, message=nil, &proc)
  #   @example
  #	assert_throw(:done) do
  #	  throw(:done)
  #	end
  #
  # assert_nothing_thrown(message=nil, &proc)
  #
  # assert_in_delta(expected_float,
  #		    actual_float,
  #		    delta=0.001,
  #		    message="")
  #   Passes if `expected_float` and `actual_float` are equal
  #   within `delta` tolerance.
  #
  #   @example
  #	assert_in_delta 0.05, (50000.0 / 10**6), 0.00001
  #
  # assert_not_in_delta(expected_float,
  #			actual_float,
  #			delta=0.001,
  #			message="")
  #
  # assert_in_epsilon(expected_float,
  #		      actual_float,
  #		      epsilon=0.001,
  #		      message="")
  #   Passes if `expected_float` and `actual_float` are equal
  #   within `epsilon` relative error of `expected_float`.
  #
  #   @example
  #	assert_in_epsilon(10000.0, 9900.0, 0.1) # -> pass
  #	assert_in_epsilon(10000.0, 9899.0, 0.1) # -> fail
  #
  # assert_not_in_epsilon(expected_float,
  #			  actual_float,
  #                       epsilon=0.001,
  #                       message='')
  #
  # assert_send(send_array, message=nil)
  #   Passes if the method `__send__` returns not false nor nil.
  #
  #   `send_array` is composed of:
  #   * A receiver
  #   * A method
  #   * Arguments to the method
  #
  #   @example
  #	assert_send([[1, 2], :member?, 1]) # -> pass
  #	assert_send([[1, 2], :member?, 4]) # -> fail
  #
  # assert_not_send(send_array, message=nil)
  #
  # assert_boolean(actual, message=nil)
  #   Passes if `actual` is a boolean value.
  #
  #   @example
  #	assert_boolean(true) # -> pass
  #	assert_boolean(nil)  # -> fail
  #
  # assert_true(actual, message=nil)
  #
  # assert_false(actual, message=nil)
  #
  # assert_compare(expected, operator, actual, message=nil)
  #   Passes if expression "`expected` `operator` `actual`" is not
  #   false nor nil.
  #
  #   @example
  #     assert_compare(1, "<", 10)  # -> pass
  #     assert_compare(1, ">=", 10) # -> fail
  #
  # assert_fail_assertion(message=nil)
  #   Passes if assertion is failed in block.
  #
  #   @example
  #     assert_fail_assertion { assert_equal("A", "B") }  # -> pass
  #     assert_fail_assertion { assert_equal("A", "A") }  # -> fail
  #
  # assert_raise_message(expected, message=nil)
  #   Passes if an exception is raised in block and its message is
  #   `expected`.
  #
  #   @example
  #     assert_raise_message("exception") { raise "exception" }  # -> pass
  #     assert_raise_message(/exc/i) { raise "exception" }       # -> pass
  #     assert_raise_message("exception") { raise "EXCEPTION" }  # -> fail
  #     assert_raise_message("exception") {}                     # -> fail
  #
  # assert_const_defined(object, constant_name, message=nil)
  #   Passes if `object`.const_defined?(`constant_name`)
  #
  #   @example
  #     assert_const_defined(Test, :Unit)          # -> pass
  #     assert_const_defined(Object, :Nonexistent) # -> fail
  #
  # assert_not_const_defined(object, constant_name, message=nil)
  #
  # assert_predicate(object, predicate, message=nil)
  #   Passes if `object`.`predicate` is not false nor nil.
  #
  #   @example
  #     assert_predicate([], :empty?)  # -> pass
  #     assert_predicate([1], :empty?) # -> fail
  #
  # assert_not_predicate(object, predicate, message=nil)
  #
  # assert_alias_method(object, alias_name, original_name, message=nil)
  #   Passes if `object`#`alias_name` is an alias method of
  #   `object`#`original_name`.
  #
  #   @example
  #     assert_alias_method([], :length, :size)  # -> pass
  #     assert_alias_method([], :size, :length)  # -> pass
  #     assert_alias_method([], :each, :size)    # -> fail
  #
  # assert_path_exist(path, message=nil)
  #   Passes if filesystem `path` exists.
  #
  #   @example
  #     assert_path_exist("/tmp")          # -> pass
  #     assert_path_exist("/bin/sh")       # -> pass
  #    assert_path_exist("/nonexistent")  # -> fail
  #
  # assert_path_not_exist(path, message=nil)
  #
  # assert_include(collection, object, message=nil)
  #   Passes if `collection` includes `object`.
  #
  #   @example
  #     assert_include([1, 10], 1)            # -> pass
  #     assert_include(1..10, 5)              # -> pass
  #     assert_include([1, 10], 5)            # -> fail
  #     assert_include(1..10, 20)             # -> fail
  #
  # assert_not_include(collection, object, message=nil)
  #
  # assert_empty(object, message=nil)
  #   Passes if `object` is empty.
  #
  #   @example
  #     assert_empty("")                       # -> pass
  #     assert_empty([])                       # -> pass
  #     assert_empty({})                       # -> pass
  #     assert_empty(" ")                      # -> fail
  #     assert_empty([nil])                    # -> fail
  #     assert_empty({ 1 => 2 })               # -> fail
  #
  # assert_not_empty(object, message=nil)
  #
  # assert_all(collection, message=nil)
  #   @overload assert_all(collection, message=nil, &block)
  #
  #     Asserts that all `block.call(item)` where `item` is each
  #     item in `collection` are not false nor nil.
  #
  #     If `collection` is empty, this assertion is always passed
  #     with any `block`.
  #
  #     @example Pass patterns
  #       assert_all([1, 2, 3]) {|item| item > 0} # => pass
  #       assert_all([1, 2, 3], &:positive?)      # => pass
  #       assert_all([]) {|item| false}           # => pass
  #
  #     @example Failure pattern
  #       assert_all([0, 1, 2], &:zero?) # => failure
  #
  #     @param [#each] collection The check target.
  #     @param [String] message The additional user message. It is
  #       showed when the assertion is failed.
  #     @yield [Object] Give each item in `collection` to the block.
  #     @yieldreturn [Object] The checked object.
  #     @return [void]
  #
  # assert_nothing_leaked_memory(max_increasable_size,
  #                              target=:physical,
  #                              message=nil)
  #   @overload assert_nothing_leaked_memory(max_increasable_size,
  #                                          target=:physical,
  #                                          message=nil,
  #                                          &block)
  #
  #     Asserts that increased memory usage by `block.call` is less
  #     than `max_increasable_size`. `GC.start` is called before and
  #     after `block.call`.
  #
  #     This assertion may be fragile. Because memory usage is depends
  #     on the current Ruby process's memory usage. Launching a new
  #     Ruby process for this will produce more stable result but we
  #     need to specify target code as `String` instead of block for
  #     the approach. We choose easy to write API approach rather than
  #     more stable result approach for this case.
  #
  #     @example Pass pattern
  #       require "objspace"
  #       size_per_object = ObjectSpace.memsize_of("Hello")
  #       # If memory isn't leaked, physical memory of almost created
  #       # objects (1000 - 10 objects) must be freed.
  #       assert_nothing_leaked_memory(size_per_object * 10) do
  #         1_000.times do
  #           "Hello".dup
  #         end
  #       end # => pass
  #
  #     @example Failure pattern
  #       require "objspace"
  #       size_per_object = ObjectSpace.memsize_of("Hello")
  #       strings = []
  #       assert_nothing_leaked_memory(size_per_object * 10) do
  #         10_000.times do
  #           # Created objects aren't GC-ed because they are
  #           # referred.
  #           strings << "Hello".dup
  #         end
  #       end # => failure
  #
  #     @param target [:physical, :virtual] which memory usage is
  #       used for comparing. `:physical` means physical memory usage
  #       also known as Resident Set Size (RSS). `:virtual` means
  #       virtual memory usage.
  #     @yield [] do anything you want to measure memory usage
  #       in the block.
  #     @yieldreturn [void]
  #     @return [void]
  #
  class TestUnitAssertionsDoc ; end

  nil
end				# module TAGF

# Local Variables:
# mode: ruby
# indent-tabs-mode: nil
# eval: (if (intern-soft "fci-mode") (fci-mode 1))
# eval: (auto-fill-mode 1)
# End:
