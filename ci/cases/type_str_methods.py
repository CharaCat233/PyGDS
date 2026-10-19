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


# 非 str 实参校验 (CPython 文案: strip 族 / split 族 / replace / encode 分族)
def _sa(label, fn):
    try:
        print(label, fn())
    except Exception as e:
        print(label, type(e).__name__, e)


_sa("strip_int", lambda: "abc".strip(1))
_sa("lstrip_int", lambda: "abc".lstrip(1))
_sa("rstrip_int", lambda: "abc".rstrip(1))
_sa("strip_tuple", lambda: "abc".strip((1, 2)))
_sa("strip_none", lambda: "abc".strip(None))
_sa("split_int", lambda: "a b".split(1))
_sa("rsplit_int", lambda: "a-b".rsplit(1.5))
_sa("split_none", lambda: "a b".split(None))
_sa("replace_new_int", lambda: "abc".replace("a", 1))
_sa("replace_old_int", lambda: "abc".replace(1, "b"))
_sa("replace_count_str", lambda: "abc".replace("a", "b", "x"))
_sa("encode_int", lambda: "abc".encode(1))
_sa("encode_err_int", lambda: "abc".encode("utf-8", 2))
_sa("encode_enc_none", lambda: "abc".encode(None))
_sa("encode_err_none", lambda: "abc".encode("utf-8", None))
_sa("encode_kw_int", lambda: "abc".encode(encoding=1))
_sa("encode_kw_err_int", lambda: "abc".encode("utf-8", errors=2))
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

# 检索族 start/end 实参校验: float/str 报 TypeError, None 视同缺省, 大数按 ±∞ 钳制
def _arg_exc(label, fn):
    try:
        print(label, repr(fn()))
    except Exception as e:
        print(label, type(e).__name__, str(e))


_arg_exc("find_float", lambda: "abc".find("a", 1.5))
_arg_exc("count_float", lambda: "abc".count("a", 1.5))
_arg_exc("startswith_float", lambda: "abc".startswith("a", 1.5))
_arg_exc("endswith_float", lambda: "abc".endswith("a", 1.5))
_arg_exc("find_str", lambda: "abc".find("a", "x"))
_arg_exc("find_none", lambda: "abc".find("a", None))
_arg_exc("count_none2", lambda: "abc".count("a", None, None))
_arg_exc("startswith_none", lambda: "abc".startswith("a", None))
_arg_exc("find_big_start", lambda: "abc".find("a", 10**100))
_arg_exc("find_big_end", lambda: "abc".find("a", 0, 10**100))
_arg_exc("find_big_neg", lambda: "abc".find("b", -10**100))
print("abc".find("b", True))

# 空前缀/后缀边界 (区间起止越界形态)
print("abc".startswith("", 3))
print("abc".startswith("", 4))
print("abc".startswith("", 10))
print("abc".startswith("", 2, 1))
print("abc".startswith("", 1, 2))
print("abc".endswith("", 3))
print("abc".endswith("", 4))
print("abc".endswith("", 10))
print("abc".endswith("", 2, 1))
print("abc".endswith("", 1, 10**100))
print("abc".startswith("bc", 1))
print("abc".startswith("bcd", 1))
print("abc".startswith("bc", 1, 2))
print("abc".endswith("b", 0, 2))
print("abc".endswith("cd", 0, 4))
print("abc".endswith("a", 0, 1))
print("abc".endswith("c", 2, 20))

# replace count 实参: float/None 报 '<t>' object cannot be interpreted as an integer, 大数报 OverflowError
_arg_exc("replace_float", lambda: "abc".replace("b", "x", 1.5))
_arg_exc("replace_none", lambda: "abc".replace("b", "x", None))
_arg_exc("replace_big", lambda: "abc".replace("b", "x", 10**100))
print("abc".replace("b", "x", True))
print("abab".replace("b", "x", True))
print("abab".replace("b", "x", 2**63 - 1))

# 无参方法族的多余位置实参
_arg_exc("upper-1", lambda: "abc".upper(1))
_arg_exc("lower-1", lambda: "abc".lower(1))
_arg_exc("title-1", lambda: "abc".title(1))
_arg_exc("capitalize-1", lambda: "abc".capitalize(1))
_arg_exc("casefold-1", lambda: "abc".casefold(1))
_arg_exc("swapcase-1", lambda: "abc".swapcase(1))
_arg_exc("isalpha-1", lambda: "abc".isalpha(1))
_arg_exc("isdigit-1", lambda: "1".isdigit(1))
_arg_exc("isalnum-1", lambda: "a1".isalnum(1))
_arg_exc("isspace-1", lambda: " ".isspace(1))
_arg_exc("islower-1", lambda: "abc".islower(1))
_arg_exc("isupper-1", lambda: "ABC".isupper(1))
_arg_exc("istitle-1", lambda: "Abc".istitle(1))
_arg_exc("isdecimal-1", lambda: "1".isdecimal(1))
_arg_exc("isnumeric-1", lambda: "1".isnumeric(1))
_arg_exc("isidentifier-1", lambda: "ab".isidentifier(1))
_arg_exc("isascii-1", lambda: "ab".isascii(1))
_arg_exc("isprintable-1", lambda: "ab".isprintable(1))
_arg_exc("strip-2", lambda: "abc".strip("a", "b"))
_arg_exc("lstrip-2", lambda: "abc".lstrip("a", "b"))
_arg_exc("rstrip-2", lambda: "abc".rstrip("a", "b"))
_arg_exc("split-3", lambda: "a,b".split(",", 1, 2))
_arg_exc("rsplit-3", lambda: "a,b".rsplit(",", 1, 2))
_arg_exc("find-4", lambda: "abc".find("a", 0, 1, 2))
_arg_exc("rfind-4", lambda: "abc".rfind("a", 0, 1, 2))
_arg_exc("count-4", lambda: "abc".count("a", 0, 1, 2))
_arg_exc("index-4", lambda: "abc".index("a", 0, 1, 2))
_arg_exc("startswith-4", lambda: "abc".startswith("a", 0, 1, 2))
_arg_exc("endswith-4", lambda: "abc".endswith("a", 0, 1, 2))
_arg_exc("zfill-2", lambda: "a".zfill(2, 3))
_arg_exc("ljust-3", lambda: "a".ljust(3, "x", "y"))
_arg_exc("rjust-3", lambda: "a".rjust(3, "x", "y"))
_arg_exc("removeprefix-2", lambda: "ab".removeprefix("a", "b"))
_arg_exc("removesuffix-2", lambda: "ab".removesuffix("b", "c"))
_arg_exc("partition-2", lambda: "ab".partition("a", "b"))
_arg_exc("rpartition-2", lambda: "ab".rpartition("a", "b"))
