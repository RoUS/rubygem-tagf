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

require_relative('../sptaf')
require('byebug')

# @!macro doc.TAF
module TAF

  #
  class Game

    include(::TAF::ContainerMixin)

    #
    attr_accessor(:inventory)

    #
    def load(*args, **kwargs)
      @elements		= {}
      if ((loadfile = kwargs[:file]).nil?)
        raise_exception(NoLoadFile)
      end
      begin
        @elements	= YAML.load(File.read(loadfile))
      rescue StandardError => e
        raise_exception(BadLoadFile, file: loadfile, exception: e)
      end
      return @elements
    end                         # def load

    #
    def items
      return self.inventory.select { |o| o.kind_of?(::TAF::Item) }
    end                         # def items

    #
    def locations
      return self.inventory.select { |o| o.kind_of?(::TAF::Location) }
    end                         # def locations

    #
    # @todo
    #   * Really need to mutex or threadlock the inventories..
    #
    def change_slug(obj=nil, oldslug=nil, newslug=nil, **kwargs)
      obj		||= kwargs[:object]
      oldslug		||= kwargs[:oldslug]
      newslug		||= kwargs[:newslug]
      unless (obj.respond_to?(:slug))
        self.raise_exception(NotGameElement, obj)
      end
      g			= self.game
      inventories	= g.inventory.select { |o|
        o.kind_of?(::TAF::Inventory) && o.keys.include?(oldslug)
      }
      inventories.unshift(self.game.inventory)
      inventories_edited = []
      if (inventories.empty?)
        warn("No inventories found containing slug '%s'" % [oldslug])
      else
        obj.instance_variable_set(:@slug, newslug)
        inventories.each do |i|
          ckobj		= i[oldslug]
          if (ckobj != obj)
            self.raise_exception(KeyObjectMismatch,
                                 oldslug,
                                 obj,
                                 ckobj,
                                 i.name)
          end
          i.delete(oldslug)
          i.add(obj)
          inventories_edited <<	i
        end                     # inventories.each do
      end
      obj.instance_variable_set(:@slug, newslug)
      return inventories_edited
    end                         # def change_slug

    #
    def initialize(*args, **kwargs)
      warn('[%s] %s' % [self.class.name, __method__.to_s])
      self.object_setup do
        self.game	= self
        self.owned_by	= self
        self.static!
=begin
        self.inventory	= ::TAF::Inventory.new(game:	self,
                                               owned_by: self,
                                               master:	true)
=end
      end                       # self.object_setup
      self.initialize_thing(*args, **kwargs)
      self.initialize_container(*args, **kwargs)
      debugger
      self.add_inventory(game:		self,
                         owned_by:	self,
                         master:	true)
      self.add(self)
    end                         # def initialize

    nil
  end                           # class Game

  nil
end                             # module TAF

# Local Variables:
# mode: ruby
# indent-tabs-mode: nil
# eval: (if (intern-soft "fci-mode") (fci-mode 1))
# End:
