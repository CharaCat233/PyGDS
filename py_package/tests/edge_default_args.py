# Edge: 默认参数求值时机

# 默认参数在函数定义时求值
x = 10

def f(a=x):
    return a

print(f())                    # 10

x = 20
print(f())                    # 10 (已被捕获，不受后续 x 变化影响)

# 可变默认参数的陷阱（Python 行为）
def g(lst=[]):
    lst.append(1)
    return lst

print(g())                    # [1]
print(g())                    # [1, 1] (同一个列表对象!)
print(g())                    # [1, 1, 1]

print("done")