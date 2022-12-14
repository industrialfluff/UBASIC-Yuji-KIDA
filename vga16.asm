;vga16.asm
;vga 16 colors

data	SEGMENT	WORD PUBLIC

	extrn	linesdef:byte,chars1:byte,chars2:word,charsall2:word
	extrn	originalvideomode:byte

gpradr		dw	?
gproffset	db	?
gprmask1st	db	?
gprmask2nd	db	?

	even
gprstack_up	dw	5 dup(0)	;stack for TeX up
gprsp_up	dw	0
gprstack_down	dw	5 dup(0)	;stack for TeX down
gprsp_down	dw	0

data	ends


	public	farfunctionkeybox


RWmode	db	?		;vga 16 color only

	even
gramoveradr	dw	?

viewX1address	dw	?
viewY1startadr	dw	?
viewX2address	dw	?
viewY2overadr	dw	?
viewX1pixel	db	?
viewX2pixel	db	?

pixelsreal	dw	?,?
linecount	dw	?

gadr		dw	?
goff		db	?,0

linelength	dw	?
pixelstepreal	dw	?,?

linedirection	dw	?	;\pm 1
linegxbytes	dw	?	;\pm gxbytes

radius2low	dw	?
radius2high	dw	?

arcX1	dw	?
arcY1	dw	?
arcX2	dw	?
arcY2	dw	?

dirX	dw	?
dirY	dw	?
absX	dw	?
absY	dw	?


ellipseX1	equ	arcX1
ellipseY1	equ	arcY1
ellipseX2	equ	arcX2
ellipseY2	equ	arcY2

tangent1gx	dw	?
tangent1gy	dw	?

	even
paintbuffertop	dw	?
paintbufferover	dw	?
paintbaseadr	dw	?
metothertask	db	?

countarc	db	?


	public	resetXYinfo,return2text

_CRTstatusregister	equ	03dah	;color mode
_attributecontroller	equ	03c0h
_graphiccontroller	equ	03ceh
_sequencer		equ	03c4h

_read0write0		equ	00h
_read0write1		equ	01h
_read0write2		equ	02h
_read0write3		equ	03h
_read1write0		equ	08h
_read1write1		equ	09h
_read1write2		equ	0ah
_read1write3		equ	0bh

_setreset	equ	0
_enablesetreset	equ	1
_colorcompare	equ	2
_datarotate	equ	3
_readmap	equ	4
_readwritemode	equ	5
_miscella	equ	6
_colordontcare	equ	7
_bitmask	equ	8

_mapmask	equ	2

	even
setresetnow	db	?
enablenow	db	?
colorcomparenow	db	?
datarotatenow	db	?
readmapnow	db	?
readwritenow	db	?
miscellanow	db	?
colordontnow	db	?
bitmasknow	db	?
mapmasknow	db	?
displplanenow	db	?

setresetmem	db	?
enablemem	db	?
colorcomparemem	db	?
datarotatemem	db	?
readmapmem	db	?
readwritemem	db	?
miscellamem	db	?
colordontmem	db	?
bitmaskmem	db	?
mapmaskmem	db	?
displplanemem	db	?

monocolormask	db	?		;translate any color number to 15
					;on monochrome mode

	even
palettesetnow	dw	offset paletteIBM3
palette0	db	0,15 dup(7),0
palette2	db	0,1,4,5,2,3,6,7,9 dup(0)
palette3	db	0,9,36,45,58,59,62,63,56,1,4,5,2,3,6,7,0
paletteIBM2	db	0,1,2,3,4,5,6,7,0,9 dup(0)
;palette4	db	0,18,27,36,45,54,63,9 dup(0)
paletteIBM3	db	0,1,2,3,4,5,6,7,56,57,58,59,60,61,62,63,0
;palette14	db	0,1,2,3,4,5,6,7,56,9,18,27,36,45,54,63,0
dummypalette	db	10,12,13,14,15,17,21,22,23,25,28,29,30,31,33,35


;work area : usable by any routines

gscrolldiff	dw	?
gscrolldiffbytes	dw	?
gscrolllines	dw	?
gscrolltopadr	dw	?
gscrollbytes	dw	?
gscrollmask1	db	0
gscrollmask2	db	0
gscrolladr1	dw	?
gscrolladr2	dw	?
gscrolloffbytes	dw	?
gscrolloffbits	db	?,0

	even
srcXbytes	dw	?	;source bytes/line/plane
destXbytes	dw	?	;destination
srcallXbytes	dw	?	;source bytes/line in all planes
myputlines	dw	?	;lines to put
mygetbitoff	db	?

fontbuffer	db	34 dup(0)




;
gregsave:
	push	es
	mov	ax,cs
	mov	es,ax

	mov	si,offset setresetnow
	mov	di,offset setresetmem
	mov	cx,11
	rep	movs byte ptr es:[si], es:[di]

	mov	ax,_read1write1
	call	readwritemode
	mov	ax,_gramseg
	mov	es,ax
	mov	di,[gramoveradr]
	mov	es:[di+1],al	;save ratch data
	mov	ah,[readwritemem]
	call	readwritemode
	pop	es
	ret

;
gregrestore:
	mov	ah,readwritemem
	call	readwritemode

	mov	ah,colordontmem
	call	colordontcare

	mov	ah,bitmaskmem
	call	bitmask

	mov	ah,datarotatemem
	call	datarotate

	mov	ah,mapmaskmem
	call	mapmask

	call	clearratch

	mov	ah,enablemem
	call	enablesetreset

	mov	ah,setresetmem
	call	setreset

	mov	ah,colorcomparemem
	call	colorcompare

	mov	ah,readmapmem
	call	readmap

	mov	ah,displplanemem
	call	selectdisplayplane

	push	es
	mov	ax,_gramseg
	mov	es,ax
	mov	di,[gramoveradr]
	mov	al,es:[di+1]	;restore ratch data
	pop	es
	ret


; Since texts in graphic mode use current ratch data as a background
; color, such ratch data must be cleared

clearratch:
	mov	ah,0fh
	call	enablesetreset
	mov	ah,0
	call	setreset

	push	es
	mov	ax,_gramseg
	mov	es,ax
	mov	di,[gramoveradr]
	mov	al,es:[di]		;dummy read
	pop	es			;to clear ratch
	ret


weakgregnormal:
	mov	ah,_read1write3
	call	readwritemode

	mov	ah,0
	call	colordontcare

	mov	ah,0ffh
	call	bitmask

	mov	ah,_greplace
	call	datarotate

	mov	ah,[activeplane]
	call	mapmask

	call	clearratch

	mov	ah,0
	call	enablesetreset

	mov	ah,[gcolor]
	call	setreset

	mov	ah,ss:[displplane]
	call	selectdisplayplane
	ret


gregnormal:
	mov	ah,_read1write3
	call	readwritemodein

	mov	ah,0
	call	colordontcarein

	mov	ah,0ffh
	call	bitmaskin

	mov	ah,_greplace
	call	datarotatein

	mov	ah,[activeplane]
	call	mapmaskin

	mov	ah,0
	call	enablesetresetin

	mov	ah,[gcolor]
	call	setresetin

	mov	ah,ss:[displplane]
;	jmp	selectdisplayplanein
;	ret

selectdisplayplane:
	cmp	ah,[displplanenow]
	je	selectdisplret
selectdisplayplanein:
	push	bx
	mov	[displplanenow],ah
	mov	bh,ah
	mov	ax,1000h
	mov	bl,12h
	int	10h
	pop	bx
selectdisplret:
	ret


setreset:
	or	ah,ah
	jz	setresetjp
	or	ah,[monocolormask]
setresetjp:
	cmp	ah,[setresetnow]
	je	setresetret
setresetin:
	mov	[setresetnow],ah
	mov	dx,_graphiccontroller
	mov	al,_setreset
	out	dx,ax
setresetret:
	ret

enablesetreset:
	cmp	ah,[enablenow]
	je	enablesetresetret
enablesetresetin:
	mov	[enablenow],ah
	mov	dx,_graphiccontroller
	mov	al,_enablesetreset
	out	dx,ax
enablesetresetret:
	ret

colorcompare:
	cmp	ah,[colorcomparenow]
	je	colorcompareret
colorcomparein:
	mov	[colorcomparenow],ah
	mov	dx,_graphiccontroller
	mov	al,_colorcompare
	out	dx,ax
colorcompareret:
	ret

datarotate:
	cmp	ah,[datarotatenow]
	je	datarotateret
datarotatein:
	mov	[datarotatenow],ah
	mov	dx,_graphiccontroller
	mov	al,_datarotate
	out	dx,ax
datarotateret:
	ret

readmap:
	cmp	ah,[readmapnow]
	je	readmapret
readmapin:
	mov	[readmapnow],ah
	mov	dx,_graphiccontroller
	mov	al,_readmap
	out	dx,ax
readmapret:
	ret

readwritemode:
	cmp	ah,[readwritenow]
	je	readwriteret
readwritemodein:
	mov	[readwritenow],ah
	mov	dx,_graphiccontroller
	mov	al,_readwritemode
	out	dx,ax
readwriteret:
	ret

miscella:
	cmp	ah,[miscellanow]
	je	miscellaret
miscellain:
	mov	[miscellanow],ah
	mov	dx,_graphiccontroller
	mov	al,_miscella
	out	dx,ax
miscellaret:
	ret

colordontcare:
	cmp	ah,[colordontnow]
	je	colordontret
colordontcarein:
	mov	[colordontnow],ah
	mov	dx,_graphiccontroller
	mov	al,_colordontcare
	out	dx,ax
colordontret:
	ret

bitmask:
	cmp	ah,[bitmasknow]
	je	bitmaskret
bitmaskin:
	mov	[bitmasknow],ah
	mov	dx,_graphiccontroller
	mov	al,_bitmask
	out	dx,ax
bitmaskret:
	ret

mapmask:
	cmp	ah,[mapmasknow]
	je	mapmaskret
mapmaskin:
	mov	[mapmasknow],ah
	mov	dx,_sequencer
	mov	al,_mapmask
	out	dx,ax
mapmaskret:
	ret


;
;*
;
mybox:
	call	gregnormal
	push	es
	mov	ax,_gramseg
	mov	es,ax
	call	boxclipping
	jc	myboxret
	call	myboxsub
myboxret:
	pop	es
	jmp	weakgregnormal		;call & ret


	;draw box
	;inp: ([bX1],[bY1])-([bX2],[bY2])
	;     [palette]
myboxsub:
	mov	ax,[bX1]
	mov	[gX1],ax
	mov	ax,[bX2]
	mov	[gX2],ax
	mov	ax,[bY1]
	cmp	ax,[viewY1]
	jl	myboxsub10
	mov	[gY1],ax
	mov	[gY2],ax
	call	mylinesub
myboxsub10:
	mov	ax,[bY2]
	cmp	ax,[viewY2]
	jg	myboxsub20
	mov	[gY1],ax
	mov	[gY2],ax
	call	mylinesub
myboxsub20:
	mov	ax,[bX1]
	cmp	ax,[viewX1]
	jl	myboxsub30
	mov	[gX1],ax
	mov	[gX2],ax
	mov	ax,[bY1]
	mov	[gY1],ax
	mov	ax,[bY2]
	mov	[gY2],ax
	call	mylinesub
myboxsub30:
	mov	ax,[bX2]
	cmp	ax,[viewX2]
	jg	myboxsub40
	mov	[gX1],ax
	mov	[gX2],ax
	mov	ax,[bY1]
	mov	[gY1],ax
	mov	ax,[bY2]
	mov	[gY2],ax
	call	mylinesub
myboxsub40:
	ret


myboxfill:
	;draw box and fill inside
	;inp: ([bX1],[bY1])-([bX2],[bY2])
	;     [palette]
	;     [paintcolor]

	call	gregnormal
	push	es
	mov	ax,_gramseg
	mov	es,ax

	call	boxclipping
	jc	boxfillret
	call	myboxsub

	mov	ah,[paintcolor]
	call	setreset

	mov	ax,[bX2]
	mov	dx,[bX1]
	cmp	ax,dx
	jae	boxfill10
	xchg	ax,dx
boxfill10:
	inc	dx
	mov	[gX],dx
	sub	ax,dx
	jbe	boxfillret		;no inner space
	mov	[linelength],ax

	mov	ax,[bY2]
	mov	dx,[bY1]
	cmp	ax,dx
	jae	boxfill20
	xchg	ax,dx
boxfill20:
	inc	dx
	mov	[gY],dx
	sub	ax,dx
	jbe	boxfillret		;no inner space

	mov	cx,ax

	cmp	[tilelength],0
	jne	boxfilllpB
boxfilllp:
	push	cx
	call	Hline
	inc	[gY]
	pop	cx
	myloop	boxfilllp
	jmps	boxfillret

boxfilllpB:
	push	cx
	call	HlineTile
	inc	[gY]
	pop	cx
	myloop	boxfilllpB

boxfillret:
	pop	es
	jmp	weakgregnormal		;call & ret


;
;*
;
mypset:
	call	gregnormal
	mov	ah,_read1write3
	call	readwritemode
	push	es
	mov	ax,_gramseg
	mov	es,ax
	call	getadr_setpixel
	pop	es
	jmp	weakgregnormal		;call & ret


getadr_setpixel:
	;inp: ([gX],[gY])
	;     [palette]
	;out: di=adr, cl=bit position(MSB=0,LSB=7)
	;     set pixel

	;assume ds=data, es=_gramseg, mode=_read1write3

	mov	ah,[gcolor]
	call	setreset

getadr_setpixel_in:
	mov	ax,[gY]
	mul	[gxbytes]
	mov	di,ax
	mov	ax,[gX]
	mov	cx,ax
	my_shr	ax,3
	add	di,ax
	and	cl,07h
	mov	al,80h
	shr	al,cl
	and	es:[di],al
	ret

;
;*
;
mypget:
	;inp: ([gX],[gY])
	;out: al=palette

	call	gregnormal

	push	es
	mov	ax,_gramseg
	mov	es,ax

	mov	ah,_read0write3
	call	readwritemode

	mov	ax,[gY]
	mul	[gxbytes]
	mov	di,ax
	mov	ax,[gX]
	mov	cx,ax
	my_shr	ax,3
	add	di,ax
	and	cl,07h
	mov	al,80h
	shr	al,cl
	mov	ch,al		;mask
	xor	bx,bx		;answer
	mov	cl,3
pgeti10:
	mov	ah,cl
	call	readmap

	mov	al,es:[di]
	and	al,ch
	jz	pgeti20
	stc
pgeti20:
	rcl	bx,1
	sub	cl,1
	jnb	pgeti10

	mov	ah,_read1write3
	call	readwritemode

	pop	es
	push	bx
	call	weakgregnormal
	pop	ax
	xor	ah,ah
	ret


getadr:
	mov	ax,[gY]
	mul	[gxbytes]
	mov	di,ax
	mov	ax,[gX]
	mov	cx,ax
	my_shr	ax,3
	add	di,ax
	and	cl,07h
;	mov	al,80h
;	shr	al,cl
	ret


;
; *
;
myline:
	call	gregnormal
	push	es
	mov	ax,_gramseg
	mov	es,ax
	call	mylinesub
	pop	es
	jmp	weakgregnormal	;call & ret


mylinesub:
	;draw a line with clipping
	;inp: ([gX1],[gY1])-([gX2],[gY2])
	;     [palette]

	mov	ah,[gcolor]
	call	setreset

	mov	ax,[gX2]
	push	ax			;* push [gX2]
	sub	ax,[gX1]
	jge	myline10
	neg	ax
myline10:
	mov	cx,[gY2]
	push	cx			;** push [gY2]
	sub	cx,[gY1]
	jge	myline20
	neg	cx
myline20:
	cmp	ax,cx
	jbe	lineVertical

lineHorizontal:
	call	clipping
	jc	lineret

	mov	ax,[gX2]
	mov	bx,[gX1]
	cmp	ax,bx
	jge	lineH10
	xchg	ax,bx
	mov	[gX2],ax
	mov	[gX1],bx
	mov	cx,[gY1]
	xchg	cx,[gY2]
	mov	[gY1],cx
lineH10:
	sub	ax,bx
	inc	ax			;diffx

	mov	bx,1
	mov	dx,[gxbytes]
	mov	cx,[gY2]
	sub	cx,[gY1]
	jnb	lineH20
	neg	cx
	neg	bx
	neg	dx
lineH20:
	mov	[linedirection],bx
	mov	[linegxbytes],dx
	inc	cx			;dy
	mov	[linecount],cx
	xor	dx,dx
	shl	ax,1
	div	cx
	mov	[pixelstepreal+2],ax
	xor	ax,ax
	div	cx
	mov	[pixelstepreal],ax
	mov	ax,[gX1]
	mov	[gX],ax
	mov	ax,[gY1]
	mov	[gY],ax
	call	getadr_setpixel
	mov	[gadr],di		;start adr
	mov	[goff],cl		;start bit position
	inc	cl			;move 1 pixel
	and	cl,7
	jnz	lineH30
	inc	di
lineH30:
	mov	[goff],cl

	cmp	[pixelstepreal+2],2
	ja	lineH40
	mov	ax,[pixelstepreal]
	mov	[pixelsreal],ax
	mov	ax,[pixelstepreal+2]
	mov	[pixelsreal+2],ax
	add	di,[linegxbytes]
	mov	[gadr],di
	jmp	lineHlp

lineH40:				;1st line
	mov	[gadr],di
	mov	ax,[pixelstepreal]
	mov	[pixelsreal],ax
	mov	ax,[pixelstepreal+2]
	mov	[pixelsreal+2],ax
	inc	ax
	shr	ax,1
	dec	ax			;already set 1 pixel
	mov	[linelength],ax
	call	linesubX

lineHlp:
	dec	[linecount]
	jz	lineret
	mov	ax,[pixelstepreal]
	add	[pixelsreal],ax
	mov	ax,[pixelstepreal+2]
	mov	dx,[pixelsreal+2]
	adc	ax,dx
	mov	[pixelsreal+2],ax
	inc	dx
	shr	dx,1
	inc	ax
	shr	ax,1
	sub	ax,dx
	mov	[linelength],ax
	call	linesubX
	jmp	lineHlp

lineret:
	pop	[gY]			;**
	pop	[gX]			;*
	ret


lineVertical:
	call	clipping
	jc	lineret

	mov	ax,[gY2]
	mov	bx,[gY1]
	cmp	ax,bx
	jae	lineV10
	xchg	ax,bx
	mov	[gY2],ax
	mov	[gY1],bx
	mov	cx,[gX1]
	xchg	cx,[gX2]
	mov	[gX1],cx
lineV10:
	sub	ax,bx
	inc	ax			;diffy

	mov	bx,1
	mov	cx,[gX2]
	sub	cx,[gX1]
	jnb	lineV20
	neg	cx
	neg	bx
lineV20:
	mov	[linedirection],bx
	inc	cx			;dx
	mov	[linecount],cx		;number of lines
	shl	ax,1
	xor	dx,dx
	div	cx
	mov	[pixelstepreal+2],ax
	xor	ax,ax
	div	cx
	mov	[pixelstepreal],ax

	mov	ax,[gX1]
	mov	[gX],ax
	mov	ax,[gY1]
	mov	[gY],ax
	call	getadr_setpixel		;set start pixel
	mov	[gadr],di
	mov	[goff],cl		;start adr

	add	di,[gxbytes]

	cmp	[pixelstepreal+2],2
	ja	lineV39

	mov	ax,[pixelstepreal]
	mov	[pixelsreal],ax
	mov	ax,[pixelstepreal+2]
	mov	[pixelsreal+2],ax
	mov	dx,[linedirection]
	mov	ax,word ptr [goff]
	add	ax,dx
	cmp	ax,8
	jb	lineV38
	sub	ax,8
	jz	lineV36
	mov	ax,7
lineV36:
	add	di,dx
lineV38:
	mov	[goff],al
	mov	[gadr],di
	jmp	lineVlp

lineV39:
	mov	[gadr],di

lineV40:
	mov	ax,[pixelstepreal]
	mov	[pixelsreal],ax
	mov	ax,[pixelstepreal+2]
	mov	[pixelsreal+2],ax
	inc	ax
	shr	ax,1
	dec	ax			;already draw 1 pixel
	mov	[linelength],ax
	call	linesubY

lineVlp:
	dec	[linecount]
	jz	lineret
	mov	ax,[pixelstepreal]
	add	[pixelsreal],ax
	mov	ax,[pixelstepreal+2]
	mov	dx,[pixelsreal+2]
	adc	ax,dx
	mov	[pixelsreal+2],ax
	inc	dx
	shr	dx,1
	inc	ax
	shr	ax,1
	sub	ax,dx
	mov	[linelength],ax
	call	linesubY
	jmp	lineVlp


linesubX:
	push	cx
	push	bp

	mov	cx,[linelength]
	jcxz	linesubXret

	; 1st byte

	mov	bp,[linestylesw]

	mov	ax,8
	sub	al,[goff]		;pixels in right hand side
	sub	cx,ax
	ja	linesubX100		;data in other adr exist
	add	cx,ax
	mov	ax,00ffh
	shl	ax,cl
	add	cl,[goff]
	sub	cx,8
	neg	cx
	shl	ah,cl
	mov	di,[gadr]
	mov	al,es:[di]		;dummy read
	or	bp,bp
	jz	linesubX10
	mov	si,di
	and	si,3
	and	ah,linestyleXpattern[si]
linesubX10:
	mov	es:[di],ah
	mov	ax,[linelength]
	add	al,[goff]
	and	al,7
	jnz	linesubX20
	inc	di
linesubX20:
	mov	[goff],al
	add	di,[linegxbytes]
	mov	[gadr],di
	jmp	linesubXret

linesubX100:
	; 1st byte

	mov	cx,8
	sub	cl,[goff]
	mov	ax,00ffh
	shl	ax,cl
	mov	di,[gadr]
	mov	al,es:[di]		;dummy read
	or	bp,bp
	je	linesubX110
	mov	si,di
	and	si,3
	and	ah,linestyleXpattern[si]
linesubX110:
	mov	es:[di],ah
	inc	di

	; other bytes

	mov	dx,[linelength]
	sub	dx,cx
	mov	cx,dx
	my_shr	cx,3			;/8

	jcxz	linesubX130
	mov	al,0ffh			;full pattern
linesubX120:
	or	bp,bp
	jz	linesubX125
	mov	si,di
	and	si,3
	mov	al,linestyleXpattern[si]
	inc	si
linesubX125:
	mov	ah,es:[di]		;dummy read
	stosb
	myloop	linesubX120

	; last byte

linesubX130:
	and	dl,07h
	jz	linesubX150		;already last byte
	mov	cl,dl
	mov	ax,0ff00h
	shr	ax,cl
	mov	ah,es:[di]		;dummy read
	or	bp,bp
	jz	linestylesub140
	mov	si,di
	and	si,3
	and	al,linestyleXpattern[si]
linestylesub140:
	mov	es:[di],al
linesubX150:
	mov	[goff],dl
	add	di,[linegxbytes]
	mov	[gadr],di

linesubXret:
	pop	bp
	pop	cx
	ret


linesubY:
	push	cx

	mov	cx,[linelength]
	jcxz	linesubYret

	mov	ax,di			;for line style
	xor	dx,dx			;
	div	word ptr [gxbytes]	;
	mov	si,ax			;

	mov	cl,[goff]
	mov	al,80h
	shr	al,cl
	mov	dx,ax			;memo al
	mov	di,[gadr]
	mov	cx,[linelength]

	cmp	[linestylesw],0
	jne	linesubYlpB		;with linestyle

linesubYlp:
	mov	ah,es:[di]		;dummy read
	mov	al,dl
	mov	es:[di],al
	add	di,[gxbytes]
	inc	si
	myloop	linesubYlp
	jmps	linesubYjp

linesubYlpB:
	mov	ah,es:[di]		;dummy read
	mov	al,dl
	and	si,31
	and	al,linestyleYpattern[si]
	mov	es:[di],al
	add	di,[gxbytes]
	inc	si
	myloop	linesubYlpB

linesubYjp:
	mov	dx,[linedirection]
	mov	al,[goff]
	add	al,dl
	cmp	al,8
	jb	linesubY110
	sub	al,8
	jz	linesubY100
	mov	al,7
linesubY100:
	add	di,dx
linesubY110:
	mov	[gadr],di
	mov	[goff],al
linesubYret:
	pop	cx
	ret


;
;*
;
mysetlinestyle:
		;inp: dx:ax = 32bits pattern

	xchg	dl,dh
	xchg	al,ah
	mov	[linestylesw],4		;set switch
	mov	si,offset linestyleXpattern
	mov	[si],dx
	mov	[si+2],ax
	xchg	dl,dh
	xchg	al,ah

	mov	si,offset linestyleYpattern
	push	ax
	mov	cx,16
setlinestyle10:
	xor	al,al
	shl	dx,1
	jnc	setlinestyle20
	dec	al
setlinestyle20:
	mov	[si],al
	inc	si
	myloop	setlinestyle10

	pop	dx
	mov	cx,16
setlinestyle30:
	xor	al,al
	shl	dx,1
	jnc	setlinestyle40
	dec	al
setlinestyle40:
	mov	[si],al
	inc	si
	myloop	setlinestyle30
	ret


Hline:
	;draw horizontal line
	;inp: ([gX],[gY]), [linelength]
	
	call	getadr_setpixel_in
	mov	[goff],cl
	mov	[gadr],di
	call	linesubX
	ret


Vline:
	;draw vertical line
	;inp: ([gX],[gY]), [linelength]
	
	call	getadr_setpixel_in
	mov	[goff],cl
	mov	[gadr],di
	call	linesubY
	ret


HlineTile:
	;draw horizontal line
	;with tilepattern
	;inp: ([gX],[gY]), [linelength]
	
	call	getadr
	mov	[goff],cl
	mov	[gadr],di
	call	linesubXtile
	mov	ah,0fh
	call	mapmask
	ret



linesubXtile:
	;usage : see HlineTile above
	;must recover the videomode

;	push	cx

	mov	cx,[linelength]
	jcxz	linesubXtret

	mov	ah,_read0write0
	call	readwritemode

	mov	ah,0
	call	enablesetreset

	mov	ax,[gadr]
	xor	dx,dx
	div	word ptr [gxbytes]
	push	ax
	mov	cx,4
	xor	al,al
	mov	ah,[activeplane]
linesubXt10:
	shr	ah,1
	adc	al,0
	myloop	linesubXt10
	mov	cl,al			;cx=ax:# of active planes
	pop	ax
	mul	cx
	xor	dx,dx
	div	[tilelength]
	mov	si,dx			;start of tile pattern
	add	si,[tileaddress]

	mov	cx,0001h		;ch=0 for readmap, cl=1 for mapmask
linesubXtlp:
	test	cl,[activeplane]
	jz	linesubXtskip

	push	cx

	mov	ah,ch
	call	readmap

	mov	ah,cl
	call	mapmask

	mov	bl,[si]			;tile pattern

	; 1st byte

	mov	cx,[linelength]
	mov	ax,8
	sub	al,[goff]		;pixels in right hand side
	sub	cx,ax
	ja	linesubXt100		;data in other adr exist
	add	cx,ax
	mov	ax,00ffh
	shl	ax,cl			;lower of ah=line of disired length
	add	cl,[goff]
	sub	cx,8
	neg	cx
	shl	ah,cl
	call	bitmask
	mov	di,[gadr]
	mov	al,es:[di]		;dummy read
	mov	es:[di],bl		;tile
	jmp	linesubXt200

linesubXt100:
	; 1st byte

	mov	cx,8
	sub	cl,[goff]
	mov	ax,00ffh
	shl	ax,cl
	call	bitmask
	mov	di,[gadr]
	mov	al,es:[di]		;dummy read
	mov	es:[di],bl		;tile
	inc	di

	; other bytes

	mov	dx,[linelength]
	sub	dx,cx
	mov	cx,dx
	my_shr	cx,3			;/8

	jcxz	linesubXt130

	push	dx
	mov	ah,0ffh
	call	bitmask
	pop	dx
linesubXt120:
	mov	al,es:[di]		;dummy read
	mov	es:[di],bl		;tile
	inc	di
	myloop	linesubXt120

	; last byte

linesubXt130:
	and	dl,07h
	jz	linesubXt200		;already last byte
	mov	cl,dl
	mov	ax,00ffh
	ror	ax,cl
	call	bitmask
	mov	al,es:[di]		;dummy read
	mov	es:[di],bl		;tile

linesubXt200:
	inc	si
	sub	si,[tileaddress]
	cmp	si,[tilelength]
	jb	linesubXt210
	xor	si,si
linesubXt210:
	add	si,[tileaddress]
	pop	cx
linesubXtskip:
	shl	cl,1
	inc	ch
	cmp	ch,4
	jb	linesubXtlp

linesubXtret:
;	pop	cx
	ret


circlesubsub:
	mov	ax,[gY]
	mul	[gxbytes]
	mov	di,ax

	mov	ax,[centerX]
	add	ax,[gX]
	cmp	ax,[viewX1]
	jl	circlesubskip40	;no pt to set
	cmp	ax,[viewX2]
	jg	circlesubskip20

	mov	cx,ax
	my_shr	ax,3
	add	ax,si
	mov	bx,ax
	and	cl,07h
	mov	al,80h
	shr	al,cl

	mov	cx,[centerY]
	add	cx,[gY]
	cmp	cx,[viewY1]
	jl	circlesubskip40	;no pt to set
	cmp	cx,[viewY2]
	jg	circlesubskip10

	and	es:[bx+di],al
circlesubskip10:
	mov	cx,[centerY]
	sub	cx,[gY]
	cmp	cx,[viewY1]
	jl	circlesubskip20
	cmp	cx,[viewY2]
	jg	circlesubskip40

	neg	di
	and	es:[bx+di],al
	neg	di

circlesubskip20:
	mov	ax,[centerX]
	sub	ax,[gX]
	cmp	ax,[viewX1]
	jl	circlesubskip40
	cmp	ax,[viewX2]
	jg	circlesubskip40
	mov	cx,ax
	my_shr	ax,3
	add	ax,si
	mov	bx,ax
	and	cl,07h
	mov	al,80h
	shr	al,cl

	mov	cx,[centerY]
	add	cx,[gY]
	cmp	cx,[viewY2]
	jg	circlesubskip30
	cmp	cx,[viewY1]
	jl	circlesubskip40
	and	es:[bx+di],al
circlesubskip30:
	mov	cx,[centerY]
	sub	cx,[gY]
	cmp	cx,[viewY1]
	jl	circlesubskip40
	cmp	cx,[viewY2]
	jg	circlesubskip40
	neg	di
	and	es:[bx+di],al
circlesubskip40:
	ret



;
;*
;
mycircle:
	;draw circle
	;inp: ([centerX],[centerY]), [radius]
	;     [palette]

	push	es
	mov	[paintflg],0
	call	gregnormal
	mov	ax,_gramseg
	mov	es,ax
	call	mycirclemain
	pop	es
	jmp	weakgregnormal	;call & ret

;
;*
;
mycirclefill:
	;draw circle and fill inside
	;inp: ([centerX],[centerY]), [radius]
	;     [palette]

	push	ds
	push	es

	mov	[paintflg],-1
	call	gregnormal

	mov	ax,graphworkseg		;save data
	add	ax,data
	mov	es,ax
	mov	si,[txttop]
	mov	di,0
	mov	cx,[viewY2]
	inc	cx
	my_shl	cx,1		;2words/line
	rep	movsw

	mov	ax,data		;fill work by 8000h
	mov	es,ax
	mov	di,[txttop]
	mov	cx,[viewY2]
	inc	cx
	my_shl	cx,1		;2words/line
	mov	ax,8000h
	rep	stosw

	mov	ax,_gramseg
	mov	es,ax
	call	mycirclemain

	mov	ah,[paintcolor]
	call	setreset
	call	mycirclefillinner

	mov	ax,data
	mov	es,ax
	mov	ax,graphworkseg		;restore data
	add	ax,data
	mov	ds,ax
	mov	si,0
	mov	di,es:[txttop]
	mov	cx,es:[viewY2]
	my_shl	cx,1		;2words/line
	rep	movsw

	pop	es
	pop	ds
	jmp	weakgregnormal	;call & ret


mycirclenot:
	ret

mycirclemain:
	mov	ah,[gcolor]
	call	setreset

	mov	dx,[radius]
	mov	ax,[centerX]
	add	ax,dx
	cmp	ax,[viewX1]
	jl	mycirclenot	;out of range
	sub	ax,dx
	sub	ax,dx
	cmp	ax,[viewX2]
	jg	mycirclenot
	mov	ax,[centerY]
	add	ax,dx
	cmp	ax,[viewY1]
	jl	mycirclenot	;out of range
	sub	ax,dx
	sub	ax,dx
	cmp	ax,[viewY2]
	jg	mycirclenot

	mov	ax,[centerY]
	mov	si,[centerbaseadr]	;si = base address of center

myellipseXYequal:		;jumped from ellipse routine
	mov	bx,[radius]
	mov	ax,0
	mov	[gX],bx
	mov	[gY],ax
	mov	dx,0		;dx = diff = x^2+y^2-r^2

	call	mycirclesub

	;compute only 1/8 circle: i.e. while y <= x

mycircleLP:
	cmp	ax,bx
	ja	circleret

	mov	cx,ax
	shl	cx,1
	inc	cx
	add	dx,cx		;diff += 2y+1
	mov	cx,bx
	shl	cx,1
	dec	cx		;cx = 2x-1
	sub	dx,cx		;diff += 2y+1-2x+1
	jge	circle110	;new x = old x - 1
	neg	dx
	cmp	dx,bx
	jb	circle105
	neg	dx
	add	dx,cx
	jmps	circle120
circle105:
	neg	dx
circle110:
	dec	bx
	mov	[gX],bx		;new x = old x -1
circle120:
	inc	ax
	mov	[gY],ax
	call	mycirclesub
	jmp	mycircleLP
circleret:
	ret


mycirclesub:
	push	ax
	push	bx
	push	dx
	cmp	[paintflg],0
	jne	mycirclefillsub
	call	circlesubsub
	mov	ax,[gY]
	xchg	ax,[gX]
	mov	[gY],ax
	call	circlesubsub
	mov	ax,[gY]
	xchg	ax,[gX]
	mov	[gY],ax
	pop	dx
	pop	bx
	pop	ax
	ret


mycirclefillsub:
	push	si
	call	circlefillmem
	mov	ax,[gY]
	xchg	ax,[gX]
	mov	[gY],ax
	call	circlefillmem
	mov	ax,[gY]
	mov	[gY1],ax	;memo
	xchg	ax,[gX]
	mov	[gY],ax
	pop	si

	pop	dx
	pop	bx
	pop	ax
	ret


circlefillmem:
	mov	ax,[centerX]
	add	ax,[gX]
	cmp	ax,[viewX1]
	jl	circlememret		;no pt to set

	dec	ax
	mov	dx,[viewX2]
	cmp	ax,dx
	jle	circlemem10
	mov	ax,dx
circlemem10:
	mov	[gX2],ax

	mov	ax,[centerX]
	sub	ax,[gX]
	cmp	ax,[viewX2]
	jg	circlememret	;no pt to set

	inc	ax
	mov	cx,[viewX1]
	cmp	ax,cx
	jge	circlemem20	;left end = viewX1
	mov	ax,cx
circlemem20:			;now cx = left end
	mov	[gX1],ax

	mov	bx,[centerbaseadr]	;center
	mov	ax,[gY]
	mul	[gxbytes]
	mov	di,ax

	mov	ax,[centerY]
	add	ax,[gY]
	cmp	ax,[viewY1]
	jl	circlememret
	cmp	ax,[viewY2]
	jg	circlemem50

	my_shl	ax,2		;4bytes/line
	add	ax,[txttop]
	mov	si,ax

	mov	ax,[gX1]
	cmp	ax,[si]
	jle	circlemem30
	mov	[si],ax
circlemem30:
	mov	ax,[gX2]
	cmp	ax,[si+2]
	jae	circlemem40
	mov	[si+2],ax
circlemem40:
	call	circlefillsetpt

circlemem50:
	mov	ax,[centerY]
	sub	ax,[gY]
	cmp	ax,[viewY1]
	jl	circlememret
	cmp	ax,[viewY2]
	jg	circlememret

	my_shl	ax,2		;4bytes/line
	add	ax,[txttop]
	mov	si,ax

	mov	ax,[gX1]
	cmp	ax,[si]
	jle	circlemem60
	mov	[si],ax
circlemem60:
	mov	ax,[gX2]
	cmp	ax,[si+2]
	jae	circlemem70
	mov	[si+2],ax
circlemem70:
	neg	di
	call	circlefillsetpt

circlememret:
	ret


circlefillsetpt:
	;inp: bx+di = base adr of Y

	mov	ax,[gX1]
	cmp	ax,[viewX1]
	je	circlefillsetpt10

	dec	ax
	mov	cx,ax
	my_shr	ax,3
	add	di,ax
	and	cl,07h
	mov	ch,80h
	shr	ch,cl
	and	es:[bx+di],ch
	sub	di,ax

circlefillsetpt10:
	mov	ax,[gX2]
	cmp	ax,[viewX2]
	je	circlefillsetpt20

	inc	ax
	mov	cx,ax
	my_shr	ax,3
	add	di,ax
	and	cl,07h
	mov	ch,80h
	shr	ch,cl
	and	es:[bx+di],ch
	sub	di,ax

circlefillsetpt20:
	ret


mycirclefillinner:
;	mov	al,[mapmasknow]
;	mov	ah,[bitmasknow]
;	push	ax

	mov	ax,[viewY1]
	mov	si,ax
	mul	[gxbytes]
	mov	di,ax
	mov	cx,[viewY2]
	inc	cx
	sub	cx,si
	my_shl	si,2			;4bytes/line
	add	si,[txttop]

mycirclefill10:
	mov	ax,[si]
	cmp	ax,8000h
	je	mycirclefill50		;no line

	mov	[gX1],ax
	mov	dx,ax
	dec	ax
	sub	ax,[si+2]
	neg	ax
	cmp	ax,0
	jle	mycirclefill50

	mov	[linelength],ax
	mov	ax,dx
	my_shr	ax,3
	add	ax,di
	mov	[gadr],ax
	and	dl,7
	mov	[goff],dl

	push	cx
	push	si
	push	di

	cmp	[tilelength],0
	jne	mycirclefilltile

	call	linesubX
	jmps	mycirclefill40
mycirclefilltile:
	call	linesubXtile
	mov	ah,_read1write3
	call	readwritemode

mycirclefill40:
	pop	di
	pop	si
	pop	cx
mycirclefill50:
	add	di,[gxbytes]
	add	si,4		;4bytes/line

	myloop	mycirclefill10

;	pop	ax
;	mov	si,ax
;	call	bitmask
;	mov	ax,si
;	mov	ah,al
;	call	mapmask
	ret


;
;*
;
myellipse:
	mov	[paintflg],0
myellipsein:
	call	gregnormal
	push	es
	mov	ax,_gramseg
	mov	es,ax
	call	myellipsemain
	pop	es
	jmp	weakgregnormal	;call & ret

;
;*
;
myellipsefill:
	;draw ellipse and fill inside

	push	ds
	push	es

	mov	[paintflg],-1
	call	gregnormal

	mov	ax,graphworkseg		;save data
	add	ax,data
	mov	es,ax
	mov	si,[txttop]
	mov	di,0
	mov	cx,[viewY2]		;2words/line
	inc	cx
	my_shl	cx,1
	rep	movsw

	mov	ax,data			;fill work by 8000h
	mov	es,ax
	mov	di,[txttop]
	mov	cx,[viewY2]		;2words/line
	inc	cx
	my_shl	cx,1
	mov	ax,8000h
	rep	stosw

	mov	ax,_gramseg
	mov	es,ax
	call	myellipsemain

	mov	ah,[paintcolor]
	call	setreset
	call	mycirclefillinner

	mov	ax,data
	mov	es,ax
	mov	ax,graphworkseg		;restore data
	add	ax,data
	mov	ds,ax
	mov	si,0
	mov	di,es:[txttop]
	mov	cx,es:[viewY2]		;2words/line
	inc	cx
	my_shl	cx,1
	rep	movsw

	pop	es
	pop	ds
	jmp	weakgregnormal	;call & ret



myellipsenot:
	ret

myellipsemain:
	mov	cx,[radiusX]
	mov	ax,[centerX]
	add	ax,cx
	cmp	ax,[viewX1]
	jl	myellipsenot	;out of range
	sub	ax,cx
	sub	ax,cx
	cmp	ax,[viewX2]
	jg	myellipsenot
	mov	dx,[radiusY]
	mov	ax,[centerY]
	add	ax,dx
	cmp	ax,[viewY1]
	jl	myellipsenot	;out of range
	sub	ax,dx
	sub	ax,dx
	cmp	ax,[viewY2]
	jg	myellipsenot

	mov	ah,[gcolor]
	call	setreset

	mov	si,[centerbaseadr]

	mov	cx,[radiusX]
	mov	dx,[radiusY]
	cmp	cx,dx
	ja	myellipseXlonger
	jb	myellipseYlonger

	mov	[radius],cx
	jmp	myellipseXYequal	;goto circle

myellipseXlonger:
	xor	ax,ax
	div	cx
	mov	[radiusratio],ax

	mov	bx,cx
	mov	[gX],bx
	mov	ax,0
	mov	[gYpoint],8000h
	mov	[gY],ax
	mov	dx,0		;dx = diff = x^2+y^2-r^2

	call	myellipsesub

	;compute only 1/8 circle: i.e. while y <= x

myellipseLP:
	cmp	ax,bx
	jae	myellipseNext

	mov	cx,ax
	shl	cx,1
	inc	cx
	add	dx,cx		;diff += 2y+1
	jle	ellipse120

	cmp	dx,bx
	jb	ellipse120

	mov	cx,bx
	shl	cx,1
	dec	cx		;cx = 2x-1
	sub	dx,cx		;diff += 2y+1-2x+1

	dec	bx
	mov	[gX],bx		;new x = old x -1
ellipse120:
	inc	ax
	mov	di,[radiusratio]
	add	[gYpoint],di
	adc	[gY],0
	call	myellipsesub
	jmp	myellipseLP

	;compute next 1/8 circle: i.e. while 0 < x < y 
myellipseNext:

myellipseLP2:
	or	bx,bx
	jz	ellipseret

	mov	cx,bx
	shl	cx,1
	dec	cx
	sub	dx,cx		;diff -= 2x-1
	jge	myellipse170	;new y = old y

	mov	cx,ax
	neg	cx
	cmp	dx,cx
	jge	myellipse170

	shl	cx,1
	dec	cx		;cx = 2y+1
	sub	dx,cx		;diff += 2y+1-2x+1
	inc	ax		;new y = old y + 1
	mov	di,[radiusratio]
	add	[gYpoint],di
	adc	[gY],0
myellipse170:
	dec	bx
	mov	[gX],bx

	call	myellipsesub
	jmp	myellipseLP2

ellipseret:
	ret

myellipseYlonger:
	xchg	cx,dx
	mov	bx,dx
	xor	ax,ax
	div	cx
	mov	[radiusratio],ax

	mov	[gXpoint],8000h
	mov	[gX],bx
	mov	bx,cx
	mov	ax,0
	mov	[gY],ax
	mov	dx,0		;dx = diff = x^2+y^2-r^2

	call	myellipsesub

	;compute only 1/8 circle: i.e. while y <= x

myellipseLPY:
	cmp	ax,bx
	jae	myellipseNextY

	mov	cx,ax
	shl	cx,1
	inc	cx
	add	dx,cx		;diff += 2(old)y+1
	jle	ellipse220
	cmp	dx,bx
	jb	ellipse220

	mov	cx,bx
	shl	cx,1
	dec	cx		;cx = 2x-1
	sub	dx,cx

	dec	bx
	mov	di,[radiusratio]
	sub	[gXpoint],di
	sbb	[gX],0
ellipse220:
	inc	ax
	mov	[gY],ax		;new y
	call	myellipsesub
	jmp	myellipseLPY

	;compute next 1/8 circle: i.e. while 0 < x < y 
myellipseNextY:

myellipseLP2Y:
	or	bx,bx
	jz	ellipseretY

	mov	cx,bx
	shl	cx,1
	dec	cx
	sub	dx,cx		;diff -= 2x-1
	jge	ellipse270	;new y = old y

	mov	cx,ax
	neg	cx
	cmp	dx,cx
	jge	ellipse270	;new y = old y

	shl	cx,1
	dec	cx		;cx = 2y+1
	sub	dx,cx		;diff += 2y+1-2x+1
	inc	ax		;new y = old y + 1
	mov	[gY],ax
ellipse270:
	dec	bx		;new x = old x - 1
	mov	di,[radiusratio]
	sub	[gXpoint],di
	sbb	[gX],0

	call	myellipsesub
	jmp	myellipseLP2Y

ellipseretY:
	ret


myellipsesub:
	push	ax
	push	bx
	push	dx
	cmp	[paintflg],0
	jne	myellipsefillsub
;myellipsesubin:
	call	circlesubsub
	pop	dx
	pop	bx
	pop	ax
	ret


myellipsefillsub:
	call	circlefillmem
	pop	dx
	pop	bx
	pop	ax
	ret


sqrt_dxax:			;inp: dx:ax, out:ax
	mov	di,dx
	mov	si,ax

	xor	bx,bx		;bx=answer
	mov	cx,8000h	;cx=width
sqrt20:
	add	bx,cx
	mov	ax,bx
	mul	ax
	sub	ax,si
	sbb	dx,di
	jb	sqrt50
	ja	sqrt40
	or	ax,ax
	jz	sqrt100
sqrt40:
	sub	bx,cx
sqrt50:
	shr	cx,1
	jnz	sqrt20
sqrt100:
	mov	ax,bx
	ret


letoncircle:
	mov	[dirX],0
	mov	ax,[gX]
	or	ax,ax
	jz	oncircle10
	mov	[dirX],1
	jns	oncircle10
	neg	ax
	mov	[dirX],-1
oncircle10:
	mov	[gX],ax
	mov	[absX],ax

	mov	[dirY],0
	mov	ax,[gY]
	or	ax,ax
	jz	oncircle20
	mov	[dirY],1
	jns	oncircle20
	neg	ax
	mov	[dirY],-1
oncircle20:
	mov	[gY],ax
	mov	[absY],ax

	mov	ax,[gX]
	shl	ax,1
	mul	[radius]
	mov	[gX],dx

	mov	ax,[gY]
	shl	ax,1
	mul	[radius]
	mov	[gY],dx

	;([gX],[gY]) is a candidate

oncircle50:
	mov	ax,[gX]
	mul	ax
	mov	bx,ax
	mov	cx,dx
	mov	ax,[gY]
	mul	ax
	add	bx,ax
	adc	cx,dx
	mov	ax,[radius]
	mul	ax
	sub	ax,bx
	sbb	dx,cx		;dx:ax = r^2 - (x^2 + y^2)
	jae	oncircle90

	neg	ax
	mov	dx,ax
	mov	ax,[gX]
	cmp	ax,[gY]
	jae	oncircle70

	mov	ax,[gY]
	cmp	ax,dx
	ja	oncircle220
	mov	ax,[gX]
	sub	ax,1
	jc	oncircle60
	mov	[gX],ax
	jmp	oncircle50
oncircle60:
	dec	[gY]
	jmp	oncircle50
oncircle70:
	cmp	ax,dx
	ja	oncircle120
	mov	ax,[gY]
	sub	ax,1
	jc	oncircle80
	mov	[gY],ax
	jmp	oncircle50
oncircle80:
	dec	[gX]
	jmp	oncircle50

oncircle90:
	mov	dx,ax		;diff

	mov	ax,[absX]
	cmp	ax,[absY]
	jb	oncircle200
oncircle100:
	mov	ax,[gX]
	dec	ax
oncircle110:
	inc	ax
	cmp	dx,ax
	jbe	oncircle120
	mov	cx,ax
	shl	cx,1
	inc	cx
	sub	dx,cx
	ja	oncircle110
	neg	dx
	cmp	dx,ax
	ja	oncircle120
	inc	ax
oncircle120:
	mul	[dirX]
	mov	[gX],ax
	mov	ax,[gY]
	mul	[dirY]
	mov	[gY],ax
oncircleret:
	ret

oncircle200:
	mov	ax,[gY]
	dec	ax
oncircle210:
	inc	ax
	cmp	dx,ax
	jbe	oncircle220
	mov	cx,ax
	shl	cx,1
	inc	cx
	sub	dx,cx
	ja	oncircle210
	neg	dx
	cmp	dx,ax
	ja	oncircle220
	inc	ax
oncircle220:
	mul	[dirY]
	mov	[gY],ax
	mov	ax,[gX]
	mul	[dirX]
	mov	[gX],ax
	jmp	oncircleret


sectormem:
	push	ax
	push	dx

sectormemY:
	mov	ax,[gY]
	mov	cx,[radiusratioY]
	jcxz	sectormemY10
	sal	ax,1
	imul	cx
	mov	ax,dx
sectormemY10:
	add	ax,[centerY]
	cmp	ax,[viewY1]
	jl	sectormemret
	cmp	ax,[viewY2]
	jg	sectormemret

	mov	[gY1],ax		;memo

	mov	ax,[gX]
	mov	cx,[radiusratioX]
	jcxz	sectormem5
	sal	ax,1
	imul	cx
	mov	ax,dx
sectormem5:
	or	ax,ax
	js	sectormemleft		;point on left hand side

sectormemright:
	add	ax,[centerX]
	cmp	ax,[viewX1]
	jl	sectormemret

	mov	si,ax			;x-position
	dec	ax
	mov	dx,[viewX2]
	cmp	ax,dx
	jg	sectormemright10
	mov	dx,ax
sectormemright10:
	mov	ax,[gY1]
	my_shl	ax,2
	mov	di,ax
	shl	ax,1
	add	ax,di		;12bytes/line
	add	ax,[txttop]
	mov	di,ax

	cmp	dx,[di+10]
	jae	sectormem40
	mov	[di+10],dx
sectormem40:
	jmps	sectormemsetpt

sectormemleft:
	add	ax,[centerX]
	cmp	ax,[viewX2]
	jg	sectormemret

	mov	si,ax		;x-position
	inc	ax
	mov	dx,[viewX1]
	cmp	ax,dx
	jl	sectormemleft10
	mov	dx,ax
sectormemleft10:
	mov	ax,[gY1]
	my_shl	ax,2
	mov	di,ax
	shl	ax,1
	add	ax,di		;12bytes/line
	add	ax,[txttop]
	mov	di,ax

	cmp	dx,[di]
	jle	sectormem30
	mov	[di],dx
sectormem30:

sectormemsetpt:
	cmp	si,[viewX1]
	jl	sectormemret
	cmp	si,[viewX2]
	jg	sectormemret

	mov	ax,[gY1]
	mul	[gxbytes]
	mov	di,ax

	mov	cx,si
	my_shr	si,3
	add	di,si
	and	cl,07h
	mov	al,80h
	shr	al,cl
	and	es:[di],al

sectormemret:
	pop	dx
	pop	ax
	ret


;
;*
;
myarcsub:
	cmp	[paintflg],0
	jne	sectormem

	push	ax
	push	dx

	mov	ax,[gY]
	mov	cx,[radiusratioY]
	jcxz	myarcsub10
	sal	ax,1
	imul	cx
	mov	ax,dx
myarcsub10:
	add	ax,[centerY]
	cmp	ax,[viewY1]
	jl	myarcsubret
	cmp	ax,[viewY2]
	jg	myarcsubret

	mul	[gxbytes]
	mov	di,ax

	mov	ax,[gX]
	mov	cx,[radiusratioX]
	jcxz	myarcsub20
	sal	ax,1
	imul	cx
	mov	ax,dx
myarcsub20:
	add	ax,[centerX]
	cmp	ax,[viewX1]
	jl	myarcsubret
	cmp	ax,[viewX2]
	jg	myarcsubret

	mov	cx,ax
	my_shr	ax,3
	add	di,ax
	and	cl,07h
	mov	al,80h
	shr	al,cl
	and	es:[di],al


myarcsubret:
	pop	dx
	pop	ax
	ret



myarc:
	;draw arc
	;inp: ([centerX],[centerY]), [radius]
	;     ([gX1],[gY1])-([gX2,gY2])
	;     [palette]

	call	gregnormal
	push	es
	mov	ax,_gramseg
	mov	es,ax
	call	myarcmain
	pop	es
	jmp	weakgregnormal	;call & ret


mysector:
	;draw sector
	;inp: ([centerX],[centerY]), [radius]
	;     ([gX1],[gY1])-([gX2,gY2])
	;     [palette]

	call	gregnormal
	push	es
	mov	ax,_gramseg
	mov	es,ax
	call	myarcmain
	mov	cx,[centerX]
	mov	[gX1],cx
	mov	dx,[centerY]
	mov	[gY1],dx
	mov	ax,[arcX1]
	add	ax,cx
	mov	[gX2],ax
	mov	ax,[arcY1]
	add	ax,dx
	mov	[gY2],ax
	call	mylinesub
	mov	cx,[centerX]
	mov	[gX1],cx
	mov	dx,[centerY]
	mov	[gY1],dx
	mov	ax,[arcX2]
	add	ax,cx
	mov	[gX2],ax
	mov	ax,[arcY2]
	add	ax,dx
	mov	[gY2],ax
	call	mylinesub
	pop	es
	jmp	weakgregnormal	;call & ret


;
;*
;
sector:
	call	myarc
	push	[gX1]
	push	[gY1]
	push	[gX2]
	push	[gY2]
	mov	ax,[arcX1]
	add	ax,[centerX]
	mov	[gX1],ax
	mov	ax,[arcY1]
	add	ax,[centerY]
	mov	[gY1],ax
	mov	ax,[centerX]
	mov	[gX2],ax
	push	ax
	mov	ax,[centerY]
	mov	[gY2],ax
	push	ax
	call	mylinesub
	mov	ax,[arcX2]
	add	ax,[centerX]
	mov	[gX1],ax
	mov	ax,[arcY2]
	add	ax,[centerY]
	mov	[gY1],ax
	pop	[gY2]
	pop	[gX2]
	call	mylinesub
	pop	[gY2]
	pop	[gX2]
	pop	[gY1]
	pop	[gX1]
	ret


letonellipse:
	mov	ax,[gX]
	or	ax,ax
	jge	letonell10
	neg	ax
letonell10:
	mov	si,ax
	mul	[radiusY]
	mov	bx,ax
	mov	cx,dx
	mov	ax,[gY]
	or	ax,ax
	jge	letonell20
	neg	ax
letonell20:
	or	si,ax
	jz	letonellret		;both = 0
	mul	[radiusX]
	or	dx,dx
	jnz	letonell30
	or	cx,cx
	jnz	letonell30
	mov	dh,dl
	mov	dl,ah
	mov	ah,al
	mov	ch,cl
	mov	cl,bh
	mov	bh,bl
letonell30:
	cmp	dx,2000h
	jae	letonell40
	cmp	cx,2000h
	jae	letonell40
	shl	ax,1
	rcl	dx,1
	shl	bx,1
	rcl	cx,1
	jmp	letonell30
letonell40:
	cmp	[gX],0
	jge	letonell50
	neg	cx
letonell50:
	mov	[gX],cx			;bx
	cmp	[gY],0
	jge	letonell60
	neg	dx
letonell60:
	mov	[gY],dx			;ay

	mov	ax,[gX]
	imul	ax
	mov	bx,ax
	mov	cx,dx
	mov	ax,[gY]
	imul	ax
	add	ax,bx
	adc	dx,cx			;dx:ax = x^2 + (ay/b)^2
	call	sqrt_dxax
	mov	bx,ax
	mov	ax,[gX]
	imul	[radiusX]
	idiv	bx
	mov	[gX],ax
	mov	ax,[gY]
	imul	[radiusY]
	idiv	bx
	mov	[gY],ax
letonellret:
	ret


;
; * clear view port
;

myclearviewarea:
	;* clears the view area

	call	gregnormal

	mov	ah,0ffh
	call	enablesetreset

	mov	ah,0h
	call	setreset

	mov	ax,[viewX2]
	inc	ax
	sub	ax,[viewX1]
	mov	[linelength],ax

gscrollclearscreen:
	mov	bx,[viewY1]
	mov	cx,[viewY2]
	sub	cx,bx
	inc	cx

	push	es
	mov	ax,_gramseg
	mov	es,ax

	mov	ax,[viewX1]
	mov	[gX],ax
	mov	[gY],bx

	mov	ah,[backcolor]
	call	setreset
gclspart10:
	push	cx
	call	Hline
	inc	[gY]
	pop	cx
	myloop	gclspart10
	pop	es
	jmp	weakgregnormal	;call & ret


;
;*
;

_paintstackunit	equ	10
addressleft	equ	0
addressright	equ	2
addressleft0	equ	4
addressright0	equ	6
offsetboth	equ	8
offsetboth0	equ	9

_paintstack2unit	equ	5
addressleft2	equ	0
addressright2	equ	2
offsetboth2	equ	4


getdirection	macro	reg,adr
	mov	reg,adr
	and	reg,00001000b		;4th bit is reserved
endm

putdirection_usingAX	macro	adr,val
	mov	al,val
	and	al,1
	my_shl	al,3
	mov	ah,adr
	and	ah,11110111b
	or	al,ah
	mov	adr,al
endm

getleft	macro	reg, adr
	mov	reg,adr
	and	reg,11100000b
	my_rol	reg,3
endm

getright	macro	reg, adr
	mov	reg,adr
	and	reg,00000111b
endm

putleft_usingAX	macro	adr,reg
	mov	al,reg
	my_ror	al,3
	mov	ah,adr
	and	ah,00011111b
	or	al,ah
	mov	adr,al
endm

putright_usingAX	macro	adr,reg
	mov	al,reg
	mov	ah,adr
	and	ah,11111000b
	or	al,ah
	mov	adr,al
endm


getleftend:
	;inp : di = address, cl = pixel offset of current
	;out : di = address, cl = pixel offset of leftend

	;for the current byte

	mov	al,80h
	shr	al,cl
	mov	ch,es:[di]		;current byte(read mode 1)
	test	ch,al
	jnz	getleftonborder		;on border
	mov	dx,di
	sub	dx,[paintbaseadr]
	cmp	dx,[viewX1address]
	je	getleft200
	dec	al
	not	al			;al = mask to cut right
	shl	al,1
	and	al,ch
	jz	getleft30		;none in this byte

	mov	cl,9
getleft10:
	dec	cl
	shr	al,1
	jnc	getleft10
					;no case of cl=8
getleftret:
	clc				;di = address, cl = pixel offset
	ret
getleftonborder:
	stc
	ret


getleft30:
	dec	di
	mov	cx,di
	sub	cx,[paintbaseadr]	;current is (cx-1)-th from left
	mov	dx,[viewX1address]
	sub	cx,dx			;cx = bytes in left 
					;excludes current & last
	jz	getleft110

	;for intermediate bytes

getleft50:
	mov	al,es:[di]
	or	al,al
	jnz	getleft70
	dec	di
	myloop	getleft50
	jmps	getleft110

getleft70:
	mov	cl,9
getleft80:
	dec	cl
	shr	al,1
	jnc	getleft80
	cmp	cl,8
	jne	getleftret
	inc	di			;start from next byte?
	mov	cl,0
	jmp	getleftret

	;for leftend byte

getleft100:
	mov	cl,[viewX1pixel]
	jmp	getleftret

getleft110:
	mov	al,es:[di]
	or	al,al
	jz	getleft100

getleft170:
	mov	cl,9
getleft180:
	dec	cl
	shr	al,1
	jnc	getleft180
	cmp	cl,8
	je	getleft190
	cmp	cl,[viewX1pixel]
	jae	getleftret
	jmp	getleft100
getleft190:
	inc	di
	mov	cl,0
	jmp	getleftret

getleft200:
	dec	al
	not	al			;al = mask to cut right
	shl	al,1
	and	al,ch
	jz	getleft100		;none in this byte
	jmp	getleft170


linetorightend:
	;line for paint with palette
	;current pixel must NOT be on border

	cmp	[tilelength],0
	jne	filltorightend

	mov	di,[bx+addressleft]
	getleft	cl,[bx+offsetboth]
	mov	ax,0100h
	shr	ax,cl
	dec	ax
	mov	ah,al			;al = ah = mask to cut left
	mov	ch,es:[di]		;current byte(read mode 1)
	mov	dx,di
	sub	dx,[paintbaseadr]
	cmp	dx,[viewX2address]
	je	linetoright20		;already on the viewX2
	and	al,ch
	jz	linetoright30		;no boundary in the leftend byte

	;boundary on the leftend byte

	mov	cl,-2
linetoright10:
	inc	cl
	shl	al,1
	jnc	linetoright10

linetoright15:
	mov	al,80h
	sar	al,cl			;cl>=0 because current pixel is 
					;not on border
	and	al,ah			;ah = mask to cut left
 	mov	es:[di],al
linetorightret:
	ret

linetoright20:
	and	al,ch
	jnz	linetoright24		;find a boundary
linetoright22:
	mov	cl,[viewX2pixel]
	jmp	linetoright15
linetoright24:
	mov	cl,-2
linetoright26:
	inc	cl
	shl	al,1
	jnc	linetoright26
	cmp	cl,[viewX2pixel]
	jbe	linetoright15
	jmp	linetoright22

	;for intermediate byte

linetoright30:
	mov	es:[di],ah		;set leftendbyte
	inc	di

	mov	ax,di
	sub	ax,[paintbaseadr]
	mov	cx,[viewX2address]
	sub	cx,ax			;cx = bytes in right
					;excludes current & last
	jz	linetoright110		;next byte is rightend

	mov	al,0ffh
linetoright50:
	mov	ah,es:[di]		;read mode 1
	or	ah,ah
	jnz	linetoright60		;find a boundary
	stosb				;paint this byte
	myloop	linetoright50
	jmp	linetoright110

linetoright60:
	shl	ah,1
	jnc	linetoright70
	dec	di
	mov	cl,7			;paint already
	jmp	linetorightret

linetoright70:
	mov	cl,-1
linetoright80:
	inc	cl
	shl	ah,1
	jnc	linetoright80
linetoright90:
	mov	al,80h
	sar	al,cl
	mov	es:[di],al
	jmp	linetorightret

	;for right end byte

linetoright110:
	mov	ah,es:[di]		;read mode 1
	or	ah,ah
	jnz	linetoright170		;find a boundary
linetoright130:
	mov	cl,[viewX2pixel]
	jmp	linetoright90

linetoright170:
	shl	ah,1
	jnc	linetoright180
	dec	di
	mov	cl,7
	jmp	linetorightret		;paint already

linetoright180:
	mov	cl,-1
linetoright190:
	inc	cl
	shl	ah,1
	jnc	linetoright190
	cmp	cl,[viewX2pixel]
	jbe	linetoright90
	mov	cl,[viewX2pixel]
	jmp	linetoright90


filltorightend:
	;line for paint with tiling
	;current pixel must NOT be on border

	push	bx
	push	si

;	mov	ah,0fh
;	call	mapmask

;	mov	ah,_read1write3
;	call	readwritemode

;	mov	ah,0fh
;	call	colordontcare

;	mov	ah,[bordercolor]
;	call	colorcompare

;	mov	ah,0ffh
;	call	bitmask

	mov	di,[bx+addressleft]
	getleft	cl,[bx+offsetboth]

	mov	[gadr],di
	mov	[goff],cl

	mov	bx,8			;bx = linelength
	sub	bl,cl

	mov	ax,0100h
	shr	ax,cl
	dec	ax
	mov	ah,al			;al = ah = mask to cut left
	mov	ch,es:[di]		;current byte(read mode 1)
	mov	dx,di
	sub	dx,[paintbaseadr]
	cmp	dx,[viewX2address]
	je	filltoright20		;already on the viewX2

	and	al,ch
	jz	filltoright30		;no boundary in the leftend byte

	sub	bx,8

	;ended by boundary

filltorightboundend:
	dec	bx
filltorightlp1:
	inc	bx
	shl	al,1
	jnc	filltorightlp1
filltorightret:
	mov	[linelength],bx

	call	linesubXtile

	mov	ah,0fh
	call	mapmask

	mov	ah,_read1write3
	call	readwritemode

;	mov	ah,0fh
;	call	colordontcare

;	mov	ah,[bordercolor]
;	call	colorcompare

	mov	ah,0ffh
	call	bitmask

	mov	di,[gadr]
	mov	ax,[linelength]
	dec	ax
	add	al,[goff]
	adc	ah,0
	mov	cl,al
	and	cl,7
	my_shr	ax,3
	add	di,ax

	pop	si
	pop	bx
	ret

	;1st byte is viewend
filltoright20:
	and	al,ch

	;on viewend

filltorightviewend:
	mov	cl,[viewX2pixel]
	mov	ah,80h
	sar	ah,cl			;mask to cut right
	and	al,ah
	jnz	filltorightboundend		;find a boundary
;	mov	cl,[viewX2pixel]
	xor	ch,ch
	inc	cx
	add	bx,cx
	jmp	filltorightret

	;for intermediate byte

filltoright30:
	inc	di

	mov	ax,di
	sub	ax,[paintbaseadr]
	mov	cx,[viewX2address]
	sub	cx,ax			;cx = bytes in right
					;excludes last
	jz	filltoright110		;cx = 0 means rightend

filltoright50:
	mov	al,es:[di]		;read mode 1
	or	al,al
	jnz	filltorightboundend	;find a boundary
	inc	di
	add	bx,8
	myloop	filltoright50

	;for right end byte

filltoright110:
	mov	al,es:[di]		;read mode 1
	jmp	filltorightviewend


getstart:
	;inp: di=address, cl=pixel offset of current
	;out: di=address, cl=pixel offset of 
	;        left most pixel connected to last line

	mov	ax,di
	sub	ax,[paintbaseadr]
	cmp	ax,[viewX2address]

	ja	getstartnone
	je	getstart20		;right end

	mov	ax,00ffh
	ror	ax,cl			;ah = mask to set left
	mov	al,es:[di]		;current byte(read mode 1)
	or	al,ah
	cmp	al,0ffh
	je	getstart30		;no target pt in this byte

	mov	ch,cl			;memo cl
	mov	cl,-1
getstart10:
	inc	cl
	shl	al,1
	jc	getstart10
	cmp	cl,ch
	jne	getstartret		;find new start pixel
	call	getleftend		;if current pixel is ok
					;then find start
getstartret:
	mov	ax,di
	sub	ax,[paintbaseadr]
	push	ax
	mov	ax,[si+addressright]
	xor	dx,dx
	div	[gxbytes]
	pop	ax
	cmp	ax,dx
	ja	getstartnone		;over leftend
	jb	getstartok
	getright al,[si+offsetboth]
	cmp	cl,al
	ja	getstartnone		;over leftend
getstartok:
	clc
	ret
getstartnone:
	stc				;all filled by border color
	ret

getstart20:
	mov	ax,00ffh
	ror	ax,cl			;ah = mask to set left
	mov	cl,7
	sub	cl,[viewX2pixel]
	mov	al,1
	shl	al,cl
	dec	al			;al = mask to set right
	or	al,ah

	or	al,es:[di]		;current byte(read mode 1)
	cmp	al,0ffh
	je	getstartnone		;no target pt on this line

	mov	cl,-1
getstart22:
	inc	cl
	shl	al,1
	jc	getstart22
	jmp	getstartret

getstart30:
	inc	di
	mov	ax,di
	sub	ax,[paintbaseadr]
	mov	cx,[viewX2address]
	sub	cx,ax			;cx = bytes in right 
					;excludes current & last
	jb	getstartnone		;already on the rightend
	je	getstart20		;check rightend, note: cl = 0
getstart50:
	mov	al,es:[di]		;read mode 1
	cmp	al,0ffh
	jne	getstart55
	inc	di
	myloop	getstart50
	jmp	getstart20		;check rightend, note: cl=0

getstart55:
	mov	cl,-1
getstart60:
	inc	cl
	shl	al,1
	jc	getstart60
	jmp	getstartret


search_dicl:
	;search di:cl if on the interval

	push	si
	mov	si,[paintbuffertop]
searchdicl10:
	cmp	di,[si+addressleft]
	jb	searchdicl20
	ja	searchdicl15
	getleft	al,[si+offsetboth]
	cmp	cl,al
	jb	searchdicl20
	je	searchdiclyes
searchdicl15:
	cmp	di,[si+addressright]
	ja	searchdicl20
	jb	searchdiclyes
	getright	al,[si+offsetboth]
	cmp	cl,al
	jbe	searchdiclyes

searchdicl20:
	cmp	di,[si+addressleft0]
	jb	searchdicl30
	ja	searchdicl25
	getleft	al,[si+offsetboth0]
	cmp	cl,al
	jb	searchdicl30
	je	searchdiclyes2
searchdicl25:
	cmp	di,[si+addressright0]
	ja	searchdicl30
	jb	searchdiclyes2
	getright	al,[si+offsetboth0]
	cmp	cl,al
	jbe	searchdiclyes2

searchdicl30:
	add	si,_paintstackunit
	cmp	si,bx
	jb	searchdicl10

	mov	si,bp
searchdicl40:
	add	si,_paintstack2unit
	cmp	si,[paintbufferover]
	jae	searchdiclno
	cmp	di,[si+addressleft2]
	jb	searchdicl40
	ja	searchdicl35
	getleft	al,[si+offsetboth2]
	cmp	cl,al
	jb	searchdicl40
	je	searchdiclyes3
searchdicl35:
	cmp	di,[si+addressright2]
	ja	searchdicl40
	jb	searchdiclyes3
	getright	al,[si+offsetboth2]
	cmp	cl,al
	jbe	searchdiclyes3
	jmp	searchdicl40

searchdiclno:
	pop	si
	clc
	ret
searchdiclyes:
	mov	di,[si+addressright]
	getright cl,[si+offsetboth]
	mov	al,1		;al = 1 = met other task
	pop	si
	stc
	ret
searchdiclyes2:
	mov	di,[si+addressright0]
	getright cl,[si+offsetboth0]
	xor	al,al		;al = 0 = not met other task
	pop	si
	stc
	ret
searchdiclyes3:
	mov	di,[si+addressright2]
	getright cl,[si+offsetboth2]
	mov	al,1		;al = 1 = met other task
	pop	si
	stc
	ret


makenewtask:
	mov	[bx+addressleft],di
	putleft_usingAX	[bx+offsetboth],cl
	call	linetorightend
	mov	[bx+addressright],di
	putright_usingAX	[bx+offsetboth],cl
	mov	ax,[si+addressleft]
	mov	[bx+addressleft0],ax
	mov	ax,[si+addressright]
	mov	[bx+addressright0],ax
	mov	al,[si+offsetboth]
	mov	[bx+offsetboth0],al
	add	bx,_paintstackunit
makenewtask100:
	add	bx,_paintstackunit
	cmp	bx,bp
	ja	makenewtaskerr
	sub	bx,_paintstackunit
	clc
	ret
makenewtaskerr:
	stc
	ret

makenewmemo:
	mov	ax,[si+addressleft]
	mov	[bp+addressleft2],ax
	mov	ax,[si+addressright]
	mov	[bp+addressright2],ax
	mov	al,[si+offsetboth]
	mov	[bp+offsetboth2],al
	sub	bp,_paintstack2unit
	jmp	makenewtask100

calc_baseadr:
	mov	ax,di
	xor	dx,dx
	div	[gxbytes]
	mov	ax,di
	sub	ax,dx
	mov	[paintbaseadr],ax
	ret


mypaint:
	;inp: ([gX],[gY]), [bordercolor], [paintcolor]

	call	gregnormal
	push	es
	mov	ax,_gramseg
	mov	es,ax
	push	bp

	mov	ax,[calcsp]
	sub	ax,2
	cmp	[tilelength],0
	je	mypaint5
	sub	ax,UNITBYTE
mypaint5:
	mov	[paintbufferover],ax
	mov	ax,[calcsp_limit]
	mov	[paintbuffertop],ax

	mov	ah,_read1write3
	call	readwritemode

	mov	ah,0fh
	call	colordontcare

	mov	ah,[bordercolor]
	call	colorcompare

	mov	ah,[paintcolor]
	call	setreset

	call	getadr

	mov	bx,[paintbuffertop]
	mov	[bx+addressleft],di
	putleft_usingAX	[bx+offsetboth],cl
	call	calc_baseadr
	call	getleftend
	jc	paintout		;if on border
	mov	[bx+addressleft],di
	putleft_usingAX	[bx+offsetboth],cl
	call	linetorightend		;draw 1st line
	mov	[bx+addressright],di
	putright_usingAX [bx+offsetboth],cl
	putdirection_usingAX [bx+offsetboth],0	;go upper

	mov	si,bx
	add	bx,_paintstackunit

	mov	di,[si+addressleft]
	sub	di,[gxbytes]
	jb	mypaintin
	getleft	cl,[si+offsetboth]
	cmp	di,[viewY1startadr]
	jb	mypaintin
	call	calc_baseadr
	call	getstart
	jc	mypaintin
	mov	[bx+addressleft],di
	putleft_usingAX	[bx+offsetboth],cl
	mov	[si+addressleft0],di
	putleft_usingAX	[si+offsetboth0],cl
	call	linetorightend		;draw 2nd line
	mov	[bx+addressright],di
	putright_usingAX [bx+offsetboth],cl
	putdirection_usingAX [bx+offsetboth],1	;to lower
	mov	[si+addressright0],di
	putright_usingAX [si+offsetboth0],cl

	mov	ax,[si+addressleft]
	mov	[bx+addressleft0],ax
	mov	ax,[si+addressright]
	mov	[bx+addressright0],ax
	mov	al,[si+offsetboth]
	mov	[bx+offsetboth0],al

	add	bx,_paintstackunit
	mov	bp,[paintbufferover]
	sub	bp,_paintstack2unit

mypaintin:
paintlp10:
	mov	si,[paintbuffertop]
	cmp	bx,si
	jbe	paintout
paintlp20:
	push	si
	call	paintsub
	pop	si
	jc	paintout
	add	si,_paintstackunit
	cmp	si,bx
	jb	paintlp20
	jmp	paintlp10
paintout:
	pop	bp
	pop	es
	jmp	weakgregnormal	;call & ret


paintsub:
	mov	[metothertask],0
	getdirection	al,[si+offsetboth]
	or	al,al
	jnz	paintsublower

paintsubupper:
	mov	di,[si+addressleft]
	add	di,[gxbytes]
	jc	paintsubup100
	cmp	di,[viewY2overadr]
	jae	paintsubup100		;cannot generate upper task
	call	calc_baseadr
	mov	[paintbaseadr],ax
	getleft	cl,[si+offsetboth]
paintsubup20:
	call	getstart
	jc	paintsubup100
	call	search_dicl
	jnc	paintsubup25
	or	[metothertask],al
	jmp	paintsubup30
paintsubup25:
	putdirection_usingAX [bx+offsetboth],0
	call	makenewtask
	jc	paintsuberrret
paintsubup30:
	inc	cl
	and	cl,7
	jnz	paintsubup40
	inc	di
paintsubup40:
	jmp	paintsubup20

paintsubup100:
	mov	di,[si+addressleft]
	sub	di,[gxbytes]
	jb	paintsubup200
	cmp	di,[viewY1startadr]
	jb	paintsubup200
	call	calc_baseadr
	getleft	cl,[si+offsetboth]
paintsubup120:
	call	getstart
	jc	paintsubup200
	call	search_dicl
	jnc	paintsubup125
	or	[metothertask],al
	jmp	paintsubup130
paintsubup125:
	putdirection_usingAX [bx+offsetboth],1
	call	makenewtask
	jc	paintsuberrret
paintsubup130:
	inc	cl
	and	cl,7
	jnz	paintsubup120
	inc	di
	jmp	paintsubup120

paintsubup200:
	cmp	[metothertask],0
	je	paintsubup210
	call	makenewmemo
	jc	paintsuberrret
paintsubup210:
	sub	bx,_paintstackunit
	mov	di,si
	mov	si,bx
	mov	cx,_paintstackunit
	push	es
	push	ds
	pop	es
	rep	movsb			;replace old by new
	pop	es
paintsubret:
	clc
	ret

paintsuberrret:
	stc
	ret

paintsublower:
	mov	di,[si+addressleft]
	sub	di,[gxbytes]
	jb	paintsublow100
	cmp	di,[viewY1startadr]
	jb	paintsublow100
	call	calc_baseadr
	getleft	cl,[si+offsetboth]
paintsublow20:
	call	getstart
	jc	paintsublow100
	call	search_dicl
	jnc	paintsublow25
	or	[metothertask],al
	jmp	paintsublow30
paintsublow25:
	putdirection_usingAX [bx+offsetboth],1
	call	makenewtask
	jc	paintsuberrret
paintsublow30:
	inc	cl
	and	cl,7
	jnz	paintsublow40
	inc	di
paintsublow40:
	jmp	paintsublow20

paintsublow100:
	mov	di,[si+addressleft]
	add	di,[gxbytes]
	jc	paintsubup200
	cmp	di,[viewY2overadr]
	jae	paintsubup200
	call	calc_baseadr
	getleft	cl,[si+offsetboth]
paintsublow110:
	inc	cl
	and	cl,7
	jnz	paintsublow120
	inc	di
paintsublow120:
	call	getstart
	jc	paintsubup200
	call	search_dicl
	jnc	paintsublow125
	or	[metothertask],al
	jmp	paintsublow110
paintsublow125:
	putdirection_usingAX [bx+offsetboth],0
	call	makenewtask
	jc	paintsuberrret
	jmp	paintsublow110


mygetgrapherr:
	stc
	ret

mygetgraph:
	;inp: ([bX1],[bY1],[bX2],[bY2])
	;es:di = out [calcsp]

	call	gregnormal

	mov	ax,[bY2]
	cmp	ax,[viewY2]
	jbe	myget10
	mov	ax,[viewY2]
	mov	[bY2],ax
myget10:
	inc	ax
	sub	ax,[bY1]
	jbe	mygetgrapherr

	mov	cx,ax		;cx=lines
	mov	bx,[bX2]
	cmp	bx,[viewX2]
	jbe	myget20
	mov	bx,[viewX2]
	mov	[bX2],bx
myget20:
	inc	bx
	sub	bx,[bX1]	;bx=width
	jbe	mygetgrapherr

	mov	ax,bx
	add	ax,7
	my_shr	ax,3		;bytes in 1 line on 1 plane
	xor	dl,dl
	mov	dh,[activeplane]
  rept	4
  	shr	dh,1
  	adc	dl,0
  endm
	mul	dx
	or	dx,dx
	jnz	mygetgrapherr
	mul	cx
	or	dx,dx
	jnz	mygetgrapherr
	cmp	ax,limitword*2-4
	ja	mygetgrapherr

	inc	ax
	shr	ax,1
	add	ax,2
	or	ah,stringmaskhigh
	mov	[di],ax		;set attribute
	mov	[di+2],bx	;x-size
	mov	[di+4],cx	;y-size
	add	di,6		;es:di = buffer

	;

	mov	ax,[bY1]
	mov	cx,[gxbytes]
	mul	cx
	mov	si,ax

	mov	ax,[bX2]
	mov	dx,[bX1]
	inc	ax
	sub	ax,dx
	add	ax,7
	my_shr	ax,3
	mov	[destXbytes],ax
	mov	bx,dx
	and	bx,7
	mov	[mygetbitoff],bl
	my_shr	dx,3
	add	si,dx

	mov	cx,[bY2]
	inc	cx
	sub	cx,[bY1]

	mov	ah,_read0write3
	call	readwritemode

	push	ds
	mov	ax,_gramseg
	mov	ds,ax

mygetmainlp:
	push	cx
	call	myget1line
	add	si,ss:[gxbytes]
	pop	cx
	myloop	mygetmainlp

	pop	ds
	call	weakgregnormal
	clc
	ret

myget1line:
	mov	bh,0		;bh for readmap
	mov	bl,ss:[activeplane]
	mov	cl,[mygetbitoff]
myget1lp:
	shr	bl,1
	jnc	myget1skip

	mov	ah,bh
	call	readmap

	mov	dx,[destXbytes]
myget1lp2:
	mov	ah,[si]
	inc	si
	mov	al,[si]
	shl	ax,cl
	mov	al,ah
	stosb
	dec	dx
	jnz	myget1lp2

	sub	si,[destXbytes]

myget1skip:
	inc	bh
	cmp	bh,4
	jb	myget1lp
	ret


myputerr:
	stc
	ret

myputgraph:
	;inp: ([bX1],[bY1])
	;ds:si = inp buffer
	;[si] word = x-size
	;[si+2] word = y-size
	;[si+4] -> data

	call	gregnormal

	mov	ax,[bX1]
	cmp	ax,[viewX2]
	ja	myputret	;do nothing

	mov	bx,ax		;bx = bX1
	mov	cl,8
	and	ax,7
	mov	[mygetbitoff],al
	sub	cl,al
	mov	dx,1
	shl	dx,cl
	dec	dx
	mov	[gscrollmask1],dl

	mov	ax,[si]		;get x-size
	add	ax,7
	my_shr	ax,3
	mov	[srcXbytes],ax	;source bytes/line/plane
	mov	dh,[activeplane]
	xor	dl,dl
  rept	4
  	shr	dh,1
  	adc	dl,0
  endm
	mul	dx
	mov	[srcallXbytes],ax

	lodsw			;get x-size
	dec	ax
	add	ax,bx
	mov	cx,ax
	and	cl,7
	mov	ch,80h
	sar	ch,cl
	mov	[gscrollmask2],ch
	mov	cx,ax		;ax = cx = bX2

	my_shr	bx,3
	my_shr	ax,3
	inc	ax
	sub	ax,bx
	mov	[destXbytes],ax	;dest bytes/line/plane

	mov	ax,[viewX2]
	cmp	ax,cx
	jae	myput10
	my_shr	ax,3
	inc	ax
	sub	ax,bx
	mov	[destXbytes],ax	;dest bytes/line/plane
	mov	[gscrollmask2],0ffh
myput10:
	mov	ax,[bY1]
	cmp	ax,[viewY2]
	ja	myputret	;do nothing

	mov	dx,[gxbytes]
	mul	dx
	add	ax,bx
	mov	di,ax		;top address

	push	es
	mov	ax,_gramseg
	mov	es,ax

	mov	ah,_read0write0
	call	readwritemode

	lodsw			;y-size
	mov	cx,ax
	add	ax,[bY1]
	sub	ax,[viewY2]
	jbe	myput20
	sub	cx,ax
myput20:
	mov	[myputlines],cx

	mov	bx,0001h		;bh for readmap, bl for mapmask
	mov	cl,[mygetbitoff]
myputmainlp:
	test	bl,[activeplane]
	jz	myputskip

	push	bx
	push	si
	push	di

	mov	ah,bh
	call	readmap

	mov	ah,bl
	call	mapmask

	call	myput1plane

	pop	di
	pop	si
	pop	bx
	add	si,[srcXbytes]		;top of next plane

myputskip:
	shl	bl,1
	inc	bh
	cmp	bh,4
	jb	myputmainlp

	pop	es
	jmp	weakgregnormal	;call & ret
myputret:
	ret


myput1plane:
	mov	bx,[destXbytes]

	;1st byte

	mov	ah,[gscrollmask1]
	dec	bx
	jz	myput1_50

	call	bitmask

	push	si
	push	di
	mov	dx,[myputlines]
myput1_10:
	mov	al,[si]
	shr	al,cl
	mov	ah,es:[di]		;dummy read
	mov	es:[di],al
	add	si,[srcallXbytes]
	add	di,[gxbytes]
	dec	dx
	jnz	myput1_10

	pop	di
	pop	si
	inc	si
	inc	di

	;intermediate bytes

	mov	ah,0ffh
	dec	bx
	jz	myput1_50		;if 2 bytes

	call	bitmask

	push	si
	push	di

	mov	dx,[myputlines]
myput1_20:
	push	bx
myput1_30:
	mov	ah,[si-1]
	lodsb
	shr	ax,cl
	mov	ah,es:[di]		;dummy read
	stosb
	dec	bx
	jnz	myput1_30
	pop	bx
	sub	si,bx
	add	si,[srcallXbytes]
	sub	di,bx
	add	di,[gxbytes]
	dec	dx
	jnz	myput1_20

	;last byte

	pop	di
	pop	si
	add	si,bx
	add	di,bx

	mov	ah,0ffh
myput1_50:
	and	ah,[gscrollmask2]
	call	bitmask

	mov	dx,[myputlines]
myput1_60:
	mov	ax,[si-1]	;mov	ah,[si-1]
	xchg	al,ah		;mov	al,[si]
	shr	ax,cl
	mov	ah,es:[di]		;dummy read
	mov	es:[di],al
	add	si,[srcallXbytes]
	add	di,[gxbytes]
	dec	dx
	jnz	myput1_60
	ret

;
; * change hardwate video mode
;

mysetvideomode:
	mov	ax,[hardwarevideomode]
	cmp	ax,_vmode12
	je	setvm640480
	cmp	ax,_vmode6a
	je	setvm800600

setvm640480:
	mov	bx,_gxsize12
	mov	cx,_gysize12

	cmp	[graphflg],0
	je	setvm64in

	cmp	[gxmax],_gxsize12-1	;already this mode
	je	setvmnot

setvm64in:
	mov	ax,_vmode12
	mov	[hardwarevideomode],ax
	int	10h

setvm100:
	push	bx
	my_shr	bx,3
	mov	[gxbytes],bx
	mov	ax,bx
	mul	cx
	mov	[gramoveradr],ax
	pop	bx
	dec	bx
	mov	[gxmax],bx
	mov	[local_gxmax],bx
	dec	cx
	mov	[gymax],cx
	mov	[local_gymax],cx

	mov	al,0fh			;use 4 planes
	mov	[setresetnow],0
	mov	[enablenow],0
	mov	[colorcomparenow],0
	mov	[datarotatenow],0
	mov	[readmapnow],0
	mov	[readwritenow],0ffh
	mov	[miscellanow],0
	mov	[colordontnow],al
	mov	[bitmasknow],0ffh
	mov	[mapmasknow],al
	mov	[displplanenow],al

	mov	ah,_read0write0
	push	es
	mov	ax,_gramseg
	mov	es,ax
	mov	di,[gramoveradr]
	mov	byte ptr es:[di],0	;use for clear current ratch
	pop	es
	mov	[graphflg],-1
	clc
	ret

setvmnot:
	dec	cx
	mov	[gymax],cx
	mov	[local_gymax],cx
	mov	[graphflg],-1
	stc
	ret

setvm800600:
	mov	bx,_gxsize6a
	mov	cx,_gysize6a

	cmp	[graphflg],0
	je	setvm86in

	cmp	[gxmax],_gxsize6a-1
	je	setvmnot	;already this mode

setvm86in:
	call	ahedsp2
	mov	di,si		;es:di = buffer for VESA info
	mov	ax,4f00h
	int	10h
	add	[calcsp],UNITBYTE
	cmp	al,4fh
	jne	setvm640480	;non vesa

	mov	bx,0102h	;800*600 16 colors
	mov	ax,4f02h
	int	10h
	cmp	ax,004fh
	jne	setvm640480

	mov	ax,1124h	;select 16 dots font
	mov	bl,0
	mov	dl,37		;37 lines
	int	10h

	mov	bx,_gxsize6a
	mov	cx,_gysize6a
	jmp	setvm100


mypaletteerr:
	stc
	ret
mypalette:
	;inp: bx = palette number
	;     dx:ax = 24 bit color code

	mov	cx,[UBvideomode]
	sub	cx,_gxmax800
	jae	mypalette10
	add	cx,_gxmax800
mypalette10:
	cmp	cx,1
	je	mypalette50	;8/8 color mode
	cmp	cx,11
	jne	mypalette100
mypalette50:
	cmp	bx,8
	jae	mypaletteerr
	or	dx,dx
	jnz	mypaletteerr
	cmp	ax,8
	jae	mypaletteerr
	mov	si,ax
	add	si,[palettesetnow]
	mov	bh,cs:[si]		;color register number
mypalettesetPR:
	mov	ax,1000h
	int	10h
	clc
	ret

mypalette100:
	cmp	bx,16
	jae	mypaletteerr
	push	bx			;*
	mov	bl,dummypalette[bx]
	xor	bh,bh			;bx=dummy mypalette
	cmp	cl,10
	jae	mypaletteAT
mypalette98:
	mov	dh,dl
	mov	ch,ah
	mov	cl,2
	shr	dh,cl
	shr	ch,cl
	shr	al,cl
	mov	cl,al
	xchg	dh,ch
mypalettesetCR:
	mov	ax,1010h
	int	10h
	mov	al,bl
	pop	bx			;*
	mov	bh,al
	jmp	mypalettesetPR

mypaletteAT:
	mov	cl,4
	mov	dh,dl
	mov	dl,ah
	shl	dx,cl
	shl	ax,cl
	mov	ch,ah
	shr	ax,cl
	mov	cl,al
	mov	al,00111111b
	and	dh,al
	and	ch,al
	and	cl,al
	jmp	mypalettesetCR


	even
gsavebytes	dw	?
gareanumber	dw	?
gXbytesDisk	dw	?
gXbytesScrn	dw	?
gYsizeDisk	dw	?
gYsizeScrn	dw	?

mygload:
	call	gregnormal

	mov	ah,_read0write0
	call	readwritemode

	mov	[displplane],0

	mov	[gareanumber],0
	mov	[gX],0
	mov	[gY],0
	mov	[gXbytesScrn],_gXbytes98
	mov	[gYsizeScrn],_gymax98+1
	call	loadandput

	mov	[gareanumber],1
	mov	[gX],_gxmax98+1
;	mov	[gY],0
	mov	ax,[gxmax]
	inc	ax
	sub	ax,[gX]
	my_shr	ax,3
	mov	[gXbytesScrn],ax
;	mov	[gYsizeScrn],_gymax98+1
	call	loadandput

	mov	[gareanumber],2
	mov	[gX],0
	mov	[gY],_gymax98+1
	mov	[gXbytesScrn],_gXbytes98
	mov	ax,[gymax]
	inc	ax
	sub	ax,[gY]
	mov	[gYsizeScrn],ax
	call	loadandput

	mov	[gareanumber],3
	mov	[gX],_gxmax98+1
;	mov	[gY],_gymax98+1
	mov	ax,[gxmax]
	inc	ax
	sub	ax,[gX]
	my_shr	ax,3
	mov	[gXbytesScrn],ax
;	mov	ax,[gymax]
;	inc	ax
;	sub	ax,[gY]
;	mov	[gYsizeScrn],ax
	call	loadandput

	cmp	[displplane],0
	jne	gloadout
	mov	[displplane],0fh	;display 4 planes
gloadout:
	jmp	weakgregnormal	;call & ret


loadandput:
	cmp	[gXbytesScrn],0
	jle	loadputret
	cmp	[gYsizeScrn],0
	jle	loadputret

	mov	si,[gareanumber]
	mov	cl,6
	shl	si,cl		;* 16 * 4 plane
	add	si,[calcsp]

	mov	ax,1
	cmp	word ptr [si],0
	je	loadput20
	call	loadputsub
loadput20:
	add	si,gattribbytes1
	mov	ax,2
	cmp	word ptr [si],0
	je	loadput30
	call	loadputsub
loadput30:
	add	si,gattribbytes1
	mov	ax,4
	cmp	word ptr [si],0
	je	loadput40
	call	loadputsub
loadput40:
	add	si,gattribbytes1
	mov	ax,8
	cmp	word ptr [si],0
	je	loadputret
	call	loadputsub
loadputret:
	ret


loadputsub:
	push	ds
	push	es
	push	si

	push	ax		;*
	or	[displplane],al

	mov	ax,[si]
	mov	[gsavebytes],ax	;non compressed bytes

	mov	cx,[si+8]	;x-width(bytes)
	cmp	[gareanumber],0
	jne	loadput10
	mov	cx,_gXbytes98	;compatiblity for older version
loadput10:
	mov	[gXbytesDisk],cx

	xor	dx,dx
	div	cx
	mov	[gYsizeDisk],ax

	mov	cx,[si+4]	;number of compressed bytes
	call	loadputsubsub

	pop	ax		;*
	mov	ah,al
	call	mapmask

	;copy work -> screen

	xor	si,si
	mov	ax,[gY]
	mul	word ptr [gXbytes]
	mov	di,[gX]
	my_shr	di,3
	add	di,ax

	mov	dx,[gXbytesScrn]
	cmp	dx,[gXbytesDisk]
	jbe	loadputsub50
	mov	dx,[gXbytesDisk]
loadputsub50:
	my_shr	dx,1

	mov	ax,[arrayseg]
	mov	ds,ax
	mov	ax,_gramseg
	mov	es,ax

	mov	cx,[gYsizeScrn]
	cmp	cx,[gYsizeDisk]
	jbe	loadputsub60
	mov	cx,[gYsizeDisk]
loadputsub60:
	push	cx

	mov	cx,dx
	push	si
	push	di
	rep	movsw
	pop	di
	pop	si
	add	si,[gXbytesDisk]
	add	di,ss:[gXbytes]

	pop	cx
	myloop	loadputsub60

	pop	si		;
	pop	es
	pop	ds
	ret


loadputsubdirect:
	xor	dx,dx
	mov	bx,ss:[handle]
	mov	ah,3fh		;read compressed data
	int	21h

	pop	es
	pop	ds
	ret

loadputsubsub:
	push	ds
	push	es

	mov	ax,[arrayseg]
	mov	ds,ax
	mov	es,ax

	cmp	cx,[gsavebytes]
	je	loadputsubdirect

	mov	dx,[gsavebytes]
	mov	bx,ss:[handle]
	mov	ah,3fh		;read compressed data
	int	21h

	mov	si,[gsavebytes]
	xor	di,di
	mov	dx,[gsavebytes]
loadputsubsub50:
	lodsb
	stosb
	or	al,al
	jnz	loadputsubsub80
	xor	cx,cx
	mov	cl,[si]
	inc	si
	sub	dx,cx
	rep	stosb
loadputsubsub80:
	dec	dx
	jnz	loadputsubsub50

	mov	cx,[gsavebytes]
	mov	si,cx
	sub	si,2			;bytes640400-2
	mov	bx,[gXbytesDisk]
	sub	cx,bx
	shr	cx,1
	sub	bx,2
	neg	bx
	std
loadputsubsub85:
	lodsw			;take xor image
	xor	[bx+si],ax	;with the previous
	myloop	loadputsubsub85	;line
	cld

	mov	cx,[gsavebytes]
	dec	cx
	mov	si,cx
	std
loadputsubsub90:
	lodsb			;take xor image
	xor	[si],al		;with the previous
	myloop	loadputsubsub90	;byte
	cld

	pop	es
	pop	ds
	ret


mygsave:
	call	gregnormal

	mov	ah,_read0write3
	call	readwritemode

	mov	si,[calcsp]

	mov	[gareanumber],0
	mov	[gX],0
	mov	[gY],0
	mov	[gXbytesScrn],_gXbytes98
	mov	[gYsizeScrn],_gymax98+1
	call	getandsave
	jc	mygsaveout

	mov	[gareanumber],1
	mov	[gX],_gxmax98+1
;	mov	[gY],0
	mov	ax,[gxmax]
	inc	ax
	sub	ax,[gX]
	my_shr	ax,3
	mov	[gXbytesScrn],ax
;	mov	[gYsizeScrn],_gymax98+1
	call	getandsave
	jc	mygsaveout

	mov	[gareanumber],2
	mov	[gX],0
	mov	[gY],_gymax98+1
	mov	[gXbytesScrn],_gXbytes98
	mov	ax,[gymax]
	inc	ax
	sub	ax,[gY]
	mov	[gYsizeScrn],ax
	call	getandsave
	jc	mygsaveout

	mov	[gareanumber],3
	mov	[gX],_gxmax98+1
;	mov	[gY],_gymax98+1
	mov	ax,[gxmax]
	inc	ax
	sub	ax,[gX]
	my_shr	ax,3
	mov	[gXbytesScrn],ax
;	mov	ax,[gymax]
;	inc	ax
;	sub	ax,[gY]
;	mov	[gYsizeScrn],ax
	call	getandsave

mygsaveout:
	pushf
	call	weakgregnormal
	popf
	ret


getandsave:
	mov	ax,[gXbytesScrn]
	mul	[gYsizeScrn]
	mov	[gsavebytes],ax
	or	ax,ax
	jz	getsaveskip

	mov	ax,0
	test	[displplane],1
	jz	getsave10
	call	gsavesub
	jc	getsaveret
getsave10:
	add	si,gattribbytes1
	mov	ax,1
	test	[displplane],2
	jz	getsave20
	call	gsavesub
	jc	getsaveret
getsave20:
	add	si,gattribbytes1
	mov	ax,2
	test	[displplane],4
	jz	getsave30
	call	gsavesub
	jc	getsaveret
getsave30:
	add	si,gattribbytes1
	mov	ax,3
	test	[displplane],8
	jz	getsave40
	call	gsavesub
	jc	getsaveret
getsave40:
	add	si,gattribbytes1
	clc
getsaveret:
	ret
getsaveskip:
	add	si,gattribbytes1*4
	clc
	ret

gsavesub:
	push	ds
	push	si

	mov	ah,al
	call	readmap

	call	getgramdata
	call	compressdata
	mov	dx,[gsavebytes]	;data address
	jnc	gsavesub50
	call	getgramdata	;compress failed, read data again
	mov	cx,[gsavebytes]
	xor	dx,dx		;data address
gsavesub50:
	mov	bx,[handle]
	mov	ax,[arrayseg]
	mov	ds,ax
	mov	ah,40h		;write handle
	int	21h
	cmp	ax,cx
	jne	gsavesuberr

	pop	si
	pop	ds
	mov	ax,[gsavebytes]
	mov	[si],ax
	mov	[si+4],cx	;compressed bytes
	mov	ax,[gXbytesScrn]
	mov	[si+8],ax
	clc
	ret

gsavesuberr:
	pop	si
	pop	ds
	stc
	ret


getgramdata:
	push	ds
	push	es
	push	si

	mov	ax,[arrayseg]
	mov	es,ax

	mov	ax,[gY]
	mul	[gXbytes]
	mov	si,[gX]
	my_shr	si,3
	add	si,ax
	xor	di,di

	mov	ax,_gramseg
	mov	ds,ax

	mov	cx,[gYsizeScrn]
getgramdata10:
	push	cx
	mov	cx,[gXbytesScrn]
	shr	cx,1
	push	si
	rep	movsw
	pop	si
	add	si,ss:[gXbytes]
	pop	cx
	myloop	getgramdata10

	pop	si
	pop	es
	pop	ds
	ret


compressdata:
	push	ds
	push	es

	mov	ax,[arrayseg]
	mov	ds,ax
	mov	es,ax

	mov	si,1
	mov	cx,[gsavebytes]
	dec	cx
compress10:
	lodsb			;take xor image
	xor	[si-2],al	;with the next
	myloop	compress10	;byte

	mov	si,[gXbytesScrn]
	lea	bx,[si+2]
	neg	bx
	mov	cx,[gsavebytes]
	sub	cx,si
	shr	cx,1
compress20:
	lodsw			;take xor image
	xor	[bx+si],ax	;with the next
	myloop	compress20	;line

	xor	si,si
	mov	cx,[gsavebytes]
	mov	di,cx
	mov	dx,cx
	shl	dx,1
compress50:
	lodsb
	stosb
	or	al,al
	jnz	compress80
	xor	ah,ah		;number of 0's-1
	dec	cx
	jz	compress100		;last byte
compress60:
	lodsb
	or	al,al
	jnz	compress70
	inc	ah
	cmp	ah,0ffh
	jae	compress65
	myloop	compress60
	jmp	compress100
compress65:
	mov	[di],ah		;set number of 0's-1
	inc	di
	jmp	compress80
compress70:
	mov	[di],ah		;set number of 0's-1
	inc	di
	stosb
compress80:
	cmp	di,dx
	jae	compressfail
	myloop	compress50
	jmp	compress110		
compress100:
	mov	[di],ah		;set number of 0's-1
	inc	di
compress110:
	mov	cx,di
	sub	cx,[gsavebytes]
	cmp	cx,[gsavebytes]
	jae	compressfail	;cannot compress

	clc
	pop	es
	pop	ds
	ret			;cx=bytes
compressfail:
	stc
	pop	es
	pop	ds
	ret


;
;* print on graphic plane
;

mygprintset:
	call	usegraph?
	mov	ah,_read1write3
	call	readwritemodein
	mov	ah,[gprcolor]
	call	setreset
	ret


	;
	; get font pattern
	; 1 byte case
	; in  : al = code of 1 byte char
	; out : pattern on [calcsp]

getankfont:
  if JAPANESE
	push	es
	xor	cx,cx
	smov	es,cs
	mov	cl,al
	mov	si,offset fontbuffer
	call	dword ptr [ankfontread]
	pop	es
  else
	push	ds
	push	es
	smov	es,cs
	xor	bx,bx
	lds	si,dword ptr [ankfontread]
	mov	bl,al
	my_shl	bx,4		;16 bytes/char
	add	si,bx
	mov	cx,8		;8 words
	mov	di,offset fontbuffer
	rep	movsw
	pop	es
	pop	ds
  endif

	;
	; enlarge ank font pattern
	; out : [calcsp]

enlargeaf:
	mov	di,[calcsp]	;clear work area
	mov	al,byte ptr [height]
	mov	ah,byte ptr [gwidth_ratio]
	inc	ah
	mul	ah
	mov	cx,ax
	xor	ax,ax
	rep	stosb

	mov	si,offset fontbuffer

	mov	cx,[gwidth_ratio]
	mov	ax,8000h
	sar	ax,cl
	shl	ax,1		;set [gwidth_ratio] bits pattern
	mov	ch,[gproffset]
	xchg	cl,ch
	shr	ax,cl
	xchg	cl,ch		;cl = ratio
				;ch = counter mod 8
	mov	di,[calcsp]
	mov	bl,byte ptr [height]
enlargeaf10:
	mov	dl,cs:[si]
	inc	si
	mov	bh,8		;8 bits
enlargeaf20:
	shl	dl,1
	jnc	enlargeaf22
	xchg	al,ah
	or	[di],ax
	xchg	al,ah
enlargeaf22:
	ror	ax,cl
	add	ch,cl
	cmp	ch,8
	jb	enlargeaf24
	sub	ch,8
	xchg	al,ah
	inc	di
enlargeaf24:
	dec	bh
	jnz	enlargeaf20

	inc	di
	dec	bl
	jnz	enlargeaf10
	ret

  if JAPANESE
	;
	; get font pattern
	; 2 byte case
	; in  : ax = code of 2 byte char
	; out : pattern on cs:fontbuffer
getkanjifont:
	push	es
	mov	cx,ax
	smov	es,cs
	mov	si,offset fontbuffer
	call	dword ptr [kanjifontread]
	pop	es

	;
	; enlarge kanji font pattern
	; out : [calcsp]

enlargekf:
	mov	di,[calcsp]	;clear work area
	mov	al,byte ptr [height]
	mov	ah,byte ptr [gwidth_ratio]
	inc	ah
	mul	ah
	mov	cx,ax
	xor	ax,ax
	rep	stosw

	mov	si,offset fontbuffer

	mov	cx,[gwidth_ratio]
	mov	ax,8000h
	sar	ax,cl
	shl	ax,1		;set bit by [gwidth_ratio] bits
	mov	ch,[gproffset]
	xchg	cl,ch
	shr	ax,cl		;initial mask
	xchg	cl,ch		;cl = ratio
				;ch = counter mod 8
	mov	di,[calcsp]
	mov	bl,byte ptr [height]
	shl	bl,1
enlargekf10:
	mov	dx,cs:[si]
	winc	si
	xchg	dl,dh
	mov	bh,16		;16 bits
enlargekf20:
	shl	dx,1
	jnc	enlargekf22
	xchg	al,ah
	or	[di],ax
	xchg	al,ah
enlargekf22:
	ror	ax,cl
	add	ch,cl
	cmp	ch,8
	jb	enlargekf24
	sub	ch,8
	xchg	al,ah
	inc	di
enlargekf24:
	dec	bh
	jnz	enlargekf20
	winc	di
	dec	bl
	jnz	enlargekf10
	ret
  endif

	;
	; display font pattern in font buffer
	; 1 byte case
	;       pattern on cs:fontbuffer
setankfont:
	push	es
	mov	ax,_gramseg
	mov	es,ax

	mov	bx,[gpradr]
	mov	si,[calcsp]

	mov	ah,[gprmask1st]
	call	bitmask
	call	setankfsub

	mov	cx,[gwidth_ratio]
	dec	cx
	jz	setankf80

	mov	ah,0ffh
	call	bitmask

setankf30:
	push	cx
	call	setankfsub
	pop	cx
	myloop	setankf30

setankf80:
	mov	ah,[gprmask2nd]
	or	ah,ah
	jz	setankf100

	call	bitmask
	call	setankfsub

setankf100:
	pop	es
	call	weakgregnormal
	ret

setankfsub:
	push	bx
	push	si
	mov	cx,[height]
setankfsub10:
	push	cx
	lodsb
	mov	cx,[gheight_ratio]
setankfsub20:
	and	es:[bx],al
	add	bx,[gxbytes]
	myloop	setankfsub20
	add	si,[gwidth_ratio]
	pop	cx
	myloop	setankfsub10
	pop	si
	pop	bx
	inc	bx
	inc	si
	ret

  if JAPANESE

	;
	; display font pattern in font buffer
	; 2 byte case
	;       pattern on ds:[calcsp]
setkanjifont:
	push	es
	mov	ax,_gramseg
	mov	es,ax

	mov	bx,[gpradr]
	mov	si,[calcsp]

	mov	ah,[gprmask1st]
	call	bitmask
	call	setkanjifsub

	mov	cx,[gwidth_ratio]
	shl	cx,1
	dec	cx
;	jz	setkanjif80

	mov	ah,0ffh
	call	bitmask

setkanjif30:
	push	cx
	call	setkanjifsub
	pop	cx
	myloop	setkanjif30

;setkanjif80:
	mov	ah,[gprmask2nd]
	or	ah,ah
	jz	setkanjif100

	call	bitmask
	call	setkanjifsub

setkanjif100:
	pop	es
	call	weakgregnormal
	ret


setkanjifsub:
	push	bx
	push	si
	mov	cx,[height]
setkanjifsub10:
	push	cx
	lodsb
	mov	cx,[gheight_ratio]
setkanjifsub20:
	and	es:[bx],al
	add	bx,[gxbytes]
	myloop	setkanjifsub20
	inc	si
	add	si,[gwidth_ratio]
	add	si,[gwidth_ratio]
	pop	cx
	myloop	setkanjifsub10
	pop	si
	pop	bx
	inc	bx
	inc	si
	ret
  endif


;
;* clear graphic character
;
setgprmode:
	test	[gprcolor],80h
	jz	gprwithblack

	mov	ah,_read1write3
	call	readwritemode

	mov	ah,0fh
	call	enablesetreset

	mov	ah,[gprcolor]
	call	setreset
	ret

gprwithblack:
	mov	ah,_read1write0
	call	readwritemode

	mov	ah,[gprcolor]
	not	ah
	and	ah,0fh
	call	enablesetreset

	xor	ax,ax
	call	setreset
	ret


;
; * scroll gram up/down
;  input ax=scroll lines

mygscrollud:
	push	ds
	push	es
  if flg32
	pusha
  else
	push	ax
	push	bx
	push	cx
	push	dx
	push	si
	push	di
  endif

	mov	[gscrolldiff],ax
;	sub	[chypos],ax
	mov	bx,ax			;memo
	mov	ax,[viewy1]
	mov	cx,[gxbytes]
	test	bh,80h
	jz	gscr10
	mov	ax,[viewy2]
	neg	bx
gscr10:
	mul	cx
	mov	dx,[viewx1]
	my_shr	dx,3
	add	ax,dx
	mov	[gscrolltopadr],ax
	mov	ax,bx
	mul	cx
	mov	[gscrolldiffbytes],ax

	mov	cx,[local_gymax]
	sub	cx,bx
	inc	cx
	mov	[gscrolllines],cx

	mov	ax,[viewx1]
	mov	cl,8
	mov	ch,al
	and	ch,7
	sub	cl,ch
	mov	dx,1
	shl	dx,cl
	dec	dx
	mov	[gscrollmask1],dl
	my_shr	ax,3
	mov	dx,ax		;memo

	mov	ax,[viewx2]
	mov	cl,al
	and	cl,7
	mov	ch,80h
	sar	ch,cl
	mov	[gscrollmask2],ch

	my_shr	ax,3
	sub	ax,dx
	dec	ax		;bytes/line-2
	mov	[gscrollbytes],ax

	mov	ax,_gramseg
	mov	ds,ax
	mov	es,ax
	call	gscrollsub

	call	weakgregnormal

  if flg32
	popa
  else
	pop	di
	pop	si
	pop	dx
	pop	cx
	pop	bx
	pop	ax
  endif
	pop	es
	pop	ds
	ret

gscrollsub:
	test	byte ptr [gscrolldiff+1],80h
	jnz	gscrollsubdown

	mov	di,[gscrolltopadr]
	mov	si,di
	add	si,[gscrolldiffbytes]

	mov	cx,[gscrolllines]
	jcxz	gscrup55
gscrup50:
	call	move1line
	mov	ax,ss:[gxbytes]
	add	si,ax
	add	di,ax
	myloop	gscrup50
gscrup55:
	mov	cx,[gscrolldiff]
	jcxz	gscrup65
gscrup60:
	call	clear1line
	add	di,ss:[gxbytes]
	myloop	gscrup60
gscrup65:
	ret

gscrollsubdown:
	mov	di,[gscrolltopadr]
	mov	si,di
	sub	si,[gscrolldiffbytes]

	mov	cx,[gscrolllines]
	jcxz	gscrdwn55
gscrdwn50:
	call	move1line
	mov	ax,ss:[gxbytes]
	sub	si,ax
	sub	di,ax
	myloop	gscrdwn50
gscrdwn55:
	mov	cx,[gscrolldiff]
	neg	cx
	jcxz	gscrdwn65
gscrdwn60:				;clear lines
	call	clear1line
	sub	di,ss:[gxbytes]
	myloop	gscrdwn60
gscrdwn65:
	ret


move1line:
	push	cx
	push	si
	push	di

	;1st byte

	mov	ah,_read0write0
	call	readwritemode

	mov	ah,[gscrollmask1]
	call	bitmask

	mov	cx,0100h		;ch for mapmask, cl for readmap
move1lp:
	test	ch,ss:[activeplane]
	jz	move1skip		;not active

	mov	ah,cl
	call	readmap

	mov	ah,ch
	call	mapmask

	mov	al,[si]
	mov	ah,[di]		;dummy read
	mov	[di],al
move1skip:
	shl	ch,1
	inc	cl
	cmp	cl,4
	jb	move1lp
	inc	si
	inc	di

	;intermediate bytes

	mov	ah,_read0write1
	call	readwritemode

	mov	ah,0ffh
	call	bitmask

	mov	ah,ss:[activeplane]
	call	mapmask

	mov	cx,[gscrollbytes]
	rep	movsb

	;last byte

	mov	ah,_read0write0
	call	readwritemode

	mov	ah,[gscrollmask2]
	call	bitmask

	mov	cx,0100h		;ch for mapmask, cl for readmap
move1lp2:
	test	ch,ss:[activeplane]
	jz	move1skip2

	mov	ah,cl
	call	readmap

	mov	ah,ch
	call	mapmask

	mov	al,[si]
	mov	ah,[di]		;dummy read
	mov	[di],al
move1skip2:
	shl	ch,1
	inc	cl
	cmp	cl,4
	jb	move1lp2

	pop	di
	pop	si
	pop	cx
	ret

clear1line:
	push	cx
	push	di

	;1st byte

	mov	ah,_read0write0
	call	readwritemode

	mov	ah,[gscrollmask1]
	call	bitmask

	mov	cx,0102h
clear1lp:
	test	ch,ss:[activeplane]
	jz	clear1skip

	mov	ah,ch
	call	mapmask

	mov	al,[di]		;dummy read
	mov	byte ptr [di],0	;no color
clear1skip:
	shl	ch,1
	cmp	ch,16
	jb	clear1lp
	inc	di

	;intermediate bytes

	mov	ah,ss:[activeplane]
	call	mapmask

	mov	ah,0ffh
	call	bitmask

	mov	cx,[gscrollbytes]
	xor	ax,ax		;no color
	rep	stosb

	;last byte

	mov	ah,_read0write0
	call	readwritemode

	mov	ah,[gscrollmask2]
	call	bitmask

	mov	cx,0102h
clear1lp2:
	test	ch,ss:[activeplane]
	jz	clear1skip2

	mov	ah,ch
	call	mapmask

	mov	al,[di]		;dumy read
	mov	byte ptr [di],0	;no color
clear1skip2:
	shl	ch,1
	cmp	ch,16
	jb	clear1lp2

	pop	di
	pop	cx
	ret


;
; * scroll gram left/right
; input ax = lines

mygscrolllr:
  if flg32
	pusha
  else
	push	ax
	push	bx
	push	cx
	push	dx
	push	si
	push	di
  endif

	mov	[gscrolldiff],ax
	or	ax,ax
	jz	gxscrlret		;no slide
	jns	gxscrl10
	neg	ax
gxscrl10:
	mov	dx,ax
	add	ax,[viewX1]
	cmp	ax,[viewX2]
	jb	gxscrl20
	call	myclearviewarea		;clear all
	jmp	gxscrlret
gxscrl20:
	mov	ax,dx
	my_shr	ax,3
	mov	[gscrolloffbytes],ax
	and	dl,7
	mov	[gscrolloffbits],dl
	mov	bx,ax		;memo
	mov	cx,[gxbytes]

	mov	ah,_read0write0
	call	readwritemode

	mov	ah,0
	call	enablesetreset

	push	bp
	call	gxscrollsub
	pop	bp

	call	weakgregnormal
gxscrlret:
  if flg32
	popa
  else
	pop	di
	pop	si
	pop	dx
	pop	cx
	pop	bx
	pop	ax
  endif
	ret


gxscrollsub:
	test	byte ptr [gscrolldiff+1],80h
	jnz	gscrollsubright

gscrollsubleft:
	mov	ax,[viewy1]
	mul	cx
	mov	dx,ax		;memo

	mov	ax,[viewx1]
	my_shr	ax,3
	add	ax,dx
	mov	[gscrolladr1],ax	;left end adr

	mov	ax,[viewx2]
	sub	ax,word ptr [gscrolloffbits]
	my_shr	ax,3
	add	ax,dx
	mov	[gscrolladr2],ax	;right end adr

	mov	ax,[viewx1]
	mov	cl,8
	mov	ch,al
	and	ch,7
	sub	cl,ch
	mov	al,1
	shl	al,cl
	dec	al
	mov	[gscrollmask1],al

	mov	ax,[viewx2]
	sub	al,[gscrolloffbits]
	and	al,7
	mov	cl,al
	mov	al,80h
	sar	al,cl
	mov	[gscrollmask2],al

	push	es
	mov	ax,_gramseg
	mov	es,ax

	mov	di,[gscrolladr1]
	mov	si,di
	add	si,[gscrolloffbytes]

	call	get1lr
gscrleft50:
	cmp	si,[gscrolladr2]
	ja	gscrleft100
	call	move1left
	inc	si
	inc	di
	jmp	gscrleft50

gscrleft100:
	push	[viewX1]
	mov	ax,[viewX2]
	sub	ax,[gscrolldiff]
	inc	ax
	mov	[viewX1],ax
	call	myclearviewarea
	pop	[viewX1]
	pop	es
	ret

gscrollsubright:
	mov	ax,[viewy1]
	mul	cx
	mov	dx,ax		;memo

	mov	ax,[viewx1]
	add	ax,word ptr [gscrolloffbits]
	my_shr	ax,3
	add	ax,dx
	mov	[gscrolladr1],ax	;destination left end adr

	mov	ax,[viewx2]
	my_shr	ax,3
	add	ax,dx
	mov	[gscrolladr2],ax	;destination right end adr

	mov	ax,[viewx1]
	add	al,[gscrolloffbits]
	mov	cl,8
	mov	ch,al
	and	ch,7
	sub	cl,ch
	mov	al,1
	shl	al,cl
	dec	al
	mov	[gscrollmask1],al

	mov	ax,[viewx2]
	and	al,7
	mov	cl,al
	mov	al,80h
	sar	al,cl
	mov	[gscrollmask2],al

	push	es
	mov	ax,_gramseg
	mov	es,ax

	mov	di,[gscrolladr2]
	mov	si,di
	sub	si,[gscrolloffbytes]
	call	get1lr
gscrright50:
	cmp	si,[gscrolladr1]
	jb	gscrright100
	call	move1right
	dec	si
	dec	di
	jmp	gscrright50

gscrright100:
	push	[viewX2]
	mov	ax,[viewX1]
	sub	ax,[gscrolldiff]
	dec	ax
	mov	[viewX2],ax
	call	myclearviewarea
	pop	[viewX2]
	pop	es
	ret

get1lr:
	mov	bp,[calcsp]
	sub	bp,UNITBYTE		;use for work area
	mov	cx,0100h		;ch for mapmask, cl for readmap
get1lrlp10:
	test	ch,ss:[activeplane]
	jz	get1lrskip

	mov	ah,cl
	call	readmap

	push	si
	mov	bx,[gxbytes]
	mov	dx,[local_gymax]
	inc	dx

	test	byte ptr [gscrolldiff+1],80h
	jnz	get1lrlp30
get1lrlp20:
	mov	al,es:[si]
	mov	[bp],al
	inc	bp
	add	si,bx
	dec	dx
	jnz	get1lrlp20
	jmp	get1lr100

get1lrlp30:
	mov	al,es:[si]
	mov	[bp],al
	inc	bp
	add	si,bx
	dec	dx
	jnz	get1lrlp30

get1lr100:
	pop	si
get1lrskip:
	shl	ch,1
	inc	cl
	cmp	cl,4
	jb	get1lrlp10
	ret


move1left:
	mov	ah,0ffh			;no mask
	cmp	di,[gscrolladr1]
	jne	move1left10
	and	ah,[gscrollmask1]	;cut left
move1left10:
	cmp	si,[gscrolladr2]
	jne	move1left20
	and	ah,[gscrollmask2]	;cut right
move1left20:
	jmp	move1lrin

move1right:
	mov	ah,0ffh			;no mask
	cmp	di,[gscrolladr2]
	jne	move1right10
	and	ah,[gscrollmask2]	;cut right
move1right10:
	cmp	si,[gscrolladr1]
	jne	move1right20
	and	ah,[gscrollmask1]	;cut left
move1right20:

move1lrin:
	or	ah,ah
	jz	move1lrret2		;no data for move in this byte

	mov	bp,[calcsp]
	sub	bp,UNITBYTE		;use for work area

	push	si
	push	di

	call	bitmask

	mov	cx,0100h		;ch for mapmask, cl for readmap
move1lrlp10:
	test	ch,ss:[activeplane]
	jz	move1lrskip

	mov	ah,ch
	call	mapmask

	mov	ah,cl
	call	readmap

	push	cx
	push	si
	push	di
	mov	bx,[gxbytes]
	mov	cl,[gscrolloffbits]
	mov	dx,[local_gymax]
	inc	dx

	test	byte ptr [gscrolldiff+1],80h
	jnz	move1lrlp30
move1lrlp20:
	mov	ah,[bp]
	mov	al,es:[si+1]
	mov	[bp],al
	shl	ax,cl
	mov	ch,es:[di]		;dummy read
	mov	es:[di],ah
	inc	bp
	add	si,bx
	add	di,bx
	dec	dx
	jnz	move1lrlp20
	jmp	move1lr100

move1lrlp30:
	mov	al,[bp]
	mov	ah,es:[si-1]
	mov	[bp],ah
	shr	ax,cl
	mov	ch,es:[di]		;dummy read
	mov	es:[di],al
	inc	bp
	add	si,bx
	add	di,bx
	dec	dx
	jnz	move1lrlp30

move1lr100:
	pop	di
	pop	si
	pop	cx
move1lrskip:
	shl	ch,1
	inc	cl
	cmp	cl,4
	jb	move1lrlp10

move1lrret:
	pop	di
	pop	si
move1lrret2:
	ret


farfunctionkeybox:
	call	gregsave

	mov	ah,_read1write2
	call	readwritemode
	mov	ah,0ffh
	call	bitmask

	push	es
	mov	ax,_gramseg
	mov	es,ax

	mov	ax,word ptr ss:[linesdef]
	dec	ax
	mul	ss:[gxbytes]
	my_shl	ax,4		;16 lines
	mov	di,ax
	mov	al,ss:[whitenow]
	mov	ah,al
	mov	cx,15		;16-1
functionkeybox10:
	add	di,3
  rept 4
  	stosw
	stosw
	stosw
	inc	di
  endm
	add	di,2
  rept 4
  	stosw
	stosw
	stosw
	inc	di
  endm
	add	di,2
  rept 2
  	stosw
	stosw
	stosw
	inc	di
  endm
	sub	di,77
	add	di,ss:[gxbytes]
	myloop	functionkeybox10

	pop	es

	call	gregrestore
	retf


	public	hardcopy


lprmac	macro	CHAR
	mov	al,CHAR
	call	lprint_al3
	endm


lprinimsg0	db	esc,"@"		;initialize
		db	esc,"@"
		db	esc,"P"		;Pica
		db	1ch,"S",5,5	;5dots+kanji+5dots
		db	esc,"3",30	;30/180 inch CR
;		db	esc,"l",6	;left margin 6 chars
		db	0

lprinimsg80c	db	esc,"@"		;initialize
		db	esc,"@"
		db	esc,"M"		;Elite
		db	1ch,"S",3,3	;3dots+kanji+3dots
		db	esc,"3",30	;30/180 inch CR
		db	esc,"l",6	;left margin 6 chars
		db	CR,0		;and CR

lprinimsg100c	db	esc,"@"		;initialize
		db	esc,"@"
;		db	esc,"M",esc," ",1	;Elite+1dot
		db	esc,"g"		;Elite+1dot
;		db	1ch,"S",0,0	;4dots+kanji+4dots
		db	esc,"3",24	;24/180 inch CR
		db	esc,"l",8	;left margin 8 chars
		db	CR,0		;and CR

lprinimsg640g	db	esc,"@"		;initialize
		db	esc,"@"
		db	esc,"3",16	;16/180 inch CR
		db	esc,"l",6	;left margin 6 chars
		db	CR,0		;and CR

lprinimsg800g	db	esc,"@"		;initialize
		db	esc,"@"
		db	esc,"3",8	;8/180 inch CR
		db	esc,"l",6	;left margin 6 chars
		db	CR,0		;and CR


senddatamsgEPS	db	ESC,"*"
bitimagemode	db	38		;or 39
		db	8,0
		;bit image 24 dots CRT or double density 8 rows

headmoveunit	dw	8*1

;lprnormalcrmsg		db	esc,"A",0	;1/6 inch CR
lprnormalcrmsgEPS	db	esc,"@",esc,"@"
			db	1ch,"B",0	;initialize

lprcrlfmsg	db	cr,lf,0

;lprkanjiinmsg		db	esc,4bh,0
lprkanjiinmsgEPS	db	1ch,"&",0

;lprkanjioutmsg		db	esc,48h,0
lprkanjioutmsgEPS	db	1ch,".",0

dotmovemsg	db	esc,"F0000",0

;cpimessage10	db	esc,"P",esc,"l",1,0
;cpimessage12	db	esc,"M",esc,"l",8,0
;cpimessage15	db	esc,"g",esc,"l",10,0

lprdotposition	dw	0
lprdots		dw	8	;8=25lines mode,10=20 lines mode
;lprdotsw	dw	2	;2=25lines mode, 3=20 lines mode

copybusy	db	0

HARDCOPY:			;al = parameter
	push	ds
	push	es

	cmp	[copybusy],0
	jne	hardcopyret	;busy

	mov	[copybusy],-1

	mov	dx,data		;not ss (for COPY-key interrupt)
	mov	ds,dx

	cmp	al,1
	jbe	hcopytext
	cmp	[graphflg],0
	jne	hcopygraph

hcopytext:
	mov	ax,[vramsegnow]
	mov	es,ax

	mov	si,offset lprinimsg80c
	mov	ax,word ptr [chars1]
	cmp	ax,96
	jb	hcopyt5
	mov	si,offset lprinimsg100c
hcopyt5:
	call	lprmsgcs
	xor	si,si		;vram pointer

	mov	cx,[maxlinesnow]
hcopyt10:
	push	cx
	call	copychars	;偶数番目はテキストを印刷

	lprmac	CR		;位置を戻す
	lprmac	LF

	pop	cx
	myloop	hcopyt10

	lprmac	FF

	mov	si,offset lprinimsg0
	call	lprmsgcs

	jmp	hardcopyret

copychars:
	mov	cx,word ptr [chars1]
copyc10:
	mov	ax,es:[si]
	winc	si			;ah = attribute
  if JAPANESE
  	call	far ptr farKANJI1ST?
	jc	copyckanji
  endif
copyc20:
	cmp	al,20h
	jae	copyc25
copyc22:
	mov	al,20h
copyc25:
	call	lprint_al3
copyc30:
	myloop	copyc10
	ret

  if JAPANESE
copyckanji:
	cmp	cx,1
	je	copycilg	;no space for kanji
	push	ax
	push	si
	mov	si,offset lprkanjiinmsgEPS
	call	lprmsgcs
	pop	si
	pop	bx
	mov	ax,es:[si]
	winc	si
	mov	ah,bl
	call	far ptr farSJIS_JIS
	push	ax
	mov	al,ah
	call	lprint_al3
	pop	ax
	call	lprint_al3
	dec	cx
	push	si
	mov	si,offset lprkanjioutmsgEPS
	call	lprmsgcs
	pop	si
	jmp	copyc30
  endif

copycilg:
	jmp	copyc22


hcopygraph:
	mov	ax,_gramseg
	mov	es,ax

	cmp	[displplane],0
	je	hardcopyret

	call	gregsave

	mov	ah,_read0write3
	call	readwritemode

	mov	si,offset lprinimsg640g
	mov	ax,0810h
	mov	[bitimagemode],38

	cmp	[gxmax],720
	jb	hcopy10

	lprmac	esc		;draft mode
	lprmac	"x"
	lprmac	0
	mov	[bitimagemode],39
	mov	si,offset lprinimsg800g
	mov	ax,0808h
hcopy10:
	mov	byte ptr [lprdots],ah
	mov	byte ptr [headmoveunit],al
	call	lprmsgcs	;行送り幅の設定

	xor	bx,bx		;pointer of Graphic
	mov	ax,[gymax]
	inc	ax
	xor	dx,dx
	div	[lprdots]
	mov	cx,ax
hcopylp30:
	push	cx
	mov	[lprdotposition],0
	mov	cx,[gxbytes]
hcopylp60:
	push	cx
	call	copy8rows	;8 dotlines の印刷
	inc	bx
	pop	cx
	myloop	hcopylp60

	mov	ax,[lprdots]
	dec	al
	mov	ah,byte ptr [gxbytes]
	mul	ah
	add	bx,ax

	lprmac	CR
	lprmac	LF
	pop	cx
	myloop	hcopylp30

	mov	si,offset lprnormalcrmsgEPS
	call	lprmsgcs	;行送り幅を元に戻す

	call	gregrestore

hardcopyret:
	mov	[copybusy],0

	pop	es
	pop	ds
	retf


copy8rows:
	mov	di,offset fnamebuf+4
	mov	cx,[lprdots]	;clear work area
	shr	cx,1
	xor	ax,ax		;8bytes
copy8lp:
	mov	[di],ax
	winc	di
	myloop	copy8lp

plane1:				;get each plane
	test	[displplane],1
	jz	plane2
	mov	ah,0
	call	getplane
plane2:
	test	[displplane],2
	jz	plane3
	mov	ah,1
	call	getplane
plane3:
	test	[displplane],4
	jz	plane4
	mov	ah,2
	call	getplane
plane4:
	test	[displplane],8
	jz	dataready
	mov	ah,3
	call	getplane

dataready:			;if data ready then
	mov	di,offset fnamebuf+4
	mov	cx,[lprdots]
	shr	cx,1
	xor	ax,ax
datareadylp:
	cmp	[di],ax
	jne	copysubgo	;start if there are non 0 data
	winc	di
	myloop	datareadylp
datareadyjp:
	mov	ax,[lprdotposition]	;if all 0 then memo skip length
	or	ah,80h
	add	ax,[headmoveunit]
	mov	[lprdotposition],ax
	ret

copysubgo:
	mov	ax,[lprdotposition]
	test	ah,80h
	jz	copysub10	;未実行の移動がない場合

	and	ah,7fh		;実際にヘッドを移動
	push	ax

	lprmac	esc		;relative head move
	lprmac	"\"
	pop	ax
	push	ax
	call	lprint_al3
	pop	ax
	lprmac	ah

	mov	[lprdotposition],0

copysub10:
	mov	si,offset senddatamsgEPS
	call	lprmsgcs
	lprmac	0		;0 cannot be sent by lprmsgcs

	mov	cx,8		;8 columns
copysub30:
	push	cx		;*

	mov	si,offset fnamebuf+4
	mov	cx,3		;24 pins
copysub35:
	push	cx		;**
	cmp	[headmoveunit],8
	je	copysub42
	mov	cx,4		;4 rows
copysub40:
	shl	byte ptr [si],1	;[si]~[si+3] の
	pushf
	rcl	al,1		;上位bits を二重にして al へ
	popf
	rcl	al,1
	inc	si
	myloop	copysub40
	call	lprint_al3
copysub50:
	pop	cx		;**
	myloop	copysub35

	pop	cx
	myloop	copysub30	;*
	ret

copysub42:
	mov	cx,8		;8 rows
copysub44:
	shl	byte ptr [si],1	;[si]~[si+7]
	rcl	al,1
	inc	si
	myloop	copysub44
	call	lprint_al3
	jmp	copysub50


getplane:
	call	readmap

	mov	si,bx
	mov	di,offset fnamebuf+4
	mov	cx,[lprdots]		;8
getplane10:
	mov	al,es:[si]
	or	[di],al
	add	si,[gxbytes]
	inc	di
	myloop	getplane10
	ret


lprint_al3:
	push	ax
	push	dx
	xor	dx,dx		;to printer 0
lprint3_lp:
	mov	ah,0
	int	17h
	shl	ah,1
;	jnc	lprint3_lp
	pop	dx
	pop	ax
	ret

lprmsgcs:
lprmsglp:
	lods	byte ptr cs:[si]
	or	al,al
	jz	lprmsgret
	call	lprint_al3
	jmp	lprmsglp
lprmsgret:
	ret


