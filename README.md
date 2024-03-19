#  TAGF - Single-Player Text Adventure Framework

**N.B.: *This project is still in early development, and is not ready
for actual use.* **

The TAGF (Text Adventure Game Framework) gem is an attempt to provide
a structure which can be used to build text adventure games without
lots and lots of coding and special-case processing.  The approach is
to make as much as possible data-driven from `YAML` definitions, such
as describing rooms and items, linking locations together, and
handling inventories.

The initial test-case is to have a TAGF game that reproduces the
classic Colossal Cave (ADVENT) game experience as much as possible.
Other enhancements have been added as ideas have occurred, such as
less-than-perfect visibility, illuminated locations, *&c.*

Two advantages of the data-driven nature of TAGF:

1. Locations and routes between them are recognised internally as a
   digraph, which means you can *generate a graphic map* of the
   adventure.  A tool is provided to do so: `bin/tagf help render`
1. The data can be validated, doing things such as identifying
   unreachable locations, or ones that can be entered but not exited,
   or locked items that cannot be unlocked because no key has been
   defined.

## Usage

### With a Pre-Defined Game Definition File

If you already have a `YAML` file defining a game, you will be able to
play it from within Ruby with something like the following:

```ruby

require('tagf')
include(TAGF)
game = Game.load('mytextgame.yaml')
game.start
```

Alternatively, you should be able to do much the same from the command
line with something like:

```bash
% tagf run mytextgame.yaml
```

## [Contributing to tagf](id:contributing)

* Check out the latest master to make sure the feature hasn't been
  implemented or the bug hasn't been fixed yet.
* Check out the issue tracker to make sure someone already hasn't
  requested it and/or contributed it.
* Fork the project.
* Start a feature/bugfix branch.
* Commit and push until you are happy with your contribution.  **Don't
  forget to keep up to date with the master branch.**
* Make sure to add tests for it. This is important so I don't break it
  in a future version unintentionally.
* Please try not to mess with the Rakefile, version, or history.  If
  you want to have your own version, or is otherwise necessary, that
  is fine, but please isolate to its own commit so I can cherry-pick
  around it.

## [Copyright](id:copyright)

`TAGF` is copyright (c) 2022 by Ken Coar, and is made available
under the terms of the Apache Licence 2.0. See the
[LICENCE file](./file.LICENCE.html) for further details.

<!-- Local Variables: -->
<!-- mode: markdown -->
<!-- eval: (if (intern-soft "fci-mode") (fci-mode 1)) -->
<!-- eval: (auto-fill-mode 1) -->
<!-- End: -->
