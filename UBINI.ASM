;UBINI.ASM for IBM-AT & DOS/V
;
; ** Initialize Routine
;	VERSION 9
;	1988-98 by Yuji KIDA

	INCLUDE	UBDEF.H
	INCLUDE	UB.H


DATA	SEGMENT	WORD PUBLIC

	public	initdata,environment,functionkey_sw
	public	machinetype,originalvideomode

	EXTRN	OUT_DEV:BYTE,blocksw:byte,stopflg:byte
	EXTRN	XPOS:BYTE,YPOS:BYTE,LNEND:WORD,directflg:byte
	EXTRN	EDITPTR:WORD,listtimer:word
	extrn	CONTADR:WORD,contcsp:word,errortrap:word

	extrn	BASE_SP:word,txtend:word
	extrn	varsegnow:word,limitseg:word,vramsegnow:word,vramsegover:word
	extrn	lvarlimit:word
	extrn	chars1:byte,chars2:word,charsall2:word
	extrn	linesdef:byte
	extrn	btmline:byte,maxlinesnow:byte,btmadr:word
	extrn	whitenow:byte

	extrn	emahandle:word

	extrn	PRSPC:near,NL:near
	extrn	MSG:near,MSG_CS:near
	extrn	COLDST:near,INILOOP:near,CHGOUT_INIT:near

	extrn	graphflg:byte
	extrn	fixedflag:byte

;
;	?tBASIC ?? ?vORKING AREA
;

machinetype	dw	_machinetype

environment	dw	?

;function is displayed or not?

functionkey_sw  db      1,0

;video mode

originalvideomode	db	?,?


;the area from this address is needed only for initialization
;and will be used for the area for short variables
;must DIRECTBUF >= INITDATA

INITDATA	LABEL BYTE

OPENMSG	LABEL BYTE
UBASMSG		DB	ctrl_L,6 DUP (LF)
		DB	20 dup(' ')
		db	versionmessage,cr,lf
		DB	LF,20 dup(' '),CR,LF
		DB	20 dup(' ')
  if JAPANESE
  		DB	'Copyright 1986-2000 by ?ؓc ?S?i',CR,LF,0
  else
		DB	'Copyright 1986-2000 by Yuji KIDA',CR,LF,0
  endif
DATA	ENDS


CODE	SEGMENT WORD PUBLIC
	ASSUME	CS:CODE,DS:DATA


;PUBLIC LABELS

	PUBLIC	INIT,SYSTEM
        public  disp_functionkey,farDISP_FUNCTIONKEY
        public  clear_functionkey,farCLEAR_FUNCTIONKEY

	PUBLIC	PRNFNAMEBUF,LPTFNAMEBUF,OTHERFNAMEBUF,EXTFNAMEBUF
	PUBLIC	INPFNAMEBUF
	PUBLIC	SOURCELEN,SOURCEADR
	PUBLIC	COUNT3,COUNT2,COUNT1
	PUBLIC	BLKP2UNIT,BLKP2STEP3OFF,BLKP2STEP3SEG
	PUBLIC	BLKP2COUNT2,BLKP2STEP2OFF,BLKP2STEP2SEG
	PUBLIC	BLKP2COUNT1,COUNT23,COUNT22,COUNT21
	PUBLIC	BLKPDIM,BLKPSEG,BLKPUNIT
	PUBLIC	BLKPIND3,BLKPSTEP3
	PUBLIC	BLKPIND30,BLKPIND31,BLKPCOUNT3
	PUBLIC	BLKPSTEP3OFF,BLKPSTEP3SEG
	PUBLIC	BLKPIND2,BLKPSTEP2,BLKPIND20,BLKPIND21
	PUBLIC	BLKPCOUNT2,BLKPSTEP2OFF,BLKPSTEP2SEG
	PUBLIC	BLKPIND1,BLKPSTEP1,BLKPIND10,BLKPIND11
	PUBLIC	BLKPCOUNT1

	public	curs_form

	PUBLIC	CS_DATA,mainlp_memo
	PUBLIC	FORSP,FORSPEND,GOSUBSP,GOSUBSPEND
	public	vartbl,freezed_sp

	PUBLIC	SYSTEMERR,CALCSPERR
	PUBLIC	SYNERR,OVRERR,SPERR,LINERR,DISKERR,DISKFULL
	PUBLIC	TOOLONGLINE,NOLERR,toomanyvar,fullerr,DIVERR
	PUBLIC	cantdo,worderr,pointerr,ILGERR,INDEXERR,UNDEFERR
	public	emaerr
	PUBLIC	DBLDEF,TYPEERR,NOWHILE,NOWEND,NOUNTIL,NOREPEAT
	PUBLIC	NOFOR,NONEXT,NOGOSUB,NORETURN,NOFILE,AREAFULL
	PUBLIC	FUNCERR,CONTERR,NODATAERR,FORNEXTERR	;,MISMATCHERR
	PUBLIC	REOPENERR,OPENERR,NOTOPEN,ILGFILE,REVERSELINE
	PUBLIC	ENDOFFILE,ILGLET,NOPROG,workfull
	PUBLIC	PROTECTED,BIGPROG,ILGDATA,EXISTERR,USRERR,USRBIGERR
	PUBLIC	STACKFULL,STACKEMPTY,USRSTKERR
	PUBLIC	LABELFULL,DOUBLELABEL
	PUBLIC	CANNOTMELT,MELTERR,NOMARK,NOLOOP,BLOCKERR
	PUBLIC	LONGNAME,calcstkerr,passerr,blockbusy
	public	localerr,moderr,vmodeerr,floaterr,nooverload
	public	conditionerr

	public	brkmsg

;EXTERNAL LABELS

	extrn	hardcopy:far

	EXTRN	TROFFSUB:NEAR

	extrn	mainlp:near,break:near
	EXTRN	READY:NEAR,HOTST:NEAR,GETCOM:NEAR,GETCOMJP:NEAR
	EXTRN	farINITWP:far,resvar:near
	EXTRN	farDISPWORDSUB:far,CALC_CONSOLE:NEAR
	extrn	curs_norm:near,curson:near,cursoff:near
	EXTRN	BEEPSUB:NEAR,CLOSEALL:NEAR,closeredirect:near
	EXTRN	FREEIN:NEAR
	extrn	clear_screen:near,kanji1st?:near
	extrn	?line:near,prntbx:near

	extrn	functionkeytbl:byte
	extrn	inmsg:byte

	extrn	farfunctionkeybox:far

  if graph
  	extrn	getfontserver:far
  endif

BRKMSG		DB	'Break',0


;* return to DOS

SYSTEM:
	CALL	CHGOUT_INIT
	CALL	CLOSEALL	;vlose all files
	call	closeredirect
	call	curs_norm
	call	curson
        CALL    CLEAR_FUNCTIONKEY

	;restore interrupt vectors

	mov	ah,25h
	mov	al,5
	lds	dx,dword ptr cs:[int5off]
	int	21h

	mov	ah,25h
	mov	al,1bh
	lds	dx,dword ptr cs:[int1boff]
	int	21h

	;graphic initialize

	smov	ds,ss
;	cmp	byte ptr [bp],0deh	;code of -
;	je	system100
	mov	ah,0fh
	int	10h
	cmp	al,[originalvideomode]
	je	system100
	xor	ax,ax
	mov	al,[originalvideomode]
	int	10h
system100:
	mov	dx,ss:[emahandle]
	or	dx,dx
	jz	system114
	mov	ah,45h		;close EMS
	int	67h
system114:

	mov	ah,0dh		;reset disk
	int	21h		;for flush disk buffer

	MOV	AX,4C00H
	INT	21H


;top 3 words from mainlp

mainlp_memo	dw	?,?,?

mainlp_break	label	word
	mov	ax,offset break
	jmp	ax


;
;* routine for INT 1BH
;
INTBREAK:
	cli
	cld
	push	ds
	push	es
	push	ax
	push	si
	push	di

	mov	ax,data
	mov	ds,ax		;to stop printer
	mov	[LNEND],0
	cmp	[stopflg],0
	je	intbreaknot

	mov	ax,cs
	mov	ds,ax
	mov	es,ax
	mov	si,offset mainlp_break
	mov	di,offset mainlp
	movsw
	movsw
	movsw

intbreaknot:
	pop	di
	pop	si
	pop	ax
	pop	es
	pop	ds
	iret

;
;* for INT24H
;
IONOTREADY:
	cli
	ADD	SP,6
	MOV	BP,SP
	OR	BYTE PTR [BP+22],1	;SET CARRY
	POP	AX
	POP	BX
	POP	CX
	POP	DX
	POP	SI
	POP	DI
	POP	BP
	POP	DS
	POP	ES
	XOR	AX,AX
	IRET


;
;* COPY KEY INTERRUPT
;
hardcopyskip:
	jmp	dword ptr [int5off]

COPYKEY:
	push	ds
	push	ax
	xor	ax,ax
	mov	ds,ax
	mov	al,ds:[0417h]
	test	al,3		;check shift
	pop	ax
	pop	ds
	jz	hardcopyskip

	push	ds
	push	es
  if FLG32
	pusha
  else
	push	ax
	push	bx
	push	cx
	push	dx
	push	si
	push	di
	push	bp
  endif
	mov	al,3
	call	far ptr hardcopy

  if FLG32
	popa
  else
	pop	bp
	pop	di
	pop	si
	pop	dx
	pop	cx
	pop	bx
	pop	ax
  endif
	pop	es
	pop	ds
	iret


;****************

;   SYSTEM CALL

;****************


;* error handling part 1

;for the error that CONT can be done

SYNERR:
	MOV	DX,OFFSET SYNMSG
	db	8dh		;lea di,[]
DISKERR:	
PROTECTED:
	MOV	DX,OFFSET DISKMSG
	db	8dh		;lea di,[]
DISKFULL:
	MOV	DX,OFFSET DSKFULLMSG
	db	8dh		;lea di,[]
CANNOTMELT:
	MOV	DX,OFFSET CANNOTMELTMSG


	CMP	BP,TXTHED
	JB	ERRINHOT	;if DIRECT MODE then goto HOT
	JMP	ERRIN

ERRINHOT:
	cli
	smov	ds,ss
	smov	es,ss
	MOV	SP,ss:[base_sp]
	sti
	JMP	ERRIN10


;* error handling part2
;for the error that CONT cannot be done

SYSTEMERR:
	MOV	DX,OFFSET SYSTEMERRMSG
	db	8dh		;lea di,[]
OVRERR:
	MOV	DX,OFFSET OVRMSG
	db	8dh		;lea di,[]
CALCSPERR:
	MOV	DX,OFFSET CALCSPMSG
	db	8dh		;lea di,[]
SPERR:	
	MOV	DX,OFFSET SPMSG
	db	8dh		;lea di,[]
LINERR:	
	MOV	DX,OFFSET LINMSG
	db	8dh		;lea di,[]
TOOLONGLINE:	
	MOV	DX,OFFSET LONGMSG
	db	8dh		;lea di,[]
NOLERR:	
	MOV	DX,OFFSET NOLMSG
	db	8dh		;lea di,[]
toomanyvar:
	mov	dx,offset manyvarmsg
	db	8dh		;lea di,[]
fullerr:	
	MOV	DX,OFFSET FULMSG
	db	8dh		;lea di,[]
DIVERR:	
	MOV	DX,OFFSET DIVMSG
	db	8dh		;lea di,[]
cantdo:
	MOV	DX,OFFSET CANNOTMSG
	db	8dh		;lea di,[]
AREAFULL:
BIGPROG:	
	MOV	DX,OFFSET BIGPROGMSG
	db	8dh		;lea di,[]
ILGERR:	
	MOV	DX,OFFSET ILGMSG
	db	8dh		;lea di,[]
INDEXERR:
	MOV	DX,OFFSET INDMSG
	db	8dh		;lea di,[]
UNDEFERR:
	MOV	DX,OFFSET UNDMSG
	db	8dh		;lea di,[]
DBLDEF:
	MOV	DX,OFFSET DBLMSG
	db	8dh		;lea di,[]
TYPEERR:
	MOV	DX,OFFSET TYPEMSG
	db	8dh		;lea di,[]
NOWHILE:
NOWEND:
	MOV	DX,OFFSET WHILEMSG
	db	8dh		;lea di,[]
NOREPEAT:
NOUNTIL:
	MOV	DX,OFFSET REPEATMSG
	db	8dh		;lea di,[]
NOFOR:
NONEXT:
	MOV	DX,OFFSET FORMSG
	db	8dh		;lea di,[]
NOGOSUB:
NORETURN:
	MOV	DX,OFFSET GOSUBMSG
	db	8dh		;lea di,[]
NOFILE:
	MOV	DX,OFFSET NOFILEMSG
	db	8dh		;lea di,[]
FUNCERR:
	MOV	DX,OFFSET FUNCERRMSG
	db	8dh		;lea di,[]
CONTERR:
	MOV	DX,OFFSET CANNOTMSG
	db	8dh		;lea di,[]
ENDOFFILE:
NODATAERR:
	MOV	DX,OFFSET NODATAMSG
	db	8dh		;lea di,[]
FORNEXTERR:
	MOV	DX,OFFSET FORNEXTMSG
	db	8dh		;lea di,[]
;MISMATCHERR:
;	MOV	DX,OFFSET MISMATCHMSG
;	db	8dh		;lea di,[]
NOPROG:
	MOV	DX,OFFSET NOPROGMSG
	db	8dh		;lea di,[]
ILGFILE:
	MOV	DX,OFFSET ILGFILEMSG
	db	8dh		;lea di,[]
REOPENERR:
	MOV	DX,OFFSET REOPENMSG
	db	8dh		;lea di,[]
OPENERR:
	MOV	DX,OFFSET OPENERRMSG
	db	8dh		;lea di,[]	
NOTOPEN:
	MOV	DX,OFFSET NOTOPENMSG
	db	8dh		;lea di,[]
ILGLET:
	MOV	DX,OFFSET ILGLETMSG
	db	8dh		;lea di,[]
ILGDATA:
	MOV	DX,OFFSET ILGDATAMSG
	db	8dh		;lea di,[]
EXISTERR:
	MOV	DX,OFFSET EXISTERRMSG
	db	8dh		;lea di,[]
USRERR:
	MOV	DX,OFFSET USRERRMSG
	db	8dh		;lea di,[]
USRBIGERR:
	MOV	DX,OFFSET USRBIGMSG
	db	8dh		;lea di,[]
STACKFULL:
	MOV	DX,OFFSET STACKFULLMSG
	db	8dh		;lea di,[]
STACKEMPTY:
	MOV	DX,OFFSET STACKEMPTYMSG
	db	8dh		;lea di,[]
USRSTKERR:
	MOV	DX,OFFSET USRSTKERRMSG
	db	8dh		;lea di,[]
CALCSTKERR:
	MOV	DX,OFFSET CALCSTKERRMSG
	db	8dh		;lea di,[]
LABELFULL:
	MOV	DX,OFFSET LABELFULLMSG
	db	8dh		;lea di,[]
DOUBLELABEL:
	MOV	DX,OFFSET DOUBLELMSG
	db	8dh		;lea di,[]
REVERSELINE:
	MOV	DX,OFFSET REVERSEMSG
	db	8dh		;lea di,[]
MELTERR:
	MOV	DX,OFFSET MELTERRMSG
	db	8dh		;lea di,[]
NOMARK:
	MOV	DX,OFFSET NOMARKMSG	
	db	8dh		;lea di,[]
NOLOOP:
	MOV	DX,OFFSET NOLOOPMSG
	db	8dh		;lea di,[]
BLOCKERR:
	MOV	DX,OFFSET BLOCKMSG
	db	8dh		;lea di,[]
LONGNAME:
	MOV	DX,OFFSET LONGNAMEMSG
	db	8dh		;lea di,[]
PASSERR:
	MOV	DX,OFFSET PASSERRMSG
	db	8dh		;lea di,[]
pointerr:
	MOV	DX,OFFSET pointerrmsg
	db	8dh		;lea di,[]
worderr:
	MOV	DX,OFFSET worderrmsg
	db	8dh		;lea di,[]
workfull:
	MOV	DX,OFFSET workfullmsg
	db	8dh		;LEA DI,[]
blockbusy:
	MOV	DX,OFFSET blockbusymsg
        db      8dh             ;LEA DI,[]
localerr:
        MOV     DX,OFFSET localerrmsg
        db      8dh             ;LEA DI,[]
moderr:
        MOV     DX,OFFSET moderrmsg
        db      8dh             ;LEA DI,[]
emaerr:
        MOV     DX,OFFSET emafullmsg
        db      8dh             ;LEA DI,[]
vmodeerr:
        MOV     DX,OFFSET vmodeerrmsg
        db      8dh             ;LEA DI,[]
floaterr:
        MOV     DX,OFFSET floaterrmsg
        db      8dh             ;LEA DI,[]
nooverload:
        MOV     DX,OFFSET nooverloadmsg
        db      8dh             ;LEA DI,[]
conditionerr:
        MOV     DX,OFFSET conditionerrmsg


;* display error message

ERRIN:
	cli
	cld
	MOV	AX,DATA
	MOV	DS,AX
	MOV	ES,AX
	MOV	SS,AX
	MOV	SP,systemstackbtm
	mov	[base_sp],sp
	MOV	[CONTADR],0
	mov	[contcsp],limit
	mov	[blocksw],0
	mov	[fixedflag],0
	sti
	push	[errortrap]
	CALL	INILOOP
	pop	[errortrap]
	CALL	CLOSEALL	;close all files
ERRIN10:
	mov	ah,0dh		;flush buffer
	int	21h

	MOV	[OUT_DEV],1

	cmp	[directflg],0
	jne	errin15		;direct mode
	cmp	[errortrap],0
	jne	errin20
errin15:
	CALL	NL
	mov	ax,code2
	mov	ds,ax
	CALL	MSG
	smov	ds,ss

;	CALL	BEEPSUB

;check mode

errin20:
	cmp	[errortrap],0
	je	errin30
	cmp	[directflg],0
	jne	errin30

errortrapping:
	mov	ax,[errortrap]
	mov	bp,ax
	jmp	mainlp	

errin30:
	mov	dx,bp
	cmp	bp,txthed
	jb	directerr
	cmp	bp,[txtend]
	jb	runerr

;if DIRECT MODE then goto READY quickly

directerr:
	CALL	PRSPC
	JMP	GOHOTST

;if RUN MODE then display line number and goto READY

RUNERR:
	MOV	DX,OFFSET INMSG
	CALL	MSG_CS
	CALL	?LINE
	MOV	[EDITPTR],DX
	MOV	BX,DX
	CALL	PRNTBX
	CALL	PRSPC

GOHOTST:
	STI
	CALL	NL
	JMP	HOTST

CLEAR_FUNCTIONKEY:
	push	ds
	push	es
	smov	ds,ss
;	cmp	[functionkey_sw],0
;	je	clearfret
;	mov	[functionkey_sw],0
	mov	es,[vramsegnow]
	mov	cx,[chars2]
	mov	di,[charsall2]
	sub	di,cx		;adr of top of last line
	shr	cx,1
	mov	ax,white*100h
	rep	stosw

dispfunctionkeymain:
	call	setfkeylinesub

	mov	dl,ss:[xpos]
	mov	dh,ss:[ypos]
	mov	ah,2
	int	10h		;set cursor position

clearfret:
	pop	es
	pop	ds
	RET

farCLEAR_FUNCTIONKEY:
	call	clear_functionkey
	retf

farDISP_FUNCTIONKEY:
	call	disp_functionkey
	retf

DISP_FUNCTIONKEY:
;	mov	ss:[functionkey_sw],1
	push	ds
	push	es

	smov	ds,cs
	mov	si,offset FUNCTIONKEYTBL
	mov	es,ss:[vramsegnow]
	mov	cx,ss:[chars2]
	mov	di,ss:[charsall2]
	sub	di,cx		;top adr of last line
	shr	cx,1

	push	di
	mov	ax,white*100h
	rep	stosw	
	pop	di

	add	di,6

	call	dispfkeysub
	call	dispfkeysub
	call	dispfkeysub
	call	dispfkeysub

	add	di,4

	call	dispfkeysub
	call	dispfkeysub
	call	dispfkeysub
	call	dispfkeysub

	add	di,4

	call	dispfkeysub
	call	dispfkeysub

	cmp	ss:[graphflg],0
	je	dispfunctionkeymain	;if text mode

	call	far ptr farfunctionkeybox	;if graphics mode
	jmp	dispfunctionkeymain	;next take xor by space

dispfkeysub:
	mov	ah,reversewhite
	cmp	ss:[graphflg],0
	je	dispfkeysub5
	mov	ah,ss:[whitenow]
	or	ah,80h
dispfkeysub5:
	mov	cx,6
dispfkeysub10:
	lodsb
	cmp	al,' '
	jae	dispfkeysub20
	mov	al,' '
dispfkeysub20:
	stosw
	myloop	dispfkeysub10
	add	di,2
	add	si,10
	ret


setfkeylinesub:
	mov	ds,ss:[vramsegnow]
	mov	si,ss:[charsall2]
	sub	si,ss:[chars2]
	
	xor	bx,bx
	mov	dl,0
	mov	dh,ss:[linesdef]
	dec	dh

	mov	cx,word ptr ss:[chars1]
setfkeyline10:
	push	cx

	mov	ah,2
	int	10h		;set cursor position

	lodsw
	mov	bl,ah
	mov	cx,1
	mov	ah,9
	int	10h

	inc	dl

	pop	cx
	myloop	setfkeyline10
	ret

curs_form	dw	?

	;*
	;* FOLLOWING DATA IN CS WILL BE SAVED BY FREEZE COMMAND
	;*

	EVEN
CS_DATA		EQU	THIS WORD
SOURCELEN	DW	?
SOURCEADR	DW	?

COUNT3	DW	?
COUNT2	DW	?
COUNT1	DW	?

BLKP2UNIT	DW	?
BLKP2STEP3OFF	DW	?	
BLKP2STEP3SEG	DW	?	
BLKP2COUNT2	DW	?
BLKP2STEP2OFF	DW	?
BLKP2STEP2SEG	DW	?
BLKP2COUNT1	DW	?
COUNT23	DW	?
COUNT22	DW	?
COUNT21	DW	?

BLKPDIM		DW	?
BLKPSEG		DW	?
BLKPUNIT	DW	?

BLKPIND3	DW	?
BLKPSTEP3	DW	?
BLKPIND30	DW	?
BLKPIND31	DW	?
BLKPCOUNT3	DW	?
BLKPSTEP3OFF	DW	?	
BLKPSTEP3SEG	DW	?	

BLKPIND2	DW	?
BLKPSTEP2	DW	?
BLKPIND20	DW	?
BLKPIND21	DW	?
BLKPCOUNT2	DW	?
BLKPSTEP2OFF	DW	?
BLKPSTEP2SEG	DW	?

BLKPIND1	DW	?
BLKPSTEP1	DW	?
BLKPIND10	DW	?
BLKPIND11	DW	?
BLKPCOUNT1	DW	?

freezed_sp	dw	?	;SP when freezed

;interrupt vectors

int5off		dw	?
int5seg		dw	?

int1boff	dw	?
int1bseg	dw	?


;* VARIABLE TABLE

VARTBL	DB	VARALL*(NAMELEN+2)+2 DUP (0)


;* stack for FOR-NEXT

;structure
;    0000H word ?ϐ??^
;    0002H word ?ϐ??̔Ԓn
;    0004H word STEP
;    0006H word NEXT ?????̖߂??Ԓn
;    0008H dword ????

	EVEN
FORSP	DW	?
	DW	FORUNITWORD*FORMAXLEVEL DUP(?)
FORSPEND	LABEL WORD


;* stack for GOSUB
;structure
;    0000H return address
;    0002H usr stack pointer
;    0004H parameter table pointer
;    0006H USER function FLAG
;    0008H LOCAL array base SEGMENT
;    000AH (DWORD)EMA base address
;    000EH point
;    0010H FOR stack pointer

GOSUBSP		DW	?
		DW	GOSUBUNITWORD*GOSUBMAXLEVEL DUP(?)
GOSUBSPEND	LABEL WORD


PRNFNAMEBUF	DB	fnamelen DUP(0)
LPTFNAMEBUF	DB	fnamelen DUP(0)
INPFNAMEBUF	DB	fnamelen DUP(0)
OTHERFNAMEBUF	DB	fnamelen*(MAXFILE+1) DUP(0)

EXTFNAMEBUF	DB	fnamelen*3 DUP(0)
  ifdef FLGEMA
    if FLG32
    else
EMAFNAMEBUF	DB	fnamelen DUP(0)
    endif
  endif

;??LABEL TABLE

	public	LABEL_TABLE
LABEL_TABLE:


;* opening

INIT:	
	;check Japanese mode?

comment %
Cut this check vecause J3100 willl stop here
	push	ds
	mov	ax,6300h
	int	21h
	mov	ax,[si]
	pop	ds
	or	al,ah
	jnz	yesjapanese

	mov	ax,cs
	mov	ds,ax
	mov	dx,offset nonjapanesemsg
	mov	ah,9
	int	21h
	mov	ax,4c01h
	int	21h
nonjapanesemsg	db	'This mode is not supported. Change to Japanese mode.',cr,lf,'$'
%

yesjapanese:
	;check CPU>=386?
  if FLG32
  	pushf
	pop	ax
	pushf
	or	ax,4000h
	push	ax
	popf
	pushf
	pop	ax
	popf
	and	ax,0c000h
	cmp	ax,4000h
	je	yes386

	mov	ax,cs
	mov	ds,ax
	mov	dx,offset badcpumsg
	mov	ah,9
	int	21h
	mov	ax,4c01h
	int	21h
  if JAPANESE
badcpumsg	db	'???? UBasic ?? 80386 ???p?ł??B',cr,lf,'$'
  else
badcpumsg	db	'This UBasic is for 32 bits CPU only.',cr,lf,'$'
  endif
yes386:
  endif
  	
	cli
	cld
	MOV	AX,DATA
	MOV	ES,AX
	mov	di,systemstacktop
	mov	cx,systemstackbtm-systemstacktop
	shr	cx,1
	mov	ax,2671h
	rep	stosw

	MOV	AX,DATA
	MOV	SS,AX
	MOV	SP,systemstackbtm
	sti

;get environment segment

	mov	si,2ch
	mov	ax,[si]
	mov	ss:[environment],ax

;get OPTION

	MOV	DI,LNUMBS
	XOR	AX,AX
	MOV	SI,80H
	LODSB
	INC	AL		;includes CR
	STOSW

	push	ax
	push	si
	mov	cx,ax
getoption10:
	lodsb
	cmp	al,'.'
	je	getoption50		;yes file name
	cmp	al,'"'
	je	getoption100		;not file name
	call	kanji1st?
	jnc	getoption20
	lodsb
	dec	cx
	jz	getoption100
getoption20:
	myloop	getoption10
	jmp	getoption100
getoption50:
	lodsw
	or	ax,2020h
	cmp	ax,'bu'
	jne	getoption100

	mov	di,lnumbs
	add	word ptr es:[di],4	;for [run"]
	mov	di,inpbuf
	mov	ax,'ur'
	stosw
	mov	ax,'"n'
	stosw
getoption100:
	pop	si
	pop	cx		
	rep	movsb

	smov	ds,ss

; get display mode

	mov	ah,0fh
	int	10h
	mov	[originalvideomode],al

; get normal cursor form
; get display size

	xor	ax,ax
	mov	es,ax
	mov	ax,es:[0460h]
	mov	cs:[curs_form],ax

	mov	ax,es:[044ah]
	mov	word ptr [chars1],ax	;must <= 255
	add	ax,ax
	mov	[chars2],ax

	xor	ax,ax
	mov	al,es:[0484h]
	mov	word ptr [btmline],ax
	inc	ax
	mov	word ptr [maxlinesnow],ax
	mov	word ptr [linesdef],ax
	mul	word ptr [chars2]
	mov	[charsall2],ax


;rewrite intterupt vectors

	smov	ds,cs

	MOV	AH,25H		;set vector
	MOV	AL,23H
	MOV	DX,OFFSET INTBREAK
	INT	21H

	MOV	AH,25H
	MOV	AL,24H
	MOV	DX,OFFSET IONOTREADY
	INT	21H

	mov	ah,35h		;get vector
	mov	al,5
	int	21h
	mov	[int5off],bx
	mov	[int5seg],es

	mov	ah,25h
	mov	al,5		;COPY key
	mov	dx,offset copykey
	int	21h

	mov	ah,35h		;get vector
	mov	al,1bh
	int	21h
	mov	[int1boff],bx
	mov	[int1bseg],es

	MOV	AH,25H
	MOV	AL,1BH
	MOV	DX,OFFSET INTBREAK
	INT	21H

	smov	es,cs
	mov	si,offset mainlp
	mov	di,offset mainlp_memo
	mov	cx,3
	rep	movsw

comment %
	mov	ah,3		;key repeat speed
	mov	al,5
	mov	bx,0104h
	int	16h
%

;check memories

	MOV	BX,CS
	SUB	BX,0010H
	MOV	DS,BX
	MOV	BX,0002H	;in PSP
	MOV	CX,[BX]		;cx=next segment
	smov	ds,ss

	mov	[vramsegover],cx

	mov	al,[linesdef]
	inc	al
	mov	ah,[chars1]
	mul	ah
	add	ax,ax
	add	ax,15
	my_shr	ax,4

	cmp	ax,310		;80chars*(30+1) lines is minimum
	jae	setvramseg
	mov	ax,310
setvramseg:
	sub	cx,ax		;for virtual VRAM

	MOV	[LIMITSEG],cx
	mov	[vramsegnow],cx

	MOV	AX,UNITWORD
	ADD	AX,7
	MY_SHR	AX,3
	
	MOV	AH,16		;minimum # of LLVARS
	MUL	AH
	ADD	AX,DATA
	JC	NOMEMORY
	ADD	AX,VARSEG
	JC	NOMEMORY
	SUB	CX,AX
	JC	NOMEMORY

	XOR	DX,DX
	MOV	AX,CX
	MOV	CX,32		;minimum # of LVARS
	DIV	CX		;now AL=segments/lvar

	MY_SHL	AX,3
	DEC	AX
	CMP	AX,LIMITWORD
	JB	MEMCHK10
	MOV	AX,LIMITWORD
MEMCHK10:
	MOV	[LVARLIMIT],AX

	push	ds
	mov	dx,DATA
	add	dx,COMMONSEG
	mov	ds,dx
	xor	bx,bx
	mov	cx,COMMONDATANUMBER
commonclearlp:
	mov	word ptr [bx],0	;clear common data area
	add	bx,UNITBYTE
	loop	commonclearlp
	pop	ds

	CMP	AX,100
	jnc	dispopeningmsg
nomemory:
	jmp	nomemoryerr	;less than 100 WORDs

;display opening message

dispopeningmsg:
	call	curs_norm
	mov	dx,offset openmsg
	call	msg

;
; decide delay timer for LIST
;

	push	ds
	xor	ax,ax
	mov	ds,ax
	mov	bx,046ch
	mov	ax,[bx]
timerlp0:
	cmp	ax,[bx]		;check tick count
	je	timerlp0

	xor	cx,cx
	xor	dx,dx
	mov	ax,[bx]
timerlp1:
	add	cx,1
	adc	dx,0
	cmp	ax,[bx]
	je	timerlp1

	mov	al,ch
	mov	ah,dl
	my_shl	ax,2		;* 4
	cmp	dx,64		;256/4
	jb	timerout
	mov	ax,0ffffh
timerout:
	mov	ss:[listtimer],ax

	pop	ds


;LOAD the constant file

	call	load_ubconst

;clear screen and goto cold start

	smov	ds,ss

	CALL	CALC_CONSOLE
	call	cursoff
	CALL	CLEAR_SCREEN
        CALL    DISP_FUNCTIONKEY

	smov	ds,ss
	smov	es,ss

  if graph
  	call	far ptr getfontserver
  endif
	call	resvar
	call	iniloop
	call	far ptr farInitwp
	CALL	far ptr farDISPWORDSUB

	JMP	COLDST

	include	\ubv9\ubconst7.asm

	org	label_table+labelall

	public	codeend
codeend:
	

CODE	ENDS


code2	segment	public
	assume	cs:code2,ds:data


public errmsgtop
ERRMSGTOP	LABEL BYTE

  if JAPANESE

SYNMSG		DB	'?v???O???????邢?͓??͂??????ɃG???[???????܂?',0
SYSTEMERRMSG	DB	'?????s???̃G???[?ł?',0
OVRMSG		DB	'???l???傫?߂??܂?',0
CALCSPMSG	DB	'?v?Z?X?^?b?N?????t?ł?',0
SPMSG		DB	'?????\???̑Ή????????????????G?߂??܂?',0
LINMSG		DB	'?g???Ȃ??s?ԍ??ł?',0
LONGMSG		DB	'???s?̒??????????𒴂??܂???',0
NOLMSG		DB	'???݂??Ȃ??s?ԍ?(???x??)???w?肵?܂???',0
manyvarmsg	DB	'?ϐ??????????܂??Basave ?? new ?????s???Ă????????B',0
FULMSG		DB	'?ϐ??̈悪???t?ɂȂ??܂???',0
DIVMSG		DB	'0 ?ŏ??Z?????܂???',0
DSKFULLMSG	DB	'?f?B?X?N?????t?ł?',0
DISKMSG		DB	'?f?B?X?N?֌W?̃G???[?ł?',0
CANNOTMSG	DB	'?ł??܂???',0
BIGPROGMSG	DB	'?e?L?X?g?̈??ɗ]?T???????܂???',0
INDMSG		DB	'?z???̓Y?????s?K???ł?',0
UNDMSG		DB	'?????`?ϐ??A?z?????Q?Ƃ??܂???',0
DBLMSG		DB	'?????z?????錾???܂???',0
TYPEMSG		DB	'?^???????Ă??܂?',0
WHILEMSG	DB	'?Ή????? while(wend) ???????܂???',0
REPEATMSG	DB	'?Ή????? repeat(until) ???????܂???',0
FORMSG		DB	'?Ή????? for(next) ???????܂???',0
GOSUBMSG	DB	'?Ή????? gosub(return) ???????܂???',0
NOFILEMSG	DB	'?t?@?C?????????܂???',0
FUNCERRMSG	DB	'?????????????Ȃ??̂Ōv?Z???ł??؂??܂???',0
NODATAMSG	DB	'?f?[?^???????????܂???',0
FORNEXTMSG	DB	'next ?̕ϐ????????Ă??܂?',0
;MISMATCHMSG	DB	'???????Z?ł͏????͎g???܂???',0
ILGFILEMSG	DB	'?t?@?C???̌^???Ⴂ?܂?',0
REOPENMSG	DB	'???ɃI?[?v?????ꂽ?t?@?C???ԍ??ł?',0
OPENERRMSG	DB	'?I?[?v???o???܂???',0
NOTOPENMSG	DB	'?I?[?v?????Ă??܂???',0
ILGLETMSG	DB	'?Z?ϐ??ɏ????͑????ł??܂???',0
NOPROGMSG	DB	'save ?????v???O???????????܂???',0
ILGMSG		DB	'?p?????[?^???s?K???ł?',0
;PROTECTMSG	DB	'???????݋֎~?ł?',0
ILGDATAMSG	DB	'?ُ??ȃf?[?^???ǂݍ??݂܂???',0
EXISTERRMSG	DB	'???̃t?@?C???͊??ɂ????܂?',0
USRERRMSG	DB	'?????`?̃??[?U?[?E???[?`???ł?',0
USRBIGMSG	DB	'?z???̃T?C?Y???????????܂?',0
STACKFULLMSG	DB	'?X?^?b?N?????t?ł?',0
STACKEMPTYMSG	DB	'?X?^?b?N?ɂ̓f?[?^???????܂???',0
USRSTKERRMSG	DB	'?X?^?b?N???ُ??ł?',0
CALCSTKERRMSG	DB	'?֐??߂??l???ݒ肵?Ă??܂???',0
LABELFULLMSG	DB	'???x???????????܂?(100?܂?)',0
DOUBLELMSG	DB	'???ɒ??`???????x???ł?',0
REVERSEMSG	DB	'?ُ??ȃv???O?????ł?',0
CANNOTMELTMSG	DB	'open ???̃t?@?C?????????܂?',0
MELTERRMSG	DB	'melt ?ł??܂???',0
NOMARKMSG	DB	'?Ή????? mark ???????܂???',0
NOLOOPMSG	DB	'?Ή????? loop(endloop) ???????܂???',0
BLOCKMSG	DB	'block ?̌????Ⴂ?܂?',0
LONGNAMEMSG	DB	'?t?@?C?????????????܂?',0
PASSERRMSG	DB	'?P???Z?ϐ??͔Ԓn?n???ł??܂???',0
pointerrmsg	db	'???????????̂? point ?̕ύX?͂ł??܂???',0
worderrmsg	db	'word ???????????܂?',0
workfullmsg	db	'???Ɨ̈悪?s?????Ă??܂?',0
blockbusymsg	db	'block ?̃l?X?g?͂ł??܂???',0
localerrmsg     db      '???? local ?錾?o???Ȃ??ϐ????????܂?',0
moderrmsg	db	'modulus ???Ⴂ?܂?',0
emafullmsg	db	'ema ?̗̈悪???t?^?ُ??ł?',0
vmodeerrmsg	db	'video mode ???Ⴂ?܂?',0
floaterrmsg	db	'point ???????????܂?',0
nooverloadmsg	db	'???Z???????`?ł?',0
conditionerrmsg	db	'?????????s???S?ł?',0

  else

SYNMSG		DB	'Syntax error',0
SYSTEMERRMSG	DB	'System error',0
OVRMSG		DB	'Overflow',0
CALCSPMSG	DB	'Calculation stack full',0
SPMSG		DB	'loop too complicated/illegal',0
LINMSG		DB	'Illegal Line number',0
LONGMSG		DB	'Line too long',0
NOLMSG		DB	'Undefined line number/label',0
manyvarmsg	DB	'Variables too many. Asave the program and do New.',0
FULMSG		DB	'Variable area full.',0
DIVMSG		DB	'Division by zero',0
DSKFULLMSG	DB	'Disk full',0
DISKMSG		DB	'Disk error',0
CANNOTMSG	DB	'Cannot do',0
BIGPROGMSG	DB	'Text area full',0
INDMSG		DB	'Illegal array index',0
UNDMSG		DB	'Undefined array/variable',0
DBLMSG		DB	'Array already defined',0
TYPEMSG		DB	'Type mismatch',0
WHILEMSG	DB	'No while(wend)',0
REPEATMSG	DB	'No repeat(until)',0
FORMSG		DB	'No for(next)',0
GOSUBMSG	DB	'No gosub',0
RETURNMSG	DB	'No return',0
NOFILEMSG	DB	'No file',0
FUNCERRMSG	DB	'Series not converge',0
NODATAMSG	DB	'No data',0
FORNEXTMSG	DB	'Illegal next variable',0
;MISMATCHMSG	DB	'Must be integer for \',0
ILGFILEMSG	DB	'File type mismatch',0
REOPENMSG	DB	'Already opened',0
OPENERRMSG	DB	'Cannot open',0
NOTOPENMSG	DB	'Not yet opened',0
ILGLETMSG	DB	'Must be integer',0
NOPROGMSG	DB	'No program to save',0
ILGMSG		DB	'Illegal parameter',0
PROTECTMSG	DB	'Write protected',0
ILGDATAMSG	DB	'Read bad data',0
EXISTERRMSG	DB	'Already exists',0
USRERRMSG	DB	'Undefined user routine',0
USRBIGMSG	DB	'Array size too small',0
STACKFULLMSG	DB	'Stack full',0
STACKEMPTYMSG	DB	'No data in Stack',0
USRSTKERRMSG	DB	'Stack mismatch',0
CALCSTKERRMSG	DB	'Lack of return value',0
LABELFULLMSG	DB	'Labels too many(>100)',0
DOUBLELMSG	DB	'Label duplicate defined',0
REVERSEMSG	DB	'Illegal program',0
CANNOTMELTMSG	DB	'Opened file exists',0
MELTERRMSG	DB	'Cannot melt',0
NOMARKMSG	DB	'No corresponding mark',0
NOLOOPMSG	DB	'No corresponding loop(endloop)',0
BLOCKMSG	DB	'Different members of blocks',0
LONGNAMEMSG	DB	'Too long file name',0
passerrmsg	db	'Simple short cannot be passed by address',0
pointerrmsg	db	'Fractional number exists',0
worderrmsg	db	'Word must be bigger',0
workfullmsg	db	'Lack of work area',0
blockbusymsg	db	'Block cannot be nested',0
localerrmsg     db      'There is a variable that cannot be LOCAL',0
moderrmsg	db	'Illegal modulus',0
emafullmsg	db	'ema area full/illegal',0
vmodeerrmsg	db	'Different video mode',0
floaterrmsg	db	'Point too small',0
nooverloadmsg	db	'Operator undefined',0
conditionerrmsg	db	'Incomplete condition',0

  endif

ERRMSGEND	DB	0
public errmsgend

code2	ends


MYSTACK	SEGMENT	STACK	'STACK'

	DW	10H DUP(0)

MYSTACK ENDS

END
