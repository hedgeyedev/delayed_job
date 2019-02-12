# Re-definitions are appended to existing tasks
task :environment
task :merb_env

namespace :jobs do
  desc "Clear the delayed_job queue."
  task :clear => [:merb_env, :environment] do
    Delayed::Job.delete_all
  end

  desc "Start a delayed_job worker."
  task :work => [:merb_env, :environment] do
    options = { :min_priority => ENV['MIN_PRIORITY'], :max_priority => ENV['MAX_PRIORITY'] }
    options[:queue] = ENV['QUEUE'] if ENV['QUEUE'].present?
    options[:excluded_queue] = ENV['EXCLUDED_QUEUE'] if ENV['EXCLUDED_QUEUE'].present?
    Delayed::Worker.new(options).start
  end
end
