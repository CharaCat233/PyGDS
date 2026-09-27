# Lang: 用户类自定义描述符 (__get__ / __set__)


class Desc:
    def __get__(self, obj, owner):
        if obj is None:
            return "class:" + owner.__name__
        return "inst:" + str(obj.name)


class Host:
    d = Desc()

    def __init__(self, name):
        self.name = name


print(Host.d)
h = Host("h1")
print(h.d)
print(Host("h2").d)
print("d" in dir(Host))


class Validated:
    def __set__(self, obj, value):
        if value < 0:
            raise ValueError("negative")
        obj.value_ = value

    def __get__(self, obj, owner):
        if obj is None:
            return self
        return obj.value_


class Box:
    v = Validated()


b = Box()
b.v = 5
print(b.v)
try:
    b.v = -1
except ValueError as e:
    print("rejected:", e)
print(b.v)

# 普通属性访问不受描述符影响
plain = Host("p")
plain.other = 9
print(plain.other, plain.name)
