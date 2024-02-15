#! /usr/bin/env ruby
#
# Manual test program for checking out paths between game locations.
#

require('bundler')
Bundler.setup
require('tagf')
require('byebug')

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
  desc:		'The ending (?) location: 2')
cx1		= Connexion.new(
  eid:		'loc1-se',
  game:		g,
  owned_by:	loc1,
  name:		'loc1-se-loc2',
  desc:		'going from loc1 to loc2 via se',
  origin:	loc1,
  destination:	loc2,
  reversible:	true)
cx2		= Connexion.new(
  eid:		'loc2-nw',
  game:		g,
  owned_by:	loc2,
  name:		'loc2-nw-loc1',
  desc:		'going from loc2 to loc1 via nw',
  origin:	loc2,
  destination:	loc1,
  reversible:	true)
loc1.paths['se']= cx1
loc2.paths['nw']= cx2

debugger
puts('Ta-daaa!')

# Local Variables:
# mode: ruby
# indent-tabs-mode: nil
# eval: (if (intern-soft "fci-mode") (fci-mode 1))
# eval: (auto-fill-mode 1)
# End:
