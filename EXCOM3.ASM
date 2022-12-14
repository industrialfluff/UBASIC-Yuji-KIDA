;excom3.asm

	INCLUDE	UBDEF.H
	INCLUDE	UB.H

CODE	SEGMENT WORD PUBLIC
	ASSUME	CS:CODE,DS:DATA

	public	optioncmd3
	public	LOCATE,LLOCATE
	public	get_ax,farGet_ax,get_xy,farGET_XY
  if FLG32
  	public	farget_eax
  endif
	public	freein2
	public	letmid,letmember,letterm
	public	letmembernew

	extrn	mainlp:near,ready:near,print2:near,ahedsp:near
	extrn	FORMUL:near,KAKKO:near,resin:near
	extrn	farSTR$ENT:far,fardiscompileall:far
	extrn	farASCHL1000:far
	extrn	msg_cs:near,farprbxsp:far,cursor:near
	extrn	KAKKO_AX:near
	extrn	MIDPARAMIN:near,MIDPARAM2:near
	extrn	GETLAVADR:near,GETLLAVADR:near
	extrn	farfuncset:far
	extrn	farpass1sentence:far

	extrn	UNDEFERR:near,OVRERR:near,DBLDEF:near,FULLERR:near
	extrn	cantdo:near,synerr:near
	extrn	ilgerr:near,diskerr:near,nofile:near,existerr:near
	extrn	nolerr:near,workfull:near
  if FLG98
	extrn	workfull:near
  endif
  if FLG98
  else
	extrn	functionkeytbl:byte
    if FLGFMR
    else
	extrn	fartranskey:far
    endif
  endif

;
;	コマンド実行ルーチン(その３)
;
OPTIONCMD3:
	jmp	far ptr farOPTIONCMD3

;
;☆ＬＬＯＣＡＴＥの処理
;

LLOCATE:
	jmp	far ptr farLlocate

;
;☆ＬＯＣＡＴＥの処理
;

LOCATE:
	jmp	far ptr farLocate


;
;	LOCATE(LLOCATE) 用の引数の GET
;	also used by PRINT USING

farGET_XY:
	call	GET_XY
	retf

GET_XY:
	MOV	[X_LOC],-1	;省略時
	MOV	[Y_LOC],-1

	;第一引数を得る

	cmp	byte ptr [bp],0c2h	;code of ,
	JE	GET_XY20	;PARAM1 は省略されている

	call	get_ax
	jc	get_xyerr
	MOV	[X_LOC],AX

	;第二引数を得る

	MOV	AL,[BP]
	CMP	AL,0C2H		;code of ','
	JE	GET_XY20
	CMP	AL,CR
	JE	GET_XY40	;PARAM2 は省略されている
	CMP	AL,0C0H		;code of ':'
	JE	GET_XY40
	CMP	AL,8FH		;ELSE
	JE	GET_XY40
	CMP	AL,')'
	JE	GET_XY40	;PARAM2 は省略されている
	JMP	SYNERR
GET_XY20:
	INC	BP

	call	get_ax
	jc	get_xyerr
	MOV	[Y_LOC],AX
GET_XY40:
	RET

GET_XYERR:
	JMP	ILGERR


farGET_AX:
	call	get_ax
	retf

get_ax:
	CALL	FORMUL
	MOV	SI,[CALCSP]
	ADD	[CALCSP],UNITBYTE
	MOV	AX,[SI]
	CMP	AX,1
	JA	get_ax_negative?
	JB	get_ax10	;if 0
	MOV	AX,[SI+2]
get_ax10:
	clc
	ret

get_ax_negative?:
	cmp	ax,8001h
	jne	get_axerr
	mov	ax,[si+2]
get_axerr:
	stc
	ret

get_ax_signed:
	CALL	FORMUL
	MOV	SI,[CALCSP]
	ADD	[CALCSP],UNITBYTE
	MOV	AX,[SI]
	CMP	AX,1
	JA	get_axs20
	JB	get_axs10	;if 0
	MOV	AX,[SI+2]
	cmp	ax,8000h
	jae	get_axerr
get_axs10:
	clc
	ret

get_axs20:
	cmp	ax,8001h
	jne	get_axerr
	mov	ax,[si+2]
	cmp	ax,8000h
	jae	get_axerr
	neg	ax
	clc
	ret


  if FLG32
farget_eax:
	CALL	FORMUL
	MOV	SI,[CALCSP]
	ADD	[CALCSP],UNITBYTE
	set32
	xor	ax,ax
	lodsw
	or	ax,ax
	jz	get_eax10
	cmp	ax,2
	ja	get_eax_negative?
	mov	ax,[si]
	jb	get_eax10	;if 1 word
	set32
	mov	ax,[si]
get_eax10:
	clc
	retf

get_eax_negative?:
	;cmp	ax,8001h
	;jne	get_eaxerr
	;mov	ax,[si+2]
get_eaxerr:
	stc
	retf
  endif


;
; * free command
;
freein2:
	jmp	far ptr farFreein2

;
; * substitute term of modpolynomial
;
lettermmodilg:
	jmp	ilgerr
lettermmodsynerr:
	jmp	synerr
lettermmodover:
	jmp	ovrerr


lettermmod:
	set32
	mov	dx,[si+2]	;modulus
	set32
	cmp	dx,word ptr ss:[polymodulus]
	jne	lettermmodilg
lettermmodpoly10:
	push	ds		;*
	push	si		;**
	push	ax		;*** max words of this var.

	smov	ds,ss

	cmp	byte ptr [bp],0c2h	;code of ,
	jne	lettermmodsynerr
	inc	bp
	call	kakko_ax
	jc	lettermmodilg
	add	[calcsp],unitbyte ;kakko_ax does not 'pop'
	pop	dx		;***
	sub	dx,2
	cmp	ax,dx
	ja	lettermmodover
	push	ax		;*** degree(>=0 not incremented)

	cmp	byte ptr [bp],codeofequal
	jne	lettermmodsynerr
	inc	bp

	call	formul		;get p4

	call	ahedsp
	set32
	mov	ax,word ptr [polymodulus]
	set32
	mov	[si+2],ax	;set modulus
	mov	cx,1
	set32
	shr	ax,16
	or	ax,ax
	jz	letmod20
	inc	cx
letmod20:
	mov	[si],cx
	call	resin

	set32
	xor	dx,dx
	mov	si,[calcsp]	;result
	mov	ax,[si]
	or	ax,ax
	jz	lettermmod20
	set32
	mov	dx,[si+2]
	dec	ax
	jnz	lettermmod20
	set32
	shl	dx,16		;cut higher 16bit
	set32
	shr	dx,16
lettermmod20:
	add	si,unitbyte
	mov	[calcsp],si

	pop	cx		;*** degree
	pop	si		;**
	pop	ax		;* ds:si = base adr
	mov	ds,ax
	mov	es,ax

	mov	ax,[si]
	and	ax,lenmask
	shr	ax,1
	jz	lettermmodnew	;if original is null
	dec	ax		;degree+1(old) = # of terms
	inc	cx		;degree+1(dest)
	cmp	ax,cx
	jb	lettermmodappend
	je	lettermmod110
lettermmod90:
	inc	cx
	shl	cx,2
	add	si,cx
	set32
	mov	[si-2],dx		;set value
lettermmodout:
	mov	ax,ss
	mov	ds,ax
	mov	es,ax
	jmp	mainlp

lettermmod110:
	set32
	or	dx,dx
	jnz	lettermmod90
	dec	cx
	jz	lettermmod120	;if 0
	lea	di,[si+2]
	shl	cx,2
	add	di,cx		;di=new highest?
	shr	cx,2
	set32
	xor	ax,ax
	std
	set32
	repe	scasw
	cld
	je	lettermmod120
	add	cx,2
	shl	cx,1
	or	ch,modpolymaskhigh
lettermmod120:
	mov	[si],cx		;set attribute
	jmp	lettermmodout

lettermmodnew:
	;now cx=degree

	smov	ds,ss
	mov	di,si		;es:di = destination
	set32
	or	dx,dx
	jz	lettermmodout	;if 0 on 0
	mov	ax,cx
	add	ax,2
	shl	ax,1
	or	ah,modpolymaskhigh
	stosw			;set attribute

	set32
	mov	ax,word ptr [polymodulus]
	set32
	stosw			;set modulus

	set32
	xor	ax,ax
	set32
	rep	stosw		;fill by 0
	set32
	mov	ax,dx
	set32
	stosw
	jmp	lettermmodout

lettermmodappend:
	;si = base adr
	;cx = degree+1(new)
	;ax = degree+1(old)

	set32
	or	dx,dx
	jz	lettermmodout	;neglect append 0
	sub	cx,ax
	dec	cx

	shl	ax,2
	add	ax,6
	mov	di,si
	add	di,ax
	set32
	xor	ax,ax
	set32
	rep	stosw

	set32
	mov	[di],dx		;set value

	mov	ax,di
	sub	ax,si
	shr	ax,1
	inc	ax
	or	ah,modpolymaskhigh
	mov	[si],ax		;set attribute
	jmp	lettermmodout

;
;* substitute member of polynomial
;  subst p2 in {p1,p2,p3} by p4

lettermnew:
	set32
	mov	dx,word ptr ss:[polymodulus]
	set32
	or	dx,dx
	jz	letterm10
	set32
	mov	[si+2],dx
	jmp	lettermmodpoly10

go_lettermmod:
	jmp	lettermmod


letterm:
	inc	bp
	call	midgetadr
	mov	dx,[si]
	cmp	dx,0
	je	lettermnew	;append to 0
	and	dh,attribmaskhigh
	cmp	dh,modpolymaskhigh
	je	go_lettermmod
	cmp	dh,polymaskhigh
	jne	lettermilg
letterm10:
	call	lettermsub
	jc	lettermdegreecheck

	or	ah,polymaskhigh
	mov	es:[bx],ax
	smov	es,ss
	and	dh,attribmaskhigh
	jz	lettermout	;if integer
	cmp	dh,pointmaskhigh
	je	lettermout	;if real
	cmp	dh,ratmaskhigh
	je	lettermout	;if rational
	cmp	dh,complexmaskhigh
	jne	lettermilg
lettermout:
	jmp	mainlp

lettermilg:
	jmp	ilgerr
lettermsynerr:
	jmp	synerr

lettermdegreecheck:
	smov	ds,es
	mov	di,bx
	lea	si,[bx+4]
	mov	cx,[bx+2]	;# of elements
	mov	dx,cx
	inc	dx
lettermcheck120:
	lodsw
	and	ax,lenmask
	jz	lettermcheck130
	mov	dx,cx		;postion of nonzero elemenet
	add	ax,ax
	add	si,ax
	mov	di,si		;next of nonzero element
lettermcheck130:
	myloop	lettermcheck120

	mov	ax,[bx+2]
	inc	ax
	sub	ax,dx
	mov	[bx+2],ax
	jz	lettermcheck140
	mov	ax,di
	sub	ax,bx
	shr	ax,1
	dec	ax
	or	ah,polymaskhigh
lettermcheck140:
	mov	[bx],ax
	mov	ax,ss
	mov	ds,ax
	mov	es,ax
	jmp	mainlp


lettermsub:
	push	ax		;*max words of this var.
	push	ds		;**
	push	si		;***

	smov	ds,ss

	cmp	byte ptr [bp],0c2h	;code of ,
	jne	lettermsynerr
	inc	bp
	call	kakko_ax
	jc	lettermilg
	inc	ax		;term starts from 0
	jmp	letmembersubin

;
;* substitute submember
;  subst p2 in {p1,p2,p3} by p4

letmembernew:		;abc.2 = 
	call	letmembersubnew
	jmps	letmemberout


letmember:		;member(abc,2) = 
	inc	bp
	call	letmembersub
letmemberout:
	or	ah,packmaskhigh
	mov	es:[bx],ax
	smov	es,ss
	jmp	mainlp


letmembersynerr:
	jmp	synerr
letmemberilgerr:
	jmp	ilgerr


letmembersubnew:
	push	cx		;*max words of this var.
	push	bx		;**
	push	si		;***

	push	es
	mov	es,bx
	mov	ax,es:[si]		;es:si = base adr
	pop	es
	and	ah,attribmaskhigh
	cmp	ah,packmaskhigh
	jne	letmemberilgerr

	inc	bp
	cmp	byte ptr [bp],NCODE1
	jne	letmembersynerr
	inc	bp
	mov	ax,[bp]
	or	ax,ax
	jz	letmemberilgerr
	winc	bp
	jmps	letmembersubin2


letmembersub:
	call	midgetadr
	push	ax		;*max words of this var.
	push	ds		;**
	push	si		;***
	mov	ax,[si]
	and	ah,attribmaskhigh
	cmp	ah,packmaskhigh
	jne	letmemberilgerr

	smov	ds,ss

	cmp	byte ptr [bp],0c2h	;code of ,
	jne	letmembersynerr
	inc	bp
	call	kakko_ax
	jc	letmemberilgerr

letmembersubin:
	add	[calcsp],unitbyte ;kakko_ax does not 'pop'
	or	ax,ax
	jz	letmemberilgerr	;must >0

letmembersubin2:
	push	ax		;**** order

	cmp	byte ptr [bp],codeofequal
	jne	letmembersynerr
	inc	bp
	call	formul		;get p4

	pop	cx		;****
	pop	bx		;***
	pop	ax		;** ds:bx = base adr
	mov	ds,ax
	mov	es,ax

	mov	si,bx
	lodsw
	and	ax,lenmask
	jz	letmemnew	;originally null
	mov	dx,ax		;total words
	lodsw			;# of elements
	cmp	ax,cx
	jb	letmembappend
appendreturn:
	dec	cx
	jz	letmemb30
letmemb20:
	lodsw			;skip p1
	and	ah,lenmaskhigh
	add	ax,ax
	add	si,ax
	myloop	letmemb20
letmemb30:
	mov	ax,[si]		;si = adr of p2
	and	ah,lenmaskhigh
	inc	ax		;size of old p2
	sub	dx,ax		;dx = total size - p2size

	mov	di,ss:[calcsp]
	mov	ax,ss:[di]
	and	ah,lenmaskhigh
	inc	ax		;size of new p2
	mov	cx,ax
	add	dx,ax		;new total word

	pop	ax		;* limit word

	cmp	dx,ax
	ja	letmembover

	push	dx		;* new total word
	push	si		;** si = adr of p2

	mov	di,si
	add	di,cx
	add	di,cx		;di = new adr of p3
	lodsw
	and	ah,lenmaskhigh
	add	si,ax
	add	si,ax		;si = old adr of p3
	mov	ax,[bx]
	and	ah,lenmaskhigh
	inc	ax
	add	ax,ax
	add	ax,bx		;next adr
	sub	ax,si
	jz	letmemblast	;if no p3(exchange last member)
	shr	ax,1
	mov	cx,ax		;rest words
	cmp	si,di
	je	letmemb100
	jb	letmemb90	;old shorter
	; old longer
	rep	movsw
	jmps	letmemb100
	; old shorter
letmemb90:
	dec	ax
	add	ax,ax
	add	si,ax
	add	di,ax
	std
	rep	movsw
	cld
letmemb100:
	pop	di		;** adr of p2
	smov	ds,ss
	mov	si,[calcsp]
	mov	cx,[si]
	mov	dx,cx		;memo attribute of new data
	and	ch,lenmaskhigh
letmemb110:
	inc	cx
	rep	movsw
	add	[calcsp],unitbyte
	pop	ax		;* total word
	clc			;degree unchanged(if polynomial)
	ret			;dx= attribute of new data

letmemblast:
	pop	di		;** adr of p2
	smov	ds,ss
letmemblast10:
	mov	si,[calcsp]
	mov	cx,[si]
	mov	dx,cx		;memo attribute of new data
	and	cx,lenmask
	jnz	letmemb110	;non 0
	mov	word ptr es:[di],0
	add	[calcsp],unitbyte
	pop	ax		;* total word
	stc			;degree changed(if polynomial)
	ret			;dx= attribute of new data

letmemnew:
	mov	di,bx		;es:di = adr of var
	pop	ax		;* limit len
	smov	ds,ss
	mov	si,[calcsp]
	mov	dx,[si]
	and	dx,lenmask
	add	dx,cx		;cx = order
	jc	letmembover
	dec	ax
	cmp	dx,ax
	ja	letmembover
	inc	dx
	push	dx		;* new total word
	mov	ax,dx
	or	ah,polymaskhigh
	stosw
	mov	ax,cx
	stosw
	dec	cx
	xor	ax,ax
	rep	stosw		;fill by 0
	jmp	letmemblast10

letmembover:
	jmp	ovrerr

letmembappend:
	pop	di		;* limit len
	push	di		;*
	push	cx		;** new # of members
	sub	cx,ax
	mov	ax,di		;limit len
	lea	di,[si-2]
	add	di,dx
	add	di,dx		;next adr
	add	dx,cx		;new len
	cmp	dx,ax
	ja	letmembover
	xor	ax,ax	
	rep	stosw		;fill by 0
	mov	ax,[bx]
	and	ax,attribmask
	or	ax,dx		;new attribute
	mov	[bx],ax
	pop	ax		;**
	mov	[bx+2],ax	;new # of elements
	mov	cx,ax
	jmp	appendreturn


;
;* substitute substring
;
letmidSYNERR:
	jmp	synerr
letmidilg:
	jmp	ilgerr

letmid:
	inc	bp

	call	midgetadr
	push	ds		;(+1)
	push	si		;(+2)

	lodsw
	smov	ds,ss
	call	ahedsp
	mov	[si],ax		;set attribute for midparamin

	call	midparamin
	call	midparam2

	cmp	byte ptr [bp],codeofequal
	JNE	letmidSYNERR
	inc	bp

	;now si=destination start adr,cx=bytes

	sub	si,[calcsp]
	push	si		;(+3)
	push	cx		;(+4)

	add	[calcsp],unitbyte

	call	formul
	mov	si,[calcsp]
	lodsw
	mov	dh,ah
	and	dh,attribmaskhigh
	cmp	dh,stringmaskhigh
	jne	letmidilg
	add	ax,ax
	sbb	ax,0
	and	ax,lenmask*2+1
	pop	cx		;(+3)
	cmp	ax,cx
	ja	letmid50
	mov	cx,ax
letmid50:
	pop	di		;(+2)
	pop	ax		;(+1)
	pop	es		;(+0)
	add	di,ax
	rep	movsb
	smov	es,ss
	add	[calcsp],unitbyte
	jmp	mainlp
	

midgetadr:
	mov	al,[bp]
	INC	BP
	SUB	AL,VCODE+2
	jz	midlv
	dec	al
	jz	midlav
	dec	al
	jz	midllv
	dec	al
	jz	midllav
	jmp	ilgerr

midlv:
	xor	ax,ax
	mov	al,[bp]
	inc	bp
	mov	bx,[bp]
	add	bp,ax
	mov	ds,cs:[bx]
	xor	si,si
	mov	ax,ss:[maxword]
	ret
midllv:
	xor	ax,ax
	mov	al,[bp]
	inc	bp
	mov	bx,[bp]
	add	bp,ax
	mov	ds,cs:[bx]
	xor	si,si
	mov	ax,limitword
	ret

midLAV:
	CALL	GETLAVADR
	MOV	SI,DI		;DS は設定済
	mov	ax,ss:[maxword]
	RET
midLLAV:
	CALL	GETLLAVADR
	MOV	SI,DI		;DS は設定済
	mov	ax,limitword
	RET

;
; * value in [si] -> poly
;   in : ax max word len
;   destroy : nothing

val2poly:
	cmp	word ptr [si],0
	je	val2polyret
	push	es
  if flg32
	pusha
  else
	push	ax
	push	cx
	push	dx
	push	si
	push	di
  endif
	mov	dx,ax		;dx = limit words
	mov	ax,[si]
	mov	cx,ax
	and	ch,attribmaskhigh
	jz	val2poly10	;if integer
	cmp	ch,pointmaskhigh
	je	val2poly10	;if real
	cmp	ch,complexmaskhigh
	je	val2poly10	;if complex
	cmp	ch,ratmaskhigh
	je	val2poly10	;if rational
	jmp	ilgerr
val2poly10:
	and	ax,lenmask
	add	si,ax
	add	si,ax		;si=old highest adr
	add	ax,2
	push	ax		;* new len
	cmp	ax,dx
	ja	val2polyover	;too long
	mov	di,ds
	mov	es,di
	lea	di,[si+4]	;di=new highest
	mov	cx,ax
	dec	cx
	std
	rep	movsw
	mov	ax,1
	stosw			;# of terms
	cld
	pop	ax		;*
	or	ah,polymaskhigh
	mov	[di],ax
val2polyout:
  if flg32
	popa
  else
	pop	di
	pop	si
	pop	dx
	pop	cx
	pop	ax
  endif
	pop	es
val2polyret:
	ret

val2polyover:
	jmp	ovrerr


code	ends


DATA	SEGMENT	PUBLIC

	public	defsegdata
	extrn	lpt_dev:byte,prn_dev:byte,lposx:byte
	extrn	calcsp:word,calcsp_limit:word
	extrn	errortrap:word,base_sp:word
	extrn	txttop:word,txtend:word,tcolor:word
  if FLGIBMTOS
  	extrn	tcolor4fill:word
  endif
	extrn	whitenow:byte,maxword:word
	extrn	fnamebuf:byte,handle:word,FILETYPEMARK:byte
	extrn	chars1:byte
	extrn	xpos:byte,ypos:byte,topline:byte,btmline:byte
	extrn	vramsegnow:word,topadr:word,polymodulus:dword
	extrn	schoolflg:byte,directflg:byte

  if DISPFKEY
	extrn	functionkey_sw:byte
  endif
	extrn	arrayseg:word,limitseg:word
	extrn	x_loc:word,y_loc:word

defsegdata	dw	0ff00h

  if FLG98NOTXL
startbank	dw	0
endbank		dw	0
emaunitbytes	dw	0
emawords	dw	0
emanow		dw	0,0
emaout		dw	0,0
elements_seg	dw	0
 endif

ubflg		db	?

data	ends


code2	segment	public
	assume	cs:code2,ds:data

	public	loadgetfilename,get_char2
	public	EXTUBALL2,extubpall2,farLlocatesub
	public	ex3ilgerr
	public	FREEIN

;  if DISPFKEY
	extrn	farDISP_functionkey:far
;  endif
;  if FLG98NOTXL
	extrn	farCLEAR_FUNCTIONKEY:far
;  endif
  if FLG98
	extrn	farJIS_SJIS:far
  endif
  if JAPANESE
	extrn	farKANJI1ST?:far
  endif
	extrn	gomainlp2:near,hotst:far
	extrn	farFORMUL:far,farreal2floatbxjust:far
	extrn	farSETFNAME:far
	extrn	farCURSOR:far,farCURS_HOME:far
  	extrn	farCURSON:far,farCURSOFF:far
  	extrn	farCLEAR_SCREEN:far
	extrn	farSRCLIN:far,farGETLABELADR:far

	extrn	checkoldfile:near,consoledefault:near
	extrn	ahedsp2:near,setfname_time:near
	extrn	dispfilename2:near,prchr2:near,prspc2:near
	extrn	nl2:near,letnl2:near,msg2:near,msg_cs2:near
	extrn	listsubcs2:near,dirsub:near,helpin:near
	extrn	pausein:near,schoolin:near


JMPTBL3	LABEL WORD

	dw	keyset
	dw	outin
	dw	defseg
	dw	pokeByte
	dw	pokeWord
	dw	gsave
	dw	gload
	dw	gprint
	dw	glocate
	dw	gsize
	dw	gcolorin
	dw	rollin
	dw	on_branch	;on
	dw	ex3synerr	;error
	dw	pokeString
	dw	rename
	dw	helpin
	dw	polymod
	dw	doscmd
	dw	pausein
	dw	schoolin
	dw	ex3synerr	;createin
	dw	def_in
	dw	sysintin

ex3synerr:
	jmp	far ptr synerr
ex3ilgerr:
	jmp	far ptr ilgerr

sysintin:
	jmp	far ptr farsysint


farOPTIONCMD3:
	XOR	BX,BX
	MOV	BL,[BP]
	SUB	BL,80H
	CMP	BL,2eH
	JAE	OPTIONCMD3ERR?	;>=0aeH are functions
	INC	BP
	SHL	BX,1
	JMP	CS:jmptbl3[BX]

OPTIONCMD3ERR?:
	cmp	bl,38h
	jae	optioncmd3err
	jmp	far ptr farcpuset

OPTIONCMD3ERR:
	jmp	far ptr synerr

;
; * define line function
;
def_in:
	cmp	[directflg],0
	jne	doscmdsynerr	;def is not used in direct mode
	call	far ptr farpass1sentence
	jmp	gomainlp2

;
; * child process
;
childSPmemo	dw	?
childBPmemo	dw	?

doscmdsynerr:
	jmp	ex3synerr
doscmdilgerr:
	jmp	ex3ilgerr
childworkfull:
	jmp	far ptr workfull

doscmd:
	mov	cs:[childSPmemo],sp

	call	far ptr farCURSON
	mov	al,[bp]
	cmp	al,CR
	je	child20
	cmp	al,3ah		;':'
	jne	child30
child20:
	call	ahedsp2		;dummy
	xor	ax,ax
	push	ax		;dummy
	jmp	child50

child30:
	call	far ptr farFormul
	mov	si,[calcsp]
	lodsw
	push	si		;* start address of a command line
	mov	cx,ax
	and	ah,attribmaskhigh
	cmp	ah,stringmaskhigh
	jne	doscmdsynerr		;not a string
	mov	ax,cx
	and	ax,8000h+lenmask
	add	ax,ax
	sbb	ax,0
	cmp	ax,255
	ja	doscmdilgerr
child50:
	push	ax		;** byte length of a command line

	mov	[childBPmemo],bp
	call	far ptr farclear_functionkey

	mov	ax,[limitseg]
	sub	ax,1000h
	cmp	ax,[arrayseg]
	jb	childworkfull
	mov	ax,code
	sub	ax,0010h
	mov	es,ax		;segment of memory block
	mov	bx,[arrayseg]
	sub	bx,ax
	mov	ah,4ah		;free memory
	int	21h

  if FLG98NOTXL
	GRAMSELECT 0
  endif
  if FLGFMR
	mov	ah,1bh		;set console function
	mov	al,11000010b
	int	91h
  endif

	pop	ax		;**
	pop	si		;*

	or	al,al
	jz	commandcom	;if no command option then load command.com

	mov	bx,si
	add	bx,ax
	mov	byte ptr [bx],CR
	dec	si
	mov	[si],al

	int	2eh		;use resident command.com

childret:
	mov	ax,data
	mov	ds,ax
	mov	es,ax
	mov	ss,ax
	mov	sp,cs:[childSPmemo]
	mov	bp,cs:[childBPmemo]

  if FLG98NOTXL
	GRAMSELECT 1
  endif
  if FLGFMR
	mov	ah,1bh		;set console function
	mov	al,01000100b
	int	91h
  endif

	mov	ax,code
	sub	ax,0010h
	mov	es,ax		;segment of memory block
	mov	ah,4ah
	mov	bx,0ffffh
	int	21h
	mov	ah,4ah
	int	21h

comment %
	mov	ax,cs
	mov	ds,ax
	mov	dx,offset hitkeymsg
	mov	ah,9
	int	21h
	mov	ax,0c07h	;key wait
	int	21h
	mov	ah,2
	mov	dl,CR
	int	21h
	mov	ah,2
	mov	dl,LF
	int	21h

childnowait:
%

	mov	ax,data
	mov	ds,ax
	mov	es,ax

	call	far ptr farClear_Screen
	call	far ptr farCURSOFF
	ADD	[CALCSP],UNITBYTE
	jmp	gomainlp2

  if JAPANESE
hitkeymsg	db	cr,"<何かキーを押すと UBASIC に戻ります> $"
  else
hitkeymsg	db	cr,"<hit any key to return to UBASIC> $"
  endif


;
; search command.com
; out es:di = path

cmdline		db	0,0dh
nullfcb		db	0
comspec		db	'COMSPEC'
param4commandcom	dw	0	;environment seg 0 = from parent
cmdlineadr	dw	offset cmdline,?		;offset, segment
psp1stfcb	dw	offset nullfcb,?
psp2ndfcb	dw	offset nullfcb,?


commandcom:
	push	ds
	push	es
	push	bp

	mov	ax,code
	sub	ax,0010h
	mov	es,ax
	mov	es,es:[002ch]
	xor	di,di		;es:di = top of kankyou

	mov	cx,code
	sub	cx,ax
	my_shl	cx,4		;cx=size of kankyou

	mov	ax,cs
	mov	ds,ax

	;compare with "COMSPEC"

ccomlp:
	push	cx
	push	di
	mov	si,offset comspec
	mov	cx,7
	repe	cmpsb
	pop	di
	pop	cx
	je	ccomexec		;find it

	xor	al,al
	repne	scasb			;search 0
	cmp	es:[di],al		;next 0 too?
	jne	ccomlp

ccomret:
	pop	bp
	pop	es
	pop	ds
	jmp	childret

ccomexec:
	add	di,7
	mov	al,'='
	repne	scasb
	mov	al,' '
	repe	scasb
	dec	di

	mov	ax,es
	mov	ds,ax
	mov	dx,di		;ds:dx = path of command.com

	mov	ax,cs
	mov	es,ax
	mov	cs:[cmdlineadr+2],ax
	mov	cs:[psp1stfcb+2],ax
	mov	cs:[psp2ndfcb+2],ax

	mov	bx,offset param4commandcom

	mov	ax,4b00h	;load & exec
	int	21h

	jmp	ccomret

;
; * set modulus of polynomial
;
polymoddword:
	set32
	lodsw
  if flg98
	MOV	BX,UBCONSTSEG
  else
	mov	bx,ss
	add	bx,ubconstseg
  endif
	mov	ds,bx
	set32
	mov	di,ax

	mov	si,SYSPRM+2	;素数表の位置
	mov	cx,6543-1
	set32
	xor	bx,bx
polymodDWlp:
	mov	bx,[si]
	add	si,2
	set32
	mov	ax,di
	set32
	xor	dx,dx
	set32
	div	bx
	or	dx,dx		;16bit ok
	jz	polymodilgerr	;not a prime
	set32
	cmp	ax,bx
	jbe	polymodDWyes
	dec	cx
	jnz	polymodDWlp
polymodDWyes:
	smov	ds,ss
	set32
	mov	word ptr [polymodulus],di
	add	[calcsp],unitbyte
	jmp	gomainlp2


polymodilgerr?:
	cmp	ax,2
	je	polymoddword
polymodilgerr:
	jmp	ex3ilgerr

polymodsynerr:
	jmp	ex3synerr
polymod:
	cmp	byte ptr [bp],codeofequal
	jne	polymodsynerr
	inc	bp
	call	far ptr farFormul
	mov	si,[calcsp]
	lodsw
	cmp	ax,1
	ja	polymodilgerr?
	jb	polymod100	;if 0

	lodsw
  if flg98
	MOV	BX,UBCONSTSEG
  else
	mov	bx,ss
	add	bx,ubconstseg
  endif
	mov	es,bx
	MOV	di,SYSPRM+2	;素数表の位置
	mov	cx,6543-1
	repne	scasw
	jne	polymodilgerr
	smov	es,ss
polymod100:
	mov	word ptr [polymodulus],ax
	mov	word ptr [polymodulus+2],0
	add	[calcsp],unitbyte
	jmp	gomainlp2


;
;* Rename a file
;
renamesynerr:
	jmp	ex3synerr

rename:
	mov	di,offset fnamebuf
	cmp	byte ptr [bp],CR
	je	renamemenu
	CALL	far ptr farSETFNAME	;PATH 名を得る
	jc	renamemenu
	or	ah,ah
	jnz	rename20		;extension is assigned
	CALL	EXTUB2			;EXTENSION を UB に
rename20:
	cmp	byte ptr [bp],8ah	;to
	jne	renamesynerr
	inc	bp
	mov	di,[calcsp]
	sub	di,unitbyte
	mov	[calcsp],di
	mov	si,offset fnamebuf
rename30:
	lodsb
	stosb
	or	al,al
	jnz	rename30
	CALL	far ptr farSETFNAME	;PATH 名を得る
	jc	renamesynerr
	or	ah,ah
	jnz	rename40		;extension is assigned
	CALL	EXTUB2			;EXTENSION を UB に
rename40:
	mov	ah,56h
	mov	dx,[calcsp]
	mov	di,offset fnamebuf
	int	21h
	jc	renamediskerr
	add	[calcsp],unitbyte
	jmp	gomainlp2

renamediskerr:
	cmp	ax,2
	je	renamenofile
	cmp	ax,5
	je	renameexist
	jmp	far ptr diskerr
renamenofile:
	jmp	far ptr nofile
renameexist:
	jmp	far ptr existerr
renamefileerror:
	pop	di		;dummy
	cmp	ah,1
	je	renamenofile
	cmp	ah,5
	jmp	far ptr ready	;canceled

renamemenu:
	push	di
	call	far ptr fardiscompileall
	pop	di
	push	di
	call	loadgetfilenameall
	jc	renamefileerror
	mov	si,di
	pop	di
	mov	cx,si
	sub	cx,di
	dec	cx
	mov	al,'.'
	repne	scasb
	mov	di,si
	je	renamemenu10	;if . is in file name
	inc	di
renamemenu10:
	mov	byte ptr [di-1],0
	mov	dx,offset renamemsg
	call	msg_cs2
	call	dispfilename2
	call	prspc2
	mov	al,'t'
	call	prchr2
	mov	al,'o'
	call	prchr2
	call	prspc2
	mov	al,'"'
	call	prchr2
	jmp	hotst		;get new file name

renamemsg	db	'rename ',0


;
;* segment definition for peek/poke
;

defseg:
	cmp	byte ptr [bp],codeofequal
	jne	optioncmd3err
	inc	bp
	call	far ptr farGET_ax
	mov	[defsegdata],ax
	jmp	gomainlp2

;
;* poke a value
;
pokeString:
	call	pokegetparam
	mov	si,[calcsp]
	lodsw
	mov	dx,ax
	and	ah,attribmaskhigh
	cmp	ah,stringmaskhigh
	jne	pokesynerr
	mov	ax,dx
	and	ax,8000h+lenmask
	add	ax,ax
	sbb	ax,0
	jz	pokeret		;if null string
	mov	cx,ax

  if FLG98NOTXL
	mov	ax,es
	cmp	ax,GRAMSEG1-1000h
	jb	pokes20
	gramselect 0
	rep	movsb
	gramselect 1
	jmps	pokeret
pokes20:
  endif
	rep	movsb
	jmps	pokeret

pokeWord:
	call	pokegetparam
	mov	si,[calcsp]
	lodsw
	cmp	ax,1
	jb	pokew10
	ja	pokeilgerr	;>1 word
	lodsw
pokew10:
  if FLG98NOTXL
	mov	bx,es
	cmp	bx,GRAMSEG1-1000h
	jae	pokew20
	stosw
	jmps	pokeret
pokew20:
	mov	bx,ax
	gramselect 0
	mov	ax,bx
	stosw
	gramselect 1
	jmps	pokeret	
  else
	stosw
	jmps	pokeret
  endif


POKEbyte:
	call	pokegetparam
	mov	si,[calcsp]
	lodsw
	cmp	ax,1
	jb	pokeb10
	ja	pokeilgerr	;>1 word
	lodsw
	or	ah,ah
	jnz	pokeilgerr	;>1 byte
pokeb10:
  if FLG98NOTXL
	mov	bx,es
	cmp	bx,GRAMSEG1-1000h
	jae	pokeb20
	stosb
	jmps	pokeret
pokeb20:
	mov	bx,ax
	gramselect 0
	mov	ax,bx
	stosb
	gramselect 1
  else
	stosb
  endif

pokeret:
	smov	es,ss
	add	[calcsp],unitbyte
	jmp	gomainlp2

pokesynerr:
	jmp	ex3synerr
pokeilgerr:
	jmp	ex3ilgerr

pokegetparam:
	call	far ptr farGET_ax
	jc	pokeilgerr		;if negative
	push	ax			;offset
	cmp	byte ptr [bp],0c2h	;,
	jne	pokesynerr
	inc	bp
	call	far ptr farFormul	;get value
	mov	es,[defsegdata]
	pop	di		;es:di dest adr
	ret


;
;* output to IO-port
;
outilg:
	jmp	ex3ilgerr
Outin:
	call	far ptr farGET_ax	;get port adr
	push	ax
	cmp	byte ptr [bp],0c2h	;code of ,
	jne	outilg
	inc	bp
	call	far ptr farGET_ax	;get data
	pop	dx
	out	dx,al
	jmp	gomainlp2

;
;* function key redefinition
;

keysetilg:
	jmp	ex3ilgerr
keysetsynerr:
	jmp	ex3synerr

;
; * for PC98
;
  if FLG98
KEYSET:
	call	far ptr farGET_ax
	jc	keysetilg
	or	ax,ax
	jz	keysetilg
	cmp	ax,29h		;38h
	ja	keysetilg
	push	ax		;* key number
	cmp	byte ptr [bp],0c2h	;code of ','
	jne	keysetsynerr
	inc	bp
	call	far ptr farFORMUL
	mov	si,[calcsp]
	lodsw
	mov	di,si

	test	ah,stringmaskhigh
	jz	keysetilg		;not string

	add	ax,ax
	sbb	ax,0
	and	ax,2*lenmask+1
	cmp	ax,15
	jbe	keyset50
	mov	ax,15
keyset50:
	add	di,ax
	mov	cx,16
	sub	cx,ax
	xor	al,al
	rep	stosb

	mov	cl,0dh
	mov	dx,si
	pop	ax		;* key number
	cmp	ax,15h
	jb	keyset60
	cmp	ax,1fh
	ja	keyset60
	mov	byte ptr [si+5],0
keyset60:
	int	0dch
	add	[calcsp],unitbyte
	jmp	gomainlp2		
endif

;
; * for FMR, IBM-PC, J3100
;
  if FLGFMR+FLGIBMTOS
KEYSET:
	call	far ptr farGET_ax
	jc	keysetilg
	or	ax,ax
	jz	keysetilg

	cmp	ax,10
	ja	keysetilg
	push	ax		;* key number

	cmp	byte ptr [bp],0c2h	;code of ','
	jne	keysetsynerr
	inc	bp
	call	far ptr farFORMUL
	mov	si,[calcsp]
	lodsw
	mov	di,si

	test	ah,stringmaskhigh
	jz	keysetilg		;not string

	add	ax,ax
	sbb	ax,0
	and	ax,2*lenmask+1
	cmp	ax,15
	jbe	keyset50
	mov	ax,15
keyset50:
    if FLGFMR
	mov	cx,ax		;cx = number of chars
	mov	ax,0e00h	;ah = 0eh, al = 0 no add keyadr
	pop	dx		;* key number
	push	dx
	mov	dh,80h
	push	cx
	push	di
	int	90h		;ds:di = top addr
	pop	di
	pop	ax
    endif

	add	di,ax
	mov	cx,16
	sub	cx,ax
	xor	al,al
	rep	stosb

	mov	ax,code
	mov	es,ax
	pop	ax		;* key number
	dec	ax
	my_shl	ax,4
	add	ax,offset functionkeytbl
	mov	di,ax
	lodsb
	stosb
	or	al,al
	jnz	keyset60
	mov	byte ptr es:[di-1]," "
keyset60:
	mov	cx,15
	rep	movsb
	smov	es,ss

	cmp	[functionkey_sw],0
	je	keyset70
	call	far ptr farDISP_functionkey
keyset70:
	add	[calcsp],unitbyte
	jmp	gomainlp2		
  endif



  if JAPANESE
loadgetfmsg1	db	'<RET>：選択',tab,'<ESC>：中止',tab,'<SPACE>：内容表示',cr,lf,0
loadgetfmsg2	db	'<RET>：選択',tab,'<ESC>：中止',cr,lf,0
  else
loadgetfmsg1	db	'<RET>:select',tab,'<ESC>:cancel',tab,'<SPACE>:display contents',cr,lf,0
loadgetfmsg2	db	'<RET>:select',tab,'<ESC>:cancel',cr,lf,0
  endif


dispnamelen	equ	16


  if graph
gloadgetfilename:
	mov	[ubflg],0
	push	di
if FLGIBMTOS
else
	call	GRAPHOFF
endif
	pop	di
	push	di		;*push position of file name
	CALL	EXTUBPALL2
	jmps	loadgetf10
  endif


loadgetfilenameall:
	mov	[ubflg],0
	push	di		;*push position of filename
	CALL	EXTALL2
	call	consoledefault
	call	far ptr farCLEAR_screen

	MOV	AH,26		;set DTA
	MOV	DX,INPBUF	;to IMPBUF
	INT	21H

	MOV	[FILETYPEMARK],' '
	CALL	dirsub
	jc	loadgetfnofile
	jmps	loadgetf12

loadgetfilename:
	mov	[ubflg],-1
	push	di		;*push position of filename
	CALL	EXTUBALL2

loadgetf10:
	call	consoledefault
	call	far ptr farCLEAR_screen

	MOV	AH,26		;set DTA
	MOV	DX,INPBUF	;to IMPBUF
	INT	21H

	MOV	[FILETYPEMARK],' '
	CALL	dirsub2
	jc	loadgetfnofile

loadgetf12:
	mov	dx,offset loadgetfmsg1
	cmp	[ubflg],0
	jne	loadgetf15
	mov	dx,offset loadgetfmsg2
loadgetf15:
	call	msg_cs2
	mov	bh,[ypos]	;memo yposition
	sub	bh,2
	xor	dx,dx
loadgetfLP:
	mov	[xpos],dl
	mov	[ypos],dh
	call	LongCursorOn
;  else
;	call	far ptr farcurson
;	call	far ptr farcursor
;  endif
loadgetflp2:
	MOV	AH,7		;直接キー入力
	INT	21H
  if FLG98
  else
	or	al,al
	jnz	loadgetf20
	mov	ah,7		;input 1 more key
	int	21h	
	cmp	al,44h
	jbe	loadgetflp2
    if FLGFMR
    else
	call	far ptr fartranskey
    endif
loadgetf20:
  endif

	call	LongCursorOff

	CMP	AL,CR
	JE	loadgetfin
	cmp	al,ESC
	je	loadgetfbreak
	cmp	al,CTRL_D
	je	curs_right
	cmp	al,CTRL_S
	je	curs_left
	cmp	al,CTRL_E
	je	curs_up
	cmp	al,CTRL_X
	je	curs_down
  if FLGFMR
	cmp	al,1ch
	je	curs_right
	cmp	al,1dh
	je	curs_left
	cmp	al,1eh
	je	curs_up
	cmp	al,1fh
	je	curs_down
  endif
	jmp	loadgetfhelp
curs_down:
	inc	dh
	cmp	dh,bh
	jbe	loadgetflp
	mov	dh,0
	jmp	loadgetflp		
curs_up:
	sub	dh,1
	jnb	loadgetflp
	mov	dh,bh
	jmp	loadgetflp
curs_right:
	add	dl,dispnamelen
	mov	al,[chars1]
	sub	al,dispnamelen
	cmp	dl,al
	jbe	loadgetflp
	mov	dl,0
	inc	dh
	cmp	dh,bh
	jbe	loadgetflp
	mov	dh,0
	jmp	loadgetflp
curs_left:
	sub	dl,dispnamelen
	jae	loadgetflp
	xor	dl,dl
curs_leftlp:
	add	dl,dispnamelen
	cmp	dl,[chars1]
	jbe	curs_leftlp
	sub	dl,2*dispnamelen
	sub	dh,1
	jnb	loadgetflp
	mov	dh,bh
	jmp	loadgetflp

loadgetfhelp:
	cmp	[ubflg],0
	je	loadgetfhelpno
	pop	di		;*pop position of filename
	push	di		;*
	call	dispcontent
loadgetfhelpno:
	jmp	loadgetflp


loadgetfbreak:
	pop	di		;*pop position of filename(dummy)
	mov	ah,bh
	add	ah,2
	mov	[xpos],0
	mov	[ypos],ah
  if FLG98
  else
	call	far ptr farcursor
  endif
	mov	ah,5
	stc
	ret

loadgetfnofile:
	pop	di		;*pop position of filename(dummy)
	mov	ah,1		;no file mark
	stc
	ret

loadgetfin:
	pop	di		;*pop position of filename
	call	getfilenamefromscreen
	call	far ptr farCLEAR_screen
	call	far ptr farCURSOFF
	clc
	ret



  if FLG98
jis_sjis2:
	add	al,20h
	xchg	al,ah
	call	far ptr farJIS_SJIS
	xchg	al,ah
	ret
  endif

  if FLG98
LongCursorOff:
	push	cx
	mov	cx,[tcolor]
	jmps	longcursorin
LongCursorOn:
	push	cx
	mov	cx,[tcolor]
	xor	cx,reversebit
longcursorin:
	push	es
	push	ax
	push	di
	mov	al,[ypos]
	mov	ah,[chars1]
	mul	ah
	add	ax,word ptr [xpos]
	add	ax,ax
	mov	di,ax
	mov	ax,vramseg+200h
	mov	es,ax
	mov	ax,cx
	mov	cx,dispnamelen-2
	rep	stosw
	pop	di
	pop	ax
	pop	es
	pop	cx
	ret
  endif


  if FLGFMR
LongCursorOff:
	push	ax
	push	bx
	mov	ax,[tcolor]
	mov	bx,ax
	jmps	longcursorin
LongCursorOn:
	push	ax
	push	bx
	mov	ax,[tcolor]
	mov	bx,ax
	xor	al,00001000b	;reverse
longcursorin:
	push	cx
	push	dx
	push	di
	mov	[tcolor],ax

	mov	cx,dispnamelen-2
	mov	dh,[ypos]
	mov	dl,[xpos]
	add	dx,0101h
	mov	di,offset tcolor-1
longcurslp:
	mov	ah,0fh
	int	91h
	inc	dl
	myloop	longcurslp

	mov	[tcolor],bx
	mov	di,offset tcolor-1
	mov	ah,11h
	int	91h

	pop	di
	pop	dx
	pop	cx
	pop	bx
	pop	ax
	ret
  endif

  if FLGIBMTOS
LongCursorOff:
LongCursorOn:
	push	ax
	push	bx
	push	cx
	push	dx

	xor	bx,bx

	mov	dh,[ypos]
	mov	dl,[xpos]
	mov	cx,dispnamelen-2
longcurslp:
	push	cx

	mov	ah,2
	int	10h		;set cursor position

	mov	ah,8
	int	10h		;get char

	mov	bl,ah		;attribute
  rept 4
	ror	bl,1		;reverse
  endm
	mov	cx,1
	mov	ah,9
	int	10h		;set char

	inc	dl
	pop	cx
	myloop	longcurslp

	mov	dh,[ypos]
	mov	dl,[xpos]
	mov	ah,2
	int	10h		;set cursor position

	pop	dx
	pop	cx
	pop	bx
	pop	ax
	ret
  endif


getfilenamefromscreen:			;input di
	MOV	ds,ss:[vramsegnow]
	MOV	AL,SS:[YPOS]
	MOV	AH,ss:[chars1]
	MUL	AH
	add	ax,word ptr ss:[xpos]
	add	ax,ax
	MOV	SI,AX		;現在アドレス

	mov	cx,dispnamelen
getffscrn80:
  if FLG98
	lodsw
	or	ax,ax
	jz	getffscrn100
	cmp	ax,0020h
	je	getffscrn100
  else
	lodsw
	cmp	al,20h
	jbe	getffscrn100
  endif
  if FLG98
	or	ah,ah
	jz	getffscrn85
	call	jis_sjis2
	stosw
	add	si,2		;dummy
	jmps	getffscrn90
getffscrn85:
  endif

	stosb
getffscrn90:
	myloop	getffscrn80
getffscrn100:
	mov	al,'.'
	stosb
	smov	ds,ss	
	ret


dispcontent:
	push	bx
	push	dx
	push	di

	call	getfilenamefromscreen
	mov	word ptr [di],'BU'
	mov	byte ptr [di+2],0
	call	far ptr farCURSOFF

	mov	dx,offset FNAMEBUF
	mov	ah,3dh
	xor	al,al
	int	21h		;open file for read
	jc	dispcopenerr2
	mov	bx,ax		;handle

	call	ahedsp2		;* si=top of work area

	mov	ah,3fh		;read program
	mov	dx,si
	mov	cx,unitbyte-10
	int	21h
	jc	dispcopenerr
	push	ax

	mov	ah,3eh		;close handle
	int	21h

	call	far ptr farCLEAR_screen

	pop	cx
	cmp	word ptr [si],0d00h
	jb	dispcbinary
dispcascii:
  if JAPANESE
	dec	cx
  endif
dispc10:
	lodsb
	call	prchr2
	mov	al,[btmline]
	sub	al,2
	cmp	[ypos],al
	jae	dispc20
	myloop	dispc10
dispc20:
  if JAPANESE
	lodsb
	call	far ptr farkanji1st?
	jc	dispc50		;if kanji1st then neglect
	call	prchr2
  endif
	jmps	dispc50

dispcbinary:
	add	cx,si
	dec	cx		;cx=bound
	mov	dx,si		;dx=offset
	call	changeadr
	mov	si,dx
dispc30:
	call	nl2
	call	listsubcs2
	jc	dispc50
	mov	al,[btmline]
	sub	al,2
	cmp	[ypos],al
	jb	dispc30	
dispc50:
	mov	ah,7
	int	21h

	call	far ptr farCLEAR_screen
	pop	di
	push	di
	CALL	EXTUBALL2
	MOV	[FILETYPEMARK],' '
	CALL	dirsub2
	mov	dx,offset loadgetfmsg1
	call	msg_cs2
dispcopenerr:
	add	[calcsp],unitbyte	;*
dispcopenerr2:
	pop	di
	pop	dx
	pop	bx
	ret

changeadr:
	lodsw
	or	ax,ax
	jz	changeadr50
	add	ax,dx
	jc	changeadr40
	cmp	ax,cx
	jae	changeadr40
	mov	[si-2],ax
	mov	si,ax
	jmp	changeadr
changeadr40:
	mov	word ptr [si-2],0
changeadr50:
	ret


dirsub2:
	;最初のファイルを捜す

	MOV	AH,4EH		;search 1st
	MOV	CX,17H		;search all attributed file
	MOV	DX,OFFSET FNAMEBUF
	INT	21H
	jnc	dirlp
	ret			;no file
DIRLP:	
	MOV	DI,INPBUF+1EH	;見付けたファイルを表示
	MOV	CX,dispnamelen
	MOV	AL,'.'
DIR10:
	dec	cx
	INC	DI
	CMP	[DI],AL
	JNE	DIR10
	MOV	AL,' '
	REP	STOSB
	xor	al,al
	stosb			;end mark

	MOV	DI,INPBUF+1EH+8
	MOV	AL,[FILETYPEMARK]
	STOSB
	MOV	BX,INPBUF+15H
	MOV	AL,' '
	TEST	BYTE PTR [BX],1
	JZ	DIR20
	MOV	AL,'p'
DIR20:
	STOSB
	MOV	BX,INPBUF
	MOV	AX,[BX+1AH]	;ファイルのサイズ
	MOV	DX,[BX+1CH]	;ファイルのサイズ
	MOV	BX,100
	DIV	BX
	OR	DX,DX
	JZ	DIRJP
	INC	AX
DIRJP:
	MOV	BX,AX
	MOV	CH,' '
	CALL	far ptr farASCHL1000
	MOV	AX,0020H
	STOSW

	MOV	DX,INPBUF+1EH
	CALL	MSG2		;display this

	mov	al,[xpos]
	add	al,dispnamelen
	cmp	al,[chars1]
	ja	dirsub10
	mov	al,' '
	call	prchr2
	jmps	dirsub20
dirsub10:
	call	nl2

	;次のファイルを捜す
dirsub20:
	MOV	AH,4FH			;search next
	INT	21H
	JNC	DIRLP
	clc
dirsub2RET:
	pushf
	CMP	AX,18
	jne	dirsub2diskerr
	call	nl2
	popf
	ret			;CF=1 iff no file
dirsub2diskerr:
	jmp	far ptr DISKERR


	
;
; * on
;
on_branch:
	mov	ax,[bp]
	cmp	ax,8db2h	;code of error
	jmpz	onerror
	jmp	ex3synerr

;
;on error goto
;
onerror:
	add	bp,2
	cmp	byte ptr [bp],87h	;goto
	jne	onerrsynerr
	inc	bp

	MOV	AL,[BP]
	CMP	AL,Ncode1
	JE	GO1ST		;if 1st time
	CMP	AL,Ncode_LABEL
	JE	GO1STLABEL
	JMP	ex3SYNERR

onerrgotoerr:
	jmp	far ptr nolerr

GO1ST:	
	MOV	CX,[BP+1]
	CALL	far ptr farSRCLIN
	jnz	onerrGOTOERR

	ADD	BX,5		;番地・番号をパスするのみ
				;これ以上最適化すると元に戻せない
	mov	[errortrap],bx
	add	bp,3
	jmp	gomainlp2

GO1STLABEL:
	CALL	far ptr farGETLABELADR
	mov	[errortrap],ax
	jmp	gomainlp2
	

onerrsynerr:
	jmp	ex3synerr


;
;* get charcter from key board
;    with echo,flush buffer
;
get_char2:
	CALL	far ptr farCURSON

	mov	ah,0ch
	mov	al,7
	int	21h

	push	ax
	call	prchr2

	CALL	far ptr farCURSOFF

	pop	ax
	ret


EXTALL2:
	MOV	AX,'.*'
	stosw
	XOR	AX,AX
	mov	al,'*'
	STOSW
	RET

EXTUBALL2:
	MOV	AX,'.*'
	stosw
EXTUB2:
	MOV	AX,'BU'
	STOSW
	XOR	AX,AX
	STOSW
	RET

EXTUBPALL2:
	MOV	AX,'.*'
	stosw
EXTUBP2:
	MOV	AX,'BU'
	STOSW
	XOR	AX,AX
	mov	al,'P'
	STOSW
	RET


;
;☆ＦＲＥＥの処理
;    DISPLAY FREE TEXT AREA
;
FREEIN:
	MOV	DX,OFFSET freetextmsg
	CALL	MSG_CS2
	MOV	BX,TXTLIM
	SUB	BX,[TXTEND]
	CALL	far ptr farPRBXSP
	mov	dx,offset bytemsg
	call	msg_cs2
	JMP	far ptr READY

farFREEIN2:
	MOV	DX,OFFSET freestackmsg
	CALL	MSG_CS2
	mov	di,systemstacktop
	mov	cx,systemstackbtm-systemstacktop
	shr	cx,1
	mov	bx,cx
	mov	ax,2671h
	repe	scasw
	sub	bx,cx
	call	far ptr farPrbxsp
	mov	dx,offset wordmsg
	call	msg_cs2
	jmp	freein

  if JAPANESE
freetextmsg	db	cr,'未使用テキスト領域 ＝ ',0
freestackmsg	db	cr,'未使用スタック領域 ＝ ',0
bytemsg		db	' バイト',cr,lf,0
wordmsg		db	' ワード',cr,lf,0
  else
freetextmsg	db	cr,'Free text area  = ',0
freestackmsg	db	cr,'Virgin stack area = ',0
bytemsg		db	' bytes',cr,lf,0
wordmsg		db	' words',cr,lf,0
  endif


;
;☆ＬＬＯＣＡＴＥの処理
;
farLLOCATE:
	CALL	far ptr farGET_XY
	MOV	AL,[LPT_DEV]
	TEST	AL,1
	JZ	LLOC10
	CALL	LOCATESUB
	MOV	AL,[LPT_DEV]
LLOC10:
	TEST	AL,2
	JZ	LLOC20
	CALL	LLOCATESUB
LLOC20:
	jmp	gomainlp2


	;LLOCATE の SUBROUTINE

farLLOCATESUB:
	call	LLOCATESUB
	retf

LLOCATESUB:
	MOV	AX,[X_LOC]
	CMP	AX,-1
	JE	LLOCSUB30
	CMP	AX,149
	JA	LOCERR

	MOV	CX,AX
	MOV	[LPOSX],AL

  if FLG98
	mov	al,CR
	call	lprint_al2
	JCXZ	LLOCSUB30
LLOCSUB20:
	mov	al,' '
	call	lprint_al2
	myloop	LLOCSUB20	
  else
	MOV	AH,5
	MOV	DL,CR
	INT	21H
	JCXZ	LLOCSUB30
LLOCSUB20:
	MOV	AH,5
	MOV	DL,' '
	INT	21H
	myloop	LLOCSUB20	
  endif
LLOCSUB30:
	RET			;第二引数は無視


;
;☆ＬＯＣＡＴＥの処理
;

farLOCATE:
	CALL	far ptr farGET_XY
	MOV	AL,[PRN_DEV]
	TEST	AL,1
	JZ	LOC10
	CALL	LOCATESUB
	MOV	AL,[PRN_DEV]
LOC10:
	TEST	AL,2
	JZ	LOC20
	CALL	LLOCATESUB
LOC20:
	jmp	gomainlp2


	;LOCATE の SUBROUTINE

LOCATESUB:
	MOV	AX,[X_LOC]
	CMP	AX,-1
	JE	LOCSUB20
	CMP	ax,word ptr [chars1]
	jb	locsub10
	mov	al,[chars1]
	dec	al
locsub10:
	MOV	[XPOS],AL
LOCSUB20:
	MOV	AX,[Y_LOC]
	CMP	AX,-1
	JE	LOCSUB100
	CMP	AX,word ptr [btmline]
	jb	locsub90
	mov	al,[btmline]
	dec	al
locsub90:
	MOV	[YPOS],AL
LOCSUB100:
  if FLG98
	RET
  else
	call	far ptr farCURSOR
	ret
  endif

LOCERR:
	JMP	far ptr ILGERR

lprint_al2:
lprint2_lp:
	mov	ah,11h
	int	1ah
	and	ah,3
	cmp	ah,1
	jne	lprint2_lp
	ret


code2	ends

code3	segment	public
	assume	ds:data,cs:code3

	extrn	farcpuset:far, farsysint:far

code3	ends


  if GRAPH
    if FLGIBMTOS
        include \ubv9\graph.asm
    else
	include	\ub9\graph.asm
    endif
  else
	include	\ub9\nograph.asm
  endif

  if flggprint
    if FLGIBMTOS
    else
	include	gprint.asm
    endif
  else
    if FLGIBMTOS
    	include	nogprint.asm
    else
	include	\ub9\nogprint.asm
    endif
  endif

