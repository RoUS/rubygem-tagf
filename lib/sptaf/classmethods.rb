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

require('byebug')

# @!macro ModuleDoc
module TAF

  module Thing
    
    module ClassMethods

      def flag(*args)
        args.each do |attrib|
          attrib_s	= attrib.to_s.sub(%r![^_[:alnum:]]*$!, '')
          attrib_q	= "#{attrib_s}?".to_sym
          attrib_set	= "#{attrib_s}=".to_sym
          attrib_bang	= "#{attrib_s}!".to_sym
          attrib	= attrib_s.to_sym
          attrib_ivar	= "@#{attrib_s}".to_sym
          define_method(attrib) {
            return instance_variable_get(attrib_ivar)
          }
          define_method(attrib_q) {
            return instance_variable_get(attrib_ivar) ? true : false
          }
          define_method(attrib_bang) {
            return instance_variable_set(attrib_ivar, true)
          }
          define_method(attrib_set) { |val|
            if (val.kind_of?(Numeric) && val.to_i.zero?)
              val	= false
            end
            return instance_variable_set(attrib_ivar,
                                         val ? true : false)
          }
        end                     # args.each
        nil
      end                       # def flag

      nil
    end                         # module TAF::Thing::ClassMethods

    nil
  end                           # module TAF::Thing

  nil
end                             # module TAF

# Local Variables:
# mode: ruby
# indent-tabs-mode: nil
# eval: (if (intern-soft "fci-mode") (fci-mode 1))
# End:
