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

require('cri')
require('ostruct')
require('shellwords')
require('byebug')

# @!macro doc.TAGF.module
module TAGF

  # @!macro doc.TAGF.CLI.module
  module CLI

    # Global (well, within the TAGF::CLI module) hash of command names
    # and parsing structures for the `cri` gem.
    Commands		= {}

    # @!macro doc.TAGF.CLI.module.eigenclass
    class << self

      # Import the TAGF::CLI::Commands command hash into the
      # eigenclass, where the command processing methods reside.
      Commands		= TAGF::CLI::Commands

      # @!method command(cmd_p, &block)
      #
      # @param [String]			cmd_p
      # @yield [cdef]
      #   The skeleton Cri::Command object created by this method.
      #   The block gives the caller the opportunity to set up the
      #   command, such as the description, flags, and options.
      # @yieldreturn [Cri::Command]
      #   The Cri::Command object created by the method and configured
      #   by the block.
      # @return [Cri::Command]
      def command(cmd_p, &block)
	Commands[cmd_p]	= Cri::Command.define { |cdef|
	  cdef.name(cmd_p)
	  yield(cdef)
          cdef
	}
	return Commands[cmd_p]
      end                       # def command

      def subcommand(cmd_p, **options, &block)
	cmdsegs		= cmd_p.split(%r!\s+!)
	cmdgroup	= cmdsegs.pop
	(name, *alii)	= cmdgroup.split(%r!\|!)
	if (cmdsegs.empty?)
	  parent	= :root
	  key		= name
	else
	  parent	= cmdsegs.compact.join('~')
	  key		= [ parent, name ].compact.join('~')
	end
        debugger
	result		= CLI.command(key) do |cdef|
	  cdef.name(name)
	  cdef.aliases(alii) unless (alii.empty?)
	  yield(cdef, name, cmdgroup)
	end
	unless ((name == 'help') \
		|| (options.key?(:help_subcommand) \
		    && (! options[:help_subcommand])))
	  Commands[key].add_command(Commands['help'].dup)
	end
	unless (parent.nil?)
	  Commands[parent].add_command(Commands[key])
	end
        return result
      end                       # def subcommand

      def cmdpath(cmd_p)
	cmd		= cmd_p.dup
	segments	= []
	while (cmd)
	  segments.unshift(cmd.name)
	  cmd		= cmd.supercommand
	end
	result		= segments.join(' ')
	return result
      end                       # def cmdpath

      nil
    end                         # Eigenclass for TAGF::CLI module

    nil
  end                           # module TAGF::CLI

  nil
end                             # module TAGF

# Local Variables:
# mode: ruby
# indent-tabs-mode: nil
# eval: (if (intern-soft "fci-mode") (fci-mode 1))
# eval: (auto-fill-mode 1)
# End:
