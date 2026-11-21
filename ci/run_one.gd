extends SceneTree

## 单文件直跑 harness (审计用, 参照 ci/run_cases.gd 的进程内执行方式)
## 用法:
##   godot --headless --path . --script res://ci/run_one.gd -- res://tests/probes/xxx.py [pygds|python|diff]
## pygds  = 仅运行 PyGDS, 打印 stdout / 错误
## python = 仅运行 CPython
## diff   = 双端运行并逐行比对输出 (默认)

var _re_addr: RegEx
var _re_main: RegEx
var _re_parse_err: RegEx
var PYRUN := "res://ci/_pyrun.py"
var RESULT_USER := "user://pyrun_result_audit.json"


func _init() -> void:
	_re_addr = RegEx.create_from_string(" at 0x[0-9a-fA-F]+>")
	_re_main = RegEx.create_from_string("<__main__\\.")
	_re_parse_err = RegEx.create_from_string("^Line \\d+, Column \\d+: ")

	var args := OS.get_cmdline_user_args()
	var path := ""
	var mode := "diff"
	if args.size() >= 1:
		path = args[0]
	if args.size() >= 2:
		mode = args[1]
	if path == "":
		print("usage: run_one.gd -- <res://file.py> [pygds|python|diff]")
		quit(1)
		return

	var source := _read_file(path)
	if source == "":
		print("ERROR: 无法读取文件: " + path)
		quit(1)
		return

	var pg_out := ""
	var pg_err := ""
	var pg_ok := true
	var cp_out := ""
	var cp_err := ""
	var cp_ok := true

	if mode == "pygds" or mode == "diff":
		var script: GDScript = load("res://pygds.gd")
		var dsl = script.new("", false)
		if dsl == null:
			print("ERROR: pygds.gd 加载失败")
			quit(1)
			return
		dsl.set_debug_mode(false)
		dsl.write_dsl_script(source)
		dsl.run()
		var pump := 0
		while dsl.state == dsl.State.SUSPENDED_SLEEPING and pump < 500:
			pump += 1
			dsl.state = dsl.State.RUNNING
			dsl.run()
		pg_ok = dsl.state != dsl.State.ERROR
		if not pg_ok and dsl.report != null:
			pg_err = dsl.report.last_error
			var m := _re_parse_err.search(pg_err)
			if m != null:
				pg_err = "SyntaxError: " + pg_err.substr(m.get_end())
		pg_out = dsl.print_output
		dsl.free()

	if mode == "python" or mode == "diff":
		var result_os := OS.get_user_data_dir() + "/pyrun_result_audit.json"
		if FileAccess.file_exists(RESULT_USER):
			DirAccess.remove_absolute(result_os)
		var py := _detect_python()
		OS.execute(py, PackedStringArray([
			ProjectSettings.globalize_path(PYRUN),
			ProjectSettings.globalize_path(path),
			result_os, ""
		]), [], false, false)
		if FileAccess.file_exists(RESULT_USER):
			var parsed = JSON.parse_string(_read_file(RESULT_USER))
			if parsed is Dictionary:
				cp_out = parsed.get("stdout", "")
				cp_err = parsed.get("stderr", "")
				cp_ok = int(parsed.get("code", 1)) == 0

	if mode == "pygds":
		print("--- PyGDS stdout ---")
		print(pg_out)
		if not pg_ok:
			print("--- PyGDS error ---")
			print(pg_err)
		quit(0)
		return
	if mode == "python":
		print("--- CPython stdout ---")
		print(cp_out)
		if not cp_ok:
			print("--- CPython error ---")
			print(cp_err)
		quit(0)
		return

	# diff 模式: 归一化后逐行比对
	var n_pg := _normalize(pg_out)
	var n_cp := _normalize(cp_out)
	var err_pg := pg_err.strip_edges()
	var err_cp := _cp_last_error(cp_err)
	if n_cp == n_pg and (pg_ok == cp_ok):
		if pg_ok:
			print("SAME: 输出一致 (%d 行)" % n_pg.split("\n").size())
		else:
			if _err_class(err_cp) == _err_class(err_pg) and _norm_err(err_cp) == _norm_err(err_pg):
				print("SAME: 双端报错一致: %s" % err_cp)
			else:
				print("DIFF-ERR:\n[CPython] %s\n[PyGDS]   %s" % [err_cp, err_pg])
		quit(0)
		return

	if pg_ok != cp_ok:
		print("ONESIDED (PyGDS err=%s):" % str(not pg_ok))
		print("[CPython] %s" % (err_cp if not cp_ok else "(正常)"))
		print("[PyGDS]   %s" % (err_pg if not pg_ok else "(正常)"))
		print("--- PyGDS stdout ---\n%s--- CPython stdout ---\n%s" % [pg_out, cp_out])
		quit(1)
		return
	if not pg_ok:
		print("DIFF-ERR:\n[CPython] %s\n[PyGDS]   %s" % [err_cp, err_pg])
		if _err_class(err_cp) == _err_class(err_pg):
			print("(异常类相同, 消息差异如上)")
		quit(1)
		return
	print("DIFF-OUT:")
	var cp_lines := n_cp.split("\n")
	var pg_lines := n_pg.split("\n")
	var n := maxi(cp_lines.size(), pg_lines.size())
	var shown := 0
	for i in range(n):
		var a: String = cp_lines[i] if i < cp_lines.size() else "<missing>"
		var b: String = pg_lines[i] if i < pg_lines.size() else "<missing>"
		if a != b:
			print("  line %d:\n    CP: %s\n    PG: %s" % [i + 1, a, b])
			shown += 1
			if shown >= 30:
				print("  ...(更多差异省略)")
				break
	quit(1)


func _detect_python() -> String:
	var candidates := ["python3", "python"]
	if OS.get_name() == "Windows":
		candidates = ["python", "python3"]
	for cmd in candidates:
		var out := []
		if OS.execute(cmd, PackedStringArray(["--version"]), out, false, false) == 0:
			return cmd
	return ""


func _cp_last_error(stderr: String) -> String:
	var lines := stderr.replace("\r\n", "\n").split("\n")
	for i in range(lines.size() - 1, -1, -1):
		var line := lines[i].strip_edges()
		if line != "":
			return line
	return ""


func _err_class(err_line: String) -> String:
	var line := err_line.strip_edges()
	var idx := line.find(":")
	if idx < 0:
		return line
	return line.substr(0, idx).strip_edges()


func _norm_err(msg: String) -> String:
	var s := msg.strip_edges()
	if s.ends_with(")"):
		var idx := s.rfind(" (line ")
		if idx >= 0:
			s = s.substr(0, idx).strip_edges()
	return _normalize(s)


func _normalize(text: String) -> String:
	var t := text.replace("\r\n", "\n")
	t = _re_addr.sub(t, ">", true)
	t = _re_main.sub(t, "<", true)
	return t


func _read_file(path: String) -> String:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return ""
	var text := file.get_as_text()
	file.close()
	return text
