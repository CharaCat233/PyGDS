# f-string 增强测试: = 调试说明符 与 嵌套格式宽度

# = 调试说明符 (Python 3.8+)
x = 42
print(f"{x=}")              # x=42 (默认 repr)
s = "hi"
print(f"{s=}")              # s='hi' (字符串用 repr)
f = 3.14
print(f"{f=}")              # f=3.14
lst = [1, 2]
print(f"{lst=}")            # lst=[1, 2]

# = 与转换标志
print(f"{x=!s}")            # x=42 (str)
print(f"{s=!r}")            # s='hi' (repr)
print(f"{x=!r}")            # x=42

# = 与格式说明符
print(f"{x=:05d}")          # x=00042
print(f"{x=:+d}")           # x=+42
print(f"{f=:.2f}")          # f=3.14

# = 表达式
y = 5
print(f"{x + y=}")          # x + y=47
print(f"{x * 2=}")          # x * 2=84

# 嵌套格式宽度 (动态宽度/精度)
w = 8
print(f"{123:0{w}d}")       # 00000123
print(f"{'abc':>{w}}")      #      abc (宽度 8 右对齐)
p = 2
print(f"{3.14159:.{p}f}")   # 3.14 (动态精度)
n = 5
print(f"{42:{n}d}")         #    42 (宽度 5)

print("done")
