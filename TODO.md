# TODO list for TAGF project

## Coding/concepts to investigate

* Rationalise `ClassMethods`, `PackageClassMethods`, and
  `UniversalMethods` — particularly with regard to the game options.
* Finish designing YAML definition structure and language.
* Figure out & fix the (`Class`,`Universal`)`Methods`
  inclusion/extension stuff.
* Allow saving game serialised as YAML, via `#Marshal` (possibly
  compressed), encrypted.
* Importing and exporting should do the smallest granularity first, so
  that the game already has things like contents declared when
  defining containers.  Or not.  Maybe just build all elements and then
  connect them afterward?
* Allow for `#debugging?` to take a list of symbols; figure out
  whether they should be ANDed or ORed by default.
  * Done (using AND by default), but there are **two** `#debugging?`
    methods in `mixin/debugging.rb`!
* Work on ability to load a game from YAML.
  * Pass the YAML results through a syntax checker.  (Something for
    the 'Thor' tool mentioned later.)
  * Perhaps _per_-class `import` class method to take a parsed element
    definition and create a new instance from it?  Deeply tied to the
    YAML syntax at first blush.
* Move detailed documentation out of `README` and into a separate
  file.
* Sort out `included` and `extended` module class methods so that
  including any of the mixins will properly include all the ancestors
  and set up the class methods for the invoking entity.
* See about replacing monkey patch of `String` with a refining module.
* Investigate inheritance of modules brought in with `using` method.
* Add ability to have 'cloned' items (like torches) that can be
  treated the same without having to manually create each one.  Maybe
  a `tag` or `category` field?  And a `#create_{item-or-element}`
  method to instantiate new elements in the category?
* Add visibility/opacity to `Location` (for fog/darkness effects,
  *&c.*).
* Add functionality for doors.
  - *See class Path with module Mixin::Sealable*
* Add functionality for locks (doors, chests, padlocks) and
  keys/tokens to lock/unlock them.
  - *See class Path with module Mixin::Sealable*
* Levels as an alternative (or in addition) to meandering cave-like
  structures.
* Add concept of traps?
  * Perception-like checks for detection.
  * [Re]settable by PCs, DM, auto-reset, *&c.*
* Scriptable monster/NPC actions and reactions (think ADVENT's snake
  with and without the bird).
  * Work on how to add scripting to [YAML?] definition file.
  * Figure out how to manage flag re/setting for stepping through
    complex patterns, such as solving a combination lock.
* Ability to short-circuit logic paths that become unavailable (again,
  think of what happens in ADVENT if you prematurely kill the bird).
* Consumables (such as torches, ADVENT's lantern batteries, *&c.*).
* Figure out how to chain together `Location`s to provide for seamless
  hallways, stairs, and other labyrinthinic structures.
* Build `describe` method that can do as deep a dive as requested for
  nested `Container`s with inventories.
* Event processing: think about objects registering 'event listeners'.
* Dynamic changing of edge weight for sealed paths that are unopenable
  or sealed with locks; high weight unless the player possesses the
  key to the seal, in which case it gets dropped.
* Figure out a way to limit Portable items so that they can only be
  obtained if the player has the right container.  Think: ADVENT bird
  and birdcage.
* Add more attitudes, such as 'afraid' for the ADVENT bird's reaction
  to the rod, or why the ADVENT dwarves actively follow the player
  rather than just attacking him when co-located.
* Enhance Faction with Opinion/Regard/Reputation/Respect
* Add a way to control path usage according to actor inventory.  One
  aspect is *via* a seal like a locked door, but think ADVENT's "you
  won't get it up the steps!" restriction on the gold nugget.
* Add `wander` as a direction to allow the player to go in a random
  direction.
* Don't give new-location descriptions, and disable `look` and
  friends, if the current/new location's #light_level <= zero.
  Combined with `wander`, this can get delightfully confusing for the
  player.
* Add light-aversion (and a maximum tolerable light-level) as a
  characteristic of NPCs; think light-averse but player-seeking
  wandering monsters like "grues."  If the lights go out, the grues
  can actually reach the player.  Nom, nom.
  - TAGF::NPC#light_tolerance added, but behaviour needs to be
    designed and implemented.

### Completed coding/concept items

* ~~Fix all references to `sptaf` and `TAF` to `tagf` and `TAGF`
  respectively.~~
* ~~Abstract out all methods in the top `TAGF` module to a separate
  `TAGF::Base` module; `TAGF` should be namespace only.~~
* ~~Add `Mixin::Container` and `Mixin::Portable` to YAML element
  fields.~~
  - *Handled with YAML key `mixins: []`*
* ~~Change YAML `sealable` to be an array element of `mixins`?~~
  - *Done; see previous item.  Mixins LightSource, Portable,
    Graphable, and Sealable, for starters.&*
* ~~Re-integrate `Mixin::Location` (*et alia*?) to `Location` if that's
  the only actual element that reference it.~~

## Tools

* Build a visual graph from `Location` paths (`Connexions`)
  - *Prototyped with `render.rb`, and digraph now built into the code
    itself (primarily for purposes of finding shortest paths).*
* Add Thor (?) generators for building (rooms, items, connexions, and
  so on), verifying the locations as a graph to make sure everything
  is reachable — and escapeable.
  * Enhance command-line tools to be able to use `here-docs` for
    things like descriptions (started in `ui.rb`).
* Validate `YAML` file by loading it and then checking:
  1. `Location` paths that are marked `reversible: true` actually have
     a `Connexion` back from the `:destination` to the `:origin`.
  1. `Connexion` objects' `:via` field match their key in
     `.owned_by.paths[]`.
  1. Everything with an `:owned_by` field should be listed in the
     `owned_by.inventory` structure.
  1. All `:seal_key` values in Keyword definitions themselves are
     registered as keywords.
  1. Anything listed as a `:seal_key` needs to be registered as a
     `Portable` `Item` or else the seal can't be opened.  This should
     be a warning.
  1. Keywords and alii must be unique; only one can define "e", for
     instance.

### Complete tool items

## Testing

* Continue writing unit tests for underlying support attributes and
  methods.
* Write tests for individual objects (`Item`, `Location`, *&c.*
* Finish converting ADVENT flat datafile to YAML.
* Build test adventure based on ADVENT.
  * Describe fully in YAML
  * Write tests for running through Colossal Cave

### Completed testing items

<!-- Local Variables: -->
<!-- mode: markdown -->
<!-- page-delimiter: "^[[:space:]]*<!-- \\(--\\|\\+\\+\\)" -->
<!-- eval: (if (intern-soft "fci-mode") (fci-mode 1)) -->
<!-- eval: (auto-fill-mode 1) -->
<!-- End: -->
