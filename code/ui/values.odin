package ui

import "core:fmt"
import "core:strconv"

start_editing_value :: proc(box: ^Box) {
	box.editable_string = &state.ui.ctx.editable_string
	box.editable_string^ = from_string(fmt.tprintf("%v", (cast(^f32)box.value.data)^))
	string_select_all(box.editable_string)
	fmt.println("Starting edit...", to_string(box.editable_string))
}

end_editing_value :: proc(box: ^Box) {
	parsed, ok := strconv.parse_f32(to_string(box.editable_string))
	val := cast(^f32)box.value.data
	if ok do val^ = parsed
	box.editable_string = nil
	fmt.println("Done editing", parsed, ok)
}

