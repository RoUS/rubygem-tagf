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

#require('tagf/debugging')
#warn(__FILE__) if (TAGF.debugging?(:file))

require('tagf/mixin/universal')
require('byebug')

# @!macro doc.TAGF.module
module TAGF

  module Boolean ; end

  TrueClass.include(TAGF::Boolean)
  FalseClass.include(TAGF::Boolean)

  # @!macro doc.TAGF.Mixin.module
  module Mixin

    # @!macro doc.TAGF.Mixin.DTypes.module
    module DTypes

      # Eigenclass declarations for the TAGF::Mixin::DTypes module.
      # This is where 'magic' methods like #included and #extended are
      # declared, which are invoked when the module itself is, well,
      # included or extended in a class or module.
      class << self

        # @!method included(klass)
        # This method is invoked every time the `TAGF::Mixin::DTypes`
        # module is included in a class or other module.  It makes
        # sure that the instance-type declarations go into the
        # including scope, and the class-type declarations go into its
        # eigenclass.
        # @return [void]
        def included(klass)
          klass.include(TAGF::Mixin::InstanceTypes)
          klass.extend(TAGF::Mixin::ClassTypes)
          klass.extend(TAGF::Mixin::DTypes)
          return nil
        end                     # def included(klass)

        # @!method extended(klass)
        # This method is invoked every time the `TAGF::Mixin::DTypes`
        # module is included in a class or other module.  It makes
        # sure that the instance-type declarations go into the
        # including scope, and the class-type declarations go into its
        # eigenclass.
        # @return [void]
        def extended(klass)
          klass.include(TAGF::Mixin::InstanceTypes)
          klass.extend(TAGF::Mixin::ClassTypes)
          return nil
        end                     # def extended(klass)

        nil
      end                       # module DTypes eigenclass

      nil
    end                         # module TAGF::Mixin::DTypes

    # Module defining datatypes and classes that should be included
    # and available at the instance level.
    module InstanceTypes

      # Very simple class used to identify strings used specifically
      # as Element ID (EID) values.
      class EID < String ; end

      # Class describing an entry in the `Loadable_Fields` constant
      # arrays.  Using an object rather than just a simple string
      # allows metadata to be stored; in the first example, some of
      # the fields are used to automatically construct aspects of
      # command-line tools.
      class FieldDef

        # List of the attributes for a loadable field
        AttrList	= %i[
          name
          shortname
          datatype
          description
          internal
        ]

        # Add an attribute for each of the named fields.
        AttrList.each do |attr_sym|
          attr_accessor(attr_sym)
        end

        # @!attribute [r] list?
        # Originally added because the Cri gem doesn't turn
        # multi-value options like `-opt=a,b,c -opt=d` into
        # `["a","b","c","d"]` but leaves it as `["a,b,c","d"]`, and we
        # want to easily detect this in case it needs to be fixed.
        #
        # However, it may have other uses in the future.
        #
        # @return [If]
        #   `true` if the #datatype field is either an array, or the
        #   Array class itself.
        def list?
          result	= (self.datatype.kind_of?(Array) ||
                           (self.datatype == Array))
          return result
        end                     # def list?

        # Constructor for a FieldDef instance.
        #
        # @params [Hash<Symbol=>Any>] kwargs
        # @option kwargs [String]	name
        #   The (string) name of the attribute in the object, and the
        #   long-form option on the shell command line.
        # @option kwargs [String]	shortname
        #   The short-form (single letter) option for the command
        #   line.  `nil` means no short form.
        # @option kwargs [Class]	datatype
        #   Primarily for use with the command-line interface;
        #   `Boolean` gets it exposed as a flag, otherwise its a
        #   valued option.  By default, command-line options require
        #   values.
        # @option kwargs [String]	description
        #   Short description for the command-line interface.
        # @option kwargs [Boolean]	internal
        #   `true` to keep the attribute from being exposed on the
        #   command-line.
        def initialize(**kwargs)
          AttrList.each do |attr_sym|
            setter	= format('%s=', attr_sym.to_s).to_sym
            self.send(setter, kwargs[attr_sym])
          end
        end                     # def initialize(**kwargs)

        nil
      end                       # class FieldDef

      nil
    end                         # module TAGF::Mixin::InstanceTypes

    # Module declaring types and classes that should be declared at
    # the eigenclass level, making them available at the class/module
    # declaration scope but not inside instances.
    module ClassTypes

      #
      include(Mixin::UniversalMethods)
      #
      # Ensure that the definitions in this module also appear in its
      # eigenclass as 'class' methods.
      #
      extend(self)

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
    end                         # module TAGF::Mixin::ClassTypes

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
