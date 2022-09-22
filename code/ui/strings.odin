package ui

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
	mem: [KEY_LEN]byte,
	len: int,
}

Long_String :: struct {
	mem: [KEY_LEN]byte,
	len: int,
}

string_to_short :: proc(text: string) -> Short_String {
	short: Short_String
	short.len = len(text)
	assert(short.len <= SHORT_STRING_LEN, text)
	copy(short.mem[:short.len], text)
	return short
}

short_to_string :: proc(short: ^Short_String) -> string {
	return string(short.mem[:short.len])
}

key_to_string :: proc(key: ^Key) -> string {
	return string(key.mem[:key.len])
}