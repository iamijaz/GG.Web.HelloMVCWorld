$install_path = "C:\wwwcom\GG.Web.HelloMVCWorld"
$name = "GG.Web.HelloMVCWorld"
$exe = "$install_path\bin\$name.dll"
try {
     
    Write-Host "starting"
     
    Import-Module WebAdministration
    try {
        Stop-WebAppPool $name
        Write-Host "Stopped app pool"
    }
    catch {
        Write-Host "Couldn't stop the app pool"
    }
     
    write-host "Check for previous install at path $install_path"
    if ((Test-path -path $install_path -pathtype container) -eq $true)
    {
        write-host "removing $install_path"
        rmdir -force -recurse $install_path
    }
     
    if ((Test-path -path $install_path -pathtype container) -eq $false)
    {  
        Write-Host "Creating folder"
        mkdir $install_path
    }
 
    $src =  $(Split-Path -parent $MyInvocation.MyCommand.Definition) + "\..\application\$name\*"
    Write-Host "Copying website from $src"
    copy-item -Recurse -Force $src $install_path\
 
    try {
        Start-WebAppPool $name
        Write-Host "Started app pool"
    }
    catch {
        Write-Host "Couldn't start the app pool"
    }
 
    Write-Host "Issuing IISReset"
    iisreset
 
    Write-ChocolateySuccess $name
}
catch
{
    Write-ChocolateyFailure $name $($_.Exception.Message)
    throw
}