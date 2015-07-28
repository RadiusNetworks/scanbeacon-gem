require "bundler/gem_tasks"
require "rake/extensiontask"

Rake::ExtensionTask.new "core_bluetooth" do |ext|
  ext.lib_dir = "lib/scan_beacon"
end

darwin_built_gem_path = nil
task :build do
  helper = Bundler::GemHelper.new
  ENV['GEM_OS'] = "darwin"
  darwin_built_gem_path = helper.build_gem
  ENV['GEM_OS'] = nil
end

task "release:rubygem_push" do
  helper = Bundler::GemHelper.new
  helper.rubygem_push(darwin_built_gem_path)
end

if RUBY_PLATFORM =~ /darwin/
  task("install").clear
  task "install" => :build do
    helper = Bundler::GemHelper.new
    helper.install_gem(darwin_built_gem_path)
  end
end
