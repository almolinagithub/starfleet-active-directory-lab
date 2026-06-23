# Starfleet Active Directory Lab

A Windows Active Directory practice lab with a Star Trek theme. The primary script provisions a domain controller, two workstations, sample accounts, and supporting lab configuration.

## Configuration

Before running the script, edit the configuration block at the top of `lab_creator.ps1`.

- Domain: `STARFLEET.local`
- Domain controller: `ENTERPRISE-DC`
- Workstations: `ENTERPRISE-01` and `VOYAGER-01`
- Lab accounts: James T. Kirk, Spock, Leonard McCoy, and Data

The host names, account names, passwords, and IP-address suffixes are configurable from this block. The service account may be renamed; its SQL service principal names remain associated with the selected account.

## Requirements

- Windows Server or Windows workstation virtual machines suitable for an Active Directory lab
- PowerShell running as Administrator
- Isolated lab environment only

## Running the Lab

Run `lab_creator.ps1` as Administrator on the relevant virtual machine, then select the corresponding menu option for the domain controller or a workstation. Some steps reboot the computer; rerun the script when prompted.

## Validation

The script has been parsed successfully with PowerShell 7.6.1.

## Safety

This script deliberately changes security settings for a controlled training environment. Do not run it on production systems or a network that you do not own and administer.
