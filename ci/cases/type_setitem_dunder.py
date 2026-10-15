# 职责: __setitem__ dunder 直调路径的切片赋值与类型/越界校验
# 比对: same_output

# __setitem__ dunder 直调此前静默 no-op (切片形态报 TypeError, bytearray 越界值静默忽略)
# 语句路径 l[1:2] = [9, 9] 正常, 仅 dunder 直调失效; 改为共用语句路径实现

# list 切片形态 dunder 直调
l = [1, 2, 3]
l.__setitem__(slice(1, 2), [9, 9])
print(l)
l[1:2] = [7]
print(l)
l.__setitem__(slice(0, 2), [])
print(l)
l.__setitem__(1, 42)
print(l)
try:
    l.__setitem__(9, 0)
except IndexError as e:
    print("IE:", e)

# bytearray dunder 直调: 越界值/类型错须报错, 合法值写入
bb = bytearray(b"a")
try:
    bb.__setitem__(0, 300)
except ValueError as e:
    print("VE:", e)
try:
    bb.__setitem__(0, "z")
except TypeError as e:
    print("TE:", e)
print(bytes(bb))
bb.__setitem__(0, 120)
print(bytes(bb))
try:
    bb.__setitem__(5, 1)
except IndexError as e:
    print("IE2:", e)

# 字典 dunder 直调
d = {}
d.__setitem__("k", 1)
print(d["k"])
d.__setitem__(5, "five")
print(d[5])
