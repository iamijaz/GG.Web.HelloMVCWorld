default['gg-web-hellomvcworld']['install_path'] = "C:\\wwwcom\\GG.Web.HelloMVCWorld"
default['gg-web-hellomvcworld']['executable_name'] = "GG.Web.HelloMVCWorld.dll"
default['gg-web-hellomvcworld']['service_name'] = "GG.Web.HelloMVCWorld"

#Config file parameters
default['gg-web-hellomvcworld']['port'] = 80

default['gg-web-hellomvcworld']['ChocolateySource'] = "http://packages.prod.justgiving.service/artifactory/api/nuget/int-chocolatey"

#Very important. Several deployment scripts rely on CookbookVersion being published
default['gg-web-hellomvcworld']['CookbookVersion'] = run_context.cookbook_collection['gg-web-hellomvcworld'].metadata.version

#Make environment monitoring tools aware that the standardised health check is available on /status/health. Include the GG.Internal.MonitoringComponents library to support this.
default['gg-web-hellomvcworld']['SupportsHealthCheck'] = false

#Make environment monitoring tools aware that this application uses the blue/green deployment model.
default['gg-web-hellomvcworld']['SupportsBlueGreen'] = true

default['gg-web-hellomvcworld']['vcredist2012_32bit']['version'] = "1.0.0.1"

default['gg-web-hellomvcworld']['ab_service'] = "http://ab.dev.aws.justgiving.service"

default['gg-web-hellomvcworld']['mainsite'] = "http://www.justgiving.com"
