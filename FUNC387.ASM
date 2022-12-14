
longdblbyte	equ	10
longdblbyte2	equ	8
longdblbias	equ	3fffh

data	segment	word public

	align	2
longdblbuffer	db	longdblbyte2 dup(?)
longdblexponent	dw	1

data	ends


code2	segment	public
	assume	cs:code2,ds:data


f2ldset0:
	mov	di,offset longdblbuffer
	mov	cx,longdblbyte/2
	xor	ax,ax
	rep	stosw
	ret


getlongdblovererr:
	jmp	func3ovrerr
getlongdblilgerr:
	jmp	func3ilgerr

getlongdbl:
	call	far ptr farkakko
	mov	si,[calcsp]
	mov	ah,[si+1]
	test	ah,nonnumericmaskhigh
	jnz	getlongdblilgerr
	test	ah,complexmaskhigh
	jnz	flogilgerr
	call	far ptr farall2float0
	mov	si,[calcsp]

ubfloat2longdbl:
	;[si] -> [longdblbuffer]

	mov	dx,[si]
	or	dx,dx
	jz	f2ldset0
	mov	ax,[si+2]
	cmp	ax,0f801h
	jle	f2ldset0
	cmp	ax,0800h
	jge	getlongdblovererr

	push	dx
	push	ax

	and	dx,lenmask
	mov	di,offset longdblexponent-1
	add	dx,dx
	add	si,dx
	sub	dx,2
	cmp	dx,longdblbyte2
	jbe	f2ld10
	mov	dx,longdblbyte2
f2ld10:
	std
	mov	al,[si+1]
	xor	cx,cx
f2ld20:
	inc	cx
	shl	al,1
	jnc	f2ld20
	dec	cx
	mov	bx,cx		;memo cx

	mov	ch,dl
	add	cl,8		;more 8 bits rolling
f2ldlp:				;copy mantissa
	mov	ax,[si]
	dec	si
	rol	ax,cl
	stosb
	dec	ch
	jnz	f2ldlp

	sub	dx,longdblbyte2
	jae	f2ld50
	neg	dx
	mov	cx,dx
	xor	ax,ax
	rep	stosb
f2ld50:
	cld
	pop	dx
	sal	dx,3		;* 8
	sub	dx,bx
	dec	dx
	add	dx,longdblbias
	pop	ax		;*/
	and	ax,signmask
	or	ax,dx
	mov	[longdblexponent],ax	;set exponent and sign
	ret



longdblset0:
	mov	word ptr [di],0
	ret
longdblovererr:
	jmp	func3ovrerr


longdbl2ubfloat:

	;[longdblbuffer] -> [calcsp]

	mov	di,[calcsp]

	mov	ax,[longdblexponent]
	and	ax,7fffh
	jz	longdblset0
	cmp	ax,7fffh
	je	longdblovererr

	push	di		;/*

	mov	si,offset longdblexponent
	add	di,longdblbyte
	std
	mov	ax,[si]
	mov	cx,ax
	and	cx,7fffh	;cut sign
	sub	cx,longdblbias
	inc	cx
	and	cx,111b
	jz	ld2f50

	mov	ch,longdblbyte2
	sub	cl,8
	neg	cl
	dec	si
	inc	di
	xor	ax,ax
	mov	al,[si]
ld2flp:				;copy mantissa
	shr	ax,cl
	stosb
	dec	si
	mov	ax,[si]
	dec	ch
	jnz	ld2flp
	jmps	ld2f60

ld2f50:
	sub	si,2
	mov	cx,4
	rep	movsw

ld2f60:
	cld

	pop	di		;*/
	mov	ax,[longdblexponent]
	mov	dx,ax
	and	ax,8000h	;get sign
	or	ax,pointmask
	add	ax,5
	mov	[di],ax		;set attribute

	and	dx,7fffh	;cut sign
	sub	dx,longdblbias
	sar	dx,3		;/ 8
	inc	dx

	mov	[di+2],dx	;set offset
	ret


;
;
flogilgerr:
	jmp	func3ilgerr


flog:
	call	getlongdbl
	test	byte ptr [longdblexponent+1],80h	;check sign
	jnz	flogilgerr
	fldln2
	fld	tbyte ptr [longdblbuffer]
	fyl2x
	fstp	tbyte ptr [longdblbuffer]
	call	longdbl2ubfloat
	jmp	far ptr returnadr

flog2:
	call	getlongdbl
	test	byte ptr [longdblexponent+1],80h	;check sign
	jnz	flogilgerr
	fld1
	fld	tbyte ptr [longdblbuffer]
	fyl2x
	fstp	tbyte ptr [longdblbuffer]
	call	longdbl2ubfloat
	jmp	far ptr returnadr

flog10:
	call	getlongdbl
	test	byte ptr [longdblexponent+1],80h	;check sign
	jnz	flogilgerr
	fldlg2
	fld	tbyte ptr [longdblbuffer]
	fyl2x
	fstp	tbyte ptr [longdblbuffer]
	call	longdbl2ubfloat
	jmp	far ptr returnadr


fcos:
	call	getlongdbl
	fld	tbyte ptr [longdblbuffer]
	db	11011001b,11111111b		;= fcos
	fstp	tbyte ptr [longdblbuffer]
	call	longdbl2ubfloat
	jmp	far ptr returnadr

fsin:
	call	getlongdbl
	fld	tbyte ptr [longdblbuffer]
	db	11011001b,11111110b		;= fsin
	fstp	tbyte ptr [longdblbuffer]
	call	longdbl2ubfloat
	jmp	far ptr returnadr


fsqrt:
	call	getlongdbl
	test	byte ptr [longdblexponent+1],80h	;check sign
	jnz	flogilgerr
	fld	tbyte ptr [longdblbuffer]
	fsqrt
	fstp	tbyte ptr [longdblbuffer]
	call	longdbl2ubfloat
	jmp	far ptr returnadr


ftan:
	call	getlongdbl
	fld	tbyte ptr [longdblbuffer]
	db	11011001b,11110010b		;= fptan
	db	11011001b,11111001b		;= fdivp
	fstp	tbyte ptr [longdblbuffer]
	call	longdbl2ubfloat
	jmp	far ptr returnadr

fatan:
	call	getlongdbl
	fld	tbyte ptr [longdblbuffer]
	fld1
	db	11011001b,11110011b		;= fpatan
	fstp	tbyte ptr [longdblbuffer]
	call	longdbl2ubfloat
	jmp	far ptr returnadr


code2	ends
