# Title: Check volumes after the custom recovery partition installation
# Author/channel: Darien Hawkins / Darien's Tips
# Purpose: Display the volumes visible to the installed server after the manual setup path.
# Source script: WSVR28BREFS_Title-Script_20261120.txt
# Preparation date: 2026-11-20
# Tested environment: Windows Server 2028 Preview in the Generation 2 Hyper-V lab, custom 4 GB WinRE layout.
# Usage notes: Read-only example from the end of the manual installation chapter.
#
# Target: The installed guest after Windows Setup completes.
# Shell and privileges: Local Windows PowerShell with read access to the Storage provider.
# An administrator session can perform this query.
# Prerequisites: Boot the installation that used the DiskPart layout.
#
# Example. List volumes and locate the ReFS Windows volume.
# In Desktop Experience, Disk Management also shows the 4 GB recovery partition.
Get-Volume
