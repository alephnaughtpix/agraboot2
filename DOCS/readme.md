# Atari (16 bit) Bootsector Coding

* BOOTSECTORS, THE 512 BYTE MARVEL OF THE ST WORLD!!!!!!
* THE NUMBER ONE SECTOR ON YOUR FLOPPIES!!!!
* LET THE POWER OF THE BOOTSECTOR WORK FOR *YOU*!!!!
* ERRR.... DOING THINGS!!!
* A THOROUGH IN-DEPTH INVESTIGATION BY **AGRAJAG**.
* INCLUDING *EXCLUSIVE* SECRETS ON HOW TO DO AN ANTIVIRUS BOOTSECTOR!!!

*This text in this document is largly from an article which originally appeared in **[Ledgers disk magazine issue 11](https://demozoo.org/productions/78512/)** on the Atari ST in June 1992, and subsequently updated and [posted on my very first website](https://web.archive.org/web/19970121061825/http://grelb.src.gla.ac.uk:8000/~mjames/computers/source/boot_sec/bootsector.html) a couple of years later, so forgive the wackiness inherent in this text.*

## Introduction

Are you one of those people who blunder through life with clean bootsectors on your disks? Well, then I'd say you're bloody lucky not get a virus on them! What's your secret?

No, you're more likely to put some nice looking antivirus bootsector on it, like the 'English' antivirus or the 4 meg incompatible Medway Boys Virus protector 3. But have you ever stopped to think 'Wow! I wonder how that's all done in such a small 512 byte space?' Stop looking at the screen like that, of course you have. Well, that's what this article is all about.

## Anatomy of a bootsector

First the really boring theory bit. Did you know that not all of the bootsector can be used for your coding experiments? I'm afraid it's true. Some of the meagre 512 bytes is used by the system in order to determine the format of the disk. Yes, I know it's annoying. Why the system can't work out how to read the disk by itself without needing to read a couple of bytes which could be used for some hyper-optimised code I don't know. Still, that's the way it is. So let's look at the bits you *have* to put in the bootsector.


| `BYTE`      | FUNCTION                                                                                                                                                                            |
| ------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `00 - 01`   | `bra.s` command. Usually `bra.s + $38`. Jumps to bootcode. If the bootcode is not executable, then it's just a word value of 0.                                                     |
| `02 - 07`   | 'Loader' - has absolutely no function other than that of ego trip, since you have 6 chars space to put your initials in!! In a 'Clean' disk, it's`IBM  V`                           |
| `08 - 10`   | 24 bit disk serial number!!! Not really very useful!!!                                                                                                                              |
| `11 - 12`   | Bytes per sector. Like wow, you could have*1024 byte sector disks!!!!* (Except that GEM won't like it very much.)                                                                   |
| `13`        | Sectors per cluster. Clusters are blocks used by the DOS to store files. The default is 2, which is 1K (2 * 512 bytes.)                                                             |
| `14 - 15`   | No. of reserved sectors. In other words, just the bootsector ie 1 on any disk.                                                                                                      |
| `16`        | No. of file allocation tables. (FATs) That's where DOS looks when it wants to work out where a file starts and ends on a disk.                                                      |
| `17 - 18`   | Max no of directory entries. Guess what that's for!                                                                                                                                 |
| `19 - 20`   | The TOTAL number of sectors on a disk. For example an 81 track 10 sector double sided disk has ermmmm, hang on... 81 times 10 is 810, times 2 is,.... yes, 1620 sectors, I think. ! |
| `21`        | This apparently is the 'Media Descriptor Byte', which is not used by the ST, but is used by MS-DOS. Wow!                                                                            |
| `22 - 23`   | The number of sectors per file allocation table. I don't need to tell you how exciting that is.                                                                                     |
| `24 - 25`   | Number of sectors per track. Usually 9 or 10 or even (if you are really naughty!) 11!                                                                                               |
| `26 - 27`   | Number of sides. Now I don't need to tell you which number I think SHOULD be default! Clue: single sided drives went out with half meg STFMs.                                       |
| `28 - 29`   | Number of hidden sectors! I don't think this is ever used!                                                                                                                          |
| `30 - `     | After all that,**then** your boot code can start!                                                                                                                                   |
| `510 - 511` | Checksum number. Add this to a checksum of the rest of the bootsector, and if it comes to**$1234** (ie 1234 in hexidecimal notation), then the bootsector is executable.            |

Some of you might have noticed that there's no mention of the number of actual tracks in a disk. This, believe it or not, is one of the few things the computer can work out by itself, by dividing the total number of sectors by the number of sectors per track.

It's also worth mentioning that the code in the bootsector is executed in supervisor mode. It's **has** to be pc-relative and **has** to end with an `rts`.

Another thing you might have noticed is that your code can start at 30. Now 30 is $1e in hex, but most executable boot code starts at $38 or byte 56! So there's a lot of space there that could be used! In fact, **Fastcopy** stamps it's name in the area $1e-$38 when it formats a disk. Which is how I know **T.V.I**. used Fastcopy to format the disks for their *'The Year After'* megademo!

## Uses for bootsector code

So what use can all that nonsense possibly be?

Firstly, when you're formatting disks, you've got to get the structure of the bootsector right, or the disk will behave strangely!

Secondly, you might want to put your own custom 'antivirus' bootsector on all your disks, and annoy your friends and contacts no end! If you want to be really annoying, why not write a virus as well! That'll really piss them off! *[**NOTE**: That was meant to be a joke. Please do **not** do this!]*

Thirdly, you might want to write a demo... Ahhhh, well, I'm not telling you too much about that yet!

All you really need to know is **the magic 4 steps to installing a bootsector**.

1. Read the bootsector into memory.
2. Do what ever you want to do with it.
3. Make sure you've got the right checksum on it!
4. Write it back out to disk.

In this (nice long) article, I'm concentrating on putting some good old assembler mnemonics into the bootsector, from a simple virus-free message to a more complex antivirus warning system.

## How to put code on a bootsector

You might already have got source from a previous Ledgers magazine which installed 68000 code on a bootsector. If you haven't, then there should be a pretty simple example in [`BOOT.S`](https://github.com/alephnaughtpix/agraboot2/blob/main/DOCS/examples/BOOT.S) which does the above four steps. Let's look at them in a bit more detail.

1. How could we possibly read the bootsector into memory?? What's that I hear? Trap #13 *rwabs* or Trap #14 *floprd* call? Yes, that sounds a good idea. Quick delve into *ST Internals*. Yes, that's a good idea. In `BOOT.S`, we're using the Trap #14 *floprd* call:

```
read_boot:
	move.w	#1,-(sp)	  ; Read one sector...
	move.w	#0,-(sp)	  ; on side 0 of the disk...
	move.w	#0,-(sp)	  ; on track 0 of the disk...
	move.w	#1,-(sp)	  ; and sector 1... Hey! A bootsector!
	move.w	#0,-(sp)	  ; Using device: 0 for A etc..
	clr.l	-(sp)		     ; filler  (unused)
	pea	    buffer    ; Address of 512 byte buffer to load into
	move.w	#8,-(sp)   ; floprd call
	trap	#14
	add.l	#20,sp
	tst.w	d0            ; Error?
	beq	read_ok
	bra	disk_error
read_ok:
    rts

    [...]
  
buffer:	ds.b	512			; The bootsector store
```

2. So we've got our original bootsector in a 512 byte buffer. First we need to put our `bra.s + $1e` right at the start of the buffer. To do this, just put the word value `$601e` at the start of the buffer. Then we need to copy our bootcode into the buffer starting `$1e` bytes after that. You might also want to change the 'loader' and serial number as well! Here's how I did it in `BOOT.S`:

```
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

   [...]

loader:	dc.b	'by AGR'   ; Loader - 6 chars only!

   [...]

   	opt 	p+,o+

boot_code:

; ------------------- PUT YOUR FAVOURITE BOOTCODE HERE! ----------------

    [...]

; -------------------------- END OF BOOTCODE ---------------------------
boot_code_end
```

3) For an executable bootsector to be executable, then sum of all the word values must equal **$1234**! You can do this with the trap #14 *proboot* call, though you can do it yourself by simply adding up all the word values in the bootsector buffer until byte 510, subtracting the result from $1234, and putting the (word) result in bytes 511-512. `BOOT.S` uses the trap #14 *proboot* call:

```
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
```

4) How could you possibly write a 512 byte buffer to disk. Yes, surprise! It's
   that good old trap #13 rwabs again, or a trap #14 flopwr call, like I did in `BOOT.S`. And that's
   all there is.

```
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
```

So having convinced you of how stunningly easy it is to put any old crap on your bootsector, let's make an antivirus bootsector!

## A simple antivirus bootsector

Generally, an antivirus is a bootsector which is there to stop any viruses edging in on it. Some more complex ones may help to detect viruses eg flash whenever a disk has an executable bootsector. However, they do NOT spread, so I would suspect that stuff like the *English/Dutch/German 'antivirus'* is really a virus which merely spreads under the pretence that it does not do any nasty virus type things like reverse mouse controls, wipe disks, etc., etc., ....

The simplest type of antivirus bootsector is the sort that just says that it's there, so if any virus overwrites it, then you'll notice. This is usually simple stuff like flashing colours and a text message. There are 2 examples of this in my source code, one in [`BOOT.S`](https://github.com/alephnaughtpix/agraboot2/blob/main/DOCS/examples/BOOT.S) and the other in [`PHNX_BT.S`](https://github.com/alephnaughtpix/agraboot2/blob/main/DOCS/examples/PHOENIX/PHNX_BT.S). I've also done an installer program for `PHNX_BT.S`, which allows you to type in any message you want to display with the bootsector! Look in [`INSTALLP.S`](https://github.com/alephnaughtpix/agraboot2/blob/main/DOCS/examples/PHOENIX/INSTALLP.S).

I might as well note here that there have been some **stunning** examples of this type of bootsector. For example: the *OVR full-o-boot, Fingerbobs sprites, Oberjee's rasters, Oberjee's starfield, DCK boot*. All of them done in less than 512 bytes!

The bootsector in `PHNX_BT.S` also checks to see in the reset vector has been changed, a possible pointer to a reset-proof virus. However, it is probably a bit more likely that any virus will be reset-**resident**, (eg *Ghost* virus) which uses a different technique entirely.

Without giving the whole game away to all you budding virus coders, reset-resident code depends on arranging code at a specific area in memory, and, like bootsectors, doing a checksum of this block of code to make sure it comes to a certain number. (But it's not `$1234`!) At the start of the block of code, there's a "magic number". Basically, all you have to do is look for this number. The first leaders in this sort of antivirus were the **Medway Boys** Protectors. (Although Protector v3.0 isn't 4 meg compatible.) Of course, my own Agraboot 2 is compatible *and* can check for reset-resident code!

## More complex antivirus bootsectors

Slightly more complex are the antivirus bootsectors which uses techniques used by virus writers to warn of potential viruses BEFORE you try and boot them up! (This is what this masterwork of an article is leading to, by the way!) You know, the sort. If a disk with an executable is placed in the drive, as soon as it's accessed, the screen flashes, and there might even be some sort of beep! Examples of this are *Exorcist boot*, and of course the *English/Dutch/German 'antivirus'*. (Except that it also spreads like a virus.)

Actually, I must protest as the way that such bootsectors readily flash at every executable bootsector! Nearly every PD or shareware disk these days has an antivirus bootsector, and of course all games and demos which use DMA loading have executable bootsectors. Which means that whatever disk you put in these days, your 'smart' antivirus will flash at them, whether they are disk threatening viruses or harmless *'Grythyx says hi to Bubblelob and Zoltar the aroused radio set.'* type messages. It's also incredibly easy to say *'Yeah, the screen's flashing cause I put an antivirus on it last week.'*, when, during the last week, a virus could have installed itself on that disk! As yet, there is no antivirus bootsector I have seen that can tell the difference between a virus and an ordinary executable bootsector. **Until now**, that is! For this is exactly what I'm going to do.

In what way can this be acheived? To do this, we need to look at the way a virus on the ST would operate. Don't worry- I'm not giving any exact details, so all you budding virus writers are going to be disappointed. Anyway, you'd have to be pretty clever to outwit most decent virus killer programs these days. I have included code for the *English 'Antivirus'* (Which I got from reverse-engineering the bloody thing after I got fed up of it cropping up on my disks!) for reference in [`ANTI.S`](https://github.com/alephnaughtpix/agraboot2/blob/main/DOCS/examples/ANTI.S).

## How viruses spread

When you think on it, a virus spreads in a pretty similar way to the magic 4 steps described above. All we need is a way of calling our antivirus routine every time a new disk is inserted, and a safe place in which to reside in memory.

One safe bit in memory would be in the area `$140-$3ff`. Certainly the *Ghost* virus resides in this area. However the *English 'antivirus'* takes an address from the memory location `$4c6`, adds `$600` to it, and treats this as a safe place to put it's routines!!!! It works, but it seemed strange to say the least.

Leafing through *ST Internals*, `$4c6` is referred to as a *'pointer to a 1024 byte disk buffer'* which is *'used for GSX routines'*!!!! GSX?!??!? And isn't $600 one and a *half* kilobytes?? That's 3 normal sectors worth, you know! Well, after looking closer at a couple of virus codes, it became obvious to me that this was a buffer containing the bootsector and 2 other sectors, (FATs?) which is set every time a normal disk directory is read, by... *who?... what?... where?.... what routine?* Aha! We have found both a way of reading the bootsector, and a possible way of calling our routines!

The vector which fills out all this information is `get_bpb` vector in `$472`. When this is called by the system, it pushes the drive number as a word value onto the stack, then jumps to the vector.

Note- the way the *English 'Antivirus'* finds a safe place in memory is a bit dodgy to be honest, as it assumes only $600 bytes are used, when in fact it could be more. (eg if there's a bigger directory, and more FATs are read.) It's also pretty dodgy if you've got a hard drive, which uses a lot of FATs! For these reasons, the *'antivirus'* can crash very badly on other Atari systems, but- get this- the *Ghost* virus still works!

## Putting it all together

Now we've got all the information we need to piece together our antivirus. Don't believe me? Let's go through the various steps of an antivirus and it's constituent parts one by one. First the installation of the routine.

1. When your ST executes the bootcode, first find some place in memory.
2. Copy your bootsector code to that area, and jump to the next instruction there.
3. Save the current `get_bpb` vector, and slot in your virus detect code into that vector.
4. Return to system.

And now your virus detect code.

1. `JSR` through the old `get_bpb` vector (to get the bootsector).
2. Examine the bootsector.
3. If it's executable, then flash the screen.
4. If it's a potential virus, then really flash it!
5. Return to system.

Finding the safe place in memory we've already covered. Copying the virus to that place BEFORE installing the routine in the `get_bpb` vector is vital because the bootsector uses pc-relative code, so installing your routine would mean that the `get_bpb` would point to some high point in ST memory rather than the safe place you actually intended for it! It makes sense when you think about it. Copying bits of code to other places is pretty simple stuff for the average ST assembler coder. So is saving the old `get_bpb` vector and installing your own virus detect routines. Remember that saving the old `get_bpb` is **vital**!!

Once you've done that, you can display a nice message, informing the user how helpful your nice antivirus is. You might notice that my antivirus flashes the screen in a similar way to Future Minds *Boul Boot*. I bet you'll kick yourself when you see how I did it!!!

## Detecting executable bootsectors

Now down to the nitty gritty of the virus detect code. While the likes of the *Ghost* virus isn't too fussy about what's in the bootsector cause it's gonna write over it anyway, an antivirus needs to have a look at the bootsector, so the first thing to do is `JSR` through the old `get_bpb` vector to get the bootsector. The slight complication in all of this is that we have to get the drive number and push it as a word value on the stack before the `JSR`. That value will have already been given by the system before it turned up in your `get_bpb` code!! So it'll be on the stack, behind the return address. All you have to do is get it.

In the *English 'antivirus'* this is done by using the `LINK` command. (Which I had never used in coding before.) `link an,#n` apparently means link address register an to the stack at the current moment with an offset of n. So, in the *'antivirus'* code we have `link a6,#0` which means that `a6` is now pointing to where the stack is at that particular point, and no matter how much you fiddle about with the stack, `a6` will stay where it is. I personally think now that this is not exactly the best way of doing it, especially since drive number is now in `8(a6)` rather than `4(a6)` as you might expect. Still, that's how I did it in Agraboot version 1.0, so you know what to improve. Anyway, however you get the number, push it on the stack, `JSR` through the old `get_bpb` vector, then correct the stack.

Now we've got the bootsector in the buffer pointed to by `$4c6`, how do we determine if it's executable or not? What's that I hear you say? Oh yes! If the checksum comes to `$1234`, then the bootsector is executable! So we add up all the word values in the buffer, and if it comes to `$1234`, then we flash the screen! Of course, we'll put some code to check that it's not our *own* antivirus but that's pretty easy. Hurrah hurrah! We've now got an antivirus that is the equal of any on the scene!

## Detecting viruses

But of course, we can go further. My **[Agraboot v1.0](https://github.com/alephnaughtpix/agraboot2/tree/main/DOCS/examples/AGRABOOT.1)** antivirus flashes the screen at an executable bootsector, but flashes RED at a possible virus!!! As far as I can tell, this is the only antivirus bootsector which has this feature. But since I am of the opinion that this sort of feature should be a bit more widespread, then I'll share the secret with you lucky readers!!!

Actually, there's nothing much to it. When you think on it, what is common to every virus? What have all viruses got to do to be viruses? Yes, they've got to spread!! So we look for the part which saves a virus onto the bootsector. Well, that's easy-peasy, we look for a Trap #13 *rwabs* call or a Trap #14 *flopwr* call.

Let's look at the offending calls in hexidecimal.


| INSTRUCTION          | HEX CODE      |
| ---------------------- | --------------- |
| `move.w  #4,-(sp)`   | `$3f3c0004`   |
| `trap    #13`        | `$4e4d`       |
| -------------------- | ------------- |
| `move.w  #9,-(sp)`   | `$3f3c0009`   |
| `trap    #14`        | `$4e4e`       |

As you can see, the offending instructions begin with a `$3f3c`, so if we find one in the virus bootsector, then we can check further for the rest of the incriminating bytes. If so, we can flash *'red for suspicious'*. This is not exactly foolproof, but it can detect most viruses.

If you want to see how I did then you can load up [`AGRABOOT.S`](https://github.com/alephnaughtpix/agraboot2/blob/main/DOCS/examples/AGRABOOT.1/AGRABOOT.S). It's old code now, and I've improved it, but it's quite nice. There's also an installer program for it in [`INSTALLB.S`](https://github.com/alephnaughtpix/agraboot2/blob/main/DOCS/examples/AGRABOOT.1/INSTALLA.S).

## Other uses for bootsector code

I did sneakily mention the part that bootsectors play in demos above. I'll not give too much away, since I'm actually helping to put one together at the moment, but let's say you have your DMA loader working, but you can't fit it on a 512 byte bootsector. (Which I think is probable, don't you?) How do you load the DMA loader into memory and start the demo proper? If you haven't guessed by now then there's no hope. Use trap #13 to sector load the DMA loader. Then you can jump to it. The advantage here is that there's lots of space to allow you to put in some really annoying protection into your demo!!!

You can even use a bootsector, even if you are not using a DMA loader! Yes! You can put something like a simple screen fade into the bootsector before the AUTO program loads, making it look like a REAL demo!!!

## Conclusion

So, that's just a glimpse (wot a cliche!) at the amazing power of the bootsector. If you wan't to know more, don't ask me, as I am just about to fall asleep because it is now nearly 2:30 am, and I, like most human beings, try to get to sleep at around this time, instead of typing stuff which should have been in *ST internals* anyway. Think about that the next time you boot up a disk.

**Agrajag**
