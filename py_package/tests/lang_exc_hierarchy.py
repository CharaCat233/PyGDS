# 异常层次与状态隔离测试
# 对应 v0.5.0-alpha.5:
#   - 内置异常继承关系 (ArithmeticError / LookupError 等父类可捕获子类)
#   - 捕获异常后不得污染后续执行 (None 单例类型、后续 except 匹配)

# === 异常继承关系 ===
try:
    1 / 0
except ArithmeticError:
    print("ZeroDivisionError is ArithmeticError")

try:
    1.0 / 0
except ArithmeticError:
    print("float ZeroDivisionError is ArithmeticError")

try:
    1 // 0
except ArithmeticError:
    print("floordiv is ArithmeticError")

try:
    1 % 0
except ArithmeticError:
    print("mod is ArithmeticError")

try:
    int(float("inf"))
except ArithmeticError:
    print("OverflowError is ArithmeticError")

try:
    1 / 0
except ZeroDivisionError:
    print("ZeroDivisionError catchable directly")

try:
    {}["k"]
except LookupError:
    print("KeyError is LookupError")

try:
    [1][9]
except LookupError:
    print("IndexError is LookupError")

try:
    [1][9]
except IndexError:
    print("IndexError catchable directly")

try:
    {}["k"]
except KeyError:
    print("KeyError catchable directly")

# ValueError 不属于 ArithmeticError
caught_kind = "none"
try:
    int("zz")
except ArithmeticError:
    caught_kind = "arith"
except ValueError:
    caught_kind = "value"
print("ValueError kind:", caught_kind)

# === 捕获异常后状态不被污染 ===
try:
    int("abc")
except ValueError as e:
    pass

print("None type:", type(None).__name__)
print("None repr:", None)
print("None is None:", None is None)
print("None bool:", bool(None))

# 捕获后仍能正常匹配后续 except
try:
    None + None
except TypeError as e:
    print("caught after prior catch")

try:
    float("xyz")
except ValueError as e:
    print("float error caught after prior catch")

# 捕获后类型系统仍正确
print("types:", type(True).__name__, type(1).__name__, type(1.5).__name__, type("s").__name__)
print("still works:", 1 + True, 1.5 + True, "a" + "b", [1] + [2])


def raises_then_catches(a, b):
    try:
        return a["missing"]
    except KeyError:
        return "caught-key"


print(raises_then_catches({}, 1))
print(raises_then_catches({}, 2))

# 连续多次捕获不同类型的异常
kinds = []
for i in range(3):
    try:
        if i == 0:
            1 / 0
        elif i == 1:
            None + None
        else:
            [][5]
    except ZeroDivisionError:
        kinds.append("zero")
    except TypeError:
        kinds.append("type")
    except IndexError:
        kinds.append("index")
print("kinds:", kinds)
