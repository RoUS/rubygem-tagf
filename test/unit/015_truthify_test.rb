require('tagf/mixin/universal')
require('test/unit')
require('ostruct')
require('pp')
require('byebug')

class Test_Truthify < Test::Unit::TestCase

  include(TAGF::Mixin::UniversalMethods)
  include(RoUS::TestHelpers)
  extend(self)

  #
  # Method used to add a value, and its string representation, to a
  # test input list.
  #
  # @param [Object]               elt
  #   The object to be tested.  The result array will include this
  #   and also an entry for `elt#to_s`.
  # @param [Hash<Symbol=>String>] kwargs
  #   Keyword arguments customising behaviour.
  # @option kwargs [String]       :suffix     (nil)
  #   By default, the name of the test generated will include the
  #   string representation of `elt`.  For cases in which the
  #   `#to_s` value includes characters illegal in method names, the
  #   `:suffix` option permits the developer to provide a safe
  #   alternative.
  # @option kwargs [String]       :nostring   (nil)
  #   If passed with a truthy value, no second stringified (with
  #   `#to_s`) representation is added to the return array.  This
  #   is useful when the stringified value is added separately.
  # @return [Array<(Object,String)>]
  #   if no `:suffix` option was provided.  The two elements are
  #   the original `elt` value and that of `elt#to_s` (unless
  #   option `:nostring` was specified with a true value).
  # @return [Array[(Hash<Object=>String>)]
  #   single-element array with the test value and the constructed
  #   suffix.
  # @return [Array[(Hash<Object=>String>,Hash<String=>String>)]
  #   an array containing two single-element hashes.  The key of
  #   one is the raw value of `elt`, and the other is its string
  #   representation.  The value in each case is the value of the
  #   `:suffix` option.
  def addtestval(elt, **kwargs)
    result		= []
    debugger if (elt == '(1+0i)')
    value_raw		= elt
    suffix		= kwargs[:suffix]
    coercer		= kwargs[:coerce]
    dostring		= (! kwargs[:nostring])
    value_coerced	= coerce_to(coercer, elt)
    value_stringed	= value_coerced.to_s
    #
    # `testval` contains the actual value to be tested.  Now we need
    # to determine whether or not to add a string representation as
    # an additional test value.
    #
    # Suffix truth table:
    #  V₁ = elt
    #  V₂ = coerced-elt
    #  V₃ = V₁.to_s
    #  V₄ = V₂.inspect
    #  V₅ = V₂.to_s
    #  V₆ = V₁.inspect
    #  K₁ = V₁.class.name
    #  K₂ = V₂.class.name
    #  K₃ = V₃.class.name
    #  K₄ = V₄.class.name
    #  I₁ = V₁.inspect
    #  I₂ = V₂.inspect
    #  I₃ = V₃.inspect
    # elt        suffix  coerce    suffix₁  nostring  alt  suffix₂
    #  "(1+1i)"   nil     false     K₁:I₁    no
    #  "(1+1i)"   nil     false     K₁:I₁    yes
    #  "(1+1i)"   nil     true      K₂:I₂    no        V₂   K₂:I₁
    #  "(1+1i)"   nil     true      K₁:I₁    yes
    #  "(1+1i)"   "foo"   false     "foo"    no
    #  "(1+1i)"   "foo"   false     "foo"    yes
    #  "(1+1i)"   "foo"   true      "foo"    no        V₂   "foo"
    #  "(1+1i)"   "foo"   true      "foo"    yes
    #  1          nil     false     K₁:I₁    no        V₃   K₃:I₁
    #  1          nil     false     K₁:I₁    yes
    #  1          nil     true      K₂:I₂    no        Exception
    #  1          nil     true      K₁:I₁    yes       Exception
    #  1          "foo"   false     "foo"    no
    #  1          "foo"   false     "foo"    yes
    #  1          "foo"   true      "foo"    no        Exception
    #  1          "foo"   true      "foo"    yes       Exception
    #
    item_s		=
      unless (suffix)
        if (coercer && elt.kind_of?(String))
          item_s	= elt
        else
          item_s	= testval.inspect
        end
        suffix		= format('%s:%s',
                                 testval.class.name,
                                 item_s)
      end
    req		= OpenStruct.new(
      value:		testval,
      suffix:		suffix
    )
    result		<< req
    #
    # Now see if we need to add an element for a string version.
    #
    if (dostring)
      req		= OpenStruct.new(
        value		=
        end
        value_list	= [ testval ]
        result		= []
        if (dostring)
          if (coercer.nil?)
            value_list	<< testval.inspect
          else
            value_list	<< elt
          end
        end
        if (! kwargs.empty?)
          value_list.each do |val|
            result	<< {
              val		=> suffix,
            }.merge(kwargs)
          end
        else
          result		= value_list
        end
        return result
        end                         # def addtestval(elt, **kwargs)

  # Eigenclass for Test_Truthify class.
  class << self


    nil
  end                           # class Test_Truthify eigenclass

  #
  # Test values that should always be considered truthy according to
  # our default rules.	Implemented as an array to ensure all of our
  # test values are handled; if done as a hash, some of the complex
  # values will fold together.
  #
  # Each element in the array is either a scalar, or a hash of
  # {testval=>testname-suffix}, allowing us to supply a string suffix
  # for the testname in cases where it is hard to evolve a readable
  # suffix from the test value.
  # @see addtestval
  # @see FalseValues
  #
  TrueValues		= [
    *addtestval(true,		suffix:   '_Boolean_true',
				nostring: true),
    'true',
    'True',
    't',
    'T',
    :true,
    *addtestval(Object.new,	suffix:   'new',
             			nostring: true),
    *addtestval(Math::PI,	suffix:   'MathPI'),
    *addtestval(1),
    *addtestval(17),
    *addtestval(1.0),
    *addtestval(0.1),
    *addtestval('(0+1i)',	coerce:   Complex),
    *addtestval('(0-1i)',	coerce:   Complex),
    *addtestval('(0+1.0i)',	coerce:   Complex),
    *addtestval('(0-1.0i)',	coerce:   Complex),
    *addtestval('(0.0+1i)',	coerce:   Complex),
    *addtestval('(0.0-1i)',	coerce:   Complex),
    *addtestval('(0.0+1.0i)',	coerce:   Complex),
    *addtestval('(0.0-1.0i)',	coerce:   Complex),
    *addtestval('(1+0i)',	coerce:   Complex),
    *addtestval('(1-0i)',	coerce:   Complex),
    *addtestval('(1+1i)',	coerce:   Complex),
    *addtestval('(1-1i)',	coerce:   Complex),
    *addtestval('(1.0+0i)',	coerce:   Complex),
    *addtestval('(1.0-0i)',	coerce:   Complex),
    *addtestval('(1.0+1.0i)',	coerce:   Complex),
    *addtestval('(1.0-1.0i)',	coerce:   Complex),
  ]

  #
  # Test values that should always be considered UNtruthy according to
  # our default rules.
  # @see TrueValues
  # @see addtestval
  #
  FalseValues		= [
    *addtestval(false,		suffix:   '_Boolean_false',
				nostring: true),
    'false',
    'False',
    'f',
    'F',
    :false,
    *addtestval(nil,		suffix:   'nil',
             			nostring: true),
    'nil',
    'empty',
    'unknown',
    *addtestval(0),
    *addtestval(0.0),
    *addtestval('(0+0i)',	coerce:   Complex),
    *addtestval('(0-0i)',	coerce:   Complex),
    *addtestval('(0.0+0i)',	coerce:   Complex),
    *addtestval('(0.0-0i)',	coerce:   Complex),
    *addtestval('(0+0.0i)',	coerce:   Complex),
    *addtestval('(0-0.0i)',	coerce:   Complex),
    *addtestval('(0.0+0.0i)',	coerce:   Complex),
    *addtestval('(0.0-0.0i)',	coerce:   Complex),
  ]

  #
  # Truthiness rule proc that always returns true.
  #
  TruthyProc_AlwaysTrue	= Proc.new { |testvalue|
    true
  }

  #
  # Truthiness rule proc that always returns false.
  #
  TruthyProc_AlwaysFalse = Proc.new { |testvalue|
    false
  }

  #
  # Generate tests for values that should be considered truthy by
  # our default rules.
  #
  TrueValues.each do |elt|
    suffix		= nil
    coercer		= nil
    testval		= 'undefined'
    if (elt.kind_of?(Hash))
      elt.to_a.each do |k,v|
        case(k)
        when :coerce
          coercer	= v
        when :suffix
          suffix	= v
        else
          testval	= k
          suffix	||= v
        end                     # case(k)
      end                       # elt.to_a.each do |k,v|
    else
      testval		= elt
      suffix		= elt.inspect
    end                         # if (elt.kind_of?(Hash)
    if (coercer)
      testval		= coerce_to(coercer, testval)
    end
    msg			= format('Testing for true: %s:%s',
				 testval.class.name,
				 testval.inspect)
    testname		= mktestname(expect:  true,
				     testval: testval,
				     suffix:  suffix,
                                     coerce:  coercer)
    warn(format("\nelt = %s\nmsg=%s\ntestname=%s\n",
                PP.pp(elt, ''),
                msg.inspect,
                testname.inspect))
    define_method(testname) do
      assert_true(truthify(testval), "#{msg}")
    end
  end				# TrueValues.each

  #
  # Generate tests for values that should be considered UNtruthy by
  # our default rules.
  #
  FalseValues.each do |testval|
    suffix		= nil
    if (testval.kind_of?(Hash))
      (testval, suffix)	= testval.first
    end
    msg			= format('Testing for false: %s:%s',
				 testval.class.name,
				 testval.inspect)
    testname		= mktestname(expect:  false,
				     testval: testval,
				     suffix:  suffix)
    define_method(testname) do
      assert_false(truthify(testval), "#{msg}")
    end
  end				# FalseValues.each

  #
  # Generate tests for our custom truthiness procs.
  #
  (TrueValues | FalseValues).each do |testval|
    suffix		= nil
    if (testval.kind_of?(Hash))
      (testval, suffix)	= testval.first
    end
    msg			= format('Custom proc should return true ' +
				 'for: %s:%s',
				 testval.class.name,
				 testval.inspect)
    testname		= mktestname(expect:  true,
				     testval: testval,
				     suffix:  suffix,
				     prefix:  'trueproc')
    define_method(testname) do
      answer		= truthify(testval,
				   truthiness_proc: TruthyProc_AlwaysTrue)
      assert_true(answer, "#{msg}")
    end
    #
    msg			= format('Custom proc should return false ' +
				 'for: %s:%s',
				 testval.class.name,
				 testval.inspect)
    testname		= mktestname(expect:  false,
				     testval: testval,
				     suffix:  suffix,
				     prefix:  'falseproc')
    define_method(testname) do
      answer		= truthify(testval,
				   truthiness_proc: TruthyProc_AlwaysFalse)
      assert_false(answer, "#{msg}")
    end
  end				# TrueValues.merge(FalseValues).each

  #
  # Executed before each test is invoked.
  #
  def setup
    begin
      super
    rescue NoMethodError
      # No-op
    end
    return nil
  end                           # def setup

  #
  # Called after each test method completes.
  #
  def teardown
    begin
      super
    rescue NoMethodError
      # No-op
    end
    return nil
  end                           # def teardown

  nil
end				# class Test_Truthify

# Local Variables:
# mode: ruby
# indent-tabs-mode: nil
# eval: (if (intern-soft "fci-mode") (fci-mode 1))
# eval: (auto-fill-mode 1)
# End:
