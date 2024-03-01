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
require('tagf/mixin/universal')
require('tagf/exceptions')
require('tagf/mixin/element')
require('forwardable')
require('ostruct')
require('rgl/adjacency')
require('rgl/dijkstra')
require('byebug')

# @!macro doc.TAGF.module
module TAGF

  # @!macro doc.TAGF.Mixin.module
  module Mixin

    # Module providing attributes and methods for something that can
    # (and probably will) be opened included in the digraph.
    # Basically, Location and Path elements.  But, just in case..
    module Graphable

      include(Mixin::DTypes)
      include(Mixin::UniversalMethods)

      # Class encapsulating all 'global' aspects of the
      # <em>per</em>-game digraph.  Each game has an instance.
      class GraphInfo
        
        include(RGL)

        # @!attribute [r] graph
        #
        # @return [RGL::DirectedAdjacencyGraph]
        attr_reader(:graph)

        # @!attribute [r] game
        # The game object within which is embedded all the graph
        # information.  Read-only and set by the constructor.
        #
        # @return [TAGF::Game]
        #   the game instance from which the graph information will be
        #   extracted.
        attr_reader(:game)

        # @!attribute [r] weighthash
        # A mapping of edges to their weights (Float values), used to
        # determine the cost of routes from one vertex to another and
        # the 'shortest' path from those.  Each key is a two-element
        # array composed of the `origin` and `destination` (or
        # `source` and `target`, in RGL terms) vertices; the
        # corresponding value is a floating-point number indicating
        # the weight.
        #
        # By default (see #initialize), this begins as an empty hash
        # object with a default value of `0.0`, so <em>all</em>
        # lookups will return that value.  Edges (paths) that should
        # actually be more expensive to traverse can explicitly add an
        # entry to this hash to override the `0.0` default.
        #
        # The #weighthash object is used to build the map stored in
        # the #weightmap attribute (<em>q.v.</em>).
        #
        # @return [Hash<Array<(Location,Location)>=>Float>]
        attr_reader(:weighthash)

        # @!attribute [r] weightmap
        # Readonly attribute, set by the constructor, holding the
        # RGL-specific data structure for determining the weight of
        # edges in the game digraph.
        #
        # @return [RGL::EdgePropertiesMap]
        #   see the documentation for RGL::EdgePropertiesMap
        attr_reader(:weightmap)

        # @!attribute [r] scout
        # Instance of the Dijkstra path-finding algorithm class from
        # the RGL gem.  The attribute's value is set by the
        # constructor.  Uses #weightmap and #graph (which must
        # therefore have been set up before the instance is created)
        # to walk the graph and determine edge (path) costs.  Methods
        # of this object return the lowest-cost routes between
        # locations (vertices).
        #
        # @return [RGL::DijkstraAlgorithm]
        #   the RGL path-finding object we use to find the shortest
        #   route from one location to another.
        attr_reader(:scout)

        # @!method assemble
        # Intended to be invoked after all game objects have been
        # instantiated and completed, this method tells each Location
        # (vertex) and Path (edge) object to add itself to the game
        # graph.
        #
        # If the graph has already been assembled, this is a no-op.
        #
        # Once this method has been invoked, the graph is ready for
        # use, whether for route analysis during gameplay, or
        # standalone rendering into a graphic image, or any other
        # reason.
        #
        # @return [void]
        def assemble
          return nil if (@assembled)
          self.game.filter(klass: TAGF::Location).each do |loc|
            loc.add_to_graph
          end
          self.game.filter(klass: TAGF::Path).each do |path|
            path.add_to_graph
          end
          @assembled	= true
          return nil
        end                     # def assemble

        # @!method initialize(game)
        # Create ans set up an instance of the GraphInfo class, which
        # contains all the bits necessary to treat the game as a
        # directed graph of locations and paths between them.  The
        # digraph can be used for something as prosaic as rendering
        # a graphic 'map' of the game, or for finding routes between
        # locations, but may also end up being useful in as-yet
        # unforeseen ways.
        #
        # @param [TAGF::Game] game
        #   The game instance which this graph is intended to
        #   describe.
        #
        # @return [void]
        def initialize(game)
          @assembled	= false
          @game		= game
          @graph	= RGL::DirectedAdjacencyGraph.new
          #
          # Since all of our edge weights are essentially zero, create
          # a hash with that as the default value.  Paths which might
          # have a different weight (such as those involving doors or
          # other obstacles) can, of course, change this on a
          # <em>per</em>-case basis.
          #
          @weighthash	= {}
          @weighthash.default = 0.0
          @weightmap	= RGL::EdgePropertiesMap.new(@weighthash,
                                                     true)
          #
          # Something used by RGL to help traverse the graph when
          # finding shortest paths between locations.
          #
          @visitor	= RGL::DijkstraVisitor.new(@graph)
          #
          # And the actual hunter/seeker for path walking.
          #
          @scout	= RGL::DijkstraAlgorithm.new(@graph,
                                                     @weightmap,
                                                     @visitor)
          return nil
        end                     # def initialize

        nil
      end                       # class GraphInfo

      # @!macro TAGF.constant.Loadable_Fields
      Loadable_Fields		= [
        'tooltip',
      ]

      #
      # Default visual attributes to apply to graph components,
      # according to their various attributes.  <em>E.g.</em>,
      # components that are marked as invisible are rendered
      # differently from those which are visible.
      #
      Graph_Attributes		= OpenStruct.new(
        vertex:			OpenStruct.new(
          #
          # By default, vertices will look like this.
          #
          default:		{
            color:		'black',
            shape:		'rectangle',
            style:		'filled',
            fillcolor:		'silver',
          },
          #
          # If a location is invisible, modify its appearance as follows.
          #
          invisible:		{
            shape:		'ellipse',
            fillcolor:		'red',
          },
          #
          # The starting location has its own special look.
          #
          start:		{
            shape:		'parallelogram',
            fillcolor:		'lime',
          }),
        edge:			OpenStruct.new(
          #
          # Normal path depiction.
          #
          default:		{
            color:		'slategrey',
            style:		'solid',
            arrowhead:		'normal',
          },
          #
          # If it's invisible, its looks are modified as follows.
          #
          invisible:		{
            color:		'red',
            style:		'dashed',
          },
          #
          # And if it can only be traversed one direction, mark it so.
          #
          irreversible:		{
            arrowhead:		'normalnormal',
            arrowtail:		'tee',
          })
      )

      attr_accessor(:tooltip)

      # @!attribute [rw] graph_component
      # When the game has been fully instantiated, the Game#graph
      # digraph is populated with all of the game's TAGF::Location and
      # TAGF::Path elements.  The #graph_component will be set to the
      # appropriate graph object.
      #
      # Vertices in RGL don't have wrappers; instead, they're
      # registered in an internal data structure.  As a consequence,
      # Location elements' #graph_component will reference the
      # Location object itself.
      #
      # Edges in RGL, on the other hand, <em>do</em> have their own
      # RGL objects.  Therefore, the #graph_component attribute for
      # Path objects will reference an actual RGL::Edge object of some
      # sort.
      #
      # @return [TAGF::Location]
      #   if the receiver is a TAGF::Location object, that object
      #   itself is returned.
      # @return [RGL::Edge]
      #   if the receiver is a TAGF::Path object, the corresponding
      #   RGL::Edge object is returned.
      attr_accessor(:graph_component)

      # @!method add_to_graph(graphobj)
      # @abstract
      # Graphable classes need to override this methos.
      #
      # This method will be invoked for each instance of every
      # Graphable class in the game.  It is this method's
      # responsibility to add the instance to the graph, including any
      # rendering attributes (see Graph_Attributes).
      #
      # @return [void]
      def add_to_graph(graphobj)
        raise_exception(RuntimeError,
                        format('Graphable classes ' \
                               + 'must override method #%s',
                               __callee__.to_s))
        return nil
      end                       # def add_to_graph

      # @!method label(rcvr=nil)
      # Provide a default stringify method for all game elements.
      # (Or, actually, any kind of object, though non-game objects
      # will be unimaginatively labeled.)
      # Unless this method is overridden, the return value will
      # include the result from the element's #to_key method; if the
      # #name attribute is a String, then that will be appended.
      #
      # @param [Any] rcvr		self
      #   Optional object for which a label should be generated.  By
      # default, it's `self`.
      # @return [String]
      def label(rcvr=nil)
        rcvr		||= self
        result		= rcvr.to_s
        catch(:labeled) do
          if (! (rcvr.respond_to?(:name) \
                 && rcvr.respond_to?(:to_key)))
            throw(:labeled)
          end
          if (rcvr.name.kind_of?(String))
            result	= format('%s - %s',
                                 rcvr.to_key,
                                 rcvr.name.to_s)
          else
            result	= rcvr.to_key
          end
        end                     # catch(:labeled)
        return result
      end                       # def label(rcvr=nil)

      # @!method initialize_graphable(*args, **kwargs)
      # When something mixes in this module, this method should be
      # invoked to preset any attributes it provides.
      #
      # @param [Array]			args
      #   Ignored.
      # @param [Hash<Symbol=>Any>]	kwargs
      #   Hash of keyword arguments.  Any mixin-specific settings will
      #   be passed through this.
      # @option kwargs [String]		:tooltip
      #   Optional string to be added as the `:tooltip` attribute of
      #   the #graph_component reference.
      #
      # @return [void]
      def initialize_graphable(*args, **kwargs)
        @tooltip	= kwargs[:tooltip]
        @graph_component = nil
      end                       # def initialize_graphable

      nil
    end                         # module Graphable

    nil
  end                           # module TAGF::Mixin

  nil
end                             # module TAGF

# Local Variables:
# mode: ruby
# indent-tabs-mode: nil
# eval: (if (intern-soft "fci-mode") (fci-mode 1))
# eval: (auto-fill-mode 1)
# End:
