#  SPTAF - Single-Player Text Adventure Framework

## Usage

```ruby

require('sptaf')
include SPTAF
game = Game.new(slug: 'mytextgame',
                name: 'The Secrect Caverns of the Shoggoths',
                shortdesc: 'My first game',
                author: 'John Q Doe <johnqdoe@example.com>')
game.load(file: 'mytextgame.yaml')
game.start
```

## The Game Object

**`slug`**

: The game-wide unique identifier for the object.

**`game`**

: The game object that ultimately owns all the other objects. Each
  object has this attribute, which is how they can find each other.

[**`is_container?`**](id:attribute-is_container)

: Returns `true` if the object has mixed in the `Mixin::Container`
  module, and can therefore have an [inventory](#class-inventory) and
  'own' other objects.

## [Game Elements](id:game-elements)

Description goes here.

### [Class: Thing](id:class-thing)

Description goes here.

### [Class: Container](id:class-container)

Description goes here.

### [Class: Inventory](id:class-inventory)

Description goes here.  See the [Inventories](#inventories) section
for details.

### [Class: Location](id:class-location)

Description goes here.

### [Class: Feature](id:class-feature)

Description goes here.

### [Class: Item](id:class-item)

Description goes here.

### [Class: NPC](id:class-npc)

Description goes here.

### [Class: Player](id:class-player)

Description goes here.

### [Class: Faction](id:class-faction)

Description goes here.

## [Inventories](id:inventories)

Description goes here.

## Relationships Between Objects

Description goes here.

## Contributing to sptaf

* Check out the latest master to make sure the feature hasn't been
  implemented or the bug hasn't been fixed yet
* Check out the issue tracker to make sure someone already hasn't
  requested it and/or contributed it
* Fork the project
* Start a feature/bugfix branch
* Commit and push until you are happy with your contribution
* Make sure to add tests for it. This is important so I don't break it
  in a future version unintentionally.
* Please try not to mess with the Rakefile, version, or history. If
  you want to have your own version, or is otherwise necessary, that
  is fine, but please isolate to its own commit so I can cherry-pick
  around it.

## Copyright

`SPTAF` is copyright (c) 2022 by Ken Coar, and is made available
under the terms of the Apache Licence 2.0. See the
[LICENCE file](./file.LICENCE.html) for further details.

<!-- Local Variables: -->
<!-- mode: markdown -->
<!-- eval: (if (intern-soft "fci-mode") (fci-mode 1)) -->
<!-- End: -->
