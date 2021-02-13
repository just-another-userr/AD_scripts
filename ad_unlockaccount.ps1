## Author: Patrick Kroll 

## Fill in/uncomment $adServer variable if the host will not change and comment out the prompt below
## $adServer = ''
$adServer = read-host -prompt "Enter the IP address of the AD server you would like to make changes in"
## $loginName = $domain + '\' ## $env:username

Write-Output 'Please enter your password for the domain'

$creds = Get-Credential ## $loginName
try {
    $credsTest = Get-ADComputer -Server $adServer -Credential $creds -Filter * | Select-Object -First 1
} 
catch {
    'The provided credentials were not accepted by the server, please enter a valid password for the username'
}   
while (!$credsTest) {

    $creds = Get-Credential ## $logonName
    try {
        $credsTest = Get-ADComputer -Server $adServer -Credential $creds -Filter *  | Select-Object -First 1
    } 
    catch {
        'The provided credentials were not accepted by the server, please enter a valid password for the username'
    }
}

## Gather user's name
$userName = Read-Host -Prompt 'Please enter the name of the user to unlock'
while ($userName -match '[$!~#%&*{}\\:<>?/|+"@_()]' -or $userName.Length -eq '0' -or $userName -eq ' ') {
    $userName = Read-Host -Prompt 'Please enter the name of the user to unlock'
}
## Get Samaccountname and reduce to a value we can pass to <Unlock-ADAccount>
$sam = Get-ADUser -Server $adServer -Credential $creds -filter {DisplayName -eq $userName} | Select-Object samaccountname
$useableSam = $sam.samaccountname

## Check to make sure $usableSam is not empty/null and loop to handle error 
while (!$useableSam) {
    $userName = Read-Host -Prompt "This user wasn't found, please enter the name of a user in the directory to unlock"
    $sam = Get-ADUser -Server $adServer -Credential $creds -filter {DisplayName -eq $userName} | Select-Object samaccountname
    $useableSam = $sam.samaccountname
}

## Try to unlock and handle any permissions errors 
try {
    Unlock-ADAccount -Server $adServer -Credential $creds -Identity $useableSam
}
catch {
    
    ## get better permissions kid
    if ($Error) { 
        write-output ' '
        write-output "You do not have sufficient privileges to unlock this account."
        Write-Output "Please reach out to the core team or an analyst for assistance"
        write-output ' '
        break
    } 
}

## 
write-output ' '
write-output "This account has been unlocked"
write-output ' '
[System.Threading.Thread]::Sleep(1500)