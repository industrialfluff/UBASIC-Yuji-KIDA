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

	mov	di,[calcsp]		;stack0 = x/2
	mov	ax,2
	call	far ptr farfloatdivdiax

	copyF	[calcsp],work3		;work3 = (x/2)^2
	mov	di,work3
	call	far ptr farsquareFdi

	mov	ax,[fdiv1]
	or	ax,ax
	jnz	bessel50

	mov	di,[calcsp]		;stack0 = 1.0
	mov	ax,1
	call	far ptr farfloatsetdiax
	jmps	bessel60

bessel50:
	mov	di,[calcsp]		;stack0 = (x/2)^k
	mov	ax,[fdiv1]
	call	far ptr farpowerFFdiax

	mov	di,work2		;work2 = k!
	mov	ax,[fdiv1]
	call	far ptr farfactorialFFdiax

	mov	di,[calcsp]		;stack0 = (x/2)^k/k!
	mov	si,work2
	call	far ptr fardivIorFdisi

bessel60:
	copyF	[calcsp],work2		;stack0 = work2 = term_0

	mov	di,work2		;work2 = term_1
	mov	si,work3
	call	far ptr farmulAAdisi

	mov	[fdivnum],2
	mov	[fdivstep],1
	inc	[fdiv1]
	mov	[fdiv2],1
	mov	[freserve],0
	call	far ptr farseries
	jmp	far ptr returnadr

