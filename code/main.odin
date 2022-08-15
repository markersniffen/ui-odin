package main	

import "/ui"

main :: proc() {
	using ui

	state = new(State)

	if init()
	{
		for !state.quit
		{
			update()
			ui_update()
			ui_render()
		}
	}
}
