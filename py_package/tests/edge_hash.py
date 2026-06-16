# Edge: __hash__ 和 hashable

# 内置类型的 hash
print(type(hash(42)))        # <class 'int'>
print(type(hash("hello")))   # <class 'int'>
print(type(hash(3.14)))      # <class 'int'>
print(type(hash(True)))      # <class 'int'>

# 相同值有相同 hash
print(hash(42) == hash(42))  # True

# list 不可 hash
try:
    hash([1, 2, 3])
except TypeError:
    print("TypeError")       # TypeError

# dict 不可 hash
try:
    hash({"a": 1})
except TypeError:
    print("TypeError")       # TypeError

# 自定义 __hash__
class Hashable:
    def __init__(self, v):
        self.v = v
    def __hash__(self):
        return hash(self.v)
    def __eq__(self, other):
        if isinstance(other, Hashable):
            return self.v == other.v
        return NotImplemented

h1 = Hashable(42)
h2 = Hashable(42)
print(hash(h1) == hash(h2))  # True

print("done")