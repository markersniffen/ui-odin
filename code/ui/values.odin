package ui

import "core:fmt"
import "core:strconv"

start_editing_value :: proc(box: ^Box) {
	box.editable_string = &state.ui.ctx.editable_string
	box.editable_string^ = from_string(fmt.tprint(box.value))
	string_select_all(box.editable_string)
	fmt.println("Starting edit...", to_string(box.editable_string), ">>>", box.value)
}

end_editing_value :: proc(box: ^Box) {
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

	box.editable_string = nil
	fmt.println("Done editing")
}

