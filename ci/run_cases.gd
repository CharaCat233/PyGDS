extends SceneTree

## PyGDS 行为一致性双端运行器
##
## 对 ci/cases/ 下每个用例文件:
##  1. 经 ci/_pyrun.py 垫片现场运行 CPython, 从结果 JSON 文件取回 stdout/stderr/退出码
##  2. 在本进程内运行 PyGDS, 取 print_output 与 report 错误通道
##  3. 按用例头注声明的「比对」语义判定, 全部用例结束后输出汇总并决定退出码
##
## 用例头注元数据 (文件顶部行首注释, 缺省比对值为 same_output, 键中英并存):
##  # duty: <一句话职责说明>
##  # compare: same_output | same_exception | same_error | diverge
##  # skip: <原因>             (可选, 声明后跳过不参与判定, 值中 " # " 起为尾注释被剥离)
##
## 判定语义:
##  same_output    双端均正常完成, stdout 归一化后逐字一致
##  same_exception 双端均报错, 异常类名精确一致 (不支持子类容差)
##  same_error     双端均报错, 类名与消息均一致 (剥离行号尾缀并归一化后)
##  diverge        已文档化的既定分歧, 仅要求双端「报错与否」状态一致
##  任何「单边报错」一律判失败, 与声明的比对值无关
##
## 归一化 (双端同规则): CRLF -> LF; 对象默认 repr 的 " at 0x...>" 与
## "<__main__." 前缀 (CPython 的对象 repr 带内存地址与模块限定, PyGDS 为简化形式)
##
## 用法:
##  godot --headless --path . --script res://ci/run_cases.gd
##  godot --headless --path . --script res://ci/run_cases.gd -- --filter=math
##
## 文件类用例 (open / 用户 import) 在盘符沙箱内运行: PyGDS 实例化时传入盘符 CI 并
## 开启 path_access, 裸相对路径收敛到 user://<base_path>/CI/; CPython 垫片以盘符根的
## 真实路径为工作目录, 双端的裸相对路径由此落到同一物理目录 (夹具每轮重放)

const CASES_DIR := "res://ci/cases"

## 文件类用例使用的沙箱盘符 (仅字母)
const DRIVE_LETTER := "CI"

## 头注键别名: 中英并存, 归一化为英文键 (解析器只认英文键)
const HEADER_KEY_ALIASES := {
	"duty": "duty", "职责": "duty",
	"compare": "compare", "比对": "compare",
	"anchor": "anchor", "锚定": "anchor",
	"ref": "ref", "关联": "ref",
	"lines": "lines", "行号": "lines",
	"skip": "skip", "跳过": "skip",
}
const PYRUN_PATH := "res://ci/_pyrun.py"
const RESULT_USER := "user://pyrun_result.json"
const MAX_PUMP := 2000

var passed_count := 0
var failed_count := 0
var skipped_count := 0

var _re_addr: RegEx
var _re_main: RegEx
var _re_parse_err: RegEx
var _re_cpline: RegEx

## pygds.gd 脚本引用 (实例化传盘符与夹具清盘复用)
var _pygds_script: GDScript = null
## 沙箱盘符根的真实路径 (CPython 垫片工作目录)
var _drive_root_os: String = ""


func _init() -> void:
	_re_addr = RegEx.create_from_string(" at 0x[0-9a-fA-F]+>")
	_re_main = RegEx.create_from_string("<__main__\\.")
	# PyGDS 解析器未对齐文案的行首格式, 本质仍是 SyntaxError, 提取时归一到
	# "SyntaxError: " 前缀, 使类名比对与 CPython 对齐 (消息比对不受影响, 未对齐文案的用例应声明 same_exception 直至文案对齐后升级)
	_re_parse_err = RegEx.create_from_string("^Line \\d+, Column \\d+: ")
	# CPython traceback 帧: File "...", line N
	_re_cpline = RegEx.create_from_string("File \"[^\"]*\", line (\\d+)")

	var filter := ""
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--filter="):
			filter = arg.substr("--filter=".length())

	var python_cmd := _detect_python()
	if python_cmd == "":
		print("ERROR: 未找到可用的 CPython (尝试过 python3 / python)")
		quit(1)
		return

	# 盘符沙箱准备: 清盘后重放夹具, 保证文件类用例的确定性
	_pygds_script = load("res://pygds.gd")
	var base: String = _pygds_script.base_path
	while base.begins_with("/"):
		base = base.substr(1)
	while base.ends_with("/"):
		base = base.substr(0, base.length() - 1)
	var drive_root := "user://"
	if base != "":
		drive_root += base + "/"
	drive_root += DRIVE_LETTER
	_pygds_script._remove_dir_recursive(drive_root)
	var fixture_src := CASES_DIR + "/files"
	var fixture_dst := drive_root + "/ci/cases/files"
	DirAccess.make_dir_recursive_absolute(fixture_dst)
	var fdir := DirAccess.open(fixture_src)
	if fdir == null:
		print("ERROR: 夹具目录不存在: %s" % fixture_src)
		quit(1)
		return
	fdir.list_dir_begin()
	var fname = fdir.get_next()
	while fname != "":
		if not fdir.current_is_dir() and not fname.begins_with("."):
			DirAccess.copy_absolute(fixture_src + "/" + fname, fixture_dst + "/" + fname)
		fname = fdir.get_next()
	fdir.list_dir_end()
	_drive_root_os = ProjectSettings.globalize_path(drive_root)

	var dir := DirAccess.open(CASES_DIR)
	if dir == null:
		print("ERROR: 用例目录不存在: %s" % CASES_DIR)
		quit(1)
		return

	var case_names: Array[String] = []
	for f in dir.get_files():
		if f.ends_with(".py") and not f.begins_with("_"):
			case_names.append(f.get_basename())
	case_names.sort()

	print("=".repeat(60))
	print("PyGDS Behavior Runner (dual-end)")
	print("cases: %d | python: %s | drive: %s" % [case_names.size(), python_cmd, _drive_root_os])
	print("=".repeat(60))

	for case_name in case_names:
		if filter != "" and not case_name.contains(filter):
			continue
		_run_case(case_name, python_cmd)

	print("")
	print("=".repeat(60))
	print("Results: %d passed, %d failed, %d skipped" % [passed_count, failed_count, skipped_count])
	print("=".repeat(60))

	if failed_count > 0:
		print("SOME TESTS FAILED!")
		quit(1)
	else:
		print("ALL TESTS PASSED!")
		quit(0)


## 探测可用的 CPython 命令 (Windows 先 python, ubuntu 先 python3)
func _detect_python() -> String:
	var candidates := ["python3", "python"]
	if OS.get_name() == "Windows":
		candidates = ["python", "python3"]
	for cmd in candidates:
		var out := []
		if OS.execute(cmd, PackedStringArray(["--version"]), out, false, false) == 0:
			return cmd
	return ""


func _run_case(case_name: String, python_cmd: String) -> void:
	var path := CASES_DIR + "/" + case_name + ".py"
	var source := _read_file(path)
	var meta := _parse_header(source)

	if meta.has("skip"):
		print("  [SKIP] %s: %s" % [case_name, meta["skip"]])
		skipped_count += 1
		return

	# CPython 侧: 垫片执行, 结果经 JSON 文件取回
	var result_os_path := OS.get_user_data_dir() + "/pyrun_result.json"
	if FileAccess.file_exists(RESULT_USER):
		DirAccess.remove_absolute(result_os_path)
	var args := PackedStringArray([
		ProjectSettings.globalize_path(PYRUN_PATH),
		ProjectSettings.globalize_path(path),
		result_os_path,
		_drive_root_os,
	])
	OS.execute(python_cmd, args, [], false, false)

	if not FileAccess.file_exists(RESULT_USER):
		_fail(case_name, "CASE-ERR", "CPython 垫片未产出结果文件 (命令: %s)" % python_cmd)
		return
	var parsed = JSON.parse_string(_read_file(RESULT_USER))
	if not parsed is Dictionary:
		_fail(case_name, "CASE-ERR", "垫片结果 JSON 解析失败")
		return

	var code_val = parsed.get("code", 1)
	var cp_errored: bool = code_val == null or int(code_val) != 0
	var cp_stdout: String = parsed.get("stdout", "")
	var cp_error := _cp_last_error(parsed.get("stderr", ""))

	# PyGDS 侧: 进程内执行, 推进挂起直至结束
	var dsl = _pygds_script.new(DRIVE_LETTER, true)
	if dsl == null:
		_fail(case_name, "CASE-ERR", "pygds.gd 加载失败 (解析错误?)")
		return
	dsl.set_debug_mode(false)
	dsl.write_dsl_script(source)
	dsl.run()
	var pump := 0
	while dsl.state == dsl.State.SUSPENDED_SLEEPING and pump < MAX_PUMP:
		pump += 1
		dsl.state = dsl.State.RUNNING
		dsl.run()
	if pump >= MAX_PUMP:
		printerr("  [WARN] %s: 挂起恢复超过 %d 次, 可能存在循环挂起" % [case_name, MAX_PUMP])
	if dsl.state == dsl.State.RUNNING:
		# run() 未走到终态判定即返回: 引擎 VM 调用栈上限 ("Stack overflow") 会硬中止
		# GDScript 调用链, interpret 的终态判定整体被跳过; 视作用例环境错误而非双端差异
		_fail(case_name, "CASE-ERR", "解释器未达终态 (疑似引擎 VM 调用栈硬中止, 见已知问题清单 P2)")
		return
	# 错误信号 = State.ERROR: 解析期错误在 write_dsl_script 后由 run() 置位
	# 运行期未捕获异常在顶层 fatal_error 确认时会清掉 report.has_error,
	# 但 report.last_error 保留完整消息, 两种路径都用它取错误文本
	var pg_errored: bool = dsl.state == dsl.State.ERROR
	var pg_error: String = ""
	if pg_errored and dsl.report != null:
		pg_error = dsl.report.last_error
		var m := _re_parse_err.search(pg_error)
		if m != null:
			pg_error = "SyntaxError: " + pg_error.substr(m.get_end())
	var pg_stdout: String = dsl.print_output
	dsl.free()

	# 判定
	var mode: String = meta.get("compare", "same_output")
	var line_check: bool = meta.get("lines", "") == "same"
	var verdict := _judge(mode, cp_errored, cp_error, pg_errored, pg_error, cp_stdout, pg_stdout, line_check, parsed.get("stderr", ""))
	if verdict["ok"]:
		# PASS 用例不逐条输出 (常态输出只保留失败条目与汇总)
		passed_count += 1
	else:
		_fail(case_name, verdict["kind"], verdict["detail"])


## 按声明的比对值判定单个用例
func _judge(mode: String, cp_errored: bool, cp_error: String, pg_errored: bool, pg_error: String, cp_stdout: String, pg_stdout: String, line_check: bool = false, cp_stderr: String = "") -> Dictionary:
	var one_sided := cp_errored != pg_errored
	match mode:
		"same_output":
			if one_sided:
				return _verdict_fail("ONESIDED", _onesided_detail(cp_errored, cp_error, pg_errored, pg_error))
			if cp_errored:
				return _verdict_fail("UNEXPECTED-ERR", "声明 same_output 但双端均报错\nCPython: %s\nPyGDS:   %s" % [cp_error, pg_error])
			if _normalize(cp_stdout) != _normalize(pg_stdout):
				return _verdict_fail("OUT", "stdout 不一致\n[CPython]\n%s\n[PyGDS]\n%s" % [_show(cp_stdout), _show(pg_stdout)])
			return {"ok": true}
		"same_exception", "same_error":
			if one_sided:
				return _verdict_fail("ONESIDED", _onesided_detail(cp_errored, cp_error, pg_errored, pg_error))
			if not cp_errored:
				return _verdict_fail("NO-ERR", "声明 %s 但双端均正常完成" % mode)
			if _error_class(cp_error) != _error_class(pg_error):
				return _verdict_fail("ERRTYPE", "异常类不一致\nCPython: %s\nPyGDS:   %s" % [cp_error, pg_error])
			if mode == "same_error":
				var cm := _normalize(_strip_line_suffix(cp_error))
				var pm := _normalize(_strip_line_suffix(pg_error))
				if cm != pm:
					return _verdict_fail("ERRMSG", "错误消息不一致\nCPython: %s\nPyGDS:   %s" % [cm, pm])
			if line_check:
				# 可选行号比对: 声明「行号: same」时核对报错行 (PyGDS "(line N)" vs CPython traceback 末帧)
				var pl := _error_line_number(pg_error)
				var cl := _cp_last_line_number(cp_stderr)
				if pl == 0 or cl == 0:
					return _verdict_fail("LINE-UNKNOWN", "行号未知 (声明 行号: same)\nCPython 末帧行: %d\nPyGDS 错误行: %s" % [cl, pg_error])
				if pl != cl:
					return _verdict_fail("LINE", "报错行号不一致\nCPython: line %d\nPyGDS: line %d" % [cl, pl])
			return {"ok": true}
		"diverge":
			if one_sided:
				return _verdict_fail("ONESIDED", _onesided_detail(cp_errored, cp_error, pg_errored, pg_error))
			return {"ok": true}
		_:
			return _verdict_fail("META", "未知比对值: %s" % mode)


func _verdict_fail(kind: String, detail: String) -> Dictionary:
	return {"ok": false, "kind": kind, "detail": detail}


func _onesided_detail(cp_errored: bool, cp_error: String, _pg_errored: bool, pg_error: String) -> String:
	if cp_errored:
		return "单边报错: CPython 报错而 PyGDS 正常完成\nCPython: %s" % cp_error
	return "单边报错: PyGDS 报错而 CPython 正常完成\nPyGDS:   %s" % pg_error


func _fail(case_name: String, kind: String, detail: String) -> void:
	print("  [FAIL] %s (%s)" % [case_name, kind])
	for line in detail.split("\n"):
		print("      " + line)
	failed_count += 1


## 解析用例头注元数据: 自文件首行起, 连续的 "# 键: 值" 注释 (空行跳过, 首个非注释行停止)
## 键中英并存 (HEADER_KEY_ALIASES), 归一化为英文键, 值中的 " # " 起为尾注释, 剥离不参与数据
func _parse_header(source: String) -> Dictionary:
	var meta := {}
	for line in source.split("\n"):
		var t := line.strip_edges()
		if t == "":
			continue
		if not t.begins_with("#"):
			break
		var body := t.substr(1).strip_edges()
		var idx := body.find(":")
		if idx > 0:
			var key: String = body.substr(0, idx).strip_edges().to_lower()
			if HEADER_KEY_ALIASES.has(key):
				key = HEADER_KEY_ALIASES[key]
			var value := body.substr(idx + 1).strip_edges()
			var comment := value.find(" # ")
			if comment != -1:
				value = value.substr(0, comment).strip_edges()
			meta[key] = value
	return meta


## CPython 错误行 = stderr 最后一个非空行 (未捕获异常的 traceback 末行)
func _cp_last_error(stderr: String) -> String:
	var lines := stderr.replace("\r\n", "\n").split("\n")
	for i in range(lines.size() - 1, -1, -1):
		var line := lines[i].strip_edges()
		if line != "":
			return line
	return ""


## 从错误行提取异常类名 (首个冒号前, 精确匹配不支持子类)
func _error_class(err_line: String) -> String:
	var line := err_line.strip_edges()
	var idx := line.find(":")
	if idx < 0:
		return line
	return line.substr(0, idx).strip_edges()


## 从 PyGDS 错误行解析 " (line N)" 的 N (无则 0)
func _error_line_number(msg: String) -> int:
	var s := msg.strip_edges()
	if s.ends_with(")"):
		var idx := s.rfind(" (line ")
		if idx >= 0:
			var num := s.substr(idx + 7, s.length() - idx - 8)
			if num.is_valid_int():
				return int(num)
	return 0


## 从 CPython stderr 解析最后一个 traceback 帧 "File ..., line N" 的 N (无则 0)
func _cp_last_line_number(stderr: String) -> int:
	var last := 0
	var from := 0
	while true:
		var m := _re_cpline.search(stderr, from)
		if m == null:
			break
		last = int(m.get_string(1))
		from = m.get_end()
	return last


## 剥离 PyGDS 附加的 " (line N)" 尾缀 (CPython 错误行不含行号)
func _strip_line_suffix(msg: String) -> String:
	var s := msg.strip_edges()
	if s.ends_with(")"):
		var idx := s.rfind(" (line ")
		if idx >= 0:
			var num := s.substr(idx + 7, s.length() - idx - 8)
			if num.is_valid_int():
				return s.substr(0, idx).strip_edges()
	return s


## 双端同规则归一化: CRLF -> LF, 对象默认 repr 的内存地址与模块限定前缀
func _normalize(text: String) -> String:
	var t := text.replace("\r\n", "\n")
	t = _re_addr.sub(t, ">", true)
	t = _re_main.sub(t, "<", true)
	return t


func _show(text: String) -> String:
	if text == "":
		return "(empty)"
	return text.replace("\r", "\\r").replace("\t", "\\t")


func _read_file(path: String) -> String:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return ""
	var text := file.get_as_text()
	file.close()
	return text
