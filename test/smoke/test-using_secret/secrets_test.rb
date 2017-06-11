# # encoding: utf-8

# Inspec test for recipe kitchen-example::using_secret

# The Inspec reference, with examples and extensive documentation, can be
# found at http://inspec.io/docs/reference/resources/

# This is an example test, replace it with your own test.
describe file('/etc/special_config_with_secret_data') do
  its('content') { should match /secret/ }
end
