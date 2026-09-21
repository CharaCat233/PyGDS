@tool
extends EditorPlugin

## PyGDS 编辑器插件 [br]
## 在 Project > Tools 菜单提供「Run PyGDS Script...」动作: [br]
## 通过文件对话框选择一个 .py 文件, 使用项目根目录的 pygds.gd 解释器执行, [br]
## 并将 print 输出打印到编辑器控制台 [br]
## 依赖: 项目根目录存在 pygds.gd (单文件集成方式)

const PYGDS_PATH := "res://pygds.gd"

## 文件对话框实例 (懒加载)
var _dialog: EditorFileDialog = null


func _enter_tree() -> void:
	add_tool_menu_item("Run PyGDS Script...", _on_run_script)


func _exit_tree() -> void:
	remove_tool_menu_item("Run PyGDS Script...")
	if _dialog != null and is_instance_valid(_dialog):
		_dialog.queue_free()
		_dialog = null


## 弹出文件选择对话框
func _on_run_script() -> void:
	if _dialog == null or not is_instance_valid(_dialog):
		_dialog = EditorFileDialog.new()
		_dialog.title = "Run PyGDS Script"
		_dialog.file_mode = EditorFileDialog.FILE_MODE_OPEN_FILE
		_dialog.access = EditorFileDialog.ACCESS_FILESYSTEM
		_dialog.add_filter("*.py", "Python script")
		_dialog.file_selected.connect(_on_file_selected)
		EditorInterface.get_base_control().add_child(_dialog)
	_dialog.popup_centered_ratio(0.5)


## 选择文件后, 用 PyGDS 执行并输出结果 [br]
## [param path] 选中的 .py 文件路径
func _on_file_selected(path: String) -> void:
	if not FileAccess.file_exists(PYGDS_PATH):
		push_error("PyGDS: 未找到 %s, 请将 pygds.gd 复制到项目根目录" % PYGDS_PATH)
		return
	var fa := FileAccess.open(path, FileAccess.READ)
	if fa == null:
		push_error("PyGDS: 无法打开文件 %s" % path)
		return
	var source := fa.get_as_text()
	fa.close()

	var dsl = load(PYGDS_PATH).new()
	dsl.set_debug_mode(true)
	dsl.write_dsl_script(source)
	dsl.run()
	if dsl.report.has_error:
		push_error("PyGDS: %s" % dsl.report.last_error)
	if dsl.print_output != "":
		print("PyGDS output:\n%s" % dsl.print_output)
	dsl.free()
