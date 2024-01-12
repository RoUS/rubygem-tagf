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

  # * Test that default class runtime severities match the hardcoded
  #   values 
  def test_class_default_severity
    DefaultSeverity.each do |exsym,kdefsev|
      klass_i		= eval(format('%s.new', exsym.to_s))
      assert_equal(klass_i.severity,
                   kdefsev,
                   format('Verifying unmodified default severity ' \
                          'for %s is %d',
                          exsym.to_s,
                          kdefsev))
    end
  end                           # def test_class_default_severity

  # * Test that changes to the default class severity persist
  def test_class_change_default_severity
    DefaultSeverity.each do |exsym,kdefsev|
      klass_i		= eval(format('%s.new', exsym.to_s))
      #
      # Pick a different severity level than the default, then set it
      # as the new class default.
      #
      while ((newsev = SEVERITY_LEVELS.sample) != kdefsev)
        nil
      end
      klass_i.severity	= newsev
      assert_equal(klass_i.severity,
                   newsev,
                   format('Verifying %s default severity changed ' \
                          'from %d to %d',
                          exsym.to_s,
                          kdefsev,
                          newsev))
    end
  end                           # def test_class_change_default_severity

  # * Test that new instances inherit the class severity
  # * Test that new instances inherit the changed class severity
  # * Test that new instances can have their severity changed w/o
  #   affecting class severity

  nil
end                             # class Test_Exception_Severities

# Local Variables:
# mode: ruby
# indent-tabs-mode: nil
# eval: (if (intern-soft "fci-mode") (fci-mode 1))
# eval: (auto-fill-mode 1)
# End:
