# 数值转换、真值算术与类型错误文案测试
# 对应 v0.5.0-alpha.5:
#   - int() / float() 严格解析 (非法字面量必须报错, 不能静默给 0)
#   - float repr 采用最短往返表示
#   - bool 按 int 子类参与算术与相等比较
#   - 各运算符的类型错误文案与 CPython 一致

# === int() 严格解析 ===
print(int("12"))
print(int("ff", 16))
print(int("0x1f", 16))
print(int("0x1f", 0))
print(int("10", 2))
print(int("1_0"))
print(int("  42  "))
print(int("+5"))
print(int(1.9))
print(int(-1.9))
print(int(True))

try:
    int("abc")
except ValueError as e:
    print("int-abc ValueError:", e)
try:
    int("12abc")
except ValueError as e:
    print("int-12abc ValueError:", e)
try:
    int("1.5")
except ValueError as e:
    print("int-1.5 ValueError:", e)
try:
    int("")
except ValueError as e:
    print("int-empty ValueError:", e)
try:
    int("ff")
except ValueError as e:
    print("int-ff ValueError:", e)
try:
    int("5", 3)
except ValueError as e:
    print("int-53 ValueError:", e)
try:
    int(None)
except TypeError as e:
    print("int-none TypeError:", e)
try:
    int([1])
except TypeError as e:
    print("int-list TypeError:", e)
try:
    int(float("nan"))
except ValueError as e:
    print("int-nan ValueError:", e)
try:
    int(float("inf"))
except OverflowError as e:
    print("int-inf OverflowError:", e)

# === float() 严格解析与特殊值 ===
print(float("1.5"))
print(float("  2.5  "))
print(float("1_0"))
print(float("inf"), float("-inf"))
print(float(True))
print(float("nan") != float("nan"))
try:
    float("abc")
except ValueError as e:
    print("float-abc ValueError:", e)
try:
    float("")
except ValueError as e:
    print("float-empty ValueError:", e)
try:
    float(None)
except TypeError as e:
    print("float-none TypeError:", e)

# === float repr 采用最短往返表示 ===
print(1 / 3)
print(1 / 1.5)
print(0.1 + 0.2)
print(2.0 ** 0.5)
print(1e16)
print(1e-5)
print(repr(1.5), repr(0.1 + 0.2))
print([1 / 3], (1 / 3,), {1: 1 / 3})

# === bool 按 int 子类参与算术 ===
print(True + 1, False + 1, True * 3, True - 1)
print(-True, ~True, +True, +False)
print(True / 2, True // 2, True % 2, True ** 2)
print(True + True, True * True, True / True)
print(True << 1, True >> 1, True & 1, True | 2, True ^ 3)
print(True < 2, True > 0, True <= 1, True >= 1)
print(True == 1, 1 == True, True == 1.0, 1.0 == True)
print(True != 0, 0 != True, False == 0, 0 == False)
print(True + 1.5, True * 2.5, True / 0.5)
print(type(True).__name__, isinstance(True, int), isinstance(True, bool))
print(True is True)

# === dict / set 中 bool 与整数是同一个键 ===
d = {True: "a"}
print(d[True], d[1])
print(True in {1}, 1 in {True}, 1.0 in {1})
print({1: "b"}[True])
print(len({True, 1, 1.0}))

# === 运算符类型错误文案 ===


def op_kind(a, b, op):
    try:
        if op == "+":
            return "no-error:" + repr(a + b)
        elif op == "-":
            return "no-error:" + repr(a - b)
        elif op == "*":
            return "no-error:" + repr(a * b)
        elif op == "/":
            return "no-error:" + repr(a / b)
        elif op == "//":
            return "no-error:" + repr(a // b)
        elif op == "%":
            return "no-error:" + repr(a % b)
        elif op == "**":
            return "no-error:" + repr(a ** b)
        elif op == "<<":
            return "no-error:" + repr(a << b)
        elif op == ">>":
            return "no-error:" + repr(a >> b)
        elif op == "&":
            return "no-error:" + repr(a & b)
        elif op == "|":
            return "no-error:" + repr(a | b)
        return "no-error:" + repr(a ^ b)
    except Exception as e:
        return type(e).__name__ + ": " + str(e)


print(op_kind(None, None, "+"))
print(op_kind(None, 1, "+"))
print(op_kind(1, None, "+"))
print(op_kind(None, 2, "*"))
print(op_kind(None, 2, "/"))
print(op_kind(None, 2, "//"))
print(op_kind(None, 2, "%"))
print(op_kind(None, 2, "**"))
print(op_kind(None, 1, "<<"))
print(op_kind(None, 1, ">>"))
print(op_kind(None, 1, "&"))
print(op_kind(None, 1, "|"))
print(op_kind(None, 1, "^"))
print(op_kind("s", 2, "/"))
print(op_kind([1], 2, "/"))
print(op_kind((1,), 2, "/"))
print(op_kind("s", 1, "<<"))
print(op_kind([1], [2], "&"))
print(op_kind(1, "s", "+"))
print(op_kind(1.5, "s", "/"))
print(op_kind(True, "s", "+"))


def unary_kind(a, op):
    try:
        if op == "-":
            return "no-error:" + repr(-a)
        if op == "+":
            return "no-error:" + repr(+a)
        return "no-error:" + repr(~a)
    except Exception as e:
        return type(e).__name__ + ": " + str(e)


print(unary_kind(None, "-"))
print(unary_kind(None, "+"))
print(unary_kind(None, "~"))
print(unary_kind("s", "-"))
print(unary_kind([1], "~"))

# === 序列拼接与重复的类型规则 ===
print(op_kind("s", 2, "+"))
print(op_kind("s", 2.5, "+"))
print(op_kind("s", [1], "+"))
print(op_kind("s", None, "+"))
print(op_kind("s", (1,), "+"))
print(op_kind([1], "s", "+"))
print(op_kind([1], (2,), "+"))
print(op_kind((1,), [2], "+"))
print(op_kind("ab", 2, "*"))
print(op_kind("ab", 2.5, "*"))


def seq_kind(a, b, op):
    try:
        if op == "*":
            return "no-error:" + repr(a * b)
        return "no-error:" + repr(a + b)
    except Exception as e:
        return type(e).__name__ + ": " + str(e)


print(seq_kind("ab", True, "*"))
print(seq_kind(b"a", "b", "+"))
print(seq_kind(b"a", 1, "+"))

# === 一元正号: 数值原样 ===
print(+5, +2.5, -5, -2.5)
print(+-3, -+3, +-+3)

# === 异常层次: 子类可被父类 except 捕获 ===
try:
    1 / 0
except ArithmeticError:
    print("ZeroDivisionError is ArithmeticError")
try:
    int(float("inf"))
except ArithmeticError:
    print("OverflowError is ArithmeticError")
try:
    {}["k"]
except LookupError:
    print("KeyError is LookupError")
try:
    [1][5]
except LookupError:
    print("IndexError is LookupError")
try:
    int("zz")
except ArithmeticError:
    print("ValueError is ArithmeticError (should not print)")
except ValueError:
    print("ValueError is not ArithmeticError")
