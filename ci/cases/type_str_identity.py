# 职责: 字符串驻留与 is 身份关系
# 比对: same_output

# 运行期字符串与字面量的身份关系 (P2-39)
a = "ab"
b = "a" + "b"
print(a is b)
print("ab" * 2 is "abab", 2 * "xy" is "xyxy")
print(b"a" + b"b" is b"ab")
print("中" is "中")
long_lit = "a" * 100 + "b" * 100
print("a" * 100 + "b" * 100 is long_lit)

# 大结果不折叠 (CPython 编译器 4096 上限)
print("x" * 5000 == "x" * 5000, "x" * 5000 is "x" * 5000)

# 单字符 latin-1 缓存: 运行期结果与字面量共享
print("a b".split()[0] is "a")
print(chr(97) is "a", chr(0x4e2d) is "中")
print("abc"[1] is "b", list("ab")[0] is "a", "ab"[0:1] is "a")
s = "a"
print(s[0] is "a")
it = iter("ab")
print(next(it) is "a")

# 空串全局单例
print("".join([]) is "")
print("abc"[:0] is "", "abc".strip("abc") is "")

# 大小写变换不走缓存 (CPython 一致)
print("a".upper() is "A", "A".lower() is "a")

# 一般运行期构造两侧均为新串
print("a".replace("a", "b") is "b", "".join(["a", "b"]) is "ab")

# 自返回语义与快速路径 (CPython 一致)
h = "hello"
print(h.center(5) is h, h.ljust(5) is h, h.rjust(5) is h, h.zfill(5) is h)
print(h.expandtabs() is h, "x".expandtabs(0) is "x")
w = "abc"
print("%s" % w is w, "{}".format(w) is w)
print(" a ".strip() is "a", "ax".removeprefix("a") is "x")
