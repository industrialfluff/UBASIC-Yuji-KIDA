;excom2.asm


DATA	SEGMENT	PUBLIC

	PUBLIC	PRN_DEV,LPT_DEV,INP_DEV,OUT_DEV,contout_dev
	PUBLIC	PRNHANDLE,LPTHANDLE,INPHANDLE,aschandle,INPFILEPTR
	PUBLIC	DEBUG1,DEBUG2,DEBUG3
	public	tcolor,whitenow,printertype
	public	usingsw,using_frac_part,using_int_part

  if FLGIBMTOS
  	public	tcolor4fill
  endif
	EXTRN	XPOS:BYTE,YPOS:BYTE
	extrn	chars1:byte,linesdef:byte
	extrn	maxlinesnow:byte
	extrn	handle:word,ptword:word
	extrn	topline:byte,topadr:word
	extrn	btmline:byte,charsallnow:word,btmadr:word
	EXTRN	HANDLE1:WORD,HANDLE2:WORD,HANDLE3:WORD,FILENO:WORD
	EXTRN	FNAMEBUF:BYTE,dummyname:byte,EDITPTR:WORD
	extrn	CONTADR:WORD,contcsp:word
	extrn	labelend:word
	extrn	DATE:byte,HOUR:byte,MINUTE:byte,SECOND:byte
	extrn	MSECOND:word,TICKCOUNTS:dword
  if DISPFKEY
	extrn	functionkey_sw:byte
  endif
  if FLG98
  else
	extrn	CHKTIMER:byte
  endif

  if GRAPH
    if FLGIBMTOS
	extrn	graphflg:byte
    endif
  endif

	extrn	fixedflag:byte

	public	inputsw,copysw
	public	x_loc,y_loc

INP_BP	DW	?
INPPTR	DW	?		;INPUT 時に入力したデータのポインタ
INPFILEPTR	DW	?,?	;INPUT from FILE 時のポインタ
inputsw	db	0,0		;input numeric or string
copysw	db	1,0

printertype	db	NECPR,?

arrayword	DW	?
DIMENSION	DW	?

CRLFSW		DB	0
USINGSW		DB	0

	even
DEBUGSTOP	DB	?
DEBUG1		DB	?
DEBUG2		DW	?
DEBUG3		DW	?

debugptr	dw	?

USING_INT_PART	dw	0
USING_FRAC_PART	dw	0

X_LOC		DW	0
Y_LOC		DW	0

PRNHANDLE	DW	?
LPTHANDLE	DW	?
INPHANDLE	DW	?
aschandle	dw	?
OUT_DEV	DB	1
contOUT_DEV	DB	1
PRN_DEV	DB	1	;PRINT 出力先
LPT_DEV	DB	2	;LPRINT 出力先
INP_DEV	DB	1	;INPUT 入力元

  if FLG98
tcolor		dw	white		;text color
  endif
  if FLGFMR
		db	0		;dummy
tcolor		dw	white*100h	;text color
		db	0		;dummy
  endif
  if FLGIBMTOS
tcolor		dw	white*100h	;text color
tcolor4fill	dw	white*100h	;used in graphic mode
  endif

whitenow	db	white

DATA	ENDS



CODE	SEGMENT WORD PUBLIC
	ASSUME	CS:CODE,DS:DATA


;PUBLIC LABELS

	public	optioncmd
	PUBLIC	LPRINT,PRINT,PRINT2
	PUBLIC	PRTHL
	PUBLIC	INPUT,INPLET,strinput,DIM,DIMSUB
	public	width,console,calc_console
	PUBLIC	GETPAR,ERASEIN,PARASE,farPARASE
	PUBLIC	CLRTIME,TRON,TROFF,TROFFSUB,farTroffsub,DEBUGLP

	PUBLIC	POPSHORTSUB,POPLONGSUB,POPXLONGSUB
	PUBLIC	PUSHSHORTSUB,PUSHLONGSUB

	PUBLIC	WORDIN
	public	revive,new,pointin,colorin
	public	evalin,evalout

	PUBLIC	LET0,LET1,LET2,LET3,LET4,LET5,LETEXT
	PUBLIC	LET0SUB,LET2SUB,let_extended,farlet_extended

	public	cls,farPrint_calcsp,print_calcsp_out

;EXTERNAL LABELS

	extrn	get_ax:near,farGET_AX:far,get_xy:near
	extrn	farLlocatesub:far
	extrn	calc:near,idivin:near
	EXTRN	SUBIN:NEAR,DIVIN:NEAR,MULIN:NEAR
	EXTRN	PRCHRSUBIN:NEAR,CTRL_KEY:NEAR
	EXTRN	NUMSET:NEAR,PARNUM:NEAR
	EXTRN	CURSON:NEAR,CURSOFF:NEAR,CURS_NORM:NEAR
  if DISPFKEY
	extrn	farDISP_functionkey:far,farCLEAR_functionkey:far
  endif
	EXTRN	FORMUL:NEAR,farFORMUL:far
	extrn	KAKKO:NEAR,farKakko:far
	extrn	kakko_ax:near
	extrn	farKakko_ax:far,farKakko_ax_signed:far
	EXTRN	BINASC:NEAR,CHG2CAP:NEAR
	EXTRN	MAINLP:NEAR,READY:NEAR,MAININ:NEAR
	EXTRN	GET_DATA:NEAR
	EXTRN	HEXCX:NEAR
	EXTRN	ENCDIN:NEAR,DECODE:NEAR
	EXTRN	CHKCTRL_C:NEAR,CHKCTRL_S:NEAR
	EXTRN	PRCHRSUB:NEAR,MAKE1SPACE:NEAR
	EXTRN	CURSOR:NEAR,GETCOMIN:NEAR
	extrn	compilevar:near,compilevardirect:near
	extrn	discompileall:near
	extrn	discompilevar:near,discompilegoto:NEAR
	extrn	cos_ent:near,sin_ent:near
	extrn	returnadr:near

	extrn	label_table:byte,jmptbl2:word
	extrn	midparamin:near,midparam2:near
	extrn	encodein:near

	EXTRN	EXTSUB1st:NEAR,EXTSUB2nd:NEAR,GETLABELLINE:NEAR
	EXTRN	PASSTOKEN:NEAR

	EXTRN	GOSUBSP:WORD,vartbl:word
	extrn	letmid:near,letmember:near,letterm:near
	extrn	letmembernew:near

	EXTRN	LPTFNAMEBUF:BYTE,PRNFNAMEBUF:BYTE,INPFNAMEBUF:BYTE
	
	EXTRN	SYNERR:NEAR,OVRERR:NEAR,fullerr:NEAR,TOOLONGLINE:NEAR
	EXTRN	DBLDEF:NEAR,INDEXERR:NEAR,UNDEFERR:NEAR
	EXTRN	ILGLET:NEAR,ILGERR:NEAR,NOTOPEN:NEAR,NODATAERR:NEAR
	EXTRN	DISKERR:NEAR,PROTECTED:NEAR,OPENERR:NEAR
	EXTRN	LONGNAME:NEAR,TYPEERR:NEAR
	EXTRN	STACKFULL:NEAR,STACKEMPTY:NEAR,cantdo:near
	extrn	systemerr:near

	extrn	letema:near,inpema:near,dimema:near

  if FLG98NOTXL
	extrn	jis_sjis:near
  endif

	extrn	farDISCOMPILEALL:far,farCLOSEALL:far
	extrn	farRESVAR:far
	extrn	farDISCOMPILEVAR:far
	extrn	farDISCOMPILEGOTO:far
	extrn	farRESETVAR_WORD:far	;,farRESETVAR_POINT:far
	extrn	printpoly:far,printmodpoly:far,printratpoly:far
	extrn	farSeqwrite:far,farSeqread:far


;  if GRAPH
;	include	\ub9\graph.asm
;  else
;	include	\ub9\nograph.asm
;  endif
;	ASSUME	CS:CODE,DS:DATA

;
;* set text color
;
	
colorin:
	jmp	far ptr farCOLORIN

;
;* evaluate a command line
;

evalilg:
	jmp	ilgerr

evalin:
	call	encodein

	mov	si,[calcsp]
	lodsw
	
	add	ax,ax
	sbb	ax,0
	and	ax,2*lenmask+1
	cmp	ax,2
	jbe	evalnull	;at most only CR

;	cmp	ax,unitbyte-3
;	jae	evalilg		;too long
	push	bp		;*
	lea	bp,[si+1]
	add	si,ax
	mov	word ptr [si-1],0bdc0h	;end mark of eval(replace CR)
	jmp	mainlp

evalout:
	pop	bp
evalnull:
	add	[calcsp],unitbyte
	jmp	mainlp


;
;* far jump far call branch
;

width:
	jmp	far ptr farWIDTH

console:
	jmp	far ptr farCONSOLE

calc_console:
	call	far ptr farCALC_CONSOLE
	ret

;
;	コマンド実行ルーチン(その２)
;

OPTIONCMD:
	XOR	BX,BX
	MOV	BL,[BP]
	SUB	BL,80H
	CMP	BL,30H
	JAE	OPTIONCMDERR	;0B0H 以上は関数
	INC	BP
	SHL	BX,1
	ADD	BX,OFFSET JMPTBL2	
	JMP	CS:[BX]

OPTIONCMDERR:
	cmp	bl,0f5h-80h	;0f5H=ema()
	je	goletema
	cmp	bl,0bbh-80h	;0bbh=mid()
	je	goletmid
	cmp	bl,0feh-80h	;0feh=member()
	je	goletmember
	cmp	bl,0ffh-80h	;0ffh=term()
	je	goletterm
	JMP	LETEXT

goletema:
	jmp	letema

goletmid:
	jmp	letmid
goletmember:
	jmp	letmember
goletterm:
	jmp	letterm


;
;☆ＥＲＡＳＥの処理
;
ERASE_NON:
	JMP	cantdo

ERASEIN:
	CMP	CS:[GOSUBSP],OFFSET GOSUBSP-GOSUBUNITBYTE+2
	JNE	ERASE_NON
	jmp	far ptr farERASE

;
;☆ＴＲＯＮの処理
;
TRON:
	MOV	BX,OFFSET MAININ
	MOV	AL,CS:[BX]
	CMP	AL,0B8H		;1ST BYTE OF MOV AX,ADDRESS
	JE	TRONOUT		;既に TRACE MODE
	MOV	[DEBUG1],AL
	MOV	AX,CS:[BX+1]
	MOV	[DEBUG2],AX
	MOV	AX,CS:[BX+3]
	MOV	[DEBUG3],AX	

	MOV	BYTE PTR CS:[BX],0B8H	;MOV AX,OFFSET DEBUG MAIN
	MOV	WORD PTR CS:[BX+1],OFFSET DEBUGin
	MOV	CS:[BX+3],0E0FFH	;JMP AX
TRONOUT:
	xor	ax,ax
	mov	[debugstop],al		;0
	dec	ax
	mov	[debugptr],ax		;0ffffh
tron50:
	MOV	ax,[BP]
	cmp	al,96H		;CODE OF STOP
	je	tronstop
	cmp	ax,0ac80h	;code of skip
	je	tronskip
	JMP	MAINLP

tronstop:
	inc	bp
	MOV	[DEBUGSTOP],-1
	jmp	tron50

tronskip:
	winc	bp
	mov	ax,[gosubsp]
	mov	[debugptr],ax
	jmp	tron50


DIRECTRET:
  if FLG98
	XOR	AX,AX
	MOV	DS,AX
	MOV	BX,0528H
	CMP	[BX],AL		;KEY BUFFER を チェック
	jne	go_CHKCTRL_C	;KEY 入力があったら調べる
	smov	ds,ss
	jmp	mainlp
  else
    if FLGIBMTOS
	XOR	AX,AX
	MOV	DS,AX
	MOV	BX,0418H
	CMP	[BX],AL		;KEY BUFFER を チェック
	jne	go_CHKCTRL_C	;KEY 入力があったら調べる
	smov	ds,ss
	jmp	mainlp
    else
	DEC	[CHKTIMER]
	JZ	CHKCTRL_C	;5 回に1回調べる
    endif
  endif

go_CHKCTRL_C:
	jmp	CHKCTRL_C

;
;☆ TRACE 実行時の処理
;
DEBUGin:
	cmp	[directflg],0
	jne	directret

	CMP	BP,TXTHED
	JB	DIRECTRET	;DIRECT MODE なので MAINLP に戻る
	CMP	BYTE PTR [BP-1],0C0H	;':'
	JE	DIRECTRET	;MULTI STATEMENT は無視

	mov	ax,[gosubsp]
	cmp	ax,[debugptr]
	ja	directret

	MOV	[CONTADR],BP
	mov	al,[out_dev]
	mov	[contout_dev],al
	mov	ax,[calcsp]
	mov	[contcsp],ax

	CALL	?LINE		;outPUT:BX=該当行の先頭番地
				;       DX=目的の行番号
	MOV	[EDITPTR],DX

	cmp	[DEBUGSTOP],0
	Jne	DEBUG8		;STOP MODE

	;NON STOP MODE(行番号の表示と^S,^C のチェック)

;	CALL	CHKCTRL_CS
	MOV	AL,'$'
	CALL	PRCHR
	MOV	BX,[EDITPTR]
	CALL	PRBXSP
	CALL	PRSPC
	CALL	PRSPC
	JMP	DEBUG30


	;STOP MODE(各行をリストして入力待ち)
DEBUG8:
	PUSH	BX
	CALL	discompilegoto
	POP	SI
	LODSW			;NEXT ADR

	;CODBUF にコピー

	MOV	CX,AX
	SUB	CX,SI
	MOV	DI,CODBUF+2
	REP	MOVSB

	;ASCII に戻して表示(印字)

	CALL	NL
	MOV	AL,'$'
	CALL	PRCHR
	CALL	DECODE
	MOV	DX,INPBUF
	CALL	MSG
	CALL	LETNL

	;一行入力

DEBUGLP:
	mov	[directflg],0		;let non direct mode
	CMP	[CONTADR],0
	JMPZ	READY			;CONT 出来ないときは READY へ
	CALL	NL
DEBUG10:

	CALL	CURSON

	CALL	DEBUG_GET_LINE
	TEST	BYTE PTR [INSFLG],-1
	JZ	DEBUG20
	MOV	BYTE PTR [INSFLG],0	;NON INSERT MODE に

	CALL	CURS_NORM

DEBUG20:
	MOV	BX,LNUMBS
	CMP	WORD PTR [BX],1
	JB	DEBUG10		;BREAK
	JMPNZ	GETCOMIN	;命令ならば解釈実行
	DEC	[YPOS]

	CALL	CURSOFF		;CR のみなら CONTINUE

	CALL	NL
DEBUG30:
	call	cursor
	call	compilevar
	mov	al,[contout_dev]
	mov	[out_dev],al
	MOV	BP,[CONTADR]
	jmp	directret	;	JMP	MAINLP


DEBUG_GET_LINE:
  if FLG98
        CALL    DEBUG_GETLSUB
  else
        call    getl_sub
  endif
	JC	DEBUG_NO_GET	;BREAK
	CALL	GET_DATA	
	JC	DEBUG_GETLTOOLONG	;TOO LONG LINE
	JMP	CURSOR		;CALL & RET

DEBUG_NO_GET:
	MOV	BX,LNUMBS
	MOV	WORD PTR [BX],0
	JMP	CURSOR		;CALL & RET

DEBUG_GETLTOOLONG:
	JMP	TOOLONGLINE


DEBUG_GETLSUB:
	MOV	AH,0CH		;KEY BUFFER を CLEAR して
	MOV	AL,7		;直接キー入力
	INT	21H
	CMP	AL,LF		;最初の LF は無視(FILE へ REDIRECT
	JNE	DEBUG_GETLSUB10	;されている場合の対策)
DEBUG_GETLLP:
	MOV	AH,7		;直接キー入力
	INT	21H
DEBUG_GETLSUB10:
	CMP	AL,CR
	JE	DEBUG_GETLRET
	CMP	AL,CTRL_C
	JE	DEBUG_GETLBREAK
	TEST	BYTE PTR [INSFLG],-1
	CALLNZ	MAKE1SPACE	;INSERT MODE ならば一文字分空ける
	CALL	PRCHRSUB
	JMP	DEBUG_GETLLP

DEBUG_GETLRET:			;改行は GET_DATA でする
	CLC
	RET

DEBUG_GETLBREAK:
	STC
	RET



;
;☆ ＴＲＯＦＦの処理
;
TROFF:
	CALL	TROFFSUB
	JMP	MAINLP

farTROFFSUB:
	call	TROFFSUB
	retf

TROFFSUB:			;INITIALIZE からも呼ばれる
	MOV	BX,OFFSET MAININ
	MOV	AL,CS:[BX]
	CMP	AL,0B8H		;1ST BYTE OF MOV AX,ADDRESS
	JNE	TROFFOUT	;既に TRACE OFF
	MOV	AL,[DEBUG1]
	MOV	CS:[BX],AL
	MOV	AX,[DEBUG2]
	MOV	CS:[BX+1],AX
	MOV	AX,[DEBUG3]
	MOV	CS:[BX+3],AX
TROFFOUT:
	RET

;
;☆ＰＲＩＮＴの処理
;

GOSEQWRITE:
	inc	bp
	call	get_ax
	jc	prnilgerr
	cmp	ax,maxfile
	ja	prnilgerr
	mov	[fileno],ax
	cmp	byte ptr [bp],0c2h
	jne	goseqwritejp		;jne	prnsynerr
	inc	bp
goseqwritejp:
	mov	bx,ax
	shl	bx,1
	cmp	word ptr [bx+PTWORD],0	;0 = ascii file
	je	seqwrtascii
	JMP	far ptr farSEQWRITE	;if non_ascii

seqwrtascii:
	mov	bx,[bx+HANDLE]	;HANDLE NUMBER
	cmp	bh,2
	jne	prnnotopen	;WOPEN されていない
	xor	bh,bh
	mov	[aschandle],bx
	mov	ah,bit4
	jmps	print2
	
prnsynerr:
	jmp	synerr
prnilgerr:
	jmp	ilgerr
prnnotopen:
	jmp	notopen

EXTRAFUNCTION:
	CMP	AH,0E2H
	JMPZ	MOVETAB		;code of TAB(
	JMP	PRFORM

;goDISPWORD:
;	jmp	far ptr farDISPWORD
;goDISPPOINT:
;	jmp	far ptr farDISPPOINT


	;
	; *lprint entry
	;
goLPTCHG:
	jmp	far ptr LPTCHG

LPRINT:	
	cmp	byte ptr [bp],codeofequal
	JE	goLPTCHG

	MOV	AH,[LPT_DEV]
	JMPs	PRINT2

	;
	; *PRINT ENTRY
	;
PRINT:	
	MOV	AL,[BP]
	CMP	AL,'#'
	je	GOSEQWRITE

	CMP	AL,codeofequal
	jne	printjp
	jmp	far ptr newPRNCHG
printjp:
	MOV	AH,[PRN_DEV]


PRINT2:	
	push	word ptr [out_dev]
	MOV	[OUT_DEV],AH

	MOV	al,[USINGSW]
	MOV	ah,[CRLFSW]
	push	ax

	MOV	[USINGSW],0
	MOV	[CRLFSW],-1

	;  print main loop

PRINLP:	
	MOV	AX,[BP]
	CMP	AL,CR
	JMPZ	CRLF?
	CMP	AL,0C0H		;':'
	JMPZ	CRLF?
	CMP	AX,0EC80H	;code of USING
	JMPZ	PRINT_USING_SET

	CMP	AL,'"'
	JE	PRFORM		;//
	CMP	AL,09FH		;code of WORD
        JE      PRFORM
	CMP	AL,0A9H		;code of POINT
        JE      PRFORM
	CMP	AL,codemark2	;=80H
	JMPZ	EXTRAFUNCTION
	CMP	AL,codemark3	;=0ffH
	je	PRFORM
	CMP	AL,VCODE5
	JBE	PRFORM
	CMP	AL,0A3H		;res
	JE	PRFORM
	CMP	AL,0B3H		;fn
	JE	PRFORM
	CMP	AL,0BBH		;0x
	JE	PRFORM
	CMP	AL,0DDH		;+
	JE	PRFORM
	CMP	AL,0DEH		;-
	JE	PRFORM
        CMP     AL,9eh          ;#i
        JE      PRFORM
	cmp	al,0c2h		;,
	je	gotabsetincBP
	CMP	AL,NCODE
	JB	CRLF?		;普通のコードは区切りとみなす

	;式の値を出力

PRFORM:	
	CALL	FORMUL
	call	print_calcsp
	add	[calcsp],unitbyte
	jmp	prnext

	;次の文字へ

PRNEXT:	
	MOV	[CRLFSW],-1
	MOV	AL,[BP]
	INC	BP
	CMP	AL,0C1H		;';'
	JE	NOCRLF
	CMP	AL,0C2H		;','
	JE	GOTABSET
	DEC	BP
	JMP	CRLF?


CRLF?:	
	TEST	[CRLFSW],-1
	CALLNZ	LETNL
	pop	ax
	MOV	[USINGSW],al
	MOV	[CRLFSW],ah
	pop	word ptr [out_dev]
	JMP	MAINLP

GOTABSETincBP:
	inc	bp
GOTABSET:
	MOV	AL,TAB
	CALL	PRCHR
NOCRLF:	
	MOV	[CRLFSW],0
	JMP	PRINLP
GOCRLF:	
	CALL	LETNL
	JMP	PRINLP


farPrint_calcsp:
	call	print_calcsp
	retf

print_calcsp:
	mov	si,[calcsp]
	mov	cx,[si]
	mov	al,ch
	and	al,attribmaskhigh
	cmp	al,complexmaskhigh
	je	goprintcomplex
	cmp	al,ratmaskhigh
	je	goprintrational
	cmp	al,stringmaskhigh
	je	goprintstring
	cmp	al,packmaskhigh
	je	goprintpack
	cmp	al,polymaskhigh
	je	goprintpoly
	cmp	al,modpolymaskhigh
	je	goprintmodpoly
	cmp	al,ratpolymaskhigh
	je	goprintratpoly
	call	prformsub	;int & point
print_calcsp_out:
	test	[USINGSW],-1
	jnz	print_calcsp_ret
	mov	al,[postmark]
	or	al,al
	jz	print_calcsp_ret
	CALL	PRCHR		;print space
print_calcsp_ret:
	ret

goprintcomplex:
	jmp	printcomplex
goprintrational:
	jmp	printrational
goprintstring:
	jmp	printstring
goprintpack:
	jmp	printpack
goprintpoly:
	jmp	far ptr printpoly	;in polynomi.asm
goprintmodpoly:
	jmp	far ptr printmodpoly
goprintratpoly:
	jmp	far ptr printratpoly	;in ratfunc.asm

	
printpack:
	mov	al,'('
	call	prchr

	call	ahedsp
	add	si,unitbyte+2
	lodsw
	mov	cx,ax
	jcxz	printpack100
	jmps	printpack20
printpack10:
	mov	al,','
	call	prchr
printpack20:
	push	cx
	mov	di,[calcsp]
	copy_si2di_ax
	push	si
	call	print_calcsp
	pop	si
	pop	cx
	myloop	printpack10

printpack100:
	mov	al,')'
	call	prchr
	add	[calcsp],unitbyte
	jmp	print_calcsp_ret


printcomplex:
	winc	si
	push	si
	mov	cx,[si]
	call	prformsub
	pop	si
	lodsw
	and	ax,lenmask
	add	ax,ax
	add	si,ax
	mov	cx,[si]
	cmp	cx,1
	je	printcomplex40
	cmp	cx,8001h
	jne	printcomplex50
	cmp	word ptr [si+2],1
	jne	printcomplex50
	mov	al,'-'		;if -1
	call	prchr
	jmp	printcomplex60
printcomplex40:
	cmp	word ptr [si+2],1
	jne	printcomplex50
	mov	al,'+'		;if 1
	call	prchr
	jmp	printcomplex60
printcomplex50:
	push	word ptr [plusmark]
	mov	[plusmark],'+'
	call	prformsub
	pop	word ptr [plusmark]
printcomplex60:
	mov	al,'#'		;complex
	call	prchr		;
	mov	al,'i'		;#i
	call	prchr		;
	jmp	print_calcsp_out


printrational:
	winc	si
	push	si
	mov	cx,[si]
	call	prformsub
	mov	al,'/'
	call	prchr
	pop	si
	lodsw
	and	ax,lenmask
	add	ax,ax
	add	si,ax
	cmp	[usingsw],0
	je	prformrat50
	mov	al,'/'
	call	prchr
	mov	cx,[si]
	call	prformsub
	jmp	print_calcsp_out

prformrat50:			;if plus
	push	word ptr [plusmark]
	mov	[plusmark],'/'
	mov	cx,[si]
	call	prformsub
	pop	word ptr [plusmark]
	jmp	print_calcsp_out


printstring:
  if flggprint
	test	[out_dev],bit5
	jnz	gogprintstring
  endif
	lodsw
	add	ax,ax
	sbb	ax,0
	and	ax,lenmask*2+1
	jz	printstringret
	mov	cx,ax
printstringlp:
	lodsb
	call	prchr
	call	chkCTRL_S
	myloop	printstringlp
printstringret:
	jmp	print_calcsp_ret

  if flggprint
gogprintstring:
	call	far ptr fargprintstring
	jmp	printstringret
  endif


	;☆PRINT のsubroutines


	; print formula
prformsub:
	push	cx		;/* attribute
	and	cx,lenmask
	inc	cx
	mov	di,work3
	rep	movsw		;copy to work3
	call	binasc

	mov	ax,ss
	add	ax,ASCBINSEG
	mov	ds,ax
	mov	es,ax

	pop	cx		;*/ attribute

	test	ch,signmaskhigh		;print sign
	mov	al,ss:[plusmark]
	jz	prformsub20
	mov	al,'-'		;if minus
prformsub20:
	mov	si,ASCBUFTOP-1
	mov	[si],al		;on top

	cmp	ss:[usingsw],0
	jne	prformsubusing
prformsubnonusing:
	test	ch,pointmaskhigh
	jz	prformsub30	;if integer
	call	far ptr prfloatnormalize
	jmps	prformsub30

prformsubusing:
	test	ch,pointmaskhigh
	jnz	prformsubusingfloat

	;print using for integer

	call	using4int

	mov	di,ASCBUFTOP
	mov	cx,0ffffh
	xor	al,al
	repne	scasb
	mov	cx,ss:[USING_FRAC_PART]
	jcxz	prformsubus10		;0 is assigned
	cmp	cx,-1
	je	prformsubus10		;no assignment
	mov	byte ptr es:[di-1],'.'
	mov	al,'0'
	rep	stosb
	xor	al,al
	stosb
	jmps	prformsub30
prformsubus10:
	mov	byte ptr es:[di-1],0
	jmps	prformsub30

prformsubusingfloat:
	call	far ptr using4float

prformsub30:
	mov	si,ASCBUFTOP-1
	lodsb
	or	al,al		;0 means no sign output
	jnz	prformsub40
prformsublp:
	lodsb
	or	al,al
	jz	prformsub50
prformsub40:
	call	prchr
	call	chkCTRL_S
	jmp	prformsublp
prformsub50:
	mov	ax,ss
	mov	ds,ax
	mov	es,ax
	ret


	;BX を 10進 5 桁で出力

PRTHL:	
	MOV	AX,BX
	MOV	CH,0
	MOV	BX,10000
	CALL	DECIHL
	MOV	BX,1000
	CALL	DECIHL
	MOV	BX,100
	CALL	DECIHL
	MOV	BX,10
	CALL	DECIHL
	MOV	AL,BL
	ADD	AL,'0'
	JMP	PRCHR		;call & ret

DECIHL:	
	XOR	DX,DX
	DIV	BX
	CMP	CH,'0'
	JE	DECI21		;0 を出力してもよい
	OR	AL,AL
	JNZ	DECI20		;最初の non-zero
	OR	CH,CH
	JZ	DECIHLRET
	CALL	PRCHR
DECIHLRET:
	MOV	AX,DX
	RET

DECI20:	
	MOV	CH,'0'
DECI21:	
	ADD	AL,'0'
	CALL	PRCHR
	JMP	DECIHLRET

;**
;**	ROUTINES for USING
;**

usingilgerr:
	jmp	ilgerr

PRINT_USING_SET:
	MOV	[USINGSW],-1
	ADD	BP,2
	CALL	GET_XY
	mov	ax,[Y_LOC]
;	cmp	ax,-1
;	jne	prus2
;	inc	ax		;default frac_part = 0
;prus2:
	mov	[USING_FRAC_PART],ax
	mov	ax,[X_LOC]
	cmp	ax,2
	jb	usingilgerr
	mov	[USING_INT_PART],ax
	CMP	AX,-1
	JE	PRUS10
	cmp	ax,1		;intpart>=2 or =0
	jne	prus5
	mov	ax,2
	mov	[using_int_part],ax
	jmp	prus10
prus5:
	CMP	AX,UNITWORD*5
	JA	PRUSERR
PRUS10:
	MOV	BX,[USING_FRAC_PART]
	CMP	BX,-1
	JNE	PRUS20
	XOR	BX,BX
;	MOV	[USING_FRAC_PART],BX
PRUS20:
	CMP	BX,UNITWORD*5
	JA	PRUSERR
	ADD	AX,BX
	CMP	AX,UNITWORD*5
	JA	PRUSERR

	MOV	AX,[BP]
	CMP	AX,0C229H	;'),'
	JMPNZ	SYNERR
	ADD	BP,2
	JMP	PRINLP

PRUSERR:
	JMP	ILGERR


GETINTLEN:			;get length of integer_part
	MOV	DI,ASCBUFTOP-1
	MOV	CX,SS:[ASCEND]
	SUB	CX,DI
	MOV	AL,'.'
	REPNE	SCASB
	JNE	GETINTL10
	DEC	DI
GETINTL10:
	MOV	AX,DI
	SUB	AX,ASCBUFTOP-1
	RET

;
;* USING MAIN PART
;
using4int:
	call	getintlen
	mov	cx,ss:[USING_INT_PART]
	cmp	cx,-1
	je	usingret	;default
	sub	cx,ax
	jb	USINGERR
	je	using100

	;right align

	push	cx		;/*
	mov	si,ss:[ascend]
	mov	di,si
	add	di,cx
	mov	cx,si
	inc	cx
	sub	cx,ASCBUFTOP-1
	std
	rep	movsb
	cld
	pop	cx		;*/
	mov	al,' '		;fill by spaces
	mov	di,ASCBUFTOP-1
	rep	stosb
	jmps	usingret
using100:
	xor	al,al		;end mark
	stosb
usingret:
	ret

usingerr:
	add	cx,ax
	mov	al,'?'
	mov	di,ASCBUFTOP
	stosb
	sub	cx,2
	mov	al,'-'
	rep	stosb
	jmp	using100


;
;* cut '0' for fractional part
;
schoolcut0:
	mov	di,ASCBUFTOP-1
	mov	cx,0ffffh
	xor	ax,ax
	repne	scasb
	sub	di,2
	push	di
	mov	cx,di
	sub	cx,ASCBUFTOP-1
	mov	al,'.'
	std
	repne	scasb
	cld
	pop	di
	jne	schoolcut0ret		;if no . <-> integer

	mov	cx,0ffffh
	mov	al,'0'
	std
	repe	scasb
	cld
	inc	di
	cmp	byte ptr es:[di],'.'
	jne	schoolcut0jp
	inc	di
schoolcut0jp:
	inc	di
	xor	ax,ax
	stosb			;end mark
schoolcut0ret:
	ret

;
;☆ SPC 関数
;
PRINTSPACES:
	jmp	far ptr farPrintspaces

;
;☆ TAB 関数
;
MOVETAB:
	jmp	far ptr farMOVETAB

;
;☆ DIRECT CODE 出力
;
PRINTCODE:
	jmp	far ptr farPRINTCODE

;
;☆ＬＥＴの処理
;

;☆各代入のエントリ

LET0:
	CALL	LET0SUB
	JMP	MAINLP

LET1:
	CALL	LET1SUB
	JMP	MAINLP

LET2:
	CALL	LET2SUB
	JMP	MAINLP

LET3:
	CALL	LET3SUB
	JMP	MAINLP

LET4:
	CALL	LET4SUB
	JMP	MAINLP

LET5:
	CALL	LET5SUB
	JMP	MAINLP


farlet_extended:
	call	let_extended
	retf

let_extended:
	mov	al,[bp]
	inc	bp
	MOV	BX,[TYPMEM]
	inc	bx
	mov	[bx],al		;operation type
	cmp	byte ptr [bp],codeofequal
	jne	let_synerr
	MOV	[TYPMEM],BX
	inc	bp
	call	formul
	jmp	calc		;call & ret


let_synerr:
	sub	bp,2
	backsp_mac		;reset calcsp
	jmp	synerr



;☆短変数への代入

LET0SUB:
	xor	ax,ax
	mov	al,[bp]
	inc	bp
	mov	bx,[bp]
	PUSH	BX
	add	bp,ax

	cmp	byte ptr [bp],codeofequal
	jne	let0_extended
	INC	BP

	CALL	FORMUL
let0_30:
	BACKSP_MAC
	MOV	AX,[SI]
	MOV	DX,AX
	TEST	AH,POINTMASKHIGH
	JNZ	ILG_LET0	;小数の代入は不可
	AND	AX,LENMASK
	CMP	AX,1
	JB	LET0_10		;IF 0
	JA	LET0_OVRERR

	AND	DH,80H		;符号
	MOV	AX,[SI+2]	;値
	TEST	AH,80H
	JNZ	LET0_OVRERR
	OR	AH,DH
LET0_10:
	POP	SI
	MOV	cs:[SI],AX		;値のセット
	RET

let0_extended:
	call	ahedsp
	mov	ax,cs:[bx]
	or	ax,ax
	jz	let0_ex10
	mov	dx,ax
	and	dh,7fh
	mov	[si+2],dx	;set value
	and	ah,80h
	mov	al,1
let0_ex10:
	mov	[si],ax		;set attribute
	call	let_extended
	jmp	let0_30

LET0_OVRERR:
	JMP	OVRERR
ILG_LET0:
	JMP	ILGLET


go_letmembernewlong:
	xor	si,si
	mov	cx,[maxword]
	jmp	letmembernew


;☆長変数への代入

LET2SUB:
	xor	ax,ax
	mov	al,[bp]
	inc	bp
	mov	bx,[bp]
	MOV	BX,cs:[BX]
	add	bp,ax

	cmp	byte ptr [bp],'.'
	je	go_letmembernewlong

	PUSH	BX
	cmp	byte ptr [bp],codeofequal
	JNZ	LET2_extended
	INC	BP

	CALL	FORMUL
let2_30:
	BACKSP_MAC
	MOV	CX,[SI]
	AND	CX,LENMASK
	CMP	CX,[MAXWORD]
	JA	LET2_OVRERR
	INC	CX

	POP	ES
	XOR	DI,DI
	REP	MOVSW		;値のセット
	MOV	AX,SS
	MOV	ES,AX
	RET

let2_extended:
	call	ahedsp
	mov	di,si
	mov	ds,bx
	xor	si,si
	copy_si2di_ax

	mov	ax,ss
	mov	ds,ax

	call	let_extended
	jmp	let2_30

LET2_OVRERR:
	JMP	OVRERR


go_letmembernewextra:
	xor	si,si
	mov	cx,limitword
	jmp	letmembernew


;☆特別変数への代入

LET4SUB:
	xor	ax,ax
	mov	al,[bp]
	inc	bp

	mov	bx,[bp]
	MOV	BX,cs:[BX]
	add	bp,ax

	cmp	byte ptr [bp],'.'
	je	go_letmembernewextra

	PUSH	BX
	cmp	byte ptr [bp],codeofequal
	JNZ	LET4_extended
	INC	BP

	CALL	FORMUL
let4_30:
	BACKSP_MAC
	POP	ES
	XOR	DI,DI
	copy_si2di_ax

	MOV	AX,SS
	MOV	ES,AX
	RET

let4_extended:
	call	ahedsp
	mov	di,si
	mov	ds,bx
	xor	si,si
	copy_si2di_ax

	mov	ax,ss
	mov	ds,ax

	call	let_extended
	jmp	let4_30


;☆配列短変数への代入

LET1SUB:
	CALL	GETSAVADR
	PUSH	DS
	PUSH	DI

	cmp	byte ptr [bp],codeofequal
	JNZ	LET1_extended
	INC	BP

	MOV	AX,SS
	MOV	DS,AX

	CALL	FORMUL
let1_30:
	BACKSP_MAC
	MOV	AX,[SI]
	MOV	DX,AX
	TEST	AH,POINTMASKHIGH
	JNZ	ILG_LET1	;小数の代入は不可
	AND	AX,LENMASK
	CMP	AX,1
	JB	LET1_50		;IF 0
	JA	LET1_OVRERR

	AND	DH,80H		;符号
	MOV	AX,[SI+2]	;値
	TEST	AH,80H
	JNZ	LET1_OVRERR
	OR	AH,DH
LET1_50:
	POP	DI
	POP	ES
	MOV	ES:[DI],AX		;値のセット
	MOV	AX,SS
	MOV	ES,AX
	RET	

let1_extended:
	mov	ax,[di]

	MOV	si,SS
	MOV	DS,si

	call	ahedsp
	or	ax,ax
	jz	let1_ex10
	mov	dx,ax
	and	dh,7fh
	mov	[si+2],dx	;set value
	and	ah,80h
	mov	al,1
let1_ex10:
	mov	[si],ax		;set attribute
	call	let_extended
	jmp	let1_30

ILG_LET1:
	JMP	ILGLET
LET1_OVRERR:
	JMP	OVRERR


;☆配列長変数への代入

go_letmembernewlongarray:
	mov	bx,ds
	mov	ax,ss
	mov	si,di
	mov	ds,ax
	mov	cx,[maxword]
	jmp	letmembernew

LET3SUB:
	CALL	GETLAVADR

	cmp	byte ptr [bp],'.'
	je	go_letmembernewlongarray

	PUSH	DS
	PUSH	DI

	cmp	byte ptr [bp],codeofequal
	JNE	LET3_extended
	INC	BP

	MOV	AX,SS
	MOV	DS,AX

	CALL	FORMUL
let3_30:
	BACKSP_MAC
	MOV	CX,[SI]
	AND	CX,LENMASK
	CMP	CX,[MAXWORD]
	JA	LET3_OVRERR
	INC	CX

	POP	DI		;** MOV	DI,[LETADR]
	POP	ES		;* MOV	ES,[LETSEG]
	REP	MOVSW		;値のセット
	MOV	AX,SS
	MOV	ES,AX
	RET	

let3_extended:
	mov	ax,ds
	mov	bx,di

	mov	si,ss
	mov	ds,si
	call	ahedsp

	mov	di,si
	mov	si,bx
	mov	ds,ax
	copy_si2di_ax

	MOV	AX,SS
	MOV	DS,AX

	call	let_extended
	jmp	let3_30

LET3_OVRERR:
	JMP	OVRERR


;☆配列特別変数への代入

go_letmembernewextraarray:
	mov	bx,ds
	mov	ax,ss
	mov	si,di
	mov	ds,ax
	mov	cx,limitword
	jmp	letmembernew


LET5SUB:
	CALL	GETLLAVADR

	cmp	byte ptr [bp],'.'
	je	go_letmembernewextraarray

	PUSH	DS
	PUSH	DI

	cmp	byte ptr [bp],codeofequal
	JNE	LET5_extended
	INC	BP

	MOV	AX,SS
	MOV	DS,AX

	CALL	FORMUL
let5_30:
	BACKSP_MAC
	POP	DI		;** MOV	DI,[LETADR]
	POP	ES		;* MOV	ES,[LETSEG]
	copy_si2di_ax

	MOV	AX,SS
	MOV	ES,AX
	RET	

let5_extended:
	mov	ax,ds
	mov	bx,di

	mov	si,ss
	mov	ds,si
	call	ahedsp

	mov	di,si
	mov	si,bx
	mov	ds,ax
	copy_si2di_ax

	MOV	AX,SS
	MOV	DS,AX

	call	let_extended
	jmp	let5_30

LET5_OVRERR:
	JMP	OVRERR


;☆外部配列変数への代入

LETEXT:
	MOV	AX,OFFSET HANDLE1
	MOV	BL,[BP]
	CMP	BL,0D4H
	JE	LETEXT10
	MOV	AX,OFFSET HANDLE2
	CMP	BL,0D6H
	JE	LETEXT10
	MOV	AX,OFFSET HANDLE3
	CMP	BL,0D8H
	JNE	LETEXTSYNERR
	
	;POINTER の移動
LETEXT10:
	INC	BP
	push	ax		;file no
	CALL	EXTSUB1st	;get file ptr
	jc	LETEXTILGIND
	push	cx
	push	dx
	BACKSP_MAC

	;代入する値の計算

	cmp	byte ptr [bp],codeofequal
	JNZ	LETEXTSYNERR
	INC	BP

	CALL	FORMUL
	BACKSP_MAC

	;書き込む

	pop	dx
	pop	cx
	pop	bx
	mov	[fileno],bx
	call	EXTSUB2nd	;move file ptr

	MOV	BX,[FILENO]
	MOV	CX,[SI]
	AND	CX,LENMASK
	INC	CX
	SHL	CX,1
	CMP	CX,[BX+6]
	JA	LETEXTOVRERR	;数値が大き過ぎる

	MOV	AH,40H		;WRITE HANDLE
	MOV	DX,SI
	MOV	BX,[BX]
	OR	BX,BX
	JZ	LETNOTOPEN
	INT	21H
	JC	LETEXTERR
	JMP	MAINLP

LETEXTERR:
	CMP	AX,5
	JMPNZ	DISKERR
	JMP	PROTECTED

LETEXTSYNERR:
	JMP	SYNERR
LETEXTOVRERR:
	JMP	OVRERR
LETNOTOPEN:
	JMP	NOTOPEN
LETEXTILGIND:
	JMP	INDEXERR


;☆☆汎用サブルーチン

;
;☆ＩＮＰＵＴの処理
;
  if JAPANESE
INPERRMSG	DB	'入力ミスです。もう一度',CR,LF,0
  else
INPERRMSG	DB	'Input error. Redo from start.',CR,LF,0
  endif

INPCHG2FILE:

	;GET FILE NAME

	INC	BP
	MOV	SI,BP
	MOV	DI,OFFSET FNAMEBUF
	XOR	CX,CX
ICHG2F10:	
	LODSB
	CMP	AL,'"'
	JE	ICHG2F30
	CMP	AL,'.'
	JE	ICHG2F20
	CALL	CHG2CAP		;capital
ICHG2F20:
	STOSB
	INC	CX
	CMP	CX,32
	JB	ICHG2F10
	JMP	LONGNAME
ICHG2F30:
	MOV	BYTE PTR [DI],0	;ASCIZ END MARK
	MOV	BP,SI

	;OPEN HANDLE FOR READ

	MOV	AH,3DH
	MOV	AL,0
	MOV	DX,OFFSET FNAMEBUF
	INT	21H	
	JC	ICHG2F50

ICHG2F100:
	RET

ICHG2F50:
	JMP	OPENERR

INPCHGERR:
	JMP	SYNERR


INPCHG:
	;CLOSE FILE

	TEST	[INP_DEV],BIT4
	JZ	INPCHG10	;FILE を使っていない場合
	MOV	BX,[INPHANDLE]
	MOV	AH,3EH
	INT	21H
INPCHG10:
	INC	BP
	MOV	AL,[BP]
	CMP	AL,'"'
	JNE	INPCHG30
	CALL	INPCHG2FILE	;FILE の場合
	MOV	[INPHANDLE],AX
	MOV	[INP_DEV],BIT4
	MOV	[INPFILEPTR],0
	MOV	[INPFILEPTR+2],0
	smov	es,cs
	MOV	SI,OFFSET FNAMEBUF
	MOV	DI,OFFSET INPFNAMEBUF
	MOV	CX,16
	REP	MOVSW
	smov	es,ss
	JMPS	INPCHG60
INPCHG30:
	CMP	AL,0A7H		;CODE OF INPUT
	JNE	INPCHGERR
	MOV	[INP_DEV],BIT0
	INC	BP
INPCHG60:
	JMP	MAINLP


GOSEQREAD:
	JMP	far ptr farSEQREAD


strinput:
	mov	[inputsw],1
	jmps	inputin

INPUT:	
	mov	[inputsw],0
inputin:
	MOV	AL,[BP]
	CMP	AL,codeofequal
	JE	INPCHG
	CMP	AL,'#'
	je	GOSEQREAD
	MOV	[INP_BP],BP	;FOR MIS INPUT
	CMP	AL,'"'
	JNZ	INPIN

	;if a prompt message exists

INPRLP:	
	INC	BP
	MOV	AL,[BP]
	CMP	AL,'"'
	JE	INPRJP
	CALL	PRCHR		;CRT only
	JMP	INPRLP

INPBREAK:
	MOV	BP,[INP_BP]	;CONT用
	DEC	BP
	JMP	BREAK

INPAGAIN:
	MOV	BP,[INP_BP]
	MOV	DX,OFFSET INPERRMSG
	CALL	MSG_CS
	JMP	INPUTin


INPRJP:	
	INC	BP
	cmp	byte ptr [bp],0C1H		;';'
	JMPNZ	SYNERR
	INC	BP

	;line input from console?
INPIN:	
	TEST	[INP_DEV],BIT4
	JMPNZ	INPFILE		;input from file
	MOV	AL,'?'
	CALL	PRCHR
	CALL	PRSPC

	CALL	CURSON

	push	bp
	CALL	GETL_SUB
	pop	bp
	JC	INPBREAK
	CALL	GET_DATA
	JC	INPAGAIN

	TEST	BYTE PTR [INSFLG],-1
	JZ	INPINJP
	cmp	[insflgdef],0
	jne	inpinjp
	MOV	BYTE PTR [INSFLG],0	;OVRWRT mode に

	CALL	CURS_NORM

INPINJP:
	CALL	CURSOFF

	MOV	DI,LNUMBS
	MOV	CX,[DI]
	DEC	CX

	;search '?'

	MOV	DI,INPBUF
	MOV	AL,'?'
	REPNE	SCASB
	jne	inpagain	;no ?

	;cut space

	dec	di
inpin5:
	inc	di
	cmp	byte ptr [di],' '
	je	inpin5
	
	cmp	[inputsw],0
	jne	strinpsub	;string case
	jcxz	INPAGAIN	;only ? (value case)
	jmp	inp_numer

strinpsub:
	call	ahedsp
	xchg	si,di		;input string
	add	di,2
minp10:
	lodsb
	stosb
	cmp	al,CR	
	jne	minp10
	mov	byte ptr [di-1],0
	mov	si,[calcsp]
	mov	ax,di
	sub	ax,si
	sub	ax,2
	shr	ax,1
	jc	minp15
	or	ah,80h		;if odd length
minp15:
	or	ah,stringmaskhigh
	mov	[si],ax
	CALL	INPLET
	JMP	MAINLP


inp_numer:			;input numeric
	MOV	SI,DI		;slide to cut space
	MOV	DI,INPBUF
minp30:
	LODSB
	STOSB
	CMP	AL,CR
	JNE	minp30

	;encode

	PUSH	BP
	MOV	BP,INPBUF
	call	ahedsp
	mov	di,[calcsp]	;	MOV	DI,inpcalcbuf
	CALL	ENCDIN
	mov	word ptr [di],0
	mov	si,[calcsp]	;	inpcalcbuf
	call	compilevardirect
	POP	BP
	mov	ax,[calcsp]
	MOV	[INPPTR],ax	;	inpcalcbuf
MULTIINP:
	PUSH	BP
	MOV	BP,[INPPTR]
	CALL	FORMUL
	MOV	[INPPTR],BP
	POP	BP
	CALL	INPLET
	CMP	BYTE PTR [BP],0C2H	;CODE OF ','
	JE	INPNEXT

	add	[calcsp],unitbyte	;//

	MOV	SI,[INPPTR]
	cmp	byte ptr [si],CR
	jne	inpagain	;values too many

	JMP	MAINLP

INPNEXT:
	INC	BP
	MOV	SI,[INPPTR]
MINP40:
	LODSB
	MOV	[INPPTR],SI
	CMP	AL,' '
	JE	MINP40
	CMP	AL,0C2H		;code of ','
	JE	MULTIINP

	add	[calcsp],unitbyte
	JMP	INPAGAIN	;variables too many


;INPUT FROM FILE

INPFILE:
	mov	di,offset inpbuf
	lea	si,[di-2]		;//work1

	;get a line from file

	mov	cx,UNITBYTE-16
INPF10:		
	CALL	GETF1
	jc	inpf30		;EOF
	cmp	al,CR
	je	inpfCR
	cmp	al,LF
	je	inpf40
	cmp	al,CTRL_Z
	je	inpfCTRL_Z
inpf20:
	stosb
	loop	inpf10
	jmps	inpf40
inpfCR:
	call	getf1
	jc	inpf40		;if no more data
	cmp	al,LF
	je	inpf40
	call	restoref1
	jmps	inpf40
inpfCTRL_Z:
	call	getf1
	jc	inpf40		;if last
	call	restoref1
	mov	al,CTRL_Z
	jmps	inpf20
inpf30:
	cmp	di,offset inpbuf
	je	inpfnodata
inpf40:
	mov	al,CR		;forced to end
inpf50:
	stosb
	mov	al,LF
	stosb
	xor	al,al
	stosb

;	mov	dx,inpbuf
;	call	msg

	cmp	[inputsw],0
	je	inpf100
	mov	di,inpbuf
	jmp	strinpsub

inpfnodata:
	jmp	nodataerr

inpf100:	
	PUSH	BP
	MOV	BP,INPBUF
	call	ahedsp
	MOV	DI,[calcsp]	;	inpcalcbuf
	CALL	ENCDIN
	mov	word ptr [di],0
	mov	si,[calcsp]	;	inpcalcbuf
	call	compilevardirect
	POP	BP
	mov	ax,[calcsp]
	MOV	[INPPTR],ax	;	inpcalcbuf
FMULTIINP:
	PUSH	BP
	MOV	BP,[INPPTR]
	CALL	FORMUL
	MOV	[INPPTR],BP
	POP	BP
	CALL	INPLET
	CMP	BYTE PTR [BP],0C2H	;CODE OF ','
	JE	FINPNEXT

	add	[calcsp],unitbyte

	MOV	SI,[INPPTR]
	cmp	byte ptr [si],CR
	jne	Finpagain	;values too many

	JMP	MAINLP

FINPNEXT:
	INC	BP
	MOV	SI,[INPPTR]
FMINP40:
	LODSB
	MOV	[INPPTR],SI
	CMP	AL,' '
	JE	FMINP40
	CMP	AL,0C2H		;code of ','
	JE	FMULTIINP

	add	[calcsp],unitbyte
	JMP	FINPAGAIN	;variables too many

FINPAGAIN:		;variables too many
	JMP	ILGERR

goinpema:
	jmp	inpema

	;代入する変数を得る

INPLET:
	MOV	AX,[BP]
	cmp	ax,0f580h	;ema?
	je	goinpema
	MOV	[TYPMEM1],AL
	CALL	GETVADR
	MOV	AX,DS		;行き先
	MOV	ES,AX		;ES:DI
	MOV	DI,SI
	MOV	AX,SS		;出発元
	MOV	DS,AX		;DS:DI
	MOV	SI,[CALCSP]
	MOV	AL,[TYPMEM1]
	CMP	AL,VCODE4
	JAE	INP20
	CMP	AL,VCODE2
	JAE	INP10
	CALL	STORESV		;短変数
	JMPS	INP30
INP10:
	CALL	STORELV		;長変数
	JMPS	INP30
INP20:
	CALL	STORELLV	;特別変数
INP30:
	add	[calcsp],unitbyte
	ret


	;INPUT FILE から一文字入力
GETF1:
	push	cx
	MOV	DX,SI
	MOV	AH,3FH
	MOV	BX,[INPHANDLE]
	MOV	CX,1
	INT	21H
	JMPC	DISKERR
	or	ax,ax
	jz	getf1EOF
	ADD	[INPFILEPTR],1
	ADC	[INPFILEPTR+2],0
	mov	al,[si]		;input data
	pop	cx
	clc
	ret
getf1EOF:
	pop	cx
	stc
	ret


restoreF1:
	sub	[inpfileptr],1
	sbb	[inpfileptr+2],0
	mov	dx,-1
	mov	cx,dx
	mov	ax,4201h	;relative move file ptr
	mov	bx,[inphandle]
	int	21h
	ret


;
;☆ＤＩＭの処理
;

DIM_NON:
	JMP	cantdo

DIM:	
	CMP	CS:[GOSUBSP],OFFSET GOSUBSP-GOSUBUNITBYTE+2
	JNE	DIM_NON
DIMLP:
	CALL	DIMSUB
	cmp	byte ptr [bp],0c2h	;code of ,
	JMPNZ	MAINLP		;もうない場合
	INC	BP
	JMP	DIMLP		;next def
	
DIMDBLERR:
	JMP	DBLDEF
DIMSYNERR:
	JMP	SYNERR

godimema:
	jmp	dimema
	
DIMSUB:
	MOV	AX,[BP]
	cmp	ax,0f580h
	je	godimema
	INC	BP
	SUB	AL,VCODE
	JB	DIMSYNERR
	CMP	AL,3
	JE	DIMLVAR
	CMP	AL,5
	JE	DIMLLVAR
	CMP	AL,1
	JNE	DIMSYNERR

	;短変数の配列の場合

	MOV	AX,1
	JMPS	DIMMAIN

	;長変数の配列
DIMLVAR:
	MOV	AX,[MAXALL]
	JMPS	DIMMAIN

	;特別変数の配列
DIMLLVAR:
	MOV	AX,unitword

DIMMAIN:
	MOV	[arrayword],AX
	xor	ax,ax
	mov	al,[bp]
	inc	bp
	mov	bx,[bp]
	add	bp,ax		;new text pointer

	cmp	word ptr cs:[bx],0	;erased mark
	Jne	DIMDBLERR	;配列の二重定義

	push	bx		;* table adr

	;配列のサイズを計算

dimmain50:
	MOV	[DIMENSION],1
	CALL	FORMUL

	XOR	CX,CX		;二次以上の SIZE
	XOR	BX,BX		;

	MOV	AL,[BP]
	INC	BP
	CMP	AL,')'
	JE	DIMMAIN100	;一次元
	CMP	AL,0C2H		;CODE OF ','
	JE	DIMMAIN150	;二次元以上
	DEC	BP
	JMP	SYNERR

	;二次元以上の場合

DIMMAIN150:
	INC	[DIMENSION]
	CALL	FORMUL
	XOR	CX,CX
	MOV	AL,[BP]
	INC	BP
	CMP	AL,')'
	JE	DIMMAIN200	;二次元
	CMP	AL,0C2H		;CODE OF ','
	JE	DIMMAIN300	;三次元
	DEC	BP
	JMP	SYNERR

	;三次元の場合

DIMMAIN300:
	INC	[DIMENSION]
	CALL	KAKKO
	CALL	BACKSP
	MOV	CX,[SI]
	CMP	CX,1
	JA	BIGINDEX	;INDEX が大き過ぎる
	JB	DIMMAIN200	;INDEX=0
	MOV	CX,[SI+2]
	CMP	CX,65535
	JE	BIGINDEX	;INDEX must be <65535

	;二次元の場合

DIMMAIN200:
	CALL	BACKSP
	MOV	BX,[SI]
	CMP	BX,1
	JA	BIGINDEX	;INDEX が大き過ぎる
	JB	DIMMAIN100	;INDEX=0
	MOV	BX,[SI+2]
	CMP	BX,65535
	JE	BIGINDEX	;INDEX must be <65535

	;一次元の場合

DIMMAIN100:
	CALL	BACKSP
	MOV	AX,[SI]
	CMP	AX,1
	JA	BIGINDEX	;>1 WORD OR MINUS
	JB	DIMOUT		;INDEX=0
	MOV	AX,[SI+2]
	CMP	ax,65535
	JE	BIGINDEX	;INDEX must be <65535

	;NOW AX,BX,CX=1st,2nd,3rd indices
	
DIMOUT:
	MOV	DX,[arrayseg]	;DX=BASE SEGMENT
	MOV	DS,DX
	XOR	SI,SI
	MOV	DX,SS:[DIMENSION]
	MOV	[SI],DX		;次元
	MOV	WORD PTR [SI+2],0	;未定義
	MOV	[SI+4],AX	;先頭はサイズ
	MOV	[SI+8],BX	;二次元用
	MOV	[SI+12],CX	;三次元用
	MOV	WORD PTR [SI+14],1	;今は意味なし
	INC	CX
	MOV	[SI+10],CX
	INC	BX
	MOV	AX,BX
	MUL	CX
	OR	DX,DX
	JNZ	BIGINDEX	;二次以上の総要素数は<=65535
	MOV	[SI+6],AX
	MOV	BX,AX		;MEMO
	MOV	AX,[SI+4]	;AX を復活
	inc	ax

	smov	ds,ss

	MUL	BX
	JMPS	DIMOUT30

	;新変数が設定できないときの処理
BIGINDEX:
	JMP	INDEXERR
CANTDIM:	
	JMP	fullerr

DIMOUT30:
	;NOW DX:AX=NUMBER OF ALL MEMEBERS

	MOV	CX,[arrayword]
	MOV	BX,DX		;MEMO DX
	MUL	CX
	MOV	SI,DX
	MOV	DI,AX		;SI:DI
	MOV	AX,BX
	MUL	CX
	OR	DX,DX
	JNZ	CANTDIM		;32BIT 以上
	ADD	AX,SI
	JC	CANTDIM		;32BIT 以上
	MOV	DX,AX
	MOV	AX,DI	

	REPT	3
	SHR	DX,1
	RCR	AX,1
	ENDM

	or	dx,dx
	jnz	cantdim
	add	ax,arrayheadseg+1
	jc	cantdim
	MOV	DX,[arrayseg]
	ADD	AX,DX
	JC	CANTDIM
	CMP	AX,[LIMITSEG]
	JAE	CANTDIM
	pop	bx		;* table adr
	mov	cs:[bx],dx	;base segment of theis array
	MOV	[arrayseg],AX	;base segment of next array

DIMCLR:
	MOV	AX,DX		;base segment

	;全メンバーを 0 に

	MOV	DX,[arrayword]	;words/MEMBER
	CMP	DX,8
	JBE	DIMCLRALL	;8 words 以下ならベタ消し

	shl	dx,1		;byte size

	MOV	DS,AX
	MOV	ES,AX

	MOV	DI,ARRAYHEAD	;先頭
	XOR	AX,AX
	XOR	BX,BX
	MOV	CX,ES:[BX+12]	;max index for 3rd dim
	INC	CX		;0 になっても OK
DIMCLRLP10:
	PUSH	CX
	MOV	CX,ES:[BX+8]	;max index for 2nd dim
	INC	CX		;0 になっても OK
DIMCLRLP20:
	PUSH	CX
	MOV	CX,ES:[BX+4]	;max index for 1st dim
	INC	CX		;0 になっても OK
DIMCLRLP30:
	MOV	[DI],AX
	ADD	DI,DX		;dx=byte size
	JNC	DIMCLRJP40
	MOV	SI,DS
	ADD	SI,1000H
	MOV	DS,SI
DIMCLRJP40:
	myloop	DIMCLRLP30
	POP	CX
	myloop	DIMCLRLP20
	POP	CX
	myloop	DIMCLRLP10
	smov	ds,ss
	smov	es,ss

DIMCLR100:
	RET


DIMCLRALL:			;512KB 以上ではまづい
	ADD	AX,ARRAYHEADSEG	;ARRAYHEAD の分
	MOV	BX,[arrayseg]
	SUB	BX,AX
	MOV	ES,AX
	XOR	AX,AX
	XOR	DI,DI
DIM0ALL10:
	SUB	BX,1000H
	JB	DIM0ALL20
	MOV	CX,8000H
	REP	STOSW
	MOV	CX,ES
	ADD	CX,1000H
	MOV	ES,CX
	JMP	DIM0ALL10
DIM0ALL20:
	ADD	BX,1000H
	JZ	DIM0ALL30
	MOV	CX,BX
	MY_SHL	CX,3
	REP	STOSW
DIM0ALL30:	
	smov	es,ss
	ret			;JMP	DIMCLR100		

;
;☆テキストから，で区切られた二つのパラメータを得る
;
; 入力	BP=pointer
; 出力	DX 1st parameter
;	CX 2nd parameter
; CALL する前に default の DX & CX をセットしておく事

GETPAR:	
	MOV	AL,[BP]
	CMP	AL,CR
	JE	GETPARRET
	CMP	AL,0C0H		;':'
	JE	GETPARRET

	CMP	AL,0C2H		;','
	JE	GET2ND
	PUSH	CX
	CALL	HEXCX
	MOV	DX,CX
	POP	CX
	cmp	byte ptr [bp],0c2h	;code of ,
	JNE	GETPARRET
GET2ND:	
	MOV	AL,[BP+1]
	CMP	AL,CR
	JE	GETPARRET
	CMP	AL,0C0H
	JE	GETPARRET
	INC	BP
	CALL	HEXCX
GETPARRET:
	RET	

;
;☆テキストから－で区切られた二つのパラメータを得る
;
; 入力	BP=pointer
; 出力	DX 1st parameter
;	CX 2nd parameter
;	CF=1 DELETE に対するものとしては無効

farPARASE:
	CALL	PARASE
	retf

PARASE:	
	MOV	DX,0
	MOV	CX,0FFFFH
	MOV	AL,[BP]
	CMP	AL,CR
	JE	SETCF		;コマンドのみ
	CMP	AL,0C0H		;':'
	JE	SETCF		;コマンドのみ

	CMP	AL,0DEH		;'-'
	JE	PAR2ND		;1ST は省略されている

	PUSH	CX
	cmp	al,0b3h		;fn
	jne	par1st5
	inc	bp
	mov	al,[bp]
par1st5:
	CMP	AL,NCODE_LABEL
	JE	PAR1ST_LABEL
	CALL	HEXCX
PAR1ST10:
	MOV	DX,CX
	MOV	AL,[BP]
	CMP	AL,0DEH		;'-'
	POP	BX		;dummy
	JNE	RESCF		;1st のみ
	MOV	CX,BX
	JMPS	PAR2ND
PAR1ST_LABEL:
	CALL	GETLABELLINE
	JMP	PAR1ST10

	
PAR2ND:	
	INC	BP
	MOV	AL,[BP]
	CMP	AL,CR
	JE	SETCF		;1ST は省略されている
	CMP	AL,0C0H
	JE	SETCF		;1ST は省略されている

	cmp	al,0b3h		;fn
	jne	par2nd5
	inc	bp
	mov	al,[bp]
par2nd5:
	CMP	AL,NCODE_LABEL
	JE	PAR2ND_LABEL
	CALL	HEXCX
RESCF:	
	OR	AL,AL
	RET	

SETCF:
	STC
	RET	

PAR2ND_LABEL:
	CALL	GETLABELLINE
	JMP	RESCF


;
;	* RESET TIME
;
CLRTIME:
	jmp	far ptr farCLRTIME

;
;	* new
;

NEW:	
	jmp	far ptr farNEW

;
;	* revive
;

REVIVE:
	jmp	far ptr farREVIVE

;
;	* word
;
wordcantdo:
	JMP	cantdo
WORDIN:	
	CMP	cs:[GOSUBSP],OFFSET GOSUBSP-GOSUBUNITBYTE+2
	JNE	wordcantdo
	jmp	far ptr farWORDIN

;
;	* point
;
point_NON:
	JMP	cantdo

POINTIN:	
;	CMP	cs:[GOSUBSP],OFFSET GOSUBSP-GOSUBUNITBYTE+2
;	JNE	point_NON	;cannot do in subroutines
	jmp	far ptr farPOINTIN

;
;	* pop
;
POPSHORTSUB:			;input es:di = destination
	CALL	POPMAIN
	CMP	AX,1
	JB	POPSHORT100
	JA	POPOVR		;OVERFLOW
	TEST	CH,40H
	JNZ	POPOVR		;IF POINT NUMBER
	LODSW
	CMP	AX,8000H
	JAE	POPOVR
	AND	CH,80H
	OR	AH,CH		;SET SIGN
POPSHORT100:
	STOSW
	RET



POPLONGSUB:
	CALL	POPMAIN
	CMP	AX,SS:[MAXWORD]
	JA	POPOVR
	XCHG	AX,CX
	STOSW			;store attribute
	REP	MOVSW
	RET

POPXLONGSUB:
	CALL	POPMAIN
	XCHG	AX,CX
	STOSW			;store attibute
	REP	MOVSW
	RET

	public	POPOVR
POPOVR:
	JMP	OVRERR

POPMAIN:
	LDS	SI,DWORD PTR SS:[STACKPTR]
	SUB	SI,2		;MUST CHECK FLAG
	JB	NOPOP		;NO DATA IN STACK
	MOV	AX,[SI]		;ATTRIBUTE
	MOV	CX,AX
	AND	AX,LENMASK
	SUB	SI,AX
	SUB	SI,AX
	MOV	SS:[STACKPTR],SI
	RET			;DS:SI CX(AX)

NOPOP:
	JMP	STACKEMPTY


PUSHSHORTSUB:
	OR	AX,AX
	JZ	PUSHSHORTSUB0000
	LES	DI,DWORD PTR SS:[STACKPTR]
	CMP	DI,USTKSIZE-4
	JAE	PUSHOVR
	MOV	CX,AX
	AND	AX,7FFFH
	STOSW			;PUSH DATA
	MOV	AX,CX
	AND	AX,8000H
	OR	AL,1
	STOSW
	MOV	SS:[STACKPTR],DI
	RET

PUSHSHORTSUB0000:
	LES	DI,DWORD PTR SS:[STACKPTR]
	CMP	DI,USTKSIZE-2
	JAE	PUSHOVR
	XOR	AX,AX		;DATA
	STOSW
	MOV	SS:[STACKPTR],DI
	RET


PUSHLONGSUB:
	LES	DI,DWORD PTR SS:[STACKPTR]
	LODSW
	MOV	CX,AX
	AND	CX,LENMASK	
	MOV	DX,DI		;memo top
	ADD	DI,CX
	ADD	DI,CX
	CMP	DI,USTKSIZE-2
	JAE	PUSHOVR		;STACK EMPTY
	STOSW			;PUSH ATTRIBUTE
	MOV	SS:[STACKPTR],DI
	MOV	DI,DX
	REP	MOVSW
	RET

PUSHOVR:
	JMP	STACKFULL


;☆画面クリア

CLS:
	MOV	AL,[BP]
	CMP	AL,CR
	JE	cls0		;コマンドのみ
	CMP	AL,0C0H		;':'
	JE	cls0		;コマンドのみ
	call	get_ax
	jc	cls_ilg
	or	ax,ax
	jz	cls0
	dec	ax
	je	cls1
	dec	ax
	je	cls2
	dec	ax
	je	cls3
cls_ilg:
	jmp	ilgerr


  if GRAPH
cls0:
cls1:
	call	clear_screen
	JMP	MAINLP

cls3:
	call	clear_screen
cls2:
  if FLGIBMTOS
  	cmp	[graphflg],0
	je	cls1		;if text mode
  endif
	call	far ptr farusegraph?
	jmp	far ptr cleargraphic

  else
cls0:
cls1:
cls2:
cls3:
	call	clear_screen
	JMP	MAINLP
  endif

CODE	ENDS


code2	segment	word public
	assume	cs:code2,ds:data

	public	farCONSOLE,farCALC_CONSOLE,farCHECK_PROTECTED
	public	consoledefault
	public	farDispwordsub,farRevivesub
	public	farINITWP,newPRNCHG2FIN
	public	farpointsetsub


  if FLG98
	public	lines1msg,lines2msg
  endif

	extrn	prfloatnormalize:far,using4float:far


  if flggprint
	extrn	fargprintstring:far
  endif

  if FLGFMR
	extrn	setcolor:near,initcolor:near
  endif

  if GRAPH
	extrn	palettein:near,paletteinitin:near,cleargraphic:near
	extrn	farusegraph?:far
    if FLGIBMTOS
  	extrn	return2text:near
    endif
  endif


;
; * erase an array
;
farERASE:

ERASELP:
	XOR	BX,BX
	MOV	BL,[BP]
	INC	BP
	SUB	BL,VCODE+1
	JZ	ERASESHORTARRAY
	SUB	BX,2
	JZ	ERASELONGARRAY
	SUB	BX,2
	JZ	ERASEEXLONGARRAY
ERASESYNERR:
	JMP	far ptr SYNERR

ERASEUNDEF:
	JMP	far ptr UNDEFERR


	;IF EXTRALONG ARRAY

ERASEEXLONGARRAY:
	MOV	AX,unitword
	JMPS	ERASEMAIN

	;IF LONG ARRAY

ERASELONGARRAY:
	MOV	AX,[MAXALL]
	JMPS	ERASEMAIN

	;IF SHORT ARRAY

ERASESHORTARRAY:
	MOV	AX,1

ERASEMAIN:
	MOV	[arrayword],AX
	xor	ax,ax
	mov	al,[bp]
	inc	bp
	mov	bx,[bp]
	add	bp,ax
	push	ds
	mov	ax,code
	mov	ds,ax
	mov	ax,[bx]
	pop	ds
	or	ax,ax
	jz	eraseundef

	;次の配列の開始 SEGMENT の計算

	MOV	DS,ax
	XOR	SI,SI
	MOV	AX,[SI+4]
	INC	AX
	MUL	WORD PTR [SI+6]	;DX:AX=要素の総数
	PUSH	DX
	smov	ds,ss

	MUL	[arrayword]
	MOV	CX,AX
	MOV	DI,DX
	POP	AX
	MUL	[arrayword]
	ADD	DI,AX		;CARRY は出ない
	
	REPT	3
	SHR	DI,1
	RCR	CX,1
	ENDM

	push	ds
	mov	ax,code
	mov	ds,ax
	ADD	CX,ARRAYHEADSEG+1	;HEADER+calibration
	MOV	DX,[BX]			;その配列のSEGMENT:以下保存
	MOV	WORD PTR [BX],0		;erased mark
	ADD	CX,DX
	pop	ds
	
	;NOW CX=START SEGMENT OF NEXT ARRAY

	CMP	CX,[arrayseg]
	jb	erase50
	jne	gosystemerr

	MOV	[arrayseg],DX	;if last defined array
	JMP	ERASEAGAIN

gosystemerr:
	jmp	far ptr systemerr

ERASE50:
	;途中の配列の場合

	SUB	CX,DX		;新旧 SEGMENT の差

	;他の配列の SEGMENT の書き換え

	push	ds
	mov	ax,code
	mov	ds,ax
	mov	si,offset vartbl
	CALL	ERASEREWRITE
	pop	ds

	;配列の移動

	MOV	AX,[arrayseg]
	SUB	AX,CX
	MOV	[arrayseg],AX
	MOV	BX,DX
	ADD	BX,CX
	MOV	DS,BX
	MOV	ES,DX
	SUB	AX,DX		;移動 SEGMENT 量
	MOV	DX,AX
	XOR	SI,SI
	XOR	DI,DI
ERASE110:
	OR	DX,DX
	JZ	ERASE130	;丁度64Kの区切りと一致している場合
	SUB	DX,1000H
	JB	ERASE120
	MOV	CX,8000H
	REP	MOVSW	
	MOV	AX,DS
	ADD	AX,1000H
	MOV	DS,AX
	MOV	AX,ES
	ADD	AX,1000H
	MOV	ES,AX
	JMP	ERASE110
ERASE120:
	ADD	DX,1000H
	MOV	CX,DX
	MY_SHL	CX,3
	REP	MOVSW
ERASE130:
	smov	ds,ss
	smov	es,ss
ERASEAGAIN:
	cmp	byte ptr [bp],0c2h	;code of ,
	JNE	ERASEOUT
	INC	BP
	JMP	ERASELP
ERASEOUT:
	jmp	gomainlp2


ERASEREWRITE:
	LODSW
	OR	AX,AX
	JZ	ERASERWOUT	;TABLE の終り
	cmp	al,0ffh
	je	ERASERWOUT	;TABLE の終り
	cmp	al,vcode
	je	eraserw10	;if simple short
	add	si,namelen-2
	LODSW
	CMP	AX,DX
	JBE	ERASEREWRITE
	SUB	[SI-2],CX	;SEGMENT の書き換え
	JMP	ERASEREWRITE
ERASERWOUT:
	RET

eraserw10:
	add	si,namelen
	jmp	eraserewrite
	

;
; * color set
;
farCOLORIN:
	mov	al,[bp]
	cmp	al,codeofequal
	je	gopalettein

	cmp	al,CR
	je	paletteinit
	cmp	al,0c0h		;code of ':'
	je	paletteinit

	call	far ptr farget_ax
  if FLG98
  comment %
	ror	al,1		;BRG-order to BGR-order
	mov	ah,al		;
	shr	ah,1		;
	shr	ah,1		;
	rcr	al,1		;
	rcr	al,1		;
  %
	my_ror	al,3
	xor	al,1
  else
	mov	ah,al
	xor	al,al
  endif
  if FLG98
	mov	byte ptr [tcolor],al
  else
	mov	[tcolor],ax
  endif
  if FLGIBMTOS
  	mov	[tcolor4fill],ax
  endif

  if FLGFMR
	call	setcolor	
  endif
	jmp	gomainlp2	


gopalettein:
	inc	bp
  if GRAPH
	jmp	palettein
  else
	jmp	far ptr synerr
  endif

paletteinit:
  if FLGFMR
	call	initcolor
  else
    if FLG98
	mov	[tcolor],white
    else
	mov	[tcolor],white*100h
	mov	[tcolor4fill],white*100h
    endif
  endif

  if GRAPH
	jmp	paletteinitin
  else
	jmp	gomainlp2
  endif

;
;** width
;
  if FLG98
    if FLGXL
lines1msg	db	ESC,'[>3l$'
lines2msg	db	ESC,'[>3n$'
    else
lines1msg	db	ESC,'[>3h$'
lines2msg	db	ESC,'[>3l$'
    endif
  endif

ex2ilgerr:
widthilgerr:
	jmp	far ptr ilgerr

widthinit:
	mov	al,ss:[linesdef]	;default
	jmps	widthin

farWIDTH:
	mov	dl,[bp]
	cmp	dl,CR
	je	widthinit
	cmp	dl,0c0h		;':'
	je	widthinit
	call	far ptr farGET_ax
	cmp	byte ptr [bp],0c2h	;','
	jne	widthret
	inc	bp
	call	far ptr farGET_ax
  if FLG98
widthin:
	mov	dx,offset lines1msg
	cmp	ax,maxlines1
	je	width10
	mov	dx,offset lines2msg
	cmp	ax,maxlines2
	jne	widthret
width10:
	mov	[maxlinesnow],al
	smov	ds,cs
	mov	ah,9
	int	21h	
	smov	ds,ss

	call	far ptr farCLEAR_SCREEN
	call	far ptr farcursoff

	mov	al,[maxlinesnow]
	sub	al,[functionkey_sw]
	mov	[btmline],al
widthret:
	jmp	consoleinit
  endif

  if FLGFMR
widthin:
	mov	dh,al
	mov	dl,[chars1]
	mov	ah,3
	int	91h
	mov	ah,4
	int	91h
	dec	dh
	mov	[maxlinesnow],dh

	call	far ptr farCLEAR_SCREEN
	call	far ptr farcursoff

	mov	al,[maxlinesnow]
	sub	al,[functionkey_sw]
	mov	[btmline],al
widthret:
	jmp	consoleinit

  endif


  if FLGIBMTOS
widthin:
widthret:
	jmp	gomainlp2
  endif

	
;
;** CONSOLE
;
consoleinit:
	mov	[functionkey_sw],1
	call	consoledefault
	jmp	consoleout

farCONSOLE:
  if GRAPH
    if FLGIBMTOS
	cmp	[graphflg],0
	je	consoleinijp
	call	return2text
consoleinijp:
    endif
  endif
	mov	dl,[bp]
	cmp	dl,CR
	je	consoleinit
	cmp	dl,0c0h		;':'
	je	consoleinit

	mov	al,[topline]
	cmp	dl,0c2h		;code of ','
	je	console10	;start line is unchanged
	xor	ax,ax
	inc	bp
	cmp	dl,0e5h		;'*' means default
	je	console10
	dec	bp
	call	far ptr farGET_ax
	jc	consoleilg
	mov	dx,ax
	add	dx,minlines
	cmp	dx,word ptr [maxlinesnow]
	ja	consoleilg
console10:
	mov	dl,[topline]		;memo old top line
	mov	[topline],al
	cmp	byte ptr [bp],0c2h	;code of ','
	jne	consoleilg

	inc	bp
	xor	ax,ax
	mov	al,[btmline]
	sub	al,dl		;old number of lines in console window
	mov	dl,[bp]
	cmp	dl,0c2h		;code of ','
	je	console22	;number of lines is unchanged
	inc	bp
	cmp	dl,0e5h		;'*' means default:bottom=maxlines
	je	console23
	dec	bp
	call	far ptr farGET_ax
	jc	consoleilg
	cmp	ax,minlines
	jb	consoleilg
console22:
	add	ax,word ptr [topline]
	cmp	ax,word ptr [maxlinesnow]
	jbe	console24
console23:
	mov	al,[maxlinesnow]
  if FLG98+FLGFMR
  else
;	dec	al
  endif
console24:
	mov	[btmline],al

	mov	al,[functionkey_sw]
	cmp	byte ptr [bp],0c2h	;code of ','
	je	console24a
	mov	ah,[btmline]		;function key sw not assigned
	cmp	ah,[maxlinesnow]
	jb	console24c
	mov	[functionkey_sw],0
	jmp	console24c	
console24a:
	inc	bp
	call	far ptr farGET_ax
	jc	consoleilg

	or	ax,ax
	jz	console24b
	mov	al,1
console24b:
	mov	[functionkey_sw],al
	mov	ah,[btmline]
	cmp	ah,[maxlinesnow]
	jb	console24c
	sub	ah,al
	mov	[btmline],ah
console24c:
	call	far ptr farCALC_CONSOLE
	mov	al,[ypos]
	cmp	al,[topline]
	jae	console25
	mov	al,[topline]
	jmps	console27
console25:
	cmp	al,[btmline]
	jb	console30
	mov	al,[btmline]
	dec	al
console27:
	mov	[ypos],al
console30:
	cmp	[functionkey_sw],0
	je	consolefclear
	call	far ptr farDISP_functionkey
	jmp	consoleout
consolefclear:
	call	far ptr farCLEAR_functionkey

consoleout:
  if FLGIBMTOS
	call	setcursorpostition2
  endif
	jmp	gomainlp2

  if FLGIBMTOS
setcursorpostition2:
	mov	dl,ss:[xpos]
	mov	dh,ss:[ypos]
	xor	bx,bx
	mov	ah,2
	int	10h
	ret
  endif

consoleilg:
	call	consoledefault
	jmp	ex2ilgerr	


consoledefault:
	mov	[topline],0
  if DISPFKEY
	mov	al,[maxlinesnow]
;    if FLGFMR
;    	dec	al
;    endif
    if FLGIBMTOS
    	dec	al
    else
    	sub	al,[functionkey_sw]
    endif
	mov	[btmline],al
	push	ax
	call	far ptr farCALC_CONSOLE
	pop	ax
	cmp	[ypos],al
	jb	console200
	dec	ax
	mov	[ypos],al
console200:
	cmp	[functionkey_sw],0	;0 or 1
	je	console210
	call	far ptr farDISP_functionkey
console210:
  endif
  if FLGIBMTOS
	call	setcursorpostition2
  endif
	ret

farCALC_CONSOLE:
	mov	al,[topline]
	mov	dl,[chars1]
	mul	dl
	add	ax,ax
	mov	[topadr],ax
	mov	al,[btmline]
	mul	dl
	add	ax,ax
	mov	[btmadr],ax	
	sub	ax,[topadr]
	shr	ax,1
	mov	[charsallnow],ax
	retf


farCHECK_PROTECTED:
	mov	si,offset fnamebuf
	mov	di,offset dummyname
chkprolp:
	lodsb
	cmp	al,':'
	je	chkpro20
	or	al,al
	jnz	chkprolp
	add	di,2
	jmps	chkpro50
chkpro20:
	mov	al,[si-2]
	mov	[di],al	
chkpro50:
	mov	dx,offset fnamebuf

	push	dx
	push	di

	mov	ah,56h		;rename
	int	21h

	pop	dx
	pop	di
	jc	checkproterr

	mov	ah,56h		;re-rename
	int	21h
checkproret:
	retf

checkproterr:
	cmp	ax,2
	je	checkproret
	jmp	far ptr protected


;	* reset time

farCLRTIME:
  if FLGIBMTOS
  	push	ds
	xor	ax,ax
	mov	ds,ax
	mov	bx,ds:[046ch]	;get tick count
clrtimelp:
	cmp	bx,ds:[046ch]
	je	clrtimelp
	mov	bx,ds:[046ch]	;get tick count
	mov	ax,ds:[046eh]	;get tick count
	pop	ds
	mov	word ptr [TICKCOUNTS],bx
	mov	word ptr [TICKCOUNTS+2],ax
	mov	ah,2ch		;get TIME
	int	21h
  else
	mov	ah,2ch		;get TIME
	int	21h
  	mov	bh,dh
clrtimelp:
	mov	ah,2ch		;get TIME
	int	21h
	cmp	bh,dh
	je	clrtimelp
  endif

	MOV	[HOUR],CH
	MOV	[MINUTE],CL
	MOV	[SECOND],DH
  	mov	byte ptr [MSECOND],DL

	MOV	AH,2AH
	INT	21H
	MOV	[DATE],AL	;ONLY WEEK

	jmp	gomainlp2

;
;	* new
;
farnewcantdo:
	jmp	far ptr cantdo

farNEW:	
	cmp	bp,txthed
	jae	farnewcantdo		;cannot NEW in program
	call	far ptr farDiscompileall	;for REVIVE
	mov	[labelend],offset label_table
	call	far ptr farIniloop
	XOR	AX,AX
	MOV	[EDITPTR],AX
	MOV	BX,TXTHED
	MOV	[BX],AX
	INC	BX
	MOV	[TXTEND],BX
	mov	[calcsp_limit],bx
	add	[calcsp_limit],unitbyte
	call	far ptr farCloseall
	CALL	far ptr farCHGOUT_INIT
	CALL	INITWP		;WORD POINT の初期化
	call	far ptr farTroffsub
	CALL	far ptr farRESVAR
	JMP	far ptr READY

farINITWP:
	call	INITWP
	retf

INITWP:
;	mov	[schoolflg],0
	mov	ax,defaultword
	MOV	[MAXWORD],AX
	INC	AX
	MOV	[MAXALL],AX
	add	ax,7
	my_shr	ax,3		;segmentize
	mov	[longvarsegsize],ax

	MOV	AX,pointinit
	MOV	[POINTWORD],AX
	add	ax,ax
	mov	[pointbyte],ax
	MY_SHL	AX,2
	MOV	DX,_floatdeciratio
	MUL	DX
	sub	dx,3
	MOV	[POINTDECI],DX
	RET

;
;	* revive
;

farREVIVE:
	call	revivesub
	jmp	far ptr ready


farRevivesub:
	call	revivesub
	retf

revivesub:
	call	far ptr fardiscompilevar	;reset compilevar_sw

	MOV	BX,TXTHED
	MOV	SI,BX
	LODSW
	OR	AX,AX
	JNZ	REVVRET		;消されていない場合
	LODSW
	OR	AX,AX
	JZ	REVVRET		;復活するテキストがない場合
	inc	si		;pass sapce#

	;行の最後を捜す
REVV30:
	LODSB
	CMP	AL,CR
	JE	REVV70
	CALL	far ptr farPASSTOKEN
	JMP	REVV30
REVV70:
	MOV	[BX],SI		;最初の NEXT ADR

	;TEXT END を捜す
REVV80:
	MOV	BX,[SI]
	OR	BX,BX
	JZ	REVV90
	MOV	SI,BX
	JMP	REVV80
REVV90:
	INC	SI
	MOV	[TXTEND],SI
	MOV	[calcsp_limit],si
	add	[calcsp_limit],unitbyte

	CALL	far ptr farINITWP	;WORD POINT の初期化
	call	far ptr farTroffsub
	CALL	far ptr farINILOOP
	CALL	far ptr farDiscompilegoto
	CALL	far ptr farRESVAR
REVVRET:
	ret


;
;☆ＷＯＲＤの処理
;

DISPWPSW	DB	?

WORDILG:
	JMP	ex2ILGERR

farWORDIN:	
	MOV	CS:[DISPWPSW],-1
	mov	ax,[bp]
	cmp	ax,0e5deh	;'-*'
	jne	word2
	winc	bp
	mov	cs:[dispwpsw],0	;not display
	mov	ax,[lvarlimit]
	jmp	wordset

word2:
	cmp	al,0e5h		;code of *
	jne	word5
	inc	bp
	mov	ax,[lvarlimit]
	jmp	wordset

word5:
	call	far ptr farFormul
	backsp_mac
	lodsw
	test	ah,80h
	jz	word20
	mov	cs:[dispwpsw],0	;not display
word20:
	test	ah,pointmaskhigh
	jnz	wordilg		;not integer
word30:
	and	ax,lenmask
	cmp	ax,1
	jne	wordilg		;not 1	
	mov	ax,[si]
	CMP	AX,[LVARLIMIT]
	JA	WORDILG
	CMP	AX,2
	JB	WORDILG
wordset:
	MOV	[MAXWORD],AX
	INC	AX
	MOV	[MAXALL],AX
	add	ax,7
	my_shr	ax,3		;segmentize
	mov	[longvarsegsize],ax

	CALL	far ptr farCLOSEALL	;FILE を全て CLOSE
	call	far ptr farResetvar_word

	TEST	CS:[DISPWPSW],-1
	JNZ	DISPWORD10
	jmp	gomainlp2

;farDISPWORD:				;also jumped from print
;	INC	BP
DISPWORD10:
	CALL	DISPWORDSUB
	jmp	gomainlp2

farDISPWORDSUB:
	call	DISPWORDSUB
	retf

DISPWORDSUB:
	CALL	NL2
	MOV	DX,OFFSET WDMSG1
	CALL	MSG_CS2		;CRT only
	MOV	BX,[MAXWORD]
	CALL	far ptr farPRNTBX
	MOV	DX,OFFSET WDMSG2
	CALL	MSG_CS2		;CRT only
	MOV	BX,LIMITWORD
	CALL	far ptr farPRNTBX
	MOV	DX,OFFSET FINISHMSG
	call	MSG_CS2
	ret

  if JAPANESE
WDMSG1		DB	'長変数のワード数は ',0
WDMSG2		DB	' (内部計算のワード数は ',0
POINTMSG1	DB	'小数部のワード数は ',0
POINTMSG2	DB	' (10進での表示桁数は ',0
FINISHMSG	DB	')',CR,LF,0
pointmsgschool	db	'小数部の表示桁数は ',0
  else
WDMSG1		DB	'Words for long variables ',0
WDMSG2		DB	' (Words for internal calculation ',0
POINTMSG1	DB	'Words for fractionals ',0
POINTMSG2	DB	' (Decimals for display ',0
FINISHMSG	DB	')',CR,LF,0
pointmsgschool	db	'Fractionals for display ',0
endif

;
;	* point
;

POINTILG:
	JMP	ex2ILGERR

farPOINTIN:	
	MOV	CS:[DISPWPSW],-1
	mov	ax,[bp]
	cmp	ax,0e5deh	;'-*'
	jne	point2
	winc	bp
	mov	cs:[dispwpsw],0	;not display
	mov	ax,pointmax
	jmp	pointset

point2:
	cmp	al,0e5h		;code of *
	jne	point5
	inc	bp
	mov	ax,pointmax
	jmp	pointset

point5:
	cmp	al,0c2h		;code of ','
	je	pointend10

	call	far ptr farFormul
	backsp_mac
	lodsw
	test	ah,80h
	jz	point20
	mov	cs:[dispwpsw],0	;not display
point20:
	test	ah,pointmaskhigh
	jnz	pointilg	;not integer
point30:
	and	ax,lenmask
	cmp	ax,1
	jne	pointilg	;not 1 word
	mov	ax,[si]
	cmp	ax,pointmin
	jb	pointilg
	cmp	ax,pointmax
	ja	pointilg
	inc	ax
	and	al,0feh		;must be even
pointset:
	cmp	ax,[pointword]
	je	pointend	;do not do if same point
pointsetin:			;jumped from school
	call	pointsetsub
	test	cs:[dispwpsw],-1
	jnz	disppoint10
pointend:
	xor	ax,ax
	cmp	byte ptr [bp],0c2h	;code of ','
	jne	pointend20
pointend10:
	inc	bp
	call	far ptr farget_ax
	or	al,ah
pointend20:
	mov	[fixedflag],al
	jmp	gomainlp2

farpointsetsub:
	call	pointsetsub
	retf

pointsetsub:
	mov	[pointword],ax
	add	ax,ax
	mov	[pointbyte],ax
	mov	[schooldeci],ax
	my_shl	ax,2
	mov	dx,_floatdeciratio
	mul	dx
	sub	dx,3
	cmp	[schoolflg],0
	je	pointset10
	add	dx,[schooldeci]
	shr	dx,1
pointset10:
	mov	[pointdeci],dx
	ret


;farDisppoint:				;also jumped from print
;	inc	bp
disppoint10:
	call	disppointsub
	jmp	gomainlp2

disppointsub:
	CALL	NL2
	cmp	[schoolflg],0
	je	disppointsub10

	mov	dx,offset pointmsgschool
	call	msg_cs2
	mov	bx,[schooldeci]
	call	far ptr farprntbx
	call	nl2
	ret

disppointsub10:
	MOV	DX,OFFSET POINTMSG1
	CALL	MSG_CS2			;CRT only
	MOV	BX,[POINTWORD]
	CALL	far ptr farPRNTBX
	MOV	DX,OFFSET POINTMSG2
	CALL	MSG_CS2			;CRT only

	MOV	BX,[POINTDECI]
	CALL	far ptr farPRNTBX
	MOV	DX,OFFSET FINISHMSG
	call	MSG_CS2
	ret


;
;☆ SPC 関数
;
farPRINTSPACES:
	WINC	BP
	CALL	far ptr farKAKKO_ax
	jc	prcodeovr
	add	[calcsp],unitbyte
	or	ax,ax
	jz	PRSPSOUT	;=0
	CMP	ax,2000
	JAE	PRCODEOVR
	mov	cx,ax
PRSPSLP:
	call	prspc2
	myloop	PRSPSLP
PRSPSOUT:
	JMP	far ptr PRNEXT

PRCODEOVR:
	JMP	far ptr ILGERR

;
;☆ TAB 関数
;
farMOVETAB:
	WINC	BP
	CALL	far ptr farKakko_ax_signed
	jc	prcodeovr
	add	[calcsp],unitbyte
	mov	cx,ax
	jcxz	MOVETAB10	;=0
	and	ch,7fh
MOVETAB10:
	MOV	[X_LOC],cx
;	TEST	[OUT_DEV],BIT0	;画面出力か?
;//	JZ	MOVETAB20
	CMP	cx,word ptr [chars1]
	JAE	PRCODEOVR
	SUB	cl,[XPOS]	;LOCATESUB は用いない
	JE	MOVETAB40
	JB	MOVETAB50
	test	ah,80h
	jnz	movetab15	;cursor move only

	TEST	[OUT_DEV],BIT0	;画面出力か?
	JZ	MOVETAB20

	MOV	AL,[OUT_DEV]
	MOV	[OUT_DEV],BIT0
	PUSH	AX
	PUSH	CX
MOVETAB12:
	call	prspc2
	myloop	MOVETAB12
	POP	CX
	POP	AX
	MOV	[OUT_DEV],AL
	jmp	movetab20

movetab15:
	ADD	[XPOS],cl
	CALL	far ptr farCURSOR

MOVETAB20:
	MOV	AL,[OUT_DEV]
	TEST	AL,BIT2
	JZ	MOVETAB25
	MOV	[OUT_DEV],BIT2
	PUSH	AX
	PUSH	CX
MOVETAB22:
	call	prspc2
	myloop	MOVETAB22
	POP	CX
	POP	AX
	MOV	[OUT_DEV],AL
MOVETAB25:
	TEST	AL,BIT3		;FILE 出力か?
	JZ	MOVETAB30
	MOV	[OUT_DEV],BIT3
	PUSH	AX
	PUSH	CX
MOVETAB26:
	call	prspc2
	myloop	MOVETAB26
	POP	CX
	POP	AX
	MOV	[OUT_DEV],AL

MOVETAB30:
	TEST	AL,BIT1		;PRINTER 出力か?
	JZ	MOVETAB40
	TEST	AL,BIT0
	JZ	MOVETAB55	;画面出力なし
	MOV	[OUT_DEV],BIT1
	PUSH	AX
MOVETAB32:
	call	prspc2
	myloop	MOVETAB32
	POP	AX
	MOV	[OUT_DEV],AL
MOVETAB40:
	JMP	far ptr PRNEXT

MOVETAB50:
	TEST	[OUT_DEV],BIT1	;PRINTER 出力か?
	JZ	MOVETAB40
MOVETAB55:
;//	MOV	[Y_LOC],-1
	CALL	far ptr farLLOCATESUB
	JMP	MOVETAB40

PRCODEOVR2:
	JMP	far ptr ILGERR


;
;☆ DIRECT CODE 出力
;
farPRINTCODE:
	WINC	BP
	CALL	far ptr farKAKKO_ax
	add	[calcsp],unitbyte
	or	ax,ax
	jz	PRCODE10
	OR	AH,AH
	JNZ	PRCODEOVR2
PRCODE10:
	TEST	[OUT_DEV],BIT0
	JZ	PRCODE20
	CALL	CODEPRNT
PRCODE20:
	TEST	[OUT_DEV],BIT1
	JZ	PRCODE30
  if FLG98
	MOV	AH,11H		;DIRECT PRINT OUT
	INT	1AH
  else
	mov	ah,5
	mov	dl,al
	int	21h
  endif
PRCODE30:
	TEST	[OUT_DEV],BIT2
	JZ	PRCODE40
	PUSH	BX
	MOV	BX,[PRNHANDLE]
	CALL	far ptr farFPRNSUB
	POP	BX
PRCODE40:
	TEST	[OUT_DEV],BIT3
	JZ	PRCODE50
	PUSH	BX
	MOV	BX,[LPTHANDLE]
	CALL	far ptr farFPRNSUB
	POP	BX
PRCODE50:
	JMP	far ptr PRNEXT


CODEPRNT:
	PUSH	DS
  if flg32
	pusha
  else
	PUSH	AX
	PUSH	BX
	PUSH	CX
  endif
	smov	ds,ss

	CMP	AL,20H
	JB	goCTRL_KEY
	JMP	far ptr PRCHRSUBIN
goCTRL_KEY:
	jmp	far ptr CTRL_KEY



; change to capital

newCHG2CAP:	
	CMP	AL,'a'
	JB	newCHG2CAP100
	CMP	AL,'z'
	JA	newCHG2CAP100
	SUB	AL,20H
newCHG2CAP100:
	RET	

;
;☆ＬＰＲＩＮＴの処理
;
LPTCHG:
	;CLOSE FILE

	TEST	[LPT_DEV],BIT3
	JZ	LPTCHG10		;FILE を使っていない場合
	MOV	BX,[LPTHANDLE]
	MOV	AH,3EH
	INT	21H
LPTCHG10:
	MOV	[LPT_DEV],0

LPTCHGLP:
	INC	BP
	MOV	AL,[BP]
	cmp	al,CR
	je	LPTCHG100
	cmp	al,0c2h		;code of ':'
	je	LPTCHG100
	CMP	AL,99h		;code of print
	je	lptchg30
	CMP	AL,9ah		;code of lprint
	je	lptchg40

	TEST	[LPT_DEV],BIT3	;BIT2 は使わない
	JNZ	LPTCHGERR	;FILE を２つ定義
	CALL	newPRNCHG2FILE	;FILE の場合
	mov	si,code
	mov	es,si
	MOV	SI,OFFSET FNAMEBUF
	MOV	DI,OFFSET LPTFNAMEBUF
	MOV	CX,16
	REP	MOVSW
	smov	es,ss
	CALL	newPRNCHG2FILE2
	MOV	[LPTHANDLE],AX
	OR	[LPT_DEV],BIT3
	JMPS	LPTCHG60
LPTCHG30:
	OR	[LPT_DEV],BIT0
	JMPS	LPTCHG50
LPTCHG40:
	OR	[LPT_DEV],BIT1
LPTCHG50:
	INC	BP
LPTCHG60:
	cmp	byte ptr [bp],0DDH	;CODE OF +
	JE	LPTCHGLP

LPTCHG100:
	jmp	gomainlp2

LPTCHGERR:
	JMP	far ptr SYNERR


;
; * print redirection to file
;
prnchg2fsynerr:
	jmp	far ptr Synerr
prnchg2flongname:
	jmp	far ptr longname

newPRNCHG2FILE:
	call	far ptr farFormul
	mov	si,[calcsp]
	lodsw
	test	ah,stringmaskhigh
	jz	prnchg2fsynerr
	add	ax,ax
	sbb	ax,0
	and	ax,2*lenmask+1
	cmp	ax,maxfilenamelen
	ja	prnchg2flongname

	mov	cx,ax
	mov	di,offset fnamebuf
rep	movsb
comment %
	jcxz	PCHG2F30
PCHG2F10:	
	lodsb
	cmp	al,'.'
	je	PCHG2F12
	call	newCHG2CAP		;capital
PCHG2F12:
	stosb
	myloop	pchg2f10	
PCHG2F30:
%
	MOV	BYTE PTR ES:[DI],0	;ASCIZ END MARK
	add	[calcsp],unitbyte
	RET


newPRNCHG2FILE2:
	;OPEN HANDLE FOR APPEND

	call	far ptr farCHECK_protected

	MOV	AH,3DH
	MOV	AL,2
	MOV	DX,OFFSET FNAMEBUF
	INT	21H	
	JC	PCHG2F50	;no file

	;MOVE POINTER TO FILE END-1

newPRNCHG2FIN:
	PUSH	AX		;☆HANDLE

	MOV	BX,AX
	MOV	AH,42H		;move file pointer
	MOV	AL,2		;to tail
	MOV	CX,0
	MOV	DX,CX
	INT	21H
	or	ax,dx
	jz	PCHG2F40	;IF 0 BYTES FILE

	MOV	AH,42H		;move file pointer
	MOV	AL,2		;to tail-1
	MOV	CX,0FFFFH
	MOV	DX,CX
	INT	21H

	;CUT CTRL_Z IF EXISTS

	MOV	AH,3FH		;READ 1 CHAR
	MOV	DX,OFFSET FNAMEBUF
	MOV	CX,1
	INT	21H

	CMP	[FNAMEBUF],CTRL_Z
	JNE	PCHG2F40

	MOV	AH,42H		;CTRL_Z を消すために１つ戻る
	MOV	AL,1
	MOV	CX,0FFFFH
	MOV	DX,CX
	INT	21H

PCHG2F40:
	POP	AX		;☆HANDLE
	JMPS	PCHG2F100


PCHG2F50:
	CMP	AX,2
	jnz	pchg2fopenerr

	;CREATE FILE

	MOV	AH,3CH
	MOV	DX,OFFSET FNAMEBUF
	MOV	CX,0
	INT	21H
	JC	pchg2fopenerr

PCHG2F100:
	RET


PRNCHGERR:
	JMP	far ptr SYNERR

pchg2fopenerr:
	jmp	far ptr openerr


newPRNCHG:
	;CLOSE FILE

	TEST	[PRN_DEV],BIT2
	JZ	PRNCHG10	;FILE を使っていない場合
	MOV	BX,[PRNHANDLE]
	MOV	AH,3EH
	INT	21H
PRNCHG10:
	MOV	[PRN_DEV],0

PRNCHGLP:
	INC	BP
	MOV	AL,[BP]
	cmp	al,CR
	je	PRNCHG100
	cmp	al,0c2h		;code of ':'
	je	PRNCHG100
	cmp	al,99h
	je	prnchg30
	cmp	al,9ah
	je	prnchg40
	TEST	[PRN_DEV],BIT2	;BIT3 は使わない
	JNZ	PRNCHGERR	;FILE を２つ定義
	CALL	newPRNCHG2FILE	;FILE の場合
;	smov	es,cs
	mov	si,code
	mov	es,si
	MOV	SI,OFFSET FNAMEBUF
	MOV	DI,OFFSET PRNFNAMEBUF
	MOV	CX,16
	REP	MOVSW
	smov	es,ss
	CALL	newPRNCHG2FILE2
	MOV	[PRNHANDLE],AX
	OR	[PRN_DEV],BIT2
	JMPS	PRNCHG60
PRNCHG30:
	OR	[PRN_DEV],BIT0
	JMPS	PRNCHG50
PRNCHG40:
	OR	[PRN_DEV],BIT1
PRNCHG50:
	INC	BP
PRNCHG60:
	cmp	byte ptr [bp],0DDH		;CODE OF +
	JE	PRNCHGLP
PRNCHG100:
	jmp	gomainlp2


code2	ends

