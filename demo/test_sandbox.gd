extends SceneTree

## PyGDS 盘符虚拟沙箱综合测试 [br]
## 覆盖: 路径收敛正反两向 / open + import + load_dsl_script 组合 / [br]
## path_access 四象限 / close-free 时序 / 多实例共享与随机盘符 / 非法盘符拒绝

## 通过 load 引用解释器脚本, 避免依赖编辑器生成的全局类缓存 (CI 无缓存可解析) [br]
## 沙箱为宿主侧能力, CPython 无对应语义, 不进 ci/ 双端用例体系而独立成套件

var _pygds_script: GDScript = null
var _passed: int = 0
var _failed: int = 0

## 本套件专用的命名盘符 (仅字母), 与挂起套件 / 双端用例的盘符互不相干
const DRIVES := ["PA", "PB", "PC", "PD", "PE", "PF", "PG", "PH", "PI", "RA"]


func _init() -> void:
	print("=".repeat(60))
	print("PyGDS Drive Sandbox — Comprehensive Tests")
	print("=".repeat(60))

	_pygds_script = load("res://pygds.gd")
	# 清除上一轮在命名盘符留下的状态, 保证可重复运行 (随机盘符目录一并尽力清除)
	for letter in DRIVES:
		_pygds_script._remove_dir_recursive(_drive_root(letter))

	_probe_path_positive()
	_probe_path_negative()
	_probe_subdir_main()
	_probe_import_combo()
	_probe_load_and_write()
	_probe_no_access()
	_probe_close_free_timing()
	_probe_multi_random()
	_probe_invalid_drive()

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


func _check(name: String, ok: bool, detail: String = "") -> void:
	if ok:
		_passed += 1
		print("  [PASS] %s" % name)
	else:
		_failed += 1
		print("  [FAIL] %s" % name)
		if detail != "":
			print("      %s" % detail)


## 按盘符字母计算沙箱根 (与 PyGDS.base_path 的归一化口径一致)
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


## 在盘内预放文件 (宿主侧, 模拟宿主预放数据的推荐方式)
func _place(root: String, rel: String, content: String) -> void:
	var full = root + "/" + rel
	DirAccess.make_dir_recursive_absolute(full.substr(0, full.rfind("/")))
	var f = FileAccess.open(full, FileAccess.WRITE)
	f.store_string(content)
	f.close()


## 写入并运行一段脚本, 返回 print_output (报错时返回带错误文本的标记串)
func _run_ok(dsl, source: String) -> String:
	if not dsl.write_dsl_script(source):
		return "<write rejected>"
	dsl.run()
	if dsl.state == dsl.State.ERROR:
		return "<error> " + dsl.report.last_error
	return dsl.print_output


func _new_drive(letter: String, access: bool):
	return _pygds_script.new(letter, access)


## 一. 路径收敛正向: 裸相对路径以主脚本目录为基准, 本盘符前缀可用, .. 在盘内可回溯
func _probe_path_positive() -> void:
	print("[group] path convergence (positive)")
	var root := _drive_root("PA")
	var dsl = _new_drive("PA", true)

	var out = _run_ok(dsl, """
fh = open("data.txt", "w")
fh.write("hello")
fh.close()
print(open("data.txt").read())
print(open("./data.txt").read())
print(open("sub/../data.txt").read())
print(open("PA:/data.txt").read())
print(open("pa:/data.txt").read())
""")
	_check("bare / . / .. normalize to main dir", out == "hello\nhello\nhello\nhello\nhello\n", out)

	var out2 = _run_ok(dsl, """
try:
    open("nope.txt")
except FileNotFoundError as e:
    print(e)
try:
    open("missing_dir/nope.txt", "w")
except OSError as e:
    print(type(e).__name__)
""")
	_check("missing file keeps CPython message", out2 == "[Errno 2] No such file or directory: 'nope.txt'\nOSError\n", out2)

	# cleanup 不删命名盘符目录
	dsl.cleanup()
	_check("named drive persists after cleanup", DirAccess.dir_exists_absolute(root))
	dsl.free()


## 二. 路径收敛反向: 他盘符前缀 / 越出盘根 / 绝对形态一律按文件不存在拒绝
func _probe_path_negative() -> void:
	print("[group] path convergence (negative)")
	var dsl = _new_drive("PB", true)
	var cases = [
		["ZZ:/data.txt", "foreign drive prefix"],
		["../data.txt", "dotdot beyond root"],
		["a/../../data.txt", "dotdot beyond root nested"],
		["/abs.txt", "posix absolute form"],
		["res://data.txt", "res protocol form"],
		["user://data.txt", "user protocol form"],
	]
	for c in cases:
		var out = _run_ok(dsl, """
try:
    open("%s")
except FileNotFoundError as e:
    print("FN", e)
except Exception as e:
    print("OTHER", type(e).__name__)
""" % c[0])
		_check("reject: " + c[1], out.begins_with("FN [Errno 2] No such file or directory"), out)
	dsl.free()


## 三. 子目录主文件: write 文件模式落盘, 主文件位置随路径, .. 回到盘根可用
func _probe_subdir_main() -> void:
	print("[group] subdir main via write path mode")
	var root := _drive_root("PC")
	var dsl = _new_drive("PC", true)
	_place(root, "root.txt", "at-root")
	_place(root, "sub/x.txt", "in-sub")

	var ok = dsl.write_dsl_script("""
print(open("x.txt").read())
print(open("PC:/root.txt").read())
print(open("../root.txt").read())
try:
    open("../../root.txt")
except FileNotFoundError:
    print("escaped")
""", "sub/main.py")
	_check("write path mode returns true", ok)
	dsl.run()
	var out = dsl.print_output if dsl.state != dsl.State.ERROR else "<error> " + dsl.report.last_error
	_check("subdir main dir + root escape up one", out == "in-sub\nat-root\nat-root\nescaped\n", out)
	_check("main file written into drive", FileAccess.file_exists(root + "/sub/main.py"))
	_check("__file__ injected", dsl._script_path == "PC:/sub/main.py", dsl._script_path)
	dsl.free()


## 四. open / import / load 组合: 盘内预放模块, sys.path 追加, 模块内 open 统一基准
func _probe_import_combo() -> void:
	print("[group] open + import + load combo")
	var root := _drive_root("PD")
	var dsl = _new_drive("PD", true)
	_place(root, "lib/libmod.py", "VALUE = 41\nDATA = open(\"moddata.txt\").read()\n")
	_place(root, "moddata.txt", "shared-base")
	_place(root, "main.py", "import sys\nsys.path.append(\"lib\")\nimport libmod\nprint(libmod.VALUE + 1)\nprint(libmod.DATA)\nprint(libmod.__file__)\n")

	_check("load_dsl_script from drive", dsl.load_dsl_script("main.py"))
	dsl.run()
	var out = dsl.print_output if dsl.state != dsl.State.ERROR else "<error> " + dsl.report.last_error
	_check("import in drive + unified open base", out == "42\nshared-base\nPD:/lib/libmod.py\n", out)

	# 主文件在子目录时: 裸 sys.path 项与 open 以子目录为基准, 盘符前缀直达盘根
	_place(root, "sub/inner.txt", "inner")
	_place(root, "sub/innermod.py", "Y = 7\n")
	var ok = dsl.write_dsl_script("""
import sys
sys.path.append(".")
import innermod
print(open("inner.txt").read())
print(innermod.Y)
""", "sub/main2.py")
	_check("load subdir main", ok)
	dsl.run()
	var out2 = dsl.print_output if dsl.state != dsl.State.ERROR else "<error> " + dsl.report.last_error
	_check("subdir main: bare sys.path entry follows main dir", out2 == "inner\n7\n", out2)
	dsl.free()


## 五. load_dsl_script 的宿主侧错误通道: 空盘符 / 越界 / 不存在返回 false 并 push_error
func _probe_load_and_write() -> void:
	print("[group] load_dsl_script host-side errors")
	var plain = _pygds_script.new()
	_check("load on empty drive refused", not plain.load_dsl_script("main.py"))
	var ok1 = plain.write_dsl_script("print(1)", "main.py")
	_check("write path mode without drive refused", not ok1)
	plain.free()

	var dsl = _new_drive("PE", false)
	_check("load missing file refused", not dsl.load_dsl_script("m.py"))
	_place(_drive_root("PE"), "m.py", "print('from disk')\n")
	_check("load without access reads file", dsl.load_dsl_script("m.py"))
	dsl.run()
	_check("loaded script ran", dsl.print_output == "from disk\n", dsl.print_output)
	_check("load missing file refused (after place)", not dsl.load_dsl_script("ghost.py"))
	_check("load out-of-drive refused", not dsl.load_dsl_script("../ghost.py"))
	var ok2 = dsl.write_dsl_script("print(2)", "gen.py")
	_check("write path mode without path_access refused", not ok2)
	dsl.free()

	var dsl2 = _new_drive("PF", true)
	_check("load out-of-drive refused (access on)", not dsl2.load_dsl_script("../ghost.py"))
	dsl2.free()


## 六. path_access = false 四象限: open 与用户 import 拒绝, 内置 import 不受影响
func _probe_no_access() -> void:
	print("[group] path_access=false quadrant")
	var dsl = _new_drive("PG", false)
	_place(_drive_root("PG"), "data.txt", "hidden")
	_place(_drive_root("PG"), "hid.py", "X = 1\n")
	var out = _run_ok(dsl, """
import math
try:
    open("data.txt")
except FileNotFoundError as e:
    print("open:", e)
try:
    import hid
except ImportError as e:
    print("imp:", e)
print(math.floor(1.9))
""")
	_check("no access: open/import refused, builtin import fine",
		out == "open: [Errno 2] No such file or directory: 'data.txt'\nimp: No module named 'hid'\n1\n", out)
	dsl.free()


## 七. close-free 时序: 未 close 的文件随 cleanup 释放, 随机盘符目录被删除, 实例可重建
func _probe_close_free_timing() -> void:
	print("[group] close-free timing (random drive)")
	var dsl = _pygds_script.new("", true)
	var name: String = dsl._drive_letter
	var ok_name := name.begins_with("_") and name.length() == 1 + int(_pygds_script.RANDOM_DRIVE_LENGTH)
	for i in range(1, name.length()):
		if name[i] < "A" or name[i] > "Z":
			ok_name = false
	_check("random drive name is _-prefixed letters", ok_name, name)
	var rroot := _drive_root(name)
	_check("random drive dir created", DirAccess.dir_exists_absolute(rroot), rroot)
	var out = _run_ok(dsl, """
fh = open("left_open.txt", "w")
fh.write("x")
print("written", fh.closed)
sf = open("closed.txt", "w")
sf.write("x")
sf.close()
print(open("closed.txt").read())
print(open("%s:/closed.txt").read())
""" % name)
	# 同轮运行内覆盖裸路径写读与临时盘符前缀形态; left_open 句柄保持打开至脚本结束
	_check("file left open runs + prefix form", out == "written False\nx\nx\n", out)
	dsl.cleanup()
	_check("random sandbox deleted after cleanup", not DirAccess.dir_exists_absolute(rroot))
	# 重建: cleanup 后重新 write + run, 目录惰性重建, 上一轮文件已随目录删除
	var out2 = _run_ok(dsl, "print(open('left_open.txt').read())")
	_check("instance reusable after cleanup", out2.contains("No such file or directory: 'left_open.txt'"), out2)
	dsl.free()
	# 占用注册表: 40 个并存的随机盘符互不相同 (多字母组合无数量上限), 全部释放后注册表清空
	var live := []
	for i in range(40):
		live.append(_pygds_script.new("", true))
	var names := {}
	var dup := false
	for d in live:
		var l: String = d._drive_letter
		if names.has(l):
			dup = true
		names[l] = true
	_check("40 concurrent random drives unique", not dup and names.size() == 40, str(names.size()))
	for d in live:
		d.cleanup()
		d.free()
	_check("claims released after free", _pygds_script._drive_claims.is_empty(), str(_pygds_script._drive_claims))
	var late = _pygds_script.new("", true)
	_check("assignment works after release", late._drive_letter != "")
	late.cleanup()
	late.free()


## 八. 多实例: 共享命名盘符允许, 随机盘符互不相同且删除互不影响
func _probe_multi_random() -> void:
	print("[group] multi instance shared named drive")
	var a = _new_drive("PH", true)
	var b = _new_drive("PH", true)
	var out = _run_ok(a, "open('shared.txt', 'w').write('AB')")
	_check("A writes shared file", out == "")
	var out2 = _run_ok(b, "print(open('shared.txt').read())")
	_check("B reads shared file", out2 == "AB\n", out2)
	var r1 = _pygds_script.new("", true)
	var r2 = _pygds_script.new("", true)
	_check("random names differ", r1._drive_letter != r2._drive_letter)
	# 临时盘符与命名盘符命名空间互斥: 临时盘符恒为 _ 前缀, 其 cleanup 删除
	# 在构造上不可能波及命名盘符, 命名盘符也无法占用 _ 前缀名字
	var named = _new_drive("PI", true)
	_run_ok(named, "open('keep.txt', 'w').write('KEEP')")
	var tmp = _pygds_script.new("", true)
	_run_ok(tmp, "open('tmp.txt', 'w').write('T')")
	_check("temp name always _-prefixed", tmp._drive_letter.begins_with("_"), tmp._drive_letter)
	var impostor = _pygds_script.new(tmp._drive_letter, true)
	_check("named cannot claim a _-prefixed drive", impostor._init_rejected != "")
	impostor.free()
	tmp.cleanup()
	var out_keep = _run_ok(named, "print(open('keep.txt').read())")
	_check("named drive data survives temp cleanup", out_keep == "KEEP\n", out_keep)
	a.free()
	b.free()
	named.free()
	tmp.free()
	r1.free()
	r2.cleanup()
	r2.free()


## 九. 非法盘符: push_error 拒绝实例化, run 进入 ERROR
func _probe_invalid_drive() -> void:
	print("[group] invalid drive letters")
	for bad in ["C1", "AB!", "A B", "C:", "_ABC"]:
		var dsl = _pygds_script.new(bad, true)
		_check("rejected: " + bad, dsl._init_rejected != "" and dsl._drive_letter == "")
		dsl.run()
		_check("run on rejected instance errors", dsl.state == dsl.State.ERROR)
		dsl.free()
	var ok_dsl = _pygds_script.new("ab", true)
	_check("lowercase normalized to upper", ok_dsl._drive_letter == "AB")
	ok_dsl.free()
