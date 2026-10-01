# 职责: min/max 缺省与 __getitem__ 旧式迭代
# 比对: same_output


print(min([], default="empty"), max([], default=0))
print(min([], default=None))
print(min([3, 1], key=lambda v: -v), max([], default="keep"))
print(min(2, 5), max(2, 5))
try:
    min([])
except ValueError as e:
    print("no default still raises")


class Grid:
    def __init__(self):
        self.data = [10, 20, 30]

    def __getitem__(self, k):
        if k >= len(self.data):
            raise IndexError(k)
        return self.data[k]


g = Grid()
print(list(g))
print([v // 10 for v in g])
print(sum(g))
out = []
for v in g:
    out.append(v * 2)
print(out)
print(max(g), min(g))
print(tuple(g))

# 迭代中抛出的其他错误照常传播
class Bad:
    def __getitem__(self, k):
        if k == 2:
            raise KeyError("bad")
        if k > 2:
            raise IndexError
        return k


try:
    list(Bad())
except KeyError as e:
    print("propagated:", e)
