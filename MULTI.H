;
;macro definition for memory handling
;

	xa	equ	0
	xb	equ	unitseg
	xc	equ	unitseg*2
	xd	equ	unitseg*3
	xg	equ	unitseg*4
	xw	equ	unitseg*5

xmul	macro
	push	bx
	call	far ptr farmul_calcsp
	pop	bx
endm

xadd	macro
	push	bx
	call	far ptr faradd_calcsp
	pop	bx
endm

xsub	macro
	push	bx
	call	far ptr farsub_calcsp
	pop	bx
endm

xidiv	macro
	push	bx
	call	far ptr faridiv_calcsp
	pop	bx
endm

xputboth	macro	dst1,dst2,src
	mov	si,[calcsp]
  if src
	sub	si,src*unitbyte
  endif
	mov	ax,dst1
	mov	dx,dst2
	call	xputbothsub
endm

xput	macro	dst,src
	mov	si,[calcsp]
  if src
	sub	si,src*unitbyte
  endif
	mov	ax,dst
	call	xputsub
endm

xget	macro	dst,src
	mov	di,[calcsp]
  if dst
	sub	di,dst*unitbyte
  endif
	mov	ax,src
	call	xgetsub
endm

xreduce	macro	xa,xb,xg
	mov	ax,xa
	mov	cx,xb
	mov	dx,xg
	call	xreducesub
endm

;macro definition for complex & rational arithmetic

setspm3	macro	reg
	mov	reg,[calcsp]
	add	reg,unitbyte*3
endm

setspm2	macro	reg
	mov	reg,[calcsp]
	add	reg,unitbyte*2
endm

setspm1	macro	reg
	mov	reg,[calcsp]
	add	reg,unitbyte
endm

setsp0	macro	reg
	mov	reg,[calcsp]
endm

setsp1	macro	reg
	mov	reg,[calcsp]
	sub	reg,unitbyte
endm

setsp2	macro	reg
	mov	reg,[calcsp]
	sub	reg,unitbyte*2
endm

setsp3	macro	reg
	mov	reg,[calcsp]
	sub	reg,unitbyte*3
endm

setsp4	macro	reg
	mov	reg,[calcsp]
	sub	reg,unitbyte*4
endm


checkcalcsp	macro	depth
	local	exit

	mov	ax,[calcsp]
	sub	ax,unitbyte*depth
	cmp	ax,[calcsp_limit]
	jae	exit
	jmp	CALCSPERR
exit:
endm

checkcalcspfar	macro	depth
	local	exit

	mov	ax,[calcsp]
	sub	ax,unitbyte*depth
	cmp	ax,[calcsp_limit]
	jae	exit
	jmp	far ptr CALCSPERR
exit:
endm


;
; make positive
; valid only for integer and float
; no meaning for rational and complex

makepos	macro	param
	mov	di,[calcsp]
    if param
	sub	di,unitbyte*param
    endif
	and	byte ptr [di+1],signmaskhighCPL
endm


;
; [di] *= 2
; use only for integer
; destroy other data

cshl	macro	param
	mov	di,[calcsp]
   if param
	sub	di,unitbyte*param
   endif
	call	shiftleft_di
endm


;
;
cdiv	macro	dst,src
	mov	si,[calcsp]
   if dst
	lea	di,[si-unitbyte*dst]
   else
	mov	di,si
   endif
   if src
	sub	si,unitbyte*src
   endif
	call	divIorFdisi
endm


cidiv	macro	dst,src
	mov	si,[calcsp]
   if dst
	lea	di,[si-unitbyte*dst]
   else
	mov	di,si
   endif
   if src
	sub	si,unitbyte*src
   endif
	call	idivIIdisi
endm


cidivfar	macro	dst,src
	mov	si,[calcsp]
   if dst
	lea	di,[si-unitbyte*dst]
   else
	mov	di,si
   endif
   if src
	sub	si,unitbyte*src
   endif
	call	far ptr faridivIIdisi
endm


cmul	macro	dst,src
	mov	si,[calcsp]
   if dst
	lea	di,[si-unitbyte*dst]
   else
	mov	di,si
   endif
   if src
	sub	si,unitbyte*src
   endif
	call	mulIorFdisi
endm


csquare	macro	dst
	mov	di,[calcsp]
   if dst
	sub	di,unitbyte*dst
   endif
	call	squareIFCdi
endm


csquarefar	macro	dst
	mov	di,[calcsp]
   if dst
	sub	di,unitbyte*dst
   endif
	call	far ptr farsquareIFCdi
endm


;
; change sign
; valid only for integer and float
; no meaning for rational, complex, ...

chgsign	macro	dst
	local	cneg_out

	mov	di,[calcsp]
   if dst
	sub	di,unitbyte*dst
   endif
	call	chgsigndi
cneg_out:
endm


;
; [di] = unsigned int value
;
putword	macro	dst,value
	mov	di,[calcsp]
	mov	ax,1
   if dst
	sub	di,unitbyte*dst
   endif
	stosw
	mov	ax,value
	stosw
endm


csub	macro	dst,src
	mov	si,[calcsp]
   if dst
	lea	di,[si-unitbyte*dst]
   else
	mov	di,si
   endif
   if src
	sub	si,unitbyte*src
   endif
	call	subAAdisi
endm


cadd	macro	dst,src
	mov	si,[calcsp]
   if dst
	lea	di,[si-unitbyte*dst]
   else
	mov	di,si
   endif
   if src
	sub	si,unitbyte*src
   endif
	call	addAAdisi
endm


caddfar	macro	dst,src
	mov	si,[calcsp]
   if dst
	lea	di,[si-unitbyte*dst]
   else
	mov	di,si
   endif
   if src
	sub	si,unitbyte*src
   endif
	call	far ptr faraddAAdisi
endm


cmove	macro	dst,src
	mov	si,[calcsp]
   if dst
	lea	di,[si-unitbyte*dst]
   else
	mov	di,si
   endif
   if src
	sub	si,unitbyte*src
   endif
	lodsw
	stosw
	and	ax,lenmask
	mov	cx,ax
	rep	movsw
endm


cmove2	macro	dst,src
	mov	si,[calcsp]
	mov	di,dst
   if src
	sub	si,unitbyte*src
   endif
	lodsw
	stosw
	and	ax,lenmask
	mov	cx,ax
	rep	movsw
endm


cmove3	macro	dst,src
	mov	di,[calcsp]
	mov	si,src
   if dst
	sub	di,unitbyte*dst
   endif
	lodsw
	stosw
	and	ax,lenmask
	mov	cx,ax
	rep	movsw
endm


cmovereal	macro	dst,src
	mov	si,[calcsp]
   if dst
	lea	di,[si-unitbyte*dst]
   else
	mov	di,si
   endif
	sub	si,unitbyte*src-2
	lodsw
	stosw
	and	ax,lenmask
	mov	cx,ax
	rep	movsw
endm

cmoveimag	macro	dst,src
	mov	si,[calcsp]
   if dst
	lea	di,[si-unitbyte*dst]
   else
	mov	di,si
   endif
	sub	si,unitbyte*src-2
	lodsw
	and	ax,lenmask
	add	ax,ax
	add	si,ax
	lodsw
	stosw
	and	ax,lenmask
	mov	cx,ax
	rep	movsw
endm

cmoverealimag	macro	dstre,dstim,src
	mov	bx,[calcsp]
	lea	si,[bx-unitbyte*src+2]
   if dstre
	lea	di,[bx-unitbyte*dstre]
   else
	mov	di,bx
   endif
	lodsw
	stosw
	and	ax,lenmask
	mov	cx,ax
	rep	movsw

   if dstim
	lea	di,[bx-unitbyte*dstim]
   else
	mov	di,bx
   endif
	lodsw
	stosw
	and	ax,lenmask
	mov	cx,ax
	rep	movsw
endm


cstore	macro
	mov	bx,[calcsp]
	mov	si,bx
	mov	di,WORK3
	lodsw
	stosw
	and	ax,lenmask
	mov	cx,ax
	rep	movsw

	lea	si,[bx-unitbyte]
	mov	di,WORK4
	lodsw
	stosw
	and	ax,lenmask
	mov	cx,ax
	rep	movsw
endm


cmovereal2	macro	dst,src
	mov	si,src+2
	mov	di,[calcsp]
	lodsw
   if dst
	sub	di,unitbyte*dst
   endif
	stosw
	and	ax,lenmask
	mov	cx,ax
	rep	movsw
endm

cmoveimag2	macro	dst,src
	mov	si,src+2
	mov	di,[calcsp]
	lodsw
   if dst
	sub	di,unitbyte*dst
   endif
	and	ax,lenmask
	add	ax,ax
	add	si,ax
	lodsw
	stosw
	and	ax,lenmask
	mov	cx,ax
	rep	movsw
endm


cmovereal3	macro	dst,src
	mov	si,[calcsp]
	mov	di,dst
   if src
	sub	si,unitbyte*src-2
   else
	add	si,2
   endif
	lodsw
	stosw
	and	ax,lenmask
	mov	cx,ax
	rep	movsw
endm

cmoveimag3	macro	dst,src
	mov	si,[calcsp]
	mov	di,dst
   if src
	sub	si,unitbyte*src-2
   else
	add	si,2
   endif
	lodsw
	and	ax,lenmask
	add	ax,ax
	add	si,ax
	lodsw
	stosw
	and	ax,lenmask
	mov	cx,ax
	rep	movsw
endm

copyrealsi	macro	dst
	add	si,2
	mov	di,dst
	lodsw
	stosw
	and	ax,lenmask
	mov	cx,ax
	rep	movsw
endm

copyimagsi	macro	dst
	add	si,2
	mov	di,dst
	lodsw
	and	ax,lenmask
	add	ax,ax
	add	si,ax
	lodsw
	stosw
	and	ax,lenmask
	mov	cx,ax
	rep	movsw
endm

setimagtopsi	macro
	mov	ax,[si+2]
	add	si,4
	and	ax,lenmask
	add	si,ax
	add	si,ax
endm


;
; [bx] = [si] + i[di]
;

cset	macro	real,imag
	mov	bx,[calcsp]
	lea	si,[bx-unitbyte*real]
	lea	di,[bx-unitbyte*imag]
	jmp	setcomplex	;call & ret
endm


set_pi	macro	dst
	mov	si,[calcsp]
   if dst
	sub	si,unitbyte*dst
   endif
	call	pai10
endm


caddFF	macro	dst,src
	mov	si,[calcsp]
   if dst
	lea	di,[si-unitbyte*dst]
   else
	mov	di,si
   endif
   if src
	sub	si,unitbyte*src
   endif
	call	addFFdisi
endm


csubFF	macro	dst,src
	mov	si,[calcsp]
   if dst
	lea	di,[si-unitbyte*dst]
   else
	mov	di,si
   endif
   if src
	sub	si,unitbyte*src
   endif
	call	subFFdisi
endm


csetFc	macro	dst,constnum
	mov	di,[calcsp]
	mov	ax,constnum
  if dst
	sub	di,unitbyte*dst
  endif
	call	floatsetdiax
endm


cmulFc	macro	dst,constnum
	mov	di,[calcsp]
	mov	ax,constnum
   if dst
	sub	di,unitbyte*dst
   endif
	call	floatmuldiax
endm


;store i*constnum

csetImdi	macro	constnum
	mov	ax,3+complexmask
	stosw
	xor	ax,ax
	stosw
	inc	ax
	stosw
	mov	word ptr [di],constnum
endm

