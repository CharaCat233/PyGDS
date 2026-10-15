# 职责: global 声明后置（名字先被使用）触发编译期 SyntaxError
# 比对: same_error

x = 1
print(x)
global x
