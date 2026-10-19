# 职责: print 的 sep/end 与 type() 查询
# 比对: same_output


# 测试内置函数

print()
print(1)
print(1.5)
print("a")
print("a", "b")
print("a", "b", "c", sep=", ")
print("a", "b", "c", end=" --\n")
print("a", "b", "c", sep=", ", end=" --\n")
print("a", "b", "c", sep=", ", end=" --\n")

print(type(0))
print(type(""))

# sep/end 类型校验 (sep=None 按默认分隔符, 非 str/None 报 TypeError)
print(1, 2, sep=None)
print(1, 2, end=None)
try:
    print(1, sep=1)
except TypeError as e:
    print("TE-sep:", e)
try:
    print(1, end=1)
except TypeError as e:
    print("TE-end:", e)
try:
    print("a", "b", sep=3.5)
except TypeError as e:
    print("TE-sep2:", e)

# 未知关键字实参报错 (优先于 sep/end 取值校验) 与 flush 无操作
try:
    print(1, foo=2)
except TypeError as e:
    print("TE-kw:", e)
try:
    print(1, sep=1, foo=2)
except TypeError as e:
    print("TE-kw2:", e)
print("fz", flush=True)
print("fn", file=None)

# file= 写入目标文件对象 (错误文案与读取面经文本读归一)
pf = open("print_file.tmp", "w")
print("to-file", file=pf)
pf.close()
print(repr(open("print_file.tmp").read()))
pf = open("print_file.tmp", "w")
print(1, 2, sep="-", end="!\n", file=pf)
pf.close()
print(repr(open("print_file.tmp").read()))
try:
    print("x", file=1)
except AttributeError as e:
    print("AE:", e)
open("print_file.tmp", "w").close()
pf = open("print_file.tmp", "r")
try:
    print("x", file=pf)
except Exception as e:
    print("RO:", type(e).__name__, str(e))
pf.close()
try:
    print("x", foo=1)
except TypeError as e:
    print("TE-kw3:", e)
print("done")
