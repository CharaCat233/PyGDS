# Edge: __call__ 可调用对象

class Multiplier:
    def __init__(self, factor):
        self.factor = factor

    def __call__(self, x):
        return x * self.factor

double = Multiplier(2)
triple = Multiplier(3)

print(double(5))             # 10
print(triple(5))             # 15
print(double(10))            # 20

# callable 检查
print(callable(double))      # True
print(callable(42))          # False
print(callable(len))         # True

print("done")