# 职责: types 模块的类型别名身份与 SimpleNamespace 行为
# 比对: same_output

import types

print(types.FunctionType is type(lambda: 0))
print(types.LambdaType is types.FunctionType)
print(types.NoneType is type(None))
print(types.EllipsisType is type(...))
print(type([].append) is types.BuiltinMethodType)
print(type(int | str) is types.UnionType)
print(type(list[int]) is types.GenericAlias)
ns = types.SimpleNamespace(a=1, b="x")
print(repr(ns), type(ns).__name__)
ns.c = 3
print(ns.c, ns.a)
print(ns == types.SimpleNamespace(a=1, b="x", c=3))
print(ns != types.SimpleNamespace(a=1))
print(sorted(ns.__dict__))
print(types.MappingProxyType({"a": 1})["a"])
