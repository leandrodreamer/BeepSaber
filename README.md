# Open Saber VR
This is a fork of [Beep Saber by NeoSpark314](https://github.com/NeoSpark314/BeepSaber) ported to Godot 4.4.1 and OpenXR (WIP)
(The OQ Toolkit is only partially ported/patched for it to work on Godot 4 with OpenXR, most features that are not used in this project will not work)

This fork tries to improve the experience and make it more of it's own game instead of just a demo.



This is a basic implementation of the beat saber game mechanic for VR using the [Godot Game Engine](https://godotengine.org/) and the [Godot Oculus Quest Toolkit](https://github.com/NeoSpark314/godot_oculus_quest_toolkit). The main objective of this project is to show how a VR game can be implemented using
the Godot game engine.

The main target platform is the Oculus Quest but it should also work with SteamVR if you add the OpenVR plugin to the addons folder in the godot project.

Originally this game was (and still is) a demo game as part of the Godot Oculus Quest Toolkit. To keep the demo implementation small
this stand alone version was forked so that it can be changed and developed independent of the original demo.

![screenshot01](doc/images/OS0.4.0_1.gif)
![screenshot02](doc/images/OS0.4.0_2.gif)
![screenshot03](doc/images/OS0.4.0_3.gif)
# About the implementation
This game uses godot 4.3. The implementation supports to load and play maps from [BeatSaver](https://beatsaver.com/).
To export for android headsets the godot openxr vendors plugin may be needed

There is one demo song included that is part of the deployed package.

You can play custom songs by downloading them in the in-game menu. 

# Credits
The included Music Track is Time Lapse by TheFatRat (https://www.youtube.com/watch?v=3fxq7kqyWO8)

# Licensing
The source code of the godot beep saber / open saber game in this repository is licensed under an MIT License.

<h1>Now About the Mods!</h1>
Currently there is an issue where if there are too many notes, there will be lots of lag.
I have made a fix for this, but I need to bring it over to this repo as its hevily out of date.
<h2>Progress</h2>
<h3>Chroma</h3>
There is full Chroma support*
The only thing you can't do, is control each light with the "_light_id" as it is used in changing environments and Open saber only has 1, but the notes change colour properly!
<h3>Mapping extensions</h3>
Mapping extensions is currently in the works as the walls are placed in a weird way I can't understand, however wall sizeing is fully working along side everything else*
the only things not implemented is archs and chains, as i've never even seen a mapping extension level in v3 anyways.

Songs used for texting: Air (67ba), Dadadada of the bumblebee (922f)

<h3>Noodle extensions</h3>
While I have code that can make it work, there is no animation support and in general is extremly buggy so It's unimplimented but I want to give it support someday!

<h3>Vivify</h3>
No.
