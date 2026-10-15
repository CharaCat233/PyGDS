# 职责: 类定义、类变量与类方法/静态方法
# 比对: same_output


class MyClass:
    class_var = 100

    def __init__(self, val):
        self.val = val

    @classmethod
    def get_class_var(cls):
        return cls.class_var

    @classmethod
    def increment_class_var(cls):
        cls.class_var = cls.class_var + 1

    @classmethod
    def factory(cls, x):
        return cls(x)

    @staticmethod
    def add(a, b):
        return a + b

    @staticmethod
    def greet(name):
        return "Hello, " + name

    def get_val(self):
        return self.val


# 通过类调用 classmethod
print("classmethod on class:", MyClass.get_class_var())  # 100

# 通过实例调用 classmethod
obj = MyClass(42)
print("classmethod on instance:", obj.get_class_var())  # 100

# classmethod 工厂方法
obj2 = MyClass.factory(99)
print("factory:", obj2.get_val())  # 99

# 通过类调用 staticmethod
print("staticmethod on class:", MyClass.add(3, 7))  # 10

# 通过实例调用 staticmethod
print("staticmethod on instance:", obj.add(10, 20))  # 30

# staticmethod 字符串操作
print("staticmethod greet:", MyClass.greet("World"))  # Hello, World
print("staticmethod greet instance:", obj.greet("DSL"))  # Hello, DSL

# 综合调用测试
print("class_var:", MyClass.class_var)  # 100
MyClass.increment_class_var()
print("class_var:", MyClass.get_class_var())  # 101
MyClass.increment_class_var()
obj.increment_class_var()
print("class_var:", MyClass.class_var)  # 103
MyClass.increment_class_var()
print("class_var:", MyClass.get_class_var())  # 104


# 嵌套/局部类的默认 repr 用限定名 (CPython __main__.fn.<locals>.Item)
def _mk_local():
    class Item:
        pass

    return Item()


_mk_local_inst = _mk_local()
print(str(_mk_local_inst))  # 归一后 <_mk_local.<locals>.Item object>
print(repr(_mk_local_inst))
print(_mk_local_inst.__class__.__qualname__)  # _mk_local.<locals>.Item

# 类级 repr 与 __name__ 不变
print(type(_mk_local_inst).__name__)
print(repr(type(_mk_local_inst)))  # <class '__main__._mk_local.<locals>.Item'>
