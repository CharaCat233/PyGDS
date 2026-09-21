# 赋值表达式 walrus := 测试 (Python 3.8+)

# 表达式的值即赋值结果
print(x := 7)                 # 7
print(x)                      # 7

# if 条件中使用 (带括号与不带括号)
if (n := 10) > 5:
    print(n)                  # 10
if m := 20:
    print(m)                  # 20

# while 循环: 读取直到哨兵值
data = [3, 1, 4, 0, 5]
i = 0
while (cur := data[i]) != 0:
    print(cur)                # 3 1 4
    i += 1

# 列表推导式中的 walrus (绑定到外层作用域)
vals = [y := v * 2 for v in range(4)]
print(vals)                   # [0, 2, 4, 6]
print(y)                      # 6

# 推导式条件中的 walrus
print([z for v in range(6) if (z := v * v) > 4])   # [9, 16, 25]
print(z)                      # 25


# 函数调用实参
def show(a, b):
    print(a, b)


show(x := 1, x + 1)           # 1 2

# 嵌套赋值 (需括号)
print((a := (b := 3)) + a + b)   # 9

# 与三目运算符组合
print((m2 := 5) if True else 0)  # 5
print(m2)                        # 5

# 容器字面量中
print([(k := 2), k * 3])         # [2, 6]
print({(q := 1): q + 1})         # {1: 2}
print((s := "ab") + "c")         # abc

# 生成器表达式中的 walrus 与 any 短路
print(any((e := v) > 2 for v in [1, 2, 3]))   # True
print(e)                                      # 3

# lambda 内的 walrus 绑定在函数局部
print((lambda: (t := 9))())      # 9

# 增强赋值右侧
total = 0
nums = [5, 10, 15]
idx = 0
while idx < 3:
    total += (v := nums[idx])
    idx += 1
print(total)                     # 30
print(v)                         # 15

# 字符串与数字混合
print((w := "a" * 2) + w)        # aaaa
print((f := 2.5) * 2)            # 5.0

# 循环变量与 walrus 同时使用
pairs = [(r := i * i, i) for i in range(3)]
print(pairs)                     # [(0, 0), (1, 1), (4, 2)]
print(r)                         # 4

# 裸写 while 条件 (无需括号)
src = iter([1, 2, 3])
while cur2 := next(src, None):
    print(cur2)                  # 1 2 3

# for 的迭代对象中使用
for item in (lst := [7, 8]):
    print(item)                  # 7 8
print(lst)                       # [7, 8]

# 集合 / 字典推导式
print(sorted({(q2 := x) * 2 for x in [1, 2]}))   # [2, 4]
print(q2)                                        # 2
print({(k2 := x): (m3 := x + 1) for x in [1, 2]})  # {1: 2, 2: 3}
print(k2, m3)                                      # 2 3

# assert 中使用
try:
    assert (z2 := 0) == 1, "fail"
except AssertionError as err:
    print("assert", err, z2)     # assert fail 0

# 默认参数 (定义时求值)
def with_default(a=(d2 := 5)):
    return a + d2


print(with_default())            # 10
print(d2)                        # 5

# 函数内 global 声明与 walrus
gv = 0


def set_global():
    global gv
    return (gv := 9)


print(set_global(), gv)          # 9 9


# 嵌套函数: walrus 绑定在局部作用域
def outer():
    def inner():
        return (loc := 4)
    return inner()


print(outer())                   # 4

# 生成器惰性求值与 walrus
gen2 = ((c2 := x) * 10 for x in [1, 2, 3])
print(next(gen2), c2)            # 10 1
print(list(gen2), c2)            # [20, 30] 3

# 三元表达式两侧的 walrus
print((p2 := 1) if (n3 := 0) else (p2 := 2))   # 2
print(p2, n3)                                  # 2 0

print("done")
