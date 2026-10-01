# 职责: __slots__ 白名单赋值与继承行为
# 比对: same_output

# __slots__ 实例赋值白名单 (P2-23)
class S:
    __slots__ = ("a", "b")
s = S()
s.a = 1
print(s.a)
try:
    s.c = 3
except AttributeError as e:
    print(e)
try:
    print(s.b)
except AttributeError as e:
    print("unset:", e)

class A:
    __slots__ = ("x",)
class B(A):
    __slots__ = ("y",)
b = B()
b.x = 1
b.y = 2
print(b.x, b.y)
try:
    b.z = 3
except AttributeError as e:
    print(e)

class T:
    __slots__ = "s"
t = T()
t.s = 5
print(t.s)

class P:
    pass
class Q(P):
    __slots__ = ("q",)
q = Q()
q.q = 1
q.other = 2
print(q.other)

S.desc = 9
print(S.desc)
print(hasattr(s, "__dict__"))
