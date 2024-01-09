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

#
# Require the master file unless some of its key definitions have been
# declared.
#
if ((! Kernel.const_defined?('TAGF')) \
    || (! TAGF.ancestors.include?(Contracts::Core)))
#  require('tagf')
end

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

      #
      include(Contracts::Core)

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

      #
      # Creates a new exception object of the specified class, edits
      # the backtrace to remove the appropriate number of stack
      # frames, and raises it.
      #
      # @param [Exception] exc_class
      #	  Exception to raise, as a class object (<em>e.g.</em>,
      #	  `StandardError`, `DuplicateObject`, <em>etc.</em>
      #	  <em>Not</em> a string nor an instance.
      # @param [Array] args
      #	  List of arguments to pass to the exception constructor.
      # @param [Hash] kwargs
      #	  Hash of keyword arguments to pass to the constructor,
      #	  possibly with the `:levels` keyword which will be consumed
      #	  by this method.
      # @option kwargs [Integer] :levels (1)
      #	  The number of stack frames to pop off the backtrace.	The
      #	  default is 1, meaning that the caller's caller will appear
      #	  to be the location raising the exception.
      # @raise [NotExceptionClass,Exception]
      #	  either the requested exception, or a `NotExceptionClass`
      #	  exception if the argument wasn't actually an exception
      #	  class.
      # @return [void]
      #
      def raise_exception(exc_class, *args, **kwargs)
	kwargs[:levels] ||= 1
	bt		= caller
	#
	# Verify that we were given an actual exception class.
	#
	unless (exc_class.ancestors.include?(Exception))
	  bt.pop
	  exc		= NotExceptionClass.new(exc_class)
	  exc.set_backtrace(bt)
	  raise(exc)
	end
	#
	# Add ourself to what's being elided, and remove the depth
	# field.
	#
	(kwargs[:levels] + 1).times { bt.pop }
	kwargs.delete(:levels)
	#
	# Pass any arguments to the exception constructor, set the new
	# exception object's backtrace to our caller (or whatever
	# stack frame was made current), and raise it.
	#
	exc		= exc_class.new(*args, **kwargs)
	exc.set_backtrace(bt)
	raise(exc)
      end			# def raise_exception
      private(:raise_exception)

      # Return `true` if the given object is a game element — that is,
      # its eigenclass has included (or been extended by) the
      # TAGF::Mixin::Element module.
      #
      # @param [Object]		target
      # @return [Boolean]
      def is_game_element?(target)
	result	= target.singleton_class.ancestors.include?(Mixin::Element)
	return result ? true : false
      end			# is_game_element?(target)
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

      # Convert a value (string, numeric, any kind of object) into a
      # Boolean.  This varies slightly from normal Ruby semantics in
      # that an integer 0 is considered `false` whereas normal Ruby
      # interpretation would consider it `true`.
      #
      # @param [Object]		testvalue
      #   value to evaluate for truthiness.
      # @return [Boolean]
      #   the result of the evaluation.
      #
      def truthify(testvalue)
        #
        # Fast-track actual Booleans.
        #
        if ([true, false].include?(testvalue))
          result	= testvalue
        elsif (testvalue.nil?)
          result	= false
        #
        # If it's some kind of number, zero is false.
        #
        elsif (testvalue.kind_of?(Numeric))
          result	= (! testvalue.zero?)
        #
        # If it's a string, see if it's one of our truthy keywords.
        #
        elsif (testvalue.kind_of?(String))
          if (Truthy_Strings.include?(testvalue.downcase))
            result	= true
          else
            result	= (! testvalue.to_f.zero?)
          end
        #
        # See if it can be turned into a float, whatever it is.
        #
        elsif (testvalue.respond_to?(:to_f))
          result	= testvalue.to_f.zero?
        #
        # Shrug.  False it is.
        #
        else
          result	= false
        end
        return result
      end                       # def truthify(testvalue)

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
