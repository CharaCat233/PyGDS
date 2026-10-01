# 职责: split/rsplit 的 maxsplit 行为
# 比对: same_output


s = "a,b,c,d"
print(s.split(","))             # ['a', 'b', 'c', 'd']
print(s.split(",", 1))          # ['a', 'b,c,d']
print(s.split(",", 2))          # ['a', 'b', 'c,d']

# 默认 split
s2 = "hello world foo bar"
print(s2.split())                # ['hello', 'world', 'foo', 'bar']
print(s2.split(None, 1))         # ['hello', 'world foo bar']

# rsplit
print(s.rsplit(",", 1))          # ['a,b,c', 'd']
print(s.rsplit(",", 2))          # ['a,b', 'c', 'd']

print("done")
