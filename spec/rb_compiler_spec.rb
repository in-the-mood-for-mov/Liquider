require 'spec_helper'

include Liquider::Ast
include Liquider::Spec
include Liquider::RbCompiler::Ast

describe Liquider::RbCompiler do
  let(:compiler) { Liquider::RbCompiler.new }
  before do
    target.visit(compiler)
  end

  context StringNode do
    let(:target) { StringNode.new('hello y#{all}') }
    it "escapes the strings" do
      expect(compiler.output).to eq('"hello y\\#{all}"')
    end
  end

  context BooleanNode do
    context "false" do
      let(:target) { BooleanNode.new(false) }
      it "outputs the value" do
        expect(compiler.output).to eq("false")
      end
    end

    context "true" do
      let(:target) { BooleanNode.new(true) }
      it "outputs the value" do
        expect(compiler.output).to eq("true")
      end
    end
  end

  context NumberNode do
    let(:target) { NumberNode.new(123.333) }
    it "outputs the number" do
      expect(compiler.output).to eq("123.333")
    end
  end

  context BooleanNode do
    let(:target) { BooleanNode.new(true) }
    it "outputs the boolean" do
      expect(compiler.output).to eq("true")
    end
  end

  context NilNode do
    let(:target) { NilNode.new }
    it "outputs nil" do
      expect(compiler.output).to eq("nil")
    end
  end

  context TagNode do
    let(:target) {
      TagNode.new(TestTag.new(:markup, DocumentNode.new([])))
    }
    it "renders the tag" do
      expect_any_instance_of(TestTag).to receive(:render_rb).with(compiler)
      target.visit(compiler)
    end
  end

  context TextNode do
    let(:target) { TextNode.new('<toto id="toto">') }
    it "escapes the output" do
      expect(compiler.output).to eq(%(@rb_output << "<toto id=\\"toto\\">"\n))
    end
  end

  context MustacheNode do
    let(:target) {
      MustacheNode.new(StringNode.new("foo"))
    }
    it "wraps it's expression into an rb output node" do
      expect(compiler.output).to eq(%(@rb_output << "foo"\n\n))
    end
  end

  context NegationNode do
    let(:target) {
      NegationNode.new(NumberNode.new(5))
    }
    it "negates the expression" do
      expect(compiler.output).to eq("!(5)")
    end
  end

  context BinOpNode do
    let(:target) {
      BinOpNode.new(
        :+,
        StringNode.new("foo"),
        StringNode.new("bar"),
      )
    }
    it "adds spaces for sanity" do
      expect(compiler.output).to eq(%("foo" + "bar"))
    end
  end

  context CallNode do
    context 'litteral' do
      let(:target) {
        CallNode.new(StringNode.new("toto"), SymbolNode.new("length"))
      }
      it "doesn't send the symbol to the context" do
        skip
        expect(compiler.output).to eq("'toto'.length")
      end
    end

    context 'symbol' do
      let(:target) {
        CallNode.new(
          CallNode.new(SymbolNode.new("toto"), SymbolNode.new("titi")),
          SymbolNode.new("tata")
        )
      }

      it 'delegates the call to the context' do
        expect(compiler.output).to eq("@context['toto.titi.tata']")
      end
    end
  end

  context IndexNode do
    let(:target) {
      IndexNode.new(SymbolNode.new("toto"), SymbolNode.new("property"))
    }
    it "sends the symbol to the context" do
      expect(compiler.output).to eq("@context['toto[property]']")
    end
  end

  context SymbolNode do
    let(:target) { SymbolNode.new("number") }
    it "sends the symbol to the context" do
      expect(compiler.output).to eq("@context['number']")
    end
  end

  context AssignNode do
    context "simple" do
      let(:target) {
        AssignNode.new(SymbolNode.new("toto"), StringNode.new("titi"))
      }

      it 'assigns a litteral' do
        expect(compiler.output).to eq(%(@context['toto'] = "titi"))
      end
    end

    context "with filters" do
      let(:target) {
        AssignNode.new(SymbolNode.new('toto'),
          FilterNode.new(
            "filter1",
            ArgListNode.new([
              SymbolNode.new("identifier")
            ], [])
          )
        )
      }

      it 'assigns to the context correctly' do
        expect(compiler.output).to eq("@context['toto'] = filter1(@context['identifier'])")
      end
    end
  end

  context CaseNode do
    let(:target) {
      CaseNode.new(
        SymbolNode.new('x'),
        [
          WhenNode.new(
            NumberNode.new(0),
            DocumentNode.new([TextNode.new('foo')])
          ),
          WhenNode.new(
            NumberNode.new(1),
            DocumentNode.new([TextNode.new('bar')])
          ),
          CaseElseNode.new(
            DocumentNode.new([TextNode.new('quux')])
          ),
        ]
      )
    }
    it 'compiles case/when/else' do
      expected =
        %(case @context['x']\n) +
        %(when 0\n@rb_output << "foo"\n) +
        %(when 1\n@rb_output << "bar"\n) +
        %(else\n@rb_output << "quux"\n) +
        %(end\n)
      expect(compiler.output).to eq(expected)
    end
  end

  context ForNode do
    let (:empty_body) { "do |_liquider_var_1|\n@context['x'] = _liquider_var_1\nend\n" }
    context "simple for" do
      let(:target) {
        ForNode.new(
          SymbolNode.new('x'),
          CallNode.new(SymbolNode.new('foo'), SymbolNode.new('bar')),
          DocumentNode.new([
            MustacheNode.new(
              CallNode.new(SymbolNode.new('x'), SymbolNode.new('title'))
            ),
          ])
        )
      }

      it 'compiles the body in an each loop and assigns to the context' do
        expect(compiler.output).to eq(%(@context['foo.bar'].each do |_liquider_var_1|\n@context['x'] = _liquider_var_1\n@rb_output << @context['x.title']\n\nend\n))
      end
    end

    context "for reversed" do
      let(:target) {
        ForNode.new(
          SymbolNode.new('x'),
          SymbolNode.new('foo'),
          DocumentNode.new([]),
          reversed: BooleanNode.new(true),
        )
      }

      it "reverses the elements" do
        expect(compiler.output).to eq("@context['foo'].reverse.each " + empty_body)
      end
    end

    context "for with limit" do
      let(:target) {
        ForNode.new(
          SymbolNode.new('x'),
          SymbolNode.new('foo'),
          DocumentNode.new([]),
          limit: BinOpNode.new(:+, NumberNode.new(5), NumberNode.new(4)),
        )
      }

      it "takes some elements" do
        expect(compiler.output).to eq("@context['foo'].take(5 + 4).each " + empty_body)
      end
    end

    context "for with offset" do
      let(:target) {
        ForNode.new(
          SymbolNode.new('x'),
          SymbolNode.new('foo'),
          DocumentNode.new([]),
          offset: BinOpNode.new(:+, NumberNode.new(5), NumberNode.new(4)),
        )
      }

      it "drops some elements" do
        expect(compiler.output).to eq("@context['foo'].drop(5 + 4).each " + empty_body)
      end
    end

    context "with everything" do
      let(:target) {
        ForNode.new(
          SymbolNode.new('x'),
          SymbolNode.new('foo'),
          DocumentNode.new([]),
          offset: NumberNode.new(5),
          limit: NumberNode.new(5),
          reversed: BooleanNode.new(true),
        )
      }

      it "combines drop/take/reverse" do
        expect(compiler.output).to eq("@context['foo'].drop(5).take(5).reverse.each " + empty_body)
      end
    end
  end

  context IfNode do
    context 'simple if' do
      let(:target) {
        IfNode.new(
          SymbolNode.new('foo'),
          DocumentNode.new([
            TextNode.new('asdf')
          ]),
          NullNode.new
        )
      }

      it 'compiles simple if nodes' do
        expect(compiler.output).to eq(%(if @context['foo']\n@rb_output << "asdf"\nelse\nend\n))
      end
    end

    context 'if/else' do
      let(:target) {
        IfNode.new(
          SymbolNode.new('foo'),
          DocumentNode.new([
            TextNode.new('asdf')
          ]),
          ElseNode.new(
            DocumentNode.new([
              MustacheNode.new(SymbolNode.new('bar'))
            ])
          )
        )
      }

      it 'compiles if/else branches' do
        expected = %(if @context['foo']\n@rb_output << "asdf"\nelse\n@rb_output << @context['bar']\n\nend\n)
        expect(compiler.output).to eq(expected)
      end
    end

    context 'if/elsif/else' do
      let(:target) {
        IfNode.new(
          SymbolNode.new('foo'),
          DocumentNode.new([
            TextNode.new('asdf')
          ]),
          IfNode.new(
            SymbolNode.new('quux'),
            DocumentNode.new([]),
            ElseNode.new(
              DocumentNode.new([
                MustacheNode.new(SymbolNode.new('bar'))
              ])
            )
          )
        )
      }

      it 'compiles if/elsif/else branches' do
        expected = %(if @context['foo']\n@rb_output << "asdf"\nelse\nif @context['quux']\nelse\n@rb_output << @context['bar']\n\nend\nend\n)
        expect(compiler.output).to eq(expected)
      end
    end
  end

  context FilterNode do
    let(:target) {
      FilterNode.new(
        "filter2",
        ArgListNode.new([
          FilterNode.new(
            "filter1",
            ArgListNode.new([
              SymbolNode.new("identifier")
            ], [])
          )], []
        )
      )
    }
    it 'unwraps filters correctly' do
      expect(compiler.output).to eq("filter2(filter1(@context['identifier']))")
    end
  end

  context ArgListNode do
    let(:target) {
      ArgListNode.new([
        StringNode.new('arg1'),
        SymbolNode.new('variable')
      ], [
        OptionPairNode.new(
          'key',
          StringNode.new('value')
        ),
        OptionPairNode.new(
          'other_key',
          SymbolNode.new('other_variable')
        )
      ])
    }

    it 'correctly outputs positionals and optionals' do
      expect(compiler.output).to eq(%("arg1", @context['variable'], {"key" => "value", "other_key" => @context['other_variable']}))
    end
  end

  context ParenthesisedNode do
    let(:target) {
      ParenthesisedNode.new(
        BinOpNode.new(
          :/,
          ParenthesisedNode.new(BinOpNode.new(:+, NumberNode.new(1), NumberNode.new(3))),
          BinOpNode.new(:*, NumberNode.new(4), NumberNode.new(5)),
        )
      )
    }
    it "can be nested" do
      expect(compiler.output).to eq("((1 + 3) / 4 * 5)")
    end
  end

  context DocumentNode do
    let(:target) {
      DocumentNode.new([
        MustacheNode.new(
          BinOpNode.new(
            :<,
            BinOpNode.new(
              :+,
              SymbolNode.new('foo'),
              BinOpNode.new(
                :*,
                StringNode.new('bar'),
                SymbolNode.new('baz'),
              ),
            ),
            NumberNode.new(40),
          ),
        ),
        TextNode.new("this is sparta")
      ])
    }

    it "compiles the document" do
      expect(compiler.output).to eq(
        %(@rb_output << @context['foo'] + "bar" * @context['baz'] < 40\n\n) +
        %(@rb_output << "this is sparta"\n)
      )
    end
  end

  context CaptureNode do
    let(:target) {
      CaptureNode.new("toto", MustacheNode.new(StringNode.new("test")))
    }
    it 'captures the body of the div' do
      expect(compiler.output).to eq(%(toto = capture do\n@rb_output << "test"\n\nend\n))
    end
  end

  context LocalAssignNode do
    let(:target) {
      LocalAssignNode.new("toto", StringNode.new("titi"))
    }
    it 'assigns the variable to the local context' do
      expect(compiler.output).to eq(%(toto = "titi"\n))
    end
  end

  context LocalFetchNode do
    let(:target) {
      MustacheNode.new(LocalFetchNode.new("toto"))
    }
    it 'renders correctly' do
      expect(compiler.output).to eq("@rb_output << toto\n\n")
    end
  end

  context ContextStackNode do
    let(:target) {
      ContextStackNode.new(TextNode.new("text"))
    }
    it 'stacks context' do
      expect(compiler.output).to eq(%(@context.stack do\n@rb_output << "text"\nend\n))
    end
  end
end


