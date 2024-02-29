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
require('tagf/mixin/dtypes')
require('tagf/mixin/graphable')
require('tagf/mixin/universal')
require('byebug')

# @!macro doc.TAGF.module
module TAGF

  #
  class Path

    #
    include(Mixin::UniversalMethods)
    include(Mixin::DTypes)
    include(Mixin::Element)
    include(Mixin::Graphable)

    # @!macro TAGF.constant.Loadable_Fields
    Loadable_Fields		= [
      'origin',
      'destination',
      'tooltip',
      'via',
      'reversible',
      'sealable',
      'seal_key',
      'must_possess',
    ]

    # @!macro TAGF.constant.Abstracted_Fields
    Abstracted_Fields		= {
      origin:			EID,
      destination:		EID,
    }

    # @!attribute [rw] reversible
    # Whether the player can 'back up' after following the path.  (If
    # the destination is at the bottom of a cliff, it's probably not
    # reversible.)
    #
    # @return [Boolean]
    #   whether or not the path can be followed in reverse.
    flag(:reversible)

    # @!attribute [rw] origin
    # @see #destination
    # @see #via
    #
    # @return [TAGF::Location]
    #   The Location at which the path originates.
    attr_accessor(:origin)

    # @!attribute [rw] destination
    # @see #origin
    # @see #via
    #
    # @return [TAGF::Location]
    #   The Location at which the path terminates.
    attr_accessor(:destination)

    # @!attribute [rw] via
    # @see #origin
    # @see #destination
    #
    # @return [Array<String>]
    #   The direction keywords (such as `"se"`) that leave the origin
    #   and follow the path to the destination.
    attr_reader(:via)
    def via=(val)
      if (! val.kind_of?(Array))
        val		= [ *val ]
      end
      @via		= val
    end                         # def via=(val)

    # @!attribute [rw] graph_edge
    # Edge object in the game graph for this path element.
    #
    # @return [GraphViz::Edge]
    attr_accessor(:graph_edge)

    # @!attribute [rw] graph_index
    # The index number assigned to this path's edge in the game graph.
    #
    # @return [Integer]
    attr_accessor(:graph_index)

    # @!attribute [rw] must_possess
    # If this Path is sealable, and there is a :seal_key assigned,
    # this flag indicates whether the key must be in the actor's
    # possession in order to open (or close) the seal and transit the
    # path.
    #
    # @return [Boolean]
    flag(:must_possess)

    # @!method add_to_graph(graphobj)
    # This method will be invoked for every Location instance in the
    # game.  It has the responsibility of adding the Location as a
    # vertex in the graph, and setting the rendering attributes as
    # appropriate (see Graph_Attributes)..
    #
    # @return [void]
    def add_to_graph
      graph		= self.game.graphinfo.graph
      #
      # If we're already registered, don't do it again.
      #
      if (edge = self.graph_component.nil?)
        graph.add_edge(self.origin, self.destination)
        edge		= graph.edges.find { |e|
          (e.source == self.origin) &&
          (e.target == self.destination)
        }
        self.graph_component = edge
      end
      #
      # However, our attributes may have changed (such as visibility)
      # and therefore how we should be rendered.  Set the rendering
      # bits (or reset them) according to the current settings.
      #
      gattr		= Graph_Attributes
      attr		= {
        label:		self.label,
        tooltip:	self.desc,
      }.merge(gattr.edge.default)
      if (! self.visible?)
        attr		= attr.merge(gattr.edge.invisible)
      end
      graph.set_edge_options(edge.source, edge.target, **attr)
      return nil
    end                       # def add_to_graph

    # @!method export
    # `Location`-specific export method, responsible for adding any
    # unusual fields that need to be abstracted to the export hash.
    # That is, things that can't be simply boiled down to a string
    # EID.
    #
    # @return [Hash<String=>Any>]
    #   the updated export hash.
    def export
      result			= super
      vias			= [] | self.via.map { |kw|
        self.game.keyword(kw, required: true).root
      }
      result['via']		= vias
      return result
    end                         # def export

    # @!method conflicts(*args, **kwargs)
    #
    def conflicts(*args, **kwargs)
      result		= []
      args.each do |other|
        #
        # We don't conflict with ourself, so skip us.
        #
        next if (other == self)
        other_via	= [ *other.via ]
        unless ((self.via & other_via).empty?)
          result.push(other)
        end
      end
      result		= nil if (result.empty?)
      return result
    end                         # def conflicts

    # @!method initialize(*args, **kwargs)
    def initialize(*args, **kwargs)
      TAGF::Mixin::Debugging.invocation
      self.visible!
      self.initialize_element(*args, **kwargs)
    end                         # def initialize(*args, **kwargs)

    nil
  end                           # class Path

  nil
end                             # module TAGF

# Local Variables:
# mode: ruby
# indent-tabs-mode: nil
# eval: (if (intern-soft "fci-mode") (fci-mode 1))
# eval: (auto-fill-mode 1)
# End:
