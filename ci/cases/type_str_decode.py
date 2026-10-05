# 职责: str(object, encoding, errors) 编码解码路径与类型校验 (I2-58)
# 比对: same_output
# 锚定: CPython 3.12


def t(label, fn):
    try:
        print(label + ":", repr(fn()))
    except Exception as e:
        print(label, type(e).__name__, ":", e)


# encoding 给定且输入为 bytes: 复用解码机制 (与 bytes.decode 同错误通道)
t("decode_utf8", lambda: str(b"abc", "utf-8"))
t("decode_ascii", lambda: str(b"abc", "ascii"))
t("decode_latin1", lambda: str(b"abc", "latin-1"))
t("decode_bytearray", lambda: str(bytearray(b"ab"), "utf-8"))
t("decode_kw", lambda: str(b"ab", encoding="utf-8"))
t("decode_errors_ignore", lambda: str(bytes([0xff, 0x61]), "utf-8", "ignore"))
t("decode_errors_replace", lambda: str(bytes([0xff, 0x61]), "utf-8", "replace"))
t("decode_errors_kw_only", lambda: str(b"ab", errors="strict"))
t("decode_unknown_enc", lambda: str(b"ab", "bogus"))
t("decode_bad_utf8", lambda: str(bytes([0xff]), "utf-8"))

# encoding 给定且输入为 str: CPython 明确拒绝解码
t("str_input", lambda: str("C", "utf-8"))
t("str_input_3", lambda: str("C", "utf-8", "strict"))

# encoding 给定且输入为其他类型: 报 bytes-like 文案
t("int_input", lambda: str(123, "utf-8"))
t("none_input", lambda: str(None, encoding="utf-8"))

# encoding / errors 类型校验: 给定即须为 str, 显式 None 同样拒绝
t("enc_tuple", lambda: str("C", (), {}))
t("enc_int", lambda: str(1, 2, 3))
t("enc_none", lambda: str("C", None))
t("err_tuple", lambda: str("C", "utf-8", ()))

# 参数个数: 位置 + 关键字合计, 上限 3
t("four_pos", lambda: str(1, 2, 3, 4))
t("three_pos_kw", lambda: str("C", "u", "s", errors="x"))

# 同名参数以名称与位置重复给定
t("dup_object", lambda: str("C", object=1))
t("dup_encoding", lambda: str("C", "utf-8", encoding="ascii"))

# 未知关键字与 object 关键字形态
t("kw_bogus", lambda: str("C", bogus=1))
t("kw_object", lambda: str(object=5))

# 未给待转换值时直接返回空串 (即便 encoding 已给定)
t("enc_only", lambda: str(encoding="utf-8"))
t("err_only", lambda: str(errors="strict"))

# str 子类走同一解码路径, 结果携带子类标记


class S(str):
    pass


t("sub_decode", lambda: S(b"ab", "utf-8"))
t("sub_decode_type", lambda: type(S(b"ab", "utf-8")).__name__)
t("sub_str_input", lambda: S("C", "utf-8"))
t("sub_obj_kw", lambda: S(object=5))
t("sub_plain", lambda: S("C"))

# 常规形态不受影响
t("plain", lambda: str(()))
t("empty", lambda: str())
t("bytes_bare", lambda: str(b"abc"))
