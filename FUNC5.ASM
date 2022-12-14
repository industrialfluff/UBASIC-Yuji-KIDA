;func5.asm

code	segment	word public
	assume	cs:code, ds:data

	extrn	mul_float_float:near
	extrn	mul_complex_float:near
	extrn	complexsetdiax:near
	extrn	chgsigndi:near

	extrn	faraddAAdisi:far,farsubAAdisi:far
	extrn	farmulAAdisi:far

comment %
	extrn	complexdivdiax:near,farcomplexdivdiax:far


;
; bessel functions for complex number
;

besselcomplex:
	call	complex2float0

	mov	di,[calcsp]		;stack0 = x/2
	mov	ax,2
	call	complexdivdiax

	copyF	[calcsp],work3		;work3 = (x/2)^2
	mov	di,work3
	call	squareCdi

	mov	ax,[fdiv1]
	or	ax,ax
	jnz	bessecl50

	mov	di,[calcsp]		;stack0 = 1.0
	mov	ax,1
	call	floatsetdiax
	jmps	besselc60

besselc50:
	mov	di,[calcsp]		;stack0 = (x/2)^k
	mov	ax,[fdiv1]
	call	powerFFdiax

	mov	di,work2		;work2 = k!
	mov	ax,[fdiv1]
	call	factorialFFdiax

	mov	di,[calcsp]		;stack0 = (x/2)^k/k!
	mov	si,work2
	call	divIorFdisi

besselc60:
	copyF	[calcsp],work2		;stack0 = work2 = term_0

	mov	di,work2		;work2 = term_1
	mov	si,work3
	call	mulAAdisi

	mov	[fdivnum],2
	mov	[fdivstep],1
	inc	[fdiv1]
	mov	[fdiv2],1
	mov	[freserve],0
	call	far ptr farcseries
	ret
%


;
; exp(x) for complex number x
;
complex_exp:

	;exp(a+bi) = exp(a)(cos(b)+isin(b))
	;use work2, work3, mulwork
	;    2 more calc stack

	checkcalcsp	2

	mov	si,[calcsp]
	lea	di,[si-unitbyte]
	add	si,2
	mov	[calcsp],di
	lodsw
	and	ax,lenmask
	add	ax,ax
	add	si,ax
	push	si
	copy_si2di		;[sp1] = b
	call	cos_ent		;[sp1] = cos(b)

	pop	si
	mov	di,[calcsp]
	sub	di,unitbyte
	mov	[calcsp],di
	copy_si2di		;st2 = b
	call	sin_ent		;st2 = sin(b)

	cmovereal3	work2,-2	;work2 = a
	mov	bx,[calcsp]
	mov	di,bx
	lea	si,[bx+unitbyte]
	add	bx,unitbyte*2
	mov	[calcsp],bx
	call	setcomplex	;[sp0] = cos(b) + isin(b)
	sub	[calcsp],unitbyte

	cmove3	0,work2		;[sp1] = a
	call	exp_ent		;[sp1] = exp(a)
	mov	si,[calcsp]
	lea	di,[si+unitbyte]
	mov	[calcsp],di
	test	word ptr [di],complexmask
	jz	go_mul_float_float
	jmp	mul_complex_float
go_mul_float_float:
	jmp	mul_float_float

;
;* subroutines for sin, cos, sinh, cosh
;

sinhcoshcomplexsub:

	;inp
	;x = a + bi
	;out
	;[sp0] = sinh(a)
	;[sp1] = cosh(a)
	;st2 = sin(b)
	;stack3 = cos(b)

	;use work4 (sin,cos,sinh,cosh do not use work4)
	;copy to work4
	;with replacing real part and imaginary part

	mov	si,[calcsp]
	mov	di,work4
	lodsw
	push	si		;start of real part
	stosw
	lodsw
	and	ax,lenmask
	add	ax,ax
	add	si,ax
	copy_si2di		;1st copy im part as real part
	pop	si
	copy_si2di		;2nd copy real part as im part
	jmps	sincossinhcosh


sincoscomplexsub:

	;inp
	;x = a + bi
	;out
	;[sp0] = sinh(b)
	;[sp1] = cosh(b)
	;st2 = sin(a)
	;stack3 = cos(a)

	copyF	[calcsp],work4

sincossinhcosh:

	;use work4 (sin,cos,sinh,cosh do not use work4)

	checkcalcsp	3	;needs 3 more

	cmoveimag2	0,work4
	call	sinh_ent
	sub	[calcsp],unitbyte
	cmoveimag2	0,work4
	call	cosh_ent
	sub	[calcsp],unitbyte
	cmovereal2	0,work4
	call	sin_ent
	sub	[calcsp],unitbyte
	cmovereal2	0,work4
	call	cos_ent
	add	[calcsp],unitbyte*3
	ret


;
;* complex SIN
;
sincomplex:
	call	sincoscomplexsub

	cmul	2,1		;st2 = sin(a)cosh(b)
	cmul	3,0		;stack3 = cos(a)sinh(b)
	cset	2,3

;
;* complex COS
;
coscomplex:
	call	sincoscomplexsub

	cmul	2,0		;st2 = sin(a)sinh(b)
	chgsign	2
	cmul	3,1		;stack3 = cos(a)cosh(b)
	cset	3,2


;
;* complex SINh
;
sinhcomplex:
	call	sinhcoshcomplexsub

	cmul	2,1		;st2 = sin(b)cosh(a)
	cmul	3,0		;stack3 = cos(b)sinh(a)
	cset	3,2

;
;* complex COSh
;
coshcomplex:
	call	sinhcoshcomplexsub

	cmul	2,0		;st2 = sin(b)sinh(a)
	cmul	3,1		;stack3 = cos(b)cosh(a)
	cset	3,2



;
;* complex square root
;

sqrtnegative:
	makepos	0
	call	sqrt_ent
	mov	si,[calcsp]
	mov	ax,[si]
	and	ax,lenmask
	add	si,ax
	add	si,ax
	lea	di,[si+4]
	inc	ax
	mov	cx,ax

	std
	rep	movsw
	mov	cx,ax		;push	ax
	xor	ax,ax
	stosw			;real part
	mov	ax,cx		;pop	ax
	inc	ax
	or	ah,complexmaskhigh
	stosw
	cld
	ret


sqrtcomplex:
	checkcalcsp	3

	cmove	1,0		;copy

	sub	[calcsp],unitbyte	;call	ahedsp

	call	abs_ent			;take abs

	cmovereal	1,-1
	mov	bx,[calcsp]
	sub	bx,unitbyte
	test	byte ptr [bx+1],signmaskhigh	;check sign
	jnz	csqrtAneg		;if A < 0
csqrtApos:
	cadd	0,1
	call	csqrtsub
	cset	1,2

csqrtAneg:
	csub	0,1
	call	csqrtsub
	cset	2,1

csqrtsub:
	mov	di,[calcsp]
	mov	ax,2
	call	floatdivdiax
	call	sqrt_ent

	cmoveimag	1,-1
	cdiv	1,0
	mov	di,[calcsp]
	sub	di,unitbyte
	mov	ax,2
	call	floatdivdiax

	add	[calcsp],unitbyte	;call	backsp
	ret


;
;* complex tangent
;

comment %
We do not use this from version 9
reason:
	if im(z) is near #pi then the error is very large

tancomplex:
	checkcalcsp	2

	mov	di,[calcsp]
	sub	di,unitbyte
	mov	[calcsp],di

	csetImdi	2	;[sp1] = 2i

	call	mulin		;with BACKSP
	call	cexp_ent	;[sp0] = exp(2iZ)

	mov	di,[calcsp]
	sub	di,unitbyte
	mov	[calcsp],di
	mov	ax,1
	stosw			;[sp1]=1
	stosw
	call	subin		;with BACKSP
				;[sp0]=exp(2iZ)-1
	cmove	1,0

	mov	di,[calcsp]
	sub	di,unitbyte*2
	mov	[calcsp],di
	mov	ax,1
	stosw			;[sp2]=2
	inc	ax
	stosw
	call	addin		;with BACKSP
				;[sp1]=exp(2iZ)+1
	mov	di,[calcsp]
	sub	di,unitbyte
	mov	[calcsp],di
	csetImdi	1	;[sp2]=i

	call	mulin		;with BACKSP
	call	divin		;with BACKSP
	ret
%


atancomplex:
	jmp	ilgerr


comment %
cut this function because of code size lack
1998/1/6
;
;* complex ARCTANGENT
;

atancomplex:
	checkcalcsp	1

	cmove	1,0		;st0 = st1 = z

	mov	si,[calcsp]
	sub	si,unitbyte
	mov	[calcsp],si	;(+1)

	;change sign complex

	winc	si
	lodsw			;real part
	or	ax,ax
	jz	atanim50
	xor	ah,signmaskhigh
	mov	[si-2],ax
	and	ax,lenmask
	add	ax,ax
	add	si,ax
atanim50:
	lodsw
	or	ax,ax
	jz	atanim60
	xor	ah,signmaskhigh
	mov	[si-2],ax
atanim60:

	mov	di,work4
	csetImdi	1	;work4 = #i
	setsp0	di
	mov	si,work4
	call	addAAdisi	;st1 = #i - z

	setsp0	si		;st0 = #i - z, st1 = z
	setspm1	di
	call	xchgsidi

	mov	di,work4
	csetImdi	1	;work4 = #i
	setsp0	di
	mov	si,work4
	call	addAAdisi	;st1 = #i + z

	call	divin		;st0 = (#i-z)/(#i+z)
	call	log_ent		;st0 = log()

	mov	di,[calcsp]
	sub	di,unitbyte
	mov	[calcsp],di	;(+1)

	csetImdi	2	;st1 = 2#i
	jmp	divin		;st0 = log()/2#i
				;call & ret
%


;
;* complex log(Z)
;
;work2-work4 cannnot be used
;use 4 level calc stacks(including 1st parameter area)


logcomplex:
lognegative:
	checkcalcsp	2

	sub	[calcsp],unitbyte	;ahedsp +1
	cmove	0,-1		;copy Z
	call	abs_ent		;take abs
	call	logreal		;take log
	sub	[calcsp],unitbyte	;ahedsp +2
	cmove	0,-2		;copy Z
	call	arg_ent
	add	[calcsp],unitbyte*2

	cset	1,2


;
; * argument of complex numbers
;

argreal:
	test	ah,signmaskhigh
	jnz	argminus
	mov	word ptr [si],0
	ret
argminus:
	set_pi	0
	ret


argilgerr:
	jmp	ilgerr

argin:
	call	kakko

arg_ent:
	mov	si,[calcsp]
	mov	ax,[si]
	test	ah,nonnumericmaskhigh
	jnz	argilgerr
	test	ah,complexmaskhigh
	jz	argreal

	checkcalcsp	1

	mov	si,[calcsp]	;slide down real part
	mov	di,si
	winc	si
	lodsw
	mov	bx,ax		;memo attribute of real part
	and	ah,signmaskhighCPL	;make positive
	stosw
	and	ax,lenmask
	mov	cx,ax
	rep	movsw

	mov	di,[calcsp]	;copy imaginary part to st1
	sub	di,unitbyte
	lodsw
	push	ax		;* attribute of imaginary part
	push	bx		;** attribute of real part
	and	ah,signmaskhighCPL	;make positive
	stosw
	and	ax,lenmask
	mov	cx,ax
	rep	movsw

	mov	di,[calcsp]
	lea	si,[di-unitbyte]
	call	compdisi_abs
	cmp	al,4
	je	arg30		;if abs[di] < abs[si]

	cdiv	1,0
	cmove	0,1
	call	atanreal
	jmp	arg40

arg30:
	cdiv	0,1
	call	atanreal
	set_pi	1
	mov	di,[calcsp]
	sub	di,unitbyte
	mov	ax,2
	call	floatdivdiax
	chgsign	0
	cadd	0,1
arg40:
	pop	ax		;** attribute of real part
	test	ah,signmaskhigh
	jz	arg50
	chgsign	0
	set_pi	1
	cadd	0,1
arg50:
	pop	ax		;* attribute of imaginary part
	test	ah,signmaskhigh
	jz	arg60
	chgsign	0
arg60:
	ret


;  in  : di,si
;  out : al=1 abs[di] = abs[si]
;        al=2 abs[di] > abs[si]
;        al=4 abs[di] < abs[si]
;  also called from MIN,MAX
;  must be non-destructive

compdisi_abs:
	mov	ax,[di]
	mov	dx,[si]
	push	ax
	push	di
	push	dx
	push	si

	mov	bx,di
	test	ax,ratmask
	jz	compabs10
	add	bx,2
compabs10:
	and	word ptr [bx],signmaskCPL

	mov	bx,si
	test	dx,ratmask
	jz	compabs30
	add	bx,2
compabs30:
	and	word ptr [bx],signmaskCPL

	call	comparein

	pop	si
	pop	dx
	mov	[si],dx
	pop	di
	pop	dx		;reserve ax
	mov	[di],dx
	ret

code	ends
