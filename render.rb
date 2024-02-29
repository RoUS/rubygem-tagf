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
# Path elements which are marked reversible use a single arrowhead to
# retain the indication of the main direction.  If a path is
# <em>not</em> reversible, a double-arrowhead is used to emphasise
# that it's a one-way-only path.  So:
#
# * One arrowhead (`→`)
# : The path is reversible, and commands for 'go back' will backtrace
#   along it.
# * Double arrowhead (`↠`)
# : The path is IRreversible; once followed, 'go back' commands won't
#   return along it.
#
# Paths which are sealable (`kind_of?(TAGF::Mixin::Sealable)`)
# <em>and</em> openable will be annotated with either a door "🚪" (if
# not lockable) or a padlock.  If it's locked, a padlock & key "🔐"
# will be used; if it's unlocked, an open padlock "🔓" will be used.
#
require('bundler')
Bundler.setup
require('tagf')
require('ostruct')
require('pathname')
require('rgl/adjacency')
require('rgl/dijkstra')
require('rgl/dot')
require('byebug')

edgeweights		= {}
graph_attr		= OpenStruct.new(
  vertex:			OpenStruct.new(
    #
    # By default, vertices will look like this.
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
    },
    start:		{
      shape:		'parallelogram',
      fillcolor:	'lime',
    }),
  edge:			OpenStruct.new(
    #
    # Normal path depiction.
    #
    default:		{
      color:		'slategrey',
      style:		'solid',
      arrowhead:	'normal',
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
      arrowtail:	'tee',
    })
)

#
# Read in the game definition.
#
fioer			= TAGF::Filer.new
yamlfile		= ARGV[0] || 'locx.yaml'
yamlpath		= Pathname(yamlfile)
basename		= yamlpath.to_s.sub(%r!#{yamlpath.extname}$!,
                                            '')
game			= fioer.load_game(yamlpath)
game.filter(klass: TAGF::Location).each do |loc|
  cxs			= game.filter(klass: TAGF::Path, origin: loc)
  loc.add_path(*cxs) unless (cxs.nil? || cxs.empty?)
end

#
# Prepare to graph this bugger.
#
locgraf			= RGL::DirectedAdjacencyGraph.new

#
# We keep hashes of location elements and the graph vertices keyed by
# the location EIDs.  This will be useful later for navigating through
# things.
#
lochash			= {}
vertexhash		= {}
pathhash		= {}
edgehash		= {}

#
# Go through the list of game elements and create a graph vertex for
# each Location object.  Ignore all other types of elements.
#
game.inventory.each do |eid,locelt|
  next unless (locelt.kind_of?(TAGF::Location))
  attr			= {
    label:		locelt.label,
    tooltip:		locelt.desc,
  }.merge(graph_attr.vertex.default)
  if (! locelt.visible?)
    attr		= attr.merge(graph_attr.vertex.invisible)
  end
  if (locelt == game.start)
    attr		= attr.merge(graph_attr.vertex.start)
  end
  locgraf.add_vertex(locelt)
  locgraf.set_vertex_options(locelt, **attr)
  lochash[eid]		= locelt
  vertexhash[eid]	= locelt
end

#
# Go through the Location elements we've stored, and turn their paths
# into graph edges.
#
lochash.values.each do |locelt|
  locelt.paths.each do |cxelt|
    eid			= cxelt.eid
    label_prefix	= ''
    if (cxelt.sealable? &&
        cxelt.openable?)
      if (cxelt.lockable?)
        label_prefix	= cxelt.locked ? '🔐 ' : '🔓 '
      else
        label_prefix	= '🚪 '
      end
    end
    vias		= cxelt.via.map { |k|
      game.keyword(k).root
    }.join(',')
    tip			= label_prefix + vias
    if (cxelt.respond_to?(:tooltip) &&
        cxelt.tooltip.kind_of?(String))
      tip		= format('%s[%s] %s',
                                 label_prefix,
                                 vias,
                                 cxelt.tooltip)
    end
    attr		= {
      #
      # Since a path may be accessed by more than one keyword, the
      # label lists all keywords that apply.
      #
      label:		tip, #label + vias,
      id:		eid,
      tooltip:		tip,
    }.merge(graph_attr.edge.default)
    if (! cxelt.visible?)
      attr		= attr.merge(graph_attr.edge.invisible)
    end
    if (! cxelt.reversible?)
      attr		= attr.merge(graph_attr.edge.irreversible)
    end
    origin		= lochash[cxelt.origin.eid]
    destination		= lochash[cxelt.destination.eid]
    locgraf.add_edge(origin,
                     destination)
    edgeweights[[origin,destination]] = 0.0
    edge		= locgraf.edges.find { |e|
      (e.source == origin) &&
      (e.target == destination)
    }
    locgraf.set_edge_options(origin, destination, **attr)
    edgehash[eid]	= edge
    pathhash[eid]	= cxelt
  end
end
debugger
edgeprops		= RGL::EdgePropertiesMap.new(edgeweights, true)
visitor			= RGL::DijkstraVisitor.new(locgraf)
dij			= RGL::DijkstraAlgorithm.new(locgraf,
                                                     edgeprops,
                                                     visitor)
#
# Doughnut batter is ready, time to pop them in the eazy bacon oven!
#
locgraf.write_to_graphic_file('png',
                              format('location-map-%s', basename))

# Local Variables:
# mode: ruby
# indent-tabs-mode: nil
# eval: (if (intern-soft "fci-mode") (fci-mode 1))
# eval: (auto-fill-mode 1)
# End:
