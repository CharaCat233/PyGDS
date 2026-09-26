# Feature: 排序与 min/max 桥接用户类 __lt__ / __gt__ (含反射)

class P:
    def __init__(self, v):
        self.v = v
    def __lt__(self, other):
        return self.v < other.v

a = [P(2), P(1)]
a.sort()
print([p.v for p in a])

b = sorted([P(3), P(1), P(2)], reverse=True)
print([p.v for p in b])

print(min([P(2), P(1)]).v)
print(max([P(2), P(1)]).v)
print(min([P(2), P(1)], key=lambda p: -p.v).v)
print(sorted([P(2), P(1)], key=lambda p: p.v)[0].v)

class Q:
    def __init__(self, v):
        self.v = v
    def __gt__(self, other):
        return self.v > other.v

print(sorted([Q(2), Q(1)])[0].v)
print(max([Q(2), Q(1)]).v)
print([P(1), P(9)] < [P(2), P(9)])

try:
    sorted([P(1), 'a'])
except TypeError:
    print('TypeError')
print('done')
