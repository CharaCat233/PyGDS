# 职责: 嵌套解包、变量交换与多重赋值目标（下标/属性/键）
# 比对: same_output


# 基本嵌套解包
(a, (b, c)) = (1, (2, 3))
print(a, b, c)               # 1 2 3

# 三层嵌套
(a, (b, (c, d))) = (1, (2, (3, 4)))
print(a, b, c, d)            # 1 2 3 4

# 星号 + 嵌套
a, (b, *rest), c = 1, [2, 3, 4], 5
print(a, b, rest, c)         # 1 2 [3, 4] 5

# 混合括号和星号
first, *mid, (a, b) = "x", "y", "z", (10, 20)
print(first, mid, a, b)      # x ['y', 'z'] 10 20

# 解包到已有的变量交互
x = 1
y = 2
x, y = y, x
print(x, y)                  # 2 1

# 星号解包空
a, *b = [1]
print(a, b)                  # 1 []

# 纯星号解包
*a, = [1, 2, 3]
print(a)                     # [1, 2, 3]

print("done")

# === 多重赋值目标 ===
a = [1, 2, 3]
a[0], a[2] = a[2], a[0]
print("swap:", a)


class C:
    def __init__(self):
        self.p = 0
        self.q = 0


o = C()
o.p, o.q = 7, 8
print("attr:", o.p, o.q)

dd = {}
dd["m"], dd["n"] = 10, 20
print("item:", dd)


class Bag:
    def __init__(self):
        self.data = {}

    def put(self, k, v):
        self.data[k] = v


bag = Bag()
bag.put("z", 5)
print("chained:", bag.data)

print("done")
