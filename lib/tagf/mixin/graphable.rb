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
require('byebug')

# @!macro doc.TAGF.module
module TAGF

  # @!macro doc.TAGF.Mixin.module
  module Mixin

    # Module providing attributes and methods for something that can
    # (and probably will) be opened included in the digraph.
    # Basically, Location and Path elements.  but, just in case..
    module Graphable

      include(Mixin::DTypes)
      include(Mixin::UniversalMethods)

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

      attr_accessor(:graph_component)

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
