# 职责: property / staticmethod / classmethod 的子类化与实例行为
# 比对: same_output


class P(property):
    pass


class C:
    v = P(lambda s: 5)


print(C().v, C.v)
print(type(C.v).__name__)


class S(staticmethod):
    pass


class D:
    m = S(lambda: 7)


print(D().m())
print(type(D.__dict__["m"]).__name__)

hits = []


class Q(property):
    def __set_name__(self, owner, name):
        hits.append((owner.__name__, name))
        self.stored = name


class E:
    p = Q(lambda s: 7)


print(E.p.stored, hits, E().p)
