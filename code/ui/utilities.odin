package ui

new_uid :: proc() -> Uid
{
	if state.uid == 0 do state.uid += 1
	state.uid += 1 // make atomic
	return state.uid
}

mouse_in_quad :: proc(quad: Quad) -> bool {
	return pt_in_quad({f32(state.mouse.pos.x), f32(state.mouse.pos.y)}, quad)
}