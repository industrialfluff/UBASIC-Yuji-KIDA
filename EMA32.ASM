;ema32.asm

	; Expanded Memory Array

	INCLUDE	UBDEF.H
	INCLUDE	UB.H

shl_dxax_cl	macro
	db	0fh,0a5h,0c2h	;=shld	dx,ax,cl
	shl	ax,cl
	endm

shl_edxeax_cl	macro
	set32
	db	0fh,0a5h,0c2h	;=shld	dx,ax,cl
	set32
	shl	ax,cl
	endm

makemaptbl	macro	reg1,reg2
	mov	[reg1],reg2
	inc	reg2
	mov	[reg1+4],reg2
	inc	reg2
	mov	[reg1+8],reg2
	inc	reg2
	mov	[reg1+12],reg2
	sub	reg2,3
	endm


get_dxax	macro
	local	jp

	backsp_mac
	xor	dx,dx
	lodsw
	or	ax,ax
	jz	jp
	cmp	ax,2
	lodsw
	jb	jp
	mov	dx,[si]
	je	jp
	jmp	ilgerr
jp:
	endm


_emabaseadr	equ	0
_emabasehigh	equ	2
_ema1stlim	equ	4
_ema2ndlim	equ	8

_emaattribsize	equ	16		;>= _ema2ndlim + 4
_emaattribsizeword	equ	8	;_emaattribsize/2
_emaattribsizelog	equ	4	;log_2 of _emaattribsize


EMSpagesize	equ	4000h
EMSmaxhigh	equ	128*16	;128*16*64K=128M


CODE	SEGMENT PUBLIC
	ASSUME	CS:CODE,DS:DATA

	public	getemaadr,emaword,letema,inpema,dimema,useema
	public	swapema,emain,ema_close
	public	clrema,negema,incema,decema

	extrn	mainlp:near,hotst:near
	extrn	clr_next:near,neg_next:near
	extrn	inc_next:near,dec_next:near
	extrn	negallsi:near,lvincin:near,lvdecin:near
	extrn	blockout:near
	extrn	let_extended:near
	extrn	ready:near,print2:near,ahedsp:near
	extrn	FORMUL:near,KAKKO:near
	extrn	addin:near,subin:near,mulin:near,divin:near
	extrn	resin:near,idivin:near,ratdivin:near

	extrn	farFORMUL:far
	extrn	farGET_AX:far,farGET_EAX:far
	extrn	farPRNTBX:far,farBINASC:far

	extrn	UNDEFERR:near,OVRERR:near,DBLDEF:near,emaerr:near
	extrn	cantdo:near,synerr:near,sperr:near
	extrn	ilgerr:near,diskerr:near,nofile:near,existerr:near
	extrn	nolerr:near,indexerr:near,blockerr:near
	extrn	undeferr:near,nofile:near

;
; * return EMS handle
;
ema_close:
	mov	dx,[emahandle]
	or	dx,dx
	jz	emacloseret
	mov	ah,45h
	int	67h
	mov	[emahandle],0
emacloseret:
	ret

;
; * get ema adr
;   out: ecx = file pointer

getemacantdo:
	jmp	undeferr

getemadirect:
	mov	ax,[bp+1]
	add	bp,3
	jmps	getema5
getemaadr:
	cmp	[emahandle],0
	je	getemacantdo

	mov	al,[bp]
	mov	ah,[bp+3]
	cmp	ax,0c1f1h	;1 word number + ; ?
	je	getemadirect

	call	formul		;get ema number
	cmp	byte ptr [bp],0c1h	;code of ;
	je	getema2
	xor	ax,ax		;ema number is not specified
	push	ax		;* attribute base adr
	jmp	getema7
getema2:
	backsp_mac
	mov	ax,[si]
	cmp	ax,1
	jb	getema5
	jne	getemailg
	mov	ax,[si+2]
getema5:
	cmp	ax,16
	jae	getemailg
	my_shl	ax,_emaattribsizelog
	push	ax		;* attribute base adr

	inc	bp
	call	formul
getema7:
	get_dxax

	mov	cl,[bp]
	cmp	cl,0c2h		;code of ,
	je	getema20	;2 dim case

	; 1 dim case

	cmp	cl,')'
	jne	getemasynerr
	inc	bp

  if FLG98
	mov	cx,emaattributeseg
  else
	mov	cx,ss
	add	cx,emaattributeseg
  endif
	mov	es,cx
	set32
	shl	dx,16
	mov	dx,ax

	pop	di		;* attrib offset

	cmp	word ptr es:[di+_emabasehigh],-1
	je	getemaundef
	set32
	cmp	dx,es:[di+_ema1stlim]
	ja	getemailg
	set32
	mov	ax,es:[di+_ema2ndlim]
	set32
	or	ax,ax
	jnz	getemailg
	mov	cl,[emaunitlog]
	set32
	shl	dx,cl

	set32
	add	dx,es:[di+_emabaseadr]
	set32
	mov	cx,dx
	smov	es,ss
	ret

getemailg:
	jmp	ilgerr
getemasynerr:
	jmp	synerr
getemaundef:
	jmp	undeferr

getema20:			;2 dim case
	push	dx		;** 1st argument
	push	ax		;

	inc	bp
	call	kakko
	get_dxax
	push	dx		;*** 2nd argument
	push	ax		;

getema50:
  if FLG98
	mov	ax,emaattributeseg
  else
	mov	ax,ss
	add	ax,emaattributeseg
  endif
	mov	es,ax

	set32
	pop	bx		;*** 2nd arg
	set32
	pop	ax		;** 1st arg
	pop	di		;* attrib offset

	cmp	word ptr es:[di+_emabasehigh],-1
	je	getemaundef
	set32
	cmp	ax,es:[di+_ema1stlim]
	ja	getemailg
	set32
	mov	cx,es:[di+_ema2ndlim]
	set32
	cmp	bx,cx
	ja	getemailg
	set32
	inc	cx
	set32
	mul	cx

	set32
	add	ax,bx		;now eax = local element number

	mov	cl,[emaunitlog]
	set32
	shl	ax,cl

	set32
	add	ax,es:[di+_emabaseadr]
	set32
	mov	cx,ax
	smov	es,ss
	ret


;
; map logical pages to physical pages
;  in      :ecx file pointer

emsmaperror:
	call	ema_close
	jmp	emaerr

mappage_ax:
	push	ax
	push	cx
	push	dx
	push	si

	; make allocation map

	mov	si,offset maptable
	mov	cx,ax
	makemaptbl     si,cx

	; do mapping

	mov	ax,5000h
	mov	dx,[emahandle]
	mov	cx,4		;64K/pagesize
	mov	si,offset maptable
	int	67h
	or	ah,ah
	jnz	emsmaperror

	pop	si
	pop	dx
	pop	cx
	pop	ax
	ret

;farmappage:
;	call	mappage
;	retf


;
;* expanded MEMORY ARRAY used as function
;
EMA1ilg:
	jmp	ilgerr

EMAIN:
	call	getemaadr	;ecx = offset

;	jmp	getfromema	;call & ret

;
; * copy from ema to calc stack
;  in      : ecx file pointer
;  result  : [calcsp] and its value
;  destroy : cx,di,si

getfromema:
	set32
	mov	ax,cx
	set32
	shr	ax,14
	and	al,0fch		;cut lowest 2 bits
	cmp	ax,[maptable]	;mapped top page
	je	getfromema10	;already mapped
	call	mappage_ax
getfromema10:
	call	ahedsp
	mov	di,si		;dest
	push	ds		;*
	mov	ds,[EMSbaseseg]	;EMS seg
	mov	si,cx		;EMS adr
	mov	cx,[si]
	and	cx,lenmask
	inc	cx
	rep	movsw
	pop	ds		;*
	ret


;
; * copy to ema from calc stack
;  in      :ecx file pointer
;             [calcsp] and its value
;             [calcsp] will be updated
;  destroy : ax,bx,cx,dx,si

puttoema:
	set32
	mov	ax,cx
	set32
	shr	ax,14
	and	al,0fch		;cut lowest 2 bits
	cmp	ax,[maptable]	;mapped top page
	je	puttoema10	;already mapped
	call	mappage_ax
puttoema10:
	mov	si,[calcsp]	;source
	push	es		;*
	mov	es,[EMSbaseseg]	;EMS seg
	mov	di,cx		;EMS adr

	mov	cx,[si]
	and	cx,lenmask
	cmp	cx,[emawords]
	ja	emaover
	inc	cx
	rep	movsw
	pop	es		;*
	ret

farputtoema:
	call	puttoema
	retf

emaover:
	jmp	ovrerr


;
; * access to expanded ram
;
letema:
	inc	bp
	call	getemaadr	;ecx = offset
	set32
	push	cx

	;calc value to assign

	cmp	byte ptr [bp],codeofequal
	JNE	letema_expanded
	INC	BP

	CALL	FORMUL
letema_30:
	;store value

	set32
	pop	cx
	call	puttoema
	add	[calcsp],unitbyte
	jmp	mainlp	

emasynerr:
	jmp	synerr


letema_expanded:
	call	getfromema
	call	let_extended
	jmp	letema_30

;
;* input to ema
;
inpemaover:
	jmp	ovrerr

inpema:
	winc	bp
	call	getemaadr	;ecx = offset
	call	puttoema
	add	[calcsp],unitbyte
	ret


;
;* dim ema
;

dimdblerr:
	jmp	dbldef

dimema:
	push	es

	call	far ptr farinitema

	winc	bp
	call	formul

	cmp	byte ptr [bp],0c1h	;code of ;
	je	dimema5
	xor	ax,ax		;ema number is not specified
	push	ax		;* attribute base
	jmp	dimema15

dimema5:
	backsp_mac
	lodsw
	cmp	ax,1
	jb	dimema10	;if 0
	jne	dimemailg
	mov	ax,[si]
	cmp	ax,16
	jae	dimemailg	;must <= 15
dimema10:
	my_shl	ax,_emaattribsizelog
	push	ax		;* attribute base
	mov	di,ax

	cmp	byte ptr [bp],0c1h	;code of ;
	jne	dimemailg

	inc	bp
	call	formul
dimema15:
	get_dxax
	push	dx		;** 1st limit
	push	ax		;

	cmp	byte ptr [bp],0c2h	;code of ,
	jne	dimema40

	inc	bp
	call	formul
	get_dxax
	push	dx		;*** 2nd limit
	push	ax		;
	jmp	dimema50
dimema40:
	set32
	xor	ax,ax
	set32
	push	ax		;*** 2nd limit(for 1 dim case)

dimema50:
	cmp	byte ptr [bp],')'
	jne	dimemailg
	inc	bp

	;set ema attributes
  if FLG98
	mov	ax,emaattributeseg
  else
	mov	ax,ss
	add	ax,emaattributeseg
  endif
	mov	es,ax

	set32
	pop	ax		;***
	set32
	pop	bx		;**
	pop	di		;*

	cmp	word ptr es:[di+_emabasehigh],-1
	je	dimema55
	jmp	dimdblerr	;duplicate definition
dimema55:
	set32
	mov	es:[di+_ema2ndlim],ax	;2nd limit
	set32
	inc	ax
	jz	dimemailg

	set32
	mov	es:[di+_ema1stlim],bx	;1st limit
	set32
	inc	bx
	jz	dimemailg

	set32
	mul	bx		;edx:eax = # of elements
	set32
	or	dx,dx
	jnz	dimemaover
	set32
	push	ax		;*

	mov	cl,[emaunitlog]
	shl_edxeax_cl
	set32
	or	dx,dx
	jnz	dimemaover

	set32
	mov	bx,[emanow]	;ebx = limit+1
	set32
	add	ax,bx
dimema60:
	set32
	mov	es:[di+_emabaseadr],bx	;start adr
	set32
	mov	[emanow],ax	;next start adr

	set32
	push	bx		;* start adr

	;check EMS free space

	set32
	mov	dx,ax
	set32
	shr	dx,16
	cmp	dx,EMSmaxhigh
	jae	dimemaover

	mov	cx,EMSpagesize
	div	cx
	or	dx,dx
	jz	chkEMS10
	inc	ax
chkEMS10:
	add	ax,3		;pages-1
	and	ax,0fffch	;cut lowest 3bits
	mov	bx,ax		;total page number
	mov	ah,51h		;reallocation
	mov	dx,[emahandle]
	int	67h
	or	ah,ah
	jnz	dimemaover

	; make allocation map

	xor	bx,bx		;map 0 page
	mov	si,offset maptable
	makemaptbl	si,bx

	; do mapping

	mov	ax,5000h
	mov	dx,[emahandle]
	mov	cx,4
	mov	si,offset maptable
	int	67h
	or	ah,ah
	jnz	emsmaperror
	
	; set all elements to 0

	pop	di		;si:di = start ptr
	pop	si		;

	set32
	pop	dx		;edx = # of elements

	mov	es,[EMSbaseseg]
dimema90:
	set32
	push	dx

	mov	ax,si
	my_shl	ax,2
	cmp	ax,[maptable]	;mapped top page
	je	dimema95	;already mapped

	push	si
	push	di

	; make allocation map

	mov	bx,offset maptable
	my_shl	si,2		;*4
	makemaptbl     bx,si

	; do mapping

	mov	ax,5000h
	mov	dx,[emahandle]
	mov	cx,4
	mov	si,offset maptable
	int	67h
	or	ah,ah
	jnz	emsmaperror

	pop	di
	pop	si
dimema95:
	mov	word ptr es:[di],0	;set 0

	add	di,[emaunitbytes]
	adc	si,0
	set32
	pop	dx
	set32
	dec	dx
	jnz	dimema90

	pop	es
	ret

dimemaover:
	jmp	emaerr

dimemailg:
	jmp	ilgerr


;
; * use expanded ram
;

useema:
	call	far ptr farinitema
	jmp	mainlp

;
; * check expanded ram
;
EMAword:
	jmp	far ptr farEMAword


;
; * swap ema
;
swapema:
	call	getemaadr	;ecx = offset
	set32
	push	cx		;* offset1
	call	getfromema
	cmp	byte ptr [bp],0c2h	;code of ,
	jne	swapemasynerr	
	INC	BP
	cmp	word ptr [bp],0f580h	;code of ema(
	jne	swapemasynerr	
	add	bp,2
	call	getemaadr	;ecx = offset
	set32
	pop	ax
	set32
	push	cx		;* offset2
	set32
	push	ax		;** offset1
	call	getfromema

	set32
	pop	cx		;** offset1
	call	puttoema
	add	[calcsp],unitbyte
	set32
	pop	cx		;* offset2
	call	puttoema
	add	[calcsp],unitbyte
	jmp	mainlp

swapemasynerr:
	jmp	synerr

farSwapemasub:
	mov	ax,code2
	mov	es,ax
	set32
	mov	ax,es:[emablocknowB]
	set32
	push	ax		;*p2
	set32
	mov	cx,es:[emablocknow]
	set32
	push	cx		;**p1
	mov	ax,ss
	mov	es,ax
	call	getfromema	;get valA from var1
	set32
	pop	ax		;**p1
	set32
	pop	cx		;*p2
	set32
	push	cx		;*p2
	set32
	push	ax		;**p1
	call	getfromema	;get valB from var2

	set32
	pop	cx		;**p1
	call	puttoema	;write valB to var1
	add	[calcsp],unitbyte
	set32
	pop	cx		;*p2
	call	puttoema	;write valA to var2
	add	[calcsp],unitbyte
	retf

;
;* copy ema to ema by block
;
copyemasub:
	mov	ax,code2
	mov	es,ax
	set32
	mov	ax,es:[emablocknowB]
	set32
	push	ax
	set32
	mov	cx,es:[emablocknow]
	mov	ax,ss
	mov	es,ax
	call	getfromema
	set32
	pop	cx
	call	puttoema
	add	[calcsp],unitbyte
	retf


;
;* add ema (block+=const)
;
addemablkconstsub:
	mov	ax,code2
	mov	es,ax
	set32
	mov	cx,es:[emablocknow]
	set32
	push	cx
	mov	ax,ss
	mov	es,ax

	call	getfromema

	call	ahedsp
	mov	di,si
	add	si,2*unitbyte
	copy_si2di

	call	word ptr [blockoperation]

	set32
	pop	cx
	call	puttoema
	add	[calcsp],unitbyte
	retf

	;
	; * add ema (block+=block)
	;
addemablkblksub:
	mov	ax,code2
	mov	es,ax
	set32
	mov	cx,es:[emablocknowB]
	set32
	push	cx		;*
	set32
	mov	ax,es:[emablocknow]
	set32
	push	ax		;**
	mov	ax,ss
	mov	es,ax
	call	getfromema

	set32
	pop	cx		;**
	call	getfromema

	call	word ptr [blockoperation]

	set32
	pop	cx		;*
	call	puttoema
	add	[calcsp],unitbyte
	retf


;
; * negate ema
;
negema:
	call	getemaadr	;ecx = offset
	call	negemasub
	jmp	neg_next

negemasub:
	set32
	push	cx
	call	getfromema
	mov	si,[calcsp]
	call	negallsi
	set32
	pop	cx
	call	puttoema
	add	[calcsp],unitbyte
	ret

farnegemasub:
	call	negemasub
	retf

;
; * increment ema
;
incema:
	call	getemaadr	;ecx = offset
	set32
	push	cx		;offset
	call	getfromema
	mov	di,[calcsp]
	mov	ax,[emawords]
	mov	[limitlen],ax
	call	lvincin
	set32
	pop	cx		;offset
	call	puttoema
	add	[calcsp],unitbyte
	jmp	inc_next

;
; * decrement ema
;
decema:
	call	getemaadr	;ecx = offset
	set32
	push	cx		;offset
	call	getfromema
	mov	di,[calcsp]
	mov	ax,[emawords]
	mov	[limitlen],ax
	call	lvdecin
	set32
	pop	cx		;offset
	call	puttoema
	add	[calcsp],unitbyte
	jmp	dec_next

;
; * clear ema
;
clrema:
	call	getemaadr	;ecx = offset
	call	clremasub
	jmp	clr_next

clremasub:
	set32
	mov	ax,cx
	set32
	shr	ax,14
	and	al,0fch		;cut lowest 2 bits
	cmp	ax,[maptable]	;mapped top page
	je	clrema10	;already mapped
	call	mappage_ax
clrema10:
	push	ds
	mov	ds,[EMSbaseseg]
	mov	si,cx
	mov	word ptr [si],0
	pop	ds
	ret

farclremasub:
	call	clremasub
	retf


code	ends


DATA	SEGMENT	PUBLIC

	public	emahandle,emanow,emawords

	extrn	fnamebuf:byte
	extrn	calcsp:word
	extrn	maxword:word,limitlen:word
	extrn	blocksw:byte,blockoperation:word
	extrn	calcsp_limit:word

EMSbaseseg	dw	0
emahandle	dw	0
emanow		dw	0,0

emaunitlog	db	0,0
emaunitbytes	dw	0,0
emawords	dw	0

maptable	dw	0,0,0,1,0,2,0,3


data	ends



code2	segment	public
	assume	cs:code2,ds:data

	public	swapemablk,clremablk,negemablk,emablkin
	public	faremaword
	public	fardeleteema,emausing

	extrn	ahedsp2:near
	extrn	msg2:near,msg_cs2:near,get_char2:near,letnl2:near
	extrn	farBEEPSUB:far

	extrn	ex3ilgerr:near


;
; * jumped from freeze
;
emausing:
	mov	dx,offset emausingmsg
	call	msg_cs2
	jmp	far ptr ready

  if JAPANESE
emausingmsg	db	'‚d‚l‚`”z—ñŽg—p’†‚Ífreeze‚Å‚«‚Ü‚¹‚ñ',0
  else
emausingmsg	db	'cannot freeze including ema-arrays',0
  endif

;
; * use expanded ram
;

farinitema:
	call	initema
	retf

initema:
	mov	bx,[emahandle]
	or	bx,bx
	jnz	initemaret	;already got handle

	call	getemahandle
useemain:
	set32
	xor	ax,ax
	set32
	mov	[emanow],ax

  if FLG98
	mov	ax,emaattributeseg
  else
	mov	ax,ss
	add	ax,emaattributeseg
  endif
	mov	es,ax
	xor	di,di
	mov	cx,_emaattribsizeword*16	;16emas
	mov	ax,-1
	rep	stosw
	smov	es,ss

	mov	ax,[maxword]
	inc	ax		;+ attribute
	add	ax,ax
	call	goodEMSunitlog
	mov	[emaunitlog],cl
	mov	[emaunitbytes],ax
	shr	ax,1
	dec	ax
	mov	[emawords],ax
initemaret:
	ret


EMMMSG  db      'EMMXXXX0'

getemahandle:
        push    ds
        push    es
        xor     ax,ax           ;check int67h address is specified
        mov     ds,ax
        mov     bx,4*67h+2
        mov     es,[bx]
        mov     ax,cs
        mov     ds,ax
        mov     si,offset EMMMSG
        mov     di,0ah
        mov     cx,8
        repe    cmpsb
        pop     es
        pop     ds
        jne     noEMS

	mov	ah,40h
	int	67h
	or	ah,ah
	jnz	noEMS

	mov	ah,41h
	int	67h
	or	ah,ah
	jnz	noEMS
  if FLG98notXL
	cmp	bx,0c000h
  else
	cmp	bx,0a000h
  endif
	jb	ilgEMS
	mov	[EMSbaseseg],bx

	mov	ah,46h		;get EMM version
	int	67h
	or	ah,ah
	jnz	badEMS
	cmp	al,40h		;4.0 or later?
	jb	badEMS

	mov	ah,43h		;create handle
	mov	bx,1		;request 1 page
	int	67h	
	or	ah,ah
	jnz	EMSfull		;no page
	mov	[emahandle],dx

	mov	ah,51h		;return the 1 page
	xor	bx,bx
	int	67h

	ret

noEMS:
	mov	dx,offset noemsmsg
gotoready:
	call	msg_cs2
	jmp	far ptr ready

EMSfull:
	jmp	far ptr emaerr

ilgEMS:
	mov	dx,offset ilgEMSmsg
	jmp	gotoready

badEMS:
	mov	dx,offset badEMSmsg
	jmp	gotoready


  if JAPANESE
noemsmsg	db	'‚d‚l‚rƒhƒ‰ƒCƒo‚ª‚ ‚è‚Ü‚¹‚ñB',0
    if FLG98notXL
ilgEMSmsg	db	'‚d‚l‚r‚ÌƒAƒhƒŒƒX‚Í C000H ‚É‚µ‚Ä‚­‚¾‚³‚¢B',0
    else
ilgEMSmsg	db	'‚d‚l‚r‚ÌƒAƒhƒŒƒX‚Í A000H ˆÈã‚É‚µ‚Ä‚­‚¾‚³‚¢',0
    endif
badEMSmsg	db	'‚d‚l‚rƒhƒ‰ƒCƒo‚Ív4.0ˆÈã‚ª•K—v‚Å‚·B',0
  else
noemsmsg	db	'EMS driver is not ready.',0
ilgEMSmsg	db	'EMS address must >= A000H',0
badEMSmsg	db	'EMS driver is too old.',0
  endif


goodEMSunitlog:
	; inp: ax = unitbytes to get
	; out: ax = unitbytes decided mustbe power of 2
	;      cl = its log2

	push	dx
	mov	dx,1
	mov	cl,0
goodEMS50:
	add	dx,dx
	inc	cl
	cmp	ax,dx
	ja	goodEMS50
	mov	ax,dx
;goodEMS60:
;	cmp	ax,UNITBYTE
;	jbe	goodEMS70
;	shr	ax,1
;	dec	cl
;	jmp	goodEMS60
;goodEMS70:
	pop	dx
	ret
	
;
; * dealloc EMS memory
;	for SYSTEM command
fardeleteema:
	mov	dx,[emahandle]
	or	dx,dx
	jz	delema10	;already closed or not used

	mov	ah,45h		;close handle
	int	67h
	mov	[emahandle],0
delema10:
	retf

;
; * ema word
;

emacantdo:
	jmp	far ptr undeferr

farEMAword:
	call	initema

	;get word

	mov	dh,80h		;stop to display
	mov	cx,[emawords]	;default
	mov	al,[bp]
	cmp	al,CR
	je	emaword40
	cmp	al,3ah		;code of ':'
	je	emaword40
	mov	cx,[maxword]
	mov	al,[bp]
	inc	bp
	cmp	al,0e5h		;code of '*'
	je	emaword40
	dec	bp
	call	far ptr farformul
	backsp_mac
	lodsw
	mov	dx,ax

	and	ax,lenmask
	cmp	ax,1
;	jb	emawordilg
	jne	emawordilg
	mov	cx,[si]
	cmp	cx,limitword
	ja	emawordilg
emaword40:
	mov	ax,cx
	inc	ax		;attribute
	add	ax,ax
	call	goodEMSunitlog
	mov	[emaunitlog],cl
	mov	[emaunitbytes],ax
	shr	ax,1
	dec	ax
	mov	[emawords],ax

	test	dh,80h
	jnz	emaword100	;non display if word < 0

	mov	dx,offset EMSwordmsg
	call	msg_cs2
	mov	bx,[emawords]
	call	far ptr farprntbx
	call	letnl2
emaword100:
	set32
	xor	ax,ax
	set32
	mov	[emanow],ax

  if FLG98
	mov	ax,emaattributeseg
  else
	mov	ax,ss
	add	ax,emaattributeseg
  endif
	mov	es,ax
	mov	di,0
	mov	cx,_emaattribsizeword*16	;16emas
	mov	ax,-1
	rep	stosw
	smov	es,ss

emawordret:
	jmp	far ptr mainlp


emawordilg:
	jmp	ex3ilgerr


  if JAPANESE
EMSwordmsg	db	'‚d‚l‚`”z—ñ‚Ì—v‘f‚Ìƒ[ƒh”‚Í ',0
  else
EMSwordmsg	db	'EMA element size is ',0
  endif

	align	4
emaworkstart:
emablockind2	dw	?,?
emablockind20	dw	?,?
emablockind21	dw	?,?
emablockcount2	dw	?,?
emablockind1	dw	?,?
emablockind10	dw	?,?
emablockind11	dw	?,?
emablockcount1	dw	?,?
emablockstep	dw	?,?
emablocknow	dw	?,?
emaworkend1:

emablockcount2B	dw	?,?
emablockcount1B	dw	?,?
emablockstepB	dw	?,?
emablocknowB	dw	?,?


emablockparamini:
	my_shl	ax,_emaattribsizelog
	mov	di,ax

  if FLG98
	mov	ax,emaattributeseg
  else
	mov	ax,ss
	add	ax,emaattributeseg
  endif
	mov	es,ax

	cmp	word ptr es:[di+_emabasehigh],-1
	je	emablockparamundef

	set32
	mov	ax,es:[di+_emabaseadr]
	set32
	mov	[emablocknow],ax
	set32
	mov	ax,es:[di+_ema1stlim]
	set32
	mov	[emablockind1],ax
	set32
	mov	ax,es:[di+_ema2ndlim]
	set32
	mov	[emablockind2],ax

	smov	es,ss
	ret


emablockparamcantdo:
	jmp	far ptr undeferr


emablockparam:
	cmp	[emahandle],0
	je	emablockparamcantdo

	smov	es,cs
	mov	cx,offset emaworkend1-emaworkstart
	shr	cx,1
	xor	ax,ax
	mov	di,offset emaworkstart
	rep	stosw
	smov	es,ss

	cmp	byte ptr [bp],0e5h	;'*'
	jne	emablockparam5

	xor	ax,ax		;ema0
	call	emablockparamini
	jmps	emablk150

emablockparam5:
	call	far ptr farGet_eax	;get ema number
	jc	emablockindERR
	cmp	byte ptr [bp],0c1h	;code of ;
	je	emablockparam10

	set32			;eax = 1st param of ema0
	push	ax
	xor	ax,ax
	call	emablockparamini
	set32
	pop	ax
	jmps	emablk110

emablockparam10:
	inc	bp		;skip ;
	set32			;check eax < 16
	cmp	ax,16
	dw	0		;for higher 16bits
	jae	emablockparamilg
	call	emablockparamini

	;‚PŽŸŒ³–Ú
;emablk100:
	CMP	BYTE PTR [BP],0e5h	;'*'
	je	emablk150
	call	far ptr farGet_eax
	jc	emablockinderr
emablk110:
	set32
	MOV	[emablockind10],AX
	CMP	BYTE PTR [BP],0C3H	;'..'
	JNE	emablk190
	INC	BP
	call	far ptr farGet_eax
	jnc	emablk190
	jmp	emablockindERR
emablk150:
	inc	bp
	set32
	xor	ax,ax
	set32
	mov	[emablockind10],ax
	set32
	MOV	ax,[emablockind1]
emablk190:
	set32
	MOV	[emablockind11],AX
	jmps	emablk200

emablockparamilg:
	jmp	far ptr ilgerr
emablockparamundef:
	jmp	far ptr undeferr
emablkSYNERR:
	JMP	far ptr SYNERR
emablockindERR:
	JMP	far ptr INDEXERR


	;‚QŽŸŒ³–Ú
emablk200:
	CMP	BYTE PTR [BP],0c2h	;','
	jne	emablockout
	inc	bp
	CMP	BYTE PTR [BP],0e5h	;'*'
	je	emablk250
	call	far ptr farGet_eax
	jc	emablockindERR
	set32
	MOV	[emablockind20],AX
	CMP	BYTE PTR [BP],0C3H	;'..'
	JNE	emablk290
	INC	BP
	call	far ptr farGet_eax
	jnc	emablk290
	Jmp	emablockindERR
emablk250:
	inc	bp
	set32
	xor	ax,ax
	set32
	mov	[emablockind20],ax
	set32
	MOV	ax,[emablockind2]
emablk290:
	set32
	MOV	[emablockind21],AX

emablockout:
	CMP	BYTE PTR [BP],')'
	JNE	emablksynERR
	INC	BP		;pass )

	set32
	mov	ax,[emablockind21]
	set32
	cmp	ax,[emablockind2]
	ja	emablockinderr
	set32
	sub	ax,[emablockind20]
	jb	emablockinderr
	set32
	inc	ax
	set32
	mov	[emablockcount2],ax

	set32
	mov	ax,[emablockind11]
	set32
	cmp	ax,[emablockind1]
	ja	emablockinderr
	set32
	sub	ax,[emablockind10]
	jb	emablockinderr
	set32
	inc	ax
	set32
	mov	[emablockcount1],ax

	set32
	mov	ax,[emablockind2]
	set32
	sub	ax,[emablockind21]
	set32
	add	ax,[emablockind20]
	set32
	mul	word ptr [emaunitbytes]
	set32
	mov	[emablockstep],ax

	set32
	mov	ax,[emablockind10]
	set32
	mov	bx,[emablockind2]
	set32
	inc	bx
	set32
	mul	bx
	set32
	add	ax,[emablockind20]
	mov	cl,[emaunitlog]
	set32
	shl	ax,cl
	set32
	add	[emablocknow],ax
	ret

;
; * clear ema by block
;
clremablk:
	add	bp,2
	CALL	emaBLOCKPARAM
	set32
	mov	cx,[emablocknow]
	set32
	mov	ax,[emablockcount1]
clremablklp10:
	set32
	push	ax
	set32
	mov	ax,[emablockcount2]
clremablklp20:
	set32
	push	ax
	set32
	push	cx
	call	far ptr farclremasub
	set32
	pop	cx
	set32
	add	cx,[emaunitbytes]
	set32
	pop	ax
	set32
	dec	ax
	jnz	clremablklp20
	set32
	add	cx,[emablockstep]
	set32
	pop	ax
	set32
	dec	ax
	jnz	clremablklp10

	mov	[blocksw],0
	jmp	far ptr clr_next


;
; * neg ema by block
;
negemablk:
	add	bp,2
	CALL	emaBLOCKPARAM
	set32
	mov	si,[emablocknow]
	set32
	mov	cx,[emablockcount1]
negemablklp10:
	set32
	push	cx
	set32
	mov	cx,[emablockcount2]
negemablklp20:
	set32
	push	cx
	set32
	push	si
	set32
	mov	cx,si
	call	far ptr farnegemasub
	set32
	pop	si
	set32
	xor	ax,ax
	set32
	mov	ax,[emaunitbytes]
	set32
	add	si,ax
	set32
	pop	cx
	set32
	myloop	negemablklp20
	set32
	add	si,[emablockstep]
	set32
	pop	cx
	set32
	myloop	negemablklp10

	mov	[blocksw],0
	jmp	far ptr neg_next

;
; * swap ema by block
;
swapemablkilg:
	jmp	far ptr blockerr
swapemablksynerr:
	jmp	far ptr synerr

swapemablk:
	add	bp,2
	CALL	emaBLOCKPARAM
	set32
	mov	ax,[emablockstep]
	set32
	mov	[emablockstepB],ax
	set32
	mov	ax,[emablocknow]
	set32
	mov	[emablocknowB],ax
	set32
	mov	ax,[emablockcount1]
	set32
	mov	[emablockcount1B],ax
	set32
	mov	dx,[emablockcount2]
	set32
	mov	[emablockcount2B],dx
	set32
	mul	dx
	set32
	push	ax
	set32
	push	dx
	cmp	byte ptr [bp],0c2h	;code of ,
	jne	swapemablksynerr	
	INC	BP
	cmp	byte ptr [bp],0A2H	;BLOCK
	JNE	SWAPemaBLK10		;‚Q‚Â–Ú‚Ì block ‚Í‚È‚­‚Ä‚à‰Â
	INC	BP
SWAPemaBLK10:
	cmp	word ptr [bp],0f580h	;code of ema(
	jne	swapemablksynerr	
	add	bp,2
	CALL	emaBLOCKPARAM
	set32
	mov	ax,[emablockcount1]
	set32
	mul	[emablockcount2]
	set32
	pop	cx
	set32
	pop	bx
	set32
	cmp	ax,bx
	jne	swapemablkilg		;ŒÂ”‚ªˆê’v‚¹‚¸
	set32
	cmp	dx,cx
	jne	swapemablkilg		;ŒÂ”‚ªˆê’v‚¹‚¸
	set32
	or	cx,cx
	jnz	swapemablkilg

	set32
	mov	cx,[emablockcount1]
	set32
	mov	dx,[emablockcount2B]
swapemablklp10:
	set32
	push	cx
	set32
	mov	cx,[emablockcount2]
swapemablklp20:
	set32
	push	cx
	set32
	push	dx

	call	far ptr farswapemasub

	set32
	mov	ax,[emaunitbytes]
	set32
	add	[emablocknow],ax
	set32
	add	[emablocknowB],ax
	set32
	pop	dx
	set32
	dec	dx
	jz	swapemablk110
swapemablk30:
	set32
	pop	cx
	set32
	myloop	swapemablklp20

	set32
	mov	ax,[emablockstep]
	set32
	add	[emablocknow],ax
	set32
	pop	cx
	set32
	myloop	swapemablklp10

	mov	[blocksw],0
	jmp	far ptr mainlp

swapemablk110:
	set32
	mov	ax,[emablockstepB]
	set32
	add	[emablocknowB],ax
	set32
	mov	dx,[emablockcount2B]
	jmp	swapemablk30


;
; * let ema by block
;
emablkin:
	add	bp,2
	CALL	emaBLOCKPARAM
	mov	ax,[bp]
	cmp	ah,codeofequal
	jmpz	emablockexpanded
	cmp	al,codeofequal
	jne	letemablksynerr

	inc	bp
	cmp	ah,0a2h		;BLOCK
	jne	letemablksimple
	jmp	copyemablock

	; case of letting a fixed value

letemablksimple:
	call	far ptr farformul

	set32
	mov	si,[emablocknow]
	set32
	mov	cx,[emablockcount1]
letemablklp10:
	set32
	push	cx
	set32
	mov	cx,[emablockcount2]
letemablklp20:
	set32
	push	cx
	set32
	push	si

	set32
	mov	cx,si
	call	far ptr farputtoema

	set32
	pop	si
	set32
	add	si,[emaunitbytes]
	set32
	pop	cx
	set32
	myloop	letemablklp20
	set32
	add	si,[emablockstep]
	set32
	pop	cx
	set32
	myloop	letemablklp10

	mov	[blocksw],0
	add	[calcsp],unitbyte
	jmp	far ptr mainlp

letemablkover:
	jmp	far ptr ovrerr

letemablkilg:
	jmp	far ptr blockerr
letemablksynerr:
	jmp	far ptr synerr

	; case of copy block

copyemablock:
	set32
	mov	ax,[emablockstep]
	set32
	mov	[emablockstepB],ax
	set32
	mov	ax,[emablocknow]
	set32
	mov	[emablocknowB],ax
	set32
	mov	ax,[emablockcount1]
	set32
	mov	[emablockcount1B],ax
	set32
	mov	dx,[emablockcount2]
	set32
	mov	[emablockcount2B],dx
	set32
	mul	dx
	set32
	push	ax
	set32
	push	dx
	inc	bp
	cmp	word ptr [bp],0f580h	;code of ema(
	jne	letemablksynerr	
	add	bp,2
	CALL	emaBLOCKPARAM
	set32
	mov	ax,[emablockcount1]
	set32
	mul	[emablockcount2]
	set32
	pop	cx
	set32
	pop	bx
	set32
	cmp	ax,bx
	jne	letemablkilg		;ŒÂ”‚ªˆê’v‚¹‚¸
	set32
	cmp	dx,cx
	jne	letemablkilg		;ŒÂ”‚ªˆê’v‚¹‚¸
	set32
	or	cx,cx
	jnz	letemablkilg

	set32
	mov	cx,[emablockcount1]
	set32
	mov	dx,[emablockcount2B]
copyemablklp10:
	set32
	push	cx
	set32
	mov	cx,[emablockcount2]
copyemablklp20:
	set32
	push	cx
	set32
	push	dx

	call	far ptr copyemasub

	set32
	mov	ax,[emaunitbytes]
	set32
	add	[emablocknow],ax
	set32
	add	[emablocknowB],ax
	set32
	pop	dx
	set32
	dec	dx
	jz	copyemablk110
copyemablk30:
	set32
	pop	cx
	set32
	myloop	copyemablklp20

	set32
	mov	ax,[emablockstep]
	set32
	add	[emablocknow],ax
	set32
	pop	cx
	set32
	myloop	copyemablklp10

	mov	[blocksw],0
	jmp	far ptr mainlp

copyemablk110:
	set32
	mov	ax,[emablockstepB]
	set32
	add	[emablocknowB],ax
	set32
	mov	dx,[emablockcount2B]
	jmp	copyemablk30


	;
	; case of let with operation
	;
emablockexpanded:
	mov	bx,offset addin
	cmp	al,0ddh
	je	setblockoperation
	mov	bx,offset subin
	cmp	al,0deh
	je	setblockoperation
	mov	bx,offset mulin
	cmp	al,0e5h
	je	setblockoperation
	mov	bx,offset divin
	cmp	al,0e6h
	je	setblockoperation
	mov	bx,offset resin
	cmp	al,0e7h
	je	setblockoperation
	mov	bx,offset idivin
	cmp	al,0e8h
	je	setblockoperation
	mov	bx,offset ratdivin
	cmp	al,0e9h
	je	setblockoperation

	jmp	far ptr synerr
addemablksperr:
	jmp	far ptr sperr


setblockoperation:
	mov	[blockoperation],bx
	
	;GET SOURCE ADR

	mov	ax,[calcsp]
	sub	ax,3*unitbyte
	cmp	ax,[calcsp_limit]
	jb	addemablksperr

	add	bp,2
	cmp	byte ptr [bp],0a2h	;BLOCK
	jmpz	addemablkblk

	; case of block+=const

addemablkconst:
	call	far ptr farformul	;calc right side

	set32
	mov	cx,[emablockcount1]
addemablklp10:
	set32
	push	cx
	set32
	mov	cx,[emablockcount2]
addemablklp20:
	set32
	push	cx

	call	far ptr addemablkconstsub

	set32
	mov	ax,[emaunitbytes]
	set32
	add	[emablocknow],ax
	set32
	pop	cx
	set32
	myloop	addemablklp20
	set32
	mov	ax,[emablockstep]
	set32
	add	[emablocknow],ax
	set32
	pop	cx
	set32
	myloop	addemablklp10

	mov	[blocksw],0
	add	[calcsp],unitbyte
	jmp	far ptr mainlp

addemablkover:
	jmp	far ptr ovrerr
addemablkblkilg:
	jmp	far ptr blockerr
addemablkblksynerr:
	jmp	far ptr synerr

	; case of block+=block

addemablkblk:
	set32
	mov	ax,[emablockstep]
	set32
	mov	[emablockstepB],ax
	set32
	mov	ax,[emablocknow]
	set32
	mov	[emablocknowB],ax
	set32
	mov	ax,[emablockcount1]
	set32
	mov	[emablockcount1B],ax
	set32
	mov	dx,[emablockcount2]
	set32
	mov	[emablockcount2B],dx
	set32
	mul	dx
	set32
	push	ax
	set32
	push	dx
	inc	bp
	cmp	word ptr [bp],0f580h	;code of ema(
	jne	addemablkblksynerr	
	add	bp,2
	CALL	emaBLOCKPARAM
	set32
	mov	ax,[emablockcount1]
	set32
	mul	[emablockcount2]
	set32
	pop	cx
	set32
	pop	bx
	set32
	cmp	ax,bx
	jne	addemablkblkilg		;ŒÂ”‚ªˆê’v‚¹‚¸
	set32
	cmp	dx,cx
	jne	addemablkblkilg		;ŒÂ”‚ªˆê’v‚¹‚¸
	set32
	or	cx,cx
	jnz	addemablkblkilg

	set32
	mov	cx,[emablockcount1]
	set32
	mov	dx,[emablockcount2B]
addemablkblklp10:
	set32
	push	cx
	set32
	mov	cx,[emablockcount2]
addemablkblklp20:
	set32
	push	cx
	set32
	push	dx

	call	far ptr addemablkblksub

	set32
	mov	ax,[emaunitbytes]
	set32
	add	[emablocknow],ax
	set32
	add	[emablocknowB],ax
	set32
	pop	dx
	set32
	dec	dx
	jz	addemablkblk110
addemablkblk30:
	set32
	pop	cx
	set32
	myloop	addemablkblklp20
	set32
	mov	ax,[emablockstep]
	set32
	add	[emablocknow],ax
	set32
	pop	cx
	set32
	myloop	addemablkblklp10

	mov	[blocksw],0
	jmp	far ptr mainlp

addemablkblk110:
	set32
	mov	ax,[emablockstepB]
	set32
	add	[emablocknowB],ax
	set32
	mov	dx,[emablockcount2B]
	jmp	addemablkblk30

code2	ends
end
