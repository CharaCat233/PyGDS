# Feature: 括号内换行 (隐式续行) 与反斜杠续行

x = (1 +
     2)
print(x)

y = [
    1,
    2,
]
print(y)

z = {
    'a': 1,
}
print(z)

print(
    1,
    2,
)

m = {
    "k": (1 +
          2),
}
print(m)

s = 1 + \
    2
print(s)

t = (1 +
     # 注释行
     3)
print(t)

# 调用实参尾随逗号
print(max(1, 2, key=lambda v: -v,))
print(*[1, 2],)

# 括号内换行不污染缩进
def f():
    return [
        10,
        20,
    ]
print(f())
print(sum([
    1,
    2,
]))
