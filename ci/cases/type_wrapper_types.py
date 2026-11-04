# 职责: 内建魔法描述符与其绑定形态的类型名与 repr (wrapper_descriptor / method-wrapper)
# 比对: same_output


def tn(v):
    return type(v).__name__


# 类级槽: wrapper_descriptor
print(tn(list.__len__))
print(tn(str.__add__))
print(tn(list.__iadd__))
print(tn(dict.__getitem__))
# 实例绑定: method-wrapper
print(tn([].__len__))
print(tn("".__len__))
print(tn({}.__getitem__))
# 类级 repr (slot wrapper 形态, 无地址)
print(repr(list.__len__))
print(repr(str.__add__))
print(repr(list.__iadd__))
# 绑定 repr 的名称段 (地址双端不同, 截断比对)
print(repr([].__len__)[:32])
print(repr([].append)[:30])
print(tn([].append))
print(tn(len))
