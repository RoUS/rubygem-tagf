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
require('psych')
require('yaml')
require('byebug')

# @!macro doc.TAF.module
module TAF

  #
  class Game

    include(::TAF::ContainerMixin)

    #
    attr_reader(:inventory)

    #
    flag(:loaded)

    #
    attr_reader(:threadgroup)

    #
    def initialize(*args, **kwargs)
      warn('[%s]->%s running' % [self.class.name, __method__.to_s])
      @threadgroup	= ThreadGroup.new
      threadgroup.add(Thread.current)
      self.game		= self
      self.owned_by	= self
      kwargs.delete(:slug) if (@slug = kwargs[:slug])
      kwargs.delete(:name) if (self.name = kwargs[:name])
      @slug		||= self.object_id
      self.name		||= ''
      self.static!
      self.initialize_thing(*args, **kwargs)
      self.initialize_container(*args, **kwargs)
      self.create_inventory_on(self,
                               game:		self,
                               owned_by:	self,
                               master:		true)
      self.add(self)
      self.allow_containers!
    end                         # def initialize

    inventory_niladics	= %i[
      keys
      actors
      containers
      inventories
      items
      locations
      npcs
    ]
    inventory_niladics.each do |meth|
      define_method(meth) {
        self.inventory.send(meth)
      }
    end

    #
    def [](*args)
      return @inventory.send(__method__, *args)
    end                         # def []

    #
    def create_inventory_on(target, **kwargs)
      if (target.has_inventory?)
        raise_exception(AlreadyHasInventory, target)
      end
      kwargs		= kwargs.dup
      kwargs[:game]	= self.game
      kwargs[:owned_by]	= target
      kwargs[:master]	= (target == self.game ? true : false)
      target.inventory	= Inventory.new(**kwargs)
      self.game.add(target.inventory)
      return target.inventory
    end                         # def create_inventory_on

    #
    def create_item(**kwargs)
      override		= {
        game:		self.game
      }
      kwargs		= override.merge(kwargs.merge(owned_by: self.game))
      item		= Item.new([], **kwargs)
      self.game.add(item)
      return item      
    end                         # def create_item

    #
    def create_item_on(target, **kwargs)
      kwargs		= kwargs.merge(owned_by: target)
      item		= self.create_item(**kwargs)
      target.add(item)
      return item
    end                         # def create_item_on

    #
    def create_container(**kwargs)
      override		= {
        game:		self.game
      }
      kwargs		= override.merge(kwargs.merge(owned_by: self.game))
      item		= Container.new([], **kwargs)
      self.game.add(item)
      return item      
    end                         # def create_container

    #
    def create_container_on(target, **kwargs)
      kwargs		= kwargs.merge(owned_by: target)
      item		= self.create_container(**kwargs)
      target.add(item)
      return item
    end                         # def create_container_on

    #
    def create_location(**kwargs)
      override		= {
        game:		self.game
      }
      kwargs		= override.merge(kwargs.merge(owned_by: self.game))
      item		= Location.new([], **kwargs)
      self.game.add(item)
      return item      
    end                         # def create_location

    #
    def create_location_on(target, **kwargs)
      kwargs		= kwargs.merge(owned_by: target)
      item		= self.create_location(**kwargs)
      target.add(item)
      return item
    end                         # def create_location_on

    #
    def inspect
      result		= '#<%s:"%s" name="%s">' \
                          % [
        self.class.name,
        self.slug.to_s,
        self.name.to_s
      ]
      return result
    end                         # def inspect

    #
    # @todo
    #   * Really need to mutex or threadlock the inventories..
    #
    def change_slug(obj=nil, oldslug=nil, newslug=nil, **kwargs)
      obj		||= kwargs[:object]
      oldslug		||= kwargs[:oldslug]
      newslug		||= kwargs[:newslug]
      unless (obj.respond_to?(:slug))
        raise_exception(NotGameElement, obj)
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
            raise_exception(KeyObjectMismatch,
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
      return inventories_edited
    end                         # def change_slug

    #
    def load(*args, **kwargs)
      @elements		||= {}
      if (self.loaded?)
        raise_exception(GameAlreadyLoaded, self)
      end
      if ((loadfile = kwargs[:file]).nil?)
        raise_exception(NoLoadFile)
      end
      begin
        @elements	= YAML.load(File.read(loadfile))
      rescue StandardError => e
        raise_exception(BadLoadFile,
                        file:		loadfile,
                        exception:	e)
      end
      return @elements
    end                         # def load

    nil
  end                           # class Game

  nil
end                             # module TAF

# Local Variables:
# mode: ruby
# indent-tabs-mode: nil
# eval: (if (intern-soft "fci-mode") (fci-mode 1))
# End:
