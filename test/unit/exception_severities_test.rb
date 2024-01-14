require('tagf/exceptions')
require('test/unit')

class Test_Exception_Severities < Test::Unit::TestCase

  include TAGF::Exceptions

  ExceptionClasses	= {
    InvalidSeverity:		SEVERITY.warning,
    BadHistoryFile:		SEVERITY.warning,
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
    @imessage		= 'testing message'
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
      msg		= format('Verifying unmodified ' \
                                 'default severity for %s is %i',
                                 exsym.to_s,
                                 kdefsev)
      assert_equal(klass_o.severity,
                   kdefsev,
                   msg)
    end
  end                           # def test_class_default_severity

  # * Test that changes to the default class severity persist
  def test_class_changed_class_severity_persists
    ExceptionClasses.each do |exsym,kdefsev|
      klass_o		= eval(exsym.to_s)
      klass_i		= nil
      #
      # Pick a different severity level than the default, then set it
      # as the new class default.
      #
      while ((newsev = SEVERITY_LEVELS.sample) != kdefsev)
        nil
      end
      msg		= format('Setting %s class defalt severity ' \
                                 + 'to %i',
                                 exsym.to_s,
                                 newsev)
      assert_nothing_raised(msg) do
        klass_o.severity = newsev
      end
      msg		= format('Verifying %s default severity ' \
                                 + 'changed from %d to %d',
                                 exsym.to_s,
                                 kdefsev,
                                 newsev)
      assert_equal(klass_o.severity,
                   newsev,
                   msg)
    end
  end                           # def test_class_changed_class_severity_persists

  # * Test that new instances inherit the class severity
  def test_instance_inherits_class_default_severity
    ExceptionClasses.each do |exsym,kdefsev|
      klass_o		= eval(exsym.to_s)
      klass_i		= nil
      msg		= format('Instantiating ' \
                                 + '%s.new(%s)',
                                 exsym.to_s,
                                 @imessage.inspect)
      assert_nothing_raised(msg) do
        klass_i		= klass_o.new(@imessage)
      end
      msg		= format('Verifying %s instances ' \
                                 + 'inherit class severity',
                                 exsym.to_s)
      assert_equal(klass_i.severity,
                   klass_o.severity,
                   msg)
    end
  end                           # def test_instance_inherits_class_default_severity

  # * Test that new instances inherit the changed class severity
  def test_instances_inherit_changed_class_severity
    ExceptionClasses.each do |exsym,kdefsev|
      klass_o		= eval(exsym.to_s)
      klass_i		= nil
      #
      # Pick a different severity level than the default, then set it
      # as the new class default.
      #
      while ((newsev = SEVERITY_LEVELS.sample) != kdefsev)
        nil
      end
      msg		= format('Setting %s class severity to %i',
                                 exsym.to_s,
                                 newsev)
      assert_nothing_raised(msg) do
        klass_o.severity = newsev
      end
      klass_i		= nil
      msg		= format('Instantiating ' \
                                 + '%s.new(%s)',
                                 exsym.to_s,
                                 @imessage.inspect)
      assert_nothing_raised(msg) do
        klass_i		= klass_o.new(@imessage)
      end
      msg		= format('Verifying %s instance inherits ' \
                                 + 'new class severity %i',
                                 exsym.to_s,
                                 newsev)
      assert_equal(klass_i.severity,
                   newsev,
                   msg)
    end
  end                           # def test_instances_inherit_changed_class_severity

  # * Test that new instances can have their severity changed
  def test_changing_instance_severity
    ExceptionClasses.each do |exsym,kdefsev|
      klass_o		= eval(exsym.to_s)
      klass_i		= nil
      msg		= format('Instantiating ' \
                                 + '%s.new(%s)',
                                 exsym.to_s,
                                 @imessage.inspect)
      assert_nothing_raised(msg) do
        klass_i		= klass_o.new(@imessage)
      end
      #
      # Pick a different severity level than the default, then set it
      # as the new class default.
      #
      while ((newsev = SEVERITY_LEVELS.sample) != klass_i.severity)
        nil
      end
      msg		= format('Setting %s severity to %i',
                                 exsym.to_s,
                                 newsev)
      assert_nothing_raised(msg) do
        klass_i.severity = newsev
      end
      msg		= format('Verifying new %s instance ' \
                                 + 'severity %i persists',
                                 exsym.to_s,
                                 newsev)
      assert_equal(klass_i.severity,
                   newsev,
                   msg)
    end
  end                           # def test_class_instances_inherit_changed_class_severity

  # * Test that new instances can have their severity changed w/o
  #   affecting class severity
  def test_changing_instance_severity_leaves_class_severity
    ExceptionClasses.each do |exsym,kdefsev|
      klass_o		= eval(exsym.to_s)
      klass_i		= nil
      msg		= format('Instantiating ' \
                                 + '%s.new(%s)',
                                 exsym.to_s,
                                 @imessage.inspect)
      assert_nothing_raised(msg) do
        klass_i		= klass_o.new(@imessage)
      end
      #
      # Pick a different severity level than the default, then set it
      # as the new class default.
      #
      while ((newsev = SEVERITY_LEVELS.sample) != klass_i.severity)
        nil
      end
      msg		= format('Setting %s severity to %i',
                                 exsym.to_s,
                                 newsev)
      assert_nothing_raised(msg) do
        klass_i.severity = newsev
      end
      msg		= format('Verifying new %s instance ' \
                                 + 'severity %i persists',
                                 exsym.to_s,
                                 newsev)
      assert_equal(klass_i.severity,
                   newsev,
                   msg)
      msg		= format('Verifying new %s instance ' \
                                 + 'severity %i persists',
                                 exsym.to_s,
                                 newsev)
      assert_equal(klass_o.severity,
                   kdefsev,
                   msg)
    end
  end                           # def test_changing_instance_severity_leaves_class_severity

  # * Test that passing a string makes that the message
  def test_instances_use_message_from_args
    ExceptionClasses.each do |exsym,kdefsev|
      klass_o		= eval(exsym.to_s)
      klass_i		= nil
      msg		= format('Instantiating ' \
                                 + '%s.new(%s)',
                                 exsym.to_s,
                                 @imessage.inspect)
      assert_nothing_raised(msg) do
        klass_i		= klass_o.new(@imessage)
      end
      msg		= format('Verifying %s instance ' \
                                 + 'uses message %s',
                                 exsym.to_s,
                                 @imessage.inspect)
      assert_equal(klass_i.message,
                   @imessage,
                   msg)
    end
  end                           # def test_instances_use_message_from_args

  # * Test that properly-formatted actuals produce the correct message

  nil
end                             # class Test_Exception_Severities

# Local Variables:
# mode: ruby
# indent-tabs-mode: nil
# eval: (if (intern-soft "fci-mode") (fci-mode 1))
# eval: (auto-fill-mode 1)
# End:
