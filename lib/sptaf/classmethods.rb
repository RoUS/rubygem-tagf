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

TAF.require_file('sptaf')
warn(__FILE__) if (TAF.debugging?(:file))
TAF.require_file('sptaf/exceptions')
TAF.require_file('ostruct')
TAF.require_file('byebug')

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

    #
    TAF.mixin(::TAF)

    # @!macro doc.TAF.module.classmethod.included
    def included(klass)
      whoami		= '%s eigenclass.%s' \
                          % [self.name, __method__.to_s]
=begin
      warn('%s called for %s' \
           % [whoami, klass.name])
=end
      [ TAF::ClassMethods ].each do |xmodule|
        if (klass.singleton_class.included_modules.include?(xmodule))
          next
        end
        if (TAF.debugging?(:extend))
          warn('%s extending %s with %s' \
               % [whoami, klass.name, xmodule.name])
        end
        klass.extend(xmodule)
      end
      super
      return nil
    end                         # def included(klass)

    # @private
    #
    # @param [Any] default (nil)
    #   Whatever default value should be supplied for attributes
    #   listed in the `args` array.
    # @param [Array<Symbol>] args
    #   (Possibly empty) array of attribute identifiers.
    # @param [Hash{Symbol=>Any}] kwargs
    #   (Possibly empty) hash of <em>keysym:inival</em> tuples.
    # @yield [inival]
    #   allows an attribute declarator to perform validity checks or
    #   transformations on the initial values (such as ensuring they
    #   are all of a particular class (<em>e.g.</em>, `TrueClass` or
    #   `FalseClass` for a Boolean attribute).
    # @yieldparam inival [Object]
    #   each <em>inival</em> in turn.
    # @yieldreturn [Object]
    #   whatever tranformation, if any, the block performs on the
    #   <em>inival</em>.
    # @return [Hash{Symbol=>Any}]
    #   a hash of <em>keysym:inival</em> tuples built from merging the
    #   <em>kwargs</em> hash onto the one constructed from the
    #   <em>args</em> array and the <em>default</em> value.
    def _inivaluate_attrib(default=nil, *args, **kwargs, &block)
      unless ((argc = args.count).zero?)
        #
        # Turn any bare attributes into hashes with the appropriate
        # default setting.
        #
        defaults	= [default] * argc
        nmargs		= args.map { |o| o.to_sym }
        nmargs		= nmargs.zip(defaults).map { |ary| Hash[*ary] }
        nmargs		= nmargs.reduce(&:merge)
        #
        # Do it in the `nmargs.merge(kwargs)` order so any
        # attributes that <em>were</em> given initial values override
        # bare ones of the same name picking up the default.
        #
        kwargs		= nmargs.merge(kwargs)
      end
      #
      # Allow refinement of the initial values by a block supplied by
      # our caller.
      #
      if (block_given?)
        kwargs.keys.each do |k|
          kwargs[k]	= yield(kwargs[k])
        end
      end
      return kwargs
    end                         # def _inivaluate_attrib
    private(:_inivaluate_attrib)

    # @ ! macro doc.TAF.classmethod.flag.def
    def flag(*args, **kwargs)
      kwargs		= _inivaluate_attrib(false,
                                             *args,
                                             **kwargs) { |v|
        truthify(v)
      }
      kwargs.each do |attrib,default|
        default		= default ? true : false
        f_attr		= decompose_attrib(attrib, default)
        #
        # Define the getter method.  We don't just use {attr_reader}
        # because we want to set an initial value on the first read.
        #
        define_method(f_attr.getter) {
          ival		= instance_variable_get(f_attr.ivar)
          if (ival.nil?)
            ival	= truthify(f_attr.default)
            instance_variable_set(f_attr.ivar, ival)
          end
          return ival
        }
        #
        # Now the query method, which is basically a copy of the getter method.
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
      end                       # args.each

      nil
    end                         # def flag


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

    # @!macro doc.TAF.classmethod.float_accessor.def
    def float_accessor(*args, **kwargs)
      attrmethod	= __method__.to_s
      kwargs		= _inivaluate_attrib(0.0, *args, **kwargs)
      kwargs.each do |attrib,default|
        f_attr		= decompose_attrib(attrib, default)
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

    # @!macro doc.TAF.classmethod.int_accessor.def
    def int_accessor(*args, **kwargs)
      attrmethod	= __method__.to_s
      kwargs		= _inivaluate_attrib(0, *args, **kwargs)
      kwargs.each do |attrib,default|
        f_attr		= decompose_attrib(attrib, default)
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
