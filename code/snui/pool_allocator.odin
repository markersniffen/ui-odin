package snui

import "core:fmt"
import "core:mem"

//- NOTE Simple Pool allocator 
// TODO make this growable...
Node :: struct
{
	next: ^Node,
}

Pool :: struct
{
	memory: []byte,
	chunk_size: int,
	chunk_count: int,
	head: ^Node,
}

pool_init :: proc(p: ^Pool, size: int, count: int)
{
	p.chunk_size = size; // set chunk_size
	p.chunk_count = count; // set count
	Ok:any;
	p.memory, Ok = mem.alloc_bytes(size * count); // allocated the total bytes
	p.head = nil; // sets the head to null
	
	pool_free_all(p);
}

pool_free_all :: proc(p: ^Pool)
{
	mem.zero(&p.memory[0], p.chunk_count * p.chunk_size)
		for C in 0..<p.chunk_count // loop through number of chunks
	{
		ptr := &p.memory[C * p.chunk_size]; // get pointer to the Chunk memory
		node : ^Node = cast(^Node)ptr; // create  cast the pointer we just created to a Node object,
		node.next = p.head; // Set the Node's "next" value to the current pool's "head" (^Node)
		p.head = node; // set the pool's "head" to the current Node
	}
}

pool_alloc :: proc (p: ^Pool) -> rawptr
{
	new_alloc := p.head
	if new_alloc != nil
	{
		p.head = p.head.next
		mem.zero(new_alloc, p.chunk_size)
		
		return new_alloc
	}
	return nil
}

pool_free :: proc(p: ^Pool, ptr: rawptr) -> bool
{
	node : ^Node
	
	start := &p.memory
	length := (p.chunk_size * p.chunk_count) - 1
	end := &p.memory[length]
	
	if ptr == nil do return false
	if !(start <= ptr && ptr < end) do return false
	
	// Push free Node
	node = cast(^Node)ptr
	node.next = p.head
	p.head = node
	return true
}

pool_delete :: proc(p: ^Pool)
{
	free(&p.memory[0])
}