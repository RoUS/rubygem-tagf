#! /usr/bin/env ruby
#
# Manual test program for checking out paths between game locations.
#

require('bundler')
Bundler.setup
require('tagf')
require('byebug')
require('pp')
include(TAGF)

#
# Build up the barest skeleton of a game: two locations, and two paths
# between them.
#
# Eventually this should be able to be autoread from `locx.yaml`
# (which should be kept up-to-date with any change made here).
#

g		= Game.new(
  eid:		'gameloctest01',
  name:		'LocTest01',
  author:	'theRoUS',
  licence:	'Apache 2.0',
  desc:		'Test 01 of game location connexions')

loc1		= Location.new(
  eid:		'Loc1',
  game:		g,
  owned_by:	g,
  name:		'Location 1',
  desc:		'The starting (?) location: 1')

loc2		= Location.new(
  eid:		'Loc2',
  game:		g,
  owned_by:	g,
  name:		'Location 2',
  desc:		'The ending (?) location, #2')

container1	= Container.new(
  eid:		'birdcage',
  game:		g,
  owned_by:	loc1,
  name:		'birdcage',
  desc:		'A little brass birdcage, rather battered.')

item1		= Item.new(
  eid:		'bird',
  game:		g,
  owned_by:	container1,
  desc:		'A little songbird.')

cx1		= Connexion.new(
  eid:		'null-a',
  game:		g,
  owned_by:	g,
  name:		'loop-1',
  desc:		'A small hole up on the wall ' \
  		+ 'would let you crawl upwards.',
  shortdesc:	'upward-leading crawl.',
  origin:	loc1,
  destination:	loc1,
  via:		'up',
  reversible:	true)

cx2		= Connexion.new(
  eid:		'loc1-se',
  game:		g,
  owned_by:	g,
  name:		'loc1-se-loc2',
  desc:		'A low rocky tunnel slopes downward ' \
                 + 'to the southeast, leading to Location 2.',
  shortdesc:	'low rocky tunnel',
  origin:	loc1,
  destination:	loc2,
  via:		'se',
  reversible:	true)

cx3		= Connexion.new(
  eid:		'loc2-nw',
  game:		g,
  owned_by:	g,
  name:		'loc2-nw-loc1',
  desc:		'A low rocky tunnel slopes upward ' \
                 + 'to the northwest, leading to Location 1.',
  shortdesc:	'low rocky tunnel',
  origin:	loc2,
  destination:	loc1,
  via:		'nw',
  reversible:	true)
loc1.paths['up']= cx1
loc1.paths['se']= cx2
loc2.paths['nw']= cx3

filer		= TAGF::Filer.new
g2		= filer.load_game('locx.yaml')

File.open('l1cx.yaml', 'w') do |f|
  f.puts(g.export_game.to_yaml)
end
g3		= filer.load_game('l1cx.yaml')

debugger

puts('Ta-daaa!')

# Local Variables:
# mode: ruby
# indent-tabs-mode: nil
# eval: (if (intern-soft "fci-mode") (fci-mode 1))
# eval: (auto-fill-mode 1)
# End:
