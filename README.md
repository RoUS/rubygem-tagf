#  SPTAF - Single-Player Text Adventure Framework

## Usage

```ruby

require('sptaf')
include SPTAF
game = Game.new(eid: 'mytextgame',
                name: 'The Secrect Caverns of the Shoggoths',
                shortdesc: 'My first game',
                author: 'John Q Doe <johnqdoe@example.com>')
game.load(file: 'mytextgame.yaml')
game.start
```

## [Things Specific to Actors](id:actor-features)

### [Attributes](id:actor-attributes)

[**`attitude`**](id:attribute-attitude) [rw] (*Symbol*)

: TBS

[**`breadcrumbs`**](id:attribute-breadcrumbs) [rw] (*Array*)

: TBS

[**`faction`**](id:attribute-faction) [rw] ([*Faction*](#class-faction))

: TBS

[**`hp`**](id:attribute-hp) [rw] (*Float*)

: TBS
  (*See the section on [Hitpoints](#option-hitpoints)*)

[**`maxhp`**](id:attribute-maxhp) [rw] (*Integer*)

: TBS
  (*See the section on [Hitpoints](#option-hitpoints)*)

## [Things Specific to Containers](id:container-features)

### [Attributes](id:container-attributes)

[**`allow_containers`**](id:attribute-allow_containers) [rw] ([*Boolean*](#type-flag))

: TBS

[**`capacity_items`**](id:attribute-capacity_items) [rw] (*Integer*)

: TBS
  (*See the section on [Item, Weight, and Volume Limits](#option-capacities)*)

[**`capacity_mass`**](id:attribute-capacity_mass) [rw] (*Float*)

: TBS
  (*See the section on [Item, Weight, and Volume Limits](#option-capacities)*)

[**`capacity_volume`**](id:attribute-capacity_volume) [rw] (*Float*)

: TBS
  (*See the section on [Item, Weight, and Volume Limits](#option-capacities)*)

[**`current_items`**](id:attribute-current_items) [rw] (*Integer*)

: TBS
  (*See the section on [Item, Weight, and Volume Limits](#option-capacities)*)

[**`current_mass`**](id:attribute-current_mass) [rw] (*Float*)

: TBS
  (*See the section on [Item, Weight, and Volume Limits](#option-capacities)*)

[**`current_volume`**](id:attribute-current_volume) [rw] (*Float*)

: TBS
  (*See the section on [Item, Weight, and Volume Limits](#option-capacities)*)

[**`is_open`**](id:attribute-is_open) [rw] ([*Boolean*](#type-flag))

: TBS
  (*See [`is_openable`](#attribute-is_openable),
        [`is_surface`](#attribute-is_surface)*)

[**`is_openable`**](id:attribute-is_openable) [rw] ([*Boolean*](#type-flag))

: TBS
  (*See [`is_open`](#attribute-is_open),
        [`is_surface`](#attribute-is_surface)*)

[**`is_surface`**](id:attribute-is_surface) [rw] ([*Boolean*](#type-flag))

: TBS
  (*See [`is_open`](#attribute-is_open),
        [`is_openable`](#attribute-is_openable)*)

[**`is_transparent`**](id:attribute-is_transparent) [rw] ([*Boolean*](#type-flag))

: TBS

## [Things Specific to Locations](id:location-features)

### [Attributes](id:location-attributes)

[**`light_level`**](id:attribute-light_level) [rw] (*Float*)
  (*See the section on [Lighting](#option-lighting)*)

: TBS

[**`paths`**](id:attribute-paths) [rw] (*Hash*)

: TBS

## [Things Relating to Events](id:event-features)

### [Attributes](id:event-attributes)

[**`event_queue`**](id:attribute-event_queue) [r] (*Array*)

: TBS

[**`events_heard`**](id:attribute-events_heard) [rw] (*Set*)

: TBS

## [Things Common to All Classes](id:common-features)

### [Attributes](id:common-attributes)

[**`article`**](id:attribute-article) [rw] (*String*)

: TBS

[**`desc`**](id:attribute-desc) [rw] (*String*)

: TBS
  (*See [`shortdesc`](#attribute-shortdesc)*)

[**`eid`**](id:attribute-eid) [ro] (*String*)

: The game-wide unique element identifier for the object.

[**`game`**](id:attribute-game) [rw] ([*Game*](#class-game))

: The game object that ultimately owns all the other objects. Each
  object has this attribute, which is how they can find each other.

[**`illumination`**](id:attribute-illumination) [rw] (*Integer*)

: TBS
  (*See the section on [Lighting](#option-lighting)*)

[**`is_static`**](id:attribute-is_static) [rw] ([*Boolean*](#type-flag))

: TBS

[**`is_visible`**](id:attribute-is_visible) [rw] ([*Boolean*](#type-flag))

: TBS

[**`mass`**](id:attribute-mass) [rw] (*Float*)

: TBS

[**`name`**](id:attribute-name) [rw] (*String*)

: TBS

[**`owned_by`**](id:attribute-owned_by) [rw] ([*Element*](#class-element))

: TBS

[**`only_dim_near_player`**](id:attribute-only_dim_near_player) [rw] ([*Boolean*](#type-flag))

: TBS
  (*See the section on [Lighting](#option-lighting)*)

[**`pct_dim_per_turn`**](id:attribute-pct_dim_per_turn) [rw] (*Float*)

: TBS
  (*See the section on [Lighting](#option-lighting)*)

[**`preposition`**](id:attribute-preposition) [rw] (*String*)

: TBS

[**`shortdesc`**](id:attribute-shortdesc) [rw] (*String*)

: TBS
  (*See [`desc`](#attribute-desc)*)

[**`volume`**](id:attribute-volume) [rw] (*Float*)

: TBS

### [Methods](id:common-methods)

## [Events](id:feature-events)

## [Game Options](id:game-options)

The `game_options` method.

* `EnableHitpoints`
* `EnforceCapacities`
* `EnforceLighting`
* `EnforceItemCounts`
* `EnforceMass`
* `EnforceVolume`
* `RaiseOnInvalidValues`

### [Hitpoints](id:option-hitpoints)

### [Lighting](id:option-lighting)

### [Item, Weight, and Volume Limits](id:option-capacities)

#### [Item Limits](id:option-itemlimits)

#### [Weight Limits](id:option-masslimits)

#### [Volume Limits](id:option-volumelimits)

### [Validation and Paranoia Mode](id:option-valuechecking)

## The Game Object

[**`is_container?`**](id:method-is_container)

: Returns `true` if the object has mixed in the `Mixin::Container`
  module, and can therefore have an [inventory](#class-inventory) and
  'own' other objects.

## [Game Elements](id:game-elements)

Description goes here.

### [Class: Element](id:class-element)

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

## [Relationships Between Elements](id:element-relationships)

Description goes here.

## [Contributing to sptaf](id:contributing)

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

`SPTAF` is copyright (c) 2022 by Ken Coar, and is made available
under the terms of the Apache Licence 2.0. See the
[LICENCE file](./file.LICENCE.html) for further details.

<!-- Local Variables: -->
<!-- mode: markdown -->
<!-- eval: (if (intern-soft "fci-mode") (fci-mode 1)) -->
<!-- End: -->
