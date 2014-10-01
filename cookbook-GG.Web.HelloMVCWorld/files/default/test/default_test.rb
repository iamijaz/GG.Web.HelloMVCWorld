require 'minitest/spec'
 
describe_recipe 'default::test' do
 
  include Chef::Mixin::PowershellOut
  include MiniTest::Chef::Assertions
  include MiniTest::Chef::Context
  include MiniTest::Chef::Resources
 
 it "has copied the executable" do
    file("C:\\wwwcom\\GG.Web.HelloMVCWorld\\bin\\#{node['gg-web-hellomvcworld']['executable_name']}").must_exist     
end

it "created the config file" do
    file("#{ node['gg-web-hellomvcworld']['install_path'] }/web.config").must_exist
end
 
end