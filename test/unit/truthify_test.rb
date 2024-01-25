require('tagf/mixin/universal')
require('test/unit')
require('pp')
require('byebug')

class Test_Truthify < Test::Unit::TestCase

  include TAGF::Mixin::UniversalMethods

  TrueValues		= [
    true,
    'true',
    'True',
    't',
    'T',
    :true,
    Math::PI,
    Math::PI.to_s,
    1,
    17,
    1.0,
    0.1,
    (1+0i),
    (1-0i),
    (0+1i),
    (0-1i),
    (1.0+0i),
    (1.0-0i),
    (0+1.0i),
    (0-1.0i),
    (0.0+1.0i),
    (0.0-1.0i),
    (1.0+1.0i),
    (1.0-1.0i),
    '1',
    '17',
    '1.0',
    '0.1',
    '(1+0i)',
    '(1-0i)',
    '(0+1i)',
    '(0-1i)',
    '(1.0+0i)',
    '(1.0-0i)',
    '(0+1.0i)',
    '(0-1.0i)',
    '(0.0+1.0i)',
    '(0.0-1.0i)',
    '(1.0+1.0i)',
    '(1.0-1.0i)',
    Object.new,
  ]

  FalseValues		= [
    false,
    'false',
    'False',
    'f',
    'F',
    :false,
    nil,
    'nil',
    'empty',
    'unknown',
    0,
    '0',
    0.0,
    '0.0',
    (0+0i),
    (0-0i),
    (0.0+0i),
    (0.0-0i),
    (0+0.0i),
    (0-0.0i),
    (0.0+0.0i),
    (0.0-0.0i),
    '(0+0i)',
    '(0-0i)',
    '(0.0+0i)',
    '(0.0-0i)',
    '(0+0.0i)',
    '(0-0.0i)',
    '(0.0+0.0i)',
    '(0.0-0.0i)',
  ]

  TruthyProc_AlwaysTrue	= Proc.new { |testvalue| true }

  TruthyProc_AlwaysFalse = Proc.new { |testvalue| false }

  def setup

    nil
  end                           # def setup

  def teardown
    
  end                           # def teardown

  #
  def test_true
    TrueValues.each do |testval|
      msg		= format('truthify(%s:%s) => true failed',
                                 testval.class.name,
                                 testval.inspect)
      assert_true(truthify(testval), msg)
    end                         # TrueValues.each do |testval|
  end                           # def test_true

  #
  def test_false
    FalseValues.each do |testval|
      msg		= format('truthify(%s:%s) => false failed',
                                 testval.class.name,
                                 testval.inspect)
      assert_false(truthify(testval), msg)
    end                         # FalseValues.each do |testval|
  end                           # def test_false

  #
  def test_true_value_array
    
  end                           # def test_true_value_array

  #
  def test_truthiness_proc_true
    (TrueValues + FalseValues).each do |testval|
      msg		= format('truthify(%s:%s) => true',
                                 testval.class.name,
                                 testval.inspect)
      assert_true(truthify(testval,
                           truthiness_proc: TruthyProc_AlwaysTrue),
                  msg)
    end
  end                           # def test_truthiness_proc_true

  #
  def test_truthiness_proc_false
    (TrueValues + FalseValues).each do |testval|
      msg		= format('truthify(%s:%s) => false',
                                 testval.class.name,
                                 testval.inspect)
      assert_false(truthify(testval,
                            truthiness_proc: TruthyProc_AlwaysFalse),
                   msg)
    end
  end                           # def test_truthiness_proc_false

  nil
end                             # class Test_Truthify

# Local Variables:
# mode: ruby
# indent-tabs-mode: nil
# eval: (if (intern-soft "fci-mode") (fci-mode 1))
# eval: (auto-fill-mode 1)
# End:
