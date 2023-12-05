* Agrajag shows you how to put some code onto your bootsector!
loop	
    pea	    get_ready(pc)
	move	#9,-(sp)
	trap	#1
	addq.l	#6,sp
	bsr	    waitkey
	bsr	    read_boot
	bsr	    make_boot
	bsr	    write_boot

quit
	clr	-(sp)
	trap	#1

waitkey	
    move	#7,-(sp)
	trap	#1
	addq.l	#2,sp
	swap	d0
	rts

read_boot
	move.w	#1,-(sp)	; Read one sector...
	move.w	#0,-(sp)	; on side 0 of the disk...
	move.w	#0,-(sp)	; on track 0 of the disk...
	move.w	#1,-(sp)	; and sector 1... Hey! A bootsector!
	move.w	#0,-(sp)	; Using device: 0 for A etc..
	clr.l	-(sp)		; filler  (unused)
	pea	    buffer      ; Address of 512 byte buffer to load into
	move.w	#8,-(sp)    ; floprd call
	trap	#14
	add.l	#20,sp
	tst.w	d0          ; error?
	beq	    read_ok		
	bra	    disk_error
read_ok:
    rts

* Make up the bootsector - first the code is copied to the buffer, then
; we do a trap #14 on it to make up the checksum.

make_boot
	bsr	copy_code
	move.w	#1,-(sp)		; Executable
	move.w	#-1,-(sp)		; Disk type no change
	move.l	#s_no,-(sp)		; Same serial number
	pea	buffer			    ; 512 bootsector buffer
	move.w	#18,-(sp)		; proboot call
	trap	#14
	add.l	#14,sp
	rts

write_boot:
	move.w	#1,-(sp)	; Write 1 sec
	move.w	#0,-(sp)	; on side 0
	move.w	#0,-(sp)	; track 0
	move.w	#1,-(sp)	; sector 1- it's the bootsector again! (Oh shut up!)
	move.w	#0,-(sp)	; drive A
	clr.l	-(sp)       ; filler  (unused)
	pea	    buffer      ; Address of 512 byte buffer to save from
	move.w	#9,-(sp)    ; flopwr call
	trap	#14
	add.l	#20,sp
	tst.w	d0		    ; error?
	beq	wr_sc_ok
	bra	disk_error
wr_sc_ok:
    rts	

disk_error	
	pea	err1
	move	#9,-(sp)
	trap	#1
	addq.l	#6,sp
	bsr	waitkey
	addq.l	#2,sp
	bra	loop

copy_code:
	lea	    boot_code,a0
	lea	    buffer,a1
	move	#$601E,(a1)+		; BRA instruction to code
	lea	    loader,a2
	move	(a2)+,(a1)+		    ; Copy 6 byte 'loader'
	move.l	(a2)+,(a1)+
	adda.l	#$1e-6,a1           ; Move to where we're copying the code into the buffer
.loop:
	cmpa.l	#boot_code_end,a0   ; Copy until we reach the end of the code
	beq	.end
	move.b	(a0)+,(a1)+
	bra	.loop
.end:
	rts

err1	dc.b	'DISK ERROR!!! ',13,10,13,10

get_ready	dc.b	'Get ready suckers!!!!',0

	even
buffer:	ds.b	512			; The bootsector store

; --------------------------------------------------------------------

* Loader - 6 chars only!

loader:	dc.b	'by AGR'

* Serial number - a value of #-1 leaves numbers unchanged.

s_no	equ	-1

	opt 	p+,o+

boot_code:

; ------------------- PUT YOUR FAVOURITE BOOTCODE HERE! ----------------

	pea	    whit(pc)
	move	#9,-(sp)
	trap	#1
	addq.l	#6,sp
	move	#$700,$ffff8240
	rts

whit:
	dc.b	'I don''t do that much really!',0

; -------------------------- END OF BOOTCODE ---------------------------	
boot_code_end
