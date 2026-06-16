class_name PyGDS
extends Node

## Token 类型
enum TokenType {
	PLUS, MINUS, STAR, SLASH, DOUBLESLASH, STARSTAR, PERCENT, DOT,
	EQUAL, GREATER, LESS, BANG, PIPE, BITAND, LESS_LESS, GREATER_GREATER, CARET, TILDE,
	LPAREN, RPAREN, LBRACKET, RBRACKET,
	LBRACE, RBRACE, COMMA, COLON, NEWLINE,
	EQUAL_EQUAL, NOT_EQUAL, GREATER_EQUAL, LESS_EQUAL,
	IDENTIFIER, STRING, INTEGER, FLOAT,
	IF, ELIF, ELSE, WHILE, FOR, IN, ASSERT,
	AND, OR, NOT, TRUE, FALSE,
	DEF, CLASS, RETURN, BREAK, CONTINUE, PASS,
	GLOBAL, NONLOCAL, DEL,
	INDENT, DEDENT, EOF,
	AT, NULL,
	TRY, EXCEPT, FINALLY, RAISE, AS,
	PLUS_EQ, MINUS_EQ, STAR_EQ, SLASH_EQ, DOUBLESLASH_EQ, STARSTAR_EQ, PERCENT_EQ,
	IS, IS_NOT, NOT_IN
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
	## 缩进 用于生成 INDENT/DEDENT
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
		"try": TokenType.TRY, "except": TokenType.EXCEPT, "finally": TokenType.FINALLY,
		"raise": TokenType.RAISE, "as": TokenType.AS,
		"is": TokenType.IS
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
			'|': add_token(TokenType.PIPE)
			'(': add_token(TokenType.LPAREN)
			')': add_token(TokenType.RPAREN)
			'[': add_token(TokenType.LBRACKET)
			']': add_token(TokenType.RBRACKET)
			'{': add_token(TokenType.LBRACE)
			'}': add_token(TokenType.RBRACE)
			',': add_token(TokenType.COMMA)
			':': add_token(TokenType.COLON)
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
	## [returns] 转义后的字符串
	func _unescape_string(s: String) -> String:
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
		
	## 扫描数字字面量 (整数或浮点数)
	func number():
		while peek().is_valid_int():
			advance()
		if peek() == '.' and peek_next().is_valid_int():
			advance()
			while peek().is_valid_int():
				advance()
			add_token(TokenType.FLOAT, float(source.substr(start, current - start)))
		else:
			add_token(TokenType.INTEGER, int(source.substr(start, current - start)))
	
	## 扫描标识符或关键字
	func identifier():
		while peek().is_valid_identifier() or peek().is_valid_int():
			advance()
		var text = source.substr(start, current - start)
		var type = keywords.get(text, TokenType.IDENTIFIER)
		if type == TokenType.TRUE:
			add_token(type, true)
		elif type == TokenType.FALSE:
			add_token(type, false)
		elif type == TokenType.NULL:
			add_token(type, null)
		else:
			add_token(type, text)

## AST 节点
class ASTNode:
	pass

## Statements 声明基类
class Stmt:
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
		object = o;
		index = i

## 索引赋值表达式, 例如 arr[idx] = value [br]
## 对容器对象的指定下标位置设置值
class SetItem extends Expr:
	## 对象表达式
	var object: Expr
	## 索引表达式
	var index: Expr
	## 待赋值的表达式
	var value: Expr
	## 构造索引赋值表达式 [br]
	## [param o] 对象表达式 [br]
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
	## 对象表达式
	var object: Expr
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
	
	## 构造函数调用表达式 [br]
	## [param c] 被调用的表达式 [br]
	## [param a] 位置参数列表 [br]
	## [param kw] 关键字参数列表
	func _init(c, a, kw = []):
		callee_expr = c
		arguments = a
		keyword_args = kw

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
## 创建包含键值对的字典
class DictLiteral extends Expr:
	## 键表达式数组
	var keys: Array
	## 值表达式数组
	var values: Array
	## 构造字典字面量 [br]
	## [param k] 键表达式数组 (实际类型 Array[Expr]) [br]
	## [param v] 值表达式数组 (实际类型 Array[Expr])
	func _init(k, v):
		keys = k
		values = v

## 列表推导式, 例如 [x for x in iterable if cond] [br]
## 通过对迭代对象中满足条件的每个元素计算表达式来生成列表
class ListComp extends Expr:
	## 元素表达式
	var elt_expr: Expr
	## 循环变量名
	var var_name: String
	## 迭代对象表达式
	var iterable: Expr
	## 过滤条件表达式, 可为 null
	var condition: Expr
	## 构造列表推导式 [br]
	## [param e] 元素表达式 [br]
	## [param v] 循环变量名 [br]
	## [param i] 迭代对象表达式 [br]
	## [param c] 过滤条件表达式, 可为 null
	func _init(e, v, i, c):
		elt_expr = e
		var_name = v
		iterable = i
		condition = c

## 字典推导式, 例如 {k: v for k, v in iterable if cond} [br]
## 通过对迭代对象中满足条件的每个键值对计算表达式来生成字典
class DictComp extends Expr:
	## 键表达式
	var key_expr: Expr
	## 值表达式
	var value_expr: Expr
	## 键变量名
	var k_var: String
	## 值变量名
	var v_var: String
	## 迭代对象表达式
	var iterable: Expr
	## 过滤条件表达式, 可为 null
	var condition: Expr
	## 构造字典推导式 [br]
	## [param k] 键表达式 [br]
	## [param v] 值表达式 [br]
	## [param kv] 键变量名 [br]
	## [param vv] 值变量名 [br]
	## [param i] 迭代对象表达式 [br]
	## [param c] 过滤条件表达式, 可为 null
	func _init(k, v, kv, vv, i, c):
		key_expr = k
		value_expr = v
		k_var = kv
		v_var = vv
		iterable = i
		condition = c

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
	## [param c] 循环条件表达式
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

## del 删除语句, 例如 del obj.attr 或 del arr[idx] [br]
## 删除对象的属性或容器中的元素
class DelStmt extends Stmt:
	## 删除目标表达式列表
	var targets: Array[Expr]
	## 构造 del 语句 [br]
	## [param t] 删除目标表达式列表
	func _init(t):
		targets = t

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
	## [param n] 参数名
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
		
	func magic_eq(args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLBool:
		if len(args) == 2:
			return DSLBool.new(args[0] == args[1])
		if len(args) == 1:
			return DSLBool.new(self == args[0])
		return null
		
	func magic_ne(args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLBool:
		if len(args) == 2:
			return DSLBool.new(args[0] != args[1])
		if len(args) == 1:
			return DSLBool.new(not (self == args[0]))
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
		last_error = "TypeError: '%s' object is not a container" % [_type_name()]
		return null
	
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
	
	func _dsl_bool() -> bool:
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
		var s = "slice("
		if start != null:
			s += start._dsl_str()
		s += ", "
		if stop != null:
			s += stop._dsl_str()
		s += ", "
		if step != null:
			s += step._dsl_str()
		s += ")"
		return s

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
		var a = self_obj._promote(other); if a[0] == null:
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
		if args.size() != 3:
			last_error = "TypeError: replace() takes exactly two arguments"
			return null
		return DSLString.new(raw.value.replace(args[1]._dsl_str(), args[2]._dsl_str()))
	
	func builtin_find(args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLObject:
		var obj = args[0]
		var raw = DSLObject._unwrap_dsl(obj)
		if args.size() != 2:
			last_error = "TypeError: find() takes exactly one argument"
			return null
		return DSLInteger.new(raw.value.find(args[1]._dsl_str()))
	
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
		var obj = args[0]; var raw = DSLObject._unwrap_dsl(obj); var s = raw.value
		if args.size() >= 2:
			var chars = args[1]._dsl_str()
			var start = 0
			while start < s.length() and chars.find(s[start]) != -1: start += 1
			return DSLString.new(s.substr(start))
		return DSLString.new(s.lstrip(" \t\n\r"))
	
	func builtin_rstrip(args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLObject:
		var obj = args[0]
		var raw = DSLObject._unwrap_dsl(obj)
		var s = raw.value
		if args.size() >= 2:
			var chars = args[1]._dsl_str()
			var end = s.length() - 1
			while end >= 0 and chars.find(s[end]) != -1: end -= 1
			return DSLString.new(s.substr(0, end + 1))
		return DSLString.new(s.rstrip(" \t\n\r"))
	
	func builtin_capitalize(args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLObject:
		var s = DSLObject._unwrap_dsl(args[0]).value
		if s.length() == 0: return DSLString.new("")
		return DSLString.new(s[0].to_upper() + s.substr(1).to_lower())
	
	func builtin_casefold(args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLObject:
		return DSLString.new(DSLObject._unwrap_dsl(args[0]).value.to_lower())
	
	func builtin_title(args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLObject:
		var raw = DSLObject._unwrap_dsl(args[0]).value; var r = ""; var iw = false
		for i in range(raw.length()):
			var ch = raw[i]
			if ch.is_valid_int() or (ch >= 'a' and ch <= 'z') or (ch >= 'A' and ch <= 'Z'):
				if not iw: r += ch.to_upper(); iw = true
				else: r += ch.to_lower()
			else: r += ch; iw = false
		return DSLString.new(r)
	
	func builtin_swapcase(args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLObject:
		var raw = DSLObject._unwrap_dsl(args[0]).value; var r = ""
		for i in range(raw.length()):
			var ch = raw[i]
			if ch >= 'a' and ch <= 'z': r += ch.to_upper()
			elif ch >= 'A' and ch <= 'Z': r += ch.to_lower()
			else: r += ch
		return DSLString.new(r)
	
	func builtin_count(args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLObject:
		var obj = args[0]; var raw = DSLObject._unwrap_dsl(obj)
		if args.size() < 2: raw.last_error = "TypeError: count() takes at least 1 argument"; return null
		var sub = args[1]._dsl_str(); var sv = raw.value; var si = 0; var ei = sv.length()
		if args.size() >= 3 and args[2] is DSLInteger:
			si = args[2].value
			if si < 0:
				si = max(0, si + sv.length())
		if args.size() >= 4 and args[3] is DSLInteger:
			ei = args[3].value
			if ei < 0:
				ei = max(0, ei + sv.length())
			ei = min(ei, sv.length())
		sv = sv.substr(si, ei - si); var cnt = 0; var pos = 0
		while true:
			pos = sv.find(sub, pos)
			if pos == -1:
				break
			cnt += 1
			pos += sub.length()
		return DSLInteger.new(cnt)
	
	func builtin_isdigit(args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLObject:
		var raw = DSLObject._unwrap_dsl(args[0]).value
		if raw.length() == 0: return DSLBool.new(false)
		for ch in raw: if not ch.is_valid_int(): return DSLBool.new(false)
		return DSLBool.new(true)
	
	func builtin_isalpha(args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLObject:
		var raw = DSLObject._unwrap_dsl(args[0]).value
		if raw.length() == 0: return DSLBool.new(false)
		for ch in raw: if not ((ch >= 'a' and ch <= 'z') or (ch >= 'A' and ch <= 'Z')): return DSLBool.new(false)
		return DSLBool.new(true)
	
	func builtin_isalnum(args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLObject:
		var raw = DSLObject._unwrap_dsl(args[0]).value
		if raw.length() == 0: return DSLBool.new(false)
		for ch in raw: if not (ch.is_valid_int() or (ch >= 'a' and ch <= 'z') or (ch >= 'A' and ch <= 'Z')): return DSLBool.new(false)
		return DSLBool.new(true)
	
	func builtin_isspace(args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLObject:
		var raw = DSLObject._unwrap_dsl(args[0]).value
		if raw.length() == 0: return DSLBool.new(false)
		for ch in raw: if not (ch == ' ' or ch == '\t' or ch == '\n' or ch == '\r'): return DSLBool.new(false)
		return DSLBool.new(true)
	
	func builtin_islower(args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLObject:
		var raw = DSLObject._unwrap_dsl(args[0]).value; var ha = false
		for ch in raw:
			if (ch >= 'a' and ch <= 'z') or (ch >= 'A' and ch <= 'Z'): ha = true; if ch >= 'A' and ch <= 'Z': return DSLBool.new(false)
		return DSLBool.new(ha)
	
	func builtin_isupper(args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLObject:
		var raw = DSLObject._unwrap_dsl(args[0]).value; var ha = false
		for ch in raw:
			if (ch >= 'a' and ch <= 'z') or (ch >= 'A' and ch <= 'Z'): ha = true; if ch >= 'a' and ch <= 'z': return DSLBool.new(false)
		return DSLBool.new(ha)
	
	func builtin_istitle(args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLObject:
		var raw = DSLObject._unwrap_dsl(args[0]).value; var ha = false; var iw = false
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
		var obj = args[0]; var raw = DSLObject._unwrap_dsl(obj)
		if args.size() < 2: raw.last_error = "TypeError: center() takes at least 1 argument"; return null
		var s = raw.value; var width = 0
		if args[1] is DSLInteger: width = args[1].value
		var fill = " "
		if args.size() >= 3 and args[2] is DSLString:
			fill = args[2].value
			if fill.length() == 0:
				fill = " "
		if s.length() >= width: return DSLString.new(s)
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
		var obj = args[0]; var raw = DSLObject._unwrap_dsl(obj)
		if args.size() < 2: raw.last_error = "TypeError: ljust() takes at least 1 argument"; return null
		var s = raw.value; var width = 0
		if args[1] is DSLInteger: width = args[1].value
		var fill = " "; if args.size() >= 3 and args[2] is DSLString: fill = args[2].value; if fill.length() == 0: fill = " "
		if s.length() >= width: return DSLString.new(s)
		var r = s; while r.length() < width: r += fill[0]
		return DSLString.new(r)
	
	func builtin_rjust(args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLObject:
		var obj = args[0]; var raw = DSLObject._unwrap_dsl(obj)
		if args.size() < 2: raw.last_error = "TypeError: rjust() takes at least 1 argument"; return null
		var s = raw.value; var width = 0
		if args[1] is DSLInteger: width = args[1].value
		var fill = " "; if args.size() >= 3 and args[2] is DSLString: fill = args[2].value; if fill.length() == 0: fill = " "
		if s.length() >= width: return DSLString.new(s)
		var r = s; while r.length() < width: r = fill[0] + r
		return DSLString.new(r)
	
	func builtin_zfill(args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLObject:
		var obj = args[0]; var raw = DSLObject._unwrap_dsl(obj)
		if args.size() < 2: raw.last_error = "TypeError: zfill() takes exactly 1 argument"; return null
		var s = raw.value; var width = 0
		if args[1] is DSLInteger: width = args[1].value
		if s.length() >= width: return DSLString.new(s)
		var r = s; while r.length() < width: r = "0" + r
		return DSLString.new(r)
	
	func builtin_rsplit(args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLObject:
		var obj = args[0]; var raw = DSLObject._unwrap_dsl(obj); var s = raw.value
		var sep = ""; var maxsplit = -1; var use_default = false
		if args.size() >= 2 and not args[1] is DSLNone: sep = args[1]._dsl_str()
		else: use_default = true
		if args.size() >= 3 and args[2] is DSLInteger: maxsplit = args[2].value
		var result = DSLList.new()
		if use_default:
			var words = s.strip_edges().split(" ", false); var wf = []
			for w in words: if w != "": wf.append(w)
			if maxsplit >= 0 and wf.size() > maxsplit + 1:
				var rm = ""; for i in range(maxsplit, wf.size()): if i > maxsplit: rm += " "; rm += wf[i]
				wf = wf.slice(0, maxsplit); wf.append(rm)
			wf.reverse()
			for w in wf: result.items.append(DSLString.new(w))
		else:
			var parts = []; var remaining = s; var cnt = 0
			while remaining.length() > 0:
				if maxsplit >= 0 and cnt >= maxsplit: parts.append(remaining); break
				var pos = remaining.rfind(sep)
				if pos == -1: parts.append(remaining); break
				parts.append(remaining.substr(pos + sep.length()))
				remaining = remaining.substr(0, pos); cnt += 1
			parts.reverse()
			for p in parts: result.items.append(DSLString.new(p))
		return result
	
	func builtin_format(args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLObject:
		var obj = args[0]; var raw = DSLObject._unwrap_dsl(obj)
		var template = raw.value
		var fmt_args = args.slice(1)
		var result = ""
		var auto_idx = 0
		var i = 0
		while i < template.length():
			if template[i] == '{' and i + 1 < template.length() and template[i + 1] == '}':
				var idx = auto_idx
				if idx < fmt_args.size():
					result += fmt_args[idx]._dsl_str()
				auto_idx += 1
				i += 2
				continue
			if template[i] == '{':
				var j = i + 1
				while j < template.length() and template[j] != '}':
					j += 1
				if j < template.length():
					var idx_str = template.substr(i + 1, j - i - 1)
					var idx = int(idx_str)
					if idx >= 0 and idx < fmt_args.size():
						result += fmt_args[idx]._dsl_str()
					i = j + 1
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
	
## DSL 列表类型, 对应 Python list
class DSLList extends DSLObject:
	## 列表元素数组
	var items: Array[DSLObject]
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
		return "list"
	
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
			s += "'" + items[i].value + "'" if items[i] is DSLString else items[i]._dsl_str()
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
			if key_func is DSLFunction or key_func is DSLBuiltinFunction or (key_func is DSLClass and key_func._lookup_method("__call__") != null):
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
				return "(" + ("'" + items[0].value + "'" if items[0] is DSLString else items[0]._dsl_str()) + ",)"
			_:
				var s = ""
				for i in range(items.size()):
					if i > 0:
						s += ", "
					s += "'" + items[i].value + "'" if items[i] is DSLString else items[i]._dsl_str()
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
	
	func magic_getitem(args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLObject:
		var self_obj = args[0]
		var key = args[1]
		var vkey = _key_to_variant(key)
		if vkey == null:
			return null
		if self_obj.dict.has(vkey):
			return self_obj.dict[vkey]
		self_obj.last_error = "KeyError: " + key._dsl_str()
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
			s += "'" + key_obj.value + "'" if key_obj is DSLString else key_obj._dsl_str()
			s += ": "
			s += "'" + dict[k].value + "'" if dict[k] is DSLString else dict[k]._dsl_str()
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
			last_error = "KeyError: " + key._dsl_str()
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
			last_error = "KeyError: " + key._dsl_str()
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
		var obj = args[0]; var raw = DSLObject._unwrap_dsl(obj)
		if args.size() < 2: raw.last_error = "TypeError: setdefault() takes at least 1 argument"; return null
		var dsl_key = args[1]
		var vkey = _key_to_variant(dsl_key)
		if vkey == null: return null
		if raw.dict.has(vkey): return raw.dict[vkey]
		var default_val = DSLNone.new()
		if args.size() >= 3: default_val = args[2]
		raw.dict[vkey] = default_val
		return default_val
	
	func builtin_popitem(args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLObject:
		var obj = args[0]; var raw = DSLObject._unwrap_dsl(obj)
		if raw.dict.size() == 0: raw.last_error = "KeyError: 'popitem(): dictionary is empty'"; return null
		var keys = raw.dict.keys(); var raw_key = keys[keys.size() - 1]
		var value = raw.dict[raw_key]; raw.dict.erase(raw_key)
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
	
	func _dsl_str() -> String:
		return "dict_keys(" + _list_repr() + ")"
	
	## 内部列表表示 [br]
	## [returns] "[k1, k2, ...]" 格式
	func _list_repr() -> String:
		var s = ""
		for i in range(keys_list.size()):
			if i > 0:
				s += ", "
			var item = keys_list[i]
			s += "'" + item.value + "'" if item is DSLString else item._dsl_str()
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
	
	func _dsl_str() -> String:
		return "dict_values(" + _list_repr() + ")"
	
	## 生成值的列表表示字符串 [br]
	## [returns] "[v1, v2, ...]" 格式
	func _list_repr() -> String:
		var s = ""
		for i in range(values_list.size()):
			if i > 0:
				s += ", "
			var item = values_list[i]
			s += "'" + item.value + "'" if item is DSLString else item._dsl_str()
		return "[" + s + "]"
 
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
			for e in v: lst.items.append(_wrap_static(e))
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

## DSL 迭代器基类, 对应 Python 迭代器协议 (鸭子类型) [br]
## DSLIterator 从未暴露, 无需继承自 DSLObject [br]
## 提供 has_next() / next() 接口的子类可 for 循环使用
class DSLIterator:
	## 检查是否还有下一个元素 [br]
	## [returns] 还有元素时返回 true
	func has_next() -> bool:
		return false
	
	## 获取下一个元素 [br]
	## [returns] 下一个元素 (DSLObject)
	func next() -> DSLObject:
		return null

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
	## 这是所有顶层语法结构的入口分发函数 [br]
	## [returns] 解析出的 Stmt 或 Expr 节点, 末尾或出错时返回 null
	func declaration():
		skip_newlines()
		if is_at_end():
			return null
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
		return expression_statement()
		
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
				if report.has_error: break
				
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
			targets.append(target)
			if not match_types([TokenType.COMMA]):
				break
		skip_newlines()
		return DelStmt.new(targets)
		
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
			var false_expr = conditional_expression()  # 递归, 实现右结合
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
		
	## 解析基本表达式 (字面量, 变量, 括号组, 列表, 字典) [br]
	## 所有基本表达式解析后都会通过 finish_call_or_index 进行后缀链式处理 [br]
	## [returns] 解析出的 Expr 节点
	func primary():
		if match_types([TokenType.INTEGER, TokenType.FLOAT, TokenType.STRING, TokenType.TRUE, TokenType.FALSE, TokenType.NULL]):
			return finish_call_or_index(Literal.new(previous().literal))
		if match_types([TokenType.IDENTIFIER]):
			return finish_call_or_index(Variable.new(previous().lexeme))
		if match_types([TokenType.LPAREN]):
			return finish_call_or_index(parse_group_or_generator())
		if match_types([TokenType.LBRACKET]):
			return finish_call_or_index(parse_list_or_listcomp())
		if match_types([TokenType.LBRACE]):
			return finish_call_or_index(parse_dict_or_dictcomp())
		report.error("Unexpected token '%s'" % peek().lexeme)
		return null
		
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
				if not check(TokenType.RPAREN):
					var arg_data = arguments()
					if report.has_error:
						return null
					args = arg_data[0]
					kw_args = arg_data[1]
				var rparen = consume(TokenType.RPAREN, "Expected ')'")
				if rparen == null:
					return null
				expr = Call.new(expr, args, kw_args)
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
		
	## 解析函数调用中的实参列表, 返回表达式数[pos_args, keyword_args]
	## 解析函数调用中的实参列表 [br]
	## 区分位置参数和关键字参数, 并检测位置参数跟在关键字参数之后的语法错误 [br]
	## [returns] 包含两个数组的数组: [[Expr, ...], [KeywordArg, ...]]
	func arguments() -> Array[Array]:
		var pos_args: Array[Expr] = []
		var kw_args: Array[KeywordArg] = []
		var saw_keyword = false
		
		# 解析第一个参数
		if not check(TokenType.RPAREN):
			while true:
				if report.has_error:
					break
				# 尝试解析一个表达式
				var expr = simple_expression()
				if match_types([TokenType.EQUAL]):
					# 这是一个关键字参数, 要求 expr 必须Variable
					if not expr is Variable:
						report.error("Invalid keyword argument name")
						return [pos_args, kw_args]
					else:
						var value = simple_expression()
						kw_args.append(KeywordArg.new(expr.name, value))
						saw_keyword = true
				else:
					if saw_keyword:
						report.error("SyntaxError: positional argument follows keyword argument")
						return [pos_args, kw_args]
					# 普通位置参数
					pos_args.append(expr)
					
				if not match_types([TokenType.COMMA]):
					break
				skip_newlines()
		return [pos_args, kw_args]
		
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
		if match_types([TokenType.FOR]):
			if first is TupleLiteral:
				report.error("SyntaxError: invalid syntax")
				return null
				
			var var_tok = consume(TokenType.IDENTIFIER, "Expected variable")
			if var_tok == null:
				return null
			var var_name = var_tok.lexeme
			var in_tok = consume(TokenType.IN, "Expected 'in'")
			if in_tok == null:
				return null
			
			var iterable = or_expr()
			if report.has_error:
				return null
			var condition = null
			if match_types([TokenType.IF]):
				condition = simple_expression()
				if report.has_error:
					return null
			var rparen = consume(TokenType.RPAREN, "Expected ')'")
			if rparen == null:
				return null
			return ListComp.new(first, var_name, iterable, condition)
		else:
			# 不是生成器 则按普通圆括号结束
			var rparen = consume(TokenType.RPAREN, "Expected ')'")
			if rparen == null:
				return null
		# 返回 first, 可能TupleLiteral ((1, 2)) 或单个表达式 (仅分 (x))
		return first
			
	## 解析列表字面量或列表推导式 [br]
	## 空方括号返回空列表, 有 for 则解析为列表推导式, 否则解析普通列表 [br]
	## [returns] 解析出的 ListLiteral 或 ListComp 节点
	func parse_list_or_listcomp():
		if check(TokenType.RBRACKET):
			advance()
			return ListLiteral.new([])
			
		var first = simple_expression()
		if report.has_error:
			return null
			
		if match_types([TokenType.FOR]):
			var var_tok = consume(TokenType.IDENTIFIER, "Expected variable")
			if var_tok == null:
				return null
			var var_name = var_tok.lexeme
			var in_tok = consume(TokenType.IN, "Expected 'in'")
			if in_tok == null:
				return null
				
			var iterable = or_expr()
			if report.has_error:
				return null
			var condition = null
			if match_types([TokenType.IF]):
				condition = simple_expression()
				if report.has_error:
					return null
			var rbracket = consume(TokenType.RBRACKET, "Expected ']'")
			if rbracket == null:
				return null
			return ListComp.new(first, var_name, iterable, condition)
		else:
			var elems = [first]
			while match_types([TokenType.COMMA]):
				if check(TokenType.RBRACKET):
					break
				var elem = simple_expression()
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
			
		var key_expr = simple_expression()
		if report.has_error:
			return null
		var colon = consume(TokenType.COLON, "Expected ':'")
		if colon == null:
			return null
		var value_expr = simple_expression()
		if report.has_error:
			return null
			
		if match_types([TokenType.FOR]):
			var k_tok = consume(TokenType.IDENTIFIER, "Expected key variable")
			if k_tok == null:
				return null
			var k_var = k_tok.lexeme
			var v_var = ""
			if match_types([TokenType.COMMA]):
				var v_tok = consume(TokenType.IDENTIFIER, "Expected value variable")
				if v_tok == null:
					return null
				v_var = v_tok.lexeme
				
			var in_tok = consume(TokenType.IN, "Expected 'in'")
			if in_tok == null:
				return null
			var iterable = or_expr()
			if report.has_error:
				return null
			var condition = null
			if match_types([TokenType.IF]):
				condition = simple_expression()
				if report.has_error:
					return null
			var rbrace = consume(TokenType.RBRACE, "Expected '}'")
			if rbrace == null:
				return null
			return DictComp.new(key_expr, value_expr, k_var, v_var, iterable, condition)
		else:
			var keys = [key_expr]
			var values = [value_expr]
			while match_types([TokenType.COMMA]):
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
			var rbrace = consume(TokenType.RBRACE, "Expected '}'")
			if rbrace == null:
				return null
			return DictLiteral.new(keys, values)
	
	## 解析一个解包目标 (变量, 括号嵌套, 或星号前缀) [br]
	## 支持 Variable, UnpackTarget (括号/方括号嵌套) 和 StarredTarget (星号前缀) [br]
	## [returns] 解析出的 Variable, UnpackTarget 或 StarredTarget 节点
	func parse_target():
		if match_types([TokenType.STAR]):
			if not check(TokenType.IDENTIFIER):
				report.error("Expected identifier after '*'")
				return null
			var var_name = advance().lexeme
			return StarredTarget.new(Variable.new(var_name))
		if match_types([TokenType.IDENTIFIER]):
			return Variable.new(previous().lexeme)
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
	
	## 表达式入口 (无逗号, 无赋值, 用于列表元素, 字典键值, 函数实参, 索引, 条件表达式等) [br]
	## 直接委托给 conditional_expression, 确保从三目表达式开始解析 [br]
	## [returns] 解析出的 Expr 节点
	func simple_expression() -> Expr:
		return conditional_expression()
		
	## 元组表达式 (允许逗号序列), 用于顶层表达式语句, 赋值右侧, return 之后 [br]
	## 如果遇到逗号, 则将多个表达式打包为 TupleLiteral [br]
	## [returns] 解析出的 Expr 节点 (可能是 TupleLiteral), 出错时返回 null
	func tuple_expression() -> Expr:
		var first = simple_expression()
		if first == null or report.has_error:
			return null
		if match_types([TokenType.COMMA]):
			var elements = [first]
			while not check(TokenType.NEWLINE) and not check(TokenType.EOF) and not check(TokenType.RPAREN) and not check(TokenType.RBRACKET) and not check(TokenType.RBRACE):
				var elem = simple_expression()
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
		
		# 增强赋 x += 1, x -= 2, x *= 3, x /= 4, x //= 5, x **= 6, x %= 7
		if match_types([TokenType.PLUS_EQ, TokenType.MINUS_EQ, TokenType.STAR_EQ, TokenType.SLASH_EQ, TokenType.DOUBLESLASH_EQ, TokenType.STARSTAR_EQ, TokenType.PERCENT_EQ]):
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
		var depth = 0   # 括号嵌套深度
		
		while idx < tokens.size():
			var t = tokens[idx]
			
			# 换行处理
			if t.type == TokenType.NEWLINE:
				if depth == 0:
					return false
				idx += 1
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
				
			# 逗号 (深度内也需重置has_target)
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
	## 控制台报告器
	var report: ConsoleReport
	## 执行结果枚举, 用于控制流程跳转
	enum ExecResult {NORMAL, RETURN, BREAK, CONTINUE, ERROR, RAISE}
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
	
	## 构造解释器实例 [br]
	## [param p_reporter] 控制台报告器 [br]
	## [param p_api] 外部 API 函数注册
	func _init(p_reporter: ConsoleReport, p_api: Dictionary[String, Callable] = {}):
		report = p_reporter
		api_funcs = p_api
		globals = DSLEnvironment.new(report)
		environment = globals
		register_builtins()
	
	## 抛出 DSL 异常, 设置 last_exception 并报告错误
	func raise_exception(err_type: String, msg: String):
		var exc_class = globals.get_val(err_type)
		if exc_class is DSLClass:
			var exc_args: Array[DSLObject] = [DSLString.new(msg)]
			last_exception = exc_class.magic_call(exc_args, {})
		else:
			last_exception = DSLException.new(msg, err_type)
		report.error(err_type + ": " + msg)
	
	## 尝试调用实例类的 magic 方法, 失败时回退 fallback [br]
	## [param obj] 目标对象 [br]
	## [param method_name] magic 方法名称 [br]
	## [param extra_args] 额外参数 [br]
	## [param fallback] 回退回调, 返回 DSLObject
	func _call_magic_or_fallback(obj: DSLObject, method_name: String, extra_args: Array[DSLObject], fallback: Callable) -> DSLObject:
		if obj.klass != null:
			var method: Variant = obj._dsl_getattribute(method_name)
			if method != null and not (method is DSLNone):
				var all_args: Array[DSLObject] = []
				all_args.append_array(extra_args)
				var result = obj.klass._invoke_func(method, all_args, {} as Dictionary[String, DSLObject])
				if result != null:
					return result
			var class_method = obj.klass._lookup_method(method_name)
			if class_method != null:
				if class_method.has_method("__get__"):
					class_method = class_method.__get__(obj, obj.klass)
				var all_args: Array[DSLObject] = []
				all_args.append_array(extra_args)
				var result = obj.klass._invoke_func(class_method, all_args, {} as Dictionary[String, DSLObject])
				if result != null:
					return result
		return fallback.call()
	
	## 从带格式 last_error 字符串中抛出异常
	## 解析 "TypeName: message" 格式的错误字符串并抛出对应异常 [br]
	## [param last_err] 格式为 "TypeName: message" 的错误字符串
	func raise_exception_from_last_error(last_err: String):
		var colon_idx = last_err.find(": ")
		if colon_idx != -1:
			raise_exception(last_err.substr(0, colon_idx), last_err.substr(colon_idx + 2))
		else:
			raise_exception("RuntimeError", last_err)
	
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
		
		var class_obj = DSLClass.new(type_name, base_class, methods, self)
		globals.define(type_name, class_obj)
		exception_hierarchy[type_name] = base_name
	
	## 增强赋值计算, 根据运算符对 left/right 执行相应 dsl_* 操作
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
		var msg = ""
		if pos_args.size() > 0:
			msg = pos_args[0]._dsl_str()
		var exc = DSLException.new(msg, wrapper.klass.name, pos_args)
		wrapper._wrapped = exc
		wrapper.fields["args"] = DSLTuple.new(pos_args)
		return DSLNone.new()
	
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
		
	## 注册内置类型, 函数与异常到全局作用域 [br]
	## 创建 object/type/int/float/str/list/tuple/dict/bool 类型类, [br]
	## 注入对应魔术方法描述符与内置方法, [br]
	## 注册内置函数 (print/len/range/type/id 等) 及 API 函数, [br]
	## 定义内置异常继承层级
	func register_builtins():
		# === Programmatic built-in type class registration ===
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
		
		globals.define("len", _make_builtin("len", Callable(self, "builtin_len")))
		globals.define("range", _make_builtin("range", Callable(self, "builtin_range")))
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
		_define_exception("AssertionError")
		_define_exception("EOFError")
		
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
		
	## 在给定环境中执行语句块并捕获 return/break/continue 信号 [br]
	## [param statements] 语句数组 [br]
	## [param env] 要使用的环境
	func exec_block(statements: Array, env: DSLEnvironment) -> ExecResult:
		var prev_env = environment
		environment = env
		for stmt in statements:
			if report.has_error:
				environment = prev_env
				if last_exception != null:
					return ExecResult.RAISE
				return ExecResult.ERROR
			var res = execute(stmt)
			if res == ExecResult.ERROR and last_exception != null:
				res = ExecResult.RAISE
			if res != ExecResult.NORMAL:
				environment = prev_env
				return res
		environment = prev_env
		return ExecResult.NORMAL
		
	## 执行单条语句, 返回执行结果状态 [br]
	## [param stmt] 语句节点
	func execute(stmt) -> ExecResult:
		if report.has_error:
			return ExecResult.ERROR
			
		step_count += 1
		if step_count > max_steps:
			raise_exception("RuntimeError", "maximum step count exceeded")
			return ExecResult.RAISE
			
		if stmt is ExpressionStmt:
			var val = evaluate(stmt.expression)
			if val == null or report.has_error:
				return ExecResult.ERROR
			return ExecResult.NORMAL
			
		if stmt is IfStmt:
			var cond = evaluate(stmt.condition)
			if cond == null or report.has_error:
				return ExecResult.ERROR
			if cond._dsl_bool():
				return exec_block(stmt.then_branch, environment)
			else:
				for branch in stmt.elif_branches:
					cond = evaluate(branch[0])
					if cond == null or report.has_error:
						return ExecResult.ERROR
					if cond._dsl_bool():
						return exec_block(branch[1], environment)
				if stmt.else_branch.size() > 0:
					return exec_block(stmt.else_branch, environment)
			return ExecResult.NORMAL
		
		if stmt is WhileStmt:
			var did_break = false
			while true:
				var cond = evaluate(stmt.condition)
				if cond == null or report.has_error:
					return ExecResult.ERROR
				if not cond._dsl_bool():
					break
				var res = exec_block(stmt.body, environment)
				if res == ExecResult.BREAK:
					did_break = true
					break
				elif res == ExecResult.CONTINUE:
					continue
				elif res == ExecResult.ERROR or res == ExecResult.RETURN or res == ExecResult.RAISE:
					return res
			if not did_break and stmt.has_meta("_else_body"):
				var else_body = stmt.get_meta("_else_body")
				exec_block(else_body, DSLEnvironment.new(environment.report, environment))
			return ExecResult.NORMAL
			
		if stmt is ForStmt:
			var iterable = evaluate(stmt.iterable)
			if iterable == null or iterable is DSLNone:
				raise_exception("RuntimeError", "iterable is null in for loop")
				return ExecResult.RAISE
			var iterator = iterable._dsl_iter()
			if iterator == null:
				raise_exception_from_last_error(iterable.last_error if iterable.last_error else "TypeError: object is not iterable")
				return ExecResult.RAISE
			var did_break = false
			while iterator.has_next():
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
					for i in range(stmt.variables.size()):
						environment.set_val(stmt.variables[i], seq[i] if seq[i] is DSLObject else _wrap(seq[i]))
				var res = exec_block(stmt.body, environment)
				if res == ExecResult.BREAK:
					did_break = true
					break
				elif res == ExecResult.CONTINUE:
					continue
				elif res == ExecResult.RETURN or res == ExecResult.RAISE or res == ExecResult.ERROR:
					return res
			if not did_break and stmt.has_meta("_else_body"):
				var else_body = stmt.get_meta("_else_body")
				exec_block(else_body, DSLEnvironment.new(environment.report, environment))
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
					if obj == null:
						return ExecResult.ERROR
					obj._dsl_delattr(target.name)
					if obj.last_error != "":
						raise_exception_from_last_error(obj.last_error)
						return ExecResult.RAISE
				elif target is GetItem:
					var obj = evaluate(target.object)
					if obj == null:
						return ExecResult.ERROR
					var index = evaluate(target.index)
					if index == null:
						return ExecResult.ERROR
					obj._dsl_delitem(index)
					if obj.last_error != "":
						raise_exception_from_last_error(obj.last_error)
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
			var res = exec_block(stmt.try_body, environment)
			
			if res == ExecResult.RAISE:
				var caught = false
				for clause in stmt.except_clauses:
					if _is_exception_match(last_exception, clause.exception_type):
						report.clear_error()
						if clause.as_name != "":
							environment.define(clause.as_name, last_exception)
						res = exec_block(clause.body, environment)
						if res != ExecResult.RAISE:
							last_exception = null
							caught = true
						break
				if not caught:
					res = ExecResult.RAISE
			
			if stmt.finally_body.size() > 0:
				var saved_has_error = report.has_error
				report.has_error = false
				var fin_res = exec_block(stmt.finally_body, environment)
				report.has_error = saved_has_error or report.has_error
				if fin_res != ExecResult.NORMAL:
					return fin_res
			
			return res
			
		return ExecResult.NORMAL
	
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
			var nullflag = assign_from_targets(expr.targets, items, environment)
			return null if nullflag == null else val
			
		if expr is SetItem:
			var obj = evaluate(expr.object)
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
				raise_exception_from_last_error(obj.last_error)
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
			var left = evaluate(expr.left)
			var right = evaluate(expr.right)
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
			var callee = evaluate(expr.callee_expr)
			if callee == null:
				return null
			var pos_args: Array[DSLObject] = []
			for a in expr.arguments:
				var arg_val = evaluate(a)
				if arg_val == null:
					return null
				pos_args.append(arg_val)
			var kw_dict: Dictionary[String, DSLObject] = {}
			for kw in expr.keyword_args:
				var val = evaluate(kw.value)
				if val == null:
					return null
				kw_dict[kw.name] = val
			if callee is DSLMethod:
				return callee.magic_call(pos_args, kw_dict)
			elif callee is DSLFunction:
				return call_user_function(callee, pos_args, kw_dict)
			elif callee is DSLClass:
				return callee.magic_call(pos_args, kw_dict)
			else:
				var result = callee.magic_call(pos_args, kw_dict)
				if report.has_error:
					return null
				# Check for errors from builtin methods (which set last_error on the proto)
				if callee is DSLBuiltinFunction:
					var proto = callee.callback.get_object()
					if proto is DSLObject and proto.last_error != "":
						raise_exception_from_last_error(proto.last_error)
						proto.last_error = ""
						return null
				return result
			
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
					raise_exception_from_last_error(obj.last_error)
					return null
				return result
			else:
				var idx = evaluate(expr.index)
				if idx == null:
					return null
				var result = obj._dsl_getitem(idx)
				if result == null:
					raise_exception_from_last_error(obj.last_error)
					return null
				return result
			
		if expr is GetAttr:
			var obj = evaluate(expr.object)
			if obj == null:
				return null
			var result = obj._dsl_getattribute(expr.name)
			if obj.last_error != "":
				raise_exception_from_last_error(obj.last_error)
				return null
			return result
		
		if expr is SetAttr:
			var obj = evaluate(expr.object)
			if obj == null:
				return null
			var val = evaluate(expr.value)
			if val == null:
				return null
			obj._dsl_setattr(expr.name, val)
			if obj.last_error != "":
				raise_exception_from_last_error(obj.last_error)
				return null
			return val
			
		if expr is ListLiteral:
			var lst = DSLList.new()
			for e in expr.elements:
				var element = evaluate(e)
				if element == null:
					return null
				lst.items.append(element)
			return lst
			
		if expr is TupleLiteral:
			var tup = DSLTuple.new()
			for e in expr.elements:
				var element = evaluate(e)
				if element == null:
					return null
				tup.items.append(element)
			return tup
			
		if expr is DictLiteral:
			var d = DSLDict.new()
			for i in range(expr.keys.size()):
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
			
		if expr is ListComp:
			var iterable = evaluate(expr.iterable)
			if iterable == null:
				return null
			var iterator = iterable._dsl_iter()
			if iterator == null:
				raise_exception_from_last_error(iterable.last_error if iterable.last_error != "" else "TypeError: object is not iterable")
				return null
			var result = DSLList.new()
			while iterator.has_next():
				if report.has_error:
					return null
				var item = iterator.next()
				var old = environment.values.get(expr.var_name)
				environment.define(expr.var_name, item)
				var cond_result = null
				if expr.condition != null:
					cond_result = evaluate(expr.condition)
					if cond_result == null:
						return null
				if expr.condition == null or cond_result._dsl_bool():
					var element = evaluate(expr.elt_expr)
					if element == null:
						return null
					result.items.append(element)
				if environment.values.has(expr.var_name):
					environment.values.erase(expr.var_name)
				if old != null:
					environment.define(expr.var_name, old)
			return result
			
		if expr is DictComp:
			var iterable = evaluate(expr.iterable)
			if iterable == null:
				return null
			var iterator = iterable._dsl_iter()
			if iterator == null:
				raise_exception_from_last_error(iterable.last_error if iterable.last_error else "TypeError: object is not iterable")
				return null
			var result = DSLDict.new()
			while iterator.has_next():
				if report.has_error:
					return null
				var item = iterator.next()
				environment.define(expr.k_var, item)
				if expr.v_var != "":
					var val = DSLNone.new()
					if iterable is DSLDict:
						val = iterable._dsl_getitem(item)
						if val == null:
							raise_exception_from_last_error(iterable.last_error if iterable.last_error else "KeyError during dict comprehension")
							return null
					environment.define(expr.v_var, val)
				var cond_result = null
				if expr.condition != null:
					cond_result = evaluate(expr.condition)
					if cond_result == null:
						return null
				if expr.condition == null or cond_result._dsl_bool():
					var key = evaluate(expr.key_expr)
					if key == null:
						return null
					var value = evaluate(expr.value_expr)
					if value == null:
						return null
					result._dsl_setitem(key, value)
					if result.last_error != "":
						raise_exception_from_last_error(result.last_error)
						return null
			return result
			
		return DSLNone.new()
		
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
			if p.is_kwargs: continue
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
				if kw_args.size() > 1: msg += "s"
				msg += ")"
			msg += " were given"
			raise_exception("TypeError", msg)
			return null
			
		var arg_idx = 0
		var param_idx = 0
		while param_idx < params.size() and arg_idx < args.size():
			var p = params[param_idx]
			if p.is_kwargs: break
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
				if p.is_kwargs: continue
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
				if default_val == null: return null
				local.define(p.name, default_val)
			else:
				if p.is_keyword_only:
					missing_kw.append(p.name)
				else:
					missing_pos.append(p.name)
					
		if missing_pos.size() > 0:
			var msg = "%s() missing %d required positional argument" % [decl.name, missing_pos.size()]
			if missing_pos.size() > 1: msg += "s"
			msg += ": "
			for i in range(missing_pos.size()):
				if i > 0:
					if i == missing_pos.size() - 1:
						msg += ", and " if missing_pos.size() > 2 else " and "
					else: msg += ", "
				msg += "'%s'" % missing_pos[i]
			raise_exception("TypeError", msg)
			return null
			
		if missing_kw.size() > 0:
			var msg = "%s() missing %d required keyword-only argument" % [decl.name, missing_kw.size()]
			if missing_kw.size() > 1: msg += "s"
			msg += ": "
			for i in range(missing_kw.size()):
				if i > 0:
					if i == missing_kw.size() - 1:
						msg += ", and " if missing_kw.size() > 2 else " and "
					else: msg += ", "
				msg += "'%s'" % missing_kw[i]
			raise_exception("TypeError", msg)
			return null
			
		for p in params:
			if p.is_args and not local.values.has(p.name):
				local.define(p.name, DSLTuple.new())
			if p.is_kwargs and not local.values.has(p.name):
				local.define(p.name, DSLDict.new())
				
		var prev_env = environment
		environment = local
		var res = exec_block(decl.body, environment)
		environment = prev_env
		
		if res == ExecResult.RETURN:
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
		for body_stmt in stmt.body:
			if body_stmt is FunctionStmt:
				if body_stmt.method_type == 3:
					# @property getter
					var func_obj = DSLFunction.new(body_stmt, environment)
					func_obj._cls_interp = self
					var prop = DSLProperty.new(body_stmt.name, func_obj, self)
					methods[body_stmt.name] = prop
				elif body_stmt.method_type == 4:
					# @name.setter
					var func_obj = DSLFunction.new(body_stmt, environment)
					func_obj._cls_interp = self
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
					methods[body_stmt.name] = func_obj
			elif body_stmt is ExpressionStmt and body_stmt.expression is Assign:
				var assign = body_stmt.expression as Assign
				var val = evaluate(assign.value)
				if val == null:
					return ExecResult.ERROR
				class_attrs[assign.name] = val
		var class_obj = DSLClass.new(stmt.name, superclass_obj, methods, self)
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
			return assign_from_targets(target.targets, inner_items, env)
		# StarredTarget 不会出现在这
		return DSLNone.new()
	
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
	
	## len(obj) - 返回对象的长度 [br]
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
		if obj is DSLTuple:
			return DSLInteger.new(obj.items.size())
		raise_exception("TypeError", "object of type '%s' has no len()" % obj._type_name())
		return null
		
	## range(start, stop, step) - 生成整数序列 [br]
	func builtin_range(args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLList:
		var start = 0
		var stop = 0
		var step = 1
		if args.size() == 1:
			stop = (args[0] as DSLInteger).value
		elif args.size() == 2:
			start = (args[0] as DSLInteger).value
			stop = (args[1] as DSLInteger).value
		elif args.size() == 3:
			start = (args[0] as DSLInteger).value
			stop = (args[1] as DSLInteger).value
			step = (args[2] as DSLInteger).value
		else:
			raise_exception("TypeError", "range expected at most 3 arguments, got %d" % args.size())
			return null
		var arr: Array[DSLObject] = []
		var i = start
		if step > 0:
			while i < stop:
				arr.append(DSLInteger.new(i))
				i += step
		else:
			while i > stop:
				arr.append(DSLInteger.new(i))
				i += step
		return DSLList.new(arr)
		
	## print(*args, sep, end) - 输出到控制台 [br]
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
	
	## info(*args) - 输出信息日志 [br]
	func builtin_info(args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLNone:
		var s = args[0]._dsl_str() if args.size() >= 1 else ""
		report.info(s)
		return DSLNone.new()
		
	## warn(*args) - 输出警告日志 [br]
	func builtin_warn(args: Array[DSLObject], kwargs: Dictionary[String, DSLObject]) -> DSLNone:
		return builtin_warning(args, kwargs)
		
	## warning(*args) - 输出警告日志 [br]
	func builtin_warning(args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLNone:
		var s = args[0]._dsl_str() if args.size() >= 1 else ""
		report.warn(s)
		return DSLNone.new()
		
	## error(*args) - 输出错误日志 [br]
	func builtin_error(args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLNone:
		var s = args[0]._dsl_str() if args.size() >= 1 else ""
		report.err(s)
		return DSLNone.new()
	
	## str(obj) - 转换为字符串 [br]
	func builtin_str(args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLString:
		if args.size() != 1:
			raise_exception("TypeError", "str() takes 1 argument")
			return null
		var obj = args[0]
		var result = obj.magic_str([obj] as Array[DSLObject], {} as Dictionary[String, DSLObject])
		if result is DSLString:
			return result
		return DSLString.new(obj._dsl_str())
	
	## repr(obj) - 返回对象的字符串表示 [br]
	func builtin_repr(args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLString:
		if args.size() != 1:
			raise_exception("TypeError", "repr() takes 1 argument")
			return null
		var obj = args[0]
		var res = obj.magic_repr([obj] as Array[DSLObject], {} as Dictionary[String, DSLObject])
		if res is DSLString:
			return res
		return DSLString.new("<" + obj._type_name() + " object>")
	
	## hash(obj) - 计算对象的哈希值 [br]
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
	
	## abs(x) - 返回绝对值 [br]
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
	
	## min(*args, key) - 返回最小值 [br]
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
			raise_exception("TypeError", "min() arg is not iterable")
			return null
		min_val = args[0]
		for i in range(1, args.size()):
			var cmp = min_val.magic_lt([min_val, args[i]] as Array[DSLObject], {} as Dictionary[String, DSLObject])
			if cmp is DSLBool and not cmp.value:
				min_val = args[i]
		return min_val
	
	## max(*args, key) - 返回最大值 [br]
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
			raise_exception("TypeError", "max() arg is not iterable")
			return null
		max_val = args[0]
		for i in range(1, args.size()):
			var cmp = max_val.magic_gt([max_val, args[i]] as Array[DSLObject], {} as Dictionary[String, DSLObject])
			if cmp is DSLBool and not cmp.value:
				max_val = args[i]
		return max_val
	
	## sum(iterable, start) - 求和 [br]
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
		raise_exception("TypeError", "sum() arg is not iterable")
		return null
	
	## pow(x, y, mod) - 幂运算 [br]
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
	
	## divmod(a, b) - 返回商和余数的元组 [br]
	func builtin_divmod(args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLTuple:
		if args.size() != 2:
			raise_exception("TypeError", "divmod() takes 2 arguments")
			return null
		var a = args[0]
		var b = args[1]
		var quot = a.magic_floordiv([a, b] as Array[DSLObject], {} as Dictionary[String, DSLObject])
		var rem = a.magic_mod([a, b] as Array[DSLObject], {} as Dictionary[String, DSLObject])
		return DSLTuple.new([quot, rem])
	
	## sorted(iterable, key, reverse) - 返回排序后的列表 [br]
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
		else:
			raise_exception("TypeError", "sorted() arg is not iterable")
			return null
		var reverse_val = false
		if _kwargs.has("reverse"):
			var rv = _kwargs["reverse"]
			if rv is DSLBool:
				reverse_val = rv.value
		if _kwargs.has("key"):
			var key_func = _kwargs["key"]
			if key_func is DSLFunction or key_func is DSLBuiltinFunction or (key_func is DSLClass and key_func._lookup_method("__call__") != null):
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
	
	## 升序比较函数, 用于 sorted [br]
	func _compare_asc(a: DSLObject, b: DSLObject) -> bool:
		var cmp = a.magic_lt([a, b] as Array[DSLObject], {} as Dictionary[String, DSLObject])
		if cmp is DSLBool:
			return cmp.value
		return false
	
	## 降序比较函数, 用于 sorted [br]
	func _compare_desc(a: DSLObject, b: DSLObject) -> bool:
		var cmp = a.magic_gt([a, b] as Array[DSLObject], {} as Dictionary[String, DSLObject])
		if cmp is DSLBool:
			return cmp.value
		return false
	
	## reversed(seq) - 返回反向迭代器 [br]
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
		raise_exception("TypeError", "reversed() arg is not iterable")
		return null
	
	## enumerate(iterable, start) - 返回枚举对象 [br]
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
		raise_exception("TypeError", "enumerate() arg is not iterable")
		return null
	
	## zip(*iterables) - 并行迭代 [br]
	func builtin_zip(args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLList:
		if args.size() == 0:
			return DSLList.new()
		var lists: Array[Array] = []
		var min_len = 999999
		for arg in args:
			var obj = arg
			if obj._wrapped != null:
				obj = obj._wrapped
			if obj is DSLList or obj is DSLTuple:
				lists.append(obj.items)
				if obj.items.size() < min_len:
					min_len = obj.items.size()
			else:
				raise_exception("TypeError", "zip() arg is not iterable")
				return null
		var result = DSLList.new()
		for i in range(min_len):
			var row: Array[DSLObject] = []
			for lst in lists:
				row.append(lst[i])
			result.items.append(DSLTuple.new(row))
		return result
	
	## any(iterable) - 任一元素为真则返回 True [br]
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
		return DSLBool.new(true)
	
	## all(iterable) - 所有元素为真则返回 True [br]
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
		return DSLBool.new(true)
	
	## ord(c) - 返回字符的 Unicode 码点 [br]
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
	
	## chr(i) - 返回 Unicode 码点对应的字符 [br]
	func builtin_chr(args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLString:
		if args.size() != 1:
			raise_exception("TypeError", "chr() takes 1 argument")
			return null
		var obj = args[0]
		if obj is DSLInteger:
			return DSLString.new(char(obj.value))
		raise_exception("TypeError", "chr() argument must be int")
		return null
	
	## 将整数转换为十六进制字符串 [br]
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
	
	## hex(x) - 转换为十六进制字符串 [br]
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
	
	## oct(x) - 转换为八进制字符串 [br]
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
	
	## bin(x) - 转换为二进制字符串 [br]
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
	
	## isinstance(obj, cls) - 检查类型 [br]
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
	
	## issubclass(cls, cls_or_tuple) - 检查继承关系 [br]
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
		
	## int(x, base) - 转换为整数 [br]
	func builtin_int(args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLInteger:
		if args.size() == 0:
			return DSLInteger.new(0)
		var arg = args[0]
		if arg is DSLInteger:
			return arg
		if arg is DSLFloat:
			return DSLInteger.new(int(arg.value))
		if arg is DSLString:
			return DSLInteger.new(int(arg.value))
		if arg is DSLBool:
			return DSLInteger.new(1 if arg.value else 0)
		return DSLInteger.new(0)
	
	## float(x) - 转换为浮点数 [br]
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
		
	## round(x, ndigits) - 四舍五入 [br]
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
			return DSLFloat.new(rounded)
		return DSLInteger.new(int(rounded))
		
	## input(prompt) - 读取用户输入 [br]
	func builtin_input(args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLObject:
		if args.size() > 0:
			var prompt = args[0]
			if prompt is DSLString:
				report.info(prompt.value)
				report.dsl.print_output += prompt.value
		raise_exception("EOFError", "EOF when reading a line")
		return null
		
	## callable(obj) - 检查对象是否可调用 [br]
	func builtin_callable(args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLObject:
		if args.size() == 0:
			raise_exception("TypeError", "callable() takes exactly one argument")
			return null
		var obj = args[0]
		if obj is DSLFunction:
			return DSLBool.new(true)
		if obj is DSLBuiltinFunction:
			return DSLBool.new(true)
		if obj is DSLClass:
			return DSLBool.new(true)
		if obj.klass != null:
			var method = obj.klass._lookup_method("__call__")
			if method != null:
				return DSLBool.new(true)
		return DSLBool.new(false)
	
	## iter(obj) - 返回迭代器 [br]
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
		var it_obj = DSLList.new(items)
		it_obj.iter_index = 0
		return it_obj
	
	## next(iter, default) - 获取迭代器的下一个元素 [br]
	func builtin_next(args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLObject:
		if args.size() < 1 or args.size() > 2:
			raise_exception("TypeError", "next() takes 1 or 2 arguments")
			return null
		var it = args[0]
		if not (it is DSLList):
			raise_exception("TypeError", "object is not an iterator")
			return null
		if it.iter_index < it.items.size():
			var result = it.items[it.iter_index]
			it.iter_index += 1
			return result
		if args.size() == 2:
			return args[1]
		raise_exception("StopIteration", "")
		return null
	
	## bool(x) - 转换为布尔值 [br]
	func builtin_bool(args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLBool:
		if args.size() == 0:
			return DSLBool.new(false)
		elif args.size() > 1:
			raise_exception("TypeError", "bool expected at most 1 argument, got %d" % args.size())
			return null
		return DSLBool.new(true if args[0]._dsl_bool() else false)
	
	## list(iterable) - 构造列表 [br]
	func builtin_list(args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLList:
		var lst = DSLList.new()
		if args.size() > 0:
			var it = args[0]._dsl_iter()
			if it == null:
				raise_exception("TypeError", "list() argument must be iterable")
				return null
			while it.has_next():
				lst.items.append(it.next())
		return lst
	
	## dict(iterable) - 构造字典 [br]
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
				if pair is DSLTuple and pair.items.size() == 2:
					var k = pair.items[0]
					var v = pair.items[1]
					var vkey = d._key_to_variant(k)
					if vkey != null:
						d.dict[vkey] = v
		return d
	
	## type(obj) - 返回对象的类型 [br]
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
			pass  # empty tuple, use object
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
	
	## id(obj) - 返回对象的唯一标识 [br]
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
			if args.size() > 2:
				raise_exception("TypeError", "int expected at most 1 argument, got %d" % (args.size() - 1))
				return null
			if args.size() >= 2:
				var arg = args[1]
				if arg is DSLInteger:
					return DSLInteger.new(arg.value)
				elif arg is DSLFloat:
					return DSLInteger.new(int(arg.value))
				elif arg is DSLString:
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
			return DSLTuple.new(arr)
		if args.size() >= 2 and not args[1] is DSLNone:
			var arg = args[1]
			if arg._wrapped != null:
				arg = arg._wrapped
			var it = arg._dsl_iter()
			if it != null:
				while it.has_next():
					arr.append(it.next())
		var result = DSLTuple.new(arr)
		result.klass = cls
		return result
	
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
## 累积的 print 输出文本
var print_output: String = ""
## 控制台输出文本 (日志/错误)
var console_output: String = ""
## 解析后的 AST 语句列表
var statements: Array = []
## 解释器实例
var interpreter: Interpreter = null
## 控制台报告器实例
var report: ConsoleReport = null
## 日志输出级别
var log_level: ConsoleReport.Level = ConsoleReport.Level.INFO
 
## 外部 API 函数注册 名称 -> Callable 的映射
var api_functions: Dictionary[String, Callable] = {}
 
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
	api_functions = api
 
## 解析 DSL 源代码为 AST [br]
## 经过词法分析 (Lexer) 和语法分析 (Parser), [br]
## 结果存入 [member statements] [br]
## [param source] DSL 源代码字符串
func write_dsl_script(source: String):
	if dsl_script != source:
		print_output = ""
		console_output = ""
		statements = []
		report = ConsoleReport.new(self, debug)
		# 尝试解析并执行
		var tokens = []
		var lexer = Lexer.new(report, source)
		tokens = lexer.scan()
		if not report.has_error:
			var parser = Parser.new(report, tokens)
			statements = parser.parse()
		if report.has_error:
			report.fatal_error(report.last_error)
 
## 执行已解析的 DSL 代码 [br]
## 创建解释器实例并运行所有 AST 语句
func run():
	if report.has_error:
		return
	interpreter = Interpreter.new(report, api_functions)
	interpreter.interpret(statements)
