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
require('tagf/cli')
require('tagf/exceptions')
require('tagf/filer')
require('logger')
require('pathname')
require('rgl/dot')
require('ruby-graphviz')
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

      attr_accessor(:level)

      def report(*args, **kwargs)
        return nil if (self.level < 0)
        if (args[0].kind_of?(Integer))
          msglevel	= args.shift
        end
        if ((kwlevel = kwargs[:level]).kind_of?(Integer))
          msglevel	= kwlevel
        end
        if (msglevel < self.level)
          warn(args[0])
        end
        return nil
      end                       # def report(*args, **kwargs)

      def initialize(*args, **kwargs)
        if (kwargs[:quiet])
          self.level	= -1
        else
          self.level	= (kwargs[:level] || 0).to_i
        end
      end                       # def initialize

      nil
    end                         # class Reporter

    #
    # Given a TAGF game definition, use the internal RGL digraph to
    # render it into an image file.
    #
    # Invisible Location and Path elements are depicted in red, with
    # the paths using dashed rather than solid lines.
    #
    # Path elements which are marked reversible use a single arrowhead
    # to retain the indication of the main direction.  If a path is
    # <em>not</em> reversible, a double-arrowhead is used to emphasise
    # that it's a one-way-only path.  So:
    #
    # * One arrowhead (`→`)
    # : The path is reversible, and commands for 'go back' will
    #   backtrace along it.
    # * Double arrowhead (`↠`)
    # : The path is IRreversible; once followed, 'go back' commands
    #   won't return along it.
    #
    # Paths which are sealable (`kind_of?(TAGF::Mixin::Sealable)`)
    # <em>and</em> openable will be annotated with either a door "🚪"
    # (if not lockable) or a padlock.  If it's locked, a padlock & key
    # "🔐" will be used; if it's unlocked, an open padlock "🔓" will
    # be used.
    #

    # @!method validate(**kwargs)
    # Generate a graphic depiction of the game map, either from an
    # actual game object or from a `YAML` file defining it.  The
    # format of the image and the name of the output file are
    # controllable through the `kwargs` key values.
    #
    # @param [Hash<Symbol=>Any> kwargs
    # @option kwargs [TAGF::Game]	:game
    # @option kwargs [String]		:source
    # @option kwargs [String]		:format		"png"
    # @option kwargs [String]		:output
    #
    # @return [Integer]
    #   Exit code (on success, Errno::NOERROR.new.errno (zero)).  On
    #   failure, either -1 or whatever exception processing delivers.
    def validate(**kwargs)
      verbosity		= kwargs[:verbosity].to_i
      verbosity		= -2 if kwargs[:quiet]
      logger		= Reporter.new(level: verbosity)
      worst_severity	= Exceptions::SEVERITY.success
      #
      # What are we validating?
      #
      if (game = kwargs[:game])
        logger.report(format('validating pre-loaded game "%s"',
                             game.eid),
                      level:	1)
      elsif (source = kwargs[:source])
        logger.report(format('validating game loaded from "%s"',
                             source),
                      level:	1)
        #
        # If we're working from a source file, then the default output
        # filename is derived from the source minus any extension.
        #
        filer		= TAGF::Filer.new
        game		= filer.load_game(source)
      end
      #
      # Okey, we need to digraph info, so build it.
      #
      begin
        #
        # There may be something bogus in the game itself, or the
        # graph processing might raise an exception.
        #
        game.graphinfo.assemble
      rescue StandardError => exc
        #
        # For now, this is essentially a no-op.  However, we might
        # do this more elaborately later.
        #
        result		= 1
        raise
      end
      #
      # Assume we're going to be successful.
      #
      result		= Errno::NOERROR.new.errno
      #
      # Start the validation.
      #
      # @todo
      #   Do we want to scan by element type, or by type of problem?
      #   If two Locations have the same two problems, do we want to
      #   group them by problem or by location?  (Probably the
      #   latter.)
      #
      logger.report('Beginning validation scan..',
                    level:	2)
      #
      # Scan for totally inaccessible locations (exclusive of
      # shortcuts or magic).
      #
      #
      # Location issues we want to mention include:
      #  * no paths leading in or out
      #  * only paths leading in, and none are reversible
      #
      logger.report('Scanning locations..',
                    level:	3)
      #
      # Look for Locations with no neighbours.
      #
      logger.report('Looking for inaccessible locations..',
                    level:	4)
      #
      # Look for all Locations that aren't mentioned as an origin nor
      # as a destination in any Path.
      #
      noaccess		= game.filter(klass: Location).select { |obj|
        (obj.incoming.empty? &&
         obj.outgoing.empty?)
      }
      #
      # If there were any, write 'em up.
      #
      noaccess.each do |obj|
        msg		= NoAccess.new(location: obj)
        worst_severity	= [worst_severity, msg.severity].max
        logger.report(msg.render,
                      level:	-1)
      end
      #
      # Now look for Locations with ways in — but no ways out (all
      # incoming paths are irreversible).
      #
      logger.report('Looking for dead ends..',
                    level:	4)
      #
      # Look for all Locations that have no departure paths, and any
      # entry paths are irreversible.
      #
      deadends		= game.filter(klass: Location).select { |obj|
        (obj.outgoing.empty? &&
         obj.incoming.all? { |p| p.irreversible? })
      }
      #
      # If there were any, write 'em up.
      #
      deadends.each do |obj|
        msg		= NoExit.new(location: obj)
        worst_severity	= [worst_severity, msg.severity].max
        logger.report(msg.render,
                      level:	-1)
      end
      #
      # Sealable issues we want to mention include:
      #  * All `seal_key` identifiers are listed as keywords
      #  * All `seal_key` identifiers are the EIDs of Portable Items
      #
      logger.report('Scanning sealable elements..',
                    level:	3)
      sealables		= game.filter.select { |obj|
        (obj.mixins.include?(TAGF::Mixin::Sealable) &&
         obj.respond_to?(:seal_key) &&
         (! obj.seal_key.nil?))
      }
      nokeyword		= sealables.select { |obj|
        game.keyword(obj.seal_key).nil?
      }
      #
      # If there were any, write 'em up.
      #
      nokeyword.each do |obj|
        msg		= NoSealKeyword.new(sealable: obj)
        worst_severity	= [worst_severity, msg.severity].max
        logger.report(msg.render,
                      level:	-1)
      end
      #
      # Check for seal_keys which aren't items.
      # @todo
      #   Need to check for Portable mixin.
      #
      noitem		= sealables.select { |obj|
        game.filter(klass: TAGF::Item, eid: obj.seal_key).count.zero?
      }
      #
      # If there were any, write 'em up.
      #
      noitem.each do |obj|
        msg		= NoSealKeyItem.new(sealable: obj)
        worst_severity	= [worst_severity, msg.severity].max
        logger.report(msg.render,
                      level:	-1)
      end
      #
      # Now check the paths between locations.
      #
      game.filter(klass: Path).each do |obj|
        logger.report(format('Scanning path %s',
                             obj.to_key),
                      level:	4)
      end
      return worst_severity - 1
    end                         # def validate(**kwargs)
    module_function(:validate)

    nil
  end                           # module Tools

end                             # module TAGF

TAGF::CLI.subcommand('help validate') do |cdef,**opts|
  cdef.summary('Check the validity of a game structure.')
  cdef.run do |opts,args,cmd|
    subcmd		= [cmd.name, *args].compact.join('~')
    puts(Commands[subcmd].help)
    Errno::NOERROR.new.errno
  end
end

TAGF::CLI.command('validate') do |cdef,**opts|
  cdef.summary('Validate TAGF game structure.')
  cdef.usage('validate [options] [sourcefile]')
  cdef.description(<<-EOT)
The `validate` command loads a TAGF game from its YAML file
and checks for inconsistencies, like inaccessible locations,
locked items with no keys defined, &c.

The name of the YAML file to check is either passed as an
argument, or as the value of the `--source` option.  If both
are specified, the latter overrides the former.
  EOT

  cdef.flag(:h, :help, 'Display command help') do |value,cmd|
    puts(cmd.help)
    exit(0)
  end
  cdef.flag(:v,
            :verbose,
            'Each occurrence increases detail of reporting',
            multiple:	true)
  cdef.flag(:q,
            :quiet,
            'Suppress *all* messages')
  cdef.option(:s,
              :source,
              ('game source YAML file ' +
               '(overrides `sourcefile` parameter)'),
              argument:	:required)

  cdef.run do |opts,args,cmd|
    if (val = opts.delete(:quiet))
      opts[:verbosity]	= -1
    else
      opts[:verbosity]	= [*opts.delete(:verbose)].count
    end
    input		= opts[:source] || args[0]
    if (input.nil?)
      warn(format('%s: %s: source file not specified ' +
                  '(parameter or --source required)',
                  Pathname($0).basename,
                  cmd.name))
      exit(TAGF::Exceptions::NoLoadFile.errorcode)
    end
    opts[:source]	= input
    result		= TAGF::Tools.validate(**opts)
    result
  end
end

# Local Variables:
# mode: ruby
# indent-tabs-mode: nil
# eval: (if (intern-soft "fci-mode") (fci-mode 1))
# eval: (auto-fill-mode 1)
# End:
