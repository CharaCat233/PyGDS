# 序列拼接与重复的类型规则
# 对应 v0.5.0-alpha.5: str/list/tuple/bytes 的 + 与 * 严格按 CPython 类型规则


def concat(a, b):
    try:
        return "OK:" + repr(a + b)
    except Exception as e:
        return type(e).__name__ + ": " + str(e)


def repeat(a, b):
    try:
        return "OK:" + repr(a * b)
    except Exception as e:
        return type(e).__name__ + ": " + str(e)


# === 字符串拼接只接受 str ===
print(concat("s", "t"))
print(concat("s", 2))
print(concat("s", 2.5))
print(concat("s", [1]))
print(concat("s", (1,)))
print(concat("s", True))
print(concat("s", None))

# === 字符串重复: 次数须为整数 (bool 视为整数) ===
print(repeat("ab", 2))
print(repeat("ab", 0))
print(repeat("ab", True))
print(repeat("ab", 2.5))
print(repeat("ab", "x"))

# === 列表拼接只接受 list ===
print(concat([1], [2]))
print(concat([1], (2,)))
print(concat([1], "s"))
print(concat([1], 2))
print(repeat([1, 2], 2))
print(repeat([1], 2.5))

# === 元组拼接只接受 tuple ===
print(concat((1,), (2,)))
print(concat((1,), [2]))
print(concat((1,), "s"))
print(repeat((1, 2), 2))

# === bytes ===
print(concat(b"a", b"b"))
print(concat(b"a", "b"))
print(concat(b"a", 1))
print(repeat(b"a", 2))

# === 数值与序列的运算顺序不影响结论 ===
print(concat(1, "s"))
print(concat(1, [2]))
print(concat(1.5, "s"))
print(concat(True, "s"))
