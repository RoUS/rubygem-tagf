#--
# Copyright 2022 Ken Coar
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

topsrcdir	= File.dirname(File.dirname(__FILE__))
namespace(:local) do

  desc('Convert markdown files to HTML')
  task(:markdown) do
    datadir	= File.join(topsrcdir, 'pandoc')
    cssfiles	= Dir["#{datadir}/*.css"]
    cssfiles	= cssfiles.map { |f|
      f.sub(%r!#{topsrcdir}/(.*)!, '--css=\1')
    }
    pandoc_options = %I[
      --standalone
      --data-dir=#{datadir}
      --from=markdown+backtick_code_blocks+fenced_divs
      --to=html
    ] | cssfiles

    Dir[File.join(topsrcdir, '*.md')].each do |mdname|
      muname	= mdname.sub(%r!\.md$!, '.html')
      tocname	= mdname.sub(%r!\.md$!, '.build-toc')
      if ((! File.exist?(muname)) \
          || (File.mtime(muname) < File.mtime(mdname)))
        $stdout.print("Converting #{mdname}:")
        toc_opt	= File.exist?(tocname) ? '--toc' : ''
        title	= muname.sub(%r!\.[^.]*$!, '').sub(%r!^\./!, '')
        command	= %I[
          pandoc
          #{pandoc_options.join(' ')}
          --metadata-file=#{datadir}/metadata.yaml
          --metadata=title="#{title}"
          --output="#{muname}"
          #{toc_opt}
          "#{mdname}"
        ].join(' ')
        warn(command)
        system(command)
        $stdout.puts(' done.')
      end
    end
  end                           # task(:markdown) do
end                             # namespace(:local) do

# Local Variables:
# mode: ruby
# indent-tabs-mode: nil
# eval: (if (intern-soft "fci-mode") (fci-mode 1))
# End:
