package ui

import "core:fmt"
import "core:os"
import "core:mem"

load_doc :: proc(doc:^Document, filename:string) -> bool {
	close_doc(doc)
	
	fmt.println("trying to load doc:", filename)
	doc_ok := false
	doc.mem, doc_ok = os.read_entire_file(filename)
	if !doc_ok {
		fmt.println("ERROR LOADING", filename)
		return false
	}
	doc.len = len(doc.mem)

	temp_returns := make([]int, doc.len)
	defer delete(temp_returns)

	return_count := 0
	for char, index in doc.mem {
		if char == '\n' {
			return_count += 1
			temp_returns[return_count] = index
		}
	}
	
	doc.returns = make([]int, return_count)
	copy(doc.returns[:], temp_returns[:return_count])
	doc.return_count = return_count

	return true
}

close_doc :: proc(doc: ^Document) -> bool {
	fmt.println("closing doc")
	delete(doc.mem)
	delete(doc.returns)
	doc^ = {}
	return true
}

Document :: struct {
	mem: []u8,
	len: int,

	returns: []int,
	return_count: int,

	width: f32,
	lines: int,
	current_line: int,
	last_line: int,
	current_char: int,
	// index: int,
	// start: int,
	// end: int,
}
