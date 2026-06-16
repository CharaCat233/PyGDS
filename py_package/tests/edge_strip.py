# Edge: strip 带参数

s = "  hello  "
print(repr(s.strip()))           # 'hello'
print(repr(s.strip(" ")))        # 'hello'

s2 = "xxhelloxx"
print(s2.strip("x"))             # hello

s3 = "abc123abc"
print(s3.strip("abc"))           # 123

s4 = "##title##"
print(s4.strip("#"))             # title

# lstrip
print(repr("  hi".lstrip()))     # 'hi'
print("xxhi".lstrip("x"))        # hi

# rstrip
print(repr("hi  ".rstrip()))     # 'hi'
print("hixx".rstrip("x"))        # hi

print("done")