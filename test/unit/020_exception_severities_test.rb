require('tagf/exceptions')
require('test/unit')

class Test_Exception_Severities < Test::Unit::TestCase

  include TAGF::Exceptions
  include RoUS::TestHelpers

  #
  # Manually maintained, unfortunately.  List of all the exception
  # classes and declaration details we <em>think</em> we've
  # assigned to them.
  #
  ExceptionClassElements = [
    TestElement.new(
      value:		InvalidSeverity,
      severity:		SEVERITY.warning,
      exception_id:	0x001
    ),
    TestElement.new(
      value:		BadHistoryFile,
      severity:		SEVERITY.warning,
      exception_id:	0x002
    ),
    TestElement.new(
      value:		LimitItems,
      severity:		SEVERITY.warning,
      exception_id:	0x101
    ),
    TestElement.new(
      value:		NoLoadFile,
      severity:		SEVERITY.error,
      exception_id:	0x002
    ),
    TestElement.new(
      value:		BadLoadFile,
      severity:		SEVERITY.severe,
      exception_id:	0x003
    ),
    TestElement.new(
      value:		NotExceptional,
      severity:		SEVERITY.error,
      exception_id:	0x004
    ),
    TestElement.new(
      value:		NotGameElement,
      severity:		SEVERITY.severe,
      exception_id:	0x005
    ),
    TestElement.new(
      value:		NoObjectOwner,
      severity:		SEVERITY.severe,
      exception_id:	0x006
    ),
    TestElement.new(
      value:		KeyObjectMismatch,
      severity:		SEVERITY.severe,
      exception_id:	0x007
    ),
    TestElement.new(
      value:		NoGameContext,
      severity:		SEVERITY.severe,
      exception_id:	0x008
    ),
    TestElement.new(
      value:		SettingLocked,
      severity:		SEVERITY.warning,
      exception_id:	0x009
    ),
    TestElement.new(
      value:		ImmovableObject,
      severity:		SEVERITY.error,
      exception_id:	0x00a
    ),
    TestElement.new(
      value:		NotAContainer,
      severity:		SEVERITY.error,
      exception_id:	0x00b
    ),
    TestElement.new(
      value:		AliasRedefinition,
      severity:		SEVERITY.warning,
      exception_id:	0x00c
    ),
    TestElement.new(
      value:		UnscrewingInscrutable,
      severity:		SEVERITY.error,
      exception_id:	0x00d
    ),
    TestElement.new(
      value:		MasterInventory,
      severity:		SEVERITY.error,
      exception_id:	0x00e
    ),
    TestElement.new(
      value:		HasNoInventory,
      severity:		SEVERITY.error,
      exception_id:	0x00f
    ),
    TestElement.new(
      value:		AlreadyHasInventory,
      severity:		SEVERITY.warning,
      exception_id:	0x010
    ),
    TestElement.new(
      value:		AlreadyInInventory,
      severity:		SEVERITY.warning,
      exception_id:	0x011
    ),
    TestElement.new(
      value:		ImmovableElementDestinationError,
      severity: 	SEVERITY.error,
      exception_id:	0x012
    ),
    TestElement.new(
      value:		DuplicateObject,
      severity:		SEVERITY.warning,
      exception_id:	0x013
    ),
    TestElement.new(
      value:		DuplicateItem,
      severity:		SEVERITY.warning,
      exception_id:	0x014
    ),
    TestElement.new(
      value:		DuplicateLocation,
      severity:		SEVERITY.warning,
      exception_id:	0x015
    ),
    TestElement.new(
      value:		UnterminatedHeredoc,
      severity:		SEVERITY.error,
      exception_id:	0x016
    ),
    TestElement.new(
      value:		UnsupportedObject,
      severity:		SEVERITY.fatal,
      exception_id:	0x017
    ),
    TestElement.new(
      value:		UncallableObject,
      severity:		SEVERITY.fatal,
      exception_id:	0x018
    ),
  ]

  #
  # Array of all the exception classes, derived from the list of test
  # elements for them.  Used in instance-test iterations.
  #
  ExceptionClasses	= ExceptionClassElements.map { |te| te.value }

  #
  # Array of exception instances.
  #
  ExceptionElements	= [
    TestElement.new(
      klass:		InvalidSeverity,
      args:		[ false ],
      xmessage:		'invalid severity level: FalseClass:false'
    ),
    TestElement.new(
      klass:		BadHistoryFile,
      args:		[],
      xmessage:		'cannot open/read command history file'
    ),
    TestElement.new(
      klass:		BadHistoryFile,
      args:		[],
      kwargs:		{
        file:		'/dev/null',
      },
      xmessage:		"cannot restore history from /dev/null\n" +
			"\tunknown reason"
    ),
    TestElement.new(
      klass:		BadHistoryFile,
      args:		[],
      kwargs:		{
        exception:	'ENOENT',
      },
      xmessage:		"cannot restore history from <not specified>\n" +
			"\tENOENT"
    ),
    TestElement.new(
      klass:		BadHistoryFile,
      args:		[],
      kwargs:		{
        file:		'/dev/null',
        exception:	'ENOENT',
      },
      xmessage:		"cannot restore history from /dev/null\n" +
			"\tENOENT"
    ),
  ]

  #
  # Executed before each test is invoked.
  #
  def setup
    @imessage		= 'testing message'
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

  # * Test that default class runtime severities match the hardcoded
  #   values
  def test_class_default_severity
    ExceptionClassElements.each do |te|
      klass_o		= te.value
      klass_i		= nil
      kdefsev		= klass_o.severity
      msg		= format('Verifying unmodified ' \
                                 'default severity for %s is %i',
                                 klass_o.to_s,
                                 te.severity)
      assert_equal(klass_o.severity,
                   te.severity,
                   msg)
    end
  end                           # def test_class_default_severity

  # * Test that changes to the default class severity persist
  def test_class_changed_class_severity_persists
    ExceptionClassElements.each do |te|
      klass_o		= te.value
      klass_i		= nil
      kdefsev		= te.severity
      #
      # Pick a different severity level than the default, then set it
      # as the new class default.
      #
      while ((newsev = SEVERITY_LEVELS.sample) != kdefsev)
        nil
      end
      msg		= format('Setting %s class defalt severity ' \
                                 + 'to %i',
                                 klass_o.to_s,
                                 newsev)
      assert_nothing_raised(msg) do
        klass_o.severity = newsev
      end
      msg		= format('Verifying %s default severity ' \
                                 + 'changed from %d to %d',
                                 klass_o.to_s,
                                 kdefsev,
                                 newsev)
      assert_equal(klass_o.severity,
                   newsev,
                   msg)
    end
  end                           # def test_class_changed_class_severity_persists

  # * Test that new instances inherit the class severity
  def test_instance_inherits_class_default_severity
    ExceptionClassElements.each do |te|
      klass_o		= te.value
      klass_i		= nil
      msg		= format('Instantiating ' \
                                 + '%s.new(%s)',
                                 klass_o.to_s,
                                 @imessage.inspect)
      assert_nothing_raised(msg) do
        klass_i		= klass_o.new(@imessage)
      end
      msg		= format('Verifying %s instances ' \
                                 + 'inherit class severity',
                                 klass_o.to_s)
      assert_equal(klass_i.severity,
                   klass_o.severity,
                   msg)
    end
  end                           # def test_instance_inherits_class_default_severity

  # * Test that new instances inherit the changed class severity
  def test_instances_inherit_changed_class_severity
    ExceptionClassElements.each do |te|
      klass_o		= te.value
      klass_i		= nil
      kdefsev		= te.severity
      #
      # Pick a different severity level than the default, then set it
      # as the new class default.
      #
      while ((newsev = SEVERITY_LEVELS.sample) != kdefsev)
        nil
      end
      msg		= format('Setting %s class severity to %i',
                                 klass_o.to_s,
                                 newsev)
      assert_nothing_raised(msg) do
        klass_o.severity = newsev
      end
      klass_i		= nil
      msg		= format('Instantiating ' \
                                 + '%s.new(%s)',
                                 klass_o.to_s,
                                 @imessage.inspect)
      assert_nothing_raised(msg) do
        klass_i		= klass_o.new(@imessage)
      end
      msg		= format('Verifying %s instance inherits ' \
                                 + 'new class severity %i',
                                 klass_o.to_s,
                                 newsev)
      assert_equal(klass_i.severity,
                   newsev,
                   msg)
    end
  end                           # def test_instances_inherit_changed_class_severity

  # * Test that new instances can have their severity changed
  def test_changing_instance_severity
    ExceptionClassElements.each do |te|
      debugger if (te.value.nil?)
      klass_o		= te.value
      klass_i		= nil
      kdefsev		= klass_o.severity
      msg		= format('Instantiating ' \
                                 + '%s.new(%s)',
                                 klass_o.to_s,
                                 @imessage.inspect)
      assert_nothing_raised(msg) do
        klass_i		= klass_o.new(@imessage)
      end
      #
      # Pick a different severity level than the default, then set it
      # as the new class default.
      #
      while ((newsev = SEVERITY_LEVELS.sample) != klass_o.severity)
        nil
      end
      msg		= format('Setting %s severity to %i',
                                 klass_o.to_s,
                                 newsev)
      assert_nothing_raised(msg) do
        klass_o.severity = newsev
      end
      msg		= format('Verifying existing %s instance ' \
                                 + 'severity %i persists',
                                 klass_o.to_s,
                                 newsev)
      assert_equal(klass_i.severity,
                   kdefsev,
                   msg)
    end
  end                           # def test_class_instances_inherit_changed_class_severity

  # * Test that new instances can have their severity changed w/o
  #   affecting class severity
  def test_changing_instance_severity_leaves_class_severity
    ExceptionClassElements.each do |te|
      klass_o		= te.value
      klass_i0		= nil
      klass_i1		= nil
      msg		= format('Instantiating ' \
                                 + '%s.new(%s)',
                                 klass_o.to_s,
                                 @imessage.inspect)
      assert_nothing_raised(msg) do
        klass_i0	= klass_o.new(@imessage)
      end
      #
      # Pick a different severity level than the default, then set it
      # as the new class default.
      #
      while ((newsev = SEVERITY_LEVELS.sample) != klass_o.severity)
        nil
      end
      msg		= format('Setting %s severity to %i',
                                 klass_o.to_s,
                                 newsev)
      assert_nothing_raised(msg) do
        klass_o.severity = newsev
      end
      msg		= format('Verifying new %s instance ' \
                                 + 'inherits new severity %i',
                                 klass_o.to_s,
                                 newsev)
      assert_nothing_raised(msg) do
        klass_i1	= klass_o.new(@imessage)
      end
      assert_equal(klass_i1.severity,
                   newsev,
                   msg)
    end
  end                           # def test_changing_instance_severity_leaves_class_severity

  # * Test that passing a string makes that the message
  def test_instances_use_message_from_args
    ExceptionClassElements.each do |te|
      klass_o		= te.value
      klass_i		= nil
      msg		= format('Instantiating ' \
                                 + '%s.new(%s)',
                                 klass_o.to_s,
                                 @imessage.inspect)
      assert_nothing_raised(msg) do
        klass_i		= klass_o.new(@imessage)
      end
      msg		= format('Verifying %s instance ' \
                                 + 'uses message %s',
                                 klass_o.to_s,
                                 @imessage.inspect)
      assert_equal(klass_i.message,
                   @imessage,
                   msg)
    end
  end                           # def test_instances_use_message_from_args

  # * Test that properly-formatted actuals produce the correct message
  def test_instances_as_intended
    ExceptionElements.each do |te|
      args		= te.respond_to?(:args)   ? te.args   : []
      kwargs		= te.respond_to?(:kwargs) ? te.kwargs : {}
      instance		= te.klass.new(*args, **kwargs)
      msg		= format('%s(%s%s)',
                                 te.klass.to_s,
                                 args.empty? \
                                 ? '' \
                                 : format('*%s,',
                                          args.inspect),
                                 kwargs.empty? \
                                 ? '{}' \
                                 : format('**%s,',
                                          kwargs.inspect))
      assert_equal(instance.message,
                   te.xmessage,
                   msg)
    end
  end                           # def test_instances_as_intended

  nil
end                             # class Test_Exception_Severities

# Local Variables:
# mode: ruby
# indent-tabs-mode: nil
# eval: (if (intern-soft "fci-mode") (fci-mode 1))
# eval: (auto-fill-mode 1)
# End:
