# 职责: type 三参建类/dir/float.hex
# 比对: same_output

# type 身份语义, dir 内置实例, range 方法, float.hex

# type 名字是类对象本身
print(type)
print(type(5), type("s"), type([1]))


# 类是 type 的实例
class C:
    pass


print(isinstance(C, type), type(C) is type, type(type) is type)
print(isinstance(int, type), isinstance(5, type), isinstance(len, type))

# type 三参动态建类
A = type("A", (object,), {"x": 1})
a = A()
print(type(a) is A, a.x)
B = type("B", (), {})
print(isinstance(B(), B))

try:
    type()
except TypeError as e:
    print("t0:", e)
try:
    type(1, 2)
except TypeError as e:
    print("t2:", e)

# type 与 issubclass
print(issubclass(C, object), issubclass(C, type))

# dir 对内置类型实例列出方法
print("append" in dir([]), "sort" in dir([]), "__eq__" in dir([]))
print("bit_length" in dir(5), "__add__" in dir(5), "x" in dir(5))
print("keys" in dir({}), "get" in dir({}))
print("lower" in dir("s"), "decode" in dir(b"ab"))
print("args" in dir(ValueError()))
print(dir([]) == sorted(dir([])))


# dir 对用户类实例不变
class D:
    def method(self):
        return 1


print("method" in dir(D()), "append" in dir(D()))

# dir() 对任意非模块对象含 __class__ (CPython 所有对象/类均含, 无参 dir 不含)
print("__class__" in dir("s"), "__class__" in dir(5), "__class__" in dir([]))
print("__class__" in dir({}), "__class__" in dir((1,)), "__class__" in dir(1.5))
print("__class__" in dir(b"ab"), "__class__" in dir(range(3)), "__class__" in dir(None))
print("__class__" in dir(int), "__class__" in dir(D()), "__class__" in dir(len))

# range 的 count / index
print(range(10).count(3), range(10).count(99))
print(range(0, 20, 5).index(10), range(4).index(0))
try:
    range(3).index(9)
except ValueError as e:
    print("vr:", e)
print("count" in dir(range(3)), "index" in dir(range(3)))

# float.hex
print((1.5).hex())
print((3.0).hex())
print((-2.5).hex())
print((0.1).hex())
print((0.0).hex(), (-0.0).hex())
print((255.0).hex())
print(1e-300.hex())
print((2.2250738585072014e-308).hex())
print((2.2250738585072014e-308 / 4).hex())
print(float("inf").hex(), float("-inf").hex(), float("nan").hex())
print((1024.0).hex())


# type(生成器/文件对象).__name__ 返回正确类型名 (此前误返回 'type')
print(type((x for x in [1])).__name__)


def gen85():
    yield 1


print(type(gen85()).__name__)
print(type(gen85).__name__)
t85 = open("i85_type_tmp.txt", "w")
t85.close()
print(type(open("i85_type_tmp.txt")).__name__)
print(type(open("i85_type_tmp.txt", "rb")).__name__)
g85 = (x for x in [1])
print(g85.__class__.__name__)
f85 = open("i85_type_tmp.txt", "rb")
print(f85.__class__.__name__)
f85.close()
