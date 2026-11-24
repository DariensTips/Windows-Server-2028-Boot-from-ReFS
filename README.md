# Windows Server 2028: Boot from ReFS (Setup Walkthrough)

## Video

**Watch on YouTube** · https://www.youtube.com/watch?v=97jfkrlGRDg

| Field | Details |
| --- | --- |
| Author / channel | Darien Hawkins / Darien's Tips |
| Purpose | Install Windows Server 2028 Preview on a ReFS Windows volume, verify the partition layout, and boot into Windows Recovery Environment (WinRE). |
| Source script | `WSVR28BREFS_Title-Script_20261120.txt` |
| Preparation date | 2026-11-20 |
| Tested environment | Windows Server 2028 Preview, Desktop Experience and Server Core, in a Generation 2 Hyper-V lab with UEFI firmware and a GPT disk. |
| Usage notes | Choose one installation path per blank disk. Run each reference example at the indicated prompt. Formatting erases the selected partition. |

## Overview

The walkthrough answers two questions. Can Windows Server boot from a ReFS-formatted Windows partition? Can WinRE still locate and read that installation? The lab checks the file system inside Windows and a second time from the recovery console.

Windows Setup created a 2 GB recovery partition when ReFS was selected in its format dialog. A separate installation used DiskPart to reserve 4 GB for recovery. In both layouts the Windows partition uses ReFS, the EFI System Partition holds the UEFI boot files, and the recovery partition uses NTFS.

## Prerequisites

- Use Windows Server 2028 Preview installation media that offers ReFS in the interactive format dialog for the graphical path. Microsoft introduced ReFS boot in Windows Server Insider Preview build 29531. That number identifies the feature’s introduction. The recording does not specify the exact build installed.
- Use UEFI firmware and a GPT target disk. The walkthrough uses a Generation 2 Hyper-V VM and a single blank virtual disk. For the second installation, start from a blank target again.
- Have console access to Windows Setup and to the guest during the recovery boot. Use a local administrator session for the installed-server examples. Save open work before restarting.
- Verify your target disk by number and size before formatting. Back up anything you need to keep.

## Path A · Select ReFS in Windows Setup

1. At **Select location to install Windows Server**, select the target disk’s unallocated space. Choose **Create Partition** and accept the default size.
2. Select the primary **Windows** partition, Partition 3 in this lab. Choose **Format Partition**, select **I agree**, choose **ReFS**, and format.
3. Leave the recovery partition in place. Select the Windows partition and continue the installation.

| Order in the lab | Partition | Format | What the walkthrough shows |
| --- | --- | --- | --- |
| 1 | EFI System Partition (ESP) | FAT32 | Holds UEFI boot files. Disk Management shows 200 MB on the recorded disk. |
| 2 | Microsoft Reserved (MSR) | Unformatted | 16 MB. Use `Get-Partition` to see it. |
| 3 | Windows | ReFS | Becomes C: in the installed guest. The default-layout screenshot shows 637.79 GB. |
| 4 | Windows Recovery | NTFS | 2 GB created during interactive Setup. The manual path below uses 4 GB. |

### Check the installed server

- **Desktop Experience, 01:55.** Open **Disk Management** from the Start context menu. Look for ReFS on C: and the recovery partition immediately after it. Open the Windows volume’s **Properties** for a second view of the file system.
- **Server Core, 02:29.** Choose **15** in SConfig to return to PowerShell. `Get-Volume -DriveLetter C` reports the file system. The next two commands look up the partition for C:, read its disk number, and list every partition on that disk, including the MSR. [PowerShell reference](01-installed-windows-powershell.ps1)

## Path B · Make a 4 GB recovery partition with DiskPart

Begin a separate installation at **03:08**. On a blank disk, use **Create Partition** in Setup and accept the default. Open **Command Prompt** with **Shift+F10**, launch DiskPart, and enter the commands individually. [Setup and DiskPart reference](02-windows-setup-diskpart.txt)

| Step | Commands in the reference | What to look for |
| --- | --- | --- |
| Select the target | `LIST DISK`, `SELECT DISK 0`, `LIST PART`, `SELECT PART 3`, `LIST PART` | Match the expected disk size. The asterisk in the GPT column identifies a GPT disk. The asterisk to the left of a partition in the final list identifies the selected partition. |
| Reserve space | `SHRINK DESIRED=4096` | Free 4096 MB while the selected Windows partition is still NTFS. ReFS does not support volume shrink. |
| Format Windows | `FORMAT FS=REFS QUICK`, `DETAIL PART` | Confirm that the selected Windows partition now contains the ReFS volume. |
| Create recovery | `CREATE PART PRIMARY`, `FORMAT FS=NTFS QUICK` | The new partition takes focus and consumes the available space in this layout. Confirm creation succeeded before formatting. |
| Identify and protect recovery | `SET ID`, `GPT ATTRIBUTES`, `DETAIL PART` | Set the recovery type GUID, then set the platform-required and no-default-drive-letter attributes. Inspect the result. The exact values are below and in the reference. |

Return to Setup and refresh the disk list. Select the resized Windows partition, leave the 4 GB recovery partition in place, and complete Setup. After installation, verify the layout in Disk Management and use the unfiltered `Get-Volume` example to locate the ReFS volume. [Post-installation PowerShell reference](03-manual-install-verification.ps1)

## Test Windows Recovery Environment

1. At **05:24**, open administrative PowerShell in the installed guest. Run `reagentc /info`. Check for **Enabled** and a Windows RE location. On this layout, the location should point to the recovery partition on the target disk.
2. Run `reagentc /boottore` to request WinRE for the next boot. After it reports success, run `Restart-Computer` to restart the guest. [Installed Windows commands](04-installed-windows-recovery.txt)
3. At **Choose an option**, select **Troubleshoot**, then open **Command Prompt** from **Advanced options**.
4. Run `bcdedit`. Find the `osdevice` value under the **Windows Boot Loader** entry for the installed OS. That drive letter can change in WinRE.
5. Run `fsutil fsinfo volumeinfo c:` using the letter you found. **File System Name** reported **ReFS** in this lab. Reaching Advanced options and reading the installed volume were the recovery checks demonstrated. [WinRE commands](05-winre-command-prompt.txt)

## Placeholder guide

| Value in these files | How to use it |
| --- | --- |
| `0` in `SELECT DISK 0` | Substitute the target disk number shown by `LIST DISK` in Windows Setup. |
| `3` in `SELECT PART 3` | Substitute the verified Windows partition number shown by `LIST PART`. |
| `C` / `c:` | Use the installed Windows volume letter for PowerShell. In WinRE, check the Windows Boot Loader’s `osdevice` first. |
| `4096` | The demonstrated shrink amount in MB for a 4 GB recovery partition. |
| `DE94BBA4-06D1-4D40-A16A-BFD50179D6AC` | Fixed Windows Recovery Tools GPT type GUID. Use this value for the new recovery partition. |
| `0X8000000000000001` | Fixed attribute mask in this procedure. It marks the partition as required and suppresses automatic drive-letter assignment. |

## Microsoft references

### Windows Server Preview and partition layout

- [Windows Server 2028 public preview announcement](https://techcommunity.microsoft.com/blog/WindowsServerNewsandBestPractices/windows-server-2028-a-trusted-foundation-for-an-evolving-enterprise/4574112)
- [ReFS boot announcement and interactive Setup example](https://techcommunity.microsoft.com/blog/WindowsServerNewsandBestPractices/announcing-refs-boot-for-windows-server-insiders/4496592)
- [ReFS boot volume and NTFS recovery layout for unattended deployment](https://learn.microsoft.com/en-us/windows-server/storage/refs/refs-boot-windows-server-unattend)
- [Windows Server Insider Preview build 29651 notes on WinRE sizing](https://techcommunity.microsoft.com/discussions/windowsserverinsiders/announcing-windows-server-vnext-preview-build-29651/4549702)
- [Configure UEFI/GPT-based partitions](https://learn.microsoft.com/en-us/windows-hardware/manufacture/desktop/configure-uefigpt-based-hard-drive-partitions?view=windows-11)
- [Hyper-V virtual machine generations](https://learn.microsoft.com/en-us/windows-server/virtualization/hyper-v/plan/should-i-create-a-generation-1-or-2-virtual-machine-in-hyper-v)

### DiskPart and installed Windows

- [DiskPart and command focus](https://learn.microsoft.com/en-us/windows-server/administration/windows-commands/diskpart)
- [Shrink a volume](https://learn.microsoft.com/en-us/windows-server/administration/windows-commands/shrink)
- [Create a primary partition](https://learn.microsoft.com/en-us/windows-server/administration/windows-commands/create-partition-primary)
- [Set the GPT partition type](https://learn.microsoft.com/en-us/windows-server/administration/windows-commands/set-id)
- [Set GPT attributes](https://learn.microsoft.com/en-us/windows-server/administration/windows-commands/gpt)
- [Display partition details](https://learn.microsoft.com/en-us/windows-server/administration/windows-commands/detail-partition)
- [SConfig on Server Core](https://learn.microsoft.com/en-us/windows-server/administration/server-core/server-core-sconfig)
- [Get-Volume](https://learn.microsoft.com/en-us/powershell/module/storage/get-volume?view=windowsserver2025-ps)
- [Get-Partition](https://learn.microsoft.com/en-us/powershell/module/storage/get-partition?view=windowsserver2025-ps)

### Windows Recovery Environment

- [Windows RE technical reference](https://learn.microsoft.com/en-us/windows-hardware/manufacture/desktop/windows-recovery-environment--windows-re--technical-reference?view=windows-11)
- [REAgentC command-line options](https://learn.microsoft.com/en-us/windows-hardware/manufacture/desktop/reagentc-command-line-options?view=windows-11)
- [Restart-Computer](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.management/restart-computer?view=powershell-5.1)
- [Find the Windows volume from WinRE using BCDEdit](https://learn.microsoft.com/en-us/troubleshoot/windows-server/performance/use-winre-to-troubleshoot-startup-issue)
- [BCDEdit command reference](https://learn.microsoft.com/en-us/windows-server/administration/windows-commands/bcdedit)
- [Fsutil fsinfo volumeinfo](https://learn.microsoft.com/en-us/windows-server/administration/windows-commands/fsutil-fsinfo)

## Darien’s Tips

- [GitHub repository for this walkthrough](https://github.com/DariensTips/Windows-Server-2028-Boot-from-ReFS)
- [Earlier video on installing Windows Server vNext when the ReFS format option was missing](https://youtu.be/31Nu_BD9AHo)
- [Windows Server playlist](https://www.youtube.com/playlist?list=PLLmyrX1SggDCZTHKsEdHEVojSv-rIW2lL)
