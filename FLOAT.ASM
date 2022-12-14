;float.asm

data	segment	word public
	assume	ds:data

	extrn	pointword:word,pointbyte:word,schoolflg:byte
	extrn	ascend:word

floatbias	dw	?
thisfloatword	dw	?
thisfloatbyte	dw	?
thispointdeci	dw	?

pointtmp	dw	?
biasmem		dw	?

data	ends


code	segment	public
	assume	cs:code,ds:data

	public	pointascin
	public	divIorFdisi,fardivIorFdisi
	public	intin,int_ent,farint_ent
	public	floorin,ceilin,roundin,fixin
	public	floor_ent,ceil_ent,round_ent,fix_ent

	public	store_float,justlengthFdi,normalizeFdi
	public	int2floatbxcurrent
	public	floatdivdiax,floatmuldiax
	public	farfloatdivdiax

	public	add_integer_float,add_float_integer,add_float_float
	public	mul_integer_float,mul_float_integer,mul_float_float
	public	div_integer_float,div_float_integer,div_float_float
	public	idiv_integer_float,idiv_float_integer,idiv_float_float
	public	addFFdisi,subFFdisi,mulFFdisi,divFFdisi,idivFFdisi
	public	compFFdisi
	public	faraddFFdisi,farsubFFdisi,farmulFFdisi

	public	add_float_rational,add_rational_float
	public	mul_float_rational,mul_rational_float
	public	div_float_rational,div_rational_float

	public	cmp_float_float
	public	cmp_integer_float,cmp_float_integer
	public	cmp_rational_float,cmp_float_rational

	public	divin,fardivin,divAAdisi,fardivAAdisi
	public	mulIorFdisi,inverseFdi

	public	real2floatbxjust,farreal2floatbxjust
	public	real2float0,farall2float0

	extrn	farbinasc:far,binascret:near
	extrn	prchr:near,prntbx:near,print_calcsp_out:near

	public	squareIFCdi,farsquareIFCdi
	extrn	squareIdi:near

	public	floatsetdiax,farfloatsetdiax
	public	squareFdi,farsquareFdi
	public	factorialFFdiax,farfactorialFFdiax
	public	powerFCdiax,farpowerFCdiax

	public	float2intbx,farfloat2intbx

	public	roundupF

	extrn	overloaddiv:near




sftupdiax:
	;in  ax: difference
	;    di: base adr

	;NOTE: non checking overflow!!
	;    higher address may be destroyed
	;    must check higher address

	mov	cx,[di]
	and	cx,lenmask
	jz	sftupdiaxret
	push	ax			;/*
	add	[di],ax
	add	di,cx
	add	di,cx
	mov	si,di
	add	di,ax
	add	di,ax
	add	ax,cx
;	cmp	ax,limitword
;	ja	sftupdiaxover
	std
	rep	movsw
	pop	cx			;*/
	xor	ax,ax
	rep	stosw
	cld
sftupdiaxret:
	ret
;sftupdiaxover:
;	jmp	ovrerr


divdibyax:
	;in  ax: divisor
	;out ax: length of result

	PUSH	DX
	PUSH	SI
	PUSH	DI
	PUSH	BP

	MOV	BP,ax
	MOV	CX,[DI]
	MOV	[ANSLEN],CX	;expected length of result
	XOR	DX,DX		;remainder
	ADD	DI,CX
	ADD	DI,CX
	MOV	SI,DI		;SI=DI=MSW
	STD
divditen10:
	MOV	AX,[DI]
	DIV	BP
	STOSW
	myloop	divditen10
	CLD
;	shr	bp,1
;	cmp	dx,bp
;	jb	divditen50
;
;	; roundup
;
;	stc
;divditen20:
;	winc	di
;	adc	word ptr [di],0
;	jc	divditen20

divditen50:
	mov	ax,[anslen]

	CMP	[SI],CX		;CX=0
	JNE	divditen100

	;decrement length since MSW = 0

	dec	ax
divditen100:
	POP	BP
	POP	DI
	POP	SI
	POP	DX

	mov	[di],ax		;set new length
	ret


justlengthFdi:
	;inp  di: base adr
	;make length to [pointword]

	mov	ax,[di]
	lea	bx,[di+4]
	and	ax,lenmask
	jz	jusstlenret
	dec	ax
	sub	ax,[pointword]
	jz	jusstlenret
	jb	jusstlenup
jusstlendown:
	sub	[di],ax		;rewrite attr
	mov	cx,[pointword]
	mov	di,bx
	mov	si,bx
	add	si,ax
	add	si,ax
	mov	ah,[si-1]	;lower byte
	rep	movsw
	add	ah,ah
	jnc	jusstlenret
	jmp	roundupF	;call & ret
jusstlenret:
	ret

jusstlenup:
	neg	ax
	mov	cx,[pointword]
	add	[di],ax		;rewrite attr
	inc	cx
	add	di,cx
	add	di,cx
	dec	cx
	mov	si,di
	sub	si,ax
	sub	si,ax
	sub	cx,ax
	std
	rep	movsw
	mov	cx,ax
	xor	ax,ax
	rep	stosw
	cld
	ret


normalizeFdi:
	;inp  di: base adr
	;cut higher 0

	mov	cx,[di]
	jcxz	normalret
	mov	si,di
	and	cx,lenmask
	add	cx,cx
	xor	al,al
	add	di,cx
	sub	cx,2
	inc	di			;MSB
	mov	dx,cx
	mov	bx,di
	std
	repe	scasb
	cld
	je	normalset0			;all 0
	inc	di
	inc	cx			;cx = number of non 0 bytes
	sub	dx,cx			;dx = number of higher 0 bytes
	sub	[si+2],dx		;rewrite bias
	mov	si,di			;src MSB
	mov	di,bx			;dst MSB
	std
	rep	movsb
	mov	cx,dx
	xor	al,al
	rep	stosb
	cld
normalret:
	ret
normalset0:
	mov	word ptr [si],0
	ret


store_float:
	;convert integer part to float

	mov	bx,[calcsp]
	mov	cx,[bx]
	and	cx,lenmask
	push	cx		;/*

	call	int2floatbxcurrent

	;get fractional part

	inc	bp
	mov	al,[bp]
	call	parnumsub	;get as an integer

	;copy to mulwork

	mov	ax,[calcsp]
	copyF	ax,mulwork
	add	ax,unitbyte
	mov	[calcsp],ax

	pop	dx		;*/
	cmp	dx,[pointword]
	jbe	strf10		;must calc frac part
	jmp	strf100

strf10:
	or	dx,dx
	jnz	strf30

	;slide up by currentword + pointword + 1

	mov	di,mulwork
	mov	ax,[di]
	and	ax,lenmask
	add	ax,[pointword]
	inc	ax
	push	ax		;/*
	call	sftupdiax

	;division by 10000 or 10

	mov	si,mulwork
	pop	dx		;*/
	mov	ax,[si]
	mov	di,si
	inc	dx
	add	si,dx
	add	si,dx		;adr of intpart
strf15:
	cmp	ax,dx
	je	strf20		;if intpart = 1 word
	mov	ax,10000
	call	divdibyax
	jmp	strf15
strf20:
	cmp	word ptr [si],1
	je	strf25		;if int part = 1
	mov	ax,10
	call	divdibyax
	jmp	strf20

strf25:
	;set fractional part

	lea	di,[si-1]		;fraction MSB
	mov	si,mulwork
	mov	cx,di
	sub	cx,si
	dec	cx
	xor	al,al
	mov	dx,cx
	std
	repe	scasb
	cld
	je	strfset0	;if 0.0
	sub	dx,cx
	dec	dx		;dx = number of higher 0
	neg	dx
	lea	si,[di+1]	;si = non zero top
	mov	di,[calcsp]
	mov	ax,[pointword]
	sub	si,ax
	sub	si,ax
	mov	cx,ax
	inc	si
	inc	ax
	or	ax,pointmask
	stosw
	mov	[di],dx		;bias
	winc	di
	mov	ah,[si-1]	;used by roundup
	mov	bx,di		;
	rep	movsw
	jmp	strf90
strfset0:
	mov	word ptr [si],0
	jmp	strf100

strf30:
	mov	di,mulwork
	mov	ax,[pointword]
	inc	ax		;1 more word
	call	sftupdiax	;shift up for division

	mov	si,mulwork
	mov	ax,[si]
	mov	dx,[pointword]
	add	dx,2
	mov	di,si
	add	si,dx
	add	si,dx		;adr of intpart
strf40:
	cmp	ax,dx
	je	strf50		;if intpart = 1 word
	mov	ax,10000
	call	divdibyax
	jmp	strf40
strf50:
	cmp	word ptr [si],1
	je	strf60		;if int part = 1
	mov	ax,10
	call	divdibyax
	jmp	strf50

strf60:
	;copy fractional part

	mov	di,[calcsp]
	mov	ax,[di+2]	;bias
	add	di,4
	mov	cx,[pointword]
	add	cx,cx
	sub	cx,ax		;byte length of rest data
	sub	si,cx		;MSB of frac part
	mov	bx,di		;used by roundupF
	mov	ah,[si-1]	;
	rep	movsb
strf90:
	add	ah,ah
	jnc	strf100
	call	roundupF

	;done ?
strf100:
	mov	al,[bp]
	cmp	al,'e'
	je	strf120
strf105:
	mov	al,[bp]
	cmp	al,9eh		;code of complex
	je	strf110
	ret
strf110:
	jmp	store_complex

strf120:
	inc	bp
	mov	dx,1		;dx is sign
	mov	al,[bp]
	inc	bp
	cmp	al,ncode
	je	strf105		;bias = 0
	cmp	al,0deh		;code of -
	jne	strf125
	mov	dx,-1
	mov	al,[bp]
	inc	bp
strf125:
	cmp	al,ncode1
	jne	strfovererr
	mov	ax,[bp]
	winc	bp
	cmp	dx,1
	jne	strfminus

strfplus:
	mov	di,[calcsp]
	mov	cx,ax
	push	ax		;/*
	shr	cx,2
	jz	strf126a
strf126:
	push	cx
	mov	ax,10000
	call	floatmuldiax
	pop	cx
	myloop	strf126
strf126a:
	pop	cx		;*/
	and	cx,3
	jz	strf126c
	mov	ax,10
	dec	cx
	jz	strf126b
	mov	ax,100
	dec	cx
	jz	strf126b
	mov	ax,1000
strf126b:
	call	floatmuldiax
strf126c:
	jmp	strf105

strfminus:
	mov	di,[calcsp]
	mov	cx,ax
	push	ax		;/*
	shr	cx,2
	jz	strf127a
strf127:
	push	cx
	mov	ax,10000
	call	floatdivdiax
	pop	cx
	myloop	strf127
strf127a:
	pop	cx		;*/
	and	cx,3
	jz	strf127c
	mov	ax,10
	dec	cx
	jz	strf127b
	mov	ax,100
	dec	cx
	jz	strf127b
	mov	ax,1000
strf127b:
	call	floatdivdiax
strf127c:
	jmp	strf105


strfovererr:
	jmp	ovrerr


farslide1:
	call	slide1
	retf

floatover:
	jmp	ovrerr

slide1:
	;slide down x_0,x_1,...,x_2F with offset 1
	;increment bias word
	;inp bx:base adr + 4
	;    bx is unchanged

	mov	cx,[bx-4]
	mov	ax,[bx-2]
	and	cx,lenmask
	inc	ax
	dec	cx
	cmp	ax,floatbiasover
	jge	floatover
	mov	di,bx
	mov	[bx-2],ax
	lea	si,[bx+1]
	mov	al,[bx]		;mem low byte
	rep	movsw
	add	al,al
	jc	roundupF	;cross reference
	ret

roundupF:
	;inp bx:base adr + 4
	;    bx is unchanged

	mov	cx,[bx-4]
	mov	si,bx
	and	cx,lenmask
	stc
	dec	cx
roundupF10:
	jnc	roundupF20
	adc	word ptr [si],0
	winc	si
	myloop	roundupF10
	jc	goslide1
roundupF20:
	ret
goslide1:
	mov	word ptr [si],1	;highest word
	jmp	slide1		;cross reference


floatmulby2:
	xor	ax,ax			;clc
fmulsubby2lp:
	rcl	word ptr [si],1
	winc	si
	myloop	fmulsubby2lp
	rcl	ax,1			;get overflow
	mov	[si],ax
	pop	di
	ret

farfloatmulaxsub:
	call	floatmulaxsub
	retf

floatmulaxsub:
	push	di
	mov	bx,ax			;multiplier
	mov	si,di
	mov	cx,[si]
	add	si,4
	and	cx,lenmask
	dec	cx
	mov	[thisfloatword],cx
	cmp	ax,2
	je	floatmulby2

  if FLG32
	shr	cx,1
	jc	fmulaxsub16		;ubnormal case(storef,...)
	set32
	shl	bx,16
	set32
	shr	bx,16
	set32
	xor	di,di			;carry
fmulaxsublp:
	set32
	mov	ax,[si]
	set32
	mul	bx
	set32
	add	ax,di
	set32
	adc	dx,0
	set32
	mov	[si],ax
	set32
	mov	di,dx
	qinc	si
	myloop	fmulaxsublp
	jmps	fmulaxsubout

fmulaxsub16:
	rcl	cx,1
endif

	xor	di,di			;carry
fmulaxsub16lp:
	mov	ax,[si]
	mul	bx
	add	ax,di
	adc	dx,0
	mov	[si],ax
	mov	di,dx
	winc	si
	myloop	fmulaxsub16lp

fmulaxsubout:
	mov	[si],di			;overflow
	mov	ax,di			;overflow
	pop	di
	ret


farfloatmuldiax:
	call	floatmuldiax
	retf

floatmuldiax:
	;[di] *= ax
	; reserve di
	; non assuming es=ds

	cmp	word ptr [di],0
	je	floatmulaxret

	call	floatmulaxsub
	or	ax,ax
	jz	floatmulaxret		;no overflow

	or	ah,ah
	jnz	floatmulaxjp3		;if 2bytes overflow
floatmulaxjp2:
	lea	si,[di+4]
	mov	ax,[si-2]
	inc	ax
	cmp	ax,floatbiasover
	jge	floatmulover
	mov	[si-2],ax		;set bias
	mov	cx,[thisfloatword]
	lodsb
	add	al,al			;check lower bit for round
floatmulaxlp2:				;add carry with slide copy
	lodsw
	adc	ax,0
	mov	[si-3],ax
	myloop	floatmulaxlp2
	jnc	floatmulaxret
	mov	byte ptr [si-1],1
	jmp	floatmulaxjp2

floatmulaxret:
	ret
floatmulover:
	jmp	ovrerr

floatmulaxjp3:				;2bytes overflow
	lea	si,[di+4]
	mov	ax,[si-2]
	add	ax,2
	cmp	ax,floatbiasover
	jge	floatmulover
	mov	[si-2],ax		;set bias
	mov	cx,[thisfloatword]
	lodsw
	add	ah,ah			;check lower bit for round
floatmulaxlp3:				;add carry with slide copy
	lodsw
	adc	ax,0
	mov	[si-4],ax
	myloop	floatmulaxlp3
					;must non carry
	jmp	floatmulaxret


floatdivdiaxcomplex:
	push	di
	add	di,2
	mov	si,di
	mov	dx,[di]
	and	dx,lenmask
	inc	dx
	add	si,dx
	add	si,dx
	push	ax
	push	si			;top of im part
	call	floatdivdiax
	cmp	word ptr [di],0
	je	floatdivdiaxcomplexre0
floatdivdiaxcomplexjp:
	pop	di
	pop	ax
	call	floatdivdiax
	cmp	word ptr [di],0
	je	floatdivdiaxcomplexim0
	pop	di
	mov	ax,[di+2]
	mov	si,di
	and	ax,lenmask
	add	si,ax
	add	si,ax
	mov	dx,[si+4]
	and	dx,lenmask
	add	ax,2
	add	ax,dx
	or	ah,complexmaskhigh
	mov	[di],ax
	ret

floatdivdiaxcomplexre0:			;if real part = 0
	pop	si
	add	di,2
	push	di
	copy_si2di
	jmp	floatdivdiaxcomplexjp

floatdivdiaxcomplexim0:			;if imag part = 0
	pop	di
	push	di
	lea	si,[di+2]
	copy_si2di
	pop	di
	ret


  if FLG32
floatdivby2:
	shr	cx,1
	sub	si,2
	xor	ax,ax			;clc
floatdivby2lp:
	set32
	rcr	word ptr [si],1
	qdec	si
	myloop	floatdivby2lp
	rcr	ax,1			;get carry
	jmps	floatdivdiaxjp

  else
floatdivby2:
	xor	ax,ax			;clc
floatdivby2lp:
	rcr	word ptr [si],1
	wdec	si
	myloop	floatdivby2lp
	rcr	ax,1			;get carry
	jmps	floatdivdiaxjp
  endif


farfloatdivdiax:
	call	floatdivdiax
	retf

floatdivdiaxilg:
	jmp	ilgerr

floatdivdiax:
	;[di] /= ax
	; [di] are float or complex
	; reserve di

	mov	si,di
	mov	bx,ax			;divisor
	mov	cx,[si]
	add	si,2
	mov	dx,cx
	and	cx,lenmask
	jz	floatdivaxret
	and	dh,attribmaskhigh
	cmp	dh,complexmaskhigh
	je	floatdivdiaxcomplex
	cmp	dh,pointmaskhigh
	jne	floatdivdiaxilg
	dec	cx
	mov	[thisfloatword],cx
	add	si,cx
	add	si,cx			;adr of MSW
	xor	dx,dx			;carry
	push	si
	cmp	ax,2
	je	floatdivby2

	shr	cx,1
	wdec	si
	set32
	xor	dx,dx
	set32
	shl	bx,16
	set32
	shr	bx,16
floatdivaxlp:
	set32
	mov	ax,[si]
	set32
	div	bx
	set32
	mov	[si],ax
	qdec	si
	myloop	floatdivaxlp
	set32
	xor	ax,ax
	set32
	div	bx
	set32
	ror	ax,16			;ax=next, higher=next to next

floatdivdiaxjp:
	pop	si
	mov	cx,[si]
	or	ch,ch
	jz	floatdivaxup		;if higher 0

	lea	si,[di+2]
	add	ah,ah			;check lower bit for round
floatdivaxlp1:
	jnc	floatdivaxret
	winc	si
	adc	word ptr [si],0
	jmp	floatdivaxlp1

floatdivaxup:
	or	cl,cl
	jz	floatdivaxup2		;2 bytes higher 0

	;1 byte higher 0 case

	mov	cx,[thisfloatword]
	mov	di,si
	dec	si
	std
	rep	movsw
	mov	[di+2],ah
	cld
	sub	di,2

	mov	cx,[di+2]		;set bias
	dec	cx
	jmp	floatdivaxupout

floatdivsetdi0:
	mov	word ptr [di],0
floatdivaxret:
	ret

floatdivaxup2:
	;2 bytes higher 0 case

	mov	cx,[thisfloatword]
	dec	cx
	mov	di,si
	sub	si,2
	std
	rep	movsw
	mov	[di],ax
	cld
	sub	di,4
	set32
	rol	ax,8			;al = next byte

	mov	cx,[di+2]		;set bias
	sub	cx,2
floatdivaxupout:
	cmp	cx,floatbiasunder
	jle	floatdivsetdi0
	mov	[di+2],cx

	add	al,al
	jnc	fixedcheck

	lea	bx,[di+4]
	push	di
	call	roundupF
	pop	di

fixedcheck:
	cmp	[fixedflag],0
	je	floatdivaxret

	mov	ax,[pointword]
	add	ax,ax
	add	ax,cx
	jle	floatdivsetdi0

	add	ax,3
	shr	ax,1
	and	ax,0fffeh

	mov	cx,[di]
	and	cx,lenmask
	dec	cx

	cmp	ax,cx
	jae	xxxret
	sub	cx,ax
	sub	[di],cx

	mov	bx,di

	add	di,4
	mov	si,di
	add	si,cx
	add	si,cx
	mov	cx,ax
	rep	movsw
	mov	di,bx
xxxret:
	jmp	floatdivaxret


;
; arithmetic for floating numbers
;


;
;* multiplication of integers & floats
; Note:
;  if float is included then 
;  integer will be translated to float (may be rounded)

mulIorFdisi:			;can treat integer & float
	mov	ax,[di]
	mov	dx,[si]
	and	ax,attribmask
	jz	muldisiifint
	and	dx,attribmask
	jz	muldisiiffloatint
	jmp	mulFFdisi
muldisiifint:
	and	dx,attribmask
	jz	mulIIdisi
	jmp	mul_integer_float
muldisiiffloatint:
	jmp	mul_float_integer


align	4

;
;* multiplicaation of floating numbers
;  [di] *= [si]			;both float
;  reserve [si] (si destroyed)
;  use mulwork


farmulFFdisi:
	call	mulFFdisi
	retf


mulFFdisi:

mul_float_float:
	mov	cx,[di]
	mov	bx,[si]
	mov	al,ch
	mov	ah,bh
	and	cx,lenmask
	jz	mulFFret		;if [di] = 0
	and	bx,lenmask
	jz	mulFFset0		;if [si] = 0
	dec	cx
	dec	bx
	push	ax			;attrib
	winc	si
	winc	di
	mov	ax,[si]
	add	ax,[di]
	push	ax			;new bias

	winc	di
	winc	si

	push	di
	call	far ptr farmulFFsub
	pop	di

	sub	di,4
	mov	si,mulwork
	mov	dx,[si]
	shr	dx,1
	pop	bx			;new bias
	pop	ax			;attrib
	xor	ah,al
	and	ax,signmask
	jmp	getfloat		;call & ret

mulFFset0:
	mov	word ptr [di],0
mulFFret:
	ret


;
; integer data in [si]
;   to float data in [di]
;       si must >= di+2
;	ax: sign
;	dx: precision
;	bx: sum of bias

getFover:
	jmp	ovrerr
getFset0:
	mov	word ptr [di],0
	ret


getfloat:
	mov	cx,[si]		;get length
	add	cx,cx
	add	si,cx
	winc	si		;src MSW+2
	cmp	byte ptr [si-1],0
	jne	getF70
	dec	cx
	dec	si
	dec	bx			;dec bias
getF70:
	mov	[di+2],bx		;set bias
	cmp	bx,floatbiasover	;overflow
	jge	getFover
	cmp	bx,floatbiasunder
	jle	getFset0		;underflow

	lea	bx,[di+4]		;dst base+4
	inc	dx
	or	ah,pointmaskhigh
	or	ax,dx
	mov	[di],ax			;set attrib
	dec	dx
	mov	di,bx
	add	dx,dx

	;now si = src  MSB+1
	;    cx = src byte length
	;    bx = di = dst LSW
	;    dx = dst byte length

	cmp	cx,dx
	jbe	getFlackdata

	sub	si,dx			;src LSW
	shr	dx,1
	mov	ah,[si-1]		;lower byte
	mov	cx,dx
	rep	movsw
	add	ah,ah
	jc	getFroundup		;call & ret
	ret
getFroundup:
	jmp	roundupF

getFlackdata:
	dec	si			;src MSB
	add	di,dx
	dec	di			;dst MSB
	sub	dx,cx
	std
	rep	movsb
	xor	al,al
	mov	cx,dx
	rep	stosb
	cld
	ret


mul_float_integer:
	mov	ax,[di]
	mov	bx,si
	cmp	word ptr [si],0
	je	mulsetdi0
	call	int2floatbxax
	jmp	mul_float_float

mulsetdi0:
	mov	word ptr [di],0
	ret

mul_integer_float:
	mov	ax,[si]
	mov	bx,di
	cmp	word ptr [di],0
	je	mulsetdi0
	call	int2floatbxax
	jmp	mul_float_float


mul_float_rational:
	mov	ax,[di]
	mov	bx,si
	call	rat2floatbxax
	jmp	mul_float_float

mul_rational_float:
	mov	ax,[si]
	mov	bx,di
	call	rat2floatbxax
	jmp	mul_float_float


;
; convert rational to float
;	far call version
;	inp di,si
;	    ax,dx
;	reserve di,si
; use mulwork

farrat2float4add:
	and	ax,lenmask
	mov	cx,[bx]
	dec	ax
	and	cx,lenmask
	add	ax,ax
	add	cx,cx
	sub	ax,dx		;sub bias
	add	ax,cx
	inc	ax
	shr	ax,1
	call	rat2floatbxaxin
	retf


;
; convert rational to float
;	inp bx
;	reserve di,si
;	reserve also [di],[si]
;	result = ax-word on work2
; use mulwork, work2

rat2floatbxaxwork2:
	push	si
	push	di

	mov	si,bx
	mov	di,work2
	copy_si2di
	mov	bx,work2
	call	rat2floatbxax

	pop	di
	pop	si
	ret


;
; convert rational to float
;	inp bx
;	reserve di,si
;	result = [pointword]
; use mulwork

rat2floatbxcurrent:
	mov	ax,[pointword]
	jmps	rat2floatbxaxin

;
; convert rational to float
;	inp bx,ax
;	reserve di,si
;	result = ax-1
; use mulwork

rat2floatbxax:
	and	ax,lenmask
	dec	ax
rat2floatbxaxin:
	mov	[pointtmp],ax

;
; convert rational to float
;	inp bx
;	reserve di,si
;	result precision = [pointtmp]
; use mulwork

rat2floatbx:
	push	si
	push	di

	lea	si,[bx+2]	;top of num
	lodsw
	mov	[bx],ax		;memo attribute of num
	and	ax,lenmask
	add	si,ax
	add	si,ax		;top of den
	mov	di,mulwork
	mov	ax,[si]
	mov	cx,[pointtmp]
	and	ax,lenmask
	inc	cx
	cmp	ax,cx
	ja	rat2fbxlonger
rat2fbxshorter:
	inc	ax
	mov	cx,ax
	rep	movsw		;copy den as is
	dec	ax		;new len of den
	mov	[biasmem],0
	jmps	rat2fbx100
rat2fbxlonger:
	movsw			;copy attrib
	sub	ax,cx
	sub	[di-2],ax	;new attrib
	add	ax,ax
	add	si,ax
	neg	ax
	mov	[biasmem],ax
	mov	ax,cx		;mem new len of den
	rep	movsw		;copy den in part

rat2fbx100:
	lea	si,[bx+2]
	mov	cx,[si]
	mov	di,si
	and	cx,lenmask
	add	ax,[pointtmp]
	inc	ax
	cmp	ax,cx
	jb	rat2fbxlonger2
	je	rat2fbx200
rat2fbxshorter2:
	mov	[si],ax		;new length
	mov	di,si
	add	si,cx
	add	di,ax
	add	si,cx		;MSW of num
	add	di,ax
	sub	ax,cx
	std
	rep	movsw
	mov	cx,ax
	add	ax,ax
	sub	[biasmem],ax
	xor	ax,ax
	rep	stosw
	cld
	jmps	rat2fbx200
rat2fbxlonger2:
	mov	[si],ax		;new length
	lea	di,[si+2]
	xchg	ax,cx
	mov	si,di
	sub	ax,cx
	add	ax,ax
	add	si,ax
	add	[biasmem],ax
	rep	movsw
rat2fbx200:
	lea	di,[bx+2]
	mov	si,mulwork
	push	bx
	call	idivIIdisi
	pop	bx

	lea	si,[bx+2]
	mov	ax,[si]
	add	ax,ax
	add	si,ax
	inc	si		;MSB of result?
	cmp	byte ptr [si],0
	jne	rat2fbx210
	dec	ax
	dec	si
rat2fbx210:
	mov	dx,[pointtmp]
	mov	cx,dx
	inc	dx
	add	ax,[biasmem]
	or	dh,pointmaskhigh
	mov	[bx+2],ax		;set bias
	mov	ax,[bx]
	and	ax,signmask
	or	ax,dx
	mov	[bx],ax			;set new attribute

	sub	si,cx
	sub	si,cx
	lea	di,[bx+4]
	mov	ah,[si]
	inc	si
	cmp	si,di
	je	rat2fbxret
	rep	movsw
	add	ah,ah
	jnc	rat2fbxret
	add	bx,4
	call	roundupF
rat2fbxret:
	pop	di
	pop	si
	ret


;
; convert int, rat & float to float
;	specially tailored to the argument of functions

;	inp bx
;	reserve di,si
;	result = just [pointword] words long

complex2float:
	mov	ax,1
	call	memoryalloc1

	mov	si,[calcsp]
	mov	ax,[si+2]
	and	ax,lenmask
	add	ax,2
	add	ax,ax
	add	si,ax		;top of imaginary part
	mov	ax,xa
	call	xputsub1	;memo imaginary part

	push	bx
	mov	bx,[calcsp]
	add	bx,2
	call	real2floatbxjust	;real part to float

	mov	di,[calcsp]
	mov	ax,[di+2]
	and	ax,lenmask
	add	ax,2
	add	ax,ax
	add	di,ax
	mov	ax,xa
	pop	bx
	push	di
	call	xgetsub1		;restore imaginary part
	pop	bx
	call	real2floatbxjust	;to float

	mov	bx,[calcsp]
	mov	si,bx
	mov	ax,[bx+2]
	and	ax,lenmask
	add	si,ax
	add	si,ax
	mov	dx,[si]
	and	dx,lenmask
	add	ax,dx
	add	ax,2
	or	ah,complexmaskhigh
	mov	[bx],ax		;set attribute

	mov	ax,1
	call	memoryfree1
	ret

all2float0:
real2float0:
	mov	bx,[calcsp]
real2floatbxjust:
	mov	ax,[bx]
	mov	cx,ax
	and	ah,attribmaskhigh
	jz	int2floatbxcurrent		;if integer
	cmp	ah,pointmaskhigh
	je	real2floatbxret		;if already float
	cmp	ah,ratmaskhigh
	je	rat2floatbxcurrent		;if rational
	cmp	ah,complexmaskhigh
	je	complex2float		;if complex
	jmp	ilgerr
real2floatbxret:
	ret

farall2float0:
	call	all2float0
	retf

farreal2floatbxjust:
	call	real2floatbxjust
	retf


;
; convert int to float
;	inp bx
;	reserve di,si
;	result = accurate as possible
;		 at least pointmin

farint2floatbx:
	call	farint2floatbxsub
	retf

fari2fsubret:
	ret

farint2floatbxsub:
	mov	cx,[bx]
	and	cx,lenmask
	jz	fari2fsubret		;if 0 do nothing

	mov	ax,pointmax
	cmp	ax,cx
	jbe	i2fin
	mov	ax,cx
	inc	ax
	mov	dx,pointmin
	and	al,0feh			;must be even
	cmp	ax,dx
	jae	i2fin
	mov	ax,dx
	jmps	i2fin


;
; convert int to float
;	inp bx
;	reserve di,si
;	result = just [pointtmp] words long

int2floatbx:
	mov	cx,[bx]
	and	cx,lenmask
	jz	i2fbxret

	mov	ax,[pointtmp]
	jmp	i2fin


;
; convert int to float
;	inp bx
;	reserve di,si
;	result = just [pointword] words long

i2fbxret:
	ret

int2floatbxcurrent:
	mov	cx,[bx]
	and	cx,lenmask
	jz	i2fbxret

	mov	ax,[pointword]
	jmps	i2fin

int2floatbxax:
	and	ax,lenmask
	mov	cx,[bx]
	dec	ax
	and	cx,lenmask
	jz	i2fbxret

i2fin:
	;bx = base adr
	;cx = src length
	;ax = dst length(excludes bias)

	push	si
	push	di

	inc	ax			;includes bias

	mov	dx,[bx]
	and	dx,signmask
	add	dx,ax
	or	dx,pointmask
	mov	[bx],dx			;set new attrib

	mov	si,bx
	mov	di,bx
	add	cx,cx
	add	ax,ax
	add	si,cx			;src MSW
	add	di,ax			;dst MSW

	cmp	byte ptr [si+1],0
	jne	i2f10
	dec	si
	dec	cx
i2f10:
	mov	dx,cx			;mem bias
	sub	ax,2			;byte length of dst
	cmp	si,di
	ja	i2fdown
	cmp	ax,cx
	jb	i2fequal
i2fup:
	sub	ax,cx			;byte offset
	std
	inc	cx
	shr	cx,1
	rep	movsw
	mov	cx,ax
	xor	ax,ax
	shr	cx,1
	jnc	i2fup10
	mov	[di+2],al
i2fup10:
	rep	stosw
	cld
	mov	[bx+2],dx		;set bias
i2fret:
	pop	di
	pop	si
i2fretdirect:
	ret

i2fequal:
	mov	cx,ax
	shr	cx,1
	std
	rep	movsw
	cld
	mov	ah,[si+1]		;used by roundupF
	jmps	i2froundup

i2fdown:
	mov	cx,ax
	sub	si,ax
	shr	cx,1
	add	si,2
	lea	di,[bx+4]
	mov	ah,[si-1]		;used by roundupF
	rep	movsw
i2froundup:
	mov	[bx+2],dx		;set bias
	add	ah,ah
	jnc	i2fret
	add	bx,4
	call	roundupF
	jmp	i2fret


;
;* float division entry
;  [di]=[di]/[si]
;  resadr = 0

fardivAAdisi:
	call	divAAdisi
	retf

fardivin:
	call	divin
	retf

farDiv_calcsp:
	mov	di,[calcsp]
	lea	si,[di-unitbyte]
	call	divin_nobacksp
	retf

divset0:
	mov	word ptr ds:[resadr],0
	ret

divdivby0:
	jmp	diverr

divin:
	call	backsp
divAAdisi:
divin_nobacksp:
	mov	dx,[si]
	mov	ax,[di]
	or	dx,dx
	jz	divdivby0
	or	ax,ax
	jz	divset0

	mov	al,ah
	mov	ah,dh
	and	ax,attribmaskdouble
	jnz	div_extra
	jmp	div_integer_integer


div_data_types	equ	4

div_extra:
	xor	bx,bx
	or	al,al
	jz	divextra20
	add	bx,div_data_types
	cmp	al,pointmaskhigh
	je	divextra20
	add	bx,div_data_types
	cmp	al,complexmaskhigh
	je	divextra20
	add	bx,div_data_types
	cmp	al,ratmaskhigh
	jne	div_etc

divextra20:
	or	ah,ah
	jz	divextra40
	inc	bx
	cmp	ah,pointmaskhigh
	je	divextra40
	inc	bx
	cmp	ah,complexmaskhigh
	je	divextra40
	inc	bx
	cmp	ah,ratmaskhigh
	jne	div_etc2

divextra40:
	add	bx,bx
	jmp	cs:[div_table+bx]


div_etc:
	cmp	al,packmaskhigh
	je	go_div_overload
	cmp	ah,packmaskhigh
	je	go_div_overload

	cmp	al,polymaskhigh
	je	go_div_poly1
	cmp	al,modpolymaskhigh
	je	go_div_modpoly1
	cmp	al,ratpolymaskhigh
	je	go_div_ratfunc1
	jmp	ilgerr

go_div_poly1:
	jmp	far ptr div_pl		;poly / any
go_div_modpoly1:
	jmp	far ptr div_mpl		;modpoly / any
go_div_ratfunc1:
	jmp	far ptr div_rf

div_etc2:
	cmp	ah,polymaskhigh
	je	go_div_poly2		;[si] is poly
	cmp	ah,modpolymaskhigh
	je	go_div_modpoly2		;[si] is modpoly
	cmp	ah,ratpolymaskhigh
	je	go_div_ratfunc2		;[si] is rat func
	cmp	ah,packmaskhigh
	je	go_div_overload		;[si] is pack
divilg2:
	jmp	ilgerr


go_div_poly2:
	jmp	far ptr div_numpl	;num / poly
go_div_modpoly2:
	or	al,al
	jnz	divilg2
	jmp	far ptr div_intmpl
go_div_ratfunc2:
	jmp	far ptr div_numrf	;num / rf

go_div_overload:
	jmp	overloaddiv


even
div_table	label	word
	dw	div_integer_integer,div_integer_float
	dw	div_integer_complex,div_integer_rational

	dw	div_float_integer,div_float_float
	dw	div_float_complex,div_float_rational

	dw	div_complex_integer,div_complex_float
	dw	div_complex_complex,div_complex_rational

	dw	div_rational_integer,div_rational_float
	dw	div_rational_complex,div_rational_rational

	;
	;* division main routines
	;  for each data type
	;

;
; slide [di] by offset 2*ax
;	treat [di] as an integer
;	reserve di,si
slideover:
	jmp	ovrerr

slide_diax_word:
	or	ax,ax
	jz	slidediaxret	;do nothing
	push	si
	push	di
	jl	slidediaxdown
slidediaxup:
	mov	cx,[di]
	add	[di],ax		;new attrib
	and	ax,lenmask
	and	cx,lenmask
	cmp	ax,limitword
	ja	slideover	;overflow
	add	di,cx
	add	di,cx		;src MSW
	mov	si,di
	add	di,ax
	add	di,ax		;dst MSW
	std
	rep	movsw		;slide up
	mov	cx,ax
	xor	ax,ax
	rep	stosw		;fill by 0
	cld
slidediaxretpop:
	pop	di
	pop	si
slidediaxret:
	ret

slidediaxdown:
	mov	cx,[di]
	winc	di		;LSW
	add	cx,ax
	mov	si,di
	mov	[di-2],cx	;new attr
	and	cx,lenmask
	sub	si,ax
	sub	si,ax
	rep	movsw		;slide down
	jmp	slidediaxretpop

;
; slide [di] by offset ax
;	treat [di] as an integer
;	reserve di,si
;
;	limit is LIMITWORD

slidebover:
	jmp	ovrerr

slide_diax:
	sar	ax,1
	jnc	slide_diax_word
	inc	ax
	or	ax,ax
	push	si
	push	di
	jl	slidediaxbdown
slidediaxbup:
	mov	cx,[di]
	add	[di],ax		;new attrib
	and	ax,lenmask
	and	cx,lenmask
	cmp	ax,limitword
	ja	slidebover	;overflow
	add	di,cx
	add	di,cx		;src MSW
	mov	si,di
	add	di,ax
	add	di,ax
	mov	byte ptr [di+1],0
	dec	di		;dst MSW
	std
	rep	movsw		;slide up
	dec	ax
	mov	cx,ax
	xor	ax,ax
	rep	stosw		;fill by 0
	cld
	mov	[di+1],al	;fill by 0
slidediaxbretpop:
	pop	di
	pop	si
slidediaxbret:
	ret

slidediaxbdown:
	mov	cx,[di]
	winc	di		;LSW
	add	cx,ax
	mov	si,di
	mov	[di-2],cx	;new length
	and	cx,lenmask
	sub	si,ax		;ax is negative
	sub	si,ax
	dec	si
	rep	movsw		;slide down
	mov	byte ptr [di-1],0	;over copied
	jmp	slidediaxbretpop


;
;* division of integers & floats
; Note:
;  if float is included then 
;  integer will be translated to float (may be rounded)

fardivIorFdisi:			;can treat integer & float
	call	divIorFdisi
	retf

divIorFdisi:			;can treat integer & float
	mov	ax,[di]
	mov	dx,[si]
	and	ax,attribmask
	jz	divdisiifint
	and	dx,attribmask
	jz	divdisiiffloatint
	jmp	div_float_float
divdisiifint:
	and	dx,attribmask
	jz	divIIdisi
	jmp	div_integer_float
divdisiiffloatint:
	jmp	div_float_integer


;
;* float division of integers
;  [di] /= [si]		both integer
; destroy [si]

divIIret0:
	ret

	even
divIIdisi:
div_integer_integer:
	mov	cx,[di]
	jcxz	divIIret0	;if [di]=0

	mov	ax,[pointword]
	mov	[pointtmp],ax

	mov	ax,[si]
	mov	dx,ax
	and	ax,lenmask

	push	si
	push	di
	mov	bx,di		;memo base of num

	xor	dx,cx
	mov	[si],ax
	and	dx,signmask	;get sign
	mov	cx,[pointtmp]
	push	dx
	push	si		;/*

	inc	cx
	mov	[biasmem],0
	cmp	ax,cx
	jbe	divII100
divIIlonger:
	sub	ax,cx
	mov	[si],cx		;new attrib
	winc	si
	add	ax,ax
	mov	di,si
	add	si,ax
	neg	ax
	mov	[biasmem],ax
	mov	ax,cx		;mem new len of den
	rep	movsw		;copy den shortly

divII100:
	add	ax,[pointtmp]
	mov	cx,[bx]
	mov	si,bx
	and	cx,lenmask
	inc	ax
	mov	[bx],cx
	cmp	ax,cx
	jb	divIIlonger2
	je	divII200
divIIshorter2:
	mov	[si],ax		;new length
	mov	di,si
	add	si,cx
	add	di,ax
	add	si,cx		;MSW of num
	add	di,ax
	sub	ax,cx
	std
	rep	movsw
	mov	cx,ax
	add	ax,ax
	sub	[biasmem],ax
	xor	ax,ax
	rep	stosw
	cld
	jmps	divII200
divIIlonger2:
	mov	[si],ax		;new length
	lea	di,[si+2]
	xchg	ax,cx
	mov	si,di
	sub	ax,cx
	add	ax,ax
	add	[biasmem],ax
	add	si,ax
	rep	movsw
divII200:
	mov	di,bx
	pop	si		;*/

	push	bx
	call	idivIIdisi
	pop	bx

	mov	ax,[bx]
	mov	si,bx
	add	ax,ax
	add	si,ax
	inc	si		;MSB of result?
divII210:
	cmp	byte ptr [si],0
	jne	divII220
	dec	ax
	dec	si
	jmp	divII210
divII220:
	mov	dx,[pointtmp]
	add	ax,[biasmem]	;ax = new bias
	inc	dx
	pop	cx		;get sign
	or	dh,pointmaskhigh
	or	cx,dx
	mov	[bx],cx		;set new attribute
	mov	dx,ax		

	mov	cx,[pointtmp]
	sub	si,cx
	sub	si,cx
	lea	di,[bx+4]
	mov	ah,[si]
	inc	si
	cmp	si,di
	je	divII300
	jb	divII400
	rep	movsw
divII300:
	mov	[bx+2],dx	;set new bias
	add	ah,ah
	jnc	divIIret
	add	bx,4
	call	roundupF
divIIret:
	pop	di
	pop	si
	ret
divII400:
	add	si,cx
	add	di,cx
	add	si,cx
	add	di,cx
	wdec	si
	wdec	di
	std
	rep	movsw
	cld
	jmp	divII300


;
;* division of floating numbers
;  [di] /= [si]			;both float
;  reserve [si] (si destroyed)

	even
divFFSImem	dw	?
divFFSImem2	dw	?
divFFresultlen	dw	?
divFFresultbias	dw	?

divFFdiverr:
	jmp	diverr
divFFskipret:
	ret

divFFdisi:
div_float_float:
	mov	bx,[si]		;get attrib
	winc	si
	or	bx,bx
	jz	divFFdiverr
	mov	cx,[di]
	jcxz	divFFskipret	;if num=0

	push	di		;push base adr

	winc	di
	mov	ax,[di]
	mov	dx,bx
	sub	ax,[si]
	xor	dx,cx
	mov	[divFFresultbias],ax

	and	dx,signmask
	push	dx		;push sign

	and	bx,lenmask
	and	cx,lenmask
	dec	bx
	dec	cx
	mov	[di],cx
	mov	ax,bx
	sub	ax,cx
	jb	divFFdilonger
divFFsilonger:
	add	si,ax
	add	si,ax
	mov	dx,[si]
	sub	bx,ax
	mov	[divFFsimem],dx
	jmps	divFFin

divFFdilonger:
	add	cx,ax

	mov	ax,[si]
	mov	[divFFsimem],ax

divFFin:
	mov	[si],bx		;new attrib as integer

	mov	[divFFresultlen],cx

	push	si

	;reduce [si] to minimum length

	xchg	bx,cx
	xchg	si,di
	and	cx,lenmask
	xor	ax,ax
	winc	di		;skip bias
	repe	scasw
	sub	di,4
	inc	cx
	mov	ax,[di]
	mov	[di],cx		;attrib as integer
	mov	[divFFsimem2],ax
	xchg	bx,cx
	xchg	si,di

	mov	ax,bx
	inc	ax		;ax = new len[si]+1
	add	ax,[divFFresultlen]
	sub	ax,[di]
	add	ax,ax
	call	slide_diax

	push	si
	push	di
	call	idivIIdisi
	pop	di
	pop	si

	mov	ax,[divFFsimem2]
	mov	[si],ax

	pop	si
	mov	ax,[divFFsimem]
	mov	[si],ax

	; clear resadr because it has no meaning

	mov	bx,resadr
	mov	word ptr [bx],stringmask1char
	mov	word ptr [bx+2],"?"

	; normalize and copy

	mov	si,di
	mov	ax,[di]
	add	si,ax
	add	si,ax			;MSW
	dec	ax
	mov	cx,[divFFresultlen]
	mov	dx,[divFFresultbias]
	cmp	ax,cx
	je	divFF60
	dec	si			;will be cancelled by dec si
	inc	dx			;inc bias
divFF60:
	inc	si

	pop	ax		;pop sign
	pop	bx		;base adr

	cmp	dx,floatbiasover
	jge	divFFover
	cmp	dx,floatbiasunder
	jle	divFFset0

	or	ax,cx
	mov	di,bx
	inc	ax
	or	ax,pointmask
	mov	[di],ax		;set attribute
	winc	di
	mov	[di],dx		;set bias
	winc	di
	sub	si,cx
	sub	si,cx
	mov	ah,[si]
	inc	si
	rep	movsw
	add	ah,ah
	jc	divFFroundup
	ret

divFFroundup:
	add	bx,4
	jmp	roundupF	;call & ret

divFFover:
	jmp	ovrerr
divFFset0:
	mov	word ptr [bx],0
	ret


div_float_integer:
	mov	ax,[si]
	cmp	ax,1
	je	divFI10
	cmp	ax,signmask+1
	je	divFI10
divFI0:
	mov	ax,[di]
	mov	bx,si
	call	int2floatbxax
	jmp	div_float_float
divFI10:
	push	ax
	mov	ax,[si+2]
	push	di
	call	floatdivdiax
	pop	di
	pop	ax
	cmp	word ptr [di],0
	je	divFI20
	and	ax,signmask
	xor	[di],ax
divFI20:
	ret


div_integer_float:
	mov	ax,[si]
	mov	bx,di
	call	int2floatbxax
	jmp	div_float_float


div_rational_integer:
	;(a//b)/c = a/(b*c)

	mov	[dimem_div],di
	mov	[simem_div],si

	xchg	si,di
	mov	ax,[si+2]
	add	si,4
	and	ax,lenmask
	add	ax,ax
	add	si,ax		;top of b
	call	mulIIdisi	;b*c

	mov	di,[dimem_div]
	lea	si,[di+2]
	copy_si2di
	mov	di,[dimem_div]
	mov	si,[simem_div]
	jmp	div_integer_integer

div_integer_rational:
	;a/(c//d) = (a*d)/c

	mov	[dimem_div],di
	mov	[simem_div],si

	mov	ax,[si+2]
	add	si,4
	and	ax,lenmask
	add	ax,ax
	add	si,ax		;top of d
	call	mulIIdisi	;a*d

	mov	di,[dimem_div]
	mov	si,[simem_div]
	add	si,2		;top of c
	jmp	div_integer_integer


div_rational_rational:
	;(a//b)/(c//d) = (a*d)/(b*c)

	mov	[dimem_div],di
	mov	[simem_div],si

	mov	si,di
	copyimagsi	work2	;reserve b

	mov	di,[dimem_div]
	lea	si,[di+2]
	copy_si2di
	mov	di,[dimem_div]	;top of a
	mov	si,[simem_div]
	mov	ax,[si+2]
	add	si,4
	and	ax,lenmask
	add	ax,ax
	add	si,ax		;top of d
	call	mulIIdisi	;a*d

	mov	di,work2
	mov	si,[simem_div]
	add	si,2		;top of c
	call	mulIIdisi	;b*c

	mov	di,[dimem_div]
	mov	si,work2
	jmp	div_integer_integer


div_float_rational:
	mov	ax,[di]
	mov	bx,si
	call	rat2floatbxax
	jmp	div_float_float

div_rational_float:
	mov	ax,[si]
	mov	bx,di
	call	rat2floatbxax
	jmp	div_float_float


div_complex_rational:
	mov	ax,[di]
	mov	bx,si
	call	rat2floatbxax
	jmp	div_complex_float

div_rational_complex:
	mov	ax,[si]
	mov	bx,di
	call	rat2floatbxax
	jmp	div_float_complex


;
;	get answer for each 16bit
;
divFFsub:
	;normalize higher 2 words of resadr
	;ans set to dx:ax

	mov	si,resadr
	add	si,[ptrnow]
	mov	word ptr [si+2],0ffffh	;to avoid borrow

	mov	cx,[sftbit]
	mov	dx,[si]
	mov	ax,[si-2]
	mov	bh,[si-3]
	jcxz	divFFsub30
divFFsub10:
	add	bh,bh
	rcl	ax,1
	rcl	dx,1
	myloop	divFFsub10

divFFsub30:

	;ax = min of (dx:ax/[divword],0ffffh)

divFFsub40:
	mov	bx,[divword]
	cmp	dx,bx
	jae	divFFsub50
	div	bx
	mov	bp,ax
	or	ax,ax
	jnz	divFFsub60
	ret			;ans = 0

divFFsub50:
	mov	bp,0ffffh

divFFsub60:		;subtract ax*[si] from resadr
	mov	cx,[divlen]
	mov	si,[simem_m]
	mov	bx,resadr
	mov	ax,[ptrnow2]
	add	bx,ax
	or	ax,ax
	jge	divFFsub70
	sub	bx,ax		;bx = resadr
	sub	si,ax
	sar	ax,1
	add	cx,ax
public divFFsub70
divFFsub70:
	lodsw
	mul	bp
	sub	[bx],ax
	winc	bx
	sbb	[bx],dx
	jb	divFFsub90
divFFsub80:
	myloop	divFFsub70
	ret

divFFsub90:
	mov	ax,bx			;mem
divFFsub95:
	winc	bx
	sbb	word ptr [bx],0
	jb	divFFsub95
	mov	bx,ax
	cmp	cx,1
	jne	divFFsub80

	;over subtracted

divFFsub100:
	mov	cx,[divlen]
	mov	si,[simem_m]
	mov	bx,resadr
	mov	ax,[ptrnow2]
	add	bx,ax
	or	ax,ax
	jge	divFFsub105
	sub	bx,ax		;bx = resadr
	sub	si,ax
	sar	ax,1
	add	cx,ax
divFFsub105:
	clc
divFFsub110:
	lodsw
	adc	[bx],ax
	winc	bx
	myloop	divFFsub110
	adc	word ptr [bx],0
	dec	bp
	jnc	divFFsub100
	ret


;
; * ceil function
;

ceilin:
	call	kakko
ceil_ent:
	call	fix_ent

	test	dh,signmaskhigh
	jz	ceilpos
	ret
ceilpos:
	or	al,al
	jnz	ceilinc
	ret
ceilinc:
	mov	di,bx
	mov	ax,1
	jmp	lwadd		;[di] += ax



;
;* int(x) & floor(x)
;

farint_ent:
	call	int_ent
	retf


floorin:
intin:
	call	kakko
floor_ent:
int_ent:
	call	fix_ent

	test	dh,signmaskhigh
	jnz	f2ibxneg
	ret
f2ibxneg:
	or	al,al
	jnz	f2ibxdec
	ret
f2ibxdec:
	mov	di,bx
	mov	ax,1
	jmp	lwsub		;[di] -= ax

;
;* round(x)
;

roundin:
	call	kakko
round_ent:
	call	fix_ent

	or	al,al
	jnz	f2riwithfrac
	ret
f2riwithfrac:
	add	ah,ah
	jc	f2riwithcarry
	ret
f2riwithcarry:
	mov	di,bx
	mov	ax,1
	test	dh,signmaskhigh
	jnz	f2ribxdec
f2ribxinc:
	jmp	lwadd		;[di] += ax
f2ribxdec:
	jmp	lwsub		;[di] -= ax


;
;* fix(x)
;
; out	dh : includes sign bit
;	al : 0 iff frac part = 0
;	ah : MSB of frac (valid iff al<>0)
; reserve bx


fixin:
	call	kakko
fix_ent:
	mov	si,[calcsp]
	mov	bx,si
	mov	ax,[si]
	mov	dx,ax
	and	ah,attribmaskhigh
	jz	fixintret		;already integer
	cmp	ah,pointmaskhigh
	je	f2isub
	cmp	ah,ratmaskhigh
	je	gorat2intfix
	jmp	ilgerr
fixintret:
	xor	ax,ax
	ret

gorat2intfix:
	jmp	rat2intfix


;
; float to integer subroutine
;
; out	dh : includes sign bit
;	al : 0 iff frac part = 0
;	ah : MSB of frac (valid iff dl<>0)
; reserve bx

f2ismall:
	mov	word ptr [bx],0
	mov	ax,0001h	;frac MSB = 0 but nonzero frac
	ret

f2iset0:
	jl	f2ismall

	mov	word ptr [bx],0
	mov	ax,dx
	and	ax,lenmask
	add	ax,ax
	add	si,ax
	mov	ax,[si]		;get MSW
	mov	al,1		;nonzero frac
	ret


farfloat2intbx:
	call	float2intbx
	retf

f2isub0:
	xor	ax,ax
	ret

f2iover:
	jmp	ovrerr

float2intbx:
f2isub:
	mov	si,bx
	mov	dx,[bx]
	or	dx,dx
	jz	f2isub0			;if 0
	mov	ax,[si+2]		;ax = bias
	cmp	ax,limitword*2
	jg	f2iover
	or	ax,ax
	jle	f2iset0

	mov	cx,ax
	inc	cx
	shr	cx,1			;new length
	mov	bx,dx
	and	bh,signmaskhigh
	or	ch,bh
	mov	[si],cx			;new attribute

	mov	bx,si			;restore bx

	mov	cx,dx
	and	cx,lenmask
	dec	cx
	add	cx,cx			;whole byte length
	sub	cx,ax			;bytes for frac
	jg	f2iwithfraction
	jz	f2ijustinteger

f2iwithhidden0:
	neg	cx			;fill lower by 0
	sub	cx,2
	jb	f2i1hidden0		;1 byte 0
	je	f2i2hidden0		;2 bytes 0

f2imanyhidden0:
	mov	ax,cx			;offset for slide up
	mov	cx,dx
	and	cx,lenmask
	add	cx,cx
	add	si,cx			;MSW
	mov	di,si
	add	di,ax
	shr	cx,1
	dec	cx
	std
	mov	byte ptr [di+2],0
	rep	movsw
	mov	cx,ax
	inc	di
	xor	al,al
	add	cx,2			;for bias
	rep	stosb
	cld
	xor	ax,ax
	ret

f2i2hidden0:				;base unchanged
	mov	word ptr [bx+2],0
	xor	ax,ax
	ret

f2i1hidden0:
	mov	cx,ax
	xor	ax,ax
	lea	di,[bx+2]
	shr	cx,1
	stosb				;set 0
	lea	si,[bx+4]
	rep	movsw
	stosb				;1 more 0
	ret

f2ijustinteger:
	lea	di,[bx+2]
	mov	cx,ax
	lea	si,[bx+4]
	shr	cx,1
	rep	movsw
	xor	ax,ax
	ret


f2iwithfraction:
	;cx = bytes of frac

	lea	si,[bx+4]		;base + 4
	add	si,cx			;integer part base

	;search frac part

	push	ax
	lea	di,[bx+4]
	xor	ax,ax
	repe	scasb
	je	f2icopyintpart		;if frac part = 0
	mov	al,1
	mov	ah,[si-1]		;MSB of frac

f2icopyintpart:
	pop	cx
	lea	di,[bx+2]
	rep	movsb
	mov	byte ptr [di],0		;one more 0
	ret


comment %
;
; * floor function
;

floorset01:
	or	dx,dx
	jnz	floorsetminus1
	mov	word ptr [bx-4],0	;set 0
	ret
floorsetminus1:
	mov	ax,[pointword]
	mov	cx,ax
	inc	ax
	or	ax,signmask+pointmask
	mov	[bx-4],ax
	mov	word ptr [bx-2],1	;bias
	mov	di,bx
	xor	ax,ax
	rep	stosw
	mov	byte ptr [di-1],1
	ret


floorilgerr:
	jmp	ilgerr

floorrational:
	call	rat2int
floorint2float:
	mov	bx,[calcsp]
	jmp	int2floatbxasis

floorin:
	call	kakko
floor_ent:
	mov	si,[calcsp]
floor10:
	mov	dx,[si]
	test	dh,nonrealmaskhigh
	jnz	floorilgerr
	test	dh,ratmaskhigh
	jnz	floorrational
	test	dh,pointmaskhigh
	jz	floorint2float		;if integer

	mov	ax,[si+2]
	or	ax,ax
	jle	floorset01		;0/1 as positive/negative

	lea	bx,[si+4]
	mov	cx,dx
	and	cx,lenmask
	dec	cx
	add	cx,cx
	sub	cx,ax
	jbe	floorret		;already integer

	xor	dl,dl			;fractional part flag
	mov	di,bx
	xor	al,al
	repe	scasb
	je	floorret		;already integer
	mov	dl,1			;fractional part <> 0
	inc	cx
	dec	di
	rep	stosb			;fill by 0

	and	dh,signmaskhigh
	or	dl,dh
	cmp	dl,signmaskhigh
	ja	floorneg		;both non zero
floorret:
	ret

floorneg:
roundinc:
	mov	dx,[bx-4]
	mov	si,bx
	mov	cx,[bx-2]
	and	dx,lenmask
	dec	dx
	add	dx,dx
	sub	dx,cx
	add	si,dx		;integer base ptr
	jcxz	floorslide1
	stc
floor50:
	jnc	floor60
	adc	byte ptr [si],0
	inc	si
	myloop	floor50
	jc	floorslide1
floor60:
	ret
floorslide1:
	mov	word ptr [si],1	;highest word
	jmp	slide1
%


;
;* power of float
;
farsquareIFCdi:
	call	squareIFCdi
	retf


squareIFCdi:
	mov	ax,[di]
	and	ax,attribmask
	jz	squareIdi
	cmp	ax,pointmask
	je	squareFdi
	cmp	ax,complexmask
	je	squareCdi
	jmp	ilgerr


;
;* compare float with float
;  must be same as subtraction
;  algorithm:
;	compare bias
;		if same then compare common parts
;			if same then check the rest is 0
;	does not care about [pointword]

; non destructive and non use mulwork,work2,work3,work4

compFFdisi:
	mov	cx,[di]
	mov	dx,[si]
	jmp	cmp_float_float

di_zeroFF:
	or	dx,dx
	jz	disi_equalFF		;dizerosizero
	test	ah,signmaskhigh
	jnz	di_biggerFF		;dizerosineg
	jmp	si_biggerFF		;dizerosipos
si_zeroFF:
	test	al,signmaskhigh
	jnz	si_biggerFF		;dinegsizero
	jmp	di_biggerFF		;dipossizero


cmp_float_float:
	mov	al,ch
	mov	ah,dh
	and	cx,lenmask
	and	dx,lenmask
	test	al,signmaskhigh
	jnz	di_negFF		;if [di]<0
	test	ah,signmaskhigh
	jnz	di_biggerFF	;if [di]>=0 & [si]<0

	;if both >= 0
	;compare bias
compFFin:
	jcxz	di_zeroFF
	or	dx,dx
	jz	si_zeroFF

	mov	ax,[di+2]
	cmp	ax,[si+2]
	jg	di_biggerFF
	jl	si_biggerFF

	;if same bias

	add	di,cx
	add	si,dx
	add	di,cx		;MSW
	add	si,dx		;

	dec	cx
	dec	dx
	cmp	cx,dx
	jae	di_longer
si_longer:
	sub	dx,cx
	std
	repe	cmpsw
	cld
	jb	di_biggerFF	;[si]<[di]
	ja	si_biggerFF	;[si]>[di]
	mov	cx,dx

	;search rest of [si]

	mov	di,si
	xor	ax,ax
	std
	repe	scasw
	cld
	je	disi_equalFF
	jmp	si_biggerFF
di_longer:
	xchg	cx,dx
	sub	dx,cx
	std
	repe	cmpsw
	cld
	jb	di_biggerFF	;[si]<[di]
	ja	si_biggerFF	;[si]>[di]
	mov	cx,dx

	jcxz	disi_equalFF

	;search rest of [di]

	xor	ax,ax
	std
	repe	scasw
	cld
	je	disi_equalFF
	jmp	di_biggerFF

si_biggerFF:
	mov	al,4
	ret
di_biggerFF:
	mov	al,2
	ret
disi_equalFF:
	mov	al,1
	ret

di_negFF:
	test	ah,signmaskhigh
	jz	si_biggerFF	;if [di]<0 & [si]>=0

	;if both < 0
	; use routine for > 0

	call	compFFin

oppositeresult:
	cmp	al,1
	je	oppositeret
	sub	al,6		;2 -> 4
	neg	al		;4 -> 2
oppositeret:
	ret


;
;* compare float with integer
;  must be same as subtraction
;  algorithm:
;	compare bias
;		if same then compare common parts
;			if same then check the rest is 0
;	does not care about [pointword]

; non destructive and non use mulwork,work2,work3,work4

cmp_float_integer:
	xchg	cx,dx
	xchg	di,si
	call	cmp_integer_float
	jmp	oppositeresult


di_negIF:
	test	ah,signmaskhigh
	jz	si_biggerIF	;if [di]<0 & [si]>=0

	;if both < 0
	; use routine for > 0

	call	compIFin
	cmp	al,1
	je	compIFnegret
	sub	al,6		;2 -> 4
	neg	al		;4 -> 2
compIFnegret:
	ret


cmp_integer_float:
	mov	al,ch
	mov	ah,dh
	and	cx,lenmask
	and	dx,lenmask
	test	al,signmaskhigh
	jnz	di_negIF	;if [di]<0
	test	ah,signmaskhigh
	jnz	di_biggerIF	;if [di]>=0 & [si]<0

	;if both >= 0

	jcxz	si_biggerIF	;if [di] = 0

compIFin:
	mov	ax,[si+2]
	or	ax,ax
	jle	di_biggerIF	;if [si] < 1

	mov	dx,[di]
	and	dx,lenmask
	add	dx,dx		;dx = byte length
	add	di,dx		;MSW
	cmp	byte ptr [di+1],0
	jne	compIF10
	dec	di
	dec	dx
compIF10:
	cmp	ax,dx
	jb	di_biggerIF
	ja	si_biggerIF

	;if same bias

	mov	ax,[si]
	and	ax,lenmask
	add	ax,ax
	add	si,ax		;MSW

	sub	ax,2		;byte length
	inc	di		;MSB
	inc	si		;

	cmp	ax,dx
	jb	compIFIlonger
compIFFlonger:
compIFsamelen:
	mov	cx,dx		;compare integer part
	std
	repe	cmpsb
	cld
	jb	di_biggerIF
	ja	si_biggerIF
	sub	ax,dx
	jz	disi_equalIF
	mov	cx,ax		;check fractional part of [si]
	mov	di,si
	xor	al,al
	std
	repe	scasb
	cld
	je	disi_equalIF
	jmp	si_biggerIF

si_biggerIF:
	mov	al,4
	ret
di_biggerIF:
	mov	al,2
	ret
disi_equalIF:
	mov	al,1
	ret

compIFIlonger:
	mov	cx,ax		;compare upper of integer part
	std
	repe	cmpsb
	cld
	jb	di_biggerIF
	ja	si_biggerIF
	sub	dx,ax
	mov	cx,dx		;check rest of [di]
	xor	al,al
	std
	repe	scasb
	cld
	je	disi_equalIF
	jmp	di_biggerIF


;
;* compare float with rational
; use mulwork,work2

cmp_float_rational:

if debug
cmp	di,work2
je	cfrerr
cmp	si,work2
je	cfrerr
endif
	mov	ax,[di]
	mov	bx,si
	call	rat2floatbxaxwork2
	mov	si,work2
	jmp	compFFdisi


cmp_rational_float:
if debug
cmp	di,work2
je	cfrerr
cmp	si,work2
je	cfrerr
endif
	mov	ax,[si]
	mov	bx,di
	call	rat2floatbxaxwork2
	mov	di,work2
	jmp	compFFdisi

if debug
cfrerr:
	jmp	systemerr
endif


;
;* integer division of floating numbers
;  [di] = int([di]/[si])
;	inp [di],[si] both float (of course not 0)
;	also remainder in resadr
;	[si] may be transformed to higher precision

idivset0_0:
	mov	word ptr ds:[resadr],0
	ret

idivFFset0_di:
	push	si		;/*
	lea	si,[di-2]	;copy [di] to resadr
	push	si		;/**
	mov	di,resadr
	copy_si2di
	pop	si		;**/
	test	word ptr [si],signmask
	jnz	idivFF0negative
	mov	word ptr [si],0
	add	sp,2		;*/
	ret
idivFF0negative:
	mov	word ptr [si],signmask+1	;ans = -1
	mov	word ptr [si+2],1
	pop	si		;*/
	wdec	si
	mov	di,resadr
	call	addFFdisi
	pop	si
	ret


idivFFover:
	jmp	ovrerr

idivFFdisi:
idiv_float_float:
	mov	bx,[si]		;get attrib
	mov	cx,[di]
	winc	si
	winc	di
	mov	ax,[si]		;get bias
	mov	dx,[di]
	and	bx,signmask+lenmask
	and	cx,signmask+lenmask
	jz	idivset0_0
	dec	bx
	dec	cx
	sub	dx,ax		;dx = bias(x)-bias(y)
	jl	idivFFset0_di	;if abs(x) < abs(y)

	mov	[si-2],ax	;mem bias(y)
	mov	[si],bx		;length&sign as integer
	mov	[di],cx		;length&sign as integer

	;now di = original di + 2
	;    si = original si + 2

	and	bx,lenmask
	and	cx,lenmask
	add	bx,bx		;len(y)
	add	cx,cx		;len(x)
	mov	ax,bx
	add	ax,dx		;ax = bias(x)-bias(y)+len(y)
	cmp	ax,2*limitword
	ja	idivFFover

	sub	bx,[si-2]	;bx = len(y)-bias(y)
	push	bx		;/*

	sub	ax,cx
	jz	idivFF50
	jb	idivFF40
	call	slide_diax
	jmps	idivFF50
idivFF40:
	neg	ax
	pop	bx		;*/
	add	bx,ax		;new len(y)-bias(y)
	push	bx		;/*
	xchg	si,di
	call	slide_diax
	xchg	si,di
idivFF50:
	push	si
	push	di
	call	idivIIdisi
	pop	di
	pop	si

	mov	ax,[si]			;recover si
	mov	cx,ax
	inc	ax
	add	cx,cx
	mov	dx,[si-2]
	or	ax,pointmask
	sub	cx,dx
	mov	[si-2],ax
	mov	[si],dx

	; set result

	mov	si,di
	sub	di,2
	copy_si2di

	; normalize resadr

	mov	bx,resadr
	mov	ax,[bx]
	and	ax,lenmask
	jz	idivFFretpop		;if 0
	inc	ax
	or	al,1			;let ax be odd
					;ax = dst length include bias
	call	int2floatbxax
	pop	ax			;*/ len(y)-bias(y)
	sub	ds:[resadr+2],ax	;set bias
idivFFret:
	ret
idivFFretpop:
	add	sp,2			;dummy
	ret


idiv_integer_float:
	mov	bx,di
	call	int2floatbxcurrent
	jmp	idiv_float_float

idiv_float_integer:
	mov	bx,si
	call	int2floatbxcurrent
	jmp	idiv_float_float


;
;* square float
;  [di] = [di]^2
;

farsquareFdi:
	call	squareFdi
	retf

squareFdi:
	mov	ax,[di]			;attribute
	mov	dx,[di+2]		;bias
;	mov	[di+2],ax
	and	ax,lenmask
	jz	sqFret			;if 0

	mov	[di],dx
	winc	di
	dec	ax
	push	dx			;bias
	push	ax			;length
	mov	[di],ax			;set attr as positive integer
	push	di			;base adr

	call	squareIdi

	pop	si
	lea	di,[si-2]
	pop	dx			;length
	pop	bx
	add	bx,bx			;new bias
	xor	ax,ax			;positive
	jmp	getfloat		;call & ret
sqFret:
	ret


;
; convert ax to float and set on [di]
; ax is treated as signed int
;

farfloatsetdiax:
	call	floatsetdiax
	retf


setfdiaxset0:
	mov	[di],ax
	ret

floatsetdiax:
	mov	dx,[pointword]
	mov	cx,dx
	inc	dx
	or	dx,pointmask
	or	ax,ax
	jz	setfdiaxset0
	jg	floatsetjp		;if positive
	neg	ax
	or	dh,signmaskhigh
floatsetjp:
	mov	[di],dx
	mov	dx,ax
	winc	di
	or	ah,ah
	jnz	setfdiaxword
setfdiaxbyte:
	mov	word ptr [di],1
	winc	di
	xor	ax,ax
	rep	stosw
	mov	[di-1],dl
	ret
setfdiaxword:
	mov	word ptr [di],2
	winc	di
	dec	cx
	xor	ax,ax
	rep	stosw
	mov	[di],dx
	ret


;
; factorial of floating number
; [di] = ax!

farfactorialFFdiax:
	call	factorialFFdiax
	retf

factorialFFdiax:
	or	ax,ax
	jnz	factdiax10
	inc	ax			;0! = 1!
factdiax10:
	push	ax
	push	di
	call	floatsetdiax		;set ax as a floating number
	pop	di
	pop	ax
	cmp	ax,2
	jbe	factdiaxret
factdiaxlp:
	dec	ax
	push	ax
	push	di
	call	floatmuldiax
	pop	di
	pop	ax
	cmp	ax,2
	ja	factdiaxlp
factdiaxret:
	ret


;
; power of floating number
; [di] = [di]^ax
; ax = unsigned int
; use stack 1 level

farpowerFCdiax:
	call	powerFCdiax
	retf

powerFCdiax:
	cmp	ax,1
	jb	powdiaxset1		;*^0 = 1.0
	jne	powdiax10
	ret				;if ^1
powdiaxset1:
	mov	ax,1
	jmp	floatsetdiax		;call & ret

powdiax10:
	call	ahedsp			;non use ax/di
	push	di
	xchg	si,di

	;new stk0 = x

	copy_si2di			;non use ax

	pop	di
	shr	ax,1
	jc	powdiax20

	push	di
	push	ax
	mov	ax,1
	call	floatsetdiax
	pop	ax
	pop	di

powdiax20:
	or	ax,ax
	jnz	powdiax30
	add	[calcsp],unitbyte
	ret

powdiax30:
	push	ax
	push	di
	mov	di,[calcsp]
	call	squareIFCdi
	pop	di
	pop	ax

	shr	ax,1
	jnc	powdiax20

	push	ax
	push	di
	mov	si,[calcsp]
	call	mulAAdisi
	pop	di
	pop	ax
	jmp	powdiax20


;
; [di] = 1 / [di]
; [di] must be float
; use resadr

inverseFdi:
	push	di
	copyF	di,work2	;work2 = x

	pop	di
	push	di
	mov	ax,1
	call	floatsetdiax	;stack0 = 1.0

	pop	di
	mov	si,work2
	jmp	divIorFdisi	;call & ret


pointascin:
;	jmp	far ptr farfixedascin
	jmp	far ptr farfloatascin


;jump table for add & sub

add_integer_float:
	jmp	far ptr add_integer_float3
add_float_integer:
	jmp	far ptr add_float_integer3
add_float_float:
	jmp	far ptr add_float_float3
add_float_rational:
	jmp	far ptr add_float_rational3
add_rational_float:
	jmp	far ptr add_rational_float3


farsubFFdisi:
	call	subFFdisi
	retf

subFFdisi:
	mov	ax,[si]
	or	ax,ax
	jz	addFFskip
	xor	ax,signmask
	push	si
	mov	[si],ax
	call	addFFdisi
	pop	si
	xor	word ptr [si],signmask	;restore sign
subFFdisiret:
	ret


faraddFFdisi:
	call	addFFdisi
	retf

addFFcopy:
	copy_si2di
addFFskip:
	ret

addFFdisi:
	xor	ax,ax
	cmp	[si],ax
	je	addFFskip
	cmp	[di],ax
	je	addFFcopy
	jmp	far ptr add_float_float3


code	ends


code2	segment	public
	assume	cs:code2,ds:data

	public	prfloatnormalize,using4float
	public	farmulFFsub

	extrn	LLMULfast:far

;
;* float to ascii
;  jumped from BINASC
;  data is in di=WORK3

farfloatascin:

	;now es = seg of ascbuf

	mov	[floatbias],0
	mov	ax,[di]
	and	ax,lenmask
	dec	ax
	mov	[thisfloatword],ax
	add	ax,ax
	mov	[thisfloatbyte],ax
	cmp	[schoolflg],0
	je	floatasc5
	mov	dx,ax
	jmps	floatasc7
floatasc5:
	my_shl	ax,2
	mov	dx,_floatdeciratio
	mul	dx
	sub	dx,3
floatasc7:
	mov	[thispointdeci],dx	;standard display digits

floatasc10:
	cmp	word ptr [di+2],0	;multiply 10000
	jg	floatasc20		;until >=1.0
	sub	[floatbias],4
	mov	ax,10000
	call	far ptr farfloatmuldiax
	jmp	floatasc10

floatasc20:
	mov	ax,[thisfloatbyte]	;div by 10000
	sub	ax,[di+2]
	jge	floatasc50		;until . inside
	cmp	ax,2
	jbe	floatasc30		;until 1 or 2 bytes over .
	add	[floatbias],4
	mov	ax,10000
	push	es
	smov	es,ds
	call	far ptr farfloatdivdiax
	pop	es
	jmp	floatasc20

floatasc30:
	mov	ax,[thisfloatbyte]	;div by 10
	sub	ax,[di+2]
	jge	floatasc50		;until . inside
	inc	[floatbias]
	mov	ax,10
	push	es
	smov	es,ds
	call	far ptr farfloatdivdiax
	pop	es
	jmp	floatasc30

floatasc50:
	;copy to mulwork

	smov	es,ds

	mov	bx,di		;memo base = work3
	copyF	di,mulwork

	;set int part

	lea	si,[bx+2]
	mov	di,si
	mov	cx,[si]		;bias
	mov	dx,cx		;memo bias

	add	si,[thisfloatbyte]
	winc	si		;MSB+1
	mov	ax,cx
	sub	si,cx		;base adr
	rep	movsb
	mov	[di],cl		;1 more 0
	inc	ax
	shr	ax,1
	mov	[bx],ax		;set length

	push	dx
	call	far ptr farbinasc	;transform this

	mov	di,[ascend]
	mov	ax,ss
	add	ax,ascbinseg
	mov	es,ax

	mov	al,'.'
	stosb

	;set frac part

	pop	cx		;byte length of int part
	mov	bx,work3

	mov	ax,[thisfloatbyte]
	sub	ax,cx
	jnz	floatascfrac
	mov	al,'0'
	stosb
	jmp	floatascnormalize

floatascfrac:
	push	es
	push	di
	smov	es,ds

	mov	dx,ax		;byte length of frac part
	mov	si,mulwork
	mov	di,bx
	movsw
	movsw
	xor	al,al
	rep	stosb
	mov	cx,dx
	rep	movsb

	pop	di
	pop	es

	mov	si,bx

	mov	dx,di
	sub	dx,ASCBUFTOP+1		;asclen of int part
	mov	cx,[thispointdeci]
	inc	cx			;1 more char
	sub	cx,dx
	jbe	floatascnormalize
	push	cx
	shr	cx,2
	jz	floatasc64
floatasc60:
	push	cx
	push	di
	mov	di,si
	mov	ax,10000
	push	si
	call	far ptr farfloatmulaxsub
	pop	si
	pop	di

	;store 4 digits

	xor	dx,dx
	mov	cx,1000
	div	cx
	add	al,'0'
	stosb
	mov	ax,dx
	xor	dx,dx
	mov	cx,100
	div	cx
	add	al,'0'
	stosb
	mov	ax,dx
	xor	dx,dx
	mov	cx,10
	div	cx
	add	al,'0'
	stosb
	mov	al,dl
	add	al,'0'
	stosb

	pop	cx
	myloop	floatasc60

floatasc64:
	pop	cx
	and	cx,3
	jz	floatascnormalize
floatasc66:
	push	cx
	push	di
	mov	di,si
	mov	ax,10
	push	si
	call	far ptr farfloatmulaxsub
	pop	si
	add	al,'0'
	pop	di
	stosb
	pop	cx
	myloop	floatasc66

floatascnormalize:
	dec	di
	push	di
	mov	cx,0ffffh
	mov	al,'.'
	std
	repne	scasb
	cld
	mov	si,di
	inc	di
	mov	cx,si
	sub	cx,ASCBUFTOP
	add	[floatbias],cx
	mov	dx,[floatbias]

	push	ds
	smov	ds,es
	std
	rep	movsb
	mov	byte ptr [di],'.'
	cld
	pop	ds
	pop	di

	mov	ax,[thispointdeci]
	add	ax,ASCBUFTOP+1
	cmp	ax,di
	jae	floatasc70
	mov	di,ax
floatasc70:
	mov	al,es:[di]		;last char
	cmp	al,'5'
	jb	floatascbias

	;round up

floatasc72:
	push	di
floatasc72lp:
	dec	di
	mov	al,es:[di]
	cmp	al,'.'
	je	floatasc74
	inc	al
	cmp	al,'9'
	jbe	floatasc73
	mov	byte ptr es:[di],'0'
	jmp	floatasc72lp
floatasc73:
	stosb
	pop	di
	jmps	floatascbias
floatasc74:
	inc	di
	mov	byte ptr es:[di],'0'
	inc	di
	mov	al,es:[di-3]
	cmp	al,'9'
	je	floatasc76
	inc	al
	mov	es:[di-3],al
	pop	di
	jmps	floatascbias

floatasc76:
	mov	byte ptr es:[di-3],'1'	;9.999... to  1.0e+1
	inc	[floatbias]		;
	pop	di

floatascbias:
	mov	ax,'+e'
	mov	bx,[floatbias]
	stosw
	or	bx,bx
	jge	floatasc90
	mov	byte ptr es:[di-1],'-'
	neg	bx
floatasc90:
	call	ascbx
floatasc100:
	jmp	far ptr binascret


prfloatnormalize:
	; now ds=es = ascbinseg

	mov	di,ss:[ascend]
	mov	al,'e'
prfnormlp:
	dec	di
	cmp	[di],al
	jne	prfnormlp

	;now di is on 'e'

	mov	bx,ss:[floatbias]
	or	bx,bx
	jg	prfnormplus
	jl	prfnormminus

prfnorm20:
	dec	di			;cut 0 and e...
	std				;
	mov	cx,0ffffh		;
	mov	al,'0'
	repe	scasb
	cld
	add	di,2
	cmp	byte ptr [di-1],'.'
	jne	prfnorm30
	inc	di
prfnorm30:
	mov	byte ptr [di],0		;end mark
	mov	ss:[ascend],di		;end point
	retf

prfnormplus:
	mov	cx,ss:[thispointdeci]
	dec	cx
	cmp	bx,cx
	jae	prfnorm50
	push	di
	mov	di,ASCBUFTOP+1
	lea	si,[di+1]
	mov	cx,bx
	rep	movsb
	mov	byte ptr [di],'.'
	pop	di
	jmp	prfnorm20
prfnorm50:
	mov	si,di			;si is on 'e'
	dec	di
	mov	al,'0'
	mov	cx,0ffffh
	std
	repe	scasb
	cld
	add	di,2
	cmp	byte ptr [di-1],'.'
	jne	prfnorm60
	inc	di
prfnorm60:
	mov	cx,ss:[ascend]
	sub	cx,si
	rep	movsb
	jmp	prfnorm30

prfnormminus:
	push	di
	dec	di
	mov	al,'0'
	mov	cx,bx
	neg	cx
	std
	repe	scasb
	cld
	mov	si,di
	pop	di
	jne	prfnorm50		;not enough '0'

	mov	cx,ss:[thispointdeci]
	push	di

	dec	di
	add	cx,bx
	dec	cx
	std
	rep	movsb
	dec	si
	movsb
	mov	al,'0'
	mov	cx,bx
	neg	cx
	dec	cx
	rep	stosb
	mov	al,'.'
	stosb
	cld
	mov	byte ptr [di],'0'
	pop	di
	jmp	prfnorm20


using4float:
	; now ds=es = ascbinseg

	mov	cx,ss:[using_frac_part]
	mov	di,ss:[ascend]
;	or	cx,cx
;	jge	using4fixed
	cmp	cx,-1
	jne	using4fixed

	;print using for float by exponential form

	mov	ax,ASCBUFTOP-1
	mov	cx,ss:[using_int_part]
	add	ax,cx
	cmp	ax,di
	je	usingfret
	jb	usingfcut
usingfextend:
	mov	cx,di
	inc	cx
	sub	cx,ASCBUFTOP
	mov	si,di
	mov	di,ax
	sub	ax,si
	std
	rep	movsb
	mov	cx,ax
	mov	al,' '
	rep	stosb
	cld
usingfret:
	retf

usingfcut:
	mov	dx,di
	sub	dx,ax		;cut dx bytes
	mov	al,'e'
	xor	cx,cx
usingfcutlp:
	inc	cx
	dec	di
	cmp	[di],al
	jne	usingfcutlp
	mov	si,di		;si=di on 'e'
	sub	di,dx
	cmp	di,ASCBUFTOP+3
	jae	usingfcut20
	mov	di,ASCBUFTOP+3
usingfcut20:
	mov	ah,[di]
	mov	dx,di		;memo
	rep	movsb
	xor	al,al
	stosb			;end mark
	cmp	ah,'5'
	jae	usingfcut30	;roundup
usingfcutret:
	jmp	usingfret
usingfcut30:
	xchg	di,dx
	dec	di
usingfcut40:
	mov	al,[di]
	cmp	al,'.'
	je	usingfcut50	;skip .
	inc	al
	mov	[di],al
	cmp	al,'9'
	jbe	usingfcutret
	mov	byte ptr [di],'0'
usingfcut50:
	dec	di
	cmp	di,ASCBUFTOP
	jae	usingfcut40
	inc	di
	mov	byte ptr [di],'1'	;make 1.0
	xor	al,al
	mov	cx,8000h
	mov	di,dx
	sub	di,2		;di is on last char
usingfcut60:
	mov	al,[di]
	cmp	al,'+'
	je	usingfcut70
	cmp	al,'-'
	je	usingfcut70
	inc	al
	mov	[di],al
	cmp	al,'9'
	jbe	usingfcutret
	mov	byte ptr [di],'0'
	dec	di
	jmp	usingfcut60
usingfcut70:
	mov	ah,'1'
	cmp	byte ptr [di-3],'.'	;if no fractional digit
	je	usingfcut80
	mov	[di-1],ax
	mov	byte ptr [di-2],'e'
	retf
usingfcut80:
	inc	di
	xchg	ah,[di]
	or	ah,ah
	jnz	usingfcut80
	mov	[di+1],ah		;end mark
	retf

using4fixedlong:
	mov	di,ASCBUFTOP
	mov	cx,ss:[using_int_part]
	add	cx,ss:[using_frac_part]
	dec	cx
	cmp	cx,ASCBUFEND-ASCBUFTOP-3
	jbe	using4fixedlong10
	mov	cx,ASCBUFEND-ASCBUFTOP-3
using4fixedlong10:
	mov	al,'?'
	stosb
	mov	al,'-'
	rep	stosb
	xor	al,al
	stosb
	retf

using4fixed:
	mov	cx,ss:[floatbias]
	mov	dx,ss:[using_int_part]
	cmp	dx,-1
	je	using4fixed10		;int part as is
	inc	cx
	cmp	cx,dx
	jge	using4fixedlong
	dec	cx
	cmp	cx,ASCBUFEND-ASCBUFTOP-2
	jg	using4fixedlong
	or	cx,cx
	jge	using4fixed10
	neg	cx
	add	cx,di
	cmp	cx,ASCBUFEND-2
	jg	using4fixedlong

using4fixed10:
	mov	al,'e'
using4fixed20:
	dec	di
	cmp	[di],al
	jne	using4fixed20

	;normalize to .1234... (start from .)

	mov	si,ASCBUFTOP
	mov	ax,[si]
	xchg	al,ah
	mov	[si],ax

	mov	cx,ss:[floatbias]
	add	cx,1
	jle	using4fixed_lt1		;< 1.0

	mov	si,ASCBUFTOP+1
	add	si,cx
	cmp	di,si
	ja	using4fixed50		;. is inside

	; xxxxx0000.00000 case

	push	cx
	mov	al,'0'
	mov	cx,si
	sub	cx,di
	rep	stosb
	pop	cx
	mov	si,ASCBUFTOP+1
	mov	di,ASCBUFTOP
	rep	movsb
	mov	al,'.'
	stosb
	mov	cx,ss:[using_frac_part]
	mov	al,'0'
	rep	stosb
	jmps	using4fixed100

using4fixed50:
	push	di
	mov	si,ASCBUFTOP+1
	mov	di,ASCBUFTOP
	rep	movsb
	mov	al,'.'
	stosb
	mov	si,di
	pop	di
	cmp	si,di
	jne	using4fixed60
	mov	al,'0'
	stosb
using4fixed60:
	mov	cx,si
	add	cx,ss:[using_frac_part]
	sub	cx,di
	jbe	using4fixed70
	mov	al,'0'
	rep	stosb
	jmp	using4fixed100
using4fixed70:
	add	di,cx
	jcxz	using4fixed100		;if no cut
	cmp	byte ptr [di],'5'
	jb	using4fixed100		;no round up

	mov	byte ptr [di],0		;end mark
	mov	si,di			;memo end point
	dec	di
using4fixed80:
	mov	al,[di]
	cmp	al,'.'
	je	using4fixed85
	inc	al
	mov	[di],al
	cmp	al,'9'
	jbe	using4fixed110
	mov	byte ptr [di],'0'
using4fixed85:
	dec	di
	cmp	di,ASCBUFTOP
	jae	using4fixed80

	lea	di,[si+1]
	mov	dx,di			;memo
	mov	cx,di
	sub	cx,ASCBUFTOP
	std
	rep	movsb
	mov	byte ptr [di],'1'
	cld
	mov	di,dx
	mov	si,dx
	jmp	using4fixed110


gousing4fixedlong:
	jmp	using4fixedlong

using4fixed100:
	mov	byte ptr [di],0		;end mark
	mov	si,di			;memo end point
using4fixed110:
	mov	di,ASCBUFTOP
	mov	al,'.'
	mov	cx,0ffffh
	repne	scasb
	dec	di			;di is at '.'
	mov	ax,di
	sub	ax,ASCBUFTOP-1		;ax = length of int_part
	mov	cx,ss:[using_int_part]
	or	cx,cx
	jle	using4fixret		;if int_part is not assigned
	sub	cx,ax
	je	using4fixret
	jb	gousing4fixedlong	;if int_part is longer
	push	cx

	;slide right and make cx spaces

	mov	di,si			;di=si is at 0=end mark
	add	di,cx
	mov	cx,si
	sub	cx,ASCBUFTOP
	inc	cx
	mov	ax,di
	add	ax,cx
	sub	ax,ASCBUFEND-2
	jbe	usingffix15
	sub	cx,ax
usingffix15:
	std
	rep	movsb
	pop	cx
	cmp	byte ptr [di+1],'.'
	jne	using4fix20		;if fractional part exists
	dec	cx			;if no fractional part
	mov	al,'0'
	stosb
using4fix20:
	mov	al,ds:[ASCBUFTOP-1]	;sign
	stosb
	mov	al,' '
	rep	stosb
	cld
using4fixret:
	mov	di,ASCBUFTOP
	xor	al,al
	mov	cx,8000h
	repne	scasb		;search end mark
	sub	di,2
	cmp	byte ptr [di],'.'
	jne	using4fixout
	mov	byte ptr [di],0	;cut last '.'
using4fixout:
	retf


using4fixed_lt1:
	neg	cx
	mov	dx,ss:[using_frac_part]
	cmp	cx,dx
	ja	using4flt1all0

	push	cx
	mov	cx,ASCBUFTOP+1
	add	cx,dx
	mov	si,cx
	sub	cx,di
	jbe	using4flt120
	mov	al,'0'
	rep	stosb		;append '0'
	xor	al,al
	stosb
using4flt120:
	mov	di,si		;si=di adr of new end
	pop	dx		;dx = bias
	push	si

	sub	si,dx
	mov	cx,si
	sub	cx,ASCBUFTOP
	std
	rep	movsb		;slide right
	mov	cx,dx
	mov	al,'0'
	rep	stosb		;and fill left by '0'
	mov	al,'.'
	stosb
	cld

	pop	di		;adr of last char + 1
	lea	si,[di-1]
	mov	ah,[di]		;char to cut
	push	di
	mov	cx,si
	sub	cx,ASCBUFTOP-1
	std
	rep	movsb
	cld
	mov	byte ptr [di],'0'
	pop	si
	lea	di,[si+1]
	cmp	ah,'5'
	jb	using4flt1100
using4flt150:
	mov	al,[si]
	cmp	al,'.'
	je	using4flt160
	inc	al
	mov	[si],al
	cmp	al,'9'
	jbe	using4flt1100
	mov	byte ptr [si],'0'
using4flt160:
	dec	si
	cmp	si,ASCBUFTOP
	jae	using4flt150
using4flt1100:
	jmp	using4fixed100

using4flt1all0:
	mov	cx,dx
	mov	di,ASCBUFTOP
	mov	ax,'.0'
	stosw
	rep	stosb
	jmp	using4fixed100


ascbx:
	;inp : bx
	;out : es;di-> ascii image

	xor	si,si		;flag for 0 suppless
	mov	ax,bx
	mov	bx,10000
	mov	cx,4
ascbxlp:
	xor	dx,dx
	div	bx
	push	dx
	add	si,ax
	jz	ascbxjp
	add	al,'0'
	stosb
ascbxjp:
	mov	ax,bx
	xor	dx,dx
	mov	bx,10
	div	bx
	mov	bx,ax
	pop	ax
	myloop	ascbxlp

	add	al,'0'
	stosb
	ret

;
; subroutine for multiplication
;

mulFFsubover:
	jmp	far ptr ovrerr


farmulFFsub:
	;assume floating numbers have even word length

	cmp	cx,bx
	je	mulFF20
	ja	mulFF10
	xchg	cx,bx
	xchg	di,si
mulFF10:
	sub	cx,bx
	add	cx,cx
	add	di,cx
	mov	cx,bx
mulFF20:
	mov	[dilen_m],cx
	mov	[silen_m],bx

	mov	[dimem_m],di
	mov	[simem_m],si

	mov	ax,bx
	add	ax,cx
	mov	ds:[MULWORK],ax		;total words

	cmp	cx,LLMULswitchlen*2
	jbe	mulFFshort
;	cmp	bx,LLMULswitchlen*2
;	jbe	mulFFshort

mulFFLong:
	call	far ptr LLMULfast
	mov	di,MULWORK+2
	set32
	rep	movsw
	mov	ax,data
	mov	ds,ax
	retf

mulFFshort:
	push	bp

	shr	ax,1
	mov	cx,ax
	mov	di,MULWORK+2
	set32
	xor	ax,ax
	set32
	rep	stosw		;clear result

	mov	di,[dimem_m]
	mov	cx,[dilen_m]
	mov	bx,MULWORK+2
	shr	cx,1
mulFFshort10:
	set32
	mov	bp,[di]
	qinc	di
	set32
	or	bp,bp
	jz	mulFFshort60

	push	cx
	push	bx
	mov	si,[simem_m]
	mov	cx,[silen_m]
	shr	cx,1
mulFFshort20:
	mylodsd
	set32
	mul	bp
	set32
	add	[bx],ax
	qinc	bx
	set32
	adc	[bx],dx
	jc	mulFFshort110
mulFFshort50:
	dec	cx
	jnz	mulFFshort20

	pop	bx
	pop	cx

mulFFshort60:
	qinc	bx
	dec	cx
	jnz	mulFFshort10

	pop	bp
	retf


mulFFshort110:
	mov	dx,bx		;push	bx
	set32
	xor	ax,ax
	stc
mulFFshort130:
	qinc	bx
	set32
	adc	[bx],ax		;eax = 0
	jc	mulFFshort130
	mov	bx,dx		;pop	bx
	jmp	mulFFshort50


code2	ends


code3	segment	public
	assume	ds:data,cs:code3



comment %

r2f4addret:
	ret

	align	4
rat2float4add:
	mov	cx,[di]
	and	cx,lenmask
	jz	r2f4addret	;if 0 do nothing

	mov	dx,[si]
	mov	ax,[si+2]	;bias of [si]
	and	dx,lenmask
	dec	dx
	add	dx,dx		;byte length
	sub	ax,dx		;bias of minimum byte
				;=0 <-> just integer

	jl	r2f4addfraction

	mov	bx,di		;no fractional part
//	call	far ptr farint2floatbx
	ret

r2f4addover:
	jmp	far ptr ovrerr

r2f4addfraction:
	neg	ax
	mov	dx,ax
	mov	bx,di
	mov	ax,cx
	add	ax,ax
	add	bx,ax
	inc	bx
	cmp	byte ptr [bx],0	;highest byte
	jne	r2f4add110
	dec	bx
	dec	ax
r2f4add110:
	push	ax		;new bias

	add	ax,dx
	jc	r2f4addover
	add	ax,3
	jc	r2f4addover
	and	ax,0fffch	;must be a multiple of 4
	mov	dx,ax		;total byte length

	shr	ax,1
	inc	ax		;for bias
	cmp	ax,limitword
	jg	r2f4addover

	pop	cx		;new bias
	push	cx

	mov	di,bx
	xchg	si,bx
	add	di,dx
	sub	di,cx
	add	di,2		;for bias
	std
	rep	movsb		;slide up
	mov	si,bx		;restore si
	pop	bx		;new bias
	xor	al,al
	mov	cx,dx
	sub	cx,bx
	rep	stosb		;fill lower by 0

	dec	di
	mov	ax,bx
	stosw			;set bias
	cld

	mov	cx,[di]		;old attribute
	and	ch,lenmaskhighcpl
	or	ch,pointmaskhigh
	shr	dx,1
	inc	dx
	or	dh,ch
	mov	[di],dx		;new attribute
	ret
%


; convert int to float
;	inp di:adr of int
;	    si:adr of float
;	reserve di,si
;	result = so that the least byte of [si] has meaning
;	         and total words must be even

i2f4addret:
	ret

	align	4
int2float4add:
	mov	cx,[di]
	and	cx,lenmask
	jz	i2f4addret	;if 0 do nothing

	mov	dx,[si]
	mov	ax,[si+2]	;bias of [si]
	and	dx,lenmask
	dec	dx
	add	dx,dx		;byte length
	sub	ax,dx		;bias of minimum byte
				;=0 <-> just integer

	jl	i2f4addfraction

	mov	bx,di		;no fractional part
	call	far ptr farint2floatbx
	ret

i2f4addover:
	jmp	far ptr ovrerr

i2f4addfraction:
	neg	ax
	mov	dx,ax
	mov	bx,di
	mov	ax,cx
	add	ax,ax
	add	bx,ax
	inc	bx
	cmp	byte ptr [bx],0	;highest byte
	jne	i2f4add110
	dec	bx
	dec	ax
i2f4add110:
	push	ax		;new bias

	add	ax,dx
	jc	i2f4addover
	add	ax,3
	jc	i2f4addover
	and	ax,0fffch	;must be a multiple of 4
	mov	dx,ax		;total byte length

	shr	ax,1
	inc	ax		;for bias
	cmp	ax,limitword
	jg	i2f4addover

	pop	cx		;new bias
	push	cx

	mov	di,bx
	xchg	si,bx
	add	di,dx
	sub	di,cx
	add	di,2		;for bias
	std
	rep	movsb		;slide up
	mov	si,bx		;restore si
	pop	bx		;new bias
	xor	al,al
	mov	cx,dx
	sub	cx,bx
	rep	stosb		;fill lower by 0

	dec	di
	mov	ax,bx
	stosw			;set bias
	cld

	mov	cx,[di]		;old attribute
	and	ch,lenmaskhighcpl
	or	ch,pointmaskhigh
	shr	dx,1
	inc	dx
	or	dh,ch
	mov	[di],dx		;new attribute
	ret


align	4
add_float_integer3:
	mov	dx,[si]
	or	dx,dx
	jz	addIFret
	xchg	si,di
	call	int2float4add
	xchg	si,di
	jmp	add_float_float3

align	4
add_integer_float3:
	cmp	word ptr [di],0
	je	addIFcopy
	call	int2float4add
	jmp	add_float_float3
addIFcopy:
	copy_si2di
addIFret:
	jmp	far ptr returnadr


add_float_rational3:
	mov	ax,[di]
	mov	dx,[di+2]
	mov	bx,si
	call	far ptr farrat2float4add
	jmp	add_float_float3

add_rational_float3:
	mov	ax,[si]
	mov	dx,[si+2]
	mov	bx,di
	call	far ptr farrat2float4add
	jmp	add_float_float3


;
;* addition of float & float
;  [di] += [si]
;  [si] is reserved
;  use mulwork


add_float_float3:
	mov	ax,[di]
	xor	ax,[si]
	and	ax,signmask
	jnz	subFFin3

addFFin3:
	mov	bx,di		;result adr

	mov	ax,[di+2]	;compare bias
	cmp	ax,[si+2]
	jl	addFFsibigger
	jg	addFFdibigger
addFFequalbias:
	mov	cx,[di]
	mov	dx,[si]
	and	cx,lenmask
	and	dx,lenmask
	cmp	cx,dx
	jae	addFFdibigger	;take longer for base

addFFsibigger:
	;* if [si] > [di]

	xchg	di,si

addFFdibigger:
	;* if [di] >= [si]

	mov	cx,[di]
	mov	dx,[si]
	mov	[bx],cx	;set attribute
	and	cx,lenmask
	and	dx,lenmask
	dec	cx
	dec	dx
	add	cx,cx
	add	dx,dx

	push	dx
	mov	ax,[di+2]
	mov	dx,[si+2]
	mov	[bx+2],ax	;set bias
	sub	ax,dx		;ax = bias(di) - bias(si)
	pop	dx
	sub	cx,ax		;cx = len(di) - (bias(di) - bias(si))
	jbe	addFFretcopy	;no intersection

	lea	bx,[bx+4]
	lea	di,[di+4]
	lea	si,[si+4]
	cmp	cx,dx		;len(di)-len(si) - (bias(di)-bias(si)) > 0 ?
	jbe	addFFnormal

addFFinner:
	push	ax		;bias(di)-bias(si)

	mov	ax,cx
	sub	ax,dx
	mov	cx,ax
	and	ax,0fffch
	sub	cx,ax		;fill 0 by cx-bytes lower of [si]
	add	di,ax		;[di] starts here
	shr	ax,1
;//	add	[bx-4],ax	;change length of result
	sub	[bx-4],ax	;change length of result

	mov	ax,cx
	add	ax,dx		;new byte length of [si]
	push	ax

	push	si
	push	di
	add	si,dx
	dec	si		;MSB
	mov	di,si
	add	di,cx
	xchg	cx,dx
	std
	rep	movsb
	mov	cx,dx
	xor	ax,ax
	rep	stosb
	cld
	pop	di
	pop	si

	pop	cx
	pop	ax		;bias(di)-bias(si)
	jmps	addFFmain

addFFnormal:			;cut lower bytes of [si]
	sub	dx,cx		;dx = len(si)-len(di) - (bias(si)-bias(di))
				;cx = len(di) - (bias(di) - bias(si))
	add	si,dx		;[si] starts here
				;[di] starts normally

addFFmain:
	;inp ax = bias(di)-bias(si)
	;    di, si = source base adr
	;    bx = result adr
	;    cx = bytes for add

	push	bx

	mov	dx,ax		;higher bytes to copy
	mov	ax,cx

	and	ax,3
	shr	cx,2
	clc
	push	ax		;/*
	jcxz	addFF15
addFF10:
	set32
	mov	ax,[si]
	qinc	si
	set32
	adc	ax,[di]
	qinc	di
	set32
	mov	[bx],ax
	qinc	bx
	myloop	addFF10
addFF15:
	pop	cx		;*/
	jcxz	addFF17
addFF16:
	mov	al,[si]
	inc	si
	adc	al,[di]
	inc	di
	mov	[bx],al
	inc	bx
	myloop	addFF16
addFF17:
	mov	cx,dx
	jcxz	addFF22
addFF20:
	mov	al,[di]
	inc	di
	adc	al,0
	mov	[bx],al
	inc	bx
	dec	cx
	jnz	addFF20
addFF22:
	jc	addFFover	;no higer byte = overflow
	test	bl,1
	jnz	addFFunder
	add	sp,2
	jmp	far ptr returnadr

addFFunder:
	mov	byte ptr [bx],0
	pop	bx
	jmp	subFFnormalize

addFFover:
	mov	word ptr [bx],1	;may destory 1 more byte
	pop	bx
	call	far ptr farslide1	;needs bx = baseadr + 4
	jmp	far ptr returnadr

addFFretcopy:
	cmp	bx,di
	je	addFFnocopy
	mov	si,di		;copy [di] to [bx]
	mov	di,bx
	copy_si2di
addFFnocopy:
	jmp	far ptr returnadr




subFFretcopy:
	cmp	bx,di
	je	subFFnocopy
	mov	si,di		;copy [di] to [bx]
	mov	di,bx
	copy_si2di
subFFnocopy:
	jmp	far ptr returnadr


subFFin3:
	mov	bx,di		;result adr

	mov	ax,[di+2]	;compare bias
	cmp	ax,[si+2]
	jl	subFFsibigger
	jg	subFFdibigger
subFFequalbias:
	mov	cx,[di]
	mov	dx,[si]
	and	cx,lenmask
	and	dx,lenmask
	cmp	cx,dx
	jae	subFFdibigger	;take longer for base

subFFsibigger:
	;* if [si] > [di]

	xchg	di,si

subFFdibigger:
	;* if [di] >= [si]

	mov	cx,[di]
	mov	dx,[si]
	mov	[bx],cx		;set attribute
	and	cx,lenmask
	and	dx,lenmask
	dec	cx
	dec	dx
	add	cx,cx
	add	dx,dx

	push	dx
	mov	ax,[di+2]
	mov	dx,[si+2]
	mov	[bx+2],ax	;set bias
	sub	ax,dx		;ax = bias(di) - bias(si)
	pop	dx
	sub	cx,ax		;cx = len(di) - (bias(di) - bias(si))
	jbe	subFFretcopy	;no intersection

	lea	bx,[bx+4]
	lea	di,[di+4]
	lea	si,[si+4]
	cmp	cx,dx		;len(di)-len(si) - (bias(di)-bias(si)) > 0?
	jbe	subFFnormal

subFFinner:
	push	ax		;bias(di)-bias(si)

	mov	ax,cx
	sub	ax,dx
	mov	cx,ax
	and	ax,0fffch
	sub	cx,ax		;fill 0 by cx-bytes lower of [si]
	add	di,ax		;[di] starts here
	shr	ax,1
;//	add	[bx-4],ax	;change length of result
	sub	[bx-4],ax	;change length of result

	mov	ax,cx
	add	ax,dx		;new byte length of [si]
	push	ax

	push	si
	push	di
	add	si,dx
	dec	si		;MSB
	mov	di,si
	add	di,cx
	xchg	cx,dx
	std
	rep	movsb
	mov	cx,dx
	xor	ax,ax
	rep	stosb
	cld
	pop	di
	pop	si

	pop	cx
	pop	ax		;bias(di)-bias(si)
	jmps	subFFmain

subFFnormal:			;cut lower bytes of [si]
	sub	dx,cx		;dx = len(si)-len(di) - (bias(si)-bias(di))
				;cx = len(di) - (bias(di) - bias(si))
	add	si,dx		;[si] starts here
				;[di] starts normally

subFFmain:
	;inp ax = bias(di)-bias(si)
	;    di, si = source adr
	;    bx = result adr
	;    cx = bytes for subtract

	push	bx

	mov	dx,ax		;higher bytes to copy
	mov	ax,cx

	and	ax,3
	shr	cx,2
	clc
	push	ax		;/*
	jcxz	subFF15
subFF10:
	set32
	mov	ax,[di]
	qinc	di
	set32
	sbb	ax,[si]
	qinc	si
	set32
	mov	[bx],ax
	qinc	bx
	myloop	subFF10
subFF15:
	pop	cx		;*/
	jcxz	subFF17
subFF16:
	mov	al,[di]
	inc	di
	sbb	al,[si]
	inc	si
	mov	[bx],al
	inc	bx
	myloop	subFF16
subFF17:

	mov	cx,dx
	jcxz	subFF22
subFF20:
	mov	al,[di]
	inc	di
	sbb	al,0
	mov	[bx],al
	inc	bx
	dec	cx
	jnz	subFF20
subFF22:
	jc	subFFnegative	;no higer byte = oversubtraction

subFFnormalize:
	;decide length and normalize
	;bx = base adr + 4

	pop	bx

subFFnormalizein:
	mov	cx,[bx-4]
	and	cx,lenmask	;//03/11/16
	dec	cx		;//
	mov	di,bx
	add	cx,cx
	add	di,cx
	xor	al,al
	dec	di		;MSB
	cmp	[di],al		;check MSB
	jne	subFFret	;same as before, already normal

	push	di		;/*
	dec	cx
	dec	di
	mov	dx,cx
	std
	repe	scasb
	cld
	je	subFFset0pop	;all 0 must pop
	inc	di		;non zero top
	inc	cx		;number of non zero bytes
	mov	si,di
	sub	dx,cx
	inc	dx		;number of higher 0
	pop	di		;*/

	mov	ax,[bx-2]	;bias
	sub	ax,dx
	cmp	ax,floatbiasunder
	jl	subFFset0

	mov	[bx-2],ax	;new bias
	mov	ax,dx
	and	dx,3
	and	ax,0fffch
	sub	di,ax		;new top
	shr	ax,1
	sub	[bx-4],ax	;new attribute
	std
	rep	movsb		;slide up
	mov	cx,dx
	xor	al,al
	rep	stosb		;fill lower by 0
	cld
subFFret:
	jmp	far ptr returnadr

subFFset0pop:
	add	sp,2		;dummy pop
subFFset0:
	mov	word ptr [bx-4],0
	jmp	far ptr returnadr

subFFnegative:
	pop	bx

	mov	di,bx
	mov	cx,[bx-4]
	and	cx,lenmask
	dec	cx
	mov	dx,cx		;memo
	clc
subFFneglp:
	mov	ax,0
	sbb	ax,[di]
	mov	[di],ax
	winc	di
	myloop	subFFneglp
	xor	word ptr [bx-4],signmask	;change sign
	jmp	subFFnormalizein


code3	ends
