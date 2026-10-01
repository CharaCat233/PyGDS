# 职责: global 与 nonlocal 声明改写外层变量
# 比对: same_output


def outer():
    y = 2

    def inner():
        nonlocal y
        y = 3

    inner()
    print(y)  # 3


def change_global():
    global y
    y = 100


y = 1
print(y)  # 1
outer()  # 3
print(y)  # 1
change_global()
print(y)  # 100
