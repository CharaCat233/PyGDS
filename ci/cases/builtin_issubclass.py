# 职责: issubclass/isinstance 元组嵌套短路
# 比对: same_output

# issubclass 元组第二参 (alpha.4)
print(issubclass(bool, (int, str)))
print(issubclass(bool, (str, dict)))
print(issubclass(bool, int))
print(issubclass(bool, ()))

# 短路求值: 首个匹配即返回, 后续非类元素不检查
print(issubclass(bool, (int, 5)))
print(issubclass(bool, (int, (str,))))

# 嵌套元组递归
print(issubclass(bool, ((str,),)))
print(issubclass(bool, ((str,), (bool,))))
print(issubclass(bool, (str, (bool, dict))))

# 自定义类与多继承


class A:
    pass


class B(A):
    pass


class C(B):
    pass


print(issubclass(C, (A, B)))
print(issubclass(C, (str, B)))
print(issubclass(A, (B, C)))
print(issubclass(C, A))

# isinstance 元组形态 (嵌套与短路)
print(isinstance(5, (int, str)))
print(isinstance(5, (int, 5)))
print(isinstance("a", ((str,), (int,))))
print(isinstance(5, (str, (int,))))

# 错误文案 (CPython 同句式)
try:
    print(issubclass(bool, (str, 5)))
except TypeError as e:
    print("T1:", e)
try:
    print(issubclass(bool, [int, str]))
except TypeError as e:
    print("T2:", e)
try:
    print(issubclass(bool, 5))
except TypeError as e:
    print("T3:", e)
try:
    print(issubclass(5, int))
except TypeError as e:
    print("T4:", e)
try:
    print(isinstance(5, (str, 5)))
except TypeError as e:
    print("T5:", e)
try:
    print(isinstance(5, 5))
except TypeError as e:
    print("T6:", e)
