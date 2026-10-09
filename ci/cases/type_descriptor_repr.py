# 职责: method_descriptor / wrapper_descriptor 的 repr 归属类名 (I2-72)
# 比对: same_output

# 方法描述符 repr 显示定义类型名 (str.upper → of 'str' objects), 不再为 ?? 占位;
# 异常类 __init__ 按类型名、__str__/__repr__ 归 BaseException, object 描述符归 object

print(str(str.upper))
print(str(int.bit_length))
print(str(list.append))
print(str(dict.get))
print(str(bytes.upper))
print(str(float.__eq__))
print(str(str.__add__))
print(str(int.__eq__))
print(str(list.__len__))
print(str(Exception.__str__))
print(str(ValueError.__init__))
print(str(object.__init__))
print(repr(str.upper))
