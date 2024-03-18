# System Reset

This project attempts to authentically recreate [Noctis IV](https://en.wikipedia.org/wiki/Noctis_(video_game)) in Godot. It uses [a Godot GDextension](https://github.com/jorisvddonk/feltyrion-godot), which itself is based off of [a modern sourceport of Noctis IV](https://github.com/dgcole/noctis-iv-lr), for most of its underlying universe generation code.

This project is, at this stage, very alpha, and the code can be a bit messy as a result. That said, the main concepts have now been proven and development is underway to address remaining issues and implement missing features.

The currently supported Godot version is **4.2**.

## Compiling dependencies

This project depends on https://github.com/jorisvddonk/feltyrion-godot, which is not included by default, and needs to be compiled for your operating system in order for the project to function correctly. Follow the following steps to compile all of the dependencies:

1. Clone the https://github.com/jorisvddonk/feltyrion-godot git repository somewhere.
2. Follow feltyrion-godot's compiling instructions to compile the GDExtension for your operating system.
3. Find `feltyrion-godot.gdextension` in the built output and copy it plus all sibling folders to `addons/feltyrion-godot`, such that the file `addons/feltyrion-godot/feltyrion-godot.gdextension` exists.
4. Done! You should now be able to load this project in Godot and try it out from there!
