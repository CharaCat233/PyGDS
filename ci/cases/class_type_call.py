# 职责: type.__call__ 槽与元类 __call__ 委派 (super().__call__ / type.__call__)
# 比对: same_output


class Meta(type):
    def __call__(cls, *args, **kwargs):
        print("meta:", args)
        return super().__call__(*args, **kwargs)


class C(metaclass=Meta):
    def __init__(self, x):
        self.x = x


print(C(7).x)


class Meta2(type):
    def __call__(cls, *args, **kwargs):
        return type.__call__(cls, *args, **kwargs)


class D(metaclass=Meta2):
    def __init__(self, v):
        self.v = v


print(D(3).v)
print(type.__call__(C, 5).x)
print(type(C).__name__, type(C(1)).__name__)
