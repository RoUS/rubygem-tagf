require('tagf/exceptions')
require('test/unit')

class Test_Exception_Severities < Test::Unit::TestCase

  include TAGF::Exceptions

  ExceptionClasses	= {
    InvalidSeverity:		SEVERITY.warning,
    LimitItems:			SEVERITY.warning,
    NoLoadFile:			SEVERITY.error,
    BadLoadFile:		SEVERITY.severe,
    NotExceptionClass:		SEVERITY.error,
    NotGameElement:		SEVERITY.severe,
    NoObjectOwner:		SEVERITY.severe,
    KeyObjectMismatch:		SEVERITY.severe,
    NoGameContext:		SEVERITY.severe,
    SettingLocked:		SEVERITY.warning,
    ImmovableObject:		SEVERITY.error,
    NotAContainer:		SEVERITY.error,
    AliasRedefinition:		SEVERITY.warning,
    UnscrewingInscrutable:	SEVERITY.error,
    MasterInventory:		SEVERITY.error,
    HasNoInventory:		SEVERITY.error,
    AlreadyHasInventory:	SEVERITY.warning,
    AlreadyInInventory:		SEVERITY.warning,
    ImmovableElementDestinationError: SEVERITY.error,
    DuplicateObject:		SEVERITY.warning,
    DuplicateItem:		SEVERITY.warning,
    DuplicateLocation:		SEVERITY.warning,
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
    ExceptionClasses.each do |exsym,kdefsev|
      klass_o		= eval(exsym.to_s)
      klass_i		= nil
      msg		= format('Instantiating ' \
                                 + '%s.new("testing message")',
                                 exsym.to_s)
      assert_nothing_raised(msg) do
        klass_i		= klass_o.new('testing message')
      end
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
    ExceptionClasses.each do |exsym,kdefsev|
      klass_o		= eval(exsym.to_s)
      klass_i		= nil
      msg		= format('Instantiating ' \
                                 + '%s.new("testing message")',
                                 exsym.to_s)
      assert_nothing_raised(msg) do
        klass_i		= klass_o.new('testing message')
      end
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
  def test_instance_inherits_class_default_severity
    ExceptionClasses.each do |exsym,kdefsev|
      klass_o		= eval(exsym.to_s)
      klass_i		= nil
      msg		= format('Instantiating ' \
                                 + '%s.new("testing message")',
                                 exsym.to_s)
      assert_nothing_raised(msg) do
        klass_i		= klass_o.new('testing message')
      end
      assert_equal(klass_i.severity,
                   klass_o.severity,
                   format('Verifying %s instances inherit class ' \
                          'severity',
                          exsym.to_s))
    end
  end                           # def test_instance_inherits_class_default_severity

  # * Test that new instances inherit the changed class severity
  # * Test that new instances can have their severity changed w/o
  #   affecting class severity
  #
  # * Test that passing a string makes that the message
  # * Test that properly-formatted actuals produce the correct message

  nil
end                             # class Test_Exception_Severities

# Local Variables:
# mode: ruby
# indent-tabs-mode: nil
# eval: (if (intern-soft "fci-mode") (fci-mode 1))
# eval: (auto-fill-mode 1)
# End:
