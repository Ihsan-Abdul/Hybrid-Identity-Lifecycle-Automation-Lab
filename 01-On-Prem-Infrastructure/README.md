# Part 1 — On-Premises Infrastructure & Lifecycle

### Overview
This part of the project covers building a structured Active Directory environment and automating the full identity lifecycle: Joiner, Mover, and Leaver using PowerShell.

The approach was intentionally iterative. Rather than starting with a finished solution, each phase identified a limitation in the previous one and solved it before moving forward. The result is a progression from hardcoded scripts to parameterized, reusable automation scripts that reflects how IAM environments actually evolve in practice.

As the automation expanded, every design decision was driven by a security principle: role-based access control (RBAC) was used to enforce least privilege, group memberships were updated during role changes to reduce permission creep, and disabled accounts were retained in a dedicated OU to support auditing instead of being permanently deleted.


## Table of Contents
- [Phase 1 — Foundational Scripting](#phase-1--foundational-scripting)
- [Phase 2 — Structured Automation](#phase-2--structured-automation)
- [Phase 3 — Joiner Automation](#phase-3--joiner-automation)
- [Phase 4 — Mover Automation](#phase-4--mover-automation)
- [Phase 5 — Leaver Automation](#phase-5--leaver-automation)
- [Troubleshooting Case Study](#troubleshooting-case-study)
- [Outcome & Results](#outcome--results)

---

### Phase 1 — Foundational Scripting 

**Script:** `1-NewOU-Basic.ps1`

The first script built the foundational AD structure in one hardcoded block:

- Department OU structure
- Global and Domain Local security groups
- AGDLP group nesting for role-based access
- User accounts with assigned roles and group memberships

This version fully hardcoded:

- OU paths
- User attributes
- Group names

Although the script worked as intended, it became difficult to maintain and had had obvious limitations as additional users and departments were added. Every OU path, user attribute, and group name was hardcoded. Adding a new department or user meant editing the script directly. It wasn't reusable and it didn't scale.


[View script here](scripts/1-NewOU-Basic.ps1)

---

### Phase 2 — Structured Automation 

**Script:** `2-NewOU-Iterative.ps1`

The second iteration focused on eliminating repetition. The core change was moving from individual user creation commands to a data-driven loop structure:

```powershell
foreach ($User in $UserToCreate) {
    New-ADUser @UserParams
}
```

Other improvements introduced:

- Centralized environment variables (Domain, OU paths)
- Dynamic naming using `$Dept`
- Use of arrays to store user data
- Use of `foreach` loops for bulk user creation
- Continued use of splatting for readability


Instead of creating each account individually, the script now reads user information from an array and provisions every account through a single foreach loop. Expanding the environment only requires adding another object to the array instead of duplicating the provisioning logic.

[View script here](scripts/2-NewOU-Iterative.ps1)

---

## Phase 3 — Joiner Automation 

### First Joiner Script

**Script:** `3a-static-Joiner.ps1`

With the Active Directory environment set up, the next step was automating user onboarding. The first joiner script introduced control logic that wasn't present before:

- User existence validation before creation
- Try/Catch error handling to prevent silent failures
- Standardized attribute assignment

At this stage, the script was Still partially static at this stage, but the structure was there.

[View script here](scripts/3a-static-Joiner.ps1)

### Parameterized Joiner Script

**Script:** `3b-joiner.ps1`

The joiner was redesigned to accept runtime input rather than hardcoded values:

```powershell
param(
    [string]$Dept = "Marketing",
    [string]$FirstName = "Elena",
    [string]$LastName = "Mark",
    [string]$UserID = "emark",
    [string]$Title = "$($Dept) Staff"
)
```


The same script now handles any department or user without modification. Duplicate account validation was also added to prevent provisioning errors. 
This is the version that would actually be handed to a help desk or IT operations team to run.


[View Joiner script here](scripts/3b-joiner.ps1)

---

## Phase 4 — Mover Automation 

### Problem

User transitions are one of the most common sources of permission creep. A user moves departments, gets the new access, but nobody removes the old access. These scripts were built to prevent that.

### Role-Based Mover

**Script:** `4a-role-mover.ps1`

The first mover script handled role changes within the same department. The key logic is the group membership swap, the old role group is removed in the same operation that adds the new one, ensuring the user never holds both memberships simultaneously.

Logic:
- Check if user already has the target role
- Update user attributes
- Perform a group membership swap
  - Remove old group membership 
  - Add new group membership 

This ensures RBAC enforcement during promotions.

[View role mover script](scripts/4a-role-mover.ps1)

### Department Mover

**Script:** `4b-department-mover.ps1`

A second script handled cross-department moves. It extended the mover logic to cross-department transfers, adding OU relocation, manager reassignment, and department attribute updates alongside the group swap.

[View department mover](scripts/4b-department-mover.ps1)

### Master Mover Script 

**Script:** `4c-mover.ps1`

The final mover combines both scenarios into a single parameter-driven script. Conditional logic handles optional inputs like `ReportsToID` and `ReportsFromID` so the same script works for both role-only changes and full department transfers.

```powershell
Add-ADGroupMember -Identity $NewGroup -Members $UserID -ErrorAction Stop
Remove-ADGroupMember -Identity $OldGroup -Members $UserID -Confirm:$false -ErrorAction Stop
Write-Host "$UserId has moved from $OldGroup to $NewGroup"
```

The remove and add happen in the same execution block. The user is left only with the access their new role requires.


[View comprehensive Mover script here](scripts/4c-mover.ps1)

---

## Phase 5 — Leaver Automation 

**Script:** `5-Leaver.ps1`

The leaver script is the most complete stage of the lifecycle. It handles offboarding in a specific sequence designed to prevent both security gaps and orphaned data.

**Pre-check validation** — Detects if the account is already disabled or relocated to prevent duplicate execution.

**Subordinate reassignment** — Before anything else, identifies all users reporting to the departing employee and reassigns them to a new manager. This step must run before the account is moved because moving the object changes its Distinguished Name, which would break the manager reference.

```powershell
$Subordinate = Get-ADUser -Filter "Manager -eq '$($User.DistinguishedName)'"
if ($Subordinate) {
    $Subordinate | Set-ADUser -Manager $NewManager
    Write-Host "Re-assigned $($Subordinate.Count) subordinates to $NewManager"
}
```

**Access removal** — All group memberships except Domain Users are stripped, leaving the account in a zero-access state.

**Account decommissioning** — The account is disabled and moved to a Disabled Users OU. Deletion is intentionally avoided to maintain audit visibility and support any post departure access reviews.

**Implementation Note**
- Before disabling a manager's account, the script identifies and reassigns all subordinates to prevent "orphaned" reporting lines:


[View Leaver script here](scripts/5-Leaver.ps1)

---

## Troubleshooting Case Study

**Issue**

During the development of the Mover script, subordinate reassignment was failing after the user was moved to a new OU.

**Root Cause**

Moving a user object in Active Directory changes its Distinguished Name immediately. The script was storing the DN before the move and referencing it after, but by that point the reference was stale and so the reassignment failed.

**Resolution**

Execution order was corrected to run subordinate reassignment before the OU move, not after:

1. Reassign subordinates (while DN is still valid)
2. Remove group memberships
3. Disable account
4. Move object to Disabled Users OU

**Key learning** — Active Directory object attributes update in real time. In automation workflows, execution order isn't just a logic preference, it's a dependency that determines whether the operation succeeds or fails.

**Key Takeaways** — Building the project incrementally reinforced several practical Active Directory concepts beyond writing PowerShell scripts. As the automation became more complex, maintaining execution order, preserving manager relationships, updating group memberships, and designing reusable scripts became just as important as provisioning users. The project also shows how identity lifecycle automation supports security by reducing manual administration and enforcing consistent automated access management.

---

### Outcome & Results

A full end-to-end lifecycle test validated the complete automation suite:

- **Joiner:** `emark` provisioned into Marketing OU with correct group 
  memberships and role assignment
- **Mover:** `emark` transferred to Finance, group swap completed, old 
  role access removed
- **Leaver:** `asmith` offboarded — all group memberships stripped, 
  subordinates reassigned, account disabled and relocated to Disabled Users OU
  
![Image of JML automated process](images/jml-script-screenshot.png)
