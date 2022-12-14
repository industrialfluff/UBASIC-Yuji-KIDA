;excom0.asm

DATA	SEGMENT WORD PUBLIC
	ASSUME	CS:CODE,DS:DATA


	public	varsegnow,varseglim,vramsegnow,vramsegover,arrayseg
	public	longvarsegsize,exlongvarsegsize
	public	LIMITSEG,LVARLIMIT
	PUBLIC	MAXWORD,MAXALL,TXTTOP,ASCTOP,ASCEND,CALCSP
	PUBLIC	POINTWORD,pointbyte,POINTDECI,schooldeci
	PUBLIC	TYPMEM,TYPWRK
	PUBLIC	directflg,INSFLG,insflgdef,AUTOFLG,AUTONUM,autoxpos
	PUBLIC	txtend,calcsp_limit,INPUTLEN
	PUBLIC	UNLPT,LPOSX,SPMEM,stopflg
	PUBLIC	base_sp,stackptr,polymodulus
	public	plusmark,postmark,varmark

	public	errortrap
	public	blocksw,blockoperation

	extrn	txtnow:word,txtnex:word,diflen:word
	EXTRN	XPOS:BYTE,YPOS:BYTE,HANDLE:WORD,LNEND:WORD
	extrn	chars1:byte,topline:byte
	EXTRN	EDITPTR:WORD
	extrn	CONTADR:WORD,contcsp:word
	extrn	compilegoto_sw:byte,labelend:word,COMPILEJP_SW:byte

	EXTRN	COUNT3:WORD,COUNT2:WORD,COUNT1:WORD
	EXTRN	BLKP2UNIT:WORD,BLKP2STEP3OFF:WORD
	EXTRN	BLKP2STEP3SEG:WORD,BLKP2COUNT2:WORD
	EXTRN	BLKP2STEP2OFF:WORD,BLKP2STEP2SEG:WORD
	EXTRN	BLKP2COUNT1:WORD
	EXTRN	COUNT23:WORD,COUNT22:WORD,COUNT21:WORD
	EXTRN	BLKPDIM:WORD,BLKPSEG:WORD,BLKPUNIT:WORD
	EXTRN	BLKPIND3:WORD,BLKPSTEP3:WORD
	EXTRN	BLKPIND30:WORD,BLKPIND31:WORD
	EXTRN	BLKPCOUNT3:WORD,BLKPSTEP3OFF:WORD,BLKPSTEP3SEG:WORD
	EXTRN	BLKPIND2:WORD,BLKPSTEP2:WORD
	EXTRN	BLKPIND20:WORD,BLKPIND21:WORD
	EXTRN	BLKPCOUNT2:WORD,BLKPSTEP2OFF:WORD,BLKPSTEP2SEG:WORD
	EXTRN	BLKPIND1:WORD,BLKPSTEP1:WORD,BLKPIND10:WORD
	EXTRN	BLKPIND11:WORD,BLKPCOUNT1:WORD
	EXTRN	SOURCELEN:WORD,SOURCEADR:WORD

  if FLG98
	extrn	brkmsg:byte
  endif

;current system base stack pointer
; not equal tp INISP in subroutine/user function

base_sp	dw	?

;CPU スタック・ポインタのメモ

SPMEM	DW	?

;メモリの限界を超えた SEGMENT

LIMITSEG	DW	?

;長変数の current segment & limit segment

varsegnow	dw	?
varseglim	dw	?

;配列変数の SEGMENT

arrayseg	dw	?

;長変数の最大ワード数

LVARLIMIT	DW	?

;長変数のワード数

MAXWORD	DW	?	;maximal length

;1WORD のヘッダも付けると

MAXALL	DW	?	;maximal length+1

;長変数のsegment数

longvarsegsize	dw	?

;特別変数のsegment数

exlongvarsegsize	dw	?

;words for floating numbers

POINTWORD	DW	0
pointbyte	DW	0

;display length for floating numbers

POINTDECI	DW	0
schooldeci	dw	0

;テキストの先頭アドレス(APPEND の時に一時的に変更する)

TXTTOP	DW	?

;  ASCBUF pointers

ASCTOP	DW	?
ASCEND	DW	?

;計算用スタックの現在位置のアドレス

CALCSP	DW	0

;計算用スタックの補助で演算子を格納
; TYPMEM で TYPWRK 中の次に使える位置を表す

TYPMEM	DW	?
TYPWRK	DB	110 DUP(?)

;USER STACK AREA の SEGMENT,OFFSET

STACKPTR	DW	?,?

;VRAM SEGMENT MEMO

vramsegnow	dw	?
vramsegover	dw	?	;used only by UBI and UBV

;入力された行が DIRECT なら -1 PROGRAM なら 0

directflg	DB	0

;stop key on/off

stopflg         db      1

;編集のモードが INSERT のときに -1 

INSFLG		DB	0
insflgdef	db	0	;default(def by ub.def file)

;AUTO MODE FLAG & DEFAULT LINE NUMBER

AUTOFLG		DB	0
AUTONUM		DW	0
autoxpos	db	8

;TXTEND=テキストの最後に付ける 2BYTES の 0 の 2 つ目のアドレス

TXTEND		DW	?
calcsp_limit	dw	?

;中間言語に翻訳したものの長さ

INPUTLEN	DW	0

;ファイルに一文字書き込む時のバッファ

FILECHAR	DB	?

;a character for plus mark 
;a character adding after printing a number
; sometimes treated as 1 word
even
plusmark	db	' '
postmark	db	' '

;variable mark for a polynomial

varmark		db	'X'

;modulus for Polynomial
	even
POLYMODULUS	dd	0

;
;プリンタに CR を送っていれば 0

UNLPT	DB	?

;プリンタの水平位置(TAB 用)

LPOSX	DB	?

;block 命令の busy flag

blocksw	db	0

  if FLG98
  else
FKEYPTR	DW	0
  endif

;error trap flag

errortrap	dw	0	;0 no trap
				;otherwise address

blk_array1	dw	?,?	;block address
blk_array2	dw	?,?	;

blockoperation	dw	?

data	ends

CODE	SEGMENT PUBLIC
	ASSUME	CS:CODE,DS:DATA

	public	prchr,prspc,farPrchr,farPrspc
	public	nl,letnl,farNl,farLetnl
	public	msg,msg_cs,farMsg

	public	farFPRNSUB,LPRNSUB
	public	COLDST,RESTXT,CHGOUTINIT30
	public	INILOOP,CHGOUT_INIT
	public	farINILOOP,farCHGOUT_INIT
	public	AHEDSP,BACKSP
	public	BREAK,stopin
	public	INMSG
	public	prbxsp,prntax,prntbx,farprbxsp,farprntbx,farprntebx
	public	?line
	public	get_line,getl_sub,setin,srclin,farsrclin
	public	ctrl_ret,ctrl_ins

	public	BLOCKIN,CLRBLOCK,NEGBLOCK,swapblk,blockout

  if FLGIBMTOS
	public	fartranskey
	public	functionkeytbl
  endif
	public	CLEAR_BELOW,RIGHT_ERASE
	public	LEFT_ERASE
	public	CLEAR_SCREEN,CURS_HOME
	public	CAR_RET,CURS_BACK,CURS_DEL
	public	CURS_RIGHTEND,CURS_TAB
	public	CURS_RIGHT,CURS_LEFT
  ifdef AUTOSCROLL
	public	CURS_RIGHTnoNL
  endif
	public	CURS_LEFTEND,CURS_UP,CURS_DOWN,SCROLLUP
	public	SCROLLDOWN,NEW_LINE
  if JAPANESE
	public	onkanji1st?,onkanji2nd?
  endif
	extrn	mainlp:near
	extrn	formul:near
	extrn	addin:near,subin:near,ratdivin:near
	extrn	mulin:near,divin:near,idivin:near,resin:near
	extrn	prchrsub:near
	extrn	discompilevar:near
	extrn	DISCOMPILEGOTO:near,DISCOMPILEJP:near
	extrn	GET_DATA:near,MAKE1SPACE:near
	extrn	CURSOR:near
	EXTRN	CLR_NEXT:NEAR,NEG_NEXT:NEAR,negallsi:near

	extrn	freein:far,getcom:near,getcomjp:near
	extrn	GOSUBSP:word,FORSP:word,label_table:byte
	extrn	diskerr:near,calcsperr:near,systemerr:near
	extrn	areafull:near,TOOLONGLINE:near,blockbusy:near

	extrn	clremablk:far,negemablk:far
	extrn	swapemablk:far,emablkin:far

  if JAPANESE
	extrn	kanji1st?:near
  endif
  if FLG98
  else
	extrn	brkmsg:byte
	extrn	mainlp_memo:word
  endif

	extrn	ovrerr:near,synerr:near,ilgerr:near
	extrn	BLOCKERR:NEAR,indexerr:near
	extrn	typeerr:near,ilglet:near,undeferr:near
	
  if FLG98
	extrn	CURS_NORM:near,CURS_UNDERL:near
  else
	extrn	CURS_NORM:near,CURS_BLOCK:near
  endif

;☆一文字出力

farPRCHR:	
	call	PRCHR
	retf

	myalign
PRCHR:	
	CMP	SS:[OUT_DEV],1
	JMPZ	PRCHRSUB		;NORMAL PRINT

	TEST	SS:[OUT_DEV],BIT0
	JZ	PRNT10
	CALL	PRCHRSUB
PRNT10:
	TEST	SS:[OUT_DEV],BIT1
	JZ	PRNT20
	CALL	LPRNSUB
PRNT20:
	TEST	SS:[OUT_DEV],BIT2
	JZ	PRNT30
	PUSH	BX
	MOV	BX,SS:[PRNHANDLE]
	CALL	FPRNSUB
	jnc	prnt25
	mov	ss:[prnhandle],0
	xor	ss:[prn_dev],bit2	
	xor	ss:[out_dev],bit2
	jmp	diskerr
prnt25:
	POP	BX
PRNT30:
	TEST	SS:[OUT_DEV],BIT3
	JZ	PRNT40
	PUSH	BX
	MOV	BX,SS:[LPTHANDLE]
	CALL	FPRNSUB
	jnc	prnt35
	mov	ss:[lpthandle],0
	xor	ss:[lpt_dev],bit3	
	xor	ss:[out_dev],bit3
	jmp	diskerr
prnt35:
	POP	BX
PRNT40:
	TEST	SS:[OUT_DEV],BIT4
	JZ	PRNT50
	PUSH	BX
	MOV	BX,SS:[ASCHANDLE]
	CALL	FPRNSUB
	jnc	prnt45
	mov	ss:[aschandle],0
	xor	ss:[out_dev],bit4
	jmp	diskerr
prnt45:
	POP	BX
prnt50:
  if flggprint
	TEST	SS:[OUT_DEV],BIT5
	JZ	PRNT60
	CALL	far ptr farGPRINTCHAR
prnt60:
  endif
	RET


	;ファイルへの一文字出力

farFPRNSUB:
	call	FPRNSUB
	retf

FPRNSUB:
	PUSH	DS
	PUSH	AX
	PUSH	CX
	PUSH	DX
	smov	ds,ss
	MOV	[FILECHAR],AL
	MOV	AH,40H
	MOV	CX,1
	MOV	DX,OFFSET FILECHAR
	INT	21H
	POP	DX
	POP	CX
	POP	AX
	POP	DS
	JC	FPRNERR
	RET

FPRNERR:
	mov	ah,3eh		;close handle
	int	21h	
	stc
	ret


	;プリンタ出力ルーチン

LPRNSUB:	
	call	far ptr farLPRNSUB
	ret


;☆特殊プリント

farPRSPC:	
	call	PRSPC
	retf

PRSPC:	
	PUSH	AX
	MOV	AL,' '
	CALL	PRCHR
	POP	AX
	RET


;☆改行

farNL:
	call	NL
	retf
farLETNL:
	call	LETNL
	retf

NL:
	CMP	SS:[XPOS],0
	JE	NONL
LETNL:				;いつでも改行
	PUSH	AX
	test	ss:[out_dev],bit0
	jnz	letnlCRT
	mov	al,CR
	CALL	PRCHR
	mov	al,LF
	CALL	PRCHR
letnlret:
	POP	AX
NONL:
	RET

letnlCRT:
	mov	al,CR
	call	prchrsub
	mov	al,LF
	call	prchrsub
	xor	ss:[out_dev],bit0
	call	letnl
	or	ss:[out_dev],bit0
	jmp	letnlret


;☆文字列出力

farMSG:
	call	MSG
	retf

	myalign
PMSG:	
MSG:
	PUSH	AX
	PUSH	DX
	PUSH	SI

	MOV	SI,DX
PMSGLP:	
	LODSB
	OR	AL,AL
	JZ	PMSGOUT
	CALL	PRCHR
	JMP	PMSGLP
PMSGOUT:	
	POP	SI
	POP	DX
	POP	AX
	RET	

farMSG_CS:
	call	MSG_CS
	retf

	myalign
MSG_CS:
	PUSH	CS
	POP	DS
	CALL	MSG
	PUSH	SS
	POP	DS
	RET

;☆ＣＯＬＤ ＳＴＡＲＴ ＩＮ


COLDST:
	cld
	cli
	mov	sp,systemstackbtm
	mov	ss:[base_sp],sp
	sti
  if FLG98
	GRAMSELECT 1
  endif

;☆テキスト・エリアの初期化

RESTXT:	
	MOV	BX,TXTHED
	mov	[txttop],bx
	XOR	AX,AX
	MOV	[BX],AX
	mov	[bx+2],ax
	INC	BX
	MOV	[TXTEND],BX
	add	bx,unitbyte
	mov	[calcsp_limit],bx
	mov	[labelend],offset label_table

;各定数・フラグの初期化

	MOV	DI,OFFSET HANDLE
	MOV	CX,MAXFILE+1
	REP	STOSW		;HANDLE の初期化

	MOV	[compilegoto_sw],AL

	MOV	[OUT_DEV],1
	MOV	[UNLPT],AL
	MOV	[LPOSX],AL

	MOV	SI,RESADR
	MOV	[SI],AX

	mov	ax,unitword
	add	ax,7
	my_shr	ax,3
	mov	[exlongvarsegsize],ax

	CALL	far ptr farINITWP
	MOV	BX,LNUMBS
	CMP	WORD PTR [BX],1
	jne	restxt50
	JMP	far ptr FREEIN		;FREE AREA の表示
restxt50:
	cli
	mov	sp,systemstackbtm
	mov	ss:[base_sp],sp
	sti
  if FLG98
	GRAMSELECT 1
  endif
	MOV	BP,CODBUF
	JMP	GETCOMJP


;☆各制御命令用のスタックの初期化

farINILOOP:
	call	INILOOP
	retf

INILOOP	PROC	

	MOV	[DATAFLG],0
	MOV	[CONTADR],0
	mov	[contcsp],limit
	MOV	[CALCSP],LIMIT
	MOV	[TYPMEM],OFFSET TYPWRK
	MOV	CS:[GOSUBSP],OFFSET GOSUBSP-GOSUBUNITBYTE+2
	MOV	CS:[FORSP],OFFSET FORSP-FORUNITBYTE+2
	MOV	[TXTTOP],TXTHED
	MOV	[DATAPTR],TXTHED+4

	MOV	[STACKPTR],0
   if FLG98
	mov	ax,USERSTACKSEG
   else
	MOV	AX,DATA
	ADD	AX,USERSTACKSEG
   endif
	MOV	[STACKPTR+2],AX

	mov	[errortrap],0
	mov	[plusmark],' '
	mov	[postmark],' '
	mov	[varmark],'X'
	RET	

INILOOP	ENDP


;
;PRINT,LPRINT の出力先変更の初期化
;
farCHGOUT_INIT:
	call	CHGOUT_INIT
	retf

CHGOUT_INIT:
	TEST	[PRN_DEV],BIT2
	JZ	CHGOUTINIT10
	MOV	BX,[PRNHANDLE]
	MOV	AH,3EH
	INT	21H
CHGOUTINIT10:
	TEST	[LPT_DEV],BIT3
	JZ	CHGOUTINIT20
	MOV	BX,[LPTHANDLE]
	MOV	AH,3EH
	INT	21H
CHGOUTINIT20:
	TEST	[INP_DEV],BIT4
	JZ	CHGOUTINIT30
	MOV	BX,[INPHANDLE]
	MOV	AH,3EH
	INT	21H
CHGOUTINIT30:
	MOV	[PRN_DEV],BIT0
	MOV	[LPT_DEV],BIT1	
	MOV	[OUT_DEV],BIT0
	MOV	[INP_DEV],BIT0
	RET


; ** SUBROUTINES


;
;計算用スタックを一つ深くする
;    output:SI new calcsp
;    destroy:NOTHING

	myalign
AHEDSP:	
	MOV	SI,[CALCSP]
	SUB	SI,UNITBYTE
	CMP	SI,[calcsp_limit]
	JB	GO_CALCSPERR
	MOV	[CALCSP],SI
	RET

GO_CALCSPERR:
	JMP	CALCSPERR


;
;計算用スタックを一つ浅くする
;  output:SI old calcsp
;         DI new calcsp(演算結果の入る方)
;  DESTROY:NOTHING

	myalign
BACKSP:	
	MOV	SI,[CALCSP]
	MOV	DI,SI
	ADD	DI,UNITBYTE
	CMP	DI,LIMIT
	JA	GO_SYSTEMERR
	MOV	[CALCSP],DI
	RET

GO_SYSTEMERR:
	JMP	SYSTEMERR


;
; stop
;
stopin:
        mov     al,[bp]
        cmp     al,CR
        je      break
        cmp     al,0c0h         ;code of :
        je      break
        cmp     al,97h         ;code of endif
        je      break
        call    formul
        backsp_mac
        lodsw
        or      al,ah
        mov     [stopflg],al
        jmp     mainlp


;☆ＢＲＥＡＫキーが押された時の処理

BREAK:
  if FLG98
	call	restore_mainlp
  endif
	mov	ax,ss
	mov	ds,ax
	mov	es,ax
	sti
	cld

	mov	ah,0ch		;clear key buffer
	mov	al,6
	mov	dl,0ffh
	int	21h

	MOV	DX,OFFSET BRKMSG
	MOV	[CONTADR],BP
	mov	al,[out_dev]
	mov	[contout_dev],al
	mov	ax,[calcsp]
	mov	[contcsp],ax

	MOV	[OUT_DEV],1
	CALL	NL
  if FLG98
	MOV	AX,ERRMSGSEG
	MOV	DS,AX
	SUB	DX,OFFSET BRKMSG
	CALL	MSG
	smov	ds,ss
	or	bp,bp
	jz	break50
	CALL	BEEPSUB
break50:
  else
	CALL	MSG_CS
  endif
	MOV	DX,BP		;現在位置(=BP)からモードを判断
	CMP	BP,TXTHED
	JB	BREAK100

	MOV	DX,OFFSET INMSG
	CALL	MSG_CS
	CALL	?LINE
	MOV	[EDITPTR],DX
	MOV	BX,DX
	CALL	PRNTBX
BREAK100:
	CALL	NL
	JMP	GETCOM

INMSG	DB	' in ',0


;BP の示す番地を含む行の行番号を求める
;   inpUT:BP
;   outPUT:BX=該当行の先頭番地
;          DX=目的の行番号

?LINE:	
	MOV	BX,OFFSET TXTHED
?LINLP:	
	MOV	AX,[BX]
	OR	AX,AX
	JZ	?LINJP			;最終行に来た
	CMP	AX,BP
	JA	?LINJP			;次の行はもう超えている
	MOV	BX,AX
	JMPS	?LINLP
?LINJP:	
	MOV	DX,[BX+2]	
	RET	


;☆ＢＸ を １０進５桁で表示(初めの方の 0 は ' ' で埋める

farPRBXSP:
	call	PRBXSP
	retf

PRBXSP:
	MOV	CH,' '
	JMPS	PRNTBX1

PRBXwith0:
	MOV	CH,'0'
	JMPS	PRNTBX1

PRBX_4digit_with0:
	mov	ch,'0'
	push	ax
	push	bx
	push	cx
	push	dx
	jmps	prntbx_4digit


;☆ＢＸ を １０進で表示(初めの方の 0 は無視する)

farPRNTBX:
	call	PRNTBX
	retf

prntax:
	push	bx
	mov	bx,ax
	call	prntbx
	pop	bx
	ret

PRNTBX1:
	push	ax
	push	bx
	push	cx
	push	dx
	jmps	prntbx10

PRNTBX:	
	push	ax
	push	bx
	push	cx
	push	dx

	MOV	CH,0
PRNTBX10:
	MOV	DX,10000
	CALL	PRDECI
PRNTBX_4digit:	
	MOV	DX,1000
	CALL	PRDECI
	MOV	DX,100
	CALL	PRDECI
	MOV	DX,10
	CALL	PRDECI
	MOV	AL,BL
	ADD	AL,'0'
	call	PRCHR

	pop	dx
	pop	cx
	pop	bx
	pop	ax
	ret


PRDECI:	
	XOR	AL,AL
PRDELP:	
	INC	AL
	SUB	BX,DX
	JNC	PRDELP
	DEC	AL
	ADD	BX,DX
	CMP	CH,'0'
	JE	PRDEJ1
	OR	AL,AL
	JNZ	PRDEJ0			;first nonzero
	OR	CH,CH
	JZ	PRDECI100
	MOV	AL,CH
	JMP	PRCHR			;call & ret
PRDECI100:
	RET

PRDEJ0:	
	MOV	CH,'0'
PRDEJ1:	
	ADD	AL,'0'
	JMP	PRCHR			;call & ret

farPRNTEBX:
	call	PRNTEBX
	retf

PRNTEBX:
	push	ax
	push	bx
	push	cx
	push	dx

	set32
	mov	ax,bx
	set32
	xor	cx,cx
	mov	cx,10000
	set32
	xor	dx,dx
	set32
	div	cx
	push	dx		;lower 4 digit
	set32
	xor	dx,dx
	set32
	div	cx
	push	dx		;middle 4 digit

	or	ax,ax
	jz	prntebx50

	mov	bx,ax
	call	prntbx		;higher
	pop	bx		;middle
	call	prbx_4digit_with0
	pop	bx		;lower
	mov	ch,'0'
	jmp	prntbx_4digit	;call & ret

prntebx50:
	pop	bx		;middle
	or	bx,bx
	jz	prntebx60
	call	prntbx
	pop	bx		;lower
	mov	ch,'0'
	jmp	prntbx_4digit	;call & ret
prntebx60:
	pop	bx		;lower
	mov	ch,0
	jmp	prntbx_4digit	;call & ret

;
;	ＵBASIC のテキスト格納処理
;

;
;☆CODEBUF に入力した一行をテキストに入れる
;

SETIN:	

;行番号で捜して

	call	discompilevar
	CMP	BYTE PTR [compilegoto_sw],0
	je	setin5
	CALL	discompilegoto
setin5:
	CMP	BYTE PTR [compilejp_sw],0
	JE	SETIN10
	call	discompilejp
SETIN10:
	MOV	BX,CODBUF+2
	MOV	CX,[BX]		;line num
	MOV	[AUTONUM],CX	;for auto
	MOV	[EDITPTR],CX
	mov	al,[bx+2]
	add	al,5
	mov	[autoxpos],al
	CALL	SRCLIN
	MOV	[TXTNOW],BX
	MOV	[TXTNEX],DX
	JNC	NONAPPEND

;１．最後尾に追加の場合

	MOV	CX,[INPUTLEN]
	CMP	CX,6		;//5

	;行番号だけなら何もせず

	jz	setinret

	;余裕があるか

	MOV	DI,BX
	ADD	DI,2
	MOV	AX,[TXTEND]
	ADD	AX,CX
	JMPC	AREAFULL
	CMP	AX,TXTLIM
	JMPA	AREAFULL

	;余裕があれば追加

	SUB	CX,2
	MOV	SI,CODBUF+2
	REP	MOVSB

	;END MARK の 0000 を置く

	MOV	BX,[TXTNOW]
	MOV	[BX],DI
	MOV	WORD PTR [DI],0
	INC	DI
	MOV	[TXTEND],DI
	MOV	[calcsp_limit],DI
	add	[calcsp_limit],unitbyte
setinret:
	mov	[labelend],offset label_table
	RET


;２．途中の場合

NONAPPEND:
	PUSHF
	MOV	CX,[INPUTLEN]
	ADD	CX,BX
	MOV	SI,CODBUF		;??
	MOV	[SI],CX
	POPF
	JZ	EQULIN


;2.1 その行が存在しない時＝行の挿入の場合

NEWINS:	
	MOV	AX,[INPUTLEN]
	CMP	AX,6		;//5

	;CR のみならば戻る

	jz	setinret

	;次アドレスを書き換え

	MOV	[DIFLEN],AX	;offset=INPUTLEN
	ADD	AX,[TXTEND]
	JMPC	AREAFULL
	CMP	AX,TXTLIM
	JMPA	AREAFULL
	CALL	ADRINCDEC

	;その分を開ける

	MOV	SI,[TXTEND]
	MOV	CX,SI
	SUB	CX,[TXTNOW]
	INC	CX
	MOV	DI,SI
	ADD	DI,[INPUTLEN]
	MOV	[TXTEND],DI
	mov	[calcsp_limit],di
	add	[calcsp_limit],unitbyte
	STD
	REP	MOVSB

	MOV	CX,[INPUTLEN]
	MOV	SI,CODBUF
	ADD	SI,CX
	DEC	SI
	REP	MOVSB
	CLD
	jmp	setinret


;2.2 その行が存在する場合＝書き換えの場合

EQULIN:	
	MOV	AX,[INPUTLEN]
	CMP	AX,6		;//5
	JNE	CHANGE
	MOV	[INPUTLEN],0
CHANGE:	

	;新旧の長さを比べる

	SUB	DX,BX
	SUB	DX,[INPUTLEN]

	;等しかったら変えるだけ

	JE	TRANS

	;差が OFFSET 

	NEG	DX
	MOV	[DIFLEN],DX
	CMP	DH,80H
	JAE	CHG10
	ADD	DX,[TXTEND]
	JMPC	AREAFULL
	CMP	DX,TXTLIM
	JMPA	AREAFULL
CHG10:
	CALL	ADRINCDEC
	CALL	MOVUPDOWN

	;CODBUF から テキストへ

TRANS:	
	MOV	CX,[INPUTLEN]
	OR	CX,CX
	JZ	TRANSRET
	MOV	SI,CODBUF
	MOV	DI,[TXTNOW]
	MOV	BX,DI
	REP	MOVSB
	MOV	[BX],DI		;NEXT ADDRESS の書き換え
TRANSRET:
	jmp	setinret


;  SUBROUTINES

CLEAR_BELOW:
	call	far ptr farCLEAR_BELOW
	ret
RIGHT_ERASE:
	call	far ptr farRIGHT_ERASE
	ret
LEFT_ERASE:
	call	far ptr farLEFT_ERASE
	ret
NEW_LINE:
	call	far ptr farNEW_LINE
	ret
CLEAR_SCREEN:
	call	far ptr farCLEAR_SCREEN
	ret
CURS_HOME:
	call	far ptr farCURS_HOME
	ret
CAR_RET:
	call	far ptr farCAR_RET
	ret
CURS_BACK:
	mov	al,ss:[ypos]
	sub	al,ss:[topline]
	or	al,ss:[xpos]
	jz	curs_back_ret
  if JAPANESE
	call	far ptr farCURS_LEFT
	call	onkanji2nd?
	pushf
	call	far ptr farCURS_RIGHT
	call	far ptr farCURS_BACK
	popf
	jnc	curs_back_ret
	call	kanjiwait
  endif
	call	far ptr farCURS_BACK
curs_back_ret:
	ret

CURS_DEL:
  if JAPANESE
	call	onkanji1st?
	jnc	cursd_del_once
	call	kanjiwait
	call	replacebyspace
	call	far ptr farCURS_DEL
  endif
cursd_del_once:
	call	far ptr farCURS_DEL
	ret

  if JAPANESE
replacebyspace:
	mov	al,[ypos]
	mov	ah,[chars1]
	mul	ah
	add	ax,word ptr [xpos]
	add	ax,ax
	mov	di,ax
	push	es
	mov	es,[vramsegnow]
	mov	ax,' ';	xor	ax,ax
    if FLG98
	stosw
	stosw
    else
	stosb
	inc	di
	stosb
    endif
	pop	es
	ret
  endif


CURS_RIGHTEND:
	call	far ptr farCURS_RIGHTEND
	ret
CURS_TAB:
	call	far ptr farCURS_TAB
  if JAPANESE
	call	onkanji2nd?
	jc	curs_right
  endif
	ret
CURS_RIGHT:
	call	far ptr farCURS_RIGHT
  if JAPANESE
	call	onkanji2nd?
	jc	curs_right
  endif
	ret
  ifdef AUTOSCROLL
CURS_RIGHTnoNL:
	call	far ptr farCURS_RIGHTnoNL
	ret
  endif
CURS_LEFT:
	call	far ptr farCURS_LEFT
	ret
CURS_LEFTEND:
	call	far ptr farCURS_LEFTEND
	ret
CURS_UP:
	call	far ptr farCURS_UP
	ret
CURS_DOWN:
	call	far ptr farCURS_DOWN
	ret
SCROLLDOWN:
	call	far ptr farSCROLLDOWN
	ret
SCROLLUP:
	call	far ptr farSCROLLUP
	ret

 if JAPANESE
kanjiwait:
	push	cx
  if FLG98
	mov	cx,2		;kanjiwaittime
  else
	mov	cx,1
  endif
kanjiwaitlp:
	push	cx
	mov	cx,8000h
	loop	$
	pop	cx
	myloop	kanjiwaitlp
	pop	cx
	ret
  endif

;
;* is on kanji2nd?  CF=1 means kanji2nd
;
  if JAPANESE
    if FLG98
onkanji2nd?:
	push	ds
	push	ax
	push	cx
	push	si
	mov	ds,ss:[vramsegnow]
	mov	al,ss:[ypos]
	mov	ah,ss:[chars1]
	mul	ah
	add	ax,word ptr ss:[xpos]
	add	ax,ax
  	mov	si,ax
	mov	ax,[si]
	test	ah,80h
	jz	nokanji2nd
    else
onkanji2nd?:
	push	ds
	push	ax
	push	cx
	push	si
	mov	ds,ss:[vramsegnow]
	mov	al,ss:[ypos]
	mov	ah,ss:[chars1]
	mul	ah
	add	ax,ax
	mov	si,ax
	mov	cx,word ptr ss:[xpos]
	jcxz	nokanji2nd	;top of line must not be kanji2nd
kanji2nd10:
	lodsw
	call	kanji1st?
	jc	kanji2nd30
kanji2nd20:
	myloop	kanji2nd10
	jmp	nokanji2nd
kanji2nd30:
	add	si,2
	dec	cx
	jnz	kanji2nd20
    endif
yeskanji2nd:
	stc
kanji2ndret:
	pop	si
	pop	cx
	pop	ax
	pop	ds
	ret
nokanji2nd:
	clc
	jmp	kanji2ndret
  endif

;
;* is on kanji1st?  CF=1 means kanji2nd
;
  if JAPANESE
    if FLG98
onkanji1st?:
	push	ds
	push	ax
	push	cx
	push	si
	mov	ds,ss:[vramsegnow]
	mov	al,ss:[ypos]
	mov	ah,ss:[chars1]
	mul	ah
	add	ax,word ptr ss:[xpos]
	add	ax,ax
  	mov	si,ax
	mov	ax,[si]
	or	ah,ah
	jz	nokanji1st
	test	ah,80h
	jnz	nokanji1st
    else
onkanji1st?:
	push	ds
	push	ax
	push	cx
	push	si
	mov	ds,ss:[vramsegnow]
	mov	al,ss:[ypos]
	mov	ah,ss:[chars1]
	mul	ah
	add	ax,ax
	mov	si,ax
	mov	cx,word ptr ss:[xpos]
	inc	cx
kanji1st10:
	lodsw
	call	kanji1st?
	jc	kanji1st30
kanji1st20:
	myloop	kanji1st10
	jmp	nokanji1st
kanji1st30:
	add	si,2
	dec	cx
	jnz	kanji1st20
    endif

yeskanji1st:
	stc
kanji1stret:
	pop	si
	pop	cx
	pop	ax
	pop	ds
	ret
nokanji1st:
	clc
	jmp	kanji1stret
  endif


;☆指定した行番号を捜す
;   input
;	CX=捜すべき行番号
;   output
;	Z=1 存在する
;	Z=0 存在しない
;	  CY=0 次の行はある(間に挿入する事になる)
;	  CY=1 次の行もない(後ろに追加になる)

;	BX=該当行の先頭アドレス
;	 存在しない時は直ぐ次の行の先頭アドレス
;	DX=次の行の先頭番地(Z=0 なら意味なし)
;	AX=前の行の先頭番地(先頭行なら BX と同じ)

farSRCLIN:
	call	SRCLIN
	retf

SRCLIN	PROC
	
	MOV	BX,[TXTTOP]	;普段は TXTHED でも良い
				;APPEND時に意味あり
	MOV	AX,BX
SRCLLP:	
	MOV	DX,[BX]
	OR	DX,DX
	JZ	NOTFND		;最後まで捜したがなかった
	CMP	CX,[BX+2]
	JBE	FOUND		;過ぎたか、あった(ZF で区別)
	MOV	AX,BX		;現在行をメモ
	MOV	BX,DX
	JMP	SRCLLP		;次の行へ

FOUND:
	CLC
	RET

NOTFND:				;全ての行番号が CX より若い
	OR	AX,AX		;reset Z(AX=0はない)
	STC			;set CY
	RET	

SRCLIN	ENDP


ADRINCDEC:	
	MOV	BX,[TXTNOW]
	MOV	AX,[DIFLEN]
ADRLP:	
	MOV	DX,[BX]
	OR	DX,DX
	JZ	ADRRET
	ADD	[BX],AX
	MOV	BX,DX
	JMP	ADRLP
ADRRET:
	RET


MOVUPDOWN:	
	MOV	SI,[TXTEND]
	MOV	DI,[TXTNEX]
	MOV	DX,[DIFLEN]
	MOV	CX,SI
	SUB	CX,DI
	INC	CX
	CMP	DH,80H
	JAE	MOVDOWN
	MOV	DI,SI
	ADD	DI,DX
	MOV	[TXTEND],DI
	mov	[calcsp_limit],di
	add	[calcsp_limit],unitbyte
	STD
	REP	MOVSB
	CLD
	RET
	
MOVDOWN:
	MOV	SI,DI
	ADD	DI,DX
	REP	MOVSB
	DEC	DI
	MOV	[TXTEND],DI
	MOV	[calcsp_limit],DI
	add	[calcsp_limit],unitbyte
	RET

;☆☆一行入力ルーチン WITH ＰＲＩＮＴ

CTRL_RET:
	RET

CTRL_INS:			;INS DEL の MODE 切り換え
	XOR	BYTE PTR [INSFLG],-1
	JNZ	CHGTOINS
CHGTONOINS:

	JMP	CURS_NORM	;CALL & RET

CHGTOINS:
  if FLG98
	JMP	CURS_UNDERL	;CALL & RET
  else
	JMP	CURS_BLOCK	;CALL & RET
  endif


GET_LINE:
	CALL	GETL_SUB
	JC	NO_GET		;BREAK
	CALL	GET_DATA	
	JC	GETL_TOOLONG	;TOO LONG LINE
	JMP	CURSOR		;CALL & RET
NO_GET:
	MOV	BX,LNUMBS
	MOV	WORD PTR [BX],0
	JMP	CURSOR		;CALL & RET

GETL_TOOLONG:
	JMP	TOOLONGLINE


;
; * GETL_SUB for PC98
;
  if FLG98
GETL_SUB:
	MOV	AH,7		;直接キー入力
	INT	21H
	CMP	AL,LF		;最初の LF は無視(FILE へ REDIRECT
	JNE	GETL_SUB10	;されている場合の対策)
GETL_LP:
	MOV	AH,7		;直接キー入力
	INT	21H
GETL_SUB10:
	CMP	AL,CR
	JE	GETL_RET
	CMP	AL,CTRL_C
	JE	GETL_BREAK
	TEST	BYTE PTR [INSFLG],-1
	CALLNZ	MAKE1SPACE	;INSERT MODE ならば一文字分空ける
	CALL	PRCHRSUB
	JMP	GETL_LP
endif

;
; * GETL_SUB for FMR
;
  if FLGFMR
GETL_SUB:
	call	cursor

	MOV	AH,7		;直接キー入力
	INT	21H
	CMP	AL,LF		;最初の LF は無視(FILE へ REDIRECT
	JNE	GETL_SUB10	;されている場合の対策)
GETL_LP:
	call	cursor
	MOV	AH,7		;直接キー入力
	INT	21H
GETL_SUB10:
;	cmp	al,ESC
;	jne	getl_sub20
;
;	mov	ah,7		;input 1 more key
;	int	21h	
;getl_sub20:
	CMP	AL,CR
	JE	GETL_RET
	CMP	AL,CTRL_C
	JE	GETL_BREAK
	TEST	BYTE PTR [INSFLG],-1
	jz	getl_sub30
	CALL	MAKE1SPACE	;INSERT MODE ならば一文字分空ける
getl_sub30:
	CALL	PRCHRSUB
	JMP	GETL_LP
endif

;
; * GETL_SUB for IBM-PC and J3100
;
  if FLGIBMTOS
getfromfunkey:
	mov	bx,[fkeyptr]
	mov	ax,cs:[bx]
	inc	bx
	mov	[fkeyptr],bx
	or	ah,ah
	jnz	getl_sub10
	mov	[fkeyptr],0
	jmps	getl_sub10

GETL_SUB:
	call	cursor
	cmp	[fkeyptr],0
	jne	getfromfunkey

	MOV	AH,7		;直接キー入力
	INT	21H
	CMP	AL,LF		;最初の LF は無視(FILE へ REDIRECT
	JNE	GETL_SUB10	;されている場合の対策)
GETL_LP:
	call	cursor
	cmp	[fkeyptr],0
	jne	getfromfunkey

	MOV	AH,7		;直接キー入力
	INT	21H
GETL_SUB10:
	or	al,al
	jnz	getl_sub20

	mov	ah,7		;input 1 more key
	int	21h	
	call	transkey
getl_sub20:
	CMP	AL,CR
	JE	GETL_RET
	CMP	AL,CTRL_C
	JE	GETL_BREAK
	TEST	BYTE PTR [INSFLG],-1
	CALLNZ	MAKE1SPACE	;INSERT MODE ならば一文字分空ける
	CALL	PRCHRSUB
	JMP	GETL_LP
  endif

GETL_RET:			;改行は GET_DATA でする
	call	restore_mainlp
	CLC
	RET

GETL_BREAK:
        cmp     [stopflg],0
        je      getl_lp
	call	restore_mainlp
	STC
	RET



  if FLG98
restore_mainlp:
	pushf
	push	ds
	push	es
	cld
	mov	ax,code2
	mov	ds,ax
	mov	si,offset mainlp_memo
	mov	ax,code
	mov	es,ax
	mov	di,offset mainlp
	movsw
	movsw
	movsw
	pop	es
	pop	ds
	popf
	ret

  else
restore_mainlp:
	pushf
	push	ds
	push	es
	cld
	mov	ax,cs
	mov	ds,ax
	mov	es,ax
	mov	si,offset mainlp_memo
	mov	di,offset mainlp
	movsw
	movsw
	movsw
	pop	es
	pop	ds
	popf
	ret
  endif

;
;* special key for IBM-PC & J3100
;
  if FLGIBMTOS
fartranskey:
	call	transkey
	retf
transkey:
	mov	ah,CTRL_E	;cursor up
	cmp	al,48h
	je	transkeyret
	mov	ah,CTRL_X	;cursor down
	cmp	al,50h
	je	transkeyret
	mov	ah,CTRL_S	;cursor left
	cmp	al,4bh
	je	transkeyret
	mov	ah,CTRL_A	;ctrl+cursor left
	cmp	al,73h
	je	transkeyret
	mov	ah,CTRL_F	;ctrl+cursor right
	cmp	al,74h
	je	transkeyret
	mov	ah,CTRL_V	;insert/overwrite
	cmp	al,52h
	je	transkeyret
	mov	ah,CTRL_G	;delete
	cmp	al,53h
	je	transkeyret
	mov	ah,CTRL_Q	;home
	cmp	al,47h
	je	transkeyret
	mov	ah,CTRL_L	;ctrl+home
	cmp	al,77h
	je	transkeyret
	mov	ah,CTRL_R	;pgup
	cmp	al,49h
	je	transkeyret
	mov	ah,CTRL_C	;pgdown
	cmp	al,51h
	je	transkeyret
	mov	ah,CTRL_D	;cursor right
	cmp	al,4dh
	je	transkeyret
	mov	ah,CTRL_F	;End
	cmp	al,4eh
	je	transkeyret
	sub	al,3bh
	cmp	al,10
	jb	functionkey
transkeyret:
	mov	al,ah
	ret
functionkey:
	xor	ah,ah
	my_shl	ax,4
	add	ax,offset functionkeytbl
	mov	bx,ax
	mov	ax,cs:[bx]
	or	ah,ah
	jz	nomorefkey
	inc	bx
	mov	[fkeyptr],bx
	ret
nomorefkey:
	mov	[fkeyptr],0
	ret

functionkeytbl:
	DB	'load "',10 DUP(0)
	DB	'dir "*.ub"',19H,CR,4 DUP(0)
	DB	'auto ',19H,10 DUP(0)
	DB	'list ',19H,10 DUP(0)
	DB	'run',19H,CR,11 DUP(0)

	DB	'save "',10 DUP(0)
	DB	'xref ',11 DUP(0)
	DB	'append "',8 DUP(0)
	DB	'edit',19H,CR,10 DUP(0)
	DB	'cont',19H,CR,10 DUP(0)
  endif

;
;☆ add,sub,mul,div block and const
;   now work2 is no more used
;
addblkconst:
	mov	ax,ss
	mov	ds,ax
	mov	es,ax

	call	formul		;calc right side
				;*** reserve value in stack
	checkcalcsp 2

;	call	backsp
;	mov	di,work2
;	mov	cx,[si]
;	and	cx,lenmask
;	inc	cx
;	rep	movsw		;copy to work2

	pop	ax
	mov	ss:[blk_array1+2],ax
	pop	ax
	mov	ss:[blk_array1],ax

	CMP	cs:[BLKP2UNIT],2
	jne	adblkconTOLONG


	;SHORT += const

adblkcons:
	MOV	AX,[MAXWORD]
	INC	AX
	add	ax,ax
	CMP	AX,cs:[BLKPUNIT]
	JE	adblkcons10
	MOV	AX,UNITBYTE
adblkcons10:
	SHR	AX,1
	DEC	AX
	MOV	BX,AX		;MAX WORD

adblkconsLP:
	lds	si,dword ptr ss:[blk_array1]
	mov	ax,[si]
	mov	cx,ax
	jcxz	adblkcons20
	and	ah,7fh
	and	ch,80h
	mov	cl,1
adblkcons20:
	mov	di,ss
	mov	es,di
	mov	di,ss:[calcsp]
	sub	di,unitbyte
	mov	ss:[calcsp],di

	mov	es:[di],cx		;set 1st parameter
	mov	es:[di+2],ax

	mov	ax,ss
	mov	ds,ax
	sub	di,unitbyte
	mov	[calcsp],di
	lea	si,[di+2*unitbyte]
	copy_si2di		;set 2nd parameter

	;operation main

	call	[blockoperation]

	mov	ax,[calcsp]
	mov	si,ax
	add	ax,unitbyte
	mov	[calcsp],ax
	lodsw
	mov	cx,ax
	and	ax,lenmask
	jz	adblkcons50	;if 0
	cmp	ax,1
	ja	adblkconsovr	;>1 word
	and	ch,80h		;get sign
	mov	ax,[si]	
	cmp	ah,80h
	jae	adblkconsovr	;>32767
	or	ah,ch		;set sign
adblkcons50:
	les	di,dword ptr [blk_array1]
	mov	es:[di],ax
	CALL	NEXTADR_ESDI
	jc	adblkconsJP
	mov	ss:[blk_array1],di
	mov	ss:[blk_array1+2],es
	Jmp	adblkconsLP

adblkconsJP:
	add	ss:[calcsp],unitbyte	;***
	jmp	blockout

adblkconsOVR:
	JMP	OVRERR



	;LONG += const

adblkconTOLONG:
	MOV	AX,[MAXWORD]
	INC	AX
	add	ax,ax
	CMP	AX,cs:[BLKPUNIT]
	JE	adblkconl10
	MOV	AX,UNITBYTE
adblkconl10:
	SHR	AX,1
	DEC	AX
	MOV	BX,AX		;MAX WORD

adblkconlLP:
	lds	si,dword ptr ss:[blk_array1]
	MOV	CX,[SI]
	AND	CX,LENMASK
	INC	CX

	mov	ax,ss
	mov	es,ax
	mov	di,ss:[calcsp]
	sub	di,unitbyte
	mov	ss:[calcsp],di

	REP	MOVSW		;set 1st parameter

	mov	ax,ss
	mov	ds,ax

	mov	di,[calcsp]
	sub	di,unitbyte
	mov	[calcsp],di
	lea	si,[di+2*unitbyte]
	copy_si2di		;set 2nd parameter

	;operation main

	push	bx
	call	[blockoperation]
	pop	bx

	mov	si,[calcsp]
	add	si,unitbyte
	mov	[calcsp],si
	sub	si,unitbyte
	MOV	CX,[SI]
	AND	CX,LENMASK
	CMP	CX,BX
	JA	adblkconlOVR
	INC	CX

	les	di,dword ptr [blk_array1]
	REP	MOVSW
	mov	di,[blk_array1]

	CALL	NEXTADR_ESDI
	jc	adblkconljp
	mov	ss:[blk_array1],di
	mov	ss:[blk_array1+2],es
	Jmp	adblkconlLP

adblkconlJP:
	jmp	adblkconsJP


adblkconlOVR:
	JMP	OVRERR




;
;☆ add,sub,mul,div blocks
;
addblksperr:
	jmp	calcsperr
addblkerr:
	jmp	synerr

blockextended:

	;set operation

	mov	bx,offset addin
	cmp	al,0ddh
	je	setblockoperation
	mov	bx,offset subin
	cmp	al,0deh
	je	setblockoperation
	mov	bx,offset mulin
	cmp	al,0e5h
	je	setblockoperation
	mov	bx,offset divin
	cmp	al,0e6h
	je	setblockoperation
	mov	bx,offset resin
	cmp	al,0e7h
	je	setblockoperation
	mov	bx,offset idivin
	cmp	al,0e8h
	je	setblockoperation
	mov	bx,offset ratdivin
	cmp	al,0e9h
	je	setblockoperation
	jmp	synerr

setblockoperation:
	mov	[blockoperation],bx
	
	;GET SOURCE ADR

	mov	ax,[calcsp]
	sub	ax,2*unitbyte
	cmp	ax,stacktop
	jb	addblksperr

	wINC	BP
	MOV	AL,[BP]
	CMP	AL,0A2H		;BLOCK
	jne	addblkconst	;case of right side constant

	INC	BP
	CALL	BLOCKPARAM
	MOV	AX,CS:[BLKPCOUNT3]
	MOV	CS:[COUNT3],AX
	MOV	AX,CS:[BLKPCOUNT2]
	MOV	CS:[COUNT2],AX
	MOV	AX,CS:[BLKPCOUNT1]
	MOV	CS:[COUNT1],AX

	mov	ss:[blk_array2],bx
	mov	ss:[blk_array2+2],ds

	pop	es
	pop	di
	mov	ss:[blk_array1],di
	mov	ss:[blk_array1+2],es

	mov	ax,ss
	mov	ds,ax
	mov	es,ax

	CMP	cs:[BLKP2UNIT],2
	JNE	addblkTOLONG
addblkTOSHORT:
	CMP	cs:[BLKPUNIT],2
	JE	addblkss
	JMP	addblksl

addblkTOLONG:
	CMP	cs:[BLKPUNIT],2
	JE	addblkls

	;LONG += LONG

addblkll:
	MOV	AX,[MAXWORD]
	INC	AX
	add	ax,ax
	CMP	AX,cs:[BLKP2UNIT]	;//
	JE	addblkLL10
	MOV	AX,UNITBYTE
addblkLL10:
	SHR	AX,1
	DEC	AX
	MOV	BX,AX		;MAX WORD

addblkLLLP:
	lds	si,dword ptr ss:[blk_array1]
	MOV	CX,[SI]
	AND	CX,LENMASK
	INC	CX

	mov	ax,ss
	mov	es,ax
	mov	di,ss:[calcsp]
	sub	di,unitbyte
	mov	ss:[calcsp],di

	REP	MOVSW		;set 1st parameter

	lds	si,dword ptr ss:[blk_array2]
	MOV	CX,[SI]
	AND	CX,LENMASK
	INC	CX

	mov	di,ss:[calcsp]
	sub	di,unitbyte
	mov	ss:[calcsp],di

	REP	MOVSW		;set 2nd parameter

	;operation main

	push	bx
	mov	ax,ss
	mov	ds,ax
	call	[blockoperation]
	pop	bx

	;

	mov	si,[calcsp]
	add	si,unitbyte
	mov	[calcsp],si
	sub	si,unitbyte
	MOV	CX,[SI]
	AND	CX,LENMASK
	CMP	CX,BX
	JA	addblkllOVR
	INC	CX

	les	di,dword ptr [blk_array1]
	REP	MOVSW
	mov	di,[blk_array1]

	lds	si,dword ptr [blk_array2]

	CALL	NEXTADR_DSSI
	JC	addblkLLJP
	CALL	NEXTADR_ESDI
	jc	addblkllerr
	mov	ss:[blk_array1],di
	mov	ss:[blk_array1+2],es
	mov	ss:[blk_array2],si
	mov	ss:[blk_array2+2],ds
	Jmp	addblkLLLP

addblkLLERR:
	JMP	BLOCKERR
addblkLLJP:
	CALL	NEXTADR_ESDI
	JNC	addblkLLERR
	jmp	blockout

addblkllOVR:
	JMP	OVRERR


	;LONG += SHORT

addblkls:
	MOV	AX,[MAXWORD]
	INC	AX
	add	ax,ax
	CMP	AX,cs:[BLKPUNIT]
	JE	addblkls10
	MOV	AX,UNITBYTE
addblkls10:
	SHR	AX,1
	DEC	AX
	MOV	BX,AX		;MAX WORD

addblklsLP:
	lds	si,dword ptr ss:[blk_array1]
	MOV	CX,[SI]
	AND	CX,LENMASK
	INC	CX

	mov	ax,ss
	mov	es,ax
	mov	di,ss:[calcsp]
	sub	di,unitbyte
	mov	ss:[calcsp],di

	REP	MOVSW		;set 1st parameter

	lds	si,dword ptr ss:[blk_array2]
	mov	ax,[si]
	mov	cx,ax
	jcxz	addblkls20
	and	ah,7fh
	and	ch,80h
	mov	cl,1
addblkls20:
	mov	di,ss:[calcsp]
	sub	di,unitbyte
	mov	ss:[calcsp],di

	mov	ss:[di],cx	;set 2nd parameter
	mov	ss:[di+2],ax

	;operation main

	push	bx
	mov	ax,ss
	mov	ds,ax
	call	[blockoperation]
	pop	bx

	;

	mov	si,[calcsp]
	add	si,unitbyte
	mov	[calcsp],si
	sub	si,unitbyte
	MOV	CX,[SI]
	AND	CX,LENMASK
	CMP	CX,BX
	JA	addblklsOVR
	INC	CX

	les	di,dword ptr [blk_array1]
	REP	MOVSW
	mov	di,[blk_array1]

	lds	si,dword ptr [blk_array2]

	CALL	NEXTADR_DSSI
	JC	addblklsJP
	CALL	NEXTADR_ESDI
	jc	addblklserr
	mov	ss:[blk_array1],di
	mov	ss:[blk_array1+2],es
	mov	ss:[blk_array2],si
	mov	ss:[blk_array2+2],ds
	Jmp	addblklsLP

addblklsERR:
	JMP	BLOCKERR
addblklsJP:
	CALL	NEXTADR_ESDI
	JNC	addblklsERR
	jmp	blockout

addblklsOVR:
	JMP	OVRERR


	;SHORT += LONG

addblksl:
	MOV	AX,[MAXWORD]
	INC	AX
	add	ax,ax
	CMP	AX,cs:[BLKPUNIT]
	JE	addblksl10
	MOV	AX,UNITBYTE
addblksl10:
	SHR	AX,1
	DEC	AX
	MOV	BX,AX		;MAX WORD

addblkslLP:
	lds	si,dword ptr ss:[blk_array1]
	mov	ax,[si]
	mov	cx,ax
	jcxz	addblksl20
	and	ah,7fh
	and	ch,80h
	mov	cl,1
addblksl20:
	mov	di,ss
	mov	es,di
	mov	di,ss:[calcsp]
	sub	di,unitbyte
	mov	ss:[calcsp],di

	mov	es:[di],cx		;set 1st parameter
	mov	es:[di+2],ax

	lds	si,dword ptr ss:[blk_array2]
	MOV	CX,[SI]
	AND	CX,LENMASK
	INC	CX

	mov	di,ss:[calcsp]
	sub	di,unitbyte
	mov	ss:[calcsp],di

	REP	MOVSW		;set 2nd parameter

	;operation main

	push	bx
	mov	ax,ss
	mov	ds,ax
	call	[blockoperation]
	pop	bx

	;

	mov	si,[calcsp]
	add	si,unitbyte
	mov	[calcsp],si
	sub	si,unitbyte
	lodsw
	mov	cx,ax
	and	ax,lenmask
	jz	addblksl50	;if 0
	cmp	ax,1
	ja	addblkssovr
	and	ch,80h		;get sign
	mov	ax,[si]	
	cmp	ah,80h
	jae	addblkssovr
	or	ah,ch		;set sign
addblksl50:
	les	di,dword ptr [blk_array1]
	mov	es:[di],ax

	lds	si,dword ptr [blk_array2]

	CALL	NEXTADR_DSSI
	JC	addblkslJP
	CALL	NEXTADR_ESDI
	jc	addblkslerr
	mov	ss:[blk_array1],di
	mov	ss:[blk_array1+2],es
	mov	ss:[blk_array2],si
	mov	ss:[blk_array2+2],ds
	Jmp	addblkslLP

addblkslERR:
	JMP	BLOCKERR
addblkslJP:
	CALL	NEXTADR_ESDI
	JNC	addblkslERR
	jmp	blockout

addblkslOVR:
	JMP	OVRERR


	;SHORT += SHORT

addblkss:
	MOV	AX,[MAXWORD]
	INC	AX
	add	ax,ax
	CMP	AX,cs:[BLKPUNIT]
	JE	addblkss10
	MOV	AX,UNITBYTE
addblkss10:
	SHR	AX,1
	DEC	AX
	MOV	BX,AX		;MAX WORD

addblkssLP:
	lds	si,dword ptr ss:[blk_array1]
	mov	ax,[si]
	mov	cx,ax
	jcxz	addblkss20
	and	ah,7fh
	and	ch,80h
	mov	cl,1
addblkss20:
	mov	di,ss
	mov	es,di
	mov	di,ss:[calcsp]
	sub	di,unitbyte
	mov	ss:[calcsp],di

	mov	es:[di],cx		;set 1st parameter
	mov	es:[di+2],ax

	lds	si,dword ptr ss:[blk_array2]
	mov	ax,[si]
	mov	cx,ax
	jcxz	addblkss30
	and	ah,7fh
	and	ch,80h
	mov	cl,1
addblkss30:
	mov	di,ss:[calcsp]
	sub	di,unitbyte
	mov	ss:[calcsp],di

	mov	ss:[di],cx	;set 2nd parameter
	mov	ss:[di+2],ax

	;operation main

	mov	ax,ss
	mov	ds,ax
	call	[blockoperation]

	;

	mov	si,[calcsp]
	add	si,unitbyte
	mov	[calcsp],si
	sub	si,unitbyte
	lodsw
	mov	cx,ax
	and	ax,lenmask
	jz	addblkss50	;if 0
	cmp	ax,1
	ja	addblkssovr
	and	ch,80h		;get sign
	mov	ax,[si]	
	cmp	ah,80h
	jae	addblkssovr
	or	ah,ch		;set sign
addblkss50:
	les	di,dword ptr [blk_array1]
	mov	es:[di],ax

	lds	si,dword ptr [blk_array2]

	CALL	NEXTADR_DSSI
	JC	addblkssJP
	CALL	NEXTADR_ESDI
	jc	addblksserr
	mov	ss:[blk_array1],di
	mov	ss:[blk_array1+2],es
	mov	ss:[blk_array2],si
	mov	ss:[blk_array2+2],ds
	Jmp	addblkssLP

addblkssERR:
	JMP	BLOCKERR
addblkssJP:
	CALL	NEXTADR_ESDI
	JNC	addblkssERR
	jmp	blockout

addblkssOVR:
	JMP	OVRERR


;
;☆ swap
;
goswapemablk:
	jmp	far ptr swapemablk

SWAPBLK:
	cmp	[blocksw],0
	jmpnz	blockbusy
	mov	[blocksw],1
	INC	BP
	cmp	word ptr [bp],0f580h
	je	goswapemablk
	CALL	BLOCKPARAM
	PUSH	BX
	PUSH	DS

	MOV	AX,CS:[BLKPCOUNT3]
	MOV	CS:[COUNT23],AX
	MOV	AX,CS:[BLKPCOUNT2]
	MOV	CS:[BLKP2COUNT2],AX
	MOV	CS:[COUNT22],AX
	MOV	AX,CS:[BLKPCOUNT1]
	MOV	CS:[BLKP2COUNT1],AX
	MOV	CS:[COUNT21],AX

	MOV	AX,CS:[BLKPSTEP3OFF]
	MOV	CS:[BLKP2STEP3OFF],AX
	MOV	AX,CS:[BLKPSTEP3SEG]
	MOV	CS:[BLKP2STEP3SEG],AX
	MOV	AX,CS:[BLKPSTEP2OFF]
	MOV	CS:[BLKP2STEP2OFF],AX
	MOV	AX,CS:[BLKPSTEP2SEG]
	MOV	CS:[BLKP2STEP2SEG],AX
	MOV	AX,CS:[BLKPUNIT]
	MOV	CS:[BLKP2UNIT],AX

	MOV	AX,SS
	MOV	DS,AX
	cmp	byte ptr [bp],0c2h	;code of ,
	JMPNZ	SYNERR

	INC	BP
	cmp	byte ptr [bp],0A2H	;BLOCK
	JNE	SWAPBLK10	;２つ目の block はなくても可
	INC	BP
SWAPBLK10:

	;GET SOURCE ADR

	CALL	BLOCKPARAM
	MOV	AX,CS:[BLKPCOUNT3]
	MOV	CS:[COUNT3],AX
	MOV	AX,CS:[BLKPCOUNT2]
	MOV	CS:[COUNT2],AX
	MOV	AX,CS:[BLKPCOUNT1]
	MOV	CS:[COUNT1],AX

	MOV	SI,BX
	POP	ES
	POP	DI

	MOV	AX,CS:[BLKPUNIT]
	CMP	CS:[BLKP2UNIT],AX
	JMPNZ	TYPEERR
	CMP	AX,2
	JMPZ	SWAPBLKSHORT

SWAPBLKLONG:
SWABLKLLLP:
	MOV	BX,SI		;MEMO
	MOV	DX,DI		;SI & DI

	MOV	CX,[SI]
	AND	CX,LENMASK
	MOV	AX,ES:[DI]
	AND	AX,LENMASK
	CMP	CX,AX
	JAE	SWAPBLK15
	MOV	CX,AX
SWAPBLK15:
	INC	CX
SWAPBLK20:
	MOV	AX,ES:[DI]
	MOVSW
	MOV	[SI-2],AX
	myloop	SWAPBLK20

	MOV	SI,BX
	MOV	DI,DX
	CALL	NEXTADR_DSSI
	JC	SWABLKLLJP
	CALL	NEXTADR_ESDI
	JNC	SWABLKLLLP
SWAPBLKLLERR:
	JMP	BLOCKERR	;個数が一致せず
SWABLKLLJP:
	CALL	NEXTADR_ESDI
	JNC	SWAPBLKLLERR
	jmp	blockout


SWAPBLKSHORT:
SWABLKSSLP:
	MOV	AX,[SI]
	XCHG	ES:[DI],AX
	MOV	[SI],AX
	CALL	NEXTADR_DSSI
	JC	SWABLKSSJP
	CALL	NEXTADR_ESDI
	JNC	SWABLKSSLP
SWAPBLKSSERR:
	JMP	BLOCKERR	;個数が一致せず
SWABLKSSJP:
	CALL	NEXTADR_ESDI
	JNC	SWAPBLKSSERR
	jmp	blockout

;
;☆ＣＯＰＹ ＢＬＯＣＫ
;

COPYBLOCK:
	;GET SOURCE ADR

	INC	BP
	CALL	BLOCKPARAM
	MOV	AX,CS:[BLKPCOUNT3]
	MOV	CS:[COUNT3],AX
	MOV	AX,CS:[BLKPCOUNT2]
	MOV	CS:[COUNT2],AX
	MOV	AX,CS:[BLKPCOUNT1]
	MOV	CS:[COUNT1],AX

	MOV	SI,BX
	POP	ES
	POP	DI

	CMP	CS:[BLKP2UNIT],2
	JNE	COPBLKTOLONG
COPBLKTOSHORT:
	CMP	CS:[BLKPUNIT],2
	JE	COPBLKSSLP
	JMP	COPBLKLSLP

COPBLKTOLONG:
	CMP	CS:[BLKPUNIT],2
	JE	COPBLKSLLP

	;LONG TO LONG

	MOV	AX,SS:[MAXWORD]
	INC	AX
	add	ax,ax
	CMP	AX,CS:[BLKPUNIT]
	JE	COPBLKLL10
	MOV	AX,UNITBYTE
COPBLKLL10:
	SHR	AX,1
	DEC	AX
	MOV	BX,AX		;MAX WORD
COPBLKLLLP:
	MOV	AX,SI		;MEMO
	MOV	DX,DI		;SI & DI

	MOV	CX,[SI]
	AND	CX,LENMASK
	CMP	CX,BX
	JA	COPBLKOVR
	INC	CX
	REP	MOVSW

	MOV	SI,AX
	MOV	DI,DX
	CALL	NEXTADR_DSSI
	JC	COPBLKLLJP
	CALL	NEXTADR_ESDI
	JNC	COPBLKLLLP
COPBLKLLERR:
	JMP	BLOCKERR
COPBLKLLJP:
	CALL	NEXTADR_ESDI
	JNC	COPBLKLLERR
	jmp	blockout

COPBLKOVR:
	JMP	OVRERR

	;SHORT TO SHORT
COPBLKSSLP:
	MOV	AX,[SI]
	MOV	ES:[DI],AX
	CALL	NEXTADR_DSSI
	JC	COPBLKSSJP
	CALL	NEXTADR_ESDI
	JNC	COPBLKSSLP
COPBLKSSERR:
	JMP	BLOCKERR
COPBLKSSJP:
	CALL	NEXTADR_ESDI
	JNC	COPBLKSSERR
	jmp	blockout


	;SHORT TO LONG
COPBLKSLLP:
	XOR	CX,CX
	MOV	AX,[SI]
	OR	AX,AX
	JZ	COPBLKSL10
	MOV	CH,AH
	AND	AH,7FH
	AND	CH,80H
	MOV	CL,1
COPBLKSL10:		
	MOV	ES:[DI],CX
	MOV	ES:[DI+2],AX
	CALL	NEXTADR_DSSI
	JC	COPBLKSLJP
	CALL	NEXTADR_ESDI
	JNC	COPBLKSLLP
COPBLKSLERR:
	JMP	BLOCKERR
COPBLKSLJP:
	CALL	NEXTADR_ESDI
	JNC	COPBLKSLERR
	jmp	blockout

	;LONG TO SHORT
COPBLKLSLP:
	MOV	AX,[SI]
	MOV	CX,AX
	AND	CH,80H		;SGN
	AND	AX,LENMASK
	JZ	COPBLKLS10	;IF 0
	CMP	AX,1
	JA	COPBLKOVR
	MOV	AX,[SI+2]
	CMP	AH,80H
	JAE	COPBLKOVR
	OR	AH,CH
COPBLKLS10:	
	MOV	ES:[DI],AX
	CALL	NEXTADR_DSSI
	JC	COPBLKLSJP
	CALL	NEXTADR_ESDI
	JNC	COPBLKLSLP
COPBLKLSERR:
	JMP	BLOCKERR
COPBLKLSJP:
	CALL	NEXTADR_ESDI
	JNC	COPBLKLSERR
	jmp	blockout


;
;☆ ＣＬＥＡＲ ＢＬＯＣＫ
;   JUMPED from CLR
;
goclremablk:
	jmp	far ptr clremablk

CLRBLOCK:
	cmp	[blocksw],0
	jmpnz	blockbusy
	mov	[blocksw],1
	INC	BP
	cmp	word ptr [bp],0f580h
	je	goclremablk
	CALL	BLOCKPARAM		;NOW DS:BX = top of start adr
CLRBLOCKIN:
	MOV	AX,CS:[BLKPCOUNT3]
	MOV	CS:[COUNT3],AX
	MOV	AX,CS:[BLKPCOUNT2]
	MOV	CS:[COUNT2],AX
	MOV	AX,CS:[BLKPCOUNT1]
	MOV	CS:[COUNT1],AX
	MOV	SI,BX
CLRBLKLP:
	MOV	WORD PTR [SI],0
	CALL	NEXTADR_DSSI
	JNC	CLRBLKLP

	MOV	AX,SS
	MOV	DS,AX
	mov	[blocksw],0
	JMP	CLR_NEXT

;
;☆ NEGATE BLOCK
;   JUMPED from NEG
;
gonegemablk:
	jmp	far ptr negemablk


NEGBLOCK:
	cmp	[blocksw],0
	jmpnz	blockbusy
	mov	[blocksw],1
	INC	BP
	cmp	word ptr [bp],0f580h
	je	gonegemablk
	CALL	BLOCKPARAM	;NOW DS:BX = top of start adr
	cmp	cs:[blkpunit],2
	jne	negblocklong

	MOV	AX,CS:[BLKPCOUNT3]
	MOV	CS:[COUNT3],AX
	MOV	AX,CS:[BLKPCOUNT2]
	MOV	CS:[COUNT2],AX
	MOV	AX,CS:[BLKPCOUNT1]
	MOV	CS:[COUNT1],AX
	MOV	SI,BX
NEGBLKLP:
	MOV	AX,[SI]
	OR	AX,AX
	JZ	NEGBLKJP
	XOR	AH,signmaskhigh		;change sign
	MOV	[SI],AX
NEGBLKJP:
	CALL	NEXTADR_DSSI
	JNC	NEGBLKLP

	MOV	AX,SS
	MOV	DS,AX
	mov	[blocksw],0
	JMP	NEG_NEXT

negblocklong:
	MOV	AX,CS:[BLKPCOUNT3]
	MOV	CS:[COUNT3],AX
	MOV	AX,CS:[BLKPCOUNT2]
	MOV	CS:[COUNT2],AX
	MOV	AX,CS:[BLKPCOUNT1]
	MOV	CS:[COUNT1],AX
	MOV	SI,BX
NEGBLKLLP:
	push	si
	call	negallsi
	pop	si
NEGBLKLJP:
	CALL	NEXTADR_DSSI
	JNC	NEGBLKLLP

	MOV	AX,SS
	MOV	DS,AX
	mov	[blocksw],0
	JMP	NEG_NEXT


;
;☆ ＢＬＯＣＫ代入文の実行
;
goemablk:
	jmp	far ptr emablkin

BLOCKIN:
	cmp	[blocksw],0
	jmpnz	blockbusy
	mov	[blocksw],1
	cmp	word ptr [bp],0f580h
	je	goemablk
	CALL	BLOCKPARAM

	PUSH	BX
	PUSH	DS

	MOV	AX,CS:[BLKPCOUNT3]
	MOV	CS:[COUNT23],AX
	MOV	AX,CS:[BLKPCOUNT2]
	MOV	CS:[BLKP2COUNT2],AX
	MOV	CS:[COUNT22],AX
	MOV	AX,CS:[BLKPCOUNT1]
	MOV	CS:[BLKP2COUNT1],AX
	MOV	CS:[COUNT21],AX

	MOV	AX,CS:[BLKPSTEP3OFF]
	MOV	CS:[BLKP2STEP3OFF],AX
	MOV	AX,CS:[BLKPSTEP3SEG]
	MOV	CS:[BLKP2STEP3SEG],AX
	MOV	AX,CS:[BLKPSTEP2OFF]
	MOV	CS:[BLKP2STEP2OFF],AX
	MOV	AX,CS:[BLKPSTEP2SEG]
	MOV	CS:[BLKP2STEP2SEG],AX
	MOV	AX,CS:[BLKPUNIT]
	MOV	CS:[BLKP2UNIT],AX

	MOV	AX,SS
	MOV	DS,AX
	MOV	AX,[BP]
	cmp	ah,codeofequal
	jmpz	blockextended
	CMP	AL,codeofequal
	JMPNZ	SYNERR

	INC	BP
	cmp	byte ptr [bp],0A2H	;BLOCK
	JMPZ	COPYBLOCK

	CALL	FORMUL
	BACKSP_MAC
	MOV	CX,[SI]
	OR	CX,CX
	JNZ	BLOCK100
	POP	DS
	POP	BX
	JMP	CLRBLOCKIN

BLOCK1OVR:
	JMP	OVRERR

BLOCK100:
	POP	ES
	POP	DI

	MOV	AX,CS:[BLKP2UNIT]
	CMP	AX,2
	JE	BLOCK1SHORT

	AND	CX,LENMASK
	SHR	AX,1
	DEC	AX
	CMP	AX,CX
	JB	BLOCK1OVR
BLOCK1LONG:
	INC	CX
	MOV	CS:[SOURCELEN],CX
	MOV	CS:[SOURCEADR],SI
BLOCK1LONGLP:
	MOV	BX,DI		;PUSH DI
	MOV	CX,CS:[SOURCELEN]
	MOV	SI,CS:[SOURCEADR]
	REP	MOVSW
	MOV	DI,BX		;POP DI
	CALL	NEXTADR_ESDI
	JNC	BLOCK1LONGLP
blockout:
	MOV	AX,SS
	MOV	DS,AX
	MOV	ES,AX
	mov	[blocksw],0
	JMP	MAINLP


BLOCK1ILG:
	JMP	ILGLET


BLOCK1SHORT:
	TEST	CH,POINTMASKHIGH
	JNZ	BLOCK1ILG
	AND	CX,LENMASK
	CMP	CX,1
	JNE	BLOCK1OVR
	MOV	AX,SS:[SI+2]
	CMP	AX,8000H
	JAE	BLOCK1OVR
	MOV	CX,SS:[SI]
	AND	CH,80H
	OR	AH,CH		;SET SIGN
	MOV	CS:[SOURCELEN],AX
BLOCK1SHORTLP:
	MOV	AX,CS:[SOURCELEN]
	MOV	ES:[DI],AX
	CALL	NEXTADR_ESDI
	JNC	BLOCK1SHORTLP
	jmp	blockout

;
;	GET NEXT DS:SI
;
;	i:BLKPCOUNT1,2,3
;	      COUNT1,2,3
;	o:CF=1 if loop end

NEXTADR_DSSI:
	ADD	SI,CS:[BLKPUNIT]
	CMP	SI,8000H
	JB	NXTADR3JP1
	SUB	SI,8000H
	MOV	AX,DS
	ADD	AX,0800H		;8000H/16
	MOV	DS,AX
NXTADR3JP1:
	DEC	CS:[COUNT1]
	JNZ	NXTADRRET
	
	MOV	AX,CS:[BLKPCOUNT1]
	MOV	CS:[COUNT1],AX
	MOV	AX,DS
	ADD	SI,CS:[BLKPSTEP2OFF]
	JNC	NXTADR3JP21
	ADD	AX,1000H
NXTADR3JP21:
	CMP	SI,8000H
	JB	NXTADR3JP22
	SUB	SI,8000H
	ADD	AX,0800H
NXTADR3JP22:
	ADD	AX,CS:[BLKPSTEP2SEG]
	MOV	DS,AX
	DEC	CS:[COUNT2]
	JNZ	NXTADRRET

	MOV	AX,CS:[BLKPCOUNT2]
	MOV	CS:[COUNT2],AX
	MOV	AX,DS
	ADD	SI,CS:[BLKPSTEP3OFF]
	JNC	NXTADR3JP31
	ADD	AX,1000H
NXTADR3JP31:
	CMP	SI,8000H
	JB	NXTADR3JP32
	SUB	SI,8000H
	ADD	AX,0800H
NXTADR3JP32:
	ADD	AX,CS:[BLKPSTEP3SEG]
	MOV	DS,AX
	DEC	CS:[COUNT3]
	JNZ	NXTADRRET
	STC
	RET

NXTADRRET:
	CLC
	RET

;
;	GET NEXT ES:DI
;
;	i:BLKP2COUNT1,2
;	      COUNT21,22,23
;	o:CF=1 if loop end

NEXTADR_ESDI:
	ADD	DI,CS:[BLKP2UNIT]
	CMP	DI,8000H
	JB	NXTADR_ESDI3JP1
	SUB	DI,8000H
	MOV	AX,ES
	ADD	AX,0800H		;8000H/16
	MOV	ES,AX
NXTADR_ESDI3JP1:
	DEC	CS:[COUNT21]
	JNZ	NXTADR_ESDIRET
	
	MOV	AX,CS:[BLKP2COUNT1]
	MOV	CS:[COUNT21],AX
	MOV	AX,ES
	ADD	DI,CS:[BLKP2STEP2OFF]
	JNC	NXTADR_ESDI3JP21
	ADD	AX,1000H
NXTADR_ESDI3JP21:
	CMP	DI,8000H
	JB	NXTADR_ESDI3JP22
	SUB	DI,8000H
	ADD	AX,0800H
NXTADR_ESDI3JP22:
	ADD	AX,CS:[BLKP2STEP2SEG]
	MOV	ES,AX
	DEC	CS:[COUNT22]
	JNZ	NXTADR_ESDIRET

	MOV	AX,CS:[BLKP2COUNT2]
	MOV	CS:[COUNT22],AX
	MOV	AX,ES
	ADD	DI,CS:[BLKP2STEP3OFF]
	JNC	NXTADR_ESDI3JP31
	ADD	AX,1000H
NXTADR_ESDI3JP31:
	CMP	DI,8000H
	JB	NXTADR_ESDI3JP32
	SUB	DI,8000H
	ADD	AX,0800H
NXTADR_ESDI3JP32:
	ADD	AX,CS:[BLKP2STEP3SEG]
	MOV	ES,AX
	DEC	CS:[COUNT23]
	JNZ	NXTADR_ESDIRET
	STC
	RET

NXTADR_ESDIRET:
	CLC
	RET


;
;	DX:AX = 32BITS	-> DX = SEGMENT
;			   AX = OFFSET<２５６ NOT < １６
;	DESTROY:NOTHING

TRANSADR:
	MOV	DH,DL
	MOV	DL,AH
	XOR	AH,AH
	MY_SHL	DX,4
	RET


BLKPUNDEF:
	JMP	UNDEFERR

BLOCKPARAM:
	MOV	AL,[BP]		;変数型
	CMP	AL,VCODE1
	JE	BLKPSHORT
	CMP	AL,VCODE3
	JE	BLKPLONG
	CMP	AL,VCODE5
	JE	BLKPEXTRA
	JMP	SYNERR

BLKPEXTRA:
	MOV	AX,UNITBYTE
	JMPS	BLKP0

BLKPLONG:
	MOV	AX,[MAXALL]
	add	ax,ax
	JMPS	BLKP0

BLKPSHORT:
	MOV	AX,2

BLKP0:
	MOV	CS:[BLKPUNIT],AX	;一つの要素のBYTE数
	INC	BP

	xor	ax,ax
	mov	al,[bp]
	inc	bp
	mov	bx,[bp]
	add	bp,ax
	mov	ax,cs:[bx]
	or	ax,ax
	JZ	BLKPUNDEF	;未定義配列

	MOV	BX,ax
	MOV	CS:[BLKPSEG],BX	;BASE SEGMENT

	;get array information

	MOV	DS,BX

	XOR	AX,AX
	MOV	CS:[BLKPSTEP3],AX
	MOV	CS:[BLKPSTEP2],AX
	MOV	CS:[BLKPIND3],AX
	MOV	CS:[BLKPIND2],AX
	MOV	CS:[BLKPIND1],AX

	XOR	SI,SI
	LODSW
	MOV	CS:[BLKPDIM],AX
	WINC	SI
	DEC	AX
	JZ	BLKP10
	DEC	AX
	JZ	BLKP20
BLKP30:
	LODSW
	MOV	CS:[BLKPIND3],AX
	LODSW
	MOV	CS:[BLKPSTEP3],AX
BLKP20:
	LODSW
	MOV	CS:[BLKPIND2],AX
	LODSW
	MOV	CS:[BLKPSTEP2],AX
BLKP10:
	LODSW
	MOV	CS:[BLKPIND1],AX
	MOV	AX,SS
	MOV	DS,AX	

	MOV	AX,CS:[BLKPDIM]
	DEC	AX
	JZ	BLKP100
	DEC	AX
	JZ	BLKP200

	;３次元目
BLKP300:
	CMP	BYTE PTR [BP],0e5h	;'*'
	je	blkp350
	CALL	GET2BYTES
	JC	BLKPINDERR
	MOV	CS:[BLKPIND30],AX
	CMP	BYTE PTR [BP],0C3H	;'..'
	JNE	BLKP390
	INC	BP
	CALL	GET2BYTES
	jnc	BLKP390
	Jmp	BLKPINDERR
blkp350:
	inc	bp
	xor	ax,ax
	mov	cs:[blkpind30],ax
	MOV	ax,CS:[BLKPIND3]
blkp390:
	MOV	CS:[BLKPIND31],AX
	CMP	BYTE PTR [BP],0C2H	;','		
	jne	BLKPINDERR
	INC	BP		;pass ,

	;２次元目
BLKP200:
	CMP	BYTE PTR [BP],0e5h	;'*'
	je	blkp250
	CALL	GET2BYTES
	JC	BLKPINDERR
	MOV	CS:[BLKPIND20],AX
	CMP	BYTE PTR [BP],0C3H	;'..'
	JNE	BLKP290
	INC	BP
	CALL	GET2BYTES
	jnc	blkp290
	Jmp	BLKPINDERR
blkp250:
	inc	bp
	xor	ax,ax
	mov	cs:[blkpind20],ax
	MOV	ax,CS:[BLKPIND2]
BLKP290:
	MOV	CS:[BLKPIND21],AX
	CMP	BYTE PTR [BP],0C2H	;','		
	JNE	BLKPINDERR
	INC	BP		;pass ,
	JMPS	BLKP100

BLKPSYNERR:
	JMP	SYNERR
BLKPINDERR:
	JMP	INDEXERR

	;１次元目
BLKP100:
	CMP	BYTE PTR [BP],0e5h	;'*'
	je	blkp150
	CALL	GET2BYTES
	JC	BLKPINDERR
	MOV	CS:[BLKPIND10],AX
	CMP	BYTE PTR [BP],0C3H	;'..'
	JNE	BLKP190
	INC	BP
	CALL	GET2BYTES
	jnc	blkp190
	jmp	BLKPINDERR
blkp150:
	inc	bp
	xor	ax,ax
	mov	cs:[blkpind10],ax
	MOV	ax,CS:[BLKPIND1]
BLKP190:
	MOV	CS:[BLKPIND11],AX
	CMP	BYTE PTR [BP],0C2H	;','		
	JE	BLKPSYNERR
	CMP	BYTE PTR [BP],')'
	JNE	BLKPINDERR
	INC	BP		;pass )

BLKP1000:
	XOR	AX,AX
	MOV	CS:[BLKPSTEP3OFF],AX
	MOV	CS:[BLKPSTEP3SEG],AX
	MOV	CS:[BLKPSTEP2OFF],AX
	MOV	CS:[BLKPSTEP2SEG],AX
	INC	AX
	MOV	CS:[BLKPCOUNT3],AX
	MOV	CS:[BLKPCOUNT2],AX

	MOV	AX,CS:[BLKPDIM]
	DEC	AX
	JZ	BLKP1100
	DEC	AX
	JZ	BLKP1200
	JMP	BLKP1300

BLKPINDERR2:
	JMP	INDEXERR

	;３次元

BLKP1300:
	;set step seg:off
	;step3=(dim2-ind21+ind20)*step2*unit

	MOV	AX,CS:[BLKPIND2]
	SUB	AX,CS:[BLKPIND21]
	ADD	AX,CS:[BLKPIND20]
	MUL	CS:[BLKPSTEP2]
	MUL	CS:[BLKPUNIT]
	CALL	TRANSADR
	MOV	CS:[BLKPSTEP3OFF],AX
	MOV	CS:[BLKPSTEP3SEG],DX

	;set loop counter

	MOV	AX,CS:[BLKPIND31]
	CMP	AX,CS:[BLKPIND3]
	JA	BLKPINDERR2
	SUB	AX,CS:[BLKPIND30]
	JB	BLKPINDERR2
	INC	AX
	MOV	CS:[BLKPCOUNT3],AX

BLKP1200:
	;step2=(dim1-ind11+ind10)*unit

	MOV	AX,CS:[BLKPIND1]
	SUB	AX,CS:[BLKPIND11]
	ADD	AX,CS:[BLKPIND10]
	MUL	CS:[BLKPUNIT]
	CALL	TRANSADR
	MOV	CS:[BLKPSTEP2OFF],AX
	MOV	CS:[BLKPSTEP2SEG],DX

	;set loop counter

	MOV	AX,CS:[BLKPIND21]
	CMP	AX,CS:[BLKPIND2]
	JA	BLKPINDERR2
	SUB	AX,CS:[BLKPIND20]
	JB	BLKPINDERR2
	INC	AX
	MOV	CS:[BLKPCOUNT2],AX

BLKP1100:
	;set loop counter

	MOV	AX,CS:[BLKPIND11]
	CMP	AX,CS:[BLKPIND1]
	JA	BLKPINDERR2
	SUB	AX,CS:[BLKPIND10]
	JB	BLKPINDERR2
	INC	AX
	MOV	CS:[BLKPCOUNT1],AX

	;init adr = (ind30*step3+ind20*step2+ind10)*unit

	MOV	AX,CS:[BLKPIND30]
	MUL	CS:[BLKPSTEP3]
	MOV	BX,AX
	MOV	CX,DX
	MOV	AX,CS:[BLKPIND20]
	MUL	CS:[BLKPSTEP2]
	ADD	AX,BX
	ADC	DX,CX
	ADD	AX,CS:[BLKPIND10]
	ADC	DX,0
BLKP3010:
	PUSH	DX
	MUL	CS:[BLKPUNIT]
	MOV	BX,AX
	MOV	CX,DX
	POP	AX
	MUL	CS:[BLKPUNIT]
	ADD	AX,CX
	MOV	DX,AX
	MOV	AX,BX
BLKP3020:
	CALL	TRANSADR
	ADD	AX,20H		;top offset of array
	MOV	BX,AX
	MOV	AX,DX
	ADD	AX,CS:[BLKPSEG]
	MOV	DS,AX
	RET			;DS:BX = TOP ADR


comment %
	;INDEX が省略されれば全部

BLOCKALL:
	INC	BP		;pass )
	MOV	AX,CS:[BLKPDIM]
	DEC	AX
	JZ	BLKPA100
	DEC	AX
	JZ	BLKPA200

	;３次元目
BLKPA300:
	XOR	AX,AX
	MOV	CS:[BLKPIND30],AX
	MOV	AX,CS:[BLKPIND3]
	MOV	CS:[BLKPIND31],AX
	;２次元目
BLKPA200:
	XOR	AX,AX
	MOV	CS:[BLKPIND20],AX
	MOV	AX,CS:[BLKPIND2]
	MOV	CS:[BLKPIND21],AX
	;１次元目
BLKPA100:
	XOR	AX,AX
	MOV	CS:[BLKPIND10],AX
	MOV	AX,CS:[BLKPIND1]
	MOV	CS:[BLKPIND11],AX
	JMP	BLKP1000
%


GET2BYTES:
	CALL	FORMUL
	BACKSP_MAC
	MOV	AX,[SI]
	CMP	AX,1
	JA	GET2BYTESBIG	;>2 BYTES OR MINUS OR POINT
	JB	GET2BYTESRET	;INDEX=0
	MOV	AX,[SI+2]
GET2BYTESRET:
	CLC
	RET
GET2BYTESBIG:
	STC
	RET


	PUBLIC	TRANSADR

code	ends


code2	segment	word public
	assume	cs:code2,ds:data

  if flggprint
	extrn	farGPRINTCHAR:far
  endif
  if FLG98
	extrn	mainlp_memo:word
  endif
	extrn	farCLEAR_BELOW:far,farRIGHT_ERASE:far
	extrn	farLEFT_ERASE:far
	extrn	farCLEAR_SCREEN:far,farCURS_HOME:far
	extrn	farCAR_RET:far,farCURS_BACK:far,farCURS_DEL:far
	extrn	farCURS_RIGHTEND:far,farCURS_TAB:far
	extrn	farCURS_RIGHT:far,farCURS_LEFT:far
  ifdef AUTOSCROLL
	extrn	farCURS_RIGHTnoNL:far
  endif
	extrn	farCURS_LEFTEND:far,farCURS_UP:far,farCURS_DOWN:far
	extrn	farSCROLLUP:far
	extrn	farSCROLLDOWN:far,farNEW_LINE:far

  if FLG98
	public	lprint_al
  endif


farLPRNSUB:
	push	ax
	push	cx
	push	dx

	MOV	SS:[UNLPT],-1
	CMP	AL,TAB
	JE	LPRNSUBTAB

	CMP	AL,CR
	JE	LPRNCR
	CMP	AL,LF
	JE	LPRNLF
	INC	SS:[LPOSX]
LPRNSUB10:
  if FLG98
	call	lpr_char
  else
	MOV	AH,5
	MOV	DL,AL
	INT	21H
  endif
lprnsubret:
	pop	dx
	pop	cx
	pop	ax
	retf

LPRNCR:
	MOV	SS:[LPOSX],0
LPRNLF:
	MOV	SS:[UNLPT],0
	JMP	LPRNSUB10

LPRNSUBTAB:
	MOV	AL,SS:[LPOSX]
	MOV	CL,AL
	XOR	CH,CH
	ADD	CL,8
	AND	CL,0F8H	
	MOV	SS:[LPOSX],CL
	SUB	CL,AL
PTABLP:
  if FLG98
	mov	al,' '
	call	lpr_char
  else
	MOV	AH,5
	MOV	DL,' '
	INT	21H
  endif
	myloop	PTABLP
	jmp	lprnsubret


  if flg98

;
;	プリンタ１バイト出力
;	DESTROY	AX

lprkanjiinmsg		db	1ch,"B",esc,4bh,0
lprkanjiinmsgEPS	db	1ch,"&"
			db	1ch,"S",6,6,0
			;4dots+kanji+4dots

lprkanjioutmsg		db	1ch,"B",esc,48h,0
lprkanjioutmsgEPS	db	1ch,"."
;			db	esc,"M",esc," ",1,0
			;Elite+1dot


kanjisw	db	0
knj1st	db	0
knj2nd	db	0

LPR_CHAR:
	TEST	CS:KNJ1ST,-1
	JNZ	DO_KANJI		;漢字の２バイト目

	CMP	AL,' '
	JB	DO_PRINT
	CALL	SJIS?
	JNC	DO_PRINT		;１バイトコード
	mov	CS:KNJ1ST,al		;漢字の１バイト目のメモ
LPRTRET:
	ret

DO_PRINT:				;１バイトコードの処理
	push	ax
	test	CS:KANJISW,-1
	jz	doprint10

	push	si
	mov	si,offset lprkanjioutmsg
	cmp	ss:[printertype],NECPR
	je	doprint5
	mov	si,offset lprkanjioutmsgEPS
doprint5:
	call	lprmsgcs
	pop	si
	mov	CS:KANJISW,0
doprint10:
	pop	ax
	CMP	AL,' '
	JB	DOPRINTCTRL
	call	lprint_al
	JMP	LPRTRET

DOPRINTCTRL:			;コントロールコードの処理
	call	lprint_al	;今の所何もせず
	JMP	LPRTRET


DO_KANJI:				;漢字の処理
	mov	CS:KNJ2ND,al
	test	CS:KANJISW,-1
	jnz	dokanji10
	push	si
	mov	si,offset lprkanjiinmsg
	cmp	ss:[printertype],NECPR
	je	dokanji5
	mov	si,offset lprkanjiinmsgEPS
dokanji5:
	call	lprmsgcs		;printer = kanji mode
	pop	si
	mov	CS:KANJISW,-1
dokanji10:
	mov	ah,CS:KNJ1ST
	mov	al,CS:KNJ2ND
	call	SJIS_JIS
	push	ax
	mov	al,ah
	call	lprint_al
	pop	ax
	call	lprint_al
	mov	CS:KNJ1ST,0
	jmp	LPRTRET


lprint_al:
lprint_lp:
	mov	ah,11h
	int	1ah
	and	ah,3
	cmp	ah,1
	jne	lprint_lp
	ret

lprmsgcs:
lprmsglp:
	mov	al,cs:[si]
	inc	si
	or	al,al
	jz	lprmsgret
	call	lprint_al
	jmp	lprmsglp
lprmsgret:
	ret

SJIS?:
	cmp	al,81h		;漢字,GRAPHICで異なる
	jb	notsjis
	cmp	al,9fh
	jbe	yessjis
	cmp	al,0e0h
	jb	notsjis
yessjis:
	stc
	ret
notsjis:
	clc
	ret

;	Convert JIS <- Shift-JIS

SJIS_JIS:
	SUB	AH,71H
	CMP	AH,6FH
	JB	SJIS1
	SUB	AH,40H
SJIS1:
	CMP	AL,80H
	JB	SJIS2
	DEC	AL
SJIS2:
	SHL	AH,1
	INC	AH
	CMP	AL,9EH
	JB	SJIS3
	INC	AH
	SUB	AL,5EH
SJIS3:
	SUB	AL,1FH
	RET

  endif

code2	ends
