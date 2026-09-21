# str.format 格式说明符测试

# 位置参数 (自动编号与显式编号)
print("{} and {}".format(1, 2))         # 1 and 2
print("{0} {1}".format("a", "b"))       # a b
print("{1} {0}".format("a", "b"))       # b a
print("{0} {0}".format("x"))            # x x

# 关键字参数
print("{name}".format(name="Alice"))    # Alice
print("{x} and {y}".format(x=1, y=2))   # 1 and 2

# 混合位置与关键字
print("{0} {name}".format(10, name="z"))  # 10 z

# 浮点格式
print("{:.2f}".format(3.14159))         # 3.14
print("{:.1f}".format(3.14159))         # 3.1
print("{:,.2f}".format(12345.678))      # 12,345.68

# 整数格式
print("{0:04d}".format(42))             # 0042
print("{:x}".format(255))               # ff
print("{:X}".format(255))               # FF
print("{:b}".format(5))                 # 101
print("{:o}".format(8))                 # 10

# 对齐与填充
print("{:>8}".format("hi"))             # "      hi"
print("{:<8}|".format("hi"))            # "hi      |"
print("{:^8}".format("hi"))             # "   hi   "
print("{0:0>4}".format(7))              # 0007
print("{:*^6}".format("ab"))            # **ab**
print("{:>5}".format(42))               # "   42"

# 转换标志
print("{!r}".format("str"))             # 'str'
print("{!s}".format("str"))             # str
print("{!a}".format("hi"))              # 'hi'

# 转义花括号
print("{{}}".format())                  # {}
print("{{{}}}".format(5))               # {5}

# 组合
print("{0!r:>10}".format("hi"))         # "      'hi'"
print("{:s}".format("hi"))              # hi

print("done")
