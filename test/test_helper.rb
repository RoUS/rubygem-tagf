#--
# Copyright © 2022 Ken Coar
#
# Licensed under the Apache License, Version 2.0 (the "License"); you
# may not use this file except in compliance with the License.	You
# may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or
# implied.  See the License for the specific language governing
# permissions and limitations under the License.
#++
# frozen_string_literal: true

$LOAD_PATH.unshift(File.expand_path('../lib', __dir__))
require('tagf')

require('test-unit')

FixturesDir		= File.join(Pathname(__FILE__).dirname,
                                    'fixtures')

# @!macro doc.TAGF.module
module TAGF

  #
  # Types of assertions (see Test::Unit::Assertions):
  #
  # flunk(message="Flunked")
  #   Always fails.
  #
  # assert_block(message='assert_block failed.')
  #   @example Example Custom Assertion
  #
  #	def deny(boolean, message=nil)
  #	  message = build_message(message, '<?> is not false or nil.',
  #				  boolean)
  #	  assert_block(message) do
  #	    not boolean
  #	  end
  #	end
  #
  # assert(object=NOT_SPECIFIED, message=nil, &block)
  #
  # assert_equal(expected, actual, message=nil)
  #
  # assert_raise(*args, &block)
  #
  # assert_raise_with_message(expected_exception_class,
  #			      expected_message,
  #			      message=nil,
  #			      &block)
  #   `expected_message` can be a String or a Regexp.
  #
  # assert_raise_kind_of(*args, &block)
  #
  # assert_instance_of(klass, object, message=nil)
  #
  # assert_not_instance_of(klass, object, message=nil)
  #
  # assert_nil(object, message=nil)
  #
  # assert_kind_of(klass, object, message=nil)
  #
  # assert_not_kind_of(klass, object, message=nil)
  #
  # assert_respond_to(object, method, message=nil)
  #
  # assert_not_respond_to(object, method, message=nil)
  #
  # assert_match(pattern, string, message=nil)
  #
  # assert_same(expected, actual, message=nil)
  #
  # assert_operator(object1, operator, object2, message=nil)
  #
  # assert_not_operator(object1, operator, object2, message=nil)
  #
  # assert_nothing_raised(*args)
  #
  # assert_not_same(expected, actual, message=nil)
  #
  # assert_not_equal(expected, actual, message=nil)
  #
  # assert_not_nil(object, message=nil)
  #
  # assert_not_match(pattern, string, message=nil)
  #
  # assert_no_match(regexp, string, message="")
  #
  # assert_throw(expected_object, message=nil, &proc)
  #   @example
  #	assert_throw(:done) do
  #	  throw(:done)
  #	end
  #
  # assert_nothing_thrown(message=nil, &proc)
  #
  # assert_in_delta(expected_float,
  #		    actual_float,
  #		    delta=0.001,
  #		    message="")
  #   Passes if `expected_float` and `actual_float` are equal
  #   within `delta` tolerance.
  #
  #   @example
  #	assert_in_delta 0.05, (50000.0 / 10**6), 0.00001
  #
  # assert_not_in_delta(expected_float,
  #			actual_float,
  #			delta=0.001,
  #			message="")
  #
  # assert_in_epsilon(expected_float,
  #		      actual_float,
  #		      epsilon=0.001,
  #		      message="")
  #   Passes if `expected_float` and `actual_float` are equal
  #   within `epsilon` relative error of `expected_float`.
  #
  #   @example
  #	assert_in_epsilon(10000.0, 9900.0, 0.1) # -> pass
  #	assert_in_epsilon(10000.0, 9899.0, 0.1) # -> fail
  #
  # assert_not_in_epsilon(expected_float,
  #			  actual_float,
  #                       epsilon=0.001,
  #                       message='')
  #
  # assert_send(send_array, message=nil)
  #   Passes if the method `__send__` returns not false nor nil.
  #
  #   `send_array` is composed of:
  #   * A receiver
  #   * A method
  #   * Arguments to the method
  #
  #   @example
  #	assert_send([[1, 2], :member?, 1]) # -> pass
  #	assert_send([[1, 2], :member?, 4]) # -> fail
  #
  # assert_not_send(send_array, message=nil)
  #
  # assert_boolean(actual, message=nil)
  #   Passes if `actual` is a boolean value.
  #
  #   @example
  #	assert_boolean(true) # -> pass
  #	assert_boolean(nil)  # -> fail
  #
  # assert_true(actual, message=nil)
  #
  # assert_false(actual, message=nil)
  #
  # assert_compare(expected, operator, actual, message=nil)
  #   Passes if expression "`expected` `operator` `actual`" is not
  #   false nor nil.
  #
  #   @example
  #     assert_compare(1, "<", 10)  # -> pass
  #     assert_compare(1, ">=", 10) # -> fail
  #
  # assert_fail_assertion(message=nil)
  #   Passes if assertion is failed in block.
  #
  #   @example
  #     assert_fail_assertion {assert_equal("A", "B")}  # -> pass
  #     assert_fail_assertion {assert_equal("A", "A")}  # -> fail
  #
  # assert_raise_message(expected, message=nil)
  #   Passes if an exception is raised in block and its message is
  #   `expected`.
  #
  #   @example
  #     assert_raise_message("exception") {raise "exception"}  # -> pass
  #     assert_raise_message(/exc/i) {raise "exception"}       # -> pass
  #     assert_raise_message("exception") {raise "EXCEPTION"}  # -> fail
  #     assert_raise_message("exception") {}                   # -> fail
  #
  # assert_const_defined(object, constant_name, message=nil)
  #   Passes if `object`.const_defined?(`constant_name`)
  #
  #   @example
  #     assert_const_defined(Test, :Unit)          # -> pass
  #     assert_const_defined(Object, :Nonexistent) # -> fail
  #
  # assert_not_const_defined(object, constant_name, message=nil)
  #
  # assert_predicate(object, predicate, message=nil)
  #   Passes if `object`.`predicate` is not false nor nil.
  #
  #   @example
  #     assert_predicate([], :empty?)  # -> pass
  #     assert_predicate([1], :empty?) # -> fail
  #
  # assert_not_predicate(object, predicate, message=nil)
  #
  # assert_alias_method(object, alias_name, original_name, message=nil)
  #   Passes if `object`#`alias_name` is an alias method of
  #   `object`#`original_name`.
  #
  #   @example
  #     assert_alias_method([], :length, :size)  # -> pass
  #     assert_alias_method([], :size, :length)  # -> pass
  #     assert_alias_method([], :each, :size)    # -> fail
  #
  # assert_path_exist(path, message=nil)
  #   Passes if filesystem `path` exists.
  #
  #   @example
  #     assert_path_exist("/tmp")          # -> pass
  #     assert_path_exist("/bin/sh")       # -> pass
  #    assert_path_exist("/nonexistent")  # -> fail
  #
  # assert_path_not_exist(path, message=nil)
  #
  # assert_include(collection, object, message=nil)
  #   Passes if `collection` includes `object`.
  #
  #   @example
  #     assert_include([1, 10], 1)            # -> pass
  #     assert_include(1..10, 5)              # -> pass
  #     assert_include([1, 10], 5)            # -> fail
  #     assert_include(1..10, 20)             # -> fail
  #
  # assert_not_include(collection, object, message=nil)
  #
  # assert_empty(object, message=nil)
  #   Passes if `object` is empty.
  #
  #   @example
  #     assert_empty("")                       # -> pass
  #     assert_empty([])                       # -> pass
  #     assert_empty({})                       # -> pass
  #     assert_empty(" ")                      # -> fail
  #     assert_empty([nil])                    # -> fail
  #     assert_empty({1 => 2})                 # -> fail
  #
  # assert_not_empty(object, message=nil)
  #
  # assert_all(collection, message=nil)
  #   @overload assert_all(collection, message=nil, &block)
  #
  #     Asserts that all `block.call(item)` where `item` is each
  #     item in `collection` are not false nor nil.
  #
  #     If `collection` is empty, this assertion is always passed
  #     with any `block`.
  #
  #     @example Pass patterns
  #       assert_all([1, 2, 3]) {|item| item > 0} # => pass
  #       assert_all([1, 2, 3], &:positive?)      # => pass
  #       assert_all([]) {|item| false}           # => pass
  #
  #     @example Failure pattern
  #       assert_all([0, 1, 2], &:zero?) # => failure
  #
  #     @param [#each] collection The check target.
  #     @param [String] message The additional user message. It is
  #       showed when the assertion is failed.
  #     @yield [Object] Give each item in `collection` to the block.
  #     @yieldreturn [Object] The checked object.
  #     @return [void]
  #
  # assert_nothing_leaked_memory(max_increasable_size,
  #                              target=:physical,
  #                              message=nil)
  #   @overload assert_nothing_leaked_memory(max_increasable_size,
  #                                          target=:physical,
  #                                          message=nil,
  #                                          &block)
  #
  #     Asserts that increased memory usage by `block.call` is less
  #     than `max_increasable_size`. `GC.start` is called before and
  #     after `block.call`.
  #
  #     This assertion may be fragile. Because memory usage is depends
  #     on the current Ruby process's memory usage. Launching a new
  #     Ruby process for this will produce more stable result but we
  #     need to specify target code as `String` instead of block for
  #     the approach. We choose easy to write API approach rather than
  #     more stable result approach for this case.
  #
  #     @example Pass pattern
  #       require "objspace"
  #       size_per_object = ObjectSpace.memsize_of("Hello")
  #       # If memory isn't leaked, physical memory of almost created
  #       # objects (1000 - 10 objects) must be freed.
  #       assert_nothing_leaked_memory(size_per_object * 10) do
  #         1_000.times do
  #           "Hello".dup
  #         end
  #       end # => pass
  #
  #     @example Failure pattern
  #       require "objspace"
  #       size_per_object = ObjectSpace.memsize_of("Hello")
  #       strings = []
  #       assert_nothing_leaked_memory(size_per_object * 10) do
  #         10_000.times do
  #           # Created objects aren't GC-ed because they are
  #           # referred.
  #           strings << "Hello".dup
  #         end
  #       end # => failure
  #
  #     @param target [:physical, :virtual] which memory usage is
  #       used for comparing. `:physical` means physical memory usage
  #       also known as Resident Set Size (RSS). `:virtual` means
  #       virtual memory usage.
  #     @yield [] do anything you want to measure memory usage
  #       in the block.
  #     @yieldreturn [void]
  #     @return [void]
  #
  class TestUnitAssertionsDoc ; end

  nil
end				# module TAGF

# Local Variables:
# mode: ruby
# indent-tabs-mode: nil
# eval: (if (intern-soft "fci-mode") (fci-mode 1))
# eval: (auto-fill-mode 1)
# End:
