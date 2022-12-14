;graph.asm
; included in excom3.asm
;  for UBasic
;


_IBM0	equ	20
_IBM1	equ	21
_IBM2	equ	22
_IBM3	equ	23


CODE	SEGMENT WORD PUBLIC
	ASSUME	CS:CODE,DS:DATA


	public	viewin,windowin,screenin,linein
	public	psetin,circlein,paintin,putgraph,getgraph
	public	hcopyin,graph_chg

	extrn	farkakko:far


viewin:
	jmp	far ptr farviewin

windowin:
	jmp	far ptr farwindowin

screenin:
	jmp	far ptr farscreenin

linein:
	jmp	far ptr farlinein

psetin:
	jmp	far ptr farpsetin

circlein:
	jmp	far ptr farcirclein

paintin:
	jmp	far ptr farpaintin

putgraph:
	jmp	far ptr farputgraph

hcopyin:
	jmp	far ptr farhcopyin


getgraph:
	call	far ptr fargetgraph
	ret

graph_chg:
	ret

code	ends


data	segment	para public

	public	viewx1,viewy1,viewy2,graphflg

	extrn	RETURNADR:word,COPYSW:byte
	extrn	PRINTERTYPE:word,MAXLINESNOW:word,calcsp_limit:word
	extrn	varseglim:word,vramsegover:word


gcolor		db	7,0		;graphic color
backcolor	db	?
paintcolor	db	?
bordercolor	db	?

	even
gxbytes		dw	?
gxmax		dw	?
gymax		dw	?

gXpoint		dw	?	;fractional part of gX used by ellipse
gX		dw	?
gYpoint		dw	?	;fractional part of gY used by ellipse
gY		dw	?

gX1		dw	?
gY1		dw	?
gX2		dw	?
gY2		dw	?

bX1		dw	?
bY1		dw	?
bX2		dw	?
bY2		dw	?

centerX		dw	?
centerY		dw	?
centerbaseadr	dw	?

radius		dw	?
radiusX		dw	?
radiusY		dw	?
radiusratio	dw	?
radiusratioX	dw	?
radiusratioY	dw	?

gposx		dw	0	;current graphic pointer
gposy		dw	0	;

windowsw	dw	0
viewx1		dw	0
viewy1		dw	0
viewx2		dw	?
viewy2		dw	?
viewx1memo	dw	0
viewy1memo	dw	0
viewx2memo	dw	?
viewy2memo	dw	?

linestylesw		dw	?
linestyleXpattern	db	4 dup(0ffh)
linestyleYpattern	db	32 dup(0ffh)

tilelength	dw	0
tileaddress	dw	?

UBvideomode	dw	0

activeplane	db	0
planemask	db	0
displplane	db	0

graphflg	db	0


	even
	public	chxpos,chypos

ankwidth	dw	?
height		dw	?
height2		dw	?
halfheight	dw	?
gsizemax	dw	?

chxpos		dw	?
chypos		dw	?

gprcolor	db	?
gprkanji1st	db	0

TeXFlg		db	1

	even
local_gxmax	dw	?
local_gymax	dw	?

gwidth		dw	?
gwidth_ratio	dw	1
gheight		dw	?
gheight_ratio	dw	1
halfgheight	dw	?

gwidth2		dw	?
gheight2	dw	?

gprpoint	dw	?
gprbytes	dw	?

ankfontread	dw	?,?
  if JAPANESE
kanjifontread	dw	?,?
  endif


data	ends


code2	segment	word public
	assume	cs:code2,ds:data

	public	palettein,paletteinitin,cleargraphic
	public	farusegraph?
	public	dotcolor	;,gxxfer,gyxfer
	public	get_world_x,get_world_y

	extrn	ahedsp2:near,backsp2:near

	extrn	farsubin:far,farmulin:far,fardivin:far
	extrn	farint_ent:far,farcos_ent:far,farsin_ent:far

	public	fargsizeinit
	public	farGPRINTCHAR,farGPRINTSTRING
	public	farreturn2text

	extrn	farCLEAR_FUNCTIONKEY:far
	extrn	consoledefault:near

	even
hardwarevideomode	dw	_vmode12
paintflg	db	0

	even
angle_int	dw	?
angle_frac	dw	?

linemem1or2	dw	?


paletteinitin:
	call	usegraph?
	call	selectpalette
	jmp	gomainlp2


changepalette:
; dh = color code
; al = blue, ah = red, dl = green

	ret

;
; * get graphic from rectangle area
;
getgraphsynerr:
	jmp	gosynerr
getgraphover:
goovererr:
	jmp	far ptr ovrerr


fargetgraph:
	call	usegraph?
	call	get_screen_xy
	mov	[bX1],bx
	mov	[bY1],ax

	cmp	byte ptr [bp],0deh	;'-'
	jne	getgraphsynerr
	inc	bp

	call	get_screen_xy
	mov	[bX2],bx	;x2
	mov	[bY2],ax	;y2

	call	ahedsp2
	mov	di,[calcsp]	;es:di = buffer

	call	mygetgraph
	jc	getgraphover

	retf


;
; * put graphic to rectangle area
;
putsynerr:
gosynerr:
	jmp	far ptr synerr
putilgerr:
goilgerr:
	jmp	far ptr ilgerr

farputgraph:
	call	usegraph?

	call	get_screen_xy
	mov	[bX1],bx
	mov	[bY1],ax

	cmp	byte ptr [bp],codeofequal
	jne	putsynerr
	inc	bp
	call	far ptr farformul
	mov	si,[calcsp]
	lodsw
	test	ah,stringmaskhigh
	jz	putilgerr

	call	myputgraph

	add	[calcsp],unitbyte
	jmp	gomainlp2


;
; * screen hard copy
;

hcopy_ilg:
	jmp	goilgerr

farHCOPYIN:
	MOV	AL,[BP]
	CMP	AL,CR
	JE	farhcopy10		;コマンドのみ
	CMP	AL,0C0H			;':'
	JE	farhcopy10		;コマンドのみ
	call	far ptr farget_ax
	jc	hcopy_ilg
farhcopy10:
	cmp	al,3
	jbe	exec_hcopy
	mov	al,1			;text only
exec_hcopy:
	call	far ptr HARDCOPY
	jmp	gomainlp2


;
;* parameter get for graphic commands
;	out: ax -10000 to 10000

_gpmax	equ	10000

getgrpparam:
	call	far ptr farformul
getgrpparamin:
	call	backsp2
	lodsw
	cmp	ax,1
	jb	getgpret	;if 0
	jne	getgpjp
getgppos:
	lodsw
getgpposin:
	cmp	ax,_gpmax
	jbe	getgpret
getgpposovr:
	mov	ax,_gpmax	;set max
getgpret:
	ret

getgpilgout:
	jmp	goilgerr


getgpjp:
	cmp	ax,signmask+1	;negative 1 byte
	jne	getgp50
	lodsw
	cmp	ax,_gpmax
	jbe	getgp40
	mov	ax,_gpmax
getgp40:
	neg	ax
	jmp	getgpret

getgp50:
	test	ah,compratstrmaskhigh
	jnz	getgpilgout	;complex/rational/string
	test	ah,pointmaskhigh
	jnz	getgp10
	test	ah,signmaskhigh
	jz	getgpposovr	;positive integer>=2 words
	and	ax,lenmask
	cmp	ax,1
	jne	getgpnegovr	;negative integer>=2 words
getgpneg:
	lodsw
getgpnegin:
	cmp	ax,_gpmax
	ja	getgpnegovr
	neg	ax
	jmp	getgpret
getgpnegovr:
	mov	ax,-_gpmax
	jmp	getgpret

getgp10:			;fraction case
	test	ah,signmaskhigh
	pushf			;*
	and	ax,lenmask
	mov	cx,[si]		;exp
	dec	ax
	or	cx,cx
	jg	getgp20
	je	getgp15
getgp12:
	popf			;*
	xor	ax,ax
	jmp	getgpret

getgp15:			;check roundup
	add	si,ax
	add	si,ax
	lodsw			;get MSW
	add	ax,ax
	jnc	getgp12	
	mov	ax,1
	popf			;*
	jz	getgpret	;if positive
	mov	ax,-1		;if negative
	jmp	getgpret

getgp20:
	add	si,ax
	add	si,ax

	cmp	cx,2
	ja	getgpovr
	je	getgp22
	mov	dh,[si]
	mov	al,[si+1]
	xor	ah,ah
	jmps	getgp24
getgp22:
	mov	dh,[si-1]
	mov	ax,[si]
getgp24:
	add	dh,dh
	adc	ax,0
	jc	getgpovr
	popf			;*
	jnz	getgpnegin
	jmp	getgpposin
getgpovr:
	popf			;*
	jnz	getgpnegovr
	jmp	getgpposovr

;
; * color
;
palettesynerr:
	jmp	gosynerr

palettein:
	call	usegraph?
palette10:
	cmp	byte ptr [bp],'('
	jne	palettesynerr
	inc	bp
	call	getgrpparam
	push	ax		;palette number
	cmp	byte ptr [bp],0c2h	;code of ,
	jne	palettesynerr	
	inc	bp
	call	far ptr farkakko
	call	backsp2		;now SI=pointer of color code

	pop	bx		;palette number
	xor	dx,dx		;dx:ax = color code
	lodsw
	mov	cx,ax
	jcxz	palette30	;=0
	lodsw
	dec	cx
	jz	palette30
	mov	dx,[si]
palette30:
	call	mypalette
	jc	paletteilgerr
	jmp	gomainlp2

paletteilgerr:
	jmp	goilgerr



screenmodeset:
	;inp: ax = UBasic screen mode number

	mov	bl,0fh		;use 4 planes to any color
				;by setreset
	mov	cx,0f04h	;use 4 planes, textcolor=15
	mov	dx,offset palette0
	or	ax,ax
	jz	screenset10
	cmp	ax,_gxmax800
	je	screenset10
	cmp	ax,_IBM0
	je	screenset10
	cmp	ax,_gxmax800+_IBM0
	je	screenset10

	mov	bl,0		;non modify
	mov	cx,0703h	;use 3 planes, textcolor=7
	mov	dx,offset palette2
	cmp	ax,1
	je	screenset10
	cmp	ax,801
	je	screenset10

;	mov	cx,0703h	;use 3 planes, textcolor=7
;	mov	dx,offset palette2
	cmp	ax,2
	je	screenset10
	cmp	ax,802
	je	screenset10

	mov	cx,0f04h	;use 4 planes, textcolor=15
	mov	dx,offset palette3
	cmp	ax,3
	je	screenset10
	cmp	ax,803
	je	screenset10

	mov	cx,0703h	;use 3 planes, textcolor=7
	mov	dx,offset paletteIBM2
	cmp	ax,_IBM1
	je	screenset10
	cmp	ax,_gxmax800+_IBM1
	je	screenset10

;	mov	cx,0703h	;use 3 planes, textcolor=7
;	mov	dx,offset paletteIBM2
	cmp	ax,_IBM2
	je	screenset10
	cmp	ax,_gxmax800+_IBM2
	je	screenset10

	mov	cx,0704h	;use 4 planes, textcolor=7
	mov	dx,offset paletteIBM3
	cmp	ax,_IBM3
	je	screenset10
	cmp	ax,_gxmax800+_IBM3
	je	screenset10

	jmp	screenilg
screenset10:
	mov	[UBvideomode],ax
	mov	[monocolormask],bl
	mov	[palettesetnow],dx

	mov	bx,_vmode12
	cmp	ax,_gxmax800
	jb	screenset20
	mov	bx,_vmode6a
screenset20:
	mov	[hardwarevideomode],bx

	mov	dl,1
	shl	dl,cl
	dec	dl
	mov	[planemask],dl
	mov	[whitenow],ch
	ret


;
; * screen
;
godefaultgraph:
	call	defaultgraph
	jmp	gomainlp2
screenreset:
	cmp	[graphflg],0
	je	godefaultgraph
	call	graphicinit
	jmp	gomainlp2

farscreenin:

	;1st

	mov	al,[bp]
	cmp	al,CR
	je	screenreset
	cmp	al,0c0h		;':'
	je	screenreset
	push	ax		;switch of view initialize
	cmp	al,0c2h		;','
	je	screen20

	call	getgrpparam
	call	screenmodeset
	call	graphicinit
	mov	ax,[UBvideomode]
	cmp	ax,10
	jb	screen12
	sub	ax,_gxmax800
	cmp	ax,10
	jae	screen15
screen12:
	call	setgXYsize98		;if 98 mode
screen15:

	cmp	byte ptr [bp],0c2h
	jne	screen120

	;start of 2nd
screen20:
	inc	bp
	cmp	byte ptr [bp],0c2h	;','
	je	screen30
	call	getgrpparam	;set active plane

	and	al,[planemask]
	mov	[activeplane],al
	mov	[gprcolor],al

	cmp	byte ptr [bp],0c2h	;','
	jne	screen100
screen30:
	;start of 3rd
	inc	bp
	call	getgrpparam	;set display plane

	and	al,[planemask]
	mov	[displplane],al

screen100:
	mov	ah,[activeplane]
	call	mapmask
	mov	ah,[displplane]
	call	selectdisplayplane
screen120:
	pop	ax		;switch of view initialize
	cmp	al,0c2h
	je	screen110
	call	selectpalette
	call	initviewparam
	jmp	gomainlp2

screen110:
	jmp	gomainlp2

screenilg:
	jmp	goilgerr


selectpalette:
	push	es
	mov	dx,cs
	mov	es,dx
	mov	dx,es:[palettesetnow]
	mov	ax,1002h
	int	10h

	mov	ah,ss:[whitenow]
	mov	byte ptr ss:[tcolor+1],ah
	pop	es
	ret


;
;* get world x-y
;
get_world_xy:
	cmp	byte ptr [bp],'('
	jne	get_world_xysynerr
get_world_xy10:
	inc	bp
get_world_xy20:
	call	get_world_x
	push	ax		;x
	cmp	byte ptr [bp],0c2h	;code of ,
	jne	get_world_xysynerr	
	inc	bp
	call	get_world_y

	cmp	byte ptr [bp],')'
	jne	get_world_xysynerr
	inc	bp
	pop	bx
	ret			;now bx=x,ax=y

get_world_xysynerr:
	jmp	gosynerr

;
;* get screen x-y
;
get_screen_xy:
	cmp	byte ptr [bp],'('
	jne	get_screen_xysynerr
get_screen_xy10:
	inc	bp
get_screen_xy20:
	call	get_screen_x
	push	ax		;x
	cmp	byte ptr [bp],0c2h	;code of ,
	jne	get_screen_xysynerr	
	inc	bp
	call	get_screen_y

	cmp	byte ptr [bp],')'
	jne	get_screen_xysynerr
	inc	bp
	pop	bx
	ret			;now bx=x,ax=y

get_screen_xysynerr:
	jmp	gosynerr


;
;*get color palette/tile pattern
;

getcolortile:
	call	far ptr farformul
	mov	si,[calcsp]
	lea	di,[si+UNITBYTE]
	mov	[calcsp],di
	lodsw
	test	ah,stringmaskhigh
	jz	getct105

	add	ax,ax
	sbb	ax,0
	and	ax,lenmask*2+1

	mov	[tilelength],ax
	mov	[tileaddress],si
	mov	ah,0ffh		;with tiling
	ret

getct105:
	or	ax,ax
	jz	getct107
	lodsw
	and	ax,000fh
getct107:
	mov	[paintcolor],al
	ret			;with palette


comment %
;
; x-size conversion of graphic plane
;
gxxfer:
	mov	bx,[gxmax]
	mov	cx,_gxmax98
	jmps	gxyxferin

;
; y-size conversion of graphic plane
;
gyxfer:
	mov	bx,[gymax]
	mov	cx,_gymax98

gxyxferin:
	push	bx
	push	cx
	call	far ptr farkakko
	pop	cx
	pop	bx
	mov	si,[calcsp]
	mov	ax,[si]
	cmp	ax,1
	jb	gxyxferret	;if 0
	jne	hcopy_ilg
	mov	ax,[si+2]
	cmp	ax,1000h	;max x,y = 1000h 
	ja	hcopy_ilg
	cmp	bx,cx
	je	gxyxferret
	inc	bx
	mul	bx
	inc	cx
	div	cx
	jmp	dotsetax
gxyxferret:
	jmp	dotsetret
%


;
; *graphic routine
;

farusegraph?:
	call	usegraph?
	retf

usegraph?:
  	cmp	[graphflg],0
  	je	defaultgraph
    	ret

defaultgraph:
	mov	[hardwarevideomode],_vmode12

	mov	[palettesetnow],offset paletteIBM3
	mov	[UBvideomode],_IBM3
	mov	[planemask],0fh	;4 planes

	mov	[whitenow],white
	mov	[monocolormask],0

graphicinit:
	xor	cx,cx
	mov	ch,[whitenow]
	mov	[gprcolor],ch
	mov	[tcolor],cx
	mov	[tcolor4fill],0
	mov	[gcolor],ch
	mov	[paintcolor],ch
	mov	[backcolor],black

	call	mysetvideomode
	pushf
	cmp	[UBvideomode],800
	jb	graphicinit50
	cmp	[hardwarevideomode],_vmode6a
	je	graphicinit50
	mov	[UBvideomode],_IBM3
graphicinit50:
	popf
	jc	graphicinitskip	;not changed the mode

	call	gsizeinitsub	; set gprint sizes
	call	resetXYinfo
	call	far ptr farclear_screen
graphicinitskip:
	call	consoledefault
	mov	ax,0
	mov	bx,0
	mov	cx,[gxmax]
	mov	dx,[gymax]
	call	setviewmainin
	mov	al,[planemask]
	mov	[displplane],al
	mov	[activeplane],al

	call	selectpalette

	mov	[linestylesw],0
	mov	[tilelength],0

	call	gregnormal
	ret


farreturn2text:
	call	return2text
	retf

return2text:
	cmp	[graphflg],0
	je	return2textout
	xor	ax,ax
	mov	al,[originalvideomode]
	int	10h
	mov	[graphflg],0
	mov	ah,white
	mov	byte ptr [tcolor+1],ah
	mov	byte ptr [tcolor4fill+1],ah
	call	resetXYinfo
	call	consoledefault
	mov	[xpos],0
	mov	[ypos],0
return2textout:
	ret


resetXYinfo:
	push	es
	xor	ax,ax
	mov	es,ax

	mov	ax,es:[044ah]
	mov	word ptr [chars1],ax	;must <= 255
	add	ax,ax
	mov	[chars2],ax
resetXYagain:
	xor	ax,ax
	mov	al,es:[0484h]
	mov	word ptr [btmline],ax
	inc	ax
	mov	word ptr [maxlinesnow],ax
	mov	word ptr [linesdef],ax
	mul	word ptr [chars2]
	mov	[charsall2],ax		;total chars*2

	add	ax,15
	my_shr	ax,4
	mov	cx,[vramsegover]
	sub	cx,ax
	cmp	cx,[arrayseg]
	jbe	resetXYmemoryerr
	mov	[vramsegnow],cx
	mov	[limitseg],cx

	mov	cx,[charsall2]		;clears vram
	shr	cx,1

	mov	ax,[vramsegnow]
	mov	es,ax
	xor	di,di
	mov	ax,white*100h
	rep	stosw

	pop	es
	ret

resetXYmemoryerr:
	mov	ax,[vramsegover]
	sub	ax,[arrayseg]
	dec	ax
	my_shl	ax,4
	xor	dx,dx
	div	[chars2]
	dec	al
	mov	es:[0484h],al
	jmp	resetXYagain


setgXYsize98:
	mov	ax,[gymax]	;make y-size 5/6
	inc	ax
	mov	dx,5
	mul	dx
	mov	bx,6
	div	bx
	dec	ax
	mov	[gymax],ax
	mov	[local_gymax],ax
	ret


;
;* get x,y coordinate considering window params
;


getparamx:
	jmp	getgrpparamin	;call & ret

get_world_x:
	call	far ptr farformul		;(+1)
	cmp	[windowsw],0
	je	get_world_x_out

	call	ahedsp2		;(+2)
	mov	di,si
	mov	si,worldx1
	call	windowload
	call	far ptr farsubin		;(+1)
	call	ahedsp2		;(+2)
	mov	di,si
	mov	si,worldxpro
	call	windowload
	call	far ptr farmulin		;(+1)
get_world_x_out:
	call	getgrpparamin
	add	ax,[viewx1]
	ret

get_screen_x:
	call	getgrpparam
	add	ax,[viewx1]
	ret


get_world_y:
	call	far ptr farformul
	cmp	[windowsw],0
	je	get_world_y_out

	call	ahedsp2
	mov	di,si
	mov	si,worldy1		;worldy2
	call	windowload
	call	far ptr farsubin
	call	ahedsp2
	mov	di,si
	mov	si,worldypro
	call	windowload
	call	far ptr farmulin
get_world_y_out:
	call	getgrpparamin
	jmps	get_screen_y_in

get_screen_y:
	call	getgrpparam
get_screen_y_in:
	cmp	[schoolflg],0
	jne	get_screen_y_school
	add	ax,[viewy1]
	ret
get_screen_y_school:
	sub	ax,[viewy2]
	neg	ax
	ret

		
;
; * line
;

farlinein:
	call	usegraph?
	mov	[linestylesw],0

	cmp	byte ptr [bp],0deh	;'-'
	jne	line20
	inc	bp
	mov	ax,[gposx]
	mov	[gX1],ax
	mov	ax,[gposy]
	mov	[gY1],ax
	jmp	line50		;1st param is default

linesynerr:
	jmp	gosynerr

line20:
	call	get_world_xy
	mov	[gX1],bx
	mov	[gY1],ax

	cmp	byte ptr [bp],0deh	;'-'
	jne	linesynerr
	inc	bp
line50:	
	call	get_world_xy
	mov	[gX2],bx
	mov	[gposx],bx	;x2
	mov	[gY2],ax
	mov	[gposy],ax	;y2

	cmp	byte ptr [bp],0c2h	;','
	jne	line100		;no other param
	inc	bp
	cmp	byte ptr [bp],0c2h	;','
	je	line100
	cmp	byte ptr [bp],'"'
	je	boxin10			;in priciple error

	call	getgrpparam
	mov	[gcolor],al
line100:
	cmp	byte ptr [bp],0c2h	;','
	je	boxin
line200:
	call	myline
	jmp	gomainlp2

linestyle:
	call	setlinestyle
	jmp	line200


boxin:
	inc	bp
	mov	al,[bp]
	cmp	al,0c2h
	je	linestyle
	cmp	al,'"'
	jne	boxsynerr
boxin10:
	mov	ax,[gX1]
	mov	[bX1],ax
	mov	ax,[gY1]
	mov	[bY1],ax
	mov	ax,[gX2]
	mov	[bX2],ax
	mov	ax,[gY2]
	mov	[bY2],ax

	inc	bp
	mov	al,[bp]
	or	al,20h
	cmp	al,'b'
	jne	boxsynerr
	inc	bp
	mov	al,[bp]
	cmp	al,'"'
	jne	boxfill
	inc	bp
	mov	al,[bp]
	cmp	al,0c2h
	jne	box50		;line style is assigned
	call	setlinestyle
box50:
	call	mybox
	jmp	gomainlp2


boxsynerr:
	jmp	gosynerr

boxfill:
	or	al,20h
	cmp	al,'f'
	jne	boxsynerr
	inc	bp
	cmp	byte ptr [bp],'"'
	jne	boxsynerr

	mov	[tilelength],0
	mov	al,[gcolor]
	mov	[paintcolor],al

	inc	bp
	cmp	byte ptr [bp],0c2h	;code of ,
	jne	boxfillgo		;paint color default
	inc	bp

	call	getcolortile
boxfillgo:
	call	myboxfill
	jmp	gomainlp2


setlinestyle:
	inc	bp
	call	far ptr farget_ax
	mov	dx,ax
	call	mysetlinestyle
	ret


;
; * pset
;

psetsynerr:
	jmp	gosynerr

farpsetin:
	call	usegraph?
pset10:
	call	get_world_xy
	mov	[gposx],bx	;x
	mov	[gposy],ax	;y
	mov	[gX],bx
	mov	[gY],ax

	cmp	byte ptr [bp],0c2h	;code of ,
	jne	pset100		;color default
	inc	bp
	call	getgrpparam
	mov	[gcolor],al
pset100:
	call	mypset
	jmp	gomainlp2


;
; * get pixel color
;   function
;

dotcolor:
	call	usegraph?
	call	get_world_xy20
	mov	[gposx],bx	;x
	mov	[gposy],ax	;y
	mov	[gX],bx
	mov	[gY],ax
	call	mypget
	call	ahedsp2
dotsetax:
	or	ax,ax
	jz	dot50
	mov	[si+2],ax
	mov	ax,1
dot50:
	mov	[si],ax		
dotsetret:
	jmp	far ptr returnadr


;
; * circle
;

farcirclein:
	call	usegraph?
	call	get_world_xy

	mov	[centerX],bx
	mov	[centerY],ax
	imul	[gxbytes]
	mov	[centerbaseadr],ax

	cmp	byte ptr [bp],0c2h	;code of ,
	jne	circlesynerr
	inc	bp

	mov	al,[gcolor]
	mov	[paintcolor],al
	mov	[tilelength],0

	;get x-radius

	cmp	byte ptr [bp],'('	;check (rx,ry) ?
	jne	circle70
	inc	bp
	call	circleradiusX
	mov	al,[bp]
	inc	bp
	cmp	al,')'
	je	circle90		;(r) type
	cmp	al,0c2h		;code of ,
	jne	circlesynerr
	call	circleradiusY
	cmp	byte ptr [bp],')'
	jne	circlesynerr
	inc	bp
	jmps	circle90

circle70:
	call	circleradiusX

	;get color

circle90:
	mov	al,[gcolor]
	cmp	byte ptr [bp],0c2h	;code of ,
	jne	circle92	;color default
	inc	bp
	cmp	byte ptr [bp],0c2h	;code of ,
	je	circle92	;color default
	call	getgrpparam
	mov	[gcolor],al
	mov	[paintcolor],al
circle92:
	cmp	byte ptr [bp],0c2h	;code of ,
	je	circle200

circle100:			;full circle without any operation
	cmp	[radius],0
	je	circle150
	call	myellipse
circle150:
	jmp	gomainlp2


circlesynerr:
	jmp	gosynerr

circle200:
	inc	bp
	cmp	byte ptr [bp],'"'
	je	circlefill	;full circle with paint

  	call	circlesub	;get start angle
	mov	[gX1],dx
	mov	[gY1],ax

	cmp	byte ptr [bp],0c2h
	jne	circlesynerr
	inc	bp

	call	circlesub	;get end angle
	mov	[gX2],dx
	mov	[gY2],ax

	cmp	byte ptr [bp],0c2h	;code of ,
	je	sectorfill
	cmp	[radius],0
	je	circle220
	call	myarc
circle220:
	jmp	gomainlp2

sectorfill:
	inc	bp
	cmp	byte ptr [bp],'"'
	jne	circlesynerr

sectorfill10:
	inc	bp
	mov	al,[bp]
	or	al,20h
	cmp	al,'f'
	jne	circlesynerr
	inc	bp
	cmp	byte ptr [bp],'"'
	jne	circlesynerr
	inc	bp
	cmp	byte ptr [bp],0c2h	;code of ,
	jne	circlesynerr
	inc	bp
	call	getcolortile
	cmp	[radius],0
	je	sectorfill20
	call	mysectorfill
sectorfill20:
	jmp	gomainlp2

circlefill:
	inc	bp
	mov	al,[bp]
	or	al,20h
	cmp	al,'f'
	jne	circlesynerr
	inc	bp
	cmp	byte ptr [bp],'"'
	jne	circlesynerr
	inc	bp
	cmp	byte ptr [bp],0c2h	;code of ,
	jne	circlesynerr
	inc	bp
	call	getcolortile
	cmp	[radius],0
	je	circlefill20
	call	myellipsefill
circlefill20:
	jmp	gomainlp2


circleradiusX:
	cmp	[windowsw],0
	jne	circleradiusX50
	call	getgrpparam
	mov	[radiusX],ax
	mov	[radius],ax
	jmps	circleradiusX80

circleradiusX50:
	call	far ptr farformul		;(+1)
	call	ahedsp2		;(+2)
	mov	di,si
	add	si,unitbyte
	mov	cx,[si]
	and	cx,lenmask
	inc	cx
	rep	movsw
	call	ahedsp2		;(+3)
	mov	di,si
	mov	si,worldxpro
	call	windowload
	call	far ptr farmulin		;(+2)
	call	getgrpparamin	;(+1)
	test	ah,signmaskhigh		;let positive
	jz	circleradiusX70
	neg	ax
circleradiusX70:
	mov	[radiusX],ax

circleradiusX75:
	call	ahedsp2		;(+2)
	mov	di,si
	mov	si,worldypro
	call	windowload
	call	far ptr farmulin		;(+1)
	call	getgrpparamin	;(0)
	test	ah,signmaskhigh		;let positive
	jz	circleradiusX80
	neg	ax

circleradiusX80:
	mov	[radiusY],ax
	cmp	ax,[radiusX]
	jae	circleradiusX85
	mov	ax,[radiusX]
circleradiusX85:
	mov	[radius],ax
	ret


circleradiusY:
	cmp	[windowsw],0
	jne	circleradiusY50
	call	getgrpparam
	jmps	circleradiusX80

circleradiusY50:
	call	far ptr farformul		;(+1)
	jmp	circleradiusX75


circlesub:			;if parameters contain angle
	call	get_fx2

	mov	[angle_int],dx
	mov	[angle_frac],ax
	
	call	cosDW
	test	dl,1		;check +-1?
	jz	circlesub80	;no

	mov	ax,0ffffh	;(10000h is better)
circlesub80:
	shr	ax,1		;non using carry
	test	dh,signmaskhigh		;check sign
	jz	circlesub90
	neg	ax
circlesub90:
	push	ax		;x-part

	mov	dx,[angle_int]
	mov	ax,[angle_frac]

	call	sinDW
	test	dl,1
	jz	circlesub180
	mov	ax,0ffffh	;(10000h is better)
circlesub180:
	shr	ax,1		;non using carry
	test	dh,signmaskhigh		;check sign
	jnz	circlesub190
	neg	ax
circlesub190:
	pop	dx		;x-part
	add	[calcsp],unitbyte
	ret


	;
	;* get_fx2
	; out dx:ax 32bits fixed point
	;     dx = integer part : MSB=sign

get_fx2:
	push	bx
	push	cx
	push	si
	push	di

	call	far ptr farformul

	mov	bx,[calcsp]
	call	far ptr farreal2floatbxjust

	xor	dx,dx		;integer part
	mov	si,[calcsp]
  	mov	ax,[si]
	or	ax,ax
	jz	get_fxret	;if 0

	mov	bx,ax		;memo sign

	mov	cx,[si+2]	;exp
	inc	cx
	and	ax,lenmask
	add	si,ax
	add	si,ax		;MSW
	xor	ax,ax
	or	cx,cx
	jl	get_fxret	;ans = 0
	jnz	get_fx10
	mov	al,[si+1]
	jmps	get_fx100
get_fx10:
	dec	cx
	jnz	get_fx20
	mov	ax,[si]
	jmps	get_fx100
get_fx20:
	dec	cx
	jnz	get_fx30
	mov	ax,[si-1]
	mov	dl,[si+1]
	jmps	get_fx100
get_fx30:
	dec	cx
	jnz	get_fxover
	mov	ax,[si-2]
	mov	dx,[si]
	test	dh,signmaskhigh
	jnz	get_fxover
get_fx100:
	and	bh,signmaskhigh		;get sign
	or	dh,bh
get_fxret:
	pop	di
	pop	si
	pop	cx
	pop	bx
	ret

get_fxover:
	mov	dx,07fffh
	mov	ax,0ffffh
	jmp	get_fx100


	;cosine for graphic
	;32bit fixed point format
	; inp, out : DX = integer part(MSB=sign)
	;            AX = fractional part
cosDW:
	push	bx
	push	cx
	push	si
	push	di

	xor	cx,cx			;for sign
	and	dh,7fh			;cut sign
	shr	dx,1
	rcr	ax,1
	shr	dx,1
	rcr	ax,1
	mov	bx,PI16bit		;2bits for int, 14bits for frac
	div	bx
	test	al,1
	jz	cosDW20
	xor	ch,signmaskhigh			;change sign
cosDW20:
	mov	ax,dx
	mov	dx,bx
	sub	dx,ax			;ax=x,dx=pi-x
	cmp	ax,dx
	jbe	cosDW30
	mov	ax,dx
	xor	ch,signmaskhigh			;change sign
cosDW30:
	shr	bx,1			;pi/2
	mov	dx,bx
	sub	dx,ax			;ax=x,dx=pi/2-x
	cmp	ax,dx
	jbe	cosDW50
	mov	ax,dx
	jmp	sinDW50
cosDW50:
	; first calc x-x^3/4/3+x^5/6/5/4/3+...

	add	ax,ax
	add	ax,ax			;16bits for frac

	push	ax			;*
	mov	si,ax			;initial value
	mul	ax
	mov	di,dx			;memo square
	mov	ax,si			;initial term
	mov	bx,2
cosDWlp:
	or	ax,ax
	jz	cosDWjp

	inc	bx
	xor	dx,dx
	div	bx
	inc	bx
	xor	dx,dx
	div	bx
	mul	di
	mov	ax,dx
	sub	si,ax

	inc	bx
	xor	dx,dx
	div	bx
	inc	bx
	xor	dx,dx
	div	bx
	mul	di
	mov	ax,dx
	add	si,ax
	jmp	cosDWlp
cosDWjp:
	;next mul x and div by 2

	pop	ax			;*
	mul	si
	mov	ax,dx
	shr	ax,1

	;and subtract from 1

	mov	dx,cx			;set sign
	neg	ax
;	or	ax,ax
	jnz	cosDWret
	inc	dx
cosDWret:
	pop	di
	pop	si
	pop	cx
	pop	bx
	ret

	;sine for graphic
	;32bit fixed point format
	; DX = integer part(MSB=sign)
	; AX = fractional part
sinDW:
	push	bx
	push	cx
	push	si
	push	di

	mov	cx,dx
	and	cx,8000h		;set sign
	and	dh,7fh			;cut sign
	shr	dx,1
	rcr	ax,1
	shr	dx,1
	rcr	ax,1
	mov	bx,PI16bit		;2bits for int, 14bits for frac
	div	bx
	test	al,1
	jz	sinDW20
	xor	ch,signmaskhigh			;change sign
sinDW20:
	mov	ax,dx
	mov	dx,bx
	sub	dx,ax			;ax=x,dx=pi-x
	cmp	ax,dx
	jbe	sinDW30
	mov	ax,dx
sinDW30:
	shr	bx,1			;pi/2
	mov	dx,bx
	sub	dx,ax
	cmp	ax,dx			;ax=x,dx=pi/2-x
	jbe	sinDW50
	mov	ax,dx
	jmp	cosDW50
sinDW50:
	add	ax,ax
	add	ax,ax			;16bits for frac

	; first calc x^2-x^4/5/4+x^6/7/6/5/4-...

	push	ax			;*
	mul	ax
	mov	di,dx			;memo square
	mov	si,dx			;initial value
	mov	ax,dx			;initial term
	mov	bx,3
sinDWlp:
	or	ax,ax
	jz	sinDWjp

	inc	bx
	xor	dx,dx
	div	bx
	inc	bx
	xor	dx,dx
	div	bx
	mul	di
	mov	ax,dx
	sub	si,ax

	inc	bx
	xor	dx,dx
	div	bx
	inc	bx
	xor	dx,dx
	div	bx
	mul	di
	mov	ax,dx
	add	si,ax
	jmp	sinDWlp
sinDWjp:
	; next div by 2*3

	xor	dx,dx
	mov	ax,si
	mov	bx,6
	div	bx

	; and mul x

	pop	bx			;*
	mul	bx
	mov	ax,dx

	; and subtract from x

	sub	ax,bx
	neg	ax

	mov	dx,cx			;sign
	or	ax,ax
	jnz	sinDWret
	xor	dx,dx			;avoid 8000:0000
sinDWret:
	pop	di
	pop	si
	pop	cx
	pop	bx
	ret


;
; * paint
;

paintsynerr:
	jmp	gosynerr
paintilgerr:
	jmp	goilgerr

farpaintin:
	call	usegraph?
	call	get_world_xy
	mov	[gX],bx
	mov	[gY],ax

	mov	al,[gcolor]
	mov	[paintcolor],al
	mov	[bordercolor],al

	mov	[tilelength],0

	cmp	byte ptr [bp],0c2h	;code of ,
	jne	paint110		;all default
	inc	bp
	cmp	byte ptr [bp],0c2h	;code of ,
	je	paint110

	call	getcolortile
paint110:
	cmp	byte ptr [bp],0c2h	;code of ,
	jne	paint200
	inc	bp
	sub	[calcsp],UNITBYTE	;to protect tile pattern
	call	getgrpparam		;get border color
	mov	[bordercolor],al
	add	[calcsp],UNITBYTE
paint200:
	mov	ax,[gX]
	cmp	ax,[viewX2]
	jg	paintskip		;do nothing
	cmp	ax,[viewX1]
	jl	paintskip		;do nothing
	mov	ax,[gY]
	cmp	ax,[viewY2]
	jg	paintskip		;do nothing
	cmp	ax,[viewY1]
	jl	paintskip		;do nothing
	call	mypaint
paintskip:
	jmp	gomainlp2


;
; * view
;
viewinit?:
	cmp	al,CR
	je	viewinit
	cmp	al,0c0h		;code of ':'
	jne	viewsynerr
viewinit:
	call	initviewparam
	jmp	gomainlp2

farviewin:
  if flggprint
	mov	[chxpos],0
	mov	[chypos],0
  endif
	call	usegraph?
	mov	al,[bp]
	cmp	al,'('
	jne	viewinit?
	inc	bp
	call	getgrpparam
	cmp	ax,[gxmax]
	jae	viewilg
	mov	[viewx1memo],ax
	cmp	byte ptr [bp],0c2h	;code of ,
	jne	viewsynerr	
	inc	bp
	call	getgrpparam
	cmp	ax,[gymax]
	jae	viewilg
	mov	[viewy1memo],ax
	cmp	byte ptr [bp],')'
	jne	viewsynerr
	inc	bp
	cmp	byte ptr [bp],0deh		;'-'
	je	view50
viewsynerr:
	call	initviewparam
	jmp	gosynerr
viewilg:
	call	initviewparam
	jmp	goilgerr

view50:
	inc	bp
	cmp	byte ptr [bp],'('
	jne	viewsynerr
	inc	bp
	call	getgrpparam
	cmp	ax,[gxmax]
	jbe	view60
	mov	ax,[gxmax]
view60:
	mov	dx,ax
	sub	ax,[viewx1memo]
	jb	viewilg
	cmp	ax,17		;minimum=17
	jb	viewilg
	mov	[viewx2memo],dx
	cmp	byte ptr [bp],0c2h	;code of ,
	jne	viewsynerr	
	inc	bp
	call	getgrpparam
	cmp	ax,[gymax]
	jbe	view70
	mov	ax,[gymax]
view70:
	mov	dx,ax
	sub	ax,[viewy1memo]
	jb	viewilg
	cmp	ax,17		;minimum=17
	jb	viewilg
	mov	[viewy2memo],dx

	cmp	byte ptr [bp],')'
	jne	viewsynerr
	inc	bp

	cmp	[schoolflg],0
	je	view100
	mov	ax,[gymax]
	sub	ax,[viewy1memo]
	xchg	ax,[viewy2memo]
	sub	ax,[gymax]
	neg	ax
	mov	[viewy1memo],ax
view100:
	cmp	byte ptr [bp],0c2h	;code of ,
	jne	viewout

	;set colors

	call	initviewparam
	inc	bp
	cmp	byte ptr [bp],0c2h	;code of ,
	je	view75			;no paint

	call	getgrpparam
	mov	[gcolor],al
	mov	[paintcolor],al

	mov	ax,[viewx1memo]
	mov	[bX1],ax
	mov	ax,[viewy1memo]
	mov	[bY1],ax
	mov	ax,[viewx2memo]
	mov	[bX2],ax
	mov	ax,[viewy2memo]
	mov	[bY2],ax
	push	word ptr [linestylesw]
	mov	[linestylesw],0
	mov	[tilelength],0
	call	myboxfill
	pop	word ptr [linestylesw]

	cmp	byte ptr [bp],0c2h	;code of ,
	jne	viewout
view75:
	inc	bp
	call	getgrpparam
	mov	[gcolor],al

	mov	ax,[viewx1memo]
	dec	ax
	mov	[bX1],ax
	mov	ax,[viewy1memo]
	dec	ax
	mov	[bY1],ax
	mov	ax,[viewx2memo]
	inc	ax
	mov	[bX2],ax
	mov	ax,[viewy2memo]
	inc	ax
	mov	[bY2],ax
	push	word ptr [linestylesw]
	mov	[linestylesw],0
	call	mybox
	pop	word ptr [linestylesw]

viewout:
	;set view

	mov	ax,[viewx2memo]
	sub	ax,[viewx1memo]
	inc	ax
	shr	ax,1
	cmp	ax,word ptr [gwidth]
	jb	viewsizemismatch
	cmp	ax,word ptr [gwidth2]
	jb	viewsizemismatch
	mov	ax,[viewy2memo]
	sub	ax,[viewy1memo]
	inc	ax
	cmp	ax,word ptr [gheight]
	jb	viewsizemismatch
	cmp	ax,word ptr [gheight2]
	jb	viewsizemismatch

	mov	ax,[viewx1memo]
	mov	bx,[viewy1memo]
	mov	cx,[viewx2memo]
	mov	dx,[viewy2memo]
	call	setviewmain

	mov	[windowsw],0

viewout100:
  	jmp	gomainlp2

viewsizemismatch:
	call	far ptr fargsizeinit
	jmp	goilgerr


;
; * window
;

farwindowin:
	call	usegraph?
	mov	[windowsw],-1

	cmp	byte ptr [bp],'('
	jne	windowsynerr
	inc	bp
	call	far ptr farformul
	mov	di,worldx1
	call	windowstore
	cmp	byte ptr [bp],0c2h	;code of ,
	jne	windowsynerr	
	inc	bp
	call	far ptr farkakko
	mov	di,worldy1
	call	windowstore
	cmp	byte ptr [bp],0deh	;'-'
	je	window50
windowsynerr:
	jmp	gosynerr

window50:
	inc	bp
	cmp	byte ptr [bp],'('
	jne	windowsynerr
	inc	bp
	call	far ptr farformul
	mov	di,worldx2
	call	windowstore
	cmp	byte ptr [bp],0c2h	;code of ,
	jne	windowsynerr	
	inc	bp
	call	far ptr farkakko
	mov	di,worldy2
	call	windowstore

	call	windowsub
	jmp	gomainlp2


windowsub:
	;set (x2-x1)/(wx2-wx1)

	call	ahedsp2		;(+1)
	mov	word ptr [si],1
	mov	ax,[viewx2]
	sub	ax,[viewx1]
	mov	[si+2],ax

	call	ahedsp2		;(+2)
	mov	di,si
	mov	si,worldx2
	call	windowload

	call	ahedsp2		;(+3)
	mov	di,si
	mov	si,worldx1
	call	windowload

	call	far ptr farsubin		;(+2)
	call	far ptr fardivin		;(+1)
	mov	di,worldxpro
	call	windowstore	;(0)

	;set (y2-y1)/(wy2-wy1)

	call	ahedsp2		;(+1)
	mov	word ptr [si],1
	mov	ax,[viewy2]
	sub	ax,[viewy1]
	mov	[si+2],ax

	call	ahedsp2		;(+2)
	mov	di,si
	mov	si,worldy2
	call	windowload

	call	ahedsp2		;(+3)
	mov	di,si
	mov	si,worldy1
	call	windowload

	call	far ptr farsubin		;(+2)
	call	far ptr fardivin		;(+1)
	mov	di,worldypro
	call	windowstore	;(0)
	ret


windowstore:
	call	far ptr farfuncset
	mov	ax,[calcsp]
	mov	si,ax
	add	ax,unitbyte
	mov	[calcsp],ax

  	mov	ax,windowseg
  if FLG98
  else
  	add	ax,DATA
  endif
	mov	es,ax

	mov	ax,[si]
	mov	cx,ax
	jcxz	winstorejp	;if 0

	and	ax,signmask
	or	ax,pointmask+3
winstorejp:
	stosw
	mov	ax,[si+2]
	stosw			;exp
	and	cx,lenmask
	dec	cx
	add	cx,cx
	add	si,cx
	movsw			;store higher 2 words
	movsw
	smov	es,ss
	ret

windowload:
	mov	ax,windowseg
  if FLG98
  else
    	add	ax,DATA
  endif
	mov	ds,ax
	lodsw
	or	ax,ax
	jz	winloadjp	;if 0
	and	ax,signmask
	or	ax,pointmask+5
winloadjp:
	stosw
	movsw			;exp
	xor	ax,ax
	stosw			;fill by 0
	stosw
	movsw
	movsw
	smov	ds,ss
	ret


cleargraphic:
	call	myclearviewarea
	mov	[chxpos],0
	mov	[chypos],0
	jmp	gomainlp2


initviewparam:
	mov	[windowsw],0
	mov	ax,0
	mov	bx,0
	mov	cx,[gxmax]
	mov	dx,[gymax]
	call	setviewmain
	ret


fontreaddummy:
	retf


	public	getfontserver

  if JAPANESE
	extrn	farSJIS_JIS:far
  endif

getfontserver:
	push	es

  if JAPANESE
	mov	ax,offset fontreaddummy
	mov	[ankfontread],ax
	mov	[kanjifontread],ax
	mov	[ankfontread+2],cs
	mov	[kanjifontread+2],cs

	mov	ax,5000h		;get font read adr
	xor	bx,bx
	mov	dh,ankwidthL
	mov	dl,heightL
	xor	bp,bp
	int	15h
	jc	gprinit45
	mov	[ankfontread],bx
	mov	[ankfontread+2],es
gprinit45:
	mov	ax,5000h		;get font read adr
	mov	bx,0100h
	mov	dh,ankwidthL*2
	mov	dl,heightL
	xor	bp,bp
	int	15h
	jc	ginit55
	mov	[kanjifontread],bx
	mov	[kanjifontread+2],es
ginit55:

  else
	push	bp
	mov	ax,1130h
	mov	bh,6			;VGA font
	int	10h
	mov	[ankfontread],bp
	mov	[ankfontread+2],es
	pop	bp
  endif
	pop	es
	retf


;
; * set draw color for gprint
;
gcolorilg:
	jmp	ex3ilgerr

gcolorin:
	call	far ptr farget_ax
	jnc	gcolor10
	or	al,signmaskhigh
gcolor10:
	mov	[gprcolor],al
	jmp	gomainlp2


;
;* graphic ram load
;

gattribbytes1	equ	16
gattribbytes	equ	16*gattribbytes1
planebytes	equ	80*400		;bytes/plane <2^16


gloadmsg	db	'gload ',0

gloadcannot:
	jmp	far ptr workfull
gloaddiskerr:
	cmp	ax,2
	je	gloadnofile
	jmp	far ptr DISKERR
gloadnofile:
	jmp	far ptr NOFILE
gloaderror:
	cmp	ah,1
	je	gloadnofile
;	cmp	ah,5
	jmp	far ptr ready		;canceled

gload:
  if GRAPH
    if FLGIBMTOS
	call	return2text
	call	far ptr farcursoff
    endif
  endif
	mov	ax,[limitseg]
	sub	ax,[arrayseg]
	cmp	ax,1000h		;>gattribbytes+2*planebytes
	jb	gloadcannot		;lack of work area

	mov	di,offset fnamebuf
	cmp	byte ptr [bp],CR
	je	gload5
	CALL	far ptr farSETFNAME	;PATH 名を得る
	jnc	gload10
gload5:
	call	gloadgetfilename
	jc	gloaderror
	xor	ax,ax
gload10:
	or	ah,ah
	jnz	gload15		;extension is assigned
	CALL	EXTUBP2		;EXTENSION を UBP に
gload15:
	mov	dx,offset gloadmsg
	call	msg_cs2
	call	gload_dispfilename
	call	letnl2

	mov	dx,offset FNAMEBUF
	mov	ah,3dh
	xor	al,al
	int	21h		;open file for read
	jc	gloaddiskerr

	mov	[handle],ax
	call	ahedsp2		;si=top of work area

	mov	bx,[handle]
	mov	ah,3fh		;read attribute	
	mov	dx,si
	mov	cx,gattribbytes
	int	21h

	call	gloadsetvideomode
	call	mygload

	mov	bx,[handle]
	mov	ah,3eh		;close handle
	int	21h

	add	[calcsp],UNITBYTE
	jmp	gomainlp2


gloadsetvideomode:
	;check graphic size

	mov	ax,[si]
	add	ax,[si+gattribbytes1*8]
	xor	dx,dx
	mov	bx,_gxbytes98
	div	bx		;lines
	mov	bx,ax
	mov	ax,3		;98 normal
	cmp	bx,400		;_gymax98+1
	je	gsetvmode50
	mov	ax,_IBM3
	cmp	bx,480
	jbe	gsetvmode50	;includes 0
	mov	ax,803
	cmp	bx,500
	je	gsetvmode50
	mov	ax,_gxmax800+_IBM3
gsetvmode50:
	call	screenmodeset
	call	graphicinit
	mov	ax,[UBvideomode]
	cmp	ax,10
	jb	gsetvmode62
	sub	ax,_gxmax800
	cmp	ax,10
	jae	gsetvmode65
gsetvmode62:
	call	setgXYsize98		;if 98 mode
gsetvmode65:
	call	selectpalette
	call	initviewparam
	ret


gload_dispfilename:
	mov	al,'"'
	call	prchr2
	mov	dx,offset fnamebuf
	call	msg2
	mov	al,'"'
	jmp	prchr2		;call & ret


;
;* graphic ram save
;

gsavesynerr:
	jmp	ex3synerr
gsavecannot:
	jmp	far ptr workfull
gsavediskerr:
	jmp	far ptr DISKERR

gsave:
	mov	ax,[limitseg]
	sub	ax,[arrayseg]
	cmp	ax,1000h		;>gattribbytes+2*planebytes
	jb	gsavecannot		;lack of work area

	mov	di,offset fnamebuf
;	cmp	byte ptr [bp],'"'
;	jne	gsave5
	CALL	far ptr farSETFNAME	;PATH 名を得る
	jnc	gsave10
gsave5:
	call	setfname_time
gsave10:
	or	ah,ah
	jnz	gsave15		;extension is assigned
	CALL	EXTUBP2		;EXTENSION を UBP に
gsave15:
	CMP	BYTE PTR [BP],0C2H	;','
	JNE	gSAVE20
	INC	BP
	CMP	BYTE PTR [BP],'"'
	JNE	gSAVESYNERR
	INC	BP
	mov	al,[bp]
	or	al,20h
	cmp	al,"n"
	jne	gsavesynerr
	inc	bp
	CMP	BYTE PTR [BP],'"'
	JNE	gSAVESYNERR
	INC	BP		

	mov	dx,offset FNAMEBUF
	mov	ah,41h		;del file
	int	21h
	jnc	gsave20
	cmp	ax,2
	jne	gsavediskerr

gsave20:
	call	checkoldfile	;open/create set [handle]
	jc	gsaveout
	call	ahedsp2		;si=top of work area
				;work area is used for attribute area
	mov	bx,[handle]
	mov	di,si
	xor	ax,ax
	mov	cx,gattribbytes/2
	rep	stosw

	mov	ah,42h		;move file pointer
	mov	dx,gattribbytes
	mov	al,0
	int	21h

	call	mygsave
	jc	gsaveerr

	mov	bx,[handle]
	mov	ah,42h		;move file pointer
	mov	dx,0		;move to file top
	mov	cx,0
	mov	al,0
	int	21h

	mov	ah,40h		;write handle
	mov	dx,[calcsp]
	mov	cx,gattribbytes
	int	21h
	cmp	ax,cx
	jne	gsaveerr

	mov	ah,3eh		;close handle
	int	21h

	add	[calcsp],UNITBYTE
gsaveout:
	call	gregnormal
	jmp	gomainlp2	;** exit

gsaveerr:
	mov	ah,3eh		;close file
	int	21h
	jmp	far ptr diskerr


;
;* locate gprint pointer
;
glocate:
	call	far ptr farGET_XY
	mov	ax,[x_loc]
	cmp	ax,-1
	je	glocate15
	cmp	ax,[local_gxmax]
	jbe	glocate10
	mov	ax,[local_gxmax]
glocate10:
	mov	[chxpos],ax
glocate15:
	mov	ax,[y_loc]
	cmp	ax,-1
	je	glocate25
	cmp	ax,[local_gymax]
	jbe	glocate20
	mov	ax,[local_gymax]
glocate20:
	cmp	[schoolflg],0
	je	glocate22
	sub	ax,[local_gymax]
	neg	ax
	sub	ax,[gheight]
glocate22:
	mov	[chypos],ax
glocate25:
	jmp	gomainlp2


gprint:
	call	mygprintset
	mov	[gprkanji1st],0
	mov	ah,bit5		;out_device select bit
	jmp	far ptr print2


fargprintstring:
	mov	si,[calcsp]
	lodsw
	add	ax,ax
	sbb	ax,0
	and	ax,2*lenmask+1
	jz	gprstrend

	mov	[gprpoint],si
	mov	[gprbytes],ax

	call	ahedsp2

gprstrlp:
	call	gprintstringsub
	cmp	[gprbytes],0
	jg	gprstrlp

	add	[calcsp],UNITBYTE
gprstrend:
	retf

gprintstringsub:
	mov	si,[gprpoint]
	lodsb
	mov	[gprpoint],si
	dec	[gprbytes]

	cmp	al,'\'
	je	gprnoncontrol	;call & ret
	cmp	[TeXFlg],0
	je	gprintstringnonTeX
	cmp	al,'^'
	je	gprhalfup	;call & ret
	cmp	al,'_'
	je	gprhalfdown	;call & ret
gprintstringnonTeX:
  if JAPANESE
  	call	far ptr farKANJI1ST?
	jmpnc	gprintank	;call & ret
	mov	ah,al
	mov	si,[gprpoint]
	lodsb
	mov	[gprpoint],si
	dec	[gprbytes]
	jmp	gprintkanji	
  else
	jmp	gprintank
  endif


gprnoncontrol:
	mov	si,[gprpoint]
	lodsb			;next char
	call	gprintAL
	mov	[gprpoint],si
	dec	[gprbytes]
	ret

	;
	;* half up
	;
gprhalfup:
	push	[chxpos]		;*
	push	[chypos]

	mov	ax,[chypos]
	sub	ax,[halfgheight]
	jb	gprhalfup10
	mov	[chypos],ax
gprhalfup10:
	mov	si,[gprpoint]
	cmp	byte ptr [si],'{'
	je	gprhalfup20
	call	gprintstringsub	;1 character case

gprhalfupret:
	mov	ax,[chypos]
	add	ax,[halfgheight]
	add	ax,[gheight]
	cmp	ax,[local_gymax]
	ja	gprhalfupret10
	sub	ax,[gheight]
	mov	[chypos],ax
gprhalfupret10:
	mov	si,[gprpoint]
	cmp	byte ptr [si],'_'
	je	gprhalfupret20	

	add	sp,4		;* dummy
	ret
gprhalfupret20:
	pop	[chypos]		;*
	pop	[chxpos]
	ret


gprhalfup20:
	inc	[gprpoint]
	dec	[gprbytes]
	jz	gprhalfupret		;error = only { 
gprhalfup30:
	call	gprintstringsub
	cmp	byte ptr [gprbytes],0
	je	gprhalfupret		;error = only {
	mov	si,[gprpoint]
	cmp	byte ptr [si],'}'
	jne	gprhalfup30
	inc	[gprpoint]
	dec	[gprbytes]
	jmp	gprhalfupret

	;
	;* half down
	;
gprhalfdown:
	push	[chxpos]		;*
	push	[chypos]

	mov	ax,[chypos]
	add	ax,[halfgheight]
	mov	si,[gymax]
	inc	si
	sub	si,[height]
	cmp	ax,si		;cmp	ax,gymax+1-height
	ja	gprhalfdown10
	mov	[chypos],ax
gprhalfdown10:
	mov	si,[gprpoint]
	cmp	byte ptr [si],'{'
	je	gprhalfdown20
	call	gprintstringsub	;1 character case

gprhalfdownret:
	mov	ax,[chypos]
	sub	ax,[halfgheight]
	jb	gprhalfdownret10
	mov	[chypos],ax
gprhalfdownret10:
	mov	si,[gprpoint]
	cmp	byte ptr [si],'^'
	je	gprhalfdownret20	

	add	sp,4		;* dummy
	ret
gprhalfdownret20:
	pop	[chypos]		;*
	pop	[chxpos]
	ret


gprhalfdown20:
	inc	[gprpoint]
	dec	[gprbytes]
	jz	gprhalfdownret		;error = only { 
gprhalfdown30:
	call	gprintstringsub
	cmp	byte ptr [gprbytes],0
	je	gprhalfdownret		;error = only {
	mov	si,[gprpoint]
	cmp	byte ptr [si],'}'
	jne	gprhalfdown30
	inc	[gprpoint]
	dec	[gprbytes]
	jmp	gprhalfdownret


farGPRINTCHAR:			;non TeX mode
	push	ds
	push	es
	push	ax
	push	si
	push	di
	mov	si,ss
	mov	ds,si
	mov	es,si

	call	ahedsp2
	call	gprintAL
	add	[calcsp],UNITBYTE

	pop	di
	pop	si
	pop	ax
	pop	es
	pop	ds
	retf

gprCR:
	mov	[chxpos],0
	jmp	gprintankret

gprLF:
	mov	ax,[gheight2]
	add	[chypos],ax
	jmp	gprintankret

gprTAB:
	mov	ax,[gwidth]
	call	getgpradr			;getgp??
	xor	dx,dx
	mov	ax,[chxpos]
	mov	bx,[gwidth2]
	add	ax,bx
	dec	ax
	div	bx
	add	ax,8
	and	ax,0fff8h
	mul	bx
	mov	[chxpos],ax
	jmp	gprintankret

gprRIGHTERASE:
	push	[viewX1]
	push	[viewY1]
	push	[viewY2]
	
	mov	ax,[chxpos]
	mov	[viewX1],ax
	mov	ax,[chypos]
	mov	[viewY1],ax
	dec	ax
	add	ax,[gheight2]
	cmp	ax,[viewY2]
	ja	gprrighterasejp
	mov	[viewY2],ax
gprrighterasejp:
	call	myclearviewarea

	pop	[viewY2]
	pop	[viewY1]
	pop	[viewX1]
	jmp	gprintankret


gprankctrl:
	cmp	al,CR
	je	gprCR
	cmp	al,LF
	je	gprLF
	cmp	al,TAB
	je	gprTAB
	cmp	al,CTRL_Y
	je	gprRIGHTERASE
	jmp	gprintankret


gprintAL:
  if JAPANESE
  	mov	ah,[gprkanji1st]
	or	ah,ah
	jmpnz	gprintkanji		;call & ret
	call	far ptr farKANJI1ST?
	jmpnc	gprintank		;call & ret
	mov	[gprkanji1st],al
	ret
  endif

gprintank:
  if flg32
	pusha
  else
	push	ax
	push	bx
	push	cx
	push	dx
	push	di
  endif
	cmp	al,020h
	jb	gprankctrl
	push	ax
	mov	ax,[gwidth]
	call	getgpradr
	call	setgprmode
	pop	ax
	call	getankfont
	call	setankfont
	mov	ax,[gwidth2]
	add	[chxpos],ax
gprintankret:
  if flg32
	popa
  else
	pop	di
	pop	dx
	pop	cx
	pop	bx
	pop	ax
  endif
	ret


  if JAPANESE
;
; * gprint kanji
;
gprintkanji:
	mov	[gprkanji1st],0
  if flg32
	pusha
  else
	push	ax
	push	bx
	push	cx
	push	dx
	push	di
  endif
gprintkanji_in:			;jumped from noncontrol
	push	ax
	mov	ax,[gwidth]
	add	ax,ax
	call	getgpradr
	call	setgprmode
	pop	ax
	call	getkanjifont
	call	setkanjifont
	mov	ax,[gwidth2]
	add	ax,ax
	add	[chxpos],ax
	jmp	gprintankret
  endif



;
; get gram offset from chxpos/chypos
;
getgpradr:
	mov	bx,ax
	add	ax,[chxpos]
	mov	dx,[local_gxmax]
	inc	dx
	sub	ax,dx
	jbe	getgpradr20

	mov	[chxpos],0	;check next line
	mov	ax,[chypos]
	add	ax,[gheight2]
	mov	[chypos],ax
	mov	dx,[local_gymax]
	inc	dx
	cmp	ax,dx
	jbe	getgpradr20
	mov	ax,[gheight2]
	sub	[chypos],ax
	call	mygscrollud
getgpradr20:			;now x-position ok, y-position ?
	mov	ax,[chypos]
	mov	dx,[local_gymax]
	inc	dx
	sub	dx,[gheight]
	cmp	ax,dx
	jbe	getgpradr30	;can write
	mov	[chxpos],0
	mov	ax,[gheight2]
	sub	[chypos],ax
	call	mygscrollud
	jmp	getgpradr20
getgpradr30:
	mov	ax,[gxbytes]
	mov	dx,[chypos]
	add	dx,[viewy1]
	mul	dx
	mov	bx,ax
	mov	ax,[chxpos]
	add	ax,[viewx1]
	mov	cx,ax
	my_shr	ax,3
	add	ax,bx
	mov	[gpradr],ax
	and	cx,7
	mov	[gproffset],cl
	mov	ax,00ffh
	jcxz	getgpradr100

	mov	ch,cl		;memo
	mov	ah,8
	sub	ah,cl
	mov	cl,ah
	mov	al,1
	shl	al,cl
	dec	al
	mov	ah,al
	not	ah
getgpradr100:
	mov	[gprmask1st],al
	mov	[gprmask2nd],ah
	ret


;
;* roll up/down graphic ram
;
rollin:
	cmp	byte ptr [bp],0c2h	;,
	je	roll110
	call	farFORMUL
	backsp_mac
	lodsw
	mov	dh,ah
	and	ah,attribmaskhigh
	jnz	rollilgerr
	and	ax,lenmask
	jz	roll100
	mov	cx,[local_gymax]
	inc	cx
	cmp	ax,1
	jne	roll40
	lodsw
	cmp	ax,cx
	jbe	roll50
roll40:
	mov	ax,cx
roll50:
	test	dh,signmaskhigh
	jz	goscrollud	;scroll up
	neg	ax		;scroll down
goscrollud:
	call	mygscrollud
	jmp	roll100

rollilgerr:
	jmp	ex3ilgerr

roll100:
	cmp	byte ptr [bp],0c2h	;,
	jne	roll200
roll110:
	inc	bp
	call	farFORMUL
	backsp_mac
	lodsw
	mov	dh,ah
	and	ah,attribmaskhigh
	jnz	rollilgerr
	and	ax,lenmask
	jz	roll200
	mov	cx,[local_gxmax]
	inc	cx
	cmp	ax,1
	jne	roll140
	lodsw
	cmp	ax,cx
	jbe	roll150
roll140:
	mov	ax,cx
roll150:
	test	dh,signmaskhigh
	jz	goscrolllr	;scroll left
	neg	ax		;scroll right
goscrolllr:
	call	mygscrolllr
roll200:
	jmp	gomainlp2



;
;* assign graphic print size
;
gsizesub:
	cmp	byte ptr [bp],0c2h	;,
	je	gsizenonchange
	call	far ptr farGET_AX
	jc	gsizeerr
	cmp	ax,gsizemax
	ja	gsizeilgerr
	clc
	ret
gsizenonchange:
	inc	bp
	stc
	ret

gsizeerr:
	jmp	ex3synerr
gsizeilgerr:
	jmp	ex3ilgerr

fargsizeinit:
	call	gsizeinitsub
	retf

gsizeinit:
	call	gsizeinitsub
	jmp	gomainlp2

gsizeinitsub:
	mov	ax,ankwidthL
	mov	[ankwidth],ax
	mov	[gwidth],ax
	mov	[gwidth2],ax
	mov	ax,heightL
	mov	[height],ax
	mov	[gheight],ax
	mov	ax,halfheightL
	mov	[halfheight],ax
	mov	[halfgheight],ax
	mov	ax,height2L
	mov	[height2],ax
	mov	[gheight2],ax
	mov	[gsizemax],gsizemaxL
	mov	[gwidth_ratio],1
	mov	[gheight_ratio],1
	mov	[TeXFlg],1
	ret

gsize:
	call	usegraph?

	MOV	AL,[BP]
	CMP	AL,CR
	JE	gsizeinit	;コマンドのみ
	CMP	AL,0C0H		;':'
	JE	gsizeinit	;コマンドのみ
	call	gsizesub
	jc	gsize15
	and	ax,0fff8h	;idiv ankwidth & times ankwidth
	jnz	gsize10
	mov	ax,[ankwidth]
gsize10:
	mov	dx,ax
	add	dx,dx
	dec	dx
	cmp	dx,[local_gxmax]
	ja	gsizeilgerr
	mov	[gwidth],ax
	my_shr	ax,3
	mov	[gwidth_ratio],ax
	cmp	byte ptr [bp],0c2h	;,
	jne	gsizeret
	inc	bp
gsize15:
	call	gsizesub
	jc	gsize25
	and	ax,0fff0h	;idiv height & times height
	jnz	gsize20
	mov	ax,[height]
gsize20:
	mov	dx,[local_gymax]
	inc	dx
	cmp	ax,dx
	ja	gsizeilgerr
	mov	[gheight],ax
	shr	ax,1
	mov	bx,ax
	my_shr	ax,2
	add	bx,ax
	dec	bx
	mov	[halfgheight],bx	;=height*5/8-1
	shr	ax,1
	mov	[gheight_ratio],ax
	cmp	byte ptr [bp],0c2h	;,
	jne	gsizeret
	inc	bp
gsize25:
	call	gsizesub
	jc	gsize35
	mov	dx,ax
	add	dx,dx
	dec	dx
	cmp	dx,[local_gxmax]
	ja	gsizeilgerr
	mov	[gwidth2],ax
	cmp	byte ptr [bp],0c2h	;,
	jne	gsizeret
	inc	bp
gsize35:
	call	gsizesub
	jc	gsize45
	mov	dx,[local_gymax]
	inc	dx
	cmp	ax,dx
	ja	gsizeilgerr
	mov	[gheight2],ax
	cmp	byte ptr [bp],0c2h	;,
	jne	gsizeret
	inc	bp
gsize45:
	call	gsizesub		;secret command
	jc	gsizeerr
	or	al,ah
	mov	[TeXFlg],al		;if AX<>0 then AL<>0
gsizeret:
	jmp	gomainlp2


;
;*
;
setviewmain:
	;inp ax, bx = viewX1, viewY1
	;    cx, dx = viewX2, viewY2

setviewmainin:
	cmp	ax,cx
	jbe	setview10
	xchg	ax,cx
setview10:
	cmp	bx,dx
	jbe	setview20
	xchg	bx,dx
setview20:
	cmp	cx,[gxmax]
	ja	setview30
	mov	[viewX1],ax
	push	ax
	and	al,7
	mov	[viewX1pixel],al
	pop	ax
	my_shr	ax,3
	mov	[viewX1address],ax

	mov	[viewX2],cx
	mov	ax,cx
	and	al,7
	mov	[viewX2pixel],al
	mov	ax,cx
	my_shr	ax,3
	mov	[viewX2address],ax
setview30:
	cmp	dx,[gymax]
	ja	setview100
	mov	[viewY2],dx
	mov	ax,dx
	inc	ax
	mul	[gxbytes]
	mov	[viewY2overadr],ax

	mov	[viewY1],bx
	mov	ax,bx
	mul	[gxbytes]
	mov	[viewY1startadr],ax
setview100:
	mov	ax,[viewX2]
	sub	ax,[viewx1]
	mov	[local_gxmax],ax
	mov	ax,[viewy2]
	sub	ax,[viewY1]
	mov	[local_gymax],ax
	ret


mysectorfill:
	;draw sector and fill inside
	;inp: ([centerX],[centerY]), [radius]
	;     ([gX1],[gY1])-([gX2,gY2])
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
	mov	ax,[viewY2]
	inc	ax
	add	ax,ax
	mov	cx,ax
	add	ax,ax
	add	cx,ax		;6words/line
	rep	movsw

	mov	ax,data		;fill work by 8000h
	mov	es,ax
	mov	di,[txttop]
	mov	ax,[viewY2]
	inc	ax
	add	ax,ax
	mov	cx,ax
	add	ax,ax
	add	cx,ax		;6words/line
	mov	ax,8000h
	rep	stosw

	mov	ax,_gramseg
	mov	es,ax

	call	myarcmain
	call	mysectorlines

	mov	ah,[paintcolor]
	call	setreset
	call	mysectorfillinner

	mov	ax,data
	mov	es,ax
	add	ax,graphworkseg		;restore data
	mov	ds,ax
	mov	si,0
	mov	di,es:[txttop]
	mov	ax,es:[viewY2]
	inc	ax
	add	ax,ax
	mov	cx,ax
	add	ax,ax
	add	cx,ax		;6words/line
	rep	movsw

	pop	es
	pop	ds
	jmp	weakgregnormal	;call & ret


mysectorlines:
	mov	cx,[centerX]
	mov	[gX1],cx
	mov	ax,[arcX1]
	mov	bx,[radiusratioX]
	or	bx,bx
	jz	sectorline50
	sal	ax,1
	imul	bx
	mov	ax,dx
sectorline50:
	add	ax,cx
	mov	[gX2],ax

	mov	cx,[centerY]
	mov	[gY1],cx
	mov	ax,[arcY1]
	mov	bx,[radiusratioY]
	or	bx,bx
	jz	sectorline60
	sal	ax,1
	imul	bx
	mov	ax,dx
sectorline60:
	add	ax,cx
	mov	[gY2],ax
	mov	ax,2
	call	sectorlinemem
	call	sectorlinedraw

	mov	cx,[centerX]
	mov	[gX1],cx
	mov	ax,[arcX2]
	mov	bx,[radiusratioX]
	or	bx,bx
	jz	sectorline70
	sal	ax,1
	imul	bx
	mov	ax,dx
sectorline70:
	add	ax,cx
	mov	[gX2],ax

	mov	cx,[centerY]
	mov	[gY1],cx
	mov	ax,[arcY2]
	mov	bx,[radiusratioY]
	or	bx,bx
	jz	sectorline80
	sal	ax,1
	imul	bx
	mov	ax,dx
sectorline80:
	add	ax,cx
	mov	[gY2],ax
	mov	ax,6
	call	sectorlinemem
	call	sectorlinedraw

	ret


sectorlinemem:
	mov	[linemem1or2],ax
	mov	ax,[gX2]
	sub	ax,[gX1]
	jge	linemem10
	neg	ax
linemem10:
	mov	cx,[gY2]
	sub	cx,[gY1]
	jge	linemem20
	neg	cx
linemem20:
	cmp	ax,cx
	jbe	linememV

linememH:
	call	clipYstart
	jc	linememret

	mov	ax,[gX2]		;let [gX1] <= [gX2]
	mov	bx,[gX1]
	cmp	ax,bx
	jge	linememH10
	xchg	ax,bx
	mov	[gX2],ax
	mov	[gX1],bx
	mov	cx,[gY1]
	xchg	cx,[gY2]
	mov	[gY1],cx
linememH10:
	sub	ax,bx
	inc	ax			;diffx

	mov	bx,12			;12bytes/line
	mov	cx,[gY2]
	sub	cx,[gY1]
	jnb	linememH20
	neg	cx
	neg	bx
linememH20:
	mov	[linedirection],bx	;down/up
	inc	cx			;dy
	mov	[linecount],cx
	xor	dx,dx
	add	ax,ax
	div	cx
	mov	[pixelstepreal+2],ax
	xor	ax,ax
	div	cx
	mov	[pixelstepreal],ax

	;initialize

	mov	ax,[gY1]
	my_shl	ax,2
	mov	bx,ax
	add	ax,ax
	add	ax,bx			;12bytes/line
	add	ax,[txttop]
	mov	bx,ax
	mov	dx,[gX1]		;start pt

	;1st line

	mov	ax,[pixelstepreal]
	mov	di,ax
	mov	ax,[pixelstepreal+2]
	mov	si,ax			;si:di = current pixel adr
	inc	ax
	shr	ax,1			;length

linememHlp:
	add	ax,dx
	dec	ax
	call	linememsub
	inc	ax
	mov	dx,ax
	add	bx,[linedirection]

	mov	ax,[pixelstepreal]
	add	di,ax
	mov	ax,[pixelstepreal+2]
	mov	cx,si
	adc	ax,si
	mov	si,ax
	inc	cx
	shr	cx,1
	inc	ax
	shr	ax,1
	sub	ax,cx			;length
	dec	[linecount]
	jnz	linememHlp
linememret:
	ret


linememV:
	call	clipYstart
	jc	linememret
	mov	ax,[gY2]		;let [gY1] <= [gY2]
	mov	bx,[gY1]
	cmp	ax,bx
	jge	linememV10
	xchg	ax,bx
	mov	[gY2],ax
	mov	[gY1],bx
	mov	cx,[gX1]
	xchg	cx,[gX2]
	mov	[gX1],cx
linememV10:
	sub	ax,bx
	inc	ax			;diffy

	mov	bx,1
	mov	cx,[gX2]
	sub	cx,[gX1]
	jnl	linememV20
	neg	cx
	neg	bx
linememV20:
	mov	[linedirection],bx
	inc	cx			;dx
	mov	[linecount],cx		;number of lines
	add	ax,ax
	xor	dx,dx
	div	cx
	mov	[pixelstepreal+2],ax
	xor	ax,ax
	div	cx
	mov	[pixelstepreal],ax

	mov	ax,[gY1]
	my_shl	ax,2
	mov	bx,ax
	add	ax,ax
	add	ax,bx			;12bytes/line
	add	ax,[txttop]
	mov	bx,ax
	mov	dx,[gX1]

	mov	ax,[pixelstepreal]
	mov	di,ax
	mov	ax,[pixelstepreal+2]
	mov	si,ax			;si:di = current pixel adr
	inc	ax
	shr	ax,1

linememVlp:
	mov	cx,ax			;length
	mov	ax,dx
linememVlp2:
	call	linememsub
	add	bx,12			;12bytes/line
	myloop	linememVlp2

	add	dx,[linedirection]

	mov	ax,[pixelstepreal]
	add	di,ax
	mov	ax,[pixelstepreal+2]
	mov	cx,si
	adc	ax,si
	mov	si,ax
	inc	cx
	shr	cx,1
	inc	ax
	shr	ax,1
	sub	ax,cx

	dec	[linecount]
	jnz	linememVlp
	ret

linememsub:
	cmp	[linemem1or2],2
	jne	linememsub10
	mov	[bx+2],dx
	mov	[bx+4],ax
	ret
linememsub10:
	mov	[bx+6],dx
	mov	[bx+8],ax
	ret


sectorfillsetorder:
	;bx = 8000h

	;is [si] connected to [si+2] ?

	cmp	[si+2],bx
	je	setorder100
	mov	ax,[si]
	cmp	ax,bx
	je	setorder100
	cmp	ax,[si+2]
	jl	setorder100

	mov	ax,[si+4]		;if yes then gather to 1 pt
	inc	ax
	cmp	[si],ax
	jge	setorder10
	mov	[si],ax
setorder10:
	mov	[si+2],bx
	mov	[si+4],bx
	cmp	[arcY1],0
	jge	setorder100
	mov	[si],bx			;delete this pt
setorder100:
	;is [si] connected to [si+6] ?

	cmp	[si+6],bx
	je	setorder150
	mov	ax,[si]
	cmp	ax,bx
	je	setorder150
	cmp	ax,[si+6]
	jl	setorder150

	mov	ax,[si+8]		;if yes then gather to 1 pt
	inc	ax
	cmp	[si],ax
	jge	setorder110
	mov	[si],ax
setorder110:
	mov	[si+6],bx
	mov	[si+8],bx
	cmp	[arcY2],0
	jle	setorder150
	mov	[si],bx			;delete this pt
setorder150:
	;is [si+8] connected to [si+10] ?

	cmp	[si+8],bx
	je	setorder200
	mov	ax,[si+10]
	cmp	ax,bx
	je	setorder200
	cmp	ax,[si+8]
	jg	setorder200

	mov	ax,[si+6]		;if yes then gather to 1 pt
	dec	ax
	cmp	[si+10],ax
	jle	setorder160
	mov	[si+10],ax
setorder160:
	mov	[si+6],bx
	mov	[si+8],bx
	cmp	[arcY2],0
	jge	setorder200
	mov	[si+10],bx		;delete this pt
setorder200:
	;is [si+4] connected to [si+10] ?

	cmp	[si+4],bx
	je	setorder250
	mov	ax,[si+10]
	cmp	ax,bx
	je	setorder250
	cmp	ax,[si+4]
	jg	setorder250

	mov	ax,[si+2]		;if yes then gather to 1 pt
	dec	ax
	cmp	[si+10],ax
	jle	setorder210
	mov	[si+10],ax
setorder210:
	mov	[si+2],bx
	mov	[si+4],bx
	cmp	[arcY1],0
	jle	setorder250
	mov	[si+10],bx		;delete this pt
setorder250:
	;let [si+2] <= [si+6]

	mov	ax,[si+2]
	cmp	ax,bx
	je	setorder20
	mov	ax,[si+6]
	cmp	ax,bx
	je	setorder20
	cmp	ax,[si+2]
	jge	setorder20
	xchg	ax,[si+2]
	mov	[si+6],ax
	mov	ax,[si+8]
	xchg	ax,[si+4]
	mov	[si+8],ax
setorder20:
	;is [si+4] connected to [si+6] ?

	mov	ax,[si+4]
	cmp	ax,bx
	je	setorder300
	inc	ax
	cmp	ax,[si+6]
	jl	setorder300		;no
	mov	ax,[si+8]		;if yes then gather to 1pt
	cmp	ax,[si+4]
	jle	setorder30
	mov	[si+4],ax
setorder30:
	mov	[si+6],bx
	mov	[si+8],bx
	ret
setorder300:
	cmp	[si+2],bx
	jne	setorder310
	mov	ax,[si+6]
	mov	[si+2],ax
	mov	ax,[si+8]
	mov	[si+4],ax
	mov	[si+6],bx
	mov	[si+8],bx
setorder310:
	ret


mysectorfillinner:

	;note [si] and [si+10] are open points
	;while others are used points

	mov	ax,[viewY1]
	mov	si,ax
	mul	[gxbytes]
	mov	di,ax
	mov	cx,[viewY2]
	inc	cx
	sub	cx,si
	my_shl	si,2
	mov	dx,si
	add	si,si
	add	si,dx			;12bytes/line
	add	si,[txttop]

mysectorfill10:
	push	cx

	mov	bx,8000h		;dummy

	call	sectorfillsetorder

	mov	dx,[si]
	cmp	dx,bx
	je	sectorfillP0
sectorfillP1:
	mov	ax,[si+2]
	cmp	ax,bx
	je	sectorfillP10
;sectorfillP11:
	dec	ax
	call	sectorfillinsub		;0->1
sectorfillP111:
	mov	ax,[si+10]
	cmp	ax,bx
	jne	sectorfillP111AB
	mov	ax,[si+6]
	cmp	ax,bx
	je	sectorfillskip		;no more line
	dec	ax
	mov	dx,[si+4]
	inc	dx
	jmps	sectorfillgo		;0,1->2

sectorfillP111AB:
	mov	dx,[si+8]
	cmp	dx,bx
	je	sectorfillP111M
	inc	dx
	jmps	sectorfillgo		;2->3

sectorfillP111M:
	mov	dx,[si+4]
	inc	dx
	jmp	sectorfillgo		;0,1,2->3

sectorfillP10:
	mov	ax,[si+10]		;0->3
	cmp	ax,bx
	je	sectorfillskip		;no more line
	jmps	sectorfillgo

sectorfillP0:
	mov	ax,[si+2]
	cmp	ax,bx
	je	sectorfillskip		;no line
	mov	dx,[si+4]
	inc	dx
	mov	ax,[si+6]
	cmp	ax,bx
	je	sectorfillP000
	dec	ax
	jmps	sectorfillgo		;1->2
sectorfillP000:
	mov	ax,[si+10]
	cmp	ax,bx
	je	sectorfillskip
	jmps	sectorfillgo		;1->3

sectorfillgo:
	call	sectorfillinsub
sectorfillskip:
	pop	cx
	add	di,[gxbytes]
	add	si,12		;12bytes/line

	myloop	mysectorfill10
	ret


sectorlinedraw:
	push	[tilelength]

	mov	[tilelength],0

	mov	ax,[viewY1]
	mov	si,ax
	mul	[gxbytes]
	mov	di,ax
	mov	cx,[viewY2]
	inc	cx
	sub	cx,si
	my_shl	si,2
	mov	dx,si
	add	si,si
	add	si,dx			;12bytes/line
	add	si,[txttop]
	add	si,[linemem1or2]
sectorlinedraw10:
	push	cx

	mov	dx,[si]
	cmp	dx,8000h
	je	sectorlinedraw20
	mov	ax,[si+2]
	call	sectorfillinsub
sectorlinedraw20:
	pop	cx
	add	di,[gxbytes]
	add	si,12		;12bytes/line

	myloop	sectorlinedraw10
	pop	[tilelength]
	ret


sectorfillinsub:
	cmp	dx,[viewX2]
	jle	sectorfillinsub1
	ret
sectorfillinsub1:
	cmp	ax,[viewX1]
	jge	sectorfillinsub2
	ret
sectorfillinsub2:
	cmp	ax,[viewX2]
	jle	sectorfillinsub3
	mov	ax,[viewX2]
sectorfillinsub3:
	cmp	dx,[viewX1]
	jge	sectorfillinsub4
	mov	dx,[viewX1]
sectorfillinsub4:
	inc	ax
	sub	ax,dx
	jg	sectorfillinsub10
	ret
sectorfillinsub10:
	mov	[linelength],ax
	mov	ax,dx
	my_shr	ax,3
	add	ax,di
	mov	[gadr],ax
	and	dl,7
	mov	[goff],dl

	push	si
	push	di

	cmp	[tilelength],0
	jne	mysectorfilltile

	call	linesubX
	jmps	mysectorfillinret
mysectorfilltile:
	call	linesubXtile
	mov	ah,_read1write3
	call	readwritemode

mysectorfillinret:
	pop	di
	pop	si
	ret


myarcmain:
	;decide goal point

	mov	ax,[gX2]
	mov	[gX],ax
	mov	ax,[gY2]
	mov	[gY],ax
	call	letoncircle
	mov	ax,[gX]
	mov	[arcX2],ax
	mov	bx,[gY]
	mov	[arcY2],bx

	;decide start point

	mov	ax,[gX1]
	mov	[gX],ax
	mov	ax,[gY1]
	mov	[gY],ax
	call	letoncircle

	mov	ax,[gX]
	mov	[arcX1],ax
	mov	ax,[gY]
	mov	[arcY1],ax

	sub	ax,[arcX2]
	jnz	arcmain
	sub	bx,[arcY2]
	jnz	arcmain
	jmp	mycircle	;full circle

arcmain:
	mov	[countarc],0
	mov	[radiusratioX],0
	mov	[radiusratioY],0
	mov	bx,[radiusX]
	mov	cx,[radiusY]
	cmp	bx,cx
	jb	arcYlonger
	je	arcXYequal
arcXlonger:
	mov	dx,cx
	xor	ax,ax
	div	bx
	shr	ax,1
	or	ax,ax
	jnz	arcXlong10
	inc	ax
arcXlong10:
	mov	[radiusratioY],ax
	jmps	arcXYequal
arcYlonger:
	mov	dx,bx
	xor	ax,ax
	div	cx
	shr	ax,1
	or	ax,ax
	jnz	arcXlong20
	inc	ax
arcXlong20:
	mov	[radiusratioX],ax

arcXYequal:
	mov	ax,[arcX1]
	imul	ax
	mov	bx,ax
	mov	cx,dx
	mov	ax,[arcY1]
	imul	ax
	add	bx,ax
	adc	cx,dx
	mov	ax,[radius]
	mul	ax
	sub	bx,ax
	sbb	cx,dx
	mov	dx,bx		;dx = diff = (x^2+y^2) - r^2

	mov	ax,[arcY1]
	mov	bx,[arcX1]
	mov	[gY],ax
	mov	[gX],bx

	call	myarcsub	;set 1 st point

	mov	cx,[absX]
	sub	cx,[absY]

	cmp	[dirX],0
	jl	arc3456
arc1278:
	cmp	[dirY],0
	jl	arc12
arc78:
	mov	[dirX],1
	mov	[dirY],-1
	or	cx,cx
	jns	arc800LP
	jmp	arc700LP
arc12:
	mov	[dirX],-1
	mov	[dirY],-1
	or	cx,cx
	jns	arc100LP
	jmp	arc200LP
arc3456:
	cmp	[dirY],0
	jl	arc34
arc56:
	mov	[dirX],1
	mov	[dirY],1
	or	cx,cx
	jns	arc500LP
	jmp	arc600LP
arc34:
	mov	[dirX],-1
	mov	[dirY],1
	or	cx,cx
	jns	arc400LP
	jmp	arc300LP

	;compute only 1/8 circle: i.e. while abs y <= x

arc100500:
	mov	cl,[countarc]
	cmp	cl,4
	je	arc100ret		;avoid infinite loop
	inc	cl
	mov	[countarc],cl
	neg	[dirX]
arc100LP:
arc500LP:
	cmp	bx,[arcX2]
	jne	arc102
	cmp	ax,[arcY2]
	jne	arc102
arc100ret:
	ret
arc102:	
	mov	cx,ax
	add	cx,bx
	jz	arc200600
	xor	cx,[dirY]
	jns	arc200600

	mov	cx,ax
	or	cx,cx
	jns	arc104
	neg	cx
arc104:
	add	cx,cx
	inc	cx
	add	dx,cx		;diff += abs(2y+1)
	jle	arc120		;new x = old x

	mov	cx,bx
	or	cx,cx
	jns	arc106
	neg	cx
arc106:
	cmp	dx,cx
	jb	arc120		;new x = old x

	add	cx,cx
	dec	cx
	sub	dx,cx		;diff += abs(2y+1)-abs(2x-1)

	add	bx,[dirX]
	mov	[gX],bx		;new x = old x -1
arc120:
	add	ax,[dirY]
	mov	[gY],ax
	call	myarcsub
	jmp	arc100LP

	;while x >= 0
arc200600:
arc200LP:
arc600LP:
	cmp	bx,[arcX2]
	jne	arc202
	cmp	ax,[arcY2]
	jne	arc202
arc200ret:
	ret
arc202:	
	or	bx,bx
	jz	arc300700

	mov	cx,bx
	or	cx,cx
	jns	arc204
	neg	cx
arc204:
	add	cx,cx
	dec	cx
	sub	dx,cx		;diff -= abs(2x)-1
	jge	arc270		;new y = old y

	mov	cx,ax
	or	cx,cx
	js	arc206
	neg	cx		;make NEGATIVE
arc206:
	cmp	dx,cx
	jge	arc270		;new y = old y

	add	cx,cx
	dec	cx		;cx = -abs(2y)-1
	sub	dx,cx		;diff += 2y+1-2x+1
	add	ax,[dirY]	;new y = old y + 1
	mov	[gY],ax

arc270:
	add	bx,[dirX]
	mov	[gX],bx

	call	myarcsub
	jmp	arc200LP

	;while y >= -x
arc300700:
	neg	[dirY]
arc300LP:
arc700LP:
	cmp	bx,[arcX2]
	jne	arc302
	cmp	ax,[arcY2]
	jne	arc302
arc300ret:
	ret
arc302:	
	mov	cx,bx
	sub	cx,ax
	jz	arc400800
	xor	cx,[dirX]
	jns	arc400800

	mov	cx,bx
	or	cx,cx
	jns	arc304
	neg	cx
arc304:
	add	cx,cx
	inc	cx
	add	dx,cx		;diff += abs(2x)+1
	jle	arc370		;new y = old y

	mov	cx,ax
	or	cx,cx
	jns	arc306
	neg	cx
arc306:
	cmp	dx,cx
	jb	arc370		;new y = old y

	add	cx,cx
	dec	cx		;cx = abs(2y)-1
	sub	dx,cx		;diff += 2x+1-2y+1
	add	ax,[dirY]	;new y = old y + 1
	mov	[gY],ax
arc370:
	add	bx,[dirX]
	mov	[gX],bx

	call	myarcsub
	jmp	arc300LP

arc400800:
arc400LP:
arc800LP:
	cmp	bx,[arcX2]
	jne	arc402
	cmp	ax,[arcY2]
	jne	arc402
arc400ret:
	ret
arc402:	
	or	ax,ax
	jz	arc100500

	mov	cx,ax
	or	cx,cx
	jns	arc404
	neg	cx
arc404:
	add	cx,cx
	dec	cx
	sub	dx,cx		;diff += -abs(2y)+1
	jge	arc420		;new x = old x

	mov	cx,bx
	or	cx,cx
	js	arc406
	neg	cx		;make NEGATIVE
arc406:
	cmp	dx,cx
	jge	arc420		;new x = old x

	add	cx,cx
	dec	cx		;cx = -abs(2x)-1
	sub	dx,cx		;diff += -abs(2y)+1+abs(2x)+1

	add	bx,[dirX]
	mov	[gX],bx		;new x = old x -1
arc420:
	add	ax,[dirY]
	mov	[gY],ax
	call	myarcsub
	jmp	arc400LP


;
; * clipping
;   L,M,R : for X
;   U,M,D : for Y

clipping:
	mov	ax,[gX1]
	mov	bx,[gX2]
	mov	si,[viewX1]
	mov	di,[viewX2]
	cmp	ax,si
	jl	clipX1L
	cmp	ax,di
	jg	clipX1R
clipX1M:
	cmp	bx,si
	jl	clipX1M2L
	cmp	bx,di
	jle	clipYstart	;X1M2M
clipX1M2R:			;meet on X = viewX2
	mov	si,di
	call	meetptY
	mov	[gY2],ax
	mov	[gX2],si
	jmps	clipYstart
clipX1M2L:			;meet on X = viewX1
;	mov	si,si
	call	meetptY
	mov	[gY2],ax
	mov	[gX2],si
	jmps	clipYstart
clipX1L:
	cmp	bx,si
	jl	clipX1L2L
	cmp	bx,di
	jg	clipX1L2R
clipX1L2M:			;meet on X = viewX1
;	mov	si,si
	call	meetptY
	mov	[gY1],ax
	mov	[gX1],si
	jmps	clipYstart
clipX1L2R:			;meet on both X = viewX1,viewX2
;	mov	si,si
	call	meetptY
	mov	[gY1],ax
	mov	[gX1],si

	mov	ax,[gX1]
	mov	bx,[gX2]
	mov	si,di
	call	meetptY
	mov	[gY2],ax
	mov	[gX2],si
	jmps	clipYstart
clipX1R:
	cmp	bx,si
	jl	clipX1R2L
	cmp	bx,di
	jg	clipX1R2R
clipX1R2M:			;meet on X = viewX2
	mov	si,di
	call	meetptY
	mov	[gY1],ax
	mov	[gX1],si
	jmps	clipYstart
clipX1R2L:			;meet on both X = viewX1,viewX2
;	mov	si,si
	call	meetptY
	mov	[gY2],ax
	mov	[gX2],si

	mov	ax,[gX1]
	mov	bx,[gX2]
	mov	si,di
	call	meetptY
	mov	[gY1],ax
	mov	[gX1],si

	jmps	clipYstart
clipX1L2L:
clipX1R2R:
clipY1U2U:
clipY1D2D:
	stc
	ret

clipX1M2M:
clipYstart:
	mov	ax,[gY1]
	mov	bx,[gY2]
	mov	si,[viewY1]
	mov	di,[viewY2]
	cmp	ax,si
	jl	clipY1U
	cmp	ax,di
	jg	clipY1D
clipY1M:
	cmp	bx,si
	jl	clipY1M2U
	cmp	bx,di
	jle	clipY1M2M
clipY1M2D:			;meet on Y = viewY2
	mov	si,di
	call	meetptX
	mov	[gX2],ax
	mov	[gY2],si
	jmps	clipret
clipY1M2U:			;meet on Y = viewY1
;	mov	si,si
	call	meetptX
	mov	[gX2],ax
	mov	[gY2],si
	jmps	clipret

clipY1U:
	cmp	bx,si
	jl	clipY1U2U
	cmp	bx,di
	jg	clipY1U2D
clipY1U2M:			;meet on Y = viewY1
;	mov	si,si
	call	meetptX
	mov	[gX1],ax
	mov	[gY1],si
	jmps	clipret
clipY1U2D:			;meet on both Y = viewY1, viewY2
;	mov	si,si
	call	meetptX
	mov	[gX1],ax
	mov	[gY1],si

	mov	ax,[gY1]
	mov	bx,[gY2]
	mov	si,di
	call	meetptX
	mov	[gX2],ax
	mov	[gY2],si
	jmps	clipret

clipY1D:
	cmp	bx,si
	jl	clipY1D2U
	cmp	bx,di
	jg	clipY1D2D
clipY1D2M:			;meet on Y = viewY2
	mov	si,di
	call	meetptX
	mov	[gX1],ax
	mov	[gY1],si
	jmps	clipret
clipY1D2U:			;meet on both Y = viewY1, viewY2
;	mov	si,si
	call	meetptX
	mov	[gX2],ax
	mov	[gY2],si

	mov	ax,[gY1]
	mov	bx,[gY2]
	mov	si,di
	call	meetptX
	mov	[gX1],ax
	mov	[gY1],si
	jmps	clipret
clipY1M2M:
clipret:
	clc
	ret


;
; * clipping of box
;   L,M,R : for X
;   U,M,D : for Y

boxclipping:
	mov	ax,[bX1]
	mov	bx,[bX2]
	mov	si,[viewX1]
	mov	di,[viewX2]
	cmp	ax,si
	jl	bclipX1L
	cmp	ax,di
	jg	bclipX1R
bclipX1M:
	cmp	bx,si
	jl	bclipX1M2L
	cmp	bx,di
	jle	bclipYstart	;X1M2M
bclipX1M2R:			;meet on X = viewX2
	inc	di
	mov	[bX2],di
	jmps	bclipYstart
bclipX1M2L:			;meet on X = viewX1
	dec	si
	mov	[bX2],si
	jmps	bclipYstart
bclipX1L:
	cmp	bx,si
	jl	bclipX1L2L
	cmp	bx,di
	jg	bclipX1L2R
bclipX1L2M:			;meet on X = viewX1
	dec	si
	mov	[bX1],si
	jmps	bclipYstart
bclipX1L2R:			;meet on both X = viewX1,viewX2
	dec	si
	mov	[bX1],si

	inc	di
	mov	[bX2],di
	jmps	bclipYstart
bclipX1R:
	cmp	bx,si
	jl	bclipX1R2L
	cmp	bx,di
	jg	bclipX1R2R
bclipX1R2M:			;meet on X = viewX2
	inc	di
	mov	[bX1],di
	jmps	bclipYstart
bclipX1R2L:			;meet on both X = viewX1,viewX2
	dec	si
	mov	[bX2],si
	inc	di
	mov	[bX1],di

	jmps	bclipYstart
bclipX1L2L:
bclipX1R2R:
bclipY1U2U:
bclipY1D2D:
	stc
	ret

bclipX1M2M:
bclipYstart:
	mov	ax,[bY1]
	mov	bx,[bY2]
	mov	si,[viewY1]
	mov	di,[viewY2]
	cmp	ax,si
	jl	bclipY1U
	cmp	ax,di
	jg	bclipY1D
bclipY1M:
	cmp	bx,si
	jl	bclipY1M2U
	cmp	bx,di
	jle	bclipY1M2M
bclipY1M2D:			;meet on Y = viewY2
	inc	di
	mov	[bY2],di
	jmps	bclipret
bclipY1M2U:			;meet on Y = viewY1
	dec	si
	mov	[bY2],si
	jmps	bclipret

bclipY1U:
	cmp	bx,si
	jl	bclipY1U2U
	cmp	bx,di
	jg	bclipY1U2D
bclipY1U2M:			;meet on Y = viewY1
	dec	si
	mov	[bY1],si
	jmps	bclipret
bclipY1U2D:			;meet on both Y = viewY1, viewY2
	dec	si
	mov	[bY1],si
	inc	di
	mov	[bY2],di
	jmps	bclipret

bclipY1D:
	cmp	bx,si
	jl	bclipY1D2U
	cmp	bx,di
	jg	bclipY1D2D
bclipY1D2M:			;meet on Y = viewY2
	inc	di
	mov	[bY1],di
	jmps	bclipret
bclipY1D2U:			;meet on both Y = viewY1, viewY2
	dec	si
	mov	[bY2],si
	inc	di
	mov	[bY1],di
	jmps	bclipret
bclipY1M2M:
bclipret:
	clc
	ret



meetptY:
	;ans = -(y2-y1)*(x1-X)/(x2-x1)+y1
	;AX = ans, SI = X, AX = x1, BX = x2

	sub	bx,ax
	sub	ax,si
	mov	cx,[gY1]
	mov	dx,[gY2]
	sub	dx,cx
	imul	dx
	idiv	bx
	sub	ax,cx
	neg	ax
	ret


meetptX:
	;ans = -(x2-x1)*(y1-Y)/(y2-y1)+x1
	;AX = ans, SI = Y, AX = y1, BX = y2

	sub	bx,ax
	sub	ax,si
	mov	cx,[gX1]
	mov	dx,[gX2]
	sub	dx,cx
	imul	dx
	idiv	bx
	sub	ax,cx
	neg	ax
	ret


	include	vga16.asm

code2	ends
