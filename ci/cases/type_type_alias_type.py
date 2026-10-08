# 职责: type(类型别名实例) 返回 TypeAliasType (I2-70)
# 比对: same_output

# PEP 695 type 别名绑定 TypeAliasType 对象, type(别名) 返回 TypeAliasType 类型类
# (repr 带 typing. 前缀, 与 CPython 一致)

type Alias1 = int
print("type:", type(Alias1))
print("name:", type(Alias1).__name__)
print("repr:", repr(type(Alias1)))
print("class:", Alias1.__class__)

type Alias2 = list
print("alias2-type:", type(Alias2).__name__)
print("alias2-repr:", repr(type(Alias2)))

# 别名自身的 str/repr 不受影响
print("alias-str:", str(Alias1))
