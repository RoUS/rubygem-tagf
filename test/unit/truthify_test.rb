require('tagf/mixin/base')
require('test/unit')

class Test_Truthify < Test::Unit::TestCase

  def setup
    
  end                           # def setup

  def teardown
    
  end                           # def teardown

  #
  def test_true
    assert('truthify(true) failed') do
      TAGF.truthify(true)
    end
  end                           # def test_true

end                             # class Test_Truthify

# Local Variables:
# mode: ruby
# indent-tabs-mode: nil
# eval: (if (intern-soft "fci-mode") (fci-mode 1))
# End:
