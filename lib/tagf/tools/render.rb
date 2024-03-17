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
require('tagf/logging')
require('abbrev')
require('pathname')
require('rgl/dot')
require('ruby-graphviz')
require('byebug')

# @!macro doc.TAGF.module
module TAGF

  # @!macro doc.TAGF.Tools.module
  module Tools

    include(TAGF::Exceptions)

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

    Orientations	= Abbrev.abbrev([
                                          'portrait',
                                          'landscape',
                                        ])

    # @!method render(**kwargs)
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
    def render(**kwargs)
      verbosity		= kwargs[:verbosity].to_i
      verbosity		= SUPPRESS_REPORTS if (kwargs[:quiet])
      logger		= Reporter.new(maxlevel:  verbosity,
                                       component: __callee__.to_s)
      output_default	= ''
      if (game = kwargs[:game])
        logger.report(format('validating pre-loaded game "%s"',
                             game.eid),
                      level:	1)
        #
        # If we're working from a Game object, the default output
        # filename is the EID.
        #
        output_default	= game.eid
      elsif (source = kwargs[:source])
        logger.report(format('preparing to render game ' +
                             'loaded from "%s"',
                             source),
                      level:	1)
        #
        # If we're working from a source file, then the default output
        # filename is derived from the source minus any extension.
        #
        output_default	= source
        filer		= TAGF::Filer.new
        game		= filer.load_game(source)
        sname      	= Pathname(source)
        output_default	= sname.to_s.sub(%r!#{sname.extname}$!, '')
      end
      #
      # And if there's an explicit output filename, it dominates, of
      # course.
      #
      output		= kwargs[:output] || output_default
      gformat		= kwargs[:format] || 'png'
      #
      # If the user specified a file with the graphic format as the
      # extension, strip it off, since the graph-writing code
      # unconditionally adds it.
      #
      output		= output.sub(%r!\.#{gformat}$!, '')
      #
      # Assume we're going to be successful.
      #
      result		= Errno::NOERROR.new.errno
      catch(:render_done) do
        begin
          #
          # There may be something bogus in the game itself, or the
          # graph processing might raise an exception.
          #
          logger.report(format('building game digraph for "%s"',
                               game.to_key),
                        level:	2)
          game.graphinfo.assemble
          #
          # Fill in any graph-wide options (which use a hash with
          # string keys, not symbols) from what we've collected.
          #
          # The internal name of the graph is *always* the game's EID.
          #
          logger.report('applying graph-wide attributes',
                        level:	3)
          dotoptions	= {
            'name'	=> game.eid,
          }
          #
          # If the user specified a name on the command line (or in
          # the options kwargs if invoked any other way), it's meant
          # to be as the graph's label.
          #
          if (optval = kwargs[:name])
            dotoptions['label'] = optval
          end
          #
          # The orientation can be either landscape or portrait (the
          # default).
          #
          if (optval = kwargs[:orientation])
            optval	= TAGF::Tools::Orientations[optval]
            dotoptions['orientation'] = optval
          end
          #
          # @todo
          #   --pagesize is NYI
          #
          if (optval = kwargs[:pagesize])
            dotoptions['page'] = optval.sub(%r!x!i, ',')
          end
          logger.report(format('writing %s graph rendition to "%s.%s"',
                               gformat.upcase,
                               output,
                               gformat),
                        level:	0)
          game.graphinfo.graph.write_to_graphic_file(gformat,
                                                     output,
                                                     dotoptions)
        rescue StandardError => exc
          #
          # For now, this is essentially a no-op.  However, we might
          # do this more elaborately later.
          #
          result	= 1
          raise
        end
      end                       # catch(:render_done)
      return result
    end                         # def render(**kwargs)
    module_function(:render)

    nil
  end                           # module Tools

end                             # module TAGF

TAGF::CLI.subcommand('help render') do |cdef,**opts|
  cdef.summary('Render an image of a game map.')
  cdef.run do |opts,args,cmd|
    subcmd		= [cmd.name, *args].compact.join('~')
    puts(Commands[subcmd].help)
    Errno::NOERROR.new.errno
  end
end

TAGF::CLI.command('render') do |cdef,**opts|
  
  cdef.summary('Render an image of a game map.')
  cdef.usage('render [options] [sourcefile]')
  cdef.description(<<-EOT)
The `render` command loads a TAGF game from its YAML file
and generates a graphical image of its location map.

The `--output` option will override the default image file
name, which is derived from the source file name (from the
parameter or the `--source` option).  Any final extension
on the source file name is removed and replaced with the
image format.  For example,

*   render --source=foo.yml --format=svg

will produce an output file named `foo.svg`.
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
#  cdef.param(:sourcefile)
  cdef.option(:s,
              :source,
              ('game source YAML file ' +
               '(overrides `sourcefile` parameter)'),
              argument:	:required)
  cdef.option(:o,
              :output,
              'output file name',
              argument:	:required)
  cdef.option(:f,
              :format,
              'image format (e.g., "svg", "png", "jpg")',
              argument:	:optional,
              default:	'png') do |value,cmd|
    #
    # If we're given a bogus graphic format, gritch about it.
    #
    unless (GraphViz::Constants::FORMATS.include?(value))
      badfmtmsg		= 'unknown/unsupported graphic format "%s"'
      badfmtexc		= RuntimeError.new(format(badfmtmsg, value))
      warn(format('%s, %s', badfmtexc.class.to_s, badfmtmsg))
      exit(1)              
    end
  end

  cdef.option(:c,
              :config,
              ('YAML file customising graph display attributes.  ' +
               '(See the "graph-attributes.yml" file in this gem ' +
               'for an example and the defaults.)'),
              argument:	:required)
  cdef.option(:n,
              :name,
              ('Label for the graph as a whole.'),
              argument:	:required)
  cdef.option(nil,
              :orientation,
              ('portrait (default) or landscape.'),
              argument:	:required,
              transform: -> (val) { TAGF::Tools::Orientations[val] }
             ) do |value,cmd|
    unless (optval = TAGF::Tools::Orientations[value])
      warn(format('%s: bad value for orientation: %s',
                  cmd.name,
                  value.inspect))
      exit(1)
    end
    optval
  end

  cdef.run do |opts,args,cmd|
    opts[:verbosity]	= [*opts.delete(:verbose)].count
    input		= opts[:source] || args[0]
    if (input.nil?)
      warn(format('%s: %s: source file not specified ' +
                  '(parameter or --source required)',
                  Pathname($0).basename,
                  cmd.name))
      exit(TAGF::Exceptions::NoLoadFile.errorcode)
    end
    opts[:source]	= input
    result		= TAGF::Tools.render(**opts)
    result
  end
end

# Local Variables:
# mode: ruby
# indent-tabs-mode: nil
# eval: (if (intern-soft "fci-mode") (fci-mode 1))
# eval: (auto-fill-mode 1)
# End:
