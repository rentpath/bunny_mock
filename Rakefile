require "bundler/gem_tasks"

begin
  require "midwire_common/rake_tasks"
rescue Exception => e
  puts ">>> Could not load 'midwire_common/rake_tasks': #{e}"
  exit
end

unless File.exists?("#{ENV['HOME']}/.gem/geminabox")
  puts ">>> Please configure geminabox first by running: [gem inabox -c]."
  exit
end

require 'rspec/core/rake_task'
RSpec::Core::RakeTask.new('spec')
task :default => :spec

module Bundler
  class GemHelper

    protected

    # Push the gem to our own internal gem server
    def rubygem_push(path)
      puts(">>> #{path}")
      sh("gem inabox '#{path}'")
      Bundler.ui.confirm "Pushed #{name} #{version} to http://gems.idg.primedia.com/"
    end
  end
end
