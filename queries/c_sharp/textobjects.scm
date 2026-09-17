; ~/.config/nvim/queries/c_sharp/textobjects.scm
;
; Textobjects Tree-sitter para C#, pensados para o mini.ai.
; Convenção: @x.outer = o nó inteiro | @x.inner = só o "miolo".
; Captures quantificadas (_* @x.inner) viram um único range, do primeiro
; ao último nó; o mini.ai junta tudo sozinho.

; ============================================================================
; CLASS: class, struct, record, interface, enum
; ============================================================================

[
  (class_declaration)
  (struct_declaration)
  (record_declaration)
  (interface_declaration)
  (enum_declaration)
] @class.outer

; miolo = tudo entre as chaves (sem inner se o corpo estiver vazio).
; Um padrão por tipo: namespace também usa declaration_list e não é classe.
(class_declaration
  body: (declaration_list "{" _+ @class.inner "}"))

(struct_declaration
  body: (declaration_list "{" _+ @class.inner "}"))

(record_declaration
  body: (declaration_list "{" _+ @class.inner "}"))

(interface_declaration
  body: (declaration_list "{" _+ @class.inner "}"))

(enum_declaration
  body: (enum_member_declaration_list
    "{"
    _+ @class.inner
    "}"))

; ============================================================================
; FUNCTION: métodos, construtores, funções locais, lambdas, get/set
; ============================================================================

[
  (method_declaration)
  (constructor_declaration)
  (destructor_declaration)
  (operator_declaration)
  (conversion_operator_declaration)
  (local_function_statement)
  (lambda_expression)
  (anonymous_method_expression)
  (accessor_declaration)
] @function.outer

; corpo com chaves:  void Foo() { ... }
; (um padrão por tipo: for, while, using etc. também têm body: (block))
(method_declaration
  body: (block "{" _+ @function.inner "}"))

(constructor_declaration
  body: (block "{" _+ @function.inner "}"))

(destructor_declaration
  body: (block "{" _+ @function.inner "}"))

(operator_declaration
  body: (block "{" _+ @function.inner "}"))

(conversion_operator_declaration
  body: (block "{" _+ @function.inner "}"))

(local_function_statement
  body: (block "{" _+ @function.inner "}"))

(accessor_declaration
  body: (block "{" _+ @function.inner "}"))

(lambda_expression
  body: (block "{" _+ @function.inner "}"))

; expression-bodied:  int Dobro(int x) => x * 2;
(method_declaration
  body: (arrow_expression_clause "=>" (_) @function.inner))

(constructor_declaration
  body: (arrow_expression_clause "=>" (_) @function.inner))

(destructor_declaration
  body: (arrow_expression_clause "=>" (_) @function.inner))

(operator_declaration
  body: (arrow_expression_clause "=>" (_) @function.inner))

(conversion_operator_declaration
  body: (arrow_expression_clause "=>" (_) @function.inner))

(local_function_statement
  body: (arrow_expression_clause "=>" (_) @function.inner))

(accessor_declaration
  body: (arrow_expression_clause "=>" (_) @function.inner))

; lambda de expressão:  x => x * 2
(lambda_expression
  body: (expression) @function.inner)

; delegate { ... } não usa o campo "body"
(anonymous_method_expression
  (block
    "{"
    _+ @function.inner
    "}"))

; ============================================================================
; BLOCK: qualquer { ... } de código
; ============================================================================

(block) @block.outer

(block
  "{"
  _+ @block.inner
  "}")

; ============================================================================
; CONDITIONAL: if / else, switch, switch expression, ternário
; ============================================================================

[
  (if_statement)
  (switch_statement)
  (switch_expression)
  (conditional_expression)
] @conditional.outer

; if com chaves -> conteúdo do bloco; sem chaves -> a própria instrução
(if_statement
  consequence: (block
    "{"
    _+ @conditional.inner
    "}"))

(if_statement
  consequence: [
    (expression_statement)
    (return_statement)
    (throw_statement)
    (break_statement)
    (continue_statement)
  ] @conditional.inner)

(switch_statement
  body: (switch_body
    "{"
    _+ @conditional.inner
    "}"))

(switch_expression
  "{"
  _+ @conditional.inner
  "}")

(conditional_expression
  consequence: (_) @conditional.inner)

; ============================================================================
; LOOP: for, foreach, while, do-while
; ============================================================================

[
  (for_statement)
  (foreach_statement)
  (while_statement)
  (do_statement)
] @loop.outer

(for_statement
  body: (block "{" _+ @loop.inner "}"))

(foreach_statement
  body: (block "{" _+ @loop.inner "}"))

(while_statement
  body: (block "{" _+ @loop.inner "}"))

(do_statement
  body: (block "{" _+ @loop.inner "}"))

(for_statement
  body: [
    (expression_statement)
    (if_statement)
    (return_statement)
    (break_statement)
    (continue_statement)
    (throw_statement)
  ] @loop.inner)

(foreach_statement
  body: [
    (expression_statement)
    (if_statement)
    (return_statement)
    (break_statement)
    (continue_statement)
    (throw_statement)
  ] @loop.inner)

(while_statement
  body: [
    (expression_statement)
    (if_statement)
    (return_statement)
    (break_statement)
    (continue_statement)
    (throw_statement)
  ] @loop.inner)

; ============================================================================
; CALL: Foo(a, b) e new Foo(a, b)
; ============================================================================

[
  (invocation_expression)
  (object_creation_expression)
] @call.outer

(invocation_expression
  arguments: (argument_list
    "("
    _+ @call.inner
    ")"))

(object_creation_expression
  arguments: (argument_list
    "("
    _+ @call.inner
    ")"))

; ============================================================================
; PARAMETER: parâmetros na declaração e argumentos na chamada
; outer inclui a vírgula, para "daa" apagar sem sobrar ", "
; ============================================================================

; parâmetro precedido de vírgula: pega ", param"
(parameter_list
  "," @parameter.outer
  .
  (parameter) @parameter.inner @parameter.outer)

; primeiro parâmetro: pega "param," (vírgula opcional)
(parameter_list
  .
  "("
  .
  (parameter) @parameter.inner @parameter.outer
  .
  ","? @parameter.outer)

(argument_list
  "," @parameter.outer
  .
  (argument) @parameter.inner @parameter.outer)

(argument_list
  .
  "("
  .
  (argument) @parameter.inner @parameter.outer
  .
  ","? @parameter.outer)

; ============================================================================
; ASSIGNMENT: x = 1;  var x = 1;  int X { get; } = 1;
; ============================================================================

; x = valor;
(expression_statement
  (assignment_expression
    left: (_) @assignment.lhs
    right: (_) @assignment.rhs @assignment.inner)) @assignment.outer

; var x = valor;  (e campos: private int _x = 1;)
[
  (local_declaration_statement)
  (field_declaration)
] @assignment.outer

(variable_declarator
  name: (_) @assignment.lhs
  "="
  .
  (_) @assignment.rhs @assignment.inner)

; propriedade com inicializador:  public int X { get; set; } = 10;
(property_declaration
  name: (_) @assignment.lhs
  "="
  .
  value: (_) @assignment.rhs @assignment.inner) @assignment.outer

; ============================================================================
; RETURN
; ============================================================================

(return_statement) @return.outer

(return_statement
  (_) @return.inner)

; ============================================================================
; COMMENT: comentários consecutivos (ex.: bloco de /// <summary>) viram um só
; ============================================================================

(comment)+ @comment.outer

; ============================================================================
; EXTRAS DE C#
; ============================================================================

; [HttpGet("{id}")]  -> outer com colchetes, inner sem
(attribute_list) @attribute.outer

(attribute_list
  "["
  _+ @attribute.inner
  "]")

; public string Nome { get; set; }  -> inner = o bloco { get; set; }
(property_declaration) @property.outer

(property_declaration
  accessors: (accessor_list) @property.inner)

(property_declaration
  value: (arrow_expression_clause) @property.inner)
