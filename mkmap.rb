#! /usr/bin/env ruby
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

require('rubygems')
require('ostruct')
require('byebug')
require('ruby-graphviz')

elts		= OpenStruct.new
elts.modules	||= []
elts.classes	||= []

attrmap		= OpenStruct.new(
  mixin:	{
    color:	'red',
    fillcolor:	'orange',
  },
  klass:	{
    color:	'blue',
    fillcolor:	'lime',
  },
  has:		{
    label:	'has',
    color:	'blue',
  },
  included_by:	{
    label:	'included-by',
    color:	'green',
  },
  extended_by:	{
    label:	'extended-by',
    color:	'cyan',
  })

mgraf		= GraphViz.new(:TAF,
                               type:	:digraph,
                               label:	'TAF')

module_taf	= mgraf.add_nodes('module_TAF')
module_taf[:label] = 'module TAF'
elts.module_taf	= module_taf
elts.modules.push(module_taf)

module_classmethods= mgraf.add_nodes('module_ClassMethods',
                                     label:	'module ClassMethods')
mixins		= mgraf.add_nodes('module_Mixins',
                                  {
                                    label:	'module Mixins',
                                  }.merge(attrmap.mixin))
mixin_actor	= mgraf.add_nodes('module_Actor',
                                  {
                                    label:	'module Mixins::Actor',
                                  }.merge(attrmap.mixin))
mixin_container	= mgraf.add_nodes('module_Container',
                                  {
                                    label:	'module Mixins::Container',
                                  }.merge(attrmap.mixin))
mixin_debug	= mgraf.add_nodes('module_Debugging',
                                  {
                                    label:	'module Mixins::Debugging',
                                  }.merge(attrmap.mixin))
mixin_element	= mgraf.add_nodes('module_Element',
                                  {
                                    label:	'module Mixins::Element',
                                  }.merge(attrmap.mixin))
mixin_events	= mgraf.add_nodes('module_Events',
                                  {
                                    label:	'module Mixins::Events',
                                  }.merge(attrmap.mixin))
mixin_exceptions= mgraf.add_nodes('module_Exceptions',
                                  {
                                    label:	'module Exceptions',
                                  }.merge(attrmap.mixin))
mixin_location	= mgraf.add_nodes('module_Location',
                                  {
                                    label:	'module Mixins::Location',
                                  }.merge(attrmap.mixin))
class_connexion	= mgraf.add_nodes('class_Connexion',
                                  {
                                    label:	'class Connexion',
                                  }.merge(attrmap.klass))
class_container	= mgraf.add_nodes('class_Container',
                                  {
                                    label:	'class Container',
                                  }.merge(attrmap.klass))
class_faction	= mgraf.add_nodes('class_Faction',
                                  {
                                    label:	'class Faction',
                                  }.merge(attrmap.klass))
class_feature	= mgraf.add_nodes('class_Feature',
                                  {
                                    label:	'class Feature',
                                  }.merge(attrmap.klass))
class_game	= mgraf.add_nodes('class_Game',
                                  {
                                    label:	'class Game',
                                  }.merge(attrmap.klass))
class_inventory	= mgraf.add_nodes('class_Inventory',
                                  {
                                    label:	'class Inventory',
                                  }.merge(attrmap.klass))
class_item	= mgraf.add_nodes('class_Item',
                                  {
                                    label:	'class Item',
                                  }.merge(attrmap.klass))
class_location	= mgraf.add_nodes('class_Location',
                                  {
                                    label:	'class Location',
                                  }.merge(attrmap.klass))
class_npc	= mgraf.add_nodes('class_NPC',
                                  {
                                    label:	'class NPC',
                                  }.merge(attrmap.klass))
class_player	= mgraf.add_nodes('class_Player',
                                  {
                                    label:	'class Player',
                                  }.merge(attrmap.klass))
class_reality	= mgraf.add_nodes('class_Reality',
                                  {
                                    label:	'class Reality',
                                  }.merge(attrmap.klass))

[
  [mixin_actor,		class_npc],
  [mixin_actor,		class_player],
  [mixin_container,	class_container],
  [mixin_container,	class_feature],
  [mixin_container,	class_game],
  [mixin_container,	mixin_actor],
  [mixin_container,	mixin_location],
  [mixin_debug,		module_taf],
  [mixin_element,	class_connexion],
  [mixin_element,	class_faction],
  [mixin_element,	class_inventory],
  [mixin_element,	class_item],
  [mixin_element,	class_reality],
  [mixin_element,	mixin_container],
  [mixin_events,	module_taf],
  [mixin_exceptions,	module_taf],
  [mixin_location,	class_location],
  [module_taf,		mixin_element],
  [module_taf,		mixin_events],
  [module_taf,		mixin_exceptions],
  [module_taf,		module_classmethods],
].each do |(n1, n2)|
  mgraf.add_edge(n1, n2, attrmap.included_by)
end

=begin

#
# Add edges showing what classes include instances of others,
# like containers having inventories.
#
[
  [class_container,	class_inventory],
  [class_feature,	class_inventory],
  [class_game,		class_inventory],
  [class_location,	class_inventory],
].each do |(n1, n2)|
  mgraf.add_edge(n1, n2, attrmap.has)
end

[
  [mixin_debug,		module_classmethods],
  [module_classmethods,	mixin_container],
  [module_classmethods,	mixin_location],
  [module_classmethods,	module_taf],
].each do |(n2, n1)|
  mgraf.add_edge(n1, n2, attrmap.extended_by)
end

=end

mgraf.output(png: 'module-map.png')

# Local Variables:
# mode: ruby
# indent-tabs-mode: nil
# eval: (if (intern-soft "fci-mode") (fci-mode 1))
# End:
