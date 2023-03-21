package ui

import fp "core:path/filepath"
import "core:os"

file_browser :: proc (path: ^String, _filters:[]string={}) -> bool {
	begin()
	axis(.Y)
	size(.PIXELS, 600, .SUM_CHILDREN, 1)
	empty("file_browser")
		axis(.X)
		size(.PCT_PARENT, 1, .TEXT, 1)
		empty("file_browser2")
			size(.MIN_SIBLINGS, 1, .TEXT, 1)
			drag_panel("Load file:")
			size(.TEXT, 1, .TEXT, 1)
			if button("<#> x ").released do delete_panel(state.panels.floating)
		pop()
		axis(.Y)
		size(.PCT_PARENT, 1, .TEXT, 1)
		empty("load file button")
			axis(.X)
			size(.MIN_SIBLINGS, 1, .TEXT, 1)
			edit_text("file browser", path)
			size(.TEXT, 1, .TEXT, 1)
			override_result := false
			if button("Open###file").released {
				override_result = true
				delete_panel(state.panels.floating)
			}
			spacer_pixels("load file spacer", 4)
			filters : []string
			if radio("Filter###switch").ops.selected do filters = _filters
		pop()
		axis(.Y)
		size(.PCT_PARENT, 1, .TEXT, 12)
		scrollbox("file_browser")
		axis(.Y)
		size(.PCT_PARENT, 1, .SUM_CHILDREN, 1)
		empty("file_browser3")
		axis(.Y)
		size(.PCT_PARENT, 1, .TEXT, 1)
		result := find_files_and_run(path, filters)
	pop()
	end()
	if override_result do result = true
	return result
}

find_files_and_run :: proc(path:^String, filters:[]string={}) -> bool {
	using fp
	result := false

	if path.mem[path.len] == '\\' {
		path.mem[path.len] = 0
		path.len -= 1
	}
	path_string := to_odin_string(path)
	if os.is_dir(path_string) {
		handle, hok := os.open(path_string)
		file_list, fok := os.read_dir(handle, 0)

		if button("..").released {
			for i := path.len-1; i > 0; i -= 1 {
				char := path.mem[i]
				path.mem[i] = 0
				path.len -= 1
				if char == '\\' {
					break
				}
			}
		}
		for file in file_list {
			if file.is_dir {
				if button(concat("<#>g<b>", file.name)).released {
					replace_string(path, concat(path_string[:len(path_string)], '\\', file.name))
				}
			} else {
				skip := true
				if len(filters) == 0 {
					skip = false
				} else {
					for filter in filters {
						if filter == ext(file.name) {
							skip = false
						}
					}
				}
				if !skip {
					if button(file.name).released {
						result = true
						replace_string(path, concat(path_string[:len(path_string)], '\\', file.name))
						delete_panel(state.panels.floating)
					}
				}
			}
		}
	}
	return result
}
