extends Object

class ImgLoadRequest:
	extends RefCounted
	
	var filepath: String
	var callback_func: Callable
	var is_main_cover: bool
	var index: int
	var thread := Thread.new()

var _img_load_request_queue := LinkedList.new()

# variable used to keep track of how many threads are currently loading images
var _img_load_mutex := Mutex.new()
var _running_img_load_threads := 0

var _max_img_load_threads: int

func _init(num_threads: int = 10) -> void:
	_max_img_load_threads = num_threads

func load_texture(filepath: String, callback_func: Callable, is_main_cover: bool, index: int) -> void:
	var new_req := ImgLoadRequest.new()
	new_req.filepath = filepath
	new_req.callback_func = callback_func
	new_req.is_main_cover = is_main_cover
	new_req.index = index
	_img_load_request_queue.push_back(new_req)
	
	_start_next_img_load()

func _start_next_img_load() -> void:
	_img_load_mutex.lock()
	if _img_load_request_queue.size() > 0 and _running_img_load_threads < _max_img_load_threads:
		var next_req := _img_load_request_queue.pop_front() as ImgLoadRequest
		
		if next_req and next_req.thread.start(_load_img_threaded.bind(next_req)) == OK:
			_running_img_load_threads += 1
	_img_load_mutex.unlock()

func _load_img_threaded(req: ImgLoadRequest) -> void:
	# read cover image data from file into a buffer
	var img := Image.load_from_file(req.filepath)
	var tex := ImageTexture.create_from_image(img)
	
	# perform callback in the form of my_callback(texture, filepath, ...)
	req.callback_func.bind(tex, req.is_main_cover, req.index).call()
	
	# decrement count to show that this thread is done and another can start
	_img_load_mutex.lock()
	_running_img_load_threads -= 1
	_img_load_mutex.unlock()
	
	# start next load if there are any waiting
	_start_next_img_load()
