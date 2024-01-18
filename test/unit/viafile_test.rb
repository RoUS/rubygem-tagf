require('tagf/ui')
require('tagf/exceptions')
require('byebug')
require('pathname')
require('test/unit')

class Test_InputMethod_ViaFile < Test::Unit::TestCase

  FixtureDir		= File.join(Pathname(__FILE__).dirname,
                                    '..',
                                    'fixtures')

  include TAGF::UI
  include TAGF::Exceptions

  def setup
    @iface		= Interface.new(inputmethod:	'ViaFile',
                                        record:		false,
                                        transcribe:	false)
    nil
  end                           # def setup

  def teardown
    nil
  end                           # def teardown

  def access_file(base)
    fspec		= File.expand_path(base, FixtureDir)
    @context		= Context.new(interface:	@iface,
                                      inputmethod:	'ViaFile',
                                      record:		false,
                                      transcribe:	false,
                                      file:		fspec)
    @lines		= File.readlines(fspec).map { |l| l.chomp }
    return @lines
  end

  # * Tes that ViaFile properly reads a single line.
  def test_viafile_1_liner
    access_file('viafile-lines-1.txt')
    assert_equal(@context.read,
                 @lines[0],
                 format('Verifying read line %i of %i',
                        1,
                        @lines.count))
    assert_nil(@context.read, 'Verifying EOF returned nil')
    assert(@context.eof?, 'Verifying EOF flag set')
  end                           # def test_viafile_1_liner


  nil
end                             # class Test_Exception_Severities

# Local Variables:
# mode: ruby
# indent-tabs-mode: nil
# eval: (if (intern-soft "fci-mode") (fci-mode 1))
# eval: (auto-fill-mode 1)
# End:
