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

require('fileutils')

topsrcdir	= File.dirname(__FILE__)
Proc.new {
  libdir	= File.join(topsrcdir, 'lib')
  xlibdir	= File.expand_path(libdir)
  $:.unshift(xlibdir) unless ($:.include?(libdir) || $:.include?(xlibdir))
}.call

require('bundler/gem_tasks')

include Rake::DSL

require('rake/testtask')
Rake::TestTask.new(:test) do |t|

  t.libs	<< 'test'
  t.libs	<< 'lib'
  # helper(simplecov) must be required before loading power_assert
  helper_path	= File.realpath('test/test_helper.rb')
  t.ruby_opts	= ['-w', "-r#{helper_path}"]
  t.test_files	= FileList['test/**/*_test.rb'].exclude do |i|
    begin
      next false unless defined?(RubyVM)
      RubyVM::InstructionSequence.compile(File.read(i))
      false
    rescue SyntaxError
      true
    end                         # begin
  end                           # t.test_files = FileList[]
end                             # Rake::TestTask.new(:test) do

#
# Load our local tasks.
#
Dir['tasks/**/*.rake'].each { |t| load(t) }

task(:default => 'doc:yard')

# Local Variables:
# mode: ruby
# indent-tabs-mode: nil
# eval: (if (intern-soft "fci-mode") (fci-mode 1))
# End:
