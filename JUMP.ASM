;JUMP.ASM

	INCLUDE	UBDEF.H
	INCLUDE	UB.H


DATA	SEGMENT	WORD PUBLIC
	public	contadr,contcsp
	public	overloadaddadr,overloadsubadr,overloadmuladr
	public	overloaddivadr,overloadidivadr,overloadratdivadr
	public	overloadmodadr,overloadpoweradr

	EXTRN	compilegoto_sw:BYTE,compilejp_sw:BYTE
	extrn	compilevar_sw:byte,directflg:byte,schoolflg:byte
	EXTRN	CALCSP:WORD,UNLPT:BYTE
	EXTRN	MAXWORD:WORD,maxall:word,pointword:word
	EXTRN	ENDMEM:WORD,STACKPTR:WORD
	EXTRN	TXTTOP:WORD,TXTEND:WORD,calcsp_limit:word
	extrn	base_sp:word,editptr:word
	extrn	labelend:word
	extrn	arrayseg:word,limitseg:word,emanow:word
	extrn	out_dev:byte,contout_dev:byte


contadr		dw	?
contcsp		dw	?	;calcsp

overloadaddadr	dw	0
overloadsubadr	dw	0
overloadmuladr	dw	0
overloaddivadr	dw	0
overloadidivadr	dw	0
overloadratdivadr	dw	0
overloadmodadr	dw	0
overloadpoweradr	dw	0


DATA	ENDS



CODE	SEGMENT PUBLIC
	ASSUME	CS:CODE,DS:DATA

; following values are illegal values for attribute
; thus can be used for IDmark for passing parameteres

markofadr	equ	0ff00h
markofarray	equ	0ff01h


;PUBLIC LABELS

	PUBLIC	ENDIN,CANCEL,FUNCTION,GOSUB,RETURN,WHILE,WEND
	PUBLIC	REPEAT,UNTIL,FORIN,NEXT,DATAIN,contin
	PUBLIC	GOTO,RUN,JUMPIN,LOOPIN,ENDLOOP
	PUBLIC	HEXCX
	PUBLIC	IFIN,THENIN,ELSEIN,ELSEIFIN,IF2IN
	public	PASSTOKEN,farPasstoken,pasnxt_rem,farpass1sentence
	public	deffnreturn

	public	setoverloadadr
	public	overloadadd,overloadsub,overloadmul
	public	overloaddiv,overloadidiv,overloadratdiv
	public	overloadmod,overloadpower
	public	farpush_calcstack,farpop_calcstack

;EXTERNAL LABELS
	EXTRN	MAINLP:NEAR,LPRNSUB:NEAR,READY:NEAR
	EXTRN	FORMUL:NEAR,KAKKO:NEAR
	EXTRN	BACKSP:NEAR,AHEDSP:NEAR,INTER1:NEAR,SRCLIN:NEAR
	EXTRN	INILOOP:NEAR,DIMSUB:NEAR
	EXTRN	farINITWP:far,LINEND:NEAR,GO_ENDIN:NEAR
	EXTRN	SUBIN:NEAR,chg2cap:near
	EXTRN	LWADD:NEAR,LWSUB:NEAR,CLOSEALL:NEAR
	extrn	LOADMP:NEAR
	EXTRN	GETSAVADR:NEAR,GETLAVADR:NEAR,GETLLAVADR:NEAR
	EXTRN	PUSHSHORTSUB:NEAR,PUSHLONGSUB:NEAR
	EXTRN	POPSHORTSUB:NEAR,POPLONGSUB:NEAR,POPXLONGSUB:NEAR
	extrn	CHGOUT_INIT:near
	extrn	resvar:near,kanji1st?:near
	extrn	compilevar:near
	extrn	discompileall:near,discompilejp:near
	extrn	discompilegoto:near,discompilevar:near
	extrn	MAKE_LABEL_TABLE:near,getlabeladr:near
	extrn	label_table:byte

	EXTRN	FORSP:WORD,FORSPEND:WORD
	EXTRN	GOSUBSP:WORD,GOSUBSPEND:WORD

	EXTRN	SYNERR:NEAR,NOFOR:NEAR,NOWHILE:NEAR,SPERR:NEAR
	EXTRN	OVRERR:NEAR,NOGOSUB:NEAR,conterr:near,labelfull:near
	EXTRN	CALCSTKERR:NEAR,USRSTKERR:NEAR,ILGLET:NEAR
	EXTRN	NORETURN:NEAR,NONEXT:NEAR,NOWEND:NEAR,NOUNTIL:NEAR
	EXTRN	NOREPEAT:NEAR,NOLERR:NEAR,FORNEXTERR:NEAR
	EXTRN	ILGERR:NEAR,NOFILE:NEAR,DISKERR:NEAR,BIGPROG:NEAR
	EXTRN	NOMARK:NEAR,NOLOOP:NEAR,STACKFULL:NEAR,STACKEMPTY:NEAR
	EXTRN	UNDEFERR:NEAR,TYPEERR:NEAR,PASSERR:NEAR,fullerr:near
        extrn   localerr:near,cantdo:near,nooverload:near
	extrn	conditionerr:near


;
;☆次の行までスキップ(REM 行用)
;全てアスキーコードとみなす

PASNXT_REM:
	MOV	AX,[BP]
	OR	AX,AX
	JZ	PASNXT_REMIN
	MOV	BP,AX
	JMP	MAINLP

PASNXT_REMIN:
	MOV	SI,BP		;change pointer
	inc	si		;PASS 2 BYTES WORK
pasnxt_rem5:
	inc	si
PASNXT_REM10:
	LODSB
	CMP	AL,CR
	JNE	PASNXT_REM10

	mov	dx,si		;memo CRadr+1
	LODSW
	OR	AX,AX
	JZ	GO_GO_ENDIN	;実行終了

	ADD	SI,3		;PASS LINE#
	MOV	AL,[SI]
	CMP	AL,NCODE_LABEL
	JNE	PASNXT_REM20
				;PASSLABEL
	INC	SI
	LODSB
	XOR	AH,AH
	ADD	AX,2
	ADD	SI,AX
PASNXT_REM20:
	cmp	byte ptr [si],98h
	je	pasnxt_rem5
	mov	si,dx
	dec	si
	MOV	[BP],SI		;CR adr次の行の先頭をセット
	MOV	[compilejp_sw],-1
	MOV	BP,SI
	JMP	MAINLP

GO_GO_ENDIN:
	MOV	BP,SI
	JMP	GO_ENDIN


;
;☆ ＤＡＴＡ
;次の行までスキップ

DATAIN:
	MOV	SI,BP		;change pointer
	LODSB
	CMP	AL,CR
	JE	DATAPAS5B	;行の終わりなので行番号と次先頭をパス
DATALP:	
	CALL	PASSTOKEN
	LODSB
	CMP	AL,CR
	JNE	DATALP

DATAPAS5B:			;先頭 5BYTES をパス	
	LODSW
	ADD	SI,3
	OR	AX,AX
	JNZ	DATARET
	SUB	SI,6		;CR の位置にする
DATARET:
	MOV	BP,SI
	JMP	MAINLP

;
;☆ＣＡＮＣＥＬの処理
;

CANCEL:	
	MOV	AL,[BP]
	INC	BP
	CMP	AL,89H		;FOR
	JE	CANFOR
	JMP	SYNERR

CANFOR:	
	MOV	BX,CS:[FORSP]
	CMP	BX,OFFSET FORSP
	JBE	CANF_ERR	;FOR がないのに CANCEL した
	SUB	BX,forunitbyte
	MOV	CS:[FORSP],BX
	CMP	BYTE PTR [BP],0C2H	;code of ,
	JNE	CANFOUT
	INC	BP
	JMP	CANCEL
CANFOUT:
	JMP	MAINLP
CANF_ERR:
	JMP	NOFOR


;
;* operator overload
;

setoverloaddefault:
	inc	bp
	mov	word ptr [bx],0
	jmp	mainlp

setoverloadsynerr:
	jmp	synerr

setoverloadadd:
	inc	bp
	mov	ax,[bp]
	cmp	ah,CR
	je	setoverloaddefault
	cmp	ah,0c0h		;code of ':'
	je	setoverloaddefault
	cmp	ax,0b3d1h	;code of '=fn'
	jne	setoverloadsynerr
	winc	bp
	jmp	setoverloadjp

setoverloadadr:
	mov	al,[bp]
	mov	bx,offset overloadaddadr
	cmp	al,codeofadd
	je	setoverloadadd
	mov	bx,offset overloadsubadr
	cmp	al,codeofsub
	je	setoverloadin
	mov	bx,offset overloadmuladr
	cmp	al,codeofmul
	je	setoverloadin
	mov	bx,offset overloaddivadr
	cmp	al,codeofdiv
	je	setoverloadin
	mov	bx,offset overloadidivadr
	cmp	al,codeofidiv
	je	setoverloadin
	mov	bx,offset overloadratdivadr
	cmp	al,codeofratdiv
	je	setoverloadin
	mov	bx,offset overloadmodadr
	cmp	al,codeofmod
	je	setoverloadin
	mov	bx,offset overloadpoweradr
	cmp	al,codeofpower
	jne	setoverloadsynerr
setoverloadin:
	inc	bp
	cmp	word ptr [bp],0b3d1h	;code of '=fn'
	jne	setoverloadsynerr
	winc	bp
setoverloadjp:
	mov	al,[bp]
	cmp	al,Ncode_LABEL
	jne	setoverloadsynerr

	push	bx
	call	getlabeladr
	pop	bx
	mov	[bx],ax
	jmp	mainlp


overload_undef:
	jmp	nooverload

overloadpower:
	mov	di,[overloadpoweradr]
	jmp	overloadin

overloadsub:
	mov	di,[overloadsubadr]
	jmp	overloadin

overloadmul:
	mov	di,[overloadmuladr]
	jmp	overloadin

overloaddiv:
	mov	di,[overloaddivadr]
	jmp	overloadin

overloadidiv:
	mov	di,[overloadidivadr]
	jmp	overloadin

overloadratdiv:
	mov	di,[overloadratdivadr]
	jmp	overloadin

overloadmod:
	mov	di,[overloadmodadr]
	jmp	overloadin

overloadadd:
	mov	di,[overloadaddadr]

overloadin:
	or	di,di
	jz	overload_undef

	push	[base_sp]
	mov	[base_sp],sp	;current base stack pointer

	push	di		;/*

	MOV	SI,CS:[GOSUBSP]
	ADD	SI,GOSUBUNITBYTE
	CMP	SI,OFFSET GOSUBSPEND-GOSUBUNITBYTE
	JA	GOSUBSPERR
	MOV	CS:[GOSUBSP],SI
	MOV	word ptr CS:[SI+4],0
	MOV	AX,[CALCSP]
	;SUB	AX,UNITBYTE
	MOV	CS:[SI+6],AX
	MOV	AX,[arrayseg]
	MOV	CS:[SI+8],AX	;variable segment now
	mov	ax,[emanow]
	MOV	cs:[SI+10],AX	;ema address_low  now
	mov	ax,[emanow+2]
	MOV	cs:[SI+12],AX	;ema address_high now
	mov	ax,[pointword]
	mov	cs:[si+14],ax
	mov	ax,cs:[FORSP]
	mov	cs:[si+16],ax

	xor	ax,ax
	call	usrpushax	;USR STACK END MARK(will be used by RETURN)

	pop	di		;*/

	cmp	byte ptr [di],'('
	jne	overloadargerr

	inc	di

	mov	bx,[gosubsp]
	mov	cs:[bx],bp	;set return address
	mov	ax,[calcsp]
	add	ax,unitbyte
	mov	[calcsp],ax
;	add	ax,unitbyte
;	mov	cs:[bx+4],ax	;base adr of parameter stack

	mov	al,[di]
	cmp	al,'&'
	je	overloadargerrdi
	call	getvalue	;call by value
	ahedsp_mac

	cmp	byte ptr [di],0c2h	;code of ','
	jne	overloadargerr
	inc	di

	mov	al,[di]
	cmp	al,'&'
	je	overloadargerrDI
	call	getvalue	;call by value
	add	[calcsp],unitbyte

;	mov	bx,[gosubsp]
;	mov	ax,[calcsp]
;	sub	ax,unitbyte
;	mov	cs:[bx+4],ax	;base adr of parameter stack

	cmp	byte ptr [di],')'
	jne	overloadargerrDI
	inc	di

	jmp	go_getlocal

overloadargerrDI:
	mov	bp,di
overloadargerr:
	jmp	ilgerr



;
;☆ ＦＮの処理
;
	myalign
FUNCTION:
	push	[base_sp]
	mov	[base_sp],sp	;current base stack pointer

	MOV	SI,CS:[GOSUBSP]
	ADD	SI,GOSUBUNITBYTE
	CMP	SI,OFFSET GOSUBSPEND-GOSUBUNITBYTE
	JA	GOSUBSPERR
	MOV	CS:[GOSUBSP],SI
	MOV	word ptr CS:[SI+4],0
	MOV	AX,[CALCSP]
	SUB	AX,UNITBYTE
	MOV	CS:[SI+6],AX
	MOV	AX,[arrayseg]
	MOV	CS:[SI+8],AX	;variable segment now
	mov	ax,[emanow]
	MOV	cs:[SI+10],AX	;ema address_low  now
	mov	ax,[emanow+2]
	MOV	cs:[SI+12],AX	;ema address_high now
	mov	ax,[pointword]
	mov	cs:[si+14],ax
	mov	ax,cs:[FORSP]
	mov	cs:[si+16],ax

	MOV	AL,[BP]
	CMP	AL,Ncode_LABEL
	JAE	GOSUB_LABEL
	JMP	SYNERR


;
; * push all the calc stacks to user stack

farpush_calcstack:
	push	es
	xor	ax,ax		;counter
	mov	si,[calcsp]
	cmp	si,LIMIT
	je	pushcalcst100
pushcalcst10:
	push	ax
	call	pushlongsub
	pop	ax
	inc	ax
	mov	si,[calcsp]
	add	si,UNITBYTE
	mov	[calcsp],si
	cmp	si,LIMIT
	jb	pushcalcst10	
pushcalcst100:
	call	usrpushax	;number of data
	mov	ax,'&'+3	;mark of calc_stack data
	call	usrpushax
	pop	es
	retf

;
; * pop all the calc stacks from user stack
;
farpop_calcstack:
	push	ds
	mov	ss:[calcsp],LIMIT
	call	usrpopax
	cmp	ax,'&'+3	;mark of calc_stack data
	jne	retusrstkerr
	call	usrpopax
	or	ax,ax
	jz	popcalcst100
popcalcst10:
	push	ax
	mov	di,ss:[calcsp]
	sub	di,UNITBYTE
	mov	ss:[calcsp],di
	call	poplongsub
	pop	ax
	dec	ax
	jnz	popcalcst10
popcalcst100:
	pop	ds
	retf


;
;☆ ＧＯＳＵＢの処理
;

GOSUBSPERR:
	JMP	SPERR
GOSUBNOLERR:
	JMP	NOLERR

	myalign
GOSUB:	
	MOV	AX,OFFSET MAINLP
	PUSH	AX		;push for return

	push	[base_sp]
	mov	[base_sp],sp	;current base stack pointer

	MOV	SI,CS:[GOSUBSP]
	ADD	SI,GOSUBUNITBYTE
	CMP	SI,OFFSET GOSUBSPEND-GOSUBUNITBYTE
	JA	GOSUBSPERR
	MOV	CS:[GOSUBSP],SI

	MOV	word ptr CS:[SI+4],0
	MOV	AX,[CALCSP]
	MOV	CS:[SI+6],AX	;no_function mark
	MOV	AX,[arrayseg]
	MOV	CS:[SI+8],AX	;array segment now
	mov	ax,[emanow]
	MOV	CS:[SI+10],AX	;ema address_low  now
	mov	ax,[emanow+2]
	MOV	CS:[SI+12],AX	;ema address_high now
	mov	ax,[pointword]
	mov	cs:[si+14],ax
	mov	ax,cs:[FORSP]
	mov	cs:[si+16],ax

	MOV	AL,[BP]
	CMP	AL,Ncode_LABEL
	JAE	GOSUB_LABEL

	;* LINE NUMBER CASE

GOSUB_LINNUM:
	INC	BP
	CMP	AL,Ncode_ADR
	JE	GOSUB_LN2ND
GOSUB_LN1ST:
	CMP	AL,NCODE1
	JNE	SYNERRSI

	;* LINE NUMBER CASE OF 1ST TIME

	MOV	CX,[BP]		;行番号をアドレスに変える
	CALL	SRCLIN
	JNZ	GOSUBNOLERR
	ADD	BX,5		;番地・番号をパスするのみ
	MOV	[compilegoto_sw],-1
	MOV	BYTE PTR[BP-1],Ncode_ADR
	MOV	[BP],BX		;飛び先番地
	LEA	SI,[BP+2]
	MOV	DI,BX
	JMP	SETARG

	;* LINE NUMBER CASE OF 2ND TIME

GOSUB_LN2ND:
	MOV	DI,[BP]		;アドレスになっている場合
	LEA	SI,[BP+2]
	JMP	SETARG

	;* LABEL CASE

GOSUB_LABEL:
	CMP	AL,NCODE_ADR2
	JE	GOSUB_LABEL2ND
	JNB	SYNERRSI

	;* LABEL CASE OF 1ST TIME

GOSUB_LABEL1ST:
	MOV	[compilegoto_sw],-1
	MOV	BYTE PTR [BP],Ncode_ADR2
	CALL	GETLABELADR
	MOV	SI,BP
	SUB	BP,2		;BP=jump address area in text
	MOV	[BP],DI		;set adr where jump adr stored
	mov	di,ax		;jump adr
	JMP	SETARG

	;* LABEL CASE OF 2ND TIME

GOSUB_LABEL2ND:
	XOR	BX,BX
	MOV	BL,[BP+1]
	ADD	BX,2
	ADD	BP,BX		;BP=jump address area in text
	LEA	SI,[BP+2]
	MOV	DI,[BP]
	mov	di,cs:[di]
	jmp	setarg

synerrsi:
	LEA	BP,[SI-1]
	JMP	ilgerr


	;
	;* set parameters in CALCSP
	;
	myalign
SETARG:
	XOR	AX,AX
	CALL	USRPUSHAX	;USR STACK END MARK(will be used by RETURN)

	CMP	BYTE PTR [SI],'('
	JE	setarg5

	cmp	byte ptr [di],'('
	je	synerrSI
setarg2:
	mov	bx,[gosubsp]
	mov	cs:[bx],si	;set return address
	jmp	go_getlocal	;no parameters
setarg3:
	inc	si
	cmp	word ptr [di],')('
	jne	synerrSI
	add	di,2
	jmp	setarg2

setarg5:
	INC	SI
	CMP	BYTE PTR [SI],')'
	je	setarg3		;no parameter
	CMP	BYTE PTR [DI],'('
	JNE	SYNERRSI

	MOV	BX,[GOSUBSP]
	mov	ax,[calcsp]
	mov	cs:[bx+4],ax	;base adr of parameter stack

	INC	DI
	push	di		;*

SETARGLP:
	MOV	AL,[SI]
	CMP	AL,'&'
	JE	SETARG10

	cmp	al,vcode1
	je	setargwholearray?
	cmp	al,vcode3
	je	setargwholearray?
	cmp	al,vcode5
	je	setargwholearray?
setarg7:
	MOV	BP,SI		;call by value
	CALL	FORMUL
	mov	si,bp
	JMP	SETARG20

setargwholearray?:
	lea	bx,[si+1]
	xor	ax,ax
	mov	al,[bx]
	inc	bx
	add	bx,ax
	mov	al,[bx]
	cmp	al,29h		;')'
	je	gosetargarray
	cmp	al,0c2h		;','
	je	gosetargarray
	jmp	setarg7

passerrsi:
	LEA	BP,[SI-1]
	jmp	passerr

gosetargarray:
	jmp	setargwholearray

SETARG10:
	mov	ax,si		;call by address
	call	ahedsp
	mov	di,si
	mov	si,ax
	mov	ax,markofadr	;address mark
	stosw
	inc	si		;pass '&'
	lodsb
	stosb			;store varcode
	cmp	al,0b3h		;code of fn
	je	setarg_fn
	cmp	al,ncode_label
	jae	setarg_proc
	SUB	AL,VCODE
	JB	go_synerrsi
	JE	passerrsi	;simple short not passed by address
	CMP	AL,6
	JAE	go_synerrsi

	xor	ax,ax
	lodsb
	mov	bx,[si]
	add	si,ax		;new text ptr

        inc     byte ptr cs:[bx-2]      ;depth of '&'-used
        mov     ax,bx
        stosw                   ;store table adr(new)
	MOV	ax,cs:[BX]	;get offset/segment
	or	ax,ax
	jz	setargundef	;undefined array
	stosw			;store it

SETARG20:
	CMP	BYTE PTR [SI],0C2H	;code of ','
	JNE	SETARGOUT
	INC	SI
	JMP	SETARGLP

setargundef:
	jmp	undeferr

go_synerrsi:
	jmp	synerrsi


setarg_proc:
	dec	si

setarg_fn:
	mov	bp,si
	mov	al,[bp]
	cmp	al,ncode_label
	je	setargfn1st
	cmp	al,ncode_adr2
	jne	go_synerrsi

setargfn2nd:
	xor	ax,ax
	inc	si
	lodsb
	add	si,ax
	lodsw
	mov	bx,ax
	mov	ax,cs:[bx]
	stosw			;store table adr
setargfnout:
	lodsw
	cmp	ax,2928H	;()
	je	setarg20
	sub	si,2
	jmp	setarg20

setargfn1st:
	mov	[compilegoto_sw],-1
	mov	byte ptr [BP],Ncode_ADR2
	push	di
	call	getlabeladr
	or	ax,ax
	jz	setargundef
	mov	si,bp
	mov	[si-2],di	;set table adr
	pop	di
	stosw			;store function adr
	jmp	setargfnout


SETARGOUT:
	CMP	BYTE PTR [SI],')'
	JNE	go_SYNERRSI
	INC	SI
	pop	di		;*

setarg100:
	MOV	BX,[GOSUBSP]
	MOV	CS:[BX],SI	;set return address

	;
	;* get parameters from CALCSP
	;
getarg:
	mov	ax,[calcsp]

	mov	bx,[gosubsp]
	mov	cx,cs:[bx+4]
	mov	[calcsp],cx
getarglp:
	push	ax		;* final calcsp

	MOV	AL,[di]
	CMP	AL,'&'
	JE	getarg10
	call	getvalue	;call by value
	ahedsp_mac
	JMP	getarg20
getarg10:
	inc	di
	call	getaddress
getarg20:
	CMP	BYTE PTR [di],0C2H	;code of ','
	JNE	getargOUT
	INC	di

	pop	ax		;*
	cmp	ax,[calcsp]
	jae	ilgerrdi	;check parameter numbers
	JMP	getargLP

ilgerrdi:
	lea	bp,[di-1]
	jmp	ilgerr

getargOUT:
	CMP	BYTE PTR [di],')'
	JNE	SYNERRdi
	INC	di

	pop	ax		;*
	cmp	ax,[calcsp]
	jne	ilgerrdi	;check parameter numbers
	mov	bx,[gosubsp]
	mov	ax,cs:[bx+4]
	mov	[calcsp],ax

go_getlocal:
	CMP	WORD PTR [DI],98C0H	;':REM'
	JNE	goloc105
	ADD	DI,2
	CALL	PASSREM_DI
	JMP	goloc110
goloc105:
	CMP	BYTE PTR [DI],CR
	JNE	goloc110
	CMP	WORD PTR [DI+1],0
	JE	SYNERRDI
	ADD	DI,6
	CMP	BYTE PTR [DI],98H	;'REM
	JNE	goloc110
	INC	DI
	CALL	PASSREM_DI
goloc110:
	mov	al,[di]
	jmp	branch

synerrdi:
	LEA	BP,[DI-1]
	JMP	ilgerr

	;*
	;* BRANCH TO LOCAL & LOCAL_DIM
	;*
branchlp:
	cmp	al,CR
	je	branch_cr
	cmp	al,0c0h		;':'
	jne	branch
	inc	di
	mov	al,[di]
	jmp	branchlp
branch_cr:
	cmp	word ptr [di+1],0
	je	synerrdi
	add	di,6
	mov	al,[di]
	jmp	branchlp

go_setlocaldim:
	jmp	setlocaldim

BRANCH:
	cmp	al,0bah		;local
	je	setlocal
	cmp	al,0a4h		;dim
	je	go_setlocaldim
	cmp	al,98h		;REM
	je	branch_rem

	MOV	BX,CS:[GOSUBSP]
	MOV	AX,[STACKPTR]
	MOV	CS:[BX+2],AX	;user stack pointer

	MOV	BP,DI
	JMP	INTER1

branch_rem:
	INC	DI
	CALL	PASSREM_DI
	mov	al,[di]
	jmp	branchlp


	;
	;* pass all values of an array
	;
setargwholearray:
	push	di
	mov	ax,si
	call	ahedsp
	mov	di,si
	mov	si,ax
	mov	ax,markofarray
	stosw

	movsb			;store varcode

	xor	ax,ax
	lodsb
	mov	bx,[si]
	add	si,ax		;new text ptr

	MOV	ax,cs:[BX]	;get offset/segment
	or	ax,ax
	jz	argwholeundef	;undefined array
	stosw			;store it
	pop	di
	jmp	setarg20

	
argwholeundef:
	jmp	undeferr


	;*
	;* SET LOCAL VARIABLES
	;*
golocalerr:
        mov     bp,bx
        jmp     localerr

SETLOCAL:
	INC	DI
	lea	bx,[di+1]
	xor	ax,ax
	mov	al,[bx]
	inc	bx
        mov     si,[bx]
        cmp     byte ptr cs:[si-2],0
        jne     golocalerr
	add	bx,ax
	cmp	byte ptr [bx],codeofequal
	jne	setlocal50
	lea	bp,[bx+1]	;initial value is assigned
	push	di
	call	formul
	pop	di
	push	bp
	call	setvaluein	;di is pointer
	pop	di
	jmp	setlocal100

setlocal50:			;initial value default(=0)
	CALL	AHEDSP
	MOV	WORD PTR [SI],0
	CALL	SETVALUEIN	;set 0

setlocal100:
	mov	al,[di]
	cmp	al,0c2h		;','
	je	setlocal
	jmp	branchlp

	;*
	;* SET LOCAL ARRAYS
	;*
setlocaldim:
	INC	DI
	push	di
	CALL	SETLARADDRESS
	POP	BP
	CALL	DIMSUB
	MOV	DI,BP
	MOV	AX,[DI]
	CMP	AL,0C2H		;','
	je	setlocaldim
	jmp	branchlp


PASSREM_DI:
	MOV	AX,[DI]
	OR	AX,AX
	JZ	PASSREMDI10
	MOV	DI,AX
	RET
PASSREMDI10:
	MOV	BX,DI
PASSREMDI20:
	INC	DI
PASSREMDI30:
	INC	DI
	MOV	AL,CR
	MOV	CX,8000H
	REPNE	SCASB
	CMP	WORD PTR [DI],0
	JE	synerrdi2
	ADD	DI,5
	CMP	BYTE PTR [DI],98H
	JNE	PASSREMDI40
	INC	DI
	MOV	AX,[DI]
	OR	AX,AX
	JZ	PASSREMDI20
	MOV	DI,AX
PASSREMDI40:
	MOV	[BX],DI
	RET


SYNERRSI2:
	LEA	BP,[SI-1]
	JMP	ilgerr

SYNERRDI2:
	LEA	BP,[DI-1]
	JMP	ilgerr

	;*
	;* SUBROUTINE FOR SET PARAMETERS
	;*

	;* CALL BY ADDRESS
getadrilgerrdi:
	lea	bp,[di-1]
	jmp	ilgerr

go_getadr_proc:
	jmp	getadr_proc

SETTYPERR:
	MOV	BP,DI
	JMP	TYPEERR

getaddress:
	call	ahedsp
	lodsw
	cmp	ax,markofadr
	jne	getadrilgerrdi

	lodsb			;varcode
	cmp	al,ncode_label
	jae	go_getadr_proc
	cmp	AL,[DI]
	JNE	SETTYPERR
	cmp	al,0b3h
	je	getadr_fn	;function case
	inc	di
        lodsw
        CALL    USRPUSHAX       ;push source table adr(new)
        lodsw
        PUSH    ax              ;*push var adr

	xor	ax,ax
	mov	al,[di]		;chars
	inc	di
	mov	bx,[di]
	add	di,ax		;new text ptr

	MOV	AX,cs:[BX]
	CALL	USRPUSHAX	;push old adr in user stack

	POP	AX		;*pop var adr
	MOV	cs:[BX],AX	;set adr
	MOV	AX,BX
	call	USRPUSHAX	;push table adr in user stack
	mov	al,'&'+1	;ah = undef
	jmp	usrpushax	;call & ret

getadr_proc:
	dec	di

getadr_fn:
	lodsw
	push	ax		;*push adr

	inc	di
	mov	bp,di
	mov	al,[bp]
	cmp	al,ncode_label
	je	getadrfn1st
	cmp	al,ncode_adr2
	je	getadrfn2nd
	jmp	synerrdi2

getadrfn2nd:
	xor	ax,ax
	inc	di
	mov	al,[di]
	inc	ax
	add	di,ax
	mov	bx,[di]
	mov	ax,cs:[bx]
	CALL	USRPUSHAX	;push old adr in user stack
	add	di,2		;pass table adr
	mov	ax,[di]
	cmp	ax,2928H	;()
	jne	getadrfnout
	winc	di
;	jmp	getadrfnout

getadrfnout:
	POP	AX		;*pop adr
	MOV	cs:[BX],AX	;set adr
	MOV	AX,BX
	call	USRPUSHAX	;push table adr in user stack
	mov	al,'&'		;ah = undef
	jmp	usrpushax	;call & ret

getadrfnLABELOVER:
	MOV	BP,SI
	JMP	LABELFULL

	public	getadrfn1st
getadrfn1st:
	mov	[compilegoto_sw],-1
	mov	byte ptr [BP],Ncode_ADR2

	mov	di,[labelend]
	lea	si,[di+labelunit]
	cmp	si,OFFSET LABEL_TABLE+LABELALL
	jae	getadrfnlabelover
	mov	byte ptr cs:[si],0ffh
	mov	[labelend],si

	mov	ax,cs
	mov	es,ax
	lea	si,[bp+1]
	xor	cx,cx
	mov	cl,[si]
	inc	cx
	rep	movsb		;copy to label area
	xor	ax,ax
	push	di		;*
	stosw			;label address
	mov	ax,ss
	mov	es,ax

	call	getlabeladr

	CALL	USRPUSHAX	;push old adr in user stack
	pop	bx		;*
	cmp	di,bx
	je	getadrfn50	;use dummy

	mov	si,[labelend]	;erase dummy
	sub	si,labelunit
	mov	[labelend],si
	mov	byte ptr cs:[si],0ffh

getadrfn50:
	mov	bx,di
	mov	[bp-2],di	;set table adr
	mov	di,bp
	mov	ax,[di]
	cmp	ax,2928H	;()
	jne	getadrfnout
	winc	di
	jmp	getadrfnout


SET_UNDEF:
	MOV	BP,SI
	JMP	UNDEFERR


SETLARADDRESS:			;local array
	MOV	AX,[DI]
	cmp	ax,0f580h	;code of ema()
	je	setlocalema
	SUB	AL,VCODE
	JB	SYNERRDI3
	CMP	AL,6
	JAE	SYNERRDI3
	TEST	AL,1
	JZ	SYNERRDI3	;not array
	INC	DI

;	xor	ax,ax
;	mov	al,[di]
	inc	di
	mov	bx,[di]
;	add	di,ax

	MOV	AX,cs:[BX]
	CALL	USRPUSHAX	;push old adr in user stack
	MOV	word ptr CS:[BX],0	;erased mark
	MOV	AX,BX
	call	USRPUSHAX	;push variable table adr
	mov	al,'&'		;ah = undef
	jmp	usrpushax	;call & ret

setlocalema:
	xor	bx,bx		;ema number
	mov	ax,[di+2]
	cmp	ax,0c1f0h	; code of '0;'		
	je	setlocalema20
	cmp	al,0f1h
	jne	setlocalema20
	cmp	word ptr [di+4],0c100h	;higher byte = 0 and ;
	jne	setlocalema20	; '0;' is omitted
	mov	bl,ah
setlocalema20:
	push	es		;*
  if FLG98
	mov	ax,emaattributeseg
  else
	mov	ax,ss
	add	ax,emaattributeseg
  endif
	mov	es,ax
	my_shl	bx,5		;attribute base addr
	mov	cx,4		;only 8 bytes are used now
setlocalema40:
	mov	ax,es:[bx]
	call	usrpushax
	add	bx,2
	myloop	setlocalema40
	mov	word ptr es:[bx-6],-1	;erased mark
	pop	es		;*
	mov	ax,bx
	call	usrpushax	;push baseadr+8
	mov	al,'&'+2	;ah = undef
	jmp	usrpushax


USRPUSHAX:
push	es
	PUSH	DI
	LES	DI,DWORD PTR [STACKPTR]
	CMP	DI,USTKSIZE-4
	JAE	USRPUSHOVR
	STOSW			;PUSH DATA
	OR	AX,AX
	JZ	USRPUSHAX10
	MOV	AX,1	
	STOSW
USRPUSHAX10:
	MOV	[STACKPTR],DI
;	MOV	AX,SS
;	MOV	ES,AX
	POP	DI
pop	es
	RET


USRPUSHOVR:
	JMP	STACKFULL

getvatyperr:
	mov	bp,di
	jmp	typeerr

SYNERRDI3:
	LEA	BP,[DI-1]
	JMP	SYNERR


getvaluearray:
	winc	si
	lodsb			;varcode
	cmp	AL,[DI]
	JNE	getvaTYPERR
	push	ax		;*push var code
	inc	di
	lodsw
	PUSH	ax		;** push source adr

	xor	ax,ax
	mov	al,[di]		;chars
	inc	di
	mov	bx,[di]
	add	di,ax		;new text ptr

	MOV	AX,cs:[BX]
	CALL	USRPUSHAX	;push old adr in user stack
	MOV	AX,[arrayseg]
	mov	cs:[bx],ax	;set new adr
	mov	es,ax
	POP	ds		;**pop source adr
	pop	ax		;*pop var code
	push	bx

	push	di
	call	movearray
	mov	ax,ss
	mov	ds,ax
	mov	es,ax
	backsp_mac		;dummy
	pop	di

	pop	ax
	call	USRPUSHAX	;push table adr in user stack
	mov	al,'&'		;ah = undef
	jmp	usrpushax	;call & ret


getvalueilgerrdi:
	LEA	BP,[dI-1]
	jmp	ilgerr

	;* CALL BY VALUE

getvalue:
	call	ahedsp
	mov	ax,[si]
	cmp	ax,markofadr
	je	getvalueilgerrdi ;address is in
	cmp	ax,markofarray
	je	getvaluearray
SETVALUEIN:                     ;called from LOCAL var set
	MOV	AL,[DI]
	SUB	AL,VCODE	;dest var type
	JB	SYNERRDI3
	CMP	AL,6
	JAE	SYNERRDI3
	shr	al,1
	jc	synerrdi3	;array is invalid
	INC	DI
	PUSH	BP		;*
	MOV	BP,DI

	OR	AL,AL
	JZ	SETSHORT
	DEC	AL
	JZ	SETLONG
	DEC	AL
	Jnz	SYNERRDI3
	jmp	SETXLONG
SETVALUE90:
	MOV	AX,SS
	MOV	ES,AX
SETVALUE100:
	MOV	DI,BP
	POP	SI		;**
	RET

SETSHORT:
	xor	ax,ax
	mov	al,[bp]
	inc	bp
	mov	bx,[bp]
	add	bp,ax

	MOV	AX,cs:[BX]
	CALL	PUSHSHORTSUB
	MOV	AX,SS
	MOV	ES,AX
	BACKSP_MAC
	MOV	AX,[SI]
	MOV	DX,AX
	TEST	AH,attribmaskhigh
	JNZ	ILG_SET		;小数の代入は不可
	AND	AX,LENMASK
	CMP	AX,1
	JB	SETSRT_10	;IF 0
	JA	SET_OVRERR

	AND	DH,80H		;符号
	MOV	AX,[SI+2]	;値
	TEST	AH,80H
	JNZ	SET_OVRERR
	OR	AH,DH
SETSRT_10:
	MOV	cs:[BX],AX	;値のセット

	mov	ax,bx
	call	usrpushax	;value adr
	xor	ax,ax
	mov	ah,vcode	;short var mark
	call	usrpushax
	JMP	SETVALUE100


ILG_SET:
	JMP	ILGERR


SETLONG:
SETLONGIN:
	xor	ax,ax
	mov	al,[bp]
	inc	bp
	mov	bx,[bp]
	add	bp,ax

	mov	bx,cs:[bx]
	MOV	DS,BX
	XOR	SI,SI
	CALL	PUSHLONGSUB
	MOV	AX,SS
	MOV	DS,AX
	BACKSP_MAC
	MOV	CX,[SI]
	AND	CX,LENMASK
	CMP	CX,[MAXWORD]
	JA	SET_OVRERR
	INC	CX
	MOV	ES,BX
	XOR	DI,DI
	REP	MOVSW		;値のセット

	mov	ax,bx
	call	usrpushax	;value segment
	xor	ax,ax
	mov	ah,vcode2	;long var mark
	call	usrpushax
	JMP	SETVALUE90


SET_OVRERR:
	JMP	OVRERR


SETXLONG:
	xor	ax,ax
	mov	al,[bp]
	inc	bp
	mov	bx,[bp]
	add	bp,ax

	mov	bx,cs:[bx]
	MOV	DS,BX
	XOR	SI,SI
	CALL	PUSHLONGSUB
	MOV	AX,SS
	MOV	DS,AX
	BACKSP_MAC
	MOV	CX,[SI]
	AND	CX,LENMASK
	INC	CX
	MOV	ES,BX
	XOR	DI,DI
	REP	MOVSW		;値のセット

	mov	ax,bx
	call	usrpushax	;segment
	xor	ax,ax
	mov	ah,vcode4	;llv mark
	call	usrpushax
	JMP	SETVALUE90


	; move array
public movearray
movearray:
	cmp	al,vcode1
	jne	movelong
moveshort:
	xor	si,si
	xor	di,di
	mov	ax,[si+4]
	inc	ax
	mul	word ptr [si+6]
	add	ax,7		;for segment calibration
	adc	dx,0		;now dx:ax = # of elements/2

	rept	3
	shr	dx,1
	rcr	ax,1	
	endm

	add	ax,arrayheadseg
	mov	dx,ax		;total segment size
	add	ax,ss:[arrayseg]
	jc	movearrayfull
	cmp	ax,ss:[limitseg]
	jae	movearrayfull
	mov	ss:[arrayseg],ax
moves40:
	cmp	dx,1000h
	jbe	moves50
	mov	cx,8000h
	rep	movsw
	mov	ax,ds
	add	ax,1000h
	mov	ds,ax
	mov	ax,es
	add	ax,1000h
	mov	es,ax
	sub	dx,1000h
	jmp	moves40
moves50:
	mov	cx,dx
	my_shl	cx,3
	rep	movsw
	ret


movearrayfull:
	jmp	fullerr

movelong:
	mov	dx,ss:[maxall]
	shl	dx,1
	cmp	al,vcode3
	je	movel10
	mov	dx,unitbyte
movel10:
	xor	si,si

	mov	ax,[si+4]
	inc	ax
	mov	di,[si+6]
	
	push	dx
	push	ax

	mul	dx
	cmp	dx,16
	jae	movearrayfull	;over 1MB
	mov	bx,ax		;memo lower word
	mov	ax,dx
	mul	di
	or	dx,dx
	jnz	movearrayfull
	xchg	ax,bx		;now ax=lower
	mul	di
	add	dx,bx
	jc	movearrayfull
	mov	bx,16
	cmp	dx,bx
	jae	movearrayfull
	div	bx
	or	dx,dx
	jz	movel20
	inc	ax
	jz	movearrayfull
movel20:
	add	ax,arrayheadseg
	jc	movearrayfull
	mov	dx,ax		;total segment size
	add	ax,ss:[arrayseg]
	jc	movearrayfull
	cmp	ax,ss:[limitseg]
	jae	movearrayfull

	pop	ax
	pop	dx		

	push	bp		;**
	mov	bp,di
	xor	di,di
	mov	cx,arrayhead/2
	rep	movsw		;copy attributes
movel30:
	mov	bx,bp
movel40:
	push	si
	mov	cx,[si]
	and	cx,lenmask
	inc	cx
	rep	movsw
	pop	si
	add	si,dx
	cmp	si,8000h
	jae	movel60
movel50:
	mov	di,si
	dec	bx
	jnz	movel40
	dec	ax
	jnz	movel30

	my_shr	di,4
	inc	di
	mov	ax,es
	add	ax,di
	mov	ss:[arrayseg],ax	

	pop	bp		;**
	ret

movel60:
	mov	cx,ds
	add	cx,0800h
	mov	ds,cx
	mov	cx,es
	add	cx,0800h
	mov	es,cx
	sub	si,8000h
	jmp	movel50


;
;* def fn = 
;
deffnreturn:
	MOV	BX,CS:[GOSUBSP]
	CMP	BX,OFFSET GOSUBSP
	JBE	RETURNERR
	MOV	AX,CS:[BX+2]
	CMP	AX,[STACKPTR]
	JNE	RETUSRSTKERR
	CALL	formul
	jmps	return10


;
;☆ＲＥＴＵＲＮの処理
;

RETURN:	
	MOV	BX,CS:[GOSUBSP]
	CMP	BX,OFFSET GOSUBSP
	JBE	RETURNERR
	MOV	AX,CS:[BX+2]
	CMP	AX,[STACKPTR]
	JNE	RETUSRSTKERR
	CMP	BYTE PTR [BP],'('
	JNE	RETURNJP
	INC	BP
	CALL	KAKKO
return10:
	MOV	BX,CS:[GOSUBSP]
RETURNJP:
	call	pop_param	;	CALLNZ	POPARG
	MOV	AX,[CALCSP]
	CMP	AX,CS:[BX+6]
	JNE	RETCALCSTKERR

	MOV	AX,CS:[BX+8]
	MOV	[arrayseg],AX	;free local array area
	MOV	AX,CS:[BX+10]
	mov	[emanow],ax
	MOV	AX,CS:[BX+12]
	mov	[emanow+2],ax
	mov	ax,cs:[bx+14]
	cmp	ax,[pointword]
	je	return50
	call	far ptr farpointsetsub
return50:
	mov	ax,cs:[bx+16]
	mov	cs:[FORSP],ax

	MOV	BP,CS:[BX]
	SUB	BX,GOSUBUNITBYTE
	MOV	CS:[GOSUBSP],BX
	pop	[base_sp]
	RET


RETURNERR:
	JMP	NOGOSUB

RETCALCSTKERR:
	JMP	CALCSTKERR
RETUSRSTKERR:
	JMP	USRSTKERR


poplocalemaadr:
	push	es		;*
  if FLG98
	mov	ax,emaattributeseg
  else
	mov	ax,ss
	add	ax,emaattributeseg
  endif
	mov	es,ax

	call	usrpopax
	mov	si,ax
	mov	cx,4		;only 8 bytes are used now
poplocalema40:
	sub	si,2
	call	usrpopax
	mov	es:[si],ax
	myloop	poplocalema40
	pop	es		;*
	jmp	pop_param


pop_param:
	call	usrpopax
	or	ax,ax
	jz	pop_param_ret
	or	al,al
	jz	popp50

        cmp     al,'&'+1
        je      popvaradr

	cmp	al,'&'+2
	je	poplocalemaadr

	call	usrpopax
	mov	si,ax
	call	usrpopax
	mov	cs:[si],ax	;rewrite table
	jmp	pop_param

popvaradr:
        call    usrpopax        ;get table adr
        mov     si,ax
        call    usrpopax
        mov     cs:[si],ax      ;rewrite table
        call    usrpopax        ;get source var adr
        mov     si,ax
        dec     byte ptr cs:[si-2]      ;depth of '&'-called
        jmp     pop_param

popp50:
	call	pop_value	;ah = var type
	jmp	pop_param
pop_param_ret:
	ret

pop_value:
	SUB	ah,VCODE	;dest var type
	JZ	POPSHORT
	sub	ah,2
	JZ	POPLONG
	JMP	POPXLONG

pop_value_ret:
	MOV	AX,SS
	MOV	DS,AX
	MOV	ES,AX
	RET


POPSHORT:
	call	usrpopax
	MOV	DI,ax
	mov	ax,cs
	mov	es,ax
	CALL	POPSHORTSUB
	JMP	pop_value_ret


ILG_POP:
	JMP	ILGERR

POPLONG:
	call	usrpopax
	MOV	ES,ax
	XOR	DI,DI
	CALL	POPLONGSUB
	JMP	pop_value_ret

POPXLONG:
	call	usrpopax
	MOV	ES,ax
	XOR	DI,DI
	CALL	POPXLONGSUB
	JMP	pop_value_ret

POPADRNOPOP:
	JMP	STACKEMPTY

POPADRSTKERR:
	JMP	USRSTKERR


USRPOPAX:
push	ds
	PUSH	SI
	LDS	SI,DWORD PTR SS:[STACKPTR]
	SUB	SI,2		;MUST CHECK FLAG
	JB	POPADRNOPOP	;NO DATA IN STACK
	MOV	AX,[SI]		;ATTRIBUTE
	CMP	AX,1
	JA	POPADRSTKERR
	JB	USRPOPAX10
	WDEC	SI
	MOV	AX,[SI]
USRPOPAX10:
	MOV	SS:[STACKPTR],SI
;	MOV	SI,SS
;	MOV	DS,SI
	POP	SI
pop	ds
	RET


;
;☆ＥＮＤの処理
;

ENDIN:	
	CALL	CLOSEALL	;FILE を全て CLOSE
	CMP	BP,TXTHED
	XOR	BP,BP		;END FLAG FOR ERROR 処理
	CMP	[UNLPT],0
	JZ	END10
	MOV	AL,CR		;プリンタに印字司令
	CALL	LPRNSUB
	MOV	AL,LF
	CALL	LPRNSUB
	MOV	[UNLPT],0
END10:
;	CALL	LOOPCHECK	;各制御命令が全て終了したか調査
	MOV	[CONTADR],0
	mov	[contcsp],limit
	JMP	READY

LOOPCHECK:
	CMP	CS:[GOSUBSP],OFFSET GOSUBSP
	JMPNC	NORETURN
	CMP	CS:[FORSP],OFFSET FORSP
	JMPNC	NONEXT
	RET


;
;* process of WHILE
;

WHILERR:
	JMP	NOWEND

WHILE:	
	;set jump address

	MOV	AX,[BP]
	OR	AX,AX
	JNZ	WHILE20
	ADD	BP,2
	CALL	SRCWEND
	JC	WHILERR

	SUB	BP,2
	MOV	[DI],BP		;WEND retrun address
	MOV	[BP],SI		;jump address if  FALSE
	MOV	[compilejp_sw],-1

;* process of UNTIL	same as main part of WHILE

UNTIL:
WHILIN:				;also looped from WEND
	MOV	AX,[BP]
WHILE20:
	PUSH	AX		;/*
	ADD	BP,2

	CMP	BYTE PTR [BP],0B5H	;NOT
	JE	WHILENOT

	CALL	FORMUL
	CALL	BACKSP

	MOV	AX,[SI]
	OR	AX,AX
	JZ	WHILEPASS
	and	ax,attribmask
	jnz	whilepointerr
WHILEDO:
	ADD	SP,2		;*/DUMMY
	JMP	MAINLP

whilepointerr:
	jmp	conditionerr

WHILENOT:
	INC	BP

	CALL	FORMUL
	CALL	BACKSP

	MOV	AX,[SI]
	OR	AX,AX
	JZ	WHILEDO
	and	ax,attribmask
	jnz	whilepointerr
WHILEPASS:
	POP	BP		;*/
	JMP	MAINLP


;
;* process of WEND
;

WEND:
	MOV	AX,[BP]
	OR	AX,AX
	JZ	WEND_ERR	;WEND WITHOUT WHILE
	MOV	BP,AX
	JMP	WHILIN

WEND_ERR:
	JMP	NOWHILE


;
;* process of REPEAT
;

REPEATERR:
	JMP	NOUNTIL

REPEAT:	
	;まづは戻り先をセット

	ADD	BP,2
	CMP	WORD PTR [BP-2],0
	JE	REPEAT1ST
	JMP	MAINLP

REPEAT1ST:
	CALL	SRCUNTIL
	JC	REPEATERR

	MOV	[DI],BP		;UNTIL の戻り先
	MOV	WORD PTR [BP-2],-1	;COMPILED FLAG
	MOV	[compilejp_sw],-1
	JMP	MAINLP


;
;☆ＬＯＯＰの処理
;

LOOPIN:
	;戻り先をセット

	ADD	BP,2
	CMP	WORD PTR [BP-2],0
	JE	LOOP1ST
	JMP	MAINLP

LOOP1ST:
	CALL	SRCENDLOOP
	JC	ENDLOOPERR
	MOV	[DI],BP		;ENDLOOP の戻り先
	MOV	WORD PTR [BP-2],-1	;コード化マーク
	MOV	[compilejp_sw],-1
	JMP	MAINLP

ENDLOOPERR:
	JMP	NOLOOP

;
;☆ＥＮＤＬＯＯＰの処理
;

ENDLOOP:
	MOV	AX,[BP]
	OR	AX,AX
	JZ	ENDLOOPERR
	MOV	BP,AX
	JMP	MAINLP

;
;☆ＪＵＭＰの処理
;

JUMPIN:
	MOV	AX,[BP]
	OR	AX,AX
	JZ	JUMP10
	MOV	BP,AX
	JMP	MAINLP

JUMP10:
	CALL	SEARCH_MARK
	MOV	[BP],SI
	MOV	[compilejp_sw],-1
	MOV	BP,SI
	JMP	MAINLP


SEARCH_MARK:
	MOV	DL,0B7H		;MARK
	MOV	SI,BP		;change pointer
MARKLP:	
	LODSB
	CMP	AL,CR
	JE	MARKPAS5B	;行の終わりなので行番号と次先頭をパス
	CMP	AL,DL
	JE	MARKOUT		;あった
	CALL	PASSTOKEN
	JMP	MARKLP

MARKOUT:
	RET

MARKPAS5B:				;先頭 5BYTES をパス	
	LODSW
	ADD	SI,3
	OR	AX,AX
	JNZ	MARKLP
	JMP	NOMARK


;
;☆ＧＯＴＯの処理
;

	myalign
GOTO:	
	MOV	AL,[BP]
	CMP	AL,Ncode_ADR
	JNE	GOTO10

	;アドレスになっている場合

	MOV	BP,[BP+1]
	JMP	INTER1

GOTO10:
	CMP	AL,Ncode_ADR2
	JE	GO2NDLABEL
	CMP	AL,Ncode1
	JE	GO1ST		;if 1st time
	CMP	AL,Ncode_LABEL
	JE	GO1STLABEL
	JMP	SYNERR

	;行番号をアドレスに変える

GO1ST:	
	MOV	CX,[BP+1]
	CALL	SRCLIN
	JNZ	GOTOERR

	ADD	BX,5		;番地・番号をパスするのみ
				;これ以上最適化すると元に戻せない
	MOV	[compilegoto_sw],-1
	MOV	BYTE PTR[BP],Ncode_ADR
	MOV	[BP+1],BX
	MOV	BP,BX
	JMP	INTER1
GOTOERR:
	JMP	NOLERR

GO2NDLABEL:
	XOR	AX,AX
	MOV	AL,[BP+1]
	MOV	SI,AX
	MOV	BP,[BP+SI+2]
	JMP	MAINLP
		
GO1STLABEL:
	MOV	[compilegoto_sw],-1
	MOV	BYTE PTR [BP],Ncode_ADR2
	CALL	GETLABELADR
	MOV	[BP-2],AX
	MOV	BP,AX
	JMP	MAINLP


;
;☆ ＣＯＮＴ の処理
;

CONTIN:
	mov	[directflg],0	;non direct mode
	MOV	AX,[CONTADR]
	CMP	AX,TXTHED
	JMPC	CONTERR
	mov	ax,[contcsp]
	cmp	ax,[calcsp]
	jmpnz	conterr
	CALL	compilevar	;変数を登録
	mov	al,[contout_dev]
	mov	[out_dev],al
	mov	ax,[contadr]
	MOV	[CONTADR],0
	mov	[contcsp],limit
	MOV	BP,AX
	JMP	MAINLP


;
;☆ＲＵＮの処理
;
nofilename:
	cmp	[TXTEND],TXTHED+1
	je	runaftermenu	;no name and no text
	or	ah,ah
	jnz	run_normal
cantrun:			;RUN without option in the program
	jmp	cantdo
runaftermenu:
	call	ahedsp
	mov	word ptr [si],0800h
	backsp_mac
	jmp	runafterload

RUN:	
	mov	ah,[directflg]
	mov	[directflg],0

;	mov	[schoolflg],0

	mov	al,[bp]
	cmp	al,CR
	je	nofilename
	cmp	al,0c0h		;code of :
	je	nofilename

	call	ahedsp			;pregetfilename
	mov	word ptr [si],0		;
	backsp_mac			;
	cmp	byte ptr [BP],CR	;
	je	pregetout		;
	call	FORMUL			;
	backsp_mac			;
pregetout:				;

	call	discompilegoto
	call	discompilevar
runafterload:
	mov	[compilegoto_sw],0
	mov	[compilevar_sw],0
	MOV	SI,TXTHED
	MOV	[TXTTOP],SI
	MOV	[ENDMEM],SI
	mov	dx,offset runmsg
	CALL	LOADMP
	JC	CANTLOAD

	mov	[directflg],0
	mov	[compilegoto_sw],0
	mov	[compilevar_sw],0
	MOV	[EDITPTR],0
	CALL	CHGOUT_INIT
	CALL	discompilegoto		;飛び先ADRなどを元に戻す
	call	far ptr farInitWP
	MOV	AX,[ENDMEM]
	MOV	[TXTEND],AX
	add	ax,unitbyte		;MOV	[calcsp_limit],ax
	mov	[calcsp_limit],ax	;add	[calcsp_limit],unitbyte
	MOV	[compilejp_sw],-1

RUN_NORMAL:
	mov	sp,systemstackbtm
	mov	[base_sp],sp
	mov	[labelend],offset label_table
	CALL	MAKE_LABEL_TABLE
	mov	[compilejp_sw],-1
	call	discompilejp
	call	discompilegoto
	call	closeall	;close all files
	call	iniloop
	call	discompilevar	;code -> name : all variables
	call	resvar		;clear variable table
	CALL	compilevar	;name -> code : all variables
	MOV	BP,TXTHED
	CMP	WORD PTR [BP],0
	je	cancelrun	;no text in memory
	ADD	BP,5
	JMP	INTER1

cancelrun:
	jmp	ready

CANTLOAD:
	cmp	ah,5
	je	cancelrun
	CMP	AH,1
	JMPZ	NOFILE
	CMP	AH,2
	JMPZ	DISKERR
	cmp	ah,4
	je	go_partload
	JMP	BIGPROG
go_partload:
	jmp	far ptr partload

;
;☆テキスト(PTR BP)から 1 ワードの数値を読んで CX に返す
;
HEXCX:	
	MOV	AL,[BP]
	INC	BP
	CMP	AL,0F1H
	JE	NUMWORD
	CMP	AL,0F2H
	JE	NUMLONG

	SUB	AL,0F0H
	JC	HEXCXERR

	XOR	CX,CX
	RET	

HEXCXERR:
	JMP	SYNERR

NUMWORD:	
	MOV	CX,[BP]
	WINC	BP
	RET	

NUMLONG:	
	MOV	AX,[BP]
	WINC	BP
	AND	AX,LENMASK
	CMP	AX,3
	JNC	HEXCXERR
	MOV	CX,[BP]
	WINC	BP
	RET	

;
;☆ ＴＨＥＮ
;

THENIN:
	MOV	AL,[BP]
	CMP	AL,Ncode_ADR
	JE	THEN10
	CMP	AL,Ncode_ADR2
	JE	THEN20
	CMP	AL,Ncode1
	JE	THEN30
	CMP	AL,Ncode_LABEL
	JE	THEN40	
	JMP	MAINLP

THEN10:				;アドレスになっている場合
	MOV	BP,[BP+1]
	JMP	INTER1
THEN20:
	JMP	GO2NDLABEL
THEN30:
	JMP	GO1ST		;if 1st time
THEN40:
	JMP	GO1STLABEL

;
; * ELSE
; * ELSEIF
;

ELSEIN:	
ELSEIFIN:
	ADD	BP,2		;PASS 2BYTES after ELSE
	MOV	SI,[BP-2]
	OR	SI,SI
	JNZ	ELSE100
	CALL	ENDIFNEXTLINE	;search endif or nextline
	MOV	[BP-2],SI	;飛び先のセット
	MOV	[compilejp_sw],-1
ELSE100:
	MOV	BP,SI
	JMP	MAINLP

;
;☆ＩＦの処理
;

IFSYNERR:
	JMP	SYNERR
ifconditionerr:
	jmp	conditionerr


IF2IN:
IFIN:	
	PUSH	BP		;☆
	ADD	BP,2

	CMP	BYTE PTR [BP],0B5H	;NOT
	JE	IFNOT

	CALL	FORMUL
	CALL	BACKSP

	MOV	AX,[SI]
	OR	AX,AX
	JZ	IFFALSE
	and	ax,pointcomp	;attribmask
	jnz	ifconditionerr
IFDO:
	ADD	SP,2		;☆
	JMP	MAINLP		;if true


IFNOT:
	INC	BP

	CALL	FORMUL
	CALL	BACKSP

	MOV	AX,[SI]
	OR	AX,AX
	JZ	IFDO
	and	ax,attribmask
	jnz	ifconditionerr
IFFALSE:
	POP	BX		;☆

	MOV	SI,[BX]
	OR	SI,SI
	JNZ	IFFALSE100
	CALL	ELSEENDIFNEXTLINE	;else,elseif,endif,nextline
	MOV	[BX],SI		;飛び先のセット
	MOV	[compilejp_sw],-1
IFFALSE100:
	MOV	BP,SI
	JMP	THENIN		;ELSE+飛び先かもしれない


;
;☆ＦＯＲの処理
;

FORSPERR:
	JMP	SPERR

FORSYNERR1:
	JMP	SYNERR

	myalign
FORIN:

	;FOR~NEXT 用スタックの更新

	MOV	BX,CS:[FORSP]
	ADD	BX,forunitbyte
	CMP	BX,OFFSET FORSPEND-forunitbyte
	JA	FORSPERR
	MOV	CS:[FORSP],BX

	;最初の代入文の処理(初期値がスタック１に)
	;ループ変数は短変数と長変数のみ

	MOV	AL,[BP]
	MOV	CS:[BX.FORVARTYPE],AL	;変数の型をセット
	INC	BP
	SUB	AL,Vcode
	JZ	FORLET0
	CMP	AL,2
	JE	FORLET2
	JMP	FORSYNERR1

FORLET0:
	CALL	FORLET0SUB
	JMPS	FORIN10
FORLET2:
	CALL	FORLET2SUB
	
	;変数名とアドレス(or SEGMENT)をセット

FORIN10:
	MOV	SI,CS:[FORSP]
	MOV	CS:[SI.FORVARADR],BX	;adr=offset or segment
	PUSH	SI		;☆

	;次は TO かチェック

	MOV	AL,[BP]
	CMP	AL,8AH		;code of 'TO'
	JNE	FORSYNERR1
	INC	BP

	;終了値を得る(ON スタック２)

	CALL	AHEDSP		;計算スタックを一つ深く
	CALL	FORMUL

	MOV	SI,[CALCSP]
	MOV	AX,[SI]
	OR	AX,[SI+UNITBYTE]
	TEST	AH,attribmaskhigh
	JNZ	ILG_FORTOSTEP	;小数は不可

	;初期値-終了値の計算(結果がスタック１に)
	
	CALL	SUBIN

	;STEP を得る

	MOV	AL,[BP]
	CMP	AL,8BH		;code of STEP
	JNE	NONSTEP

	;STEP があった場合

	INC	BP

	;STEP を計算(ON STACK2)

	CALL	FORMUL
	CALL	BACKSP
	POP	BX		;☆
	MOV	AX,[SI]		;[SI]=STEP,[DI]=開始-終了
	TEST	AH,attribmaskhigh
	JNZ	ILG_FORTOSTEP	;小数は不可
	MOV	CL,AH
	AND	CL,80H		;CL=符号
	AND	AX,LENMASK
	JZ	ILG_FORTOSTEP	;if step=0
	CMP	AX,1
	JA	FOROVRERR	;if step too big

	MOV	DX,[SI+2]
	TEST	DH,80H		;abs(STEP) must
	JNZ	FOROVRERR	;<8000H

	OR	DH,CL		;STEP の符号設定
	MOV	CS:[BX.FORSTEP],DX	;set STEP

	MOV	AX,[DI]
	OR	AX,AX
	JZ	SETTM1		;if start=end
	XOR	AH,CL
	JZ	GO_PASFOR	;符号が違う(無限ループ)
	AND	AX,LENMASK

	;ループ回数の計算

	MOV	CX,DX
	AND	CH,7FH		;take abs of STEP
	XOR	DX,DX
	CMP	AX,2
	JB	STEP1W
	JE	STEP2W
	cmp	ax,3
	JA	FOROVRERR

STEP3W:
	mov	dx,[di+6]
	cmp	dx,cx
	jb	step2win
FOROVRERR:
	JMP	OVRERR

STEP2W:
	xor	dx,dx
STEP2WIN:
	mov	ax,[di+4]
	div	cx
	push	ax
	mov	ax,[di+2]
	div	cx
	pop	dx
	jmps	setcnt

STEP1W:
	xor	dx,dx
	mov	ax,[di+2]
	div	cx
	xor	dx,dx
	jmps	setcnt


ILG_FORTOSTEP:
	JMP	ILGERR	

GO_PASFOR:
	JMP	PASFOR

FORSYNERR:
	JMP	SYNERR

FOROUT:
	JMP	ENDIN


	;STEP が省略された場合

NONSTEP:
	POP	BX		;☆
	MOV	WORD PTR CS:[BX.FORSTEP],1	;DEFAULT is 1

	MOV	SI,[CALCSP]
	xor	dx,dx
	MOV	AX,[SI]
	OR	AX,AX
	JZ	SETTM1		;start=end -> only 1 time
	TEST	AH,80H
	JZ	PASFOR		;if start>end
	AND	AX,LENMASK
	CMP	AX,2
	JA	FOROVRERR	;too many
	MOV	AX,[SI+2]	;loop TIME
	jne	setcnt
	mov	dx,[si+4]

	;set loop time

SETCNT:
	add	ax,1
	adc	dx,0
	jc	FOROVRERR
SETCNT10:
	MOV	CS:[BX.FORCOUNT],AX	;set loop time
	MOV	CS:[BX.FORCOUNT+2],DX	;

	CALL	BACKSP

	;get start adr

	MOV	AL,[BP]
	CMP	AL,CR
	JE	LOPACR
	CMP	AL,0C0H		;code of ':'
	JNE	LOPAJP
	INC	BP
	JMPS	LOPAJP
LOPACR:
	INC	BP
	CMP	WORD PTR [BP],0
	JE	FOROUT		;テキストがもうない
	ADD	BP,5
	MOV	AL,[BP]
	CMP	AL,Ncode_LABEL
	JE	LOPA20	
LOPAJP:
	MOV	CS:[BX.FORRETURN],BP

	;cut for-next stack if re-enter

	mov	si,cs:[GOSUBSP]
	mov	di,offset FORSP - FORUNITBYTE + 2
	cmp	si,offset GOSUBSP - GOSUBUNITBYTE + 2
	je	forsp_reent_check
	mov	di,cs:[si+16]	;get FORSP local top
forsp_reent_check:
	add	di,FORUNITBYTE
	cmp	cs:[di.FORRETURN],bp
	jne	forsp_reent_check
	cmp	bx,di
	jne	forsp_reenter
	JMP	MAINLP		;FOR の処理の終わり
forsp_reenter:
	mov	cs:[FORSP],di
	push	ds
	push	es
	mov	ax,cs
	mov	ds,ax
	mov	es,ax
	mov	si,bx
	mov	cx,FORUNITWORD
	rep	movsw
	pop	es
	pop	ds
	jmp	mainlp

LOPA20:
	INC	BP
	XOR	AX,AX
	MOV	AL,[BP]
	ADD	AX,4
	ADD	BP,AX
	JMP	LOPAJP

SETTM1:	
	xor	dx,dx
	mov	ax,1
	JMP	SETCNT10

	;FOR の条件がおかしい時は対応する NEXT までパス
PASFOR:	
	CALL	BACKSP
	SUB	CS:[FORSP],forunitbyte
	MOV	SI,BP		;change pointer

	MOV	CX,0189H	;CH=counter,CL=FOR
FORSLP:	
	LODSB
FORSLP10:
	CMP	AL,94H		;code of CANCEL
	JE	FORSJP
	CMP	AL,0DH
	JE	PAS5B2
	CMP	AL,CL		;code of FOR
	JE	FORPUS
	CMP	AL,8CH		;code of NEXT
	JE	FORPOP
forslp20:
	CALL	PASSTOKEN
	JMP	FORSLP

FORSJP:				;CANCEL に出て来る FOR を無視	
	LODSB
	CMP	AL,CL
	JNE	FORSLP10
FORSJP10:
	CMP	BYTE PTR [SI],0C2H	;code of ,
	JNE	FORSLP
	INC	SI
	LODSB
	CMP	AL,CL
	JE	FORSJP10
	JMP	SYNERR

FORPUS:				;FOR が出れば COUNTER を増す	
	mov	al,[si]		;must followed by a variable
	cmp	al,vcode
	jb	forslp20
	cmp	al,vcode5
	ja	forslp20
	INC	CH
	JMP	FORSLP

FORPOP:				;NEXT が出れば COUNTER を減らす	
	DEC	CH
	JNZ	FORSLP

	MOV	BP,SI
	MOV	AL,[BP]
	CMP	AL,0DH
	JE	FORPJP
	CMP	AL,0C0H
	JE	FORPJP
	CALL	CHECKVAR	;ある場合はチェック
FORPJP:
	JMP	MAINLP

NONEXTERR:			;if error
	JMP	NONEXT

FORSYNERR3:
	JMP	SYNERR

PAS5B2:				;行の先頭をパス	
	LODSW
	OR	AX,AX
	JZ	NONEXTERR	;FOR without NEXT
	ADD	SI,3
	JMP	FORSLP

CHECKVAR:
	MOV	AL,[BP]
	INC	BP
	CMP	AL,CS:[BX.FORVARTYPE]
	JNE	CHKVERR		;変数の型が一致せず
	cmp	al,vcode2
	je	checkvarlong
	xor	ax,ax
	mov	al,[bp]
	inc	bp
	mov	cx,[bp]
	cmp	cx,CS:[BX.FORVARadr]
	jne	chkverr
	add	bp,ax
	ret

checkvarlong:
	xor	ax,ax
	mov	al,[bp]
	inc	bp
	mov	si,[bp]
	mov	cx,cs:[si]
	cmp	cx,CS:[BX.FORVARadr]
	jne	chkverr
	add	bp,ax
	ret


CHKVERR:
	JMP	FORNEXTERR


;☆短変数への代入
;OUTPUT BX=table adr

FORLET0SUB:
	xor	ax,ax
	mov	al,[bp]
	inc	bp
	mov	bx,[bp]
	add	bp,ax

	PUSH	BX		;**ADR
	MOV	AL,[BP]
	CMP	AL,codeofequal
	JNE	FORLET_SYNERR
	INC	BP

	CALL	FORMUL
	BACKSP_MAC
	MOV	AX,[SI]
	MOV	DX,AX
	TEST	AH,attribmaskhigh
	JNZ	ILG_FORLET	;小数の代入は不可
	AND	AX,LENMASK
	CMP	AX,1
	JB	FORLET0_10		;IF 0
	JA	FORLET_OVRERR

	AND	DH,80H		;符号
	MOV	AX,[SI+2]	;値
	TEST	AH,80H
	JNZ	FORLET_OVRERR
	OR	AH,DH
FORLET0_10:
	POP	BX		;**
	MOV	cs:[BX],AX	;値のセット
	RET

FORLET_SYNERR:
	JMP	SYNERR
FORLET_OVRERR:
	JMP	OVRERR
ILG_FORLET:
	JMP	ILGLET


;☆長変数への代入
;OUTPUT CX:VAR NUMBER,BX:SEGMENT

FORLET2SUB:
	xor	ax,ax
	mov	al,[bp]
	inc	bp
	mov	bx,[bp]
	add	bp,ax

	MOV	BX,cs:[BX]
	PUSH	BX		;**ADR=segment
	MOV	AL,[BP]
	CMP	AL,codeofequal
	JNZ	FORLET_SYNERR
	INC	BP

	CALL	FORMUL
	BACKSP_MAC
	MOV	CX,[SI]
	AND	CX,LENMASK
	CMP	CX,[MAXWORD]
	JA	FORLET_OVRERR
	INC	CX
	POP	BX		;**ADR
	MOV	ES,BX
	XOR	DI,DI
	REP	MOVSW		;値のセット
	MOV	AX,SS
	MOV	ES,AX
	RET


;
;☆ＮＥＸＴの処理
;

NEXTSYNERR:
	JMP	SYNERR
NEXTSPERR:
	JMP	NOFOR

	myalign
NEXT:	
	mov	si,cs:[GOSUBSP]
	mov	di,offset FORSP - FORUNITBYTE + 2
	cmp	si,offset GOSUBSP - GOSUBUNITBYTE + 2
	je	next_check10
	mov	di,cs:[si+16]	;get FORSP local top
next_check10:
	MOV	BX,CS:[FORSP]
	CMP	BX,di
	JBE	NEXTSPERR		;NEXT without FOR

	;変数名があるか

	MOV	AL,[BP]
	CMP	AL,0DH
	JE	NEXTJ1
	CMP	AL,0C0H
	JE	NEXTJ1

	CALL	CHECKVAR	;ある場合はチェック

	;STEP をループ変数に加える

NEXTJ1:	
	MOV	BX,CS:[FORSP]
	MOV	DI,CS:[BX.FORVARADR]	;var adr or seg
	MOV	AX,CS:[BX.FORSTEP]	;AX=STEP
	PUSH	BX			;/*
	CMP	BYTE PTR CS:[BX.FORVARTYPE],Vcode
	JE	SRTVAR		;if short type

	;ループ変数が LONG 型の場合

	MOV	DS,DI
	MOV	ES,DI
	XOR	DI,DI
	TEST	AH,80H
	JZ	NEXT20		;IF AX>=0
	AND	AH,7FH
	CALL	LWSUB
	JMPS	NEXT30
NEXT20:
	CALL	LWADD
NEXT30:
	MOV	AX,SS
	MOV	DS,AX
	MOV	ES,AX
	JMPS	DECLPV

	;ループ変数が SHORT 型の場合

SRTVAR:	
	MOV	DX,cs:[DI]	;DX=変数の値
	MOV	CL,AH
	MOV	CH,DH
	AND	AH,7FH
	AND	DH,7FH

	;STEP と変数の値の符号をチェック

	AND	CX,8080H	;符号のみを残す
	XOR	CL,CH
	JNZ	DIFSGN		;違う場合

	ADD	AX,DX		;同じ場合
	TEST	AH,80H
	JNZ	NEXT50
	OR	AH,CH		;符号のセット
	JMP	SETNEW
NEXT50:
	JMP	OVRERR

DIFSGN:	
	SUB	DX,AX		;違う符号の場合は
	MOV	AX,DX		;符号が変わる事がある
	JNC	DIFSJ1
	NEG	AX		;符号が逆になる
	XOR	CH,80H
	OR	AH,CH
	JMPS	SETNEW

DIFSJ1:	
	or	ax,ax
	jz	setnew		;if 0	
	OR	AH,CH		;符号は元のまま

	;新しい値をセット

SETNEW:	
	MOV	cs:[DI],AX


	;ループ・カウンタを減らす

DECLPV:	
	POP	BX		;*/
	mov	ax,cs:[bx.forcount]
	mov	dx,cs:[bx.forcount+2]
	sub	ax,1
	sbb	dx,0
	mov	cs:[bx.forcount],ax
	mov	cs:[bx.forcount+2],dx

	or	ax,dx
	jz	next_out

	;0 でなければループする

	MOV	BP,CS:[BX.FORRETURN]
	JMP	MAINLP

	;0 ならばループ終了

next_out:
	SUB	BX,forunitbyte
	MOV	CS:[FORSP],BX
	JMP	MAINLP


;☆一まとまりの中間コードをスキップする
;INPUT	AL=先頭一バイト
;	SI=AL の POINTER+1
;OUTPUT	SI=次の POINTER

PASS5:
	JE	PASS_extended	;拡張コードの場合
	CMP	AL,'"'
	JE	PASSQUOTE
	RET			;1 バイトのコードの場合

PASSQUOTE:			;文字列をパス
	LODSB
	CMP	AL,'"'
	JNE	PASSQUOTE
	RET

pass_extended:
	lodsb
	cmp	al,0e7h		;and{
	jb	passret0
	cmp	al,0e8h		;or{
	ja	passret0
	winc	si
	ret
pass_extended3:
	inc	si
	ret


farPASSTOKEN:
	call	PASSTOKEN
	retf

	myalign
PASSTOKEN:
	CMP	AL,codemark2	;=80h
	JBE	PASS5
	cmp	al,codemark3
	je	pass_extended3
	CMP	AL,Vcode5
	JBE	PASSvariable	;変数の場合
PASS10:
	CMP	AL,Ncode
	JA	PASS12
	JE	PASSRET0
	cmp	al,0afh		;elseif
	je	passret5
	cmp	al,0b0h		;secret if
	je	passret2
	CMP	AL,98H		;REM
	JE	PASSREM
	CMP	AL,8DH		;IF
	JB	passret0
	CMP	AL,0B6H		;JUMP
	JE	PASSRET2
	CMP	AL,0B8H		;loop
	JE	PASSRET2
	CMP	AL,0B9H		;ENDLOOP
	JE	PASSRET2
	CMP	AL,93H		;UNTIL
	JA	passret0
	CMP	AL,8EH		;THEN
	JNE	PASSRET2	;IF,ELSE, 
PASSret0:
	RET			;1 バイトのコードの場合

PASSRET2:
	INC	SI
PASSRET1:
	INC	SI
	RET
passret5:
	add	si,5
	ret

PASS12:
	SUB	AL,Ncode1
	JZ	PASSRET2	;1 ワードの数値の場合
	DEC	AL
	JZ	PASS15		;=Ncode2
	DEC	AL		;Ncode3 は未使用
	DEC	AL
	JZ	PASSRET2	;=Ncode_ADR
	DEC	AL
	JZ	PASS17		;=Ncode_LABEL
	DEC	AL
	JZ	PASS17		;=Ncode_ADR2
	JMP	SYNERR

PASS17:				;LABEL の場合
	LODSW
	XOR	AH,AH
	INC	AX
	ADD	SI,AX
	RET			;JMPS	PASSRET

PASS15:
	LODSW			;多桁の数値の場合
	AND	AH,LENMASKHIGH
	ADD	SI,AX
	ADD	SI,AX
	RET			;JMPS	PASSRET

passvariable:
	xor	ax,ax
	mov	al,[si]
	inc	si
	ADD	SI,ax
	RET


PASSREM:
	LODSW
	OR	AX,AX
	JZ	PASSREM10
	MOV	SI,AX
	RET

PASSREM10:
	LODSB
	CMP	AL,CR
	JNE	PASSREM10
	DEC	SI
	RET			;must stop at CR
				;used by VCHG,...etc

;
;	対応する ELSE,ELSEIF,ENDIF or 次の行の先頭までパス
;

ELSEENDIFNEXTLINE:
	MOV	SI,BP		;change pointer
EEINLLP:	
	LODSB
	CMP	AL,CR
	JE	EEINLPAS5B	;行の終わりなので行番号と次先頭をパス
	CMP	AL,8DH		;IF
	JE	EEINLPUSH
	CMP	AL,97H		;ENDIF
	JE	EEINLRET
	CMP	AL,8FH		;ELSE
	JE	EEINLELSERET
	CMP	AL,0AFH		;ELSEIF
	JE	EEINLELSERET
	CALL	PASSTOKEN
	JMP	EEINLLP
EEINLELSERET:
	ADD	SI,2		;PASS 2BYTES WORK
EEINLRET:
	RET


EEINLPUSH:
	ADD	SI,2		;PASS 2 BYTES WORK
	CALL	PASSIFSUB	;if 文を pass
	JMP	EEINLLP

EEINLPAS5B:			;先頭 5BYTES をパス	
	LODSW
	ADD	SI,3
	OR	AX,AX
	JZ	EEINLPAS5BEND
	LODSB
	CMP	AL,0C0H		;CODE OF : 継続マーク
	JE	EEINLLP
	DEC	SI
EEINLPAS5BEND:
	SUB	SI,6		;CR の位置にする
	JMP	EEINLRET

;
;	現在の IF 文の次までパス
;

ENDIFNEXTLINE:
	MOV	SI,BP		;change pointer

PASSIFSUB:
	PUSH	DX
	XOR	DX,DX		;DOUBLE ELSE CHECK
EORNLLP:	
	LODSB
	CMP	AL,CR
	JE	EORNLPAS5B	;行の終わりなので行番号と次先頭をパス
	CMP	AL,8DH		;IF
	JE	EORNLPUSH
	CMP	AL,97H		;ENDIF
	JE	EORNLRET
	CMP	AL,8FH		;ELSE
	JE	EORNLCHK	;this time don't care ELSEIF
	CALL	PASSTOKEN
	JMP	EORNLLP
EORNLRET0:
	DEC	SI
EORNLRET:
	POP	DX
	RET


EORNLPUSH:
	ADD	SI,2		;PASS 2 BYTES WORK
	CALL	PASSIFSUB
	JMP	EORNLLP

EORNLCHK:
	CMP	DX,1
	JE	EORNLRET0
	ADD	SI,2		;PASS 2 BYTES WORK
	INC	DX
	JMP	EORNLLP

EORNLPAS5B:			;先頭 5BYTES をパス	
	LODSW
	ADD	SI,3
	OR	AX,AX
	JZ	EORNLPAS5BEND
	LODSB
	CMP	AL,0C0H		;CODE OF : 継続マーク
	JE	EORNLLP
	DEC	SI
EORNLPAS5BEND:
	SUB	SI,6		;CR の位置にする
	JMP	EORNLRET



;
;	対応する ENDLOOP までパス
;
SRCENDLOOP:
	MOV	DX,0B8B9H	;B8h=loop,B9h=ENDLOOP
	JMPS	SRCWENDIN

;
;	対応する UNTIL までパス
;
SRCUNTIL:
	MOV	DX,9293H	;92h=repeat,93h=until
	JMPS	SRCWENDIN

;
;	対応する WEND までパス
;

SRCWEND:
	MOV	DX,9091H	;90h=while,91h=wend
SRCWENDIN:
	MOV	SI,BP		;change pointer
	MOV	CH,1		;CH=counter
WHENLP:	
	LODSB
WHENLP2:
	CMP	AL,CR
	JE	PAS5B1		;行の終わりなので行番号と次先頭をパス
	CMP	AL,DH
	JE	WHPUSH
	CMP	AL,DL
	JE	WHPOP
	CALL	PASSTOKEN
	JMP	WHENLP

WHPUSH:				;WHILE があったら CH を増す
	INC	CH
	JMP	WHENLP

WHPOP:	
	DEC	CH		;WEND があったら CH を減らす
	JNZ	WHENLP
	MOV	DI,SI		;WEND,UNTIL の WORK の位置
	ADD	SI,2		;PASS 2 BYTES WORK(もっと最適化せよ)
	CLC
	RET

PAS5B1:				;先頭 5BYTES をパス	
	LODSW
	ADD	SI,3
	OR	AX,AX
	JNZ	WHENLP
	STC
	RET


farpass1sentence:
	MOV	SI,BP		;change pointer

pass1slp:
	LODSB
	CMP	AL,CR
	JE	pass1sx		;end of line
	cmp	al,0c0h		; ':'
	je	pass1sxret
	CALL	PASSTOKEN
	JMP	pass1slp

pass1sx:
	lodsw			;skip top 5 bytes
	add	si,3
	or	ax,ax
	jz	pass1sxendofprog
pass1sxret:
	mov	bp,si
	retf

pass1sxendofprog:
	sub	si,6
	jmp	pass1sxret


CODE	ENDS

code2	segment	word public
	assume	cs:code2,ds:data

	extrn	runmsg:byte
	extrn	partload:far
	extrn	farpointsetsub:far


code2	ends

END
