# 函数与方法的类型类 (P2-20)
def fn():
    pass
lam = lambda: 1
class C:
    def m(self):
        pass
inst = C()
print(type(fn).__name__)
print(type(lam).__name__)
print(type(len).__name__)
print(type(inst.m).__name__)
print(type(fn))
print(type(len))
print(isinstance(fn, type))
print(type(fn) is type(print))
print(C.m.__name__)
print(inst.m.__name__)
print(len.__name__)
