# match 映射模式: 键查找, rest, 嵌套, 排除规则

# 基本键匹配
match {"a": 1}:
    case {"a": v}:
        print("a =", v)

# 缺键不匹配
match {"b": 2}:
    case {"a": v}:
        print("no")
    case _:
        print("miss")

# 多键
match {"a": 1, "b": 2}:
    case {"a": v, "b": w}:
        print(v, w)

# 空映射匹配任意 dict
match {}:
    case {}:
        print("empty-any")

match {"k": 1}:
    case {}:
        print("nonempty-any")

# 非 dict 主题不匹配
match [1, 2]:
    case {}:
        print("no")
    case _:
        print("not-dict")

# **rest 捕获剩余键
match {"a": 1, "b": 2, "c": 3}:
    case {"a": v, **rest}:
        print(v, rest)

# rest 可为空
match {"a": 1}:
    case {"a": v, **rest}:
        print("empty-rest", v, rest)

# 只有 rest
match {"x": 9}:
    case {**all}:
        print("all", all)

# 嵌套映射与序列
match {"p": [1, {"q": 2}]}:
    case {"p": [1, {"q": q}]}:
        print("nested q", q)

# 子模式递归匹配
match {"nums": [1, 2]}:
    case {"nums": [a, b]}:
        print("nums", a, b)

# 键为负数字面量
match {-1: "neg"}:
    case {-1: v}:
        print("negkey", v)

# 键为 None
match {None: "n"}:
    case {None: v}:
        print("nonekey", v)

# 键为 True (与 1 同键)
match {True: "t"}:
    case {1: v}:
        print("boolkey", v)

# 子模式绑定后用于守卫
match {"v": 5}:
    case {"v": v} if v > 3:
        print("guard", v)

# 非 dict 主题带嵌套也不匹配
match {"a": {"b": 1}}:
    case {"a": {"b": x}}:
        print("deep", x)

match {"a": [1]}:
    case {"a": [x]}:
        print("seqval", x)

# dict 值匹配失败继续下一个 case
match {"a": 1}:
    case {"a": 2}:
        print("no")
    case {"a": 1}:
        print("yes")

print("done_map")
