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

require_relative('lib/tagf/version')

Gem::Specification.new do |gem|
  gem.name		= 'tagf'
  gem.version		= TAGF::VERSION

  if (gem.respond_to?(:required_rubygems_version=))
    gem.required_rubygems_version = Gem::Requirement.new('>= 1.7.2')
  end
  gem.authors		= ['Ken Coar']
  gem.email		= ['The.Rodent.of.Unusual.Size+tagf@gmail.com']

  gem.date		= '2022-05-28'
  gem.summary		= 'Text Adventure Game Framework gem'
  gem.description	= 'Provide a basis for mostly data-driven text game construction.'
  gem.homepage		= 'http://github.com/RoUS/tagf'

  gem.licenses		= ['Apache 2.0']
  gem.rubygems_version 	= '1.7.2'
  gem.required_ruby_version \
        		= TAGF::RUBY_VERSION_MIN_GEMSPEC
  gem.metadata['rubygems_mfa_required'] = 'String' # eh? true
  gem.metadata['allowed_push_host'] \
  			= 'TODO: Set to your gem server "https://example.com"'

  gem.metadata['homepage_uri'] \
  			= gem.homepage
  gem.metadata['source_code_uri'] \
  			= 'https://example.com/'
  gem.metadata['changelog_uri'] \
  			= 'https://example.com/'

  #
  # Specify which files should be added to the gem when it is
  # released.  The `git ls-files -z` loads the files in the RubyGem
  # that have been added into git.
  #
  gem.require_paths 	= ['lib']
  gem.files 		= Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject do |f|
      ((f == __FILE__) \
       || f.match(%r{\A(?:(?:test|spec|features)/|\.(?:git|travis|circleci)|appveyor)}))
    end
  end

end                 # Gem::Specification.new do

# Local Variables:
# mode: ruby
# indent-tabs-mode: nil
# eval: (if (intern-soft "fci-mode") (fci-mode 1))
# End:
