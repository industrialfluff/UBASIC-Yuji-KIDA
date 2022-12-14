;ratfunc.asm
;
; rational functions

code	segment	public
	assume	cs:code,ds:data

	extrn	print_calcsp_out:near
	extrn	fargcd_calcsp:far


;
; * memory allocation
;
;	inp  ax : number of variables
;	out  bx : base segment

memoryalloc1:
	mov	bx,unitseg
	mul	bx
	mov	bx,[arrayseg]
	add	ax,bx
	cmp	ax,[limitseg]
	jae	malloc1over
	mov	[arrayseg],ax
	ret
malloc1over:
	jmp	calcsperr

;
; * memory free
;
;	inp  ax : number of variables

memoryfree1:
	mov	bx,unitseg
	mul	bx
	sub	[arrayseg],ax
	ret


xputsub1:
	push	es
	add	ax,bx
	xor	di,di
	mov	es,ax
	mov	cx,[si]
	add	si,2
	mov	es:[di],cx
	add	di,2
	and	cx,lenmask
	rep	movsw
	pop	es
	ret

xgetsub1:
	push	ds
	add	ax,bx
	xor	si,si
	mov	ds,ax
	mov	cx,[si]
	add	si,2
	mov	es:[di],cx
	add	di,2
	and	cx,lenmask
	rep	movsw
	pop	ds
	ret


code	ends


code2	segment	public
	assume	cs:code2,ds:data


	public	printratpoly
	public	add_rf,sub_rf
	public	mul_rf,div_rf,ratdiv_rf
	public	add_numrf,sub_numrf,mul_numrf,div_numrf
	public	farcompare_any
	public	memoryalloc,memoryfree,xputsub


;
;* compare any data
;  non destructive
;  si ,di : addresses
farcompareilg:
	jmp	far ptr systemerr

farcompare_any:
	add	[calcsp],unitbyte

	cmp	di,[calcsp]
	jne	farcompareilg
	lea	bx,[di-unitbyte]
	cmp	bx,si
	jne	farcompareilg

	mov	ax,2
	call	memoryalloc

	xput	xa,0			;reserve
	xput	xb,1			;
	xsub

	mov	si,[calcsp]
	cmp	word ptr [si],0
	pushf
	xget	0,xa
	xget	1,xb

	mov	ax,2
	call	memoryfree
	sub	[calcsp],unitbyte
	popf
	retf


;
; * check calcsp = const
;
isconst_calcsp:
	mov	si,[calcsp]
	mov	ax,[si]
	and	ah,attribmaskhigh
	jz	yesconst
	cmp	ah,polymaskhigh
	je	checkdegreepoly
	cmp	ah,modpolymaskhigh
	je	checkdegreemodpoly
	test	ah,nonnumericmaskhigh
	jnz	notconst
yesconst:
	xor	ax,ax		;set ZF
	ret
notconst:
	xor	ax,ax
	dec	ax		;reset ZF
	ret
checkdegreepoly:
	cmp	word ptr [si+2],1	;check degree = 0?
	ret
checkdegreemodpoly:
	cmp	word ptr [si],modpolymask+2	;check degree = 0?
	ret


;
; * memory allocation
;
;	inp  ax : number of variables
;	out  bx : base segment

memoryalloc:
	mov	bx,unitseg
	mul	bx
	mov	bx,[arrayseg]
	add	ax,bx
	cmp	ax,[limitseg]
	jae	mallocover
	mov	[arrayseg],ax
	ret
mallocover:
	jmp	far ptr calcsperr

;
; * memory free
;
;	inp  ax : number of variables

memoryfree:
	mov	bx,unitseg
	mul	bx
	sub	[arrayseg],ax
	ret

xreducesub:
	push	bp
	mov	bp,sp
	push	dx
	push	cx
	push	ax

	mov	di,[calcsp]
	call	xgetsub		;xget 0,xa
	mov	di,[calcsp]
	mov	ax,[bp-4]
	sub	di,unitbyte
	call	xgetsub		;xget 1,xb
	push	bx
	call	far ptr fargcd_calcsp
	pop	bx
	call	isconst_calcsp
	je	xreducegcd1	;if gcd is constant

;	call	integerpoly_calcsp
;	call	normalizepoly_calcsp

	mov	si,[calcsp]
	mov	ax,[bp-2]
	call	xputsub		;xput xg,0

	mov	di,[calcsp]
	mov	ax,[bp-6]
	call	xgetsub		;xget 0,xa
	mov	di,[calcsp]
	mov	ax,[bp-2]
	sub	di,unitbyte
	call	xgetsub		;xget 1,xg
	xidiv
	mov	si,[calcsp]
	mov	ax,[bp-6]
	call	xputsub		;xput xa,0

	mov	di,[calcsp]
	mov	ax,[bp-4]
	call	xgetsub		;xget 0,xb
	mov	di,[calcsp]
	mov	ax,[bp-2]
	sub	di,unitbyte
	call	xgetsub		;xget 1,xg
	xidiv
	mov	si,[calcsp]
	mov	ax,[bp-4]
	call	xputsub		;xput xb,0

xreduce100:
	mov	sp,bp
	pop	bp
	ret

xreducegcd1:			;set gcd = 1
	push	ds
	mov	ax,[bp-2]
	add	ax,bx
	mov	ds,ax
	xor	si,si
	mov	ax,1
	mov	[si],ax
	mov	[si+2],ax
	pop	ds
	jmp	xreduce100


xputbothsub:
	push	es
	add	ax,bx
	xor	di,di
	mov	es,ax
	add	si,2
	mov	cx,[si]
	add	si,2
	mov	es:[di],cx
	add	di,2
	and	cx,lenmask
	rep	movsw

	add	dx,bx
	xor	di,di
	mov	es,dx
	mov	cx,[si]
	add	si,2
	mov	es:[di],cx
	add	di,2
	and	cx,lenmask
	rep	movsw
	pop	es
	ret

xputsub:
	push	es
	add	ax,bx
	xor	di,di
	mov	es,ax
	mov	cx,[si]
	add	si,2
	mov	es:[di],cx
	add	di,2
	and	cx,lenmask
	rep	movsw
	pop	es
	ret

xgetsub:
	push	ds
	add	ax,bx
	xor	si,si
	mov	ds,ax
	mov	cx,[si]
	add	si,2
	mov	es:[di],cx
	add	di,2
	and	cx,lenmask
	rep	movsw
	pop	ds
	ret


neg_rfsi:
	add	si,2
	mov	ax,[si]
	and	ax,attribmask
	cmp	ax,polymask
	jne	neg_rf_mpl
neg_rf_pl:
	jmp	neg_polysi	;call & ret
neg_rf_mpl:
	jmp	neg_modpolysi	;call & ret


sub_rfrf:
	mov	si,[calcsp]
	sub	si,unitbyte
	mov	[calcsp],si
	call	neg_rfsi
	add	[calcsp],unitbyte

add_rfrf:
	; a//b + c//d = (ad+bc)//bd

	mov	ax,5
	call	memoryalloc

	xputboth	xa,xb,0
	xputboth	xc,xd,1

	xreduce	xb,xd,xg

	xget	0,xa
	xget	1,xd
	xmul
	xput	xa,0		;xa = ad'

	xget	0,xb
	xget	1,xc
	xmul
	xget	1,xa
	xadd
	xput	xa,0		;xa = ad'+b'c

	xget	0,xb
	xget	1,xd
	xmul
	xget	1,xg
	xmul
	cmove	1,0		;sp1 = b'd'g

	xget	0,xa		;sp0 = ad'+bc'

	mov	ax,5
	call	memoryfree
	jmp	setratfunc


; add rational functions entry

sub_rf:
	cmp	ah,ratpolymaskhigh
	jne	sub_rfnum
	jmp	sub_rfrf
sub_rfnum:
	mov	si,[calcsp]
	sub	si,unitbyte
	mov	[calcsp],si
	call	neg_numpl2
	add	[calcsp],unitbyte
	jmps	add_rfpl

add_rf:
	cmp	ah,ratpolymaskhigh
	je	add_rfrf

add_rfpl:
	; a//b + c = (a+bc)//b

	mov	ax,2
	call	memoryalloc

	xputboth	xa,xb,0
	xget	0,xb
add_rfplin:
	xmul			;bc
	xget	1,xa
	xadd			;a+bc

	xget	1,xb

	mov	ax,2
	call	memoryfree
	jmp	setratf_nogetgcd

;*

sub_numrf:
	mov	si,[calcsp]
	sub	si,unitbyte
	mov	[calcsp],si
	call	neg_rfsi
	add	[calcsp],unitbyte

add_numrf:
	; c + a//b = (a+bc)//b

	mov	ax,2
	call	memoryalloc

	xputboth	xa,xb,1
	xget	1,xb
	jmp	add_rfplin


div_numrf:
	; c / a//b = c * b//a = bc//a

	mov	ax,4
	call	memoryalloc

	xputboth	xb,xa,1
	xput	xc,0
	jmp	mul_rfplin

;*

div_rfpl:
	; a//b / c = a//bc

	mov	ax,4
	call	memoryalloc

	xputboth	xa,xb,0
	xput	xc,1
	xreduce	xa,xc,xd

	xget	0,xb
	xget	1,xc
	xmul			;bc
	cmove	1,0

	xget	0,xa

	mov	ax,4
	call	memoryfree
	jmp	setratf_nogetgcd

ratdiv_rf:
div_rf:
	cmp	ah,ratpolymaskhigh
	je	div_rfrf
	jmp	div_rfpl

;*

div_rfrf:
	; a//b / c//d = a//b * d//c = ad//bc

	mov	ax,5
	call	memoryalloc

	xputboth	xa,xb,0
	xputboth	xd,xc,1
	jmp	mul_rfrfin

;*

mul_rfpl:
	; a//b * c = ac//b

	mov	ax,4
	call	memoryalloc

	xputboth	xa,xb,0
	xput	xc,1
mul_rfplin:
	xreduce	xb,xc,xd

	xget	0,xa
	xget	1,xc
	xmul			;ac

	xget	1,xb

	mov	ax,4
	call	memoryfree
	jmp	setratf_nogetgcd

mul_numrf:
	; c * a//b = ac//b

	mov	ax,4
	call	memoryalloc

	xputboth	xa,xb,1
	xput	xc,0
	jmp	mul_rfplin

;*

mul_rf:
	cmp	ah,ratpolymaskhigh
	jne	mul_rfpl
;	je	mul_rfrf

mul_rfrf:
	; a//b * c//d = ac//bd

	mov	ax,5
	call	memoryalloc

	xputboth	xa,xb,0
	xputboth	xc,xd,1
mul_rfrfin:
	xreduce	xa,xd,xg
	xreduce	xb,xc,xg

	xget	0,xb
	xget	1,xd
	xmul			;bd
	xput	xg,0

	xget	0,xa
	xget	1,xc
	xmul			;ac

	xget	1,xg

	mov	ax,5
	call	memoryfree
	jmp	setratf_nogetgcd


ratdiv_intmpl:
div_intmpl:
	mov	bx,di
	call	int2modpoly2
	jmps	div_mplmpl

ratdiv_numpl:
div_numpl:
	mov	bx,di
	call	numer2poly2

div_mplmpl:
div_plpl:
;	call	reducedisi
	jmps	setratfunc
setratfunc2:
	add	[calcsp],2*unitbyte

setratfunc:
	mov	ax,3
	call	memoryalloc

	xput	xa,0
	xput	xb,1
	push	bx
	call	far ptr fargcd_calcsp
	pop	bx
	call	isconst_calcsp
	je	setratf20		;if gcd = const

;	call	integerpoly_calcsp
;	call	normalizepoly_calcsp
	xput	xc,0		;xc = g

	xget	0,xb
	xget	1,xc
	push	bx
	call	far ptr faridiv_calcsp
	pop	bx
	xput	xb,0

	xget	0,xa
	xget	1,xc
	push	bx
	call	far ptr faridiv_calcsp
	pop	bx
	jmps	setratf30

setratf20:
	xget	0,xa
setratf30:
	xget	1,xb

	mov	ax,3
	call	memoryfree

setratf_nogetgcd:
	mov	bx,[calcsp]
	mov	ax,[bx]
	or	ax,ax
	jz	gosetratfret		;if 0

	and	ah,attribmaskhigh
	cmp	ah,polymaskhigh
	je	setratf_poly
	jmp	setratf_modpoly

setratf_poly:
	cmp	word ptr [bx+2],1
	jne	setratf40		;not const
	cmp	word ptr [bx-unitbyte+2],1
	jne	setratf40		;not const

	;if both const then divide rationally

	mov	di,bx
	lea	si,[bx+4]
	mov	cx,[si]
	and	cx,lenmask
	inc	cx
	rep	movsw

	sub	bx,unitbyte
	mov	di,bx
	lea	si,[bx+4]
	mov	cx,[si]
	and	cx,lenmask
	inc	cx
	rep	movsw

	call	far ptr farratdiv_calcsp
gosetratfret:
	jmp	setratfret

setratf40:
	;let the leadcoef of den be positive

	mov	bx,[calcsp]
	sub	bx,unitbyte
	call	getleadcoeffadr
	mov	ax,[bx]
	test	ah,signmaskhigh
	jz	setratf48		;if highest > 0
	mov	si,[calcsp]
	call	neg_polysi		;neg num
	mov	si,[calcsp]
	sub	si,unitbyte
	call	neg_polysi		;neg den
setratf48:
	;check GCD of coeffs

	mov	bx,[calcsp]
	lea	di,[bx-2*unitbyte]
	mov	[calcsp],di
	lea	si,[bx+4]
	copy_si2di
	mov	cx,[bx+2]		;number of terms
	dec	cx
	jz	setratf52
setratf50:
	mov	di,[calcsp]
	mov	ax,1
	cmp	[di],ax
	jne	setratf51
	cmp	[di+2],ax
	je	setratf60			;if GCD=1 then end
setratf51:
	push	cx
	push	si
	mov	di,[calcsp]
	call	far ptr farGETGCD
	mov	si,WORK3		;GCDADR
	mov	di,[calcsp]
	copy_si2di
	pop	si
	mov	ax,[si]
	and	ax,lenmask
	inc	ax
	add	ax,ax
	add	si,ax
	pop	cx
	loop	setratf50

setratf52:
	mov	bx,[calcsp]
	add	bx,unitbyte
	lea	si,[bx+4]
	mov	cx,[bx+2]		;number of terms
setratf55:
	mov	di,[calcsp]
	mov	ax,1
	cmp	[di],ax
	jne	setratf56
	cmp	[di+2],ax
	je	setratf60			;if GCD=1 then end
setratf56:
	push	cx
	push	si
	mov	di,[calcsp]
	call	far ptr farGETGCD
	mov	si,WORK3		;GCDADR
	mov	di,[calcsp]
	copy_si2di
	pop	si
	mov	ax,[si]
	and	ax,lenmask
	inc	ax
	add	ax,ax
	add	si,ax
	pop	cx
	loop	setratf55

;connect them

setratf60:
	mov	si,[calcsp]
	mov	ax,1
	cmp	[si],ax
	jne	setratf62
	cmp	[si+2],ax
	jne	setratf62
	add	si,2*unitbyte
	mov	[calcsp],si
	jmps	setratf65

setratf62:
	;divide by GCD of coefs

	mov	ax,2
	call	memoryalloc

	xput	xa,0			;reserve GCD of coefs
	add	[calcsp],unitbyte
	push	bx
	call	far ptr faridiv_calcsp
	pop	bx
	xput	xb,0			;reserve result
	xget	0,xa
	add	[calcsp],unitbyte
	push	bx
	call	far ptr faridiv_calcsp
	pop	bx
	xget	1,xb

	mov	ax,2
	call	memoryfree

setratf65:
	mov	di,[calcsp]
	lea	si,[di-unitbyte]
	mov	cx,[si]
	and	cx,lenmask
	cmp	cx,1
	jne	setratf68
	cmp	word ptr [si+2],1
	je	setratfret	;if den=1
setratf68:
	inc	cx
	mov	bx,[di]
	and	bx,lenmask
	jz	setratfret	;if num=0
	inc	bx
	mov	ax,bx
	add	ax,cx
	cmp	ax,limitword
	ja	setratfovr
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
	or	ah,ratpolymaskhigh
	stosw
	cld
setratfret:
	jmp	far ptr returnadr

setratfovr:
	jmp	far ptr ovrerr


getleadcoeffadr:
	mov	cx,[bx+2]		;number of terms
	add	bx,4
getleadca10:
	dec	cx
	jz	getleadcaret
	mov	ax,[bx]
	and	ax,lenmask
	inc	ax
	add	ax,ax
	add	bx,ax
	jmp	getleadca10
getleadcaret:
	ret


setratf_modpoly:
	mov	ax,modpolymask+4
	cmp	[bx],ax
	jne	setratf_mp40		;not const
	cmp	word ptr [bx-unitbyte],ax
	jne	setratf_mp40		;not const

	;if both const then divide them

	set32
	mov	ax,[bx-unitbyte+6]	;den
	call	modinvdword

	set32
	mov	dx,[bx+6]
	set32
	mul	dx
	set32
	mov	di,word ptr [polymodulus]
	set32
	div	di
	set32
	mov	[bx+6],dx
gosetratf_mpret:
	jmp	setratfret

setratf_mp40:
	;let the leadcoef of den be 1

	mov	bx,[calcsp]
	lea	si,[bx-unitbyte]

	mov	cx,[si]
	and	cx,lenmask
	add	cx,cx
	add	si,cx
	set32
	mov	ax,[si-2]			;lead coeff
	set32
	dec	ax
	jz	setratf_mp50
	set32
	inc	ax

	set32
	mov	di,[bx+2]		;=[polymodulus]

	call	modinvdword
	set32
	mov	si,ax

	mov	bx,[calcsp]
	mov	cx,[bx]
	and	cx,lenmask
	shr	cx,1
	dec	cx
	add	bx,6
setratf_mplp1:
	set32
	mov	ax,[bx]
	set32
	mul	si
	set32
	div	di
	set32
	mov	[bx],dx
	add	bx,4
	loop	setratf_mplp1

	mov	bx,[calcsp]
	sub	bx,unitbyte
	mov	cx,[bx]
	and	cx,lenmask
	shr	cx,1
	dec	cx
	add	bx,6
setratf_mplp2:
	set32
	mov	ax,[bx]
	set32
	mul	si
	set32
	div	di
	set32
	mov	[bx],dx
	add	bx,4
	loop	setratf_mplp2

setratf_mp50:				;connect them
	mov	di,[calcsp]
	lea	si,[di-unitbyte]
	mov	cx,[si]
	and	cx,lenmask
	cmp	cx,4
	je	setratf_mpret		;if den=1
setratf_mp60:
	inc	cx
	mov	bx,[di]
	and	bx,lenmask
	jz	setratf_mpret	;if num=0
	inc	bx
	mov	ax,bx
	add	ax,cx
	cmp	ax,limitword
	ja	setratf_mpovr
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
	or	ah,ratpolymaskhigh
	stosw
	cld
setratf_mpret:
	jmp	far ptr returnadr

setratf_mpovr:
	jmp	far ptr ovrerr


printratpoly:
	call	ahedsp2
	cmovereal	0,-1

	mov	al,'('
	call	prchr2

	call	printpolyboth

	mov	al,')'
	call	prchr2

	mov	al,'/'
	call	prchr2

	cmoveimag	0,-1

	mov	al,'('
	call	prchr2

	call	printpolyboth

	mov	al,')'
	call	prchr2

	add	[calcsp],unitbyte
	jmp	far ptr print_calcsp_out

printpolyboth:
	mov	si,[calcsp]
	mov	ax,[si]
	and	ax,attribmask
	cmp	ax,polymask
	je	go_printpoly
	cmp	ax,modpolymask
	je	go_printmodpoly
	jmp	polyilgerr
go_printpoly:
	jmp	printpolysub
go_printmodpoly:
	jmp	printmodpolysub


code2	ends
