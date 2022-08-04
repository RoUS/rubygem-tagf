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

require('rubygems')
require('set')
require('byebug')
require('binding_of_caller')

# @!macro doc.TAF.module
module TAF

  #
  # Debug options are:
  #
  # * `file`
  # * `include`
  # * `extend`
  # * `require`
  #
  DEBUG_ITEMS           = Set.new(%i[
                                     extend
                                     file
                                     include
                                     require
                                    ])

  #
  def debugging?(item)
    return (DEBUG_ITEMS.include?(item.to_sym)) ? true : false
  end                           # def debugging?(item)
  module_function(:debugging?)

  #
  class << self
    
    #
    def include(mixin_module)
      methsym		= __method__
      methname          = methsym.to_s
      warn('In %s eigenclass .%s' % [self.name, methname])
      ppstring		= ''
      warn('===== %s' % [PP.pp(DEBUG_ITEMS, String.new)])
      if (TAF.debugging?(:include))
        bt              = caller
        calling_file    = bt.first
        warn("%s %s(%s)" % [calling_file, methname, mixin_module.to_s])
      end
      #
      eval_str          = 'self.method(%s).super_method.call(%s)' \
                          % [methsym.inspect, mixin_module.to_s]
      warn('====== %s' % [eval_str])
      binding.of_caller(1).eval(eval_str)
#     super
    end                         # def include(mixin_module)

    #
    def require(path)
      methsym		= __method__
      methname		= methsym.to_s
      if (TAF.debugging?(:require))
        bt              = caller
        calling_file    = bt.first
        warn("%s %s(%s)" % [calling_file, methname, path.inspect])
      end
      #
      eval_str          = 'self.method(%s).super_method.call(%s)' \
                          % [methsym.inspect, path.inspect]
      warn('====== %s' % [eval_str])
      binding.of_caller(1).eval(eval_str)
    end                         # def require(filespec)
    alias_method(:require_relative, :require)

    nil
  end                           # module TAF eigenclass

  nil
end                             # module TAF

warn(__FILE__) if (TAF.debugging?(:file))

# Local Variables:
# mode: ruby
# indent-tabs-mode: nil
# eval: (if (intern-soft "fci-mode") (fci-mode 1))
# End:
