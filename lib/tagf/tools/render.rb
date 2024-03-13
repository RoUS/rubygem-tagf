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
      output_default	= ''
      if (game = kwargs[:game])
        #
        # If we're working from a Game object, the default output
        # filename is the EID.
        #
        output_default	= game.eid
      elsif (source = kwargs[:source])
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
      # Assume we're going to be successful.
      #
      result		= Errno::NOERROR.new.errno
      catch(:render_done) do
        #
        # If we're given a bogus graphic format, gritch about it.
        #
        unless (GraphViz::Constants::FORMATS.include?(gformat))
          badfmtmsg	= 'unknown/unsupported graphic format "%s"'
          badfmtexc	= RuntimeError.new(format(badfmtmsg, gformat))
          warn(format('%s, %s', badfmtexc.class.to_s, badfmtmsg))
          result	= -1
          throw(:render_done)
        end
        begin
          #
          # There may be something bogus in the game itself, or the
          # graph processing might raise an exception.
          #
          game.graphinfo.assemble
          game.graphinfo.graph.write_to_graphic_file(gformat, output)
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
            'Increase verbosity',
            multiple:	true)
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
              default:	'png')

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
    warn(format("%s.%s\n  opts = %s\n  args = %s\n  cmd  = %s",
                self.respond_to?(:name) ? self.name : self.class.to_s,
                __callee__.to_s,
                opts.inspect,
                args.inspect,
                cmd.inspect))
    result
  end
end

# Local Variables:
# mode: ruby
# indent-tabs-mode: nil
# eval: (if (intern-soft "fci-mode") (fci-mode 1))
# eval: (auto-fill-mode 1)
# End: