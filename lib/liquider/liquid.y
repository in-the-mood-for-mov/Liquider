class Liquider::GeneratedParser

token PIPE DOT DOTDOT COLON COMMA
token TIMES DIV
token PLUS MINUS
token EQ EQEQ NE LT LE GT GE CONTAINS
token MUSTACHEOPEN MUSTACHECLOSE
token TAGOPEN TAGCLOSE
token PARENOPEN PARENCLOSE
token BRACKETOPEN BRACKETCLOSE

token TEXT IDENT KEYWORD NUMBER STRING TRUE FALSE

token GOTOEXPRESSION GOTOARGLIST

token MARKUP ENDBLOCK
token IF ELSIF ELSE ENDIF UNLESS ENDUNLESS
token CASE WHEN ENDCASE
token FOR IN REVERSED ENDFOR
token ASSIGN CAPTURE ENDCAPTURE

rule
  Liquid
  : Document
  | GOTOEXPRESSION PipeExpression { result = val[1] }
  | GOTOARGLIST ArgList       { result = val[1] }
  ;

  Document
  : { result = Ast::DocumentNode.new([]) }
  | DocumentElementList { result = Ast::DocumentNode.new([val].flatten) }
  ;

  DocumentElementList
  : DocumentElement
  | DocumentElementList DocumentElement { result = val.flatten }
  ;

  DocumentElement
  : TEXT { result = Ast::TextNode.new(val[0]) }
  | MUSTACHEOPEN PipeExpression MUSTACHECLOSE { result = Ast::MustacheNode.new(val[1]) }
  | Block
  ;

  Expression
  : ComparisonExpression
  ;

  PipeExpression
  : Expression
  | PipeExpression PIPE Filter {
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
  | ComparisonExpression EQEQ AdditiveExpression { result = Ast::BinOpNode.new(:==, val[0], val[2]) }
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
  | AdditiveExpression MINUS MultiplicativeExpression { result = Ast::BinOpNode.new(:-, val[0], val[2]) }
  ;

  MultiplicativeExpression
  : CallExpression
  | MultiplicativeExpression TIMES CallExpression { result = Ast::BinOpNode.new(:*, val[0], val[2]) }
  | MultiplicativeExpression DIV CallExpression { result = Ast::BinOpNode.new(:'/', val[0], val[2]) }
  ;

  CallExpression
  : PrimaryExpression
  | CallExpression DOT IDENT { result = Ast::CallNode.new(val[0], Ast::SymbolNode.new(val[2])) }
  | CallExpression BRACKETOPEN Expression BRACKETCLOSE { result = Ast::IndexNode.new(val[0], val[3]) }
  ;

  PrimaryExpression
  : IDENT { result = Ast::SymbolNode.new(val[0]) }
  | STRING { result = Ast::StringNode.new(val[0]) }
  | NUMBER { result = Ast::NumberNode.new(val[0].to_i) }
  | TRUE { result = Ast::BooleanNode.new(true) }
  | FALSE { result = Ast::BooleanNode.new(false) }
  | PARENOPEN PipeExpression PARENCLOSE { result = Ast::ParenthesisedNode.new(val[1]) }
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
  : OptArg { result = [val[0]] }
  | OptArgList COMMA OptArg {
      opt_arg_list, _, opt_arg = val
      if opt_arg_list.map(&:key).include?(opt_arg.key)
        raise LiquiderSyntaxError.new(%Q<Duplicate key "#{opt_arg.key}" in option list.>)
      end
      result = val[0] + [val[2]]
    }
  ;

  OptArg
  : KEYWORD Expression { result = Ast::OptionPairNode.new(val[0].chomp(':'), val[1]) }
  ;

  Block
  : IfStatement
  | UnlessStatement
  | CaseStatement
  | ForStatement
  | AssignStatement
  | CaptureStatement
  | BlockHead Document BlockTail {
      head, document, tail = val
      unless head.tag_name == tail.tag_name
        raise LiquiderSyntaxError.new(%Q<Expected "{% end#{head.tag_name} %}", but found "{% end#{tail.tag_name} %}".>)
      end
      tag_class = tags[head.tag_name]
      parsed_markup = tag_class.parse_markup(head.markup)
      result = Ast::TagNode.new(tag_class.new(parsed_markup, document))
    }
  ;

  BlockHead
  : TAGOPEN MARKUP TAGCLOSE {
      tag_head, markup, _ = val
      tag_name = tag_head.gsub(/\{%\s*/, '')
      inject_token([:ENDBLOCK, "{%end#{tag_name}%}"]) unless tag_with_name(tag_name).block?
      result = BlockHead.new(tag_name, markup)
    }
  ;

  BlockTail
  : ENDBLOCK { result = BlockTail.from_token(val[0]) }
  ;

  IfStatement
  : IF Expression TAGCLOSE Document IfContinuation {
      _, head, _, document, continuation = *val
      result = Ast::IfNode.new(head, document, continuation)
    }
  ;

  IfContinuation
  : ENDIF {
      result = Ast::NullNode.new
    }
  | ELSE Document ENDIF {
      _, body, _ = *val
      result = Ast::ElseNode.new(body)
    }
  | ELSIF Expression TAGCLOSE Document IfContinuation {
      _, head, _, body, continuation = *val
      result = Ast::IfNode.new(head, body, continuation)
    }
  ;

  UnlessStatement
  : UNLESS Expression TAGCLOSE Document ENDUNLESS {
      _, head, _, body, _ = *val
      result = Ast::IfNode.new(Ast::NegationNode.new(head), body, Ast::NullNode.new)
    }
  ;

  CaseStatement
  : CASE Expression TAGCLOSE WHEN Expression TAGCLOSE Document CaseContinuation {
      _, head, _, _, first_case, _, first_value, rest = *val
      result = Ast::CaseNode.new(head, [WhenNode.new(first_case, first_value), *rest])
    }
  ;

  CaseContinuation
  : ENDCASE { result = [] }
  | ELSE TAGCLOSE Document ENDCASE { result = [CaseElseNode.new(val[2])] }
  | WHEN Expression TAGCLOSE Document CaseContinuation { result = [WhenNode.new(val[1], val[3]), *val[4]] }
  ;

  ForStatement
  : FOR IDENT IN Expression ForOptions TAGCLOSE Document ENDFOR {
      _, binding, _, expression, options, _, body, _ = *val
      result = Ast::ForNode.new(Ast::SymbolNode.new(binding), expression, body, **options)
    }
  ;

  ForOptions
  : { result = {} }
  | COMMA ForOptions {
      _, options = *val
      result = options
    }
  | KEYWORD Expression ForOptions {
      keyword, value, options = *val
      result = case keyword.gsub(/:\z/, '')
      when 'limit'
        if options.has_key?(:limit)
          raise LiquiderSyntaxError.new("'limit' was specified multiple times on 'for' tag.")
        end
        options.merge(limit: value)
      when 'offset'
        if options.has_key?(:offset)
          raise LiquiderSyntaxError.new("'offset' was specified multiple times on 'for' tag.")
        end
        options.merge(offset: value)
      else raise LiquiderSyntaxError.new("Unknown 'for' loop option '#{keyword}'.")
      end
    }
  | REVERSED ForOptions {
      _, options = *val
      if options.has_key?(:reversed)
        raise LiquiderSyntaxError.new("'reversed' was specified multiple times on 'for' tag.")
      end
      result = options.merge(reversed: Ast::BooleanNode.new(true))
    }
  ;

  AssignStatement
  : ASSIGN IDENT EQ Expression TAGCLOSE {
      _, binding, _, value = *val
      result = Ast::AssignNode.new(Ast::SymbolNode.new(binding), value)
    }
  ;

  CaptureStatement
  : CAPTURE IDENT TAGCLOSE Document ENDCAPTURE {
      _, binding, _, document, _ = *val
      result = Ast::CaptureNode.new(Ast::SymbolNode.new(binding), document)
    }
  ;
