;MAINLP.ASM for DOS/V and Toshiba J-3100

	INCLUDE	UBDEF.H
	INCLUDE	UB.H


CODE	SEGMENT PUBLIC
	ASSUME	CS:CODE,DS:DATA

;PUBLIC LABELS

	PUBLIC	HOTST,INTER,INTER1,READY,LINEND
	PUBLIC	GETCOM,GETCOMIN,GETCOMJP
	PUBLIC	MAINLP,MAININ,GO_ENDIN
	PUBLIC	PRCHRSUB,PRCHRSUBIN,CTRL_KEY
	PUBLIC	GET_DATA,GET_LTOP
	public	CURSOR
	public	curson,cursoff,farcurson,farcursoff
	PUBLIC	curs_norm,curs_block
	public	farCURSOR
	public	CHKCTRL_C,CHKCTRL_S
	PUBLIC	farCHKCTRL_CS
	PUBLIC	MAKE1SPACE
  if JAPANESE
	public	farSJIS_JIS
  endif
	public	callusr

;EXTERNAL LABELS

	EXTRN	JMPTBL:WORD,label_table:byte
  if JAPANESE
  	extrn	onkanji1st?:near,onkanji2nd?:near
  endif
	EXTRN	ROLL_UP:NEAR,ROLL_DOWN:NEAR
	EXTRN	PAGE_UP:NEAR,PAGE_DOWN:NEAR
	EXTRN	INIT:NEAR,make_label_table:near
	extrn	discompilevar:near,discompilegoto:NEAR
	extrn	discompilejp:near
        extrn   compilevar:near,compilevardirect:near
	EXTRN	DECODE:NEAR,ENCODE:NEAR
	EXTRN	BREAK:NEAR,ENDIN:NEAR,DEBUGLP:NEAR
	EXTRN	NL:NEAR,MSG:NEAR,PRCHR:NEAR,TROFFSUB:NEAR

	EXTRN	USRFUNC:NEAR,SYSPUSH:NEAR,SYSPOP:NEAR,UNDEF:NEAR
	EXTRN	SPADD:NEAR,SPSUB:NEAR,SPMUL:NEAR,SPDIV:NEAR
	EXTRN	SPIDIV:NEAR,SPMOD:NEAR,SP2P:NEAR
	EXTRN	GOTO:NEAR,AUTOSUB:NEAR

	extrn	CLEAR_BELOW:near,RIGHT_ERASE:near
	extrn	LEFT_ERASE:near,NEW_LINE:near
	extrn	CLEAR_SCREEN:near,CURS_HOME:near
	extrn	CAR_RET:near,CURS_BACK:near,CURS_DEL:near
	extrn	CURS_RIGHTEND:near,CURS_TAB:near
	extrn	CURS_RIGHT:near,CURS_LEFT:near
;	extrn	CURS_RIGHTnoNL:near
	extrn	CURS_LEFTEND:near,CURS_UP:near,CURS_DOWN:near
	extrn	SCROLLUP:near
	extrn	ctrl_ret:near
	extrn	farLETNL:far
	extrn	GET_LINE:near
	extrn	SETIN:near,farPRCHR:near,CTRL_INS:near
	extrn	letcommon:near

	extrn	deffnreturn:near

	EXTRN	SYNERR:NEAR,AREAFULL:NEAR,TOOLONGLINE:NEAR

	extrn	curs_form:word
  if JAPANESE
  	extrn	kanji1st?:near
  endif

;  * UBASIC INTERPRETOR (* MS-DOS version)
;    start & command getting routine

;00H-7FH is used for work area of random number

;80H-0efH is reserved for BUG patch area

ORG     100H


START:
	JMP	INIT

;
;* user machine language entry point
;

org	104h

CALLUSR:
	push	bp
	pushf
	CALL	DWORD PTR SS:[BASEOFF]	;USER ROUTINE へ
	popf
	pop	bp
	MOV	AX,SS
	MOV	DS,AX
	MOV	ES,AX
	JMP	MAINLP

;
; * call HELP
;
goHELP:
	call	far ptr farHELP
	ret


;
;☆☆ＵBASIC のＭAIN ＬOOP
;
;

HOTST:	

;  initialize stack pointer

	cli
	MOV	SP,ss:[base_sp]
	sti

;* input from keyboard and execute

GETCOM:	
	MOV	BP,CODBUF
	TEST	BYTE PTR [AUTOFLG],-1
	JZ	GETCOM10
	CALL	AUTOSUB
GETCOM10:
	CALL	CURSON
	CALL	GET_LINE
	TEST	BYTE PTR [INSFLG],-1
	JZ	GETCOMJP
	mov	al,[insflgdef]
	MOV	BYTE PTR [INSFLG],al	;let INS/OVRWRT be default mode
	CALL	CURS_NORM
GETCOMJP:
	MOV	BX,LNUMBS
	CMP	WORD PTR [BX],1
	JE	GETCOM		;CR ONLY
	JB	GO_PAGEUP?	;CTRL_C
GETCOMIN:
	CALL	CURSOFF
	CALL	NL

;encode the input data

	CALL	ENCODE
	cmp	byte ptr [directflg],0

;execute if command

	jne	DIRECT			;direct mode

;store if text

	call	troffsub
	MOV	[CONTADR],0		;CONT unable
	mov	[contcsp],limit
	mov	[errortrap],0
	CALL	SETIN

;repeat input

	CMP	BYTE PTR CS:[MAININ],0B8H	;TRACE ON?
	JMPNZ	GETCOM		;IF OFF
	JMP	READY

GO_PAGEUP?:			;CTRL_C handling
	TEST	BYTE PTR [AUTOFLG],-1
	JZ	GO_PAGEUP
	MOV	BYTE PTR [AUTOFLG],0
	CALL	NL
	JMP	READY
GO_PAGEUP:
	CALL	PAGE_UP
	JMP	GETCOM

;* direct mode

directtoolong:
        jmp     toolongline

DIRECT:	
	MOV	[AUTOFLG],0

;put END MARK and go execute routine

	MOV	SI,CODBUF+2
	MOV	CX,DI
	SUB	CX,SI
	cmp     cx,directbufsize-4
	ja      directtoolong
	MOV	DI,DIRECTBUF
	MOV	AX,CX
	STOSW				;BYTES
	REP	MOVSB
	MOV	WORD PTR [DI],0		;set endmark

	mov	si,directbuf+2
	mov	ax,[si]
	cmp	ax,8780h		;pass compile if 'asave'
	je	direct50		;or 'new ' for variable full
	cmp	ax,8e80h		;recovery
	je	direct50
	cmp	ax,8080h		;or 'list'
	je	direct50
	cmp	ax,9780h		;or 'edit'
	je	direct50
	cmp	ax,8d80h		;or 'system'
	je	direct50
	cmp	ax,8380h		;or 'delete'
	je	direct50
	call	make_label_table
	call	compilevar
	mov	si,directbuf+2
	call	compilevardirect

direct50:
	MOV	BP,DIRECTBUF+2
	JMP	MAINLP


small_code:
	cmp	al,'$'-80h		;symbol of COMMON DATA
	je	go_common
	JMP	SYNERR
go_common:
	jmp	letcommon


;* loop for each command

;skip the top of line

	myalign
INTER:	
	INC	BP		;PASS #SPACE
INTER1:
	MOV	AX,[BP]	
	CMP	AL,NCODE_LABEL
	JNE	MAININ

PASSLABEL:
	MOV	AL,AH
	XOR	AH,AH
	ADD	AX,4
	ADD	BP,AX

	myalign
MAININ:
	XOR	AX,AX
	MOV	DS,AX
	MOV	BX,0418H
	CMP	[BX],AL		;KEY BUFFER を チェック
	mov	ax,ss
	mov	ds,ax
	jne	CHKCTRL_C	;KEY 入力があったら調べる

;ここからテキストの解釈

	myalign
MAINLP:				;CONT の入口
	XOR	AH,AH
	MOV	AL,[BP]
	INC	BP
	CMP	AL,CR
	JE	LINEND		;CR は行の終わり
	SUB	AL,80H
	jb	small_code
	CMP	AL,4FH		;0CFH-80H
	ja	notcmd

	SHL	AX,1
	ADD	AX,OFFSET JMPTBL
	MOV	BX,AX
	JMP	CS:[BX]		;各命令の処理へ

notcmd:
	cmp	al,51h		;0d1h-80h
	je	deffnreturn	;single = is only used by deffn
	jmp	synerr


;行の終わりに来た時

LINEND:
	CMP	WORD PTR [BP],0
	JE	GO_ENDIN	;実行終了
	ADD	BP,5		;PASS LINE#
	JMP	INTER1

GO_ENDIN:
	CMP	BP,TXTHED
	JMPNC	ENDIN

	CMP	BYTE PTR CS:[MAININ],0B8H	;1ST BYTE OF MOV AX,ADDRESS
	JE	GO_DEBUG	;TRACE MODE
	JMP	READY		;DIRECT MODE
GO_DEBUG:
	JMP	DEBUGLP


chkctrl_c:
	mov	ah,1
	int	16h
	jz	mainlp

	cmp	al,CTRL_C
	jne	mainlp

	mov	ah,0
	int	16h
;chkctrel_cjp:
	cmp	[stopflg],0
	je	mainlp
	JMP	BREAK


;
; * PRINT における CTRL_S の検査
;   スピードは必要ない
;
chkctrl_s:
	push	bx
	mov	bl,ctrl_s
	mov	bh,bl

chkctrl_in:			;check bl,bh 
	push	ax
	push	dx

	push	ds
	mov	ax,0040h
	mov	ds,ax
	mov	al,ds:[0017h]
	pop	ds
	test	al,00000100b	;check control key
	jz	chkctrlret

	mov	ah,1
	int	16h
	JZ	chkctrlret
	CMP	AL,bl
	JE	chkctrlget_s
	CMP	AL,bh
	JE	chkctrlget_c

;	MOV	AH,6		;DIRECT CONSOLE INPUT
;	MOV	DL,0FFH
;	INT	21H

chkctrlret:
	clc
chkctrlret2:
	pop	dx
	pop	ax
	pop	bx
	RET

chkctrlget_s:
	mov	ah,1
	int	16h

	push	ds
	mov	ax,ss
	mov	ds,ax
	call	cursor
	pop	ds
	call	curson
	mov	ah,0	;MOV	AH,7		;wait next key input
	int	16h	;INT	21H
	call	cursoff
	CMP	AL,CTRL_C
	jne	chkctrlret

chkctrlget_c:
	cmp	bh,ctrl_c
	jne	chkctrlget_c_out
	stc
	jmp	chkctrlret2

chkctrlget_c_out:
	xor	bp,bp
	jmp	break

;
; * LIST 等における CTRL_S,CTRL_S の検査
;   スピードは必要ない
;
chkctrl_cs:
	push	bx
	mov	bl,ctrl_s
	mov	bh,ctrl_c
	jmp	chkctrl_in


farchkctrl_cs:
	call	chkctrl_cs
	retf


;☆入力モードに行く為の定数の初期化


READY1:	
	MOV	BX,0101H
	MOV	WORD PTR [BX],OFFSET BREAK

;display 'OK' and goto HOTST

READY:	
	STI
	CALL	NL
	MOV	DX,OFFSET RDYMSG
	CALL	MSG		;CRT only
	JMP	HOTST


;* display 1 character

putchar:
	push	bx
	push	cx
	xor	bx,bx
	mov	bl,byte ptr ss:[tcolor+1]
	mov	cx,1
	mov	ah,09h
	push	ax
	int	10h		;display
	pop	ax
	mov	ah,bl		;set on vvram
	stosw

	pop	cx
	pop	bx
	ret

putdummy:
	push	bx
	push	cx
	xor	bx,bx
	mov	bl,byte ptr ss:[tcolor+1]
	mov	cx,1
	mov	ax,0920h
	int	10h		;display space

	mov	ah,bl		;set vvram
	mov	al,dummychar
	stosw

	pop	cx
	pop	bx
	ret

PRCHRSUB:
	push	ds
	push	es
	pushall

	smov	ds,ss

  if JAPANESE
	TEST	BYTE PTR [KANJIMEM],-1
	JNZ	KANJI2ND
	CALL	KANJI1ST?
	JC	KANJIIN
  endif
PRCHRSUBIN:			;in: al = code
	CMP	AL,20H
	JB	CTRL_KEY
  if JAPANESE
	call	onkanji1st?
	pushf			;*
  endif
	push	ax		;**

	mov	dl,[xpos]
	mov	dh,[ypos]
comment %
	cmp	dl,[chars1]
	jb	prchrsub20
	xor	dl,dl
	mov	[xpos],dl
	inc	dh
	cmp	dh,[btmline]
	jb	prchrsub10
	dec	dh
	call	far ptr farScrollUp
prchrsub10:
	mov	[ypos],dh
prchrsub20:
%
	xor	bx,bx
	mov	ah,2
	int	10h		;set cursor position

	mov	al,[ypos]	;write on vvram
	mov	ah,[chars1]
	mul	ah
	add	ax,word ptr [xpos]
	shl	ax,1
	mov	di,ax
	mov	es,[vramsegnow]

	pop	ax		;**
	call	putchar

	inc	[xpos]

  if JAPANESE
	popf			;*
	jnc	prchrsubret

	mov	al,' '		;display ' '
	call	putchar

	mov	dl,[xpos]
	dec	dl
	mov	dh,[ypos]
	xor	bx,bx
	mov	ah,2
	int	10h		;set cursor position
	sub	di,4
	mov	al,es:[di]	;display code again
	call	putchar
	inc	dl
	mov	ah,2
	int	10h		;set cursor position
	mov	al,' '		;display ' ' again
	call	putchar
  endif

prchrsubret:
	mov	dl,[xpos]
	mov	dh,[ypos]
	cmp	dl,[chars1]
	jb	prchrsub120
	xor	dl,dl
	mov	[xpos],dl
	inc	dh
	cmp	dh,[btmline]
	jb	prchrsub110
	dec	dh
	call	far ptr farScrollUp
prchrsub110:
	mov	[ypos],dh
prchrsub120:

prchrsubout:
	popall
	pop	es
	pop	ds
	RET


	
; CONTROL コードの処理

CTRL_KEY:
	cmp	al,28
	JA	CTRL_OUT
	XOR	BX,BX
	MOV	BL,AL
	shl	bx,1
	ADD	BX,OFFSET CTRL_TBL
	CALL	[BX]
CTRL_OUT:
	JMP	PRCHRSUBout


  if JAPANESE
;漢字の一文字目の場合=メモするだけ

KANJIIN:
	MOV	[KANJIMEM],AL
	jmp	prchrsubout

;漢字の二文字目の場合=まとめて表示

KANJI2ND:
	mov	ah,al
	mov	al,[kanjimem]
	mov	[kanjimem],0
	push	ax		;☆

	mov	dl,[xpos]
	mov	dh,[ypos]
	cmp	dl,[chars1]
	jb	kanji20
	xor	dl,dl
	mov	[xpos],dl
	inc	dh
	cmp	dh,[btmline]
	jb	kanji10
	dec	dh
	call	far ptr farScrollUp
kanji10:
	mov	[ypos],dh
kanji20:
	xor	bx,bx
	mov	ah,2
	int	10h		;set cursor position

	cmp	[insflg],0
	je	kanjidisp10

;	call	far ptr farmake1space	;make 1 more space

kanjidisp10:
	mov	es,[vramsegnow]
	mov	al,[ypos]
	mov	ah,[chars1]
	mul	ah
	add	ax,word ptr [xpos]
	shl	ax,1
	mov	di,ax		;current vvram addr

	mov	al,[xpos]
	inc	al
	cmp	al,[chars1]
	jb	kanjidisp20	;normal

	call	putdummy
;	mov	al,' '		;set dummy char
;	call	putchar

	mov	[xpos],0

	mov	al,[ypos]
	inc	al
	mov	[ypos],al
	cmp	al,[btmline]
	jb	kanjidisp20

	call	far ptr farScrollUp
	dec	[ypos]
	sub	di,[chars2]

kanjidisp20:
	mov	dl,[xpos]
	mov	dh,[ypos]
	xor	bx,bx
	mov	ah,2
	int	10h		;set cursor position

	mov	al,es:[di]
	call	kanji1st?
	jc	kanjidisp30	;if on kanji

	;if on ANK

	mov	al,es:[di+2]
	call	kanji1st?
	jnc	kanjidisp30	;if on ANK+ANK

	;if on ANK+kanji

	pop	cx		;☆

	mov	al,cl
	call	putchar

	mov	dl,[xpos]
	inc	dl
	mov	dh,[ypos]
	xor	bx,bx
	mov	ah,2
	int	10h		;set cursor position

	mov	al,ch
	call	putchar
	inc	dl
	mov	ah,2
	int	10h		;set cursor position

	mov	al,' '
	call	putchar

	add	[xpos],2

	jmp	prchrsubout

kanjidisp30:			;if on ANK+ANK or on KANJI
	pop	cx		;☆

	mov	al,cl
	call	putchar
	mov	dl,[xpos]
	inc	dl
	mov	dh,[ypos]
	xor	bx,bx
	mov	ah,2
	int	10h		;set cursor position

	mov	al,ch
	call	putchar

	add	[xpos],2

	jmp	prchrsubout


;	SHIFT-JIS から JIS へ
;	INPUT	:AX SHIFT-JIS CODE ('亜'なら AX=889FH)
;	OUTPUT	:AX JIS CODE	   ('亜'なら AX=3021H)
;	DESTROY	:AX only
;
;	注意	CRT CODE は JIS+6000H と JIS-2000H の２ワードをそれぞ
;	れ上位バイトから置いたものなのでワード単位でセットする場合は
;	AH,ALを交換しなければならない。

farSJIS_JIS:
	call	SJIS_JIS
	retf

SJIS_JIS	PROC
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
SJIS_JIS	ENDP
  endif


;☆カーソルの移動
;破壊	フラグのみ

farCURSOR:
	call	CURSOR
	retf

CURSOR:
	PUSH	AX
	PUSH	BX
	PUSH	DX

  if JAPANESE
	call	onkanji2nd?
	jnc	cursor5
	dec	[xpos]
  endif
cursor5:
	mov	dl,[xpos]
	mov	dh,[ypos]
	cmp	dl,[chars1]
	jb	cursor20
	xor	dl,dl
	mov	[xpos],dl
	inc	dh
	cmp	dh,[btmline]
	jb	cursor10
	dec	dh
	call	far ptr farScrollUp
cursor10:
	mov	[ypos],dh
cursor20:
	MOV	AH,2
	MOV	BH,0		;PAGE
	INT	10H

	POP	DX
	POP	BX
	POP	AX
	RET


farcurson:
	call	curson
	retf

curson:
	test	ss:[insflg],-1
	jnz	curs_block
	jmp	curs_norm

farcursoff:
	call	cursoff
	retf

cursoff:
	push	ax
	push	cx

	mov	cx,2000h
	mov	ah,1
	int	10h

	pop	cx
	pop	ax
	ret

curs_norm:
	push	ax
	push	cx

	mov	cx,cs:[curs_form]
	mov	ah,1
	int	10h

	pop	cx
	pop	ax
	ret

curs_block:
	push	ax
	push	cx

	mov	cx,000eh
	mov	ah,1
	int	10h

	pop	cx
	pop	ax
	ret


GET_DATA	PROC
	CALL	GET_LTOP
	MOV	DI,INPBUF

	mov	ss:[lines2get],_lines2get
getdatalp:
	CALL	MOVE80
	or	al,al
	jz	GETD30
	CMP	SI,ss:[btmadr]
	JE	GETD30		;最終行に達した

	dec	ss:[lines2get]
	jnz	getdatalp
	jmp	GETD50		;長過ぎる

comment %
	CALL	MOVE80
	or	al,al
	jz	GETD30
	CMP	SI,ss:[btmadr]
	JE	GETD30		;最終行に達した

	CALL	MOVE80
	or	al,al
	jz	GETD30
	CMP	SI,ss:[btmadr]
	JE	GETD30		;最終行に達した

	CALL	MOVE80
	or	al,al
	jz	GETD30
	CMP	SI,ss:[btmadr]
	JE	GETD30		;最終行に達した

	CALL	MOVE80
	or	al,al
	jnz	GETD50			;長過ぎる(5 行を超えた)
%
GETD30:
	smov	ds,ss
	MOV	AX,SI
	shr	ax,1
	MOV	BL,[chars1]
	DIV	BL
	CMP	AL,[btmline]
	JB	GETD35
	CALL	SCROLLUP
	mov	al,[btmline]
	dec	al
GETD35:
	MOV	[xpos],0
	MOV	[YPOS],AL
GETD40:
	CMP	DI,INPBUF
	JE	GETD45
	DEC	DI		;後ろの 00H,20H をカット
	MOV	AL,[DI]
	OR	AL,AL
	JZ	GETD40
	CMP	AL,' '
	JE	GETD40
	INC	DI
GETD45:
	MOV	BYTE PTR [DI],CR
	MOV	SI,INPBUF
	SUB	DI,SI
	MOV	CX,DI
	INC	DI
	MOV	BX,LNUMBS
	MOV	[BX],DI
	JCXZ	GETD48
	MOV	AH,' '
GETD46:
	LODSB
	OR	AL,AL
	JNZ	GETD47
	MOV	[SI-1],AH	;0 を 20H に変える
GETD47:
	myloop	GETD46
GETD48:
	CALL	CURSOR
	CLC
	RET

getd50:
	CALL	MOVE80
	or	al,al
	jz	GETD55
	CMP	SI,ss:[btmadr]
	JB	GETD50
	smov	ds,ss
	CALL	SCROLLUP
	MOV	[xpos],0
	mov	al,[btmline]
	dec	al
	MOV	[YPOS],al
	STC
	RET
getd55:
	smov	ds,ss
	mov	ax,si
	shr	ax,1
	mov	bl,[chars1]
	div	bl
	dec	al
	mov	[ypos],al
	stc
	ret


MOVE80:				;一行分を BUFFER に移し SI,DI を更新
	MOV	CX,word ptr ss:[chars1]
MOVE80LP:
	LODSW
	cmp	al,dummychar
	je	move80jp
	STOSB
MOVE80JP:
	myloop	MOVE80LP
	RET


GET_LTOP:
	MOV	ds,ss:[vramsegnow]
	MOV	AL,SS:[YPOS]
	MOV	AH,ss:[chars1]
	MUL	AH
	shl	ax,1
	MOV	SI,AX		;現在行の先頭アドレス
GETLT10:
	OR	SI,SI
	JZ	GETLT20		;VRAM の先頭に達した
	CMP	byte PTR [SI-2],0
	JE	GETLT20		;0 を切れ目と見なす
	SUB	SI,ss:[chars2]
	JMP	GETLT10
GETLT20:
	RET

GET_DATA	ENDP	

;
;☆インサート・モードでカーソル位置に SPACE を空ける
;

MAKE1SPACE:
	cmp	al,20h
	jb	make1spcut
	call	cursoff
	call	far ptr farMake1space
	call	curson
	call	cursor
make1spcut:
	ret


CODE	ENDS


code2	segment	public
	assume	cs:code2,ds:data

	public	farCURS_HOME
	public	farCLEAR_BELOW,farNEW_LINE
	public	farLEFT_ERASE,farRIGHT_ERASE
	public	farCLEAR_SCREEN,farCURS_HOME
	public	farCAR_RET,farCURS_BACK,farCURS_DEL
	public	farCURS_RIGHTEND,farCURS_TAB
	public	farCURS_RIGHT,farCURS_LEFT
;	public	farCURS_RIGHTnoNL
	public	farCURS_LEFTEND,farCURS_UP,farCURS_DOWN
	public	farSCROLLUP,farSCROLLDOWN

  if JAPANESE
	public	kanji1st2
  endif
	extrn	farHELP:far


;
;☆インサート・モードでカーソル位置に SPACE を空ける
;

  if JAPANESE
kanji1st2:
	CMP	AL,81H
	JB	NO_K1ST2
	CMP	AL,9FH
	JBE	YES_K1ST2
	CMP	AL,0E0H
	JB	NO_K1ST2
	CMP	AL,0FCH
	JBE	YES_K1ST2
NO_K1ST2:
	CLC
	RET
YES_K1ST2:
	STC
	RET
  endif

even
lineend		dw	?
displayedchars	dw	?

farMAKE1SPACE:

	PUSH	DS
	PUSH	ES
	pushall

	mov	al,ss:[ypos]
	mov	ah,ss:[chars1]
	mul	ah
	shl	ax,1
	mov	bx,ax		;BX=top adr of the current line

	mov	ax,ss:[vramsegnow]
	mov	ds,ax
	mov	ax,ss
	add	ax,ASCBINSEG
	mov	es,ax
	xor	di,di
	mov	cs:[lineend],di
	mov	si,bx

	;copy 1st line to buffer

	mov	cx,word ptr ss:[xpos]
	mov	cs:[displayedchars],cx
	rep	movsw

	mov	ax,ss:[tcolor]
	mov	al,' '
	stosw
	mov	cx,word ptr ss:[chars1]
	sub	cx,word ptr ss:[xpos]
	rep	movsw

	;check last char
makespc30:
	sub	di,2
	mov	ax,es:[di]
	cmp	al,dummychar
	je	makespc50
	or	al,al
	jz	makespc40
	add	di,2
	jmp	makespc50	;no separator
makespc40:
	or	di,di
	jz	makespc45
	sub	di,2
	cmp	byte ptr es:[di],0
	je	makespc40		
	add	di,2
makespc45:
	add	di,2
	jmp	makespc100	;find separator

	;no separator case = to be continued to next line
makespc50:
	mov	cs:[lineend],di

	;copy to VRAM

	push	ds		;exchange ds,es
	push	es
	pop	ds
	pop	es

	xor	si,si
	mov	di,bx
	mov	cx,word ptr ss:[chars1]
	dec	cx
makespc60:
	lodsw
	stosw
  if JAPANESE
	call	kanji1st2
	jc	makespc62
  endif
	myloop	makespc60
  if JAPANESE
	jmp	makespc64
makespc62:
	movsw			;copy kanji2nd
	dec	cx
	jz	makespc80	;done +1
	myloop	makespc60
makespc64:
  endif
	lodsw
  if JAPANESE
	call	kanji1st2
	jc	makespc70	;if Kanji1st
   endif
makespc65:
	stosw
  if JAPANESE
	jmp	makespc80
makespc70:
	sub	si,2
	mov	ax,ss:[tcolor]
	mov	al,dummychar
	stosw
  endif
makespc80:
	mov	dx,word ptr ss:[chars1]
	push	si
	mov	si,bx
	call	makespcsub
	pop	si

	mov	ax,ds
	mov	dx,es		;memo push
	mov	es,ax
	mov	cx,cs:[lineend]
	sub	cx,si
	shr	cx,1
	jz	make1spret	;no overflow = done all
	xor	di,di
	rep	movsw
	mov	cs:[lineend],di

	;copy next line to buffer

	mov	ds,dx		;memo pop
	add	bx,ss:[chars2]
	cmp	bx,ss:[btmadr]
	jae	makespc182	;no separation and ended
	mov	si,bx
	mov	cx,word ptr ss:[chars1]
	rep	movsw

	push	bx
	xor	bx,bx
	mov	ah,3
	int	10h		;get cursor position
	or	dl,dl
	jz	makespc90
	xor	dl,dl
	inc	dh
makespc90:
	mov	ah,2
	int	10h		;set cursor position
	pop	bx
	jmp	makespc30

makespc100:
	mov	cs:[lineend],di
	mov	dx,di
	shr	dx,1		;overflowed chars

	;process of last line
	;copy to VRAM

	push	ds		;exchange ds,es
	push	es
	pop	ds
	pop	es

	xor	si,si
	mov	di,bx
	mov	cx,word ptr ss:[chars1]
	dec	cx
	cmp	cx,dx
	jbe	makespc150
	mov	cx,dx
makespc150:
	xor	dx,dx		;counter
makespc160:
	inc	dx
	lodsw
	stosw
  if JAPANESE
	call	kanji1st2
	jc	makespc162
  endif
	myloop	makespc160
  if JAPANESE
	jmp	makespc164
makespc162:
	inc	dx
	movsw			;copy kanji2nd
	dec	cx
	jz	makespc180	;done +1
	myloop	makespc160
makespc164:
  endif
	cmp	si,cs:[lineend]
	jae	makespc200	;done all

	lodsw
  if JAPANESE
	call	kanji1st2
	jc	makespc170	;if Kanji1st
  endif
makespc165:
	inc	dx
	stosw
	cmp	si,cs:[lineend]
	jb	makespc180
	jmp	makespc200	;done all
  if JAPANESE
makespc170:
	sub	si,2
	mov	ax,ss:[tcolor]
	mov	al,dummychar
	inc	dx
	stosw
  endif
makespc180:
	smov	es,ds
	mov	cx,cs:[lineend]
	sub	cx,si
	shr	cx,1
	xor	di,di
	add	dx,cx
	rep	movsw
	or	di,di
;	jz	makespc200	;no overflow=done all
	mov	cs:[lineend],di

	mov	si,bx
	call	makespcsub

	add	bx,ss:[chars2]
makespc182:
	cmp	bx,ss:[btmadr]
	jb	makespc185	;if not on the last line
	mov	al,ss:[ypos]
	cmp	al,ss:[topline]
	je	makespc200	;neglect overflowed chars
	call	far ptr farScrollup
	dec	ss:[ypos]
	sub	bx,ss:[chars2]

	push	bx
	xor	bx,bx
	xor	dl,dl
	mov	dh,ss:[btmline]
	dec	dh
	mov	ah,2
	int	10h		;set cusor position on the left bottom
	pop	bx
	jmp	makespc187


makespc185:			;slide down and make a blank line

	mov	ax,ss:[vramsegnow]
	mov	ds,ax
	mov	es,ax

	mov	cx,word ptr ss:[chars1]
	mov	di,bx
	xor	ax,ax
makespc185a:
	scasb
	jne	makespc185b
	inc	di
	myloop	makespc185a
	jmp	makespc187	;next line all blank
makespc185b:
	inc	di
	mov	ax,bx
	shr	ax,1
	mov	dl,ss:[chars1]
	div	dl
	mov	ch,al
	xor	cl,cl
	dec	dl
	mov	dh,ss:[btmline]
	dec	dh
	mov	ah,7
	mov	al,1
	push	bx		;*
	xor	bx,bx
	int	10h		;slide down

;	mov	ah,3
;	int	10h		;get cursor position
;	dec	dh
;	mov	ah,2
;	int	10h		;set cusor position
	pop	bx		;*

	mov	cx,ss:[btmadr]
	mov	di,cx
	sub	di,2

	std			;!
	sub	cx,bx
	shr	cx,1
	sub	cx,word ptr ss:[chars1]
	jz	makespc186	;only overwrite blank

	mov	si,di
	sub	si,ss:[chars2]
	rep	movsw
makespc186:
	mov	cx,word ptr ss:[chars1]
	mov	ax,ss:[tcolor]
	rep	stosw
	cld			;!

makespc187:
	mov	ax,ss
	add	ax,ASCBINSEG
	mov	ds,ax
	mov	es,ss:[vramsegnow]

	mov	cx,cs:[lineend]
	shr	cx,1
	mov	dx,cx
	xor	si,si
	mov	di,bx
	rep	movsw
	
makespc200:
	mov	si,bx
	call	makespcsub

MAKE1SPRET:
	popall
	POP	ES
	POP	DS
	RETf

makespcsub:			;inp si,dx
	push	ds
	push	bx
	mov	ds,ss:[vramsegnow]
	mov	cx,cs:[displayedchars]
	add	si,cx
	add	si,cx
	sub	cx,dx
	neg	cx
	jcxz	makespcsub20

	push	cx
	xor	bx,bx
	mov	ah,3
	int	10h		;get cursor position
	pop	cx

makespcsub10:
	lodsw
	cmp	al,dummychar
	je	makespcsub30
makespcsub15:
	push	cx
	mov	cx,ax		;memo

	mov	ah,2
	int	10h		;set cursor position

	mov	al,cl
	mov	bl,ch
	mov	cx,1
	mov	ah,09h
	int	10h

	inc	dl
	cmp	dl,ss:[chars1]
	jb	makespcsub16
	xor	dl,dl
	inc	dh
makespcsub16:
	pop	cx
	myloop	makespcsub10
makespcsub20:
	mov	cs:[displayedchars],0
	pop	bx
	pop	ds
	ret
makespcsub30:
	mov	al,' '
	jmp	makespcsub15


farNEW_LINE:
	push	ds
	push	es
	pushall

	;scroll down display

	mov	ax,0701h	;down 1 line
	xor	cx,cx
	mov	ch,[ypos]
	mov	dh,[btmline]
	dec	dh
	mov	dl,[chars1]
	dec	dl
	mov	bx,[tcolor4fill]
	int	10h

	;scroll down vvram

	mov	al,[ypos]
	mov	ah,[chars1]
	mul	ah
	shl	ax,1
	mov	cx,[btmadr]
	sub	cx,ax
	sub	cx,[chars2]	;cut 1 line
	shr	cx,1		;SCROLL DOWN する文字数
	mov	di,[btmadr]
	sub	di,2		;最終行の最後
	mov	si,di
	sub	si,[chars2]

	MOV	AX,[vramsegnow]
	MOV	DS,AX
	MOV	ES,AX		;SEGMENT
	STD

	rep	movsw
	mov	ax,ss:[tcolor]
	mov	cx,word ptr ss:[chars1]
	rep	stosw
	CLD

	popall
	pop	es
	pop	ds
	retf


farCLEAR_SCREEN:
	push	ax
	mov	ss:[xpos],0
	mov	al,ss:[topline]
	mov	ss:[ypos],al
	pop	ax
farCLEAR_BELOW:
	push	es
	pushall

	mov	al,ss:[ypos]
	mov	ah,ss:[chars1]
	mul	ah
	shl	ax,1
	mov	di,ax
	mov	cx,ss:[btmadr]
	sub	cx,ax
	shr	cx,1
	mov	es,ss:[vramsegnow]
	mov	ax,ss:[tcolor]
	rep	stosw

;  	cmp	[graphflg],0
;	jne	nonsclr
	mov	ch,ss:[ypos]
	xor	cl,cl
	mov	dh,ss:[btmline]
	dec	dh
	mov	dl,ss:[chars1]
	dec	dl
	mov	bx,ss:[tcolor4fill]
	mov	ax,0600h
	int	10h
nonsclr:
	call	far ptr farcursor
	
sclrret:
	popall
	pop	es
	retf



farRIGHT_ERASE:			;CUSOR 位置から右のCLEAR
	PUSH	ES
	pushall

	MOV	AL,[YPOS]
	MOV	AH,[chars1]
	MUL	AH
	MOV	DI,WORD PTR [xpos]
	MOV	CX,word ptr [chars1]
	SUB	CX,DI		;その行の消すべき文字数
	add	di,ax
	shl	di,1		;offset

	MOV	es,ss:[vramsegnow]
	mov	ax,ss:[tcolor]
RERASE10:
	DEC	CX
	REP	STOSW
	CMP	ES:[DI],al
	JE	RERASE20
	STOSW
	MOV	CX,word ptr ss:[chars1]
	CMP	DI,ss:[btmadr]
	JNE	RERASE10
RERASE20:
	mov	ch,ss:[ypos]
	mov	cl,ss:[xpos]
	mov	dh,ch
	mov	dl,ss:[chars1]
	dec	dl
	xor	bx,bx
;  	cmp	[graphflg],0
;	jne	rerase350
	mov	bx,ss:[tcolor4fill]
rerase30:
	mov	ax,0600h
	int	10h
rerase350:

	JMP	SCLRRET


farLEFT_ERASE:
	retf



farCURS_HOME:
	MOV	[xpos],0
;	push	ax
;	mov	al,[topline]
;	MOV	[YPOS],AL
;	pop	ax
	RETf


farCAR_RET:
	MOV	[xpos],0
	RETf


farCURS_BACK:
	MOV	AL,[xpos]
	OR	AL,AL
	JZ	CBACK10
	DEC	AL
	MOV	[xpos],AL
	JMPS	farCURS_DEL

CBACK10:
	MOV	AL,[YPOS]
	cmp	al,[topline]
	jne	CBACK20
	RETf			;HOME POSITION の場合

CBACK20:
	DEC	AL
	MOV	[YPOS],AL
	mov	al,[chars1]
	dec	al
	mov	[xpos],al

	mov	dl,al
	mov	dh,[ypos]
	xor	bx,bx
	mov	ah,2
	int	10h		;set cursor position

	MOV	AL,' '		;0 ではつながらない
	CALL	far ptr farPRCHR
	dec	[ypos]
	mov	al,[chars1]
	dec	al
	MOV	[xpos],al

farCURS_DEL:
	MOV	AX,ss:[vramsegnow]
	MOV	DS,AX
	MOV	ES,AX

	push	bx		;*
	mov	al,ss:[YPOS]
	mov	ah,ss:[chars1]
	mul	ah
	shl	ax,1
	mov	di,ax
	mov	bx,ax		;top adr of current line
	mov	dx,ax
cdel10:
	add	bx,ss:[chars2]
	cmp	byte ptr [bx-2],0
	je	cdel20
	cmp	bx,ss:[btmadr]
	jb	cdel10
cdel20:
	cmp	bx,dx
	jbe	cdelallout
	sub	bx,2
	cmp	byte ptr [bx],0
	je	cdel20
	add	bx,2		;now bx=next adr of slide end	

	mov	cx,word ptr ss:[xpos]
	add	di,cx
	add	di,cx
	lea	si,[di+2]
	mov	ch,ss:[chars1]
	dec	ch		;max xpos

	xor	dx,dx		;counter
	push	di		;**
cdel30:
	cmp	si,bx
	jae	cdelret
	lodsw
	cmp	al,dummychar
	je	cdel30
  if JAPANESE
	call	kanji1st2
	jc	cdel40		
  endif
  	inc	dx
	stosw			;if 1byte char
cdel35:
	inc	cl
	cmp	cl,ch
	jbe	cdel30
	xor	cl,cl
	jmp	cdel30

  if JAPANESE
cdel40:				;if 2byte char
	cmp	cl,ch
	je	cdel50
cdel45:
	inc	dx
	stosw
	inc	dx
	movsw
	inc	cl
	jmp	cdel35
cdel50:
	push	ax
	mov	ax,ss:[tcolor]
	mov	al,dummychar
	inc	dx
	stosw
	pop	ax
	xor	cl,cl
	jmp	cdel45
  endif

CDELRET:
	mov	ax,ss:[tcolor]
cdelretlp:
	cmp	di,bx
	jae	cdelretout
	inc	dx
	stosw
	jmp	cdelretlp
cdelretout:
	push	dx		;***

	mov	dl,ss:[xpos]
	mov	dh,ss:[ypos]
	xor	bx,bx
	mov	ah,2
	int	10h		;set cursor position

	pop	cx		;***
	pop	si		;**
	smov	ds,es
	jcxz	cdelallout
	call	far ptr farCursoff
cdelprintlp:
	lodsw

	push	cx
	mov	bl,ah
	mov	cx,1
	mov	ah,09h
	int	10h
	inc	dl
	cmp	dl,ss:[chars1]
	jb	cdelprintjp
	xor	dl,dl
	inc	dh
cdelprintjp:
	mov	ah,2
	int	10h		;set cursor position
	pop	cx
	myloop	cdelprintlp
cdelallout:
	pop	bx		;*

	syskeyclear		;KEY BUFFER CLEAR & INPUT

	smov	ds,ss
	smov	es,ss
	jmp	far ptr farcurson	;call & ret


farCURS_TAB:
	MOV	AL,[xpos]
	ADD	AL,8
	CMP	AL,[chars1]
	JAE	CURS_R10
	AND	AL,11111000B
	MOV	[xpos],AL	
	RETf


farCURS_RIGHT:
	MOV	AL,[xpos]
	inc	al
	CMP	AL,[chars1]
	JE	CURS_R10
	MOV	[xpos],AL
	RETf
CURS_R10:
	MOV	[xpos],0
	MOV	AL,[YPOS]
	inc	al
	CMP	AL,[btmline]
	JE	CURS_R20
	MOV	[YPOS],AL
	RETf
CURS_R20:
	jmp	far ptr farLETNL	;call & ret


comment %
farCURS_RIGHTnoNL:
	MOV	AL,[xpos]
	inc	al
	CMP	AL,[chars1]
	JE	CURS_RN10
	MOV	[xpos],AL
	RETf
CURS_RN10:
	MOV	[xpos],0
	MOV	AL,[YPOS]
	inc	al
	CMP	AL,[btmline]
	JE	CURS_RN20
	MOV	[YPOS],AL
	RETf
CURS_RN20:
	push	ds
	push	es
	push	ax
	push	cx
	push	si
	push	di

	MOV	AX,ss:[vramsegnow]	;scroll up virtual VRAM
	MOV	DS,AX
	MOV	ES,AX
	MOV	SI,ss:[chars2]
	MOV	DI,0
	MOV	CX,ss:[charsallnow]
	sub	cx,word ptr ss:[chars1]
	REP	MOVSW
	mov	ax,ss:[tcolor]
	MOV	CX,word ptr ss:[chars1]
	REP	STOSW

	pop	di
	pop	si
	pop	cx
	pop	ax
	pop	es
	pop	ds
	retf
%

farCURS_RIGHTEND:
	mov	cx,word ptr ss:[chars1]
	MOV	ds,ss:[vramsegnow]
	mov	ax,word ptr ss:[ypos]
	inc	ax
	mul	cx
	dec	ax
	shl	ax,1
	MOV	SI,AX		;end adr of current line
	inc	cx		;chars+1
	STD
CURSRE10:
	dec	cx
	jz	CURSRE20	;out of the desplay
	LODSW
	OR	AL,AL
	JZ	CURSRE10

	cmp	cx,word ptr ss:[chars1]
	jne	cursre20
	dec	cx
CURSRE20:
	CLD
	smov	ds,ss
	MOV	[xpos],CL
	RETF

farCURS_LEFT:
	MOV	AL,[xpos]
	OR	AL,AL
	JZ	CURS_L10
	DEC	AL
	MOV	[xpos],AL
	RETf
CURS_L10:
	MOV	AL,[YPOS]
	OR	AL,AL
	JZ	CURS_L20
comment %
	push	ds
	MOV	ds,ss:[vramsegnow]
	MOV	AL,SS:[YPOS]
	MOV	AH,ss:[chars1]
	MUL	AH
	shl	ax,1
	mov	si,ax
	cmp	byte ptr [si],0
	pop	ds
	je	curs_l20
%
	dec	[YPOS]
	mov	al,[chars1]
	dec	al
	MOV	[xpos],al
CURS_L20:
	RETf


farCURS_LEFTEND:
	MOV	[xpos],0
	RETf

farCURS_UP:
	MOV	AL,[YPOS]
	OR	AL,AL
	JZ	CURS_UPRET	;	JZ	CURS_UP10
	DEC	AL
	MOV	[YPOS],AL
CURS_UPRET:
	RETf

farCURS_DOWN:
	MOV	AL,[YPOS]
	inc	al
	CMP	AL,[btmline]
	JAE	CURS_DWN10	;SCROLL UP
	MOV	[YPOS],AL
	RETf
CURS_DWN10:
	dec	al
	JMP	farSCROLLUP	;CALL & RET


;☆スクリーンをスクロールダウン
;破壊	フラグのみ


farSCROLLDOWN:
	mov	cs:[scroll_direction],7
	jmp	farscrollin


;☆スクリーンをスクロール・アップ
;破壊	フラグのみ

scroll_direction	db	?

farSCROLLUP:
	mov	cs:[scroll_direction],6

farscrollin:
	push	ds
	push	es
	pushall

	mov	ch,ss:[topline]
	mov	cl,0
	mov	dh,ss:[btmline]
	dec	dh
	mov	dl,ss:[chars1]
	dec	dl
	mov	bx,ss:[tcolor4fill]
	mov	al,1
	mov	ah,cs:[scroll_direction]
	int	10h

	mov	ax,ss:[vramsegnow]
	mov	ds,ax
	mov	es,ax

	mov	al,ss:[topline]
	cmp	cs:[scroll_direction],7
	je	farscroll10

	mov	al,ss:[topline]		;scroll up
	mov	ah,ss:[chars1]
	mul	ah
	shl	ax,1
	mov	di,ax
	mov	si,di
	add	si,ss:[chars2]
	mov	cx,ss:[charsallnow]
	sub	cx,word ptr ss:[chars1]
	rep	movsw
	mov	ax,ss:[tcolor]
	mov	cx,word ptr ss:[chars1]
	rep	stosw
	jmp	farscroll20

farscroll10:
	std				;scroll down
	mov	di,ss:[btmadr]
	sub	di,2
	mov	si,di
	sub	si,ss:[chars2]
	mov	cx,ss:[charsallnow]
	sub	cx,word ptr ss:[chars1]
	rep	movsw
	mov	ax,ss:[tcolor]
	mov	cx,word ptr ss:[chars1]
	rep	stosw
	cld

farscroll20:
	popall
	pop	es
	pop	ds
	retf


code2	ends


code3	segment	public

code3	ends


DATA	SEGMENT	PUBLIC

	PUBLIC	XPOS,YPOS,diflen,txtnow,txtnex,CHKTIMER
	public	topline,topadr,btmadr
	public	maxlinesnow,btmline,charsallnow	
	public	chars1,chars2,charsall2
	public	linesdef

	extrn	vramsegnow:word
	extrn	CONTADR:WORD,contcsp:word
	EXTRN	directflg:BYTE,INSFLG:BYTE,insflgdef:byte
	extrn	AUTOFLG:BYTE,stopflg:byte
	extrn	base_sp:word
	extrn	baseoff:word
	extrn	errortrap:word
	extrn	tcolor:word,tcolor4fill:word,graphflg:byte

;extrn arrayseg:word

	;SYSTEM CALL TABLE

	DD	USRFUNC,SYSPUSH,SYSPOP,UNDEF
	DD	UNDEF,UNDEF,UNDEF,UNDEF
	DD	SPADD,SPSUB,SPMUL,SPDIV
	DD	SPIDIV,SPMOD,SP2P,UNDEF
	DD	UNDEF,UNDEF,UNDEF,UNDEF


DIFLEN		DW	0
TXTNOW		DW	?
TXTNEX		DW	?
CHKTIMER	DB	5,0
lines2get	dw	?

CTRL_TBL	LABEL WORD
	DW	CTRL_RET,CURS_LEFTEND	;@,A
	DW	CLEAR_BELOW,CTRL_RET	;B,C
	DW	CURS_RIGHT,CURS_UP	;D,E
	DW	CURS_RIGHTEND,CURS_DEL	;F,G

	DW	CURS_BACK,CURS_TAB	;H,I
	DW	CURS_DOWN,CTRL_RET	;J,K
	DW	CLEAR_SCREEN,CAR_RET	;L,M
	DW	NEW_LINE,NEW_LINE	;N,O

	DW	CTRL_RET,CURS_HOME	;P,Q
	DW	PAGE_DOWN,CURS_LEFT	;R,S
;	DW	LEFT_ERASE,CTRL_RET	;T,U
	DW	ctrl_ret,CTRL_RET	;T,U
	DW	CTRL_INS,ROLL_DOWN	;V,W

	DW	CURS_DOWN,RIGHT_ERASE	;X,Y
	DW	ROLL_UP,ctrl_ret	;Z,ESC

	dw	goHELP			;HELP

; parameters for display

chars1		db	?,0	;characters/line
chars2		dw	?	;*2
charsall2	dw	?	;*2
linesdef	db	?,0	;lines/display

XPOS		DB	0,0
YPOS		DB	0,0
topline		db	0,0
topadr		dw	0
btmline		DB	?,0
charsallnow	DW	0
btmadr		DW	0
KANJIMEM	DB	0,0
delchars	db	0

maxlinesnow	db	?,0

RDYMSG	DB	'OK ',CR,LF,0

DATA	ENDS


END	START

