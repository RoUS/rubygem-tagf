#! /usr/bin/env ruby
#
# Manual test program for checking out paths between game locations.
#

require('bundler')
Bundler.setup
require('optparse')
require('yaml')
require('byebug')
require('pp')

cmdopts = {
  file_ref:	'locx-manual.yaml',
  file_test:	'locx-exported.yaml',
  verbosity:	0,
}

oparser = OptionParser.new do |odef|
  odef.version  = '0.1.0'
  odef.banner   = <<-EOT
Compares two TAGF game YAML files.

One (either $1 or the --reference option value) is considered
the 'gold standard'; the second file is compared to it.  All fields
in the reference file are considered mandatory; any extra fields
or definitions in the test file are pruned before comparison.

Usage: #{File.basename($0)} [OPTIONS] [REF-FILE [TEST-FILE]]

  EOT

  desc          = ('YAML file providing the reference for ' \
                   + "comparison.  Default is #{cmdopts[:file_ref]}.")
  odef.on('-r FILE', '--reference', String, desc) do |rfile|
    cmdopts[:file_ref]	= rfile
  end

  desc          = ('YAML file to be compared to the reference.' \
                   + "  Default is #{cmdopts[:file_test]}.")
  odef.on('-t FILE', '--test', String, desc) do |tfile|
    cmdopts[:file_test]	= tfile
  end

  desc		= 'Increase verbosity.'
  odef.on('-v', '--verbose', desc) do |verbosity|
    cmdopts[:verbosity] += 1
  end
end
oparser.parse!

if (cmdopts[:file_ref].nil?)
  alt			= ARGV[0]
  cmdopts[:file_ref]	= alt || 'locx-manual.yaml'
end

if (cmdopts[:file_test].nil?)
  alt			= ARGV[0] ? ARGV[1] : ARGV[0]
  cmdopts[:file_test]	= alt || 'locx-exported.yaml'
end

@verbosity		= cmdopts[:verbosity]
#
# Trim a copy of the candidate so it only contains the same keys as
# the reference hash.  And sort both by key.  Returns a two-element
# array; the first is a copy of the refhash sorted by key, the second
# is an edited copy of the candidate, also sorted by key.
#
def compare_record(sect, eid, refhash, testhash)
  result	= true
  keys		= refhash.keys.sort { |a,b| a.to_s <=> b.to_s }
  keys.each do |key|
    unless (@verbosity.zero?)
      puts(format('Checking "%s[%s].%s ..',
                  sect,
                  refhash['eid'],
                  key.to_s))
    end
    reference	= refhash[key]
    candidate	= testhash[key]
    if (candidate != reference)
      result	= false
      warn(format("Mismatch in section '%s' EID '%s': field '%s'\n" +
                  "  reference: %s\n" +
                  "  test:      %s",
                  sect,
                  refhash['eid'],
                  key.to_s,
                  reference.inspect,
                  (testhash.has_key?(key) \
                   ? candidate.inspect \
                   : 'MISSING')))
      @diffcount += 1
    end
  end
  return result
end

yaml_ref	= YAML.load(File.read(cmdopts[:file_ref]))
yaml_test	= YAML.load(File.read(cmdopts[:file_test]))

reference	= ''
candidate	= ''

@success	= true
@diffcount	= 0
unless (@verbosity.zero?)
  puts(format('Comparing YAML from "%s" with reference "%s"',
              cmdopts[:file_test],
              cmdopts[:file_ref]))
end

yaml_ref.each do |sect,elt_ref|
  #
  # Each sect is a top-level hash key.  The value is either a hash, or
  # an array of hashes.
  #
  elt_test		= yaml_test[sect]
  reference	= {}
  candidate	= {}
  unless (@verbosity.zero?)
    puts(format("Checking classes for section '%s'",
                sect))
  end
  if (elt_test.class != elt_ref.class)
    warn(format("** Class mismatch in section '%s':\n" +
                "  reference: %s\n" +
                "  test:      %s",
                elt_ref.class.to_s,
                elt_test.class.to_s))
    @diffcount	+= 1
    @success	= false
    next
  elsif (elt_ref.kind_of?(Hash))
    unless (compare_record(sect, elt_ref['eid'], elt_ref, elt_test))
      @diffcount += 1
      @success	= false
    end
  elsif (elt_ref.kind_of?(Array))
    eids	= elt_ref.map { |e| e['eid'] }.sort
    eids.each do |eid|
      reference	= elt_ref.find { |e| e['eid'] == eid }
      candidate	= elt_test.find { |e| e['eid'] == eid }
      unless (compare_record(sect, eid, reference, candidate))
        @diffcount += 1
        @success = false
      end
    end
  end
end

if (@success)
  unless (@verbosity.zero?)
    puts('YAML is functionally equivalent.')
  end
else
  warn(format('Significant differences (%i) were found.',
              @diffcount))
end
exit(@success ? 0 : 1)

# Local Variables:
# mode: ruby
# indent-tabs-mode: nil
# eval: (if (intern-soft "fci-mode") (fci-mode 1))
# eval: (auto-fill-mode 1)
# End:
