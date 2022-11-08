package ui

import "core:fmt"
import "core:strconv"

start_editing_value :: proc(box: ^Box) {
	fmt.println("starting editing value")
	
	if state.ui.boxes.editing != nil {
		end_editing_value(state.ui.boxes.editing)
	}


	state.ui.boxes.editing = box
	box.editable_string = &state.ui.ctx.editable_string
	box.editable_string^ = from_string(fmt.tprint(box.value))
	string_select_all(box.editable_string)
}

end_editing_value :: proc(box: ^Box, commit:bool=false) {
	fmt.println("ending editing value. commit:", commit)
	if commit {
		switch box.value.id {
			case string:
			val := cast(^string)box.value.data
			val^ = to_string(box.editable_string)

			case f32:
			parsed, ok := strconv.parse_f32(to_string(box.editable_string))
			val := cast(^f32)box.value.data
			if ok do val^ = parsed

			case int:
			parsed, ok := strconv.parse_int(to_string(box.editable_string))
			val := cast(^int)box.value.data
			if ok do val^ = parsed
		}
	}
	box.editable_string = nil
	state.ui.ctx.editable_string = {}
	state.ui.boxes.editing = nil
	fmt.println(box.value)
}

// end_editing_value :: proc(box: ^Box) {
// 	fmt.println("ENDING EDIT FOR", to_string(&box.name))
// 	switch box.value.id {
// 		case string:
// 		val := cast(^string)box.value.data
// 		val^ = to_string(box.editable_string)

// 		case f32:
// 		parsed, ok := strconv.parse_f32(to_string(box.editable_string))
// 		val := cast(^f32)box.value.data
// 		if ok do val^ = parsed

// 		case int:
// 		parsed, ok := strconv.parse_int(to_string(box.editable_string))
// 		val := cast(^int)box.value.data
// 		if ok do val^ = parsed
// 	}

// 	box.ops.editing = false
// 	box.editable_string = nil
// 	state.ui.boxes.editing = nil
// 	fmt.println("Done editing")
// }

// end_editing_text :: proc(box: ^Box) {
// 	// box.ops.editing = false
// 	state.ui.boxes.editing = nil
// }