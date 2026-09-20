extends Node2D


var dsl: PyGDS = PyGDS.new()

func _ready() -> void:
	dsl.set_debug_mode(true)
	dsl.write_dsl_script("""

def a():
    print("a1")
    b()
    print("a2")

def b():
    print("b1")
    sleep(1)
    print("b2")


a()

""")
	dsl.run()
