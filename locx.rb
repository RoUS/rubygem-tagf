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

gmanual		= Game.new(
  eid:		'gameloctest01',
  name:		'LocTest01',
  author:	'theRoUS',
  copyright_year: '2019-2024',
  licence:	'Apache 2.0',
  desc:		'Test 01 of game location connexions.')

kw_up		= Keyword.new(
  eid:		'kw-up',
  game:		gmanual,
  owned_by:	gmanual,
  root:		'up',
  alii:		[
    'upward',
  ],
  flags:	[
    :motion,
  ])

kw_down		= Keyword.new(
  eid:		'kw-down',
  game:		gmanual,
  owned_by:	gmanual,
  root:		'down',
  alii:		[
    'downward',
  ],
  flags:	[
    :motion,
  ])

kw_e		= Keyword.new(
  eid:		'kw-east',
  game:		gmanual,
  owned_by:	gmanual,
  root:		'east',
  alii:		[
    'e',
  ],
  flags:	[
    :motion,
    :facing,
  ])

kw_w		= Keyword.new(
  eid:		'kw-west',
  game:		gmanual,
  owned_by:	gmanual,
  root:		'west',
  alii:		[
    'w',
  ],
  flags:	[
    :motion,
    :facing,
  ])

kw_se		= Keyword.new(
  eid:		'kw-southeast',
  game:		gmanual,
  owned_by:	gmanual,
  root:		'southeast',
  alii:		[
    'se',
  ],
  flags:	[
    :motion,
    :facing,
  ])

kw_nw		= Keyword.new(
  eid:		'kw-northwest',
  game:		gmanual,
  owned_by:	gmanual,
  root:		'northwest',
  alii:		[
    'nw',
  ],
  flags:	[
    :motion,
    :facing,
  ])

kw_back		= Keyword.new(
  eid:		'kw-back',
  game:		gmanual,
  owned_by:	gmanual,
  root:		'back',
  alii:		[
    'return',
    'retreat',
  ],
  flags:	[
    :motion,
  ])

kw_rfid		= Keyword.new(
  eid:		'kw-RFID',
  game:		gmanual,
  owned_by:	gmanual,
  root:		'RFID',
  alii:		nil,
  name:		'RFID plot item',
  desc:		("A small metal-and-plastic doodad " +
  		 "of apparently no consequence, but " +
  		 "somehow giving an impression of importance."),
  flags:	[
    :item,
    :key,
  ])

faction0	= Faction.new(
  eid:		'dwarves',
  name:		'dwarves',
  desc:		'The troupe of threatening little dwarves, always hostile.',
  shortdesc:	'Threatening little dwarves.',
  game:		gmanual,
  owned_by:	gmanual,
  attitude:	:hostile)

loc0		= Location.new(
  eid:		'Loc0',
  game:		gmanual,
  owned_by:	gmanual,
  name:		'Location 0 - Entrance',
  shortdesc:	'entrance room.',
  desc:		("You're in Location 0, the starting location " +
  		 "for players in new games."))

loc1		= Location.new(
  eid:		'Loc1',
  game:		gmanual,
  owned_by:	gmanual,
  name:		'Location 1',
  desc:		("Room 1, one of the locations accessible from the entrance."),
  shortdesc:	'Room 1.')

loc2		= Location.new(
  eid:		'Loc2',
  game:		gmanual,
  owned_by:	gmanual,
  name:		'Location 2',
  desc:		'The ending (?) location, #2',
  shortdesc:	'Room 2.')

loc3		= Location.new(
  eid:		'Loc3',
  game:		gmanual,
  owned_by:	gmanual,
  name:		'Location 3 (secret room)',
  desc:		'The Secret Room!',
  visible:	false,
  shortdesc:	"It's a secret!")

loc4		= Location.new(
  eid:		'Loc4',
  game:		gmanual,
  owned_by:	gmanual,
  name:		'Location 4 (oubliette)',
  desc:		'There is no way out.',
  shortdesc:	"You're doomed for all time.",
  visible:	false)

loc5		= Location.new(
  eid:		'Loc5',
  game:		gmanual,
  owned_by:	gmanual,
  name:		'Location 5 (the Lost Room)',
  desc:		('There is no way out.  ' +
                 'But then, there is no way in, either.'),
  shortdesc:	"You couldn't get heah from theah.",
  visible:	false)

container1	= Container.new(
  eid:		'birdcage',
  game:		gmanual,
  owned_by:	loc1,
  name:		'birdcage',
  article:	'a',
  desc:		'rather battered little brass birdcage')

item1		= Item.new(
  eid:		'bird',
  game:		gmanual,
  owned_by:	container1,
  is_living:	true,
  article:	'a',
  desc:		'little songbird')

cx0_0		= Path.new(
  eid:		'loc0-loc0',
  game:		gmanual,
  owned_by:	gmanual,
  name:		'Loc0 ceiling grate',
  origin:	loc0,
  destination:	loc0,
  desc:		("A small hole up on the wall would let you crawl " +
  		 "upwards.  There is a steel grate across the opening."),
  shortdesc:	'upward-leading crawl.',
  tooltip:	'Ceiling grate',
  via:		[
    'up',
  ],
  reversible:	true,
  mixins:	[
    'Sealable',
  ],
  sealable:	true,
  openable:	true,
  opened:	false,
  lockable:	true,
  locked:	true,
  seal_key:	'RFID',
  must_possess:	true,
  desc_open:	("The grate in the ceiling is open.  " +
  		 "You can probably crawl upward through it."),
  shortdesc_open: ("You could probably crawl upward through " +
                   "the grate in the ceiling."),
  desc_closed:	"The ceiling grate is closed.",
  shortdesc_closed: nil)

cx0_1		= Path.new(
  eid:		'loc0-loc1',
  game:		gmanual,
  owned_by:	gmanual,
  name:		'loc0-loc1',
  desc:		"To the east is a stone door.",
  shortdesc:	'broad smooth passage.',
  tooltip:	'Stone door',
  origin:	loc0,
  destination:	loc1,
  via:		[
    'east',
  ],
  reversible:	true,
  mixins:	[
    'Sealable',
  ],
  sealable:	true,
  openable:	true,
  opened:	false,
  autoclose:	true,
  lockable:	false,
  locked:	false,
  desc_open:	("The stone door is open, and through it you can " +
                 "see a broad passage, with a flat, smooth floor " +
                 "and smooth walls."),
  shortdesc_open: "The stone door to the east is open.",
  desc_closed:	"The stone door is currently closed.",
  shortdesc_closed: 'The stone door is currently closed.')

cx0_2		= Path.new(
  eid:		'loc0-loc2',
  game:		gmanual,
  owned_by:	gmanual,
  name:		'loc0-loc2',
  desc:		("A narrow, cramped tunnel, with rough walls " +
                 "and floor, leads west."),
  shortdesc:	'narrow cramped tunnel.',
  tooltip:	'Narrow cramped tunnel',
  origin:	loc0,
  destination:	loc2,
  via:		[
    'west',
  ],
  reversible:	true)

cx1_0		= Path.new(
  eid:		'loc1-loc0',
  game:		gmanual,
  owned_by:	gmanual,
  name:		'loc1-loc0',
  desc:		("A rough doorway-sized opening to the west " +
                 "appears to open up after a few metres."),
  shortdesc:	'door-sized opening.',
  tooltip:	'Door-sized opening',
  origin:	loc1,
  destination:	loc0,
  via:		[
    'west',
  ],
  reversible:	true)

cx1_2		= Path.new(
  eid:		'loc1-loc2',
  game:		gmanual,
  owned_by:	gmanual,
  name:		'loc1-loc2',
  desc:		("A low rocky tunnel slopes downward to the " +
                 "southeast, leading to Location 2."),
  shortdesc:	'low rocky tunnel.',
  tooltip:	'Low rocky tunnel',
  origin:	loc1,
  destination:	loc2,
  via:		[
    'southeast',
  ],
  reversible:	true)

cx1_4		= Path.new(
  eid:		'loc1-loc4',
  game:		gmanual,
  owned_by:	gmanual,
  name:		'loc1-loc4',
  desc:		("A dark pit lies at your feet, " +
  		 "radiating menace and exuding a miasma of " +
  		 "hopelessness.  It probably leads somewhere " +
  		 "you don't want to go."),
  shortdesc:	'dark pit.',
  tooltip:	'Dark pit',
  origin:	loc1,
  destination:	loc4,
  via:		[
    'down',
  ],
  reversible:	false)

cx2_0		= Path.new(
  eid:		'loc2-loc0',
  game:		gmanual,
  owned_by:	gmanual,
  name:		'loc2-loc0',
  desc:		'A narrow crack leads east.',
  shortdesc:	'narrow crack.',
  tooltip:	'Narrow crack',
  origin:	loc2,
  destination:	loc0,
  via:		[
    'east',
  ],
  reversible:	true)

cx2_1		= Path.new(
  eid:		'loc2-loc1',
  game:		gmanual,
  owned_by:	gmanual,
  name:		'loc2-loc1',
  desc:		("A low rocky tunnel slopes upward to the " +
                 "northwest, leading to Location 1."),
  shortdesc:	'low rocky tunnel.',
  tooltip:	'Low rocky tunnel',
  origin:	loc2,
  destination:	loc1,
  via:		[
    'northwest',
  ],
  reversible:	true)

cx2_3		= Path.new(
  eid:		'loc2-loc3',
  game:		gmanual,
  owned_by:	gmanual,
  name:		'loc2-loc3',
  desc:		("Close examination reveals a dark, secret passage " +
  		 "hidden behind a boulder.  It appears to lead " +
  		 "steeply down into the darkness to an " +
                 "unknown destination."),
  shortdesc:	'dark secret passage.',
  tooltip:	'Dark secret passage',
  visible:	false,
  origin:	loc2,
  destination:	loc3,
  via:		[
    'down',
  ],
  reversible:	false)

gmanual.start		= loc0
loc0.add_path(cx0_0, cx0_1, cx0_2)
loc1.add_path(cx1_0, cx1_2, cx1_4)
loc2.add_path(cx2_0, cx2_1, cx2_3)

#debugger
player		= Player.new(
  eid:		'Player-1',
  name:		'Solo',
  game:		gmanual,
  owned_by:	gmanual,
  whereami:	loc0,
  locations:	{
    loc0 	=> 1,
  })

File.open('locx-exported.yaml', 'w') do |f|
  f.puts('%YAML 1.2')
  f.puts(gmanual.export_game.to_yaml)
  f.puts("# Local Variables:\n" +
         "# mode: yaml\n" +
         "# eval: (if (intern-soft \"fci-mode\") (fci-mode 1))\n" +
         "# eval: (auto-fill-mode 1)\n" +
         "# End:")
end

puts('Ta-daaah!')

# Local Variables:
# mode: ruby
# indent-tabs-mode: nil
# eval: (if (intern-soft "fci-mode") (fci-mode 1))
# eval: (auto-fill-mode 1)
# End:
