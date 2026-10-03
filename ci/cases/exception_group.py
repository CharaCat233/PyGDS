# 职责: ExceptionGroup 与 BaseExceptionGroup (构造校验, 属性, str/repr, subgroup/split)
# 比对: same_output

# 构造与属性
g = ExceptionGroup("msg", [ValueError("v"), TypeError("t")])
print("type:", type(g).__name__)
print("str:", str(g))
print("exceptions:", len(g.exceptions), g.exceptions[0], g.exceptions[1])
print("message:", g.message)

bg = BaseExceptionGroup("bm", [ValueError("v"), KeyboardInterrupt()])
print("btype:", type(bg).__name__)

# 构造校验文案
try:
    ExceptionGroup("m", [KeyboardInterrupt()])
except TypeError as e:
    print("eg-base-only:", e)
try:
    ExceptionGroup("m", [])
except ValueError as e:
    print("eg-empty:", e)
try:
    ExceptionGroup(1, [ValueError("v")])
except TypeError as e:
    print("eg-msg:", e)
try:
    ExceptionGroup("m", [ValueError("v"), 5])
except ValueError as e:
    print("eg-member:", e)

# subgroup / split: 无匹配返回 None, 命中 (含单成员) 仍为组, 消息随原组
g2 = ExceptionGroup("g", [ValueError("v"), TypeError("t")])
sub = g2.subgroup(ValueError)
print("subgroup:", type(sub).__name__, str(sub))
m, r = g2.split(TypeError)
print("split:", str(m), "|", str(r))
print("subgroup-none:", g2.subgroup(KeyError))
m2, r2 = g2.split(KeyError)
print("split-nomatch:", m2, str(r2))

# except Exception 可捕获 ExceptionGroup (双继承), KeyboardInterrupt 组不被捕获
def catch_test():
    try:
        raise ExceptionGroup("g", [ValueError("v")])
    except Exception as e:
        print("except-exc:", type(e).__name__)


catch_test()

# 直接 raise 组: 未捕获形态按类型名与消息报告 (多行树为既定简化)


def raiser():
    raise ExceptionGroup("boom", [ValueError("v")])


try:
    raiser()
except ExceptionGroup as e:
    print("raise-catch:", type(e).__name__, str(e))
