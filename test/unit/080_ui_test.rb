require('tagf/ui')
require('test/unit')

class Test_UI < Test::Unit::TestCase

  include(TAGF::UI)
  include(TAGF::Mixin::UniversalMethods)

  #
  # Executed before each test is invoked.
  #
  def setup
    fspec		= File.join(FixturesDir, 'truthify.yaml')
    @samples		= YAML.load(File.read(fspec))
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

  #
  def test_read1line
    streamin		= File.open('duh.test', 'r')
    plex		= Plex.new(instream: streamin)
    testval		= plex.readline
    @samples['true'].each do |testval|
      msg		= format('truthify(%s:%s) => true failed',
                                 testfile.class.name,
                                 testval.inspect)
      assert(truthify(testval), msg)
    end                         # @samples['true'].each do
  end                           # def test_read1line

  nil
end                             # class Test_UI

# Local Variables:
# mode: ruby
# indent-tabs-mode: nil
# eval: (if (intern-soft "fci-mode") (fci-mode 1))
# eval: (auto-fill-mode 1)
# End:
