require 'capistrano/ext/multistage'
require "rvm/capistrano"
require "bundler/capistrano"

set :normalize_asset_timestamps, false
set :stages, ["development","staging", "production"]
set :default_stage, "development"
set :bundle_without, [:darwin, :development, :test]

set :rvm_type, :user
set :rvm_ruby_string, 'ruby-1.9.2-p318@workers'

set :scm, :git
set :scm_passphrase, ""
set :application, "brightpush-scheduler"
set :deploy_to, "/var/www/brightpush-scheduler"
set :repository,  "git@bright.unfuddle.com:bright/brightpush-scheduler.git"
set :user, "ubuntu"
set :rack_env,"development"

# if you want to clean up old releases on each deploy uncomment this:
# after "deploy:restart", "deploy:cleanup"

# if you're still using the script/reaper helper you will need
# these http://github.com/rails/irs_process_scripts

# If you are using Passenger mod_rails uncomment this:
# namespace :deploy do
#   task :start do ; end
#   task :stop do ; end
#   task :restart, :roles => :app, :except => { :no_release => true } do
#     run "#{try_sudo} touch #{File.join(current_path,'tmp','restart.txt')}"
#   end
# end
 
 before 'deploy', 'rvm:install_ruby'
 
 after 'deploy:update_code', 'deploy:start_workers'
 namespace :deploy do
  desc "Starts the workers"
  task :start_workers, :roles => :app do
    run "cd #{release_path} && bundle install"
    run "cd #{release_path} && scripts/workers restart #{rack_env}"
  end
 end