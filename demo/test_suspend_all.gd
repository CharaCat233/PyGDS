extends SceneTree

## PyGDS 挂起系统综合测试 [br]
## 覆盖: SLEEPING/WAITING/嵌套函数/控制流/混合/预设代码/连续挂起/on_resume回调

## 通过 preload 引用解释器脚本, 避免依赖编辑器生成的全局类缓存 (CI 无缓存可解析)
const PYGDS_SCRIPT = preload("res://pygds.gd")

var _dsl: PYGDS_SCRIPT
var _test_queue: Array = []
var _test_idx: int = 0
var _passed: int = 0
var _failed: int = 0
var _suspend_count: int = 0
var _active_resume_count: int = 0
var _max_suspend: int = 50

func _init() -> void:
	print("=".repeat(60))
	print("PyGDS Suspend System — Comprehensive Tests")
	print("=".repeat(60))

	# 构建测试队列: [name, setup_func, expected_output, extra_check_func]
	# === A. SLEEPING 挂起 (sleep) — 基础 ===
	_test_queue.append(["A1. 顶层 sleep", func(dsl):
		dsl.write_dsl_script("print('a')\nsleep(0.1)\nprint('b')\n")
	, "a\nb\n", null])

	_test_queue.append(["A2. 函数内 sleep", func(dsl):
		dsl.write_dsl_script("def f():\n print('a')\n sleep(0.1)\n print('b')\nf()\n")
	, "a\nb\n", null])

	_test_queue.append(["A3. 嵌套函数 sleep (a→b→sleep)", func(dsl):
		dsl.write_dsl_script("def a():\n print('a1')\n b()\n print('a2')\ndef b():\n print('b1')\n sleep(0.1)\n print('b2')\na()\n")
	, "a1\nb1\nb2\na2\n", null])

	_test_queue.append(["A4. 三层嵌套 (a→b→c→sleep)", func(dsl):
		dsl.write_dsl_script("def a():\n b()\ndef b():\n c()\ndef c():\n print('x')\n sleep(0.1)\n print('y')\na()\n")
	, "x\ny\n", null])

	# === B. WAITING 挂起 (API) — 基础 ===
	_test_queue.append(["B1. 顶层 API 主动挂起", func(dsl):
		dsl.write_dsl_script("print('a')\nconfirm()\nprint('b')\n")
	, "a\nb\n", null])

	_test_queue.append(["B2. 函数内 API 主动挂起", func(dsl):
		dsl.write_dsl_script("def f():\n print('a')\n confirm()\n print('b')\nf()\n")
	, "a\nb\n", null])

	_test_queue.append(["B3. 嵌套函数内 API (a→b→confirm)", func(dsl):
		dsl.write_dsl_script("def a():\n print('a1')\n b()\n print('a2')\ndef b():\n print('b1')\n confirm()\n print('b2')\na()\n")
	, "a1\nb1\nb2\na2\n", null])

	# === C. 混合挂起 ===
	_test_queue.append(["C1. sleep 后 API", func(dsl):
		dsl.write_dsl_script("print('a')\nsleep(0.1)\nprint('b')\nconfirm()\nprint('c')\n")
	, "a\nb\nc\n", null])

	_test_queue.append(["C2. API 后 sleep", func(dsl):
		dsl.write_dsl_script("print('a')\nconfirm()\nprint('b')\nsleep(0.1)\nprint('c')\n")
	, "a\nb\nc\n", null])

	_test_queue.append(["C3. 函数内混合 (sleep+API)", func(dsl):
		dsl.write_dsl_script("def f():\n print('a')\n sleep(0.1)\n print('b')\n confirm()\n print('c')\nf()\n")
	, "a\nb\nc\n", null])

	# === D. 控制流中的挂起 ===
	_test_queue.append(["D1. if 分支内 sleep", func(dsl):
		dsl.write_dsl_script("if True:\n print('a')\n sleep(0.1)\n print('b')\nprint('c')\n")
	, "a\nb\nc\n", null])

	_test_queue.append(["D2. if-else (走 if 分支 sleep)", func(dsl):
		dsl.write_dsl_script("if True:\n print('a')\n sleep(0.1)\n print('b')\nelse:\n print('x')\nprint('c')\n")
	, "a\nb\nc\n", null])

	_test_queue.append(["D3. elif 分支 sleep", func(dsl):
		dsl.write_dsl_script("x=2\nif x==1:\n print('a')\nelif x==2:\n print('b')\n sleep(0.1)\n print('c')\nprint('d')\n")
	, "b\nc\nd\n", null])

	_test_queue.append(["D4. while 循环内 sleep", func(dsl):
		dsl.write_dsl_script("i=0\nwhile i<2:\n print(i)\n sleep(0.1)\n i=i+1\nprint('done')\n")
	, "0\n1\ndone\n", null])

	_test_queue.append(["D5. while 循环内 API 主动挂起", func(dsl):
		dsl.write_dsl_script("i=0\nwhile i<2:\n print(i)\n confirm()\n i=i+1\nprint('done')\n")
	, "0\n1\ndone\n", null])

	_test_queue.append(["D6. for 循环内 sleep", func(dsl):
		dsl.write_dsl_script("for x in[1,2]:\n print(x)\n sleep(0.1)\nprint('done')\n")
	, "1\n2\ndone\n", null])

	# === E. 函数调用中的挂起 ===
	_test_queue.append(["E1. 递归函数内 sleep", func(dsl):
		dsl.write_dsl_script("def f(n):\n if n>0:\n  print(n)\n  sleep(0.1)\n  f(n-1)\nf(2)\n")
	, "2\n1\n", null])

	_test_queue.append(["E2. 同一函数多次调用 sleep", func(dsl):
		dsl.write_dsl_script("def f():\n print('a')\n sleep(0.1)\n print('b')\nf()\nf()\n")
	, "a\nb\na\nb\n", null])

	# === F. 连续多次挂起 ===
	_test_queue.append(["F1. 同一函数多次 sleep", func(dsl):
		dsl.write_dsl_script("def f():\n print('a')\n sleep(0.1)\n print('b')\n sleep(0.1)\n print('c')\nf()\n")
	, "a\nb\nc\n", null])

	_test_queue.append(["F2. 同一函数多次 API 主动挂起", func(dsl):
		dsl.write_dsl_script("def f():\n print('a')\n confirm()\n print('b')\n confirm()\n print('c')\nf()\n")
	, "a\nb\nc\n", null])

	# === G. on_resume 回调 ===
	_test_queue.append(["G1. 主动挂起 + on_resume 回调", func(dsl):
		dsl.register_api_pair("confirm_cb", func(_a,_k):
			dsl.request_suspend_waiting(func(): _active_resume_count += 1)
		)
		dsl.write_dsl_script("print('before')\nconfirm_cb()\nprint('after')\n")
	, "before\nafter\n", func(name, dsl, expected):
		if _active_resume_count >= 2:
			return true
		else:
			print("  [FAIL] %s: on_resume count=%d (expected >=2)" % [name, _active_resume_count])
			return false
	])

	# === H. 预设代码 + 用户代码 ===
	_test_queue.append(["H1. 预设定义函数 + 用户代码调用挂起", func(dsl):
		dsl.set_preset_script("def greet(name):\n print('hello')\n sleep(0.1)\n print(name)\n")
		dsl.write_dsl_script("greet('world')\n")
	, "hello\nworld\n", null])

	create_timer(0.001).timeout.connect(_start_next_test)


func _start_next_test():
	if _test_idx >= _test_queue.size():
		print("")
		print("=".repeat(60))
		print("Results: %d passed, %d failed" % [_passed, _failed])
		print("=".repeat(60))
		if _failed > 0:
			print("SOME TESTS FAILED!")
			quit(1)
		else:
			print("ALL TESTS PASSED!")
			quit(0)
		return

	var entry = _test_queue[_test_idx]
	_test_idx += 1
	var name = entry[0]
	var setup_func: Callable = entry[1]
	var expected = entry[2]
	var extra_check: Callable = entry[3] if entry[3] != null else Callable()

	_suspend_count = 0
	_active_resume_count = 0

	_dsl = load("res://pygds.gd").new()
	_dsl._sleeping_resume_callback = func():
		_suspend_count += 1
		if _suspend_count > _max_suspend:
			printerr("  [FAIL] %s: SLEEPING 循环 > %d 次!" % [name, _max_suspend])
			_start_next_test()
			return
		create_timer(0.001).timeout.connect(_on_resume.bind(name, expected, extra_check))

	_dsl.register_api_pair("confirm", func(_a, _k):
		_dsl.request_suspend_waiting()
	)

	setup_func.call(_dsl)
	_on_resume(name, expected, extra_check)


func _on_resume(name: String, expected: String, extra_check: Callable):
	if _dsl.state == PYGDS_SCRIPT.State.SUSPENDED_WAITING:
		_dsl.state = PYGDS_SCRIPT.State.RUNNING

	var state = _dsl.run()

	match state:
		PYGDS_SCRIPT.State.SUSPENDED_SLEEPING:
			pass
		PYGDS_SCRIPT.State.SUSPENDED_WAITING:
			_active_resume_count += 1
			if _active_resume_count > _max_suspend:
				printerr("  [FAIL] %s: WAITING 循环 > %d 次!" % [name, _max_suspend])
				_start_next_test()
				return
			_on_resume(name, expected, extra_check)
		PYGDS_SCRIPT.State.FINISHED:
			_verify(name, expected, extra_check)
		PYGDS_SCRIPT.State.ERROR:
			_failed += 1
			print("  [FAIL] %s: %s" % [name, _dsl.report.last_error])
			_start_next_test()
		_:
			_failed += 1
			print("  [FAIL] %s: Unexpected state %d" % [name, state])
			_start_next_test()


func _verify(name: String, expected: String, extra_check: Callable):
	var actual = _dsl.print_output
	var ok = (actual == expected)
	if extra_check.is_valid():
		ok = ok and extra_check.call(name, _dsl, expected)
	if ok:
		_passed += 1
		print("  [PASS] %s" % name)
	else:
		_failed += 1
		print("  [FAIL] %s" % name)
		print("    Expected: %s" % expected.replace("\n", "\\n"))
		print("    Got:      %s" % actual.replace("\n", "\\n"))
	_start_next_test()
