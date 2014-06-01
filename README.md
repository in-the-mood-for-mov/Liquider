# Liquider

Liquider is an alternative implementation of [Liquid](http://liquidmarkup.org/). Its goals are to
- be stricter and to report errors;
- be faster;
- be easier to expand.

## The Liquid Language

Liquider supports the following grammar.
```
<mustache> ::= '{{' <filtered_expr> '}}'
<filtered_expr> ::= <expr> ('|' <filter>)*
<filter> ::=  <ident> (':' <arg_list>)?
<arg_list> ::= <expr> (',' opt_list)?
<opt_list> ::= <ident> ':' <expr> (',' <opt_list>)?
<expr> ::= <call_expr>
         | <op_expr>
         | <range_expr>
<call_expr> ::= <ident> ('.' <call_expr>)?
<op_expr> ::= <expr> <op> <expr>
<range_expr> :: '(' <number> '..' <number> ')'
```
