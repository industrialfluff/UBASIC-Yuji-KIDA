;ubconst7.asm
;load ubconst7.dat
;use by including in ubini.asm



UBCONST2	DB	'A:\'
ubconst1	db	'UBCONST7.DAT',0
ubconst_end	label	byte


  if JAPANESE
NOCONSTMSG	DB	'UBCONST7.DAT Ç™Ç†ÇËÇ‹ÇπÇÒÅB',CR,LF,0
NOMEMORYMSG	DB	'ÉÅÉÇÉäÇ™ë´ÇËÇ‹ÇπÇÒÅB',CR,LF,0
 else
NOCONSTMSG	DB	'UBCONST7.DAT is needed.',CR,LF,0
NOMEMORYMSG	DB	'Give me enough memory.',CR,LF,0
 endif

LFSP		db	LF,LF,20 dup(' '),0


load_ubconst:
	call	set_dat_path
	jc	other_path

	MOV	AH,3DH		;OPEN HANDLE
	MOV	DX,CODBUF
	MOV	AL,0		;OPEN FOR READ
	INT	21H
	JNC	ub7here
	
other_path:
	smov	ds,cs

	MOV	AH,3DH		;OPEN HANDLE
	MOV	DX,OFFSET UBCONST1
	MOV	AL,0		;OPEN FOR READ
	INT	21H
	JNC	ub7here

	MOV	AH,3DH		;OPEN HANDLE
	MOV	DX,OFFSET UBCONST2
	MOV	AL,0		;OPEN FOR READ
	INT	21H
	JC	NOCONST
ub7here:
	MOV	BX,AX		;HANDLE
  if FLG98
	MOV	AX,UBCONSTSEG
  else
	mov	ax,ss
	add	ax,ubconstseg
  endif
	MOV	DS,AX
	XOR	DX,DX
	MOV	AH,3FH		;READ HANDLE
	MOV	CX,8000H
	INT	21H
	jc	NOCONST

	mov	word ptr ds:[SYSCONSP2],0	;set 2nd separator
	smov	ds,ss

	MOV	AH,3EH		;close handle
	INT	21H

	smov	es,ss
	ret

NOCONST:
	MOV	DX,OFFSET NOCONSTMSG

initerror:
	smov	ds,cs
;	MOV	AH,9
;	INT	21H		
	call	msgLF
	smov	ds,ss

	JMP	SYSTEM

nomemoryerr:
	MOV	DX,OFFSET NOMEMORYMSG
	JMP	INITERROR

msgLF:
	push	dx
	mov	dx,offset LFSP
	call	msg
	pop	dx
	jmp	msg


set_dat_path:

	;* get path where this loaded from

	mov	ah,30h
	int	21h		;get DOS version
	cmp	al,3
	jb	version2	;cannot get path from kankyou

	mov	ax,cs
	sub	ax,0010h
	mov	ds,ax

	mov	bx,002ch
	mov	ax,[bx]
	mov	ds,ax
	mov	es,ax
	mov	cx,cs
	sub	cx,ax
	my_shl	cx,4		;cx=size of kankyou
	xor	di,di		;es:di = top of kankyou
	xor	al,al	
set_dat_lp:
	repne	scasb		;search 0
	cmp	[di],al		;next 0 too?
	jne	set_dat_lp
	inc	di
	cmp	word ptr [di],0001
	jne	version2	;error(never happen)
	add	di,2
set_path:
	smov	es,ss
	mov	si,di		;now si=top of path	
	mov	di,CODBUF
	mov	bx,di		;init top of path
set_pathlp:
	lodsb
	stosb
	cmp	al,':'
	jne	set_path10
	mov	bx,di
set_path10:
	cmp	al,'\'
	jne	set_path20
	mov	bx,di		;next of \
set_path20:
	or	al,al
	jnz	set_pathlp
	mov	di,bx		;next of last \

	smov	ds,cs
	mov	si,offset ubconst1
	mov	cx,offset ubconst_end-offset ubconst1
	rep	movsb
	smov	ds,ss
	clc
	ret

version2:
	smov	ds,ss
	smov	es,ss
	stc
	ret

  if FLG32
    if JAPANESE
non386msg	db	'CPU Ç™ 80386 Ç≈ÇÕÇ†ÇËÇ‹ÇπÇÒÅB',cr,lf,0
    else
non386msg	db	'CPU is not 80386.',cr,lf,0
    endif
non386error:
	mov	dx,offset non386msg
	smov	ds,cs
;	MOV	AH,9
;	INT	21H		
	call	msgLF
	mov	ah,4ch
	int	21h
  endif


if flg98
;
;get printer type from kankyou
;and set in PRINTERTYPE
;
set_printer:
	mov	ax,cs
	sub	ax,0010h
	mov	ds,ax

	mov	bx,002ch
	mov	ax,[bx]
	mov	ds,ax
	mov	dx,cs
	sub	dx,ax
	my_shl	dx,4		;dx=size of kankyou
	xor	si,si		;ds:si = top of kankyou
setlpr10:
	lodsb
	or	al,al
	jnz	setlpr10
setlpr20:
	cmp	si,dx
	jae	setlpr50	;not set
	lodsb
	or	al,al
	jz	setlpr50	;not set
	or	al,20h
	cmp	al,'p'
	jne	setlpr10

	mov	di,offset printermsg+1
	mov	cx,6
setlpr30:
	lodsb
	or	al,al
	jz	setlpr20
	or	al,20h
	cmp	al,cs:[di]
	jne	setlpr10
	inc	di
	myloop	setlpr30

setlpr40:
	lodsb
	cmp	al,' '
	je	setlpr40
	cmp	al,'='
	jne	setlpr10
setlpr50:
	lodsb
	cmp	al,' '
	je	setlpr50
	or	al,20h
	mov	ah,EPSON
	cmp	al,'e'
	je	setlpr60
	mov	ah,NECPR
setlpr60:
	smov	ds,ss
	mov	[printertype],ah
	ret	
endif

printermsg	db	'printer'
