# duty: 非类基类的元类候选解析与调用文案 (直接/星参/混合形态, CPython 同文案)
# compare: same_output
# anchor: CPython 3.12

def try_build(label, fn):
    try:
        print(label + ":", fn())
    except TypeError as e:
        print(label, "TypeError:", e)

# CPython 对非类基类以其类型作元类候选: 胜出候选 dict 按 (名字, 基类元组, 属性字典) 三参调用,
# dict 只收 1 参报 "dict expected at most 1 argument, got 3" (与裸调 dict("C", (), {}) 同文案)
def mk_direct_dict():
    class C({}):
        pass
    return "ok"
try_build("direct-dict", mk_direct_dict)

# 星参展开的非类基类同规则, 与直接形态文案一致
def mk_star_dict():
    class C(*[{}]):
        pass
    return "ok"
try_build("star-dict", mk_star_dict)

# 类基类与非类基类混排: 候选 type 与候选 dict 互不为子类, 不发起调用直接报 conflict
class B:
    pass
def mk_mixed():
    class C(B, *[{}]):
        pass
    return "ok"
try_build("mixed", mk_mixed)

# 两个非类基类候选不同 (dict 与 int): 互不为子类报 metaclass conflict
def mk_two_diff():
    class C(*[{}, 1]):
        pass
    return "ok"
try_build("two-diff", mk_two_diff)

# 同一候选重复出现 (两个 dict 基类) 不冲突, 仍按三参调用报错
def mk_two_same():
    class C(*[{}, {}]):
        pass
    return "ok"
try_build("two-same", mk_two_same)

# 显式 metaclass=type 与非类基类候选并存: type 与 dict 互不为子类报 conflict
def mk_meta_type():
    class C(*[{}], metaclass=type):
        pass
    return "ok"
try_build("dict-meta-type", mk_meta_type)

# 显式非可调用 metaclass 先于候选解析报调用错误 (CPython 同序)
def mk_meta_int():
    class C(*[{}], metaclass=1):
        pass
    return "ok"
try_build("dict-meta-int", mk_meta_int)

# 显式 metaclass=dict 与非类基类并存: dict 与 int 候选互不为子类报 conflict
def mk_meta_dict():
    class C(1, metaclass=dict):
        pass
    return "ok"
try_build("int-meta-dict", mk_meta_dict)

# 星参展开的真类基类不受影响, 正常建类
def mk_star_class():
    class C(*[B]):
        pass
    return C.__name__
try_build("star-class", mk_star_class)

# int 基类: 胜出候选 int 按 (名字, 基类元组, 属性字典) 三参调用,
# int 只收 2 参报 "int() takes at most 2 arguments (3 given)" (I2-58 文案对齐后入册)
def mk_int_base():
    class C(1):
        pass
    return "ok"
try_build("int-base", mk_int_base)

# str 基类: 胜出候选 str 三参调用走 encoding 类型校验,
# 报 "str() argument 'encoding' must be str, not tuple" (I2-58 文案对齐后入册)
def mk_str_base():
    class C(*["abc"]):
        pass
    return "ok"
try_build("str-base", mk_str_base)
