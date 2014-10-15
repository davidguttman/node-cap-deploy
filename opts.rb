set :application, "appname"
set :application_port, "port"
role :app, "server.com"
set :repository, "git@github.com:davidguttman/#{application}.git"

set :node_version, '0.10.32'
