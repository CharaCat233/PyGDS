# 职责: list/bytearray 原地 dunder 直调 (__iadd__ / __imul__) 属性面与语义
# 比对: same_output

# list.__iadd__ / list.__imul__ 与 bytearray 同族直调: 属性可达, 返回自身保持别名
# bytes 不可变无原地 dunder (CPython 同)

# list __iadd__ 原地 extend 语义 + 别名恒等
l = [1, 2]
r = l.__iadd__([3])
print(r, l is r)
print(l)
l2 = [1]
l2.__iadd__((2,))
l2.__iadd__("ab")
l2.__iadd__(range(2))
print(l2)

# list __iadd__ 非可迭代: 两端同文案 ('X' object is not iterable)
try:
    [1].__iadd__(5)
except TypeError as e:
    print("TE-add:", e)

# list __imul__ 原地重复 + 别名恒等 + n<=0 清空
l3 = [1, 2]
r3 = l3.__imul__(2)
print(r3, l3 is r3)
l4 = [1, 2]
r4 = l4.__imul__(0)
print(r4, l4 is r4, l4)
l5 = [3]
l5.__imul__(True)
print(l5)

# list __imul__ 大数计数: 索引位溢出
try:
    [1].__imul__(10 ** 100)
except OverflowError as e:
    print("OE-mul:", e)

# bytearray __iadd__ 仅收 bytes-like, 原地 extend + 别名恒等
ba = bytearray(b"a")
rb = ba.__iadd__(b"b")
print(rb, ba is rb)
try:
    bytearray(b"a").__iadd__([1])
except TypeError as e:
    print("TE-ba:", e)

# bytearray __imul__ 原地重复 + 别名恒等 + n<=0 清空
ba2 = bytearray(b"ab")
rb2 = ba2.__imul__(2)
print(rb2, ba2 is rb2)
ba3 = bytearray(b"ab")
rb3 = ba3.__imul__(0)
print(rb3, ba3 is rb3)
ba4 = bytearray(b"a")
ba4.__imul__(-1)
print(ba4)

# bytearray __imul__ 大数计数
try:
    bytearray(b"a").__imul__(10 ** 100)
except OverflowError as e:
    print("OE-ba:", e)

# bytes 不可变: 无原地 dunder (hasattr/属性访问双端一致)
print(hasattr(b"ab", "__iadd__"), hasattr(bytes, "__iadd__"))
print(hasattr(bytes, "__imul__"))
try:
    b"ab".__iadd__
except AttributeError as e:
    print("AE:", e)

# 类级与实例级 presence 矩阵
print(hasattr(list, "__iadd__"), hasattr(list, "__imul__"))
print(hasattr(bytearray, "__iadd__"), hasattr(bytearray, "__imul__"))
print(hasattr([1], "__iadd__"), hasattr([1], "__imul__"))
print(hasattr(bytearray(b"a"), "__iadd__"), hasattr(bytearray(b"a"), "__imul__"))
print([1].__iadd__ is not None, list.__iadd__ is not None)

# 类级描述符 repr 形态 (slot wrapper)
print(repr(list.__iadd__))
print(repr(bytearray.__imul__))

# dir 面含原地 dunder
print("__iadd__" in dir([1]), "__imul__" in dir([1]))
print("__iadd__" in dir(bytearray(b"a")), "__imul__" in dir(bytearray(b"a")))

# += / *= 语句层语义不受注册影响 (别名与返回值)
a = [1]
b = a
a += [2]
print(b, a is b)
c = [1]
d = c
c *= 3
print(d, c is d)
e = bytearray(b"x")
f = e
e *= 2
print(f, e is f)
