# 职责: split/reversed/except-as 回归
# 比对: same_output

print("a,b,c".split(",", 0), "a,b,c".split(",", 1), " a b ".split(None, 0))
r = reversed([1, 2, 3])
print(list(r), list(r))
print(type(r).__name__)
print(list(reversed("ab")), list(reversed((1, 2))))
print(list(reversed({"a": 1, "b": 2})))
print("{0.real}".format(3), "{n.real}".format(n=5))
class N:
    v = "attr-val"
print("{m.v}".format(m=N()))
print(b"abc" < b"abd", b"abc" <= b"abc", b"abd" > b"abc")
print(bytes(range(3)))
try:
    raise ValueError("v")
except ValueError as e:
    pass
try:
    print(e)
except NameError:
    print("as-deleted")
try:
    raise 1
except TypeError as err:
    print("TE:", err)
print("ab".center(5, "-"), "abc".center(6))
try:
    "ab".center(5, "**")
except TypeError as e:
    print("FILL")
