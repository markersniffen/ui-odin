package sniffui	

import "/snui"
import "vendor:glfw"
import "core:fmt"

WIDTH  	:: 1280
HEIGHT 	:: 720
TITLE 	:: "Sniff UI"

main :: proc() {
	using snui

	if !bool(glfw.Init())
	{
		fmt.eprintln("GLFW has failed to load.")
		return
	}

	window := glfw.CreateWindow(WIDTH, HEIGHT, TITLE, nil, nil)
	defer glfw.Terminate()
	defer glfw.DestroyWindow(window)

	if window == nil
	{
		fmt.eprintln("GLFW has failed to load the window.")
		return
	}

	state = new(State)
	defer free(state)
	glfw.MakeContextCurrent(window)
	glfw.SetKeyCallback(window, cast(glfw.KeyProc)keyboard_callback)
	glfw.SetMouseButtonCallback(window, cast(glfw.MouseButtonProc)mouse_callback)
	glfw.SetScrollCallback(window, cast(glfw.ScrollProc)scroll_callback)
	glfw.SetCharCallback(window, cast(glfw.CharProc)typing_callback)
	
	glfw.SetWindowUserPointer(window, state)
	state.window = window

	opengl_init()

	for !glfw.WindowShouldClose(window)
	{
		glfw.PollEvents()

		width, height := glfw.GetWindowSize(window)
		state.window_size = {width, height}
		
		mouseX, mouseY := glfw.GetCursorPos(window)
		old_mouse := state.mouse.pos
		state.mouse.pos = {i32(mouseX), i32(mouseY)}
		state.mouse.delta = state.mouse.pos - old_mouse

		update()
		render()
	}
}

read_key :: proc(Key: ^bool) -> bool
{
	if Key^ {
		Key^ = false
		return true
	} else {
		return false
	}
}

process_keyboard_input :: proc(action: int, key_state: ^bool, repeat: bool)
{
	if action == int(glfw.RELEASE)
	{
		key_state^ = false
	} else {
		if repeat {
			if action == int(glfw.PRESS) || action == int(glfw.REPEAT)
			{
				key_state^ = true
			}
		} else {
			if action == int(glfw.PRESS)
			{
				key_state^ = true
			}
		}
	}
}

keyboard_callback :: proc(Window: glfw.WindowHandle, key: int, scancode: int, action: int, mods: int)
{
	using snui, fmt
	
	switch key
	{
		case glfw.KEY_LEFT:
		process_keyboard_input(action, &state.keys.left, true)
		case glfw.KEY_RIGHT:
		process_keyboard_input(action, &state.keys.right, true)
		case glfw.KEY_UP:
		process_keyboard_input(action, &state.keys.up, true)
		case glfw.KEY_DOWN:
		process_keyboard_input(action, &state.keys.down, true)
		
		case glfw.KEY_ESCAPE:
		process_keyboard_input(action, &state.keys.escape, true)
		case glfw.KEY_TAB:
		process_keyboard_input(action, &state.keys.tab, false)
		case glfw.KEY_ENTER:
		process_keyboard_input(action, &state.keys.enter, true)
		case glfw.KEY_SPACE:
		process_keyboard_input(action, &state.keys.space, true)
		case glfw.KEY_BACKSPACE:
		process_keyboard_input(action, &state.keys.backspace, true)
		case glfw.KEY_DELETE:
		process_keyboard_input(action, &state.keys.delete, true)
		
		case glfw.KEY_KP_ENTER:
		process_keyboard_input(action, &state.keys.enter, true)
		case glfw.KEY_KP_SUBTRACT:
		process_keyboard_input(action, &state.keys.n_minus, false)
		case glfw.KEY_KP_ADD:
		process_keyboard_input(action, &state.keys.n_plus, false)
		
		case glfw.KEY_LEFT_ALT:
		process_keyboard_input(action, &state.keys.alt, false)
		case glfw.KEY_RIGHT_ALT:
		process_keyboard_input(action, &state.keys.alt, false)
		
		case glfw.KEY_LEFT_CONTROL:
		process_keyboard_input(action, &state.keys.ctrl, false)
		case glfw.KEY_RIGHT_CONTROL:
		process_keyboard_input(action, &state.keys.ctrl, false)
		
		case glfw.KEY_LEFT_SHIFT:
		process_keyboard_input(action, &state.keys.shift, false)
		case glfw.KEY_RIGHT_SHIFT:
		process_keyboard_input(action, &state.keys.shift, false)
	}
}

typing_callback :: proc(window: glfw.WindowHandle, codepoint: u32)
{
	using snui
	fmt.println(rune(codepoint))
	// State.UILastChar = rune(codepoint);
}

scroll_callback :: proc(window: glfw.WindowHandle, x: f64, y: f64)
{
	using snui
	state.mouse.scroll = f32(y/10)
}

mouse_callback :: proc(window: glfw.WindowHandle, button: int, action: int, mods: int)
{
	using snui
	if button == int(glfw.MOUSE_BUTTON_LEFT)
	{
		if action == int(glfw.PRESS) do state.mouse.left = .CLICK
		if action == int(glfw.RELEASE) do state.mouse.left = .UP
	}
	
	if button == int(glfw.MOUSE_BUTTON_MIDDLE)
	{
		if action == int(glfw.PRESS) do state.mouse.middle = .CLICK
		if action == int(glfw.RELEASE) do state.mouse.middle = .UP
	}
	
	if button == int(glfw.MOUSE_BUTTON_RIGHT)
	{
		if action == int(glfw.PRESS) do state.mouse.right = .CLICK
		if action == int(glfw.RELEASE) do state.mouse.right = .UP
	}
}
