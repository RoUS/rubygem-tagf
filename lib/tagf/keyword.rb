#--
# Copyright © 2022 Ken Coar
#
# Licensed under the Apache License, Version 2.0 (the "License"); you
# may not use this file except in compliance with the License.  You
# may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or
# implied.  See the License for the specific language governing
# permissions and limitations under the License.
#++
# frozen_string_literal: true

require('tagf/debugging')
warn(__FILE__) if (TAGF.debugging?(:file))
require('tagf/mixin/container')
require('tagf/mixin/element')
require('tagf/mixin/dtypes')
require('byebug')

# @!macro doc.TAGF.module
module TAGF

  #
  class Keyword

    #
    include(Mixin::DTypes)
    include(Mixin::UniversalMethods)
    include(Mixin::Element)

    # @!macro TAGF.constant.Loadable_Fields
    Loadable_Fields	= {
      'root'		=> FieldDef.new(
        name:		'root',
        datatype:	String,
        description:	'Root word to which alii are translated'
      ),
      'alii'		=> FieldDef.new(
        name:		'alii',
        datatype:	Array[String],
        description:	'Alias for the root keyword'
      ),
      'flags'		=> FieldDef.new(
        name:		'flags',
        datatype:	Array[Symbol],
        description:	'Flags (motion, shortcut, ...)'
      ),
    }

    # @!method check_keyword(word)
    # Ensure that the `word` argument obeys our simple syntax
    # requirements.
    #
    # @raise [ArgumentError]
    #   on failure of syntax check:
    #   <tt>"keywords must be single-word strings; bad value
    #   "<em>class</em>:<em>inspectM</em>"</tt> 
    # @return [Boolean]
    #   `true` if the keyword string passes the syntax check
    def self.check_keyword(word)
      if (word.kind_of?(String) \
          && word.match(%r!^\S+$!))
        return true
      end
      raise_exception(ArgumentError,
                      format('keywords must be single-word ' \
                             + 'strings; bad value "%s:%s"',
                             word.class.to_s,
                             word.inspect))
    end                         # def self.check_keyword

    # @!attribute [r] root
    # The actual keyword at the heart of the object.  Keywords are
    # strings and may contain no whitespace.  Generally speaking
    # they're also lowercase and considered case-sensitive.
    #
    # @return [String]
    #   the actual keyword string.
    attr_reader(:root)

    # @!attribute [rw] alii
    # A list of alternate versions of the keyword, such as `"s"` being
    # an another word for `"south"`.  Alias values <em>can</em> be
    # used in game definitions, but that's discouraged; their primary
    # <em>raison d'être</em> is to allow the player to use them in
    # commands.
    #
    # @return [Array<String>]
    #   a list of all the recognised alias values for the keyword.
    attr_accessor(:alii)

    # @!attribute [rw] flags
    #
    # `:motion`
    # :  Keyword identifies some sort of motion for the player, such
    #    as `"east"` being an instruction to attempt to move the
    #    player according to any Path with the `"east"` keyword in its
    #    Path#via field.
    # `:facing`
    # :  Keyword can be an instruction to change the direction in
    #    which the player is facing.  (Meaningful for games in which
    #    directions can be relative, such as `"left"` or `"right"`.)
    # `:location`
    # :  Keyword is a reference to a location and can be used to
    #    'teleport' to it if it's nearby (for unknown values of
    #    nearby).  <em>Incompatible with `:item`, `:key`, and
    #    `:consumable`.</em>
    # `:item`
    # :  Keyword is a reference to an item, such as a game treasure.
    # `:key`
    # :  Keyword is a reference to a special item that affects
    #    gameplay if it's in the player's possession under the
    #    appropriate circumstances.  An example would be a key to a
    #    locked door.
    # `:consumable`
    # :  Indicates that the key item is perishable, and each use
    #    reduces the number left.  (See #uses.)  <em>Only meanigful
    #    if `:key` is also set.</em>
    #
    # @return [Set<Symbol>]
    attr_accessor(:flags)

    # @!method includes?(word)
    def includes?(word)
      our_words		= [ self.root, *self.alii ].uniq
      result		= our_words.include?(word)
      return result
    end                         # def includes?(word)

    # @!method initialize(*args, **kwargs)
    # Constructor for keyword elements
    # @!macro doc.TAGF.formal.kwargs
    # @return [Feature] self
    #
    def initialize(*args, **kwargs)
      TAGF::Mixin::Debugging.invocation
      @root		= args[0] || kwargs[:root]
      [ @root, *kwargs[:alii] ].compact.each do |word|
        Keyword.check_keyword(word)
      end
      #
      # Pre-set some default values for this keyword.
      #
      eid		= format('kw-%s', @root)
      self.alii		= Set.new
      self.flags	= Set.new
      self.initialize_element(*args,
                              **kwargs,
                              eid: eid)
      self.static!
      self.visible	= false

    end                         # def initialize(*args, **kwargs)

  end                           # class Feature

  nil
end                             # module TAGF

# Local Variables:
# mode: ruby
# indent-tabs-mode: nil
# eval: (if (intern-soft "fci-mode") (fci-mode 1))
# eval: (auto-fill-mode 1)
# End:
