# 新增 str 方法测试: splitlines / removeprefix / removesuffix / partition / is* / expandtabs
# 以及 find/index/count/replace 增强

# splitlines
print("a\nb\n".splitlines())    # ['a', 'b']
print("ab\n\ncd".splitlines())  # ['ab', '', 'cd']
print("a\n\n".splitlines())     # ['a', '']
print("a\nb".splitlines())      # ['a', 'b']
print("a\nb\n".splitlines(True))  # ['a\n', 'b\n']

# removeprefix / removesuffix
print("hello".removeprefix("he"))    # llo
print("world".removeprefix("x"))     # world
print("hello".removesuffix("lo"))    # hel
print("hello".removesuffix("x"))     # hello
print("test".removeprefix("test"))   # ""

# partition / rpartition
print("hello".partition("l"))    # ('he', 'l', 'lo')
print("hello".rpartition("l"))   # ('hel', 'l', 'o')
print("hello".partition("z"))    # ('hello', '', '')
print("hello".rpartition("z"))   # ('', '', 'hello')
print("a-b-c".partition("-"))    # ('a', '-', 'b-c')

# is* 判定
print("123".isdecimal())         # True
print("12a".isdecimal())         # False
print("".isdecimal())            # False
print("123".isnumeric())         # True
print("abc123".isidentifier())   # False
print("abc".isidentifier())      # True
print("_x1".isidentifier())      # True
print("1abc".isidentifier())     # False
print("abc".isprintable())       # True
print("a\tb".isprintable())      # False
print("abc".isascii())           # True

# expandtabs
print("a\tb".expandtabs(4))      # a   b
print("a\t b".expandtabs(4))     # a    b
print("ab\tcd".expandtabs(4))    # ab  cd

# find / rfind / index (含 start/end)
print("hello".find("l"))         # 2
print("hello".find("l", 3))      # 3
print("hello".find("z"))         # -1
print("hello".rfind("l"))        # 3
print("hello".index("l"))        # 2
print("banana".count("a"))       # 3
print("banana".count("an"))      # 2
print("hello".count("l", 0, 3))  # 1

# replace (含 count)
print("hello".replace("l", "L"))        # heLLo
print("hello".replace("l", "L", 1))     # heLlo
print("ababa".replace("a", "x"))        # xbxbx
print("ababa".replace("a", "x", 2))     # xbxba

print("done")
