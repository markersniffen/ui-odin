package ui

import "core:fmt"
import "core:mem"

//- NOTE Simple Pool allocator 
Node :: struct 
{
	next: ^Node,
}

Pool :: struct
{
	name: string,
	pages: [dynamic][]byte,
	node_size:int,					// size of each node
	page_size: int,
	nodes_per_page: int,

	nodes_used: int,
	num_pages: int,
	
	head: ^Node,
}

pool_init :: proc(pool: ^Pool, size: int, count: int, name: string)
{
	pool.name = name
	pool.node_size = size										// set chunk_size
	pool.nodes_per_page = count
	pool.page_size = size * count
	pool.num_pages = 1

	first_page, ok := mem.alloc_bytes(pool.page_size)	// allocated the total bytes
	append(&pool.pages, first_page)
	
	pool_free_page(pool, 0)
	
	fmt.println(fmt.tprintf("Initialized >>%v<< Pool | Size: %v | Count: %v | Head: %v", name, size, count, pool.head))
}

pool_free_page :: proc(pool: ^Pool, page_number: int)
{
	mem.zero(&pool.pages[page_number][0], pool. node_size * pool.nodes_per_page)
	
	prev := pool.head
	for index in 0..<pool.nodes_per_page
	{
		ptr := &pool.pages[page_number][index * pool.node_size]
		node: ^Node = cast(^Node)ptr
		if prev == nil {
			pool.head = node
		} else {
			prev.next = node
		}
		prev = node
	}
}

pool_alloc :: proc(pool: ^Pool) -> rawptr
{
	new_alloc := pool.head
	if new_alloc.next == nil {
		new_page, ok := mem.alloc_bytes(pool.page_size)
		append(&pool.pages, new_page)
		pool.num_pages += 1
		pool_free_page(pool, pool.num_pages-1)
	}
	
	pool.head = pool.head.next
	mem.zero(new_alloc, pool.node_size)		
	pool.nodes_used += 1
	return new_alloc
}

pool_free :: proc(pool: ^Pool, ptr: rawptr) -> bool
{
	node : ^Node
	
	if ptr == nil do return false

	in_page := false
	for page in pool.pages {
		start := &page[0]
		length := pool.page_size - 1
		end := &page[length]
		if (start <= ptr && ptr < end) do in_page = true
	}
	assert(in_page, "ptr to Pool Node not found in any page!")
	
	mem.zero(ptr, pool.node_size)
	
	// Push free Node
	node = cast(^Node)ptr
	node.next = pool.head
	pool.head = node

	pool.nodes_used -= 1
	return true
}

pool_delete :: proc(pool: ^Pool)
{
	// free(&pool.memory[0])
}