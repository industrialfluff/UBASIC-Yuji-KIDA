;formulin
;	formul.asm & formul32.asm common part
;

DATA	SEGMENT	WORD PUBLIC

	PUBLIC	DIVLEN,ANSLEN,DIVWORD,limitlen
	PUBLIC	PTRNOW,PTRNOW2,SFTBIT,attrib
	public	SIMEM_M,DIMEM_M,silen_m,dilen_m
	public	xmem,ymem,pmem
	PUBLIC	XSIGN2

	EXTRN	POINTWORD:WORD,directflg:byte
	EXTRN	TYPMEM:WORD,CALCSP:WORD
	EXTRN	MAXWORD:WORD,MAXALL:WORD,emawords:word
	extrn	calcsp_limit:word,polymodulus:dword
	extrn	poly_operation:word
	extrn	overloadaddadr:word

CALCTBL	DW	SYNERR,check_equal,compare,compare
	dw	compare,compare,check_equal
	DW	SYNERR,SYNERR,SYNERR,SYNERR,SYNERR
	DW	SIGNIN,ADDIN,SUBIN
	DW	SYNERR,SYNERR,SYNERR,SYNERR,SYNERR,SYNERR
	DW	MULIN,DIVIN,RESIN,IDIVIN,RATDIVIN
	DW	SYNERR,SYNERR,SYNERR,SYNERR,SYNERR
	DW	POWERin

INCTBL	DW	SVINC,SAVINC,LVINC,LAVINC,LLVINC,LLAVINC

DECTBL	DW	SVDEC,SAVDEC,LVDEC,LAVDEC,LLVDEC,LLAVDEC

CLRTBL	DW	SVCLR,SAVCLR,LVCLR,LAVCLR,LLVCLR,LLAVCLR

NEGTBL	DW	SVNEG,SAVNEG,LVNEG,LAVNEG,LLVNEG,LLAVNEG


SIGN_PT		DW	?	;結果の符号
TOTALWORDS	DW	?	;結果の長さ(+1,-0)
SFTBIT		DW	0
PTRNOW		DW	?
PTRNOW2		DW	?
  if FLG32
DIVWORD		DW	?	;正規化した割る数の上位１ワード
		DW	?	;32 BIT対応
  else
DIVWORD		DW	?	;正規化した割る数の上位１ワード
  endif
DIVLEN		DW	?	;割る数のワード数
ANSLEN		DW	?
HIGHOFANS	DW	?

XMEM		DW	?
YMEM		DW	?
PMEM		DW	?
XSIGN2		DW	?
SQARHIGH	DW	?

ATTRIBPTR	DW	?
ATTRIB		DW	?
SIMEM_M		DW	?
SILEN_M		DW	?	;[SI] の長さ
DIMEM_M		DW	?
DILEN_M		DW	?	;[DI] の長さ

ARRAY_UNIT	DW	?

DIMEM_A		DW	?
LIMITLEN	DW	?
CALMEM		DB	0
;OPMEM		DB	?

DATA	ENDS


CODE	SEGMENT PUBLIC
	ASSUME	CS:CODE,DS:DATA

	public	calc
	public	kakko_ax,farKakko_ax
	public	kakko_ax_signed,farkakko_ax_signed
	public	formul,farformul
	public	faradd_calcsp,farsub_calcsp
	public	faraddAAdisi,farsubAAdisi,farmulAAdisi
	public	farMul_calcsp,farRes_calcsp
	public	faridiv_calcsp,farpower_calcsp
	public	parnumsub
	public	pow_main
	public	paremaword

	public	neg_next,clr_next,inc_next,dec_next
	public	lvincin,lvdecin		;lvnegin

	public	chgsigndi,farchgsigndi
	public	letcommon

	extrn	log_ent:near,exp_ent:near
	extrn	negema:near,clrema:near,incema:near,decema:near

	extrn	moderr:near

	extrn	getgcd:near
	extrn	mulIorFdisi:near
	extrn	divin:near
	extrn	idiv_complex:near
	extrn	store_float:near,store_complex:near

	extrn	farneg_polysi:near,farneg_modpolysi:near
	extrn	power_poly:near,power_modpoly:near
	extrn	poly_scalar:near

	extrn	add_integer_rational:near,add_rational_integer:near
	extrn	add_rational_rational:near
	extrn	add_integer_float:near,add_float_integer:near
	extrn	add_integer_complex:near,add_complex_integer:near
	extrn	add_float_float:near,add_complex_complex:near
	extrn	add_float_rational:near,add_rational_float:near
	extrn	add_float_complex:near,add_complex_float:near
	extrn	add_rational_complex:near,add_complex_rational:near
;	extrn	add_modpoly_scalar:near

	extrn	mul_integer_rational:near,mul_rational_integer:near
	extrn	mul_rational_rational:near
	extrn	mul_integer_float:near,mul_float_integer:near
	extrn	mul_integer_complex:near,mul_complex_integer:near
	extrn	mul_float_float:near,mul_complex_complex:near
	extrn	mul_float_rational:near,mul_rational_float:near
	extrn	mul_float_complex:near,mul_complex_float:near
	extrn	mul_rational_complex:near,mul_complex_rational:near

	extrn	div_integer_float:near,div_float_integer:near
	extrn	div_integer_complex:near,div_complex_integer:near
	extrn	div_float_float:near,div_complex_complex:near
	extrn	div_float_rational:near,div_rational_float:near
	extrn	div_float_complex:near,div_complex_float:near
	extrn	div_rational_complex:near,div_complex_rational:near

	extrn	idiv_float_float:near
	extrn	idiv_integer_float:near,idiv_float_integer:near

	extrn	cmp_float_float:near
	extrn	cmp_integer_float:near,cmp_float_integer:near
	extrn	cmp_rational_float:near,cmp_float_rational:near

	extrn	ratdivin:near
	extrn	powXrational:near
	extrn	powYbigXcomplex:near,powYbigXrational:near
	extrn	powYcomplex:near
	extrn	powYfloat:near,powXcomplex:near

	extrn	overloadadd:near,overloadsub:near
	extrn	overloadmul:near,overloaddiv:near
	extrn	overloadidiv:near,overloadmod:near
	extrn	overloadpower:near

	extrn	returnadr:near
	extrn	farlet_extended:near

	extrn	systemerr:near,calcsperr:near,nodataerr:near
	extrn	cantdo:near

;
;* calc and return with ax
;  with NO backsp
;  0 <= return AX <= 65535

farKakko_ax:
	call	kakko_ax
	retf

kakko_ax:
	call	kakko
	MOV	SI,[CALCSP]
	MOV	AX,[SI]
	CMP	AX,1
	JA	kakko_axerr
	JB	kakko_ax10	;if 0
	MOV	AX,[SI+2]
kakko_ax10:
	clc
	ret
kakko_axerr:
	stc
	ret

;
;* calc and return with ax
;  with NO backsp
;  -32767 <= return AX <= 32767
;  form of AX : sign + absolute

farkakko_ax_signed:
	call	kakko_ax_signed
	retf

kakko_ax_signed:
	call	kakko
	MOV	SI,[CALCSP]
	MOV	AX,[SI]
	cmp	ax,signmask+1
	je	kakko_axNeg
	CMP	AX,1
	JA	kakko_axerr
	JB	kakko_ax10	;if 0
	MOV	AX,[SI+2]
	test	ah,signmaskhigh
	jnz	kakko_axerr
	clc
	ret
kakko_axNeg:
	mov	ax,[si+2]
	test	ah,signmaskhigh
	jnz	kakko_axerr
	or	ah,signmaskhigh
	clc
	ret


;* 数式の解釈

farFORMUL:
	call	formul
	retf


	myalign
FORMUL:	
	MOV	BX,[TYPMEM]
	INC	BX
	MOV	BYTE PTR [BX],0	;開始マーク
	MOV	[TYPMEM],BX

FORMLP:	
	CALL	PARAM		;パラメータをスタックに積む
	MOV	AL,[BP]		;演算子
	cmp	al,0beh		;code of 'or'
	je	forml1
	cmp	al,0c5h		;code of 'and'
	je	forml1
	CMP	AL,0D0H
	JC	ENDMKJ
	CMP	AL,NCODE
	JNC	FORMSYNERR
forml1:
	MOV	[CALMEM],AL	;mem A

FORML2:	
	SUB	AL,6
	MOV	BX,[TYPMEM]
	CMP	AL,[BX]
	JNC	NOCALC		;前の演算よりも強い

	PUSH	BP
	CALL	CALC		;前の演算の実行
	POP	BP
	MOV	AL,[CALMEM]
	JMP	FORML2

NOCALC:	
	INC	BP
	MOV	BX,[TYPMEM]
	INC	BX
	MOV	[TYPMEM],BX
	MOV	AL,[CALMEM]
	MOV	[BX],AL		;演算子をスタックに積む
	JMP	FORMLP

FORMSYNERR:
	JMP	SYNERR

ENDMKJ:	
	MOV	BX,[TYPMEM]
	MOV	AL,[BX]
	OR	AL,AL
	JZ	FORMULEND

	PUSH	BP
	CALL	CALC		;実行していない演算の実行
	POP	BP
	JMP	ENDMKJ

FORMULEND:
	DEC	BX
	MOV	[TYPMEM],BX
	RET



;* SUBROUTINES


;* 各演算ルーチンに飛ぶ
; NOW	パラメータ(一個or二個)がスタックに
;	演算子が TYPMEM で示される番地に
; BACKSP を CALL するのは各ルーチンの役目
; except SIGNIN
;
; 破壊	SEGMENT REGISTERS 以外全て(BP も破壊)

	myalign
CALC	PROC	
	XOR	AX,AX
	MOV	BX,[TYPMEM]
	MOV	AL,[BX]		;演算子
	DEC	BX
	MOV	[TYPMEM],BX

	SUB	AL,0D0H
	JBE	isCALCSYNERR
	CMP	AL,0EFH-0D0H
	JA	CALCSYNERR
	MOV	BX,AX		;AL は compare で使う
	add	bx,bx
	ADD	BX,OFFSET CALCTBL
	JMP	[BX]

isCALCSYNERR:
	cmp	al,0beh-0d0h	;code of 'or'
	je	calc_or
	cmp	al,0c5h-0d0h	;code of 'and'
	je	calc_and
CALCSYNERR:
	JMP	SYNERR


;
; calculate OR
;
calc_or:
	mov	si,[calcsp]
	mov	ax,[si]
	add	si,UNITBYTE
	mov	[calcsp],si
	or	ax,[si]
setax_andor:
	jz	set0_andor
	mov	ax,1
	mov	[si],ax
	add	si,2
set0_andor:
	mov	[si],ax
	ret

;
; calculate AND
;
calc_and:
	mov	si,[calcsp]
	mov	ax,[si]
	add	si,UNITBYTE
	mov	[calcsp],si
	or	ax,ax
	jz	set0_andor
	mov	ax,[si]
	or	ax,ax
	jmp	setax_andor


;  符号を逆にする
;  BACKSP は CALL しない

SIGNIN:	
	mov	si,[calcsp]

negallsi:
	mov	ax,[si]
	or	ax,ax
	jz	signret
	test	ah,compratstrpackmaskhigh
	jnz	sign_extra
	xor	ah,signmaskhigh		;change sign
	mov	[si],ax
signret:
	ret

go_sign_poly:			;called from negpoly?
	jmp	far ptr farneg_polysi	;call & ret
go_sign_modpoly:		;called from negmodpoly?
	jmp	far ptr farneg_modpolysi	;calll & ret
sign_ratpoly:
	mov	ax,[si]
sign_extra:
	and	ah,attribmaskhigh
	cmp	ah,polymaskhigh
	je	go_sign_poly
	cmp	ah,modpolymaskhigh
	je	go_sign_modpoly
	add	si,2
	cmp	ah,ratpolymaskhigh
	je	sign_ratpoly
	cmp	ah,complexmaskhigh
	je	sign_complex
	cmp	ah,ratmaskhigh
	je	signcomplex20
	jmp	ilgerr
sign_complex:
	mov	ax,[si]		;real part
	or	ax,ax
	jz	signcomplex10
	xor	ah,signmaskhigh		;符号 BIT の反転
	mov	[si],ax
	and	ax,lenmask
signcomplex10:
	inc	ax
	add	si,ax
	add	si,ax
signcomplex20:
	mov	ax,[si]		;imaginary part
	or	ax,ax
	jz	signcomplexret
	xor	ah,signmaskhigh		;符号 BIT の反転
	mov	[si],ax
signcomplexret:
	ret


CALC	ENDP

;
;☆ 括弧の処理
;

farKAKKO:
	call	kakko
	retf

KAKKO0:				;called from GCD
	INC	BP
	myalign
KAKKO:				;called from DIM etc.
	MOV	BX,[TYPMEM]
	INC	BX
	MOV	BYTE PTR [BX],1	;start mark
	MOV	[TYPMEM],BX

PARNLP:	
	CALL	PARAM		;パラメータを積む
	MOV	AL,[BP]
	CMP	AL,0D0H
	JC	PARMK?		;セパレータか?
	CMP	AL,NCODE
	JNC	PARNSYNERR
parnl1:
	MOV	[CALMEM],AL	;mem A

PARNL2:	
	SUB	AL,6
	MOV	BX,[TYPMEM]
	CMP	AL,[BX]
	JNC	PNCALC

	PUSH	BP
	CALL	CALC		;前の演算の実行
	POP	BP
	MOV	AL,[CALMEM]
	JMP	PARNL2

isPARNSYNERR:
	cmp	al,0beh		;code of 'or'
	je	parnl1
	cmp	al,0c5h		;code of 'and'
	je	parnl1

PARNSYNERR:
	JMP	SYNERR

PNCALC:	
	INC	BP
	MOV	BX,[TYPMEM]
	INC	BX
	MOV	[TYPMEM],BX
	MOV	AL,[CALMEM]
	MOV	[BX],AL		;演算子を積む
	JMP	PARNLP

PARMK?:	
	CMP	AL,')'
	jne	isPARNSYNERR	;最後は ) でなければならない

PARMKL:	
	MOV	BX,[TYPMEM]
	MOV	AL,[BX]
	OR	AL,AL
	JZ	PARNSYNERR	;lack of ')'
	DEC	AL
	JZ	PAROUT		;1=end mark

	PUSH	BP
	CALL	CALC		;残っている演算の実行
	POP	BP
	JMP	PARMKL

PAROUT:	
	INC	BP		;pass ')'
	DEC	BX
	MOV	[TYPMEM],BX
	RET	

;
;	パラメータを得る(括弧に囲まれたものは計算してから)
;

parposcomplex:
	call	ahedsp
	inc	bp
	mov	di,si		;[calcsp]
	mov	ah,complexmaskhigh
	mov	al,3
	stosw
	xor	ax,ax
	stosw			;real part
	inc	ax
	stosw			;imag part
	stosw
	ret

parposhex:
	add	bp,2		;skip code & 0f2h
	call	ahedsp
	mov	di,si		;=[calcsp]
	mov	si,bp
	mov	cx,[si]
	inc	cx
	rep	movsw
	mov	bp,si
	ret


param0:
	inc	bp

	myalign
PARAM:
	MOV	AL,[BP]
	CMP	AL,codemark2
	jbe	PARFUNC?
	cmp	al,vcode5
	jbe	parvar		;variable
	CMP	AL,NCODE
	JB	PARPOS5
	cmp	al,ncode2	;CMP	AL,NCODE_ADR
	JBE	PARNUM		;numeric
PARPOS5:
	CMP	AL,0DEH		;'-'
	JE	PARMINUS	;if minus mark
	cmp	al,0ddh		;'+'
	je	param0		;if '+' then skip
;PARPOS:
	cmp	al,codemark3
	je	gofunc3
PARPOS10:
	cmp	al,9eh		;#i
	je	parposcomplex
	cmp	al,0bbh		;code of 0x
	je	parposhex
PARPOS20:
	CMP	AL,0A3H		;code of RES
	JE	STRRES	
	CMP	AL,0B3H		;code of 'fn'
	jne	parpos100
STRFUNC:
	INC	BP
	JMP	FUNCTION	;in 'JUMP.ASM'

parpos100:
	cmp	al,09FH		;code of WORD
	je	parWORD
	CMP	AL,0A9H		;code of POINT
	je	parPOINT
parsynerr:
	jmp	synerr

parword:
	inc	bp
	mov	ax,[maxword]
	jmps	parwordpoint
paremaword:
	mov	ax,[emawords]
	jmps	parwordpoint
parpoint:
	inc	bp
	mov	ax,[pointword]
parwordpoint:
	call	ahedsp
	or	ax,ax
	jz	parwordpoint20
	mov	word ptr [si],1
	winc	si
parwordpoint20:
	mov	[si],ax
	ret


; pre-posed minus mark

PARMINUS:
	MOV	BX,[TYPMEM]
	MOV	AL,[BX]
	OR	AL,AL
	JZ	PARN1		;if top
	CMP	AL,1
	JE	PARN1		;if '('
	CMP	AL,0DCH
	JNC	parsynerr	;if not compare

PARN1:	
	INC	BX
	MOV	BYTE PTR [BX],0DCH	;minus mark
	MOV	[TYPMEM],BX
	INC	BP
	JMP	PARAM

PARFUNC?:
	je	gofuncin
	CMP	AL,'('
	JE	goKAKKO0
	cmp	al,'"'
	je	parstring
	cmp	al,'_'
	je	parpolynomial
	cmp	al,'$'
	je	parcommon
	jmp	ilgerr


parcommon:
	jmp	far ptr farparcommon
gofunc3:
	jmp	func3in
gofuncin:
	jmp	funcin
goKAKKO0:
	jmp	kakko0

parstring:
	inc	bp
	call	ahedsp
	lea	di,[si+2]
parstring10:
	mov	al,[bp]
	inc	bp
	stosb
	cmp	al,'"'
	jne	parstring10
	mov	byte ptr [di-1],0

	mov	ax,di
	sub	ax,3
	sub	ax,si		;byte length

	cmp	ax,limitword*2
	ja	parstringovr
	inc	ax
	shr	ax,1
	jc	parstringret
	or	ah,signmaskhigh		;odd length
parstringret:
	or	ah,stringmaskhigh
	mov	[si],ax
	ret
parstringovr:
	jmp	ovrerr

parpolynomial:
	winc	bp		;skip X
	call	ahedsp
	set32
	mov	ax,word ptr [polymodulus]
	set32
	or	ax,ax
	jnz	parmodpoly
	mov	word ptr [si],polymask+4
	mov	word ptr [si+2],2
	mov	word ptr [si+4],0
	mov	word ptr [si+6],1
	mov	word ptr [si+8],1
	ret
parmodpoly:
	mov	word ptr [si],modpolymask+6
	set32
	mov	word ptr [si+2],ax
	mov	word ptr [si+6],0
	mov	word ptr [si+8],0
	mov	word ptr [si+10],1
	mov	word ptr [si+12],0
	ret


;ＲＥＳのロード

STRRES:	
	CALL	AHEDSP
	MOV	DI,SI		;=[CALCSP]
	INC	BP
	MOV	SI,RESADR
	copy_si2di
	RET	

;  if numeric data

	myalign	
PARNUM:	
	call	parnumsub
	mov	al,[bp]
	CMP	al,'.'
	je	gostore_float	;if float
	cmp	al,9eh		;code of complex
	je	gostore_complex
	ret

gostore_float:
	jmp	store_float

gostore_complex:
	jmp	store_complex

parnumsub:
	INC	BP
	CALL	AHEDSP
	MOV	CL,0		;positive
	SUB	AL,NCODE
	JC	PARMSYNERR

	JE	SET0
	DEC	AL
	JZ	SETW
	DEC	AL
	JZ	STRL
PARMSYNERR:
	JMP	SYNERR

SET0:	
	MOV	BX,[CALCSP]
	MOV	word ptr [BX],0
	ret

SETW:	
	MOV	DX,[BP]
	WINC	BP

	MOV	CX,1
STRW:
	MOV	BX,[CALCSP]
	MOV	[BX],CX		;set attribute
	MOV	[BX+2],DX	;set value
	ret

	myalign
STRL:	
	MOV	CX,[BP]
	AND	CX,LENMASK
	INC	CX
	MOV	DI,[CALCSP]

STRLLP:	
	MOV	AX,[BP]
	WINC	BP
	STOSW
	loop	STRLLP
	ret


;変数のロード

	;配列短変数の場合

LOADSAV:
	CALL	GETSAVADR
	XOR	CX,CX		;CX=長さ
	MOV	DX,[DI]		;DX=値
	OR	DX,DX
	JZ	LOADARR20
	MOV	CH,DH
	AND	CH,signmaskhigh		;符号
	MOV	CL,1		;長さ
	AND	DH,7FH		;res 7-th bit
LOADARR20:
	MOV	AX,SS
	MOV	DS,AX
	JMP	STRW

GO_UNDEFERR:
	JMP	UNDEFERR
GO_INDEXERR:
	JMP	INDEXERR	;配列のINDEX ERROR


LOADARRAY:
	CMP	AL,3
	JB	LOADSAV
	JE	LOADLAV

	;配列特別変数のロード

LOADLLAV:
	CALL	GETLLAVADR
	MOV	SI,DI		;DS は設定済
	MOV	DI,SS:[CALCSP]
	jmp	loadlvcopy

	;配列長変数のロード

LOADLAV:
	CALL	GETLAVADR
LOADLAVIN:
	MOV	SI,DI		;DS は設定済
	MOV	DI,SS:[CALCSP]
	jmp	loadlvcopy

GOSET0:
	JMP	SET0


	myalign
PARVAR:				;NOW AL=変数型
	INC	BP
	CALL	AHEDSP		;計算スタックを一つ深く
	SUB	AL,VCODE
	TEST	AL,1
	JNZ	LOADARRAY	;配列の場合

	CMP	AL,2
	JAE	LOADLV

	;単純短変数のロード

LOADSV:	
	xor	ax,ax
	mov	al,[bp]
	inc	bp
	mov	bx,[bp]
	add	bp,ax

	MOV	DX,cs:[BX]	;DX=VALUE
	OR	DX,DX
	JZ	GOSET0		;IF 0		
	MOV	CH,DH
	AND	CH,signmaskhigh		;符号
	MOV	CL,1		;長さ
	AND	DH,7FH		;res 7-th bit
	JMP	STRW

	;単純特別変数のロード
	;単純長変数のロード

LOADLV:	
	xor	ax,ax
	mov	al,[bp]
	inc	bp
	mov	bx,[bp]
	add	bp,ax

	MOV	DI,[CALCSP]
	MOV	DS,cs:[BX]
	XOR	SI,SI

loadlvcopy:
	cmp	byte ptr [bp],'.'
	je	loadpackmember
loadlvcopymain:
	copy_si2di
	MOV	AX,SS
	MOV	DS,AX
	RET	


loadpackmember:
	inc	bp
	cmp	byte ptr [bp],NCODE1
	jne	gonopack

loadpackmemberagain:
	mov	ax,[si]
	winc	si
	and	ah,attribmaskhigh
	cmp	ah,packmaskhigh
	jne	gonopack

	inc	bp
	mov	cx,[bp]		;target number
	jcxz	gonopack
	winc	bp

	cmp	cx,[si]
	ja	gonopack
	winc	si
	dec	cx
	jz	loadlvcopyagain
loadpacklp:
	mov	ax,[si]
	and	ax,lenmask
	inc	ax
	add	ax,ax
	add	si,ax
	myloop	loadpacklp
loadlvcopyagain:
	cmp	word ptr [bp],'.'+256*NCODE1
	jne	loadlvcopy
	inc	bp
	jmp	loadpackmemberagain


gonopack:
	jmp	ilgerr


comment %
;
;	２つのパラメータの型を合わせる
;
;	INPUT DI,SI base adrs
;
MATCHTYPE	PROC
	AND	CH,POINTMASKHIGH
	JMPNZ	CHG2POINT	;[SI] を小数に CALL & RET

	XCHG	DI,SI
	CALL	CHG2POINT	;[DI] を小数に
	XCHG	DI,SI
	RET

MATCHTYPE	ENDP
%

;
;	整数を小数化する
;

CHG2POINT	PROC

	PUSH	SI
	PUSH	DI

	MOV	CX,[SI]
	MOV	DX,CX		;MEMO IT
	TEST	CH,POINTMASKHIGH
	JNZ	CHG2PRET	;既に小数
	AND	CX,LENMASK
	JZ	CHG2PRET	;0 はそのまま
	MOV	AX,[POINTWORD]
	OR	DH,POINTMASKHIGH	;小数化
	ADD	DX,AX
	MOV	[SI],DX
	ADD	SI,CX
	ADD	SI,CX		;元の最高位
	MOV	DI,SI
	ADD	DI,AX
	ADD	DI,AX		;結果の最高位
	ADD	AX,CX
	CMP	AX,LIMITWORD
	JA	CHG2POVR
	STD
	REP	MOVSW		;上位にスライド
	MOV	CX,[POINTWORD]
	XOR	AX,AX
	REP	STOSW		;下位をクリア
	CLD
CHG2PRET:
	POP	DI
	POP	SI
	RET

CHG2POVR:
	JMP	OVRERR

CHG2POINT	ENDP



;☆変数のINC,DEC

ID_UNDEF:
	JMP	UNDEFERR

INCIN:
	XOR	BX,BX
	MOV	BL,[BP]
	INC	BP
	CMP	BL,80H
	JE	inc_OPTION
	SUB	BL,VCODE
	JB	ID_SYNERR
	CMP	BL,6
	JAE	ID_SYNERR
	add	bx,bx
	ADD	BX,OFFSET INCTBL
	CALL	[BX]
INC_NEXT:
	CMP	BYTE PTR [BP],0C2H	;CODE OF ','
	JNE	INCDECOUT
	INC	BP
	JMP	INCIN

inc_option:
	cmp	byte ptr [bp],0f5h	;ema(
	jne	id_synerr2
	inc	bp
	jmp	incema


INCDECOUT:
	JMP	MAINLP


ID_SYNERR:
	SUB	BP,3
id_synerr2:
	JMP	SYNERR

DECIN:
	XOR	BX,BX
	MOV	BL,[BP]
	INC	BP
	CMP	BL,80H
	JE	dec_OPTION
	SUB	BL,VCODE
	JB	ID_SYNERR
	CMP	BL,6
	JAE	ID_SYNERR
	add	bx,bx
	ADD	BX,OFFSET DECTBL
	CALL	[BX]
DEC_NEXT:
	CMP	BYTE PTR [BP],0C2H	;CODE OF ','
	JNE	INCDECOUT
	INC	BP
	JMP	DECIN

dec_option:
	cmp	byte ptr [bp],0f5h	;ema(
	jne	id_synerr2
	inc	bp
	jmp	decema

	
;☆短変数のINC

SVINC:
	xor	ax,ax
	mov	al,[bp]
	inc	bp
	mov	di,[bp]
	add	bp,ax
	mov	ax,cs
	mov	ds,ax
svincin:
	MOV	AX,[DI]
	TEST	AH,signmaskhigh
	JNZ	SVINCJP		;if minus
	INC	AX
	TEST	AH,80H
	JNZ	SIOVRERR

SETSVAL:			;set new value
	MOV	[DI],AX
	MOV	AX,SS
	MOV	DS,AX
	RET

SIOVRERR:
	JMP	OVRERR

SVINCJP:			;if minus
	AND	AH,7FH		;cut sign
	DEC	AX
	JZ	SETSVAL
	OR	AH,80H
	JMP	SETSVAL

SVDEC:
	xor	ax,ax
	mov	al,[bp]
	inc	bp
	mov	di,[bp]
	add	bp,ax
	mov	ax,cs
	mov	ds,ax
SVDECIN:
	MOV	AX,[DI]
	TEST	AH,signmaskhigh
	JNZ	SVDECJP		;if minus

	SUB	AX,1
	JNC	SETSVAL		;if no borrow
	MOV	AX,8001H	;set -1
	JMP	SETSVAL

SVDECJP:			;(minus)-1=-((plus)+1)
	ADD	AX,1
	JNC	SETSVAL
	JMP	OVRERR



;☆長変数のINC,DEC
;SEGMENT はこちらで設定

LVINC:
	xor	ax,ax
	mov	al,[bp]
	inc	bp
	mov	bx,[bp]
	add	bp,ax

	MOV	DS,cs:[BX]
LVINC2:
	MOV	AX,SS:[MAXWORD]
	MOV	SS:[LIMITLEN],AX
LVINC3:
	XOR	DI,DI

LVINCIN:			;配列からも呼ばれる
	MOV	SI,DI		;MEMO FOR INCLEN
	MOV	CX,[DI]
	test	ch,attribmaskhigh
	jnz	lvincoption
	TEST	CH,signmaskhigh
	JNZ	LVINC50		;IF MINUS
	AND	CX,LENMASK
	JZ	LVINC90		;IF 0
	MOV	DX,CX		;MEMO LEN
	WINC	DI
	MOV	AX,1

LVINC10:
	ADD	[DI],AX
	JNC	LVINC20
	WINC	DI
	loop	LVINC10
	INC	DX
	CMP	DX,SS:[LIMITLEN]
	JA	LVINC30
	MOV	[DI],AX		;新最上位
	MOV	[SI],DX		;SET LEN
LVINC20:
	MOV	AX,SS
	MOV	DS,AX
	RET

lvincoption:
	jmp	ilgerr

LVINC30:
	JMP	OVRERR

	align	4,,3		;FOR MAKING LINCEVEN2 BE EVEN
LVINC50:
	AND	CX,LENMASK
	MOV	DX,CX		;MEMO LEN
	WINC	DI
	MOV	AX,1

LVINC60:
	SUB	[DI],AX
	JNC	LVINC70
	WINC	DI
	loop	LVINC60		;このループを全部回りきる事はない
LVINC70:
	JNZ	LVINC80		;not 0
	dec	cx
	jnz	lvinc80		;if not MSWord
	MOV	AX,[SI]
	DEC	AX
	CMP	AX,8000H
	JNE	LVINC75
	XOR	AX,AX		;-0 を避ける
LVINC75:
	MOV	[SI],AX
LVINC80:
	MOV	AX,SS
	MOV	DS,AX
	RET

LVINC90:
	MOV	AX,1
	MOV	[SI],AX
	MOV	[SI+2],AX
	JMP	LVINC80

INCDEC_ILG:
	JMP	ILGERR


LVDEC:
	xor	ax,ax
	mov	al,[bp]
	inc	bp
	mov	bx,[bp]
	add	bp,ax

	MOV	DS,cs:[BX]
LVDEC2:
	MOV	AX,SS:[MAXWORD]
	MOV	SS:[LIMITLEN],AX
LVDEC3:
	XOR	DI,DI

LVDECIN:			;配列からも呼ばれる
	MOV	SI,DI		;MEMO FOR DECLEN
	MOV	CX,[DI]
	TEST	CH,attribmaskhigh
	jnz	lvdecilg
	TEST	CH,signmaskhigh
	JZ	LVDEC50		;IF PLUS
	AND	CX,LENMASK
	MOV	DX,CX		;MEMO LEN
	WINC	DI
	MOV	AX,1

LVDEC10:
	ADD	[DI],AX
	JNC	LVDEC20
	WINC	DI
	loop	LVDEC10
	INC	DX
	CMP	DX,SS:[LIMITLEN]
	JA	LVDEC30
	MOV	[DI],AX		;SET 1
	OR	DH,signmaskhigh		;SET MINUS
	MOV	[SI],DX		;SET LEN
LVDEC20:
	MOV	AX,SS
	MOV	DS,AX
	RET

lvdecilg:
	jmp	ilgerr

LVDEC30:
	JMP	OVRERR

	myalign
LVDEC50:
	AND	CX,LENMASK
	JZ	LVDEC90		;IF 0
	MOV	DX,CX		;MEMO LEN
	WINC	DI
	MOV	AX,1
	DEC	CX
	JZ	LVDEC65

LVDEC60:
	SUB	[DI],AX
	JNC	LVDEC80		;途中で既に引けた
	WINC	DI
	loop	LVDEC60
LVDEC65:
	SUB	[DI],AX
	JNZ	LVDEC80		;最上位が0でない
	DEC	WORD PTR [SI]
LVDEC80:
	MOV	AX,SS
	MOV	DS,AX
	RET

LVDEC90:
	MOV	WORD PTR [SI],8001H	;SET -1
	MOV	WORD PTR [SI+2],1
	JMP	LVDEC80


;☆特別変数のINC,DEC
;SEGMENT はこちらで設定

LLVINC:
	xor	ax,ax
	mov	al,[bp]
	inc	bp
	mov	bx,[bp]
	add	bp,ax

	MOV	DS,cs:[BX]
LLVINC20:
	MOV	SS:[LIMITLEN],LIMITWORD
	JMP	LVINC3

LLVDEC:
	xor	ax,ax
	mov	al,[bp]
	inc	bp
	mov	bx,[bp]
	add	bp,ax

	MOV	DS,cs:[BX]
LLVDEC20:
	MOV	SS:[LIMITLEN],LIMITWORD
	JMP	LVDEC3

;☆配列短変数のINC

SAVINC:
	CALL	GETSAVADR
	JMP	SVINCIN


;☆配列短変数のDEC

SAVDEC:
	CALL	GETSAVADR
	JMP	SVDECIN


;☆配列長変数のINC,DEC

LAVINC:
	CALL	GETLAVADR
	MOV	AX,SS:[MAXWORD]
	MOV	SS:[LIMITLEN],AX
	JMP	LVINCIN

LAVDEC:
	CALL	GETLAVADR
	MOV	AX,SS:[MAXWORD]
	MOV	SS:[LIMITLEN],AX
	JMP	LVDECIN


;☆配列特別変数のINC,DEC

LLAVINC:
	CALL	GETLLAVADR
	MOV	SS:[LIMITLEN],LIMITWORD
	JMP	LVINCIN


LLAVDEC:
	CALL	GETLLAVADR
	MOV	SS:[LIMITLEN],LIMITWORD
	JMP	LVDECIN



GOCLRBLOCK:
	JMP	CLRBLOCK


CLRIN:
	CMP     BYTE PTR [BP],0A2H	;BLOCK
	JE	GOCLRBLOCK

	XOR	BX,BX
	MOV	BL,[BP]

	INC	BP
	CMP	BL,80H
	JE	CLR_OPTION
	SUB	BL,VCODE
	JB	CLR_SYNERR
	CMP	BL,6
	JAE	clr_synerr
	add	bx,bx
	ADD	BX,OFFSET CLRTBL
	CALL	[BX]
CLR_NEXT:
	CMP	BYTE PTR [BP],0C2H	;CODE OF ','
	JNE	CLR_OUT
	INC	BP
	JMP	CLRIN

CLR_OUT:
	JMP	MAINLP

CLR_SYNERR:
	SUB	BP,3
CLR_ERR:
	JMP	SYNERR

CLR_OPTION:
	CMP	BYTE PTR [BP],0f5H	;ema
	je	goclrema
	CMP	BYTE PTR [BP],9AH	;TIME
	JMPNZ	SYNERR
	INC	BP
	JMP	CLRTIME
goclrema:
	inc	bp
	jmp	clrema


CLR_UNDEF:
	JMP	UNDEFERR

	
;☆短変数のCLR

SVCLR:
	xor	ax,ax
	mov	al,[bp]
	inc	bp
	mov	bx,[bp]
	add	bp,ax

	MOV	WORD PTR cs:[BX],0
	RET

;☆長変数のCLR
;SEGMENT はこちらで設定

LVCLR:
	xor	ax,ax
	mov	al,[bp]
	inc	bp
	mov	bx,[bp]
	add	bp,ax

	MOV	DS,cs:[BX]
LVCLR20:
	XOR	DI,DI

LVCLRIN:
	MOV	WORD PTR [DI],0
	MOV	AX,SS
	MOV	DS,AX
	RET

;☆特別変数のCLR,DEC
;SEGMENT はこちらで設定

LLVCLR:
	xor	ax,ax
	mov	al,[bp]
	inc	bp
	mov	bx,[bp]
	add	bp,ax

	MOV	DS,cs:[BX]
	JMP	LVCLR20


;☆配列短変数のCLR

SAVCLR:
	CALL	GETSAVADR
	JMP	LVCLRIN


;☆配列長変数のCLR

LAVCLR:
	CALL	GETLAVADR
	JMP	LVCLRIN


;☆配列特別変数のCLR

LLAVCLR:
	CALL	GETLLAVADR
	JMP	LVCLRIN


;☆変数の NEGATE

GONEGBLOCK:
	JMP	NEGBLOCK

NEGIN:
	CMP     BYTE PTR [BP],0A2H	;BLOCK
	JE	GONEGBLOCK

	XOR	BX,BX
	MOV	BL,[BP]
	INC	BP
	cmp	bl,80h
	je	neg_option
	SUB	BL,VCODE
	JB	NEG_SYNERR
	CMP	BL,6
	JAE	NEG_synerr
	add	bx,bx
	ADD	BX,OFFSET NEGTBL
	CALL	[BX]
NEG_NEXT:
	CMP	BYTE PTR [BP],0C2H	;CODE OF ','
	JNE	NEG_OUT
	INC	BP
	JMP	NEGIN

NEG_OUT:
	JMP	MAINLP

NEG_SYNERR:
	SUB	BP,3
neg_synerr2:
	JMP	SYNERR

neg_option:
	cmp	byte ptr [bp],0f5h	;ema(
	jne	neg_synerr2
	inc	bp
	jmp	negema

	
;☆短変数のNEG

SVNEG:
	xor	ax,ax
	mov	al,[bp]
	inc	bp
	mov	bx,[bp]
	add	bp,ax

	CMP	WORD PTR cs:[BX],0
	JE	SVNEGRET	;if 0
	XOR	WORD PTR cs:[BX],8000H	;change sign
SVNEGRET:
	RET

;☆長変数のNEG
;SEGMENT はこちらで設定

LVNEG:
	xor	ax,ax
	mov	al,[bp]
	inc	bp
	mov	bx,[bp]
	add	bp,ax

	MOV	DS,cs:[BX]
LVNEG20:
	xor	si,si		;	XOR	DI,DI

LVNEGIN:
	call	negallsi
	mov	ax,ss
	mov	ds,ax
	ret

comment %
lvnegoption:
	test	ah,nonnumericmaskhigh
	jnz	negpoly?
	test	ah,complexmaskhigh
	jnz	negcomplex
	test	ah,ratmaskhigh
	jnz	negrational
negilg:
	jmp	ilgerr
negrational:
	add	di,2
	mov	ax,[di]
	jmp	lvnegnormal

negcomplex:
	add	di,2
	mov	ax,[di]		;real part
	or	ax,ax
	jz	negcomplex10
	xor	ah,signmaskhigh		;change sign
	mov	[di],ax
negcomplex10:
	and	ax,lenmask
	inc	ax
	add	ax,ax
	add	di,ax

	mov	ax,[di]		;imaginary part
	or	ax,ax
	jnz	lvnegnormal
	jmp	lvnegret

negpoly?:
	and	ah,attribmaskhigh
	cmp	ah,polymaskhigh
	jne	negmodpoly?
	mov	bx,di
	call	go_sign_poly
	jmp	lvnegret
negmodpoly?:
	cmp	ah,modpolymaskhigh
	jne	negratfunc?
	mov	bx,di
	call	go_sign_modpoly
	jmp	lvnegret
negratfunc?:
	cmp	ah,ratpolymaskhigh
	jne	negilg
	add	di,2		;skip attribute
	mov	ax,[di]
	jmp	negpoly?
%


;☆特別変数のNEG
;SEGMENT はこちらで設定

LLVNEG:
	xor	ax,ax
	mov	al,[bp]
	inc	bp
	mov	bx,[bp]
	add	bp,ax

	MOV	DS,cs:[BX]
	JMP	LVNEG20


;☆配列短変数のNEG

SAVNEG:
	CALL	GETSAVADR
	mov	si,di
	JMP	LVNEGIN


;☆配列長変数のNEG

LAVNEG:
	CALL	GETLAVADR
	mov	si,di
	JMP	LVNEGIN


;☆配列特別変数のNEG

LLAVNEG:
	CALL	GETLLAVADR
	mov	si,di
	JMP	LVNEGIN

;*
;*  COMPARE ( it may destroy data )
;*  data must on [calcsp+unitbyte] and [calcsp]
;
compare:
;  in : al=code( >2,<4,>=3,<=5 )
	mov	si,[calcsp]
	lea	di,[si+unitbyte]	;do not store di in [calcsp]
	push	ax			;because sp-1 is used by comparein
	call	comparein
compare10:
	pop	dx
	xor	cx,cx
	and	al,dl
	jz	compare20
	inc	cx
compare20:
	mov	di,[calcsp]
	add	di,unitbyte
	mov	[calcsp],di
	mov	[di],cx
	mov	[di+2],cx
	ret

; *
; * check equality(data will be destroyed)
; *

check_equal:
;  in : al=code( =1,<>6 )

	mov	si,[calcsp]
	lea	di,[si+unitbyte]
	mov	[calcsp],di
	push	ax
	call	isequal			; data is on [calcsp]
	pop	dx
	xor	cx,cx
	and	al,dl
	jz	checkeq20
	inc	cx
checkeq20:
	mov	di,[calcsp]
	mov	[di],cx
	mov	[di+2],cx
	ret


;
;* compare main routine
;  out:	al= 1 true, 0 false

;
; * subroutine of compare
;  in  : di,si
;  out : al=1 [di]=[si]
;        al=2 [di]>[si]
;        al=4 [di]<[si]
;  also called from MIN,MAX
;  must be non-destructive

comparein:
	mov	cx,[di]
	mov	dx,[si]
	mov	al,ch
	mov	ah,dh
	test	ax,attribmaskdouble
	jz	cmp_integer_integer
	and	ax,attribmaskdouble
	cmp	ax,pointmaskdouble
	je	gocmp_float_float
	jmp	cmp_extra

gocmp_float_float:
	jmp	cmp_float_float

compare_direct0:
	mov	si,[calcsp]
	lea	di,[si+unitbyte]
compare_direct:
	mov	cx,[di]
	mov	dx,[si]
	mov	al,ch
	mov	ah,dh
cmp_integer_integer:
	and	cx,lenmask
	and	dx,lenmask
	test	al,signmaskhigh
	jnz	compareii20	;if [di]<0
	test	ah,signmaskhigh
	jnz	di_bigger	;if [di]>=0 & [si]<0
;if both >= 0
	cmp	cx,dx
	jb	si_bigger
	ja	di_bigger
	jcxz	disi_equal	;if both=0

	add	cx,cx
	add	di,cx
	add	si,cx
	mov	cx,dx
	std
	repe	cmpsw
	cld
	je	disi_equal	;[si]=[di]
	jb	di_bigger	;[si]<[di]
si_bigger:			;[si]>[di]
	mov	al,4
	ret
di_bigger:
	mov	al,2
	ret
disi_equal:
	mov	al,1
	ret

compareii20:
	test	ah,signmaskhigh
	jz	si_bigger	;if [di]<0 & [si]>=0
;if both < 0
	cmp	cx,dx
	jb	di_bigger
	ja	si_bigger
	add	cx,cx
	add	di,cx
	add	si,cx
	mov	cx,dx
	std
	repe	cmpsw
	cld
	je	disi_equal
	ja	di_bigger
	jmp	si_bigger


cmp_data_types	equ	3


cmp_extra:
	xor	bx,bx
	or	al,al
	jz	compextra20
	add	bx,cmp_data_types
	cmp	al,pointmaskhigh
	je	compextra20
	add	bx,cmp_data_types
	cmp	al,ratmaskhigh
	je	compextra20
	cmp	ax,stringmaskdouble
	jne	compareilg
	jmp	compare_strings
compextra20:
	or	ah,ah
	jz	compextra40
	inc	bx
	cmp	ah,pointmaskhigh
	je	compextra40
	inc	bx
	cmp	ah,ratmaskhigh
	je	compextra40
compareilg:
	jmp	ilgerr


compextra40:
	add	bx,bx
	jmp	cs:[cmp_table+bx]


cmp_table	label	word
	dw	ilgerr,cmp_integer_float,cmpDIintSIrat
	dw	cmp_float_integer,ilgerr,cmp_float_rational
	dw	cmpDIratSIint,cmp_rational_float,cmpDIratSIrat


cmpDIratSIintcalcsperr:
	jmp	calcsperr

cmpDIratSIint:
	mov	bx,[calcsp]
	sub	bx,unitbyte
	cmp	bx,[calcsp_limit]
	jb	cmpDIratSIintcalcsperr
	lea	si,[di+2]
	lodsw
	and	ax,lenmask
	add	si,ax
	add	si,ax
	mov	di,bx
	copy_si2di		;copy den of di -> sp[-1]
	mov	di,bx
	lea	si,[bx+unitbyte]
	call	mulIIdisi		;mul int to den of di
	mov	di,[calcsp]
	lea	si,[di-unitbyte]	;sp[-1]
	add	di,unitbyte+2		;original num of di
	jmp	compare_direct

cmpDIintSIratcalcsperr:
	jmp	calcsperr

cmpDIintSIrat:
	mov	bx,[calcsp]
	sub	bx,unitbyte
	cmp	bx,[calcsp_limit]
	jb	cmpDIintSIratcalcsperr
	add	si,2
	lodsw
	and	ax,lenmask
	add	si,ax
	add	si,ax
	mov	di,bx
	copy_si2di		;copy den to sp[-1]
	mov	di,bx
	lea	si,[di+2*unitbyte]	;mul int to sp[-1]
	call	mulIIdisi
	mov	si,[calcsp]
	mov	di,si
	add	si,2		;num of [sp0]
	sub	di,unitbyte	;[sp-1]
	jmp	compare_direct

cmpDIratSIratcalcsperr:
	jmp	calcsperr

cmpDIratSIrat:
	mov	bx,[calcsp]
	sub	bx,2*unitbyte
	cmp	bx,[calcsp_limit]	;bx=sp[-2]
	jb	cmpDIratSIratcalcsperr
	add	si,2
	lodsw
	and	ax,lenmask
	add	si,ax
	add	si,ax
	mov	di,bx
	copy_si2di		;copy den of si to sp[-2]
	lea	di,[bx+3*unitbyte]
	lea	si,[di+2]
	lodsw
	and	ax,lenmask
	add	si,ax
	add	si,ax
	lea	di,[bx+unitbyte]
	copy_si2di		;copy den of di to sp[-1]
	lea	si,[bx+3*unitbyte+2]
	mov	di,bx
	call	mulIIdisi	;mul num of di to sp[-2]
	mov	si,[calcsp]
	lea	di,[si-unitbyte]
	add	si,2
	call	mulIIdisi		;mul num of si to sp[-1]
	mov	si,[calcsp]
	lea	di,[si-2*unitbyte]	;sp[-2]
	sub	si,unitbyte		;sp[-1]
	jmp	compare_direct

;
; compare string
;
compare_strings:
	mov	cx,[di]
	add	di,2
	add	cx,cx
	sbb	cx,0
	and	cx,2*lenmask+1
	lodsw
	add	ax,ax
	sbb	ax,0
	and	ax,2*lenmask+1
	cmp	ax,cx
	je	cmpstreqlen	;equal length
	jb	cmpstrdilonger
cmpstrsilonger:
	jcxz	cmpstrsibigger	;if [DI]=null
	repe	cmpsb
	jae	cmpstrsibigger
cmpstrdibigger:
	jmp	di_bigger

cmpstrdilonger:
	mov	cx,ax
	jcxz	cmpstrdibigger	;if [SI]=null
	repe	cmpsb
	jbe	cmpstrdibigger
cmpstrsibigger:
	jmp	si_bigger

cmpstreqlen:
	repe	cmpsb
	ja	cmpstrsibigger
	jb	cmpstrdibigger
	jmp	disi_equal


;
; isequal
; check  only equal or not equal for any numeric data
; in  : di,si address of data
; out : al =1 if equal, 6 if not equal
;       di,si next address
;  data may not on [calcsp]

farisequal_calcsp:
	mov	di,[calcsp]
	lea	si,[di-unitbyte]
	call	isequal
	retf


equ_II:
equ_RatRat:
equ_MPMP:
equ_SS:
	mov	cx,[di]
	mov	dx,[si]
	add	di,2
	add	si,2
	cmp	cx,dx
	jne	nonequ_skipall
	and	cx,lenmask
	repe	cmpsw
	jne	nonequ_skiprest
	mov	al,1
	ret
nonequ_skiprest:
	mov	al,6
	add	cx,cx
	add	di,cx
	add	si,cx
	ret

goequ_PLPL:
	jmp	equ_poly_poly
goequ_pack_pack:
	jmp	equ_pack_pack


isequal:
isequal_real:
	mov	al,[di+1]
	mov	ah,[si+1]
	and	ax,attribmaskdouble
	jz	equ_II
	cmp	al,ah
	jne	equ_difftype
	cmp	al,ratmaskhigh
	je	equ_ratrat
	cmp	al,complexmaskhigh
	je	equ_CC
	cmp	al,pointmaskhigh
	je	equ_FF
	cmp	al,polymaskhigh
	je	goequ_PLPL
	cmp	al,modpolymaskhigh
	je	equ_MPMP
	cmp	al,ratpolymaskhigh
	je	equ_RFRF
	cmp	al,stringmaskhigh
	je	equ_SS
	cmp	al,packmaskhigh
	je	goequ_pack_pack
	jmp	ilgerr

equ_FF:
equ_IF:
equ_FI:
equ_ratF:
equ_Frat:
	push	si
	push	di
	call	comparein
	pop	di
	pop	si
;skipall:
	mov	cx,[di]
	mov	dx,[si]
	and	cx,lenmask
	and	dx,lenmask
	inc	cx
	inc	dx
	add	di,cx
	add	di,cx
	add	si,dx
	add	si,dx
	ret

goequ_poly1:
	jmp	equ_poly1
goequ_poly2:
	jmp	equ_poly2
goequ_modpoly1:
	jmp	equ_modpoly1
goequ_modpoly2:
	jmp	equ_modpoly2

equ_difftype:
	cmp	ax,pointmask
	je	equ_IF
	cmp	ax,pointmaskhigh
	je	equ_FI
	cmp	ax,pointmask+ratmaskhigh
	je	equ_ratF
	cmp	ax,ratmask+pointmaskhigh
	je	equ_Frat

	cmp	al,polymaskhigh
	je	goequ_poly1
	cmp	ah,polymaskhigh
	je	goequ_poly2
	cmp	al,modpolymaskhigh
	je	goequ_modpoly1
	cmp	ah,modpolymaskhigh
	je	goequ_modpoly2
	jmp	nonequ_skipall2

nonequ_skipall:
	mov	al,6
isequal_skipall:
	add	cx,cx
	add	dx,dx
	add	di,cx
	add	si,dx
	ret
nonequ_skipall3:
	mov	cx,[di]
	mov	dx,[si]
	and	cx,lenmask
	and	dx,lenmask
nonequ_skipall2:
	add	si,2
	add	di,2
	jmp	nonequ_skipall


equ_RFRF:
equ_CC:
	add	di,2
	add	si,2
	call	isequal
	cmp	al,1
	jne	nonequ_skipall3
	jmp	isequal		;call & ret


;
; check equality of polynomials & packed data
;
equ_poly_poly:
equ_pack_pack:
	mov	cx,[di]
	mov	dx,[si]
	add	di,2
	add	si,2
	and	cx,lenmask
	and	dx,lenmask
	add	cx,cx
	add	dx,dx
	add	cx,di
	add	dx,si
	push	cx		;new DI adr
	push	dx		;new SI adr
	mov	cx,[di]		;# of data
	cmp	cx,[si]
	jne	equplnequ
	jcxz	equpl20		;both empty
	add	di,2
	add	si,2
equpl10:
	push	cx
	call	isequal		;data is on [calcsp] not always on top
	pop	cx
	cmp	al,1
	jne	equplnequ
	loop	equpl10
equpl20:
	mov	al,1
	pop	si
	pop	di
	ret
equplnequ:
	mov	al,6
	pop	si
	pop	di
	ret


equ_poly2:
	cmp	word ptr [si+2],1
	jne	equpolyskipall	;if degree <> 0
	add	si,4
	jmp	isequal

equ_poly1:
	cmp	word ptr [di+2],1
	jne	equpolyskipall	;if degree <> 0
	add	di,4
	jmp	isequal
equpolyskipall:
	mov	cx,[di]
	mov	dx,[si]
	and	cx,lenmask
	and	dx,lenmask
	add	cx,cx
	add	dx,dx
	add	di,cx
	add	si,dx
	mov	al,6
	ret

equ_modpoly1:
	;compare modpoly with integer

	cmp	word ptr [di],modpolymask+4
	jne	equpolyskipall	;if degree <> 0
	mov	ax,[si]
	set32
	mov	dx,[si+2]
	cmp	ax,2
	je	eqump1_10
	cmp	ax,1
	jne	equpolyskipall	;if not integer of 1or2 word
	set32
	shl	dx,16		;cut higher 16 bit
	set32			;
	shr	dx,16		;
eqump1_10:
	add	di,10		;next adr
	add	si,4		;next adr
	mov	al,1
	set32
	cmp	dx,[di-4]
	je	equmodpolyret
	mov	al,6
equmodpolyret:
	ret

equ_modpoly2:
	cmp	word ptr [si],modpolymask+4
	jne	equpolyskipall	;if degree <> 0
	mov	ax,[di]
	set32
	mov	dx,[di+2]
	cmp	ax,2
	je	eqump2_20
	cmp	ax,1
	jne	equpolyskipall	;if not integer of 1 word
	set32
	shl	dx,16		;cut higher 16bit
	set32
	shr	dx,16		;cut higher 16 bit
eqump2_20:
	add	si,10		;next adr
	add	di,4		;next adr
	mov	al,1
	set32
	cmp	dx,[si-4]
	je	equmodpolyret
	mov	al,6
	jmp	equmodpolyret


;
; * POWER X^Y
;

gopowYbigXrational:
	jmp	powYbigXrational

powYbig:			;if >= 2 words power
	checkcalcsp	2
	mov	si,[xmem]
	lodsw
	test	ah,ratmaskhigh
	jnz	gopowYbigXrational
	cmove	2,0
	mov	si,[xmem]
	sub	si,unitbyte
	mov	[calcsp],si	;(+1)
	mov	[pmem],si	;address of original y
	sub	si,unitbyte
	mov	[ymem],si
	mov	ax,[si]
	test	ah,complexmaskhigh
	jnz	powYbigXcomplex

	mov	si,[pmem]
	mov	cx,[si]
	add	si,cx
	add	si,cx		;highest adr
	mov	bx,[si]
	cmp	bx,1
	je	powbig10
	push	cx
	push	si
	call	pow_main	;1st word
	pop	si
	pop	cx
powbig10:
	dec	cx
	wdec	si
powbiglp:			;other words
	push	cx
	push	si
	mov	cx,16
	mov	bx,[si]
	call	pow_main2
	pop	si
	wdec	si
	pop	cx
	loop	powbiglp

	add	[calcsp],unitbyte
	ret


SETX1:
	MOV	AX,1
	STOSW
	STOSW
	JMP	POWOUT

POW_ILG:
	JMP	ILGERR		;ILLEGAL FT CALL

;//XEQPM1:
;	test	ah,signmaskhigh
;	JZ	POWOUT2			;if plus
;	AND	WORD PTR [SI+2],1
;	JNZ	POWOUT2			;if Y is odd
;	AND	WORD PTR [DI],7FFFH	;set plus
POWOUT2:
	RET

GOOVRERR:
	JMP	OVRERR

power_extra:
	and	ah,lenmaskhighcpl
	cmp	ah,polymaskhigh
	je	go_power_poly
	cmp	ah,modpolymaskhigh
	je	go_power_modpoly
	cmp	ah,packmaskhigh
	je	go_overloadpower	;[di] is pack
	jmp	ilgerr
go_power_poly:
	jmp	far ptr power_poly
go_power_modpoly:
	jmp	far ptr power_modpoly
go_overloadpower:
	jmp	overloadpower


gopowsquare:
	jmp	squareIFCdi

gopowYpointcomprat:
	jmp	powYpointcomprat


farPower_calcsp:
	mov	di,[calcsp]
	lea	si,[di-unitbyte]
	call	power_nobacksp
	retf


powerin:
	call	backsp
power_nobacksp:
	mov	[xmem],di	;cannot be recursively called
	mov	[ymem],si

	mov	ax,[di]
	test	ah,nonnumericmaskhigh
	jnz	power_extra

	mov	cx,[si]
	test	ch,nonnumericmaskhigh
	jnz	pow_ilg		
	jcxz	setx1		;if Y=0 then ans=1(superior to X=0)
				;1 or 1.0???
	mov	bx,ax
	and	ah,attribmaskhigh
	and	bx,lenmask
	jz	powout2		;if X=0 then ans=0

	test	ch,pointcomprathigh
	jnz	gopowYpointcomprat ;if Y is not an integer

;	CMP	BX,1
;	JNZ	POWJ1

;	CMP	WORD PTR [DI+2],1
;	jne	POWJ1
;	test	word ptr [di],pointmask
;	jz	XEQPM1		;if X=+-1
;POWJ1:

	test	ch,signmaskhigh
	callnz	powerinverse	;if Y<0 then let X=1/X
	cmp	cx,2
	jae	powYbig		;if power index>=2words

	;X^(1 word positive integer)

	mov	bx,[si+2]	;bx = value of Y
	test	ah,compratmaskhigh
	jnz	powXcomplexrat

	cmp	bx,2
	je	gopowsquare	;if power=2

	cmp	bx,1
	je	powout		;if power=1 do nothing

	mov	si,[xmem]
	mov	di,[ymem]
	copy_si2di

;  main part  [xmem]=[xmem]^BX
;  use mulwork
;  before call must set
;  xmem base adr
;  ymem work area
;  and set the same data in [xmem] and [ymem]

pow_main:
	mov	cx,16
powmain10:
	add	bx,bx		;bx > 1 is already checked
	dec	cx
	jnc	powmain10
pow_main2:
powmain20:
	push	cx
	mov	di,[xmem]
	push	bx
	call	squareIFCdi
	pop	bx
	add	bx,bx
	jnc	powmain30

	mov	di,[xmem]
	mov	si,[ymem]
	push	bx
	call	mulIorFdisi
	pop	bx
powmain30:
	pop	cx
	loop	powmain20

powout:
	ret


powXcomplexrat:
	CMP	BX,1
	JE	POWOUT		;巾が1ならば何もせず

	MOV	SI,[XMEM]	;copy X to Y
	MOV	DI,[YMEM]
	MOV	CX,[SI]
	test	ch,ratmaskhigh
	jnz	gopowXrational
	jmp	powXcomplex
gopowXrational:
	jmp	powXrational


powYpointcomprat:
	and	ch,attribmaskhigh
	cmp	ch,pointmaskhigh
	je	gopowYfloat
	cmp	ch,complexmaskhigh
	je	gopowYcomplex
	jmp	ilgerr
gopowYcomplex:
	jmp	powYcomplex
gopowYfloat:
	jmp	powYfloat


	;if Y<0 then let X=1/X

powerinverse:
	push	si
	push	di

	and	ch,signmaskhighCPL
	mov	[si],cx
	mov	si,[calcsp]
	sub	si,unitbyte*3
	mov	[calcsp],si		;(+3)
	mov	ax,1
	mov	[si+unitbyte],ax
	mov	[si+unitbyte+2],ax
	mov	di,si
	mov	si,[XMEM]
	copy_si2di
	call	ratdivin		;(+2)
	mov	si,[calcsp]
	lea	di,[si+2*unitbyte]
	mov	[calcsp],di	;(+0)
	mov	cx,[si]

	mov	ax,cx

	and	cx,lenmask
	inc	cx
	rep	movsw

	pop	di
	pop	si
	mov	cx,[si]
	ret


;
;
;** integer division principal routine
;
; (DI)=INT((DI)/(SI))
; RESADR=AMARI
; 割り算は余りが 0 以上 ABS((SI)) 未満になるように行われます
; 例 １割る３は商  ０余り１ですが
;  －１割る３は商－１余り２になります


farIdiv_calcsp:
	mov	di,[calcsp]
	lea	si,[di-unitbyte]
	call	Idiv_nobacksp
	retf


go_idiv_poly1:
	jmp	far ptr idiv_pl

go_idiv_modpoly1:
	jmp	far ptr idiv_mpl

go_overloadidiv:
	jmp	overloadidiv

idiv_etc:
	cmp	ax,pointmaskdouble
	je	idiv_float_float	;float\float
	cmp	ax,pointmask
	je	idiv_integer_float	;int\float
	cmp	ax,pointmaskhigh
	je	idiv_float_integer	;float\int

	cmp	al,packmaskhigh
	je	go_overloadidiv		;[di] is pack
	cmp	ah,packmaskhigh
	je	go_overloadidiv		;[si] is pack

	cmp	al,polymaskhigh
	je	go_idiv_poly1		;[di] is poly
	cmp	al,modpolymaskhigh
	je	go_idiv_modpoly1	;[di] is modpoly

	cmp	ah,polymaskhigh
	je	go_idiv_poly2		;[si] is poly
	cmp	ah,modpolymaskhigh
	je	go_idiv_modpoly2	;[si] is modpoly
idivilg:
	jmp	ilgerr

go_idiv_poly2:
go_idiv_modpoly2:
	cmp	word ptr [di],0
	jne	idivilg		;non0scalar\poly is undefined
	mov	bx,resadr	;if 0\poly
	mov	word ptr [bx],0	;set remainder=0
	ret


IDIVIN:
	CALL	BACKSP
idiv_nobacksp:
	mov	al,[di+1]
	mov	ah,[si+1]
	and	ax,attribmaskdouble
	jnz	idiv_extra
	jmp	idivIIdisi		;both integers

idiv_extra:
	cmp	ax,complexmaskhigh	;al=complexmaskhigh,ah=0
	jne	idiv_etc
	jmp	idiv_complex


;
; ** remainder
;

farRes_calcsp:
	mov	di,[calcsp]
	lea	si,[di-unitbyte]
	call	Resin_nobacksp
	retf

RESIN:	
	CALL	BACKSP
resin_nobacksp:
	mov	al,[di+1]
	mov	ah,[si+1]
	and	ax,attribmaskdouble
	jnz	res_extra
	call	idivIIdisi
resout:
	MOV	SI,RESADR
	MOV	DI,[CALCSP]
	copy_si2di
	RET	

res_extra:
	cmp	ax,complexmaskhigh	;al=complex,ah=int
	jne	res_ex10
res_ci:
	call	idiv_complex
	jmp	resout

res_ex10:
	cmp	ax,pointmaskdouble	
	jne	res_ex20
res_ff:
	mov	bx,[di]
	and	bx,lenmask
	dec	bx
	add	bx,bx
	sub	bx,[di+2]		;bias
	neg	bx
	cmp	bx,[si+2]
	jge	res_floaterror
	call	idiv_float_float	;float\float
	jmp	resout

res_ex20:
	cmp	ax,pointmask
	jne	res_ex30
res_if:
	mov	bx,[di]
	mov	cx,[si]
	and	bx,lenmask
	and	cx,lenmask
	dec	cx
	sub	bx,cx
	jae	res_if20
res_if10:
	add	bx,bx
	cmp	bx,[si+2]		;bias
	jl	res_ifin
	jmps	res_floaterror
res_if20:
	cmp	word ptr [si+2],0	;bias
	jle	res_floaterror
res_ifin:
	call	idiv_integer_float	;int\float
	jmp	resout

res_ex30:
	cmp	ax,pointmaskhigh	
	jne	res_ex40
res_fi:
	mov	bx,[di]
	and	bx,lenmask
	dec	bx
	add	bx,bx
	sub	bx,[di+2]		;bias
	neg	bx
	sar	bx,1
	mov	cx,[si]
	and	cx,lenmask
	cmp	bx,cx
	jge	res_floaterror
	call	idiv_float_integer	;float\int
	jmp	resout
res_ex40:
	cmp	al,polymaskhigh
	je	res_poly_if
res_ex50:
	cmp	ax,packmaskdouble
	je	go_overloadmod
	call	idiv_etc
	jmp	resout

res_poly_if:				;poly @ int|float
	test	ah,compratstrpackmaskhigh
	jnz	res_ex50
	mov	[poly_operation],offset farRes_calcsp
	jmp	far ptr poly_scalar	;call & ret
go_overloadmod:
	jmp	overloadmod

res_floaterror:
	jmp	floaterr


;
;* subtraction entry
;  [di]=[di]-[si]
;

farsub_calcsp:
	mov	di,[calcsp]
	lea	si,[di-unitbyte]
farsubAAdisi:
	call	subAAdisi
	retf

farsubin:
	call	subin
	retf


SUBIN:
	call	backsp

subIIdisi:
subAAdisi:
subin_nobacksp:
	;change sign and go ADD

	mov	al,[di+1]
	mov	ah,[si+1]
	and	ax,attribmaskdouble
	jnz	sub_extra
	jmp	llsub

sub_chgsign_if:
	mov	ax,[si]
	or	ax,ax
	jz	go_addAAdisi
	xor	ax,signmask		;change sign
	mov	[si],ax
go_addAAdisi:
	jmp	addAAdisi


sub_extra:
	test	ax,nonnumericmaskdouble
	jnz	sub_etc0

	or	ah,ah
	jz	sub_chgsign_if		;[si] is int
	cmp	ah,pointmaskhigh
	je	sub_chgsign_if		;[si] is float

	cmp	ah,ratmaskhigh
	je	sub_rational2		;[si] is rational
	cmp	ah,complexmaskhigh
	je	sub_complex2		;[si] is complex
	jmp	ilgerr

sub_rational2:
	xor	byte ptr [si+3],signmaskhigh	;change sign of num
	jmp	addAAdisi

sub_complex2:
	mov	bx,[si+2]
	or	bx,bx
	jz	subcomplex10
	xor	bh,signmaskhigh
	mov	[si+2],bx
subcomplex10:
	and	bx,lenmask
	add	bx,2
	add	bx,bx
	add	bx,si
	xor	byte ptr [bx+1],signmaskhigh	;change sign
	jmp	addAAdisi

sub_ret:
	ret

go_sub_poly1:
	jmp	far ptr sub_pl
go_sub_modpoly1:
	jmp	far ptr sub_mpl
go_sub_ratpoly1:
	jmp	far ptr sub_rf		;rational functions

sub_etc0:
	cmp	al,packmaskhigh
	je	go_sub_overload		;[di] is pack
	cmp	ah,packmaskhigh
	je	go_sub_overload		;[si] is pack

	cmp	word ptr [si],0
	je	sub_ret			;if [si] = 0

	cmp	al,polymaskhigh
	je	go_sub_poly1		;[di] is poly
	cmp	al,modpolymaskhigh
	je	go_sub_modpoly1		;[di] is modpoly
	cmp	al,ratpolymaskhigh
	je	go_sub_ratpoly1		;[di] is rational function

	cmp	ah,polymaskhigh
	je	go_sub_poly2		;[si] is poly
	cmp	ah,modpolymaskhigh
	je	go_sub_modpoly2		;[si] is modpoly
	cmp	ah,ratpolymaskhigh
	je	go_sub_ratpoly2		;[si] is rational function
	jmp	ilgerr

go_sub_overload:
	jmp	overloadsub

go_sub_poly2:
	jmp	far ptr sub_numpl
go_sub_modpoly2:
	jmp	far ptr sub_nummpl
go_sub_ratpoly2:
	jmp	far ptr sub_numrf	;rational functions


;
;* multiplication entry
;
;   [DI]=[DI]*[SI]
;

farmulin:
	call	mulin
	retf

farMul_calcsp:
	mov	di,[calcsp]
	lea	si,[di-unitbyte]
farmulAAdisi:
	call	mulAAdisi
	retf


	align	4
mulin:
	call	backsp
mulAAdisi:
	mov	al,[di+1]
	mov	ah,[si+1]
	and	ax,attribmaskdouble
	jnz	mul_extra
mul_integer_integer:
	jmp	mulIIdisi

mul_data_types	equ	4

mul_extra:
	xor	bx,bx
	or	al,al
	jz	mulextra20
	add	bx,mul_data_types
	cmp	al,pointmaskhigh
	je	mulextra20
	add	bx,mul_data_types
	cmp	al,complexmaskhigh
	je	mulextra20
	add	bx,mul_data_types
	cmp	al,ratmaskhigh
	je	mulextra20
	jmp	mul_etc
mulextra20:
	or	ah,ah
	jz	mulextra40
	inc	bx
	cmp	ah,pointmaskhigh
	je	mulextra40
	inc	bx
	cmp	ah,complexmaskhigh
	je	mulextra40
	inc	bx
	cmp	ah,ratmaskhigh
	je	mulextra40
	jmp	mul_etc2
mulextra40:
	add	bx,bx
	jmp	cs:[mul_table+bx]


go_mul_poly1:
	jmp	far ptr mul_pl

go_mul_modpoly1:
	jmp	far ptr mul_mpl

go_mul_ratfunc:
	jmp	far ptr mul_rf


mul_etc:
	cmp	al,polymaskhigh
	je	go_mul_poly1		;[di] is poly
	cmp	al,modpolymaskhigh
	je	go_mul_modpoly1		;[di] is modpoly
	cmp	al,ratpolymaskhigh
	je	go_mul_ratfunc		;[di] is rational function
	cmp	al,packmaskhigh
	je	go_mul_overload		;[di] is pack
	jmp	ilgerr

mul_etc2:
	cmp	ah,polymaskhigh
	je	go_mul_poly2		;[si] is poly
	cmp	ah,modpolymaskhigh
	je	go_mul_modpoly2		;[si] is modpoly
	cmp	ah,ratpolymaskhigh
	je	go_mul_ratpoly2		;[si] is rational func
	cmp	ah,packmaskhigh
	je	go_mul_overload		;[si] is pack
mul_etc2ilg:
	jmp	ilgerr

go_mul_poly2:
	jmp	far ptr mul_numpl

go_mul_modpoly2:
	jmp	far ptr mul_nummpl

go_mul_ratpoly2:
	jmp	far ptr mul_numrf

go_mul_overload:
	jmp	overloadmul


mul_table	label	word
	dw	mul_integer_integer,mul_integer_float
	dw	mul_integer_complex,mul_integer_rational

	dw	mul_float_integer,mul_float_float
	dw	mul_float_complex,mul_float_rational

	dw	mul_complex_integer,mul_complex_float
	dw	mul_complex_complex,mul_complex_rational

	dw	mul_rational_integer,mul_rational_float
	dw	mul_rational_complex,mul_rational_rational

	;
	;* multiplication main routines
	;  for each data type
	;

;
;* addition entry
;  [di]=[di]+[si]
;

farAdd_calcsp:
	mov	di,[calcsp]
	lea	si,[di-unitbyte]
faraddAAdisi:
	call	addAAdisi
	retf

faraddin:
	call	addin
	retf

addin:
	call	backsp
addAAdisi:
	mov	al,[di+1]
	mov	ah,[si+1]
	and	ax,attribmaskdouble
	jnz	add_extra
add_integer_integer:
	jmp	lladd		;if both integers


add_data_types	equ	4

add_extra:
	xor	bx,bx
	or	al,al
	jz	addextra20
	add	bx,add_data_types
	cmp	al,pointmaskhigh
	je	addextra20
	add	bx,add_data_types
	cmp	al,complexmaskhigh
	je	addextra20
	add	bx,add_data_types
	cmp	al,ratmaskhigh
	jne	add_etc

addextra20:
	or	ah,ah
	jz	addextra40
	inc	bx
	cmp	ah,pointmaskhigh
	je	addextra40
	inc	bx
	cmp	ah,complexmaskhigh
	je	addextra40
	inc	bx
	cmp	ah,ratmaskhigh
	jne	add_etc2

addextra40:
	add	bx,bx
	jmp	cs:[add_table+bx]


go_add_poly1:
	jmp	far ptr add_pl

go_add_modpoly1:
	jmp	far ptr add_mpl

go_add_ratfunc:
	jmp	far ptr add_rf

add_ret:
	ret

add_etc:
	cmp	al,packmaskhigh
	je	go_add_overload		;[di] is pack
	cmp	ah,packmaskhigh
	je	go_add_overload		;[si] is pack

	cmp	word ptr [si],0
	je	add_ret			;if [si] = 0

	cmp	al,polymaskhigh
	je	go_add_poly1		;[di] is poly
	cmp	al,modpolymaskhigh
	je	go_add_modpoly1		;[di] is modpoly
	cmp	al,ratpolymaskhigh
	je	go_add_ratfunc		;[di] is rational function
	cmp	ax,stringmaskdouble
	je	go_add_string_string	;[di],[si] both string
	jmp	ilgerr

add_etc2:
	cmp	ah,packmaskhigh
	je	go_add_overload		;[si] is pack

	cmp	ah,polymaskhigh
	je	go_add_poly2		;[si] is poly
	cmp	ah,modpolymaskhigh
	je	go_add_modpoly2		;[si] is modpoly
	cmp	ah,ratpolymaskhigh
	je	go_add_ratpoly2		;[si] is rational function
	jmp	ilgerr


go_add_overload:
	cmp	[overloadaddadr],0
	je	go_add_pack		;if default
	jmp	overloadadd
go_add_pack:
	jmp	far ptr add_pack

go_add_string_string:
	jmp	far ptr add_string_string

go_add_poly2:
	jmp	far ptr add_numpl

go_add_modpoly2:
	jmp	far ptr add_nummpl

go_add_ratpoly2:
	jmp	far ptr add_numrf


even
add_table	label	word
	dw	add_integer_integer,add_integer_float
	dw	add_integer_complex,add_integer_rational

	dw	add_float_integer,add_float_float
	dw	add_float_complex,add_float_rational

	dw	add_complex_integer,add_complex_float
	dw	add_complex_complex,add_complex_rational

	dw	add_rational_integer,add_rational_float
	dw	add_rational_complex,add_rational_rational

	;
	;* addition main routines
	;  for each data type
	;

;
;* [di] = - [di]
;

chgsigndi:
	mov	cx,[di]
	jcxz	chgsignret
	mov	ax,cx
	and	ax,attribmask
	jnz	chgsign20
chgsign10:
	xor	cx,signmask
	mov	[di],cx
chgsignret:
	ret
chgsign20:
	cmp	ax,pointmask
	je	chgsign10
	cmp	ax,ratmask
	jne	chgsign30
;rational
	xor	word ptr [di+2],signmask
	ret
chgsign30:
	cmp	ax,complexmask
	jne	chgsignilg
;complex
	add	di,2
	mov	ax,[di]
	or	ax,ax
	jz	chgsigncompjp
	xor	ax,signmask
	mov	[di],ax
	and	ax,lenmask
chgsigncompjp:
	inc	ax
	add	ax,ax
	add	di,ax		;top of imaginary part
	mov	ax,[di]
	or	ax,ax
	jz	chgsignret
	xor	ax,signmask
	mov	[di],ax
	ret

chgsignilg:
	jmp	ilgerr

farchgsigndi:
	call	chgsigndi
	retf

letcommon:
	jmp	far ptr farletcommon

code	ends

code2	segment	public
	assume	cs:code2,ds:data

	extrn	add_pl:far,add_numpl:far
	extrn	sub_pl:far,sub_numpl:far
	extrn	mul_pl:far,mul_numpl:far
	extrn	div_pl:far,idiv_pl:far

	extrn	add_mpl:far,add_nummpl:far,add_mpl_in:far
	extrn	sub_mpl:far,sub_nummpl:far
	extrn	mul_mpl:far,mul_nummpl:far
	extrn	idiv_mpl:far

	extrn	add_rf:far,add_numrf:far
	extrn	sub_rf:far,sub_numrf:far
	extrn	mul_rf:far,mul_numrf:far
	extrn	div_rf:far,div_numrf:far

	extrn	memoryfree:near,memoryalloc:near,xputsub:near
	extrn	farcompare_any:far



add_pack_pack:
	mov	bx,di
	mov	ax,[si+2]
	add	[di+2],ax	;new # of members
	mov	ax,[di]
	and	ax,lenmask
	mov	dx,ax		;memo old len
	inc	ax
	shl	ax,1
	add	di,ax

	lodsw
	and	ax,lenmask
	dec	ax
	mov	cx,ax
	add	ax,dx
	cmp	ax,limitword
	ja	add_packover
	add	si,2
	rep	movsw
	or	ah,packmaskhigh
	mov	[bx],ax
	jmp	far ptr returnadr

add_packover:
	jmp	far ptr ovrerr

add_pack:
	cmp	ah,packmaskhigh
	je	add_pack_pack
	mov	bx,di
	inc	word ptr [di+2]	;inc # of members
	mov	ax,[di]
	and	ax,lenmask
	mov	dx,ax		;memo old len
	inc	ax
	shl	ax,1
	add	di,ax

	mov	ax,[si]
	and	ax,lenmask
	inc	ax
	mov	cx,ax
	add	ax,dx
	cmp	ax,limitword
	ja	add_packover
	rep	movsw
	or	ah,packmaskhigh
	mov	[bx],ax
	jmp	far ptr returnadr


add_string_string:
	lodsw
	add	ax,ax
	sbb	ax,0
	and	ax,lenmask*2+1
	mov	cx,ax		;byte length of [si]

	mov	ax,[di]
	add	ax,ax
	sbb	ax,0
	and	ax,lenmask*2+1	;byte length of [di]

	mov	dx,ax		;memo ax
	add	ax,cx		;total byte length
	cmp	ax,limitword*2
	ja	addstrover
	inc	ax
	shr	ax,1
	jnc	addstr50

	or	ah,stringmaskhigh
	stosw
	add	di,dx
	rep	movsb
	jmps	addstrret
addstr50:		;odd length
	or	ah,80h+stringmaskhigh
	stosw
	add	di,dx
	rep	movsb
	mov	byte ptr [di],0
addstrret:
	jmp	far ptr returnadr

addstrover:
	jmp	far ptr ovrerr	

common_synerr:
	jmp	far ptr synerr

farparcommon:
	inc	bp
	mov	al,[bp]
	cmp	al,NCODE1
	jne	common_synerr
	inc	bp
	mov	bx,[bp]
	cmp	bx,COMMONDATANUMBER
	ja	common_indexerr
	winc	bp
	call	getfromCOMMONbx
	jmp	far ptr returnadr

getfromCOMMONbx:
	push	ds
	mov	ax,DATA
	add	ax,COMMONSEG
	mov	ds,ax

	dec	bx
	mov	ax,UNITBYTE
	mul	bx
	mov	si,ax

	mov	di,es:[calcsp]
	sub	di,UNITBYTE
	cmp	di,es:[calcsp_limit]
	jb	common_calcsperr

	mov	es:[calcsp],di
	mov	cx,[si]
	and	cx,lenmask
	inc	cx
	rep	movsw
	pop	ds
	ret

common_indexerr:
	jmp	far ptr indexerr
common_nodata:
	jmp	far ptr nodataerr
common_calcsperr:
	jmp	far ptr calcsperr
common_cantdo:
	jmp	far ptr cantdo

farletcommon:
	cmp	[directflg],0
	je	common_cantdo		;only direct mode
	mov	al,[bp]
	cmp	al,NCODE1
	jne	common_synerr
	inc	bp
	mov	bx,[bp]
	cmp	bx,COMMONDATANUMBER
	ja	common_indexerr
	winc	bp
	push	bx			;*
	cmp	byte ptr [bp],codeofequal
	JNE	letcommon_extended
	inc	bp
	call	far ptr farformul

letcommon30:
	pop	bx			;*
	dec	bx
	mov	ax,UNITBYTE
	mul	bx
	mov	di,ax

	push	es
	mov	ax,DATA
	add	ax,COMMONSEG
	mov	es,ax

	mov	si,[calcsp]
	mov	cx,[si]
	and	cx,lenmask
	inc	cx
	rep	movsw

	add	[calcsp],UNITBYTE
	pop	es
	jmp	far ptr mainlp

letcommon_extended:
	call	getfromCOMMONbx
	call	far ptr farlet_extended
	jmp	letcommon30


comment %

equpackerr:
	jmp	far ptr systemerr

equ_pack_pack:
	mov	ax,2
	call	memoryalloc

	mov	ax,[calcsp]
	cmp	ax,di
	jne	equpackerr
	sub	ax,unitbyte
	cmp	ax,si
	jne	equpackerr
	push	es
	push	di
	mov	es,bx
	xor	di,di
	copy_si2di		;copy [si] to xa
	pop	si
	mov	di,unitseg*16
	copy_si2di		;copy [di] to xb
	pop	es

	mov	ds,bx
	mov	di,2
	lea	si,[di+unitseg*16]
	mov	cx,[di]		;# of data
	cmp	cx,[si]
	jne	equpacknequ
	jcxz	equpack20	;both empty
	add	di,2
	add	si,2
equpack10:
	push	cx
	mov	dx,di		;memo
	mov	di,ss:[calcsp]
	copy_si2di		;get member of xa on sp0
	push	si
	mov	si,dx
	mov	di,ss:[calcsp]
	sub	di,unitseg*16
	copy_si2di		;get member of xb on sp1
	push	si
	mov	ax,ss
	mov	ds,ax
	push	bx
	call	far ptr farisequal_calcsp
	pop	bx
	pop	di
	pop	si
	pop	cx
	cmp	al,1
	jne	equpacknequ
	mov	ds,bx
	myloop	equpack10
equpack20:
	mov	ax,2
	call	memoryfree
	mov	al,1
equpackret:
	mov	si,ss
	mov	ds,si

	jmp	far ptr returnadr

equpacknequ:
	mov	ax,2
	call	memoryfree
	mov	al,6
	jmp	equpackret
%

code2	ends
