;polynomi.asm



DATA	SEGMENT	WORD PUBLIC
	assume	cs:code,ds:data

	public	X_adr,Z_adr,Z_limadr,deg_now
	public	poly_operation

	extrn	polymodulus:dword
	extrn	varmark:byte,postmark:byte,plusmark:byte
	extrn	degnowp1:word


X_adr		dw	?
X_baseadr	dw	?
X_deg		dw	?
X_tempdeg	dw	?
Y_adr		dw	?
Y_baseadr	dw	?
Y_deg		dw	?
Y_tempdeg	dw	?
Z_adr		dw	?
Z_deg		dw	?
non0Z_adr	dw	?
Z_limadr	dw	?
deg_now		dw	?
non0_deg	dw	?
constadr	dw	?
poly_operation	dw	?,code

data	ends


CODE	SEGMENT PUBLIC
	ASSUME	CS:CODE,DS:DATA


	extrn	moderr:near
	extrn	farprint_calcsp:far,farprntbx:far,farprntebx:far

code	ends



code2	segment	public
	assume	cs:code2,ds:data

	public	printpoly,printmodpoly,str$poly,str$modpoly

	public	val_poly,val_modpoly,store_si2Z
	public	modpow_poly,modpow_modpoly
	public	gcd_poly,gcd_modpoly
	public	monicin,lcoeffin,ccoeffin
	public	modmulin

	public	add_pl,add_numpl
	public	sub_pl,sub_numpl
	public	mul_pl,mul_numpl
	public	div_pl,idiv_pl
	public	power_poly,poly_scalar,farneg_polysi

	public	add_mpl,add_nummpl,add_mpl_in
	public	sub_mpl,sub_nummpl
	public	mul_mpl,mul_nummpl
	public	idiv_mpl
	public	power_modpoly,farneg_modpolysi
	public	farint2modpoly,farnumer2poly


	extrn	str$packsub:near,str$prntax:near,str$prnteax:near

	extrn	ahedsp2:near
	extrn	returnadr:far
	extrn	prchr2:near,prspc2:near


;
; * numeric in [bx] -> poly
;   destroy : nothing
;
numer2polyilg:
	jmp	far ptr ilgerr
numer2polyover:
	jmp	far ptr ovrerr

farnumer2poly:
  if flg32
	pusha
  else
	push	ax
	push	cx
	push	si
	push	di
  endif
	mov	ax,[bx]
	test	ah,nonnumericmaskhigh
	jnz	numer2polyilg	;not a number
	and	ax,lenmask
	jz	numer2polyout
	mov	cx,ax
	inc	cx
	mov	si,bx
	add	si,ax
	add	si,ax		;highest adr
	add	ax,2
	cmp	ax,limitword
	ja	numer2polyover
	lea	di,[si+4]
	std
	rep	movsw
	cld
	mov	word ptr [bx+2],1	;# of members
	or	ah,polymaskhigh
	mov	[bx],ax
numer2polyout:
  if flg32
	popa
  else
	pop	di
	pop	si
	pop	cx
	pop	ax
  endif
	retf

comment %
;
; * poly in [bx] -> numeric
;   destroy : nothing
;
poly2numerilg:
	jmp	ilgerr

poly2numer:
	push	cx
	push	si
	push	di

	cmp	word ptr [bx+2],1
	jne	poly2numerilg	;not a const poly
	mov	di,bx
	lea	si,[bx+4]
	copy_si2di

	pop	di
	pop	si
	pop	cx
	ret	
%

;
; * integer in [bx] -> modpoly
;   destroy : nothing
int2modpolyilg:
	jmp	far ptr moderr

farint2modpoly:
	push	ax

	set32
	mov	ax,word ptr ss:[polymodulus]
	set32
	or	ax,ax
	jz	int2modpolyilg
	call	reduction_modP32
	set32
	or	ax,ax
	jz	int2modpolyset0
	set32
	mov	[bx+6],ax	;result
	set32
	mov	ax,word ptr ss:[polymodulus]
	set32
	mov	[bx+2],ax	;modulus
	mov	word ptr [bx],modpolymaskhigh*256+4
	pop	ax
	retf

int2modpolyset0:
	mov	word ptr [bx],ax
	set32
	mov	ax,word ptr ss:[polymodulus]
	set32
	mov	[bx+2],ax	;modulus(next use only,
				;usually no meaning)
	pop	ax
	retf

;
; * integer in [bx] -- reduction mod P -> eax
;   destroy : nothing

reduction_ilg:
	jmp	far ptr ilgerr

reduction_modP32:
	push	bx
	push	cx
	push	dx
	push	si

	mov	si,bx
	set32
	mov	bx,ax		;ebx = modulus
	mov	ax,[si]
	test	ah,attribmaskhigh
	jnz	reduction_ilg
	mov	cx,ax
	and	cx,lenmask
	jz	reductionPret0		;if 0
	push	ax		;*
	add	si,cx
	add	si,cx		;highest word adr

	set32
	xor	dx,dx
	std

	inc	cx
	shr	cx,1
	jc	reductioP6
	set32
	xor	ax,ax
	mov	ax,[si]
	sub	si,4
	jmp	short reductioP12
reductioP6:
	sub	si,2

	;now si=highest dword adr
reductionP10:
	set32
	lodsw
reductioP12:
	set32
	div	bx
	myloop	reductionP10
	cld
	pop	cx		;*
	set32
	mov	ax,dx
	set32
	or	dx,dx
	jz	reductionPret	;if 0
	test	ch,80h
	jz	reductionPret	;if >0
	set32
	neg	ax
	set32
	add	ax,bx
reductionPret:
	pop	si
	pop	dx
	pop	cx
	pop	bx
	ret	
reductionPret0:
	set32
	xor	ax,ax
	jmp	reductionPret

;
; * add mod polynomilas
; [di]=[di]+[si]

addmoderr:
polymoderr:
	jmp	far ptr moderr

go_add_mplrf:
	jmp	add_numrf

add_nummpl:
	mov	bx,di
	cmp	word ptr [di],0
	jne	add_mpl10
	copy_si2di		;if [di]=0 then copy [si]
	jmp	far ptr returnadr

add_mpl:
	cmp	ah,modpolymaskhigh
	je	add_mpl_in
	cmp	ah,ratpolymaskhigh
	je	go_add_mplrf
	cmp	ah,polymaskhigh
	je	addmoderr

	mov	bx,si
add_mpl10:
	call	int2modpoly2
add_mpl_in:
	set32
	mov	bx,word ptr [polymodulus]
	set32
	cmp	bx,[di+2]
	jne	addmoderr
	set32
	cmp	bx,[si+2]
	jne	addmoderr

	lodsw
	and	ax,lenmask
	jz	addmodpolyout	;if [si]=0

	mov	cx,[di]
	add	di,2
	and	cx,lenmask
	jz	addmodpolycopy	;if [di]=0

	shr	ax,1
	shr	cx,1
	dec	ax
	dec	cx
	add	si,4		;skip modulus
	add	di,4
	cmp	ax,cx
	jne	addmodpoly100	;nonequal length

	push	cx		;/*
addmodpoly20:
	set32
	lodsw
	set32
	add	ax,[di]
	jc	addmodpoly25	;remedied on March 20,1991
	set32
	cmp	ax,bx
	jb	addmodpoly30
addmodpoly25:
	set32
	sub	ax,bx
addmodpoly30:
	set32
	stosw
	myloop	addmodpoly20

addmodpoly40:
	sub	di,4
	pop	cx		;*/
	set32
	xor	ax,ax
	std
	set32
	repe	scasw
	cld
	je	addmodpoly60	;all 0	
	inc	cx		;recover scasd decrement
	shl	cx,1
	add	cx,2		;modulus
addmodpoly50:
	or	ch,modpolymaskhigh
addmodpoly60:
	mov	si,[calcsp]
	mov	[si],cx
addmodpolyout:
	jmp	far ptr returnadr

addmodpolycopy:
	sub	si,2
	sub	di,2
	mov	cx,ax
	inc	cx
	rep	movsw
	jmp	addmodpolyout

addmodpoly100:
	push	ax		;* len of [si]-1
	push	cx		;* len of [di]-1
	ja	addmodpoly120
	mov	cx,ax
addmodpoly120:
	set32
	lodsw
	set32
	add	ax,[di]
	jc	addmodpoly125	;remedied on March 20,1991
	set32
	cmp	ax,bx
	jb	addmodpoly130
addmodpoly125:
	set32
	sub	ax,bx
addmodpoly130:
	set32
	stosw
	myloop	addmodpoly120
	pop	cx
	pop	ax
	shl	cx,1
	shl	ax,1
	mov	dx,ax		;len of [si]-1
	sub	ax,cx
	jb	addmodpolyout	;degree unchanged
	mov	cx,ax
	rep	movsw
	mov	cx,dx
	add	cx,2		;modulus
	jmp	addmodpoly50

;
; * subtract mod polynomilas
;

submplmplerror:
	jmp	far ptr systemerr

submoderr:
	jmp	polymoderr

go_sub_mplrf:
	jmp	sub_numrf

sub_nummpl:
	mov	bx,di
	cmp	word ptr [di],0
	jne	sub_mpl10
	push	di		;if [di] = 0
	copy_si2di		;then copy
	pop	si
	call	neg_modpolysi	;and change sign
	jmp	far ptr returnadr

sub_mpl:
	cmp	ah,modpolymaskhigh
	je	sub_mplmpl
	cmp	ah,ratpolymaskhigh
	je	go_sub_mplrf
	cmp	ah,polymaskhigh
	je	submoderr

	mov	bx,si
sub_mpl10:
	call	int2modpoly2
sub_mplmpl:
	set32
	mov	bx,word ptr [polymodulus]
	set32
	cmp	bx,[di+2]
	jne	submoderr
	set32
	cmp	bx,[si+2]
	jne	submoderr

	lodsw
	and	ax,lenmask
	jz	submplmplerror	;no case of [si]=0

	mov	cx,[di]
	add	di,2
	and	cx,lenmask
	jz	submplmplerror	;no case of [di]=0

	shr	ax,1
	shr	cx,1
	dec	ax
	dec	cx
	add	si,4		;skip modulus
	add	di,4
	cmp	ax,cx
	jne	submodpoly100	;nonequal length
	push	cx
submodpoly25:
	set32
	mov	ax,[di]
	set32
	sub	ax,[si]
	jnb	submodpoly30
	set32
	add	ax,bx
submodpoly30:
	set32
	stosw
	add	si,4
	myloop	submodpoly25
	jmp	addmodpoly40

submodpoly100:
	push	ax
	push	cx
	ja	submodpoly120
	mov	cx,ax
submodpoly120:
	set32
	mov	ax,[di]
	set32
	sub	ax,[si]
	jnb	submodpoly130
	set32
	add	ax,bx
submodpoly130:
	set32
	stosw
	add	si,4
	dec	cx
	jnz	submodpoly120

	pop	cx
	pop	ax
	mov	dx,ax		;len of [si]-1
	sub	ax,cx
	jb	addmodpolyout

	mov	cx,ax
submodpoly140:
	set32
	lodsw
	set32
	neg	ax
	jz	submodpoly150
	set32
	add	ax,bx
submodpoly150:
	set32
	stosw
	dec	cx
	jnz	submodpoly140
	mov	cx,dx
	shl	cx,1
	add	cx,2
	jmp	addmodpoly50

;
; * negate modpoly
;   in  : si = ptr
;   out : si = new ptr
;   ds : not always = ss
;   destroy ax,cx,dx,si

negmoderr:
	jmp	polymoderr

farneg_modpolysi:
	call	neg_modpolysi
	jmp	far ptr returnadr

neg_modpolysi:
	mov	ax,[si]
	add	si,2
negmodpolyin:
	and	ax,lenmask
	jz	negmodpolyout	;if 0
	mov	cx,ax
	set32
	mov	dx,word ptr ss:[polymodulus]
	set32
	cmp	dx,[si]
	jne	negmoderr
	add	si,4
	shr	cx,1
	dec	cx
negmodpoly10:
	set32
	mov	ax,[si]
	set32
	neg	ax
	jz	negmodpoly20
	set32
	add	ax,dx
	set32
	mov	[si],ax
negmodpoly20:
	add	si,4
	myloop	negmodpoly10
negmodpolyout:
	ret


;
; * power of modpoly
; [bx]^cx  power = cx = 16bit

powmodpolyconst:
	set32
	mov	si,[bx+6]	;now calc esi^cx mod prime

	set32
	xor	ax,ax
	mov	ax,cx
	push	bp		;*
	set32
	mov	bp,word ptr [polymodulus]
	set32
	xor	dx,dx
	mov	dx,2		;edx=2
	set32
	cmp	bp,dx
	je	powmodpolycon50
	set32
	dec	bp
	set32
	xor	dx,dx
	set32
	div	bp
	set32
	or	dx,dx
	jz	powmodpolyset1popbp
	mov	di,dx		;cut multi of p-1
				;must be 16bit
	set32
	inc	bp
	mov	cx,16		;power is 16bit
powmodpolycon10:
	add	di,di		;16bit
	dec	cx
	jnc	powmodpolycon10
	set32
	mov	ax,si
	jcxz	powmodpolycon30
powmodpolycon20:
	set32
	mul	ax
	set32
	div	bp
	set32
	mov	ax,dx
	add	di,di		;16bit
	jnc	powmodpolycon25
	set32
	mul	si
	set32
	div	bp
	set32
	mov	ax,dx
powmodpolycon25:
	dec	cx
	jnz	powmodpolycon20
powmodpolycon30:
	set32
	mov	[bx+6],ax
powmodpolycon50:
	pop	bp		;*
	jmp	powmodpolyret

powmodpoly_X?:		;power of X?
	set32
	xor	di,di
	set32
	cmp	[bx+6],di		;const term
	jne	powmodpoly10		;not _X
	inc	di			;edi=1
	set32
	cmp	[bx+10],di
	jne	powmodpoly10		;not _X
	shl	ax,1
	cmp	ax,limitword-4
	ja	powmodpolyover
	add	ax,4
	or	ah,modpolymaskhigh
	mov	[bx],ax
	lea	di,[bx+6]
	shl	cx,1
	xor	ax,ax
	rep	stosw
	inc	ax
	stosw
	dec	ax
	stosw
	jmp	powmodpolyret


powmodpolyilg:
polyilgerr:
	jmp	far ptr ilgerr
powmoderr:
	jmp	polymoderr
powmodpolyover:
polyovrerr:
	jmp	far ptr ovrerr

powmodpolyset1popbp:
	pop	bp
powmodpolyset1:
	mov	word ptr [bx],modpolymask+4
	mov	word ptr [bx+6],1
	mov	word ptr [bx+8],0
	jmp	powmodpolyret

;
; power of mod polynomial
;

power_modpoly:
	checkcalcspfar	2
	mov	bx,[calcsp]
	set32
	mov	ax,word ptr [polymodulus]
	set32
	cmp	ax,[bx+2]
	jne	powmoderr
	lea	si,[bx-unitbyte]
	lodsw
	cmp	ax,1
	ja	powmodpolyilg
	jb	powmodpolyset1	;if 0-th power
	lodsw
	mov	cx,ax		;*power 16bit
	mov	dx,[bx]
	and	dh,lenmaskhigh
	shr	dx,1
	sub	dx,2		;now dx = degree
	jz	powmodpolyconst
	cmp	dx,1
	je	powmodpoly_X?
	mul	dx
	or	dx,dx
	jnz	powmodpolyover
powmodpoly10:
	shl	ax,1
	cmp	ax,limitword-4
	ja	powmodpolyover

	push	bp		;*
	set32
	mov	bp,word ptr [polymodulus]

	cmp	cx,2
	jbe	powmodpolyP1	;^1 or ^2
	mov	ax,cx

	sub	[calcsp],unitbyte

	mov	si,bx		;copy poly to sp
	mov	di,[calcsp]
	copy_si2di

	mov	cx,16
polwmodpoly30:
	add	ax,ax
	dec	cx
	jnc	polwmodpoly30
polwmodpoly50:
	push	cx
	push	ax
	call	square_modpoly
	pop	ax
	add	ax,ax
	jnc	polymodpoly70
	push	ax
	cmove	1,-1
	call	far ptr farMul_calcsp
	pop	ax
polymodpoly70:
	pop	cx
	dec	cx
	jnz	polwmodpoly50

	mov	si,[calcsp]
	lea	di,[si+unitbyte]
	mov	[calcsp],di
	copy_si2di		;set result

powmodpolyout:
	pop	bp		;*
powmodpolyret:
	jmp	far ptr returnadr

powmodpolyP1:
	cmp	cx,1
	je	powmodpolyout	;if ^1
	call	square_modpoly	;if ^2
	jmp	powmodpolyout

	;
	; square of modpoly
	; [sp0] := [sp0]^2
	; ebp = polymodulus
	; not checking overflow
	; destroy many

squaremodpoly2w:
	; (c0 +c1X)^2

	set32
	mov	ax,[bx+6]	;c0
	set32
	mov	si,ax		;memo
	set32
	mul	ax		;c0^2
	set32
	div	bp
	set32
	mov	[bx+6],dx
	set32
	mov	cx,dx		;ecx = 1st
	set32
	mov	ax,[bx+10]
	set32
	mov	di,ax		;memo
	set32
	mul	ax		;c1^2
	set32
	div	bp
	set32
	mov	[bx+14],dx
	set32
	mov	ax,di
	set32
	mov	di,dx		;edi = 3rd
	set32
	mul	si
	set32
	div	bp
	set32
	add	dx,dx
	jc	squaremodpoly2w10
	set32
	cmp	dx,bp
	jb	squaremodpoly2w20
squaremodpoly2w10:
	set32
	sub	dx,bp
squaremodpoly2w20:
	set32
	mov	[bx+10],dx	;edx = 2nd
	mov	ax,modpolymask+8
	mov	[bx],ax
	ret

squaremodpolyshort:
	je	squaremodpoly2w
	set32
	mov	ax,[bx+6]
	set32
	mul	ax
	set32
	div	bp
	set32
	mov	[bx+6],dx
	ret

squaremodpolyforP2:		;if polymodulus=2
	shr	ax,1
	dec	ax		;# of members
	mov	cx,ax
	mov	dx,ax
	shl	ax,2
	lea	si,[bx+2]
	add	si,ax		;si = highest dword adr
	mov	di,si
	add	di,ax		;di = new highest adr+4
	sub	di,4
	set32
	xor	ax,ax
	std
sqmodpolyp210:
	set32
	movsw
	set32
	stosw
	myloop	sqmodpolyp210
	cld

	mov	word ptr [bx+2],2	;restore modulus
	mov	word ptr [bx+4],0	;
	shl	dx,2		;(dx*2-1)*2+2=dx*4
	or	dh,modpolymaskhigh
	mov	[bx],dx	
	ret

square_modpoly:
	mov	bx,[calcsp]
	mov	ax,[bx]
	and	ax,lenmask
	set32
	xor	cx,cx
	mov	cx,2		;ecx=2
	set32
	cmp	bp,cx
	je	squaremodpolyforP2	;if polymodulus=2

	shr	ax,1
	dec	ax
	cmp	ax,2		;# of members
	jbe	squaremodpolyshort
	mov	si,bx
	lea	di,[bx-unitbyte]
	copy_si2di		;copy to sp+1

	mov	cx,ax		;# of members
	shl	ax,2		;total words of result
;	cmp	ax,limitword
;	ja	powmodpolyover
	or	ah,modpolymaskhigh
	lea	si,[bx-unitbyte+6]
	mov	di,bx
	stosw			;new attribute
	add	di,4		;skip modulus

	dec	cx		;# of members -1
	push	cx

	;square parts

	set32
	lodsw
	set32
	mul	ax
	set32
	div	bp
	set32
	mov	ax,dx
	set32
	stosw
sqmodpoly10:
	set32
	xor	ax,ax
	set32
	stosw
	set32
	lodsw
	set32
	mul	ax
	set32
	div	bp
	set32
	mov	ax,dx
	set32
	stosw
	myloop	sqmodpoly10

	pop	cx
	lea	si,[bx-unitbyte+6]
	lea	di,[bx+6]

	;other parts

sqmodpoly20:
	add	di,4
	set32
	lodsw
	set32
	or	ax,ax
	jz	sqmodpoly90
	set32
	mov	bx,ax
	push	cx
sqmodpoly40:
	set32
	lodsw
	set32
	mul	bx
	set32
	div	bp
	set32
	mov	ax,dx
	set32
	add	ax,ax
	jc	sqmodpoly50
	set32
	cmp	ax,bp
	jb	sqmodpoly60
sqmodpoly50:
	set32
	sub	ax,bp
sqmodpoly60:
	set32
	add	ax,[di]
	jc	sqmodpoly70
	set32
	cmp	ax,bp
	jb	sqmodpoly80
sqmodpoly70:
	set32
	sub	ax,bp
sqmodpoly80:
	set32
	stosw
	myloop	sqmodpoly40

	pop	cx
	shl	cx,2
	sub	si,cx
	sub	di,cx
	shr	cx,2
sqmodpoly90:
	add	di,4
	myloop	sqmodpoly20
	ret


;
; * multiplication of modpoly
;  [sp0]=[sp0]*[sp1]
;  assume modulus is PRIME
;

mulmodpolyset0:
	mov	si,[calcsp]
	mov	word ptr [si],0
go_mulmodpolyout:
	jmp	mulmodpolyout

mul_mpl:
	cmp	ah,modpolymaskhigh
	je	mul_mplmpl
	or	ah,ah
	jz	mul_mplnum
	cmp	ah,ratpolymaskhigh
	je	go_mul_mplrf
	cmp	ah,polymaskhigh
	je	mulmoderr
	jmp	polyilgerr

go_mul_mplrf:
	jmp	mul_numrf		;mpl*rf -> rf

mulmoderr:
	jmp	polymoderr

mulmodpolyovererr:
	jmp	polyovrerr


mul_nummpl:
	mov	bx,di
	jmps	mul_mpl10
mul_mplnum:
	mov	bx,si
mul_mpl10:
	call	int2modpoly2

mul_mplmpl:
	set32
	mov	ax,word ptr [polymodulus]
	set32
	cmp	ax,[di+2]
	jne	mulmoderr
	set32
	cmp	ax,[si+2]
	jne	mulmoderr
	checkcalcspfar	2
	mov	si,[calcsp]	;move [sp0] to [sp2]
	mov	bx,si		;bx = sp0
	lea	di,[si-2*unitbyte]
	lodsw
	and	ax,lenmask
	jz	mulmodpolyout	;if [sp0]=zeropoly
	mov	cx,ax
	stosw
	rep	movsw

	mov	di,bx
	lea	si,[bx-unitbyte] ;si = sp1 	
	mov	cx,[si]
	and	cx,lenmask
	jz	mulmodpolyset0	;if [sp1]=zeropoly
	mov	[si],cx
	add	cx,ax		;len[sp1] + len[sp2]
	sub	cx,4
	cmp	cx,limitword
	ja	mulmodpolyovererr
	mov	ax,cx
	or	ah,modpolymaskhigh
	stosw			;set new length(here we needs
				;modulus is PRIME
	add	di,4		;skip modulus
	shr	cx,1
	dec	cx
	shl	cx,1
	xor	ax,ax
	rep	stosw		;clear [sp0]

	lea	di,[si-unitbyte] ;now BX = sp0, SI = sp1, DI = sp2
	mov	ax,[di]
	mov	cx,[si]
	shr	ax,1
	shr	cx,1
	dec	ax
	dec	cx
	add	bx,6
	add	di,6
	add	si,6
	push	bp		;**
	set32
	mov	bp,word ptr [polymodulus]
mulmodpoly10:
	set32
	xor	dx,dx
	set32
	cmp	[di],dx
	je	mulmodpoly50
	push	ax
	push	cx
mulmodpoly20:
	push	cx
	set32
	xor	cx,cx
	set32
	lodsw
	set32
	mov	dx,[di]
	set32
	mul	dx
	set32
	add	ax,[bx]
	set32
	adc	dx,cx		;edx:eax <= (p-1)^2+p < p^2 < p*2^32
	set32
	div	bp
	set32
	mov	[bx],dx
	add	bx,4
	pop	cx
	dec	cx
	jnz	mulmodpoly20

	pop	cx
	pop	ax
	shl	cx,2
	sub	bx,cx
	sub	si,cx
	shr	cx,2
mulmodpoly50:
	add	di,4
	add	bx,4
	dec	ax
	jnz	mulmodpoly10

	pop	bp		;**
mulmodpolyout:
	jmp	far ptr returnadr


;
; *  modpoly / integer
;

div_modscadiverr:
	jmp	far ptr diverr
modpolyscamoderr:
	jmp	polymoderr

div_mplint:
	mov	bx,[calcsp]
	sub	bx,unitbyte
	call	int2modpoly2
	mov	ax,[bx]
	or	ax,ax
	jz	div_modscadiverr	;div by 0
	set32
	mov	ax,[bx+6]
	call	modinvdword
	set32
	mov	bx,ax

	mov	si,[calcsp]
	set32
	mov	ax,word ptr [polymodulus]
	set32
	cmp	ax,[si+2]
	jne	modpolyscamoderr
	mov	cx,[si]
	add	si,6
	and	cx,lenmask
	shr	cx,1
	dec	cx		;# of members
	push	bp		;*
	set32
	mov	bp,ax
divmodpolyscalar10:
	set32
	lodsw
	set32
	mul	bx
	set32
	div	bp
	set32
	mov	[si-4],dx
	myloop	divmodpolyscalar10
	pop	bp		;*

	jmp	far ptr returnadr

;
; * polynomial division
;

idivmodpolybyconst:
	shr	ax,1
	mov	cx,ax
	dec	cx		;terms of num.
	set32
	mov	ax,[si]	;den.
	call	modinvdword
	set32
	mov	si,ax
	add	bx,6
	push	bp
	set32
	mov	bp,word ptr [polymodulus]
idivmodpolyconlp:
	set32
	mov	ax,[bx]
	set32
	mul	si
	set32
	div	bp
	set32
	mov	[bx],dx
	add	bx,4
	myloop	idivmodpolyconlp
	pop	bp

idivmodpolyout0:
	mov	si,resadr
	mov	word ptr [si],0	;res=0
idivmodpolyout:
	jmp	far ptr returnadr


;
; * modpoly // y
;

ratdiv_mpl:
	cmp	ah,modpolymaskhigh
	je	go_div_mplmpl		;y is modpoly
	or	ah,ah
	jz	go_ratdiv_mplint	;y is integer
	cmp	ah,ratpolymaskhigh
	je	go_ratdiv_mplrf
	cmp	ah,polymaskhigh
	je	idivmoderr
;div_mpl_ilgerr:
	jmp	polyilgerr

go_ratdiv_mplint:
	jmp	div_mplint

go_ratdiv_mplrf:
	jmp	div_numrf


;
; * modpoly / y
;

go_div_mplrf:
	jmp	div_numrf

div_mpl:
	cmp	ah,modpolymaskhigh
	je	go_div_mplmpl		;y is modpoly
	or	ah,ah
	jz	go_div_mplint		;y is integer
	cmp	ah,ratpolymaskhigh
	je	go_div_mplrf
	cmp	ah,polymaskhigh
	je	idivmoderr
;div_mpl_ilgerr:
	jmp	polyilgerr

go_div_mplmpl:
	jmp	div_mplmpl		;mpl / mpl -> rf

go_div_mplint:
	jmp	div_mplint


idivmodpolyby0:
	jmp	far ptr diverr

idivmodpolyset0:
	mov	si,[calcsp]
	mov	word ptr [si],0
	jmp	far ptr returnadr

idivmplmoderr:
	jmp	polymoderr

;
; * modpoly \ y
;

idiv_mpl:
	cmp	ah,modpolymaskhigh
	je	idiv_mplmpl		;y is modpoly
;	or	ah,ah
;	jz	go_idiv_mplint		;y is integer
	cmp	ah,polymaskhigh
	je	idivmplmoderr
;idiv_mpl_ilgerr:
	jmp	polyilgerr

;go_idiv_mplint:
;	jmp	idiv_mplint

idiv_mplmpl:
	set32
	mov	ax,word ptr [polymodulus]
	set32
	cmp	ax,[di+2]
	jne	idivmplmoderr
	set32
	cmp	ax,[si+2]
	jne	idivmplmoderr

	mov	bx,di		;copy num. to resadr
	mov	si,di
	mov	di,resadr
	mov	cx,[si]
	and	cx,lenmask
	jz	idivmodpolyout0	;if num.=zeropoly
	inc	cx
	rep	movsw

	mov	di,resadr	 ;num.
	lea	si,[bx-unitbyte] ;den.

	mov	cx,[si]
	and	cx,lenmask
	jz	idivmodpolyby0	;division by 0

	mov	ax,[di]
	and	ah,lenmaskhigh
	add	di,ax
	add	di,ax
	sub	di,2		;highest dword adr of num.
	mov	dx,ax

	add	si,cx
	add	si,cx
	sub	si,2		;highest dword adr of den.
	shr	dx,1
	shr	cx,1
	sub	dx,cx
	jb	idivmodpolyset0
	sub	cx,2		;terms of den.-1
	jz	idivmodpolybyconst
	inc	dx		;terms of result
	mov	ax,dx
	inc	ax
	shl	ax,1
	or	ah,modpolymaskhigh
	mov	[bx],ax		;attrib of result
	and	ah,lenmaskhigh
	add	ax,ax
	add	bx,ax
	sub	bx,2		;highest dword adr of result

	push	bp
	set32
	mov	bp,word ptr [polymodulus]

	set32
	mov	ax,[si]
	set32
	dec	ax
	jnz	idivmodpolynonmonic
	set32
	inc	ax
idivmodpolymonic:
	push	dx
	set32
	mov	ax,[di]
	set32
	mov	[bx],ax		;store result
	set32
	dec	ax
	jz	idivmodpoly66	;if result=1

	push	cx		;/*
idivmodpoly62:
	sub	si,4
	sub	di,4
	set32
	mov	ax,[si]
	set32
	mov	dx,[bx]
	set32
	mul	dx
	set32
	div	bp
	set32
	mov	ax,[di]
	set32
	sub	ax,dx
	jnb	idivmodpoly64
	set32
	add	ax,bp
idivmodpoly64:
	set32
	mov	[di],ax
	dec	cx
	jnz	idivmodpoly62
idivmodpoly65:
	pop	cx		;*/
	shl	cx,2
	add	si,cx
	add	di,cx
	shr	cx,2

	sub	di,4
	sub	bx,4
	pop	dx
	dec	dx
	jnz	idivmodpolymonic
	jmp	idivmodpolysetrem

idivmodpoly66:			;directly subtract case
	push	cx
idivmodpoly67:
	sub	si,4
	sub	di,4
	set32
	mov	ax,[di]
	set32
	sub	ax,[si]
	jnb	idivmodpoly68
	set32
	add	ax,bp
idivmodpoly68:
	set32
	mov	[di],ax
	myloop	idivmodpoly67
	jmp	idivmodpoly65

idivmodpolynonmonic:
	set32
	inc	ax
	call	modinvdword
idivmodpolynonmoniclp:
	set32
	push	ax		;/*
	push	dx
	set32
	mov	dx,[di]
	set32
	mul	dx
	set32
	div	bp		;dx=A/B mod P
	set32
	mov	[bx],dx		;store result

	push	bx
	push	cx
	set32
	mov	bx,dx		;bx=dx=A/M mod P
idivmodpoly72:
	sub	si,4
	sub	di,4
	set32
	mov	ax,[si]
	set32
	mul	bx
	set32
	div	bp
	set32
	mov	ax,[di]
	set32
	sub	ax,dx
	jnb	idivmodpoly74
	set32
	add	ax,bp
idivmodpoly74:
	set32
	mov	[di],ax
	myloop	idivmodpoly72
	pop	cx
	pop	bx
	shl	cx,2
	add	si,cx
	add	di,cx
	shr	cx,2

	sub	di,4
	sub	bx,4
	pop	dx
	set32
	pop	ax		;*/
	dec	dx
	jnz	idivmodpolynonmoniclp

idivmodpolysetrem:
	;set remainder
	; now cx=len of remainder?

	mov	di,resadr+2
	shl	cx,2
	add	di,cx
	shr	cx,2
	set32
	xor	ax,ax
	std
	set32
	repe	scasw
	cld
	je	idivmodpoly90
	inc	cx
	shl	cx,1
	add	cx,2
	or	ch,modpolymaskhigh
idivmodpoly90:
	mov	si,resadr
	mov	[si],cx

	pop	bp
	jmp	far ptr returnadr


comment %
modinvword:
; inp : ax (GCD with 'polymodulus' must be 1)
; out : ax = 1/ax mod 'polymodulus'
; destroy : nothing

	cmp	ax,1
	je	modinvwordret
	push	bx
	push	dx
	push	si
	push	di

	mov	bx,word ptr [polymodulus]
	cmp	ax,bx
	jb	modinvw10
	xor	dx,dx
	div	bx
	mov	ax,dx
modinvw10:
	cmp	ax,1
	je	modinvwout
	xchg	ax,bx
	xor	si,si		;coef1
	mov	di,1		;coef2
modinvw20:
	xor	dx,dx
	div	bx
	push	dx		;remainder
	push	di		;coef2
	mul	di
	div	[polymodulus]
	mov	ax,si
	sub	ax,dx
	jae	modinvw30
	add	ax,word ptr [polymodulus]
modinvw30:
	mov	di,ax		;new coef2=coef1-quotient*coef2
	pop	si		;new coef1=old coef2
	mov	ax,bx
	pop	bx
	cmp	bx,1
	jne	modinvw20	;GCD must 1 otherwise endlessloop
	mov	ax,di
modinvwout:
	pop	di
	pop	si
	pop	dx
	pop	bx
modinvwordret:
	ret
%


modinvdword:
; inp : eax (GCD with 'polymodulus' must be 1)
; out : eax = 1/eax mod 'polymodulus'
; destroy : nothing

	set32
	dec	ax
	jz	modinvdwordretinc	;if = 1
	set32
	inc	ax
	push	bx
	push	dx
	push	si
	push	di

	set32
	mov	bx,word ptr [polymodulus]
	set32
	cmp	ax,bx
	jb	modinvdw10
	set32
	xor	dx,dx
	set32
	div	bx
	set32
	mov	ax,dx
modinvdw10:
	set32
	dec	ax
	jz	modinvdwordretinc
	set32
	inc	ax
	set32
	xchg	ax,bx
	set32
	xor	si,si		;coef1
	set32
	xor	di,di
	inc	di		;edi=1 = coef2
modinvdw20:
	set32
	xor	dx,dx
	set32
	div	bx
	set32
	push	dx		;remainder
	set32
	push	di		;coef2
	set32
	mul	di
	set32
	div	word ptr [polymodulus]
	set32
	mov	ax,si
	set32
	sub	ax,dx
	jae	modinvdw30
	set32
	add	ax,word ptr [polymodulus]
modinvdw30:
	set32
	mov	di,ax		;new coef2=coef1-quotient*coef2
	set32
	pop	si		;new coef1=old coef2
	set32
	mov	ax,bx
	set32
	pop	bx
	set32
	dec	bx
	pushf
	set32
	inc	bx
	popf
	jnz	modinvdw20	;GCD must 1 otherwise endlessloop
	set32
	mov	ax,di
modinvdwout:
	pop	di
	pop	si
	pop	dx
	pop	bx
	ret
modinvdwordretinc:
	set32
	inc	ax
	ret

;
; * integer in [bx] -> modpoly
;   destroy : nothing
;
int2modpoly2ilg:
	jmp	polyilgerr

int2modpoly2:
  if flg32
	pusha
  else
	push	ax
	push	bx
	push	cx
	push	dx
	push	si
  endif
	mov	si,bx
	set32
	mov	bx,word ptr ss:[polymodulus]
	set32
	or	bx,bx
	jz	int2modpoly2ilg		;if modulus=0
	mov	ax,[si]
	test	ah,attribmaskhigh
	jnz	int2modpoly2ilg	;not integer
	mov	cx,ax
	and	cx,lenmask
	jz	int2modpoly2set0	;0 is ok
	push	ax		;*
	add	si,cx
	add	si,cx

	set32
	xor	dx,dx
	std

	inc	cx
	shr	cx,1
	jc	int2modp208
	set32
	xor	ax,ax
	mov	ax,[si]
	sub	si,4
	jmp	short int2modp212
int2modp208:
	sub	si,2		;highest dword adr
int2modpoly210:
	set32
	lodsw
int2modp212:
	set32
	div	bx
	dec	cx
	jnz	int2modpoly210
	cld

	add	si,2		;base adr

	pop	ax		;*
	set32
	or	dx,dx
	jz	int2modpoly2set0
	test	ah,80h
	jz	int2modpoly220	;if >0
	set32
	neg	dx
	set32
	add	dx,bx
int2modpoly220:
	mov	word ptr [si],modpolymaskhigh*256+4
	set32
	mov	[si+2],bx	;modulus
	set32
	mov	[si+6],dx	;result
int2modpoly2ret:
  if flg32
	popa
  else
	pop	si
	pop	dx
	pop	cx
	pop	bx
	pop	ax
  endif
	ret	

int2modpoly2set0:
	mov	word ptr [si],0
	set32
	mov	[si+2],bx	;set modulus(for next calc. only)
	jmp	int2modpoly2ret

;
; * value of a mod polynomial
;
val_modpolyilg:
	jmp	polyilgerr

valmodpolyconst:
	mov	si,[calcsp]
	add	si,unitbyte
	mov	[calcsp],si
	xor	cx,cx
	set32
	mov	ax,[si+6]	;const term
	set32
	or	ax,ax
	jz	valmodpoly110
	set32
	mov	[si+2],ax	;set value
	inc	cx
	set32
	shr	ax,16
	or	ax,ax
	jz	valmodpoly110
	inc	cx
valmodpoly110:
	mov	[si],cx
	jmp	far ptr returnadr

val_modpoly:
	mov	bx,[calcsp]
	call	int2modpoly2
	mov	si,[calcsp]
	set32
	mov	ax,[si+2]	;modulus
	mov	bx,[si]
	or	bx,bx
	jz	valmodpolyconst	;if parameter = 0

	set32
	mov	bx,[si+6]	;multiplier
valmodpoly10:
	mov	si,[calcsp]
	add	si,unitbyte
	mov	[calcsp],si	;backsp
	set32
	cmp	ax,[si+2]	;check modulus
	jne	val_modpolyilg
	mov	ax,[si]
	and	ax,lenmask
	shr	ax,1
	dec	ax
	mov	cx,ax		;# of elements
	shl	ax,2
	add	ax,2
	add	si,ax		;highest dword adr
	set32
	mov	ax,[si]		;set result in eax
	sub	si,4
	dec	cx
	jz	valmodpoly50	;if const

	push	bp		;*
	set32
	mov	bp,word ptr [polymodulus]
valmodpoly20:
	push	cx
	set32
	xor	cx,cx
	set32
	mul	bx
	set32
	add	ax,[si]
	set32
	adc	dx,cx		;dx:ax <= p^2-p < p^2
	set32
	div	bp
	set32
	mov	ax,dx
	sub	si,4
	pop	cx
	dec	cx
	jnz	valmodpoly20
	pop	bp		;*

valmodpoly50:
	set32
	mov	[si],ax		;set result
	sub	si,2		;attribute adr
	xor	cx,cx
	set32
	or	ax,ax
	jz	valmodpoly60
	inc	cx
	set32
	shr	ax,16
	or	ax,ax
	jz	valmodpoly60
	inc	cx
valmodpoly60:
	mov	[si],cx		;set attribute
	jmp	far ptr returnadr


;
; * monic form of a polynomial
;

monicmodpoly:
	set32
	mov	bx,word ptr [polymodulus]
	set32
	cmp	bx,[si+2]
	jne	monicmoderr
	and	cx,lenmask
	jz	monicmodpolyret

monicmodpolyin:			;inp : si,cx,bx
	add	si,cx
	add	si,cx
	sub	si,2		;highest dword adr
	set32
	mov	ax,[si]
	set32
	dec	ax
	je	monicmodpolyret	;already monic
	set32
	inc	ax
	mov	word ptr [si],1
	mov	word ptr [si+2],0
	sub	cx,4
	jz	monicmodpolyret	;const
	sub	si,4
	set32
	push	bx
	call	modinvdword
	set32
	pop	bx
	set32
	mov	di,ax
	shr	cx,1
monic10:
	set32
	mov	ax,[si]
	set32
	mul	di
	set32
	div	bx
	set32
	mov	[si],dx
	sub	si,4
	dec	cx
	jnz	monic10
monicmodpolyret:
	jmp	far ptr returnadr

monicilgerr:
	jmp	polyilgerr
monicmoderr:
	jmp	polymoderr

monicin:
	call	far ptr farKakko
	mov	si,[calcsp]
	mov	ax,[si]
	mov	cx,ax
	jcxz	monicmodpolyret		;if 0
	and	ah,attribmaskhigh
	cmp	ah,polymaskhigh
	je	monicpoly
	cmp	ah,modpolymaskhigh
	je	monicmodpoly
	test	ah,nonnumericmaskhigh
	jnz	monicilgerr
	mov	word ptr [si],1		;if non0 scalar
	mov	word ptr [si+2],1	;result = scalar 1
	jmp	monicmodpolyret

monicpolyscalar:
	mov	word ptr [bx],polymask+3	;if non0 scalar poly
	mov	word ptr [bx+2],1	;1 element
	mov	word ptr [bx+4],1	;1 word
	mov	word ptr [bx+6],1	;1
	jmp	monicmodpolyret

monicpoly:
	checkcalcspfar	3
	mov	bx,[calcsp]
	mov	dx,[bx+2]	;# of members
	dec	dx
	jz	monicpolyscalar
	mov	ax,bx
	sub	ax,unitbyte-4
	mov	[X_adr],ax
	add	ax,unitbyte
	mov	[Z_adr],ax
	add	ax,2*unitword-3
	mov	[Z_limadr],ax

	mov	si,bx
	lea	di,[bx-unitbyte]
	copy_si2di

	mov	cx,dx		;# of elements -1
	push	cx
	mov	si,[X_adr]
	call	getpolypointer
	pop	cx
	mov	[constadr],si
	cmp	word ptr [si],1
	jne	monicpoly40
	cmp	word ptr [si+2],1
	je	monicpolyret	;already monic
monicpoly40:
	sub	bx,2*unitbyte
	mov	[calcsp],bx	;*sp+2
monicpoly50:
	push	cx
	mov	si,[X_adr]
	mov	bx,[calcsp]
	mov	di,bx
	copy_si2di_ax
	mov	[X_adr],si
	mov	si,[constadr]
	lea	di,[bx-unitbyte]
	copy_si2di_ax

	call	far ptr farRatdiv_calcsp

	mov	si,[calcsp]
	call	store_si2Z
	pop	cx
	myloop	monicpoly50

	mov	si,[calcsp]
	mov	word ptr [si],1
	mov	word ptr [si+2],1
	call	store_si2Z

	mov	si,[calcsp]
	add	si,2*unitbyte
	mov	[calcsp],si	;*

	mov	ax,[Z_adr]
	sub	ax,si
	shr	ax,1
	dec	ax
	or	ah,polymaskhigh
	mov	[si],ax
monicpolyret:
	jmp	far ptr returnadr


;
; gcd of modpoly
;

gcdmodpolysub:
	cmp	ax,cx
	ja	gcdmodpoly10
	setsp0	si
	setsp1	di
	call	far ptr farxchgsidi
gcdmodpoly10:
	sub	[calcsp],unitbyte
gcdmodpoly50:
	cmove	1,-1
	call	far ptr farIdiv_calcsp
	mov	si,resadr
	cmp	word ptr [si],0
	je	gcdmodpoly80
	cmove	0,-1
	cmove3	-1,resadr
	jmp	gcdmodpoly50
gcdmodpoly80:
	add	[calcsp],unitbyte
	ret

gcdpolymoderr:
	jmp	polymoderr

gcd_modpoly:
	checkcalcspfar	2
	set32
	mov	ax,word ptr [polymodulus]
	set32
	cmp	ax,[di+2]
	jne	gcdpolymoderr
	set32
	cmp	ax,[si+2]
	jne	gcdpolymoderr
	mov	ax,[si]
	and	ax,lenmask
	jz	gcdmodpolyout	;if Y=0 then X is an answer
	mov	cx,[di]
	and	cx,lenmask
	jz	gcdmodpolycopyret	;if X=0 then Y is an answer
	cmp	ax,4
	je	gcdmodpolyset1	;if Y=non0 const
	cmp	cx,4
	je	gcdmodpolyset1	;if X=non0 const
	call	gcdmodpolysub
gcdmodpolyout:
	mov	si,[calcsp]
	mov	cx,[si]
	and	cx,lenmask
	set32
	mov	bx,[si+2]	;modulus
	jmp	monicmodpolyin

gcdmodpolycopyret:
	copy_si2di_ax
	jmp	gcdmodpolyout

gcdmodpolyset1:
	mov	si,[calcsp]
	mov	word ptr [si],modpolymask+4
	mov	word ptr [si+6],1
	mov	word ptr [si+8],0
	jmp	far ptr returnadr


gcdpolysub:
	;now data are in xa, xb

	xget	0,xa
	xget	1,xb
	mov	di,[calcsp]
	lea	si,[di-unitbyte]
	mov	ax,[di]
	mov	cx,[si]
	and	ax,lenmask
	and	cx,lenmask
	cmp	ax,cx
	jae	gcdpoly10
	xget	0,xb
	xget	1,xa
	xput	xb,1
gcdpoly10:
gcdpoly50:
	xidiv
	mov	si,resadr
	cmp	word ptr [si],0
	je	gcdpoly80
	xget	0,xb
	cmove3	1,resadr
	sub	[calcsp],unitbyte
	call	integerpoly_calcsp
	add	[calcsp],unitbyte
	xput	xb,1
	jmp	gcdpoly50
gcdpoly80:
	xget	0,xb
	ret

gcdpolyset1:
	mov	si,[calcsp]
	mov	word ptr [si],polymask+3
	mov	word ptr [si+2],1
	mov	word ptr [si+4],1
	mov	word ptr [si+6],1
gcdpolyret:
	jmp	far ptr returnadr

	testmod	equ	65521

gcd_poly:
	checkcalcspfar	2
	mov	ax,[si]
	and	ax,lenmask
	jz	gcdpolyret	;if Y=0 then X is an answer
	mov	cx,[di]
	and	cx,lenmask
	jz	gcdpolycopyret	;if X=0 then Y is an answer
	mov	ax,[si+2]	;# of members
	mov	cx,[di+2]	;
	cmp	ax,1
	je	gcdpolyset1		;if Y=non0 const
	cmp	cx,1
	je	gcdpolyset1		;if X=non0 const

	mov	ax,2
	call	memoryalloc
	xput	xa,0
	xput	xb,1
	push	bx

	mov	si,[calcsp]
	set32
	xor	bx,bx
	mov	bx,testmod
	call	modebx_sipl
	set32
	or	dx,dx
	jz	gcdpolyin
	mov	si,[calcsp]
	sub	si,unitbyte
	set32
	xor	bx,bx
	mov	bx,testmod
	call	modebx_sipl
	set32
	or	dx,dx
	jz	gcdpolyin

	mov	di,[calcsp]
	lea	si,[di-unitbyte]
	set32
	push	word ptr [polymodulus]
	set32
	mov	word ptr [polymodulus],bx
	mov	ax,[si]
	mov	cx,[di]
	and	ax,lenmask
	and	cx,lenmask
	call	gcdmodpolysub		;gcd as modpoly
	set32
	pop	word ptr [polymodulus]
	mov	si,[calcsp]
	mov	ax,[si]
	and	ax,lenmask
	cmp	ax,2
	ja	gcdpolyin		;if gcd != const

	mov	ax,2
	call	memoryfree
	pop	bx
	jmp	gcdpolyret

gcdpolyin:
	pop	bx

	call	gcdpolysub
	mov	ax,2
	call	memoryfree

	call	integerpoly_calcsp
	call	normalizepoly_calcsp
	jmp	gcdpolyret

gcdpolycopyret:
	copy_si2di_ax
	jmp	gcdpolyret

gcdpolyilg:
	jmp	polyilgerr


;
;* tranfer polynomial to mod ebx polynomial
;
;	inp : [si] integer polynomial
;	    : ebx modulus  MUST be 16bit(i.e. higher 16 bits = 0)
;	out : [si] result
;	    : edx leading coeff
;	         if edx = 0 then the result is not true

modebx_sipl:
	push	si		;/1

	;store each answer as 16bit length

	lea	di,[si+4]
	add	si,2		;skip attribute
	mov	cx,[si]		;number of members
	add	si,2
modppllp:
	push	cx		;/2

	;for each coefficient

	mov	ax,[si]
	test	ax,attribmask
	jnz	modpplilg
	mov	cx,ax
	xor	dx,dx
	and	cx,lenmask
	jz	short modppljp3	;if 0

	add	si,cx
	add	si,cx		;highest word adr
	push	si		;/3
	push	ax		;/4
modppllp2:
	mov	ax,[si]
	sub	si,2
	div	bx
	myloop	modppllp2
	pop	ax		;4/
	test	ah,signmaskhigh
	jz	modppljp2	;if positive
	or	dx,dx
	jz	modppljp2	;if 0
	sub	dx,bx
	neg	dx
modppljp2:
	pop	si		;3/
modppljp3:
	mov	[di],dx
	add	di,2

	pop	cx		;2/
	add	si,2
	myloop	modppllp

	;keep dx until ret

	;extend to 32bit length

	sub	si,2		;highest word adr of answers
	pop	di		;1/
	add	di,2		;skip attrib
	mov	ax,[di]		;get # of members
	mov	cx,ax
	shl	ax,2
	add	di,ax		;highest dword adr
	set32
	xor	ax,ax
modppllp3:
	mov	ax,[si]		;get 16bit
	sub	si,2
	set32
	mov	[di],ax		;put 32bit
	sub	di,4
	myloop	modppllp3

	mov	ax,[di]		;get # of members
	lea	si,[di-2]
	inc	ax		;modulus
	shl	ax,1
	or	ax,modpolymask
	set32
	mov	[di],bx		;set modulus
	mov	[si],ax		;set attribute

	ret			;with dx = highest coeff
				;if dx = 0 then the degree is not true
modpplilg:
	jmp	polyilgerr


;
; * add polynomials
; [di]=[di]+[si]
; cannot be recursively called

addsubplplerror:
	jmp	far ptr systemerr

add_plmpl:
	jmp	polymoderr

go_add_plrf:
	jmp	add_numrf

add_numpl:
	mov	bx,di
	cmp	word ptr [di],0
	jne	add_pl10
	copy_si2di		;if [di]=0 then copy [si]
	jmp	far ptr returnadr

add_pl:
	cmp	ah,polymaskhigh
	je	add_plpl
	cmp	ah,modpolymaskhigh
	je	add_plmpl
	cmp	ah,ratpolymaskhigh
	je	go_add_plrf
	mov	bx,si
add_pl10:
	call	numer2poly2

add_plpl:

	; di = sp0
	; si = sp1

	checkcalcspfar	4

	mov	cx,[si]
	and	cx,lenmask
	jz	addsubplplerror	;no case of [si]=0

	mov	ax,[di]
	and	ax,lenmask
	jz	addsubplplerror	;no case of [di]=0

	inc	ax
	mov	cx,ax
	mov	si,di		;copy di to sp2
	sub	di,2*unitbyte
	mov	ax,di
	rep	movsw
	add	ax,4
	mov	[X_adr],ax	;adr of 0-th term of sp2

	mov	di,[calcsp]
	add	di,2
	lea	si,[di-unitbyte]
	lodsw			;# of members in [si]
	mov	[Y_adr],si
	mov	cx,[di]		;# of members in [di]
	add	di,2
	mov	[Z_adr],di
	mov	[non0Z_adr],di
	add	di,2*limitword
	sub	di,3
	mov	[Z_limadr],di

	;calc [Z_adr]:=[X_adr]+[Y_adr]

	sub	[calcsp],3*unitbyte

	cmp	ax,cx
	jne	addpoly100	;nonequal members

	call	addpolysub

	add	[calcsp],3*unitbyte

	xor	ax,ax
	mov	si,[calcsp]
	mov	cx,[non0_deg]
	inc	cx
	jcxz	addpoly50
	mov	[si+2],cx	;members
	mov	ax,[non0Z_adr]
	sub	ax,si
	shr	ax,1
	dec	ax
	or	ah,polymaskhigh
addpoly50:
	mov	[si],ax
addpolyout:
	jmp	far ptr returnadr

addpolyover:
	jmp	polyovrerr

addpoly100:
	push	ax		;# of members of [si]
	push	cx		;# of members of [di]
	cmp	ax,cx
	jae	addpoly120
	mov	cx,ax
addpoly120:
	call	addpolysub

	add	[calcsp],3*unitbyte

	pop	cx
	pop	ax
	mov	si,[X_adr]
	cmp	ax,cx
	jb	addpoly130	;[di] longer
	mov	si,[Y_adr]
	xchg	ax,cx
addpoly130:
	push	cx		;new # of members
	sub	cx,ax
	mov	di,[Z_adr]
addpoly140:
	push	cx
	mov	ax,[si]
	and	ax,lenmask
	inc	ax
	mov	cx,ax
	add	ax,ax
	add	ax,di
	cmp	ax,[Z_limadr]
	ja	addpolyover
	rep	movsw
	pop	cx
	myloop	addpoly140

	mov	si,[calcsp]
	mov	ax,di
	sub	ax,si
	shr	ax,1
	dec	ax
	or	ah,polymaskhigh
	mov	[si],ax

	pop	ax
	mov	[si+2],ax
	jmp	addpolyout


addpolysub:
	mov	[deg_now],0
	mov	[non0_deg],-1
addpolysub20:
	push	cx
	cmove3	0,[X_adr]
	mov	[X_adr],si

	cmove3	1,[Y_adr]
	mov	[Y_adr],si

	call	far ptr faradd_calcsp

	mov	si,[calcsp]
	mov	di,[Z_adr]
	mov	ax,[si]
	and	ax,lenmask
	mov	cx,ax
	inc	ax
	add	ax,ax
	add	ax,di
	cmp	ax,[Z_limadr]
	ja	addpolysubover
	movsw
	jcxz	addpolysub30
	rep	movsw
	mov	ax,[deg_now]
	mov	[non0_deg],ax
	mov	[non0Z_adr],di
addpolysub30:
	mov	[Z_adr],di
	inc	[deg_now]
	pop	cx
	myloop	addpolysub20
	ret

addpolysubover:
	jmp	polyovrerr


;
; * subtract polynomilas
;

subplplerror:
	jmp	far ptr systemerr

sub_plmpl:
	jmp	polymoderr

go_sub_plrf:
	jmp	sub_numrf

sub_numpl:
	mov	bx,di
	cmp	word ptr [di],0
	jne	sub_pl10
	push	di		;if [di] = 0
	copy_si2di		;then copy
	pop	si
	call	neg_polysi	;and change sign
	jmp	far ptr returnadr

sub_pl:
	cmp	ah,polymaskhigh
	je	sub_plpl
	cmp	ah,ratpolymaskhigh
	je	go_sub_plrf
	cmp	ah,modpolymaskhigh
	je	sub_plmpl
	mov	bx,si
sub_pl10:
	call	numer2poly2

sub_plpl:
	; di = sp0
	; si = sp1

	push	si
	call	neg_polysi
	pop	si
	jmp	add_plpl


;
; * negate polynomilas
;   inp : si = ptr
;   out : si = new ptr
;   ds : not always = ss

farneg_polysi:
	call	neg_polysi
	jmp	far ptr returnadr

neg_polysi:
	mov	ax,[si]
	add	si,2
negpolyin:
	and	ax,lenmask
	jz	negpolyout	;if 0
	mov	cx,[si]		;# of members
	add	si,2
negpoly10:
	call	neg_numeric2
	myloop	negpoly10
negpolyout:
	ret


;
; * multiplication of polynomial
;  [sp0]=[sp0]*[sp1]
;

mulplmoderr:
	jmp	polymoderr

mul_numpl:
	call	ex_calcsp2
	mov	[poly_operation],offset farmul_calcsp
	jmp	poly_scalar

mulpolyset0:
	mov	si,[calcsp]
	mov	word ptr [si],0
go_mulpolyout:
	jmp	mulpolyout

mul_pl:
	test	ah,nonnumericmaskhigh
	jnz	mul_pl10
	mov	[poly_operation],offset farmul_calcsp
	jmp	poly_scalar
mul_pl10:
	cmp	ah,polymaskhigh
	je	mul_plpl
	cmp	ah,ratpolymaskhigh
	je	go_mul_plrf
	cmp	ah,modpolymaskhigh
	je	mulplmoderr
	jmp	polyilgerr

go_mul_plrf:
	jmp	mul_numrf		;pl*rf -> rf


mul_plpl:
	checkcalcspfar	5	;5 levels

	mov	bx,[calcsp]	;copy X to [sp2]
	mov	si,bx
	lea	di,[bx-2*unitbyte]
	lodsw
	and	ax,lenmask
	jz	go_mulpolyout	;if X=zeropoly
	mov	cx,ax
	stosw
	rep	movsw

	cmp	word ptr [bx-unitbyte],0
	je	mulpolyset0	;if Y=zeropoly

	lea	di,[bx+4]
	mov	[Z_adr],di
	add	di,2*limitword-3
	mov	[Z_limadr],di

	sub	bx,unitbyte	;sp+1
	lea	si,[bx+2]
	lodsw			;# of members in Y
	dec	ax
	mov	[Y_deg],ax
	mov	[Y_baseadr],si

	sub	bx,unitbyte	;sp+2
	lea	si,[bx+2]
	lodsw			;# of members in X
	dec	ax
	mov	[X_deg],ax
	add	ax,[Y_deg]
	mov	[Z_deg],ax
	mov	[X_baseadr],si

	sub	bx,2*unitbyte
	mov	[calcsp],bx	;sp+4

	mov	[deg_now],0
	mov	cx,[Z_deg]
	inc	cx

	; loop for degree of result
mulpoly50:
	push	cx

	mov	di,[calcsp]	;clear temp adr
	mov	word ptr [di+unitbyte],0

	mov	ax,[deg_now]	;get start deg of Y
	mov	cx,ax
	cmp	ax,[Y_deg]
	jbe	mulpoly60
	mov	ax,[Y_deg]
mulpoly60:
	mov	[Y_tempdeg],ax

	mov	si,[X_baseadr]
	sub	cx,ax
	call	getpolypointer
	mov	[X_adr],si

	mov	cx,[Y_tempdeg]
	mov	ax,[deg_now]
	sub	ax,[X_deg]
	jb	mulpoly90
	sub	cx,ax
mulpoly90:
	inc	cx

	; start of subloop
mulpoly100:
	push	cx

	cmove3	0,[X_adr]
	mov	[X_adr],si

	mov	si,[Y_baseadr]
	mov	cx,[Y_tempdeg]
	call	getpolypointer
	mov	di,[calcsp]
	sub	di,unitbyte
	copy_si2di_ax

	call	far ptr farMul_calcsp

	add	[calcsp],unitbyte
	call	far ptr farAdd_calcsp	;add to temp
	sub	[calcsp],unitbyte

	dec	[Y_tempdeg]
	pop	cx
	myloop	mulpoly100

	; end of subloop

	mov	si,[calcsp]		;store result
	add	si,unitbyte		;of this degree
	call	store_si2Z

	inc	[deg_now]
	pop	cx
	myloop	mulpoly50

	add	[calcsp],4*unitbyte

	mov	si,[calcsp]
	mov	ax,[Z_adr]
	sub	ax,si
	shr	ax,1
	dec	ax
	or	ah,polymaskhigh
	mov	[si],ax
	mov	ax,[Z_deg]
	inc	ax
	mov	[si+2],ax	;members
mulpolyout:
	jmp	far ptr returnadr


;
; * power of poly
;
powpolyconst:			;if constpoly
	mov	di,bx		;trans to really const
	lea	si,[bx+4]
	copy_si2di_ax
	call	far ptr farPower_calcsp
	mov	bx,[calcsp]
	call	numer2poly2
	jmp	powpolyret

powpolyset1:
	mov	word ptr [bx],polymask+3
	mov	word ptr [bx+2],1
	mov	word ptr [bx+4],1
	mov	word ptr [bx+6],1
	jmp	powpolyret

powpoly_X?:
	cmp	word ptr [bx+4],0
	jne	powpoly10
	cmp	word ptr [bx+6],1
	jne	powpoly10
	cmp	word ptr [bx+8],1
	jne	powpoly10
	cmp	ax,limitword-3
	ja	powpolyover
	inc	ax
	mov	[bx+2],ax
	add	ax,2
	or	ah,polymaskhigh
	mov	[bx],ax
	lea	di,[bx+4]
	xor	ax,ax
	rep	stosw
	inc	ax
	stosw
	stosw
	jmp	powpolyret

powpolyilg:
	jmp	polyilgerr
powpolyover:
	jmp	polyovrerr

power_poly:
	checkcalcspfar	2
	mov	bx,[calcsp]
	mov	dx,[bx+2]
	dec	dx		;degree
	jz	powpolyconst	;if constpoly

	lea	si,[bx-unitbyte]
	lodsw
	cmp	ax,1
	ja	powpolyilg
	jb	powpolyset1	;if 0-th power
	lodsw
	mov	cx,ax		;power
	cmp	dx,1
	je	powpoly_X?
	mul	dx		;power*degree -> new degree
	or	dx,dx
	jnz	powpolyover
powpoly10:
	cmp	ax,limitword-2
	ja	powpolyover

	cmp	cx,2
	jbe	powpolyP1
	mov	ax,cx

	sub	[calcsp],unitbyte

	mov	si,bx		;copy poly to sp
	mov	di,[calcsp]
	copy_si2di

	mov	cx,16
polwpoly30:
	add	ax,ax
	dec	cx
	jnc	polwpoly30
				;now cx>0 because power>1
polwpoly50:
	push	cx
	push	ax
	cmove	1,0
	call	far ptr farMul_calcsp
	pop	ax
	add	ax,ax
	jnc	polypoly70
	push	ax
	cmove	1,-1
	call	far ptr farMul_calcsp
	pop	ax
polypoly70:
	pop	cx
	myloop	polwpoly50

	mov	si,[calcsp]
	lea	di,[si+unitbyte]
	mov	[calcsp],di
	copy_si2di_ax		;set result
powpolyret:
	jmp	far ptr returnadr

powpolyP1:
	cmp	cx,1
	je	powpolyret	;if ^1
	cmove	1,0		;if ^2
	call	far ptr farMul_calcsp
	jmp	powpolyret


;
; * polynomial // any

ratdiv_pl:
	test	ah,nonnumericmaskhigh
	jnz	ratdiv_pl10
	mov	[poly_operation],offset farratdiv_calcsp
	jmp	poly_scalar
ratdiv_pl10:
	cmp	ah,polymaskhigh
	je	go_ratdiv_plpl
	cmp	ah,ratpolymaskhigh
	je	go_ratdiv_plrf
	cmp	ah,modpolymaskhigh
	je	go_ratdivmoderr
	jmp	polyilgerr

go_ratdiv_plpl:
	jmp	div_plpl		;pl/pl -> rf
go_ratdiv_plrf:
	jmp	div_numrf		;pl/rf -> rf

go_ratdivmoderr:
	jmp	polymoderr


;
; * polynomilal / any
;

divmoderr:
	jmp	polymoderr

div_pl:
	test	ah,nonnumericmaskhigh
	jnz	div_pl10
	mov	[poly_operation],offset fardiv_calcsp
	jmp	poly_scalar
div_pl10:
	cmp	ah,polymaskhigh
	je	go_div_plpl
	cmp	ah,ratpolymaskhigh
	je	go_div_plrf
	cmp	ah,modpolymaskhigh
	je	divmoderr
	jmp	polyilgerr

go_div_plpl:
	jmp	div_plpl		;pl/pl -> rf
go_div_plrf:
	jmp	div_numrf		;pl/rf -> rf


;
; * polynomial \ polynomial
;

idivmoderr:
	jmp	polymoderr

idiv_pl:
	test	ah,nonnumericmaskhigh
	jnz	idiv_pl10
	mov	[poly_operation],offset farIdiv_calcsp
	jmp	poly_scalar		;poly\int
idiv_pl10:
	cmp	ah,polymaskhigh
	je	idiv_plpl
	cmp	ah,modpolymaskhigh
	je	idivmoderr
	jmp	polyilgerr

divpolyby0:
	jmp	far ptr diverr

divbybigger:
	mov	si,[calcsp]
	mov	bx,si
	mov	di,resadr
	copy_si2di_ax		;set remainder
	mov	word ptr [bx],0	;set result = 0
go_divpolyout:
	jmp	divpolyout

idiv_plpl:
	checkcalcspfar	5	;5 levels

	mov	bx,[calcsp]	;copy X to [sp2]
	mov	si,bx
	lea	di,[bx-2*unitbyte]
	lodsw
	and	ax,lenmask
	jz	go_divpolyout	;if X=zeropoly
	mov	cx,ax
	stosw
	rep	movsw

	cmp	word ptr [bx-unitbyte],0
	je	divpolyby0	;if Y=zeropoly

	lea	di,[bx+4]
	mov	[Z_adr],di
	add	di,2*limitword-3
	mov	[Z_limadr],di

	sub	bx,unitbyte	;sp+1
	lea	si,[bx+2]
	lodsw			;# of members in Y
	dec	ax
	mov	[Y_deg],ax
	mov	cx,ax
	call	getpolypointer
	mov	[Y_baseadr],si

	sub	bx,unitbyte	;sp+2
	lea	si,[bx+2]
	lodsw			;# of members in X
	dec	ax
	mov	[X_deg],ax
	mov	[X_tempdeg],ax
	sub	ax,[Y_deg]
	jb	divbybigger	;if deg Y > deg X
	mov	[Z_deg],ax
	mov	[X_baseadr],si

	sub	bx,unitbyte
	mov	[calcsp],bx	;sp+3

	mov	ax,[Z_deg]
	mov	[deg_now],ax

	; main loop

divpoly100:
	mov	si,[X_baseadr]
	mov	cx,[X_tempdeg]
	cmp	cx,[X_deg]
	jne	divpoly200	;expected coeff of X is 0

	call	getpolypointer
	mov	di,[calcsp]
	copy_si2di_ax

	cmove3	1,[Y_baseadr]
	call	far ptr farRatdiv_calcsp

	mov	ax,[Z_adr]
	mov	[constadr],ax
	mov	si,[calcsp]	;store result
	call	store_si2Z

	call	divpolysub

divpoly150:
	dec	[X_tempdeg]
	sub	[deg_now],1
	jnb	divpoly100

	; end of main loop

	add	[calcsp],3*unitbyte

	mov	si,[calcsp]
	mov	ax,[Z_adr]
	sub	ax,si
	shr	ax,1
	dec	ax
	or	ah,polymaskhigh
	mov	[si],ax
	mov	ax,[Z_deg]
	inc	ax
	mov	[si+2],ax	;members

	call	poly_reverse	; order reversing
	cmove2	resadr,2	;set remainder
divpolyout:
	jmp	far ptr returnadr

divpoly200:
	mov	si,[calcsp]	;store result
	mov	word ptr [si],0
	call	store_si2Z
	jmp	divpoly150

divpolyover:
	jmp	polyovrerr


	; X = X - x^(n-m)*const*Y
	; X     in sp-1
	; const in [constadr]
	; Y     in sp-2
	;  all must be non 0
	;  use sp0 as work
divpolysub:
	push	[Z_adr]
	push	[Z_limadr]

	mov	di,[calcsp]
	add	di,2
	mov	ax,di
	add	ax,2*limitword-1
	mov	[Z_limadr],ax

	mov	ax,[X_deg]
	stosw
	lea	si,[di+unitbyte]
	sub	ax,[Y_deg]
	jz	divpolysub20
divpolysub10:			;copy lower part of X to Z
	copy_si2di
	dec	ax
	jnz	divpolysub10
divpolysub20:
	mov	[X_adr],si	
	mov	[Z_adr],di

	mov	ax,[calcsp]
	add	ax,2*unitbyte+4
	mov	[Y_adr],ax
	sub	ax,3*unitbyte+4
	mov	[calcsp],ax	;* sp+1

	mov	si,[Y_adr]
	mov	cx,[si-2]	;# of elements
	dec	cx		;highest word must become 0
	jz	divpolysub60	;if Y is const
divpolysub50:
	push	cx
	cmove3	0,[Y_adr]
	mov	[Y_adr],si
	cmove3	1,[constadr]
	call	far ptr farMul_calcsp

	mov	si,[calcsp]
	call	neg_numeric2

	cmove3	1,[X_adr]
	mov	[X_adr],si

	call	far ptr farAdd_calcsp

	mov	si,[calcsp]
	call	store_si2Z

	pop	cx
	myloop	divpolysub50
divpolysub60:	
	add	[calcsp],unitbyte	;*

	; replace X and decide degree

	mov	si,[calcsp]
	add	si,2
	lodsw			;(old # of X) -1
	lea	di,[si+unitbyte]
	mov	dx,ax
	inc	dx		;non0degree
	mov	bx,di		;non0adr
	or	ax,ax
	jz	divpolysub100	;X was const = X is now 0
	push	ax
divpolysub70:
	mov	cx,[si]
	movsw
	and	cx,lenmask
	jz	divpolysub80
	rep	movsw
	mov	bx,di		;non0adr
	mov	dx,ax
divpolysub80:
	dec	ax
	jnz	divpolysub70

	pop	ax
	inc	ax
	sub	ax,dx
	jz	divpolysub100	;if result is 0

	mov	si,[calcsp]
	add	si,unitbyte
	mov	[si+2],ax	;new # of X
	dec	ax
	mov	[X_deg],ax
	sub	bx,si
	shr	bx,1
	dec	bx
	or	bh,polymaskhigh
	mov	[si],bx
divpolysubout:
	pop	[Z_limadr]
	pop	[Z_adr]
	ret

divpolysub100:
	mov	si,[calcsp]
	add	si,unitbyte
	mov	[si],ax		;set X = 0
	dec	ax
	mov	[X_deg],ax
	jmp	divpolysubout

;
; * numeric in [bx] -> poly
;   destroy : nothing
;
numer2poly2ilg:
	jmp	polyilgerr
numer2poly2over:
	jmp	polyovrerr

numer2poly2:
  if flg32
	pusha
  else
	push	ax
	push	cx
	push	si
	push	di
  endif
	mov	ax,[bx]
	test	ah,nonnumericmaskhigh
	jnz	numer2poly2ilg	;not a number
	and	ax,lenmask
	jz	numer2poly2out
	mov	cx,ax
	inc	cx
	mov	si,bx
	add	si,ax
	add	si,ax		;highest adr
	add	ax,2
	cmp	ax,limitword
	ja	numer2poly2over
	lea	di,[si+4]
	std
	rep	movsw
	cld
	mov	word ptr [bx+2],1	;# of members
	or	ah,polymaskhigh
	mov	[bx],ax
numer2poly2out:
  if flg32
	popa
  else
	pop	di
	pop	si
	pop	cx
	pop	ax
  endif
	ret	

;
; * store result in [calcsp] to [Z_adr]
;
store_si2Z:
	mov	di,[Z_adr]
	mov	ax,[si]
	and	ax,lenmask
	inc	ax
	mov	cx,ax
	add	ax,ax
	add	ax,di
	cmp	ax,[Z_limadr]
	ja	polyover
	rep	movsw
	mov	[Z_adr],di
	ret
polyover:
	jmp	polyovrerr

;
; * goes to the addr assigned by CX
;   range is not checked

getpolypointer:
	jcxz	getpptrret
getppr10:
	lodsw
	and	ax,lenmask
	add	ax,ax
	add	si,ax
	myloop	getppr10
getpptrret:
	ret

;
; * negate numeric and pl/mpl
;

neg_numpl2:
	mov	cx,[si]
	add	si,2
	mov	ax,cx
	and	ch,attribmaskhigh
	jz	negnumerif		;if integer
	cmp	ch,polymaskhigh
	je	go_negpoly
	cmp	ch,modpolymaskhigh
	je	go_negmodpoly
	test	ch,compratmaskhigh
	jnz	negnumer100
	jmps	negnumerif
go_negpoly:
	jmp	negpolyin
go_negmodpoly:
	jmp	negmodpolyin


;
; * negate numeric data
;     in  : si = pointer
;     out : si = next pointer
; destroy : ax

neg_numeric2:
	mov	ax,[si]
	add	si,2
	test	ah,compratmaskhigh
	jnz	negnumer100
negnumerif:
	and	ax,lenmask
	jz	negnumer50
negnumer30:
	xor	byte ptr [si-1],signmaskhigh	;change sign
negnumer40:
	add	ax,ax
	add	si,ax
negnumer50:
	ret

negnumer100:			;if complex
	test	ah,ratmaskhigh
	jnz	negnumer150
	lodsw			;real part
	and	ax,lenmask
	jz	negnumer110
	xor	byte ptr [si-1],signmaskhigh
	add	ax,ax
	add	si,ax
negnumer110:
	lodsw			;imaginary part
	and	ah,lenmaskhigh
	jmp	negnumer30

negnumer150:			;if rational
	xor	byte ptr [si+1],signmaskhigh	;change sign
	and	ah,lenmaskhigh
	jmp	negnumer40


comment %
;
; * copy with negate numeric data
;     in  : ds:si = src pointer
;	  : es:di = dst pointer
;     out : ds:si = new src pointer
;	  : es:di = new dst pointer
; destroy : ax

neg_numeric_copy2:
	mov	ax,[si]
	add	si,2
	mov	cx,ax
	test	ah,compratmaskhigh
	jnz	negnumcopy100		;if complex or rational

;if int/float
negnumcopysub:
	and	cx,lenmask
	jz	negnumcopy50
negnumcopy30:
	xor	ah,signmaskhigh		;change sign
	mov	es:[di],ax
	add	di,2
	rep	movsw
	ret
negnumcopy50:
	mov	es:[di],ax
	add	di,2
	ret

negnumcopy100:
	test	ah,ratmaskhigh
	jnz	negnumcopy150

;if complex
;then negate re and im both

	mov	ax,[si]		;real part
	add	si,2
	mov	cx,ax
	call	negnumcopysub

	mov	ax,[si]			;imaginary part
	add	si,2
	mov	cx,ax
	jmp	negnumcopysub

;if rational
;then negate num only

negnumcopy150:
	mov	ax,[si]		;num
	add	si,2
	mov	cx,ax
	call	negnumcopysub

	mov	ax,[si]		;den
	add	si,2
	mov	cx,ax
	mov	es:[di],ax
	and	cx,lenmask
	add	di,2
	rep	movsw
	ret
%

;
; * reversing the order of polynomial in [calcsp]
;  use 1 more calcsp
;  destroy nothing

poly_reverse:
  if FLG32
	pusha
  else
	push	ax
	push	bx
	push	cx
	push	dx
	push	si
	push	di
  endif
	call	ahedsp2
	mov	bx,si
	mov	di,si
	add	si,unitbyte
	mov	[calcsp],si
	copy_si2di_ax

	add	bx,4			;start of original
	lea	di,[bx+unitbyte]	;start of result
	mov	cx,[bx-2]
polyrev10:
	push	cx
	mov	si,bx
	dec	cx
	call	getpolypointer
	copy_si2di_ax
	pop	cx
	myloop	polyrev10

  if FLG32
	popa
  else
	pop	di
	pop	si
	pop	dx
	pop	cx
	pop	bx
	pop	ax
  endif
	ret



;
; * value of a polynomial
;   F * A

gocalcsperr1:
	jmp	far ptr calcsperr

valpolyconst:
	lea	di,[si-4]
	mov	[calcsp],di
	copy_si2di_ax
	jmp	far ptr returnadr

val_poly:
	mov	bx,[calcsp]
	lea	si,[bx+unitbyte]
	sub	bx,unitbyte
	cmp	bx,[calcsp_limit]
	jb	gocalcsperr1
	mov	[calcsp],bx
	lodsw
	lodsw
	dec	ax
	jz	valpolyconst	;if const
	mov	cx,ax
	push	ax
	push	si		;X_base
	call	getpolypointer
	mov	di,[calcsp]
	copy_si2di_ax		;copy X to calcsp
	pop	si		;X_base
	pop	cx		;# of members-1
valpoly10:
	push	cx
	push	si		;X_base
	cmove	1,-1		;copy A to sp+1
	call	far ptr farMul_calcsp	;mul to F

	pop	si		;X_base
	pop	cx
	push	cx
	push	si		;X_base
	dec	cx
	call	getpolypointer
	mov	di,[calcsp]
	sub	di,unitbyte
	copy_si2di_ax		;copy X to sp+1
	call	far ptr farAdd_calcsp	;add to F
	pop	si		;X_base
	pop	cx
	myloop	valpoly10

	mov	si,[calcsp]
	lea	di,[si+2*unitbyte]
	mov	[calcsp],di
	copy_si2di_ax
	jmp	far ptr returnadr

;
; * polynomial scalar operation
;

poly_scalar:
	checkcalcspfar	4

	mov	bx,[calcsp]	;copy X to [sp2]
	mov	si,bx
	lea	di,[bx-2*unitbyte]
	copy_si2di_ax

	lea	di,[bx+4]
	mov	[Z_adr],di
	mov	[non0Z_adr],di
	mov	[non0_deg],-1

	add	di,2*limitword-3
	mov	[Z_limadr],di

	sub	bx,unitbyte	;sp+1
	mov	[constadr],bx

	sub	bx,unitbyte	;sp+2
	lea	si,[bx+2]
	lodsw			;# of members in X
	dec	ax
	mov	[X_deg],ax
	mov	[X_adr],si

	sub	bx,unitbyte
	mov	[calcsp],bx	;sp+3

	mov	[deg_now],0

	;loop for degree of result
polysca50:
	cmove3	0,[X_adr]
	mov	[X_adr],si

	cmove3	1,[constadr]

	call	dword ptr [poly_operation]

	mov	si,[calcsp]		;store result
	cmp	word ptr [si],0
	pushf
	call	store_si2Z
	popf
	je	polysca60
	mov	ax,[Z_adr]
	mov	[non0Z_adr],ax
	mov	ax,[deg_now]
	mov	[non0_deg],ax
polysca60:
	inc	[deg_now]
	sub	[X_deg],1
	jnb	polysca50

	mov	si,[calcsp]
	add	si,3*unitbyte
	mov	[calcsp],si

	mov	ax,[non0_deg]
	inc	ax
	jz	polysca90	;if 0
	mov	[si+2],ax	;# of members
	mov	ax,[non0Z_adr]
	sub	ax,si
	shr	ax,1
	dec	ax
	or	ah,polymaskhigh
polysca90:
	mov	[si],ax

	cmp	[poly_operation],offset faridiv_calcsp
	je	polysca110
polysca100:
	jmp	far ptr returnadr

polysca110:
	; clear resadr because it has no meaning

	mov	si,resadr
	mov	word ptr [si],stringmask1char
	mov	word ptr [si+2],"?"
	jmp	polysca100

;
; * leading coefficient of polynomial
;
polysynerr:
lcoeffsynerr:
	jmp	far ptr synerr

lcoeffin:
	call	far ptr farKakko
	mov	si,[calcsp]
	lodsw
	and	ah,attribmaskhigh
	cmp	ah,polymaskhigh
	je	lcoeff_poly
	cmp	ah,modpolymaskhigh
	je	lcoeff_modpoly
	cmp	word ptr [si-2],0
	jne	lcoeffilgerr
	jmp	far ptr returnadr

lcoeffilgerr:
	jmp	polyilgerr

lcoeff_poly:
	lea	di,[si-2]	;base adr
	lodsw			;# of terms
	dec	ax		;degree
	jz	lcoeffpoly20
	mov	cx,ax
lcoeffpoly10:
	lodsw
	and	ax,lenmask
	add	ax,ax
	add	si,ax
	myloop	lcoeffpoly10
lcoeffpoly20:
	copy_si2di_ax
	jmp	far ptr returnadr

lcoeff_modpoly:
	lea	di,[si-2]	;base adr
	mov	ax,[di]
	and	ax,lenmask
	sub	ax,2
	add	ax,ax
	add	si,ax
	mov	cx,1
	set32
	mov	ax,[si]
	set32
	mov	[di+2],ax
	set32
	shr	ax,16
	or	ax,ax
	jz	lcoeffmpjp
	inc	cx
lcoeffmpjp:
	mov	[di],cx
	jmp	far ptr returnadr

;
; * constant term of polynomial
;
ccoeffsynerr:
	jmp	polysynerr

ccoeffin:
	call	far ptr farKakko
	mov	si,[calcsp]
	lodsw
	and	ah,attribmaskhigh
	cmp	ah,polymaskhigh
	je	ccoeff_poly
	cmp	ah,modpolymaskhigh
	je	ccoeff_modpoly
	cmp	word ptr [si-2],0
	jne	ccoeffilgerr
	jmp	far ptr returnadr

ccoeffilgerr:
	jmp	polyilgerr

ccoeff_poly:
	lea	di,[si-2]
	add	si,2
	copy_si2di_ax
	jmp	far ptr returnadr

ccoeff_modpoly:
	lea	di,[si-2]	;base adr
	add	si,4		;skip modulus
	xor	cx,cx
	set32
	mov	ax,[si]
	set32
	or	ax,ax
	jz	ccoeffmpjp
	inc	cx
	set32
	mov	[di+2],ax
	set32
	shr	ax,16
	or	ax,ax
	jz	ccoeffmpjp
	inc	cx
ccoeffmpjp:
	mov	[di],cx
	jmp	far ptr returnadr


;
; * multiplication of polynomials with modulo
;
modmulsynerr:
	jmp	polysynerr
modmulilg:
	jmp	polyilgerr

modmulset0:
	mov	si,[calcsp]
	mov	word ptr [si],0
go_modmulout:
	jmp	modmulout

modmulin:
	call	far ptr farFormul
	mov	si,[calcsp]
	mov	al,[si+1]
	and	al,attribmaskhigh
	cmp	al,polymaskhigh
	jne	modmulilg
	cmp	byte ptr [bp],0c2h
	jne	modmulsynerr
	inc	bp
	call	far ptr farFormul
	mov	si,[calcsp]
	mov	al,[si+1]
	and	al,attribmaskhigh
	cmp	al,polymaskhigh
	jne	modmulilg
	cmp	byte ptr [bp],0c2h
	jne	modmulsynerr
	inc	bp
	call	far ptr farKakko
	mov	si,[calcsp]
	mov	al,[si+1]
	and	al,lenmaskhighcpl
	jnz	modmulilg

	add	si,2*unitbyte
	mov	[calcsp],si

	;now X in sp, Y in sp+1, mod in sp+2 

	checkcalcspfar	6	;6 levels

	mov	bx,[calcsp]	;copy X to [sp3]
	mov	si,bx
	lea	di,[bx-3*unitbyte]
	lodsw
	and	ax,lenmask
	jz	go_modmulout	;if X=zeropoly
	mov	cx,ax
	stosw
	rep	movsw

	cmp	word ptr [bx-unitbyte],0
	je	modmulset0	;if Y=zeropoly

	lea	di,[bx+4]
	mov	[Z_adr],di
	add	di,2*limitword-3
	mov	[Z_limadr],di

	sub	bx,unitbyte	;sp+1
	lea	si,[bx+2]
	lodsw			;# of members in Y
	dec	ax
	mov	[Y_deg],ax
	mov	[Y_baseadr],si

	sub	bx,2*unitbyte	;sp+3
	lea	si,[bx+2]
	lodsw			;# of members in X
	dec	ax
	mov	[X_deg],ax
	add	ax,[Y_deg]
	mov	[Z_deg],ax
	mov	[X_baseadr],si

	sub	bx,2*unitbyte
	mov	[calcsp],bx	;sp+5

	mov	[deg_now],0
	mov	cx,[Z_deg]
	inc	cx

	;loop for degree of result
modmul50:
	push	cx

	mov	di,[calcsp]	;clear temp adr
	mov	word ptr [di+unitbyte],0

	mov	ax,[deg_now]	;get start deg of Y
	mov	cx,ax
	cmp	ax,[Y_deg]
	jbe	modmul60
	mov	ax,[Y_deg]
modmul60:
	mov	[Y_tempdeg],ax

	mov	si,[X_baseadr]
	sub	cx,ax
	call	getpolypointer
	mov	[X_adr],si

	mov	cx,[Y_tempdeg]
	mov	ax,[deg_now]
	sub	ax,[X_deg]
	jb	modmul90
	sub	cx,ax
modmul90:
	inc	cx

	; start of subloop
modmul100:
	push	cx

	cmove3	0,[X_adr]
	mov	[X_adr],si

	mov	si,[Y_baseadr]
	mov	cx,[Y_tempdeg]
	call	getpolypointer
	mov	di,[calcsp]
	sub	di,unitbyte
	copy_si2di_ax

	call	far ptr farMul_calcsp
	cmove	1,-3
	call	far ptr farRes_calcsp	

	add	[calcsp],unitbyte
	call	far ptr farAdd_calcsp	;add to temp
	sub	[calcsp],unitbyte

	dec	[Y_tempdeg]
	pop	cx
	myloop	modmul100

	; end of subloop

	cmove	0,-1
	cmove	1,-3
	call	far ptr farRes_calcsp	
	mov	si,[calcsp]		;store result of this degree
	call	store_si2Z

	inc	[deg_now]
	pop	cx
	myloop	modmul50

	add	[calcsp],5*unitbyte

	mov	bx,[calcsp]
	mov	ax,[Z_deg]
	inc	ax
	mov	cx,ax
	inc	ax
	push	ax
	mov	dx,ax
	xor	di,di
	lea	si,[bx+4]
modmul200:
	lodsw
	and	ax,lenmask
	jz	modmul210
	add	ax,ax
	add	si,ax
	mov	dx,cx
	mov	di,si
modmul210:
	myloop	modmul200
	pop	ax
	sub	ax,dx
	jz	modmul220
	mov	[bx+2],ax
	mov	ax,di
	sub	ax,bx
	shr	ax,1
	dec	ax
	or	ah,polymaskhigh
modmul220:
	mov	[bx],ax

modmulout:
	jmp	far ptr returnadr


;
; modpower of polynomial
;

MODPOWERROR2:
	jmp	polyilgerr


modpow_modpoly:
	;check A

	mov	si,[calcsp]
	add	si,2*UNITBYTE
	mov	ax,[si]
	and	ah,attribmaskhigh
	cmp	ah,modpolymaskhigh
	jne	MODPOWERROR2	;not polynomial
	jmps	modpow_polyin

modpow_poly:
	;check A

	mov	si,[calcsp]
	add	si,2*UNITBYTE
	mov	ax,[si]
	and	ah,attribmaskhigh
	cmp	ah,polymaskhigh
	jne	MODPOWERROR2	;not polynomial

modpow_polyin:
	push	bp

	call	ahedsp2

	;check B

	mov	si,[calcsp]
	add	si,2*UNITBYTE
	mov	cx,[si]
	test	ch,attribmaskhigh
	JNZ	MODPOWERROR2	;not positive integer

	; A=A@N

	cmove	0,-3
	cmove	1,-1
	call	far ptr farIdiv_calcsp
	cmove3	-3,resadr

	cmove3	0,resadr	;initial value of the result
	 
	;MAIN loop

	MOV	SI,[calcsp]
	add	si,2*unitbyte	;B ‚ÌˆÊ’u
	MOV	CX,[SI]
	OR	CX,CX
	JMPZ	MODPOWpolySET1	;B=0 ‚È‚ç‚Î“š‚¦‚Í 1(*‚É—Dæ)

	mov	di,[calcsp]
	add	di,2*UNITBYTE
	cmp	word ptr [di],0
	JMPZ	MODPOWpolySET0	;A ‚ª 0 ‚È‚ç‚Î“š‚¦‚Í 0(*)

MODPOW10:
	;highest word

	add	si,cx
	add	si,cx

	mov	ax,[si]		;highest word
	wdec	si

	push	cx		;/*length
	push	si

	mov	cx,16		;get bit length of MSW
	or	ah,ah
	jnz	modpow12
	xchg	al,ah
	mov	cx,8
modpow12:
	add	ax,ax
	dec	cx
	jnc	modpow12
	jcxz	modpow15	;MSW = 1
modpow13:
	push	cx
	add	ax,ax
	push	ax
	call	modpow_poly_1bit
	pop	ax
	pop	cx
	loop	modpow13

modpow15:
	pop	si
	pop	cx		;*/length

	dec	cx
	jmpz	modpow90	;no more word

	;other words
modpow20:
	mov	ax,[si]
	wdec	si

	push	cx
	push	si

	mov	cx,16
modpowlp:
	push	cx
	add	ax,ax
	push	ax
	call	modpow_poly_1bit
	pop	ax
	pop	cx
	loop	modpowlp

	pop	si
	pop	cx
	loop	modpow20

modpow90:
	cmove	-3,0
	add	[calcsp],3*UNITBYTE

MODPOW100:
	pop	bp
	jmp	far ptr returnadr


MODPOWpolySET0:
	MOV	SI,[CALCSP]
	add	si,3*UNITBYTE
	mov	[calcsp],si
	MOV	word ptr [SI],0
	JMP	MODPOW100

MODPOWpolySET1:
	MOV	di,[CALCSP]
	add	di,3*UNITBYTE
	mov	[calcsp],di
	mov	ax,[di]
	and	ah,attribmaskhigh
	cmp	ah,modpolymaskhigh
	je	modpolyset1
	mov	al,3
	stosw
	mov	ax,1
	stosw
	stosw
	stosw
	JMP	MODPOW100
modpolyset1:
	mov	al,4
	stosw
	mov	word ptr [di+4],1	;skip modulus
	mov	word ptr [di+6],0
	jmp	modpow100


modpow_poly_1bit:
	pushf
	cmove	1,0
	call	far ptr farmul_calcsp
	cmove	1,-1
	call	far ptr farIdiv_calcsp	;[sp0]=A^2@N
	cmove3	0,resadr
	popf
	JNC	modpowpoly1ret

	cmove	1,-3
	call	far ptr farmul_calcsp
	cmove	1,-1
	call	far ptr farIdiv_calcsp	;[sp0]=A^2@N*orinalA@N
	cmove3	0,resadr
modpowpoly1ret:
	ret


;
; * print a modpoly
;

printmodpoly:
	call	printmodpolysub
	jmp	far ptr print_calcsp_out

printmodpolysub:
	call	prspc2
	mov	ax,[si]
	and	ax,lenmask
				;jz	prmodpolyzero(no case)
	mov	cx,ax
	add	ax,ax
	shr	cx,1
	dec	cx
	add	si,ax
	sub	si,2		;print from highest dword
	mov	bx,cx		;memo
	push	si		;/* highest adr
prmodpoly10:
	push	bx
	set32
	mov	ax,[si]
	set32
	or	ax,ax
	jz	prmodpoly20	;if =0 then skip
	set32
	push	ax
	cmp	cx,bx
	je	prmodpoly11	;if 1st then skip
	call	prspc2		;print '+'
	mov	al,'+'
	call	prchr2
	call	prspc2
prmodpoly11:
	set32
	pop	ax
	set32
	xor	bx,bx
	inc	bx		;ebx=1
	set32
	cmp	ax,bx
	ja	prmodpoly12	;if >=2 then must print
	cmp	cx,1		;if =1 and if deg>0 then skip
	jne	prmodpoly14
prmodpoly12:
	set32
	mov	bx,ax
	call	far ptr farprntebx
	cmp	cx,1
	je	prmodpoly20	;if deg=0 then skip
	mov	al,'*'
	call	prchr2
prmodpoly14:
	mov	al,'X'
	call	prchr2		;print 'X'
	cmp	cx,2
	je	prmodpoly20	;if deg=1 then skip
	mov	al,'^'		;print power index
	call	prchr2
	mov	ax,cx
	dec	ax
	mov	bx,ax
	call	far ptr farprntbx
prmodpoly20:
	sub	si,4
	pop	bx
	myloop	prmodpoly10
	pop	si		;*/
	add	si,2
	ret


;
; * print a polynomial
;

printpolyset0:
	mov	word ptr [si],0
	call	far ptr farPrint_calcsp
	jmp	printpoly100

printpoly:
	call	printpolysub
	jmp	far ptr print_calcsp_out


printpolysub:
	mov	ax,word ptr [plusmark]
	push	ax			;push	word ptr [postmark]
	mov	word ptr [plusmark],0	;mov	[postmark],0
	or	al,al
	jz	printpoly5
	call	prchr2
printpoly5:
	checkcalcspfar	2
	mov	si,[calcsp]
	mov	bx,si
	lea	di,[si-unitbyte]
	copy_si2di

	mov	si,[calcsp]
	mov	ax,[si+2]	;number of elements
	or	ax,ax
	jz	printpolyset0
	mov	[degnowP1],ax	;degree + 1 
	mov	bx,ax
	sub	[calcsp],2*unitbyte
printpoly10:			;must reserve bx,dx in this loop
	call	getstr$srcptr	;si = source pointer
	mov	ax,[si]
	and	ax,lenmask
	jz	printpoly90	;if =0 then skip
	push	di
	mov	di,[calcsp]
	mov	cx,ax
	inc	cx
	rep	movsw		;copy to calcsp
	pop	di
	call	getsign		;get sign & make positive
	cmp	bx,[degnowP1]
	je	printpoly40	;if 1st
	call	prspc2
	call	prchr2
	call	prspc2
	jmps	printpoly50
printpoly40:
	cmp	al,'+'
	je	printpoly50	;if 1st and + then skip
	call	prchr2
printpoly50:
	cmp	[degnowP1],1
	je	printpolysetout	;deg=0 then end
	mov	si,[calcsp]
	mov	ax,[si]
	mov	ch,ah
	and	ah,lenmaskhigh
	cmp	ax,1
	ja	printpoly60	;if >=2words then must print
	cmp	word ptr [si+2],1
	ja	printpoly60	;if >=2 then must print
	test	ch,attribmaskhigh
	jz	printpoly80	;if =1 then skip
printpoly60:
	test	ch,attribmaskhigh
	jz	printpoly70
	mov	al,'('		;if not integer then enclose by ()
	call	prchr2
	call	far ptr farPrint_calcsp
	mov	al,')'
	call	prchr2
	jmps	printpoly75
printpoly70:
	call	far ptr farPrint_calcsp
printpoly75:
	mov	al,'*'
	call	prchr2
printpoly80:
	cmp	[degnowP1],1
	je	printpoly95	;if deg=0 then end
	mov	al,[varmark]
	call	prchr2
	cmp	[degnowP1],2
	je	printpoly90	;if deg=1 then skip
	mov	al,'^'		;print power index
	call	prchr2

	mov	ax,[degnowP1]
	dec	ax
	mov	[degnowP1],ax
	mov	si,[calcsp]
	mov	word ptr [si],1
	mov	[si+2],ax
	call	far ptr farPrint_calcsp
	jmp	printpoly10

printpoly90:
	dec	[degnowP1]
	jnz	printpoly10

printpoly95:
	add	[calcsp],2*unitbyte
printpoly100:
	pop	word ptr [plusmark]
	ret

printpolysetout:
	call	far ptr farPrint_calcsp
	jmp	printpoly95



str$polyset0:
	mov	al,'0'
	stosb
	jmp	str$poly100

str$poly:
	checkcalcspfar	2
	mov	ax,word ptr [plusmark]	;push	word ptr [postmark]
	push	ax
	mov	word ptr [plusmark],0	;mov	[postmark],0

	mov	si,[calcsp]
	mov	bx,si
	lea	di,[si-unitbyte]
	copy_si2di

	lea	di,[bx+2]	;di = dest adr
	mov	dx,di
	add	dx,2*limitword	;dx = limit of di

	or	al,al
	jz	str$poly5
	stosb
str$poly5:
	mov	si,[calcsp]
	sub	si,unitbyte
	mov	ax,[si+2]	;number of elements
	or	ax,ax
	jz	str$polyset0
	mov	[degnowP1],ax	;degree + 1 
	mov	bx,ax
	sub	[calcsp],2*unitbyte
str$poly10:			;must reserve bx,dx in this loop
	call	getstr$srcptr	;si = source pointer
	mov	ax,[si]
	and	ax,lenmask
	jz	str$poly90	;if =0 then skip
	push	di
	mov	di,[calcsp]
	mov	cx,ax
	inc	cx
	rep	movsw		;copy to calcsp
	pop	di
	call	getsign		;get sign & make positive
	cmp	bx,[degnowP1]
	je	str$poly40	;if 1st
	mov	ah,al
	mov	al,' '
	stosw
	stosb
	jmps	str$poly50
str$poly40:
	cmp	al,'+'
	je	str$poly50	;if 1st and + then skip
	stosb
str$poly50:
	cmp	[degnowP1],1
	je	str$polysetout	;deg=0 then end
	mov	si,[calcsp]
	mov	ax,[si]
	mov	ch,ah
	and	ah,lenmaskhigh
	cmp	ax,1
	ja	str$poly60	;if >=2words then must print
	cmp	word ptr [si+2],1
	ja	str$poly60	;if >=2 then must print
	jmps	str$poly80	;if =1 then skip
str$poly60:
	test	ch,attribmaskhigh
	jz	str$poly70
	mov	al,'('		;if not integer then enclose by ()
	stosb
	call	str$packsub
	mov	al,')'
	stosb
	jmps	str$poly75
str$poly70:
	call	str$packsub
str$poly75:
	mov	al,'*'
	stosb
str$poly80:
	cmp	[degnowP1],1
	je	str$poly95	;if deg=0 then end
	mov	al,[varmark]
	stosb
	cmp	[degnowP1],2
	je	str$poly90	;if deg=1 then skip
	mov	al,'^'		;print power index
	stosb

	mov	ax,[degnowP1]
	dec	ax
	mov	[degnowP1],ax
	call	str$prntax
	jmp	str$poly10

str$poly90:
	dec	[degnowP1]
	jnz	str$poly10

str$poly95:
	add	[calcsp],2*unitbyte
str$poly100:
	pop	ax
	mov	word ptr [plusmark],ax
	or	ah,ah
	jz	str$poly105
	mov	al,ah
	stosb
str$poly105:
	mov	ax,di
	mov	si,[calcsp]
	sub	ax,si
	dec	ax
	shr	ax,1
	jc	str$poly110
	mov	byte ptr [di],0
	inc	di
	or	ah,80h
str$poly110:
	cmp	di,dx
	ja	str$polyover
	or	ah,stringmaskhigh
	mov	[si],ax
	retf

str$polysetout:
	call	str$packsub
	jmp	str$poly95

str$polyover:
	jmp	far ptr ovrerr


getstr$srcptr:
	push	ax
	push	cx
	mov	si,[calcsp]
	add	si,unitbyte+4
	mov	cx,[degnowP1]
	dec	cx
	jz	str$srcout
str$src10:
	lodsw
	and	ah,lenmaskhigh
	add	ax,ax
	add	si,ax
	myloop	str$src10
str$srcout:
	pop	cx
	pop	ax
	ret


getsign:
	mov	si,[calcsp]
getsign10:
	lodsw
	test	ah,ratmaskhigh
	jnz	getsign10	;if rational then see next word
	test	ah,80h
	jz	getsignpositive
	and	ah,7fh		;make positive
	mov	[si-2],ax
getsignnegative:
	mov	al,'-'
	ret
getsignpositive:
	mov	al,'+'
	ret


str$modpoly:
	mov	di,si
	mov	dx,si
	add	dx,limitword*2+2	;limit adr
	call	ahedsp2
	xchg	si,di
	copy_si2di

	mov	si,[calcsp]
	lea	di,[si+unitbyte+2]

	mov	al,[plusmark]
	or	al,al
	jz	str$modpoly5
	stosb
str$modpoly5:
	mov	ax,[si]
	and	ax,lenmask
	mov	cx,ax
	shr	cx,1
	dec	cx
	mov	bx,cx		;memo
	add	ax,ax
	add	si,ax
	sub	si,2		;print from highest dword
str$modpoly10:
	set32
	mov	ax,[si]
	set32
	or	ax,ax
	jz	str$modpoly20	;if =0 then skip
	set32
	push	ax
	cmp	cx,bx
	je	str$modpoly11	;if 1st then skip
	mov	al,' '
	mov	ah,'+'
	stosw
	stosb
str$modpoly11:
	set32
	pop	ax
	push	cx
	set32
	xor	cx,cx
	inc	cx		;ecx=1
	set32
	cmp	ax,cx
	pop	cx
	ja	str$modpoly12	;if >=2 then must print
	cmp	cx,1		;if =1 and if deg>0 then skip
	jne	str$modpoly14
str$modpoly12:
	call	str$prnteax
	cmp	cx,1
	je	str$modpoly20	;if deg=0 then skip
	mov	al,'*'
	stosb
str$modpoly14:
	mov	al,'X'
	stosb
	cmp	cx,2
	je	str$modpoly20	;if deg=1 then skip
	mov	al,'^'		;print power index
	stosb
	mov	ax,cx
	dec	ax
	call	str$prntax
str$modpoly20:
	sub	si,4
	cmp	di,dx
	ja	str$modpolyover
	myloop	str$modpoly10
str$modpoly30:
	mov	al,[postmark]
	or	al,al
	jz	str$modpoly35
	stosb
str$modpoly35:
	mov	cx,di
	mov	si,[calcsp]
	add	si,unitbyte
	mov	[calcsp],si
	sub	cx,si
	dec	cx
	shr	cx,1
	jc	str$modpoly40
	mov	byte ptr [di],0
	or	ch,80h
str$modpoly40:
	or	ch,stringmaskhigh
	mov	[si],cx
	retf

str$modpolyzero:
	mov	al,'0'
	stosb
	jmps	str$modpoly30

str$modpolyover:
	jmp	far ptr ovrerr


ex_calcsp2:
	mov	si,[calcsp]
	lea	di,[si-unitbyte]
	mov	cx,[si]
	mov	dx,[di]
	mov	[di],cx
	mov	[si],dx
	and	cx,lenmask
	and	dx,lenmask
	cmp	cx,dx
	jae	ex_silonger
ex_dilonger:
	xchg	si,di
	jmps	excalc10
ex_silonger:
	xchg	cx,dx
excalc10:
	sub	dx,cx
	jcxz	excalc30
excalc20:
	add	si,2
	add	di,2
	mov	ax,[si]
	mov	bx,[di]
	mov	[di],ax
	mov	[si],bx
	myloop	excalc20
excalc30:
	mov	cx,dx
	jcxz	excalc100
	add	si,2
	add	di,2
	rep	movsw
excalc100:
	ret


;
; * rational poly to integer poly
; must reserve bx

integerpoly_calcsp:
	push	bx

integerpolyin:
	mov	si,[calcsp]
	add	si,2
	mov	cx,[si]		;number of members
	add	si,2
intpllp:
	mov	ax,[si]
	add	si,2
	mov	dx,ax
	and	ah,attribmaskhigh
	jz	intpljp
	cmp	ah,ratmaskhigh
	je	intplrational
	jne	intplout
intpljp:
	and	dx,lenmask
	add	dx,dx
	add	si,dx
	myloop	intpllp

intplout:
	pop	bx
	ret

intplrational:
	mov	ax,[si]
	add	si,2
	and	ax,lenmask
	add	ax,ax
	add	si,ax
	mov	di,[calcsp]
	sub	di,unitbyte
	mov	cx,[si]
	and	cx,lenmask
	inc	cx
	rep	movsw
	call	far ptr farmul_calcsp
	jmp	integerpolyin

;
; * normalize INTEGER polynomial
;   let GCD of all coeffs to 1
; must reserve bx

normalizepoly_calcsp:
	push	bx

	call	ahedsp2
	setspm1	si
	add	si,2
	mov	cx,[si]		;number of members
	add	si,2
	mov	ax,[si]
	test	ah,attribmaskhigh
	jnz	normalplout
	dec	cx
	jz	normalplset1
	push	cx
	mov	cx,ax
	setsp0	di
	and	cx,lenmask
	inc	cx
	rep	movsw
	pop	cx
normalpllp:
	mov	di,[calcsp]
	cmp	word ptr [di],1
	jne	normalpl20
	cmp	word ptr [di+2],1
	je	normalplout
normalpl20:
	mov	ax,[si]
	test	ah,attribmaskhigh
	jnz	normalplout
	push	cx
	mov	cx,ax
	setsp1	di
	and	cx,lenmask
	inc	cx
	rep	movsw
	push	si
	call	far ptr fargcd_calcsp
	pop	si
	pop	cx
	myloop	normalpllp
	add	[calcsp],unitbyte
	call	far ptr faridiv_calcsp
	pop	bx
	ret

normalplout:
	add	[calcsp],unitbyte
	pop	bx
	ret

normalplset1:
	mov	si,[calcsp]
	add	si,unitbyte
	mov	[calcsp],si
	mov	ax,[si]
	and	ax,attribmask
	add	ax,3
	mov	[si],ax
	mov	ax,1
	mov	[si+2],ax
	mov	[si+4],ax
	mov	[si+6],ax
	pop	bx
	ret

code2	ends
