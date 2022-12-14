;UB.H for 日本語DOS
;	ＵBASIC の 定数の定義
;	各ファイルに INCLUDE される


debug	equ	0

IF FLG32
.286c
ENDIF

FLG98		EQU	0
FLG98NOTXL	EQU	0
FLGXL		EQU	0
;FLGSTDGRP	EQU	-1

FLG4075		EQU	1

;
_chars98	equ	80
_lines98	equ	25
_lines2get	equ	18		;used by get_data

; printer type

NECPR		equ	1
NECNM		equ	2
EPSON		equ	4


MAXFILE		EQU	10	;同時にOPEN出来るSEQ.FILEの数

fnamelen	equ	32
fnamewordlen	equ	fnamelen/2
maxfilenamelen  equ	fnamelen-1

white		equ	07h
reversewhite	equ	70h
black		equ	0
blue		equ	1
transparent	equ	255


delaytimer	equ	20h

LLMULswitchlen	equ	12	;long * long を高速ルーチンを用いるかどうかの
						;境目

NAMELEN		EQU	20
VARALL		EQU	180	;number of variables

minlines	equ	5

ankwidthL	equ	8
heightL		equ	16
height2L	equ	20	;25
halfheightL	equ	9	;height*5/8-1
gsizemaxL	equ	8*8

maxreadsize	equ	512		;max read file size at 1 time


    if FLG4075
UNITWORD	EQU	848		;must be a multiple of 8
    else
UNITWORD	EQU	544		;must be a multiple of 8
    endif
unitseg		equ	UNITWORD/8

LIMITWORD	EQU	UNITWORD-4
defaultword	equ	limitword
UNITBYTE	EQU	UNITWORD*2	;計算のSYSYEMワークの長さ

pointmax	equ	limitword/2-2	;see div_float_float
pointmin	equ	2
pointinit	equ	4

floatbiasover	equ	3527h	;<4000h and decimal digit <=32767
floatbiasunder	equ	-floatbiasover
_floatdeciratio	equ	99a0h		;pointdeci=pointword*8*this\0x10000-3

ARRAYHEAD	EQU	32		;配列の ATTRIBUTE AREA の長さ
ARRAYHEADSEG	EQU	2		;ARRAYHEAD/16

helpintvect	equ	0c6h		;interrupt vector for HELP

maxhelpsegsize	equ	140h		;buffersize for help text /16

PI16bit		equ	0c90fh		;3.14159... : 2bit for int, 14 bit frac


;bit masks for attribute word

signmask		equ	1000000000000000b
signmaskhigh		equ	10000000b
signmaskdouble		equ	1000000010000000b
signmaskCPL		equ	0111111111111111b
signmaskhighCPL		equ	01111111b

LENMASK			equ	0000001111111111b
LENMASKHIGH		equ	00000011b
LENMASKHIGHCPL		equ	11111100b

attribmask		equ	0111110000000000b
attribmaskhigh		equ	01111100b
attribmaskdouble	equ	0111110001111100b

POINTMASK		equ	0100000000000000b
POINTMASKHIGH		equ	01000000b
POINTMASKdouble		equ	0100000001000000b

complexmask		equ	0010000000000000b
complexmaskhigh		equ	00100000b
complexmaskdouble	equ	0010000000100000b

pointcomp		equ	0110000000000000b
pointcomphigh		equ	01100000b

ratmask			equ	0001000000000000b
ratmaskhigh		equ	00010000b
ratmaskdouble		equ	0001000000010000b

nonnumericmask		equ	0000110000000000b
nonnumericmaskhigh	equ	00001100b
nonnumericmaskdouble	equ	0000110000001100b

nonrealmask		equ	0010110000000000b
nonrealmaskhigh		equ	00101100b
nonrealmaskdouble	equ	0010110000101100b

nonposrealmask		equ	1010110000000000b
nonposrealmaskhigh	equ	10101100b
nonposrealmaskdouble	equ	1010110010101100b

compratmaskhigh		equ	00110000b
ratstrmaskhigh		equ	00011000b

compratstrmaskhigh	equ	00111000b
compratstrdouble	equ	0011100000111000b

pointcompstr		equ	0110100000000000b
pointcompstrdouble	equ	0110100001101000b
pointcompstrhigh	equ	01101000b

pointcomprathigh	equ	01110000b
pointcompratstrhigh	equ	01111000b

stringmask		equ	0000100000000000b
stringmask1char		equ	1000100000000001b	;1 character
stringmaskhigh		equ	00001000b
stringmaskdouble	equ	0000100000001000b

compratstrmaskhigh	equ	00111000b
compstrmaskhigh		equ	00101000b	

packmask		equ	0000010000000000b
packmaskhigh		equ	00000100b
packmaskdouble		equ	0000010000000100b

comppackmaskhigh	equ	00100100b
compstrpackmaskhigh	equ	00101100b
compratstrpackmaskhigh	equ	00111100b
compratstrpackdouble	equ	0011110000111100b

polymask		equ	0000110000000000b
polymaskhigh		equ	00001100b
polymaskdouble		equ	0000110000001100b

modpolymask		equ	0001100000000000b
modpolymaskhigh		equ	00011000b
modpolymaskdouble	equ	0001100000011000b

ratpolymask		equ	0001110000000000b
ratpolymaskhigh		equ	00011100b
ratpolymaskdouble	equ	0001110000011100b


;internal code of arithmetic

codeofequal	equ	0d1h
codeofadd	equ	0ddh
codeofsub	equ	0deh
codeofmul	equ	0e5h
codeofdiv	equ	0e6h
codeofmod	equ	0e7h
codeofidiv	equ	0e8h
codeofratdiv	equ	0e9h
codeofpower	equ	0efh


   if FLG4075
maxfactorial	equ	1487
   else
maxfactorial	equ	1014
   endif

systemstacktop	equ	0fe00h
systemstackbtm	equ	0fffeH	;スタックは FE00~FFFE


;	assignment of work area starts here
;	DIRECTBUF>=INITDATA (check by .map file)

;DIRECT MODE 用バッファ

DIRECTBUF	EQU	0d60H	;>initdata
directbufsize	equ	400
;inpcalcbuf	equ	DIRECTBUF+directbufsize
;inpcalcbufsize	equ	400

;TXTHED	EQU	inpcalcbuf+inpcalcbufsize
TXTHED	EQU	directbuf+directbufsize

    if FLG4075
stackin	equ	systemstacktop-17*unitbyte-16
TXTLIM	EQU	systemstacktop-14*UNITBYTE-16
    else
stackin	equ	systemstacktop-25*unitbyte-16
TXTLIM	EQU	systemstacktop-20*UNITBYTE-16
    endif

;
;	CALCULATION STACK AREA
;	12/20 LEVELS
;
    if FLG32
STACKTOP	EQU	stackin+2
    else
STACKTOP	EQU	stackin+4
    endif

    if FLG4075
LIMIT	EQU	STACKTOP+12*UNITBYTE
    else
LIMIT	EQU	STACKTOP+20*UNITBYTE
    endif

RESADR	EQU	LIMIT

LNUMBS	EQU	RESADR+UNITBYTE+8	;RESADR は 4 WORD 余裕を置く


;
;note mulwork is used as 2 units wide
; by store_float
; take care of destroying work2

mulwork	EQU	LNUMBS
INPBUF	EQU	LNUMBS+2
WORK2	EQU	mulwork+UNITBYTE
CODBUF	EQU	WORK2
WORK3	EQU	WORK2+UNITBYTE
;GCDADR	EQU	WORK3			;GETGCD で GCD を返す
WORK4	EQU	WORK3+UNITBYTE

GOSUBMAXLEVEL	EQU	38		;GOSUB の深さの MAX
GOSUBUNITBYTE	EQU	18
GOSUBUNITWORD	EQU	GOSUBUNITBYTE/2

;
; * for-next stack structure
;
FORMAXLEVEL	EQU	28		;FOR-NEXT の深さの MAX
FORUNITBYTE	EQU	12
FORUNITWORD	EQU	FORUNITBYTE/2

;構造
;    0000H word 変数型
;    0002H word 変数の番地
;    0004H word STEP
;    0006H word NEXT からの戻り番地
;    0008H dword 回数

FORVARTYPE	EQU	0000H
FORVARADR	EQU	0002H
FORSTEP		EQU	0004H
FORRETURN	EQU	0006H
FORCOUNT	EQU	0008H


;common value area

COMMONSEG		equ	1000h	;data + this
			;1000H FOR DATA SEGMENT
COMMONDATANUMBER	equ	 8
COMMONSEGSIZE	equ	UNITSEG*COMMONDATANUMBER

;graphic window data

GRAPHWORKSEG	equ	(COMMONSEG+COMMONSEGSIZE)
GRAPHSEGSIZE	equ	450	;_gymax600*12/16	;12bytes/line


WINDOWSEG	EQU	(GRAPHWORKSEG+GRAPHSEGSIZE)
WINDOWSEGSIZE	EQU	3	;8bytes*6

worldx1		equ	0
worldy1		equ	8
worldx2		equ	16
worldy2		equ	24
worldxpro	equ	32
worldypro	equ	40

;USER STACK の SEGMENT

USERSTACKSEG	EQU	WINDOWSEG+WINDOWSEGSIZE
   if FLG4075
USTKSIZE	EQU	6000H
   else
USTKSIZE	EQU	4000H
   endif
USTKSEGSIZE	EQU	USTKSIZE/16

;ASCII<->BINARY CONVERSION BUFFER
;also LLMULfast work area

ASCBINSEG	EQU	USERSTACKSEG+USTKSEGSIZE
ASCBUFTOP	EQU	0010H
   if FLG4075
ASCBUFEND	EQU	17FEH	;for 6000 digits
   else
ASCBUFEND	EQU	0FFEH	;for 4000 digits
   endif

LLMULworkseg		equ	ASCBINSEG
LLMULworksegsize	equ	8*UNITSEG		;must > ASCBUFEND/16

;定数の SEGMENT & OFFSET

UBCONSTSEG	EQU	ASCBINSEG+LLMULworksegsize

SYSPI		EQU	0
SYSEXP		EQU	1102
SYSEXP12	EQU	1102*2
SYSLOG2		EQU	1102*3
SYSATAN12	EQU	1102*4
SYSATAN14	EQU	1102*5
SYSEULER	EQU	1102*6
SYSPRM		EQU	1102*7
			;6543個
			;SEPARATOR1(2BYTE)
SYSPRM2W	EQU	1102*7+2*6544
			;5709個
SYSCONSP2	EQU	1102*7+2*12253
			;SEPARATOR2(2BYTE)
			;total =07DDEH

;ema attribute area

EMAATTRIBUTESEG	EQU	UBCONSTSEG+07E0H	;DATA+THIS
			;use 16*16 bytes

;長変数の SEGMENT

VARSEG		EQU	EMAATTRIBUTESEG+10H	;10H=16*16/16

;テキスト変換用バッファの SEGMENT

TEXTCONVSEG	EQU	VARSEG

;変数のコード

VCODE	EQU	81H		;短、普通
VCODE1	EQU	VCODE+1		;短、配列
VCODE2	EQU	VCODE+2		;長、普通
VCODE3	EQU	VCODE+3		;長、配列
VCODE4	EQU	VCODE+4		;特別、普通
VCODE5	EQU	VCODE+5		;特別、配列

;数値のコード

NCODE		EQU	0F0H		;0
NCODE1		EQU	NCODE+1		;0でない 1WORD の数
					;次の 1WORD が値
NCODE2		EQU	NCODE+2		;2WORDS 以上の数
					;次の 1WORD は ATTRIBUTE
NCODE3		EQU	NCODE+3		;未使用

NCODE_ADR	EQU	NCODE+4		;GOTO の行き先行番号が実行時に
					;番地に変換された場合のコード
NCODE_LABEL	EQU	NCODE+5		;LABEL のコード
					;次の 1 BYTE が文字数
NCODE_ADR2	EQU	NCODE+6		;GOTO の行き先LABELが実行時に
					;番地に変換された場合のコード

;
; prefix byte of extended commands and functions 
;
codemark2       equ     80h
codemark3       equ     0b2h

;LABEL 関係の量

LABELLEN	EQU	23
LABELUNIT	EQU	LABELLEN+3	;MUST EVEN>=labellen+3
LABELALL	EQU	LABELUNIT*100


dummychar	equ	0ffh

CTRL_A	EQU	1
CTRL_B	EQU	2
CTRL_C	EQU	3
CTRL_D	EQU	4
CTRL_E	EQU	5
CTRL_F	EQU	6
CTRL_G	EQU	7
CTRL_H	EQU	8
TAB	EQU	9
LF	EQU	0AH
CTRL_K	EQU	0BH
CTRL_L	EQU	0CH
FF	EQU	0CH
CR	EQU	0DH
CTRL_P	EQU	10H
CTRL_Q	EQU	11H
CTRL_R	EQU	12H
CTRL_S	EQU	13H
CTRL_T	EQU	14H
CTRL_V	EQU	16H
CTRL_W	EQU	17H
CTRL_X	EQU	18H
CTRL_Y	EQU	19H
CTRL_Z	EQU	1AH
ESC	EQU	1BH
CLEARRIGHT	EQU	CTRL_Y


BIT0	EQU	1
BIT1	EQU	2
BIT2	EQU	4
BIT3	EQU	8
BIT4	EQU	16
BIT5	EQU	32

NOTBIT1	EQU	11111101B



IF FLG32

;note 1
;	myloop	$
;		will make an infinite loop
;note 2
;	set32   myloop dst   uses ECX but
;       set32   loop dst     uses CX not ECX!!

myloop	macro	dst
	dec	cx
	jnz	dst
	endm


WINC	MACRO	PARAM
	LEA	PARAM,[PARAM+2]
	ENDM


WDEC	MACRO	PARAM
	LEA	PARAM,[PARAM-2]
	ENDM


QINC	MACRO	PARAM
	LEA	PARAM,[PARAM+4]
	ENDM


QDEC	MACRO	PARAM
	LEA	PARAM,[PARAM-4]
	ENDM


SET32	MACRO
	DB	66H
	ENDM

ELSE

myloop	macro	dst
	loop	dst
	endm


WINC	MACRO	PARAM
	INC	PARAM
	INC	PARAM
	ENDM


WDEC	MACRO	PARAM
	DEC	PARAM
	DEC	PARAM
	ENDM
ENDIF

AHEDSP_MAC	MACRO
	MOV	SI,[CALCSP]
	SUB	SI,UNITBYTE
	MOV	[CALCSP],SI
	ENDM

BACKSP_MAC	MACRO
	MOV	SI,[CALCSP]
	MOV	DI,SI
	ADD	DI,UNITBYTE
	MOV	[CALCSP],DI
	ENDM

SYSINKEY	MACRO
	MOV	AH,6
	MOV	DL,0FFH
	INT	21H
	ENDM

SYSKEYCLEAR	MACRO
	MOV	AH,0CH
	MOV	AL,6
	MOV	DL,0FFH
	INT	21H
	ENDM

SYSGETCHAR	MACRO
	MOV	AH,7
	INT	21H
	ENDM
	
PUSHALL	MACRO
  if FLG32
	pusha
  else
	push	ax
	push	bx
	push	cx
	push	dx
	push	si
	push	di
  endif
	ENDM

POPALL	MACRO
  if FLG32
	popa
  else
	pop	di
	pop	si
	pop	dx
	pop	cx
	pop	bx
	pop	ax
  endif
	ENDM


JMPS	MACRO	DEST
	JMP	SHORT DEST
	ENDM


JMPZ	MACRO	DEST
	LOCAL	LAB
	JNZ	LAB
	JMP	DEST
LAB:	
	ENDM

JMPNZ	MACRO	DEST
	LOCAL	LAB
	JZ	LAB
	JMP	DEST
LAB:	
	ENDM

JMPC	MACRO	DEST
	LOCAL	LAB
	JNC	LAB
	JMP	DEST
LAB:	
	ENDM

JMPNC	MACRO	DEST
	LOCAL	LAB
	JC	LAB
	JMP	DEST
LAB:	
	ENDM

JMPA	MACRO	DEST
	LOCAL	LAB
	JBE	LAB
	JMP	DEST
LAB:	
	ENDM

CALLZ	MACRO	DEST
	LOCAL	LAB
	JNZ	LAB
	CALL	DEST
LAB:	
	ENDM

CALLNZ	MACRO	DEST
	LOCAL	LAB
	JZ	LAB
	CALL	DEST
LAB:	
	ENDM

CALLC	MACRO	DEST
	LOCAL	LAB
	JNC	LAB
	CALL	DEST
LAB:	
	ENDM


CALLNC	MACRO	DEST
	LOCAL	LAB
	JC	LAB
	CALL	DEST
LAB:	
	ENDM

RETZ	MACRO
	LOCAL	LAB
	JNZ	LAB
	RET
LAB:	
	ENDM

RETNZ	MACRO
	LOCAL	LAB
	JZ	LAB
	RET
LAB:	
	ENDM

RETC	MACRO
	LOCAL	LAB
	JNC	LAB
	RET
LAB:	
	ENDM

RETNC	MACRO
	LOCAL	LAB
	JC	LAB
	RET
LAB:	
	ENDM


if FLG32
MY_SHL	MACRO	REG,COUNT
	SHL	REG,COUNT
ENDM

MY_SHR	MACRO	REG,COUNT
	SHR	REG,COUNT
ENDM

MY_ROL	MACRO	REG,COUNT
	ROL	REG,COUNT
ENDM

MY_ROR	MACRO	REG,COUNT
	ROR	REG,COUNT
ENDM

else

MY_SHL	MACRO	REG,COUNT
	REPT	COUNT
	SHL	REG,1
	ENDM
ENDM

MY_SHR	MACRO	REG,COUNT
	REPT	COUNT
	SHR	REG,1
	ENDM
ENDM

MY_ROR	MACRO	REG,COUNT
	REPT	COUNT
	ROR	REG,1
	ENDM
ENDM

MY_ROL	MACRO	REG,COUNT
	REPT	COUNT
	ROL	REG,1
	ENDM
ENDM

endif

LIN2SEG	MACRO	SEGREG,OFFREG
	MOV	DH,DL
	MOV	DL,AH
	XOR	AH,AH
	MOV	OFFREG,AX
	MY_SHL	DX,4
	MOV	SEGREG,DX	
ENDM


GETSYSVARADR	MACRO
	XOR	AH,AH
	AND	AL,0FEH
	MOV	BX,AX
	MY_SHL	AX,2
	ADD	BX,AX
	ADD	BX,OFFSET VARDATA
	MOV	AX,CS:[BX+6]
	MOV	DX,CS:[BX+8]
ENDM

smov	macro	sreg1,sreg2
	push	sreg2
	pop	sreg1
endm

;

myalign	macro
  if FLG32
	align	4
  else
	even
  endif
endm

;
copy_si2di	macro
	mov	cx,[si]
	and	cx,lenmask
	inc	cx
	rep	movsw
endm

copy_si2di_ax	macro
	lodsw
	stosw
	and	ax,lenmask
	mov	cx,ax
	rep	movsw
endm

copyF	macro	src,dst
	mov	si,src
	mov	di,dst
	mov	cx,[si]
	add	si,2
	mov	[di],cx
	add	di,2
	and	cx,lenmask
	rep	movsw
endm

mylodsd	macro
	set32
	mov	ax,[si]
	qinc	si
endm

mystosd	macro
	set32
	mov	[di],ax
	qinc	di
endm


_paintbuffersize	equ	1000h	;must >= 1000h

_gramseg	equ	0a000h


;gxmaxL	equ	639
;gymaxL	equ	479

_gxsize98	equ	640
_gysize98	equ	400
_gxmax98	equ	639
_gymax98	equ	399
_gxbytes98	equ	80

_gxmax800	equ	800
_gymax600	equ	600

_vmode13	equ	13h			;set VGA 320*200*256colors
_gxsize13	equ	320
_gysize13	equ	200

_vmode12	equ	12h			;set VGA 640*480*16colors
_gxsize12	equ	640
_gysize12	equ	480

_vmode6a	equ	6ah			;set VGA 800*600*16colors
_gxsize6a	equ	800
_gysize6a	equ	600

_vmode70	equ	70h			;set VGA 800*600*16colors
_gxsize70	equ	800
_gysize70	equ	600

_vmode72	equ	72h			;set VGA 800*600*16colors
_gxsize70	equ	800
_gysize70	equ	600

_vmode101	equ	101h		;set SVGA 640*480*256colors
_gxsize101	equ	640
_gysize101	equ	480

_vmode103	equ	103h		;set SVGA 800*600*256colors
_gxsize103	equ	800
_gysize103	equ	600

_vmode105	equ	105h		;set VGA 1024*768*256colors
_gxsize105	equ	1024
_gysize105	equ	768

_vmode111	equ	111h		;set VGA 1024*768*256colors
_gxsize111	equ	640
_gysize111	equ	480

_viewXsizemin	equ	16
_viewYsizemin	equ	16

_greplace	equ	00000b
_gand		equ	01000b
_gor		equ	10000b
_gxor		equ	11000b


;version message

  if JAPANESE
    IF FLG32
versionmessage	equ	'UBASIC86(32)v9.0zl DOS/V用'
    ELSE
versionmessage	equ	'UBASIC86v9.0zl DOS/V用'
    ENDIF
  else
    if FLG32
versionmessage	equ	'UBASIC86(32) for IBM-PC version 9.0zl'
    else
versionmessage	equ	'UBASIC86 for IBM-PC version 9.0zl'
    endif
  endif
