properties {
  $Build_Artifacts = 'output'
  $pwd = pwd
  $msbuild = "C:\Windows\Microsoft.NET\Framework\v4.0.30319\MSBuild.exe"
  $chocolateyPath = $env:ChocolateyInstall
  $cpack = if((Test-Path "$chocolateyPath\bin\cpack.bat") -eq $true){"$chocolateyPath\bin\cpack.bat"}else{"$chocolateyPath\bin\cpack.exe"}
  $cinst = if((Test-Path "$chocolateyPath\bin\cinst.bat") -eq $true){"$chocolateyPath\bin\cinst.bat"}else{"$chocolateyPath\bin\cinst.exe"}
  $nunit =  "$pwd\packages\NUnit.Runners.2.6.3\tools\nunit-console-x86.exe"
  $TestOutput = "$pwd\BuildOutput"
  $UnitTestOutputFolder = "$TestOutput\UnitTestOutput";
  $Company = "JustGiving";
  $version = Get-Version
  $year = Get-Year
  $Copyright = "$Company $year";
  $NugetUrls = @{"nuget" = "http://nuget.prod.justgiving.service/artifactory/api/nuget/int-nuget"; "chocolatey" = "http://packages.prod.justgiving.service/artifactory/api/nuget/int-chocolatey"}
  $NugetKeys = @{"nuget" = "pkgs:abc123"; "chocolatey" = "pkgs:abc123" }
  $NugetSource = "http://nuget.prod.justgiving.service/artifactory/api/nuget/all-nuget"
}

task default -depends Init, Clean, GetPackages, WriteNuspecNuget, WriteNuspecChocolatey, Compile, Test, PackageNuget, PackageChocolatey, PushNuget, PushChocolatey, UpdateCookbooks, PublishCookbooks, Cleanup
task local -depends Init, Clean, GetPackages, WriteNuspecNuget, WriteNuspecChocolatey, Compile, Test, PackageNuget, PackageChocolatey, Cleanup 
task publish -depends Init, Clean, GetPackages, WriteNuspecNuget, WriteNuspecChocolatey, Compile, Test, PackageNuget, PackageChocolatey, PushNuget, PushChocolatey, UpdateCookbooks, Cleanup

task EnsureAdmin { 
	Assert (([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) "Administrative permissions required"
}

task InstallChocolatey -depends EnsureAdmin {
  if ((Test-Path "$chocolateyPath" -pathType container) -ne $true) 
  {
    iex ((new-object net.webclient).DownloadString('https://chocolatey.org/install.ps1'))
  }
}

task InstallDotNet45 -depends EnsureAdmin {
  if ((Test-Path "$chocolateyPath\lib\DotNet4.5.4*" -pathType container) -ne $true) 
  {
    exec {& $cinst DotNet4.5}
    exec {& $cinst DotNet4.5.1}
  }
}

task Init -depends EnsureAdmin, InstallChocolatey, InstallDotNet45{
	Generate-AllAssemblyInfo
}

task Clean {
  Remove-Item -Force *.nupkg
  Remove-Item -Force -Recurse $TestOutput -ErrorAction SilentlyContinue
   
  while((test-path  $Build_Artifacts -pathtype container))
  {
	   rmdir -Force -Recurse $Build_Artifacts
	   Start-Sleep -Seconds 1
  }     
  while (Test-Path $TestOutput) 
  {
	   Remove-Item -force -recurse $TestOutput
	   Start-Sleep -Seconds 1
  }  
  Exec {  & $msbuild /m:4 /verbosity:quiet /nologo /p:OutDir=""$Build_Artifacts\"" /t:Clean "$(Get-FirstSlnFile)" }  
  
  Get-ChildItem * -recurse | Where-Object {$_.PSIsContainer -eq $True} | where-object {$_.Name -eq "output"} | where-object {$_.Fullname.Contains("output\") -eq $false}| Remove-Item -Force -Recurse -ErrorAction SilentlyContinue
}

task GetPackages {
  $sln = Get-FirstSlnFile
  Exec { .\nuget.exe restore "$sln" -OutputDirectory packages -source $nugetSource}
}

task WriteNuspecChocolatey -precondition { return ($ChocolateyPackages -ne $null) } {  
	foreach ($package in $ChocolateyPackages)
	{
		Write-Nuspec -PackageName $package
	}
}

task WriteNuspecNuget -precondition { return ($NugetPackages -ne $null) } {  	
	foreach ($package in $NugetPackages)
	{
		Write-Nuspec -PackageName $package
	}
}

function Write-Nuspec {
	param($packageName)
	Write-Host "Writing NuSpec with package name $packageName $version"
	
	$file = Get-Item "$packageName.nuspec"
	$x = [xml] (Get-Content $file)     
	$x.package.metadata.id = $packageName
	$x.package.metadata.title = $packageName
	$x.package.metadata.version = [string]$version
	$x.package.metadata.authors = $company
	$x.package.metadata.owners = $company
	$x.package.metadata.copyright = "$company $year"
	$x.package.metadata.summary = $packageName
	$x.package.metadata.tags = "tags"  
	$x.Save($file)    
}

task Compile {  
   Exec {  & $msbuild /m:4 /verbosity:quiet /nologo /p:OutDir=""$Build_Artifacts\"" /t:Rebuild /p:Configuration=Release "$(Get-FirstSlnFile)" }   	
}

task Test { 			
	$sinkoutput = mkdir $TestOutput -Verbose:$false;  
    $sinkoutput = mkdir $UnitTestOutputFolder -Verbose:$false;  
	
	$unitTestFolders = Get-ChildItem * -recurse | Where-Object {$_.PSIsContainer -eq $True} | where-object {$_.Fullname.Contains("output")} | where-object {$_.Fullname.Contains("output\") -eq $false}| select-object FullName
	#Write-Host $unitTestFolders
	foreach($folder in $unitTestFolders)
	{
		$x = [string] $folder.FullName
		copy-item -force -path $x\* -Destination "$UnitTestOutputFolder\" 
	}
	cd $UnitTestOutputFolder
	$TestAssemblies = Get-ChildItem -Path "$UnitTestOutputFolder\"  -Filter *.test.*.dll -Recurse

  Write-Host "Test assemblies: $TestAssemblies"

  if ([string]::IsNullOrEmpty($TestAssemblies))
  {
    return
  }
	
	if (Is-TCBuild -eq $true)
	{
		Write-Host "Using TC test runner $(Get-TCTestRunner) v4.0 x86 NUnit-2.6.2 $TestAssemblies"
		$tcr = Get-TCTestRunner
		Exec { & $tcr v4.0 x86 NUnit-2.6.2 $TestAssemblies }	
	}
	else 
	{
		Exec { & $nunit $TestAssemblies /nologo /labels /framework=net-4.0 }
	}
	cd $pwd	
}

task PackageChocolatey -precondition { return ($ChocolateyPackages -ne $null) } {   
   	foreach ($package in $ChocolateyPackages)
	{
		Create-Package -PackageName $package -IsChocolateyPackage $true
	}
}

task PackageNuget -precondition { return ($NugetPackages -ne $null) } {
	foreach ($package in $NugetPackages)
	{
		Create-Package -PackageName $package 
	}
}

function Create-Package{
	param($packageName, [bool]$IsChocolateyPackage = $false)
  cd $pwd 
	$fullFolder = "$Build_Artifacts\$packageName"
	$nuspec = "$packageName.nuspec"

  Write-Host "Copying nuget files for packaging from .\$packageName\output to $fullFolder"
		
	Copy-item -Recurse .\$packageName\output $fullFolder\
	Copy-item -Recurse -Force -Filter *.cs .\$packageName\ $Build_Artifacts\
	Copy-item $nuspec $fullFolder\
	#Create-IgnoreFiles -Path $fullFolder
	
	if ($IsChocolateyPackage -eq $true)
	{	
		Exec { & $cpack "$fullFolder\$nuspec" }
	}
	else 
	{
		Exec { .\NuGet.exe pack "$fullFolder\$nuspec" -BasePath $fullFolder -outputdirectory . -Symbols}
	}
}

task PushChocolatey -precondition { return ($ChocolateyPackages -ne $null) } {   
   	foreach ($package in $ChocolateyPackages)
	{
		Push-Package -PackageName $package -Type "chocolatey"
	}
}

task PushNuget -precondition { return ($NugetPackages -ne $null) } {
	foreach ($package in $NugetPackages)
	{
		Push-Package -PackageName $package -Type "nuget"
	}
}

task UpdateCookbooks {

    $configs = Get-ChildItem -recurse  | where-object {$_.Name.EndsWith(".Deployed.config.transformed") } `
                                       | where-object { !$_.FullName.Contains(".Test.")} `
                                       | where-object { !$_.FullName.Contains("\output\")} `
                                       | where-object { !$_.FullName.Contains("UnitTestOutput")}
    foreach ($path in $configs)
    { 
        if ($path.FullName -eq $null)
        {
            continue
        }  

        Write-Host "Found transformed config in $($path.FullName) using the Chef convention. Checking for matching cookbook..."
        $folder = Split-Path -parent $path.FullName
        $appname = $folder.substring($folder.lastindexof("\")+1, $folder.length - $folder.lastindexof("\")-1)
        Write-Host "Potential Chef-deployable application is $appname"
        $destinationCookbookTemplates = "$pwd\cookbook-$appname\templates\default"
        $destinationCookbookMetadata = "$pwd\cookbook-$appname\metadata.rb"
        Write-Host "Looking for cookbook template folder $destinationCookbookTemplates"

        if ((Test-Path -Path $destinationCookbookTemplates) -eq $false)
        {
            Write-Host "No chef cookbook found for $appname, aborting"
            continue
        }

        Write-Host "Creating .erb template from transformed app or web.config file..."
        Replace-StringsInFile -Source $path.FullName -Destination "$destinationCookbookTemplates\config.erb" -LookupTable @{'&gt;' = '>';'&lt;' = '<'}

        Write-Host "Patching version in cookbook metadata $destinationCookbookMetadata"
        Replace-StringsInFile -Source $destinationCookbookMetadata -Destination $destinationCookbookMetadata -LookupTable @{"\d+.\d+.\d+" = $version }
    }
}

task PublishCookbooks {

    $configs = Get-ChildItem -recurse  | where-object { $_.Name.EndsWith(".Deployed.config.transformed") } `
                                       | where-object { !$_.FullName.Contains(".Test.")} `
                                       | where-object { !$_.FullName.Contains("\output\")} `
                                       | where-object { !$_.FullName.Contains("UnitTestOutput")}
    foreach ($path in $configs)
    { 
        if ($path.FullName -eq $null)
        {
            continue
        }  

        Write-Host "Found transformed config in $($path.FullName) using the Chef convention. Checking for matching cookbook..."
        $folder = Split-Path -parent $path.FullName
        $appname = $folder.substring($folder.lastindexof("\")+1, $folder.length - $folder.lastindexof("\")-1)

        Write-Host "Potential Chef-deployable application is $appname"
        $destinationCookbookTemplates = "$pwd\cookbook-$appname\templates\default"

        if ((Test-Path -Path $destinationCookbookTemplates) -eq $false)
        {
            Write-Host "No chef cookbook found for $appname, aborting"
            continue
        }

        Write-Host "Executing berkshelf upload in $pwd\cookbook-$appname"
        cd "$pwd\cookbook-$appname"
        Remove-Item -Force -ErrorAction SilentlyContinue ".\Berksfile.lock"
        Remove-Item -Force -ErrorAction SilentlyContinue ".\metadata.json"
        exec { & berks install }  
        try
        {
          Exec {berks upload}
        }
        catch
        {
          write-host "berks upload failed, ignore and try again"
          Exec {berks upload}
        } 
        cd $pwd
    }
}

task Cleanup {
	$version = "1.0.0.0"
	foreach ($package in $NugetPackages)
	{
		Write-Nuspec -PackageName $package
	}
	foreach ($package in $ChocolateyPackages)
	{
		Write-Nuspec -PackageName $package
	}
	Generate-AllAssemblyInfo
}

function Push-Package
{
	param($packageName, $type)
	
	$url = $NugetUrls.Get_Item($type)
	$key = $NugetKeys.Get_Item($type)

	$packages = gci *.nupkg | Where-Object {$_.name.StartsWith("$packageName.$version")} | `
	Foreach-Object{ 

    if ($_.name.Contains("symbols") -eq $true)
    {
       continue
    }
		
    #if ($type -eq "chocolatey") 
    #{
    #   $dest = "$url/$packageName/$packageName"
    #}
    #else
    #{
    #   $dest = $url
    #}

    $dest = "$url/$packageName/$packageName"

    Write-Host "Pushing package $($_.name) to $dest..."
		Exec { .\nuget.exe push $_.name $key -Source $dest }
	}
}

task ? -Description "Helper to display task info" {
    Write-Documentation
}

function Create-IgnoreFiles {
  param($path)
  Get-ChildItem $path -Filter *.exe | `
  Foreach-Object{
    echo $null >  "$_.FullName" + ".ignore"
  }
}

function Get-FirstSlnFile {
   return @(Get-Item *.sln)[0]  
}

function Make-Folder {
  param($path)
  if ((Test-path -path $path -pathtype container) -eq $false)
  {   
    mkdir $path -Verbose:$false
  }
}

function Get-Version {
	$buildNumber = Get-BuildVersion 
  
	if ($buildNumber -ne $null)
	{
		Write-Host "Using TC build number $buildNumber";
		return $buildNumber
	}
	
    $year = (Get-Date -Format "yy").Substring(1,1)
	$t1 = Get-Date -format "MMdd"
    $t2 = Get-Date -format "Hmm"
	return "0.$year$t1.$t2"
}
function Get-BuildVersion {
  return $env:TC_BUILD_NUMBER
}

function Get-TCTestRunner {
  return $env:TC_NUNIT_RUNNER
}

function Generate-AllAssemblyInfo {
	$files = Get-ChildItem * -recurse | Where-Object {$_.Fullname.Contains("AssemblyInfo.cs")}
	foreach ($file in $files)
	{
		Generate-Assembly-Info `
        -file $file.Fullname `
        -title "$ApplicationName $version" `
        -description $ApplicationName `
        -company $Company `
        -product "$ApplicationName $version" `
        -version $version `
        -copyright $Copyright
	}
}

function Generate-Assembly-Info
{
param(
    [string]$clsCompliant = "true",
    [string]$title, 
    [string]$description, 
    [string]$company, 
    [string]$product, 
    [string]$copyright, 
    [string]$version,
    [string]$file = $(Throw "file is a required parameter.")
)
  $asmInfo = "using System;
using System.Reflection;
using System.Runtime.InteropServices;

[assembly: CLSCompliantAttribute($clsCompliant)]
[assembly: ComVisibleAttribute(false)]
[assembly: AssemblyTitleAttribute(""$title"")]
[assembly: AssemblyDescriptionAttribute(""$description"")]
[assembly: AssemblyCompanyAttribute(""$company"")]
[assembly: AssemblyProductAttribute(""$product"")]
[assembly: AssemblyCopyrightAttribute(""$copyright"")]
[assembly: AssemblyVersionAttribute(""$version"")]
[assembly: AssemblyInformationalVersionAttribute(""$version"")]
[assembly: AssemblyFileVersionAttribute(""$version"")]
[assembly: AssemblyDelaySignAttribute(false)]
"

    $dir = [System.IO.Path]::GetDirectoryName($file)
    if ([System.IO.Directory]::Exists($dir) -eq $false)
    {
        Write-Host "Creating directory $dir"
        [System.IO.Directory]::CreateDirectory($dir)
    }
   # Write-Host "Generating assembly info file: $file"
    out-file -filePath $file -encoding UTF8 -inputObject $asmInfo
}

function Get-Year {
  $yyyy = get-date -Format yyyy
  return "$yyyy" -replace "`n",", " -replace "`r",", "
}

function Is-TCBuild 
{
  Test-Path env:\TEAMCITY_VERSION 
}

function Replace-StringsInFile
{
    param($source, $destination, $lookupTable)

    if ($source -eq $destination)
    {
        $rename = $true
        $destination = "$destination.temp"
    }

    Get-Content -Path $source | ForEach-Object { 
        $line = $_

        $lookupTable.GetEnumerator() | ForEach-Object {
            if ($line -match $_.Key)
            {
                $line = $line -replace $_.Key, $_.Value
            }
        }
        $line
    } | Set-Content -Path $destination     

    if ($rename)
    {
        Remove-Item -Force $source
        Move-Item -Force "$source.temp" $source
    }
}
