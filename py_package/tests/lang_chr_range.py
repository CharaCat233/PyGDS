# chr() 与 %c 越界明确报错

print(chr(65), chr(True), chr(97))
try:
    print(chr(1114112))
except ValueError as e:
    print('VE1')
try:
    print(chr(-1))
except ValueError as e:
    print('VE2')
try:
    print('%c' % 1114112)
except OverflowError as e:
    print('OE1')
try:
    print('%c' % -1)
except OverflowError as e:
    print('OE2')
print('%c' % 65)
