require('tagf')
require('byebug')
require('pathname')
require('test/unit')

class Test_Game < Test::Unit::TestCase

  include(TAGF::Exceptions)
  include(TAGF::Mixin::UniversalMethods)

  #
  # Executed before each test is invoked.
  #
  def setup
    @fixtures		= Dir[File.join(FixturesDir, 'game-*.yaml')]
                            .sort
    @game		= TAGF::Game.new(
      eid:		__FILE__,
      name:		Pathname(__FILE__).basename.to_s,
      author:		'T. E. Ster',
      copyright:	'Copyright © 2023-2024 by Ken Coar',
      licence:		'Apache 2.0',
      version:		'0.0.1',
      date:		'2024-01')
    begin
      super
    rescue NoMethodError
      # No-op
    end
    return nil
  end                           # def setup

  #
  # Called after each test method completes.
  #
  def teardown
    #
    # Try to trigger the garbage collector between test cases.
    #
    @game		= nil
    begin
      super
    rescue NoMethodError
      # No-op
    end
    return nil
  end                           # def teardown

  def access_file(base)
    fspec		= File.expand_path(base, FixtureDir)
    data		= YAML.load(File.read(fspec))
    return data
  end                           # def access_file

  #
  # Things to test:
  # * author
  # * copyright
  # * licence, license
  # * version
  # * date
  # * inventory (stub?)
  # * loaded (flag)
  # * loadfile
  # * savefile
  #
  # The following probably need to be in integration tests, but
  # stubbed here:
  #
  # * creation_overrides [r] private
  # * keys, actors, containers, inventories, items, locations, npcs
  # * [], each, find, map, select
  # * validate_container
  # * create_inventory_on
  # * create_item
  # * create_item_on
  # * create_container
  # * create_container_on
  # * create_feature
  # * create_feature_on
  # * create_location
  # * create_location_on
  # * inspect
  # * change_eid
  # * load
  #

  # * Test that the setup gave us a TAGF::Game object.
  def test_game_object
    assert_kind_of(TAGF::Game,
                   @game,
                   '#setup created a TAGF::Game object')
  end                           # def test_game_object

  # * Test that a new game object gets the #object_id as @eid by
  #   default.
  def test_game_default_eid
    @game		= TAGF::Game.new
    assert_equal(@game.eid,
                 @game.object_id.to_s,
                 'Game EID defaults to game object object_id')
  end                           # def test_game_default_eid

  nil
end                             # class Test_Game

# Local Variables:
# mode: ruby
# indent-tabs-mode: nil
# eval: (if (intern-soft "fci-mode") (fci-mode 1))
# eval: (auto-fill-mode 1)
# End:
