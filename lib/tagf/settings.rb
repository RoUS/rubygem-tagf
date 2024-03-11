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
require('tagf/exceptions')
require('ostruct')
require('byebug')

# @!macro doc.TAGF.module
module TAGF

  # Class encapsulating settings specific to a particular game
  # instance.
  class Settings

    include(TAGF::Mixin::DTypes)
    include(TAGF::Mixin::UniversalMethods)

    class << self

      # @!method invalid_settings(*args, **kwargs)
      #
      # @param [Hash<Symbol=>Any>]	kwargs
      # @option kwargs [Boolean]	:report
      #
      # @return [Array<Symbol>]
      #   List of symbolised setting names from args and kwargs that
      #   <strong>don't</strong> appear in
      #   {Mixin::UniversalMethods::GAME_OPTIONS}.
      # @return [nil]
      #   if all if the keywords are valid game setting names.
      def invalid_settings(*args, **kwargs)
        result		= nil
        report		= kwargs.delete(:report)
        kwlist		= [*args, *kwargs.keys].uniq.compact.map { |k|
          k.to_sym
        }
        kwlist		-= GAME_OPTIONS
        result		= kwlist.empty? ? nil : kwlist
        if (result && report)
          warn(format('%s.%s: ignoring invalid game setting(s): %s',
                      self.class.to_s,
                      __callee__.to_s,
                      ivkwlist.map { |kw|
                        kw.to_sym.inspect
                      }.join(', ')))
        end
        return result
      end                       # def invalid_settings

      nil
    end                         # Eigenclass for TAGF::Settings

    def invalid_settings(*args, **kwargs)
      result		= self.class.invalid_settings(*args, **kwargs)
      return result
    end                         # def invalid_settings

    # @!attribute [r] flags
    # Record of the defined game flags (on/off settings) that are
    # currently enabled.  Absence from the set means the setting is
    # disabled.
    #
    # @return [Set<Symbol>]
    #   a set of game flags which are set/enabled.  Absence from the
    #  set means that the flasg <em>isn't</em> enabled.
    attr_reader(:flags)

    # @!attribute [r] settings
    # @result [Hash]
    #   the non-Boolean game settings and their values.
    attr_reader(:settings)

    #
    # The game flags, flag groups, and valued settings are all defined
    # in TAGF::Mixin::UniversalMethods.
    GAME_FLAGS.each do |fsym|
      fstr		= fsym.to_s
      getter		= fsym
      query		= format('%s?', fstr).to_sym
      forcer		= format('%s!', fstr).to_sym
      setter		= format('%s=', fstr).to_sym
      define_method(getter) do
        return self.flags.include?(fsym)
      end
      alias_method(query, getter)
      define_method(forcer) do
        self.flags.add(fsym)
        return true
      end
      define_method(setter) do |onoff|
        if (truthify(onoff))
          self.flags.add(fsym)
        else
          self.flags.delete(fsym)
        end
        return self.send(getter)
      end
    end                         # GAME_FLAGS.each do

    GAME_FLAG_GROUPS.each do |fsym,group|
      if (badsettings = self.invalid_settings(*group, report: true))
        group		-= badsettings
      end
      fstr		= fsym.to_s
      getter		= fsym
      query		= format('%s?', fstr).to_sym
      forcer		= format('%s!', fstr).to_sym
      setter		= format('%s=', fstr).to_sym
      define_method(getter) do
        return [*group].all? { |flag| self.flags.include?(flag) }
      end
      alias_method(query, getter)
      define_method(forcer) do
        self.flags.replace(self.flags.merge([*group]))
        return true
      end
      define_method(setter) do |onoff|
        if (truthify(onoff))
          self.flags		|= [*group]
        else
          self.flags		-= [*group]
        end
        return self.send(getter)
      end
    end                         # GAME_FLAG_GROUPS.each do

    #
    # Check to see whether one or more game options are currently
    # enabled.  If any arguments aren't recognised as game options,
    # a warning is sent to `stderr` and that argument is ignored.
    #
    # @param [Symbol] option
    # @param [Array<Symbol>] args
    # @return [Boolean]
    #   `true` if **all** of the requested options are currently
    #   enabled.
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

    # @!method export_settings
    #
    # @return [Hash<String=>Hash>]
    #   a one-key (`"settings"`) hash of all of the defined game
    #   settings, flags and values alike, in a form suitable for
    #   inclusion in a larger hash for eventiual exportation as YAML.
    def export_settings
      result		= {}
      tflags		= self.flags.dup
      #
      # Go through the grouped flags.  If any of the groups has all
      # member flags set or clear, include the group name in the
      # export hash and remove the individual member flags from
      # further consideration.
      #
      game_flags	GAME_FLAGS.dup
      GAME_FLAG_GROUPS.each do |cname,group|
        if (group.all? { |f| tflags.include?(f) })
          result[cname.to_s] = true
          game_flags.each { |f| tflags.delete(f) }
        elsif (group.none? { |f| tflags.include?(f) })
          result[cname.to_s] = false
          game_flags.each { |f| tflags.delete(f) }
        end
      end
      #
      # Go through the individual flag settings and include the
      # Boolean settings in the result hash.  Any that have been set
      # or cleared as part of the group analysis will have already
      # been removed from the list to export, and thus won't be
      # exported individually as well as part of a group.
      #
      game_flags.each do |flag|
        result[flag.to_s] = (tflags.include?(flag))
      end
      #
      # Now process the settings with non-Boolean values.
      #
      GAME_SETTINGS.each do |sname,svalue|
        result[sname.to_s] = svalue
      end
      return { 'settings' => result }
    end                         # def export

    # @!method process_flags(**kwargs)
    #
    # @param [Hash<Symbol=>Boolean>]	kwargs
    # @option kwargs [Boolean]		<em>any</em>
    #   See {UniversalMethods::GAME_FLAGS} and
    #   {UniversalMethods::GAME_FLAG_GROUPS} for possible keywords.
    #
    # @return [void]
    def process_flags(**kwargs)
      kwargs		= symbolise_kwargs(kwargs)
      if (ivkwlist = self.invalid_settings(**kwargs, report: true))
        #
        # We were given something unknown or undefined; complain and
        # then remove them from future processing.
        #
        warn(format('%s.%s: ignoring invalid game setting(s): %s',
                    self.class.to_s,
                    __callee__.to_s,
                    ivkwlist.map { |kw|
                      kw.to_sym.inspect
                    }.join(', ')))
        ivkwlist.each { |ikw| kwargs.delete(ikw) }
      end
      #
      # If a flag name is a key in `kwargs`, the truthiness (see
      # the #truthify method) of its value controls whether the flag
      # is explicitly added or removed from the settings.  This allows
      # this method to be used at Settings initialisation, or later to
      # change existing settings.
      #
      # Do the grouped flags first, turning on any named groups first
      # so that selective DISabling of group members can be properly
      # handled.
      #
      GAME_FLAG_GROUPS.each do |cname,group|
        next unless (kwargs.has_key?(cname))
        if (truthify(kwargs[cname]))
          @flags	|= group
        else
          @flags	-= group
        end
        kwargs.delete(cname)
      end
      #
      # Now handle the individual flags, potentially changing settings
      # applied by group arguments.
      #
      GAME_FLAGS.each do |flag|
        next unless (kwargs.has_key?(flag))
        if (truthify(kwargs[flag]))
          @flags.add(flag)
        else
          @flags.delete(flag)
        end
        kwargs.delete(flag)
      end
      return nil
    end                         # def process_flags(**kwargs)

    # @!method process_settings(**kwargs)
    #
    # @param [Hash<Symbol=>any>]	kwargs
    # @option kwargs [Any]		<em>any</em>
    #   See {UniversalMethods::GAME_SETTINGS} for possible keywords.
    #
    # @return [void]
    def process_settings(**kwargs)
      kwargs		= symbolise_kwargs(kwargs)
      if (ivkwlist = self.invalid_settings(**kwargs))
        #
        # We were given something unknown or undefined; complain and
        # then remove them from future processing.
        #
        warn(format('%s.%s: ignoring invalid game setting(s): %s',
                    self.class.to_s,
                    __callee__.to_s,
                    ivkwlist.map { |kw|
                      kw.to_sym.inspect
                    }.join(', ')))
        ivkwlist.each { |ikw| kwargs.delete(ikw) }
      end
      kwargs.each do |kw,value|
        self.settings[kw] = value
      end
      return nil
    end                         # def process_settings(**kwargs)

    # @method method_missing(mname, *args, **kwargs)
    # Handle flags and settings as though they have their own
    # accessors.  Syntax-check the calls accordingly.
    #
    # @return [Any]
    def method_missing(mname, *args, **kwargs)
      mname_s		= mname.to_s
      suffix		= mname_s.sub(%r!^.*?([^_[:alnum:]])$!, '\1')
      basename		= mname_s.sub(%r!#{suffix}$!, '')
      basename_sym	= basename.to_sym
      catch(:badsetting) do
        unless (GAME_OPTIONS.include?(basename_sym))
          throw(:badsetting)
        end
        if (GAME_SETTINGS.include(basename_sym))
          suffixes	= [ '', '=' ]
          unless (suffixes.include?(suffix))
            throw(:badsetting)
          end
          if (suffix == '=')
            #
            # @todo
            #   need to verify args.count == 1
            #
            self.settings[basename_sym] = args[0]
          end
          result	= self.settings[basename_sym]
        else
          #
          # It's a flag.  We recognise '', '!', '=', and '?' as
          # suffixes.
          #
          suffixes	= [ '', '=', '!', '?' ]
          unless (suffixes.include?(suffix))
            throw(:badsetting)
          end
          #
          # `flag`? and `flag` just fall through to the 'is this set
          # or not?' final action.  So no need to include them in the
          # case.
          #
          case(suffix)
          when '!'
            self.flags.add(basename_sym)
          when '='
            #
            # @todo
            #   need to verify args.count == 1
            #
            if (truthify(args[0]))
              self.flags.add(basename_sym)
            else
              self.flags.delete(basename_sym)
            end
          end
          result	= self.flags.include?(basename_sym)
        end
        return result
      end                       # catch(:badsetting)
      raise_exception(NoMethodError,
                      format('undefined method `%s`',
                             mname_s))
    end                         # def method_missing

    # Constructor for the settings class.
    # @param [Hash<Symbol=>Boolean>]	kwargs
    # @option kwargs [Boolean]		<em>any</em>
    #   See {UniversalMethods::GAME_FLAGS} and
    #   {UniversalMethods::GAME_FLAG_GROUPS} for possible keywords.
    #
    # @return [void]
    def initialize(**kwargs)
      kwargs		= symbolise_kwargs(kwargs)
      @flags		= Set.new
      @settings	= {}
      #
      # First, do the flags — Boolean on/off settings.
      #
      self.process_flags(**kwargs)
      #
      # Remove the flag settings from our keyword arguments; what keys
      # remain should be those that take a particular value as opposed
      # to a yes/no option.
      #
      GAME_FLAGS.each { |f| kwargs.delete(f) }
      #
      # Now do the settings that have values, like player hitpoints
      # and such.
      #
      self.process_settings(**kwargs)
      return nil
    end			# def initialize(**kwargs)

    nil
  end				# class Settings

  nil
end				# module TAGF

# Local Variables:
# mode: ruby
# indent-tabs-mode: nil
# eval: (if (intern-soft "fci-mode") (fci-mode 1))
# eval: (auto-fill-mode 1)
# End:
