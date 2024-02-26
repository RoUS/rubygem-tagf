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
  copyright_year: '2019-2024',
  licence:	'Apache 2.0',
  desc:		'Test 01 of game location connexions')

kw_up		= Keyword.new(
  eid:		'kw-up',
  game:		g,
  owned_by:	g,
  word:		'up',
  alii:		nil,
  flags:	[
    :motion,
  ])

kw_down		= Keyword.new(
  eid:		'kw-down',
  game:		g,
  owned_by:	g,
  word:		'down',
  alii:		nil,
  flags:	[
    :motion,
  ])

kw_e		= Keyword.new(
  eid:		'kw-east',
  game:		g,
  owned_by:	g,
  word:		'east',
  alii:		[
    'e',
  ],
  flags:	[
    :motion,
    :facing,
  ])

kw_w		= Keyword.new(
  eid:		'kw-west',
  game:		g,
  owned_by:	g,
  word:		'west',
  alii:		[
    'w',
  ],
  flags:	[
    :motion,
    :facing,
  ])

kw_se		= Keyword.new(
  eid:		'kw-southeast',
  game:		g,
  owned_by:	g,
  word:		'southeast',
  alii:		[
    'se',
  ],
  flags:	[
    :motion,
    :facing,
  ])

kw_nw		= Keyword.new(
  eid:		'kw-northwest',
  game:		g,
  owned_by:	g,
  word:		'northwest',
  alii:		[
    'nw',
  ],
  flags:	[
    :motion,
    :facing,
  ])

kw_back		= Keyword.new(
  eid:		'kw-back',
  game:		g,
  owned_by:	g,
  word:		'back',
  alii:		[
    'return',
    'retreat',
  ],
  flags:	[
    :motion,
  ])

loc0		= Location.new(
  eid:		'Loc0',
  game:		g,
  owned_by:	g,
  name:		'Location 0 - Entrance',
  shortdesc:	'entrance room.',
  desc:		<<-EOT)
You're in Location 0, the starting location for players in new games.
  EOT

loc1		= Location.new(
  eid:		'Loc1',
  game:		g,
  owned_by:	g,
  name:		'Location 1',
  desc:		<<-EOT,
Room 1, one of the locations accessible from the entrance.
  EOT
  shortdesc:	'Room 1.')

loc2		= Location.new(
  eid:		'Loc2',
  game:		g,
  owned_by:	g,
  name:		'Location 2',
  desc:		'The ending (?) location, #2',
  shortdesc:	'Room 2.')

loc3		= Location.new(
  eid:		'Loc3',
  game:		g,
  owned_by:	g,
  name:		'Location 3 (secret room)',
  desc:		'The Secret Room!',
  shortdesc:	"It's a secret!")

container1	= Container.new(
  eid:		'birdcage',
  game:		g,
  owned_by:	loc1,
  name:		'birdcage',
  article:	'a',
  desc:		'rather battered little brass birdcage')

item1		= Item.new(
  eid:		'bird',
  game:		g,
  owned_by:	container1,
  is_living:	true,
  article:	'a',
  desc:		'little songbird')

cx0_0		= Path.new(
  eid:		'loc0-loc0',
  game:		g,
  owned_by:	g,
  name:		'loc0-loc0',
  sealable:	true,
  seal_key:	'RFID',
  desc:		<<-EOT,
A small hole up on the wall would let you crawl upwards.
  EOT
  shortdesc:	'upward-leading crawl.',
  origin:	loc0,
  destination:	loc0,
  via:		[
    'up',
  ],
  reversible:	true)

cx0_1		= Path.new(
  eid:		'loc0-loc1',
  game:		g,
  owned_by:	g,
  name:		'loc0-loc1',
  desc:		<<-EOT,
A broad passage, with a flat, smooth floor and smooth walls, is
visible to the east.
  EOT
  shortdesc:	'broad smooth passage.',
  origin:	loc0,
  destination:	loc1,
  via:		'e',
  reversible:	true)

cx0_2		= Path.new(
  eid:		'loc0-loc2',
  game:		g,
  owned_by:	g,
  name:		'loc0-loc2',
  desc:		<<-EOT,
A narrow, cramped tunnel, with rough walls and floor, leads west.
  EOT
  shortdesc:	'cramped tunnel.',
  origin:	loc0,
  destination:	loc2,
  via:		[
    'w',
  ],
  reversible:	true)

cx1_0		= Path.new(
  eid:		'loc1-loc0',
  game:		g,
  owned_by:	g,
  name:		'loc1-loc0',
  desc:		<<-EOT,
A rough doorway-sized opening to the west
appears to open up after a few metres.
  EOT
  shortdesc:	'door-sized opening.',
  origin:	loc1,
  destination:	loc0,
  via:		[
    'w',
  ],
  reversible:	true)

cx2_0		= Path.new(
  eid:		'loc2-loc0',
  game:		g,
  owned_by:	g,
  name:		'loc2-loc0',
  desc:		'A narrow crack leads east.',
  shortdesc:	'narrow crack.',
  origin:	loc2,
  destination:	loc0,
  via:		[
    'e',
  ],
  reversible:	true)

cx1_2		= Path.new(
  eid:		'loc1-loc2',
  game:		g,
  owned_by:	g,
  name:		'loc1-loc2',
  desc:		<<-EOT,
A low rocky tunnel slopes downward to the southeast, leading to
Location 2.
  EOT
  shortdesc:	'low rocky tunnel.',
  origin:	loc1,
  destination:	loc2,
  via:		[
    'se',
  ],
  reversible:	true)

cx2_1		= Path.new(
  eid:		'loc2-loc1',
  game:		g,
  owned_by:	g,
  name:		'loc2-loc1',
  desc:		<<-EOT,
A low rocky tunnel slopes upward to the northwest, leading to
Location 1.
  EOT
  shortdesc:	'low rocky tunnel.',
  origin:	loc2,
  destination:	loc1,
  via:		[
    'nw',
  ],
  reversible:	true)

cx2_3		= Path.new(
  eid:		'loc2-loc3',
  game:		g,
  owned_by:	g,
  name:		'loc2-loc3',
  desc:		<<-EOT,
Close examination reveals a dark, secret passage hidden behind a
boulder.  It appears to lead steeply down into the darkness to an
unknown destination.
  EOT
  shortdesc:	'dark secret passage.',
  is_visible:	false,
  origin:	loc2,
  destination:	loc3,
  via:		[
    'down',
  ],
  reversible:	false)

g.start		= loc0
loc0.add_path(cx0_0, cx0_1, cx0_2)
loc1.add_path(cx1_0, cx1_2)
loc2.add_path(cx2_0, cx2_1, cx2_3)

player		= Player.new(
  eid:		'Player-1',
  name:		'Solo',
  game:		g,
  owned_by:	g,
  whereami:	loc0,
  locations:	{
    loc0 	=> 1,
  })

loc0.look
loc1.look
=begin
is = g.inventory.subordinate_inventories
=end
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
