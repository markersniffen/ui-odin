package ui

import "core:fmt"

new_uid :: proc() -> Uid
{
	if state.uid == 0 do state.uid += 1
	state.uid += 1 // make atomic
	return state.uid
}

mouse_in_quad :: proc(quad: Quad) -> bool {
	return pt_in_quad({f32(state.input.mouse.pos.x), f32(state.input.mouse.pos.y)}, quad)
}

v2_f32 :: proc(value: v2i) -> v2 {
	return {f32(value.x), f32(value.y)}
}

linear :: proc(value, OldMin, OldMax, NewMin, NewMax: f32) -> f32 {
	return (((value - OldMin) * (NewMax - NewMin)) / (OldMax - OldMin)) + NewMin
}

concat :: proc(texts: ..any) -> string {
	return fmt.tprint(args=texts, sep="")
}