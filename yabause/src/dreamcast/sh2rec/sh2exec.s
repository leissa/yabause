!   Copyright 2010 Lawrence Sebald
!
!   This file is part of Yabause.
!
!   Yabause is free software; you can redistribute it and/or modify
!   it under the terms of the GNU General Public License as published by
!   the Free Software Foundation; either version 2 of the License, or
!   (at your option) any later version.
!
!   Yabause is distributed in the hope that it will be useful,
!   but WITHOUT ANY WARRANTY; without even the implied warranty of
!   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
!   GNU General Public License for more details.
!
!   You should have received a copy of the GNU General Public License
!   along with Yabause; if not, write to the Free Software
!   Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA

!   Code for calling upon the code generated by sh2rec (SuperH).

    .file       "sh2exec.s"
    .little
    .text
    .balign     8

!   void sh2rec_exec(SH2_struct *cxt, u32 cycles)
!       Execute the specified number of cycles on the given SH2 context
    .globl  _sh2rec_exec
_sh2rec_exec:
    stc.l   gbr, @-r15                  ! Save call-preserved stuff
    sts.l   mach, @-r15                 ! Ditto
    sts.l   macl, @-r15                 ! Ditto
    mov.l   r8, @-r15                   ! Ditto
    mov     r4, r8                      ! Put the SH2 struct in r8
    mov.l   r9, @-r15                   ! More call-preserved stuff
    add     #76, r4                     ! Point at MACH in the SH2 struct
    mov.l   r10, @-r15                  ! More call-preserved stuff
    mov.l   r11, @-r15                  ! Last one for now...
    lds.l   @r4+, mach                  ! Load the SH2 MACH into our MACH
    lds.l   @r4+, macl                  ! Ditto for MACL
    mov.l   checkInterrupts, r0         ! We need to check for interrupts...
    mov.l   sh2memfuncsptr, r9          ! Memory access function pointer table
    sts.l   pr, @-r15                   ! Helps to know where to go back to
    mov     r5, r11                     ! This is important enough to keep here
    mov.l   r5, @-r15                   ! Save this on the stack too
    mov     r8, r4                      ! We need the original SH2_struct back
    jsr     @r0                         ! Call sh2rec_check_interrupts
    ldc     r8, gbr                     ! Put the SH2 struct in gbr (delay slot)
    mov.l   findBlock, r1               ! Grab the sh2rec_find_block function
    mov.l   @(88, gbr), r0              ! Grab the PC we are at
.exec_loop:                             ! This is where the fun is!
    jsr     @r1                         ! Call sh2rec_find_block
    mov     r0, r4                      ! Move the PC to argument 1 (delay slot)
    mov.l   @r0, r2                     ! Grab where the code is
    mov.l   @(8, r0), r1                ! Figure out the number of cycles used
    jsr     @r2                         ! Call the block
    sub     r1, r11                     ! Chop off the cycles (delay slot)
    cmp/pl  r11                         ! Are we done?
    mov.l   findBlock, r1               ! Grab the sh2rec_find_block function
    bt      .exec_loop                  ! Continue on if needed
                                        ! When we are done, we will be here.
    mov.l   r0, @(88, gbr)              ! Save the next PC value
    mov.l   @r15+, r5                   ! Pop the requested number of cycles
    mov     r8, r4                      ! Keep this for sanity for now
    add     #84, r8                     ! Point just after MACL in SH2 struct
    sts.l   macl, @-r8                  ! Store the SH2 MACL back in the struct
    sts.l   mach, @-r8                  ! Ditto for MACH
    lds.l   @r15+, pr                   ! Restore stuff from the stack
    sub     r11, r5                     ! Our counter is negitive, so this works
    mov.l   cycleOffset, r2             ! Where is the cycles member at?
    mov.l   @r15+, r11                  ! More restoring...
    add     r2, r4                      ! Point r4 at the cycles member
    mov.l   @r15+, r10
    mov.l   @r15+, r9
    mov.l   @r15+, r8
    lds.l   @r15+, macl
    lds.l   @r15+, mach
    mov.l   r5, @r4                     ! Save the cycles we spent
    rts                                 ! Return to the caller
    ldc.l   @r15+, gbr                  ! Last thing to restore (delay slot)

    .balign     4
sh2memfuncsptr:
    .long       sh2memfuncs
checkInterrupts:
    .long       _sh2rec_check_interrupts
findBlock:
    .long       _sh2rec_find_block
cycleOffset:
    .long       5516

    .data
    .balign     4
sh2memfuncs:
    .long       _MappedMemoryReadByte
    .long       _MappedMemoryReadWord
    .long       _MappedMemoryReadLong
    .long       _MappedMemoryWriteByte
    .long       _MappedMemoryWriteWord
    .long       _MappedMemoryWriteLong
