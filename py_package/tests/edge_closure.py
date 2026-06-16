# Edge: 闭包捕获

def make_adder(n):
    def adder(x):
        return x + n
    return adder

add5 = make_adder(5)
print(add5(10))               # 15

add7 = make_adder(7)
print(add7(10))               # 17
print(add5(10))               # 15 (独立闭包)

# 闭包修改 nonlocal
def counter():
    count = 0
    def inc():
        nonlocal count
        count = count + 1
        return count
    return inc

c = counter()
print(c())                    # 1
print(c())                    # 2
print(c())                    # 3

# 多个闭包共享环境
def make_counters():
    count = 0
    def inc():
        nonlocal count
        count = count + 1
        return count
    def dec():
        nonlocal count
        count = count - 1
        return count
    return inc, dec

inc_fn, dec_fn = make_counters()
print(inc_fn())               # 1
print(inc_fn())               # 2
print(dec_fn())               # 1

print("done")