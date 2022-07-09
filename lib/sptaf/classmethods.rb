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

require('ostruct')
require('byebug')

# @!macro ModuleDoc
module TAF

  module ClassMethods

    module Thing

      def _decompose_attrib(attrib_p, default=nil)
        strval		= attrib_p.to_s.sub(%r![^_[:alnum:]]*$!, '')
        pieces		= OpenStruct.new(
          default: 	default,
          str:		strval,
          getter:	strval.to_sym,
          setter:	"#{strval}=".to_sym,
          query:	"#{strval}?".to_sym,
          bang:		"#{strval}!".to_sym,
          ivar:		"@#{strval}".to_sym
        )
        return pieces
      end
      protected(:_decompose_attrib)

      def _inivaluate_attrib(default, *args, **kwargs)
        unless ((argc = args.count).zero?)
          #
          # Turn any bare attributes into hashes with the appropriate
          # default setting.
          #
          defaults	= [default] * argc
          nmargs	= args.zip(defaults).map { |ary| Hash[*ary] }
          nmargs	= nmargs.reduce(&:merge)
          #
          # Do it in the `nmargs.merge(kwargs)` order so any
          # attributes that <em>were</em> given initial value override
          # bare ones of the same name.
          #
          kwargs	= nmargs.merge(kwargs)
        end
        return kwargs
      end
      protected(:_inivaluate_attrib)

      def flag(*args, **kwargs)
        kwargs		= _inivaluate_attrib(false, *args, **kwargs)
        kwargs.each do |attrib,default|
          default	= default ? true : false
          f_attr	= _decompose_attrib(attrib, default)
          define_method(f_attr.getter) {
            ival	= instance_variable_get(f_attr.ivar)
            if (ival.nil?)
              ival	= f_attr.default
              instance_variable_set(f_attr.ivar, ival)
            end
            return ival
          }
          define_method(f_attr.query) {
            return instance_variable_get(f_attr.ivar) ? true : false
          }
          define_method(f_attr.bang) {
            return instance_variable_set(f_attr.ivar, true)
          }
          define_method(f_attr.setter) { |val|
            if (val.kind_of?(Numeric) && val.to_i.zero?)
              val	= false
            end
            return instance_variable_set(f_attr.ivar,
                                         val ? true : false)
          }
        end                     # args.each
        nil
      end                       # def flag

      def iattr_accessor(*args, **kwargs)
        attrmethod	= __method__.to_s
        kwargs		= _inivaluate_attrib(0, *args, **kwargs)
        kwargs.each do |attrib,default|
          f_attr	= _decompose_attrib(attrib, default)
          unless (f_attr.default.kind_of?(Integer))
            raise(TypeError,
                  "attribute '#{f_attr.str}' " \
                  + 'can only have integer values')
          end
          unless (attrmethod =~ %r!_writer$!)
            define_method(f_attr.getter) {
              ival	= instance_variable_get(f_attr.ivar)
              if (ival.nil?)
                ival	= f_attr.default
                instance_variable_set(f_attr.ivar, ival)
              end
              return ival
            }
          end
          unless (attrmethod =~ %r!_reader$!)
            define_method(f_attr.setter) { |val|
              unless (val.kind_of?(Integer))
                raise(TypeError,
                      "attribute '#{f_attr.str}' " \
                      + 'can only have integer values')
              end
              return instance_variable_set(f_attr.ivar, val)
            }
          end
        end                     # args.each

        nil
      end                       # def iattr_accessor
      alias_method(:iattr_reader, :iattr_accessor)
      alias_method(:iattr_writer, :iattr_accessor)

      nil
    end                         # module TAF::ClassMethods::Thing

    nil
  end                           # module TAF::ClassMethods

  nil
end                             # module TAF

# Local Variables:
# mode: ruby
# indent-tabs-mode: nil
# eval: (if (intern-soft "fci-mode") (fci-mode 1))
# End:
