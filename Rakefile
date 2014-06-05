require 'bundler/gem_tasks'
require 'rake/testtask'

Rake::TestTask.new do |t|
  t.libs << 'lib'
  t.libs << 'test'
  t.test_files = FileList['test/unit/test_*.rb']
  t.verbose = true
end

task :parser do
  sh 'racc lib/liquider/liquid.y -o lib/liquider/generated_parser.rb'
end
