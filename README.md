### Imgui-style ui library atop a sokol base layer for Odin.

Suggested use: None. \
Very unstable and very much a work in progress. Use at your own risk!

#### Requirements:
- Requires sokol-odin in the same folder as this repo: https://github.com/floooh/sokol-odin  
- The build-run.bat file uses floooh's shader tool if you want to regenerate the shader: https://github.com/floooh/sokol-tools  
- Uses odin-tracy to profile unless you comment out the includes: https://github.com/oskarnp/odin-tracy

### TODOs:

#### Major changes:
- [x] store all font glyphs in 1 font texture
- [-] redo memory pools/arena - make growable (use odin's arena?)
- [-] figure out a better way to make unique keys for boxes - level/index system? (now requires unique string input for every widget)
- [ ] better string system (not fixed length? use Odin's strings? Use a string arena?)
- [ ] rewrite input system to use callbacks?
- [ ] redo scrollbar - make a scrollbar value per box?
- [ ] have boxes adjust size dynamically if too big to fit on screen? (finish layout algorithm)
- [ ] rebuild the layer rendering system...I don't really know what I'm doing
- [ ] render while resizing window
- [ ] redo panel system - just use boxes?

#### Things to add:
- [-] drawing a custom image to a box
- [ ] copy/paste values
- [ ] load defaults from file
- [ ] "x_end()" functions for widgets that have weird conditional pop(n)'s?

#### Things to fix:
- [x] scrolling on floating panel also scrolls panels beneath
- [x] force floating panels to stay in bounds on creation
- [ ] hovering bleeds through layers (does clicking do this too?)
- [ ] text width for labels and other general widgets with text

#### Widgets:
- [x] empty
- [x] color
- [x] label
- [x] value
- [x] edit_value
- [x] edit_text
- [x] paragraph
- [x] slider
- [x] button
- [x] menu
- [x] menu_button
- [x] dropdown
- [x] radio
- [x] tab
- [x] spacer_fill
- [x] spacer_pixels
- [x] scrollbox
- [x] sizebar_x
- [x] sizebar_y
- [x] drag_panel
- [x] image
- [ ] color picker
- [ ] checkbox