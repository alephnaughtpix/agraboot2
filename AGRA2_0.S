* AGRABOOT 2

main_loop:
    pea	    txt_intro
    move	#9,-(a7)	; Cconws
    trap	#1		    ; Gemdos
    addq.l	#6,a7
    bsr	    wait_key
    cmp.b	#16,d0
    beq	    exit
    pea	    txt_choose_boot
    move	#9,-(a7)	; Cconws
    trap	#1		; Gemdos
    addq.l	#6,a7
    bsr	    wait_key
    move.l	d0,d7

    bsr	    read_bootsector
    bsr	    make_bootsector
    bsr	    write_bootsector

    pea	    txt_installed
    move	#9,-(a7)	; Cconws
    trap	#1		; Gemdos
    addq.l	#6,a7
    bsr	    wait_key
    bra     main_loop

exit:
	clr	    -(a7)
	trap	#1		; Gemdos

wait_key:
	move	#7,-(a7)	; Crawcin
    trap	#1		    ; Gemdos
    addq.l	#2,a7
    swap	d0
    rts

read_bootsector:
    move	#1,-(a7)
    move	#0,-(a7)
    move	#0,-(a7)
    move	#1,-(a7)
    move	#0,-(a7)
    clr.l	-(a7)
    pea	    bootsector_buffer
    move	#8,-(a7)	; Floprd
    trap	#14		; Xbios
    adda.l	#20,a7
    tst	    d0
    beq	    .no_error
    bra	    disk_error
.no_error:
    rts

make_bootsector:
    bsr	    get_bootcode
    cmp.b	#49,d7
    beq	    .clean_bootsector
.agra_bootsector:
    move	#1,-(a7)
    move	#-1,-(a7)
    move.l	#-1,-(a7)
    pea	    bootsector_buffer
    move	#18,-(a7)	; Protobt
    trap	#14		    ; Xbios
    adda.l	#14,a7
    rts
.clean_bootsector:
    clr	    -(a7)
    move	#-1,-(a7)
    move.l	#$01000000,-(a7)
    pea	    bootsector_buffer
    move	#18,-(a7)	; Protobt
    trap	#14		    ; Xbios
    adda.l	#14,a7
    rts

write_bootsector:
    move	#1,-(a7)
    move	#0,-(a7)
    move	#0,-(a7)
    move	#1,-(a7)
    move	#0,-(a7)
    clr.l	-(a7)
    pea	    bootsector_buffer
    move	#9,-(a7)	; Flopwr
    trap	#14		; Xbios
    adda.l	#20,a7
    tst	    d0
    beq	    .no_error
    bra	    disk_error
.no_error:
    rts

disk_error:
    pea     txt_disk_error
    move	#9,-(a7)	; Cconws
    trap	#1		; Gemdos
    addq.l	#6,a7
    bsr	    wait_key
    addq.l	#2,a7
    bra     main_loop

get_bootcode:
	lea	    agraboot_code,a0
	lea	    bootsector_buffer,a1
    cmp.b	#49,d7
	beq	    .clean_bootsector
.agra_bootsector
	move.w	#$601e,(a1)+
	move.w	#'by',(a1)+
    move.l	#' AGR',(a1)+
    adda.l	#24,a1
.copy_loop:
	cmpa.l	#agraboot_code_end,a0
    beq.s   .end
    move.b	(a0)+,(a1)+
    bra	    .copy_loop
.end:
	rts
.clean_bootsector:
	clr.w	    (a1)+
    move.l	#'IBM ',(a1)+
    move.w	#' V',(a1)+
    adda.l	#24,a1
.clear_loop:
    cmpa.l	#bootsector_buffer_end,a1
	beq	    .end
    clr.b	(a1)+
    bra	    .clear_loop

; 394:	dc	17481
; 396:	subq	#1,a3
; 398:	movea.l	d5,a0
; 400:	addq	#1,(a2)
; 402:	dc	20306
; 404:	move.l	-(a1),-(a0)
; 406:	move.l	-(a0),-(a0)
; 408:	movep	3338(a2),d6

txt_disk_error:
    dc.b    13,10,'DISK ERROR!!!',0   
txt_intro:
    dc.b    27,'E'
    dc.b    'AGRABOOT v2.0 Bootsector Installer.',13,10,13,10
    dc.b    'Press Q to quit, any other key to install.',13,10,13,10,13,10,0
txt_installed:
    dc.b    13,10,'Bootsector installed. ',13,10
    dc.b    'Press any key to restart.',13,10,0
txt_choose_boot:
    dc.b    'Press <A> for AGRABOOT or <N> for clean bootsector.',13,10,0
    even
; 558:	dc	25971
; 560:	dc	29472
; 562:	movea	d1,a6
; 564:	move	-(a0),d7
; 566:	dc	26223
; 568:	moveq	#32,d1
; 570:	dc	16711
; 572:	addq	#1,d1
; 574:	dc	16975
; 576:	dc	20308
; 578:	movea.l	29216(a7),a0
; 582:	movea	a6,a6
; 584:	move	-(a0),d7
; 586:	dc	26223
; 588:	moveq	#32,d1
; 590:	bls.s	700
; 592:	dc	25953
; 594:	bgt.s	628
; 596:	dc	25199
; 598:	ble.s	.reset_proof_found
; 600:	dc	29541
; 602:	bls.s	720
; 604:	ble.s	720
; 606:	move.l	a5,d7
; 608:	dc	2560

c16regs		        equ	$ffff8240
mem_phystop         equ	$42e
reset_vector_valid  equ	$426
system_boot         equ	$4

reset_vector_magic      equ	$31415926
reset_resident_magic    equ	$12123456
bootsector_magic        equ	$1234

    opt     p+

agraboot_code:
    clr.w   c16regs+2.w
    move.w	#$777,c16regs.w
    bsr.s	scan_for_reset_code
    pea	    txt_agraboot_intro_message(pc)
    move	#9,-(a7)	; Cconws
    trap	#1		; Gemdos
    addq.l	#6,a7
    lea	    580(pc),a0
    movea.l	$4c6.w,a1
    lea	    600(a1),a1
    movea.l	a1,a2
    move	#127,d0
.copy_code:	
    move.l	(a0)+,(a1)+
    dbf 	d0,.copy_code
    jmp	    176(a2)

scan_for_reset_code:	
    lea	    reset_vector_valid.w,a5
    movea.l mem_phystop.w,a0
    movea.l system_boot.w,a6
    cmpa.l	#$3ffffc,a0
    ble.s	.memory_scan
    lea	    -4(a0),a0
.memory_scan:
    cmpi.l	#reset_resident_magic,(a0)
    beq.s	.reset_proof_found
    lea	    -512(a0),a0
    cmpa.l	#0,a0
    bgt.s	.memory_scan
    cmpi.l	#reset_vector_magic,(a5)
    beq.s	.reset_proof_found
    bra.s	.exit
.reset_proof_found:
    move	#$700,c16regs.w
    pea	    txt_agraboot_reset_found(pc)
    move	#9,-(a7)	; Cconws
    trap	#1		; Gemdos
    move	#7,-(a7)	; Crawcin
    trap	#1		; Gemdos
    addq.l	#8,a7
    swap	d0
    cmp.b	#21,d0
    bne.s	.exit
    clr.l	(a5)
    clr.l	(a0)
    jmp	    (a6)
.exit:	
    rts

install_bpb:
    lea	    old_bpb+2(pc),a0
    move.l	$472.w,(a0)
    lea	    new_bpb(pc),a0
    move.l	a0,$472.w
    moveq	#7,d2
.wait1:	moveq	#-4,d3
.wait2:	eori	#$707,c16regs.w
    dbf	    d3,.wait2
    dbf	    d2,.wait1
    rts

new_bpb:	
    move	4(a7),d0
    move	d0,-(a7)
old_bpb:
    jsr	0
    addq.l	#2,a7
    movem.l	d0-d4/a0-a2,-(a7)
    movea.l	$4c6.w,a2                           ; Bootsector in a2
    movea.l	a2,a0
    move	#256-1,d1
    moveq	#0,d0
.checksum_loop:	
    add	    (a0)+,d0
    dbf	    d1,.checksum_loop
    cmp	    #bootsector_magic,d0
    bne	    .bootsector_not_executable
    movea.l	a2,a0
    adda	#428,a0
    cmpi.l	#'AGRA',(a0)+
    bne.s	.check_bootsector
    cmpi.l	#'BOOT',(a0)+
    beq	    .bootsector_not_executable
.check_bootsector:
    movea.l	a2,a0                       ; a0 = bootsector in memory
    lea	    512(a2),a2                  ; a2 = end of bootsector in memory
    moveq	#0,d1
    move	d1,d0                       ; d0 will contain the number of warnings
.scan_loop1:
    add	    d0,d1
    cmpa.l	a0,a2
    beq.s	end_scan
    clr	    d0
    cmpi	#$3f3c,(a0)+                ; Test for "move.w" instruction
    bne.s	.scan_loop1
    lea	    warning_values(pc),a1
.scan_loop2:
    move	(a0),d3
    move	(a1)+,d4
    cmp	    d3,d4
    bne.s	.next_value
    addq	#1,d0
    bra.s	.scan_loop2
.next_value:
    move	(a0)+,d3
    move	(a1)+,d4
    cmp	    d3,d4
    bne.s	.test_for_next_scan
    addq	#1,d0
    bra.s	.scan_loop2
.test_for_next_scan:
	tst.b	d0
    beq.s	.scan_loop1
    subq	#1,d0
    bra.s	.scan_loop1

warning_values:	
    ori.b	#9,d4
    trap	#13		; Bios
    trap	#14		; Xbios

end_scan:	
    lea	    c16regs.w,a1
    move	(a1),d2
    tst.b	d1
    beq.s	.executable_warn
.suspicious_warn:
    move	#$700,(a1)
	bra.s	.ring_bell
.executable_warn:
    eori	#$777,(a1)
.ring_bell:
    lea	    -30720.w,a0
    move.l	#$05000100,(a0)
    move.l	#$0A001000,(a0)
    move.l	#$0C00A000,(a0)
    move.l	#$0700FB00,(a0)
    move.l	#$0D000000,(a0)
    moveq	#-3,d0
.pause:	
    dbf	    d0,.pause
    move	d2,(a1)
.bootsector_not_executable:
    movem.l	(a7)+,d0-d4/a0-a2
    rts

txt_agraboot_intro_message:
    dc.b    27,'b1'         ; Set text pen to colour 1
    dc.b    27,'E'          ; Clear screen
    dc.b    27,'Y',32,46
    dc.b    'AGRABOOT 2'
    dc.b    27,'Y',39,40
    dc.b    'Flash = executable boot'
    dc.b    27,'Y',41,43
    dc.b    'RED = suspicious!'
    dc.b    0
txt_agraboot_reset_found
    dc.b    27,'E'
    dc.b    'Reset prog! Clear?'
    dc.b    0
    even

agraboot_code_end:

bootsector_buffer:
        ds.b    512
bootsector_buffer_end:
	end	
