# Edge: 递归深度

def factorial(n):
    if n <= 1:
        return 1
    return n * factorial(n - 1)

print(factorial(5))           # 120
print(factorial(10))          # 3628800

# 相互递归
def is_even(n):
    if n == 0:
        return True
    return is_odd(n - 1)

def is_odd(n):
    if n == 0:
        return False
    return is_even(n - 1)

print(is_even(10))            # True
print(is_even(11))            # False
print(is_odd(10))             # False
print(is_odd(11))             # True

print("done")