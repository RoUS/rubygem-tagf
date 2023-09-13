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
require('tagf')
require('readline')

# @!macro doc.TAGF.module
module TAGF

  # @!macro doc.TAGF.UI.module
  module UI

    HEREDOC_RE		= %r!^
			     <<(-)?
			     (['"])?
			     ([[:alnum:]][-_[:alnum:]]*)
			     (['"])?
			     $!x

    # Method used to check whether a line of input starts a
    # `here-document`.  Primarily intended for use by the
    # administrator command-line and scripting tools, it either
    # returns `false` if there's no `here-doc` indicator, or a
    # structure for use in processing the `here-doc` text lines that
    # follow.
    #
    # @param [String] input
    #   A line of text to be checked for `here-document` inclusion.
    # @raise [RuntimeError]
    #   The `here-doc` termination string was invalid, either in
    #   outright composition or possibly by having mismatched
    #   quotation marks.
    # @return [OpenStruct,false]
    #   * If the last word (as defined by the shell) of the input
    #     parameter <b>does not</b> match a valid `here-doc`
    #     terminator pattern, this method returns `false`.
    #   * If the last word <b>does</b> is a valid `here-doc`
    #     terminator, the return value is a structure with the
    #     following attributes:
    #
    #     * `.interpolate` [Boolean]
    #       (Not currently used.)  Indicates whether the final value
    #       of the `here-doc` should be sujected to variable
    #       interpolation or other post-processing.  If `false`, it
    #       should be treated as a raw string.
    #     * `.term_re` [Reqexp]
    #       A regular expression identifying the format of a line
    #       terminating the `here-doc` text.  It matches the *entire*
    #       line, so no pre-parsing is necessary.
    #
    # @see Here_Documents
    #
    def heredoc?(input)
      words		= Shellwords.split(input)
      if (words.last[0,2] == '<<')
        warn('Possible here-doc')
        if (! (m = words.last.match(HEREDOC_RE)))
          #
          # Doesn't match our allowed pattern.  Don't explain why.
          #
          raise(RuntimeError, 'invalid here-doc suffix syntax')
        end
        #
        # We have a here-doc suffix that matches the pattern..
        #
        if (m.captures[1] != m.captures[3])
          #
          # .. except the '<<{word}' was quoted incorrectly.  Bzzzt!
          #
          raise(RuntimeError,
                'invalid here-suffix (mismatched quotes)')

        end
        warn(format('Here-document ending with «%s»', m.captures[2]))
        result		= OpenStruct.new(
          interpolate:	(! m.capures[1].nil?),
          term_re:	nil
        )
        terminator	= format('^%s%s$',
                                 (m.captures[0] == '-' ? '\s*' : ''),
                                 Regexp.escape(m.captures[2]))
        result.term_re	= Regexp.compile(terminator)
        return result
      end
      return false
    end                         # def heredoc?(input)

    #
    def readline(prompt=nil, **kwargs)
      opts		= kwargs
      opts[:record]	= true unless (opts.has_key?(:record))
      opts[:echo]	= true unless (opts.has_key?(:echo))
      if (opts[:echo] || (! $stdin.tty?))
        if (default = opts[:default])
          Readline.pre_input_hook = ->{
            Readline.insert_text(default)
            Readline.redisplay
            Readline.pre_input_hook = nil
          }
        end
        result		= Readline.readline(prompt || '> ',
                                            opts[:record])
      else
        #
        # Now we're doing a noecho thing, or we're not on a
        # terminal.
        #
        new_sigint	= nil
        new_sigtstp	= nil
        new_sigcont	= nil
        old_sigint	= nil
        old_sigtstp	= nil
        old_sigcont	= nil
        #
        # Save the current terminal configuration
        #
        term		= `stty -g`.chomp
        new_sigint	= Proc.new {
          `stty #{term.shellescape}`
          trap('SIGINT', old_sigint)
          Process.kill('SIGINT', Process.pid)
        }

        new_sigtstp	= Proc.new {
          `stty #{term.shellescape}`
          trap('SIGCONT', new_sigcont)
          trap('SIGTSTP', old_sigtstp)
          Process.kill('SIGTSTP', Process.pid)
        }

        new_sigcont	= Proc.new {
          `stty -echo`
          trap('SIGCONT', old_sigcont)
          trap('SIGTSTP', new_sigtstp)
          Process.kill('SIGCONT', Process.pid)
        }
        #
        # Set all signal handlers
        #
        old_sigint	= trap('SIGINT',  new_sigint)  || 'DEFAULT'
        old_sigtstp	= trap('SIGTSTP', new_sigtstp) || 'DEFAULT'
        old_sigcont	= trap('SIGCONT', new_sigcont) || 'DEFAULT'

        $stdout.print(prompt)
        $stdout.flush
        #
        # Turn off character echo if the driver can't do it through
        # Ruby's #IO.
        #
        input		= nil
        begin
          if ($stdin.respond_to?(:noecho))
            input	= $stdin.noecho(:gets)
          else
            `stty -echo`
            input	= $stdin.gets
          end
          if (input.kind_of?(String))
            input.chomp!
          else
            input	= nil
          end
        ensure
          #
          # Restore terminal settings and handlers
          #
          # @todo
          #   Store echo status above the `stty -noecho` and
          #   restore it here.
          #
          `stty #{term.shellescape}`
          trap('SIGINT',  old_sigint)
          trap('SIGTSTP', old_sigtstp)
          trap('SIGCONT', old_sigcont)
        end
        result		= input
      end
      return result
    end                         # def readline(prompt, opts_p={})

  end                           # module UI

  #
  # Directions, possibly prefixed with `go` (as in `south` or
  # `go south`), and other actions (like `get`, `take`, `drop`,
  # `throw`, and so forth).
  #
  class Verb

    #
    include(Mixin::Element)

    #
    # @return [String]
    #
    attr_accessor(:name)

    #
    # @return [???]
    #
    attr_accessor(:type)

    #
    # @return [???]
    #
    attr_accessor(:objects)

    #
    # @return [???]
    #
    attr_accessor(:prepositions)

    #
    # @return [???]
    #
    attr_accessor(:target)

    #
    # @!macro doc.TAGF.formal.kwargs
    # @return [Verb] self
    #
    def initialize(*args, **kwargs)
      if (TAGF.debugging?(:initialize))
        warn(format('[%s]->%s running',
                    self.class.name,
                    __method__.to_s))
      end
      kwargs[:type] = :intransitive unless (kwargs[:type])
      self.initialize_element(*args, **kwargs)
      return self
    end                         # def initialize(*args, **kwargs)

    nil
  end                           # class Verb

  #
  # Like `xyzzy`, `plugh`, and `y2` in ADVENT.
  #
  class Imperative

    #
    include(Mixin::Element)

    #
    # @!macro doc.TAGF.formal.kwargs
    # @return [Imperative] self
    def initialize(*args, **kwargs)
      if (TAGF.debugging?(:initialize))
        warn(format('[%s]->%s running',
                    self.class.name,
                    __method__.to_s))
      end
      self.initialize_element(*args, **kwargs)
      return self
    end                         # def initialize(*args, **kwargs)

    nil
  end                           # class Imperative

  #
  class Noun

    #
    include(Mixin::Element)

    #
    # @!macro doc.TAGF.formal.kwargs
    # @return [Noun] self
    #
    def initialize(*args, **kwargs)
      if (TAGF.debugging?(:initialize))
        warn(format('[%s]->%s running',
                    self.class.name,
                    __method__.to_s))
      end
      self.initialize_element(*args, **kwargs)
    end                         # def initialize(*args, **kwargs)

    nil
  end                           # class Noun

  #
  # :l
  # :look
  # :inventory
  # :direction
  # :go :direction
  # :go :handed (if we know facing)
  # :turn [:around|:left|:right] (if we know facing; this changes it)
  # :get {Item}
  # :get all
  # :drop {Item}
  # :drop all
  # :throw {Item}
  # :throw {Item} at {Mixin::Actor}
  # :give {Item}
  # :give {Item} to {Mixin::Actor}
  # :attack
  # :attack with {Item}
  # :attack {Mixin::Actor}
  # :attack {Mixin::Actor} with {Item}
  # :kill {Item}
  # :kill {Item} with {Item}
=begin
  DEFAULTS              = {
    noun:               {
    },
    verb:               {
      l:                Verb.new(type:          :intransitive),
      look:             Verb.new(type:          :intransitive),
      inventory:        Verb.new(alii:          %i[ i invent ],
                                 type:          :intransitive),
      go:               Verb.new(objects:       :direction,
                                 type:          :transitive),
      get:              Verb.new(alii:          %i[ g take ],
                                 type:          :transitive,
                                 object:        [ :all, Item ],
                                 :clause =>     {
                                   :optional => { :from => [ Mixin::Actor,
                                                             Item,
                                                             Feature
                                                           ]
                                                }
                                 }),
      drop:             Verb.new(type:          :transitive,
                                 object:        [ :all, Item ]),
      place:            Verb.new(alii:          %i[ put ],
                                 type:          :transitive,
                                 object:        [ :all, Item ],
                                 :clause =>     {
                                   :required => { in: [ Item ],
                                                  on: [ Feature ]
                                                }
                                 }),
      #
      # `throw` is a Ruby keyword, so beware..
      #
      throw:            nil,
    },
    direction:          {
      #
      # Special direction: return to previous location if possible.
      #
      back:             nil,
      north:            %i! n    !,
      northeast:        %i! ne   !,
      east:             %i! e    !,
      southeast:        %i! se   !,
      south:            %i! s    !,
      west:             %i! w    !,
      up:               %i! u    !,
      down:             %i! d    !,
    },
    #
    # These assume the player is facing a particular direction, and we
    # can figure out to which compass direction they refer.
    #
    handed:             {
      left:             nil,
      right:            nil,
      forward:          %i! straight !,
    },
  }
=end

  nil
end                             # module TAGF

# Local Variables:
# mode: ruby
# indent-tabs-mode: nil
# eval: (if (intern-soft "fci-mode") (fci-mode 1))
# End:
