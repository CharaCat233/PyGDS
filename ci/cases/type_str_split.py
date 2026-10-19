# 职责: split/rsplit 的 maxsplit 行为
# 比对: same_output


s = "a,b,c,d"
print(s.split(","))  # ['a', 'b', 'c', 'd']
print(s.split(",", 1))  # ['a', 'b,c,d']
print(s.split(",", 2))  # ['a', 'b', 'c,d']

# 默认 split
s2 = "hello world foo bar"
print(s2.split())  # ['hello', 'world', 'foo', 'bar']
print(s2.split(None, 1))  # ['hello', 'world foo bar']

# rsplit
print(s.rsplit(",", 1))  # ['a,b,c', 'd']
print(s.rsplit(",", 2))  # ['a,b', 'c', 'd']

# maxsplit 实参校验: float/None 报 '<t>' object cannot be interpreted as an integer, 大数报 OverflowError
def _arg_exc(label, fn):
    try:
        print(label, repr(fn()))
    except Exception as e:
        print(label, type(e).__name__, str(e))


_arg_exc("split_float", lambda: "a b c".split(None, 1.5))
_arg_exc("split_none", lambda: "a,b".split(",", None))
_arg_exc("split_big", lambda: "a b c".split(None, 10**100))
_arg_exc("rsplit_float", lambda: "a b c".rsplit(None, 1.5))
_arg_exc("rsplit_none", lambda: "a,b".rsplit(",", None))
_arg_exc("rsplit_big", lambda: "a b c".rsplit(None, 10**100))
print("a,b,c".split(",", True))
print("a,b,c".rsplit(",", True))
print("a,b,c".split(",", 2**63 - 1))
print("a b c".split(None, 2**63 - 1))

# 空分隔符 (与 partition 同族)
try:
    "a,b,c".split("", 2)
except ValueError as e:
    print("VE:", str(e))
try:
    "a,b,c".rsplit("", 2)
except ValueError as e:
    print("VE:", str(e))
