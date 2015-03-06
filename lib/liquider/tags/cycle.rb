class Liquider::Tags::Cycle < Liquider::Tags::Tag
  extend Liquider::MarkupHelper

  def intialize(*args)
    @args = args
  end

  def to_erb
    RawErbNode.new(
      "_cycles ||= Hash.new(0); [",
      @args,
      "][_cycles[#{@args.hash} += 1] % #{@args.length}]"
    )
  end

  def self.parse_markup(markup)
    # binding.pry
  end
end
