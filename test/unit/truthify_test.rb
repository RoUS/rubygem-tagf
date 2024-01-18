require('tagf/mixin/universal')
require('test/unit')
require('pp')
require('byebug')

class Test_Truthify < Test::Unit::TestCase

  include TAGF::Mixin::UniversalMethods

  FixturesDir		= File.join(Pathname(__FILE__).dirname,
                                    '..',
                                    'fixtures')
  TrueValues		= [
    true,
    'true',
    'True',
    't',
    'T',
    1,
  ]

  FalseValues		= [
    false,
    'false',
    'False',
    'f',
    'F',
    nil,
    'nil',
    0,
    0.0,
    (0+0i),
  ]

  def setup

    nil
  end                           # def setup

  def teardown
    
  end                           # def teardown

  #
  def test_true
    TrueValues.each do |testval|
      assert(format('truthify(%s) => true failed', testval.inspect)) do
        truthify(testval)
      end
    end                         # @samples['true'].each do
  end                           # def test_true

  #
  def test_false
    FalseValues.each do |testval|
      assert(format('truthify(%s) => false failed', testval.inspect)) do
        (! truthify(testval))
      end
    end                         # @samples['true'].each do
  end                           # def test_true

  nil
end                             # class Test_Truthify

# Local Variables:
# mode: ruby
# indent-tabs-mode: nil
# eval: (if (intern-soft "fci-mode") (fci-mode 1))
# eval: (auto-fill-mode 1)
# End:
