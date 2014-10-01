$install_path = "C:\wwwcom\GG.Web.HelloMVCWorld"
$name = "GG.Web.HelloMVCWorld"
try
{
  Remove-Item -Recurse -Force $install_path
  Write-ChocolateySuccess $name
} catch
{
  Write-ChocolateyFailure $name $($_.Exception.Message)
  throw
}