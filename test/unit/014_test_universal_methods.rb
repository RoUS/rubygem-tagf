require('test/unit')
require('ostruct')
require('pp')
require('byebug')

#
# Test our custom bits from test/test_helper.rb
#
class Test_UniversalMethods < Test::Unit::TestCase

  include(RoUS::TestHelpers)
  include(TAGF::Mixin::UniversalMethods)

  Exception_Text	= 'explicit static text'

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

  # Things to test:
  # * _inivaluate_args
  # * decompose_attrib
  # * game_options?
  # * is_game_element?
  # * pluralise
  # * raise_exception (has its own tests)
  # * truthify (already has its own tests)
  #

  def test_010_inivaluate_args
    
  end                           # test_010_inivaluate_args

  def test_020_decompose_attrib
    
  end                           # test_020_decompose_attrib

  def test_030_game_options?
    
  end

  def test_040_is_game_element?
    
  end                           # test_040_is_game_element?

  def test_050_pluralise
    
  end                           # test_050_pluralise

  nil
end				# class Test_UniversalMethods

# Local Variables:
# mode: ruby
# indent-tabs-mode: nil
# eval: (if (intern-soft "fci-mode") (fci-mode 1))
# eval: (auto-fill-mode 1)
# End:
