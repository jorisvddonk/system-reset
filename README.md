# System Reset

This project attempts to authentically recreate [Noctis IV](https://en.wikipedia.org/wiki/Noctis_(video_game)) in Godot. It uses [a Godot GDextension](https://github.com/jorisvddonk/feltyrion-godot), which itself is based off of [a modern sourceport of Noctis IV](https://github.com/dgcole/noctis-iv-lr), for most of its underlying universe generation code.

This project is currently in Beta, and the code can be a bit messy as a result. Many of Noctis IV's features have been implemented, but they may differ slightly; for example, planet generation isn't fully compatible with Noctis IV just yet; some planets - like Felysian worlds - don't have all of their sectors represented accurately.

## Developing System Reset

The currently supported Godot version is **4.3**.

### Compiling dependencies

This project depends on https://github.com/jorisvddonk/feltyrion-godot, which is not included by default, and needs to be compiled for your operating system in order for the project to function correctly. Follow the following steps to compile all of the dependencies:

1. Clone the https://github.com/jorisvddonk/feltyrion-godot git repository somewhere.
2. Follow feltyrion-godot's compiling instructions to compile the GDExtension for your operating system.
3. Find `feltyrion-godot.gdextension` in the built output and copy it plus all sibling folders to `addons/feltyrion-godot`, such that the file `addons/feltyrion-godot/feltyrion-godot.gdextension` exists.
4. Done! You should now be able to load this project in Godot and try it out from there!

There is no strict version compatibility - both forwards nor backwards - defined between the two projects. So if you're not on the main branch of System Reset or checking out a previous commit, make sure you compile the commit from feltyrion-godot that was most recent at that time.

### Optional script-ide

If you aren't fond of Godot's default script editor, you can install [script-ide](https://github.com/Maran23/script-ide) via AssetLib. Note that you do NOT need to enable it globally, as the 'system reset dev plugin' loads it dynamically for you. If script-ide has enabled itself, make sure to disable it in Project Settings.