# 职责: str 常用方法：大小写/切分/查找等
# 比对: same_output


s = "Hello World"
print(s.upper())  # HELLO WORLD
print(s.lower())  # hello world

trim_str = "  trim  "
print(trim_str.strip())  # trim

# split
split_src = "a,b,c"
parts = split_src.split(",")
print(parts)  # ['a', 'b', 'c']
print(len(parts))  # 3

# join
joiner = ", "
print(joiner.join(parts))  # a, b, c

# replace
replace_src = "abab"
print(replace_src.replace("a", "x"))  # xbxb

# find / startswith / endswith
hello_str = "hello"
print(hello_str.find("ll"))  # 2
print(hello_str.find("xx"))  # -1
print(hello_str.startswith("he"))  # True
print(hello_str.endswith("lo"))  # True
print(hello_str.endswith("xx"))  # False

# casefold 完整 Unicode 折叠
print("ß".casefold(), "ABC".casefold())
print("ﬁ".casefold(), "ſ".casefold())

# encode/split/rsplit 关键字实参被忽略 (此前 encoding= 被丢弃, split(sep=) 当无分隔符)
try:
    "é".encode(encoding="ascii")
except UnicodeEncodeError as e:
    print("UEE:", str(e))

print("é".encode(encoding="latin-1"))
print("a".encode(encoding="ascii"))
try:
    "é".encode("ascii", errors="ignore")
except Exception:
    print("ignore-multi")
print("é".encode("ascii", "ignore"))
print("é".encode(encoding="ascii", errors="replace"))
print("a,b".split(sep=","))
print("a,b,c".split(sep=",", maxsplit=1))
print("a b c".split(sep=" ", maxsplit=1))
print("a,b".rsplit(sep=","))
print("a,b,c".rsplit(sep=",", maxsplit=1))

# rsplit 丢失最左空字段 (此前 ",a".rsplit(",") -> ['a'])
print(",a".rsplit(","))
print("a".rsplit("a"))
print("".rsplit(","))
print(",,a".rsplit(","))
print("a,b,".rsplit(","))
print(",a,b".rsplit(","))
# 空分隔符按 CPython 报 ValueError
try:
    print("".rsplit(""))
except ValueError as e:
    print("VE:", str(e))

# 空 needle 检索族 (此前 rfind 用 min, find 忽略 end, count 为 0)
print("abc".rfind(""))
print("abc".rfind("", 1))
print("abc".find("", 1, 0))
print("abc".find("", 2, 1))
print("abc".count(""))
print("abc".count("c", 2, 1))
print("abc".count("", 1, 3))
print("abc".find(""))
print("abc".rfind("", 0, 2))
print("abc".find("", 0, 3))

# bool 实参按 int 参与 (此前静默忽略)
print("aaa".replace("a", "b", True))
print("aaa".replace("a", "b", False))
print("a b c".split(None, True))
print("a b c".split(None, False))
print("abc".find("a", True))
print("abc".find("a", False))
print("abc".count("a", True))
print("abc".rfind("a", True))
print("abc".replace("a", "b", True))
print("abc".startswith("b", True))
print("abc".endswith("c", True))

# 空串包含判定 (此前 "" in "abc" 返回 False, 任何串包含空串)
print("" in "abc")
print("a" in "")
print("" in "")
print("" not in "abc")
print([] in [[], 1])

# partition/rpartition 空分隔符报 ValueError (此前静默错元组)
try:
    print("abc".partition(""))
except ValueError as e:
    print("VE:", e)
try:
    print("abc".rpartition(""))
except ValueError as e:
    print("VE:", e)
print("abc".partition("b"))
print("abc".rpartition("b"))
print("abc".partition("x"))
print("abc".rpartition("x"))

# expandtabs 在 \r 处重置列计数 (此前仅 \n 归零)
print("a\rb\tc".expandtabs())
print("a\nb\tc".expandtabs())
print("a\r\tb".expandtabs(4))
print("a\n\tb".expandtabs(4))
print("ab\tc".expandtabs(4))


# startswith/endswith 的 start/end 位置实参 (元组前缀已支持)
print("hello".startswith("ell", 1, 4))
print("hello"[0:4].endswith("ell", 0, 3))
print("hello".startswith(("x", "he")))
# split("") 空分隔符报 ValueError
try:
    "abc".split("")
except ValueError as e:
    print("VE-split:", str(e))
# rsplit(None, maxsplit) 保留左段内部空白
print("  a  b ".rsplit(None, 1))
print("  a  b ".rsplit(None, 0))
print("  a  b ".rsplit(None))
print("   ".rsplit(None, 1))
# replace("", X) 空串替换展开
print("abc".replace("", "-"))
print("abc".replace("", "-", 2))
print("".replace("", "-"))
print("abc".replace("", "-", 0))
# splitlines 识别 NEL / 其他行界
print("a\r\nb\rc\nd\x85e".splitlines())
print("a\x0bb\x0cc\x1cd".splitlines())
print("a\u2028b".splitlines())
# join 校验元素类型 (此前静默字符串化)
try:
    "-".join([1, 2])
except TypeError as e:
    print("TE-join:", str(e))
try:
    "-".join(["a", 1])
except TypeError as e:
    print("TE-join2:", str(e))
print("-".join(["a", "b"]))
# encode 未知错误处理器名报 LookupError (编码出错时惰性查找)
try:
    "héllo".encode("ascii", "bogus")
except LookupError as e:
    print("LE:", str(e))
print("abc".encode("ascii", "bogus"))
print("héllo".encode("ascii", "backslashreplace"))
print("héllo".encode("ascii", "xmlcharrefreplace"))

# ljust/rjust fill 校验 / startswith 非 str / removeprefix 非 str
try:
    "a".ljust(3, "")
except TypeError as e:
    print("TE-fill1:", str(e)[:40])
try:
    "a".ljust(5, "xy")
except TypeError as e:
    print("TE-fill2:", str(e)[:40])
try:
    "a".rjust(3, 5)
except TypeError as e:
    print("TE-fill3:", str(e)[:40])
try:
    "abc".startswith(1)
except TypeError as e:
    print("TE-sw:", str(e)[:40])
try:
    "abc".removeprefix(1)
except TypeError as e:
    print("TE-rp:", str(e)[:40])
print("a\vb\fc".splitlines())
