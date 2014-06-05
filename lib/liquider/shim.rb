require 'liquid'

module Liquider
  module Shim
    class Context
      def initialize(variables)
        @context = Liquid::Context.new
        @context.merge(variables)
      end

      def to_erb
        binding
      end
    end

    class Tag
      def initialize(tag_name)
        @tag_name = tag_name
      end

      def parse(body)
      end

      def self.render(tag, markup, tokens, options, context)
        parsed = Liquid::Template.tags[tag].parse(tag, markup, tokens, options)
        parsed.render(context)
      end
    end

    class TagNode
      def initialize(tag_name, markup, options)
        @tag_name = tag_name
        @markup = markup
        @options = options
      end
    end

    class BlockNode
      def initialize(tag_name, markup, body, options)
        @tag_name = tag_name
        @markup = markup
        @options = options
        @body = body
      end
    end

    class MarkupParser
      def initialize(node_name)
      end

      def parse(markup)
        markup
      end
    end

    class BodyParser
      def self.blocks
        @blocks ||= Liquid::Template.tags.select { |name, tag| tag < Liquid::Block }
      end

      def initialize(block_name)
        @block_name = block_name
      end

      def fragment_match
        open_blocks = Regexp.union(self.class.blocks.keys)
        /{%\s*(:?=#{open_blocks}.*?%})|(end#{@block_name}\s*%})/
      end

      def parse(stream)
        position = stream.pos
        raw_body = stream.scan_until(fragment_match)
        if end_body?(stream.matched)
          [raw_body]
        else
          # Nested Parsing
        end
      end

      def end_body?(fragment)
        fragment =~ /end#{@block_name}/
      end
    end
  end
end

class Liquid::Tag
  def self.markup_parser
    Liquider::Shim::MarkupParser
  end

  def self.body_parser
    Liquider::Shim::BodyParser
  end
end
#puts ERB.new(File.read("./template.html.erb")).result(Shim::Context.new(vars).to_erb)
