extends SceneTree

## 文件 IO 双端 harness (基于 run_one.gd, 增加盘符沙箱与夹具)
## 用法: godot --headless --path . --script res://ci/run_one_io.gd -- res://tests/probes/r1011/<file>.py [diff|pygds|python]

var _re_addr: RegEx
var _re_main: RegEx
var _re_parse_err: RegEx
var PYRUN := "res://ci/_pyrun.py"
var RESULT_USER := "user://pyrun_result_audit.json"
var DRIVE := "PZ"


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
		print("usage: run_one_io.gd -- <res://file.py> [pygds|python|diff]")
		quit(1)
		return

	var source := _read_file(path)
	if source == "":
		print("ERROR: 无法读取文件: " + path)
		quit(1)
		return

	# 沙箱夹具: 盘内预放文本与二进制文件
	_pygds_script = load("res://pygds.gd")
	var root := _drive_root(DRIVE)
	DirAccess.make_dir_recursive_absolute(root)
	_place(root, "io_in.txt", "line1\nline2\nline3\n")
	_place(root, "noeol.txt", "abc")
	_place_bin(root, "bin_in.dat", PackedByteArray([65, 66, 67, 10, 68, 255, 254]))

	var pg_out := ""
	var pg_err := ""
	var pg_ok := true
	var cp_out := ""
	var cp_err := ""
	var cp_ok := true

	if mode == "pygds" or mode == "diff":
		var dsl = _pygds_script.new(DRIVE, true)
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
		_pygds_script._remove_dir_recursive(root)

	if mode == "python" or mode == "diff":
		# CPython 侧以临时目录为工作目录运行, 夹具同步预放
		var tmpdir := ProjectSettings.globalize_path("user://pyio_fixture")
		DirAccess.make_dir_recursive_absolute(tmpdir)
		var ftxt := FileAccess.open(tmpdir + "/io_in.txt", FileAccess.WRITE)
		ftxt.store_string("line1\nline2\nline3\n")
		ftxt.close()
		var ftxt2 := FileAccess.open(tmpdir + "/noeol.txt", FileAccess.WRITE)
		ftxt2.store_string("abc")
		ftxt2.close()
		var fbin := FileAccess.open(tmpdir + "/bin_in.dat", FileAccess.WRITE)
		fbin.store_buffer(PackedByteArray([65, 66, 67, 10, 68, 255, 254]))
		fbin.close()
		if FileAccess.file_exists(RESULT_USER):
			DirAccess.remove_absolute(OS.get_user_data_dir() + "/pyrun_result_audit.json")
		var py := _detect_python()
		OS.execute(py, PackedStringArray([
			ProjectSettings.globalize_path(PYRUN),
			ProjectSettings.globalize_path(path),
			OS.get_user_data_dir() + "/pyrun_result_audit.json",
			tmpdir
		]), [], false, false)
		if FileAccess.file_exists(RESULT_USER):
			var parsed = JSON.parse_string(_read_file("user://pyrun_result_audit.json"))
			if parsed is Dictionary:
				cp_out = parsed.get("stdout", "")
				cp_err = parsed.get("stderr", "")
				cp_ok = int(parsed.get("code", 1)) == 0
		DirAccess.remove_absolute(tmpdir + "/io_in.txt")
		DirAccess.remove_absolute(tmpdir + "/noeol.txt")
		DirAccess.remove_absolute(tmpdir + "/bin_in.dat")
		DirAccess.remove_absolute(tmpdir)

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


var _pygds_script: GDScript

func _drive_root(letter: String) -> String:
	var base: String = _pygds_script.base_path
	while base.begins_with("/"):
		base = base.substr(1)
	while base.ends_with("/"):
		base = base.substr(0, base.length() - 1)
	var root := "user://"
	if base != "":
		root += base + "/"
	return root + letter


func _place(root: String, rel: String, content: String) -> void:
	var full = root + "/" + rel
	var f = FileAccess.open(full, FileAccess.WRITE)
	f.store_string(content)
	f.close()


func _place_bin(root: String, rel: String, data: PackedByteArray) -> void:
	var full = root + "/" + rel
	var f = FileAccess.open(full, FileAccess.WRITE)
	f.store_buffer(data)
	f.close()


func _detect_python() -> String:
	for name in ["python3", "python"]:
		if OS.execute(name, ["--version"], [], true, false) == 0:
			return name
	return "python"


func _read_file(p: String) -> String:
	var f := FileAccess.open(p, FileAccess.READ)
	if f == null:
		return ""
	return f.get_as_text()


func _normalize(s: String) -> String:
	s = _re_addr.sub(s, " at 0x...>")
	s = _re_main.sub(s, "<__main__.", true)
	return s.strip_edges()


func _cp_last_error(err: String) -> String:
	var lines := err.strip_edges().split("\n")
	if lines.size() == 0:
		return ""
	for i in range(lines.size() - 1, -1, -1):
		var l: String = lines[i]
		if l.strip_edges() != "":
			return l.strip_edges()
	return ""


func _err_class(err: String) -> String:
	var c := err.split(":")
	if c.size() >= 2:
		return c[0].strip_edges()
	return err


func _norm_err(err: String) -> String:
	return _re_addr.sub(err, " at 0x...>").strip_edges()
