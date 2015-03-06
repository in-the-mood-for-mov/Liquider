class Liquider::Tags::For
  extend Liquider::MarkupHelper

  def intialize(*args)
    @args = args
  end

  def to_erb
  end

  def self.parse_markup(markup)
    binding.pry
  end
end
