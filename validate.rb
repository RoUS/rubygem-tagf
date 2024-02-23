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

require('bundler')
Bundler.setup
require('tagf')
require('ostruct')
require('ruby-graphviz')
require('byebug')

fioer		= TAGF::Filer.new
game		= fioer.load_game('locx.yaml')
debugger
locgraf		= GraphViz.new(:TAGF,
                               type:	:digraph,
                               label:	format('%s locations',
                                               game.name))
lochash		= {}
nodehash	= {}
game.inventory.each do |eid,locelt|
  next unless (locelt.kind_of?(TAGF::Location))
  locnode	= locgraf.add_nodes(eid,
                                    {
                                      label: locelt.name,
                                    })
  lochash[eid]	= locelt
  nodehash[eid]	= locnode
end
lochash.values.each do |locelt|
  locelt.paths.each do |via,cxelt|
    locgraf.add_edge(nodehash[cxelt.origin.eid],
                     nodehash[cxelt.destination.eid],
                     {
                       label: cxelt.via,
                     })
    
  end
end

locgraf.output(png: 'location-map.png')

# Local Variables:
# mode: ruby
# indent-tabs-mode: nil
# eval: (if (intern-soft "fci-mode") (fci-mode 1))
# eval: (auto-fill-mode 1)
# End:
