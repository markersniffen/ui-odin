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
	editable: Editable_String
	editable.len = len(text)
	assert(editable.len <= LONG_STRING_LEN, text)
	fmt.println(len(editable.mem),	editable.len, len(text))
	copy(editable.mem[:editable.len], text)
	return editable
}

editable_to_string :: proc(editable: ^Editable_String) -> string {
	return string(editable.mem[:editable.len])
}

editable_jump_right :: proc(editable: ^Editable_String) -> int {
	start := clamp(editable.start+1, 0, editable.len)
	for m in editable.start+1..=editable.len {
		letter := rune(editable.mem[m])
		if letter == ' ' || m == editable.len {
			if m == editable.len {
				return m -1
				// editable.start = m-1
			} else {
				return m
				// editable.start = m
			}
			// editable.end = editable.start
		}
	}
	return 0
}

editable_ctrl_left :: proc(editable: ^Editable_String) {

}

editable_jump_left :: proc(editable: ^Editable_String) -> int {
	fmt.println("Start", editable.start, 0)
	index := clamp(editable.start-2, 0, editable.len)
	fmt.println(rune(editable.mem[index]))
	for index >= 0 {
		letter := rune(editable.mem[index])
		fmt.println(letter, index)
		if letter == ' ' || index == 0 {
			if index == 0 {
				// editable.start = index
				return index
			} else {
				// editable.start = index+1
				return index+1
			}
			// editable.end = editable.start
		}
		index -= 1
	}
	return 0
}

short_to_string :: proc(short: ^Short_String) -> string {
	return string(short.mem[:short.len])
}

key_to_string :: proc(key: ^Key) -> string {
	return string(key.mem[:key.len])
}

