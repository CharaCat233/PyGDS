# 职责: eval / exec / compile 动态求值与 globals / locals / vars / sys.modules (I1-32): 表达式求值与语句执行 / code 对象元数据 / globals 实参快照写回 / globals() 活视图与函数内 locals 快照 / vars 的实例字典 / 动态代码顶层禁挂起 (exec 内定义的函数体挂起正常)
# 比对: same_output
# 锚定: CPython 3.12
import sys


def t(label, fn):
    try:
        print(label + ":", repr(fn()))
    except Exception as e:
        print(label, type(e).__name__, ":", e)


t("eval", lambda: eval("1 + 2"))
t("eval_var", lambda: eval("x + 1", {"x": 5}))
t("eval_multi", lambda: eval("1; 2"))
t("eval_assign", lambda: eval("a = 1"))
t("exec_stmt", lambda: exec("y = 7"))
d = {}
t("exec_dict", lambda: (exec("q = 9", d), d.get("q")))
t("compile", lambda: str(compile("1+1", "<s>", "eval")).split("at ")[0])
t("eval_code", lambda: eval(compile("3+4", "<s>", "eval")))
c = compile("1", "<x>", "eval")
t("code_repr", lambda: str(c).split("at ")[0])
t("code_meta", lambda: (c.co_name, c.co_filename, c.co_firstlineno))
t("compile_bad_mode", lambda: compile("1", "<s>", "nope"))
t("compile_exec_eval", lambda: eval(compile("a=1", "<s>", "exec")))
g = {"v": 10}
t("exec_writes", lambda: (exec("v = v + 1", g), g["v"]))


def f():
    lv = 3
    return list(locals().keys())


t("locals_keys", f)
t("globals_is_dict", lambda: isinstance(globals(), dict))
globals()["gv"] = 42
t("globals_write", lambda: gv)


class A:
    m = 1


t("vars_obj", lambda: vars(A()))
t("vars_none", lambda: vars(5))
t("sys_modules_in", lambda: "sys" in sys.modules)
t("sys_modules_get", lambda: type(sys.modules["sys"]).__name__)
t("eval_uses_builtins", lambda: eval("len([1,2])"))


# exec 定义的函数 / 生成器被主脚本调用时可正常挂起 (函数体在语句键体系内)
exec("""
import time


def slow(v):
    time.sleep(0)
    return v * 2


def g():
    for i in [1, 2]:
        time.sleep(0)
        yield i
""")
print("slow:", slow(3))
print("gen:", list(g()))
