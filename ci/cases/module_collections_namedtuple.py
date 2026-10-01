# 职责: namedtuple 构造/_make/_replace
# 比对: same_output


from collections import namedtuple

Point = namedtuple("Point", "x y")
p = Point(1, 2)
print(p.x, p.y)
print(p[0], p[1], p[-1])
print(len(p))
print(list(p))
a, b = p
print(a + b)
print(repr(p), str(p))
print(p == Point(1, 2), p == (1, 2), p == Point(9, 9))
print(isinstance(p, tuple))
print(Point._fields)
print(p == [1, 2])

# 关键字构造与默认不可省略
q = Point(x=5, y=6)
print(q.x, q.y)
try:
    Point(1)
except TypeError as te:
    print("missing:", te)
try:
    Point(1, 2, 3)
except TypeError as te:
    print("extra:", te)

# _make / _replace / _asdict
r = Point._make([7, 8])
print(r.x, r.y)
r2 = r._replace(y=99)
print(r2, r.y)
print(r._asdict()["x"])

# 逗号分隔与可迭代字段名
Colored = namedtuple("Colored", "r, g, b")
c = Colored(1, 2, 3)
print(c.r + c.g + c.b)
Pair = namedtuple("Pair", ["left", "right"])
pr = Pair("L", "R")
print(pr.left, pr.right, repr(pr))

# 作方法返回值与遍历
class Shape:
    def corners(self):
        return Point(0, 1)


s = Shape()
for coord in s.corners():
    print("corner", coord)
