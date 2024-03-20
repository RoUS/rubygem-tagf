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

require('tagf/debugging')
warn(__FILE__) if (TAGF.debugging?(:file))
require('tagf/mixin/dtypes')
require('tagf/mixin/element')
require('tagf/mixin/universal')
require('tagf/exceptions')
require('tagf/item')
require('forwardable')
require('byebug')

# @!macro doc.TAGF.module
module TAGF

  # @!macro doc.TAGF.Mixin.module
  module Mixin

    # Module providing attributes and methods for something that can
    # be opened, closed, and possibly locked.  Containers always
    # include this module, but Path elements do so conditionally if
    # they include something like a (potentially locked) door.
    module Sealable

      include(Mixin::DTypes)
      include(Mixin::UniversalMethods)

      # @!macro TAGF.constant.Loadable_Fields
      Loadable_Fields		= [
        'desc_open',
        'desc_closed',
        'shortdesc_open',
        'shortdesc_closed',
        'openable',
        'opened',
        'autoclose',
        'lockable',
        'locked',
        'relock',
        'seal_key',
        'seal_name',
      ]

      # @!macro TAGF.constant.Abstracted_Fields
      Abstracted_Fields		= {
      }

      # @!attribute [rw] seal_key
      # @return [String]
      attr_accessor(:seal_key)

      # @!attribute [rw] seal_name
      # The name of the seal; used to ensure that if it changes state
      # from one side (such as being opened or unlocked), the change
      # is reflected from the other side (in the appropriate path).
      #
      # @return [String]
      attr_accessor(:seal_name)

      attr_accessor(:desc_open)
      attr_accessor(:shortdesc_open)
      attr_accessor(:desc_closed)
      attr_accessor(:shortdesc_closed)

      # @!attribute [rw] openable
      # Does this element have the option of being open or closed?
      # Think about a birdcage, which would want a door to keep any
      # birds from escaping.
      #
      # @!macro doc.TAGF.classmethod.flag.invoke
      # @return [Boolean]
      #   `true` if this element can be opened and/or closed.
      flag(openable: false)

      # @!attribute [rw] opened
      # If the container is openable, is it actually open?  We
      # override some of the standard attribute accessors added by
      # the Mixin::ClassMethods#flag method to provide correct results
      # if the element can't even be opened.
      #
      # @!macro doc.TAGF.classmethod.flag.invoke
      # @overload opened
      #   @return [Boolean]
      #     `true` or `false` if the element can be opened
      #     (#openable), otherwise `false`.
      # @overload opened?
      #   @return [Boolean]
      #     `true` or `false` if the element can be opened
      #     (#openable), otherwise `false`.
      # @overload opened!
      #   Sets the flag to `true` if the element is openable,
      #   otherwise always `false`.
      #   @return [Boolean]
      #     `true` or `false` if the element can be opened
      #     (#openable), otherwise `false`.
      # @overload opened=(value)
      #   Sets the flag to the `truthy` (see #truthify) value of the
      #   argument, but only if the current element is openable.
      #   Otherwise, the value is always `false`.
      #   @param [Boolean] value
      #     The new setting for the attribute, either `true` or
      #     `false` according to its truthiness (see #truthify), or
      #     unconditionally `false` if the element cannot be opened
      #     (see #openable).
      #   @return [Boolean]
      #     `true` or `false` if the element can be opened
      #     (#openable), otherwise `false`.
      flag(opened: false)
      def opened
        if (self.respond_to?(:surface) \
            && self.surface?)
          @opened	= true
        elsif (! self.openable?)
          @opened	= false
        end
        result		= @opened
        return result
      end                       # def opened
      alias_method(:opened?, :opened)
      def opened=(value)
        value		= truthify(value)
        #
        # @todo
        #   Need to handle trying to close an always-open surface with
        #   an exception.
        # @todo
        #   Need to make the interaction of the settings for
        #   openable/lockable/opened/locked clear; don't allow a
        #   locked seal to be opened, for instance; it needs to be
        #   unlocked first.
        #
        if (self.openable?)
          @opened	= value
        elsif (game_options?(:RaiseOnInvalidValues) && value)
          raise_exception(UnscrewingInscrutable,
                          self,
                          __method__,
                          true,
                          self,
                          :openable,
                          false)
        else
          value		= false
        end
        @opened		= value
        return @opened
      end                       # def opened=(value)

      # @!attribute [rw] lockable
      # Does this element have the option of being lock or closed?
      # Think about a birdcage, which would want a door to keep any
      # birds from escaping.
      #
      # @!macro doc.TAGF.classmethod.flag.invoke
      # @return [Boolean]
      flag(lockable: false)
      def lockable
        if (self.respond_to?(:surface) \
            && self.surface?)
          #
          # Containers that keep their inventory on a surface (like a
          # desk or a feature or a location) are always open and
          # cannot be locked.  Force the instance variable
          # appropriately.
          #
          @lockable	= false
        end
        return @lockable
      end                       # def lockable
      def lockable=(value)
        if (self.respond_to?(:surface) \
            && self.surface?)
          @lockable	= false
        else
          @lockable	= truthify(value)
        end
        return @lockable
      end                       # def lockable=(value)

      # @!attribute [rw] locked
      # If the container is lockable, is it actually lock?  We
      # override some of the standard attribute accessors added by
      # the Mixin::ClassMethods#flag method to provide correct results
      # if the element can't even be locked.
      #
      # @!macro doc.TAGF.classmethod.flag.invoke
      # @overload locked
      #   @return [Boolean]
      #     `true` or `false` if the element can be locked
      #     (#lockable), otherwise `false`.
      # @overload locked?
      #   @return [Boolean]
      #     `true` or `false` if the element can be locked
      #     (#lockable), otherwise `false`.
      # @overload locked!
      #   Sets the flag to `true` if the element is lockable,
      #   otherwise always `false`.
      #   @return [Boolean]
      #     `true` or `false` if the element can be locked
      #     (#lockable), otherwise `false`.
      # @overload locked=(value)
      #   Sets the flag to the `truthy` (see #truthify) value of the
      #   argument, but only if the current element is lockable.
      #   Otherwise, the value is always `false`.
      #   @param [Boolean] value
      #     The new setting for the attribute, either `true` or
      #     `false` according to its truthiness (see #truthify), or
      #     unconditionally `false` if the element cannot be locked
      #     (see #lockable).
      #   @return [Boolean]
      #     `true` or `false` if the element can be locked
      #     (#lockable), otherwise `false`.
      flag(locked: false)
      def locked
        if (self.respond_to?(:surface) \
            && self.surface?)
          #
          # Things which keep their inventory on a surface (like a
          # desk or a location (which keeps the inventory on the
          # floor, apparently) aren't lockable and are never locked.
          #
          @locked	= false
        elsif (! self.lockable?)
          @locked	= false
        end
        result		= @locked
        return result
      end                       # def locked
      alias_method(:locked?, :locked)
      def locked=(value)
        value		= truthify(value)
        #
        # @todo
        #   Need to handle trying to close an always-open surface with
        #   an exception.
        #
        if (self.lockable?)
          @locked	= value
        elsif (game_options?(:RaiseOnInvalidValues) && value)
          raise_exception(UnscrewingInscrutable,
                          self,
                          __callee__,
                          true,
                          self,
                          :lockable,
                          false)
        else
          value		= false
        end
        @locked		= value
        return @locked
      end                       # def locked=(value)

      # @!attribute [rw] autoclose
      # Whether the seal is automatically relocked after every use.
      # Think of an emergency exit door.  Forced to `false` unless
      # #lockable? returns `true`, in which case it's set to the
      # truthy value of the argument.
      #
      # @!macro doc.TAGF.classmethod.flag.invoke
      #
      # @return [Boolean]
      #   `true` if the seal is automatically relocked after every
      #   use.
      flag(autoclose: false)
      def autoclose!
        result		= self.autoclose(true)
        return result
      end                       # def autoclose!
      def autoclose=(value)
        if (self.openable?)
          result	= truthify(value)
        else
          result	= false
        end
        @autoclose	= result
        return self.autoclose?
      end                       # def autoclose=(value)

      # @!attribute [rw] relock
      # Whether the seal is automatically relocked after every use.
      # Think of an emergency exit door.  Forced to `false` unless
      # #lockable? returns `true`, in which case it's set to the
      # truthy value of the argument.
      #
      # @!macro doc.TAGF.classmethod.flag.invoke
      #
      # @return [Boolean]
      #   `true` if the seal is automatically relocked after every
      #   use.
      flag(relock: false)
      def relock!
        result		= self.relock(true)
        return result
      end                       # def relock!
      def relock=(value)
        if (self.lockable?)
          result	= truthify(value)
        else
          result	= false
        end
        @relock		= result
        return self.relock?
      end                       # def relock=(value)

      # @!method initialize_sealable(*args, **kwargs)
      def initialize_sealable(*args, **kwargs)
        if (self.respond_to?(:surface?) \
            && self.surface?)
          self.openable	= true
          self.opened	= true
        end
        #
        # Propagate any seal-specific attribute values from `kwargs`
        # to the actual attributes of this object.
        #
        Loadable_Fields.each do |fname|
          fgetter	= fname.to_sym
          fivar		= format('@%s', fname).to_sym
          if (kwargs.has_key?(fgetter))
            fsetter	= format('%s=', fname).to_sym
            self.send(fsetter, kwargs[fgetter])
          end
        end
      end                       # def initialize_sealable

      nil
    end                         # module Sealable

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
