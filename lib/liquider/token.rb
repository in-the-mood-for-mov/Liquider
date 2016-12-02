require 'pry'
class Liquider::Token
  attr_reader :text, :source_info

  class << self
    def new_type(token_name, pattern, &block)
      token_type = Class.new(self) do
        define_method :token_name do
          token_name
        end
      end

      token_type.define_singleton_method :pattern do
        pattern
      end

      token_type.define_singleton_method :to_s do
        token_name.to_s
      end

      token_type.class_eval(&block) if block_given?
      token_type
    end

    def new_tag_leader(token_name)
      new_type(token_name, %r<\{%\s*#{token_name.to_s.downcase}>) do
        def next_mode(current_mode)
          :liquid
        end
      end
    end

    def new_text_keyword(token_name, &block)
      new_type(token_name, %r<\{%\s*#{token_name.to_s.downcase}\s*%\}>, &block)
    end

    def new_expr_keyword(token_name)
      new_type(token_name, %r<#{token_name.to_s.downcase}>)
    end
  end

  def initialize(text, source_info)
    @text, @source_info = text, source_info
  end

  def weight
    text.length
  end

  def ignore?
    false
  end

  def next_mode(current_mode)
    current_mode
  end

  def to_racc
    [token_name, text]
  end

  def raise_on_error(tokens, scanner)
  end

  def to_s
    %Q{#<#{token_name} "#{text}">}
  end
end
