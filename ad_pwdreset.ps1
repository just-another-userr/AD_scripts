## Base reset AD passwords

## Author: Patrick Kroll 

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

## Get name of user 
$userName = Read-Host -Prompt 'Please enter the name of the user to reset the password for'
        
## Validate input is valid and re-prompt until input is valid
while ($userName -match '[$!~#%&*{}\\:<>?/|+"@_()]' -or $userName.Length -eq '0' -or $userName -eq ' ') {

    $userName = Read-Host -Prompt 'Please enter the name of the user to reset the password for'
}

## Get user attributes
$sam = Get-ADUser -Server $adServer -Credential $creds -filter "DisplayName -eq '$userName'" -Properties * | Select-Object samaccountname, Title, Department, Manager, Enabled, LockedOut

## Test to verify variable contains a value
while (!$sam) {

    $userName = Read-Host -Prompt "The user wasn't found in the directory, please enter a valid account name to proceed"
    $sam = Get-ADUser -Server $adServer -Credential $creds -filter "DisplayName -eq '$userName'" -Properties * | Select-Object samaccountname, Title, Department, Manager
}

## Trim to useable value for Set-ADAccountPassword
$useableSam = $sam.samaccountname 
if ($sam.Enabled -match 'True'){ 
    Write-Output ' ' ; "This user's account is Enabled"  
    [System.Threading.Thread]::Sleep(1500)
} else { 
    write-output ' ' 
    write-output "This user's account is Disabled. "
    write-output ' ' 
    write-output "Please follow the steps in KB0010178 to proceed." 
    write-output ' ' 
    write-output "If you have approval to re-enable, please log into $domain AD to continue."
    write-output ' ' 
    break 
}
if ($sam.LockedOut -match 'False')
{ Write-Output ' ' ; "This user's account is not locked"  
[System.Threading.Thread]::Sleep(1500)
} else { 
    write-output ' ' 
    write-output "This user's account is locked."
    Write-Output "Please restart the script and run option 1, then come back and run option 2 to continue"
    break 
}
            

if ($sam.Manager) {
    $ouPos = $sam.Manager.IndexOf(',')
    $eqPos = $sam.Manager.IndexOf('=')
    $manager = $sam.Manager.Substring($eqPos + 1, $ouPos - 3)
    Write-Output ' '
    Write-Output "Is the user able to verify any of the information below?"
    Write-Output ' '
    Write-output "Job Title:  $($sam.Title)" 
    Write-output "Department: $($sam.Department)"
    Write-output "Manager: $manager"
    Write-Output ' '
    $isValidated = Read-Host -Prompt "Enter 'y' for Yes or 'n' for No"
    while ($isValidated -notmatch '[yYnN]') {
        Write-Output "The input provided isn't accepted"
        $isValidated = Read-Host -Prompt "Enter 'y' for Yes or 'n' for No"
    }
    if ($isValidated -match '[nN]') {
        Write-Output ' '
        write-output "Please use the verify the email address of the user and proceed."
        break
    }
    else {
        ## Get new password and confirm + trim any accidental spaces on the ends
        $newPass1 = Read-Host -Prompt "Please enter a new password" 
        $newPass2 = Read-Host -Prompt "Please confirm the new password"
        $trimmedPass1 = $newPass1.Trim()
        $trimmedPass2 = $newPass2.Trim()
        while ($trimmedPass1 -ne $trimmedPass2) {
            Write-Output "The passwords don't match, please enter the passwords again"
            $newPass1 = Read-Host -Prompt "Please enter a new password"
            $trimmedPass1.Trim()
            $newPass2 = Read-Host -Prompt "Please reenter the password"
            $trimmedPass2.Trim()
        }
        try { 
            Set-ADAccountPassword -Server $adServer -Credential $creds -Identity $useableSam -Reset -NewPassword (ConvertTo-SecureString -AsPlainText $newPass1 -Force)
        }
        catch { write-output ' ' ; "There was an error while changing this user's password, please try again" }
        Write-Output ' '
        Write-Output "This user's password has been changed"
        Write-Output ' '
        break
    }
    ; break
}
else {                    
    [System.Threading.Thread]::Sleep(1500)
    Write-Output ' '
    Write-Output "Is the user able to verify any of the information below?"
    Write-Output ' '
    Write-output "Job Title:  $($sam.Title)" 
    Write-output "Department: $($sam.Department)"
    Write-Output ' '
    $isValidated = Read-Host -Prompt "Enter 'y' for Yes or 'n' for No"
    while ($isValidated -notmatch '[yYnN]') {
        Write-Output "The input provided isn't accepted"
        $isValidated = Read-Host -Prompt "Enter 'y' for Yes or 'n' for No"
    }
    if ($isValidated -match '[nN]') {
        Write-Output ' '
        write-output "Please log into $domain AD and locate something to identify this user with or have the user's manager call to reset this password "
        break
    }
    else {
        $newPass1 = Read-Host -Prompt "Please enter a new password" 
        $getTrimmed1 = $newPass1.Trim()
        $newPass2 = Read-Host -Prompt "Please reenter the password"
        $getTrimmed2 = $newPass2.Trim()

        while ($getTrimmed1 -ne $getTrimmed2) {
            Write-Output "The passwords don't match, please enter the passwords again"
            $newPass1 = Read-Host -Prompt "Please enter a new password"

            $newPass2 = Read-Host -Prompt "Please reenter the password"
        }
        try { 
            Set-ADAccountPassword -Server $adServer -Credential $creds -Identity $useableSam -Reset -NewPassword (ConvertTo-SecureString -AsPlainText $newPass1 -Force)
        }
        catch { 
            if($Error) {
            write-output ' '
            write-output "There was an error while changing this user's password, please log into $domain AD to proceed" 
            write-output ' '
            break
            }
        }
        Write-Output ' '
        Write-Output "This user's password has been changed"
        Write-Output ' '
        [System.Threading.Thread]::Sleep(1500)
    }
}