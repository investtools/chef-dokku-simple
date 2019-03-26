#
# Cookbook Name:: dokku-simple
# Recipe:: default
#
# Copyright 2014, Ric Lister
#
# All rights reserved - Do Not Redistribute
#

include_recipe 'docker'

root = '/home/dokku'
vhost = node[:dokku][:vhost]

execute "echo 'dokku dokku/web_config boolean false' | debconf-set-selections"
execute "echo 'dokku dokku/key_file string /tmp/dokku.pub' | debconf-set-selections"
if vhost
  execute "echo 'dokku dokku/vhost_enable boolean true' | debconf-set-selections"
  execute "echo 'dokku dokku/hostname string #{vhost}' | debconf-set-selections"
end

file '/tmp/dokku.pub' do
  content node[:dokku][:public_key]
  mode 00600
end

apt_repository 'dokku' do
  uri         'https://packagecloud.io/dokku/dokku/ubuntu/'
  components  ['main']
  key         'https://packagecloud.io/gpg.key'
  distribution node['lsb']['codename']
end


package 'dokku' do
  version node[:dokku][:version]
  options '--force-yes'
end

## setup env vars for listed apps
node[:dokku][:apps].each do |app, cfg|

  directory File.join(root, app) do
    owner  'dokku'
    group  'dokku'
  end

  template File.join(root, app, 'ENV') do
    source 'ENV.erb'
    owner  'dokku'
    group  'dokku'
    variables(:env => cfg[:env] || {})
  end

end

## initial git push works better if we restart docker first
service 'docker' do
  provider Chef::Provider::Service::Upstart
  supports :status => true, :restart => true, :reload => true
  action [ :enable, :start ]
end
