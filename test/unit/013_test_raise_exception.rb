require('test/unit')
require('ostruct')
require('pp')
require('byebug')

require('tagf/exceptions')
require('tagf/mixin/universal')

#
# Test our custom exception reporting method.
#
class Test_Raise_Exception < Test::Unit::TestCase

  include(RoUS::TestHelpers)
  include(TAGF::Mixin::UniversalMethods)
  include(TAGF::Exceptions)

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
  # * raise_exception(String)
  # * raise_exception(exc_instance)
  # * raise_exception(exc_class)
  # * raise_exception(Proc)
  # * raise_exception(anything-else)
  #
  # And all of the above with args and kwargs
  #

  def test_010_raise_exception_string
    bt_base		= nil
    bt_exc		= nil
    #
    # Raise an exception (and rescue it) so we can get the unedited
    # backtrace.
    #
    begin
      raise(RuntimeError.new(Exception_Text))
    rescue RuntimeError => exc
      bt_base		= exc.backtrace
    end
    exc = assert_raise_with_message(RuntimeError,
                                    Exception_Text,
                                    'raise_exception(String)') do
      raise_exception(Exception_Text)
    end
  end                           # test_010_raise_exception_string

  def test_020_raise_exception_instance
    bt_base		= nil
    bt_exc		= nil
    #
    # Raise an exception (and rescue it) so we can get the unedited
    # backtrace.
    #
    begin
      raise(RuntimeError.new(Exception_Text))
    rescue RuntimeError => exc
      bt_base		= exc.backtrace
    end
    exc_object		= IOError.new(Exception_Text)
    exc = assert_raise_with_message(IOError,
                                    %r!#{Exception_Text}!,
                                    'raise_exception(exc_object)') do
      raise_exception(exc_object)
    end
  end                           # test_020_raise_exception_instance

  def test_030_raise_exception_class
    bt_base		= nil
    bt_exc		= nil
    #
    # Raise an exception (and rescue it) so we can get the unedited
    # backtrace.
    #
    begin
      raise(RuntimeError.new(Exception_Text))
    rescue RuntimeError => exc
      bt_base		= exc.backtrace
    end
    exc_klass		= Errno::ENOENT
    args		= [ Exception_Text ]
    exc = assert_raise_with_message(Errno::ENOENT,
                                    %r!#{Exception_Text}!,
                                    'raise_exception(exc_klass,text)') do
      raise_exception(exc_klass, *args)
    end
  end                           # test_030_raise_exception_class

  def test_040_raise_exception_proc
    bt_base		= nil
    bt_exc		= nil
    #
    # Raise an exception (and rescue it) so we can get the unedited
    # backtrace.
    #
    begin
      raise(RuntimeError.new(Exception_Text))
    rescue RuntimeError => exc
      bt_base		= exc.backtrace
    end
    exc_proc		= Proc.new { |*args|
      FiberError.new(*args)
    }
    args		= [ Exception_Text ]
    exc = assert_raise_with_message(FiberError,
                                    %r!#{Exception_Text}!,
                                    'raise_exception(exc_proc,text)') do
      raise_exception(exc_proc, *args)
    end
  end                           # test_040_raise_exception_proc

  def test_050_raise_exception_bogus
    bt_base		= nil
    bt_exc		= nil
    #
    # Raise an exception (and rescue it) so we can get the unedited
    # backtrace.
    #
    begin
      raise(RuntimeError.new(Exception_Text))
    rescue RuntimeError => exc
      bt_base		= exc.backtrace
    end
    exc_bogus		= Object
    args		= [ Exception_Text ]
    msg			= format('not an exception or ' +
                                 'exception class: %s:%s',
                                 exc_bogus.class.name,
                                 exc_bogus.inspect)
    exc = assert_raise_with_message(NotExceptional,
                                    msg,
                                    'raise_exception(exc_bogus,text)') do
      raise_exception(exc_bogus, *args)
    end
  end                           # test_050_raise_exception_bogus


  nil
end				# class Test_UniversalMethods

# Local Variables:
# mode: ruby
# indent-tabs-mode: nil
# eval: (if (intern-soft "fci-mode") (fci-mode 1))
# eval: (auto-fill-mode 1)
# End:
