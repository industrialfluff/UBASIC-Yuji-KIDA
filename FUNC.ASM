;FUNC.ASM


DATA	SEGMENT	WORD PUBLIC

	PUBLIC	DATE,HOUR,MINUTE,SECOND,MSECOND,TICKCOUNTS
	PUBLIC	DATE2,HOUR2,MINUTE2,SECOND2
	public	packeddata,packedlength,packedptr

	extrn	xpos:byte,ypos:byte
	EXTRN	CALCSP:WORD,calcsp_limit:word,POINTWORD:WORD
	extrn	compilejp_sw:byte
;	extrn	polymodulus:word
	extrn	fixedflag:byte


DATE	DB	0
HOUR	DB	0
MINUTE	DB	0
SECOND	DB	0
MSECOND	DB	0
TICKCOUNTS	DD	0

DATE2	DB	0
HOUR2	DB	0
MINUTE2	DB	0
SECOND2	DB	0
MSECOND2	DW	0
SECONDMEM	DB	0


COSFLG		DB	?
coshflg		db	?
ATAN_CHG	DB	?
		db	?		;dummy

	even
bessel_count	dw	?
bessel_IJ	db	0,0

packeddata	dw	?
packedlength	dw	?
packedptr	dw	?

randomnow	dd	4e3ce5edh	;some value at some time

DATA	ENDS


CODE	SEGMENT WORD PUBLIC
	ASSUME	CS:CODE,DS:DATA

	PUBLIC	FUNCIN,encodein,packin

	PUBLIC	ANDIN,ORIN
	PUBLIC	COSIN,COS_ENT,SININ,SIN_ENT
	PUBLIC	farCOS_ENT,farSIN_ENT
	PUBLIC	TAN_ENT,ARCTAN,ATAN_ENT,farARCTAN
	PUBLIC	randomize,randomize_main
	public	argin,arg_ent,midparamin,midparam2,cvr
	public	shiftleft_di,ishiftright_di

	public	xchgsidi,farxchgsidi

	extrn	mainlp:near,setcomplex:near
	EXTRN	KAKKO:NEAR,AHEDSP:NEAR,BACKSP:NEAR,CHG2POINT:NEAR
	extrn	cursor:near,curson:near,cursoff:near

	extrn	real2floatbxjust:near
	extrn	floatsetdiax:near,farfloatsetdiax:far
	extrn	floatmuldiax:near
	extrn	floatdivdiax:near,farfloatdivdiax:far
	extrn	addFFdisi:near,subFFdisi:near,compFFdisi:near
	extrn	mulFFdisi:near,divFFdisi:near,idivFFdisi:near
	extrn	faraddFFdisi:far,farsubFFdisi:far
	extrn	farmulFFdisi:far
	extrn	squareFdi:near,farsquareFdi:far,farsquareIFCdi:far
	extrn	factorialFFdiax:near,farfactorialFFdiax:far
	extrn	powerFCdiax:near,farpowerFCdiax:far
	extrn	idivIIdisi:NEAR,faridivIIdisi:far
	extrn	addAAdisi:near,subAAdisi:near,mulAAdisi:near
	extrn	mulIorFdisi:near
	extrn	divIorFdisi:near,fardivIorFdisi:far

	extrn	emain:near,paremaword:near

	extrn	get_ax:near,kakko_ax:near,kakko_ax_signed:near
	extrn	formul:near,passtoken:near

	extrn	fgetbytes:near

	extrn	absmax:near,absadd:near

	extrn	divin:near,mulin:near,powerin:near,idivin:near
	EXTRN	ADDIN:NEAR,LLADD:NEAR,LWADD:NEAR
	EXTRN	SUBIN:NEAR,LLSUB:NEAR,LWSUB:NEAR
	extrn	encdin:near,compilevardirect:near,DecodeToken:near
	extrn	getgraph:near

	extrn	find:near

	extrn	intin:near,roundin:near,fixin:near

	EXTRN	SYNERR:NEAR,OVRERR:NEAR,FUNCERR:NEAR,ilgerr:near
	extrn	calcsperr:near,floaterr:near


;
;* xchg ubasic standard data
;
farxchgsidi:
	call	xchgsidi
	retf

xchgsidi:
	mov	bx,[si]
	mov	cx,[di]
	mov	[di],bx
	mov	[si],cx
	and	bx,lenmask
	and	cx,lenmask
	winc	si
	winc	di
	cmp	bx,cx
	ja	xchg10
	xchg	bx,cx
	xchg	si,di
xchg10:
	sub	bx,cx
	jcxz	xchg20
xchglp:
	mov	ax,[si]
	mov	dx,[di]
	mov	[di],ax
	mov	[si],dx
	winc	si
	winc	di
	loop	xchglp
xchg20:
	mov	cx,bx
	rep	movsw
	ret


;
;* ubasic functions
;

getemaword:
	jmp	paremaword
extrafunc:
	cmp	al,0abh-0b0h
	je	getemaword
	cmp	al,88h-0b0h
	jmpz	getdir
	cmp	al,99h-0b0h
	jmpz	getdate
	cmp	al,9ah-0b0h
	jmpz	gettime
	cmp	al,91h-0b0h
	jmpz	getpolymod
FUNCSYNERR:
	jmp	synerr

FUNCIN:	
	INC	BP		;inc pointer
	MOV	AL,[BP]
	INC	BP
	SUB	AL,0B0H
	jb	extrafunc
	CMP	AL,4fH		;4fH=FfH-B0H
	JA	FUNCSYNERR
	XOR	BX,BX
	MOV	BL,AL
	SHL	BX,1
	JMP	CS:FUNC_TBL[BX]



USRERR:				;USER FUNCTION CALL
	STC
	RET


	EVEN
FUNC_TBL	DW	ROUNDin
	DW	ARGIN,IRANDOM,CONJUGATE
	DW	REALPART,IMAGPART,SINH,COSH
	DW	COMBIN,ascin,right,mid
	DW	left,packin,ABSMAX,ABSADD

	DW	ABSIN,SGNIN,LENIN,BITIN
	DW	GCDIN,SQRTIN,ISQRTIN,FIXIN
	DW	KROIN,SININ,COSIN,cEXPIN
	DW	LOGIN,PAIIN,PRIMEIN,MOBIUS
	DW	EULER,PRMDIV,EOFIN,CHR$IN
	DW	EXT1IN,SYNERR,EXT2IN,SYNERR
	DW	EXT3IN,FUNCERR,MODPOW,MODINV
	DW	INTIN,ASCLEN,NXTPRM,MAXin
	DW	MINin,SHIFT,FUNCERR,SPCIN
	DW	FIND,ODDIN,EVENIN,ANDIN
	DW	ORIN,FACTORIAL,RANDOM,ARCTAN
	DW	SYNERR,TANin,EXP1,epsilon
	DW	eulerconst,input$,besselJ,besselI

	DW	multipi,emain,inkey,rat2real

	DW	encodein,decodein,getgraph,polyin
	DW	str$in,valin,memberin,coeffin

;
;* n-th member of a string/packed data
;
membersynerr:
	jmp	synerr

gostringmember:
	jmp	far ptr stringmember

memberin:
	call	formul
	cmp	byte ptr [bp],0c2h	;code of ,
	jne	membersynerr
	inc	bp
	call	kakko_ax
	jc	memberilgerr
	mov	cx,ax		;order
	jcxz	memberilgerr	;order must >=1
	mov	si,[calcsp]
	add	si,unitbyte
	mov	[calcsp],si	;kakko_ax doesnot pop[calcsp]
	lodsw
	and	ah,attribmaskhigh
	cmp	ah,stringmaskhigh
	je	gostringmember
	cmp	ah,packmaskhigh
	je	memberpack
memberilgerr:
	jmp	ilgerr

memberpack:
	mov	bx,si		;bx=[calcsp]+2
	lodsw			;ax=number of members	
	cmp	ax,cx
	jb	memberilgerr
	dec	cx
	jz	memberpack40
memberpack30:			;skip members
	lodsw
	and	ax,lenmask
	add	ax,ax
	add	si,ax
	myloop	memberpack30
memberpack40:
	lea	di,[bx-2]
	copy_si2di
	ret

;
; * coefficients of polynomial
;
coeffsynerr:
	jmp	synerr

coeffin:
	call	formul
	cmp	byte ptr [bp],0c2h	;code of ,
	jne	coeffsynerr
	inc	bp
	call	kakko_ax
	jc	coeffilgerr
	mov	cx,ax
	mov	si,[calcsp]
	add	si,unitbyte
	mov	[calcsp],si	;kakko_ax doesnot pop[calcsp]
	lodsw
	and	ah,attribmaskhigh
	cmp	ah,polymaskhigh
	je	coeff_poly
	cmp	ah,modpolymaskhigh
	je	coeff_modpoly
	cmp	word ptr [si-2],0
	jne	coeffilgerr
	ret			;if 0 then 0
coeffilgerr:
	jmp	ilgerr

coeff_poly:
	lea	di,[si-2]
	lodsw
	dec	ax		;degree
	cmp	ax,cx
	jb	polynocoeff
	jcxz	coeffpoly20
coeffpoly10:
	lodsw
	and	ax,lenmask
	add	ax,ax
	add	si,ax
	myloop	coeffpoly10
coeffpoly20:
	copy_si2di
	ret

polynocoeff:
	mov	word ptr [di],0
	ret

coeff_modpoly:
	lea	di,[si-2]	;base adr
	mov	ax,[di]
	and	ax,lenmask
	shr	ax,1
	sub	ax,2		;degree
	cmp	ax,cx
	jb	polynocoeff			
	set32
	lodsw			;modulus
;	cmp	ax,[polymodulus]
;	jne	coeffilgerr
	shl	cx,2
	add	si,cx
	xor	cx,cx
	set32
	mov	ax,[si]
	set32
	or	ax,ax
	jz	modpolycoeff20
	inc	cx
	mov	[di+2],ax
	set32
	shr	ax,16
	or	ax,ax
	jz	modpolycoeff20
	inc	cx
	mov	[di+4],ax
modpolycoeff20:
	mov	[di],cx
	ret


;
;* rational to real
;
rat2realilg:
	jmp	ilgerr

rat2real:
	call	kakko
	mov	si,[calcsp]
	lodsw
	test	ah,nonnumericmaskhigh
	jnz	rat2realilg	;non numeric
	test	ah,complexmaskhigh
	jnz	rat2realilg	;complex
	test	ah,ratmaskhigh
	jz	rat2realret
cvr:
	checkcalcsp	1
	cmoveimag	1,0
	cmovereal	0,0
	cdiv	0,1
rat2realret:
	ret
	

;
;* value of numeric string
;

val_poly?:
	cmp	byte ptr [bp],0c2h	;','
	jne	val_synerr
	inc	bp
	call	kakko
	mov	bx,[calcsp]
	lea	si,[bx+unitbyte]
	mov	ax,[si]
	and	ah,attribmaskhigh
	cmp	ah,polymaskhigh
	je	go_val_poly
cmp	ah,modpolymaskhigh
je	go_val_modpoly
test	ah,nonnumericmaskhigh
jnz	val_ilg
; *now val(numeric, numeric)
mov	[calcsp],si
ret

go_val_modpoly:
	mov	ax,[bx]
;	cmp	ah,modpolymaskhigh
;	je	go_val_modpoly_out
	test	ah,attribmaskhigh
	jnz	val_ilg
;go_val_modpoly_out:
	jmp	far ptr val_modpoly
go_val_poly:
	mov	ax,[bx]
	cmp	ah,polymaskhigh
	je	go_val_poly_out
	test	ah,nonnumericmaskhigh
	jnz	val_ilg
go_val_poly_out:
	jmp	far ptr val_poly	


val_synerr:
	jmp	synerr
val_ilg:
	jmp	ilgerr

valin:
	call	formul
	cmp	byte ptr [bp],')'
	jne	val_poly?
	inc	bp

	mov	si,[calcsp]
	lodsw
	mov	cx,ax
	jcxz	val_ret		;if 0
	and	ch,attribmaskhigh
	cmp	ch,stringmaskhigh
	jne	val_ilg
val_string:
	cmp	byte ptr [si],0
	je	val_encoded
	mov	cx,ax
	and	cx,lenmask
	sub	si,2
	call	encode10
	mov	si,[calcsp]
	lodsw
val_encoded:
	add	ax,ax
	sbb	ax,0
	and	ax,2*lenmask+1
	cmp	ax,2
	jbe	valnull		;at most only CR

	push	bp		;*
	lea	bp,[si+1]
	add	si,ax
	mov	byte ptr [si],0		;end mark
	call	formul			;(+2)
	mov	si,[calcsp]
	lea	di,[si+unitbyte]
	mov	[calcsp],di		;(+1)
	copy_si2di
	pop	bp
val_ret:
	ret

valnull:
	mov	word ptr [si-2],0
	ret	

;
;* binary expression of numerical string
;
encodecalcsperr:
	jmp	calcsperr

encodein:
	call	kakko		;(+1)

	mov	si,[calcsp]
	mov	ax,[si]		;copy to deeper stack
	mov	cx,ax
	and	ah,attribmaskhigh
	cmp	ah,stringmaskhigh
	jne	encodeilg	;not string
	and	cx,lenmask
	jz	encodenull	;set 0 if null string

	cmp	byte ptr [si+2],0
	je	encoderet	;already encoded
encode10:
	lea	di,[si-unitbyte]
	cmp	di,[calcsp_limit]
	jb	encodecalcsperr
	mov	[calcsp],di	;(+2)

	inc	cx
	rep	movsw

	push	bp		;*

	mov	si,[calcsp]
	lodsw
	lea	di,[si+unitbyte]
	mov	byte ptr [di],0	;encoded mark
	inc	di
	mov	bp,si
	add	ax,ax
	sbb	ax,0
	and	ax,2*lenmask+1
	cmp	ax,unitbyte-2
	jae	encodeilg
	add	si,ax
	mov	byte ptr [si],CR	;endmark for encdin
	call	encdin

	mov	word ptr [di],0		;end mark for encode
	mov	si,[calcsp]
	add	si,unitbyte
	mov	[calcsp],si		;(+1)
	mov	ax,di
	sub	ax,si
	dec	ax		;-2+1
	shr	ax,1
	jc	encode50
	or	ah,80h		;if odd bytes
encode50:
	or	ah,stringmaskhigh
	mov	[si],ax
	add	si,3		;skip encoded mark
	call	compilevardirect
	pop	bp
encoderet:
	ret

encodenull:
	mov	word ptr [si],stringmask+8001h
	mov	word ptr [si+2],0
	ret
	
encodeilg:
	jmp	ilgerr

;
;* decode a encoded numeric string
;  inserting spaces as separators
;
decodeilgerr:
	jmp	ilgerr

decodein:
	call	kakko
	checkcalcsp	1
	cmove	1,0
	mov	di,[calcsp]
	lea	si,[di-unitbyte]
	lodsw
	mov	ch,ah
	and	ch,attribmaskhigh
	cmp	ch,stringmaskhigh
	jne	decodeilgerr
	add	ax,ax
	sbb	ax,0
	and	ax,lenmask*2+1
	mov	cx,ax
	lodsb
	or	al,al
	jnz	decodeilgerr
	push	bp
	mov	bp,si
	add	si,cx		;highest byte adr+1
	mov	byte ptr [si],CR	;end mark for DECODE
	add	di,2

decode30:			;decode main part
	mov	al,[bp]
	inc	bp
	cmp	al,CR
	je	decode50
	call	DecodeToken
	mov	al,' '		;put space after each token
	stosb			;
	jmp	decode30
decode50:
	dec	di
	mov	byte ptr [di],0

	pop	bp
	mov	si,[calcsp]
	mov	ax,di
	sub	ax,si
	dec	ax		;-2+1
	shr	ax,1
	jc	decoderet
	or	ah,80h		;if odd length
decoderet:
	or	ah,stringmaskhigh
	mov	[si],ax
	ret	

	
;
;* string expression of a value
;

str$in:
	call	kakko
str$ent:
	call	far ptr farSTR$ent
	ret

;
;* right
;
rightsynerr:
	jmp	synerr
rightilgerr:
	jmp	ilgerr

rightpack:
	mov	dx,[si+2]
	cmp	ax,dx
	jbe	rightpack10
	mov	ax,dx
rightpack10:
	sub	dx,ax
	inc	dx
	jmp	midpack

right:
	call	formul
	mov	ax,1
	cmp	byte ptr [bp],')'
	je	right5
	cmp	byte ptr [bp],0c2h	;code of ,
	jne	rightsynerr
	inc	bp
	call	get_ax
	jc	rightilgerr
right5:
	mov	si,[calcsp]
	mov	bx,si
	mov	cx,[si]
	mov	dh,ch
	and	dh,attribmaskhigh
	cmp	dh,packmaskhigh
	je	rightpack
	cmp	dh,stringmaskhigh
	jne	rightilgerr	;not string
	shl	cx,1
	sbb	cx,0
	and	cx,2*lenmask+1
	cmp	ax,cx
	jge	right100
	add	si,2
	mov	di,si
	add	si,cx
	sub	si,ax
	mov	cx,ax
	rep	movsb
	mov	byte ptr [di],0
	inc	ax
	shr	ax,1
	jc	right10
	or	ah,80h		;if odd bytes
right10:
	or	ah,stringmaskhigh
	mov	[bx],ax	
right100:
	cmp	byte ptr [bp],')'
	jne	rightsynerr
	inc	bp
	ret

;
;* mid
;

;* get parameter for mid() part1
; out : ax=new members,dx=start member

midparam1:
	call	formul
	mov	si,[calcsp]
	mov	al,[si+1]
	and	al,attribmaskhigh
	cmp	al,stringmaskhigh
	je	midparamin
	cmp	al,packmaskhigh
	je	midparamin
	jmp	ilgerr
midparamin:
	cmp	byte ptr [bp],0c2h	;code of ,
	jne	midsynerr
	inc	bp
	call	get_ax
	jc	midilgerr
	or	ax,ax
	jz	midilgerr
	push	ax		;start
	mov	ax,1
	cmp	byte ptr [bp],')'
	je	mid5			;if 3rd not assigned then 1
	cmp	byte ptr [bp],0c2h	;code of ,
	jne	midsynerr
	inc	bp
	cmp	byte ptr [bp],0e5h	;code of *
	jne	mid2
	inc	bp
	mov	ax,unitbyte
	jmps	mid5	
mid2:
	call	get_ax
	jc	midilgerr
mid5:
	pop	dx
	ret

midsynerr:
	jmp	synerr
midilgerr:
	jmp	ilgerr

;* get parameter for mid() part2
; out : cx=new bytes,si=source start adr,bx=[calcsp]

midparam2:
	mov	si,[calcsp]
	mov	cx,[si]
	mov	bx,cx
	and	bh,attribmaskhigh
	cmp	bh,stringmaskhigh
	jne	midilgerr	
	mov	bx,si
	shl	cx,1
	sbb	cx,0
	and	cx,2*lenmask+1

	;now cx=old bytes,dx=start,ax=new bytes,si=[calcsp]

	cmp	dx,cx
	ja	midsetnull	;null string
	add	si,2
	mov	di,si		;destination
	dec	dx
	add	si,dx		;start adr
	sub	cx,dx

	cmp	ax,cx
	jg	mid10
	mov	cx,ax
mid10:
	cmp	byte ptr [bp],')'
	jne	midsynerr
	inc	bp
	ret
midsetnull:
	xor	cx,cx
	jmp	mid10

;
; * mid
;
mid:
	call	midparam1
	mov	si,[calcsp]
	test	byte ptr [si+1],packmaskhigh
	jnz	midpack		;for packed data
	call	midparam2
	mov	ax,cx
	rep	movsb
	mov	byte ptr [di],0
	inc	ax
	shr	ax,1
	jc	mid20
	or	ah,80h		;if odd bytes
mid20:
	or	ah,stringmaskhigh
	mov	[bx],ax	
	ret

midpackilg:
	jmp	ilgerr
midsynerr2:
	jmp	synerr

midpack:			;now ax=new members,dx=start member
	dec	dx
	cmp	byte ptr [bp],')'
	jne	midsynerr2
	inc	bp
	mov	cx,ax
	mov	si,[calcsp]
	mov	bx,si		;memo
	lodsw
	lodsw			;ax=old members	
	sub	ax,dx		;ax=available members
	jb	midpackilg
	cmp	ax,cx
	jbe	midpack20
	mov	ax,cx	
midpack20:
	mov	cx,ax		;ax=cx=exact new members
	mov	[bx+2],ax

	or	dx,dx		;skip left members
	jz	midpack40
midpack30:
	lodsw
	and	ax,lenmask
	add	ax,ax
	add	si,ax
	dec	dx
	jnz	midpack30
midpack40:
	lea	di,[bx+4]
	jcxz	midpack60		;no member
	mov	dx,cx
midpack50:
	copy_si2di
	dec	dx
	jnz	midpack50
midpack60:
	mov	ax,di
	sub	ax,bx
	sub	ax,2
	shr	ax,1
	or	ah,packmaskhigh
	mov	[bx],ax
	ret
	
;
;* left
;

leftpack:
	mov	dx,1
	jmp	midpack

leftsynerr:
	jmp	synerr
leftilgerr:
	jmp	ilgerr

left:
	call	formul
	mov	ax,1
	cmp	byte ptr [bp],')'
	je	left5		;# of chars is not assigned
	cmp	byte ptr [bp],0c2h	;code of ,
	jne	leftsynerr
	inc	bp
	call	get_ax
	jc	leftilgerr
left5:
	mov	si,[calcsp]
	mov	cx,[si]
	mov	dh,ch
	and	dh,attribmaskhigh
	cmp	dh,packmaskhigh
	je	leftpack
	cmp	dh,stringmaskhigh
	jne	leftilgerr	
	shl	cx,1
	sbb	cx,0
	and	cx,2*lenmask+1
	cmp	ax,cx
	jg	left100
	lea	di,[si+2]
	add	di,ax
	mov	byte ptr [di],0
	inc	ax
	shr	ax,1
	jc	left10
	or	ah,80h		;if odd bytes
left10:
	or	ah,stringmaskhigh
	mov	[si],ax	
left100:
	cmp	byte ptr [bp],')'
	jne	leftsynerr
	inc	bp
	ret

;
;* ASC()
;
ascilg:
	jmp	ilgerr

ascin:
	call	kakko
	mov	si,[calcsp]
	mov	ax,[si]
	mov	cx,ax
	and	ch,attribmaskhigh
	cmp	ch,stringmaskhigh
	jne	ascilg	
	and	ax,lenmask
;	jz	asc10		;if null string
;	xor	ax,ax
;	cmp	[si+2],al
;	jz	asc10		;if 0
;	mov	[si+3],al	;0
;	mov	ax,1
;asc10:
	mov	[si],ax
	ret

;
;* CHR$()
;
chr$ilgerr:
	jmp	ilgerr

chr$in:
	call	kakko
	mov	si,[calcsp]
	mov	ax,[si]
	test	ah,attribmaskhigh
	jnz	chr$ilgerr	;if not integer
	and	ax,lenmask
	jnz	chr$10
	mov	[si+2],ax
	inc	ax
chr$10:
	mov	bx,si
	add	bx,ax
	add	bx,ax		;highest word adr
	cmp	byte ptr [bx+1],0
	jne	chr$20
	or	ah,80h		;odd length
chr$20:
	or	ah,stringmaskhigh
	mov	[si],ax
	ret

;
;* SPC()
;
spcin:
	call	kakko_ax
	jc	spcilgerr
	mov	di,[calcsp]
	cmp	ax,limitword*2
	ja	spcilgerr	;big/non integer/negative
	mov	cx,ax
	inc	ax
	shr	ax,1	
	jc	spc10
	or	ah,80h		;if odd length
spc10:
	or	ah,stringmaskhigh
	stosw
	mov	al,' '
	rep	stosb
	ret

spcilgerr:
	jmp	ilgerr
	
;
;* COMBINATION
;   (N, R)

combILG:
	JMP	ILGERR
combover:
	jmp	ovrerr

COMBIN:
	CALL	GET2ARGS
COMB_ENT:
	BACKSP_MAC
	MOV	AX,[DI]
	CMP	AX,1
	JB	comb10
	JA	combILG		;> 1 word is ilg(also other types)
	MOV	AX,[DI+2]
comb10:
	MOV	BX,[SI]
	CMP	BX,1
	JB	combset1	;ans=1 if R=0
	JNE	combILG
	MOV	BX,[SI+2]
comb20:
	;now AX=N,BX=R

	mov	cx,ax
	sub	cx,bx
	jb	combilg
	jz	combset1		;ans=1 if N=R
	cmp	cx,bx
	jb	comb30
	mov	cx,bx
comb30:
	;now CX=min(R,N-R)

	cmp	cx,maxfactorial
	ja	combover		;too big

	mov	di,ax
	sub	di,cx
	inc	di

	mov	bx,[calcsp]
	mov	word ptr [bx],1
	mov	[bx+2],di
	dec	cx
	jz	combret		;ans=N if R=1,N-1
	inc	di

	push	cx

	call	fact10
	mov	ax,[bx]
	cmp	ax,limitword
	ja	combover

	pop	cx

	mov	bx,[calcsp]
	sub	bx,unitbyte
	mov	[calcsp],bx

	mov	dx,1
	mov	[bx],dx
	mov	[bx+2],dx

	mov	di,2
	call	fact10

	call	idivin
combret:
	ret

combset1:
	mov	bx,[calcsp]
	mov	ax,1
	mov	[bx],ax
	mov	[bx+2],ax
	ret

		
;
; * epsilon
;
EPSILON:
	call	ahedsp
	mov	ax,[pointword]
	mov	cx,ax
	or	ah,pointmaskhigh
	inc	ax
	mov	[si],ax
	dec	cx
	add	cx,cx
	neg	cx
;	cmp	cx,floatbiasunder
;	jge	eps10
;	mov	cx,floatbiasunder
;eps10:
	mov	[si+2],cx		;set bias
	and	ax,lenmask
	lea	di,[si+4]
	dec	ax
	mov	cx,ax
	xor	ax,ax
	rep	stosw
	mov	byte ptr [di-1],1
	ret


;
; * IMAGINARY PART
;
imagprtilgerr:
	jmp	ilgerr

IMAGPART:
	CALL	KAKKO
	mov	si,[calcsp]
	mov	di,si
	lodsw
	test	ah,nonnumericmaskhigh
	jnz	imagprtilgerr
	test	ah,complexmaskhigh
	jz	imagset0	;if real
	lodsw
	and	ax,lenmask
	add	ax,ax
	add	si,ax
	copy_si2di
	ret

imagset0:
	mov	word ptr [di],0
	ret

;
; * REAL PART
;
realprtilgerr:
	jmp	ilgerr

REALPART:
	CALL	KAKKO
	mov	si,[calcsp]
	mov	di,si
	lodsw
	test	ah,nonnumericmaskhigh
	jnz	realprtilgerr
	test	ah,complexmaskhigh
	jz	realpart100	;if real
	copy_si2di
realpart100:
	ret

;
; * COMPLEX CONJUGATION
;
conjilgerr:
	jmp	ilgerr

CONJUGATE:
	CALL	KAKKO
	mov	si,[calcsp]
	lodsw
	test	ah,nonnumericmaskhigh
	jnz	conjilgerr
	test	ah,complexmaskhigh
	jz	conjugate100	;if real
	lodsw			;attribute of real part
	and	ax,lenmask
	add	ax,ax
	add	si,ax
	xor	byte ptr [si+1],signmaskhigh	;change sign
conjugate100:
	ret


;
; * random number
;
;   a = 16807      =     41a7h
;   m = 2147483647 = 7fffffffh
;   seed = seed * a @ m

_random_a	equ	    41a7h
_random_m	equ	7fffffffh
_random_mH	equ	    7fffh
_random_mL	equ	   0ffffh

;
; * initilaize random number
;

randomdefault:
	mov	ah,2ch
	int	21h		;get time
	mov	al,ch
	shr	al,1		;hour/2
	mov	ah,60
	mul	ah
	xor	ch,ch
	add	ax,cx
	mov	cx,60
	push	dx
	mul	cx
	pop	dx
	add	al,dh
	adc	ah,0
	or	ax,ax
	jnz	randomize50
	inc	ax
	jmps	randomize50
		
RANDOMIZE:
	MOV	AL,[BP]
	CMP	AL,CR
	JE	randomdefault	;ƒRƒ}ƒ“ƒh‚Ì‚Ý
	CMP	AL,0C0H		;':'
	JE	randomdefault	;ƒRƒ}ƒ“ƒh‚Ì‚Ý

	call	get_ax
	jc	RNDILGILG
randomize50:
	call	randomize_main
	JMP	MAINLP

RNDILGILG:
	JMP	ILGERR

randomize_main:
	mov	word ptr [randomnow],ax
	mov	word ptr [randomnow+2],0
	jmp	randomsub	;call & ret


;
; * fractional random number (0.0-0.999...)
;

RANDOM:
	call	randomsub
	call	realrandomsub
	push	dx
	push	ax
	call	ahedsp
	mov	di,si
	mov	ax,[pointword]
	mov	cx,ax
	inc	ax			;for exp
	or	ax,pointmask
	stosw
	winc	di
	sub	cx,2
	xor	ax,ax
	rep	stosw
	pop	ax
	pop	dx

	xor	cx,cx			;calc exp
random50:
	mov	bx,dx
	or	bx,ax
	jz	randomset0
	or	dh,dh
	jnz	random60
	dec	cx
	mov	dh,dl
	mov	dl,ah
	mov	ah,al
	xor	al,al
	jmp	random50
random60:
	stosw
	mov	[di],dx
	mov	[si+2],cx		;set exp
	ret
randomset0:
	mov	word ptr [si],0
	ret


;
; * integer random number (0-32767)
;

IRANDOM:
	call	randomsub
	call	ahedsp
	mov	cx,1
	mov	ax,word ptr [randomnow]
	and	ax,7fffh
	mov	[si+2],ax
	jnz	irandom100
	xor	cx,cx
irandom100:
	mov	[si],cx
	ret


RANDOMSUB:
  if FLG32
	set32
	mov	ax,word ptr [randomnow]
	set32
	mov	cx,_random_a
	dw	0
	set32
	mul	cx
	set32
	mov	cx,_random_mL
	dw	_random_mH
	set32
	div	cx
	set32
	mov	word ptr [randomnow],dx
	ret

  else

  	mov	ax,word ptr [randomnow]
	mov	cx,_random_a
	mul	cx
	mov	di,ax
	mov	si,dx
	mov	ax,word ptr [randomnow+2]
	mul	cx
	add	si,ax
	adc	dx,0		;dx:si:di = random_a * oldvalue
	mov	ax,si
	and	si,7fffh
	add	ax,ax
	mov	ax,dx
	rcl	ax,1		;ax= dx:si:di\2^31

	add	di,ax
	adc	si,0

	mov	word ptr [randomnow],di
	mov	word ptr [randomnow+2],si

	sub	di,_random_mL
	sbb	si,_random_mH
	jb	randomsubret

	mov	word ptr [randomnow],di
	mov	word ptr [randomnow+2],si
randomsubret:
	ret

  endif


realRANDOMSUB:
	mov	dx,word ptr [randomnow+2]
	mov	ax,word ptr [randomnow]
	add	ax,ax
	rcl	dx,1
	cmp	dx,_random_mH
	jb	realrndsubret
	ja	realrndsubincret
	cmp	ax,_random_mL
	jb	realrndsubret
realrndsubincret:
	add	ax,1
	adc	dx,0
realrndsubret:
	ret


;
;™ ŠKæ
;
FACTORIAL:
	CALL	KAKKO
factorial_ent:
	MOV	BX,[CALCSP]
	MOV	AX,[BX]
	MOV	CX,[BX+2]

	;INITIAL VALUE

	MOV	word ptr [BX],1
	MOV	word ptr [BX+2],1

	CMP	AX,1
	JA	FACTILG		;> 1 word is ilg(also other types)
	jb	FACTRET		;0!=1
	CMP	CX,maxfactorial
	JA	FACTILG
	DEC	CX
	JZ	FACTRET		;1!=1

	MOV	DI,2		;æ”
FACT10:				;also called from COMB
	PUSH	CX
	MOV	SI,BX
	MOV	CX,[SI]
	WINC	SI
	MOV	AX,[SI]
	MUL	DI
	MOV	[SI],AX
	WINC	SI
	MOV	AX,[SI]
	MOV	[SI],DX
	DEC	CX
	JZ	FACT30
FACT20:
	MUL	DI
	ADD	[SI],AX
	ADC	DX,0
	WINC	SI
	MOV	AX,[SI]
	MOV	[SI],DX
	myloop	FACT20
FACT30:
	OR	DX,DX
	JZ	FACT40
	INC	WORD PTR [BX]
FACT40:
	INC	DI
	POP	CX
	myloop	FACT10

FACTRET:
	RET

FACTILG:
	JMP	ILGERR


;
;** input$
;

input$file:
	inc	bp		;skip '#'
	call	get_ax
	jc	input$ilg
	push	ax
	cmp	byte ptr [bp],0c2h	;code of ','
	jne	input$ilg
	inc	bp
	call	kakko_ax
	pop	bx
	cmp	ax,limitword*2
	ja	input$ilg
	jmp	fgetbytes	;bx = file number, ax = bytes
				;call&ret

input$ilg:
	jmp	ilgerr

input$:
	mov	al,[bp]
	cmp	al,CR
	je	input$10
	cmp	al,0C0H		;':'
	je	input$10	;allow input$( only for compatibility
	cmp	byte ptr [bp],'#'
	je	input$file

input$kb:
	call	kakko_ax_signed
	jc	input$ilg
	cmp	ax,limitword*2
	jg	input$ilg
	or	ax,ax
	jz	input$clearkeybuffer
	jg	input$20	;cursor display
	and	ah,signmaskhighcpl
	jmps	input$30	;cursor disappear

input$clearkeybuffer:
  	mov	ax,0c00h
	int	21h
  	mov	ax,stringmask
	mov	di,[calcsp]
	stosw			;return null string
	ret

input$10:
	call	ahedsp
	mov	ax,1
input$20:
	push	ax
	call	cursor
	CALL	CURSON
	pop	ax
input$30:
	mov	cx,ax		;bytes to be gotten
	mov	di,[calcsp]
	inc	ax
	shr	ax,1
	jc	input$40
	or	ah,signmaskhigh
input$40:
	or	ah,stringmaskhigh
	stosw
	mov	dx,ax
input$lp:
  if FLGIBMTOS
	mov	ah,0		;the reason why we use BIOS call
				;because we cannot get cursor keys by 
				;DOS call.
	int	16h
	or	al,al
	jnz	input$jp
	mov	al,ah
input$jp:
  else
  			;mov	ah,0ch
	mov	ah,7	;mov	al,7
	int	21h
  endif
	stosb
	myloop	input$lp
	or	dx,dx
	jns	input$out
	mov	byte ptr [di],0	;fill undefined byte

input$out:
  if FLG98
	CALL	CURSOFF
  endif
	ret


;
;* real time keyinput
;

inkey:
	call	ahedsp
  if FLGIBMTOS
	mov	ah,1
	int	16h
	jnz	inkey_get
  endif
  if FLGFMR
  	MOV	AH,6		;DIRECT CONSOLE INPUT
	MOV	DL,0FFH
	INT	21H		;if ZF then no key input
	jnz	inkey_get
  endif
  if FLG98
  	MOV	AH,6		;DIRECT CONSOLE INPUT
	MOV	DL,0FFH
	INT	21H		;if ZF then no key input
	jnz	inkey_get

inkeyno:
  endif

;    if FLGFMR
;	MOV	AH,6		;DIRECT CONSOLE INPUT
;	MOV	DL,0FFH
;	INT	21H		;if ZF then no key input
;	jnz	inkey_get
;    endif
	mov	word ptr [si],stringmask
	ret

inkey_get:
  if FLGIBMTOS
	mov	ah,0
	int	16h
	or	al,al
	jnz	inkeyjp
	mov	al,ah
inkeyjp:
  endif
    	xor	ah,ah
	mov	[si+2],ax
	mov	word ptr [si],stringmask1char
	ret

;
;™ ‚`‚m‚c
;
ANDIN:
	mov	si,[bp]
	or	si,si
	jnz	and10
	call	src_andorend
	mov	[compilejp_sw],-1
	mov	[bp],si
and10:
	winc	bp
	push	si		;™ jmp adr
ANDLP:
	CALL	FORMUL
	MOV	SI,[CALCSP]
	CMP	WORD PTR [SI],0
	JE	AND_NO
	MOV	AL,[BP]
	CMP	AL,'}'
	JE	AND_YES
	CMP	AL,0C2H		;,
	JNE	AND_ERR
	INC	BP
	ADD	SI,UNITBYTE
	MOV	[CALCSP],SI
	CMP	BYTE PTR [BP],CR
	JNE	ANDLP

	CMP	WORD PTR [BP+1],0
	JE	AND_ERR			;END OF TEXT
	ADD	BP,1+5
	CMP	BYTE PTR [BP],0C0H	;':'
	Jne	AND_err
	inc	bp
	jmp	andlp

AND_ERR:
	JMP	SYNERR

AND_YES:
	MOV	WORD PTR [SI],1
	MOV	WORD PTR [SI+2],1
	pop	bp			;™
	RET

AND_NO:
	MOV	WORD PTR [SI],0
	pop	bp			;™
	RET


src_andorend:
	MOV	DX,0E7E8H	;80+DL=or{,80+DH=and{
SRCAOENDIN:
	MOV	SI,BP		;change pointer
	MOV	CH,1		;CH=counter
AOENDLP:	
	LODSB
	CMP	AL,CR
	JE	AOENDPAS5B	;s‚ÌI‚í‚è‚È‚Ì‚Ås”Ô†‚ÆŽŸæ“ª‚ðƒpƒX
	CMP	AL,80H
	JE	AOENDPUSH?
	CMP	AL,'}'
	JE	AOENDPOP
	CALL	PASSTOKEN
	JMP	AOENDLP

AOENDPUSH?:
	LODSB
	CMP	AL,DL		;AND or OR
	JE	AOENDPUSHIN
	CMP	AL,DH
	JNE	AOENDLP
AOENDPUSHIN:
	INC	CH
	JMP	AOENDLP

AOENDPOP:	
	DEC	CH
	JNZ	AOENDLP
	RET

AOENDPAS5B:			;æ“ª 5BYTES ‚ðƒpƒX	
	LODSW
	ADD	SI,3
	OR	AX,AX
	JZ	AOENDERR
	LODSB
	CMP	AL,0C0H		;':'
	JE	AOENDLP
AOENDERR:
	jmp	synerr		;no correspoding }


;
;™ ‚n‚q
;

ORIN:
	mov	si,[bp]
	or	si,si
	jnz	or10
	call	src_andorend
	mov	[compilejp_sw],-1
	mov	[bp],si
or10:
	winc	bp
	push	si		;™ jmp adr
ORLP:
	CALL	FORMUL
	MOV	SI,[CALCSP]
	CMP	WORD PTR [SI],0
	JNE	OR_YES
	MOV	AL,[BP]
	CMP	AL,'}'
	JE	OR_NO
	CMP	AL,0C2H		;,
	JNE	AND_ERR
	INC	BP
	ADD	SI,UNITBYTE
	MOV	[CALCSP],SI
	CMP	BYTE PTR [BP],CR
	JNE	ORLP

	CMP	WORD PTR [BP+1],0
	JE	OR_ERR			;END OF TEXT
	ADD	BP,1+5
	CMP	BYTE PTR [BP],0C0H	;':'
	JnE	OR_err
	inc	bp
	jmp	orlp

OR_ERR:
	JMP	SYNERR

OR_NO:
	MOV	WORD PTR [SI],0
	pop	bp		;™
	RET

OR_YES:
	MOV	WORD PTR [SI],1
	MOV	WORD PTR [SI+2],1
	pop	bp		;™
	RET


;
; * shift left [DI] by 1 bit
; [DI] must be integer

ISHIFTLEFT:
	MOV	CX,[DI]
	JCXZ	ISFTLRET
	MOV	AX,CX
	MOV	SI,DI
	CLC
ISFTL10:
	WINC	DI
	RCL	WORD PTR [DI],1
	myloop	ISFTL10
ISFTL20:
	JNC	ISFTLRET
	INC	AX
	CMP	AX,LIMITWORD
	JA	ISFTLOVR
	MOV	[SI],AX
	MOV	word ptr [DI+2],1
ISFTLRET:
	RET

ISFTLOVR:
	JMP	OVRERR

;
; * shift left [DI] by 1 bit
;

SHIFTLEFT_di:
	MOV	CX,[DI]
	JCXZ	sftlRET
	MOV	AX,CX
	and	cx,lenmask
	MOV	SI,DI
	CLC
sftl10:
	WINC	DI
	RCL	WORD PTR [DI],1
	myloop	sftl10
sftl20:
	JNC	sftlRET
	INC	AX
	mov	cx,ax
	and	cx,lenmask
	CMP	cx,LIMITWORD
	JA	sftlOVR
	MOV	[SI],AX
	MOV	word ptr [DI+2],1
sftlRET:
	RET

sftlOVR:
	JMP	OVRERR

;
; * shift right [DI] by 1 bit
; [DI] must be integer

ISHIFTRIGHT_di:
	MOV	CX,[DI]
	JCXZ	ISFTRRET
	MOV	bx,CX
	MOV	SI,DI
	ADD	DI,CX
	ADD	DI,CX		;highest adr
	CLC
	mov	ax,[di]
	rcr	ax,1
	mov	[di],ax
	dec	cx
	jz	isftr20
ISFTR10:
	wdec	di
	RCR	WORD PTR [DI],1
	myloop	ISFTR10
ISFTR20:
	or	ax,ax
	JNZ	ISFTRRET
	dec	bx
	mov	[si],bx
ISFTRRET:
	RET

;
; * shift right [DI] by 1 bit
;   if odd integer then make to fraction

SHIFTRIGHT_di:
	MOV	CX,[DI]
	JCXZ	SFTR50
	MOV	AX,CX		;memo
	AND	CX,LENMASK
	ADD	DI,CX
	ADD	DI,CX		;highest adr
	MOV	SI,DI
	test	ah,pointmaskhigh
	jz	sftr100		;if integer
	CLC
SFTR10:
	RCR	WORD PTR [DI],1
	wdec	di
	myloop	SFTR10

	cmp	word ptr [si],0
	jne	sftr50		;same len

	mov	cx,ax		;original attribute
	and	ax,lenmask
	dec	ax
	jz	sftr30		;if 0
	and	ch,lenmaskhighcpl	;complement of lenmaskhigh
	or	ah,ch		;set attribute
sftr30:
	mov	[di],ax
sftr50:
	RET


sftr100:
	CLC
SFTR110:
	RCR	WORD PTR [DI],1
	wdec	di
	myloop	SFTR110
	pushf			;reserve CF

	cmp	word ptr [si],0
	jne	sftr140		;same len

	mov	cx,ax		;original attribute
	and	ax,lenmask
	dec	ax
	jz	sftr130		;if 0
	and	ch,lenmaskhighcpl	;complement of lenmaskhigh
	or	ah,ch		;set attribute
sftr130:
	mov	[di],ax
sftr140:
	popf
	jc	sftroddinteger
	RET

sftroddinteger:
	and	ax,lenmask
	push	ax		;* words of integer part
	add	ax,[pointword]
	cmp	ax,limitword
	ja	sftrover
	or	ah,ch		;set attribute
	or	ah,pointmaskhigh
	mov	[di],ax
	pop	cx		;*
	add	di,cx
	add	di,cx
	mov	si,di
	mov	ax,[pointword]
	add	di,ax
	add	di,ax

	std
	rep	movsw
	mov	ax,8000h
	stosw			;set 0.5
	mov	cx,[pointword]
	dec	cx
	xor	ax,ax
	rep	stosw		;clear [pointword] words
	cld
	ret

sftrover:
	jmp	ovrerr


;
;	GET DIR
;
getDIR:
	jmp	far ptr farGetDIR

;
;	SET DATE
;
getdate:
	jmp	far ptr farGetdate

;
;	GET TIME
;

gettime:
	jmp	far ptr farGettime

;
; * get modulus of polynomial
;
getpolymod:
	call	ahedsp
	xor	cx,cx
	set32
	mov	ax,word ptr [polymodulus]
	set32
	or	ax,ax
	jz	getpolymod100
	inc	cx
	mov	[si+2],ax
	set32
	shr	ax,16
	or	ax,ax
	jz	getpolymod100
	inc	cx
	mov	[si+4],ax
getpolymod100:
	mov	[si],cx
	ret

;
;* make packed data
;
packovererr:
	jmp	ovrerr

packin:
	push	[packeddata]
	push	[packedlength]
	push	[packedptr]

	call	ahedsp
	mov	[packeddata],0
	mov	[packedlength],1
	add	si,4
	mov	[packedptr],si
	cmp	byte ptr [bp],')'
	je	pack100
pack10:
	call	formul
	mov	ax,[calcsp]
	mov	si,ax
	add	ax,unitbyte
	mov	[calcsp],ax
	mov	ax,[si]
	and	ax,lenmask
	inc	ax
	mov	cx,ax
	add	ax,[packedlength]
	cmp	ax,limitword
	ja	packovererr
	mov	[packedlength],ax
	inc	[packeddata]
	mov	di,[packedptr]
	rep	movsw
	mov	[packedptr],di
	mov	al,[bp]
	cmp	al,')'
	je	pack100
	cmp	al,0c2h		;,
	jne	packsynerr
	inc	bp
	jmp	pack10
pack100:
	inc	bp
	mov	di,[calcsp]
	mov	ax,[packedlength]
	or	ah,packmaskhigh
	stosw
	mov	ax,[packeddata]
	stosw

	pop	[packedptr]
	pop	[packedlength]
	pop	[packeddata]
	ret

packsynerr:
	jmp	synerr


comment %
funcdivax:
	;[di] /= ax
	; does not slide i.e. fixed point computation
	; attrib and exp may be changed(higher byte may be 0)
	; so that the LSW is on the same level as before
	; reserve di

	mov	bx,ax			;divisor
	mov	cx,[di]
	mov	si,di
	and	cx,lenmask
	add	si,cx
	add	si,cx			;adr of MSW
	xor	dx,dx			;carry
	mov	ax,[si]
	div	bx
	mov	[si],ax
	wdec	si
	or	ax,ax
	jnz	funcdivax10
	mov	ax,[di]
	dec	ax
	mov	[di],ax			;dec length
	sub	word ptr [di+2],2	;exp -= 2
	and	ax,lenmask
	jz	funcdivaxset0
funcdivax10:
	sub	cx,2
	jz	funcdivaxret
funcdivaxlp:
	mov	ax,[si]
	div	bx
	mov	[si],ax
	wdec	si
	myloop	funcdivaxlp
funcdivaxret:
	ret
funcdivaxset0:
	mov	[di],ax			;now ax = 0
	ret


;
; add non standard floating numbers
;  for power series
;  assume
;    [di] >= [si]
;    LSWs are on the same level
;    non carry
;    both positive

funcadd:
	mov	cx,[si]
	and	cx,lenmask
	dec	cx
	add	si,4
	add	di,4
	clc
funcaddlp:
	mov	ax,[si]
	winc	si
	adc	[di],ax
	winc	di
	loop	funcaddlp
	jnc	funcaddret
funcaddlp2:
	adc	[di],cx		;cx = 0
	winc	di
	jc	funcaddlp2
funcaddret:
	ret


;
; sub non standard floating numbers
;  for power series
;  assume
;    [di] >= [si]
;    LSWs are on the same level
;    non changing exp
;    both positive

funcsub:
	mov	cx,[si]
	and	cx,lenmask
	dec	cx
	add	si,4
	add	di,4
	clc
funcsublp:
	mov	ax,[si]
	winc	si
	sbb	[di],ax
	winc	di
	loop	funcsublp
	jnc	funcsubret
funcsublp2:
	sbb	[di],cx		;cx = 0
	winc	di
	jc	funcsublp2
funcsubret:
	ret

;
; multiplication of non staandard floating numbers
; [di] *= [si]
; allow higher byte 0
;   assume 
;	both possitive
;	[si] < 1

funcmul:
	mov	cx,[di]
	mov	bx,[si]
;	mov	al,ch
;	mov	ah,bh
;	and	ax,signmask
;	push	ax			;sign
	and	cx,lenmask
	and	bx,lenmask
	dec	cx
	dec	bx
	winc	si
	winc	di
	mov	ax,bx
	add	ax,ax
	sub	ax,[si]
	push	ax			;len(y)-exp(y)

	winc	di
	winc	si

	push	di
	call	far ptr farmulFFsub
	pop	di

	mov	si,mulwork
	pop	bx			;new exp
	add	bx,si
	call	funcgetfloat
	ret


funcgetfloat:
	; si = src base
	; bx = src start
	; di = dst base
	;  assume sign unchanged
	;  emp is already set in [di+2] and is not changed
	; result is non standard form, i.e. higher byte may be 0

	mov	cx,[si]		;get length
	add	cx,cx
	add	si,cx
	winc	si		;src MSW+2
	cmp	byte ptr [si-1],0
	jne	fgetF70
	dec	si
fgetF70:
	mov	ax,si
	sub	ax,bx		;byte length
	inc	ax
	shr	ax,1
	mov	cx,ax		;word length
	inc	ax
	or	ah,pointmaskhigh
	mov	[di],ax			;set attrib
	add	di,4
	mov	si,bx
	rep	movsw
	shr	si,1
	jnc	fgetFret
	mov	byte ptr [di-1],0
fgetFret:
	ret
%


CODE	ENDS

code2	segment	public
	assume	cs:code2,ds:data

	public	gettime100

	extrn	val_poly:far,val_modpoly:far
	extrn	farmulFFsub:far

;
;	GET DIR
;
farGetDIR:
	call	ahedsp2

	mov	ah,19h		;get current drive number
	int	21h
	add	al,'A'

	mov	bx,[calcsp]
	lea	di,[bx+2]
	stosb
	mov	al,":"
	mov	ah,"\"
	stosw
	mov	si,di

	mov	ah,47h		;get current directory
	xor	dx,dx
	int	21h

	lea	di,[bx+5]
	mov	cx,64
	xor	al,al
	repne	scasb
	sub	di,bx
	sub	di,2		;di=chars+1
	shr	di,1
	jc	getdir100	;if even length
	or	di,8000h
getdir100:
	or	di,stringmask
	mov	[bx],di
	
	jmp	far ptr returnadr

;
;	GET DATE
;
farGetdate:
  if FLGIBMTOS
	mov	ah,2		;get real time clock
	int	1ah
	mov	dl,cl
	mov	cl,4

	mov	al,ch
	mov	ah,al
	and	al,0fh
	shr	ah,cl
	aad
	mov	ch,al

	mov	al,dh
	mov	ah,al
	and	al,0fh
	shr	ah,cl
	aad
	mov	dh,al

	mov	al,dl
	mov	ah,al
	and	al,0fh
	shr	ah,cl
	aad
	mov	cl,al

	xor	dl,dl
	mov	ah,2dh		;set DOS clock
	int	21h
  endif
	call	ahedsp2
	mov	si,[calcsp]
	lea	di,[si+2]

	MOV	AH,2AH		;GET DATE
	INT	21H

	MOV	AL,' '
	STOSB
	MOV	AX,CX
	MOV	CL,100
	DIV	CL
	MOV	CL,AH
	MOV	AH,' '
	CALL	putdecial
	MOV	AH,'0'
	MOV	AL,CL
	CALL	putdecial
	MOV	AH,' '
	MOV	AL,'/'
	STOSB

	MOV	AL,DH
	CALL	putdecial
	MOV	AL,'/'
	STOSB

	MOV	AL,DL
	CALL	putdecial
	MOV	AL,'/'
	STOSB
	MOV	AL,' '
	STOSB

	mov	ah,2ch		;GET TIME
	int	21h

	mov	al,ch
	mov	ah,' '
	call	putdecial
	mov	al,':'
	STOSB
	mov	al,cl
	mov	ah,'0'
	call	putdecial
	MOV	AL,':'
	STOSB
	MOV	AL,DH
	MOV	AH,'0'
	CALL	putdecial

getdate90:
	xor	al,al
	stosb			;dummy for odd bytes

	mov	ax,di
	sub	ax,si
	sub	ax,2		;bytes+1
	shr	ax,1
	jc	getdate100
	or	ah,80h		;if odd bytes
getdate100:
	or	ah,stringmaskhigh
	mov	[si],ax
	jmp	far ptr returnadr

;
;	GET TIME
;

farGettime:
	call	gettimesub
	jmp	getdate90

gettimesub:
	call	ahedsp2
	mov	si,[calcsp]
	lea	di,[si+2]

	MOV	AH,2AH		;GET DATE
	INT	21H

	PUSH	AX
	mov	ah,2ch		;get TIME
	int	21h
	POP	AX

  if FLG98+FLGFMR
	mov	[secondmem],dh
  	SUB	DH,[SECOND]
  else
	sub	dl,[MSECOND]
	jnb	gettime5
	add	dl,100
gettime5:
	mov	byte ptr [MSECOND2],dl
	SBB	DH,[SECOND]
  endif
  	JNB	gettim10
	ADD	DH,60
gettim10:
	mov	[second2],dh	;for time100
	SBB	CL,[MINUTE]
	JNB	gettim20
	ADD	CL,60
gettim20:
	mov	[minute2],cl
	SBB	CH,[HOUR]
	JNB	gettim30
	ADD	CH,24
gettim30:
	mov	[hour2],ch
	SBB	AL,[DATE]
	JNB	gettim40
	ADD	AL,7
gettim40:
	MOV	BYTE PTR [DI],' '
	INC	DI
	MOV	AH,24
	MUL	AH
	ADD	AL,CH
	CMP	AL,100
	JB	gettim45
	MOV	BYTE PTR [DI],'1'
	INC	DI
	SUB	AL,100
	MOV	AH,'0'
	JMPS	gettim50
gettim45:
	MOV	AH,' '
gettim50:
	call	putdecial
	mov	al,':'
	STOSB
	mov	al,cl
	mov	ah,'0'
	call	putdecial
	MOV	AL,':'
	STOSB
	MOV	AL,DH
	MOV	AH,'0'
	jmp	putdecial	;call & ret

putdecial:
	push	ax
	push	bx
	mov	bh,ah	;memo it
	xor	ah,ah
	mov	bl,10
	div	bl
	add	al,'0'
	cmp	al,'0'
	jne	PUTD10
	mov	al,bh
PUTD10:
	STOSB
	mov	al,ah
	add	al,'0'
	STOSB
	pop	bx
	pop	ax
	ret

;
; * get time (1/1000sec)
;

  if FLGIBMTOS
time100sub:		;inp : ax
	xor	bx,bx
time100lp:
	inc	bx
	mov	cx,100h
time100lp2:
	push	cx
	pop	cx
	myloop	time100lp2
	cmp	ax,ds:[046ch]
	je	time100lp
	ret

gettime100:
	push	ds
	xor	ax,ax
	mov	ds,ax

	cli
	mov	si,ds:[046ch]	;[046ch] DW = tick count since midnight
	mov	di,ds:[046eh]
	sti
	mov	ax,si
	call	time100sub
	push	bx
	mov	ax,ds:[046ch]
	call	time100sub
	pop	cx

	mov	ax,bx
	sub	ax,cx
	jae	time100A
	xor	ax,ax
time100A:
	mov	dx,28125	;3600*1000/128
	mul	dx
	div	bx
	mov	bx,512		;65536/128
	xor	dx,dx
	div	bx
	mov	cx,ax

	;now  cx= time with unit=1/1000 sec

	pop	ds

	sub	si,word ptr [TICKCOUNTS]
	sbb	di,word ptr [TICKCOUNTS+2]
	jnb	time100B
	add	si,00b0h	;1800b0h = 24hours
	adc	di,0018h
time100B:
	mov	ax,si
	mov	bx,28125	;3600*1000/128
	mul	bx
	push	ax
	push	dx
	mov	ax,di
	mul	bx
	pop	di
	pop	si
	add	ax,di
	adc	dx,0

	mov	bx,512		;65536/128
	div	bx
	mov	di,ax
	mov	ax,si
	div	bx
	mov	dx,di

	add	ax,cx
	adc	dx,0

	call	ahedsp2
	mov	di,[calcsp]
	mov	cx,2
	or	dx,dx
	jnz	gettimeret
	dec	cx
	or	ax,ax
	jnz	gettimeret
	dec	cx
gettimeret:
	mov	[di],cx
	mov	[di+2],ax
	mov	[di+4],dx
	jmp	far ptr returnadr
endif


  if FLG98+FLGFMR
time100sub:
	xor	bx,bx
time100lp:
	inc	bx
	mov	cx,10h
time100lp2:
	push	cx
	mov	ah,2ch		;get TIME
	int	21h
	pop	cx
	myloop	time100lp2
	cmp	dh,[secondmem]
	je	time100lp
	ret

gettime100:
	call	gettimesub
	call	time100sub
	push	bx
	mov	[secondmem],dh
	call	time100sub
	pop	cx
	mov	ax,bx
	sub	ax,cx
	jae	time100A
	xor	ax,ax
time100A:
	mov	dx,1000
	mul	dx
	div	bx
	mov	[msecond2],ax
  endif

 if FLG98+FLGFMR
  	mov	al,[hour2]
	mov	bx,60
	mul	bl
	add	al,[minute2]
	adc	ah,0
	mul	bx
	add	al,[second2]
	adc	ah,0
	adc	dx,0
	push	dx
	mov	bx,1000
	mul	bx
	add	ax,[msecond2]
	adc	dx,0
	mov	si,ax
	mov	di,dx
	pop	ax
	mul	bx
	mov	dx,di
	add	dx,ax
	mov	ax,si

	mov	di,[calcsp]
	mov	cx,2
	or	dx,dx
	jnz	gettimeret
	dec	cx
	or	ax,ax
	jnz	gettimeret
	dec	cx
gettimeret:
	mov	[di],cx
	mov	[di+2],ax
	mov	[di+4],dx
	jmp	far ptr returnadr
  endif

code2	ends

