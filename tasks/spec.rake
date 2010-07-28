begin
  require "spec/rake/spectask"
  namespace :spec do
    namespace :plugins do
      desc "Runs the examples for redmine_reporting"
      Spec::Rake::SpecTask.new(:redmine_reporting) do |t|
        t.spec_opts = ['--options', "\"#{RAILS_ROOT}/spec/spec.opts\""]
        t.spec_files = FileList['vendor/plugins/redmine_reporting/spec/**/*_spec.rb']
      end
    end
  end
  task :spec => "spec:plugins:redmine_reporting"

  begin
     require 'ci/reporter/rake/rspec'     # use this if you're using RSpec
     require 'ci/reporter/rake/test_unit' # use this if you're using Test::Unit
     task :"spec:plugins:redmine_reporting:ci" => ["ci:setup:rspec", "spec:plugins:redmine_reporting"]
   rescue LoadError
     puts <<-EOS
       Missing the CI Reporter gem. This is not fatal.
       If you want XML output for the CI, execute

           gem install ci_reporter

     EOS
   end
rescue LoadError
end
