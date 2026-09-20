# f-string 支持测试

name = "Alice"
age = 30

# 基础插值
print(f"Hello, {name}!")
print(f"Age: {age}")
print(f"Sum: {1 + 2}")
print(f"Mixed: {name} is {age} years old")

# 表达式
print(f"Double: {age * 2}")
print(f"Len: {len([1, 2, 3])}")
print(f"Cond: {'yes' if age > 18 else 'no'}")

# 字符串方法调用
print(f"Upper: {'hello'.upper()}")

# 转义花括号
print(f"literal {{braces}}")
print(f"empty: {{}}")

# 数字格式化
print(f"int: {42:d}")
print(f"hex: {255:x}")
print(f"HEX: {255:X}")
print(f"bin: {5:b}")
print(f"oct: {8:o}")
print(f"pad: {42:05d}")
print(f"float: {3.14159:.2f}")
print(f"width: |{42:>6}|")
print(f"left: |{42:<6}|")
print(f"center: |{42:^6}|")
print(f"fill: |{'hi':*^8}|")
print(f"sign+: {5:+d}")
print(f"sign-: {-5:+d}")
print(f"comma: {1000000:,}")
print(f"percent: {0.25:.1%}")

# 转换标志
print(f"str: {age!s}")
print(f"repr: {[1, 2, 3]!r}")

# 字典/列表索引
d = {"k": "v"}
print(f"dict: {d['k']}")
lst = [10, 20, 30]
print(f"list: {lst[1]}")

# 嵌套 f-string
x = 5
print(f"outer {f'inner {x}'}")

print("done")
