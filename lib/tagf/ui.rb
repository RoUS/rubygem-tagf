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
#require('tagf')
require('contracts')
#require_relative('classmethods')
require_relative('mixin/dtypes')
require_relative('mixin/universal')
require('forwardable')
require('ostruct')
require('shellwords')
require('singleton')

# @!macro doc.TAGF.module
module TAGF

  # @!macro doc.TAGF.UI.module
  module UI

    include(Mixin::UniversalMethods)
    extend(Mixin::DTypes)

    #
    # Regular expression describing the header of a 'here-doc'.
    #
    HEREDOC_RE		= %r!^
			     <<(-)?
			     (['"])?
			     ([[:alnum:]][-_[:alnum:]]*)
			     (['"])?
			     $!x

    #
    # Bits of this are unashamedly cadged from the IRB source — with
    # ignorance aforethought.
    # @!macro doc.TAGF.UI.InputMethod.module
    class InputMethod

      extend(Mixin::DTypes)
      extend(Forwardable)

      attr_reader(:pathname)
      attr_reader(:context)
      def_delegator(:@context, :stdin)
      def_delegator(:@context, :stdout)

      # Reads the next line from this input method.
      #
      # See IO#gets for more information.
      def gets
        fail(NotImplementedError, 'abstract gets method')
      end                       # def gets
      public(:gets)

      def winsize
        outstream	= self.context.stdout
        if (outstream.respond_to?(:tty?) && outstream.tty?)
          result	= outstream.winsize
        else
          result	= [24, 80]
        end
        return result
      end                       # def winsize

      # Whether this input method is still readable when there is no
      # more data to read.
      #
      # See IO#eof for more information.
      def readable_after_eof?
        false
      end                       # def readable_after_eof?

      # For debugging message; describe this particular class.
      def inspect
        return 'Abstract InputMethod'
      end                       # def inspect


      # Constructor for input method objects.
      #
      # @param	       [Array]	   	args		([])
      # @param	       [Array]		kwargs		({})
      # @option kwargs [Context]	:context
      #   <b>REQUIRED.</b>
      #   Interface context to use.  Contains relevant details such as
      #   the current prompt, whether to echo input, <em>&c.</em>
      # @option kwargs [String,IO]	:stdin		($stdin)
      # @option kwargs [String,nil]	:pathname	(nil)
      #   String to use when rendering the stream's path for human
      #   consumption.
      def initialize(*args, **kwargs)
        context		= kwargs[:context]
        unless (context.kind_of?(Context))
          raise(TypeError,
                format('%s.new requires a UI::Context object as ' \
                       + 'for the :context keyword',
                       self.class.name))
        end
        @context	= context
        @pathname	= kwargs[:pathname]
      end                       # def initialize(*args, **kwargs)

      nil
    end                         # class InputMethod

    #
    class Context

      extend(Mixin::DTypes)

      # Instance of the class that will be used to read from the input
      # stream.
      attr_accessor(:inputmethod)

      # @!macro [attach] doc.TAGF.classmethod.file_accessor.invoke
      file_accessor(:stdin	=> $stdin)

      # @!macro doc.TAGF.classmethod.file_accessor.invoke
      file_accessor(:stdout	=> $stdout)

      # @!macro doc.TAGF.classmethod.file_accessor.invoke
      file_accessor(:stderr	=> $stderr)

      # Boolean flag indicating whether lines read from the input
      # stream should be echoed to the output stream.  If the input
      # method is ViaReadline, this is handled directly by the
      # {Readline#readline} library.  If the input stream is a file
      # (<em>i.e.</em>, the input method is ViaFile), such echoing
      # must be done manually.
      #
      # @!macro [attach] doc.TAGF.classmethod.flag.invoke
      flag(echo:	true)

      # Boolean flag indicating whether input lines should be checked
      # for here-doc header signatures.
      # @see Here_Documents
      # @note
      #   If a here-doc is in progress, this flag is disabled;
      #   here-docs cannot be nested.
      # @!macro doc.TAGF.classmethod.flag.invoke
      flag(allow_heredoc: true)

      # Boolean flag indicating whether we're currently reading lines
      # of a here-doc.  When true, input lines are checked for the
      # here-doc terminator, and new here-docs are not allowed (or,
      # rather, are treated as just normal text).
      # @!macro doc.TAGF.classmethod.flag.invoke
      flag(in_heredoc:	false)

      # Prompts used when requesting input in this context.  New ones
      # are pushed when read context changes (such as reading lines of
      # a here-doc), and popped when that reverts.
      attr_reader(:prompt)

      # Array of input lines stored as history.  New lines are pushed
      # on the end.
      attr_reader(:history)

      # Standard set of word-break characters for completion.
      DEFAULT_WORD_BREAK_CHARS = " \t\n`><=;|&{("

      # Valid keywords in the constructor's `kwargs` hash argument.
      KWSYMS		= {
        echo:			true,
        allow_heredoc:		true,
        in_heredoc:		false,
        prompt:			'> ',
        history:		[],
        file:			nil,
        pathname:		nil,
        stdin:			$stdin,
        stdout:			$stdout,
        stderr:			$stderr,
      }

      #
      def initialize(*args, **kwargs)
        settings	= KWSYMS.merge(kwargs)
        settings.each do |kw,val|
          kivar		= format('@%s', kw.to_s).to_sym
          ksetter	= format('%s=', kw.to_s).to_sym
          if (self.respond_to?(ksetter))
            self.send(ksetter, val)
          else
            self.instance_variable_set(kivar, val)
          end
        end
        settings[:context] = self
        if (settings[:file])
          self.inputmethod = ViaFile.new(**settings)
        elsif (self.stdin.tty?)
          self.inputmethod = ViaReadline.new(**settings)
        else
          raise(RuntimeError, "can't determine input type")
        end
      end                       # def initialize(*args, **kwargs)

      #
      def gets
        return self.inputmethod.gets
      end                       # def gets

      def clone(*args, **kwargs)
        #
        # Hash up the settings of the current context.
        #
        ckwargs		= KWSYMS.keys.inject({}) { |memo,kwsym|
          kwivar	= format('@%s', kwsym.to_s).to_sym
          memo[kwsym]	= self.instance_variable_get(kwivar)
          memo
        }
        ckwargs		= ckwargs.merge(**kwargs)
        nu_me		= self.class.new(**ckwargs)
        return nu_me
      end                       # def clone

      nil
    end                         # class Context

    # Class defining the input method to read input from a file.
    class ViaFile < InputMethod

      class << self
        def open(file, &block)
          begin
            io		= new(file)
            block.call(io)
          ensure
            io&.close
          end
        end                     # def open(file, &block)

        nil
      end                       # class ViaFile eigenclass

      # The file name of this input method, usually given during
      # initialization.
      attr_reader(:file_name)

      # Creates a new ViaFile input method object, for reading input
      # from a non-terminal file-like source.
      def initialize(*args, **kwargs)
        debugger
        super
        file		= kwargs[:file]
        unless (file.kind_of?(String) || file.kind_of?(IO))
          raise(RuntimeError,
                format('%s constructor requires a file: keyword ' \
                       'specifying a filename or IO stream',
                       self.class.name))
        end
        @pathname	||= kwargs[:pathname] || file
        @io		= (file.is_a?(IO) \
                           ? file \
                           : File.open(file, 'r'))
        @external_encoding = @io.external_encoding
      end                       # def initialize(file, *args, **kwargs)

      # Whether the end of this input method has been reached, returns
      # `true` if there is no more data to read.
      #
      # See IO#eof? for more information.
      def eof?
        return @io.closed? || @io.eof?
      end                       # def eof?

      # Reads the next line from this input method.
      #
      # See IO#gets for more information.
      def gets
        self.stdout.print(self.context.prompt)
        return @io.gets
      end                       # def gets
      public(:gets)

      # The external encoding for standard input.
      def encoding
        return @external_encoding
      end                       # def encoding

      # For debug message
      def inspect
        return format('%s file=%s',
                      __method__.to_s,
                      self.file_name)
      end                       # def inspect

      def close
        return @io.close
      end                       # def close

      nil
    end                         # class ViaFile


    # Class defining the input method to read from a terminal using
    # the Readline gem.
    class ViaReadline < InputMethod

      # Require and initialise the Readline package, but keep it
      # local to this input method.
      # @return [void]
      def self.initialize_readline
        begin
          require('readline')
        rescue LoadError
        else
          include(::Readline)
        end
        return nil
      end                       # def self.initialize_readline

      # Creates a new input method object using Readline
      def initialize(*args, **kwargs)
        self.class.initialize_readline
=begin
          if (Readline.respond_to?(:encoding_system_needs))
            IRB.__send__(:set_encoding,
                         Readline.encoding_system_needs.name,
                         override: false)
          end
=end
        super
        debugger
        @line_no	= 0
        @line		= []
        @eof		= false

=begin
          @stdin	= IO.open(STDIN.to_i,
                                  :external_encoding => IRB.conf[:LC_MESSAGES].encoding,
                                  :internal_encoding => '-')
          @stdout	= IO.open(STDOUT.to_i,
                                  'w',
                                  :external_encoding => IRB.conf[:LC_MESSAGES].encoding,
                                  :internal_encoding => '-')
=end
        if (Readline.respond_to?(:basic_word_break_characters=))
          Readline.basic_word_break_characters = Context::DEFAULT_WORD_BREAK_CHARS
        end
        Readline.completion_append_character = nil
=begin
          Readline.completion_proc =
          IRB::InputCompletor::CompletionProc
=end
      end                       # def initialize(*args, **kwargs)

      # Reads the next line from this input method.
      #
      # See IO#gets for more information.
      def gets
        Readline.input	= self.stdin
        Readline.output	= self.stdout
        if (l = readline(self..prompt, false))
          HISTORY.push(l) unless (l.empty?)
          @line[@line_no += 1] = l + "\n"
        else
          @eof		= true
          l
        end
      end                       # def gets
      public(:gets)

      # Whether the end of this input method has been reached, returns
      # `true` if there is no more data to read.
      #
      # See IO#eof? for more information.
      def eof?
        return @@eof
      end                       # def eof?

      # Whether this input method is still readable when there is no
      # more data to read.
      #
      # See IO#eof for more information.
      def readable_after_eof?
        return true
      end                       # def readable_after_eof?

      # Returns the current line number for #io.
      #
      # #line counts the number of times #gets is called.
      #
      # See IO#lineno for more information.
      def line(line_no)
        return @line[line_no]
      end                       # def line(line_no)

      # The external encoding for standard input.
      def encoding
        return @context.stdin.external_encoding
      end                       # def encoding

      # For debug message
      def inspect
        readline_impl	= (defined?(Reline) && Readline == Reline) \
                          ? 'Reline' \
                          : 'ext/readline'
        str		= format('%s with %s %s',
                                 self.class.name.sub(%r!^.*::!, ''),
                                 readline_impl,
                                 Readline::VERSION)
        inputrc_path	= File.expand_path(ENV['INPUTRC'] \
                                           || '~/.inputrc')
        if (File.exist?(inputrc_path))
          str		+= format(' and %s', inputrc_path)
        end
        return str
      end                       # def inspect

      nil
    end                         # class ViaReadline < InputMethod

    # Class defining the environment for interfacing with the user.
    # Each time there is some sort of transition, such as to a
    # different command syntax tree, a new instantiation should be
    # created and pushed.  When the transition completes, the
    # environment should be popped back.
    class Interface

      extend(Mixin::DTypes)
      include(Mixin::UniversalMethods)

      attr_reader(:contexts)

      # Return the 'current' context object; that is, the most recent
      # one pushed on the stack.
      # @return [Context]
      def context
        return self.contexts.last
      end                       # def context

      #
      def push_context(*args, **kwargs)
        if (@contexts.empty?)
          new_ctx	= Context.new(*args, **kwargs)
        else
          new_ctx	= @contexts.last.clone(*args, **kwargs)
        end
        return @contexts.push(new_ctx).last
      end                       # def push_context(*args, **kwargs)

      #
      def pop_context
        @contexts.pop
        if (@contacts.empty?)
          raise_exception(Exceptions::IfaceStackEmpty)
        end
        return self.context
      end                       # def pop_context

      attr_accessor(:prompts)
      protected(:prompts=)


      # Constructor for the Interface class, which is a main part of
      # the 'user interface' for TAGF.  Its primary purpose is getting
      # input from the user (player), but becoming the main conduit
      # between the code and the Outer World — including displaying
      # output (usually stdout) and reporting errors (stderr) is
      # currently in the goal list.
      #
      # Many of the options specifically control how input is obtained
      # and processed.  Support for 'here-docs' is included, since
      # being able to build adventure databases from the command line
      # is also on the goal list.  Multi-line descriptions, for
      # instance.
      #
      # @param [Array]		args
      # @param [Hash<Symbol=>Object>]	kwargs		({})
      # @option kwargs [Boolean]	:echo		(true)
      # @option kwargs [Boolean]	:history	(true)
      # @option kwargs [Symbol]		:input		($stdin)
      # @option kwargs [Symbol]		:output		($stdout)
      # @option kwargs [Symbol]		:error		($stderr)
      # @option kwargs [String]		:prompt		('> ')
      # @option kwargs [Boolean]	:allow_heredoc	(true)
      # @option kwargs [Object]		:cmdtree	(nil)
      # @raise [RuntimeError]
      def initialize(*args, **kwargs)
        debugger
        @contexts	= []
      end                       # def initialize

      # Method used to check whether a line of input starts a
      # `here-document`.  Primarily intended for use by the
      # administrator command-line and scripting tools, it either
      # returns `false` if there's no `here-doc` indicator, or a
      # structure for use in processing the `here-doc` text lines that
      # follow.
      #
      # @param [String] input
      #   A line of text to be checked for a `here-document` opener.
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
      #       terminating the `here-doc` text.  It matches the
      #       *entire* line, so no pre-parsing is necessary.
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
            raise(RuntimeError,
                  format('invalid here-doc suffix syntax: %s',
                         words.last.inspect))
          end
          #
          # We have a here-doc suffix that matches the pattern..
          #
          if (m.captures[1] != m.captures[3])
            #
            # .. except the '<<{word}' was quoted incorrectly.  Bzzzt!
            #
            raise(RuntimeError,
                  format('invalid here-suffix ' \
                         + '(mismatched quotes): %s',
                         m.captures.inxpect
                        ))
          end
          warn(format('Here-document ending with «%s»',
                      m.captures[2]))
          result	= OpenStruct.new(
            interpolate: (! m.captures[1].nil?),
            term_re:	nil
          )
          terminator	= format('^%s%s$',
                                 (m.captures[0] == '-' ? '\s*' : ''),
                                 Regexp.escape(m.captures[2]))
          result.term_re = Regexp.compile(terminator)
          return result
        end                     # if (words.last[0,2] == '<<')
        return false
      end                       # def heredoc?(input)

      #
      def readline(prompt=nil, **kwargs)
        opts		= kwargs
        if (Readline.rl_instream != self.instream)
          Readline.input = self.instream
        end
        opts[:record]	= true unless (opts.has_key?(:record))
        opts[:echo]	= true unless (opts.has_key?(:echo))
        if (opts[:echo] || (! self.instream.tty?))
          if (default = opts[:default])
            Readline.pre_input_hook = ->{
              Readline.insert_text(default)
              Readline.redisplay
              Readline.pre_input_hook = nil
            }
          end
          result	= Readline.readline(prompt || '> ',
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

          self.outstream.print(prompt)
          self.outstream.flush
          #
          # Turn off character echo if the driver can't do it through
          # Ruby's #IO.
          #
          input		= nil
          begin
            if (self.instream.respond_to?(:noecho))
              input	= self.instream.noecho(:gets)
            else
              `stty -echo`
              input	= self.instream.gets
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
          result	= input
        end                     # if ((opts[:echo] || (! $stdin.tty?))
        return result
      end                       # def readline(prompt, opts_p={})

      nil

    end                         # class Interface

    nil
  end                           # module UI

  #
  # Directions, possibly prefixed with `go` (as in `south` or
  # `go south`), and other actions (like `get`, `take`, `drop`,
  # `throw`, and so forth).
  #
  class Verb

    #
#    include(Mixin::Element)

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
#      TAGF::Mixin::Debugging.invocation
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
#    include(Mixin::Element)

    #
    # @!macro doc.TAGF.formal.kwargs
    # @return [Imperative] self
    def initialize(*args, **kwargs)
#      TAGF::Mixin::Debugging.invocation
      self.initialize_element(*args, **kwargs)
      return self
    end                         # def initialize(*args, **kwargs)

    nil
  end                           # class Imperative

  #
  # Things that can be objects of verbs, like items or locations.
  #
  class Noun

    #
#    include(Mixin::Element)

    #
    # @!macro doc.TAGF.formal.kwargs
    # @return [Noun] self
    #
    def initialize(*args, **kwargs)
#      TAGF::Mixin::Debugging.invocation
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
# eval: (auto-fill-mode 1)
# End:
