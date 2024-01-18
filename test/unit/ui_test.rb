require('tagf/ui')
require('test/unit')

class Test_UI < Test::Unit::TestCase

  include TAGF::UI

  def setup
    @samples		= YAML.load('../fixtures/truthify.yaml')
  end                           # def setup

  def teardown
    
  end                           # def teardown

  #
  def test_read1line
    streamin		= File.open('duh.test', 'r')
    plex		= Plex.new(instream: streamin)
    testval		= plex.readline
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
# eval: (auto-fill-mode 1)
# End:
