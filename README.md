Imgui-style ui library atop a sokol base layer.

Suggested use: None.
Very unstable and very much a work in progress. Use at your own risk!

Requires sokol-odin in the same folder as this repo: https://github.com/floooh/sokol-odin
The build-run.bat file uses floooh's shader tool: https://github.com/floooh/sokol-tools

## TODOs:

#### Major Features:

[ ] rebuild the layer rendering system...I don't really know what I'm doing
[ ] rewrite input system to use callbacks?
[ ] figure out a better way to make unique keys for boxes - level/index system?
[ ] redo panel system - just use boxes?
[ ] render while resizing window
[ ] have boxes adjust size dynamically if too big to fit on screen?
[ ] better string system
[ ] redo memory pools/arena - make growable
[ ] store all font glyphs in 1 font texture

#### Minor Featuers:
[ ] checkbox
[ ] copy/paste values
[?] load defaults from file

#### Things to Fix:
[ ] scrolling on floating panel also scrolls panels beneath
[ ] hovering bleeds through layers (does clicking do this too?)

## Example:


