package ui

import "core:fmt"
import "core:mem"

KEY_LEN :: 128
LONG_STRING_LEN :: 512

Key :: struct {
	mem: [KEY_LEN]u8,
	len: int,
}

string_to_key :: proc(text: string) -> Key {
	key: Key
	key.len = min(len(text), KEY_LEN)

	// assert(key.len <= KEY_LEN, "key length is too long")
	copy(key.mem[:key.len], text)
	return key
}

key_to_string :: proc(key: ^Key) -> string {
	return string(key.mem[:key.len])
}

String :: struct {
	mem: [LONG_STRING_LEN]u8,
	len: int,
	max: int,
	start: int,
	end: int,
}

to_string :: proc(es: ^String) -> string {
	if es.len == 0 do fmt.println(es)
	assert(es.len != 0, "^String has zero length")
	return string(es.mem[:es.len])
}

replace_string :: proc(es: ^String, text: string) {
	new_len := len(text)
	if new_len > es.len {
		mem.zero(&es.mem[new_len], new_len-es.len)
	}
	es.len = new_len
	copy(es.mem[:es.len], text)
}

from_string :: proc(text: string) -> String {
	es : String
	es.len = len(text)
	assert(es.len <= LONG_STRING_LEN, text)
	copy(es.mem[:es.len], text)
	return es
}

string_len_assert :: proc(es: ^String) {
	for letter, i in es.mem {
		if letter == 0 {
			assert(es.len == i, "Editable_Text len doesn't match number of characters.")
			break
		}
	}
}

string_backspace :: proc(es: ^String) {
	if es.start >= 0 { // TODO there might be a bug here
		if es.start == es.end {
			if es.start != 0 {
				es.start-=1
				es.end = es.start
				if es.start >= es.len {
					copy(es.mem[es.start-1:], es.mem[es.start:])
				} else {
					copy(es.mem[es.start:], es.mem[es.start+1:])
				}
				es.len -= 1
			}
		} else if es.start < es.end {
			copy(es.mem[es.start:], es.mem[es.end:])
			es.len = es.len - (es.end - es.start)
			es.end = es.start
		} else if es.end < es.start {
			copy(es.mem[es.end:], es.mem[es.start:])
			es.len -= (es.start - es.end)
			es.start = es.end
		}
	}
}

string_backspace_all :: proc(es: ^String) {
	es.start = editable_jump_left(es)
	string_backspace(es)
}

string_delete :: proc (es: ^String) {
	if es.start == es.end {
		if es.start != es.len {
			copy(es.mem[es.start:], es.mem[es.start+1:])
			es.len -= 1
		}
	} else if es.end > es.start {
		copy(es.mem[es.start:], es.mem[es.end:])
		es.len -= (es.end - es.start)
		es.end = es.start
	} else {
		copy(es.mem[es.end:], es.mem[es.start:])
		es.len -= (es.start - es.end)
		es.start = es.end
	}
}

string_delete_all :: proc(es: ^String) {
	es.end = editable_jump_right(es)
	string_delete(es)
}

editable_jump_right :: proc(es: ^String) -> int {
	start := es.start
	end := es.end
	if start > end {
		start = es.end
		end = es.start
	}

	index := end+1
	if index > es.len {
		return es.len
	} else {
		for index <= es.len {
			letter := rune(es.mem[clamp(index, 0, es.len)])
			if letter == 0 || letter == ' ' {
				return index
			}
			index += 1
		}
	}
	return 0
}

editable_jump_left :: proc(es: ^String) -> int {
	start := es.start
	end := es.end
	if start > end {
		start = es.end
		end = es.start
	}

	index := start-1
	for index >= 0 {
		letter := rune(es.mem[clamp(index, 0, es.len)])
		if index == 0 {
			return index
		} else if letter == ' ' {
			return index
		}
		index -= 1
	}
	return 0
}

string_home :: proc(es: ^String) {
	es.start = 0
	es.end = 0
}

string_end :: proc(es: ^String) {
	es.start = es.len
	es.end = es.len
}

string_select_all :: proc(es: ^String) {
	es.start = 0
	es.end = es.len
}

