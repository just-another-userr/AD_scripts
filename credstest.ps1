## Base creds test

## Author: Patrick Kroll 

$adServer = '192.168.4.22'
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