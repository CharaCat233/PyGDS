# 职责: PEP 695 type 别名与泛型类/函数语法接受
# 比对: same_output


type Vector = list
type Mapping[K, V] = dict


class Box[T]:
    def __init__(self, v):
        self.value = v

    def get(self):
        return self.value


b = Box(7)
print(b.get())


class Pair[K, V]:
    def __init__(self, k, v):
        self.k = k
        self.v = v


p = Pair("a", 1)
print(p.k, p.v)


def first[T](items):
    return items[0]


print(first([1, 2]))


def pick[T: int, U](x):
    return x


print(pick(3))


class Holder[T]:
    def __init__(self):
        self.items = []

    def add(self, x):
        self.items.append(x)


h = Holder()
h.add(1)
h.add(2)
print(h.items)


def scale(v: Vector, k):
    return v[0] * k


print(scale([3, 4], 2))

x: Vector = 5
print(x)

print("generic syntax accepted")
