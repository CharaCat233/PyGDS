# Edge: abs / min / max / sum

print(abs(-5))               # 5
print(abs(5))                # 5
print(abs(-3.14))            # 3.14
print(abs(0))                # 0

print(min(1, 2, 3))          # 1
print(min(3, 2, 1))          # 1
print(min([5, 3, 9]))        # 3
print(max(1, 2, 3))          # 3
print(max(3, 2, 1))          # 3
print(max([5, 3, 9]))        # 9

print(sum([1, 2, 3]))        # 6
print(sum([1, 2, 3], 10))    # 16
print(sum([]))               # 0
print(sum([], 5))            # 5

print("done")