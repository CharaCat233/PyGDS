
# Code and Documentation Standards

## Code Writing

### No Inline Multi-Statements

Inline multi-statements are not allowed

```gdscript
# Wrong example
if true: var a = 10; var b = 20;

# Should be changed to
if true:
  var a = 10
  var b = 20
```

### Symbol and Punctuation Rules

1. Semicolons are not allowed in code or comments (excluding string literals, URLs, regular expressions and other content that actually does its work)
2. Chinese punctuation inside comments is only allowed when it serves as described content, avoids ambiguity, quotes the original text, or forms a formal name (for example, in the comment `# 替换所有的 "【】" 符号`, the Chinese punctuation serves an explanatory purpose and is allowed)
3. After English punctuation such as commas, colons, exclamation marks and question marks, add one space if prose continues

```gdscript
# Wrong example: carries a semicolon
# This is a comment; This is also a comment

# Correct example
# This is a comment
# This is also a comment

# Wrong example: carries Chinese punctuation
# This is a comment，this is also a comment

# Correct example
# This is a comment, this is also a comment

# Wrong example: no space after English punctuation
# This is a comment,this is also a comment

# Correct example
# This is a comment, this is also a comment
```

### Proper Use of `BBCode` in Doc Comments

Doc comments should add the `[br]` marker after non-final lines (Godot doc comments do not preserve soft line breaks automatically); the `[code]` marker is considered potentially harmful to readability, so it may be omitted

```gdscript
# Wrong example: no marker
## This is a document annotation
## This is also a document annotation

# Wrong example: trailing marker
## This is a document annotation [br]

# Correct example
## This is a document annotation [br]
## This is also a document annotation
```

### External References

Comments should not contain unnecessary external references, nor lack necessary ones. Necessary scenarios include:

1. Relating to a known issue, issue, or PR
2. Relating to a design document, protocol, or standard
3. Explaining background that cannot be expanded within the comment
4. Marking temporary workarounds and their removal conditions

```gdscript
# Wrong example: unnecessary external reference
# The issue (P0-1) has been fixed in version v1.0.0 and the method is running normally.

# Correct example: describe what the code does, or omit the issue ID and the fixed-in version after the fix
# ... (method description)

# Wrong example: missing a necessary external reference
# This method has anomalies.

# Correct example
# This method has anomalies, please refer to the list of known issues for details (ID P0-1)
```

## Document Writing

### Document Punctuation

Documents should use the punctuation of their own language, and a space must follow English punctuation. In Chinese documents, a paragraph may end without a full stop, and sentence-final full stops are discouraged inside tables and similar regions; English documents should use full stops

```markdown
这是一段中文文档，描述了一段代码的作用。这段代码用途很多，分别是：用途 A、用途 B 以及用途 C

This is a Chinese document that describes the function of a piece of code. This code has many uses, including: use A, use B, and use C.
```

### Code Block Rules

Text inside code blocks should follow the rules in [Code Writing](#code-writing)

## Special Documents

### Commit Messages

Git commit messages should satisfy the following rules

1. The first line is the subject, ideally no more than 50 characters; the second line is blank; each body line is no more than 72 characters
2. Code parts should be wrapped in markdown inline code markers
3. Follow the Commit message convention as much as possible

### Changelog

`CHANGELOG.md` should satisfy the following rules

1. During development, write changes into the corresponding category under `## [Unreleased]`
2. On release, rename `Unreleased` to the concrete version number and date (for example `## [1.2.0] - 2024-06-01`), then recreate an empty `## [Unreleased]` at the top
3. Follow the Keep a Changelog and Semantic Versioning conventions as much as possible (see the `CHANGELOG.md` document for versions)

### Differences List

The [Differences List](differences.md) document should satisfy the following rules

***Entry Summary Table***

Its rules are written at the top of the corresponding section (see [Entry Summary Table](./differences.md#entry-summary-table)); below is an example row of the table

```markdown
| ID | Status | Date | Version | Brief Description |
| :--- | :--- | :--- | :--- | :--- |
| [I2-0](#i2-0-example-issue) | Deferred | 2026-09-29 | `v0.6.0-alpha.1` | Brief description of the issue |
```

***Entry Section Format***

Entry sections should be written following the sample below

````markdown
### I2-0 Example Issue

***Brief Description***

(Example 1) The issue was discovered on 2026-09-29, in version `v0.6.0-alpha.1`; a certain function has a serious side effect with no warning or error

(Example 2) The issue was discovered on 2026-09-29, in version `v0.6.0-alpha.1`, from the [GitHub Issues](https://github.com/CharaCat233/PyGDS/issues) page; a certain function has a serious side effect with no warning or error

***Issue Status***

(Example 1) Due to a Godot platform limitation, the issue is very hard to fix and remains unfixed for now

(Example 2) The issue was fixed on 2026-09-29, as one of the tasks of version `v0.6.0-alpha.2`

***Minimal Reproduction***

```python
# Example Python code
```

Expected output (Python)

```txt
```

Actual output (PyGDS)

```txt
```

***Fix Record and Notes***

This part may contain the fix record (including dead ends and pitfalls encountered during fixing), or notes taken during the fixing process
````
