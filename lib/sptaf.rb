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
require('byebug')
require_relative('sptaf/version')
require_relative('sptaf/classmethods')

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
  # Include the project exceptions so that anything that mixes in this
  # module will get those, as well.
  #
  include(::TAF::Exceptions)

  # @!macro [new] doc.TAF.module.eigenclass
  #   Eigenclass for the top-level TAF module.  It provides class
  #   methods (like additional attribute declaration methods) for
  #   anything that extends the TAF module into its singleton class.
  class << self

    #
    # We can either `include` the classmethods module in the
    # eigenclass, or `extend` it from the main module body.  Six of
    # one..  Do the `include` because that makes Yard understand a
    # little better what's going on.
    #
    include(::TAF::ClassMethods)

    # @!macro doc.TAF...module.classmethod.included
    def included(klass)
      whoami		= '%s eigenclass.%s' \
                          % [self.name, __method__.to_s]
      warn('%s called for %s' \
           % [whoami, klass.name])
      super
      return nil
    end                         # def included(klass)

    nil
  end                           # module TAF eigenclass

  #
  def mixin_supers(msym=:initialize)
    msym		= msym.to_sym
    debugger
    result		= []
    next_method		= method(msym)
    while (next_method)
      owner		= next_method.owner
      warn('Owner %s is a %s' % [owner.name, owner.class.name])
      result.push(owner)
      next_method	= next_method.super_method
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
  # @raise [TAF::Exceptions::NotExceptionClass,Exception]
  #   either the requested exception, or a `NotExceptionClass`
  #   exception if the argument wasn't actually an exception class.
  # @return [void]
  #
  def raise_exception(exc_class, *args, **kwargs)
    kwargs[:levels]	||= 1
    bt			= caller
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
    # Add ourself to what's being elided, and remove the depth field.
    #
    (kwargs[:levels] + 1).times { bt.pop }
    kwargs.delete(:levels)
    #
    # Pass any arguments to the exception constructor, set the new
    # exception object's backtrace to our caller (or whatever stack
    # frame was made current), and raise it.
    #
    exc			= exc_class.new(*args, **kwargs)
    exc.set_backtrace(bt)
    raise(exc)
  end                           # def raise_exception
  private(:raise_exception)

  #
  def pluralise(name, number=1)
    result		= name
    unless (number.kind_of?(Integer) && (number == 1))
      result		= name.en.plural
    end
    return result
  end                           # def pluralise

  #
  # Checks to see if the object is a container according to the game
  # mechanics (basically, its class has included the
  # TAF::ContainerMixin module).
  #
  # @return [Boolean] `true`
  #   if the current object (`self`) has included the
  #   `ContainerMixin` module and has all the related methods
  #   and attributes.
  # @return [Boolean] `false`
  #   if the object is not a container.
  #
  def is_container?
    return self.class.ancestors.include?(::TAF::ContainerMixin) \
           ? true \
           : false
  end                         # def is_container?

  nil
end                             # module TAF

require('binding_of_caller')
require('linguistics')
require('ostruct')
require_relative('sptaf/exceptions')
require_relative('sptaf/thing')
require_relative('sptaf/inventory')
require_relative('sptaf/container')
require_relative('sptaf/item')
require_relative('sptaf/location')
require_relative('sptaf/game')
require_relative('sptaf/actor')
require_relative('sptaf/player')
require_relative('sptaf/npc')

Linguistics.use(:en)

# Local Variables:
# mode: ruby
# indent-tabs-mode: nil
# eval: (if (intern-soft "fci-mode") (fci-mode 1))
# End:
