class_name PyGDS
extends Node

## Token 类型
enum TokenType {
	PLUS, MINUS, STAR, SLASH, DOUBLESLASH, STARSTAR, PERCENT, DOT,
	EQUAL, GREATER, LESS, BANG, PIPE, BITAND, LESS_LESS, GREATER_GREATER, CARET, TILDE,
	LPAREN, RPAREN, LBRACKET, RBRACKET,
	LBRACE, RBRACE, COMMA, COLON, NEWLINE,
	EQUAL_EQUAL, NOT_EQUAL, GREATER_EQUAL, LESS_EQUAL,
	IDENTIFIER, STRING, FSTRING, INTEGER, FLOAT,
	IF, ELIF, ELSE, WHILE, FOR, IN, ASSERT, LAMBDA,
	AND, OR, NOT, TRUE, FALSE,
	DEF, CLASS, RETURN, BREAK, CONTINUE, PASS,
	GLOBAL, NONLOCAL, DEL, IMPORT, FROM,
	INDENT, DEDENT, EOF,
	AT, NULL,
	TRY, EXCEPT, FINALLY, RAISE, AS,
	PLUS_EQ, MINUS_EQ, STAR_EQ, SLASH_EQ, DOUBLESLASH_EQ, STARSTAR_EQ, PERCENT_EQ,
	PIPE_EQ, IS, IS_NOT, NOT_IN, COLON_EQ,
	YIELD,
	ASYNC, AWAIT
}

## Token
class Token:
	## Token 类型
	var type: TokenType
	## 原始字符
	var lexeme: String
	## 字面量 (整数, 浮点数, 字符串等)
	var literal: Variant
	## 所在行
	var line: int
	## 所在列
	var column: int
	
	## 构造 Token [br]
	## [param p_type] Token 类型 [br]
	## [param p_lexeme] 原始字符串 [br]
	## [param p_literal] 字面量 [br]
	## [param p_line] 所在行 [br]
	## [param p_column] 所在列
	func _init(p_type, p_lexeme, p_literal, p_line, p_column):
		type = p_type
		lexeme = p_lexeme
		literal = p_literal
		line = p_line
		column = p_column

## 词法分析, 将源代码字符串转换为 Token 列表 (支持缩进, 三引号字符串, # 注释)
class Lexer:
	## 控制台报告器
	var report: ConsoleReport
	## 源代码
	var source: String
	## Token 列表
	var tokens: Array = []
	## 当前词素的起始位置
	var start: int = 0
	## 当前扫描位置
	var current: int = 0
	## 当前行号
	var line: int = 1
	## 当前列号
	var column: int = 1
	## 缩进, 用于生成 INDENT/DEDENT
	var indent_stack: Array = [0]
	## 是否处于行首 (用于处理缩进)
	var at_line_start: bool = true
	
	## 关键字映射
	static var keywords = {
		"if": TokenType.IF, "elif": TokenType.ELIF, "else": TokenType.ELSE,
		"while": TokenType.WHILE, "for": TokenType.FOR, "in": TokenType.IN,
		"assert": TokenType.ASSERT,
		"and": TokenType.AND, "or": TokenType.OR, "pass": TokenType.PASS,
		"not": TokenType.NOT,
		"True": TokenType.TRUE, "False": TokenType.FALSE,
		"None": TokenType.NULL,
		"def": TokenType.DEF, "class": TokenType.CLASS, "return": TokenType.RETURN,
		"break": TokenType.BREAK, "continue": TokenType.CONTINUE,
		"global": TokenType.GLOBAL, "nonlocal": TokenType.NONLOCAL, "del": TokenType.DEL,
		"import": TokenType.IMPORT, "from": TokenType.FROM,
		"try": TokenType.TRY, "except": TokenType.EXCEPT, "finally": TokenType.FINALLY,
		"raise": TokenType.RAISE, "as": TokenType.AS,
		"lambda": TokenType.LAMBDA,
		"is": TokenType.IS,
		"yield": TokenType.YIELD,
		"async": TokenType.ASYNC, "await": TokenType.AWAIT
	}
	
	## 构造词法分析器 [br]
	## [param p_reporter] 控制台报告器实例 [br]
	## [param p_source] 待扫描的源代码字符串
	func _init(p_reporter: ConsoleReport, p_source: String):
		report = p_reporter
		source = p_source
	
	## 启动扫描, 返回 Token 列表
	func scan() -> Array:
		while not is_at_end() and not report.has_error:
			start = current
			scan_token()
		# 在文件末尾生成剩余的 DEDENT
		while indent_stack.size() > 1:
			indent_stack.pop_back()
			tokens.append(Token.new(TokenType.DEDENT, "", null, line, column))
		tokens.append(Token.new(TokenType.EOF, "", null, line, column))
		return tokens
		
	## 判断是否处于文件末尾
	func is_at_end() -> bool:
		return current >= source.length()
		
	## 前进一个字符并返回该字符
	func advance() -> String:
		var c = source[current]
		current += 1
		column += 1
		return c
		
	## 查看当前字符, 与 [method Lexer.advance] 不同的是其不会导致指针前进
	func peek() -> String:
		return "" if is_at_end() else source[current]
		
	## 查看下一个字符
	func peek_next() -> String:
		return "" if current + 1 >= source.length() else source[current + 1]
	
	## 查看下下个字符 (不前进) [br]
	## [returns] 下下个字符, 越界时返回空串
	func peek_next_next() -> String:
		return "" if current + 2 >= source.length() else source[current + 2]
	
	## 如果当前字符匹配预期, 则前进并返回 true, 否则返回 false
	func match_char(expected: String) -> bool:
		if is_at_end() or source[current] != expected:
			return false
		current += 1
		column += 1
		return true
		
	## 添加一个 Token
	func add_token(type: TokenType, literal: Variant = null):
		var text = source.substr(start, current - start)
		tokens.append(Token.new(type, text, literal, line, column - (current - start)))
		
	## 处理行首缩进, 生成 INDENT DEDENT
	func handle_indent():
		var spaces = 0
		const TAB_SIZE = 8
		while peek() == ' ' or peek() == '\t':
			if peek() == ' ':
				spaces += 1
			else:
				spaces += TAB_SIZE
			advance()
		start = current
		if peek() == '\n':
			return
		var top = indent_stack.back()
		if spaces > top:
			indent_stack.append(spaces)
			tokens.append(Token.new(TokenType.INDENT, "", null, line, column))
		elif spaces < top:
			while indent_stack.size() > 1 and indent_stack.back() > spaces:
				indent_stack.pop_back()
				tokens.append(Token.new(TokenType.DEDENT, "", null, line, column))
			if indent_stack.back() != spaces:
				report.error("Inconsistent indentation at line %d" % line)
				
	## 扫描一个 Token
	func scan_token():
		if at_line_start:
			handle_indent()
			at_line_start = false
		var c = advance()
		match c:
			'.': add_token(TokenType.DOT)
			'+':
				if match_char('='):
					add_token(TokenType.PLUS_EQ)
				else:
					add_token(TokenType.PLUS)
			'-':
				if match_char('='):
					add_token(TokenType.MINUS_EQ)
				else:
					add_token(TokenType.MINUS)
			'@': add_token(TokenType.AT)
			'*':
				if match_char('*'):
					if match_char('='):
						add_token(TokenType.STARSTAR_EQ)
					else:
						add_token(TokenType.STARSTAR)
				elif match_char('='):
					add_token(TokenType.STAR_EQ)
				else:
					add_token(TokenType.STAR)
			'/':
				if match_char('/'):
					if match_char('='):
						add_token(TokenType.DOUBLESLASH_EQ)
					else:
						add_token(TokenType.DOUBLESLASH)
				elif match_char('='):
					add_token(TokenType.SLASH_EQ)
				else:
					add_token(TokenType.SLASH)
			'%':
				if match_char('='):
					add_token(TokenType.PERCENT_EQ)
				else:
					add_token(TokenType.PERCENT)
			'&': add_token(TokenType.BITAND)
			'|':
				if match_char('='):
					add_token(TokenType.PIPE_EQ)
				else:
					add_token(TokenType.PIPE)
			'(': add_token(TokenType.LPAREN)
			')': add_token(TokenType.RPAREN)
			'[': add_token(TokenType.LBRACKET)
			']': add_token(TokenType.RBRACKET)
			'{': add_token(TokenType.LBRACE)
			'}': add_token(TokenType.RBRACE)
			',': add_token(TokenType.COMMA)
			':':
				if match_char('='):
					add_token(TokenType.COLON_EQ)
				else:
					add_token(TokenType.COLON)
			' ', '\t', '\r': pass
			'\n':
				add_token(TokenType.NEWLINE)
				line += 1
				column = 1
				at_line_start = true
			'=':
				if match_char('='):
					add_token(TokenType.EQUAL_EQUAL)
				else:
					add_token(TokenType.EQUAL)
			'!':
				if match_char('='):
					add_token(TokenType.NOT_EQUAL)
				else:
					add_token(TokenType.BANG)
			'>':
				if match_char('>'):
					add_token(TokenType.GREATER_GREATER)
				elif match_char('='):
					add_token(TokenType.GREATER_EQUAL)
				else:
					add_token(TokenType.GREATER)
			'<':
				if match_char('<'):
					add_token(TokenType.LESS_LESS)
				elif match_char('='):
					add_token(TokenType.LESS_EQUAL)
				else:
					add_token(TokenType.LESS)
			'^': add_token(TokenType.CARET)
			'~': add_token(TokenType.TILDE)
			'#':
				while peek() != '\n' and not is_at_end():
					advance()
			'"', "'": string(c)
			_:
				if c.is_valid_int() or (c == '.' and peek().is_valid_int()):
					number()
				elif c.is_valid_identifier() or c == '_':
					identifier()
				else:
					report.error("Unexpected character '%s' at line %d, col %d" % [c, line, column])
	
	## 扫描字符串字面量
	func string(quote_char: String):
		# 检查是否为三引号
		if peek() == quote_char and peek_next() == quote_char:
			advance()
			advance()
			var content_start = current
			while not is_at_end():
				# 安全检测连续的三个引号
				if peek() == quote_char and peek_next() == quote_char:
					# 暂存当前位置, 用于超前查看第三个引号
					var saved = current
					advance()
					advance()
					if not is_at_end() and peek() == quote_char:
						advance()
						add_token(TokenType.STRING, _unescape_string(source.substr(content_start, current - content_start - 3)))
						return
					else:
						# 回退 saved 位置继续扫描
						current = saved
				# 处理换行, 更新行号和列号
				if peek() == '\n':
					line += 1
					column = 1
				advance()
			report.error("Unterminated triple-quoted string at line %d" % line)
			return
			
		# 普通单行字符串
		while peek() != quote_char and not is_at_end():
			if peek() == '\n':
				line += 1
				column = 1
			advance()
		if is_at_end():
			report.error("Unterminated string at line %d" % line)
			return
		# 跳过结束引号
		advance()
		var value = _unescape_string(source.substr(start + 1, current - start - 2))
		add_token(TokenType.STRING, value)
	
	## 将字符串中的转义序列还原为实际字符 [br]
	## 支持 \n, \t, \r, \\, \", \' 等常见转义序列 [br]
	## [param s] 包含转义序列的原始字符串 [br]
	## [param is_raw] 是否为原始字符串 (r 前缀, 不做转义) [br]
	## [returns] 转义后的字符串
	func _unescape_string(s: String, is_raw: bool = false) -> String:
		if is_raw:
			return s
		var result = ""
		var i = 0
		while i < s.length():
			var ch = s[i]
			if ch == '\\' and i + 1 < s.length():
				i += 1
				var next_ch = s[i]
				match next_ch:
					'n': result += '\n'
					't': result += '\t'
					'r': result += '\r'
					'\\': result += '\\'
					'"': result += '"'
					"'": result += "'"
					_: result += '\\' + next_ch
			else:
				result += ch
			i += 1
		return result
		
	## 扫描数字字面量 (十进制/十六进制/八进制/二进制, 支持下划线分隔与科学计数法)
	func number():
		# 十六进制 0x/0X
		if (peek() == 'x' or peek() == 'X') and start + 1 < source.length() and source[start] == '0':
			advance()
			var digits = ""
			while peek() != '' and (peek().to_lower() in "0123456789abcdef" or peek() == '_'):
				if peek() != '_':
					digits += peek()
				advance()
			if digits == "":
				report.error("Invalid hex literal at line %d" % line)
				return
			add_token(TokenType.INTEGER, _digits_to_int(digits, 16))
			return
		# 八进制 0o/0O
		if (peek() == 'o' or peek() == 'O') and start + 1 < source.length() and source[start] == '0':
			advance()
			var digits = ""
			while peek() != '' and (peek() in "01234567" or peek() == '_'):
				if peek() != '_':
					digits += peek()
				advance()
			if digits == "":
				report.error("Invalid octal literal at line %d" % line)
				return
			add_token(TokenType.INTEGER, _digits_to_int(digits, 8))
			return
		# 二进制 0b/0B
		if (peek() == 'b' or peek() == 'B') and start + 1 < source.length() and source[start] == '0':
			advance()
			var digits = ""
			while peek() != '' and (peek() in "01" or peek() == '_'):
				if peek() != '_':
					digits += peek()
				advance()
			if digits == "":
				report.error("Invalid binary literal at line %d" % line)
				return
			add_token(TokenType.INTEGER, _digits_to_int(digits, 2))
			return
		# 十进制 (支持下划线)
		# 注意: 首个字符已被 scan_token 的 advance() 消费, 需从 source[start] 补回
		var int_part = ""
		if start < source.length() and source[start].is_valid_int():
			int_part += source[start]
		while peek() != '' and (peek().is_valid_int() or peek() == '_'):
			if peek() != '_':
				int_part += peek()
			advance()
		var mantissa = int_part
		var is_float = false
		if peek() == '.' and peek_next().is_valid_int():
			is_float = true
			advance()
			mantissa += "."
			while peek() != '' and (peek().is_valid_int() or peek() == '_'):
				if peek() != '_':
					mantissa += peek()
				advance()
		# 科学计数法 1e5 / 1.5e-3
		var exponent = ""
		if peek() == 'e' or peek() == 'E':
			is_float = true
			advance()
			if peek() == '+' or peek() == '-':
				exponent += peek()
				advance()
			while peek() != '' and (peek().is_valid_int() or peek() == '_'):
				if peek() != '_':
					exponent += peek()
				advance()
		if is_float:
			var full = mantissa
			if exponent != "":
				full += "e" + exponent
			add_token(TokenType.FLOAT, float(full))
		else:
			add_token(TokenType.INTEGER, int(int_part))

	## 将指定进制的数字字符串转换为整数 [br]
	## [param digits] 数字字符 (不含前缀与下划线) [br]
	## [param base] 进制 (2/8/16) [br]
	## [returns] 转换结果
	func _digits_to_int(digits: String, base: int) -> int:
		var result = 0
		for ch in digits:
			var v = 0
			if ch.is_valid_int():
				v = int(ch)
			else:
				v = ch.to_lower().unicode_at(0) - 97 + 10
			result = result * base + v
		return result
		
	## 扫描标识符或关键字
	func identifier():
		while peek().is_valid_identifier() or peek().is_valid_int():
			advance()
		var text = source.substr(start, current - start)
		# 字符串前缀 (f/r/b/u 及组合) 后跟引号 → 扫描带前缀字符串
		if _is_string_prefix(text) and (peek() == '"' or peek() == "'"):
			scan_prefixed_string(text)
			return
		var type = keywords.get(text, TokenType.IDENTIFIER)
		if type == TokenType.TRUE:
			add_token(type, true)
		elif type == TokenType.FALSE:
			add_token(type, false)
		elif type == TokenType.NULL:
			add_token(type, null)
		else:
			add_token(type, text)

	## 判断标识符是否为字符串前缀 (f/r/b/u 及其组合) [br]
	## [param text] 标识符文本 [br]
	## [returns] 是否可作为字符串前缀
	func _is_string_prefix(text: String) -> bool:
		var prefixes = ["f", "F", "r", "R", "b", "B", "u", "U",
			"rf", "rF", "Rf", "RF", "fr", "Fr", "fR", "FR",
			"rb", "rB", "Rb", "RB", "br", "Br", "bR", "BR"]
		return prefixes.has(text)

	## 扫描带前缀的字符串字面量 (f-string / raw / bytes) [br]
	## [param prefix] 前缀文本 (如 "f", "rf")
	func scan_prefixed_string(prefix: String):
		var is_fstring = prefix.find("f") != -1 or prefix.find("F") != -1
		var is_raw = prefix.find("r") != -1 or prefix.find("R") != -1
		var quote_char = peek()
		# 三引号判定: 须连续三个引号才是三引号字符串
		# (只判前两个会把 b"" 这类空字面量误判为三引号起始, 导致报未闭合)
		var triple = peek() == quote_char and peek_next() == quote_char and peek_next_next() == quote_char
		advance()
		if triple:
			advance()
			advance()
			var content_start = current
			while not is_at_end():
				if peek() == quote_char and peek_next() == quote_char:
					var saved = current
					advance()
					advance()
					if not is_at_end() and peek() == quote_char:
						advance()
						var raw_body = source.substr(content_start, current - content_start - 3)
						var is_bytes3 = prefix.find("b") != -1 or prefix.find("B") != -1
						if is_fstring:
							add_token(TokenType.FSTRING, _scan_fstring_parts(raw_body, quote_char, is_raw))
						elif is_bytes3:
							var text_body3 = _unescape_string(raw_body, is_raw)
							var bytes_out3: Array[int] = []
							for bi in range(text_body3.length()):
								var code3 = text_body3.unicode_at(bi)
								if code3 > 255:
									report.error("SyntaxError: bytes can only contain ASCII literal characters")
									return
								bytes_out3.append(code3)
							add_token(TokenType.STRING, DSLBytes.new(bytes_out3))
						else:
							add_token(TokenType.STRING, _unescape_string(raw_body, is_raw))
						return
					else:
						current = saved
				if peek() == '\n':
					line += 1
					column = 1
				advance()
			report.error("Unterminated triple-quoted string at line %d" % line)
			return

		# 单行字符串
		while peek() != quote_char and not is_at_end():
			if peek() == '\n':
				line += 1
				column = 1
			advance()
		if is_at_end():
			report.error("Unterminated string at line %d" % line)
			return
		advance()
		var body_start = start + prefix.length() + 1
		var raw_body = source.substr(body_start, current - body_start - 1)
		var is_bytes = prefix.find("b") != -1 or prefix.find("B") != -1
		if is_fstring:
			add_token(TokenType.FSTRING, _scan_fstring_parts(raw_body, quote_char, is_raw))
		elif is_bytes:
			# b"..." 字面量: 转义后按字节值收集 (非 ASCII 字符报错, 与 CPython 一致)
			var text_body = _unescape_string(raw_body, is_raw)
			var bytes_out: Array[int] = []
			for i in range(text_body.length()):
				var code = text_body.unicode_at(i)
				if code > 255:
					report.error("SyntaxError: bytes can only contain ASCII literal characters")
					return
				bytes_out.append(code)
			add_token(TokenType.STRING, DSLBytes.new(bytes_out))
		else:
			add_token(TokenType.STRING, _unescape_string(raw_body, is_raw))

	## 扫描 f-string 主体, 拆分为字面量片段与替换字段 [br]
	## 返回 parts 数组, 每个元素为 {"is_literal": bool, "text": String, "expr": String, "conv": String, "fmt": String} [br]
	## [param body] 引号之间的原始内容 [br]
	## [param quote_char] 引号字符 [br]
	## [param is_raw] 是否原始字符串 [br]
	## [returns] parts 数组
	func _scan_fstring_parts(body: String, _quote_char: String, is_raw: bool) -> Array:
		var parts: Array = []
		var lit = ""
		var i = 0
		while i < body.length():
			var ch = body[i]
			if ch == '{':
				# 转义的 {{ → 字面 {
				if i + 1 < body.length() and body[i + 1] == '{':
					lit += '{'
					i += 2
					continue
				if lit != "":
					parts.append({"is_literal": true, "text": _unescape_string(lit, is_raw), "expr": null, "conv": "", "fmt": ""})
					lit = ""
				i += 1
				var field = _scan_fstring_field(body, i)
				if field == null:
					return [ {"is_literal": true, "text": "", "expr": null, "conv": "", "fmt": ""}]
				parts.append({"is_literal": false, "text": "", "expr": field.expr, "conv": field.conv, "fmt": field.fmt, "debug": field.get("debug", false)})
				i = field.end
			elif ch == '}':
				if i + 1 < body.length() and body[i + 1] == '}':
					lit += '}'
					i += 2
					continue
				report.error("f-string: single '}' is not allowed")
				return [ {"is_literal": true, "text": "", "expr": null, "conv": "", "fmt": ""}]
			else:
				lit += ch
				i += 1
		if lit != "":
			parts.append({"is_literal": true, "text": _unescape_string(lit, is_raw), "expr": null, "conv": "", "fmt": ""})
		return parts

	## 扫描 f-string 中的一个替换字段 {expr[!conv][:fmt]} [br]
	## 从开括号后一位开始, 正确处理嵌套花括号与字段内字符串字面量 [br]
	## [param body] f-string 主体 [br]
	## [param start] 开括号后一位的索引 [br]
	## [returns] {"expr": String, "conv": String, "fmt": String, "end": int}
	func _scan_fstring_field(body: String, start: int) -> Dictionary:
		var expr_src = ""
		var conv = ""
		var fmt = ""
		var debug = false
		var i = start
		var depth = 1
		while i < body.length():
			var ch = body[i]
			if ch == '"' or ch == "'":
				var skip = _skip_string_literal(body, i)
				expr_src += body.substr(i, skip - i)
				i = skip
				continue
			if ch == '{':
				depth += 1
				expr_src += ch
				i += 1
				continue
			if ch == '}':
				depth -= 1
				if depth == 0:
					# 转换标志 (!r/!s/!a) 与格式说明符 (:fmt) 已在花括号内部解析
					# 闭括号后遇到 ! 或 : 属于字段之外的普通文本, 原样保留
					# 表达式末尾的单个 "=" 为调试说明符 (f"{x=}"), 排除 ==/!=/>=/<=
					var strip = _strip_debug_eq(expr_src)
					expr_src = strip[0]
					debug = strip[1]
					return {"expr": expr_src, "conv": conv, "fmt": fmt, "end": i + 1, "debug": debug}
			if ch == '!' and depth == 1:
				if i + 1 < body.length():
					conv = body[i + 1]
					i += 2
					continue
				i += 1
				continue
			if ch == ':' and depth == 1:
				i += 1
				var fmt_start = i
				var fmt_depth = 0
				while i < body.length():
					var fc = body[i]
					if fc == '{':
						fmt_depth += 1
					elif fc == '}':
						if fmt_depth == 0:
							break
						fmt_depth -= 1
					i += 1
				fmt = body.substr(fmt_start, i - fmt_start)
				if i < body.length() and body[i] == '}':
					i += 1
				# 表达式末尾的单个 "=" 为调试说明符 (f"{x=:spec}")
				var strip = _strip_debug_eq(expr_src)
				expr_src = strip[0]
				debug = strip[1]
				return {"expr": expr_src, "conv": conv, "fmt": fmt, "end": i, "debug": debug}
			expr_src += ch
			i += 1
		report.error("f-string: unterminated replacement field")
		return {"expr": expr_src, "conv": conv, "fmt": fmt, "end": body.length()}

	## 检测并剥离 f-string 表达式末尾的调试说明符 "=" [br]
	## 若表达式以单个 "=" 结尾 (且前一字符不是 =/!/</>), 则剥离并标记为调试模式 [br]
	## [param src] 表达式源码 [br]
	## [returns] [剥离后的源码, 是否为调试模式]
	func _strip_debug_eq(src: String) -> Array:
		if src.length() >= 2 and src.ends_with("="):
			var prev = src[src.length() - 2]
			if prev != "=" and prev != "!" and prev != "<" and prev != ">":
				return [src.substr(0, src.length() - 1), true]
		return [src, false]

	## 跳过字段表达式内的字符串字面量 (含三引号), 返回结束后的索引 [br]
	## [param body] 字段源码 [br]
	## [param start] 引号起始索引 [br]
	## [returns] 字符串结束后的索引
	func _skip_string_literal(body: String, start: int) -> int:
		var q = body[start]
		var i = start + 1
		if i + 1 < body.length() and body[i] == q and body[i + 1] == q:
			i += 2
			while i < body.length():
				if body[i] == q and i + 2 < body.length() and body[i + 1] == q and body[i + 2] == q:
					return i + 3
				i += 1
			return i
		while i < body.length():
			if body[i] == '\\':
				i += 2
				continue
			if body[i] == q:
				return i + 1
			i += 1
		return i

## AST 节点
class ASTNode:
	pass

## Statements 声明基类
class Stmt:
	## 语句所在源文件行号 (运行时错误定位用)
	var line: int = 0
	pass

## Expressions 声明基类
class Expr extends ASTNode:
	pass

## 星号目标 (仅用于最外层解包) [br]
## 在解包赋值中捕获剩余元素, 对应 Python 的 *target 语法
class StarredTarget:
	## 星号捕获的目标变量 (只能是 Variable)
	var target
	## 构造星号解包目标 [br]
	## [param t] 星号后跟随的 Variable 节点
	func _init(t: Variable):
		target = t

## 嵌套解包目标, 例如 (a, b) 或 [a, b] [br]
## 支持圆括号和方括号两种嵌套形式
class UnpackTarget:
	## 嵌套的目标列表, 元素为 Variable 或 UnpackTarget
	var targets: Array
	## 构造嵌套解包目标 [br]
	## [param t] 目标数组 (实际类型 Array[Variable | UnpackTarget])
	func _init(t: Array):
		targets = t

## 下标赋值目标, 例如 a[i] = v 或 (a[i], b[j]) = ... 中的 a[i] [br]
## 仅用于多重赋值/解包赋值的左侧目标 (单目标赋值由 SetItem 直接表达)
class SubscriptTarget:
	## 被索引的对象 (Expr, 或嵌套的 SubscriptTarget / AttrTarget)
	var object = null
	## 下标表达式 (可为 SliceExpr)
	var index = null
	## 构造下标目标 [br]
	## [param o] 对象表达式 [br]
	## [param i] 下标表达式
	func _init(o, i):
		object = o
		index = i

## 属性赋值目标, 例如 o.x = v 或 (o.x, o.y) = ... 中的 o.x [br]
## 仅用于多重赋值/解包赋值的左侧目标
class AttrTarget:
	## 宿主对象 (Expr, 或嵌套的 SubscriptTarget / AttrTarget)
	var object = null
	## 属性名
	var name: String
	## 构造属性目标 [br]
	## [param o] 宿主对象表达式 [br]
	## [param n] 属性名
	func _init(o, n: String):
		object = o
		name = n

## 星号解包表达式, 例如 [*a, 1] 或 (*a,) 中的 *a [br]
## 仅在列表/元组/集合字面量内出现, 求值时展开为多个元素
class StarredExpr extends Expr:
	## 被解包的表达式
	var value: Expr
	## 构造星号解包表达式 [br]
	## [param v] 被解包的表达式
	func _init(v: Expr):
		value = v

## 推导式循环子句, 例如 for x in a if cond [br]
## 一个推导式可包含多个子句, 按书写顺序嵌套迭代
class CompClause:
	## 循环目标变量名数组 (元组目标 for k, v in ... 时为多个名字)
	var targets: Array
	## 迭代对象表达式
	var iterable: Expr
	## 过滤条件表达式数组 (可为零个或多个 if 子句)
	var conditions: Array
	## 构造推导式循环子句 [br]
	## [param t] 目标变量名数组 (实际类型 Array[String]) [br]
	## [param i] 迭代对象表达式 [br]
	## [param c] 过滤条件表达式数组 (实际类型 Array[Expr])
	func _init(t: Array, i: Expr, c: Array):
		targets = t
		iterable = i
		conditions = c

## 字面量表达式 (整数, 浮点, 字符串, 布尔值, None) [br]
## 表示源代码中直接写出的常量值
class Literal extends Expr:
	## 字面量的实际值 (int/float/String/bool/null)
	var value
	## 构造字面量表达式 [br]
	## [param v] 字面量的实际值
	func _init(v):
		value = v

## 变量引用表达式 [br]
## 表示对已定义变量的名称引用, 解析时通过作用域链查找值
class Variable extends Expr:
	## 变量名称
	var name: String
	## 构造变量引用表达式 [br]
	## [param n] 变量名称字符串
	func _init(n):
		name = n

## 简单赋值表达式, 例如 x = value [br]
## 将右侧表达式的结果绑定到左侧变量名
class Assign extends Expr:
	## 被赋值的变量名
	var name: String
	## 赋值右侧的表达式
	var value: Expr
	## 构造赋值表达式 [br]
	## [param n] 变量名 [br]
	## [param v] 右侧表达式
	func _init(n, v):
		name = n
		value = v

## 增强赋值 (Augmented Assignment): x += 1, x -= 2, x *= 3, etc. [br]
## 将运算符与赋值合并, 如 += -= *= /= //= %= **=
class AugAssign extends Expr:
	## 变量名
	var name: String
	## 运算符 Token (如 TokenType.PLUS_EQ)
	var operator: Token
	## 右侧表达式
	var value: Expr
	## 构造增强赋值表达式 [br]
	## [param n] 变量名 [br]
	## [param o] 运算符 Token [br]
	## [param v] 右侧表达式
	func _init(n, o, v):
		name = n
		operator = o
		value = v

## 增强赋值, 属性形式: obj.attr += 1 [br]
## 对对象的属性进行增强赋值操作
class AugAssignAttr extends Expr:
	## 对象表达式
	var object: Expr
	## 属性名
	var name: String
	## 运算符 Token
	var operator: Token
	## 右侧表达式
	var value: Expr
	## 构造增强属性赋值 [br]
	## [param o] 对象表达式 [br]
	## [param n] 属性名 [br]
	## [param op] 运算符 Token [br]
	## [param v] 右侧表达式
	func _init(o, n, op, v):
		object = o
		name = n
		operator = op
		value = v

## 增强赋值, 索引形式: arr[idx] += 1 [br]
## 对对象的索引元素进行增强赋值操作
class AugAssignItem extends Expr:
	## 对象表达式
	var object: Expr
	## 索引表达式
	var index: Expr
	## 运算符 Token
	var operator: Token
	## 右侧表达式
	var value: Expr
	## 构造增强索引赋值 [br]
	## [param o] 对象表达式 [br]
	## [param i] 索引表达式 [br]
	## [param op] 运算符 Token [br]
	## [param v] 右侧表达式
	func _init(o, i, op, v):
		object = o
		index = i
		operator = op
		value = v

## 切片与索引访问表达式, 例如 arr[start:stop:step] [br]
## 对容器对象的下标或切片访问操作
class SliceExpr extends Expr:
	## 切片起始表达式
	var start: Expr
	## 切片终止表达式
	var stop: Expr
	## 切片步长表达式, 可为 null
	var step: Expr
	## 构造切片表达式 [br]
	## [param s] 起始表达式 [br]
	## [param e] 终止表达式 [br]
	## [param st] 步长表达式, 默认为 null
	func _init(s, e, st = null):
		start = s
		stop = e
		step = st

## 索引访问表达式, 例如 arr[idx] [br]
## 对容器对象的指定下标位置获取值
class GetItem extends Expr:
	## 对象表达式
	var object: Expr
	## 索引表达式
	var index: Expr
	## 构造索引访问表达式 [br]
	## [param o] 对象表达式 [br]
	## [param i] 索引表达式
	func _init(o, i):
		object = o
		index = i

## 索引赋值表达式, 例如 arr[idx] = value [br]
## 对容器对象的指定下标位置设置值
class SetItem extends Expr:
	## 对象表达式 (也接受嵌套赋值目标 AttrTarget / SubscriptTarget)
	var object = null
	## 索引表达式
	var index: Expr
	## 待赋值的表达式
	var value: Expr
	## 构造索引赋值表达式 [br]
	## [param o] 对象表达式或嵌套赋值目标 [br]
	## [param i] 索引表达式 [br]
	## [param v] 右侧表达式
	func _init(o, i, v):
		object = o
		index = i
		value = v

## 比较链表达式, 例如 a < b < c
class CompareChainExpr extends Expr:
	## 左侧表达式
	var left: Expr
	## 比较运算符数组
	var ops: Array
	## 比较对象数组
	var comparators: Array
	## 构造比较链表达式 [br]
	## [param l] 左侧表达式 [br]
	## [param o] 比较运算符数组 [br]
	## [param c] 比较对象数组
	func _init(l, o, c):
		left = l
		ops = o
		comparators = c

## 二元运算表达式, 例如 a + b, a > b [br]
## 支持算术运算, 比较运算, 逻辑运算等所有双操作数运算
class Binary extends Expr:
	## 左侧表达式
	var left: Expr
	## 运算符 Token
	var operator: Token
	## 右侧表达式
	var right: Expr
	## 构造二元运算表达式 [br]
	## [param l] 左侧表达式 [br]
	## [param o] 运算符 Token [br]
	## [param r] 右侧表达式
	func _init(l, o, r):
		left = l
		operator = o
		right = r

## 一元运算表达式 (负号 -, 逻辑非 not) [br]
## 对单个操作数进行运算
class Unary extends Expr:
	## 运算符 Token
	var operator: Token
	## 右侧表达式 (操作数)
	var right: Expr
	## 构造一元运算表达式 [br]
	## [param o] 运算符 Token [br]
	## [param r] 右侧表达式
	func _init(o, r):
		operator = o
		right = r

## 属性访问表达式, 例如 obj.attr [br]
## 通过点操作符访问对象的属性
class GetAttr extends Expr:
	## 对象表达式
	var object: Expr
	## 属性名
	var name: String
	## 构造属性访问表达式 [br]
	## [param o] 对象表达式 [br]
	## [param n] 属性名
	func _init(o, n):
		object = o
		name = n

## 属性赋值表达式, 例如 obj.attr = value [br]
## 通过点操作符设置对象的属性值
class SetAttr extends Expr:
	## 对象表达式 (也接受嵌套赋值目标 AttrTarget / SubscriptTarget)
	var object = null
	## 属性名
	var name: String
	## 待赋值的表达式
	var value: Expr
	## 构造属性赋值表达式 [br]
	## [param o] 对象表达式 [br]
	## [param n] 属性名 [br]
	## [param v] 右侧表达式
	func _init(o, n, v):
		object = o
		name = n
		value = v

## 函数调用表达式, 例如 func(arg1, arg2, kw=val) [br]
## 支持位置参数和关键字参数
class Call extends Expr:
	## 被调用的表达式 (通常为 Variable 或 GetAttr)
	var callee_expr: Expr
	## 位置参数列表
	var arguments: Array[Expr] = []
	## 关键字参数列表
	var keyword_args: Array[KeywordArg] = []
	## 星号解包表达式列表 (*iterable)
	var star_args: Array[Expr] = []
	## 双星号解包表达式列表 (**mapping)
	var star_kwargs: Array[Expr] = []
	
	## 构造函数调用表达式 [br]
	## [param c] 被调用的表达式 [br]
	## [param a] 位置参数列表 [br]
	## [param kw] 关键字参数列表 [br]
	## [param sa] 星号解包表达式列表 [br]
	## [param skw] 双星号解包表达式列表
	func _init(c, a, kw = [], sa = [], skw = []):
		callee_expr = c
		arguments = a
		keyword_args = kw
		star_args = sa
		star_kwargs = skw

## 列表字面量表达式, 例如 [1, 2, 3] [br]
## 创建包含指定元素的列表
class ListLiteral extends Expr:
	## 列表元素表达式数组
	var elements: Array
	## 构造列表字面量 [br]
	## [param e] 元素表达式数组 (实际类型 Array[Expr])
	func _init(e):
		elements = e

## 元组字面量表达式, 例如 (1, 2, 3) [br]
## 创建包含指定元素的不可变元组
class TupleLiteral extends Expr:
	## 元组元素表达式数组
	var elements: Array
	## 构造元组字面量 [br]
	## [param e] 元素表达式数组 (实际类型 Array[Expr])
	func _init(e):
		elements = e

## 字典字面量表达式, 例如 {"key": value, ...} [br]
## 创建包含键值对的字典, 支持 **mapping 解包条目
class DictLiteral extends Expr:
	## 键表达式数组 (解包条目的键为 null)
	var keys: Array
	## 值表达式数组 (解包条目存解包表达式)
	var values: Array
	## 逐条目标记是否为 **mapping 解包
	var star_flags: Array = []
	## 构造字典字面量 [br]
	## [param k] 键表达式数组 (实际类型 Array[Expr]) [br]
	## [param v] 值表达式数组 (实际类型 Array[Expr]) [br]
	## [param s] 逐条目解包标记数组 (可省略)
	func _init(k, v, s = []):
		keys = k
		values = v
		star_flags = s

## set 字面量表达式, 例如 {1, 2, 3} [br]
## 解析时与字典字面量区分: 元素无冒号视为集合
class SetLiteral extends Expr:
	## 元素表达式数组
	var elements: Array
	## 构造 set 字面量 [br]
	## [param e] 元素表达式数组 (实际类型 Array[Expr])
	func _init(e):
		elements = e

## 集合推导式, 例如 {x*x for x in iterable if cond} [br]
## 通过对迭代对象中满足条件的每个元素计算表达式来生成集合
class SetComp extends Expr:
	## 元素表达式
	var elt_expr: Expr
	## 循环子句数组 (实际类型 Array[CompClause]), 支持多 for 与多 if
	var clauses: Array
	## 构造集合推导式 [br]
	## [param e] 元素表达式 [br]
	## [param c] 循环子句数组 (实际类型 Array[CompClause])
	func _init(e: Expr, c: Array):
		elt_expr = e
		clauses = c

## 列表推导式, 例如 [x for x in iterable if cond] [br]
## 通过对迭代对象中满足条件的每个元素计算表达式来生成列表
class ListComp extends Expr:
	## 元素表达式
	var elt_expr: Expr
	## 循环子句数组 (实际类型 Array[CompClause]), 支持多 for 与多 if
	var clauses: Array
	## 构造列表推导式 [br]
	## [param e] 元素表达式 [br]
	## [param c] 循环子句数组 (实际类型 Array[CompClause])
	func _init(e: Expr, c: Array):
		elt_expr = e
		clauses = c

## 生成器表达式, 例如 (x*x for x in iterable if cond) [br]
## 求值为惰性的 DSLGenerator (一次性迭代器), 而非列表
class GenComp extends Expr:
	## 元素表达式
	var elt_expr: Expr
	## 循环子句数组 (实际类型 Array[CompClause]), 支持多 for 与多 if
	var clauses: Array
	## 构造生成器表达式 [br]
	## [param e] 元素表达式 [br]
	## [param c] 循环子句数组 (实际类型 Array[CompClause])
	func _init(e: Expr, c: Array):
		elt_expr = e
		clauses = c

## 字典推导式, 例如 {k: v for k, v in iterable if cond} [br]
## 通过对迭代对象中满足条件的每个键值对计算表达式来生成字典
class DictComp extends Expr:
	## 键表达式
	var key_expr: Expr
	## 值表达式
	var value_expr: Expr
	## 循环子句数组 (实际类型 Array[CompClause]), 支持多 for 与多 if
	var clauses: Array
	## 构造字典推导式 [br]
	## [param k] 键表达式 [br]
	## [param v] 值表达式 [br]
	## [param c] 循环子句数组 (实际类型 Array[CompClause])
	func _init(k: Expr, v: Expr, c: Array):
		key_expr = k
		value_expr = v
		clauses = c

## 解包赋值表达式, 例如 a, (b, c), *rest = expr [br]
## 将右侧迭代对象的值按顺序解包到左侧多个目标中
class UnpackAssign extends Expr:
	## 解包目标列表, 元素为 Variable, UnpackTarget 或 StarredTarget
	var targets: Array
	## 值表达式
	var value: Expr
	## 构造解包赋值表达式 [br]
	## [param t] 目标列表 (实际类型 Array[Variable | UnpackTarget | StarredTarget]) [br]
	## [param v] 右侧表达式
	func _init(t, v):
		targets = t
		value = v

## 赋值表达式 (walrus 运算符 :=), 例如 (n := len(a)) [br]
## 求值时先赋值再返回右侧值, 目标只能是简单变量名
class WalrusExpr extends Expr:
	## 赋值目标变量名
	var name: String
	## 右侧值表达式
	var value: Expr
	## 构造赋值表达式 [br]
	## [param n] 目标变量名 [br]
	## [param v] 右侧值表达式
	func _init(n: String, v: Expr):
		name = n
		value = v

## yield 表达式, 例如 yield v / yield / yield from iterable [br]
## 仅出现在生成器函数体内; 挂起时产出 [member value] (或 from 子迭代器的元素) [br]
## [param value] 产出值表达式, 可为 null (裸 yield 产出 None) [br]
## [param from_expr] yield from 的子可迭代对象表达式, 非 null 时为委托形式
class YieldExpr extends Expr:
	## 产出值表达式, 可为 null
	var value: Expr
	## yield from 的子可迭代对象表达式, 可为 null
	var from_expr: Expr = null
	## 构造 yield 表达式 [br]
	## [param v] 产出值表达式, 可为 null [br]
	## [param f] yield from 的子表达式, 默认为 null
	func _init(v: Expr, f: Expr = null):
		value = v
		from_expr = f

## await 表达式, 例如 await coro() [br]
## PyGDS 不支持 async/await (以挂起系统替代), 本节点仅用于在语法分析阶段 [br]
## 给出与 CPython 一致的 SyntaxError 文案, 不会进入求值阶段
class AwaitExpr extends Expr:
	## 被等待的表达式
	var value: Expr
	## 构造 await 表达式 [br]
	## [param v] 被等待的表达式
	func _init(v: Expr):
		value = v

## 表达式语句, 将表达式包装为语句 [br]
## 用于将任意表达式 (如赋值, 调用) 作为独立语句执行
class ExpressionStmt extends Stmt:
	## 被包装的表达式
	var expression: Expr
	## 构造表达式语句 [br]
	## [param e] 表达式
	func _init(e):
		expression = e

## 三目条件表达式, 例如 true_val if cond else false_val [br]
## 根据条件表达式的布尔结果选择两个分支之一
class ConditionalExpr extends Expr:
	## 条件表达式
	var condition: Expr
	## 真值分支表达式
	var true_expr: Expr
	## 假值分支表达式
	var false_expr: Expr
	## 构造三目条件表达式 [br]
	## [param c] 条件表达式 [br]
	## [param t] 真值分支表达式 [br]
	## [param f] 假值表达式
	func _init(c, t, f):
		condition = c
		true_expr = t
		false_expr = f

## lambda 表达式, 例如 lambda x, y=1: x + y [br]
## 解析时捕获参数列表与单表达式函数体, 运行时构造为 DSLFunction
class LambdaExpr extends Expr:
	## 参数列表
	var params: Array
	## 函数体 (单个表达式, 运行时包装为 return)
	var body: Expr
	## 是否为生成器 lambda (函数体直接含 yield, Python 3.12+ 允许)
	var is_generator: bool = false
	## 构造 lambda 表达式 [br]
	## [param p] 参数列表 (实际类型 Array[Param]) [br]
	## [param b] 函数体表达式
	func _init(p, b):
		params = p
		body = b

## f-string 表达式, 例如 f"hello {name}" [br]
## parts 为混合字面量与替换字段的数组 [br]
## 每个 part 为 Dictionary: {"is_literal": bool, "text": String, "expr": Expr, "conv": String, "fmt": String}
class FStringExpr extends Expr:
	## 混合字面量/替换字段数组
	var parts: Array
	## 构造 f-string 表达式 [br]
	## [param p] parts 数组
	func _init(p):
		parts = p

## super() 表达式, 运行时解析为 DSLSuper 代理 [br]
## 支持零参数 super() (Python 3 风格) 与双参数 super(Class, obj)
class SuperExpr extends Expr:
	## 位置参数表达式数组 (0 或 2 个)
	var arguments: Array
	## 构造 super 表达式 [br]
	## [param a] 参数表达式数组
	func _init(a):
		arguments = a

## if/elif/else 条件语句 [br]
## 支持 elif 分支链和可选的 else 分支
class IfStmt extends Stmt:
	## if 条件表达式
	var condition: Expr
	## if 分支语句列表
	var then_branch: Array
	## elif 分支列表, 每个元素为 [condition, body]
	var elif_branches: Array
	## else 分支语句列表 (可为空数组)
	var else_branch: Array
	## 构造 if 语句 [br]
	## [param c] 条件表达式 [br]
	## [param t] if 分支语句列表 [br]
	## [param eli] elif 分支列表 [br]
	## [param els] else 分支语句列表
	func _init(c, t, eli, els):
		condition = c
		then_branch = t
		elif_branches = eli
		else_branch = els

## while 循环语句 [br]
## 当条件为真时重复执行循环体
class WhileStmt extends Stmt:
	## 循环条件表达式
	var condition: Expr
	## 循环体语句列表
	var body: Array
	## else 分支语句列表 (循环正常结束未 break 时执行)
	var _else_body: Array
	## 构造 while 循环 [br]
	## [param c] 循环条件表达式 [br]
	## [param b] 循环体语句列表
	func _init(c, b):
		condition = c
		body = b
		_else_body = []

## for 循环语句 [br]
## 遍历迭代对象中的每个元素执行循环体, 支持多变量解包
class ForStmt extends Stmt:
	## 循环变量名列表 (支持多变量解包)
	var variables: Array[String]
	## 迭代对象表达式
	var iterable: Expr
	## 循环体语句列表
	var body: Array
	## else 分支语句列表 (循环正常结束未 break 时执行)
	var _else_body: Array
	## 构造 for 循环 [br]
	## [param v] 循环变量名列表 [br]
	## [param i] 迭代对象表达式 [br]
	## [param b] 循环体语句列表
	func _init(v, i, b):
		variables = v
		iterable = i
		body = b
		_else_body = []

## 函数定义语句 [br]
## 定义函数签名和函数体, 支持 method_type 区分普通/类/静态方法
class FunctionStmt extends Stmt:
	## 函数名
	var name: String
	## 参数列表
	var params: Array[Param]
	## 函数体语句列表
	var body: Array
	## 方法类型: 0=普通方法, 1=类方法(@classmethod), 2=静态方法(@staticmethod), 3=属性(@property), 4=属性设置器(@name.setter), 5=属性删除器(@name.deleter)
	var method_type: int = 0
	## 是否为生成器函数 (函数体含 yield, 定义时由解析器检测)
	var is_generator: bool = false
	## 构造函数定义 [br]
	## [param n] 函数名 [br]
	## [param p] 参数列表 [br]
	## [param b] 函数体语句列表
	func _init(n, p, b):
		name = n
		params = p
		body = b

## 类定义语句 [br]
## 定义类名, 基类和类体内容
class ClassStmt extends Stmt:
	## 类名
	var name: String
	## 基类表达式 (可为 null, 表示继承 DSLObject)
	var superclass: Expr
	## 类体语句列表 (一系列 FunctionStmt 或其他语句)
	var body: Array[Stmt]
	## 构造类定义 [br]
	## [param n] 类名 [br]
	## [param s] 基类表达式, 可为 null [br]
	## [param b] 类体语句列表
	func _init(n, s, b):
		name = n
		superclass = s
		body = b

## return 语句 [br]
## 从当前函数返回, 可选携带返回值 [br]
## [param value] 返回值表达式, 可为 null (表示返回 None)
class ReturnStmt extends Stmt:
	## 返回值表达式, 可为 null (表示返回 None)
	var value: Expr
	## 构造 return 语句 [br]
	## [param v] 返回值表达式, 可为 null
	func _init(v):
		value = v

## break 语句 [br]
## 跳出当前最内层循环 (while/for)
class BreakStmt extends Stmt:
	pass

## continue 语句 [br]
## 跳过当前循环的剩余迭代, 进入下一次迭代
class ContinueStmt extends Stmt:
	pass

## global 声明 [br]
## 将变量声明为全局作用域变量, 后续对该变量的读写直接在全局作用域进行
class GlobalStmt extends Stmt:
	## 声明为全局的变量名
	var name: String
	## 构造 global 声明 [br]
	## [param n] 变量名
	func _init(n):
		name = n

## nonlocal 声明 [br]
## 将变量声明为非局部变量, 绑定到外层函数作用域的对应变量
class NonlocalStmt extends Stmt:
	## 声明为非局部的变量名列表
	var names: Array
	## 构造 nonlocal 声明 [br]
	## [param n] 变量名列表
	func _init(n):
		names = n

## assert 断言语句, 例如 assert x > 0, "x must be positive" [br]
## 条件为假时抛出 AssertionError
class AssertStmt extends Stmt:
	## 断言测试表达式
	var test: Expr
	## 断言失败时的错误消息, 可为 null
	var message: Expr
	## 构造 assert 语句 [br]
	## [param t] 测试表达式 [br]
	## [param m] 错误消息, 默认为 null
	func _init(t, m = null):
		test = t
		message = m

## pass 语句
class PassStmt extends Stmt:
	pass

## del 删除语句, 例如 [code]del obj.attr[/code] 或 [code]del arr[idx][/code] [br]
## 删除对象的属性或容器中的元素
class DelStmt extends Stmt:
	## 删除目标表达式列表
	var targets: Array[Expr]
	## 构造 del 语句 [br]
	## [param t] 删除目标表达式列表
	func _init(t):
		targets = t

## import 语句 [br]
## 支持 import math, random 及 import math as m
class ImportStmt extends Stmt:
	## 导入的模块名与别名列表, 每个元素 {"name": String, "alias": String}
	var names: Array
	## 构造 import 语句 [br]
	## [param n] names 数组
	func _init(n):
		names = n

## from module import name 语句 [br]
## 支持 from math import sqrt, pi 及 from math import *
class FromImportStmt extends Stmt:
	## 模块名
	var module: String
	## 导入的名字与别名列表, 每个元素 {"name": String, "alias": String}
	var names: Array
	## 是否星号导入 (from math import *)
	var star: bool = false
	## 构造 from-import 语句 [br]
	## [param m] 模块名 [br]
	## [param n] names 数组 [br]
	## [param s] 是否星号导入
	func _init(m, n, s = false):
		module = m
		names = n
		star = s

## try/except/finally 异常处理语句 [br]
## 支持多个 except 子句和一个可选的 finally 子句
class TryStmt extends Stmt:
	## try 分支语句列表
	var try_body: Array
	## except 子句列表 (ExceptClause 数组)
	var except_clauses: Array
	## finally 分支语句列表 (可为空数组)
	var finally_body: Array
	## 构造 try 语句 [br]
	## [param try_b] try 分支语句列表 [br]
	## [param exc_c] except 子句列表 [br]
	## [param fin_b] finally 分支语句列表
	func _init(try_b, exc_c, fin_b):
		try_body = try_b
		except_clauses = exc_c
		finally_body = fin_b

## except 子句 [br]
## 定义异常捕获的类型, 绑定变量和异常处理代码
class ExceptClause:
	## 捕获的异常类型表达式, 可为 null (表示捕获所有异常)
	var exception_type: Expr
	## as 绑定的变量名, 可为空字符串 (表示不绑定)
	var as_name: String
	## except 分支语句列表
	var body: Array
	## 构造 except 子句 [br]
	## [param exc] 异常类型表达式, 可为 null [br]
	## [param as_n] as 绑定变量名 [br]
	## [param b] except 分支语句列表
	func _init(exc, as_n, b):
		exception_type = exc
		as_name = as_n
		body = b

## raise 语句 [br]
## 抛出异常, 可选携带异常表达式, 无表达式时表示重新抛出当前异常 (re-raise)
class RaiseStmt extends Stmt:
	## 抛出的异常表达式, 可为 null (表示 re-raise)
	var expression: Expr
	## 构造 raise 语句 [br]
	## [param e] 异常表达式, 可为 null
	func _init(e):
		expression = e

## 控制台统一输出与错误报告器, 支持日志级别 [br]
## 整合 DSL 的 print 输出, 解析错误和运行时错误 [br]
## 通过日志级别控制输出详细程度
class ConsoleReport:
	## 日志级别枚举, 数值越大优先级越高 [br]
	## PRINT 级别用于 DSL print 输出, 不受日志级别过滤
	enum Level {
		PRINT = -1,
		ALL = 0,
		TRACE = 1,
		DEBUG = 2,
		INFO = 3,
		WARN = 4,
		ERROR = 5,
		FATAL = 6,
		OFF = 7,
	}
	
	## 关联的 PyGDS 实例
	var dsl: PyGDS = null
	## 是否启用调试模式 (输出到 Godot 控制台)
	var debug_mode: bool = false
	## 是否存在解析或运行时错误
	var has_error: bool = false
	## 最后一个错误信息
	var last_error: String = ""
	## 信息列表: [(Level, msg), ...]
	var messages: Array[Array] = []
	## 日志级别阈值
	var report_log_level: Level = Level.INFO
	
	## 构造控制台报告器 [br]
	## [param p_dsl] 关联的 PyGDS 实例 [br]
	## [param p_debug] 是否启用调试模式
	func _init(p_dsl: PyGDS, p_debug: bool = false):
		dsl = p_dsl
		debug_mode = p_debug
		
	## 输出 print 消息 (不受日志级别过滤) [br]
	## [param msg] 输出消息字符串
	func print_msg(msg: String):
		append_output(Level.PRINT, msg)
		if debug_mode:
			print(msg)
		
	## 输出普通信息 (由于 gdscript 无 info 函数, 故也使用 push_warning 函数) [br]
	## [param msg] 输出消息字符串
	func info(msg: String):
		append_output(Level.INFO, "[INFO] " + msg + "\n")
		if debug_mode:
			push_warning(msg)
		
	## 输出警告信息 [br]
	## [param msg] 输出消息字符串
	func warn(msg: String):
		append_output(Level.WARN, "[WARN] " + msg + "\n")
		if debug_mode:
			push_warning(msg)
	
	## 输出错误信息 [br]
	## [param msg] 输出消息字符串
	func err(msg: String):
		append_output(Level.ERROR, "[ERROR] " + msg + "\n")
		if debug_mode:
			push_warning(msg)
		
	## 错误记录 (静默模式: 不输出到终端, 等待顶层确认是否为未捕获异常) [br]
	## [param msg] 错误消息字符串
	func error(msg: String):
		if not has_error:
			has_error = true
			last_error = msg
	
	## 确认未捕获异常, 输出到 Godot 控制台和游戏内日志终端, 同时写入 print_output [br]
	## [param msg] 错误消息字符串
	func fatal_error(msg: String):
		append_output(Level.ERROR, "[ERROR] " + msg)
		if dsl:
			dsl.print_output += msg + "\n"
		if debug_mode:
			push_error(msg)
	
	## 清除错误状态 (try-except 异常捕获后使用) [br]
	## 重置 has_error 和 last_error 为初始状态
	func clear_error():
		has_error = false
		last_error = ""
		
	## 追加输出到消息列表 [br]
	## PRINT 级别的消息同时写入 print_output, 其他级别根据 report_log_level 过滤写入 console_output [br]
	## [param level] 日志级别 [br]
	## [param msg] 消息字符串
	func append_output(level: Level, msg: String) -> void:
		messages.append([level, msg])
		if level == Level.PRINT:
			dsl.print_output += msg
		elif level >= report_log_level:
			dsl.console_output += msg
		
	## 刷新输出, 重建 print_output 和 console_output 字符串 [br]
	## 遍历所有已记录消息, 按级别重新拼接输出
	func refresh_output() -> void:
		var print_str: String = ""
		var log_str: String = ""
		
		for ls in messages:
			var lv: Level = ls.get(0) as Level
			var msg: String = ls.get(1) as String
			if lv == Level.PRINT:
				print_str += msg + "\n"
			elif lv >= report_log_level:
				log_str += msg + "\n"
		
		if dsl:
			dsl.print_output = print_str
			dsl.console_output = log_str
			
	## 重置错误状态 (每次运行新脚本前调用) [br]
	## 清除 has_error 和 last_error, 准备新的执行
	func reset():
		has_error = false
		last_error = ""

## 函数参数封装 [br]
## 支持普通参数, 仅位置参数 (/), *args (可变位置), 仅关键字参数 (*), **kwargs (可变关键字)
class Param:
	## 参数名称
	var name: String
	## 默认值表达式, 没有则为 null
	var default_value: Expr
	## 该参数是否为 *args (可变位置参数)
	var is_args: bool
	## 该参数是否为 **kwargs (可变关键字参数)
	var is_kwargs: bool
	## 该参数是否为仅限位置传参 (位于 / 之前)
	var is_positional_only: bool = false
	## 该参数是否为仅限关键字传参 (位于 * 之后)
	var is_keyword_only: bool = false
	
	## 构造函数参数 [br]
	## [param p_name] 参数名称 [br]
	## [param p_default] 默认值表达式, 无默认值则为 null [br]
	## [param p_args] 是否为 *args 可变位置参数 [br]
	## [param p_kwargs] 是否为 **kwargs 可变关键字参数 [br]
	## [param p_positional_only] 是否为仅限位置传参 [br]
	## [param p_keyword_only] 是否为仅限关键字传参
	func _init(p_name: String, p_default = null, p_args = false, p_kwargs = false, p_positional_only = false, p_keyword_only = false):
		name = p_name
		default_value = p_default
		is_args = p_args
		is_kwargs = p_kwargs
		is_positional_only = p_positional_only
		is_keyword_only = p_keyword_only

## 关键字参数封装 [br]
## 用于函数调用时的 key=value 形式参数
class KeywordArg:
	## 参数名
	var name: String
	## 参数值表达式
	var value: Expr
	
	## 构造关键字参数 [br]
	## [param n] 参数名 [br]
	## [param v] 参数值表达式
	func _init(n, v):
		name = n
		value = v

## 所有 DSL 值的基类, 定义通用的操作接口, 子类重写以实现多态 [br]
## DSLObject 对标 CPython PyObject, 统一对象模型的核心 [br]
## DSLObject 任何可能出错的方法在出错时返回 null, 并将错误信息写入自己的 last_error [br]
## 命名规范与编排顺序: [br]
## - _* = GDS 内部通用辅助方法 (如 _type_name, _is_subclass_of_klass 等在基类注册的通用方法) [br]
## - magic_{magic_method_name} = 这些方法总是在 klass 查找不到用户定义的 魔术方法 时, 由 fallback 回调直接调用 [br]
## - _dsl_{magic_method_name} = 解释器直接调用的实例方法 (魔术方法), 不需要经过 klass 查找 [br]
## - builtin_{builtin_method_name} = DSL 内置方法, 签名 (args, kwargs) -> DSLObject [br]
## - _* = GDS 内部子类辅助方法 (如 _index_type_error 等在子类注册或在基类注册但无需子类覆写的方法)
class DSLObject:
	## 下一个 Object ID (静态计数器)
	static var _next_object_id: int = 0
	## 存储最后一个错误信息 (仅解释器读取)
	var last_error: String = ""
	## 与 last_error 对应的原始参数对象 (如 KeyError 的键) [br]
	## 异常构造需要原始对象才能给出正确的 e.args 与 repr (键可能是非字符串)
	var last_error_args: Array[DSLObject] = []
	## 唯一对象标识 (用于 id() 内置函数)
	var _object_id: int
	## 类型指针 (对应 PyObject.ob_type), 统一方法查找入口
	var klass = null
	## 实例属性字典 (对应 Python __dict__), null 表示无 __dict__, {} 表示用户自定义类实例
	var fields = null
	## 仅异常实例使用, 存储被包裹的 DSLException
	var _wrapped = null
	## 关联的解释器实例
	var interp: Interpreter = null
	
	## 构造 DSL 对象, 分配唯一 ID
	func _init():
		_object_id = _next_object_id
		_next_object_id += 1
	
	## 获取 class type 名称
	func _type_name() -> String:
		if klass != null:
			return klass.name
		return "object"
	
	## 判断当前类是否是目标类的子类 [br]
	## [param target] 目标类对象 [br]
	## [return] 如果当前类继承自目标类则返回 true
	func _is_subclass_of_klass(target: DSLClass) -> bool:
		if klass == null:
			return false
		var current = klass
		while current != null:
			if current == target:
				return true
			current = current.superclass
		return false
		
	func magic_add(args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLObject:
		if len(args) != 1:
			return null
		return _arithmetic_type_error("+", args[0])
		
	func magic_sub(args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLObject:
		if len(args) != 1:
			return null
		return _arithmetic_type_error("-", args[0])
		
	func magic_mul(args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLObject:
		if len(args) != 1:
			return null
		return _arithmetic_type_error("*", args[0])
		
	func magic_pow(args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLObject:
		if len(args) != 1:
			return null
		return _arithmetic_type_error("**", args[0])
		
	func magic_truediv(args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLObject:
		if len(args) != 1:
			return null
		return _arithmetic_type_error("/", args[0])
		
	func magic_floordiv(args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLObject:
		if len(args) != 1:
			return null
		return _arithmetic_type_error("//", args[0])
		
	func magic_mod(args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLObject:
		if len(args) != 1:
			return null
		return _arithmetic_type_error("%", args[0])
		
	func magic_lt(args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLBool:
		if len(args) == 2:
			_comparison_type_error("<", args[1])
			return DSLBool.new(false)
		if len(args) == 1:
			_comparison_type_error("<", args[0])
			return DSLBool.new(false)
		return null
		
	func magic_gt(args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLBool:
		if len(args) == 2:
			_comparison_type_error(">", args[1])
			return DSLBool.new(false)
		if len(args) == 1:
			_comparison_type_error(">", args[0])
			return DSLBool.new(false)
		return null
		
	func magic_le(args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLBool:
		if len(args) == 2:
			_comparison_type_error("<=", args[1])
			return DSLBool.new(false)
		if len(args) == 1:
			_comparison_type_error("<=", args[0])
			return DSLBool.new(false)
		return null
		
	func magic_ge(args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLBool:
		if len(args) == 2:
			_comparison_type_error(">=", args[1])
			return DSLBool.new(false)
		if len(args) == 1:
			_comparison_type_error(">=", args[0])
			return DSLBool.new(false)
		return null
		
	## 相等判定 (容器成员判定 / 排序比较等的统一入口) [br]
	## 用户类若定义了 __eq__, 走用户实现; 否则回退到身份比较 [br]
	## 这使 `x in [a, b]`、list.remove / index / count 等容器操作与 CPython 一致 [br]
	## [param other] 比较对象 [br]
	## [returns] 相等时返回 true
	func _dsl_eq(other: DSLObject) -> bool:
		var rhs = other
		if rhs != null:
			rhs = DSLObject._unwrap_dsl(rhs)
		if klass != null:
			var method = klass._lookup_method("__eq__")
			if method != null:
				var res = klass._invoke_func(method, [self, rhs] as Array[DSLObject], {} as Dictionary[String, DSLObject])
				if res is DSLBool:
					return res.value
		return self == rhs
	
	## 不等判定 (容器操作中的 != 语义) [br]
	## 直接取 __eq__ 的相反值: CPython 在未定义 __ne__ 时即如此回退 [br]
	## 此处不经类方法查找, 避免 DSLObject 级回退被误当作访问用户属性
	func _dsl_ne(other: DSLObject) -> bool:
		return not _dsl_eq(other)

	func magic_eq(args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLBool:
		if len(args) == 2:
			return DSLBool.new(args[0] == args[1])
		if len(args) == 1:
			return DSLBool.new(self == args[0])
		return null
		
	## 不等判定 [br]
	## 用户类若定义了 __ne__ 由其处理, 否则按 CPython 语义回退为 not __eq__ [br]
	## (此前回退到身份比较, 会与 __eq__ 结果矛盾)
	func magic_ne(args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLBool:
		if len(args) == 2:
			var rhs = args[1]
			if rhs != null:
				rhs = DSLObject._unwrap_dsl(rhs)
			return DSLBool.new(args[0]._dsl_ne(rhs))
		if len(args) == 1:
			return DSLBool.new(not (self._dsl_eq(args[0])))
		return null
		
	func magic_bool(_args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLBool:
		return DSLBool.new(true)
		
	func magic_getitem(_args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLObject:
		last_error = "TypeError: '%s' object is not subscriptable" % [_type_name()]
		return null
		
	func magic_setitem(_args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLObject:
		last_error = "TypeError: '%s' object does not support item assignment" % [_type_name()]
		return null
		
	## 对应 PyObject.__getattribute__ 方法 (默认实现) [br]
	## 先通过 _dsl_getattribute 查找属性, 未找到时回退到 __getattr__ [br]
	## [param args] [self, attr_name] [br]
	## [returns] 属性值, 未找到时返回 null 并设置 last_error
	func magic_getattribute(args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLObject:
		if len(args) < 1:
			return null
		var attr_name = args[0]
		if not attr_name is DSLString:
			last_error = "TypeError: attribute name must be string, not '%s'" % attr_name._type_name()
			return null
		var result = _dsl_getattribute(attr_name.value)
		if result != null:
			return result
		# _dsl_getattribute 未找到, 尝试 klass 中的 __getattr__ 回退
		if klass != null:
			var getattr_method = klass._lookup_method("__getattr__")
			if getattr_method != null:
				var getattr_result = klass._invoke_func(getattr_method, [self, attr_name] as Array[DSLObject], {} as Dictionary[String, DSLObject])
				if getattr_result != null:
					return getattr_result
		# last_error 已由 _dsl_getattribute 设置
		return null
	
	## 对应 PyObject.__getattr__ 方法 (默认实现) [br]
	## 仅在 __getattribute__ 未找到属性时被调用, 默认直接报 AttributeError [br]
	## [param args] [self, attr_name] [br]
	## [returns] 始终返回 null 并设置 last_error
	func magic_getattr(args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLObject:
		if len(args) < 1:
			return null
		var attr_name = args[0]
		if not attr_name is DSLString:
			last_error = "TypeError: attribute name must be string, not '%s'" % attr_name._type_name()
			return null
		last_error = "AttributeError: '%s' object has no attribute '%s'" % [_type_name(), attr_name.value]
		return null
	
	## 对应 PyObject.__setattr__ 方法 (默认实现) [br]
	## 委托给 _dsl_setattr 处理属性设置 [br]
	## [param args] [self, attr_name, attr_value] [br]
	## [returns] DSLNone, 失败时返回 null 并设置 last_error
	func magic_setattr(args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLObject:
		if len(args) < 2:
			return null
		var attr_name = args[0]
		var attr_value = args[1]
		if not attr_name is DSLString:
			last_error = "TypeError: attribute name must be string, not '%s'" % attr_name._type_name()
			return null
		_dsl_setattr(attr_name.value, attr_value)
		if last_error != "":
			return null
		return DSLNone.new()
		
	func magic_call(args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject] = {}) -> DSLObject:
		if klass != null:
			var method = klass._lookup_method("__call__")
			if method != null:
				var call_args: Array[DSLObject] = [self]
				call_args.append_array(args)
				return klass._invoke_func(method, call_args, _kwargs)
		last_error = "TypeError: '%s' object is not callable" % [_type_name()]
		return null
		
	func magic_iter(_args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLIterator:
		if klass != null:
			var method = klass._lookup_method("__iter__")
			if method != null:
				var res = klass._invoke_func(method, [self] as Array[DSLObject], {} as Dictionary[String, DSLObject])
				if res is DSLIterator:
					return res
		last_error = "TypeError: '%s' object is not iterable" % [_type_name()]
		return null
	
	func magic_str(_args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLString:
		if klass != null:
			var method = klass._lookup_method("__str__")
			if method != null:
				var res = klass._invoke_func(method, [self] as Array[DSLObject], {} as Dictionary[String, DSLObject])
				if res is DSLString:
					return res
			# Fall back to __repr__ if __str__ is not defined
			var repr_method = klass._lookup_method("__repr__")
			if repr_method != null:
				var rep_res = klass._invoke_func(repr_method, [self] as Array[DSLObject], {} as Dictionary[String, DSLObject])
				if rep_res is DSLString:
					return rep_res
		return DSLString.new(_dsl_str())
	
	func magic_repr(_args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLObject:
		if klass != null:
			var method = klass._lookup_method("__repr__")
			if method != null:
				return klass._invoke_func(method, [self] as Array[DSLObject], {} as Dictionary[String, DSLObject])
		return DSLString.new("<" + _type_name() + " object>")
	
	func magic_contains(args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLObject:
		if klass != null:
			var method = klass._lookup_method("__contains__")
			if method != null:
				return klass._invoke_func(method, args, _kwargs)
		# 未定义 __contains__ 时回退为迭代查找 (CPython 的行为)
		if klass != null and klass._lookup_method("__iter__") != null:
			var target = args[1]
			var it = _dsl_iter()
			if it != null:
				while it.has_next():
					var item = it.next()
					if item == null:
						break
					if item._dsl_eq(target):
						return DSLBool.new(true)
				return DSLBool.new(false)
		last_error = "TypeError: '%s' object is not a container" % [_type_name()]
		return null

	## 判断对象是否可调用 (callable() 与 sorted(key=) 等共用) [br]
	## 默认对函数/内置函数/类/偏函数与定义了 __call__ 的实例返回 true [br]
	## [returns] 可调用返回 true
	func _dsl_is_callable() -> bool:
		if self is DSLFunction or self is DSLBuiltinFunction or self is DSLClass or self is DSLPartial:
			return true
		if klass != null and klass._lookup_method("__call__") != null:
			return true
		return false
	
	func magic_len(_args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLObject:
		if klass != null:
			var method = klass._lookup_method("__len__")
			if method != null:
				return klass._invoke_func(method, [self] as Array[DSLObject], {} as Dictionary[String, DSLObject])
		last_error = "TypeError: '%s' object has no len()" % [_type_name()]
		return null
		
	func _dsl_str() -> String:
		# 对于异常类型会委托到 _wrapped._dsl_str()
		if _wrapped != null and _wrapped is DSLException:
			return _wrapped._dsl_str()
		if fields != null and klass != null:
			return "<%s object>" % klass.name
		# 对于普通对象返回 "<类型名 object at 0x地址>" 格式
		return "<%s object at 0x%x>" % [_type_name(), _object_id]
	
	## 真值判定, 按 CPython 的优先级查用户类协议 [br]
	## __bool__ 优先; 无 __bool__ 但定义了 __len__ 时以非 0 为真; 两者都无则恒为真 [br]
	## 与 __len__ / __str__ / __contains__ / __eq__ 的既有桥接保持同一形状 [br]
	## [returns] 对象的真值
	func _dsl_bool() -> bool:
		if klass != null:
			var bool_method = klass._lookup_method("__bool__")
			if bool_method != null:
				var bool_res = klass._invoke_func(bool_method, [self] as Array[DSLObject], {} as Dictionary[String, DSLObject])
				if bool_res is DSLBool:
					return bool_res.value
				return true
			var len_method = klass._lookup_method("__len__")
			if len_method != null:
				var len_res = klass._invoke_func(len_method, [self] as Array[DSLObject], {} as Dictionary[String, DSLObject])
				if len_res is DSLInteger:
					return len_res.value != 0
		return true
		
	func _dsl_iter() -> DSLIterator:
		if klass != null:
			var method = klass._lookup_method("__iter__")
			if method != null:
				var result = klass._invoke_func(method, [self] as Array[DSLObject], {} as Dictionary[String, DSLObject])
				if result is DSLIterator:
					return result
				if result is DSLList:
					return DSLListIterator.new(result.items)
				if result is DSLTuple:
					return DSLListIterator.new(result.items)
				if result is DSLRange:
					return result._dsl_iter()
				# __iter__ 返回另一个用户实例 (通常是 self): 按其 __next__ 驱动
				if result != null and result._wrapped == null:
					var next_method = null
					if result.klass != null:
						next_method = result.klass._lookup_method("__next__")
					if next_method != null:
						return DSLUserIterator.new(result)
				# __iter__ 返回生成器函数调用结果 (生成器): 直接作为迭代器
				if result is DSLFunctionGenerator:
					return result._dsl_iter()
				if result is DSLGenerator:
					return result._dsl_iter()
		# 未定义 __iter__ 但定义了 __next__ 的对象自身也可迭代 (与 CPython 一致)
		var self_next = klass._lookup_method("__next__") if klass != null else null
		if self_next != null:
			return DSLUserIterator.new(self)
		last_error = "TypeError: '%s' object is not iterable" % [_type_name()]
		return null
	
	func _dsl_getattribute(name: String) -> DSLObject:
		if fields != null and fields.has(name):
			return fields[name]
		if klass != null:
			var method = klass._dsl_getattribute(name)
			if method != null and not (method is DSLNone):
				if method.has_method("__get__"):
					return method.__get__(self, klass)
				return method
			# Fallback: call __getattr__ if defined
			var getattr_method = klass._lookup_method("__getattr__")
			if getattr_method != null:
				return klass._invoke_func(getattr_method, [self, DSLString.new(name)] as Array[DSLObject], {} as Dictionary[String, DSLObject])
		last_error = "AttributeError: '%s' object has no attribute '%s'" % [_type_name(), name]
		return DSLNone.new()
	
	func _dsl_setattr(name: String, value: DSLObject):
		if klass != null:
			# Check for property descriptor with __set__
			var prop = klass._dsl_getattribute(name)
			if prop != null and not (prop is DSLNone) and prop.has_method("__set__"):
				prop.__set__(self, value)
				return
			var method = klass._lookup_method("__setattr__")
			if method != null:
				klass._invoke_func(method, [self, DSLString.new(name), value] as Array[DSLObject], {} as Dictionary[String, DSLObject])
				return
		if fields != null:
			fields[name] = value
			return
		last_error = "TypeError: '%s' object has no __dict__" % _type_name()
	
	func _dsl_delattr(name: String):
		if klass != null:
			var method = klass._lookup_method("__delattr__")
			if method != null:
				klass._invoke_func(method, [self, DSLString.new(name)] as Array[DSLObject], {} as Dictionary[String, DSLObject])
				return
		if fields != null and fields.has(name):
			fields.erase(name)
			return
		last_error = "AttributeError: '%s' object has no attribute '%s'" % [_type_name(), name]
	
	func _dsl_delitem(_index: DSLObject):
		last_error = "TypeError: '%s' object does not support item deletion" % _type_name()
		return null
	
	func _dsl_getitem(index: DSLObject) -> DSLObject:
		return magic_getitem([self, index] as Array[DSLObject], {} as Dictionary[String, DSLObject])
	
	func _dsl_setitem(_index: DSLObject, _value: DSLObject):
		last_error = "TypeError: '%s' object does not support item assignment" % [_type_name()]
		return null
		
	## 解包 DSLInstance 包装 (静态方法) [br]
	## 如果 obj 是 DSLInstance 且有 _wrapped 字段, 则返回其内部 _wrapped, 否则返回 obj 本身 [br]
	## 用于比较运算和算术运算前的类型标准化 [br]
	## [param obj] 要解包的对象 [br]
	## [returns] 解包后的对象
	static func _unwrap_dsl(obj: DSLObject) -> DSLObject:
		if obj._wrapped != null:
			return obj._wrapped
		return obj

	## Python 风格的 repr (静态方法) [br]
	## 与 CPython 的 repr() 一致: 字符串带引号、None/True/False 用字面量、容器递归 [br]
	## 异常构造 (如 KeyError 的参数) 与异常 repr 需要它区分 str 与 repr [br]
	## [param obj] 要表示的对象 [br]
	## [returns] repr 字符串
	static func _py_repr(obj: DSLObject) -> String:
		var o = obj
		if o == null:
			return "None"
		if o._wrapped != null and o.klass != null:
			# 用户类实参 (DSLInstance 包装): 取内层值做 repr
			o = o._wrapped
		if o is DSLNone:
			return "None"
		if o is DSLBool:
			return "True" if o.value else "False"
		if o is DSLString:
			return "'" + _py_str_repr(o.value) + "'"
		if o is DSLInteger:
			return str(o.value)
		if o is DSLFloat:
			return str(o.value)
		if o is DSLList or o is DSLTuple or o is DSLDict or o is DSLSet or o is DSLFrozenSet:
			return o._dsl_str()
		return "<" + o._type_name() + " object>"

	## Python 风格的字符串 repr 转义 (静态方法) [br]
	## 转义换行/制表/回车/反斜杠/单引号, 用于容器 (list/tuple/dict/set) 的字符串表示 [br]
	## [param v] 原始字符串 [br]
	## [returns] 转义后的字符串
	static func _py_str_repr(v: String) -> String:
		var r = ""
		for i in range(v.length()):
			var ch = v[i]
			if ch == "\n":
				r += "\\n"
			elif ch == "\t":
				r += "\\t"
			elif ch == "\r":
				r += "\\r"
			elif ch == "\\":
				r += "\\\\"
			elif ch == "'":
				r += "\\'"
			else:
				r += ch
		return r
		
	## 生成索引访问类型错误 [br]
	## 设置 last_error 并返回 null [br]
	## [param index] 导致错误的索引 (可选)
	func _index_type_error(index: DSLObject = null) -> DSLObject:
		var idx: DSLObject = DSLNone.new() if index == null else index
		last_error = "TypeError: %s indices must be integers or slices, not %s" % [_type_name(), idx._type_name()]
		return null
		
	## 生成算术运算类型错误 [br]
	## 设置 last_error 并返回 null [br]
	## [param op] 运算符字符串 [br]
	## [param other] 右侧操作数对象 (可选)
	func _arithmetic_type_error(op: String, other: DSLObject = null) -> DSLObject:
		var o: DSLObject = DSLNone.new() if other == null else other
		last_error = "TypeError: unsupported operand type(s) for %s: '%s' and '%s'" % [op, _type_name(), o._type_name()]
		return null
	
	## 生成比较运算类型错误 [br]
	## 设置 last_error 并返回 null [br]
	## [param op] 运算符字符串 [br]
	## [param other] 右侧操作数对象 (可选)
	func _comparison_type_error(op: String, other: DSLObject = null) -> DSLObject:
		var o: DSLObject = DSLNone.new() if other == null else other
		last_error = "TypeError: '%s' not supported between instances of '%s' and '%s'" % [op, _type_name(), o._type_name()]
		return null

## DSL None 类型的表示, 对应 Python None, 表示空值
class DSLNone extends DSLObject:
	func _type_name() -> String:
		return "NoneType"
		
	func _dsl_str() -> String:
		return "None"
	
	func _dsl_bool() -> bool:
		return false
	
	func _dsl_eq(other: DSLObject) -> bool:
		other = DSLObject._unwrap_dsl(other)
		return other is DSLNone

## DSL 切片类型, 对应 Python Slice, 用于切片操作 start:stop:step
class DSLSlice extends DSLObject:
	## 切片起始索引
	var start: DSLObject
	## 切片中止索引
	var stop: DSLObject
	## 切片步长
	var step: DSLObject
	
	## 构造切片对象 [br]
	## [param s] 切片起始索引 [br]
	## [param e] 切片中止索引 [br]
	## [param st] 切片步长
	func _init(s, e, st = null):
		super._init()
		start = s
		stop = e
		step = st
	
	func _type_name() -> String:
		return "slice"
	
	func _dsl_str() -> String:
		return "slice(" + _bound_str(start) + ", " + _bound_str(stop) + ", " + _bound_str(step) + ")"

	## 边界值的字符串表示, null 边界显示 None (与 Python 一致) [br]
	## [param v] 边界值, 可为 null
	func _bound_str(v) -> String:
		return "None" if v == null else v._dsl_str()

	func magic_repr(_args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLObject:
		return DSLString.new(_dsl_str())

	## 属性访问: start/stop/step (未指定边界返回 None)
	func _dsl_getattribute(name: String) -> DSLObject:
		if name == "start":
			return start if start != null else DSLNone.new()
		if name == "stop":
			return stop if stop != null else DSLNone.new()
		if name == "step":
			return step if step != null else DSLNone.new()
		return super._dsl_getattribute(name)

## DSL 布尔类型, 对应 Python bool, 表示 true 和 false
class DSLBool extends DSLObject:
	## 底层的布尔值
	var value: bool
	
	## 构造布尔值对象 [br]
	## [param v] 布尔值
	func _init(v):
		super._init()
		value = v
	
	func _type_name() -> String:
		return "bool"
		
	func magic_eq(args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLBool:
		var self_obj = args[0]
		var other = args[1]
		other = DSLObject._unwrap_dsl(other)
		return DSLBool.new(other is DSLBool and self_obj.value == other.value)
		
	func magic_ne(args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLBool:
		var self_obj = args[0]
		var other = args[1]
		other = DSLObject._unwrap_dsl(other)
		return DSLBool.new(not (other is DSLBool and self_obj.value == other.value))
		
	func magic_str(args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLString:
		return DSLString.new("True" if args[0].value else "False")
		
	func magic_repr(args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLString:
		return DSLString.new("True" if args[0].value else "False")
		
	func magic_bool(args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLBool:
		return DSLBool.new(args[0].value)
	
	func _dsl_str() -> String:
		return "True" if value else "False"
	
	func _dsl_bool() -> bool:
		return value
	
	func _dsl_eq(other: DSLObject) -> bool:
		other = DSLObject._unwrap_dsl(other)
		return (other is DSLBool) and value == other.value

## DSL 异常类型, 对应 Python BaseException, 表示错误和异常情况
class DSLException extends DSLObject:
	## 错误消息字符串
	var message: String
	## 异常类型名称 ("Exception", "TypeError")
	var error_type: String
	## 额外的异常参数
	var args: Array[DSLObject] = []
	
	## 构造异常对象 [br]
	## [param p_msg] 错误消息 [br]
	## [param p_type] 异常类型名称 [br]
	## [param p_args] 额外参数 (实际类型 Array[DSLObject])
	func _init(p_msg: String = "", p_type: String = "Exception", p_args: Array[DSLObject] = []):
		super._init()
		message = p_msg
		error_type = p_type
		args = p_args
	
	func _type_name() -> String:
		return error_type
	
	func _dsl_str() -> String:
		# 仅返回消息 (Python str() 规范)
		return message
	
	func _dsl_bool() -> bool:
		return true
	
	func _dsl_eq(other: DSLObject) -> bool:
		other = DSLObject._unwrap_dsl(other)
		if other is DSLException:
			return error_type == other.error_type and message == other.message
		return false

## DSL 整数类型, 对应 Python int
class DSLInteger extends DSLObject:
	## 底层的整数值
	var value: int
	## int 类型的魔法方法描述符缓存 [br]
	## 存储各 Python 魔法方法对应的 DSLWrappedDescriptor
	var _int_magic_descriptors: Dictionary = {}
	
	## 构造整数值对象 [br]
	## [param v] 整数值
	func _init(v):
		super._init()
		value = v
	
	func _type_name() -> String:
		return "int"
	
	func magic_add(args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLObject:
		var self_obj = args[0]
		var other = args[1]
		var a = self_obj._promote(other)
		if a[0] == null:
			return null
		elif a[1] is DSLInteger:
			return DSLInteger.new(self_obj.value + a[1].value)
		else:
			return DSLFloat.new(a[0].value + a[1].value)
			
	func magic_sub(args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLObject:
		var self_obj = args[0]
		var other = args[1]
		var a = self_obj._promote(other)
		if a[0] == null:
			return null
		elif a[1] is DSLInteger:
			return DSLInteger.new(self_obj.value - a[1].value)
		else:
			return DSLFloat.new(a[0].value - a[1].value)
			
	func magic_mul(args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLObject:
		var self_obj = args[0]
		var other = args[1]
		var a = self_obj._promote(other)
		if a[0] == null:
			return null
		elif a[1] is DSLInteger:
			return DSLInteger.new(self_obj.value * a[1].value)
		else:
			return DSLFloat.new(a[0].value * a[1].value)
			
	func magic_div(args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLObject:
		var self_obj = args[0]
		var other = args[1]
		var a = self_obj._promote(other)
		if a[0] == null:
			return null
		if a[1].value == 0:
			self_obj.last_error = "ZeroDivisionError: division by zero"
			return null
		return DSLFloat.new(float(self_obj.value) / float(a[1].value))
	
	func magic_floordiv(args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLObject:
		var self_obj = args[0]
		var other = args[1]
		other = DSLObject._unwrap_dsl(other)
		if other is DSLInteger:
			if other.value == 0:
				self_obj.last_error = "ZeroDivisionError: division by zero"
				return null
			return DSLInteger.new(self_obj.value / other.value)
		if other is DSLFloat:
			if other.value == 0.0:
				self_obj.last_error = "ZeroDivisionError: division by zero"
				return null
			return DSLFloat.new(floor(float(self_obj.value) / other.value))
		self_obj._arithmetic_type_error("//", other)
		return null
		
	func magic_mod(args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLObject:
		var self_obj = args[0]
		var other = args[1]
		other = DSLObject._unwrap_dsl(other)
		if other is DSLInteger:
			if other.value == 0:
				self_obj.last_error = "ZeroDivisionError: division by zero"
				return null
			return DSLInteger.new(self_obj.value % other.value)
		if other is DSLFloat:
			if other.value == 0.0:
				self_obj.last_error = "ZeroDivisionError: division by zero"
				return null
			return DSLFloat.new(fmod(float(self_obj.value), other.value))
		self_obj._arithmetic_type_error("%", other)
		return null
		
	func magic_pow(args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLObject:
		var self_obj = args[0]
		var other = args[1]
		other = DSLObject._unwrap_dsl(other)
		if other is DSLInteger:
			var _exp = other.value
			if _exp >= 0:
				var result = 1
				var base = self_obj.value
				var e = _exp
				while e > 0:
					if e & 1:
						result *= base
					base *= base
					e >>= 1
				return DSLInteger.new(result)
			else:
				return DSLFloat.new(pow(float(self_obj.value), float(_exp)))
		if other is DSLFloat:
			return DSLFloat.new(pow(float(self_obj.value), other.value))
		self_obj._arithmetic_type_error("**", other)
		return null
	
	func magic_eq(args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLBool:
		var self_obj = args[0]
		var other = args[1]
		other = DSLObject._unwrap_dsl(other)
		var result = DSLBool.new((other is DSLInteger and self_obj.value == other.value) or (other is DSLFloat and float(self_obj.value) == other.value))
		return result
	
	func magic_ne(args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLBool:
		var self_obj = args[0]
		var other = args[1]
		other = DSLObject._unwrap_dsl(other)
		return DSLBool.new(not ((other is DSLInteger and self_obj.value == other.value) or (other is DSLFloat and float(self_obj.value) == other.value)))
	
	func magic_lt(args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLBool:
		var self_obj = args[0]
		var other = args[1]
		other = DSLObject._unwrap_dsl(other)
		if other is DSLInteger:
			return DSLBool.new(self_obj.value < other.value)
		if other is DSLFloat:
			return DSLBool.new(float(self_obj.value) < other.value)
		self_obj._comparison_type_error("<", other)
		return DSLBool.new(false)
	
	func magic_gt(args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLBool:
		var self_obj = args[0]
		var other = args[1]
		other = DSLObject._unwrap_dsl(other)
		if other is DSLInteger:
			return DSLBool.new(self_obj.value > other.value)
		if other is DSLFloat:
			return DSLBool.new(float(self_obj.value) > other.value)
		self_obj._comparison_type_error(">", other)
		return DSLBool.new(false)
	
	func magic_le(args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLBool:
		var self_obj = args[0]
		var other = args[1]
		other = DSLObject._unwrap_dsl(other)
		if other is DSLInteger:
			return DSLBool.new(self_obj.value <= other.value)
		if other is DSLFloat:
			return DSLBool.new(float(self_obj.value) <= other.value)
		self_obj._comparison_type_error("<=", other)
		return DSLBool.new(false)
	
	func magic_ge(args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLBool:
		var self_obj = args[0]
		var other = args[1]
		other = DSLObject._unwrap_dsl(other)
		if other is DSLInteger:
			return DSLBool.new(self_obj.value >= other.value)
		if other is DSLFloat:
			return DSLBool.new(float(self_obj.value) >= other.value)
		self_obj._comparison_type_error(">=", other)
		return DSLBool.new(false)
	
	func magic_neg(args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLObject:
		return DSLInteger.new(-args[0].value)
	
	func magic_str(args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLString:
		return DSLString.new(str(args[0].value))
	
	func magic_repr(args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLObject:
		return DSLString.new(str(args[0].value))
	
	func magic_bool(args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLBool:
		return DSLBool.new(args[0].value != 0)
	
	func magic_invert(args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLObject:
		return DSLInteger.new(~args[0].value)
	
	func magic_lshift(args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLObject:
		var self_obj = args[0]
		var other = args[1]
		other = DSLObject._unwrap_dsl(other)
		if other is DSLInteger:
			return DSLInteger.new(self_obj.value << other.value)
		return self_obj._arithmetic_type_error("<<", other)
	
	func magic_rshift(args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLObject:
		var self_obj = args[0]
		var other = args[1]
		other = DSLObject._unwrap_dsl(other)
		if other is DSLInteger:
			return DSLInteger.new(self_obj.value >> other.value)
		return self_obj._arithmetic_type_error(">>", other)
	
	func magic_xor(args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLObject:
		var self_obj = args[0]
		var other = args[1]
		other = DSLObject._unwrap_dsl(other)
		if other is DSLInteger:
			return DSLInteger.new(self_obj.value ^ other.value)
		return self_obj._arithmetic_type_error("^", other)
	
	func magic_or(args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLObject:
		var self_obj = args[0]
		var other = args[1]
		other = DSLObject._unwrap_dsl(other)
		if other is DSLInteger:
			return DSLInteger.new(self_obj.value | other.value)
		return self_obj._arithmetic_type_error("|", other)
	
	func magic_and(args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLObject:
		var self_obj = args[0]
		var other = args[1]
		other = DSLObject._unwrap_dsl(other)
		if other is DSLInteger:
			return DSLInteger.new(self_obj.value & other.value)
		return self_obj._arithmetic_type_error("&", other)
	
	func _dsl_str() -> String:
		return str(value)
	
	func _dsl_bool() -> bool:
		return value != 0
	
	func _dsl_eq(other: DSLObject) -> bool:
		other = DSLObject._unwrap_dsl(other)
		if other is DSLInteger:
			return value == other.value
		if other is DSLFloat:
			return float(value) == other.value
		if other is DSLBool:
			return (value != 0) == other.value
		return false
	
	func _dsl_getattribute(name: String) -> DSLObject:
		if _int_magic_descriptors.is_empty():
			_init_magic_descriptors()
		if _int_magic_descriptors.has(name):
			return _int_magic_descriptors[name].__get__(self, null)
		return super._dsl_getattribute(name)
	
	## 类型提升: 将操作数转为兼容类型 [br]
	## [param other] 另一个操作数 [br]
	## [returns] [self, other] 或 [DSLFloat, other], 类型不兼容时返回 [null, null] (实际类型 Array[DSLObject])
	func _promote(other: DSLObject) -> Array:
		other = DSLObject._unwrap_dsl(other)
		if other is DSLInteger:
			return [self, other]
		if other is DSLFloat:
			return [DSLFloat.new(float(value)), other]
		last_error = "TypeError: cannot operate int with " + other._type_name()
		return [null, null]
	
	## 初始化魔法方法描述符字典 [br]
	## 注册所有 Python int 类型的魔法方法 (__add__ 等)
	func _init_magic_descriptors():
		_int_magic_descriptors = {
			"__add__": DSLWrappedDescriptor.new("__add__", Callable(self, "magic_add")),
			"__sub__": DSLWrappedDescriptor.new("__sub__", Callable(self, "magic_sub")),
			"__mul__": DSLWrappedDescriptor.new("__mul__", Callable(self, "magic_mul")),
			"__truediv__": DSLWrappedDescriptor.new("__truediv__", Callable(self, "magic_div")),
			"__floordiv__": DSLWrappedDescriptor.new("__floordiv__", Callable(self, "magic_floordiv")),
			"__mod__": DSLWrappedDescriptor.new("__mod__", Callable(self, "magic_mod")),
			"__pow__": DSLWrappedDescriptor.new("__pow__", Callable(self, "magic_pow")),
			"__eq__": DSLWrappedDescriptor.new("__eq__", Callable(self, "magic_eq")),
			"__ne__": DSLWrappedDescriptor.new("__ne__", Callable(self, "magic_ne")),
			"__lt__": DSLWrappedDescriptor.new("__lt__", Callable(self, "magic_lt")),
			"__gt__": DSLWrappedDescriptor.new("__gt__", Callable(self, "magic_gt")),
			"__le__": DSLWrappedDescriptor.new("__le__", Callable(self, "magic_le")),
			"__ge__": DSLWrappedDescriptor.new("__ge__", Callable(self, "magic_ge")),
			"__neg__": DSLWrappedDescriptor.new("__neg__", Callable(self, "magic_neg")),
			"__str__": DSLWrappedDescriptor.new("__str__", Callable(self, "magic_str")),
			"__repr__": DSLWrappedDescriptor.new("__repr__", Callable(self, "magic_repr")),
			"__bool__": DSLWrappedDescriptor.new("__bool__", Callable(self, "magic_bool")),
		}
	
## DSL 浮点数类型, 对应 Python float
class DSLFloat extends DSLObject:
	## 底层的浮点值
	var value: float
	## float 类型的魔法方法描述符缓存 [br]
	## 存储各 Python 魔法方法对应的 DSLWrappedDescriptor
	var _float_magic_descriptors: Dictionary = {}
	
	## 构造浮点数值对象 [br]
	## [param v] 浮点数值
	func _init(v):
		super._init()
		value = v
	
	func _type_name() -> String:
		return "float"
	
	func magic_add(args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLObject:
		var self_obj = args[0]
		var other = args[1]
		var a = self_obj._promote(other)
		if a[0] == null:
			return null
		return DSLFloat.new(self_obj.value + a[1].value)
	
	func magic_sub(args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLObject:
		var self_obj = args[0]
		var other = args[1]
		var a = self_obj._promote(other)
		if a[0] == null:
			return null
		return DSLFloat.new(self_obj.value - a[1].value)
	
	func magic_mul(args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLObject:
		var self_obj = args[0]
		var other = args[1]
		var a = self_obj._promote(other)
		if a[0] == null:
			return null
		return DSLFloat.new(self_obj.value * a[1].value)
	
	func magic_div(args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLObject:
		var self_obj = args[0]
		var other = args[1]
		var a = self_obj._promote(other)
		if a[0] == null:
			return null
		if a[1].value == 0.0:
			self_obj.last_error = "ZeroDivisionError: division by zero"
			return null
		return DSLFloat.new(self_obj.value / a[1].value)
	
	func magic_floordiv(args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLObject:
		var self_obj = args[0]
		var other = args[1]
		other = DSLObject._unwrap_dsl(other)
		if other is DSLInteger or other is DSLFloat:
			var denom = other.value
			if denom == 0:
				self_obj.last_error = "ZeroDivisionError: division by zero"
				return null
			return DSLFloat.new(floor(self_obj.value / denom))
		self_obj._arithmetic_type_error("//", other)
		return null
	
	func magic_mod(args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLObject:
		var self_obj = args[0]
		var other = args[1]
		other = DSLObject._unwrap_dsl(other)
		if other is DSLInteger or other is DSLFloat:
			var v = other.value
			if v == 0:
				self_obj.last_error = "ZeroDivisionError: division by zero"
				return null
			return DSLFloat.new(fmod(self_obj.value, v))
		self_obj._arithmetic_type_error("%", other)
		return null
	
	func magic_pow(args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLObject:
		var self_obj = args[0]
		var other = args[1]
		other = DSLObject._unwrap_dsl(other)
		if other is DSLInteger or other is DSLFloat:
			return DSLFloat.new(pow(self_obj.value, other.value))
		self_obj._arithmetic_type_error("**", other)
		return null
	
	func magic_eq(args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLBool:
		var self_obj = args[0]
		var other = args[1]
		other = DSLObject._unwrap_dsl(other)
		return DSLBool.new((other is DSLFloat and self_obj.value == other.value) or (other is DSLInteger and self_obj.value == float(other.value)))
	
	func magic_ne(args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLBool:
		var self_obj = args[0]
		var other = args[1]
		other = DSLObject._unwrap_dsl(other)
		return DSLBool.new(not ((other is DSLFloat and self_obj.value == other.value) or (other is DSLInteger and self_obj.value == float(other.value))))
	
	func magic_lt(args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLBool:
		var self_obj = args[0]
		var other = args[1]
		other = DSLObject._unwrap_dsl(other)
		if other is DSLFloat:
			return DSLBool.new(self_obj.value < other.value)
		if other is DSLInteger:
			return DSLBool.new(self_obj.value < float(other.value))
		self_obj._comparison_type_error("<", other)
		return DSLBool.new(false)
	
	func magic_gt(args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLBool:
		var self_obj = args[0]
		var other = args[1]
		other = DSLObject._unwrap_dsl(other)
		if other is DSLFloat:
			return DSLBool.new(self_obj.value > other.value)
		if other is DSLInteger:
			return DSLBool.new(self_obj.value > float(other.value))
		self_obj._comparison_type_error(">", other)
		return DSLBool.new(false)
	
	func magic_le(args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLBool:
		var self_obj = args[0]
		var other = args[1]
		other = DSLObject._unwrap_dsl(other)
		if other is DSLFloat:
			return DSLBool.new(self_obj.value <= other.value)
		if other is DSLInteger:
			return DSLBool.new(self_obj.value <= float(other.value))
		self_obj._comparison_type_error("<=", other)
		return DSLBool.new(false)
	
	func magic_ge(args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLBool:
		var self_obj = args[0]
		var other = args[1]
		other = DSLObject._unwrap_dsl(other)
		if other is DSLFloat:
			return DSLBool.new(self_obj.value >= other.value)
		if other is DSLInteger:
			return DSLBool.new(self_obj.value >= float(other.value))
		self_obj._comparison_type_error(">=", other)
		return DSLBool.new(false)
	
	func magic_neg(args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLObject:
		return DSLFloat.new(-args[0].value)
	
	func magic_str(args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLString:
		return DSLString.new(str(args[0].value))
	
	func magic_repr(args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLObject:
		return DSLString.new(str(args[0].value))
	
	func magic_bool(args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLBool:
		return DSLBool.new(args[0].value != 0.0)
	
	func _dsl_str() -> String:
		return str(value)
	
	func _dsl_bool() -> bool:
		return value != 0.0
	
	func _dsl_eq(other: DSLObject) -> bool:
		other = DSLObject._unwrap_dsl(other)
		if other is DSLFloat:
			return value == other.value
		if other is DSLInteger:
			return value == float(other.value)
		if other is DSLBool:
			return (value != 0.0) == other.value
		return false
	
	func _dsl_getattribute(name: String) -> DSLObject:
		if _float_magic_descriptors.is_empty():
			_init_magic_descriptors()
		if _float_magic_descriptors.has(name):
			return _float_magic_descriptors[name].__get__(self, null)
		return super._dsl_getattribute(name)
	
	## 类型提升: 将操作数转为兼容类型 [br]
	## [param other] 另一个操作数 [br]
	## [returns] [self, other] 或 [self, DSLFloat(other)], 类型不兼容时返回 [null, null] (实际类型 Array[DSLObject])
	func _promote(other):
		other = DSLObject._unwrap_dsl(other)
		if other is DSLFloat:
			return [self, other]
		if other is DSLInteger:
			return [self, DSLFloat.new(float(other.value))]
		last_error = "TypeError: cannot operate float with " + other._type_name()
		return [null, null]
	
	## 初始化魔法方法描述符字典 [br]
	## 注册所有 Python float 类型的魔法方法
	func _init_magic_descriptors():
		_float_magic_descriptors = {
			"__add__": DSLWrappedDescriptor.new("__add__", Callable(self, "magic_add")),
			"__sub__": DSLWrappedDescriptor.new("__sub__", Callable(self, "magic_sub")),
			"__mul__": DSLWrappedDescriptor.new("__mul__", Callable(self, "magic_mul")),
			"__truediv__": DSLWrappedDescriptor.new("__truediv__", Callable(self, "magic_div")),
			"__floordiv__": DSLWrappedDescriptor.new("__floordiv__", Callable(self, "magic_floordiv")),
			"__mod__": DSLWrappedDescriptor.new("__mod__", Callable(self, "magic_mod")),
			"__pow__": DSLWrappedDescriptor.new("__pow__", Callable(self, "magic_pow")),
			"__eq__": DSLWrappedDescriptor.new("__eq__", Callable(self, "magic_eq")),
			"__ne__": DSLWrappedDescriptor.new("__ne__", Callable(self, "magic_ne")),
			"__lt__": DSLWrappedDescriptor.new("__lt__", Callable(self, "magic_lt")),
			"__gt__": DSLWrappedDescriptor.new("__gt__", Callable(self, "magic_gt")),
			"__le__": DSLWrappedDescriptor.new("__le__", Callable(self, "magic_le")),
			"__ge__": DSLWrappedDescriptor.new("__ge__", Callable(self, "magic_ge")),
			"__neg__": DSLWrappedDescriptor.new("__neg__", Callable(self, "magic_neg")),
			"__str__": DSLWrappedDescriptor.new("__str__", Callable(self, "magic_str")),
			"__repr__": DSLWrappedDescriptor.new("__repr__", Callable(self, "magic_repr")),
			"__bool__": DSLWrappedDescriptor.new("__bool__", Callable(self, "magic_bool")),
		}
	
## DSL 字符串类型, 对应 Python str
class DSLString extends DSLObject:
	## 底层的字符串值
	var value: String
	## str 类型的魔法方法描述符缓存 [br]
	## 存储各 Python 魔法方法对应的 DSLWrappedDescriptor
	var _str_magic_descriptors: Dictionary = {}
	## str 类型的方法描述符缓存 [br]
	## 存储各内置方法的 DSLMethodDescriptor
	static var _str_descriptors: Dictionary = {}
	## str 类型的原型实例 [br]
	## 用于方法描述符初始化
	static var _str_proto: DSLString
	
	## 构造字符串对象 [br]
	## [param v] 字符串值
	func _init(v):
		super._init()
		value = v
		
	func _type_name() -> String:
		return "str"
		
	func magic_add(args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLObject:
		var self_obj = args[0]
		var other = args[1]
		other = DSLObject._unwrap_dsl(other)
		if other is DSLString:
			return DSLString.new(self_obj.value + other.value)
		if other is DSLInteger:
			return DSLString.new(self_obj.value + str(other.value))
		if other is DSLFloat:
			return DSLString.new(self_obj.value + str(other.value))
		self_obj._arithmetic_type_error("+", other)
		return null
		
	func magic_mul(args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLObject:
		var self_obj = args[0]
		var other = args[1]
		other = DSLObject._unwrap_dsl(other)
		if other is DSLInteger:
			var result = ""
			for _i in range(other.value):
				result += self_obj.value
			return DSLString.new(result)
		self_obj._arithmetic_type_error("*", other)
		return null

	## str % 格式化: "%s: %d" % (x, y) [br]
	## 支持 printf 风格转换说明: %s %r %d %i %u %f %F %e %E %g %G %x %X %o %c %% [br]
	## 标志 (- + 空格 0), 宽度与精度
	func magic_mod(args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLObject:
		var self_obj = args[0]
		var other = args[1]
		var fmt = self_obj.value
		var values: Array[DSLObject] = []
		other = DSLObject._unwrap_dsl(other)
		if other is DSLTuple:
			values = other.items.duplicate()
		else:
			values = [other]
		return DSLString.new(_percent_format(fmt, values))

	## 执行 printf 风格格式化 [br]
	## [param fmt] 格式字符串 [br]
	## [param values] 待格式化值列表 [br]
	## [returns] 格式化结果字符串
	func _percent_format(fmt: String, values: Array[DSLObject]) -> String:
		var out = ""
		var vi = 0
		var i = 0
		while i < fmt.length():
			var ch = fmt[i]
			if ch != '%':
				out += ch
				i += 1
				continue
			if i + 1 < fmt.length() and fmt[i + 1] == '%':
				out += '%'
				i += 2
				continue
			i += 1
			var flags = ""
			while i < fmt.length() and fmt[i] in "-+ 0#":
				flags += fmt[i]
				i += 1
			var width = 0
			while i < fmt.length() and fmt[i].is_valid_int():
				width = width * 10 + int(fmt[i])
				i += 1
			var precision = -1
			if i < fmt.length() and fmt[i] == '.':
				i += 1
				precision = 0
				while i < fmt.length() and fmt[i].is_valid_int():
					precision = precision * 10 + int(fmt[i])
					i += 1
			if i >= fmt.length():
				break
			var conv = fmt[i]
			i += 1
			var val = values[vi] if vi < values.size() else null
			vi += 1
			out += _format_one(val, conv, width, precision, flags)
		return out

	## 格式化单个值
	func _format_one(val: DSLObject, conv: String, width: int, precision: int, flags: String) -> String:
		if val == null:
			return "%" + conv
		var s = ""
		var is_numeric = false
		match conv:
			's':
				s = val._dsl_str()
				if precision >= 0 and s.length() > precision:
					s = s.substr(0, precision)
			'r', 'a':
				var r = val.magic_repr([val] as Array[DSLObject], {} as Dictionary[String, DSLObject])
				s = r.value if r is DSLString else val._dsl_str()
			'd', 'i', 'u':
				is_numeric = true
				s = str(int(_num(val)))
			'x', 'X':
				is_numeric = true
				var n = int(_num(val))
				var body = _int_to_base_str(abs(n), 16)
				s = ("-" if n < 0 else "") + (body.to_upper() if conv == 'X' else body)
				if flags.find("#") != -1:
					s = ("-" if n < 0 else "") + ("0X" if conv == 'X' else "0x") + body
			'o':
				is_numeric = true
				var n = int(_num(val))
				s = ("-" if n < 0 else "") + _int_to_base_str(abs(n), 8)
			'c':
				s = char(int(_num(val)))
			'f', 'F':
				is_numeric = true
				s = _fixed_float_str(float(_num(val)), precision if precision >= 0 else 6)
			'e', 'E':
				is_numeric = true
				s = _sci_float_str(float(_num(val)), precision if precision >= 0 else 6, conv == 'E')
			'g', 'G':
				is_numeric = true
				s = _general_float_str(float(_num(val)), precision if precision >= 0 else 6, conv == 'G')
			_:
				return "%" + conv
		if is_numeric and not s.begins_with("-"):
			if flags.find("+") != -1:
				s = "+" + s
			elif flags.find(" ") != -1:
				s = " " + s
		if width > s.length():
			var pad = width - s.length()
			if flags.find("-") != -1:
				s = s + " ".repeat(pad)
			elif flags.find("0") != -1 and is_numeric:
				if s.length() > 0 and (s[0] == "-" or s[0] == "+" or s[0] == " "):
					s = s[0] + "0".repeat(pad) + s.substr(1)
				else:
					s = "0".repeat(pad) + s
			else:
				s = " ".repeat(pad) + s
		return s

	## 提取数值
	func _num(o: DSLObject) -> float:
		if o is DSLInteger:
			return float(o.value)
		if o is DSLFloat:
			return o.value
		return 0.0

	## 整数转任意进制字符串
	func _int_to_base_str(n: int, base: int) -> String:
		if n == 0:
			return "0"
		var chars = "0123456789abcdef"
		var result = ""
		while n > 0:
			result = chars[n % base] + result
			n /= base
		return result

	## 定点浮点格式化
	func _fixed_float_str(v: float, p: int) -> String:
		return ("%." + str(p) + "f") % v

	## 科学计数法格式化
	func _sci_float_str(v: float, p: int, upper: bool) -> String:
		if v == 0.0:
			return "0." + "0".repeat(p) + ("E" if upper else "e") + "+00"
		var e = _decimal_exp(v)
		var m = v / pow(10.0, e)
		if abs(m) >= 10.0:
			m /= 10.0
			e += 1
		if abs(m) < 1.0 and m != 0.0:
			m *= 10.0
			e -= 1
		var ms = ("%." + str(p) + "f") % m
		var es = ("+" if e >= 0 else "-") + ("0" if abs(e) < 10 else "") + str(int(abs(e)))
		return ms + ("E" if upper else "e") + es

	## 计算十进制指数, 修正浮点对数误差
	func _decimal_exp(v: float) -> int:
		var e = int(floor(log(abs(v)) / log(10.0)))
		var p10 = pow(10.0, e)
		if p10 > abs(v):
			e -= 1
		elif p10 * 10.0 <= abs(v):
			e += 1
		return e

	## 通用格式 g/G
	func _general_float_str(v: float, p: int, upper: bool) -> String:
		if v == 0.0:
			return "0"
		var e = _decimal_exp(v)
		if e < -4 or e >= p:
			var mp = p - 1
			if mp < 0:
				mp = 0
			return _strip_g_zeros(_sci_float_str(v, mp, upper))
		var dec = p - 1 - int(e)
		if dec < 0:
			dec = 0
		return _strip_g_zeros(("%." + str(dec) + "f") % v)

	## 去除 g 格式尾部的零
	func _strip_g_zeros(s: String) -> String:
		var ei = -1
		var ep = ""
		for i in range(s.length()):
			if s[i] == "e" or s[i] == "E":
				ei = i
				ep = s.substr(i)
				break
		var mant = s if ei == -1 else s.substr(0, ei)
		if mant.find(".") != -1:
			while mant.ends_with("0"):
				mant = mant.substr(0, mant.length() - 1)
			if mant.ends_with("."):
				mant = mant.substr(0, mant.length() - 1)
		return mant + ep

	## 千分位逗号 [br]
	## [param s] 数字字符串 [br]
	## [returns] 加入千分位逗号的结果
	func _add_thousands(s: String) -> String:
		var neg = s.begins_with("-")
		if neg:
			s = s.substr(1)
		var dot = s.find(".")
		var int_part = s if dot == -1 else s.substr(0, dot)
		var frac = "" if dot == -1 else s.substr(dot)
		var result = ""
		var count = 0
		for i in range(int_part.length() - 1, -1, -1):
			result = int_part[i] + result
			count += 1
			if count % 3 == 0 and i > 0:
				result = "," + result
		return (("-" if neg else "") + result + frac)

	## 按 str.format 迷你格式说明符格式化值 [br]
	## 支持 [code][[fill]align][sign][#][0][width][,][.precision][type][/code] [br]
	## [param value] 值对象 [br]
	## [param spec] 格式说明符 [br]
	## [param pre] 预转换字符串 (用于 !r/!s 转换后再应用对齐宽度) [br]
	## [returns] 格式化字符串
	func _format_spec_value(value: DSLObject, spec: String, pre: String = "") -> String:
		var is_numeric = (value is DSLInteger) or (value is DSLFloat)
		if spec == "":
			if pre != "":
				return pre
			return value._dsl_str()
		var i = 0
		var fill = " "
		var align = ""
		var sign = ""
		var alt = false
		var zero_pad = false
		var width = 0
		var comma = false
		var precision = -1
		var type_c = ""
		# [[fill]align]
		if i < spec.length() and spec[i] in "<>^=":
			align = spec[i]
			i += 1
		elif i + 1 < spec.length() and spec[i + 1] in "<>^=":
			fill = spec[i]
			align = spec[i + 1]
			i += 2
		# [sign]
		if i < spec.length() and spec[i] in "+- ":
			sign = spec[i]
			i += 1
		# [#]
		if i < spec.length() and spec[i] == "#":
			alt = true
			i += 1
		# [0]
		if i < spec.length() and spec[i] == "0":
			zero_pad = true
			i += 1
		# [width]
		while i < spec.length() and spec[i].is_valid_int():
			width = width * 10 + int(spec[i])
			i += 1
		# [,]
		if i < spec.length() and spec[i] == ",":
			comma = true
			i += 1
		# [.precision]
		if i < spec.length() and spec[i] == ".":
			i += 1
			precision = 0
			while i < spec.length() and spec[i].is_valid_int():
				precision = precision * 10 + int(spec[i])
				i += 1
		# [type]
		if i < spec.length():
			type_c = spec[i]
			i += 1
		# 计算基础字符串
		var s = ""
		if pre != "":
			s = pre
			if precision >= 0 and type_c == "s":
				s = s.substr(0, min(precision, s.length()))
		else:
			s = _format_spec_base(value, type_c, precision, comma)
		# 符号前缀
		if is_numeric and sign != "" and not s.begins_with("-"):
			if sign == "+":
				s = "+" + s
			elif sign == " ":
				s = " " + s
		# 备用形式 (进制前缀)
		if alt and type_c in ["x", "X", "o", "b"] and is_numeric:
			var prefix = "0x" if type_c == "x" else ("0X" if type_c == "X" else ("0o" if type_c == "o" else "0b"))
			if not s.begins_with(prefix):
				s = prefix + s
		# 零填充
		if zero_pad and align == "" and width > s.length():
			var pad = width - s.length()
			if s.length() > 0 and (s[0] == "-" or s[0] == "+" or s[0] == " "):
				s = s[0] + "0".repeat(pad) + s.substr(1)
			else:
				s = "0".repeat(pad) + s
		# 对齐与宽度
		if width > s.length():
			var pad = width - s.length()
			if align == ">":
				s = fill.repeat(pad) + s
			elif align == "^":
				var left = pad / 2
				s = fill.repeat(left) + s + fill.repeat(pad - left)
			elif align == "=":
				if s.length() > 0 and (s[0] == "-" or s[0] == "+" or s[0] == " "):
					s = s[0] + fill.repeat(pad) + s.substr(1)
				else:
					s = fill.repeat(pad) + s
			else:
				# 默认: 数值右对齐, 字符串左对齐
				if is_numeric and align == "":
					s = fill.repeat(pad) + s
				else:
					s = s + fill.repeat(pad)
		return s

	## 按类型字符计算 str.format 的基础字符串 [br]
	## [param value] 值对象 [br]
	## [param type_c] 类型字符 [br]
	## [param precision] 精度 (-1 未指定) [br]
	## [param comma] 是否千分位 [br]
	## [returns] 基础格式化字符串
	func _format_spec_base(value: DSLObject, type_c: String, precision: int, comma: bool) -> String:
		var is_int = value is DSLInteger
		var is_float = value is DSLFloat
		if type_c == "s":
			return value._dsl_str()
		if type_c == "c":
			var code = value.value if is_int else int(value._dsl_str())
			return char(code)
		if type_c in ["x", "X", "o", "b"]:
			var n = value.value if is_int else int(_num(value))
			var neg = n < 0
			var body = ""
			match type_c:
				"x": body = _int_to_base_str(abs(n), 16)
				"X": body = _int_to_base_str(abs(n), 16).to_upper()
				"o": body = _int_to_base_str(abs(n), 8)
				"b": body = _int_to_base_str(abs(n), 2)
			if comma:
				body = _add_thousands(body)
			return ("-" if neg else "") + body
		if type_c == "d":
			var n = value.value if is_int else int(_num(value))
			var body = str(n)
			return _add_thousands(body) if comma else body
		if type_c in ["f", "F"]:
			var num = float(value.value) if is_int else value.value
			var p = precision if precision >= 0 else 6
			var body = _fixed_float_str(num, p)
			return _add_thousands(body) if comma else body
		if type_c in ["e", "E"]:
			var num = float(value.value) if is_int else value.value
			var p = precision if precision >= 0 else 6
			return _sci_float_str(num, p, type_c == "E")
		if type_c in ["g", "G"]:
			var num = float(value.value) if is_int else value.value
			return _general_float_str(num, precision if precision >= 0 else 6, type_c == "G")
		if type_c == "%":
			var num = float(value.value) if is_int else value.value
			var p = precision if precision >= 0 else 6
			return _fixed_float_str(num * 100.0, p) + "%"
		# 默认: 数值按 str, 浮点若有精度则定点
		if is_float and precision >= 0:
			return _fixed_float_str(value.value, precision)
		return value._dsl_str()

	## 解析单个 str.format 字段并格式化 [br]
	## 字段格式: [[index|name][!conv][:spec]] [br]
	## [param field] 字段内容 [br]
	## [param fmt_args] 位置参数数组 [br]
	## [param kwargs] 关键字参数字典 [br]
	## [param idx_box] 自动编号计数器 (数组引用, idx_box[0]) [br]
	## [returns] 格式化字符串
	func _format_field(field: String, fmt_args: Array, kwargs: Dictionary, idx_box: Array) -> String:
		var idx_str = field
		var conv = ""
		var spec = ""
		var bang = field.find("!")
		var colon = field.find(":")
		if bang != -1:
			idx_str = field.substr(0, bang)
			var after = field.substr(bang + 1)
			var colon2 = after.find(":")
			if colon2 != -1:
				conv = after.substr(0, colon2)
				spec = after.substr(colon2 + 1)
			else:
				conv = after
		elif colon != -1:
			idx_str = field.substr(0, colon)
			spec = field.substr(colon + 1)
		# 解析索引/名称
		var val: DSLObject = null
		if idx_str == "":
			var a = idx_box[0]
			if a < fmt_args.size():
				val = fmt_args[a]
			idx_box[0] = a + 1
		elif idx_str.is_valid_int():
			var a = int(idx_str)
			if a >= 0 and a < fmt_args.size():
				val = fmt_args[a]
		else:
			if kwargs.has(idx_str):
				val = kwargs[idx_str]
		if val == null:
			return ""
		# 应用转换标志
		if conv == "r" or conv == "a":
			var r = val.magic_repr([val] as Array[DSLObject], {} as Dictionary[String, DSLObject])
			var rs = r.value if r is DSLString else val._dsl_str()
			if spec != "":
				return _format_spec_value(val, spec, rs)
			return rs
		if conv == "s":
			var st = val.magic_str([val] as Array[DSLObject], {} as Dictionary[String, DSLObject])
			var ss = st.value if st is DSLString else val._dsl_str()
			if spec != "":
				return _format_spec_value(val, spec, ss)
			return ss
		if spec != "":
			return _format_spec_value(val, spec)
		return val._dsl_str()

	func magic_eq(args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLBool:
		var self_obj = args[0]
		var other = args[1]
		other = DSLObject._unwrap_dsl(other)
		return DSLBool.new((other is DSLString) and self_obj.value == other.value)
		
	func magic_ne(args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLBool:
		var self_obj = args[0]
		var other = args[1]
		other = DSLObject._unwrap_dsl(other)
		return DSLBool.new(not ((other is DSLString) and self_obj.value == other.value))
		
	func magic_lt(args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLBool:
		var self_obj = args[0]
		var other = args[1]
		other = DSLObject._unwrap_dsl(other)
		if other is DSLString:
			return DSLBool.new(self_obj.value < other.value)
		self_obj._comparison_type_error("<", other)
		return DSLBool.new(false)
		
	func magic_gt(args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLBool:
		var self_obj = args[0]
		var other = args[1]
		other = DSLObject._unwrap_dsl(other)
		if other is DSLString:
			return DSLBool.new(self_obj.value > other.value)
		self_obj._comparison_type_error(">", other)
		return DSLBool.new(false)
		
	func magic_le(args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLBool:
		var self_obj = args[0]
		var other = args[1]
		other = DSLObject._unwrap_dsl(other)
		if other is DSLString:
			return DSLBool.new(self_obj.value <= other.value)
		self_obj._comparison_type_error("<=", other)
		return DSLBool.new(false)
		
	func magic_ge(args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLBool:
		var self_obj = args[0]
		var other = args[1]
		other = DSLObject._unwrap_dsl(other)
		if other is DSLString:
			return DSLBool.new(self_obj.value >= other.value)
		self_obj._comparison_type_error(">=", other)
		return DSLBool.new(false)
		
	func magic_getitem(args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLObject:
		var self_obj = args[0]
		var index = args[1]
		if index is DSLInteger:
			var i = index.value
			if i < 0:
				i = i + self_obj.value.length()
			if i < 0 or i >= self_obj.value.length():
				self_obj.last_error = "IndexError: string index out of range"
				return null
			return DSLString.new(self_obj.value[i])
		if index is DSLSlice:
			var s = self_obj.value
			var start_idx = s.length() - 1 if (index.step != null and not index.step is DSLNone and index.step.value < 0) else 0
			var stop_idx = -1 if (index.step != null and not index.step is DSLNone and index.step.value < 0) else s.length()
			var step_val = 1
			if index.start != null and not index.start is DSLNone:
				start_idx = index.start.value
				if start_idx < 0:
					start_idx = start_idx + s.length()
			if index.stop != null and not index.stop is DSLNone:
				stop_idx = index.stop.value
				if stop_idx < 0:
					stop_idx = stop_idx + s.length()
			if index.step != null and not index.step is DSLNone:
				step_val = index.step.value
			var result = ""
			var i = start_idx
			if step_val > 0:
				while i < stop_idx and i < s.length():
					if i >= 0:
						result += s[i]
					i = i + step_val
			elif step_val < 0:
				while i > stop_idx and i >= 0:
					if i < s.length():
						result += s[i]
					i = i + step_val
			return DSLString.new(result)
		return self_obj._index_type_error(index)
		
	func magic_str(args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLString:
		return DSLString.new(args[0].value)
		
	func magic_repr(args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLObject:
		return DSLString.new("'" + args[0].value + "'")
		
	func magic_bool(args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLBool:
		return DSLBool.new(args[0].value.length() > 0)
	
	func magic_contains(args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLObject:
		var self_obj = args[0]
		var item = args[1]
		item = DSLObject._unwrap_dsl(item)
		if item is DSLString:
			return DSLBool.new(self_obj.value.find(item.value) != -1)
		return DSLBool.new(false)
	
	func _dsl_str() -> String:
		return value
	
	func _dsl_bool() -> bool:
		return value.length() > 0
	
	func _dsl_eq(other: DSLObject) -> bool:
		other = DSLObject._unwrap_dsl(other)
		if other is DSLString:
			return value == other.value
		return false
	
	func _dsl_iter() -> DSLIterator:
		return DSLStringIterator.new(value)
	
	func _dsl_getattribute(name: String) -> DSLObject:
		if _str_magic_descriptors.is_empty():
			_init_magic_descriptors()
		if _str_magic_descriptors.has(name):
			return _str_magic_descriptors[name].__get__(self, null)
		_ensure_str_descriptors()
		if _str_descriptors.has(name):
			return _str_descriptors[name].__get__(self, null)
		return super._dsl_getattribute(name)
	
	func builtin_upper(args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLObject:
		var obj = args[0]
		var raw = DSLObject._unwrap_dsl(obj)
		return DSLString.new(raw.value.to_upper())
	
	func builtin_lower(args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLObject:
		var obj = args[0]
		var raw = DSLObject._unwrap_dsl(obj)
		return DSLString.new(raw.value.to_lower())
	
	func builtin_strip(args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLObject:
		var obj = args[0]
		var raw = DSLObject._unwrap_dsl(obj)
		var s = raw.value
		if args.size() >= 2:
			var chars = args[1]._dsl_str()
			var start_idx = 0
			var end_idx = s.length() - 1
			while start_idx < s.length() and chars.find(s[start_idx]) != -1:
				start_idx += 1
			while end_idx >= 0 and chars.find(s[end_idx]) != -1:
				end_idx -= 1
			if start_idx > end_idx:
				return DSLString.new("")
			return DSLString.new(s.substr(start_idx, end_idx - start_idx + 1))
		return DSLString.new(s.strip_edges())
	
	func builtin_split(args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLObject:
		var obj = args[0]
		var raw = DSLObject._unwrap_dsl(obj)
		var sep = ""
		var maxsplit = -1
		var use_default = false
		if args.size() >= 2 and not args[1] is DSLNone:
			sep = args[1]._dsl_str()
		else:
			use_default = true
		if args.size() >= 3:
			var maxsplit_arg = args[2]
			if maxsplit_arg is DSLInteger:
				maxsplit = maxsplit_arg.value
		var result = DSLList.new()
		if use_default:
			# Default: split on whitespace, removing empty strings
			var s = raw.value.strip_edges()
			var words = s.split(" ", false)
			var words_filtered = []
			for w in words:
				if w != "":
					words_filtered.append(w)
			if maxsplit >= 0 and words_filtered.size() > maxsplit + 1:
				var remaining = ""
				for i in range(maxsplit, words_filtered.size()):
					if i > maxsplit:
						remaining += " "
					remaining += words_filtered[i]
				words_filtered = words_filtered.slice(0, maxsplit)
				words_filtered.append(remaining)
			for w in words_filtered:
				result.items.append(DSLString.new(w))
		elif sep == "":
			for ch in raw.value:
				result.items.append(DSLString.new(ch))
		else:
			var s = raw.value
			if maxsplit <= 0:
				var parts = s.split(sep)
				for p in parts:
					result.items.append(DSLString.new(p))
			else:
				var remaining = s
				var splits_done = 0
				while splits_done < maxsplit:
					var idx = remaining.find(sep)
					if idx == -1:
						break
					result.items.append(DSLString.new(remaining.substr(0, idx)))
					remaining = remaining.substr(idx + sep.length())
					splits_done += 1
				result.items.append(DSLString.new(remaining))
		return result
	
	func builtin_join(args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLObject:
		var obj = args[0]
		var raw = DSLObject._unwrap_dsl(obj)
		if args.size() != 2:
			last_error = "TypeError: join() takes exactly one argument"
			return null
		var iterable = args[1]
		var it_raw = iterable
		if it_raw._wrapped != null:
			it_raw = it_raw._wrapped
		var parts = []
		if it_raw is DSLList or it_raw is DSLTuple:
			for item in it_raw.items:
				parts.append(item._dsl_str())
		else:
			var it = it_raw._dsl_iter()
			if it == null:
				last_error = "TypeError: argument must be iterable"
				return null
			while it.has_next():
				parts.append(it.next()._dsl_str())
		return DSLString.new(raw.value.join(parts))
	
	func builtin_replace(args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLObject:
		var obj = args[0]
		var raw = DSLObject._unwrap_dsl(obj)
		if args.size() < 3:
			last_error = "TypeError: replace() takes at least two arguments"
			return null
		var s = raw.value
		var old = args[1]._dsl_str()
		var new_s = args[2]._dsl_str()
		var count = -1
		if args.size() >= 4 and args[3] is DSLInteger:
			count = args[3].value
		if old == "":
			return DSLString.new(s)
		var result = ""
		var i = 0
		var replaced = 0
		while i < s.length():
			var idx = s.find(old, i)
			if idx == -1 or (count >= 0 and replaced >= count):
				result += s.substr(i)
				break
			result += s.substr(i, idx - i) + new_s
			i = idx + old.length()
			replaced += 1
		return DSLString.new(result)
		
	func builtin_find(args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLObject:
		var obj = args[0]
		var raw = DSLObject._unwrap_dsl(obj)
		if args.size() < 2:
			last_error = "TypeError: find() takes at least one argument"
			return null
		var s = raw.value
		var sub = args[1]._dsl_str()
		var si = 0
		var ei = s.length()
		if args.size() >= 3 and args[2] is DSLInteger:
			si = args[2].value
			if si < 0:
				si = max(0, si + s.length())
		if args.size() >= 4 and args[3] is DSLInteger:
			ei = args[3].value
			if ei < 0:
				ei = max(0, ei + s.length())
		if si >= s.length() or ei <= si:
			return DSLInteger.new(-1)
		var sliced = s.substr(si, ei - si)
		var p = sliced.find(sub)
		if p == -1:
			return DSLInteger.new(-1)
		return DSLInteger.new(p + si)

	## str.index(sub[, start[, end]]) - 查找子串, 找不到抛 ValueError
	func builtin_index(args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLObject:
		var found = builtin_find(args, _kwargs)
		if found is DSLInteger and found.value == -1:
			last_error = "ValueError: substring not found"
			return null
		return found

	## str.rfind(sub[, start[, end]]) - 从右向左查找
	func builtin_rfind(args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLObject:
		var obj = args[0]
		var raw = DSLObject._unwrap_dsl(obj)
		if args.size() < 2:
			last_error = "TypeError: rfind() takes at least one argument"
			return null
		var s = raw.value
		var sub = args[1]._dsl_str()
		var si = 0
		var ei = s.length()
		if args.size() >= 3 and args[2] is DSLInteger:
			si = args[2].value
			if si < 0:
				si = max(0, si + s.length())
		if args.size() >= 4 and args[3] is DSLInteger:
			ei = args[3].value
			if ei < 0:
				ei = max(0, ei + s.length())
		ei = min(ei, s.length())
		if sub == "":
			return DSLInteger.new(min(max(si, 0), ei))
		var p = -1
		if ei > si:
			var idx = si
			while idx < s.length():
				var f = s.find(sub, idx)
				if f == -1 or f + sub.length() > ei:
					break
				p = f
				idx = f + 1
		return DSLInteger.new(p)

	## str.rindex(sub) - 从右向左查找, 找不到抛 ValueError
	func builtin_rindex(args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLObject:
		var found = builtin_rfind(args, _kwargs)
		if found is DSLInteger and found.value == -1:
			last_error = "ValueError: substring not found"
			return null
		return found

	## str.splitlines([keepends]) - 按行边界拆分 [br]
	## 尾部换行符不产生多余的空行 (与 Python 一致)
	func builtin_splitlines(args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLObject:
		var raw = DSLObject._unwrap_dsl(args[0]).value
		var keepends = false
		if args.size() >= 2 and args[1] is DSLBool:
			keepends = args[1].value
		var lines = []
		var start = 0
		var i = 0
		while i < raw.length():
			if raw[i] == '\n' or raw[i] == '\r':
				var line = raw.substr(start, i - start)
				var term = raw[i]
				var term_len = 1
				if raw[i] == '\r' and i + 1 < raw.length() and raw[i + 1] == '\n':
					term = "\r\n"
					term_len = 2
				if keepends:
					line += term
				lines.append(line)
				i += term_len
				start = i
			else:
				i += 1
		if start < raw.length():
			lines.append(raw.substr(start))
		var lst = DSLList.new()
		for line in lines:
			lst.items.append(DSLString.new(line))
		return lst

	## str.removeprefix(prefix)
	func builtin_removeprefix(args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLObject:
		var raw = DSLObject._unwrap_dsl(args[0]).value
		var prefix = args[1]._dsl_str()
		if raw.begins_with(prefix):
			return DSLString.new(raw.substr(prefix.length()))
		return DSLString.new(raw)

	## str.removesuffix(suffix)
	func builtin_removesuffix(args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLObject:
		var raw = DSLObject._unwrap_dsl(args[0]).value
		var suffix = args[1]._dsl_str()
		if suffix != "" and raw.ends_with(suffix):
			return DSLString.new(raw.substr(0, raw.length() - suffix.length()))
		return DSLString.new(raw)

	## str.partition(sep) - 分割为 (head, sep, tail)
	func builtin_partition(args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLObject:
		var raw = DSLObject._unwrap_dsl(args[0]).value
		var sep = args[1]._dsl_str()
		var p = raw.find(sep)
		if p == -1 or sep == "":
			return DSLTuple.new([DSLString.new(raw), DSLString.new(""), DSLString.new("")])
		return DSLTuple.new([DSLString.new(raw.substr(0, p)), DSLString.new(sep), DSLString.new(raw.substr(p + sep.length()))])

	## str.rpartition(sep) - 从右向左分割
	func builtin_rpartition(args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLObject:
		var raw = DSLObject._unwrap_dsl(args[0]).value
		var sep = args[1]._dsl_str()
		var p = raw.rfind(sep)
		if p == -1 or sep == "":
			return DSLTuple.new([DSLString.new(""), DSLString.new(""), DSLString.new(raw)])
		return DSLTuple.new([DSLString.new(raw.substr(0, p)), DSLString.new(sep), DSLString.new(raw.substr(p + sep.length()))])

	## str.isdecimal()
	func builtin_isdecimal(args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLObject:
		var raw = DSLObject._unwrap_dsl(args[0]).value
		if raw.length() == 0:
			return DSLBool.new(false)
		for ch in raw:
			if not ch.is_valid_int():
				return DSLBool.new(false)
		return DSLBool.new(true)

	## str.isnumeric() (等价于 isdecimal)
	func builtin_isnumeric(args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLObject:
		return builtin_isdecimal(args, _kwargs)

	## str.isprintable()
	func builtin_isprintable(args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLObject:
		var raw = DSLObject._unwrap_dsl(args[0]).value
		for ch in raw:
			if ch == '\n' or ch == '\t' or ch == '\r':
				return DSLBool.new(false)
		return DSLBool.new(true)

	## str.isascii()
	func builtin_isascii(args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLObject:
		var raw = DSLObject._unwrap_dsl(args[0]).value
		for ch in raw:
			if ch.unicode_at(0) > 127:
				return DSLBool.new(false)
		return DSLBool.new(true)

	## str.isidentifier()
	func builtin_isidentifier(args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLObject:
		var raw = DSLObject._unwrap_dsl(args[0]).value
		if raw.length() == 0:
			return DSLBool.new(false)
		if not (raw[0].is_valid_identifier() or raw[0] == "_"):
			return DSLBool.new(false)
		for i in range(1, raw.length()):
			var ch = raw[i]
			if not (ch.is_valid_identifier() or ch.is_valid_int() or ch == "_"):
				return DSLBool.new(false)
		return DSLBool.new(true)

	## str.expandtabs([tabsize])
	func builtin_expandtabs(args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLObject:
		var raw = DSLObject._unwrap_dsl(args[0]).value
		var tabsize = 8
		if args.size() >= 2 and args[1] is DSLInteger:
			tabsize = args[1].value
		if tabsize <= 0:
			return DSLString.new(raw.replace("\t", ""))
		var result = ""
		var col = 0
		for ch in raw:
			if ch == '\t':
				var pad = tabsize - (col % tabsize)
				result += " ".repeat(pad)
				col += pad
			else:
				result += ch
				col += 1
				if ch == '\n':
					col = 0
		return DSLString.new(result)

	func builtin_startswith(args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLObject:
		var obj = args[0]
		var raw = DSLObject._unwrap_dsl(obj)
		if args.size() != 2:
			last_error = "TypeError: startswith() takes exactly one argument"
			return null
		return DSLBool.new(raw.value.begins_with(args[1]._dsl_str()))
	
	func builtin_endswith(args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLObject:
		var obj = args[0]
		var raw = DSLObject._unwrap_dsl(obj)
		if args.size() != 2:
			last_error = "TypeError: endswith() takes exactly one argument"
			return null
		return DSLBool.new(raw.value.ends_with(args[1]._dsl_str()))
	
	func builtin_lstrip(args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLObject:
		var obj = args[0]
		var raw = DSLObject._unwrap_dsl(obj)
		var s = raw.value
		if args.size() >= 2:
			var chars = args[1]._dsl_str()
			var start = 0
			while start < s.length() and chars.find(s[start]) != -1:
				start += 1
			return DSLString.new(s.substr(start))
		return DSLString.new(s.lstrip(" \t\n\r"))
	
	func builtin_rstrip(args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLObject:
		var obj = args[0]
		var raw = DSLObject._unwrap_dsl(obj)
		var s = raw.value
		if args.size() >= 2:
			var chars = args[1]._dsl_str()
			var end = s.length() - 1
			while end >= 0 and chars.find(s[end]) != -1:
				end -= 1
			return DSLString.new(s.substr(0, end + 1))
		return DSLString.new(s.rstrip(" \t\n\r"))
	
	func builtin_capitalize(args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLObject:
		var s = DSLObject._unwrap_dsl(args[0]).value
		if s.length() == 0:
			return DSLString.new("")
		return DSLString.new(s[0].to_upper() + s.substr(1).to_lower())
	
	func builtin_casefold(args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLObject:
		return DSLString.new(DSLObject._unwrap_dsl(args[0]).value.to_lower())
	
	func builtin_title(args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLObject:
		var raw = DSLObject._unwrap_dsl(args[0]).value
		var r = ""
		var iw = false
		for i in range(raw.length()):
			var ch = raw[i]
			if ch.is_valid_int() or (ch >= 'a' and ch <= 'z') or (ch >= 'A' and ch <= 'Z'):
				if not iw:
					r += ch.to_upper()
					iw = true
				else:
					r += ch.to_lower()
			else:
				r += ch
				iw = false
		return DSLString.new(r)
	
	func builtin_swapcase(args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLObject:
		var raw = DSLObject._unwrap_dsl(args[0]).value
		var r = ""
		for i in range(raw.length()):
			var ch = raw[i]
			if ch >= 'a' and ch <= 'z':
				r += ch.to_upper()
			elif ch >= 'A' and ch <= 'Z':
				r += ch.to_lower()
			else:
				r += ch
		return DSLString.new(r)
	
	func builtin_count(args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLObject:
		var obj = args[0]
		var raw = DSLObject._unwrap_dsl(obj)
		if args.size() < 2:
			raw.last_error = "TypeError: count() takes at least 1 argument"
			return null
		var sub = args[1]._dsl_str()
		var sv = raw.value
		var si = 0
		var ei = sv.length()
		if args.size() >= 3 and args[2] is DSLInteger:
			si = args[2].value
			if si < 0:
				si = max(0, si + sv.length())
		if args.size() >= 4 and args[3] is DSLInteger:
			ei = args[3].value
			if ei < 0:
				ei = max(0, ei + sv.length())
			ei = min(ei, sv.length())
		sv = sv.substr(si, ei - si)
		var cnt = 0
		var pos = 0
		while true:
			pos = sv.find(sub, pos)
			if pos == -1:
				break
			cnt += 1
			pos += sub.length()
		return DSLInteger.new(cnt)
	
	func builtin_isdigit(args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLObject:
		var raw = DSLObject._unwrap_dsl(args[0]).value
		if raw.length() == 0:
			return DSLBool.new(false)
		for ch in raw:
			if not ch.is_valid_int():
				return DSLBool.new(false)
		return DSLBool.new(true)
	
	func builtin_isalpha(args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLObject:
		var raw = DSLObject._unwrap_dsl(args[0]).value
		if raw.length() == 0:
			return DSLBool.new(false)
		for ch in raw:
			if not ((ch >= 'a' and ch <= 'z') or (ch >= 'A' and ch <= 'Z')):
				return DSLBool.new(false)
		return DSLBool.new(true)
	
	func builtin_isalnum(args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLObject:
		var raw = DSLObject._unwrap_dsl(args[0]).value
		if raw.length() == 0:
			return DSLBool.new(false)
		for ch in raw:
			if not (ch.is_valid_int() or (ch >= 'a' and ch <= 'z') or (ch >= 'A' and ch <= 'Z')):
				return DSLBool.new(false)
		return DSLBool.new(true)
	
	func builtin_isspace(args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLObject:
		var raw = DSLObject._unwrap_dsl(args[0]).value
		if raw.length() == 0:
			return DSLBool.new(false)
		for ch in raw:
			if not (ch == ' ' or ch == '\t' or ch == '\n' or ch == '\r'):
				return DSLBool.new(false)
		return DSLBool.new(true)
	
	func builtin_islower(args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLObject:
		var raw = DSLObject._unwrap_dsl(args[0]).value
		var ha = false
		for ch in raw:
			if (ch >= 'a' and ch <= 'z') or (ch >= 'A' and ch <= 'Z'):
				ha = true
				if ch >= 'A' and ch <= 'Z':
					return DSLBool.new(false)
		return DSLBool.new(ha)
	
	func builtin_isupper(args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLObject:
		var raw = DSLObject._unwrap_dsl(args[0]).value
		var ha = false
		for ch in raw:
			if (ch >= 'a' and ch <= 'z') or (ch >= 'A' and ch <= 'Z'):
				ha = true
				if ch >= 'a' and ch <= 'z':
					return DSLBool.new(false)
		return DSLBool.new(ha)
	
	func builtin_istitle(args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLObject:
		var raw = DSLObject._unwrap_dsl(args[0]).value
		var ha = false
		var iw = false
		for i in range(raw.length()):
			var ch = raw[i]
			if ch.is_valid_int() or (ch >= 'a' and ch <= 'z') or (ch >= 'A' and ch <= 'Z'):
				ha = true
				if not iw:
					if ch >= 'a' and ch <= 'z':
						return DSLBool.new(false)
					iw = true
				else:
					if ch >= 'A' and ch <= 'Z':
						return DSLBool.new(false)
			else:
				iw = false
		return DSLBool.new(ha)
	
	func builtin_center(args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLObject:
		var obj = args[0]
		var raw = DSLObject._unwrap_dsl(obj)
		if args.size() < 2:
			raw.last_error = "TypeError: center() takes at least 1 argument"
			return null
		var s = raw.value
		var width = 0
		if args[1] is DSLInteger:
			width = args[1].value
		var fill = " "
		if args.size() >= 3 and args[2] is DSLString:
			fill = args[2].value
			if fill.length() == 0:
				fill = " "
		if s.length() >= width:
			return DSLString.new(s)
		var padding = width - s.length()
		var left = padding / 2
		var right = padding - left
		var r = ""
		for j in range(left):
			r += fill[0]
		r += s
		for k in range(right):
			r += fill[0]
		return DSLString.new(r)
	
	func builtin_ljust(args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLObject:
		var obj = args[0]
		var raw = DSLObject._unwrap_dsl(obj)
		if args.size() < 2:
			raw.last_error = "TypeError: ljust() takes at least 1 argument"
			return null
		var s = raw.value
		var width = 0
		if args[1] is DSLInteger:
			width = args[1].value
		var fill = " "
		if args.size() >= 3 and args[2] is DSLString:
			fill = args[2].value
			if fill.length() == 0:
				fill = " "
		if s.length() >= width:
			return DSLString.new(s)
		var r = s
		while r.length() < width:
			r += fill[0]
		return DSLString.new(r)
	
	func builtin_rjust(args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLObject:
		var obj = args[0]
		var raw = DSLObject._unwrap_dsl(obj)
		if args.size() < 2:
			raw.last_error = "TypeError: rjust() takes at least 1 argument"
			return null
		var s = raw.value
		var width = 0
		if args[1] is DSLInteger:
			width = args[1].value
		var fill = " "
		if args.size() >= 3 and args[2] is DSLString:
			fill = args[2].value
			if fill.length() == 0:
				fill = " "
		if s.length() >= width:
			return DSLString.new(s)
		var r = s
		while r.length() < width:
			r = fill[0] + r
		return DSLString.new(r)
	
	func builtin_zfill(args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLObject:
		var obj = args[0]
		var raw = DSLObject._unwrap_dsl(obj)
		if args.size() < 2:
			raw.last_error = "TypeError: zfill() takes exactly 1 argument"
			return null
		var s = raw.value
		var width = 0
		if args[1] is DSLInteger:
			width = args[1].value
		if s.length() >= width:
			return DSLString.new(s)
		var r = s
		while r.length() < width:
			r = "0" + r
		return DSLString.new(r)
	
	func builtin_rsplit(args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLObject:
		var obj = args[0]
		var raw = DSLObject._unwrap_dsl(obj)
		var s = raw.value
		var sep = ""
		var maxsplit = -1
		var use_default = false
		if args.size() >= 2 and not args[1] is DSLNone:
			sep = args[1]._dsl_str()
		else:
			use_default = true
		if args.size() >= 3 and args[2] is DSLInteger:
			maxsplit = args[2].value
		var result = DSLList.new()
		if use_default:
			var words = s.strip_edges().split(" ", false)
			var wf = []
			for w in words:
				if w != "":
					wf.append(w)
			if maxsplit >= 0 and wf.size() > maxsplit + 1:
				var rm = ""
				for i in range(maxsplit, wf.size()):
					if i > maxsplit:
						rm += " "
					rm += wf[i]
				wf = wf.slice(0, maxsplit)
				wf.append(rm)
			wf.reverse()
			for w in wf:
				result.items.append(DSLString.new(w))
		else:
			var parts = []
			var remaining = s
			var cnt = 0
			while remaining.length() > 0:
				if maxsplit >= 0 and cnt >= maxsplit:
					parts.append(remaining)
					break
				var pos = remaining.rfind(sep)
				if pos == -1:
					parts.append(remaining)
					break
				parts.append(remaining.substr(pos + sep.length()))
				remaining = remaining.substr(0, pos)
				cnt += 1
			parts.reverse()
			for p in parts:
				result.items.append(DSLString.new(p))
		return result
	
	func builtin_format(args: Array[DSLObject], kwargs: Dictionary[String, DSLObject]) -> DSLObject:
		var obj = args[0]
		var raw = DSLObject._unwrap_dsl(obj)
		var template = raw.value
		var fmt_args = args.slice(1)
		var result = ""
		var idx_box = [0]
		var i = 0
		while i < template.length():
			# 转义的花括号 {{ 与 }}
			if template[i] == '{' and i + 1 < template.length() and template[i + 1] == '{':
				result += '{'
				i += 2
				continue
			if template[i] == '}' and i + 1 < template.length() and template[i + 1] == '}':
				result += '}'
				i += 2
				continue
			if template[i] == '{':
				# 查找匹配的右花括号 (忽略嵌套)
				var j = i + 1
				var depth = 1
				while j < template.length() and depth > 0:
					if template[j] == '{':
						depth += 1
					elif template[j] == '}':
						depth -= 1
					j += 1
				if depth != 0:
					result += template[i]
					i += 1
					continue
				var field = template.substr(i + 1, j - i - 2)
				result += _format_field(field, fmt_args, kwargs, idx_box)
				i = j
				continue
			result += template[i]
			i += 1
		return DSLString.new(result)
	
	## 初始化魔法方法描述符字典 [br]
	## 注册所有 Python str 类型的魔法方法
	func _init_magic_descriptors():
		_str_magic_descriptors = {
			"__add__": DSLWrappedDescriptor.new("__add__", Callable(self, "magic_add")),
			"__mul__": DSLWrappedDescriptor.new("__mul__", Callable(self, "magic_mul")),
			"__eq__": DSLWrappedDescriptor.new("__eq__", Callable(self, "magic_eq")),
			"__ne__": DSLWrappedDescriptor.new("__ne__", Callable(self, "magic_ne")),
			"__lt__": DSLWrappedDescriptor.new("__lt__", Callable(self, "magic_lt")),
			"__gt__": DSLWrappedDescriptor.new("__gt__", Callable(self, "magic_gt")),
			"__le__": DSLWrappedDescriptor.new("__le__", Callable(self, "magic_le")),
			"__ge__": DSLWrappedDescriptor.new("__ge__", Callable(self, "magic_ge")),
			"__contains__": DSLWrappedDescriptor.new("__contains__", Callable(self, "magic_contains")),
			"__getitem__": DSLWrappedDescriptor.new("__getitem__", Callable(self, "magic_getitem")),
			"__str__": DSLWrappedDescriptor.new("__str__", Callable(self, "magic_str")),
			"__repr__": DSLWrappedDescriptor.new("__repr__", Callable(self, "magic_repr")),
			"__bool__": DSLWrappedDescriptor.new("__bool__", Callable(self, "magic_bool")),
		}
	
	## 确保 str 方法描述符已初始化
	func _ensure_str_descriptors():
		if not _str_descriptors.is_empty():
			return
		var proto = DSLString.new("")
		_str_proto = proto
		_str_descriptors["upper"] = DSLMethodDescriptor.new("upper", Callable(proto, "builtin_upper"))
		_str_descriptors["lower"] = DSLMethodDescriptor.new("lower", Callable(proto, "builtin_lower"))
		_str_descriptors["strip"] = DSLMethodDescriptor.new("strip", Callable(proto, "builtin_strip"))
		_str_descriptors["split"] = DSLMethodDescriptor.new("split", Callable(proto, "builtin_split"))
		_str_descriptors["join"] = DSLMethodDescriptor.new("join", Callable(proto, "builtin_join"))
		_str_descriptors["replace"] = DSLMethodDescriptor.new("replace", Callable(proto, "builtin_replace"))
		_str_descriptors["find"] = DSLMethodDescriptor.new("find", Callable(proto, "builtin_find"))
		_str_descriptors["startswith"] = DSLMethodDescriptor.new("startswith", Callable(proto, "builtin_startswith"))
		_str_descriptors["endswith"] = DSLMethodDescriptor.new("endswith", Callable(proto, "builtin_endswith"))
		_str_descriptors["lstrip"] = DSLMethodDescriptor.new("lstrip", Callable(proto, "builtin_lstrip"))
		_str_descriptors["rstrip"] = DSLMethodDescriptor.new("rstrip", Callable(proto, "builtin_rstrip"))
		_str_descriptors["capitalize"] = DSLMethodDescriptor.new("capitalize", Callable(proto, "builtin_capitalize"))
		_str_descriptors["casefold"] = DSLMethodDescriptor.new("casefold", Callable(proto, "builtin_casefold"))
		_str_descriptors["title"] = DSLMethodDescriptor.new("title", Callable(proto, "builtin_title"))
		_str_descriptors["swapcase"] = DSLMethodDescriptor.new("swapcase", Callable(proto, "builtin_swapcase"))
		_str_descriptors["count"] = DSLMethodDescriptor.new("count", Callable(proto, "builtin_count"))
		_str_descriptors["isdigit"] = DSLMethodDescriptor.new("isdigit", Callable(proto, "builtin_isdigit"))
		_str_descriptors["isalpha"] = DSLMethodDescriptor.new("isalpha", Callable(proto, "builtin_isalpha"))
		_str_descriptors["isalnum"] = DSLMethodDescriptor.new("isalnum", Callable(proto, "builtin_isalnum"))
		_str_descriptors["isspace"] = DSLMethodDescriptor.new("isspace", Callable(proto, "builtin_isspace"))
		_str_descriptors["islower"] = DSLMethodDescriptor.new("islower", Callable(proto, "builtin_islower"))
		_str_descriptors["isupper"] = DSLMethodDescriptor.new("isupper", Callable(proto, "builtin_isupper"))
		_str_descriptors["istitle"] = DSLMethodDescriptor.new("istitle", Callable(proto, "builtin_istitle"))
		_str_descriptors["center"] = DSLMethodDescriptor.new("center", Callable(proto, "builtin_center"))
		_str_descriptors["ljust"] = DSLMethodDescriptor.new("ljust", Callable(proto, "builtin_ljust"))
		_str_descriptors["rjust"] = DSLMethodDescriptor.new("rjust", Callable(proto, "builtin_rjust"))
		_str_descriptors["zfill"] = DSLMethodDescriptor.new("zfill", Callable(proto, "builtin_zfill"))
		_str_descriptors["rsplit"] = DSLMethodDescriptor.new("rsplit", Callable(proto, "builtin_rsplit"))
		_str_descriptors["format"] = DSLMethodDescriptor.new("format", Callable(proto, "builtin_format"))
		_str_descriptors["index"] = DSLMethodDescriptor.new("index", Callable(proto, "builtin_index"))
		_str_descriptors["rindex"] = DSLMethodDescriptor.new("rindex", Callable(proto, "builtin_rindex"))
		_str_descriptors["rfind"] = DSLMethodDescriptor.new("rfind", Callable(proto, "builtin_rfind"))
		_str_descriptors["splitlines"] = DSLMethodDescriptor.new("splitlines", Callable(proto, "builtin_splitlines"))
		_str_descriptors["removeprefix"] = DSLMethodDescriptor.new("removeprefix", Callable(proto, "builtin_removeprefix"))
		_str_descriptors["removesuffix"] = DSLMethodDescriptor.new("removesuffix", Callable(proto, "builtin_removesuffix"))
		_str_descriptors["partition"] = DSLMethodDescriptor.new("partition", Callable(proto, "builtin_partition"))
		_str_descriptors["rpartition"] = DSLMethodDescriptor.new("rpartition", Callable(proto, "builtin_rpartition"))
		_str_descriptors["isdecimal"] = DSLMethodDescriptor.new("isdecimal", Callable(proto, "builtin_isdecimal"))
		_str_descriptors["isnumeric"] = DSLMethodDescriptor.new("isnumeric", Callable(proto, "builtin_isnumeric"))
		_str_descriptors["isprintable"] = DSLMethodDescriptor.new("isprintable", Callable(proto, "builtin_isprintable"))
		_str_descriptors["isascii"] = DSLMethodDescriptor.new("isascii", Callable(proto, "builtin_isascii"))
		_str_descriptors["isidentifier"] = DSLMethodDescriptor.new("isidentifier", Callable(proto, "builtin_isidentifier"))
		_str_descriptors["expandtabs"] = DSLMethodDescriptor.new("expandtabs", Callable(proto, "builtin_expandtabs"))
	
## DSL 列表类型, 对应 Python list
class DSLList extends DSLObject:
	## 列表元素数组
	var items: Array[DSLObject]
	## 是否为 range() 的产物 [br]
	## range 在 PyGDS 中以列表承载, 但类型名与可变性须与 CPython 区分 (如 shuffle 拒绝)
	var is_range: bool = false
	## 迭代器索引, 用于 __next__ 支持
	var iter_index: int = 0
	## list 类型的魔法方法描述符缓存 [br]
	## 存储各 Python 魔法方法对应的 DSLWrappedDescriptor
	var _lst_magic_descriptors: Dictionary = {}
	## list 类型的方法描述符缓存 [br]
	## 存储各内置方法的 DSLMethodDescriptor
	static var _lst_descriptors: Dictionary = {}
	## list 类型的原型实例 [br]
	## 用于方法描述符初始化
	static var _lst_proto: DSLList
	
	## 构造列表对象 [br]
	## [param p_items] 初始元素数组, 默认为空
	func _init(p_items: Array[DSLObject] = []):
		super._init()
		items = p_items
	
	func _type_name() -> String:
		return "range" if is_range else "list"
	
	func magic_add(args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLObject:
		var self_obj = args[0]
		var other = args[1]
		other = DSLObject._unwrap_dsl(other)
		if other is DSLList:
			var new_list = DSLList.new()
			new_list.items.append_array(self_obj.items)
			new_list.items.append_array(other.items)
			return new_list
		if other is DSLTuple:
			var new_list = DSLList.new()
			new_list.items.append_array(self_obj.items)
			new_list.items.append_array(other.items)
			return new_list
		return self_obj._arithmetic_type_error("+", other)
	
	func magic_mul(args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLObject:
		var self_obj = args[0]
		var other = args[1]
		other = DSLObject._unwrap_dsl(other)
		if other is DSLInteger:
			var new_list = DSLList.new()
			for _i in range(other.value):
				new_list.items.append_array(self_obj.items)
			return new_list
		return self_obj._arithmetic_type_error("*", other)
	
	func magic_eq(args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLBool:
		var self_obj = args[0]
		var other = args[1]
		other = DSLObject._unwrap_dsl(other)
		if other is DSLList:
			if self_obj.items.size() != other.items.size():
				return DSLBool.new(false)
			for i in range(self_obj.items.size()):
				if not self_obj.items[i]._dsl_eq(other.items[i]):
					return DSLBool.new(false)
			return DSLBool.new(true)
		if other is DSLTuple:
			if self_obj.items.size() != other.items.size():
				return DSLBool.new(false)
			for i in range(self_obj.items.size()):
				if not self_obj.items[i]._dsl_eq(other.items[i]):
					return DSLBool.new(false)
			return DSLBool.new(true)
		return DSLBool.new(false)
	
	func magic_ne(args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLBool:
		var self_obj = args[0]
		var other = args[1]
		other = DSLObject._unwrap_dsl(other)
		if other is DSLList:
			if self_obj.items.size() != other.items.size():
				return DSLBool.new(true)
			for i in range(self_obj.items.size()):
				if not self_obj.items[i]._dsl_eq(other.items[i]):
					return DSLBool.new(true)
			return DSLBool.new(false)
		if other is DSLTuple:
			if self_obj.items.size() != other.items.size():
				return DSLBool.new(true)
			for i in range(self_obj.items.size()):
				if not self_obj.items[i]._dsl_eq(other.items[i]):
					return DSLBool.new(true)
			return DSLBool.new(false)
		return DSLBool.new(true)
	
	func magic_getitem(args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLObject:
		var self_obj = args[0]
		var index = args[1]
		if index is DSLInteger:
			var i = index.value
			if i < 0:
				i = i + self_obj.items.size()
			if i < 0 or i >= self_obj.items.size():
				self_obj.last_error = "IndexError: list index out of range"
				return null
			return self_obj.items[i]
		if index is DSLSlice:
			var start_idx = self_obj.items.size() - 1 if (index.step != null and not index.step is DSLNone and index.step.value < 0) else 0
			var stop_idx = -1 if (index.step != null and not index.step is DSLNone and index.step.value < 0) else self_obj.items.size()
			var step_val = 1
			if index.start != null and not index.start is DSLNone:
				start_idx = index.start.value
				if start_idx < 0:
					start_idx = start_idx + self_obj.items.size()
			if index.stop != null and not index.stop is DSLNone:
				stop_idx = index.stop.value
				if stop_idx < 0:
					stop_idx = stop_idx + self_obj.items.size()
			if index.step != null and not index.step is DSLNone:
				step_val = index.step.value
			var result = DSLList.new([])
			var i = start_idx
			if step_val > 0:
				while i < stop_idx and i < self_obj.items.size():
					if i >= 0:
						result.items.append(self_obj.items[i])
					i = i + step_val
			elif step_val < 0:
				while i > stop_idx and i >= 0:
					if i < self_obj.items.size():
						result.items.append(self_obj.items[i])
					i = i + step_val
			return result
		return self_obj._index_type_error(index)
	
	func magic_setitem(args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLObject:
		var self_obj = args[0]
		var index = args[1]
		var value = args[2]
		if index is DSLInteger:
			var i = index.value
			if i < 0:
				i = i + self_obj.items.size()
			if i < 0 or i >= self_obj.items.size():
				self_obj.last_error = "IndexError: list assignment index out of range"
				return null
			self_obj.items[i] = value
			return DSLNone.new()
		return self_obj._index_type_error(index)
	
	func magic_str(args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLString:
		return DSLString.new(args[0]._dsl_str())
	
	func magic_repr(args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLObject:
		return DSLString.new(args[0]._dsl_str())
		
	func magic_bool(args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLBool:
		return DSLBool.new(args[0].items.size() > 0)
		
	func magic_contains(args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLObject:
		var self_obj = args[0]
		var item = args[1]
		for i in range(self_obj.items.size()):
			if self_obj.items[i]._dsl_eq(item):
				return DSLBool.new(true)
		return DSLBool.new(false)
	
	func _dsl_setitem(index: DSLObject, value: DSLObject):
		if is_range:
			# range 对象不可变 (CPython: 'range' object does not support item assignment)
			last_error = "TypeError: 'range' object does not support item assignment"
			return
		if index is DSLInteger:
			var i = index.value
			if i < 0:
				i = i + items.size()
			if i < 0 or i >= items.size():
				last_error = "IndexError: list assignment index out of range"
				return
			items[i] = value
			return
		_index_type_error(index)
	
	func _dsl_delitem(index: DSLObject):
		var raw = DSLObject._unwrap_dsl(self)
		if raw.is_range:
			# range 对象不可变 (CPython: 'range' object doesn't support item deletion)
			last_error = "TypeError: 'range' object doesn't support item deletion"
			return
		if index is DSLInteger:
			var i = index.value
			if i < 0:
				i += raw.items.size()
			if i < 0 or i >= raw.items.size():
				last_error = "IndexError: list assignment index out of range"
				return
			raw.items.remove_at(i)
	
	func _dsl_str() -> String:
		var s = ""
		for i in range(items.size()):
			if i > 0:
				s += ", "
			s += "'" + DSLObject._py_str_repr(items[i].value) + "'" if items[i] is DSLString else items[i]._dsl_str()
		return "[" + s + "]"
	
	func _dsl_bool() -> bool:
		return items.size() > 0
		
	func _dsl_iter() -> DSLIterator:
		return DSLListIterator.new(items)
	
	func _dsl_getattribute(name: String) -> DSLObject:
		if _lst_magic_descriptors.is_empty():
			_init_magic_descriptors()
		if _lst_magic_descriptors.has(name):
			return _lst_magic_descriptors[name].__get__(self, null)
		_ensure_lst_descriptors()
		if _lst_descriptors.has(name):
			return _lst_descriptors[name].__get__(self, null)
		return super._dsl_getattribute(name)
	
	func builtin_append(args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLObject:
		var obj = args[0]
		var raw = DSLObject._unwrap_dsl(obj)
		if args.size() != 2:
			last_error = "TypeError: append() takes exactly one argument"
			return null
		raw.items.append(DSLObject._unwrap_dsl(args[1]))
		return DSLNone.new()
	
	func builtin_extend(args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLObject:
		var obj = args[0]
		var raw = DSLObject._unwrap_dsl(obj)
		if args.size() != 2:
			last_error = "TypeError: extend() takes exactly one argument"
			return null
		var other = DSLObject._unwrap_dsl(args[1])
		if other is DSLList or other is DSLTuple:
			raw.items.append_array(other.items)
		else:
			var it = other._dsl_iter()
			if it == null:
				last_error = "TypeError: argument must be iterable"
				return null
			while it.has_next():
				raw.items.append(it.next())
				if it.suspended:
					break
		return DSLNone.new()
	
	func builtin_pop(args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLObject:
		var obj = args[0]
		var raw = DSLObject._unwrap_dsl(obj)
		var idx = raw.items.size() - 1
		if args.size() >= 2:
			idx = args[1].value
		if idx < 0 or idx >= raw.items.size():
			last_error = "IndexError: pop index out of range"
			return null
		var val = raw.items[idx]
		raw.items.remove_at(idx)
		return val
	
	func builtin_remove(args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLObject:
		var obj = args[0]
		var raw = DSLObject._unwrap_dsl(obj)
		if args.size() != 2:
			last_error = "TypeError: remove() takes exactly one argument"
			return null
		var target = DSLObject._unwrap_dsl(args[1])
		for i in range(raw.items.size()):
			if raw.items[i]._dsl_eq(target):
				raw.items.remove_at(i)
				return DSLNone.new()
		last_error = "ValueError: list.remove(x): x not in list"
		return null
	
	func builtin_insert(args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLObject:
		var obj = args[0]
		var raw = DSLObject._unwrap_dsl(obj)
		if args.size() != 3:
			last_error = "TypeError: insert() takes exactly two arguments"
			return null
		var idx = args[1].value
		var val = DSLObject._unwrap_dsl(args[2])
		if idx < 0:
			idx = max(0, raw.items.size() + idx)
		idx = mini(idx, raw.items.size())
		raw.items.insert(idx, val)
		return DSLNone.new()
	
	func builtin_index(args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLObject:
		var obj = args[0]
		var raw = DSLObject._unwrap_dsl(obj)
		if args.size() < 2:
			last_error = "TypeError: index() takes at least one argument"
			return null
		var target = DSLObject._unwrap_dsl(args[1])
		for i in range(raw.items.size()):
			if raw.items[i]._dsl_eq(target):
				return DSLInteger.new(i)
		last_error = "ValueError: value not in list"
		return null
	
	func builtin_count(args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLObject:
		var obj = args[0]
		var raw = DSLObject._unwrap_dsl(obj)
		var target = DSLObject._unwrap_dsl(args[1])
		var c = 0
		for item in raw.items:
			if item._dsl_eq(target):
				c += 1
		return DSLInteger.new(c)
	
	func builtin_sort(args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLObject:
		var obj = args[0]
		var raw = DSLObject._unwrap_dsl(obj)
		var reverse_val = false
		if _kwargs.has("reverse"):
			var rv = _kwargs["reverse"]
			reverse_val = rv is DSLBool and rv.value
		if _kwargs.has("key"):
			var key_func = _kwargs["key"]
			if key_func._dsl_is_callable():
				# Transform items via key function for sorting, then restore
				var mapped = []
				for item in raw.items:
					var k = key_func.magic_call([item] as Array[DSLObject], {} as Dictionary[String, DSLObject])
					mapped.append({"item": item, "key": k})
				if reverse_val:
					mapped.sort_custom(func(a, b): return not _cmp_items(a["key"], b["key"]))
				else:
					mapped.sort_custom(func(a, b): return _cmp_items(a["key"], b["key"]))
				raw.items.clear()
				for m in mapped:
					raw.items.append(m["item"])
			else:
				raw.items.sort_custom(Callable(self, "_cmp_items"))
		else:
			if reverse_val:
				raw.items.sort_custom(func(a, b): return not _cmp_items(a, b))
			else:
				raw.items.sort_custom(Callable(self, "_cmp_items"))
		return DSLNone.new()
	
	func builtin_reverse(args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLObject:
		var obj = args[0]
		var raw = DSLObject._unwrap_dsl(obj)
		raw.items.reverse()
		return DSLNone.new()
	
	func builtin_clear(args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLObject:
		var obj = args[0]
		var raw = DSLObject._unwrap_dsl(obj)
		raw.items.clear()
		return DSLNone.new()
	
	func builtin_copy(args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLObject:
		var obj = args[0]
		var raw = DSLObject._unwrap_dsl(obj)
		var new_list = DSLList.new()
		for item in raw.items:
			new_list.items.append(item)
		return new_list
	
	## 初始化魔法方法描述符字典 [br]
	## 注册所有 Python list 类型的魔法方法
	func _init_magic_descriptors():
		_lst_magic_descriptors = {
			"__add__": DSLWrappedDescriptor.new("__add__", Callable(self, "magic_add")),
			"__mul__": DSLWrappedDescriptor.new("__mul__", Callable(self, "magic_mul")),
			"__eq__": DSLWrappedDescriptor.new("__eq__", Callable(self, "magic_eq")),
			"__ne__": DSLWrappedDescriptor.new("__ne__", Callable(self, "magic_ne")),
			"__contains__": DSLWrappedDescriptor.new("__contains__", Callable(self, "magic_contains")),
			"__getitem__": DSLWrappedDescriptor.new("__getitem__", Callable(self, "magic_getitem")),
			"__setitem__": DSLWrappedDescriptor.new("__setitem__", Callable(self, "magic_setitem")),
			"__str__": DSLWrappedDescriptor.new("__str__", Callable(self, "magic_str")),
			"__repr__": DSLWrappedDescriptor.new("__repr__", Callable(self, "magic_repr")),
			"__bool__": DSLWrappedDescriptor.new("__bool__", Callable(self, "magic_bool")),
		}
		
	## 确保 list 方法描述符已初始化
	func _ensure_lst_descriptors():
		if not _lst_descriptors.is_empty():
			return
		var proto = DSLList.new([])
		_lst_proto = proto
		_lst_descriptors["append"] = DSLMethodDescriptor.new("append", Callable(proto, "builtin_append"))
		_lst_descriptors["extend"] = DSLMethodDescriptor.new("extend", Callable(proto, "builtin_extend"))
		_lst_descriptors["pop"] = DSLMethodDescriptor.new("pop", Callable(proto, "builtin_pop"))
		_lst_descriptors["remove"] = DSLMethodDescriptor.new("remove", Callable(proto, "builtin_remove"))
		_lst_descriptors["insert"] = DSLMethodDescriptor.new("insert", Callable(proto, "builtin_insert"))
		_lst_descriptors["index"] = DSLMethodDescriptor.new("index", Callable(proto, "builtin_index"))
		_lst_descriptors["count"] = DSLMethodDescriptor.new("count", Callable(proto, "builtin_count"))
		_lst_descriptors["sort"] = DSLMethodDescriptor.new("sort", Callable(proto, "builtin_sort"))
		_lst_descriptors["reverse"] = DSLMethodDescriptor.new("reverse", Callable(proto, "builtin_reverse"))
		_lst_descriptors["clear"] = DSLMethodDescriptor.new("clear", Callable(proto, "builtin_clear"))
		_lst_descriptors["copy"] = DSLMethodDescriptor.new("copy", Callable(proto, "builtin_copy"))
	
	## 排序比较器, 调用 a.magic_lt(b) 进行元素比较 [br]
	## [param b] 右侧元素 [br]
	## [returns] a < b 则 true
	static func _cmp_items(a: DSLObject, b: DSLObject) -> bool:
		var result = a.magic_lt([a, b] as Array[DSLObject], {} as Dictionary[String, DSLObject])
		if result is DSLBool:
			return result.value
		return false
	
## DSL 元组类型, 对应 Python tuple
class DSLTuple extends DSLObject:
	## 元组元素数组
	var items: Array[DSLObject]
	## tuple 类型的魔法方法描述符缓存 [br]
	## 存储各 Python 魔法方法对应的 DSLWrappedDescriptor
	var _tup_magic_descriptors: Dictionary = {}
	## tuple 类型的方法描述符缓存 [br]
	## 存储各内置方法的 DSLMethodDescriptor
	static var _tup_descriptors: Dictionary = {}
	
	## 构造元组对象 [br]
	## [param p_items] 初始元素数组, 默认为空
	func _init(p_items: Array[DSLObject] = []):
		super._init()
		items = p_items
	
	func _type_name() -> String:
		return "tuple"
	
	func magic_eq(args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLBool:
		var self_obj = args[0]
		var other = args[1]
		other = DSLObject._unwrap_dsl(other)
		if other is DSLTuple and self_obj.items.size() == other.items.size():
			for i in range(self_obj.items.size()):
				if not self_obj.items[i]._dsl_eq(other.items[i]):
					return DSLBool.new(false)
			return DSLBool.new(true)
		return DSLBool.new(false)
	
	func magic_ne(args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLBool:
		var self_obj = args[0]
		var other = args[1]
		other = DSLObject._unwrap_dsl(other)
		if other is DSLTuple and self_obj.items.size() == other.items.size():
			for i in range(self_obj.items.size()):
				if not self_obj.items[i]._dsl_eq(other.items[i]):
					return DSLBool.new(true)
			return DSLBool.new(false)
		return DSLBool.new(true)
	
	func magic_getitem(args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLObject:
		var self_obj = args[0]
		var index = args[1]
		if index is DSLInteger:
			var i = index.value
			if i < 0:
				i = i + self_obj.items.size()
			if i < 0 or i >= self_obj.items.size():
				self_obj.last_error = "IndexError: tuple index out of range"
				return null
			return self_obj.items[i]
		if index is DSLSlice:
			var start_idx = self_obj.items.size() - 1 if (index.step != null and not index.step is DSLNone and index.step.value < 0) else 0
			var stop_idx = -1 if (index.step != null and not index.step is DSLNone and index.step.value < 0) else self_obj.items.size()
			var step_val = 1
			if index.start != null and not index.start is DSLNone:
				start_idx = index.start.value
				if start_idx < 0:
					start_idx = start_idx + self_obj.items.size()
			if index.stop != null and not index.stop is DSLNone:
				stop_idx = index.stop.value
				if stop_idx < 0:
					stop_idx = stop_idx + self_obj.items.size()
			if index.step != null and not index.step is DSLNone:
				step_val = index.step.value
			var result = DSLTuple.new([])
			var i = start_idx
			if step_val > 0:
				while i < stop_idx and i < self_obj.items.size():
					if i >= 0:
						result.items.append(self_obj.items[i])
					i = i + step_val
			elif step_val < 0:
				while i > stop_idx and i >= 0:
					if i < self_obj.items.size():
						result.items.append(self_obj.items[i])
					i = i + step_val
			return result
		return self_obj._index_type_error(index)
	
	func magic_str(args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLString:
		return DSLString.new(args[0]._dsl_str())
		
	func magic_repr(args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLObject:
		return DSLString.new(args[0]._dsl_str())
		
	func magic_bool(args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLBool:
		return DSLBool.new(args[0].items.size() > 0)
		
	func magic_contains(args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLObject:
		var self_obj = args[0]
		var item = args[1]
		for i in range(self_obj.items.size()):
			if self_obj.items[i]._dsl_eq(item):
				return DSLBool.new(true)
		return DSLBool.new(false)
	
	func magic_add(args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLObject:
		var self_obj = args[0]
		var other = args[1]
		other = DSLObject._unwrap_dsl(other)
		if other is DSLTuple:
			var new_items = self_obj.items.duplicate()
			new_items.append_array(other.items)
			return DSLTuple.new(new_items)
		self_obj._arithmetic_type_error("+", other)
		return null
	
	func magic_mul(args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLObject:
		var self_obj = args[0]
		var other = args[1]
		other = DSLObject._unwrap_dsl(other)
		if other is DSLInteger:
			var new_items: Array[DSLObject] = []
			for _i in range(other.value):
				new_items.append_array(self_obj.items)
			return DSLTuple.new(new_items)
		self_obj._arithmetic_type_error("*", other)
		return null
	
	func _dsl_getitem(_index: DSLObject) -> DSLObject:
		return magic_getitem([self, _index], {})
	
	func _dsl_str() -> String:
		match items.size():
			0:
				return "()"
			1:
				return "(" + ("'" + DSLObject._py_str_repr(items[0].value) + "'" if items[0] is DSLString else items[0]._dsl_str()) + ",)"
			_:
				var s = ""
				for i in range(items.size()):
					if i > 0:
						s += ", "
					s += "'" + DSLObject._py_str_repr(items[i].value) + "'" if items[i] is DSLString else items[i]._dsl_str()
				return "(" + s + ")"
	
	func _dsl_bool() -> bool:
		return items.size() > 0
		
	func _dsl_iter() -> DSLIterator:
		return DSLListIterator.new(items)
	
	func _dsl_getattribute(name: String) -> DSLObject:
		if _tup_magic_descriptors.is_empty():
			_init_magic_descriptors()
		if _tup_magic_descriptors.has(name):
			return _tup_magic_descriptors[name].__get__(self, null)
		_ensure_tup_descriptors()
		if _tup_descriptors.has(name):
			return _tup_descriptors[name].__get__(self, null)
		return super._dsl_getattribute(name)
	
	func builtin_count(args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLObject:
		var obj = args[0]
		var raw = DSLObject._unwrap_dsl(obj)
		var target = args[1]
		if target._wrapped != null:
			target = target._wrapped
		var c = 0
		for item in raw.items:
			if item._dsl_eq(target):
				c += 1
		return DSLInteger.new(c)
	
	func builtin_index(args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLObject:
		var obj = args[0]
		var raw = DSLObject._unwrap_dsl(obj)
		var target = args[1]
		if target._wrapped != null:
			target = target._wrapped
		for i in range(raw.items.size()):
			if raw.items[i]._dsl_eq(target):
				return DSLInteger.new(i)
		last_error = "ValueError: value not in tuple"
		return null
		
	## 初始化魔法方法描述符字典 [br]
	## 注册所有 Python tuple 类型的魔法方法
	func _init_magic_descriptors():
		_tup_magic_descriptors = {
			"__eq__": DSLWrappedDescriptor.new("__eq__", Callable(self, "magic_eq")),
			"__ne__": DSLWrappedDescriptor.new("__ne__", Callable(self, "magic_ne")),
			"__contains__": DSLWrappedDescriptor.new("__contains__", Callable(self, "magic_contains")),
			"__getitem__": DSLWrappedDescriptor.new("__getitem__", Callable(self, "magic_getitem")),
			"__str__": DSLWrappedDescriptor.new("__str__", Callable(self, "magic_str")),
			"__repr__": DSLWrappedDescriptor.new("__repr__", Callable(self, "magic_repr")),
			"__add__": DSLWrappedDescriptor.new("__add__", Callable(self, "magic_add")),
			"__mul__": DSLWrappedDescriptor.new("__mul__", Callable(self, "magic_mul")),
			"__bool__": DSLWrappedDescriptor.new("__bool__", Callable(self, "magic_bool")),
		}
	
	## 确保 tuple 方法描述符已初始化 [br]
	## 注册 count, index 方法
	func _ensure_tup_descriptors():
		if not _tup_descriptors.is_empty():
			return
		var proto = DSLTuple.new([])
		_tup_descriptors["count"] = DSLMethodDescriptor.new("count", Callable(proto, "_tup_count"))
		_tup_descriptors["index"] = DSLMethodDescriptor.new("index", Callable(proto, "_tup_index"))

## DSL 字典类型, 对应 Python dict
class DSLDict extends DSLObject:
	## 字典数据 (键为 Variant, 值为 DSLObject)
	var dict: Dictionary[Variant, DSLObject]
	## dict 类型的魔法方法描述符缓存 [br]
	## 存储各 Python 魔法方法对应的 DSLWrappedDescriptor
	var _dict_magic_descriptors: Dictionary = {}
	## dict 类型的方法描述符缓存 [br]
	## 存储各内置方法的 DSLMethodDescriptor
	static var _dict_descriptors: Dictionary = {}
	## dict 类型的原型实例 [br]
	## 用于方法描述符初始化
	static var _dict_proto: DSLDict
	
	## 构造字典对象 [br]
	## [param p_dict] 初始字典数据, 默认为空
	func _init(p_dict: Dictionary[Variant, DSLObject] = {}):
		super._init()
		dict = p_dict
	
	func _type_name() -> String:
		return "dict"
		
	func magic_eq(args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLBool:
		var self_obj = args[0]
		var other = args[1]
		other = DSLObject._unwrap_dsl(other)
		if other is DSLDict:
			if self_obj.dict.size() != other.dict.size():
				return DSLBool.new(false)
			for key in self_obj.dict.keys():
				if not other.dict.has(key):
					return DSLBool.new(false)
				if not self_obj.dict[key]._dsl_eq(other.dict[key]):
					return DSLBool.new(false)
			return DSLBool.new(true)
		return DSLBool.new(false)
	
	func magic_ne(args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLBool:
		var self_obj = args[0]
		var other = args[1]
		other = DSLObject._unwrap_dsl(other)
		if other is DSLDict:
			if self_obj.dict.size() != other.dict.size():
				return DSLBool.new(true)
			for key in self_obj.dict.keys():
				if not other.dict.has(key):
					return DSLBool.new(true)
				if not self_obj.dict[key]._dsl_eq(other.dict[key]):
					return DSLBool.new(true)
			return DSLBool.new(false)
		return DSLBool.new(true)
	
	## 合并 | (Python 3.9+): 返回新字典, 右侧覆盖左侧同键
	func magic_or(args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLObject:
		var other = DSLObject._unwrap_dsl(args[1])
		if other is DSLDict:
			var new_dict = DSLDict.new()
			for key in args[0].dict.keys():
				new_dict.dict[key] = args[0].dict[key]
			for key in other.dict.keys():
				new_dict.dict[key] = other.dict[key]
			return new_dict
		args[0]._arithmetic_type_error("|", args[1])
		return null
	
	func magic_getitem(args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLObject:
		var self_obj = args[0]
		var key = args[1]
		var vkey = _key_to_variant(key)
		if vkey == null:
			return null
		if self_obj.dict.has(vkey):
			return self_obj.dict[vkey]
		self_obj.last_error = "KeyError: " + DSLObject._py_repr(key)
		self_obj.last_error_args = [key] as Array[DSLObject]
		return null
	
	func magic_setitem(args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLObject:
		var self_obj = args[0]
		var key = args[1]
		var value = args[2]
		var vkey = _key_to_variant(key)
		if vkey == null:
			return null
		self_obj.dict[vkey] = value
		return DSLNone.new()
	
	func magic_str(args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLString:
		return DSLString.new(args[0]._dsl_str())
		
	func magic_repr(args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLObject:
		return DSLString.new(args[0]._dsl_str())
		
	func magic_bool(args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLBool:
		return DSLBool.new(args[0].dict.size() > 0)
		
	func magic_contains(args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLObject:
		var self_obj = args[0]
		var key = args[1]
		var vkey = _key_to_variant(key)
		if vkey == null:
			return DSLBool.new(false)
		return DSLBool.new(self_obj.dict.has(vkey))
	
	func _dsl_iter() -> DSLIterator:
		return DSLDictKeyIterator.new(dict)
		
	func _dsl_bool() -> bool:
		return dict.size() > 0
	
	func _dsl_str() -> String:
		var s = ""
		var first = true
		for k in dict.keys():
			if not first:
				s += ", "
			first = false
			var key_obj = _wrap_key(k)
			s += "'" + DSLObject._py_str_repr(key_obj.value) + "'" if key_obj is DSLString else key_obj._dsl_str()
			s += ": "
			s += "'" + DSLObject._py_str_repr(dict[k].value) + "'" if dict[k] is DSLString else dict[k]._dsl_str()
		return "{" + s + "}"
		
	func _dsl_setitem(index: DSLObject, value: DSLObject):
		var vkey = _key_to_variant(index)
		if vkey == null:
			return
		dict[vkey] = value
		
	func _dsl_getattribute(name: String) -> DSLObject:
		if _dict_magic_descriptors.is_empty():
			_init_magic_descriptors()
		if _dict_magic_descriptors.has(name):
			return _dict_magic_descriptors[name].__get__(self, null)
		_ensure_dict_descriptors()
		if _dict_descriptors.has(name):
			return _dict_descriptors[name].__get__(self, null)
		return super._dsl_getattribute(name)
	
	func _dsl_delitem(key: DSLObject):
		var vkey = _key_to_variant(key)
		if vkey == null:
			last_error = "TypeError: unhashable type"
			return
		if not dict.has(vkey):
			last_error = "KeyError: " + DSLObject._py_repr(key)
			last_error_args = [key] as Array[DSLObject]
			return
		dict.erase(vkey)
		
	func builtin_items(args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLObject:
		var obj = args[0]
		var raw = DSLObject._unwrap_dsl(obj)
		var result = DSLList.new()
		for key in raw.dict.keys():
			result.items.append(DSLTuple.new([_wrap_key(key), raw.dict[key]]))
		return result
	
	func builtin_keys(args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLObject:
		var obj = args[0]
		var raw = DSLObject._unwrap_dsl(obj)
		var result: Array[DSLObject] = []
		for key in raw.dict.keys():
			result.append(_wrap_key(key))
		return DSLDictKeys.new(result)
	
	func builtin_values(args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLObject:
		var obj = args[0]
		var raw = DSLObject._unwrap_dsl(obj)
		var result: Array[DSLObject] = []
		for key in raw.dict.keys():
			result.append(raw.dict[key])
		return DSLDictValues.new(result)
	
	func builtin_get(args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLObject:
		var obj = args[0]
		var raw = DSLObject._unwrap_dsl(obj)
		var key = args[1]
		var default = args[2] if args.size() >= 3 else DSLNone.new()
		var vkey = _key_to_variant(key)
		if vkey != null and raw.dict.has(vkey):
			return raw.dict[vkey]
		return default
	
	func builtin_pop(args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLObject:
		var obj = args[0]
		var raw = DSLObject._unwrap_dsl(obj)
		var key = args[1]
		var vkey = _key_to_variant(key)
		if vkey == null:
			return null
		if not raw.dict.has(vkey):
			if args.size() >= 3:
				return args[2]
			last_error = "KeyError: " + DSLObject._py_repr(key)
			last_error_args = [key] as Array[DSLObject]
			return null
		var val = raw.dict[vkey]
		raw.dict.erase(vkey)
		return val
	
	func builtin_update(args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLObject:
		var obj = args[0]
		var raw = DSLObject._unwrap_dsl(obj)
		# Handle positional argument (dict)
		if args.size() >= 2:
			var other = args[1]
			var other_raw = other
			if other._wrapped != null:
				other_raw = other._wrapped
			if other_raw is DSLDict:
				for k in other_raw.dict.keys():
					raw.dict[k] = other_raw.dict[k]
			elif other_raw is DSLList:
				# Support update([(key, value), ...])
				for item in other_raw.items:
					if item is DSLTuple and item.items.size() == 2:
						var vkey = _key_to_variant(item.items[0])
						if vkey != null:
							raw.dict[vkey] = item.items[1]
			else:
				last_error = "TypeError: update() argument must be a dict or iterable of pairs"
				return null
		# Handle keyword arguments
		for k in _kwargs.keys():
			var vkey = k
			raw.dict[vkey] = _kwargs[k]
		return DSLNone.new()
	
	func builtin_clear(args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLObject:
		var obj = args[0]
		var raw = DSLObject._unwrap_dsl(obj)
		raw.dict.clear()
		return DSLNone.new()
	
	func builtin_copy(args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLObject:
		var obj = args[0]
		var raw = DSLObject._unwrap_dsl(obj)
		var new_dict = DSLDict.new()
		for k in raw.dict.keys():
			new_dict.dict[k] = raw.dict[k]
		return new_dict
	
	func builtin_setdefault(args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLObject:
		var obj = args[0]
		var raw = DSLObject._unwrap_dsl(obj)
		if args.size() < 2:
			raw.last_error = "TypeError: setdefault() takes at least 1 argument"
			return null
		var dsl_key = args[1]
		var vkey = _key_to_variant(dsl_key)
		if vkey == null:
			return null
		if raw.dict.has(vkey):
			return raw.dict[vkey]
		var default_val = DSLNone.new()
		if args.size() >= 3:
			default_val = args[2]
		raw.dict[vkey] = default_val
		return default_val
	
	func builtin_popitem(args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLObject:
		var obj = args[0]
		var raw = DSLObject._unwrap_dsl(obj)
		if raw.dict.size() == 0:
			raw.last_error = "KeyError: " + DSLObject._py_repr(DSLString.new("popitem(): dictionary is empty"))
			raw.last_error_args = [DSLString.new("popitem(): dictionary is empty")] as Array[DSLObject]
			return null
		var keys = raw.dict.keys()
		var raw_key = keys[keys.size() - 1]
		var value = raw.dict[raw_key]
		raw.dict.erase(raw_key)
		return DSLTuple.new([_wrap_key(raw_key), value])
	
	## DSL 键转换为 Variant 类型 [br]
	## [param key] DSLObject [br]
	## [returns] 对应的 Variant 值, 类型不可哈希时返回 null
	func _key_to_variant(key: DSLObject) -> Variant:
		key = DSLObject._unwrap_dsl(key)
		if key is DSLString:
			return key.value
		if key is DSLInteger:
			return key.value
		if key is DSLFloat:
			return key.value
		if key is DSLBool:
			return key.value
		if key is DSLTuple:
			# 元组可作键: 拼接各元素的键 (与 CPython 的元组哈希语义一致)
			var parts = []
			for it in key.items:
				var part = _key_to_variant(it)
				if part == null:
					return null
				parts.append(str(part))
			return "tuple:" + "|" + "|".join(parts)
		if key is DSLFrozenSet:
			var parts = []
			for k in key.items:
				parts.append(k)
			parts.sort()
			return "frozenset:" + "|" + "|".join(parts)
		if key.klass != null:
			var hash_method = key.klass._lookup_method("__hash__")
			var eq_method = key.klass._lookup_method("__eq__")
			if hash_method == null:
				if eq_method != null:
					# 定义了 __eq__ 却未定义 __hash__: 不可哈希 (与 CPython 一致)
					last_error = "TypeError: unhashable type: '%s'" % key._type_name()
					return null
				# 两者都未定义: 按身份哈希 (普通用户类的默认行为)
				return "user:id|" + str(key._object_id)
			var hres = key.klass._invoke_func(hash_method, [key] as Array[DSLObject], {} as Dictionary[String, DSLObject])
			if not (hres is DSLInteger):
				last_error = "TypeError: unhashable type: '%s'" % key._type_name()
				return null
			# 未定义 __eq__ 时按身份区分
			if eq_method != null:
				return "user:|" + str(hres.value)
			return "user:|" + str(hres.value) + "|" + str(key._object_id)
		last_error = "TypeError: unhashable type: " + key._type_name()
		return null
		
	## Variant 键包装为 DSLObject [br]
	## [param raw] Variant 类型的键[br]
	## [returns] 对应的 DSLObject
	func _wrap_key(raw) -> DSLObject:
		if typeof(raw) == TYPE_STRING:
			return DSLString.new(raw)
		if typeof(raw) == TYPE_INT:
			return DSLInteger.new(raw)
		if typeof(raw) == TYPE_FLOAT:
			return DSLFloat.new(raw)
		if typeof(raw) == TYPE_BOOL:
			return DSLBool.new(raw)
		return DSLNone.new()

	## 初始化魔法方法描述符字典 [br]
	## 注册所有 Python dict 类型的魔法方法
	func _init_magic_descriptors():
		_dict_magic_descriptors = {
			"__eq__": DSLWrappedDescriptor.new("__eq__", Callable(self, "magic_eq")),
			"__ne__": DSLWrappedDescriptor.new("__ne__", Callable(self, "magic_ne")),
			"__contains__": DSLWrappedDescriptor.new("__contains__", Callable(self, "magic_contains")),
			"__getitem__": DSLWrappedDescriptor.new("__getitem__", Callable(self, "magic_getitem")),
			"__setitem__": DSLWrappedDescriptor.new("__setitem__", Callable(self, "magic_setitem")),
			"__str__": DSLWrappedDescriptor.new("__str__", Callable(self, "magic_str")),
			"__repr__": DSLWrappedDescriptor.new("__repr__", Callable(self, "magic_repr")),
			"__bool__": DSLWrappedDescriptor.new("__bool__", Callable(self, "magic_bool")),
		}
	
	## 确保 dict 方法描述符已初始化 [br]
	## 注册 items, keys, values, get, pop, update, clear, copy 方法
	func _ensure_dict_descriptors():
		if not _dict_descriptors.is_empty():
			return
		var proto = DSLDict.new({})
		_dict_proto = proto
		_dict_descriptors["items"] = DSLMethodDescriptor.new("items", Callable(proto, "builtin_items"))
		_dict_descriptors["keys"] = DSLMethodDescriptor.new("keys", Callable(proto, "builtin_keys"))
		_dict_descriptors["values"] = DSLMethodDescriptor.new("values", Callable(proto, "builtin_values"))
		_dict_descriptors["get"] = DSLMethodDescriptor.new("get", Callable(proto, "builtin_get"))
		_dict_descriptors["pop"] = DSLMethodDescriptor.new("pop", Callable(proto, "builtin_pop"))
		_dict_descriptors["update"] = DSLMethodDescriptor.new("update", Callable(proto, "builtin_update"))
		_dict_descriptors["clear"] = DSLMethodDescriptor.new("clear", Callable(proto, "builtin_clear"))
		_dict_descriptors["copy"] = DSLMethodDescriptor.new("copy", Callable(proto, "builtin_copy"))
		_dict_descriptors["setdefault"] = DSLMethodDescriptor.new("setdefault", Callable(proto, "builtin_setdefault"))
		_dict_descriptors["popitem"] = DSLMethodDescriptor.new("popitem", Callable(proto, "builtin_popitem"))

## DSL dict_keys 视图包装器, 对应 Python dict_keys
class DSLDictKeys extends DSLObject:
	## 键列表
	var keys_list: Array[DSLObject]
	
	## 构造 dict_keys 视图 [br]
	## [param kl] 键的 DSLObject 数组
	func _init(kl: Array[DSLObject]):
		super._init()
		keys_list = kl
	
	func _type_name() -> String:
		return "dict_keys"
	
	## 迭代支持: 视图以列表承载, 迭代顺序与字典插入顺序一致
	func _dsl_iter() -> DSLIterator:
		return DSLListIterator.new(keys_list)
	
	## 长度支持 (CPython: len(d.keys()) == len(d))
	func _dsl_len_hint() -> int:
		return keys_list.size()

	## 真值判定: 空视图为假 (与 CPython 的 __len__ 回退一致)
	func _dsl_bool() -> bool:
		return keys_list.size() != 0

	## 成员判定 (CPython: k in d.keys())
	func magic_contains(args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLObject:
		var target = args[1]
		for k in keys_list:
			if k._dsl_eq(target):
				return DSLBool.new(true)
		return DSLBool.new(false)
	
	## 相等判定 (CPython: dict_keys 按集合语义比较, 与元素顺序无关)
	func _dsl_eq(other: DSLObject) -> bool:
		other = DSLObject._unwrap_dsl(other)
		if other is DSLDictKeys:
			return _set_equal(keys_list, other.keys_list)
		if other is DSLSet:
			var vals: Array[DSLObject] = []
			for k in other.items.values():
				vals.append(k)
			return _set_equal(keys_list, vals)
		return false
	
	## 不等判定 (与 _dsl_eq 相反)
	func _dsl_ne(other: DSLObject) -> bool:
		return not _dsl_eq(other)
	
	## 相等判定 (运算符 == 经此分派, 与其它类型的比较走左侧的 magic_eq)
	func magic_eq(args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLBool:
		return DSLBool.new(args[0]._dsl_eq(args[1]))
	
	## 不等判定 (运算符 != 经此分派)
	func magic_ne(args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLBool:
		return DSLBool.new(not args[0]._dsl_eq(args[1]))
	
	## 按集合语义比较两个列表 (无序, 元素一一对应)
	## [param a] 左列表 [br]
	## [param b] 右列表 [br]
	## [returns] 集合意义下相等时返回 true
	func _set_equal(a: Array[DSLObject], b: Array[DSLObject]) -> bool:
		if a.size() != b.size():
			return false
		for item in a:
			var found = false
			for other_item in b:
				if item._dsl_eq(other_item):
					found = true
					break
			if not found:
				return false
		return true
	
	func _dsl_str() -> String:
		return "dict_keys(" + _list_repr() + ")"
	
	## repr 与 str 相同 (CPython: repr(d.keys()) == "dict_keys(['a'])")
	func magic_repr(args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLObject:
		return DSLString.new(args[0]._dsl_str())
	
	## 内部列表表示 [br]
	## [returns] "[k1, k2, ...]" 格式
	func _list_repr() -> String:
		var s = ""
		for i in range(keys_list.size()):
			if i > 0:
				s += ", "
			s += DSLObject._py_repr(keys_list[i])
		return "[" + s + "]"

## DSL dict_values 视图包装器, 对应 Python dict_values
class DSLDictValues extends DSLObject:
	## 值列表
	var values_list: Array[DSLObject]
	
	## 构造 dict_values 视图 [br]
	## [param vl] 值的 DSLObject 数组
	func _init(vl: Array[DSLObject]):
		super._init()
		values_list = vl
	
	func _type_name() -> String:
		return "dict_values"
	
	## 迭代支持: 视图以列表承载, 迭代顺序与字典插入顺序一致
	func _dsl_iter() -> DSLIterator:
		return DSLListIterator.new(values_list)
	
	## 长度支持 (CPython: len(d.values()) == len(d))
	func _dsl_len_hint() -> int:
		return values_list.size()

	## 真值判定: 空视图为假 (与 CPython 的 __len__ 回退一致)
	func _dsl_bool() -> bool:
		return values_list.size() != 0

	## 成员判定 (CPython: v in d.values() 为线性扫描)
	func magic_contains(args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLObject:
		var target = args[1]
		for v in values_list:
			if v._dsl_eq(target):
				return DSLBool.new(true)
		return DSLBool.new(false)
	
	func _dsl_str() -> String:
		return "dict_values(" + _list_repr() + ")"
	
	## repr 与 str 相同 (CPython: repr(d.values()) == "dict_values([1])")
	func magic_repr(args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLObject:
		return DSLString.new(args[0]._dsl_str())
	
	## 生成值的列表表示字符串 [br]
	## [returns] "[v1, v2, ...]" 格式
	func _list_repr() -> String:
		var s = ""
		for i in range(values_list.size()):
			if i > 0:
				s += ", "
			s += DSLObject._py_repr(values_list[i])
		return "[" + s + "]"

## DSL bytes 类型, 对应 Python bytes [br]
## 不可变字节串: 索引/迭代产出整数 (0-255), repr 形如 b'xy'
class DSLBytes extends DSLObject:
	## 字节数组 (每个元素 0-255)
	var data: Array[int] = []

	## 构造 bytes [br]
	## [param d] 字节数组 (元素为 0-255 的整数)
	func _init(d: Array = []):
		super._init()
		for b in d:
			data.append(int(b))

	func _type_name() -> String:
		return "bytes"

	## 字节长度
	func _dsl_len_hint() -> int:
		return data.size()

	## 迭代产出整数
	func _dsl_iter() -> DSLIterator:
		return DSLBytesIterator.new(self)

	## 索引/切片: 单个下标返回整数, 切片返回新 bytes
	func _dsl_getitem(index: DSLObject) -> DSLObject:
		if index is DSLSlice:
			var n = data.size()
			var res = _slice_range(index, n)
			if res == null:
				return null
			var out: Array[int] = []
			var i = int(res[0])
			var step = int(res[2])
			if step > 0:
				while i < int(res[1]):
					out.append(data[i])
					i += step
			else:
				while i > int(res[1]):
					out.append(data[i])
					i += step
			return DSLBytes.new(out)
		if not (index is DSLInteger):
			last_error = "TypeError: byte indices must be integers or slices, not %s" % index._type_name()
			return null
		var idx = index.value
		if idx < 0:
			idx += data.size()
		if idx < 0 or idx >= data.size():
			last_error = "IndexError: index out of range"
			return null
		return DSLInteger.new(data[idx])

	## 计算切片下标三元组 (与 range 相同的 CPython slice.indices 语义)
	func _slice_range(slice: DSLSlice, n: int):
		var pstep = 1
		if slice.step != null:
			if not (slice.step is DSLInteger):
				last_error = "TypeError: slice indices must be integers"
				return null
			pstep = slice.step.value
		if pstep == 0:
			last_error = "ValueError: slice step cannot be zero"
			return null
		var pstart = 0 if pstep > 0 else n - 1
		var pstop = n if pstep > 0 else -1
		if slice.start != null:
			if not (slice.start is DSLInteger):
				last_error = "TypeError: slice indices must be integers"
				return null
			pstart = slice.start.value
			if pstart < 0:
				pstart += n
			pstart = clampi(pstart, (0 if pstep > 0 else -1), (n if pstep > 0 else n - 1))
		if slice.stop != null:
			if not (slice.stop is DSLInteger):
				last_error = "TypeError: slice indices must be integers"
				return null
			pstop = slice.stop.value
			if pstop < 0:
				pstop += n
			pstop = clampi(pstop, (0 if pstep > 0 else -1), (n if pstep > 0 else n - 1))
		return [pstart, pstop, pstep]

	## 成员判定: 支持单个字节 (int) 与子串 (bytes)
	func magic_contains(args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLObject:
		var target = DSLObject._unwrap_dsl(args[1])
		if target is DSLInteger:
			for b in data:
				if b == target.value:
					return DSLBool.new(true)
				return DSLBool.new(false)
		if target is DSLBytes:
			var sub = target.data
			if sub.is_empty():
				return DSLBool.new(true)
			for i in range(data.size() - sub.size() + 1):
				var ok = true
				for j in range(sub.size()):
					if data[i + j] != sub[j]:
						ok = false
						break
				if ok:
					return DSLBool.new(true)
			return DSLBool.new(false)
		return DSLBool.new(false)

	## 相等判定: 仅与 bytes 逐字节比较 (与 str 不相等)
	func _dsl_eq(other: DSLObject) -> bool:
		var rhs = DSLObject._unwrap_dsl(other)
		if rhs is DSLBytes:
			return data == rhs.data
		return false

	func _dsl_ne(other: DSLObject) -> bool:
		return not _dsl_eq(other)

	func magic_eq(args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLBool:
		return DSLBool.new(args[0]._dsl_eq(args[1]))

	func magic_ne(args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLBool:
		return DSLBool.new(not args[0]._dsl_eq(args[1]))

	## repr 形如 b'xy'; str() 与 repr 相同 (CPython 的 bytes 即如此)
	func _dsl_str() -> String:
		var s = "b'"
		for b in data:
			if b == 9:
				s += "\t"
			elif b == 10:
				s += "\n"
			elif b == 13:
				s += "\r"
			elif b == 92:
				s += "\\\\"
			elif b == 39:
				s += "'"
			elif b >= 32 and b < 127:
				s += char(b)
			else:
				s += String.chr(92) + "x%02x" % b
		return s + "'"

	func magic_repr(args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLObject:
		return DSLString.new(args[0]._dsl_str())

	## 拼接: bytes + bytes -> 新 bytes (与 CPython 一致, 不允许与 str 混拼)
	func magic_add(args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLObject:
		var other = DSLObject._unwrap_dsl(args[1])
		if other is DSLBytes:
			var out: Array[int] = []
			out.append_array(args[0].data)
			out.append_array(other.data)
			return DSLBytes.new(out)
		last_error = "TypeError: can't concat %s to bytes" % other._type_name()
		return null

	## 重复: bytes * n -> 新 bytes
	func magic_mul(args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLObject:
		var other = args[1]
		if other is DSLInteger:
			var out: Array[int] = []
			for _i in range(maxi(0, other.value)):
				out.append_array(args[0].data)
			return DSLBytes.new(out)
		last_error = "TypeError: can't multiply sequence by non-int"
		return null

	func _dsl_bool() -> bool:
		return data.size() > 0

## bytes 的迭代器 (产出整数)
class DSLBytesIterator extends DSLIterator:
	## 所属 bytes
	var src: DSLBytes = null
	## 当前位置
	var index: int = 0

	func _init(b: DSLBytes):
		src = b

	func has_next() -> bool:
		return index < src.data.size()

	func next() -> DSLObject:
		if index >= src.data.size():
			return null
		var v = src.data[index]
		index += 1
		return DSLInteger.new(v)

## DSL 集合类型, 对应 Python set [br]
## 元素为可哈希对象 (int/float/str/bool/None/tuple), 通过规范化键保证唯一性 [br]
## 支持集合运算 (| & - ^), 比较 (== != < <= > >=) 与常用方法
class DSLSet extends DSLObject:
	## 规范化键 -> DSLObject 映射
	var items: Dictionary = {}

	func _type_name() -> String:
		return "set"

	## 计算元素的规范化键, 不可哈希返回空字符串 [br]
	## [param obj] 元素对象 [br]
	## [returns] 规范化键, 不可哈希返回 ""
	func _set_key(obj: DSLObject) -> String:
		obj = DSLObject._unwrap_dsl(obj)
		if obj is DSLInteger:
			return "i:" + str(obj.value)
		if obj is DSLFloat:
			return "f:" + str(obj.value)
		if obj is DSLBool:
			return "b:" + ("1" if obj.value else "0")
		if obj is DSLNone:
			return "n"
		if obj is DSLString:
			return "s:" + obj.value
		if obj is DSLTuple:
			var parts = []
			for it in obj.items:
				var k = _set_key(it)
				if k == "":
					return ""
				parts.append(k)
			return "t:(" + ",".join(parts) + ")"
		if obj is DSLFrozenSet:
			var parts = []
			for k in obj.items:
				parts.append(k)
			parts.sort()
			return "fs:[" + ",".join(parts) + "]"
		if obj.klass != null:
			# 用户类实例: 需定义 __hash__ 才可作集合元素 (与 CPython 一致)
			var hash_method = obj.klass._lookup_method("__hash__")
			if hash_method == null:
				return ""
			var hres = obj.klass._invoke_func(hash_method, [obj] as Array[DSLObject], {} as Dictionary[String, DSLObject])
			if not (hres is DSLInteger):
				return ""
			# CPython 的集合以「哈希 + 相等」判定: 未定义 __eq__ 时退化为身份比较,
			# 故键 = 哈希值 + (定义了 __eq__ 则留空, 否则取对象身份)
			if obj.klass._lookup_method("__eq__") != null:
				return "u:" + str(hres.value)
			return "u:" + str(hres.value) + ":" + str(obj._object_id)
		return ""

	## 添加元素, 重复元素自动去重
	func _dsl_add(obj: DSLObject) -> DSLObject:
		var k = _set_key(obj)
		if k == "":
			last_error = "TypeError: unhashable type: '%s'" % obj._type_name()
			return null
		items[k] = obj
		return DSLNone.new()

	## 移除元素, 不存在时抛 KeyError
	func _dsl_remove(obj: DSLObject) -> DSLObject:
		var k = _set_key(obj)
		if k == "":
			last_error = "TypeError: unhashable type: '%s'" % obj._type_name()
			return null
		if not items.has(k):
			last_error = "KeyError: %s" % DSLObject._py_repr(obj)
			last_error_args = [obj] as Array[DSLObject]
			return null
		items.erase(k)
		return DSLNone.new()

	## 移除元素, 不存在时不报错
	func _dsl_discard(obj: DSLObject) -> DSLObject:
		var k = _set_key(obj)
		if k != "" and items.has(k):
			items.erase(k)
		return DSLNone.new()

	## 弹出任意元素, 空集合抛 KeyError
	func _dsl_pop() -> DSLObject:
		if items.is_empty():
			last_error = "KeyError: " + DSLObject._py_repr(DSLString.new("pop from an empty set"))
			last_error_args = [DSLString.new("pop from an empty set")] as Array[DSLObject]
			return null
		var k = items.keys()[0]
		var v = items[k]
		items.erase(k)
		return v

	func _dsl_clear() -> DSLObject:
		items.clear()
		return DSLNone.new()

	func _dsl_copy() -> DSLSet:
		var s = DSLSet.new()
		s.items = items.duplicate()
		return s

	func _contains_key(obj: DSLObject) -> bool:
		var k = _set_key(obj)
		return k != "" and items.has(k)

	func _dsl_union(other) -> DSLSet:
		var s = _dsl_copy()
		for k in other.items:
			s.items[k] = other.items[k]
		return s

	func _dsl_intersection(other) -> DSLSet:
		var s = DSLSet.new()
		for k in items:
			if other.items.has(k):
				s.items[k] = items[k]
		return s

	func _dsl_difference(other) -> DSLSet:
		var s = DSLSet.new()
		for k in items:
			if not other.items.has(k):
				s.items[k] = items[k]
		return s

	func _dsl_symmetric_difference(other) -> DSLSet:
		var s = DSLSet.new()
		for k in items:
			if not other.items.has(k):
				s.items[k] = items[k]
		for k in other.items:
			if not items.has(k):
				s.items[k] = other.items[k]
		return s

	func _dsl_issubset(other) -> bool:
		for k in items:
			if not other.items.has(k):
				return false
		return true

	func _dsl_issuperset(other) -> bool:
		return other._dsl_issubset(self)

	func _dsl_isdisjoint(other) -> bool:
		for k in items:
			if other.items.has(k):
				return false
		return true

	func _dsl_bool() -> bool:
		return not items.is_empty()

	## 字符串表示 (元素排序以保证确定性, 便于与 Python 对照)
	func _dsl_str() -> String:
		if items.is_empty():
			return "set()"
		var parts = []
		for k in items:
			var v = items[k]
			if v is DSLString:
				parts.append("'" + DSLObject._py_str_repr(v.value) + "'")
			else:
				parts.append(v._dsl_str())
		parts.sort()
		return "{" + ", ".join(parts) + "}"

	func _dsl_eq(other: DSLObject) -> bool:
		other = DSLObject._unwrap_dsl(other)
		if other is DSLSet:
			if items.size() != other.items.size():
				return false
			for k in items:
				if not other.items.has(k):
					return false
			return true
		return false

	func _dsl_iter() -> DSLIterator:
		return DSLSetIterator.new(self)

	func _dsl_getitem(index: DSLObject) -> DSLObject:
		last_error = "TypeError: 'set' object is not subscriptable"
		return null

	func magic_contains(args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLObject:
		var self_obj = args[0]
		var item = args[1]
		return DSLBool.new(self_obj._contains_key(item))

	func magic_len(args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLObject:
		return DSLInteger.new(args[0].items.size())

	## 并集 |
	func magic_or(args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLObject:
		var other = DSLObject._unwrap_dsl(args[1])
		if other is DSLSet:
			return args[0]._dsl_union(other)
		args[0]._arithmetic_type_error("|", args[1])
		return null

	## 交集 &
	func magic_and(args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLObject:
		var other = DSLObject._unwrap_dsl(args[1])
		if other is DSLSet:
			return args[0]._dsl_intersection(other)
		args[0]._arithmetic_type_error("&", args[1])
		return null

	## 差集 -
	func magic_sub(args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLObject:
		var other = DSLObject._unwrap_dsl(args[1])
		if other is DSLSet:
			return args[0]._dsl_difference(other)
		args[0]._arithmetic_type_error("-", args[1])
		return null

	## 对称差集 ^
	func magic_xor(args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLObject:
		var other = DSLObject._unwrap_dsl(args[1])
		if other is DSLSet:
			return args[0]._dsl_symmetric_difference(other)
		args[0]._arithmetic_type_error("^", args[1])
		return null

	func magic_eq(args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLBool:
		return DSLBool.new(args[0]._dsl_eq(args[1] if len(args) > 1 else null))

	func magic_ne(args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLBool:
		return DSLBool.new(not args[0]._dsl_eq(args[1] if len(args) > 1 else null))

	## 真子集 <
	func magic_lt(args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLBool:
		var other = DSLObject._unwrap_dsl(args[1]) if len(args) > 1 else null
		if other is DSLSet:
			return DSLBool.new(args[0].items.size() < other.items.size() and args[0]._dsl_issubset(other))
		return DSLBool.new(false)

	## 子集 <=
	func magic_le(args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLBool:
		var other = DSLObject._unwrap_dsl(args[1]) if len(args) > 1 else null
		if other is DSLSet:
			return DSLBool.new(args[0]._dsl_issubset(other))
		return DSLBool.new(false)

	## 真超集 >
	func magic_gt(args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLBool:
		var other = DSLObject._unwrap_dsl(args[1]) if len(args) > 1 else null
		if other is DSLSet:
			return DSLBool.new(args[0].items.size() > other.items.size() and other._dsl_issubset(args[0]))
		return DSLBool.new(false)

	## 超集 >=
	func magic_ge(args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLBool:
		var other = DSLObject._unwrap_dsl(args[1]) if len(args) > 1 else null
		if other is DSLSet:
			return DSLBool.new(args[0]._dsl_issuperset(other))
		return DSLBool.new(false)

	## 方法回调 (args[0] = 实际实例)
	func builtin_add(args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLObject:
		return args[0]._dsl_add(args[1])

	func builtin_remove(args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLObject:
		return args[0]._dsl_remove(args[1])

	func builtin_discard(args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLObject:
		return args[0]._dsl_discard(args[1])

	func builtin_pop(args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLObject:
		return args[0]._dsl_pop()

	func builtin_clear(args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLObject:
		return args[0]._dsl_clear()

	func builtin_copy(args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLObject:
		return args[0]._dsl_copy()

	func builtin_union(args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLObject:
		var other = DSLObject._unwrap_dsl(args[1])
		if other is DSLSet:
			return args[0]._dsl_union(other)
		args[0].last_error = "TypeError: union() argument must be a set"
		return null

	func builtin_intersection(args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLObject:
		var other = DSLObject._unwrap_dsl(args[1])
		if other is DSLSet:
			return args[0]._dsl_intersection(other)
		args[0].last_error = "TypeError: intersection() argument must be a set"
		return null

	func builtin_difference(args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLObject:
		var other = DSLObject._unwrap_dsl(args[1])
		if other is DSLSet:
			return args[0]._dsl_difference(other)
		args[0].last_error = "TypeError: difference() argument must be a set"
		return null

	func builtin_symmetric_difference(args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLObject:
		var other = DSLObject._unwrap_dsl(args[1])
		if other is DSLSet:
			return args[0]._dsl_symmetric_difference(other)
		args[0].last_error = "TypeError: symmetric_difference() argument must be a set"
		return null

	func builtin_issubset(args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLObject:
		var other = DSLObject._unwrap_dsl(args[1])
		if other is DSLSet:
			return DSLBool.new(args[0]._dsl_issubset(other))
		args[0].last_error = "TypeError: issubset() argument must be a set"
		return null

	func builtin_issuperset(args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLObject:
		var other = DSLObject._unwrap_dsl(args[1])
		if other is DSLSet:
			return DSLBool.new(args[0]._dsl_issuperset(other))
		args[0].last_error = "TypeError: issuperset() argument must be a set"
		return null

	func builtin_isdisjoint(args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLObject:
		var other = DSLObject._unwrap_dsl(args[1])
		if other is DSLSet:
			return DSLBool.new(args[0]._dsl_isdisjoint(other))
		args[0].last_error = "TypeError: isdisjoint() argument must be a set"
		return null

## collections.defaultdict 默认字典对象, 对应 Python defaultdict [br]
## 缺失键访问时自动调用工厂函数创建默认值并存储
class DSLDefaultDict extends DSLObject:
	## 底层字典 (实际存储)
	var inner: DSLDict = DSLDict.new()
	## 默认值工厂 (可调用 DSLObject 或 null)
	var factory = null
	## 是否为 Counter (暴露 most_common 方法)
	var is_counter: bool = false

	func _type_name() -> String:
		return "defaultdict"

	func _dsl_str() -> String:
		return inner._dsl_str()

	func _dsl_bool() -> bool:
		return inner._dsl_bool()

	## 获取键值, 缺失时自动调用工厂创建并存储 [br]
	## [param index] 键 [br]
	## [returns] 值, 出错时返回 null
	func _dsl_getitem(index: DSLObject) -> DSLObject:
		var vkey = inner._key_to_variant(index)
		if vkey == null:
			last_error = inner.last_error
			return null
		if inner.dict.has(vkey):
			return inner.dict[vkey]
		if factory != null:
			var created = factory.magic_call([] as Array[DSLObject], {} as Dictionary[String, DSLObject])
			if created != null:
				inner.dict[vkey] = created
				return created
		last_error = "KeyError: %s" % DSLObject._py_repr(index)
		last_error_args = [index] as Array[DSLObject]
		return null

	## 设置键值 (委托底层字典)
	func _dsl_setitem(index: DSLObject, value: DSLObject):
		inner._dsl_setitem(index, value)

	## 属性访问: default_factory 返回工厂, most_common 仅 Counter 暴露, 其余委托底层字典 (keys/values/items/get 等)
	func _dsl_getattribute(name: String) -> DSLObject:
		if name == "default_factory":
			return factory if factory != null else DSLNone.new()
		if name == "most_common" and is_counter:
			var bf = DSLBuiltinFunction.new("most_common", Callable(self, "builtin_most_common"))
			bf.__self__ = self
			return bf
		return inner._dsl_getattribute(name)

	## Counter.most_common(n=None) - 按出现次数降序返回 [(元素, 次数)] 列表 [br]
	## 同次数按首次插入顺序排列 (与 Python 3.7+ 一致) [br]
	## 采用 __self__ 绑定模式: args[0] 为 self, 之后才是参数
	func builtin_most_common(args: Array, _kwargs: Dictionary[String, DSLObject]) -> DSLObject:
		var self_obj: DSLDefaultDict = self
		if args.size() >= 1 and args[0] == self:
			self_obj = args[0]
		var n = -1
		if args.size() >= 2:
			var a = args[1]
			if a is DSLInteger:
				n = a.value
			elif a is DSLFloat:
				n = int(a.value)
			else:
				last_error = "TypeError: most_common() argument must be an integer"
				return null
		var pairs: Array = []
		var order = 0
		for k in self_obj.inner.dict.keys():
			var count = self_obj.inner.dict[k]
			var count_val = count.value if (count is DSLInteger or count is DSLFloat) else 0
			var obj_key: DSLObject = null
			if typeof(k) == TYPE_STRING:
				obj_key = DSLString.new(k)
			elif typeof(k) == TYPE_INT:
				obj_key = DSLInteger.new(k)
			elif typeof(k) == TYPE_FLOAT:
				obj_key = DSLFloat.new(k)
			elif typeof(k) == TYPE_BOOL:
				obj_key = DSLBool.new(k)
			else:
				obj_key = DSLNone.new()
			pairs.append({"key": obj_key, "count": int(count_val), "order": order})
			order += 1
		pairs.sort_custom(func(a, b):
			if a["count"] != b["count"]:
				return a["count"] > b["count"]
			return a["order"] < b["order"])
		var result = DSLList.new()
		for p in pairs:
			if n >= 0 and result.items.size() >= n:
				break
			result.items.append(DSLTuple.new([p["key"], DSLInteger.new(p["count"])]))
		return result

	func _dsl_iter() -> DSLIterator:
		return inner._dsl_iter()

	## 长度
	func magic_len(_args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLObject:
		return DSLInteger.new(inner.dict.size())

	## 成员检查
	func magic_contains(args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLObject:
		var item = args[1]
		var vkey = inner._key_to_variant(item)
		return DSLBool.new(vkey != null and inner.dict.has(vkey))

## frozenset 不可变集合类型, 对应 Python frozenset [br]
## 可哈希 (可作为 set 元素), 不含可变操作方法 (add/remove 等)
class DSLFrozenSet extends DSLSet:
	func _type_name() -> String:
		return "frozenset"

	func _dsl_str() -> String:
		if items.is_empty():
			return "frozenset()"
		var parts = []
		for k in items:
			var v = items[k]
			if v is DSLString:
				parts.append("'" + DSLObject._py_str_repr(v.value) + "'")
			else:
				parts.append(v._dsl_str())
		parts.sort()
		return "frozenset({" + ", ".join(parts) + "})"

	## 从 DSLSet 构造 DSLFrozenSet (浅拷贝) [br]
	## [param src] 源集合 [br]
	## [returns] DSLFrozenSet
	func _from_set(src: DSLSet) -> DSLFrozenSet:
		var fs = DSLFrozenSet.new()
		fs.items = src.items.duplicate()
		return fs

	## 并集 | (返回 frozenset)
	func magic_or(args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLObject:
		var other = DSLObject._unwrap_dsl(args[1])
		if other is DSLSet:
			return _from_set(args[0]._dsl_union(other))
		args[0]._arithmetic_type_error("|", args[1])
		return null

	## 交集 & (返回 frozenset)
	func magic_and(args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLObject:
		var other = DSLObject._unwrap_dsl(args[1])
		if other is DSLSet:
			return _from_set(args[0]._dsl_intersection(other))
		args[0]._arithmetic_type_error("&", args[1])
		return null

	## 差集 - (返回 frozenset)
	func magic_sub(args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLObject:
		var other = DSLObject._unwrap_dsl(args[1])
		if other is DSLSet:
			return _from_set(args[0]._dsl_difference(other))
		args[0]._arithmetic_type_error("-", args[1])
		return null

	## 对称差集 ^ (返回 frozenset)
	func magic_xor(args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLObject:
		var other = DSLObject._unwrap_dsl(args[1])
		if other is DSLSet:
			return _from_set(args[0]._dsl_symmetric_difference(other))
		args[0]._arithmetic_type_error("^", args[1])
		return null

	## copy (返回 frozenset)
	func builtin_copy(args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLObject:
		return args[0]._from_set(args[0])

	## union (返回 frozenset)
	func builtin_union(args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLObject:
		var other = DSLObject._unwrap_dsl(args[1])
		if other is DSLSet:
			return _from_set(args[0]._dsl_union(other))
		args[0].last_error = "TypeError: union() argument must be a set"
		return null

	## intersection (返回 frozenset)
	func builtin_intersection(args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLObject:
		var other = DSLObject._unwrap_dsl(args[1])
		if other is DSLSet:
			return _from_set(args[0]._dsl_intersection(other))
		args[0].last_error = "TypeError: intersection() argument must be a set"
		return null

	## difference (返回 frozenset)
	func builtin_difference(args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLObject:
		var other = DSLObject._unwrap_dsl(args[1])
		if other is DSLSet:
			return _from_set(args[0]._dsl_difference(other))
		args[0].last_error = "TypeError: difference() argument must be a set"
		return null

	## symmetric_difference (返回 frozenset)
	func builtin_symmetric_difference(args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLObject:
		var other = DSLObject._unwrap_dsl(args[1])
		if other is DSLSet:
			return _from_set(args[0]._dsl_symmetric_difference(other))
		args[0].last_error = "TypeError: symmetric_difference() argument must be a set"
		return null

	## 集合运算/比较委托: eq/ne/lt/le/gt/ge/contains/len 沿用 DSLSet 实现, 但以 args[0] 为实例
	func magic_eq(args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLBool:
		return DSLBool.new(args[0]._dsl_eq(args[1] if len(args) > 1 else null))

	func magic_ne(args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLBool:
		return DSLBool.new(not args[0]._dsl_eq(args[1] if len(args) > 1 else null))

	func magic_lt(args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLBool:
		var other = DSLObject._unwrap_dsl(args[1]) if len(args) > 1 else null
		if other is DSLSet:
			return DSLBool.new(args[0].items.size() < other.items.size() and args[0]._dsl_issubset(other))
		return DSLBool.new(false)

	func magic_le(args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLBool:
		var other = DSLObject._unwrap_dsl(args[1]) if len(args) > 1 else null
		if other is DSLSet:
			return DSLBool.new(args[0]._dsl_issubset(other))
		return DSLBool.new(false)

	func magic_gt(args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLBool:
		var other = DSLObject._unwrap_dsl(args[1]) if len(args) > 1 else null
		if other is DSLSet:
			return DSLBool.new(args[0].items.size() > other.items.size() and other._dsl_issubset(args[0]))
		return DSLBool.new(false)

	func magic_ge(args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLBool:
		var other = DSLObject._unwrap_dsl(args[1]) if len(args) > 1 else null
		if other is DSLSet:
			return DSLBool.new(args[0]._dsl_issuperset(other))
		return DSLBool.new(false)

	func magic_len(args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLObject:
		return DSLInteger.new(args[0].items.size())

	func magic_contains(args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLObject:
		var self_obj = args[0]
		var item = args[1]
		return DSLBool.new(self_obj._contains_key(item))

## DSL 集合迭代器
class DSLSetIterator extends DSLIterator:
	## 被迭代的集合
	var set_obj: DSLSet
	## 键数组
	var keys: Array
	## 当前索引
	var index: int = 0

	## 构造集合迭代器 [br]
	## [param s] 被迭代的集合
	func _init(s):
		set_obj = s
		keys = s.items.keys()

	func has_next() -> bool:
		return index < keys.size()

	func next() -> DSLObject:
		var v = set_obj.items[keys[index]]
		index += 1
		return v

## DSL Property 描述符, 对应 Python @property 装饰器 [br]
## 实现数据描述符协议 (__get__ / __set__ / __delete__) [br]
## 存储 getter 函数和可选的 setter/deleter 函数
class DSLProperty extends DSLObject:
	## 属性名
	var prop_name: String
	## getter 函数 (DSLFunction)
	var fget
	## setter 函数 (DSLFunction, 可为 null)
	var fset
	## deleter 函数 (DSLFunction, 可为 null)
	var fdel
	## 解释器引用
	var _cls_interp
	
	## 构造 Property 描述符 [br]
	## [param p_name] 属性名 [br]
	## [param getter] getter 函数 [br]
	## [param p_interp] 解释器引用
	func _init(p_name, getter, p_interp):
		super._init()
		prop_name = p_name
		fget = getter
		fset = null
		fdel = null
		_cls_interp = p_interp
	
	func _type_name() -> String:
		return "property"
	
	func _dsl_str() -> String:
		return "<property '%s'>" % prop_name
	
	## 描述符协议 __get__ [br]
	## [param instance] 实例 (null 时返回自身) [br]
	## [param owner] 所属类 [br]
	## [returns] getter 函数的返回值
	func __get__(instance, _owner):
		if instance == null:
			return self
		if fget == null:
			return DSLNone.new()
		return _cls_interp.call_user_function(fget, [instance] as Array[DSLObject], {} as Dictionary[String, DSLObject])
	
	## 描述符协议 __set__ [br]
	## [param instance] 实例 [br]
	## [param value] 要设置的值
	func __set__(instance, value):
		if fset == null:
			instance.last_error = "AttributeError: can't set attribute"
			return
		_cls_interp.call_user_function(fset, [instance, value] as Array[DSLObject], {} as Dictionary[String, DSLObject])
	
	## 描述符协议 __delete__ [br]
	## [param instance] 实例
	func __delete__(instance):
		if fdel == null:
			instance.last_error = "AttributeError: can't delete attribute"
			return
		_cls_interp.call_user_function(fdel, [instance] as Array[DSLObject], {} as Dictionary[String, DSLObject])
	
	## setter 装饰器 [br]
	## [param setter_func] setter 函数 [br]
	## [returns] self (用于链式调用)
	func setter(setter_func):
		fset = setter_func
		return self
	
	## deleter 装饰器 [br]
	## [param deleter_func] deleter 函数 [br]
	## [returns] self
	func deleter(deleter_func):
		fdel = deleter_func
		return self

## DSL 用户自定义函数对象, 对应 Python function
class DSLFunction extends DSLObject:
	## 函数声明 AST 节点
	var declaration: FunctionStmt
	## 闭包环境 (捕获的外部变量)
	var closure: DSLEnvironment
	## 方法类型 0=普通函数, 1=classmethod, 2=staticmethod
	var method_type: int = 0
	## 定义该方法的类 (super() 定位), 顶层函数为 null
	var _defining_class: DSLClass = null
	## 类解释器引用
	var _cls_interp: Interpreter = null
	## 默认参数值数组
	var default_values: Array[Variant] = []
	
	## 构造函数对象 [br]
	## [param decl] 函数声明 AST 节点 [br]
	## [param clos] 闭包环境
	func _init(decl, clos):
		super._init()
		declaration = decl
		closure = clos
		method_type = decl.method_type
	
	func _type_name() -> String:
		return "function"
	
	func _dsl_str() -> String:
		return "<function " + declaration.name + ">"
	
	## 函数调用 (由 Interpreter.call_user_function 实现, 此处为占位符) [br]
	## [param _kwargs] 关键字参数 [br]
	## [returns] 在用户函数调用逻辑中实际被替换, 这里直接返回 null
	func magic_call(_args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject] = {}) -> DSLObject:
		if _cls_interp != null:
			return _cls_interp.call_user_function(self, _args, _kwargs)
		return null
	
	## 描述符协议 __get__ [br]
	## [param instance] 实例 (可为 null) [br]
	## [param owner] 所属类 [br]
	## [returns] staticmethod 返回自身, classmethod 返回绑定 DSLMethod(owner), 普通方法跟 instance 绑定
	func __get__(instance, owner):
		if method_type == 2:
			return self
		if method_type == 1:
			return DSLMethod.new(owner, self, _cls_interp)
		if instance == null:
			return self
		return DSLMethod.new(instance, self, _cls_interp)

## DSL 内置函数或绑定方法对象, 对应 Python builtin_function_or_method
class DSLBuiltinFunction extends DSLObject:
	## 函数名称
	var name: String
	## 回调 Callable
	var callback: Callable
	## 绑定的 self 对象 (null 表示未绑定)
	var __self__: DSLObject = null
	
	## 构造内置函数对象 [br]
	## [param p_name] 函数名称 [br]
	## [param p_cb] 回调 Callable
	func _init(p_name, p_cb):
		super._init()
		name = p_name
		callback = p_cb
	
	func _type_name() -> String:
		return "builtin_function_or_method"
	
	func _dsl_str() -> String:
		if __self__ != null:
			return "<built-in method '%s' of '%s' object>" % [name, __self__._type_name()]
		return "<built-in function %s>" % name
	
	## 调用内置函数 [br]
	## [param kwargs] 关键字参数 [br]
	## [returns] 函数返回值 (自动包装为 DSLObject), 已绑定时自动插入 __self__
	func magic_call(args: Array[DSLObject], kwargs: Dictionary[String, DSLObject] = {}) -> DSLObject:
		if __self__ != null:
			var full_args: Array[DSLObject] = [__self__]
			full_args.append_array(args)
			return _wrap(callback.callv([full_args, kwargs]))
		return _wrap(callback.callv([args, kwargs]))
	
	## Variant 包装为 DSLObject (静态方法, 支持缓存) [br]
	## [param v] 任意 Variant 值 [br]
	## [returns] 对应的 DSLObject, int/float/string/bool/null/Array/Dictionary 分别映射
	static func _wrap_static(v: Variant) -> DSLObject:
		if v is DSLObject:
			return v
		if typeof(v) == TYPE_INT:
			return DSLInteger.new(v)
		if typeof(v) == TYPE_FLOAT:
			return DSLFloat.new(v)
		if typeof(v) == TYPE_STRING:
			return DSLString.new(v)
		if typeof(v) == TYPE_BOOL:
			if v:
				if Interpreter._cached_true == null:
					Interpreter._cached_true = DSLBool.new(v)
				return Interpreter._cached_true
			if Interpreter._cached_false == null:
				Interpreter._cached_false = DSLBool.new(v)
			return Interpreter._cached_false
		if v == null:
			if Interpreter._cached_none == null:
				Interpreter._cached_none = DSLNone.new()
			return Interpreter._cached_none
		if v is Array:
			var lst = DSLList.new()
			for e in v:
				lst.items.append(_wrap_static(e))
			return lst
		if v is Dictionary:
			var d = DSLDict.new()
			for k in v.keys():
				d.dict[_wrap_static(k)] = _wrap_static(v[k])
			return d
		return Interpreter._cached_none if Interpreter._cached_none else DSLNone.new()
	
	## Variant 包装为 DSLObject (实例方法, 委托 _wrap_static) [br]
	## [param v] 任意 Variant 值 [br]
	## [returns] 对应的 DSLObject
	func _wrap(v: Variant) -> DSLObject:
		return _wrap_static(v)

## functools.partial 偏函数对象, 对应 Python functools.partial [br]
## 持有原函数与预绑定的参数, 调用时合并预绑定参数与本次调用参数
class DSLPartial extends DSLObject:
	## 原函数 (DSLFunction/DSLBuiltinFunction/DSLClass/DSLMethod 等可调用对象)
	var target_func: DSLObject = null
	## 预绑定的位置参数
	var bound_args: Array[DSLObject] = []
	## 预绑定的关键字参数
	var bound_kwargs: Dictionary[String, DSLObject] = {}
	## 解释器引用
	var _cls_interp: Interpreter = null

	## 构造偏函数 [br]
	## [param p_func] 原函数 [br]
	## [param p_args] 预绑定位置参数 [br]
	## [param p_kwargs] 预绑定关键字参数
	func _init(p_func, p_args, p_kwargs):
		super._init()
		target_func = p_func
		bound_args = p_args
		bound_kwargs = p_kwargs

	func _type_name() -> String:
		return "partial"

	func _dsl_str() -> String:
		if target_func != null:
			return "functools.partial(%s)" % target_func._dsl_str()
		return "functools.partial(?)"

	## 调用偏函数: 合并预绑定参数与本次调用参数后调用原函数 [br]
	## [param args] 本次调用的位置参数 [br]
	## [param kwargs] 本次调用的关键字参数 [br]
	## [returns] 原函数调用结果
	func magic_call(args: Array[DSLObject], kwargs: Dictionary[String, DSLObject] = {}) -> DSLObject:
		var full_args: Array[DSLObject] = bound_args.duplicate()
		full_args.append_array(args)
		var full_kwargs: Dictionary[String, DSLObject] = bound_kwargs.duplicate()
		for k in kwargs:
			full_kwargs[k] = kwargs[k]
		if target_func == null:
			last_error = "TypeError: 'NoneType' object is not callable"
			return null
		return target_func.magic_call(full_args, full_kwargs)

## functools.cmp_to_key 的 key 对象, 对应 CPython functools.KeyWrapper [br]
## 两种形态: 未包装值时为 key 工厂 (调用它以包装元素), 已包装值时按 cmp(a, b) 的符号比较
class DSLCmpKey extends DSLObject:
	## 底层被包装的值 (null 表示工厂形态)
	var value: DSLObject = null
	## 旧式比较函数 cmp(a, b), 返回负数/零/正数
	var cmp_func: DSLObject

	## 构造 key 对象 [br]
	## [param v] 底层值, 传 null 构造工厂 [br]
	## [param c] 比较函数
	func _init(v: DSLObject, c: DSLObject):
		super._init()
		value = v
		cmp_func = c

	func _type_name() -> String:
		return "functools.KeyWrapper"

	func _dsl_str() -> String:
		return "<functools.KeyWrapper object>"

	func _dsl_is_callable() -> bool:
		return true

	## 用参数包装出新的 key 对象 (工厂与包装形态都可调用, 与 CPython 一致) [br]
	## [param args] 单个参数: 被包装的元素 [br]
	## [returns] 新的 DSLCmpKey
	func magic_call(args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject] = {}) -> DSLObject:
		if args.size() != 1:
			last_error = "TypeError: KeyWrapper() takes exactly 1 argument (%d given)" % args.size()
			return null
		return DSLCmpKey.new(args[0], cmp_func)

	## 调用底层比较函数并归一化为 -1/0/1 [br]
	## [param other] 另一个 key 包装对象 [br]
	## [returns] 比较结果符号
	func _cmp(other: DSLCmpKey) -> int:
		var r = cmp_func.magic_call([value, other.value] as Array[DSLObject], {} as Dictionary[String, DSLObject])
		if r == null:
			return 0
		var n = 0.0
		if r is DSLInteger or r is DSLFloat:
			n = float(r.value)
		if n < 0:
			return -1
		if n > 0:
			return 1
		return 0

	func magic_lt(args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLBool:
		return DSLBool.new(_cmp(args[1]) < 0)

	func magic_gt(args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLBool:
		return DSLBool.new(_cmp(args[1]) > 0)

	func magic_le(args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLBool:
		return DSLBool.new(_cmp(args[1]) <= 0)

	func magic_ge(args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLBool:
		return DSLBool.new(_cmp(args[1]) >= 0)

	func magic_eq(args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLBool:
		return DSLBool.new(_cmp(args[1]) == 0)

	func magic_ne(args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLBool:
		return DSLBool.new(_cmp(args[1]) != 0)

## operator.itemgetter 返回的可调用对象 [br]
## 单键取值, 多键返回由各键取值组成的元组
class DSLItemGetter extends DSLObject:
	## 目标键数组
	var keys: Array[DSLObject]

	## 构造 itemgetter 对象 [br]
	## [param k] 目标键数组
	func _init(k: Array[DSLObject]):
		super._init()
		keys = k

	func _type_name() -> String:
		return "operator.itemgetter"

	## 逐键生成 repr 文本 (与 CPython operator.itemgetter 的表示一致)
	func _dsl_str() -> String:
		var parts: Array = []
		for k in keys:
			var r = k.magic_repr([k] as Array[DSLObject], {} as Dictionary[String, DSLObject])
			parts.append(r.value if r is DSLString else k._dsl_str())
		return "operator.itemgetter(%s)" % ", ".join(parts)

	func _dsl_is_callable() -> bool:
		return true

	## 按键取值 [br]
	## [param args] 单个参数: 目标对象 [br]
	## [returns] 单键返回该键的值, 多键返回元组
	func magic_call(args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject] = {}) -> DSLObject:
		if args.size() != 1:
			last_error = "TypeError: itemgetter expected 1 argument, got %d" % args.size()
			return null
		var target = args[0]
		if keys.size() == 1:
			var v = target._dsl_getitem(keys[0])
			if v == null:
				last_error = target.last_error if target.last_error != "" else "TypeError: itemgetter target is not subscriptable"
			return v
		var out: Array[DSLObject] = []
		for k in keys:
			var v = target._dsl_getitem(k)
			if v == null:
				last_error = target.last_error if target.last_error != "" else "TypeError: itemgetter target is not subscriptable"
				return null
			out.append(v)
		return DSLTuple.new(out)

## operator.attrgetter 返回的可调用对象 [br]
## 单属性取值, 多属性返回由各属性值组成的元组, 属性名支持 a.b 点号路径
class DSLAttrGetter extends DSLObject:
	## 目标属性路径数组 (每项按 "." 切分)
	var paths: Array

	## 构造 attrgetter 对象 [br]
	## [param p] 属性名数组 (字符串数组)
	func _init(p: Array):
		super._init()
		paths = p

	func _type_name() -> String:
		return "operator.attrgetter"

	func _dsl_str() -> String:
		return "operator.attrgetter(%s)" % ", ".join(paths.map(func(p): return "'%s'" % p))

	func _dsl_is_callable() -> bool:
		return true

	## 沿点号路径逐级取属性 [br]
	## [param target] 目标对象 [br]
	## [param path] 属性路径 [br]
	## [returns] 属性值, 出错时返回 null
	func _get_path(target: DSLObject, path: String) -> DSLObject:
		var cur: DSLObject = target
		for part in path.split("."):
			cur = cur._dsl_getattribute(part)
			if cur == null:
				last_error = "AttributeError: '%s' object has no attribute '%s'" % [target._type_name(), part]
				return null
		return cur

	## 按属性路径取值 [br]
	## [param args] 单个参数: 目标对象 [br]
	## [returns] 单属性返回该属性值, 多属性返回元组
	func magic_call(args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject] = {}) -> DSLObject:
		if args.size() != 1:
			last_error = "TypeError: attrgetter expected 1 argument, got %d" % args.size()
			return null
		var target = args[0]
		if paths.size() == 1:
			return _get_path(target, paths[0])
		var out: Array[DSLObject] = []
		for p in paths:
			var v = _get_path(target, p)
			if v == null:
				return null
			out.append(v)
		return DSLTuple.new(out)

## DSL 类级别非魔法方法描述符, 对应 Python method_descriptor
class DSLMethodDescriptor extends DSLObject:
	## 方法名称
	var name: String
	## 回调 Callable
	var callback: Callable
	
	## 构造方法描述符 [br]
	## [param p_name] 方法名称 [br]
	## [param p_cb] 回调 Callable
	func _init(p_name, p_cb):
		super._init()
		name = p_name
		callback = p_cb
	
	func _type_name() -> String:
		return "method_descriptor"
	
	func _dsl_str() -> String:
		return "<method '%s' of '%s' objects>" % [name, "??"]
	
	## 直接调用 (通过 Callable 执行) [br]
	## [param kwargs] 关键字参数 [br]
	## [returns] 方法返回值 (自动包装为 DSLObject)
	func magic_call(args: Array[DSLObject], kwargs: Dictionary[String, DSLObject] = {}) -> DSLObject:
		return DSLBuiltinFunction._wrap_static(callback.callv([args, kwargs]))
	
	## 描述符协议 __get__ [br]
	## [param instance] 实例 (null 时返回自身) [br]
	## [param owner] 所属类 (未使用) [br]
	## [returns] instance 非空则返回绑定了 self 的 DSLBuiltinFunction
	func __get__(instance, _owner):
		if instance == null:
			return self
		var bf = DSLBuiltinFunction.new(name, callback)
		bf.__self__ = instance
		return bf

## DSL 类级别魔法方法描述符, 对应  Python wrapper_descriptor
class DSLWrappedDescriptor extends DSLObject:
	## 方法名称
	var name: String
	## 回调 Callable
	var callback: Callable
	
	## 构造魔法方法描述符 [br]
	## [param p_name] 方法名称 [br]
	## [param p_cb] 回调 Callable
	func _init(p_name, p_cb):
		super._init()
		name = p_name
		callback = p_cb
	
	func _type_name() -> String:
		return "wrapper_descriptor"
	
	func _dsl_str() -> String:
		return "<slot wrapper '%s' of '%s' objects>" % [name, "??"]
	
	## 直接调用 (通过 Callable 执行) [br]
	## [param kwargs] 关键字参数 [br]
	## [returns] 方法返回值 (自动包装为 DSLObject)
	func magic_call(args: Array[DSLObject], kwargs: Dictionary[String, DSLObject] = {}) -> DSLObject:
		return DSLBuiltinFunction._wrap_static(callback.callv([args, kwargs]))
	
	## 描述符协议 __get__ [br]
	## [param instance] 实例 (null 时返回自身) [br]
	## [param owner] 所属类 (未使用) [br]
	## [returns] instance 非空则返回 DSLMethodWrapper 绑定实例
	func __get__(instance, _owner):
		if instance == null:
			return self
		return DSLMethodWrapper.new(self, instance)

## DSL 实例级别魔法方法包装, 对应 Python method-wrapper
class DSLMethodWrapper extends DSLObject:
	## 所属描述符
	var descriptor: DSLWrappedDescriptor
	## 绑定 self 对象
	var bound_self: DSLObject
	
	## 实例级别构造魔法方法包装 [br]
	## [param p_desc] 所属描述符 [br]
	## [param p_self] 绑定 self 对象
	func _init(p_desc, p_self):
		super._init()
		descriptor = p_desc
		bound_self = p_self
	
	func _type_name() -> String:
		return "method-wrapper"
	
	func _dsl_str() -> String:
		return "<method-wrapper '%s' of %s object>" % [descriptor.name, bound_self._type_name()]
	
	## 调用包装的魔法方法 [br]
	## [param kwargs] 关键字参数 [br]
	## [returns] 方法返回值 (自动将 bound_self 插入参数列表首位)
	func magic_call(args: Array[DSLObject], kwargs: Dictionary[String, DSLObject] = {}) -> DSLObject:
		var full_args: Array[DSLObject] = [bound_self]
		full_args.append_array(args)
		var callv_args = [full_args, kwargs]
		var raw_result = descriptor.callback.callv(callv_args)
		return DSLBuiltinFunction._wrap_static(raw_result)

## DSL 用户定义绑定方法, 对应 Python method
class DSLMethod extends DSLObject:
	## 方法所属实例
	var instance: DSLObject
	## 函数对象
	var function: DSLFunction
	
	## 构造绑定方法 [br]
	## [param p_instance] 方法所属实例 [br]
	## [param p_func] 函数对象 [br]
	## [param p_interp] 解释器引用
	func _init(p_instance, p_func, p_interp):
		super._init()
		instance = p_instance
		function = p_func
		interp = p_interp
		
	func _type_name() -> String:
		return "method"
		
	func _dsl_str() -> String:
		var klass_name = instance.klass.name
		var func_name = function.declaration.name
		return "<bound method %s.%s of %s>" % [klass_name, func_name, instance._type_name()]
		
	## 调用绑定方法 [br]
	## [param kwargs] 关键字参数 [br]
	## [returns] 函数返回值 (自动将 instance 插入参数列表首位)
	func magic_call(args: Array[DSLObject], kwargs: Dictionary[String, DSLObject] = {}) -> DSLObject:
		var new_args: Array[DSLObject] = [instance]
		new_args.append_array(args)
		return interp.call_user_function(function, new_args, kwargs)

## DSL 类对象, 对应 Python type, 支持继承和方法查找
class DSLClass extends DSLObject:
	## 类名
	var name: String
	## 基类, 可为 null
	var superclass: DSLClass
	## 方法名字 -> DSLFunction
	var methods: Dictionary
	## 类属性
	var class_attrs: Dictionary
	
	## 构造 DSLClass 对象 [br]
	## [param p_name] 类名 [br]
	## [param p_superclass] 基类 (可为 null) [br]
	## [param p_methods] 方法字典 [br]
	## [param p_interp] 解释器引用
	func _init(p_name, p_superclass, p_methods, p_interp):
		super._init()
		name = p_name
		superclass = p_superclass
		methods = p_methods
		interp = p_interp
		class_attrs = {}
	
	func _dsl_str(): return "<class '%s'>" % name
	
	## 类调用 (实例化) [br]
	## 先调用 __new__ 创建实例, 再调用 __init__ 初始化 [br]
	## [param kwargs] 关键字参数 [br]
	## [returns] 新创建的实例 (DSLObject)
	func magic_call(args: Array[DSLObject], kwargs: Dictionary[String, DSLObject] = {}) -> DSLObject:
		var new_func = _lookup_method("__new__")
		var new_args: Array[DSLObject] = [self]
		new_args.append_array(args)
		var instance = _invoke_func(new_func, new_args, kwargs)
		if instance != null:
			instance.klass = self
		if instance == null or interp.report.has_error:
			return instance
		if instance.fields != null and instance._is_subclass_of_klass(self):
			var init_func = _lookup_method("__init__")
			if init_func != null:
				var init_args: Array[DSLObject] = [instance]
				init_args.append_array(args)
				_invoke_func(init_func, init_args, kwargs)
		return instance
	
	## 方法查找 (支持继承链) [br]
	## [param attr_name] 方法名称 [br]
	## [returns] 找到的函数
	func _lookup_method(attr_name: String) -> DSLObject:
		if methods.has(attr_name):
			return methods[attr_name]
		var current = superclass
		while current != null:
			if current.methods.has(attr_name):
				return current.methods[attr_name]
			current = current.superclass
		return null
	
	## 统一的方法调用入口 [br]
	## [param func_obj] 函数对象 (DSLBuiltinFunction DSLFunction 等) [br]
	## [param args_ary] 位置参数 [br]
	## [param kw_args] 关键字参数 [br]
	## [returns] 方法返回值
	func _invoke_func(func_obj, args_ary: Array[DSLObject], kw_args: Dictionary[String, DSLObject]) -> DSLObject:
		if func_obj == null:
			return null
		if func_obj is DSLBuiltinFunction:
			return func_obj.magic_call(args_ary, kw_args)
		if func_obj is DSLFunction:
			return interp.call_user_function(func_obj, args_ary, kw_args)
		return func_obj.magic_call(args_ary, kw_args)
	
	## 属性访问 (方法查找 + 描述符协议 + 继承链) [br]
	## [param attr_name] 属性名 [br]
	## [returns] 方法 (经__get__ 描述符处理), 类属性, 或委托给父类/superclass
	func _dsl_getattribute(attr_name: String) -> DSLObject:
		if attr_name == "__name__":
			return DSLString.new(name)
		if methods.has(attr_name):
			var method = methods[attr_name]
			if method is DSLBuiltinFunction:
				return method
			if method.has_method("__get__"):
				return method.__get__(null, self)
			return method
		if class_attrs.has(attr_name):
			return class_attrs[attr_name]
		var current = superclass
		while current != null:
			if current.methods.has(attr_name):
				var method = current.methods[attr_name]
				if method is DSLBuiltinFunction:
					return method
				if method.has_method("__get__"):
					return method.__get__(null, self)
				return method
			if current.class_attrs.has(attr_name):
				return current.class_attrs[attr_name]
			current = current.superclass
		return DSLNone.new()
	
	## 设置类属性
	func _dsl_setattr(attr_name: String, value: DSLObject):
		class_attrs[attr_name] = value

## DSL super() 代理对象, 用于调用父类方法 [br]
## 持有父类引用与绑定实例, 属性查找沿父类 MRO 并绑定到实例
class DSLSuper extends DSLObject:
	## 开始查找的类 (父类)
	var sup_cls: DSLClass = null
	## 绑定的实例 (self)
	var sup_instance: DSLObject = null
	## 解释器引用
	var sup_interp: Interpreter = null

	## 构造 super 代理 [br]
	## [param p_cls] 父类 [br]
	## [param p_instance] 绑定实例 [br]
	## [param p_interp] 解释器引用
	func _init(p_cls, p_instance, p_interp):
		super._init()
		sup_cls = p_cls
		sup_instance = p_instance
		sup_interp = p_interp

	func _type_name() -> String:
		return "super"

	func _dsl_str() -> String:
		if sup_cls != null:
			return "<super: <class '%s'>>" % sup_cls.name
		return "<super object>"

	## 属性访问: 沿父类查找并绑定到实例 [br]
	## 等价于 CPython super 代理的 __getattribute__
	func _dsl_getattribute(name: String) -> DSLObject:
		if sup_cls == null:
			last_error = "RuntimeError: super(): no class"
			return DSLNone.new()
		var method = sup_cls._dsl_getattribute(name)
		if method != null and not (method is DSLNone):
			if method.has_method("__get__"):
				return method.__get__(sup_instance, sup_cls)
			return method
		last_error = "AttributeError: 'super' object has no attribute '%s'" % name
		return DSLNone.new()

## DSL 模块对象, 对应 Python 的 module 对象 [br]
## 存储模块名与成员 (函数/常量), 通过属性访问获取成员 [br]
## 内置模块 (math/random) 在解释器初始化时注册, import 语句将其绑定到当前作用域
class DSLModule extends DSLObject:
	## 模块名
	var mod_name: String
	## 成员表: 名字 -> DSLObject
	var members: Dictionary[String, DSLObject] = {}

	## 构造模块 [br]
	## [param p_name] 模块名
	func _init(p_name):
		super._init()
		mod_name = p_name

	func _type_name() -> String:
		return "module"

	func _dsl_str() -> String:
		return "<module '%s'>" % mod_name

	## 属性访问: 优先查成员表, 未找到时回退到基类实现
	func _dsl_getattribute(name: String) -> DSLObject:
		if members.has(name):
			return members[name]
		return super._dsl_getattribute(name)

## DSL 迭代器基类, 对应 Python 迭代器协议 (鸭子类型) [br]
## DSLIterator 从未暴露, 无需继承自 DSLObject [br]
## 提供 has_next() / next() 接口的子类可 for 循环使用
class DSLIterator:
	## 最近一次推进是否因程序挂起 (sleep) 而中断 [br]
	## 消费方应据此把挂起向上传播, 而不是把迭代器当作已耗尽
	var suspended: bool = false
	## 是否已耗尽
	var done: bool = false
	## 是否为一次性迭代器 (生成器): 语句重放时必须从产出日志重读 [br]
	## 可重建迭代器 (列表/字符串/无限对象等) 重放时由消费方新建, 无需日志
	var once: bool = false
	## 已产出值的日志 (一次性迭代器维护; 供语句重放时重读)
	var _log: Array = []
	## 已消费位置 (一次性迭代器的读取游标)
	var _read_pos: int = 0
	## 已确认取走的最大位置 (高水位) [br]
	## 语句重放会把 _read_pos 回退到窗口起点以便重读, 但 next() 是「消费」语义:
	## 重放时必须从高水位继续驱动迭代器, 而不是把已交付过的值再交付一次
	var _hi_pos: int = 0
	## 当前消费窗口起点 (语句开始消费时的 _read_pos); 语句重放时游标回退到此 [br]
	## 使消费方无需感知挂起: 重放时重新调用 has_next()/next() 会自动重读相同序列
	var _win_start: int = -1
	## 是否参与语句消费窗口 (yield from 的子迭代器设为 false, 由父生成器状态负责)
	var windowed: bool = true
	## 窗口所属语句标识 (见 Interpreter._current_stmt_key)
	var _win_stmt: int = 0

	## 把迭代器层面的挂起转为解释器层面的挂起 [br]
	## 使消费方 (list/sum/推导式等原生循环) 无需感知挂起: [br]
	## 它们按 has_next() 返回 false 退出, 而语句会整体重放并重新消费 [br]
	## [param ip] 解释器引用
	func _propagate_suspend(ip) -> void:
		if ip == null:
			return
		ip._needs_replay = true
		ip._suspended = true
		ip._suspend_reason = Interpreter.SuspendReason.SLEEPING
		ip._is_waiting = false

	## 进入消费窗口: 语句切换时记录窗口起点并登记到解释器 (供语句重放时回退游标) [br]
	## 仅一次性迭代器需要; 可重建迭代器重放时由消费方新建实例 [br]
	## [param ip] 解释器引用
	func _begin_use(ip) -> void:
		if ip == null or not windowed:
			return
		if ip._current_generator != null:
			# 生成器步内部: 重放由生成器自身的挂起状态负责, 不再叠加语句消费窗口
			return
		# 以「重放根语句」为窗口锚点: 嵌套用户函数内部的语句会改变 _current_stmt_key,
		# 若按它锚定会在重放时把窗口起点重置到当前位置, 从而跳过此前已产出的元素
		var key = ip._sleep_root_key if ip._sleep_root_key != 0 else ip._current_stmt_key
		if _win_stmt == key:
			return
		_win_start = _read_pos
		_win_stmt = key
		if not ip._stmt_iterators.has(key):
			ip._stmt_iterators[key] = []
		var lst: Array = ip._stmt_iterators[key]
		if not lst.has(self):
			lst.append(self)

	## 检查是否还有下一个元素 [br]
	## [returns] 还有元素时返回 true
	func has_next() -> bool:
		return false
	
	## 获取下一个元素 [br]
	## [returns] 下一个元素 (DSLObject)
	func next() -> DSLObject:
		return null

## DSL range 类型, 对应 Python range [br]
## 惰性整数序列: 只保存 start/stop/step, 按索引与迭代惰性求值 (不预先展开) [br]
## 支持 len / 索引 (含负索引与切片) / 成员判定 / 相等比较 / 迭代
class DSLRange extends DSLObject:
	## 起始值 (含)
	var start: int = 0
	## 终止值 (不含)
	var stop: int = 0
	## 步长 (非 0)
	var step: int = 1

	## 构造 range [br]
	## [param a] 单参数时为 stop, 两/三参数时为 start [br]
	## [param b] stop (单参数时省略) [br]
	## [param s] 步长 (默认 1)
	func _init(a: int, b = null, s: int = 1):
		super._init()
		if b == null:
			start = 0
			stop = a
		else:
			start = a
			stop = int(b)
		step = s

	func _type_name() -> String:
		return "range"

	## 元素个数 (与 CPython 的 range.__len__ 一致)
	func _length() -> int:
		if step > 0:
			if stop <= start:
				return 0
			return (stop - start + step - 1) / step
		if stop >= start:
			return 0
		return (start - stop - step - 1) / (-step)

	func _dsl_len_hint() -> int:
		return _length()

	## 真值判定: 空 range 为假 (与 CPython 的 __len__ 回退一致)
	func _dsl_bool() -> bool:
		return _length() != 0

	## 取第 i 个元素 (i 已规范化为非负且在范围内)
	func _at(i: int) -> DSLObject:
		return DSLInteger.new(start + i * step)

	## 索引/切片访问 (CPython 语义: 支持负索引与 [start:stop:step] 切片) [br]
	## [param index] 索引或 DSLSlice [br]
	## [returns] 元素或子 range
	func _dsl_getitem(index: DSLObject) -> DSLObject:
		var n = _length()
		if index is DSLSlice:
			var res = _slice_indices(index, n)
			if res == null:
				return null
			var new_start = start + int(res[0]) * step
			var new_stop = start + int(res[1]) * step
			var new_step = step * int(res[2])
			return DSLRange.new(new_start, new_stop, new_step)
		if not (index is DSLInteger):
			last_error = "TypeError: range indices must be integers or slices, not %s" % index._type_name()
			return null
		var i = index.value
		if i < 0:
			i += n
		if i < 0 or i >= n:
			last_error = "IndexError: range object index out of range"
			return null
		return _at(i)

	## 计算切片对应的 (start, stop, step) 下标三元组 (CPython slice.indices 语义)
	func _slice_indices(slice: DSLSlice, n: int):
		var st = step
		var def_step = 1
		var pstep = def_step
		if slice.step != null:
			if not (slice.step is DSLInteger):
				last_error = "TypeError: slice indices must be integers"
				return null
			pstep = slice.step.value
		if pstep == 0:
			last_error = "ValueError: slice step cannot be zero"
			return null
		var lo = 0
		var hi = n
		var pstart = lo if pstep > 0 else hi - 1
		var pstop = hi if pstep > 0 else -1
		if slice.start != null:
			if not (slice.start is DSLInteger):
				last_error = "TypeError: slice indices must be integers"
				return null
			pstart = slice.start.value
			if pstart < 0:
				pstart += n
			if pstep > 0:
				pstart = clampi(pstart, lo, hi)
			else:
				pstart = clampi(pstart, lo - 1, hi - 1)
		if slice.stop != null:
			if not (slice.stop is DSLInteger):
				last_error = "TypeError: slice indices must be integers"
				return null
			pstop = slice.stop.value
			if pstop < 0:
				pstop += n
			if pstep > 0:
				pstop = clampi(pstop, lo, hi)
			else:
				pstop = clampi(pstop, lo - 1, hi - 1)
		return [pstart, pstop, pstep]

	## 成员判定 (按等差数列求解, 与 CPython 一致地支持任意 step)
	func magic_contains(args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLObject:
		var target = args[1]
		if not (target is DSLInteger):
			return DSLBool.new(false)
		var v = target.value
		if step > 0:
			if v < start or v >= stop:
				return DSLBool.new(false)
		else:
			if v > start or v <= stop:
				return DSLBool.new(false)
		return DSLBool.new((v - start) % step == 0)

	## 相等判定 (与 range 比较 start/stop/step, 与列表等不相等)
	func _dsl_eq(other: DSLObject) -> bool:
		other = DSLObject._unwrap_dsl(other)
		if other is DSLRange:
			if _length() == 0 and other._length() == 0:
				return true
			return start == other.start and stop == other.stop and step == other.step
		if other is DSLList:
			# 列表逐元素比较 (CPython: range(3) == [0,1,2] 为 False, 因类型不同)
			return false
		return false

	func _dsl_ne(other: DSLObject) -> bool:
		return not _dsl_eq(other)
	
	## 相等判定 (运算符 == 经 magic_eq 分派)
	func magic_eq(args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLBool:
		return DSLBool.new(args[0]._dsl_eq(args[1]))
	
	## 不等判定 (运算符 != 经 magic_ne 分派)
	func magic_ne(args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLBool:
		return DSLBool.new(not args[0]._dsl_eq(args[1]))

	## 元素赋值: range 不可变 (CPython 文案为 "does not support item assignment")
	func _dsl_setitem(_index: DSLObject, _value: DSLObject):
		last_error = "TypeError: 'range' object does not support item assignment"
	
	## 元素删除: range 不可变 (CPython 此处用 "doesn't", 与赋值文案不同)
	func _dsl_delitem(_index: DSLObject):
		last_error = "TypeError: 'range' object doesn't support item deletion"

	## repr: range(start, stop[, step]) 形式 (step 为 1 时省略)
	func _dsl_str() -> String:
		if step == 1:
			return "range(%d, %d)" % [start, stop]
		return "range(%d, %d, %d)" % [start, stop, step]

	func magic_repr(args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLObject:
		return DSLString.new(args[0]._dsl_str())

	## 迭代器 (惰性按需产出)
	func _dsl_iter() -> DSLIterator:
		return DSLRangeIterator.new(self)

	## 转列表 (供 list() / sorted() 等消费)
	func _to_list() -> DSLList:
		var lst = DSLList.new()
		var i = start
		if step > 0:
			while i < stop:
				lst.items.append(DSLInteger.new(i))
				i += step
		else:
			while i > stop:
				lst.items.append(DSLInteger.new(i))
				i += step
		return lst

## range 的惰性迭代器
class DSLRangeIterator extends DSLIterator:
	## 所属 range
	var rng: DSLRange = null
	## 当前值
	var current: int = 0
	## 是否已到末尾
	var exhausted: bool = false

	func _init(r: DSLRange):
		rng = r
		current = r.start
		exhausted = exactly_at_end()

	## 判断起始位置是否已越界 (空 range)
	func exactly_at_end() -> bool:
		if rng.step > 0:
			return current >= rng.stop
		return current <= rng.stop

	func has_next() -> bool:
		return not exhausted

	func next() -> DSLObject:
		if exhausted:
			return null
		var value = current
		current += rng.step
		exhausted = exactly_at_end()
		return DSLInteger.new(value)

## 用户类迭代器: 按用户定义的 __next__ 驱动 [br]
## 用于 __iter__ 返回用户实例 (常见写法: return self) 或对象自身实现 __next__ 的场景 [br]
## __next__ 抛 StopIteration 时视为耗尽
class DSLUserIterator extends DSLIterator:
	## 被驱动的用户实例 (需具备 __next__)
	var target: DSLObject = null
	## 所属解释器引用 (调用用户方法需要)
	var interp: Interpreter = null
	## 是否已预取下一个值
	var _has_prefetched: bool = false
	## 已预取的值
	var _prefetched: DSLObject = null

	## 构造用户迭代器 [br]
	## [param obj] 被驱动的用户实例
	func _init(obj: DSLObject):
		target = obj
		interp = obj.interp

	## 是否还有下一个元素 [br]
	## 用户 __next__ 可能有副作用, 不能预取: 这里惰性驱动一次并缓存结果
	func has_next() -> bool:
		if done:
			return false
		if not _has_prefetched:
			_prefetch()
		return not done

	## 取下一个元素 (必要时先预取)
	func next() -> DSLObject:
		if done:
			return null
		if not _has_prefetched:
			_prefetch()
		if done:
			return null
		_has_prefetched = false
		return _prefetched

	## 驱动一次用户 __next__ 并缓存结果, StopIteration 视为耗尽
	func _prefetch() -> void:
		_has_prefetched = true
		_prefetched = null
		if target == null or target.klass == null:
			done = true
			return
		var next_method = target.klass._lookup_method("__next__")
		if next_method == null:
			done = true
			return
		var res = target.klass._invoke_func(next_method, [target] as Array[DSLObject], {} as Dictionary[String, DSLObject])
		if interp != null and interp.report.has_error:
			# StopIteration (或其它异常): 结束迭代并清除错误标记
			interp.report.clear_error()
			interp.last_exception = null
			done = true
			return
		_prefetched = res

## DSL 列表迭代器 (数组)
class DSLListIterator extends DSLIterator:
	## 被迭代的数组
	var items: Array
	## 当前索引位置
	var index: int = 0
	
	## 构造列表迭代器 [br]
	## [param p] 被迭代的数组
	func _init(p):
		items = p
	
	func has_next() -> bool:
		return index < items.size()
	
	func next() -> DSLObject:
		var res = items[index]
		index += 1
		return res

## DSLDict 键迭代器 [br]
## 迭代字典的键, 并将 Variant 键自动包装为 DSLObject
class DSLDictKeyIterator extends DSLIterator:
	## 被迭代的字典
	var dict: Dictionary
	## 键数
	var keys: Array
	## 当前索引位置
	var index: int = 0
	
	## 构造字典键迭代器 [br]
	## [param p_dict] 被迭代的字典
	func _init(p_dict):
		dict = p_dict
		keys = dict.keys()
	
	func has_next() -> bool:
		return index < keys.size()
	
	## 获取下一个键 [br]
	## [returns] 包装为 DSLObject 的键
	func next() -> DSLObject:
		var raw = keys[index]
		index += 1
		if typeof(raw) == TYPE_STRING:
			return DSLString.new(raw)
		if typeof(raw) == TYPE_INT:
			return DSLInteger.new(raw)
		if typeof(raw) == TYPE_FLOAT:
			return DSLFloat.new(raw)
		if typeof(raw) == TYPE_BOOL:
			return DSLBool.new(raw)
		return DSLNone.new()

## DSLString 迭代器 (逐字符迭代)
class DSLStringIterator extends DSLIterator:
	## 被迭代的字符
	var value: String
	## 当前索引位置
	var index: int = 0
	
	## 构造字符串迭代器 [br]
	## [param v] 被迭代的字符串
	func _init(v):
		value = v
	
	func has_next() -> bool:
		return index < value.length()
	
	## 获取下一个字符 [br]
	## [returns] 单个字符 (DSLString)
	func next() -> DSLObject:
		var ch = value[index]
		index += 1
		return DSLString.new(ch)

## 无限迭代器基类: has_next() 恒为 true [br]
## 用于 itertools 的无限序列 (repeat/cycle/count), 需配合 islice/takewhile 惰性消费
class DSLInfiniteIterator extends DSLIterator:
	func has_next() -> bool:
		return true

## 无限重复同一个值 (itertools.repeat(obj))
class DSLRepeatIterator extends DSLInfiniteIterator:
	## 被重复的值
	var value: DSLObject
	## 构造无限重复迭代器 [br]
	## [param v] 被重复的值
	func _init(v):
		value = v
	func next() -> DSLObject:
		return value

## 无限循环序列迭代器 (itertools.cycle(iterable))
class DSLCycleIterator extends DSLInfiniteIterator:
	## 被循环的元素数组
	var items: Array
	## 当前索引
	var index: int = 0
	## 构造循环迭代器 [br]
	## [param it] 元素数组
	func _init(it):
		items = it
	func next() -> DSLObject:
		var res = items[index]
		index = (index + 1) % items.size()
		return res

## 无限递增计数迭代器 (itertools.count(start, step))
class DSLCountIterator extends DSLInfiniteIterator:
	## 当前值
	var current: int
	## 步长
	var step: int
	## 构造计数迭代器 [br]
	## [param s] 起始值 [br]
	## [param st] 步长
	func _init(s, st):
		current = s
		step = st
	func next() -> DSLObject:
		var res = DSLInteger.new(current)
		current += step
		return res

## itertools.repeat 无限对象 (未指定次数时返回, 由 _dsl_iter 惰性产生序列)
class DSLRepeat extends DSLObject:
	## 被重复的值
	var value: DSLObject
	## 构造 repeat 对象 [br]
	## [param v] 被重复的值
	func _init(v):
		value = v
	func _type_name() -> String:
		return "repeat"
	func _dsl_iter() -> DSLIterator:
		return DSLRepeatIterator.new(value)

## itertools.cycle 无限对象
class DSLCycle extends DSLObject:
	## 被循环的元素数组
	var items: Array
	## 构造 cycle 对象 [br]
	## [param it] 元素数组
	func _init(it):
		items = it
	func _type_name() -> String:
		return "cycle"
	func _dsl_iter() -> DSLIterator:
		return DSLCycleIterator.new(items)

## itertools.count 无限对象
class DSLCount extends DSLObject:
	## 起始值
	var start: int
	## 步长
	var step: int
	## 构造 count 对象 [br]
	## [param s] 起始值 [br]
	## [param st] 步长
	func _init(s, st):
		start = s
		step = st
	func _type_name() -> String:
		return "count"
	func _dsl_iter() -> DSLIterator:
		return DSLCountIterator.new(start, step)

## 生成器表达式对象, 对应 Python generator [br]
## 惰性求值: 持有表达式与闭包环境, 通过共享的 DSLGeneratorIterator 逐次产出元素 [br]
## 一次性迭代器: 多次迭代不会从头开始 (与 Python 生成器一致)
class DSLGenerator extends DSLObject:
	## 元素表达式
	var elt_expr
	## 循环子句数组 (实际类型 Array[CompClause]), 支持多 for 与多 if
	var clauses: Array
	## 闭包环境 (创建时的环境)
	var closure
	## 共享的生成器迭代器 (首次访问时创建)
	var _iterator: DSLGeneratorIterator = null

	## 构造生成器对象 [br]
	## [param e] 元素表达式 [br]
	## [param c] 循环子句数组 (实际类型 Array[CompClause]) [br]
	## [param env] 闭包环境 [br]
	## [param ip] 解释器引用
	func _init(e, c: Array, env, ip):
		elt_expr = e
		clauses = c
		closure = env
		interp = ip

	func _type_name() -> String:
		return "generator"

	func _dsl_str() -> String:
		return "<generator object <genexpr>>"

	func _dsl_bool() -> bool:
		return true

	## 返回共享迭代器, 使生成器保持一次性语义
	func _dsl_iter() -> DSLIterator:
		if _iterator == null:
			_iterator = DSLGeneratorIterator.new(self)
		return _iterator

## 生成器表达式迭代器: 每次 next() 推进一次推导式循环 [br]
## 惰性求值迭代源, 循环状态 (源迭代器/变量绑定/是否耗尽) 保存在字段中
class DSLGeneratorIterator extends DSLIterator:
	## 所属生成器
	var gen
	## 循环帧栈, 每帧对应一个子句 (键: clause/iterator/phase/bound/saved/cond_idx)
	var _frames: Array = []
	## 是否已初始化首个子句的迭代器
	var _started: bool = false

	## 构造生成器迭代器 [br]
	## [param g] 所属生成器
	func _init(g):
		gen = g
		once = true

	func has_next() -> bool:
		_begin_use(gen.interp)
		if _read_pos < _log.size():
			suspended = false
			return true
		if done:
			return false
		var v = _walk_next()
		if suspended:
			_propagate_suspend(gen.interp)
			return false
		if v == null:
			done = true
			return false
		_log.append(v)
		return true

	func next() -> DSLObject:
		_begin_use(gen.interp)
		if _read_pos < _log.size():
			var buffered = _log[_read_pos]
			_read_pos += 1
			suspended = false
			return buffered
		if done:
			return null
		var v = _walk_next()
		if suspended:
			_propagate_suspend(gen.interp)
			return null
		if v == null:
			done = true
			return null
		_log.append(v)
		_read_pos += 1
		return v

	## 推进推导式一轮并返回产出的元素 (不移动读取游标; 挂起时置 suspended) [br]
	## [returns] 产出的值; 耗尽返回 null; 挂起时返回 null 且 suspended 为 true
	func _walk_next() -> DSLObject:
		suspended = false
		var v = _advance()
		if suspended:
			return null
		return v

	## 为指定子句创建迭代器并压入帧栈 [br]
	## 迭代对象在闭包环境中惰性求值; 求值过程若挂起 (sleep), 置 suspended 并返回 false [br]
	## [param idx] 子句下标 [br]
	## [returns] 成功返回 true
	func _push_frame(idx: int) -> bool:
		var interp = gen.interp
		var clause = gen.clauses[idx]
		var it = null
		var prev_env = interp.environment
		interp.environment = gen.closure
		var iterable_val = interp.evaluate(clause.iterable)
		interp.environment = prev_env
		if interp._suspended:
			suspended = true
			return false
		if iterable_val == null:
			return false
		# 挂起可能发生在内层消费 (如元素为生成器函数调用): 重新求值时复用已保存的迭代器
		var frame_state = null
		for fs in _frames:
			if fs.get("pending_idx", -1) == idx:
				frame_state = fs
				break
		if frame_state != null and frame_state.get("iter", null) != null:
			it = frame_state.iter
		else:
			it = iterable_val._dsl_iter()
			if it == null:
				interp.raise_exception_from_last_error(iterable_val.last_error if iterable_val.last_error != "" else "TypeError: object is not iterable")
				return false
		# 本迭代器是生成器表达式内部状态的一部分: 其进度由帧栈保存,
		# 外层语句重放时不得回退它的读取游标 (否则同一元素会被重复产出)
		it.windowed = false
		_frames.append({"clause": clause, "iterator": it, "bound": false, "saved": [], "phase": "start", "cond_idx": 0})
		return true

	## 推进嵌套循环并返回下一个满足条件的元素, 耗尽或出错时返回 null [br]
	## 支持挂起恢复: 子句迭代器/循环变量绑定/条件进度都保存在帧栈中, [br]
	## 挂起后重新进入时从上次阶段继续 (不重复绑定, 也不跳过元素)
	func _advance() -> DSLObject:
		var interp = gen.interp
		if not _started:
			_started = true
			if not _push_frame(0):
				return null
		while _frames.size() > 0:
			if interp.report.has_error:
				return null
			var top = _frames.back()
			# 阶段 init: 取下一个元素并绑定循环变量
			if top["phase"] == "init":
				var it0 = top["iterator"]
				if not it0.has_next():
					if it0.suspended:
						suspended = true
						return null
					it0.suspended = false
					_frames.pop_back()
					continue
				var item0 = it0.next()
				if interp._suspended:
					suspended = true
					return null
				var saved0 = interp._bind_comp_targets(top["clause"].targets, item0, gen.closure)
				if interp._suspended:
					suspended = true
					return null
				if saved0 == null:
					return null
				top["saved"] = saved0
				top["bound"] = true
				top["cond_idx"] = 0
				top["phase"] = "cond"
				continue
			# 阶段 emit: 上一轮元素求值被挂起, 本次重新求值同一元素
			if top["phase"] == "emit":
				top["phase"] = "cond"
				continue
			# 阶段 cond: 依次求值当前帧的条件
			if top["phase"] == "cond":
				var conds = top["clause"].conditions
				var cond_ok = true
				while top["cond_idx"] < conds.size():
					var prev_env = interp.environment
					interp.environment = gen.closure
					var cond_result = interp.evaluate(conds[top["cond_idx"]])
					interp.environment = prev_env
					if interp._suspended:
						suspended = true
						return null
					if cond_result == null:
						return null
					if not cond_result._dsl_bool():
						cond_ok = false
						break
					top["cond_idx"] = int(top["cond_idx"]) + 1
				if not cond_ok:
					_finish_frame(top)
					continue
				# 条件通过: 尚有未展开的子句则进入下一层 (子帧耗尽后回到本帧的 sub 阶段)
				if _frames.size() < gen.clauses.size():
					top["phase"] = "sub"
					var sub_idx = _frames.size()
					if not _push_frame(sub_idx):
						if suspended:
							return null
						return null
					continue
				# 最内层: 求值元素表达式并产出
				# 阶段保持 emit 直到求值成功, 使挂起重入时对同一元素重新求值 (绑定未变)
				top["phase"] = "emit"
				var prev_env_e = interp.environment
				interp.environment = gen.closure
				var element = interp.evaluate(gen.elt_expr)
				interp.environment = prev_env_e
				if interp._suspended:
					suspended = true
					return null
				if element == null:
					return null
				top["phase"] = "finish"
				return element
			# 阶段 sub: 子帧已耗尽并弹出, 本帧继续取下一个元素
			if top["phase"] == "sub":
				_finish_frame(top)
				continue
			# 阶段 finish: 上一轮元素已产出, 本帧继续取下一个元素
			if top["phase"] == "finish":
				_finish_frame(top)
				continue
			# 未知阶段 (不应发生): 复位到 init 以免死循环
			top["phase"] = "init"
		return null

	## 结束当前帧的本次迭代: 恢复循环变量绑定并回到 init 阶段 [br]
	## [param top] 帧栈顶帧
	func _finish_frame(top) -> void:
		var interp = gen.interp
		if top["bound"]:
			interp._restore_comp_bindings(gen.closure, top["saved"])
			top["bound"] = false
			top["saved"] = []
		top["cond_idx"] = 0
		top["phase"] = "init"


## 生成器函数迭代器: 每次 next() 驱动生成器函数体推进一个 yield [br]
## 预取缓冲保证 has_next() 准确; 一次性迭代语义 (与 Python 生成器一致) [br]
## 与 DSLGeneratorIterator 不同: 其推进逻辑委托给 DSLFunctionGenerator._step 的栈切换机制
class DSLFunctionGeneratorIterator extends DSLIterator:
	## 所属生成器
	var gen: DSLFunctionGenerator = null

	## 构造生成器迭代器 [br]
	## [param g] 所属生成器
	func _init(g: DSLFunctionGenerator):
		gen = g
		once = true

	func has_next() -> bool:
		_begin_use(gen.interp)
		if _read_pos < _log.size():
			return true
		if done:
			return false
		var v = _produce()
		if suspended:
			_propagate_suspend(gen.interp)
			return false
		return v != null

	func next() -> DSLObject:
		_begin_use(gen.interp)
		if _read_pos < _log.size():
			var buffered = _log[_read_pos]
			_read_pos += 1
			if _read_pos > _hi_pos:
				_hi_pos = _read_pos
			return buffered
		if done:
			return null
		var v = _produce()
		if suspended:
			_propagate_suspend(gen.interp)
			return null
		if v == null:
			return null
		_read_pos += 1
		if _read_pos > _hi_pos:
			_hi_pos = _read_pos
		return v

	## 推进一步生成器: 产出值记入日志; 挂起时置 suspended 由消费方传播 [br]
	## [returns] 产出的值, 结束/挂起/出错时返回 null
	func _produce() -> DSLObject:
		suspended = false
		if done:
			return null
		var res = gen._step()
		if gen._stepped_suspended:
			gen._stepped_suspended = false
			suspended = true
			return null
		if res == 1:
			_log.append(gen._yielded_value)
			return gen._yielded_value
		done = true
		return null

	## 使读取游标与缓冲失效 (send/throw/close 直接驱动生成器后调用)
	func _invalidate() -> void:
		pass

## 生成器函数对象, 对应 def 中含 yield 的函数调用结果 (Python generator) [br]
## 调用时不执行函数体, 立即返回本对象; 持有函数声明/闭包与参数绑定后的局部环境, [br]
## 以及挂起时保存的解释器执行状态 (栈切换机制见 _step) [br]
## 对外表现与 DSLGenerator (生成器表达式) 一致: _type_name 为 "generator", 一次性迭代
class DSLFunctionGenerator extends DSLObject:
	## 生成器函数对象 (持有声明与闭包)
	var function: DSLFunction = null
	## 参数绑定后的局部环境 (跨 yield 保持)
	var local_env: DSLEnvironment = null
	## 实际执行的函数体语句 (首次启动带注入抛出语句时不同于 func.declaration.body)
	var body: Array = []
	## 挂起时保存的解释器执行栈 (_exec_stack 的副本引用)
	var exec_stack: Array = []
	## 挂起时保存的解释器函数调用栈
	var call_stack: Array = []
	## 挂起时保存的方法上下文 (super() 定位)
	var cur_class = null
	## 挂起时保存的 self/cls 上下文
	var cur_self = null
	## 是否已启动 (首次 step 后为 true)
	var _started: bool = false
	## 是否已结束 (耗尽/return/异常后为 true)
	var _finished: bool = false
	## 是否挂起在 yield 上
	var _suspended: bool = false
	## 当前语句重执行时的 yield 位置计数 (每条语句开始时重置为 0)
	var _yield_pos: int = 0
	## 挂起的 yield 位置 (1-based, 0 表示无待注入)
	var _pending_yield_index: int = 0
	## 待注入的 send 值 (next() 注入 None)
	var _send_value: DSLObject = null
	## 待注入的抛出异常标记 (throw/close)
	var _throw_pending: bool = false
	## 待注入的异常对象
	var _throw_value = null
	## yield from 的子迭代器状态列表, 每项 {"expr": YieldExpr, "iter": DSLIterator, "val": DSLObject}
	var _yield_from_states: Array = []
	## 最近一次 yield 产出的值
	var _yielded_value: DSLObject = null
	## return 值 (StopIteration.value)
	var _result_value: DSLObject = null
	## 共享迭代器 (一次性语义)
	var _iterator: DSLFunctionGeneratorIterator = null
	## 生成器名称 (repr 用)
	var _name: String = "<genexpr>"
	## 最近一次 _step 是否因程序挂起 (sleep) 中断 (由迭代器读取并转为 suspended)
	var _stepped_suspended: bool = false
	## 跨 yield 重放的子表达式值记忆: 上一轮 (挂起前) 已求值的子表达式 [br]
	## 语句因 yield 挂起后会被重新执行, 若不加记忆, 挂起点之前的子表达式 [br]
	## (如 f(a(), (yield 1)) 中的 a()) 会重复求值, 导致副作用执行两次 [br]
	## 键为 "<节点 id>#<序号>", 值为按求值顺序排列的数组
	var _yv_prev: Dictionary = {}
	## 本轮 (重放轮) 新求值的子表达式
	var _yv_curr: Dictionary = {}
	## 本轮各键的出现计数
	var _yv_occ: Dictionary = {}
	## 本轮是否为 yield 重放轮 (为真时读取 _yv_prev)
	var _yv_replay: bool = false

	## 构造生成器对象 [br]
	## [param p_interp] 解释器引用 [br]
	## [param p_func] 生成器函数对象 [br]
	## [param p_env] 参数绑定后的局部环境
	func _init(p_interp: Interpreter, p_func: DSLFunction, p_env: DSLEnvironment):
		super._init()
		interp = p_interp
		function = p_func
		local_env = p_env
		body = p_func.declaration.body
		_name = p_func.declaration.name
		_result_value = _none()

	func _type_name() -> String:
		return "generator"

	func _dsl_str() -> String:
		return "<generator object %s>" % _name

	func _dsl_bool() -> bool:
		return true

	func magic_repr(_args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLObject:
		return DSLString.new("<generator object %s>" % _name)

	## 返回共享迭代器, 使生成器保持一次性语义
	func _dsl_iter() -> DSLIterator:
		if _iterator == null:
			_iterator = DSLFunctionGeneratorIterator.new(self)
		return _iterator

	## 生成器协议方法 (send/throw/close/__next__) 的属性访问 [br]
	## [param name] 属性名 [br]
	## [returns] DSLBuiltinFunction 包装或委托给基类
	func _dsl_getattribute(name: String) -> DSLObject:
		if name == "send":
			return DSLBuiltinFunction.new(name, Callable(self, "_dsl_send"))
		if name == "throw":
			return DSLBuiltinFunction.new(name, Callable(self, "_dsl_throw"))
		if name == "close":
			return DSLBuiltinFunction.new(name, Callable(self, "_dsl_close"))
		if name == "__next__":
			return DSLBuiltinFunction.new(name, Callable(self, "_dsl_next"))
		return super._dsl_getattribute(name)

	## 使预取缓冲失效 (send/throw/close 绕过迭代器直接驱动后调用)
	func _invalidate_iter() -> void:
		if _iterator != null:
			_iterator._invalidate()

	## 驱动生成器执行一步 [br]
	## 通过栈切换: 保存解释器的 environment/_exec_stack/_call_stack/_current_class/_current_self, [br]
	## 换上本生成器的挂起状态, 恢复执行函数体, 再换回调用方状态 [br]
	## [returns] 1=产出一个值 (存于 _yielded_value), 2=正常结束 (return 值存于 _result_value), 3=异常结束
	func _step() -> int:
		if _finished:
			return 2
		var ip = interp
		# 保存解释器当前状态 (调用方)
		var caller_env = ip.environment
		var caller_exec = ip._exec_stack
		var caller_call = ip._call_stack
		var caller_class = ip._current_class
		var caller_self = ip._current_self
		var caller_suspended = ip._suspended
		var caller_waiting = ip._is_waiting
		var caller_reason = ip._suspend_reason
		var caller_expr_eval = ip._expr_evaluated
		var caller_gen = ip._current_generator
		# 首次启动且带注入异常 (throw 到未启动生成器): 在函数体开头注入抛出语句
		if not _started and _throw_pending:
			_started = true
			var injected: Array = [RaiseStmt.new(Literal.new(_throw_value))]
			injected.append_array(function.declaration.body)
			body = injected
			_throw_pending = false
			_throw_value = null
		# 换上生成器状态
		ip.environment = local_env
		ip._exec_stack = exec_stack
		ip._call_stack = call_stack
		ip._current_class = cur_class
		ip._current_self = cur_self
		ip._suspended = false
		ip._is_waiting = false
		ip._suspend_reason = Interpreter.SuspendReason.NONE
		ip._expr_evaluated = false
		ip._current_generator = self
		# 恢复执行函数体 (帧查找按 statements/env 身份匹配)
		var res = ip.exec_block(body, local_env)
		# 处理执行结果
		var step_result = 1
		if res == Interpreter.ExecResult.NORMAL:
			_finished = true
			_result_value = _none()
			step_result = 2
		elif res == Interpreter.ExecResult.RETURN:
			_finished = true
			_result_value = ip.return_value if ip.return_value != null else _none()
			step_result = 2
		elif res == Interpreter.ExecResult.RAISE or res == Interpreter.ExecResult.ERROR:
			_finished = true
			step_result = 3
		elif res == Interpreter.ExecResult.SUSPENDED:
			if ip._suspend_reason != Interpreter.SuspendReason.YIELD:
				# 生成器体内发起程序挂起 (time.sleep): 暂停本步, 交由消费方传播
				_stepped_suspended = true
				step_result = 4
			else:
				_suspended = true
				step_result = 1
		# 保存生成器状态
		exec_stack = ip._exec_stack
		call_stack = ip._call_stack
		cur_class = ip._current_class
		cur_self = ip._current_self
		_suspended = ip._suspended
		_started = true
		# 换回调用方状态
		ip.environment = caller_env
		ip._exec_stack = caller_exec
		ip._call_stack = caller_call
		ip._current_class = caller_class
		ip._current_self = caller_self
		if step_result == 4:
			# 生成器体内发起程序挂起: 保留挂起标志与原因, 让上层语句/消费方继续传播
			ip._suspended = true
			ip._is_waiting = caller_waiting
			ip._suspend_reason = caller_reason
		else:
			ip._suspended = caller_suspended
			ip._is_waiting = caller_waiting
			ip._suspend_reason = caller_reason
		ip._expr_evaluated = caller_expr_eval
		ip._current_generator = caller_gen
		return step_result

	## 每条语句开始时准备子表达式记忆 [br]
	## 若本次进入是 yield 重放 (存在待注入的挂起位置), 则本轮读取上一轮的值 [br]
	## 否则视为新一轮, 清空记忆重新记录
	func _yv_begin_stmt() -> void:
		_yv_occ.clear()
		# 仅「因 yield 挂起而重放」的这一轮才读取记忆: [br]
		# 该标记由 exec_block 在判定重放时显式置位, 避免 sleep 重放误用旧值
		if _pending_yield_index > 0:
			# 该语句正在重放 (待注入挂起的 yield): 读取上一轮记录的值
			_yv_replay = true
			_yv_curr.clear()
		else:
			_yv_replay = false
			_yv_prev.clear()

	## 语句挂起前保存本轮记忆, 供重放轮复用
	func _yv_commit() -> void:
		if not _yv_replay:
			_yv_prev = _yv_curr.duplicate()
			# 标记已提交: 同一次挂起会被沿途每一层 exec_block 看到并重复调用,
			# 若重复提交会把刚保存的 _yv_prev 覆盖为空 (第二轮起记忆失效)
			_yv_replay = true
		_yv_curr.clear()

	## 查询/记录子表达式的值 [br]
	## 重放轮命中上一轮记录时返回其值 (不重复求值), 未命中则调用 producer 求值并记录 [br]
	## [param node] 子表达式节点 [br]
	## [param slot] 序号 (同一节点在一轮内多处出现时区分) [br]
	## [param producer] 求值回调 [br]
	## [returns] 子表达式的值
	func _yv_memo(node, slot: int, producer: Callable) -> DSLObject:
		if node == null:
			return producer.call()
		# 首轮执行时记录 (供后续 yield 重放复用); 重放轮则优先取回记录 [br]
		# sleep 重放由语句级消费窗口负责, 与这里的 yield 记忆互不干扰:
		# 本函数的记忆只在「当前语句含 yield 且正在执行」时才有内容
		var key = str(node.get_instance_id()) + "#" + str(slot)
		var occ = int(_yv_occ.get(key, 0))
		_yv_occ[key] = occ + 1
		# 重放判定以生成器自身的挂起位置为准 (比外部标志更可靠, 不会被跨语句残留污染)
		if _yv_replay or _pending_yield_index > 0:
			var plst: Array = _yv_prev.get(key, [])
			if occ < plst.size():
				return plst[occ]
		var value = producer.call()
		if value == null:
			# 求值中被挂起 (或出错): 不能把占位 null 记入记忆,
			# 否则重放轮会把它当作已求值结果, 使该子表达式被跳过
			return null
		var clst: Array = _yv_curr.get(key, [])
		clst.append(value)
		_yv_curr[key] = clst
		return value

	## 取缓存的 None 单例 (保证 `is None` 身份语义) [br]
	## 直接 DSLNone.new() 会创建新实例, 使 `x is None` 误判为假 [br]
	## [returns] DSLNone 单例
	func _none() -> DSLObject:
		if interp == null:
			return DSLNone.new()
		return interp.get_none()

	## 取走待注入的 send 值 (未设置时为 None) [br]
	## [returns] 注入值
	func _take_send_value() -> DSLObject:
		var sv = _send_value
		_send_value = null
		if sv == null:
			sv = _none()
		return sv

	## 生成器方法: send(value) [br]
	## 恢复执行并把 value 注入为挂起 yield 表达式的结果 (next() 注入 None) [br]
	## [param args] [value] [br]
	## [param _kwargs] 关键字参数 (未使用) [br]
	## [returns] 产出的值, 结束/出错时返回 null (异常由解释器记录)
	func _dsl_send(args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLObject:
		if args.size() != 1:
			interp.raise_exception("TypeError", "send() takes exactly one argument (%d given)" % args.size())
			return null
		var value = args[0]
		if not _started and not (value is DSLNone):
			interp.raise_exception("TypeError", "can't send non-None value to a just-started generator")
			return null
		if _finished:
			interp.raise_stop_iteration_value(_result_value)
			return null
		_invalidate_iter()
		_send_value = value
		var res = _step()
		if res == 1:
			return _yielded_value
		if res == 3:
			return null
		interp.raise_stop_iteration_value(_result_value)
		return null

	## 生成器方法: throw(type[, value]) [br]
	## 在挂起位置抛出异常; 未启动生成器在函数体开头抛出 [br]
	## [param args] [type, value?] 或 [实例] [br]
	## [param _kwargs] 关键字参数 (未使用) [br]
	## [returns] 产出的值, 结束/出错时返回 null
	func _dsl_throw(args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLObject:
		if _finished:
			interp.raise_stop_iteration_value(_result_value)
			return null
		var exc = _throw_arg_to_exception(args)
		if exc == null:
			return null
		_invalidate_iter()
		_throw_pending = true
		_throw_value = exc
		var res = _step()
		if res == 1:
			return _yielded_value
		if res == 3:
			return null
		interp.raise_stop_iteration_value(_result_value)
		return null

	## 生成器方法: close() [br]
	## 在挂起位置注入 GeneratorExit; 生成器捕获并继续产出时抛 RuntimeError [br]
	## [param args] 无 [br]
	## [param _kwargs] 关键字参数 (未使用) [br]
	## [returns] DSLNone
	func _dsl_close(args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLObject:
		if _finished:
			return _none()
		if not _started:
			_finished = true
			return _none()
		var exc_class = interp.globals.get_val_safe("GeneratorExit")
		var exc = null
		if exc_class is DSLClass:
			exc = exc_class.magic_call([], {})
		else:
			exc = DSLException.new("", "GeneratorExit")
		_invalidate_iter()
		_throw_pending = true
		_throw_value = exc
		var res = _step()
		if res == 1:
			# 生成器捕获了 GeneratorExit 并继续产出
			_finished = true
			interp.raise_exception("RuntimeError", "generator ignored GeneratorExit")
			return null
		# 结束或异常: GeneratorExit 静默 (close 成功), 其他异常原样传播
		if interp.last_exception != null and interp.last_exception._type_name() == "GeneratorExit":
			interp.report.clear_error()
			interp.last_exception = null
		return _none()

	## 生成器方法: __next__() [br]
	## 与 next(g) 等价, 直接驱动一步 [br]
	## [param args] 无 [br]
	## [param _kwargs] 关键字参数 (未使用) [br]
	## [returns] 产出的值
	func _dsl_next(args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLObject:
		if _finished:
			interp.raise_stop_iteration_value(_result_value)
			return null
		_invalidate_iter()
		var res = _step()
		if res == 1:
			return _yielded_value
		if res == 3:
			return null
		interp.raise_stop_iteration_value(_result_value)
		return null

	## 将 throw 参数转换为异常实例 [br]
	## 支持 throw(类型), throw(类型, 值), throw(实例) [br]
	## [param args] 方法参数 [br]
	## [returns] 异常实例, 出错时返回 null
	func _throw_arg_to_exception(args: Array[DSLObject]):
		if args.size() == 0:
			interp.raise_exception("TypeError", "throw() takes at least 1 argument (0 given)")
			return null
		var first = args[0]
		if first is DSLClass:
			var ctor_args: Array[DSLObject] = []
			if args.size() >= 2:
				ctor_args.append(args[1])
			var inst = first.magic_call(ctor_args, {})
			if inst == null or interp.report.has_error:
				return null
			return inst
		if first is DSLException:
			return first
		if first.fields != null:
			var exc_type = interp.globals.get_val_safe("Exception")
			if exc_type is DSLClass and first._is_subclass_of_klass(exc_type):
				return first
		interp.raise_exception("TypeError", "thrown value is not an exception")
		return null

## 变量作用域环境, 管理变量的定义, 读写和作用域链 [br]
## 支持 global/nonlocal 声明, 通过 enclosing 链实现嵌套作用域
class DSLEnvironment:
	## 控制台报告器
	var report: ConsoleReport
	## 变量名到 DSLObject 的映射表
	var values: Dictionary[String, DSLObject] = {}
	## 外层作用域环境 (null 表示全局作用域)
	var enclosing: DSLEnvironment = null
	## global 声明的变量名列表
	var global_vars: Array[String] = []
	## nonlocal 绑定表: 变量名 -> 目标 Environment
	var nonlocal_bindings: Dictionary[String, DSLEnvironment] = {}
	
	## 构造作用域环境 [br]
	## [param p_reporter] 错误报告器实例 [br]
	## [param p_enclosing] 外层作用域环境 (null 表示全局作用域)
	func _init(p_reporter: ConsoleReport, p_enclosing = null):
		report = p_reporter
		enclosing = p_enclosing
	
	## 在当前作用域定义变量 (直接写入当前环境) [br]
	## [param name] 变量名 [br]
	## [param value] 变量值 (DSLObject 实例)
	func define(name: String, value: DSLObject):
		values[name] = value
	
	## 读取变量值, 遵循作用域链从内向外查找 [br]
	## 优先检查 nonlocal 绑定, 其次检查当前环境, 最后查找外层环境 [br]
	## [param name] 变量名 [br]
	## [returns] 变量对应的 DSLObject 值, 未找到时返回 null 并报错
	func get_val(name: String) -> DSLObject:
		if nonlocal_bindings.has(name):
			return nonlocal_bindings[name].get_val(name)
		if values.has(name):
			return values[name]
		if enclosing:
			return enclosing.get_val(name)
		report.error("NameError: name '%s' is not defined" % name)
		return null
	
	## 读取变量值, 遵循作用域链从内向外查找 [br]
	## 优先检查 nonlocal 绑定, 其次检查当前环境, 最后查找外层环境 [br]
	## [param name] 变量名 [br]
	## [returns] 变量对应的 DSLObject 值, 未找到时返回 null, 不同于 [method DSLEnvironment.get_val] 的是其不会报错
	func get_val_safe(name: String) -> DSLObject:
		if nonlocal_bindings.has(name):
			return nonlocal_bindings[name].get_val_safe(name)
		if values.has(name):
			return values[name]
		if enclosing:
			return enclosing.get_val_safe(name)
		return null
	
	## 检查变量是否已在作用域链中定义 [br]
	## 搜索顺序: nonlocal 绑定 -> 当前环境 -> 外层环境 [br]
	## [param name] 变量名 [br]
	## [returns] 如果变量已在作用域链中定义则返回 true
	func has_val(name: String) -> bool:
		if nonlocal_bindings.has(name):
			return nonlocal_bindings[name].has_val(name)
		if values.has(name):
			return true
		if enclosing:
			return enclosing.has_val(name)
		return false
	
	## 设置变量值, 遵循作用域链和 global/nonlocal 声明 [br]
	## 优先检查 nonlocal 绑定 (重定向到目标环境), 其次检查 global 声明 (写入全局环境), [br]
	## 再次检查当前环境是否已有该变量 (更新), 否则在当前环境创建局部变量 [br]
	## [param name] 变量名 [br]
	## [param value] 新的变量值 (DSLObject 实例)
	func set_val(name: String, value: DSLObject):
		if nonlocal_bindings.has(name):
			nonlocal_bindings[name].set_val(name, value)
			return
		if global_vars.has(name):
			var env = self
			while env.enclosing:
				env = env.enclosing
			env.values[name] = value
			return
		if values.has(name):
			values[name] = value
		else:
			# create local
			# 在当前环境创建局部变量
			values[name] = value
	
	## 删除指定名称的变量, 沿作用域链向上查找 [br]
	## 对应 Python 的 del 语句: 先查 nonlocal 绑定, 再查当前作用域, [br]
	## 最后向上委托给外层作用域, 若全部未找到则报 NameError [br]
	## [param name] 要删除的变量名
	func delete(name: String):
		if nonlocal_bindings.has(name):
			nonlocal_bindings[name].delete(name)
			return
		if values.has(name):
			values.erase(name)
			return
		if enclosing:
			enclosing.delete(name)
			return
		report.error("NameError: name '%s' is not defined" % name)
			
	## 将变量标记为 global (全局作用域变量) [br]
	## 后续对该变量的读写将直接操作全局作用域 [br]
	## [param name] 变量名
	func mark_global(name: String):
		global_vars.append(name)
		if values.has(name):
			values.erase(name)
		
	## 将变量标记为 nonlocal (非局部变量) [br]
	## 后续对该变量的读写将重定向到指定的目标外层环境 [br]
	## [param name] 变量名 [br]
	## [param target_env] 目标外层环境 (DSLEnvironment 实例)
	func mark_nonlocal(name: String, target_env):
		nonlocal_bindings[name] = target_env
		if values.has(name):
			values.erase(name)

## 递归下降语法分析器, 将 Token 序列转换为 AST [br]
## 采用经典的递归下降解析策略, 每个非终结符对应一个解析函数 [br]
## 支持完整的 Python 风格语法: 函数/类定义, 控制流, 表达式, 推导式, 解包等
class Parser:
	## 控制台报告器
	var report: ConsoleReport
	## 待解析的 Token 列表
	var tokens: Array
	## 当前处理的 Token 索引
	var current: int = 0
	
	## 构造解析器实例 [br]
	## [param p_reporter] 控制台报告器实例, 用于输出语法错误 [br]
	## [param p_tokens] 需要解析的 Token 列表
	func _init(p_reporter: ConsoleReport, p_tokens: Array):
		report = p_reporter
		tokens = p_tokens
	
	## 开始解析, 返回由语句节点组成的 AST 数组 [br]
	## 循环解析顶层声明直到 Token 流末尾或发生错误 [br]
	## [returns] 解析完成的语句节点数组 (实际类型 Array[Stmt/Expr])
	func parse() -> Array:
		var statements = []
		while not is_at_end() and not report.has_error:
			var stmt = declaration()
			if stmt != null:
				statements.append(stmt)
		if not report.has_error:
			_walk_yield_stmt(statements, 0)
		return statements
		
	## 检查是否已到达 Token 流末尾 [br]
	## [returns] 当前 Token 为 EOF 时返回 true
	func is_at_end() -> bool:
		return peek().type == TokenType.EOF
	
	## 返回当前 Token (但不消费它) [br]
	## [returns] 当前位置的 Token 对象
	func peek() -> Token:
		return tokens[current]
	
	## 返回上一个已消费的 Token [br]
	## [returns] 上一个被 advance() 消费的 Token 对象
	func previous() -> Token:
		return tokens[current - 1]
		
	## 前进到下一个 Token 并返回它 [br]
	## 若已到达 Token 流末尾, 报错并返回当前 EOF Token [br]
	## [returns] 消费后的 Token (即之前的下一个 Token)
	func advance() -> Token:
		if is_at_end():
			report.error("Unexpected end of file")
			return peek()
		current += 1
		return previous()
	
	## 检查当前 Token 是否为指定类型 (不消费 Token) [br]
	## [param type] 期望的 TokenType 枚举值 [br]
	## [returns] 当前 Token 类型匹配时返回 true
	func check(type: TokenType) -> bool:
		return (not is_at_end()) and peek().type == type
	
	## 尝试匹配一组 Token 类型中的任意一个 [br]
	## 若匹配成功则消费 Token 并返回 true, 否则仅返回 false [br]
	## [param types] 待匹配的 TokenType 数组 [br]
	## [returns] 匹配成功时返回 true
	func match_types(types: Array) -> bool:
		for t in types:
			if check(t):
				advance()
				return true
		return false
	
	## 断言当前 Token 为指定类型, 否则报错 [br]
	## 匹配成功时消费并返回该 Token, 失败时返回 null [br]
	## [param type] 期望的 TokenType 枚举值 [br]
	## [param error_msg] 匹配失败时的错误信息 [br]
	## [returns] 消费的 Token, 失败时返回 null
	func consume(type: int, error_msg: String) -> Token:
		if check(type):
			return advance()
		report.error("Line %d, Column %d: %s" % [peek().line, peek().column, error_msg])
		return null
	
	## 跳过连续的换行 Token (NEWLINE) [br]
	## Python 风格的解析中, 换行作为语句分隔符, 需要被跳过
	func skip_newlines():
		while match_types([TokenType.NEWLINE]):
			pass
	
	## 解析一条顶层语句 (定义, 声明, 控制流或表达式) [br]
	## 记录语句起始行号 (运行时错误定位), 再分发到具体解析函数 [br]
	## [returns] 解析出的 Stmt 或 Expr 节点, 末尾或出错时返回 null
	func declaration():
		skip_newlines()
		if is_at_end():
			return null
		var start_line = peek().line
		var result = declaration_impl()
		if result is Stmt:
			result.line = start_line
		return result

	## 语句解析分发函数 [br]
	## 根据当前 Token 类型匹配对应的语法结构 [br]
	## [returns] 解析出的 Stmt 节点, 出错时返回 null
	func declaration_impl():
		if match_types([TokenType.AT]):
			return decorated_declaration()
		if match_types([TokenType.DEF]):
			return function_declaration()
		if match_types([TokenType.CLASS]):
			return class_declaration()
		if match_types([TokenType.RETURN]):
			return return_statement()
		if match_types([TokenType.BREAK]):
			return BreakStmt.new()
		if match_types([TokenType.CONTINUE]):
			return ContinueStmt.new()
		if match_types([TokenType.ASSERT]):
			return assert_statement()
		if match_types([TokenType.PASS]):
			return pass_statement()
		if match_types([TokenType.GLOBAL]):
			return global_statement()
		if match_types([TokenType.NONLOCAL]):
			return nonlocal_statement()
		if match_types([TokenType.IMPORT]):
			return import_statement()
		if match_types([TokenType.FROM]):
			return from_statement()
		if match_types([TokenType.DEL]):
			return del_statement()
		if match_types([TokenType.IF]):
			return if_statement()
		if match_types([TokenType.WHILE]):
			return while_statement()
		if match_types([TokenType.FOR]):
			return for_statement()
		if match_types([TokenType.TRY]):
			return try_statement()
		if match_types([TokenType.RAISE]):
			return raise_statement()
		if match_types([TokenType.ASYNC]):
			return async_declaration()
		return expression_statement()
		
	## 处理 async 开头的语句 [br]
	## PyGDS 不支持 async/await (按既定范围以挂起系统替代) [br]
	## 此处按 CPython 的语法规则给出 SyntaxError, 而非让 async 落入标识符解析后报 NameError [br]
	## [returns] 始终返回 null (该位置必然报错)
	func async_declaration():
		if check(TokenType.DEF):
			# CPython 中 async def 合法, PyGDS 明确不支持: 给出明确的降级报错
			report.error("SyntaxError: 'async def' is not supported")
			return null
		if check(TokenType.FOR):
			report.error("SyntaxError: 'async for' outside async function")
			return null
		if check(TokenType.IDENTIFIER) and peek().lexeme == "with":
			report.error("SyntaxError: 'async with' outside async function")
			return null
		# async 用作变量名/类型标注等: CPython 报通用语法错误
		report.error("SyntaxError: invalid syntax")
		return null
		
	## 解析带装饰器的声明 (@classmethod / @staticmethod / @property / @name.setter) [br]
	## 装饰器必须紧接在 def 之前, 用于标记方法的类型 [br]
	## [returns] 解析出的 FunctionStmt 节点 (已设置 method_type), 出错时返回 null
	func decorated_declaration():
		var decorator_lexeme = peek().lexeme
		var method_type = 0
		var property_name = ""
		
		if decorator_lexeme == "classmethod":
			method_type = 1
		elif decorator_lexeme == "staticmethod":
			method_type = 2
		elif decorator_lexeme == "property":
			method_type = 3
		else:
			var name_tok = advance()
			if match_types([TokenType.DOT]):
				var attr_tok = consume(TokenType.IDENTIFIER, "Expected 'setter' or 'deleter'")
				if attr_tok == null:
					return null
				if attr_tok.lexeme == "setter":
					method_type = 4
					property_name = name_tok.lexeme
				elif attr_tok.lexeme == "deleter":
					method_type = 5
					property_name = name_tok.lexeme
				else:
					report.error("Unknown decorator: @%s.%s at line %d" % [name_tok.lexeme, attr_tok.lexeme, name_tok.line])
					return null
			else:
				report.error("Unknown decorator: @%s at line %d" % [name_tok.lexeme, name_tok.line])
				return null
		
		if method_type <= 3:
			var name_tok = consume(TokenType.IDENTIFIER, "Expected decorator name")
			if name_tok == null:
				return null
		
		skip_newlines()
		if not match_types([TokenType.DEF]):
			report.error("Decorator must be followed by a function definition")
			return null
		
		var func_stmt = function_declaration()
		if func_stmt == null:
			return null
		func_stmt.method_type = method_type
		if property_name != "":
			func_stmt.set_meta("_property_name", property_name)
		return func_stmt
		
	## 解析函数定义语句 [br]
	## 支持完整的 Python 函数签名: 位置参数, 仅位置参数 (/), *args, 关键字参数 (*), **kwargs, 默认值, 返回类型注解 [br]
	## [returns] 解析出的 FunctionStmt 节点, 出错时返回 null
	func function_declaration():
		var name_tok = consume(TokenType.IDENTIFIER, "Expected function name")
		if name_tok == null:
			return null
		var name = name_tok.lexeme
		
		var lparen = consume(TokenType.LPAREN, "Expected '('")
		if lparen == null:
			return null
		
		var params: Array[Param] = []
		var saw_kwargs = false
		var saw_star = false
		
		if not check(TokenType.RPAREN):
			while true:
				if report.has_error:
					break
				
				# 处理 / 分隔
				if check(TokenType.SLASH):
					advance()
					# 将前面所有普通参数标记为 positional-only
					for p in params:
						if not p.is_args and not p.is_kwargs:
							p.is_positional_only = true
					if not match_types([TokenType.COMMA]):
						break
					continue
					
				# 处理 * 分隔符或 *args
				elif check(TokenType.STAR):
					# 判断是单独的 * 还是 *args
					var next_idx = current + 1
					var is_star_only = false
					if next_idx >= tokens.size():
						is_star_only = true
					else:
						var next_type = tokens[next_idx].type
						if next_type == TokenType.IDENTIFIER or next_type == TokenType.COLON or next_type == TokenType.EQUAL:
							is_star_only = false
						else:
							is_star_only = true
							
					if is_star_only:
						advance()
						saw_star = true
						if not match_types([TokenType.COMMA]):
							break
						continue
					else:
						# *args
						advance()
						var tok = consume(TokenType.IDENTIFIER, "Expected parameter name")
						if tok == null:
							return null
						if match_types([TokenType.COLON]):
							skip_type_annotation()
						params.append(Param.new(tok.lexeme, null, true, false, false, false))
						saw_star = true
						if not match_types([TokenType.COMMA]):
							break
						continue
						
				# 处理 **kwargs
				elif check(TokenType.STARSTAR):
					if saw_kwargs:
						report.error("Multiple **kwargs not allowed")
						return null
					# 消费 **
					advance()
					var tok = consume(TokenType.IDENTIFIER, "Expected parameter name")
					if tok == null:
						return null
					params.append(Param.new(tok.lexeme, null, false, true))
					saw_kwargs = true
					# **kwargs 后不能再有参数
					break
					
				# 普通参数
				else:
					var tok = consume(TokenType.IDENTIFIER, "Expected parameter name")
					if tok == null:
						return null
					var param_name = tok.lexeme
					
					if match_types([TokenType.COLON]):
						skip_type_annotation()
						
					var default_expr = null
					if match_types([TokenType.EQUAL]):
						default_expr = simple_expression()
						if report.has_error:
							return null
						
					# keyword-only 条件: 处于 * 之后且不为 *args
					params.append(Param.new(param_name, default_expr, false, false, false, saw_star))
					
				if not match_types([TokenType.COMMA]):
					break
		
		var rparen = consume(TokenType.RPAREN, "Expected ')'")
		if rparen == null:
			return null
		
		# 可选的返回值类型注解
		if match_types([TokenType.MINUS]):
			if match_types([TokenType.GREATER]):
				skip_type_annotation()
			else:
				report.error("Expected '>' for return type annotation")
				
		var colon = consume(TokenType.COLON, "Expected ':'")
		if colon == null:
			return null
		
		var body = block()
		return FunctionStmt.new(name, params, body)
	
	## 解析类定义语句 [br]
	## 支持可选基类 (括号语法) 和类体块 [br]
	## [returns] 解析出的 ClassStmt 节点, 出错时返回 null
	func class_declaration():
		var name_tok = consume(TokenType.IDENTIFIER, "Expected class name")
		if name_tok == null:
			return null
		var superclass = null
		if match_types([TokenType.LPAREN]):
			# 基类表达式 例如 Foo(Base)
			superclass = primary()
			consume(TokenType.RPAREN, "Expected ')'")
		var colon = consume(TokenType.COLON, "Expected ':'")
		if colon == null:
			return null
		var body = block()
		return ClassStmt.new(name_tok.lexeme, superclass, body)
	
	## 解析 return 语句, 可选的返回值表达式 [br]
	## [returns] 解析出的 ReturnStmt 节点
	func return_statement():
		var value = null
		if not check(TokenType.NEWLINE) and not is_at_end():
			value = tuple_expression()
		skip_newlines()
		return ReturnStmt.new(value)
		
	## 解析 assert 声明语句 [br]
	## [returns] 解析出的 AssertStmt 节点, 出错时返回 null
	func assert_statement():
		var test = simple_expression()
		var message = null
		if match_types([TokenType.COMMA]):
			message = simple_expression()
		skip_newlines()
		return AssertStmt.new(test, message)

	## 解析 pass 声明语句 [br]
	## [returns] 解析出的 PassStmt 节点, 出错时返回 null
	func pass_statement():
		skip_newlines()
		return PassStmt.new()

	## 解析 global 声明语句 [br]
	## [returns] 解析出的 GlobalStmt 节点, 出错时返回 null
	func global_statement():
		var name_tok = consume(TokenType.IDENTIFIER, "Expected variable name")
		if name_tok == null:
			return null
		skip_newlines()
		return GlobalStmt.new(name_tok.lexeme)
		
	## 解析 nonlocal 声明语句 [br]
	## [returns] 解析出的 NonlocalStmt 节点, 出错时返回 null
	func nonlocal_statement():
		var names = []
		var name_tok = consume(TokenType.IDENTIFIER, "Expected variable name")
		if name_tok == null:
			return null
		names.append(name_tok.lexeme)
		while match_types([TokenType.COMMA]):
			name_tok = consume(TokenType.IDENTIFIER, "Expected variable name")
			if name_tok == null:
				return null
			names.append(name_tok.lexeme)
		skip_newlines()
		return NonlocalStmt.new(names)
	
	## 解析 del 声明语句 [br]
	## [returns] 解析出的 DelStmt 节点, 出错时返回 null
	func del_statement():
		var targets: Array[Expr] = []
		while true:
			var target = simple_expression()
			if target == null:
				report.error("Expected target for del statement")
				return null
			if target is WalrusExpr:
				report.error("SyntaxError: cannot delete named expression")
				return null
			targets.append(target)
			if not match_types([TokenType.COMMA]):
				break
		skip_newlines()
		return DelStmt.new(targets)

	## 解析 import 语句: import math / import math as m / import a, b [br]
	## [returns] ImportStmt 节点, 出错时返回 null
	func import_statement():
		var names: Array = []
		while true:
			var mod_tok = consume(TokenType.IDENTIFIER, "Expected module name")
			if mod_tok == null:
				return null
			var alias = ""
			if match_types([TokenType.AS]):
				var alias_tok = consume(TokenType.IDENTIFIER, "Expected alias after 'as'")
				if alias_tok == null:
					return null
				alias = alias_tok.lexeme
			names.append({"name": mod_tok.lexeme, "alias": alias})
			if not match_types([TokenType.COMMA]):
				break
		skip_newlines()
		return ImportStmt.new(names)

	## 解析 from-import 语句: from math import sqrt / from math import sqrt as s, pi / from math import * [br]
	## [returns] FromImportStmt 节点, 出错时返回 null
	func from_statement():
		var mod_tok = consume(TokenType.IDENTIFIER, "Expected module name")
		if mod_tok == null:
			return null
		var module = mod_tok.lexeme
		# 支持点分模块名 from pkg.mod import name (但本解释器模块为扁平注册表)
		while match_types([TokenType.DOT]):
			var sub_tok = consume(TokenType.IDENTIFIER, "Expected module name after '.'")
			if sub_tok == null:
				return null
			module += "." + sub_tok.lexeme
		if not match_types([TokenType.IMPORT]):
			report.error("Expected 'import' in from statement")
			return null
		# 星号导入
		if match_types([TokenType.STAR]):
			skip_newlines()
			return FromImportStmt.new(module, [], true)
		var names: Array = []
		# 可选括号 from math import (sqrt, pi)
		var has_paren = match_types([TokenType.LPAREN])
		while true:
			if report.has_error:
				return null
			if has_paren and check(TokenType.RPAREN):
				break
			var name_tok = consume(TokenType.IDENTIFIER, "Expected name to import")
			if name_tok == null:
				return null
			var alias = ""
			if match_types([TokenType.AS]):
				var alias_tok = consume(TokenType.IDENTIFIER, "Expected alias after 'as'")
				if alias_tok == null:
					return null
				alias = alias_tok.lexeme
			names.append({"name": name_tok.lexeme, "alias": alias})
			if not match_types([TokenType.COMMA]):
				break
		if has_paren:
			consume(TokenType.RPAREN, "Expected ')' after import names")
		skip_newlines()
		return FromImportStmt.new(module, names, false)
		
	## 解析 if/elif/else 条件语句 [br]
	## 支持 elif 链和可选的 else 分支 [br]
	## [returns] 解析出的 IfStmt 节点, 出错时返回 null
	func if_statement():
		var condition = simple_expression()
		if report.has_error:
			return null
		
		var colon = consume(TokenType.COLON, "Expected ':'")
		if colon == null:
			return null
		var then_branch = block()
		if report.has_error:
			return null
		
		var elif_branches = []
		while match_types([TokenType.ELIF]):
			var elif_cond = simple_expression()
			if report.has_error:
				return null
			colon = consume(TokenType.COLON, "Expected ':'")
			if colon == null:
				return null
			elif_branches.append([elif_cond, block()])
			if report.has_error:
				return null
				
		var else_branch = []
		if match_types([TokenType.ELSE]):
			colon = consume(TokenType.COLON, "Expected ':'")
			if colon == null:
				return null
			else_branch = block()
			if report.has_error:
				return null
			
		return IfStmt.new(condition, then_branch, elif_branches, else_branch)
		
	## 解析 while 循环语句 [br]
	## [returns] 解析出的 WhileStmt 节点, 出错时返回 null
	func while_statement():
		var condition = simple_expression()
		if report.has_error:
			return null
			
		var colon = consume(TokenType.COLON, "Expected ':'")
		if colon == null:
			return null
		var body = block()
		if report.has_error:
			return null
			
		var while_stmt = WhileStmt.new(condition, body)
		if match_types([TokenType.ELSE]):
			consume(TokenType.COLON, "Expected ':'")
			while_stmt.set_meta("_else_body", block())
		return while_stmt
		
	## 解析 for 循环语句 [br]
	## 支持多变量解包 (逗号分隔) [br]
	## [returns] 解析出的 ForStmt 节点, 出错时返回 null
	func for_statement():
		var variables: Array[String] = []
		var first_tok = consume(TokenType.IDENTIFIER, "Expected variable")
		if first_tok == null:
			return null
		variables.append(first_tok.lexeme)
		
		while match_types([TokenType.COMMA]):
			var next_tok = consume(TokenType.IDENTIFIER, "Expected variable")
			if next_tok == null:
				return null
			variables.append(next_tok.lexeme)
			
		var in_tok = consume(TokenType.IN, "Expected 'in'")
		if in_tok == null:
			return null
		
		var iterable = simple_expression()
		if report.has_error:
			return null
		
		var colon = consume(TokenType.COLON, "Expected ':'")
		if colon == null:
			return null
		var body = block()
		if report.has_error:
			return null
			
		var for_stmt = ForStmt.new(variables, iterable, body)
		if match_types([TokenType.ELSE]):
			consume(TokenType.COLON, "Expected ':'")
			for_stmt.set_meta("_else_body", block())
		return for_stmt
		
	## 解析 try/except/finally 异常处理语句 [br]
	## 支持多个 except 子句和一个可选的 finally 子句 [br]
	## [returns] 解析出的 TryStmt 节点, 出错时返回 null
	func try_statement():
		var try_colon = consume(TokenType.COLON, "Expected ':'")
		if try_colon == null:
			return null
		var try_body = try_block()
		if report.has_error:
			return null
		
		var except_clauses: Array[ExceptClause] = []
		skip_newlines()
		while match_types([TokenType.EXCEPT]):
			var exc_type = null
			var as_name = ""
			if not check(TokenType.COLON):
				exc_type = simple_expression()
				if match_types([TokenType.AS]):
					var var_tok = consume(TokenType.IDENTIFIER, "Expected variable name after 'as'")
					if var_tok != null:
						as_name = var_tok.lexeme
			var colon = consume(TokenType.COLON, "Expected ':'")
			if colon == null:
				return null
			except_clauses.append(ExceptClause.new(exc_type, as_name, block()))
			skip_newlines()
		
		var finally_body: Array[Stmt] = []
		skip_newlines()
		if match_types([TokenType.FINALLY]):
			var colon2 = consume(TokenType.COLON, "Expected ':'")
			if colon2 == null:
				return null
			finally_body = block()
		
		if except_clauses.is_empty() and finally_body.is_empty():
			var debug_tok = peek()
			report.error("Expected 'except' or 'finally' block, but got: %s (type=%d, lexeme='%s')" % [TokenType.keys()[debug_tok.type], debug_tok.type, debug_tok.lexeme])
			return null
		
		return TryStmt.new(try_body, except_clauses, finally_body)
	
	## 解析 try 代码块, 与 block() 类似, 但遇到 except/finally 时停止 (不消费它们) [br]
	## 这样嵌套 try-except 内部的 except 归内层, 外层的 except/finally 归外层 [br]
	## [returns] try 块内的语句数组 (实际类型 Array[Stmt])
	func try_block() -> Array[Stmt]:
		var stmts: Array[Stmt] = []
		if check(TokenType.NEWLINE):
			advance()
			var indent = consume(TokenType.INDENT, "Expected indented block")
			if indent == null:
				return stmts
			while not check(TokenType.DEDENT) and not is_at_end():
				if report.has_error:
					break
				skip_newlines()
				if check(TokenType.DEDENT):
					break
				if check(TokenType.EXCEPT) or check(TokenType.FINALLY):
					break
				var stmt = declaration()
				if stmt != null:
					stmts.append(stmt)
			var dedent = consume(TokenType.DEDENT, "Expected dedent")
			if dedent == null:
				return stmts
		else:
			var stmt = expression_statement()
			if stmt != null:
				stmts.append(stmt)
		return stmts
	
	## 解析 raise 语句 [br]
	## [returns] 解析出的 RaiseStmt 节点
	func raise_statement():
		var expr = null
		if not is_at_end() and not check(TokenType.NEWLINE):
			expr = simple_expression()
		return RaiseStmt.new(expr)
		
	## 解析冒号后的代码块, 支持缩进块和单行语句 [br]
	## 如果下个 Token 是 NEWLINE, 则读取 INDENT 缩进块直到 DEDENT [br]
	## 否则只读取一条表达式语句 [br]
	## [returns] 代码块内的语句数组 (实际类型 Array[Stmt])
	func block() -> Array[Stmt]:
		var stmts: Array[Stmt] = []
		if check(TokenType.NEWLINE):
			advance()
			var indent = consume(TokenType.INDENT, "Expected indented block")
			if indent == null:
				return stmts
			while not check(TokenType.DEDENT) and not is_at_end():
				if report.has_error:
					break
				skip_newlines()
				if check(TokenType.DEDENT):
					break
				var stmt = declaration()
				if stmt != null:
					stmts.append(stmt)
			var dedent = consume(TokenType.DEDENT, "Expected dedent")
			if dedent == null:
				return stmts
		else:
			var stmt = expression_statement()
			if stmt != null:
				stmts.append(stmt)
		return stmts
		
	## 解析三目条件表达式 (x if cond else y) [br]
	## 右结合: a if b else c if d else e 解析为 a if b else (c if d else e) [br]
	## [returns] 解析出的 ConditionalExpr 或普通表达式节点
	func conditional_expression() -> Expr:
		var expr = or_expr()
		if match_types([TokenType.IF]):
			var condition = or_expr()
			var else_token = consume(TokenType.ELSE, "Expected 'else' in conditional expression")
			if else_token == null:
				return null
			var false_expr = conditional_expression() # 递归, 实现右结合
			return ConditionalExpr.new(condition, expr, false_expr)
		return expr
		
	## 解析 or 运算 (最低优先级的逻辑运算) [br]
	## 左结合, 优先级最低 [br]
	## [returns] 解析出的 Binary 节点或下级表达式节点
	func or_expr():
		var expr = and_expr()
		while match_types([TokenType.OR]):
			var op = previous()
			var right = and_expr()
			expr = Binary.new(expr, op, right)
		return expr
		
	## 解析 and 运算 [br]
	## 左结合 [br]
	## [returns] 解析出的 Binary 节点或下级表达式节点
	func and_expr():
		var expr = not_expr()
		while match_types([TokenType.AND]):
			var op = previous()
			var right = not_expr()
			expr = Binary.new(expr, op, right)
		return expr
		
	## 解析 not 一元运算 [br]
	## 右结合 [br]
	## [returns] 解析出的 Unary 节点或下级表达式节点
	func not_expr():
		if match_types([TokenType.NOT]):
			var op = previous()
			return Unary.new(op, not_expr())
		return comparison()
		
	## 解析比较运算 (==, !=, <, >, <=, >=, is, in, is not, not in) [br]
	## 左结合, 所有比较运算符处于同一优先级 [br]
	## [returns] 解析出的 Binary 节点或下级表达式节点
	func comparison():
		var expr = bitwise_or()
		var ops = []
		var comparators = []
		while match_types([TokenType.EQUAL_EQUAL, TokenType.NOT_EQUAL, TokenType.GREATER, TokenType.GREATER_EQUAL, TokenType.LESS, TokenType.LESS_EQUAL, TokenType.IS, TokenType.IN]):
			var op = previous()
			if op.type == TokenType.IS and match_types([TokenType.NOT]):
				op = Token.new(TokenType.IS_NOT, "is not", null, op.line, op.column)
			if op.type == TokenType.IN and match_types([TokenType.NOT]):
				op = Token.new(TokenType.NOT_IN, "not in", null, op.line, op.column)
			ops.append(op)
			var right = bitwise_or()
			comparators.append(right)
		if ops.size() == 0:
			return expr
		if ops.size() == 1:
			return Binary.new(expr, ops[0], comparators[0])
		return CompareChainExpr.new(expr, ops, comparators)

	## 解析位或运算 (|) [br]
	## 左结合: a | b | c 解析为 ((a | b) | c) [br]
	## [returns] 解析出的 Binary 或位异或表达式
	func bitwise_or():
		var expr = bitwise_xor()
		while match_types([TokenType.PIPE]):
			expr = Binary.new(expr, previous(), bitwise_xor())
		return expr

	## 解析位异或运算 (^) [br]
	## 左结合: a ^ b ^ c 解析为 ((a ^ b) ^ c) [br]
	## [returns] 解析出的 Binary 或位与表达式
	func bitwise_xor():
		var expr = bitwise_and()
		while match_types([TokenType.CARET]):
			expr = Binary.new(expr, previous(), bitwise_and())
		return expr

	## 解析位与运算 (&) [br]
	## 左结合: a & b & c 解析为 ((a & b) & c) [br]
	## [returns] 解析出的 Binary 或移位表达式
	func bitwise_and():
		var expr = shift()
		while match_types([TokenType.BITAND]):
			expr = Binary.new(expr, previous(), shift())
		return expr

	## 解析移位运算 (<<, >>) [br]
	## 左结合: a << b << c 解析为 ((a << b) << c) [br]
	## [returns] 解析出的 Binary 或加减表达式
	func shift():
		var expr = addition()
		while match_types([TokenType.LESS_LESS, TokenType.GREATER_GREATER]):
			expr = Binary.new(expr, previous(), addition())
		return expr

	## 解析加减运算 (+, -) [br]
	## 左结合 [br]
	## [returns] 解析出的 Binary 节点或下级表达式节点
	func addition():
		var expr = multiplication()
		while match_types([TokenType.PLUS, TokenType.MINUS]):
			var op = previous()
			var right = multiplication()
			expr = Binary.new(expr, op, right)
		return expr
		
	## 解析乘除, 取模运算 (*, /, %, //) [br]
	## 左结合 [br]
	## [returns] 解析出的 Binary 节点或下级表达式节点
	func multiplication():
		var expr = power()
		while match_types([TokenType.STAR, TokenType.SLASH, TokenType.PERCENT, TokenType.DOUBLESLASH]):
			var op = previous()
			var right = power()
			expr = Binary.new(expr, op, right)
		return expr
		
	## 解析乘方运算 (**) [br]
	## 右结合: a ** b ** c 解析为 a ** (b ** c) [br]
	## [returns] 解析出的 Binary 节点或下级表达式节点
	func power():
		var expr = unary()
		if match_types([TokenType.STARSTAR]):
			var op = previous()
			var right = power()
			expr = Binary.new(expr, op, right)
		return expr
		
	## 解析一元负号和逻辑非 (-, !) [br]
	## 右结合 [br]
	## [returns] 解析出的 Unary 节点或下级基本表达式节点
	func unary():
		if match_types([TokenType.MINUS, TokenType.BANG, TokenType.TILDE]):
			var op = previous()
			return Unary.new(op, unary())
		return primary()
		
	## 解析基本表达式 (字面量, 变量, 括号组, 列表, 字典, lambda, f-string, super) [br]
	## 所有基本表达式解析后都会通过 finish_call_or_index 进行后缀链式处理 [br]
	## lambda 例外: 其函数体自行吸收后缀, 直接返回 LambdaExpr [br]
	## [returns] 解析出的 Expr 节点
	func primary():
		if match_types([TokenType.INTEGER, TokenType.FLOAT, TokenType.STRING, TokenType.TRUE, TokenType.FALSE, TokenType.NULL]):
			return finish_call_or_index(Literal.new(previous().literal))
		if match_types([TokenType.FSTRING]):
			return finish_call_or_index(parse_fstring_expr(previous().literal))
		if match_types([TokenType.IDENTIFIER]):
			var name = previous().lexeme
			if name == "super" and check(TokenType.LPAREN):
				return finish_call_or_index(parse_super_call())
			return finish_call_or_index(Variable.new(name))
		if match_types([TokenType.LAMBDA]):
			return lambda_expression()
		if match_types([TokenType.YIELD]):
			return yield_expression()
		if match_types([TokenType.AWAIT]):
			# await 的运算对象是一个 primary 表达式 (CPython 的 await_primary 规则),
			# 其作用域合法性由解析后的 AST 遍历统一判定 (见 _walk_yield_expr)
			var awaited = primary()
			if awaited == null:
				return null
			return AwaitExpr.new(awaited)
		if match_types([TokenType.LPAREN]):
			return finish_call_or_index(parse_group_or_generator())
		if match_types([TokenType.LBRACKET]):
			return finish_call_or_index(parse_list_or_listcomp())
		if match_types([TokenType.LBRACE]):
			return finish_call_or_index(parse_dict_or_dictcomp())
		# async/await 是保留字, 出现在表达式位置按 CPython 报通用语法错误,
		# 而不是让它们作为标识符进入求值阶段报 NameError
		if check(TokenType.ASYNC) or check(TokenType.AWAIT):
			report.error("SyntaxError: invalid syntax")
			return null
		report.error("Unexpected token '%s'" % peek().lexeme)
		return null

	## 解析 lambda 表达式: lambda [params]: body [br]
	## 支持默认值, *args, **kwargs 与仅关键字参数 (* 分隔) [br]
	## [returns] LambdaExpr 节点, 出错时返回 null
	func lambda_expression() -> Expr:
		var params: Array[Param] = []
		var saw_star = false
		if not check(TokenType.COLON):
			while true:
				if report.has_error:
					return null
				if check(TokenType.STAR):
					var next_idx = current + 1
					var is_star_only = false
					if next_idx >= tokens.size():
						is_star_only = true
					else:
						var nt = tokens[next_idx].type
						if nt == TokenType.IDENTIFIER or nt == TokenType.COLON or nt == TokenType.EQUAL:
							is_star_only = false
						else:
							is_star_only = true
					if is_star_only:
						advance()
						saw_star = true
						if not match_types([TokenType.COMMA]):
							break
						continue
					else:
						advance()
						var tok = consume(TokenType.IDENTIFIER, "Expected parameter name")
						if tok == null:
							return null
						params.append(Param.new(tok.lexeme, null, true, false, false, false))
						saw_star = true
						if not match_types([TokenType.COMMA]):
							break
						continue
				elif check(TokenType.STARSTAR):
					advance()
					var tok = consume(TokenType.IDENTIFIER, "Expected parameter name")
					if tok == null:
						return null
					params.append(Param.new(tok.lexeme, null, false, true))
					break
				else:
					var tok = consume(TokenType.IDENTIFIER, "Expected parameter name")
					if tok == null:
						return null
					var param_name = tok.lexeme
					var default_expr = null
					if match_types([TokenType.EQUAL]):
						default_expr = simple_expression()
						if report.has_error:
							return null
					params.append(Param.new(param_name, default_expr, false, false, false, saw_star))
				if not match_types([TokenType.COMMA]):
					break
		var colon = consume(TokenType.COLON, "Expected ':' in lambda expression")
		if colon == null:
			return null
		var body = simple_expression()
		if body == null or report.has_error:
			return null
		return LambdaExpr.new(params, body)

	## 解析 yield 表达式: yield [from] [expr] [br]
	## yield 可作独立语句或任意表达式位置 (Python 3 语义), 值表达式吸收完整元组 [br]
	## [returns] YieldExpr 节点, 出错时返回 null
	func yield_expression() -> Expr:
		var y = YieldExpr.new(null)
		if match_types([TokenType.FROM]):
			var from_val = tuple_expression()
			if report.has_error or from_val == null:
				return null
			y.from_expr = from_val
			return y
		if _starts_expression():
			var val = tuple_expression()
			if report.has_error or val == null:
				return null
			y.value = val
		return y

	## 判断当前 Token 是否可作表达式开头 [br]
	## 用于区分裸 yield 与 yield expr [br]
	## [returns] 当前 Token 可开始表达式时返回 true
	func _starts_expression() -> bool:
		if is_at_end():
			return false
		var starters = [TokenType.INTEGER, TokenType.FLOAT, TokenType.STRING, TokenType.FSTRING,
			TokenType.TRUE, TokenType.FALSE, TokenType.NULL,
			TokenType.IDENTIFIER, TokenType.LAMBDA, TokenType.YIELD, TokenType.AWAIT,
			TokenType.LPAREN, TokenType.LBRACKET, TokenType.LBRACE,
			TokenType.MINUS, TokenType.BANG, TokenType.TILDE, TokenType.NOT]
		return starters.has(peek().type)

	## 编译期检测 yield 用法 (在解析完成后遍历整棵 AST) [br]
	## 规则: 函数外 yield 报 SyntaxError; 推导式内直接 yield 报 SyntaxError; [br]
	## 函数体含 yield 时标记 FunctionStmt.is_generator; lambda 体直接含 yield 时标记为生成器 lambda [br]
	## [param stmts] 语句数组 [br]
	## [param scope] 0=模块/类体(非函数), 1=函数体, 2=lambda 体 [br]
	## [returns] 本作用域内是否含直接 yield
	func _walk_yield_stmt(stmts: Array, scope: int, loop_depth: int = 0) -> bool:
		var found = false
		for stmt in stmts:
			# 首个语法错误即为最终结论 (与 CPython 一致), 避免后续遍历覆盖错误文案
			if report.has_error:
				return found
			if stmt is FunctionStmt:
				stmt.is_generator = _walk_yield_stmt(stmt.body, 1)
				for p in stmt.params:
					if p.default_value != null:
						_walk_yield_expr(p.default_value, scope, "")
			elif stmt is ClassStmt:
				# 类体是独立作用域: 外层循环不使其中的 break/continue 合法
				_walk_yield_stmt(stmt.body, 0)
			elif stmt is ExpressionStmt:
				if _walk_yield_expr(stmt.expression, scope, ""):
					found = true
			elif stmt is IfStmt:
				_walk_yield_expr(stmt.condition, scope, "")
				if _walk_yield_stmt(stmt.then_branch, scope, loop_depth):
					found = true
				for branch in stmt.elif_branches:
					_walk_yield_expr(branch[0], scope, "")
					if _walk_yield_stmt(branch[1], scope, loop_depth):
						found = true
				if _walk_yield_stmt(stmt.else_branch, scope, loop_depth):
					found = true
			elif stmt is WhileStmt:
				_walk_yield_expr(stmt.condition, scope, "")
				if _walk_yield_stmt(stmt.body, scope, loop_depth + 1):
					found = true
			elif stmt is ForStmt:
				_walk_yield_expr(stmt.iterable, scope, "")
				if _walk_yield_stmt(stmt.body, scope, loop_depth + 1):
					found = true
			elif stmt is ReturnStmt:
				if scope == 0:
					report.error("SyntaxError: 'return' outside function")
				if stmt.value != null and _walk_yield_expr(stmt.value, scope, ""):
					found = true
			elif stmt is BreakStmt:
				if loop_depth == 0:
					report.error("SyntaxError: 'break' outside loop")
			elif stmt is ContinueStmt:
				if loop_depth == 0:
					report.error("SyntaxError: 'continue' not properly in loop")
			elif stmt is TryStmt:
				if _walk_yield_stmt(stmt.try_body, scope, loop_depth):
					found = true
				for clause in stmt.except_clauses:
					if clause.exception_type != null:
						_walk_yield_expr(clause.exception_type, scope, "")
					if _walk_yield_stmt(clause.body, scope, loop_depth):
						found = true
				if _walk_yield_stmt(stmt.finally_body, scope, loop_depth):
					found = true
			elif stmt is RaiseStmt:
				if stmt.expression != null and _walk_yield_expr(stmt.expression, scope, ""):
					found = true
			elif stmt is AssertStmt:
				_walk_yield_expr(stmt.test, scope, "")
				if stmt.message != null:
					_walk_yield_expr(stmt.message, scope, "")
			elif stmt is DelStmt:
				for t in stmt.targets:
					_walk_yield_expr(t, scope, "")
		return found

	## 递归遍历表达式, 检测 yield 用法 (对标 CPython 3.12) [br]
	## [param expr] 表达式节点 [br]
	## [param scope] 0=模块/类体, 1=函数体, 2=lambda 体 [br]
	## [param comp_ctx] 推导式上下文: ""=不在推导式内, "outer"=推导式最外层可迭代 (在函数作用域求值), [br]
	## 其余为推导式作用域 (list/set/dict/generator), 其中的 yield 一律报错 [br]
	## [returns] 本作用域内是否含直接 yield (嵌套函数/lambda 的 yield 不计)
	func _walk_yield_expr(expr, scope: int, comp_ctx: String) -> bool:
		if expr == null:
			return false
		# 首个语法错误即为最终结论 (与 CPython 一致)
		if report.has_error:
			return false
		if expr is YieldExpr:
			if comp_ctx != "":
				# 裸 yield 是语法错误, 括号 yield 在推导式作用域内报 "inside ... comprehension"
				if not expr.has_meta("parenthesized"):
					report.error("SyntaxError: invalid syntax")
					return false
				if comp_ctx == "outer":
					if expr.value != null:
						_walk_yield_expr(expr.value, scope, comp_ctx)
					if expr.from_expr != null:
						_walk_yield_expr(expr.from_expr, scope, comp_ctx)
					return true
				report.error("SyntaxError: 'yield' inside " + _comp_kind_phrase(comp_ctx))
				return false
			if scope == 0:
				report.error("SyntaxError: 'yield' outside function")
				return false
			if expr.value != null:
				_walk_yield_expr(expr.value, scope, comp_ctx)
			if expr.from_expr != null:
				_walk_yield_expr(expr.from_expr, scope, comp_ctx)
			return true
		if expr is AwaitExpr:
			# await 只在 async 函数内合法; PyGDS 不支持 async, 因此任何位置都报错 [br]
			# 文案按 CPython 的三种语境区分 (推导式内另有专属文案)
			if comp_ctx != "":
				report.error("SyntaxError: asynchronous comprehension outside of an asynchronous function")
			elif scope == 0:
				report.error("SyntaxError: 'await' outside function")
			else:
				report.error("SyntaxError: 'await' outside async function")
			if expr.value != null:
				_walk_yield_expr(expr.value, scope, comp_ctx)
			return false
		if expr is LambdaExpr:
			if expr.body != null and _walk_yield_expr(expr.body, 2, ""):
				expr.is_generator = true
			for p in expr.params:
				if p.default_value != null:
					_walk_yield_expr(p.default_value, scope, comp_ctx)
			return false
		if expr is ListComp or expr is SetComp or expr is GenComp or expr is DictComp:
			return _walk_comp_yield(expr, scope, comp_ctx)
		if expr is Assign:
			return _walk_yield_expr(expr.value, scope, comp_ctx)
		if expr is WalrusExpr:
			return _walk_yield_expr(expr.value, scope, comp_ctx)
		if expr is AugAssign:
			return _walk_yield_expr(expr.value, scope, comp_ctx)
		if expr is AugAssignAttr:
			if _walk_yield_expr(expr.object, scope, comp_ctx):
				return true
			return _walk_yield_expr(expr.value, scope, comp_ctx)
		if expr is AugAssignItem:
			if _walk_yield_expr(expr.object, scope, comp_ctx):
				return true
			if _walk_yield_expr(expr.index, scope, comp_ctx):
				return true
			return _walk_yield_expr(expr.value, scope, comp_ctx)
		if expr is GetItem:
			if _walk_yield_expr(expr.object, scope, comp_ctx):
				return true
			return _walk_yield_expr(expr.index, scope, comp_ctx)
		if expr is SetItem:
			if _walk_yield_expr(expr.object, scope, comp_ctx):
				return true
			if _walk_yield_expr(expr.index, scope, comp_ctx):
				return true
			return _walk_yield_expr(expr.value, scope, comp_ctx)
		if expr is SliceExpr:
			if expr.start != null and _walk_yield_expr(expr.start, scope, comp_ctx):
				return true
			if expr.stop != null and _walk_yield_expr(expr.stop, scope, comp_ctx):
				return true
			if expr.step != null and _walk_yield_expr(expr.step, scope, comp_ctx):
				return true
			return false
		if expr is CompareChainExpr:
			if _walk_yield_expr(expr.left, scope, comp_ctx):
				return true
			for cmp in expr.comparators:
				if _walk_yield_expr(cmp, scope, comp_ctx):
					return true
			return false
		if expr is Binary:
			if _walk_yield_expr(expr.left, scope, comp_ctx):
				return true
			return _walk_yield_expr(expr.right, scope, comp_ctx)
		if expr is Unary:
			return _walk_yield_expr(expr.right, scope, comp_ctx)
		if expr is GetAttr:
			return _walk_yield_expr(expr.object, scope, comp_ctx)
		if expr is SetAttr:
			if _walk_yield_expr(expr.object, scope, comp_ctx):
				return true
			return _walk_yield_expr(expr.value, scope, comp_ctx)
		if expr is Call:
			if _walk_yield_expr(expr.callee_expr, scope, comp_ctx):
				return true
			for a in expr.arguments:
				if _walk_yield_expr(a, scope, comp_ctx):
					return true
			for sa in expr.star_args:
				if _walk_yield_expr(sa, scope, comp_ctx):
					return true
			for skw in expr.star_kwargs:
				if _walk_yield_expr(skw, scope, comp_ctx):
					return true
			for kw in expr.keyword_args:
				if _walk_yield_expr(kw.value, scope, comp_ctx):
					return true
			return false
		if expr is ListLiteral or expr is TupleLiteral or expr is SetLiteral:
			for e in expr.elements:
				if _walk_yield_expr(e, scope, comp_ctx):
					return true
			return false
		if expr is DictLiteral:
			for k in expr.keys:
				if _walk_yield_expr(k, scope, comp_ctx):
					return true
			for v in expr.values:
				if _walk_yield_expr(v, scope, comp_ctx):
					return true
			return false
		if expr is StarredExpr:
			return _walk_yield_expr(expr.value, scope, comp_ctx)
		if expr is UnpackAssign:
			if _walk_yield_expr(expr.value, scope, comp_ctx):
				return true
			return false
		if expr is ConditionalExpr:
			if _walk_yield_expr(expr.condition, scope, comp_ctx):
				return true
			if _walk_yield_expr(expr.true_expr, scope, comp_ctx):
				return true
			return _walk_yield_expr(expr.false_expr, scope, comp_ctx)
		if expr is FStringExpr:
			for part in expr.parts:
				if part.expr != null and _walk_yield_expr(part.expr, scope, comp_ctx):
					return true
			return false
		if expr is SuperExpr:
			for a in expr.arguments:
				if _walk_yield_expr(a, scope, comp_ctx):
					return true
			return false
		return false

	## 遍历推导式的子表达式, 遇到直接 yield 时按 [param err_msg] 报错 [br]
	## 将推导式上下文标识转为报错文案 [br]
	## [param ctx] list/set/dict/generator [br]
	## [returns] 对应的英文短语 (CPython 报错文案用)
	func _comp_kind_phrase(ctx: String) -> String:
		match ctx:
			"list":
				return "list comprehension"
			"set":
				return "set comprehension"
			"dict":
				return "dict comprehension"
			"generator":
				return "generator expression"
		return "comprehension"

	## 遍历推导式的子表达式, 按 CPython 规则处理其中的 yield [br]
	## 最外层子句的可迭代表达式在外层作用域求值 (其中的 yield 属于外层生成器函数, 合法) [br]
	## 其余子句可迭代/元素/键值/条件都在推导式自身作用域求值 (其中的 yield 报错) [br]
	## 嵌套 lambda 体内的 yield 属于 lambda 自身, 不计入推导式 [br]
	## [param comp] 推导式节点 [br]
	## [param scope] 外层作用域 [br]
	## [param enclosing_ctx] 外层推导式上下文 [br]
	## [returns] 最外层可迭代内是否含属于外层函数的 yield
	func _walk_comp_yield(comp, scope: int, enclosing_ctx: String) -> bool:
		var kind = "generator"
		if comp is ListComp:
			kind = "list"
		elif comp is SetComp:
			kind = "set"
		elif comp is DictComp:
			kind = "dict"
		var found = false
		# 最外层子句的可迭代表达式在 "外层作用域" 求值 (外层非推导式时 yield 合法)
		if comp.clauses.size() > 0:
			var outer_ctx = enclosing_ctx if enclosing_ctx != "" else "outer"
			if _walk_yield_expr(comp.clauses[0].iterable, scope, outer_ctx):
				found = true
		# 其余子句可迭代表达式在推导式自身作用域求值
		for i in range(1, comp.clauses.size()):
			_walk_yield_expr(comp.clauses[i].iterable, scope, kind)
		# 条件与元素/键值同样在推导式自身作用域求值
		for clause in comp.clauses:
			for cond in clause.conditions:
				_walk_yield_expr(cond, scope, kind)
		if comp is DictComp:
			_walk_yield_expr(comp.key_expr, scope, kind)
			_walk_yield_expr(comp.value_expr, scope, kind)
		else:
			_walk_yield_expr(comp.elt_expr, scope, kind)
		return found

	## 解析 super(...) 调用 [br]
	## 支持零参数 super() 与双参数 super(Class, obj) [br]
	## [returns] SuperExpr 节点
	func parse_super_call() -> Expr:
		var args: Array[Expr] = []
		if match_types([TokenType.LPAREN]):
			if not check(TokenType.RPAREN):
				while true:
					if report.has_error:
						return null
					var e = simple_expression()
					if e == null:
						return null
					args.append(e)
					if not match_types([TokenType.COMMA]):
						break
			consume(TokenType.RPAREN, "Expected ')' after super")
		return SuperExpr.new(args)

	## 解析 f-string 的 parts, 将替换字段的源码片段解析为 Expr [br]
	## [param parts_raw] Lexer 产出的原始 parts (expr 为源码字符串) [br]
	## [returns] FStringExpr 节点, 出错时返回 null
	func parse_fstring_expr(parts_raw: Array) -> Expr:
		var parts: Array = []
		for part in parts_raw:
			if part.get("is_literal", true):
				parts.append({"is_literal": true, "text": part.text, "expr": null, "conv": "", "fmt": "", "debug": false, "raw": ""})
			else:
				var expr_src: String = part.expr
				var parsed = parse_sub_expression(expr_src)
				if parsed == null:
					return null
				parts.append({"is_literal": false, "text": "", "expr": parsed, "conv": part.conv, "fmt": part.fmt, "debug": part.get("debug", false), "raw": expr_src})
		return FStringExpr.new(parts)

	## 将一段源码字符串独立解析为单个表达式 [br]
	## 用于 f-string 内嵌表达式 [br]
	## [param src] 源码片段 [br]
	## [returns] Expr 节点, 出错时返回 null
	func parse_sub_expression(src: String) -> Expr:
		var lexer = Lexer.new(report, src)
		var toks = lexer.scan()
		if report.has_error:
			return null
		var sub_parser = Parser.new(report, toks)
		var expr = sub_parser.simple_expression()
		if report.has_error or expr == null:
			return null
		return expr
		
	## 后缀链式处理: 函数调用 (args), 索引访问 [index], 属性访问 .attr [br]
	## 循环消费紧跟在基本表达式后面的 LPAREN, LBRACKET, DOT, 构建链式 AST [br]
	## [param expr] 已解析的基本表达式 [br]
	## [returns] 经过后缀链式处理后的完整表达式节点
	func finish_call_or_index(expr: Expr) -> Expr:
		while true:
			if report.has_error:
				return null
			if match_types([TokenType.LPAREN]):
				var args: Array[Expr] = []
				var kw_args: Array[KeywordArg] = []
				var star_args: Array[Expr] = []
				var star_kwargs: Array[Expr] = []
				if not check(TokenType.RPAREN):
					var arg_data = arguments()
					if report.has_error:
						return null
					args = arg_data[0]
					kw_args = arg_data[1]
					star_args = arg_data[2]
					star_kwargs = arg_data[3]
				var rparen = consume(TokenType.RPAREN, "Expected ')'")
				if rparen == null:
					return null
				expr = Call.new(expr, args, kw_args, star_args, star_kwargs)
			elif match_types([TokenType.LBRACKET]):
				if match_types([TokenType.COLON]):
					var start = null
					var stop = null
					var step = null
					if not check(TokenType.RBRACKET) and not check(TokenType.COLON):
						stop = simple_expression()
					if match_types([TokenType.COLON]):
						if not check(TokenType.RBRACKET):
							step = simple_expression()
					var rbracket = consume(TokenType.RBRACKET, "Expected ']'")
					if rbracket == null:
						return null
					expr = GetItem.new(expr, SliceExpr.new(start, stop, step))
				else:
					var index = simple_expression()
					if report.has_error:
						return null
					if match_types([TokenType.COLON]):
						var start = index
						var stop = null
						var step = null
						if not check(TokenType.RBRACKET) and not check(TokenType.COLON):
							stop = simple_expression()
						if match_types([TokenType.COLON]):
							if not check(TokenType.RBRACKET):
								step = simple_expression()
						var rbracket = consume(TokenType.RBRACKET, "Expected ']'")
						if rbracket == null:
							return null
						expr = GetItem.new(expr, SliceExpr.new(start, stop, step))
					else:
						var rbracket = consume(TokenType.RBRACKET, "Expected ']'")
						if rbracket == null:
							return null
						expr = GetItem.new(expr, index)
			elif match_types([TokenType.DOT]):
				var attr_tok = consume(TokenType.IDENTIFIER, "Expected attribute name")
				if attr_tok == null:
					return null
				expr = GetAttr.new(expr, attr_tok.lexeme)
			else:
				break
		return expr
		
	## 解析函数调用中的实参列表 [br]
	## 支持位置参数, 关键字参数, *iterable 解包与 **mapping 解包 [br]
	## 检测位置参数跟在关键字参数之后的语法错误 [br]
	## [returns] [code][pos_args, keyword_args, star_args, star_kwargs][/code]
	func arguments() -> Array:
		var pos_args: Array[Expr] = []
		var kw_args: Array[KeywordArg] = []
		var star_args: Array[Expr] = []
		var star_kwargs: Array[Expr] = []
		var saw_keyword = false
		
		# 解析第一个参数
		if not check(TokenType.RPAREN):
			while true:
				if report.has_error:
					break
				# *iterable 解包
				if match_types([TokenType.STAR]):
					if saw_keyword:
						report.error("SyntaxError: iterable unpacking cannot be used in keyword arguments")
						return [pos_args, kw_args, star_args, star_kwargs]
					var star_expr = simple_expression()
					if star_expr == null:
						return [pos_args, kw_args, star_args, star_kwargs]
					star_args.append(star_expr)
				# **mapping 解包
				elif match_types([TokenType.STARSTAR]):
					var kw_expr = simple_expression()
					if kw_expr == null:
						return [pos_args, kw_args, star_args, star_kwargs]
					star_kwargs.append(kw_expr)
					saw_keyword = true
				else:
					# 尝试解析一个表达式
					var expr = simple_expression()
					if match_types([TokenType.EQUAL]):
						# 这是一个关键字参数, 要求 expr 必须 Variable
						if not expr is Variable:
							report.error("Invalid keyword argument name")
							return [pos_args, kw_args, star_args, star_kwargs]
						else:
							var value = simple_expression()
							kw_args.append(KeywordArg.new(expr.name, value))
							saw_keyword = true
					else:
						if saw_keyword:
							report.error("SyntaxError: positional argument follows keyword argument")
							return [pos_args, kw_args, star_args, star_kwargs]
						# 裸生成器表达式作为位置参数: f(x for x in it)
						if check(TokenType.FOR):
							var gen = _parse_gen_comp_after_first(expr)
							if gen == null:
								return [pos_args, kw_args, star_args, star_kwargs]
							pos_args.append(gen)
						else:
							# 普通位置参数
							pos_args.append(expr)
						
				if not match_types([TokenType.COMMA]):
					break
				skip_newlines()
		return [pos_args, kw_args, star_args, star_kwargs]
		
	## 解析圆括号内的元组字面量或生成器表达式 (x for x in ...) [br]
	## 空括号返回空元组, 单个带逗号的表达式返回元组, 有 for 则返回生成器 (ListComp) [br]
	## [returns] 解析出的 TupleLiteral, ListComp 或单个表达式节点
	func parse_group_or_generator():
		# 空圆括号 -> 空元组
		if check(TokenType.RPAREN):
			advance()
			return TupleLiteral.new([])
			
		# 内部可能已经是元组(有逗号) 或单个表达式
		var first = tuple_expression()
		if report.has_error:
			return null
		skip_newlines()
		
		# 生成器表达式: single_target for ... in ... [if ...]
		if check(TokenType.FOR):
			var gen = _parse_gen_comp_after_first(first)
			if gen == null:
				return null
			var rparen = consume(TokenType.RPAREN, "Expected ')'")
			if rparen == null:
				return null
			return gen
		else:
			# 不是生成器 则按普通圆括号结束
			var rparen = consume(TokenType.RPAREN, "Expected ')'")
			if rparen == null:
				return null
		# 标记为带括号的表达式 (供语句级检查裸写赋值表达式使用)
		if first is Expr:
			first.set_meta("parenthesized", true)
		# 返回 first, 可能TupleLiteral ((1, 2)) 或单个表达式 (仅分 (x))
		return first

	## 在首个元素表达式后解析生成器表达式尾部: for var in iterable [if cond] [br]
	## 支持多 for 与多 if 子句 [br]
	## [param first] 元素表达式 [br]
	## [returns] GenComp 节点, 非生成器或出错时返回 null
	func _parse_gen_comp_after_first(first) -> Expr:
		if first is TupleLiteral:
			report.error("SyntaxError: invalid syntax")
			return null
		var clauses = _parse_comp_clauses(false)
		if clauses == null:
			return null
		var gen_comp = GenComp.new(first, clauses)
		if not _check_comp_walrus(gen_comp):
			return null
		return gen_comp

	## 校验推导式的赋值表达式规则 (对标 CPython) [br]
	## 规则 1: 赋值表达式不得重绑定本推导式或其外层推导式的循环变量 [br]
	## 规则 2: 赋值表达式不得出现在推导式的可迭代表达式内 [br]
	## [param node] 推导式节点 (ListComp/SetComp/DictComp/GenComp) [br]
	## [param outer_protected] 外层推导式的循环变量名 (嵌套推导式继承) [br]
	## [returns] 校验通过返回 true, 违反规则时报错并返回 false
	func _check_comp_walrus(node, outer_protected: Array = []) -> bool:
		var protected: Array = outer_protected.duplicate()
		for clause in node.clauses:
			for t in clause.targets:
				protected.append(t)
		# 规则 2: 可迭代表达式内禁止任何赋值表达式 (含 lambda 与嵌套推导式内部)
		for clause in node.clauses:
			if _has_walrus_anywhere(clause.iterable):
				report.error("SyntaxError: assignment expression cannot be used in a comprehension iterable expression")
				return false
		# 规则 1: 元素/键值/条件内不得重绑定循环变量
		if node is DictComp:
			if not _check_walrus_rebind(node.key_expr, protected):
				return false
			if not _check_walrus_rebind(node.value_expr, protected):
				return false
		else:
			if not _check_walrus_rebind(node.elt_expr, protected):
				return false
		for clause in node.clauses:
			for cond in clause.conditions:
				if not _check_walrus_rebind(cond, protected):
					return false
		return true

	## 检查表达式内是否存在重绑定受保护循环变量的赋值表达式 (规则 1) [br]
	## 不进入 lambda 体 (其作用域独立); 进入嵌套推导式时把其循环变量一并纳入保护 [br]
	## [param expr] 待检查表达式 [br]
	## [param protected] 受保护的循环变量名数组 [br]
	## [returns] 通过返回 true, 违反时返回 false
	func _check_walrus_rebind(expr, protected: Array) -> bool:
		if expr == null:
			return true
		if expr is WalrusExpr:
			if protected.has(expr.name):
				report.error("SyntaxError: assignment expression cannot rebind comprehension iteration variable '%s'" % expr.name)
				return false
			return _check_walrus_rebind(expr.value, protected)
		if expr is LambdaExpr:
			return true
		if expr is ListComp or expr is SetComp or expr is GenComp or expr is DictComp:
			return _check_comp_walrus(expr, protected)
		if expr is Assign:
			return _check_walrus_rebind(expr.value, protected)
		if expr is AugAssign:
			return _check_walrus_rebind(expr.value, protected)
		if expr is AugAssignAttr:
			if not _check_walrus_rebind(expr.object, protected):
				return false
			return _check_walrus_rebind(expr.value, protected)
		if expr is AugAssignItem:
			if not _check_walrus_rebind(expr.object, protected):
				return false
			if not _check_walrus_rebind(expr.index, protected):
				return false
			return _check_walrus_rebind(expr.value, protected)
		if expr is GetItem:
			if not _check_walrus_rebind(expr.object, protected):
				return false
			return _check_walrus_rebind(expr.index, protected)
		if expr is SetItem:
			if not _check_walrus_rebind(expr.object, protected):
				return false
			if not _check_walrus_rebind(expr.index, protected):
				return false
			return _check_walrus_rebind(expr.value, protected)
		if expr is SliceExpr:
			if not _check_walrus_rebind(expr.start, protected):
				return false
			if not _check_walrus_rebind(expr.stop, protected):
				return false
			return _check_walrus_rebind(expr.step, protected)
		if expr is CompareChainExpr:
			if not _check_walrus_rebind(expr.left, protected):
				return false
			for cmp in expr.comparators:
				if not _check_walrus_rebind(cmp, protected):
					return false
			return true
		if expr is Binary:
			if not _check_walrus_rebind(expr.left, protected):
				return false
			return _check_walrus_rebind(expr.right, protected)
		if expr is Unary:
			return _check_walrus_rebind(expr.right, protected)
		if expr is GetAttr:
			return _check_walrus_rebind(expr.object, protected)
		if expr is SetAttr:
			if not _check_walrus_rebind(expr.object, protected):
				return false
			return _check_walrus_rebind(expr.value, protected)
		if expr is Call:
			if not _check_walrus_rebind(expr.callee_expr, protected):
				return false
			for a in expr.arguments:
				if not _check_walrus_rebind(a, protected):
					return false
			for sa in expr.star_args:
				if not _check_walrus_rebind(sa, protected):
					return false
			for skw in expr.star_kwargs:
				if not _check_walrus_rebind(skw, protected):
					return false
			for kw in expr.keyword_args:
				if not _check_walrus_rebind(kw.value, protected):
					return false
			return true
		if expr is ListLiteral or expr is TupleLiteral or expr is SetLiteral:
			for e in expr.elements:
				if not _check_walrus_rebind(e, protected):
					return false
			return true
		if expr is DictLiteral:
			for k in expr.keys:
				if not _check_walrus_rebind(k, protected):
					return false
			for v in expr.values:
				if not _check_walrus_rebind(v, protected):
					return false
			return true
		if expr is StarredExpr:
			return _check_walrus_rebind(expr.value, protected)
		if expr is UnpackAssign:
			return _check_walrus_rebind(expr.value, protected)
		if expr is ConditionalExpr:
			if not _check_walrus_rebind(expr.condition, protected):
				return false
			if not _check_walrus_rebind(expr.true_expr, protected):
				return false
			return _check_walrus_rebind(expr.false_expr, protected)
		if expr is FStringExpr:
			for part in expr.parts:
				if part.expr != null and not _check_walrus_rebind(part.expr, protected):
					return false
			return true
		if expr is SuperExpr:
			for a in expr.arguments:
				if not _check_walrus_rebind(a, protected):
					return false
			return true
		return true

	## 检查表达式子树内是否存在赋值表达式 (规则 2 用) [br]
	## 不做作用域区分: lambda 体与嵌套推导式内部同样计入 [br]
	## [param expr] 待检查表达式 [br]
	## [returns] 存在赋值表达式时返回 true
	func _has_walrus_anywhere(expr) -> bool:
		if expr == null:
			return false
		if expr is WalrusExpr:
			return true
		if expr is LambdaExpr:
			return _has_walrus_anywhere(expr.body)
		if expr is ListComp or expr is SetComp or expr is GenComp:
			if _has_walrus_anywhere(expr.elt_expr):
				return true
			return _has_walrus_in_clauses(expr.clauses)
		if expr is DictComp:
			if _has_walrus_anywhere(expr.key_expr):
				return true
			if _has_walrus_anywhere(expr.value_expr):
				return true
			return _has_walrus_in_clauses(expr.clauses)
		if expr is Assign:
			return _has_walrus_anywhere(expr.value)
		if expr is AugAssign:
			return _has_walrus_anywhere(expr.value)
		if expr is AugAssignAttr:
			return _has_walrus_anywhere(expr.object) or _has_walrus_anywhere(expr.value)
		if expr is AugAssignItem:
			return _has_walrus_anywhere(expr.object) or _has_walrus_anywhere(expr.index) or _has_walrus_anywhere(expr.value)
		if expr is GetItem:
			return _has_walrus_anywhere(expr.object) or _has_walrus_anywhere(expr.index)
		if expr is SetItem:
			return _has_walrus_anywhere(expr.object) or _has_walrus_anywhere(expr.index) or _has_walrus_anywhere(expr.value)
		if expr is SliceExpr:
			return _has_walrus_anywhere(expr.start) or _has_walrus_anywhere(expr.stop) or _has_walrus_anywhere(expr.step)
		if expr is CompareChainExpr:
			if _has_walrus_anywhere(expr.left):
				return true
			for cmp in expr.comparators:
				if _has_walrus_anywhere(cmp):
					return true
			return false
		if expr is Binary:
			return _has_walrus_anywhere(expr.left) or _has_walrus_anywhere(expr.right)
		if expr is Unary:
			return _has_walrus_anywhere(expr.right)
		if expr is GetAttr:
			return _has_walrus_anywhere(expr.object)
		if expr is SetAttr:
			return _has_walrus_anywhere(expr.object) or _has_walrus_anywhere(expr.value)
		if expr is Call:
			if _has_walrus_anywhere(expr.callee_expr):
				return true
			for a in expr.arguments:
				if _has_walrus_anywhere(a):
					return true
			for sa in expr.star_args:
				if _has_walrus_anywhere(sa):
					return true
			for skw in expr.star_kwargs:
				if _has_walrus_anywhere(skw):
					return true
			for kw in expr.keyword_args:
				if _has_walrus_anywhere(kw.value):
					return true
			return false
		if expr is ListLiteral or expr is TupleLiteral or expr is SetLiteral:
			for e in expr.elements:
				if _has_walrus_anywhere(e):
					return true
			return false
		if expr is DictLiteral:
			for k in expr.keys:
				if _has_walrus_anywhere(k):
					return true
			for v in expr.values:
				if _has_walrus_anywhere(v):
					return true
			return false
		if expr is StarredExpr:
			return _has_walrus_anywhere(expr.value)
		if expr is UnpackAssign:
			return _has_walrus_anywhere(expr.value)
		if expr is ConditionalExpr:
			return _has_walrus_anywhere(expr.condition) or _has_walrus_anywhere(expr.true_expr) or _has_walrus_anywhere(expr.false_expr)
		if expr is FStringExpr:
			for part in expr.parts:
				if part.expr != null and _has_walrus_anywhere(part.expr):
					return true
			return false
		if expr is SuperExpr:
			for a in expr.arguments:
				if _has_walrus_anywhere(a):
					return true
			return false
		return false

	## 检查推导式子句序列内是否存在赋值表达式 (规则 2 用) [br]
	## [param clauses] CompClause 数组 [br]
	## [returns] 存在赋值表达式时返回 true
	func _has_walrus_in_clauses(clauses: Array) -> bool:
		for clause in clauses:
			if _has_walrus_anywhere(clause.iterable):
				return true
			for cond in clause.conditions:
				if _has_walrus_anywhere(cond):
					return true
		return false

	## 解析推导式的循环子句序列 (支持多 for 与多 if) [br]
	## 调用时当前令牌必须是 FOR [br]
	## [param allow_pair_target] 是否允许 k, v 形式的元组目标 [br]
	## [returns] CompClause 数组, 出错时返回 null
	func _parse_comp_clauses(allow_pair_target: bool):
		var clauses: Array = []
		while match_types([TokenType.FOR]):
			var targets: Array = []
			var first_tok = consume(TokenType.IDENTIFIER, "Expected variable")
			if first_tok == null:
				return null
			targets.append(first_tok.lexeme)
			if allow_pair_target or check(TokenType.COMMA):
				while match_types([TokenType.COMMA]):
					var next_tok = consume(TokenType.IDENTIFIER, "Expected variable")
					if next_tok == null:
						return null
					targets.append(next_tok.lexeme)
			var in_tok = consume(TokenType.IN, "Expected 'in'")
			if in_tok == null:
				return null
			var iterable = or_expr()
			if report.has_error:
				return null
			var conditions: Array = []
			while match_types([TokenType.IF]):
				var cond = or_expr()
				if report.has_error:
					return null
				conditions.append(cond)
			clauses.append(CompClause.new(targets, iterable, conditions))
		if clauses.size() == 0:
			report.error("SyntaxError: invalid comprehension")
			return null
		return clauses

	## 解析列表/元组/集合字面量中的一个条目, 识别前置 * 解包 [br]
	## [returns] StarredExpr (解包条目) 或普通 Expr, 出错时返回 null
	func _parse_star_or_simple() -> Expr:
		if match_types([TokenType.STAR]):
			var inner = simple_expression()
			if report.has_error:
				return null
			return StarredExpr.new(inner)
		return simple_expression()

	## 解析列表字面量或列表推导式 [br]
	## 空方括号返回空列表, 有 for 则解析为列表推导式, 否则解析普通列表 (支持 * 解包) [br]
	## [returns] 解析出的 ListLiteral 或 ListComp 节点
	func parse_list_or_listcomp():
		if check(TokenType.RBRACKET):
			advance()
			return ListLiteral.new([])

		var first = _parse_star_or_simple()
		if report.has_error:
			return null

		if check(TokenType.FOR):
			if first is StarredExpr:
				report.error("SyntaxError: iterable unpacking cannot be used in comprehension")
				return null
			var clauses = _parse_comp_clauses(false)
			if clauses == null:
				return null
			var rbracket = consume(TokenType.RBRACKET, "Expected ']'")
			if rbracket == null:
				return null
			var list_comp = ListComp.new(first, clauses)
			if not _check_comp_walrus(list_comp):
				return null
			return list_comp
		else:
			var elems = [first]
			while match_types([TokenType.COMMA]):
				if check(TokenType.RBRACKET):
					break
				var elem = _parse_star_or_simple()
				if report.has_error:
					return null
				elems.append(elem)
			var rbracket = consume(TokenType.RBRACKET, "Expected ']'")
			if rbracket == null:
				return null
			return ListLiteral.new(elems)
			
	## 解析字典字面量或字典推导式 [br]
	## 空花括号返回空字典, 有 for 则解析为字典推导式, 否则解析普通字典 [br]
	## [returns] 解析出的 DictLiteral 或 DictComp 节点
	func parse_dict_or_dictcomp():
		if check(TokenType.RBRACE):
			advance()
			return DictLiteral.new([], [])
		
		# 首个条目为 **mapping 解包 (一定是字典字面量)
		if check(TokenType.STARSTAR):
			advance()
			var ue = or_expr()
			if report.has_error:
				return null
			var keys = [null]
			var values = [ue]
			var star_flags = [true]
			while match_types([TokenType.COMMA]):
				if check(TokenType.RBRACE):
					break
				if match_types([TokenType.STARSTAR]):
					var ue2 = or_expr()
					if report.has_error:
						return null
					keys.append(null)
					values.append(ue2)
					star_flags.append(true)
				else:
					var k = simple_expression()
					if report.has_error:
						return null
					var colon2 = consume(TokenType.COLON, "Expected ':'")
					if colon2 == null:
						return null
					var v = simple_expression()
					if report.has_error:
						return null
					keys.append(k)
					values.append(v)
					star_flags.append(false)
			var rbrace = consume(TokenType.RBRACE, "Expected '}'")
			if rbrace == null:
				return null
			return DictLiteral.new(keys, values, star_flags)
		
		# 首个条目为 * 解包: 一定是集合字面量 ({*a, 1})
		if check(TokenType.STAR):
			var star_first = _parse_star_or_simple()
			if report.has_error:
				return null
			var star_elems = [star_first]
			while match_types([TokenType.COMMA]):
				if check(TokenType.RBRACE):
					break
				var star_elem = _parse_star_or_simple()
				if report.has_error:
					return null
				star_elems.append(star_elem)
			var star_rbrace = consume(TokenType.RBRACE, "Expected '}'")
			if star_rbrace == null:
				return null
			return SetLiteral.new(star_elems)

		var first = simple_expression()
		if report.has_error:
			return null
		# 集合字面量: 元素后无冒号 (如 {1, 2, 3} 或 {1})
		if not check(TokenType.COLON):
			# 集合推导式: {expr for var in iterable [if cond]} (支持多 for 与多 if)
			if check(TokenType.FOR):
				var clauses = _parse_comp_clauses(false)
				if clauses == null:
					return null
				var comp_rbrace = consume(TokenType.RBRACE, "Expected '}'")
				if comp_rbrace == null:
					return null
				var set_comp = SetComp.new(first, clauses)
				if not _check_comp_walrus(set_comp):
					return null
				return set_comp
			var elems = [first]
			while match_types([TokenType.COMMA]):
				if check(TokenType.RBRACE):
					break
				var elem = _parse_star_or_simple()
				if report.has_error:
					return null
				elems.append(elem)
			var set_rbrace = consume(TokenType.RBRACE, "Expected '}'")
			if set_rbrace == null:
				return null
			return SetLiteral.new(elems)
		# 字典字面量或字典推导式
		var key_expr = first
		var colon = consume(TokenType.COLON, "Expected ':'")
		if colon == null:
			return null
		var value_expr = simple_expression()
		if report.has_error:
			return null
			
		if check(TokenType.FOR):
			var clauses = _parse_comp_clauses(true)
			if clauses == null:
				return null
			var rbrace = consume(TokenType.RBRACE, "Expected '}'")
			if rbrace == null:
				return null
			var dict_comp = DictComp.new(key_expr, value_expr, clauses)
			if not _check_comp_walrus(dict_comp):
				return null
			return dict_comp
		else:
			var keys = [key_expr]
			var values = [value_expr]
			var star_flags = [false]
			while match_types([TokenType.COMMA]):
				if check(TokenType.RBRACE):
					break
				# **mapping 解包条目
				if match_types([TokenType.STARSTAR]):
					var ue = or_expr()
					if report.has_error:
						return null
					keys.append(null)
					values.append(ue)
					star_flags.append(true)
				else:
					key_expr = simple_expression()
					if report.has_error:
						return null
					colon = consume(TokenType.COLON, "Expected ':'")
					if colon == null:
						return null
					value_expr = simple_expression()
					if report.has_error:
						return null
					keys.append(key_expr)
					values.append(value_expr)
					star_flags.append(false)
			var rbrace = consume(TokenType.RBRACE, "Expected '}'")
			if rbrace == null:
				return null
			return DictLiteral.new(keys, values, star_flags)
	
	## 解析下标赋值目标的后续部分: 消费 [ ... ] (可连续, 支持 a[i][j]) [br]
	## [param base] 已解析的基础表达式 [br]
	## [returns] SubscriptTarget 链末端节点; 出错时返回 null
	func _parse_subscript_target(base):
		var target = base
		while true:
			if check(TokenType.LBRACKET):
				advance()
				if check(TokenType.RBRACKET):
					report.error("Invalid assignment target")
					return null
				var index_expr = simple_expression()
				if index_expr == null:
					return null
				var rb = consume(TokenType.RBRACKET, "Expected ']' after subscript target")
				if rb == null:
					return null
				target = SubscriptTarget.new(target, index_expr)
				continue
			if check(TokenType.DOT):
				# 下标后接属性 (如 a[0].x): 继续消费为 AttrTarget
				target = _parse_attr_target(target)
				if target == null:
					return null
				continue
			break
		return target
	
	## 解析属性赋值目标的后续部分: 消费 .name (可连续, 支持 a.b.c) [br]
	## [param base] 已解析的基础表达式 [br]
	## [returns] AttrTarget 链末端节点; 出错时返回 null
	func _parse_attr_target(base):
		var target = base
		while true:
			if check(TokenType.DOT):
				advance()
				var name_tok = consume(TokenType.IDENTIFIER, "Expected attribute name after '.'")
				if name_tok == null:
					return null
				target = AttrTarget.new(target, name_tok.lexeme)
				continue
			if check(TokenType.LBRACKET):
				# 属性后接下标 (如 self._data[name]): 继续消费为 SubscriptTarget
				target = _parse_subscript_target(target)
				if target == null:
					return null
				continue
			break
		return target
	
	## 解析一个解包目标 (变量, 括号嵌套, 星号前缀, 或下标/属性目标) [br]
	## 支持 Variable, UnpackTarget (括号/方括号嵌套), StarredTarget (星号前缀), [br]
	## 以及后缀形式的下标/属性目标 (a[0] / o.x, 用于多重赋值) [br]
	## [returns] 解析出的目标节点
	func parse_target():
		if match_types([TokenType.STAR]):
			if not check(TokenType.IDENTIFIER):
				report.error("Expected identifier after '*'")
				return null
			var var_name = advance().lexeme
			return StarredTarget.new(Variable.new(var_name))
		if match_types([TokenType.IDENTIFIER]):
			var name = previous().lexeme
			# 后缀形式的下标/属性目标 (如 a[0] / o.x): 消费后缀并返回对应目标节点
			if check(TokenType.LBRACKET):
				return _parse_subscript_target(Variable.new(name))
			if check(TokenType.DOT):
				return _parse_attr_target(Variable.new(name))
			return Variable.new(name)
		if match_types([TokenType.LPAREN]):
			var inner_targets = parse_target_list()
			var rparen = consume(TokenType.RPAREN, "Expected ')'")
			if rparen == null:
				return null
			return UnpackTarget.new(inner_targets)
		if match_types([TokenType.LBRACKET]):
			var inner_targets = parse_target_list()
			var rbracket = consume(TokenType.RBRACKET, "Expected ']'")
			if rbracket == null:
				return null
			return UnpackTarget.new(inner_targets)
		return null
		
	## 解析逗号分隔的目标列表 [br]
	## 用于解包赋值左侧, 检测多个星号目标的语法错误 [br]
	## [returns] 目标节点数组 (实际类型 Array[Variable/UnpackTarget/StarredTarget])
	func parse_target_list() -> Array:
		var targets = []
		var has_star = false
		while true:
			var target = parse_target()
			if target == null:
				break
			if target is StarredTarget:
				if has_star:
					report.error("Multiple starred targets in assignment")
				has_star = true
			targets.append(target)
			if not match_types([TokenType.COMMA]):
				break
		return targets
	
	## 解析简单表达式: 无逗号, 无语句级赋值语义, 用于列表元素/字典键值/函数实参/索引/条件表达式等 [br]
	## 从三目表达式开始解析, 并支持赋值表达式 walrus (x := 1) [br]
	## [returns] 解析出的 Expr 节点 (可能是 WalrusExpr), 出错时返回 null
	func simple_expression() -> Expr:
		var expr = conditional_expression()
		if report.has_error or expr == null:
			return null
		if match_types([TokenType.COLON_EQ]):
			# 赋值表达式: 目标必须是简单变量名 (与 Python 一致)
			if expr is GetAttr:
				report.error("SyntaxError: cannot use assignment expressions with attribute")
				return null
			if expr is GetItem:
				report.error("SyntaxError: cannot use assignment expressions with subscript")
				return null
			if not expr is Variable:
				report.error("SyntaxError: invalid syntax")
				return null
			var walrus_value = conditional_expression()
			if report.has_error or walrus_value == null:
				return null
			return WalrusExpr.new(expr.name, walrus_value)
		return expr
		
	## 元组表达式 (允许逗号序列), 用于顶层表达式语句, 赋值右侧, return 之后 [br]
	## 如果遇到逗号, 则将多个表达式打包为 TupleLiteral (元素可为 * 解包) [br]
	## [returns] 解析出的 Expr 节点 (可能是 TupleLiteral), 出错时返回 null
	func tuple_expression() -> Expr:
		var first = _parse_star_or_simple()
		if first == null or report.has_error:
			return null
		# 裸 *expr 仅在有逗号构成元组时合法 (与 Python 一致)
		if first is StarredExpr and not check(TokenType.COMMA):
			report.error("SyntaxError: can't use starred expression here")
			return null
		if match_types([TokenType.COMMA]):
			var elements = [first]
			while not check(TokenType.NEWLINE) and not check(TokenType.EOF) and not check(TokenType.RPAREN) and not check(TokenType.RBRACKET) and not check(TokenType.RBRACE):
				var elem = _parse_star_or_simple()
				if elem == null or report.has_error:
					return null
				elements.append(elem)
				if not match_types([TokenType.COMMA]):
					break
			return TupleLiteral.new(elements)
		return first
	
	## 解析完整的表达式语句 (可能包含赋值, 类型注解或解包赋值) [br]
	## 自动检测解包赋值 (a, b = ...), 处理增强赋值 (+=, -= 等)和链式赋值 (a = b = value) [br]
	## 同时处理带类型注解的变量声明 (var: type [= value]) [br]
	## [returns] 解析出的 ExpressionStmt 节点, 出错时返回 null
	func expression_statement():
		# 处理带类型注释的变量声明 var : type [= value]
		if check(TokenType.IDENTIFIER):
			var lookahead = current + 1
			if lookahead < tokens.size() and tokens[lookahead].type == TokenType.COLON:
				var name_tok = consume(TokenType.IDENTIFIER, "Expected variable name")
				if name_tok == null:
					return null
				var colon = consume(TokenType.COLON, "Expected ':'")
				if colon == null:
					return null
				skip_type_annotation()
				if match_types([TokenType.EQUAL]):
					var value = tuple_expression()
					return ExpressionStmt.new(Assign.new(name_tok.lexeme, value))
				else:
					# 仅类型注解, 不产生任何语句
					skip_newlines()
					return null
		
		# 优先判断是否为解包赋
		if is_unpack_assignment():
			return parse_assignment_statement()
		
		var expr = tuple_expression()
		if report.has_error or expr == null:
			return null

		# 裸写赋值表达式作为语句 (如 x := 1) 与 Python 一致地报错, 带括号的 (x := 1) 合法
		if expr is WalrusExpr and not expr.has_meta("parenthesized"):
			report.error("SyntaxError: invalid syntax")
			return null

		# 增强赋值 x += 1, x -= 2, x *= 3, x /= 4, x //= 5, x **= 6, x %= 7, x |= 8
		if match_types([TokenType.PLUS_EQ, TokenType.MINUS_EQ, TokenType.STAR_EQ, TokenType.SLASH_EQ, TokenType.DOUBLESLASH_EQ, TokenType.STARSTAR_EQ, TokenType.PERCENT_EQ, TokenType.PIPE_EQ]):
			var op = previous()
			var value = tuple_expression()
			if value == null:
				return null
			if expr is Variable:
				return ExpressionStmt.new(AugAssign.new(expr.name, op, value))
			elif expr is GetItem:
				return ExpressionStmt.new(AugAssignItem.new(expr.object, expr.index, op, value))
			elif expr is GetAttr:
				return ExpressionStmt.new(AugAssignAttr.new(expr.object, expr.name, op, value))
			else:
				report.error("Invalid augmented assignment target")
				return null
		
		if match_types([TokenType.EQUAL]):
			# 收集赋值目标链 (支持 a = b = value)
			var targets = [expr]
			while true:
				var rhs = tuple_expression()
				if match_types([TokenType.EQUAL]):
					# rhs 变成新的赋值目标
					if rhs is Variable or rhs is GetItem or rhs is GetAttr:
						targets.append(rhs)
					else:
						report.error("Invalid assignment target")
						return null
				else:
					# 最终的右侧
					var value = rhs
					# 从右向左嵌套生成 Assign / SetItem
					var assign_expr: Expr = value
					for i in range(targets.size() - 1, -1, -1):
						var tgt = targets[i]
						if tgt is Variable:
							assign_expr = Assign.new(tgt.name, assign_expr)
						elif tgt is GetItem:
							assign_expr = SetItem.new(tgt.object, tgt.index, assign_expr)
						elif tgt is GetAttr:
							assign_expr = SetAttr.new(tgt.object, tgt.name, assign_expr)
						else:
							report.error("Invalid assignment target")
							return null
					return ExpressionStmt.new(assign_expr)
		else:
			return ExpressionStmt.new(expr)
	
	## 跳过类型注释, 直到遇到终止标记 (等号, 逗号, 右括号, 冒号, 换行) [br]
	## 处理嵌套的方括号和圆括号, 确保复杂类型注解 (如 list[int])被正确跳过
	func skip_type_annotation():
		var depth = 0
		while not is_at_end():
			var t = peek()
			if depth == 0:
				if t.type == TokenType.EQUAL or t.type == TokenType.COMMA or t.type == TokenType.RPAREN or t.type == TokenType.COLON or t.type == TokenType.NEWLINE:
					break
			if t.type == TokenType.LBRACKET or t.type == TokenType.LPAREN:
				depth += 1
				advance()
			elif t.type == TokenType.RBRACKET or t.type == TokenType.RPAREN:
				if depth > 0:
					depth -= 1
					advance()
				else:
					break
			else:
				advance()
				
	## 平衡地跳过 Token 直到遇到 stop_types 中的任意类型 [br]
	## 正确处理嵌套的括号 ((), [], {}), 避免在不平衡时提前停止 [br]
	## [param stop_types] 停止 Token 类型数组
	func skip_until_balanced(stop_types: Array):
		var depth = 0
		while not is_at_end():
			var t = peek()
			if depth == 0:
				for stop_type in stop_types:
					if t.type == stop_type:
						return
			if t.type == TokenType.LPAREN or t.type == TokenType.LBRACKET or t.type == TokenType.LBRACE:
				depth += 1
				advance()
			elif t.type == TokenType.RPAREN or t.type == TokenType.RBRACKET or t.type == TokenType.RBRACE:
				if depth > 0:
					depth -= 1
					advance()
				else:
					advance()
			else:
				advance()
	
	## 跳过成对的括号内容, 返回结束括号的后一个位置 [br]
	## 用于在 Token 序列中查找配对括号的结束位置 [br]
	## [param start_idx] 开始括号的索引位置 [br]
	## [param close_type] 结束括号的 TokenType [br]
	## [returns] 结束括号之后的下一个索引位置
	func _skip_parens(start_idx: int, open_type: int, close_type: int) -> int:
		var i = start_idx + 1
		var depth = 1
		while i < tokens.size() and depth > 0:
			if tokens[i].type == open_type:
				depth += 1
			elif tokens[i].type == close_type:
				depth -= 1
			i += 1
		return i
	
	## 判断当前 token 序列是否为解包赋值目标 [br]
	## 向前扫描 Token 流, 检测是否有逗号, 星号, 括号等解包特征, 以及等号 [br]
	## [returns] 如果当前序列是解包赋值模式则返回 true
	func is_unpack_assignment() -> bool:
		var idx = current
		var has_target = false
		var has_comma_or_star_or_paren = false
		# 括号嵌套深度
		var depth = 0
		
		while idx < tokens.size():
			var t = tokens[idx]
			
			# 换行处理
			if t.type == TokenType.NEWLINE:
				if depth == 0:
					return false
				idx += 1
				continue
				
			# 下标后缀 (紧跟在目标之后, 如 a[0] 的 [0]): 整体跳过配对括号,
			# 其内容属于目标表达式而非独立的解包目标
			if t.type == TokenType.LBRACKET and has_target:
				idx = _skip_parens(idx, TokenType.LBRACKET, TokenType.RBRACKET)
				has_comma_or_star_or_paren = true
				continue
			
			# 开括号: 增加深度, 根据不同情况设置标志
			if t.type == TokenType.LPAREN or t.type == TokenType.LBRACKET:
				if has_target:
					depth += 1
					idx += 1
					continue
				else:
					has_target = true
					has_comma_or_star_or_paren = true
					depth += 1
					idx += 1
					continue
					
			# 闭括号: 减少深度
			if t.type == TokenType.RPAREN or t.type == TokenType.RBRACKET:
				depth -= 1
				idx += 1
				continue
				
			# 花括号不是解包目标, 直接返回 false (脚本中不会出现 {} 作为目标)
			if t.type == TokenType.LBRACE or t.type == TokenType.RBRACE:
				return false
				
			# 标识符
			if t.type == TokenType.IDENTIFIER:
				has_target = true
				idx += 1
				continue
				
			# 星号 (前面不能有未用逗号分隔的目标)
			if t.type == TokenType.STAR:
				if has_target:
					return false
				if idx + 1 >= tokens.size() or tokens[idx + 1].type != TokenType.IDENTIFIER:
					return false
				has_target = true
				has_comma_or_star_or_paren = true
				idx += 2
				continue
			
			# 下标/属性后缀: 属于目标的一部分 (如 a[0] / o.x), 继续扫描其后缀与逗号
			if t.type == TokenType.DOT:
				if not has_target:
					return false
				has_comma_or_star_or_paren = true
				idx += 1
				continue
				
			# 逗号 (深度内也需重置 has_target)
			if t.type == TokenType.COMMA:
				if not has_target:
					return false
				has_target = false
				has_comma_or_star_or_paren = true
				idx += 1
				continue
				
			# 等号 (深度内忽略)
			if t.type == TokenType.EQUAL:
				if depth > 0:
					idx += 1
					continue
				return idx > current and has_comma_or_star_or_paren
				
			# 其他 token (如运算符, 非解包特征)
			return false
		return false
		
	## 解析解包赋值语句 (左侧 * 或嵌套括号) [br]
	## 如果只有一个普通变量目标则退化为 Assign, 否则生成 UnpackAssign [br]
	## [returns] 解析出的 ExpressionStmt 节点 (内含 Assign 或 UnpackAssign)
	func parse_assignment_statement() -> ExpressionStmt:
		var targets = parse_target_list()
		if targets.size() == 0:
			report.error("Invalid unpacking target")
			return null
		var eq = consume(TokenType.EQUAL, "Expected '='")
		if eq == null:
			return null
		var value = tuple_expression()
		if report.has_error:
			return null
		if targets.size() == 1 and targets[0] is Variable:
			return ExpressionStmt.new(Assign.new(targets[0].name, value))
		elif targets.size() == 1 and targets[0] is SubscriptTarget:
			# 单一下标目标 (a[i] = v): 退化为 SetItem, 与普通赋值一致
			var st = targets[0] as SubscriptTarget
			return ExpressionStmt.new(SetItem.new(st.object, st.index, value))
		elif targets.size() == 1 and targets[0] is AttrTarget:
			# 单一属性目标 (o.x = v): 退化为 SetAttr
			var at = targets[0] as AttrTarget
			return ExpressionStmt.new(SetAttr.new(at.object, at.name, value))
		else:
			return ExpressionStmt.new(UnpackAssign.new(targets, value))
		
## 解释器, 遍历 AST 并执行, 通过对象模型进行多态计算 [br]
## 任何可能出错的方法在出错时返回 null (若返回 DSLNone 则代表其是预期结果)
class Interpreter:
	## None 单例缓存, 确保 is 语义正确
	static var _cached_none: DSLNone
	## True 单例缓存, 确保 is 语义正确
	static var _cached_true: DSLBool
	## False 单例缓存, 确保 is 语义正确
	static var _cached_false: DSLBool
	## 内置类型 proto 缓存, 防止 _inject_builtin_methods 中的 Callable 引用的 proto 被 GC
	static var _builtin_protos: Dictionary = {}

	## 执行结果枚举, 用于控制流程跳转
	enum ExecResult {
		NORMAL,
		RETURN,
		BREAK,
		CONTINUE,
		ERROR,
		RAISE,
		SUSPENDED
	}

	## 控制台报告器
	var report: ConsoleReport
	## 全局作用域
	var globals: DSLEnvironment
	## 当前作用域
	var environment: DSLEnvironment
	## 外部 API 注册
	var api_funcs: Dictionary[String, Callable] = {}
	## 最大执行步数, 防止无限循环
	var max_steps: int = 50000
	## 当前已执行步数计数器
	var step_count: int = 0
	## 存储最近的 return 值
	var return_value: DSLObject = null
	## 最近抛出的异常
	var last_exception = null
	## 异常继承层级: type_name -> base_name, 用于 isinstance 检查
	var exception_hierarchy: Dictionary[String, String] = {}
	## 执行栈 (exec_block 递归层级追踪)
	var _exec_stack: Array = []
	## 函数调用栈
	var _call_stack: Array = []
	## 挂起标志位 (是否已挂起)
	var _suspended: bool = false
	## 表达式求值完成标志 (区分 sleep() 已求值 vs 函数调用未求值)
	var _expr_evaluated: bool = false
	## 挂起类型 (false = SLEEPING(自动恢复) / true = WAITING(手动恢复))
	var _is_waiting: bool = false
	## 挂起原因枚举: 用于区分程序挂起 (sleep/waiting) 与生成器 yield
	enum SuspendReason {
		NONE = 0,
		SLEEPING = 1,
		WAITING = 2,
		YIELD = 3
	}
	## 当前挂起原因 (见 SuspendReason)
	var _suspend_reason: int = SuspendReason.NONE
	## 内置类型的类对象 (名称 -> DSLClass): 用于 type() 返回等场景 [br]
	## 主要覆盖那些名字被内置函数占用的类型 (如 range)
	var _builtin_type_classes: Dictionary = {}
	## 当前正在执行步骤的生成器 (生成器体内 yield 定位与 sleep 拦截用)
	var _current_generator = null
	## 当前语句是否含 yield 表达式 (由 execute 置位): [br]
	## 生成器侧的跨 yield 子表达式记忆仅在该条件下启用, 避免干扰 sleep 重放
	var _stmt_has_yield: bool = false
	## 本次执行是否发生过未捕获的致命错误 (宿主据此进入 ERROR 终态)
	var _had_fatal_error: bool = false
	## 本轮重放已遇到的睡眠序号 (每次挂起后归零, 下一轮从 0 重新计数)
	var _sleep_seq: int = 0
	## 已确认等待完成的睡眠数 (跨轮累计): 对应序号 < 它的睡眠在本轮立即返回, 不重复等待
	var _sleep_skip: int = 0
	## 本轮已真正发起等待的睡眠数 (挂起时累加进 _sleep_skip)
	var _sleep_waited: int = 0
	## 重放根语句标识 (该语句正常结束时睡眠计数全部归零)
	var _sleep_root_key: int = 0
	## 当前正在执行的语句节点标识 (消费窗口按语句隔离)
	var _current_stmt_key: int = 0
	## 消费过程中发生挂起 (语句必须整体重放, 不能视为已完成)
	var _needs_replay: bool = false
	## 生成器创建记忆表: 语句标识 -> { 表达式标识 -> [第1个生成器, 第2个...] } [br]
	## 语句重放时按出现次序复用同一批生成器 (否则会重新创建, 丢失已推进的进度)
	var _gen_memo: Dictionary = {}
	## 本轮各生成器表达式的出现计数: 语句标识 -> { 表达式标识 -> int }
	var _gen_occur: Dictionary = {}
	## 当前正在求值的调用表达式节点 (生成器函数调用需要它做记忆键)
	var _current_call_node = null
	## 语句消费窗口登记表: 语句标识 -> 该语句消费过的一次性迭代器数组 [br]
	## 语句被挂起重放时, 把这些迭代器的读取游标退回各自窗口起点, 使消费方重读相同序列
	var _stmt_iterators: Dictionary = {}
	## 当前执行语句的行号 (运行时错误定位)
	var _current_line: int = 0
	## 当前正在执行的方法所属的类 (super() 定位)
	var _current_class: DSLClass = null
	## 当前正在执行的方法的 self/cls (super() 定位)
	var _current_self: DSLObject = null
	## 内置模块注册表, Key 为模块名
	var modules: Dictionary[String, DSLModule] = {}
	## random 模块的伪随机数生成器状态
	var _rng_state: int = 1
	## PyGDS 宿主引用
	var owner: PyGDS = null
	
	## 构造解释器实例 [br]
	## [param p_reporter] 控制台报告器 [br]
	## [param p_api] 外部 API 函数注册
	func _init(p_reporter: ConsoleReport, p_api: Dictionary[String, Callable] = {}):
		report = p_reporter
		api_funcs = p_api
		globals = DSLEnvironment.new(report)
		environment = globals
		register_builtins()
	
	## 比对两次调用的实参是否一致 (按对象身份) [br]
	## 用于判断保存的挂起帧能否被当前调用复用: 参数不同说明是另一次调用, 不能复用旧环境 [br]
	## [param a] 保存帧的实参数组 [br]
	## [param b] 当前调用的实参数组 [br]
	## [returns] 数量与每个参数的对象身份都一致时返回 true
	func _args_match(a, b) -> bool:
		if not (a is Array) or not (b is Array):
			return false
		if a.size() != b.size():
			return false
		for i in range(a.size()):
			if not _arg_value_eq(a[i], b[i]):
				return false
		return true

	## 判断实参在语句重放前后是否「同一个值」 [br]
	## 重放会重新求值实参表达式，因此像 f(C(1)) 里的 C(1) 会产生结构相同但身份不同的新实例； [br]
	## 此处按值/结构逐层比较，使这类调用能匹配到已挂起的帧 [br]
	## 不使用用户 __eq__: 它可能带副作用或侧效应, 不适合在内部匹配时调用 [br]
	## [param x] 保存帧中的实参 [br]
	## [param y] 当前调用的实参 [br]
	## [param depth] 剩余递归层数 (防止循环引用) [br]
	## [returns] 视为同一个值时返回 true
	func _arg_value_eq_replay(x, y, depth: int = 4) -> bool:
		if x == null or y == null:
			return x == y
		if _arg_value_eq(x, y):
			return true
		if depth <= 0:
			return false
		if x is DSLList and y is DSLList:
			return _arg_seq_eq(x.items, y.items, depth - 1)
		if x is DSLTuple and y is DSLTuple:
			return _arg_seq_eq(x.items, y.items, depth - 1)
		if x is DSLDict and y is DSLDict:
			if x.dict.size() != y.dict.size():
				return false
			for k in x.dict:
				if not y.dict.has(k):
					return false
				if not _arg_value_eq_replay(x.dict[k], y.dict[k], depth - 1):
					return false
			return true
		# 用户实例: 同类且字段集合与取值逐对相等时视为同一个值 [br]
		# 不调用用户 __eq__ (它可能带副作用或引起递归), 仅逐字段递归比较
		if x.klass != null and x.klass == y.klass and x.fields != null and y.fields != null:
			if x.fields.size() != y.fields.size():
				return false
			for f in x.fields:
				if not y.fields.has(f):
					return false
				if not _arg_value_eq_replay(x.fields[f], y.fields[f], depth - 1):
					return false
			return true
		return false

	## 逐个比较两个实参序列 [br]
	## [param a] 序列 A [br]
	## [param b] 序列 B [br]
	## [param depth] 剩余递归层数 [br]
	## [returns] 长度与逐个元素都相等时返回 true
	func _arg_seq_eq(a: Array, b: Array, depth: int) -> bool:
		if a.size() != b.size():
			return false
		for i in range(a.size()):
			if not _arg_value_eq_replay(a[i], b[i], depth):
				return false
		return true

	## 按结构比较两个实参序列 (供语句重放时匹配已挂起的帧) [br]
	## 仅用于重放轮: 实参可能是重新构造出的等值新实例 [br]
	## [param a] 保存帧的实参数组 [br]
	## [param b] 当前调用的实参数组 [br]
	## [returns] 数量与逐个参数都等值时返回 true
	func _args_match_structural(a, b) -> bool:
		if not (a is Array) or not (b is Array):
			return false
		if a.size() != b.size():
			return false
		for i in range(a.size()):
			if not _arg_value_eq_replay(a[i], b[i]):
				return false
		return true

	## 判断两个实参是否表示同一次调用的同一参数 [br]
	## 不可变字面量 (int/float/str/bool/None) 按值比较: 重放会重新求值字面量产生新对象 [br]
	## 其余对象按身份比较: 避免把不同的可变对象误判为同一次调用 [br]
	## [param x] 保存帧中的实参 [br]
	## [param y] 当前调用的实参 [br]
	## [returns] 视为同一实参时返回 true
	func _arg_value_eq(x, y) -> bool:
		if x == null or y == null:
			return x == y
		if x is DSLInteger and y is DSLInteger:
			return x.value == y.value
		if x is DSLFloat and y is DSLFloat:
			return x.value == y.value
		if x is DSLString and y is DSLString:
			return x.value == y.value
		if x is DSLBool and y is DSLBool:
			return x.value == y.value
		if x is DSLNone and y is DSLNone:
			return true
		return x == y

	## 取 None 单例, 必要时初始化缓存 [br]
	## 保证同一解释器内 None 的身份唯一 (`x is None` 依赖于此) [br]
	## [returns] DSLNone 单例
	func get_none() -> DSLNone:
		if _cached_none == null:
			_cached_none = DSLNone.new()
		return _cached_none

	## 抛出 DSL 异常, 设置 last_exception 并报告错误 [br]
	## 若已知当前语句行号, 会在错误消息后附加 "(line N)"
	func raise_exception(err_type: String, msg: String):
		var exc_class = globals.get_val(err_type)
		if exc_class is DSLClass:
			var exc_args: Array[DSLObject] = [DSLString.new(msg)]
			last_exception = exc_class.magic_call(exc_args, {})
		else:
			last_exception = DSLException.new(msg, err_type)
		var line_suffix = ""
		if _current_line > 0:
			line_suffix = " (line %d)" % _current_line
		report.error(err_type + ": " + msg + line_suffix)

	## 抛出携带 value 的 StopIteration (生成器 return 值) [br]
	## 异常实例的 args 为空, value 字段存入 return 值 (与 CPython 一致) [br]
	## [param value_obj] StopIteration.value 值
	func raise_stop_iteration_value(value_obj: DSLObject):
		var exc_class = globals.get_val("StopIteration")
		if exc_class is DSLClass:
			last_exception = exc_class.magic_call([], {})
			last_exception.fields["value"] = value_obj
			last_exception.fields["args"] = DSLTuple.new([])
		else:
			last_exception = DSLException.new("", "StopIteration")
		var line_suffix = ""
		if _current_line > 0:
			line_suffix = " (line %d)" % _current_line
		report.error("StopIteration: " + line_suffix)

	## 抛出已构造的异常实例 (throw/close 注入用) [br]
	## [param exc] 异常实例 (DSLException 或 DSLInstance wrapper)
	func raise_existing_exception(exc):
		var is_valid = false
		var err_type = ""
		var err_msg = ""
		if exc is DSLException:
			is_valid = true
			err_type = exc.error_type
			err_msg = exc.message
		elif exc.fields != null:
			var exc_type = globals.get_val_safe("Exception")
			if exc_type is DSLClass and exc._is_subclass_of_klass(exc_type):
				is_valid = true
			elif _is_registered_exception_instance(exc):
				is_valid = true
			if is_valid:
				err_type = exc._type_name()
				if exc._wrapped != null and exc._wrapped is DSLException:
					err_msg = exc._wrapped.message
				elif exc.fields.has("args") and exc.fields["args"] is DSLTuple and exc.fields["args"].items.size() > 0:
					err_msg = exc.fields["args"].items[0]._dsl_str()
		if is_valid:
			last_exception = exc
			report.error(err_type + ": " + err_msg)
		else:
			raise_exception("TypeError", "exceptions must derive from Exception")

	## 判断对象是否为已注册异常类的实例 [br]
	## 覆盖不继承 Exception 的内置异常 (如 GeneratorExit, 继承自 BaseException) [br]
	## [param exc] 对象 [br]
	## [returns] 是已注册异常类的实例时返回 true
	func _is_registered_exception_instance(exc) -> bool:
		if exc.klass == null:
			return false
		var c = exc.klass
		while c != null:
			if exception_hierarchy.has(c.name):
				return true
			c = c.superclass
		return false
		
	## 尝试调用实例类的 magic 方法, 失败时回退 fallback [br]
	## 用户魔术方法内部挂起 (sleep) 时返回 null 并把挂起标志向上传播, [br]
	## 此时不得回退到内置语义, 也不得让 fallback 覆盖掉真实结果 [br]
	## [param obj] 目标对象 [br]
	## [param method_name] magic 方法名称 [br]
	## [param extra_args] 额外参数 [br]
	## [param fallback] 回退回调, 返回 DSLObject
	func _call_magic_or_fallback(obj: DSLObject, method_name: String, extra_args: Array[DSLObject], fallback: Callable) -> DSLObject:
		if obj.klass != null:
			# 用户类未定义该魔术方法时 _dsl_getattribute 会报 AttributeError,
			# 此处静默回退到内置语义 (CPython 对未定义的魔术方法同样回退)
			var method: Variant = obj.klass._lookup_method(method_name)
			if method == null:
				return fallback.call()
			method = obj._dsl_getattribute(method_name)
			if method != null and not (method is DSLNone):
				var all_args: Array[DSLObject] = []
				all_args.append_array(extra_args)
				var result = obj.klass._invoke_func(method, all_args, {} as Dictionary[String, DSLObject])
				# 用户方法内发起程序挂起: 结果尚未产生, 交由上层语句重放;
				# 若继续回退, 基类的引用比较会静默给出错误答案
				if _suspended:
					return null
				if result != null:
					return result
			var class_method = obj.klass._lookup_method(method_name)
			if class_method != null:
				if class_method.has_method("__get__"):
					class_method = class_method.__get__(obj, obj.klass)
				var all_args: Array[DSLObject] = []
				all_args.append_array(extra_args)
				var result = obj.klass._invoke_func(class_method, all_args, {} as Dictionary[String, DSLObject])
				if _suspended:
					return null
				if result != null:
					return result
		return fallback.call()
	
	## 从带格式 last_error 字符串中抛出异常 [br]
	## 解析 "TypeName: message" 格式的错误字符串并抛出对应异常 [br]
	## message 已是最终显示文本 (各站点按 CPython 的 str 规则生成), 不再经 __init__ 加工 [br]
	## [param last_err] 格式为 "TypeName: message" 的错误字符串 [br]
	## [param args] 原始参数对象 (如 KeyError 的键), 使 e.args 与 repr 正确, 省略时用消息本身
	func raise_exception_from_last_error(last_err: String, args: Array[DSLObject] = []):
		var colon_idx = last_err.find(": ")
		var err_type = "RuntimeError"
		var msg = last_err
		if colon_idx != -1:
			err_type = last_err.substr(0, colon_idx)
			msg = last_err.substr(colon_idx + 2)
		var exc_args: Array[DSLObject] = args
		if exc_args.is_empty():
			exc_args = [DSLString.new(msg)] as Array[DSLObject]
		var exc_class = globals.get_val(err_type)
		if exc_class is DSLClass:
			last_exception = exc_class.magic_call([], {})
			var raw = last_exception._wrapped
			if raw is DSLException:
				raw.message = msg
				raw.args = exc_args
			last_exception.fields["args"] = DSLTuple.new(exc_args)
		else:
			last_exception = DSLException.new(msg, err_type)
		var line_suffix = ""
		if _current_line > 0:
			line_suffix = " (line %d)" % _current_line
		report.error(err_type + ": " + msg + line_suffix)
	
	## 注册内置异常类型 DSLClass [br]
	## 在全局作用域中定义异常 [br]
	## 并记录异常继承关系 [br]
	## [param type_name] 异常类型名称 [br]
	## [param base_name] 父异常类型名, 默认"Exception"
	func _define_exception(type_name: String, base_name: String = "Exception"):
		var base_class = null
		if base_name != "":
			base_class = globals.get_val(base_name)
		
		var methods = {}
		var obj_new = _make_builtin("__new__", Callable(self, "api_object_new"))
		if obj_new is DSLBuiltinFunction:
			methods["__new__"] = obj_new
		
		var init_desc = DSLMethodDescriptor.new("__init__", Callable(self, "_exception_init"))
		methods["__init__"] = init_desc
		
		var str_desc = DSLWrappedDescriptor.new("__str__", Callable(self, "_exception_str"))
		methods["__str__"] = str_desc
		
		var repr_desc = DSLWrappedDescriptor.new("__repr__", Callable(self, "_exception_repr"))
		methods["__repr__"] = repr_desc
		
		var class_obj = DSLClass.new(type_name, base_class, methods, self)
		globals.define(type_name, class_obj)
		exception_hierarchy[type_name] = base_name
	
	## 增强赋值计算, 根据运算符对 left/right 执行相应 dsl_* 操作 [br]
	## 根据运算符类型调用 left 的对应魔术方法计算增强赋值结果 [br]
	## 优先使用类定义的魔术方法, 失败时回退到默认 dsl_* 操作 [br]
	## [param left] 左操作数 [br]
	## [param op] 运算符 Token [br]
	## [param right] 右操作数 [br]
	## [returns] 计算结果, 不支持的运算符返回 null
	func _aug_assign_compute(left: DSLObject, op: Token, right: DSLObject) -> DSLObject:
		match op.type:
			TokenType.PLUS_EQ:
				return _call_magic_or_fallback(left, "__add__", [right], func(): return left.magic_add([left, right] as Array[DSLObject], {} as Dictionary[String, DSLObject]))
			TokenType.MINUS_EQ:
				return _call_magic_or_fallback(left, "__sub__", [right], func(): return left.magic_sub([left, right] as Array[DSLObject], {} as Dictionary[String, DSLObject]))
			TokenType.STAR_EQ:
				return _call_magic_or_fallback(left, "__mul__", [right], func(): return left.magic_mul([left, right] as Array[DSLObject], {} as Dictionary[String, DSLObject]))
			TokenType.SLASH_EQ:
				return _call_magic_or_fallback(left, "__truediv__", [right], func(): return left.magic_div([left, right] as Array[DSLObject], {} as Dictionary[String, DSLObject]))
			TokenType.DOUBLESLASH_EQ:
				return _call_magic_or_fallback(left, "__floordiv__", [right], func(): return left.magic_floordiv([left, right] as Array[DSLObject], {} as Dictionary[String, DSLObject]))
			TokenType.STARSTAR_EQ:
				return _call_magic_or_fallback(left, "__pow__", [right], func(): return left.magic_pow([left, right] as Array[DSLObject], {} as Dictionary[String, DSLObject]))
			TokenType.PERCENT_EQ:
				return _call_magic_or_fallback(left, "__mod__", [right], func(): return left.magic_mod([left, right] as Array[DSLObject], {} as Dictionary[String, DSLObject]))
			TokenType.PIPE_EQ:
				return _call_magic_or_fallback(left, "__or__", [right], func(): return left.magic_or([left, right] as Array[DSLObject], {} as Dictionary[String, DSLObject]))
			_:
				return null
	
	## 检查异常是否匹配 except 子句中指定的类型 [br]
	## [param exc] 被抛出的异常实例 [br]
	## [param type_expr] except 子句的类型表达式 [br]
	## [returns] 是否匹配
	func _is_exception_match(exc, type_expr) -> bool:
		if type_expr == null:
			return true
		var saved_has_error = report.has_error
		report.has_error = false
		var type_obj = evaluate(type_expr)
		report.has_error = saved_has_error
		if type_obj == null:
			return false
		if type_obj is DSLTuple:
			for item in type_obj.items:
				if item is DSLClass and exc.fields != null:
					if exc._is_subclass_of_klass(item):
						return true
			return false
		if not type_obj is DSLClass:
			return false
		if exc.fields != null:
			return exc._is_subclass_of_klass(type_obj)
		return false
	
	## 内置异常 __init__ 回调 [br]
	## 从参数中提取消息并构造 DSLException 存入 wrapper._wrapped [br]
	## [param exc_args] 异常构造函数参数, 首个为 DSLInstance wrapper [br]
	## [param _kwargs] 关键字参数 (未使用) [br]
	## [returns] DSLNone
	func _exception_init(exc_args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLObject:
		var wrapper = exc_args[0]
		var pos_args: Array[DSLObject] = []
		for i in range(1, exc_args.size()):
			pos_args.append(exc_args[i])
		var msg = _exception_message(wrapper.klass.name, pos_args)
		var exc = DSLException.new(msg, wrapper.klass.name, pos_args)
		wrapper._wrapped = exc
		wrapper.fields["args"] = DSLTuple.new(pos_args)
		return DSLNone.new()

	## 按 CPython 语义计算异常的 str() 结果 [br]
	## 无参数为空串, 多参数为参数元组的 repr, 单参数时 KeyError 用 repr, 其余用 str [br]
	## [param type_name] 异常类型名 [br]
	## [param pos_args] 构造参数 [br]
	## [returns] 异常消息
	func _exception_message(type_name: String, pos_args: Array[DSLObject]) -> String:
		if pos_args.size() == 0:
			return ""
		if pos_args.size() > 1:
			var tup = DSLTuple.new(pos_args)
			return tup._dsl_str()
		if type_name == "KeyError":
			return DSLObject._py_repr(pos_args[0])
		return pos_args[0]._dsl_str()
	
	## 内置 object.__init__ 回调 [br]
	## 默认无操作, 仅返回 DSLNone [br]
	## [param args] 初始化参数 (首项为 DSLInstance wrapper) [br]
	## [param _kwargs] 关键字参数 (未使用) [br]
	## [returns] DSLNone
	func _object_init(_args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLObject:
		return DSLNone.new()
	
	## 内置 object.__setattr__ 回调 [br]
	## 直接设置实例字段, 绕过类级别的 __setattr__ 方法 [br]
	## [param args] [self, name, value] [br]
	## [param _kwargs] 关键字参数 (未使用) [br]
	## [returns] DSLNone
	func _object_setattr(args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLObject:
		var self_obj = args[0]
		var name_obj = args[1]
		var value = args[2]
		var name = name_obj.value if name_obj is DSLString else name_obj._dsl_str()
		if self_obj.fields != null:
			self_obj.fields[name] = value
		return DSLNone.new()
	
	## 内置 object.__delattr__ 回调 [br]
	## 直接删除实例字段, 绕过类级别的 __delattr__ 方法 [br]
	## [param args] [self, name] [br]
	## [param _kwargs] 关键字参数 (未使用) [br]
	## [returns] DSLNone
	func _object_delattr(args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLObject:
		var self_obj = args[0]
		var name_obj = args[1]
		var name = name_obj.value if name_obj is DSLString else name_obj._dsl_str()
		if self_obj.fields != null and self_obj.fields.has(name):
			self_obj.fields.erase(name)
			return DSLNone.new()
		raise_exception("AttributeError", name)
		return null
	
	## 内置异常 __str__ 回调 [br]
	## [param exc_args] 异常参数, 首个为 wrapper 实例 [br]
	## [param _kwargs] 关键字参数 (未使用) [br]
	## [returns] 异常的字符串表示
	func _exception_str(exc_args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLObject:
		var wrapper = exc_args[0]
		var raw = wrapper._wrapped
		if raw and raw is DSLException:
			return DSLString.new(raw._dsl_str())
		return DSLString.new(wrapper._type_name())

	## 内置异常 __repr__ 回调 [br]
	## 与 CPython 一致: 类型名后跟参数 repr, 如 KeyError('b') / ValueError() [br]
	## [param exc_args] 异常参数, 首个为 wrapper 实例 [br]
	## [param _kwargs] 关键字参数 (未使用) [br]
	## [returns] 异常的 repr 字符串
	func _exception_repr(exc_args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLObject:
		var wrapper = exc_args[0]
		var type_name = wrapper._type_name()
		var pos_args: Array[DSLObject] = []
		if wrapper._wrapped != null and wrapper._wrapped is DSLException:
			pos_args = wrapper._wrapped.args
		elif wrapper.fields != null and wrapper.fields.has("args") and wrapper.fields["args"] is DSLTuple:
			pos_args = wrapper.fields["args"].items
		var parts = ""
		for i in range(pos_args.size()):
			if i > 0:
				parts += ", "
			parts += DSLObject._py_repr(pos_args[i])
		return DSLString.new(type_name + "(" + parts + ")")
		
	## 注册内置类型, 函数与异常到全局作用域 [br]
	## 创建 object/type/int/float/str/list/tuple/dict/bool 类型类, [br]
	## 注入对应魔术方法描述符与内置方法, [br]
	## 注册内置函数 (print/len/range/type/id 等) 及 API 函数, [br]
	## 定义内置异常继承层级
	func register_builtins():
		# Programmatic built-in type class registration
		# Create object class (user class base, still uses api_object_new + _object_init)
		var obj_methods = {}
		obj_methods["__new__"] = _make_builtin("__new__", Callable(self, "api_object_new"))
		var obj_init_desc = DSLMethodDescriptor.new("__init__", Callable(self, "_object_init"))
		obj_methods["__init__"] = obj_init_desc
		var obj_setattr_desc = DSLMethodDescriptor.new("__setattr__", Callable(self, "_object_setattr"))
		obj_methods["__setattr__"] = obj_setattr_desc
		var obj_delattr_desc = DSLMethodDescriptor.new("__delattr__", Callable(self, "_object_delattr"))
		obj_methods["__delattr__"] = obj_delattr_desc
		var obj_class = DSLClass.new("object", null, obj_methods, self)
		globals.define("object", obj_class)
		
		var type_methods = {}
		type_methods["__new__"] = _make_builtin("__new__", Callable(self, "api_object_new"))
		var type_class = DSLClass.new("type", obj_class, type_methods, self)
		obj_class.klass = type_class
		type_class.klass = type_class
		
		# Create int class: __new__ returns DSLInteger directly
		var int_methods = {}
		int_methods["__new__"] = _make_builtin("__new__", Callable(self, "api_int_new"))
		var int_class = DSLClass.new("int", obj_class, int_methods, self)
		int_class.klass = type_class
		_inject_builtin_methods(int_class, "int")
		globals.define("int", int_class)
		
		# Create float class: __new__ returns DSLFloat directly
		var float_methods = {}
		float_methods["__new__"] = _make_builtin("__new__", Callable(self, "api_float_new"))
		var float_class = DSLClass.new("float", obj_class, float_methods, self)
		float_class.klass = type_class
		_inject_builtin_methods(float_class, "float")
		globals.define("float", float_class)
		
		# Create str class: __new__ returns DSLString directly
		var str_methods = {}
		str_methods["__new__"] = _make_builtin("__new__", Callable(self, "api_str_new"))
		var str_class = DSLClass.new("str", obj_class, str_methods, self)
		str_class.klass = type_class
		_inject_builtin_methods(str_class, "str")
		globals.define("str", str_class)
		
		# Create list class: __new__ returns DSLList directly
		var list_methods = {}
		list_methods["__new__"] = _make_builtin("__new__", Callable(self, "api_list_new"))
		var list_class = DSLClass.new("list", obj_class, list_methods, self)
		list_class.klass = type_class
		_inject_builtin_methods(list_class, "list")
		globals.define("list", list_class)
		
		# Create tuple class: __new__ returns DSLTuple directly
		var tuple_methods = {}
		tuple_methods["__new__"] = _make_builtin("__new__", Callable(self, "api_tuple_new"))
		var tuple_class = DSLClass.new("tuple", obj_class, tuple_methods, self)
		tuple_class.klass = type_class
		_inject_builtin_methods(tuple_class, "tuple")
		globals.define("tuple", tuple_class)
		
		# Create dict class: __new__ returns DSLDict directly
		var dict_methods = {}
		dict_methods["__new__"] = _make_builtin("__new__", Callable(self, "api_dict_new"))
		var dict_class = DSLClass.new("dict", obj_class, dict_methods, self)
		dict_class.klass = type_class
		_inject_builtin_methods(dict_class, "dict")
		globals.define("dict", dict_class)
		
		# dict 视图类型 (dict_keys / dict_values): 仅用于 type() 返回与 isinstance 判定,
		# 其实例由 dict.keys() / dict.values() 直接构造
		var dict_keys_class = DSLClass.new("dict_keys", obj_class, {}, self)
		dict_keys_class.klass = type_class
		globals.define("dict_keys", dict_keys_class)
		var dict_values_class = DSLClass.new("dict_values", obj_class, {}, self)
		dict_values_class.klass = type_class
		globals.define("dict_values", dict_values_class)
		
		# Create bool class: __new__ returns DSLBool directly
		var bool_methods = {}
		bool_methods["__new__"] = _make_builtin("__new__", Callable(self, "api_bool_new"))
		var bool_class = DSLClass.new("bool", int_class, bool_methods, self)
		bool_class.klass = type_class
		_inject_builtin_methods(bool_class, "bool")
		globals.define("bool", bool_class)
		
		# Create NoneType class: __new__ returns DSLNone directly
		var nonetype_methods = {}
		nonetype_methods["__new__"] = _make_builtin("__new__", Callable(self, "api_none_new"))
		var nonetype_class = DSLClass.new("NoneType", obj_class, nonetype_methods, self)
		nonetype_class.klass = type_class
		globals.define("NoneType", nonetype_class)

		# Create set class: __new__ returns DSLSet directly
		var set_methods = {}
		set_methods["__new__"] = _make_builtin("__new__", Callable(self, "api_set_new"))
		var set_class = DSLClass.new("set", obj_class, set_methods, self)
		set_class.klass = type_class
		_inject_builtin_methods(set_class, "set")
		globals.define("set", set_class)

		# Create slice class: __new__ 返回 DSLSlice (slice(start, stop[, step]))
		var slice_methods = {}
		slice_methods["__new__"] = _make_builtin("__new__", Callable(self, "api_slice_new"))
		var slice_class = DSLClass.new("slice", obj_class, slice_methods, self)
		slice_class.klass = type_class
		globals.define("slice", slice_class)

		# Create frozenset class: __new__ returns DSLFrozenSet directly (不可变, 可哈希)
		var frozenset_methods = {}
		frozenset_methods["__new__"] = _make_builtin("__new__", Callable(self, "api_frozenset_new"))
		var frozenset_class = DSLClass.new("frozenset", obj_class, frozenset_methods, self)
		frozenset_class.klass = type_class
		_inject_builtin_methods(frozenset_class, "frozenset")
		globals.define("frozenset", frozenset_class)
		
		globals.define("len", _make_builtin("len", Callable(self, "builtin_len")))
		globals.define("range", _make_builtin("range", Callable(self, "builtin_range")))
		# range 名被内置函数占用 (须可调用), 其类型类另存供 type() 返回
		var rng_cls = DSLClass.new("range", obj_class, {}, self)
		rng_cls.klass = type_class
		_builtin_type_classes["range"] = rng_cls
		# bytes 同理: 字面量直接产出 DSLBytes, 类对象供 type() / isinstance 使用
		var bytes_cls = DSLClass.new("bytes", obj_class, {}, self)
		bytes_cls.klass = type_class
		_builtin_type_classes["bytes"] = bytes_cls
		globals.define("print", _make_builtin("print", Callable(self, "builtin_print")))
		globals.define("info", _make_builtin("info", Callable(self, "builtin_info")))
		globals.define("warn", _make_builtin("warn", Callable(self, "builtin_warn")))
		globals.define("warning", _make_builtin("warning", Callable(self, "builtin_warning")))
		globals.define("error", _make_builtin("error", Callable(self, "builtin_error")))
		globals.define("type", _make_builtin("type", Callable(self, "builtin_type")))
		globals.define("id", _make_builtin("id", Callable(self, "builtin_id")))
		globals.define("callable", _make_builtin("callable", Callable(self, "builtin_callable")))
		globals.define("input", _make_builtin("input", Callable(self, "builtin_input")))
		globals.define("round", _make_builtin("round", Callable(self, "builtin_round")))
		globals.define("repr", _make_builtin("repr", Callable(self, "builtin_repr")))
		globals.define("hash", _make_builtin("hash", Callable(self, "builtin_hash")))
		globals.define("abs", _make_builtin("abs", Callable(self, "builtin_abs")))
		globals.define("min", _make_builtin("min", Callable(self, "builtin_min")))
		globals.define("max", _make_builtin("max", Callable(self, "builtin_max")))
		globals.define("sum", _make_builtin("sum", Callable(self, "builtin_sum")))
		globals.define("pow", _make_builtin("pow", Callable(self, "builtin_pow")))
		globals.define("divmod", _make_builtin("divmod", Callable(self, "builtin_divmod")))
		globals.define("sorted", _make_builtin("sorted", Callable(self, "builtin_sorted")))
		globals.define("reversed", _make_builtin("reversed", Callable(self, "builtin_reversed")))
		globals.define("enumerate", _make_builtin("enumerate", Callable(self, "builtin_enumerate")))
		globals.define("iter", _make_builtin("iter", Callable(self, "builtin_iter")))
		globals.define("next", _make_builtin("next", Callable(self, "builtin_next")))
		globals.define("zip", _make_builtin("zip", Callable(self, "builtin_zip")))
		globals.define("any", _make_builtin("any", Callable(self, "builtin_any")))
		globals.define("all", _make_builtin("all", Callable(self, "builtin_all")))
		globals.define("ord", _make_builtin("ord", Callable(self, "builtin_ord")))
		globals.define("chr", _make_builtin("chr", Callable(self, "builtin_chr")))
		globals.define("hex", _make_builtin("hex", Callable(self, "builtin_hex")))
		globals.define("oct", _make_builtin("oct", Callable(self, "builtin_oct")))
		globals.define("bin", _make_builtin("bin", Callable(self, "builtin_bin")))
		globals.define("isinstance", _make_builtin("isinstance", Callable(self, "builtin_isinstance")))
		globals.define("issubclass", _make_builtin("issubclass", Callable(self, "builtin_issubclass")))
		globals.define("getattr", _make_builtin("getattr", Callable(self, "builtin_getattr")))
		globals.define("setattr", _make_builtin("setattr", Callable(self, "builtin_setattr")))
		globals.define("delattr", _make_builtin("delattr", Callable(self, "builtin_delattr")))
		globals.define("map", _make_builtin("map", Callable(self, "builtin_map")))
		globals.define("filter", _make_builtin("filter", Callable(self, "builtin_filter")))
		
		for name in api_funcs:
			globals.define(name, DSLBuiltinFunction.new(name, api_funcs[name]))
		
		_define_exception("Exception", "")
		_define_exception("TypeError")
		_define_exception("ValueError")
		_define_exception("RuntimeError")
		_define_exception("NameError")
		_define_exception("KeyError")
		_define_exception("IndexError")
		_define_exception("AttributeError")
		_define_exception("ArithmeticError")
		_define_exception("ZeroDivisionError", "ArithmeticError")
		_define_exception("StopIteration")
		_define_exception("GeneratorExit", "")
		_define_exception("AssertionError")
		_define_exception("EOFError")
		_define_exception("ImportError")
		_define_exception("StatisticsError", "ValueError")

		_register_modules()

	## 注册内置模块到模块注册表 [br]
	## import 语句通过 _get_module 解析这些模块
	func _register_modules():
		modules["math"] = _create_math_module()
		modules["random"] = _create_random_module()
		modules["statistics"] = _create_statistics_module()
		modules["functools"] = _create_functools_module()
		modules["itertools"] = _create_itertools_module()
		modules["collections"] = _create_collections_module()
		modules["string"] = _create_string_module()
		modules["operator"] = _create_operator_module()
		modules["time"] = _create_time_module()

	## 创建 time 模块 [br]
	## sleep 为协作式挂起 (不阻塞宿主), 其余函数对标 CPython 的 time 模块 [br]
	## [returns] DSLModule
	func _create_time_module() -> DSLModule:
		var mod = DSLModule.new("time")
		mod.members["sleep"] = _make_builtin("sleep", Callable(self, "_time_sleep"))
		mod.members["time"] = _make_builtin("time", Callable(self, "_time_time"))
		mod.members["time_ns"] = _make_builtin("time_ns", Callable(self, "_time_time_ns"))
		mod.members["monotonic"] = _make_builtin("monotonic", Callable(self, "_time_monotonic"))
		mod.members["monotonic_ns"] = _make_builtin("monotonic_ns", Callable(self, "_time_monotonic_ns"))
		mod.members["perf_counter"] = _make_builtin("perf_counter", Callable(self, "_time_monotonic"))
		mod.members["perf_counter_ns"] = _make_builtin("perf_counter_ns", Callable(self, "_time_monotonic_ns"))
		mod.members["process_time"] = _make_builtin("process_time", Callable(self, "_time_monotonic"))
		return mod

	## time.sleep(secs) — 协作式睡眠挂起 [br]
	## 挂起期间宿主继续运行, 超时后由宿主恢复执行 (不阻塞游戏) [br]
	## [param args] [secs] [br]
	## [param _kwargs] 关键字参数 (未使用) [br]
	## [returns] None
	func _time_sleep(args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLObject:
		if args.size() != 1:
			raise_exception("TypeError", "sleep() takes exactly 1 argument (%d given)" % args.size())
			return null
		var v = args[0]
		var secs = 0.0
		if v is DSLInteger:
			secs = float(v.value)
		elif v is DSLFloat:
			secs = v.value
		elif v is DSLBool:
			secs = 1.0 if v.value else 0.0
		else:
			raise_exception("TypeError", "'%s' object cannot be interpreted as an integer" % v._type_name())
			return null
		if secs < 0:
			raise_exception("ValueError", "sleep length must be non-negative")
			return null
		# 生成器步内部的 sleep: 生成器对象会被复用, 其进度由自身挂起状态保证,
		# 因此这里遇到的每个 sleep 都是「首次遇到」, 必须真正等待
		# (若按重放序号跳过, 会把生成器后续元素的等待错误地吃掉)
		if _current_generator != null:
			_suspended = true
			_is_waiting = false
			_suspend_reason = SuspendReason.SLEEPING
			if owner != null:
				owner.request_suspend_sleeping(secs)
			return get_none()
		# 语句级重放时的睡眠去重 (仅适用于语句自身表达式内的 sleep):
		# 同一轮重放内按遇到次序编号, 序号小于「已等待数」的睡眠立即返回 (已完成等待, 不重复等待)
		# 其余睡眠真正发起等待, 并在挂起时把本轮已等待数累加进 _sleep_skip, 供后续轮次跳过
		var sleep_idx = _sleep_seq
		_sleep_seq += 1
		if sleep_idx < _sleep_skip:
			return get_none()
		_sleep_waited += 1
		_suspended = true
		_is_waiting = false
		_suspend_reason = SuspendReason.SLEEPING
		if owner != null:
			owner.request_suspend_sleeping(secs)
		return get_none()

	## time.time() — 当前 Unix 时间戳 (秒) [br]
	## [param args] 无 [br]
	## [param _kwargs] 关键字参数 (未使用) [br]
	## [returns] DSLFloat
	func _time_time(args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLObject:
		if args.size() != 0:
			raise_exception("TypeError", "time.time() takes no arguments (%d given)" % args.size())
			return null
		return DSLFloat.new(Time.get_unix_time_from_system())

	## time.time_ns() — 当前 Unix 时间戳 (纳秒) [br]
	## [param args] 无 [br]
	## [param _kwargs] 关键字参数 (未使用) [br]
	## [returns] DSLInteger
	func _time_time_ns(args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLObject:
		if args.size() != 0:
			raise_exception("TypeError", "time.time_ns() takes no arguments (%d given)" % args.size())
			return null
		return DSLInteger.new(int(Time.get_unix_time_from_system() * 1000000000.0))

	## time.monotonic() / perf_counter() / process_time() — 单调递增时钟 (秒) [br]
	## 基于宿主引擎的运行时长, 不受系统时间调整影响 [br]
	## [param args] 无 [br]
	## [param _kwargs] 关键字参数 (未使用) [br]
	## [returns] DSLFloat
	func _time_monotonic(args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLObject:
		if args.size() != 0:
			raise_exception("TypeError", "monotonic() takes no arguments (%d given)" % args.size())
			return null
		return DSLFloat.new(Time.get_ticks_usec() / 1000000.0)

	## time.monotonic_ns() / perf_counter_ns() — 单调递增时钟 (纳秒) [br]
	## [param args] 无 [br]
	## [param _kwargs] 关键字参数 (未使用) [br]
	## [returns] DSLInteger
	func _time_monotonic_ns(args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLObject:
		if args.size() != 0:
			raise_exception("TypeError", "monotonic_ns() takes no arguments (%d given)" % args.size())
			return null
		return DSLInteger.new(int(Time.get_ticks_usec() * 1000))

	## 从模块注册表获取模块 [br]
	## [param name] 模块名 [br]
	## [returns] DSLModule 或 null
	func _get_module(name: String) -> DSLModule:
		if modules.has(name):
			return modules[name]
		return null

	## 创建 math 模块 [br]
	## [returns] DSLModule
	func _create_math_module() -> DSLModule:
		var mod = DSLModule.new("math")
		mod.members["pi"] = DSLFloat.new(PI)
		mod.members["e"] = DSLFloat.new(exp(1.0))
		mod.members["tau"] = DSLFloat.new(TAU)
		# 数学函数
		mod.members["sqrt"] = _make_builtin("sqrt", Callable(self, "_math_sqrt"))
		mod.members["isqrt"] = _make_builtin("isqrt", Callable(self, "_math_isqrt"))
		mod.members["floor"] = _make_builtin("floor", Callable(self, "_math_floor"))
		mod.members["ceil"] = _make_builtin("ceil", Callable(self, "_math_ceil"))
		mod.members["trunc"] = _make_builtin("trunc", Callable(self, "_math_trunc"))
		mod.members["fabs"] = _make_builtin("fabs", Callable(self, "_math_fabs"))
		mod.members["fmod"] = _make_builtin("fmod", Callable(self, "_math_fmod"))
		mod.members["pow"] = _make_builtin("pow", Callable(self, "_math_pow"))
		mod.members["exp"] = _make_builtin("exp", Callable(self, "_math_exp"))
		mod.members["log"] = _make_builtin("log", Callable(self, "_math_log"))
		mod.members["log2"] = _make_builtin("log2", Callable(self, "_math_log2"))
		mod.members["log10"] = _make_builtin("log10", Callable(self, "_math_log10"))
		mod.members["sin"] = _make_builtin("sin", Callable(self, "_math_sin"))
		mod.members["cos"] = _make_builtin("cos", Callable(self, "_math_cos"))
		mod.members["tan"] = _make_builtin("tan", Callable(self, "_math_tan"))
		mod.members["asin"] = _make_builtin("asin", Callable(self, "_math_asin"))
		mod.members["acos"] = _make_builtin("acos", Callable(self, "_math_acos"))
		mod.members["atan"] = _make_builtin("atan", Callable(self, "_math_atan"))
		mod.members["atan2"] = _make_builtin("atan2", Callable(self, "_math_atan2"))
		mod.members["hypot"] = _make_builtin("hypot", Callable(self, "_math_hypot"))
		mod.members["degrees"] = _make_builtin("degrees", Callable(self, "_math_degrees"))
		mod.members["radians"] = _make_builtin("radians", Callable(self, "_math_radians"))
		mod.members["factorial"] = _make_builtin("factorial", Callable(self, "_math_factorial"))
		mod.members["gcd"] = _make_builtin("gcd", Callable(self, "_math_gcd"))
		mod.members["comb"] = _make_builtin("comb", Callable(self, "_math_comb"))
		mod.members["perm"] = _make_builtin("perm", Callable(self, "_math_perm"))
		mod.members["prod"] = _make_builtin("prod", Callable(self, "_math_prod"))
		mod.members["lcm"] = _make_builtin("lcm", Callable(self, "_math_lcm"))
		mod.members["copysign"] = _make_builtin("copysign", Callable(self, "_math_copysign"))
		mod.members["isnan"] = _make_builtin("isnan", Callable(self, "_math_isnan"))
		mod.members["isinf"] = _make_builtin("isinf", Callable(self, "_math_isinf"))
		mod.members["isfinite"] = _make_builtin("isfinite", Callable(self, "_math_isfinite"))
		mod.members["remainder"] = _make_builtin("remainder", Callable(self, "_math_remainder"))
		mod.members["cbrt"] = _make_builtin("cbrt", Callable(self, "_math_cbrt"))
		return mod

	## 创建 random 模块 [br]
	## 使用内置 xorshift32 PRNG (seed() 可复现), 与 CPython 的 Mersenne Twister 序列不同 [br]
	## [returns] DSLModule
	func _create_random_module() -> DSLModule:
		var mod = DSLModule.new("random")
		mod.members["seed"] = _make_builtin("seed", Callable(self, "_rng_seed"))
		mod.members["random"] = _make_builtin("random", Callable(self, "_rng_random"))
		mod.members["uniform"] = _make_builtin("uniform", Callable(self, "_rng_uniform"))
		mod.members["randint"] = _make_builtin("randint", Callable(self, "_rng_randint"))
		mod.members["randrange"] = _make_builtin("randrange", Callable(self, "_rng_randrange"))
		mod.members["choice"] = _make_builtin("choice", Callable(self, "_rng_choice"))
		mod.members["shuffle"] = _make_builtin("shuffle", Callable(self, "_rng_shuffle"))
		mod.members["sample"] = _make_builtin("sample", Callable(self, "_rng_sample"))
		mod.members["choices"] = _make_builtin("choices", Callable(self, "_rng_choices"))
		mod.members["gauss"] = _make_builtin("gauss", Callable(self, "_rng_gauss"))
		return mod

	## 创建 statistics 模块 (纯逻辑统计函数) [br]
	## [returns] DSLModule
	func _create_statistics_module() -> DSLModule:
		var mod = DSLModule.new("statistics")
		mod.members["mean"] = _make_builtin("mean", Callable(self, "_stat_mean"))
		mod.members["median"] = _make_builtin("median", Callable(self, "_stat_median"))
		mod.members["mode"] = _make_builtin("mode", Callable(self, "_stat_mode"))
		mod.members["stdev"] = _make_builtin("stdev", Callable(self, "_stat_stdev"))
		mod.members["pstdev"] = _make_builtin("pstdev", Callable(self, "_stat_pstdev"))
		mod.members["variance"] = _make_builtin("variance", Callable(self, "_stat_variance"))
		mod.members["pvariance"] = _make_builtin("pvariance", Callable(self, "_stat_pvariance"))
		mod.members["quantiles"] = _make_builtin("quantiles", Callable(self, "_stat_quantiles"))
		mod.members["StatisticsError"] = globals.get_val_safe("StatisticsError")
		return mod

	## 创建 functools 模块 [br]
	## [returns] DSLModule
	func _create_functools_module() -> DSLModule:
		var mod = DSLModule.new("functools")
		mod.members["reduce"] = _make_builtin("reduce", Callable(self, "_ft_reduce"))
		mod.members["partial"] = _make_builtin("partial", Callable(self, "_ft_partial"))
		mod.members["cmp_to_key"] = _make_builtin("cmp_to_key", Callable(self, "_ft_cmp_to_key"))
		return mod

	## 创建 itertools 模块 (常用迭代工具) [br]
	## [returns] DSLModule
	func _create_itertools_module() -> DSLModule:
		var mod = DSLModule.new("itertools")
		mod.members["chain"] = _make_builtin("chain", Callable(self, "_it_chain"))
		mod.members["product"] = _make_builtin("product", Callable(self, "_it_product"))
		mod.members["combinations"] = _make_builtin("combinations", Callable(self, "_it_combinations"))
		mod.members["permutations"] = _make_builtin("permutations", Callable(self, "_it_permutations"))
		mod.members["islice"] = _make_builtin("islice", Callable(self, "_it_islice"))
		mod.members["repeat"] = _make_builtin("repeat", Callable(self, "_it_repeat"))
		mod.members["cycle"] = _make_builtin("cycle", Callable(self, "_it_cycle"))
		mod.members["count"] = _make_builtin("count", Callable(self, "_it_count"))
		mod.members["zip_longest"] = _make_builtin("zip_longest", Callable(self, "_it_zip_longest"))
		mod.members["takewhile"] = _make_builtin("takewhile", Callable(self, "_it_takewhile"))
		mod.members["dropwhile"] = _make_builtin("dropwhile", Callable(self, "_it_dropwhile"))
		mod.members["accumulate"] = _make_builtin("accumulate", Callable(self, "_it_accumulate"))
		mod.members["pairwise"] = _make_builtin("pairwise", Callable(self, "_it_pairwise"))
		mod.members["groupby"] = _make_builtin("groupby", Callable(self, "_it_groupby"))
		mod.members["starmap"] = _make_builtin("starmap", Callable(self, "_it_starmap"))
		return mod

	## 创建 operator 模块 (以函数形式暴露内置运算符) [br]
	## [returns] DSLModule
	func _create_operator_module() -> DSLModule:
		var mod = DSLModule.new("operator")
		# 算术
		mod.members["add"] = _make_builtin("add", Callable(self, "_op_add"))
		mod.members["sub"] = _make_builtin("sub", Callable(self, "_op_sub"))
		mod.members["mul"] = _make_builtin("mul", Callable(self, "_op_mul"))
		mod.members["truediv"] = _make_builtin("truediv", Callable(self, "_op_truediv"))
		mod.members["floordiv"] = _make_builtin("floordiv", Callable(self, "_op_floordiv"))
		mod.members["mod"] = _make_builtin("mod", Callable(self, "_op_mod"))
		mod.members["pow"] = _make_builtin("pow", Callable(self, "_op_pow"))
		mod.members["neg"] = _make_builtin("neg", Callable(self, "_op_neg"))
		mod.members["pos"] = _make_builtin("pos", Callable(self, "_op_pos"))
		mod.members["abs"] = _make_builtin("abs", Callable(self, "_op_abs"))
		# 位运算
		mod.members["and_"] = _make_builtin("and_", Callable(self, "_op_and"))
		mod.members["or_"] = _make_builtin("or_", Callable(self, "_op_or"))
		mod.members["xor"] = _make_builtin("xor", Callable(self, "_op_xor"))
		mod.members["invert"] = _make_builtin("invert", Callable(self, "_op_invert"))
		mod.members["lshift"] = _make_builtin("lshift", Callable(self, "_op_lshift"))
		mod.members["rshift"] = _make_builtin("rshift", Callable(self, "_op_rshift"))
		# 比较
		mod.members["eq"] = _make_builtin("eq", Callable(self, "_op_eq"))
		mod.members["ne"] = _make_builtin("ne", Callable(self, "_op_ne"))
		mod.members["lt"] = _make_builtin("lt", Callable(self, "_op_lt"))
		mod.members["le"] = _make_builtin("le", Callable(self, "_op_le"))
		mod.members["gt"] = _make_builtin("gt", Callable(self, "_op_gt"))
		mod.members["ge"] = _make_builtin("ge", Callable(self, "_op_ge"))
		mod.members["is_"] = _make_builtin("is_", Callable(self, "_op_is"))
		mod.members["is_not"] = _make_builtin("is_not", Callable(self, "_op_is_not"))
		# 逻辑
		mod.members["not_"] = _make_builtin("not_", Callable(self, "_op_not"))
		mod.members["truth"] = _make_builtin("truth", Callable(self, "_op_truth"))
		# 序列
		mod.members["concat"] = _make_builtin("concat", Callable(self, "_op_concat"))
		mod.members["contains"] = _make_builtin("contains", Callable(self, "_op_contains"))
		mod.members["getitem"] = _make_builtin("getitem", Callable(self, "_op_getitem"))
		mod.members["setitem"] = _make_builtin("setitem", Callable(self, "_op_setitem"))
		mod.members["delitem"] = _make_builtin("delitem", Callable(self, "_op_delitem"))
		mod.members["countOf"] = _make_builtin("countOf", Callable(self, "_op_count_of"))
		mod.members["indexOf"] = _make_builtin("indexOf", Callable(self, "_op_index_of"))
		mod.members["length_hint"] = _make_builtin("length_hint", Callable(self, "_op_length_hint"))
		# 取项/取属性 (与 sorted(key=) 高频配合)
		mod.members["itemgetter"] = _make_builtin("itemgetter", Callable(self, "_op_itemgetter"))
		mod.members["attrgetter"] = _make_builtin("attrgetter", Callable(self, "_op_attrgetter"))
		return mod

	## 创建 collections 模块 [br]
	## [returns] DSLModule
	func _create_collections_module() -> DSLModule:
		var mod = DSLModule.new("collections")
		mod.members["Counter"] = _make_builtin("Counter", Callable(self, "_col_counter"))
		mod.members["defaultdict"] = _make_builtin("defaultdict", Callable(self, "_col_defaultdict"))
		return mod

	## 创建 string 模块 (字符串常量) [br]
	## [returns] DSLModule
	func _create_string_module() -> DSLModule:
		var mod = DSLModule.new("string")
		mod.members["ascii_lowercase"] = DSLString.new("abcdefghijklmnopqrstuvwxyz")
		mod.members["ascii_uppercase"] = DSLString.new("ABCDEFGHIJKLMNOPQRSTUVWXYZ")
		mod.members["ascii_letters"] = DSLString.new("abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ")
		mod.members["digits"] = DSLString.new("0123456789")
		mod.members["hexdigits"] = DSLString.new("0123456789abcdefABCDEF")
		mod.members["octdigits"] = DSLString.new("01234567")
		mod.members["punctuation"] = DSLString.new("!\"#$%&'()*+,-./:;<=>?@[\\]^_`{|}~")
		mod.members["whitespace"] = DSLString.new(" \t\n\r\v\f")
		mod.members["printable"] = DSLString.new("0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!\"#$%&'()*+,-./:;<=>?@[\\]^_`{|}~ \t\n\r\v\f")
		return mod

	## 生成下一个伪随机整数 (xorshift32)
	func _rng_next() -> int:
		var x = _rng_state
		x = x ^ ((x << 13) & 0xFFFFFFFF)
		x = x ^ (x >> 17)
		x = x ^ ((x << 5) & 0xFFFFFFFF)
		_rng_state = x & 0xFFFFFFFF
		return _rng_state

	## 生成 [0, 1) 的伪随机浮点数
	func _rng_float() -> float:
		return float(_rng_next()) / 4294967296.0

	## 从 DSLObject 参数中提取数值 [br]
	## [param arg] DSLInteger 或 DSLFloat [br]
	## [returns] 数值或 null
	func _num_val(arg: DSLObject):
		if arg is DSLInteger:
			return arg.value
		if arg is DSLFloat:
			return arg.value
		return null

	## 从 DSLObject 参数中提取数值, 不可用时返回默认值 [br]
	## [param arg] DSLObject 参数, 可为 null [br]
	## [param default] 默认值 [br]
	## [returns] 数值
	func _num_val_or(arg, default: float) -> float:
		if arg == null:
			return default
		var v = _num_val(arg)
		return default if v == null else float(v)

	## math.sqrt(x)
	func _math_sqrt(args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLObject:
		if args.size() != 1:
			raise_exception("TypeError", "sqrt() takes exactly one argument")
			return null
		var x = _num_val(args[0])
		if x == null:
			raise_exception("TypeError", "sqrt() argument must be a number")
			return null
		return DSLFloat.new(sqrt(float(x)))

	## math.isqrt(x)
	func _math_isqrt(args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLObject:
		if args.size() != 1:
			raise_exception("TypeError", "isqrt() takes exactly one argument")
			return null
		var x = _num_val(args[0])
		if x == null or x < 0:
			raise_exception("ValueError", "isqrt() argument must be nonnegative")
			return null
		return DSLInteger.new(int(sqrt(float(x))))

	## math.floor(x)
	func _math_floor(args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLObject:
		if args.size() != 1:
			raise_exception("TypeError", "floor() takes exactly one argument")
			return null
		var x = _num_val(args[0])
		if x == null:
			raise_exception("TypeError", "floor() argument must be a number")
			return null
		return DSLInteger.new(floor(float(x)))

	## math.ceil(x)
	func _math_ceil(args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLObject:
		if args.size() != 1:
			raise_exception("TypeError", "ceil() takes exactly one argument")
			return null
		var x = _num_val(args[0])
		if x == null:
			raise_exception("TypeError", "ceil() argument must be a number")
			return null
		return DSLInteger.new(ceil(float(x)))

	## math.trunc(x)
	func _math_trunc(args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLObject:
		if args.size() != 1:
			raise_exception("TypeError", "trunc() takes exactly one argument")
			return null
		var x = _num_val(args[0])
		if x == null:
			raise_exception("TypeError", "trunc() argument must be a number")
			return null
		return DSLInteger.new(int(float(x)))

	## math.fabs(x)
	func _math_fabs(args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLObject:
		if args.size() != 1:
			raise_exception("TypeError", "fabs() takes exactly one argument")
			return null
		var x = _num_val(args[0])
		if x == null:
			raise_exception("TypeError", "fabs() argument must be a number")
			return null
		return DSLFloat.new(abs(float(x)))

	## math.fmod(a, b)
	func _math_fmod(args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLObject:
		if args.size() != 2:
			raise_exception("TypeError", "fmod() takes exactly two arguments")
			return null
		var a = _num_val(args[0])
		var b = _num_val(args[1])
		if a == null or b == null:
			raise_exception("TypeError", "fmod() arguments must be numbers")
			return null
		return DSLFloat.new(fmod(float(a), float(b)))

	## math.pow(a, b)
	func _math_pow(args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLObject:
		if args.size() != 2:
			raise_exception("TypeError", "pow() takes exactly two arguments")
			return null
		var a = _num_val(args[0])
		var b = _num_val(args[1])
		if a == null or b == null:
			raise_exception("TypeError", "pow() arguments must be numbers")
			return null
		return DSLFloat.new(pow(float(a), float(b)))

	## math.exp(x)
	func _math_exp(args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLObject:
		if args.size() != 1:
			raise_exception("TypeError", "exp() takes exactly one argument")
			return null
		var x = _num_val(args[0])
		if x == null:
			raise_exception("TypeError", "exp() argument must be a number")
			return null
		return DSLFloat.new(exp(float(x)))

	## math.log(x[, base])
	func _math_log(args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLObject:
		if args.size() < 1 or args.size() > 2:
			raise_exception("TypeError", "log() takes one or two arguments")
			return null
		var x = _num_val(args[0])
		if x == null:
			raise_exception("TypeError", "log() argument must be a number")
			return null
		if args.size() == 2:
			var base = _num_val(args[1])
			if base == null:
				raise_exception("TypeError", "log() base must be a number")
				return null
			return DSLFloat.new(log(float(x)) / log(float(base)))
		return DSLFloat.new(log(float(x)))

	## math.log2(x)
	func _math_log2(args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLObject:
		if args.size() != 1:
			raise_exception("TypeError", "log2() takes exactly one argument")
			return null
		var x = _num_val(args[0])
		if x == null:
			raise_exception("TypeError", "log2() argument must be a number")
			return null
		return DSLFloat.new(log(float(x)) / log(2.0))

	## math.log10(x)
	func _math_log10(args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLObject:
		if args.size() != 1:
			raise_exception("TypeError", "log10() takes exactly one argument")
			return null
		var x = _num_val(args[0])
		if x == null:
			raise_exception("TypeError", "log10() argument must be a number")
			return null
		return DSLFloat.new(log(float(x)) / log(10.0))

	## math.sin(x)
	func _math_sin(args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLObject:
		if args.size() != 1:
			raise_exception("TypeError", "sin() takes exactly one argument")
			return null
		var x = _num_val(args[0])
		if x == null:
			raise_exception("TypeError", "sin() argument must be a number")
			return null
		return DSLFloat.new(sin(float(x)))

	## math.cos(x)
	func _math_cos(args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLObject:
		if args.size() != 1:
			raise_exception("TypeError", "cos() takes exactly one argument")
			return null
		var x = _num_val(args[0])
		if x == null:
			raise_exception("TypeError", "cos() argument must be a number")
			return null
		return DSLFloat.new(cos(float(x)))

	## math.tan(x)
	func _math_tan(args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLObject:
		if args.size() != 1:
			raise_exception("TypeError", "tan() takes exactly one argument")
			return null
		var x = _num_val(args[0])
		if x == null:
			raise_exception("TypeError", "tan() argument must be a number")
			return null
		return DSLFloat.new(tan(float(x)))

	## math.asin(x)
	func _math_asin(args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLObject:
		if args.size() != 1:
			raise_exception("TypeError", "asin() takes exactly one argument")
			return null
		var x = _num_val(args[0])
		if x == null:
			raise_exception("TypeError", "asin() argument must be a number")
			return null
		return DSLFloat.new(asin(float(x)))

	## math.acos(x)
	func _math_acos(args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLObject:
		if args.size() != 1:
			raise_exception("TypeError", "acos() takes exactly one argument")
			return null
		var x = _num_val(args[0])
		if x == null:
			raise_exception("TypeError", "acos() argument must be a number")
			return null
		return DSLFloat.new(acos(float(x)))

	## math.atan(x)
	func _math_atan(args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLObject:
		if args.size() != 1:
			raise_exception("TypeError", "atan() takes exactly one argument")
			return null
		var x = _num_val(args[0])
		if x == null:
			raise_exception("TypeError", "atan() argument must be a number")
			return null
		return DSLFloat.new(atan(float(x)))

	## math.atan2(y, x)
	func _math_atan2(args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLObject:
		if args.size() != 2:
			raise_exception("TypeError", "atan2() takes exactly two arguments")
			return null
		var y = _num_val(args[0])
		var x = _num_val(args[1])
		if y == null or x == null:
			raise_exception("TypeError", "atan2() arguments must be numbers")
			return null
		return DSLFloat.new(atan2(float(y), float(x)))

	## math.hypot(a, b)
	func _math_hypot(args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLObject:
		if args.size() < 2:
			raise_exception("TypeError", "hypot() takes at least two arguments")
			return null
		var total = 0.0
		for a in args:
			var v = _num_val(a)
			if v == null:
				raise_exception("TypeError", "hypot() arguments must be numbers")
				return null
			total += float(v) * float(v)
		return DSLFloat.new(sqrt(total))

	## math.degrees(x)
	func _math_degrees(args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLObject:
		if args.size() != 1:
			raise_exception("TypeError", "degrees() takes exactly one argument")
			return null
		var x = _num_val(args[0])
		if x == null:
			raise_exception("TypeError", "degrees() argument must be a number")
			return null
		return DSLFloat.new(rad_to_deg(float(x)))

	## math.radians(x)
	func _math_radians(args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLObject:
		if args.size() != 1:
			raise_exception("TypeError", "radians() takes exactly one argument")
			return null
		var x = _num_val(args[0])
		if x == null:
			raise_exception("TypeError", "radians() argument must be a number")
			return null
		return DSLFloat.new(deg_to_rad(float(x)))

	## math.factorial(n)
	func _math_factorial(args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLObject:
		if args.size() != 1:
			raise_exception("TypeError", "factorial() takes exactly one argument")
			return null
		var n = _num_val(args[0])
		if n == null:
			raise_exception("TypeError", "factorial() argument must be an integer")
			return null
		var iv = int(n)
		if float(iv) != float(n) or iv < 0:
			raise_exception("ValueError", "factorial() argument must be a nonnegative integer")
			return null
		var result = 1
		for i in range(2, iv + 1):
			result *= i
		return DSLInteger.new(result)

	## math.gcd(a, b)
	func _math_gcd(args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLObject:
		if args.size() < 2:
			raise_exception("TypeError", "gcd() takes at least two arguments")
			return null
		var a = int(_num_val(args[0]))
		var b = int(_num_val(args[1]))
		a = abs(a)
		b = abs(b)
		while b != 0:
			var t = b
			b = a % b
			a = t
		return DSLInteger.new(a)

	## math.comb(n, k) - 组合数 C(n, k)
	func _math_comb(args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLObject:
		if args.size() != 2:
			raise_exception("TypeError", "comb() takes exactly two arguments")
			return null
		var n = int(_num_val(args[0]))
		var k = int(_num_val(args[1]))
		if k < 0 or k > n:
			raise_exception("ValueError", "comb() n < k or k < 0")
			return null
		if k > n - k:
			k = n - k
		var result: float = 1.0
		for i in range(1, k + 1):
			result = result * (n - k + i) / i
		return DSLInteger.new(int(result))

	## math.perm(n, k) - 排列数 P(n, k)
	func _math_perm(args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLObject:
		if args.size() != 2:
			raise_exception("TypeError", "perm() takes exactly two arguments")
			return null
		var n = int(_num_val(args[0]))
		var k = int(_num_val(args[1]))
		if k < 0 or k > n:
			raise_exception("ValueError", "perm() n < k or k < 0")
			return null
		var result: float = 1.0
		for i in range(n - k + 1, n + 1):
			result = result * i
		return DSLInteger.new(int(result))

	## math.prod(iterable, start=1) - 连乘
	func _math_prod(args: Array[DSLObject], kwargs: Dictionary[String, DSLObject]) -> DSLObject:
		if args.size() < 1:
			raise_exception("TypeError", "prod() takes at least one argument")
			return null
		var start: DSLObject = DSLInteger.new(1)
		if args.size() >= 2:
			start = args[1]
		elif kwargs.has("start"):
			start = kwargs["start"]
		var it = args[0]._dsl_iter()
		if it == null:
			raise_exception("TypeError", "prod() argument must be iterable")
			return null
		var result = start
		while it.has_next():
			var v = it.next()
			if it.suspended:
				break
			result = result.magic_mul([result, v] as Array[DSLObject], {} as Dictionary[String, DSLObject])
			if result == null:
				return null
		return result

	## math.lcm(*args) - 最小公倍数
	func _math_lcm(args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLObject:
		if args.size() < 2:
			raise_exception("TypeError", "lcm() takes at least two arguments")
			return null
		var lcm_val = 1
		for i in range(args.size()):
			var n = abs(int(_num_val(args[i])))
			if n == 0:
				return DSLInteger.new(0)
			var a = lcm_val
			var b = n
			while b != 0:
				var t = b
				b = a % b
				a = t
			var g = a
			lcm_val = int(lcm_val / g) * n
		return DSLInteger.new(lcm_val)

	## math.copysign(x, y)
	func _math_copysign(args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLObject:
		if args.size() != 2:
			raise_exception("TypeError", "copysign() takes exactly two arguments")
			return null
		var x = _num_val(args[0])
		var y = _num_val(args[1])
		if x == null or y == null:
			raise_exception("TypeError", "copysign() arguments must be numbers")
			return null
		var r = abs(float(x))
		if float(y) < 0:
			r = -r
		return DSLFloat.new(r)

	## math.isnan(x)
	func _math_isnan(args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLObject:
		if args.size() != 1:
			raise_exception("TypeError", "isnan() takes exactly one argument")
			return null
		var x = _num_val(args[0])
		if x == null:
			raise_exception("TypeError", "isnan() argument must be a number")
			return null
		return DSLBool.new(is_nan(float(x)))

	## math.isinf(x)
	func _math_isinf(args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLObject:
		if args.size() != 1:
			raise_exception("TypeError", "isinf() takes exactly one argument")
			return null
		var x = _num_val(args[0])
		if x == null:
			raise_exception("TypeError", "isinf() argument must be a number")
			return null
		return DSLBool.new(is_inf(float(x)))

	## math.isfinite(x)
	func _math_isfinite(args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLObject:
		if args.size() != 1:
			raise_exception("TypeError", "isfinite() takes exactly one argument")
			return null
		var x = _num_val(args[0])
		if x == null:
			raise_exception("TypeError", "isfinite() argument must be a number")
			return null
		return DSLBool.new(is_finite(float(x)))

	## math.remainder(x, y) [br]
	## IEEE 754 余数: x - n*y, 其中 n 为 x/y 四舍五入到最近偶数, 除数为零或 x 为无穷时抛 ValueError
	func _math_remainder(args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLObject:
		if args.size() != 2:
			raise_exception("TypeError", "remainder() takes exactly two arguments")
			return null
		var x = _num_val(args[0])
		var y = _num_val(args[1])
		if x == null or y == null:
			raise_exception("TypeError", "remainder() arguments must be numbers")
			return null
		var fx = float(x)
		var fy = float(y)
		if fy == 0.0 or is_inf(fx):
			raise_exception("ValueError", "math domain error")
			return null
		if is_nan(fx) or is_nan(fy):
			return DSLFloat.new(NAN)
		if is_inf(fy):
			return DSLFloat.new(fx)
		var q = fx / fy
		var n = floor(q)
		var diff = q - n
		if diff > 0.5:
			n += 1.0
		elif diff == 0.5 and fmod(n, 2.0) != 0.0:
			n += 1.0
		var r = fx - n * fy
		# 余数为零时保留被除数的符号 (与 IEEE 754 / CPython 一致)
		if r == 0.0:
			var x_is_negative = fx < 0.0 or (fx == 0.0 and (1.0 / fx) < 0.0)
			r = -0.0 if x_is_negative else 0.0
		return DSLFloat.new(r)

	## math.cbrt(x)
	func _math_cbrt(args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLObject:
		if args.size() != 1:
			raise_exception("TypeError", "cbrt() takes exactly one argument")
			return null
		var x = _num_val(args[0])
		if x == null:
			raise_exception("TypeError", "cbrt() argument must be a number")
			return null
		var fx = float(x)
		if fx == 0.0 or is_nan(fx) or is_inf(fx):
			return DSLFloat.new(fx)
		var r = pow(abs(fx), 1.0 / 3.0)
		return DSLFloat.new(-r if fx < 0.0 else r)

	## random.seed(n)
	func _rng_seed(args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLObject:
		var s = 0
		if args.size() > 0:
			var v = _num_val(args[0])
			if v != null:
				s = int(v) & 0xFFFFFFFF
			elif args[0] is DSLString:
				s = args[0].value.hash() & 0xFFFFFFFF
		if s == 0:
			s = 1
		_rng_state = s
		return DSLNone.new()

	## random.random()
	func _rng_random(args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLObject:
		return DSLFloat.new(_rng_float())

	## random.uniform(a, b)
	func _rng_uniform(args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLObject:
		if args.size() != 2:
			raise_exception("TypeError", "uniform() takes exactly two arguments")
			return null
		var a = _num_val(args[0])
		var b = _num_val(args[1])
		if a == null or b == null:
			raise_exception("TypeError", "uniform() arguments must be numbers")
			return null
		return DSLFloat.new(float(a) + (float(b) - float(a)) * _rng_float())

	## random.randint(a, b)
	func _rng_randint(args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLObject:
		if args.size() != 2:
			raise_exception("TypeError", "randint() takes exactly two arguments")
			return null
		var a = int(_num_val(args[0]))
		var b = int(_num_val(args[1]))
		if a > b:
			raise_exception("ValueError", "empty range for randint()")
			return null
		return DSLInteger.new(a + _rng_next() % (b - a + 1))

	## random.randrange(stop) / (start, stop) / (start, stop, step)
	func _rng_randrange(args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLObject:
		if args.size() < 1 or args.size() > 3:
			raise_exception("TypeError", "randrange() takes from 1 to 3 arguments")
			return null
		var start = 0
		var stop = 0
		var step = 1
		if args.size() == 1:
			stop = int(_num_val(args[0]))
		elif args.size() == 2:
			start = int(_num_val(args[0]))
			stop = int(_num_val(args[1]))
		else:
			start = int(_num_val(args[0]))
			stop = int(_num_val(args[1]))
			step = int(_num_val(args[2]))
		var count = (stop - start + step - 1) / step if step > 0 else 0
		if count <= 0:
			raise_exception("ValueError", "empty range for randrange()")
			return null
		return DSLInteger.new(start + step * (_rng_next() % count))

	## 抽样函数的生成器参数校验 [br]
	## 生成器是一次性迭代器且没有 len(), CPython 的抽样函数一律拒绝, 此处同样拒绝 [br]
	## [param obj] 待检查的实参 [br]
	## [returns] 是生成器时返回 true
	func _rng_is_generator(obj) -> bool:
		var raw = DSLObject._unwrap_dsl(obj)
		return raw is DSLFunctionGenerator or raw is DSLGenerator

	## 抽样函数的序列长度 (对应 CPython 的 len(population)) [br]
	## 沿用内置 len() 的判定, 对无长度信息的对象返回 -1 [br]
	## [param obj] 待测对象 [br]
	## [returns] 长度, 无长度信息时为 -1
	func _rng_len_of(obj) -> int:
		var raw = DSLObject._unwrap_dsl(obj)
		var res = builtin_len([raw] as Array[DSLObject], {} as Dictionary[String, DSLObject])
		if report.has_error:
			report.clear_error()
			return -1
		if res is DSLInteger:
			return res.value
		return -1

	## 抽样函数按整数下标取值 (对应 CPython 的 seq[i]) [br]
	## 列表/元组取元素, 字符串取单字符, 字典按键取 (与 CPython 一致, 键非 0..n-1 时报 KeyError) [br]
	## [param obj] 待索引对象 [br]
	## [param idx] 下标 [br]
	## [returns] 取到的元素, 失败时返回 null 并置 last_error
	func _rng_index(obj, idx: int) -> DSLObject:
		var raw = DSLObject._unwrap_dsl(obj)
		if raw is DSLList or raw is DSLTuple:
			return raw.items[idx]
		if raw is DSLRange:
			return raw._at(idx)
		if raw is DSLString:
			return DSLString.new(raw.value[idx])
		if raw is DSLDict or raw is DSLDefaultDict:
			var d = raw if raw is DSLDict else raw.inner
			var vkey = d._key_to_variant(DSLInteger.new(idx))
			if vkey != null and d.dict.has(vkey):
				return d.dict[vkey]
			raise_exception("KeyError", str(idx))
			return null
		raise_exception("TypeError", "'%s' object is not subscriptable" % raw._type_name())
		return null

	## random.choice(seq)
	func _rng_choice(args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLObject:
		if args.size() != 1:
			raise_exception("TypeError", "choice() takes exactly one argument")
			return null
		# 与 CPython 一致: choice 取 len(seq) 后按 seq[_randbelow(len)] 索引,
		# 因此生成器因无 len 被拒、集合因不可下标被拒、字典按键取到下标对应的键
		var n = _rng_len_of(args[0])
		if n < 0:
			raise_exception("TypeError", "object of type '%s' has no len()" % DSLObject._unwrap_dsl(args[0])._type_name())
			return null
		if n == 0:
			raise_exception("IndexError", "Cannot choose from an empty sequence")
			return null
		var picked = _rng_index(args[0], _rng_next() % n)
		if picked == null:
			return null
		return picked

	## random.shuffle(seq)
	func _rng_shuffle(args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLObject:
		if args.size() != 1:
			raise_exception("TypeError", "shuffle() takes exactly one argument")
			return null
		var raw = DSLObject._unwrap_dsl(args[0])
		var n = _rng_len_of(raw)
		if n < 0:
			raise_exception("TypeError", "object of type '%s' has no len()" % raw._type_name())
			return null
		# 与 CPython 一致: shuffle 需要可写序列, 元组/字符串/range 因不支持元素赋值被拒
		if raw is DSLList and raw.is_range:
			raise_exception("TypeError", "'range' object does not support item assignment")
			return null
		if not (raw is DSLList or raw is DSLDict or raw is DSLDefaultDict):
			if raw is DSLSet or raw is DSLFrozenSet:
				raise_exception("TypeError", "'%s' object is not subscriptable" % raw._type_name())
				return null
			raise_exception("TypeError", "'%s' object does not support item assignment" % raw._type_name())
			return null
		for i in range(n - 1, 0, -1):
			var j = _rng_next() % (i + 1)
			if raw is DSLList:
				var tmp = raw.items[i]
				raw.items[i] = raw.items[j]
				raw.items[j] = tmp
			else:
				var d = raw if raw is DSLDict else raw.inner
				var ki = d._key_to_variant(DSLInteger.new(i))
				var kj = d._key_to_variant(DSLInteger.new(j))
				if ki == null or kj == null or not d.dict.has(ki) or not d.dict.has(kj):
					raise_exception("KeyError", str(j))
					return null
				var tmp2 = d.dict[ki]
				d.dict[ki] = d.dict[kj]
				d.dict[kj] = tmp2
		return DSLNone.new()
		return null

	## random.sample(population, k)
	func _rng_sample(args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLObject:
		if args.size() != 2:
			raise_exception("TypeError", "sample() takes exactly two arguments")
			return null
		var raw = DSLObject._unwrap_dsl(args[0])
		var k = int(_num_val(args[1]))
		var pool: Array[DSLObject] = []
		if raw is DSLList or raw is DSLTuple:
			pool = raw.items.duplicate()
		elif raw is DSLRange:
			pool = raw._to_list().items
		elif raw is DSLString:
			for i in range(raw.value.length()):
				pool.append(DSLString.new(raw.value[i]))
		else:
			# CPython: sample 需要序列, 生成器/集合/字典一律拒绝并提示 sorted(d)
			raise_exception("TypeError", "Population must be a sequence.  For dicts or sets, use sorted(d).")
			return null
		if k < 0 or k > pool.size():
			raise_exception("ValueError", "Sample larger than population or is negative")
			return null
		var result = DSLList.new()
		for i in range(k):
			var j = _rng_next() % (pool.size() - i)
			result.items.append(pool[j])
			pool[j] = pool[pool.size() - 1 - i]
		return result

	## random.choices(population, weights=None, k=1) [br]
	## 有放回抽样, 可按 weights 加权, 返回长度为 k 的列表
	func _rng_choices(args: Array[DSLObject], kwargs: Dictionary[String, DSLObject]) -> DSLObject:
		if args.size() < 1 or args.size() > 3:
			raise_exception("TypeError", "choices() takes from 1 to 3 positional arguments")
			return null
		if _rng_is_generator(args[0]):
			# CPython: 抽样需要序列, 生成器没有 len() 而被拒绝
			raise_exception("TypeError", "object of type 'generator' has no len()")
			return null
		var pool: Array[DSLObject] = []
		var it = args[0]._dsl_iter()
		if it == null:
			raise_exception("TypeError", "choices() population must be a sequence")
			return null
		while it.has_next():
			pool.append(it.next())
			if it.suspended:
				break
		if it.suspended:
			# 消费中途挂起: pool 只是半截, 交由语句重放而不是当作完整总体
			return null
		if pool.size() == 0:
			raise_exception("IndexError", "Cannot choose from an empty population")
			return null
		# weights 可位置传入或关键字传入
		var weights_obj: DSLObject = null
		if args.size() >= 2:
			weights_obj = args[1]
		if kwargs.has("weights"):
			weights_obj = kwargs["weights"]
		var k = 1
		if args.size() >= 3:
			k = int(_num_val_or(args[2], 1.0))
		if kwargs.has("k"):
			k = int(_num_val_or(kwargs["k"], 1.0))
		var cum: Array = []
		if weights_obj != null and not (weights_obj is DSLNone):
			# 权重只需可迭代 (CPython 对 weights 不做 len 检查, 生成器可接受)
			var wt = weights_obj._dsl_iter()
			if wt == null:
				raise_exception("TypeError", "choices() weights must be a sequence")
				return null
			var total = 0.0
			while wt.has_next():
				var wv = _num_val(wt.next())
				if wv == null:
					raise_exception("TypeError", "weights must be numbers")
					return null
				total += float(wv)
				cum.append(total)
			if wt.suspended:
				# 消费中途挂起: cum 只是半截, 交由语句重放
				return null
			if cum.size() != pool.size():
				raise_exception("ValueError", "The number of weights does not match the population")
				return null
			if total <= 0.0:
				raise_exception("ValueError", "Total of weights must be greater than zero")
				return null
		var result = DSLList.new()
		for i in range(k):
			var idx = 0
			if cum.size() == 0:
				idx = _rng_next() % pool.size()
			else:
				var r = _rng_float() * float(cum[cum.size() - 1])
				idx = cum.size() - 1
				for j in range(cum.size()):
					if r < float(cum[j]):
						idx = j
						break
			result.items.append(pool[idx])
		return result

	## random.gauss(mu=0.0, sigma=1.0) [br]
	## 正态分布采样 (Box-Muller 变换), 使用内置 PRNG
	func _rng_gauss(args: Array[DSLObject], kwargs: Dictionary[String, DSLObject]) -> DSLObject:
		if args.size() > 2:
			raise_exception("TypeError", "gauss() takes at most two arguments")
			return null
		var mu = 0.0
		var sigma = 1.0
		if args.size() >= 1:
			var m = _num_val(args[0])
			if m == null:
				raise_exception("TypeError", "gauss() arguments must be numbers")
				return null
			mu = float(m)
		if args.size() >= 2:
			var s = _num_val(args[1])
			if s == null:
				raise_exception("TypeError", "gauss() arguments must be numbers")
				return null
			sigma = float(s)
		if kwargs.has("mu"):
			mu = _num_val_or(kwargs["mu"], mu)
		if kwargs.has("sigma"):
			sigma = _num_val_or(kwargs["sigma"], sigma)
		# Box-Muller: u1 取 (0, 1] 避免 log(0)
		var u1 = 1.0 - _rng_float()
		var u2 = _rng_float()
		var z = sqrt(-2.0 * log(u1)) * cos(TAU * u2)
		return DSLFloat.new(mu + z * sigma)

	## 收集数值数组, 同时记录是否全部为整数 (用于匹配 Python 3.12 的返回类型) [br]
	## [param data] 数据对象 (list/tuple/set 等) [br]
	## [returns] [code][数值数组, 是否全部为 int][/code]
	func _collect_nums(data: DSLObject) -> Array:
		var nums: Array = []
		var all_int = true
		var it = data._dsl_iter()
		if it == null:
			raise_exception("TypeError", "statistics functions require an iterable")
			return [nums, false]
		while it.has_next():
			var v = it.next()
			if it.suspended:
				break
			var nv = _num_val(v)
			if nv == null:
				raise_exception("TypeError", "statistics functions require numeric data")
				return [nums, false]
			if not (v is DSLInteger):
				all_int = false
			nums.append(float(nv))
		return [nums, all_int]

	## 根据结果与输入类型决定返回 int 还是 float (匹配 Python 3.12: 整数输入且结果为整数时返回 int) [br]
	## [param v] 数值结果 [br]
	## [param all_int] 输入是否全为整数 [br]
	## [returns] DSLInteger 或 DSLFloat
	func _stat_num_result(v: float, all_int: bool) -> DSLObject:
		if all_int and v == floor(v):
			return DSLInteger.new(int(v))
		return DSLFloat.new(v)

	## statistics.mean(data)
	func _stat_mean(args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLObject:
		if args.size() != 1:
			raise_exception("TypeError", "mean() takes exactly one argument")
			return null
		var collected = _collect_nums(args[0])
		var nums: Array = collected[0]
		var all_int: bool = collected[1]
		if nums.size() == 0:
			raise_exception("ValueError", "mean() requires at least one data point")
			return null
		var total = 0.0
		for n in nums:
			total += n
		return _stat_num_result(total / nums.size(), all_int)

	## statistics.median(data)
	func _stat_median(args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLObject:
		if args.size() != 1:
			raise_exception("TypeError", "median() takes exactly one argument")
			return null
		var collected = _collect_nums(args[0])
		var nums: Array = collected[0]
		var all_int: bool = collected[1]
		if nums.size() == 0:
			raise_exception("ValueError", "median() requires at least one data point")
			return null
		nums.sort()
		var n = nums.size()
		if n % 2 == 1:
			return _stat_num_result(nums[n / 2], all_int)
		return _stat_num_result((nums[n / 2 - 1] + nums[n / 2]) / 2.0, all_int)

	## statistics.mode(data) - 返回出现次数最多的元素
	func _stat_mode(args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLObject:
		if args.size() != 1:
			raise_exception("TypeError", "mode() takes exactly one argument")
			return null
		var counts: Dictionary = {}
		var order: Array = []
		var it = args[0]._dsl_iter()
		if it == null:
			raise_exception("TypeError", "mode() requires an iterable")
			return null
		while it.has_next():
			var v = it.next()
			if it.suspended:
				break
			var key = DSLObject._unwrap_dsl(v)
			var k = ""
			if key is DSLInteger:
				k = "i:" + str(key.value)
			elif key is DSLFloat:
				k = "f:" + str(key.value)
			elif key is DSLString:
				k = "s:" + key.value
			elif key is DSLBool:
				k = "b:" + ("1" if key.value else "0")
			elif key is DSLNone:
				k = "n"
			else:
				k = "o:" + str(key._object_id)
			if not counts.has(k):
				counts[k] = {"count": 1, "obj": v}
				order.append(k)
			else:
				counts[k]["count"] += 1
		if order.size() == 0:
			raise_exception("ValueError", "mode() requires at least one data point")
			return null
		var best_key = order[0]
		for k in order:
			if counts[k]["count"] > counts[best_key]["count"]:
				best_key = k
		return counts[best_key]["obj"]

	## statistics.variance(data) - 样本方差 (n-1)
	func _stat_variance(args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLObject:
		if args.size() != 1:
			raise_exception("TypeError", "variance() takes exactly one argument")
			return null
		var collected = _collect_nums(args[0])
		var nums: Array = collected[0]
		var all_int: bool = collected[1]
		if nums.size() < 2:
			raise_exception("ValueError", "variance() requires at least two data points")
			return null
		var mean = 0.0
		for n in nums:
			mean += n
		mean /= nums.size()
		var sq = 0.0
		for n in nums:
			var d = n - mean
			sq += d * d
		return _stat_num_result(sq / (nums.size() - 1), all_int)

	## statistics.stdev(data) - 样本标准差
	func _stat_stdev(args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLObject:
		var v = _stat_variance(args, _kwargs)
		var vnum = v.value if (v is DSLInteger or v is DSLFloat) else 0.0
		return DSLFloat.new(sqrt(float(vnum)))

	## statistics.pvariance(data) - 总体方差 (n)
	func _stat_pvariance(args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLObject:
		if args.size() != 1:
			raise_exception("TypeError", "pvariance() takes exactly one argument")
			return null
		var collected = _collect_nums(args[0])
		var nums: Array = collected[0]
		var all_int: bool = collected[1]
		if nums.size() == 0:
			raise_exception("ValueError", "pvariance() requires at least one data point")
			return null
		var mean = 0.0
		for n in nums:
			mean += n
		mean /= nums.size()
		var sq = 0.0
		for n in nums:
			var d = n - mean
			sq += d * d
		return _stat_num_result(sq / nums.size(), all_int)

	## statistics.pstdev(data) - 总体标准差
	func _stat_pstdev(args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLObject:
		var v = _stat_pvariance(args, _kwargs)
		var vnum = v.value if (v is DSLInteger or v is DSLFloat) else 0.0
		return DSLFloat.new(sqrt(float(vnum)))

	## statistics.quantiles(data, n=4) [br]
	## 按 exclusive 方法返回 n-1 个分位切点, 数据点少于 2 个时抛 StatisticsError
	func _stat_quantiles(args: Array[DSLObject], kwargs: Dictionary[String, DSLObject]) -> DSLObject:
		if args.size() < 1 or args.size() > 2:
			raise_exception("TypeError", "quantiles() takes 1 or 2 arguments")
			return null
		var collected = _collect_nums(args[0])
		var nums: Array = collected[0]
		if report.has_error:
			return null
		var n = 4
		if args.size() == 2:
			n = int(_num_val_or(args[1], 4.0))
		if kwargs.has("n"):
			n = int(_num_val_or(kwargs["n"], 4.0))
		if n < 1:
			raise_exception("ValueError", "n must be at least 1")
			return null
		if nums.size() < 2:
			raise_exception("StatisticsError", "must have at least two data points")
			return null
		nums.sort()
		var ld = nums.size()
		var m = ld + 1
		var result = DSLList.new()
		for i in range(1, n):
			var j = int(floor(float(i * m) / float(n)))
			var delta = i * m - j * n
			var interpolated = (float(nums[j - 1]) * float(n - delta) + float(nums[j]) * float(delta)) / float(n)
			result.items.append(DSLFloat.new(interpolated))
		return result

	## functools.reduce(func, iterable[, initial])
	func _ft_reduce(args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLObject:
		if args.size() < 2 or args.size() > 3:
			raise_exception("TypeError", "reduce() takes 2 or 3 arguments")
			return null
		var fn = args[0]
		var items: Array[DSLObject] = []
		var it = args[1]._dsl_iter()
		if it == null:
			raise_exception("TypeError", "reduce() argument 2 must be iterable")
			return null
		while it.has_next():
			items.append(it.next())
			if it.suspended:
				break
		var acc: DSLObject = null
		var start = 0
		if args.size() == 3:
			acc = args[2]
		elif items.size() > 0:
			acc = items[0]
			start = 1
		else:
			raise_exception("TypeError", "reduce() of empty iterable with no initial value")
			return null
		for i in range(start, items.size()):
			var r = fn.magic_call([acc, items[i]] as Array[DSLObject], {} as Dictionary[String, DSLObject])
			if r == null:
				return null
			acc = r
		return acc

	## functools.partial(func, *args, **kwargs)
	func _ft_partial(args: Array[DSLObject], kwargs: Dictionary[String, DSLObject]) -> DSLObject:
		if args.size() < 1:
			raise_exception("TypeError", "partial() requires at least one argument")
			return null
		var bound_args: Array[DSLObject] = []
		for i in range(1, args.size()):
			bound_args.append(args[i])
		var p = DSLPartial.new(args[0], bound_args, kwargs)
		p._cls_interp = self
		return p

	## functools.cmp_to_key(func) [br]
	## 返回 key 工厂: 调用它包装元素, 排序时按旧式 cmp(a, b) 的符号比较
	func _ft_cmp_to_key(args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLObject:
		if args.size() != 1:
			raise_exception("TypeError", "cmp_to_key() takes exactly one argument")
			return null
		var cmp_func = args[0]
		if not cmp_func._dsl_is_callable():
			raise_exception("TypeError", "cmp_to_key() argument must be callable")
			return null
		return DSLCmpKey.new(null, cmp_func)

	## itertools.chain(*iterables)
	func _it_chain(args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLObject:
		var result = DSLList.new()
		for arg in args:
			var it = arg._dsl_iter()
			if it == null:
				raise_exception("TypeError", "chain() arguments must be iterable")
				return null
			while it.has_next():
				result.items.append(it.next())
				if it.suspended:
					break
		return result

	## itertools.product(*iterables) - 笛卡尔积
	func _it_product(args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLObject:
		var pools: Array = []
		for arg in args:
			var items: Array[DSLObject] = []
			var it = arg._dsl_iter()
			if it == null:
				raise_exception("TypeError", "product() arguments must be iterable")
				return null
			while it.has_next():
				items.append(it.next())
				if it.suspended:
					break
			pools.append(items)
		var result = DSLList.new()
		var idx: Array = []
		for i in range(pools.size()):
			idx.append(0)
		# 迭代笛卡尔积 (类似多进制计数器)
		while true:
			var row: Array[DSLObject] = []
			for i in range(pools.size()):
				row.append(pools[i][idx[i]])
			result.items.append(DSLTuple.new(row))
			# 递增计数器
			var carry = pools.size() - 1
			while carry >= 0:
				idx[carry] += 1
				if idx[carry] < pools[carry].size():
					break
				idx[carry] = 0
				carry -= 1
			if carry < 0:
				break
		return result

	## itertools.combinations(iterable, r)
	func _it_combinations(args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLObject:
		if args.size() != 2:
			raise_exception("TypeError", "combinations() takes exactly two arguments")
			return null
		var items: Array[DSLObject] = []
		var it = args[0]._dsl_iter()
		if it == null:
			raise_exception("TypeError", "combinations() argument 1 must be iterable")
			return null
		while it.has_next():
			items.append(it.next())
			if it.suspended:
				break
		var r = int(_num_val(args[1]))
		var result = DSLList.new()
		if r < 0 or r > items.size():
			return result
		_combinations_recursive(items, r, 0, [], result)
		return result

	## 递归生成组合
	func _combinations_recursive(items: Array, r: int, start: int, cur: Array, result: DSLList):
		if cur.size() == r:
			var typed: Array[DSLObject] = []
			for e in cur:
				typed.append(e)
			result.items.append(DSLTuple.new(typed))
			return
		for i in range(start, items.size()):
			cur.append(items[i])
			_combinations_recursive(items, r, i + 1, cur, result)
			cur.pop_back()

	## itertools.permutations(iterable[, r])
	func _it_permutations(args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLObject:
		if args.size() < 1 or args.size() > 2:
			raise_exception("TypeError", "permutations() takes 1 or 2 arguments")
			return null
		var items: Array[DSLObject] = []
		var it = args[0]._dsl_iter()
		if it == null:
			raise_exception("TypeError", "permutations() argument 1 must be iterable")
			return null
		while it.has_next():
			items.append(it.next())
			if it.suspended:
				break
		var r = items.size()
		if args.size() == 2:
			r = int(_num_val(args[1]))
		var result = DSLList.new()
		if r < 0 or r > items.size():
			return result
		var used: Array = []
		for i in range(items.size()):
			used.append(false)
		_permutations_recursive(items, r, [], used, result)
		return result

	## 递归生成排列
	func _permutations_recursive(items: Array, r: int, cur: Array, used: Array, result: DSLList):
		if cur.size() == r:
			var typed: Array[DSLObject] = []
			for e in cur:
				typed.append(e)
			result.items.append(DSLTuple.new(typed))
			return
		for i in range(items.size()):
			if used[i]:
				continue
			used[i] = true
			cur.append(items[i])
			_permutations_recursive(items, r, cur, used, result)
			cur.pop_back()
			used[i] = false

	## itertools.islice(iterable, stop) / (iterable, start, stop[, step]) [br]
	## 惰性消费源迭代器, 仅取到 stop 为止, 因此可作用于无限迭代器 (repeat/cycle/count)
	func _it_islice(args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLObject:
		if args.size() < 2 or args.size() > 4:
			raise_exception("TypeError", "islice() takes 2 to 4 arguments")
			return null
		var start = 0
		var stop = 0
		var step = 1
		if args.size() == 2:
			stop = int(_num_val(args[1]))
		else:
			start = int(_num_val(args[1]))
			stop = int(_num_val(args[2]))
			if args.size() == 4:
				step = int(_num_val(args[3]))
		if step <= 0:
			raise_exception("ValueError", "islice() step must be positive")
			return null
		var it = args[0]._dsl_iter()
		if it == null:
			raise_exception("TypeError", "islice() argument 1 must be iterable")
			return null
		var result = DSLList.new()
		var idx = 0
		var lower = max(start, 0)
		while it.has_next():
			var v = it.next()
			if it.suspended:
				break
			if idx >= lower and idx < stop and (idx - start) % step == 0:
				result.items.append(v)
			idx += 1
			if idx >= stop:
				break
		return result

	## itertools.repeat(obj[, times]) - 重复对象, 指定 times 返回列表, 否则返回无限对象 [br]
	## 无限形式需配合 islice/takewhile 使用
	func _it_repeat(args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLObject:
		if args.size() < 1 or args.size() > 2:
			raise_exception("TypeError", "repeat() takes 1 or 2 arguments")
			return null
		var value = args[0]
		if args.size() == 2:
			var times = int(_num_val(args[1]))
			var result = DSLList.new()
			for i in range(times):
				result.items.append(value)
			return result
		return DSLRepeat.new(value)

	## itertools.cycle(iterable) - 无限循环迭代序列 [br]
	## 返回无限对象, 需配合 islice/takewhile 使用, 空输入返回空列表
	func _it_cycle(args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLObject:
		if args.size() != 1:
			raise_exception("TypeError", "cycle() takes exactly one argument")
			return null
		var items: Array[DSLObject] = []
		var it = args[0]._dsl_iter()
		if it == null:
			raise_exception("TypeError", "cycle() argument must be iterable")
			return null
		while it.has_next():
			items.append(it.next())
			if it.suspended:
				break
		if items.size() == 0:
			return DSLList.new()
		return DSLCycle.new(items)

	## itertools.count(start=0, step=1) - 无限递增计数 [br]
	## 返回无限对象, 需配合 islice/takewhile 使用
	func _it_count(args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLObject:
		if args.size() > 2:
			raise_exception("TypeError", "count() takes at most 2 arguments")
			return null
		var start = 0
		var step = 1
		if args.size() >= 1:
			start = int(_num_val(args[0]))
		if args.size() == 2:
			step = int(_num_val(args[1]))
		return DSLCount.new(start, step)

	## itertools.zip_longest(*iterables, fillvalue=None) - 以最长可迭代对象为准并行配对 [br]
	## 不足处用 fillvalue 填充
	func _it_zip_longest(args: Array[DSLObject], kwargs: Dictionary[String, DSLObject]) -> DSLObject:
		var fillvalue: DSLObject = DSLNone.new()
		if kwargs.has("fillvalue"):
			fillvalue = kwargs["fillvalue"]
		var pools: Array = []
		var max_len = 0
		for arg in args:
			var items: Array[DSLObject] = []
			var it = arg._dsl_iter()
			if it == null:
				raise_exception("TypeError", "zip_longest() arguments must be iterable")
				return null
			while it.has_next():
				items.append(it.next())
				if it.suspended:
					break
			pools.append(items)
			if items.size() > max_len:
				max_len = items.size()
		var result = DSLList.new()
		for i in range(max_len):
			var row: Array[DSLObject] = []
			for pool in pools:
				if i < pool.size():
					row.append(pool[i])
				else:
					row.append(fillvalue)
			result.items.append(DSLTuple.new(row))
		return result

	## itertools.takewhile(predicate, iterable) - 取满足谓词的开头元素, 遇首个不满足即止 [br]
	## 惰性消费, 可作用于无限迭代器
	func _it_takewhile(args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLObject:
		if args.size() != 2:
			raise_exception("TypeError", "takewhile() takes exactly two arguments")
			return null
		var pred = args[0]
		var it = args[1]._dsl_iter()
		if it == null:
			raise_exception("TypeError", "takewhile() argument 2 must be iterable")
			return null
		var result = DSLList.new()
		while it.has_next():
			var v = it.next()
			if it.suspended:
				break
			var r = pred.magic_call([v] as Array[DSLObject], {} as Dictionary[String, DSLObject])
			if r == null:
				return null
			if not r._dsl_bool():
				break
			result.items.append(v)
		return result

	## itertools.dropwhile(predicate, iterable) - 丢弃满足谓词的开头元素, 其余原样返回 [br]
	## 惰性消费, 可作用于无限迭代器
	func _it_dropwhile(args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLObject:
		if args.size() != 2:
			raise_exception("TypeError", "dropwhile() takes exactly two arguments")
			return null
		var pred = args[0]
		var it = args[1]._dsl_iter()
		if it == null:
			raise_exception("TypeError", "dropwhile() argument 2 must be iterable")
			return null
		var result = DSLList.new()
		var dropping = true
		while it.has_next():
			var v = it.next()
			if it.suspended:
				break
			if dropping:
				var r = pred.magic_call([v] as Array[DSLObject], {} as Dictionary[String, DSLObject])
				if r == null:
					return null
				if r._dsl_bool():
					continue
				dropping = false
			result.items.append(v)
		return result

	## itertools.accumulate(iterable[, func][, initial]) [br]
	## 前缀累积, 默认用加法, 返回物化列表 (含初始值)
	func _it_accumulate(args: Array[DSLObject], kwargs: Dictionary[String, DSLObject]) -> DSLObject:
		if args.size() < 1 or args.size() > 3:
			raise_exception("TypeError", "accumulate() takes from 1 to 3 arguments")
			return null
		var it = args[0]._dsl_iter()
		if it == null:
			raise_exception("TypeError", "accumulate() argument 1 must be iterable")
			return null
		var func_obj: DSLObject = null
		if args.size() >= 2 and not (args[1] is DSLNone):
			func_obj = args[1]
		if kwargs.has("func") and not (kwargs["func"] is DSLNone):
			func_obj = kwargs["func"]
		var has_initial = false
		var acc: DSLObject = null
		if args.size() >= 3:
			acc = args[2]
			has_initial = true
		if kwargs.has("initial"):
			acc = kwargs["initial"]
			has_initial = true
		var result = DSLList.new()
		if has_initial:
			result.items.append(acc)
		while it.has_next():
			var v = it.next()
			if it.suspended:
				break
			if acc == null:
				acc = v
			elif func_obj == null:
				acc = acc.magic_add([acc, v] as Array[DSLObject], {} as Dictionary[String, DSLObject])
				if acc == null:
					return null
			else:
				acc = func_obj.magic_call([acc, v] as Array[DSLObject], {} as Dictionary[String, DSLObject])
				if acc == null:
					return null
			result.items.append(acc)
		return result

	## itertools.pairwise(iterable) [br]
	## 相邻元素配对, 返回长度为 n-1 的元组列表
	func _it_pairwise(args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLObject:
		if args.size() != 1:
			raise_exception("TypeError", "pairwise() takes exactly one argument")
			return null
		var it = args[0]._dsl_iter()
		if it == null:
			raise_exception("TypeError", "pairwise() argument must be iterable")
			return null
		var result = DSLList.new()
		if not it.has_next():
			return result
		var prev = it.next()
		while it.has_next():
			var cur = it.next()
			if it.suspended:
				break
			var pair: Array[DSLObject] = [prev, cur]
			result.items.append(DSLTuple.new(pair))
			prev = cur
		return result

	## itertools.groupby(iterable, key=None) [br]
	## 相邻分组, 返回 [(key, [元素...]), ...] 列表
	func _it_groupby(args: Array[DSLObject], kwargs: Dictionary[String, DSLObject]) -> DSLObject:
		if args.size() < 1 or args.size() > 2:
			raise_exception("TypeError", "groupby() takes 1 or 2 arguments")
			return null
		var it = args[0]._dsl_iter()
		if it == null:
			raise_exception("TypeError", "groupby() argument 1 must be iterable")
			return null
		var key_func: DSLObject = null
		if args.size() == 2 and not (args[1] is DSLNone):
			key_func = args[1]
		if kwargs.has("key") and not (kwargs["key"] is DSLNone):
			key_func = kwargs["key"]
		var result = DSLList.new()
		if not it.has_next():
			return result
		var cur_key: DSLObject = null
		var group = DSLList.new()
		var have_group = false
		while it.has_next():
			var v = it.next()
			if it.suspended:
				break
			var k: DSLObject = v
			if key_func != null:
				k = key_func.magic_call([v] as Array[DSLObject], {} as Dictionary[String, DSLObject])
				if k == null:
					return null
			if not have_group:
				cur_key = k
				group = DSLList.new()
				have_group = true
			elif not cur_key._dsl_eq(k):
				var entry: Array[DSLObject] = [cur_key, group]
				result.items.append(DSLTuple.new(entry))
				cur_key = k
				group = DSLList.new()
			group.items.append(v)
		if have_group:
			var last_entry: Array[DSLObject] = [cur_key, group]
			result.items.append(DSLTuple.new(last_entry))
		return result

	## itertools.starmap(func, iterable) [br]
	## 用每组参数解包调用 func, 返回结果列表
	func _it_starmap(args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLObject:
		if args.size() != 2:
			raise_exception("TypeError", "starmap() takes exactly two arguments")
			return null
		var fn = args[0]
		var it = args[1]._dsl_iter()
		if it == null:
			raise_exception("TypeError", "starmap() argument 2 must be iterable")
			return null
		var result = DSLList.new()
		while it.has_next():
			var row = it.next()
			if it.suspended:
				break
			var call_args: Array[DSLObject] = []
			var row_it = row._dsl_iter()
			if row_it == null:
				raise_exception("TypeError", "starmap() argument 2 must be an iterable of iterables")
				return null
			while row_it.has_next():
				call_args.append(row_it.next())
				if row_it.suspended:
					break
			var r = fn.magic_call(call_args, {} as Dictionary[String, DSLObject])
			if r == null:
				return null
			result.items.append(r)
		return result

	## operator 模块: 二元运算通用实现 [br]
	## 构造等价运算符令牌并复用表达式求值路径, 使自定义类的 dunder 同样生效 [br]
	## [param name] operator 函数名 (用于错误信息) [br]
	## [param tok_type] 等价的 TokenType [br]
	## [param args] 两个操作数
	func _op_binary(name: String, tok_type: TokenType, args: Array[DSLObject]) -> DSLObject:
		if args.size() != 2:
			raise_exception("TypeError", "%s expected 2 arguments, got %d" % [name, args.size()])
			return null
		var tok = Token.new(tok_type, name, null, 0, 0)
		var r = _evaluate_binary_op(args[0], tok, args[1])
		if r == null:
			if args[0].last_error != "":
				raise_exception_from_last_error(args[0].last_error)
			else:
				raise_exception("TypeError", "unsupported operand type(s) for %s" % name)
			return null
		return r

	## operator 模块: 一元运算通用实现 [br]
	## [param name] operator 函数名 (用于错误信息) [br]
	## [param dunder] 对应的魔法方法名 [br]
	## [param magic] DSLObject 上的回退方法名 [br]
	## [param args] 单个操作数
	func _op_unary(name: String, dunder: String, magic: String, args: Array[DSLObject]) -> DSLObject:
		if args.size() != 1:
			raise_exception("TypeError", "%s expected 1 argument, got %d" % [name, args.size()])
			return null
		var obj = args[0]
		var fallback = func() -> DSLObject:
			return obj.call(magic, [obj] as Array[DSLObject], {} as Dictionary[String, DSLObject])
		var r = _call_magic_or_fallback(obj, dunder, [] as Array[DSLObject], fallback)
		if r == null:
			if obj.last_error != "":
				raise_exception_from_last_error(obj.last_error, obj.last_error_args)
			else:
				raise_exception("TypeError", "bad operand type for unary %s: '%s'" % [name, obj._type_name()])
			return null
		return r

	## operator.add(a, b)
	func _op_add(args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLObject:
		return _op_binary("add", TokenType.PLUS, args)

	## operator.sub(a, b)
	func _op_sub(args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLObject:
		return _op_binary("sub", TokenType.MINUS, args)

	## operator.mul(a, b)
	func _op_mul(args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLObject:
		return _op_binary("mul", TokenType.STAR, args)

	## operator.truediv(a, b)
	func _op_truediv(args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLObject:
		return _op_binary("truediv", TokenType.SLASH, args)

	## operator.floordiv(a, b)
	func _op_floordiv(args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLObject:
		return _op_binary("floordiv", TokenType.DOUBLESLASH, args)

	## operator.mod(a, b)
	func _op_mod(args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLObject:
		return _op_binary("mod", TokenType.PERCENT, args)

	## operator.pow(a, b)
	func _op_pow(args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLObject:
		return _op_binary("pow", TokenType.STARSTAR, args)

	## operator.and_(a, b)
	func _op_and(args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLObject:
		return _op_binary("and_", TokenType.BITAND, args)

	## operator.or_(a, b)
	func _op_or(args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLObject:
		return _op_binary("or_", TokenType.PIPE, args)

	## operator.xor(a, b)
	func _op_xor(args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLObject:
		return _op_binary("xor", TokenType.CARET, args)

	## operator.lshift(a, b)
	func _op_lshift(args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLObject:
		return _op_binary("lshift", TokenType.LESS_LESS, args)

	## operator.rshift(a, b)
	func _op_rshift(args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLObject:
		return _op_binary("rshift", TokenType.GREATER_GREATER, args)

	## operator.eq(a, b)
	func _op_eq(args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLObject:
		return _op_binary("eq", TokenType.EQUAL_EQUAL, args)

	## operator.ne(a, b)
	func _op_ne(args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLObject:
		return _op_binary("ne", TokenType.NOT_EQUAL, args)

	## operator.lt(a, b)
	func _op_lt(args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLObject:
		return _op_binary("lt", TokenType.LESS, args)

	## operator.le(a, b)
	func _op_le(args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLObject:
		return _op_binary("le", TokenType.LESS_EQUAL, args)

	## operator.gt(a, b)
	func _op_gt(args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLObject:
		return _op_binary("gt", TokenType.GREATER, args)

	## operator.ge(a, b)
	func _op_ge(args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLObject:
		return _op_binary("ge", TokenType.GREATER_EQUAL, args)

	## operator.is_(a, b)
	func _op_is(args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLObject:
		return _op_binary("is_", TokenType.IS, args)

	## operator.is_not(a, b)
	func _op_is_not(args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLObject:
		return _op_binary("is_not", TokenType.IS_NOT, args)

	## operator.concat(a, b) - 序列拼接
	func _op_concat(args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLObject:
		return _op_binary("concat", TokenType.PLUS, args)

	## operator.neg(a)
	func _op_neg(args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLObject:
		return _op_unary("neg", "__neg__", "magic_neg", args)

	## operator.invert(a)
	func _op_invert(args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLObject:
		return _op_unary("invert", "__invert__", "magic_invert", args)

	## operator.pos(a) [br]
	## 数值返回其本身 (布尔按 int 提升), 其他类型尝试 __pos__
	func _op_pos(args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLObject:
		if args.size() != 1:
			raise_exception("TypeError", "pos expected 1 argument, got %d" % args.size())
			return null
		var obj = args[0]
		if obj is DSLBool:
			return DSLInteger.new(1 if obj.value else 0)
		if obj is DSLInteger or obj is DSLFloat:
			return obj
		var fallback = func() -> DSLObject:
			return null
		var r = _call_magic_or_fallback(obj, "__pos__", [] as Array[DSLObject], fallback)
		if r == null:
			raise_exception("TypeError", "bad operand type for unary pos: '%s'" % obj._type_name())
			return null
		return r

	## operator.abs(a)
	func _op_abs(args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLObject:
		return builtin_abs(args, _kwargs)

	## operator.not_(a)
	func _op_not(args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLObject:
		if args.size() != 1:
			raise_exception("TypeError", "not_ expected 1 argument, got %d" % args.size())
			return null
		return DSLBool.new(not args[0]._dsl_bool())

	## operator.truth(a)
	func _op_truth(args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLObject:
		if args.size() != 1:
			raise_exception("TypeError", "truth expected 1 argument, got %d" % args.size())
			return null
		return DSLBool.new(args[0]._dsl_bool())

	## operator.contains(seq, obj) - 注意参数顺序与 in 相反
	func _op_contains(args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLObject:
		if args.size() != 2:
			raise_exception("TypeError", "contains expected 2 arguments, got %d" % args.size())
			return null
		var container = args[0]
		var item = args[1]
		var fallback = func() -> DSLObject:
			return container.magic_contains([container, item] as Array[DSLObject], {} as Dictionary[String, DSLObject])
		var r = _call_magic_or_fallback(container, "__contains__", [item], fallback)
		if r == null:
			if container.last_error != "":
				raise_exception_from_last_error(container.last_error)
			else:
				raise_exception("TypeError", "argument of type '%s' is not a container" % container._type_name())
			return null
		return r

	## operator.getitem(obj, key)
	func _op_getitem(args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLObject:
		if args.size() != 2:
			raise_exception("TypeError", "getitem expected 2 arguments, got %d" % args.size())
			return null
		var r = args[0]._dsl_getitem(args[1])
		if r == null:
			raise_exception_from_last_error(args[0].last_error if args[0].last_error != "" else "TypeError: '%s' object is not subscriptable" % args[0]._type_name())
			return null
		return r

	## operator.setitem(obj, key, value)
	func _op_setitem(args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLObject:
		if args.size() != 3:
			raise_exception("TypeError", "setitem expected 3 arguments, got %d" % args.size())
			return null
		args[0]._dsl_setitem(args[1], args[2])
		if args[0].last_error != "":
			raise_exception_from_last_error(args[0].last_error)
			return null
		return DSLNone.new()

	## operator.delitem(obj, key)
	func _op_delitem(args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLObject:
		if args.size() != 2:
			raise_exception("TypeError", "delitem expected 2 arguments, got %d" % args.size())
			return null
		args[0]._dsl_delitem(args[1])
		if args[0].last_error != "":
			raise_exception_from_last_error(args[0].last_error)
			return null
		return DSLNone.new()

	## operator.countOf(seq, value) - 统计出现次数
	func _op_count_of(args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLObject:
		if args.size() != 2:
			raise_exception("TypeError", "countOf expected 2 arguments, got %d" % args.size())
			return null
		var it = args[0]._dsl_iter()
		if it == null:
			raise_exception("TypeError", "countOf argument 1 must be iterable")
			return null
		var count = 0
		while it.has_next():
			if it.next()._dsl_eq(args[1]):
				count += 1
		return DSLInteger.new(count)

	## operator.indexOf(seq, value) - 首个匹配元素的下标
	func _op_index_of(args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLObject:
		if args.size() != 2:
			raise_exception("TypeError", "indexOf expected 2 arguments, got %d" % args.size())
			return null
		var it = args[0]._dsl_iter()
		if it == null:
			raise_exception("TypeError", "indexOf argument 1 must be iterable")
			return null
		var idx = 0
		while it.has_next():
			if it.next()._dsl_eq(args[1]):
				return DSLInteger.new(idx)
			idx += 1
		if it.suspended:
			# 消费中途挂起: 交由语句重放, 不能当作未找到
			return null
		raise_exception("ValueError", "sequence.index(x): x not in sequence")
		return null

	## operator.length_hint(obj) - 长度提示, 无长度信息时返回 0
	func _op_length_hint(args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLObject:
		if args.size() != 1:
			raise_exception("TypeError", "length_hint expected 1 argument, got %d" % args.size())
			return null
		var hint = _dsl_len_hint(args[0])
		return DSLInteger.new(hint if hint > 0 else 0)

	## operator.itemgetter(key, ...) - 返回按键取值的可调用对象
	func _op_itemgetter(args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLObject:
		if args.size() < 1:
			raise_exception("TypeError", "itemgetter expected at least 1 argument")
			return null
		return DSLItemGetter.new(args.duplicate())

	## operator.attrgetter(name, ...) - 返回按属性取值的可调用对象
	func _op_attrgetter(args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLObject:
		if args.size() < 1:
			raise_exception("TypeError", "attrgetter expected at least 1 argument")
			return null
		var paths: Array = []
		for a in args:
			if not (a is DSLString):
				raise_exception("TypeError", "attrgetter arguments must be strings")
				return null
			paths.append(a.value)
		return DSLAttrGetter.new(paths)

	## 获取对象的长度提示, 无长度信息时返回 -1 (不抛异常) [br]
	## 与 len() 的长度来源一致: 先看 __len__, 再按内置容器类型取大小 [br]
	## [param obj] 目标对象 [br]
	## [returns] 长度, 未知时返回 -1
	func _dsl_len_hint(obj: DSLObject) -> int:
		if obj.klass != null:
			var len_method = obj.klass._lookup_method("__len__")
			if len_method != null:
				var res = obj.klass._invoke_func(len_method, [obj] as Array[DSLObject], {} as Dictionary[String, DSLObject])
				if res is DSLInteger:
					return res.value
		var inner = obj._wrapped if obj._wrapped != null else obj
		if inner is DSLList or inner is DSLTuple:
			return inner.items.size()
		if inner is DSLString:
			return inner.value.length()
		if inner is DSLDict:
			return inner.dict.size()
		if inner is DSLDefaultDict:
			return inner.inner.dict.size()
		if inner is DSLSet:
			return inner.items.size()
		if inner is DSLDictKeys:
			return inner.keys_list.size()
		if inner is DSLDictValues:
			return inner.values_list.size()
		if inner is DSLRange:
			return inner._length()
		if inner is DSLBytes:
			return inner.data.size()
		return -1

	## collections.Counter(iterable) - 统计元素出现次数, 返回字典
	func _col_counter(args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLObject:
		if args.size() > 1:
			raise_exception("TypeError", "Counter() takes at most one argument")
			return null
		# 使用 DSLDefaultDict + int 工厂, 使缺失键返回 0 (与 Python Counter 一致)
		var counter = DSLDefaultDict.new()
		counter.factory = globals.get_val_safe("int")
		counter.is_counter = true
		if args.size() == 0:
			return counter
		var it = args[0]._dsl_iter()
		if it == null:
			raise_exception("TypeError", "Counter() argument must be iterable")
			return null
		while it.has_next():
			var v = it.next()
			if it.suspended:
				break
			var vkey = counter.inner._key_to_variant(v)
			if vkey == null:
				raise_exception("TypeError", "unhashable type in Counter()")
				return null
			if counter.inner.dict.has(vkey):
				var c = counter.inner.dict[vkey]
				counter.inner.dict[vkey] = DSLInteger.new((c.value if c is DSLInteger else 1) + 1)
			else:
				counter.inner.dict[vkey] = DSLInteger.new(1)
		return counter

	## collections.defaultdict(default_factory) - 缺失键自动调用工厂创建
	func _col_defaultdict(args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLObject:
		if args.size() < 1 or args.size() > 2:
			raise_exception("TypeError", "defaultdict() takes 1 or 2 arguments")
			return null
		var factory = args[0] if args.size() >= 1 else null
		var dd = DSLDefaultDict.new()
		dd.factory = factory if (factory != null and not (factory is DSLNone)) else null
		dd.interp = self
		# 可选初始映射 (字典参数)
		if args.size() == 2:
			var src = DSLObject._unwrap_dsl(args[1])
			if src is DSLDict:
				for k in src.dict:
					dd.inner.dict[k] = src.dict[k]
		return dd

	## 创建内置函数的包装对象 [br]
	## [param name] 函数名称 [br]
	## [param method] GDScript Callable
	func _make_builtin(name: String, method: Callable) -> DSLBuiltinFunction:
		return DSLBuiltinFunction.new(name, method)
		
	## 开始解释执行 AST [br]
	## [param statements] 顶层语句列表
	func interpret(statements: Array) -> void:
		step_count = 0
		exec_block(statements, environment)
		if report.has_error:
			report.fatal_error(report.last_error)
			report.has_error = false
			# 未捕获错误已终止本次执行: 清除挂起标志并记录, 使宿主状态机进入终态而非反复恢复
			_suspended = false
			_suspend_reason = SuspendReason.NONE
			_current_generator = null
			_had_fatal_error = true
		
	## 在给定环境中执行语句块并捕获 return/break/continue 信号 [br]
	## [param statements] 语句数组 [br]
	## [param env] 要使用的环境
	func exec_block(statements: Array, env: DSLEnvironment) -> ExecResult:
		var start_pc = 0
		var resume_info = {}
		var prev_sleeps_done = 0
		
		# 搜索整个 _exec_stack 寻找匹配帧 (嵌套调用时栈顶可能是内层帧)
		var match_idx = -1
		for j in range(_exec_stack.size() - 1, -1, -1):
			var f = _exec_stack[j]
			if f.statements == statements and f.env == env:
				match_idx = j
				start_pc = f.pc
				resume_info = f.resume_info if f.has("resume_info") else {}
				prev_sleeps_done = f.get("sleeps_done", 0)
				break
		
		if match_idx >= 0:
			_exec_stack.remove_at(match_idx)
			# 清理栈中重复的 stale 帧 (相同 statements 和 env)
			var j = 0
			while j < _exec_stack.size():
				var sf = _exec_stack[j]
				if sf.statements == statements and sf.env == env:
					_exec_stack.remove_at(j)
				else:
					j += 1
		
		var prev_env = environment
		environment = env
		
		# 压入当前帧
		var frame = {
			"statements": statements,
			"pc": 0,
			"env": env,
			"resume_info": resume_info,
			"sleeps_done": prev_sleeps_done,
			"pass_open": false
		}
		_exec_stack.append(frame)
		
		var i = start_pc
		while i < statements.size():
			if report.has_error:
				_exec_stack.pop_back()
				environment = prev_env
				if last_exception != null:
					return ExecResult.RAISE
				return ExecResult.ERROR
			
			frame.pc = i
			var stmt = statements[i]
			i += 1
			
			var res = execute(stmt)
			# 语句正常结束后清除 resume_info: 它只在语句被挂起后重新进入时才有意义,
			# 否则会泄漏到后续语句 (例如让下一个 if 跳过条件求值)
			if res != ExecResult.SUSPENDED:
				frame.resume_info = {}
				# 消费窗口与生成器记忆都以「重放根语句」为键: 重放根语句执行期间,
				# 其内部语句正常结束不得清空它们 (否则重放时生成器会被重新创建,
				# 导致生成器体重复执行); 只有根语句自身完成才结束本轮
				if _sleep_root_key == 0 or _stmt_key(stmt) == _sleep_root_key:
					_clear_stmt_window(stmt)
					_clear_gen_memo(stmt)
				if _stmt_key(stmt) == _sleep_root_key:
					_sleep_seq = 0
					_sleep_skip = 0
					_sleep_waited = 0
					_sleep_root_key = 0
			# 为直接 report.error 的运行时错误 (如 NameError) 附加行号
			if report.has_error and report.last_error != "" and not report.last_error.contains("(line "):
				report.last_error += " (line %d)" % _current_line
			if res == ExecResult.SUSPENDED:
				if _suspend_reason == SuspendReason.YIELD and _current_generator != null:
					# yield 挂起: 保存本轮已求值子表达式, 供重放轮复用
					_current_generator._yv_commit()
				if _suspend_reason == SuspendReason.SLEEPING:
					# 本轮已等待的睡眠转为「已确认等待」, 下一轮从序号 0 重新计数
					_sleep_skip += _sleep_waited
					_sleep_seq = 0
					_sleep_waited = 0
				# 保存下次恢复的位置
				if _expr_evaluated:
					# 表达式已求值, 跳过当前语句 (如独立语句形式的 sleep)
					frame.pc = i
					_expr_evaluated = false
				else:
					# 表达式未求值, 恢复时重新执行 (含嵌套调用的语句)
					frame.pc = i - 1
					# 仅程序挂起 (sleep/waiting) 需要重放窗口: 消费方会重新执行整条语句,
					# 已产出元素从日志重读, 生成器按出现次序复用
					# yield 挂起由生成器自身状态推进, 回退游标会导致元素重复
					if _suspend_reason != SuspendReason.YIELD:
						_reset_read_marks(stmt)
						# 出现次序须按「重放根语句」的键归零 (与 _memo_generator 取值一致):
						# 若按当前语句键清除, 生成器记忆会读到未归零的旧序号而错误换用新对象
						_gen_occur.erase(_sleep_root_key if _sleep_root_key != 0 else _stmt_key(stmt))
				environment = prev_env
				return ExecResult.SUSPENDED
			if res == ExecResult.ERROR and last_exception != null:
				res = ExecResult.RAISE
			if res != ExecResult.NORMAL:
				_exec_stack.pop_back()
				environment = prev_env
				return res
		
		_exec_stack.pop_back()
		environment = prev_env
		return ExecResult.NORMAL
		
	## 判断语句是否含 yield 表达式 (供生成器侧子表达式记忆启用判定) [br]
	## 递归检查表达式与嵌套语句块, 只做结构判断, 不涉及语义 [br]
	## [param stmt] 语句节点 [br]
	## [returns] 含 yield 时返回 true
	func _stmt_contains_yield(stmt) -> bool:
		if stmt == null:
			return false
		var found = false
		for prop in stmt.get_property_list():
			if prop.usage & PROPERTY_USAGE_SCRIPT_VARIABLE == 0:
				continue
			var value = stmt.get(prop.name)
			if value is Expr:
				if _expr_contains_yield(value):
					return true
			elif value is Array:
				# 只检查语句自身的表达式列表, 不递归进嵌套语句块:
				# 外层 for/while 的 body 含 yield 不代表该语句本身会挂起,
				# 递归会让 n += 1 这类语句被误判 (进而干扰 sleep 重放)
				for item in value:
					if item is Expr and _expr_contains_yield(item):
						return true
		return found
	
	## 判断表达式是否含 yield (递归检查子表达式) [br]
	## [param expr] 表达式节点 [br]
	## [returns] 含 yield 时返回 true
	func _expr_contains_yield(expr) -> bool:
		if expr == null:
			return false
		if expr is YieldExpr:
			return true
		for prop in expr.get_property_list():
			if prop.usage & PROPERTY_USAGE_SCRIPT_VARIABLE == 0:
				continue
			var value = expr.get(prop.name)
			if value is Expr and _expr_contains_yield(value):
				return true
			elif value is Array:
				for item in value:
					if item is Expr and _expr_contains_yield(item):
						return true
		return false
	
	## 执行单条语句, 返回执行结果状态 [br]
	## [param stmt] 语句节点
	func execute(stmt) -> ExecResult:
		if report.has_error:
			return ExecResult.ERROR
			
		if stmt is Stmt:
			_current_line = stmt.line
			
		# 重置当前生成器的 yield 位置计数 (每条语句一个计数周期)
		if _current_generator != null:
			_current_generator._yield_pos = 0
			# 标记本语句是否含 yield (供子表达式记忆启用判定)
			var _prev_has_yield = _stmt_has_yield
			_stmt_has_yield = _stmt_contains_yield(stmt)
			# 准备跨 yield 重放的子表达式记忆 (区分新一轮与重放轮)
			_current_generator._yv_begin_stmt()
			
		# 语句级消费窗口: 记录当前语句标识 (睡眠计数按重放轮次累计, 见 _time_sleep)
		_current_stmt_key = _stmt_key(stmt)
		if _sleep_root_key == 0:
			_sleep_root_key = _current_stmt_key
		_needs_replay = false
			
		step_count += 1
		if step_count > max_steps:
			raise_exception("RuntimeError", "maximum step count exceeded")
			return ExecResult.RAISE
			
		if stmt is ExpressionStmt:
			var val = evaluate(stmt.expression)
			if _suspended:
				_expr_evaluated = (val != null) and not _needs_replay
				return ExecResult.SUSPENDED
			if val == null or report.has_error:
				return ExecResult.ERROR
			return ExecResult.NORMAL
			
		if stmt is IfStmt:
			# 检查 resume_info 是否跳过条件求值
			var frame = _exec_stack.back() if _exec_stack.size() > 0 else {}
			var ri = frame.get("resume_info", {}) if frame is Dictionary else {}
			if ri.get("type") == "if":
				var branch = ri.get("branch", "then")
				if branch == "then":
					return exec_block(stmt.then_branch, environment)
				elif branch == "elif":
					var idx = ri.get("elif_idx", 0)
					return exec_block(stmt.elif_branches[idx][1], environment)
				elif branch == "else":
					if stmt.else_branch.size() > 0:
						return exec_block(stmt.else_branch, environment)
					return ExecResult.NORMAL
			
			var cond = evaluate(stmt.condition)
			if _suspended:
				_expr_evaluated = (cond != null) and not _needs_replay
				return ExecResult.SUSPENDED
			if cond == null or report.has_error:
				return ExecResult.ERROR
			if cond._dsl_bool():
				# 设置 resume_info
				var f = _exec_stack.back() if _exec_stack.size() > 0 else null
				if f != null and f is Dictionary:
					f.resume_info = {"type": "if", "branch": "then"}
				return exec_block(stmt.then_branch, environment)
			else:
				for branch_idx in range(stmt.elif_branches.size()):
					var branch = stmt.elif_branches[branch_idx]
					cond = evaluate(branch[0])
					if _suspended:
						_expr_evaluated = (cond != null) and not _needs_replay
						return ExecResult.SUSPENDED
					if cond == null or report.has_error:
						return ExecResult.ERROR
					if cond._dsl_bool():
						var f = _exec_stack.back() if _exec_stack.size() > 0 else null
						if f != null and f is Dictionary:
							f.resume_info = {"type": "if", "branch": "elif", "elif_idx": branch_idx}
						return exec_block(branch[1], environment)
				if stmt.else_branch.size() > 0:
					var f = _exec_stack.back() if _exec_stack.size() > 0 else null
					if f != null and f is Dictionary:
						f.resume_info = {"type": "if", "branch": "else"}
					return exec_block(stmt.else_branch, environment)
			return ExecResult.NORMAL
		
		if stmt is WhileStmt:
			# 检查 resume_info 是否跳过条件求值
			var frame = _exec_stack.back() if _exec_stack.size() > 0 else {}
			var ri = frame.get("resume_info", {}) if frame is Dictionary else {}
			if ri.get("type") == "while_else":
				# 恢复被挂起的 else 体
				var we_env = ri.get("else_env")
				if we_env == null:
					we_env = DSLEnvironment.new(environment.report, environment)
				return exec_block(stmt.get_meta("_else_body"), we_env)
			var skip_cond = ri.get("type") == "while"
			
			var did_break = false
			while true:
				if not skip_cond:
					var cond = evaluate(stmt.condition)
					if _suspended:
						_expr_evaluated = (cond != null) and not _needs_replay
						_exec_stack.back().resume_info = {"type": "while"}
						return ExecResult.SUSPENDED
					if cond == null or report.has_error:
						return ExecResult.ERROR
					if not cond._dsl_bool():
						break
				skip_cond = false
				
				# 设置 resume_info
				var f = _exec_stack.back() if _exec_stack.size() > 0 else null
				if f != null and f is Dictionary:
					f.resume_info = {"type": "while"}
				
				var res = exec_block(stmt.body, environment)
				if res == ExecResult.BREAK:
					did_break = true
					break
				elif res == ExecResult.CONTINUE:
					continue
				elif res == ExecResult.ERROR or res == ExecResult.RETURN or res == ExecResult.RAISE or res == ExecResult.SUSPENDED:
					return res
			if not did_break and stmt.has_meta("_else_body"):
				var else_body = stmt.get_meta("_else_body")
				var we_env = DSLEnvironment.new(environment.report, environment)
				if _exec_stack.size() > 0:
					_exec_stack.back().resume_info = {"type": "while_else", "else_env": we_env}
				var else_res = exec_block(else_body, we_env)
				if else_res != ExecResult.NORMAL:
					return else_res
			return ExecResult.NORMAL
			
		if stmt is ForStmt:
			# 检查 resume_info 是否跳过迭代器重建
			var frame = _exec_stack.back() if _exec_stack.size() > 0 else {}
			var ri = frame.get("resume_info", {}) if frame is Dictionary else {}
			var iterator = null
			var did_break = false
			var is_body_resume = false
			
			if ri.get("type") == "for_else":
				# 恢复被挂起的 else 体
				var fe_env = ri.get("else_env")
				if fe_env == null:
					fe_env = DSLEnvironment.new(environment.report, environment)
				return exec_block(stmt.get_meta("_else_body"), fe_env)
			
			if ri.get("type") == "for":
				# 从 resume_info 恢复迭代器
				iterator = ri.get("iterator")
				is_body_resume = ri.get("body_resume", false)
				if iterator == null:
					raise_exception("RuntimeError", "cannot resume for loop: iterator lost")
					return ExecResult.RAISE
			else:
				var iterable = evaluate(stmt.iterable)
				if _suspended:
					_expr_evaluated = (iterable != null) and not _needs_replay
					return ExecResult.SUSPENDED
				if iterable == null or iterable is DSLNone:
					raise_exception("RuntimeError", "iterable is null in for loop")
					return ExecResult.RAISE
				iterator = iterable._dsl_iter()
				if iterator == null:
					raise_exception_from_last_error(iterable.last_error if iterable.last_error else "TypeError: object is not iterable")
					return ExecResult.RAISE
				# for 语句的迭代器不参与语句消费窗口: 循环自身的进度由 resume_info
				# 保存的迭代器对象与循环变量维护, 重放时由本分支重新推进;
				# 若叠加窗口, 重放会把游标退回窗口起点, 使已交付的元素被再次产出
				iterator.windowed = false
			
			var first_iter = true
			while true:
				# 恢复被挂起的 body 时不推进迭代器 (循环变量仍是挂起迭代的值)
				if is_body_resume and first_iter:
					is_body_resume = false
				else:
					# 即将推进迭代器: 清除上一轮遗留的 body_resume 标记,
					# 使此处挂起时的重放重新推进 (而不是重跑 body 造成重复产出)
					var adv_frame = _exec_stack.back() if _exec_stack.size() > 0 else null
					if adv_frame != null and adv_frame is Dictionary:
						adv_frame.resume_info = {"type": "for", "iterator": iterator, "body_resume": false}
					if not iterator.has_next():
						if iterator.suspended:
							# 内层迭代器因程序挂起 (sleep) 中断, 而非耗尽
							# 向上传播为程序挂起, 由语句重放机制接管续跑
							iterator.suspended = false
							_suspended = true
							_suspend_reason = SuspendReason.SLEEPING
							_needs_replay = true
							return ExecResult.SUSPENDED
						if report.has_error:
							# 迭代器推进时抛出异常, 而非耗尽:
							# 向上传播, 使外层 try/except 能捕获 (否则错误被本语句吞掉)
							return ExecResult.RAISE if last_exception != null else ExecResult.ERROR
						break
					var item = iterator.next()
					if stmt.variables.size() == 1:
						environment.set_val(stmt.variables[0], item)
					else:
						var seq = item
						if item is DSLList or item is DSLTuple:
							seq = item.items
						elif typeof(item) == TYPE_ARRAY:
							seq = item
						else:
							raise_exception("TypeError", "Cannot unpack non-sequence")
							return ExecResult.RAISE
						if seq.size() != stmt.variables.size():
							raise_exception("ValueError", "Unpacking mismatch: expected %d, got %d" % [stmt.variables.size(), seq.size()])
							return ExecResult.RAISE
						for j in range(stmt.variables.size()):
							environment.set_val(stmt.variables[j], seq[j] if seq[j] is DSLObject else _wrap(seq[j]))
				first_iter = false
				
				# 设置 resume_info
				var f = _exec_stack.back() if _exec_stack.size() > 0 else null
				if f != null and f is Dictionary:
					f.resume_info = {"type": "for", "iterator": iterator, "body_resume": true}
				
				var res = exec_block(stmt.body, environment)
				if res == ExecResult.BREAK:
					did_break = true
					break
				elif res == ExecResult.CONTINUE:
					continue
				elif res == ExecResult.RETURN or res == ExecResult.RAISE or res == ExecResult.ERROR or res == ExecResult.SUSPENDED:
					return res
			if not did_break and stmt.has_meta("_else_body"):
				var else_body = stmt.get_meta("_else_body")
				var fe_env = DSLEnvironment.new(environment.report, environment)
				if _exec_stack.size() > 0:
					_exec_stack.back().resume_info = {"type": "for_else", "else_env": fe_env}
				var else_res = exec_block(else_body, fe_env)
				if else_res != ExecResult.NORMAL:
					return else_res
			return ExecResult.NORMAL
			
		if stmt is FunctionStmt:
			var func_obj = DSLFunction.new(stmt, environment)
			func_obj._cls_interp = self
			environment.define(stmt.name, func_obj)
			if func_obj is DSLFunction:
				for p in stmt.params:
					if p.is_args or p.is_kwargs:
						func_obj.default_values.append(null)
						continue
					if p.default_value != null:
						var prev_env = environment
						environment = func_obj.closure
						var val = evaluate(p.default_value)
						environment = prev_env
						func_obj.default_values.append(val)
					else:
						func_obj.default_values.append(null)
			return ExecResult.NORMAL
			
		if stmt is ClassStmt:
			return execute_class(stmt)
			
		if stmt is ReturnStmt:
			return_value = evaluate(stmt.value) if stmt.value else DSLNone.new()
			if _suspended:
				_expr_evaluated = (return_value != null) and not _needs_replay
				return ExecResult.SUSPENDED
			if stmt.value and (return_value == null or report.has_error):
				return ExecResult.ERROR
			return ExecResult.RETURN
			
		if stmt is BreakStmt:
			return ExecResult.BREAK
			
		if stmt is ContinueStmt:
			return ExecResult.CONTINUE
		
		if stmt is GlobalStmt:
			var env = environment
			while env.enclosing:
				env = env.enclosing
			if not env.values.has(stmt.name):
				env.define(stmt.name, DSLNone.new())
			environment.mark_global(stmt.name)
			return ExecResult.NORMAL
			
		if stmt is NonlocalStmt:
			for name in stmt.names:
				var env = environment.enclosing
				while env and env != globals:
					if env.values.has(name):
						environment.mark_nonlocal(name, env)
						break
				if not (env and env != globals):
					raise_exception("SyntaxError", "no binding for nonlocal '%s'" % name)
					return ExecResult.RAISE
			return ExecResult.NORMAL
		
		if stmt is AssertStmt:
			var test_val = evaluate(stmt.test)
			if _suspended:
				_expr_evaluated = (test_val != null) and not _needs_replay
				return ExecResult.SUSPENDED
			if test_val == null:
				return ExecResult.ERROR
			if not test_val._dsl_bool():
				var msg = ""
				if stmt.message != null:
					var msg_val = evaluate(stmt.message)
					if msg_val != null:
						msg = msg_val._dsl_str()
				raise_exception("AssertionError", msg)
				return ExecResult.ERROR
			return ExecResult.NORMAL

		if stmt is PassStmt:
			return ExecResult.NORMAL

		if stmt is DelStmt:
			for target in stmt.targets:
				if target is Variable:
					environment.delete(target.name)
					if report.has_error:
						raise_exception_from_last_error(report.last_error)
						return ExecResult.RAISE
				elif target is GetAttr:
					var obj = evaluate(target.object)
					if _suspended:
						_expr_evaluated = false
						return ExecResult.SUSPENDED
					if obj == null:
						return ExecResult.ERROR
					obj._dsl_delattr(target.name)
					if obj.last_error != "":
						raise_exception_from_last_error(obj.last_error, obj.last_error_args)
						return ExecResult.RAISE
				elif target is GetItem:
					var obj = evaluate(target.object)
					if _suspended:
						_expr_evaluated = false
						return ExecResult.SUSPENDED
					if obj == null:
						return ExecResult.ERROR
					var index = evaluate(target.index)
					if _suspended:
						_expr_evaluated = false
						return ExecResult.SUSPENDED
					if index == null:
						return ExecResult.ERROR
					obj._dsl_delitem(index)
					if obj.last_error != "":
						raise_exception_from_last_error(obj.last_error, obj.last_error_args)
						return ExecResult.RAISE
			return ExecResult.NORMAL
		
		if stmt is RaiseStmt:
			if stmt.expression != null:
				var exc = evaluate(stmt.expression)
				if exc == null:
					return ExecResult.RAISE
				var is_valid = false
				var err_type = ""
				var err_msg = ""
				if exc is DSLException:
					is_valid = true
					err_type = exc.error_type
					err_msg = exc.message
				elif exc.fields != null:
					var exc_type = globals.get_val("Exception")
					if exc_type is DSLClass and exc._is_subclass_of_klass(exc_type):
						is_valid = true
						err_type = exc._type_name()
						if exc._wrapped != null and exc._wrapped is DSLException:
							err_msg = exc._wrapped.message
						elif exc.fields.has("args") and exc.fields["args"] is DSLTuple and exc.fields["args"].items.size() > 0:
							err_msg = exc.fields["args"].items[0]._dsl_str()
				if is_valid:
					last_exception = exc
					report.error(err_type + ": " + err_msg)
				else:
					raise_exception("TypeError", "exceptions must derive from Exception")
				return ExecResult.RAISE
			else:
				if last_exception == null:
					raise_exception("RuntimeError", "No active exception to re-raise")
					return ExecResult.RAISE
				var err_type = ""
				var err_msg = ""
				if last_exception is DSLException:
					err_type = last_exception.error_type
					err_msg = last_exception.message
				elif last_exception.fields != null:
					err_type = last_exception._type_name()
					if last_exception._wrapped != null and last_exception._wrapped is DSLException:
						err_msg = last_exception._wrapped.message
					elif last_exception.fields.has("args") and last_exception.fields["args"] is DSLTuple and last_exception.fields["args"].items.size() > 0:
						err_msg = last_exception.fields["args"].items[0]._dsl_str()
				if err_type != "":
					report.error(err_type + ": " + err_msg)
				return ExecResult.RAISE
		
		if stmt is TryStmt:
			var frame = _exec_stack.back() if _exec_stack.size() > 0 else {}
			var ri = frame.get("resume_info", {}) if frame is Dictionary else {}
			var stage = ri.get("try_stage", "")
			var exc_idx = ri.get("except_idx", 0)
			var res = ExecResult.NORMAL
			
			if stage == "except":
				# 恢复被挂起的 except 体 (从保存的 pc 继续)
				if exc_idx < stmt.except_clauses.size():
					res = exec_block(stmt.except_clauses[exc_idx].body, environment)
				if res == ExecResult.RAISE or res == ExecResult.SUSPENDED:
					return res
			elif stage == "finally":
				# 恢复被挂起的 finally 体
				return exec_block(stmt.finally_body, environment)
			else:
				# 首次执行或恢复 try 体
				if stage != "try" and _exec_stack.size() > 0:
					_exec_stack.back().resume_info = {"try_stage": "try"}
				res = exec_block(stmt.try_body, environment)
				if res == ExecResult.SUSPENDED:
					return res
			
			# 处理 try 体结果 (异常分发, 首次执行与 try 体恢复后共用)
			if res == ExecResult.RAISE:
				var caught = false
				for i in range(stmt.except_clauses.size()):
					var clause = stmt.except_clauses[i]
					if _is_exception_match(last_exception, clause.exception_type):
						report.clear_error()
						if clause.as_name != "":
							environment.define(clause.as_name, last_exception)
						if _exec_stack.size() > 0:
							_exec_stack.back().resume_info = {"try_stage": "except", "except_idx": i}
						res = exec_block(clause.body, environment)
						if res == ExecResult.RAISE or res == ExecResult.SUSPENDED:
							return res
						last_exception = null
						caught = true
						break
				if not caught:
					res = ExecResult.RAISE
			
			if stmt.finally_body.size() > 0:
				if _exec_stack.size() > 0:
					_exec_stack.back().resume_info = {"try_stage": "finally"}
				var saved_has_error = report.has_error
				report.has_error = false
				var fin_res = exec_block(stmt.finally_body, environment)
				report.has_error = saved_has_error or report.has_error
				if fin_res != ExecResult.NORMAL:
					return fin_res
			
			return res
			
		if stmt is ImportStmt:
			for entry in stmt.names:
				var mod = _get_module(entry.name)
				if mod == null:
					raise_exception("ImportError", "No module named '%s'" % entry.name)
					return ExecResult.RAISE
				var bind_name = entry.alias if entry.alias != "" else entry.name
				environment.define(bind_name, mod)
			return ExecResult.NORMAL
			
		if stmt is FromImportStmt:
			var mod = _get_module(stmt.module)
			if mod == null:
				raise_exception("ImportError", "No module named '%s'" % stmt.module)
				return ExecResult.RAISE
			if stmt.star:
				# from module import *: 导入所有非下划线开头的公开成员
				for attr_name in mod.members:
					if not attr_name.begins_with("_"):
						environment.define(attr_name, mod.members[attr_name])
			else:
				for entry in stmt.names:
					if not mod.members.has(entry.name):
						raise_exception("ImportError", "cannot import name '%s' from module '%s'" % [entry.name, stmt.module])
						return ExecResult.RAISE
					var bind_name = entry.alias if entry.alias != "" else entry.name
					environment.define(bind_name, mod.members[entry.name])
			return ExecResult.NORMAL
			
		return ExecResult.NORMAL

	## 执行 yield from 语句 (语句级执行器) [br]
	## 子迭代器状态保存在当前帧的 resume_info 中, 恢复时从挂起点继续 [br]
	## 对二元表达式求值, 返回对应的 DSLObject [br]
	## 通过 _call_magic_or_fallback 先查类方法, 再 fallback 到内置 magic_* 多态方法 [br]
	## [param left] 左操作数 [br]
	## [param op_token] 运算符 Token [br]
	## [param right] 右操作数 [br]
	## [returns] 运算结果 DSLObject, 出错时返回 null
	func _evaluate_binary_op(left: DSLObject, op_token: Token, right: DSLObject) -> DSLObject:
		var result: DSLObject = null
		match op_token.type:
			TokenType.PLUS:
				result = _call_magic_or_fallback(left, "__add__", [right], func(): return left.magic_add([left, right] as Array[DSLObject], {} as Dictionary[String, DSLObject]))
			TokenType.MINUS:
				result = _call_magic_or_fallback(left, "__sub__", [right], func(): return left.magic_sub([left, right] as Array[DSLObject], {} as Dictionary[String, DSLObject]))
			TokenType.STAR:
				result = _call_magic_or_fallback(left, "__mul__", [right], func(): return left.magic_mul([left, right] as Array[DSLObject], {} as Dictionary[String, DSLObject]))
			TokenType.SLASH:
				result = _call_magic_or_fallback(left, "__truediv__", [right], func(): return left.magic_div([left, right] as Array[DSLObject], {} as Dictionary[String, DSLObject]))
			TokenType.DOUBLESLASH:
				result = _call_magic_or_fallback(left, "__floordiv__", [right], func(): return left.magic_floordiv([left, right] as Array[DSLObject], {} as Dictionary[String, DSLObject]))
			TokenType.STARSTAR:
				result = _call_magic_or_fallback(left, "__pow__", [right], func(): return left.magic_pow([left, right] as Array[DSLObject], {} as Dictionary[String, DSLObject]))
			TokenType.PERCENT:
				result = _call_magic_or_fallback(left, "__mod__", [right], func(): return left.magic_mod([left, right] as Array[DSLObject], {} as Dictionary[String, DSLObject]))
			TokenType.LESS_LESS:
				result = _call_magic_or_fallback(left, "__lshift__", [right], func(): return left.magic_lshift([left, right] as Array[DSLObject], {} as Dictionary[String, DSLObject]))
			TokenType.GREATER_GREATER:
				result = _call_magic_or_fallback(left, "__rshift__", [right], func(): return left.magic_rshift([left, right] as Array[DSLObject], {} as Dictionary[String, DSLObject]))
			TokenType.CARET:
				result = _call_magic_or_fallback(left, "__xor__", [right], func(): return left.magic_xor([left, right] as Array[DSLObject], {} as Dictionary[String, DSLObject]))
			TokenType.PIPE:
				result = _call_magic_or_fallback(left, "__or__", [right], func(): return left.magic_or([left, right] as Array[DSLObject], {} as Dictionary[String, DSLObject]))
			TokenType.BITAND:
				result = _call_magic_or_fallback(left, "__and__", [right], func(): return left.magic_and([left, right] as Array[DSLObject], {} as Dictionary[String, DSLObject]))
			TokenType.EQUAL_EQUAL:
				result = _call_magic_or_fallback(left, "__eq__", [right], func(): return left.magic_eq([left, right] as Array[DSLObject], {} as Dictionary[String, DSLObject]))
			TokenType.NOT_EQUAL:
				result = _call_magic_or_fallback(left, "__ne__", [right], func(): return left.magic_ne([left, right] as Array[DSLObject], {} as Dictionary[String, DSLObject]))
			TokenType.GREATER:
				result = _call_magic_or_fallback(left, "__gt__", [right], func(): return left.magic_gt([left, right] as Array[DSLObject], {} as Dictionary[String, DSLObject]))
			TokenType.GREATER_EQUAL:
				result = _call_magic_or_fallback(left, "__ge__", [right], func(): return left.magic_ge([left, right] as Array[DSLObject], {} as Dictionary[String, DSLObject]))
			TokenType.LESS:
				result = _call_magic_or_fallback(left, "__lt__", [right], func(): return left.magic_lt([left, right] as Array[DSLObject], {} as Dictionary[String, DSLObject]))
			TokenType.LESS_EQUAL:
				result = _call_magic_or_fallback(left, "__le__", [right], func(): return left.magic_le([left, right] as Array[DSLObject], {} as Dictionary[String, DSLObject]))
			TokenType.AND:
				result = left if not left._dsl_bool() else right
			TokenType.OR:
				result = left if left._dsl_bool() else right
			TokenType.IS:
				result = DSLBool.new(left._object_id == right._object_id)
			TokenType.IS_NOT:
				result = DSLBool.new(left._object_id != right._object_id)
			TokenType.IN:
				result = _call_magic_or_fallback(right, "__contains__", [left], func(): return right.magic_contains([right, left] as Array[DSLObject], {} as Dictionary[String, DSLObject]))
			TokenType.NOT_IN:
				result = _call_magic_or_fallback(right, "__contains__", [left], func(): return right.magic_contains([right, left] as Array[DSLObject], {} as Dictionary[String, DSLObject]))
				if result is DSLBool:
					result = DSLBool.new(not result.value)
		return result
	
	## 对表达式求值, 返回对应的 DSLObject [br]
	## 根据表达式类型分发到不同的求值逻辑 [br]
	## 运行时若接收到返回值为 DSLObject, 实际为 null, 应获取相关的 DSLObject 并读取其 last_error 数据 [br]
	## [param expr] 表达式节点 [br]
	## [returns] 求值结果 DSLObject, 出错时返回 null
	func evaluate(expr) -> DSLObject:
		if _suspended:
			return null
		if expr is YieldExpr:
			return _evaluate_yield(expr)
		if expr is Literal:
			return _wrap(expr.value)
			
		if expr is Variable:
			var val = environment.get_val(expr.name)
			if val == null:
				raise_exception("NameError", "name '%s' is not defined" % expr.name)
				return null
			return val
			
		if expr is Assign:
			var value = evaluate(expr.value)
			if value == null:
				return null
			environment.set_val(expr.name, value)
			if report.has_error:
				return null
			return value

		if expr is WalrusExpr:
			var value = evaluate(expr.value)
			if value == null:
				return null
			environment.set_val(expr.name, value)
			if report.has_error:
				return null
			return value
		
		if expr is AugAssign:
			var current = environment.get_val(expr.name)
			if current == null:
				return null
			var value = evaluate(expr.value)
			if value == null:
				return null
			var result = _aug_assign_compute(current, expr.operator, value)
			if result == null:
				return null
			environment.set_val(expr.name, result)
			return result
		
		if expr is AugAssignAttr:
			var obj = evaluate(expr.object)
			if obj == null:
				return null
			var current = obj._dsl_getattribute(expr.name)
			if current == null or report.has_error:
				return null
			var value = evaluate(expr.value)
			if value == null:
				return null
			var result = _aug_assign_compute(current, expr.operator, value)
			if result == null:
				return null
			obj._dsl_setattr(expr.name, result)
			return result
		
		if expr is AugAssignItem:
			var obj = evaluate(expr.object)
			if obj == null:
				return null
			var idx = evaluate(expr.index)
			if idx == null:
				return null
			var current = obj._dsl_getitem(idx)
			if current == null or report.has_error:
				return null
			var value = evaluate(expr.value)
			if value == null:
				return null
			var result = _aug_assign_compute(current, expr.operator, value)
			if result == null:
				return null
			obj._dsl_setitem(idx, result)
			return result
		
		if expr is UnpackAssign:
			var val = evaluate(expr.value)
			if val == null or val is DSLNone:
				raise_exception("TypeError", "cannot unpack None")
				return null
			var items: Array[DSLObject] = []
			var iter = val._dsl_iter()
			if iter == null:
				raise_exception("TypeError", "cannot unpack non-iterable object")
				return null
			while iter.has_next():
				items.append(iter.next())
				if iter.suspended:
					break
			var nullflag = assign_from_targets(expr.targets, items, environment)
			return null if nullflag == null else val
			
		if expr is SetItem:
			# expr.object 可能是普通表达式, 也可能是嵌套的赋值目标 (如 self._data[k] 里的 self._data):
			# 统一经 _eval_target_object 求值, 使单目标赋值与多重赋值行为一致
			var obj = _eval_target_object(expr.object)
			if obj == null:
				return null
			var idx = evaluate(expr.index)
			if idx == null:
				return null
			var val = evaluate(expr.value)
			if val == null:
				return null
			obj._dsl_setitem(idx, val)
			if obj.last_error != "":
				raise_exception_from_last_error(obj.last_error, obj.last_error_args)
				return null
			return val
			
		if expr is CompareChainExpr:
			var left = evaluate(expr.left)
			if left == null:
				return null
			for i in range(expr.ops.size()):
				var right = evaluate(expr.comparators[i])
				if right == null:
					return null
				var op_token = expr.ops[i]
				var result = _evaluate_binary_op(left, op_token, right)
				if result is DSLBool and not result.value:
					return DSLBool.new(false)
				left = right
			return DSLBool.new(true)

		if expr is Binary:
			# 仅当所在语句含 yield 时才经记忆: sleep 重放由消费窗口负责,
			# 若在此处记忆会与睡眠去重冲突 (如 n += 1 里的加法)
			var _bin_gen = _current_generator
			var _use_memo = _bin_gen != null and (_bin_gen._yv_replay or _bin_gen._pending_yield_index > 0)
			if not _use_memo and _bin_gen != null and _stmt_has_yield:
				_use_memo = true
			var left = null
			var right = null
			if _use_memo:
				left = _bin_gen._yv_memo(expr.left, 0, func(): return evaluate(expr.left))
				right = _bin_gen._yv_memo(expr.right, 1, func(): return evaluate(expr.right))
			else:
				left = evaluate(expr.left)
				right = evaluate(expr.right)
			var result: DSLObject = null
			if left == null or right == null:
				return null
			match expr.operator.type:
				TokenType.PLUS:
					result = _call_magic_or_fallback(left, "__add__", [right], func(): return left.magic_add([left, right] as Array[DSLObject], {} as Dictionary[String, DSLObject]))
				TokenType.MINUS:
					result = _call_magic_or_fallback(left, "__sub__", [right], func(): return left.magic_sub([left, right] as Array[DSLObject], {} as Dictionary[String, DSLObject]))
				TokenType.STAR:
					result = _call_magic_or_fallback(left, "__mul__", [right], func(): return left.magic_mul([left, right] as Array[DSLObject], {} as Dictionary[String, DSLObject]))
				TokenType.SLASH:
					result = _call_magic_or_fallback(left, "__truediv__", [right], func(): return left.magic_div([left, right] as Array[DSLObject], {} as Dictionary[String, DSLObject]))
				TokenType.DOUBLESLASH:
					result = _call_magic_or_fallback(left, "__floordiv__", [right], func(): return left.magic_floordiv([left, right] as Array[DSLObject], {} as Dictionary[String, DSLObject]))
				TokenType.STARSTAR:
					result = _call_magic_or_fallback(left, "__pow__", [right], func(): return left.magic_pow([left, right] as Array[DSLObject], {} as Dictionary[String, DSLObject]))
				TokenType.PERCENT:
					result = _call_magic_or_fallback(left, "__mod__", [right], func(): return left.magic_mod([left, right] as Array[DSLObject], {} as Dictionary[String, DSLObject]))
				TokenType.LESS_LESS:
					result = _call_magic_or_fallback(left, "__lshift__", [right], func(): return left.magic_lshift([left, right] as Array[DSLObject], {} as Dictionary[String, DSLObject]))
				TokenType.GREATER_GREATER:
					result = _call_magic_or_fallback(left, "__rshift__", [right], func(): return left.magic_rshift([left, right] as Array[DSLObject], {} as Dictionary[String, DSLObject]))
				TokenType.CARET:
					result = _call_magic_or_fallback(left, "__xor__", [right], func(): return left.magic_xor([left, right] as Array[DSLObject], {} as Dictionary[String, DSLObject]))
				TokenType.PIPE:
					result = _call_magic_or_fallback(left, "__or__", [right], func(): return left.magic_or([left, right] as Array[DSLObject], {} as Dictionary[String, DSLObject]))
				TokenType.BITAND:
					result = _call_magic_or_fallback(left, "__and__", [right], func(): return left.magic_and([left, right] as Array[DSLObject], {} as Dictionary[String, DSLObject]))
				TokenType.EQUAL_EQUAL:
					result = _call_magic_or_fallback(left, "__eq__", [right], func(): return left.magic_eq([left, right] as Array[DSLObject], {} as Dictionary[String, DSLObject]))
				TokenType.NOT_EQUAL:
					result = _call_magic_or_fallback(left, "__ne__", [right], func(): return left.magic_ne([left, right] as Array[DSLObject], {} as Dictionary[String, DSLObject]))
				TokenType.GREATER:
					result = _call_magic_or_fallback(left, "__gt__", [right], func(): return left.magic_gt([left, right] as Array[DSLObject], {} as Dictionary[String, DSLObject]))
				TokenType.GREATER_EQUAL:
					result = _call_magic_or_fallback(left, "__ge__", [right], func(): return left.magic_ge([left, right] as Array[DSLObject], {} as Dictionary[String, DSLObject]))
				TokenType.LESS:
					result = _call_magic_or_fallback(left, "__lt__", [right], func(): return left.magic_lt([left, right] as Array[DSLObject], {} as Dictionary[String, DSLObject]))
				TokenType.LESS_EQUAL:
					result = _call_magic_or_fallback(left, "__le__", [right], func(): return left.magic_le([left, right] as Array[DSLObject], {} as Dictionary[String, DSLObject]))
				TokenType.AND:
					result = left if not left._dsl_bool() else right
				TokenType.OR:
					result = left if left._dsl_bool() else right
				TokenType.IS:
					result = DSLBool.new(left._object_id == right._object_id)
				TokenType.IS_NOT:
					result = DSLBool.new(left._object_id != right._object_id)
				TokenType.IN:
					result = _call_magic_or_fallback(right, "__contains__", [left], func(): return right.magic_contains([right, left] as Array[DSLObject], {} as Dictionary[String, DSLObject]))
				TokenType.NOT_IN:
					result = _call_magic_or_fallback(right, "__contains__", [left], func(): return right.magic_contains([right, left] as Array[DSLObject], {} as Dictionary[String, DSLObject]))
					if result is DSLBool:
						result = DSLBool.new(not result.value)
			# 用户魔术方法 (__eq__ / __add__ 等) 内部发起程序挂起时返回 null:
			# 这不是运算失败, 而是本次结果尚未产生, 交回上层语句重放
			if _suspended:
				return null
			if left.last_error != "" or right.last_error != "":
				raise_exception_from_last_error(left.last_error if left.last_error else right.last_error)
				return null
			if result == null:
				raise_exception("RuntimeError", "Unknown binary operation error")
				return null
			return result
					
		if expr is Unary:
			var right = evaluate(expr.right)
			if right == null:
				return null
			match expr.operator.type:
				TokenType.MINUS:
					if right.klass != null:
						var result = _call_magic_or_fallback(right, "__neg__", [], func(): return right.magic_neg([right] as Array[DSLObject], {} as Dictionary[String, DSLObject]))
						if result == null:
							if right.last_error != "":
								raise_exception_from_last_error(right.last_error)
							else:
								raise_exception("TypeError", "unsupported operand type for unary -")
							return null
						return result
					else:
						var res = right.magic_neg([right] as Array[DSLObject], {} as Dictionary[String, DSLObject])
						if res == null:
							if right.last_error != "":
								raise_exception_from_last_error(right.last_error)
							else:
								raise_exception("TypeError", "unsupported operand type for unary -")
							return null
						return res
				TokenType.BANG, TokenType.NOT:
					return DSLBool.new(not right._dsl_bool())
				TokenType.TILDE:
					if right.klass != null:
						var result = _call_magic_or_fallback(right, "__invert__", [], func(): return right.magic_invert([right] as Array[DSLObject], {} as Dictionary[String, DSLObject]))
						if result == null:
							if right.last_error != "":
								raise_exception_from_last_error(right.last_error)
							else:
								raise_exception("TypeError", "unsupported operand type for unary ~")
							return null
						return result
					else:
						var res = right.magic_invert([right] as Array[DSLObject], {} as Dictionary[String, DSLObject])
						if res == null:
							if right.last_error != "":
								raise_exception_from_last_error(right.last_error)
							else:
								raise_exception("TypeError", "unsupported operand type for unary ~")
							return null
						return res
				
		if expr is ConditionalExpr:
			var cond = evaluate(expr.condition)
			if cond == null:
				return null
			if cond._dsl_bool():
				return evaluate(expr.true_expr)
			else:
				return evaluate(expr.false_expr)
				
		if expr is Call:
			# _current_call_node 在本 Call 求值期间保持为自身节点, 供 call_user_function 复用生成器对象;
			# 求值结束后恢复调用方的节点 (嵌套调用互不干扰)
			var prev_call_node = _current_call_node
			_current_call_node = expr
			var callee = evaluate(expr.callee_expr)
			if callee == null:
				_current_call_node = prev_call_node
				return null
			var pos_args: Array[DSLObject] = []
			var _arg_gen = _current_generator
			for _ai in range(expr.arguments.size()):
				var a = expr.arguments[_ai]
				var arg_val = null
				if _arg_gen != null:
					# 记忆已求值的实参: 语句因 yield 重放时不再重复执行其副作用
					arg_val = _arg_gen._yv_memo(a, _ai, func(): return evaluate(a))
				else:
					arg_val = evaluate(a)
				if arg_val == null:
					return null
				pos_args.append(arg_val)
			# *iterable 解包: 将迭代对象的每个元素追加为位置参数
			for sa in expr.star_args:
				var seq_val = evaluate(sa)
				if seq_val == null:
					return null
				var it = seq_val._dsl_iter()
				if it == null:
					raise_exception_from_last_error(seq_val.last_error if seq_val.last_error != "" else "TypeError: argument after * must be an iterable")
					return null
				while it.has_next():
					pos_args.append(it.next())
					if it.suspended:
						break
			var kw_dict: Dictionary[String, DSLObject] = {}
			for kw in expr.keyword_args:
				var val = evaluate(kw.value)
				if val == null:
					return null
				kw_dict[kw.name] = val
			# **mapping 解包: 将映射的键值对作为关键字参数 (键转字符串)
			for skw in expr.star_kwargs:
				var map_val = evaluate(skw)
				if map_val == null:
					return null
				var raw_map = DSLObject._unwrap_dsl(map_val)
				if raw_map is DSLDict:
					for k in raw_map.dict:
						kw_dict[str(k)] = raw_map.dict[k]
				else:
					raise_exception("TypeError", "argument after ** must be a mapping")
					return null
			var call_result = _dispatch_call(callee, pos_args, kw_dict)
			_current_call_node = prev_call_node
			return call_result
			
		if expr is GetItem:
			var obj = evaluate(expr.object)
			if obj == null:
				return null
			if expr.index is SliceExpr:
				var slice = expr.index
				var start_val = null
				if slice.start != null:
					start_val = evaluate(slice.start)
					if start_val == null:
						return null
				var stop_val = null
				if slice.stop != null:
					stop_val = evaluate(slice.stop)
					if stop_val == null:
						return null
				var step_val = null
				if slice.step != null:
					step_val = evaluate(slice.step)
					if step_val == null:
						return null
				var result = obj._dsl_getitem(DSLSlice.new(start_val, stop_val, step_val))
				if result == null:
					raise_exception_from_last_error(obj.last_error, obj.last_error_args)
					return null
				return result
			else:
				var idx = evaluate(expr.index)
				if idx == null:
					return null
				var result = obj._dsl_getitem(idx)
				if result == null:
					raise_exception_from_last_error(obj.last_error, obj.last_error_args)
					return null
				return result
			
		if expr is GetAttr:
			var obj = evaluate(expr.object)
			if obj == null:
				return null
			var result = obj._dsl_getattribute(expr.name)
			if obj.last_error != "":
				raise_exception_from_last_error(obj.last_error, obj.last_error_args)
				return null
			return result
		
		if expr is SetAttr:
			var obj = _eval_target_object(expr.object)
			if obj == null:
				return null
			var val = evaluate(expr.value)
			if val == null:
				return null
			obj._dsl_setattr(expr.name, val)
			if obj.last_error != "":
				raise_exception_from_last_error(obj.last_error, obj.last_error_args)
				return null
			return val
			
		if expr is ListLiteral:
			var lst = DSLList.new()
			for e in expr.elements:
				if not _append_literal_element(e, lst.items):
					return null
			return lst
			
		if expr is TupleLiteral:
			var tup = DSLTuple.new()
			for e in expr.elements:
				if not _append_literal_element(e, tup.items):
					return null
			return tup
			
		if expr is DictLiteral:
			var d = DSLDict.new()
			for i in range(expr.keys.size()):
				var is_star = expr.star_flags.size() > i and expr.star_flags[i]
				if is_star:
					var unpack_val = evaluate(expr.values[i])
					if unpack_val == null:
						return null
					var unwrapped = DSLObject._unwrap_dsl(unpack_val)
					if unwrapped is DSLDict:
						for k in unwrapped.dict.keys():
							d.dict[k] = unwrapped.dict[k]
					else:
						raise_exception("TypeError", "argument after ** must be a mapping")
						return null
				else:
					var key = evaluate(expr.keys[i])
					if key == null:
						return null
					var val = evaluate(expr.values[i])
					if val == null:
						return null
					d._dsl_setitem(key, val)
					if d.last_error != "":
						raise_exception_from_last_error(d.last_error)
						return null
			return d

		if expr is SetLiteral:
			var s = DSLSet.new()
			s.klass = globals.get_val_safe("set")
			for e in expr.elements:
				if e is StarredExpr:
					var expanded: Array[DSLObject] = []
					if not _append_literal_element(e, expanded):
						return null
					for v in expanded:
						if s._dsl_add(v) == null:
							raise_exception_from_last_error(s.last_error)
							return null
				else:
					var v = evaluate(e)
					if v == null:
						return null
					if s._dsl_add(v) == null:
						raise_exception_from_last_error(s.last_error)
						return null
			return s

		if expr is SetComp:
			var s = DSLSet.new()
			s.klass = globals.get_val_safe("set")
			var emit = func() -> bool:
				var element = evaluate(expr.elt_expr)
				if element == null:
					return false
				if s._dsl_add(element) == null:
					raise_exception_from_last_error(s.last_error)
					return false
				return true
			if not _eval_comp_clauses(expr.clauses, 0, environment, emit):
				return null
			return s

		if expr is ListComp:
			var result = DSLList.new()
			var emit = func() -> bool:
				var element = evaluate(expr.elt_expr)
				if element == null:
					return false
				result.items.append(element)
				return true
			if not _eval_comp_clauses(expr.clauses, 0, environment, emit):
				return null
			return result

		if expr is GenComp:
			var gen_obj = DSLGenerator.new(expr.elt_expr, expr.clauses, environment, self)
			gen_obj.interp = self
			return _memo_generator(expr, gen_obj)

		if expr is DictComp:
			var result = DSLDict.new()
			var emit = func() -> bool:
				var key = evaluate(expr.key_expr)
				if key == null:
					return false
				var value = evaluate(expr.value_expr)
				if value == null:
					return false
				result._dsl_setitem(key, value)
				if result.last_error != "":
					raise_exception_from_last_error(result.last_error)
					return false
				return true
			if not _eval_comp_clauses(expr.clauses, 0, environment, emit):
				return null
			return result

		if expr is LambdaExpr:
			return _make_lambda_function(expr)

		if expr is FStringExpr:
			return _evaluate_fstring(expr)

		if expr is SuperExpr:
			return _evaluate_super(expr)

		return DSLNone.new()

	## 求值 yield 表达式 [br]
	## 首次执行: 求值产出值后挂起 (返回 null 触发上层空值传播), 并把挂起的 yield 位置记录到当前生成器 [br]
	## 语句重执行: 按 yield 位置注入 send 值 (throw 时在挂起位置抛出异常) [br]
	## yield from 委托给 _eval_yield_from (按节点保存子迭代器状态) [br]
	## [param expr] YieldExpr 节点 [br]
	## [returns] 注入值或挂起占位 null
	func _evaluate_yield(expr: YieldExpr) -> DSLObject:
		if expr.from_expr != null:
			return _eval_yield_from(expr)
		var gen = _current_generator
		if gen == null:
			raise_exception("SyntaxError", "'yield' outside function")
			return null
		gen._yield_pos += 1
		# 注入抛出 (throw/close): 在挂起的 yield 位置抛出
		if gen._throw_pending and gen._pending_yield_index > 0 and gen._yield_pos == gen._pending_yield_index:
			gen._throw_pending = false
			var exc = gen._throw_value
			gen._throw_value = null
			gen._pending_yield_index = 0
			raise_existing_exception(exc)
			return null
		# 已产出过的 yield: 注入 send 值 (不挂起)
		if gen._pending_yield_index > 0 and gen._yield_pos <= gen._pending_yield_index:
			if gen._yield_pos == gen._pending_yield_index:
				gen._pending_yield_index = 0
			return gen._take_send_value()
		# 首次执行: 求值产出值并挂起
		var yielded: DSLObject = get_none()
		if expr.value != null:
			yielded = evaluate(expr.value)
			if _suspended:
				return null
			if yielded == null:
				return null
		gen._yielded_value = yielded
		gen._pending_yield_index = gen._yield_pos
		gen._send_value = null
		_suspended = true
		_suspend_reason = SuspendReason.YIELD
		return null

	## 求值 yield from 表达式 [br]
	## 委托给子可迭代对象: 逐个产出其元素, 耗尽后表达式的值为子生成器的 return 值 [br]
	## 子迭代器状态按 YieldExpr 节点身份保存在当前生成器的 _yield_from_states 中, [br]
	## 语句重执行时从挂起点继续 (无需位置计数, 与普通 yield 互不干扰) [br]
	## [param expr] YieldExpr 节点 (from_expr 非空) [br]
	## [returns] 产出的元素或子 return 值, 挂起/出错时返回 null
	func _eval_yield_from(expr: YieldExpr) -> DSLObject:
		var gen = _current_generator
		if gen == null:
			raise_exception("SyntaxError", "'yield' outside function")
			return null
		# 查找已保存的子迭代器状态 (语句重执行时恢复)
		var state = null
		for s in gen._yield_from_states:
			if s.expr == expr:
				state = s
				break
		# 恢复时检查注入异常 (throw/close)
		# 若委托已开始且子生成器可接收, 则转交转发逻辑 (PEP 380: 子生成器优先捕获)
		# 否则在 yield from 位置就地抛出
		if gen._throw_pending:
			var can_forward = state != null and state.get("started", false) and state.val is DSLFunctionGenerator
			if not can_forward:
				gen._throw_pending = false
				var exc = gen._throw_value
				gen._throw_value = null
				raise_existing_exception(exc)
				return null
		if state == null:
			var from_val = evaluate(expr.from_expr)
			if _suspended:
				return null
			if from_val == null or report.has_error:
				return null
			var sub_iter = from_val._dsl_iter()
			if sub_iter == null:
				raise_exception_from_last_error(from_val.last_error if from_val.last_error != "" else "TypeError: object is not iterable")
				return null
			sub_iter.windowed = false
			state = {"expr": expr, "iter": sub_iter, "val": from_val, "started": false}
			gen._yield_from_states.append(state)
		var iter = state.iter
		# 恢复 (已产出过至少一次): 把 send 值 / 抛出转发给子生成器 (PEP 380 委托语义)
		if state.get("started", false):
			var sub = state.val
			if sub is DSLFunctionGenerator:
				var forwarded = _forward_to_yield_from(state, gen)
				if _suspended:
					return null
				if report.has_error:
					# 子生成器的异常未被其体内捕获: 结束委托并向上传播
					gen._yield_from_states.erase(state)
					return null
				if forwarded != null:
					gen._yielded_value = forwarded
					_suspended = true
					_suspend_reason = SuspendReason.YIELD
					return null
				# 子生成器结束: yield from 表达式取其 return 值
				gen._yield_from_states.erase(state)
				if sub._finished:
					return sub._result_value
				return get_none()
		# 子迭代器直连推进 (不经过消费窗口): 其进度已由 _yield_from_states 保存,
		# 若被语句重放回退游标会导致重复产出
		if iter._read_pos < iter._log.size():
			var buffered = iter._log[iter._read_pos]
			iter._read_pos += 1
			state.started = true
			gen._yielded_value = buffered
			_suspended = true
			_suspend_reason = SuspendReason.YIELD
			return null
		if iter.has_next():
			var item = iter.next()
			state.started = true
			gen._yielded_value = item
			_suspended = true
			_suspend_reason = SuspendReason.YIELD
			return null
		# 子迭代器耗尽: 移除状态, 返回子生成器的 return 值
		gen._yield_from_states.erase(state)
		var from_val = state.val
		if from_val is DSLFunctionGenerator and from_val._finished:
			return from_val._result_value
		return get_none()

	## 把外层的 send 值 / 抛出异常转发给 yield from 的子生成器 [br]
	## 对应 PEP 380 的委托: 子生成器内可捕获外层 throw 的异常, send 值送达其挂起点 [br]
	## 子生成器正常结束时 _dsl_send 会抛 StopIteration, 此处按「委托结束」处理并清除该标记 [br]
	## [param state] 该 yield from 的状态字典 [br]
	## [param gen] 外层生成器 [br]
	## [returns] 子生成器本次产出的值; 结束/出错时返回 null
	func _forward_to_yield_from(state, gen) -> DSLObject:
		var sub = state.val
		var res = null
		if gen._throw_pending:
			gen._throw_pending = false
			var exc = gen._throw_value
			gen._throw_value = null
			if exc == null:
				exc = DSLException.new("", "GeneratorExit")
			res = sub._dsl_throw([exc] as Array[DSLObject], {} as Dictionary[String, DSLObject])
		else:
			var send_val = gen._take_send_value()
			res = sub._dsl_send([send_val] as Array[DSLObject], {} as Dictionary[String, DSLObject])
		if report.has_error and last_exception != null and last_exception._type_name() == "StopIteration":
			# 子生成器正常结束: 不是错误, 交由调用方取 return 值
			report.clear_error()
			last_exception = null
		return res

	## 求值字面量中的一个元素, 遇 * 解包时展开为多个元素 [br]
	## [param e] 元素表达式 (可能为 StarredExpr) [br]
	## [param target] 收集结果的数组 (实际类型 Array[DSLObject]) [br]
	## [returns] 成功返回 true, 出错返回 false
	func _append_literal_element(e, target: Array) -> bool:
		if e is StarredExpr:
			var val = evaluate(e.value)
			if val == null:
				return false
			var it = val._dsl_iter()
			if it == null:
				raise_exception("TypeError", "Value after * must be an iterable, not %s" % val._type_name())
				return false
			while true:
				if report.has_error:
					return false
				if not it.has_next():
					if it.suspended:
						# 消费中途挂起: 交由语句重放, 不能带着部分元素当作已展开完成
						return false
					break
				target.append(it.next())
				if it.suspended:
					return false
			return true
		var element = evaluate(e)
		if element == null:
			return false
		target.append(element)
		return true

	## 递归执行推导式循环子句, 在每个完整绑定组合上调用 emit [br]
	## 子句按书写顺序嵌套, 内层子句可引用外层循环变量 [br]
	## [param clauses] CompClause 数组 [br]
	## [param idx] 当前子句下标 [br]
	## [param env] 循环变量绑定的环境 [br]
	## [param emit] 最内层回调, 返回 false 表示出错 [br]
	## [returns] 成功返回 true, 出错返回 false
	func _eval_comp_clauses(clauses: Array, idx: int, env: DSLEnvironment, emit: Callable) -> bool:
		if idx >= clauses.size():
			return emit.call()
		var clause = clauses[idx]
		var iterator = null
		var prev_env = environment
		environment = env
		var iterable = evaluate(clause.iterable)
		environment = prev_env
		if _suspended:
			return false
		if iterable == null:
			return false
		iterator = iterable._dsl_iter()
		if iterator == null:
			raise_exception_from_last_error(iterable.last_error if iterable.last_error != "" else "TypeError: object is not iterable")
			return false
		while true:
			if report.has_error:
				return false
			if not iterator.has_next():
				if iterator.suspended:
					return false
				return true
			var item = iterator.next()
			if iterator.suspended:
				return false
			var saved = _bind_comp_targets(clause.targets, item, env)
			if saved == null:
				return false
			var cond_ok = true
			for cond in clause.conditions:
				var prev_cenv = environment
				environment = env
				var cond_result = evaluate(cond)
				environment = prev_cenv
				if _suspended:
					_restore_comp_bindings(env, saved)
					return false
				if cond_result == null:
					_restore_comp_bindings(env, saved)
					return false
				if not cond_result._dsl_bool():
					cond_ok = false
					break
			if cond_ok:
				var prev_ienv = environment
				environment = env
				var sub_ok = _eval_comp_clauses(clauses, idx + 1, env, emit)
				environment = prev_ienv
				if _suspended:
					_restore_comp_bindings(env, saved)
					return false
				if not sub_ok:
					_restore_comp_bindings(env, saved)
					return false
			_restore_comp_bindings(env, saved)
		return true

	## 语句节点标识 (消费窗口隔离用) [br]
	## 按节点身份取值, 循环体同一节点重复执行时天然复用同一窗口 [br]
	## [param stmt] 语句节点 [br]
	## [returns] 标识整数
	func _stmt_key(stmt) -> int:
		if stmt == null:
			return 0
		return stmt.get_instance_id()

	## 生成器创建记忆: 语句重放时按出现次序复用上次创建的生成器 [br]
	## 否则重放会新建生成器, 丢掉已推进的进度 (导致重复等待/结果错乱) [br]
	## [param node] 生成器来源表达式节点 [br]
	## [param gen] 本次新建的生成器 [br]
	## [returns] 本次应当使用的生成器 (重放轮为上次那个)
	func _memo_generator(node, gen):
		if node == null:
			return gen
		var skey = _sleep_root_key if _sleep_root_key != 0 else _current_stmt_key
		# 记忆键除节点外还须带上「当前正在执行的生成器」:
		# 同一节点在不同生成器实例体内求值属于不同的逻辑求值。
		# 例如 [[y for y in b()] for _ in range(2)] 中, 外层推导式第二轮会新建 b,
		# 新 b 体内调用 a() 必须得到新的 a, 而不能复用上轮已耗尽的 a
		var nkey: String = str(node.get_instance_id())
		if _current_generator != null:
			nkey += "_" + str(_current_generator.get_instance_id())
		var occ_map = _gen_occur.get(skey)
		if occ_map == null:
			occ_map = {}
			_gen_occur[skey] = occ_map
		var occ = int(occ_map.get(nkey, 0))
		occ_map[nkey] = occ + 1
		var memo_map = _gen_memo.get(skey)
		if memo_map == null:
			memo_map = {}
			_gen_memo[skey] = memo_map
		var lst: Array = memo_map.get(nkey, [])
		if occ < lst.size():
			return lst[occ]
		lst.append(gen)
		memo_map[nkey] = lst
		return gen

	## 语句正常结束后清理该语句的生成器记忆 [br]
	## [param stmt] 已完成的语句节点
	func _clear_gen_memo(stmt) -> void:
		var key = _sleep_root_key if _sleep_root_key != 0 else _stmt_key(stmt)
		_gen_memo.erase(key)
		_gen_occur.erase(key)

	## 语句重放时回退消费窗口: 一次性迭代器的读取游标退回窗口起点, [br]
	## 消费方重新调用 has_next()/next() 时会重读相同的元素序列 (无需自身感知挂起) [br]
	## [param stmt] 被重放的语句节点
	func _reset_read_marks(stmt) -> void:
		var key = _sleep_root_key if _sleep_root_key != 0 else _stmt_key(stmt)
		if not _stmt_iterators.has(key):
			return
		for it in _stmt_iterators[key]:
			if it != null and it._win_start >= 0:
				it._read_pos = it._win_start
				# 清除上一轮的挂起残留: 从日志重读是正常的消费推进, 不是挂起
				it.suspended = false

	## 语句正常结束后清理消费窗口登记 [br]
	## [param stmt] 已完成的语句节点
	func _clear_stmt_window(stmt) -> void:
		var key = _sleep_root_key if _sleep_root_key != 0 else _stmt_key(stmt)
		if not _stmt_iterators.has(key):
			return
		for it in _stmt_iterators[key]:
			if it != null:
				it._win_start = -1
				it._win_stmt = 0
		_stmt_iterators.erase(key)

	## 将迭代元素绑定到推导式子句的目标变量 [br]
	## 单目标直接绑定, 多目标按序列顺序解包 [br]
	## [param targets] 目标变量名数组 [br]
	## [param item] 当前迭代元素 [br]
	## [param env] 绑定环境 [br]
	## [returns] 保存的原有绑定数组, 出错时返回 null
	func _bind_comp_targets(targets: Array, item: DSLObject, env: DSLEnvironment):
		var saved: Array = []
		for name in targets:
			saved.append([name, env.values.get(name)])
		if targets.size() == 1:
			env.define(targets[0], item)
			return saved
		var seq: Array = []
		if item is DSLList or item is DSLTuple:
			seq = item.items
		else:
			raise_exception("TypeError", "cannot unpack non-sequence %s in comprehension" % item._type_name())
			return null
		if seq.size() != targets.size():
			raise_exception("ValueError", "too many/few values to unpack (expected %d, got %d)" % [targets.size(), seq.size()])
			return null
		for i in range(targets.size()):
			env.define(targets[i], seq[i])
		return saved

	## 恢复推导式循环变量的原有环境绑定 [br]
	## [param env] 环境 [br]
	## [param saved] _bind_comp_targets 返回的绑定快照
	func _restore_comp_bindings(env: DSLEnvironment, saved: Array) -> void:
		for entry in saved:
			var name = entry[0]
			var old = entry[1]
			if env.values.has(name):
				env.values.erase(name)
			if old != null:
				env.define(name, old)

	## 将 LambdaExpr 构造为可调用的 DSLFunction [br]
	## 复用 FunctionStmt 与 call_user_function 机制, 使 lambda 行为与普通函数一致 [br]
	## [param expr] LambdaExpr 节点 [br]
	## [returns] DSLFunction
	func _make_lambda_function(expr: LambdaExpr) -> DSLFunction:
		var body: Array[Stmt] = [ReturnStmt.new(expr.body)]
		var fstmt = FunctionStmt.new("<lambda>", expr.params, body)
		fstmt.is_generator = expr.is_generator
		var func_obj = DSLFunction.new(fstmt, environment)
		func_obj._cls_interp = self
		func_obj._defining_class = _current_class
		for p in fstmt.params:
			if p.is_args or p.is_kwargs:
				func_obj.default_values.append(null)
				continue
			if p.default_value != null:
				var prev_env = environment
				environment = func_obj.closure
				var val = evaluate(p.default_value)
				environment = prev_env
				func_obj.default_values.append(val)
			else:
				func_obj.default_values.append(null)
		return func_obj

	## 求值 f-string, 拼接字面量片段与替换字段 [br]
	## [param expr] FStringExpr 节点 [br]
	## [returns] DSLString
	func _evaluate_fstring(expr: FStringExpr) -> DSLString:
		var result = ""
		for part in expr.parts:
			if part.get("is_literal", true):
				result += part.text
				continue
			var val = evaluate(part.expr)
			if val == null:
				if _suspended:
					return null
				return DSLString.new(result)
			# = 调试说明符: 输出 "表达式源码=值" (默认 repr, 显式 !s/!r/!a 覆盖, 有格式说明符时按格式)
			if part.get("debug", false):
				var formatted = ""
				if part.conv == "" and part.fmt != "":
					formatted = _format_value(val, "", part.fmt)
				else:
					var conv = part.conv
					if conv == "":
						conv = "r"
					formatted = _format_value(val, conv, part.fmt)
				result += part.get("raw", "") + "=" + formatted
			else:
				result += _format_value(val, part.conv, part.fmt)
		return DSLString.new(result)

	## 求值 super(...) 表达式, 构造 DSLSuper 代理 [br]
	## 零参数 super() 使用当前方法上下文, 双参数 super(Class, obj) 显式指定 [br]
	## [param expr] SuperExpr 节点 [br]
	## [returns] DSLSuper, 出错时返回 null
	func _evaluate_super(expr: SuperExpr) -> DSLObject:
		if expr.arguments.size() == 0:
			if _current_class == null or _current_self == null:
				raise_exception("RuntimeError", "super(): no arguments")
				return null
			return DSLSuper.new(_current_class.superclass, _current_self, self)
		if expr.arguments.size() == 2:
			var cls_val = evaluate(expr.arguments[0])
			if cls_val == null or not (cls_val is DSLClass):
				raise_exception("TypeError", "super(): argument 1 must be a class")
				return null
			var obj_val = evaluate(expr.arguments[1])
			if obj_val == null:
				return null
			return DSLSuper.new(cls_val.superclass, obj_val, self)
		raise_exception("TypeError", "super() takes 0 or 2 arguments")
		return null

	## 按 Python f-string 格式说明符格式化值 [br]
	## 支持对齐 (< > ^ =), 填充字符, 符号 (+ - 空格), 备用形式 (#), 零填充 (0), 宽度, 千分位逗号, 精度, 类型 (d f e g s x X o b c %) [br]
	## [param value] DSLObject 值 [br]
	## [param conv] 转换标志 (s/r/a, 可空) [br]
	## [param fmt] 格式说明符 [br]
	## [returns] 格式化字符串
	func _format_value(value: DSLObject, conv: String, fmt: String) -> String:
		var is_numeric = _is_numeric_value(value)
		# 转换标志优先于格式说明符
		if conv == "r" or conv == "a":
			var r = value.magic_repr([value] as Array[DSLObject], {} as Dictionary[String, DSLObject])
			return r.value if r is DSLString else value._dsl_str()
		if conv == "s":
			var st = value.magic_str([value] as Array[DSLObject], {} as Dictionary[String, DSLObject])
			return st.value if st is DSLString else value._dsl_str()
		# 展开嵌套格式字段 (f"{x:{w}}" 中的 {w})
		if fmt.find("{") != -1:
			fmt = _expand_nested_format(fmt)
		if fmt == "":
			if is_numeric:
				return _format_default_number(value)
			return value._dsl_str()

		# 解析格式说明符
		var i = 0
		var fill = " "
		var align = ""
		var sign = ""
		var alt = false
		var zero_pad = false
		var width = 0
		var comma = false
		var precision = -1
		var type_c = ""
		# [fill]align
		if i < fmt.length() and fmt[i] in "<>^=":
			align = fmt[i]
			i += 1
		elif i + 1 < fmt.length() and fmt[i + 1] in "<>^=":
			fill = fmt[i]
			align = fmt[i + 1]
			i += 2
		# 符号
		if i < fmt.length() and fmt[i] in "+- ":
			sign = fmt[i]
			i += 1
		# 备用形式
		if i < fmt.length() and fmt[i] == "#":
			alt = true
			i += 1
		# 零填充
		if i < fmt.length() and fmt[i] == "0":
			zero_pad = true
			i += 1
		# 宽度
		while i < fmt.length() and fmt[i].is_valid_int():
			width = width * 10 + int(fmt[i])
			i += 1
		# 千分位
		if i < fmt.length() and fmt[i] == ",":
			comma = true
			i += 1
		# 精度
		if i < fmt.length() and fmt[i] == ".":
			i += 1
			precision = 0
			while i < fmt.length() and fmt[i].is_valid_int():
				precision = precision * 10 + int(fmt[i])
				i += 1
		# 类型
		if i < fmt.length():
			type_c = fmt[i]
			i += 1

		var s = _format_with_type(value, type_c, precision, comma)
		# 符号前缀
		if is_numeric and sign != "" and not s.begins_with("-"):
			if sign == "+":
				s = "+" + s
			elif sign == " ":
				s = " " + s
		# 备用形式 (进制前缀)
		if alt and type_c in ["x", "X", "o", "b"] and _is_numeric_value(value):
			var prefix = "0x" if type_c == "x" else ("0X" if type_c == "X" else ("0o" if type_c == "o" else "0b"))
			if not s.begins_with(prefix):
				s = prefix + s
		# 零填充
		if zero_pad and align == "" and width > s.length():
			var pad = width - s.length()
			if s.length() > 0 and (s[0] == "-" or s[0] == "+" or s[0] == " "):
				s = s[0] + "0".repeat(pad) + s.substr(1)
			else:
				s = "0".repeat(pad) + s
		# 对齐与宽度
		if width > s.length():
			var pad = width - s.length()
			if align == ">":
				s = fill.repeat(pad) + s
			elif align == "^":
				var left = pad / 2
				s = fill.repeat(left) + s + fill.repeat(pad - left)
			elif align == "<":
				s = s + fill.repeat(pad)
			elif align == "":
				# 默认: 数值右对齐, 字符串左对齐 (与 Python 一致)
				if is_numeric:
					s = fill.repeat(pad) + s
				else:
					s = s + fill.repeat(pad)
			elif align == "=":
				if s.length() > 0 and (s[0] == "-" or s[0] == "+" or s[0] == " "):
					s = s[0] + fill.repeat(pad) + s.substr(1)
				else:
					s = fill.repeat(pad) + s
		return s

	## 展开格式说明符中的嵌套字段 {expr}, 用求值结果的字符串替换 [br]
	## 用于 f-string 动态宽度/精度: f"{123:{width}}" [br]
	## [param fmt] 原始格式说明符 [br]
	## [returns] 展开后的格式说明符
	func _expand_nested_format(fmt: String) -> String:
		var result = ""
		var i = 0
		while i < fmt.length():
			if fmt[i] == '{':
				var j = i + 1
				var depth = 1
				while j < fmt.length() and depth > 0:
					if fmt[j] == '{':
						depth += 1
					elif fmt[j] == '}':
						depth -= 1
					j += 1
				if depth != 0:
					result += fmt.substr(i)
					break
				var inner = fmt.substr(i + 1, j - i - 2)
				var nested_expr = _parse_sub_expr(inner)
				var nested_val = evaluate(nested_expr)
				if nested_val == null:
					result += fmt.substr(i)
					break
				result += nested_val._dsl_str()
				i = j
			else:
				result += fmt[i]
				i += 1
		return result

	## 解析一段源码为单个表达式 (Interpreter 侧, 供嵌套格式等使用) [br]
	## [param src] 源码片段 [br]
	## [returns] Expr 节点, 出错时返回 null
	func _parse_sub_expr(src: String) -> Expr:
		var lexer = Lexer.new(report, src)
		var toks = lexer.scan()
		if report.has_error:
			return null
		var sub_parser = Parser.new(report, toks)
		var expr = sub_parser.simple_expression()
		if report.has_error or expr == null:
			return null
		return expr

	## 判断对象是否为数值类型
	func _is_numeric_value(value: DSLObject) -> bool:
		return value is DSLInteger or value is DSLFloat

	## 数值默认格式化 (整数直接, 浮点按 str)
	func _format_default_number(value: DSLObject) -> String:
		if value is DSLInteger:
			return str(value.value)
		return value._dsl_str()

	## 按类型字符格式化值
	func _format_with_type(value: DSLObject, type_c: String, precision: int, comma: bool) -> String:
		var is_int = value is DSLInteger
		var is_float = value is DSLFloat
		if type_c == "s":
			var st = value.magic_str([value] as Array[DSLObject], {} as Dictionary[String, DSLObject])
			return st.value if st is DSLString else value._dsl_str()
		if type_c == "c":
			var code = value.value if is_int else int(value._dsl_str())
			return char(code)
		if type_c in ["x", "X", "o", "b"]:
			var n = value.value if is_int else int(value._dsl_str())
			var neg = n < 0
			var body = ""
			match type_c:
				"x": body = _to_base(abs(n), 16)
				"X": body = _to_base(abs(n), 16).to_upper()
				"o": body = _to_base(abs(n), 8)
				"b": body = _to_base(abs(n), 2)
			if comma:
				body = _add_thousands(body)
			return ("-" if neg else "") + body
		if type_c == "d":
			var n = int(value.value) if is_float else value.value
			var body = str(n)
			return _add_thousands(body) if comma else body
		if type_c == "e" or type_c == "E":
			var num = float(value.value) if is_int else value.value
			var p = precision if precision >= 0 else 6
			var body = _format_scientific(num, p, type_c == "E")
			return _add_thousands(body) if comma else body
		if type_c == "g" or type_c == "G":
			var num = float(value.value) if is_int else value.value
			return _format_general(num, precision, type_c == "G")
		if type_c == "%":
			var num = float(value.value) if is_int else value.value
			var p = precision if precision >= 0 else 6
			return _format_fixed(num * 100.0, p) + "%"
		if type_c in ["f", "F"]:
			var num = float(value.value) if is_int else value.value
			var p = precision if precision >= 0 else 6
			var body = _format_fixed(num, p)
			return _add_thousands(body) if comma else body
		# 默认数值类型
		if is_int:
			var body = str(value.value)
			return _add_thousands(body) if comma else body
		return value._dsl_str()

	## 整数转任意进制字符串
	func _to_base(n: int, base: int) -> String:
		if n == 0:
			return "0"
		var chars = "0123456789abcdef"
		var result = ""
		while n > 0:
			result = chars[n % base] + result
			n /= base
		return result

	## 千分位逗号
	func _add_thousands(s: String) -> String:
		var neg = s.begins_with("-")
		if neg:
			s = s.substr(1)
		var dot = s.find(".")
		var int_part = s if dot == -1 else s.substr(0, dot)
		var frac = "" if dot == -1 else s.substr(dot)
		var result = ""
		var count = 0
		for i in range(int_part.length() - 1, -1, -1):
			result = int_part[i] + result
			count += 1
			if count % 3 == 0 and i > 0:
				result = "," + result
		return (("-" if neg else "") + result + frac)

	## 定点浮点格式化
	func _format_fixed(num: float, precision: int) -> String:
		return ("%." + str(precision) + "f") % num

	## 科学计数法格式化
	func _format_scientific(num: float, precision: int, upper: bool) -> String:
		if num == 0.0:
			return "0." + "0".repeat(precision) + ("E" if upper else "e") + "+00"
		var exp = floor(log(abs(num)) / log(10.0))
		var mantissa = num / pow(10.0, exp)
		if abs(mantissa) >= 10.0:
			mantissa /= 10.0
			exp += 1
		if abs(mantissa) < 1.0 and mantissa != 0.0:
			mantissa *= 10.0
			exp -= 1
		var mant_str = ("%." + str(precision) + "f") % mantissa
		var exp_sign = "+" if exp >= 0 else "-"
		var exp_abs = int(abs(exp))
		var exp_str = exp_sign + ("0" if exp_abs < 10 else "") + str(exp_abs)
		return mant_str + ("E" if upper else "e") + exp_str

	## 通用格式 g/G (近似 Python 语义)
	func _format_general(num: float, precision: int, upper: bool) -> String:
		var p = precision if precision >= 0 else 6
		if num == 0.0:
			return "0"
		var exp = floor(log(abs(num)) / log(10.0))
		var use_sci = exp < -4 or exp >= p
		if use_sci:
			var mant_p = p - 1
			if mant_p < 0:
				mant_p = 0
			return _strip_g_zeros(_format_scientific(num, mant_p, upper))
		var dec = p - 1 - int(exp)
		if dec < 0:
			dec = 0
		return _strip_g_zeros(("%." + str(dec) + "f") % num)

	## 去除 g 格式尾部的零与小数点
	func _strip_g_zeros(s: String) -> String:
		var e_idx = -1
		var e_part = ""
		for i in range(s.length()):
			if s[i] == "e" or s[i] == "E":
				e_idx = i
				e_part = s.substr(i)
				break
		var mant = s if e_idx == -1 else s.substr(0, e_idx)
		if mant.find(".") != -1:
			while mant.ends_with("0"):
				mant = mant.substr(0, mant.length() - 1)
			if mant.ends_with("."):
				mant = mant.substr(0, mant.length() - 1)
		return mant + e_part

	## 按被调用对象类型分派一次函数调用 [br]
	## 从 evaluate 的 Call 分支抽出, 使 _current_call_node 的生命周期可在单一位置收束 [br]
	## 调用期间 _current_call_node 保持为本次 Call 节点, 使 call_user_function 能复用生成器对象 [br]
	## [param callee] 被调用对象 (方法/函数/类/内置等) [br]
	## [param pos_args] 位置实参 [br]
	## [param kw_dict] 关键字实参 [br]
	## [returns] 调用结果; 挂起/出错时返回 null
	func _dispatch_call(callee, pos_args: Array[DSLObject], kw_dict: Dictionary[String, DSLObject]) -> DSLObject:
		if callee is DSLMethod:
			var result = callee.magic_call(pos_args, kw_dict)
			if _suspended:
				return null
			return result
		if callee is DSLFunction:
			var result = call_user_function(callee, pos_args, kw_dict)
			if _suspended:
				return null
			return result
		if callee is DSLClass:
			var result = callee.magic_call(pos_args, kw_dict)
			if _suspended:
				return null
			if report.has_error:
				# 构造/调用过程中抛出异常: 结果是半成品, 不能当作成功值返回,
				# 否则实参求值会带着它继续 (如 print(list(gen)) 会多输出部分列表)
				return null
			return result
		var result = callee.magic_call(pos_args, kw_dict)
		if _suspended:
			# 消费中途挂起 (需重放) 返回 null, 独立调用 (已完成副作用) 返回 None 使语句被跳过
			return null if _needs_replay else DSLNone.new()
		if report.has_error:
			return null
		# Check for errors from builtin methods (which set last_error on the proto)
		if callee is DSLBuiltinFunction:
			var proto = callee.callback.get_object()
			if proto is DSLObject and proto.last_error != "":
				raise_exception_from_last_error(proto.last_error, proto.last_error_args)
				proto.last_error = ""
				return null
			# 部分方法把错误记在接收者实例上 (如 dict.popitem / set.remove / set.pop):
			# 同样须转为异常, 否则错误被吞掉、调用静默返回 None
			var recv = callee.__self__
			if recv is DSLObject and recv.last_error != "":
				var recv_err = recv.last_error
				var recv_args: Array[DSLObject] = recv.last_error_args
				recv.last_error = ""
				recv.last_error_args.clear()
				raise_exception_from_last_error(recv_err, recv_args)
				return null
		return result

	## 调用用户自定义函数 [br]
	## [param function] DSLFunction 对象 [br]
	## [param args] 实参数组 (实际类型 Array[DSLObject]) [br]
	## [param kw_args] 关键字参数字典 (实际类型 Dictionary[String, DSLObject])
	func call_user_function(function: DSLFunction, args: Array[DSLObject], kw_args: Dictionary[String, DSLObject] = {}) -> DSLObject:
		function._cls_interp = self
		var decl = function.declaration
		var params = decl.params
		var local = DSLEnvironment.new(report, function.closure)
		var closure_env = function.closure
		var has_args = false
		var positional_params = []
		var keyword_only_params = []
		for p in params:
			if p.is_kwargs:
				continue
			if p.is_args:
				has_args = true
				continue
			if p.is_keyword_only:
				keyword_only_params.append(p)
			else:
				positional_params.append(p)
				
		var min_pos = 0
		var max_pos = 0
		for p in positional_params:
			if p.default_value == null:
				min_pos += 1
			max_pos += 1
			
		if not has_args and args.size() > max_pos:
			var msg = "%s() takes " % decl.name
			if min_pos == max_pos:
				msg += "%d positional argument" % max_pos if max_pos == 1 else "%d positional arguments" % max_pos
			else:
				msg += "from %d to %d positional arguments" % [min_pos, max_pos]
			msg += " but %d positional argument" % args.size() if args.size() == 1 else " but %d positional arguments" % args.size()
			if kw_args.size() > 0:
				msg += " (and %d keyword-only argument" % kw_args.size()
				if kw_args.size() > 1:
					msg += "s"
				msg += ")"
			msg += " were given"
			raise_exception("TypeError", msg)
			return null
			
		var arg_idx = 0
		var param_idx = 0
		while param_idx < params.size() and arg_idx < args.size():
			var p = params[param_idx]
			if p.is_kwargs:
				break
			if p.is_keyword_only:
				raise_exception("TypeError", "%s() takes %d positional arguments but %d were given" % [decl.name, max_pos, args.size()])
				return null
			if p.is_args:
				var rest = DSLTuple.new()
				for i in range(arg_idx, args.size()):
					rest.items.append(args[i])
				local.define(p.name, rest)
				arg_idx = args.size()
				param_idx += 1
				continue
			local.define(p.name, args[arg_idx])
			arg_idx += 1
			param_idx += 1
			
		var has_kwargs_param = false
		for p in params:
			if p.is_kwargs:
				has_kwargs_param = true
				break
				
		var pos_only_kw_names = []
		for kw_name in kw_args:
			var kw_val = kw_args[kw_name]
			var matched = false
			for p in params:
				if p.is_kwargs:
					continue
				if p.name == kw_name:
					if p.is_positional_only:
						if has_kwargs_param:
							matched = false
						else:
							pos_only_kw_names.append(kw_name)
							matched = true
					else:
						if local.values.has(p.name):
							raise_exception("TypeError", "%s() got multiple values for argument '%s'" % [decl.name, p.name])
							return null
						local.define(p.name, kw_val)
						matched = true
					break
			if not matched:
				if has_kwargs_param:
					var kwargs_param = get_kwargs_param(params)
					var kwargs_dict = local.get_val(kwargs_param.name) if local.values.has(kwargs_param.name) else DSLDict.new()
					if kwargs_dict == null or not kwargs_dict is DSLDict:
						kwargs_dict = DSLDict.new()
					kwargs_dict._dsl_setitem(DSLString.new(kw_name), kw_val)
					local.define(kwargs_param.name, kwargs_dict)
				else:
					raise_exception("TypeError", "%s() got an unexpected keyword argument '%s'" % [decl.name, kw_name])
					return null
					
		if pos_only_kw_names.size() > 0:
			var names_str = ""
			for i in range(pos_only_kw_names.size()):
				if i > 0:
					names_str += ", "
				names_str += pos_only_kw_names[i]
			raise_exception("TypeError", "%s() got some positional-only arguments passed as keyword arguments: '%s'" % [decl.name, names_str])
			return null
			
		var missing_pos = []
		var missing_kw = []
		var def_idx = 0
		for p in params:
			if p.is_args or p.is_kwargs:
				def_idx += 1
				continue
			if local.values.has(p.name):
				def_idx += 1
				continue
			if def_idx < function.default_values.size() and function.default_values[def_idx] != null:
				local.define(p.name, function.default_values[def_idx])
			elif p.default_value != null:
				var prev_environment = environment
				environment = closure_env
				var default_val = evaluate(p.default_value)
				environment = prev_environment
				if default_val == null:
					return null
				local.define(p.name, default_val)
			else:
				if p.is_keyword_only:
					missing_kw.append(p.name)
				else:
					missing_pos.append(p.name)
					
		if missing_pos.size() > 0:
			var msg = "%s() missing %d required positional argument" % [decl.name, missing_pos.size()]
			if missing_pos.size() > 1:
				msg += "s"
			msg += ": "
			for i in range(missing_pos.size()):
				if i > 0:
					if i == missing_pos.size() - 1:
						msg += ", and " if missing_pos.size() > 2 else " and "
					else:
						msg += ", "
				msg += "'%s'" % missing_pos[i]
			raise_exception("TypeError", msg)
			return null
			
		if missing_kw.size() > 0:
			var msg = "%s() missing %d required keyword-only argument" % [decl.name, missing_kw.size()]
			if missing_kw.size() > 1:
				msg += "s"
			msg += ": "
			for i in range(missing_kw.size()):
				if i > 0:
					if i == missing_kw.size() - 1:
						msg += ", and " if missing_kw.size() > 2 else " and "
					else:
						msg += ", "
				msg += "'%s'" % missing_kw[i]
			raise_exception("TypeError", msg)
			return null
			
		for p in params:
			if p.is_args and not local.values.has(p.name):
				local.define(p.name, DSLTuple.new())
			if p.is_kwargs and not local.values.has(p.name):
				local.define(p.name, DSLDict.new())
				
		# 生成器函数: 参数绑定完成后不执行函数体, 立即返回生成器对象
		if function.declaration.is_generator:
			var gen = DSLFunctionGenerator.new(self, function, local)
			gen.cur_class = function._defining_class
			if args.size() > 0 and (function.method_type == 0 or function.method_type == 1):
				gen.cur_self = args[0]
			return _memo_generator(_current_call_node, gen)
			
		# 检查 _call_stack 是否有恢复信息 (嵌套函数调用挂起恢复)
		var saved_env = null
		var saved_pc = 0
		# 语句重放会重新求值实参表达式, 像 f(C(1)) 里的 C(1) 会产生结构相同但身份不同的新实例。
		# 此时按身份的实参比对必然失败, 函数体会被完整重跑一遍，导致副作用重复执行;
		# 故仅在重放轮 (_sleep_root_key 已置位) 追加一次「按结构」的宽松比对
		var allow_structural = _sleep_root_key != 0
		var saved_env_taken = {}
		for j in range(_call_stack.size() - 1, -1, -1):
			var cs = _call_stack[j]
			if cs.get("function") != function:
				continue
			var cs_args: Array = cs.get("args", [])
			if not _args_match(cs_args, args):
				if not allow_structural or not _args_match_structural(cs_args, args):
					continue
			# 同一函数同一实参可能有多个未完成帧 (递归): 只复用与本次调用「同层」的那个
			var cand_env = cs.get("local_env")
			if cand_env != null and saved_env_taken.has(cand_env):
				continue
			saved_env = cand_env
			saved_pc = cs.get("return_pc", 0)
			saved_env_taken[cand_env] = true
			_call_stack.remove_at(j)
			break
		
		var prev_env = environment
		var exec_env = saved_env if saved_env != null else local
		if saved_env != null:
			# 从挂起中恢复: 推回保存的帧让 exec_block 能找到
			_exec_stack.append({
				"statements": decl.body,
				"pc": saved_pc,
				"env": saved_env,
				"resume_info": {}
			})
		# 记录当前方法上下文 (super() 定位), 嵌套调用时保存并恢复
		var saved_class = _current_class
		var saved_self = _current_self
		_current_class = function._defining_class
		if args.size() > 0 and (function.method_type == 0 or function.method_type == 1):
			_current_self = args[0]
		else:
			_current_self = null
		environment = exec_env
		# 嵌套调用相对当前生成器是原子求值: 其体内语句会把 _yield_pos 归零,
		# 若不还原, 外层 yield 记录到的挂起位置会变成 0 (形同未记录),
		# 重执行该语句时被当作「首次产出」而反复重放, 直至耗尽步数上限
		var saved_yield_pos = 0
		if _current_generator != null:
			saved_yield_pos = _current_generator._yield_pos
		var res = exec_block(decl.body, environment)
		if _current_generator != null:
			_current_generator._yield_pos = saved_yield_pos
		environment = prev_env
		_current_class = saved_class
		_current_self = saved_self
		
		if res == ExecResult.SUSPENDED:
			# 压入函数调用栈帧
			var return_pc = 0
			# 从 _exec_stack 中搜索本次调用的函数体帧: 按 (statements, env) 双重身份匹配,
			# 递归时同名函数体存在多个帧, 只有 env 相同的那一个才是本次调用的帧
			for j in range(_exec_stack.size() - 1, -1, -1):
				var f = _exec_stack[j]
				if f.statements == decl.body and f.env == exec_env:
					return_pc = f.pc
					break
			_call_stack.append({
				"function": function,
				"return_env": prev_env,
				"return_pc": return_pc,
				"local_env": exec_env,
				"args": args.duplicate(),
			})
			_suspended = true
			return null
		elif res == ExecResult.RETURN:
			return return_value
		elif res == ExecResult.ERROR or res == ExecResult.RAISE:
			return null
		return DSLNone.new()
	
	## 执行类定义语句 [br]
	## 解析超类, 方法体与类属性, 构造 DSLClass 并注册到当前环境 [br]
	## [param stmt] ClassStmt AST 节点 [br]
	## [returns] 执行结果状态
	func execute_class(stmt: ClassStmt) -> ExecResult:
		var superclass_obj = null
		if stmt.superclass:
			var super_val = evaluate(stmt.superclass)
			if not super_val is DSLClass:
				raise_exception("TypeError", "superclass must be a class")
				return ExecResult.RAISE
			superclass_obj = super_val
			
		if superclass_obj == null and stmt.name != "object":
			superclass_obj = environment.get_val("object")
		var methods = {}
		var class_attrs = {}
		# 提前创建 DSLClass 骨架, 使方法能引用其定义类 (super() 定位)
		var class_obj = DSLClass.new(stmt.name, superclass_obj, {}, self)
		for body_stmt in stmt.body:
			if body_stmt is FunctionStmt:
				if body_stmt.method_type == 3:
					# @property getter
					var func_obj = DSLFunction.new(body_stmt, environment)
					func_obj._cls_interp = self
					func_obj._defining_class = class_obj
					var prop = DSLProperty.new(body_stmt.name, func_obj, self)
					methods[body_stmt.name] = prop
				elif body_stmt.method_type == 4:
					# @name.setter
					var func_obj = DSLFunction.new(body_stmt, environment)
					func_obj._cls_interp = self
					func_obj._defining_class = class_obj
					var prop_name = body_stmt.get_meta("_property_name", body_stmt.name)
					if methods.has(prop_name) and methods[prop_name] is DSLProperty:
						(methods[prop_name] as DSLProperty).setter(func_obj)
					else:
						# Create property with just setter (unusual but valid)
						var prop = DSLProperty.new(prop_name, null, self)
						prop.setter(func_obj)
						methods[prop_name] = prop
				elif body_stmt.method_type == 5:
					# @name.deleter
					var func_obj = DSLFunction.new(body_stmt, environment)
					func_obj._cls_interp = self
					func_obj._defining_class = class_obj
					var prop_name = body_stmt.get_meta("_property_name", body_stmt.name)
					if methods.has(prop_name) and methods[prop_name] is DSLProperty:
						(methods[prop_name] as DSLProperty).deleter(func_obj)
					else:
						var prop = DSLProperty.new(prop_name, null, self)
						prop.deleter(func_obj)
						methods[prop_name] = prop
				else:
					# Regular method, @classmethod, @staticmethod
					var func_obj = DSLFunction.new(body_stmt, environment)
					func_obj._cls_interp = self
					func_obj._defining_class = class_obj
					methods[body_stmt.name] = func_obj
			elif body_stmt is ExpressionStmt and body_stmt.expression is Assign:
				var assign = body_stmt.expression as Assign
				var val = evaluate(assign.value)
				if val == null:
					return ExecResult.ERROR
				class_attrs[assign.name] = val
		class_obj.methods = methods
		class_obj.class_attrs = class_attrs
		environment.define(stmt.name, class_obj)
		return ExecResult.NORMAL

	## 向 preamble 中定义的内置类型类注入对应的方法描述 [br]
	## 根据 [param cls_name] 匹配目标类型 (str/list/tuple/dict/int) [br]
	## [param class_obj] 目标 DSLClass [br]
	## [param cls_name] 类型
	func _inject_builtin_methods(class_obj: DSLClass, cls_name: String):
		match cls_name:
			"str":
				var proto = DSLString.new("")
				_builtin_protos["str"] = proto
				class_obj.methods["__mod__"] = DSLWrappedDescriptor.new("__mod__", Callable(proto, "magic_mod"))
				class_obj.methods["__contains__"] = DSLWrappedDescriptor.new("__contains__", Callable(proto, "magic_contains"))
				class_obj.methods["upper"] = DSLMethodDescriptor.new("upper", Callable(proto, "builtin_upper"))
				class_obj.methods["lower"] = DSLMethodDescriptor.new("lower", Callable(proto, "builtin_lower"))
				class_obj.methods["strip"] = DSLMethodDescriptor.new("strip", Callable(proto, "builtin_strip"))
				class_obj.methods["split"] = DSLMethodDescriptor.new("split", Callable(proto, "builtin_split"))
				class_obj.methods["join"] = DSLMethodDescriptor.new("join", Callable(proto, "builtin_join"))
				class_obj.methods["replace"] = DSLMethodDescriptor.new("replace", Callable(proto, "builtin_replace"))
				class_obj.methods["find"] = DSLMethodDescriptor.new("find", Callable(proto, "builtin_find"))
				class_obj.methods["startswith"] = DSLMethodDescriptor.new("startswith", Callable(proto, "builtin_startswith"))
				class_obj.methods["endswith"] = DSLMethodDescriptor.new("endswith", Callable(proto, "builtin_endswith"))
				class_obj.methods["lstrip"] = DSLMethodDescriptor.new("lstrip", Callable(proto, "builtin_lstrip"))
				class_obj.methods["rstrip"] = DSLMethodDescriptor.new("rstrip", Callable(proto, "builtin_rstrip"))
				class_obj.methods["capitalize"] = DSLMethodDescriptor.new("capitalize", Callable(proto, "builtin_capitalize"))
				class_obj.methods["casefold"] = DSLMethodDescriptor.new("casefold", Callable(proto, "builtin_casefold"))
				class_obj.methods["title"] = DSLMethodDescriptor.new("title", Callable(proto, "builtin_title"))
				class_obj.methods["swapcase"] = DSLMethodDescriptor.new("swapcase", Callable(proto, "builtin_swapcase"))
				class_obj.methods["count"] = DSLMethodDescriptor.new("count", Callable(proto, "builtin_count"))
				class_obj.methods["isdigit"] = DSLMethodDescriptor.new("isdigit", Callable(proto, "builtin_isdigit"))
				class_obj.methods["isalpha"] = DSLMethodDescriptor.new("isalpha", Callable(proto, "builtin_isalpha"))
				class_obj.methods["isalnum"] = DSLMethodDescriptor.new("isalnum", Callable(proto, "builtin_isalnum"))
				class_obj.methods["isspace"] = DSLMethodDescriptor.new("isspace", Callable(proto, "builtin_isspace"))
				class_obj.methods["islower"] = DSLMethodDescriptor.new("islower", Callable(proto, "builtin_islower"))
				class_obj.methods["isupper"] = DSLMethodDescriptor.new("isupper", Callable(proto, "builtin_isupper"))
				class_obj.methods["istitle"] = DSLMethodDescriptor.new("istitle", Callable(proto, "builtin_istitle"))
				class_obj.methods["center"] = DSLMethodDescriptor.new("center", Callable(proto, "builtin_center"))
				class_obj.methods["ljust"] = DSLMethodDescriptor.new("ljust", Callable(proto, "builtin_ljust"))
				class_obj.methods["rjust"] = DSLMethodDescriptor.new("rjust", Callable(proto, "builtin_rjust"))
				class_obj.methods["zfill"] = DSLMethodDescriptor.new("zfill", Callable(proto, "builtin_zfill"))
				class_obj.methods["rsplit"] = DSLMethodDescriptor.new("rsplit", Callable(proto, "builtin_rsplit"))
				class_obj.methods["index"] = DSLMethodDescriptor.new("index", Callable(proto, "builtin_index"))
				class_obj.methods["rindex"] = DSLMethodDescriptor.new("rindex", Callable(proto, "builtin_rindex"))
				class_obj.methods["rfind"] = DSLMethodDescriptor.new("rfind", Callable(proto, "builtin_rfind"))
				class_obj.methods["splitlines"] = DSLMethodDescriptor.new("splitlines", Callable(proto, "builtin_splitlines"))
				class_obj.methods["removeprefix"] = DSLMethodDescriptor.new("removeprefix", Callable(proto, "builtin_removeprefix"))
				class_obj.methods["removesuffix"] = DSLMethodDescriptor.new("removesuffix", Callable(proto, "builtin_removesuffix"))
				class_obj.methods["partition"] = DSLMethodDescriptor.new("partition", Callable(proto, "builtin_partition"))
				class_obj.methods["rpartition"] = DSLMethodDescriptor.new("rpartition", Callable(proto, "builtin_rpartition"))
				class_obj.methods["isdecimal"] = DSLMethodDescriptor.new("isdecimal", Callable(proto, "builtin_isdecimal"))
				class_obj.methods["isnumeric"] = DSLMethodDescriptor.new("isnumeric", Callable(proto, "builtin_isnumeric"))
				class_obj.methods["isprintable"] = DSLMethodDescriptor.new("isprintable", Callable(proto, "builtin_isprintable"))
				class_obj.methods["isascii"] = DSLMethodDescriptor.new("isascii", Callable(proto, "builtin_isascii"))
				class_obj.methods["isidentifier"] = DSLMethodDescriptor.new("isidentifier", Callable(proto, "builtin_isidentifier"))
				class_obj.methods["expandtabs"] = DSLMethodDescriptor.new("expandtabs", Callable(proto, "builtin_expandtabs"))
			"list":
				var proto = DSLList.new([])
				_builtin_protos["list"] = proto
				class_obj.methods["append"] = DSLMethodDescriptor.new("append", Callable(proto, "builtin_append"))
				class_obj.methods["extend"] = DSLMethodDescriptor.new("extend", Callable(proto, "builtin_extend"))
				class_obj.methods["pop"] = DSLMethodDescriptor.new("pop", Callable(proto, "builtin_pop"))
				class_obj.methods["remove"] = DSLMethodDescriptor.new("remove", Callable(proto, "builtin_remove"))
				class_obj.methods["insert"] = DSLMethodDescriptor.new("insert", Callable(proto, "builtin_insert"))
				class_obj.methods["index"] = DSLMethodDescriptor.new("index", Callable(proto, "builtin_index"))
				class_obj.methods["count"] = DSLMethodDescriptor.new("count", Callable(proto, "builtin_count"))
				class_obj.methods["sort"] = DSLMethodDescriptor.new("sort", Callable(proto, "builtin_sort"))
				class_obj.methods["reverse"] = DSLMethodDescriptor.new("reverse", Callable(proto, "builtin_reverse"))
				class_obj.methods["clear"] = DSLMethodDescriptor.new("clear", Callable(proto, "builtin_clear"))
				class_obj.methods["copy"] = DSLMethodDescriptor.new("copy", Callable(proto, "builtin_copy"))
			"tuple":
				var proto = DSLTuple.new([])
				_builtin_protos["tuple"] = proto
				class_obj.methods["count"] = DSLMethodDescriptor.new("count", Callable(proto, "builtin_count"))
				class_obj.methods["index"] = DSLMethodDescriptor.new("index", Callable(proto, "builtin_index"))
			"dict":
				var proto = DSLDict.new({})
				_builtin_protos["dict"] = proto
				class_obj.methods["items"] = DSLMethodDescriptor.new("items", Callable(proto, "builtin_items"))
				class_obj.methods["keys"] = DSLMethodDescriptor.new("keys", Callable(proto, "builtin_keys"))
				class_obj.methods["values"] = DSLMethodDescriptor.new("values", Callable(proto, "builtin_values"))
				class_obj.methods["get"] = DSLMethodDescriptor.new("get", Callable(proto, "builtin_get"))
				class_obj.methods["pop"] = DSLMethodDescriptor.new("pop", Callable(proto, "builtin_pop"))
				class_obj.methods["update"] = DSLMethodDescriptor.new("update", Callable(proto, "builtin_update"))
				class_obj.methods["clear"] = DSLMethodDescriptor.new("clear", Callable(proto, "builtin_clear"))
				class_obj.methods["copy"] = DSLMethodDescriptor.new("copy", Callable(proto, "builtin_copy"))
				class_obj.methods["setdefault"] = DSLMethodDescriptor.new("setdefault", Callable(proto, "builtin_setdefault"))
				class_obj.methods["popitem"] = DSLMethodDescriptor.new("popitem", Callable(proto, "builtin_popitem"))
				class_obj.class_attrs["fromkeys"] = _make_builtin("fromkeys", Callable(self, "builtin_fromkeys"))
			"int":
				var proto = DSLInteger.new(0)
				_builtin_protos["int"] = proto
				class_obj.methods["__add__"] = DSLWrappedDescriptor.new("__add__", Callable(proto, "magic_add"))
				class_obj.methods["__sub__"] = DSLWrappedDescriptor.new("__sub__", Callable(proto, "magic_sub"))
				class_obj.methods["__mul__"] = DSLWrappedDescriptor.new("__mul__", Callable(proto, "magic_mul"))
				class_obj.methods["__truediv__"] = DSLWrappedDescriptor.new("__truediv__", Callable(proto, "magic_div"))
				class_obj.methods["__floordiv__"] = DSLWrappedDescriptor.new("__floordiv__", Callable(proto, "magic_floordiv"))
				class_obj.methods["__mod__"] = DSLWrappedDescriptor.new("__mod__", Callable(proto, "magic_mod"))
				class_obj.methods["__pow__"] = DSLWrappedDescriptor.new("__pow__", Callable(proto, "magic_pow"))
				class_obj.methods["__eq__"] = DSLWrappedDescriptor.new("__eq__", Callable(proto, "magic_eq"))
				class_obj.methods["__ne__"] = DSLWrappedDescriptor.new("__ne__", Callable(proto, "magic_ne"))
				class_obj.methods["__lt__"] = DSLWrappedDescriptor.new("__lt__", Callable(proto, "magic_lt"))
				class_obj.methods["__gt__"] = DSLWrappedDescriptor.new("__gt__", Callable(proto, "magic_gt"))
				class_obj.methods["__le__"] = DSLWrappedDescriptor.new("__le__", Callable(proto, "magic_le"))
				class_obj.methods["__ge__"] = DSLWrappedDescriptor.new("__ge__", Callable(proto, "magic_ge"))
				class_obj.methods["__neg__"] = DSLWrappedDescriptor.new("__neg__", Callable(proto, "magic_neg"))
				class_obj.methods["__str__"] = DSLWrappedDescriptor.new("__str__", Callable(proto, "magic_str"))
				class_obj.methods["__repr__"] = DSLWrappedDescriptor.new("__repr__", Callable(proto, "magic_repr"))
			"float":
				var proto = DSLFloat.new(0.0)
				_builtin_protos["float"] = proto
				class_obj.methods["__add__"] = DSLWrappedDescriptor.new("__add__", Callable(proto, "magic_add"))
				class_obj.methods["__sub__"] = DSLWrappedDescriptor.new("__sub__", Callable(proto, "magic_sub"))
				class_obj.methods["__mul__"] = DSLWrappedDescriptor.new("__mul__", Callable(proto, "magic_mul"))
				class_obj.methods["__truediv__"] = DSLWrappedDescriptor.new("__truediv__", Callable(proto, "magic_div"))
				class_obj.methods["__floordiv__"] = DSLWrappedDescriptor.new("__floordiv__", Callable(proto, "magic_floordiv"))
				class_obj.methods["__mod__"] = DSLWrappedDescriptor.new("__mod__", Callable(proto, "magic_mod"))
				class_obj.methods["__pow__"] = DSLWrappedDescriptor.new("__pow__", Callable(proto, "magic_pow"))
				class_obj.methods["__eq__"] = DSLWrappedDescriptor.new("__eq__", Callable(proto, "magic_eq"))
				class_obj.methods["__ne__"] = DSLWrappedDescriptor.new("__ne__", Callable(proto, "magic_ne"))
				class_obj.methods["__lt__"] = DSLWrappedDescriptor.new("__lt__", Callable(proto, "magic_lt"))
				class_obj.methods["__gt__"] = DSLWrappedDescriptor.new("__gt__", Callable(proto, "magic_gt"))
				class_obj.methods["__le__"] = DSLWrappedDescriptor.new("__le__", Callable(proto, "magic_le"))
				class_obj.methods["__ge__"] = DSLWrappedDescriptor.new("__ge__", Callable(proto, "magic_ge"))
				class_obj.methods["__neg__"] = DSLWrappedDescriptor.new("__neg__", Callable(proto, "magic_neg"))
				class_obj.methods["__str__"] = DSLWrappedDescriptor.new("__str__", Callable(proto, "magic_str"))
				class_obj.methods["__repr__"] = DSLWrappedDescriptor.new("__repr__", Callable(proto, "magic_repr"))
			"bool":
				var proto = DSLBool.new(false)
				_builtin_protos["bool"] = proto
				class_obj.methods["__eq__"] = DSLWrappedDescriptor.new("__eq__", Callable(proto, "magic_eq"))
				class_obj.methods["__ne__"] = DSLWrappedDescriptor.new("__ne__", Callable(proto, "magic_ne"))
				class_obj.methods["__str__"] = DSLWrappedDescriptor.new("__str__", Callable(proto, "magic_str"))
				class_obj.methods["__repr__"] = DSLWrappedDescriptor.new("__repr__", Callable(proto, "magic_repr"))
				class_obj.methods["__bool__"] = DSLWrappedDescriptor.new("__bool__", Callable(proto, "magic_bool"))
			"set":
				var proto = DSLSet.new()
				_builtin_protos["set"] = proto
				class_obj.methods["__or__"] = DSLWrappedDescriptor.new("__or__", Callable(proto, "magic_or"))
				class_obj.methods["__and__"] = DSLWrappedDescriptor.new("__and__", Callable(proto, "magic_and"))
				class_obj.methods["__sub__"] = DSLWrappedDescriptor.new("__sub__", Callable(proto, "magic_sub"))
				class_obj.methods["__xor__"] = DSLWrappedDescriptor.new("__xor__", Callable(proto, "magic_xor"))
				class_obj.methods["__eq__"] = DSLWrappedDescriptor.new("__eq__", Callable(proto, "magic_eq"))
				class_obj.methods["__ne__"] = DSLWrappedDescriptor.new("__ne__", Callable(proto, "magic_ne"))
				class_obj.methods["__lt__"] = DSLWrappedDescriptor.new("__lt__", Callable(proto, "magic_lt"))
				class_obj.methods["__gt__"] = DSLWrappedDescriptor.new("__gt__", Callable(proto, "magic_gt"))
				class_obj.methods["__le__"] = DSLWrappedDescriptor.new("__le__", Callable(proto, "magic_le"))
				class_obj.methods["__ge__"] = DSLWrappedDescriptor.new("__ge__", Callable(proto, "magic_ge"))
				class_obj.methods["__contains__"] = DSLWrappedDescriptor.new("__contains__", Callable(proto, "magic_contains"))
				class_obj.methods["__len__"] = DSLWrappedDescriptor.new("__len__", Callable(proto, "magic_len"))
				class_obj.methods["add"] = DSLMethodDescriptor.new("add", Callable(proto, "builtin_add"))
				class_obj.methods["remove"] = DSLMethodDescriptor.new("remove", Callable(proto, "builtin_remove"))
				class_obj.methods["discard"] = DSLMethodDescriptor.new("discard", Callable(proto, "builtin_discard"))
				class_obj.methods["pop"] = DSLMethodDescriptor.new("pop", Callable(proto, "builtin_pop"))
				class_obj.methods["clear"] = DSLMethodDescriptor.new("clear", Callable(proto, "builtin_clear"))
				class_obj.methods["copy"] = DSLMethodDescriptor.new("copy", Callable(proto, "builtin_copy"))
				class_obj.methods["union"] = DSLMethodDescriptor.new("union", Callable(proto, "builtin_union"))
				class_obj.methods["intersection"] = DSLMethodDescriptor.new("intersection", Callable(proto, "builtin_intersection"))
				class_obj.methods["difference"] = DSLMethodDescriptor.new("difference", Callable(proto, "builtin_difference"))
				class_obj.methods["symmetric_difference"] = DSLMethodDescriptor.new("symmetric_difference", Callable(proto, "builtin_symmetric_difference"))
				class_obj.methods["issubset"] = DSLMethodDescriptor.new("issubset", Callable(proto, "builtin_issubset"))
				class_obj.methods["issuperset"] = DSLMethodDescriptor.new("issuperset", Callable(proto, "builtin_issuperset"))
				class_obj.methods["isdisjoint"] = DSLMethodDescriptor.new("isdisjoint", Callable(proto, "builtin_isdisjoint"))
			"frozenset":
				var proto = DSLFrozenSet.new()
				_builtin_protos["frozenset"] = proto
				class_obj.methods["__or__"] = DSLWrappedDescriptor.new("__or__", Callable(proto, "magic_or"))
				class_obj.methods["__and__"] = DSLWrappedDescriptor.new("__and__", Callable(proto, "magic_and"))
				class_obj.methods["__sub__"] = DSLWrappedDescriptor.new("__sub__", Callable(proto, "magic_sub"))
				class_obj.methods["__xor__"] = DSLWrappedDescriptor.new("__xor__", Callable(proto, "magic_xor"))
				class_obj.methods["__eq__"] = DSLWrappedDescriptor.new("__eq__", Callable(proto, "magic_eq"))
				class_obj.methods["__ne__"] = DSLWrappedDescriptor.new("__ne__", Callable(proto, "magic_ne"))
				class_obj.methods["__lt__"] = DSLWrappedDescriptor.new("__lt__", Callable(proto, "magic_lt"))
				class_obj.methods["__gt__"] = DSLWrappedDescriptor.new("__gt__", Callable(proto, "magic_gt"))
				class_obj.methods["__le__"] = DSLWrappedDescriptor.new("__le__", Callable(proto, "magic_le"))
				class_obj.methods["__ge__"] = DSLWrappedDescriptor.new("__ge__", Callable(proto, "magic_ge"))
				class_obj.methods["__contains__"] = DSLWrappedDescriptor.new("__contains__", Callable(proto, "magic_contains"))
				class_obj.methods["__len__"] = DSLWrappedDescriptor.new("__len__", Callable(proto, "magic_len"))
				class_obj.methods["copy"] = DSLMethodDescriptor.new("copy", Callable(proto, "builtin_copy"))
				class_obj.methods["union"] = DSLMethodDescriptor.new("union", Callable(proto, "builtin_union"))
				class_obj.methods["intersection"] = DSLMethodDescriptor.new("intersection", Callable(proto, "builtin_intersection"))
				class_obj.methods["difference"] = DSLMethodDescriptor.new("difference", Callable(proto, "builtin_difference"))
				class_obj.methods["symmetric_difference"] = DSLMethodDescriptor.new("symmetric_difference", Callable(proto, "builtin_symmetric_difference"))
				class_obj.methods["issubset"] = DSLMethodDescriptor.new("issubset", Callable(proto, "builtin_issubset"))
				class_obj.methods["issuperset"] = DSLMethodDescriptor.new("issuperset", Callable(proto, "builtin_issuperset"))
				class_obj.methods["isdisjoint"] = DSLMethodDescriptor.new("isdisjoint", Callable(proto, "builtin_isdisjoint"))

	## 根据目标列表和已收集的元素执行解包赋值 [br]
	## 支持星号 (*) 解包目标, 将 items 中对应位置的元素赋给 targets [br]
	## [param targets] 目标列表 (Variable/StarredTarget/UnpackTarget) [br]
	## [param items] 已收集的 DSLObject 元素数组 [br]
	## [param env] 目标环境 [br]
	## [returns] DSLNone 表示成功, null 表示错误
	func assign_from_targets(targets: Array, items: Array[DSLObject], env: DSLEnvironment) -> DSLObject:
		var starred_idx = -1
		for i in range(targets.size()):
			if targets[i] is StarredTarget:
				starred_idx = i
				break
				
		if starred_idx == -1:
			# 处理嵌套解包: 如果只有一个 UnpackTarget, 则按内部目标数比较
			if targets.size() == 1 and targets[0] is UnpackTarget:
				var inner = (targets[0] as UnpackTarget).targets
				if items.size() != inner.size():
					raise_exception("ValueError", "too many/few values to unpack (expected %d, got %d)" % [inner.size(), items.size()])
					return null
				for i in range(inner.size()):
					var nullflag = assign_target_value(inner[i], items[i], env)
					if nullflag == null:
						return null
			else:
				if items.size() != targets.size():
					raise_exception("ValueError", "too many/few values to unpack (expected %d, got %d)" % [targets.size(), items.size()])
					return null
				for i in range(targets.size()):
					var nullflag = assign_target_value(targets[i], items[i], env)
					if nullflag == null:
						return null
		else:
			var min_items = targets.size() - 1
			if items.size() < min_items:
				raise_exception("ValueError", "not enough values to unpack (expected at least %d, got %d)" % [min_items, items.size()])
				return null
			# 处理星号前的目标
			for i in range(starred_idx):
				var nullflag = assign_target_value(targets[i], items[i], env)
				if nullflag == null:
					return null
			# 处理星号目标
			var star_target = targets[starred_idx] as StarredTarget
			var var_name = (star_target.target as Variable).name
			var remaining_count = items.size() - (targets.size() - 1)
			var starred_list = DSLList.new()
			for j in range(starred_idx, starred_idx + remaining_count):
				starred_list.items.append(items[j])
			env.set_val(var_name, starred_list)
			# 处理星号后的目标
			var offset = starred_idx + remaining_count
			for i in range(starred_idx + 1, targets.size()):
				var nullflag = assign_target_value(targets[i], items[offset], env)
				if nullflag == null:
					return null
				offset += 1
		return DSLNone.new()
		
	## 将单个元素赋值给单个目标 (可能是变量或嵌套解包) [br]
	## 支持 Variable (直接赋值) 与 UnpackTarget (嵌套解包) [br]
	## [param target] 目标节点 (Variable 或 UnpackTarget) [br]
	## [param val] 要赋值的 DSLObject 值 [br]
	## [param env] 目标环境 [br]
	## [returns] DSLNone 表示成功, null 表示错误
	func assign_target_value(target, val: DSLObject, env: DSLEnvironment) -> DSLObject:
		if target is Variable:
			env.set_val(target.name, val)
			if report.has_error:
				return null
			return DSLNone.new()
		elif target is UnpackTarget:
			var inner_items: Array[DSLObject] = []
			var iter = val._dsl_iter()
			if iter == null:
				raise_exception_from_last_error(val.last_error if val.last_error != "" else "TypeError: cannot unpack non-iterable into nested target")
				return null
			while iter.has_next():
				inner_items.append(iter.next())
				if iter.suspended:
					break
			return assign_from_targets(target.targets, inner_items, env)
		elif target is SubscriptTarget:
			# 下标目标: obj[index] = val (与 SetItem 同一语义)
			# obj 可能是普通表达式, 也可能是嵌套的属性/下标目标, 故用 _eval_target_object 求值
			var obj = _eval_target_object(target.object)
			if obj == null:
				return null
			var idx = evaluate(target.index)
			if idx == null:
				return null
			obj._dsl_setitem(idx, val)
			if obj.last_error != "":
				raise_exception_from_last_error(obj.last_error, obj.last_error_args)
				return null
			return DSLNone.new()
		elif target is AttrTarget:
			# 属性目标: obj.name = val
			var host = _eval_target_object(target.object)
			if host == null:
				return null
			host._dsl_setattr(target.name, val)
			if host.last_error != "":
				raise_exception_from_last_error(host.last_error)
				return null
			return DSLNone.new()
		# StarredTarget 不会出现在这
		return DSLNone.new()
	
	## 求值赋值目标中的「宿主对象」表达式 [br]
	## 目标链可能由 SubscriptTarget / AttrTarget 嵌套构成 (如 self._data[k] 里的 self._data), [br]
	## 这类节点不是 Expr, 不能直接交给 evaluate, 需按目标语义逐层求值 [br]
	## [param node] 宿主对象节点 (Expr 或嵌套目标) [br]
	## [returns] 宿主对象; 出错时返回 null
	func _eval_target_object(node) -> DSLObject:
		if node is SubscriptTarget:
			var inner = _eval_target_object(node.object)
			if inner == null:
				return null
			var idx = evaluate(node.index)
			if idx == null:
				return null
			return inner._dsl_getitem(idx)
		if node is AttrTarget:
			var host = _eval_target_object(node.object)
			if host == null:
				return null
			return host._dsl_getattribute(node.name)
		return evaluate(node)
	
	## 判断参数列表中是否包含 **kwargs 不定长关键字参数 [br]
	## [param params] 参数数组 [br]
	## [returns] 是否存在 kwargs 参数
	func has_kwargs(params: Array[Param]) -> bool:
		for p in params:
			if p.is_kwargs:
				return true
		return false
		
	## 获取 **kwargs 不定长关键字参数对象 [br]
	## [param params] 参数数组 [br]
	## [returns] kwargs 参数对象, 不存在则返回 null
	func get_kwargs_param(params: Array[Param]) -> Param:
		for p in params:
			if p.is_kwargs:
				return p
		return null
	
	## len(obj) - 返回对象的长度
	func builtin_len(args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLInteger:
		if args.size() != 1:
			raise_exception("TypeError", "len() takes 1 argument")
			return null
		var obj = args[0]
		if obj.klass != null:
			var len_method = obj.klass._lookup_method("__len__")
			if len_method != null:
				var res = obj.klass._invoke_func(len_method, [obj] as Array[DSLObject], {} as Dictionary[String, DSLObject])
				if res is DSLInteger:
					return res
		if obj._wrapped != null:
			obj = obj._wrapped
		if obj is DSLList:
			return DSLInteger.new(obj.items.size())
		if obj is DSLString:
			return DSLInteger.new(obj.value.length())
		if obj is DSLDict:
			return DSLInteger.new(obj.dict.size())
		if obj is DSLDefaultDict:
			return DSLInteger.new(obj.inner.dict.size())
		if obj is DSLTuple:
			return DSLInteger.new(obj.items.size())
		if obj is DSLSet:
			return DSLInteger.new(obj.items.size())
		if obj is DSLDictKeys:
			return DSLInteger.new(obj.keys_list.size())
		if obj is DSLDictValues:
			return DSLInteger.new(obj.values_list.size())
		if obj is DSLRange:
			return DSLInteger.new(obj._length())
		if obj is DSLBytes:
			return DSLInteger.new(obj.data.size())
		raise_exception("TypeError", "object of type '%s' has no len()" % obj._type_name())
		return null
		
	## range(start, stop, step) - 生成整数序列
	func builtin_range(args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLObject:
		if args.size() < 1 or args.size() > 3:
			raise_exception("TypeError", "range expected 1 to 3 arguments, got %d" % args.size())
			return null
		for a in args:
			if not (a is DSLInteger):
				raise_exception("TypeError", "'%s' object cannot be interpreted as an integer" % a._type_name())
				return null
		var start = 0
		var stop = 0
		var step = 1
		if args.size() == 1:
			stop = args[0].value
		elif args.size() == 2:
			start = args[0].value
			stop = args[1].value
		else:
			start = args[0].value
			stop = args[1].value
			step = args[2].value
		if step == 0:
			raise_exception("ValueError", "range() arg 3 must not be zero")
			return null
		return DSLRange.new(start, stop, step)
		
	## print(*args, sep, end) - 输出到控制台
	func builtin_print(args: Array[DSLObject], kwargs: Dictionary[String, DSLObject]) -> DSLNone:
		var sep = " "
		var end = "\n"
		if kwargs.has("sep"):
			sep = kwargs["sep"]._dsl_str()
		if kwargs.has("end"):
			end = kwargs["end"]._dsl_str()
		
		var s = ""
		for i in range(args.size()):
			if i > 0:
				s += sep
			var str_result = args[i].magic_str([args[i]] as Array[DSLObject], {} as Dictionary[String, DSLObject])
			s += str_result.value if str_result is DSLString else args[i]._dsl_str()
		s += end
		report.print_msg(s)
		return DSLNone.new()
	
	## info(*args) - 输出信息日志
	func builtin_info(args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLNone:
		var s = args[0]._dsl_str() if args.size() >= 1 else ""
		report.info(s)
		return DSLNone.new()
		
	## warn(*args) - 输出警告日志
	func builtin_warn(args: Array[DSLObject], kwargs: Dictionary[String, DSLObject]) -> DSLNone:
		return builtin_warning(args, kwargs)
		
	## warning(*args) - 输出警告日志
	func builtin_warning(args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLNone:
		var s = args[0]._dsl_str() if args.size() >= 1 else ""
		report.warn(s)
		return DSLNone.new()
		
	## error(*args) - 输出错误日志
	func builtin_error(args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLNone:
		var s = args[0]._dsl_str() if args.size() >= 1 else ""
		report.err(s)
		return DSLNone.new()
	
	## str(obj) - 转换为字符串
	func builtin_str(args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLString:
		if args.size() != 1:
			raise_exception("TypeError", "str() takes 1 argument")
			return null
		var obj = args[0]
		var result = obj.magic_str([obj] as Array[DSLObject], {} as Dictionary[String, DSLObject])
		if result is DSLString:
			return result
		return DSLString.new(obj._dsl_str())
	
	## repr(obj) - 返回对象的字符串表示
	func builtin_repr(args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLString:
		if args.size() != 1:
			raise_exception("TypeError", "repr() takes 1 argument")
			return null
		var obj = args[0]
		var res = obj.magic_repr([obj] as Array[DSLObject], {} as Dictionary[String, DSLObject])
		if res is DSLString:
			return res
		return DSLString.new("<" + obj._type_name() + " object>")
	
	## hash(obj) - 计算对象的哈希值
	func builtin_hash(args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLInteger:
		if args.size() != 1:
			raise_exception("TypeError", "hash() takes 1 argument")
			return null
		var obj = args[0]
		if obj.klass != null:
			var method = obj.klass._lookup_method("__hash__")
			if method != null:
				var res = obj.klass._invoke_func(method, [obj] as Array[DSLObject], {} as Dictionary[String, DSLObject])
				if res is DSLInteger:
					return res
		if obj is DSLInteger:
			return DSLInteger.new(obj.value)
		if obj is DSLFloat:
			return DSLInteger.new(hash(obj.value))
		if obj is DSLString:
			return DSLInteger.new(obj.value.hash())
		if obj is DSLBool:
			return DSLInteger.new(1 if obj.value else 0)
		if obj is DSLNone:
			return DSLInteger.new(0)
		if obj is DSLList or obj is DSLDict:
			raise_exception("TypeError", "unhashable type: '%s'" % obj._type_name())
			return null
		return DSLInteger.new(obj.get_instance_id())
	
	## abs(x) - 返回绝对值
	func builtin_abs(args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLObject:
		if args.size() != 1:
			raise_exception("TypeError", "abs() takes 1 argument")
			return null
		var obj = args[0]
		if obj.klass != null:
			var method = obj.klass._lookup_method("__abs__")
			if method != null:
				return obj.klass._invoke_func(method, [obj] as Array[DSLObject], {} as Dictionary[String, DSLObject])
		if obj is DSLInteger:
			return DSLInteger.new(abs(obj.value))
		if obj is DSLFloat:
			return DSLFloat.new(abs(obj.value))
		raise_exception("TypeError", "bad operand type for abs(): '%s'" % obj._type_name())
		return null
	
	## min(*args, key) - 返回最小值
	func builtin_min(args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLObject:
		var min_val
		if args.size() == 0:
			raise_exception("TypeError", "min() takes at least 1 argument")
			return null
		if args.size() == 1:
			var obj = args[0]
			if obj._wrapped != null:
				obj = obj._wrapped
			if obj is DSLList or obj is DSLTuple:
				if obj.items.size() == 0:
					raise_exception("ValueError", "min() arg is an empty sequence")
					return null
				min_val = obj.items[0]
				for item in obj.items:
					var cmp = min_val.magic_lt([min_val, item] as Array[DSLObject], {} as Dictionary[String, DSLObject])
					if cmp is DSLBool and not cmp.value:
						min_val = item
				return min_val
			var iter = obj._dsl_iter()
			if iter == null:
				raise_exception("TypeError", "min() arg is not iterable")
				return null
			if not iter.has_next():
				if iter.suspended:
					# 消费中途挂起: 交由语句重放, 不能当作空序列
					return null
				raise_exception("ValueError", "min() arg is an empty sequence")
				return null
			min_val = iter.next()
			while iter.has_next():
				var item = iter.next()
				if iter.suspended:
					break
				var cmp = min_val.magic_lt([min_val, item] as Array[DSLObject], {} as Dictionary[String, DSLObject])
				if cmp is DSLBool and not cmp.value:
					min_val = item
			return min_val
		min_val = args[0]
		for i in range(1, args.size()):
			var cmp = min_val.magic_lt([min_val, args[i]] as Array[DSLObject], {} as Dictionary[String, DSLObject])
			if cmp is DSLBool and not cmp.value:
				min_val = args[i]
		return min_val
	
	## max(*args, key) - 返回最大值
	func builtin_max(args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLObject:
		var max_val
		if args.size() == 0:
			raise_exception("TypeError", "max() takes at least 1 argument")
			return null
		if args.size() == 1:
			var obj = args[0]
			if obj._wrapped != null:
				obj = obj._wrapped
			if obj is DSLList or obj is DSLTuple:
				if obj.items.size() == 0:
					raise_exception("ValueError", "max() arg is an empty sequence")
					return null
				max_val = obj.items[0]
				for item in obj.items:
					var cmp = max_val.magic_gt([max_val, item] as Array[DSLObject], {} as Dictionary[String, DSLObject])
					if cmp is DSLBool and not cmp.value:
						max_val = item
				return max_val
			var iter = obj._dsl_iter()
			if iter == null:
				raise_exception("TypeError", "max() arg is not iterable")
				return null
			if not iter.has_next():
				if iter.suspended:
					# 消费中途挂起: 交由语句重放, 不能当作空序列
					return null
				raise_exception("ValueError", "max() arg is an empty sequence")
				return null
			max_val = iter.next()
			while iter.has_next():
				var item = iter.next()
				if iter.suspended:
					break
				var cmp = max_val.magic_gt([max_val, item] as Array[DSLObject], {} as Dictionary[String, DSLObject])
				if cmp is DSLBool and not cmp.value:
					max_val = item
			return max_val
		max_val = args[0]
		for i in range(1, args.size()):
			var cmp = max_val.magic_gt([max_val, args[i]] as Array[DSLObject], {} as Dictionary[String, DSLObject])
			if cmp is DSLBool and not cmp.value:
				max_val = args[i]
		return max_val
	
	## sum(iterable, start) - 求和
	func builtin_sum(args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLObject:
		if args.size() < 1:
			raise_exception("TypeError", "sum() takes at least 1 argument")
			return null
		var start = DSLInteger.new(0)
		if args.size() >= 2:
			start = args[1]
		var obj = args[0]
		if obj._wrapped != null:
			obj = obj._wrapped
		var total = start
		if obj is DSLList or obj is DSLTuple:
			for item in obj.items:
				total = total.magic_add([total, item] as Array[DSLObject], {} as Dictionary[String, DSLObject])
			return total
		var iter = obj._dsl_iter()
		if iter == null:
			raise_exception("TypeError", "sum() arg is not iterable")
			return null
		while iter.has_next():
			var iv = iter.next()
			if iter.suspended:
				break
			total = total.magic_add([total, iv] as Array[DSLObject], {} as Dictionary[String, DSLObject])
		return total
	
	## pow(x, y, mod) - 幂运算
	func builtin_pow(args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLObject:
		if args.size() < 2:
			raise_exception("TypeError", "pow() takes at least 2 arguments")
			return null
		var base = args[0]
		var exp_ = args[1]
		var result = base.magic_pow([base, exp_] as Array[DSLObject], {} as Dictionary[String, DSLObject])
		if args.size() >= 3:
			var mod = args[2]
			result = result.magic_mod([result, mod] as Array[DSLObject], {} as Dictionary[String, DSLObject])
		return result
	
	## divmod(a, b) - 返回商和余数的元组
	func builtin_divmod(args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLTuple:
		if args.size() != 2:
			raise_exception("TypeError", "divmod() takes 2 arguments")
			return null
		var a = args[0]
		var b = args[1]
		var quot = a.magic_floordiv([a, b] as Array[DSLObject], {} as Dictionary[String, DSLObject])
		var rem = a.magic_mod([a, b] as Array[DSLObject], {} as Dictionary[String, DSLObject])
		return DSLTuple.new([quot, rem])
	
	## sorted(iterable, key, reverse) - 返回排序后的列表
	func builtin_sorted(args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLList:
		if args.size() < 1:
			raise_exception("TypeError", "sorted() takes at least 1 argument")
			return null
		var obj = args[0]
		if obj._wrapped != null:
			obj = obj._wrapped
		var items: Array[DSLObject] = []
		if obj is DSLList or obj is DSLTuple:
			items = obj.items.duplicate()
		elif obj is DSLSet:
			for k in obj.items:
				items.append(obj.items[k])
		elif obj is DSLString:
			for i in range(obj.value.length()):
				items.append(DSLString.new(obj.value[i]))
		else:
			var iter = obj._dsl_iter()
			if iter == null:
				raise_exception("TypeError", "sorted() arg is not iterable")
				return null
			while iter.has_next():
				items.append(iter.next())
				if iter.suspended:
					break
		var reverse_val = false
		if _kwargs.has("reverse"):
			var rv = _kwargs["reverse"]
			if rv is DSLBool:
				reverse_val = rv.value
		if _kwargs.has("key"):
			var key_func = _kwargs["key"]
			if key_func._dsl_is_callable():
				var mapped = []
				for item in items:
					var k = key_func.magic_call([item] as Array[DSLObject], {} as Dictionary[String, DSLObject])
					mapped.append({"item": item, "key": k})
				if reverse_val:
					mapped.sort_custom(func(a, b): return not _compare_asc(a["key"], b["key"]))
				else:
					mapped.sort_custom(func(a, b): return _compare_asc(a["key"], b["key"]))
				var result_items: Array[DSLObject] = []
				for m in mapped:
					result_items.append(m["item"])
				return DSLList.new(result_items)
		if reverse_val:
			items.sort_custom(_compare_desc)
		else:
			items.sort_custom(_compare_asc)
		return DSLList.new(items)
	
	## 升序比较函数, 用于 sorted
	func _compare_asc(a: DSLObject, b: DSLObject) -> bool:
		var cmp = a.magic_lt([a, b] as Array[DSLObject], {} as Dictionary[String, DSLObject])
		if cmp is DSLBool:
			return cmp.value
		return false
	
	## 降序比较函数, 用于 sorted
	func _compare_desc(a: DSLObject, b: DSLObject) -> bool:
		var cmp = a.magic_gt([a, b] as Array[DSLObject], {} as Dictionary[String, DSLObject])
		if cmp is DSLBool:
			return cmp.value
		return false
	
	## reversed(seq) - 返回反向迭代器
	func builtin_reversed(args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLObject:
		if args.size() != 1:
			raise_exception("TypeError", "reversed() takes 1 argument")
			return null
		var obj = args[0]
		if obj._wrapped != null:
			obj = obj._wrapped
		if obj is DSLList or obj is DSLTuple:
			var rev_items = obj.items.duplicate()
			rev_items.reverse()
			return DSLList.new(rev_items)
		if obj is DSLString:
			var result = DSLList.new()
			for i in range(obj.value.length() - 1, -1, -1):
				result.items.append(DSLString.new(obj.value[i]))
			return result
		if obj is DSLRange:
			# range 反向: 末元素为 (start + (len-1)*step), 步长取反, 末端前移一格
			var n = obj._length()
			if n == 0:
				return DSLList.new()
			var last = obj.start + (n - 1) * obj.step
			var rev = DSLRange.new(last, obj.start - obj.step, -obj.step)
			return rev._to_list()
		raise_exception("TypeError", "reversed() arg is not iterable")
		return null
	
	## enumerate(iterable, start) - 返回枚举对象
	func builtin_enumerate(args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLList:
		if args.size() < 1:
			raise_exception("TypeError", "enumerate() takes at least 1 argument")
			return null
		var start = 0
		if _kwargs.has("start"):
			start = (_kwargs["start"] as DSLInteger).value
		elif args.size() >= 2:
			start = (args[1] as DSLInteger).value
		var obj = args[0]
		if obj._wrapped != null:
			obj = obj._wrapped
		var result = DSLList.new()
		if obj is DSLList or obj is DSLTuple:
			for i in range(obj.items.size()):
				result.items.append(DSLTuple.new([DSLInteger.new(start + i), obj.items[i]]))
			return result
		var iter = obj._dsl_iter()
		if iter == null:
			raise_exception("TypeError", "enumerate() arg is not iterable")
			return null
		var idx = start
		while iter.has_next():
			result.items.append(DSLTuple.new([DSLInteger.new(idx), iter.next()]))
			idx += 1
		return result
	
	## zip(*iterables) - 并行迭代
	func builtin_zip(args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLList:
		if args.size() == 0:
			return DSLList.new()
		var lists: Array[Array] = []
		var min_len = 999999
		for arg in args:
			var obj = arg
			if obj._wrapped != null:
				obj = obj._wrapped
			var iter = obj._dsl_iter()
			if iter == null:
				raise_exception("TypeError", "zip() arg is not iterable")
				return null
			var zitems: Array[DSLObject] = []
			while iter.has_next():
				zitems.append(iter.next())
				if iter.suspended:
					break
			lists.append(zitems)
			if zitems.size() < min_len:
				min_len = zitems.size()
		var result = DSLList.new()
		for i in range(min_len):
			var row: Array[DSLObject] = []
			for lst in lists:
				row.append(lst[i])
			result.items.append(DSLTuple.new(row))
		return result
	
	## any(iterable) - 任一元素为真则返回 True
	func builtin_any(args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLBool:
		if args.size() != 1:
			raise_exception("TypeError", "any() takes 1 argument")
			return null
		var obj = args[0]
		if obj._wrapped != null:
			obj = obj._wrapped
		if obj is DSLList or obj is DSLTuple:
			for item in obj.items:
				var obj_item = item
				if obj_item._wrapped != null:
					obj_item = obj_item._wrapped
				if obj_item._dsl_bool():
					return DSLBool.new(true)
			return DSLBool.new(false)
		if obj is DSLDict:
			if obj.dict.size() == 0:
				return DSLBool.new(false)
			for key in obj.dict.keys():
				if obj.dict[key]._dsl_bool():
					return DSLBool.new(true)
			return DSLBool.new(false)
		if obj is DSLString:
			return DSLBool.new(obj.value != "")
		var iter = obj._dsl_iter()
		if iter != null:
			while iter.has_next():
				var obj_item = iter.next()
				if iter.suspended:
					break
				if obj_item._wrapped != null:
					obj_item = obj_item._wrapped
				if obj_item._dsl_bool():
					return DSLBool.new(true)
			return DSLBool.new(false)
		return DSLBool.new(true)
	
	## all(iterable) - 所有元素为真则返回 True
	func builtin_all(args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLBool:
		if args.size() != 1:
			raise_exception("TypeError", "all() takes 1 argument")
			return null
		var obj = args[0]
		if obj._wrapped != null:
			obj = obj._wrapped
		if obj is DSLList or obj is DSLTuple:
			for item in obj.items:
				var obj_item = item
				if obj_item._wrapped != null:
					obj_item = obj_item._wrapped
				if not obj_item._dsl_bool():
					return DSLBool.new(false)
			return DSLBool.new(true)
		if obj is DSLDict:
			for key in obj.dict.keys():
				if not obj.dict[key]._dsl_bool():
					return DSLBool.new(false)
			return DSLBool.new(true)
		if obj is DSLString:
			return DSLBool.new(obj.value != "")
		var iter = obj._dsl_iter()
		if iter != null:
			while iter.has_next():
				var obj_item = iter.next()
				if iter.suspended:
					break
				if obj_item._wrapped != null:
					obj_item = obj_item._wrapped
				if not obj_item._dsl_bool():
					return DSLBool.new(false)
			return DSLBool.new(true)
		return DSLBool.new(true)
	
	## ord(c) - 返回字符的 Unicode 码点
	func builtin_ord(args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLInteger:
		if args.size() != 1:
			raise_exception("TypeError", "ord() takes 1 argument")
			return null
		var obj = args[0]
		if obj is DSLString:
			if obj.value.length() == 0:
				raise_exception("TypeError", "ord() expected a character, but string of length 0 found")
				return null
			return DSLInteger.new(obj.value.unicode_at(0))
		raise_exception("TypeError", "ord() expected string of length 1")
		return null
	
	## chr(i) - 返回 Unicode 码点对应的字符
	func builtin_chr(args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLString:
		if args.size() != 1:
			raise_exception("TypeError", "chr() takes 1 argument")
			return null
		var obj = args[0]
		if obj is DSLInteger:
			return DSLString.new(char(obj.value))
		raise_exception("TypeError", "chr() argument must be int")
		return null
	
	## 将整数转换为十六进制字符串
	func _int_to_hex(v: int) -> String:
		var hex_chars = "0123456789abcdef"
		if v == 0:
			return "0"
		var n = abs(v)
		var result = ""
		while n > 0:
			result = hex_chars[n % 16] + result
			n /= 16
		return result
	
	## hex(x) - 转换为十六进制字符串
	func builtin_hex(args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLString:
		if args.size() != 1:
			raise_exception("TypeError", "hex() takes 1 argument")
			return null
		var obj = args[0]
		if obj is DSLInteger:
			if obj.value < 0:
				return DSLString.new("-0x" + _int_to_hex(-obj.value))
			return DSLString.new("0x" + _int_to_hex(obj.value))
		raise_exception("TypeError", "hex() argument must be int")
		return null
	
	## oct(x) - 转换为八进制字符串
	func builtin_oct(args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLString:
		if args.size() != 1:
			raise_exception("TypeError", "oct() takes 1 argument")
			return null
		var obj = args[0]
		if obj is DSLInteger:
			if obj.value == 0:
				return DSLString.new("0o0")
			var n = abs(obj.value)
			var result = ""
			while n > 0:
				result = str(n % 8) + result
				n /= 8
			if obj.value < 0:
				result = "-0o" + result
			else:
				result = "0o" + result
			return DSLString.new(result)
		raise_exception("TypeError", "oct() argument must be int")
		return null
	
	## bin(x) - 转换为二进制字符串
	func builtin_bin(args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLString:
		if args.size() != 1:
			raise_exception("TypeError", "bin() takes 1 argument")
			return null
		var obj = args[0]
		if obj is DSLInteger:
			if obj.value == 0:
				return DSLString.new("0b0")
			var n = abs(obj.value)
			var result = ""
			while n > 0:
				result = str(n % 2) + result
				n /= 2
			if obj.value < 0:
				result = "-0b" + result
			else:
				result = "0b" + result
			return DSLString.new(result)
		raise_exception("TypeError", "bin() argument must be int")
		return null
	
	## isinstance(obj, cls) - 检查类型
	func builtin_isinstance(args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLBool:
		if args.size() != 2:
			raise_exception("TypeError", "isinstance() takes 2 arguments")
			return null
		var obj = args[0]
		var cls = args[1]
		if cls is DSLClass:
			# Every object is an instance of object
			if cls.name == "object":
				return DSLBool.new(true)
			if obj.klass != null:
				if obj.klass == cls:
					return DSLBool.new(true)
				var current = obj.klass.superclass
				while current != null:
					if current == cls:
						return DSLBool.new(true)
					current = current.superclass
				return DSLBool.new(false)
			# bool is a subclass of int in Python
			if obj is DSLBool and cls.name == "int":
				return DSLBool.new(true)
			if obj._type_name() == cls.name:
				return DSLBool.new(true)
			return DSLBool.new(false)
		if cls is DSLTuple:
			for item in cls.items:
				if item is DSLClass:
					if item.name == "object":
						return DSLBool.new(true)
					if obj.klass != null:
						if obj.klass == item:
							return DSLBool.new(true)
						var current = obj.klass.superclass
						while current != null:
							if current == item:
								return DSLBool.new(true)
							current = current.superclass
					elif obj._type_name() == item.name:
						return DSLBool.new(true)
					elif obj is DSLBool and item.name == "int":
						return DSLBool.new(true)
			return DSLBool.new(false)
		# Handle case where cls is a DSLString (e.g., type(None) returns "<class 'NoneType'>")
		if cls is DSLString:
			var cls_name = cls.value
			if cls_name == "<class '" + obj._type_name() + "'>":
				return DSLBool.new(true)
		return DSLBool.new(false)
	
	## issubclass(cls, cls_or_tuple) - 检查继承关系
	func builtin_issubclass(args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLBool:
		if args.size() != 2:
			raise_exception("TypeError", "issubclass() takes 2 arguments")
			return null
		var sub = args[0]
		var sup = args[1]
		if not (sub is DSLClass):
			return DSLBool.new(false)
		if not (sup is DSLClass):
			raise_exception("TypeError", "issubclass() arg 2 must be a class")
			return null
		if sub == sup:
			return DSLBool.new(true)
		var current = sub.superclass
		while current != null:
			if current == sup:
				return DSLBool.new(true)
			current = current.superclass
		return DSLBool.new(false)

	## getattr(obj, name, default) - 获取对象属性 [br]
	## 属性不存在时返回 default (若提供), 否则抛 AttributeError
	func builtin_getattr(args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLObject:
		if args.size() < 2 or args.size() > 3:
			raise_exception("TypeError", "getattr expected 2 or 3 arguments, got %d" % args.size())
			return null
		var obj = args[0]
		var name_obj = args[1]
		var name = name_obj.value if name_obj is DSLString else name_obj._dsl_str()
		var result = obj._dsl_getattribute(name)
		if result != null and not (result is DSLNone):
			return result
		if obj.last_error != "":
			obj.last_error = ""
			if args.size() == 3:
				return args[2]
			raise_exception("AttributeError", "'%s' object has no attribute '%s'" % [obj._type_name(), name])
			return null
		return result

	## setattr(obj, name, value) - 设置对象属性
	func builtin_setattr(args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLObject:
		if args.size() != 3:
			raise_exception("TypeError", "setattr expected 3 arguments, got %d" % args.size())
			return null
		var obj = args[0]
		var name_obj = args[1]
		var name = name_obj.value if name_obj is DSLString else name_obj._dsl_str()
		obj._dsl_setattr(name, args[2])
		if obj.last_error != "":
			raise_exception_from_last_error(obj.last_error, obj.last_error_args)
			obj.last_error = ""
			return null
		return DSLNone.new()

	## delattr(obj, name) - 删除对象属性
	func builtin_delattr(args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLObject:
		if args.size() != 2:
			raise_exception("TypeError", "delattr expected 2 arguments, got %d" % args.size())
			return null
		var obj = args[0]
		var name_obj = args[1]
		var name = name_obj.value if name_obj is DSLString else name_obj._dsl_str()
		obj._dsl_delattr(name)
		if obj.last_error != "":
			raise_exception_from_last_error(obj.last_error, obj.last_error_args)
			obj.last_error = ""
			return null
		return DSLNone.new()

	## map(func, iterable, ...) - 对可迭代对象逐元素应用函数 [br]
	## 支持多可迭代对象 (逐元素并行), 本实现为立即求值并返回列表
	func builtin_map(args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLList:
		if args.size() < 2:
			raise_exception("TypeError", "map() must have at least 2 arguments")
			return null
		var fn = args[0]
		var iter_lists: Array = []
		for i in range(1, args.size()):
			var it = args[i]._dsl_iter()
			if it == null:
				raise_exception("TypeError", "map() argument %d is not iterable" % (i + 1))
				return null
			var items: Array[DSLObject] = []
			while it.has_next():
				items.append(it.next())
				if it.suspended:
					break
			iter_lists.append(items)
		var count = iter_lists[0].size()
		if iter_lists.size() > 1:
			for lst in iter_lists:
				if lst.size() < count:
					count = lst.size()
		var result = DSLList.new()
		for i in range(count):
			var call_args: Array[DSLObject] = []
			for lst in iter_lists:
				call_args.append(lst[i])
			var r = fn.magic_call(call_args, {} as Dictionary[String, DSLObject])
			if r == null:
				return null
			result.items.append(r)
		return result

	## filter(func, iterable) - 保留满足条件的元素 [br]
	## func 为 null 时按真值过滤
	func builtin_filter(args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLList:
		if args.size() != 2:
			raise_exception("TypeError", "filter() takes exactly 2 arguments")
			return null
		var fn = args[0]
		var it = args[1]._dsl_iter()
		if it == null:
			raise_exception("TypeError", "filter() argument 2 is not iterable")
			return null
		var result = DSLList.new()
		while it.has_next():
			var item = it.next()
			if it.suspended:
				break
			var keep = false
			if fn == null or fn is DSLNone:
				keep = item._dsl_bool()
			else:
				var r = fn.magic_call([item] as Array[DSLObject], {} as Dictionary[String, DSLObject])
				if r == null:
					return null
				keep = r._dsl_bool()
			if keep:
				result.items.append(item)
		return result
		
	## int(x, base) - 转换为整数
	func builtin_int(args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLInteger:
		if args.size() == 0:
			return DSLInteger.new(0)
		if args.size() > 2:
			raise_exception("TypeError", "int() takes at most 2 arguments")
			return null
		var arg = args[0]
		if arg is DSLInteger:
			return arg
		if arg is DSLFloat:
			return DSLInteger.new(int(arg.value))
		if arg is DSLString:
			if args.size() == 2:
				var base = int(_num_val(args[1]))
				return _parse_int_with_base(arg.value, base)
			return DSLInteger.new(int(arg.value))
		if arg is DSLBool:
			return DSLInteger.new(1 if arg.value else 0)
		return DSLInteger.new(0)

	## 按指定进制解析整数字符串 (支持符号与前缀, base=0 时按 0x/0o/0b 前缀自动识别, 否则十进制)
	func _parse_int_with_base(s: String, base: int) -> DSLInteger:
		if base < 0 or base > 36:
			raise_exception("ValueError", "int() base must be >= 2 and <= 36, or 0")
			return null
		var text = s.strip_edges()
		var neg = false
		if text.begins_with("-"):
			neg = true
			text = text.substr(1)
		elif text.begins_with("+"):
			text = text.substr(1)
		if text == "":
			raise_exception("ValueError", "invalid literal for int() with base %d: '%s'" % [base, s])
			return null
		if base == 0:
			if text.begins_with("0x") or text.begins_with("0X"):
				base = 16
				text = text.substr(2)
			elif text.begins_with("0o") or text.begins_with("0O"):
				base = 8
				text = text.substr(2)
			elif text.begins_with("0b") or text.begins_with("0B"):
				base = 2
				text = text.substr(2)
			else:
				base = 10
		else:
			if base == 16 and (text.begins_with("0x") or text.begins_with("0X")):
				text = text.substr(2)
			elif base == 8 and (text.begins_with("0o") or text.begins_with("0O")):
				text = text.substr(2)
			elif base == 2 and (text.begins_with("0b") or text.begins_with("0B")):
				text = text.substr(2)
		if text == "":
			raise_exception("ValueError", "invalid literal for int() with base %d: '%s'" % [base, s])
			return null
		var value = 0
		for ch in text:
			var d = _digit_value(ch)
			if d < 0 or d >= base:
				raise_exception("ValueError", "invalid literal for int() with base %d: '%s'" % [base, s])
				return null
			value = value * base + d
		return DSLInteger.new(-value if neg else value)

	## 返回字符的数字值 (0-9a-z), 非法字符返回 -1
	func _digit_value(ch: String) -> int:
		if ch >= "0" and ch <= "9":
			return ch.unicode_at(0) - "0".unicode_at(0)
		var lower = ch.to_lower()
		if lower >= "a" and lower <= "z":
			return lower.unicode_at(0) - "a".unicode_at(0) + 10
		return -1

	## dict.fromkeys(iterable, value=None) - 以可迭代对象为键构造新字典, 值均为 value
	func builtin_fromkeys(args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLObject:
		if args.size() < 1 or args.size() > 2:
			raise_exception("TypeError", "fromkeys() takes 1 or 2 arguments")
			return null
		var default_val: DSLObject = DSLNone.new()
		if args.size() == 2:
			default_val = args[1]
		var d = DSLDict.new()
		var it = args[0]._dsl_iter()
		if it == null:
			raise_exception("TypeError", "fromkeys() argument must be iterable")
			return null
		while it.has_next():
			var k = it.next()
			if it.suspended:
				break
			d._dsl_setitem(k, default_val)
		return d
	
	## float(x) - 转换为浮点数
	func builtin_float(args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLFloat:
		if args.size() == 0:
			return DSLFloat.new(0.0)
		var arg = args[0]
		if arg is DSLFloat:
			return arg
		if arg is DSLInteger:
			return DSLFloat.new(float(arg.value))
		if arg is DSLString:
			return DSLFloat.new(float(arg.value))
		return DSLFloat.new(0.0)
		
	## round(x, ndigits) - 四舍五入
	func builtin_round(args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLObject:
		if args.size() == 0:
			raise_exception("TypeError", "round() takes at least one argument")
			return null
		var val = args[0]
		var has_ndigits = args.size() >= 2
		var ndigits = 0
		if has_ndigits:
			if args[1] is DSLInteger:
				ndigits = args[1].value
			elif args[1] is DSLFloat:
				ndigits = int(args[1].value)
		var num = 0.0
		if val is DSLInteger:
			num = float(val.value)
		elif val is DSLFloat:
			num = val.value
		else:
			raise_exception("TypeError", "a float is required")
			return null
		var factor = pow(10, ndigits)
		var scaled = num * factor
		# Banker's rounding (round half to even)
		var rounded = floor(scaled + 0.5)
		if abs(scaled - floor(scaled) - 0.5) < 0.0000001:
			if int(floor(scaled)) % 2 == 0:
				rounded = floor(scaled)
		rounded = rounded / factor
		if has_ndigits:
			# 与 Python 一致: round(int, n) 返回 int, round(float, n) 返回 float
			if val is DSLInteger:
				return DSLInteger.new(int(rounded))
			return DSLFloat.new(rounded)
		return DSLInteger.new(int(rounded))
		
	## input(prompt) - 读取用户输入
	func builtin_input(args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLObject:
		if args.size() > 0:
			var prompt = args[0]
			if prompt is DSLString:
				report.info(prompt.value)
				report.dsl.print_output += prompt.value
		raise_exception("EOFError", "EOF when reading a line")
		return null
		
	## callable(obj) - 检查对象是否可调用
	func builtin_callable(args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLObject:
		if args.size() == 0:
			raise_exception("TypeError", "callable() takes exactly one argument")
			return null
		return DSLBool.new(args[0]._dsl_is_callable())
	
	## iter(obj) - 返回迭代器
	func builtin_iter(args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLObject:
		if args.size() != 1:
			raise_exception("TypeError", "iter() takes exactly one argument")
			return null
		var obj = args[0]
		var internal_it = obj._dsl_iter()
		if internal_it == null:
			raise_exception("TypeError", "object is not iterable")
			return null
		var items: Array[DSLObject] = []
		while internal_it.has_next():
			items.append(internal_it.next())
			if internal_it.suspended:
				break
		var it_obj = DSLList.new(items)
		it_obj.iter_index = 0
		return it_obj
	
	## next(iter, default) - 获取迭代器的下一个元素
	func builtin_next(args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLObject:
		if args.size() < 1 or args.size() > 2:
			raise_exception("TypeError", "next() takes 1 or 2 arguments")
			return null
		var it = args[0]
		if it is DSLList:
			if it.iter_index < it.items.size():
				var result = it.items[it.iter_index]
				it.iter_index += 1
				return result
		else:
			var iter = it._dsl_iter()
			if iter == null:
				raise_exception("TypeError", "object is not an iterator")
				return null
			# next() 是消费语义: 语句重放时游标可能被回退到窗口起点,
			# 此处推进到已确认取走的位置, 避免把交付过的值再交付一次
			if iter._read_pos < iter._hi_pos:
				iter._read_pos = iter._hi_pos
			if iter.has_next():
				return iter.next()
			if iter.suspended:
				# 消费中途挂起: 交由语句重放, 不能当作已耗尽
				return null
		if args.size() == 2:
			return args[1]
		if report.has_error:
			return null
		if it is DSLFunctionGenerator and it._finished:
			raise_stop_iteration_value(it._result_value)
			return null
		raise_exception("StopIteration", "")
		return null
	
	## bool(x) - 转换为布尔值
	func builtin_bool(args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLBool:
		if args.size() == 0:
			return DSLBool.new(false)
		elif args.size() > 1:
			raise_exception("TypeError", "bool expected at most 1 argument, got %d" % args.size())
			return null
		return DSLBool.new(true if args[0]._dsl_bool() else false)
	
	## list(iterable) - 构造列表
	func builtin_list(args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLList:
		var lst = DSLList.new()
		if args.size() > 0:
			var it = args[0]._dsl_iter()
			if it == null:
				raise_exception("TypeError", "list() argument must be iterable")
				return null
			while it.has_next():
				lst.items.append(it.next())
				if it.suspended:
					break
				if it.suspended:
					return null
		return lst
	
	## dict(iterable) - 构造字典
	func builtin_dict(args: Array[DSLObject], kwargs: Dictionary[String, DSLObject]) -> DSLDict:
		var d = DSLDict.new()
		if not kwargs.is_empty():
			for k in kwargs.keys():
				var key_obj = DSLString.new(k)
				d.dict[key_obj._dsl_str()] = kwargs[k]
			return d
		if args.size() > 0:
			var arg = args[0]
			var it = arg._dsl_iter()
			if it == null:
				raise_exception("TypeError", "dict() argument must be iterable")
				return null
			while it.has_next():
				var pair = it.next()
				if it.suspended:
					break
				if pair is DSLTuple and pair.items.size() == 2:
					var k = pair.items[0]
					var v = pair.items[1]
					var vkey = d._key_to_variant(k)
					if vkey != null:
						d.dict[vkey] = v
		return d
	
	## type(obj) - 返回对象的类型
	func builtin_type(args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLObject:
		if args.size() == 0:
			raise_exception("TypeError", "type() takes 1 or 3 arguments")
			return null
		if args.size() == 2:
			raise_exception("TypeError", "type() takes 1 or 3 arguments")
			return null
		if args.size() == 3:
			return _type_metaclass(args[0], args[1], args[2])
		var obj = args[0]
		if obj.klass != null:
			return obj.klass
		# For built-in types without klass, look up the class from globals (if it exists)
		var type_name = args[0]._type_name()
		if type_name != "object":
			# 优先查内置类型表 (range 等名字被内置函数占用的类型)
			if _builtin_type_classes.has(type_name):
				return _builtin_type_classes[type_name]
			# Safely check if the class exists in globals
			var cls = globals.get_val_safe(type_name)
			if cls is DSLClass:
				return cls
		return DSLString.new("<class '" + type_name + "'>")
	
	## type(name, bases, dict) 元类构造器, 动态创建新类 [br]
	## [param name_obj] 类名 (DSLString) [br]
	## [param bases_obj] 基类 (DSLTuple 或 DSLClass) [br]
	## [param attrs_obj] 类属性字典 (DSLDict) [br]
	## [returns] 新创建的 DSLClass
	func _type_metaclass(name_obj: DSLObject, bases_obj: DSLObject, attrs_obj: DSLObject) -> DSLObject:
		# Validate name
		if not name_obj is DSLString:
			raise_exception("TypeError", "type() argument 1 must be str, not " + name_obj._type_name())
			return null
		# Validate dict
		if not attrs_obj is DSLDict:
			raise_exception("TypeError", "type() argument 3 must be dict, not " + attrs_obj._type_name())
			return null
		# Determine superclass
		var superclass = globals.get_val_safe("object")
		if bases_obj is DSLTuple:
			if bases_obj.items.size() > 1:
				raise_exception("TypeError", "multiple bases are not yet supported")
				return null
			if bases_obj.items.size() == 1:
				var base = bases_obj.items[0]
				if base is DSLClass:
					superclass = base
				else:
					raise_exception("TypeError", "bases must be types")
					return null
		elif bases_obj is DSLClass:
			superclass = bases_obj
		elif bases_obj is DSLTuple and bases_obj.items.size() == 0:
			pass # empty tuple, use object
		else:
			raise_exception("TypeError", "bases must be types")
			return null
		# Build methods and class_attrs from attrs
		var methods = {}
		var class_attrs_dict = {}
		for key in attrs_obj.dict:
			var val = attrs_obj.dict[key]
			var key_str = str(key) if key is String else str(key)
			# DSLFunction or callable objects become methods
			if val is DSLFunction or val.has_method("magic_call"):
				methods[key_str] = val
			else:
				class_attrs_dict[key_str] = val
		var new_cls = DSLClass.new(name_obj.value, superclass, methods, self)
		new_cls.klass = globals.get_val_safe("type")
		new_cls.class_attrs = class_attrs_dict
		globals.define(name_obj.value, new_cls)
		return new_cls
	
	## id(obj) - 返回对象的唯一标识
	func builtin_id(args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLInteger:
		if args.size() != 1:
			raise_exception("TypeError", "id() takes exactly one argument (%d given)" % args.size())
			return null
		return DSLInteger.new(args[0]._object_id)
	
	## 内部 API: int.__new__, 直接返回 DSLInteger [br]
	## 对于 int 本身返回裸 DSLInteger, 对于子类返回带 klass 标记的 DSLInteger [br]
	## [param args] [cls, value?] [br]
	## [returns] DSLInteger, DSLInstance
	func api_int_new(args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLObject:
		var cls = args[0]
		if cls.name == "int":
			if args.size() > 3:
				raise_exception("TypeError", "int expected at most 2 arguments, got %d" % (args.size() - 1))
				return null
			if args.size() >= 2:
				var arg = args[1]
				if arg is DSLInteger:
					return DSLInteger.new(arg.value)
				elif arg is DSLFloat:
					return DSLInteger.new(int(arg.value))
				elif arg is DSLString:
					if args.size() == 3:
						var base = _num_val(args[2])
						if base == null:
							raise_exception("TypeError", "int() base must be an integer")
							return null
						return _parse_int_with_base(arg.value, int(base))
					return DSLInteger.new(int(arg.value))
				elif arg is DSLBool:
					return DSLInteger.new(1 if arg.value else 0)
			return DSLInteger.new(0)
		var result = DSLInteger.new(0)
		if args.size() >= 2:
			var arg = args[1]
			if arg is DSLInteger:
				result = DSLInteger.new(arg.value)
			elif arg is DSLFloat:
				result = DSLInteger.new(int(arg.value))
			elif arg is DSLString:
				result = DSLInteger.new(int(arg.value))
			elif arg is DSLBool:
				result = DSLInteger.new(1 if arg.value else 0)
		result.klass = cls
		return result
	
	## 内部 API: float.__new__, 直接返回 DSLFloat [br]
	## 对于 float 类本身直接返回 DSLFloat 裸值, 对于子类返回带 klass 标记的 DSLFloat [br]
	## [param args] [cls, value?], cls 为目标类, value 为可选的初始值 [br]
	## [param _kwargs] 关键字参数 (未使用) [br]
	## [returns] DSLFloat 或带 klass 标记的 DSLFloat
	func api_float_new(args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLObject:
		var cls = args[0]
		if cls.name == "float":
			if args.size() > 2:
				raise_exception("TypeError", "float expected at most 1 argument, got %d" % (args.size() - 1))
				return null
			if args.size() >= 2:
				var arg = args[1]
				if arg is DSLFloat:
					return DSLFloat.new(arg.value)
				elif arg is DSLInteger:
					return DSLFloat.new(float(arg.value))
				elif arg is DSLString:
					return DSLFloat.new(float(arg.value))
			return DSLFloat.new(0.0)
		var result = DSLFloat.new(0.0)
		if args.size() >= 2:
			var arg = args[1]
			if arg is DSLFloat:
				result = DSLFloat.new(arg.value)
			elif arg is DSLInteger:
				result = DSLFloat.new(float(arg.value))
			elif arg is DSLString:
				result = DSLFloat.new(float(arg.value))
		result.klass = cls
		return result
	
	## 内部 API: str.__new__, 直接返回 DSLString [br]
	## 对于 str 类本身直接返回 DSLString 裸值, 对于子类返回带 klass 标记的 DSLString [br]
	## [param args] [cls, value?], cls 为目标类, value 为可选的初始值 [br]
	## [param _kwargs] 关键字参数 (未使用) [br]
	## [returns] DSLString 或带 klass 标记的 DSLString
	func api_str_new(args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLObject:
		var result: DSLString
		var cls = args[0]
		if cls.name == "str":
			if args.size() > 2:
				raise_exception("TypeError", "str expected at most 1 argument, got %d" % (args.size() - 1))
				return null
			if args.size() >= 2:
				result = args[1].magic_str([args[1]] as Array[DSLObject], {} as Dictionary[String, DSLObject])
				if result is DSLString:
					return result
				return DSLString.new(args[1]._dsl_str())
			return DSLString.new("")
		result = DSLString.new("")
		if args.size() >= 2:
			result = DSLString.new(args[1]._dsl_str())
		result.klass = cls
		return result
	
	## 内部 API: list.__new__, 直接返回 DSLList [br]
	## 对于 list 类本身直接返回 DSLList 裸值, 对于子类返回带 klass 标记的 DSLList [br]
	## [param args] [cls, iterable?], cls 为目标类, iterable 为可选的可迭代初始值 [br]
	## [param _kwargs] 关键字参数 (未使用) [br]
	## [returns] DSLList 或带 klass 标记的 DSLList
	func api_list_new(args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLObject:
		var cls = args[0]
		if cls.name == "list":
			if args.size() > 2:
				raise_exception("TypeError", "list expected at most 1 argument, got %d" % (args.size() - 1))
				return null
			var raw = DSLList.new()
			if args.size() >= 2 and not args[1] is DSLNone:
				var arg = args[1]
				if arg._wrapped != null:
					arg = arg._wrapped
				var it = arg._dsl_iter()
				if it != null:
					while it.has_next():
						raw.items.append(it.next())
						if it.suspended:
							break
			return raw
		var result = DSLList.new()
		if args.size() >= 2 and not args[1] is DSLNone:
			var arg = args[1]
			if arg._wrapped != null:
				arg = arg._wrapped
			var it = arg._dsl_iter()
			if it != null:
				while it.has_next():
					result.items.append(it.next())
					if it.suspended:
						break
		result.klass = cls
		return result
	
	## 内部 API: tuple.__new__, 直接返回 DSLTuple [br]
	## 对于 tuple 类本身直接返回 DSLTuple 裸值, 对于子类返回带 klass 标记的 DSLTuple [br]
	## [param args] [cls, iterable?], cls 为目标类, iterable 为可选的可迭代初始值 [br]
	## [param _kwargs] 关键字参数 (未使用) [br]
	## [returns] DSLTuple 或带 klass 标记的 DSLTuple
	func api_tuple_new(args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLObject:
		var cls = args[0]
		var arr: Array[DSLObject] = []
		if cls.name == "tuple":
			if args.size() > 2:
				raise_exception("TypeError", "tuple expected at most 1 argument, got %d" % (args.size() - 1))
				return null
			if args.size() >= 2 and not args[1] is DSLNone:
				var arg = args[1]
				if arg._wrapped != null:
					arg = arg._wrapped
				var it = arg._dsl_iter()
				if it != null:
					while it.has_next():
						arr.append(it.next())
						if it.suspended:
							break
						if it.suspended:
							break
			return DSLTuple.new(arr)
		if args.size() >= 2 and not args[1] is DSLNone:
			var arg = args[1]
			if arg._wrapped != null:
				arg = arg._wrapped
			var it = arg._dsl_iter()
			if it != null:
				while it.has_next():
					arr.append(it.next())
					if it.suspended:
						break
		var result = DSLTuple.new(arr)
		result.klass = cls
		return result

	## slice 类型构造: slice(stop) / slice(start, stop) / slice(start, stop, step) [br]
	## None 表示未指定的边界, 返回 DSLSlice
	func api_slice_new(args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLObject:
		var cls = args[0]
		if args.size() < 2 or args.size() > 4:
			raise_exception("TypeError", "slice expected at most 3 arguments, got %d" % (args.size() - 1))
			return null
		var start: DSLObject = null
		var stop: DSLObject = null
		var step: DSLObject = null
		if args.size() == 2:
			stop = args[1]
		elif args.size() == 3:
			start = args[1]
			stop = args[2]
		else:
			start = args[1]
			stop = args[2]
			step = args[3]
		var sl = DSLSlice.new(
			null if (start == null or start is DSLNone) else start,
			null if (stop == null or stop is DSLNone) else stop,
			null if (step == null or step is DSLNone) else step)
		sl.klass = cls
		return sl
	
	## 内部 API: dict.__new__, 直接返回 DSLDict [br]
	## 对于 dict 类本身直接返回 DSLDict 裸值, 对于子类返回带 klass 标记的 DSLDict [br]
	## [param args] [cls, mapping/iterable?], cls 为目标类, 可选的字典或可迭代键值对初始值 [br]
	## [param _kwargs] 关键字参数 (未使用) [br]
	## [returns] DSLDict 或带 klass 标记的 DSLDict
	func api_dict_new(args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLObject:
		var cls = args[0]
		if cls.name == "dict":
			if args.size() > 2:
				raise_exception("TypeError", "dict expected at most 1 argument, got %d" % (args.size() - 1))
				return null
			var raw = DSLDict.new()
			if args.size() >= 2 and not args[1] is DSLNone:
				var arg = args[1]
				if arg._wrapped != null:
					arg = arg._wrapped
				if arg is DSLDict:
					for k in arg.dict.keys():
						raw.dict[k] = arg.dict[k]
				else:
					var it = arg._dsl_iter()
					if it != null:
						while it.has_next():
							var pair = it.next()
							if it.suspended:
								break
							var k = null
							var v = null
							if pair is DSLTuple and pair.items.size() == 2:
								k = pair.items[0]
								v = pair.items[1]
							elif pair is DSLList and pair.items.size() == 2:
								k = pair.items[0]
								v = pair.items[1]
							if k != null:
								raw.dict[raw._key_to_variant(k)] = v
			return raw
		var result = DSLDict.new()
		if args.size() >= 2 and not args[1] is DSLNone:
			var arg = args[1]
			if arg._wrapped != null:
				arg = arg._wrapped
			if arg is DSLDict:
				for k in arg.dict.keys():
					result.dict[k] = arg.dict[k]
			else:
				var it = arg._dsl_iter()
				if it != null:
					while it.has_next():
						var pair = it.next()
						if it.suspended:
							break
						var k = null
						var v = null
						if pair is DSLTuple and pair.items.size() == 2:
							k = pair.items[0]
							v = pair.items[1]
						elif pair is DSLList and pair.items.size() == 2:
							k = pair.items[0]
							v = pair.items[1]
						if k != null:
							result.dict[result._key_to_variant(k)] = v
		result.klass = cls
		return result
	
	## 内部 API: bool.__new__, 直接返回 DSLBool [br]
	## 对于 bool 类本身直接返回 DSLBool 裸值, 对于子类返回带 klass 标记的 DSLBool [br]
	## [param args] [cls, value?], cls 为目标类, value 为可选的初始值 (通过 _dsl_bool() 转换) [br]
	## [param _kwargs] 关键字参数 (未使用) [br]
	## [returns] DSLBool 或带 klass 标记的 DSLBool
	func api_bool_new(args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLObject:
		var cls = args[0]
		if cls.name == "bool":
			if args.size() > 2:
				raise_exception("TypeError", "bool expected at most 1 argument, got %d" % (args.size() - 1))
				return null
			if args.size() >= 2:
				return DSLBool.new(true if args[1]._dsl_bool() else false)
			return DSLBool.new(false)
		var result = DSLBool.new(false)
		if args.size() >= 2:
			result = DSLBool.new(true if args[1]._dsl_bool() else false)
		result.klass = cls
		return result
	
	## 内部 API: NoneType.__new__, 直接返回 DSLNone [br]
	## [param args] args[0] 为目标 DSLClass [br]
	## [param _kwargs] 关键字参数 (未使用) [br]
	## [returns] DSLNone
	func api_none_new(_args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLObject:
		return DSLNone.new()

	## 内部 API: set.__new__, 从可迭代对象构造 DSLSet [br]
	## [param args] args[0] 为目标 DSLClass, args[1:] 为构造参数 [br]
	## [param _kwargs] 关键字参数 (未使用) [br]
	## [returns] DSLSet
	func api_set_new(args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLObject:
		var s = DSLSet.new()
		if args.size() >= 2:
			var it = args[1]._dsl_iter()
			if it == null:
				raise_exception("TypeError", "set() argument must be iterable")
				return null
			while it.has_next():
				var item = it.next()
				if it.suspended:
					break
				if s._dsl_add(item) == null:
					raise_exception_from_last_error(s.last_error)
					return null
		return s

	## 内部 API: frozenset.__new__, 从可迭代对象构造不可变 DSLFrozenSet [br]
	## [param args] args[0] 为目标 DSLClass, args[1:] 为构造参数 [br]
	## [param _kwargs] 关键字参数 (未使用) [br]
	## [returns] DSLFrozenSet
	func api_frozenset_new(args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLObject:
		var s = DSLFrozenSet.new()
		if args.size() >= 2:
			var it = args[1]._dsl_iter()
			if it == null:
				raise_exception("TypeError", "frozenset() argument must be iterable")
				return null
			while it.has_next():
				var item = it.next()
				if it.suspended:
					break
				if s._dsl_add(item) == null:
					raise_exception_from_last_error(s.last_error)
					return null
		return s
	
	## 内部 API: object.__new__, 创建指定类的实例 [br]
	## [param args] args[0] 为目标 DSLClass [br]
	## [param _kwargs] 关键字参数 (未使用) [br]
	## [returns] 新的 DSLInstance
	func api_object_new(args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLObject:
		if args.size() < 1:
			raise_exception("TypeError", "object.__new__(): not enough arguments")
			return null
		var cls = args[0]
		if not cls is DSLClass:
			raise_exception("TypeError", "object.__new__(X): X is not a type object (%s)" % cls._type_name())
			return null
		var inst = DSLObject.new()
		inst.klass = cls
		inst.fields = {}
		inst.interp = self
		return inst
	
	## 内部 API: list.__init__, 初始化列表 wrapper 的内部数据 [br]
	## [param args] [DSLInstance wrapper, 可选的初始数据 (可迭代对象)] [br]
	## [param _kwargs] 关键字参数 (未使用)
	func api_list_init(args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLNone:
		if args.size() > 2:
			raise_exception("TypeError", "list expected at most 1 argument, got %d" % (args.size() - 1))
			return null
		var self_obj = args[0]
		if self_obj is DSLList:
			self_obj.items.clear()
		else:
			return DSLNone.new()
		if args.size() >= 2 and not args[1] is DSLNone:
			var arg = args[1]
			if arg._wrapped != null:
				arg = arg._wrapped
			var it = arg._dsl_iter()
			if it != null:
				while it.has_next():
					self_obj.items.append(it.next())
					if it.suspended:
						break
		return DSLNone.new()
	
	## 内部 API: dict.__init__, 初始化字典 wrapper 的内部数据 [br]
	## [param args] [DSLInstance wrapper, 可选的初始数据 (可迭代对象或 DSLDict)] [br]
	## [param _kwargs] 关键字参数 (未使用)
	func api_dict_init(args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLNone:
		if args.size() > 2:
			raise_exception("TypeError", "dict expected at most 1 argument, got %d" % (args.size() - 1))
			return null
		var self_obj = args[0]
		if self_obj is DSLDict:
			self_obj.dict.clear()
		else:
			return DSLNone.new()
		if args.size() >= 2 and not args[1] is DSLNone:
			var arg = args[1]
			if arg._wrapped != null:
				arg = arg._wrapped
			if arg is DSLDict:
				for k in arg.dict.keys():
					self_obj.dict[k] = arg.dict[k]
			else:
				var it = arg._dsl_iter()
				if it != null:
					while it.has_next():
						var pair = it.next()
						if it.suspended:
							break
						var k = null
						var v = null
						if pair is DSLTuple and pair.items.size() == 2:
							k = pair.items[0]
							v = pair.items[1]
						elif pair is DSLList and pair.items.size() == 2:
							k = pair.items[0]
							v = pair.items[1]
						if k != null:
							self_obj.dict[k._dsl_str()] = v
		return DSLNone.new()
	
	## 内部 API: str.__init__, 初始化字符串 wrapper 的内部数据 [br]
	## [param args] [DSLInstance wrapper, 可选的初始数据 (字符串来源)] [br]
	## [param _kwargs] 关键字参数 (未使用)
	func api_str_init(args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLNone:
		if args.size() > 2:
			raise_exception("TypeError", "str expected at most 1 argument, got %d" % (args.size() - 1))
			return null
		var wrapper = args[0]
		var raw = DSLString.new("")
		if args.size() >= 2:
			raw = DSLString.new(args[1]._dsl_str())
		if wrapper.fields != null:
			wrapper._wrapped = raw
		return DSLNone.new()
	
	## 内部 API: tuple.__init__, 初始化元组 wrapper 的内部数据 [br]
	## [param args] [DSLInstance wrapper, 可选的初始数据 (可迭代对象)] [br]
	## [param _kwargs] 关键字参数 (未使用)
	func api_tuple_init(args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLNone:
		if args.size() > 2:
			raise_exception("TypeError", "tuple expected at most 1 argument, got %d" % (args.size() - 1))
			return null
		var self_obj = args[0]
		if self_obj is DSLTuple:
			self_obj.items.clear()
		else:
			return DSLNone.new()
		if args.size() >= 2 and not args[1] is DSLNone:
			var arg = args[1]
			if arg._wrapped != null:
				arg = arg._wrapped
			var it = arg._dsl_iter()
			if it != null:
				while it.has_next():
					self_obj.items.append(it.next())
					if it.suspended:
						break
		return DSLNone.new()
	
	## 内部 API: 从 DSLInstance wrapper 中提取 _wrapped 字段 [br]
	## 用于桥接 DSL 类型系统与 Godot 原生类型 [br]
	## [param args] args[0] 为目标 DSLInstance [br]
	## [returns] 内部原始对象或原始 DSLObject
	func api_get_obj(args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLObject:
		if args.size() == 0:
			return DSLNone.new()
		var obj = args[0]
		if obj._wrapped != null:
			return obj._wrapped
		return obj
	
	## 内部 API: int.__init__, 初始化整数 wrapper 的内部数据 [br]
	## [param args] [DSLInstance wrapper, 可选的初始数据 (数字或字符串)] [br]
	## [param _kwargs] 关键字参数 (未使用)
	func api_int_init(args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLNone:
		if args.size() > 2:
			raise_exception("TypeError", "int expected at most 1 argument, got %d" % (args.size() - 1))
			return null
		var wrapper = args[0]
		var raw = DSLInteger.new(0)
		if args.size() >= 2:
			var arg = args[1]
			if arg is DSLInteger:
				raw = DSLInteger.new(arg.value)
			elif arg is DSLFloat:
				raw = DSLInteger.new(int(arg.value))
			elif arg is DSLString:
				raw = DSLInteger.new(int(arg.value))
			elif arg is DSLBool:
				raw = DSLInteger.new(1 if arg.value else 0)
		if wrapper.fields != null:
			wrapper._wrapped = raw
		return DSLNone.new()
	
	## 内部 API: float.__init__, 初始化浮点数 wrapper 的内部数据 [br]
	## [param args] [DSLInstance wrapper, 可选的初始数据 (数字或字符串)] [br]
	## [param _kwargs] 关键字参数 (未使用)
	func api_float_init(args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLNone:
		if args.size() > 2:
			raise_exception("TypeError", "float expected at most 1 argument, got %d" % (args.size() - 1))
			return null
		var wrapper = args[0]
		var raw = DSLFloat.new(0.0)
		if args.size() >= 2:
			var arg = args[1]
			if arg is DSLFloat:
				raw = DSLFloat.new(arg.value)
			elif arg is DSLInteger:
				raw = DSLFloat.new(float(arg.value))
			elif arg is DSLString:
				raw = DSLFloat.new(float(arg.value))
		if wrapper.fields != null:
			wrapper._wrapped = raw
		return DSLNone.new()
	
	## 内部 API: bool.__init__, 初始化布尔 wrapper 的内部数据 [br]
	## [param args] [DSLInstance wrapper, 可选的初始数据 (任意对象)] [br]
	## [param _kwargs] 关键字参数 (未使用)
	func api_bool_init(args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLNone:
		if args.size() > 2:
			raise_exception("TypeError", "bool expected at most 1 argument, got %d" % (args.size() - 1))
			return null
		var wrapper = args[0]
		var raw = DSLBool.new(false)
		if args.size() >= 2:
			raw = DSLBool.new(true if args[1]._dsl_bool() else false)
		if wrapper.fields != null:
			wrapper._wrapped = raw
		return DSLNone.new()
		
	## 将 Godot 原生变体自动包装为对应的 DSLObject [br]
	## int/float/string/bool/null 分别包装为 DSLInteger/DSLFloat/DSLString/DSLBool/DSLNone, [br]
	## Array/Dictionary 递归包装为 DSLList/DSLDict, [br]
	## DSLObject 类型直接原样返回 [br]
	## [param v] 任意 Godot Variant 值 [br]
	## [returns] 对应的 DSLObject
	func _wrap(v):
		if v is DSLObject:
			return v
		if typeof(v) == TYPE_INT:
			return DSLInteger.new(v)
		if typeof(v) == TYPE_FLOAT:
			return DSLFloat.new(v)
		if typeof(v) == TYPE_STRING:
			return DSLString.new(v)
		if typeof(v) == TYPE_BOOL:
			if v:
				if _cached_true == null:
					_cached_true = DSLBool.new(v)
				return _cached_true
			if _cached_false == null:
				_cached_false = DSLBool.new(v)
			return _cached_false
		if v == null:
			if _cached_none == null:
				_cached_none = DSLNone.new()
			return _cached_none
		if v is Array:
			var lst = DSLList.new()
			for e in v:
				lst.items.append(_wrap(e))
			return lst
		if v is Dictionary:
			var d = DSLDict.new()
			for k in v.keys():
				d.dict[_wrap(k)] = _wrap(v[k])
			return d
		return _cached_none if _cached_none else DSLNone.new()

# ============================================================
# Main DSL class
# ============================================================

## 调试模式开关, 控制是否输出详细调试信息
var debug: bool = true

## DSL 源代码文本
var dsl_script: String = ""
## 预设代码源文本 (在用户代码之前执行)
var _preset_script: String = ""
## 累积的 print 输出文本
var print_output: String = ""
## 控制台输出文本 (日志/错误)
var console_output: String = ""
## 用户代码解析后的 AST 语句列表
var statements: Array = []
## 预设代码解析后的 AST 语句
var _preset_statements: Array = []
## 解释器实例
var interpreter: Interpreter = null
## 控制台报告器实例
var report: ConsoleReport = null
## 日志输出级别
var log_level: ConsoleReport.Level = ConsoleReport.Level.INFO

## SLEEPING 恢复回调, 在 run() 恢复执行前调用
var _sleeping_resume_callback: Callable = Callable()
## WAITING 恢复回调, 在 run() 恢复执行前调用
var _waiting_resume_callback: Callable = Callable()

## 最大执行步数 (传入 Interpreter)
var _config_max_steps: int = 50000
## 外部 API 函数注册 名称 -> Callable 的映射
var api_functions: Dictionary[String, Callable] = {}

## 状态机枚举
enum State {
	## 空闲
	IDLE,
	## 运行
	RUNNING,
	## 挂起睡眠中 (sleep 触发, Timer 超时后自动恢复)
	SUSPENDED_SLEEPING,
	## 挂起等待中 (request_suspend_waiting 触发, 外部设置 RUNNING 后手动调用 run() 恢复)
	SUSPENDED_WAITING,
	## 完成
	FINISHED,
	## 错误
	ERROR
}
## 当前状态
var state: State = State.IDLE

## 请求睡眠挂起, 适用于已知等待时间的场景 [br]
## Timer 超时后自动调用 [method run] 恢复执行 [br]
## [param value] 挂起秒数 [br]
## [param on_resume] 可选, 恢复执行前回调 (在 run() 被唤醒后调用)
func request_suspend_sleeping(value: float, on_resume: Callable = Callable()) -> void:
	if state != State.RUNNING or interpreter == null:
		return
	interpreter._suspended = true
	interpreter._is_waiting = false
	interpreter._suspend_reason = Interpreter.SuspendReason.SLEEPING
	state = State.SUSPENDED_SLEEPING
	if on_resume.is_valid():
		_sleeping_resume_callback = on_resume

	var tree = Engine.get_main_loop() as SceneTree
	if tree != null:
		tree.create_timer(value).timeout.connect(run)
	else:
		run.call_deferred()

## 请求等待挂起, 适用于未知等待时间的场景 [br]
## 外部需先设置 [member state] = RUNNING, 再调用 [method run] 恢复执行 [br]
## [param on_resume] 可选, 恢复执行前回调 (在 run() 被唤醒后调用)
func request_suspend_waiting(on_resume: Callable = Callable()) -> void:
	if state != State.RUNNING or interpreter == null:
		return
	interpreter._suspended = true
	interpreter._is_waiting = true
	interpreter._suspend_reason = Interpreter.SuspendReason.WAITING
	state = State.SUSPENDED_WAITING
	_waiting_resume_callback = on_resume

## 返回当前状态码
func get_state() -> State:
	return state

## 重置所有运行时状态
func reset() -> void:
	statements = []
	report = null
	interpreter = null
	state = State.IDLE
	_sleeping_resume_callback = Callable()
	_waiting_resume_callback = Callable()
	print_output = ""
	console_output = ""

## 设置调试模式 [br]
## [param need_debug] 是否开启调试模式
func set_debug_mode(need_debug: bool) -> void:
	debug = need_debug
	if report:
		report.debug_mode = need_debug

## 设置日志输出级别 [br]
## [param log_lv] 日志级别
func set_log_level(log_lv: ConsoleReport.Level) -> void:
	log_level = log_lv
	if report:
		report.report_log_level = log_lv
		report.refresh_output()

## 注册外部 API 函数 [br]
## [param api] 名称 -> Callable 的字典映射
func register_api(api: Dictionary):
	for key in api:
		api_functions[key] = api[key]

## 注册单个外部 API 函数
func register_api_pair(api_name: String, callable: Callable) -> void:
	api_functions[api_name] = callable

## 设置预设代码 [br]
## 预设代码会在用户代码之前执行, 用户代码可直接使用其中定义的变量, 函数, 导入等 [br]
## [param source] 预设 DSL 源代码, 传空字符串可清除预设
func set_preset_script(source: String) -> void:
	_preset_script = source

	if _preset_script.is_empty():
		_preset_statements = []
	else:
		var r = ConsoleReport.new(self, debug)
		var tokens = []
		var lexer = Lexer.new(r, _preset_script)
		tokens = lexer.scan()
		if r.has_error:
			push_error("[PresetScriptError] " + r.last_error)
			_preset_statements = []
		else:
			var parser = Parser.new(r, tokens)
			_preset_statements = parser.parse()
			if r.has_error:
				push_error("[PresetScriptError] " + r.last_error)
				_preset_statements = []

	if not dsl_script.is_empty():
		write_dsl_script(dsl_script)

## 解析 DSL 源代码为 AST [br]
## 经过词法分析 (Lexer) 和语法分析 (Parser), [br]
## 结果存入 [member statements] [br]
## [param source] DSL 源代码字符串
func write_dsl_script(source: String):
	if state != State.IDLE:
		reset()
	dsl_script = source
	print_output = ""
	console_output = ""
	statements = []
	report = ConsoleReport.new(self, debug)
	var tokens = []
	var lexer = Lexer.new(report, source)
	tokens = lexer.scan()
	if not report.has_error:
		var parser = Parser.new(report, tokens)
		statements = parser.parse()
	if report.has_error:
		report.fatal_error(report.last_error)
		return
	# 在用户代码之前插入预设代码
	if not _preset_statements.is_empty():
		var combined = _preset_statements.duplicate()
		combined.append_array(statements)
		statements = combined

## 执行已解析的 DSL 代码 [br]
## 创建解释器实例并运行所有 AST 语句
func run() -> State:
	if report.has_error:
		state = State.ERROR
		return state
	
	if state == State.FINISHED or state == State.ERROR:
		return state
	
	if state == State.SUSPENDED_WAITING:
		# WAITING 挂起, 外部需先设置 state = State.RUNNING 再调用 run()
		return state
	
	if state == State.SUSPENDED_SLEEPING:
		state = State.RUNNING
		if _sleeping_resume_callback.is_valid():
			_sleeping_resume_callback.call()
			_sleeping_resume_callback = Callable()
	
	if interpreter != null and interpreter._suspended:
		# 从挂起中恢复 (SLEEPING 被 Timer 唤醒, 或 WAITING 被外部设为 RUNNING)
		interpreter._suspended = false
		state = State.RUNNING
		if _waiting_resume_callback.is_valid():
			_waiting_resume_callback.call()
			_waiting_resume_callback = Callable()
	
	if state == State.IDLE:
		interpreter = Interpreter.new(report, api_functions)
		interpreter.owner = self
		interpreter.max_steps = _config_max_steps
	
	state = State.RUNNING
	interpreter.interpret(statements)
	
	if interpreter != null and interpreter._had_fatal_error:
		# 未捕获错误已终止执行: 明确进入 ERROR, 避免停留在挂起态被反复恢复
		state = State.ERROR
	elif interpreter != null and interpreter._suspended:
		if interpreter._is_waiting:
			state = State.SUSPENDED_WAITING
		else:
			state = State.SUSPENDED_SLEEPING
	elif state == State.RUNNING and not report.has_error:
		state = State.FINISHED
	
	return state
