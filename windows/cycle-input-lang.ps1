# To run via shortcut / double click 
# powershell.exe -noLogo -ExecutionPolicy unrestricted -file "./next-lang-input.ps1"

$UserLangList = Get-WinUserLanguageList
$UserLangList.Add($UserLangList[0])
$UserLangList.RemoveAt(0)
Set-WinUserLanguageList $UserLangList -Force
