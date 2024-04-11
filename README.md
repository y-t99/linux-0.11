# linux-0.11

Linux version 0.11 source code written by Linus.

Instruction set architecture: x86.

## Link

[dibingfa/flash-linux0.11-talk](https://github.com/dibingfa/flash-linux0.11-talk)

[theanarkh/read-linux-0.11](https://github.com/theanarkh/read-linux-0.11)


## Concept

### Addressing Mode

An addressing mode specifies how to calculate the effective memory address of an operand by using information held in registers and/or constants contained within a machine instruction or elsewhere.

Real mode, gets its name from the fact that addresses in real mode always correspond to real locations in memory. Real mode is characterized by a 20-bit segmented memory address space (giving 1 MB of addressable memory) and unlimited direct software access to all addressable memory, I/O addresses and peripheral hardware.

> In real mode, CS:IP: CS <<< 4 ^ IP = Memory Address. 

Protected mode, allows system software to use features such as segmentation, virtual memory, paging and safe multi-tasking designed to increase an operating system's control over application software.

Protected mode may only be entered after the system software sets up one descriptor table and enables the Protection Enable (PE) bit in the control register 0 (CR0).

To enter protected mode, the Global Descriptor Table (GDT) must first be created with a minimum of three entries: a null descriptor, a code segment descriptor and data segment descriptor.

The Global Descriptor Table (GDT) is a data structure used by Intel x86-family processors starting with the 80286 in order to define the characteristics of the various memory areas used during program execution, including the base address, the size, and access privileges like executability and writability. These memory areas are called segments in Intel terminology.

### Operating modes

### Interrupt & Exception

The processor providers two mechanisms for interrupting program execution interrupts and exceptions:

An interrupt is an asynchronous event that is typically triggered by an I/O device.

An exception is a synchronous event that is generated when the processor detects one or more predefined conditions while executing an instruction.

> The INT n instructions also can interrupt program execution.

## Machine

### Hardware

#### CPU

##### Register

[Low Level Programming Basic Concepts](https://www.baskent.edu.tr/~tkaracay/etudio/ders/prg/pascal/PasHTM2/pas/lowlevel.html)

![Registers](./picture/registers.png)

## Boot

主板<sub>Main Board</sub>BIOS读取硬盘<sub>Hard Dist</sub>第一扇区<sub>Sector</sub>512字节进入内存<sub>Memory</sub>。

程序中断从硬盘中读取setup模块和system模块到内存，而后跳到setup模块执行。