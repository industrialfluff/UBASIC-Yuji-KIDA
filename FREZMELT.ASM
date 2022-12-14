;frezmelt.asm

;Note here in CODE2 segment

	extrn	newPRNCHG2FIN:near
	extrn	EMAusing:near

;*
;* FREEZE
;*

goEMAusingerr:
	jmp	EMAusing
goNOPROG:
	jmp	far ptr noprog

farFREEZEIN:
  if GRAPH
    if FLGIBMTOS
	call	return2text
    endif
  endif
	cmp	[emahandle],0
	jne	goEMAusingerr
	mov	ax,code
	mov	es,ax
	mov	es:[freezed_sp],sp
	smov	es,ss
	CALL	MEMO_TIME
	CMP	[TXTEND],TXTHED+1
	JZ	goNOPROG	;no program in memory

	mov	ah,0dh
	int	21h		;flush disk buffer

	CMP	BYTE PTR [BP],'"'
	JE	FREEZE20	;FILE assigned
	CALL	SETUBICE	;default file
	JMPS	FREEZE30
FREEZE20:
	CALL	far ptr farSETFNAME	;make PATH name
	mov	al,[di-2]
	cmp	al,':'
	je	freeze25	;no file name
	cmp	al,'\'
	jne	freeze30	;no file name
freeze25:
	mov	al,'U'
	mov	[di-1],al
	mov	al,'B'
	stosb
	mov	al,'.'
	stosb
FREEZE30:
	CALL	EXTICE
	CALL	FREEZEMAIN
	retf


	;MEMO CURRRENT TIME

MEMO_TIME:
	MOV	AH,2AH
	INT	21H
	MOV	[DATE2],AL

	mov	ah,2ch		;get TIME
	int	21h

	MOV	[HOUR2],CH
	MOV	[MINUTE2],CL
	MOV	[SECOND2],DH
	RET	


FREEZEMAIN:
	MOV	AH,3CH		;MAKE HANDLE
	MOV	DX,OFFSET FNAMEBUF
	MOV	CX,0
	INT	21H

	jnc	frezm5
	jmp	far ptr protected	;do not close other files

frezm5:
	MOV	BX,AX		;HANDLE
FREZM10:
	MOV	SS:[HANDLE],BX

	;CHECK DISK FREE SPACE

	MOV	AX,OFFSET CS_DATA
	SUB	AX,15
	my_SHR	AX,4
	MOV	SI,code
	ADD	AX,SI

	MOV	SI,SS
	SUB	SI,AX
	MOV	CX,SI

	ADD	CX,80H		;WORK AREA OF RND

	add	cx,1000h	;save all DS=SS

	mov	ax,ss:[charsall2]
	my_shr	ax,4
	add	cx,ax
  if FLG98
	add	cx,ax		;attributes
	add	cx,worksegsize
  endif

	MOV	AX,SS:[arrayseg]
	MOV	SI,SS
	SUB	AX,SI
	SUB	AX,1000H
	ADD	AX,07FFH
	AND	AX,0F800H	
	ADD	CX,AX
	INC	CX		;CX=SEGMENT SIZE
	PUSH	CX

	smov	ds,ss
	CALL	far ptr farDISKFREE
	REPT	4
	SHR	DX,1
	RCR	AX,1
	ENDM

	POP	CX
	OR	DX,DX
	JNZ	CS_SAVE		;16MB à»è„Ç†ÇÈ
	CMP	AX,CX
	JAE	CS_SAVE

	MOV	SS:[HANDLE],0
	jmp	far ptr WRITEFULL	;CLOSE Ç∑ÇÈ

	;CS SAVE
CS_SAVE:
	mov	ax,code
	mov	ds,ax
	XOR	SI,SI
	MOV	[SI],ax		;SAVE CS
	MOV	SI,2
	CALL	FREZSUB

	mov	ax,code
	mov	ds,ax
	MOV	SI,80H
	CALL	FREZSUB		;SAVE RANDOM NUMBER WORK AREA

	MOV	AX,OFFSET CS_DATA
	SUB	AX,15
	MY_SHR	AX,4
	MOV	SI,code
	ADD	AX,SI
	MOV	DS,AX

	MOV	SI,code2
	SUB	SI,AX
	MY_SHL	SI,4
	CALL	FREZSUB

	;save code2 fully(data area must be separated in the future)

	MOV	AX,code2
	MOV	DS,AX

	MOV	SI,SS
	SUB	SI,AX
	MY_SHL	SI,4
	CALL	FREZSUB

	;DS=SS SAVE

	MOV	AX,SS		;save stack area 1st
	add	ax,0f00h
	MOV	DS,AX
	MOV	SI,1000h
	CALL	FREZSUB

	smov	ds,ss		;save DS=SS area next
	MOV	SI,0f000h
	CALL	FREZSUB

	;VRAM SAVE

	MOV	ds,ss:[vramsegnow]
	MOV	SI,ss:[charsall2]	;160*maxlines2
	CALL	FREZSUB
  if FLG98
	mov	ax,ds			;attributes
	add	ax,200h
	mov	ds,ax
	MOV	SI,ss:[charsall2]	;160*maxlines2
	CALL	FREZSUB
  endif

	;ARRAY & USER STACK SAVE
  if FLG98
	mov	ax,WINDOWSEG
	mov	ds,ax
	mov	si,WORKSIZE
	call	frezsub
  endif
	MOV	SI,8000H	;SAVE by 8000h bytes each
	MOV	AX,SS
	ADD	AX,1000H	;skip data area(already saved)
FREZMLP:
	CMP	AX,SS:[arrayseg]
	JAE	FREZMOUT
	MOV	DS,AX
	CALL	FREZSUB
	MOV	AX,DS
	ADD	AX,800H
	JMP	FREZMLP
FREZMOUT:
	smov	ds,ss
	MOV	AH,3EH		;CLOSE HANDLE
	INT	21H
	MOV	[HANDLE],0
	ret


FREZSUB:
	MOV	CX,SI		;SIZE
	XOR	DX,DX		;BASE ADR =0
	MOV	AH,40H		;WRITE HANDLE
	INT	21H
	JC	goSAVEERR1
	CMP	AX,CX
	JC	goSAVEERR3	;DISK FULL
	RET

gosaveerr1:
	jmp	saveerr1
gosaveerr3:
	jmp	saveerr3

;*
;* MELT
;*

goCANNOTMELT:
	jmp	far ptr cannotmelt


farMELTIN:
  if GRAPH
    if FLGIBMTOS
	call	return2text
    endif
  endif
	CMP	[TXTEND],TXTHED+1
	MOV	SI,OFFSET HANDLE
	MOV	CX,MAXFILE+1
MELT10:
	LODSW
	OR	AX,AX
	LOOPZ	MELT10
	JNZ	goCANNOTMELT	;OPENED FILE exists

	CALL	far ptr farCHGOUT_INIT	;init redirection
	CMP	BYTE PTR [BP],'"'
	JE	MELT20
	CALL	SETUBICE
	JMPS	MELT30
MELT20:
	CALL	far ptr farSETFNAME	;make PATH name
	mov	al,[di-2]
	cmp	al,':'
	je	melt25		;no file name
	cmp	al,'\'
	jne	melt30		;no file name
melt25:
	mov	al,'U'
	mov	[di-1],al
	mov	al,'B'
	stosb
	mov	al,'.'
	stosb
MELT30:
	CALL	EXTICE
	jmp	MELTMAIN 	;do not CALL(stack will be destroyed)

melt40:
  if DISPFKEY
	cmp	[functionkey_sw],1
	jne	melt50
	call	far ptr farDISP_functionkey
	jmps	melt60
melt50:
	call	far ptr farCLEAR_functionkey
melt60:
  endif
  if FLG98;+FLGIBM
  else
  	CALL	DISP_REVIVE
  endif
;  ifdef FLGDOSV
;	xor	bx,bx
;	mov	dl,ss:[xpos]
;	mov	dh,ss:[ypos]
;	mov	ah,2
;	int	10h			;set cursor position
 ; endif
	CALL	CHGOUT_REVIVE
	CALL	EXT_REVIVE
	CALL	WRTFILE_REVIVE
	CALL	READFILE_REVIVE
	CALL	TIME_REVIVE
	retf

goMELTERR:
	jmp	far ptr melterr

goMELTERR1:
	CMP	AX,2
	JZ	goNOFILE
	JMP	far ptr DISKERR
goNOFILE:
	jmp	far ptr nofile

  if FLGIBMTOS
diffvmode:
	extrn	vmodeerr:far

	push	ss
	pop	ds
	mov	[originalvideomode],al
	mov	[graphflg],1
	call	return2text		;init text parameters
	jmp	far ptr vmodeerr
  endif


MELTMAIN:
	;open file

	MOV	AH,3DH		;OPEN HANDLE
	MOV	AL,0		;FOR READ
	MOV	DX,OFFSET FNAMEBUF
	INT	21H
	JC	goMELTERR1

  IF FLG98;+FLGIBM
  else
	call	far ptr farCLEAR_SCREEN
  endif

	;CS LOAD

	MOV	BX,AX
	mov	ax,code
	mov	ds,ax
	MOV	SI,2
	CALL	MELTSUB
	XOR	SI,SI
	MOV	AX,[SI]
	MOV	SI,code
	CMP	AX,SI
	JNZ	goMELTERR	;MEMORY LOCATION ERROR

	mov	ax,code
	mov	ds,ax
	MOV	SI,80H
	CALL	MELTSUB		;LOAD RANDOM NUMBER WORK AREA

	MOV	AX,OFFSET CS_DATA
	SUB	AX,15
	my_SHR	AX,4
	MOV	SI,code
	ADD	AX,SI
	MOV	DS,AX

	MOV	SI,code2
	SUB	SI,AX
	my_SHL	SI,4
	CALL	MELTSUB

	MOV	AX,code2
	MOV	DS,AX

	MOV	SI,SS
	SUB	SI,AX
	my_SHL	SI,4
	CALL	MELTSUB

	;SS LOAD

	mov	ax,code
	mov	es,ax
	mov	sp,es:[freezed_sp]	;1st load stack area
	smov	ds,ss		;to other place
	smov	es,ss
	MOV	SI,1000h	;to guard current stack area
	CALL	MELTSUB
	mov	ax,ss		;move to correct
	add	ax,0f00h	;address
	mov	es,ax
	xor	si,si
	xor	di,di
	mov	cx,0800h
	rep	movsw
	smov	ds,ss		;load other DS=SS
	MOV	SI,0f000h
	CALL	MELTSUB

	;VRAM LOAD

  if FLGIBMTOS
	mov	ah,0fh
	int	10h
	cmp	al,ss:[originalvideomode]
	jne	diffvmode
  endif

  if FLG98
	mov	al,[maxlinesnow]
	mov	dx,offset lines1msg
	cmp	al,maxlines1
	je	meltm45
	mov	dx,offset lines2msg
meltm45:
	smov	ds,cs
	mov	ah,9
	int	21h	
	smov	ds,ss
  endif	

	MOV	ds,ss:[vramsegnow]
	MOV	SI,ss:[charsall2]	;160*maxlines2
	CALL	MELTSUB
;  ifdef FLGDOSV
;	mov	es,ss:[vramsegnow]
;	xor	di,di
;	mov	cx,ss:[charsall2]
;	shr	cx,1
;	mov	ah,0ffh
;	int	10h			;DOS/V call
 ; endif

  if FLG98
	mov	ax,ds
	add	ax,200h
	mov	ds,ax
	MOV	SI,ss:[charsall2]	;160*maxlines2
	CALL	MELTSUB
  endif

	;ARRAY & USER STACK LOAD

  if FLG98
	mov	ax,WINDOWSEG
	mov	ds,ax
	mov	si,WORKSIZE
	call	meltsub
  endif
	MOV	SI,8000H	;SAVE UNIT
	MOV	AX,SS
	ADD	AX,1000H
MELTMLP:
	CMP	AX,SS:[arrayseg]
	JAE	MELTMOUT
	MOV	DS,AX
	CALL	MELTSUB
	OR	AX,AX
	JZ	MELTMOUT
	MOV	AX,DS
	ADD	AX,800H
	JMP	MELTMLP
MELTMOUT:
	smov	ds,ss
	smov	es,ss
	MOV	AH,3EH		;close handle
	INT	21H
	MOV	[HANDLE],0	;reset
	jmp	melt40

MELTSUB:
	MOV	CX,SI		;SIZE
	XOR	DX,DX		;BASE ADR
	MOV	AH,3FH		;READ HANDLE
	INT	21H
	RET

SETUBICE:	
	MOV	DI,OFFSET FNAMEBUF
	MOV	AX,'BU'
	STOSW
	MOV	AL,'.'
	STOSB
	RET


EXTICE:
	MOV	AX,'CI'
	STOSW
	MOV	AL,'E'
	XOR	AH,AH
	STOSW
	RET	


  if FLG98;+FLGIBM
  else
	;âÊñ ïúãA

DISP_REVIVE:
  if FLGFMR
  	mov	dx,0101h
  	mov	ah,0dh
	int	91h		;set cursor home
  endif
  if FLGIBMTOS
	xor	dx,dx
	mov	ah,2
	int	10h		;set cursor home
  endif
	mov	ds,ss:[vramsegnow]
	xor	si,si
	xor	dx,dx
	mov	cx,word ptr ss:[maxlinesnow]
	dec	cx
DISPREV10:
	push	cx
	mov	cx,word ptr ss:[chars1]
disprev20:
	LODSW
	int	29h
	myloop	DISPREV20
	pop	cx
	myloop	DISPREV10
	smov	ds,ss
	call	far ptr farCURSOR
	ret

  endif

	;reset TIMER

TIME_REVIVE:

	MOV	AH,2AH
	INT	21H
	PUSH	AX		;AL=WEEK

	mov	ah,2ch		;get TIME
	int	21h

	POP	AX
	ADD	DH,[SECOND]
	CMP	DH,60
	JB	TMRV10
	SUB	DH,60
	INC	CL
TMRV10:
	ADD	CL,[MINUTE]
	CMP	CL,60
	JB	TMRV20
	SUB	CL,60
	INC	CH
TMRV20:
	ADD	CH,[HOUR]
	CMP	CH,24
	JB	TMRV30
	SUB	CH,24
	INC	AL
TMRV30:
	ADD	AL,[DATE]
	CMP	AL,7
	JB	TMRV40
	SUB	AL,7
TMRV40:
	SUB	DH,[SECOND2]
	JNB	TMRV110
	ADD	DH,60
TMRV110:
	SBB	CL,[MINUTE2]
	JNB	TMRV120
	ADD	CL,60
TMRV120:
	SBB	CH,[HOUR2]
	JNB	TMRV130
	ADD	CH,24
TMRV130:
	SBB	AL,[DATE2]
	JNB	TMRV140
	ADD	AL,7
TMRV140:
	MOV	[SECOND],DH
	MOV	[MINUTE],CL
	MOV	[HOUR],CH
	MOV	[DATE],AL		
	RET


	;recover input files

READFILE_REVIVE:
	MOV	CX,MAXFILE+1
READFR10:
	PUSH	CX
	MOV	SI,CX
	SHL	SI,1
	CMP	BYTE PTR [SI+HANDLE+1],1
	JNE	READFR20	;no READ OPEN file
	PUSH	SI
	my_SHL	SI,4
	ADD	SI,OFFSET OTHERFNAMEBUF
	CALL	READREVSUB
	POP	BX
	MOV	BYTE PTR [BX+HANDLE],AL
	SHL	BX,1
	MOV	DX,[BX+FILEPTR]
	MOV	CX,[BX+FILEPTR+2]
	MOV	BX,AX		;HANDLE
	MOV	AH,42H		;recover POINTERs
	MOV	AL,0
	INT	21H
READFR20:
	POP	CX
	myloop	READFR10
	RET


READREVSUB:
	;COPY FILE NAME

	mov	ax,code
	mov	ds,ax
	MOV	DI,OFFSET FNAMEBUF
	MOV	CX,fnamewordlen
	REP	MOVSW
	smov	ds,ss

	;OPEN FOR READ

	MOV	AH,3DH		;OPEN HANDLE
	MOV	AL,0
	MOV	DX,OFFSET FNAMEBUF
	INT	21H	
	JC	READREVNOFILE	;no file
	RET

READREVNOFILE:
	MOV	DX,OFFSET FNAMEBUF
	CALL	msg2
	JMP	far ptr NOFILE


	;recover output files

WRTFILE_REVIVE:
	MOV	CX,MAXFILE+1
WRTFR10:
	PUSH	CX
	MOV	SI,CX
	SHL	SI,1
	MOV	BX,SI
	ADD	BX,OFFSET HANDLE
	CMP	BYTE PTR [BX+1],2
	JNE	WRTFR20		;no WRITE OPEN files
	PUSH	BX
	my_SHL	SI,4
	ADD	SI,OFFSET OTHERFNAMEBUF
	CALL	WRTREVSUB
	MOV	AL,BL
	MOV	AH,2
	POP	BX
	MOV	[BX],AX
WRTFR20:
	POP	CX
	myloop	WRTFR10
	RET


WRTREVSUB:
	;COPY FILE NAME

	mov	ax,code
	mov	ds,ax
	MOV	DI,OFFSET FNAMEBUF
	MOV	CX,fnamewordlen
	REP	MOVSW
	smov	ds,ss

	;OPEN FOR R/W

	MOV	AH,3DH		;OPEN HANDLE
	MOV	AL,2
	MOV	DX,OFFSET FNAMEBUF
	INT	21H	
	JC	WRTREVNOFILE	;no file

	MOV	BX,AX		;HANDLE
	MOV	AH,42H		;set POINTER to FILE END
	MOV	AL,2
	XOR	CX,CX
	XOR	DX,DX
	INT	21H
	RET

WRTREVNOFILE:
	MOV	DX,OFFSET FNAMEBUF
	CALL	msg2
	JMP	far ptr NOFILE


	;recover redirection

CHGOUT_REVIVE:
	TEST	[PRN_DEV],BIT2
	JZ	CHGR20
	MOV	SI,OFFSET PRNFNAMEBUF
	CALL	CHGRSUB
	MOV	[PRNHANDLE],AX
CHGR20:
	TEST	[LPT_DEV],BIT3
	JZ	CHGR30
	MOV	SI,OFFSET LPTFNAMEBUF
	CALL	CHGRSUB
	MOV	[LPTHANDLE],AX
CHGR30:
	TEST	[INP_DEV],BIT4
	JZ	CHGRRET
	MOV	SI,OFFSET INPFNAMEBUF
	CALL	READREVSUB
	mov	[inphandle],ax

	MOV	DX,[INPFILEPTR]
	MOV	CX,[INPFILEPTR+2]
	MOV	BX,AX		;HANDLE
	MOV	AH,42H		;recover POINTERs
	MOV	AL,0
	INT	21H
CHGRRET:
	RET

CHGRSUB:			;redirect to file
	mov	ax,code
	mov	ds,ax
	MOV	DI,OFFSET FNAMEBUF
	MOV	CX,fnamewordlen
	REP	MOVSW
	smov	ds,ss
	MOV	AH,3DH
	MOV	AL,2
	MOV	DX,OFFSET FNAMEBUF
	INT	21H
	JC	CHGR110
	jmp	newPRNCHG2FIN		;call & ret


CHGR110:
	MOV	DX,OFFSET FNAMEBUF
	CALL	msg2
	JMP	far ptr NOFILE


	;recover external arrays

EXT_REVIVE:
	CMP	[HANDLE1],0
	JE	EXTRV20
	MOV	SI,OFFSET EXTFNAMEBUF
	CALL	EXT_REVIVESUB
	MOV	[HANDLE1],AX
EXTRV20:
	CMP	[HANDLE2],0
	JE	EXTRV30
	MOV	SI,OFFSET EXTFNAMEBUF+32
	CALL	EXT_REVIVESUB
	MOV	[HANDLE2],AX
EXTRV30:
	CMP	[HANDLE3],0
	JE	EXTRVRET
	MOV	SI,OFFSET EXTFNAMEBUF+64
	CALL	EXT_REVIVESUB
	MOV	[HANDLE3],AX
EXTRVRET:
	RET


EXT_REVIVESUB:
	mov	ax,code
	mov	ds,ax
	MOV	DI,OFFSET FNAMEBUF
	MOV	CX,fnamewordlen
	REP	MOVSW
	smov	ds,ss

	;OPEN FOR R/W
EXTRV100:
	MOV	AL,2
EXTRV110:
	MOV	AH,3DH		;OPEN HANDLE
	MOV	DX,OFFSET FNAMEBUF
	INT	21H	
	JNC	EXTRV120
	CMP	AX,5		;READ ONLY ?
	JNE	EXTRVERR
	MOV	AL,0
	JMP	EXTRV110	;OPEN FOR READ		
EXTRV120:
	RET

EXTRVERR:
	MOV	DX,OFFSET FNAMEBUF
	CALL	msg2
	JMP	far ptr NOFILE

