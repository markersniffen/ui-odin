package snui

new_uid :: proc() -> Uid
{
	if state.uid == 0 do state.uid += 1
	state.uid += 1 // make atomic
	return state.uid
}
