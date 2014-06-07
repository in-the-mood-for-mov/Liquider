require 'bundler/gem_tasks'

desc "Build the parser"
task :parser do
  sh 'racc lib/liquider/liquid.y -o lib/liquider/generated_parser.rb'
end
