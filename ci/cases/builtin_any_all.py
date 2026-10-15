# 职责: any/all 对各真值组合与空容器的判定
# 比对: same_output


print(any([True, False]))  # True
print(any([False, False]))  # False
print(any([]))  # False
print(any([0, "", []]))  # False
print(any([0, "hi"]))  # True

print(all([True, True]))  # True
print(all([True, False]))  # False
print(all([]))  # True
print(all([1, "hi", [1]]))  # True
print(all([1, "", [1]]))  # False


# any/all 遍历 dict 的键 (此前遍历值), 不可迭代报 TypeError (此前静默 True)
print(any({5: 0}))  # 遍历键: 5 为真
print(all({5: 0}))  # 遍历键: 5 为真
print(any({0: "a"}))  # 遍历键: 0 为假
print(all({0: "a"}))  # 遍历键: 0 为假
print(any({}))  # 空 dict
print(all({}))
print(any({1: 0, 0: 1}))  # 遍历键 1, 0
print(all({1: 0, 2: 0}))  # 遍历键 1, 2

# 不可迭代对象报 TypeError
try:
    print(any(5))
except TypeError as e:
    print("TE", str(e))

try:
    print(all(0))
except TypeError as e:
    print("TE", str(e))

try:
    print(any(None))
except TypeError as e:
    print("TE", str(e))

# 字符串/其他可迭代不受影响
print(any("abc"))
print(all("abc"))
print(any(""))
print(all(""))
