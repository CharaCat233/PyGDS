# 职责: 列表推导式与生成器表达式带过滤
# 比对: same_output


def print_list(lst: list) -> None:
    print(lst)


ls = [n for n in range(5) if n % 2 == 0]
print(ls)  # [0, 2, 4]

print_list([n for n in range(10) if n % 2 == 0])  # [0, 2, 4, 6, 8]

generator = (n for n in range(5) if n % 2 == 0)
print([n for n in generator])  # [0, 2, 4]
