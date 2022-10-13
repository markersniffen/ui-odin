package main	

import tracy "../../odin-tracy"

import "/ui"

main :: proc() {
	using ui
	tracy.SetThreadName("main")
	state = new(State)

	if init()
	{
		for !state.quit
		{
			defer tracy.FrameMark()
			update()
		}
	}

	quit()
}
