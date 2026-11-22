# 职责: ExceptionGroup 的 derive 与 args/repr 形态 (成员列表与嵌套组型)
# 比对: same_output

g = ExceptionGroup("gg", [ValueError("v"), TypeError("t")])
print(repr(g))
print(g.args)
print(g.exceptions)
sub = g.derive([KeyError("k")])
print(repr(sub), sub.args)
try:
    g.derive(5)
except TypeError as err:
    print("derive-seq:", err)
try:
    g.derive([])
except ValueError as err:
    print("derive-empty:", err)
try:
    g.derive([1])
except ValueError as err:
    print("derive-member:", err)
bg = BaseExceptionGroup("b", [KeyboardInterrupt()])
print(repr(bg.derive([ValueError("v")])))
print(repr(ExceptionGroup("q'q", [ValueError()])))
