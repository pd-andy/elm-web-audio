module WebAudio exposing
    ( Node, Type, Key, Graph
    , node, ref, key, param
    , oscillator, osc, gain, audioDestination, dac, audioBufferSource, delay
    , channelMerger, channelSplitter, constantSource
    , biquadFilter, convolver, dynamicsCompressor, iirFilter, panner, stereoPanner, waveShaper
    , encode, encodeGraph
    )

{-|
# Types
@docs Node, Type, Key, Graph

# Basic Constructors
@docs node, ref, key, param

# Web Audio Nodes
## Common audio nodes
@docs oscillator, osc, gain, audioDestination, dac, audioBufferSource, delay

## Utility nodes
@docs channelMerger, channelSplitter, constantSource

## Signal processing nodes
@docs biquadFilter, convolver, dynamicsCompressor, iirFilter, panner, stereoPanner, waveShaper

# JSON Encoding
To turn the json in Web Audio nodes, you need to know what that data looks like.
Here's a breakdown of how everything is encoded:

**Node:**

```json
{
    "type": "OscillatorNode",
    "properties": [
        ...
    ],
    "connections": [
        ...
    ]
}
```

**Keyed:**

```json
{
    "key": "myOsc",
    "type": "OscillatorNode",
    "properties": [
        ...
    ],
    "connections": [
        ...
    ]
}
```

**Ref:**

```json
{
    "key": "myOsc",
    "type": "RefNode"
}
```

Properties can come in two types, AudioParam and NodeProperty. While the Web 
Audio API doesn't make an official distinction between the two, how they are 
used differs.

AudioParams represent parameters that can be updated at either audio rate 
(a-rate) or control rate (k-rate). Other audio nodes can connect to an 
AudioParam and modulate its value in real time. Examples of AudioParams include 
frequency, gain, and delayTime.

**AudioParam:**

```json
{
    "type": "AudioParam",
    "label": "frequency",
    "value": 440
}
```

NodeProperties are any other parameter on an audio node. An example of a 
NodeProperty is an OscillatorNode's "type" parameter.

**NodeProperty:**

```json
{
   "type": "NodeProperty",
   "label": "type",
   "value": "square"
}
```

@docs encode, encodeGraph

-}

-- Imports ---------------------------------------------------------------------
import Json.Decode as Decode
import Json.Encode as Encode exposing (encode)
import WebAudio.Property as Property exposing (..)

-- Types -----------------------------------------------------------------------
{-| The core building block of any Web Audio signal graph. `Keyed` nodes are 
just like regular nodes but with an additonal `Key` property. This allows `Ref` 
nodes to reference them elsewhere in the graph!
-}
type Node
    = Node Type (List Property) (List Node)
    | Keyed Key Type (List Property) (List Node)
    | Ref Key


{-| A simple type alias representing the type of `Node`. This could be 
something like "OscillatorNode" or "RefNode".
-}
type alias Type =
    String


{-| A simple type alias representing unique key used to identify nodes. Use 
`Key`s like you would use the `id` attribute on a HTML element.
-}
type alias Key =
    String


{-| -}
type alias Graph =
    List Node


-- Node constructors -----------------------------------------------------------
{-| General way to construct Web Audio nodes. This is used to create all the 
helper functions below. You can use this function to define custom nodes by 
partially applying just the `type` parameter. This is handy if you're using a 
library like Tone.js and want to use those nodes in Elm.

    omniOscillator : List Property -> List Node -> Node
    omniOscillator =
        node "Tone-OmniOscillatorNode"

    myOsc =
        omniOscillator
            [ Property.freq 440 ]
            [ dac ]

-}
node : Type -> List Property -> List Node -> Node
node =
    Node


{-| A ref node is used to refer to a keyed node elsewhere in the graph. This is 
how we connect multiple "chains" of nodes together and represet a graph in a 
simple list.
-}
ref : Key -> Node
ref =
    Ref


{-| Use this function to apply a key to a node. In the case of already keyed 
nodes, or ref nodes, this will update the key to the new value.

    a = osc [ Property.freq 440 ] [ dac ]
    b = key "b" <| gain [ Property.gain 0.5 ] [ dac ]
    c = ref "b"

    key "myOsc" a -- Give a the key "myOsc"
    key "myGain" b -- Rename b's key to "myGain"
    key "myOsc" c -- c is now a RefNode to "myOsc"

-}
key : Key -> Node -> Node
key k n =
    case n of
        Node t ps cs ->
            Keyed k t ps cs

        Keyed _ t ps cs ->
            Keyed k t ps cs

        Ref _ ->
            Ref k

{-| Audio nodes can connect to AudioParams to modulate their value. Use this
function for that. The first argument is the key of an existing keyedd node and
the second argument is the name of the AudioParam to connect to.

This is commonly used for frequency modulation (FM) and amplitude modulation
(AM) synthesis.

    a = osc [ frequency 10 ] [ param "carrier" "frequency" ]
    b = key "carrier" <| osc [] [ dac ]

Under the hood, this actually just creates a standard ref node! You could create
this function yourself:

    param key name = ref (key ++ "." name)
    
-}
param : Key -> String -> Node
param k p =
  ref (k ++ "." ++ p)

-- Audio nodes -----------------------------------------------------------------
{-| See: <https://developer.mozilla.org/en-US/docs/Web/API/AudioBufferSourceNode>
Common properties:

  - buffer
  - detune
  - loop
  - loopStart
  - loopEnd
  - playbackRate

-}
audioBufferSource : List Property -> List Node -> Node
audioBufferSource =
    Node "AudioBufferSourceNode"


{-| See: <https://developer.mozilla.org/en-US/docs/Web/API/AudioDestinationNode>
-}
audioDestination : Node
audioDestination =
    Node "AudioDestinationNode" [] []


{-| See: <https://developer.mozilla.org/en-US/docs/Web/API/BiquadFilterNode>
Common properties:

  - frequency
  - detune
  - Q
  - type

-}
biquadFilter : List Property -> List Node -> Node
biquadFilter =
    Node "BiquadFilterNode"


{-| See: <https://developer.mozilla.org/en-US/docs/Web/API/ChannelMergerNode>
-}
channelMerger : List Property -> List Node -> Node
channelMerger =
    Node "ChannelMergerNode"


{-| See: <https://developer.mozilla.org/en-US/docs/Web/API/ChanneSplliterNode>
-}
channelSplitter : List Property -> List Node -> Node
channelSplitter =
    Node "ChannelSplitterNode"


{-| See: <https://developer.mozilla.org/en-US/docs/Web/API/ConstantSourceNode>
Common properties:

  - offset

-}
constantSource : List Property -> List Node -> Node
constantSource =
    Node "ConstantSource"


{-| See: <https://developer.mozilla.org/en-US/docs/Web/API/ConvolverNode>
Common properties:

  - buffer
  - normalize | normalise

-}
convolver : List Property -> List Node -> Node
convolver =
    Node "ConvolverNode"


{-| An alias for `audioDestination`.
-}
dac : Node
dac =
    audioDestination


{-| See: <https://developer.mozilla.org/en-US/docs/Web/API/DelayNode>
Common properties:

  - delayTime

-}
delay : List Property -> List Node -> Node
delay =
    Node "DelayNode"


{-| See: <https://developer.mozilla.org/en-US/docs/Web/API/DynamicsCompressorNode>
Common properties:

  - threshold
  - knee
  - ratio
  - reduction
  - attack
  - release

-}
dynamicsCompressor : List Property -> List Node -> Node
dynamicsCompressor =
    Node "DynamicsCompressorNode"


{-| See: <https://developer.mozilla.org/en-US/docs/Web/API/GainNode>
Common properties:

  - gain

-}
gain : List Property -> List Node -> Node
gain =
    Node "GainNode"


{-| See: <https://developer.mozilla.org/en-US/docs/Web/API/>
-}
iirFilter : List Property -> List Node -> Node
iirFilter =
    Node "IIRFilterNode"


{-| See: <https://developer.mozilla.org/en-US/docs/Web/API/OscillatorNode>
Common properties:

  - frequency
  - detune
  - type

-}
oscillator : List Property -> List Node -> Node
oscillator =
    Node "OscillatorNode"


{-| An alias for `oscillator`.
-}
osc : List Property -> List Node -> Node
osc =
    oscillator


{-| See: <https://developer.mozilla.org/en-US/docs/Web/API/PannerNode>
Common properties:

  - coneInnerAngle
  - coneOuterAngle
  - coneOuterGain
  - distanceModel
  - maxDistance
  - orientationX
  - orientationY
  - orientationZ
  - panningModel
  - positionX
  - positionY
  - positionZ
  - refDistance
  - rolloffFactor

-}
panner : List Property -> List Node -> Node
panner =
    Node "PannerNode"


{-| See: <https://developer.mozilla.org/en-US/docs/Web/API/StereoPannerNode>
Common properties:

  - pan

-}
stereoPanner : List Property -> List Node -> Node
stereoPanner =
    Node "StereoPannerNode"


{-| See: <https://developer.mozilla.org/en-US/docs/Web/API/WaveShaperNode>
Common properties:

  - curve
  - oversample

-}
waveShaper : List Property -> List Node -> Node
waveShaper =
    Node "WaveShaperNode"


-- JSON encoding ---------------------------------------------------------------
{-| Converts a `Node` into a Json value. Use this to send a node through a port 
to javascipt, where it can be constructed into a Web Audio node!
-}
encode : Node -> Encode.Value
encode n =
    case n of
        Node t ps cs ->
            Encode.object
                [ ( "type", Encode.string t )
                , ( "properties", Encode.list Property.encode ps )
                , ( "connections", Encode.list encode cs )
                ]

        Keyed k t ps cs ->
            Encode.object
                [ ( "key", Encode.string k )
                , ( "type", Encode.string t )
                , ( "properties", Encode.list Property.encode ps )
                , ( "connections", Encode.list encode cs )
                ]

        Ref k ->
            Encode.object
                [ ( "key", Encode.string k )
                , ( "type", Encode.string "RefNode" )
                ]


{-| Encode a graph of nodes into a Json value. More than likely you'll use this 
more than `encode`
-}
encodeGraph : Graph -> Encode.Value
encodeGraph =
    Encode.list encode
