class CycleTag < Liquider::Tag
  def render_erb(compiler)
    compiler.erb_tag(output: true) do
      compiler.raw(
        "->{(@cycles ||= Hash.new{|h,k|h[k] = [0, k]}; k = ["
      )
      compiler.on_arg_list(markup)
      compiler.raw(
        "]; i = @cycles[k][0] += 1; @cycles[k][1][(i - 1) % k.length])}.call"
      )
    end
  end
end
