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
	original_size: int,
	head: ^Node,
}

pool_init :: proc(pool: ^Pool, size: int, count: int)
{
	pool.chunk_size = size								// set chunk_size
	pool.chunk_count = count							// set count
	pool.original_size = size
	ok: any
	pool.memory, ok = mem.alloc_bytes(size * count) 	// allocated the total bytes
	pool.head = nil										// sets the head to null
	pool_free_all(pool)
}

pool_free_all :: proc(pool: ^Pool)
{
	mem.zero(&pool.memory[0], pool.chunk_count * pool.chunk_size)

	for chunk in 0..<pool.chunk_count				// loop through number of chunks
	{
		ptr := &pool.memory[chunk * pool.chunk_size]	// get pointer to the Chunk memory
		node: ^Node = cast(^Node)ptr			// create  cast the pointer we just created to a Node object,
		node.next = pool.head						// Set the Node's "next" value to the current pool's "head" (^Node)
		pool.head = node							// set the pool's "head" to the current Node
	}
}

pool_alloc :: proc(pool: ^Pool) -> rawptr
{
	new_alloc := pool.head
	if new_alloc != nil
	{
		pool.head = pool.head.next
		mem.zero(new_alloc, pool.chunk_size)
		
		return new_alloc
	}
	return nil
}

// pool_grow :: proc(pool: ^Pool) -> bool
// {
// 	// TODO implement
// }

pool_free :: proc(pool: ^Pool, ptr: rawptr) -> bool
{
	node : ^Node
	
	start := &pool.memory
	length := (pool.chunk_size * pool.chunk_count) - 1
	end := &pool.memory[length]
	
	if ptr == nil do return false
	if !(start <= ptr && ptr < end) do return false
	
	// Push free Node
	node = cast(^Node)ptr
	node.next = pool.head
	pool.head = node
	return true
}

pool_delete :: proc(pool: ^Pool)
{
	free(&pool.memory[0])
}