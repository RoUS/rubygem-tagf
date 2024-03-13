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
require('tagf/filer')
require('pathname')
require('rgl/dot')
require('ruby-graphviz')
require('byebug')

# @!macro doc.TAGF.module
module TAGF

  # @!macro doc.TAGF.Tools.module
  module Tools

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
        output_default	= same.to_s.sub(%r!#{sname.extname}$!, '')
      end
      #
      # And if there's an explicit output filename, it dominates, of
      # course.
      #
      output		= kwargs[:output] || output_default
      gformat		= kwargs[:format] || 'png'
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
        #
        # Assume we're going to be successful.
        #
        result		= Errno::NOERROR.new.errno
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
    end                         # def run(**kwargs)
    module_function(:render)

    nil
  end                           # module Tools

end                             # module TAGF

# Local Variables:
# mode: ruby
# indent-tabs-mode: nil
# eval: (if (intern-soft "fci-mode") (fci-mode 1))
# eval: (auto-fill-mode 1)
# End:
