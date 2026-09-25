# 用户类真值判定测试: __bool__ / __len__ 参与 bool() 与真值语境

# === __bool__ 决定真值 ===
class F:
    def __bool__(self):
        return False


class T:
    def __bool__(self):
        return True


print("bool false:", bool(F()))
print("bool true:", bool(T()))
if F():
    print("F truthy")
else:
    print("F falsy")
if T():
    print("T truthy")
else:
    print("T falsy")

# === __len__ 回退 (无 __bool__ 时以非 0 为真) ===
class E:
    def __len__(self):
        return 0


class N:
    def __len__(self):
        return 3


print("len zero:", bool(E()))
print("len three:", bool(N()))
while E():
    print("E loop body")

# === __bool__ 优先于 __len__ (CPython 的判定优先级) ===
class Both:
    def __bool__(self):
        return True

    def __len__(self):
        return 0


print("bool priority:", bool(Both()))

# === 真值用于 not / and / or / 三目 ===
print("not:", not F(), not T())
print("and:", T() and "yes", F() and "no")
print("or:", F() or "fallback", T() or "unused")
print("ternary:", "a" if F() else "b", "c" if T() else "d")
print("any:", any([F(), F()]), any([F(), T()]))
print("all:", all([T(), T()]), all([T(), F()]))
print("sum-ish:", len([x for x in [F(), T()] if x]))

# === 两种 dunder 都未定义时保持默认真 ===
class Plain:
    pass


print("plain:", bool(Plain()))

# === 内置类型的真值不受影响 ===
print("builtin:", bool([]), bool([0]), bool(""), bool("x"))
print("builtin2:", bool({}), bool({1: 2}), bool(set()), bool(0), bool(1))
print("builtin3:", bool(()), bool((1,)), bool(frozenset()), bool(b""), bool(b"x"))
print("builtin4:", bool(range(0)), bool(range(3)), bool(range(3, 0)), bool(range(0, 3, -1)))
print("views:", bool({}.keys()), bool({1: 2}.keys()))
print("views2:", bool({}.values()), bool({1: 2}.values()))
print("truthy-objs:", bool(print), bool(int), bool(len), bool(max(1, 2)))
