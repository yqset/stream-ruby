require "bundler/gem_tasks"
require 'rspec/core/rake_task'
require 'rake_helpers'


# This is a useful default task:
task :default do
  system "rake --tasks"
end

TEST_SUITES = [
  { :id => 'unit', :title => 'unit tests', :pattern => 'spec/unit'},
  { :id => 'integration', :title => 'integration tests', :pattern => 'spec/integration'}
]

namespace :test do
  TEST_SUITES.each do |suite|
    desc "run all tests in #{suite[:title]} suite"
    task "#{suite[:id]}" do
      Rake::Task["test:#{suite[:id]}:run"].execute
    end

    RSpec::Core::RakeTask.new("#{suite[:id]}:run") do |t|
      t.pattern       = suite[:pattern]
      t.verbose       = false
      t.fail_on_error = false
      rspec_opts = ["--require", "simplecov"]

      helpers = case suite[:id]
      when 'unit'
        File.join(File.dirname(__FILE__), 'spec/unit/unit_helper.rb')
      when 'integration'
        File.join(File.dirname(__FILE__), 'spec/integration/integration_helper.rb')
      end

      rspec_opts << ["--require", helpers]
      t.rspec_opts = rspec_opts.flatten
    end
  end
end

task :test do
  TEST_SUITES.each do |suite|
    Rake::Task["test:#{suite[:id]}"].invoke
  end
end
