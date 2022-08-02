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
                                    ])

  #
  def debugging?(item)
    return (DEBUG_ITEMS.include?(item.to_sym)) ? true : false
  end                           # def debugging?(item)
  module_function(:debugging?)

  #
  class << self
    
    #
    def mixin(mixin_module)
      kmethname         = 'include'
      if (TAF.debugging?(:include))
        bt              = caller
        calling_file    = bt.first.sub(%r!:.*!, '')
        warn("%s %s(%s)" % [calling_file, kmethname, mixin_module.to_s])
      end
      #
      # @todo
      #   Okey, this is broken; it just calls us again.  Maybe
      #   __method__.super_method?
      #
      eval_str          = "#{kmethname}(#{mixin_module.to_s})"
      binding.of_caller(1).eval(eval_str)
#     super
    end                         # def mixin(mixin_module)

    #
    def require_file(path)
      kmethname         = __method__.to_s.sub(%r!_file!, '')
      if (TAF.debugging?(:require))
        bt              = caller
        calling_file    = bt.first.sub(%r!:.*!, '')
        warn("%s %s('%s')" % [calling_file, kmethname, path.to_s])
      end
      #
      # @todo
      #   Okey, this is broken; it just calls us again.  Maybe
      #   __method__.super_method?
      #
      binding.of_caller(1).eval("#{kmethname}('#{path}')")
    end                         # def require_file(filespec)
    alias_method(:require_file_relative, :require_file)

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
