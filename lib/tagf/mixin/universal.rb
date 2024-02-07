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

#require('tagf/debugging')
#warn(__FILE__) if (TAGF.debugging?(:file))

#require('contracts')

#require('tagf/exceptions')

#
# Require the master file unless some of its key definitions have been
# declared.
#
#if ((! Kernel.const_defined?('TAGF')) \
#    || (! TAGF.ancestors.include?(Contracts::Core)))
#  require('tagf')
#end


# @!macro doc.TAGF.module
module TAGF

  # @!macro doc.TAGF.Mixin.module
  module Mixin

    #
    # Now, just define these things, don't actually try to *impose*
    # them on any other part of the package.  Each module/class should
    # be responsible for its own configuration.
    #

    # @!macro doc.TAGF.Mixin.UniversalMethods.module
    module UniversalMethods

      class << self

        # Module eigenclass method invoked whenever the module is
        # `include`d into another class or module.
        #
        # As long as the including object is a module or a named Class
        # object, we'll also extend its eigenclass.  This make sure
        # anyplace the module is included, so is its eigenclass.
        # Since this is the UniversalMethods module, this ensures that
        # its definitions really <em>are</em> universal.
        #
        # @param [Class] klass
        #   The class into which the module is being `include`d.
        def included(klass)
          #
          # If the including object is a module or a named class,
          # also extend it with our UniversalMethods module.
          #
          if (klass.kind_of?(Module) \
              || (! klass.name.to_s.empty?))
            klass.extend(UniversalMethods)
          end
          return nil
        end                     # def included(klass)

        nil
      end                       # class UniversalMethods eigenclass
      
      #
#      include(Contracts::Core)

      #
      # List of game-wide option flags to impose (or relax) certain
      # restrictions.
      #
      GAME_OPTIONS	= %i[
			     RaiseOnInvalidValues
			     EnableHitpoints
			     EnforceLighting
			     EnforceMass
			     EnforceVolume
			     EnforceItemCounts
			     EnforceCapacities
			    ]

      #
      # Related options that can enabled/disabled collectively as well
      # as individually.  These are called option 'clumps.'
      #
      GAME_OPTION_CLUMPS= {
	EnforceCapacities: %i[
			      EnforceMass
			      EnforceVolume
			      EnforceItemCounts
			     ],
      }

      #
      # Symbols describing possible attitudes available to an actor.
      #
      C_Attitudes	= %i[
			     friendly
			     neutral
			     hostile
			    ]

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
      #   a hash of <em>keysym:inival</em> tuples built from merging
      #   the <em>kwargs</em> hash onto the one constructed from the
      #   <em>args</em> array and the <em>default</em> value.
      def _inivaluate_args(default=nil, *args, **kwargs, &block)
        unless ((argc = args.count).zero?)
          #
          # Turn any bare attributes into hashes with the appropriate
          # default setting.
          #
          defaults	= [default] * argc
          nmargs	= args.map { |o| o.to_sym }
          nmargs	= nmargs.zip(defaults).map { |ary| Hash[*ary] }
          nmargs	= nmargs.reduce(&:merge)
          #
          # Do it in the `nmargs.merge(kwargs)` order so any
          # attributes that <em>were</em> given initial values override
          # bare ones of the same name picking up the default.
          #
          kwargs	= nmargs.merge(kwargs)
        end
        #
        # Allow refinement of the initial values by a block supplied
        # by our caller.
        #
        if (block_given?)
          kwargs.keys.each do |k|
            kwargs[k]	= yield(kwargs[k])
          end
        end
        return kwargs
      end                       # def _inivaluate_args
      private(:_inivaluate_args)

      #
      # Check to see whether one or more game options are currently
      # enabled.  If any arguments aren't recognised as game options,
      # a warning is sent to `stderr` and that argument is ignored.
      #
      # @param [Symbol] option
      # @param [Array<Symbol>] args
      # @return [Boolean]
      #	  `true` if **all** of the requested options are currently
      #	  enabled.
      def game_options?(option, *args)
	requested	= Set.new([option, *args].map { |o| o.to_sym })
	unknown		= requested - GAME_OPTIONS
	unknown.each do |opt|
	  warn(format('%s.%s: unknown game option: %s',
	              'TAGF',
                      __method__.to_s,
                      opt.to_s))
	  requested.delete(opt)
	end
	active		= TAGF.game_options
	return requested.all? { |opt| active.include?(opt) }
      end			# def game_options?(*args)

      # @!method raise_exception(exc_object, *args, **kwargs)
      # Either uses a passed exception or creates a new exception
      # object according to the `exc_object` parameter, edits the
      # backtrace to remove the appropriate number of stack frames,
      # and raises it.
      #
      # Acceptable values for `exc_object` are any of the following:
      #
      # 1. a string
      #    — a new `RuntimeError` exception is created from the
      #    string.  `args` is ignored.
      # 1. an exception object
      #    — the object is raised as is.  `args` is ignored.
      # 1. an exception class
      #    — a new exception object is created from this constructor.
      #    `args` is passed to the constructor, and `kwargs` as well
      #    if `exc_object` is a descendant of
      #    `TAGF::Exceptions::ErrorBase`.
      # 1. a callable object that returns one of the above
      #    — anything that responds to the `:call` method falls into
      #    this category.  It will be invoked with `.call(*args)`.
      #    `kwargs` isn't passed.
      #
      # @param [String,Class,Exception,Proc] exc_object
      #	  A string (converted to a `RuntimeError` exception), an
      #   exception class, an actual exception, or a `Proc` that
      #   returns one of the above.  See the method description.
      # @param [Array] args
      #	  List of arguments to pass to any exception constructor
      #	  invoked.
      # @param [Hash] kwargs
      #	  Hash of keyword arguments to pass to the constructor,
      #	  possibly with the `:levels` keyword which will be consumed
      #	  by this method.
      # @option kwargs [Integer] :levels (1)
      #	  The number of stack frames to pop off the backtrace.	The
      #	  default is 1, meaning that the caller's caller will appear
      #	  to be the location raising the exception.
      # @raise [TAGF::Exceptions::NotExceptional]
      #   a `NotExceptional` exception is if the argument wasn't a
      #	  string, an exception instance, an exception class, or a proc
      #	  that (eventually) returns an exception class or instance.
      # @raise [Any]
      #	  whatever valid exception was derived from the arguments.
      # @return [void]
      #
      def raise_exception(exc_object, *args, **kwargs)
	kwargs[:levels] ||= 1
	bt		= caller

        warn(format("\n%s entry backtrace:" +
                    "\n  levels: %i" +
                    "\n  exc_object=%s:%s" +
                    "\n  %s",
                    __callee__.to_s,
                    kwargs[:levels].to_i,
                    exc_object.class.name,
                    exc_object.inspect,
                    PP.pp(bt[0,10],
                          String.new).gsub(%r!\n!, "\n  ")))

        loop do
          #
          # `exc_object` possibilities:
          # * an exception instance
          #   — used as-is
          # * an exception class (.ancestors.include?(:Exception))
          #   — an instance will be created from it and `args`
          # * something callable
          #   — exc_object.call(*args), then repeat
          # * a string
          #   — a `RuntimeError` instance is created from exc_object;
          #   `args` is ignored
          # * anything else
          #   — raise a Exceptions::NotExceptional exception
          #
          if (exc_object.kind_of?(Exception))
            #
            # We were passed an actual exception instance, not a
            # class.
            #
            break
          elsif (exc_object.kind_of?(String))
            #
            # It's a string!  Turn it into a `RuntimeError` the way a
            # simple `raise("string")` does.
            #
            exc_object	= RuntimeError.new(exc_object)
            break
          elsif (exc_object.respond_to?(:call))
            #
            # Something callable, which *might* return a valid
            # exception instance or class.  Try it, and loop through
            # again.
            #
            exc_object	= exc_object.call(*args)
            next
          elsif ((! exc_object.kind_of?(Class)) \
                 || (! exc_object.ancestors.include?(Exception)))
            #
            # Not a class at all, or at least not one descended from
            # `Exception`.  Raise an exception using ourself,
            # incrementing the level count to take our recursive call
            # and loop out of the backtrace.
            #
            self.send(__callee__,
                      Exceptions::NotExceptional.new(offender: exc_object),
                      levels: kwargs[:levels].to_i + 2)
          else
            #
            # This appears to be an actual exception class, so create
            # an instance from it.  If it's one of ours, pass the
            # `kwargs` hash too (minus our `:levels` keyword),
            # otherwise just pass the `args` array.
            #
            if (exc_object.kind_of?(TAGF::Exceptions::ErrorBase))
              debugger
              nkwargs	= kwargs.dup
              nkwargs.delete(:levels)
              exc_object = exc_object.new(*args, **nkwargs)
            else              
              exc_object = exc_object.new(*args)
            end
            #
            # Break out of the loop.
            #
            break
          end                   # exception-deduction if-tree
	end                     # loop do
	#
	# `exc_object` is an actual exception instance.  Let's edit
        # the backtrace and raise the sucker.
	#
	# By default we add ourself to what's being elided; this can
        # be overridden by passing `:levels` with a value <= 0.
	#
	(kwargs[:levels] + 1).times { bt.shift }
        warn(format("%s edited backtrace:" +
                    "\n  levels: %i" +
                    "\n  exc_object=%s:%s" +
                    "\n  %s",
                    __callee__.to_s,
                    kwargs[:levels].to_i,
                    exc_object.class.name,
                    exc_object.inspect,
                    PP.pp(bt[0,10],
                          String.new).gsub(%r!\n!, "\n  ")))
	#
	# Pass any arguments to the exception constructor, set the new
	# exception object's backtrace to our caller (or whatever
	# stack frame was made current), and raise it.
	#
	exc_object.set_backtrace(bt)
	raise(exc_object)
      end			# def raise_exception
#      protected(:raise_exception)

      # Return `true` if the given object is a game element — that is,
      # its eigenclass has included (or been extended by) the
      # TAGF::Mixin::Element module.
      #
      # @param [Object]		target
      # @return [Boolean]
      def is_game_element?(target)
	result	= target.singleton_class.ancestors.include?(Mixin::Element)
	return result ? true : false
      end			# def is_game_element?(target)
      module_function(:is_game_element?)
      public(:is_game_element?)

      #
      # Given a word (presumably a singular noun) and a count, return
      # the plural of the word if the count justifies it.
      #
      # @note
      #	  At the moment, only English (`en`) words are supported.
      #
      # @param [String]		word
      # @param [Integer]	number
      # @return [String]
      #	  either the original word, or the deduced plural if the
      #	  `number` argument was an integer 1.  (Floats <em>always</em>
      #	  use plurals, even if they're `1.000`.)
      #
      def pluralise(word, number=1)
	result		= word
        unless (number.kind_of?(Integer) && (number == 1))
          result	= word.en.plural
        end
        return result
      end                       # def pluralise

      #
      # List of (case-insensitive) strings that evaluate to a Boolean
      # `true` value.
      #
      Truthy_Strings	= %w[ y yes t true on ]

      #
      # List of (case-insensitive) strings that explicitly evaluate to
      # a Boolean `false` value.
      #
      UnTruthy_Strings	= %w[ n no f false off nil null ]

      #
      # Regular expression pattern matching an integer or bignum
      # string.  Used by itself, and also by {Float_String} and
      # {Complex_String}.
      #
      Digit_String	= '\d+'

      #
      # Regular expression pattern matching a floating point string.
      # Also used by {Complex_String}.  Modern Ruby requires digits on
      # both sides of the decimal point.
      #
      Float_String	= format('%s\.%s',
                                 Digit_String,
                                 Digit_String)

      #
      # Regular expression matching a Ruby complex number string.
      #
      Complex_String	= format('\(?(?:%s|%s)[-+](?:%s|%s)i\)?',
                                 Digit_String,
                                 Float_String,
                                 Digit_String,
                                 Float_String)

      #
      # Compiled regular expression matching a string of digits (an
      # integer or bignum).
      #
      Integer_String_RE	= %r!^#{Digit_String}$!

      #
      # Compiled regular expression matching a Ruby Float as a string.
      #
      Float_String_RE	= %r!^#{Float_String}$!

      #
      # Compiled regular expression matching Ruby's representation of
      # a complex numeric value.
      #
      Complex_String_RE	= %r!^#{Complex_String}$!

      #
      # Default proc used to test for truthyness of any value of any
      # kind.  Used by #truthify.  Can be used as an example for
      # custom truthiness test procs.
      #
      #
      Truthy_TestProc	= Proc.new { |testvalue|
        #
        # Symbols we don't handle directly, so convert them into
        # Strings for evaluation.  This is perhaps a cop-out.
        #
        if (testvalue.kind_of?(Symbol))
          testvalue	= testvalue.to_s
        end
        #
        # This is a messy tree of if/elsif/else/end checks.  Each
        # [els]if block is moronically simple, making this look
        # overengineered, but there are reasons.  Firstly because
        # there are several conditions (and subconditions) to check,
        # and secondly because putting them all into a single
        # conditional is even worse (and 'first true result
        # short-circuits the rest of the expression' wasn't working as
        # expected).  Plus, this makes adding/changing/deleting checks
        # much simpler.
        #
        # First, check explicit Boolean values, since they
        # short-circuit the testing massively.  `true` is, of course,
        # true.
        #
        if ((testvalue == false) ||
            testvalue.nil?)
          result	= false
        elsif (testvalue == true)
          result	= true
        elsif (testvalue.kind_of?(Numeric))
          #
          # If it's a numeric value (of any kind), anything that
          # isn't zero is considered true.
          #
          # Checking past this point is for strings, which depends
          # heavily on regular expression matching, which is
          # consumptive.
          #
          result	= (! testvalue.zero?)
        elsif (testvalue.kind_of?(String))
          #
          # Now comes the complex part: checking to see if this string
          # evaluates to something we should treat as true.  Explicit
          # text string (checked in list of truthy strings), or string
          # representations of numbers (checked as evaluating to
          # zero).
          #
          if (Truthy_Strings.include?(testvalue.downcase))
            #
            # But first, is it one of our explicitly truthy strings?
            # (Easy first test.)
            #
            result	= true
          elsif (UnTruthy_Strings.include?(testvalue.downcase))
            #
            # How about one of our explicitly UNtruthy strings?
            #
            result	= false
          elsif (testvalue =~ Integer_String_RE)
            #
            # It'a string of just decimal digits, but not evaluating
            # to zero.
            #
            result	= (! Integer(testvalue).zero?)
          elsif (testvalue =~ Float_String_RE)
            #
            # Non-zero floating-point string?
            #
            result	= (! Float(testvalue).zero?)
          elsif (testvalue =~ Complex_String_RE)
            #
            # Non-zero complex number?  The Complex coercion doesn't
            # deal with parenthesised strings, so remove those before
            # converting.  We could do it with a regex substitution,
            # but slicing is faster.
            #
            temp	= testvalue
            if ((testvalue[0,1] == '(') && (testvalue[-1,1] == ')'))
              temp	= testvalue[1,testvalue.length - 2]
            end
            result	= (! Complex(temp).zero?)
          else
            #
            # None of our string cases matched, so it isn't explicitly
            # truthy and isn't explicitly untruthy.  So it's false by
            # default.
            #
            result	= false
          end
        else
          #
          # Sorry, didn't meet any of our conditions; not explicitly
          # truthy.  Fall back on Ruby's interpretation.
          #
          result	= testvalue ? true : false
        end
        result
      }

      # Convert a value (string, numeric, any kind of object) into a
      # Boolean.  This varies slightly from normal Ruby semantics in
      # that an integer 0 is considered `false` whereas normal Ruby
      # interpretation would consider it `true`.
      #
      # Any value which isn't represented in the list of truthy values
      # is considered `false`.
      #
      # The default list of truthy values can be augmented or replaced
      # by using the keyword arguments `:true_values` and `:replace`.
      # See the option descriptions below.
      #
      # More involved checking can be performed by supplying a proc
      # (which is what the default implementation uses).  This module
      # supplies some possibly-useful string and Regexp constants.
      # @see Truthy_Test_Proc
      # @see Truthy_Strings
      # @see Digit_String
      # @see Float_String
      # @see Complex_String
      # @see Integer_String_RE
      # @see Float_String_RE
      # @see Complex_String_RE
      #
      # @param [Object]			testvalue
      #   value to evaluate for truthiness.
      # @param [Hash<Symbol=>Object>]	kwargs
      # @option kwargs [Array]		:true_values
      #   An array of objects that are the only ones that will be
      #   considered truthy.  <em>Any more involved checking than 'is
      #   it one of these?' should be handled with a truthiness
      #   proc.</em> 
      #
      #   This is only meaningful if `:truthiness_proc` isn't used.
      # @option kwargs [Proc]		:truthiness_proc
      #   Proc to be called
      # @return [Boolean]
      #   the result of the evaluation.
      #
      # @raise [UncallableObject]
      #   if the `:truthiness_proc` argument doesn't respond to the
      #   `:call` method.
      def truthify(testvalue, **kwargs)
        if (testproc = kwargs[:truthiness_proc])
          unless (testproc.respond_to?(:call))
            raise(UncallableObject.new(object: testproc,
                                       prefix: 'invalid render_proc'))
          end
          return testproc.call(testvalue)
        end
        unless (kwargs.has_key?(:true_values))
          return Truthy_TestProc.call(testvalue)
        end
        #
        # We were passed an explicit list of truthy values.  Is this
        # in the list?
        #
        return kwargs[:true_values].include?(testvalue)
      end                       # def truthify(testvalue, **kwargs)

      # @private
      # Given a symbolic attribute name and potentially a default
      # value, return a structure containing fields for the various
      # things needed to define methods dealing with it
      # (String name, instance-variable symbol, attribute with
      # suffices like `!`, `?`, `=`).  Any non-alphanumeric,
      # non-underscore characters are silently stripped before the
      # name is processed.
      #
      # See the return value for details of the returned structure.
      #
      # @param [String,Symbol]		attrib_p
      # @param [Any] default
      # @return [OpenStruct] Fields in the structure are:
      #```
      #     default:    The default value from this method invocation;
      #                 default `nil`
      #     str:        The base attribute name as a String
      #     attrib:     The base attribute name as a Symbol
      #     getter:     (Same as :attrib field)
      #     setter:     The symbolic attribute name with a `=` suffix
      #     query:      The symbolic attribute name with a `?` suffix
      #     bang:       The symbolic attribute name with a `!` suffix
      #     ivar:       The symbolic name for the corresponding
      #                 instance variable (_e.g._, `:@<attrib_p>`)
      #```
      def decompose_attrib(attrib_p, default=nil)
        strval		= attrib_p.to_s.sub(%r![^_[:alnum:]]*$!, '')
        pieces		= OpenStruct.new(
          default:	default,
          str:		strval,
          attrib:	strval.to_sym,
          getter:	strval.to_sym,
          setter:	"#{strval}=".to_sym,
          query:	"#{strval}?".to_sym,
          bang:		"#{strval}!".to_sym,
          ivar:		"@#{strval}".to_sym
        )
        return pieces
      end                # def decompose_attrib(attrib_p, default=nil)
      protected(:decompose_attrib)
      module_function(:decompose_attrib)

      nil
    end				# module TAGF::Mixin::UniversalMethods

    nil
  end				# module TAGF::Mixin

  nil
end				# module TAGF

#require('tagf/mixin/classmethods')

#TAGF::Mixin::UniversalMethods.extend(TAGF::Mixin::ClassMethods)

# Local Variables:
# mode: ruby
# indent-tabs-mode: nil
# eval: (if (intern-soft "fci-mode") (fci-mode 1))
# eval: (auto-fill-mode 1)
# End:
