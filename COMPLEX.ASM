;complex.asm

code	segment
	assume	cs:code,ds:data

	public	store_complex,setcomplex

	public	add_complex_integer,add_integer_complex
	public	add_float_complex,add_complex_float
	public	add_rational_complex,add_complex_rational
	public	add_complex_complex

	public	mul_complex_integer,mul_integer_complex
	public	mul_float_complex,mul_complex_float
	public	mul_rational_complex,mul_complex_rational
	public	mul_complex_complex

	public	div_complex_integer,div_integer_complex
	public	div_complex_float,div_float_complex
	public	div_rational_complex,div_complex_rational
	public	div_complex_complex

	public	idiv_complex
	public	complexsetdiax

	public	addCCdisi

	public	powXcomplex,powYcomplex
	public	powYbigXcomplex
	public	powYfloat

	extrn	log_ent:near,cexp_ent:near

	public	absadd,absmax
	extrn	max_ent:near,abs_ent:near


;	public	farcomplexdivdiax


;farcomplexdivdiax:
;	call	complexdivdiax
;	retf

;complexdivdiax:
	
;	ret


store_complex:
	inc	bp
	mov	si,[calcsp]
	mov	ax,[si]
	and	ax,lenmask
	jz	store_complex_ret	;if 0#i then 0
	mov	cx,ax
	add	si,ax
	add	si,ax
	lea	di,[si+4]
	inc	cx
	std
	rep	movsw
	cld
	mov	word ptr [di],0	;real part=0
	or	ah,complexmaskhigh
	add	ax,2
	mov	[si+2],ax
store_complex_ret:
	ret


;
;* make integer to fraction
;  and cut point bit
;

slide_complex:
	push	di
	winc	di
	winc	si
	lodsw
	mov	dx,ax		;memo len

	test	ah,pointmaskhigh
	jnz	slide_cx10		;if fraction
	or	ax,ax
	jz	slide_cx15		;if 0

	push	ax
	mov	cx,[pointword]
	add	ax,cx
	stosw
	xor	ax,ax
	rep	stosw		;set 0
	pop	cx
	and	cx,lenmask
	rep	movsw
	jmp	slide_cx20

slide_cx10:
	xor	ah,pointmaskhigh	;cut pointbit
	stosw
	mov	cx,ax
	and	cx,lenmask
	rep	movsw
	jmp	slide_cx20

slide_cx15:
	stosw

slide_cx20:
	lodsw
	add	dx,ax

	test	ah,pointmaskhigh
	jnz	slide_cx110		;if fraction
	or	ax,ax
	jz	slide_cx115		;if 0
	push	ax
	mov	cx,[pointword]
	add	ax,cx
	stosw
	xor	ax,ax
	rep	stosw		;set 0
	pop	cx
	and	cx,lenmask
	rep	movsw
	jmp	slide_cx120

slide_cx110:
	xor	ah,pointmaskhigh	;cut pointbit
	stosw
	mov	cx,ax
	and	cx,lenmask
	rep	movsw
	jmp	slide_cx120

slide_cx115:
	stosw

slide_cx120:
	and	dx,lenmask
	add	dx,2
	or	dh,complexmaskhigh
	pop	di
	mov	[di],dx		;set attribute
	ret

;
;* make integer to fraction
;  and cut point bit
;

slide_real:
	lodsw
	test	ah,pointmaskhigh
	jnz	slide_re10		;if fraction
	or	ax,ax
	jz	slide_re15		;if 0
	push	ax
	mov	cx,[pointword]
	add	ax,cx
	stosw
	xor	ax,ax
	rep	stosw		;set 0
	pop	cx
	and	cx,lenmask
	rep	movsw
	ret

slide_re10:
	xor	ah,pointmaskhigh	;cut pointbit
	stosw
	mov	cx,ax
	and	cx,lenmask
	rep	movsw
	ret

slide_re15:
	stosw
	ret

;
;*  abs[si]>=1?
;   cf=1 iff not

biggerthan1?:
	lodsw
	test	ah,complexmaskhigh
	jnz	big1complex
big1re:
	test	ah,pointmaskhigh	
	jnz	big1pt
	or	ax,ax
	jz	big1no		;if 0
big1yes:
	clc
	ret

big1pt:
	and	ax,lenmask
	cmp	ax,[pointword]
	ja	big1yes
big1no:
	stc
	ret

big1complex:
	lodsw			;check real part
	test	ah,pointmaskhigh
	jnz	big1cxpt
	or	ax,ax
	jnz	big1yes		;Re is an integer>=1
	jmp	big1cx20	;Re=0
big1cxpt:
	and	ax,lenmask
	cmp	ax,[pointword]
	ja	big1yes
	add	si,ax
	add	si,ax
big1cx20:
	lodsw	
	jmp	big1re


;
;* addition of complex numbers
;

addCCdisi:
add_complex_complex:
	;reserve p1

	; use (mulwork), work2, work3

	;(a+bi) + (c+di) = (a+b) + (c+d)i
	;b, d must be non zero

	mov	[dimem_cadd],di
	mov	[simem_cadd],si

	mov	si,di
	copyimagsi	work2		;work2 = b

	mov	si,[simem_cadd]
	copyimagsi	work3		;work3 = d

	mov	di,work2
	mov	si,work3
	call	addAAdisi		;work2 = b + d

	mov	si,[simem_cadd]
	copyrealsi	work3		;work3 = c

	mov	si,[dimem_cadd]
	mov	di,work3
	add	si,2
	call	addAAdisi		;work3 = a + c

	mov	bx,[dimem_cadd]
	mov	si,work3
	mov	di,work2
	jmp	setcomplex


addRCdisi:
add_rational_complex:
	; use mulwork

	mov	ax,[si+2]	;attribute of real part
	mov	bx,di
	or	ax,ax
	test	ah,pointmaskhigh
	jnz	addRC100
	mov	ax,[pointword]
addRC100:
	call	rat2floatbxax
	jmp	add_float_complex


addCRdisi:
add_complex_rational:
	; use mulwork

	mov	ax,[di+2]	;attribute of real part
	mov	bx,si
	or	ax,ax
	test	ah,pointmaskhigh
	jnz	addCR100
	mov	ax,[pointword]
addCR100:
	call	rat2floatbxax
	jmp	add_complex_float


addCIdisi:
addCFdisi:
add_complex_integer:
add_complex_float:
	;p1 may be converted to float

	; use (mulwork), work2, work3

	;(a+bi) + c = (a+c) + bi

	mov	[dimem_cadd],di
	mov	[simem_cadd],si

	mov	si,di
	copyimagsi	work3	;work3 = b

	mov	di,[dimem_cadd]
	mov	si,[simem_cadd]
	add	di,2
	call	addAAdisi	;p0+2 = a + c

	mov	bx,[dimem_cadd]
	mov	di,work3
	lea	si,[bx+2]
	jmp	setcomplex


addICdisi:
addFCdisi:
add_integer_complex:
add_float_complex:
	;reserve p1

	; use (mulwork), work2, work3

	;c + (a+bi) = (c+a) + bi

	mov	[dimem_cadd],di
	mov	[simem_cadd],si

	mov	di,work2
	mov	bx,work3
	call	separatecopy	;work2 = a, work3 = b

	mov	di,[dimem_cadd]
	mov	si,work2
	call	addAAdisi	;p0 = a + c

	mov	bx,[dimem_cadd]
	mov	di,work3
	mov	si,bx
	jmp	setcomplex


;
;* division of complex numbers
;

div_complex_complex:

	;(a+bi)/(c+di) = (a+bi)(c-di)/(a^2+b^2)
	; use (mulwork), work2, work3, work4

	mov	[dimem_div],di
	mov	[simem_div],si

	setimagtopsi
	xor	word ptr [si],signmask	;p1 = c-di

	mov	di,[dimem_div]
	mov	si,[simem_div]

	call	mul_complex_complex	;p0 = (a+bi)(c-di)

	mov	si,[simem_div]
	mov	di,work4
	copy_si2di			;work4 = c-di

div_complex_complex100:
	mov	si,work4
	setimagtopsi
	mov	di,[simem_div]
	copy_si2di		;p1 = d

	mov	di,work4+2
	call	squareIFCdi	;work4+2 = c^2

	mov	di,[simem_div]
	call	squareIFCdi	;p1 = d^2

	mov	di,[simem_div]
	mov	si,work4+2
	call	addAAdisi	;p1 = c^2+d^2

	mov	di,[dimem_div]
	mov	si,[simem_div]
	test	word ptr [di],complexmask
	jz	godiv_float_float
	jmp	div_complex_floatin
godiv_float_float:
	jmp	divIorFdisi


div_complex_integer:
div_complex_float:
	; use mulwork

	;(a+bi)/c

	mov	[dimem_div],di
	mov	[simem_div],si

div_complex_floatin:
	mov	si,di
	copyimagsi	mulwork		;mulwork = b

	mov	di,[dimem_div]
	mov	si,[simem_div]
	add	di,2
	call	divIorFdisi		;p0+2 = a/c

	mov	si,[simem_div]
	mov	di,mulwork
	call	divIorFdisi		;mulwork = b/c

	mov	bx,[dimem_div]
	lea	si,[bx+2]
	mov	di,mulwork
	jmp	setcomplex


div_integer_complex:
div_float_complex:

	;a/(c+di) = a(c-di)/(c^2+d^2)
	; use mulwork, work2, work3, work4

	mov	[dimem_div],di
	mov	[simem_div],si

	mov	di,work4
	copy_si2di			;work4 = c+di

	mov	si,[simem_div]
	setimagtopsi
	xor	word ptr [si],signmask	;p1 = c-di

	mov	di,[dimem_div]
	mov	si,[simem_div]
	call	mul_float_complex	;p0 = a(c-di)

	jmp	div_complex_complex100


;
;* multiplications of complex numbers
;

mul_complex_integer:
mul_complex_float:
	; use (mulwork), work2

	;(a+bi) * c = ac + bci

	mov	[dimem_cmul],di
	mov	[simem_cmul],si

	mov	si,di
	copyimagsi	work2	;work2 = b

	mov	di,[dimem_cmul]
	mov	si,[simem_cmul]
	add	di,2
	call	mulAAdisi	;p0+2 = ac

	mov	si,[simem_cmul]
	mov	di,work2
	call	mulAAdisi	;work2 = bc

	mov	bx,[dimem_cmul]
	lea	si,[bx+2]
	mov	di,work2
	jmp	setcomplex


mul_integer_complex:
mul_float_complex:
	; use (mulwork), work2

	;c * (a+bi) = ac + bci

	mov	[dimem_cmul],di
	mov	[simem_cmul],si

	copyimagsi	work2	;work2 = b

	mov	si,[dimem_cmul]
	mov	di,[simem_cmul]
	add	di,2
	call	mulAAdisi	;p1+2 = ac

	mov	di,work2
	mov	si,[dimem_cmul]
	call	mulAAdisi	;work2 = bc

	mov	bx,[dimem_cmul]
	mov	si,[simem_cmul]
	add	si,2
	mov	di,work2
	jmp	setcomplex



getcomplexpointbx:
	mov	ax,[pointword]
	mov	cx,[bx+2]	;attribute of real part
	inc	ax
	test	ch,pointmaskhigh
	jz	getcpbx20
	and	cx,lenmask
	cmp	ax,cx
	jae	getcpbx20
	mov	ax,cx
getcpbx20:
	add	bx,cx
	add	bx,cx
	mov	cx,[bx]
	test	ch,pointmaskhigh
	jz	getcpbxret
	and	cx,lenmask
	cmp	ax,cx
	jae	getcpbxret
	mov	ax,cx
getcpbxret:
	ret


mul_rational_complex:
	; use (mulwork), work2

	mov	bx,si
	call	getcomplexpointbx
	mov	bx,di
	call	rat2floatbxax
	jmp	mul_float_complex

mul_complex_rational:
	; use (mulwork), (work2)

	mov	bx,di
	call	getcomplexpointbx
	mov	bx,si
	call	rat2floatbxax
	jmp	mul_complex_float



mul_complex_complex:
	;reserve c+di
	; use (mulwork), work2, work3, work4

	;(a+bi) * (c+di) = (ac-bd) + (ad+bc)i

	mov	[dimem_cmul],di
	mov	[simem_cmul],si

	copyimagsi	work2	;work2 = d

	mov	si,[dimem_cmul]
	copyrealsi	work3	;work3 = a

	mov	di,work2
	mov	si,work3
	call	mulAAdisi	;work2 = ad

	mov	si,[dimem_cmul]
	copyimagsi	work3	;work3 = b

	mov	si,[simem_cmul]
	copyrealsi	work4	;work4 = c

	mov	di,work3
	mov	si,work4
	call	mulAAdisi	;work3 = bc

	mov	di,work2
	mov	si,work3
	call	addAAdisi	;work2 = ad+bc

	mov	si,[dimem_cmul]
	copyrealsi	work3	;work3 = a

	mov	di,work4
	mov	si,work3
	call	mulAAdisi	;work4 = ac

	mov	si,[simem_cmul]
	copyimagsi	work3	;work3 = d

	mov	si,[dimem_cmul]
	mov	di,si
	setimagtopsi
	copy_si2di		;p0 = b

	mov	di,[dimem_cmul]
	mov	si,work3
	call	mulAAdisi	;p0 = bd

	mov	di,work4
	mov	si,[dimem_cmul]
	call	subAAdisi	;work4 = ac-bd

	mov	bx,[dimem_cmul]
	mov	di,work2
	mov	si,work4
	jmp	setcomplex


;
;* integer divsions of complex numbers
;

idiv_complex:			
	;[calcsp] \= [next calcsp]

	; use mulwork, work2

	; (a+bi) \ c = a\c + b\c i
	; resadr = a@c + b@c i

	setsp0	si
	mov	di,mulwork
	mov	bx,work2
	call	separatecopy	;mulwork = a, work2 = b

	mov	di,work2
	setsp1	si
	call	idivIIdisi	;work2 = b \ c

	cmove3	0,resadr	;reserve remainder

	mov	di,mulwork
	setsp1	si
	call	idivIIdisi	;mulwork = a \ c

	mov	si,[calcsp]
	lodsw
	or	ax,ax
	jz	idivcxresout	;if reserved remainder = 0

	cmove3	1,resadr
	mov	bx,resadr
	setsp1	si		;real
	setsp0	di		;imag
	call	setcomplex	;set RESADR=SP1+SP0*#i

idivcxresout:
	mov	si,mulwork	;real
	mov	di,work2	;imag
	jmp	setcomplex0


;
; * set COMPLEX NUMBER
;   set in [BX](BX=[calcsp])
;   real = [SI]
;   imag = [DI]

setcomplex0:
	mov	bx,[calcsp]
setcomplex:
	mov	ax,[di]
	or	ax,ax
	jz	setcomplexreal

	push	di		;*
	lea	di,[bx+2]
	mov	cx,[si]
	and	cx,lenmask
	inc	cx
	mov	ax,cx

	cmp	si,bx
	jne	setcomplex30
	add	si,cx
	add	si,cx
	mov	di,si		;dst MSW
	mov	dx,si		;memo
	sub	si,2		;src MSW
	std
	rep	movsw
	cld
	mov	di,dx
	add	di,2
	jmps	setcomplex50

setcomplex30:
	rep	movsw
setcomplex50:
	pop	si		;*
	mov	cx,[si]
	and	cx,lenmask
	inc	cx
	add	ax,cx
	rep	movsw
	or	ah,complexmaskhigh
	mov	[bx],ax
	ret

setcomplexreal:
	mov	cx,[si]
	and	cx,lenmask
	inc	cx
	mov	di,bx
	rep	movsw
	ret

;
;
;

powYbigXcomplex:
	mov	si,[pmem]
	mov	cx,[si]
	add	si,cx
	add	si,cx		;highest adr
	mov	bx,[si]
	cmp	bx,1
	je	powbigx10
	push	cx
	push	si
	call	complexpow_main	;1st word
	pop	si
	pop	cx
powbigx10:
	dec	cx
	wdec	si
powbigxlp:			;other words
	push	cx
	push	si
	mov	cx,16
	mov	bx,[si]
	call	complexpow_main2
	pop	si
	wdec	si
	pop	cx
	myloop	powbigxlp

	add	[calcsp],unitbyte
	ret


;
;* X^Y
; X:complex, Y:16bit integer

powXcomplex:
	AND	CX,LENMASK
	INC	CX
	REP	MOVSW

;  main part  [DI]=[DI]^BX

complexpow_main:
	MOV	CX,16		;get msbit
	or	bh,bh
	jnz	complexpowm10
	mov	cx,8
	xchg	bl,bh
complexPOWM10:
	SHL	BX,1
	DEC	CX
	JNC	complexPOWM10

complexpow_main2:
	call ahedsp
	call ahedsp

complexPOWMLP:
	PUSH	CX
	MOV	DI,[XMEM]	;X=X^2
	push	bx
	call	squareCdi
	pop	bx
	SHL	BX,1
	JNC	complexPOWM30

	MOV	DI,[XMEM]	;X=X*Y
	MOV	SI,[YMEM]
	PUSH	BX
	CALL	complexMULDISI
	POP	BX
complexPOWM30:
	POP	CX
	myloop	complexPOWMLP

	add	[calcsp],unitbyte*2	;call backsp:call backsp
	RET			;done all


squareCdi:
	mov	si,di

	;complex multiplication
	;destroy [calcsp] area 1 more level

complexmuldisi:
	push	di
	mov	di,[calcsp]
	sub	di,unitbyte
	push	di
	copy_si2di
	pop	si
	pop	di
	jmp	mulAAdisi

;
; power routine X^Y
; for Y=float
;     Y=complex

powYcomplex:
powYfloat:
	setsp0	si		;exchange X and Y
	setsp1	di
	call	xchgsidi

	sub	[calcsp],unitbyte
	call	log_ent		;log(x) in (+2)

	call	mulin
	jmp	cexp_ent	;call & ret


;
; convert ax to float pure imaginary and set on [di]
; ax is treated as signed int
;

setcdiaxset0:
	mov	[di],ax
	ret

complexsetdiax:
	or	ax,ax
	jz	setcdiaxset0
	mov	dx,[pointword]
	mov	cx,dx
	add	dx,3
	or	dh,complexmaskhigh
	mov	[di],dx
	add	di,2
	mov	word ptr [di],0		;real part = 0
	add	di,2
	mov	dx,cx
	inc	dx
	or	ax,ax
	jg	complexsetjp		;if positive
	neg	ax
	or	dh,signmaskhigh
complexsetjp:
	or	dh,pointmaskhigh
	mov	[di],dx
	add	di,2

	mov	dx,ax
	or	ah,ah
	jnz	setcdiaxword
setcdiaxbyte:
	mov	word ptr [di],1		;bias
	add	di,2
	xor	ax,ax
	rep	stosw
	mov	[di-1],dl
	ret
setcdiaxword:
	mov	word ptr [di],2		;bias
	add	di,2
	dec	cx
	xor	ax,ax
	rep	stosw
	mov	[di],dx
	ret


;
; * absmax
;  max{abs(Re Z),abs(Im Z)}
;
absilgerr:
	jmp	ilgerr

absmax:
	call	kakko
	mov	si,[calcsp]
	lodsw
	test	ah,nonnumericmaskhigh
	jnz	absilgerr
	test	ah,complexmaskhigh
	jz	go_realabs

	call	ahedsp
	mov	di,si
	add	si,unitbyte+2
	lodsw
	and	ah,7fh		;cut sgn bit
	stosw
	and	ax,lenmask
	mov	cx,ax
	rep	movsw		;set real part

	mov	di,[calcsp]
	add	di,unitbyte
	lodsw
	and	ah,7fh		;cut sgn bit
	stosw
	and	ax,lenmask
	mov	cx,ax
	rep	movsw		;set real part
	jmp	max_ent		;call & ret

go_realabs:
	jmp	abs_ent		;normal abs

;
; * absadd
;  abs(Re Z)+abs(Im Z)
; use work2

absaddilgerr:
	jmp	ilgerr

absadd:
	call	kakko
	mov	si,[calcsp]
	mov	di,si
	lodsw
	test	ah,nonnumericmaskhigh
	jnz	absaddilgerr
	test	ah,complexmaskhigh
	jz	go_realabs

	mov	cx,[si]
	add	si,2
	and	cx,signmaskCPL
	mov	[di],cx
	add	di,2
	and	cx,lenmask
	rep	movsw

	mov	di,work2	;copy abs of im part to work2
	mov	cx,[si]
	add	si,2
	and	cx,signmaskCPL
	mov	[di],cx
	add	di,2
	and	cx,lenmask
	rep	movsw

	mov	di,[calcsp]
	mov	si,work2
	jmp	addAAdisi


code	ends
