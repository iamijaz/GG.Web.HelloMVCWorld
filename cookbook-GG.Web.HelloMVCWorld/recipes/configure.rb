app_name = node['gg-web-hellomvcworld']['service_name']

template "#{ node['gg-web-hellomvcworld']['install_path'] }/web.config" do
  source "config.erb"
  variables({
  })  
end

execute "Set up the 32-bit mode" do
      timeout 5
      command "C:\\windows\\system32\\inetsrv\\appcmd set apppool #{app_name} -enable32BitAppOnWin64:true"
      only_if {
      output = %x{C:\\windows\\system32\\inetsrv\\appcmd list apppool #{app_name} /text:enable32BitAppOnWin64}
	  Chef::Log.info "32-mode: #{output.strip}"
   	  output.strip == "false"
    }
end