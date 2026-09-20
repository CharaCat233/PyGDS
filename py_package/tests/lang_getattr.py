# getattr / setattr / delattr 内置函数测试

class Point:
    def __init__(self):
        self.x = 0

p = Point()

# setattr
setattr(p, "x", 42)
setattr(p, "y", 10)
print(p.x)                 # 42
print(p.y)                 # 10

# getattr 基础
print(getattr(p, "x"))     # 42
print(getattr(p, "y"))     # 10

# getattr 默认值
print(getattr(p, "missing", "default"))   # default

# delattr
delattr(p, "y")
print(getattr(p, "y", "gone"))            # gone

# 动态调用方法
class Greeter:
    def hello(self):
        return "hi"
    def bye(self):
        return "bye"

g = Greeter()
method = "hello"
print(getattr(g, method)())   # hi
print(getattr(g, "bye")())    # bye

# 获取内置方法
lst = [1, 2, 3]
m = getattr(lst, "append")
m(4)
print(lst)                    # [1, 2, 3, 4]

# callable 与 getattr 组合
print(callable(getattr([], "append")))   # True

# 类属性
class Config:
    MAX = 100

print(getattr(Config, "MAX"))  # 100

# setattr 与 getattr 交互
setattr(p, "name", "point")
print(getattr(p, "name"))      # point

print("done")
