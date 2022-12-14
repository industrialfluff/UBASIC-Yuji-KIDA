;COMPILE.ASM

	INCLUDE	UBDEF.H
	INCLUDE	UB.H


DATA	SEGMENT	WORD PUBLIC

	public	compilevar_sw,labelend
	public	compilegoto_sw,compilevar_sw,compilejp_sw

	extrn	varsegnow:word,varseglim:word
	extrn	arrayseg:word,limitseg:word
	extrn	longvarsegsize:word,exlongvarsegsize:word
	extrn	txttop:word,maxall:word
	extrn	defsegdata:word,polymodulus:dword
	extrn	blocksw:byte
	extrn	overloadaddadr:word

compilegoto_sw		db	0
compilevar_sw		db	0
compilejp_sw		db	0

	even
;LABEL TABLE POINTER

LABELEND	DW	?
LABELMEMO	DW	?


DATA	ENDS



CODE	SEGMENT WORD PUBLIC
	ASSUME	CS:CODE,DS:DATA


;PUBLIC LABELS

	public	discompileall,farDiscompileall
	public	discompilegoto,farDiscompilegoto
	public	discompilevar,farDiscompilevar
	public	discompilejp,farDiscompilejp
	public	farResetvar_word	;,farResetvar_point
	
	public	compilevar,compilevardirect
	public	kanji1st?,farkanji1st?
	public	resvar,farResvar
	public	getlabelline,getlabeladr,fargetlabeladr
	public	farrep_cmpsb_label,make_label_table

	extrn	srcvar1st:near,SRCVARNEXT:near,PASSTOKEN:near
	extrn	CHG2CAP:near,RANDOMIZE_MAIN:near

	extrn	vartbl:byte,label_table:byte

	extrn	ema_close:near

	extrn	TOOMANYVAR:near,fullerr:near
	extrn	pointerr:near,worderr:near
	extrn	labelfull:near,doublelabel:near,nolerr:near


	;
	;* reset variable table for POINT
	;

comment %
farresetvar_point:
	call	resetvar_point
	retf

resetvar_point:
	mov	ax,cs
	mov	ds,ax

	xor	di,di
	mov	si,offset vartbl
resvptlp:
	mov	al,[si]
	or	al,al
	jz	resvptend
	cmp	al,0ffh
	je	resvptend
	sub	al,vcode
	jz	resvptnext	;short var is ok
	dec	al
	jz	resvptnext	;short var is ok
	dec	al
	jz	resvptlong	;long var
	dec	al
	jz	resvptlongarr	;long array
	dec	al
	jz	resvptxlong	;xlong var
	jmp	resvptxlongarr	;xlong array
resvptnext:
	add	si,namelen+2
	jmp	resvptlp
resvptend:
	mov	ax,ss
	mov	ds,ax
	mov	es,ax
	ret

resvptlong:
resvptxlong:
	mov	es,[si+namelen]
	test	word ptr es:[di],pointmask
	jz	resvptnext
	jmp	pointerr

resvptlongarr:
	mov	bx,ss:[maxall]
	shl	bx,1
	jmp	resvptarray
resvptxlongarr:
	mov	bx,unitbyte
resvptarray:			;now bx=bytes of a member
	mov	ax,[si+namelen]
	or	ax,ax
	jz	resvptnext
	push	ds		;*
	push	si		;**
	push	di		;***
	mov	ds,ax
	xor	si,si
	mov	cx,[si+4]
	inc	cx
	mov	dx,[si+6]
	mov	si,arrayhead
	mov	ax,pointmask
resvptar10:
	push	cx
	mov	cx,dx
resvptar20:
	test	[si],ax
	jnz	resvptarerr
	add	si,bx
	jc	resvptar50
resvptar30:
	myloop	resvptar20
	pop	cx
	myloop	resvptar10

	pop	di		;***
	pop	si		;**
	pop	ds		;*
	jmp	resvptnext

resvptar50:
	mov	di,ds
	add	di,1000h
	mov	ds,di
	jmp	resvptar30

resvptarerr:
	jmp	pointerr	
%


	;
	;* reset variable table for WORD
	;
farResetvar_word:
	call	resetvar_word
	retf

resetvar_word:
	mov	ax,data
	add	ax,varseg
	mov	[varsegnow],ax
	mov	es,ax

	mov	ax,[limitseg]
	mov	[varseglim],ax

	mov	ax,cs
	mov	ds,ax

	mov	si,offset vartbl
resvwordlp:
	mov	al,[si]
	or	al,al
	jz	resvwordend
	cmp	al,0ffh
	je	resvwordend
	sub	al,vcode
	jz	resvwordnext	;short var is ok
	dec	al
;	jz	resvwordsarray	;short array
	dec	al
	jz	resvwordlong	;long var
	dec	al
;	jz	resvwordlongarr	;long array
	dec	al
	jz	resvwordxlong	;xlong var
	mov	word ptr [si+namelen],0	;let array be undef
resvwordnext:
	add	si,namelen+2
	jmp	resvwordlp

resvwordlong:
	mov	dx,ss:[longvarsegsize]
	jmp	resvwordlong10
resvwordxlong:
	mov	dx,ss:[exlongvarsegsize]
resvwordlong10:
	mov	ax,es
	mov	[si+namelen],ax
	add	ax,dx
	cmp	ax,ss:[varseglim]
	ja	resvwordfullerr
	xor	bx,bx
	mov	es:[bx],bx	;let value=0

	mov	es,ax
	jmp	resvwordnext

resvwordend:
	mov	ss:[varsegnow],es

	mov	ax,ss
	mov	ds,ax
	mov	es,ax

	mov	ax,[varsegnow]
	mov	dx,[exlongvarsegsize]
	shl	dx,1		;free area for optional variables
	shl	dx,1		;4 if 10000mode
	shl	dx,1		;8 otherwise
	add	ax,dx
	mov	dx,data
	add	dx,varseg
	add	dx,800h		;minimum=32KB for normal vars
	cmp	ax,dx
	jae	resvword100
	mov	ax,dx
resvword100:	
	cmp	ax,[limitseg]
	jae	resvwordfullerr

	mov	[varseglim],ax
	mov	[arrayseg],ax
	ret

resvwordfullerr:
	jmp	fullerr


	;*
	;* search variable in text and trans to code
	;*

compilevar:
	cmp	[compilevar_sw],-1
	je	compilevarret
	mov	[compilevar_sw],-1
	call	srcvar1st		;search 1st variable
	jc	compilevar90
compilevarlp:
	lodsw
	push	ax

	mov	bx,offset vartbl
	call	register_var
	jc	compilevarerr		;area full
	mov	[si],bx

	pop	ax
	mov	al,ah
	xor	ah,ah
	add	si,ax
	call	srcvarnext	;search next variable
	jnc	compilevarlp
compilevar90:
	mov	ax,[varsegnow]
	mov	dx,[exlongvarsegsize]
	shl	dx,1		;free area for optional variables
	shl	dx,1		;4 if 10000mode
	shl	dx,1		;8 otherwise
	add	ax,dx
	mov	dx,data
	add	dx,varseg
	add	dx,800h		;minimum=32KB for normal vars
	cmp	ax,dx
	jae	compvar100
	mov	ax,dx
compvar100:	
	cmp	ax,[limitseg]
	jae	compilevarfullerr

	cmp	ax,[varseglim]
	je	compilevarret

	mov	[varseglim],ax
	mov	[arrayseg],ax

	;erase all arrays

	mov	si,offset vartbl
compvar110:
	mov	al,cs:[si]
	add	si,namelen+2
	cmp	al,0ffh
	je	compilevarret
	cmp	al,vcode1
	je	compvar120
	cmp	al,vcode3
	je	compvar120
	cmp	al,vcode5
	je	compvar120
	jmp	compvar110
compvar120:
	mov	word ptr cs:[si-2],0		;erased mark
	jmp	compvar110

compilevarret:
	ret

compilevarfullerr:
	jmp	fullerr

	;* recover coded variables

compilevarerr:
	lea	bp,[si-2]

	MOV	SI,[TXTTOP]
compverrLP0:	
	cmp	word ptr [si],0
	je	compverrend	;if end
	ADD	SI,5		;pass line# & SPACE#
compverrLP1:	
	cmp	si,bp
	jae	compverrend	;if end
	LODSB
	CMP	AL,CR
	JE	compverrLP0	;CR が出れば次行へ

	CMP	AL,NCODE_ADR
	JE	compverr50	;ADDRESS になっている
	CMP	AL,VCODE
	JB	compverrJP2
	CMP	AL,VCODE5
	JBE	compverr60	;変数
compverrJP2:
	CALL	PASSTOKEN
	JMP	compverrLP1

compverr50:
	ADD	SI,2
	JMP	compverrLP1
compverr60:
	CALL	DISVAR
	JMP	compverrLP1

compverrEND:	
	mov	[compilevar_sw],0

	jmp	toomanyvar



	;*
	;* var -> pseudo code
	;* called from direct mode and function VAL
	;* input : SI = pointer

compilevardirect:
	push	si
	call	compilevar		;check program text 
					;is compiled?
	pop	si
compilevardirectlp:
	call	srcvarnext		;search next variable
	jc	compilevardirectret

	lodsw
	push	ax

	mov	bx,offset vartbl
	call	register_var
	jc	comvardirerr	;if area full
	mov	[si],bx

	pop	ax
	mov	al,ah
	xor	ah,ah
	add	si,ax
	jmp	compilevardirectlp

compilevardirectret:
	ret

comvardirerr:
	call	discompilevar
	jmp	fullerr



	;*
	;* register variable in the table
	;*

regvfullerr2:
	sub	bx,namelen
	mov	word ptr cs:[bx],0
	pop	bp
	stc
	ret

regvlong:
	mov	dx,[longvarsegsize]
	jmp	regvlong10

regvexlong:
	mov	dx,[exlongvarsegsize]
regvlong10:
	mov	ax,[varsegnow]
	mov	cs:[bx],ax
	mov	cx,ax
	add	ax,dx
	cmp	ax,[varseglim]
	ja	regvfullerr2
	mov	[varsegnow],ax
	mov	es,cx
	xor	di,di
	xor	ax,ax
	stosw			;initialize
	mov	ax,ss
	mov	es,ax
	jmp	regvout


regvadd_here:
	push	si
	mov	ax,cs
	mov	es,ax
	mov	di,bx
	lea	si,[si-2]
	xor	cx,cx
	mov	cl,[si+1]
	add	cx,2
	cmp	cx,namelen
	ja	regvilgerr	;//
regvaddlp:
	rep	movsb
	pop	si

	mov	ax,ss
	mov	es,ax
	mov	al,cs:[bx]
	add	bx,namelen
	cmp	al,vcode2
	je	regvlong
	cmp	al,vcode4
	je	regvexlong
regvout:
	pop	bp
	clc
	ret

regvfullerr:
	pop	bp
	stc
	ret

regvilgerr:	;//
	pop	si
	pop	bp
	stc
	ret



register_var:
				;input AX = attr+len
	push	bp		;*
regv10:
	mov	cx,cs:[bx]
	jcxz	regvadd_here
	cmp	cl,0ffh
	je	regvfullerr
	winc	bx
	cmp	ax,cx
	jne	regv55		;not equal

	push	ax		;**

	xor	cx,cx
	mov	cl,ah		;cx=name length
	mov	bp,si
	mov	di,-1
regv30:
	inc	di
	mov	al,[bp+di]
	call	kanji1st?
	jc	regvkanji
	call	chg2cap
	mov	ah,al
	mov	al,cs:[bx+di]
	call	chg2cap
	cmp	al,ah
regv40:
	jne	regv50
	myloop	regv30
	pop	ax		;**
	add	bx,namelen-2
	jmp	regvout

regv50:
	pop	ax		;**
regv55:
	add	bx,namelen
	jmp	regv10



regvkanji:
	cmp	al,cs:[bx+di]
	jne	regv50
	inc	di
	dec	cx
	mov	al,[bp+di]
	cmp	al,cs:[bx+di]	;check 2nd byte
	jmp	regv40


kanji1st?:
	CMP	al,81H
	JB	nokanji
	CMP	al,9FH
	JBE	yeskanji1st	;漢字
	CMP	al,0E0H
	JB	nokanji
	CMP	al,0FCH
	JBE	yeskanji1st
nokanji:
	clc
	RET

yeskanji1st:
	stc
	ret


farKANJI1ST?:
	call	KANJI1ST?
	retf


;☆変数の初期化

farRESVAR:
	call	RESVAR
	retf

RESVAR:
	smov	ds,ss
	MOV	BX,RESADR
	xor	ax,ax
	MOV	[BX],ax
	mov	[blocksw],al
	mov	word ptr [polymodulus],ax
	mov	word ptr [polymodulus+2],ax

	mov	ax,1234h	;any value
	call	randomize_main	;initialize random number

	mov	ax,data
	add	ax,varseg
	mov	[varsegnow],ax
	mov	[arrayseg],ax
	mov	ax,[limitseg]
	mov	[varseglim],ax

;init variable table 

	mov	ax,cs
	mov	es,ax
	mov	di,offset vartbl
	mov	cx,varall*(namelen+2)/2
	xor	ax,ax
	rep	stosw
	dec	ax
	stosw			;end mark

	mov	ax,ss
	mov	es,ax

	mov	[defsegdata],0ff00h

	call	ema_close
	ret


;☆飛び先アドレスを行番号に戻し、

farDiscompilegoto:
	call	discompilegoto
	retf

discompilegoto:			;dis-compile
	CMP	[compilegoto_sw],0
	JE	DISEND2

	MOV	SI,[TXTTOP]
DISLP0:	
	CMP	WORD PTR [SI],0
	JE	DISEND		;if end

	ADD	SI,5		;pass line# & #space
DISLP1:	
	LODSB
	CMP	AL,CR
	JE	DISLP0		;CR が出れば次行へ

DISCPL20:
	CMP	AL,NCODE_ADR
	JE	DISCPL50	;行番号でアドレスに代わっているところ
	CMP	AL,NCODE_ADR2
	JE	DISCPL40	;LABEL でアドレスになっているところ
DISJP2:
	CALL	PASSTOKEN
	JMP	DISLP1

DISCPL40:
	MOV	BYTE PTR [SI-1],NCODE_LABEL
	JMP	DISJP2

DISCPL50:
	CALL	DISADR
	JMP	DISLP1

DISEND:	
	MOV	[compilegoto_sw],0
DISEND2:
	RET	


;☆変数番号を変数名に戻すのみのルーチン

farDiscompilevar:
	call	discompilevar
	retf

discompilevar:
	mov	bx,offset overloadaddadr
	xor	ax,ax
	mov	[bx],ax
	mov	[bx+2],ax
	mov	[bx+4],ax
	mov	[bx+6],ax
	mov	[bx+8],ax
	mov	[bx+10],ax
	mov	[bx+12],ax

	CMP	[compilevar_sw],0
	JE	DISCVAREND

	MOV	SI,[TXTTOP]
DISCVARLP0:	
	cmp	WORD PTR [SI],0
	je	DISCVAREND	;if end

	ADD	SI,5		;pass line# & SPACE#
DISCVARLP1:	
	LODSB
	CMP	AL,CR
	JE	DISCVARLP0	;CR が出れば次行へ

	CMP	AL,NCODE_ADR
	JE	DISCVAR50	;ADDRESS になっている
	CMP	AL,VCODE
	JB	DISCVARJP2
	CMP	AL,VCODE5
	JBE	DISCVAR60	;変数
DISCVARJP2:
	CALL	PASSTOKEN
	JMP	DISCVARLP1

DISCVAR50:
	ADD	SI,2
	JMP	DISCVARLP1
DISCVAR60:
	CALL	DISVAR
	JMP	DISCVARLP1

DISCVAREND:	
	mov	[compilevar_sw],0
	RET	

	;
	;* code -> variables and goto,gosub dest
	;
farDiscompileall:
	call	discompileall
	retf

discompileall:
	cmp	[compilevar_sw],0
	je	discompilegoto
	cmp	[compilegoto_sw],0
	je	discompilevar

	mov	[compilevar_sw],0
	mov	[compilegoto_sw],0
	MOV	SI,[TXTTOP]
discallLP0:	
	cmp	WORD PTR [SI],0
	je	discallEND	;if end

	ADD	SI,5		;pass line# & SPACE#
discallLP1:	
	LODSB
	CMP	AL,CR
	JE	discallLP0	;CR が出れば次行へ

	CMP	AL,VCODE
	JB	discallJP2
	CMP	AL,VCODE5
	JBE	discall60	;variables
	CMP	AL,NCODE_ADR2
	JE	discall40	;coded label
	CMP	AL,NCODE_ADR
	JE	discall50	;coded line number
discallJP2:
	CALL	PASSTOKEN
	JMP	discallLP1

discall40:
	MOV	BYTE PTR [SI-1],NCODE_LABEL
	JMP	discallJP2
discall50:
	CALL	DISADR
	JMP	discallLP1
discall60:
	CALL	DISVAR
	JMP	discallLP1

discallEND:	
	RET	


;☆ IF,ELSE,...の飛び先アドレスを初期化するのみ
;   RUN の前のみ

farDiscompilejp:
	call	discompilejp
	retf

discompilejp:
	CMP	[compilejp_sw],0
	JE	discjpEND2
	MOV	SI,[TXTTOP]

discjpLP0:	
	CMP	WORD PTR [SI],0
	JE	discjpEND	;if end

	ADD	SI,5		;pass line# & #space
discjpLP1:	
	LODSB
	CMP	AL,CR
	JE	discjpLP0	;CR が出れば次行へ

	CMP	AL,98H		;REM
	JE	discjpREM

	cmp	al,80h
	je	discjp_extended
	CMP	AL,8DH		;IF
	JB	discjp20
	CMP	AL,0AFH		;ELSEIF
	JE	discjp29
	CMP	AL,0B6H		;JUMP
	JE	discjp30
	CMP	AL,0B8H		;LOOP
	JE	discjp30
	CMP	AL,0B9H		;ENDLOOP
	JE	discjp30
	CMP	AL,93H		;UNTIL
	JA	discjp20

	CMP	AL,8EH		;THEN
	JNE	discjp30
	
discjp20:
	CALL	PASSTOKEN
discjp25:
	JMP	discjpLP1


discjp29:			;for ELSEIF
	MOV	WORD PTR [SI],0	;後ろの飛び先
	ADD	SI,3
discjp30:
	MOV	WORD PTR [SI],0	;後ろの飛び先
	ADD	SI,2
	JMP	discjpLP1

discjpREM:
	MOV	WORD PTR [SI],0	;後ろの飛び先
	ADD	SI,2
discjpREM10:
	LODSB
	CMP	AL,CR
	JNE	discjpREM10	
	JMP	discjpLP0


discjpEND:	
	MOV	[compilejp_sw],0
discjpEND2:
	RET	


discjp_extended:
	lodsb
	cmp	al,0e7h
	jb	discjp25
	cmp	al,0e8h
	ja	discjp25
	jmp	discjp30


;
; DISCOMPILE の SUBROUTINES
;

DISADR:
	MOV	BYTE PTR [SI-1],NCODE1	;CODE を行番号のものに戻す
	PUSH	SI
	MOV	SI,[SI]
	MOV	AX,[SI-3]
	POP	SI
	MOV	[SI],AX
	ADD	SI,2
	RET

DISVAR:
	xor	cx,cx
	mov	cl,[si]
	inc	si
	mov	di,[si]
	sub	di,namelen-2
	xchg	si,di
	mov	ax,cs
	mov	ds,ax
	rep	movsb
	mov	ax,ss
	mov	ds,ax
	xchg	si,di
	ret

;
;* get label infor.s
;INPUT  BP = address where Ncode_LABEL exists
;OUTPUT	AX : address after label
;	DI : address that AX = CS:[DI]
;	BP : next text pointer

farGETLABELADR:
	call	GETLABELADR
	retf

GETLABELADR:
	MOV	AX,CS
	MOV	ES,AX
	INC	BP
	XOR	CX,CX
	MOV	CL,[BP]
	INC	BP
	MOV	SI,BP
	MOV	DI,OFFSET LABEL_TABLE

	;search until chars coincides
GOLABEL10:
	mov	al,es:[di]
	cmp	al,0ffh		;end mark
	je	labelerr	;undefined label
	CMP	cl,al
;	JB	LABELERR
	JE	CMPLABEL
GOLABEL20:
	ADD	DI,LABELUNIT
	JMP	GOLABEL10

	;compare strings
CMPLABEL:
	PUSH	CX
	PUSH	SI
	PUSH	DI	
	INC	DI
cmplabel10:
	call	rep_cmpsb_label
	je	equlabel
cmplabel20:
	POP	DI
	POP	SI
	POP	CX
	JA	GOLABEL20
LABELERR:
	JMP	NOLERR		;not exists

EQULABEL:
	MOV	AX,SS
	MOV	ES,AX
	MOV	AX,CS:[DI]	;address next to LABEL
	add	sp,6		;DUMMY
	LEA	BP,[SI+2]	;next TEXT pointer
	RET


;
;☆LABEL のある行の番号を得る
;INPUT  BP=Ncode_LABEL のある番地
;OUTPUT	CX=LINE NUMBER
;       BP=LABEL の次の番地

GETLABELLINE:

	INC	BP
	XOR	CX,CX
	MOV	CL,[BP]
	INC	BP
	MOV	SI,TXTHED
GETLL10:
	LODSW
	OR	AX,AX
	JZ	GETLLERR
	MOV	BX,SI		;LINE NUMBER のある番地
	MOV	DX,AX		;TOP OF NEXT LINE
	ADD	SI,3
	lodsb
	cmp	al,0b3h
	jne	getll15
	lodsb
getll15:
	cmp	al,Ncode_LABEL
	JNE	GETLL90
	CMP	CL,[SI]
	JNE	GETLL90
	INC	SI
	MOV	DI,BP
	PUSH	CX
	call	rep_cmpsb_label
	POP	CX
	JE	GETLLEND	;見つかった		
GETLL90:
	MOV	SI,DX
	JMP	GETLL10

GETLLEND:
	MOV	CX,[BX]
	LEA	BP,[DI+2]	;ADR の分	
	RET

GETLLERR:
	JMP	NOLERR



;
;☆LABEL TABLE の作成
;

MAKE_LABEL_TABLE:

	MOV	AX,CS
	MOV	ES,AX
	MOV	DI,OFFSET LABEL_TABLE
cmp	di,[labelend]
jne	labelout	;already compiled
;	MOV	[LABELEND],DI
	MOV	AL,0FFH
	STOSB			;END MARK
	MOV	SI,TXTHED
LABELLP:
	LODSW
	OR	AX,AX
	JZ	LABELOUT	;END OF TEXT
	PUSH	AX
	ADD	SI,3
	LODSB
	cmp	al,0b2h		;ext code
	jne	label40
	lodsb
	cmp	al,96h		;def
	jne	labeljp
	lodsb
label40:
	CMP	AL,0B3H		;fn
	JNE	LABEL50
	LODSB
LABEL50:
	CMP	AL,Ncode_LABEL
	JNE	LABELJP
	CALL	LABELSUB
LABELJP:
	POP	SI
	JMP	LABELLP

LABELOUT:
	MOV	AX,SS
	MOV	ES,AX
	RET



LABELSUB:
	XOR	CX,CX
	MOV	CL,[SI]		;NUMBER OF BYTES
	JCXZ	LABELSUBRET	;文字なしは登録しない
	CALL	SETLTABLE
	mov	al,cl
	stosb			;文字数も登録
	inc	si
	rep	movsb
	MOV	AX,SI		;LABEL の次の番地
	ADD	AX,2		;飛び先の分
	STOSW
LABELSUBRET:
	RET

SETLTABLE:
	;登録場所を空け、先頭番地を DI で返す
	;[LABELEND] を更新

	MOV	DI,OFFSET LABEL_TABLE
SETLTLP:
	MOV	ah,ES:[DI]
	CMP	CL,ah
	JB	SETLINS
	JE	SETLCMP
	ADD	DI,LABELUNIT
	JMP	SETLTLP


SETLINS:
	CMP	ah,0FFH
	JE	SETLOUT		;最後への追加

	PUSH	CX
	PUSH	SI

	MOV	CX,ES
	MOV	DS,CX

	MOV	SI,SS:[LABELEND]
	MOV	CX,SI
	SUB	CX,DI
	SHR	CX,1
	SUB	SI,2
	LEA	DI,[SI+LABELUNIT]
	CMP	DI,OFFSET LABEL_TABLE+LABELALL
	JAE	LABELOVER2
	STD
	REP	MOVSW
	CLD
	LEA	DI,[SI+2]

	MOV	CX,SS
	MOV	DS,CX

	POP	SI
	POP	CX
	MOV	BX,[LABELEND]
	ADD	BX,LABELUNIT
SETLRET:
	MOV	BYTE PTR ES:[BX],0FFH	;END MARK
	MOV	[LABELEND],BX
	RET

SETLOUT:
	MOV	BX,[LABELEND]
	ADD	BX,LABELUNIT
	CMP	BX,OFFSET LABEL_TABLE+LABELALL
	JB	SETLRET
LABELOVER:
	MOV	BP,SI
	JMP	LABELFULL
LABELOVER2:
	POP	BP
	JMP	LABELFULL


SETLCMP:
	PUSH	CX
	PUSH	SI
	PUSH	DI
	INC	SI
	INC	DI
	call	rep_cmpsb_label
	je	labeldup
	POP	DI
	POP	SI
	POP	CX	
	JB	SETLINS
	ADD	DI,LABELUNIT
	MOV	ah,ES:[DI]
	CMP	CL,ah
	JE	SETLCMP
	JMP	SETLINS		;同じ文字数のものがなくなった
		

LABELDUP:
	MOV	BP,SI
	JMP	DOUBLELABEL


farrep_cmpsb_label:
	call	rep_cmpsb_label
	retf

rep_cmpsb_label:
	lodsb
	call	kanji1st?
	jc	cmplabelkanji
	call	chg2cap
	mov	ah,al
	mov	al,es:[di]
	call	chg2cap
	cmp	al,ah
	jne	cmplabelnotequ
cmplabel50:
	inc	di
	myloop	rep_cmpsb_label
cmplabelequ:
	cmp	al,al		;set ZF
	ret


cmplabelkanji:
	cmp	al,es:[di]
	jne	cmplabelnotequ
	inc	di
	dec	cx		;must not be 0
	lodsb
	cmp	al,es:[di]	;check 2nd byte
	je	cmplabel50

cmplabelnotequ:
	or	al,0ffh		;reset ZF
	ret


code	ends
END
