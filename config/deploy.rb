set :application, "api"
set :repository,  "/Users/nikhilgupta/Sites/lab/whattheme/__#{application}"

set :scm, :git

set :user, "whatthem"
set :port, "22"

set :deploy_to, "/home/#{user}/rails_apps/whattheme_#{application}"
set :deploy_via, :copy

role :web, "#{application}.whattheme.net"

set :use_sudo, false
set :copy_exclude, [".git"]

after "deploy", "deploy:fix_perms"

namespace :deploy do
  task :fix_perms do
    run "#{try_sudo} chmod -R g-w #{deploy_to}/"
  end
end
