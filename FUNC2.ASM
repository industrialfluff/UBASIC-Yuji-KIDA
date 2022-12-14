;FUNC2.ASM


DATA	SEGMENT	WORD PUBLIC

	PUBLIC	SGNMEM_F

	EXTRN	POINTWORD:WORD
	EXTRN	DIVLEN:WORD,DIVWORD:WORD,PTRNOW:WORD,PTRNOW2:WORD
	EXTRN	HANDLE:WORD,EOFFLG:WORD,PTWORD:word,XSIGN2:WORD
	EXTRN	HANDLE1:WORD,HANDLE2:WORD,HANDLE3:WORD,FILENO:WORD
	EXTRN	FHANDLE:WORD,FATTR:WORD,FADR:WORD,FPOINT:WORD
	EXTRN	CALCSP:WORD,calcsp_limit:word
	EXTRN	ANSLEN:WORD,SFTBIT:WORD,SIMEM_M:WORD,DIMEM_M:WORD


ASCLMEM		DW	?

EUL_LOW		DW	?
EUL_HIGH	DW	?

MOB_LOW		DW	?
MOB_HIGH	DW	?
MOB_MEM		DW	?

KROWRK	DW	0
SIMEM_K	DW	?
DIMEM_K	DW	?

VAR_X	DW	?
VAR_Y	DW	?
VAR_A	DW	?

CUTLENGTH	DW	?
SLIDELENGTH	DW	?

;EXPSHIFTBIT	DW	?
;FUNCWORK	DW	?;EXP の整数部
SGNMEM_F	DB	?

DATA	ENDS



CODE	SEGMENT WORD PUBLIC
	ASSUME	CS:CODE,DS:DATA



;PUBLIC LABELS

	PUBLIC	ABSIN,GCDIN,GETGCD,farGETGCD
	PUBLIC	SGNIN,LENIN,BITIN,SQRTIN,farSQRTIN
	PUBLIC	ISQRTIN,KROIN,farKRO_ENT
	PUBLIC	EXP1,CEXPIN,cexp_ent,eulerconst
	PUBLIC	LOGIN,PAIIN,multipi,PRIMEIN,MOBIUS
	PUBLIC	EULER,PRMDIV,EOFIN
	PUBLIC	EXT1IN,EXT2IN,EXT3IN
	PUBLIC	MODPOW,farMODPOW_ENT
	public	MODINV,ASCLEN,NXTPRM
	PUBLIC	MAXin,MINin,SHIFT
	PUBLIC	ODDIN,EVENIN
	PUBLIC	EXTSUB1st,EXTSUB2nd,GET2ARGS,FBACKSP
	PUBLIC	PAI10

	public	farshiftleft,farshiftright

	PUBLIC	GCD_ENT,PRM_ENT,MODINV_ENT,NXTPRM_ENT,SHIFT_ENT
	PUBLIC	MAX_ENT,MIN_ENT,MODPOW_ENT,ASCLEN_ENT
	PUBLIC	EUL_ENT,MOB_ENT,KRO_ENT,sqrt_ENT,Isqrt_ENT
	PUBLIC	ABS_ENT,SGN_ENT,LEN_ENT,BIT_ENT,PRMDIV_ENT
	PUBLIC	LOG_ENT,PAI_ENT

	public	fargcd_calcsp

;EXTERNAL LABELS

	EXTRN	AHEDSP:NEAR,PASSTOKEN:NEAR,MAINLP:NEAR
	EXTRN	ADDIN:NEAR
	EXTRN	LLSUB:NEAR,LWSUB:NEAR
	EXTRN	GCDRESwork2:NEAR,GCDRESsi:near
	EXTRN	squareIFCdi:near,POWER2IN2:NEAR
	EXTRN	CHG2POINT:NEAR
	EXTRN	KAKKO:NEAR,kakko_ax:near
	EXTRN	FORMUL:NEAR,BACKSP:NEAR,comparein:near
	extrn	mulIIdisi:near
	EXTRN	READRECORD:NEAR,MUL3216:NEAR
	extrn	mulin:near

	extrn	addIIdisi:near
	extrn	idivIIdisi:near
	extrn	float2intbx:near,farfloat2intbx:far
	extrn	int2floatbxcurrent:near
	extrn	squareIdi:near

	EXTRN	SYNERR:NEAR,DIVERR:NEAR,ILGERR:NEAR,OVRERR:NEAR
	EXTRN	FUNCERR:NEAR,DISKERR:NEAR,INDEXERR:NEAR,ILGDATA:NEAR
	EXTRN	NOTOPEN:NEAR,SYSTEMERR:NEAR,calcsperr:near

if FLG32
else
	EXTRN	LLDSUB:NEAR
endif

;
;☆ ODD
;
ODDIN:
	CALL	KAKKO
	MOV	BX,[CALCSP]
	MOV	AX,[BX]
	OR	AX,AX
	JZ	FALSERET	;IF ZERO
	TEST	AH,attribmaskhigh
	JNZ	ODDILG;IF not integer
	MOV	AX,[BX+2]
	TEST	AL,1
	JZ	FALSERET
TRUERET:
	MOV	AX,1
	MOV	[BX],AX
	MOV	[BX+2],AX
	RET
FALSERET:
	XOR	AX,AX
	MOV	[BX],AX
	RET
ODDILG:
	JMP	ILGERR

;
;☆ EVEN
;
EVENIN:
	CALL	KAKKO
	MOV	BX,[CALCSP]
	MOV	AX,[BX]
	OR	AX,AX
	JZ	TRUERET;IF ZERO
	TEST	AH,attribmaskhigh
	JNZ	ODDILG;IF not integer
	MOV	AX,[BX+2]
	TEST	AL,1
	JZ	TRUERET
	JMP	FALSERET

;
; *	shl	[di] by ax bits
; *	shr	[di] by ax bits
;	[di] must be integer

farshiftleft:
	or	ax,ax
	jz	farshiftleftret;if bit = 0
	mov	dx,[di]
;	test	dh,compratstrpackmaskhigh
;	jnz	shift_ilg;complex/rational/string
	and	dx,lenmask
	jz	farshiftleftret;if = 0
	call	shiftleftin
farshiftleftret:
	retf

farshiftright:
	or	ax,ax
	jz	farshiftrightret	;if bit = 0
	mov	dx,[di]
;	test	dh,compratstrpackmaskhigh
;	jnz	shift_ilg;complex/rational/string
	and	dx,lenmask
	jz	farshiftrightret	;if = 0
	call	shiftrightin
farshiftrightret:
	retf
	
;
;☆ SHIFT
;   SHIFT(数式,BIT数)

shiftfover:
	jmp	ovrerr

shiftfloat:
	mov	cx,[si]
	jcxz	shiftret
	test	ch,attribmaskhigh
	jnz	shift_ilg	;BIT count must be an integer
	test	ch,signmaskhigh
	jz	shiftfleft
	jmp	shiftfright	;shift right if negative
shiftfleft:
	cmp	cx,1
	ja	shift_ilg
	mov	ax,[si+2]
	mov	cx,ax
	my_shr	ax,3
	add	ax,[di+2]

	and	cx,7
	and	dx,lenmask
	add	dx,dx
	add	di,dx
	xor	bx,bx
	mov	bl,[di+1]	;highest byte adr
	sub	di,dx
	shl	bx,cl
	or	bh,bh
	jz	shiftfleft50

	inc	ax
	cmp	ax,floatbiasover
	jge	shiftfover
	sub	cx,8
	neg	cx
	jmp	shiftfright50

shiftfleft50:
	cmp	ax,floatbiasover
	jge	shiftfover
	mov	[di+2],ax	;new bias

	mov	dx,[di]
	and	dx,lenmask
	dec	dx
	add	di,4
	add	dx,dx
	xor	ch,ch;for memo data
shiftflp:
	mov	ah,[di]
	mov	al,ch
	mov	ch,ah
	shl	ax,cl
	mov	[di],ah
	inc	di
	dec	dx
	jnz	shiftflp
	ret

shiftfright:
	and	cx,lenmask
	cmp	cx,1
	ja	shift_ilg
	mov	ax,[si+2]
	mov	cx,ax
	my_shr	ax,3
	neg	ax
	add	ax,[di+2]	;bias

	and	cx,7
	and	dx,lenmask
	add	dx,dx
	add	di,dx
	mov	bx,[di];highest word adr
	sub	di,dx
	shr	bx,cl
	or	bh,bh
	jnz	shiftfright50

	dec	ax
	cmp	ax,floatbiasunder
	jle	shiftf_set0
	sub	cx,8
	neg	cx
	jmps	shiftfleft50
shiftfright50:
	cmp	ax,floatbiasunder
	jle	shiftf_set0
	mov	[di+2],ax	;new bias

	mov	dx,[di]
	and	dx,lenmask
	mov	bx,di;memo base adr
	dec	dx
	add	di,4
	add	dx,dx
	mov	ch,[di]
	dec	dx
	push	cx
shiftfrlp:
	mov	ah,[di+1]
	mov	al,ch
	mov	ch,ah
	shr	ax,cl
	mov	[di],al
	inc	di
	dec	dx
	jnz	shiftfrlp
	mov	[di],ah
	pop	ax
	shr	ax,cl
	shl	al,1
	jc	roundup
	ret
roundup:
	mov	cx,[bx]
	add	bx,4
	stc
rounduplp:
	adc	word ptr [bx],0
	winc	bx
	jc	rounduplp
	ret

shiftf_set0:
	mov	word ptr [di],0
	ret

shift_ilg:
	jmp	ilgerr


	public	SHIFT
SHIFT:
	;get X,Y を得る

	CALL	GET2ARGS

SHIFT_ENT:
	CALL	FBACKSP

	mov	ax,[di]
	mov	dx,ax
	and	ah,attribmaskhigh
	jz	shiftint
	cmp	ah,pointmaskhigh
	jne	shift_ilg
	jmp	shiftfloat

shiftint:
	and	dx,lenmask
	jz	shiftret	;if = 0

	mov	cx,[si]
	jcxz	shiftret
	test	ch,attribmaskhigh
	jnz	shift_ilg	;BIT count must be an integer
	test	ch,signmaskhigh
	jz	shiftleft
	jmp	shiftright	;shift right if negative

SHIFT_OVR:
	JMP	OVRERR

SHIFTRET:
	RET

SHIFTLEFT:
	CMP	CX,1
	JA	SHIFT_OVR	;>= 65536 bits is illegal
	WINC	SI
	MOV	AX,[SI]

shiftleftin:	;inp: di, dx, ax
	MOV	CX,AX;reserve BIT count in AX
	AND	CX,7;BYTE 以下の端数分
	JZ	SHIFTLBYTE
	cmp	cx,2
	ja	shiftL40
SHIFTL15:
	PUSH	CX
	MOV	BX,DI
	MOV	CX,DX
	CLC
SHIFTL20:
	WINC	BX
	RCL	WORD PTR [BX],1
	myloop	SHIFTL20
	JNC	SHIFTL30
	INC	DX
	CMP	DX,LIMITWORD
	JA	SHIFT_OVR	
	AND	WORD PTR [DI],0E000H	;sgn,point,complex bit
	OR	[DI],DX
	MOV	WORD PTR [BX+2],1
SHIFTL30:
	POP	CX
	myloop	SHIFTL15
	jmp	shiftLBYTE

shiftL40:
	push	ax;bits

	mov	bx,1
	shl	bx,cl;multiplier

	mov	cx,dx;word length

	push	di;attribute adr
	winc	di
	xor	si,si
shiftL50:
	mov	ax,[di]
	mul	bx
	add	ax,si
	adc	dx,0
	mov	si,dx
	stosw
	myloop	shiftL50

	mov	bx,di
	pop	di;attribute adr

	or	dx,dx
	jz	shiftLbyte0	;if no carry

	mov	[bx],dx;store new highest word
	mov	dx,[di]
	mov	bx,dx;memo
	and	dx,lenmask
	inc	dx
	cmp	dx,limitword
	ja	SHIFT_OVR
	and	bh,0e0h;sgn,point,complex bit
	or	dh,bh
	mov	[di],dx

SHIFTLBYTE0:
	pop	ax
	mov	dx,[di]
	and	dx,lenmask

SHIFTLBYTE:
	MY_SHR	AX,3
	JZ	SHIFTRET2
	SHR	AX,1
	JNC	SHIFTLWORD

	PUSH	DI

	MOV	BX,DX
	SHL	BX,1
	MOV	CX,[BX+DI]	;highest word
	INC	BX;DESTINATION MSWord
	OR	CH,CH
	JZ	SHIFTL60
	INC	DX
	CMP	DX,LIMITWORD
	JA	SHIFT_OVR2
	AND	WORD PTR [DI],0C000H
	OR	[DI],DX
	INC	BX
	MOV	WORD PTR [BX+DI],0	;DESTINATION MSWord
SHIFTL60:
	LEA	DI,[BX+DI]
	LEA	SI,[DI-1]
	MOV	CX,BX
	DEC	CX
	DEC	CX
	STD
	REP	MOVSB
	CLD
	MOV	BYTE PTR [DI],0	;DESTINATION LSWord

	POP	DI

SHIFTLWORD:
	OR	AX,AX;NOW AX=WORDS FOR SHIFT
	JZ	SHIFTRET2

	MOV	BX,DX
	ADD	BX,AX
	CMP	BX,LIMITWORD
	JA	SHIFT_OVR2
	AND	WORD PTR [DI],0C000H
	OR	[DI],BX
	SHL	BX,1
	LEA	DI,[BX+DI]
	MOV	SI,DI
	SUB	SI,AX
	SUB	SI,AX
	MOV	CX,DX
	STD
	REP	MOVSW
	MOV	CX,AX
	XOR	AX,AX
	REP	STOSW
	CLD
SHIFTRET2:
	RET

SHIFT_OVR2:
	JMP	OVRERR

SHIFT_0_POP:
	POP	CX;DUMMY
SHIFT_0:
	MOV	WORD PTR [DI],0
	RET	

SHIFTRIGHT:	;now DX=word length
	AND	CH,7FH
	CMP	CX,1
	JA	SHIFT_0;if > 65535
	WINC	SI
	MOV	AX,[SI];AX で BIT 数を保存

SHIFTRIGHTin:	;inp: di, dx, ax
	MOV	CX,AX
	AND	CX,7;BYTE 以下の端数分
	JZ	SHIFTRBYTE
	cmp	cx,1
	jne	shiftr40	;>= 2 bits

	; shift 1 bit

	push	ax;bits

	mov	cx,dx
	MOV	BX,DX
	SHL	BX,1
	ADD	BX,DI
	MOV	ax,[BX];memo MSWord
	clc
SHIFTR20:
	RCR	WORD PTR [BX],1
	WDEC	BX
	myloop	SHIFTR20
	CMP	ax,1
	JNE	SHIFTR30
	DEC	DX
	JZ	SHIFT_0_pop
	AND	WORD PTR [DI],0e000H	;sign,point,complex bit
	OR	[DI],DX
SHIFTR30:
	jmp	shiftrbyte0

	; shift multi bit

shiftr40:
	push	ax;bits

	mov	bx,1
	shl	bx,cl;numerator

	mov	cx,dx;word length
	shl	dx,1
	add	di,dx
	mov	si,di;highest WORD adr
	std
	xor	dx,dx
shiftr50:
	mov	ax,[di]
	div	bx
	stosw
	myloop	shiftr50
	cld

	cmp	word ptr [si],0
	jne	shiftrbyte0

	mov	ax,[di]
	mov	bx,ax;memo
	and	ax,lenmask
	dec	ax
	jz	shift_0_pop
	and	bh,0e0h;sgn,point,complex bit
	or	ah,bh
	mov	[di],ax

SHIFTRBYTE0:
	pop	ax
	mov	dx,[di]
	and	dx,lenmask

SHIFTRBYTE:
	MY_SHR	AX,3
	JZ	SHIFTRRET
	SHR	AX,1
	JNC	SHIFTRWORD

	MOV	BX,DI;PUSH	DI

	winc	di
	LEA	SI,[DI+1]
	MOV	CX,DX
	SHL	CX,1
	DEC	CX
	REP	MOVSB
	MOV	BYTE PTR [DI],0
	CMP	BYTE PTR [DI-1],0
	MOV	DI,BX;POP	DI
	JNE	SHIFTR60
	DEC	DX
	JZ	SHIFT_02
	AND	WORD PTR [DI],0C000H
	OR	[DI],DX
SHIFTR60:

SHIFTRWORD:
	OR	AX,AX;NOW AX=WORDS FOR SHIFT
	JZ	SHIFTRRET

	MOV	BX,DX
	SUB	BX,AX
	JBE	SHIFT_02
	AND	WORD PTR [DI],0C000H
	OR	[DI],BX
	LEA	DI,[DI+2]
	MOV	SI,DI
	add	ax,ax
	ADD	SI,AX
	MOV	CX,BX
	REP	MOVSW
SHIFTRRET:
	RET

SHIFT_02:
	MOV	WORD PTR [DI],0
	RET	


;
;☆ 16 BIT 数の最初の約数を得る
;   32 BIT 以下の数ならば完全
;   32 BIT より大きくて約数が見付からない場合は 0 を返す
;
PDIVSET:
	MOV	DI,[CALCSP]
	MOV	CX,[DI]
	TEST	CH,attribmaskhigh
	JNZ	PRMDIV_ILG	;not integer
	AND	CX,LENMASK
	JZ	PDIV0
	MOV	[DI],CX;強制的に POSITIVE に
	RET
PDIV0:
	POP	AX;DUMMY
	RET


PRMDIV_ILG:
	JMP	ILGERR


PRMDIV:
	CALL	KAKKO
PRMDIV_ENT:
	CALL	PDIVSET
PRMDIVIN:
	CMP	CX,2
	JA	PDIV200;3 WORD 以上は別扱い
	JE	PDIV100;2 WORD の場合

	;一ワードの場合
PDIV10:
	MOV	AX,[DI+2]
	CMP	AX,3
	JBE	PDIV_RET	;3 以下は素数
;	MOV	BX,DATA
  if flg98
	MOV	BX,UBCONSTSEG
  else
	mov	bx,ss
	add	bx,ubconstseg
  endif
	mov	es,bx
	MOV	SI,SYSPRM	;素数表の位置
PDIV20:
	WINC	SI
	MOV	CX,ES:[SI]
	MOV	AX,[DI+2]
	XOR	DX,DX
	DIV	CX
	OR	DX,DX
	JZ	PDIV_CX;等しくなくて割れたら合成数
	CMP	AX,CX
	JAE	PDIV20;商>=割る数
;商<割る数ならば素数

PDIV_RET:
	MOV	AX,SS
	MOV	ES,AX
	RET


PDIV_CX:	;CX が約数の場合
	MOV	DI,[CALCSP]
	MOV	WORD PTR [DI],1
	MOV	[DI+2],CX
	JMP	PDIV_RET


	;二ワードの場合
PDIV100:
  if flg98
	MOV	BX,UBCONSTSEG
  else
	mov	bx,ss
	add	bx,ubconstseg
  endif
	mov	es,bx
	MOV	SI,SYSPRM	;素数表の位置
PDIV110:
	WINC	SI
	MOV	CX,ES:[SI]
	JCXZ	PDIV_RET	;割る数が無くなった
	MOV	AX,[DI+4]
	XOR	DX,DX
	DIV	CX
	MOV	BX,AX;商をメモ
	MOV	AX,[DI+2]
	DIV	CX
	OR	DX,DX
	JZ	PDIV_CX;割れたら合成数
	OR	BX,BX
	JNZ	PDIV110
	CMP	AX,CX
	JAE	PDIV110;商>=割る数
	JMP	PDIV_RET	;商<割る数ならば素数


	;三ワード以上の場合
PDIV200:
  if flg98
	MOV	BX,UBCONSTSEG
  else
	mov	bx,ss
	add	bx,ubconstseg
  endif
	MOV	ES,BX
	MOV	SI,SYSPRM	;素数表の位置
PDIV210:
	WINC	SI
	MOV	BX,ES:[SI]
	OR	BX,BX
	JZ	XPRMDIV;割る数が無くなった
	MOV	DI,[CALCSP]
	CALL	PDIVLWDIV
	JNZ	PDIV210
	MOV	CX,BX
	JMP	PDIV_CX;割り切れた場合

XPRMDIV_ILG:
	JMP	ILGERR

XPRMDIV:
	MOV	AX,SS
	MOV	ES,AX
	MOV	DI,[CALCSP]
	MOV	CX,[DI]
	CMP	CX,LIMITWORD
	JAE	XPRMDIV_ILG	;都合上510WORDSもエラー

	;[DI] を 15 BIT SHIFT して mulwork へ

	MOV	SI,DI
	ADD	SI,CX
	ADD	SI,CX
	MOV	DI,mulwork
	MOV	[DI],CX

	STD
	LODSW
	CMP	AX,1
	JE	XPRMDIV2;最上位が1だった
	INC	WORD PTR [DI]
XPRMDIV2:
	ADD	DI,CX
	ADD	DI,CX
	WINC	DI

	SHR	AX,1
	STOSW
	DEC	CX
XPRMDIV4:
	LODSW
	RCR	AX,1
	STOSW
	myloop	XPRMDIV4
	CLD

	MOV	AX,0
	RCR	AX,1
	MOV	[DI],AX	;最下位

	MOV	BX,WORK3
	MOV	WORD PTR [BX],2	;ワード数
	MOV	WORD PTR [BX+2],8000H	;割る数の下位ワード
XPRMDIV10:
  if FLG98
	MOV	AX,UBCONSTSEG
  else
	mov	ax,ss
	add	ax,ubconstseg
  endif
	MOV	ES,AX
	MOV	SI,SYSPRM2W-2	;素数表の位置
XPRMDIV20:
	WINC	SI
	MOV	AX,ES:[SI]
	OR	AX,AX
	JZ	XPRMDIVOUT	;割る数が無くなった
	MOV	BX,WORK3+4
	MOV	[BX],AX
  if flg98
  else
	push	es
  endif
	PUSH	SI
	CALL	XPRMDIVDIV
	POP	SI
  if flg98
	MOV	AX,UBCONSTSEG
	MOV	ES,AX
  else
	pop	es
  endif
	JNZ	XPRMDIV20	;割り切れなければ次の数へ

	MOV	DI,[CALCSP]	;割り切れた場合
	MOV	WORD PTR [DI],2
	MOV	AX,ES:[SI]
	ROL	AX,1
	MOV	[DI+2],AX
	MOV	WORD PTR [DI+4],1

XPRMDIVRET:
	MOV	AX,SS
	MOV	ES,AX
	RET

XPRMDIVOUT:
	MOV	DI,[CALCSP]
	MOV	CX,[DI]
	CMP	CX,3
	JA	XPRMDIV?
	MOV	AX,[DI+6]
	CMP	AX,4
	JB	XPRMDIVRET	;素数である

XPRMDIV?:
	MOV	WORD PTR [DI],0
	JMP	XPRMDIVRET


if FLG32
;---------------------------------------
XPRMDIVDIV:
	MOV	AX,DS
	MOV	ES,AX

	MOV	DI,WORK3
	MOV	SI,mulwork
	SET32
	MOV	BX,[DI+2]	;割る数(32BIT)
	MOV	CX,[SI]
	AND	CX,LENMASK
	ADD	SI,CX
	ADD	SI,CX
	TEST	CL,1
	JZ	XPRMDD10
	INC	CX
	WINC	SI
	MOV	WORD PTR [SI],0
XPRMDD10:
	WDEC	SI;32BIT BASE
	SHR	CX,1
	SET32
	XOR	DX,DX
	STD
XPRMDD20:
	SET32
	LODSW
	SET32
	DIV	BX
	myloop	XPRMDD20
	CLD
	SET32
	OR	DX,DX
	RET
;---------------------------------------
else
;---------------------------------------
XPRMDIVDIV:
	MOV	AX,DS
	MOV	ES,AX

	MOV	SI,WORK3
	MOV	[SIMEM_M],SI
	MOV	[DIVLEN],2	;2 ワード

	MOV	AX,[SI+4]
	MOV	[DIVWORD],AX
	MOV	[SFTBIT],0

	MOV	SI,mulwork
	MOV	AX,[SI]
	MOV	DI,RESADR
	INC	AX
	MOV	CX,AX
	REP	MOVSW
	MOV	WORD PTR [DI],0	;最上位＋１を０に
	SUB	DI,RESADR
	MOV	[PTRNOW],DI

	;商の予想される長さを得る

	SUB	AX,[DIVLEN]
	MOV	CX,AX;COUNTER
	add	ax,ax
	MOV	[PTRNOW2],AX

	PUSH	BP
XPRMDIVDIV30:
	PUSH	CX
	CALL	LLDSUB
	POP	CX
	MOV	AX,2
	SUB	[PTRNOW],AX
	SUB	[PTRNOW2],AX
	myloop	XPRMDIVDIV30
	POP	BP

	MOV	CX,[DIVLEN]
	MOV	DI,CX
	SHL	DI,1
	ADD	DI,RESADR
	XOR	AX,AX
	STD
	REPE	SCASW
	CLD
	RET	;ZF=1 iff AMARI=0
;---------------------------------------
endif

	;[DI]=[DI]/BX

PDIVLWDIV:
	XOR	DX,DX;余り
	MOV	CX,[DI]
	ADD	DI,CX
	ADD	DI,CX
	STD
PDIVLWDIV10:
	MOV	AX,[DI]
	DIV	BX
	WDEC	DI
	myloop	PDIVLWDIV10	
	CLD
	OR	DX,DX
	RET




;
;☆ＭＡＸ，ＭＩＮの処理
;

MAXin:
	mov	al,3
	jmps	minmax

max_ent:
	mov	al,3
;	sub	[calcsp],unitbyte
	jmps	minmaxsub

MINin:
	mov	al,5
	jmps	minmax

min_ent:
	mov	al,5
;	sub	[calcsp],unitbyte
	jmps	minmaxsub

MINMAX:
	push	ax;copare code

	;1st param を得る

	call	formul
	cmp	byte ptr [bp],0c2h	;code of ,
	jne	minmaxsynerr
	inc	bp

	;next param を得る
minmaxlp:
	call	formul
	pop	ax;*
	push	ax
	call	minmaxsub
	mov	al,[bp]
	inc	bp
	cmp	al,0c2h;code of ,
	je	minmaxlp
	cmp	al,')'
	jne	minmaxsynerr
	add	sp,2;pop ax
	ret

minmaxsynerr:
	jmp	synerr
minmaxilgerr:
	jmp	ilgerr	


minmaxsub:
	mov	si,[calcsp]
	lea	di,[si+unitbyte]
	push	ax; al = 比較コード
	call	comparein
	mov	si,[calcsp]
	lea	di,[si+unitbyte]
	mov	[calcsp],di	;backsp
	pop	dx
	cmp	al,6
	je	minmaxilgerr
	and	al,dl
	jnz	minmaxsubret
minmaxcopy:	;copy Y to X
	copy_si2di
minmaxsubret:
	ret


;
;☆ＮＸＴＰＲＭの処理
;

GONXPSET0:
	JMP	NXPSET0

NXPSET2:
	MOV	AX,1
	STOSW
	INC	AX
	STOSW
	RET

nxtprmrational:
	call	cvr
	mov	cx,[di]
	cmp	ch,pointmaskhigh
	je	nxppoint
	jmp	ilgerr

NXTPRM:
	CALL	KAKKO

NXTPRM_ENT:
	MOV	DI,[CALCSP]
	MOV	AX,[DI]
	mov	ch,ah
	and	ch,LENMASKHIGHCPL	;11111100b
	jz	nxp10;if positive integer
	cmp	ch,ratmaskhigh
	je	nxtprmrational
	cmp	ch,pointmaskhigh
	je	nxppoint
	jmp	ilgerr
nxppoint:
	mov	bx,di
	call	float2intbx
	MOV	DI,[CALCSP]
	MOV	AX,[DI]
NXP10:
	AND	AX,LENMASK
	JZ	NXPSET2;引数が 0 なら答えは 2
	MOV	[DI],AX
	CMP	AX,2
	JA	GONXPSET0	;3 WORD 以上は不可
	JE	NXP100;2 WORD の場合

	;1 WORD の場合

	MOV	AX,[DI+2]
	CMP	AX,65521
	JAE	NXP50
	MOV	CX,AX

  if flg98
	MOV	BX,UBCONSTSEG
  else
	mov	bx,ss
	add	bx,ubconstseg
  endif
	MOV	DS,BX
	MY_SHR	AX,2
	AND	AL,11111110B
	MOV	SI,AX
	CMP	SI,6542*2
	JBE	NXP15
	MOV	SI,6542*2
NXP15:
	MOV	BX,SYSPRM
NXP20:
	CMP	CX,[BX+SI]
	JAE	NXP30
	SUB	SI,20
	JNB	NXP20
	XOR	SI,SI
NXP30:
	LEA	SI,[BX+SI]
NXP40:
	LODSW
	CMP	AX,CX
	JBE	NXP40
	MOV	CX,SS
	MOV	DS,CX

	MOV	[DI+2],AX
	RET

NXP50:
	MOV	AX,2;SET 65537
	STOSW
	DEC	AX
	STOSW
	STOSW
	RET

	;2 WORD の場合
NXP100:
	set32
	MOV	AX,[DI+2]
	set32
	inc	ax
	jz	NXPSET0
	set32
	shr	ax,1
	set32
	MOV	[DI+2],AX
NXP105:
	PUSH	DI;☆
	MOV	DI,INPBUF
	set32
	XOR	AX,AX;ふるい用バッファをクリア
	set32
	xor	cx,cx;clear higher word
	MOV	CX,64;64
	set32
	REP	STOSW
	POP	DI;☆

;	cli
  if flg98
	MOV	AX,UBCONSTSEG
  else
	mov	ax,ss
	add	ax,ubconstseg
  endif
	MOV	ES,AX
;	sti
	MOV	SI,SYSPRM+4	;1 と 2 はパス
	set32
	xor	bx,bx
NXP110:
	MOV	CX,ES:[SI]	;PRIME
	JCXZ	NXP150;SIEVE 終了

	set32
	XOR	DX,DX
	set32
	MOV	AX,[DI+2]
	set32
	DIV	CX;NOW eAX=quotient ,eDX=DX=remainder
	MOV	BX,CX
	SHR	BX,1
	set32
	CMP	BX,AX
	JA	NXP150;SIEVE 終了
NXP112:
	SUB	DX,BX
	JBE	NXP118;丁度 CX の倍数の場所
	SUB	DX,CX
NXP118:
	NEG	DX	
NXP120:
	MOV	BX,INPBUF
	ADD	BX,DX;BX=SIEVE 開始位置	
	JC	NXP140;範囲を越えた
	MOV	AL,-1
NXP130:
	CMP	BX,INPBUF+256	;128
	JAE	NXP140;範囲を越えた
	MOV	[BX],AL	
	ADD	BX,CX
	JNC	NXP130
NXP140:
	WINC	SI
	JMP	NXP110	

	;SIEVE 終了
NXP150:
	MOV	AX,SS
	MOV	ES,AX
	MOV	SI,DI
	MOV	DI,INPBUF
	MOV	CX,256;128
	XOR	AX,AX
	REPNE	SCASB
	XCHG	SI,DI
	JNE	NXP170;素数なし

	SUB	SI,INPBUF+1
	ADD	WORD PTR [DI+2],SI
	ADC	WORD PTR [DI+4],0
	JC	NXPSET0;答えが 32 BIT を越えた	
	STC
	RCL	WORD PTR [DI+2],1
	RCL	WORD PTR [DI+4],1
	JC	NXPSET0;答えが 32 BIT を越えた	
	RET

	;SIEVE をその先まで続ける
NXP170:
	ADD	WORD PTR [DI+2],256	;128
	ADC	WORD PTR [DI+4],0
	JC	NXPSET0;答えが 32 BIT を越えた	
	JMP	NXP105

NXPSET0:
	MOV	WORD PTR [DI],0;0 を返す
	RET


;
;☆ＡＳＣＬＥＮの処理
;

ASCLEN:
	CALL	KAKKO
ASCLEN_ENT:
	call	far ptr farASCLENin
	RET

;
;☆ Ａ＾（－１）＠Ｎ
;
;	USE WORK2,3,4

MODINVILG:
	JMP	ILGERR
MODINVSYNERR:
	JMP	SYNERR

MODINV:

	;A,N を得る

	CALL	GET2ARGS

MODINV_ENT:
	CALL	FBACKSP
	PUSH	BP;☆

	;A,N のチェック

	MOV	AX,[DI]
	TEST	AH,attribmaskhigh
	JNZ	MODINVILG;a is not integer

	MOV	CX,[SI]
	TEST	CH,LENMASKHIGHCPL	;11111100b
	JNZ	MODINVILG
	AND	CX,LENMASK	
	JZ	MODINVILG;N=0

	;N を WORK2 へ(最後に答えを標準化するため)

	MOV	DI,WORK2
	INC	CX
	REP	MOVSW

	;WORK3=1

	MOV	SI,WORK3
	MOV	AX,1
	MOV	[SI],AX
	MOV	[SI+2],AX

	;WORK4=0

	MOV	SI,WORK4
	MOV	WORD PTR [SI],0

;	メイン・パート

MODINV10:
	;A=A\N

	MOV	DI,[CALCSP]
	MOV	SI,DI
	SUB	SI,UNITBYTE
	call	idivIIdisi
	MOV	SI,RESADR
	MOV	AX,[SI]
	OR	AX,AX
	JZ	MODINV100;余り=0

	;SWAP X1,X2

	MOV	SI,WORK3
	MOV	DI,WORK4
	MOV	AX,[SI]
	MOV	CX,[DI]
	AND	AX,LENMASK
	AND	CX,LENMASK
	CMP	AX,CX
	JBE	MODINV20
	MOV	CX,AX
MODINV20:
	INC	CX
MODINV25:
	MOV	AX,[DI]
	MOVSW
	MOV	[SI-2],AX
	myloop	MODINV25

	;X2=X2-A*X1
	;(1)A=A*X1

	MOV	DI,[CALCSP]
	MOV	SI,WORK3
	call	mulIIdisi

	;(2)X2=X2-A

	MOV	DI,WORK4
	MOV	SI,[CALCSP]
	CALL	LLSUB

	;A=N

	MOV	DI,[CALCSP]
	MOV	SI,DI
	SUB	SI,UNITBYTE
	PUSH	SI;☆
	copy_si2di

	;N=RES

	MOV	SI,RESADR
	POP	DI;☆
	copy_si2di
	JMP	MODINV10

MODINV100:
	;GCD=1 かチェック

	MOV	SI,[CALCSP]
	SUB	SI,UNITBYTE
	MOV	AX,1
	CMP	AX,[SI]
	JNE	MODINV110
	CMP	AX,[SI+2]
	JNE	MODINV110

	;結果を標準化

	MOV	DI,WORK4
	MOV	SI,WORK2
	call	idivIIdisi

	MOV	SI,RESADR
	MOV	DI,[CALCSP]
	MOV	CX,[SI]
	INC	CX
	REP	MOVSW

MODINVRET:
	POP	BP;☆
	RET

MODINV110:
	MOV	DI,[CALCSP]	;added for v2.2
	MOV	WORD PTR [DI],0	;non error if gcd>1
	JMP	MODINVRET	;return with value 0

;
;☆ Ａ＾Ｂ＠Ｎ
;
MODPSYNERR:
	JMP	SYNERR
MODPOWERROR:
	JMP	ILGERR

modpowfunc?:
	and	ch,lenmaskhighcpl
	cmp	ch,polymaskhigh
	je	go_modpow_poly
	cmp	ch,modpolymaskhigh
	jne	modpowerror
go_modpow_modpoly:
	jmp	far ptr modpow_modpoly
go_modpow_poly:
	jmp	far ptr modpow_poly


farMODPOW_ENT:
	call	MODPOW_ENT
	retf

MODPOW:
	;A を得る

	CALL	FORMUL

	cmp	byte ptr [bp],0c2h	;code of ,
	JNZ	MODPSYNERR

	;B を得る

	INC	BP
	CALL	FORMUL

	cmp	byte ptr [bp],0c2h	;code of ,
	JNZ	MODPSYNERR

	;N を得る

	INC	BP
	CALL	KAKKO

MODPOW_ENT:
	;check B

	mov	si,[calcsp]
	add	si,UNITBYTE
	TEST	BYTE PTR [SI+1],LENMASKHIGHCPL
	JNZ	MODPOWERROR	;not positive integer

	;N を WORK2 にコピー

	MOV	SI,[CALCSP]
	MOV	DI,WORK2
	MOV	CX,[SI]
	TEST	CH,LENMASKHIGHCPL
	JNZ	MODPOWFUNC?	;not positive integer
	JCXZ	MODPOWERROR	;N=0 は不可
	INC	CX
	REP	MOVSW

	PUSH	BP		;☆

	;check A

	MOV	SI,[CALCSP]
	add	si,2*UNITBYTE
	mov	[calcsp],si

	MOV	AX,[SI]
	MOV	CX,AX
	AND	AX,8000H
	MOV	[XSIGN2],AX
	TEST	CH,attribmaskhigh
	JNZ	MODPOWERROR;A is not integer
	AND	CX,lenmask
	MOV	[SI],CX

	;WORK3=A@N

	MOV	DI,RESADR
	MOV	CX,[SI]
	INC	CX
	REP	MOVSW

	CALL	GCDRESwork2

	MOV	SI,RESADR
	MOV	DI,WORK3
	MOV	CX,[SI]
	INC	CX
	REP	MOVSW

	;A = A@N

	MOV	SI,RESADR
	MOV	DI,[CALCSP]
	MOV	CX,[SI]
	INC	CX
	REP	MOVSW

	;MAIN loop

	MOV	SI,[CALCSP]
	SUB	SI,UNITBYTE	;B の位置
	MOV	CX,[SI]
	OR	CX,CX
	JMPZ	MODPOWSET1	;B=0 ならば答えは 1(*に優先)

	MOV	DI,WORK3
	MOV	AX,[DI]
	OR	AX,AX
	JMPZ	MODPOWSET0	;A が 0 ならば答えは 0(*)

	MOV	AL,[SI+2]	;added on 1987,1,15
	AND	AL,1;
	JNZ	MODPOW10	;
	MOV	[XSIGN2],0	;B が even ならば符号は正

MODPOW10:
	;highest word

	ADD	SI,CX
	ADD	SI,CX

	MOV	AX,[SI];highest word
	WDEC	SI

	PUSH	CX
	PUSH	SI

	MOV	CX,16
MODPOW12:
	add	ax,ax
	DEC	CX
	JNC	MODPOW12	;get highest bit
	JCXZ	MODPOW15
MODPOW13:
	PUSH	CX
	PUSH	AX

	MOV	DI,[CALCSP]
	call	squareIdi	;A ^ 2
	MOV	SI,[CALCSP]
	CALL	MODRES

	POP	AX
	add	ax,ax
	PUSH	AX
	JNC	MODPOW14

	MOV	DI,[CALCSP]
	MOV	SI,WORK3
	call	mulIIdisi	;A * original-A
	MOV	SI,[CALCSP]
	CALL	MODRES
MODPOW14:
	POP	AX
	POP	CX
	dec	cx
	jnz	MODPOW13

MODPOW15:
	POP	SI
	POP	CX		;*/
	DEC	CX
	JmpZ	MODPOW90

	;other words
MODPOW20:	
	MY_SHL	CX,4		;bits
	PUSH	CX
	PUSH	SI

	;make A^3@N in 3rd STACK

	MOV	SI,WORK3
	MOV	DI,[CALCSP]
	SUB	DI,UNITBYTE*2
	MOV	CX,[SI]
	INC	CX
	REP	MOVSW

	MOV	DI,[CALCSP]
	SUB	DI,UNITBYTE*2
	call	squareIdi
	MOV	SI,[CALCSP]
	SUB	SI,UNITBYTE*2
	CALL	MODRES

	MOV	DI,[CALCSP]
	SUB	DI,UNITBYTE*2
	MOV	SI,WORK3
	call	mulIIdisi
	MOV	SI,[CALCSP]
	SUB	SI,UNITBYTE*2
	CALL	MODRES

	POP	SI
	POP	CX
	MOV	dx,8000H	;mask
MODPOWLP:
	PUSH	dx
	PUSH	CX
	PUSH	SI

	MOV	DI,[CALCSP]
	call	squareIdi
	MOV	SI,[CALCSP]
	CALL	MODRES

	POP	SI
	POP	CX
	POP	dx
	TEST	[SI],dx		;check current bit
	lahf
	push	ax
	DEC	CX
	SHR	dx,1
	JNZ	MODPOW32
	MOV	dx,8000H
	WDEC	SI
MODPOW32:
	pop	ax
	sahf
	JZ	MODPOW45	;if bit = 0

	TEST	[SI],dx		;check next bit
	lahf
	push	ax
	DEC	CX
	SHR	dx,1
	JNZ	MODPOW34	;
	MOV	dx,8000H
	WDEC	SI
MODPOW34:
	pop	ax
	sahf
	PUSH	dx
	PUSH	CX
	PUSH	SI
	JZ	MODPOW_SR	;if bit = 0

MODPOW_SS:			;pattern is 1 and 1 case
	MOV	DI,[CALCSP]
	call	squareIdi
	MOV	SI,[CALCSP]
	CALL	MODRES

	MOV	DI,[CALCSP]
	LEA	SI,[DI-UNITBYTE*2]
	call	mulIIdisi
	JMPS	MODPOW38

MODPOW_SR:			;patten is 0 and 1 case
	MOV	DI,[CALCSP]
	MOV	SI,WORK3
	call	mulIIdisi
	MOV	SI,[CALCSP]
	CALL	MODRES

	MOV	DI,[CALCSP]
	call	squareIdi
MODPOW38:
	MOV	SI,[CALCSP]
	CALL	MODRES

MODPOW40:
	POP	SI
	POP	CX
	POP	dx
MODPOW45:
	CMP	CX,1
	JBE	MODPOW80
	JMP	MODPOWLP

MODPOW80:
	JB	MODPOW90
	TEST	BYTE PTR [SI],1
	lahf
	push	ax
	MOV	DI,[CALCSP]
	call	squareIdi
	MOV	SI,[CALCSP]
	CALL	MODRES
	pop	ax
	sahf
	JZ	MODPOW90
	MOV	DI,[CALCSP]
	MOV	SI,WORK3
	call	mulIIdisi
	MOV	SI,[CALCSP]
	CALL	MODRES

MODPOW90:
	MOV	SI,[CALCSP]
	MOV	AX,[SI]
	OR	AX,AX
	JZ	MODPOW100
	MOV	AX,[XSIGN2]
	TEST	AH,80H
	JZ	MODPOW100
	OR	[SI],AX		;trans to negative
	MOV	DI,SI
	MOV	SI,WORK2
	call	addIIdisi


MODPOW100:
	POP	BP;☆
	RET

MODPOWSET0:
	MOV	SI,[CALCSP]
	XOR	AX,AX
	MOV	[SI],AX
	JMP	MODPOW100

MODPOWSET1:
	MOV	SI,[CALCSP]
	MOV	AX,1
	MOV	[SI],AX
	MOV	[SI+2],AX
	JMP	MODPOW100

	;[SI]=[SI]@WORK2

MODRES:
	PUSH	SI
	MOV	DI,RESADR
	copy_si2di

	CALL	GCDRESwork2

	POP	DI
	MOV	SI,RESADR
	MOV	CX,[SI]
	INC	CX
	REP	MOVSW
	RET


;
;** randome files
;
	public EXT1IN
EXT1IN:
	MOV	AX,OFFSET HANDLE1
	JMPS	EXT10
EXT2IN:
	MOV	AX,OFFSET HANDLE2
	JMPS	EXT10
EXT3IN:
	MOV	AX,OFFSET HANDLE3
EXT10:
	PUSH	[FILENO]
	MOV	[FILENO],AX
	CALL	EXTSUB1st
	JC	EXTRET;OPTION の場合	
	call	extsub2nd
	MOV	AH,3FH;READ HANDLE
	MOV	DX,SI
	MOV	CX,2
	INT	21H
	JC	EXTERR

	MOV	BX,[FILENO]
	MOV	[FPOINT],-1	;no meaning for ver9
	;must not 0(0 means ascii file)
	MOV	BX,[BX]
	MOV	[FHANDLE],BX
	MOV	AX,[SI]
	MOV	[FATTR],AX
	MOV	[FADR],SI
	CALL	READRECORD
EXTRET:
	POP	[FILENO]
	RET

EXTSUB1st:
	CALL	formul
	XOR	DX,DX;dx:cx = INDEX
	XOR	CX,CX;
	MOV	SI,[CALCSP]
	MOV	AX,[SI]
	OR	AX,AX
	JZ	EXTSUB10
	TEST	AH,80H;INDEX is negative
	JNZ	EXTOPTION?
	MOV	CX,[SI+2]
	DEC	AX
	JZ	EXTSUB10
	MOV	DX,[SI+4]
	DEC	AX
	JNZ	EXTindERR
	EXTSUB10:
	mov	al,[bp]
	inc	bp
	cmp	al,')'
	jne	EXTSUB2dim?
	clc
	ret

EXTSUB2dim?:
	cmp	al,0c2h		;code of ,
	jne	extsynerr
EXTSUB2dim:
	push	cx
	push	dx

	CALL	KAKKO

	XOR	DX,DX		;dx:cx= INDEX
	XOR	CX,CX		;
	MOV	SI,[CALCSP]
	MOV	AX,[SI]
	OR	AX,AX
	JZ	EXTSUB210
	MOV	CX,[SI+2]
	DEC	AX
	JZ	EXTSUB210
	MOV	DX,[SI+4]
	DEC	AX
	JNZ	EXTindERR
EXTSUB210:
	mov	bx,[FILENO]
	cmp	dx,[bx+12]
	ja	extinderr
	jb	extsub215
	cmp	cx,[bx+10]
	ja	extinderr
extsub215:
	mov	di,dx
	mov	si,cx

	;NOW di:si= index2

	pop	dx	;higher
	pop	ax	;lower
	or	dx,dx
	jz	extsub220
	cmp	word ptr [bx+12],0
	jne	extinderr
	mov	bx,[bx+10]
	inc	bx
	jnc	extsub230
	jmp	extinderr
extsub220:
	mov	dx,[bx+12]
	mov	bx,[bx+10]
	add	bx,1
	adc	dx,0
	xchg	ax,bx
extsub230:
	call	mul3216;dx:ax = dx:ax * bx
	jc	extinderr
	add	ax,si
	adc	dx,di
	mov	cx,ax

	mov	si,[calcsp]
	add	si,UNITBYTE
	mov	[calcsp],si
	clc
	ret


EXTNOTOPEN:
	JMP	NOTOPEN
EXTERR:
	JMP	DISKERR
extsynerr:
	jmp	synerr
EXTINDERR:
	JMP	INDEXERR


EXTOPTION?:
	cmp	byte ptr [bp],')'
	jne	extsynerr
	inc	bp
	XOR	DX,DX;higher word of result
	MOV	BX,[FILENO]
	cmp	word ptr [bx],0
	je	extnotopen
	AND	AX,LENMASK
	CMP	AX,1
	JNE	EXTINDERR
	MOV	AX,[SI+2]
	cmp	ax,5
	ja	extinderr
	call	far ptr farextoption
	stc
	ret


EXTSUB2nd:
	;inp dx:cx = index
	;out nothing but move file pointer

	MOV	DI,[FILENO]
	CMP	DX,[DI+4]
	JA	EXTINDERR
	JB	EXTSUB2nd10
	CMP	CX,[DI+2]
	JA	EXTINDERR	;INDEX が大き過ぎる
EXTSUB2nd10:
	MOV	AX,CX
	MOV	BX,[DI+6]	;RECORD SIZE=FULL BYTES
	CALL	MUL3216
	JC	EXTINDERR
	TEST	DH,80H
	JNZ	EXTINDERR
	MOV	CX,DX
	MOV	DX,AX

	;NOW CX:DX=POINTER

	ADD	DX,16		;FCB の分
	ADC	CX,0
	MOV	AH,42H		;MOVE POINTER
	MOV	AL,0
	MOV	BX,[DI]
	OR	BX,BX
	JZ	EXTNOTOPEN
	INT	21H
	JC	EXTERR
	RET


;
;** check EOF
;
EOFIN:
	CALL	KAKKO_AX
	or	ax,ax
	jz	EOF_ILG
	CMP	ax,MAXFILE
	JA	EOF_ILG		;bad FILE NUMBER
	add	ax,ax
	mov	bx,ax
	mov	dx,[bx+ptword]	;ascii/binary flag
	MOV	CX,[BX+EOFFLG]
	MOV	BX,[BX+HANDLE]
	CMP	BH,1
	JNE	EOF_ILG		;not ROPENed

	or	dx,dx
	jz	eofascii

	cmp	cx,-1
	je	eofyes
eofnot:
	xor	ax,ax
eofout:
	mov	si,[calcsp]
	mov	[si],ax
	mov	[si+2],ax
	ret
eofyes:
	mov	ax,1
	jmp	eofout

EOF_ILG:
	JMP	ILGERR

eofascii:
	xor	bh,bh
	mov	dx,offset fnamebuf
	mov	ah,3fh
	mov	cx,1
	int	21h
	jc	eof_ilg
	or	ax,ax
	jz	eofyes
eofrestore:
	mov	dx,ax
	neg	dx
	mov	cx,-1
	mov	ax,4201h	;move file ptr
	int	21h
	jmp	eofnot


;
;☆ 32 BIT 数の EULER 関数
;

EULER:
	CALL	KAKKO
EUL_ENT:
	call	far ptr farEULERin
	ret


;
;☆ 32 BIT 数の MOBIUS 関数
;

MOBIUS:
	CALL	KAKKO
MOB_ENT:
	call	far ptr farMOBIUSin
	ret


;
;☆ 16 BIT の素数
;
PRM_ILG:
	JMP	ILGERR

PRIMEIN:
	CALL	KAKKO

PRM_ENT:
	MOV	SI,[CALCSP]
	MOV	AX,[SI]
	CMP	AX,1
	JA	PRM_ILG;>=2 words is ilg(and other types)
	JB	PRIME1;IF 0
	MOV	DI,[SI+2]
	CMP	DI,6542
	JA	PRIME2W
	SHL	DI,1
	ADD	DI,SYSPRM
  if flg98
	MOV	AX,UBCONSTSEG
  else
	mov	ax,ss
	add	ax,ubconstseg
  endif
	MOV	ES,AX
	MOV	AX,ES:[DI]
	MOV	[SI+2],AX
	MOV	AX,SS
	MOV	ES,AX
	RET

PRIME2W:
	CMP	DI,12251	;10000
	JA	PRM_ILG
	SUB	DI,6543
	SHL	DI,1
	ADD	DI,SYSPRM2W
  if flg98
	MOV	AX,UBCONSTSEG
  else
	mov	ax,ss
	add	ax,ubconstseg
  endif
	MOV	ES,AX
	MOV	WORD PTR [SI],2
	MOV	AX,ES:[DI]
	ROL	AX,1
	MOV	[SI+2],AX
	MOV	WORD PTR [SI+4],1
	MOV	AX,SS
	MOV	ES,AX
	RET


PRIME1:
	MOV	AX,1
	MOV	[SI],AX
	MOV	[SI+2],AX
	RET


;
;☆  Extended Kronecker symbol ('HL','DE')
;

farKRO_ENT:
	call	KRO_ENT
	retf


kro_synerr:
	jmp	synerr
KRO_ILG:
	JMP	ILGERR

KROIN:	
	CALL	FORMUL		; get 1st param
	cmp	byte ptr [bp],0c2h	;code of ,
	jne	kro_synerr
	INC	BP
	CALL	KAKKO		; get 2nd param

;* KRO MAIN ROUTINE

KRO_ENT:
	CALL	BACKSP
	MOV	AX,[DI]
	OR	AX,[SI]
	TEST	AH,attribmaskhigh
	JNZ	KRO_ILG		;整数以外はダメ
	PUSH	BP
	CALL	GETKRO
	POP	BP

;  set KRO in (CALCSP)

	MOV	BX,[CALCSP]
	MOV	AX,[KROWRK]
	MOV	[BX],AX
	XOR	AH,AH
	MOV	[BX+2],AX
	RET	

; ** MAIN SUBROUTINE

;   calculate KRO of (SI) and (DI)
;   and set KRO in (KROWRK)

GOSETK0:
	JMP	SETK0

GETKRO:	
	XOR	AX,AX
	CMP	AX,[DI]
	JE	GOSETK0;if 'DI'=0
	CMP	AX,[SI]
	JE	GOSETK0;if 'SI'=0

	MOV	[SIMEM_K],SI
	MOV	[DIMEM_K],DI

	MOV	AX,[DI+2]
	OR	AX,[SI+2]
	TEST	AL,1
	JZ	GOSETK0;共に偶数の時

	MOV	[KROWRK],1	;初期値

	;'DI','SI' の符号の考慮

	MOV	AX,[DI]
	TEST	AH,80H
	JZ	KROPOS;分子が正

	MOV	AX,[SI]
	TEST	AH,80H
	JZ	KROLPA;分母が正

	AND	WORD PTR [SI],LENMASK
	MOV	[KROWRK],8001H	;-1

KROLPA:	
	MOV	AX,[SI+2]
	TEST	AL,1
	JNZ	KROJPB;if 'SI' odd
	MOV	AX,[DI+2]
	AND	AL,7
	CMP	AL,7
	JE	KROJPC;if -'DI'=7@8
	CMP	AL,3
	JMPNZ	ILGERR;illegal

	XOR	BYTE PTR [KROWRK+1],80H	;change sign
KROJPC:	
	CALL	SHR_SI
	MOV	SI,[SIMEM_K]
	MOV	DI,[DIMEM_K]
	JMP	KROLPA
KROJPB:	
	MOV	AX,[SI+2]
	AND	AL,3
	CMP	AL,1
	JE	KROPOS
	XOR	BYTE PTR [KROWRK+1],80H	;change sign

	;'DI','SI' の絶対値を RESADR と WORK2 にコピー

KROPOS:	
	MOV	SI,[SIMEM_K]
	MOV	DI,WORK2
	MOV	CX,[SI]
	AND	CX,LENMASK
	MOV	[DI],CX
	WINC	SI
	WINC	DI
	REP	MOVSW

	MOV	SI,[DIMEM_K]
	MOV	DI,RESADR
	MOV	CX,[SI]
	AND	CX,LENMASK
	MOV	[DI],CX
	WINC	SI
	WINC	DI
	REP	MOVSW

	;これからは 'DI','SI' は正としてよい

	MOV	SI,RESADR+2
	MOV	DI,WORK2+2

	MOV	AX,[DI]
	TEST	AL,1
	JNZ	KROJP3;if 'DI' odd

	MOV	AX,[SI]
	TEST	AL,1
	JNZ	KROJP1;if 'SI' odd

SETK0:	
	MOV	[KROWRK],0
	RET	

	;ＭＡＩＮ・ＬＯＯＰ

KROLP1:	
	MOV	SI,RESADR+2
	MOV	DI,WORK2+2

	;N の 2 因子の処理

	MOV	AX,[DI]
	TEST	AL,1
	JNZ	KROJP3;if N odd
KROJP1:	
	MOV	AX,[SI]
	AND	AL,7;A=[SI]@8
	CMP	AL,1;
	JE	KROJP2;if =1
	CMP	AL,5
	JMPNZ	ILGERR;illegal

	XOR	BYTE PTR [KROWRK+1],80H	;if =5 then change sgn
KROJP2:	
	LEA	SI,[DI-2]
	CALL	SHR_SI;N=N/2
	JMP	KROLP1

	;これで N は奇数
	;N=1 ならば終了
KROJP3:	
	MOV	AX,[DI-2]
	CMP	AX,1
	JNE	KROJP5
	MOV	AX,[DI]
	CMP	AX,1
	RETZ

	;GCD>1 ならば終了
KROJP5:	
	CALL	GCDRESwork2
	MOV	SI,RESADR+2
	MOV	DI,WORK2+2
	MOV	AX,[SI-2]
	OR	AX,AX
	JZ	SETK0;割り切れた場合

	;M の 2 因子の処理
KROLP2:	
	MOV	AX,[SI]
	TEST	AL,1
	JNZ	KROLP3;if 'SI' odd

	MOV	AX,[DI]
	AND	AL,7
	CMP	AL,1
	JE	KROJP4;if 'DI'=1@8
	CMP	AL,7
	JE	KROJP4;if 'DI'=7@8
	XOR	BYTE PTR [KROWRK+1],80H	;change sign
KROJP4:	
	WDEC	SI
	CALL	SHR_SI
	MOV	SI,RESADR+2
	MOV	DI,WORK2+2
	JMP	KROLP2

	;M も N も奇数
	;M が 1 ならば終了
KROLP3:	
	MOV	AX,[SI]
	CMP	AX,1
	JNE	KROJP6;if 1st word<>1
	MOV	AX,[SI-2]
	CMP	AX,1
	RETZ	;if len=1

	;相互律の適用
KROJP6:	
	MOV	AX,[SI]
	AND	AL,3
	CMP	AL,1
	JE	KROJP7;if 'SI'=1 mod 4
	MOV	AX,[DI]
	AND	AL,3
	CMP	AL,1
	JE	KROJP7;if 'DI'=1 mod 4
	XOR	BYTE PTR [KROWRK+1],80H	;change sign

	;値の交換
KROJP7:
	WDEC	SI
	WDEC	DI
	MOV	CX,[SI]
	MOV	AX,[DI]
	CMP	CX,AX
	JAE	KRO100
	MOV	CX,AX
KRO100:
	INC	CX
KRO110:
	MOV	AX,[DI]
	MOVSW
	MOV	[SI-2],AX
	myloop	KRO110

	JMP	KROLP1


;
;☆NEWTON法で dx:ax の平方根を求める
; INPUT  dx:AX
; OUTPUT AX=INT(SQR(AX))
; DESTROY BX,CX,DX,DI,si

dwordsqrt:
	cmp	dx,0fffeh
	ja	worsqrffff
	jb	worsqr10
	cmp	ax,1
	jb	worsqrfffe
worsqrffff:
	mov	ax,0ffffh
	ret
worsqrfffe:
	mov	ax,0fffeh
	ret

worsqr10:
	mov	di,dx
	mov	si,ax

	mov	cx,32
	or	dx,dx
	jnz	worsqr20
	mov	cx,16
	mov	dx,ax
worsqr20:
	or	dh,dh
	jnz	worsqr30
	sub	cx,8
	mov	dh,dl
worsqr30:
	dec	cx
	shl	dh,1
	jnc	worsqr30

	shr	cx,1
	inc	cx
	mov	ax,1
	shl	ax,cl
	dec	ax;initial value

	;ax = initial value, di:si = argumaent
worsqrlp:
	mov	bx,ax
	mov	dx,di
	mov	ax,si
	div	bx
	add	ax,bx
	rcr	ax,1
	cmp	ax,bx
	jb	worsqrlp
	mov	ax,bx
	ret

;
;☆平方根を求める(NEWTON 法の SUBROUTINE)
;  引数は整数に限る(小数は適当にSLIDEして計算せよ)
;

SQRMAIN:
	;まず 1/4 の長さ分だけ計算

	MOV	SI,[CALCSP]
	MOV	CX,[SI]
	MOV	BX,CX
	CMP	CX,8
	JBE	SQRMAIN100	;8 WORDS 以下は手間の無駄
	MY_SHR	CX,2
	MOV	AX,BX
	SUB	AX,CX		;下位WORDS の長さ
	TEST	AX,1
	JZ	SQRMAIN10
	DEC	AX		;AX は偶数でなければならない
	INC	CX
SQRMAIN10:
	SHR	AX,1
	MOV	[SLIDELENGTH],AX	;右 SLIDE WORD 数
	SUB	BX,CX
	MOV	[CUTLENGTH],BX		;下位のカット量

	;引数の下位をカットして WORK4 へ

	MOV	SI,[CALCSP]
	MOV	CX,[SI]
	MOV	AX,[CUTLENGTH]
	SUB	CX,AX
	INC	AX
	ADD	SI,AX
	ADD	SI,AX;COPY すべき最下位
	MOV	DI,WORK4
	MOV	[DI],CX
	WINC	DI
	REP	MOVSW

	MOV	[VAR_A],WORK4
	CALL	SQRSUB

	;結果をSLIDEし下位を補充

	mov	si,[VAR_X]
	mov	cx,[si]		;word length
	add	si,cx
	add	si,cx		;old highest word adr
	mov	dx,[SLIDELENGTH]
	mov	di,si
	add	di,dx
	add	di,dx		;new highest word adr
	std
	rep	movsw
	mov	cx,dx
	mov	ax,0ffffh
	rep	stosw
	add	[di],dx		;new word length
	cld

	;本ルーチン

	MOV	SI,[CALCSP]
	MOV	[VAR_A],SI
	JMP	SQRSUB30	;CALL & RET

SQRMAIN100:
	MOV	SI,[CALCSP]
	MOV	[VAR_A],SI
;	JMP	SQRSUB		;CALL & RET


SQRSUB:
	;compute rough estimate of square root
	;conditions are
	; (1) ((answer+1)*base^n)^2 > a
	; (2) answer is correct when the length = 1,2
	;answer is in [var_x]

	MOV	[VAR_X],WORK2
	MOV	[VAR_Y],WORK3

	MOV	SI,[VAR_A]
	MOV	BX,[SI]
	cmp	bx,1
	jne	sqrsub2
	add	bx,bx
	xor	dx,dx
	mov	ax,[bx+si]
	call	dwordsqrt
	xor	cx,cx
	or	ax,ax
	jz	sqrsub1
sqrsub0:
	inc	cx
sqrsub1:
	mov	si,[var_x]
	mov	[si],cx
	mov	[si+2],ax
	jmps	sqrsubret

sqrsub2:
	add	bx,bx
	mov	ax,[bx+si-2]
	mov	dx,[bx+si]
	push	si
	call	dwordsqrt
	pop	si

	MOV	CX,[SI]
	MOV	DI,WORK2+2	;LOWEST ADR
	sub	cx,2
	jz	sqrsub0		;if 2 words

	MOV	BX,AX		;MEMO

	mov	al,0ffh
	rep	stosb
	mov	ax,bx
	stosw
	TEST	DI,1
	JZ	SQRSUB10	;偶数番地ならば良し
	OR	AH,AH
	JZ	SQRSUB10	;上位BYTE=0なら良し
	XOR	AL,AL;clear higher byte
	STOSB
SQRSUB10:	
	MOV	BX,WORK2
	SUB	DI,BX
	SHR	DI,1
	DEC	DI;DI=NEW WORDS
	MOV	[BX],DI

	;ここからNEWTON法スタート
	;初期値は真の答え以上でなければならない

SQRSUB30:
	;次の近似値を [VAR_Y] に作る

	  ;1) 引数を [VAR_Y] に COPY

	MOV	SI,[VAR_A]
	MOV	DI,[VAR_Y]
	MOV	CX,[SI]
	INC	CX
	REP	MOVSW

	  ;2) [VAR_X] で割る

	MOV	DI,[VAR_Y]
	MOV	SI,[VAR_X]
	call	idivIIdisi	;//

	  ;3) [VAR_X] を加える

	MOV	DI,[VAR_Y]
	MOV	SI,[VAR_X]
	call	addIIdisi

	  ;4) [VAR_Y] を 1/2 に

	MOV	SI,[VAR_Y]
	CALL	SHR_SI

	  ;5) [VAR_Y]>=[VAR_X] なら [VAR_X] が答
	  ;   初期値>=SQR(A) としているからこれで良い

	MOV	DI,[VAR_Y]
	MOV	SI,[VAR_X]
	CALL	COMPDISI
	JNC	SQRSUBRET
	
	  ;6) 終了でなければ [VAR_Y] と [VAR_X] を交換

	MOV	AX,[VAR_Y]
	XCHG	AX,[VAR_X]
	MOV	[VAR_Y],AX
	JMP	SQRSUB30

SQRSUBRET:
	RET


SQROVR:
	JMP	OVRERR



;
; 整数平方根
; 小数も整数化してから計算
;
isqrt_rational:
	checkcalcsp	1
	cmoveimag	1,0
	cmovereal	0,0
	cidiv		0,1
	mov	si,[calcsp]
	mov	ax,[si]
	or	ax,ax
	jz	isqrret0
	jmp	isqrt100

isqrtilg:
	jmp	ilgerr

isqrtnoninteger:
	test	ch,nonposrealmaskhigh
	jnz	isqrtilg
	test	ch,ratmaskhigh
	jnz	isqrt_rational
isqrt_real:	
	;first transfer real -> integer

	mov	dx,[si+2]	;bias
	or	dx,dx		;check bias
	jle	isqrret0	;if < 1.0

	and	cx,lenmask
	mov	word ptr [si+2],0
	shl	cx,1		;current byte length(includes bias)
	mov	ax,dx
	inc	ax
	shr	ax,1
	mov	[si],ax		;set new attribute

	sub	cx,dx
	jb	short isqrt_up
isqrt_dwn:
	add	si,2
	mov	di,si
	add	si,cx
	mov	cx,dx
	rep	movsb
	mov	[di],cl		;set one more 0
	jmps	isqrt100

isqrt_up:
	add	cx,dx
	add	si,cx
	inc	si		;old highest byte adr
	mov	di,si
	sub	dx,cx	
	add	di,dx		;new highest byte adr
	std
	xor	ax,ax
	mov	[di+1],al	;set one more 0
	rep	movsb
	mov	cx,dx
	rep	stosb		;fill lower by 0
	cld
	jmps	isqrt100


ISQRRET0:
	MOV	DI,[CALCSP]
	MOV	WORD PTR [DI],0
	MOV	DI,RESADR
	MOV	WORD PTR [DI],0
	RET

ISQRTIN:
	CALL	KAKKO
Isqrt_ENT:
	MOV	SI,[CALCSP]
	MOV	CX,[SI]
	JCXZ	ISQRRET0	;引数がゼロ
	test	ch,lenmaskhighcpl
	jnz	ISQRTnoninteger

ISQRT100:
	CALL	SQRMAIN		;[VAR_X]=ISQR(A)

	;A を RESADR に COPY

	MOV	SI,[CALCSP]
	MOV	DI,RESADR
	MOV	CX,[SI]
	INC	CX
	REP	MOVSW

	;[VAR_X] を [CALCSP] に COPY

	MOV	SI,[VAR_X]
	MOV	DI,[CALCSP]
	MOV	CX,[SI]
	INC	CX
	REP	MOVSW

	;A-ISQR(A)^2 を RESADR に作る

	MOV	DI,[VAR_X]
	CALL	POWER2IN2

	MOV	DI,RESADR
	MOV	SI,[VAR_X]
	CALL	LLSUB

	RET

;

ISQRSUBTRACT:

	MOV	DI,[CALCSP]
	MOV	CX,[DI]
	MOV	SI,RESADR
	MOV	BX,[SI]
	SUB	BX,CX;RESADR>=CALCSP のはず
	CLC
SQSUB10:
	WINC	SI
	WINC	DI
	MOV	AX,[SI]
	SBB	[DI],AX
	myloop	SQSUB10
	JNC	SQSUB50
	MOV	CX,BX
	JCXZ	SQSUB30
SQSUB20:
	WINC	DI
	SUB	WORD PTR [DI],1
	JNC	SQSUB50
	myloop	SQSUB20
SQSUB30:
	JMP	SYSTEMERR	

	;[RESADR] の長さの計算
SQSUB50:
	MOV	SI,RESADR
	MOV	CX,[SI]
	MOV	DI,SI
	ADD	DI,CX
	ADD	DI,CX
SQSUB60:
	CMP	WORD PTR [DI],0
	JNE	SQSUB70
	WDEC	DI
	myloop	SQSUB60
SQSUB70:
	SUB	DI,RESADR
	SHR	DI,1
	MOV	[SI],DI
	RET

;
;[SI] を 1BIT 右シフトする
;

SHR_SI	PROC

	MOV	CX,[SI]
	JCXZ	SHR_SI20

	ADD	SI,CX
	ADD	SI,CX
	MOV	DI,SI;最上位
	CLC
SHR_SI10:
	RCR	WORD PTR [SI],1
	WDEC	SI
	myloop	SHR_SI10
	CMP	WORD PTR [DI],0	
	JNE	SHR_SI20
	DEC	WORD PTR [SI]	;最上位が 0 になれば長さを減らす
SHR_SI20:
	RET

SHR_SI	ENDP

;
;☆ＧＣＤの処理
;  (最大公約数を求める)

go_gcd_poly1:
	cmp	ah,polymaskhigh
	je	gogcdpoly10
	mov	bx,si
	call	far ptr farnumer2poly
gogcdpoly10:
	jmp	far ptr gcd_poly

go_gcd_modpoly1:
	cmp	ah,modpolymaskhigh
	je	gogcdmodpoly10
	mov	bx,si
	call	far ptr farint2modpoly
gogcdmodpoly10:
	jmp	far ptr gcd_modpoly

go_gcd_poly2:
	mov	bx,di
	call	far ptr farnumer2poly
	jmp	far ptr gcd_poly
go_gcd_modpoly2:
	mov	bx,di
	call	far ptr farint2modpoly
	jmp	far ptr gcd_modpoly

gcd_etc:
	cmp	al,polymaskhigh
	je	go_gcd_poly1;[di] is poly
	cmp	al,modpolymaskhigh
	je	go_gcd_modpoly1;[di] is modpoly
	cmp	ah,polymaskhigh
	je	go_gcd_poly2;[si] is poly
	cmp	ah,modpolymaskhigh
	je	go_gcd_modpoly2;[si] is modpoly
GCD_ILG:
	jmp	ilgerr



GCDIN:	
	call	formul
gcdlp:
	cmp	byte ptr [bp],0c2h	;code of ,
	jne	gcdsynerr
	inc	bp
	call	formul
	call	gcd_ent
	cmp	byte ptr [bp],')'
	jne	gcdlp
	inc	bp
	ret
gcdsynerr:
	jmp	synerr


fargcd_calcsp:
	mov	di,[calcsp]
	lea	si,[di-unitbyte]
	call	gcd_nobacksp
	retf


GCD_ENT:
	CALL	FBACKSP

	;* GCD MAIN ROUTINE

gcd_nobacksp:
	mov	al,[di+1]
	mov	ah,[si+1]
	and	ax,attribmaskdouble
	jnz	gcd_etc

	CALL	GETGCD;if both integer

	;  set GCD in (CALCSP)

	MOV	SI,work3	;GCDADR
	MOV	DI,[CALCSP]

	MOV	CX,[SI]
	INC	CX
	REP	MOVSW
	RET	


; ** MAIN SUBROUTINE

;	[DI],[SI] の ＧＣＤ を計算して
;	[work3	;GCDADR] に返す

; use mulwork for work area

	;割られる数の絶対値を RESADR へ

farGETGCD:
	call	GETGCD
	retf


GETGCD:	
	PUSH	BP

	PUSH	DI
	MOV	DI,RESADR
	MOV	CX,[SI]
	AND	CX,LENMASK
	JZ	GCDDI;if [SI]=0 then GCD=[DI]

	MOV	[DI],CX
	WINC	SI
	WINC	DI
	REP	MOVSW

	;割る数の絶対値を mulwork へ

	POP	SI
	MOV	DI,mulwork
	MOV	CX,[SI]
	AND	CX,LENMASK
	JZ	FINDGCD;if [DI]=0 then GCD=[SI]
;[SI] は RESADR にある
	MOV	[DI],CX
	WINC	SI
	WINC	DI
	REP	MOVSW
	JMPS	GCDJP0

;  * GCD MAIN loop

GCDMLP:	
	MOV	DI,mulwork
	MOV	AX,[DI]
	AND	AX,LENMASK
	JZ	FINDGCD;if 'B'=0

GCDJP0:	
	mov	si,mulwork
	CALL	GCDRESsi

	;  swap 'A'(RESADR) & 'B'(mulwork)

	MOV	SI,RESADR
	MOV	DI,mulwork
	MOV	CX,[SI]
	CMP	CX,[DI]
	JA	GCDSWJ
	je	gcdrecalib
	MOV	CX,[DI]
GCDSWJ:	
	INC	CX;max len
GCDSWL:	
	MOV	AX,[DI]
	XCHG	AX,[SI]
	STOSW
	WINC	SI
	myloop	GCDSWL
	JMP	GCDMLP

gcdrecalib:
	mov	dx,cx;memo for *
	mov	bx,cx
	shl	bx,1
	mov	ax,[bx+si]
	add	ax,ax
	jc	gcdrecalib10
	cmp	ax,[bx+di]
	jbe	gcdswj	
gcdrecalib10:
	add	si,2
	add	di,2
;	clc
gcdrecaliblp:	;change A to B-A and xchg A,B
	lodsw
	mov	bx,[di]
	mov	[si-2],bx
	xchg	ax,bx
	sbb	ax,bx
	stosw
	myloop	gcdrecaliblp

	sub	di,2
	mov	cx,dx;*
	xor	ax,ax
	std
	repe	scasw
	cld
	inc	cx;no case of A-B=0
	mov	di,mulwork
	mov	[di],cx
	JMP	GCDMLP


	; *  set result in RESADR if (SI) is zero

GCDDI:
	POP	SI
	MOV	DI,work3	;GCDADR
	MOV	CX,[SI]
	AND	CX,LENMASK
	MOV	[DI],CX
	WINC	SI
	WINC	DI
	REP	MOVSW
	JMPS	GETGCD_RET


FINDGCD:
	MOV	SI,RESADR
	MOV	DI,work3	;GCDADR
	MOV	CX,[SI]
	INC	CX
	REP	MOVSW
GETGCD_RET:
	POP	BP
	RET


; * SUBROUTINES


;
;☆ＡＢＳの処理
; 計算スタック内の値をその絶対値に変える
;
	;if Re=0 then abs=abs(Im)
complexabs_im:
	lea	si,[bx+4]
	mov	di,bx
	lodsw
	and	ah,7fh;cut sign
	stosw
	and	ah,lenmaskhigh
	mov	cx,ax
	rep	movsw
	ret


abs_rational:
	add	bx,2;attrib of num.
	jmps	abs_out

absin:
	call	kakko
abs_ent:
	mov	bx,[calcsp]
	mov	ax,[bx]
	mov	ch,ah
 	and	ch,attribmaskhigh
	jnz	abs_extra
abs_out:
	and	byte ptr [bx+1],7fh
	ret
abs_extra:
	cmp	ch,complexmaskhigh
	je	complexabs
	cmp	ch,pointmaskhigh
	je	abs_out
	cmp	ch,ratmaskhigh
	je	abs_rational
	jmp	ilgerr

complexabs:
	mov	ax,[bx+2]	;attrib of real part
	or	ax,ax
	jz	complexabs_im

	cmoveimag3	work2,0	;imag part of stack0 -> work2
	cmovereal	0,0	;real part of stack0 -> stack0

	;real part -> float

	mov	bx,[calcsp]
	mov	ax,[bx]
	test	ax,pointmask
	jz	cabs40
	and	ax,lenmask
	dec	ax
	cmp	ax,[pointword]
	je	cabs50
	mov	di,bx
	call	justlengthFdi
	jmps	cabs50
cabs40:
	call	int2floatbxcurrent

	;imag part -> float
cabs50:
	mov	bx,work2
	mov	ax,[bx]
	test	ax,pointmask
	jz	cabs60
	and	ax,lenmask
	dec	ax
	cmp	ax,[pointword]
	je	cabs_ff
	mov	di,bx
	call	justlengthFdi
	jmps	cabs_ff
cabs60:
	call	int2floatbxcurrent

cabs_ff:
	mov	di,[calcsp]
	mov	si,work2
	mov	ax,[di+2]	;bias
	mov	bx,[si+2]	;
	mov	cx,[pointword]
	add	cx,cx
	cmp	ax,bx
	jl	cabs10
	sub	ax,cx
	mov	[di+2],cx
	sub	[si+2],ax
	push	ax;/*
	jmps	cabs20
cabs10:
	sub	bx,cx
	mov	[si+2],cx
	sub	[di+2],bx
	push	bx;/*
cabs20:
	mov	bx,[calcsp]
	call	float2intbx
	mov	di,[calcsp]
	call	squareIdi

	mov	bx,work2
	call	float2intbx
	mov	di,work2
	call	squareIdi

	mov	di,[calcsp]
	mov	si,work2
	call	addIIdisi

	call	isqrt_ent

	mov	bx,[calcsp]
	call	int2floatbxcurrent
	mov	di,[calcsp]
	pop	ax;*/
	add	[di+2],ax	;new bias
cabs_ffret:
	ret


;
;☆ＳＩＧＮの処理
;  計算スタック内の値の符号(＋－０)を返す
;
SGNIN:	
	CALL	KAKKO
SGN_ENT:
	MOV	BX,[CALCSP]
	MOV	AX,[BX]
	OR	AX,AX
	JZ	SGN_RET;0 の場合
	mov	ch,ah
	and	ch,attribmaskhigh
	jnz	sgn_extra
sgn_out:
	mov	al,1
	and	ah,80h
	mov	[bx],ax
	xor	ah,ah
	mov	[bx+2],ax	;1
sgn_ret:
	ret
sgn_extra:
	cmp	ch,pointmaskhigh
	je	sgn_out
	cmp	ch,ratmaskhigh
	je	sgn_rational
	jmp	ilgerr
sgn_rational:
	mov	ax,[bx+2]	;attrib of num.
	jmp	sgn_out
	

;
;☆ＬＥＮの処理
;  計算スタック内の値の BIT 数を返す
;  ( 1 ワードに収まる物のみなので 65536/16=4096 ワードまで)

lenpack:	;number of data in packed data
	mov	ax,[bx+2]
	or	ax,ax
	jz	lenpack10
	mov	ax,1
lenpack10:
	mov	[bx],ax
	ret

LENIN:
	CALL	KAKKO
LEN_ENT:
	MOV	BX,[CALCSP]
	MOV	CX,[BX]
	mov	al,ch
	and	al,attribmaskhigh
	jz	leninteger
	cmp	al,packmaskhigh
	je	lenpack
	cmp	al,stringmaskhigh
	je	lenstring
	cmp	al,polymaskhigh
	je	lenpack
	cmp	al,modpolymaskhigh
	je	lenmodpoly
	jmp	ilgerr
leninteger:
	AND	CX,LENMASK
	JZ	LENRET
	SHL	CX,1
	ADD	BX,CX;BX=最高位ワード
	MY_SHL	CX,3;CX=ワード数*16
	MOV	AX,[BX];最高位ワードの値
	INC	CX
LENLP:
	DEC	CX
	add	ax,ax
	JNC	LENLP
	MOV	BX,[CALCSP]
	MOV	WORD PTR [BX],1
	MOV	[BX+2],CX
LENRET:
	RET	

lenstring:
	shl	cx,1
	sbb	cx,0
	and	cx,2*lenmask+1
	jz	lenstring10
	mov	[bx+2],cx
	mov	cx,1
lenstring10:
	mov	[bx],cx
	ret

lenmodpoly:
	and	cx,lenmask
;	jz	lenmodpoly10	;no case
	shr	cx,1
	dec	cx
	mov	word ptr [bx],1
	add	bx,2
lenmodpoly10:
	mov	[bx],cx
	ret


;
;☆ＢＩＴの処理
;  計算スタック内の値の指定された BIT のセット状況を返す

bitilg:
	jmp	ilgerr

BITIN:	
	;第一パラメータ(BIT位置の指定)を得る

	CALL	FORMUL
	cmp	byte ptr [bp],0c2h	;code of ,
	JMPNZ	SYNERR

	;第二パラメータ(調べる数値)を得る

	INC	BP
	CALL	KAKKO
BIT_ENT:
	CALL	BACKSP

	;now [DI]=param1,[SI]=param2

	MOV	DX,[SI]
	test	dh,attribmaskhigh
	jnz	bitilg;not integer
	AND	DX,LENMASK
	JZ	RESBIT;調べる数値が 0

	MOV	AX,[DI]
	test	ah,attribmaskhigh
	jnz	bitilg
;	AND	AX,LENMASK
	CMP	AX,1
	JA	RESBIT;BIT 位置>65535
	JB	BIT10;IF 0
	MOV	AX,[DI+2]
BIT10:
	MOV	CX,AX
	MY_SHR	AX,4
	INC	AX
	AND	CX,000FH

	;以下 AX ワード目の CX ビットを調べればよい

	CMP	AX,DX
	JA	RESBIT
	add	ax,ax
	ADD	SI,AX
	MOV	AX,[SI];調べるべきワード
	INC	CX
	SHR	AX,CL	
	JNC	RESBIT

SETBIT:	
	MOV	AX,1
	STOSW
	STOSW
	RET	

RESBIT:	
	XOR	AX,AX
	STOSW
	RET	


;
;  set EULER CONSTANT
;
eulerconst:
	CALL	AHEDSP
	mov	[sysconstmore],0
	MOV	DI,SI
	MOV	SI,syseuler
	mov	word ptr es:[di+2],0	;bias
	jmps	sysconstin

;
;  set EXP(1)
;
	even
sysconstmore	dw	?

EXP1:
	CALL	AHEDSP
getexp1:
	mov	[sysconstmore],0
	MOV	DI,SI
	MOV	SI,SYSEXP+1
	mov	word ptr es:[di+2],1	;bias = 1

sysconstin:
  if flg98
	MOV	AX,UBCONSTSEG
  else
	mov	ax,ss
	add	ax,ubconstseg
  endif
	MOV	DS,AX
	MOV	BX,550	;1200
	MOV	CX,SS:[POINTWORD]
	add	cx,[sysconstmore]
	SUB	BX,CX
	SHL	BX,1
	ADD	SI,BX
	INC	CX
	MOV	AX,CX
	OR	AH,POINTMASKHIGH
	MOV	ES:[DI],AX;len
	add	di,4
	dec	cx
	REP	MOVSW
	MOV	AX,SS
	MOV	DS,AX
	RET


;
;  complex exp(x) 
;
compexpCALCSPERR:
	JMP	CALCSPERR
cexpilgerr:
	jmp	ilgerr

cexpin:
	call	kakko
cexp_ent:
	mov	si,[calcsp]
	mov	al,[si+1]
	test	al,nonnumericmaskhigh
	jnz	cexpilgerr
	test	al,complexmaskhigh
	jnz	gocomplex_exp
	jmp	real_exp
gocomplex_exp:
	jmp	complex_exp


;
;* set pi
;
multipiilgerr:
	jmp	ilgerr
multipicalcsperr:
	jmp	calcsperr

multipi:
	call	kakko
	call	ahedsp
	call	pai10;get more precise pi
	jmp	mulin;call & ret

	; normal pi

pai_ent:
	mov	si,[calcsp]
	jmps	pai10

paiin:
	call	ahedsp
pai10:
	mov	[sysconstmore],0
pai10in:
	mov	di,si
	mov	si,syspi+1
	mov	word ptr es:[di+2],1	;bias
	jmp	sysconstin;call & ret


getlog2:
	mov	[sysconstmore],0
getlog2in:
	mov	di,si
	mov	si,syslog2
	mov	word ptr es:[di+2],0	;bias
	jmp	sysconstin

pai10longer:
	mov	[sysconstmore],1
	jmp	pai10in

getlog2longer:
	mov	[sysconstmore],1
	jmp	getlog2in


;
;☆２つの引数を計算スタックに得る
;
;	return with
;	DI=top of 1st:SI= top of 2nd
;	BP set new

GET2ARGS:
	CALL	FORMUL
	cmp	byte ptr [bp],0c2h	;code of ,
	JNZ	GET2ARGERR	;引数が1個のみ

	;Y を得る

	INC	BP
	JMP	KAKKO;CALL & RET

GET2ARGERR:
	JMP	SYNERR


FBACKSP:
	;CALCSP の更新

	MOV	SI,[CALCSP]	;[SI]=Y
	MOV	DI,SI
	ADD	DI,UNITBYTE
	MOV	[CALCSP],DI	;[DI]=X
	RET


	;COMPARE [DI],[SI]
	;  in:[DI],[SI] must be nonnegative integers
	;  out:ZF=1 iff [DI]=[SI]
	;      CF=1 iff [DI]<[SI]
COMPDISI:
	MOV	CX,[DI]
	CMP	CX,[SI]
	JA	COMP20;長さが違って引ける場合
	JB	COMP30;長さが違って引けない場合
COMP5:
	ADD	SI,CX
	ADD	DI,CX
	ADD	SI,CX
	ADD	DI,CX
COMP10:
	MOV	AX,[DI]
	CMP	AX,[SI]
	JA	COMP20
	JB	COMP30
	WDEC	DI
	WDEC	SI
	myloop	COMP10
	CMP	AX,AX;SET ZF
COMP20:
	CLC
	RET
COMP30:
	STC
	RET


CODE	ENDS

code2	segment	public
	assume	cs:code2,ds:data

	extrn	modpow_modpoly:far,modpow_poly:far
	extrn	gcd_modpoly:far,gcd_poly:far
	extrn	farint2modpoly:far
	extrn	farnumer2poly:far

;
;☆ＡＳＣＬＥＮの処理
;

ASCLDIV:	
	MOV	CX,[DI]
	ADD	DI,CX
	ADD	DI,CX
	MOV	SI,DI;SI=DI=最高位ワード
	STD
	XOR	DX,DX
ASCLDIV10:
	MOV	AX,[DI]
	DIV	BP
	STOSW
	myloop	ASCLDIV10	
	CLD
	CMP	[SI],CX;CX=0
	JNE	ASCLDIV20
	DEC	WORD PTR [DI]	;最高位が 0 になったので長さを減らす
ASCLDIV20:
	RET

asclilgerr:
	jmp	far ptr ilgerr
	

farASCLENin:
	PUSH	BP
	MOV	[ASCLMEM],1

	MOV	DI,[CALCSP]
	MOV	AX,[DI]
	mov	ch,ah
	and	ch,attribmaskhigh
	jz	ascl5;if integer
	cmp	ch,POINTMASKHIGH
	jne	asclilgerr
	mov	bx,di
	call	far ptr farfloat2intbx
	MOV	DI,[CALCSP]
	MOV	AX,[DI]	
ASCL5:
	AND	AX,LENMASK
	JZ	ASCLRET
	MOV	[DI],AX;正に
ASCL10:
	MOV	DI,[CALCSP]
	MOV	AX,[DI]
	CMP	AX,1
	JE	ASCL20
	MOV	BP,10000
	CALL	ASCLDIV
	ADD	[ASCLMEM],4
	JMP	ASCL10
ASCL20:
	MOV	AX,[DI+2]
	MOV	CX,4
	CMP	AX,10000
	JAE	ASCL30
	DEC	CX
	CMP	AX,1000
	JAE	ASCL30
	DEC	CX
	CMP	AX,100
	JAE	ASCL30
	DEC	CX
	CMP	AX,10
	JAE	ASCL30
	DEC	CX
ASCL30:
	ADD	[ASCLMEM],CX
ASCLRET:
	MOV	DI,[CALCSP]
	MOV	AX,1
	STOSW
	MOV	AX,[ASCLMEM]
	MOV	[DI],AX
	POP	BP
	RETf

;
;☆ 32 BIT 数の EULER 関数
;

EUL_ILG:
	JMP	far ptr ILGERR

farEULERin:
	MOV	[EUL_LOW],1
	MOV	[EUL_HIGH],0
	MOV	DI,[CALCSP]
	MOV	AX,[DI]
	CMP	AX,2
	JA	EUL_ILG;>=3 words is ilg(fration,complex)
	XOR	DX,DX
	CMP	AX,1
	JB	EUL_ILG;0 は不可
	JE	EUL10
	MOV	DX,[DI+4]	;2 WORD の場合
EUL10:
	MOV	AX,[DI+2]
	MOV	[MOB_LOW],AX
	MOV	[MOB_HIGH],DX

  if flg98
	MOV	AX,UBCONSTSEG
  else
	mov	ax,ss
	add	ax,ubconstseg
  endif
	MOV	ES,AX
	MOV	SI,SYSPRM	;素数表の位置
EUL20:
	MOV	DX,[MOB_HIGH]
	OR	DX,DX
	JZ	EUL100;1 ワードになった
	WINC	SI
	MOV	CX,ES:[SI]
	JCXZ	EUL200;割る数が無くなった
	MOV	AX,DX
	XOR	DX,DX
	DIV	CX
	MOV	BX,AX;商をメモ
	MOV	AX,[MOB_LOW]
	DIV	CX
	OR	DX,DX
	JZ	EUL30
	OR	BX,BX
	JNZ	EUL20
	CMP	AX,CX
	JAE	EUL20;商>=割る数
	JMP	EUL200;商<割る数

	;割り切れた場合

EUL30:
	MOV	[MOB_LOW],AX	;商のセット
	MOV	[MOB_HIGH],BX
	DEC	CX
	CALL	EUL_MULCX
	INC	CX
EUL40:
	MOV	AX,[MOB_HIGH]
	XOR	DX,DX
	DIV	CX
	MOV	BX,AX
	MOV	AX,[MOB_LOW]
	DIV	CX
	OR	DX,DX
	JNZ	EUL20

	;二回以上割れる場合

	MOV	[MOB_LOW],AX
	MOV	[MOB_HIGH],BX
	CALL	EUL_MULCX
	JMP	EUL40

EUL100:
	MOV	AX,[MOB_LOW]
	CMP	AX,1
	JE	EUL210;1 ならば終わり
	INC	SI
	INC	SI
	MOV	CX,ES:[SI]
	JCXZ	EUL200;割る数が無くなった
	XOR	DX,DX
	DIV	CX
	OR	DX,DX
	JZ	EUL110
	CMP	AX,CX
	JAE	EUL100;商>=割る数
	JMP	EUL200;商<割る数

	;割り切れた場合

EUL110:
	MOV	[MOB_LOW],AX
	DEC	CX
	CALL	EUL_MULCX
	INC	CX
EUL140:
	MOV	AX,[MOB_LOW]
	XOR	DX,DX
	DIV	CX
	OR	DX,DX
	JNZ	EUL100

	;二回以上割れる場合

	MOV	[MOB_LOW],AX
	CALL	EUL_MULCX
	JMP	EUL140

	;素数が残った場合
EUL200:
	CALL	EUL_MUL2W	;[EUL_**] に [MOB_**]-1 をかける

	;結果のセット

EUL210:
	MOV	AX,[EUL_LOW]
	MOV	DX,[EUL_HIGH]
	MOV	CX,1
	OR	DX,DX
	JZ	EUL220
	INC	CX
EUL220:
	MOV	SI,[CALCSP]
	MOV	[SI],CX
	MOV	[SI+2],AX
	MOV	[SI+4],DX
	MOV	AX,SS
	MOV	ES,AX
	RETf

EUL_MULCX:
	MOV	AX,[EUL_LOW]
	MUL	CX
	MOV	[EUL_LOW],AX
	MOV	BX,DX
	MOV	AX,[EUL_HIGH]
	MUL	CX
	ADD	AX,BX;キャリーはないはず
	MOV	[EUL_HIGH],AX
	RET

EUL_MUL2W:
	MOV	CX,[MOB_LOW]
	SUB	CX,1
	JNC	EUL_MUL2W10
	DEC	[MOB_HIGH]
EUL_MUL2W10:
	MOV	AX,[EUL_LOW]
	MUL	CX
	PUSH	AX;一桁目をメモ
	MOV	BX,DX;二桁目の WORK
	MOV	AX,[EUL_HIGH]
	MUL	CX
	ADD	BX,AX;キャリーはないはず
	MOV	CX,[MOB_HIGH]
	MOV	AX,[EUL_LOW]
	MUL	CX
	ADD	AX,BX;キャリーはないはず
	MOV	[EUL_HIGH],AX
	POP	AX
	MOV	[EUL_LOW],AX
	ret

;
;☆ 32 BIT 数の MOBIUS 関数
;

MOB_ILG:
	JMP	far ptr ILGERR

farMOBIUSin:
	MOV	[MOB_MEM],0
	MOV	DI,[CALCSP]
	MOV	AX,[DI]
	CMP	AX,2
	JA	MOB_ILG;>=3 words is ilg(and other types)
	XOR	DX,DX
	CMP	AX,1
	JB	MOB_ILG;0 は不可
	JE	MOB10
	MOV	DX,[DI+4]	;2 WORD の場合
MOB10:
	MOV	AX,[DI+2]
	MOV	[MOB_LOW],AX
	MOV	[MOB_HIGH],DX

  if flg98
	MOV	AX,UBCONSTSEG
  else
	mov	ax,ss
	add	ax,ubconstseg
  endif
	MOV	ES,AX
	MOV	SI,SYSPRM	;素数表の位置
MOB20:
	MOV	DX,[MOB_HIGH]
	OR	DX,DX
	JZ	MOB100;1 ワードになった
	WINC	SI
	MOV	CX,ES:[SI]
	JCXZ	MOB200;割る数が無くなった
	MOV	AX,DX
	XOR	DX,DX
	DIV	CX
	MOV	BX,AX;商をメモ
	MOV	AX,[MOB_LOW]
	DIV	CX
	OR	DX,DX
	JZ	MOB30
	OR	BX,BX
	JNZ	MOB20
	CMP	AX,CX
	JAE	MOB20;商>=割る数
	JMP	MOB200;商<割る数

	;割り切れた場合

MOB30:
	MOV	[MOB_LOW],AX
	MOV	[MOB_HIGH],BX
	INC	[MOB_MEM]
	MOV	AX,BX
	XOR	DX,DX
	DIV	CX
	MOV	AX,[MOB_LOW]
	DIV	CX
	OR	DX,DX
	JNZ	MOB20
MOB_SET0:	;二回割れれば 0
	XOR	AX,AX
	MOV	SI,[CALCSP]
	MOV	[SI],AX	
MOB_RET:
	MOV	AX,SS
	MOV	ES,AX
	RETf

MOB100:
	MOV	AX,[MOB_LOW]
	CMP	AX,1
	JE	MOB210;1 ならば終わり
	WINC	SI
	MOV	CX,ES:[SI]
	JCXZ	MOB200;割る数が無くなった
	XOR	DX,DX
	DIV	CX
	OR	DX,DX
	JZ	MOB110
	CMP	AX,CX
	JAE	MOB100;商>=割る数
	JMP	MOB200;商<割る数

	;割り切れた場合

MOB110:
	MOV	[MOB_LOW],AX
	INC	[MOB_MEM]
	XOR	DX,DX
	DIV	CX
	OR	DX,DX
	JNZ	MOB100
	JMP	MOB_SET0	;二回割れれば 0

MOB200:
	INC	[MOB_MEM]
MOB210:
	MOV	SI,[CALCSP]
	MOV	AX,1
	MOV	[SI+2],AX
	TEST	[MOB_MEM],1
	JZ	MOB220
	MOV	AH,80H
MOB220:
	MOV	[SI],AX
	JMP	MOB_RET

code2	ends

code3	segment	public
assume	cs:code3,ds:data

	public	AHEDSP3

farextoption:
	dec	ax
	jz	GETEXTIND12	;# of elements
	dec	ax
	jz	getextsize	;record size
	dec	ax
	jz	getextpt	;POINT
	dec	ax
	jz	getextind1
	jmp	getextind2
getextind1:
	set32
	mov	cx,[bx+10]
	set32
	or	cx,cx
	jz	getextind12	;if 1 dim
	set32
	inc	cx
	set32
	mov	ax,[bx+2]
	set32
	inc	ax
	set32
	xor	dx,dx
	set32
	div	cx
	set32
	dec	ax
	set32
	mov	dx,ax
	set32
	shr	dx,16
	jmps	getextout
getextind2:
	mov	ax,[bx+10]
	mov	dx,[bx+12]
	jmps	getextout
getextsize:
	MOV	AX,[BX+6]	;要素サイズ
	SHR	AX,1
	DEC	AX
	JMPS	GETEXTOUT
GETEXTPT:
	MOV	AX,[BX+8]
	JMPS	GETEXTOUT
GETEXTIND12:
	MOV	AX,[BX+2]
	MOV	DX,[BX+4]
GETEXTOUT:
	MOV	CX,2
	OR	DX,DX
	JNZ	GETEXOUT50
	DEC	CX
	OR	AX,AX
	JNZ	GETEXOUT50
	DEC	CX
GETEXOUT50:
	mov	si,[calcsp]
	MOV	[SI],CX
	MOV	[SI+2],AX
	MOV	[SI+4],DX
	retf

;
; * convert polynomial
;
pconvret:
	jmp	far ptr returnadr
pconvsynerr:
	jmp	far ptr synerr
pconvilgerr:
	jmp	far ptr ilgerr

farpolyconvin:
	call	far ptr farkakko
	jc	pconvilgerr

	mov	si,[calcsp]
	mov	ax,[si]
	or	ax,ax
	jz	pconvret	;if 0 then ans=0

	call	ahedsp3

	mov	di,[calcsp]
	lea	si,[di+unitbyte]
	mov	cx,[si]
	and	cx,lenmask
	inc	cx
	rep	movsw			;copy to high
	mov	si,[calcsp]
	lea	di,[si+unitbyte]
	lodsw
	mov	cx,ax
	and	ah,attribmaskhigh
	cmp	ah,modpolymaskhigh
	je	modpconv
	cmp	ah,polymaskhigh
	jne	pconvilgerr

pconv:				;poly to modpoly
	set32
	mov	bx,word ptr [polymodulus]
	set32
	or	bx,bx
	jz	pconvilgerr
	lodsw			;degree+1
	mov	cx,ax		;
	add	di,2		;skip attribute
	set32
	mov	ax,bx
	set32
	stosw			;set modulus
pconv10:
	push	cx
	set32
	xor	ax,ax
	lodsw
	mov	cx,ax
	and	cx,lenmask
	jz	pconv50		;if =0
	and	ax,attribmask+signmask
	jz	pconv20		;if >0
	cmp	ax,signmask
	jne	pconvilgerr	;if not integer
	;if negative
pconv20:
	push	ax		;/*
	add	si,cx
	set32
	xor	dx,dx
	add	si,cx
	push	si		;/** next top adr

	inc	cx
	shr	cx,1
	jc	pconv30
	set32
	xor	ax,ax
	sub	si,2
	mov	ax,[si]
	jmp	pconv40
pconv30:
	sub	si,4
	set32
	mov	ax,[si]
pconv40:
	set32
	div	bx
	dec	cx
	jnz	pconv30

	pop	si		;**/
	set32
	mov	ax,dx
	pop	dx		;*/
	or	dx,dx
	jz	pconv50
	set32
	or	ax,ax
	jz	pconv50		;if 0
	set32
	sub	ax,bx
	set32
	neg	ax
pconv50:
	set32
	stosw
	pop	cx
	dec	cx
	jnz	pconv10

	sub	di,4		;search non 0
	mov	cx,0ffffh
	std
	set32
	xor	ax,ax
	set32
	repe	scasw
	cld
	mov	ax,di
	add	ax,2		;count attribute
	mov	si,[calcsp]
	add	si,unitbyte
	mov	[calcsp],si
	sub	ax,si
	jz	short pconv100	;if 0
	shr	ax,1
	add	ax,2		;count modulus
	or	ax,modpolymask
pconv100:
	mov	[si],ax
	jmp	far ptr returnadr


modpconv:			;modpoly to poly
	set32
	mov	ax,word ptr [polymodulus]
	set32
	or	ax,ax
	jnz	pconvilgerr
	add	di,2		;skip attribute
	and	cx,lenmask
	shr	cx,1
	dec	cx
	mov	[di],cx		;set terms
	add	di,2
	add	si,4		;skip modulus
modpconv10:
	set32
	lodsw
	set32
	or	ax,ax
	jz	modpconv20
	mov	word ptr [di],1		;set 1 word
	add	di,2
	stosw
	set32
	shr	ax,16
	or	ax,ax
	jz	modpconv30
	mov	word ptr [di-4],2	;set 2 word
modpconv20:
	stosw			;set value
modpconv30:
	loop	modpconv10

	mov	ax,di
	mov	si,[calcsp]
	add	si,unitbyte
	mov	[calcsp],si
	sub	ax,si
	shr	ax,1
	dec	ax
	cmp	ax,LIMITWORD
	ja	pconvovererr
	or	ax,polymask
	mov	[si],ax
	jmp	far ptr returnadr

pconvovererr:
	jmp	far ptr ovrerr

;
; * reverse polynomial
;
prevret:
	jmp	far ptr returnadr
prevsynerr:
	jmp	far ptr synerr
previlgerr:
	jmp	far ptr ilgerr

farpolyrevin:
	call	far ptr farkakko
	jc	previlgerr

	mov	si,[calcsp]
	mov	ax,[si]
	or	ax,ax
	jz	prevret	;if 0 then ans=0
	and	ah,attribmaskhigh
	cmp	ah,modpolymaskhigh
	je	modprev
	cmp	ah,polymaskhigh
	jne	previlgerr

prev:
	mov	si,[calcsp]
	lodsw
	and	ax,lenmask
	dec	ax		;skip degree+1
	mov	di,si
	add	si,2		;const coeff starts
	mov	bx,si		;lower bound
	add	ax,ax
	cmp	word ptr [si],0
	je	previlgerr	;if 0 then degree will change
	add	di,ax		;highest word adr
	push	di		;/*
prevlp:				;reverse all
	cmp	si,di
	jae	short prevjp
	mov	ax,[si]
	mov	dx,[di]
	mov	[di],ax
	mov	[si],dx
	add	si,2
	sub	di,2
	jmp	prevlp
prevjp:
	pop	di		;*/
prevlp2:
	mov	si,di
	mov	ax,[di]		;attrib
	and	ax,lenmask
	add	ax,ax
	sub	si,ax
	push	si		;/*
prevlp3:			;reverse each
	cmp	si,di
	jae	short prevjp3
	mov	ax,[si]
	mov	dx,[di]
	mov	[di],ax
	mov	[si],dx
	add	si,2
	sub	di,2
	jmp	prevlp3
prevjp3:
	pop	si		;*/
	lea	di,[si-2]	;next attrib
	cmp	di,bx
	jae	prevlp2
	jmp	far ptr returnadr


modprev:
	lodsw
	and	ax,lenmask
	mov	di,si
	add	si,4		;skip modulus
	add	di,ax
	add	di,ax		;
	mov	word ptr [di],0
	set32
	cmp	word ptr [si],0
	je	previlgerr	;degree will change
	and	ax,1
	add	ax,ax
	add	di,ax
	sub	di,4		;dword highest adr
mprevlp:
	cmp	si,di
	jae	mprevjp
	set32
	mov	ax,[si]
	add	si,4
	set32
	mov	dx,[di]
	sub	di,4
	set32
	mov	[di],ax
	set32
	mov	[si],dx
	jmp	mprevlp
mprevjp:
	jmp	far ptr returnadr



AHEDSP3:
	MOV	SI,[CALCSP]
	SUB	SI,UNITBYTE
	CMP	SI,[calcsp_limit]
	JB	GO_CALCSPERR3
	MOV	[CALCSP],SI
	RET

GO_CALCSPERR3:
	JMP	far ptr CALCSPERR

code3	ends
