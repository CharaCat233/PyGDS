# Edge: 嵌套解包

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