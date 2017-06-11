#
# Cookbook:: kitchen-example
# Recipe:: default
#
# Copyright:: 2017, The Authors, All Rights Reserved.

environment = node.chef_environment
role = 'role1'

# search for role1 host
host = search(:node, "roles:#{role} AND chef_environment:#{environment}").sort.first

file '/etc/special_config_with_search_data' do
  content host['ipaddress']
end
