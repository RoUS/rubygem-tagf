#  TAGF (Text Adventure Game Framework) Architecture

This document describes the inner workings of the TAGF code: all the
different components and how they interact.

## Definition Files

### [Exportable Element Fields](id:exportable-fields)

#### ["Abstracted" Fields](id:abstracted-fields)

### [Exporting a Game](id:exporting)

## The Game Graph

### The Graph Configuration File

## [Exceptions](id:exceptions)

Exceptions defined by the TAGF package are detailed and instrumented.
Some are used internally to signal conditions (such as inventory
overflow), and others are used more conventionally to end the
application with an explanatory message.  Most of the latter apply to
logic or dependency issues, and will only be seen by game developers.

Every TAGF exception is assigned a unique numeric identifier,
accessible *via* the `#exception_id` attribute.  This attribute is
available for both the exception class and instances of it.

Every TAGF exception also has a numeric severity value, accessible
through `#severity`.  By default, when an exception is instantiated,
the instance's severity is inherited from the class' `#severity`
value.  Unlike the `#exception_id` attribute, an exception instance's
severity can be changed, either at construction by passing a
`severity:` keyword argument to the constructor, or after creation by
using the instance's `#severity=` method.

Every TAGF exception instance also has an `#errorcode` attribute,
which is a combination of its exception ID value and its severity.
The errorcode is built by left-shifting the exception ID four bits and
ORing it with the severity.

### [Exception Severities](id:severities)

Every TAGF exception class (and instance thereof) is assigned a
*severity* value (see the overview [section on
Exceptions](#exceptions).  Exception class severities are immutable,
but that of exception instances can be changed.

Exception values which are odd numbers (1, 3) indicate either total
success or something of note that isn't a problem.  Even values
indicate some sort of problem.

**Success**
: Numerical value: 1

  The application has successfully performed a task.  In some cases,
  processing continues after the message is issued, but this usually
  is an end-of-run thing.

  **N.B.:** *Should be converted to 0 if it's going to be interpreted
  in situations expecting Unixish shell/libc conventions.*

**Informational**, **Info**
: Numerical value: 3

  The application has performed a task, or is providing a status
  update on one in progress.  The message provides information about
  the process.  Generally suppressed, and only used to bring to notice
  something of interest.

**Warning**, **Warn**
: Numerical value: 4

  The application may have performed some, but not all, of a task.
  The message may suggest that you verify the result or check for
  other messages.

**Error**
: Numerical value: 6

  The output or result of a task is known to be incorrect, but it may
  be localised and the application may attempt to continue execution.

**Severe**, **Fatal**
: Numerical value: 8

  The application cannot continue.  A **severe** exception indicates
  an unrecoverable condition, such as the inability to access a file,
  or perhaps a logic error has gotten the player stuck.  Should always
  result in an abnormal termination.

## Elements, Mixins, and Tools

Components of a TAGF game, such as rooms, NPCs, items, the player
itself, and so on, are all called game *elements*.  A
[`Location`](#element-Location) is an element.  A lantern is an
element.  *Everything* is an element.  All elements include the
[*`TAGF::Mixin::Element`*](#mixin-Element) mixin.  All elements are
described later in their own section(s).

[*`TAGF::Mixin::Element`*](#mixin-Element) is only one of the mixins.
Features that might apply to disparate elements are separated out and
mixed in selectively.  For instance, anything that provides light
mixes in the [*`TAGF::Mixin::LightSource`*](#mixin-LightSource)
module; anything that might have contents includes the
[*`TAGF::Mixin::Container`*](#mixin-Container) module, and anything
which can be opened or closed (or locked) mixes in
[*`TAGF::Mixin::Sealable`*](#mixin-Sealable).  Mixins are described in
their [own section](#mixins).

Some tools are provided to help game developers, and more will
doubtless be added as the need arises.  These are described in the
[*Tools*](#tools) section.

## [Tools](id:tools)

A few tools are part of the TAGF package, and each is accessed from
the command line *via* the `tagf` command (supplied in the package as
`bin/tagf`).  These include:

[**`render`**](id:tool-render)

: Allows rendering of the game layout as a visual map in a graphic
  file.  For example,

  `% tagf render --format=png --source=advent.yaml`

  will produce a file named `advent.png` showing all the locations and
  the paths between them

[**`validate`**](id:tool-validate)

: Evaluates a game definition (`YAML`) file and identifies potential
  mapping errors or playability issues (such as unreachable rooms,
  rooms that can be entered but not exited, locked items (or doors)
  with no defined keys, *&c.*).

  `% tagf validate --source=advent.yaml`

## [Game Components (Elements)](id:elements)

### [Faction](id:element-Faction)

* Mixes in [*Element*](#mixin-Element)

### [Feature](id:element-Feature)

* Mixes in [*Container*](#mixin-Container)
* Mixes in [*Element*](#mixin-Element)

### [Game](id:element-Game)

* Mixes in [*Element*](#mixin-Element)

### [Item](id:element-Item)

* *May* mix in [*Container*](#mixin-Container)
* Mixes in [*Element*](#mixin-Element)
* Mixes in [*Portable*](#mixin-Portable)
* *May* mix in [*Sealable*](#mixin-Sealable)

### [Keyword](id:element-Keyword)

* Mixes in [*Element*](#mixin-Element)

### [Location](id:element-Location)

* Mixes in [*Container*](#mixin-Container)
* Mixes in [*Element*](#mixin-Element)
* Mixes in [*Graphable*](#mixin-Graphable)

### [NPC](id:element-NPC)

* Mixes in: [*Actor*](#mixin-Actor)
* Mixes in [*Element*](#mixin-Element)

An NPC is a 'non-player character,' and the term refers to any sort of
'character' wholly under the control of the game.

### [Path](id:element-Path)

* Mixes in [*Element*](#mixin-Element)
* Mixes in [*Graphable*](#mixin-Graphable)
* *May* mix in [*Sealable*](#mixin-Sealable)

### [Player](id:element-Player)

* Mixes in [*Actor*](#mixin-Actor)
* Mixes in [*Element*](#mixin-Element)

The `Player` element (of which there should be exactly *ONE* in a TAGF
game) is the virtual avatar of the person playing the game — the
*User*, as opposed to the *Player*.  The Player is controlled
primarily by commands entered by the User, but sometimes may be
controlled by game dynamics (such as running away randomly if
panicked).

## [Includable Features (Mixins)](id:mixins)

### [Actor](id:mixin-Actor)

* Mixes in [*Container*](#mixin-Container)

### [Container](id:mixin-Container)

* Mixes in [*Element*](#mixin-Element)

### [DTypes](id:mixin-DTypes)
### [Element](id:mixin-Element)
### [Graphable](id:mixin-Graphable)
### [LightSource](id:mixin-LightSource)
### [Portable](id:mixin-Portable)
### [Sealable](id:mixin-Sealable)
### [UniversalMethods](id:mixin-UniversalMethods)

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
