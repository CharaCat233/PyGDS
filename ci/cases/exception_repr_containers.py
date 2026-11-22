# 职责: 容器与异常组成员里的异常对象 repr 形态 (Type(args...) 形式)
# 比对: same_output

print([ValueError("v")])
print((KeyError("k"), TypeError("t")))
print({"e": ValueError("x")})
print(ValueError("v", 2).args)
print(repr(ValueError("v", 2)))
print(str([Exception("e")]))
g = ExceptionGroup("g", [ValueError("v")])
print(g.exceptions[0])
print(repr(g).startswith("ExceptionGroup("))
