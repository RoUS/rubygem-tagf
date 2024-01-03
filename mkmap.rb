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

mgraf		= GraphViz.new(:TAGF,
                               type:	:digraph,
                               label:	'TAGF')

module_tagf	= mgraf.add_nodes('module_TAGF')
module_tagf[:label] = 'module TAGF'
elts.module_tagf	= module_tagf
elts.modules.push(module_tagf)

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
  [mixin_debug,		module_tagf],
  [mixin_element,	class_connexion],
  [mixin_element,	class_faction],
  [mixin_element,	class_inventory],
  [mixin_element,	class_item],
  [mixin_element,	class_reality],
  [mixin_element,	mixin_container],
  [mixin_events,	module_tagf],
  [mixin_exceptions,	module_tagf],
  [mixin_location,	class_location],
  [module_tagf,		mixin_element],
  [module_tagf,		mixin_events],
  [module_tagf,		mixin_exceptions],
  [module_tagf,		module_classmethods],
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
  [module_classmethods,	module_tagf],
].each do |(n2, n1)|
  mgraf.add_edge(n1, n2, attrmap.extended_by)
end

tagf_eigenclass.provides = %w[
game_options
]

tagf.provides = %w[
game_options?
raise_exception
is_game_element?
pluralise
truthify
decompose_attrib
]

classmethods.provides = %w[
_inivaluate_args
flag
float_accessor
float_reader
float_writer
int_accessor
int_reader
int_writer
]

actor.provides = %w[
initialize_actor
add
]

container.provides = %w[
flag_allow_containers
is_empty?
flag_is_surface
flag_is_openable
flag_is_open
flag_is_transparent
inventory
inventory=
capacity_items
capacity_items=
current_items
current_items=
capacity_mass
capacity_mass=
current_mass
current_mass=
capacity_volume
capacity_volume=
current_volume
current_volume=
pending_inventory
pending_inventory=
contains_item?
update_inventory!
add
inventory_is_full
initialize_container
]

element.provides = %w[
eid
game
game=
owned_by
owned_by=
name
name=
desc
desc=
shortdesc
shortdesc=
illumination
illumination=
pct_dim_per_turn
pct_dim_per_turn=
flag_only_dim_near_player
mass
mass=
volume
volume=
flag_is_static
flag_is_visible
article
article=
preoposition
preposition=
describe
is_container?
has_inventory?
has_items?
add_inventory
move_to
contained_in
initialize_element
]

=end

mgraf.output(png: 'module-map.png')

# Local Variables:
# mode: ruby
# indent-tabs-mode: nil
# eval: (if (intern-soft "fci-mode") (fci-mode 1))
# eval: (auto-fill-mode 1)
# End:
