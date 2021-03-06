# Bundler tasks
require 'bundler/capistrano'
require 'capistrano_colors'
require File.expand_path('sexy_settings_config', File.dirname(__FILE__))

set :application, HowitzerStat.settings.application
set :repository,  "https://github.com/romikoops/howitzer_stat.git"
set :domain, HowitzerStat.settings.domain
set :deploy_via, :remote_cache
set :scm, :git

# do not use sudo
set :use_sudo, false
set(:run_method) { use_sudo ? :sudo : :run }

# This is needed to correctly handle sudo password prompt
default_run_options[:pty] = true

set :user, HowitzerStat.settings.user
set :group, user
set :runner, user
set :ssh_options, { :forward_agent => true }

role :web, domain
role :app, domain
role :db,  domain, :primary => true
set :rails_env, "production"
set :keep_releases, 5

# Where will it be located on a server?
set :deploy_to, HowitzerStat.settings.deploy_to
set :unicorn_conf, "#{deploy_to}/current/config/unicorn.rb"
set :unicorn_pid, "#{deploy_to}/shared/pids/unicorn.pid"

set :normalize_asset_timestamps, false

after "deploy:setup", :roles => :app do
  run "mkdir -p #{deploy_to}/shared/config"
  put YAML.dump(HowitzerStat.settings.custom), "#{deploy_to}/shared/config/custom.yml"
end

before 'deploy:create_symlink', :roles => :app do
  run "ln -s #{deploy_to}/shared/config/custom.yml #{current_release}/config/custom.yml"
end

# Unicorn control tasks
namespace :deploy do
  desc "restart unicorn"
  task :restart do
    run "if [ -f #{unicorn_pid} ]; then kill -USR2 `cat #{unicorn_pid}`; else cd #{deploy_to}/current && bundle exec unicorn -c #{unicorn_conf} -E #{rails_env} -D; fi"
  end
  desc "start unicorn"
  task :start do
    run "cd #{deploy_to}/current && bundle exec unicorn -c #{unicorn_conf} -E #{rails_env} -D"
  end
  desc "stop unicorn"
  task :stop do
    run "if [ -f #{unicorn_pid} ]; then kill -QUIT `cat #{unicorn_pid}`; fi"
  end
  desc "update custom.yml"
  task :update_config do
    put YAML.dump(HowitzerStat.settings.custom), "#{deploy_to}/shared/config/custom.yml"
  end
  desc "clean unicorn logs"
  task :clean_unicorn_logs do
    run "rm -f #{deploy_to}/current/log/unicorn*"
  end
end