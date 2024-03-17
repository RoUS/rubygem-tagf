#! /usr/bin/env ruby
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

require('bundler')
Bundler.setup
require('tagf')
require('tagf/exceptions')
require('byebug')

# @!macro doc.TAGF.module
module TAGF

  # @!macro doc.TAGF.Tools.module
  module Tools

    include(TAGF::Exceptions)

    module Definitions

      extend(Forwardable)

      # A `#maxlevel` of `-2` is intended to mean that all messages
      # should be suppressed unless they're reporting actual severe
      # issues.
      SUPPRESS_REPORTS		= -2

      # A `#maxlevel` of `-1` is used to suppress reporting of any
      # messages that aren't dealing with actual error conditions, as
      # opposed to detailed 'what's going on' debugging into.
      REPORT_ONLY_ERRORS	= -1

      # Verbosity level to be attached to a call to Reporter#report
      # when the message is about a legitimate error rather than just
      # verbose debugging info.
      ERROR_REPORT		= REPORT_ONLY_ERRORS

      def_delegators(TAGF::Tools, :logger, :logger=)

      nil
    end                         # module TAGF::Tools::Definitions

    # @!attribute [rw] logger
    # When configured, the TAGF::Tools.logger attribute provides an
    # application-wide means of reporting messages to `stderr`.
    # Typically, is it set up when an instance of
    # TAGF::Tools::Reporter is instantiated with a keyword argument of
    # `install: true`, but it can be directly installed at any time by
    # setting the attribute directly.
    #
    # @example Setting as part of creating a new Reporter
    #   TAGF::Tools::Reporter.new(install: true)
    # @example Installing after Reporter creation
    #   reporter = TAGF::Tools::Reporter.new(maxlevel: 4)
    #   TAGF::Tools.logger = reporter
    # 
    # @return [TAGF::Tools::Reporter]
    attr_accessor(:logger)
    module_function(:logger)
    module_function(:logger=)

    # Class 
    class Reporter

      include(TAGF::Exceptions)
      include(TAGF::Tools::Definitions)

      # @!attribute [rw] component
      #
      # Component for which loggingg is being performed.  If
      # non-`nil`, it will be prefixed as
      # <tt>"<<em>component</em>>: #"</tt> to each message emitted,
      # This can be disabled on a case-by-case basis by including
      # `component: false` in the #report `kwargs`.
      #
      # @return [String]
      attr_accessor(:component)

      # @!attribute [rw] maxlevel
      #
      # @return [Integer]
      attr_accessor(:maxlevel)

      # @!attribute [r] severities
      #
      # @return [Hash<Integer=>Integer>]
      attr_reader(:severities)

      # @!method reset(**kwargs)
      #
      # @param [Hash<Symbol=>Any>]	kwargs
      # @option kwargs [Integer]	:maxlevel
      #
      # @return [Boolean]
      def reset(**kwargs)
        @maxlevel	= kwargs[:maxlevel] || 0
        @severities	= SEVERITY_LEVELS.inject({}) { |memo,level|
          memo[level]	= 0
          memo
        }
        return true
      end                       # def reset

      # @!method increment_severity(level)
      #
      # @param [Integer,Symbol] level
      #
      # @return [void]
      def increment_severity(level)
        #
        # See if we were passed a symbolic level, like `:info`, rather
        # than a numeric one.
        #
        if (level.respond_to?(:severity))
          level		= level.severity
        elsif (level.kind_of?(Symbol))
          level		= SEVERITY.send(level) || SEVERITY.success
        end
        #
        # If the severity level is valid, increment the counter for
        # that severity.
        #
        if (@severities.keys.include?(level))
          @severities[level] += 1
          return @severities[level]
        end
        return nil
      end

      # @!attribute [r] worst_severity
      #
      # @return [Integer]
      def worst_severity
        worst		= 0
        @severities.each do |sev,num|
          worst		= [sev, worst].max unless (num.zero?)
        end
        return worst
      end                       # def worst_severity

      # @!method report(*args, **kwargs)
      #
      # @param [Array]			args
      # @param [Hash<Symbol=>Any>]	kwargs
      # @option kwargs [Integer]	:level
      # @option kwargs [String]		:message
      # @option kwargs [Boolean]	:prefix
      # @option kwargs [String]		:component
      # @option kwargs [String]		:format
      # @option kwargs [Array]		:fmtargs
      #
      # @return [void]
      def report(*args, **kwargs)
        return nil if (self.maxlevel <= SUPPRESS_REPORTS)
        if (args[0].kind_of?(Integer))
          msglevel	= args.shift
        end
        if ((kwlevel = kwargs[:level]).kind_of?(Integer))
          msglevel	= kwlevel
        end
        if (msglevel < self.maxlevel)
          #
          # All right, this message is eligible for reporting.  Now
          # just figure out what the message *is*.
          #
          if (kwargs.fetch(:prefix, true))
            pfx		= kwargs[:component] || self.component
            if (pfx.kind_of?(String) &&
                (! pfx.empty?))
              msg	= pfx + ': '
            end
          else
            msg		= ''
          end
          if (fmt = kwargs[:format])
            fmt		= msg + fmt
            #
            # If we were passed a format string, use it (and any
            # arguments supplied for it) to generate the message text.
            #
            if (fmtargs = kwargs[:fmtargs])
              msg	= format(fmt, *fmtargs)
            else
              msg	= format(fmt)
            end
          elsif (kwargs[:message])
            #
            # No formatting; see if the keyword args include a string
            # to use.
            #
            msg		+= kwargs[:message]
          else
            #
            # If all else fails, use the first positional argument we
            # were passed.  Make sure we stringify it just in case
            # it's not a string, or nothing was passed at all.
            #
            msg		+= args[0].to_s
          end
          warn(msg)
          #
          # Reporting a thing includes the possibility of recording
          # its severity
          if ((sev = kwargs[:severity]).kind_of?(Integer))
            self.increment_severity(sev)
          end
        end
        return nil
      end                       # def report(*args, **kwargs)

      # @!method initialize(*args, **kwargs)
      # Constructor for TAGF::Tools::Reporter class.
      #
      # @param [Array]			args
      # @param [Hash<Symbol=>Any>]	kwargs
      # @option kwargs [String]		:component	(nil)
      #   Name of the tool or component that should be prefixed to
      #   every message string by default.
      # @option kwargs [Boolean]	:install	(false)
      #   Whether or not the new Reporter instance should be installed
      #   in the module-wide TAGF::Tools#logger attribute.
      # @option kwargs [Integer]	:maxlevel	(0)
      #   The maximum detail level of messages to be reported.  A
      #   value of -
      def initialize(*args, **kwargs)
        self.reset
        self.logger	= self if (kwargs[:install])
        if (kwargs[:quiet])
          self.maxlevel	= SUPPRESS_REPORTS
        else
          self.maxlevel	= (kwargs[:maxlevel] || 0).to_i
        end
        self.component	= kwargs.fetch(:component, nil)
      end                       # def initialize

      nil
    end                         # class Reporter

    nil
  end                           # module Tools

end                             # module TAGF

# Local Variables:
# mode: ruby
# indent-tabs-mode: nil
# eval: (if (intern-soft "fci-mode") (fci-mode 1))
# eval: (auto-fill-mode 1)
# End:
