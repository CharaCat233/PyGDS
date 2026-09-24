# Feature: try / else 子句 (else 体正常结束时执行, 其异常不被本 try 捕获)

try:
    x = 1
except ValueError:
    print('exc')
else:
    print('else')

try:
    x = 1
except ValueError:
    print('exc2')
else:
    print('else2')
finally:
    print('fin2')

try:
    raise ValueError('boom')
except ValueError:
    print('caught')
else:
    print('not-reached')
finally:
    print('fin3')

def f():
    try:
        return 'ret'
    except ValueError:
        pass
    else:
        print('else-not-on-return')
    finally:
        print('fin-on-return')
print(f())

try:
    v = 10
except ValueError:
    pass
else:
    v += 5
print(v)

try:
    try:
        pass
    except ValueError:
        pass
    else:
        raise ValueError('inner-else')
except ValueError as e:
    print('outer caught:', e)

print('done')
