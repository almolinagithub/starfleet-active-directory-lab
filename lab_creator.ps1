#Requires -RunAsAdministrator

# ---------------------------------------------------------------------------
# CUSTOM LAB CONFIGURATION
# Change these values to rename the domain, hosts, lab users, and lab folders.
# Example: LabRootName="ACME" => domain ACME.local and NetBIOS ACME.
# ---------------------------------------------------------------------------
$Global:LabDisplayName      = "Starfleet Active Directory Lab"
$Global:LabRootName         = "STARFLEET"
$Global:LabTld              = "local"
$Global:LabDomainFqdn       = "$($Global:LabRootName).$($Global:LabTld)"
$Global:LabDomainNetbios    = $Global:LabRootName
$Global:DomainDN            = (($Global:LabDomainFqdn).Split(".") | ForEach-Object { "DC=$_" }) -join ","

# Host names. Update these before building the corresponding virtual machines.
$Global:DCName              = "STARBASE-1"
$Global:Workstation1Name    = "ENTERPRISE-01"
$Global:Workstation2Name    = "VOYAGER-01"

$Global:DCLastOctet         = "250"
$Global:Workstation1Octet   = "220"
$Global:Workstation2Octet   = "221"
$Global:GatewayLastOctet    = "1"

$Global:ToolsRoot           = "C:\ADLab"
$Global:SharpHoundPath      = Join-Path $Global:ToolsRoot "Sharphound"
$Global:LocalAdministratorPassword = "Password1"
$Global:DirectoryServicesRestoreModePassword = "P@$$w0rd!"

# Lab accounts. Changing a value here updates account creation, domain joining, and logon instructions.
$Global:User1DisplayName    = "James T. Kirk"
$Global:User1GivenName      = "James"
$Global:User1Surname        = "Kirk"
$Global:User1SamAccountName = "jkirk"
$Global:User1Password       = "Password2"

$Global:User2DisplayName    = "Spock"
$Global:User2GivenName      = "Spock"
$Global:User2Surname        = ""
$Global:User2SamAccountName = "spock"
$Global:User2Password       = "Password1"

$Global:User3DisplayName    = "Leonard McCoy"
$Global:User3GivenName      = "Leonard"
$Global:User3Surname        = "McCoy"
$Global:User3SamAccountName = "lmccoy"
$Global:User3Password       = "Password2019!@#"

$Global:ServiceAccountDisplayName    = "Data"
$Global:ServiceAccountGivenName      = "Data"
$Global:ServiceAccountSurname        = ""
$Global:ServiceAccountSamAccountName = "data"
$Global:ServiceAccountPassword       = "MYpassword123#"

# Backward-compatible variable used in a few functions.
$Global:Domain              = $Global:LabDomainFqdn

# Active Directory lab build script.
#
# Auto-configured IP addresses:
# - Domain Controller: x.x.x.250
# - Workstation 1: x.x.x.220
# - Workstation 2: x.x.x.221
# - DNS on Domain Controller: 127.0.0.1
# - DNS on Workstations: Domain Controller IP
#
function check_ipaddress {
  $CheckIPAddress=Get-NetIPAddress -AddressFamily IPv4 -InterfaceIndex $(Get-NetConnectionProfile | Select-Object -ExpandProperty InterfaceIndex) | Select-Object -ExpandProperty IPAddress
  # Split the IP address into octets.
  $CheckIPByte = $CheckIPAddress.Split(".")
  
  # Check the first two IP address octets.
  if ($CheckIPByte[0] -eq "169" -And $CheckIPByte[1] -eq "254") 
   { write-host("`n [ ERROR ] - $CheckIPaddress is a LinkLocal Adress, Check your Hypervisor configuration `n`n")
     exit } 
  # Continue when the address is not in the link-local range.
  }

# Configure Microsoft Defender preferences.
function set_mppref {
  # Keep this in a separate function so it runs once per machine build.
  Set-MpPreference -DisableRealtimeMonitoring $true | Out-Null
  Set-MpPreference -DisableRemovableDriveScanning $true | Out-Null
  Set-MpPreference -DisableArchiveScanning  $true | Out-Null
  Set-MpPreference -DisableAutoExclusions  $true | Out-Null
  Set-MpPreference -DisableBehaviorMonitoring  $true | Out-Null
  Set-MpPreference -DisableBlockAtFirstSeen $true | Out-Null
  Set-MpPreference -DisableCatchupFullScan  $true | Out-Null
  Set-MpPreference -DisableCatchupQuickScan $true | Out-Null
  Set-MpPreference -DisableEmailScanning $true | Out-Null
  Set-MpPreference -DisableIntrusionPreventionSystem  $true | Out-Null
  Set-MpPreference -DisableIOAVProtection  $true | Out-Null
  Set-MpPreference -DisablePrivacyMode  $true | Out-Null
  Set-MpPreference -DisableRealtimeMonitoring  $true | Out-Null
  Set-MpPreference -DisableRemovableDriveScanning  $true | Out-Null
  Set-MpPreference -DisableRestorePoint  $true | Out-Null
  Set-MpPreference -DisableScanningMappedNetworkDrivesForFullScan  $true | Out-Null
  Set-MpPreference -DisableScanningNetworkFiles  $true | Out-Null
  Set-MpPreference -DisableScriptScanning $true | Out-Null
  }
  # End Defender preference configuration.

# Disable Microsoft Defender and related protections.
function nukedefender { 
  $ErrorActionPreference = "SilentlyContinue"

  # Disable UAC, the firewall, and Microsoft Defender.
  write-host("`n  [++] Nuking Defender")

  reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" /f /v EnableLUA /t REG_DWORD /d 0 > $null
  reg add "HKLM\System\CurrentControlSet\Services\SecurityHealthService" /v "Start" /t REG_DWORD /d "4" /f > $null

  # Optionally remove the existing Defender policy registry key.
  # reg delete "HKLM\Software\Policies\Microsoft\Windows Defender" /f > $null
  
  # Disable Microsoft Defender antivirus features.
  reg add "HKLM\Software\Policies\Microsoft\Windows Defender" /v "DisableAntiSpyware" /t REG_DWORD /d "1" /f > $null
  reg add "HKLM\Software\Policies\Microsoft\Windows Defender" /v "DisableAntiVirus" /t REG_DWORD /d "1" /f > $null
  reg add "HKLM\Software\Policies\Microsoft\Windows Defender\MpEngine" /v "MpEnablePus" /t REG_DWORD /d "0" /f > $null
  reg add "HKLM\Software\Policies\Microsoft\Windows Defender\Real-Time Protection" /v "DisableBehaviorMonitoring" /t REG_DWORD /d "1" /f > $null
  reg add "HKLM\Software\Policies\Microsoft\Windows Defender\Real-Time Protection" /v "DisableIOAVProtection" /t REG_DWORD /d "1" /f > $null
  reg add "HKLM\Software\Policies\Microsoft\Windows Defender\Real-Time Protection" /v "DisableOnAccessProtection" /t REG_DWORD /d "1" /f > $null
  reg add "HKLM\Software\Policies\Microsoft\Windows Defender\Real-Time Protection" /v "DisableRealtimeMonitoring" /t REG_DWORD /d "1" /f > $null
  reg add "HKLM\Software\Policies\Microsoft\Windows Defender\Real-Time Protection" /v "DisableScanOnRealtimeEnable" /t REG_DWORD /d "1" /f > $null
  reg add "HKLM\Software\Policies\Microsoft\Windows Defender\Real-Time Protection" /v "DisableScriptScanning" /t REG_DWORD /d "1" /f > $null 
  reg add "HKLM\Software\Policies\Microsoft\Windows Defender\Reporting" /v "DisableEnhancedNotifications" /t REG_DWORD /d "1" /f > $null
  reg add "HKLM\Software\Policies\Microsoft\Windows Defender\SpyNet" /v "DisableBlockAtFirstSeen" /t REG_DWORD /d "1" /f > $null
  reg add "HKLM\Software\Policies\Microsoft\Windows Defender\SpyNet" /v "SpynetReporting" /t REG_DWORD /d "0" /f > $null
  reg add "HKLM\Software\Policies\Microsoft\Windows Defender\SpyNet" /v "SubmitSamplesConsent" /t REG_DWORD /d "2" /f > $null
  reg add "HKLM\System\CurrentControlSet\Control\WMI\Autologger\DefenderApiLogger" /v "Start" /t REG_DWORD /d "0" /f > $null
  reg add "HKLM\System\CurrentControlSet\Control\WMI\Autologger\DefenderAuditLogger" /v "Start" /t REG_DWORD /d "0" /f > $null
    
  # Disable Defender-related scheduled tasks.
  write-host("`n  [++] Nuking Defender Related Services")
  schtasks /Change /TN "Microsoft\Windows\ExploitGuard\ExploitGuard MDM policy Refresh" /Disable > $null
  schtasks /Change /TN "Microsoft\Windows\Windows Defender\Windows Defender Cache Maintenance" /Disable > $null
  schtasks /Change /TN "Microsoft\Windows\Windows Defender\Windows Defender Cleanup" /Disable > $null
  schtasks /Change /TN "Microsoft\Windows\Windows Defender\Windows Defender Scheduled Scan" /Disable > $null
  schtasks /Change /TN "Microsoft\Windows\Windows Defender\Windows Defender Verification" /Disable > $null

  # Disable Windows Update and automatic updates.
  write-host("`n  [++] Stopping Windows Update service")
  Get-Service -Name 'wuauserv' | Stop-Service -Force
  write-host("`n  [++] Disabling Windows Update service")
  Get-Service -Name 'wuauserv' | Set-Service -StartupType Disabled
  write-host("`n  [++] Nuking Windows Update")
  reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" /v "NoAutoUpdate" /t REG_DWORD /d "1" /f > $null

  # Disable remote UAC to avoid RPC access-denied errors during lab operations.
  write-host("`n  [++] Nuking UAC and REMOTE UAC")
  reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" /v "LocalAccountTokenFilterPolicy" /t REG_DWORD /d "1" /f > $null

  # Enable ICMP echo for IPv4 and IPv6.
  write-host("`n  [++] Enabling ICMP ECHO on IPv4 and IPv6")
  netsh advfirewall firewall add rule name="ICMP Allow incoming V4 echo request" protocol=icmpv4:8,any dir=in action=allow > $null
  netsh advfirewall firewall add rule name="ICMP Allow incoming V6 echo request" protocol=icmpv6:8,any dir=in action=allow > $null

  # Enable Network Discovery.
  write-host("`n  [++] Enabling Network Discovery")
  Get-NetFirewallRule -Group '@FirewallAPI.dll,-32752' |Set-NetFirewallRule -Profile 'Private, Domain' `
  -Enabled true -PassThru|Select-Object Name,DisplayName,Enabled,Profile|Format-Table -a | Out-Null

  # Disable public, private, and domain firewall profiles on servers and workstations.
  write-host("`n  [++] Disabling Windows Defender Firewalls : Public, Private, Domain")
  Set-NetFirewallProfile -Profile Domain, Public, Private -Enabled False | Out-Null
  
  # Enable dark mode.
  write-host("`n  [++] Quality of life improvement - Dark Theme")
  # Set-ItemProperty -Path "HKEY_CURRENT_USER\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize" -Name "AppsUseLightTheme" -Value 0 
  reg add "HKEY_CURRENT_USER\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize" /v "AppsUseLightTheme" /t REG_DWORD /d "0" /f > $null
  reg add "HKEY_CURRENT_USER\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize" /v "SystemUsesLightTheme" /t REG_DWORD /d "0" /f > $null

  # Disable the screen lock and timeout.
  write-host("`n  [++] Quality of life improvement - Disable ScreenSaver, ScreenLock and Timeout")
  reg add  "HKEY_CURRENT_USER\Software\Policies\Microsoft\Windows\Control Panel\Desktop" /v "ScreenSaveTimeOut" /t REG_DWORD /d "0" /f > $null 
  reg add  "HKEY_CURRENT_USER\Software\Policies\Microsoft\Windows\Control Panel\Desktop" /v "ScreenSaveActive" /t REG_DWORD /d "0" /f > $null
  reg add  "HKEY_CURRENT_USER\Software\Policies\Microsoft\Windows\Control Panel\Desktop" /v "ScreenSaverIsSecure" /t REG_DWORD /d "0" /f > $null
  }
  # End Defender configuration.

# Remove installed Windows updates.
function remove_all_updates {
  Get-WmiObject -query "Select HotFixID  from Win32_QuickFixengineering" | sort-object -Descending -Property HotFixID|ForEach-Object{
    $sUpdate=$_.HotFixID.Replace("KB","")
    write-host ("Uninstalling update "+$sUpdate);
    & wusa.exe /uninstall /KB:$sUpdate /quiet /norestart;
    Wait-Process wusa 
    Start-Sleep -s 1 }
  }
  # End update removal.

# Configure SQL Service Principal Names.
function fix_setspn {
  $FullDomainName=((Get-WmiObject Win32_ComputerSystem).Domain)
  $ShortDomainName=((Get-WmiObject Win32_ComputerSystem).Domain).Split(".")[0]
  $machine=$env:COMPUTERNAME
  $serviceAccount = "$ShortDomainName\$($Global:ServiceAccountSamAccountName)"
  write-host("`n  [++] Deleting Existing SPNs")
 
  setspn -D SQLService/$FullDomainName $machine > $null
  setspn -D SQLService/$FullDomainName $serviceAccount > $null
  setspn -D $machine/SQLService`.$FullDomainName`:60111 $serviceAccount > $null
  setspn -D $ShortDomainName/SQLService.$FullDomainName:60111 $serviceAccount > $null
  setspn -D $Global:DCName/SQLService.$FullDomainName:60111 $serviceAccount > $null

  # Add the required SPN.
  write-host("`n  [++] Adding SPNs")
 
 setspn -A $machine/SQLService.$FullDomainName`:60111 $serviceAccount > $null
 setspn -A SQLService/$FullDomainName $serviceAccount > $null
 setspn -A $Global:DCName/SQLService.$FullDomainName`:60111 $serviceAccount > $null

  # Verify local and domain SPNs.
  write-host("`n  [++] Checking Local $Global:DCName SPN")
  setspn -L $machine 
  write-host("`n  [++] Checking $serviceAccount SPN")
  setspn -L $serviceAccount
  }
  # End SPN configuration.

# Configure the Active Directory Certificate Services certification authority.
function fix_adcsca {
  write-host ("`n  [++] Removing ADCSCertificateAuthority")
  # Install-WindowsFeature ADCS-Cert-Authority -IncludeManagementTools
  Install-AdcsCertificationAuthority -Force | Out-Null
  write-host ("`n  [++] Installing new ADCSCertificateAuthority `n")
  Install-AdcsCertificationAuthority -CAType EnterpriseRootCa -CryptoProviderName "RSA#Microsoft Software Key Storage Provider" `
  -KeyLength 2048 -HashAlgorithmName SHA256 -ValidityPeriod Years -ValidityPeriodUnits 99 -WarningAction SilentlyContinue -Force | Out-Null 
  # This step may not be required.
  #Read-Host -Prompt "`n Press ENTER to continue..."
  #restart-computer 
  }
  # End certification authority configuration.

# Build the Active Directory lab.
function build_lab {
  $ErrorActionPreference = "SilentlyContinue"
  write-host("`n  When prompted you are being logged out simply click the Close button")
  remove_all_updates 

  # Prevent Server Manager from launching at startup.
  write-host("`n  [++] Disabling Server Manager from launching on startup ")
  Get-ScheduledTask -TaskName ServerManager | Disable-ScheduledTask | Out-Null

  # Download and install the latest version of Git.
  setup_git

  # Configure FDResPub for Network Discovery in File Explorer.
  # write-host("`n  [++] Setting Registry key: FDResPub")
  # reg add "HKLM\SYSTEM\CurrentControlSet\Services\FDResPub" /f /v DependOnService /t REG_MULTI_SZ /d "RpcSs\0http\0fpdhost\0LanmanWorkstation"
  # red add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Run" /f /v sc_fdrespub /t REG_EXPAND_SZ /d "sc config fdrespub depend= RpcSs/http/fdphost/LanmanWorkstation"
  
  # Install Active Directory Domain Services.
  write-host("`n  [++] Installing Active Directory Domain Services (ADDS)")
  Install-windowsfeature -name AD-Domain-Services -IncludeManagementTools -WarningAction SilentlyContinue | Out-Null

  # Import the Active Directory module.
  write-host("`n  [++] Importing Module ActiveDirectory")
  Import-Module ActiveDirectory -WarningAction SilentlyContinue | Out-Null

  # Install AD DS.
  write-host("`n  [++] Installing ADDS Domain : $($Global:LabDomainFqdn) ")
  Install-ADDSDomain -SkipPreChecks -ParentDomainName $Global:LabDomainNetbios -NewDomainName $Global:LabTld -NewDomainNetbiosName $Global:LabDomainNetbios `
  -InstallDns -SafeModeAdministratorPassword (Convertto-SecureString -AsPlainText $Global:DirectoryServicesRestoreModePassword -Force) -Force -WarningAction SilentlyContinue | Out-Null

  # Create an AD DS forest using the configured lab domain.
  write-host("`n  [++] Deploying Active Directory Domain Forest in $($Global:LabDomainFqdn)")
  Install-ADDSForest -SkipPreChecks -CreateDnsDelegation:$false -DatabasePath "C:\Windows\NTDS" `
  -DomainMode "WinThreshold" -DomainName $Global:LabDomainFqdn -DomainNetbiosName $Global:LabDomainNetbios `
  -ForestMode "WinThreshold" -InstallDns:$true -LogPath "C:\Windows\NTDS" -NoRebootOnCompletion:$false `
  -SysvolPath "C:\Windows\SYSVOL" -Force:$true `
  -SafeModeAdministratorPassword (Convertto-SecureString -AsPlainText $Global:DirectoryServicesRestoreModePassword -Force) -WarningAction SilentlyContinue | Out-Null

  write-host("`n  Note: Do NOT REBOOT MANUALLY - Let me reboot on my own! I am A BIG COMPUTER NOW!! I GOT THIS!! `n")
  }
  # End lab build.

# Configure SMB signing.
function smb_signing {
  # Enable SMB signing without requiring it.
  write-host("`n  [++] Setting Registry Keys SMB Signing Enabled but not Required")
  reg add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\LanmanWorkstation\Parameters" /v "RequireSecuritySignature" /t REG_DWORD /d "0" /f > $null
  reg add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\LanmanServer\Parameters" /v "RequireSecuritySignature" /t REG_DWORD /d "0" /f > $null
  }
  # End SMB signing configuration.

function get_sharphound {
  $source_url = "https://github.com/BloodHoundAD/SharpHound/releases/download/v1.1.1/SharpHound-v1.1.1.zip"
  New-Item -ItemType Directory -Path $Global:SharpHoundPath -Force | Out-Null
  $destination_path = $Global:SharpHoundPath
  Start-BitsTransfer -Source $source_url -Destination $destination_path 
  Expand-Archive -Path $destination_path\SharpHound-v1.1.1.zip -DestinationPath $destination_path -Force
  write-host("`n  [++] Installed Sharphound.exe to $destination_path ")
  }  

# Create Active Directory lab content.
function create_labcontent {
  $ErrorActionPreference = "SilentlyContinue"
  
  # Install Active Directory Certificate Services.
  write-host("`n  [++] Installing Active Directory Certificate Services")
  Add-WindowsFeature -Name AD-Certificate -IncludeManagementTools -WarningAction SilentlyContinue | Out-Null
  
  # Install the Active Directory Certificate Authority role.
  write-host("`n  [++] Installing Active Directory Certificate Authority")
  Add-WindowsFeature -Name Adcs-Cert-Authority -IncludeManagementTools -WarningAction SilentlyContinue | Out-Null

  # Configure the Active Directory Certificate Authority.
  write-host("`n  [++] Configuring Active Directory Certificate Authority")
  # fix_adcsca
  Install-AdcsCertificationAuthority -CAType EnterpriseRootCa -CryptoProviderName "RSA#Microsoft Software Key Storage Provider" `
  -KeyLength 2048 -HashAlgorithmName SHA1 -ValidityPeriod Years -ValidityPeriodUnits 99 -WarningAction SilentlyContinue -Force | Out-Null

  # Install Remote System Administration Tools.
  write-host("`n  [++] Installing Remote System Administration Tools (RSAT)")
  Add-WindowsCapability -Online -Name Rsat.ActiveDirectory.DS-LDS.Tools~~~~0.0.1.0 -WarningAction SilentlyContinue | Out-Null

  # Install the AD CS RSAT management tools.
  write-host("`n  [++] Installing RSAT-ADCS and RSAT-ADCS-Management")
  Add-WindowsFeature RSAT-ADCS,RSAT-ADCS-mgmt -WarningAction SilentlyContinue | Out-Null

  # Create the shared lab folder and SMB share.
  write-host("`n  [++] Creating Share C:\Share\hackme - Permissions Everyone FullAccess")
  mkdir C:\Share\hackme > $null
  New-SmbShare -Name "hackme" -Path "C:\Share\hackme" -ChangeAccess "Users" -FullAccess "Everyone" -WarningAction SilentlyContinue | Out-Null

  # Apply the SMB signing configuration.
  smb_signing

  # Configure the Point and Print settings for the lab scenario.
  write-host("`n  [++] Setting Registry Keys for PrinterNightmare")
  reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows NT\Printers\PointAndPrint" /v "NoWarningNoElevationOnInstall" /t REG_DWORD /d "1" /f > $null
  reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows NT\Printers\PointAndPrint" /v "RestrictDriverInstallationToAdministrators" /t REG_DWORD /d "0" /f > $null

  # Configure LocalAccountTokenFilterPolicy.
  write-host("`n  [++] Setting Registry Key for LocalAccountTokenFilterPolicy")
  reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\system" /v "LocalAccountTokenFilterPolicy" /t REG_DWORD /d "1" /f > $null

  # Configure AlwaysInstallElevated.
  write-host("`n  [++] Setting Registry Key for AlwaysInstallElevated")
  reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\Installer" -v "AlwaysInstallElevated" /t REG_DWORD /d "1" /f > $null 

  # LAPS
  # wget https://download.microsoft.com/download/C/7/A/C7AAD914-A8A6-4904-88A1-29E657445D03/LAPS.x64.msi
  # .\Laps.x64.msi
  # Import-module AdmPwd.PS
  # Update-AdmPwdADSchema
  
  # The following optional DNS configuration may affect IPv6 connectivity.
  #$adapter=Get-CimInstance -Class Win32_NetworkAdapter -Property NetConnectionID,NetConnectionStatus | Where-Object { $_.NetConnectionStatus -eq 2 } | Select-Object -Property NetConnectionID -ExpandProperty NetConnectionID
  #write-host("`n  [++] Setting DNS Server to 127.0.0.1 on interface $adapter")
  #Set-DNSClientServerAddress "$adapter" -ServerAddresses ("127.0.0.1") | Out-Null

  # Create the first standard lab user.
  New-ADUser -Name $Global:User1DisplayName -GivenName $Global:User1GivenName -Surname $Global:User1Surname -SamAccountName $Global:User1SamAccountName `
  -UserPrincipalName "$($Global:User1SamAccountName)@$($Global:LabDomainFqdn)" -Path $Global:DomainDN `
  -AccountPassword (ConvertTo-SecureString $Global:User1Password -AsPlainText -Force) `
  -PasswordNeverExpires $true -PassThru | Enable-ADAccount  | Out-Null
  Write-Host "`n  [++] User: $($Global:User1DisplayName) added, Logon: $($Global:User1SamAccountName) Password: $($Global:User1Password)"
  Write-Host "        Adding $($Global:User1DisplayName) to $($Global:LabDomainFqdn) Groups: Domain Users"

  # Create the second standard lab user.
  New-ADUser -Name $Global:User2DisplayName -GivenName $Global:User2GivenName -Surname $Global:User2Surname -SamAccountName $Global:User2SamAccountName `
  -UserPrincipalName "$($Global:User2SamAccountName)@$($Global:LabDomainFqdn)" -Path $Global:DomainDN `
  -AccountPassword (ConvertTo-SecureString $Global:User2Password -AsPlainText -Force) `
  -PasswordNeverExpires $true -PassThru | Enable-ADAccount  | Out-Null

  # Add the second user to Domain Admins for the intended lab scenario.
  Add-ADGroupMember -Identity "Domain Admins" -Members $Global:User2SamAccountName | Out-Null
  Write-Host "`n  [++] User: $($Global:User2DisplayName) added, Logon: $($Global:User2SamAccountName) Password: $($Global:User2Password)"
  Write-Host "        Adding $($Global:User2DisplayName) to $($Global:LabDomainFqdn) Groups: Domain Users, Domain Admins"

  # Create the privileged lab user used to join workstations to the domain.
  New-ADUser -Name $Global:User3DisplayName -GivenName $Global:User3GivenName -Surname $Global:User3Surname -SamAccountName $Global:User3SamAccountName `
  -UserPrincipalName "$($Global:User3SamAccountName)@$($Global:LabDomainFqdn)" -Path $Global:DomainDN `
  -AccountPassword (ConvertTo-SecureString $Global:User3Password -AsPlainText -Force) `
  -PasswordNeverExpires $true -PassThru | Enable-ADAccount | Out-Null

  Add-ADGroupMember -Identity "Administrators" -Members $Global:User3SamAccountName
  Add-ADGroupMember -Identity "Domain Admins" -Members $Global:User3SamAccountName
  Write-Host "`n  [++] User: $($Global:User3DisplayName) added, Logon: $($Global:User3SamAccountName) Password: $($Global:User3Password)"
  Write-Host "        Adding $($Global:User3DisplayName) to $($Global:LabDomainFqdn) Groups: Administrators, Domain Admins"

  # Create the SQL service account.
  New-ADUser -Name $Global:ServiceAccountDisplayName -GivenName $Global:ServiceAccountGivenName -Surname $Global:ServiceAccountSurname -SamAccountName $Global:ServiceAccountSamAccountName `
  -UserPrincipalName "$($Global:ServiceAccountSamAccountName)@$($Global:LabDomainFqdn)" -Path $Global:DomainDN `
  -AccountPassword (ConvertTo-SecureString $Global:ServiceAccountPassword -AsPlainText -Force) `
  -PasswordNeverExpires $true -Description "Password is $($Global:ServiceAccountPassword)" -PassThru | Enable-ADAccount | Out-Null

  Add-ADGroupMember -Identity "Administrators" -Members $Global:ServiceAccountSamAccountName | Out-Null
  Add-ADGroupMember -Identity "Domain Admins" -Members $Global:ServiceAccountSamAccountName | Out-Null
  Add-ADGroupMember -Identity "Enterprise Admins" -Members $Global:ServiceAccountSamAccountName | Out-Null
  Add-ADGroupMember -Identity "Group Policy Creator Owners" -Members $Global:ServiceAccountSamAccountName | Out-Null
  Add-ADGroupMember -Identity "Schema Admins" -Members $Global:ServiceAccountSamAccountName | Out-Null
  Write-Host "`n  [++] User: $($Global:ServiceAccountDisplayName) added, Logon Name: $($Global:ServiceAccountSamAccountName) Password: $($Global:ServiceAccountPassword)" 
  Write-Host "        Adding $($Global:ServiceAccountDisplayName) to $($Global:LabDomainFqdn) Groups: Administrators, Domain Admins, Enterprise Admins, Group Policy Creator Owners, Schema Admins"

  # Configure service principal names for the SQL service account.
  # This function supports both the initial lab build and later maintenance.
  fix_setspn

  # Create the Groups OU and move the default groups into it.
  New-ADOrganizationalUnit -Name "Groups" -Path $Global:DomainDN -Description "Groups" | Out-Null
  get-adgroup "Schema Admins" | move-adobject -targetpath "OU=Groups,$($Global:DomainDN)" | Out-Null
  get-adgroup "Allowed RODC Password Replication Group" | move-adobject -targetpath "OU=Groups,$($Global:DomainDN)" | Out-Null
  get-adgroup "Cert Publishers" | move-adobject -targetpath "OU=Groups,$($Global:DomainDN)" | Out-Null
  get-adgroup "Cloneable Domain Controllers" | move-adobject -targetpath "OU=Groups,$($Global:DomainDN)" | Out-Null
  get-adgroup "Denied RODC Password Replication Group" | move-adobject -targetpath "OU=Groups,$($Global:DomainDN)" | Out-Null
  get-adgroup "DnsAdmins" | move-adobject -targetpath "OU=Groups,$($Global:DomainDN)" | Out-Null
  get-adgroup "DnsUpdateProxy" | move-adobject -targetpath "OU=Groups,$($Global:DomainDN)" | Out-Null
  get-adgroup "Domain Computers" | move-adobject -targetpath "OU=Groups,$($Global:DomainDN)" | Out-Null
  get-adgroup "Domain Controllers" | move-adobject -targetpath "OU=Groups,$($Global:DomainDN)" | Out-Null
  get-adgroup "Domain Guests" | move-adobject -targetpath "OU=Groups,$($Global:DomainDN)" | Out-Null
  get-adgroup "Domain Users" | move-adobject -targetpath "OU=Groups,$($Global:DomainDN)" | Out-Null
  get-adgroup "Domain Admins" | move-adobject -targetpath "OU=Groups,$($Global:DomainDN)" | Out-Null
  get-adgroup "Enterprise Admins" | move-adobject -targetpath "OU=Groups,$($Global:DomainDN)" | Out-Null
  get-adgroup "Enterprise Key Admins" | move-adobject -targetpath "OU=Groups,$($Global:DomainDN)" | Out-Null
  get-adgroup "Enterprise Read-only Domain Controllers" | move-adobject -targetpath "OU=Groups,$($Global:DomainDN)" | Out-Null
  get-adgroup "Group Policy Creator Owners" | move-adobject -targetpath "OU=Groups,$($Global:DomainDN)" | Out-Null
  get-adgroup "Key Admins" | move-adobject -targetpath "OU=Groups,$($Global:DomainDN)" | Out-Null
  get-adgroup "Protected Users" | move-adobject -targetpath "OU=Groups,$($Global:DomainDN)" | Out-Null
  get-adgroup "RAS and IAS Servers" | move-adobject -targetpath "OU=Groups,$($Global:DomainDN)" | Out-Null
  get-adgroup "Read-only Domain Controllers" | move-adobject -targetpath "OU=Groups,$($Global:DomainDN)" | Out-Null
  }
  # End lab content creation.


  # ---- begin create_lab_gpo
function create_lab_gpo {
  $CurrentDomain=((Get-WmiObject Win32_ComputerSystem).Domain).Split(".")[0]
  write-host("`n  [++] Removing Disable Defender Policy and Unlinking from Domain")
  Get-GPO -Name "Disable Defender" | Remove-GPLink -target $Global:DomainDN | Remove-GPO -Name "Disable Defender" > $null 
 
  write-host("`n  [++] Creating new Disable Defender Group Policy Object")
  New-GPO -Name "Disable Defender"

  #reg add "HKLM\SYSTEM\CurrentControlSet\Services\FDResPub" /f /v DependOnService /t REG_MULTI_SZ /d "RpcSs\0http\0fpdhost\0LanmanWorkstation"
  write-host("`n  [++] Setting GPO Registry key: FDResPub")
  Set-GPRegistryValue -Name "Disable Defender" -Key "HKLM\SYSTEM\CurrentControlSet\Services\FDResPub" -ValueName "DependOnService" -Type MultiString -Value "RpcSs\0http\0fpdhost\0LanmanWorkstation"
  Set-GPRegistryValue -Name "Disable Defender" -Key "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Run" -ValueName "sc_fdredpub" -Type MultiString -Value "sc config fdrespub depend= RpcSs/http/fdphost/LanmanWorkstation"
  reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Run" /f /v sc_fdrespub /t REG_EXPAND_SZ /d "sc config fdrespub depend= RpcSs/http/fdphost/LanmanWorkstation"
  
  # Enable Remote Desktop Protocol (RDP).
  # Set-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\Terminal Server' -name "fDenyTSConnections" -value 0
  write-host("`n  [++] Enable RDP")
  Set-GPRegistryValue -Name "Disable Defender" -Key "HKLM\System\CurrentControlSet\Control\Terminal Server" -ValueName "fDenyTSConnections" -Value 0 -Type Dword | Out-Null 

  #reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" /f /v EnableLUA /t REG_DWORD /d 0 > $null
  write-host("`n  [++] Setting GPO Registry key: EnableLUA")
  Set-GPRegistryValue -Name "Disable Defender" -Key "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -ValueName "EnableLUA" -Value 0 -Type Dword | Out-Null

  #Set-GPRegistryValue -Name "LAPS_IT" -Key "HKLM\Software\Policies\Microsoft Services\AdmPwd" -ValueName 'AdmPwdEnabled' -Value 1 -Type Dword
  #reg add "HKLM\System\CurrentControlSet\Services\SecurityHealthService" /v "Start" /t REG_DWORD /d "4" /f > $null
  write-host("`n  [++] Setting GPO Registry key: SecurityHealthService")
  Set-GPRegistryValue -Name "Disable Defender" -Key "HKLM\System\CurrentControlSet\Services\SecurityHealthService" -ValueName "Start" -Value 4 -Type Dword | Out-Null
  # Optionally remove the existing Defender policy registry key.
  # reg delete "HKLM\Software\Policies\Microsoft\Windows Defender" /f > $null
  
  # Configure the group policy to disable Microsoft Defender antivirus features.
  # reg add "HKLM\Software\Policies\Microsoft\Windows Defender" /v "DisableAntiSpyware" /t REG_DWORD /d "1" /f > $null
  write-host("`n  [++] Setting GPO Registry key: DisableAntiSpyware")
  Set-GPRegistryValue -Name "Disable Defender" -Key "HKLM\Software\Policies\Microsoft\Windows Defender" -ValueName "DisableAntiSpyware" -Value 1 -Type Dword | Out-Null

  #reg add "HKLM\Software\Policies\Microsoft\Windows Defender" /v "DisableAntiVirus" /t REG_DWORD /d "1" /f > $null
  write-host("`n  [++] Setting GPO Registry key: DisableAntiVirus")
  Set-GPRegistryValue -Name "Disable Defender" -Key "HKLM\Software\Policies\Microsoft\Windows Defender" -ValueName "DisableAntiVirus" -Value 1 -Type Dword | Out-Null

  #reg add "HKLM\Software\Policies\Microsoft\Windows Defender\MpEngine" /v "MpEnablePus" /t REG_DWORD /d "0" /f > $null
  write-host("`n  [++] Setting GPO Registry key: MpEnablePus")
  Set-GPRegistryValue -Name "Disable Defender" -Key "HKLM\Software\Policies\Microsoft\Windows Defender\MpEngine" -ValueName "MpEnablePus" -Value 0 -Type Dword | Out-Null

  write-host("`n  [++] Setting GPO Registry key: RTP DisableBehaviorMonitoring")
  #reg add "HKLM\Software\Policies\Microsoft\Windows Defender\Real-Time Protection" /v "DisableBehaviorMonitoring" /t REG_DWORD /d "1" /f > $null
  Set-GPRegistryValue -Name "Disable Defender" -Key "HKLM\Software\Policies\Microsoft\Windows Defender\Real-Time Protection" -ValueName "DisableBehaviorMonitoring" -Value 1 -Type Dword | Out-Null

  write-host("`n  [++] Setting GPO Registry key: RTP DisableIOAVProtection")
  #reg add "HKLM\Software\Policies\Microsoft\Windows Defender\Real-Time Protection" /v "DisableIOAVProtection" /t REG_DWORD /d "1" /f > $null
  Set-GPRegistryValue -Name "Disable Defender" -Key "HKLM\Software\Policies\Microsoft\Windows Defender\Real-Time Protection" -ValueName "DisableIOAVProtection" -Value 1 -Type Dword | Out-Null
  
  write-host("`n  [++] Setting GPO Registry key: RTP DisableOnAccessProtection")
  #reg add "HKLM\Software\Policies\Microsoft\Windows Defender\Real-Time Protection" /v "DisableOnAccessProtection" /t REG_DWORD /d "1" /f > $null
  Set-GPRegistryValue -Name "Disable Defender" -Key "HKLM\Software\Policies\Microsoft\Windows Defender\Real-Time Protection" -ValueName "DisableOnAccessProtection" -Value 1 -Type Dword | Out-Null

  write-host("`n  [++] Setting GPO Registry key: RTP DisableRealtimeMonitoring")
  #reg add "HKLM\Software\Policies\Microsoft\Windows Defender\Real-Time Protection" /v "DisableRealtimeMonitoring" /t REG_DWORD /d "1" /f > $null
  Set-GPRegistryValue -Name "Disable Defender" -Key "HKLM\Software\Policies\Microsoft\Windows Defender\Real-Time Protection" -ValueName "DisableRealtimeMonitoring" -Value 1 -Type Dword | Out-Null
 
  write-host("`n  [++] Setting GPO Registry key: RTP DisableScanOnRealtimeEnable")
  #reg add "HKLM\Software\Policies\Microsoft\Windows Defender\Real-Time Protection" /v "DisableScanOnRealtimeEnable" /t REG_DWORD /d "1" /f > $null
  Set-GPRegistryValue -Name "Disable Defender" -Key "HKLM\Software\Policies\Microsoft\Windows Defender\Real-Time Protection" -ValueName "DisableScanOnRealtimeEnable" -Value 1 -Type Dword | Out-Null

  write-host("`n  [++] Setting GPO Registry key: RTP DisableScriptScanning")
  #Set-MpPreference -DisableScriptScanning $true 
  Set-GPRegistryValue -Name "Disable Defender" -Key "HKLM\Software\Policies\Microsoft\Windows Defender\Real-Time Protection" -ValueName "DisableScriptScanning" -Value 1 -Type Dword | Out-Null

  write-host("`n  [++] Setting GPO Registry key: Defender Reporting DisableEnhancedNotifications")
  #reg add "HKLM\Software\Policies\Microsoft\Windows Defender\Reporting" /v "DisableEnhancedNotifications" /t REG_DWORD /d "1" /f > $null
  Set-GPRegistryValue -Name "Disable Defender" -Key "HKLM\Software\Policies\Microsoft\Windows Defender\Reporting" -ValueName "DisableEnhancedNotifications" -Value 1 -Type Dword | Out-Null

  write-host("`n  [++] Setting GPO Registry key: Defender SpyNet DisableBlockAtFirstSeen")
  #reg add "HKLM\Software\Policies\Microsoft\Windows Defender\SpyNet" /v "DisableBlockAtFirstSeen" /t REG_DWORD /d "1" /f > $null
  Set-GPRegistryValue -Name "Disable Defender" -Key "HKLM\Software\Policies\Microsoft\Windows Defender\SpyNet" -ValueName "DisableBlockAtFirstSeen" -Value 1 -Type Dword | Out-Null
 
  write-host("`n  [++] Setting GPO Registry key: Defender SpyNet SpynetReporting")
  #reg add "HKLM\Software\Policies\Microsoft\Windows Defender\SpyNet" /v "SpynetReporting" /t REG_DWORD /d "0" /f > $null
  Set-GPRegistryValue -Name "Disable Defender" -Key "HKLM\Software\Policies\Microsoft\Windows Defender\SpyNet" -ValueName "SpynetReporting" -Value 0 -Type Dword | Out-Null
  
  write-host("`n  [++] Setting GPO Registry key: Defender SpyNet SubmitSamplesConsent")
  #reg add "HKLM\Software\Policies\Microsoft\Windows Defender\SpyNet" /v "SubmitSamplesConsent" /t REG_DWORD /d "2" /f > $null
  Set-GPRegistryValue -Name "Disable Defender" -Key "HKLM\Software\Policies\Microsoft\Windows Defender\SpyNet" -ValueName "SubmitSamplesConsent" -Value 2 -Type Dword | Out-Null
  
  write-host("`n  [++] Setting GPO Registry key: Defender ApiLogger")
  #reg add "HKLM\System\CurrentControlSet\Control\WMI\Autologger\DefenderApiLogger" /v "Start" /t REG_DWORD /d "0" /f > $null
  Set-GPRegistryValue -Name "Disable Defender" -Key "HKLM\System\CurrentControlSet\Control\WMI\Autologger\DefenderApiLogger" -ValueName "Start" -Value 0 -Type Dword | Out-Null 

  write-host("`n  [++] Setting GPO Registry key: Defender DefenderAuditLogger")
  #reg add "HKLM\System\CurrentControlSet\Control\WMI\Autologger\DefenderAuditLogger" /v "Start" /t REG_DWORD /d "0" /f > $null
  Set-GPRegistryValue -Name "Disable Defender" -Key "HKLM\System\CurrentControlSet\Control\WMI\Autologger\DefenderAuditLogger" -ValueName "Start" -Value 0 -Type Dword | Out-Null 
 
  # smb1 enabled 
  #Set-GPRegistryValue -Name "Disable Defender" -Key "HKLM\SYSTEM\CurrentControlSet\Services\LanmanServer\Parameters" -ValueName "SMB1" -Value 1 -Type Dword | Out-Null 
  #  
  # move the enable-windowsoptionalfeature to both the DC and Workstation builds 
  # set smb1 = enabled in both DC and Workstations Registries ( locally )
  # set smb1 = enabled via GPO for the domain 
  # Enable-WindowsOptionalFeature -Online -FeatureName SMB1Protocol -NoRestart 
  # Set-SmbServerConfiguration -EnableSMB1Protocol $true -RequireSecuritySignature $False -EnableSecuritySignature $True -Confirm:$false
  # Set-GPRegistryValue -Name "Disable Defender" -Key "HKLM:\SYSTEM\CurrentControlSet\Services\LanmanServer\Parameters" -ValueName "SMB1" -Value 1 -Type Dword | Out-Null 
  # Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\LanmanServer\Parameters" SMB1 -Type DWORD -Value 1 -Force


  # smb2 signing is enabled but not required (breakout into individual fix function)
  write-host("`n  [++] Setting GPO Registry key: Defender SMB2 Client RequireSecuritySignature")
  #reg add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\LanmanWorkstation\Parameters" /v "RequireSecuritySignature" /t REG_DWORD /d "0" /f > $null
  Set-GPRegistryValue -Name "Disable Defender" -Key "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\LanmanWorkstation\Parameters" -ValueName "RequireSecuritySignature" -Value 0 -Type Dword | Out-Null

  write-host("`n  [++] Setting GPO Registry key: Defender SMB2 Server RequireSecuritySignature")
  # reg add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\LanmanServer\Parameters" /v "requiresecuritysignature" /t REG_DWORD /d "0" /f > $null
  Set-GPRegistryValue -Name "Disable Defender" -Key "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\LanmanServer\Parameters" -ValueName "requiresecuritysignature" -Value 0 -Type Dword | Out-Null
 
  # printer-nightmare registry keys (breakout into individual fix function)
  write-host("`n  [++] Setting GPO Registry key: PrinterNightmare")
  #reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows NT\Printers\PointAndPrint" /v "NoWarningNoElevationOnInstall" /t REG_DWORD /d "1" /f > $null
  Set-GPRegistryValue -Name "Disable Defender" -Key "HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows NT\Printers\PointAndPrint" -ValueName "NoWarningNoElevationOnInstall" -Value 1 -Type Dword | Out-Null

  #reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows NT\Printers\PointAndPrint" /v "RestrictDriverInstallationToAdministrators" /t REG_DWORD /d "0" /f > $null
  Set-GPRegistryValue -Name "Disable Defender" -Key "HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows NT\Printers\PointAndPrint" -ValueName "RestrictDriverInstallationToAdministrators" -Value 0 -Type Dword | Out-Null

  # set localaccounttokenfilterpolicy
  write-host("`n  [++] Setting GPO Registry key: LocalAccountTokenFilterPolicy")
  # reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\system" /v "LocalAccountTokenFilterPolicy" /t REG_DWORD /d "1" /f
  Set-GPRegistryValue -Name "Disable Defender" -Key "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\system" -ValueName "LocalAccountTokenFilterPolicy" -Value 1 -Type Dword | Out-Null

  # set alwaysinstallelevated 
  write-host("`n  [++] Setting GPO Registry key: AlwaysInstallElevated")
  # reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\Installer" -v "AlwaysInstallElevated" /t REG_DWORD /d "1" /f > $null 
  Set-GPRegistryValue -Name "Disable Defender" -Key "HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\Installer" -ValueName "AlwaysInstallElevated" -Value 0 -Type Dword | Out-Null

  write-host("`n  [++] Setting GPO Registry key: WindowsUpdate")
  # reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" /v "NoAutoUpdate" /t REG_DWORD /d "1" /f > $null
  Set-GPRegistryValue -Name "Disable Defender" -Key "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" -ValueName "NoAutoUpdate" -Value 1 -Type Dword | Out-Null

  #winrm registry key 
  # Set-GPRegistryValue -Name "WinRM" -Key "HKLM\Policies\Microsoft\Windows\WinRM\Service" -ValueName "AllowAutoConfig" -Value 1 -Type Dword | Out-Null
  
  #winrs registry key
  # Set-GPRegistryValue -Name "WinRS" -key "HKLM\Policies\Microsoft\Windows\WinRM\Service\WinRS" -ValueName "AllowRemoteShellAccess" -Value 1 -Type Dword | Out-Null

  # Apply quality-of-life group policy settings.
    # Enable dark mode through Group Policy.
    write-host("`n  [++] Setting GPO Registry key: Dark Theme")
    Set-GPRegistryValue -Name "Disable Defender" -Key "HKEY_CURRENT_USER\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize" -ValueName "AppsUseLightTheme" -Value 0 -Type Dword | Out-Null
    Set-GPRegistryValue -Name "Disable Defender" -Key "HKEY_CURRENT_USER\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize" -ValueName "SystemUsesLightTheme" -Value 0 -Type Dword | Out-Null
    
    # Disable the screen timeout and lock screen for the lab.
    write-host("`n  [++] Setting GPO Registry key: Disable Screenlock, timer")
    Set-GPRegistryValue -Name "Disable Defender" -Key "HKEY_CURRENT_USER\Software\Policies\Microsoft\Windows\Control Panel\Desktop\" -ValueName "ScreenSaveTimeOut" -Value 0 -Type Dword
    Set-GPRegistryValue -Name "Disable Defender" -Key "HKEY_CURRENT_USER\Software\Policies\Microsoft\Windows\Control Panel\Desktop\" -ValueName "ScreenSaveActive" -Value 0 -Type Dword
    Set-GPRegistryValue -Name "Disable Defender" -Key "HKEY_CURRENT_USER\Software\Policies\Microsoft\Windows\Control Panel\Desktop\" -ValueName "ScreenSaverIsSecure" -Value 0 -Type Dword | Out-Null

    # Prefer IPv4 over IPv6.
    Set-GPRegistryValue -Name "Disabled Components" -Key "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\Tcpip6\Parameters\" -ValueName "DisabledComponents" -Value 0x20 -Type Dword 
    # New-ItemProperty “HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip6\Parameters\” -Name “DisabledComponents” -Value 0x20 -PropertyType “DWord”
    # Set-ItemProperty “HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip6\Parameters\” -Name “DisabledComponents” -Value 0x20
    
  # End Group Policy configuration.
  write-host("`n  [++] New Disable Defender GPO Created, Linked and Enforced `n")
  Get-GPO -Name "Disable Defender" | New-GPLink -target $Global:DomainDN -LinkEnabled Yes -Enforced Yes

  write-host("`n  [++] Removing and unlinking Default Domain Policy")
  Remove-GPLink -Name "Default Domain Policy" -target $Global:DomainDN | Out-Null 
  }
  # End lab Group Policy creation.

# ---- begin set_dcstaticip function  
function set_dcstaticip { 
  # get the ip address
  $IPAddress=Get-NetIPAddress -AddressFamily IPv4 -InterfaceIndex $(Get-NetConnectionProfile | Select-Object -ExpandProperty InterfaceIndex) | Select-Object -ExpandProperty IPAddress
  
  # get the adapter name
  $adapter=Get-CimInstance -Class Win32_NetworkAdapter -Property NetConnectionID,NetConnectionStatus | Where-Object { $_.NetConnectionStatus -eq 2 } | Select-Object -Property NetConnectionID -ExpandProperty NetConnectionID
  
  # split the ip address up based on the . 
  $IPByte = $IPAddress.Split(".")
  
  # first 3 octets not intrested in, only the last octet set to .250 (ip address)
  $StaticIP = ($IPByte[0]+"."+$IPByte[1]+"."+$IPByte[2]+"."+$Global:DCLastOctet) 

  # first 3 octets not intrested in, onlly the last octet set to .1 (default gateway)
  $StaticGateway = ($IPByte[0]+"."+$IPByte[1]+"."+$IPByte[2]+"."+$Global:GatewayLastOctet) 

  # static mask of 24 bits or 255.255.255.0
  $StaticMask = "255.255.255.0"

  write-host "$adapter $StaticIP $StaticMask $StaticGateway"
 
  netsh interface ipv4 set address name="$adapter" static $StaticIP $StaticMask $StaticGateway
  netsh interface ipv4 set dnsservers name="$adapter" static 8.8.8.8
  }
  # ---- end set_dcstaticip function  

# ---- begin set_workstation1_staticip function  
function set_workstation1_staticip { 
  # get the ip address
  $IPAddress=Get-NetIPAddress -AddressFamily IPv4 -InterfaceIndex $(Get-NetConnectionProfile | Select-Object -ExpandProperty InterfaceIndex) | Select-Object -ExpandProperty IPAddress
  
  # get the adapetr name
  $adapter=Get-CimInstance -Class Win32_NetworkAdapter -Property NetConnectionID,NetConnectionStatus | Where-Object { $_.NetConnectionStatus -eq 2 } | Select-Object -Property NetConnectionID -ExpandProperty NetConnectionID
   
  # split the ip address up based on the . 
  $IPByte = $IPAddress.Split(".")
   
  # first 3 octets not intrested in, only the last octet set to .250 (ip address)
  $StaticIP = ($IPByte[0]+"."+$IPByte[1]+"."+$IPByte[2]+"."+$Global:Workstation1Octet) 
 
  # first 3 octets not intrested in, onlly the last octet set to .1 (default gateway)
  $StaticGateway = ($IPByte[0]+"."+$IPByte[1]+"."+$IPByte[2]+"."+$Global:GatewayLastOctet) 
 
  # static mask of 24 bits or 255.255.255.0
  $StaticMask = "255.255.255.0"

  write-host "$adapter $StaticIP $StaticMask $StaticGateway"
 
  netsh interface ipv4 set address name="$adapter" static $StaticIP $StaticMask $StaticGateway
  netsh interface ipv4 set dnsservers name="$adapter" static 8.8.8.8
  }
  # ---- end set_workstation1_staticip function  

# ---- begin set_workstation2_staticip function  
function set_workstation2_staticip { 
  # get the ip address
  $IPAddress=Get-NetIPAddress -AddressFamily IPv4 -InterfaceIndex $(Get-NetConnectionProfile | Select-Object -ExpandProperty InterfaceIndex) | Select-Object -ExpandProperty IPAddress
  
  # get the adapetr name
  $adapter=Get-CimInstance -Class Win32_NetworkAdapter -Property NetConnectionID,NetConnectionStatus | Where-Object { $_.NetConnectionStatus -eq 2 } | Select-Object -Property NetConnectionID -ExpandProperty NetConnectionID
  
  # split the ip address up based on the . 
  $IPByte = $IPAddress.Split(".")
  
  # first 3 octets not intrested in, only the last octet set to .250 (ip address)
  $StaticIP = ($IPByte[0]+"."+$IPByte[1]+"."+$IPByte[2]+"."+$Global:Workstation2Octet) 

  # first 3 octets not intrested in, onlly the last octet set to .1 (default gateway)
  $StaticGateway = ($IPByte[0]+"."+$IPByte[1]+"."+$IPByte[2]+"."+$Global:GatewayLastOctet) 

  # static mask of 24 bits or 255.255.255.0
  $StaticMask = "255.255.255.0"

  write-host "`n  [++] Setting $adapter to IP: $StaticIP  Subnet: $StaticMask  Gateway: $StaticGateway"
  netsh interface ipv4 set address name="$adapter" static $StaticIP $StaticMask $StaticGateway

  write-host "`n  [++]  Setting $adapter to DNS: 8.8.8.8"
  netsh interface ipv4 set dnsservers name="$adapter" static 8.8.8.8
  }  
  # ---- end set_workstation2_staticip function

function fix_dcdns {
  $IPAddress=Get-NetIPAddress -AddressFamily IPv4 -InterfaceIndex $(Get-NetConnectionProfile | Select-Object -ExpandProperty InterfaceIndex) | Select-Object -ExpandProperty IPAddress
  
  # get the adapter name
  $adapter=Get-CimInstance -Class Win32_NetworkAdapter -Property NetConnectionID,NetConnectionStatus | Where-Object { $_.NetConnectionStatus -eq 2 } | Select-Object -Property NetConnectionID -ExpandProperty NetConnectionID
  
  # split the ip address up based on the . 
  $IPByte = $IPAddress.Split(".")
  
  # first 3 octets not intrested in, only the last octet set to .250 (ip address)
  $StaticIP = ($IPByte[0]+"."+$IPByte[1]+"."+$IPByte[2]+"."+$Global:DCLastOctet) 

  # first 3 octets not intrested in, onlly the last octet set to .1 (default gateway)
  $StaticGateway = ($IPByte[0]+"."+$IPByte[1]+"."+$IPByte[2]+"."+$Global:GatewayLastOctet) 

  # static mask of 24 bits or 255.255.255.0
  $StaticMask = "255.255.255.0"
   
  netsh interface ipv4 set address name="$adapter" static $StaticIP $StaticMask $StaticGateway

  write-host "`n  [++] Disabling $adapter Power Management"
  Disable-NetAdapterPowerManagement -Name "$adapter"
  
  write-host "`n  [++] Setting $adapter DNS to 127.0.0.1"
  netsh interface ipv4 set dnsservers name="$adapter" static 127.0.0.1 
  
  write-host "`n  [++] Setting Ipv6 DNS to DHCP"
  netsh interface ipv6 set dnsservers "$adapter" dhcp
}

function fix_workstationdns {
  $DCDNS=(Test-Connection -ComputerName $Global:DCName -Count 1).ipv4address.ipaddressToString
  
  write-host("`n  [++] Found $Global:DCName At $DCDNS")
  $adapter=Get-CimInstance -Class Win32_NetworkAdapter -Property NetConnectionID,NetConnectionStatus | Where-Object { $_.NetConnectionStatus -eq 2 } | Select-Object -Property NetConnectionID -ExpandProperty NetConnectionID
  
  write-host "`n  [++] Disabling $adapter Power Management"
  Disable-NetAdapterPowerManagement -Name "$adapter"
  
  write-host "`n  [++] Setting $adapter DNS to $DCDNS"
  netsh interface ipv4 set dnsservers name="$adapter" static $DCDNS
  
  write-host "`n  [++] Setting Ipv6 DNS to : DHCP"
  netsh interface ipv6 set dnsservers "$adapter" dhcp
  }

# ---- begin server_build function
function server_build {
  Get-ScheduledTask -TaskName ServerManager | Disable-ScheduledTask | Out-Null
  write-host("`n`n   Computer Name : $machine")
  write-host("     Domain Name : $domain")
  write-host("      OS Version : $osversion")

  if($currentname -ne "$Global:DCName") {
      write-host("`n  Computer Name is Incorrect Setting $Global:DCName")
      write-host("`n  - Script Run 1 of 3 - Setting the computer name to $Global:DCName and rebooting")
      write-host("`n  AFTER The reboot run the script again! to setup the domain controller!")
      Read-Host -Prompt "`n Press ENTER to continue..."
      set_mppref  # one time run of this function on the dc build 
      set_dcstaticip
      Rename-Computer -NewName "$Global:DCName" -Restart
      }
      elseif ($domain -ne "$($Global:LabDomainFqdn.ToUpper())") {
        write-host("`n  Computer name is CORRECT... Executing BuildLab Function")
        write-host("`n  Script Run 2 of 3 - AFTER The Domain Controller has been setup and configured, the system will auto-reboot")
        write-host("`n  NOTE: This Reboot will take SEVERAL MINUTES, Dont Panic! We are working hard to build your Course Domain-Controller!")
        write-host("`n  AFTER THE REBOOT run this script 1 more time and select menu option D")
        Read-Host -Prompt "`n`n Press ENTER to continue..."
        build_lab
        }
      elseif ($domain -eq "$($Global:LabDomainFqdn.ToUpper())" -And $machine -eq "$Global:DCName") {
        write-host("`n Computer name and Domain are correct : Executing CreateContent Function ")
        create_labcontent
        create_lab_gpo
        get_sharphound
        fix_dcdns 
        write-host("`n Script Run 3 of 3 - We are all done! Rebooting one last time! o7 Happy Hacking! ")
        $dcip=Get-NetIPAddress -AddressFamily IPv4 -InterfaceIndex $(Get-NetConnectionProfile | Select-Object -ExpandProperty InterfaceIndex) | Select-Object -ExpandProperty IPAddress
        write-host("`n`n Write this down! We need this in the Workstation Configuration... Domain Controller IP Address: $dcip `n`n")
        Read-Host -Prompt "`n`n Press ENTER to continue..."
        restart-computer
        }
      else { 
        write-host("Giving UP! There is nothing to do!") 
        }
      }
      # ---- end server_build function

# ---- begin git_powersploit function      
#function git_powersploit {
#  write-host("`n  [++] Git Cloning PowerSploit to $Env:windir\System32\WindowsPowerShell\v1.0\Modules\PowerSploit")
#  git clone https://github.com/PowerShellMafia/PowerSploit $Env:windir\System32\WindowsPowerShell\v1.0\Modules\PowerSploit > $null 
#  }
   # ---- end git_powersploit function

# ---- begin setup_git function
function setup_git {
  [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
  $architecture = '64-bit'
  $assetName = "Git-*-$architecture.exe"
  
  $gitHubApi = 'https://api.github.com/repos/git-for-windows/git/releases/latest'
  $response = Invoke-WebRequest -Uri $gitHubApi -UseBasicParsing
  $json = $response.Content | ConvertFrom-Json
  $release = $json.assets | Where-Object Name -like $assetName
  
  # download 
  write-host("`n  [++] Downloading $($release.name)")
  Start-BitsTransfer -Source $release.browser_download_url -Destination ".\$($release.name)" | Out-Null
  
  # install  
  write-host("`n  [++] Installing $($release.name)")
  Unblock-File -Path ".\$($release.name)"
  Start-Process .\$($release.name) -argumentlist "/silent /supressmsgboxes" -Wait  | Out-Null 
  Remove-Item .\$($release.name)  
  
  # reload environment variables 
  $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")  
  }
  # ---- end setup_git function

# ---- begin get_recon function 
function git_recon() { 
  # Put Recon in the right place (could be used on DC or Workstations) 
  write-host("`n  [++] Downloading Powershell Mafia v1.9 to $Global:ToolsRoot")
  mkdir $HOME\Documents\WindowsPowerShell\Modules\Recon
  $PowerShellMafiaPath = Join-Path $Global:ToolsRoot "PowerShellMafia"
  git clone https://github.com/PowerShellMafia/PowerSploit $PowerShellMafiaPath
  write-host("`n  [++] Copying Recon to C:\$HOME\Documents\WindowsPowerShell\Modules\Recon")
  $ReconSourcePath = Join-Path $Global:ToolsRoot "PowerShellMafia\Recon"
  echo D | xcopy /e /y $ReconSourcePath $HOME\Documents\WindowsPowerShell\Modules\Recon
  }
  # ---- end git_recon function


# ---- begin workstations_common function
function workstations_common { 

  # remove all updates 
  remove_all_updates

  # download and install Git for Windows 
  setup_git 
  
  # write-host("`n  [++] Setting Registry key: FDResPub")
  # reg add "HKLM\SYSTEM\CurrentControlSet\Services\FDResPub" /f /v DependOnService /t REG_MULTI_SZ /d "RpcSs\0http\0fpdhost\0LanmanWorkstation"
  
  # install remote system administration tools
  write-host("`n  [++] Installing Remote System Administration Tools (RSAT)") 
  Add-WindowsCapability -Online -Name Rsat.ActiveDirectory.DS-LDS.Tools~~~~0.0.1.0 | Out-Null

  # install dotnet v2 - needed for powerview fix : powershell -version 2 -ep bypass 
  write-host("`n  [++] Installing .Net 2.0")
  Add-WindowsCapability -Online -Name NetFx2~~~~ | Out-Null
    
  # install dotnet v3 
  write-host("`n  [++] Installing .Net 3.0")
  Add-WindowsCapability -Online -Name NetFx3~~~~ | Out-Null 

  # download old version of Powerview so it works with course material 
  # requires .net v2 and the powershell -version 2 -ep bypass for this 
  # (course material update for this one)
  New-Item -ItemType Directory -Path $Global:ToolsRoot -Force | Out-Null 
  write-host("`n  [++] Downloading Powerview v1.9 to $Global:ToolsRoot")
  Invoke-WebRequest  https://raw.githubusercontent.com/PowerShellEmpire/PowerTools/version_1.9/PowerView/powerview.ps1 -o (Join-Path $Global:ToolsRoot "Powerview.ps1") | Out-Null
  
  #Git PowershellMafia's Recon and drop it in $HOME\Documents\WindowsPowerShell\Modules\Recon
  # Will work for the DC wont work for the Workstation as its not logged into the domain yet... 
  # git_recon 

  # download an unzip Sharphound.zipi to $Global:SharpHoundPath
  get_sharphound 

  # download and unzip pstools.zip to c:\pstools 
  write-host("`n  [++] Downloading PSTools to $Global:ToolsRoot")
  $PSToolsZip = Join-Path $Global:ToolsRoot "PSTools.zip"
  Invoke-WebRequest  https://download.sysinternals.com/files/PSTools.zip -o $PSToolsZip | Out-Null
  Start-BitsTransfer -Source "https://download.sysinternals.com/files/PSTools.zip" -Destination $PSToolsZip | Out-Null
  write-host("`n  [++] Extracting PSTools to C:\PSTools")
  Expand-Archive -Force $PSToolsZip C:\PSTools | Out-Null 
  
  # create c:\share and smbshare
  mkdir C:\Share > $null 
  New-SmbShare -Name "Share" -Path "C:\Share" -ChangeAccess "Users" -FullAccess "Everyone" -WarningAction SilentlyContinue | Out-Null

  fix_workstationdns

  # Join the workstation to the domain with the configured privileged lab user.
  write-host("`n Joining machine to domain $($Global:LabDomainFqdn)")
  # add-computer -domainname "$($Global:LabDomainFqdn.ToUpper())" -username administrator -restart | Out-Null
  $domain = "$($Global:LabDomainNetbios)"
  $password = $Global:User3Password | ConvertTo-SecureString -AsPlainText -Force
  $username = "$domain\$($Global:User3SamAccountName)" 
  $credential = New-Object System.Management.Automation.PSCredential($username,$password)
  Add-Computer -DomainName $Global:LabDomainFqdn -Credential $credential  | Out-Null 
  }
  # ---- end workstations_common function      

# ---- begin workstation1_build function 
function workstation1_build { 
  write-host("`n`n   Computer Name : $machine")
  write-host("     Domain Name : $domain")
  write-host("      OS Version : $osversion")

  if ($machine -ne "$Global:Workstation1Name") { 
    write-host ("`n Setting the name of this machine to $Global:Workstation1Name and rebooting automatically...")
    write-host (" Run this script 1 more time and select 'P' in the menu to join the domain")
    Read-Host -Prompt "`n Press ENTER to continue..."
    # set_mppref
    set_workstation1_staticip 
    Rename-Computer -NewName "$Global:Workstation1Name" -Restart
    }
    elseif ($machine -eq "$Global:Workstation1Name") {
      workstations_common
      # Enable the local Administrator account and set its configured password.
      Get-LocalUser -Name "Administrator" | Enable-LocalUser
      $UserAccount = Get-LocalUser -Name "Administrator"
      $UserAccountPassword = $Global:LocalAdministratorPassword | ConvertTo-SecureString -AsPlainText -Force
      $UserAccount | Set-LocalUser -Password $UserAccountPassword

      Read-Host -Prompt "`n All done! $machine is all set up! `n Press Enter to reboot and log in as $($Global:LabDomainNetbios)\$($Global:User2SamAccountName) with password $($Global:User2Password)."
      restart-computer 
    }
    else { write-host("Nothing to do here") }
    } 
    # ---- end workstation1_build function 
    
# ---- begin workstation2_build function
function workstation2_build { 
  write-host("`n`n   Computer Name : $machine")
  write-host("     Domain Name : $domain")
  write-host("      OS Version : $osversion")
  
  if ($machine -ne "$Global:Workstation2Name") {
    write-host ("`n Setting the name of this machine to $Global:Workstation2Name and rebooting automatically...")
    write-host (" Run this script 1 more time and select 'S' in the menu to join the domain")
    Read-Host -Prompt "`n Press ENTER to continue..."
    set_mppref
    set_workstation2_staticip
    Rename-Computer -NewName "$Global:Workstation2Name" -Restart
    }
    elseif ($machine -eq "$Global:Workstation2Name") {
      workstations_common 
      Get-LocalUser -Name "Administrator" | Enable-LocalUser
      $UserAccount = Get-LocalUser -Name "Administrator"
      $UserAccountPassword = $Global:LocalAdministratorPassword | ConvertTo-SecureString -AsPlainText -Force
      $UserAccount | Set-LocalUser -Password $UserAccountPassword
      # Add the configured second user to the local Administrators group on this workstation.
      Add-LocalGroupMember -Group Administrators -Member $Global:User2SamAccountName -Verbose
      Read-Host -Prompt "`n All done! $machine is all set up! `n Press Enter to reboot and log in as $($Global:LabDomainNetbios)\$($Global:User1SamAccountName) with password $($Global:User1Password)."
      restart-computer 
      }
    else { write-host("Nothing to do here") }
    } 
    # ---- end workstation2_build function

# ---- begin menu function
function menu {
  do {
    Write-Host "`n`n`tCustom AD-Lab Build Menu - Select an option`n"
    Write-Host "`tPress 'D' to setup $Global:DCName Domain Controller"
    Write-host "`t(must be run 3 times)`n"
    Write-Host "`tPress 'P' to setup $Global:Workstation1Name Workstation and join the domain $($Global:LabDomainFqdn)"
    Write-host "`t(must be run 2 times)`n"
    Write-Host "`tPress 'S' to setup $Global:Workstation2Name Workstation and join the domain $($Global:LabDomainFqdn)" 
    Write-host "`t(must be run 2 times)`n"
    Write-host "`n`t --- Independant Standalone Functions ---"
    Write-host "`n`tPress 'N' to only run the NukeDefender Function"
    Write-host "`n`tPress 'F' to Fix Disable Defender GPO Policy"
    Write-Host "`n`tPress 'K' to only run the SetSPN Function"
    Write-Host "`n`tPress 'A' to only run the ADCSCertificateAuthority Function"
    Write-Host "`n`tPress 'H' to only download sharphound.zip and extract to $Global:SharpHoundPath"
    Write-Host "`n`tPress 'X' to Exit"
    $choice = Read-Host "`n`tEnter Choice" } 
    until (($choice -eq 'P') -or ($choice -eq 'D') -or ($choice -eq 'S') -or ($choice -eq 'N') -or ($choice -eq 'F') -or ($choice -eq 'X') -or ($choice -eq 'K') -or ($choice -eq 'A') -or ($choice -eq 'H'))
    
  switch ($choice) {
    'D'{  Write-Host "`n Running... $Global:DCName domain controller"
          nukedefender 
          server_build }
    'P'{  Write-Host "`n Running... $Global:Workstation1Name Workstation"
          nukedefender 
          workstation1_build }
    'S'{  Write-Host "`n Running... $Global:Workstation2Name Workstation"
          nukedefender 
          workstation2_build }
    'F'{  Write-Host "`n ONLY Running... Fix My Disable Defender GPO function and exit" 
          create_lab_gpo }          
    'N'{  Write-Host "`n ONLY Running... the NukeDefender function and exit"
          nukedefender }
    'K'{  Write-Host "`n ONLY running... Fix SetSPN Function and exit"
          fix_setspn }
    'A'{  Write-Host "`n ONLY running... Fix ADCSCertificateAuthority Function and exit"
          fix_adcsca }    
    'H'{  Write-Host "`n ONLY running... Download Sharphound.zip and extract to $Global:ToolsRoot"
          get_sharphound }                           
    'X'{Return}
    }
  } 

  # ---- begin menu function  

# ---- begin main
  $ErrorActionPreference = "SilentlyContinue"
  Clear-Host 
  $currentname=$env:COMPUTERNAME 
  $machine=$env:COMPUTERNAME
  $domain=$env:USERDNSDOMAIN
  $osversion=((Get-WmiObject -class Win32_OperatingSystem).Caption)

  write-host("`n`n   Computer Name : $machine")
  write-host("     Domain Name : $domain")
  write-host("      OS Version : $osversion")

  # execute function check_ipaddress test if ip address is 169.254.0.0/16 if it is.. fail and exit 
  check_ipaddress
  menu 

  #if ("$osversion" -eq "Microsoft Windows Server 2019 Standard Evaluation") 
  #  { menu }
  #  # elseif ("$osversion" -eq "Microsoft Windows Server 2022 Standard Evaluation") 
  #  # { menu }  
  #  elseif ("$osversion" -eq "Microsoft Windows Server 2019 Standard") 
  #  { menu }  
  #  elseif ("$osversion" -eq "Microsoft Windows Server 2016 Standard") 
  #  { menu }
  #  elseif ("$osversion" -eq "Microsoft Windows 10 Enterprise Evaluation") 
  #  { menu }
  #  elseif ("$osversion" -eq "Microsoft Windows 10 Enterprise 2016 LTSB")
  #  { menu }
  #  elseif ("$osversion" -eq "Microsoft Windows 10 Pro")
  #  { menu }
  #  elseif ("$osversion" -like "Home") {      
  #    write-host("`n [!!] Windows Home is unable to join a domain, please use the correct version of windows")
  #    exit 
  #    }
  #  elseif ("$osversion" -like "Education") {
  #    write-host("`n [!!] Windows Educational versions cannot be used with this lab")
  #    }
  #  elseif ("$osversion" -like "Windows 11") {
  #    write-host("`n [!!] Windows 11 cannot be used with this lab")
  #    exit 
  #    }
  #  elseif ("$osversion" -like "Windows Server 2022") {
  #    write-host("`n [!!] Windows Server 2022 cannot be used with this lab")
  #    exit 
  #    }
  #    else { write-host("Unable to find a suitable OS Version for this lab - Exiting") 
  #    }
      # ---- end main
    
