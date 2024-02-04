require('tagf/ui')
require('tagf/exceptions')
require('byebug')
require('pathname')
require('test/unit')

class Test_InputMethod_ViaFile_Base < Test::Unit::TestCase

  include(TAGF::UI)
  include(TAGF::Exceptions)

  #
  # Executed before each test is invoked.
  #
  def setup
    @fixtures		= Dir[File.join(FixturesDir, 'viafile-*.txt')]
                            .sort
    @iface		= Interface.new(inputmethod:	'ViaFile',
                                        record:		false,
                                        transcribe:	false)
    begin
      super
    rescue NoMethodError
      # No-op
    end
    return nil
  end                           # def setup

  #
  # Called after each test method completes.
  #
  def teardown
    #
    # Make sure any input stream is closed.
    #
#    begin
      @iface.context.input.close
#    rescue StandardError
#    end
    begin
      super
    rescue NoMethodError
      # No-op
    end
    return nil
  end                           # def teardown

  def access_file(base)
    fspec		= File.expand_path(base, FixturesDir)
    @context		= Context.new(interface:	@iface,
                                      inputmethod:	'ViaFile',
                                      record:		false,
                                      transcribe:	false,
                                      file:		fspec)
    @lines		= File.readlines(fspec).map { |l| l.chomp }
    return @lines
  end

  # * Test that ViaFile properly reads plain lines of text
  def test_viafile_read_lines
    @fixtures.grep(%r!/viafile-lines!).each do |file|
      m			= file.match(%r!viafile-lines-(\d+)\.txt!)
      lines_expected	= m.captures[0].to_i
      lines_actual	= File.readlines(file).map { |l| l.chomp }
      #
      # Make sure the expect line count from the file name matches the
      # number of lines actually in the file.
      #
      assert_equal(lines_expected,
                   lines_actual.count,
                   format('line count mismatch, ' +
                          'filename:contents for %s',
                          file))
      lines_read	= []
      #
      # Access the file through the input method; this updates
      # @context so calls to @context.read will fetch content
      # therefrom.
      #
      access_file(file)
      line_num		= 0
      previous_line	= 666
      #
      # When we read a line, we can get either:
      #
      # nil:
      #  * @context.eof? should be true
      #  * lines_read should == lines_actual
      # String:
      #  * @context.eof? should be true IFF
      #    (lines_read.count == lines_actual.count)
      #  * line should == lines_actual[line_num]
      #
      # 1. We read more lines than exist in the file.
      # 2. We read *fewer* lines than exist.
      # 3. We read the correct number of lines, but don't get EOF
      #    right.
      # 4. We read the right number of lines and EOF is correct.
      #
      # Oh, and we check each line read through ViaFile against the
      # ones read directly with File.readlines.
      #
      #
      # Wrap in a rescue block to ensure we close the input file.
      #
      begin
        #
        # We call @context.read until the return value is nil.  Preset
        # the indicator so we can reference it.
        #
        last_was_nil	= nil
        while (true) do
          line		= @context.read
          #
          # If it's a string, add it to the array of lines we've read
          # from through the input method.
          #
          lines_read.push(line) if (line.kind_of?(String))
          warn(format("\n\t%s\n", line.inspect))
          if (line.nil?)
            #
            # We've purportedly read [past] the last line.  This ends
            # the read loop.  We test for having read the exact number
            # of lines after this loop.
            #
            assert(@context.eof?,
                   '@context.read returned nil; eof? should be true')
            break
          elsif (line.kind_of?(String))
            lines_read.push(line)
            line_num	= lines_read.count - 1
            assert((lines_read.count < lines_actual.count) &&
                   (! @context.eof),
                   format('%s: read %i of %i line(s), but got EOF',
                          file,
                          lines_read.count,
                          lines_actual.count))
            assert_equal(lines_read[line_num],
                         lines_actual[line_num],
                         format('Wrong line %i from %s',
                                line_num + 1,
                                file))
            line_num	+= 1
            previous_line = line
          else
            assert(false,
                   format('received %s:%s rather than String or nil',
                          line.class.name,
                          line.inspect))
          end
        end
      ensure
        @context.close
      end
      #
      # We've processed the file, so make sure what we read through
      # the input method matches what we read through File.readlines
      #
      warn(format("\n\t% line(s) read, expected %i\n",
                  lines_read.count,
                  lines_actual.count))
      assert_equal(lines_read,
                   lines_actual,
                   format('lines_read != lines_actual (%i, %i)',
                          lines_read.count,
                          lines_actual.count))
    end                         # @fixtures.grep
  end                           # def test_viafile_1_liner


  nil
end                             # class Test_Exception_Severities

# Local Variables:
# mode: ruby
# indent-tabs-mode: nil
# eval: (if (intern-soft "fci-mode") (fci-mode 1))
# eval: (auto-fill-mode 1)
# End:
