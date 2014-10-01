param([string]$task = "local")
# Copy this file to start making use of the shared build script. Edit the ApplicationName, ChocolateyPackages and NugetPackages.
# Confluence documentation: https://justgiving.atlassian.net/wiki/display/DD/A%3A+Building+and+Testing+with+Shared+Build+Script+and+TeamCity

$ApplicationName = "GG.Example.Microservice"

#$ChocolateyPackages = @(
#	"GG.Example.Microservice.Web"
#)

#$NugetPackages = @(
#	"GG.Example.Microservice.Client"
#)

$webClient = new-object net.webclient
$webClient.Headers.Add("Accept", "application/vnd.github.3.raw")
$webClient.Headers.Add("User-Agent", "JustGivingBuildScript")
$webClient.DownloadFile('https://api.github.com/repos/justgiving/GG.BuildScript/contents/bootstrap.ps1?access_token=b8d04243394ffcb43d4295fb066ca77a3bd1d443','bootstrap.ps1')

. .\bootstrap.ps1

Invoke-Build -Task $task -ApplicationName $ApplicationName #-ChocolateyPackages $ChocolateyPackages -NugetPackages $NugetPackages