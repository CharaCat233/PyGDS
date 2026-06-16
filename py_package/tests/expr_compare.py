# Expression: 比较 / 逻辑 / 布尔

print(1 < 2 and 3 > 2)  # True
print(1 > 2 or 3 > 2)  # True
print(not True)  # False
print(0 or "hello")  # hello (短路)
print("" and 42)  # (空字符串, 短路)
print([] == False)  # False
print(None is None)  # True
print("a" in "abc")  # True
