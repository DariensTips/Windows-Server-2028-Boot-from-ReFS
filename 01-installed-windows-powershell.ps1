# Title: Verify the ReFS Windows volume and its GPT disk layout
# Author/channel: Darien Hawkins / Darien's Tips
# Purpose: Check the installed Windows file system and enumerate the partitions on its disk.
# Source script: WSVR28BREFS_Title-Script_20261120.txt
# Preparation date: 2026-11-20
# Tested environment: Windows Server 2028 Preview, Server Core in a Generation 2 Hyper-V lab.
# Usage notes: Read-only examples. Run the two lines in Example 2 in the same PowerShell session.
#
# Target: The installed Windows Server guest. The same cmdlets work with Desktop Experience.
# Shell and privileges: Local Windows PowerShell with read access to the Storage provider.
# An administrator session can perform both queries.
# Prerequisites: Complete Windows Setup. On Server Core, select option 15 in SConfig.

# Example 1. Check the file system and capacity of the installed Windows volume.
Get-Volume -DriveLetter C

# Example 2. Find the disk containing C: and list its full partition layout, including the MSR.
$windowsPartition = Get-Partition -DriveLetter C
Get-Partition -DiskNumber $windowsPartition.DiskNumber
