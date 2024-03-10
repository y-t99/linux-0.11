!
! SYS_SIZE is the number of clicks (16 bytes) to be loaded.
! 0x3000 is 0x30000 bytes = 196kB, more than enough for current
! versions of linux
!
! 系统要加载的数据量：196kB。
SYSSIZE = 0x3000
!
!	bootsect.s		(C) 1991 Linus Torvalds
!
! bootsect.s is loaded at 0x7c00 by the bios-startup routines, and moves
! iself out of the way to address 0x90000, and jumps there.
! bootsect.s通过BIOS启动程序中加载到0x7c00位置，并将自身移动到0x90000，且程序执行跳转到那里。
!
! It then loads 'setup' directly after itself (0x90200), and the system
! at 0x10000, using BIOS interrupts.
! 然后使用BIOS中断加载'setup'（0x90200）和系统（0x10000）。
!
! NOTE! currently system is at most 8*65536 bytes long. This should be no
! problem, even in the future. I want to keep it simple. This 512 kB
! kernel size should be enough, especially as this doesn't contain the
! buffer cache as in minix
! 目前系统最长为512kB。
!
! The loader has been made as simple as possible, and continuos
! read errors will result in a unbreakable loop. Reboot by hand. It
! loads pretty fast by getting whole sectors at a time whenever possible.
! 加载程序已经尽可能简化，并且持续的读取错误将导致一个无法中断的循环。
! 请手动重新启动。它通过尽可能一次获取整个扇区来实现快速加载。

! 声明全局可见性的符号：begtext、begdata、begbss、endtext、enddata和endbss
.globl begtext, begdata, begbss, endtext, enddata, endbss
! 用于指定下面的指令是代码段（text segment）的一部分。代码段通常用于存放可执行指令。
.text
begtext:
! 用于标记数据段的开始位置。
.data
begdata:
! 用于指定下面的指令是BSS段（Block Started by Symbol）的一部分。BSS段通常用于存放未初始化的全局变量。
.bss
begbss:
.text

SETUPLEN = 4					! nr of setup-sectors setup扇区的数量为4个。
BOOTSEG  = 0x07c0			! original address of boot-sector 引导扇区的原始地址为0x07c0。
INITSEG  = 0x9000			! we move boot here - out of the way
SETUPSEG = 0x9020			! setup starts here
SYSSEG   = 0x1000			! system loaded at 0x10000 (65536). 表示系统加载到的地址为0x10000（65536）。
ENDSEG   = SYSSEG + SYSSIZE		! where to stop loading 表示加载过程应停止的地址。

! ROOT_DEV:	0x000 - same type of floppy as boot.
!		0x301 - first partition on first drive etc
! ROOT_DEV用于表示根文件系统所在的设备:
!   0x000: 表示根文件系统与引导时使用的软盘类型相同。
!   0x301: 表示根文件系统位于第一块驱动器的第一个分区。
!   0x306：表示根文件系统位于第一块驱动器的第三个分区。
ROOT_DEV = 0x306

entry start
start:
	! step 1: 固件程序 BIOS，将硬盘中启动区的 512 字节，复制到内存中的0x7c00位置。
	mov	ax,#BOOTSEG
	mov	ds,ax
	mov	ax,#INITSEG
	mov	es,ax
	mov	cx,#256
	sub	si,si
	sub	di,di
	! step 2: 将启动区512字节从0x7c00位置复制到0x9000位置。
	rep
	movw
	jmpi    go,INITSEG
go:	mov	ax,cs
	! step 3: 初步做了一次内存规划。从CPU的角度看，访问三个地方的内存，为数据段和代码段：0x9000，栈顶：0x9FF00。
	mov	ds,ax
	mov	es,ax
! put stack at 0x9ff00.
	mov	ss,ax
	mov	sp,#0xFF00		! arbitrary value >>512

! load the setup-sectors directly after the bootblock.
! Note that 'es' is already set up.

! step 4: 硬盘的第2个扇区开始，把数据加载到内存0x90200处，共加载4个扇区
load_setup:
	mov	dx,#0x0000		! drive 0, head 0
	mov	cx,#0x0002		! sector 2, track 0
	mov	bx,#0x0200		! address = 512, in INITSEG
	mov	ax,#0x0200+SETUPLEN	! service 2, nr of sectors
	! bios 13号中断。对应的功能有很多，由ax传入使用哪个功能。这里使用的是功能2，读取扇区数据。
	! AH＝功能号；AL＝扇区数；CH＝柱面；CL＝扇区；DH＝磁头；
	! DL＝驱动器，00H~7FH：软盘；80H~0FFH：硬盘；
	! ES:BX＝缓冲区的地址；
	! 返回：CF＝0说明操作成功，否则，AH＝错误代码
    !
	! 读取软盘的setup模块代码，jc在CF=1时跳转，jnc则在CF=0时跳转，
	! 读取软盘出错则CF=1，ah是出错码，所以下面是CF等于1，说明加载成功，则跳转，否则则重试。
	int	0x13			! read it
	jnc	ok_load_setup		! ok - continue
	mov	dx,#0x0000
	mov	ax,#0x0000		! reset the diskette
	int	0x13
	j	load_setup

ok_load_setup:

! Get disk drive parameters, specifically nr of sectors/track

	mov	dl,#0x00
	mov	ax,#0x0800		! AH=8 is get drive parameters
	int	0x13
	mov	ch,#0x00
	seg cs
	mov	sectors,cx
	mov	ax,#INITSEG
	mov	es,ax

! Print some inane message

	mov	ah,#0x03		! read cursor pos
	xor	bh,bh
	int	0x10
	
	mov	cx,#24
	mov	bx,#0x0007		! page 0, attribute 7 (normal)
	mov	bp,#msg1
	mov	ax,#0x1301		! write string, move cursor
	int	0x10

! ok, we've written the message, now
! we want to load the system (at 0x10000)

	! step 5: 加载system模块代码
	! 把从硬盘第 6 个扇区开始往后的 240 个扇区，加载到内存 0x10000 处
	mov	ax,#SYSSEG
	mov	es,ax		! segment of 0x010000
	call	read_it
	call	kill_motor

! After that we check which root-device to use. If the device is
! defined (!= 0), nothing is done and the given device is used.
! Otherwise, either /dev/PS0 (2,28) or /dev/at0 (2,8), depending
! on the number of sectors that the BIOS reports currently.

	seg cs
	mov	ax,root_dev
	cmp	ax,#0
	jne	root_defined
	seg cs
	mov	bx,sectors
	mov	ax,#0x0208		! /dev/ps0 - 1.2Mb
	cmp	bx,#15
	je	root_defined
	mov	ax,#0x021c		! /dev/PS0 - 1.44Mb
	cmp	bx,#18
	je	root_defined
undef_root:
	jmp undef_root
root_defined:
	seg cs
	mov	root_dev,ax

! after that (everyting loaded), we jump to
! the setup-routine loaded directly after
! the bootblock:
  ! step 6: 🍀 加载完setup和system模块，跳到setup模块执行
	jmpi	0,SETUPSEG

! This routine loads the system at address 0x10000, making sure
! no 64kB boundaries are crossed. We try to load it as fast as
! possible, loading whole tracks whenever we can.
!
! in:	es - starting address segment (normally 0x1000)
!
sread:	.word 1+SETUPLEN	! sectors read of current track
head:	.word 0			! current head
track:	.word 0			! current track

read_it:
	mov ax,es
	test ax,#0x0fff
die:	jne die			! es must be at 64kB boundary
	xor bx,bx		! bx is starting address within segment
rp_read:
	mov ax,es
	cmp ax,#ENDSEG		! have we loaded all yet?
	jb ok1_read
	ret
ok1_read:
	seg cs
	mov ax,sectors
	sub ax,sread
	mov cx,ax
	shl cx,#9
	add cx,bx
	jnc ok2_read
	je ok2_read
	xor ax,ax
	sub ax,bx
	shr ax,#9
ok2_read:
	call read_track
	mov cx,ax
	add ax,sread
	seg cs
	cmp ax,sectors
	jne ok3_read
	mov ax,#1
	sub ax,head
	jne ok4_read
	inc track
ok4_read:
	mov head,ax
	xor ax,ax
ok3_read:
	mov sread,ax
	shl cx,#9
	add bx,cx
	jnc rp_read
	mov ax,es
	add ax,#0x1000
	mov es,ax
	xor bx,bx
	jmp rp_read

read_track:
	push ax
	push bx
	push cx
	push dx
	mov dx,track
	mov cx,sread
	inc cx
	mov ch,dl
	mov dx,head
	mov dh,dl
	mov dl,#0
	and dx,#0x0100
	mov ah,#2
	int 0x13
	jc bad_rt
	pop dx
	pop cx
	pop bx
	pop ax
	ret
bad_rt:	mov ax,#0
	mov dx,#0
	int 0x13
	pop dx
	pop cx
	pop bx
	pop ax
	jmp read_track

/*
 * This procedure turns off the floppy drive motor, so
 * that we enter the kernel in a known state, and
 * don't have to worry about it later.
 */
kill_motor:
	push dx
	mov dx,#0x3f2
	mov al,#0
	outb
	pop dx
	ret

sectors:
	.word 0

msg1:
	.byte 13,10
	.ascii "Loading system ..."
	.byte 13,10,13,10

.org 508
root_dev:
	.word ROOT_DEV
boot_flag:
	.word 0xAA55

.text
endtext:
.data
enddata:
.bss
endbss:
