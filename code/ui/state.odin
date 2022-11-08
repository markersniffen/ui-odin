package ui

PROFILER :: false

when PROFILER do import tracy "../../../odin-tracy"

import "core:time"

when ODIN_OS == .Windows { import win "core:sys/windows" }

WIDTH  	:: 1280
HEIGHT 	:: 720
TITLE 	:: "ui-odin"

Uid :: u64

v2 :: [2]f32
v3 :: [3]f32
v4 :: [4]f32

v2i :: [2]i32
v3i :: [3]i32
v4i :: [4]i32

state : ^State

State :: struct {
	debug: 		Debug,

	quit: 		bool,
	uid: 		Uid,
	window: 	Window,
	ui: 		Ui,
	render: 	Render,
	stats: 		Stats,
	input: 		Input,
}

Stats :: struct {
	start_time: time.Time,
	prev_time: time.Time,
	delta_time: f64,
	fps: f64,
}

Input :: struct {
	mouse: Mouse,
	keys: Keys,
}

Mouse :: struct {
	pos: v2,
	delta: v2,
	delta_temp: v2,
	left: Button,
	right: Button,
	middle: Button,
	scroll: v2,
}

Button :: enum { 
	UP,
	CLICK,
	RELEASE,
	DRAG,
}

Keys :: struct {
	left: bool,
	right: bool,
	up: bool,
	down: bool,

	escape: bool,
	tab: bool,
	enter: bool,
	space: bool,
	backspace: bool,
	delete: bool,
	home: bool,
	end: bool,

	n_enter: bool,
	n_plus: bool,
	n_minus: bool,

	ctrl: bool,
	alt: bool,
	shift: bool,

	a: bool,
	c: bool,
	x: bool,
	v: bool,
}

init :: proc() -> (^State, bool) {
	state = new(State)
	loaded := glfw_init()

	when ODIN_OS == .Windows do win.timeBeginPeriod(1)
	
	ui_render_init()
	ui_init()

	return state, loaded
}

update :: proc() {
	state.stats.start_time = time.now()
	state.stats.delta_time = time.duration_milliseconds(time.diff(state.stats.prev_time, state.stats.start_time))
	state.stats.fps = 1000 / state.stats.delta_time

	if state.quit do return
	
	glfw_update()

	ui_update()
	ui_render()

	// frame_goal : time.Duration = 16665000
	frame_goal : time.Duration = 8332500
	time_so_far := time.diff(state.stats.start_time, time.now())
	sleep_for:= frame_goal - time_so_far

	time.accurate_sleep(sleep_for)

	mouse_buttons: [3]^Button = { &state.input.mouse.left, &state.input.mouse.right, &state.input.mouse.middle }
	for mouse_button, index in mouse_buttons {
		if mouse_button^ == .CLICK do mouse_button^ = .DRAG
		if mouse_button^ == .RELEASE do mouse_button^ = .UP
	}
	state.input.mouse.scroll = {0,0}
	state.stats.prev_time = state.stats.start_time
}

quit :: proc() {
	glfw_quit()
	free(state)
}

read_key :: proc(key: ^bool) -> bool {
	if key^ {
		key^ = false
		return true
	} else {
		return false
	}
}

enter :: proc() -> bool { return state.input.keys.enter }
shift :: proc() -> bool { return state.input.keys.shift }
alt :: proc() -> bool { return state.input.keys.alt }
ctrl :: proc() -> bool { return state.input.keys.ctrl }

mouse_button :: proc(button: Button, type: Button) -> bool { return (button == type) }

lmb_click :: proc() -> bool { return mouse_button(state.input.mouse.left, .CLICK) }
lmb_drag :: proc() -> bool { return mouse_button(state.input.mouse.left, .DRAG) }
lmb_click_drag :: proc() -> bool { return lmb_click() || lmb_drag() }
lmb_release :: proc() -> bool { return mouse_button(state.input.mouse.left, .RELEASE) }
lmb_release_up :: proc() -> bool { return (mouse_button(state.input.mouse.left, .RELEASE) || mouse_button(state.input.mouse.left, .UP)) }
lmb_up :: proc() -> bool { return mouse_button(state.input.mouse.left, .UP) }

rmb_click :: proc() -> bool { return mouse_button(state.input.mouse.right, .CLICK) }
rmb_drag :: proc() -> bool { return mouse_button(state.input.mouse.right, .DRAG) }
rmb_click_drag :: proc() -> bool { return rmb_click() || rmb_drag() }
rmb_release :: proc() -> bool { return mouse_button(state.input.mouse.right, .RELEASE) }
rmb_release_up :: proc() -> bool { return (mouse_button(state.input.mouse.right, .RELEASE) || mouse_button(state.input.mouse.right, .UP)) }
rmb_up :: proc() -> bool { return mouse_button(state.input.mouse.right, .UP) }

mmb_click :: proc() -> bool { return mouse_button(state.input.mouse.middle, .CLICK) }
mmb_drag :: proc() -> bool { return mouse_button(state.input.mouse.middle, .DRAG) }
mmb_click_drag :: proc() -> bool { return mmb_click() || mmb_drag() }
mmb_release :: proc() -> bool { return mouse_button(state.input.mouse.middle, .RELEASE) }
mmb_release_up :: proc() -> bool { return (mouse_button(state.input.mouse.middle, .RELEASE) || mouse_button(state.input.mouse.middle, .UP)) }
mmb_up :: proc() -> bool { return mouse_button(state.input.mouse.middle, .UP) }

set_cursor :: proc() { glfw_set_cursor() }
cursor :: proc(type: Cursor_Type) {	state.window.cursor.type = type }
cursor_size :: proc(axis: Axis) {
	if axis == .X {
		state.window.cursor.type = .X
	} else {
		state.window.cursor.type = .Y
	}
}