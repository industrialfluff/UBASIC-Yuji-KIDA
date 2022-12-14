;excom1.asm


DATA	SEGMENT	WORD PUBLIC

	EXTRN	EDITPTR:WORD
	extrn	chars1:byte,chars2:word,charsall2:word
	extrn	xpos:byte,ypos:byte
	extrn	contadr:word
	extrn	fnamebuf:byte,lnend:word

	PUBLIC	ADRMEM1,TYPMEM1,nowlin
	PUBLIC	dataptr,DATAFLG,schoolflg

  if GRAPH
    if FLGIBMTOS
	extrn	graphflg:byte
    endif
  endif


;SORT 用変数

DIRECTION	DW	?	;SORT の方向
SORTUNIT	DW	?
SORTBASEOFF	DW	?
SORTBASESEG	DW	?
S_PTR	DW	?
S_OFF	DW	?
S_SEG	DW	?
I_PTR	DW	?
I_OFF	DW	?
I_SEG	DW	?
J_PTR	DW	?
J_OFF	DW	?
J_SEG	DW	?
E_PTR	DW	?

DATAPTR	DW	?		;read-data pointer
DATAFLG	DB	?,?		;

ADRMEM1	DD	?
ADRMEM2	DD	?
TYPMEM1	DB	?
TYPMEM2	DB	?

vchg_sp		dw	?
nowtop		dw	?
nowlin		dw	?
ENDVAR		DW	?
XREFSW		DB	?

SWAPTYPE	DB	0
schoolflg	db	0


DATA	ENDS



CODE	SEGMENT WORD PUBLIC
	ASSUME	CS:CODE,DS:DATA



;PUBLIC LABELS

	PUBLIC	SWAP,REDUCE
	PUBLIC	GETVADR,fargetvadr,GETSAVADR,GETLAVADR,GETLLAVADR
	PUBLIC	STORESV,STORELV,STORELLV
	PUBLIC	BEEPIN,BEEPSUB
	PUBLIC	READIN,RESTORE,FIND
	public	autoin,autosub,srcvar1st,srcvarnext
	public	vlist,lvlist,vxref,lvxref,vchg
	PUBLIC	XREFIN,LXREFIN


;EXTERNAL LABELS
	EXTRN	GETGCD:NEAR,idivIIdisi:near
	EXTRN	RESVAR:NEAR,CLOSEALL:NEAR
	EXTRN	MAINLP:NEAR,READY:NEAR
	EXTRN	GETLABELADR:NEAR
	EXTRN	KAKKO:NEAR
	EXTRN	FORMUL:NEAR,PASSTOKEN:NEAR
	EXTRN	RESTOREFILE:NEAR
	extrn	farGet_ax:far
	extrn	discompileall:near,discompilegoto:NEAR
	extrn	discompilejp:near,discompilevar:near
	extrn	kanji1st?:near,farrep_cmpsb_label:far

	extrn	swapema:near

	extrn	cursor:near,decode:near
	extrn	numer?:near
	extrn	hotst:near
	extrn	get_ltop:near
	extrn	wait:near
	extrn	chg2cap:near,closeall:near

	extrn	farlistsub:far
	extrn	farDiscompilegoto:far,farDISCOMPILEJP:far
	extrn	farDISCOMPILEALL:far
	extrn	farRESVAR:far,farCLOSEALL:far
	extrn	farFormul:far,farKakko:far
	extrn	gosubsp:word

	EXTRN	SYNERR:NEAR,TYPEERR:NEAR,OVRERR:NEAR,areafull:near
	EXTRN	UNDEFERR:NEAR,INDEXERR:NEAR,CONTERR:NEAR
	EXTRN	NODATAERR:NEAR,ILGERR:NEAR,DISKERR:NEAR
	EXTRN	NOTOPEN:NEAR,ILGLET:NEAR
	EXTRN	STACKFULL:NEAR,STACKEMPTY:NEAR,cantdo:near

;
;☆☆コマンドの実行(その１)
;

;☆ ＸＲＥＦ，ＬＸＲＥＦの処理
;行番号のクロスリファレンス・リスト出力

LXREFIN:
	OR	[OUT_DEV],BIT1	;プリンタ・オン

XREFIN:
	CALL	LETNL
	CALL	discompilegoto
	CALL	PARASE
	jmp	far ptr farXREFIN

;
;* variable name change
;
vchg:
	jmp	far ptr farVchg


;
;* Variable list
;
LVLIST:	
	OR	[OUT_DEV],BIT1	;プリンタ・オン

VLIST:	
	CALL	discompileall
	jmp	far ptr farVLIST


;☆変数のクロスリファレンス・リスト出力

LVXREF:	
	OR	[OUT_DEV],BIT1	;プリンタ・オン

VXREF:	
	CALL	LETNL
	CALL	discompileall
	jmp	far ptr farVXREF


;☆変数のサーチ
;INPUT	SI=開始行の先頭番地
;OUTPUT CF=0 iff exist
;	SI=変数名のあるテキストの番地

farSRCVAR1ST:
	call	SRCVAR1ST
	retf
farSRCVARNEXT:
	call	SRCVARNEXT
	retf
farSRCVARLP10:
	call	SRCVARLP10
	retf

SRCVAR1ST:
	MOV	SI,TXTHED
SRCVARLP10:
	mov	[nowtop],si
	LODSW
	OR	AX,AX
	JZ	ENDTXT		;次の先頭が 0000H なのは最終行
	LODSW
	MOV	[NOWLIN],AX	;現行番号
	INC	SI		;PASS SPACE#
SRCVARNEXT:	
SRCVARLP20:
	LODSB
SRCVARLP30:
	CMP	AL,CR
	JE	SRCVARLP10	;if end of line
	CMP	AL,VCODE
	JB	SRCVARPASS
	CMP	AL,VCODE5
	JBE	GETVAR
SRCVARPASS:
	CALL	PASSTOKEN
	JMP	SRCVARLP20

GETVAR:
	DEC	SI
	CLC
	RET

ENDTXT:				;変数がない
	STC
	RET	


;** AUTO

AUTOIN:
  if GRAPH
    if FLGIBMTOS
	call	far ptr farreturn2text
    endif
  endif
	mov	[autoxpos],8
	MOV	DX,[AUTONUM]
	CALL	PARASE
	OR	DX,DX
	JNZ	AUTO10
	xor	dx,dx		;if not assigned
	mov	si,txthed	;add last
auto6:
	lodsw
	or	ax,ax
	jz	auto8
	mov	dx,[si]
	mov	si,ax
	jmp	auto6
auto8:
	add	dx,10
	jnc	auto10
	sub	dx,10
AUTO10:
	SUB	DX,10
	MOV	[AUTONUM],DX
	MOV	[AUTOFLG],-1
	CALL	TROFFSUB
	JMP	HOTST

AUTOSUB:
	MOV	CX,[AUTONUM]
	ADD	CX,10
	CALL	SRCLIN
	JNZ	AUTO100		;new line number
	mov	al,[bx+4]
	add	al,5
	mov	[autoxpos],al
	MOV	SI,BX
	CALL	far ptr farLISTSUB
	DEC	[YPOS]
	PUSH	DS
	CALL	GET_LTOP
	POP	DS
	MOV	AX,SI
	MOV	BX,[chars2]
	XOR	DX,DX
	DIV	BX
	MOV	[YPOS],AL
	mov	al,[autoxpos]
	MOV	[XPOS],al
	JMP	CURSOR		;call & ret

AUTO100:
	mov	bx,cx
	call	prbxsp		;display line number
	xor	cx,cx
	mov	cl,[autoxpos]
	sub	cx,5
auto110:
	call	prspc
	myloop	auto110
	ret


;
;☆ FIND
;   関数であるが SORT との関連によりここで実行
;
FIND:
	call	far ptr farFIND
	ret


;
;☆ ＲＥＳＴＯＲＥ の処理
;
RESTORE:
	MOV	AL,[BP]
	CMP	AL,'#'
	JMPZ	RESTOREFILE
	CMP	AL,NCODE1
	JNE	RESTORELABEL?
	MOV	CX,[BP+1]
	CALL	SRCLIN
	JNZ	RESTOREERR
	ADD	BX,5		;NEXT ADR,LINE#,SPACE#をパス
	ADD	BP,3
RESTOREOUT:
	MOV	[DATAPTR],BX
	MOV	[DATAFLG],0
	JMP	MAINLP

RESTORELABEL?:
	CMP	AL,NCODE_LABEL
	JNE	RESTORESYNERR
	CALL	GETLABELADR
	MOV	BX,AX
	JMP	RESTOREOUT

RESTOREERR:
	JMP	NODATAERR

RESTORESYNERR:
	JMP	SYNERR

;
;☆ ＲＥＡＤ の処理
;

READIN:
	CALL	SEARCHPTR	;DATA位置のサーチ
	PUSH	BP
	MOV	BP,[DATAPTR]
	CALL	FORMUL
	MOV	[DATAPTR],BP
	MOV	[DATAFLG],-1
	POP	BP
	CALL	INPLET		;あとは INPUT に任せる
	cmp	byte ptr [bp],0c2h	;code of ,
	JMPNZ	MAINLP
	INC	BP
	JMP	READIN

SEARCHPTR:
	MOV	SI,[DATAPTR]
	CMP	[DATAFLG],0
	JE	SRCPTR20
	LODSB
	CMP	AL,0C2H		;CODE OF ,
	JE	SRCPTRRET	;次は式のはず
	JMPS	SRCPTR25	
SRCPTR20:
	LODSB
SRCPTR25:
	CMP	AL,CR
	JE	SRCPTR30
	CMP	AL,9CH		;code of DATA
	JE	SRCPTRRET
	CALL	PASSTOKEN
	JMP	SRCPTR20
SRCPTR30:
	CMP	WORD PTR [SI],0
	JE	NODATA		;DATA がなくなった
	ADD	SI,5		;pass next adr,line#,space#
	JMP	SRCPTR20

SRCPTRRET:
	LODSB			;' ' をスキップ
	CMP	AL,' '
	JE	SRCPTRRET
	DEC	SI
	MOV	[DATAPTR],SI
	RET

SRCPTRSYNERR:
	JMP	SYNERR

NODATA:
	JMP	NODATAERR
	

;
;☆ ＢＥＥＰ の処理
;

BEEPIN:
	jmp	far ptr farBEEPIN

beepsub:
	call	far ptr farBeepsub
	ret

;
;☆ＲＥＤＵＣＥの処理
;二つのパラメータをその最大公約数で割る


REDSYNERR:
	JMP	SYNERR
RED_ILG:
	JMP	ILGERR

REDUCE:	

	;第一引数の番地と型を得る

	MOV	AL,[BP]
	MOV	[TYPMEM1],AL	;第一引数の型
	CALL	GETVADR

	;第一引数をスタックへ

	MOV	WORD PTR SS:[ADRMEM1],SI	;第一引数の OFFSET
	MOV	WORD PTR SS:[ADRMEM1+2],DS	;第一引数の SEGMENT
	CMP	BYTE PTR SS:[TYPMEM1],VCODE2
	JAE	REDUCE10
	CALL	PUSHSV
	JMPS	REDUCE20
REDUCE10:
	CALL	PUSHLV
REDUCE20:
	MOV	AX,SS
	MOV	DS,AX

	cmp	byte ptr [bp],0c2h	;code of ,
	JNZ	REDSYNERR
	INC	BP

	;第二引数の番地と型を得る

	MOV	AL,[BP]
	MOV	[TYPMEM2],AL	;第二引数の型
	CALL	GETVADR

	;第二引数をスタックへ

	MOV	WORD PTR SS:[ADRMEM2],SI	;第二引数の OFFSET
	MOV	WORD PTR SS:[ADRMEM2+2],DS	;第二引数の SEGMENT
	CMP	BYTE PTR SS:[TYPMEM2],VCODE2
	JAE	REDUCE30
	CALL	PUSHSV
	JMPS	REDUCE40
REDUCE30:
	CALL	PUSHLV
REDUCE40:
	;符号を決める

	MOV	DI,[CALCSP]	;第二引数の番地
	MOV	SI,DI
	ADD	SI,UNITBYTE	;第一引数の番地
	MOV	CX,[DI]
	MOV	AX,CX
	OR	CX,[SI]
	TEST	CH,POINTCOMPSTRHIGH
	JNZ	RED_ILG		;小数は不可

	TEST	AX,LENMASK
	JMPZ	SET_M1?		;第二引数=0

	;第二引数の符号を調べる
	;正ならばそのまま、負ならば正にして
	;第一引数の符号を逆に

	TEST	AH,80H
	JZ	SGNOUT
	AND	WORD PTR [DI],lenmask

	MOV	AX,[SI]
	OR	AX,AX
	JZ	SET_N1			;if M=0 let N=1

	XOR	AH,80H
	MOV	[SI],AX

SGNOUT:	
	;GCD を計算

	CALL	GETGCD

	;N を GCD で割る

	MOV	DI,[CALCSP]
	MOV	SI,work3		;GCDADR
	call	idivIIdisi

	;N を戻す

	MOV	SI,[CALCSP]
	LES	DI,[ADRMEM2]
	MOV	AL,[TYPMEM2]
	CMP	AL,VCODE4
	JAE	REDUCE100
	CMP	AL,VCODE2
	JAE	REDUCE110
	CALL	STORESV		;短変数のセット
	JMPS	REDUCE120
REDUCE100:
	CALL	STORELLV	;特別変数のセット
	JMPS	REDUCE120
REDUCE110:
	CALL	STORELV		;長変数のセット
	JMPS	REDUCE120
REDUCE120:

	;M を GCD で割る

	MOV	DI,[CALCSP]
	ADD	DI,UNITBYTE
	MOV	[CALCSP],DI
	MOV	SI,work3	;GCDADR
	call	idivIIdisi

	;M を戻す

	MOV	SI,[CALCSP]
	LES	DI,[ADRMEM1]
	MOV	AL,[TYPMEM1]
	CMP	AL,VCODE4
	JAE	REDUCE130
	CMP	AL,VCODE2
	JAE	REDUCE135
	CALL	STORESV		;短変数のセット
	JMPS	REDUCE140
REDUCE130:
	CALL	STORELLV	;特別変数のセット
	JMPS	REDUCE140
REDUCE135:
	CALL	STORELV		;長変数のセット

	;CALCSP を元に戻して終了
REDUCE140:
	MOV	DI,[CALCSP]
	ADD	DI,UNITBYTE

REDUCEOUT:
	MOV	[CALCSP],DI
	JMP	MAINLP


	;N を 1 に
SET_N1:	
	LES	DI,[ADRMEM2]
	MOV	AL,[TYPMEM2]
	JMPS	SET_1

SET_M1?:	
	MOV	AX,[SI]		;第二引数が 0 かつ
	AND	AX,LENMASK	;第一引数が 0 ならば
	JZ	SET_0		;終わり

	;M を 1 に
SET_M1:	
	LES	DI,[ADRMEM1]
	MOV	AL,[TYPMEM1]

SET_1:	
	MOV	WORD PTR ES:[DI],1
	CMP	AL,VCODE2
	JB	SET1_OUT
	MOV	WORD PTR ES:[DI+2],1
SET1_OUT:
	MOV	AX,SS
	MOV	ES,AX
SET_0:				;REMAIN UNCHANGED(=0)
	MOV	DI,[CALCSP]
	ADD	DI,UNITBYTE*2
	JMP	REDUCEOUT


;☆[CALCSP] を一つ深くして DS:SI の短変数を PUSH する

PUSHSV:
	MOV	AX,[SI]		;値
	MOV	DI,SS		;DS を普通に戻す
	MOV	DS,DI
	MOV	DI,[CALCSP]
	SUB	DI,UNITBYTE
	MOV	[CALCSP],DI
	OR	AX,AX
	JNZ	PUSHSV10
	MOV	[DI],AX
	RET
PUSHSV10:
	MOV	CX,AX
	AND	AH,80H
	MOV	AL,1
	MOV	[DI],AX		;ATTRIBUTE
	AND	CH,7FH
	MOV	[DI+2],CX
	RET
		
;☆[CALCSP] を一つ深くして DS:SI の長・特別変数を PUSH する

PUSHLV:
	MOV	DI,SS:[CALCSP]
	SUB	DI,UNITBYTE
	MOV	SS:[CALCSP],DI
	copy_si2di_ax

	MOV	AX,SS
	MOV	DS,AX
	RET

;☆DS:SI の標準FORMAT数を ES:DI の短変数へ

STORESV:
	MOV	AX,[SI]
	MOV	CX,AX
	AND	AX,LENMASK
	JZ	STORESV10
	CMP	AX,1
	JA	STOREOVR
	MOV	AX,[SI+2]
	CMP	AH,80H
	JAE	STOREOVR
	AND	CH,80H
	OR	AH,CH
STORESV10:
	MOV	ES:[DI],AX
	MOV	AX,SS
	MOV	ES,AX
	RET

STOREOVR:
	JMP	OVRERR

;☆DS:SI の標準FORMAT数を ES:DI の長変数へ

STORELV:
	MOV	CX,[SI]
	AND	CX,LENMASK
	CMP	CX,[MAXWORD]
	JA	STOREOVR
	INC	CX
	REP	MOVSW
	MOV	AX,SS
	MOV	ES,AX
	RET

;☆DS:SI の標準FORMAT数を ES:DI の特別変数へ

STORELLV:
	copy_si2di_ax

	MOV	AX,SS
	MOV	ES,AX
	RET


;
;☆変数の値の交換
;

SWAPUNDEF:
	JMP	UNDEFERR

SWAPSYNERR:
	JMP	SYNERR

SWAPTYPEERR:
	JMP	TYPEERR

swap_option:
	cmp	word ptr [bp],0f580h	;code of ema(
	jne	swapsynerr	
	add	bp,2
	jmp	swapema

SWAP:	
	;アドレスを求め型をチエック

	CMP     BYTE PTR [BP],0A2H	;BLOCK
	JMPZ	SWAPBLK		;配列の BLOCK SWAP
	MOV	AL,[BP]
	cmp	al,80h
	je	swap_option
	SUB	AL,VCODE
	SHR	AL,1
	jz	swapsv
	cmp	al,2
	jbe	SWAPLV		;長 OR 特別変数
	jmp	ilgerr
	
;短変数の場合

swapsv:
	CALL	GETVADR
	MOV	AX,[SI]
	PUSH	DS		;第一の変数のデータを
	PUSH	SI		;PUSH
	PUSH	AX		;

	MOV	AX,SS
	MOV	DS,AX

	cmp	byte ptr [bp],0c2h	;code of ,
	JNE	SWAPSYNERR
	INC	BP
	MOV	AL,[BP]
	SUB	AL,VCODE
	SHR	AL,1
	JNZ	SWAPTYPEERR	;型が違う
	CALL	GETVADR
	MOV	AX,[SI]		;2ND VALUE

	POP	BX		;第一の変数の値をPOP
	MOV	[SI],BX
	POP	SI		;第一の変数のアドレスをPOP
	POP	DS		;
	MOV	[SI],AX
SWAPRET:
	MOV	AX,SS
	MOV	DS,AX
	JMP	MAINLP


;長変数の場合

SWAPLV:
	MOV	[SWAPTYPE],AL
	CALL	GETVADR
	PUSH	DS
	PUSH	SI
	MOV	AX,SS
	MOV	DS,AX

	cmp	byte ptr [bp],0c2h	;code of ,
	JNE	SWAPSYNERR
	INC	BP
	MOV	AL,[BP]
	SUB	AL,VCODE
	SHR	AL,1
	CMP	AL,[SWAPTYPE]
	JNE	SWAPTYPEERR	;型が違う

	CALL	GETVADR

	POP	DI
	POP	ES

	;NOW DS:SI=2ND,ES:DI=1ST
SWAPLVIN:
	MOV	CX,[SI]
	AND	CX,LENMASK
	MOV	AX,ES:[DI]
	AND	AX,LENMASK
	CMP	CX,AX
	JAE	SWAPLV10
	MOV	CX,AX
SWAPLV10:
	INC	CX
SWAPLV20:
	MOV	AX,ES:[DI]
	MOVSW
	MOV	[SI-2],AX
	myloop	SWAPLV20

	MOV	AX,SS
	MOV	DS,AX
	MOV	ES,AX
	JMP	MAINLP
	

; *  subroutines


;  SUBROUTINES

;☆変数のセグメント・オフセットを得る

farGETVADR:
	call	getvadr
	retf

GETVADR:
	MOV	AL,[BP]		;変数の型
	INC	BP
	SUB	AL,VCODE
	JB	GVA_SYNERR
	JZ	SVGVA
	SHR	AL,1
	JC	GETVADR_ARRAY
	DEC	AL
	JZ	LVGVA
	DEC	AL
	JZ	LLVGVA
GVA_SYNERR:
	JMP	SYNERR


	;短変数
SVGVA:
	xor	ax,ax
	mov	al,[bp]
	inc	bp
	mov	si,[bp]
	add	bp,ax

	mov	ax,cs
	mov	ds,ax
	RET

	;長変数
	;特別変数
LLVGVA:
LVGVA:
LVGVAIN:
	xor	ax,ax
	mov	al,[bp]
	inc	bp
	mov	bx,[bp]
	add	bp,ax

	MOV	DS,cs:[BX]
	XOR	SI,SI
	RET



;☆配列短変数のセグメントとオフセットを得る
;INPUT	DX=配列名,BP=NEXT OF NAME
;OUTPUT	DS:SI=DI
;保存	ES,SS,BP
;注意	INDEX の計算において RECURSIVE CALL されうる


GETVADR_ARRAY:
	JZ	SAVGVA
	DEC	AL
	JZ	LAVGVA
	DEC	AL
	JZ	LLAVGVA
	JMP	SYNERR


farGETSAVADR:
	call	GETSAVADR
	retf

farGETLAVADR:
	call	GETLAVADR
	retf

farGETLLAVADR:
	call	GETLLAVADR
	retf


if FLG32
;---------------------------------------

SAVGVA:
GETSAVADR:
	CALL	GETINDEX
	PUSH	DX
	PUSH	AX
	SET32
	POP	AX
	SET32
	add	ax,ax

	;now EAX=配列要素番号

GETAVADROUT:
	;now EAX=相対オフセット

	MOV	DX,AX
	XOR	AH,AH
	ADD	AX,ARRAYHEAD	;先頭のサイズの分
	MOV	DI,AX
	MOV	SI,AX		;DI=SI=OFFSET

	MOV	BX,DS
	MOV	AX,DX
	SET32
	SHR	AX,4
	AND	AL,11110000B
	ADD	AX,BX
	MOV	DS,AX
	MOV	DX,AX		;FOR COMPATIBILITY FOR 16 BIT
	MOV	AX,SS
	MOV	ES,AX
	RET


;☆配列長変数のセグメントとオフセットを得る
;INPUT	DX=配列名,BP=NEXT OF NAME
;OUTPUT	DS:SI=DI
;保存	ES,SS,BP
;注意	INDEX の計算において RECURSIVE CALL されうる、特にこのルーチン
;	は配列特別変数と共用出来ない


	;配列長変数

LAVGVA:
GETLAVADR:
	CALL	GETINDEX
	PUSH	DX
	PUSH	AX
	SET32
	POP	AX

	;now EAX=配列要素番号

	SET32
	XOR	DX,DX
	MOV	DX,SS:[MAXALL]
	SHL	DX,1		;一要素の BYTE 数
	SET32
	MUL	DX
	JMP	GETAVADROUT


;☆配列特別変数のセグメントとオフセットを得る
;INPUT	DX=配列名,BP=NEXT OF NAME
;OUTPUT	DS:SI=DI
;保存	ES,SS,BP

	;配列特別変数

LLAVGVA:
GETLLAVADR:
	CALL	GETINDEX
	PUSH	DX
	PUSH	AX
	SET32
	POP	AX

	;now EAX=配列要素番号

	SET32
	MOV	DX,UNITBYTE
	DW	0		;FOR 32 BIT
	SET32
	MUL	DX
	JMP	GETAVADROUT
;---------------------------------------
else
;---------------------------------------
	;配列短変数
SAVGVA:
GETSAVADR:
	CALL	GETINDEX
	add	ax,ax
	RCL	DX,1

GETAVADROUT:
	MOV	BX,DS
	MOV	DH,DL
	MOV	DL,AH
	XOR	AH,AH
	MY_SHL	DX,4
	ADD	DX,BX
	MOV	DS,DX
	ADD	AX,ARRAYHEAD	;先頭のサイズの分
	MOV	DI,AX
	MOV	SI,AX
	MOV	AX,SS
	MOV	ES,AX
	RET


;☆配列長変数のセグメントとオフセットを得る
;INPUT	DX=配列名,NEXT OF NAME
;OUTPUT	DS:SI=DI
;保存	ES,SS,BP
;注意	INDEX の計算において RECURSIVE CALL されうる、特にこのルーチン
;	は配列特別変数と共用出来ない


	;配列長変数
LAVGVA:
GETLAVADR:
	CALL	GETINDEX

	MOV	CX,DX
	MOV	BX,SS:[MAXALL]
	SHL	BX,1		;一要素の BYTE 数
	MUL	BX
	MOV	SI,DX
	MOV	DI,AX		;SI:DI
	MOV	AX,CX
	MUL	BX
	ADD	AX,SI
	MOV	DX,AX
	MOV	AX,DI	
	JMP	GETAVADROUT


;☆配列特別変数のセグメントとオフセットを得る
;INPUT	DX=配列名,BP=NEXT OF NAME
;OUTPUT	DS:SI=DI
;保存	ES,SS,BP

	;配列特別変数
LLAVGVA:
GETLLAVADR:
	CALL	GETINDEX

	;now AX=配列要素番号

	MOV	DX,UNITBYTE
	MUL	DX
	JMP	GETAVADROUT
;---------------------------------------
endif

;
;	配列の要素番号を得る
;
;INPUT : BP=text ptr
;OUTPUT: DS=ARRAY TOP SEGMENT
;	 DX:AX=MEMBER NUMBER

GETINDUNDEF:
	JMP	UNDEFERR

GETINDEX:
	xor	ax,ax
	mov	al,[bp]
	inc	bp
	mov	bx,[bp]
	add	bp,ax
	mov	bx,cs:[bx]
	or	bx,bx
	JZ	GETINDUNDEF	;未定義配列
	PUSH	BX		;☆BASE SEGMENT

	MOV	DS,BX
	XOR	SI,SI
	MOV	BX,[SI]		;BX=次元
	MOV	AX,SS
	MOV	DS,AX	

	;配列のサイズを計算

	DEC	BX
	JNZ	GETIND150

	;一次元の場合

GETIND100:
	CALL	KAKKO
	BACKSP_MAC
	MOV	AX,[SI]
	CMP	AX,1
	JA	GETINDERR	;>1 WORD OR MINUS
	JB	GETIND110	;INDEX=0
	MOV	AX,[SI+2]
GETIND110:
	POP	DS		;☆BASE SEGMENT
	XOR	SI,SI
	CMP	AX,[SI+4]
	JA	GETINDERR
	XOR	DX,DX		;DX:AX= 配列要素番号
	RET


GETINDERR:
	JMP	INDEXERR



GETIND150:
	PUSH	BX
	CALL	FORMUL
	POP	BX
	cmp	byte ptr [bp],0c2h	;code of ,
	JNE	GETINDERR
	INC	BP

	DEC	BX
	JNZ	GETIND300

	;二次元の場合

GETIND200:
	CALL	KAKKO
	BACKSP_MAC
	MOV	BX,[SI]
	CMP	BX,1
	JA	GETINDERR2	;INDEX が大き過ぎる
	JB	GETIND210	;INDEX=0
	MOV	BX,[SI+2]
GETIND210:
	BACKSP_MAC
	MOV	AX,[SI]
	CMP	AX,1
	JA	GETINDERR2	;>1 WORD OR MINUS
	JB	GETIND220	;INDEX=0
	MOV	AX,[SI+2]
GETIND220:
	POP	DS		;☆基底 SEGMENT
	XOR	SI,SI
	CMP	AX,[SI+4]
	JA	GETINDERR2
	XOR	DX,DX		;DX:AX= 配列要素番号
	MOV	DI,[SI+6]
	CMP	DI,1
	JE	GETIND230	;1 を掛けるのはばかばかしい
	MUL	DI
GETIND230:
	CMP	BX,[SI+8]
	JA	GETINDERR2
	ADD	AX,BX
	ADC	DX,0
	RET


GETINDERR2:
	JMP	INDEXERR



GETIND300:
	CALL	FORMUL
	cmp	byte ptr [bp],0c2h	;code of ,
	JNE	GETINDERR2
	INC	BP

	CALL	KAKKO
	BACKSP_MAC
	MOV	CX,[SI]
	CMP	CX,1
	JA	GETINDERR3	;INDEX が大き過ぎる
	JB	GETIND310	;INDEX=0
	MOV	CX,[SI+2]
GETIND310:
	BACKSP_MAC
	MOV	BX,[SI]
	CMP	BX,1
	JA	GETINDERR3	;INDEX が大き過ぎる
	JB	GETIND320	;INDEX=0
	MOV	BX,[SI+2]
GETIND320:
	BACKSP_MAC
	MOV	AX,[SI]
	CMP	AX,1
	JA	GETINDERR3	;>1 WORD OR MINUS
	JB	GETIND330	;INDEX=0
	MOV	AX,[SI+2]
GETIND330:
	POP	DS		;☆基底 SEGMENT
	XOR	SI,SI
	CMP	AX,[SI+4]
	JA	GETINDERR3
	XOR	DX,DX		;DX:AX= 配列要素番号
	MOV	DI,[SI+6]
	CMP	DI,1
	JE	GETIND340	;1 を掛けるのはばかばかしい
	MUL	DI
GETIND340:
	PUSH	AX
	PUSH	DX
	XOR	DX,DX
	MOV	AX,BX
	OR	AX,AX
	JZ	GETIND350
	CMP	AX,[SI+8]
	JA	GETINDERR3
	MOV	DI,[SI+10]
	CMP	DI,1
	JE	GETIND350	;1 を掛けるのはばかばかしい
	MUL	DI
GETIND350:
	CMP	CX,[SI+12]
	JA	GETINDERR3
	ADD	AX,CX
	ADC	DX,0
	POP	CX		;CX:BX =PUSH してあった DX:AX
	POP	BX
	ADD	AX,BX
	ADC	DX,CX		
	RET

GETINDERR3:
	JMP	INDEXERR


CODE	ENDS

code2	segment	word public
	assume	cs:code2,ds:data

	public	prchr2,prspc2,letnl2,nl2,msg2,msg_cs2
	public	farBeepsub,farHELP,helpin,gomainlp2
	public	pausein,schoolin

	extrn	ahedsp2:near

	extrn	farWAIT:far,farCHKCTRL_CS:far
	extrn	farKANJI1ST?:far
	extrn	farPASSTOKEN:far
	extrn	farCURSON:far,farCURSOFF:far,farCURSOR:far
  if GRAPH
    if FLGIBMTOS
	extrn	farreturn2text:far
    endif
  endif


;
; * frequently used subroutines
;   near call from the routin in the code2
;

prchr2:
	call	far ptr farPRCHR
	ret

prspc2:
	call	far ptr farPRSPC
	ret

LETNL2:
	call	far ptr farLETNL
	ret

NL2:
	call	far ptr farNL
	ret

msg2:
	call	far ptr farMSG
	ret

msg_cs2:
	smov	ds,cs
	call	far ptr farMSG
	smov	ds,ss
	ret
	
gomainlp2:
	jmp	far ptr mainlp


;
; vlist
;
farVLIST:
	CALL	far ptr fardiscompilegoto
	CALL	far ptr farPARASE
	MOV	[LNEND],CX
	push	dx
	mov	bx,cx
	cmp	cx,0ffffh
	je	vlist5
	inc	cx
	CALL	far ptr farSRCLIN
vlist5:
	mov	[lnend],bx
	pop	cx
	CALL	far ptr farSRCLIN
	MOV	SI,BX

	;make var list

	MOV	BX,SS
	ADD	BX,ASCBINSEG
	MOV	ES,BX
	MOV	BX,ASCBUFTOP
	MOV	BYTE PTR ES:[BX],0FFH	;END MARK
	MOV	[ENDVAR],BX

	CALL	far ptr farSRCVARLP10
	JC	VLIST20
VLIST10:
	CALL	STOREVAR
	CALL	far ptr farSRCVARNEXT
	jc	vlist20
	cmp	si,ss:[lnend]
	Jbe	VLIST10
vlist20:
	;disp var list

	MOV	SI,ASCBUFTOP
DSPVLP:	
	MOV	AL,ES:[SI]
	CMP	AL,0FFH
	Je	VL_READY
	CALL	DISPVAR		;SI=POINTER
	MOV	AL,','
	CALL	prchr2
	call	prspc2
	ADD	SI,NAMELEN+2
	JMP	DSPVLP

VL_READY:
	smov	es,ss
	CALL	NL2
	AND	[OUT_DEV],NOTBIT1	;プリンタ・オフ
	jmp	gomainlp2			;READY


;☆変数のクロスリファレンス・リスト出力

VXERR:
ex1synerr:
	JMP	far ptr SYNERR

farVXREF:	
	MOV	AL,[BP]
	CMP	AL,CR
	JE	VXALL
	CMP	AL,0C0H
	JE	VXALL

	;特定の変数のみの場合

	CMP	AL,VCODE
	JB	VXERR
	CMP	AL,VCODE5
	JA	VXERR
	mov	di,ss
	add	di,ascbinseg
	mov	es,di

	mov	di,ascbuftop
	mov	byte ptr es:[di+namelen+2],0ffh	;end mark

	mov	si,bp
	movsb			;attribute
	xor	cx,cx
	lodsb
	stosb
	mov	cl,al
	mov	bp,si
	add	bp,cx		;new text pointer
	mov	si,[si]		;var table adr
	sub	si,namelen-2
	push	ds
	mov	ax,code		;//
	mov	ds,ax
	rep	movsb
	pop	ds
	jmp	vxallin

	;全ての変数の場合
VXALL:	
	CALL	MAKEVARLIST
vxallin:
	PUSH	BP
	MOV	BP,ASCBUFTOP
VXALP:	
	CALL	far ptr farWAIT
	CALL	far ptr farCHKCTRL_CS	;STOP OR CTRL_S のチェック
	MOV	AH,ES:[bp]
	CMP	AH,0FFH
	JE	VXAOUT
	CALL	VXSUB		;BP=POINTER
	add	bp,NAMELEN+2
	JMPS	VXALP
VXAOUT:
	POP	BP
	smov	es,ss
	CALL	far ptr farLETNL
	AND	[OUT_DEV],NOTBIT1	;プリンタ・オフ
	jmp	gomainlp2		;READY


;変数毎のクロスリファレンス出力
;INPUT:	BP = START ADR OF attr of 変数

VXSUB:	
	mov	si,bp
	mov	al,es:[si]	;attribute
	CALL	DISPVAR
	call	move2tab8

	;テキストから最初の変数を得る

	CALL	far ptr farSRCVAR1ST
	JC	VXSUBRET
VXSUBLP:	
	push	si
	mov	di,bp

	call	rep_cmpsb_var
	jne	vxsub_next
vxsub_find:
	CALL	DISPLINE

vxsub_next:
	pop	si
	add	si,2
	xor	ax,ax
	mov	al,[si-1]
	add	si,ax		;new tex pointer
	CALL	far ptr farSRCVARNEXT	;次の変数を得る
	JNC	VXSUBLP

VXSUBRET:
	jmp	NL2		;call & ret


; compare variable
; all flag changes according to results

rep_cmpsb_var:
	push	ax
	lodsb			;attribute
	cmp	al,es:[di]
	jne	cmpvarnotequ
	inc	di
	xor	cx,cx
	mov	cl,[si]		;length
	cmp	cl,es:[di]
	jne	cmpvarnotequ
	inc	si
	inc	di
rep_cmpvar_lp:
	lodsb
	call	far ptr farkanji1st?
	jc	cmpvarkanji
	call	chg2cap2
	mov	ah,al
	mov	al,es:[di]
	call	chg2cap2
	cmp	ah,al
	jne	cmpvarnotequ
cmpvar50:
	inc	di
	myloop	rep_cmpvar_lp
	cmp	al,al		;set ZF
cmpvarequ:
	pop	ax
	ret


cmpvarkanji:
	cmp	al,es:[di]
	jne	cmpvarnotequ
	inc	di
	dec	cx		;must not be 0
	lodsb
	cmp	al,es:[di]	;check 2nd byte
	je	cmpvar50

cmpvarnotequ:
	pop	ax
	ret


	;
	; print space until xpos@8=0
	;
move2tab8:
	push	cx
	xor	cx,cx
	mov	cl,[xpos]
	and	cl,7
	jz	move2tab8ret
	neg	cx
	add	cx,8
move2tab8lp:
	call	prspc2
	myloop	move2tab8lp
move2tab8ret:
	pop	cx
	ret


STOREVAR:			;変数名をソートして登録
	xor	ax,ax
	mov	al,[si+1]
	add	ax,2
	add	ax,si
	push	ax		;* new text point

storev10:
	mov	di,ascbuftop
storevlp:
	push	si
	push	di
	call	rep_cmpsb_var
	pop	di
	pop	si
	je	storevend
	jb	gostorev
	add	di,namelen+2
	jmp	storevlp

gostorev:	

;NAMELEN+2 BYTES 開ける
;NOW di=開けるべき先頭位置

	push	si
	push	di

	MOV	SI,[ENDVAR]		;SOURCE
	MOV	CX,SI
	SUB	CX,di
	INC	CX
	LEA	DI,[SI+NAMELEN+2]	;DEST
	MOV	[ENDVAR],DI
	push	es
	pop	ds
	STD
	REP	MOVSB
	CLD
	push	ss
	pop	ds

	pop	di
	POP	SI
	xor	cx,cx
	mov	cl,[si+1]
	add	cx,2
	rep	movsb

storevEND:	
	pop	si		;* new text pointer
	RET


;☆変数リストを作る

MAKEVARLIST:

	;WORK AREA の初期化

	MOV	BX,SS
	ADD	BX,ASCBINSEG
	MOV	ES,BX
	MOV	BX,ASCBUFTOP
	MOV	BYTE PTR ES:[BX],0FFH	;END MARK
	MOV	[ENDVAR],BX

	;最初の変数のサーチ

	CALL	far ptr farSRCVAR1ST
	JC	VLISTRET
VLISTLP:
	CALL	STOREVAR
	CALL	far ptr farSRCVARNEXT
	JNC	VLISTLP
VLISTRET:
	RET			;全てサーチしたら戻る


;☆小文字を大文字に変換

CHG2CAP2:	
	CMP	AL,'a'
	JB	CHG2CAP100
	CMP	AL,'z'
	JA	CHG2CAP100
	SUB	AL,20H
CHG2CAP100:
	RET	


;☆ ＸＲＥＦ，ＬＸＲＥＦの処理
;行番号のクロスリファレンス・リスト出力

farXREFIN:
	MOV	[LNEND],CX
	MOV	CX,DX
	CALL	far ptr farSRCLIN
	MOV	SI,BX

	PUSH	BP		;☆

	CALL	NL2
XREFLP:
	CALL	far ptr farWAIT
	CALL	far ptr farCHKCTRL_CS	;CTRL_C OR CTRL_S のチェック
	LODSW
	OR	AX,AX
	JZ	XREFEND
	MOV	BX,[SI]		;行番号
	CMP	BX,[LNEND]
	JA	XREFEND
	PUSH	AX
	PUSH	SI
	CALL	XREFSUBNUM	;BX が 捜す行番号
	POP	SI
	CALL	XREFSUBLAB	;SI が行の先頭で行番号のある位置
	POP	SI
	JMP	XREFLP

XREFEND:
	AND	[OUT_DEV],NOTBIT1	;プリンタ・オフ
	CALL	NL2

	POP	BP		;☆
	jmp	gomainlp2


;行番号毎のクロスリファレンス出力
;INPUT:	BX= 行番号

XREFSUBNUM:
	MOV	[XREFSW],0
	MOV	SI,TXTHED
	CALL	SRCGOTO1ST	;最初の GOTO,GOSUB,RESTORE を得る
	JC	XRFSUBRET
XRFSUBLP:
	CMP	BYTE PTR [SI],NCODE1
	JNE	XRFSUBNEXT
	INC	SI
	LODSW
	CMP	AX,BX
	JNE	XRFSUBNEXT
	TEST	[XREFSW],-1
	JNZ	XRFSUB10
;	MOV	CX,labellen+2
;	SUB	CL,[XPOS]
;XRFSUB2:
	CALL	prspc2
;	myloop	XRFSUB2
	PUSH	BX		;参照されていれば一回目に
	CALL	prspc2		;行番号を表示
	CALL	far ptr farPRBXSP
;	MOV	CX,labellen+10
;	SUB	CL,[XPOS]
;XRFSUB5:
	CALL	prspc2
;	myloop	XRFSUB5
	MOV	AL,':'
	CALL	prchr2
	POP	BX
XRFSUB10:
	CALL	DISPLINE
	MOV	[XREFSW],-1
	JMP	XRFSUBNEXT
XRFSUBNOTEQ:
	CALL	far ptr farPASSTOKEN
XRFSUBNEXT:
	CALL	SRCGOTONEXT	;次の GOTO,GOSUB,RESTORE を得る
	JNC	XRFSUBLP

XRFSUBRET:
	jmp	NL2		;call & ret


;ラベル毎のクロスリファレンス出力

XREFSUBLAB:
	CALL	DISPLABEL
	JC	XRFSUBLNOT	;LABEL がない場合
	MOV	SI,TXTHED
	call	srclabel1st
	JC	XRFSUBLRET
XRFSUBLLP:
	LODSB
	XOR	CX,CX
	MOV	CL,AL		;CX =文字数
	CMP	AL,[BP-1]
	JNE	XRFSUBL100	;文字数が違う
	MOV	DI,BP
	call	far ptr farrep_cmpsb_label
	JNE	XRFSUBL90	;途中で違った
	CALL	DISPLINE
	ADD	SI,2		;行き先の分
	JMPS	XRFSUBLNEXT

XRFSUBLNOTEQ:
	CALL	far ptr farPASSTOKEN
	JMPS	XRFSUBLNEXT

xrfsubl90:
	dec	si
XRFSUBL100:
	ADD	SI,CX
	ADD	SI,2		;行き先の分

XRFSUBLNEXT:
	CALL	srclabelnext
	JNC	XRFSUBLLP

XRFSUBLRET:
	call	NL2
XRFSUBLNOT:
	RET


;☆ GOTO,GOSUB,RESTORE のサーチ
;INPUT	SI=開始番地
;OUTPUT CF=0 iff exist
;	SI= GOTO,GOSUB,RESTORE,THEN,ELSE,fn の次の番地

SRCGOTO1ST:			;最初は先頭から
	MOV	SI,TXTHED
SRCGLP10:
	LODSW
	OR	AX,AX
	JZ	SRCGENDTXT	;次の先頭が 0000H なのは最終行
	LODSW
	MOV	[NOWLIN],AX	;現行番号
	INC	SI		;PASS SPACE#
	mov	al,[si]
	cmp	al,ncode_label
	je	srcg15
	CMP	al,0B3H		;code of fn
	jne	srcglp20
	inc	si
srcg15:
	inc	si		;pass attribute
	xor	ax,ax
	lodsb
	add	si,ax
	add	si,2		;pass jump adr

SRCGOTONEXT:
SRCGLP20:
	LODSB
	CMP	AL,87H		;code of GOTO
	JE	SRCGJP
	CMP	AL,88H		;CODE OF GOSUB
	JE	SRCGJP
	CMP	AL,9DH		;CODE OF RESTORE
	JE	SRCGJP
	CMP	AL,8EH		;THEN
	JE	SRCGJPTHEN
	CMP	AL,8FH		;ELSE
	JE	SRCGJPELSE
	CMP	AL,0B3H		;fn
	JE	SRCGJP
	CMP	AL,CR
	JE	SRCGLP10	;行の終わり
SRCGIN:
	CALL	far ptr farPASSTOKEN
	JMP	SRCGLP20

SRCGJPELSE:
	ADD	SI,2		;pass 2bytes after ELSE
SRCGJPTHEN:
	LODSB
	CMP	AL,CR
	JE	SRCGLP10

	DEC	SI
SRCGJP:
	CMP	AX,AX		;SET ZF
	RET

SRCGENDTXT:
	STC
	RET


;☆ LABEL のサーチ
;INPUT	SI=開始番地
;OUTPUT CF=0 iff exist
;	SI= label attribute address

srclabel1ST:			;最初は先頭から
	MOV	SI,TXTHED
srclabel10:
	LODSW
	OR	AX,AX
	JZ	srclabelENDTXT	;次の先頭が 0000H なのは最終行
	LODSW
	MOV	[NOWLIN],AX	;現行番号
	INC	SI		;PASS SPACE#
	mov	al,[si]
	cmp	al,ncode_label
	je	srclabel15
	CMP	al,0B3H		;code of fn
	jne	srclabel20
	inc	si
srclabel15:
	inc	si		;pass attribute
	xor	ax,ax
	lodsb
	add	si,ax
	add	si,2		;pass jump adr

srclabelNEXT:
srclabel20:
	lodsb
	cmp	al,ncode_label
	je	srclabel100
	CMP	AL,CR
	JE	srclabel10	;行の終わり
	CALL	far ptr farPASSTOKEN
	JMP	srclabel20

srclabel100:
	clc
	RET

srclabelENDTXT:
	STC
	RET

;☆ ラベルの表示

DISPLABEL:
	ADD	SI,3		;PASS LINE#+SPACE#
	LODSB
	cmp	al,0b3h		;code of fn
	jne	displabel5
	lodsb
displabel5:
	CMP	AL,NCODE_LABEL
	JNE	DISPLABELNOT
DISPLABEL10:
	MOV	AL,'*'
	CALL	prchr2
	LODSB
	MOV	BP,SI		;文字列の先頭
	XOR	CX,CX
	MOV	CL,AL
DISPLABELLP:
	LODSB
	CALL	prchr2
	myloop	DISPLABELLP
	call	nl2
;	MOV	CX,labellen+2
;	SUB	CL,[XPOS]
;DISPLABEL15:
	CALL	prspc2
;	myloop	DISPLABEL15
	MOV	AL,'('
	CALL	prchr2
	CALL	far ptr farPRBXSP
	MOV	AL,')'
	CALL	prchr2		;行番号を強制的に表示

;DISPLABEL20:
;	MOV	CL,labellen+10
;	SUB	CL,[XPOS]	;CURSOR 位置を labellen+9 に
;	XOR	CH,CH
;DISPLSPC:
;	CALL	prspc2
;	myloop	DISPLSPC	
	MOV	AL,':'
	CALL	prchr2
	CLC
	RET

DISPLABELNOT:
	STC
	RET


;☆ 行番号の表示

DISPLINE:
	PUSH	BX
	PUSH	CX
	PUSH	DX
	CALL	prspc2
	MOV	BX,[NOWLIN]
	CALL	far ptr farPRBXSP
	CALL	prspc2
	MOV	AL,','
	CALL	prchr2
	POP	DX
	POP	CX
	POP	BX
	RET

;☆変数名を表示
;INPUT	AL= ATTRIBUTE
;	SI = start adr of attr
;	全て保存

DISPVAR:
	PUSH	AX
	PUSH	CX
	PUSH	SI

	PUSH	AX
	inc	si
	xor	cx,cx
	mov	cl,es:[si]
DISPVARLP:
	inc	si
	MOV	AL,ES:[SI]
	OR	AL,AL
	JZ	DISPVARJP
	CALL	prchr2
	myloop	DISPVARLP
DISPVARJP:
	POP	AX
	SUB	AL,VCODE
	JZ	VLV0
	DEC	AL
	JZ	VLV1
	DEC	AL
	JZ	VLV2
	DEC	AL
	JZ	VLV3
	DEC	AL
	JZ	VLV4
	DEC	AL
	JZ	VLV5
	JMP	ex1SYNERR

VLV0:
	MOV	AL,'%'
VLV01:
	CALL	prchr2
	JMPS	VLV2

VLV1:
	MOV	AL,'%'
	CALL	prchr2
VLV3:
VLVARR:
	MOV	AL,'('
	CALL	prchr2
	mov	al,')'
	call	prchr2
vlv2:
	call	prspc2
VLVRET:
	POP	SI
	POP	CX
	POP	AX
	RET

VLV4:
	MOV	AL,'#'
	JMP	VLV01

VLV5:
	MOV	AL,'#'
	CALL	prchr2
	JMP	VLVARR


;
;☆ ＶＣＨＧの処理
;
VCHGSYNERR:
	JMP	ex1SYNERR

VCHGMISMATCH:
	JMP	far ptr TYPEERR

farVCHG:
	call	far ptr farDiscompilegoto
	call	far ptr farDiscompilejp

	XOR	CX,CX
	cmp	byte ptr [bp],NCODE
	JB	VCHG5
	CALL	far ptr farPARASE
	CMP	BYTE PTR [BP],0C2H	;CODE OF ,
	JNE	VCHGSYNERR
	INC	BP
VCHG5:
	CALL	far ptr farSRCLIN	;cx=start line number in text
	push	bx		;bx=start adr in text

	mov	si,bp
	mov	al,[si]
	mov	bl,al		;old var type
	CMP	al,VCODE
	JB	VCHGSYNERR
	CMP	al,VCODE5
	JA	VCHGSYNERR

	mov	di,offset FNAMEBUF
	xor	cx,cx
	mov	cl,[si+1]
	movsw			;OLD var type,len
	movsw			;move varadr
	sub	cx,2
	add	si,cx

	lodsb
	cmp	al,0c2h		;','
	je	vchg7
	cmp	al,8ah		;code of TO
	jne	vchgsynerr
vchg7:
	mov	al,[si]
	mov	bh,al		;new var type
	cmp	al,vcode
	jb	vchgsynerr
	cmp	al,vcode5
	ja	vchgsynerr
	xor	al,bl
	and	al,1
	jnz	vchgmismatch	;配列と普通変数ではダメ

	mov	di,offset FNAMEBUF+namelen+2
	xor	cx,cx
	mov	cl,[si+1]
	movsw			;NEW var attr,len
	rep	movsb		;move varadr,name

	mov	[vchg_sp],WORK3

	xor	dx,dx
	mov	dl,[FNAMEBUF+1]	;old name length

	pop	si		;start adr in text

	CALL	far ptr farSRCVARLP10	;1ST を途中から捜す
	JC	VCHGsynERR
VCHG10:
	push	si

	mov	di,offset FNAMEBUF+2
	winc	si
	cmpsw
	jne	vchg20
	mov	di,[vchg_sp]
	pop	ax
	push	ax
	stosw
	mov	ax,[nowtop]
	stosw
	mov	[vchg_sp],di
vchg20:
	pop	si
	add	si,2
	xor	ax,ax
	mov	al,[si-1]
	add	si,ax		;new text ptr
	CALL	far ptr farSRCVARNEXT
	JNC	VCHG10

	;exec vchg

	mov	di,[vchg_sp]
	mov	word ptr [di],0		;end mark
	mov	ax,di
	sub	ax,WORK3
	or	ax,ax
	jz	vchg_out	;no data
	
	my_shr	ax,2
	mov	[vchg_sp],WORK3
	mov	bx,offset FNAMEBUF+1
	mov	dh,[bx]
	mov	dl,[bx+namelen+2]
	sub	dl,dh
	jb	vchg_old_longer
vchg_new_longer:
	xor	dh,dh
	push	dx
	mul	dx		;ax=augmentation of text
	pop	dx
	add	ax,[txtend]
	jc	vchg_full
	cmp	ax,txtlim
	ja	vchg_full
vnl10:
	mov	si,[vchg_sp]
	lodsw
	mov	[vchg_sp],si
	or	ax,ax
	jz	vchg_done
	mov	si,[txtend]
	mov	di,si
	add	di,dx
	mov	[txtend],di
	MOV	[calcsp_limit],DI
	add	[calcsp_limit],unitbyte
	mov	cx,si
	inc	cx
	sub	cx,ax
	std
	rep	movsb
	cld
	call	vchgjptr
	call	vchgvptr
	mov	si,offset FNAMEBUF+namelen+2
	xor	cx,cx
	mov	cl,[si+1]
	add	cx,2
	mov	di,ax
	rep	movsb
	jmp	vnl10

vchg_done:
	mov	sp,systemstackbtm
	mov	[base_sp],sp
	MOV	[CONTADR],0
	CALL	far ptr farDiscompileall ;飛び先ADRなどを元に戻す
	call	far ptr farTroffsub
	call	far ptr farResvar
	CALL	far ptr farINILOOP
	CALL	far ptr farCLOSEALL	;FILE を全て CLOSE
vchg_out:
	jmp	far ptr ready

vchg_full:
	jmp	far ptr areafull


vchg_old_longer:
	mov	dh,0ffh		;dx=new-old<0
vol10:
	mov	si,[vchg_sp]
	lodsw
	mov	[vchg_sp],si
	or	ax,ax
	jz	vchg_done
	mov	di,ax
	mov	si,di
	sub	si,dx
	mov	cx,[txtend]
	inc	cx
	sub	cx,si
	rep	movsb
	dec	di
	mov	[txtend],di
	MOV	[calcsp_limit],DI
	add	[calcsp_limit],unitbyte
	call	vchgjptr
	call	vchgvptr
	mov	si,offset FNAMEBUF+namelen+2
	xor	cx,cx
	mov	cl,[si+1]
	add	cx,2
	mov	di,ax
	rep	movsb
	jmp	vol10


	;rewrite jump adr's
vchgjptr:
	push	ax
	mov	si,[vchg_sp]
	lodsw
	mov	[vchg_sp],si
	mov	si,ax		;top of current line
vchgjptr10:
	mov	ax,[si]
	or	ax,ax
	jz	vchgjptr20
	add	ax,dx
	mov	[si],ax
	mov	si,ax
	jmp	vchgjptr10
vchgjptr20:
	pop	ax
	ret


	;rewrite var adr's
vchgvptr:
	push	ax
	mov	di,[vchg_sp]
	mov	bx,[di-2]	;top adr of current line
vchgvptr10:
	mov	ax,[di]		;var ptr
	or	ax,ax
	jz	vchgvptr20
	add	ax,dx
	stosw
	mov	ax,[di]		;jmp ptr
	cmp	ax,bx
	je	vchgvptr15
	add	ax,dx
vchgvptr15:
	stosw
	jmp	vchgvptr10
vchgvptr20:
	pop	ax
	ret


;
; * find
;
farFIND:
	;捜す数を得る

	CALL	far ptr farFORMUL

	cmp	byte ptr [bp],0c2h	;code of ,
	JNE	FINDSYNERR
	INC	BP

	;配列の型ごとに分岐

	XOR	BX,BX
	MOV	BL,[BP]
	INC	BP
	MOV	DX,[BP]
	SUB	BL,VCODE1
	JZ	FINDSHORTARRAY
	SUB	BX,2
	JZ	FINDLONGARRAY
	SUB	BX,2
	JZ	FINDEXLONGARRAY
FINDSYNERR:
	JMP	ex1SYNERR

	;IF EXTRALONG ARRAY

FINDEXLONGARRAY:
	MOV	AX,UNITBYTE
	MOV	[SORTUNIT],AX	;一つの要素のBYTE数
	CALL	far ptr farGETLLAVADR	;DS:DI が 開始ADDRESS
	JMP	FINDLONGIN

	;IF LONG ARRAY

FINDLONGARRAY:
	MOV	AX,[MAXALL]
	add	ax,ax
	MOV	[SORTUNIT],AX	;一つの要素のBYTE数
	CALL	far ptr farGETLAVADR	;DS:DI が 開始ADDRESS
	JMP	FINDLONGIN

	;IF SHORT ARRAY

FINDSHORTARRAY:
	;開始番地を得る

	CALL	far ptr farGETSAVADR	;DS:DI が 開始ADDRESS
	MOV	AX,DI		;返って来る値が
	AND	DI,000FH	;少し甘いので修正
	MY_SHR	AX,4
	MOV	BX,DS
	ADD	AX,BX

	MOV	BX,SS
	MOV	DS,BX

	MOV	[S_OFF],DI	;START OFFSET
	MOV	[S_SEG],AX	;      SEGMENT

	cmp	byte ptr [bp],0c2h	;code of ,
	JNE	FINDSYNERR
	INC	BP

	;捜す個数を得る

	CALL	far ptr farKAKKO
	BACKSP_MAC
	MOV	AX,[SI]		;個数の WORD 数
	AND	AX,LENMASK
	CMP	AX,1
	JA	FINDSBIGERR	;多すぎる
	JB	FINDSRET0	;0 個なので何もしなくてよい
	MOV	AX,[SI+2]	;個数
	CMP	AX,8000H
	JAE	FINDSBIGERR	;多すぎる

	;終了番地を得る

	add	ax,ax
	MOV	DI,[S_OFF]
	ADD	DI,AX
	JC	FINDSBIGERR
	SUB	DI,2		;END OFFSET<=0FFFCH
	MOV	[J_OFF],DI

	;捜す数値を得る

	MOV	SI,[CALCSP]
	MOV	BX,[SI]
	MOV	AX,BX
	AND	AX,LENMASK
	CMP	AX,1
	JA	FINDSRET0	;大きすぎるので存在せず
	JB	FINDS50		;IF 0
	AND	BX,8000H
	MOV	AX,[SI+2]
	CMP	AX,8000H
	JAE	FINDSRET0	;大きすぎるので存在せず
	OR	AX,BX		;符号のセット
FINDS50:
	MOV	SI,SS:[S_OFF]	;BASE OFFSET
	MOV	BX,SS:[S_SEG]	;BASE SEGMENT
	MOV	DS,BX
	MOV	ES,BX
	CALL	FINDAX
	MOV	BX,SS
	MOV	DS,BX
	MOV	ES,BX
FINDS100:
	MOV	SI,[CALCSP]
	CMP	AX,8000H
	JAE	FINDS120	;IF -
	MOV	[SI+2],AX
	OR	AX,AX
	JZ	FINDS110
	MOV	AX,1
FINDS110:
	MOV	[SI],AX
	RETf
FINDS120:
	MOV	[SI],8001H
	AND	AH,7FH
	MOV	[SI+2],AX
	RETf


FINDSRET0:
	MOV	AX,-1
	JMP	FINDS100

FINDSBIGERR:
	JMP	far ptr ILGERR


FINDAX:
	MOV	CX,[DI]
	MOV	BX,[SI]
	CMP	CH,80H
	JAE	FINDAX10
	CMP	BH,80H
	JAE	FINDAXUP0	;[SI]<0,[DI]>=0 混合
	TEST	AH,80H		;[SI],[DI]>=0
	JNZ	FINDNO		;負の数はない
	CMP	CX,BX
	JAE	FINDAXUP
	JMP	FINDAXDOWN
FINDNO:
	MOV	AX,-1
	RET

FINDAX10:
	CMP	BH,80H
	JMPC	FINDAXDOWN0	;[DI]<0,[SI]>=0 混合
	TEST	AH,80H		;[SI],[DI]<0
	JZ	FINDNO		;正の数はない
	CMP	CX,BX
	JAE	FINDAXUP
	JMP	FINDAXDOWN

FINDAXUP0:
	;正負混合なので境目を見つける
	;最後の負の数を捜す

	PUSH	AX
	MOV	AX,8000H
	ADD	SI,2		;最初と
	SUB	DI,2		;最後ではない
FINDAU0:
	CMP	SI,DI
	JE	FINDAU020	;FIND
	MOV	BX,SI
	ADD	BX,DI
	SHR	BX,1		;BX=(SI+DI)\2
	AND	BL,0FEH		;RESET BIT 0
	TEST	[BX],AX
	JZ	FINDAU010	;正の場合
	LEA	SI,[BX+2]	;負の場合
	JMP	FINDAU0
FINDAU010:
	LEA	DI,[BX-2]
	CMP	DI,SI
	JAE	FINDAU0
	MOV	BX,DI
	JMPS	FINDAU040
FINDAU020:
	TEST	[SI],AX
	JZ	FINDAU030
	MOV	BX,SI
	JMPS	FINDAU040
FINDAU030:
	LEA	BX,[SI-2]
FINDAU040:
	;now BX=LAST OF NEGATIVES
FINDAU050:
	POP	AX
	TEST	AH,80H
	JZ	FINDAU060	;IF AX>=0
	MOV	SI,SS:[S_OFF]	;IF AX<0
	MOV	DI,BX
	JMP	FINDAXDOWN
FINDAU060:
	LEA	SI,[BX+2]
	MOV	DI,SS:[J_OFF]


FINDAXUP:
	CMP	SI,DI
	JE	FINDAX60	;1 個だけ
	JA	FINDAX70	;無い場合
	MOV	BX,SI
	ADD	BX,DI
	SHR	BX,1		;BX=(SI+DI)\2
	AND	BL,0FEH		;RESET BIT 0
	CMP	AX,[BX]
	JE	FINDAX40	;FIND!ただし最初かどうか分からない
	JB	FINDAXUP10
	LEA	SI,[BX+2]
	JMP	FINDAXUP
FINDAXUP10:
	CMP	SI,BX
	JAE	FINDAX70	;NOT EXIST
	LEA	DI,[BX-2]
	JMP	FINDAXUP


FINDAX40:
	CMP	BX,SI
	JE	FINDAX50
	SUB	BX,2
	CMP	AX,[BX]
	JE	FINDAX40
	ADD	BX,2
FINDAX50:
	MOV	AX,BX
	SUB	AX,SS:[S_OFF]
	SHR	AX,1
	RET

FINDAX60:
	MOV	BX,SI
	CMP	AX,[BX]
	JE	FINDAX50	;この１個だけある
FINDAX70:
	MOV	AX,-1		;無い場合は-1
	RET

FINDAXDOWN:
	CMP	SI,DI
	JE	FINDAX60	;1 個だけ
	JA	FINDAX70	;無い場合
	MOV	BX,SI
	ADD	BX,DI
	SHR	BX,1		;BX=(SI+DI)\2
	AND	BL,0FEH		;RESET BIT 0
	CMP	AX,[BX]
	JE	FINDAX40	;FIND!ただし最初かどうか分からない
	JA	FINDAXDOWN10
	LEA	SI,[BX+2]
	JMP	FINDAXDOWN
FINDAXDOWN10:
	CMP	SI,BX
	JAE	FINDAX70	;NOT EXIST
	LEA	DI,[BX-2]
	JMP	FINDAXDOWN

FINDAXDOWN0:
	;正負混合なので境目を見つける
	;最後の NON_NEGATIVE を捜す

	PUSH	AX
	MOV	AX,8000H
	ADD	SI,2		;最初は正
	SUB	DI,2		;最後は負
FINDAD0:
	CMP	SI,DI
	JE	FINDAD020	;FIND
	MOV	BX,SI
	ADD	BX,DI
	SHR	BX,1		;BX=(SI+DI)\2
	AND	BL,0FEH		;RESET BIT 0
	TEST	[BX],AX
	JNZ	FINDAD010	;負の場合
	LEA	SI,[BX+2]	;正の場合
	JMP	FINDAD0
FINDAD010:
	LEA	DI,[BX-2]
	CMP	DI,SI
	JAE	FINDAD0
	MOV	BX,DI
	JMPS	FINDAD040
FINDAD020:
	TEST	[SI],AX
	JNZ	FINDAD030
	MOV	BX,SI
	JMPS	FINDAD040
FINDAD030:
	LEA	BX,[SI-2]
FINDAD040:
	;now BX=LAST OF NON_NEGATIVES
FINDAD050:
	POP	AX
	TEST	AH,80H
	JNZ	FINDAD060	;IF AX<0
	MOV	SI,SS:[S_OFF]	;IF AX>=0
	MOV	DI,BX
	JMP	FINDAXDOWN
FINDAD060:
	LEA	SI,[BX+2]
	MOV	DI,SS:[J_OFF]
	JMP	FINDAXUP


;長変数のＦＩＮＤ

FINDLONGIN:
	MOV	AX,DI		;返って来る値が
	AND	DI,000FH	;少し甘いので修正
	MY_SHR	AX,4
	MOV	BX,DS
	ADD	AX,BX

	MOV	BX,SS
	MOV	DS,BX

	MOV	[SORTBASEOFF],DI
	MOV	[SORTBASESEG],AX

	cmp	byte ptr [bp],0c2h	;code of ,
	JMPNZ	findSYNERR
	INC	BP

	CALL	far ptr farKAKKO
	BACKSP_MAC
	MOV	AX,[SI]		;個数の WORD 数
	AND	AX,LENMASK
	CMP	AX,1
	JA	FINDLBIGERR	;多すぎる
	JB	FINDLRET0	;0 個なので何もしなくてよい
	MOV	AX,[SI+2]	;個数
	CMP	AX,8000H
	JAE	FINDLBIGERR	;多すぎる
	MOV	[S_PTR],0	;開始番号
	DEC	AX
	MOV	[E_PTR],AX	;終了番号

	;配列の範囲を荒くチェック

	MOV	AX,[E_PTR]
	INC	AX
	MUL	[SORTUNIT]
	ADD	AX,[SORTBASEOFF]
	ADC	DX,0
	REPT	4
	SHR	DX,1	
	RCR	AX,1
	ENDM
	OR	DX,DX
	JNZ	FINDLBIGERR
	ADD	AX,[SORTBASESEG]
	JC	FINDLBIGERR
	CMP	AX,[LIMITSEG]
	JAE	FINDLBIGERR

	CALL	FINDLMAIN

	MOV	BX,SS
	MOV	DS,BX
	MOV	ES,BX
	JMP	FINDS100	;結果を設定して RET

FINDLRET0:
	MOV	AX,-1		;無い場合
	JMP	FINDS100

FINDLBIGERR:
	JMP	far ptr ILGERR


	;FINDL の実行

FINDLMAIN:
	MOV	SS:[DIRECTION],0
	MOV	AX,SS:[S_PTR]
	CALL	SEGOFF
	MOV	SI,AX
	MOV	DS,DX
	MOV	AX,SS:[E_PTR]
	CALL	SEGOFF
	MOV	DI,AX
	MOV	ES,DX
	CALL	SORTCOMPARE
	JBE	FINDL
	MOV	SS:[DIRECTION],-1	;降順の場合
	
FINDL:
	MOV	AX,SS:[S_PTR]
	MOV	BX,SS:[E_PTR]
	CMP	AX,BX
	JE	FINDL60		;1個ならチェックして終り
	ADD	AX,BX
	SHR	AX,1
	MOV	BX,AX		;中間点
	CALL	SEGOFF
	MOV	DI,AX
	MOV	ES,DX
	MOV	AX,SS
	MOV	DS,AX
	MOV	SI,[CALCSP]
	CALL	SORTCOMPARE
	JE	FINDL40		;見つけた、しかし最初とは限らない
	JB	FINDL10
	INC	BX
	MOV	SS:[S_PTR],BX
	JMP	FINDL
FINDL10:
	CMP	BX,SS:[S_PTR]
	JBE	FINDL70		;NOT EXIST
	DEC	BX
	MOV	SS:[E_PTR],BX
	JMP	FINDL

FINDL40:
	CMP	BX,SS:[S_PTR]
	JE	FINDL50
	DEC	BX
	MOV	AX,BX
	CALL	SEGOFF
	MOV	DI,AX
	MOV	ES,DX
	MOV	AX,SS
	MOV	DS,AX
	MOV	SI,[CALCSP]
	CALL	SORTCOMPARE
	JE	FINDL40
	INC	BX
FINDL50:
	MOV	AX,BX
	RET

FINDL60:
	MOV	AX,SS:[S_PTR]
	CALL	SEGOFF
	MOV	DI,AX
	MOV	ES,DX
	MOV	SI,SS
	MOV	DS,SI
	MOV	SI,[CALCSP]
	CALL	SORTCOMPARE
	JE	FINDL80
FINDL70:
	MOV	AX,-1		;無い場合は-1
	RET

FINDL80:
	MOV	AX,SS:[E_PTR]
	RET


SEGOFF:
	MUL	SS:[SORTUNIT]
	ADD	AX,SS:[SORTBASEOFF]
	ADC	DX,0
	MOV	CX,AX
	AND	AX,000FH
	REPT	4
	SHR	DX,1	
	RCR	CX,1
	ENDM
	MOV	DX,CX
	ADD	DX,SS:[SORTBASESEG]
	RET	

SORTCOMPARE:
	TEST	SS:[DIRECTION],-1
	JZ	SCMP10
	XCHG	SI,DI
	MOV	AX,DS		;XCHG DS,ES
	MOV	CX,ES		;
	MOV	ES,AX		;
	MOV	DS,CX		;
SCMP10:
	MOV	AX,[SI]
	MOV	CX,ES:[DI]
	TEST	AH,80H
	JNZ	SCMPSIMINUS	;DS:SI<0
	TEST	CH,80H
	JNZ	SCMPSIBIG	;DS:SI>=0,ES:DI<0
SCMPIN:
	MOV	DH,AH
	XOR	DH,CH
	AND	DH,POINTMASKHIGH
	JNZ	SCMPDIFTYPE	;小数整数混合の場合
	AND	AX,LENMASK
	AND	CX,LENMASK	
	CMP	AX,CX
	JNE	SCMPRET
	JCXZ	SCMPRET		;[SI]=[DI]=0
	add	ax,ax
	ADD	SI,AX		;HIGHEST ADR
	ADD	DI,AX		;HIGHEST ADR
	STD
	REPE	CMPSW
	CLD
SCMPRET:
	RET

SCMPSIBIG:
	MOV	AX,00FFH
	CMP	AL,AH		;> に FLAG をセット
	RET

SCMPDIBIG:
	MOV	AX,00FFH
	CMP	AH,AL		;< に FLAG をセット
	RET

SCMPSIMINUS:
	AND	AX,7FFFH
	TEST	CH,80H
	JZ	SCMPDIBIG	;DS:SI<0,ES:DI>=0
	AND	CX,7FFFH
	XCHG	AX,CX
	XCHG	SI,DI
	PUSH	DS		;XCHG DS,ES
	MOV	DX,ES		;
	MOV	DS,DX		;
	POP	ES		;
	JMP	SCMPIN

SCMPDIFTYPE:
	TEST	AH,POINTMASKHIGH
	JZ	SCMPDT100
	AND	AX,LENMASK
	ADD	CX,SS:[POINTWORD]
	CMP	AX,CX
	JNE	SCMPRET
	SUB	CX,SS:[POINTWORD]
	ADD	SI,AX
	ADD	SI,AX
	ADD	DI,CX
	ADD	DI,CX
	STD
	REPE	CMPSW
	CLD
	JNE	SCMPRET		;整数部が一致しない
	MOV	CX,SS:[POINTWORD]
	STD
SCMPDT10:
	LODSW
	OR	AX,AX
	loopZ	SCMPDT10
	CLD
	JNZ	SCMPSIBIG
	JMP	SCMPRET		;等しい場合
SCMPDT100:
	AND	CX,LENMASK
	ADD	AX,SS:[POINTWORD]
	CMP	AX,CX
	JNE	SCMPRET
	SUB	AX,SS:[POINTWORD]
	ADD	SI,AX
	ADD	SI,AX
	ADD	DI,CX
	ADD	DI,CX
	MOV	CX,AX
	STD
	REPE	CMPSW
	CLD
	JNE	SCMPRET		;整数部が一致しない
	MOV	CX,SS:[POINTWORD]
	STD
	XOR	AX,AX
	REPE	SCASW
	CLD
	JNE	SCMPDIBIG
	JMP	SCMPRET		;等しい場合


;
; * school
;
schoolin:
	mov	al,[bp]
	cmp	al,CR
	je	school10
	cmp	al,0c0h		;":"
	je	school10
	call	far ptr farget_ax
	or	ax,ax
	jz	schooloff
school10:
	mov	[schoolflg],-1

;	display digit is determined in farfloatascin in float.asm
;	mov	[schooldeci],8
;	mov	[pointword],4
;	mov	[pointdeci],16

	jmp	gomainlp2

schooloff:
	mov	[schoolflg],0
	call	initwp
	jmp	gomainlp2

;
; * pause
;
pausein:
	mov	ax,10		;10 units = 1sec
	mov	bl,[bp]
	cmp	bl,CR
	je	pause10
	cmp	bl,0c0h		;code of ':'
	je	pause10
	call	far ptr farget_ax
	or	ax,ax
	jz	pauseret
	cmp	ax,100
	ja	pauseilgerr
pause10:
	mov	bx,100
	mul	bx
	xor	dx,dx
  if FLG98
  	mov	bx,18
  endif
  if FLGIBMTOS
  	mov	bx,55
  endif
  if FLGFMR
	mov	bx,20
  endif
	div	bx
	inc	ax
	mov	cx,ax
pause20:
	call	pausesub
	myloop	pause20
pauseret:
	jmp	gomainlp2
pauseilgerr:
	jmp	far ptr ilgerr

;
; * beep
;
farBEEPIN:
	mov	al,[bp]
	cmp	al,CR
	je	beep10
	cmp	al,0c0h		;code of ':'
	jne	beep100
beep10:
	call	beepsub2
	jmp	gomainlp2

beep100:
	call	far ptr farGet_ax
	or	ax,ax
	jnz	setbeepon
setbeepoff:
	call	beepoff
	jmp	gomainlp2
setbeepon:
	call	beepon
	jmp	gomainlp2


farBEEPSUB:
	call	beepsub2
	retf

 if FLG98
beepsub2:
	call	waitnextvsync	;18msec
	call	beepon
	call	waitnextvsync	;18msec
	call	waitnextvsync	;18msec
	call	waitnextvsync	;18msec
	call	beepoff
	ret

beepon:
	push	ax
	mov	al,6
	out	37h,al
	pop	ax
	ret

beepoff:
	push	ax
	mov	al,7
	out	37h,al
	pop	ax
	ret

pausesub:
waitnextvsync:
	push	ax
waitvsynclp1:
	jmp	$+2
	jmp	$+2
	in	al,0a0h
	test	al,020h
	jnz	waitvsynclp1
waitvsynclp2:
	jmp	$+2
	jmp	$+2
	in	al,0a0h
	test	al,020h
	jz	waitvsynclp2
	pop	ax
	ret
	
  endif

  if FLGIBMTOS
beepsub2:
	push	ds
	push	ax
	push	bx

	mov	ax,0040h
	mov	ds,ax
	mov	bx,006ch
	mov	ax,[bx]
beeplp1:
	cmp	ax,[bx]
	je	beeplp1

	call	beepon		;1/18 sec

	mov	ax,[bx]
beeplp2:
	cmp	ax,[bx]
	je	beeplp2

	call	beepoff

	pop	bx
	pop	ax
	pop	ds
	ret

beepon:
	push	ax
	mov	al,0b6h		;set frequency
	out	43h,al
	mov	ax,1193		;1193280/1000(=1KHz)
	out	42h,al
	mov	al,ah
	out	42h,al
	in	al,97
	or	al,00000011b
	out	97,al
	pop	ax
	ret

beepoff:
	push	ax
	in	al,97
	and	al,11111100b
	out	97,al
	pop	ax
	ret

pausesub:
	push	ds
	push	ax
	push	bx

	mov	ax,0040h
	mov	ds,ax
	mov	bx,006ch
	mov	ax,[bx]
pauselp:
	cmp	ax,[bx]
	je	pauselp

	pop	bx
	pop	ax
	pop	ds
	ret

  endif

  if FLGFMR
beepsub2:
	push	ax
	push	bx
	push	dx
	mov	ah,5
	mov	bx,5		;50 msec
	mov	dx,1200		;1200 Hz
	int	9eh
	pop	dx
	pop	bx
	pop	ax
	ret

beepon:
	push	ax
	xor	ax,ax
	int	9eh
	pop	ax
	ret
beepoff:
	push	ax
	mov	ah,1
	int	9eh
	pop	ax
	ret

	even
pausework	dw	5 dup(?)

pausesub:
	push	ds
	push	ax
	push	di

	mov	ax,cs
	mov	ds,ax
	mov	di,offset pausework

	mov	ah,1
	int	96h
	mov	al,[di+8]
	add	al,2
	cmp	al,100
	jb	pauselp
	sub	al,100
pauselp:
	mov	ah,1
	int	96h
	cmp	al,[di+8]
	jne	pauselp

	pop	di
	pop	ax
	pop	ds
	ret

  endif


;
; * helpin
;

helpmsg		db	'UBHELP'
helpmsgend	db	0

cannothelp:
	jmp	far ptr cantdo
helpsynerr:
	jmp	ex1synerr


;
; entry of the command "help <keyword>"
;

helpin:
	mov	al,[bp]
	cmp	al,0dh
	je	helpmenu
	cmp	al,3ah		;code of ':'
	je	helpmenu
	call	far ptr farFORMUL
	mov	ax,[calcsp]
	mov	si,ax
	add	ax,unitbyte
	mov	[calcsp],ax
	lodsw
	test	ah,stringmaskhigh
	jz	helpsynerr
	add	ax,ax
	sbb	ax,0
	and	ax,2*lenmask+1
	mov	cx,ax		;length
	call	helpmain
	jc	cannothelp
	jmp	gomainlp2	

helpmenu:
	xor	cx,cx
	call	helpmain
	jc	cannothelp
	jmp	gomainlp2


;
; common part of command mode and help-key mode
;

helpmain:
  if GRAPH
    if FLGIBMTOS
	cmp	[graphflg],0
	jne	helpret
    endif
  endif
	mov	bx,[charsall2]
	add	bx,15
	my_shr	bx,4
	add	bx,maxhelpsegsize	;segment size of vram save
					;& command text for a command
	mov	ax,[limitseg]
	mov	dx,[arrayseg]
	sub	ax,dx
	cmp	ax,bx
	jb	helperr		;lack of work area
	mov	es,dx		;dx is a parameter for HELP
	xor	di,di
	mov	ax,cx
	stosw
	rep	movsb

	push	[vramsegnow]
	push	dx
	xor	ax,ax		;check help system exists?
	mov	ds,ax
	mov	bx,helpintvect*4
	lds	si,[bx]
	mov	si,103h
	smov	es,cs
	mov	di,offset helpmsg
	mov	cx,offset helpmsgend-offset helpmsg
	repe	cmpsb
	pop	dx
	pop	cx
	jne	helperr

	;cx = vramsegment (used only by FM-R)
	;dx = work segment

	push	bp
	int	helpintvect
	pop	bp

helpret:
	mov	ax,data
	mov	ds,ax
	mov	es,ax
	clc
	ret
helperr:
	mov	ax,data
	mov	ds,ax
	mov	es,ax
	stc
	ret

;
; entry of HELP key depressed
; 98 and IBM : ss = data
; FM-R       : ss = unknown(in interrupt mode)

farHELP:
	call	far ptr farCURSOFF

	call	ahedsp2

	MOV	AL,[YPOS]
	MOV	AH,[chars1]
	MUL	AH
	add	ax,word ptr [xpos]
	add	ax,ax
	MOV	SI,AX		;現在アドレス

	MOV	ds,[vramsegnow]

	mov	cx,16
	std
help5:
	lodsw
	cmp	al,'#'
	je	help9
	cmp	al,'0'
	jb	help8
	cmp	al,'9'
	jbe	help7
	cmp	al,'A'
	jb	help8
	cmp	al,'Z'
	jbe	help7
	cmp	al,'_'
	je	help9
	cmp	al,'a'
	jb	help8
	cmp	al,'z'
	ja	help8
help7:
	loop	help5
help8:
	add	si,2
help9:
	add	si,2
	cld

	mov	di,es:[calcsp]

	mov	cx,16
help10:
	lodsw
	stosb
	loop	help10

	mov	ax,es
	mov	ds,ax

	mov	si,[calcsp]
	mov	ax,[si]
	mov	cx,2
	cmp	ax,'nf'		;'fn'?
	je	farhelp50
	xor	cx,cx
	cmp	al,'#'		;#pi etc.
	je	farhelp20
	cmp	al,'_'		;_X
	je	farhelp20
	or	al,20h
	cmp	al,'a'
	jb	farhelp50	;no char
	cmp	al,'z'
	ja	farhelp50	;no char
farhelp20:
	push	si		;**
	inc	si
	mov	cx,15
farHELP30:
	lodsb
	cmp	al,'$'
	je	farHELP40
	cmp	al,'#'
	je	farHELP40
	cmp	al,'0'
	jb	farHELP35
	cmp	al,'9'
	jbe	farHELP40
farHELP35:
	dec	si
	or	al,20h
	cmp	al,'a'
	jb	farHELP40
	cmp	al,'z'
	ja	farHELP40
	inc	si
	loop	farHELP30
farHELP40:
	mov	bx,si
	mov	cx,si
	pop	si		;**
	sub	cx,si
	cmp	word ptr [bx],'# '
	jne	farhelp50
	mov	byte ptr [bx],'#'
	inc	cx

farhelp50:
	call	helpmain	;ds:si = the top of string
				;cx = bytes of string
	call	far ptr farCURSON
	call	far ptr farCURSOR
	add	[calcsp],unitbyte
	retf


code2	ends
