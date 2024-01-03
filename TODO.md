# TODO items (unordered) for TAGF Ruby gem

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
* ~~Fix all references to `sptaf` and `TAF` to `tagf` and `TAGF`
  respectively.~~
* Abstract out all methods in the top `TAGF` module to a separate
  `TAGF::Base` module; `TAGF` should be namespace only.
* Sort out `included` and `extended` module class methods so that
  including any of the mixins will properly include all the ancestors
  and set up the class methods for the invoking entity.
* See about replacing monkey patch of `String` with a refining module.
* Investigate inheritance of modules brought in with `using` method.
* Add visibility/opacity to `Location` (for fog/darkness effects,
  *&c.*).
* Add Thor (?) generators for building (rooms, items, connexions, and
  so on), verifying the locations as a graph to make sure everything
  is reachable — and escapeable.
  * Enhance command-line tools to be able to use `here-docs` for
    things like descriptions (started in `ui.rb`).
* Add functionality for doors.
* Add functionality for locks (doors, chests, padlocks) and
  keys/tokens to lock/unlock them.
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

## Testing

* Finish converting ADVENT flat datafile to YAML.
* Build test adventure based on ADVENT.
  * Describe fully in YAML
  * Write tests for running through Colossal Cave


<!-- Local Variables: -->
<!-- mode: markdown -->
<!-- page-delimiter: "^[[:space:]]*<!-- \\(--\\|\\+\\+\\)" -->
<!-- eval: (if (intern-soft "fci-mode") (fci-mode 1)) -->
<!-- eval: (auto-fill-mode 1) -->
<!-- End: -->
