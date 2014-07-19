require 'bundler/gem_tasks'

task default: [:spec]

desc "Run Rspec examples"
task :spec do
  sh 'rspec spec'
end

desc "Build the parser"
task :parser do
  sh 'racc lib/liquider/liquid.y -o lib/liquider/generated_parser.rb'
end
