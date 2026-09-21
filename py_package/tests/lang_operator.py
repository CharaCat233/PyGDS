# operator 模块测试

import operator

# 算术运算
print(operator.add(1, 2))           # 3
print(operator.sub(5, 3))           # 2
print(operator.mul(4, 3))           # 12
print(operator.truediv(7, 2))       # 3.5
print(operator.floordiv(7, 2))      # 3
print(operator.mod(7, 3))           # 1
print(operator.pow(2, 10))          # 1024
print(operator.neg(5))              # -5
print(operator.pos(-3))             # -3
print(operator.abs(-4))             # 4
print(operator.add("a", "b"))       # ab
print(operator.add([1], [2]))       # [1, 2]

# 位运算
print(operator.and_(12, 10))        # 8
print(operator.or_(12, 10))         # 14
print(operator.xor(12, 10))         # 6
print(operator.invert(5))           # -6
print(operator.lshift(1, 4))        # 16
print(operator.rshift(16, 4))       # 1

# 比较运算
print(operator.eq(1, 1.0))          # True
print(operator.ne(1, 2))            # True
print(operator.lt(1, 2))            # True
print(operator.le(2, 2))            # True
print(operator.gt(3, 2))            # True
print(operator.ge(2, 3))            # False
print(operator.is_(None, None))     # True
print(operator.is_not(1, 2))        # True

# 逻辑
print(operator.not_(0))             # True
print(operator.not_([1]))           # False
print(operator.truth([]))           # False
print(operator.truth("x"))          # True

# 序列操作
print(operator.concat([1, 2], [3]))         # [1, 2, 3]
print(operator.contains([1, 2, 3], 2))      # True
print(operator.contains("abc", "b"))        # True
print(operator.getitem([10, 20, 30], 1))    # 20
print(operator.getitem({"a": 1}, "a"))      # 1

d = {"x": 1}
operator.setitem(d, "y", 2)
print(d)                                    # {'x': 1, 'y': 2}

lst = [1, 2, 3]
operator.delitem(lst, 0)
print(lst)                                  # [2, 3]

print(operator.countOf([1, 1, 2], 1))       # 2
print(operator.indexOf([1, 2, 3], 2))       # 1
print(operator.length_hint([1, 2, 3]))      # 3
print(operator.length_hint(5))              # 0

# itemgetter
get1 = operator.itemgetter(1)
print(get1(["a", "b", "c"]))                        # b
print(operator.itemgetter(0, 2)(["a", "b", "c"]))   # ('a', 'c')
print(operator.itemgetter("x")({"x": 9}))           # 9
print(operator.itemgetter(1)([(1, "a"), (2, "b")])) # (2, 'b')
print(type(operator.itemgetter(1)))                 # <class 'operator.itemgetter'>
print(operator.itemgetter(1))                       # operator.itemgetter(1)
print(callable(operator.itemgetter(1)))             # True

# itemgetter 与 sorted 配合
pairs = [(2, "b"), (1, "a"), (3, "c")]
print(sorted(pairs, key=operator.itemgetter(0)))
print(sorted(pairs, key=operator.itemgetter(1)))


# attrgetter
class Point:
    def __init__(self, x, y):
        self.x = x
        self.y = y


pts = [Point(3, 1), Point(1, 2), Point(2, 0)]
print(sorted(pts, key=operator.attrgetter("x"))[0].x)   # 1
print(sorted(pts, key=operator.attrgetter("y"))[0].y)   # 0
print(operator.attrgetter("y")(pts[0]))                 # 1
print(operator.attrgetter("x", "y")(pts[0]))            # (3, 1)
print(type(operator.attrgetter("x")))                   # <class 'operator.attrgetter'>
print(operator.attrgetter("x"))                         # operator.attrgetter('x')

# itemgetter 与 map 配合
print(list(map(operator.itemgetter(0), [(1, "a"), (2, "b")])))   # [1, 2]

print("done")
