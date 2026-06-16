# Sugar: 推导式 (list / dict / generator)

def foo(py_generator) -> None:
    print(py_generator)  # Python: <generator object <genexpr> at 0x0000000000000000>


def print_list(lst: list) -> None:
    print(lst)


ls = [n for n in range(5) if n % 2 == 0]
print(ls)  # [0, 2, 4]

dt = {n - 2: n * 2 for n in [n for n in range(5) if n % 2 == 0] if n % 2 == 0}
print(dt)  # {-2: 0, 0: 4, 2: 8}

print_list([n for n in range(10) if n % 2 == 0])  # [0, 2, 4, 6, 8]

generator = (n for n in range(5) if n % 2 == 0)
print([n for n in generator])  # [0, 2, 4]

# foo(n for n in range(5) if n % 2 == 0)  # DSL - 在函数调用时未显示声明会造成语法异常
