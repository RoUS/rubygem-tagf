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
# Namespace for locally-defined tasks.
#
namespace(:local) do

  namespace(:emacs) do

    desc('Generate TAGS file for use by Emacs')
    task(:tags) do
      ctags_opts	= %i[
        -e
        --Ruby-kinds=-f
        -o TAGS
        -R
        --exclude=vendor/*
        .
      ]
      system('ctags ' + ctags_opts.join(' '))
    end

  end                           # namespace(:emacs) do

end                             # namespace(:local) do

# Local Variables:
# mode: ruby
# indent-tabs-mode: nil
# eval: (if (intern-soft "fci-mode") (fci-mode 1))
# End:
