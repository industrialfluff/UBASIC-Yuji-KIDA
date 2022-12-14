;func4.asm

data	segment	public
	assume	ds:data

fpointbyte	dw	?
fdivnum		dw	?
fdivstep	dw	?
fdiv1		dw	?
fdiv2		dw	?
fsign		db	?
fsignnow	db	?
freserve	db	?
data	ends


code	segment	word public
	assume	cs:code, ds:data

	public	exp_ent
	public	farfuncset

	extrn	inverseFdi:near
	extrn	justlengthFdi:near,normalizeFdi:near,roundupF:near
	extrn	div_integer_float:near
	extrn	real2floatbxjust:near,real2float0:near
	extrn	farall2float0:far
	extrn	farpush_calcstack:far,farpop_calcstack:far
	extrn	divAAdisi:near,fardivAAdisi:far

;
;* convert int/float/complex parameter to float
;

farfuncset:
	call	funcsetall
	retf

funcsetall:
	mov	si,[calcsp]
	mov	ax,[si]
	and	ax,attribmask
	jz	ffset10
	cmp	ax,pointmask
	je	ffsetret
	cmp	ax,ratmask
	je	ffset10
	cmp	ax,complexmask
	je	ffsetcomplex
	jmp	ilgerr
ffset10:
	call	real2float0
	mov	si,[calcsp]
ffsetret:
	mov	ax,[si]
	ret
ffsetcomplex:
	setsp0	si
	copyimagsi	work2
	setsp0	di
	lea	si,[di+2]
	copy_si2di
	setsp0	bx
	call	real2floatbxjust
	mov	bx,work2
	call	real2floatbxjust
	mov	bx,[calcsp]
	mov	si,bx
	mov	di,work2
	jmp	setcomplex	;call & ret


;
;  SIN(X)
;

farsin_ent:
	call	sin_ent
	retf

sinilgerr:
	jmp	ilgerr
gosincomplex:
	jmp	sincomplex

sinin:
	call	kakko
sin_ent:
	mov	si,[calcsp]
	lodsw
	test	ah,nonnumericmaskhigh
	jnz	sinilgerr
	test	ah,complexmaskhigh
	jnz	gosincomplex

	call	real2float0
	mov	si,[calcsp]
	mov	ax,[si]
	mov	[cosflg],0	;not cosin
	mov	cx,ax
	and	ah,signmaskhigh
	mov	[sgnmem_f],ah
	and	cx,lenmask
	jz	sinret

	call	makeltpi4F	;make <pi/4 or <1
				;also set in work2
	test	[cosflg],80h
	jnz	cos10

sin10:
	copyF	[calcsp],work3

	mov	di,work3	;work3 = x^2
	call	squareFdi

	mov	di,work2	;work2 = x^3
	mov	si,work3
	call	mulFFdisi

	mov	[fdivnum],2
	mov	[fdivstep],2
	mov	[fdiv1],3
	mov	[fdiv2],2
	mov	[fsign],80h
	mov	[fsignnow],80h
	mov	[freserve],0
	call	far ptr farseries
sinsetsign:
	mov	si,[calcsp]
	mov	ax,[si]
	or	ax,ax
	jz	sinret
	xor	ah,[sgnmem_f]
	mov	[si],ax
sinret:
	ret


;
;  COS(X)
;

farcos_ent:
	call	cos_ent
	retf
cosilgerr:
	jmp	ilgerr
gocoscomplex:
	jmp	coscomplex

cosin:
	call	kakko
cos_ent:
	mov	si,[calcsp]
	lodsw
	test	ah,nonnumericmaskhigh
	jnz	cosilgerr
	test	ah,complexmaskhigh
	jnz	gocoscomplex

	call	real2float0
	mov	si,[calcsp]
	mov	ax,[si]
	mov	[cosflg],80h
	and	ax,signmaskCPL
	mov	[sgnmem_f],0
	mov	[si],ax		;make positive
	jz	cosset1		;ans = 1 if x = 0

	call	makeltpi4F	;make x < pi/4 or 1
				;also set in work2
	test	[cosflg],80h
	jz	sin10

cos10:
	mov	di,work2
	call	squareFdi

	copyF	work2,work3	;work3 = x^2

	mov	di,work2
	mov	ax,2
	call	floatdivdiax	;work2 = x^2/2

	mov	si,work2
	mov	di,[calcsp]
	mov	cx,[si]
	jcxz	cossetPM1		;ans = +-1 if x^2/2 = 0
	xor	ch,signmaskhigh
	mov	[di],cx
	add	si,2
	add	di,2
	and	cx,lenmask
	rep	movsw		;st0 = -x^2/2

	mov	di,work2
	mov	si,work3
	call	mulFFdisi	;work2 = x^4/2

	mov	[fdivnum],2
	mov	[fdivstep],2
	mov	[fdiv1],4
	mov	[fdiv2],3
	mov	[fsign],80h
	mov	[fsignnow],0
	mov	[freserve],0
	call	far ptr farseries

	;add 1.0 last to keep samll values have meaning

	setsp1	di		;st1 = 1.0
	mov	ax,1
	call	floatsetdiax

	mov	di,[calcsp]
	lea	si,[di-unitbyte]
	call	addFFdisi

	jmp	sinsetsign

cosset1:
	mov	ax,1
gocosset1:
	mov	di,[calcsp]	;ans = 1.0
	jmp	floatsetdiax	;call & ret

cossetPM1:
	test	[sgnmem_f],80h
	jz	cosset1
	mov	ax,-1
	jmp	gocosset1

;
;
;

	;< PI/4 or < 1.0 ‚É‚·‚é

makeltilgerr:
	jmp	floaterr


makeltpi4F:

	;x < 1.0 ?

	mov	ax,[bx]
	or	ax,ax
	jz	mkltpi100		;if = 0
	and	ax,signmaskCPL
	mov	[bx],ax			;make positive
	cmp	word ptr [bx+2],0
	jle	mkltpi100		;if < 1.0

	;x = x - int(x/pi)*pi

	and	ax,lenmask
	add	ax,ax
	sub	ax,3
	sub	ax,[bx+2]
	jbe	makeltilgerr

	mov	si,work2
	call	pai10

	mov	di,[calcsp]
	mov	si,work2
	call	idivFFdisi
	mov	di,[calcsp]
	cmp	word ptr [di],0
	je	mkltpi10		;if quot = 0
	test	word ptr [di+2],1
	jz	mkltpi10		;if quot = even
	xor	[sgnmem_F],signmaskhigh
mkltpi10:
	mov	si,resadr
	copy_si2di

	;work2 = pi/2

	mov	di,work2
	mov	ax,2
	call	floatdivdiax
;	mov	di,work2
;	call	justlengthFdi

	;x < pi/2 ?

	mov	di,[calcsp]
	mov	si,work2
	call	compFFdisi
	cmp	al,4
	je	mkltpi50

	;x = x - pi/2

	mov	di,[calcsp]
	mov	si,work2
	call	subFFdisi

	xor	[cosflg],80h		;change sin <-> cos
	jnz	mkltpi50
	xor	[sgnmem_f],80h		;change sign
mkltpi50:
	;now x < pi/2

	;x < 1 ?

	mov	si,[calcsp]
	cmp	word ptr [si],0
	je	mkltpi100		;if = 0
	cmp	word ptr [si+2],0
	jle	mkltpi100		;if < 1.0

	;work2 = pi/4

	mov	di,work2
	mov	ax,2
	call	floatdivdiax

	;x < pi/4 ?

	mov	di,[calcsp]
	mov	si,work2
	call	compFFdisi
	cmp	al,4
	je	mkltpi100

	;work2 = work2*2 = pi/2

	mov	di,work2
	mov	ax,2
	call	floatmuldiax

	;x = pi/2 - x

	mov	di,[calcsp]
	mov	si,work2
	xor	word ptr [di],signmask	;make negative
	call	addFFdisi

	xor	[cosflg],80h		;sin <-> cos

mkltpi100:
;	mov	di,[calcsp]
;	call	justlengthFdi

	copyF	[calcsp],work2		;also copy to work2
	ret


tanilgerr:
	jmp	ilgerr
;gotancomplex:
;	jmp	tancomplex

tanin:
	call	kakko
tan_ent:
	mov	si,[calcsp]
	lodsw
	test	ah,nonnumericmaskhigh
	jnz	tanilgerr
	test	ah,complexmaskhigh
	jnz	tanmain			;gotancomplex

	call	real2float0
	mov	si,[calcsp]

	;x < 1 ?

	cmp	word ptr [si],0
	je	tanmain			;if = 0
	cmp	word ptr [si+2],0
	jle	tanmain			;if < 1.0

	;x = x - int(x/pi)*pi

	mov	si,work2
;	call	pai10longer			;get pi
	call	pai10

	mov	di,[calcsp]
	mov	si,work2
	call	idivFFdisi
	mov	di,[calcsp]
	mov	si,resadr
	copy_si2di

	;calc sine and cosine
tanmain:
	call	ahedsp
	mov	di,si
	add	si,unitbyte
	copy_si2di

	call	sin_ent

	;swap work

	mov	si,[calcsp]
	lea	di,[si+unitbyte]
	mov	cx,[si]
	and	cx,lenmask
	inc	cx
tan50:
	mov	ax,[si]
	mov	dx,[di]
	mov	[di],ax
	mov	[si],dx
	winc	si
	winc	di
	myloop	tan50

	call	cos_ent

	mov	si,[calcsp]
	lea	di,[si+unitbyte]
	mov	[calcsp],di
	jmp	divAAdisi		;call & ret


;
; log(x) for real number x
;
; use work2, work3, work4, mulwork

	even
logbiasbyte	dw	?
logbiasbit	dw	?


logilgerr:
	jmp	ilgerr
gologcomplex:
	jmp	logcomplex
golognegative:
	jmp	lognegative

login:
	call	kakko
log_ent:
	mov	si,[calcsp]
	mov	ah,[si+1]
	test	ah,nonnumericmaskhigh
	jnz	logilgerr
	test	ah,complexmaskhigh
	jnz	gologcomplex
	test	ah,signmaskhigh
	jnz	golognegative		;if negative real

logreal:
	call	real2float0
	mov	si,[calcsp]
	mov	ax,[si]

	;get N s.t. (2^N<= X <2^(N+1))
	; and make 1.0<= X <2.0

	test	ah,signmaskhigh
	jnz	logilgerr		;arg must > 0
	and	ax,lenmask
	jz	logilgerr		;arg must > 0

	mov	dx,[si+2]
	dec	dx
	mov	[logbiasbyte],dx	;may be < 0
	mov	[logbiasbit],0
	mov	word ptr [si+2],1	;256.0> >=1.0

	mov	di,si
	add	si,ax
	add	si,ax
	mov	ah,[si+1]	;integer part
	cmp	ah,1
	je	log50		;already normal

	mov	cx,7
	mov	al,80h
log20:
	test	ah,al		;search highest bit
	jnz	log30
	shr	al,1
	loop	log20
	hlt
log30:
	mov	[logbiasbit],cx
	xor	cx,cx
	sub	cl,al
	and	byte ptr [di+4],cl
		;cut lowest bits to avoid roundup by next div
	xor	ah,ah
	call	floatdivdiax

LOG50:
	copyF	[calcsp],work3	;work3 = x + 1.0
	mov	byte ptr [di-1],2	;int part = 2

	mov	di,work2
	mov	ax,-1
	call	floatsetdiax
	mov	di,work2
	mov	si,[calcsp]
	call	addFFdisi	;work2 = x-1

	mov	di,work2
	mov	si,work3
	call	divFFdisi	;work2 = y = (x-1)/(x+1)

	copyF	work2,work3	;work3 = y^2
	mov	di,work3
	call	squareFdi

	mov	di,work2	;work2 = 2y
	mov	ax,2
	call	floatmuldiax

	copyF	work2,[calcsp]	;initial = 2*y

	mov	di,work2	;work2 = 2y^3
	mov	si,work3
	call	mulFFdisi

	mov	[fdivnum],1
	mov	[fdivstep],2
	mov	[fdiv1],3
	mov	[fsign],0
	mov	[fsignnow],0
	mov	[freserve],1

	call	far ptr farseries

	;add N*log2 to [CALCSP]

	mov	ax,[logbiasbyte]
	mov	cx,[logbiasbit]
	mov	dx,cx
	or	dx,ax
	jz	log200		;if N = 0

	;work3 = N

	or	ax,ax
	jl	logbiasnegative

	mov	bx,8
	mul	bx
	add	ax,cx

	mov	di,work3
	mov	bx,[pointword]
	cmp	bx,4
	jae	log106
	mov	bx,4
log106:
	mov	cx,bx

log107:
	inc	bx
	or	bx,pointmask
	mov	[di],bx		;attribute
	add	di,2
	mov	si,di
	add	di,2
	sub	cx,2
	jz	log108
	push	ax
	xor	ax,ax
	rep	stosw
	pop	ax
log108:
	mov	cx,4
log110:
	or	dh,dh
	jnz	log120
	mov	dh,dl
	mov	dl,ah
	mov	ah,al
	xor	al,al
	loop	log110
log120:
	mov	[si],cx		;bias
	mov	[di],ax
	mov	[di+2],dx

	;work2 = log2

	mov	si,work2
	call	getlog2

	;work2 *= N

	MOV	DI,WORK2
	mov	si,work3
	call	mulFFdisi

	;[CALCSP] += work2

	MOV	DI,[CALCSP]
	MOV	SI,WORK2
	call	addFFdisi

LOG200:
	RET

LOGERR:
	JMP	FUNCERR

logbiasnegative:
	neg	ax
	mov	bx,8
	mul	bx
	sub	ax,cx
	sbb	dx,0

	mov	di,work3
	mov	bx,[pointword]
	cmp	bx,4
	jae	log206
	mov	bx,4
log206:
	mov	cx,bx
	or	bx,signmask
	jmp	log107


;
;* square root of a non-negative floating number
;   uses integer square root routine
;
;   USE WORK2,3
;
farsqrtin:
	call	sqrt_ent
	retf

sqrtilgerr:
	jmp	ilgerr
gosqrtcomplex:
	jmp	sqrtcomplex
gosqrtnegative:
	jmp	sqrtnegative

sqrtin:
	call	kakko
sqrt_ent:
	mov	si,[calcsp]
	mov	ax,[si]
	test	ah,nonnumericmaskhigh
	jnz	sqrtilgerr
	test	ah,complexmaskhigh
	jnz	gosqrtcomplex	;if complex

	call	real2float0
	mov	si,[calcsp]
	mov	ax,[si]
	or	ax,ax
	jz	sqrtret
	test	ah,signmaskhigh
	jnz	gosqrtnegative

	mov	bx,[si+2]	;src bias
	and	ax,lenmask
	mov	di,si
	mov	cx,ax
	add	ax,ax
	dec	cx		;src FLOAT length
	add	si,ax		;src MSW
	dec	ax
	sar	bx,1
	jc	sqrtbiasodd

sqrtbiaseven:
	cmp	ax,limitword
	jbe	sqrtbiaseven10
	mov	ax,limitword
sqrtbiaseven10:
	mov	[di],ax			;new length as integer
	push	bx			;memo bias/2

	mov	dx,ax
	sub	dx,cx
	add	ax,ax
	add	di,ax			;dst MSW
	std
	rep	movsw
	mov	cx,dx
	xor	ax,ax
	rep	stosw
	cld
	jmps	sqrt50

sqrtbiasodd:
	cmp	ax,limitword
	jbe	sqrtbiasodd10
	mov	ax,limitword
sqrtbiasodd10:
	mov	[di],ax			;new length as integer

	inc	bx
	push	bx			;memo bias/2+1

	mov	dx,ax
	sub	dx,cx
	dec	dx

	add	ax,ax
	add	di,ax			;dest MSW
	xor	ax,ax
	mov	[di+1],al		;clear MSB
	dec	di
	std
	rep	movsw
	mov	cx,dx
	rep	stosw
	mov	[di+1],al		;clear 1 more byte
	cld

sqrt50:
	call	sqrmain

	;integer -> float

	mov	si,[var_x]		;result
	mov	di,[calcsp]
	mov	ax,[si]
	lea	bx,[di+4]		;used by roundupF
	add	si,2
	mov	cx,ax
	or	ax,pointmask
	mov	[di],ax			;new attribute
	add	di,2
	pop	ax			;new bias
	mov	[di],ax
	add	di,2

	mov	ah,[si]			;least byte
	inc	si
	dec	cx
	rep	movsw
	add	ah,ah
	jnc	sqrtret
	call	roundupF
sqrtret:
	ret


comment %
the following routine is very interesting as variable point word
but is slow and is not used

sqrtin:
	call	kakko
sqrt_ent:
	call	real2float0
	mov	si,[calcsp]
	mov	ax,[si]
	or	ax,ax
	jz	sqrtret
	and	ax,signmask+attribmask
	cmp	ax,pointmask
	jne	sqrtilg

	xor	dx,dx
	mov	ax,[si+2]		;bias
	dec	ax
	sar	ax,1
	adc	dx,1
	mov	[si+2],dx		;1 if odd, 2 if even
	push	ax			;bias/2 if odd, bias/2 -1 if even

	;work4 = x0

	copyF	[calcsp],work4

	;get a better initial value

	mov	si,[calcsp]
	mov	ax,[si]
	and	ax,lenmask
	add	si,ax
	add	si,ax			;MSW
	mov	ax,[si]
	inc	ax
	jnz	sqrt20
	mov	ax,100h
	jmps	sqrt30
sqrt20:
	call	wordsqrt
sqrt30:
	mov	si,[calcsp]
	mov	di,si
	mov	cx,[si]
	mov	bx,[si+2]		;bias
	and	cx,lenmask
	add	di,cx
	add	di,cx			;MSW
	dec	cx
	mov	dx,cx
	or	bx,bx
	jz	sqrt40			;if bias=0
	my_shl	ax,4
sqrt40:
	or	ah,ah
	jnz	sqrt50
	dec	word ptr [si+2]		;dec	bias
	xchg	al,ah
sqrt50:
	std
	stosw
	mov	cx,dx
	dec	cx
	xor	ax,ax
	rep	stosw
	cld

sqrtmain:
	mov	ax,[pointword]
	mov	dx,ax
	my_shr	dx,2
	shl	dx,1			;must be even
	mov	[pointword],dx

	push	ax
	call	sqrtsub
	mov	bx,[calcsp]
	add	bx,4
	call	roundupF
	pop	ax
	mov	[pointword],ax
	call	sqrtsub

	pop	ax			;bias
	mov	si,[calcsp]
	add	[si+2],ax
sqrtret:
	ret

sqrtilg:
	jmp	ilgerr


sqrtsub:
	mov	di,[calcsp]
	call	justlengthFdi
	copyF	work4,work3
	mov	di,work3
	call	justlengthFdi
sqrtloop:
	;work2 = x0/x

	copyF	work3,work2
	mov	di,work2
	mov	si,[calcsp]
	call	divFFdisi

	;work2 += [calcsp]

	mov	di,work2
	mov	si,[calcsp]
	call	addFFdisi

	;work2 /= 2

	mov	di,work2
	mov	ax,2
	call	floatdivdiax

	;x >= old x ?

	mov	di,work2
	mov	si,[calcsp]
	call	compFFdisi
	cmp	al,2
	jbe	sqrtsubret

	;update [calcsp]

	copyF	work2,[calcsp]
	jmp	sqrtloop
sqrtsubret:
	ret
%


;
; exp(x) for real number x
;
; use work2, work3, mukwork

	even
expshift	dw	?
expint		dw	?


EXPover:
	JMP	ovrERR

EXPover?:
	test	[SGNMEM_F],signmaskhigh
	jz	expover		;overflow if X>0
expset0:
	mov	si,[calcsp]
	mov	word ptr [si],0
	ret

expset1:
	mov	di,[calcsp]
	mov	ax,1
	jmp	floatsetdiax		;call & ret

expin:
	call	kakko
real_exp:
exp_ent:
	mov	[expshift],0
	mov	[expint],0

	call	real2float0
	mov	si,[calcsp]
	mov	ax,[si]
	mov	cx,ax
	and	ah,signmaskhigh
	mov	[sgnmem_f],ah
	and	cx,signmaskCPL
	mov	[si],cx		;make positive
	and	cx,lenmask
	jz	expset1		;if = 0
	cmp	word ptr [si+2],0
	jle	exp40		;if < 1.0

	;get 8*log2

	mov	si,work2
	call	getlog2longer
	mov	di,work2
	mov	ax,8
	call	floatmuldiax
	mov	di,work2
	call	justlengthFdi

	;divide by 8*log2

	mov	di,[calcsp]
	mov	si,work2
	call	idivFFdisi

	mov	si,[calcsp]
	mov	ax,[si]
	and	ax,lenmask
	cmp	ax,1
	jb	exp30		;if quot = 0
	ja	expover?
	mov	ax,[si+2]
	cmp	ax,floatbiasover
	jae	expover?
exp30:
	mov	[expshift],ax

	copyF	resadr,[calcsp]
	mov	di,[calcsp]
	mov	cx,[di]
	or	cx,cx
	jnz	exp35

	mov	ax,1			;if = 0 then ans = 1.0
	call	floatsetdiax
	jmp	expout

exp35:
	cmp	word ptr [di+2],0
	jle	exp40			;if < 1.0

	mov	si,di
	and	cx,lenmask
	add	si,cx
	add	si,cx
	xor	ax,ax
	mov	al,[si+1]		;get integer part
	mov	[expint],ax
	mov	byte ptr [si+1],0	;clear
	call	normalizeFdi
exp40:
	mov	di,[calcsp]
	cmp	word ptr [di+2],0
	jl	exp60			;< 1/256
	mov	ax,[di]
	and	ax,lenmask
	add	di,ax
	add	di,ax
	cmp	word ptr [di],8000h
	jb	exp60			;< 1/2

	mov	di,work2
	mov	ax,-1
	call	floatsetdiax
	mov	di,work2
	mov	si,[calcsp]
	call	addFFdisi		;work2 = x - 1
	inc	[expint]
	jmps	exp70
exp60:
	copyF	[calcsp],work2
exp70:
	mov	di,work2
	call	justlengthFdi
	copyF	work2,work3		;work2 = work3 = x

	;calc exp(x)
expmain:
	mov	si,work2
	mov	di,[calcsp]
	copy_si2di			;st0 = x

	mov	di,work2
	call	squareFdi		;work2 = x^2

	mov	[fdivnum],1
	mov	[fdivstep],1
	mov	[fdiv1],2
	mov	[fsign],0
	mov	[fsignnow],0
	mov	[freserve],0
	call	far ptr farseries

	;add 1.0 last to keep small values have meaning

	setsp1	di		;st1 = 1.0
	mov	ax,1
	call	floatsetdiax

	mov	di,[calcsp]
	lea	si,[di-unitbyte]
	call	addFFdisi

expout:
	mov	ax,[expshift]
	mov	si,[calcsp]
	add	[si+2],ax		;bias

	;mul integer part
	;expint varies from 0 to 6

	cmp	[expint],0
	je	expout100

	mov	si,work2
	call	getexp1
expoutlp:
	shr	[expint],1
	jnc	expout20

	mov	di,[calcsp]
	mov	si,work2
	call	mulFFdisi
expout20:
	cmp	[expint],0
	je	expout100

	mov	di,work2
	call	squareFdi
	jmp	expoutlp

expout100:
	cmp	[sgnmem_f],0
	je	expret

	;must reverse the result

	copyF	[calcsp],work2
	mov	di,[calcsp]
	mov	ax,1
	mov	[di],ax
	mov	[di+2],ax
	mov	si,work2
	jmp	div_integer_float	;call & ret
expret:
	ret


;
;* arctangent
;

farARCTAN:
	call	atan_ent
	retf

atanilgerr:
	jmp	ilgerr
goatancomplex:
	jmp	atancomplex

ARCTAN:
	call	kakko
ATAN_ENT:
	mov	si,[calcsp]
	mov	ax,[si]
	test	ah,nonnumericmaskhigh
	jnz	atanilgerr
	test	ah,complexmaskhigh
	jnz	goatancomplex

atanreal:
	call	real2float0
	mov	si,[calcsp]
	mov	ax,[si]
	mov	cx,ax
	and	ah,signmaskhigh
	and	cx,signmaskCPL
	mov	[sgnmem_f],ah
	mov	[si],cx		;make positive
	mov	[atan_chg],0
	and	cx,lenmask
	jz	atan_ret	;if x = 0

	mov	ax,[si+2]	;bias
	cmp	ax,1
	jl	atanless1	;if x < 1.0
	jg	atangreater1	;if int(x) > 1byte

	lea	di,[si+4]
	add	cx,cx
	sub	cx,3
	xor	al,al
	repe	scasb
	jne	atangreater1		;if fraction <> 0
	cmp	byte ptr [di],1
	je	atan1		;if x is just 1.0

atangreater1:
	;if X>1 then change to 1/X

	mov	[atan_chg],10000000b	;1/X set bit

	mov	di,[calcsp]
	call	inverseFdi		;use work2

atanless1:
	;now x < 1.0
	;      < 1/2 ?

	copyF	[calcsp],work2		;work2 = x

	mov	si,[calcsp]
	mov	word ptr [si],0		;st0 = 0

	mov	si,work2
	cmp	word ptr [si],0
	je	atanadd		;if 0

	cmp	word ptr [si+2],0
	jl	atanadd		;x < 1/256
	jg	atan1		;avoid 1.0

	mov	ax,[si]
	and	ax,lenmask
	add	ax,ax
	add	si,ax		;MSW

	mov	ax,[si]
	cmp	ax,8000h
	jb	atanless12	;if <1/2

	;st0 = atan(1/2)

	mov	si,sysatan12
	mov	di,[calcsp]
	mov	word ptr [di+2],0	;bias
	mov	[sysconstmore],0
	call	sysconstin

	;work2 = new x = (2x-1)/(x+2)

	copyF	work2,work3

	mov	di,work2
	mov	ax,2
	call	floatmuldiax	;work2 = 2x

	mov	di,work4
	mov	ax,1
	call	floatsetdiax	;work4 = 1.0

	mov	di,work2
	mov	si,work4
	call	subFFdisi	;work2 = 2x-1

	mov	di,work4
	mov	ax,2
	call	floatsetdiax	;work4 = 2.0

	mov	di,work3
	mov	si,work4
	call	addFFdisi	;work3 = x+2

	mov	di,work2
	mov	si,work3
	call	divFFdisi	;work2 = (2x-1)/(x+2)

atanless12:

	;now x is < 1/2
	;         < 1/4 ?

	mov	si,work2
	cmp	word ptr [si],0
	je	atanadd		;if 0
	cmp	word ptr [si+2],0	;bias
	jl	atanadd			;if x < 1/256

	mov	ax,[si]
	and	ax,lenmask
	add	ax,ax
	add	si,ax		;MSW

	mov	ax,[si]
	cmp	ax,4000h
	jb	atanless14	;if 1/4

	;* add atan(1/4) to answer

	mov	si,sysatan14
	mov	di,work3
	mov	word ptr [di+2],0	;bias
	mov	[sysconstmore],0
	call	sysconstin
	setsp0	di
	mov	si,work3
	call	addFFdisi

	;work2 = new x = (4x-1)/(x+4)

	copyF	work2,work3

	mov	di,work2
	mov	ax,4
	call	floatmuldiax	;work2 = 4x

	mov	di,work4
	mov	ax,1
	call	floatsetdiax	;work4 = 1.0

	mov	di,work2
	mov	si,work4
	call	subFFdisi	;work2 = 4x-1

	mov	di,work4
	mov	ax,4
	call	floatsetdiax	;work4 = 4.0

	mov	di,work3
	mov	si,work4
	call	addFFdisi	;work3 = x+4

	mov	di,work2
	mov	si,work3
	call	divFFdisi	;work2 = (4x-1)/(x+4)

atanless14:

	;now x < 1/4
	;      < 1/8 ?

	mov	si,work2
	cmp	word ptr [si],0
	je	atanadd		;if 0
	cmp	word ptr [si+2],0	;bias
	jl	atanadd			;if x < 1/256

	mov	ax,[si]
	and	ax,lenmask
	add	ax,ax
	add	si,ax		;MSW

	mov	ax,[si]
	cmp	ax,2000h
	jb	atanadd		;if <1/8

	;* add atan(1/4) to answer

	mov	si,sysatan14
	mov	di,work3
	mov	word ptr [di+2],0	;bias
	mov	[sysconstmore],0
	call	sysconstin
	setsp0	di
	mov	si,work3
	call	addFFdisi

	;work2 = new x = (4x-1)/(x+4)
	;stack0 = (1-4x)/(x+4)

	copyF	work2,work3

	mov	di,work2
	call	chgsigndi
	mov	di,work2
	mov	ax,4
	call	floatmuldiax	;work2 = -4x

	mov	di,work4
	mov	ax,1
	call	floatsetdiax	;work4 = 1.0

	mov	di,work2
	mov	si,work4
	call	addFFdisi	;work2 = -4x+1

	mov	di,work4
	mov	ax,4
	call	floatsetdiax	;work4 = 4.0

	mov	di,work3
	mov	si,work4
	call	addFFdisi	;work3 = x+4

	mov	di,work2
	mov	si,work3
	call	divFFdisi	;work2 = (4x-1)/(x+4)

atansub:
	;now work2 = x
	;    st0 = intermediate result

	call	ahedsp
	call	atanmain
	add	[calcsp],unitbyte	;call	backsp
	csub	0,1
	jmp	atanout

atanadd:
	call	ahedsp
	call	atanmain
	add	[calcsp],unitbyte	;call	backsp
	cadd	0,1

atanout:
	TEST	[ATAN_CHG],10000000b
	JZ	ATAN110

	MOV	SI,[CALCSP]
	MOV	AX,[SI]
	OR	AH,signmaskhigh
	MOV	[SI],AX		;make negative

	;work2 = pi/2

	mov	si,work2
	call	pai10
	mov	di,work2
	mov	ax,2
	call	floatdivdiax

	;ans += pi/2

	mov	di,[calcsp]
	mov	si,work2
	call	addFFdisi

atan110:
	mov	si,[calcsp]
	mov	ax,[si]
	or	ax,ax
	jz	atan_ret
	xor	ah,[sgnmem_f]
	mov	[si],ax

atan_ret:
	ret


atan1:
	mov	si,[calcsp]
	call	pai10
	mov	di,[calcsp]
	mov	ax,4
	call	floatdivdiax
	jmp	atan110


atanmain:
	copyF	work2,[calcsp]		;[calcsp] = x
	copyF	work2,work3		;work3 = x

	mov	di,work3
	call	squareFdi		;work3 = x^2

	mov	di,work2
	mov	si,work3
	call	mulFFdisi		;work2 = x^3

	mov	[fdivnum],1
	mov	[fdivstep],2
	mov	[fdiv1],3
	mov	[fsign],80h
	mov	[fsignnow],80h
	mov	[freserve],1
	call	far ptr farseries
	ret

;
;* sinh,cosh
;

sinhlessthan1:
	copyF	[calcsp],work2
	copyF	[calcsp],work3

	mov	di,work3	;work3 = x^2
	call	squareFdi

	mov	di,work2	;work2 = x^3
	mov	si,work3
	call	mulFFdisi

	mov	[fdivnum],2
	mov	[fdivstep],2
	mov	[fdiv1],3
	mov	[fdiv2],2
	mov	[fsign],0
	mov	[fsignnow],0
	mov	[freserve],0
	call	far ptr farseries
	ret


coshlessthan1:
	copyF	[calcsp],work2
	mov	di,work2
	call	squareFdi

	copyF	work2,work3

	mov	di,[calcsp]	;stack0 = 1.0
	mov	ax,1
	call	floatsetdiax

	mov	[fdivnum],2
	mov	[fdivstep],2
	mov	[fdiv1],2
	mov	[fdiv2],1
	mov	[fsign],0
	mov	[fsignnow],0
	mov	[freserve],0
	call	far ptr farseries
	ret


sinhCALCSPERR:
	jmp	calcsperr
sinhilgerr:
	jmp	ilgerr

sinhret0:
	ret
gosinhlessthan1:
	jmp	sinhlessthan1

gosinhcomplex:
	jmp	sinhcomplex

sinh:
	call	kakko
sinh_ent:
	mov	si,[calcsp]
	mov	ax,[si]
	test	ah,complexmaskhigh
	jnz	gosinhcomplex
	or	ax,ax
	jz	sinhret0		;sinh(0)=0
	cmp	word ptr [si+2],0
	jle	gosinhlessthan1
	clc				;means sinh

sinhcoshreal:
	pushf
	call	exp_ent
	mov	di,work2
	mov	ax,1
	call	floatsetdiax
	mov	di,work2
	mov	si,[calcsp]
	call	divFFdisi
	mov	di,[calcsp]
	mov	si,work2
	popf
	jc	sinhcosh50		;if cosh
	call	subFFdisi
	jmps	sinhcosh60
sinhcosh50:
	call	addFFdisi
sinhcosh60:
	mov	di,[calcsp]
	mov	ax,2
	jmp	floatdivdiax	;call & ret


coshret0:
	mov	di,[calcsp]
	mov	ax,1
	jmp	floatsetdiax	;call & ret
gocoshlessthan1:
	jmp	coshlessthan1
gocoshcomplex:
	jmp	coshcomplex

cosh:
	call	kakko
cosh_ent:
	mov	si,[calcsp]
	mov	ax,[si]
	test	ah,complexmaskhigh
	jnz	gocoshcomplex
	or	ax,ax
	jz	coshret0		;cosh(0)=1
	cmp	word ptr [si+2],0
	jle	gocoshlessthan1
	stc				;means cosh
	jmp	sinhcoshreal

;
;* BESSEL FUNCTIONS
;

besselJ:
jmp	synerr
	mov	ax,8080h
	jmp	far ptr farbesselin

besselI:
jmp	synerr
	xor	ax,ax
	jmp	far ptr farbesselin


;
; * arcsin
;

asinmain:
	call	asinacospart1
	jc	asinlarge
asinnormal:
	jmp	asinacospart2	;call & ret

asinlarge:			;for only real & abs > sqrt(2)/2
	setsp0	si
	setspm1	di
	call	xchgsidi
	mov	si,[calcsp]
	mov	ax,[si]
	push	ax
	and	ax,signmaskCPL
	mov	[si],ax		;make positive
	call	asinacospart2
	call	asinacospart3
	pop	ax
	and	ax,signmask
	mov	si,[calcsp]
	xor	[si],ax
	ret


;
; * arccos
;
acosmain:
	call	asinacospart1
	jc	acoslarge
acosnormal:
	call	asinacospart2
	jmp	asinacospart3

acoslarge:			;for only real & abs sqrt(2)/2
	setsp0	si
	setspm1	di
	call	xchgsidi
	mov	si,[calcsp]
	mov	ax,[si]
	push	ax
	and	ax,signmaskCPL
	mov	[si],ax		;make positive
	call	asinacospart2
	pop	ax
	and	ax,signmask
	jnz	acosnegative
	ret			;if positive
acosnegative:
	mov	si,[calcsp]	;make negative
	cmp	word ptr [si],0
	je	acosminus1
	xor	[si],ax
	sub	si,unitbyte
	mov	[calcsp],si
	call	pai10
	jmp	addin		;call & ret
acosminus1:
	jmp	pai10		;call & ret, ans=pi


asinacosilgerr:
	jmp	ilgerr

asinacospart1:
	checkcalcsp	3

	call	kakko		;st0 = x
	mov	si,[calcsp]
	mov	ax,[si]
	test	ah,nonnumericmaskhigh
	jnz	asinacosilgerr

	push	si		;/*

	call	funcsetall	;set to float

	cmove	1,0		;st1 = x
	mov	si,[calcsp]
	sub	si,unitbyte
	mov	[calcsp],si	;(+1)

	csquare	0		;st1 = x^2

	mov	di,[calcsp]
	call	chgsigndi	;st1 = -x^2

	mov	ax,1		;st2 = 1
	mov	si,[calcsp]
	sub	si,unitbyte
	mov	[calcsp],si	;(+2)
	mov	[si],ax
	mov	[si+2],ax

	call	addin		;st1 = 1 - x^2
	call	sqrt_ent	;st1 = sqrt(1-x^2)

	pop	si		;*/
	mov	ax,[si]
	or	ax,ax
	jz	asinacosdirect		;if 0
	test	ax,complexmask
	jnz	asinacosdirect		;if complex
	cmp	word ptr [si+2],0
	jl	asinacosdirect
	ja	asinacosreverse
	and	ax,lenmask
	add	ax,ax
	add	si,ax
	cmp	byte ptr [si+1],0b5h	;MSB of sqrt(2)/2
	jae	asinacosreverse
asinacosdirect:
	clc
	ret
asinacosreverse:
	stc
	ret


asinacospart2:
	call	divin
	jmp	atan_ent	;call & ret

asinacospart3:
	call	ahedsp		;get pi/2
	call	pai10
	mov	di,[calcsp]
	mov	ax,2
	call	floatdivdiax

	call	subin
	chgsign	0
	ret


code	ends


code2	segment	public
	assume	cs:code2,ds:data

pointsetsynerr:
	jmp	far ptr synerr
pointsetilgerr:
	jmp	far ptr ilgerr


;
;* pointset
;
pointset:
	call	far ptr farformul
	cmp	byte ptr [bp],0c2h	;code of ,
	jne	pointsetsynerr
	inc	bp
	call	far ptr farkakko
	mov	si,[calcsp]
	mov	ax,[si]
	cmp	ax,1
	jne	pointsetilgerr
	mov	ax,[si+2]
	cmp	ax,2
	jb	pointsetilgerr
	cmp	ax,limitword
	jae	pointsetilgerr
	add	si,unitbyte
	mov	[calcsp],si
	mov	cx,[si]
	inc	ax
	mov	dx,cx			;memo old [si]
	and	ch,lenmaskhighcpl
	or	ah,ch
	and	ch,signmaskhighcpl
	and	dx,lenmask
	cmp	ch,pointmaskhigh
	jne	pointsetilgerr
	mov	[si],ax
	and	ax,lenmask
	sub	ax,dx
	jb	ptsetshorter
	je	ptsetreturn
ptsetlonger:
	add	si,dx
	add	si,dx			;MSW
	mov	di,si
	mov	cx,dx
	add	di,ax
	dec	cx
	add	di,ax
	std
	rep	movsw
	mov	cx,ax
	xor	ax,ax
	rep	stosw
	cld
ptsetreturn:
	jmp	far ptr returnadr
ptsetshorter:
	qinc	si
	mov	cx,ax
	mov	di,si
	mov	bx,di
	sub	si,ax
	add	cx,dx
	sub	si,ax
	dec	cx
	mov	ah,[si-1]
	rep	movsw
	add	ah,ah
	jnc	ptsetreturn
	jmp	far ptr roundupF


;
;* sizeof
;
sizeof:
	call	far ptr farkakko
	mov	si,[calcsp]
	mov	ax,[si]
	and	ax,lenmask
	inc	ax
	mov	word ptr [si],1
	mov	word ptr [si+2],ax
	jmp	far ptr returnadr


;
;* significand of floating number
;
signifilgerr:
	jmp	far ptr ilgerr

significand:
	call	far ptr farkakko
	mov	si,[calcsp]
	mov	ax,[si]
	and	ax,attribmask
	cmp	ax,pointmask
	jne	signifilgerr
	mov	word ptr [si+2],0	;set bias = 0
signifret:
	jmp	far ptr returnadr


;
;* exponent of floating number
;
exponent:
	call	far ptr farkakko
	mov	si,[calcsp]
	mov	ax,[si]
	and	ax,attribmask
	cmp	ax,pointmask
	jne	signifilgerr

	mov	ax,[si+2]
	mov	cx,ax
	or	ax,ax
	jz	exponentret
	and	cx,signmask
	inc	cx
	or	ax,ax
	jg	exponentret
	neg	ax
exponentret:
	mov	[si],cx
	mov	[si+2],ax
	jmp	far ptr returnadr
exponent4int:
	mov	ax,[si]
	mov	di,si
	and	ax,lenmask
	jz	exponent4zero
	add	ax,ax
	mov	cx,1
	add	di,ax
	cmp	byte ptr [di+1],0
	jne	exponentret
	dec	ax
	jmp	exponentret

exponent4zero:				;set minimum integer
	mov	cx,signmask+1
	mov	ax,7fffh
	jmp	exponentret


;
;* asin
;
asin:
	jmp	far ptr asinmain


;
;* acos
;
acos:
	jmp	far ptr acosmain


;
; common subroutine for power series
; for real and complex argument x
; inp
;	stack0 = initial value & result
;	work2  = general term
;	work3  = x or x^2 or (x/2)^2

;	fdivnum  = 1 or 2 = number of divisors
;	fdivstep = ? = step fdiv
;	fdiv1  = divisor1: fdiv1 must >= fdiv2
;	fdiv2  = divisor2
;	fsign  = a_{n-1} = 0 or 80h = a_n or -a_n
;	fsignnow = 0 or 80h = start from add or sub
;	freserve = 0 or 1 = a_n is independent of a_{n-1} or not

;	use stk0, -1, -2, -3, -4

goseriescomplex:
	jmp	seriescomplex

seriesret:
	mov	[fixedflag],0
	retf

farseries:
	cmp	word ptr ds:[work2],0
	je	seriesret

	test	byte ptr ds:[work2+1],complexmaskhigh
	jnz	goseriescomplex		;if complex
	test	byte ptr ds:[work3+1],complexmaskhigh
	jnz	goseriescomplex		;if complex

	mov	di,[calcsp]
	mov	ax,[di]
	test	ah,complexmaskhigh
	jnz	goseriescomplex		;if complex

	and	ax,lenmask
	dec	ax
	add	ax,ax
	mov	[fpointbyte],ax

	mov	[fixedflag],1		;fixed point mode

serieslp:
	cmp	[freserve],0
	je	series10
	copyF	work2,work4
series10:
	;div work2 by fdiv1, fdiv2

	mov	ax,[fdiv1]
	cmp	[fdivnum],1
	je	series30
	or	ah,ah
	jnz	series20
	mul	[fdiv2]
	jmps	series30
series_nomeaning:
	jmp	far ptr floaterr

series20:
	mov	di,work2
	call	far ptr farfloatdivdiax

	mov	ax,[fdiv2]
series30:
	mov	di,work2
	call	far ptr farfloatdivdiax

	;add/sub to/from total

	mov	si,work2
	cmp	word ptr [si],0
	je	seriesret	;finish if 0

	mov	di,[calcsp]
;	mov	ax,[di]
;	and	ax,lenmask
;	add	ax,ax
;	cmp	ax,[pointword]
;	jb	series_nomeaning	;point is too small

	mov	ax,[di+2]
	sub	ax,[si+2]
	cmp	ax,[fpointbyte]
	jge	seriesret	;finish if treated as 0

	mov	al,[fsignnow]
	or	al,al
	jl	series50
	call	far ptr faraddFFdisi
	jmps	series60
series50:
	call	far ptr farsubFFdisi
series60:
	;update sign

	mov	al,[fsign]
	xor	[fsignnow],al

	;update counter

	mov	ax,[fdivstep]
	add	[fdiv1],ax
	jc	serieserr
	add	[fdiv2],ax

	;update general term

	cmp	[freserve],0
	je	series70
	copyF	work4,work2
series70:
	mov	di,work2
	mov	si,work3
	call	far ptr farmulFFdisi
	jmp	serieslp

serieserr:
	jmp	far ptr funcerr		;non convergent


seriescomplex:
	cmove2	mulwork,0		;reserve
	call	far ptr farpush_calcstack
	mov	[calcsp],LIMIT-5*unitbyte	;use 5 levels
	cmove3	0,mulwork		;restore
	cmove3	-1,work2
	cmove3	-2,work3

cserieslp:
	cmp	[freserve],0
	je	cseries10
	cmove	-3,-1		;stk-1 -> stk-3	to reserve
cseries10:
	;div stk-1 by fdiv1, fdiv2

	mov	ax,[fdiv1]
	cmp	[fdivnum],1
	je	cseries30
	or	ah,ah
	jnz	cseries20
	mul	[fdiv2]
	jmps	cseries30
cseries20:
	setspm1	di
	call	far ptr farfloatdivdiax

	mov	ax,[fdiv2]
cseries30:
	setspm1	di
	call	far ptr farfloatdivdiax

	;add/sub to/from total

	cmove	-4,0		;stk0  -> stk-4 to reserve old result

	cmp	[freserve],0
	jne	cseries40
	cmove	-3,-1		;stk-1 -> stk-3 to reserve

cseries40:
	mov	di,[calcsp]
	lea	si,[di+unitbyte]

	mov	al,[fsignnow]
	or	al,al
	jl	cseries50
	call	far ptr faraddAAdisi	;stk0 += stk-1
	jmps	cseries60
cseries50:
	call	far ptr farsubAAdisi	;stk0 -= stk-1
cseries60:
	;compare old and new

	mov	si,[calcsp]
	mov	cx,[si]
	lea	di,[si+4*unitbyte]
	and	cx,lenmask
	inc	cx
	repe	cmpsw
	je	cseriesret

	;update sign

	mov	al,[fsign]
	xor	[fsignnow],al

	;update counter

	mov	ax,[fdivstep]
	add	[fdiv1],ax
	jc	serieserr
	add	[fdiv2],ax

	;update general term

	cmove	-1,-3		;stk-3 -> stk-1 to restore
				;different operation
				;for reserve and nonreserve modes
	cmove	-3,-2
	mov	di,[calcsp]
	lea	si,[di+2*unitbyte]
	add	di,unitbyte
	call	far ptr farmulAAdisi	;stk-1 *= stk-2
	cmove	-2,-3
	jmp	cserieslp

cseriesret:
	cmove2	mulwork,0	;reserve result
	call	far ptr farpop_calcstack
	cmove3	0,mulwork	;restore result
	mov	[fixedflag],0
	retf


;
; bessel function main routine
;

besselilg:
	jmp	far ptr ilgerr

farbesselin:
	push	ax			;/*
	call	far ptr farget_ax
	jc	besselilg		;not a positive integer
	cmp	ax,maxfactorial
	ja	besselilg
	push	ax			;/**

	cmp	byte ptr [bp],0c2h	;code of ,
	jne	besselilg
	inc	bp

	call	far ptr farkakko

	pop	ax			;**/
	mov	[fdiv1],ax

	pop	ax			;*/
	mov	[fsign],al
	mov	[fsignnow],ah

	mov	si,[calcsp]
	lodsw
	test	ah,nonnumericmaskhigh
	jnz	besselilg

	call	far ptr farall2float0

	sub	[calcsp],2*unitbyte	;
	call	ahedsp2			;use 3 levels more

	setspm3	di			;stk-3 = x/2
	mov	ax,2
	call	far ptr farfloatdivdiax

	setspm3	si
	setspm1	di
	copy_si2di
	setspm1	di
	call	far ptr farsquareIFCdi	;stk-1 = (x/2)^2

	setspm3	di
	mov	ax,[fdiv1]
	or	ax,ax
	jnz	bessel50

	mov	ax,1
	call	far ptr farfloatsetdiax	;stk-3 = 1.0
	jmps	bessel60

bessel50:
	call	far ptr farpowerFCdiax	;stk-3 = (x/2)^k

	mov	di,[calcsp]
	mov	ax,[fdiv1]
	call	far ptr farfactorialFFdiax	;stk0 = k!

	mov	si,[calcsp]
	lea	di,[si+3*unitbyte]
	call	far ptr fardivAAdisi	;stk-3 = (x/2)^k/k!

bessel60:
	setspm2	di
	lea	si,[di+unitbyte]
	copy_si2di			;stk-2 = stk-3

	setspm1	si
	setsp0	di
	copy_si2di			;stk0 = (x/2)^2
	setsp0	si
	lea	di,[si+2*unitbyte]
	call	far ptr farmulAAdisi	;stk-2 = 1st term

	cmove2	work2,-2
	cmove2	work3,-1
	add	[calcsp],3*unitbyte

	mov	[fdivnum],2
	mov	[fdivstep],1
	inc	[fdiv1]
	mov	[fdiv2],1
	mov	[freserve],0
	call	far ptr farseries
	jmp	far ptr returnadr


code2	ends

