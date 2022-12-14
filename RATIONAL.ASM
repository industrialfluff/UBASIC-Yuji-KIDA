;rational.asm


code	segment	public
	assume	cs:code,ds:data


	public	add_integer_rational,add_rational_integer
	public	add_rational_rational
	public	mul_integer_rational,mul_rational_integer
	public	mul_rational_rational
	public	div_integer_rational,div_rational_integer
	public	ratdivin,setrational
	public	farRatdiv_calcsp
	public	powXrational,powYbigXrational


	extrn	getgcd:near,fargetgcd:far
	extrn	pow_main:near
	extrn	overloadratdiv:near

;
;* arithmetic and functions for
;  rational numbers


;
;* rational division
;

farRatdiv_calcsp:
	mov	di,[calcsp]
	lea	si,[di-unitbyte]
	call	ratdiv_nobacksp
	retf

ratdiv_ilgerr:
	jmp	ilgerr

ratdivret:
	ret

ratdivby0:
	jmp	diverr

ratdivin:
	call	backsp
ratdiv_nobacksp:
	mov	ax,[di]
	mov	dx,[si]
	or	ax,ax
	jz	ratdivret
	or	dx,dx
	jz	ratdivby0

	mov	al,ah
	mov	ah,dh
	and	ax,attribmaskdouble

ratdiv_data_types	equ	4

ratdiv_others:
	xor	bx,bx
	or	al,al
	jz	ratdivextra20		;[di] is integer
	add	bx,3*ratdiv_data_types
	cmp	al,ratmaskhigh
	je	ratdivextra20
	sub	bx,2*ratdiv_data_types
	cmp	al,pointmaskhigh
	je	ratdivextra20
	add	bx,ratdiv_data_types
	cmp	al,complexmaskhigh
	jne	ratdiv_etc

ratdivextra20:
	or	ah,ah
	jz	ratdivextra40
	add	bx,3
	cmp	ah,ratmaskhigh
	je	ratdivextra40
	sub	bx,2
	cmp	ah,pointmaskhigh
	je	ratdivextra40
	inc	bx
	cmp	ah,complexmaskhigh
	jne	ratdiv_etc2

ratdivextra40:
	add	bx,bx
	jmp	cs:[ratdiv_table+bx]

go_ratdiv_poly1:
	jmp	far ptr ratdiv_pl	;poly // any
go_ratdiv_modpoly1:
	jmp	far ptr ratdiv_mpl	;poly // any
go_ratdiv_ratfunc1:
	jmp	far ptr ratdiv_rf
go_ratdiv_overload:
	jmp	overloadratdiv

ratdiv_etc:
	cmp	al,packmaskhigh
	je	go_ratdiv_overload
	cmp	ah,packmaskhigh
	je	go_ratdiv_overload

	cmp	al,polymaskhigh
	je	go_ratdiv_poly1
	cmp	al,modpolymaskhigh
	je	go_ratdiv_modpoly1
	cmp	al,ratpolymaskhigh
	je	go_ratdiv_ratfunc1
	jmp	ilgerr

ratdiv_etc2:
	cmp	ah,polymaskhigh
	je	go_ratdiv_poly2		;[si] is poly
	cmp	ah,modpolymaskhigh
	je	go_ratdiv_modpoly2	;[si] is modpoly
	cmp	ah,ratpolymaskhigh
	je	go_ratdiv_ratfunc2	;[si] is modpoly
	cmp	ah,packmaskhigh
	je	go_ratdiv_overload	;[si] is pack
ratdivilg:
	jmp	ilgerr

go_ratdiv_poly2:
	jmp	far ptr ratdiv_numpl	;num // poly
go_ratdiv_modpoly2:
	or	al,al
	jnz	ratdivilg
	jmp	far ptr ratdiv_intmpl	;int // mpl
go_ratdiv_ratfunc2:
	jmp	far ptr div_numrf	;num // rf


even
ratdiv_table	label	word
	dw	ratdiv_integer_integer,div_integer_float
	dw	div_integer_complex,ratdiv_integer_rational

	dw	div_float_integer,div_float_float
	dw	div_float_complex,div_float_rational

	dw	div_complex_integer,div_complex_float
	dw	div_complex_complex,div_complex_rational

	dw	ratdiv_rational_integer,div_rational_float
	dw	div_rational_complex,ratdiv_rational_rational

	;
	;* rational division main routines
	;  for each data type
	;

ratdiv_integer_integer:
	call	reducedisi
	call	positivedisi_calcsp
setrational:
	mov	di,[calcsp]
	lea	si,[di-unitbyte]
	mov	cx,[si]
	and	cx,lenmask
	cmp	cx,1
	jne	setrat20
	cmp	word ptr [si+2],1
	je	setratret	;if den=1
setrat20:
	inc	cx
	mov	bx,[di]
	and	bx,lenmask
	inc	bx
	mov	ax,bx
	add	ax,cx
	cmp	ax,limitword
	ja	setratovr
	add	di,ax
	add	si,cx
	add	di,ax		;highest word adr
	add	si,cx
	sub	si,2
	std
	rep	movsw
	lea	si,[di-2]
	mov	cx,bx
	rep	movsw
	or	ah,ratmaskhigh
	stosw
	cld
setratret:
	ret

setratovr:
	jmp	ovrerr

ratdiv_rational_integer:
	;use mulwork,work2

	;(a//b)//c = a//(b*c)

	mov	si,di
	mov	bx,work2
	call	separatecopy	;st0 = a, work2 = b

	setsp0	di
	setsp1	si

	call	reducedisi

	setsp1	di
	mov	si,work2
	call	mulIIdisi	;st1 = bc

	call	positivedisi_calcsp

	jmp	setrational


ratdiv_integer_rational:
	;use mulwork, work2

	; c//(a//b) = bc//a

	mov	di,si
	mov	bx,work2
	call	separatecopy	;st1 = a, work2 = b

	setsp0	di
	setsp1	si
	call	reducedisi

	setsp0	di
	mov	si,work2
	call	mulIIdisi	;st0 = bc

	call	positivedisi_calcsp

	jmp	setrational


ratdiv_rational_rational:
	;use mulwork, work2, work3, work4
	;no more calc stack

	; (a//b) // (c//d) = ad//bc

	setsp1	si
	mov	di,si
	mov	bx,work4
	call	separatecopy	;st1 = c, work4 = d
	setsp1	si
	mov	di,work4
	call	positivedisi
	jmp	mul_rational_rational_in


positivedisi_calcsp:
	mov	di,[calcsp]
	lea	si,[di-unitbyte]
positivedisi:
	;[si] = sgn(si) * [si]	i.e. positive
	;[di] = sgn(si) * [di]

	;[di] must be non zero

	mov	ax,signmask
	test	[si],ax
	jz	positiveret
	xor	[si],ax
	xor	[di],ax
positiveret:
	ret

;


add_rational_integer:
	;use mulwork, work2

	; a//b + c = (a+bc)//b

	setsp1	si
	mov	di,work2
	copy_si2di		;work2 = c

	setsp0	si
	mov	di,si
	setsp1	bx
	call	separatecopy	;st0 = a, st1 = b

	mov	di,work2
	setsp1	si
	call	mulIIdisi	;work2 = bc

add_rational_integer_in:
	setsp0	di
	mov	si,work2
	call	addIIdisi

	jmp	setrational

add_integer_rational:
	;use mulwork, work2

	; c + a//b = (bc+a)//b

	setsp1	si
	mov	di,work2
	mov	bx,si
	call	separatecopy	;work2 = a, st1 = b

	setsp0	di
	setsp1	si
	call	mulIIdisi	;st0 = bc

	jmp	add_rational_integer_in


add_rational_rational:
	;use mulwork, work2, work3, work4
	;no more calc stack

	; a//b + c//d = (ad+bc)//bd

	setsp0	si
	mov	di,si
	mov	bx,work2
	call	separatecopy	;st0 = a, work2 = b

	setsp1	si
	mov	di,si
	mov	bx,work4
	call	separatecopy	;st1 = c, work4 = d

	mov	di,work2
	mov	si,work4
	call	reducedisi	;g=gcd(b,d), work2=b/g, work4=d/g

	setsp0	di
	mov	si,work4
	call	mulIIdisi	;st0 = ad/g

	setsp1	di
	mov	si,work2
	call	mulIIdisi	;st1 = bc/g

	setsp0	di
	lea	si,[di-unitbyte]
	call	addIIdisi	;st0 = (ad+bc)/g

	mov	di,work2
	mov	si,work4
	call	mulIIdisi	;work2 = b/g * d/g

	mov	si,work2
	setsp1	di
	copy_si2di		;st1 = b/g * d/g

	mov	si,work3	;GCDADR
	cmp	word ptr [si],1	;check g
	jne	addratgcdnot1
	cmp	word ptr [si+2],1
	je	addratgcdeq1
addratgcdnot1:
	copyF	work3,work2	;GCDADR, work2 = g
	setsp0	di
	mov	si,work2
	call	reducedisi	;work3= gnew= gcd((ad+bc)/g, g)
				;st0= (ad+bc)/g/gnew, work2 = g/gnew
	setsp1	di
	mov	si,work2
	call	mulIIdisi	;st1 = b/g * d/g * g/gnew

addratgcdeq1:
	jmp	setrational	;den = st0, num = st1


;
;* copy rational/complex separately
;  [si]_1 -> [di]
;  [si]_2 -> [bx]

separatecopy:
	mov	cx,[si+2]
	add	si,4
	mov	[di],cx
	add	di,2
	and	cx,lenmask
	rep	movsw
	mov	di,bx
	mov	cx,[si]
	add	si,2
	mov	[di],cx
	add	di,2
	and	cx,lenmask
	rep	movsw
	ret


;
;* get gcd and reduce [di], [si]
;  gcd returns in work3

reducedisi:
	push	si
	push	di

	call	getgcd
	mov	si,work3	;GCDADR
	cmp	word ptr [si],1
	jne	reduce10
	cmp	word ptr [si+2],1
	jne	reduce10
	add	sp,4		;cancel push*2
	ret

reduce10:
	pop	di
	MOV	SI,work3	;GCDADR
	call	idivIIdisi

	pop	di
	MOV	SI,work3	;GCDADR
	jmp	idivIIdisi	;call & ret


mul_integer_rational:
	;use mulwork, work2, work3

	; c * (a//b)

	setsp1	si
	mov	di,work2
	mov	bx,si
	call	separatecopy	;work2 = a, st1 = b

	setsp0	di
	setsp1	si
	call	reducedisi	;g=gcd(c,b), st0=c/g, st1=b/g

	setsp0	di
	mov	si,work2
	call	mulIIdisi	;st0 = c * a

	jmp	setrational


mul_rational_integer:
	;use mulwork, work2, work3

	; (a//b) * c

	setsp1	si
	mov	di,work2
	copy_si2di		;work2 = c

	setsp0	si
	mov	di,si
	setsp1	bx
	call	separatecopy	;st0 = a, st1 = b

	mov	di,work2
	setsp1	si
	call	reducedisi	;g=gcd(c,b), work2=c/g, st1=b/g

	setsp0	di
	mov	si,work2
	call	mulIIdisi	;st0 = a * c

	jmp	setrational


mul_rational_rational:
	;use mulwork, work2, work3, work4
	;no more calc stack

	; a//b * c//d = ac//bd

	setsp1	si
	mov	di,work4
	mov	bx,si
	call	separatecopy	;work4 = c, st1 = d

mul_rational_rational_in:	;jumped from ratdiv_rational_rational
	setsp0	si
	mov	di,si
	mov	bx,work2
	call	separatecopy	;st0 = a, work2 = b

	setsp0	di
	setsp1	si
	call	reducedisi	;g=gcd(a,d), st0=a/g, st1=d/g

	mov	di,work2
	mov	si,work4
	call	reducedisi	;g=gcd(b,c), work2=b/g, work4=c/g

	setsp0	di
	mov	si,work4
	call	mulIIdisi	;st0 = ac

	setsp1	di
	mov	si,work2
	call	mulIIdisi	;st1 = bd

	jmp	setrational	;den = st0, num = st1


;
;* power
;

powXrational:
	; use mulwork, work2

	;(a//b)^y = a^y//b^y

	push	bx		;bx = y

	setsp0	si
	mov	di,si
	lea	bx,[si-unitbyte]	;st0 = a, st1 = b
	call	separatecopy

	mov	si,[calcsp]
	mov	[xmem],si
	mov	di,work2
	mov	[ymem],di	;work area
	copy_si2di
	pop	bx
	push	bx
	call	pow_main	;st0 = a^y

	setsp1	si
	mov	di,work2
	mov	[calcsp],si
	mov	[xmem],si
	copy_si2di
	pop	bx
	call	pow_main	;st1 = b^y
	add	[calcsp],unitbyte
	jmp	setrational

powbigover:
	jmp	ovrerr

powYbigXrational:
	;if abs(x)<1 then return 0
	;         >1 then overflow

	lodsw
	and	ax,lenmask
	mov	cx,ax		;len of num
	add	ax,ax
	add	si,ax
	lea	di,[si-2]	;di=high adr of num
	mov	ax,[si]
	and	ax,lenmask
	cmp	ax,cx
	ja	powbigset0	;if den>num
	jb	powbigover	;if den<num
	add	ax,ax
	add	si,ax		;si=high adr of den
	std
	repe	cmpsw
	cld
	jb	powbigover	;if den<num
powbigset0:			;if den>num(no case of den=num)
	mov	si,[calcsp]
	mov	word ptr [si],0
	ret



;
;* rational to integer by omitting fractional part
;  subroutine called from int,fix,round,ceil

; out	dh : includes sign bit
;	al : 0 iff frac part = 0
;	ah : MSB of frac (valid iff dl<>0)
; reserve bx

rat2intfix:
	; use mulwork

	; a//b = fix(a/b)

	push	bx

	setsp0	si
	mov	di,si
	mov	bx,mulwork
	call	separatecopy	;st0 = a, work2 = b

	cshl	0		;st0 = 2a

	mov	si,[calcsp]
	mov	ax,[si]
	push	ax		;attribute

	and	ah,signmaskhighCPL
	mov	[si],ax		;let be positive

	mov	di,si
	mov	si,mulwork
	call	idivIIdisi	;st0 = 2a\b

	mov	si,[calcsp]
	cmp	word ptr [si],0
	je	rat2intans0	;if ans = 0

	mov	ax,ds:[resadr]
	or	al,ah		;al = 0 iff remainder = 0
	mov	ah,[si+2]
	ror	ah,1
	and	ah,80h
	or	al,ah
	push	ax
	mov	di,[calcsp]
	call	ISHIFTRIGHT_di
	pop	ax
	pop	dx
	test	dh,signmaskhigh
	jz	rat2intret
	mov	si,[calcsp]
	cmp	word ptr [si],0
	je	rat2intret
	or	byte ptr [si+1],signmaskhigh	;let be negative
rat2intret:
	pop	bx
	ret

rat2intans0:
	mov	ax,00001h	;no carry from frac but nonzero frac
	pop	dx		;pop attribute
	pop	bx
	ret



code	ends
