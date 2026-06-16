# Builtin: str 方法


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
