# 职责: 类体作用域、类内推导式与 property 内 super
# 比对: same_output



class E:
    default = 9

    def f(self, k=default):
        return k


print(E().f())
print(E().f(1))


class D:
    vals = [1, 2, 3]
    squares = [x * x for x in vals]
    total = sum(vals)


print(D.squares, D.total)

z = 99
lc = [z for z in range(3)]
print(z, lc)


class Greeting:
    text = "hi"

    def shout(self, suffix="!"):
        return self.text.upper() + suffix


print(Greeting().shout(), Greeting().shout("?"))

# 方法体仍不能读类体变量 (CPython 语义)
lookup = "module-level"


class Reader:
    lookup = "class-level"

    def get(self):
        return lookup


print(Reader().get())

# property getter / setter 内的 super()


class P0:
    @property
    def val(self):
        return "p0"

    @val.setter
    def val(self, v):
        self._v = "set:" + v


class P1(P0):
    @property
    def val(self):
        return "p1+" + super().val

    @val.setter
    def val(self, v):
        self._v = "set:" + v


p = P1()
print(p.val)
p.val = "x"
print(p._v)
