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
#

require('yard')

namespace(:doc) do
  task(:yard)
  desc('Generate Yardoc documentation')
  YARD::Rake::YardocTask.new do |yardoc|
    yardoc.name         = 'yard'
    #
    # Note that we're using a NON-STANDARD options file and parsing
    # it manually.  This is partly so we can do special things with
    # it, and also so a set of standard options can be kept in a
    # reusable `.yardopts` file.  `.yardopts-local` is <em>per</em>
    # project settings.
    #
    # Also, this allows us to embed comments in the file, although
    # there is currently an issue with unmatched quote/apostrophe
    # marks in a comment.
    #
    # @todo Fix unmatched quotes in comments ("# It's a problem")
    #
    options_file	= '.yardopts-local'
    if (File.exist?(options_file))
      yo_lines		= File.readlines(options_file).map(&:chomp)
      #
      # Remove any trailing comments, including comment-only lines
      #
      yo_lines		= yo_lines.map { |l|
        l.sub(%r!^\s*#.*!, '').strip
      }
      yo_lines.delete('')
      yo_lines		= yo_lines.map { |l|
        cmtfound	= false
        words		= Shellwords.split(l).select { |token|
          cmtfound	||= (token =~ %r!^#!)
          (! cmtfound)
          # thorpe	= words.index('#')
          # words	= words[0, thorpe] unless (thorpe.nil?)
        }
        words.join(' ')
      }                         # yo_lines = yo_lines.map
      #
      # Now get rid of dups.
      #
      yo_lines		= yo_lines.uniq
      #
      # Separate the contents of .yardopts into actual options and
      # file specifications.  Note that a 
      #
      (opts, files)	= yo_lines.partition { |l|
        l =~ %r!^-([[:space:]]*.$|-)!
      }
      #
      # ..and put them into the appropriate parts of the yardoc
      # object we were passed.
      #
      yardoc.options	= opts
      yardoc.files	= FileList[*files]
    end
    #
    # Add some options we pretty much always want to have.
    #
    yardoc.options      ||= %i[ --verbose ]
    $stdout.puts(yardoc.options.inspect)
    $stdout.puts(yardoc.files.inspect)
  end                         # YARD::Rake::YardocTask.new do |yardoc|
end                           # namespace(:doc)

# Local Variables:
# mode: ruby
# indent-tabs-mode: nil
# eval: (if (intern-soft "fci-mode") (fci-mode 1))
# End:
