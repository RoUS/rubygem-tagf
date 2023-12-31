require('tagf/mixin/base')
require('test/unit')

class Test_Truthify < Test::Unit::TestCase

  def setup
    @samples		= YAML.load('../fixtures/truthify.yaml')
  end                           # def setup

  def teardown
    
  end                           # def teardown

  #
  def test_true
    @samples['true'].each do |testval|
      assert(format('truthify(%s) => true failed', testval.inspect) do
      TAGF.truthify(testval)
    end                         # @samples['true'].each do
  end                           # def test_true

end                             # class Test_Truthify

# Local Variables:
# mode: ruby
# indent-tabs-mode: nil
# eval: (if (intern-soft "fci-mode") (fci-mode 1))
# End:
