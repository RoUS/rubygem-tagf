require('test/unit')
require('ostruct')
require('pp')
require('byebug')

#
# Test our custom bits from test/test_helper.rb
#
class Test_Helpers_TestElement < Test::Unit::TestCase

  include(RoUS::TestHelpers)

  def setup

    nil
  end				# def setup

  def teardown

    nil
  end				# def teardown

  def test_001_value_recorded
    te			= TestElement.new(value: 1)
    assert_equal(1,
                 te.value,
                 'te.value matches construction'
                )
  end                           # def test_001_value_recorded

  def test_002_suffix_recorded
    suffix_s		= 'test-suffix'
    te			= TestElement.new(value:  1,
                                          suffix: suffix_s)
    assert_equal(suffix_s,
                 te.suffix,
                 'te.suffix matches construction'
                )
  end                           # def test_002_suffix_recorded

  def test_010_default_render_integer
    te			= TestElement.new(value: 1)
    assert_equal('Integer_1',
                 te.render,
                 'te.render correct default (Integer)'
                )
  end                           # def test_010_default_render_integer

  def test_011_default_render_float
    te			= TestElement.new(value: 1.1)
    assert_equal('Float_1.1',
                 te.render,
                 'te.render correct default (Float)'
                )
  end                           # def test_011_default_render_float

  def test_012_default_render_string
    te			= TestElement.new(value: 'Lorem ipsum')
    assert_equal('String_"Lorem ipsum"',
                 te.render,
                 'te.render correct default (String)'
                )
  end                           # def test_012_default_render_string

  def test_020_exception_on_change_constructor
    te			= TestElement.new(value: 1)
    assert_raise_with_message(RuntimeError,
                              %r!test value has already been set!,
                              'expect exception when changing value'
                             ) do
      te.value		= 2
    end
  end                           # def test_020_exception_on_change_constructor

  def test_999_exception_on_change_manual
    te			= TestElement.new
    te.value		= 1
    assert_raise_with_message(RuntimeError,
                              %r!test value has already been set!,
                              'expect exception when changing value'
                             ) do
      te.value		= 2
    end
  end                           # def test_021_exception_on_change_manual

  def test_040_instance_attribute
    te1			= TestElement.new(value: 1)
    te1.test_attr	= 'te1.test_attr'
    assert_equal('te1.test_attr',
                 te1.test_attr,
                 'setting dynamic instance variable')
  end                           # def test_040_instance_attribute

  def test_041_instance_attribute_only
    te1			= TestElement.new(value: 1)
    te2			= TestElement.new(value: 2)
    te1.test_attr	= 'te1.test_attr'
    assert_raise(NoMethodError) do
      test		= te2.test_attr
    end
  end                           # def test_040_instance_attribute

  def test_042_instance_attribute_distinct
    te1			= TestElement.new(value: 1)
    te2			= TestElement.new(value: 2)
    te1.test_attr	= 'te1.test_attr'
    te2.test_attr	= 'te2.test_attr'
    assert_equal('te1.test_attr',
                 te1.test_attr)
    assert_equal('te2.test_attr',
                 te2.test_attr)
  end                           # def test_040_instance_attribute

  def test_050_klass_attribute
    te1			= TestElement.new(value:	1,
                                          :attrscope => :class)
    te1.test_attr	= 'te1.test_attr'
    assert_equal('te1.test_attr',
                 te1.test_attr,
                 'accessing dynamic klass variable from 1st instance')
    te2			= TestElement.new(value:	1)
    assert_equal('te1.test_attr',
                 te2.test_attr,
                 'accessing dynamic klass variable from 2nd instance')
    assert_equal('te1.test_attr',
                 TestElement.test_attr,
                 'accessing dynamic klass variable from class')
  end                           # def test_050_klass_attribute

  nil
end				# class Test_Helpers_TestElement

# Local Variables:
# mode: ruby
# indent-tabs-mode: nil
# eval: (if (intern-soft "fci-mode") (fci-mode 1))
# eval: (auto-fill-mode 1)
# End:
