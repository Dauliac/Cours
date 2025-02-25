______________________________________________________________________

## header: 'Systems Course' footer: 'Julien Dauliac -- ynov.casualty925@passfwd.com'

<!-- headingDivider: 3 -->

<!-- paginate: true -->

<!-- colorPreset: sunset -->

# Summary

[Introduction](README.md)

______________________________________________________________________

# Courses

- [Introduction to SDLC](./sdlc/README.md)
- [Introduction to Operating Systems](./system/README.md)
- [Digital Licenses](./licences/README.md)
- [Technical Documentation](./documentations/README.md)

______________________________________________________________________

# References (Tools, Key Concepts, and Resources)

## Software Delivery Lifecycle (SDLC)

- [Project Management Tools](./sdlc/references/outils-gestion-projet.md)
- [DevOps Best Practices](./sdlc/references/devops-pratiques.md)

______________________________________________________________________

# Tutorials (Hands-on Practice and Workshops)

- [Packaging with nix](./sdlc/tps/packager-avec-nix/README.md)
- [Building a Perfect Container with nix](./sdlc/tps/container-parfait-avec-nix/README.md)

______________________________________________________________________

# How-To Guides

- [Install `nix`](./nix/INSTALL.md)

______________________________________________________________________

# Introduction

## Objectives

- Understand the system boot process, from BIOS initialization to kernel execution.
- Gain foundational knowledge of operating system architectures.
- Explore different forms of isolation, including virtual machines, containers, and lambdas, and understand their advantages and disadvantages.

## What is an OS?

### What does an OS offer?

- Do I need one?
  - Not necessarily, but if it's a personal computer (PC), it’s better.
- Why?
  - To abstract the hardware.

## A Simple System to Start

- BIOS

- Kernel booted by BIOS

- Creation of process 0 by the kernel

- IDLE = process that does nothing:

  ```c
  while(true) {}
  ```

______________________________________________________________________

![](./assets/system-2.svg)

# BIOS

- **Fun fact:** 🍎 The Mac startup sound comes from an illegal sample from The Beatles’ *Sgt. Pepper’s Lonely Hearts Club Band* album.

## Hardcore BIOS

![width:200px](./assets/Untitled.png)
![width:200px](./assets/Untitled-1.png)

## Corporate BIOS

![width:200px](./assets/Untitled-2.png)
![width:200px](./assets/Untitled-3.png)

## Casual BIOS

![width:200px](./assets/Untitled-4.png)
![width:200px](./assets/Untitled-5.png)

## What is a `BIOS`?

- The first instruction executed by the processor
- Detects and initializes hardware:
  - Processors, memory, I/O controllers, peripherals, etc.
- Hardware configuration
- Boots the operating system
- Old term

### A Language Misuse

- *Extensible Firmware Interface → INTEL*
- **Unified Extensible Firmware Interface →** [AMD](https://fr.wikipedia.org/wiki/Advanced_Micro_Devices), [American Megatrends](https://fr.wikipedia.org/wiki/American_Megatrends), [Apple](https://fr.wikipedia.org/wiki/Apple), [ARM](<https://fr.wikipedia.org/wiki/ARM_(entreprise)>), [Dell](https://fr.wikipedia.org/wiki/Dell), [HP](https://fr.wikipedia.org/wiki/Hewlett-Packard), [Intel](https://fr.wikipedia.org/wiki/Intel), [IBM](https://fr.wikipedia.org/wiki/International_Business_Machines_Corporation), Insyde Software, [Microsoft](https://fr.wikipedia.org/wiki/Microsoft), and [Phoenix Technologies](https://fr.wikipedia.org/wiki/Phoenix_Technologies)

### UEFI Architecture

[UEFI](https://fr.wikipedia.org/wiki/UEFI)

______________________________________________________________________

- SEC (*Security*) for executing authentication and integrity control processes (SecureBoot, password, USB token)

______________________________________________________________________

- PEI (*Pre EFI Initialization*) for motherboard and chipset initialization. Switches processor to protected mode.

______________________________________________________________________

- DXE (*Driver Execution Environment*) for driver registration. Manages EFI application requests like a bootloader.

______________________________________________________________________

- BDS (*Boot Dev Select*) for a boot manager like [GRUB](https://fr.wikipedia.org/wiki/GRand_Unified_Bootloader)

______________________________________________________________________

- TSL (*Transient System Load*) for the transition phase where the OS is loaded. EFI services terminate via *ExitBootServices()*, handing over control to the OS.

______________________________________________________________________

- RT (*RunTime*) once the OS takes over. Interaction with firmware is limited to EFI variables stored in NVRAM.

______________________________________________________________________

![](./assets/system-mermaid-bios.svg)

## Security

> The BIOS is not our domain, but we must protect the foundations.

- Set a UEFI password
- Enable Secure Boot:
  - Signs the bootloader, kernel, and verifies signatures at startup.

## An Open Source BIOS 🎊

**Open Firmware**

[Firmware Switching (Proprietary Firmware or System76 Open Firmware)](https://support.system76.com/articles/transition-firmware/)
