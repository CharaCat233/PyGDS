# Edge: isinstance / issubclass

print(isinstance(42, int))           # True
print(isinstance(42, float))         # False
print(isinstance(42, object))        # True
print(isinstance("hi", str))         # True
print(isinstance([1, 2], list))      # True
print(isinstance((1,), tuple))       # True
print(isinstance({}, dict))          # True
print(isinstance(True, bool))        # True
print(isinstance(True, int))         # True (bool 是 int 子类)
print(isinstance(None, type(None)))  # True

# isinstance with tuple
print(isinstance(42, (int, str)))    # True
print(isinstance("hi", (int, float)))# False

# issubclass
print(issubclass(bool, int))         # True
print(issubclass(int, object))       # True
print(issubclass(bool, object))      # True
print(issubclass(str, int))          # False

# 自定义类
class A:
    pass

class B(A):
    pass

a = A()
b = B()
print(isinstance(a, A))             # True
print(isinstance(b, A))             # True
print(isinstance(a, B))             # False
print(issubclass(B, A))             # True
print(issubclass(A, B))             # False

print("done")