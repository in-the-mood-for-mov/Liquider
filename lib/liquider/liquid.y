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

token GOTO_EXPRESSION GOTO_ARGLIST

rule
  Liquid:
    Document
  | GOTO_EXPRESSION Expression { result = val[1] }
  # | GOTO_ARGLIST Arglist       { result = val[1] }
  ;

  Document:
                        { result = Ast::DocumentNode.new([]) }
  | DocumentElementList { result = Ast::DocumentNode.new([val].flatten) }
  ;

  DocumentElementList:
    DocumentElement
  | DocumentElementList DocumentElement { result = val.flatten }
  ;

  DocumentElement:
    TEXT     { result = Ast::TextNode.new(val[0]) }
  | MUSTACHEOPEN Expression MUSTACHECLOSE { result = Ast::MustacheNode.new(val[1]) }
  | Tag
  ;

  Expression:
    ComparisonExpression
  ;

  ComparisonExpression:
    AdditiveExpression
  | ComparisonExpression EQ AdditiveExpression { result = Ast::BinOpNode.new(:==, val[0], val[2]) }
  | ComparisonExpression NE AdditiveExpression { result = Ast::BinOpNode.new(:!=, val[0], val[2]) }
  | ComparisonExpression LT AdditiveExpression { result = Ast::BinOpNode.new(:<, val[0], val[2]) }
  | ComparisonExpression LE AdditiveExpression { result = Ast::BinOpNode.new(:<=, val[0], val[2]) }
  | ComparisonExpression GT AdditiveExpression { result = Ast::BinOpNode.new(:>, val[0], val[2]) }
  | ComparisonExpression GE AdditiveExpression { result = Ast::BinOpNode.new(:>=, val[0], val[2]) }
  | ComparisonExpression CONTAINS AdditiveExpression { result = Ast::BinOpNode.new(:contains, val[0], val[2]) }
  ;

  AdditiveExpression:
    MultiplicativeExpression
  | AdditiveExpression PLUS MultiplicativeExpression { result = Ast::BinOpNode.new(:+, val[0], val[2]) }
  | AdditiveExpression MINUS MultiplicativeExpression { result = Ast::BinOpNode.new(:-, val[0], val[2], :-) }
  ;

  MultiplicativeExpression:
    CallExpression
  | MultiplicativeExpression TIMES CallExpression { result = Ast::BinOpNode.new(:*, val[0], val[2]) }
  | MultiplicativeExpression DIV CallExpression { result = Ast::BinOpNode.new(:'/', val[0], val[2]) }
  ;

  CallExpression:
    PrimaryExpression
  | CallExpression DOT IDENT { result = Ast::CallNode.new(val[0], val[2]) }
  | CallExpression BRACKETOPEN Expression BRACKETCLOSE { result = Ast::IndexNode.new(val[0], val[3]) }
  ;

  PrimaryExpression:
    IDENT { result = Ast::SymbolNode.new(val[0]) }
  | STRING { result = Ast::StringNode.new(val[0]) }
  | NUMBER { result = Ast::NumberNode.new(val[0]) }
  | TRUE { result = Ast::BooleanNode.new(true) }
  | FALSE { result = Ast::BooleanNode.new(false) }
  | PARENOPEN Expression PARENCLOSE { result = Ast::ParenthesisedNode.new(val[1]) }
  ;

  Tag:
    TagLeader TAGCLOSE
  ;

  TagLeader:
    TAGOPEN IDENT {
      parse_tag val[1]
      # tag_class = tags[tag_name]
      # raise LiquiderSyntaxError, "Unknown tag '#{tag_name}'." unless tag_class

      # markup_parser = tag_class.markup_parser.new(tag_name, tags)
      # markup = markup_parser.parse(MarkupView.new(source_scanner))
      # return tag_class.build(tag_name, markup) unless tag_class.block?

      # body_parser = tag_class.body_parser.new(tag_name, tags)
      # body = body_parser.parse(BodyView.new(source_scanner)
      # tag_class.build(tag_name, markup, body)
    }
  ;
