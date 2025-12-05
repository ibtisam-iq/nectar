# Complete Guide: Dual Booting Pop!_OS 24.04 LTS with Windows 11 (2025 Edition)

This in-depth guide walks you through installing Pop!_OS alongside Windows 11 for a stable dual-boot setup. Pop!_OS excels for developers (e.g., Docker, Kubernetes) with its COSMIC desktop, systemd-boot, and seamless hardware support. We'll cover cleanup, partitioning pitfalls (especially EFI), installation, and fixes—assuming prior Linux attempts left remnants.

> **⚠️ Critical Warning:** Partitioning risks data loss. **Backup everything** (use Macrium Reflect for images). Test in a VM first. Proceed at your own risk—this is for UEFI systems only.

## Table of Contents

- [Step Zero: Preparing the Pop!_OS Bootable USB](#step-zero---preparing-the-pop_os-bootable-usb)
- [Step 1: Clean Old Linux Boot Entries + EFI Partitions (Windows Side)](#step-1---clean-old-linux-boot-entries--efi-partitions-windows-side)
- [Step 2: Create Clean Unallocated Space for Pop!_OS Installation](#step-2---create-clean-unallocated-space-for-pop_os-installation)
- [Step 3: Understanding the ESP (EFI System Partition) Requirement for Pop!_OS](#step-3---understanding-the-esp-efi-system-partition-requirement-for-pop_os)
  - [Additional Clarification: The Three Possible Options for ESP (And Why Two Are Dangerous)](#additional-clarification-the-three-possible-options-for-esp-and-why-two-are-dangerous)
- [Step 4: Creating the New 1GB Unallocated Space Directly After MSR (Using AOMEI Partition Tool)](#step-4---creating-the-new-1gb-unallocated-space-directly-after-msr-using-aomei-partition-tool)
- [Step 5: Final System Checks Before Installing Pop!_OS](#step-5---final-system-checks-before-installing-pop_os)
- [Step 6: Installing Pop!_OS Using Custom (Advanced) Mode](#step-6---installing-pop_os-using-custom-advanced-mode)
- [Step 7: Post-Installation Fixes (Boot Menu + Windows Boot Manager)](#step-7---post-installation-fixes-boot-menu--windows-boot-manager)
- [Resources and Further Reading](#resources-and-further-reading)

## Step Zero — Preparing the Pop!_OS Bootable USB

This step covers everything required before installing Pop!_OS alongside Windows 11.
The goal is simple: **create a clean, bootable USB** that can be used for dual-boot.

---

## 1. Download the Pop!_OS ISO

Open the official Pop!_OS website and download the correct ISO file for your hardware.

* NVIDIA ISO → for systems with dedicated NVIDIA GPU
* Intel/AMD ISO → for systems with integrated graphics

This ensures the correct drivers are available during installation.

---

## 2. Download Balena Etcher

To flash the ISO onto your USB, download Balena Etcher from its official website.

We will use Etcher because:

* It is fast
* Works on Windows, macOS, and Linux
* Automatically verifies the flashed image
* Supports standard Linux ISO files
* UI is extremely simple (3-step flashing)

---

## 3. Flash the ISO to USB

Once Etcher is installed:

1. Click **Flash from File** → select your Pop!_OS ISO
2. Click **Select Target** → choose your USB drive
3. Click **Flash**

After flashing completes successfully, your USB is ready for use.

---

# Troubleshooting (Important)

Sometimes the USB refuses to flash properly.
A common reason is:

### Your USB already contains an old bootable image

This creates partition conflicts and causes Etcher errors.

Example symptoms include:

* Etcher showing errors like:
  `Error opening source`
  `requestMetadata is not a function`
* Etcher not recognizing the USB properly
* Flashing stuck or instantly failing
* USB showing strange partitions (like a 4 MB EFI partition)

### Root cause:

A leftover EFI or boot partition remains on the USB.

Windows Disk Management **cannot** delete these small partitions.

---

### Fix (100% working): Wipe USB using DISKPART

This completely removes all partitions and resets the USB to a clean state.

> ⚠ Double-check the disk number before running clean
> If you select your SSD by mistake, you will lose everything.

Steps:

```cmd
diskpart
list disk
select disk X   ← (your USB)
clean
exit
```

After this, the USB becomes fully unallocated and Etcher will work perfectly.

---

# Important Note about Etcher (MUST READ)

Etcher shows an option under the tasks area called:

**“Upgrade and Manage Devices”**

This **must stay unchecked**.

Why?

Because:

* It belongs to BalenaCloud
* It is for IoT device management (Raspberry Pi, embedded devices)
* It provisions devices for remote management
* It converts the USB into a balenaOS device
* It has nothing to do with installing Pop!_OS
* It can break the flashing process

### ✔ Always keep it OFF

### ✔ Only use:

`Flash from File → Select Target → Flash`

---

# Outcome of Step Zero

By the end of Step Zero, you will have:

✔ A fully cleaned USB
✔ Pop!_OS ISO properly flashed
✔ USB ready to boot into the installer
✔ No leftover EFI or boot partitions
✔ No conflicts or Etcher errors

---

## Step 1 — Clean Old Linux Boot Entries + EFI Partitions (Windows Side)

This step ensures that all previous Linux distributions are fully removed from the system before installing Pop!_OS.
We work from Windows because Windows controls the active EFI bootloader.

---

## 1. Boot into Windows

We start from Windows so we can safely edit the firmware-level boot entries and the EFI partition.

---

## 2. Open Command Prompt as Administrator

Search for **cmd**, right-click, and select **Run as administrator**.
This grants permission to modify firmware boot entries.

---

## 3. List All Firmware Boot Entries

Run:

```cmd
bcdedit /enum firmware
```

This command displays every bootloader registered in the system firmware, including:

• Windows Boot Manager
• Ubuntu
• Linux Mint
• Pop!_OS
• Sparky / SevenSister
• Any other leftover entries

These entries appear because old Linux installations leave behind firmware records and EFI folders.

---

## 4. Identify Unwanted Linux Boot Entries

Look for entries with descriptions like:

```
description Ubuntu
```

or

```
description Sparky
description SevenSister
description Linux
```

These represent leftover Linux bootloaders that must be removed.

Example:

```
identifier  {505e84cf-9067-11f0-bff8-806e6f6e6963}
description Sparky
path        \EFI\Sparky\shimx64.efi
```

This is a valid target for deletion.

---

## 5. Delete the Unwanted Boot Entry

Use the GUID you identified:

```cmd
bcdedit /delete {GUID}
```

Example (your actual case):

```cmd
bcdedit /delete {505e84cf-9067-11f0-bff8-806e6f6e6963}
```

This removes the Linux bootloader entry from the firmware (BIOS/UEFI boot menu).

---

## 6. OPTIONAL BUT HIGHLY RECOMMENDED: Clean the EFI Partition

This removes the leftover Linux bootloader files stored on the disk.

### 6.1 Mount the EFI Partition

```cmd
mountvol S: /s
```

### 6.2 Navigate to EFI folder

```cmd
S:
cd EFI
dir
```

Typical contents may include:

```
Microsoft      ← Windows bootloader (KEEP)
Boot           ← Generic fallback boot entry (KEEP)
HP             ← OEM firmware tools (KEEP)
ubuntu         ← Leftover Ubuntu/Mint/Zorin bootloader (DELETE)
sparky         ← Sparky Linux leftover (DELETE)
debian         ← Debian-based leftover (DELETE)
```

### 6.3 Delete only the Linux-related folders

Remove each safely:

```cmd
rmdir /s /q ubuntu
rmdir /s /q sparky
rmdir /s /q debian
```

### 6.4 DO NOT delete these:

```
Microsoft
Boot
HP
```

These are essential system components.

---

## 7. Verify Cleanup

Run:

```cmd
dir
```

Your EFI directory should now contain only:

```
Microsoft
Boot
HP
```

This confirms:

• All Linux bootloaders are removed
• Firmware entries are clean
• System is ready for a fresh Pop!_OS dual-boot installation

---

## ✅ Step 2 — Create Clean Unallocated Space for Pop!_OS Installation

This step prepares the disk for Pop!_OS by ensuring clean, unused, **unallocated** space.
Dual-boot installations require a separate partition area where the Linux installer can create its own:

• EFI entry
• root filesystem
• swap (if needed)
• optional home partition

Pop!_OS **cannot** be installed safely without unallocated space.

---

## 1. Why This Step Is Necessary

When installing Pop!_OS in *Custom (Advanced)* mode, the installer will ask you to select **unallocated space**.
If this space is not available:

• the installer may try to overwrite existing partitions
• Windows could break
• Linux bootloader may fail
• the system may become unbootable

Therefore, creating clean unallocated space is mandatory.

---

## 2. If the Laptop Already Has an Existing Linux Installation

Many systems have leftover Linux partitions from previous installations.
Even if you deleted EFI boot entries in Step 1, the actual Linux filesystem partitions still remain.

Leftover partitions typically include:

• `/` (root)
• `/home`
• `swap`
• Linux reserved partitions

If these remain:

• They still occupy disk space
• They still contain Linux filesystem metadata
• Installing into them again can cause GRUB leftovers and conflicts
• Boot may freeze if EFI files were removed but filesystem wasn't

So we must delete these partitions completely.

---

## 3. IMPORTANT: Why Step 1 Must Be Done Before Step 2

If you delete only the Linux partitions **but do not delete the EFI bootloader folders**, then:

• BIOS will still try to load the old Linux boot entry
• System will get stuck at a missing GRUB shim
• Laptop may fail to boot

This is exactly why Step 1 cleans firmware + EFI first.
Step 2 now safely removes the actual Linux data partitions.

---

## 4. If No Linux Is Currently Installed

If the system has no Linux partitions, skip directly to:

### Shrinking the Windows partition (usually C:)

Use:

**Disk Management → Right-click C: → Shrink Volume**

This creates the required unallocated space for Pop!_OS.

---

## 5. Decide How Much Space to Allocate

This depends on your usage:

• Minimum recommended: **50 GB**
• Comfortable for DevOps: **100–150 GB**
• Ideal (what you did today): **200 GB**

You chose **200 GB**, which is perfect for:

• Docker workloads
• Kubernetes clusters (k3d, kind, minikube, microk8s)
• VM usage
• Build pipelines
• Any DevOps/AIOps workflows

---

## 6. VERY IMPORTANT: Do NOT Format the Unallocated Space

After shrinking the disk or deleting old Linux partitions:

**Leave the space as UNALLOCATED.**

Do NOT create:

• NTFS
• FAT32
• EXT4
• ANY filesystem

Why?

Because the Pop!_OS installer needs **raw unallocated space** so it can:

• Create its own partitions
• Manage EFI entries correctly
• Build the correct Linux filesystem layout

If you format it yourself, the installer will not detect "free" space and the installation will break.

---

## 7. Summary of Step 2 Actions

### If Linux already existed:

✔ Delete Linux partitions
✔ DO NOT touch Windows partitions
✔ Leave the space unallocated

### If Linux did not exist:

✔ Shrink C: drive to create unallocated space
✔ Again: leave it completely unformatted

At the end of Step 2, you must see:

```
200 GB Unallocated
```

Or whatever size you chose.

This unallocated block is where Pop!_OS will be installed during Step 3.

---

## 8. How Pop!_OS Uses the Unallocated Space (Partition Layout)

When you choose **Custom (Advanced)** mode during Pop!_OS installation, the installer will automatically create **two partitions** inside the unallocated space:

### 1. Root partition (`/`)

This is the main Linux filesystem containing:

• OS files
• user files
• configs
• packages
• system-level data

Your entire Pop!_OS installation lives here.

### 2. Swap partition

Swap is used when RAM is full.
It also provides stability during heavy workloads (Docker, containers, VMs, builds).

---

## Recommended Swap Size

For a system with **16 GB RAM** (like yours):

• **4 GB swap** is more than enough
• Only increase swap to **16 GB** if you plan to use **hibernation**

### Swap rules summary:

| RAM   | Use Case        | Recommended Swap |
| ----- | --------------- | ---------------- |
| 8 GB  | normal use      | 2–4 GB           |
| 16 GB | normal use      | 4 GB             |
| 16 GB | hibernation     | 16 GB            |
| 32 GB | heavy workloads | 4–8 GB           |
| 32 GB | hibernation     | 32 GB            |

Since you are **not** using hibernation, your system should create:

✔ **Root (/)** partition
✔ **4 GB Swap**

This will happen **inside your 200 GB unallocated space**.

---

## 9. Why Only Two Partitions Are Needed

Pop!_OS does **not** require:

✘ separate `/boot`
✘ separate `/home`
✘ separate EFI (it uses existing Windows EFI)

Pop!_OS uses a simple, clean layout to avoid GRUB conflicts and to keep the dual-boot stable.

This is why Step 2 was crucial — you must provide raw unallocated space so Pop!_OS can:

• create the correct root filesystem
• create swap partition
• link to Windows EFI
• avoid overwriting existing partitions
• ensure a clean dual-boot setup

---

## 10. Final Outcome of Step 2

At the end of Step 2, your disk should show:

```
200 GB Unallocated Space (or whatever you chose)
```

And this space will later become:

```
/      (main Linux filesystem)
swap   (4 GB recommended)
```

These will be created automatically by the Pop!_OS installer in Step 3.

---

## ✅ Step 3 — Understanding the ESP (EFI System Partition) Requirement for Pop!_OS

Before creating any new partitions, it’s important to understand **how Pop!_OS handles booting** and **why it cannot use the existing Windows EFI partition**.

This step explains the ** theory**, not the actual partition creation.

---

# 1. Old Linux World: GRUB-Based Booting

Traditionally, Linux used **GRUB**:

1. Linux installer creates GRUB
2. GRUB detects Windows
3. GRUB becomes the primary bootloader
4. Startup menu appears:

```
Ubuntu
Windows Boot Manager
```

Everything is managed **inside Linux**, not Windows.

In this world:

✔ The existing 100 MB Windows EFI partition was usually enough
✔ Linux could install GRUB into the same ESP
✔ No new ESP was required

---

# 2. Pop!_OS is NOT part of the old Linux world

Pop!_OS **does not use GRUB.**

It uses:

```
systemd-boot
```

This changes the entire boot logic.

systemd-boot:

• does NOT overwrite Windows
• does NOT modify Windows ESP
• requires a **proper, spacious, dedicated EFI partition**
• has stricter UEFI layout requirements
• refuses small/legacy ESPs

---

# 3. Why Windows’ 100 MB EFI Partition Cannot Be Used

The Windows ESP is:

• too small (100MB)
• intended only for Windows boot files
• heavily optimized by Windows
• unsafe to modify
• can break after a Windows update
• **explicitly rejected** by Pop!_OS installer with the message:

> “This EFI partition is too small.”

In the old GRUB world, 100MB was enough.

In the modern systemd-boot world:

❌ 100MB is not enough
❌ Using Windows ESP is unsafe
❌ Installer will not proceed

---

# 4. Therefore: Pop!_OS Needs a Separate ESP (Boot Partition)

Pop!_OS requires a new EFI System Partition, typically:

✔ **500 MB – 1000 MB**
✔ FAT32
✔ With “boot” and “esp” flags
✔ Located in the **correct physical position** on the disk

This new ESP will hold:

```
/boot/efi
systemd-boot files
Pop!_OS kernel entries
```

---

# 5. Why the New ESP Must Be in a VERY Specific Location

This is the MOST misunderstood part by almost all dual-boot users.

UEFI firmware reads partitions in the following physical order:

```
[ Partition #1 ]
[ Partition #2 ]
[ Partition #3 ]
...
```

For dual boot to be clean:

✔ Windows ESP → stays first
✔ MSR (Microsoft Reserved) → stays second
✔ Pop!_OS ESP → must come directly after MSR

It **cannot** be:

• at the end of the disk
• placed after C:
• placed after Recovery
• placed 200GB away
• placed randomly in free space

Pop!_OS installer will **not detect it** if it is out of order.

---

# 6. Why We Cannot Place the ESP Inside the 200GB Unallocated Space

This is crucial.

Your disk layout originally looked like this:

```
[ EFI (Windows) ]
[ MSR ]
[ C: Windows ]
[ 200GB Unallocated ]
[ Recovery ]
```

If we create the Pop!_OS ESP inside the 200GB unallocated block, the layout becomes:

```
[ EFI ]
[ MSR ]
[ C ]
[ ESP for Pop!_OS ]
```

This is **invalid** because:

❌ systemd-boot will not accept an ESP after C:
❌ Firmware expects OS bootloaders before primary OS partitions
❌ Pop!_OS installer will not show the partition
❌ Dual-boot will break
❌ Windows updates may corrupt the boot order

Pop!_OS and UEFI both require:

```
ESP must be directly after MSR.
```

---

# 7. Why We Cannot “Extend” the Existing Windows ESP

You said this yourself, and it’s correct:

✔ Extending the 100MB Windows ESP is extremely risky
✔ It can corrupt Windows boot manager
✔ A failed extend = Windows becomes unbootable
✔ Modern Windows installations lock the ESP
✔ Tools refuse to expand it because of system metadata and GPT alignment

So extending is **not an option**.

---

# 8. The Only Safe Solution

✔ Create a **new** 1000 MB unallocated space
✔ Move this space so that its physical position becomes:

```
[ EFI ]
[ MSR ]
[ 1000 MB Unallocated ]
```

✔ This will later be converted into the **Pop!_OS ESP** (`/boot/efi`)

This cannot be done with Disk Management.
It **requires a third-party tool** because you must:

• move Recovery
• move C: boundaries
• rearrange partitions correctly
• preserve disk order
• avoid damaging boot sectors

This step is extremely sensitive — a mistake breaks Windows instantly.

---

# 9. Summary of the Theory for Step 3

Before creating partitions, you MUST understand these rules:

### ✔ Pop!_OS uses systemd-boot, not GRUB

### ✔ Pop!_OS needs its own ESP (boot partition)

### ✔ Windows’ 100MB ESP is too small

### ✔ ESP must be 500–1000MB in size

### ✔ ESP must be placed directly after MSR

### ✔ ESP **cannot** be placed inside the 200GB free space

### ✔ Disk Management cannot perform this layout

### ✔ A third-party partition manager must be used

### ✔ Incorrect placement will break installation

### ✔ Incorrect movement may break Windows

This theory prepares you for the *actual* Step 4, where we will use a safe tool to create and position the ESP correctly.

---

## ✅ Step 3 — Additional Clarification: The Three Possible Options for ESP (And Why Two Are Dangerous)

*(This section is appended to the previous Step 3. Do NOT replace Step 3, just add this.)*

Before creating the new Pop!_OS ESP, it is important to understand that in theory you have **three possible options** for handling EFI.
But only **one** of them is safe.

This section explains all three options clearly.

---

# Option 1 — Use the existing 100MB Windows ESP

### ❌ This option is rejected by Pop!_OS

Why?

1. It is too small (100MB)
2. Pop!_OS installer gives the error:

   > “This EFI partition is too small.”
3. systemd-boot requires more space
4. Mixing Windows boot files + Linux boot files increases risk
5. Windows updates may delete Linux entries
6. Dual-boot becomes unstable

**Conclusion:**
This option is not usable and not safe.

---

# Option 2 — Extend the existing Windows ESP

### ❌ Technically possible, but highly dangerous

This option means:

• Create unallocated space next to the 100MB ESP
• Use a tool to extend the Windows EFI partition
• Make it 900–1100MB total
• Install Pop!_OS and Windows inside the same ESP

Why this is dangerous:

1. Extending the Windows EFI can corrupt the Windows bootloader
2. If alignment fails → Windows becomes unbootable
3. If metadata moves incorrectly → BCD corruption
4. The Windows ESP is a sensitive system partition
5. Recovery tools may fail
6. Windows updates may overwrite Pop!_OS boot entries in the shared ESP

So:

✔ Yes, extending the ESP **was an option**
✔ But it is **not recommended** for modern dual-boot
✔ It introduces long-term risk even if it works once

**Conclusion:**
We intentionally avoided this option.

---

# Option 3 — Create a Separate ESP for Pop!_OS (Safe Choice)

### ✔ The safest, cleanest, modern solution

This was our final choice.

Why?

1. Pop!_OS gets its own clean ESP
2. Windows remains untouched
3. systemd-boot runs independently
4. Windows updates cannot overwrite Pop!_OS
5. Debugging becomes easier
6. Partitioning is clean and future-proof
7. Bootloaders are fully isolated

### The ONLY requirement:

✔ The new ESP must be placed **directly after the MSR partition**
(not at the end of disk)
(not inside the 200GB space)
(not after C drive)

Because UEFI firmware and systemd-boot expect a **top-ordered boot partition**.

This is why we used a **third-party partition tool** to:

• move Recovery
• shuffle partitions
• bring the new 1000MB unallocated space right after MSR

Only after achieving this exact layout does the Pop!_OS installer detect the new ESP.

**Conclusion:**
This is the safest and most stable dual-boot architecture.
This is the option we used.

---

# Final Summary of the Three ESP Options

| Option | Description                    | Safe?               | Why / Why Not                                         |
| ------ | ------------------------------ | ------------------- | ----------------------------------------------------- |
| 1      | Use 100MB Windows ESP          | ❌ Unsafe + Rejected | Too small, dangerous, Windows may overwrite           |
| 2      | Extend Windows ESP             | ❌ Very risky        | Extension can break bootloader, long-term instability |
| 3      | Create New 1GB ESP for Pop!_OS | ✔ 100% Safe         | Separate loaders, modern structure, stable dual-boot  |

---

## ✅ Step 4 — Creating the New 1GB Unallocated Space Directly After MSR (Using AOMEI Partition Tool)

This step creates the **1GB unallocated block** that will later become the **Pop!_OS /boot/efi** partition.

Windows Disk Management **cannot** do this.
Manual commands **cannot** do this.
Simple tools **cannot** do this.

We must use an **advanced partition manager** that supports:

✔ Moving system partitions
✔ Shifting the C: boundary from the left
✔ Adjusting “unallocated before”
✔ Rebooting into Pre-OS environment

The tool used here:
**[AOMEI Partition Assistant Standard (Free)](https://getintopc.com/softwares/disk-management/aomei-partition-assistant-all-editions-2025-free-download/)**

---

# 1. Why This Tool Is Required

Windows stores partitions in a fixed physical order:

```
[ EFI ] [ MSR ] [ C: ] [ Recovery ]
```

We must insert:

```
[ 1GB Unallocated ]
```

**between MSR and C:**

This requires moving the entire C: partition to the right — something Windows cannot do while running.

That is why a third-party tool is required.

---

# 2. Open the Partition Tool

Launch AOMEI Partition Assistant and locate:

```
C:
Type: NTFS
Status: System, Primary
```

Right-click the **C: partition**
Select **Resize / Move Partition**

---

# 3. Enable the Critical Checkbox

Inside the popup (same as your screenshot):

Make sure these are enabled:

✔ **Using enhanced data protection mode**
✔ **I need to move this partition**

This second option is *crucial*.

If you DO NOT enable:

```
I need to move this partition
```

Then:

✘ You cannot drag the left boundary
✘ You cannot create “Unallocated space before”
✘ You can only shrink from the right
✘ You cannot place free space after MSR

With the checkbox enabled, the field:

```
Unallocated space before: [   ]
```

becomes editable.

---

# 4. Create the 1GB Unallocated Space BEFORE C:

In the field:

```
Unallocated space before:
```

Type:

```
1024 MB
```

Or use the slider to push the C: partition slightly to the right.

Now your preview will show:

```
[ EFI ] [ MSR ] [ 1024MB Unallocated ] [ C: ] [ Recovery ]
```

This is exactly what we need.

Click **OK**.

---

# 5. Apply the Operation

Click the **Apply** button (top-left corner).

AOMEI will now warn you that this operation:

✔ Requires a reboot
✔ Will enter **PreOS Mode**

You will see a popup with three options:

1. **Restart into PreOS mode** ← **Select this**
2. Windows PE mode
3. AIK/ADK installation (ignore)

Select:

### 👉 **Restart into PreOS mode**

Then click **OK → Proceed**

Your laptop will reboot.

---

# 6. PreOS Mode Will Move the Partition

A blue/black AOMEI environment will run before Windows starts.

It will:

• lock the disk
• move the C: partition to the right
• create 1GB empty space directly after MSR
• maintain GPT alignment
• protect Windows BCD

This takes a few minutes.

When complete, the system boots back into Windows.

---

# 7. Verify the Result

Open the partition tool again or Windows Disk Management.

You should now see:

```
100MB   EFI System Partition
16MB    MSR (Microsoft Reserved)
1024MB  Unallocated   ← NEW
C:
Recovery
```

This is the **correct layout required** for Pop!_OS systemd-boot.

---

# 8. DO NOT FORMAT THIS SPACE

Just like Step 2, this space must remain:

```
Unallocated (Raw)
```

Because during installation, Pop!_OS will create:

✔ `/boot/efi` on this 1GB region
✔ Itself, using FAT32 + ESP + boot flags

We do NOT prepare it manually.

---

# Final Outcome of Step 4

At this point:

✓ A dedicated 1GB unallocated block exists
✓ It is correctly positioned between MSR and C:
✓ It is ready to become the Pop!_OS boot partition
✓ No formatting was done
✓ Windows remains untouched
✓ Disk layout now satisfies Step 3 theory

This completes Step 4.

---

## ✅ Step 5 — Final System Checks Before Installing Pop!_OS

Before starting the actual Pop!_OS installation, we must verify that the system is correctly prepared.
This ensures a safe dual-boot environment, prevents Windows boot failures, and guarantees that the Linux installer will detect partitions correctly.

This step performs **three things only**:

1. Confirm BitLocker is OFF
2. Confirm Secure Boot is OFF
3. Boot from USB correctly (F9 on HP laptops)

---

## 1. Verify BitLocker Is Disabled (Mandatory)

Pop!_OS installation modifies EFI entries.
If BitLocker is ON, Windows may lock you out and ask for a recovery key after reboot.

Check BitLocker status using:

```cmd
manage-bde -status
```

Expected output:

```
BitLocker Version:    None
Conversion Status:    Fully Decrypted
Percentage Encrypted: 0.0%
Protection Status:    Protection Off
Key Protectors:       None Found
```

### ✔ Interpretation:

* BitLocker is fully disabled
* C: drive is decrypted
* No encryption keys exist
* No risk of BitLocker recovery screen
* Safe to proceed with Linux installation

If BitLocker is ON → **STOP** and turn it off before continuing.

---

## 2. Verify Secure Boot Is Disabled (Mandatory)

Pop!_OS uses **systemd-boot**, not GRUB.
It does NOT support Secure Boot in default mode.

Check Secure Boot from Windows:

### Method 1 — System Information

1. Press Windows key
2. Type: **System Information**
3. Find:

```
Secure Boot State: Off
```

### Method 2 — PowerShell

```powershell
Confirm-SecureBootUEFI
```

Expected output:

```
False
```

### ✔ Interpretation:

* Secure Boot = OFF → Pop!_OS installer will work
* No UEFI signature conflicts
* systemd-boot can install safely

If Secure Boot = True → disable it in BIOS.

---

## 3. Prepare to Boot the Pop!_OS USB (HP Laptops)

This point is very important, especially for HP laptops:

### ✔ Do NOT press **ESC**

ESC opens the **Startup Menu** (not the Boot Menu).
You already confirmed this from your own experience.

### ✔ You MUST press **F9**

F9 opens the **Boot Menu**, which shows:

* [UEFI] USB Flash Drive
* Windows Boot Manager
* Internal Hard Drive
* Network Boot

This is where you select the Pop!_OS USB.

### Correct boot flow on HP:

1. Insert USB
2. Power on laptop
3. Immediately press:
     # 👉 **F9**
4. Select the entry:
     **USB UEFI: <your USB name>**
5. Pop!_OS installer will start

This begins the actual installation phase.

---

## 4. Summary of Step 5 (End Result)

After completing this step:

✔ All old Linux systems are removed
✔ Old partitions are deleted
✔ New 1GB ESP space is created
✔ New root/swap space is created
✔ BitLocker is OFF
✔ Secure Boot is OFF
✔ USB boot menu is known (F9)
✔ System is fully prepared for installation

At this point, the system is in a **perfect, clean state**, and you are ready to proceed to the next step:

---

## ✅ Step 6 — Installing Pop!_OS Using Custom (Advanced) Mode

This step performs the actual Pop!_OS installation, using the custom partition layout we prepared in earlier steps.

Pop!_OS provides two installation modes:

* **Clean Install** → wipes the *entire* disk
* **Custom (Advanced)** → lets you choose partitions manually

Because we are dual-booting with Windows:

# ❌ We must NOT select “Clean Install.”

It will wipe the entire disk including Windows.

We must select:

# ✔ Custom (Advanced) Install

---

# 6.1 — Enter the Custom Partitioning Tool

After selecting:

✔ Language
✔ Keyboard
✔ Time zone

You will reach the installation page with two options:

* **Clean Install**
* **Custom (Advanced)**

Select:

### 👉 Custom (Advanced)

Then click:

### 👉 Modify Partitions

This opens the partition editor.

---

# 6.2 — Identify Your Two Unallocated Spaces

You should see exactly two unallocated spaces:

1. **200GB unallocated** (from Step 2)
2. **1GB unallocated** (from Step 4)

These two spaces will become:

* `/boot/efi` → 1GB
* `/` root → 200GB minus swap
* `swap` → 4GB

### 🔥 HIGHLY SENSITIVE POINT

Carefully identify which unallocated block is which:

* The **1GB** space sits **right after MSR**
* The **200GB** space sits **after C: (Windows)**

If you select the wrong one → you destroy Windows.

---

# 6.3 — PART A: Create the Required Partitions

## Step A1 — Create SWAP (4GB)

1. Right-click the **200GB unallocated space**
2. Select **New**
3. In the size field, type:

```
4096 MB
```

4. Type: **Linux swap**
5. Do **not** give a label
6. Click **Create**

This creates `/dev/sda5` (swap).

---

## Step A2 — Create ROOT (`/`)

1. Right-click the *remaining* part of the 200GB block
2. Select **New**
3. Use the entire remaining space
4. Type: **ext4**
5. No label needed
6. Click **Create**

This creates `/dev/sda6` (root).

---

## Step A3 — Format the 1GB ESP (FAT32)

1. Right-click the **1GB unallocated space** (created in Step 4)
2. Select **New**
3. Use the full size
4. Set type: **FAT32**
5. No label needed
6. Click **Create**

### ⚠️ Important Safety Rule

This FAT32 space is **new**, so formatting is safe.

DO NOT EVER FORMAT:

* Windows ESP (100MB FAT32)
* MSR
* C:
* Recovery

Formatting those breaks Windows.

---

# 6.4 — PART B: Mount the Partitions Correctly

Now we assign mount points.

### ✔ Select the ext4 partition

(this is `/dev/sda6`)

Set:

```
Mount point: /
Format: Yes
```

---

### ✔ Select the Linux swap partition

(this is `/dev/sda5`)

Set:

```
Type: swap
Format: N/A (not required)
```

Swap has no mount point.

---

### ✔ Select the FAT32 (1GB) partition

(this is `/dev/sda4`)

Set:

```
Mount point: /boot/efi
Format: Yes (FAT32)
```

### ⚠️ Huge Warning

If the installer auto-selects the **Windows** ESP (100MB) as `/boot/efi`,
**DO NOT KEEP IT.**

Manually select the newly created 1GB ESP.

This ensures systemd-boot does not overwrite Windows.

---

# 6.5 — Expected Final Partition Table

This is EXACTLY what your system should look like:

| Partition                | Mount Point | Format? |
| ------------------------ | ----------- | ------- |
| `/dev/sda6` (ext4)       | `/` root    | ✔ Yes   |
| `/dev/sda5` (swap)       | `swap`      | N/A     |
| `/dev/sda4` (1GB FAT32)  | `/boot/efi` | ✔ Yes   |
| `/dev/sda1` (EFI, 100MB) | untouched   | ❌ No    |
| `/dev/sda2` (MSR, 16MB)  | untouched   | ❌ No    |
| `/dev/sda3` (Windows C:) | untouched   | ❌ No    |
| Recovery Partition       | untouched   | ❌ No    |

This is the correct layout for Pop!_OS + Windows dual-boot.

---

# 6.6 — Begin Installation

Once everything looks correct:

Click:

### 👉 Apply Changes

### 👉 Proceed

Pop!_OS will:

* format `/boot/efi`
* format `/`
* create swap
* install systemd-boot in the 1GB ESP
* leave Windows completely untouched

Installation takes **5–15 minutes**.

When done, reboot.

---

## Step 7 — Post-Installation Fixes (Boot Menu + Windows Boot Manager)

This is the **final step**, executed **after Pop!_OS finishes installing** and reboots for the first time.

By default:

When you reboot after installation:

### ✔ Pop!_OS boots

### ✘ Windows does not appear

### ✘ systemd-boot menu does NOT show

### ✘ loader.conf gets overwritten

### ✘ Windows requires manual entry

### ✘ Windows files must be copied from the original ESP

This step fixes **ALL** of these systematically.

---

# 7.1 — Verify Pop!_OS detected Windows (os-prober)

Pop!_OS does **not ship os-prober**, so install it:

```bash
sudo apt install os-prober
sudo os-prober
```

A correct detection looks like:

```
/dev/sda1@/efi/Microsoft/Boot/bootmgfw.efi:Windows Boot Manager
```

If Windows does **not** appear, don’t worry — we will add it manually.

---

# 7.2 — Fix systemd-boot menu not showing

Pop!_OS often boots straight into systemd-boot **without showing a menu**.

Enable the menu:

```bash
sudo nano /boot/efi/loader/loader.conf
```

Add or modify:

```
default pop_os-current
timeout 5
console-mode max
editor no
auto-entries yes
auto-firmware yes
```

Save:

```
CTRL + O, ENTER
CTRL + X
```

Now reboot:

```bash
sudo reboot
```

Systemd-boot menu should appear.

If it does NOT appear → kernelstub is overwriting loader.conf.

We fix that next.

---

# 7.3 — Prevent Pop!_OS from overwriting systemd-boot

Pop!_OS uses **kernelstub** which rewrites systemd-boot configs automatically.

To stop this, we modify:

```bash
sudo nano /etc/kernelstub/configuration
```

Insert this line into the JSON:

```
"manage_systemd_boot": false,
```

Example corrected file:

```json
{
    "esp_path": "/boot/efi",
    "setup_loader": false,
    "manage_mode": false,
    "manage_systemd_boot": false,
    "force_update": false,
    "live_mode": false,
    "config_rev": 3,
    "user": {
        "kernel_options": [
            "quiet",
            "loglevel=0",
            "systemd.show_status=false",
            "splash"
        ]
    }
}
```

Save → exit.

Update systemd-boot:

```bash
sudo bootctl update
sudo reboot
```

Now the menu will **always** appear and **never** get overwritten.

---

# 7.4 — Add Windows Boot Manager entry manually

Systemd-boot stores OS entries in:

```
/boot/efi/loader/entries/
```

Create the Windows entry:

```bash
sudo nano /boot/efi/loader/entries/windows.conf
```

Paste:

```
title   Windows 11
efi     /EFI/Microsoft/Boot/bootmgfw.efi
options root=
```

Save → exit.

---

# 7.5 — Copy full Windows Boot folder into Pop!_OS ESP

Pop!_OS created a **new 1GB ESP** (sda4).
But Windows boot files live in **the old 100MB ESP** (sda1).

Systemd-boot cannot chainload Windows unless the entire Microsoft Boot folder exists inside the **new ESP**.

So we copy it:

### 1. Mount Pop!_OS ESP:

```bash
sudo mount /dev/sda4 /boot/efi
```

### 2. Mount Windows ESP:

```bash
sudo mkdir -p /mnt/win
sudo mount /dev/sda1 /mnt/win
```

### 3. Copy the Microsoft folder completely:

```bash
sudo mkdir -p /boot/efi/EFI/Microsoft/Boot
sudo cp -av /mnt/win/EFI/Microsoft/Boot/* /boot/efi/EFI/Microsoft/Boot/
```

⚠️ Important:
Copy **everything**, not just `bootmgfw.efi`.

If you copy only one file → Windows shows:

```
BCD missing (0xc000000f)
```

Copying the full folder prevents this.

---

# 7.6 — Final rebuild of systemd-boot

```bash
sudo bootctl update
sudo reboot
```

---

# 7.7 — Expected Final Dual-Boot Behavior

After reboot:

### ✔ Systemd-boot menu appears

### ✔ Pop!_OS entry works

### ✔ Windows 11 entry appears

### ✔ Windows boots normally

### ✔ loader.conf does NOT get overwritten

### ✔ Windows BCD does NOT break

### ✔ Both OSes boot cleanly

This completes the entire dual-boot procedure end-to-end.

---

Happy dual-booting!
