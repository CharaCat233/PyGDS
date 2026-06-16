# Keyword: global, nonlocal

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
