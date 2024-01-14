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

require('tagf/mixin/dtypes')
require('tagf/mixin/universal')
require('byebug')

# @!macro doc.TAGF.module
module TAGF

  #
  module Mixin

    # @!macro doc.TAGF.PackageMethods.module
    module PackageClassMethods

      include(Mixin::DTypes)

      # TAGF game options are simply flags, considered active if they
      # appear in the game_options Set instance.
      #
      # @param [Array<Symbol>]		args		([])
      # @param [Hash<Symbol,Object>]	kwargs		({})
      # @return [Array<Symbol>]
      #   an array of the currently-active options
      #
      # @see Mixin::UniversalMethods::GAME_OPTIONS
      # @see Mixin::UniversalMethods::GAME_OPTION_CLUMPS
      def game_options(*args, **kwargs)
        #
        # Make sure we actually have an options Set before doing
        # anything.
        #
        @game_options	||= Set.new
        #
        # If we weren't passed any arguments at all, just return the
        # current settings — we're done.
        #
        return @game_options.to_a if (args.empty? && kwargs.empty?)
        #
        # Get a list of the options being requested, separate out the
        # invalid ones (such as `:not_a_real_option`), complain about
        # them to `stderr`, and strip them from the list.  This is a
        # non-fatal issue; once the bogus options are reported and
        # removed, we proceed with the (valid) remainder.
        #
        requested	= _inivaluate_attrib(true, *args, **kwargs)
        unknown		= requested.keys - GAME_OPTIONS
        unknown.each do |opt|
          warn(format('%s.%s: unknown game option: %s',
                      'TAGF',
                      __method__.to_s,
                      opt.to_s))
          requested.delete(opt)
        end
        GAME_OPTION_CLUMPS.each do |brolly,clumped|
          if (requested.keys.include?(brolly))
            newval	= requested[brolly]
            clumped.each do |opt|
              requested[opt] = newval unless (requested.keys.include?(opt))
            end
            requested[brolly] = false
          end
        end                     # GAME_OPTION_CLUMPS.each
        newopts		= requested.keys.select { |k| requested[k] }
        @game_options.replace(Set.new(newopts))
        return @game_options.to_a
      end                       # def game_options(*args, **kwargs)

      nil
    end                         # module TAGF::Mixin::PackageClassMethods

    # @!macro doc.TAGF.Mixin.ClassMethods.module
    module ClassMethods

      include(Mixin::DTypes)
      include(Mixin::UniversalMethods)
      #
      # Ensure that the definitions in this module also appear in its
      # eigenclass as 'class' methods.
      #
      extend(self)

      #
#      include(TAGF::Mixin::UniversalMethods)

      #
#      include(Contracts::Core)

      #
      # Modules for automatic inclusion for `include`:
      #
      INCLUSION_MODULES	= [
#        TAGF::Mixin::UniversalMethods,
      ]

      #
      # Modules for automatic extension with `extend`:
      #
      EXTENSION_MODULES	= [
        TAGF::Mixin::ClassMethods,
      ]

      # Name of the element key as used in definition (YAML) files.
      #
      attr_accessor(:elkey)

      # @!macro doc.TAGF.module.classmethod.included
      def included(klass)
#       debugger
=begin
        whoami		= format('%s.%s; %s.include(%s)',
                                 self.name,
                                 __method__.to_s,
                                 klass.name,
                                 self.name)
      if (TAGF.debugging?(:include))
        warn(whoami)
        warn(format('  %s.include(%s) processed',
                    klass.name,
                    self.name))
        #
        # Include any missing required modules into the invoking class.
        #
        warn(format('  %s.included_modules=%s',
                    klass.name,
                    klass.included_modules.to_s))
        warn(format('  %s.ancestors=%s',
                    klass.name,
                    klass.ancestors.to_s))
      end
=end
        INCLUSION_MODULES.each do |minc|
          unless (klass.included_modules.include?(minc) \
                  || klass.ancestors.include?(minc))
=begin
          if (TAGF.debugging?(:include))
            warn(format('  also including %s into %s',
                        minc.name,
                        self.name))
          end
=end
            klass.include(minc)
          end
        end

        EXTENSION_MODULES.each do |minc|
          unless (klass.singleton_class.included_modules.include?(minc) \
                  || klass.singleton_class.ancestors.include?(minc))
=begin
          if (TAGF.debugging?(:extend))
            warn(format('  also extending %s with %s',
                        klass.name,
                        minc.name))
          end
=end
#          debugger
            klass.extend(minc)
          end
        end                     # EXTENSION_MODULES.each do

        super
        return nil
      end                       # def included(klass)

      # @!macro doc.TAGF.module.classmethod.extended
      def extended(klass)
=begin
#       debugger
        whoami		= format('%s#%s; %s.extend(%s)',
                                 self.name,
                                 __method__.to_s,
                                 klass.name,
                                 self.name)
      if (TAGF.debugging?(:extend))
        warn(whoami)
      end
=end
        super
        return nil
      end                       # def extended(klass)

      nil
    end                         # module TAGF::Mixin::ClassMethods

    nil
  end                           # module TAGF::Mixin
  #

  nil
end                             # module TAGF

# Local Variables:
# mode: ruby
# indent-tabs-mode: nil
# eval: (if (intern-soft "fci-mode") (fci-mode 1))
# eval: (auto-fill-mode 1)
# End:
