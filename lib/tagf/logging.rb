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

    attr_accessor(:logger)
    module_function(:logger)
    module_function(:logger=)

    class Reporter

      include(TAGF::Exceptions)

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
      # @option kwargs [String]		:format
      # @option kwargs [Array]		:fmtargs
      #
      # @return [void]
      def report(*args, **kwargs)
        return nil if (self.maxlevel < 0)
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
          msg		= ''
          if (fmt = kwargs[:format])
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
            msg		= kwargs[:message]
          else
            #
            # If all else fails, use the first positional argument we
            # were passed.  Make sure we stringify it just in case
            # it's not a string, or nothing was passed at all.
            #
            msg		= args[0].to_s
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

      def initialize(*args, **kwargs)
        self.reset
        if (kwargs[:quiet])
          self.maxlevel	= -1
        else
          self.maxlevel	= (kwargs[:maxlevel] || 0).to_i
        end
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
