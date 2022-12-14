package ui

import "core:fmt"
import "core:strconv"
import "core:strings"

start_editing_value :: proc(box: ^Box) {
	ebox, eok := state.boxes.all[state.boxes.editing]
	if eok do end_editing_value(ebox)

	state.boxes.editing = box.key
	box.editable_string = &state.ctx.editable_string
	box.editable_string^ = from_odin_string(fmt.tprint(box.value))
	string_select_all(box.editable_string)
}

end_editing_value :: proc(box: ^Box, commit:bool=true) -> string {
	fmt.println(to_odin_string(box.editable_string))
	ret_val := strings.clone(to_odin_string(box.editable_string))
	if commit {
		switch box.value.id {
			case string:
			val := cast(^string)box.value.data
			fmt.println("new val", val)
			val^ = to_odin_string(box.editable_string)

			case f32:
			parsed, ok := strconv.parse_f32(to_odin_string(box.editable_string))
			val := cast(^f32)box.value.data
			if ok do val^ = parsed

			case int:
			parsed, ok := strconv.parse_int(to_odin_string(box.editable_string))
			val := cast(^int)box.value.data
			if ok do val^ = parsed
		}
	}
	box.editable_string = nil
	state.ctx.editable_string = {}
	state.boxes.editing = {}

	return ret_val
}