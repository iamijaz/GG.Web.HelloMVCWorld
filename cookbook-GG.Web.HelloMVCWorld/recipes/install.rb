::Chef::Recipe.send(:include, Chef::Mixin::PowershellOut)

marker_path = "C:\\chef-markers"

directory marker_path do
  action :create
end

windows_installed_marker = "#{marker_path}\\imageread-win-installed-#{run_context.cookbook_collection[cookbook_name].metadata.version}"

%w{ IIS-WebServerRole IIS-WebServer IIS-CommonHttpFeatures NetFx3ServerFeatures IIS-HttpRedirect IIS-LoggingLibraries IIS-RequestMonitor IIS-HttpTracing IIS-ISAPIExtensions IIS-IIS6ManagementCompatibility IIS-Metabase IIS-ISAPIFilter IIS-ISAPIExtensions NetFx3 NetFx4Extended-ASPNET45 IIS-NetFxExtensibility IIS-ASPNET IIS-NetFxExtensibility45 IIS-ASPNET45}.each do |feature|
  windows_feature feature do
    action :install
    not_if {::File.exists?("#{windows_installed_marker}") }
  end
end

file windows_installed_marker do
    action :create
end

install_path = node['gg-web-hellomvcworld']['install_path']
app_name = node['gg-web-hellomvcworld']['service_name']

iis_pool app_name do
    runtime_version "4.0"
    thirty_two_bit :true
    pipeline_mode :Integrated
    action :add
end

iis_site "Default Web Site" do
    action :delete
end

iis_site app_name do
    protocol :http
    port node['gg-web-hellomvcworld']['port']
    path install_path
    application_pool app_name
    action :add
end

Chef::Log.info "Installing #{ app_name }"
installing_version = run_context.cookbook_collection[cookbook_name].metadata.version
Chef::Log.info "To version #{installing_version}"

script = <<-EOH
			(Get-Item "#{ install_path }\\#{ node['gg-web-hellomvcworld']['executable_name'] }").VersionInfo.ProductVersion
	 		EOH
info = powershell_out(script);
current_version = info.stdout.strip
Chef::Log.info("Version before deployment #{current_version}")

chocolatey "vcredist2012_32bit" do 
  source node["gg-web-hellomvcworld"]["ChocolateySource"]
  version node['gg-web-hellomvcworld']['vcredist2012_32bit']['version']
  action :install
end

chocolatey app_name do 
	source node["gg-web-hellomvcworld"]["ChocolateySource"]
	version installing_version
	action :install
  notifies :start, "iis_site[#{app_name}]"
end