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

## Before You Begin

1. Create three virtual machines on an isolated virtual network.
2. Install the operating systems listed above and the guest tools for your hypervisor.
3. Reboot each virtual machine after installing its guest tools.
4. Copy the same version of `lab_creator.ps1` to each machine.
5. Edit the configuration block at the beginning of the script before the first run. This controls the domain, host names, IP-address suffixes, account names, and passwords.

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

If a workstation does not join the domain, confirm that `STARBASE-1` has completed its final run, all VMs are on the same isolated virtual network, and the domain controller is reachable by name.

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
