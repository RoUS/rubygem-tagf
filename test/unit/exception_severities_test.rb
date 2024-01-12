require('tagf/exceptions')
require('test/unit')

class Test_Exception_Severities < Test::Unit::TestCase

  include TAGF::Exceptions

  DefaultSeverity	= {
#    LimitItems:			SEVERITY.warning,
    NoLoadFile:			SEVERITY.error,
    BadLoadFile:		SEVERITY.severe,
    NotExceptionClass:		SEVERITY.error,
#    NotGameElement:		SEVERITY.severe,
#    NoObjectOwner:		SEVERITY.severe,
#    KeyObjectMismatch:		SEVERITY.severe,
#    NoGameContext:		SEVERITY.severe,
#    SettingLocked:		SEVERITY.warning,
#    ImmovableObject:		SEVERITY.error,
#    NotAContainer:		SEVERITY.error,
#    AliasRedefinition:		SEVERITY.warning,
#    UnscrewingInscrutable:	SEVERITY.error,
#    MasterInventory:		SEVERITY.error,
#    HasNoInventory:		SEVERITY.error,
#    AlreadyHasInventory:	SEVERITY.warning,
#    AlreadyInInventory:		SEVERITY.warning,
#    ImmovableElementDestinationError: SEVERITY.error,
#    DuplicateObject:		SEVERITY.error,
#    DuplicateItem:		SEVERITY.error,
#    DuplicateLocation:		SEVERITY.error,
  }

  def setup
    nil
  end                           # def setup

  def teardown
    nil
  end                           # def teardown

  #
  def test_class_default_severity
    DefaultSeverity.each do |exsym,xclass|
      klass_i		= eval(format('%s.new', exsym.to_s))
      assert_equal(klass_i.severity, xclass)
    end
  end                           # def test_class_default_severity

  #
  def test_class_change_default_severity
    DefaultSeverity.each do |exsym,xclass|
      klass_i		= eval(format('%s.new', exsym.to_s))
      while ((newsev = SEVERITY_LEVELS.sample) != xclass)
        nil
      end
      testsev		= klass_i.severity = newsev
      assert_equal(testsev, newsev)
    end
  end                           # def test_class_change_default_severity

end                             # class Test_Exception_Severities

# Local Variables:
# mode: ruby
# indent-tabs-mode: nil
# eval: (if (intern-soft "fci-mode") (fci-mode 1))
# eval: (auto-fill-mode 1)
# End:
