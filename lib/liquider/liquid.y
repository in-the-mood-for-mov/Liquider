class Liquider::GeneratedParser

token PIPE DOT DOTDOT COLON COMMA
token TIMES DIV
token PLUS MINUS
token EQ NE LT LE GT GE CONTAINS
token MUSTACHEOPEN MUSTACHECLOSE
token TAGOPEN TAGCLOSE
token PARENOPEN PARENCLOSE
token BRACKETOPEN BRACKETCLOSE

token TEXT IDENT NUMBER STRING TRUE FALSE

token GOTOEXPRESSION GOTOARGLIST

token MARKUP BLOCKTAIL

rule
  Liquid
  : Document
  | GOTOEXPRESSION Expression { result = val[1] }
  | GOTOARGLIST ArgList       { result = val[1] }
  ;

  Document
  :                     { result = Ast::DocumentNode.new([]) }
  | DocumentElementList { result = Ast::DocumentNode.new([val].flatten) }
  ;

  DocumentElementList
  : DocumentElement
  | DocumentElementList DocumentElement { result = val.flatten }
  ;

  DocumentElement
  : TEXT     { result = Ast::TextNode.new(val[0]) }
  | MUSTACHEOPEN Expression MUSTACHECLOSE { result = Ast::MustacheNode.new(val[1]) }
  | Block
  ;

  Expression
  : ComparisonExpression
  | Expression PIPE Filter {
      result = val[2]
      result.arg_list.positionals.unshift(val[0])
    }
  ;

  Filter
  : IDENT { result = Ast::FilterNode.new(val[0], Ast::ArgListNode.new([], [])) }
  | IDENT COLON ArgList { result = Ast::FilterNode.new(val[0], val[2]) }
  ;

  ComparisonExpression
  : AdditiveExpression
  | ComparisonExpression EQ AdditiveExpression { result = Ast::BinOpNode.new(:==, val[0], val[2]) }
  | ComparisonExpression NE AdditiveExpression { result = Ast::BinOpNode.new(:!=, val[0], val[2]) }
  | ComparisonExpression LT AdditiveExpression { result = Ast::BinOpNode.new(:<, val[0], val[2]) }
  | ComparisonExpression LE AdditiveExpression { result = Ast::BinOpNode.new(:<=, val[0], val[2]) }
  | ComparisonExpression GT AdditiveExpression { result = Ast::BinOpNode.new(:>, val[0], val[2]) }
  | ComparisonExpression GE AdditiveExpression { result = Ast::BinOpNode.new(:>=, val[0], val[2]) }
  | ComparisonExpression CONTAINS AdditiveExpression { result = Ast::BinOpNode.new(:contains, val[0], val[2]) }
  ;

  AdditiveExpression
  : MultiplicativeExpression
  | AdditiveExpression PLUS MultiplicativeExpression { result = Ast::BinOpNode.new(:+, val[0], val[2]) }
  | AdditiveExpression MINUS MultiplicativeExpression { result = Ast::BinOpNode.new(:-, val[0], val[2], :-) }
  ;

  MultiplicativeExpression
  : CallExpression
  | MultiplicativeExpression TIMES CallExpression { result = Ast::BinOpNode.new(:*, val[0], val[2]) }
  | MultiplicativeExpression DIV CallExpression { result = Ast::BinOpNode.new(:'/', val[0], val[2]) }
  ;

  CallExpression
  : PrimaryExpression
  | CallExpression DOT IDENT { result = Ast::CallNode.new(val[0], val[2]) }
  | CallExpression BRACKETOPEN Expression BRACKETCLOSE { result = Ast::IndexNode.new(val[0], val[3]) }
  ;

  PrimaryExpression
  : IDENT { result = Ast::SymbolNode.new(val[0]) }
  | STRING { result = Ast::StringNode.new(val[0]) }
  | NUMBER { result = Ast::NumberNode.new(val[0]) }
  | TRUE { result = Ast::BooleanNode.new(true) }
  | FALSE { result = Ast::BooleanNode.new(false) }
  | PARENOPEN Expression PARENCLOSE { result = Ast::ParenthesisedNode.new(val[1]) }
  ;

  ArgList
  :                             { result = Ast::ArgListNode.new([], []) }
  | PosArgList                  { result = Ast::ArgListNode.new(val[0], []) }
  | OptArgList                  { result = Ast::ArgListNode.new([], val[0]) }
  | PosArgList COMMA OptArgList { result = Ast::ArgListNode.new(val[0], val[2]) }
  ;

  PosArgList
  : Expression
  | PosArgList COMMA Expression { result = [val[0], val[2]].flatten }
  ;

  OptArgList
  : OptArg                  { result = val }
  | OptArgList COMMA OptArg {
      opt_arg_list, _, opt_arg = val
      if opt_arg_list.map(&:key).include?(opt_arg.key)
        raise LiquiderSyntaxError.new(%Q<Duplicate key "#{opt_arg.key}" in option list.>)
      end
      result = val[0] + [val[2]]
    }
  ;

  OptArg
  : IDENT COLON Expression { result = Ast::OptionPairNode.new(val[0], val[2]) }
  ;

  Block
  : BlockHead Document BlockTail {
      head, document, tail = val
      unless head.tag_name == tail.tag_name
        raise LiquiderSyntaxError.new(%Q<Expected "{% end#{head.tag_name} %}", but found "{% end#{tail.tag_name} %}".>)
      end
      parsed_markup = tags[head.tag_name].parse_markup(head.markup)
      result = Ast::TagNode.new(head.tag_name, parsed_markup, document)
    }
  ;

  BlockHead
  : TAGOPEN IDENT MARKUP TAGCLOSE {
      _, tag_name, markup, _ = val
      inject_token([:BLOCKTAIL, "{% end#{tag_name} %}"]) unless tag_with_name(tag_name).block?
      result = BlockHead.new(tag_name, markup)
    }
  ;

  BlockTail
  : BLOCKTAIL { result = BlockTail.from_source(val[0]) }
  ;
