package ui

PROFILER :: false

when PROFILER do import tracy "../../../odin-tracy"
import sapp "../../../sokol-odin/sokol/app"

import "core:time"

when ODIN_OS == .Windows { import win "core:sys/windows" }

Uid :: u64

v2 :: [2]f32
v3 :: [3]f32
v4 :: [4]f32

v2i :: [2]i32
v3i :: [3]i32
v4i :: [4]i32

state : ^State

State :: struct {
	init:					proc(),
	frame:				proc(),

	uid: 					Uid,
	sokol:				Sokol,
	window: 				Window,
	ui: 					Ui,
	input: 				Input,
	
	debug: 				Debug,
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

init :: proc(init: proc() = nil, frame: proc() = nil, title:string="My App", width:i32=1280, height:i32=720) -> (^State, bool) {
	state = new(State)
	state.init = init
	state.frame = frame
	state.window.title = title
	state.window.size = {width, height}

	ui_init()
	sokol()

	return state, true
}

quit :: proc() {
	sapp.quit()
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
esc :: proc() -> bool { return state.input.keys.escape }
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