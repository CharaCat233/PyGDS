# Lang: 菱形继承与 __init__ 链、super() 沿 MRO 协作


class Base:
    def __init__(self):
        self.steps = ["base"]
        super().__init__()

    def greet(self):
        return "Base"


class Left(Base):
    def __init__(self):
        super().__init__()
        self.steps.append("left")

    def greet(self):
        return "Left+" + super().greet()


class Right(Base):
    def __init__(self):
        super().__init__()
        self.steps.append("right")

    def greet(self):
        return "Right+" + super().greet()


class Child(Left, Right):
    def __init__(self):
        super().__init__()
        self.steps.append("child")

    def greet(self):
        return "Child+" + super().greet()


cd = Child()
print(cd.steps)
print(cd.greet())
print([k.__name__ for k in Child.__mro__])


class Mixin:
    def tag(self):
        return "mixin"


class Root:
    def __init__(self):
        self.tagged = True
        self.origin = "root"
        super().__init__()


class Feature(Mixin, Root):
    def __init__(self):
        super().__init__()


f = Feature()
print(f.tag(), f.tagged, f.origin)
print(isinstance(f, Mixin), isinstance(f, Root))


class Bottom(Feature, Child):
    def label(self):
        return "bottom"

    def greet(self):
        return "Bottom+" + super().greet()


bt = Bottom()
print([k.__name__ for k in Bottom.__mro__])
print(sorted(bt.steps))
print(bt.greet(), bt.label())
