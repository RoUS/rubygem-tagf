require('tagf/mixin/universal')
require('test/unit')
require('pp')
require('byebug')

class Test_Truthify < Test::Unit::TestCase

  include(TAGF::Mixin::UniversalMethods)

  # Eigenclass for Test_Truthify class.
  class << self
    
    #
    # Proc used to add a value, and its string representation, to a
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
      suffix		= kwargs[:suffix]
      if (suffix.nil?)
        result		= [elt]
        unless (kwargs[:nostring])
	  result		<< elt.to_s
        end
      else
        result		= [
	  {
	    elt		=> suffix,
	  },
        ]
        unless (kwargs[:nostring])
	  result		<< {
	    elt.to_s	=> suffix,
	  }
        end
      end
      return result
    end                         # def addtestval(elt, **kwargs)

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
    *addtestval(1.0,		suffix:   '1p0'),
    *addtestval(0.1,		suffix:   '0p1'),
    *addtestval((0+1i),		suffix:   'paren_0_plus_1i_paren'),
    *addtestval((0-1i),		suffix:   'paren_0_minus_1i_paren'),
    *addtestval((0+1.0i),	suffix:   'paren_0_plus_1p0i_paren'),
    *addtestval((0-1.0i),	suffix:   'paren_0_minus_1p0i_paren'),
    *addtestval((0.0+1i),	suffix:   'paren_0p0_plus_1i_paren'),
    *addtestval((0.0-1i),	suffix:   'paren_0p0_minus_1i_paren'),
    *addtestval((0.0+1.0i),	suffix:   'paren_0p0_plus_1p0i_paren'),
    *addtestval((0.0-1.0i),	suffix:   'paren_0p0_minus_1p0i_paren'),
    *addtestval((1+0i),		suffix:   'paren_1_plus_0i_paren'),
    *addtestval((1-0i),		suffix:   'paren_1_minus_0i_paren'),
    *addtestval((1+1i),		suffix:   'paren_1_plus_1i_paren'),
    *addtestval((1-1i),		suffix:   'paren_1_minus_1i_paren'),
    *addtestval((1.0+0i),	suffix:   'paren_1p0_plus_0i_paren'),
    *addtestval((1.0-0i),	suffix:   'paren_1p0_minus_0i_paren'),
    *addtestval((1.0+1.0i),	suffix:   'paren_1p0_plus_1p0i_paren'),
    *addtestval((1.0-1.0i),	suffix:   'paren_1p0_minus_1p0i_paren'),
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
    *addtestval(0.0,		suffix: '0p0'),
    *addtestval((0+0i)),#		suffix: 'paren_0_plus_0i_paren'),
    *addtestval((0-0i),		suffix: 'paren_0_minus_0i_paren'),
    *addtestval((0.0+0i),	suffix: 'paren_0p0_plus_0i_paren'),
    *addtestval((0.0-0i),	suffix: 'paren_0p0_minus_0i_paren'),
    *addtestval((0+0.0i),	suffix: 'paren_0_plus_0p0i_paren'),
    *addtestval((0-0.0i),	suffix: 'paren_0_minus_0p0i_paren'),
    *addtestval((0.0+0.0i),	suffix: 'paren_0p0_plus_0p0i_paren'),
    *addtestval((0.0-0.0i),	suffix: 'paren_0p0_minus_0p0i_paren'),
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
  TrueValues.each do |testval|
    suffix		= nil
    if (testval.kind_of?(Hash))
      (testval, suffix)	= testval.first
    end
    msg			= format('Testing for true: %s:%s',
				 testval.class.name,
				 testval.inspect)
    testname		= mktestname(expect:  true,
				     testval: testval,
				     suffix:  suffix)
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

  def setup

    nil
  end				# def setup

  def teardown

    nil
  end				# def teardown

  nil
end				# class Test_Truthify

# Local Variables:
# mode: ruby
# indent-tabs-mode: nil
# eval: (if (intern-soft "fci-mode") (fci-mode 1))
# eval: (auto-fill-mode 1)
# End:
