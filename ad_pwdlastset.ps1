## Check for pwdlastset and length of time until expiration 

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

Write-Output ' '
        ## Get user's name 
        $nameOfUser = Read-Host -Prompt "Please enter the name of a user to search for"
        Write-Output ' '
        
        try 
        {   ## Get the pwdLastSet attribute
            $time = get-aduser -Server $adServer -Credential $creds -Filter {DisplayName -eq $nameOfUser} -Properties * | Select-Object pwdLastSet
        }
        catch 
        { 
            if($Error) {
                ## Handle error
                Write-Output "There was an error gathering the date this password was last set. Please try again" 
                Write-Output ' '
                Read-Host -Prompt "Press Enter to continue" ; break
            } 
        }
        
            ## Convert to human readable format (still a string)
            $hrTime = w32tm.exe /ntte $time.pwdLastSet
        
            ## Perform string-fu on ugly $hrTime output
            $pos = $hrTime.IndexOf('-')
            $betterLookingTime = $hrTime.Substring($pos+2)
        
            Write-Output "This user last changed their password on $betterLookingTime"
            Write-Output ' '
            [System.Threading.Thread]::Sleep(1800)
        
            ##  Get today's date, convert the $hrTime string output to a datetime type, perform some math     ****** Make this a function ******* 
            $today = Get-Date
            $newBetterLookingTime = $betterLookingTime.Substring(0,10)
            $actualDateTypeBetterLookingTime = [datetime] $newBetterLookingTime
            $changeOn = $actualDateTypeBetterLookingTime.AddDays(90)
            $leftToChange = $changeOn - $today
            $toString = $leftToChange.ToString()
            $daysLeft = $toString.Substring(0,2)
        
            Write-Output "This user has $daysLeft days left before their password expires"
            [System.Threading.Thread]::Sleep(1800)
            Write-Output ' '
            Write-Output "You can select 'y' when prompted and option 3 to change the password if necessary" 
            Write-Output ' '
            [System.Threading.Thread]::Sleep(1500)
