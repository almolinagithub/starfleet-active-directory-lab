# Starfleet Active Directory Lab

A three-machine Windows Active Directory training lab with a Star Trek theme. `lab_creator.ps1` configures the domain controller, workstations, sample directory accounts, certificate services, DNS, and supporting lab tools.

## Lab Manifest

| Role | Host name | Operating system target | Configuration runs |
| --- | --- | --- | --- |
| Domain controller | `STARBASE-1` | Windows Server 2019 or 2022, Desktop Experience | 3 |
| Workstation 1 | `ENTERPRISE-01` | Windows 10 Pro or Enterprise, Desktop Experience | 2 |
| Workstation 2 | `VOYAGER-01` | Windows 10 Pro or Enterprise, Desktop Experience | 2 |

The configured domain is `STARFLEET.local`.

## Crew Accounts

| Character | Logon name | Lab role |
| --- | --- | --- |
| James T. Kirk | `jkirk` | Standard domain user |
| Spock | `spock` | Domain administrator for the lab scenario |
| Leonard McCoy | `lmccoy` | Privileged account used to join workstations to the domain |
| Data | `data` | SQL service account and SPN owner |

Data can be renamed in the configuration block. The script uses the selected service-account logon name as the SQL SPN owner while retaining the `SQLService` SPN class.

## Customization

Edit the configuration block at the start of `lab_creator.ps1` before the first run. Use the variables below to adapt the lab without changing the provisioning functions.

| What to customize | Variables |
| --- | --- |
| Domain identity | `LabDisplayName`, `LabRootName`, `LabTld` |
| Host names | `DCName`, `Workstation1Name`, `Workstation2Name` |
| Network suffixes | `DCLastOctet`, `Workstation1Octet`, `Workstation2Octet`, `GatewayLastOctet` |
| Crew accounts | `User1*`, `User2*`, `User3*` |
| SQL service account | `ServiceAccount*` |
| Local and directory-recovery passwords | `LocalAdministratorPassword`, `DirectoryServicesRestoreModePassword` |

## Before You Begin

1. Create three virtual machines on the same isolated virtual network. A VMware NAT network or a VirtualBox NAT Network is suitable; do not use a production network.
2. Keep DHCP enabled on that virtual NAT network for the initial boot of every VM. The script derives the network prefix from the current DHCP-assigned IPv4 address, then applies static addresses.
3. Exclude or reserve the static lab addresses (`.220`, `.221`, and `.250`) in the DHCP scope to prevent address conflicts.
4. Install the operating systems listed above and the guest tools for your hypervisor.
5. Reboot each virtual machine after installing its guest tools.
6. Copy the same version of `lab_creator.ps1` to each machine.
7. Edit the configuration block at the beginning of the script before the first run. This controls the domain, host names, IP-address suffixes, account names, and passwords.

To download the script from this repository on a lab VM:

```powershell
Invoke-WebRequest `
  -Uri 'https://raw.githubusercontent.com/almolinagithub/starfleet-active-directory-lab/main/lab_creator.ps1' `
  -OutFile '.\lab_creator.ps1'
```

Run it from an elevated PowerShell session:

```powershell
PowerShell -ExecutionPolicy Bypass -File .\lab_creator.ps1
```

## Network Plan

The script uses the first three octets of the machine's existing IPv4 address and applies the configured final octet.

| System | Address | DNS after configuration |
| --- | --- | --- |
| `STARBASE-1` | `x.x.x.250` | `127.0.0.1` |
| `ENTERPRISE-01` | `x.x.x.220` | Domain controller address |
| `VOYAGER-01` | `x.x.x.221` | Domain controller address |

The default gateway is `x.x.x.1` and the subnet mask is `255.255.255.0`. Change the IP suffix variables in the configuration block if those values conflict with your isolated network.

## Windows Security in the Lab

The standard deployment options (`D`, `P`, and `S`) invoke the script's lab security-configuration function before provisioning. It disables Microsoft Defender antivirus, firewall profiles, UAC-related protections, and automatic updates to create the intended practice environment.

Use this only on the isolated training VMs. Do not disable Windows antivirus or other endpoint protection on a host machine, production computer, or any network outside the dedicated lab.

## Deployment Sequence

### 1. Establish the domain controller

On the server VM, select **D** from the menu.

1. First run: renames the server to `STARBASE-1`, assigns its static address, then reboots.
2. Second run: installs and promotes the Active Directory domain services environment, then reboots.
3. Third run: creates the Starfleet accounts, configures certificate services, service principal names, Group Policy, DNS, and supporting lab content.

Wait for the final reboot before configuring either workstation.

### 2. Configure Enterprise workstation

On the first Windows client VM, select **P**.

1. First run: renames the computer to `ENTERPRISE-01`, applies the static address, then reboots.
2. Second run: configures DNS, joins `STARFLEET.local`, and completes workstation setup.

### 3. Configure Voyager workstation

On the second Windows client VM, select **S**.

1. First run: renames the computer to `VOYAGER-01`, applies the static address, then reboots.
2. Second run: configures DNS, joins `STARFLEET.local`, and completes workstation setup.

If a workstation does not join the domain, confirm that `STARBASE-1` has completed its final run, all VMs use the same virtual NAT/NAT Network, and the domain controller is reachable by name.

## Menu Reference

| Option | Action |
| --- | --- |
| `D` | Build or continue the `STARBASE-1` domain controller setup |
| `P` | Build or continue the `ENTERPRISE-01` workstation setup |
| `S` | Build or continue the `VOYAGER-01` workstation setup |
| `N` | Run the lab security-configuration function only |
| `F` | Recreate the lab Group Policy settings |
| `K` | Reconfigure SQL service principal names |
| `A` | Run the certificate-authority configuration function |
| `H` | Download and extract the SharpHound archive |
| `X` | Exit |

## Validation

`lab_creator.ps1` has been parsed successfully with PowerShell 7.6.1. It must still be run and tested on Windows because it uses Windows-only Active Directory, networking, and system-management commands.

## Safety

This training script intentionally changes security settings, permissions, and system services. Use it only on virtual machines that you own and administer, on an isolated network, and never on a production system.

## Attribution

`lab_creator.ps1` is derived from [PimpmyADLab](https://github.com/Dewalt-arch/pimpmyadlab) by **Dewalt-arch**, originally written as the Active Directory lab build script for the [TCM-Academy Practical Ethical Hacker course](https://academy.tcm-sec.com/p/practical-ethical-hacking-the-complete-course).

This project retains the core provisioning logic, function structure, and lab design of the original work, re-themed from a Marvel universe to a Star Trek universe. Full credit goes to the original authors and contributors.

### Original Authors & Contributors

| GitHub | Role |
| --- | --- |
| [@Dewalt-arch](https://github.com/Dewalt-arch) | Original author & primary maintainer (8 commits) |
| [@CarlosAmericano](https://github.com/CarlosAmericano) | Contributor (2 commits) |
| [@NevaSec](https://github.com/NevaSec) | Contributor (2 commits) |
| [@jmeliendrez](https://github.com/jmeliendrez) (pr0tag0nist) | Contributor & code author (1 commit) |
| [@WodenSec](https://github.com/WodenSec) | Code contributor |

### Special Thanks (from original project)

- **ToddAtLarge** (PNPT Certified) — for the NukeDefender script
- **Yaseen** (PNPT Certified) — for Alpha/Beta Testing
