;FILE.ASM

	INCLUDE	UBDEF.H
	INCLUDE	UB.H

DATA	SEGMENT	WORD PUBLIC

	PUBLIC	HANDLE,PTWORD,EOFFLG,HANDLE1,HANDLE2,HANDLE3,FILENO
	PUBLIC	FHANDLE,FATTR,FADR,FPOINT,EDITPTR,ENDMEM
	public	fnamebuf,dummyname,listtimer
	PUBLIC	LNEND,editpos,filetypemark

	EXTRN	INPUTLEN:WORD,maxword:word,
	extrn	CALCSP:WORD,arrayseg:WORD
	EXTRN	XPOS:BYTE,YPOS:BYTE
	extrn	chars1:byte,chars2:word
	extrn	charsall2:word
	extrn	topline:byte,topadr:word,tcolor:word
	extrn	btmline:byte,btmadr:word
	extrn	charsallnow:word,maxlinesnow:byte
	EXTRN	DATE:BYTE,HOUR:BYTE,MINUTE:BYTE,SECOND:BYTE
	EXTRN	DATE2:BYTE,HOUR2:BYTE,MINUTE2:BYTE,SECOND2:BYTE
	EXTRN	TXTEND:WORD,TXTTOP:WORD,calcsp_limit:word
	extrn	compilevar_sw:byte,compilegoto_sw:BYTE
	extrn	compilejp_sw:byte
  if DISPFKEY
	extrn	functionkey_sw:byte
  endif
	EXTRN	OUT_DEV:BYTE,PRN_DEV:BYTE,LPT_DEV:BYTE,INP_DEV:BYTE
	EXTRN	PRNHANDLE:WORD,LPTHANDLE:WORD,inphandle:word
	extrn	nowlin:word
	extrn	labelend:word,vramsegnow:word
	EXTRN	INPFILEPTR:WORD
	extrn	inputsw:byte
	extrn	emahandle:word
  if FLGIBMTOS
	extrn	originalvideomode:byte,graphflg:byte
  endif


EDITPTR		DW	0
EDITPOS		DB	0,0

DELTOP		DW	?
DELEND		DW	?

LASTLN		DW	?
ENDMEM		DW	?

OLDNUM		DW	?
NEWNUM		DW	?

LNEND		DW	?

ASCPTR		DW	?
PRENUMBER	DW	?	;前の行番号

listtimer	dw	?

; handle for sequential file

HANDLE	DW	MAXFILE+1 DUP(?)	;HANDLE#
PTWORD	DW	MAXFILE+1 DUP(?)	;ROPEN した FILE の POINT 数
FILEPTR	DW	2*MAXFILE+2 DUP(?)	;ROPEN した FILE の 現在位置
FILENO	DW	?
EOFFLG	DW	MAXFILE+1 DUP(?)
	;EOFFLG は END OF FILE の FLAG 兼,次の DATA のATTRIBUTE

FHANDLE	DW	?
FPOINT	DW	?
FATTR	DW	?
FADR	DW	?

; handle for random file

HANDLE1	DW	7 DUP(0)
HANDLE2	DW	7 DUP(0)
HANDLE3	DW	7 DUP(0)


ASCFLG	DB	0		;used by ASAVE & read open file

FILETYPEMARK	DB	?

FNAMEBUF	DB	maxfilenamelen+6 DUP(?)

dummyname	db	' :ubdummy.$$$',0

DATA	ENDS



CODE	SEGMENT WORD PUBLIC
	ASSUME	CS:CODE,DS:DATA

;PUBLIC LABELS

	public	LLIST,LIST,dirin,ldirin
	public	roll_up,roll_down,page_up,page_down
	PUBLIC	DELETE,wait
	PUBLIC	ASAVE,SAVEIN,LOADIN,KILLIN,APPEND,LOADMP
	PUBLIC	RENUM,RENUMP
	PUBLIC	OPENIN,CLOSEIN,CLOSEALL,closeredirect
	PUBLIC	SETRWIN,RESTOREFILE,EDIT,EXTUBB
	PUBLIC	MUL3216
	PUBLIC	FREEZEIN,MELTIN
	public	fgetbytes
	public	readrecord

;EXTERNAL LABELS

	EXTRN	LABEL_TABLE:BYTE,CS_DATA:WORD
	EXTRN	NUMER?:NEAR
	EXTRN	HOTST:NEAR,MAINLP:NEAR,READY:NEAR,RESVAR:NEAR
	EXTRN	PRSPC:NEAR,PRCHR:NEAR
	EXTRN	CURSOR:NEAR,farCURSOR:near
	EXTRN	CURSON:NEAR,CURSOFF:NEAR
	extrn	clear_screen:near
	EXTRN	BEEPSUB:NEAR,farCHKCTRL_CS:far
	EXTRN	LETNL:NEAR,NL:NEAR,INPLET:NEAR
	EXTRN	PRBXSP:NEAR,PARASE:NEAR,SRCLIN:NEAR
	EXTRN	CHG2CAP:NEAR,SCROLLUP:NEAR
	extrn	SCROLLDOWN:NEAR
	extrn	setoverloadadr:near

	extrn	farCHGOUT_INIT:far,farPASSTOKEN:far,farTROFFSUB:far
	extrn	farINILOOP:far,farRESVAR:far,farBEEPSUB:far
	extrn	farPARASE:far,farget_ax:far
 	EXTRN	HEXCX:NEAR,GETPAR:NEAR
	EXTRN	farDECODE:far,farENCODE:far
	EXTRN	FORMUL:NEAR,KAKKO:NEAR,BACKSP:NEAR,farINITWP:far
	EXTRN	farREVIVESUB:far
	EXTRN	BINASC:NEAR
	EXTRN	CHGOUT_INIT:NEAR,CHGOUTINIT30:NEAR,iniloop:near
	extrn	discompilejp:near
	extrn	fardiscompileall:far
	extrn	discompilegoto:near
  if DISPFKEY
	extrn	farDISP_functionkey:near,farCLEAR_functionkey:near
  endif
	EXTRN	PRNFNAMEBUF:BYTE,LPTFNAMEBUF:BYTE
	EXTRN	EXTFNAMEBUF:BYTE,OTHERFNAMEBUF:BYTE
	extrn	freezed_sp:word
	extrn	INPFNAMEBUF:BYTE

	extrn	farSTR$ENT:far

	EXTRN	SYNERR:NEAR,DISKERR:NEAR,DISKFULL:NEAR
	EXTRN	cantdo:NEAR,NOPROG:NEAR,ILGDATA:NEAR,calcsperr:near
	EXTRN	NOLERR:NEAR,NOFILE:NEAR,AREAFULL:NEAR,TYPEERR:NEAR
	EXTRN	REOPENERR:NEAR,OPENERR:NEAR,NODATAERR:NEAR
	EXTRN	NOTOPEN:NEAR,ENDOFFILE:NEAR,EXISTERR:NEAR
	EXTRN	PROTECTED:NEAR,BIGPROG:NEAR,ILGERR:NEAR
	EXTRN	ILGFILE:NEAR,REVERSELINE:NEAR,LONGNAME:NEAR
	EXTRN	MELTERR:NEAR,CANNOTMELT:NEAR,ovrerr:near

	extrn	farCHECK_PROTECTED:far

;
; * close a file
;
closeall:
	call	far ptr farCLOSEALL
	ret

closeredirect:
	call	far ptr farCLOSEREDIRECT
	ret

closein:
	jmp	far ptr farCLOSEIN

;
; * freeze and melt
;
freezein:
	call	far ptr farFREEZEIN
	jmp	ready

meltin:
	call	far ptr farMELTIN
	jmp	ready

;
;☆ ＥＤＩＴの処理
;

EDIT:
	jmp	far ptr farEDIT

;
;☆行の削除
;
DELETE:	
	jmp	far ptr farDELETE

;
; * dir
;
LDIRIN:
	OR	[OUT_DEV],BIT1
DIRIN:
	jmp	far ptr farDIRIN

;
; * kill file
;
KILLIN:	
	jmp	far ptr farKILLIN

;
;* set
;
SETRWIN:
	cmp	byte ptr [bp],'"'
	je	gofarSETRWIN
	jmp	setoverloadadr
gofarSETRWIN:
	jmp	far ptr farSETRWIN

EXTUBB:
	CALL	far ptr farEXTUBB
	ret

farSRCLIN:
	CALL	SRCLIN
	retf

farBINASC:
	call	BINASC
	retf

DISKFREE:
	call	far ptr farDISKFREE
	ret

farDISCOMPILEgoto:
	CALL	discompilegoto
	retf

WAIT:
	call	far ptr farWAIT
	ret

farNUMER?:
	call	NUMER?
	retf

farCURSON:
	call	CURSON
	retf

farCURSOFF:
	call	CURSOFF
	retf

farINPLET:
	call	inplet
	retf

farDISCOMPILEJP:
	call	DISCOMPILEJP
	retf

ASAVE:
	jmp	far ptr farASAVE

SAVEIN:
	jmp	far ptr farSAVEIN

LOADIN:
	jmp	far ptr farLOADIN

LOADMP:
	call	far ptr farLOADMP
	ret

;
;☆ ＰＡＧＥ＿ＤＯＷＮ の処理
;
PAGE_DOWN:
	cmp	bp,codbuf
	jb	page_down_ret
	call	cursoff
	call	far ptr farpage_down
	call	curson
page_down_ret:
	ret

;
;☆ ＰＡＧＥ＿ＵＰ の処理
;
PAGE_UP:
	cmp	bp,codbuf
	jb	page_up_ret
	call	cursoff
	call	far ptr farPAGE_UP
	call	curson
page_up_ret:
	ret

;
;☆ ＲＯＬＬ＿ＤＯＷＮ の処理
;
ROLL_DOWN:
	cmp	bp,codbuf
	jb	roll_down_ret
	call	cursoff
	call	far ptr farroll_down
	syskeyclear
	call	curson
roll_down_ret:
	ret

;
;☆ ＲＯＬＬ＿ＵＰ の処理
;
ROLL_UP:
	cmp	bp,codbuf
	jb	roll_up_ret
	call	cursoff
	call	far ptr farROLL_UP
	syskeyclear
	call	curson
roll_up_ret:
	ret

farscrollup:
	call	scrollup
	retf

farscrolldown:
	call	scrolldown
	retf


;☆ＡＰＰＥＮＤ

APPEND:
	jmp	far ptr farAPPEND

;
; * read 1 byte
;	inp : bx = file number
;	    : ax = bytes to get
;	out : result on [calcsp]

fgetbytes:
	mov	cx,ax		;bytes
	add	bx,bx
	mov	ax,[bx+handle]
	cmp	ah,1
	jne	fgetbytesnotopen
	xor	ah,ah
	mov	bx,ax
	mov	ah,3fh
	mov	dx,[calcsp]
	add	dx,2
	int	21h
	mov	bx,[calcsp]
	mov	cx,ax
	inc	ax
	shr	ax,1
	jc	fgetbytes20
	or	ah,signmaskhigh
fgetbytes20:
	or	ah,stringmaskhigh
	mov	[bx],ax
	add	bx,2
	add	bx,cx
	mov	byte ptr [bx],0	;dummy end mark
	ret

fgetbytesnotopen:
	jmp	notopen


;
;☆行番号を付け替える
;
RENUM:	
	MOV	DX,10		;default new#
	MOV	CX,0		;default old#
	CALL	GETPAR
	MOV	[NEWNUM],DX
	MOV	[OLDNUM],CX
	CALL	RENUMP
	JC	RENUM10
	JMP	READY
RENUM10:
	JNZ	RENUM20
	JMP	cantdo
RENUM20:
	JMP	NOLERR


renump:
	call	far ptr farRENUMP
	ret


;
;☆ＬＬＩＳＴの処理
;

LLIST:	
	OR	[OUT_DEV],BIT1
;
;☆ＬＩＳＴの処理
;

LIST:	
	jmp	far ptr farLIST


;
;	ＵBASIC ＤISK Ｉ／Ｏ ルーチン
;

;☆ファイルのセーブ

;
;☆☆ ＳＥＱＵＥＮＴＩＡＬ ＦＩＬＥ
;

;
;☆ ＯＰＥＮ A ＦＩＬＥ
;

OPENIN:
	jmp	far ptr farOPENIN


;☆ＡＰＰＥＮＤ

AOPENIN:
	jmp	far ptr farAOPENIN


;☆ＷＲＩＴＥ

WOPENIN:
	jmp	far ptr farWOPENIN

;
;☆ 1 RECORD を DISK から読む
;	INPUT [FPOINT],[FATTR],[FADR],[FHANDLE]

READRECORD:
	call	far ptr farREADRECORD
	ret

;
;☆ 外部配列のオープン
;

EXTOPEN:
	jmp	far ptr farEXTOPEN

MUL3216:
	;DX:AX ＝ DX:AX × BX

	PUSH	CX
	MOV	CX,AX
	MOV	AX,DX
	MUL	BX
	OR	DX,DX
	JNZ	MUL3216ERR
	PUSH	AX
	MOV	AX,CX
	MUL	BX
	POP	CX
	ADD	DX,CX
MUL3216RET:
	POP	CX
	RET

MUL3216ERR:
	STC
	JMP	MUL3216RET


;
;☆ＲＥＳＴＯＲＥ ＳＥＱ＿ＦＩＬＥ
;

RESTOREFILE:
	jmp	far ptr farRESTOREFILE

CODE	ENDS



code2	segment	word public
	assume	cs:code2,ds:data,es:code

	public	farlistsub,listsubcs2,dirsub
	public	CloseHandle,farSETFNAME,farCloseall
	public	checkoldfile,setfname_time
	public	partload

	public	runmsg,farwait,dispfilename2
	public	farSeqread,farSeqwrite

;	public	readbin,writebin

	extrn	loadgetfilename:near,prchr2:near
	extrn	msg2:near,letnl2:near,nl2:near

	extrn	farFORMUL:far,farKAKKO:far,farCLEAR_SCREEN:far
	extrn	gomainlp2:near, returnadr:far

  if FLG98
	extrn	lines1msg:byte,lines2msg:byte
  endif
	extrn	farClear_below:far

  if GRAPH
    if FLGIBMTOS
	extrn	return2text:near
    endif
  endif
	include	\ubv9\frezmelt.asm


farlistsub:
	call	listsubcs2
	retf

closehandle:
	call	closehandlecs2
	retf


;
; * get and set file name in fnamebuf
;   out: file name in fnamebuf
;      : cf = 0 iff file name is assigned
;      : ah = 0 iff . is not assigned
;      : if cf =1 then di = offset of fnamebuf ( if no pass name)
;                         = next adr of pass name
filefarilgerr:
setfilg:
	jmp	far ptr ilgerr

farSETFNAME:
	call	far ptr farFORMUL
	backsp_mac
farSETFNAME2:
	mov	di,offset fnamebuf
	lodsw
	test	ah,stringmaskhigh
	jz	setfilg
	add	ax,ax
	sbb	ax,0
	and	ax,2*lenmask+1
	jz	setfnull	;di=offset fnamebuf, ah=0
	mov	cx,ax
	cmp	cx,maxfilenamelen
	jbe	setf10
setflongname:
	jmp	far ptr longname
setf10:
	xor	ah,ah		;flag of .
setf12:
	cmp	byte ptr [si],' '
	ja	setf15
	inc	si
	myloop	setf12
	jmp	setfnull	;all space
setf15:
	cmp	byte ptr [si],'.'
	jne	setflp
	mov	al,'*'
	stosb
setflp:
	lodsb
	cmp	al,'"'
	je	setf100
	cmp	al,' '
	je	setf100
	cmp	al,'.'
	jne	setf90
	dec	ah
setf90:	
	stosb
	myloop	setflp
setf100:
	or	ah,ah
	jnz	setf120		;if . is assigned
	mov	al,'.'
	stosb
setf110:
	cmp	byte ptr [di-1],"."
	jne	setfexist
	mov	al,[di-2]
	cmp	al,":"
	je	setfnull2
	cmp	al,'\'
	je	setfnull2
setfexist:
	clc
	retf		;ah<>0  iff  . is assined
setfnull2:
	dec	di
setfnull:
	mov	dx,di
	sub	dx,offset FNAMEBUF
	cmp	dx,maxfilenamelen-13
	jae	setflongname
	stc
	retf		;ah<>0  iff  . is assined
setf120:
	cmp	al,'.'
	jne	setf130
	dec	di		;if last is .
SETF130:
	mov	byte ptr [di],0	;asciz end mark
	jmp	setf110


;
;* date+time を file name にする
;
setfname_time:
;	mov	di,offset fnamebuf

	MOV	AH,2AH		;GET DATE
	INT	21H

	xor	ax,ax
	mov	al,dl		;dl=date
	mov	dl,10
	div	dl
	add	ax,3030h
	stosw

	mov	ah,2ch		;GET TIME
	int	21h

	mov	dl,10

	xor	ax,ax
	mov	al,ch		;ch=hour
	div	dl
	add	ax,3030h
	stosw

	xor	ax,ax
	mov	al,cl		;cl=minute
	div	dl
	add	ax,3030h
	stosw

	xor	ax,ax
	mov	al,dh		;dh=second
	div	dl
	add	ax,3030h
	stosw

	mov	al,'.'
	stosb

	xor	ax,ax		;must ah=0
	ret

;
;☆ ＥＤＩＴの処理
;
cantedit:
	JMP	far ptr ready

farEDIT:
  if GRAPH
    if FLGIBMTOS
	call	return2text
    endif
  endif
  	CMP	[TXTEND],TXTHED+1
	JE	cantedit		;メモリ中に PROGRAM なし
	call	far ptr farCLEAR_screen
	mov	al,[topline]
	MOV	[EDITPOS],al
	CALL	far ptr farDISCOMPILEgoto
	CALL	far ptr farPARASE
	OR	DX,DX
	JNZ	EDIT10
	MOV	DX,[EDITPTR]
EDIT10:
	MOV	[EDITPTR],DX
	MOV	AX,[TXTTOP]
	MOV	DI,INPBUF	;USE FOR HISTORY AREA

	mov	cx,word ptr [btmline]
	shr	cx,1
	sub	cx,2
	cmp	cx,2
	jae	edit18
	mov	cx,2
edit18:
	REP	STOSW

EDIT20:	
	MOV	BX,AX
	MOV	AX,[BX]
	OR	AX,AX
	JZ	EDIT30		;最後まで捜したがなかった
	CMP	DX,[BX+2]
	JBE	EDIT30		;あったか過ぎた

	MOV	DI,INPBUF
	LEA	SI,[DI+2]

	mov	cx,word ptr [btmline]
	sub	cx,word ptr [topline]
	shr	cx,1
	sub	cx,2
	cmp	cx,2
	jae	edit28
	mov	cx,2
edit28:
	dec	cx

	REP	MOVSW
	MOV	[DI],BX
	JMP	EDIT20		;次の行へ

	;NOW [INPBUF]=表示開始番地

	;一行ごとのループ
EDIT30:
	MOV	SI,INPBUF
	MOV	SI,[SI]
EDITLP:	
	LODSW
	OR	AX,AX
	JZ	EDIT100

	PUSH	AX		;NEXT TOP ADR
	MOV	CX,AX	
	MOV	AX,[SI]		;行番号
	PUSH	AX

	SUB	CX,SI		;CODBUF にコピー
	MOV	DI,CODBUF+2
	REP	MOVSB

	CALL	far ptr farDECODE	;ASCII に戻す

	POP	AX		
	CMP	AX,[EDITPTR]
	JA	EDIT40
	MOV	AL,[YPOS]
	MOV	[EDITPOS],AL
EDIT40:
	;文字数を数える

	MOV	CX,1000H
	MOV	DI,INPBUF
	XOR	AL,AL
	REPNE	SCASB
	MOV	AX,DI
	SUB	AX,INPBUF
	DEC	AX
	MOV	CL,[chars1]
	DIV	CL
	INC	AL		;AL=必要な段数
	ADD	AL,[YPOS]
	CMP	AL,[btmline]
	JAE	EDIT45		;表示するとスクロールしてしまう
	MOV	DX,INPBUF
	CALL	msg2
	CALL	LETNL2
	POP	SI
	JMP	EDITLP
EDIT45:
	ja	edit50
	MOV	DX,INPBUF
	CALL	msg2
EDIT50:
	POP	SI
EDIT100:
	MOV	AL,[EDITPOS]
	MOV	[YPOS],AL
	MOV	[XPOS],8
	CALL	far ptr farCURSOR
	JMP	far ptr HOTST



;☆行の削除

deleteSYNERR:
filefarsynerr:
	jmp	far ptr synerr

farDELETE:	

;DX=削除開始行の番号
;CX=削除終了行の番号
;のGET

	CALL	far ptr farPARASE
	JC	deleteSYNERR
	PUSH	DX
	INC	CX
	CALL	far ptr farSRCLIN
	MOV	[DELEND],BX		;top of next of last
	POP	CX
	CALL	far ptr farSRCLIN
	MOV	[DELTOP],BX		;top of start
	MOV	CX,[DELEND]
	SUB	CX,BX
	jbe	deleteSYNERR

;次の行の番号の付替(CX=OFFSET)

	PUSH	CX

	CALL	far ptr farINILOOP
	CALL	far ptr farCLOSEALL	;FILE を全て CLOSE
	call	far ptr farTroffsub
	CALL	far ptr farDiscompilejp
	CALL	far ptr farDiscompileall ;飛び先ADRなどを元に戻す

	mov	[labelend],offset label_table
	POP	CX
	MOV	BX,[DELEND]
DELLP:	
	MOV	DX,[BX]
	OR	DX,DX
	JZ	DELJP
	SUB	[BX],CX
	MOV	BX,DX
	JMPS	DELLP

;[DELTOP] から [DELEND]-1 迄削除

DELJP:	
	MOV	SI,[DELEND]
	MOV	DI,[DELTOP]
	MOV	CX,[TXTEND]
	SUB	CX,SI
	INC	CX
	REP	MOVSB
	DEC	DI
	MOV	[TXTEND],DI		;set new text end
	add	di,unitbyte
	mov	[calcsp_limit],di
	JMP	far ptr READY


;☆ファイルのＫＩＬＬ

farKILLIN:	
	CALL	far ptr farSETFNAME
	or	ah,ah
	jnz	kill4		;extension is assigned
	CMP	BYTE PTR [DI-2],'+'
	JE	KILL2
	CALL	extub2
	JMPS	KILL4
KILL2:
	DEC	DI
	MOV	BYTE PTR [DI-1],'.'
	CALL	EXTUBD

	;ＫＩＬＬを実行
KILL4:
	MOV	AH,41H		;delete file
	MOV	DX,OFFSET FNAMEBUF
	INT	21H
	JNC	KILLOUT

	CMP	AX,5
	je	killPROTECTED
	CMP	BP,TXTHED
	JAE	KILLOUT		;run mode なら file がなくても無視
	CMP	AX,2
	je	killNOFILE	;direct mode
	JMP	far ptr DISKERR
KILLOUT:
	jmp	gomainlp2

killprotected:
	jmp	far ptr protected
killnofile:
	jmp	far ptr NOFILE	
;
;☆ ＳＥＴ
;
farSETRWIN:
	CALL	far ptr farSETFNAME
	or	ah,ah
	jnz	setrw10			;extension is assigned
	CMP	BYTE PTR [DI-2],'+'
	JE	SETRW2
	CALL	extub2
	JMPS	SETRW10
SETRW2:
	DEC	DI
	MOV	BYTE PTR [DI-1],'.'
	CALL	EXTUBD

SETRW10:
	CMP	BYTE PTR [BP],0C2H	;code of ','
	JNE	SETRWSYNERR
	INC	BP

	MOV	AH,43H		;get attribute
	MOV	DX,OFFSET FNAMEBUF
	xor	al,al
	INT	21H		;cx = attribute
	JC	SETRW40
	and	cl,0feh		;reset 0-th bit

	MOV	AX,[BP]
	CMP	AL,'"'
	JNE	SETRWSYNERR
	WINC	BP
	CMP	AH,'"'
	JE	SETRW30		;SET TO R/W
	CMP	AH,' '
	JE	SETRW20		;SET TO R/W

	or	cl,1		;set 0-th bit
	CMP	AH,'P'
	JE	SETRW20		;SET TO R/ONLY
	CMP	AH,'p'
	JE	SETRW20		;SET TO R/ONLY
SETRWSYNERR:
	JMP	filefarsynerr
	
SETRW20:
	CMP	BYTE PTR [BP],'"'
	JNE	SETRWSYNERR
	INC	BP
SETRW30:
	MOV	AH,43H
	MOV	DX,OFFSET FNAMEBUF
	MOV	AL,1
	INT	21H
	JC	SETRW40
	jmp	gomainlp2

SETRW40:
	CMP	AX,5
	je	killPROTECTED
	JMP	killNOFILE


CLEARBELOW:
	MOV	es,ss:[vramsegnow]
	mov	al,ss:[ypos]
	mov	ah,ss:[chars1]
	mul	ah
	add	ax,ax
	MOV	DI,AX
	MOV	CX,ss:[btmadr]
	SUB	CX,DI
	SHR	CX,1
  if FLG98
	xor	ax,ax
	push	cx
	push	di
	rep	stosw
	pop	di
	pop	cx
	add	di,2000h
	mov	ax,ss:[tcolor]
	and	al,11100101b
	rep	stosw
  else
	mov	ax,ss:[tcolor]	;nocharacter
	rep	stosw
  endif
	smov	es,ss
	RET

CLEARABOVE:
	MOV	es,[vramsegnow]
	MOV	AL,[YPOS]
	sub	al,[topline]
	MOV	AH,[chars1]
	MUL	AH
	MOV	CX,AX
	mov	di,[topadr]
  if FLG98
	xor	ax,ax
	push	cx
	push	di
	rep	stosw
	pop	di
	pop	cx
	add	di,2000h
	mov	ax,[tcolor]
	and	al,11100101b
	rep	stosw
  else
	mov	ax,[tcolor]	;nocharacter
	rep	stosw
  endif
	smov	es,ss
	RET

LINHEXSI:
	LODSW
	XOR	AH,AH
	SUB	AL,'0'
	MOV	BX,AX
LINHSILP:	
	LODSW
	XOR	AH,AH
	SUB	AL,'0'
	CMP	AL,10
	JAE	LINHSI100

	SHL	BX,1			;BX=BX*10
	JC	LINHSIERR
	MOV	DX,BX
	SHL	BX,1
	JC	LINHSIERR
	SHL	BX,1
	JC	LINHSIERR
	ADD	BX,DX
	JC	LINHSIERR
	ADD	BX,AX
	JNC	LINHSILP

LINHSIERR:	
	STC
	RET

LINHSI100:
	WDEC	SI
	CLC
	RET

;* RENUMBER の MAIN PART
; return information
;   CF=0 alright
;   CF=1 & ZF=0 undefined line#
;   CF=1 & ZF=1 can't renumber

farRENUMP:	

	;飛び先行番号をアドレスに変換

	MOV	SI,[TXTTOP]
	CALL	RENUMCOMPIL
	JC	UNDEFL			;存在しない行を参照

	;変更開始行を捜す

	MOV	AX,[OLDNUM]
	XOR	DX,DX			;行番号用
	XOR	CX,CX			;前行番号
	MOV	DI,[TXTTOP]
PH3LP1:	
	MOV	SI,[DI]			;SI=次行の先頭アドレス
	OR	SI,SI
	JZ	cantrenum		;なかった
	MOV	DX,[DI+2]
	CMP	AX,DX
	JBE	PH3JP1			;find >=old#
	MOV	CX,DX
	MOV	DI,SI
	JMPS	PH3LP1

	;NOW	DI=変更開始行の先頭アドレス
	;	DX=変更開始行の行番号
	;	CX=一つ前の行番号
PH3JP1:	

	;新行番号が重ならないか?

	MOV	AX,[NEWNUM]
	CMP	AX,CX
	JBE	cantrenum

	;重ならねば実行

	mov	dx,ax		;memo
	mov	bx,di		;memo

	mov	cx,10		;step(fixed)
PH3LP2:				;check renumber enable?
	mov	si,[di]
	or	si,si
	jz	execPH3
;	mov	[di+2],ax	;write new line number
	add	ax,cx
	jc	cantrenum
	mov	di,si
	jmp	ph3lp2

execPH3:
	mov	ax,dx
	mov	di,bx
PH3LP3:
	mov	si,[di]
	or	si,si
	jz	PHASE4
	mov	[di+2],ax	;write new line number
	add	ax,cx
;	jc	cantrenum
	mov	di,si
	jmp	ph3lp3

PHASE4:	

	;飛び先アドレスを行番号に直して戻る

	CALL	far ptr fardiscompilegoto
	OR	AL,AL			;CF=0
	RETf

	;存在しない行を参照した時

UNDEFL:					;undefined line#
	AND	AL,-1			;ZF=0
	STC				;CF=1
	RETf

	;変換出来なかった時

cantrenum:				;if can't renumber
	XOR	AL,AL			;ZF=1
	STC				;CF=1
	RETf


;
;☆飛び先をアドレスに変換する本ルーチン
;	RENUM 用

RENUMCOMPIL:	
	MOV	[compilegoto_sw],-1	;途中で失敗してもいいように
RCPL10:	
	CMP	WORD PTR [SI],0
	JNE	RCPL20
	RET			;if end

RCPL20:
	ADD	SI,5		;pass line# & space#
RCPL30:	
	LODSB
RCPL40:
	CMP	AL,CR
	JE	RCPL10		;END OF LINE
	CMP	AL,87H		;goto
	JE	RCPLMAIN
	CMP	AL,88H		;gosub
	JE	RCPLMAIN
	CMP	AL,9DH		;restore
	JE	RCPLrestore
	CMP	AL,8EH		;THEN
	JE	RCPLMAIN
	CMP	AL,8FH		;ELSE
	JE	RCPL50
rcpl45:
	CALL	far ptr farPASSTOKEN
	JMP	RCPL30

rcplrestore:
	mov	ah,al
	lodsb
	cmp	al,'#'
	jne	rcpl60
	jmp	rcpl45


;COMPILE メイン・ルーチン

RCPL50:
	ADD	SI,2		;PASS 2 BYTES WORK

RCPLMAIN:
	MOV	AH,AL
	LODSB
rcpl60:
	CMP	AL,NCODE_ADR
	JE	RCPL80		;既にアドレスに成っている
	CMP	AL,NCODE1
	JNE	LABEL?		;行番号でない(LABEL か異常)
	MOV	CX,[SI]
	CALL	far ptr farSRCLIN
	JNZ	NOLINE		;if not exist
	ADD	BX,5
	MOV	[SI],BX
	MOV	BYTE PTR [SI-1],NCODE_ADR
RCPL80:	
	ADD	SI,2
	JMPS	RCPL30

NOLINE:
	LEA	BP,[SI-1]
	STC
	RET	

LABEL?:
	CMP	AL,NCODE_LABEL
	JE	YESLABEL
	CMP	AL,NCODE_ADR2
	JNE	?THENELSE
YESLABEL:
	XOR	AX,AX
	LODSB
	ADD	AX,2
	ADD	SI,AX
	JMP	RCPL30


?THENELSE:
	CMP	AH,8EH		;'THEN'
	JE	RCPL40
	CMP	AH,8FH		;'ELSE'
	JE	RCPL40
	JMP	NOLINE


farLIST:
  if GRAPH
    if FLGIBMTOS
	call	return2text
    endif
  endif
	CALL	far ptr fardiscompilegoto
	cmp	byte ptr [bp],0deh	;code of '-'
	je	farlist10
	CALL	far ptr farPARASE
	jmps	farlist20
farlist10:
	inc	bp
	call	far ptr farget_ax
	mov	cx,ax
	xor	dx,dx
farlist20:
	MOV	[LNEND],CX
	MOV	CX,DX
	CALL	far ptr farSRCLIN
	MOV	SI,BX

	;一行ごとのループ

LISTLP:	
	CALL	far ptr farWAIT
	CALL	far ptr farCHKCTRL_CS	;STOP OR CTRL_S のチェック
	jc	LIST_OUT

	MOV	AX,[SI+2]	;行番号
	CMP	AX,[LNEND]
	JA	LIST_READY
	call	nl2
	CALL	listsubcs2
	JNC	LISTLP

LIST_READY:
	AND	[OUT_DEV],NOTBIT1	;プリンタ・オフ
	jmp	gomainlp2

LIST_OUT:
	jmp	far ptr READY


LISTSUBcs2:
	PUSH	CX		;☆MAIN の COUNTER
	LODSW			;次アドレス
	OR	AX,AX
	JZ	LISTSUBEND	;テキストの最後
	PUSH	AX		;☆☆次アドレス

	;CODBUF にコピー

	MOV	CX,AX
	SUB	CX,SI
	MOV	DI,CODBUF+2
	REP	MOVSB

	;ASCII に戻して表示(印字)

	PUSH	BP
	CALL	far ptr farDECODE
	POP	BP
	MOV	DX,INPBUF
	CALL	msg2
	call	letnl2		;not nl because of 80chars line

	POP	SI		;☆☆次アドレス
	POP	CX		;☆MAIN の COUTER
	CLC
	RET
LISTSUBEND:
	POP	CX		;☆MAIN の COUTER
	STC
	RET


farWAIT:
	PUSH	CX
	push	dx
	MOV	CX,ss:[LISTTIMER]
waitlp:
	mov	dx,DELAYTIMER
waitlp2:
	dec	dx
	jnz	waitlp2
	myloop	WAITLP
	pop	dx
	POP	CX
	RETf

;
;☆ ＰＡＧＥ＿ＤＯＷＮ の処理
;
farPAGE_DOWN:
	CALL	ROLLINIT
	CALL	GETTOPLINE
	JC	PAGEDOWNOUT	;画面上に有効な行がない
	CALL	SRCLINBACK
	JC	PAGEDOWNOUT	;その前のテキストがない
	MOV	CX,word ptr ss:[btmline]
	sub	cx,4		;maxlines-3 行戻る
PAGEDOWN10:
	PUSH	CX
	MOV	CX,[BX+2]	;行番号
	CALL	SRCLINBACK
	POP	CX
	JC	PAGEDOWN20
	myloop	PAGEDOWN10
PAGEDOWN20:
	CALL	PDOWNSUB
PAGEDOWNOUT:
	MOV	AX,WORD PTR [EDITPOS]
	MOV	[XPOS],AL
	MOV	[YPOS],AH
	jmp	far ptr farCURSOR	;CAL & RET

PDOWNSUB:
	;BX 番地から maxlines-2 行表示

	MOV	AL,CTRL_L
	call	prchr2
	MOV	CX,word ptr [btmline]
	sub	cx,2		;maxlines-2 行表示
PDOWNSUB10:
	MOV	SI,BX
	LODSW			;次アドレス
	OR	AX,AX
	JZ	PDOWNSUBRET	;テキストの最後
	PUSH	AX		;☆
	PUSH	CX		;☆☆

	;CODBUF にコピー

	MOV	CX,AX
	SUB	CX,SI
	MOV	DI,CODBUF+2
	REP	MOVSB

	CALL	far ptr farDECODE	;ASCII に戻す

	MOV	DX,INPBUF
	CALL	msg2
	CALL	letnl2
	POP	CX		;☆☆
	POP	BX		;☆
	myloop	PDOWNSUB10
PDOWNSUBRET:
	RET

PDOWNSUB50:
	POP	CX		;☆☆
	POP	BX		;☆
	RET

;
;☆ ＰＡＧＥ＿ＵＰ の処理
;
farPAGE_UP:
	CALL	ROLLINIT
	CALL	GETLASTLINE
	JC	PAGEUPOUT	;画面上に有効な行がない
	CALL	far ptr farSRCLIN
	CALL	PUPSUB
PAGEUPOUT:
	MOV	AX,WORD PTR [EDITPOS]
	MOV	[XPOS],AL
	MOV	[YPOS],AH
	JMP	far ptr farCURSOR	;CALL & RET


PUPSUB:
	;BX 番地から表示できるだけ表示

	MOV	AL,CTRL_L
	call	prchr2
PUPSUB10:
	MOV	SI,BX
	LODSW			;次アドレス
	OR	AX,AX
	JZ	PUPSUBRET	;テキストの最後
	PUSH	AX		;☆

	;CODBUF にコピー

	MOV	CX,AX
	SUB	CX,SI
	MOV	DI,CODBUF+2
	REP	MOVSB

	;ASCII に戻す

	CALL	far ptr farDECODE

	;文字数を数える

	MOV	CX,1000H
	MOV	DI,INPBUF
	XOR	AL,AL
	REPNE	SCASB
	MOV	AX,DI
	SUB	AX,INPBUF
	DEC	AX
	MOV	CL,[chars1]
	DIV	CL
	INC	AL		;AL=必要な段数
	ADD	AL,[YPOS]
	CMP	AL,[btmline]
	JAE	PUPSUB50	;表示するとスクロールしてしまう
	MOV	DX,INPBUF
	CALL	msg2
	CALL	letnl2
	POP	BX		;☆
	JMP	PUPSUB10
PUPSUB50:
	POP	BX		;☆
PUPSUBRET:
	RET


;
;☆ ＲＯＬＬ＿ＤＯＷＮ の処理
;
farROLL_DOWN:
	CALL	ROLLINIT
	CALL	GETTOPLINE
	JC	ROLLDOWNOUT	;画面上に有効な行がない
	CALL	SRCLINBACK
	JC	ROLLDOWNOUT2	;その前のテキストがない
	MOV	AX,[BX]
	OR	AX,AX
	JZ	ROLLDOWNOUT

	MOV	[XPOS],0
	CALL	CLEARABOVE

	;そこから表示

	MOV	SI,BX
	LODSW			;次アドレス
	OR	AX,AX
	JZ	ROLLDOWNOUT	;テキストの最後

	;CODBUF にコピー

	MOV	CX,AX
	SUB	CX,SI
	MOV	DI,CODBUF+2
	REP	MOVSB

	;ASCII に戻す

	CALL	far ptr farDECODE

	;文字数を数える

	MOV	CX,1000H
	MOV	DI,INPBUF
	XOR	AL,AL
	REPNE	SCASB
	MOV	AX,DI
	SUB	AX,INPBUF
	DEC	AX
	MOV	CL,[chars1]
	DIV	CL
	inc	al		;AL=必要な段数
	mov	ah,[ypos]
	sub	[ypos],al
	sub	ah,[topline]	;ah=lines available
	cmp	ah,al
	jae	rolldown30
	sub	al,ah		;al=lines to be scrolled
	CALL	ROLLDOWNSUB	;画面のスクロールダウン
	mov	al,[topline]
	MOV	[YPOS],al
ROLLDOWN30:
	MOV	DX,INPBUF
	CALL	msg2
	CALL	letnl2

ROLLDOWNOUT:
	MOV	AX,WORD PTR [EDITPOS]
ROLLDOWNOUT10:
	MOV	[XPOS],AL
	MOV	[YPOS],AH
	JMP	far ptr farCURSOR	;CALL & RET
ROLLDOWNOUT2:
	MOV	AX,WORD PTR [EDITPOS]
	CMP	AH,[YPOS]
	JBE	ROLLDOWNOUT10
	CALL	far ptr farSCROLLDOWN
	JMP	ROLLDOWNOUT10


SRCLINBACK:
	;CX より若い行の先頭番地を BX で返す

	MOV	SI,[TXTTOP]
	MOV	BX,SI
SRCLBLP:	
	MOV	DX,[SI]
	OR	DX,DX
	JZ	SRCLBNOT	;最後まで捜したがなかった
	CMP	CX,[SI+2]
	JE	SRCLBFND	;あった
	JB	SRCLBPAST	;過ぎた
	MOV	BX,SI
	MOV	SI,DX
	JMP	SRCLBLP		;次の行へ

SRCLBPAST:
	MOV	BX,SI
SCRBYES:
	CLC
	RET

SRCLBFND:
	CMP	BX,SI
	JNE	SCRBYES		;BX=SI は先頭行
SRCLBNOT:			;全ての行番号が CX より若い
	STC
	RET	
	

ROLLDOWNSUB:
  if FLG98
	mov	ah,[chars1]
	mul	ah
	add	ax,ax
	mov	dx,ax		;消す BYTE 数

	mov	ax,[vramsegnow]
	mov	ds,ax
	mov	es,ax
	STD
	mov	di,ss:[btmadr]
	mov	cx,di
	sub	di,2
	mov	si,di
	sub	si,dx
	sub	cx,dx
	sub	cx,ss:[topadr]
	shr	cx,1
	push	cx
	push	si
	push	di
	REP	MOVSW
	xor	ax,ax		;nocharacter
	MOV	CX,dx
	SHR	CX,1
	REP	STOSW
	pop	di
	pop	si
	pop	cx
	add	si,2000h
	add	di,2000h
	rep	movsw
	mov	ax,ss:[tcolor]
	and	al,11100101b
	mov	cx,dx
	shr	cx,1
	rep	stosw
	CLD
	smov	ds,ss
	smov	es,ss
	RET
  endif

  if FLGFMR
	push	ax		;al = scroll offset

	;scroll down display

	xor	cx,cx
	mov	cl,al
	mov	ax,1a01h
	mov	dh,[topline]
	inc	dh
	mov	dl,1
	mov	bh,[btmline]
	mov	bl,[chars1]
	int	91h

	;scroll down vvram

	pop	ax
	mov	ah,[chars1]
	mul	ah
	add	ax,ax
	mov	dx,ax		;消す BYTE 数

	mov	ax,[vramsegnow]
	mov	ds,ax
	mov	es,ax
	STD
	mov	di,ss:[btmadr]
	mov	cx,di
	sub	di,2
	mov	si,di
	sub	si,dx
	sub	cx,dx
	sub	cx,ss:[topadr]
	shr	cx,1
	rep	movsw
	mov	ax,ss:[tcolor]		;nocharacter
	mov	cx,dx
	shr	cx,1
	add	dx,cx
	rep	stosw
	CLD
	smov	ds,ss
	smov	es,ss
	RET
  endif

  if FLGIBMTOS
	push	ax		;al=line distance

	mov	ch,[topline]
	xor	cl,cl
	mov	dh,[btmline]
	dec	dh
	mov	dl,[chars1]
	dec	dl
	mov	bx,[tcolor]
	mov	ah,7
	int	10h		;slide down display

	mov	al,[btmline]
	sub	al,[topline]

	mov	di,[btmadr]
	sub	di,2		;right bottom
	mov	si,di

	mov	ax,[vramsegnow]
	mov	ds,ax
	mov	es,ax

	pop	ax

	mov	ah,ss:[chars1]
	mul	ah
	push	ax		;*char distance

	add	ax,ax
	sub	si,ax
	jb	rolldsub20
	mov	cx,si
	sub	cx,ss:[topadr]
	jb	rolldsub20
	shr	cx,1
	inc	cx
	std
	rep	movsw
	cld	
rolldsub20:
	pop	cx		;*
	mov	di,ss:[topadr]
	mov	ax,ss:[tcolor]	;nocharacter
	rep	stosw

	smov	ds,ss
	smov	es,ss
	ret
  endif



GETTOPLINE:
	MOV	AX,ss:[vramsegnow]
	MOV	DS,AX
	MOV	ES,AX

	;最初の NON 0 ,NON SPACE を捜す

	MOV	CX,ss:[charsallnow]
	mov	si,ss:[topadr]		;	XOR	SI,SI
GETTLIN5:
	LODSW
	OR	AL,AL
	JZ	GETTLIN7
	CMP	AL,' '
	JNE	GETTLIN10
GETTLIN7:
	myloop	GETTLIN5

GETTLINNOT:
	STC
GETTLINRET:
	smov	ds,ss
	smov	es,ss
	RET			;行がない

GETTLIN10:
	SUB	SI,2
	mov	ax,si
	shr	ax,1
	mov	dx,word ptr ss:[chars1]
	div	dl
	mov	dl,ah
	shl	dx,1
	xor	ah,ah
	mov	cx,ax

	;NOW AX=CX=YPOS

	SUB	SI,DX		;SI=TOP OF YPOS
	MOV	DI,SI
GETTLIN20:
	CMP	DI,ss:[btmadr]
	JAE	GETTLINNOT
	MOV	SI,DI		;NOW SI=DI=行の先頭
	CALL	SKIPSPSI
	CALL	far ptr farNUMER?
	JNZ	GETTLIN50
	CALL	LINHEXSI
	JC	GETTLIN50	;行番号が大き過ぎる
	MOV	CX,BX		;NOW CX=BX=行番号
	MOV	AX,DI
	shr	ax,1
	mov	bl,ss:[chars1]
	div	bl
	MOV	SS:[YPOS],AL
	CALL	SKIPSPSI	;SI は LINHEXSI で更新されている
	SUB	SI,DI
	CMP	SI,ss:[chars2]
	JB	GETTLIN40
	INC	SS:[YPOS]	;行番号だけの行
	INC	CX		;その行も表示するため
GETTLIN40:	
	CLC
	JMP	GETTLINRET

GETTLIN50:
	ADD	DI,ss:[chars2]
	JMP	GETTLIN20



ROLLINIT:
	CALL	far ptr fardiscompilegoto
	MOV	AL,[XPOS]
	MOV	AH,[YPOS]
	MOV	WORD PTR [EDITPOS],AX
	RET


;
;☆ ＲＯＬＬ＿ＵＰ の処理
;
farROLL_UP:
	CALL	ROLLINIT
	CALL	GETLASTLINE
	JC	ROLLUPOUT	;画面上に有効な行がない
	CALL	far ptr farSRCLIN
	MOV	DX,[BX]
	OR	DX,DX
	JZ	ROLLUPOUT	;TEXT の終り(行番号が大きすぎた)
	MOV	ss:[XPOS],0
	push	bx
  if flg98
	call	CLEARBELOW
  else
	call	far ptr farCLEAR_BELOW
	call	far ptr farCURSOR
  endif
	pop	bx

	;そこから表示

	MOV	SI,BX
	MOV	CX,2
ROLLUP30:
	call	nl2
	CALL	listsubcs2
	JC	ROLLUPOUT2	;最後の行を表示した
	myloop	ROLLUP30
ROLLUPOUT:
	MOV	AX,WORD PTR [EDITPOS]
	MOV	[XPOS],AL
	MOV	[YPOS],AH
	JMP	far ptr farCURSOR	;CALL & RET
ROLLUPOUT2:
	MOV	AX,WORD PTR [EDITPOS]
	INC	AH
	CMP	AH,[YPOS]
	JAE	ROLLUPOUT
	CALL	far ptr farSCROLLUP
	JMP	ROLLUPOUT

GETLASTLINE:
	MOV	AX,ss:[vramsegnow]
	MOV	DS,AX
	MOV	ES,AX

	;最後の NON 0 を捜す

	mov	si,ss:[btmadr]
	sub	si,2
	mov	cx,ss:[charsallnow]
	std
getlastlinelp:
	lodsw
	or	al,al		;nochar?
	jnz	getllin10
	myloop	getlastlinelp
	cld
GETLLINNOT:
	STC
GETLLINRET:
	smov	ds,ss
	smov	es,ss
	RET			;行がない

GETLLIN10:
	cld
	lea	di,[si+2]
	mov	ax,di
	shr	ax,1
	mov	dx,word ptr ss:[chars1]
	div	dl
	mov	dl,ah
	shl	dx,1
	xor	ah,ah
	mov	cx,ax

	;NOW AX=CX=YPOS

	sub	di,dx	;DI=TOP OF YPOS
GETLLIN20:
	SUB	DI,2
	JB	GETLLIN40

	;行の先頭を捜す

	xor	al,al
GETLLIN30:
	CMP	al,[DI]
	JE	GETLLIN40
	sub	di,ss:[chars2]
	cmp	di,ss:[topadr]
	jge	getllin30	;	JNB	GETLLIN30
GETLLIN40:
	ADD	DI,2
	MOV	SI,DI		;NOW SI=DI=行の先頭
	CALL	SKIPSPSI
	CALL	far ptr farNUMER?
	JNZ	GETLLIN50
	CALL	LINHEXSI
	JC	GETLLIN50	;行番号が大き過ぎる
	MOV	CX,BX		;NOW CX=BX=行番号
	MOV	AX,DI
	shr	ax,1
	mov	bl,ss:[chars1]
	div	bl
	MOV	SS:[YPOS],AL
	CLC
	JMP	GETLLINRET

GETLLIN50:
	SUB	DI,ss:[chars2]
	JNB	GETLLIN20
	JMP	GETLLINNOT


SKIPSPSI:
	LODSW
	CMP	AL,' '
	JE	SKIPSPSI
	OR	AL,AL
	JZ	SKIPSPSI
	WDEC	SI
	RET



;☆ＡＳＡＶＥ

farASAVE:	
	MOV	AL,-1
	JMP	SAVE10


;☆ＳＡＶＥ

farSAVEIN:	
	XOR	AL,AL
SAVE10:
	MOV	[ASCFLG],AL
	CMP	[TXTEND],TXTHED+1
	JE	DONTSAVE	;メモリ中に PROGRAM なし

	mov	di,offset fnamebuf
;	cmp	byte ptr [bp],'"'
;	jne	save11
	CALL	far ptr farSETFNAME	;PATH名を作る
	jnc	save12
save11:
	call	setfname_time
save12:
	or	ah,ah
	jz	save14		;no extension

	mov	di,offset fnamebuf	;check ext is 'ub'?
	mov	al,'.'
	mov	cx,100
	repne	scasb
	mov	ax,[di]
	or	ax,2020h
	cmp	ax,'b'*256+'u'
	jne	savesynerr		;if not 'ub'
	cmp	byte ptr [di+2],0
	jne	savesynerr		;if not 'ub'
	jmps	save15
save14:
	CALL	extub2		;EXTENSION を UB に
save15:
	CMP	BYTE PTR [BP],0C2H	;','
	JNE	SAVE20
	INC	BP
	CMP	BYTE PTR [BP],'"'
	JNE	SAVESYNERR
	INC	BP
	mov	al,[bp]
	or	al,20h
	cmp	al,"a"
	jne	savesynerr
	inc	bp
	CMP	BYTE PTR [BP],'"'
	JNE	SAVESYNERR
	INC	BP		
	MOV	[ASCFLG],-1
SAVE20:
	call	far ptr fardiscompileall
				;do not 'discompilejp' for CONT.
	CALL	SAVEMP
	JC	CANTSAVE
	JMP	far ptr READY

DONTSAVE:
	JMP	far ptr NOPROG
CANTSAVE:
	JMP	far ptr DISKERR
SAVESYNERR:
	JMP	filefarsynerr


checkoldfile:
	;ファイルのOPEN

	MOV	AH,3DH		;OPEN HANDLE
	MOV	AL,1		;FOR WRITE
	MOV	DX,OFFSET FNAMEBUF
	INT	21H

	JNC	OVERWRITE?	;あったら警告

checkoldfile5:
	MOV	AH,3CH		;create HANDLE
	MOV	DX,OFFSET FNAMEBUF
	MOV	CX,0
	INT	21H
	JC	SAVEERR2
	MOV	[HANDLE],AX
	clc
	ret

SAVEERR2:
	call	CloseHandlecs2
	JMP	far ptr PROTECTED	


	;ファイルが既にあった場合はメッセージを出す

OVERWRITE?:
	MOV	[HANDLE],AX
  if FLG98
	call	CloseHandlecs2
  endif
	CALL	far ptr farCURSON

 	MOV	DX,OFFSET OVRWRTMSG
	CALL	MSG_CS2
	call	far ptr farCURSOR
ovrwrtlp:
	MOV	AH,7
	INT	21H
	AND	AL,11011111B
	cmp	al,'N'
	JE	NOTSAVED	;書き込み中止
	CMP	AL,'Y'
	je	gosave
	call	far ptr farBEEPSUB
	jmp	ovrwrtlp
gosave:
	call	prchr2
	CALL	far ptr farCURSOFF
	CALL	NL2

	jmps	checkoldfile5


NOTSAVED:
	call	prchr2
	MOV	DX,OFFSET DIDNOTMSG
	CALL	MSG_CS2
	stc
	ret

  if JAPANESE
OVRWRTMSG	DB	'書き換えますか?(Y/N)   ',CTRL_S,CTRL_S,0
DIDNOTMSG	DB	CR,LF,'中止しました。',0
  else
OVRWRTMSG	DB	'Rewrite?(Y/N)   ',CTRL_S,CTRL_S,0
DIDNOTMSG	DB	CR,LF,'Canceled.',0
  endif

;
; * main part of text save
;

SAVEMP:	
	call	checkoldfile
	jnc	savempin
	jmp	gomainlp2

savempin:
	TEST	BYTE PTR [ASCFLG],-1
	JNZ	saveasc10

	MOV	SI,TXTHED
	MOV	CX,[TXTEND]
	INC	CX
	SUB	CX,SI		;最後の 0000H を含める
	MOV	[ASCPTR],CX	;SIZE

	;reset next adr's

	MOV	SI,TXTHED
	MOV	DI,SI
SAVEM12:
	MOV	AX,[SI]
	OR	AX,AX
	JZ	SAVEM14
	SUB	[SI],DI
	MOV	SI,AX
	JMP	SAVEM12
SAVEM14:
	MOV	BX,[HANDLE]
	MOV	CX,[ASCPTR]
	push	cx		;*1
	mov	dx,txthed	;pointer of buffer
	MOV	AH,40H		;WRITE HANDLE
	INT	21H
	pushf			;*2
	push	ax		;*3
	jc	savem16

	;decide file size

	mov	ah,40h
	xor	cx,cx
	int	21h

	;recover next adr's
savem16:
	MOV	SI,TXTHED
	MOV	DI,SI
SAVEM22:
	MOV	AX,[SI]
	OR	AX,AX
	JZ	SAVEM24
	ADD	AX,DI
	MOV	[SI],AX
	MOV	SI,AX
	JMP	SAVEM22
SAVEM24:
	pop	ax		;3*
	popf			;2*
	pop	cx		;1*
	JC	SAVEERR1	;書込失敗
	CMP	AX,CX
	JB	SAVEERR3	;DISKFULL
	JMP	SAVEMRET

saveasc10:
	mov	si,txthed
saveasc20:
	LODSW			;次アドレス
	OR	AX,AX
	JZ	savemret	;テキストの最後
	PUSH	AX		;* 次アドレス

	;CODBUF にコピー

	MOV	CX,AX
	SUB	CX,SI
	MOV	DI,CODBUF+2
	REP	MOVSB

	;ASCII に戻して表示(印字)

	PUSH	BP
	CALL	far ptr farDECODE
	POP	BP
	mov	si,inpbuf
	MOV	DX,si

	xor	cx,cx		;count chars
saveasc40:
	inc	cx
	lodsb
	or	al,al
	jnz	saveasc40
	inc	cx
	mov	word ptr [si-1],0a0dh

	MOV	BX,SS:[HANDLE]
	MOV	AH,40H		;WRITE HANDLE
	INT	21H
	JC	SAVEERR1	;書込失敗
	CMP	AX,CX
	JB	SAVEERR3	;DISKFULL

	POP	SI		;* 次アドレス
	jmp	saveasc20

savemret:
	CALL	CloseHandlecs2
	CLC
	RET	

	;エラーなのでファイルをクローズして戻る

SAVEERR1:
	call	CloseHandlecs2
	JMP	far ptr DISKERR	;DISK NOT READY

SAVEERR3:
	call	CloseHandlecs2
	JMP	far ptr DiskFULL


	;HANDLE をＣＬＯＳＥ

CloseHandlecs2:	
	push	ax
	push	bx

	mov	ah,0dh		;flush buffer
	int	21h

	MOV	AH,3EH
	MOV	BX,ss:[HANDLE]
	or	bx,bx
	jz	closenot
	INT	21H
	MOV	ss:[HANDLE],0
	jc	closeherr
closenot:
	pop	bx
	pop	ax
	RET

closeherr:
	jmp	far ptr diskerr



;☆ＬＯＡＤ

farLOADIN:
  if GRAPH
    if FLGIBMTOS
	call	return2text
	call	far ptr farcursoff
    endif
  endif
	call	pregetfilename2

	call	far ptr fardiscompileall	;for revive
	MOV	[EDITPTR],0

	mov	[labelend],offset label_table

	MOV	SI,TXTHED
	MOV	[TXTTOP],SI
	MOV	[ENDMEM],SI

	mov	dx,offset loadmsg
	CALL	far ptr farLOADMP
	JC	CANTLOAD
	call	afterload
cancelload:
	JMP	far ptr READY

afterload:
	call	far ptr farcloseall
	CALL	far ptr farCHGOUT_INIT
	CALL	far ptr farINITWP		;WORD POINT の初期化
	call	far ptr fartroffsub
	CALL	far ptr farINILOOP
	CALL	far ptr fardiscompilegoto ;飛び先ADRなどを元に戻す
	CALL	far ptr farRESVAR
	MOV	AX,[ENDMEM]
	MOV	[TXTEND],AX
	add	ax,unitbyte
	mov	[calcsp_limit],ax
	mov	[compilejp_sw],-1
	call	far ptr fardiscompilejp
	ret

CANTLOAD:
	cmp	ah,5
	je	cancelload
	CMP	AH,4
	JE	PARTLOAD	;途中までは有効
	MOV	BX,TXTHED
	MOV	WORD PTR SS:[BX],0
	INC	BX
	MOV	SS:[TXTEND],BX
	add	bx,unitbyte
	mov	ss:[calcsp_limit],bx

CANTLOADOUT:
	dec	ah
	jz	GO_NOFILE
	dec	ah
	jz	go_DISKERR
	dec	ah
	jz	go_BIGPROG
	dec	ah
	jz	far ptr REVERSELINE
	dec	ah
	jz	cancelload
;	cmp	ah,6
	jmp	far ptr cantdo

GO_NOFILE:
	CALL	far ptr farREVIVESUB
	JMP	far ptr NOFILE
go_diskerr:
	jmp	far ptr diskerr
go_bigprog:
	jmp	far ptr bigprog

PARTLOAD:			;APPEND 時はこうしない
	mov	ax,ss
	mov	ds,ax
	mov	es,ax

	mov	bx,[ENDMEM]
	mov	word ptr [bx],0
	inc	bx
	mov	[ENDMEM],bx
	call	afterload
	JMP	far ptr REVERSELINE


runmsg		db	'run ',0
loadmsg		db	'load ',0
appendmsg	db	'append ',0

loaderr5:
	pop	dx		;dummy
	stc
	retf


pregetfilename2:
	cmp	byte ptr [BP],CR
	je	pregetnoname
	call	far ptr farFORMUL
	backsp_mac
	ret
pregetnoname:
	call	ahedsp2
	mov	word ptr [si],0800h
	backsp_mac
	ret

farLOADMP:	
	push	dx			;* dx= load,append or run
	mov	si,[calcsp]
	sub	si,unitbyte
	cmp	word ptr [si],0
	je	farloadmpmenu
	CALL	far ptr farSETFNAME2	;PATH 名を得る
	jnc	farloadmpnomenu

farloadmpmenu:
	call	loadgetfilename
	jc	loaderr5
	CALL	extub2		;EXTENSION を UB に
	pop	dx			;*
	call	msg_cs2
	call	dispfilename2
	call	letnl2

	MOV	AH,3DH		;OPEN HANDLE
	MOV	AL,0		;FOR READ
	MOV	DX,OFFSET FNAMEBUF
	INT	21H
	jnc	farloadmp40
goloaderr1:
	JMP	LOADERR1	;can't open

farloadmpnomenu:
	push	di			;**
	or	ah,ah
	jnz	farloadmp10
	CALL	extub2		;EXTENSION を UB に
	jmps	farloadmp20
farloadmp10:
	mov	di,offset fnamebuf
	mov	cx,63555
	mov	al,'.'
	repne	scasb
	mov	ax,[di]
	or	ax,2020h
	cmp	ax,'bu'
	jne	farloadsynerr
	mov	al,[di+2]
	or	al,al
	jz	farloadmp20
farloadsynerr:
	jmp	filefarsynerr

farloadmp20:
	MOV	AH,3DH		;OPEN HANDLE
	MOV	AL,0		;FOR READ
	MOV	DX,OFFSET FNAMEBUF
	INT	21H
	pop	si			;**
	pop	dx			;* dummy
	jnc	farloadmp40

	mov	cx,si
	sub	cx,offset fnamebuf
	std
farloadmp30:
	lodsb
	cmp	al,'\'
	je	farloadmp35
	cmp	al,':'
	je	farloadmp35
	myloop	farloadmp30
	mov	si,offset fnamebuf-2	;-2 is dummy for add 2
farloadmp35:
	lea	di,[si+2]
	cld
	push	dx			;*
	jmp	farloadmpmenu


farloadmp40:

	MOV	[HANDLE],AX

	;SEQUENTIAL な読み込み

	MOV	AH,3FH		;read
	MOV	BX,[HANDLE]
	MOV	CX,0FFF0H
	mov	dx,ss
	add	dx,textconvseg
	MOV	DS,DX
	XOR	DX,DX	
	INT	21H
	smov	ds,ss
	JMPC	LOADERR2

	CMP	AX,0FF00H
	JMPNC	LOADERR3	;ファイルが大き過ぎる

	MOV	SI,AX
	CALL	CloseHandlecs2

	;終端の調整

	mov	ax,ss
	add	ax,textconvseg
	MOV	DS,AX
	CMP	BYTE PTR [SI-1],0
	JNE	LOADMP5		;ASCII TEXT

	;BINARY TEXT の場合

	MOV	AX,SI
	MOV	DI,SS:[ENDMEM]
	ADD	AX,DI
	JC	BLOADERR
	CMP	AX,TXTLIM+1
	JA	BLOADERR
	MOV	CX,SI		;SIZE

	;ADDRESS の付け変え
	XOR	SI,SI
BLOAD10:
	MOV	AX,[SI]
	OR	AX,AX
	JZ	BLOAD20
	MOV	BX,AX
	ADD	AX,DI
	MOV	[SI],AX
	MOV	SI,BX
	JMP	BLOAD10

BLOAD20:
	smov	es,ss
	XOR	SI,SI
	REP	MOVSB
	smov	ds,ss

	DEC	DI		;二つ目の0の位置
	MOV	[ENDMEM],DI

	CLC
	RETf

BLOADERR:
	MOV	AH,3		;BIG FILE
	STC
	RETf

	;ASCII TEXT の場合

LOADMP5:
	DEC	SI
	CMP	BYTE PTR [SI],' '
	JB	LOADMP5
	INC	SI
	MOV	BYTE PTR [SI],CR
	MOV	BYTE PTR [SI+1],LF
	MOV	BYTE PTR [SI+2],CTRL_Z

	;一行毎に翻訳し格納

	MOV	SS:[ASCPTR],0
	MOV	SS:[PRENUMBER],0	;前の行番号

	;INPBUF へ転送

LOADMP_ASCLP:	
	mov	ax,ss
	add	ax,textconvseg
	MOV	DS,AX
	MOV	SI,SS:[ASCPTR]
	MOV	DI,INPBUF
LOADMP20:
	LODSB	
	STOSB
	CMP	AL,CTRL_Z
	JE	LOADMP100	;END OF FILE
	cmp	al,LF
	jne	loadmp22
	mov	byte ptr es:[di-1],CR	;if UNIX file
	jmps	loadmp24
loadmp22:
	CMP	AL,CR
	JNE	LOADMP20
	INC	SI		;PASS LF
loadmp24:
	MOV	SS:[ASCPTR],SI
	smov	ds,ss

	;中間コードに翻訳

	CALL	far ptr farENCODE
		
	;テキスト・エリアに格納

	MOV	SI,CODBUF
	MOV	DI,[ENDMEM]
	MOV	AX,[SI+2]
	CMP	AX,[PRENUMBER]
	JBE	NUMBERERR	;行番号の逆転
	MOV	[PRENUMBER],AX
	MOV	CX,[INPUTLEN]
	CMP	CX,5
	JE	LOADMP_ASCLP	;行番号だけなら何もせず

	;余裕があるか

	MOV	AX,[ENDMEM]
	ADD	AX,CX
	JC	LOADERR3
	CMP	AX,TXTLIM-1
	JA	LOADERR3

	;追加する

	MOV	[SI],AX		;次アドレス
	REP	MOVSB
	MOV	[ENDMEM],DI
	JMP	LOADMP_ASCLP

LOADMP100:
	smov	ds,ss
	MOV	SI,[ENDMEM]
	MOV	WORD PTR [SI],0
	INC	SI
	MOV	[ENDMEM],SI
	CLC
	RETf

LOADERR1:
	CMP	AX,2
	JNE	LOADERR2
	MOV	AH,1		;ファイルなし
	STC
	RETf

LOADERR2:
	MOV	AH,2		;DISK 不良
	STC
	RETf

LOADERR3:
	MOV	AH,3		;BIG FILE
	STC
	RETf

NUMBERERR:			;行番号の逆転
	MOV	AH,4
	STC
	RETf


msg_cs2:
	push	ds
	smov	ds,cs
	CALL	msg2
	pop	ds
	ret

dispfilename2:
	mov	al,'"'
	call	prchr2
	mov	si,offset fnamebuf
dispf100:
	lodsb
	or	al,al
	jz	dispf110
	call	prchr2
	jmp	dispf100
dispf110:
	mov	al,'"'
	call	prchr2
	ret


EXTUB2:
	MOV	AX,'BU'
	STOSW
	XOR	AX,AX
	STOSW
	RET

EXTUBD:
	MOV	AX,'BU'
	STOSW
	MOV	AL,'D'
	XOR	AH,AH
	STOSW
	RET

farEXTUBB:
	MOV	AX,'BU'
	STOSW
	MOV	AL,'B'
	XOR	AH,AH
	STOSW
	RETf


;* apeend

farAPPEND:
	call	pregetfilename2

	call	far ptr fardiscompileall	;for revive
	call	far ptr fartroffsub
	CALL	far ptr farINILOOP
	CALL	far ptr farRESVAR
	mov	[labelend],offset label_table

	MOV	SI,TXTHED
	MOV	CX,0		;will be last line#
APPLP1:	
	;現在あるテキストの最後を捜す

	MOV	AX,[SI]
	OR	AX,AX
	JZ	APPJP1
	MOV	CX,[SI+2]	;行番号
	MOV	SI,AX
	JMPS	APPLP1
APPJP1:	
	MOV	[LASTLN],CX	;last line#

	;SI から後ろに新テキストを置く

	MOV	[TXTTOP],SI
	MOV	[ENDMEM],SI

	mov	dx,offset appendmsg
	CALL	far ptr farLOADMP
	jc	appenderror

	mov	[compilejp_sw],-1
	call	far ptr fardiscompilejp

	;新旧行番号を比較

	MOV	SI,[TXTTOP]
	MOV	AX,[SI+2]		;AX=first new line#
	CMP	AX,[LASTLN]		;SI=last old line#
	JA	APPEND10	

	;重なっていれば付替

	CALL	autorenum
	jc	appenderror

	;テキストの先頭終了を書き換え

APPEND10:
	MOV	AX,[ENDMEM]
	MOV	[TXTEND],AX
	add	ax,unitbyte
	mov	[calcsp_limit],ax
	mov	si,[txttop]
	mov	ax,[si+2]
	mov	[editptr],ax
	MOV	AX,TXTHED
	MOV	[TXTTOP],AX

	JMP	far ptr READY


appenderror:				;if can't append

;ロード出来ない時は保存したものを復帰
;ここにはロード・ミス、リナンバー不可能、キャンセルの時に来る

	MOV	SI,SS:[TXTEND]
	MOV	WORD PTR SS:[SI-1],0
	MOV	SS:[TXTTOP],TXTHED
	JMP	CANTLOADOUT

;行番号の付替

autorenum:	
	MOV	AX,[LASTLN]
	ADD	AX,1000			;1000 のギャップを置く
	JC	autorenerror
	MOV	[NEWNUM],AX
	MOV	[OLDNUM],0
	CALL	far ptr farRENUMP
	JC	autorenerror
	RET
autorenerror:
	mov	ah,6
	stc
	ret

;
; * close
;
CLOSEFILE:
	INC	BP
	MOV	AL,[BP]
	MOV	SI,OFFSET HANDLE1
	CMP	AL,0D5H
	JE	CLOSEFILE10
	MOV	SI,OFFSET HANDLE2
	CMP	AL,0D7H
	JE	CLOSEFILE10
	MOV	SI,OFFSET HANDLE3
	CMP	AL,0D9H
	JE	closefile10
	jmp	filefarsynerr
CLOSEFILE10:
	MOV	BX,[SI]
	OR	BX,BX
	JZ	CLOSEFILE20
	MOV	WORD PTR [SI],0
	MOV	AH,3EH
	INT	21H
CLOSEFILE20:
	INC	BP
	jmp	closeend

	
farCLOSEIN:
	MOV	AL,[BP]
	CMP	AL,CR
	JE	CLOSEALLIN	;全て CLOSE
	CMP	AL,0C0H		;CODE OF ':'
	JE	CLOSEALLIN	;全て CLOSE
closelp:
	CMP	AL,80H
	JE	CLOSEFILE
	CMP	AL,'#'
	JNE	CLOSEERR
	INC	BP
	CMP	BYTE PTR [BP],NCODE1
	JNE	CLOSEERR
	INC	BP
	MOV	AX,[BP]
	WINC	BP
	CMP	AX,MAXFILE
	JA	CLOSEERR
	add	ax,ax
	MOV	BX,OFFSET HANDLE
	ADD	BX,AX
	MOV	SI,BX		;MEMO IT
	MOV	BX,[BX]
	XOR	BH,BH
	OR	BX,BX
	JZ	CLOSEend	;not opened
	MOV	AH,3EH		;CLOSE HANDLE
	INT	21H
	MOV	WORD PTR [SI],0
CLOSEend:
	CMP	BYTE PTR [BP],0C2H	;code of ','
	jne	closeret
	inc	bp
	mov	al,[bp]
	jmp	closelp

closeret:
	jmp	gomainlp2		


CLOSEERR:
	JMP	filefarsynerr

CLOSEALLIN:
	CALL	far ptr farCLOSEALL
	jmp	gomainlp2


farCLOSEALL:
	mov	ah,0dh		;flush buffer
	int	21h

	MOV	SI,OFFSET HANDLE
	MOV	CX,MAXFILE+1
CLOSEALL10:
	LODSW
	OR	AX,AX
	JZ	CLOSEALL20
	MOV	BX,AX
	XOR	BH,BH
	MOV	AH,3EH
	INT	21H
	XOR	AX,AX
	MOV	[SI-2],AX
CLOSEALL20:
	myloop	CLOSEALL10

	MOV	CX,3
	MOV	SI,OFFSET HANDLE1
CLOSEALL25:
	MOV	BX,[SI]
	OR	BX,BX
	JZ	CLOSEALL30
	MOV	AH,3EH
	INT	21H
	MOV	WORD PTR [SI],0
CLOSEALL30:
	ADD	SI,OFFSET HANDLE2-OFFSET HANDLE1
	myloop	CLOSEALL25
	RETf


farcloseredirect:
	MOV	CX,3
	MOV	SI,OFFSET prnhandle
CLOSEred45:
	MOV	BX,[SI]
	OR	BX,BX
	JZ	CLOSEred50
	MOV	AH,3EH
	INT	21H
	MOV	WORD PTR [SI],0
CLOSEred50:
	add	si,2
	myloop	CLOSEred45
	retf


;
;* open file
;
checkUBD:				;ah = 0 iff .UBD
	mov	di,offset fnamebuf
	mov	cx,fnamelen
	mov	al,'.'
	repne	scasb
	mov	ah,0ffh
	mov	ax,es:[di]
	or	ax,2020h
	cmp	ax,'bu'
	jne	checkUBDret		;ascii
	mov	al,es:[di+2]
	or	al,20h
	cmp	al,'d'
	jne	checkUBDret
	xor	ah,ah			;ascii
checkUBDret:
	ret


farOPENIN:
	CALL	far ptr farSETFNAME	;PASS名を得る
	jc	opensynerr
	mov	[ascflg],ah		;<>0  is  ascii file
	or	ah,ah
	jz	faropen5		;if non-ascii
	call	checkUBD
	mov	[ascflg],ah
	jmps	faropen10		;if 
faropen5:
	CALL	EXTUBD			;UBD を付加
faropen10:
	CMP	BYTE PTR [BP],89H	;CODE OF FOR
	JNE	EXTOPEN?
	INC	BP
	CMP	BYTE PTR [BP],0A7H	;CODE OF INPUT
	JMPZ	farROPENIN		;JUMP TO READ OPEN
	CMP	[BP],9380H	;CODE OF OUTPUT
	JMPZ	farWOPENIN
	cmp	[bp],95b2h	;code of create
	jmpz	farCOPENIN
	CMP	[BP],9180H	;CODE OF APPEND
	JNE	OPENSYNERR
	JMP	farAOPENIN

EXTOPEN?:
	CMP	[BP],9480H	;CODE OF AS
	JNE	OPENSYNERR
	WINC	BP
	JMP	farEXTOPEN	;外部配列のオープン

OPENSYNERR:
	JMP	filefarsynerr
openilgerr:
	jmp	filefarilgerr

CHECKAS:
	CMP	[BP],9480H	;CODE OF AS
	JNE	OPENSYNERR
	WINC	BP
	RET

CHECKREOPEN:
	MOV	BX,[FILENO]
	SHL	BX,1
	CMP	WORD PTR [BX+HANDLE],0
	JNE	OPENMISS	;ALREADY OPENED
	RET

OPENMISS:
	JMP	far ptr REOPENERR

GETFILENO:
	CMP	BYTE PTR [BP],'#'
	JNE	OPENSYNERR
	INC	BP
	CMP	BYTE PTR [BP],NCODE1
	JNE	OPENILGERR
	INC	BP
	MOV	AX,[BP]
	WINC	BP
	CMP	AX,MAXFILE
	JA	OPENILGERR
	MOV	[FILENO],AX
	RET


;* append

farAOPENIN:
	WINC	BP
	CALL	CHECKAS
	CALL	GETFILENO	;FILE NUMBER を GET
	CALL	CHECKREOPEN
	call	far ptr farCHECK_PROTECTED

	;OPEN FOR R/W

	MOV	AH,3DH		;OPEN HANDLE
	MOV	AL,2
	MOV	DX,OFFSET FNAMEBUF
	INT	21H	
	JC	WOPEN10		;ファイルがない

	PUSH	AX		;☆HANDLE
	MOV	BX,[FILENO]
	SHL	BX,1

	MOV	AH,2		;FLAG FOR WRITE
	MOV	[BX+HANDLE],AX
	mov	[bx+ptword],0	;0 means ascii file

	;FILE NAME をメモ

	my_SHL	BX,4
	ADD	BX,OFFSET OTHERFNAMEBUF
	mov	ax,code
	mov	es,ax
	MOV	DI,BX
	MOV	SI,OFFSET FNAMEBUF
	MOV	CX,fnamewordlen
	REP	MOVSW
	smov	es,ss

	; read FCB

	POP	BX		;☆
	cmp	[ascflg],0
	jne	aopen50

	PUSH	BX		;☆
	MOV	DX,OFFSET FNAMEBUF
	MOV	CX,16
	MOV	AH,3FH		;read
	INT	21H
	JC	aopenOPENERR
	MOV	BX,OFFSET FNAMEBUF
	cmp	word ptr [bx],'sq'	;SEQ FILE か CHECK
	JNZ	aopenILGFILE

	MOV	di,[FILENO]
	shl	di,1
	mov	[di+ptword],1		;non ascii file

	;POINTER を FILE END に
SKIP2END:
	POP	BX		;☆HANDLE
aopen50:
	MOV	AH,42H
	MOV	AL,2
	XOR	CX,CX
	XOR	DX,DX
	INT	21H
	cmp	[ascflg],0
	jne	aopen100
aopenret:
	jmp	gomainlp2

aopen100:
	mov	cx,dx
	mov	dx,ax
	sub	dx,1
	sbb	cx,0
	jb	aopenret	;new file
	mov	si,cx		;memo
	mov	di,dx		;memo
	MOV	AH,42H		;move pointer to fileend-1
	MOV	AL,0
	INT	21H

	MOV	DX,OFFSET FNAMEBUF
	MOV	CX,1
	MOV	AH,3FH		;read
	INT	21H
	mov	al,[FNAMEBUF]
	cmp	al,CTRL_Z
	jne	aopenret

	mov	cx,si
	mov	dx,di
	MOV	AH,42H		;move pointer to fileend-1
	MOV	AL,0		;= cut CTRL_Z
	INT	21H

	jmp	aopenret

aopenOPENERR:
	jmp	far ptr openerr
aopenILGFILE:
	jmp	far ptr ilgfile


;* write

farCOPENIN:
	WINC	BP
	CALL	CHECKAS
	mov	dx,-1
	cmp	byte ptr [bp],80h	;1st code of file
	je	farEXTOPENin
	CALL	GETFILENO	;FILE NUMBER を GET
	CALL	CHECKREOPEN
	jmp	WCREATE


farWOPENIN:
	WINC	BP
	CALL	CHECKAS
	CALL	GETFILENO	;FILE NUMBER を GET
	CALL	CHECKREOPEN

	;OPEN FOR R/W

	MOV	AH,3DH		;OPEN HANDLE
	MOV	AL,2
	MOV	DX,OFFSET FNAMEBUF
	INT	21H	
	JNC	WRTEXIST	;ファイルがあったらエラー
WOPEN10:
	CMP	AX,2
	JNE	CANTWOPEN

	;ファイルの CREATE OPEN

WCREATE:
	MOV	AH,3CH		;MAKE HANDLE
	MOV	DX,OFFSET FNAMEBUF
	MOV	CX,0
	INT	21H
	JC	CANTWOPEN
	PUSH	AX		;☆HANDLE
	MOV	BX,[FILENO]
	SHL	BX,1

	MOV	AH,2		;FLAG FOR WRITE
	MOV	[BX+HANDLE],AX
	mov	[bx+ptword],0	;0 means ascii file

	;FILE NAME をメモ

	my_SHL	BX,4
	ADD	BX,OFFSET OTHERFNAMEBUF
	mov	ax,code
	mov	es,ax
	MOV	DI,BX
	MOV	SI,OFFSET FNAMEBUF
	MOV	CX,fnamewordlen
	REP	MOVSW
	smov	es,ss

	;write file FCB(16 bytes)

	pop	bx		;☆handle
	cmp	[ascflg],0
	jne	wopen50		;if ascii file

	mov	di,offset fnamebuf
	mov	dx,di
	mov	ax,'sq'		;MARK OF SEQ FILE for version 9
	stosw
	xor	ax,ax
	mov	cx,7
	rep	stosw

	mov	cx,16
	mov	ah,40h
	int	21h

	mov	bx,[fileno]
	shl	bx,1
	mov	[bx+ptword],1	;1 means nonascii file

wopen50:
	jmp	gomainlp2


CANTWOPEN:
	CMP	AX,5
	JNe	wrtOPENERR
	JMP	far ptr PROTECTED	;write protected

WRTEXIST:
	JMP	far ptr EXISTERR
wrtopenerr:
	jmp	far ptr openerr


;
;*sequential files
;	INPUT BP at '#'

farSEQWRITE:	
SEQWRITELP:
	CALL	SEQWRITESUB
	MOV	AL,[BP]
	CMP	AL,CR
	JE	SEQWRITEOUTwithRET
	CMP	AL,0C0H		;':'
	JE	SEQWRITEOUTwithRET
	INC	BP
	CMP	AL,0C1H		;';'
	JE	SEQWRITELP?
	CMP	AL,0C2H		;','
	JE	SEQWRITELP?
	dec	bp
	jmp	SEQWRITEOUTwithRET

SEQWRITELP?:
	MOV	AL,[BP]		;次は命令の終わりでは?
	CMP	AL,CR
	JE	SEQWRITEOUT
	CMP	AL,0C0H		;':'
	je	SEQWRITEOUT
	jmp	SEQWRITELP

SEQWRITEOUTwithRET:
SEQWRITEOUT:
	jmp	gomainlp2


	;エラーなのでファイルをクローズして戻る
	;BX=HANDLE であること

WRITEERR:	
	MOV	AH,3EH		;close file
	INT	21H
	JMP	far ptr DISKERR

WRITEFULL:	
	MOV	AH,3EH		;close file
	INT	21H
	JMP	far ptr DISKFULL

ILG_WRITE:
	JMP	far ptr NOTOPEN	;WRITE OPEN していない



SEQWRITESUB:
	CALL	far ptr farFORMUL
	mov	si,[calcsp]
	MOV	CX,[SI]
	AND	CX,LENMASK
	INC	CX
	SHL	CX,1		;BYTE SIZE
	MOV	BX,[FILENO]
	SHL	BX,1
	MOV	BX,[BX+HANDLE]	;HANDLE NUMBER
	CMP	BH,2
	JNE	ILG_WRITE	;WOPEN されていない
	XOR	BH,BH
	MOV	DX,si
	MOV	AH,40H		;WRITE HANDLE
	INT	21H
	JC	WRITEERR	;書込失敗
	CMP	AX,CX
	JB	WRITEFULL	;DISK FULL
	add	[calcsp],unitbyte
	RET


;☆ＲＥＡＤ

farROPENIN:
	INC	BP
	CALL	CHECKAS
	CALL	GETFILENO
	CALL	CHECKREOPEN

	;ファイルのOPEN

	MOV	AH,3DH		;OPEN HANDLE
	MOV	AL,0		;FOR READ
	MOV	DX,OFFSET FNAMEBUF
	INT	21H
	JC	CANTROPEN1

	PUSH	AX		;HANDLE

	MOV	BX,[FILENO]
	SHL	BX,1
	MOV	AH,1		;FLAG FOR READ

	MOV	[BX+HANDLE],AX
	MOV	[BX+PTWORD],0	;0 means ascii file
	SHL	BX,1
	MOV	[BX+FILEPTR],0	;32BIT POINTER
	MOV	[BX+FILEPTR+2],0;
	cmp	[ascflg],0
	jne	ropen10
	MOV	[BX+FILEPTR],16	;32BIT POINTER

	;FILE NAME をメモ
ropen10:
	my_SHL	BX,3
	ADD	BX,OFFSET OTHERFNAMEBUF
	mov	ax,code
	mov	es,ax
	MOV	DI,BX
	MOV	SI,OFFSET FNAMEBUF
	MOV	CX,fnamewordlen
	REP	MOVSW
	smov	es,ss

	;FCB の読み込み

	POP	BX		;☆
	cmp	[ascflg],0
	jne	ropen50

	MOV	DX,OFFSET FNAMEBUF
	MOV	CX,16
	MOV	AH,3FH		;read
	INT	21H
	JC	CANTROPEN
	MOV	BX,OFFSET FNAMEBUF
	cmp	[bx],'sq'	;SEQ FILE か CHECK
	JNE	GOILGFILE

	mov	bx,[fileno]
	add	bx,bx
	mov	[bx+ptword],1	;1 means nonascii file
ropen50:
	CALL	READNEXTATTR
	jmp	gomainlp2

CANTROPEN1:
	CMP	AX,2
	JNE	CANTROPEN
	JMP	far ptr NOFILE
CANTROPEN:
	JMP	far ptr OPENERR
GOILGFILE:
	JMP	far ptr ILGFILE


READNEXTATTR:
	MOV	CX,2		;read 1 word
	MOV	BX,[FILENO]
	SHL	BX,1
	cmp	[BX+PTWORD],0	;0 means ascii file
	je	readnextascii

	LEA	DX,[BX+EOFFLG]	;ADDRESS
	PUSH	DX		;☆
	MOV	BX,[BX+HANDLE]	;HANDLE NUMBER
	CMP	BH,1
	JNE	GOILG_READ	;ROPEN されていない
	XOR	BH,BH
	MOV	AH,3FH		;READ HANDLE
	INT	21H
	POP	SI		;☆
	JC	GOSEQRERR	;読込失敗
	cmp	ax,cx
	je	READNEXTATTRRET
	MOV	word ptr [SI],0ffffh	;EOF=FFFFH

READNEXTATTRRET:
	MOV	BX,[FILENO]	;POINTER INCREMENT
	SHL	BX,1
	SHL	BX,1
	ADD	[BX+FILEPTR],AX
	ADC	[BX+FILEPTR+2],0
	RET

readnextascii:
	lea	si,[bx+EOFFLG]
	mov	word ptr [si],0	;non EOF
	jmp	readnextattrret


GOILG_READ:
	JMP	far ptr NOTOPEN

GOSEQRERR:
	JMP	far ptr DISKERR

;
;☆ＳＥＱＲＥＡＤ
;

farSEQREAD:
	CALL	GETFILENO
	CMP	BYTE PTR [BP],0C2H
	JNE	GOSEQRERR
	INC	BP
SEQREADLP:
	CALL	AHEDSP2
	CALL	SEQREADSUB	;値を読み込む
	CALL	far ptr farINPLET	;変数に代入
	MOV	AL,[BP]
	CMP	AL,CR
	JE	SEQROUT
	CMP	AL,0C0H		;':'
	JE	SEQROUT
	INC	BP
	CMP	AL,0C1H		;';'
	JE	SEQREADLP
	CMP	AL,0C2H		;','
	JE	SEQREADLP
	dec	bp
;//	JMP	filefarsynerr
SEQROUT:
	jmp	gomainlp2

SEQREADSUB:
	MOV	AX,[CALCSP]
	MOV	[FADR],AX
	MOV	BX,[FILENO]
	SHL	BX,1
	MOV	AX,[BX+PTWORD]	;ファイルの小数ワード数
	MOV	[FPOINT],AX	;=0 iff ascii file
	MOV	AX,[BX+EOFFLG]
	MOV	[FATTR],AX
	MOV	AX,[BX+HANDLE]
	CMP	AH,1
	JNE	SEQRNOTOPEN	;オープンしていない
	XOR	AH,AH
	MOV	[FHANDLE],AX
	CALL	far ptr farREADRECORD
	JMP	READNEXTATTR	;CALL & RET
seqreadout:
	ret

SEQRNOTOPEN:
	JMP	far ptr NOTOPEN


;
;☆ 外部配列のオープン
;

	;既存のファイルの場合

EXTOPEN20:
	or	dx,dx
	jnz	exterr

	;OPEN FOR R/W

	MOV	AL,2
EXTOPENRO:
	MOV	AH,3DH		;OPEN HANDLE
	MOV	DX,OFFSET FNAMEBUF
	INT	21H	
	JNC	EXTOPEN25
	CMP	AX,5		;READ ONLY か?
	JNE	CANTEXTOPEN
	MOV	AL,0
	JMP	EXTOPENRO	;OPEN FOR READ		
EXTOPEN25:
	MOV	DI,[FILENO]
	STOSW			;SET HANDLE

	;FCB の読み込み

	MOV	DX,OFFSET FNAMEBUF
	MOV	CX,16
	MOV	BX,AX		;HANDLE
	MOV	AH,3FH		;READ HANDLE
	INT	21H
	JC	CANTEXTOPEN
	OR	AX,AX
	JZ	CANTEXTOPEN

	MOV	SI,OFFSET FNAMEBUF	;PARAMETER のセット
	LODSW
	cmp	ax,'rd'
	jne	notrndfile
	mov	cx,3
	rep	movsw
	mov	ax,1			;non ascii mark
	stosw
	movsw				;2dim size
	movsw				;

	WINC	BP
	jmp	gomainlp2		;後は無視

CANTEXTOPEN:
	JMP	far ptr OPENERR
EXTERR:
	JMP	filefarsynerr
EXTREOPEN:
	JMP	far ptr REOPENERR
FILEEXIST:
	JMP	far ptr EXISTERR
NOTRNDFILE:
	JMP	far ptr ILGFILE


farEXTOPEN:
	xor	dx,dx
farextopenin:				;dx=-1 if create
	MOV	AX,[BP]
	CMP	AL,80H
	JNE	EXTERR
	CMP	AH,0D4H
	JB	EXTERR
	MOV	BX,OFFSET HANDLE1
	MOV	DI,OFFSET EXTFNAMEBUF
	CMP	AH,0D6H
	JB	EXTOPEN10
	MOV	BX,OFFSET HANDLE2
	MOV	DI,OFFSET EXTFNAMEBUF+32
	CMP	AH,0D8H
	JB	EXTOPEN10
	MOV	BX,OFFSET HANDLE3
	MOV	DI,OFFSET EXTFNAMEBUF+64
	CMP	AH,0DAH
	JAE	EXTERR
EXTOPEN10:
	MOV	[FILENO],BX
	CMP	WORD PTR [BX],0
	JNE	EXTREOPEN	;ALREADY OPENED

	;MEMO FILE NAME

	mov	si,code		;must reserve AX
	mov	es,si
	MOV	SI,OFFSET FNAMEBUF
	MOV	CX,fnamewordlen
	REP	MOVSW
	smov	es,ss

	TEST	AH,1
	JMPNZ	EXTOPEN20

	or	dx,dx
	jnz	extopen30

	;OPEN FOR R/W

	MOV	AH,3DH		;OPEN HANDLE
	MOV	AL,2		;FOR READ & WRITE
	MOV	DX,OFFSET FNAMEBUF
	INT	21H	
	JNC	FILEEXIST	;already exists
	CMP	AX,2
	JNE	CANTEXTOPEN

	;make a new file

EXTOPEN30:
	MOV	AH,3CH		;CREATE HANDLE
	MOV	CX,0
	MOV	DX,OFFSET FNAMEBUF
	INT	21H
	JC	CANTEXTOPEN

	MOV	DI,[FILENO]
	MOV	[DI],AX		;SET HANDLE
	WINC	BP

	;check SIZE

	CALL	far ptr farFORMUL
	backsp_mac
	XOR	CX,CX		;INDEX の上位
	XOR	DX,DX		;INDEX の下位
	mov	bx,[fileno]
	mov	[bx+10],dx	;set 2dim size
	mov	[bx+12],cx

	MOV	AX,[SI]
	OR	AX,AX
	JZ	EXTOPEN40
	MOV	DX,[SI+2]
	DEC	AX
	JZ	EXTOPEN40
	MOV	CX,[SI+4]
	DEC	AX
	JMPNZ	ILG_EXT
EXTOPEN40:
	MOV	[bx+2],DX	;SET SIZE
	MOV	[bx+4],CX

	mov	al,[bp]
	cmp	al,')'
	je	extopen90
	cmp	al,0c2h		;code of ','
	jmpnz	ilg_ext

	inc	bp
	call	far ptr farFORMUL
	backsp_mac
	xor	cx,cx
	xor	dx,dx
	mov	ax,[si]
	or	ax,ax
	jz	extopen50
	mov	dx,[si+2]
	dec	ax
	jz	extopen50
	mov	cx,[si+4]
	dec	ax
	jmpnz	ilg_ext
extopen50:
	mov	bx,[fileno]
	mov	[bx+10],dx	;set 2dim size
	mov	[bx+12],cx
	mov	di,dx
	mov	si,cx
	add	di,1
	adc	si,0
	jc	ilg_ext

	push	si		;higher
	push	di		;lower
	mov	di,[bx+2]
	mov	si,[bx+4]
	add	di,1
	adc	si,0
	jc	ilg_ext
	pop	ax		;lower
	mov	cx,ax		;memo
	mul	di
	mov	[bx+2],ax
	mov	[bx+4],dx
	pop	ax		;higher
	push	ax
	mul	di
	add	[bx+4],ax
	adc	dx,0
	jnz	ilg_ext
	mov	ax,cx		;lower
	mul	si
	add	[bx+4],ax
	adc	dx,0
	jnz	ilg_ext
	pop	ax		;higher
	mul	si
	or	ax,dx
	jnz	ilg_ext

	sub	word ptr [bx+2],1
	sbb	word ptr [bx+4],0

extopen90:
	;UNIT WORD の SET

	cmp	byte ptr [bp],')'
	jne	ilg_ext
	inc	bp

	MOV	AX,[maxword]	;DEFAULT RECORD SIZE
	CMP	BYTE PTR [BP],9FH	;CODE OF WORD
	JNE	EXTOPEN100
	INC	BP
	CALL	far ptr farFORMUL
	backsp_mac
	MOV	AX,[SI]
	CMP	AX,1
	JNE	ILG_EXT
	MOV	AX,[SI+2]
	CMP	AX,LIMITWORD
	JBE	EXTOPEN100
ILG_EXT:
	JMP	filefarILGERR	

EXTOPEN100:
	INC	AX
	add	ax,ax
	MOV	SI,[FILENO]
	MOV	[SI+6],AX	;SETUNIT BYTE

	;write file control block

	MOV	DI,OFFSET FNAMEBUF
	MOV	DX,DI
	mov	ax,'rd'		;MARK OF RANDOM FILE from ver 9
	stosw
	MOV	SI,[FILENO]
	MOV	BX,[SI]		;HANDLE
	WINC	SI
	MOV	CX,6
	REP	MOVSW
	XOR	AX,AX
	STOSW

	MOV	AH,40H		;WRITE HANDLE
	MOV	CX,16
	INT	21H
	JC	GODISKERR
	CMP	AX,CX
	JB	GODISKFULL	

	;check disk free space

	MOV	DI,[FILENO]
	MOV	AX,[DI+2]
	MOV	DX,[DI+4]
	ADD	AX,1
	ADC	DX,0
	MOV	BX,[DI+6]
	CALL	MUL3216B
	JC	ILG_EXT
	TEST	DH,80H	
	JNZ	ILG_EXT
	MOV	CX,DX
	MOV	DX,AX
	sub	dx,1
	sbb	cx,0

	MOV	AH,42H		;MOVE POINTER
	MOV	AL,1		;RELATIVE MOVE
	MOV	BX,[DI]
	INT	21H		
	JC	GODISKERR

	MOV	AH,40H		;WRITE HANDLE
	MOV	CX,1		;DUMMY WRITE FOR CHECK
	mov	dx,offset fnamebuf	;any address
	INT	21H
	JC	GODISKERR
	OR	AX,AX
	JZ	GODISKFULL

	jmp	gomainlp2

GODISKERR:
	JMP	far ptr WRITEERR
GODISKFULL:
	JMP	far ptr WRITEFULL

;
;☆ＲＥＳＴＯＲＥ ＳＥＱ＿ＦＩＬＥ
;

farRESTOREFILE:
	INC	BP
	CMP	BYTE PTR [BP],NCODE1
	JNE	RESTORESYNERR
	INC	BP
	MOV	BX,[BP]
	CMP	BX,MAXFILE
	JA	RESTORESYNERR

	MOV	[FILENO],BX
	SHL	BX,1
	MOV	AX,[BX+HANDLE]	;HANDLE NUMBER
	CMP	AH,1
	JNE	ILG_RESTORE	;ROPEN されていない

	xor	cx,cx
	mov	dx,16		;for FCB if .UBD
	cmp	[bx+ptword],0
	jne	restoreUBfile
	xor	dx,dx
restoreUBfile:
	push	dx
	xor	ah,ah
	mov	bx,ax		;handle
	MOV	AH,42H		;MOVE PTR
	XOR	AL,AL
	INT	21H
	pop	dx
	JC	restoreDISKERR	;読込失敗
	or	dx,dx
	jz	restorefilejp
	CALL	READNEXTATTR
restorefilejp:
	WINC	BP
	jmp	gomainlp2

RESTORESYNERR:
	JMP	filefarILGERR

ILG_RESTORE:
	JMP	far ptr NOTOPEN
	
restoreDISKERR:
	jmp	far ptr diskerr


MUL3216B:
	;DX:AX ＝ DX:AX × BX

	PUSH	CX
	MOV	CX,AX
	MOV	AX,DX
	MUL	BX
	OR	DX,DX
	JNZ	MUL3216BERR
	PUSH	AX
	MOV	AX,CX
	MUL	BX
	POP	CX
	ADD	DX,CX
MUL3216BRET:
	POP	CX
	RET

MUL3216BERR:
	STC
	JMP	MUL3216BRET


;
;計算用スタックを一つ深くする
;    output:SI new calcsp
;    destroy:NOTHING

	EVEN
AHEDSP2:	
	MOV	SI,[CALCSP]
	SUB	SI,UNITBYTE
	CMP	SI,[calcsp_limit]
	JB	GO_CALCSPERR
	MOV	[CALCSP],SI
	RET

GO_CALCSPERR:
	JMP	far ptr CALCSPERR

;
;** read 1 RECORD from DISK
;	INPUT [FPOINT],[FATTR],[FADR],[FHANDLE]

readascnodata:
	jmp	far ptr nodataerr

	;input a character from file
;read1ilgdata:
;	jmp	far ptr ilgdata
readascDISKERR:
	jmp	far ptr DISKERR

readascii:
	add	di,2

	mov	bx,[fileno]
	add	bx,bx
	mov	ax,[bx+eofflg]
	cmp	ax,-1
	je	readascnodata

	mov	bx,[fhandle]
	mov	cx,maxreadsize
	push	cx			;for next pop

readascLP1:
	pop	cx
  if FLG98
	sub	cx,8
  else
	sub	cx,32
  endif
  	jb	readasc40
	push	cx

  if FLG98
  	mov	cx,8
  else
	mov	cx,32
  endif
	mov	dx,di
	mov	ah,3fh
	int	21h
	jc	readascDISKERR
	or	ax,ax
	jz	readascEOFpop		;EOF

;readascin:
	mov	cx,ax
	mov	al,LF
readascLP2:
	repne	scasb			;search LF
	jne	readascLP1		;no LF

	pop	ax			;dummy
	or	cx,cx
	jz	readasc40		;just ended by LF

	mov	dx,cx
	neg	dx
	mov	cx,-1
	mov	ax,4201h
	int	21h			;move file pointer
	jmps	readasc40

readasc1more:				;check LF
	mov	cx,1
	mov	dx,di
	mov	ah,3fh
	int	21h
	jc	readascDISKERR
	or	ax,ax
	jz	readasc40pop		;no data

	cmp	byte ptr [di],LF
	je	readasc35

	mov	cx,-1
	mov	dx,cx
	mov	al,1
	mov	ah,42h			;move file pointer
	int	21h
	jmp	readascLP1		;no CRLF

readasc35:
	inc	di

readasc40pop:
	pop	cx			;dummy
	jmps	readasc40

readascEOFpop:
	pop	cx
;	cmp	byte ptr [di-1],CTRL_Z
;	jne	readasc40
;	dec	di

readasc40:
	cmp	byte ptr [di-2],CR
	je	short readasc45
	inc	di
	mov	word ptr [di-2],CR+LF*256
readasc45:
	mov	ax,di
	mov	si,[fadr]
	sub	ax,si
	sub	ax,2

	mov	cx,ax		;=bytes(excluding CR,LF)
	inc	ax
	shr	ax,1
	jc	readasc50	;if even bytes
	mov	byte ptr [di],0
	or	ah,signmaskhigh		;mark of odd length
readasc50:
	or	ah,stringmaskhigh
	mov	[si],ax

	MOV	BX,[FILENO]	;POINTER INCREMENT
	my_shl	bx,2
	ADD	[BX+FILEPTR],cx
	ADC	[BX+FILEPTR+2],0
	jmp	readrecret

farREADRECORD:
	MOV	DI,[FADR]
	cmp	[fpoint],0
	je	readascii	;ascii opened file

	MOV	AX,[FATTR]
	CMP	AX,0FFFFH
	JE	READEND		;FILE END
	mov	[di],ax		;set attribute
	and	ax,lenmask
	jz	readrecret	;IF ZERO
	cmp	ax,limitword
	ja	readrecilgdata	;illegal data
	mov	dx,di
	add	dx,2
	mov	cx,ax
	shl	cx,1		;BYTE SIZE
	MOV	AH,3FH		;READ HANDLE
	MOV	BX,[FHANDLE]	;HANDLE NUMBER
	INT	21H
	JC	READRECERR	;読込失敗
	cmp	ax,cx
	jne	READEND		;END OF FILE(error)
readrec10:
	MOV	BX,[FILENO]	;POINTER INCREMENT
	cmp	bx,offset handle1
	jae	readrecret	;if random file
	SHL	BX,1
	SHL	BX,1
	ADD	[BX+FILEPTR],AX
	ADC	[BX+FILEPTR+2],0
readrecret:
	retf

READRECILGDATA:
	JMP	far ptr ILGDATA
READRECERR:
	JMP	far ptr DISKERR
READEND:
	JMP	far ptr NODATAERR


;☆ＤＩＲ コマンド

DIRCHG:
	INC	BP
	call	far ptr farFORMUL
	mov	si,[calcsp]
	lodsw
	test	ah,stringmaskhigh
	jz	direrr
	and	ax,lenmask
	add	ax,ax
	add	ax,si
	mov	di,ax
	mov	word ptr [di],0	;ASCIZ end mark
	MOV	DI,INPBUF
dirchg10:
	lodsb
	cmp	al,' '
	je	dirchg10
	dec	si
	mov	dl,al
	mov	al,[si+1]
	cmp	al,':'
	jne	dirchg30

	add	si,2
	and	dl,11011111b
	sub	dl,'A'
	mov	ah,0eh		;change drive
	int	21h

DIRCHG30:
	lodsb
	stosb
	or	al,al
	jnz	dirchg30
DIRCHG40:
	MOV	DX,INPBUF
	MOV	AH,3BH		;change current directory
	INT	21H

	add	[calcsp],unitbyte

	jmp	gomainlp2	;READY

DIRERR:
	JMP	filefarsynerr

	;* starts here

farDIRIN:	
	cmp	byte ptr [bp],codeofequal
	JE	DIRCHG

	;INPBUF が DMA ADR

	MOV	AH,26			;set DTA
	MOV	DX,INPBUF
	INT	21H

	mov	di,offset fnamebuf
	mov	al,[bp]
	cmp	al,CR
	je	DIR10
	cmp	al,0c0h		;code of :
	je	DIR10
	CALL	far ptr farSETFNAME
	jnc	dir30
dir10:
	mov	word ptr [di],2e2ah	;".*"
	mov	word ptr [di+2],002ah	;"*",0
dir30:
	call	dirsub

	MOV	DX,OFFSET diskfreemsg
	CALL	MSG_CS2		;残り容量の表示
	CALL	far ptr farDISKFREE
	MOV	SI,WORK3	;	[CALCSP]
				;	SUB	SI,UNITBYTE
	MOV	[SI+4],DX
	MOV	[SI+2],AX
	MOV	CX,2
	OR	DX,DX
	JNZ	DIR110
	DEC	CX
	OR	AX,AX
	JNZ	DIR110
	DEC	CX
DIR110:
	MOV	[SI],CX
	CALL	far ptr farBINASC
	MOV	DX,SS
	ADD	DX,ASCBINSEG
	MOV	DS,DX
	MOV	DX,ASCBUFTOP
	CALL	msg2
	MOV	DX,OFFSET bytemsg
	CALL	MSG_CS2
	smov	ds,ss
	AND	[OUT_DEV],NOTBIT1
	JMP	far ptr mainlp
;	JMP	far ptr READY


  if JAPANESE
DISKFREEMSG	DB	cr,'未使用ディスク領域 ＝ ',0
bytemsg		db	' バイト',cr,lf,0
  else
DISKFREEMSG	DB	cr,'Free Disk area = ',0
bytemsg		db	' bytes',cr,lf,0
  endif

farDISKFREE:
	PUSH	BX
	PUSH	CX

	MOV	DL,0
	MOV	AX,WORD PTR [FNAMEBUF]
	CMP	AH,":"
	JNE	DISKF100
	SUB	AL,"@"
	CMP	AL,20H
	JB	DISKF90
	SUB	AL,20H
DISKF90:
	MOV	DL,AL
DISKF100:
	MOV	AH,36H
	INT	21H

	MUL	CX
	MUL	BX

	POP	CX
	POP	BX
	retf


dirnamelen	equ	16

DIRSUB:
	;最初のファイルを捜す

	MOV	AH,4EH		;search 1st
	MOV	CX,17H		;search all attributed file
	MOV	DX,OFFSET FNAMEBUF
	INT	21H
	JC	DIRSUBRET	;no file
DIRLP:	
	CALL	far ptr farCHKCTRL_CS	;STOP OR CTRL_S のチェック

	mov	al,[xpos]
	add	al,dirnamelen
	cmp	al,[chars1]
	jbe	dirsub10
	call	nl2
dirsub10:
	mov	di,inpbuf+1eh
	mov	cx,dirnamelen-3
	xor	al,al
	repne	scasb
	dec	di
	add	cx,3
	mov	al,' '
	rep	stosb
	xor	al,al
	stosb
	MOV	DX,INPBUF+1EH	;見付けたファイルを表示
	CALL	MSG2

;	mov	al,[xpos]
;	inc	al
;	cmp	al,[chars1]
;	je	dirsub10
	mov	al,' '
	call	prchr2
;	jmps	dirsub20
;dirsub10:
;	call	nl2

	;次のファイルを捜す
dirsub20:
	MOV	AH,4FH			;search next
	INT	21H
	JNC	DIRLP
	clc
DIRSUBRET:
	pushf
	CMP	AX,18
	jne	dirsubdiskerr
	call	nl2
	popf
	ret			;CF=1 iff no file
dirsubdiskerr:
	jmp	far ptr DISKERR


comment %
;
;* read file as a binary file
;
readbsynerr:
	jmp	far ptr synerr
readbovererr:
	jmp	far ptr ovrerr

readbin:
	call	far ptr farget_ax
	cmp	ax,maxfile
	ja	readbovererr
	mov	[fileno],ax
	cmp	byte ptr [bp],0c2h	;','
	jne	readbsynerr
	inc	bp
	call	far ptr farget_ax
	cmp	ax,limitword*2
	jae	readbovererr
	push	ax
	cmp	byte ptr [bp],')'
	jne	readbsynerr
	inc	bp
	call	ahedsp2

	;read file

	mov	bx,[fileno]
	shl	bx,1
	mov	ax,[handle+bx]
	cmp	ah,1
	jne	readbnotopen
	mov	di,[calcsp]
	mov	word ptr [di],stringmask	;means null string
	mov	dx,di
	add	dx,2			;skip attribute
	pop	cx			;bytes
	xor	ah,ah
	mov	bx,ax
	mov	ah,3fh
	int	21h

	;set attribute

	or	ax,ax
	jz	readbret
	mov	dx,stringmask
	shr	ax,1
	jnc	readbset
	inc	ax
	or	dx,signmask
readbset:
	or	ax,dx
	mov	[di],ax			;set attribute
readbret:
	jmp	far ptr returnadr

readbnotopen:
	jmp	far ptr notopen

;
;* write file as a binary file
;

writebin:
	jmp	far ptr returnadr

%
code2	ends

END
