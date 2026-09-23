import time

# 用户类魔术方法内含 sleep 时的比较与真值判定 (P1-18)
# 语句重放期间用户魔术方法的挂起必须向上传播,
# 不能回退到基类的引用比较, 也不能被当作「首次产出」反复重放


class S:
    def __init__(self, x):
        self.x = x

    def __eq__(self, o):
        time.sleep(0)
        return isinstance(o, S) and self.x == o.x


print("direct:", S(1) == S(1))
print("direct-diff:", S(1) == S(2))
print("ne:", S(1) != S(2))
print("in list:", S(1) in [S(1)])
print("repeated:", S(5) == S(5), S(5) == S(5))


class B:
    def __init__(self, v):
        self.v = v

    def __bool__(self):
        time.sleep(0)
        return self.v


print("bool-sleep:", bool(B(False)), bool(B(True)))
if B(False):
    print("B truthy")
else:
    print("B falsy")


# === 实参中构造新实例的调用: 重放时副作用只执行一次 ===
calls2 = []


class C:
    def __init__(self, k):
        self.k = k


def f(c, k):
    calls2.append(k)
    time.sleep(0)
    return c.k + k


print("fresh-arg:", f(C(1), 2), f(C(3), 4))
print("calls2:", calls2)


def h(o):
    calls2.append("h")
    time.sleep(0)
    return o


print("nested-arg:", h(C(5)).k)
print("calls2b:", len(calls2))
