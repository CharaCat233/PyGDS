extends Control
## PyGDS 挂起系统 Demo: 回合制战斗模拟器
##
## 演示三种挂起方式:
##   1. sleep(n)             — SLEEPING 挂起 (Timer 延时后自动恢复)
##   2. wait_for_confirm()   — WAITING 挂起 (等待用户点击按钮)
##   3. play_animation(...)  — WAITING 挂起 + on_resume 回调
##
## 在 Godot 编辑器中打开 demo/demo.tscn 场景即可运行
##
## 架构: 事件驱动, 不用 _process() 轮询, 而是通过 Timer 信号
## 和按钮点击驱动执行, 真实展示挂起系统的异步特性

const PYGDS_PATH = "res://pygds.gd"

@onready var _output: RichTextLabel = $Panel/VBoxContainer/SplitContainer/LeftPanel/LeftVBox/OutputLabel
@onready var _print_output: RichTextLabel = $Panel/VBoxContainer/SplitContainer/RightPanel/RightVBox/PrintOutput
@onready var _run_button: Button = $Panel/VBoxContainer/ButtonContainer/RunButton
@onready var _continue_button: Button = $Panel/VBoxContainer/ButtonContainer/ContinueButton

var _dsl: PyGDS
var _print_offset: int = 0


func _ready():
	_run_button.pressed.connect(_start_demo)
	_continue_button.pressed.connect(_on_continue)


func _start_demo():
	_output.clear()
	_print_output.clear()
	_run_button.disabled = true
	_continue_button.visible = false
	_print_offset = 0
	
	_append("[color=cyan]========== 初始化 PyGDS ==========[/color]")
	_setup_dsl()
	_write_combat_script()
	
	_append("[color=cyan]========== 开始执行 ==========[/color]")
	_step_execute()


func _setup_dsl():
	_dsl = load(PYGDS_PATH).new()
	
	# SLEEPING 恢复回调: Timer 超时后 run() 自动调用, 回调仅更新 UI
	# (_on_sleeping_resumed 不调用 run(), 避免与 Timer 的 run() 重复执行)
	_dsl._sleeping_resume_callback = func():
		call_deferred("_on_sleeping_resumed")
	
	# 预设代码: 战斗常量与工具函数
	_dsl.set_preset_script("""
MAX_HP = 100
CRIT_MULTI = 2.0

def hp_bar(current, maximum):
    return "[" + "=" * current + " " * (maximum - current) + "]"
""")
	
	# API: WAITING 挂起 — 等待玩家确认
	_dsl.register_api_pair("wait_for_confirm", func(_args: Array, _kwargs: Dictionary):
		_append("[color=orange][WAITING] wait_for_confirm() — 挂起，等待玩家点击「继续」...[/color]")
		_dsl.request_suspend_waiting(func():
			_append("[color=orange][WAITING] 恢复后继续执行[/color]")
		)
	)
	
	# API: WAITING 挂起 (带 on_resume 回调) — 播放动画
	_dsl.register_api_pair("play_animation", func(args: Array, _kwargs: Dictionary):
		var character_name: String = args[0].value
		_append("[color=magenta][WAITING+回调] play_animation('%s') — 开始播放动画，挂起...[/color]" % character_name)
		_dsl.request_suspend_waiting(func():
			_append("[color=magenta][WAITING+回调] on_resume 回调触发: 动画 '%s' 播放完毕![/color]" % character_name)
		)
	)
	
	# API: 攻击 (无挂起)
	_dsl.register_api_pair("attack", func(args: Array, _kwargs: Dictionary):
		var source: String = args[0].value
		var target: String = args[1].value
		var damage: int = args[2].value
		var is_crit: bool = args.size() > 3 and args[3].value
		var label = "%s 攻击 %s，造成 %d 点伤害" % [source, target, damage]
		if is_crit:
			label += " [color=red][暴击!][/color]"
		_append("[color=green][API] %s[/color]" % label)
	)


func _write_combat_script():
	_dsl.write_dsl_script("""
# ===== 回合制战斗脚本 =====
print("战斗开始!")

# 第一回合: 被动挂起延时
print("--- 第一回合 ---")
print("勇者准备攻击...")
sleep(1.0)
attack("勇者", "史莱姆", 30)
sleep(1.0)
print("史莱姆反击!")
attack("史莱姆", "勇者", 15)

# 主动挂起: 等待确认
print("")
print("--- 回合间隙 ---")
wait_for_confirm()

# 第二回合: 暴击演示
print("")
print("--- 第二回合 ---")
print("勇者蓄力...")
sleep(1.5)
attack("勇者", "史莱姆", 60, True)
print("史莱姆被击败了!")

# 主动挂起: 等待确认
print("")
wait_for_confirm()

# 第三回合: 动画演示 (主动挂起 + on_resume)
print("")
print("--- 第三回合 ---")
print("勇者使用必杀技!")
play_animation("终极斩")
print("")
print("战斗结束!")
""")


## 执行一步 DSL, 由 _start_demo() 或 _on_continue() 调用
func _step_execute():
	if _dsl == null:
		return

	var state = _dsl.run()
	_handle_state(state)


## SLEEPING 恢复后的 UI 更新 (不调用 run(), 因为 Timer 已调用)
func _on_sleeping_resumed():
	_handle_state(_dsl.state)


## 统一处理执行后的状态, 更新 UI 并重新注册 SLEEPING 回调
func _handle_state(state: int):
	_flush_dsl_output()
	# 重新注册回调, 确保后续 sleep() 也能触发 UI 更新
	_dsl._sleeping_resume_callback = func():
		call_deferred("_on_sleeping_resumed")
	
	match state:
		PyGDS.State.SUSPENDED_SLEEPING:
			# Timer 已由 request_suspend_sleeping 创建, 等待超时信号触发 run()
			pass
			
		PyGDS.State.SUSPENDED_WAITING:
			_continue_button.visible = true  # 等待用户点击「继续」
			
		PyGDS.State.RUNNING:
			_append("[color=red][WARNING] 意外的 RUNNING 状态[/color]")
			_demo_finished()
			
		PyGDS.State.FINISHED:
			_demo_finished()
			
		PyGDS.State.ERROR:
			_append("[color=red][ERROR] %s[/color]" % _dsl.report.last_error)
			_demo_finished()


func _on_continue():
	_continue_button.visible = false
	_dsl.state = PyGDS.State.RUNNING
	_step_execute()


func _demo_finished():
	_append("")
	_append("[color=cyan]========== 执行完毕 ==========[/color]")
	_append("[color=gray]三种挂起方式均已演示:[/color]")
	_append("[color=gray]  1. SLEEPING: sleep(n) — Timer 延时后自动恢复[/color]")
	_append("[color=gray]  2. WAITING: wait_for_confirm() — 等待用户点击「继续」[/color]")
	_append("[color=gray]  3. WAITING+回调: play_animation() — 恢复时自动触发 on_resume[/color]")
	_run_button.disabled = false


func _flush_dsl_output():
	var full = _dsl.print_output
	if full.length() > _print_offset:
		_print_output.append_text(full.substr(_print_offset))
		_print_offset = full.length()


func _append(text: String):
	_output.append_text(text + "\n")
