;FORMUL32.ASM

	INCLUDE	UBDEF.H
	INCLUDE	UB.H
	include	\ubv9\multi.h

	include	\ubv9\formulin.asm


CODE	SEGMENT PUBLIC
	ASSUME	CS:CODE,DS:DATA



;PUBLIC LABELS

	PUBLIC	CLR_NEXT,NEG_NEXT

	PUBLIC	LOADSAV,LOADLAV,INCLENSYS,CHG2POINT
	PUBLIC	FORMUL,farFORMUL,KAKKO,farKAKKO
	public	set0,PARNUM

	PUBLIC	ADDIN,SUBIN,LLADD,LLSUB
	public	addAAdisi,faraddAAdisi
	public	POWER2IN,POWER2IN2
	PUBLIC	LLAABS,LLSABS
	PUBLIC	LWADD,LWSUB
	public	gcdressi,gcdreswork2,fargcdreswork2
	PUBLIC	INCIN,DECIN,CLRIN,NEGIN,comparein,negallsi

	PUBLIC	MULIN,LLMUL,LLDIV
	public	mulAAdisi
	PUBLIC	mulIIdisi,farmulIIdisi
	public	addIIdisi,subIIdisi
	public	addAAdisi,subAAdisi
	public	idivIIdisi,faridivIIdisi
	public	squareIdi,farsquareIdi

	PUBLIC	IDIVIN,RESIN,POWERin

	public	faraddin,farsubin,farmulin


;EXTERNAL LABELS

	EXTRN	MAINLP:NEAR
	EXTRN	TRANSADR:NEAR
	EXTRN	GETSAVADR:NEAR,GETLAVADR:NEAR,GETLLAVADR:NEAR
	EXTRN	CLRTIME:NEAR
	EXTRN	FUNCIN:NEAR
	EXTRN	AHEDSP:NEAR,BACKSP:NEAR,CLRBLOCK:NEAR,NEGBLOCK:NEAR
	EXTRN	FUNCTION:NEAR

	extrn	func3in:near

	extrn	squareIFCdi:near

	EXTRN	SYNERR:NEAR,INDEXERR:NEAR,ILGERR:NEAR,OVRERR:NEAR
	EXTRN	UNDEFERR:NEAR,DIVERR:NEAR	;,MISMATCHERR:NEAR
	EXTRN	calcsperr:near,typeerr:near,floaterr:near


;
;	ＵBASIC の演算ルーチンその１
;	足し算と引き算
;


GOMVSIDI:
	copy_si2di

LLADDRET:
	RET

;
;☆☆	ＡＤＤのＥＮＴＲＹ
;

	align	4,,3
addIIdisi:
LLADD:
	MOV	BX,[DI]
	AND	BX,LENMASK
	JZ	GOMVSIDI	;when [DI]=0

	MOV	CX,[SI]
	AND	CX,LENMASK
	JZ	LLADDRET	;when [SI]=0

LLADIN:
	MOV	[DIMEM_A],DI
	INC	DI
	INC	SI
	MOV	AL,[DI]
	XOR	AL,[SI]
	INC	DI
	INC	SI
	AND	AL,80H
	JMPNZ	LLSABS		;if dif sgn

LLAABS:

; abs[DI]=abs[DI]+abs[SI]
; sgn unchanged
; preserving [SI]
; BX=len[DI]
; CX=len[SI]
; SI=2+lowest of [SI]
; DI=2+lowest of [DI]
; lowest adr of DI is in [DIMEM_A]

	SUB	BX,CX
	JB	LLAAJP		;if [DI]<[SI]

	SHR	CX,1
	JNC	LLAA30

	LODSW			;1ST WORD
	ADD	[DI],AX
	WINC	DI
	JCXZ	LLAA40

	public	LLAA30even
LLAA30even:
LLAA30:
	SET32
	LODSW
	SET32
	ADC	[DI],AX
	QINC	DI
	myloop	LLAA30
LLAA40:
	JNC	LLAARET

LLAA50:
	MOV	SI,[DIMEM_A]
	OR	BX,BX
	JZ	LLAA70
LLAA60:
	INC	WORD PTR [DI]
	JNZ	LLAARET		;if non carry
	WINC	DI
	DEC	BX
	JNZ	LLAA60
LLAA70:
	JMP	INCLENSYS

LLAARET:
	RET

	align	4,,3
LLAAJP:				;if len[DI]<len[SI]
	ADD	BX,CX
	MOV	AX,-2[DI]
	AND	AX,0C000H	;sign,point bits
	OR	AX,CX
	MOV	-2[DI],AX	;set new? length
	XCHG	BX,CX
	SUB	BX,CX

	SHR	CX,1
	JNC	LLAA130

	LODSW			;1ST WORD
	ADD	[DI],AX
	WINC	DI
	JCXZ	LLAA150
	public	LLAA130even
LLAA130even:
LLAA130:
	SET32
	LODSW
	SET32
	ADC	[DI],AX
	QINC	DI
	myloop	LLAA130

;  this time must move [SI] to [DI]

LLAA150:
	lahf			;=pushf
	push	ax		;
	MOV	CX,BX
	SET32
	XOR	BX,BX
	SHR	CX,1
	JNC	LLAA230
	pop	ax		;=popf
	sahf			;
	LODSW			;1ST WORD
	ADC	AX,BX
	STOSW
	JCXZ	LLAA250
	jmps	LLAA240
LLAA230:
	pop	ax		;=popf
	sahf			;

	align	4
LLAA240:
	SET32
	LODSW
	SET32
	ADC	AX,BX
	SET32
	STOSW
	myloop	LLAA240
LLAA250:
	JNC	LLAARET

	MOV	SI,[DIMEM_A]
	JMP	INCLENSYS

;☆引き算のエントリー

LLSUB:
	MOV	CX,[SI]
	AND	CX,LENMASK
	JZ	LLSUBRET	;if [SI]=0

	MOV	BX,[DI]
	AND	BX,LENMASK
	JNZ	LLSBJ1

;  [DI]=0 but [SI]<>0

	PUSH	DI
	copy_si2di
	POP	DI
	XOR	BYTE PTR 1[DI],80H	;change sgn
LLSUBRET:
	RET

;  if [DI] & [SI] both <>0

LLSBJ1:
LLSBIN:
	MOV	[DIMEM_A],DI	;mem DI
	INC	DI
	INC	SI
	MOV	AL,[DI]
	XOR	AL,[SI]
	INC	DI
	INC	SI
	AND	AL,80H
	JMPNZ	LLAABS		;if dif sgn


LLSABS:

; abs[DI]=abs(abs[DI]-abs[SI])
; sgn will be changed if carry
; preserving [SI]
; DI=2+lowest adr of [DI]
; SI=2+lowest adr of [SI]
; lowest adr of [DI] is in [DIMEM_A]

	CMP	BX,CX
	JA	LLSBIG		;if [DI]>[SI]
	JMPC	LLSLES		;if [DI]<[SI]

;  if same len

;  first compare [DI] & [SI]

	PUSH	SI
	PUSH	DI
	MOV	AX,CX		;MEMO LEN
	DEC	CX		;CX=len-1
	add	cx,cx
	ADD	DI,CX		;DI=HIGH OF [DI]
	ADD	SI,CX		;SI=HIGH OF [SI]
	MOV	CX,AX
	STD
	REPE	CMPSW
	CLD
	POP	DI
	POP	SI
	JB	LLSA0
	JA	LLSA100

	MOV	WORD PTR [DI-2],0	;if equal then set zero
	RET

	align	4,,2
	;same len but [DI]>[SI]
LLSA0:
	MOV	CX,BX
	SHR	CX,1
	JNC	LLSA30

	LODSW
	SUB	[DI],AX		;1ST WORD
	WINC	DI
	JCXZ	CALLEN
	public	LLSA30even
LLSA30even:
LLSA30:
	SET32
	LODSW
	SET32
	SBB	[DI],AX
	QINC	DI
	myloop	LLSA30
	JMPS	CALLEN

	;same len but [SI]>[DI]
LLSA100:
	MOV	CX,BX
	XOR	BYTE PTR [DI-1],80H	;CHANGE SIGN
	SHR	CX,1
	JNC	LLSA130

	LODSW
	SUB	AX,[DI]		;1ST WORD
	STOSW
	JCXZ	CALLEN
	align	4
	public	LLSA130even
LLSA130even:
LLSA130:
	SET32
	LODSW
	SET32
	SBB	AX,[DI]
	SET32
	STOSW
	myloop	LLSA130

CALLEN:				;BX=len,DI=HIGH?ADR
	XOR	AX,AX
	INC	BX
CALLEL:
	DEC	BX
	WDEC	DI
	CMP	AX,[DI]
	JE	CALLEL

	MOV	DI,[DIMEM_A]
	AND	WORD PTR [DI],0C000H
	OR	[DI],BX
	RET

;  if len[DI]>len[SI]

	align	4,,1
LLSBIG:
	SUB	BX,CX
	SHR	CX,1
	JNC	LLSA230

	LODSW			;1ST WORD
	SUB	[DI],AX
	WINC	DI
	JCXZ	LLSA240
	public	LLSA230even
LLSA230even:
LLSA230:
	SET32
	LODSW
	SET32
	SBB	[DI],AX
	QINC	DI
	myloop	LLSA230
LLSA240:
	JNC	LLSBRET

	DEC	BX
	JZ	LLSA300		;残りの 1 WORD は別処理

	MOV	CX,BX		;len[DI]-len[SI]-1>=0
LLSA260:
	SUB	WORD PTR [DI],1
	JNC	LLSBRET
	WINC	DI
	myloop	LLSA260
LLSA300:
	DEC	WORD PTR [DI]	;DEC highest adr
	JNZ	LLSBRET

LLSA310:
	;新長さの計算

	XOR	AX,AX
LLSA320:
	WDEC	DI	
	CMP	[DI],AX
	JE	LLSA320
	MOV	SI,[DIMEM_A]
	SUB	DI,SI
	SHR	DI,1
	MOV	AX,[SI]
	AND	AX,0C000H
	OR	AX,DI
	MOV	[SI],AX
LLSBRET:
	RET

;  if len[SI]>len[DI]
;	COPY しながら計算せねばならない

LLSLES:
	MOV	AH,-1[DI]	;符号を変えて,LEN を COPY
	XOR	AH,80H
	AND	AX,0C000H
	OR	AX,CX
	MOV	-2[DI],AX
	SUB	CX,BX
	SHR	BX,1
	JNC	LLSA420
	JNZ	LLSA410	

	LODSW			;1ST WORD
	SUB	AX,[DI]
	STOSW
	JMPS	LLSA430

LLSA410:
	LODSW			;1ST WORD
	SUB	AX,[DI]
	STOSW
LLSA420:
	SET32
	LODSW
	SET32
	SBB	AX,[DI]
	SET32
	STOSW
	DEC	BX
	JNZ	LLSA420
LLSA430:
	JNC	MVRES1

	DEC	CX
	JZ	LLSA450

LLSA440:
	LODSW
	SUB	AX,1
	STOSW
	JNC	MVRES
	myloop	LLSA440

LLSA450:				;last word
	MOV	AX,[SI]
	SUB	AX,1
	STOSW
	JNZ	LLSLRET
	JMP	LLSA310
LLSLRET:
	RET

MVRES:				;move rested [SI] to [DI]
	INC	CX		;=rested WORDs
MVRES1:
	REP	MOVSW
	RET


;
;integer arithmetic(MUL and DIV)
;



;☆割る数が1-2ワードの数の時
; (DI)=(DI)/AX


DIVSETANS0:
	XOR	AX,AX
	MOV	[ANSLEN],AX
	JMP	DIVRET

	align	4,,3		;FOR MAKING DIV10 BE EVEN
LWDIV:
	JE	LWDIV2		;IF 2 WORDS
	MOV	WORD PTR [SI+4],0	;BE 32BIT
LWDIV2:
	MOV	CX,[DI]
	AND	CX,LENMASK
	JZ	DIVSETANS0	;[DI] が 0 の時
	PUSH	BP
	SET32
	MOV	BP,[SI+2]	;割る数(32BIT)
	ADD	DI,CX
	ADD	DI,CX
	SHR	CX,1
	JNC	DIV5
	INC	CX
	ADD	DI,2
	MOV	WORD PTR [DI],0	;SET FOR 32BIT
DIV5:
	MOV	SI,DI		;SI=BASE OF HIGHEST 16BIT
	SUB	DI,2		;DI=BASE OF HIGHEST 32BIT
	STD
	SET32
	XOR	DX,DX		;余り

	PUBLIC	DIV10even
DIV10even:
DIV10:
	SET32
	MOV	AX,[DI]
	SET32
	DIV	BP
	SET32
	STOSW
	myloop	DIV10	
	CLD

	;商の長さと余りの調整

	ADD	SI,2
DIV20:
	SUB	SI,2
	CMP	WORD PTR [SI],0	;商が 0 でも ATTRIBUTE で止まる
	JE	DIV20		;すると、うまく [ANSLEN]=0 になる

	SUB	SI,[DIMEM_M]
	SHR	SI,1
	MOV	[ANSLEN],SI
	POP	BP
DIVEND:
	MOV	DI,[DIMEM_M]
	MOV	SI,[SIMEM_M]
	MOV	AX,[DI]
	XOR	AX,[SI]

	AND	AH,80H
	JZ	DIVRET		;同符号ならパス
	MOV	AX,[ANSLEN]
	OR	AX,AX
	JZ	DIVRET		;商が 0
	OR	AH,80H		;異符号ならば負に
	MOV	[ANSLEN],AX	

DIVRET:
	MOV	AX,[ANSLEN]
	MOV	SI,[DIMEM_M]
	OR	AX,AX
	JZ	DIV30
	MOV	BX,[SI]
	AND	BH,POINTMASKHIGH
	OR	AH,BH
DIV30:
	MOV	[SI],AX

	MOV	SI,RESADR	;余りは 0 に
	MOV	WORD PTR [SI],0
	RET


;☆多桁÷多桁	ABS((DI)) が ABS((SI)) 以上の場合
;(DI)=(DI)/(SI)

LLDIV:
	;(SI) の上位 32BIT を正規化して DIVWORD に

	MOV	AX,[DIVLEN]
	CMP	AX,UNITWORD-1
	JMPNC	DIVERR		;都合上エラーとする

	TEST	AL,1
	JZ	DIV2
	INC	AX
	MOV	[DIVLEN],AX	;32BIT化
	add	ax,ax
	ADD	SI,AX
	MOV	WORD PTR [SI],0
	JMPS	DIV4
DIV2:
	add	ax,ax
	ADD	SI,AX
DIV4:
	XOR	CX,CX		;CX=正規化の為のSHIFT回数
	MOV	AX,[SI]
	OR	AX,AX
	JNZ	DIV6
	ADD	CX,16
	SUB	SI,2
DIV6:
	MOV	AL,[SI+1]
	OR	AL,AL
	JNZ	DIV8
	ADD	CX,8
	DEC	SI
DIV8:
	SUB	SI,2		;32BIT BASE
	SET32
	MOV	AX,[SI]		;最上位32BIT
	SET32
	MOV	DX,[SI-4]	;一つ前
	DEC	CX
DIV110:
	INC	CX
	SET32
	add	dx,dx
	SET32
	RCL	AX,1
	JNC	DIV110

	SET32
	RCR	AX,1
	SET32
	MOV	[DIVWORD],AX
	MOV	[SFTBIT],CX

	;[DI]の ABS を RESADR にコピー

	MOV	DI,[DIMEM_M]
	MOV	CX,[DI]
	AND	CX,LENMASK
	LEA	SI,[DI+2]
	MOV	DI,RESADR
	MOV	AX,CX		;MEMO FOR AFTER USE
	STOSW
	REP	MOVSW
	SET32
	MOV	WORD PTR [DI],0	;32BIT化
	DW	0		;OPERAND FOR 32BIT
	TEST	AL,1
	JZ	DIV122
	INC	AX
	WINC	DI
	MOV	WORD PTR [DI+2],0
DIV122:
	SUB	DI,RESADR
	MOV	[PTRNOW],DI	;32BIT BASE OF OVER HIGHEST

	SUB	AX,[DIVLEN]
	MOV	CX,AX
	add	ax,ax
	ADD	AX,2
	MOV	[PTRNOW2],AX	;32BIT BASE

;メイン・ループ
;32 bit 毎の商を EBP に求め BX で示されるアドレスに置いて行く

	SHR	CX,1		;32BIT COUNTER
	INC	CX
	MOV	BX,[DIMEM_M]
	ADD	BX,AX
	MOV	[HIGHOFANS],BX	;32BIT BASE
	PUSH	BP
	public	DIV130even
DIV130even:
DIV130:
	PUSH	BX
	PUSH	CX
	CALL	LLDSUB32
	POP	CX
	POP	BX
	SET32
	MOV	[BX],BP	
	MOV	AX,4
	SUB	BX,AX
	SUB	[PTRNOW],AX
	SUB	[PTRNOW2],AX
	myloop	DIV130
	POP	BP

	;商の長さを求める

	MOV	BX,[HIGHOFANS]
	ADD	BX,4		;2 FOR 16 BIT HIGHEST,2 FOR DUMMY
DIV140:
	SUB	BX,2
	CMP	WORD PTR [BX],0
	JE	DIV140
	SUB	BX,[DIMEM_M]
	SHR	BX,1
	MOV	[ANSLEN],BX
	JMP	DIVEND

;    
;
;☆☆整数除算ルーチン
;
; (DI)=INT((DI)/(SI))
; RESADR=AMARI
; 割り算は余りが 0 以上 ABS((SI)) 未満になるように行われます
; 例 １割る３は商  ０余り１ですが
;  －１割る３は商－１余り２になります
;    

; * integer division principal routine
;   integer\integer
;   [DI]=[DI]\[SI]
;   assume DS=SS
;   use resadr only

IDIVBY0:
	JMP	DIVERR	
IDIVMIS:
	jmp	ilgerr		;mismatcherr
IDIVSETANS0:			;商はすでに0
	XOR	AX,AX
	MOV	SI,RESADR
	MOV	[SI],AX
	RET


faridivIIdisi:
	call	idivIIdisi
	retf

idivIIdisi:
	MOV	[SIMEM_M],SI
	MOV	[DIMEM_M],DI
	MOV	AX,[SI]
	TEST	AH,attribmaskhigh
	JNZ	IDIVMIS		;non integer
	AND	AX,LENMASK
	JZ	IDIVBY0		;if [SI]=0
	MOV	[DIVLEN],AX
	MOV	BX,[DI]
	TEST	BH,attribmaskhigh
	JNZ	IDIVMIS		;non integer
	AND	BX,LENMASK
	JZ	IDIVSETANS0	;IF [DI]=0
	CMP	AX,2
	JBE	LWIDIV		;if [SI] is 1WORD

;[SI] は多桁
	CMP	AX,BX
	JA	SLIDIV
	JMP	LLIDIV


;☆多桁÷多桁	ABS((DI)) が ABS((SI)) 未満の場合

;商を０にする

SLIDIV:
	XOR	AX,AX
	MOV	[ANSLEN],AX

;余りは ABS((DI))
	
	MOV	AX,[SI]
	AND	AX,LENMASK
	MOV	CX,[DI]
	AND	CX,LENMASK
	SUB	AX,CX
	MOV	SI,DI
	MOV	DI,RESADR
	MOV	[DI],CX
	WINC	SI
	WINC	DI
	REP	MOVSW
	OR	AX,AX
	JZ	SLIDIV10
	MOV	CX,AX
	XOR	AX,AX
	REP	STOSW		;余りの逆転があるのでクリアしておく
SLIDIV10:
	JMP	SETAMARI


;☆割る数が1-2ワードの数の時
; (DI)=(DI)/AX

	align	4,,2		;TO MAKE LWIDIV10 EVEN
LWIDIV:
	JE	LWIDIV2		;IF 2 WORDS
	MOV	WORD PTR [SI+4],0	;32BIT化
LWIDIV2:
	set32
	xor	dx,dx		;set amari=0 (actually not needed)
	MOV	CX,[DI]
	AND	CX,LENMASK
	JZ	LWIDIV20	;IF [DI]=0
	PUSH	BP
	SET32
	MOV	BP,[SI+2]	;割る数
	ADD	DI,CX
	ADD	DI,CX
	SHR	CX,1
	JNC	LWIDIV5
	INC	CX
	ADD	DI,2
	MOV	WORD PTR [DI],0	;32BIT化
LWIDIV5:
	MOV	SI,DI		;SI=BASE OF HIGHEST 16BIT
	SUB	DI,2		;DI=BASE OF HIGHEST 32BIT
	STD
	SET32
	XOR	DX,DX		;余り

	PUBLIC	LWIDIV10even
LWIDIV10even:
LWIDIV10:
	SET32
	MOV	AX,[DI]
	SET32
	DIV	BP
	SET32
	STOSW
	myloop	LWIDIV10	
	CLD

	;商の長さと余りの調整

	ADD	SI,2
LWIDIV20:
	SUB	SI,2
	CMP	WORD PTR [SI],0	;商が 0 でも ATTRIBUTE で止まる
	JE	LWIDIV20	;そのとき [ANSLEN]=0 で OK

	SUB	SI,[DIMEM_M]
	SHR	SI,1
	MOV	[ANSLEN],SI
	POP	BP

	MOV	DI,[DIMEM_M]
	MOV	SI,[SIMEM_M]
	MOV	AX,[DI]
	MOV	CX,[SI]
	XOR	CX,AX
	PUSH	CX		;CX=符号の違い

	;(Ｘ<0 AND 余り>0) ならば (商=商+1 AND 余りを逆にする)

	AND	AH,80H
	JZ	LWIDIV110	;IF [DI]>=0
	SET32
	OR	DX,DX
	JZ	LWIDIV110	;余り= 0
	SET32
	PUSH	DX
	CALL	INCANS
	SET32
	POP	DX
	MOV	SI,[SIMEM_M]
	SET32
	MOV	AX,[SI+2]
	SET32
	SUB	AX,DX		;余り=割る数-余り
	SET32
	MOV	DX,AX

	;Ｘ と Ｙ の符号が違えば商を負にする

LWIDIV110:
	POP	AX
	AND	AH,80H
	JZ	LWIDIV120	;同符号ならパス
	MOV	AX,[ANSLEN]
	OR	AX,AX
	JZ	LWIDIV120
	OR	AH,80H
	MOV	[ANSLEN],AX	

	;やっと商の長さがセット出来る

LWIDIV120:
	MOV	AX,[ANSLEN]
	MOV	SI,[DIMEM_M]
	OR	AX,AX
	JZ	LWIDIV125
	MOV	BX,[SI]
	AND	BH,POINTMASKHIGH
	OR	AH,BH
LWIDIV125:
	MOV	[SI],AX

	;余りのセット

	MOV	SI,RESADR
	SET32
	MOV	[SI+2],DX
	MOV	AX,2
	CMP	WORD PTR [SI+4],0
	JNE	LWIDIV130
	DEC	AX
	CMP	WORD PTR [SI+2],0
	JNE	LWIDIV130
	DEC	AX
LWIDIV130:
	MOV	[SI],AX
	RET



;☆多桁÷多桁	ABS((DI)) が ABS((SI)) 以上の場合
;(DI)=(DI)/(SI)

	nop
LLIDIV:
	;(SI) の上位 1 ワードを正規化して DIVWORD に

	CMP	AX,UNITWORD-1
	JMPNC	DIVERR		;都合上エラーとする

	ADD	SI,AX
	ADD	SI,AX

	XOR	CX,CX		;CX=正規化の為のSHIFT回数

	TEST	AL,1
	JZ	LLIDIV6

	INC	AX
	MOV	[DIVLEN],AX	;32BIT化
	MOV	WORD PTR [SI+2],0
	MOV	CX,16
LLIDIV6:
	MOV	AL,[SI+1]
	OR	AL,AL
	JNZ	LLIDIV8
	ADD	CX,8
	DEC	SI
LLIDIV8:
	SUB	SI,2		;BASE OF HIGHEST 32BIT
	SET32
	MOV	AX,[SI]		;最上位ワード
	SET32
	MOV	DX,[SI-4]	;一つ前
	DEC	CX
LLIDIV10:
	INC	CX
	SET32
	add	dx,dx
	SET32
	RCL	AX,1
	JNC	LLIDIV10

	SET32
	RCR	AX,1
	SET32
	MOV	[DIVWORD],AX
	MOV	[SFTBIT],CX

	;[DI]の ABS を RESADR にコピー

	MOV	DI,[DIMEM_M]
	MOV	CX,[DI]
	AND	CX,LENMASK
	MOV	SI,DI
	MOV	DI,RESADR
	MOV	AX,CX		;MEMO FOR AFTER USE
	INC	CX
	REP	MOVSW
	SET32
	MOV	WORD PTR [DI],0	;SET OVER HIGHEST 0
	DW	0		;OPERAND FOR 32BIT
	TEST	AL,1
	JZ	LLIDIV122
	INC	AX
	WINC	DI
	MOV	WORD PTR [DI+2],0
LLIDIV122:
	SUB	DI,RESADR
	MOV	[PTRNOW],DI	;32BIT BASE OF OVER HIGHEST

	SUB	AX,[DIVLEN]
	MOV	CX,AX		;COUNTER
	add	ax,ax
	ADD	AX,2
	MOV	[PTRNOW2],AX	;32BIT BASE

;メイン・ループ
;16 bit 毎の商を BP に求め BX で示されるアドレスに置いて行く

	SHR	CX,1
	INC	CX
	MOV	BX,[DIMEM_M]
	ADD	BX,AX
	MOV	[HIGHOFANS],BX	;32BIT BASE
	PUSH	BP
	public	LLIDIV30even
LLIDIV30even:
LLIDIV30:
	PUSH	BX
	PUSH	CX
	CALL	LLDSUB32
	POP	CX
	POP	BX
	SET32
	MOV	[BX],BP	
	MOV	AX,4
	SUB	BX,AX
	SUB	[PTRNOW],AX
	SUB	[PTRNOW2],AX
	myloop	LLIDIV30
	POP	BP

	;商の長さを求める

	MOV	BX,[HIGHOFANS]
	ADD	BX,4		;2 FOR 16BIT HIGHEST,2 FOR DUMMY
SETLEN10:
	SUB	BX,2
	CMP	WORD PTR [BX],0
	JE	SETLEN10
	SUB	BX,[DIMEM_M]
	SHR	BX,1
	MOV	[ANSLEN],BX

	;余りの長さを求める

SETAMARI:
	MOV	AX,[DIVLEN]
	MOV	CX,AX
	add	ax,ax
	ADD	AX,RESADR
	MOV	DI,AX
	XOR	AX,AX
	STD
	REPE	SCASW
	CLD
	JE	SETAM10
	INC	CX
SETAM10:
	MOV	DI,RESADR
	MOV	[DI],CX

	;商の長さと余りの調整

	MOV	DI,[DIMEM_M]
	MOV	SI,[SIMEM_M]
	MOV	AX,[DI]
	MOV	CX,[SI]
	XOR	CX,AX
	PUSH	CX		;符号の違い

	;(Ｘ<0 AND 余り>0) ならば (商=商+1 AND 余りを逆にする)

	TEST	AH,80H
	JZ	LLD110		;IF [DI]>=0
	MOV	BX,RESADR
	CMP	WORD PTR [BX],0
	JE	LLD110
	CALL	INCANS
	CALL	REVRES

	;Ｘ と Ｙ の符号が違えば商を負にする

LLD110:
	POP	AX
	AND	AH,80H
	JZ	LLD120		;同符号ならパス
	MOV	AX,[ANSLEN]
	OR	AX,AX
	JZ	LLD120
	OR	AH,80H
	MOV	[ANSLEN],AX	

	;やっと商の長さがセット出来る

LLD120:
	MOV	AX,[ANSLEN]
	MOV	SI,[DIMEM_M]
	OR	AX,AX
	JZ	LLD125
	MOV	BX,[SI]
	AND	BH,POINTMASKHIGH
	OR	AH,BH
LLD125:
	MOV	[SI],AX
	RET

	;商を一つ増す

INCANS:
	MOV	AX,1
	MOV	SI,[DIMEM_M]
	MOV	CX,[ANSLEN]
	WINC	SI
	JCXZ	INCANS20
INCANS10:
	ADD	[SI],AX
	JNC	INCANS100
	WINC	SI
	myloop	INCANS10
INCANS20:
	MOV	[SI],AX
	INC	[ANSLEN]
INCANS100:
	RET

	;余りを逆にする
	;(RESADR)=割る数-(RESADR)

REVRES:
	MOV	DI,RESADR+2
	MOV	SI,[SIMEM_M]
	WINC	SI
	MOV	CX,[DIVLEN]
	MOV	DX,CX		;MEMO
	CLC
REVRES10:
	LODSW
	SBB	AX,[DI]
	STOSW
	myloop	REVRES10	

	;余りの長さの計算し直し

	MOV	CX,DX
	WDEC	DI
	XOR	AX,AX
	STD
	REPE	SCASW
	CLD
	JE	REVRES20
	INC	CX
REVRES20:
	MOV	DI,RESADR
	MOV	[DI],CX
	RET
	
;
;	32BIT 毎の商を得る
;

	align	4,,2

LLDSUB32:
	;RESADR の上位 4 ワードを正規化して EDX:EAX に

	MOV	SI,RESADR
	ADD	SI,[PTRNOW]
	MOV	WORD PTR [SI+4],0FFFFH
	MOV	WORD PTR [SI+6],0FFFFH
				;BORROW 用(RESADR は計4WORD余裕必要)
	MOV	CX,[SFTBIT]
	CMP	CX,16
	JB	LLDSUB32_10
	SUB	CX,16
	SUB	SI,2
LLDSUB32_10:
	CMP	CX,8
	JB	LLDSUB32_20
	SUB	CX,8
	DEC	SI
LLDSUB32_20:
	SET32
	MOV	DX,[SI]
	SET32
	MOV	AX,[SI-4]
	JCXZ	LLDSUB32_40
	SET32
	MOV	BX,[SI-8]
	public	LLDSUB32_30even
LLDSUB32_30even:
LLDSUB32_30:
	SET32
	add	bx,bx
	SET32
	RCL	AX,1
	SET32
	RCL	DX,1
	myloop	LLDSUB32_30

	;EAX に MIN(EDX:EAX/[DIVWORD],0FFFFFFFFH) を得る

LLDSUB32_40:
	SET32
	MOV	BX,[DIVWORD]
	SET32
	CMP	DX,BX
	JAE	LLDSUB32_50
	SET32
	DIV	BX
	SET32
	MOV	BP,AX
	SET32
	OR	AX,AX
	JNZ	LLDSUB32_60
	RET			;ans = 0

	align	4,,3
LLDSUB32_50:
	SET32
	XOR	bp,bp
	SET32
	DEC	bp		;仮商はU-1

	;RESADR から 割る数*EAX を引く	
LLDSUB32_60:
	MOV	CX,[DIVLEN]
	MOV	SI,[SIMEM_M]
	WINC	SI
	MOV	BX,RESADR
	ADD	BX,[PTRNOW2]
	SHR	CX,1

	PUBLIC	LLDSUB32_70even
LLDSUB32_70even:
LLDSUB32_70:
	SET32
	LODSW
	SET32
	MUL	BP
	SET32
	SUB	[BX],AX
	QINC	BX
	SET32
	SBB	[BX],DX
	JC	LLDSUB32_90
LLDSUB32_80:
	myloop	LLDSUB32_70
	RET

	align	4,,3
LLDSUB32_90:
	MOV	AX,BX		;=PUSH	BX
LLDSUB32_95:
	QINC	BX
	SET32
	SBB	WORD PTR [BX],0
				;DW	0;OPERAND FOR 32 BIT
	JC	LLDSUB32_95
	MOV	BX,AX		;=POP	BX
	CMP	CX,1
	JNE	LLDSUB32_80

	;最後に CARRY が出るのは
	;引き過ぎなので 1 つ戻す(RESADR'=RESADR'+割る数)

LLDSUB32_100:
	MOV	SI,[SIMEM_M]
	WINC	SI
	MOV	BX,RESADR
	ADD	BX,[PTRNOW2]
	MOV	CX,[DIVLEN]
	SHR	CX,1
	CLC
	public	LLDSUB32_110even
LLDSUB32_110even:
LLDSUB32_110:
	SET32
	LODSW
	SET32
	ADC	[BX],AX
	QINC	BX
	myloop	LLDSUB32_110
	SET32
	ADC	WORD PTR [BX],0
				;DW	0	;OPERAND FOR 32BIT
	SET32
	DEC	BP		;DEC ANSWER
	JNC	LLDSUB32_100	;1 MORE
	RET


;
;** multiplication principal routine
;
;   [DI] *= [SI]
;	convinient for general use
;	non checking data types = treat as integers
;       use MULWORK for work area
;
;	input	di, si: base address
;	destroy	ax,bx,cx,dx,si,di
;	reserve	contents of [si]


farmulIIdisi:
	call	mulIIdisi
	retf


	align	4
mulIIdisi:
	MOV	[ATTRIBPTR],DI
	MOV	CX,[DI]
	MOV	AL,CH
	AND	CX,LENMASK
	JZ	MULRET		;if [DI]=0
	MOV	[DILEN_M],CX
	MOV	BX,[SI]
	MOV	AH,BH
	AND	BX,LENMASK
	JZ	MULSET0		;if [SI]=0
	MOV	[SILEN_M],BX
	MOV	[ATTRIB],AX
	CALL	MUL_SUB
	MOV	AX,[ATTRIB]
	XOR	AL,AH
	AND	AL,80H		;符号
	OR	CH,AL
MULRET:
	MOV	DI,[ATTRIBPTR]
	MOV	[DI],CX
	RET

MULSET0:
	XOR	CX,CX
	JMP	MULRET

MUL_SUB:
	CMP	CX,2
	JA	MUL10
	CMP	BX,2
	JBE	WWMUL		;共に <=2 WORD
	JMP	WLMUL		;[DI] は <=2 WORD
MUL10:
	CMP	BX,2
	JBE	LWMUL		;[SI] は <=2 WORD
	JMP	LLMUL		;共に多桁

;* word * word
;  [DI]=[DI]*[SI]
;  BOTH <= 2 WORD (特に 0 ではない)

WWMUL	PROC

	cmp	bx,1
	ja	mymul?_2
mymul?_1:
	cmp	cx,1
	ja	mymul2_1
mymul1_1:
	MOV	AX,[DI+2]
	MUL	WORD PTR [SI+2]
	MOV	[DI+2],AX
	MOV	CX,1		;長さを測る
	OR	DX,DX
	JZ	WWMULRET
	MOV	[DI+4],DX
	INC	CX
WWMULRET:
	RET

mymul2_1:
	set32
	MOV	AX,[DI+2]
	set32
	xor	bx,bx
	mov	bx,[SI+2]	;16 bits
	set32
	mul	bx
	set32
	mov	[di+2],ax
	MOV	CX,2		;長さを測る
	OR	DX,DX
	JZ	WWMULRET
	MOV	[DI+6],DX
	INC	CX
	jmp	WWMULret	

mymul?_2:
	cmp	cx,1
	ja	mymul2_2
mymul1_2:
	set32
	xor	ax,ax
	MOV	AX,[DI+2]	;16 bits
	set32
	mov	bx,[SI+2]
	set32
	mul	bx
	set32
	mov	[di+2],ax
	MOV	CX,2		;長さを測る
	OR	DX,DX
	JZ	WWMULRET
	MOV	[DI+6],DX
	INC	CX
	jmp	WWMULret	

mymul2_2:
	set32
	MOV	AX,[DI+2]
	set32
	mov	bx,[SI+2]
	set32
	mul	bx
	set32
	mov	[di+2],ax
	set32
	mov	[di+6],dx
	MOV	CX,3		;長さを測る
	set32
	shr	dx,16
	or	dx,dx
	JZ	WWMULRET
	INC	CX
	jmp	WWMULret	

WWMUL	ENDP


	;
	;** DWORD * LONG
	;

	align	4,,2
DLMUL:
	;[DI] が 2 WORD の時

	push	bp

	WINC	DI
	set32
	MOV	BX,[DI]		;掛ける数

	WINC	SI
	MOV	CX,[SILEN_M]
	shr	cx,1

	lahf			;=pushf
	push	ax		;

	set32
	xor	bp,bp		;carry=0

	align	4
DLMUL10:
	set32
	lodsw
	set32
	mul	bx
	set32
	add	ax,bp
	set32
	stosw
	set32
	adc	dx,0
	set32
	mov	bp,dx		;bp=carry
	myloop	DLMUL10

	pop	ax		;=popf
	sahf			;
	jnc	DLMUL20

	set32
	xor	ax,ax
	LODSW			;get highest 16bits
	set32
	MUL	BX
	set32
	ADD	AX,BP
	set32
	STOSW
	set32
	ADC	DX,0
	mov	bp,dx		;16 bits
	jmps	DLMUL25
DLMUL20:
	set32
	shr	bp,16
	set32
DLMUL25:
	mov	[di],dx

	MOV	CX,[SILEN_M]
	jmp	LDDLMUL


;☆ワード×多桁
;  [DI]=[DI]*[SI]
;  [SI] の長さを SILEN_M にセットし
;  [DI] も [SI] も 0 ではないこと
;  破壊 BP 以外全て

	align	4,,3
WLMUL:
	cmp	cx,2
	je	DLMUL		;2word*long

	;[DI] が 1 WORD の時

	push	bp

	WINC	DI

	set32
	xor	bx,bx
	MOV	BX,[DI]		;掛ける数
	WINC	SI
	MOV	CX,[SILEN_M]
	shr	cx,1

	lahf			;=pushf
	push	ax

	set32
	xor	bp,bp		;carry=0

	align	4
WLMUL10:
	set32
	lodsw
	set32
	mul	bx
	set32
	add	ax,bp
	set32
	stosw
	set32
	adc	dx,0
	set32
	mov	bp,dx		;bp=carry
	myloop	WLMUL10

	pop	ax		;=popf
	sahf			;
	jnc	WLMUL20

	LODSW			;get highest 16bits
	MUL	BX
	ADD	AX,BP
	STOSW
	ADC	DX,0
	jmps	WLMUL25
WLMUL20:
	set32
WLMUL25:
	mov	[di],dx

	MOV	CX,[SILEN_M]
	jmp	LWWLMUL


	;
	;** LONG * DWORD
	;
	align	4,,2		;to make LDMUL10 be qadr
LDMUL:

	push	bp

	WINC	DI

	set32
	MOV	BX,[SI+2]	;掛ける数
	MOV	CX,[DILEN_M]

	shr	cx,1

	lahf			;=pushf
	push	ax		;

	set32
	xor	bp,bp		;carry=0

	align	4
LDMUL10:
	set32
	mov	ax,[di]
	set32
	mul	bx
	set32
	add	ax,bp
	set32
	stosw
	set32
	adc	dx,0
	set32
	mov	bp,dx		;bp=carry
	myloop	LDMUL10

	pop	ax		;=popf
	sahf			;
	jnc	LDMUL20

	set32
	xor	ax,ax
	mov	ax,[di]		;get highest 16bits
	set32
	MUL	BX
	set32
	ADD	AX,BP
	set32
	STOSW
	set32
	ADC	DX,0
	mov	bp,dx		;16 bit
	jmps	LDMUL25
LDMUL20:
	set32
	shr	bp,16
	set32
LDMUL25:
	mov	[di],dx

	MOV	CX,[DILEN_M]

	;SIZE の CHECK
LDDLMUL:
	inc	cx
	or	bp,bp		;最上位は 0 か?
	jz	LDDLMUL100
	INC	CX
LDDLMUL100:
	CMP	CX,LIMITWORD
	JA	LDDLMUL120	;IF OVERFLOW
	pop	bp
	RET

LDDLMUL120:
	pop	bp
	JMP	OVRERR


;☆多桁×ワード
;  [DI]=[DI]*[SI]
;  [DI] の長さを DILEN_M にセットし
;  符号を SIGN_PT にセットしてから CALL せよ
;  [DI] も [SI] も 0 ではないこと
;  破壊 BP 以外全て

	align	4
	nop
LWMUL	PROC

	cmp	bx,2
	je	LDMUL		;long*2word

	push	bp

	WINC	DI

	set32
	xor	bx,bx
	MOV	BX,[SI+2]	;掛ける数
	MOV	CX,[DILEN_M]

	shr	cx,1

	lahf			;pushf
	push	ax

	set32
	xor	bp,bp		;carry=0

	align	4
LWMUL10:
	set32
	mov	ax,[di]
	set32
	mul	bx
	set32
	add	ax,bp
	set32
	stosw
	set32
	adc	dx,0
	set32
	mov	bp,dx		;bp=carry
	myloop	LWMUL10

	pop	ax		;popf
	sahf			;
	jnc	LWMUL20

	mov	ax,[di]		;get highest 16bits
	MUL	BX
	ADD	AX,BP
	STOSW
	ADC	DX,0
	jmps	LWMUL25
LWMUL20:
	set32
LWMUL25:
	mov	[di],dx

	MOV	CX,[DILEN_M]

	;SIZE の CHECK
LWWLMUL:
	or	dx,dx		;最上位は 0 か?
	jz	LWWLMUL100
	INC	CX
	CMP	CX,LIMITWORD
	JA	LWWLMUL120	;IF OVERFLOW
LWWLMUL100:
	pop	bp
	RET

LWWLMUL120:
	pop	bp
	JMP	OVRERR

LWMUL	ENDP

;
;☆多桁×多桁
;   [DI]=[DI]*[SI]
;   DI & SI MUST NEITHER BE 0

LLMULOVR:
	POP	BP
	JMP	OVRERR

	align	4
LLMUL:
	PUSH	BP		;ポインタ
	WINC	DI
	MOV	[DIMEM_M],DI	;ORIGINAL DI+2
	WINC	SI
	MOV	[SIMEM_M],SI

	;符号と予想される長さを決める(-0に注意)

	MOV	AX,BX
	ADD	AX,CX
	CMP	AX,LIMITWORD+1
	JA	LLMULOVR	;IF OVERFLOW
	MOV	[TOTALWORDS],AX

	cmp	bx,LLMULswitchlen*2
	jbe	LLMULnormal
	cmp	cx,LLMULswitchlen*2
	jbe	LLMULnormal

	call	far ptr LLMULfast
	mov	di,es:[dimem_m]
	set32
	rep	movsw
	mov	ax,data
	mov	ds,ax
	jmp	LLMUL55

LLMULnormal:
	;COPY [DI] TO mulwork (mulwork を用いる)

	MOV	CX,[DILEN_M]
	MOV	SI,DI
	MOV	DI,mulwork+2
	MOV	AX,CX
	REP	MOVSW
	TEST	AL,1
	JZ	LLMUL100
	MOV	WORD PTR [DI],0	;SET HIGHEST 0 IF ODD LENGTH
	INC	[DILEN_M]

	;  MAKE [SI] EVEN LENGTH
LLMUL100:
	mov	ax,[SILEN_M]
	test	al,1
	jz	LLMUL110
	mov	bx,ax
	inc	ax
	add	bx,bx
	mov	[SILEN_M],ax
	add	bx,[SIMEM_M]
push	word ptr [bx]	;/*
push	bx		;/**
	mov	word ptr [bx],0
dec	ax
	;  clear original [DI]
LLMUL110:
push	ax	;original [SILEN_M]

	MOV	CX,[DILEN_M]
	MOV	DI,[DIMEM_M]	;ORIGINAL DI+2
	ADD	CX,[SILEN_M]
	XOR	AX,AX
	REP	STOSW		;//次の数まで消すおそれあり

	;* MAIN PART OF MUL WORD BY WORD

	MOV	BX,[DIMEM_M]	;ORIGINAL DI+2
	MOV	CX,[DILEN_M]
	MOV	DI,mulwork+2
	SHR	CX,1		;32 BIT
	public	LLMUL10even
LLMUL10even:
LLMUL10:
	SET32
	MOV	BP,[DI]		;これを [SI] にかけて [BX] へ
	PUSH	CX
	SET32
	OR	BP,BP
	JZ	LLMUL50		;かける数が 0 のときはパス

	;[SI] についてのループ

	PUSH	BX
;//	PUSH	DI
	MOV	CX,[SILEN_M]
	MOV	SI,[SIMEM_M]
	SHR	CX,1

	PUBLIC	LLMUL20even
LLMUL20even:
LLMUL20:
	mylodsd
	SET32
	MUL	BP
	SET32
	ADD	[BX],AX
	QINC	BX
	SET32
	ADC	[BX],DX
	JC	LLMUL200
LLMUL30:
	myloop	LLMUL20

;//	POP	DI
	POP	BX
LLMUL50:
	QINC	DI
	QINC	BX
	POP	CX
	myloop	LLMUL10

pop	ax		;original [SILEN_M]
test	ax,1
jz	short LLMUL55	;if even words
pop	bx		;**/
pop	word ptr [bx]	;*/

	;  DECIDE LEN & SIGN

LLMUL55:
	MOV	CX,[TOTALWORDS]
	MOV	BX,[DIMEM_M]	;ORIGINAL DI+2
	MOV	SI,CX
	WDEC	BX
	SHL	SI,1
	CMP	WORD PTR [BX+SI],0
	JNE	LLMUL70
	DEC	CX
LLMUL60:
	POP	BP		;ポインタを戻す
	RET	

LLMUL70:
	CMP	CX,LIMITWORD
	JBE	LLMUL60
	JMP	LLMULOVR

LLMUL200:
	MOV	AX,BX		;=PUSH	BX
LLMUL210:
	QINC	BX
	SET32
	INC	WORD PTR [BX]
	JZ	LLMUL210
	MOV	BX,AX		;=POP	BX
	JMP	LLMUL30


;
;☆２乗ルーチン
;

POW2X1:
	MOV	WORD PTR [DI],1	;SET X=1
POW2X0:
	RET

POWER2IN:
	MOV	DI,[CALCSP]
POWER2IN2:
	MOV	[XMEM],DI
	MOV	BX,[DI]
	AND	BX,LENMASK
	JZ	POW2X0		;if X=0

;	CMP	BX,1
;	JNZ	POW2JP
;	CMP	WORD PTR [DI+2],1
;	JZ	POW2X1		;if X=+-1
POW2JP:
	jmp	squareIFCdi


;
; POWER 用平方ルーチン
;	[DI]=[DI]^2

	; use mulwork


farsquareIdi:
	call	squareIdi
	retf


SQAR4WORDS:
	push	bx
	set32
	mov	bx,[di+2]
	set32
	mov	ax,bx
	set32
	mov	cx,[di+6]

	set32
	mul	ax
	set32
	mov	[di+2],ax
	set32
	mov	ax,cx
	set32
	mov	[di+6],dx
	set32
	mul	ax
	set32
	mov	[di+10],ax
	set32
	mov	ax,bx
	set32
	mov	bx,dx		;ebx = [di+14]
	set32
	mul	cx
	set32
	xor	cx,cx
	set32
	add	ax,ax
	set32
	adc	dx,dx
	set32
	adc	bx,cx
	set32
	add	[di+6],ax
	set32
	adc	[di+10],dx
	set32
	adc	bx,cx
	set32
	mov	[di+14],bx

	mov	cx,8
	set32
	shr	bx,16
	or	bx,bx
	jnz	sqar4wjp
	dec	cx
sqar4wjp:
	mov	[di],cx
	pop	bx
	ret


SQAR3WORDS:
	JE	SQAR4WORDS

	push	bx

	set32
	mov	ax,[di+2]	;get low dword
	set32
	xor	bx,bx
	mov	bx,[di+6]	;get high word
	set32
	mov	cx,ax
	set32
	mul	ax
	set32			;set low dword
	mov	[di+2],ax
	set32
	mov	ax,bx
	set32			;set middle dword
	mov	[di+6],dx
	set32
	mul	ax
	set32
	xchg	ax,cx		;ecx = high dword, eax = original low dword

	set32
	mul	bx
	set32
	add	ax,ax
	set32
	adc	dx,dx		;must non carry

	set32
	add	[di+6],ax
	set32
	adc	dx,cx
	set32
	mov	[di+10],dx

	mov	cx,6
	set32
	shr	dx,16
	or	dx,dx
	jnz	sqar3wjp
	dec	cx
sqar3wjp:
	mov	[di],cx
	pop	bx
	ret


SQAR2WORDS:
	set32
	mov	ax,[di+2]
	set32
	mul	ax
	add	cx,cx		;cx = 4
	set32
	mov	[di+6],dx
	set32
	mov	[di+2],ax
	cmp	word ptr [di+8],0
	jne	sqar2wjp
	dec	cx
sqar2wjp:
	mov	[di],cx
	ret


SQAR1WORD:
	JE	SQAR2WORDS
	MOV	AX,[DI+2]
	MUL	AX
;	MOV	CX,1		;cx must be 1
	OR	DX,DX
	JZ	SQAR1WJP
	INC	CX
SQAR1WJP:
	mov	[di],cx
	mov	[di+2],ax
	mov	[di+4],dx
	ret

;
; * square integer
;  [di] = [di]^2
;  use mulwork

squareover:
	jmp	ovrerr

	align	4
squareIdi:
	mov	cx,[di]
	and	cx,LENMASK
	jz	squareout	;if 0

	CMP	cx,2
	JBE	SQAR1WORD
	CMP	cx,4
	JBE	SQAR3WORDS

	PUSH	BX
	PUSH	BP
	WINC	DI
	MOV	[DIMEM_M],DI	;ORIGINAL DI+2
	MOV	[DILEN_M],cx
	add	cx,cx
	cmp	cx,LIMITWORD
	ja	squareover
	shr	cx,1
	call	far ptr LLSQUAREfast
	mov	ax,[dilen_m]
	mov	di,[dimem_m]
	add	ax,ax
	mov	si,di
	mov	cx,ax
	add	ax,ax
	add	di,ax
	cmp	word ptr [di-2],0
	jne	square50
	dec	cx
square50:
	cmp	cx,limitword
	ja	squareover

	mov	[si-2],cx
squareret:
	pop	bp
	pop	bx
squareout:
	ret


comment %
squareIdi:
	PUSH	BX
	PUSH	BP
	MOV	AX,[DI]
	WINC	DI
	MOV	[DIMEM_M],DI	;ORIGINAL DI+2
	AND	AX,LENMASK
	JZ	SQAR_0		;if [DI]=0
	CMP	AX,2
	JBE	SQAR1WORD

	MOV	[DILEN_M],AX

	;COPY [DI] TO mulwork
	;最下位WORDはそのまま

	MOV	DI,mulwork
	STOSW
	MOV	SI,[DIMEM_M]
	MOV	CX,AX
	REP	MOVSW
	MOV	WORD PTR [DI],0	;32BIT

	;予想される長さを決める

	add	ax,ax
	CMP	AX,LIMITWORD+1
	JA	SQAR_OVR	;IF OVERFLOW

	;A(I)^2 の分

	MOV	SI,mulwork+2
	MOV	DI,[DIMEM_M]
	MOV	CX,[DILEN_M]
	INC	CX
	SHR	CX,1
	public	SQAR40even
SQAR40even:
SQAR40:
	SET32
	LODSW
	SET32
	MUL	AX
	SET32
	STOSW
	SET32
	MOV	AX,DX
	SET32
	STOSW
	myloop	SQAR40
	MOV	[SQARHIGH],DI	;最高位32BITADR

	;* 2*A(I)*A(J) J>I の部分

	MOV	DI,mulwork+2

	MOV	BX,[DIMEM_M]
	QINC	BX		;BASE ADR FOR STORE

	MOV	CX,[DILEN_M]
	INC	CX
	SHR	CX,1
	DEC	CX		;1-2 WORD は除いたので<>0
	public	SQAR5even
SQAR5even:
SQAR5:
	SET32
	MOV	BP,[DI]
	QINC	DI
	SET32
	OR	BP,BP
	JZ	SQAR30		;0 はSKIP

	PUSH	CX
	PUSH	BX

	MOV	SI,DI
	align	4
	public	SQAR10even
SQAR10even:
SQAR10:
	SET32
	LODSW
	SET32
	MUL	BP
	SET32
	add	ax,ax
	SET32
	RCL	DX,1
	JC	SQAR20

	SET32
	ADD	[BX],AX
	QINC	BX
	SET32
	ADC	[BX],DX
	JC	SQAR21
SQAR25:
	myloop	SQAR10

	POP	BX
	POP	CX
SQAR30:
	ADD	BX,8		;QINC 2 TIMES
	myloop	SQAR5
	JMPS	SQAR60

SQAR20:
	SET32
	ADD	[BX],AX
	QINC	BX
	SET32
	ADC	[BX],DX
	MOV	AX,BX
	QINC	BX
	SET32
	ADC	WORD PTR [BX],1
	JC	SQAR22
	MOV	BX,AX
	JMP	SQAR25

SQAR21:
	MOV	AX,BX
SQAR22:
	QINC	BX
	SET32
	INC	WORD PTR [BX]
SQAR23:
	JZ	SQAR22
	MOV	BX,AX
	JMP	SQAR25

	;  DECIDE LEN

SQAR60:
	MOV	BX,[DIMEM_M]	;ORIGINAL DI+2
	WDEC	BX
	MOV	SI,[SQARHIGH]
SQAR70:
	SUB	SI,2
	CMP	WORD PTR [SI],0
	JE	SQAR70
	SUB	SI,BX
	SHR	SI,1
	MOV	CX,SI
	CMP	CX,LIMITWORD
	JA	SQAROVR2	;IF OVERFLOW

SQAR75:
;	MOV	AX,[BX]
;	AND	AX,POINTMASK
;	OR	CX,AX
	MOV	[BX],CX
;	OR	AX,AX
;	JZ	SQAR100
;
;	MOV	SI,BX
;	CALL	SFTDOWN		;shift down if not integer

SQAR100:
	POP	BP		;ポインタを戻す
	POP	BX
	RET	

SQAROVR2:
	JMP	OVRERR

SQARSET0:
	MOV	WORD PTR [BX],0
	JMP	SQAR100
%


;
;CALCSP で長さを１つ増す
;  最上位でキャリーが起こった時に呼ばれる
;  長さを増して最上位を１にする
;
;INPUT:SI=lowest adr
;      DI=NEW highest adr
;DETROY AX,CX

INCLENSYS:	
	MOV	AX,[SI]
	MOV	CX,AX
	AND	AX,LENMASK
	CMP	AX,LIMITWORD
	JAE	GO_OVRERR
	INC	AX
	AND	CH,0C0H		;reserve 7,6-th bit
	OR	AH,CH
	MOV	[SI],AX		;set new length
	MOV	WORD PTR [DI],1	;SET HIGHEST WORD
	RET	

GO_OVRERR:
	JMP	OVRERR


;☆	LWADD(long+WORD)
;	[DI]=[DI]+AX
;	seeing AX as 0 to 65535
;	NEXT から呼ばれる時は [DI] は LONG とかぎらない


;  if len=0 i.e. [DI]=0
LWAD2ZERO:
	MOV	WORD PTR [DI],1	;len=1
	MOV	2[DI],AX	;set value
LWADDRET:
	RET

	align	4
LWADD:
	OR	AX,AX
	JZ	LWADDRET	;if AX=0

	MOV	CX,[DI]		;CX=LEN
	AND	CX,LENMASK
	JZ	LWAD2ZERO

;  if len>=1

	MOV	SI,DI		;MEMO for INCLEN
	WINC	DI
	TEST	BYTE PTR [DI-1],80H
	JNZ	LWSABS		;if [DI]<0

LWAABS:

;* abs[DI]=abs[DI]+AX
;  sgn[DI] unchanged
;  CX=len
;  SI=lowest adr
;  DI=SI+2

	ADD	[DI],AX
	JC	LWADD20
LWADD10:
	RET

	align	4
	PUBLIC	LWADDEVEN
LWADDEVEN:
LWADD20:
	DEC	CX
	JZ	LWADD50
	WINC	DI
	INC	WORD PTR [DI]
	JZ	LWADD20
	RET
LWADD50:
	WINC	DI
	JMP	INCLENSYS	;if longer than original

;☆	LWSUB(long-WORD)
;	[DI]=[DI]-AX
;	seeing AL as 0 to 65535

;  if len=0 i.e. [DI]=0
LWSUBFROMZERO:
	MOV	[DI],8001H
	MOV	2[DI],AX
LWSUBRET:
	RET

	align	4
LWSUB:				;also called from NEXT
	OR	AX,AX
	JZ	LWSUBRET

	MOV	CX,[DI]
	AND	CX,LENMASK
	JZ	LWSUBFROMZERO

;  if len>0

	MOV	SI,DI		;set for DECLEN
	WINC	DI
	TEST	BYTE PTR -1[DI],80H
	JNZ	LWAABS		;if [DI]<0

LWSABS:

;* abs[DI]=abs[DI]-AX
;  sgn will be changed if carry
;  CX=len
;  SI=lowest adr(=attribute)
;  DI=SI+2

	CMP	CX,2
	JAE	LWSAJP		;if len>=2

; if len=1

	SUB	[DI],AX
	JC	LWSCHG
	JZ	LWSZER
	RET

LWSZER:				;if zero
	MOV	WORD PTR [SI],0
	RET

LWSCHG:				;if opposite sgn
	NEG	WORD PTR [DI]	;値を負に
	XOR 	BYTE PTR [DI-1],80H	;符号を負に
	RET

; if len>=2

LWSAJP:
	SUB	[DI],AX
	JC	LWSUB20
LWSUB10:
	RET

	align	4,,3		;to make lwsubeven qadr
LWSUB20:
	DEC	CX

	PUBLIC	LWSUBEVEN
LWSUBEVEN:
LWSUBLP:
	DEC	CX
	JZ	LWSUBLST	;残りは １WORD
	WINC	DI
	SUB	WORD PTR [DI],1
	JC	LWSUBLP
	ret
LWSUBLST:			;DEC highest WORD
	WINC	DI
	DEC	WORD PTR [DI]
	JZ	LWSUB100	;最上位が 0
	RET
LWSUB100:
	DEC	WORD PTR [SI]	;DEC len(0になることはない)
	RET

;  * calculate (RESADR) modulo (si)
;    destroy BP!!

farGCDRESwork2:	
	call	GCDRESwork2
	retf

GCDRESwork2:
	mov	si,work2
GCDRESsi:
	MOV	[SIMEM_M],SI
	MOV	DI,RESADR
	MOV	AX,[SI]
	AND	AX,LENMASK
	MOV	[DIVLEN],AX
	CMP	AX,2
	JBE	GCDRES5		;if [SI] is <=2WORD

	;[SI] は多桁

	MOV	BX,[DI]
	AND	BX,LENMASK
	CMP	AX,BX
	JBE	GCDRES30


GCDRES_RET:
	RET


	;割る数が<=2 ワードの数の時

GCDRES5:
	JE	GCDRES7
	MOV	WORD PTR [SI+4],0	;trans to 32bits
GCDRES7:
	SET32
	MOV	BP,[SI+2]	;割る数
	SET32
	XOR	DX,DX		;余り
	MOV	CX,[DI]
	AND	CX,LENMASK
	JZ	GCDRES_RET	;割られる数が 0
	ADD	DI,CX
	ADD	DI,CX		;DI=16bit HIGHEST BASE
	SHR	CX,1
	JNC	GCDRES8
	INC	CX
	ADD	DI,2		;DI=32bit HIGHEST BASE
	MOV	WORD PTR [DI],0
GCDRES8:
	SUB	DI,2
	STD
	public	GCDRES10even
GCDRES10even:
GCDRES10:
	SET32
	MOV	AX,[DI]
	SET32
	DIV	BP
	QDEC	DI		;	STOSW
	myloop	GCDRES10	
	CLD

	MOV	SI,RESADR
	XOR	AX,AX
	SET32
	OR	DX,DX		;DX = REMAINDER
	JZ	GCDRES20
	SET32
	MOV	[SI+2],DX
	INC	AX
	SET32
	SHR	DX,16
	SET32
	OR	DX,DX
	JZ	GCDRES20
	INC	AX
GCDRES20:
	MOV	[SI],AX
	JMP	GCDRES_RET



	;多桁÷多桁	ABS((DI)) が ABS((SI)) 以上の場合

GCDRES30:

	;(SI) の上位 1 ワードを正規化して DIVWORD に

	CMP	AX,UNITWORD-1
	JMPNC	DIVERR		;都合上エラーとする

	ADD	SI,AX
	ADD	SI,AX

	XOR	CX,CX		;CX=正規化の為のSHIFT回数

	TEST	AL,1
	JZ	GCDRES50		;if odd
	INC	AX
	MOV	[DIVLEN],AX	;32BIT化
	MOV	WORD PTR [SI+2],0
	MOV	CX,16
GCDRES50:
	MOV	AL,[SI+1]
	OR	AL,AL
	JNZ	GCDRES70
	ADD	CX,8
	DEC	SI
GCDRES70:
	SUB	SI,2		;BASE OF HIGHEST 32BIT
	SET32
	MOV	AX,[SI]		;最上位ワード
	SET32
	MOV	DX,[SI-4]	;一つ前
	DEC	CX
GCDRES80:
	INC	CX
	SET32
	add	dx,dx
	SET32
	RCL	AX,1
	JNC	GCDRES80

	SET32
	RCR	AX,1
	SET32
	MOV	[DIVWORD],AX
	MOV	[SFTBIT],CX

	;LET RESADR BE 32 BIT

	MOV	DI,RESADR
	MOV	CX,[DI]
	AND	CX,LENMASK
	MOV	AX,CX		;MEMO
	INC	CX
	ADD	DI,CX
	ADD	DI,CX
	SET32
	MOV	WORD PTR [DI],0	;SET TO 32BIT 0
	DW	0		;
	TEST	AL,1
	JZ	GCDRES90
	INC	AX
	WINC	DI
	MOV	WORD PTR [DI+2],0
GCDRES90:
	SUB	DI,RESADR
	MOV	[PTRNOW],DI	;32BIT BASE OF OVER HIGHEST

	SUB	AX,[DIVLEN]
	MOV	CX,AX		;COUNTER
	add	ax,ax
	ADD	AX,2
	MOV	[PTRNOW2],AX	;32BIT BASE

;メイン・ループ
;32 bit 毎の商を BP に求める

	SHR	CX,1
	INC	CX
	PUSH	BP
GCDRES100:
	PUSH	CX
	CALL	LLDSUB32
	POP	CX
	MOV	AX,4
	SUB	[PTRNOW],AX
	SUB	[PTRNOW2],AX
	myloop	GCDRES100
	POP	BP

	;余りの長さを求める

	MOV	AX,[DIVLEN]
	MOV	CX,AX
	add	ax,ax
	ADD	AX,RESADR
	MOV	DI,AX
	XOR	AX,AX
	STD
	REPE	SCASW
	CLD
	JE	GCDRES110
	INC	CX
GCDRES110:
	MOV	DI,RESADR
	MOV	[DI],CX
	RET


CODE	ENDS


code2	segment	public
	assume	cs:code2, ds:data

	public	LLMULfast	;called by float

LLMbaseadr		equ	0

LLMxlen	equ	12
LLMxadr	equ	10
LLMylen	equ	8
LLMyadr	equ	6
LLMzadr	equ	4

	even
LLMheap		dw	?
LLMlendone	dw	?
LLMxlenmem	dw	?	;used by LLMshort
LLMxadrmem	dw	?	;
LLMylenmem	dw	?	;"


LLMULfast:

	;fast multiplication by Karatsuba's method
	;recursive use of
	; (at+b)(ct+d) = act^2 + (ac+bd-(b-a)(d-c))t + bd

	;implememtend by Yuji KIDA
	;    January 1996

	;inp	cx = word length of x
	;	bx = word length of y
	;	[dimem_m] = adr of x
	;	[simem_m] = adr of y

	mov	ax,data
	mov	dx,cx		;memo length of x
	add	ax,LLMULworkseg
	mov	es,ax

karatsubadebug	equ	0

if karatsubadebug
mov di,llmbaseadr
mov cx,LLMULworksegsize*8
mov ax,1951h
rep stosw
endif

	set32			;clear higher word
	xor	ax,ax		;
	set32			;
	mov	cx,ax		;

	mov	ax,dx
	mov	cx,dx

	mov	si,[dimem_m]
	inc	ax
	mov	di,LLMbaseadr
	shr	ax,1
	push	ax		;param1 = length of x
	push	di		;param2 = adr of x
	rep	movsw
	mov	es:[di],cx	;clear higher word

	mov	ax,dx
	and	ax,1
	add	ax,ax
	add	di,ax		;add 2 if odd length

	mov	ax,bx
	mov	cx,bx

	mov	si,[simem_m]
	inc	ax
	shr	ax,1
	push	ax		;param3 = length of y
	push	di		;param4 = adr of y
	rep	movsw
	mov	es:[di],cx	;clear higher word
				;thus we must copy
				;the sources
				;to avoid destruction
	mov	ax,bx
	and	ax,1
	add	ax,ax
	add	di,ax		;add 2 if odd length
	push	di		;param5 = result area
	inc	bx
	inc	dx
	and	bl,0feh
	and	dl,0feh
	add	bx,dx
	add	bx,bx
	add	di,bx
	mov	[LLMheap],di

	mov	ax,es
	mov	ds,ax

	call	LLMULfastsub
	pop	si		;adr of result
	pop	ax		;dummy
	pop	bx		;length of y
	pop	ax		;dummy
	pop	cx		;length of x

if karatsubadebug
push ds
push es
push bx
push cx
mov ax,data
add ax,LLMULworkseg
mov es,ax
mov cx,LLMULworksegsize*8
mov di,cx
add di,cx
sub di,2
mov ax,1951h
std
repe scasw
cld
mov ax,data
mov ds,ax
mov word ptr ds:[resadr],1
mov ds:[resadr+2],cx
pop cx
pop bx
pop es
pop ds
endif

	mov	ax,data
	mov	es,ax
	add	cx,bx
	retf


comment %
must do next after call LLMULfast
for the call by float.asm
also do not change ds in this routine

	mov	di,es:[dimem_m]
	set32
	rep	movsw

	mov	ax,data
	mov	ds,ax
%



LLMULshortequal:
	mov	cx,ax
LLMULshort:
	mov	[LLMxlenmem],ax
	mov	[LLMylenmem],cx
	mov	bx,[bp+LLMxadr]
	add	cx,ax
	mov	[LLMxadrmem],bx

	mov	di,[bp+LLMzadr]
	set32
	xor	ax,ax
	set32
	rep	stosw		;clear result

	mov	di,[bp+LLMyadr]
	mov	bx,[bp+LLMzadr]
	mov	cx,[LLMylenmem]
LLMULshort10:
	set32
	mov	bp,[di]
	qinc	di
	set32
	or	bp,bp
	jz	LLMULshort60

	push	cx
	push	bx
	mov	si,[LLMxadrmem]
	mov	cx,[LLMxlenmem]
LLMULshort20:
	mylodsd
	set32
	mul	bp
	set32
	add	[bx],ax
	qinc	bx
	set32
	adc	[bx],dx
	jnc	LLMULshort50
	mov	dx,bx		;push	bx
	set32
	xor	ax,ax
	stc
LLMULshort30:
	qinc	bx
	set32
	adc	[bx],ax		;eax = 0
	jc	LLMULshort30
	mov	bx,dx		;pop	bx
LLMULshort50:
	dec	cx
	jnz	LLMULshort20

	pop	bx
	pop	cx

LLMULshort60:
	qinc	bx
	dec	cx
	jnz	LLMULshort10

LLMshortret:
	pop	bp
	ret


LLMULfastsub:
	push	bp
	mov	bp,sp
	mov	ax,[bp+LLMxlen]
	mov	cx,[bp+LLMylen]
	cmp	ax,cx
	je	LLMfast100
	ja	LLMfastnotequal
	xchg	ax,cx
	mov	di,[bp+LLMxadr]
	mov	si,[bp+LLMyadr]
	mov	[bp+LLMxlen],ax
	xchg	di,si
	mov	[bp+LLMylen],cx
	mov	[bp+LLMxadr],di
	mov	[bp+LLMyadr],si
LLMfastnotequal:
	cmp	cx,LLMULswitchlen
	jbe	LLMULshort

LLMfast10:
	;* make b*d on z

	push	cx		;param1 = shorter len
	mov	[LLMlendone],cx
	mov	ax,[bp+LLMxadr]
	mov	cx,[bp+LLMyadr]
	push	ax		;param2
	push	[LLMheap]	;not use in subr but push/pop
	mov	dx,[bp+LLMzadr]
	push	cx		;param4
	push	dx		;param5
	call	LLMULfastsub2
	add	sp,4		;cancel 2 params
	pop	[LLMheap]
	add	sp,4		;cancel 2 params

	;* make a*d on heap
	;  separating by each LLMylen dwords

LLMfast20:
	mov	ax,[LLMlendone]
	mov	cx,[bp+LLMxlen]
	mov	dx,[bp+LLMylen]
	sub	cx,ax
	cmp	cx,dx
	jbe	LLMfast40

	push	dx		;param1 = len of x
	shl	ax,2
	mov	bx,[bp+LLMxadr]
	add	bx,ax
	push	bx		;param2	= adr of x
	mov	ax,[bp+LLMyadr]
	sub	sp,2		;dummy
	push	ax		;param4 = adr of y
	mov	ax,[LLMheap]
	push	ax		;param5 = adr of z
	shl	dx,3
	add	ax,dx
	mov	[LLMheap],ax
	call	LLMULfastsub2
	pop	[LLMheap]	;result in this area
	add	sp,8		;cancel 4 params

	;* add result to main adr with offset

	mov	ax,[LLMlendone]
	mov	cx,[bp+LLMylen]
	mov	di,[bp+LLMzadr]
	add	[LLMlendone],cx
	mov	dx,cx
	shl	ax,2
	mov	si,[LLMheap]
	add	di,ax
	set32
	xor	bx,bx
;	clc
LLMfast30:
	mylodsd
	set32
	adc	[di],ax
	qinc	di
	dec	cx
	jnz	LLMfast30
	mov	cx,dx
LLMfast35:
	mylodsd
	set32
	adc	ax,bx
	mystosd
	dec	cx
	jnz	LLMfast35
	jmp	LLMfast20


LLMfast40:
;	mov	ax,[LLMlendone]
;	mov	cx,[bp+LLMxlen]
;	mov	dx,[bp+LLMylen]
;	sub	cx,ax

	push	ax		;/* [LLMlendone]
	push	cx		;param1 = len of x
	shl	ax,2
	add	ax,[bp+LLMxadr]
	push	ax		;param2	= adr of x
	mov	ax,[bp+LLMyadr]
	push	dx		;param3 = len of y
	push	ax		;param4 = adr of y
	mov	ax,[LLMheap]
	add	cx,dx
	push	ax		;param5 = adr of z
	shl	cx,2
	add	ax,cx
	mov	[LLMheap],ax
	call	LLMULfastsub
	pop	[LLMheap]	;result in this area
	add	sp,8		;cancel 4 params

	;* add ad to main adr with offset

	pop	ax		;*/ [LLMlendone]
	mov	cx,[bp+LLMylen]
	mov	dx,[bp+LLMxlen]
	mov	di,[bp+LLMzadr]
	sub	dx,ax
	shl	ax,2
	mov	si,[LLMheap]
	add	di,ax
	set32
	xor	bx,bx
;	clc
LLMfast50:
	mylodsd
	set32
	adc	[di],ax
	qinc	di
	dec	cx
	jnz	LLMfast50

	mov	cx,dx
LLMfast55:
	mylodsd
	set32
	adc	ax,bx
	mystosd
	dec	cx
	jnz	LLMfast55

	pop	bp
	ret


LLMULfastsub2:
	push	bp
	mov	bp,sp
	mov	ax,[bp+LLMxlen]
	cmp	ax,LLMULswitchlen
	jbe	LLMULshortequal

LLMfast100:
	;* make b*d on z

	mov	ax,[bp+LLMxlen]
	inc	ax
	shr	ax,1		;ax = l
	mov	bx,[bp+LLMxadr]
	push	ax		;param1
	mov	cx,[bp+LLMyadr]
	push	bx		;param2
	push	[LLMheap]	;not use in subr but push/pop
	mov	dx,[bp+LLMzadr]
	push	cx		;param4
	push	dx		;param5
	call	LLMULfastsub2
;call	LLMshortin
	add	sp,4		;cancel 2 params
	pop	[LLMheap]
	add	sp,4		;cancel 2 params

	;* make a*c on z+2l

	mov	ax,[bp+LLMxlen]
	mov	dx,ax
	shr	ax,1		;= m
	inc	dx
	push	ax		;param1
	shr	dx,1		;dx = l
	shl	dx,2
	mov	ax,[bp+LLMxadr]
	add	ax,dx
	push	ax		;param2
	push	[LLMheap]	;not use in subr but push/pop
	mov	ax,[bp+LLMyadr]
	add	ax,dx
	push	ax		;param4
	add	dx,dx
	mov	ax,[bp+LLMzadr]
	add	ax,dx
	push	ax		;param5
	call	LLMULfastsub2
;call	LLMshortin
	add	sp,4		;cancel 2 params
	pop	[LLMheap]
	add	sp,4		;cancel 2 params

	;* make abs(b-a)(d-c) on heap

	mov	cx,[bp+LLMxlen]
	mov	dx,cx
	shr	cx,1		;cx = m
	inc	dx
	shr	dx,1		;dx = l
	mov	bx,[bp+LLMxadr]	;bx = adr of b
	shl	dx,2		;dx = 4l
	mov	si,bx
	mov	di,[LLMheap]	;di = adr of b-a
	add	si,dx		;si = adr of a
	shr	dx,2		;dx = l
	call	LLMfsub
	sbb	cx,cx
	push	cx		;/sign

	mov	bx,[bp+LLMyadr]	;bx = adr of d
	mov	cx,[bp+LLMxlen]
	mov	si,bx
	mov	dx,cx
	shr	cx,1		;cx = m
	inc	dx
	shr	dx,1		;dx = l
	shl	dx,2
	add	si,dx		;si = adr of c
	shr	dx,2		;dx = l
	call	LLMfsub

	;now di is heap next adr

	sbb	cx,cx
	pop	ax
	xor	ax,cx		;ax = sign of (b-a)(d-c)
	push	ax		;sign/

	mov	cx,[bp+LLMxlen]
	mov	ax,[LLMheap]
	inc	cx
	shr	cx,1		;cx = l
	push	cx		;param1
	push	ax		;param2 = adr of b-a
	sub	sp,2		;param3 = dummy
	shl	cx,2
	add	ax,cx
	push	ax		;param4 = adr of d-c

	push	di		;param5 = adr of result
	add	di,cx
	add	di,cx
	mov	[LLMheap],di

	call	LLMULfastsub2
;call	LLMshortin
	pop	[LLMheap]	;result in this area
	add	sp,8		;cancel 4 params
	pop	dx		;/sign
	or	dx,dx
	jz	LLMfast115	;if (b-a)(d-c) is positive

	;* add bd to abs(b-a)(d-c)
	;   if (b-a)(d-c) is negative

	mov	cx,[bp+LLMxlen]
	mov	si,[bp+LLMzadr]
	inc	cx
	mov	di,[LLMheap]
	and	cl,0feh		;cx = 2l
	set32
	xor	dx,dx
	;clc
LLMfast110:
	mylodsd
	set32
	adc	[di],ax
	qinc	di
	dec	cx
	jnz	LLMfast110
	adc	dx,dx		;edx = carry = 0 or 1
	jmp	LLMfast120

LLMfast115:
	;* add bd to -abs(b-a)(d-c)
	;   if (b-a)(d-c) is positive

	mov	cx,[bp+LLMxlen]
	mov	si,[bp+LLMzadr]
	inc	cx
	mov	di,[LLMheap]
	and	cl,0feh		;cx = 2l
	set32
	xor	dx,dx
	;clc
LLMfast110B:
	mylodsd
	set32
	sbb	ax,[di]
	mystosd
	dec	cx
	jnz	LLMfast110B
	set32
	sbb	dx,dx		;edx = borrow = 0 or -1

LLMfast120:

	;* add ac to bd+(b-a)(c-d)

	mov	ax,[bp+LLMxlen]
	mov	si,[bp+LLMzadr]
	mov	cx,ax
	inc	ax
	mov	di,[LLMheap]
	and	al,0feh		;ax = 2l
	and	cl,0feh		;cx = 2m
	shl	ax,2
	add	si,ax		;z+8l
	shr	ax,2
	cmp	ax,cx
	jne	LLMfast135	;if l>m
	clc
LLMfast130:
	mylodsd
	set32
	adc	[di],ax
	qinc	di
	dec	cx
	jnz	LLMfast130
	jmp	LLMfast140

LLMfast135:
	clc
LLMfast136:
	mylodsd
	set32
	adc	[di],ax
	qinc	di
	dec	cx
	jnz	LLMfast136
	set32
	adc	[di],cx
	qinc	di
	set32
	adc	[di],cx

LLMfast140:
	set32
	adc	dx,cx		;edx = carry = 0 or 1

	;* add (ad+bc) to main adr with offset l

	mov	cx,[bp+LLMxlen]
	mov	di,[bp+LLMzadr]
	inc	cx
	mov	si,[LLMheap]
	and	cl,0feh		;cx = 2l
	add	di,cx
	add	di,cx		;di = z+4l
	clc
LLMfast150:
	mylodsd
	set32
	adc	[di],ax
	qinc	di
	dec	cx
	jnz	LLMfast150
	set32
	adc	[di],dx
	jc	LLMfast160
	pop	bp
	ret

LLMfast160:
	qinc	di
	set32
	adc	[di],cx		;ecx = 0
	jc	LLMfast160
	pop	bp
	ret


;
;* long square
;

LLSQswitchlength	equ	12
LLSQlen		equ	8
LLSQx		equ	6
LLSQz		equ	4

	even
LLSQheap	dw	?
LLSQlenmem	dw	?	;used by LLSQshort


LLSQUAREfast:
	;inp	cx = word length
	;	di = target

	push	di		;/*

	mov	ax,data
	mov	dx,cx		;memo length
	add	ax,LLMULworkseg
	mov	bx,di		;memo target
	mov	es,ax

if karatsubadebug
mov di,llmbaseadr
mov cx,LLMULworksegsize*8
mov ax,1951h
rep stosw
endif

	set32			;clear higher word
	xor	ax,ax		;
	set32			;
	mov	cx,ax		;

	mov	ax,dx
	mov	cx,dx

	mov	si,bx
	inc	ax
	mov	di,LLMbaseadr
	shr	ax,1
	push	ax		;param1 = dword length
	push	di		;param2 = adr of x
	rep	movsw
	mov	es:[di],cx	;clear higher word

	mov	ax,dx
	and	ax,1
	add	ax,ax
	add	di,ax		;add 2 if odd length

	push	di		;param3 = result area
	shl	dx,3
	add	dx,di
	mov	[LLSQheap],dx

	mov	ax,es
	mov	ds,ax

	call	LLSQfastsub
	pop	si		;result
	pop	cx		;dummy
	pop	cx		;dword length

	mov	ax,data
	mov	es,ax

	add	cx,cx

	pop	di		;*/
	set32
	rep	movsw

if karatsubadebug
push cx
push es
mov ax,data
add ax,LLMULworkseg
mov es,ax
mov cx,LLMULworksegsize*8
mov di,cx
add di,cx
sub di,2
mov ax,1951h
std
repe scasw
cld
mov ax,data
mov ds,ax
mov word ptr ds:[resadr],1
mov ds:[resadr+2],cx
pop es
pop cx
endif

	mov	ax,data
	mov	ds,ax
	retf



LLSQshortin:
	push	bp
	mov	bp,sp
	mov	cx,[bp+LLSQlen]
LLSQshort:
;	mov	cx,[bp+LLSQlen]
	mov	di,[bp+LLSQx]
	mov	dx,cx		;dx = len
	shl	cx,2
	set32
	xor	ax,ax
	add	di,cx
	shr	cx,1		;cx = 2len
LLSQshort6:
	sub	di,4
	set32
	cmp	ax,[di]		;check highest dword
	jne	LLSQshort8
	dec	dx
	jnz	LLSQshort6
	mov	di,[bp+LLSQz]
	set32
	rep	stosw		;clear result
	jmp	LLSQshortret

LLSQshort8:
	mov	[LLSQlenmem],dx

	;1st calc square parts

	mov	di,[bp+LLSQx]
	mov	bx,[bp+LLSQz]
	mov	cx,[bp+LLSQlen]	;not [LLSQlenmem]
LLSQshortLP1:
	set32
	mov	ax,[di]
	qinc	di
	set32
	mul	ax
	set32
	mov	[bx],ax
	qinc	bx
	set32
	mov	[bx],dx
	qinc	bx
	dec	cx
	jnz	LLSQshortLP1

	;2nd calc non-square parts

	mov	di,[bp+LLSQx]
	mov	bx,[bp+LLSQz]
	mov	cx,[LLSQlenmem]
	dec	cx
	jz	LLSQshortret
LLSQshortLP2:
	qinc	bx
	set32
	mov	bp,[di]
	qinc	di
	set32
	or	bp,bp
	jz	LLSQshort60

	push	cx
	push	bx
	mov	si,di
LLSQshort20:
	mylodsd
	set32
	mul	bp
	set32
	add	ax,ax
	set32
	adc	dx,dx
	jc	LLSQshort70
	set32
	add	[bx],ax
	qinc	bx
	set32
	adc	[bx],dx
	jnc	LLSQshort50
	mov	dx,bx		;push	bx
	set32
	xor	ax,ax
	stc
LLSQshort30:
	qinc	bx
	set32
	adc	[bx],ax		;eax = 0
	jc	LLSQshort30
LLSQshort40:
	mov	bx,dx		;pop	bx
LLSQshort50:
	dec	cx
	jnz	LLSQshort20

	pop	bx
	pop	cx

LLSQshort60:
	qinc	bx
	dec	cx
	jnz	LLSQshortLP2

LLSQshortret:
	pop	bp
	ret

LLSQshort70:
	push	di
	set32
	xor	di,di
	inc	di
	set32
	add	[bx],ax
	qinc	bx
	set32
	adc	[bx],dx
	mov	dx,bx		;push	bx
	qinc	bx
	set32
	adc	[bx],di
	jnc	LLSQshort90
	xor	di,di
	stc
LLSQshort80:
	qinc	bx
	set32
	adc	[bx],di		;edi = 0
	jc	LLSQshort80
LLSQshort90:
	pop	di
	jmp	LLSQshort40



LLSQfastsub:
	push	bp
	mov	bp,sp
	mov	cx,[bp+LLSQlen]
	cmp	cx,LLSQswitchlength
	jbe	LLSQshort

	;* make b^2 on z

	mov	cx,[bp+LLSQlen]
	push	[LLSQheap]
	inc	cx
	shr	cx,1		;cx = l
	push	cx		;param1
	mov	ax,[bp+LLSQx]
	push	ax		;param2
	mov	ax,[bp+LLSQz]
	push	ax		;param3
	call	LLSQfastsub
;call	LLSQshortin
	add	sp,6		;cancel 3 params
	pop	[LLSQheap]

	;* make a^2 on z+2l

	mov	ax,[bp+LLSQlen]
	push	[LLSQheap]
	mov	dx,ax
	shr	ax,1		;= m
	inc	dx
	push	ax		;param1
	shr	dx,1		;dx = l
	mov	ax,[bp+LLSQx]
	shl	dx,2
	add	ax,dx
	add	dx,dx
	push	ax		;param2
	mov	ax,[bp+LLSQz]
	add	ax,dx
	push	ax		;param3
	call	LLSQfastsub
;call	LLSQshortin
	add	sp,6		;cancel 3 params
	pop	[LLSQheap]

	;* make (b-a)^2 on heap

	mov	cx,[bp+LLSQlen]
	mov	dx,cx
	shr	cx,1		;cx = m
	inc	dx
	shr	dx,1		;dx = l
	mov	bx,[bp+LLSQx]	;bx = adr of b
	push	dx		;ist param = l
	shl	dx,2		;dx = 4l
	mov	si,bx
	mov	di,[LLSQheap]	;di = adr of b-a
	add	si,dx		;si = adr of a
	push	di		;2nd param = adr of b-a
	shr	dx,2		;dx = l
	call	LLMfsub
	push	di		;3rd param = adr of result

	mov	ax,[bp+LLSQlen]
	inc	ax
	shr	ax,1		;ax = l
	shl	ax,3
	add	ax,di
	mov	[LLSQheap],ax	;needs 2l dwords for result area
	call	LLSQfastsub
;call	LLSQshortin
	pop	[LLSQheap]	;result in this area
	add	sp,4		;cancel 2 params

	;* add b^2 to -(b-a)^2

	mov	cx,[bp+LLSQlen]
	mov	si,[bp+LLSQz]	;adr of b^2
	inc	cx
	mov	di,[LLSQheap]
	and	cl,0feh		;cx = 2l
	set32
	xor	dx,dx		;for last borrow
	;clc
LLSQfast110:
	mylodsd
	set32
	sbb	ax,[di]
	mystosd
	dec	cx
	jnz	LLSQfast110
	set32
	sbb	dx,dx		;edx = borrow = 0 or -1

	;* add a^2 to b^2-(b-a)^2

	mov	ax,[bp+LLSQlen]
	mov	si,[bp+LLSQz]
	mov	cx,ax
	inc	ax
	mov	di,[LLSQheap]
	and	al,0feh		;ax = 2l
	and	cl,0feh		;cx = 2m
	shl	ax,2
	add	si,ax		;z+8l
	shr	ax,2
	cmp	ax,cx
	jne	LLSQfast135	;if l>m
	clc
LLSQfast130:
	mylodsd
	set32
	adc	[di],ax
	qinc	di
	dec	cx
	jnz	LLSQfast130
	jmp	LLSQfast140

LLSQfast135:
	clc
LLSQfast136:
	mylodsd
	set32
	adc	[di],ax
	qinc	di
	dec	cx
	jnz	LLSQfast136
	set32
	adc	[di],cx		;ecx = 0
	qinc	di
	set32
	adc	[di],cx		;ecx = 0

LLSQfast140:
	set32
	adc	dx,cx		;edx = carry

	;* add 2ab to main adr with offset l

	mov	ax,[bp+LLSQlen]
	mov	di,[bp+LLSQz]
	inc	ax
	mov	si,[LLSQheap]
	and	al,0feh		;ax = 2l
	mov	cx,ax
	add	ax,ax
	add	di,ax		;di = z+4l
	clc
LLSQfast150:
	mylodsd
	set32
	adc	[di],ax
	qinc	di
	dec	cx
	jnz	LLSQfast150
	set32
	adc	[di],dx		;add carry of 2ab
	jc	LLSQfast160
	pop	bp
	ret

LLSQfast160:
	qinc	di
	set32
	adc	[di],cx		;ecx = 0
	jc	LLSQfast160
	pop	bp
	ret


comment %
LLMfadd:
	;inp	dx = l
	;	cx = m

	cmp	dx,cx
	je	LLMfast20	;if l=m
	clc
LLMfast10:
	set32
	mov	ax,[bx]		;[di] = [bx]+[si]
	qinc	bx
	set32
	adc	ax,[si]
	qinc	si
	set32
	mov	[di],ax
	qinc	di
	dec	cx
	jnz	LLMfast10
	set32
	mov	ax,[bx]
	set32
	adc	ax,cx		;ecx=0
	set32
	mov	[di],ax
	qinc	di
	set32
	adc	cx,cx		;ecx = carry
	set32
	mov	[di],cx		;len = l + cx
	qinc	di
	ret

LLMfast20:
	set32
	mov	ax,[bx]		;[di] = [bx]+[si]
	qinc	bx
	set32
	adc	ax,[si]
	qinc	si
	set32
	mov	[di],ax
	qinc	di
	dec	cx
	jnz	LLMfast20
	set32
	adc	cx,cx		;ecx = carry
	set32
	mov	[di],cx		;len = l + cx
	qinc	di
	ret
%


LLMfsub:
	;[di] = [bx]-[si]
	;inp	dx = l
	;	cx = m

	cmp	dx,cx
	je	LLMsub20	;if l=m
	clc
LLMsub10:
	set32
	mov	ax,[bx]
	qinc	bx
	set32
	sbb	ax,[si]
	qinc	si
	set32
	mov	[di],ax
	qinc	di
	dec	cx
	jnz	LLMsub10
	set32
	mov	ax,[bx]
	set32
	sbb	ax,cx		;ecx=0
	set32
	mov	[di],ax
	qinc	di
	jb	LLMsub15
	ret

; if negative then take abs

LLMsub15:
	mov	ax,dx
	mov	cx,dx
	shl	ax,2
	set32
	xor	dx,dx
	sub	di,ax
	stc
LLMsub17:
	set32
	mov	ax,[di]
	set32
	not	ax
	set32
	adc	ax,dx
	set32
	mov	[di],ax
	qinc	di
	dec	cx
	jnz	LLMsub17
	stc
	ret

LLMsub20:
	set32
	mov	ax,[bx]
	qinc	bx
	set32
	sbb	ax,[si]
	qinc	si
	set32
	mov	[di],ax
	qinc	di
	dec	cx
	jnz	LLMsub20
	jb	LLMsub15
	ret


code2	ends
end
