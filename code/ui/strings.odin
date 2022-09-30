package ui

import "core:fmt"

KEY_LEN :: 32
SHORT_STRING_LEN :: 64
LONG_STRING_LEN :: 128

Key :: struct {
	mem: [KEY_LEN]byte,
	len: int,
}

string_to_key :: proc(text: string) -> Key {
	key: Key
	key.len = len(text)
	assert(key.len <= KEY_LEN, text)
	copy(key.mem[:key.len], text)
	return key
}

Short_String :: struct {
	mem: [SHORT_STRING_LEN]byte,
	len: int,
}

Long_String :: struct {
	mem: [LONG_STRING_LEN]byte,
	len: int,
}

Editable_String :: struct {
	mem: [LONG_STRING_LEN]byte,
	len: int,
	start: int,
	end: int,
}



string_to_short :: proc(text: string) -> Short_String {
	short: Short_String
	short.len = len(text)
	assert(short.len <= SHORT_STRING_LEN, text)
	copy(short.mem[:short.len], text)
	return short
}

string_to_editable :: proc(text: string) -> Editable_String {
	es: Editable_String
	es.len = len(text)
	assert(es.len <= LONG_STRING_LEN, text)
	// fmt.println(len(es.mem),	es.len, len(text))
	copy(es.mem[:es.len], text)
	return es
}

editable_to_string :: proc(es: ^Editable_String) -> string {
	return string(es.mem[:es.len])
}

editable_jump_right :: proc(es: ^Editable_String) -> int {
	start := es.start
	end := es.end
	if start > end {
		start = es.end
		end = es.start
	}

	for m in end+1..=es.len+1 {
		letter := rune(es.mem[m])
		if m == es.len {
			return m
		} else if letter == ' ' {
			return m
		}
	}
	return 0
}

editable_ctrl_left :: proc(editable: ^Editable_String) {

}

editable_jump_left :: proc(es: ^Editable_String) -> int {
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

backspace :: proc(es: ^Editable_String) {
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
			es.len = es.len - (es.end-1 - es.start)
			es.end = es.start
		} else if es.end < es.start {
			copy(es.mem[es.end:], es.mem[es.start:])
			fmt.println(es.start, es.end, es.len)
			es.len -= (es.start - es.end)
			es.start = es.end
		}
	}
	fmt.println(es)
}

short_to_string :: proc(short: ^Short_String) -> string {
	return string(short.mem[:short.len])
}

key_to_string :: proc(key: ^Key) -> string {
	return string(key.mem[:key.len])
}

