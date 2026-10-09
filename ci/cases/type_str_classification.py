# 职责: str 字符分类的 Unicode 码位全码段 (isdecimal/isdigit/isnumeric/isprintable/isspace, I2-74)
# 比对: same_output

# Nd 全码段、digit-type 附加、No+Nl 与 CJK 数字表意字、Cf 格式符、Zs 空白
# 均按 CPython 对齐; 未分配 (Cn) 码位的 isprintable 判定为平台残余 (P4)

def t(label, ch):
    print(label, ch.isdecimal(), ch.isdigit(), ch.isnumeric(), ch.isprintable(), ch.isspace())


# Nd 十进制数字 (isdecimal/is digit True)
t("arabic-indic", "\u0660")
t("bengali", "\u09e6")
t("tamil", "\u0be6")
t("tibetan", "\u0f20")
t("fullwidth", "\uff11")
t("math-double", "\U0001d7ce")

# digit-type 附加 (isdigit True, isdecimal False)
t("super-2", "\u00b2")
t("super-0", "\u2070")
t("sub-5", "\u2085")
t("circled-3", "\u2462")

# No/Nl (isnumeric True)
t("vulgar-1-4", "\u00bc")
t("roman-100", "\u2169")
t("number-circle", "\U0001f100")

# CJK 数字表意字 (Lo 带 Numeric_Type, isnumeric True)
t("cjk-yi", "\u4e00")
t("cjk-shi", "\u5341")

# Cf 格式符 (isprintable False)
t("soft-hyphen", "\u00ad")
t("arabic-letter-mark", "\u061c")
t("mongolian-vowel", "\u180e")
t("word-joiner", "\u2060")

# Zs 空白 (isspace True, isprintable False, 空格例外)
t("nbsp", "\u00a0")
t("em-space", "\u2003")
t("space", " ")

# 常规
t("ascii-5", "5")
t("ascii-a", "a")
