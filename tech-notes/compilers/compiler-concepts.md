# Compiler Concepts

A compiler is a specialized software program that translates source code written in a high-level programming language into machine code or an intermediate representation that can be executed by a computer. The primary purpose of a compiler is to enable developers to write code in a more human-readable form while ensuring that the resulting program can run efficiently on hardware.

## Interpreted Language

**Lexer (or Tokenizer)**: This is the first stage of processing source code. A lexer takes the raw input string (the source code) and breaks it down into a stream of meaningful units called tokens. It identifies sequences of characters that represent keywords, identifiers, operators, literals (like numbers or strings), and other grammatical elements of the language, discarding whitespace and comments.

**Token**: A token is a fundamental, indivisible unit of a programming language, representing a category of lexical analysis. It consists of a type (e.g., "KEYWORD," "IDENTIFIER," "OPERATOR," "INTEGER_LITERAL") and often a value (e.g., the actual keyword "if," the identifier "myVariable," the operator "+," the number "10").

**Parser**: The parser receives the stream of tokens from the lexer and analyzes their sequence to ensure they conform to the grammatical rules (syntax) of the programming language. It constructs a structured representation of the code, typically an Abstract Syntax Tree (AST), which reflects the hierarchical relationships between the tokens and how they form valid statements and expressions.

**Interpreter**: An interpreter directly executes the instructions represented in the structured form (often an AST) produced by the parser, without first compiling the entire program into machine code. It reads and executes the code line by line or statement by statement, performing the operations specified by the program logic.

**Repl**: REPL stands for Read-Eval-Print Loop. It is an interactive programming environment that allows users to enter code, which is then read (parsed), evaluated (executed using the interpreter), and the result is printed back to the user. This loop continues until the user decides to exit. REPLs are commonly used in languages like Scala, Clojure, JavaScript, and Lisp for quick testing and experimentation.
