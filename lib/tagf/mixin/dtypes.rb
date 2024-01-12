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

#require_relative('debugging')
#warn(__FILE__) if (TAGF.debugging?(:file))

require_relative('universal')
require('byebug')

# @!macro doc.TAGF.module
module TAGF

  module Mixin

    # @!macro doc.TAGF.Mixin.DTypes.module
    module DTypes

      include(Mixin::UniversalMethods)
      #
      # Ensure that the definitions in this module also appear in its
      # eigenclass as 'class' methods.
      #
      extend(self)

      #
#      include(TAGF::Mixin::UniversalMethods)

      #
      include(Contracts::Core)


      # @!macro doc.TAGF.classmethod.flag.declare
      def flag(*args, **kwargs)
        kwargs		= _inivaluate_args(false,
                                           *args,
                                           **kwargs) { |v|
          truthify(v)
        }
        kwargs.each do |attrib,default|
          default	= default ? true : false
          f_attr	= decompose_attrib(attrib, default)
          #
          # Define the getter method.  We don't just use {attr_reader}
          # because we want to set an initial value on the first read.
          #
          define_method(f_attr.getter) {
            ival	= instance_variable_get(f_attr.ivar)
            if (ival.nil?)
              ival	= truthify(f_attr.default)
              instance_variable_set(f_attr.ivar, ival)
            end
            return ival
          }
          #
          # Now the query method, which is basically a copy of the
          # getter method.
          #
          alias_method(f_attr.query, f_attr.getter)
=begin
          define_method(f_attr.query) {
            return instance_variable_get(f_attr.ivar) ? true : false
          }
=end
          define_method(f_attr.bang) {
            return instance_variable_set(f_attr.ivar, true)
          }
          #
          # Now define the setter method, which will only store a
          # Boolean value, possibly coerced from the input argument.
          #
          define_method(f_attr.setter) { |val|
            return instance_variable_set(f_attr.ivar, truthify(val))
          }
        end                     # args.each

        nil
      end                       # def flag

      #   @overload $1
      #     @return [Float]
      #       the current value of `$1`.
      #   @overload $1=(arg)
      #     @param [Float] value
      #     @raise [TypeError]
      #       `attribute '$1' can only have float values or something
      #       coercible`
      #     @return [Float]
      #       the value of `value` that was passed in.
      #

      # @todo
      #   Add the ability for attributes to have their own validation
      #   blocks.
      #
      # @!macro doc.TAGF.classmethod.float_accessor.declare
      def float_accessor(*args, **kwargs)
        attrmethod	= __method__.to_s
        kwargs		= _inivaluate_args(0.0, *args, **kwargs)
        kwargs.each do |attrib,default|
          f_attr	= decompose_attrib(attrib, default)
          unless (f_attr.default.kind_of?(Float))
            raise(TypeError,
                  "attribute '#{f_attr.str}' " \
                  + 'can only have float values')
          end
          unless (attrmethod =~ %r!_writer$!)
            define_method(f_attr.getter) {
              ival	= instance_variable_get(f_attr.ivar)
              if (ival.nil?)
                ival	= f_attr.default || Float(0.0)
                instance_variable_set(f_attr.ivar, ival)
              end
              return ival
            }
          end
          unless (attrmethod =~ %r!_reader$!)
            define_method(f_attr.setter) { |val|
              unless (val.kind_of?(Float))
                raise(TypeError,
                      "attribute '#{f_attr.str}' " \
                      + 'can only have float values')
              end
              return instance_variable_set(f_attr.ivar, val)
            }
          end
        end                     # kwargs.each

        nil
      end                       # def float_accessor
      alias_method(:float_reader, :float_accessor)
      alias_method(:float_writer, :float_accessor)

      # @!macro doc.TAGF.classmethod.file_accessor.declare
      def file_accessor(*args, **kwargs)
        attrmethod	= __method__.to_s
        kwargs		= _inivaluate_args(nil, *args, **kwargs)
        kwargs.each do |attrib,default|
          f_attr	= decompose_attrib(attrib, default)
          #
          # Validate the default value.
          #
          unless (f_attr.default.nil? \
                  || f_attr.default.kind_of?(IO))
            raise(TypeError,
                  "attribute '#{f_attr.str}' " \
                  + 'can only be nil or an IO')
          end
          #
          # Declare the accessor/getter method.
          #
          unless (attrmethod =~ %r!_writer$!)
            define_method(f_attr.getter) {
              ival	= instance_variable_get(f_attr.ivar)
              if (ival.nil?)
                ival	= f_attr.default || nil
                instance_variable_set(f_attr.ivar, ival)
              end
              return ival
            }
          end
          #
          # Now define the setter method.  This is the one that does
          # the runtime validation.
          #
          unless (attrmethod =~ %r!_reader$!)
            define_method(f_attr.setter) { |val|
              unless ([ NilClass, IO ].include?(val.class))
                raise(TypeError,
                      format("attribute '%s' " \
                             + 'can only be nil or an IO; ' \
                             + '%s:%s is invalid',
                             f_attr.str,
                             val.class.name,
                             val.inspect))
              end
              return instance_variable_set(f_attr.ivar, val)
            }
          end
        end                     # kwargs.each

        nil
      end                       # def file_accessor(*args)
      alias_method(:file_reader, :file_accessor)
      alias_method(:file_writer, :file_accessor)

      # @!macro doc.TAGF.classmethod.int_accessor.declare
      def int_accessor(*args, **kwargs)
        attrmethod	= __method__.to_s
        kwargs		= _inivaluate_args(0, *args, **kwargs)
        kwargs.each do |attrib,default|
          f_attr	= decompose_attrib(attrib, default)
          unless (f_attr.default.kind_of?(Integer))
            raise(TypeError,
                  "attribute '#{f_attr.str}' " \
                  + 'can only have integer values')
          end
          unless (attrmethod =~ %r!_writer$!)
            define_method(f_attr.getter) {
              ival	= instance_variable_get(f_attr.ivar)
              if (ival.nil?)
                ival	= f_attr.default || Integer(0)
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
        end                     # kwargs.each

        nil
      end                       # def int_accessor
      alias_method(:int_reader, :int_accessor)
      alias_method(:int_writer, :int_accessor)

      nil
    end                         # module TAGF::Mixin::DTypes

    nil
  end                           # module TAGF::Mixin

  nil
end                             # module TAGF

# Local Variables:
# mode: ruby
# indent-tabs-mode: nil
# eval: (if (intern-soft "fci-mode") (fci-mode 1))
# eval: (auto-fill-mode 1)
# End:
