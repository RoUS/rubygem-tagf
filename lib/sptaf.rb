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
require('bundler')
Bundler.setup
require('sptaf/debugging')

warn(__FILE__) if (TAF.debugging?(:file))

require('sptaf/version')
require('sptaf/classmethods')
require('sptaf/exceptions')

unless ((RUBY_ENGINE == 'ruby') \
        && (RUBY_VERSION >= ::TAF::RUBY_VERSION_MIN))
  warn(__class__.name \
       + ' requires the ruby engine version ' \
       + "#{::TAF::RUBY_VERSION_MIN_GEMSPEC}")
  exit(1)
end                             # Ruby version check

# @!macro doc.TAF.module
module TAF

  #
  extend(ClassMethods)
  
  #
  # Include the project exceptions so that anything that mixes in this
  # module will get those as well.
  #
  include(Exceptions)

  # @!macro [new] doc.TAF.module.eigenclass
  #   Eigenclass for a TAF module.  It provides class methods (like
  #   additional attribute declaration methods) for anything that
  #   extends the TAF module into its singleton class.
  class << self

    #
    # We can either `include` the classmethods module in the
    # eigenclass, or `extend` it from the main module body.  Six of
    # one..  Do the `include` because that makes Yard understand a
    # little better what's going on.
    #
    if (TAF.debugging?(:include))
      warn('%s including %s' % [ self.name, Exceptions.name ])
    end
    include(ClassMethods)

    # @!macro doc.TAF.module.classmethod.included
    def included(klass)
      whoami            = '%s eigenclass.%s' \
                          % [self.name, __method__.to_s]
=begin
      warn('%s called for %s' \
           % [whoami, klass.name])
=end
      super
      return nil
    end                         # def included(klass)

    nil
  end                           # module TAF eigenclass

  C_Attitudes           = %i[
                             friendly
                             neutral
                             hostile
                            ]

  #
  def mixin_supers(msym=:initialize)
    msym                = msym.to_sym
    debugger
    result              = []
    next_method         = method(msym)
    while (next_method)
      owner             = next_method.owner
      warn('Owner %s is a %s' % [owner.name, owner.class.name])
      result.push(owner)
      next_method       = next_method.super_method
    end                         # while (next_method)
    return result
  end                           # def mixin_supers(msym=:initialize)

  #
  # Creates a new exception object of the specified class, edits the
  # backtrace to remove the appropriate number of stack frames, and
  # raises it.
  #
  # @param [Exception] exc_class
  #   Exception to raise, as a class object (<em>e.g.</em>,
  #   `StandardError`, `DuplicateObject`, <em>etc.</em> <em>Not</em> a
  #   string nor an instance.
  # @param [Array] args
  #   List of arguments to pass to the exception constructor.
  # @param [Hash] kwargs
  #   Hash of keyword arguments to pass to the constructor, possibly
  #   with the `:levels` keyword which will be consumed by this
  #   method.
  # @option kwargs [Integer] :levels (1)
  #   The number of stack frames to pop off the backtrace.  The
  #   default is 1, meaning that the caller's caller will appear to be
  #   the location raising the exception.
  # @raise [NotExceptionClass,Exception]
  #   either the requested exception, or a `NotExceptionClass`
  #   exception if the argument wasn't actually an exception class.
  # @return [void]
  #
  def raise_exception(exc_class, *args, **kwargs)
    kwargs[:levels]     ||= 1
    bt                  = caller
    #
    # Verify that we were given an actual exception class.
    #
    unless (exc_class.ancestors.include?(Exception))
      bt.pop
      exc               = NotExceptionClass.new(exc_class)
      exc.set_backtrace(bt)
      raise(exc)
    end
    #
    # Add ourself to what's being elided, and remove the depth field.
    #
    (kwargs[:levels] + 1).times { bt.pop }
    kwargs.delete(:levels)
    #
    # Pass any arguments to the exception constructor, set the new
    # exception object's backtrace to our caller (or whatever stack
    # frame was made current), and raise it.
    #
    exc                 = exc_class.new(*args, **kwargs)
    exc.set_backtrace(bt)
    raise(exc)
  end                           # def raise_exception
  private(:raise_exception)

  #
  # Given a word (presumably a singular noun) and a count, return the
  # plural of the word if the count justifies it.
  #
  # @note
  #   At the moment, only English (`en`) words are supported.
  #
  # @param [String] word
  # @param [Integer] number
  # @return [String]
  #   either the original word, or the deduced plural if the `number`
  #   argument was an integer 1.  (Floats <em>always</em> use plurals,
  #   even if they're `1.000`.)
  #
  def pluralise(word, number=1)
    result              = word
    unless (number.kind_of?(Integer) && (number == 1))
      result            = word.en.plural
    end
    return result
  end                           # def pluralise

  #
  # Convert a value into a Boolean.  This varies slightly from normal
  # Ruby semantics in that an integer 0 is considered `false` whereas
  # normal Ruby interpretation would consider it `true`.
  #
  # @param [Object] testvalue
  #   value to evaluate for truthiness.
  # @return [Boolean]
  #   the result of the evaluation.
  #
  def truthify(testvalue)
    if (testvalue.kind_of?(Integer) && testvalue.zero?)
      result            = false
    else
      result            = testvalue ? true : false
    end
    return result
  end                           # def truthify(testvalue)

    # @private
    #
    # @param [String,Symbol] attrib_p
    # @param [Any] default
    # @return [OpenStruct]
    def decompose_attrib(attrib_p, default=nil)
      strval		= attrib_p.to_s.sub(%r![^_[:alnum:]]*$!, '')
      pieces		= OpenStruct.new(
        default: 	default,
        str:		strval,
        attrib:		strval.to_sym,
        getter:		strval.to_sym,
        setter:		"#{strval}=".to_sym,
        query:		"#{strval}?".to_sym,
        bang:		"#{strval}!".to_sym,
        ivar:		"@#{strval}".to_sym
      )
      return pieces
    end                         # def decompose_attrib(attrib_p, default=nil)
    protected(:decompose_attrib)
    module_function(:decompose_attrib)

  nil
end                             # module TAF

require('binding_of_caller')
require('linguistics')
require('ostruct')
require('sptaf/exceptions')
require('sptaf/mixin/thing')
require('sptaf/inventory')
require('sptaf/mixin/container')
require('sptaf/container')
require('sptaf/item')
require('sptaf/cli')
require('sptaf/mixin/location')
require('sptaf/location')
require('sptaf/feature')
require('sptaf/game')
require('sptaf/mixin/actor')
require('sptaf/faction')
require('sptaf/player')
require('sptaf/npc')

Linguistics.use(:en)

# Local Variables:
# mode: ruby
# indent-tabs-mode: nil
# eval: (if (intern-soft "fci-mode") (fci-mode 1))
# End:
