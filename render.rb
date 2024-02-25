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

#
# Load in a TAGF game definition from a `YAML` file, build it as a
# digraph using `ruby-graphviz`, and render it into a PNG file.
#
# Invisible Location and Path elements are depicted in red, with the
# paths using dashed rather than solid lines.
#
# Path elements which are marked reversible use an open diamond as the
# arrowhead at the destination end.  If they <em>aren't</em>
# reversible, the arrowhead is a double arrow instead to indicate the
# path is one-way.
#
require('bundler')
Bundler.setup
require('tagf')
require('ostruct')
require('ruby-graphviz')
require('byebug')

#
# Different conditions use different styles, and nodes use different
# ones than edges.  Define the default attributes, and then the ones
# modified by circumstance.
#
grafattr		= OpenStruct.new(
  node:			OpenStruct.new(
    #
    # By default, nodes will look like this.
    #
    default:		{
      color:		'black',
      shape:		'rectangle',
      style:		'filled',
      fillcolor:	'silver',
    },
    #
    # If a location is invisible, modify its appearance as follows.
    #
    invisible:		{
      shape:		'ellipse',
      fillcolor:	'red',
    }),
  edge:			OpenStruct.new(
    #
    # Normal path depiction.
    #
    default:		{
      color:		'slategrey',
      style:		'solid',
      arrowhead:	'odiamond',
    },
    #
    # If it's invisible, its looks are modified as follows.
    #
    invisible:		{
      color:		'red',
      style:		'dashed',
    },
    #
    # And if it can only be traversed one direction, mark it so.
    #
    irreversible:		{
      arrowhead:	'normalnormal',
    })
)

#
# Read in the game definition.
#
fioer			= TAGF::Filer.new
game			= fioer.load_game('locx.yaml')

#
# Prepare to graph this bugger.
#
locgraf			= GraphViz.new(:TAGF,
                                       type:	:digraph,
                                       label:	format('%s locations',
                                                       game.name))

#
# We keep hashes of location elements and the graph nodes keyed by the
# location EIDs.  This will be useful later for navigating through
# things.
#
lochash			= {}
nodehash		= {}

#
# Go through the list of game elements and create a graph node for
# each Location object.  Ignore all other types of elements.
#
game.inventory.each do |eid,locelt|
  next unless (locelt.kind_of?(TAGF::Location))
  attr			= {
    label:		locelt.name,
  }.merge(grafattr.node.default)
  attr.merge!(grafattr.node.invisible) unless (locelt.is_visible?)
  locnode		= locgraf.add_nodes(eid,
                                            **attr)
  lochash[eid]		= locelt
  nodehash[eid]		= locnode
end

#
# Go through the Location elements we've stored, and turn their paths
# into graph edges.
#
lochash.values.each do |locelt|
  locelt.paths.each do |cxelt|
    attr		= {
      #
      # Since a path may be accessed by more than one keyword, the
      # label lists all keywords that apply.
      #
      label:		cxelt.via.join(','),
    }.merge(grafattr.edge.default)
    attr.merge!(grafattr.edge.invisible) unless (cxelt.is_visible?)
    attr.merge!(grafattr.edge.irreversible) unless (cxelt.reversible?)
    locgraf.add_edge(nodehash[cxelt.origin.eid],
                     nodehash[cxelt.destination.eid],
                     **attr)
  end
end

#
# Doughnut batter is ready, time to pop them in the eazy bacon oven!
#
locgraf.output(png: 'location-map.png')

# Local Variables:
# mode: ruby
# indent-tabs-mode: nil
# eval: (if (intern-soft "fci-mode") (fci-mode 1))
# eval: (auto-fill-mode 1)
# End:
