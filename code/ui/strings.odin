package ui

import "core:fmt"
import "core:mem"

KEY_LEN :: 32
LONG_STRING_LEN :: 512

Key :: struct {
	mem: [KEY_LEN]u8,
	len: int,
}

string_to_key :: proc(text: string) -> Key {
	key: Key
	key.len = len(text)
	assert(key.len <= KEY_LEN, text)
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

V_String :: struct {
	mem: []u8,
	len: int,
	index: int,
	width: f32,
	lines: int,
	start: int,
	end: int,
}

to_string :: proc(es: ^String) -> string {
	return string(es.mem[:es.len])
}

from_string :: proc(text: string) -> String {
	es : String
	es.len = len(text)
	copy(es.mem[:es.len], text)
	return es
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

backspace :: proc(es: ^String) {
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


