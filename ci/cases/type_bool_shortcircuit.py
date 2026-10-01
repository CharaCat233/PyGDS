# 职责: and/or 短路求值与操作数返回、真值判定
# 比对: same_output


calls = []


def side(v):
    calls.append(v)
    return v


print(side(1) or side(2))
print(calls)
calls.clear()
print(side(0) or side(2))
print(calls)
calls.clear()
print(side(1) and side(2))
print(calls)
calls.clear()
print(side(0) and side(2))
print(calls)
calls.clear()

# 短路用于防错
n = 0


class Guard:
    def check(self):
        global n
        n += 1
        return "checked"


g = None
r = g is not None and g.check()
print(r, n)
g = Guard()
r = g is not None and g.check()
print(r, n)

# 返回操作数本身
print([] or "fallback", "x" or "y", 0 and "never", "a" and "b")
print(3 or 5, "" or 0 or [] or "first-truthy")

# not 与比较不受影响
print(not (1 and 0), 1 < 2 and 2 < 3)

# 布尔上下文外的真值
results = []
for v in [None, 0, "", [], "a", [1], 5]:
    if v and v != "a":
        results.append(v)
print(results)
