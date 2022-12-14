;FUNC3.ASM


DATA	SEGMENT	WORD PUBLIC

	public	degnowP1

	extrn	varmark:byte,postmark:byte,plusmark:byte
	extrn	calcsp:word,calcsp_limit:word,environment:word
	extrn	defsegdata:word,polymodulus:dword
	extrn	xpos:byte,ypos:byte,chars1:byte,btmline:byte
  if graph
       	extrn	chxpos:word,chypos:word
       	extrn	viewx1:word,viewy1:word,viewy2:word
  endif
	extrn	fnamebuf:byte
	extrn	pointword:word
;	extrn	packeddata:word,packedlength:word,packedptr:word
	extrn	ascend:word
	extrn	X_adr:word,Z_adr:word,Z_limadr:word,deg_now:word
	extrn	schoolflg:byte
	extrn	machinetype:word

degnowP1	dw	?

DATA	ENDS


CODE	SEGMENT WORD PUBLIC
	ASSUME	CS:CODE,DS:DATA

	public	func3in,polyin,returnadr,linkpack

	extrn	formul:near,farformul:far
	extrn	kakko:near,kakko_ax:near,farkakko_ax:far
	extrn	get_ax:near,farget_ax:far
	extrn	getvadr:near,fargetvadr:far
	extrn	ahedsp:near
	extrn	resin:near
	extrn	idivIIdisi:near,idivin:near,mulin:near
	extrn	floorin:near,ceilin:near

	extrn	farKANJI1ST?:far
	extrn	farKAKKO:far
	extrn	farBinasc:far
	extrn	farPrint_calcsp:far,print_calcsp_out:far
	extrn	farmul_calcsp:far
	extrn	farRes_calcsp:far
	extrn	farmulIIdisi:far,fargcdreswork2:far
	extrn	farsquareIdi:far
	extrn	faraddAAdisi:far
	extrn	farchgsigndi:far

	extrn	synerr:near,ilgerr:near,calcsperr:near
	extrn	ovrerr:near,systemerr:near

FUNC3IN:	
;	pop	ax		;return address offset
;	push	cs		;set stack for RETF
;	push	ax		;
	jmp	far ptr func3main

;
; * jumped from code to return
; A(in CODE) が B(in CODE) を call し、B が C(in CODE) に jump
; し、C から直接 A に戻っていたが、C が CODE2 に移ったので
; B から C へは far jump に代え、C からこの returnadr に far jump
; することにした。
returnadr:
	ret


;
; * link pack
;
linkpack_pack:
	mov	bx,di
	mov	ax,[si+2]
	add	[di+2],ax	;new # of members
	mov	ax,[di]
	and	ax,lenmask
	mov	dx,ax		;memo old len
	inc	ax
	add	ax,ax
	add	di,ax

	lodsw
	and	ax,lenmask
	dec	ax
	mov	cx,ax
	add	ax,dx
	cmp	ax,limitword
	ja	linkpackover
	add	si,2
	rep	movsw
	or	ah,packmaskhigh
	mov	[bx],ax
	ret

linkpackover:
	jmp	ovrerr
linkpackilgerr:
	jmp	ilgerr

linkpack:
	call	get2args
	backsp_mac
	mov	ah,[si+1]
	mov	al,[di+1]
	and	ax,attribmaskdouble
	cmp	ax,packmaskdouble
	je	linkpack_pack
	cmp	al,packmaskhigh
	je	linkpack_nonpack
	cmp	ah,packmaskhigh
	je	linknonpack_pack
	jmp	linkpackilgerr		;both nonpack

linknonpack_pack:
	mov	bx,di			;base adr
	mov	ax,[di]
	mov	dx,[si]
	and	ax,lenmask
	and	dx,lenmask
	inc	ax
	mov	cx,ax
	add	ax,dx
	cmp	ax,limitword
	ja	linkpackover

	;slide up 1st data

	push	si
	add	di,cx
	add	di,cx
	lea	si,[di-2]
	add	di,2
	push	di
	std
	rep	movsw
	cld

	or	ah,packmaskhigh
	mov	[bx],ax			;set new attribute

	;append second data

	pop	di
	pop	si
	add	di,2
	mov	cx,dx
	mov	dx,[si+2]	;memo old # of members
	add	si,4
	inc	dx
	dec	cx
	mov	[bx+2],dx	;set new # of members
	rep	movsw
	ret

linkpack_nonpack:
	mov	bx,di
	inc	word ptr [di+2]	;inc # of members
	mov	ax,[di]
	and	ax,lenmask
	mov	dx,ax		;memo old len
	inc	ax
	add	ax,ax
	add	di,ax

	mov	ax,[si]
	and	ax,lenmask
	inc	ax
	mov	cx,ax
	add	ax,dx
	cmp	ax,limitword
	ja	linkpackover
	rep	movsw
	or	ah,packmaskhigh
	mov	[bx],ax
	ret


;
; * set polynomial
;

setmodpolyin:
	set32
	mov	[si-2],ax	;store modulus
	add	si,2
	mov	[packedptr],si
dwpoly10:
	mov	ax,[packedlength]
	add	ax,2
	cmp	ax,limitword
	ja	polyovererr
	mov	[packedlength],ax

	call	formul
	mov	si,[calcsp]
	mov	dh,[si+1]
	and	dh,attribmaskhigh
	jnz	polyilgerr	;if not integer

	call	ahedsp
	set32
	mov	ax,word ptr [polymodulus]
	set32
	mov	[si+2],ax
	set32
	shr	ax,16
	mov	cx,1
	or	ax,ax
	jz	dwpoly15
	inc	cx
dwpoly15:
	mov	 [si],cx
	call	resin		;[di] = [di] @ polymodulus

	mov	ax,[calcsp]
	mov	si,ax
	add	ax,unitbyte
	mov	[calcsp],ax
	set32
	xor	ax,ax
	mov	cx,[si]
	add	si,2
	or	cx,cx
	jz	dwpoly20
	set32
	mov	ax,[si]
	dec	cx
	jnz	dwpoly20
	set32			;cut higher 16 bit
	shl	ax,16		;
	set32			;
	shr	ax,16		;
dwpoly20:
	mov	di,[packedptr]
	set32
	stosw
	mov	[packedptr],di

	mov	al,[bp]
	inc	bp
	cmp	al,0c2h		;,
	je	dwpoly10
	cmp	al,')'
	jne	polysynerr

	mov	cx,di		;search nonzero highest
	mov	si,[calcsp]
	sub	cx,si
	sub	cx,6
	shr	cx,2
	set32
	xor	ax,ax
	sub	di,4
	std
	set32
	repe	scasw
	cld
	je	dwpoly230	;all zero
	add	cx,2		;recover over decrement by scasd + modulus
	shl	cx,1
	or	ch,modpolymaskhigh
dwpoly230:
	mov	di,[calcsp]
	mov	[di],cx
	jmp	polyout



polyilgerr:
	jmp	ilgerr
polyovererr:
	jmp	ovrerr
polysynerr:
	jmp	synerr


polyin:
	cmp	byte ptr [bp],')'
	je	polyilgerr	;empty poly is ilegal

	push	[packeddata]
	push	[packedlength]
	push	[packedptr]

	call	ahedsp
	add	si,4
	mov	[packedptr],si
	mov	[packeddata],0
	mov	[packedlength],1

	set32
	mov	ax,word ptr [polymodulus]
	set32
	or	ax,ax
	jnz	setmodpolyin

poly10:
	call	formul
	mov	si,[calcsp]
	mov	dh,[si+1]
	and	dh,attribmaskhigh
	jz	poly30		;if integer
	cmp	dh,pointmaskhigh
	je	poly30		;if fraction
	cmp	dh,ratmaskhigh
	je	poly30		;if rational
	cmp	dh,complexmaskhigh
	jne	polyilgerr
poly30:
	mov	ax,[calcsp]
	mov	si,ax
	add	ax,unitbyte
	mov	[calcsp],ax
	mov	ax,[si]
	and	ax,lenmask
	inc	ax
	mov	cx,ax
	add	ax,[packedlength]
	cmp	ax,limitword
	ja	polyovererr
	mov	[packedlength],ax
	inc	[packeddata]
	mov	di,[packedptr]
	rep	movsw
	mov	[packedptr],di
	mov	al,[bp]
	inc	bp
	cmp	al,0c2h		;,
	je	poly10
	cmp	al,')'
	jne	polysynerr

	mov	di,[calcsp]
	add	di,2
	mov	cx,[packeddata]	;search nonzero highest
	xor	bx,bx
	xor	dx,dx
	lea	si,[di+2]
poly120:
	inc	bx
	lodsw
	and	ax,lenmask
	jz	poly130
	mov	dx,bx		;nonzero position
	shl	ax,1
	add	si,ax
	mov	di,si		;
poly130:
	myloop	poly120

	mov	ax,di
	mov	di,[calcsp]
	sub	ax,di
	shr	ax,1
	dec	ax
	jz	poly140		;all zero
	or	ah,polymaskhigh
	mov	[di+2],dx
poly140:
	mov	[di],ax

polyout:
	pop	[packedptr]
	pop	[packedlength]
	pop	[packeddata]
	ret

;
; * lcm
;
LCMIN:
	checkcalcsp	4
	call	formul
lcmlp:
	cmp	byte ptr [bp],0c2h	;code of ,
	jne	lcmsynerr
	inc	bp
	call	formul			;get next argument
	call	lcmsub
	cmp	byte ptr [bp],')'
	jne	lcmlp
	inc	bp
	ret
lcmsynerr:
	jmp	synerr


lcm_etc:
	sub	[calcsp],2*unitbyte	;+2
	cmove	-1,-3
	cmove	0,-2
	call	GCD_ENT			;+1
	call	idivin			;0
	jmp	mulin			;-1 call & ret


lcmsub:
	mov	si,[calcsp]
	lea	di,[si+unitbyte]	;di=old argument

	mov	al,[di+1]
	mov	ah,[si+1]
	and	ax,attribmaskdouble
	jnz	lcm_etc

	mov	ax,[si]
	mov	dx,[di]

	cmp	word ptr [si],0
	je	lcmsub0
	cmp	word ptr [di],0
	je	lcmsub0

	call	GETGCD

	mov	di,[calcsp]
	mov	si,work3	;GCDADR
	call	idivIIdisi
	cmul	-1,0
	add	[calcsp],unitbyte
	ret

lcmsub0:
	mov	word ptr [si],0
	mov	word ptr [si+unitbyte],0
	add	[calcsp],unitbyte
	ret

code	ends


code2	segment	public
	assume	cs:code2,ds:data

	public	ahedsp2,backsp2,stringmember
	public	farStr$ent,str$packsub,str$prntax,str$prnteax

	extrn	prchr2:near,prspc2:near
	extrn	store_si2Z:near,monicin:near
	extrn	lcoeffin:near,ccoeffin:near,modmulin:near
	extrn	GET_WORLD_X:near,GET_WORLD_Y:near
	extrn	farSETFNAME:far
	extrn	str$poly:near,str$modpoly:near

;	extrn	gettime100:near

;	extrn	farARCTAN:far,farSQRTIN:far
	extrn	farADDIN:far,farSUBIN:far
;	extrn	readbin:near,writebin:near


  if JAPANESE
	extrn	kanji1st2:near
  endif
  	extrn	dotcolor:near	;,gxxfer:near,gyxfer:near


func3other:
	add	al,0aeh
	cmp	al,91h		;polymod
	jne	func3synerr
	jmp	funcpolymod
func3synerr:
	jmp	far ptr synerr
func3ilgerr:
	jmp	far ptr ilgerr
func3ovrerr:
	jmp	far ptr ovrerr

func3main:
	INC	BP		;inc pointer
	MOV	AL,[BP]
	INC	BP
	SUB	AL,0aeH
	jb	func3other
	CMP	AL,51H		;51H=FfH-aeH
	JA	FUNC3SYNERR
	XOR	BX,BX
	MOV	BL,AL
	SHL	BX,1
	JMP	CS:FUNC_TBL3[BX]


	EVEN
FUNC_TBL3	label	word
	dw	cpu_ds,cpu_es
	dw	cpu_ax,cpu_bx,cpu_cx,cpu_dx
	dw	cpu_si,cpu_di,cpu_bp,cpu_flg

	dw	fcos,fsin,ftan,fatan
	dw	fsqrt,flog,flog2,flog10

	DW	dotcolor,instr,instr2,find2
	dw	numerator,denominator,posxin,posyin
	dw	hexin,upperin,lowerin,inpin
	dw	typein,attrib,varptr,scankey
	dw	zenkaku,hankaku,cutspace,cutleftspace
	dw	mapx,mapy,peekbyte,peekword
	dw	gposxin,gposyin,existin,degin
	dw	diffin,monicin,lcoeffin,ccoeffin
	dw	modmulin,verin,peekstring,lcm
	dw	getenv,modsqrt,keyup,keydown
	dw	bitor,bitand,bitxor,bitset
	dw	bitreset,bitreverse,bitcount,keyleft
	dw	keyright,floor,ceil,asin
	dw	acos,gettime100,sysIDin,exponent
	dw	significand,sizeof,linkpackin,pointset
	dw	polyconvin,polyrevin


;,readbin,writebin

;
;* cpu registers
;
cpu_ds:
	jmp	far ptr farcpu_ds
cpu_es:
	jmp	far ptr farcpu_es
cpu_ax:
	jmp	far ptr farcpu_ax
cpu_bx:
	jmp	far ptr farcpu_bx
cpu_cx:
	jmp	far ptr farcpu_cx
cpu_dx:
	jmp	far ptr farcpu_dx
cpu_si:
	jmp	far ptr farcpu_si
cpu_di:
	jmp	far ptr farcpu_di
cpu_bp:
	jmp	far ptr farcpu_bp
cpu_flg:
	jmp	far ptr farcpu_flg


;
;* polynomial conversion
;
polyconvin:
	jmp	far ptr farpolyconvin

;
;* polynomial reverse order
;
polyrevin:
	jmp	far ptr farpolyrevin

;
;* binary file read write
;
;readbin:
;	jmp	far ptr farreadbin
;writebin:
;	jmp	far ptr farwritebin
;
;
;* link pack
;
linkpackin:
	jmp	far ptr linkpack


;
;* system ID
;
sysIDin:
	call	far ptr farKakko_AX
	or	ax,ax
	jz	countryID
	dec	ax
	jz	machineID
	dec	ax
	jz	cpuID
	jmp	func3ilgerr
countryID:
;  if JAPANESE
;	mov	ax,51h
;	jmps	sysID60
; else
  	mov	dx,[calcsp]
	mov	ax,3800h
	int	21h
	mov	ax,bx
	jmps	sysID50
;  endif

cpuID:
	mov	ax,[machinetype]
	jmps	sysID50
machineID:
	mov	ax,[machinetype]
	mov	al,ah
sysID50:
	xor	ah,ah
sysID60:
	mov	si,[calcsp]
	mov	word ptr [si],1
	mov	[si+2],ax
	jmp	far ptr returnadr


;
; * floor
;
floor:
	jmp	far ptr	floorin

;
; * ceil
;
ceil:
	jmp	far ptr ceilin

;
; * bitcount
;
bitcount:
	call	far ptr farkakko
	mov	si,[calcsp]
	lodsw
	test	ah,LENMASKHIGHCPL
	jnz	bitcountilgerr		;must be non-negative integer
	or	ax,ax
	jz	bitcountret		;if 0
	mov	bx,ax
	xor	dx,dx
bitcount10:
	lodsw
	mov	cx,16			;16 bits
bitcount20:
	shl	ax,1
	adc	dx,0
	myloop	bitcount20

	dec	bx
	jnz	bitcount10

	mov	si,[calcsp]
	mov	word ptr [si],1
	mov	[si+2],dx
bitcountret:
	jmp	far ptr returnadr

bitcountilgerr:
	jmp	func3ilgerr

;
; * bitreverse
;
bitreverse:
	call	bitsetsub		;target is (ax-1)*16 + ch-th bit
	mov	di,[calcsp]
	mov	bx,[di]
	cmp	ax,bx
	ja	bitsethigher		;set it
	sub	bx,ax
	shl	ax,1
	add	di,ax
	mov	ax,1
	mov	cl,ch
	rol	ax,cl
	xor	[di],ax
	jmp	bitreset30


;
; * bitreset
;
bitreset:
	call	bitsetsub		;target is (ax-1)*16 + ch -thbit
	mov	di,[calcsp]
	mov	bx,[di]
	cmp	ax,bx
	ja	bitsetret		;already reset
	sub	bx,ax
	shl	ax,1
	add	di,ax
	mov	ax,0fffeh
	mov	cl,ch
	rol	ax,cl
	and	[di],ax
bitreset30:
	or	bx,bx
	jnz	bitsetret
	mov	si,[calcsp]
	mov	cx,[si]
	xor	ax,ax
	std
	repe	scasw
	cld
	je	bitreset50
	inc	cx
bitreset50:
	mov	[si],cx
	jmp	bitsetret


;
; * bitset
;
bitset:
	call	bitsetsub		;target is (ax-1)*16 + ch -thbit
	mov	di,[calcsp]
	mov	bx,[di]
	cmp	ax,bx
	ja	bitsethigher
	shl	ax,1
	add	di,ax
	mov	ax,1
	mov	cl,ch
	rol	ax,cl
	or	[di],ax
bitsetret:
	jmp	far ptr returnadr

bitsethigher:
	mov	[di],ax			;new length
	inc	bx
	add	di,bx
	add	di,bx

	mov	dx,cx			;memo shift count
	mov	cx,ax
	sub	cx,bx
	xor	ax,ax
	rep	stosw
	mov	ax,1
	mov	cl,dh
	rol	ax,cl
	mov	[di],ax
	jmp	bitsetret


bitsetsub:
	call	far ptr farget_AX
	push	ax

	cmp	byte ptr [bp],0c2h	;code of ,
	jne	get2intssynerr
	inc	bp

	call	far ptr farkakko
	mov	si,[calcsp]
	lodsw
	test	ah,LENMASKHIGHCPL
	jnz	get2intsilgerr		;must be positive integer

	pop	ax
	mov	ch,al			;memo lower
	and	ch,0fh
	mov	cl,4
	shr	ax,cl			;now target = ch-th bit of [2*ax]
	inc	ax
	cmp	ax,limitword
	ja	bitsetilgerr
	ret

bitsetilgerr:
	jmp	func3ilgerr


;
; * bitor
;
bitor:
	call	get2ints
	mov	si,[calcsp]
	lea	di,[si+unitbyte]
	mov	[calcsp],di
	mov	dx,[si]
	add	si,2
	mov	bx,[di]
	cmp	bx,dx			;bx(di):1st dx(si):2nd
	jbe	bitor50			;2nd longer

;	mov	[di],bx
	add	di,2
	mov	cx,dx
bitor10:
	jcxz	bitor30
bitor20:
	lodsw
	or	[di],ax
	add	di,2
	myloop	bitor20
bitor30:
	jmps	bitorret

bitor50:
	mov	[di],dx
	add	di,2
	mov	cx,bx
	jcxz	bitor70
bitor60:
	lodsw
	or	[di],ax
	add	di,2
	myloop	bitor60
bitor70:
	mov	cx,dx
	sub	cx,bx
	rep	movsw
bitorret:
	jmp	far ptr returnadr

;
; * bitand
;
bitand:
	call	get2ints
	mov	si,[calcsp]
	lea	di,[si+unitbyte]
	mov	[calcsp],di
	mov	dx,[si]
	add	si,2
	mov	bx,[di]
	cmp	bx,dx			;bx(di):1st, dx(si):2nd
	jbe	bitand10		;1st shorter
	mov	[di],dx
	mov	bx,dx
bitand10:
	add	di,2
	mov	cx,bx
	jcxz	bitandret		;if = 0
bitand20:
	lodsw
	and	[di],ax
	add	di,2
	myloop	bitand20

	mov	cx,bx
	sub	di,2
	xor	ax,ax
	std
	repe	scasw
	cld
	je	bitand30
	inc	cx
bitand30:
	mov	di,[calcsp]
	mov	[di],cx
bitandret:
	jmp	far ptr returnadr


;
; * bitxor
;
bitxor:
	call	get2ints
	mov	si,[calcsp]
	lea	di,[si+unitbyte]
	mov	[calcsp],di
	mov	dx,[si]
	add	si,2
	mov	bx,[di]
	cmp	bx,dx			;bx(di):1st dx(si):2nd
	jbe	bitxor50		;2nd longer or equal
;	mov	[di],bx
	add	di,2
	mov	cx,dx
	jcxz	bitxorret
bitxor20:
	lodsw
	xor	[di],ax
	add	di,2
	myloop	bitxor20
	jmps	bitxorret

bitxor50:
	mov	[di],dx			;new length?
	add	di,2
	mov	cx,bx
	jcxz	bitxor70
bitxor60:
	lodsw
	xor	[di],ax
	add	di,2
	myloop	bitxor60
bitxor70:
	mov	cx,dx
	sub	cx,bx
	jz	bitxor80
	rep	movsw
bitxorret:
	jmp	far ptr returnadr
bitxor80:
	mov	cx,bx
	sub	di,2
	xor	ax,ax
	std
	repe	scasw
	cld
	je	bitxor90
	inc	cx
bitxor90:
	mov	di,[calcsp]
	mov	[di],cx
	jmp	bitxorret


get2ints:
	call	far ptr farformul
	mov	si,[calcsp]
	lodsw
	test	ah,LENMASKHIGHCPL
	jnz	get2intsilgerr		;must be positive integer

	cmp	byte ptr [bp],0c2h	;code of ,
	jne	get2intssynerr
	inc	bp

	call	far ptr farkakko
	mov	si,[calcsp]
	lodsw
	test	ah,LENMASKHIGHCPL
	jnz	get2intsilgerr		;must be positive integer

	ret

get2intsilgerr:
	jmp	func3ilgerr
get2intssynerr:
	jmp	func3synerr


comment %
;
; * xmax
;   maximum column position
;   usually 79
;
xmaxin:
	call	ahedsp2
	mov	ax,word ptr [chars1]
	dec	ax
	mov	word ptr [si],1
	mov	[si+2],ax
	jmp	far ptr returnadr

;
; * ymax
;   maximum row position
;
ymaxin:
	call	ahedsp2
	mov	ax,word ptr [btmline]
	dec	ax
	mov	word ptr [si],1
	mov	[si+2],ax
	jmp	far ptr returnadr
%

;
; * key code of cursor up
;
keyup:
	call	ahedsp2
	mov	word ptr [si],1
  if FLG98+FLGFMR
  	mov	word ptr [si+2],5
  endif
  if FLGIBMTOS
  	mov	word ptr [si+2],72
  endif
	jmp	far ptr returnadr

;
; * key code of cursor down
;
keydown:
	call	ahedsp2
	mov	word ptr [si],1
  if FLG98+FLGFMR
  	mov	word ptr [si+2],24
  endif
  if FLGIBMTOS
  	mov	word ptr [si+2],80
  endif
	jmp	far ptr returnadr

;
; * key code of cursor left
;
keyleft:
	call	ahedsp2
	mov	word ptr [si],1
  if FLG98+FLGFMR
  	mov	word ptr [si+2],19
  endif
  if FLGIBMTOS
  	mov	word ptr [si+2],75
  endif
	jmp	far ptr returnadr

;
; * key code of cursor right
;
keyright:
	call	ahedsp2
	mov	word ptr [si],1
  if FLG98+FLGFMR
  	mov	word ptr [si+2],4
  endif
  if FLGIBMTOS
  	mov	word ptr [si+2],77
  endif
	jmp	far ptr returnadr


;
; * modsqrt(a, p)
;   not check the primality of p
;
modsqrtsynerr:
	jmp	func3synerr
modsqrtilgerr:
	jmp	func3ilgerr

modsqrt:
	;get a

	call	far ptr farformul
	mov	si,[calcsp]
	lodsw
	test	ah,attribmaskhigh
	jnz	modsqrtilgerr		;must be an integer

	cmp	byte ptr [bp],0c2h	;code of ,
	jne	modsqrtsynerr
	inc	bp

	;get p

	call	far ptr farkakko
	mov	si,[calcsp]
	lodsw
	test	ah,LENMASKHIGHCPL
	jnz	modsqrtilgerr		;must be positive integer
	and	ax,lenmask
	jz	modsqrtilgerr		;must be positive integer
	mov	cx,ax
	lodsw
	test	ax,1
	jz	modsqrtilgerr		;must be odd
	or	ax,cx
	cmp	ax,1
	je	modsqrtilgerr		;must > 1
	add	[calcsp],UNITBYTE

	cmove2	work2,1			;copy p to work2

	call	far ptr farRes_calcsp
	mov	di,[calcsp]		;check a@p
	cmp	word ptr [di],0
	jne	modsqrtin
	jmp	far ptr returnadr	;if a=0 then ans=0

modsqrtin:
	mov	ax,ds:[work2+2]		;check p
	and	ax,3
	cmp	ax,3
	jne	modsqrtcase14

modsqrt34in:
	cmp	word ptr ds:[work2],1
	ja	modsqrt34long		;if p > 1 word

;	mov	di,[calcsp]
	mov	bx,[di+2]		;bx = a
	push	bp			;/*
	mov	bp,ds:[work2+2]		;get p
	mov	cx,bp			;bp = cx = p
	add	cx,1
	rcr	cx,1
	shr	cx,1			;cx = (p+1)/4
	mov	ax,bx			;ax = a
	call	poweraxcxbp
	mov	[di+2],ax		;set result
	mul	ax
	div	bp
	pop	bp			;*/
	cmp	dx,bx
	jne	func3ilgerr
	jmp	far ptr returnadr

modsqrt34long:
	;uses CALCSP for 3 levels (0,1,2)

	;uses work2 for p
	;     work4 for a
	;     work3 is used by modpower
	;     work2 is also used by modpower but the same value

	cmove2	work4,0			;copy a@p to work4

	checkcalcspfar	2
	mov	[calcsp],ax

	;make (p+1)/4

	mov	di,[calcsp]
	mov	word ptr [di],1		;set 1
	mov	word ptr [di+2],1
	caddfar		-1,0
	mov	di,[calcsp]
	mov	word ptr [di],1		;set 4
	mov	word ptr [di+2],4
	cidivfar	-1,0

	cmove3	0,work2			;copy p to sp(0)

	;answer = a^(p+1)/4 @ p

	call	far ptr farmodpow_ent	;+2 lelvels

	;make answer^2 @ p

	mov	si,[calcsp]
	sub	si,2*UNITBYTE
	mov	word ptr [si],1		;set 2
	mov	word ptr [si+2],2
	sub	si,UNITBYTE
	mov	[calcsp],si

	cmove	-2,-3			;copy answer
	cmove3	0,work2			;copy p to sp(0)

	call	far ptr farmodpow_ent	;+2 levels

	;compare answer^2@p with a

	mov	si,[calcsp]
	mov	di,work4
	mov	cx,[si]
	inc	cx
	repe	cmpsw
	jne	func3ilgerr
	add	[calcsp],UNITBYTE
	jmp	far ptr returnadr


msqrt14p	dw	?		; p 
msqrt14a	dw	?		; a
msqrt14q	dw	?		; q
msqrt14e	dw	?		; e
msqrt14yz	dw	?		; y and z
msqrt14b	dw	?		; b
msqrt14x	dw	?		; x

modsqrtcase14:
	cmp	word ptr ds:[work2],1
	ja	modsqrt14long		;if p > 1 word

	mov	ax,[di+2]		;get a
	mov	cs:[msqrt14a],ax

	mov	ax,ds:[work2+2]		;get p
	mov	cs:[msqrt14p],ax

	; search nonresidue

	mov	ax,2
msq14s10:
	mov	di,[calcsp]
	lea	si,[di-UNITBYTE]
	mov	[calcsp],si
	mov	word ptr [di],1		;set y
	mov	word ptr [di+2],ax
	push	ax
	mov	ax,cs:[msqrt14p]
	mov	word ptr [si],1		;set p
	mov	[si+2],ax
	call	far ptr farKRO_ENT
	pop	ax
	inc	ax
	mov	si,[calcsp]
	cmp	word ptr [si],8001h
	jne	msq14s10		;if <> -1

	dec	ax
	mov	cs:[msqrt14yz],ax	;set y

	mov	di,[calcsp]

	xor	ax,ax
	mov	cx,cs:[msqrt14p]	;get p
	push	bp			;/*
	mov	bp,cx			;bp = p
	dec	cx
msq14s20:
	inc	ax
	shr	cx,1			;cx = odd part of p-1
	jnc	msq14s20		;
	rcl	cx,1			;
	dec	ax
	mov	cs:[msqrt14e],ax	;set e
	mov	cs:[msqrt14q],cx	;set q

	mov	ax,cs:[msqrt14a]	;get a
	call	poweraxcxbp
	mov	cs:[msqrt14b],ax	;set b

	mov	cx,cs:[msqrt14q]	;cx = q
	mov	ax,cs:[msqrt14yz]	;ax = y
	call	poweraxcxbp
	mov	cs:[msqrt14yz],ax	;set z

	mov	cx,cs:[msqrt14q]
	inc	cx
	shr	cx,1			;cx=(q+1)/2
	mov	ax,cs:[msqrt14a]
	call	poweraxcxbp
	mov	cs:[msqrt14x],ax	;set x

	mov	cx,cs:[msqrt14e]
	sub	cx,2
	jz	msq14s100
msq14s30:
	push	cx
	mov	ax,cs:[msqrt14b]
msq14s40:				;make b^m
	mul	ax
	div	bp
	mov	ax,dx
	myloop	msq14s40
msq14s50:
	cmp	ax,1
	je	msq14s60

	mov	ax,cs:[msqrt14x]
	mul	word ptr cs:[msqrt14yz]
	div	bp
	mov	cs:[msqrt14x],dx

	mov	ax,cs:[msqrt14yz]
	mul	ax
	div	bp
	mov	cs:[msqrt14yz],dx

	mov	ax,cs:[msqrt14b]
	mul	dx
	div	bp
	mov	cs:[msqrt14b],dx
	jmp	msq14s70
msq14s60:
	mov	ax,cs:[msqrt14yz]
	mul	ax
	div	bp
	mov	cs:[msqrt14yz],dx
msq14s70:
	pop	cx
	myloop	msq14s30

msq14s100:
	cmp	word ptr cs:[msqrt14b],1
	je	msq14s110

	mov	ax,cs:[msqrt14x]
	mul	word ptr cs:[msqrt14yz]
	div	bp
	mov	cs:[msqrt14x],dx
msq14s110:
	mov	ax,cs:[msqrt14x]
	mov	si,[calcsp]
	mov	word ptr [si],1
	mov	[si+2],ax		;set answer

	mul	ax
	div	bp
	pop	bp			;*/
	cmp	dx,cs:[msqrt14a]
	jne	func3ilgerr
	jmp	far ptr returnadr

modsqrt14long:
	;uses CALCSP for 5 levels (0,1,2,3,4)

	;uses work2 for p
	;     work3 is used by modpower
	;     work2 is also used by modpower but the same value

	push	bp			;BP is destroyed by GCDRES

	checkcalcspfar	4

	; search nonresidue

	sub	[calcsp],UNITBYTE	;protect p
	cmove2	work4,-1		;save a
	cmove3	-1,work2		;load p

	mov	ax,2
msq14l10:
	mov	di,[calcsp]
	lea	si,[di-UNITBYTE]
	mov	[calcsp],si
	mov	word ptr [di],1		;set y
	mov	word ptr [di+2],ax
	push	ax
	cmove	0,-2			;copy p to sp0
	call	far ptr farKRO_ENT	;destroy work2
	pop	ax
	inc	ax			;if y>1word then endlessloop
	mov	si,[calcsp]
	cmp	word ptr [si],8001h
	jne	msq14l10		;if <> -1

	dec	ax
	mov	cs:[msqrt14yz],ax	;set y

	cmove2	work2,-1		;save p

	mov	si,[calcsp]
	add	si,UNITBYTE
	mov	[calcsp],si

	xor	dx,dx			;counter for e
	mov	di,si
	lodsw
	mov	cx,ax
	lodsw				;1st word
	dec	cx
	and	ax,0fffeh
	jnz	msq14l25		;check this words
msq14l20:
	add	dx,16			;16 bits
	lodsw
	or	ax,ax
	jz	msq14l20
msq14l25:
	inc	dx
	shr	ax,1
	jnc	msq14l25
	dec	dx
	mov	cs:[msqrt14e],dx
	mov	ax,dx			;bit count
	mov	di,[calcsp]
	call	far ptr farshiftright

	;calc x = a^(q+1)/2@p

	sub	[calcsp],3*UNITBYTE
	cmove3	-2,work4		;copy a
	cmove	-1,-3			;copy q

	mov	di,[calcsp]
	mov	word ptr [di],1		;set 1
	mov	word ptr [di+2],1
	caddfar		-1,0
	mov	di,[calcsp]
	mov	word ptr [di],1		;set 2
	mov	word ptr [di+2],2
	cidivfar	-1,0

	cmove3	0,work2			;copy p
	call	far ptr farmodpow_ent	;+2 lelvels
;//	cmove	-3,0			;set x

	;calc z = y^q@p

	mov	ax,[calcsp]
	sub	ax,UNITBYTE
	mov	si,ax
	sub	ax,2*UNITBYTE
	mov	[calcsp],ax

	mov	ax,cs:[msqrt14yz]
	mov	word ptr [si],1
	mov	[si+2],ax
	cmove	-1,-4			;copy q
	cmove3	0,work2			;copy p
	call	far ptr farmodpow_ent	;+2 lelvels

	;calc b = a^q@p

	mov	ax,[calcsp]
	sub	ax,3*UNITBYTE
	mov	[calcsp],ax

	cmove3	-2,work4		;copy a
	cmove	-1,-5			;copy q
	cmove3	0,work2			;copy p
	call	far ptr farmodpow_ent	;+2 lelvels
	cmove	-3,-2			;copy x to q
	cmove	-2,0			;copy b

	; main loop

	mov	cx,cs:[msqrt14e]
	sub	cx,2
	jz	msq14l100
msq14l30:
	push	cx
	cmove	0,-2			;load b
	pop	cx
	push	cx
msq14l40:
	push	cx
	mov	di,[calcsp]
	call	far ptr farsquareIdi
	mov	si,[calcsp]
	call	modsqrtressi
	pop	cx
	myloop	msq14l40
msq14l50:
	mov	si,[calcsp]
	mov	ax,1
	cmp	[si],ax
	jne	msq14l55
	cmp	[si+2],ax
	je	msq14l60		;if = 1

msq14l55:
	mov	di,[calcsp]		;x = xz
	mov	si,di
	add	di,3*UNITBYTE
	add	si,UNITBYTE
	push	di
	call	far ptr farmulIIdisi
	pop	si
	call	modsqrtressi

	mov	di,[calcsp]		;z = z^2
	add	di,UNITBYTE
	mov	[calcsp],di
	call	far ptr farsquareIdi
	mov	si,[calcsp]
	call	modsqrtressi
	sub	[calcsp],UNITBYTE

	mov	di,[calcsp]		;b = bz
	mov	si,di
	add	di,2*UNITBYTE
	add	si,UNITBYTE
	push	di
	call	far ptr farmulIIdisi
	pop	si
	call	modsqrtressi
	jmp	msq14l70

msq14l60:
	mov	di,[calcsp]		;z = z^2
	add	di,UNITBYTE
	mov	[calcsp],di
	call	far ptr farsquareIdi
	mov	si,[calcsp]
	call	modsqrtressi
	sub	[calcsp],UNITBYTE

msq14l70:
	pop	cx
	myloop	msq14l30
msq14l100:
	mov	si,[calcsp]		;check b
	add	si,2*UNITBYTE
	mov	ax,1
	cmp	[si],ax
	jne	msq14l105
	cmp	[si+2],ax
	je	msq14l110

msq14l105:
	mov	di,[calcsp]		;x = xz
	mov	si,di
	add	di,3*UNITBYTE
	add	si,UNITBYTE
	push	di
	call	far ptr farmulIIdisi
	pop	si
	call	modsqrtressi

msq14l110:
	add	[calcsp],2*UNITBYTE
	cmove	0,-1			;copy x
	mov	di,[calcsp]		;x = x^2
	call	far ptr farsquareIdi
	mov	si,[calcsp]
	call	modsqrtressi
	mov	ax,[calcsp]
	mov	si,ax
	add	ax,UNITBYTE
	mov	[calcsp],ax

	pop	bp

	mov	di,work4
	mov	cx,[si]
	inc	cx
	repe	cmpsw
	jne	func3ilgerr
	jmp	far ptr returnadr

; * [si] = [si] @ work2
;   using resadr

modsqrtressi:				;destory BP
	push	si
	mov	di,resadr
	mov	cx,[si]
	and	cx,lenmask
	inc	cx
	rep	movsw
	call	far ptr fargcdreswork2	;destroy BP
	pop	di
	mov	si,resadr
	mov	cx,[si]
	and	cx,lenmask
	inc	cx
	rep	movsw
	ret

; * ax = ax^cx mod bp

powerAXCXBP:
	push	si
	mov	si,1
	jcxz	powmodp90	;if cx=0 then ans=1
	or	ax,ax
	jz	powmodp100	;if ax=0 then ans=0
	shr	cx,1
	jnc	powmodp10
	jcxz	powmodp100	;if cx=1 then ans=ax
	mov	si,ax
powmodp10:
	mul	ax		;ax = ax^2 mod P
	div	bp		;
	mov	ax,dx		;

	shr	cx,1
	jnc	powmodp20

	push	ax
	mul	si		;si = si * ax mod P
	div	bp		;
	mov	si,dx		;
	pop	ax
powmodp20:
	or	cx,cx
	jnz	powmodp10
powmodp90:
	mov	ax,si
powmodp100:
	pop	si
	ret


;
; * getenv
;
getenvnot:
	pop	es		;*
	mov	si,[calcsp]
	mov	word ptr [si],0
	jmp	ver110

getenvilgerr:
	jmp	func3ilgerr

getenv:
	call	far ptr farKakko
	mov	si,[calcsp]
	lodsw
	test	ah,stringmaskhigh
	jz	getenvilgerr	;ilegal parameter
	mov	cx,ax
	xor	cx,stringmask
	jcxz	getenvall	;null string
	shl	cx,1
	sbb	cx,0		;cx = chars
	push	cx		;*
getenv10:
	lodsb
	cmp	al,'='
	jne	getenv15
	cmp	cx,1
	jne	getenvilgerr	;= must be at the end of string
getenv15:
	cmp	al,'a'
	jb	getenv20
	cmp	al,'z'
	ja	getenv20
	xor	al,20h		;to capital
	mov	[si-1],al
getenv20:
	myloop	getenv10
	pop	dx		;* dx = chars
	cmp	al,'='
	je	getenv30		;already "=" exists
	mov	byte ptr [si],"="
	inc	dx
getenv30:	
	mov	si,[calcsp]
	lea	bx,[si+2]
	push	es		;*
	mov	es,[environment]
	xor	di,di
getenv40:
	cmp	word ptr es:[di],0
	je	getenvnot	;end of ENV
	mov	si,bx
	mov	cx,dx
	push	di		;**
	rep	cmpsb
	je	getenv50
	pop	di		;**
	xor	al,al
	mov	cx,0ffffh
	repne	scasb
	jmp	getenv40
getenv50:
	add	sp,2		;**
	mov	si,di		;top of value
	xor	al,al
	mov	cx,0ffffh
	repne	scasb
	mov	ax,di
	sub	ax,si		;ax = chars+1
	shr	ax,1
	mov	cx,ax
	jc	getenv60
	or	ah,80h
getenv60:
	or	ah,stringmaskhigh
	smov	ds,es

	pop	es		;*
	mov	di,ss:[calcsp]
	stosw
	jmp	ver100		

getenvall:
	push	es		;*

	mov	es,[environment]
	xor	di,di
	xor	al,al
	mov	cx,LIMITWORD*2
getenv70:
	repne	scasb		;search 0
	cmp	es:[di],al		;also 0?
	jne	getenv70
	stosb			;put 1more 0
	mov	ax,di		;chars+1
	shr	ax,1
	mov	cx,ax
	jc	getenv80
	or	ah,80h		;odd length
getenv80:
	or	ah,stringmaskhigh
	smov	ds,es
	xor	si,si
	pop	es		;*
	mov	di,ss:[calcsp]
	stosw
	jmp	ver100

;
; * lcm
;
lcm:
	jmp	far ptr LCMIN

;
; * version
;
verin:
	call	ahedsp2
	mov	di,[calcsp]
	mov	si,offset vmsg
	mov	ax,offset vmsgend-vmsg
	inc	ax
	shr	ax,1
	mov	cx,ax
	jc	ver10
	or	ah,80h
ver10:
	or	ah,stringmaskhigh
	stosw
	smov	ds,cs
ver100:
	rep	movsw
	smov	ds,ss
ver110:
	jmp	far ptr returnadr


vmsg	db	versionmessage
vmsgend	db	0

;
; * polymod
;
funcpolymod:
	call	ahedsp2
	mov	si,[calcsp]
	set32
	mov	ax,word ptr [polymodulus]
	set32
	or	ax,ax
	jz	polymod10
	mov	cx,1
	set32
	mov	[si+2],ax
	set32
	shr	ax,16
	or	ax,ax
	jz	polymod10
	inc	cx
polymod10:
	mov	[si],cx
	jmp	far ptr returnadr

;
; * degree of polynomial
;
degin:
	call	far ptr farKakko
	mov	si,[calcsp]
	mov	ax,[si]
	or	ax,ax
	jz	degof0		;if 0
	and	ah,attribmaskhigh
	cmp	ah,polymaskhigh
	je	degpoly
	cmp	ah,modpolymaskhigh
	je	degmodpoly
	test	ah,nonnumericmaskhigh
	jz	degofscalar	;if non0 scalar
	jmp	func3ilgerr
degofscalar:
	mov	word ptr [si],0
	jmps	deg_out

degof0:
	mov	[si],8001h	;set -1
	mov	word ptr [si+2],1
	jmps	deg_out

degpoly:
	mov	ax,[si+2]	;terms
	dec	ax
	jz	degpoly20
degpoly10:
	mov	word ptr [si],1
	add	si,2
degpoly20:
	mov	[si],ax
deg_out:
	jmp	far ptr returnadr

degmodpoly:
	mov	ax,[si]
	and	ax,lenmask
	shr	ax,1
	sub	ax,2		;# of terms
	jnz	degpoly10
	jmp	degpoly20

;
; * differential of a polynomial
;
diffin:
	call	far ptr farKakko
	mov	si,[calcsp]
	mov	ax,[si]
	test	ax,lenmask
	jz	diffset0
	and	ah,attribmaskhigh
	cmp	ah,polymaskhigh
	je	diffpoly
	cmp	ah,modpolymaskhigh
	je	diffmodpoly
	test	ah,nonnumericmaskhigh
	jz	diffset0	;if scalar
diffilg:
	jmp	func3ilgerr

diffset0:
	mov	si,[calcsp]
	mov	word ptr [si],0
	jmp	far ptr returnadr

diffpoly:
	checkcalcspfar	3
	mov	si,[calcsp]
	lodsw
	lodsw
	dec	ax
	jz	diffset0	;if const then diff=0
	mov	cx,ax		;# of members -1

	mov	bx,si
	sub	bx,unitbyte
	mov	[Z_adr],bx
	mov	[bx-2],ax	;# of new members
	add	bx,2*unitbyte-3
	mov	[Z_limadr],bx

	lodsw
	and	ax,lenmask
	shl	ax,1
	add	si,ax
	mov	[X_adr],si

	mov	[deg_now],1

	sub	[calcsp],2*unitbyte
diffpoly10:
	push	cx
	mov	si,[X_adr]
	mov	di,[calcsp]
	mov	bx,di
	copy_si2di
	mov	[X_adr],si
	lea	di,[bx-unitbyte]
	mov	ax,1
	stosw
	mov	ax,[deg_now]
	stosw
	call	far ptr farMul_calcsp
	mov	si,[calcsp]
	call	store_si2Z	

	inc	[deg_now]
	pop	cx
	myloop	diffpoly10
	add	[calcsp],2*unitbyte

	mov	ax,[Z_adr]
	mov	di,[calcsp]
	lea	si,[di-unitbyte]
	sub	ax,si
	shr	ax,1
	dec	ax
	or	ah,polymaskhigh
	mov	[si],ax
	copy_si2di
	jmp	far ptr returnadr


diffmodpoly:
	;differential of modpoly

	lodsw
	and	ax,lenmask
	shr	ax,1
	sub	ax,2
	jbe	diffset0
	mov	cx,ax		;number of elements-1
				;default degree of result
	set32
	lodsw
	set32
	cmp	ax,word ptr [polymodulus]
	jne	diffilg
	set32
	mov	bx,ax		;modulus
	add	si,4		;skip const term
	set32
	xor	di,di
	inc	di		;degree
	push	cx		;*
diffmodpoly10:
	set32
	lodsw
	set32
	mul	di		;mul degree
	set32
	div	bx
	set32
	mov	[si-8],dx
	inc	di
	myloop	diffmodpoly10
	pop	cx		;*
	set32
	or	dx,dx
	jnz	diffmodpolyout	;degree is maximal

	lea	di,[si-12]
	dec	cx
	set32
	xor	ax,ax
	std
	set32
	repe	scasw
	cld
	je	diffset0	;all zero
	inc	cx		;recover over decrement by scasd
diffmodpolyout:
	inc	cx		;modulus
	shl	cx,1
	or	ch,modpolymaskhigh
	mov	si,[calcsp]
	mov	[si],cx
	jmp	far ptr returnadr


;
; * file existence check
;
existsynerr:
	jmp	func3synerr
existilgerr:
	jmp	func3ilgerr

existin:
	CALL	far ptr farSETFNAME	;PATH 名を得る
	jc	existsynerr

	call	ahedsp2

	MOV	AH,26			;set DTA
	MOV	DX,INPBUF
	INT	21H

	mov	ah,4eh
	mov	dx,offset fnamebuf
	mov	cx,16h
	int	21h

	jc	existerror
	mov	ax,1
existret:
	mov	[si],ax
	mov	[si+2],ax

	cmp	byte ptr [bp],")"
	jne	existsynerr
	inc	bp
	jmp	far ptr returnadr

existerror:
;	cmp	ax,12h
;	jne	existilgerr
	xor	ax,ax
	jmp	existret
		
;
; * real time key scan
;
  if FLG98
scankey:
	call	ahedsp2
	mov	di,[calcsp]
	add	di,2
	mov	bx,0ff00h
scankeylp:
	mov	ah,4
	mov	al,bl
	int	18h
	or	ah,ah
	jz	scankeyjp
	mov	bh,bl		;non zero group
scankeyjp:
	mov	[di],ah
	inc	di
	inc	bl
	cmp	bl,0eh
	jbe	scankeylp
	mov	byte ptr [di],0
	sub	di,0fh+2
	xor	ax,ax
	mov	al,bh
	add	al,2
	shr	ax,1
	mov	[di],ax
	jmp	far ptr returnadr

  else
scankey:
	jmp	far ptr returnadr
  endif
		
;
;計算用スタックを一つ深くする
;    output:SI new calcsp
;    destroy:NOTHING

	align	4
AHEDSP2:	
	MOV	SI,[CALCSP]
	SUB	SI,UNITBYTE
	CMP	SI,[calcsp_limit]
	JB	func3CALCSPERR
	MOV	[CALCSP],SI
	RET

func3CALCSPERR:
	JMP	far ptr CALCSPERR

;
;計算用スタックを一つ浅くする
;  output:SI old calcsp
;         DI new calcsp(演算結果の入る方)
;  DESTROY:NOTHING

	myalign
BACKSP2:	
	MOV	SI,[CALCSP]
	MOV	DI,SI
	ADD	DI,UNITBYTE
	CMP	DI,LIMIT
	JA	GO_SYSTEMERR
	MOV	[CALCSP],DI
	RET

GO_SYSTEMERR:
	JMP	far ptr SYSTEMERR


;
;* hex$ of an integer
;

hexothers:

hexover:
	jmp	func3ovrerr
hexcalcsperr:
	jmp	func3calcsperr

hexset00:
	mov	ah,stringmaskhigh
	mov	al,1
	mov	[si],ax
	mov	word ptr [si+2],3030h
	jmp	far ptr returnadr

hexin:
	call	far ptr farKakko
hex1:
	mov	si,[calcsp]
	mov	ax,[si]
	mov	dx,ax		;memo
	and	ax,lenmask
	jz	hexset00

	lea	di,[si-unitbyte]
	cmp	di,[calcsp_limit]
	jb	hexcalcsperr

	mov	cx,ax
	inc	cx
	rep	movsw

	mov	di,[calcsp]
	lea	si,[di-unitbyte+2]	;source lowest byte adr
	shl	ax,1
	mov	dl,dh
	and	dl,lenmaskhighcpl
	cmp	dl,80h+stringmaskhigh
	jne	hex5
	dec	ax		;if string of odd length
hex5:
	mov	cx,ax
	cmp	ax,limitword
	ja	hexover
	or	ah,stringmaskhigh
	stosw

	test	dh,compratstrpackmaskhigh
	jnz	hex10		;not integer/real

	add	di,cx
	add	di,cx
	sub	di,2		;dest highest word adr
	std
hex10:
	mov	al,[si]
	inc	si
	mov	ah,al
	call	transhex
	xchg	al,ah
	my_shr	al,4
	call	transhex
	stosw
	myloop	hex10
	cld
	jmp	far ptr returnadr

transhex:
	and	al,0fh
	cmp	al,10
	jb	transhex10	
	add	al,'A'-'9'-1
transhex10:
	add	al,'0'
	ret

;
;* cursor position
;	

posxin:
	mov	ax,word ptr [xpos]
posxyin:
	call	ahedsp2
	or	ax,ax
	jz	posxy100
	mov	[si+2],ax
	mov	ax,1
posxy100:
	mov	[si],ax
	jmp	far ptr returnadr

posyin:
	mov	ax,word ptr [ypos]
	jmp	posxyin


;
;* graphic character position
;	
  if flggprint

gposxin:
  	mov	ax,[chxpos]
gposxyin:
	call	ahedsp2
	or	ax,ax
	jz	gposxy100
	mov	[si+2],ax
	mov	ax,1
gposxy100:
	mov	[si],ax
	jmp	far ptr returnadr

gposyin:
  	mov	ax,[chypos]
	jmp	gposxyin
  else
gposxin:
gposyin:
	jmp	far ptr returnadr
  endif

;
;* hankaku henkan
;
hankakuilg:
	jmp	func3ilgerr
hankakucalcsperr:
	jmp	func3calcsperr

hankaku:
	call	far ptr farKakko
	mov	si,[calcsp]
	mov	ax,[si]
	mov	cx,ax
	and	ch,attribmaskhigh
	cmp	ch,stringmaskhigh
	jne	hankakuilg
	mov	cx,ax
	and	cx,lenmask
	shl	ax,1
	sbb	ax,0
	and	ax,2*lenmask+1
	jz	hanret		;null string
	lea	di,[si-unitbyte]
	cmp	di,[calcsp_limit]
	jb	hankakucalcsperr
	add	si,2
	add	di,2
	push	si
	push	di
	rep	movsw		;copy to higher calcsp
	pop	si
	pop	di

	mov	cx,ax
han10:
	lodsb
	call	far ptr farKANJI1ST?
	jc	han60
han20:
	stosb			;if not kanji
han30:
	myloop	han10
hanout:
	mov	si,[calcsp]
	mov	ax,di
	sub	ax,si
	dec	ax		;-2+1
	shr	ax,1
	jb	han40
	or	ah,80h		;if odd length
	mov	byte ptr [di],0
han40:
	or	ah,stringmaskhigh
	mov	[si],ax
hanret:
	jmp	far ptr returnadr

han60:
	dec	cx
	jz	hanout		;illegal code
	cmp	al,81h
	je	han_symbol
	cmp	al,82h
	je	han_alpnumhira
	cmp	al,83h
	je	han_kata
	stosb
	movsb
	jmp	han30		;cant hankaku
han_symbol:
	lodsb
	sub	al,40h
	cmp	al,5ch
	ja	cant_han
	mov	bx,code2
	mov	ds,bx
	mov	bx,offset hantbl
	xlat
	smov	ds,ss
	or	al,al
	jz	cant_han
	jmp	han20
cant_han:
	mov	ax,[si-2]
	stosw
	jmp	han30

han_alpnumhira:
	lodsb
	cmp	al,60h
	jae	han_alphira
	sub	al,4fh
	add	al,'0'
	jmp	han20
han_alphira:
	cmp	al,81h
	jae	han_alphira2
	sub	al,60h
	add	al,'A'
	jmp	han20
han_alphira2:
	cmp	al,9fh
	jae	cant_han	;hiragana
	sub	al,81h
	add	al,'a'
	jmp	han20

han_kata:
	lodsb
	cmp	al,9fh
	jae	cant_han
	sub	al,40h
	mov	bx,code2
	mov	ds,bx
	mov	bx,offset hantbl2
	xlat
	smov	ds,ss
	cmp	al,0a0h
	jae	han20
	add	al,40h
	cmp	al,0a0h
	jb	han_kana_o
	stosb
	mov	al,'ﾞ'
	jmp	han20
han_kana_o:
	add	al,40h
	stosb
	mov	al,'ﾟ'
	jmp	han20


hantbl	db	' ､｡,.･:;?!ﾞﾟ',0,0,0,'^'
	db	0,'_',0,0,0,0,0,0,0,0,0,0b0h,0,0,'/',0
	db	'~',0,'|',0,0,'`',27h,0,'"()',0,0,'[]{'
	db	'}',0,0,0,0,'｢｣',0,0,0,0,'+-',0,0,0
	db	0,'=',0,'<>',0,0,0,0,0,0,0,0,0,0,'\'
	db	'$',0,0,'%#&*@',0,0,0,0edh,0ech

hantbl2	db	'ｧｱｨｲｩｳｪｴｫｵ'
	db	'ｶ','ｶ'-40h,'ｷ','ｷ'-40h,'ｸ','ｸ'-40h,'ｹ','ｹ'-40h,'ｺ','ｺ'-40h
	db	'ｻ','ｻ'-40h,'ｼ','ｼ'-40h,'ｽ','ｽ'-40h,'ｾ','ｾ'-40h,'ｿ','ｿ'-40h
	db	'ﾀ','ﾀ'-40h,'ﾁ','ﾁ'-40h,'ｯ','ﾂ','ﾂ'-40h,'ﾃ','ﾃ'-40h,'ﾄ','ﾄ'-40h
	db	'ﾅﾆﾇﾈﾉ'
	db	'ﾊ','ﾊ'-40h,'ﾊ'-80h,'ﾋ','ﾋ'-40h,'ﾋ'-80h,'ﾌ','ﾌ'-40h,'ﾌ'-80h,'ﾍ','ﾍ'-40h,'ﾍ'-80h,'ﾎ','ﾎ'-40h,'ﾎ'-80h
	db	'ﾏﾐ',0,'ﾑﾒﾓ'
	db	'ｬﾔｭﾕｮﾖ'
	db	'ﾗﾘﾙﾚﾛ'
	db	0,'ﾜ',0,0,'ｦﾝ',0,0,0



;
;* zenkaku henkan
;
zenkakuilg:
	jmp	func3ilgerr
zenkakucalcsperr:
	jmp	func3calcsperr

Zenkaku:
	call	far ptr farKakko
	mov	si,[calcsp]
	mov	ax,[si]
	mov	cx,ax
	and	ch,attribmaskhigh
	cmp	ch,stringmaskhigh
	jne	zenkakuilg
	mov	cx,ax
	and	cx,lenmask
	shl	ax,1
	sbb	ax,0
	and	ax,2*lenmask+1
	jz	zenret		;null string
	lea	di,[si-unitbyte]
	cmp	di,[calcsp_limit]
	jb	zenkakucalcsperr
	add	si,2
	add	di,2
	push	si
	push	di
	rep	movsw		;copy to higher calcsp
	pop	si
	pop	di

	mov	dx,di
	add	dx,unitbyte-2	;limit of di
	mov	cx,ax
zen10:
	lodsb
	call	far ptr farKANJI1ST?
	jnc	zen60
	stosb		;if kanji
	dec	cx
	jz	zenout
	lodsb
zen20:
	stosb
zen30:
	cmp	di,dx
	ja	zenout
	myloop	zen10
zenout:
	mov	si,[calcsp]
	mov	ax,di
	sub	ax,si
	dec	ax		;-2+1
	shr	ax,1
	jb	zen35
	or	ah,80h		;if odd length
	mov	byte ptr [di],0
zen35:
	or	ah,stringmaskhigh
	mov	[si],ax
zenret:
	jmp	far ptr returnadr


numeric:
	sub	al,'0'
	add	al,4fh
zen40:
	mov	ah,al
	mov	al,82h
	stosw
	jmp	zen30

upper:
	sub	al,'A'
	add	al,60h
	jmp	zen40

lower:
	sub	al,'a'
	add	al,81h
	jmp	zen40

zen50:
	mov	ax,bx
	stosw
	jmp	zen30

zen60:
comment %
	cmp	al,CR
	je	zen20
	cmp	al,LF
	je	zen20
	cmp	al,ESC
	je	zen20
	cmp	al,1ch
	jb	zen50
%
	cmp	al,1fh
	jbe	zen20
	mov	bx,0a181h
	cmp	al,'0'
	jb	symbol1
	cmp	al,'9'
	jbe	numeric
	cmp	al,'A'
	jb	symbol2
	cmp	al,'Z'
	jbe	upper
	cmp	al,'a'
	jb	symbol3
	cmp	al,'z'
	jbe	lower
	cmp	al,7fh
	jb	symbol4
	cmp	al,0a0h
	jbe	zen50		;pass it
	cmp	al,0a5h
	jbe	symbol5
	mov	bx,5b81h
	cmp	al,0b0h
	je	zen70
	cmp	al,0deh
	jb	kana
	mov	bx,4a81h
	je	zen70
	mov	bx,4b81h
	cmp	al,0dfh
	je	zen70

zen70:
	mov	ax,bx
	stosw
	jmp	zen30


symbol5:
	sub	al,34
symbol4:
	sub	al,26
symbol3:
	sub	al,26
symbol2:
	sub	al,10	
symbol1:
	mov	bx,offset xlattbl
	sub	al,1ch
	xor	ah,ah
	add	bx,ax
	mov	al,81h
	mov	ah,cs:[bx]
	stosw
	jmp	zen30

kana:
	mov	bx,offset xlattbl2
	sub	al,0a6h
	xor	ah,ah
	add	bx,ax
	mov	al,83h
	stosb
	mov	al,cs:[bx]
	cmp	cx,1
	je	kana30		;if last byte
	cmp	byte ptr [si],0deh	;dakuon?
	jne	kana10

	cmp	al,4ah
	jb	kana30
	cmp	al,67h
	jbe	dakuon
	cmp	al,6dh
	jbe	kana30
	cmp	al,7ah
	ja	kana30
dakuon:
	jmps	kana25

kana10:
	cmp	byte ptr [si],0dfh
	jne	kana30
kana20:
	cmp	al,6dh
	jbe	kana30
	cmp	al,7ah
	ja	kana30
	inc	al
kana25:
	inc	al
	inc	si
	dec	cx
kana30:
	stosb
	jmp	zen30


xlattbl		label	byte
	db	0a8h,0a9h,0aah,0abh

	db	040h,049h,068h,094h,090h,093h,095h,066h
	db	069h,06ah,096h,07bh,043h,07ch,044h,05eh

	db	046h,047h,083h,081h,084h,048h,097h

	db	06dh,08fh,06eh,04fh,051h,065h

	db	06fh,062h,070h,060h

	db	042h,075h,076h,041h,045h

xlattbl2	label	byte
	db	092h,040h
	db	042h,044h,046h,048h,083h,085h,087h,062h
	db	05bh,041h,043h,045h,047h,049h,04ah,04ch
	db	04eh,050h,052h,054h,056h,058h,05ah,05ch
	db	05eh,060h,063h,065h,067h,069h,06ah,06bh
	db	06ch,06dh,06eh,071h,074h,077h,07ah,07dh	
	db	07eh,080h,081h,082h,084h,086h,088h,089h
	db	08ah,08bh,08ch,08dh,08fh,093h

;
;* translate world zahyou -> screen zahyou
;
  if graph
mapx:
	call	GET_WORLD_X
	mov	dx,[viewx1]
	mov	si,[calcsp]
	sub	si,unitbyte
	mov	[calcsp],si
	sub	ax,dx
mapx40:
	jz	mapx50
	mov	[si+2],ax
	mov	ax,1
mapx50:
	mov	[si],ax

	cmp	byte ptr [bp],')'
	jne	mapxsynerr
	inc	bp
	jmp	far ptr returnadr

mapy:
	call	GET_WORLD_Y
	mov	si,[calcsp]
	sub	si,unitbyte
	mov	[calcsp],si
	cmp	[schoolflg],0
	jne	mapyschool
	sub	ax,[viewy1]
	jmp	mapx40
mapyschool:
	sub	ax,[viewy2]
	neg	ax
	jmp	mapx40
  else
mapx:
mapy:
  endif
mapxsynerr:
	jmp	func3synerr


;
;* absolute address of a variable
;

VARPTR:
	call	far ptr fargetvadr
	mov	dx,ds
	mov	bx,si
	smov	ds,ss
	call	ahedsp2
	mov	ax,2
	or	dx,dx
	jnz	varptr50
	dec	ax
	or	bx,bx
	jnz	varptr50
	dec	ax
varptr50:
	mov	[si],ax
	mov	[si+2],bx
	mov	[si+4],dx
	cmp	byte ptr [bp],')'
	jne	peeksynerr
	inc	bp
	jmp	far ptr returnadr
	
;
;* peek a byte value
;
  if FLG98NOTXL
GRAMSEG1	equ	0a800h
  endif

peekString:
	call	far ptr farGET_ax
	push	ax

	cmp	byte ptr [bp],0c2h
	jne	peeksynerr
	inc	bp
	call	far ptr farKakko_ax
	jc	peeksynerr
	mov	cx,ax
	cmp	ax,limitword*2
	ja	peekilgerr

	mov	di,[calcsp]
	mov	ax,cx
	inc	ax
	shr	ax,1
	jc	peeks10
	or	ah,80h
peeks10:
	or	ah,stringmaskhigh
	stosw			;set string attribute	

	pop	si
	mov	ax,[defsegdata]
	mov	ds,ax
  if FLG98NOTXL
	cmp	ax,GRAMSEG1-1000h
	jb	peeks20
	gramselect 0
	rep	movsb
	gramselect 1
	jmps	peeks30
peeks20:
  endif
	rep	movsb
peeks30:
	mov	byte ptr [di],0
	smov	ds,ss
	jmp	far ptr returnadr

peeksynerr:
	jmp	func3synerr
peekilgerr:
	jmp	func3ilgerr


peekword:
	call	far ptr farGET_ax
	mov	si,ax
	mov	ax,[defsegdata]
	mov	ds,ax
  if FLG98NOTXL
	cmp	ax,GRAMSEG1-1000h
	jae	peekw20
	mov	bl,[si]
	mov	bh,[si+1]
	jmps	peekret
peekw20:
	gramselect 0
	mov	bl,[si]
	mov	bh,[si+1]
	gramselect 1
  else
	mov	bl,[si]
	mov	bh,[si+1]
  endif
	jmps	peekret

peekbyte:
	call	far ptr farGET_ax
	mov	si,ax
	mov	ax,[defsegdata]
	mov	ds,ax
  if FLG98NOTXL
	cmp	ax,GRAMSEG1-1000h
	jae	peekb20
	mov	bl,[si]
	jmps	peekb50
peekb20:
	gramselect 0
	mov	bl,[si]
	gramselect 1
  else
	mov	bl,[si]
  endif
peekb50:
	xor	bh,bh

peekret:
	smov	ds,ss
	cmp	byte ptr [bp],')'
	jne	peeksynerr
	inc	bp
	call	ahedsp2
	or	bx,bx
	jz	peek70
	mov	[si+2],bx
	mov	bx,1
peek70:
	mov	[si],bx
	jmp	far ptr returnadr

 
;
;* cut all spaces in a string
;

cutspace:
	call	far ptr farkakko
	mov	si,[calcsp]
	lodsw
	mov	cx,ax
	and	ch,attribmaskhigh
	cmp	ch,stringmaskhigh
	jne	cutspcilgerr
	shl	ax,1
	sbb	ax,0
	and	ax,lenmask*2+1
	jz	cutspcret	;null string
	mov	cx,ax		;byte length
	mov	dx,ax		;memo

	mov	di,si		;search space
	mov	al,' '
	repne	scasb
	jne	cutspcret	;no space

	mov	cx,dx
	xor	dx,dx		;new byte length
	mov	di,si
cutspclp:
	lodsb
	cmp	al,' '
	je	cutspcjp
	stosb
	inc	dx
cutspcjp:
	myloop	cutspclp
	xor	al,al
	stosb			;end mark
	mov	ax,dx
cutspc40:
	inc	ax
	shr	ax,1
	jc	cutspc50
	or	ah,80h		;if odd length
cutspc50:
	or	ah,stringmaskhigh
	mov	si,[calcsp]
	mov	[si],ax
cutspcret:
	jmp	far ptr returnadr

cutspcilgerr:
	jmp	func3ilgerr

;
;* cut left spaces in a string
;

cutleftspace:
	call	far ptr farkakko
	mov	si,[calcsp]
	lodsw
	mov	cx,ax
	and	ch,attribmaskhigh
	cmp	ch,stringmaskhigh
	jne	cutspcilgerr
	shl	ax,1
	sbb	ax,0
	and	ax,lenmask*2+1
	jz	cutspcret	;null string
	mov	cx,ax		;byte length

	mov	di,si
	mov	al,' '
	repe	scasb
	je	allspace

	dec	di
	inc	cx
	cmp	di,si
	je	cutspcret	;no space

	xchg	di,si
	mov	ax,cx		;new length
	inc	cx		;for end mark
	rep	movsb
	jmp	cutspc40

allspace:
	mov	si,[calcsp]
	mov	word ptr [si],stringmask	;null string
	jmp	far ptr returnadr

;
;* instring
;
instr:
	call	instrgetparam
	cmp	dx,0
	jle	instrnot	;start position overrun
	sub	dx,cx
	jb	instrnot
	inc	dx
instrlp:
	push	di
	push	si
	push	cx
	rep	cmpsb
	je	instrfind
	pop	cx
	pop	si
	pop	di
	inc	di
	dec	dx
	jnz	instrlp
instrnot:
	backsp_mac
	mov	word ptr [di],0
	jmp	far ptr returnadr

instrfind:
	pop	cx
	add	sp,4
	mov	ax,di
	mov	si,[calcsp]
	add	si,unitbyte
	mov	[calcsp],si
	sub	ax,si
	sub	ax,cx
	dec	ax
	mov	word ptr [si],1
	mov	[si+2],ax
	jmp	far ptr returnadr

instrilg:
	jmp	func3ilgerr
instrsynerr:
	jmp	func3synerr

instrgetparam:
	call	far ptr farformul
	mov	si,[calcsp]
	lodsw
	test	ah,lenmaskhighcpl	;test	ah,stringmaskhigh
	jnz	instr20		;start position is not set
	or	ax,ax
	jz	instr10
	lodsw
	dec	ax
instr10:
	push	ax		;start position
	add	[calcsp],unitbyte
	cmp	byte ptr [bp],0c2h	;code of ,
	jne	instrsynerr
	inc	bp
	call	far ptr farformul
	jmps	instr50
instr20:
	xor	ax,ax
	push	ax		;start position
instr50:
	mov	si,[calcsp]
	push	si		;base of string1
	cmp	byte ptr [bp],0c2h	;code of ,
	jne	instrsynerr
	inc	bp
	call	far ptr farkakko
	mov	si,[calcsp]
	pop	di		;base of string1
	pop	dx		;start position(-1)

	mov	ax,[di]
	mov	cx,ax
	and	ch,attribmaskhigh
	cmp	ch,stringmaskhigh
	jne	instrilg	;not string
	shl	ax,1
	sbb	ax,0
	and	ax,2*lenmask+1
	sub	ax,dx
;	jbe	instrnot
	add	di,2
	add	di,dx
	mov	dx,ax

	;di=start of string1,dx=bytes of string1 to search

	lodsw
	mov	cx,ax
	and	ch,attribmaskhigh
	cmp	ch,stringmaskhigh
	jne	instrilg
	shl	ax,1
	sbb	ax,0
	and	ax,2*lenmask+1
	jz	instrilg	;if string2=null
	mov	cx,ax

	;si=start of string2,cx=bytes of string2

	ret

;
;* instring2
;  find one in string2 in string1
;
instr2:
	call	instrgetparam
	cmp	dx,0
	jle	instrnot	;start position overrun
	xchg	si,di
instr2lp:
	lodsb
	push	di
	push	cx
	repne	scasb
	je	instr2find
	pop	cx
	pop	di
	dec	dx
	jnz	instr2lp
instr2not:
	backsp_mac
	mov	word ptr [di],0
	jmp	far ptr returnadr
instr2find:
	add	sp,4		;for pop cx,pop di

	mov	ax,si
	mov	si,[calcsp]
	add	si,unitbyte
	mov	[calcsp],si
	sub	ax,si
	sub	ax,2
	mov	word ptr [si],1
	mov	[si+2],ax
	jmp	far ptr returnadr

;
;* n-th member in a string
;  in : si = base + 2, cx=order

stringmember:
	mov	ax,[si-2]
	shl	ax,1
	sbb	ax,0
	and	ax,lenmask*2+1
	jz	memberset0		;null string
	push	si
	add	si,ax
	mov	word ptr [si],0	;endmark
	pop	si		;start of string

	jcxz	memberset0	;0-th member
	dec	cx
	jz	member20
member10:
	cmp	byte ptr [si],0
	je	memberset0
	call	getseparator
	myloop	member10
member20:
	cmp	byte ptr [si],0
	je	memberset0
	push	si
	call	getseparator
	mov	ax,si
	dec	ax
	pop	si
	sub	ax,si
	jbe	memberset0	;null string
	mov	cx,ax		;length
	inc	ax
	shr	ax,1
	jc	member30
	or	ah,80h		;if odd length
member30:
	or	ah,stringmaskhigh
	mov	di,[calcsp]
	stosw
	rep	movsb
	xor	al,al
	stosb
	jmp	far ptr returnadr

memberset0:
	mov	si,[calcsp]
	mov	word ptr [si],stringmask	;null string
	jmp	far ptr returnadr

getseparator:
getseparlp0:
	xor	dx,dx
	lodsb			;front spaces are neglected
	cmp	al,' '		;
	je	getseparlp0
	jmps	getseparjp
getseparlp:
	lodsb
	cmp	al,' '
	je	getsepfind?
getseparjp:
	or	al,al
	jz	getsepret
	cmp	al,','
	je	getsepfind?
	cmp	al,'('
	je	getlsp
	cmp	al,')'
	je	getrsp

;{ } is cut for shift JIS 2nd byte problem
;	cmp	al,'{'	
;	je	getllp
;	cmp	al,'}'
;	je	getrlp
	jmp	getseparlp
getsepfind?:
	or	dx,dx
	jnz	getseparlp
getsepret:
	ret
getlsp:
	inc	dl
	jmp	getseparlp
getrsp:
	dec	dl
	jmp	getseparlp
getllp:
	inc	dh
	jmp	getseparlp
getrlp:
	dec	dh
	jmp	getseparlp

;
; * numerator
;
numerator:
	call	far ptr farkakko
	mov	si,[calcsp]
	mov	di,si
	lodsw
	and	ah,attribmaskhigh
	jz	numerret	;integer
	cmp	ah,ratmaskhigh
	jne	numerilg
numdenin:
	mov	ax,[si]
	and	ax,lenmask
	mov	cx,ax
	inc	cx
	rep	movsw
numerret:
	jmp	far ptr returnadr

numerilg:
	cmp	ah,polymaskhigh
	je	numerret
	cmp	ah,modpolymaskhigh
	je	numerret
	cmp	ah,ratpolymaskhigh
	je	numdenin
	jmp	func3ilgerr

denomiilg:
	cmp	ah,polymaskhigh
	je	denomiset1
	cmp	ah,modpolymaskhigh
	je	denomiset1
	cmp	ah,ratpolymaskhigh
	je	denomiin
	jmp	func3ilgerr

;
; * denominator
;
denominator:
	call	far ptr farkakko
	mov	si,[calcsp]
	mov	di,si
	lodsw
	and	ah,attribmaskhigh
	jz	denomiset1	;integer
	cmp	ah,ratmaskhigh
	jne	denomiilg
denomiin:
	lodsw
	and	ax,lenmask
	shl	ax,1
	add	si,ax
	jmp	numdenin

denomiset1:
	mov	word ptr [si],1
	mov	word ptr [si-2],1
	jmp	far ptr returnadr

;
;* attribute of a data
;
attrib:
	call	far ptr farkakko
	mov	si,[calcsp]
	mov	ax,[si]
	or	ax,ax
	jz	attribret
	mov	[si+2],ax
	mov	ax,1
attribret:
	mov	[si],ax
	jmp	hex1


;
;* type of a data
;
typein:
	call	far ptr farkakko
	mov	si,[calcsp]
	mov	ax,[si]
	mov	al,1
	and	ah,attribmaskhigh
	jz	typeret
	inc	al		;=2
	cmp	ah,ratmaskhigh
	je	typeret
	inc	al		;=3
	cmp	ah,pointmaskhigh
	je	typeret
	inc	al		;=4
	cmp	ah,complexmaskhigh
	je	typeret
	inc	al		;=5
	cmp	ah,stringmaskhigh
	je	typeret
	inc	al		;=6
	cmp	ah,packmaskhigh
	je	typeret
	inc	al		;=7
	cmp	ah,polymaskhigh
	je	typeret
	inc	al		;=8
	cmp	ah,modpolymaskhigh
	je	typeret
	mov	al,0ffh		;undefined type
typeret:
	xor	ah,ah
	mov	[si+2],ax
	mov	word ptr [si],1
	jmp	far ptr returnadr

;
;* change string to capital
;
upperilg:
	jmp	func3ilgerr

upperin:
	call	far ptr farkakko
	mov	si,[calcsp]
	lodsw
	mov	cx,ax
	and	ch,attribmaskhigh
	cmp	ch,stringmaskhigh
	jne	upperilg
	shl	ax,1
	sbb	ax,0
	and	ax,lenmask*2+1
	jz	upperret
	mov	cx,ax
upper20:
	lodsb
  if JAPANESE
	call	kanji1st2
	jnc	upper25
	dec	cx
	jz	upperret
	inc	si		;skip kanji2nd
	jmp	upper30
upper25:
  endif
	cmp	al,'a'
	jb	upper30
	cmp	al,'z'
	ja	upper30
	sub	al,20h
	mov	[si-1],al
upper30:
	myloop	upper20
upperret:
	jmp	far ptr returnadr

;
;* change string to small
;
lowerilg:
	jmp	func3ilgerr

lowerin:
	call	far ptr farkakko
	mov	si,[calcsp]
	lodsw
	mov	cx,ax
	and	ch,attribmaskhigh
	cmp	ch,stringmaskhigh
	jne	lowerilg
	shl	ax,1
	sbb	ax,0
	and	ax,lenmask*2+1
	jz	lowerret
	mov	cx,ax
lower20:
	lodsb
  if JAPANESE
	call	kanji1st2
	jnc	lower25
	dec	cx
	jz	lowerret
	inc	si		;skip kanji2nd
	jmp	lower30
lower25:
  endif
	cmp	al,'A'
	jb	lower30
	cmp	al,'Z'
	ja	lower30
	add	al,20h
	mov	[si-1],al
lower30:
	myloop	lower20
lowerret:
	jmp	far ptr returnadr


;
; * input from IO port
;
inpilg:
	jmp	func3ilgerr

inpin:
	call	far ptr farkakko
	mov	si,[calcsp]
	mov	ax,[si]
	cmp	ax,1
	jb	inp10		;if 0
	ja	inpilg
	mov	ax,[si+2]
inp10:	
	mov	dx,ax
	xor	ax,ax
	in	al,dx
	or	ax,ax
	jz	inp20
	mov	[si+2],ax
	mov	ax,1
inp20:
	mov	[si],ax
	jmp	far ptr returnadr


;
;* find on no condition
;
find2:
	jmp	far ptr returnadr


;
;* string expression of a value
;

str$prntax:
	push	bx
	push	cx
	push	dx
	xor	bx,bx		;flg
	xor	dx,dx
	mov	cx,10000
	call	str$prntaxsub
	mov	cx,1000
	call	str$prntaxsub
	mov	cx,100
	call	str$prntaxsub
	mov	cx,10
	call	str$prntaxsub
	add	al,'0'
	stosb
	pop	dx
	pop	cx
	pop	bx
	ret

str$prnteax:
	push	bx
	push	cx
	push	dx
	set32
	xor	dx,dx
	set32
	xor	cx,cx
	mov	cx,10000
	set32
	div	cx
	push	dx		;lowest 4 digit
	set32
	xor	dx,dx
	set32
	div	cx
	push	dx		;middle 4 digit

	xor	dx,dx
	xor	bx,bx		;flg
	mov	cx,10
	call	str$prntaxsub
	call	str$prntaxsubin

	pop	ax
	mov	cx,1000
	call	str$prntaxsub
	mov	cx,100
	call	str$prntaxsub
	mov	cx,10
	call	str$prntaxsub
	call	str$prntaxsubin

	pop	ax
	mov	cx,1000
	call	str$prntaxsub
	mov	cx,100
	call	str$prntaxsub
	mov	cx,10
	call	str$prntaxsub
	add	al,'0'
	stosb
	pop	dx
	pop	cx
	pop	bx
	ret


str$prntaxsub:
	div	cx
str$prntaxsubin:
	or	bl,bl
	jnz	strpraxsub10
	or	al,al
	jz	strpraxsub20
	mov	bl,1
strpraxsub10:
	add	al,'0'
	stosb
strpraxsub20:
	mov	ax,dx
	xor	dx,dx
	ret

;
; string expression of packed data
;
str$pack:
	checkcalcspfar	2
	mov	si,[calcsp]
	lea	di,[si-unitbyte]
	and	cx,lenmask
	inc	cx
	rep	movsw
	mov	di,[calcsp]
	lea	si,[di-unitbyte]

	add	di,2
	mov	dx,di
	add	dx,2*limitword	;limit of dest pointer
	mov	byte ptr [di],'('
	inc	di		;dest pointer

	add	si,2
	lodsw			;number of elements
	or	ax,ax
	jz	str$pack100

	sub	[calcsp],unitbyte*2

str$pack10:			;must reserve dx in this loop
;	push	ax		;ax is counter
	push	di
	mov	di,[calcsp]
	copy_si2di
	pop	di		;dest pointer

	call	str$packsub

;	pop	ax
	dec	ax
	jz	str$pack90
	mov	byte ptr [di],','
	inc	di
	jmp	str$pack10
str$pack90:
	add	[calcsp],unitbyte*2

str$pack100:
	mov	byte ptr [di],')'
	inc	di
	mov	ax,di
	mov	si,[calcsp]
	sub	ax,si
	dec	ax
	shr	ax,1
	jc	str$pack110
	mov	byte ptr [di],0
	inc	di
	or	ah,80h
str$pack110:
	cmp	di,dx
	ja	str$packover
	or	ah,stringmaskhigh
	mov	[si],ax
	retf
str$packover:
	jmp	func3ovrerr


;
; in : di = dest pointer, dx = limit of dest
; out: di updated
; destroy nothing

str$packsub:
	push	ax
	push	bx
	push	cx
	push	si

	push	dx
	push	di
	call	far ptr farStr$ent
	pop	di
	pop	dx
	mov	si,[calcsp]
	lodsw
	shl	ax,1
	sbb	ax,0
	and	ax,2*lenmask+1
	mov	cx,ax
	add	ax,di
	cmp	ax,dx
	ja	str$packsubover
	rep	movsb

	pop	si
	pop	cx
	pop	bx
	pop	ax
	ret
str$packsubover:
	jmp	func3ovrerr

	
str$extra:
	cmp	al,packmaskhigh
	je	str$pack
	cmp	al,modpolymaskhigh
	je	str$modpoly
	cmp	al,polymaskhigh
	je	str$poly
	jmp	far ptr ilgerr


str$rational:
	call	str$part1
	inc	si		;must be ' '
	dec	cx
	mov	al,'/'
	stosb
	stosb
	rep	movsb
	jmp	str$complex100

str$ilg:
	jmp	far ptr ilgerr

farSTR$ENT:
	mov	si,[calcsp]
	mov	cx,[si]
	mov	al,ch
	and	al,compratstrpackmaskhigh
	jz	str$scalar
	cmp	al,ratmaskhigh
	je	str$rational
	cmp	al,complexmaskhigh
	je	str$complex
	cmp	al,stringmaskhigh
	je	str$ret		;already string
	jmp	str$extra
str$scalar:
	and	cx,lenmask
	inc	cx
	mov	di,work3
	rep	movsw
	call	str$real
	cmp	cx,limitword*2
	ja	str$over
	mov	di,ss:[calcsp]
	stosw
	rep	movsb
	mov	byte ptr es:[di],0
	smov	ds,ss
str$ret:
	retf


str$complex:
	call	str$part1
	lodsb
	cmp	al,' '
	jne	str$complex40
	mov	al,'+'
str$complex40:
	stosb
	dec	cx
	lodsb
	stosb
	dec	cx
	jnz	str$complex50
	cmp	al,'1'
	jne	str$complex60
	dec	di		;if only 1 then cut 1
	jmps	str$complex60
str$complex50:
	rep	movsb
str$complex60:
	mov	al,'#'
	mov	ah,'i'
	stosw
str$complex100:
	xor	al,al
	stosb

	smov	ds,ss

	mov	bx,[calcsp]
	mov	ax,di
	sub	ax,bx
	sub	ax,2		;-3+1
	shr	ax,1
	jc	str$complex70
	or	ah,80h		;if odd length
str$complex70:
	or	ah,stringmaskhigh
	mov	[bx],ax	
	retf



str$real:			;real number in work3 -> string
	mov	si,work3
	mov	cx,[si]
	test	ch,80h
	pushf
	call	far ptr farBinasc
	mov	ax,ss
	add	ax,ascbinseg
	mov	ds,ax
	mov	al,'-'
	popf
	jnz	str$10		;if <0
	mov	al,ss:[plusmark]
str$10:
	mov	si,ascbuftop-1
	mov	[si],al
	or	al,al
	jnz	str$15
	inc	si		;neglect if plusmark=0
str$15:
	mov	ax,ss:[ascend]
	sub	ax,si
	mov	cx,ax		;cx = # of chars
	inc	ax
	shr	ax,1
	jc	str$20
	or	ah,80h
str$20:
	or	ah,stringmaskhigh	;ax = attribute
	ret

str$over:
	jmp	func3ovrerr

	
str$part1:
	mov	si,[calcsp]
	mov	di,work3
	add	si,2
	copy_si2di

	push	si		;top of im-part

	call	str$real

	cmp	cx,limitword*2
	jae	str$over	;over flow or no space for im-part
	pop	dx		;top of im-part

	push	ax
	push	cx
	push	si
	push	ds

	smov	ds,ss		;copy im-part to work3
	mov	si,dx
	mov	di,work3
	copy_si2di

	pop	ds
	pop	si
	pop	cx
	pop	ax

	push	cx
	mov	di,ss:[calcsp]	;set real part
	stosw
	rep	movsb
	push	di
	smov	ds,ss

	push	word ptr [plusmark]
	mov	[plusmark],' '
	call	str$real
	pop	word ptr ss:[plusmark]

	pop	di		;dest adr
	pop	dx		;old byte length
	mov	ax,cx
	add	ax,dx
	cmp	ax,limitword*2
	jae	str$over2	;including 2 bytes of '#i'
	ret
str$over2:
	jmp	func3ovrerr


code2	ends

code3	segment	public
	assume	ds:data,cs:code3

	public	farcpuset,farsysint

sysintspmem	dw	?

_ds	dw	0
_es	dw	0
_ax	dw	1
_bx	dw	2
_cx	dw	3
_dx	dw	4
_si	dw	5
_di	dw	6
_bp	dw	7
_flg	dw	7202h

;
;* get cpu register values
;

cpugetout:
	call	ahedsp3
	mov	si,[calcsp]
	or	ax,ax
	jz	cpugetret
	mov	word ptr [si],1
	add	si,2
cpugetret:
	mov	[si],ax
	jmp	far ptr returnadr

farcpu_ds:
	mov	ax,cs:[_ds]
	jmp	cpugetout
farcpu_es:
	mov	ax,cs:[_es]
	jmp	cpugetout
farcpu_ax:
	mov	ax,cs:[_ax]
	jmp	cpugetout
farcpu_bx:
	mov	ax,cs:[_bx]
	jmp	cpugetout
farcpu_cx:
	mov	ax,cs:[_cx]
	jmp	cpugetout
farcpu_dx:
	mov	ax,cs:[_dx]
	jmp	cpugetout
farcpu_si:
	mov	ax,cs:[_si]
	jmp	cpugetout
farcpu_di:
	mov	ax,cs:[_di]
	jmp	cpugetout
farcpu_bp:
	mov	ax,cs:[_bp]
	jmp	cpugetout
farcpu_flg:
	mov	ax,cs:[_flg]
	jmp	cpugetout

;
;* set cpu register values
;
cpusetsynerr:
	jmp	far ptr synerr

farcpuset:			;jumped from OPTIONCMD3ERR? in excom3.asm
	push	bx
	inc	bp
	cmp	byte ptr [bp],0d1h	;code of "="
	jne	cpusetsynerr
	inc	bp
	pop	bx
	sub	bl,2eh
	jz	farset_ds
	dec	bl
	jz	farset_es
	dec	bl
	jz	farset_ax
	dec	bl
	jz	farset_bx
	dec	bl
	jz	farset_cx
	dec	bl
	jz	farset_dx
	dec	bl
	jz	farset_si
	dec	bl
	jz	farset_di
	dec	bl
	jz	farset_bp
	jmp	farset_flg

cpusetout:
	jmp	far ptr mainlp

farset_ds:
	call	far ptr farget_ax
	mov	cs:[_ds],ax
	jmp	cpusetout
farset_es:
	call	far ptr farget_ax
	mov	cs:[_es],ax
	jmp	cpusetout
farset_ax:
	call	far ptr farget_ax
	mov	cs:[_ax],ax
	jmp	cpusetout
farset_bx:
	call	far ptr farget_ax
	mov	cs:[_bx],ax
	jmp	cpusetout
farset_cx:
	call	far ptr farget_ax
	mov	cs:[_cx],ax
	jmp	cpusetout
farset_dx:
	call	far ptr farget_ax
	mov	cs:[_dx],ax
	jmp	cpusetout
farset_si:
	call	far ptr farget_ax
	mov	cs:[_si],ax
	jmp	cpusetout
farset_di:
	call	far ptr farget_ax
	mov	cs:[_di],ax
	jmp	cpusetout
farset_bp:
	call	far ptr farget_ax
	mov	cs:[_bp],ax
	jmp	cpusetout
farset_flg:
	call	far ptr farget_ax
	mov	cs:[_flg],ax
	jmp	cpusetout

farsysintin:
	push	bp
	mov	cs:[sysintspmem],sp

	mov	bx,cs:[_bx]
	mov	cx,cs:[_cx]
	mov	dx,cs:[_dx]
	mov	si,cs:[_si]
	mov	di,cs:[_di]
	mov	bp,cs:[_bp]
	mov	ax,cs:[_flg]
	push	ax
	popf
	mov	ax,cs:[_ax]
	mov	es,cs:[_es]
	mov	ds,cs:[_ds]
intno:
	int	21h		;dummy
	mov	cs:[_ds],ds
	mov	cs:[_es],es
	mov	cs:[_ax],ax
	mov	cs:[_bx],bx
	mov	cs:[_cx],cx
	mov	cs:[_dx],dx
	mov	cs:[_si],si
	mov	cs:[_di],di
	mov	cs:[_bp],bp
	pushf
	pop	ax
	mov	cs:[_flg],ax

	mov	sp,cs:[sysintspmem]
	pop	bp
	popf
	pop	es
	pop	ds
	jmp	far ptr mainlp


farsysint:
	push	ds
	push	es
	pushf

	call	far ptr farget_ax
	or	ah,ah
	jnz	sysintilgerr

	mov	byte ptr cs:[intno+1],al	;complecated program is made
	jmp	farsysintin			;to clear cache

sysintilgerr:
	jmp	far ptr ilgerr

code3	ends
