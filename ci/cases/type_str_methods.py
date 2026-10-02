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

# casefold 完整 Unicode 折叠 (P2-49)
print("ß".casefold(), "ABC".casefold())
print("ﬁ".casefold(), "ſ".casefold())
