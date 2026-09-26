# 异常对象 args/str/repr 与 repr 引号选择 (v0.6.0-alpha.2)

# 直接构造
e = ValueError("boom")
print(e.args)
print(str(e))
print(repr(e))
print(str(ValueError()), repr(ValueError()))
e2 = ValueError("a", 42)
print(e2.args, str(e2), repr(e2))

# 非字符串参数
e3 = ValueError(7)
print(e3.args, str(e3), repr(e3))

# raise 后捕获
try:
    raise ValueError("raised")
except ValueError as err:
    print(err.args, str(err), repr(err))

# 名称查找错误
try:
    print(no_such_name)
except NameError as ne:
    print(ne.args, str(ne), repr(ne))

# KeyError 的 str 用 repr
try:
    {}["k"]
except KeyError as ke:
    print(str(ke), repr(ke))

# 用户异常继承
class MyErr(Exception):
    pass
me = MyErr("custom")
print(me.args, str(me), repr(me))
try:
    raise MyErr("boom")
except MyErr as m2:
    print(m2.args, str(m2))

# __init__ 覆盖时 args 仍随构造参数记录 (BaseException.__new__ 语义)
class CErr(Exception):
    def __init__(self, code):
        self.code = code
ce = CErr(7)
print(ce.args, ce.code)

# args 属性存在于继承链任意层级
class Sub(MyErr):
    pass
print(Sub("s").args)

# repr 引号选择: 含单引号用双引号包裹, 含双引号用单引号, 都含用单引号转义
print(repr("it's"))
print(repr('say "hi"'))
print(repr("both ' and \""))
print(repr(["a", "b'c"]))
print(repr(("x",)))
print(repr({"k": "v'w"}))
print(repr(""))

# 异常消息含引号
try:
    raise ValueError("has 'quote'")
except ValueError as qe:
    print(repr(qe))

print("done_exc_repr")
