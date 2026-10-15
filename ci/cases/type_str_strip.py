# 职责: strip/lstrip/rstrip 带字符集参数
# 比对: same_output


s = "  hello  "
print(repr(s.strip()))  # 'hello'
print(repr(s.strip(" ")))  # 'hello'

s2 = "xxhelloxx"
print(s2.strip("x"))  # hello

s3 = "abc123abc"
print(s3.strip("abc"))  # 123

s4 = "##title##"
print(s4.strip("#"))  # title

# lstrip
print(repr("  hi".lstrip()))  # 'hi'
print("xxhi".lstrip("x"))  # hi

# rstrip
print(repr("hi  ".rstrip()))  # 'hi'
print("hixx".rstrip("x"))  # hi



# 无实参 strip/lstrip/rstrip 剥离 Python 空白全集 (含 NBSP 等 Zs/Zl/Zp)
print("\u00a0ab\u00a0".strip() == "ab")
print("\u00a0ab\u00a0".lstrip() == "ab\u00a0")
print("\u00a0ab\u00a0".rstrip() == "\u00a0ab")
print("\u2003ab\u3000".strip() == "ab")
print("\u2028ab\u2029".strip() == "ab")
print(repr("  ab \n".strip()))
print("\u00a0\u00a0x\u00a0\u2003".strip(" \t"))  # 显式字符集不受影响
