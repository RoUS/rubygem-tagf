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

require_relative('../sptaf')
require_relative('exceptions')
require('ostruct')
require('byebug')

# @!macro doc.TAF.module
module TAF

  #
  # Define class methods and constants that will be added to all
  # modules and classes in the TAF namespace.  These definitions live
  # in the modules' and class' eigenclasses (<em>a.k.a.</em>
  # 'singleton classes').  Things like the `extended` and `included`
  # metamethods live in the eigenclass, and class-level methods like
  # `attr_accessor` are defined in the eigenclass as well.
  #
  module ClassMethods

    include(::TAF::Exceptions)

    # @!macro doc.TAF.module.classmethod.included
    def included(klass)
      whoami		= '%s eigenclass.%s' \
                          % [self.name, __method__.to_s]
      warn('%s called for %s' \
           % [whoami, klass.name])
      [ TAF::ClassMethods ].each do |xmodule|
        warn('%s extending %s with %s' \
             % [whoami, klass.name, xmodule.name])
        klass.extend(xmodule)
      end
      super
      return nil
    end                         # def included(klass)

    #
    def _decompose_attrib(attrib_p, default=nil)
      strval		= attrib_p.to_s.sub(%r![^_[:alnum:]]*$!, '')
      pieces		= OpenStruct.new(
        default: 	default,
        str:		strval,
        getter:		strval.to_sym,
        setter:		"#{strval}=".to_sym,
        query:		"#{strval}?".to_sym,
        bang:		"#{strval}!".to_sym,
        ivar:		"@#{strval}".to_sym
      )
      return pieces
    end                         # def _decompose_attrib
    protected(:_decompose_attrib)

    #
    def _inivaluate_attrib(default, *args, **kwargs)
      unless ((argc = args.count).zero?)
        #
        # Turn any bare attributes into hashes with the appropriate
        # default setting.
        #
        defaults	= [default] * argc
        nmargs		= args.zip(defaults).map { |ary| Hash[*ary] }
        nmargs		= nmargs.reduce(&:merge)
        #
        # Do it in the `nmargs.merge(kwargs)` order so any
        # attributes that <em>were</em> given initial value override
        # bare ones of the same name.
        #
        kwargs		= nmargs.merge(kwargs)
      end
      return kwargs
    end                         # def _inivaluate_attrib
    protected(:_inivaluate_attrib)

    # Declares the specified symbols as accessors for Boolean values.
    # For each symbol, four (4) methods are defined:
    #
    #  * <em>`symbol`</em> -- returns the current attribute value.
    #  * <em>`symbol=`</em> --
    #    sets the attribute to the 'truthy' interpretation of the
    #    argument.
    #  * <em>`symbol?`</em> --
    #    returns `true` or `false` according to the attribute's value.
    #    <em>Equivalent to the </em>`symbol`<em> method above.</em>
    #  * <em>`symbol!`</em> --
    #    unconditionally sets the attribute to `true`.
    #
    # @param [Array<Symbol>] args
    #   Identifiers for the flag attributes to be declared.
    # @param [Hash<Symbol=>Object>] kwargs
    #   Hash of keyword arguments; see below.
    # @option kwargs [Symbol] `:default`
    # @return [void]
    #
    def flag(*args, **kwargs)
      kwargs		= _inivaluate_attrib(false, *args, **kwargs)
      kwargs.each do |attrib,default|
        default		= default ? true : false
        f_attr		= _decompose_attrib(attrib, default)
        define_method(f_attr.getter) {
          ival		= instance_variable_get(f_attr.ivar)
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
            val		= false
          end
          return instance_variable_set(f_attr.ivar,
                                       val ? true : false)
        }
      end                       # args.each

      nil
    end                         # def flag

    # @!macro [attach] doc.TAF::ClassMethods.classmethod.float_accessor
    #   @!attribute [rw] $1
    #   @overload $1
    #     @return [Float]
    #       the current value of `$1`.
    #   @overload $1=(arg)
    #     @param [Float] value
    #     @raise [TypeError]
    #       `attribute '$1' can only have float values or something coercible`
    #     @return [Float]
    #       the value of `value` that was passed in.
    #
    def float_accessor(*args, **kwargs)
      attrmethod	= __method__.to_s
      kwargs		= _inivaluate_attrib(0.0, *args, **kwargs)
      kwargs.each do |attrib,default|
        f_attr		= _decompose_attrib(attrib, default)
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
      end                       # kwargs.each

      nil
    end                         # def float_accessor
    alias_method(:float_reader, :float_accessor)
    alias_method(:float_writer, :float_accessor)

    # @!macro [attach] doc.TAF::ClassMethods.classmethod.int_accessor
    #   @!attribute [rw] $1
    #   @overload $1
    #     @return [Integer]
    #       the current value of `$1`.
    #   @overload $1=(value)
    #     @param [Integer] value
    #     @raise [TypeError]
    #       `attribute '$1' can only have integer values or something coercible`
    #     @return [Integer]
    #       the value of `value` that was passed in.
    #
    def int_accessor(*args, **kwargs)
      attrmethod	= __method__.to_s
      kwargs		= _inivaluate_attrib(0, *args, **kwargs)
      kwargs.each do |attrib,default|
        f_attr		= _decompose_attrib(attrib, default)
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
      end                       # kwargs.each

      nil
    end                         # def int_accessor
    alias_method(:int_reader, :int_accessor)
    alias_method(:int_writer, :int_accessor)

    nil
  end                           # module TAF::ClassMethods

  nil
end                             # module TAF

# Local Variables:
# mode: ruby
# indent-tabs-mode: nil
# eval: (if (intern-soft "fci-mode") (fci-mode 1))
# End:
