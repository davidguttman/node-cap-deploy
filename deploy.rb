load "config/opts"

set :user, "deploy" # ssh user

set :scm, :git
set :scm_verbose, true
set :branch, "master"

set :use_sudo, false
set :ssh_options, { :forward_agent => true }

set :deploy_to, "/home/#{user}/#{application}" 
set :deploy_via, :remote_cache
set :keep_releases, 5

set :admin_runner, 'deploy' # user to run the application node_file as

set :node_bin, "/home/#{user}/.nvm/v#{node_version}/bin/node"
set :npm, "/home/#{user}/.nvm/v#{node_version}/bin/npm"

set :node_env, 'production'

set :log_file, "/home/#{user}/logs/#{application}.log"

default_run_options[:pty] = true

namespace :deploy do
  task :start, :roles => :app, :except => { :no_release => true } do
    run "sudo start #{application}"
  end

  task :stop, :roles => :app, :except => { :no_release => true } do
    run "sudo stop #{application}"
  end

  task :restart, :roles => :app, :except => { :no_release => true } do
    run "sudo restart #{application} || sudo start #{application}"
  end

  desc "Check required packages and install if packages are not installed"
  task :update_packages, roles => :app do
    run "cd #{release_path} && #{npm} install"
  end

  desc "create deployment directory"
  task :create_deploy_to, :roles => :app do
    run "mkdir -p #{deploy_to}"
  end
  
  desc "writes the upstart script for running the daemon. Customice to your needs"
  task :write_upstart_script, :roles => :app do
    upstart_script = <<-UPSTART
  description "#{application}"

  start on runlevel [2345]
  stop on shutdown

  script
      export HOME="/home/#{admin_runner}"
      cd #{current_path}

      exec sudo -u #{admin_runner} sh -c "\
      NODE_ENV=#{node_env} PORT=#{application_port} \
      #{node_bin} #{current_path}/#{node_file} \
      >> #{log_file} 2>&1"
  end script
  respawn
UPSTART
  put upstart_script, "/tmp/#{application}_upstart.conf"
    run "sudo mv /tmp/#{application}_upstart.conf /etc/init/#{application}.conf"
  end

end

namespace :node_modules do
  desc "create node modules directory"
  task :create_dir, :roles => :app do
    run "mkdir -p #{shared_path}/node_modules"
  end

  desc "make symlink for node modules"
  task :symlink, :roles => :app do
    run "ln -nfs #{shared_path}/node_modules #{release_path}/node_modules"
  end

end

namespace :db do
  desc "create leveldb directory"
  task :create_dir, :roles => :app do
    run "mkdir -p #{shared_path}/db"
  end

  desc "make symlink for leveldb"
  task :symlink, :roles => :app do
    run "rm -rf #{release_path}/db"
    run "ln -nfs #{shared_path}/db #{release_path}/db"
  end

end

namespace :node do
  desc "Install NVM"
  task :install_nvm do
    run "curl https://raw.github.com/creationix/nvm/master/install.sh | sh"
  end

  desc "Install Node Version"
  task :install_node_version do
    invoke_command "bash -c '. ~/.nvm/nvm.sh && nvm install #{node_version}'"
  end
end

namespace :git do

  desc "Delete remote cache"
  task :delete_remote_cache do
    run "rm -rf #{shared_path}/cached-copy"
  end

end

task :log do
  stream "tail -f #{log_file}"
end

before 'deploy:setup', 'deploy:create_deploy_to', 'node:install_nvm', 'node:install_node_version'
after 'deploy:setup', 'node_modules:create_dir', 'db:create_dir', 'deploy:write_upstart_script'

after "deploy:finalize_update", "node_modules:symlink", "db:symlink", "deploy:update_packages"