* Phoenix Bootsector v1.0 Source Code 3/10/91
* Coded (in about 230 bytes) by Agrajag for my Phoenix PD menu.

; Note- I have been bothered to slightly rewrite some of this code
; with macros and equates in it- aren't you lucky!

; Detects reset-resident routines- what a smartass I am!!!
; (No, only if the reset vector has been set.)

; It also puts #$1991 (The year, it was coded, dummy!) into $160, so you
; can check for that in your AUTO program to see it the boot has been
; changed, and put some code in to re-install it.

; See INSTALLP.S for details of how to install it.


; Tabs = 8, run in Devpac 2+

opt	o+,ow-		Optimisation on (ESSENTIAL this time!)

;TEST				<<<< Uncomment if you want to test it.
	IFD	TEST
	pea	main
	move	#38,-(sp)
	trap	#14
	addq.l	#6,sp
	clr	-(sp)
 	trap	#1
	ENDC



* Equates ------------------------------------------------------------

; ST Hardware values

st_cols		=	$ffff8240
resvalid	=	$426
magic_number	=	$31415926
vbl		=	$70
start_system	=	4

; Other values

white		=	$777
red		=	$700
colour_regs	equr	a5
colour		equr	d0

key_pressed	equr	d0
y_key		=	$15

year		=	$1991
year_loc	=	$160


* Macros ------------------------------------------------------------------

random	macro			; Generates random number
	move	#17,-(sp)
	trap	#14
	addq.l	#2,sp
	endm

print_string	macro	string	; Guess!
	pea	\1
	move	#9,-(sp)
	trap	#1
	addq.l	#6,sp
	endm

getkey	macro	mode		; call with no value to return
	move	#7,-(sp)	;  scandcode in d0
	trap	#1
	addq.l	#2,sp
	IFEQ	('\1'-'')
		swap	d0
	ENDC
	endm

soft_reset	macro		; generate a soft reset
	move.l	start_system.w,vbl.w
	endm





* MAIN CODE ---------------------------------------------------------


	opt	p+				HAS to be pc relative!

main

flash_colours
	lea	st_cols.w,colour_regs
	move.l	#500,d5
.loop	random
	andi.l	#white,colour
	move	colour,(colour_regs)
	dbf	d5,.loop
	move	#year,year_loc.w			Date-stamp it
	print_string	text(pc)

check_reset_vector
	cmpi.l	#magic_number,resvalid.w	Reset-resident proggy?
	beq	clear_reset?
	bra	bye

clear_reset?
	print_string	text2(pc)
	move	#red,(colour_regs)
	getkey
	cmp.b	#$15,key_pressed	Do you wish to clear the reset vector
	beq	clear_it
	bra	bye

clear_it
	clr.l	resvalid.w		Clear reset-vector
	soft_reset

bye	move	#white,(colour_regs)
	rts

text	dc.b	27,'E',27,'Y',32,(32+10),'AGRAJAGGY SNAZZY BOOTY!',0
	ds.b	24

text2	dc.b	27,'Y',(32+11),(32+2),'THE RESET VECTOR HAS BEEN CHANGED!!!',27,'Y',(32+15),(32+12),'Clear it? (y/n)',0
	even
bootend
