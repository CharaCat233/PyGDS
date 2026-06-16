# Edge: 短路求值 (and / or 返回操作数)

# and 短路：返回第一个假值或最后一个真值
print(True and True)       # True
print(True and False)      # False
print(False and True)      # False
print(0 and 1)             # 0
print(1 and 0)             # 0
print(1 and 2)             # 2
print("" and "hello")      # (空字符串)
print("hello" and "")      # (空字符串)
print("a" and "b")         # b
print([] and [1])          # []
print([1] and [2])         # [2]
print(None and 1)          # None
print(1 and None)          # None

# or 短路：返回第一个真值或最后一个假值
print(True or False)       # True
print(False or True)       # True
print(0 or 1)              # 1
print(1 or 0)              # 1
print("" or "hello")       # hello
print("hello" or "")       # hello
print([] or [1])           # [1]
print([1] or [])           # [1]
print(None or 1)           # 1
print(0 or None)           # None

# not: 总是返回 bool
print(not True)            # False
print(not False)           # True
print(not 0)               # True
print(not 1)               # False
print(not "")              # True
print(not "hello")         # False
print(not [])              # True
print(not [1])             # False
print(not None)            # True