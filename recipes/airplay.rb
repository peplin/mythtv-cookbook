#
# Cookbook Name:: mythtv
# Recipe:: airplay
#
# Copyright 2014, James Cuzella <james.cuzella@lyraphase.com>
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

# This recipe sets up Airplay support for mythfrontend
# For this to work, we need a RAOP key and user home directory to install it to.
# This should be the same user that you run mythfrontend with
# Source: http://www.mythtv.org/wiki/AirTunes/AirPlay

user = node[:mythtv][:raop_key][:user] # user set in cookbook attrubute
# user = node['current_user'] # user running chef cookbook (on provisioned host)

Chef::Log.error('For Airplay support, you must set node[:mythtv][:raop_key][:user] to the user you wish to install the RAOPKey for (e.g. The desktop user you run mythfrontend as)') if user.nil?

begin
  home = node['etc']['passwd'][user]['dir']
rescue NoMethodError
  Chef::Log.error("Could not determine home directory for user: #{user}")
ensure
  raise 'A desktop user and home directory must exist to install the Airplay RAOPKey' if home.nil?
end

directory "#{home}/.mythtv" do
  owner user
  group user
  mode 00755
  action :create
end

remote_file "#{home}/.mythtv/RAOPKey.rsa" do
  owner     user
  source    node[:mythtv][:raop_key][:url]
  checksum  node[:mythtv][:raop_key][:checksum]
  mode      0644
  action    :create
end

Chef::Log.info("Adding mythtv_airplay.sh to /etc/profile.d/")
file_contents = "# This file was generated by Chef for #{node["fqdn"]}\n"
file_contents += "export MYTHTV_AIRPLAY=1"

file "/etc/profile.d/mythtv_airplay.sh" do
  owner "root"
  group "root"
  mode 0644
  content file_contents
  action :create
end