# Feature: hasattr 内置函数

print(hasattr(int, 'x'))
class C:
    def __init__(self):
        self.x = 1
    def m(self):
        pass

c = C()
print(hasattr(c, 'x'), hasattr(c, 'm'), hasattr(c, 'y'))
print(hasattr('ab', 'upper'))
print(hasattr([1], 'append'))
print(getattr(C, 'nope', 'def'))
try:
    getattr(C, 'nope')
except AttributeError:
    print('AE')
