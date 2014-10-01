function Invoke-Build
{
	param($ApplicationName, $ChocolateyPackages = @(), $NugetPackages = @(), $task = "default")

	Write-Host "JustGiving Build Script Bootstrapper"
	Write-Host "Building application $ApplicationName"
	
	Remove-Item -Force -ErrorAction SilentlyContinue ".\jg-build-psake.ps1"
	Download-Url -Url "https://api.github.com/repos/JustGiving/GG.BuildScript/git/blobs/9cba6edbfc43ef7cc1ee121d6bafe5b37cd98f1a" "nuget.exe" -Destination ".\nuget.exe"
	Download-GitHub -Repo "GG.BuildScript" -Path "psake.psm1" -Destination ".\psake.psm1"
	Download-GitHub -Repo "GG.BuildScript" -Path "jg-build-psake.ps1" -Destination ".\jg-build-psake.ps1"

	Import-Module ".\psake.psm1"
	Invoke-psake .\jg-build-psake.ps1 -t $task -parameters @{"ApplicationName" = $ApplicationName; "ChocolateyPackages" = $ChocolateyPackages; "NugetPackages" = $NugetPackages }
}

function Download-GitHub($repo, $path, $destination)
{
	Download-Url -Url "https://api.github.com/repos/justgiving/$repo/contents/$($path)" -Destination $destination
}

function Download-Url($url, $destination)
{
	if ((Test-Path $destination) -eq $false)
	{
		Write-Host "Downloading file $url"
		$webClient = new-object net.webclient
		$webClient.Headers.Add("Accept", "application/vnd.github.3.raw")
		$webClient.Headers.Add("User-Agent", "JustGivingBuildScript")
		$webClient.DownloadFile("$($url)?access_token=b8d04243394ffcb43d4295fb066ca77a3bd1d443" ,$destination)
	}
}
