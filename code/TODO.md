// TODO //

[ ] features to change?
 - creating and deleting panels on the fly currently uses a queue
 - render pipeline / calc pipeline
 - clipping boxes?
 - box state:
   - active, editing, hot


[X] fix blinking panel on add (used queue for creating new panels after startup)
[X] add mouse cursor changes
[X] fix clipping
[X] fix scroll bar drag movement
[X] comment widgets
[X] editable text
  [X] adding space at begining or with no text crashes (?)
  [X] select any and backspace() calculates len wrong
[X] large viewable text
   [ ] switch to word wrap vs \n wrap
   [ ] large editable text
[X] font weights
[ ] different colored text
[X] ctrl click editable text for values (e.g. buttons)
[O] context menu
  [ ] hover over other menu buttons?
[ ] checkbox
[X] dropdown
[X] tabs
[X] clean up colors
[X] scrolling
[X] proper box clipping
[ ] avoid making boxes that are cropped?
[ ] render while resizing window
[ ] copy/paste values
[ ] load defaults from file
[X] set up as library and make an app with it
[ ] have boxes adjust size dynamically if too big to fit on screen?