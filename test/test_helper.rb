#--
# Copyright © 2022 Ken Coar
#
# Licensed under the Apache License, Version 2.0 (the "License"); you
# may not use this file except in compliance with the License.  You
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

#
# Types of assertions:
#
# assert(truthy-expr[, explanation])
# assert_nil(expr[, explanation])
# assert_equal(expr1, expr2[, explanation])
# assert_not_equal(expr1, expr2[, explanation])
# assert_match(regexp, string-expr[, explanation])
# assert_kind_of(expr, klass[, explanation])
# assert_raise(exception[, explanation]) { block }
# assert_raises(exception[, explanation]) { block }
# assert_respond_to(expr, symbol[, explanation])
# assert_instance_of(klass, instance[, explanation])
#

# Local Variables:
# mode: ruby
# indent-tabs-mode: nil
# eval: (if (intern-soft "fci-mode") (fci-mode 1))
# eval: (auto-fill-mode 1)
# End:
