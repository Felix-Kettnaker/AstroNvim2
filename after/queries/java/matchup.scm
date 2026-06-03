; try / catch / finally
(try_statement
  "try" @open.try) @scope.try

(try_with_resources_statement
  "try" @open.try) @scope.try

(catch_clause
  "catch" @mid.try.1)

(finally_clause
  "finally" @mid.try.2)

; if / else  (else is a token child; "else if" nests as another if_statement)
(if_statement
  "if" @open.if
  ("else" @mid.if.1)?) @scope.if

; switch / case / default  (covers both : labels and -> rules)
(switch_expression
  "switch" @open.switch) @scope.switch

(switch_label
  "case" @mid.switch.1)

(switch_label
  "default" @mid.switch.2)
