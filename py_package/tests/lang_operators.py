# 运算符与反射运算符测试
#   覆盖:
#   - 一元正号 +x
#   - 反射版本运算符 (1 * "ab" 等序列在右的写法)
#   - 各类型的运算符支持矩阵


def bi(a, b, op):
    try:
        if op == "+":
            return "OK:" + repr(a + b)
        if op == "-":
            return "OK:" + repr(a - b)
        if op == "*":
            return "OK:" + repr(a * b)
        if op == "/":
            return "OK:" + repr(a / b)
        if op == "//":
            return "OK:" + repr(a // b)
        if op == "%":
            return "OK:" + repr(a % b)
        if op == "**":
            return "OK:" + repr(a ** b)
        if op == "<<":
            return "OK:" + repr(a << b)
        if op == ">>":
            return "OK:" + repr(a >> b)
        if op == "&":
            return "OK:" + repr(a & b)
        if op == "|":
            return "OK:" + repr(a | b)
        return "OK:" + repr(a ^ b)
    except Exception as e:
        return type(e).__name__ + ": " + str(e)


# === 数值基本运算 (含 bool 作为 int 子类) ===
print(bi(1, 2, "+"), bi(1, 2, "-"), bi(1, 2, "*"), bi(1, 2, "/"))
print(bi(7, 2, "//"), bi(7, 2, "%"), bi(2, 10, "**"))
print(bi(1, True, "+"), bi(1, True, "*"), bi(1, True, "//"))
print(bi(2, True, "**"), bi(1, True, "<<"), bi(4, True, ">>"))
print(bi(1, True, "&"), bi(1, True, "|"), bi(1, True, "^"))
print(bi(1.5, True, "+"), bi(1.5, True, "*"), bi(1.5, 2, "//"))
print(bi(1, 1.5, "/"), bi(2.0, 0.5, "**"))

# === 反射版本: 序列在右侧 ===
print(bi(1, "ab", "*"), bi(2, [1], "*"), bi(3, (1,), "*"), bi(2, b"x", "*"))
print(bi(True, "ab", "*"), bi(False, "ab", "*"))
print(bi(2, "ab", "*"), bi(2, [1, 2], "*"))

# === 序列自身在左侧 ===
print(bi("ab", 2, "*"), bi([1], 2, "*"), bi((1,), 2, "*"), bi(b"x", 2, "*"))
print(bi("ab", True, "*"), bi([1], False, "*"))

# === 序列拼接只接受同类型 ===
print(bi("a", "b", "+"), bi([1], [2], "+"), bi((1,), (2,), "+"), bi(b"a", b"b", "+"))
print(bi("a", 1, "+"), bi([1], (2,), "+"), bi((1,), [2], "+"), bi(b"a", 1, "+"))

# === 非整数的重复次数被拒绝 ===
print(bi("ab", 2.5, "*"), bi(2.5, "ab", "*"), bi(None, "ab", "*"))
print(bi([1], 2.5, "*"), bi((1,), 2.5, "*"), bi(b"x", 2.5, "*"))

# === 一元运算符 ===
print(+5, +2.5, +True, +False, -5, -2.5, ~5)

# === 除以零的文案随类型而异 ===
print(bi(1, 0, "/"), bi(1, 0, "//"), bi(1, 0, "%"))
print(bi(1, 0.0, "/"), bi(1.5, 0.0, "//"), bi(1, 0.0, "%"))

# === 集合与 frozenset 的 repr (repr 与 str 相同) ===
print(repr({1}))
print({1})
print(repr(set()))
print(set())
print({1, 2, 3})
print(repr(frozenset({1})))
print(frozenset())
print(frozenset({1, 2}))
print(repr({"a"}))
print(sorted({3, 1, 2}))
print(bool(set()), bool({1}), bool(frozenset()))

# === 字符串/bytes 的 % 格式化: 无转换说明时报错 ===
print("%d" % 1)
print("%s-%s" % ("a", "b"))
print("%%" % ())
print("100%% done" % ())

try:
    "s" % 1
except TypeError as e:
    print("str-mod TypeError:", e)
try:
    "s" % (1,)
except TypeError as e:
    print("str-mod-tuple TypeError:", e)
try:
    b"x" % 1
except TypeError as e:
    print("bytes-mod TypeError:", e)

# === bool 运算的结果类型 ===
print(repr(True & True), repr(True | False), repr(True ^ True))
print(repr(True << 1), repr(True >> 1))
print(repr(True & 1), repr(True | 1))
print(repr(True // 2), repr(True % 2), repr(True / 2))
print(repr(True // 1.5), repr(True % 1.5))
print(repr(True + True), repr(True * True), repr(True ** True))

# === % 命名字段与映射实参 ===
print("%(a)s" % {"a": 1})
print("%(a)s-%(b)d" % {"a": "x", "b": 2})
print("%s" % {"a": 1})
print("%s" % [1])
print("%s" % range(2))
print("%s" % b"x")


def mod_kind(fmt, arg):
    try:
        return "OK:" + repr(fmt % arg)
    except Exception as e:
        return type(e).__name__ + ": " + str(e)


print(mod_kind("%s", 1))
print(mod_kind("%s", True))
print(mod_kind("%s", 1.5))
print(mod_kind("%s", None))
print(mod_kind("%s", "x"))
print(mod_kind("%s", {1}))
print(mod_kind("%s", ()))
print(mod_kind("%s", (1,)))
print(mod_kind("%(a)s", {1: 2}))
