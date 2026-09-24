# Feature: format 的千位分隔符 (, 与 _)

print('{:,}'.format(1234567))
print('{:_}'.format(1234567))
print('{:,}'.format(1234567.891))
print('{:,.2f}'.format(1234567.891))
print('{:>10,}'.format(12345))
print('{:+010,}'.format(1234567))
print('{:,d}'.format(1234567))
print('{:,}'.format(True))
print('{:_x}'.format(-48879))
print('{:_b}'.format(255))
print('{:_o}'.format(65535))
try:
    print('{:,x}'.format(255))
except ValueError:
    print('VE1')
try:
    print('{:,_}'.format(1234))
except ValueError:
    print('VE2')
try:
    print('{:,}'.format('abc'))
except ValueError:
    print('VE3')
x = 1234567
print(f'{x:,}')
print(f'{255:_b}')
print(f'{1234567.891:,.2f}')
