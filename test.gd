extends SceneTree

## PyGDS 测试运行器

var test_results = {}
var passed_count = 0
var failed_count = 0
var error_count = 0


func _init() -> void:
	print("=".repeat(60))
	print("PyGDS Test Runner")
	print("=".repeat(60))
	print("")
	
	_run_all_tests()
	
	print("")
	print("=".repeat(60))
	print("Results: %d passed, %d failed, %d errors" % [passed_count, failed_count, error_count])
	print("Total: %d tests" % test_results.size())
	print("=".repeat(60))
	
	# Exit with appropriate code
	if failed_count > 0 or error_count > 0:
		print("SOME TESTS FAILED!")
		quit(1)
	else:
		print("ALL TESTS PASSED!")
		quit(0)


func _run_all_tests() -> void:
	var expected_path = "res://py_package/expected.json"
	
	if not FileAccess.file_exists(expected_path):
		print("ERROR: expected.json not found at: " + expected_path)
		quit(1)
		return
		
	var file = FileAccess.open(expected_path, FileAccess.READ)
	if file == null:
		print("ERROR: Cannot open expected.json")
		quit(1)
		return
		
	var json_text = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	var parse_result = json.parse(json_text)
	if parse_result != OK:
		print("ERROR: Failed to parse expected.json: " + json.get_error_message())
		quit(1)
		return
		
	var expected_data = json.get_data()
	if not expected_data is Dictionary:
		print("ERROR: expected.json is not a dictionary")
		quit(1)
		return
		
	var test_names = expected_data.keys()
	test_names.sort()
	
	for test_name in test_names:
		var test_case = expected_data[test_name]
		if not test_case is Dictionary:
			print("  [SKIP] %s: invalid test case format" % test_name)
			error_count += 1
			continue
			
		var source = test_case.get("source", "")
		var expected = test_case.get("expected", "")
		
		var dsl = load("res://pygds.gd").new()
		dsl.set_debug_mode(false)
		dsl.write_dsl_script(source)
		# 推进挂起: 用例可能调用 time.sleep (协作式挂起), 需反复恢复直到脚本结束
		# 与 CPython 的阻塞式 sleep 对应, 两侧最终都产出完整输出
		dsl.run()
		var pump_count = 0
		while dsl.state == dsl.State.SUSPENDED_SLEEPING and pump_count < 2000:
			pump_count += 1
			dsl.state = dsl.State.RUNNING
			dsl.run()
		if pump_count >= 2000:
			printerr("  [WARN] %s: 挂起恢复超过 2000 次, 可能存在循环挂起" % test_name)
		
		var actual = dsl.print_output
		
		# Normalize line endings
		expected = expected.replace("\r\n", "\n")
		actual = actual.replace("\r\n", "\n")
		
		if actual == expected:
			print("  [PASS] %s" % test_name)
			passed_count += 1
		else:
			print("  [FAIL] %s" % test_name)
			print("    Expected:")
			_print_multiline("      ", expected)
			print("    Actual:")
			_print_multiline("      ", actual)
			failed_count += 1
			test_results[test_name] = {
				"status": "FAIL",
				"expected": expected,
				"actual": actual
			}
			
		# Cleanup
		dsl.free()


func _print_multiline(indent: String, text: String) -> void:
	if text == "":
		print(indent + "(empty)")
		return
	var lines = text.split("\n")
	for line in lines:
		var display = line
		# Show invisible characters
		display = display.replace("\r", "\\r")
		display = display.replace("\t", "\\t")
		print(indent + display)
