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
#require('tagf/classmethods')
require('tagf/mixin/dtypes')
require('tagf/mixin/universal')
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

      attr_reader(:context)
      def_delegator(:@context, :prompt)
      def_delegator(:@context, :transcribe?)
      def_delegator(:@context, :pathname)
      def_delegator(:@context, :input)
      def_delegator(:@context, :output)

      # Reads the next line from this input method.
      #
      # See IO#gets for more information.
      def gets
        fail(NotImplementedError, 'abstract gets method')
      end                       # def gets
      public(:gets)

      def winsize
        outstream	= self.output
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
      # @option kwargs [String,IO]	:input		($stdin)
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
        @pathname	= kwargs[:pathname] \
                          || kwargs[:file] \
                          || kwargs[:input].inspect
      end                       # def initialize(*args, **kwargs)

      nil
    end                         # class InputMethod

    # Record the paticulars of a here-doc.  Here-docs are input lines
    # designed to be processed as a group.  They have a basic format
    # as follows (characters and words in brackets (<b>`[]`</b>) are
    # optional):
    #
    #    [<em>prefix</em>]<<[-]<em>delimiter</em>
    #    [<em>text-line</em>...]
    #    <em>delimiter</em>
    #
    # As an example:
    #
    #    two_liner = <<-EOF
    #      You're at the end of a road.
    #      There is a small shed here.
    #      EOF
    #
    # * <em>prefix</em> —
    #   Everything, including whitespace, preceding the `<<`
    #   introducer.  In the example, this would be
    #
    #    "`two_liner = `"
    #
    #   Notice the inclusion of the spaces.
    # * Optional hyphen —
    #   The presence of the hyphen (dash) immediately preceding the
    #   delimiter signals that when the delimiter is encountered, it
    #   <em>may</em> be preceded by irrelevant whitespace, which is to
    #   be stripped and ignored.  This is intended to improve
    #   readability by humans (not software).
    # * <em>delimiter</em> —
    #   A 'word' which, when read on a line by itself, signals the end
    #   of the here-doc content.  The delimiter is at least one
    #   character long, is case-sensitive, and may be composed of
    #   alphanumerics and the underscore (`_`) character.  Trailing
    #   whitespace is ignored.
    # * <em>text-line</em> —
    #   Lines of text comprising the actual value of the here-doc
    class HereDoc

      attr_accessor(:prefix)
      attr_accessor(:delimiter)
      attr_accessor(:delimiter_re)
      attr_accessor(:raw)
      attr_accessor(:lines)

      # Constructor for HereDoc class.  Set any instance variables
      # whose names appear in `kwargs`.
      # @param [Hash<Symbol=>Object>] kwargs
      # @option kwargs [String] 	:prefix
      # @option kwargs [String] 	:delimiter
      # @option kwargs [Regexp] 	:delimiter_re
      # @option kwargs [String]		:raw
      # @option kwargs [Array<String>]	:lines
      def initialize(**kwargs)
        %i[ prefix delimiter delimiter_re raw lines ].each do |kw|
          if (val = kwargs[kw])
            setter	= format('%s=', kw.to_s).to_sym
            self.send(setter, val)
          end
        end
      end                       # def initialize(**kwargs)

      nil
    end                         # class HereDoc

    # Main supervisory class for getting and processing input from the
    # user.  Each time we change something about how we read, such as
    # the input source or even the prompt, a new context should be
    # created, pushed on a stack, and used.  When the changed
    # conditions terminate, we should revert to the previous context.
    class Context

      # Import our app's own datatype accessor class methods.
      extend(Mixin::DTypes)

      # In the interest of readability at higher levels, we blur the
      # details of how interfaces, contexts, and input methods
      # actually interact.  Input methods 'inherit' some methods and
      # attributes from their calling contexts, and contexts do
      # likewise with aspects of the active input method.  This is
      # handled by delegating the methods in question to the
      # appropriate instance variable using the Forwardable module's
      # features.  The programmer should only have to worry about the
      # Interface and Context classes, and not any of the more
      # nitty-gritty lower-level details.
      extend(Forwardable)

      # Names of fields in the Context instance.  Used to process
      # constructor keyword arguments, but also for cloning when
      # creating a subordinate context.
      KWSYMS		= {
        #
        # Should input be visible/show up in the output stream?
        # (Doesn't include prompts, which aren't input.)
        #
        echo:                   true,
        #
        # Should input operations (prompt plus echoed input) be copied
        # to the output stream?  Mostly for ViaFile, since Readline
        # handle this itself.
        #
        transcribe:             false,
        #
        # Should input lines be recorded in the history buffer?  Only
        # echoed lines are eligible; unechoed input doesn't get
        # recorded *any*where.
        #
        record:			true,
        #
        # Should leading whitespace be stripped before input is
        # returned to the caller?
        #
        strip_leading:          true,
        #
        # How about trailing whitespace, and newlines?  Trailing
        # newlines are left untouched in here-docs.
        #
        strip_trailing:         true,
        #
        # Do we check input lines for here-doc delimiters (except when
        # processing a here-doc)?  Or just treat them verbatim?
        #
        allow_heredoc:          true,
        #
        # Runtime flag indicating whether or not we're in the middle
        # of processing a here-doc.
        #
        in_heredoc:             false,
        #
        # HereDoc object when processing (or just completed processing
        # of) a set of input lines comprising a here-doc.
        #
        heredoc:                nil,
        #
        # Input prompt.  Used directly by ViaReadline, and by ViaFile
        # when transcribing.
        #
        prompt:                 '> ',
        #
        # Support for (e.g.) TAB-completion during input.  nil means
        # 'no.'  (ViaReadline only)
        #
        completion_proc:        nil,
        #
        # Whether history is retained when pushing a new context.  If
        # false, the new context will start with an empty history
        # buffer.  (ViaReadline only)
        #
        propagate_history:      true,
        #
        # Array of text lines read in the current context; part of our
        # module, not Readline's HISTORY buffer.
        #
        lines:                  [],
        #
        # Instance of class tailored to reading from an input source;
        # either ViaFile or ViaReadline.  All actual obtaining of
        # input goes through this; source-agnostic processing occurs
        # in the Context methods.
        #
        inputmethod:		nil,
        #
        # Name of the input file to open and read.  (ViaFile only)
        #
        file:                   nil,
        #
        # Human-readable rendition of the input source.
        #
        pathname:               nil,
        #
        # IO streams to be used in the current context.
        #
        input:                  $stdin,
        output:                 $stdout,
        error:                  $stderr,
      }

      # Boolean flag indicating whether lines read from the input
      # stream should be echoed to the output stream.  If the input
      # method is ViaReadline, this is handled directly by the
      # {Readline#readline} library.  If the input stream is a file
      # (<em>i.e.</em>, the input method is ViaFile), such echoing
      # must be done manually.
      # @see transcribe
      # @see record
      # @return [Boolean]
      #   `true` if text read from the input stream should be echoed
      #   <em>verbatim</em> to the output stream as it's typed.
      # @ ! macro [attach] doc.TAGF.classmethod.flag.invoke
      flag(echo:	true)

      # Boolean flag indicating whether lines read from the input
      # stream should be echoed to the output stream <em>after having
      # been read.</em> This is a no-op when the input is being
      # handled by ViaReadline, in which case it is handled directly
      # by the {Readline#readline} library.  If the input stream is a
      # file (<em>i.e.</em>, the input method is ViaFile), such
      # echoing must be done manually.  This controls that
      # functionality.
      # @see echo
      # @return [Boolean]
      #   `true` if text read from the input stream should be echoed
      #   <em>verbatim</em> to the output stream after having been read.
      # @ ! macro [attach] doc.TAGF.classmethod.flag.invoke
      flag(transcribe:	false)

      # @see echo
      # @see transcribe
      # @return [Boolean]
      #   `true` if text read from the input stream should be echoed
      #   <em>verbatim</em> to the output stream as it's typed.
      # @ ! macro [attach] doc.TAGF.classmethod.flag.invoke
      flag(record:	true)

      # @!attribute [rw] strip_leading
      # Boolean flag indicating whether input lines should have
      # leading whitespace removed after reading and before processing
      # or storage.
      # @see #strip_trailing
      # @see #strip
      # @return [Boolean]
      # @ ! macro doc.TAGF.classmethod.flag.invoke
      flag(strip_leading: false)

      # @!attribute [rw] strip_trailing
      # Boolean flag indicating whether input lines should have
      # <em>trailing</em> whitespace removed after reading and before
      # processing or storage.
      # @see #strip_leading
      # @see #strip
      # @return [Boolean]
      # @ ! macro doc.TAGF.classmethod.flag.invoke
      flag(strip_trailing: false)

      # @!attribute [rw] strip
      # Boolean flag indicating whether input lines should have
      # leading and trailing whitespace removed.  Sets or clears both
      # the #strip_leading and #strip_trailing attributes together.
      # @see strip_leading
      # @see strip_trailing
      # @overload strip
      #   @return [Boolean]
      #     whether both leading and trailing whitespace should be
      #     removed.
      # @overload strip?
      #   @return [Boolean]
      #     whether both leading and trailing whitespace should be
      #     removed.
      # @overload strip!
      #   @return [Boolean] `true`, as both of the #strip_leading and
      #   the #strip_trailing attributes are unconditionally set.
      def strip
        result		= self.strip_leading? & self.strip_trailing?
        return result
      end                       # def strip
      alias_method(:strip?, :strip)
      # @overload strip=(val)
      #   @param [Boolean] val
      #   @return [Boolean] the argument value.
      def strip=(val)
        val		= truthify(val)
        self.strip_leading = val
        self.strip_trailing = val
        return val
      end                       # def strip=(val)
      def strip!
        self.strip_leading = true
        self.strip_trailing = true
        return true
      end                       # def strip!

      # Boolean flag indicating whether input lines should be checked
      # for here-doc header signatures.
      # @see Here_Documents
      # @note
      #   If a here-doc is in progress, this flag is disabled;
      #   here-docs cannot be nested.
      # @return [Boolean]
      #   `true` if input lines are to check for here-doc syntax and
      #   processed appropriately.
      # @ ! macro doc.TAGF.classmethod.flag.invoke
      flag(allow_heredoc: true)

      # Boolean flag indicating whether we're currently reading lines
      # of a here-doc.  When true, input lines are checked for the
      # here-doc terminator, and new here-docs are not allowed (or,
      # rather, are treated as just normal text).
      # @return [Boolean]
      #   `true` if the input processor is in the middle of readine a
      #   here-doc.
      # @ ! macro doc.TAGF.classmethod.flag.invoke
      flag(in_heredoc:	false)

      # Particulars of the most recent (or current) here-doc
      # processed.  Here-docs are more complicated than simple one-off
      # input lines, so we use a more complex storage tool for them.
      # @return [HereDoc,nil]
      #   the HereDoc object currently being processed.
      attr_accessor(:heredoc)

      # @!attribute [rw] prompt
      # Prompt used when requesting input in this context.  New ones
      # are pushed when read context changes (such as reading lines of
      # a here-doc), and popped when that reverts.
      # @return [String]
      #   the current prompt string
      attr_accessor(:prompt)

      # @!attribute [rw] completion_proc
      # Proc or method object that should be used to handle completion
      # checking and processing when reading input interactively.
      # @return [Proc,Method,nil]
      #   either the object that should be used by the Readline
      #   library to process completions, or `nil` if completion
      #   isn't enabled.
      def completion_proc
        unless (self.instance_variable_defined?(:@completion_proc))
          @completion_proc = nil
        end
        return @completion_proc
      end                       # def completion_proc
      # @overload completion_proc=(handler)
      #   @param [Proc,Method,nil] handler
      #     A Proc or bound Method object that should be
      #     invoked by the Readline library to help the user enter a
      #     command.  Set to `nil` to disable completion processing.
      def completion_proc=(handler)
        valid_handler	= [Proc,Method].any? { |ht|
          (handler.nil? || handler.kind_of?(ht))
        }
        unless (valid_handler)
          raise_exception(TypeError,
                          format('%s must either be nil or ' \
                                 'a block-type object',
                                 __method__.to_s))
        end
        @completion_proc = handler
      end                       # def completion_proc=(handler)

      # @!attribute [rw] propagate_history (true)
      # When a new context is pushed, it can either start a new list
      # of recorded lines, or it can
      # @return [Boolean]
      #   `true` if any existing history should be passed along when
      #   we push a new context.
      flag(propagate_history: true)

      # Array of input lines stored as history.  New lines are pushed
      # on the end.
      # @return [Array<String>]
      attr_reader(:lines)

      # Instance of the class that will be used to read from the input
      # stream in this context.  Supported values are any object that
      # subclasses TAGF::UI::InputMethod.
      # @return [InputMethod]
      attr_accessor(:inputmethod)

      # @!attribute rw [String] file
      # @return [String]
      #   name of input file
      attr_accessor(:file)

      # @!attribute [rw] pathname
      # @return [String]
      attr_accessor(:pathname)

      # @!attribute [rw] input ($stdin)
      # IO stream from which we read for the current context.
      # @return [IO,String]
      file_accessor(input:	$stdin)

      # @!attribute [rw] output ($stdout)
      # IO stream to which we send normal output, such as prompts,
      # reports, descriptions, <em>&c.</em>
      # @return [IO,String]
      file_accessor(output:	$stdout)

      # @!attribute [rw] error ($stdin)
      # IO stream to which we send error messages and exception
      # reports.
      # @return [IO,String]
      file_accessor(error:	$stderr)

      # Standard set of word-break characters for completion.
      DEFAULT_WORD_BREAK_CHARS = " \t\n`><=;|&{("

      # The end-of-file test actually lives in the input method object
      # rather than here in the context, but we might need it here.
      def_delegator(:@inputmethod, :eof?)

      # Constructor for Context class instances.
      # @param [Array]			args		([])
      # @param [Hash<Symbol=>Object>]	kwargs		({})
      # @option kwargs [String]		:inputmethod
      #   Name of the input method class that should be instantiated
      #   to handle actually reading from the input source.
      def initialize(*args, **kwargs)
        settings	= KWSYMS.merge(kwargs)
        settings.each do |kw,val|
          kivar		= format('@%s', kw.to_s).to_sym
          ksetter	= format('%s=', kw.to_s).to_sym
          #
          # The inputmethod attribute is specified as a string.
          #
          if ((kw == :inputmethod) && val)
            begin
              settings[kw] = UI.const_get(val)
            rescue NameError
              raise_exception(ArgumentError,
                              format('unknown input method %s',
                                     val))
            end
            next
          end
          if (self.respond_to?(ksetter))
            self.send(ksetter, val)
          else
            self.instance_variable_set(kivar, val)
          end
        end
        settings[:context] = self
        if (imclass = settings[:inputmethod])
          self.inputmethod = imclass.new(**settings)
        elsif (settings[:file])
          self.inputmethod = ViaFile.new(**settings)
        elsif (self.input.tty?)
          self.inputmethod = ViaReadline.new(**settings)
        else
          raise(RuntimeError, "can't determine input type")
        end
      end                       # def initialize(*args, **kwargs)

      # 'Smart' method for reading from the input stream.
      def read(*args, **kwargs)
        text		= self.inputmethod.gets
        #
        # If we seem to be at EOF, just exit.
        #
        return text if (text.nil?)
        #
        # Here-doc processing is involved, so let's check for the
        # simplest case (no here-docs) and get it out of the way.
        #
        unless (self.allow_heredoc? && (hdinfo = self.heredoc?(text)))
          case(true)
          when self.strip?
            text.strip!
          when self.strip_leading?
            text.lstrip!
          when self.strip_trailing?
            text.rstrip!
          end
          return text
        end                     # unless (self.allow_heredoc? && self.heredoc?(text))
        #
        # Okey, we're starting a here-doc.  `hdinfo` is a {HereDoc}
        # object that has been preloaded with much of the information.
        #

        #
        # Here is where we read the here-doc lines.
        #
        save_prompt	= self.prompt
        self.prompt	= format('[Heredoc:%s]> ', hdinfo.delimiter)
        result		= hdinfo
        self.in_heredoc	= true
        hdinfo.raw	= String.new
        catch(:heredoc_read) do
          while (true)
            line	= self.inputmethod.gets
            if (line.nil?)
              #
              # Got EOF before reaching the here-doc termination line.
              #
              warn(format('EOF encountered before ' \
                          + 'end of "%s" here-doc; ' \
                          + 'any partial input discarded',
                          hdinfo.delimiter))
              result	= ''
              throw(:heredoc_read)
            end
            if (line.match(hdinfo.delimiter_re))
              #
              # We've hit the terminator line.  Don't include it, and
              # exit the loop.
              #
              throw(:heredoc_read)
            end
            hdinfo.raw	<< line
          end
        end                     # catch(:heredoc_read) do
        self.prompt	= save_prompt
        self.in_heredoc	= false
        if (hdinfo.raw)
          hdinfo.lines	= hdinfo.raw.split(%r!\n!)
        end
        return hdinfo
      end                       # def read(*args, **kwargs)

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
      # @return [HereDoc,false]
      #   * If the last word (as defined by the shell) of the input
      #     parameter <b>does not</b> match a valid `here-doc`
      #     terminator pattern, this method returns `false`.
      #   * If the last word <b>does</b> is a valid `here-doc`
      #     terminator, the return value is a structure with the
      #     following attributes:
      #
      #     * `.interpolate` [Boolean]
      #       (Not currently used.)  Indicates whether the final value
      #       of the `here-doc` should be subjected to variable
      #       interpolation or other post-processing.  If `false`, it
      #       should be treated as a raw string.
      #     * `.delimiter_re` [Reqexp]
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
          result	= HereDoc.new(
            prefix:		input.sub(%r!<<.*!, '').chomp,
            interpolate:	(! m.captures[1].nil?),
            delimiter:		m.captures[2],
            delimiter_re:	nil,
            raw:		nil,
            lines:		[]
          )
          pre_re	= format('^%s%s$',
                                 (m.captures[0] == '-' \
                                  ? '\s*' \
                                  : ''),
                                 Regexp.escape(m.captures[2]))
          result.delimiter_re = Regexp.compile(pre_re)
          return result
        end                     # if (words.last[0,2] == '<<')
        return false
      end                       # def heredoc?(input)

      nil
    end                         # class Context

    # Class defining the input method to read input from a file.
    class ViaFile < InputMethod

      # Eigenglass for ViaFile class.
      class << self

        # ... I'm not sure what's going on here, but I'm pretty sure
        # it's artifactual of IRC.  The input method isn't a type of
        # IO.
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
      # @see Readline
      # @param [Array]			args
      # @param [Hash<Symbol=>Object>]	kwargs
      # @option kwargs [String]		:context
      # @option kwargs [String]		:file
      # @option kwargs [String]		:pathname
      # @option kwargs [String]		:input
      # @option kwargs [String]		:output
      # @option kwargs [String]		:completion_proc
      def initialize(*args, **kwargs)
        super
        file		= kwargs[:file]
        unless (file.kind_of?(String) || file.kind_of?(IO))
          raise_exception(ArgumentError,
                          format('%s constructor requires a ' \
                                 + 'file: keyword specifying a ' \
                                 + 'filename or IO stream',
                       self.class.name))
        end
        @pathname	||= kwargs[:pathname] || file
        @io		= (file.is_a?(IO) \
                           ? file \
                           : File.open(file, 'r'))
        @external_encoding = @io.external_encoding
      end                       # def initialize(file, *args, **kwargs)

      # Whether the end of this input method has been reached, returns
      # `true` if there is no more data to read.  Since we're reading
      # from a file-like source, there's only one "end of file" —
      # attempts to read further should just keep hitting that
      # condition.
      #
      # See IO#eof? for more information.
      def eof?
        return @io.closed? || @io.eof?
      end                       # def eof?

      # Reads the next line from this input method.
      #
      # See IO#gets for more information.
      def gets
        text_in		= @io.gets
        if (self.transcribe?)
          if (text_in.nil? && self.eof?)
            transcription = format("%s[end of file]\n",
                                   self.prompt)
          else
            transcription = format('%s%s',
                                   self.prompt,
                                   text_in)
          end
          self.output.print(transcription)
        end
        return text_in
      end                       # def gets
      public(:gets)

      # The external encoding for standard input.
      def encoding
        return @external_encoding
      end                       # def encoding

      # For debugging messages
      def inspect
        return format('%s file=%s',
                      self.class.name.sub(%r!^.*::!, ''),
                      self.pathname.inspect)
      end                       # def inspect

      def close
        return @io.close
      end                       # def close

      nil
    end                         # class ViaFile


    # Class defining the input method to read from a terminal using
    # the Readline gem.
    class ViaReadline < InputMethod

      #
      # ViaReadline eigenclass
      #
      class << self

        # @!attribute [r] readline_initialised
        # Flag that we've performed the one-time setup bits for the
        # Readline library (importing the code, saving any existing
        # history lines, <em>&c.</em>).  Stored in the eigenclass for
        # safety.
        # @return [Boolean]
        #   `true` if the Readline library is ready for use.
        attr_reader(:readline_initialised)

        # @!attribute [r] saved_history
        # An array of all the lines stored in the Readline::HISTORY
        # buffer at the point class method #initialise_readline was
        # invoked.  The #restore_history class method is intended to
        # reverse this process.
        # @return [Array<String>]
        attr_reader(:saved_history)

        # Require and initialise the Readline package, but keep it
        # local to this input method.  Also, make a copy of the
        # Readline::HISTORY buffer, and then clear it so it only
        # contains application input.
        # @see #save_history
        # @see #restore_history
        # @return [void]
        def initialize_readline
          if (self.readline_initialised)
            #
            # We've already been here, done this.
            #
            return
          end
          begin
            warn(format('%s.%s requiring readline',
                        self.class.name.to_s,
                        __method__.to_s))
            require('readline')
          rescue LoadError => exc
            warn(format("%s.%s unable to load readline\n" \
                        "\t%s",
                        self.class.name.to_s,
                        __method__.to_s.
                          exc.to_s))
            include(::Readline)
            #
            #
            @saved_history = HISTORY.to_a
            HISTORY.clear
          else
            warn(format('%s.%s including Readline',
                        self.class.name.to_s,
                        __method__.to_s))
            include(::Readline)
          end
          @realine_initialised = true
          return nil
        end                     # def self.initialize_readline

        nil
      end                       # ViaReadline eigenclass

      # @!method save_history(erase: false)
      # Copy the Readline::HISTORY buffer and return the array of
      # history lines.  Can optionally erase the Readline::HISTORY
      # buffer after making the copy, depending upon the value of
      # the `erase` argument.
      # 
      # @param [Boolean] erase (false)
      #   Controls whether or not the Readline::HISTORY buffer is
      #   cleared after all the lines have been copied from it.
      # @return [Array<String>]
      #   list of lines from the Readline::HISTORY buffer.
      def save_history(erase: false)
        saved_history	= []
        Readline::HISTORY.each do |line|
          saved_history << line
        end
        Readline::HISTORY.clear if (erase)
        return saved_history
      end                       # def restore_history

      # @!method load_history
      # Attempt to clear the Readline::HISTORY buffer and read in
      # new contents from the given file.  If the file cannot be
      # read, a warning is displayed and Readline::HISTORY is
      # unaffected.
      def load_history(file)
        hlines		= []
        begin
          hlines	= File.open(file, 'r').readlines
        rescue StandardError => exc
          raise_exception(BadHistoryFile,
                          file:		file,
                          exception:	exc)
        end
        Readline::HISTORY.clear
        return self.set_history(hlines)
      end                       # def load_history(file)

      # @!method set_history(histlines)
      # Clear the Readline::HISTORY buffer and copy saved lines from
      # the `histlines` argument into it.
      #
      # @param [Array<String>] histlines
      # @raise [ArgumentError]
      #   if `histlines` isn't an array of Strings
      # @return [Array<String>]
      #   the new history contents.
      def set_history(histlines)
        unless (histlines.kind_of?(Array) \
                && histlines.all? { |e| e.kind_of?(String) })
          raise_error(ArgumentError,
                      format('%s.%s requires an array of strings',
                             self.class.name,
                             __method__.to_s))
        end
        Readline::HISTORY.clear
        histlines.each do |line|
          Readline::HISTORY << line
        end
        return Readline::HISTORY.to_a
      end                       # def set_history(histlines)

      # Creates a new input method object using Readline
      # @param [Array]			args
      # @param [Hash<Symbol=>Object>]	kwargs
      # @option kwargs [String]		:context
      # @option kwargs [String]         :history_file
      # @option kwargs [String]		:file
      # @option kwargs [String]		:pathname
      # @option kwargs [String]		:input
      # @option kwargs [String]		:output
      # @option kwargs [String]		:completion_proc
      def initialize(*args, **kwargs)
        self.class.initialize_readline
        super
        if (Readline.respond_to?(:encoding_system_needs))
          self.input.__send__(:set_encoding,
                              Readline.encoding_system_needs.name,
                              override: false)
        end
        @line_no	= 0
        @line		= []
        @eof		= false

=begin
          @input	= IO.open(STDIN.to_i,
                                  :external_encoding => IRB.conf[:LC_MESSAGES].encoding,
                                  :internal_encoding => '-')
          @output	= IO.open(STDOUT.to_i,
                                  'w',
                                  :external_encoding => IRB.conf[:LC_MESSAGES].encoding,
                                  :internal_encoding => '-')
=end
        if (Readline.respond_to?(:basic_word_break_characters=))
          Readline.basic_word_break_characters = Context::DEFAULT_WORD_BREAK_CHARS
        end
        Readline.completion_append_character = nil
        Readline.completion_proc = self.context.completion_proc
      end                       # def initialize(*args, **kwargs)

      # Reads the next line from this input method.
      #
      # See IO#gets for more information.
      def gets
        Readline.input	= self.input
        Readline.output	= self.output
        @ttychars	= nil
        @ttychars	= `stty -g`.chomp if (self.input.tty?)
        begin
          if (l = readline(self.prompt, true))
            HISTORY.push(l) unless (l.empty?)
            @line[@line_no += 1] = l + "\n"
          else
            @eof	= true
            l
          end
        rescue Interrupt
          #
          # Restore the terminal settings if any were saved.
          #
          if (self.input.tty? && (@ttychars.to_s.length != 0))
            system('stty', @ttychars)
          end
          self.class.handle_interrupt
          #
          # Re-raise the Interrupt exception so anything in our call
          # tree wants to deal with it.
          #
          raise
        end                     # rescue block for CTRL/C
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
        return @context.input.external_encoding
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
      # @option kwargs [Array]		:lines		([])
      # @option kwargs [Symbol]		:input		($stdin)
      # @option kwargs [Symbol]		:output		($stdout)
      # @option kwargs [Symbol]		:error		($stderr)
      # @option kwargs [String]		:prompt		('> ')
      # @option kwargs [Boolean]	:allow_heredoc	(true)
      # @option kwargs [Object]		:cmdtree	(nil)
      # @raise [RuntimeError]
      def initialize(*args, **kwargs)
        @contexts	= []
      end                       # def initialize

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
        end                     # if ((opts[:echo] || (! self.input.tty?))
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
