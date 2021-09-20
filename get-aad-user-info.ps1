# Set the string to filter the AAD user
$setStringToFilter = ""

# Authenticate to AzureAD
# Make sure that your account have enough permission
# And set the account default tenant that you are going to use
Connect-AzureAD

# Get all AD user and put in a variable for later use
$getAllAadUser = Get-AzureADUser -All $true

# Apply filter
$filteredAadUser = $getAllAadUser | Where {$_.UserPrincipalName -like "*$($setStringToFilter)*"}

# Create new file to store the information
$dataFile = New-Item -Path $env:USERPROFILE -Name "AAD-User-info-$(get-date -Format ddMMyyyy-hhmmss).csv" -Force

# Create form for object because "OtherMails" and "ProxyAddresses" is an array 
# and may not exist in user profile which can affect the header of csv file
# Create empty arrays
$arrCountOthMails = @()
$arrCountProxAdd = @()
# Loop through each user and append count into the arrays
foreach ($user in $filteredAadUser) {
  $countUserOthMails = $user.OtherMails.Count
  $arrCountOthMails += [int]$countUserOthMails
  $countUserProxAdds = $user.ProxyAddresses.Count
  $arrCountProxAdd += [int]$countUserProxAdds
}
# Get max value from the arrays
$maxCountOthMail = [int]($arrCountOthMails | Measure -Maximum).Maximum
$maxCountProxAdd = [int]($arrCountProxAdd | Measure -Maximum).Maximum

# Export information to file
foreach ($user in $filteredAadUser) {
  # object with static properties
  $objUserInfo = [PSCustomObject]@{
    DisplayName = $user.DisplayName
    UserPrincipalName = $user.UserPrincipalName
    UserType = $user.UserType
    CreationType = $User.CreationType
    AccountEnabled = $user.AccountEnabled
    Mail = $user.Mail
  }
  # Base on the max value, it will auto append the key and value even if value is null
  for ($i = 0; $i -lt $maxCountOthMail; $i++) {
    $keyName = "OtherMail$($i)"
    $objUserInfo | Add-Member NoteProperty $keyName $user.OtherMails[$i]
  }
  for ($i = 0; $i -lt $maxCountProxAdd; $i++) {
    $keyName = "ProxyAddress$($i)"
    $objUserInfo | Add-Member NoteProperty $keyName $user.ProxyAddresses[$i]
  }
  $objUserInfo | Export-Csv -Path $dataFile.FullName -Force -Append -NoTypeInformation
  Write-Output $objUserInfo
}