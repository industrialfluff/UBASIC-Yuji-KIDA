;CODE.ASM

	INCLUDE	UBDEF.H
	INCLUDE	UB.H

;
;	ＵBASIC の アスキーコード<=>中間コード 変換
;


DATA	SEGMENT	WORD PUBLIC

	EXTRN	directFLG:BYTE,ASCTOP:WORD,ASCEND:WORD
	extrn	compilevar_sw:byte,inputlen:word
	extrn	schoolflg:byte


;*******************
;*                 *
;*  COMMAND TABLE  *
;*                 *
;*******************

CMDTBL	LABEL BYTE
	DB	0FFH			;top mark

	DB	'goto'
	DB	87H			;code
	DB	'go to'
	DB	87H

	DB	'gosub'
	DB	88H
	DB	'go sub'
	DB	88H

	DB	'for'
	DB	89H

	DB	'to'
	DB	8AH

	DB	'step'
	DB	8BH

	DB	'next'
	DB	8CH

	DB	'if'
	DB	8DH

	DB	'then'
	DB	8EH

	DB	'else'
	DB	8FH

	DB	'while'
	DB	90H

	DB	'wend'
	DB	91H

	DB	'repeat'
	DB	92H

	DB	'until'
	DB	93H

	DB	'cancel'
	DB	94H

	DB	'return'
	DB	95H

	DB	'stop'
	DB	96H

	DB	'endif'
	DB	97H
	DB	'end if'
	DB	97H

	DB	'rem'
	DB	98H
	DB	27H			;code of '
	DB	98H

	DB	'print'
	DB	99H
	DB	'?'
	DB	99H

	DB	'lprint'
	DB	9AH
	DB	'l?'
	DB	9AH

	DB	'read'
	DB	9BH

	DB	'data'
	DB	9CH

	DB	'restore'
	DB	9DH

	DB	'#i'
	DB	9EH

	DB	'word'
	DB	9FH

	DB	'inc'
	DB	0A0H

	DB	'dec'
	DB	0A1H

	DB	'block'
	DB	0A2H

	DB	'res'
	DB	0A3H

	DB	'dim'
	DB	0A4H

	DB	'swap'
	DB	0A5H

	DB	'reduce'
	DB	0A6H

	DB	'input'
	DB	0A7H

	DB	'clr'
	DB	0A8H

	DB	'point'
	DB	0A9H

	DB	'erase'
	DB	0AAH

	DB	'nop'
	DB	0ABH

	DB	'locate'
	DB	0ACH

	DB	'llocate'
	DB	0ADH

	DB	'call'
	DB	0AEH

	DB	'elseif'
	DB	0AFH
	DB	'elsif'
	DB	0AFH
				;0b0h is used for secret IF
				;associated with ELSEIF

	DB	'strinput'
	DB	0B1H

				;0b2h is used for extended cmd & func

	DB	'fn'
	DB	0B3H

	DB	'neg'
	DB	0B4H

	DB	'not'
	DB	0B5H

	DB	'jump'
	DB	0B6H

	DB	'**'
	DB	0B7H

	DB	'loop'
	DB	0B8H

	DB	'endloop'
	DB	0B9H
	DB	'end loop'
	DB	0B9H

	DB	'local'
	DB	0BAH

	db	'0x'
	db	0bbh

	db	'eval('
	db	0bch
				;0bdh is used for end mark of eval

				;0beh is used for 'or'
	
	DB	'end'
	DB	0BFH

	db	'or'
	db	0beh

				;0c0h-0c4h are used for separator

	db	'and'
	db	0c5h

	;graphic commands

				;	DB	'graph'
				;	DB	0C6H deleted

	DB	'view'
	DB	0C7H

	DB	'color'
	DB	0C8H

	DB	'window'
	DB	0C9H

	DB	'screen'
	DB	0CAH

	DB	'line'
	DB	0CBH

	DB	'pset'
	DB	0CCH

	DB	'circle'
	DB	0CDH

	DB	'paint'
	DB	0CEH



	DB	'mod'
	DB	codeofmod

	DW	0FFH		;END MARK

;  separators

SEPTBL	LABEL BYTE
	DB	0FFH

	DB	3AH		;':'
	DB	0C0H
	DB	3BH		;';'
	DB	0C1H

	DB	','
	DB	0C2H

	DB	'..'
	DB	0C3H

	;0c5h is used for 'and'

	;0c6h-0cfh are used already

;  operators

comment %
	;LEVEL -1

	db	'or'
	db	0beh

	;LEVEL 0

	db	'and'
	db	0c5h
%

	;LEVEL 1

	DB	'>='
	DB	0D3H

	DB	'=>'
	DB	0D3H

	DB	'<='
	DB	0D5H

	DB	'=<'
	DB	0D5H

	DB	'<>'
	DB	0D6H

	DB	'><'
	DB	0D6H

	DB	'='
	DB	codeofequal

	DB	'>'
	DB	0D2H

	DB	'<'
	DB	0D4H

	;LEVEL 2

	DB	'+'
	DB	codeofadd	;0DDH

	DB	'-'
	DB	codeofsub	;0DEH

	;LEVEL 3

	db	'//'
	db	0e9h

	DB	'*'
	DB	codeofmul	;0E5H

	DB	'/'
	DB	codeofdiv	;0E6H

	DB	'@'
	DB	codeofmod	;0E7H

	DB	'\'
	DB	codeofidiv	;0E8H

	;LEVEL 4

	DB	'^'
	DB	codeofpower	;0EFH


	DW	0FFH		;end mark


;拡張コマンド codemark2(=80H)+80H~0AFH

CMDTBL2	LABEL BYTE
	DB	0FFH

	DB	'list'
	DB	80H

	DB	'llist'
	DB	81H

	DB	'run'
	DB	82H

	DB	'delete'
	DB	83H

	DB	'renum'
	DB	84H

	DB	'save'
	DB	85H

	DB	'load'
	DB	86H

	DB	'asave'
	DB	87H

	DB	'dir'
	DB	88H
	DB	'files'
	DB	88H

	DB	'vxref'
	DB	89H

	DB	'lvxref'
	DB	8AH

	DB	'vlist'
	DB	8BH

	DB	'lvlist'
	DB	8CH

	DB	'system'
	DB	8DH

	DB	'new'
	DB	8EH

	DB	'vchg'
	DB	8FH

	DB	'revive'
	DB	90H

	DB	'append'
	DB	91H

	DB	'open'
	DB	92H

	DB	'output'	;for write open file
	DB	93H

	DB	'as'		;for open file
	DB	94H

	DB	'close'
	DB	95H

	DB	'set'
	DB	96H

	DB	'edit'
	DB	97H

	DB	'kill'
	DB	98H

	DB	'date'
	DB	99H
	DB	'date$'
	DB	99H

	DB	'time'
	DB	9AH
	DB	'time$'
	DB	9AH

	DB	'width'
	DB	9BH

	DB	'bload'
	DB	9CH

	DB	'tron'
	DB	9DH

	DB	'troff'
	DB	9EH

	DB	'cont'
	DB	9FH

	DB	'copy'
	DB	0A0H

	DB	'freeze'
	DB	0A1H

	DB	'xref'
	DB	0A2H

	DB	'lxref'
	DB	0A3H

	DB	'beep'
	DB	0A4H

	DB	'ldir'
	DB	0A5H
	DB	'lfiles'
	DB	0A5H

	DB	'melt'
	DB	0A6H

	DB	'free'
	DB	0A7H

	DB	'randomize'
	DB	0A8H

	DB	'auto'
	DB	0A9H

	DB	'useema'
	DB	0AAH

	DB	'emaword'
	DB	0ABH

	DB	'skip'
	DB	0ACH

	DB	'cls'
	DB	0ADH

	DB	'console'
	DB	0AEH

	db	'put'
	db	0afh


;関数 codemark2(=80H)+0B0H~0FFH

	DB	'round('
	DB	0B0H

	DB	'arg('
	DB	0B1H

	DB	'irnd'
	DB	0B2H

	DB	'conj('
	DB	0B3H

	DB	're('
	DB	0B4H

	DB	'im('
	DB	0B5H

	DB	'sinh('
	DB	0B6H

	DB	'cosh('
	DB	0B7H

	DB	'combi('
	DB	0B8H
	DB	'comb('
	DB	0B8H

	DB	'asc('
	DB	0B9H

	DB	'right('
	DB	0BAH
	DB	'right$('
	DB	0BAH

	DB	'mid('
	DB	0BBH
	DB	'mid$('
	DB	0BBH

	DB	'left('
	DB	0BCH
	DB	'left$('
	DB	0BCH

	db	'pack('
	db	0bdh

	DB	'absmax('
	DB	0BEH

	DB	'absadd('
	DB	0BFH

	DB	'abs('
	DB	0C0H

	DB	'sgn('
	DB	0C1H

	DB	'len('
	DB	0C2H

	DB	'bit('
	DB	0C3H

	DB	'gcd('
	DB	0C4H

	DB	'sqrt('
	DB	0C5H
	DB	'sqr('
	DB	0C5H

	DB	'isqrt('
	DB	0C6H
	DB	'isqr('
	DB	0C6H

	DB	'fix('
	DB	0C7H

	DB	'kro('
	DB	0C8H

	DB	'sin('
	DB	0C9H

	DB	'cos('
	DB	0CAH

	DB	'exp('
	DB	0CBH

	DB	'log('
	DB	0CCH

	DB	'#pi'		;( なし
	DB	0CDH
	DB	'pai'		;( なし
	DB	0CDH

	DB	'prm('
	DB	0CEH

	DB	'moeb('
	DB	0CFH
	DB	'mob('
	DB	0CFH

	DB	'eul('
	DB	0D0H

	DB	'prmdiv('
	DB	0D1H

	DB	'eof('
	DB	0D2H

	DB	'chr('
	DB	0D3H
	DB	'chr$('
	DB	0D3H

	DB	'file1('
	DB	0D4H

	DB	'file1'
	DB	0D5H

	DB	'file2('
	DB	0D6H

	DB	'file2'
	DB	0D7H

	DB	'file3('
	DB	0D8H

	DB	'file3'
	DB	0D9H

	DB	'modpow('
	DB	0DAH

	DB	'modinv('
	DB	0DBH

	DB	'int('
	DB	0DCH

	DB	'alen('
	DB	0DDH

	DB	'nxtprm('
	DB	0DEH

	DB	'max('
	DB	0DFH

	DB	'min('
	DB	0E0H

	DB	'sft('
	DB	0E1H

	DB	'tab('
	DB	0E2H

	DB	'spc('
	DB	0E3H
	DB	'spc$('
	DB	0E3H

	DB	'find('
	DB	0E4H

	DB	'odd('
	DB	0E5H

	DB	'even('
	DB	0E6H

	DB	'and{'
	DB	0E7H
	DB	'and {'
	DB	0E7H

	DB	'or{'
	DB	0E8H
	DB	'or {'
	DB	0E8H

	db	'!('
	db	0e9h
	DB	'factorial('
	DB	0E9H

	DB	'rnd'
	DB	0EAH

	DB	'atan('
	DB	0EBH
	DB	'atn('
	DB	0EBH

	DB	'using('
	DB	0ECH

	DB	'tan('
	DB	0EDH

	DB	'#e'
	DB	0EEH

	DB	'#eps'
	DB	0EFH

	DB	'#euler'
	DB	0F0H

	DB	'input$('
	DB	0F1H

	DB	'besselj('
	DB	0F2H

	DB	'besseli('
	DB	0F3H

	DB	'pi('
	DB	0F4H

	DB	'ema('
	DB	0F5H

	DB	'inkey'
	DB	0F6H
	DB	'inkey$'
	DB	0F6H

	db	'cvr('
	db	0f7h

	DB	'encode('
	DB	0F8H

	DB	'decode('
	DB	0F9H

	db	'get'
	db	0fah

	db	'poly('
	db	0fbh

	DB	'str('
	DB	0fcH
	DB	'str$('
	DB	0fcH

	DB	'val('
	DB	0FDH

	db	'member('
	db	0feh

	db	'coeff('
	DW	0FFH		;end mark


;extended command codemark3(=0b2H)+80H~0AFH

cmdtbl3	label byte
	db	0ffh

	db	'key'
	db	80h

	db	'out'
	db	81h

	db	'defseg'
	db	82h

	db	'poke'
	db	83h

	db	'pokew'
	db	84h

	db	'gsave'
	db	85h

	db	'gload'
	db	86h

	db	'gprint'
	db	87h
	db	'g?'
	db	87h

	db	'glocate'
	db	88h

	db	'gsize'
	db	89h

	db	'gcolor'
	db	8ah

	db	'roll'
	db	8bh

	db	'on'
	db	8ch

	db	'error'
	db	8dh

	db	'pokes'
	db	8eh

	db	'rename'
	db	8fh

	db	'help'
	db	90h

	db	'modulus'
	db	91h

	db	'doscmd'
	db	92h

	db	'pause'
	db	93h

	db	'school'
	db	94h

	db	'create'
	db	95h

	db	'def'
	db	96h

	db	'interrupt'
	db	97h

;extended 関数 codemark3(=0b2H)+0aeH~0FFH

	db	'#ds'
	db	0aeh

	db	'#es'
	db	0afh

	db	'#ax'
	db	0b0h

	db	'#bx'
	db	0b1h

	db	'#cx'
	db	0b2h

	db	'#dx'
	db	0b3h

	db	'#si'
	db	0b4h

	db	'#di'
	db	0b5h

	db	'#bp'
	db	0b6h

	db	'#flg'
	db	0b7h


	db	'fcos('
	db	0b8h

	db	'fsin('
	db	0b9h

	db	'ftan('
	db	0bah

	db	'fatan('
	db	0bbh

	db	'fsqrt('
	db	0bch

	db	'flog('
	db	0bdh

	db	'flog2('
	db	0beh

	db	'flog10('
	db	0bfh

	DB	'dot('
	DB	0c0H

	DB	'instr('
	db	0c1h

	DB	'instr2('
	DB	0c2H

	db	'find2('
	db	0c3h

	db	'num('
	db	0c4h

	db	'den('
	db	0c5h

	DB	'posx'
	DB	0c6H

	DB	'posy'
	DB	0c7H

	DB	'hex('
	DB	0c8H
	DB	'hex$('
	DB	0c8H

	db	'upper('
	db	0c9h

	db	'lower('
	db	0cah

	db	'inp('
	db	0cbh

	db	'type('
	db	0cch

	db	'attrib('
	db	0cdh

	db	'varptr('
	db	0ceh

	db	'keyscan'
	db	0cfh

	db	'zenkaku('
	db	0d0h

	db	'hankaku('
	db	0d1h

	db	'cutspc('
	db	0d2h

	db	'cutlspc('
	db	0d3h

	db	'mapx('
	db	0d4h

	db	'mapy('
	db	0d5h

	db	'peek('
	db	0d6h

	db	'peekw('
	db	0d7h

	db	'gposx'
	db	0d8h

	db	'gposy'
	db	0d9h

	db	'exist('
	db	0dah

	db	'deg('
	db	0dbh

	db	'diff('
	db	0dch

	db	'monic('
	db	0ddh

	db	'lcoeff('
	db	0deh

	db	'ccoeff('
	db	0dfh

	db	'modmul('
	db	0e0h

	db	'version'
	db	0e1h

	db	'peeks('
	db	0e2h

	db	'lcm('
	db	0e3h

	db	'getenv('
	db	0e4h

	db	'modsqrt('
	db	0e5h

	db	'#up'		;'#xmax'
	db	0e6h

	db	'#down'		;'#ymax'
	db	0e7h

	db	'bitor('
	db	0e8h

	db	'bitand('
	db	0e9h

	db	'bitxor('
	db	0eah

	db	'bitset('
	db	0ebh

	db	'bitreset('
	db	0ech

	db	'bitreverse('
	db	0edh

	db	'bitcount('
	db	0eeh

	db	'#left'		;'gxxfer('
	db	0efh

	db	'#right'	;'gyxfer('
	db	0f0h

	db	'floor('
	db	0f1h

	db	'ceil('
	db	0f2h

	db	'asin('
	db	0f3h

	db	'acos('
	db	0f4h

	db	'time1000'
	db	0f5h

	db	'#sys('
	db	0f6h

	db	'exponent('
	db	0f7h

	db	'significand('
	db	0f8h

	db	'sizeof('
	db	0f9h

	db	'link('
	db	0fah

	db	'pointset('
	db	0fbh

	db	'polyconv('
	db	0fch

	db	'polyrev('
	db	0fdh


	dw	0ffh		;endmark

DATA	ENDS



CODE	SEGMENT WORD PUBLIC
	ASSUME	CS:CODE,DS:DATA



;PUBLIC LABELS

	PUBLIC	ENCODE,ENCDIN,CHG2CAP,DecodeToken
	PUBLIC	NUMER?
	PUBLIC	DECODE,NUMSET,BINASC,farBINASC,binascret
	public	ASCHL1000,faraschl1000
	public	farDECODE,farENCODE
	PUBLIC	JMPTBL,JMPTBL2

;EXTERNAL LABELS

	EXTRN	MAINLP:NEAR,MAININ:NEAR
	EXTRN	DATAIN:NEAR,PASNXT_REM:NEAR
	EXTRN	INCLENSYS:NEAR

	EXTRN	OPTIONCMD:NEAR,optioncmd3:near
	extrn	CLS:NEAR,console:near,width:near
	extrn	SYSTEM:NEAR,putgraph:near
	extrn	EMAWORD:near,useEMA:near

	EXTRN	GOTO:NEAR,GOSUB:NEAR,RUN:NEAR,POINTIN:NEAR
	EXTRN	FORIN:NEAR,NEXT:NEAR
	EXTRN	IFIN:NEAR,THENIN:NEAR,ELSEIN:NEAR
	EXTRN	ELSEIFIN:NEAR,IF2IN:NEAR
	EXTRN	WHILE:NEAR,WEND:NEAR,REPEAT:NEAR,UNTIL:NEAR,RENUM:NEAR
	EXTRN	CANCEL:NEAR,RETURN:NEAR,ENDIN:NEAR,PRINT:NEAR
	extrn	evalin:near,evalout:near
	EXTRN	LIST:NEAR,LPRINT:NEAR,LLIST:NEAR,DELETE:NEAR
	EXTRN	WORDIN:NEAR,NEW:NEAR,INCIN:NEAR,DECIN:NEAR
	EXTRN	NEGIN:NEAR,JUMPIN:NEAR,LOOPIN:NEAR,ENDLOOP:NEAR
	EXTRN	DIM:NEAR,stopin:near
	extrn	linein:near,psetin:near,circlein:near,paintin:near
	extrn	viewin:near,colorin:near,windowin:near
	EXTRN	SCREENIN:NEAR
	EXTRN	FREEZEIN:NEAR,MELTIN:NEAR,BLOCKIN:NEAR
	EXTRN	CONTIN:NEAR,HCOPYIN:NEAR,BEEPIN:NEAR
	EXTRN	READIN:NEAR,RESTORE:NEAR,OPENIN:NEAR,CLOSEIN:NEAR
	EXTRN	SETRWIN:NEAR,EDIT:NEAR,LOCATE:NEAR,LLOCATE:NEAR
	EXTRN	CALLIN:NEAR
	EXTRN	ERASEIN:NEAR,FREEIN2:NEAR
	EXTRN	RANDOMIZE:NEAR
	EXTRN	ASAVE:NEAR,SAVEIN:NEAR,LDIRIN:NEAR,AUTOIN:NEAR
	EXTRN	LOADIN:NEAR,KILLIN:NEAR,USRLOADIN:NEAR
	EXTRN	TRON:NEAR,TROFF:NEAR,XREFIN:NEAR,LXREFIN:NEAR
	EXTRN	DIRIN:NEAR,SWAP:NEAR,REDUCE:NEAR
	extrn	INPUT:NEAR,strinput:near
	EXTRN	CLRIN:NEAR,VXREF:NEAR,LVXREF:NEAR,VLIST:NEAR
	EXTRN	LVLIST:NEAR,REVIVE:NEAR,APPEND:NEAR,vchg:near

	EXTRN	LET0:NEAR,LET1:NEAR,LET2:NEAR
	EXTRN	LET3:NEAR,LET4:NEAR,LET5:NEAR

	EXTRN	SYNERR:NEAR,LINERR:NEAR

	extrn	pointascin:near


JMPTBL	LABEL WORD
	DW	OPTIONCMD	;80H

	DW	LET0		;81H
	DW	LET1		;82H
	DW	LET2		;83H
	DW	LET3		;84H
	DW	LET4		;85H
	DW	LET5		;86H

	DW	GOTO		;87H
	DW	GOSUB		;88H
	DW	FORIN		;89H
	DW	SYNERR		;8AH(TO)
	DW	SYNERR		;8BH(STEP)
	DW	NEXT		;8CH
	DW	IFIN		;8DH
	DW	THENIN		;8EH
	DW	ELSEIN		;8FH
	DW	WHILE		;90H
	DW	WEND		;91H
	DW	REPEAT		;92H
	DW	UNTIL		;93H
	DW	CANCEL		;94H
	DW	RETURN		;95H
	DW	stopin		;96H(STOP)
	DW	MAINLP		;97H(ENDIF)
	DW	PASNXT_REM	;98H(REM)
	DW	PRINT		;99H
	DW	LPRINT		;9AH
	DW	READIN		;9BH(READ)
	DW	DATAIN		;9CH
	DW	RESTORE		;9DH(RESTORE)
	DW	SYNERR		;9EH
	DW	WORDIN		;9FH
	DW	INCIN		;A0H
	DW	DECIN		;A1H
	DW	BLOCKIN		;A2H
	DW	SYNERR		;A3H(RES)
	DW	DIM		;A4H
	DW	SWAP		;A5H
	DW	REDUCE		;A6H
	DW	INPUT		;A7H
	DW	CLRIN		;A8H
	DW	POINTIN		;A9H
	DW	ERASEIN		;AAH
	DW	MAININ		;ABH(NOP)
	DW	LOCATE		;ACH
	DW	LLOCATE		;ADH
	DW	CALLIN		;AEH
	DW	ELSEIFIN	;AFH
	DW	IF2IN		;B0H
	DW	strinput	;B1H
	DW	optioncmd3	;B2H(option command)
	DW	SYNERR		;B3H(fn)
	DW	NEGIN		;B4H
	DW	SYNERR		;B5H
	DW	JUMPIN		;B6H
	DW	MAINLP		;B7H(MARK)
	DW	LOOPIN		;B8H
	DW	ENDLOOP		;B9H
	DW	SYNERR		;BAH(LOCAL)
	DW	synerr		;BBH(&h)
	DW	evalin		;BCH
	DW	evalout		;BDH
	DW	synerr		;BEH
	DW	ENDIN		;BFH
	DW	MAINLP		;c0H(:)
	DW	synerr		;c1H
	DW	synerr		;c2H
	DW	synerr		;c3H
	DW	synerr		;c4H
	DW	synerr		;c5H
	DW	synerr		;c6H
	DW	VIEWIN		;c7H
	DW	colorin		;c8H
	DW	windowin	;c9H
	DW	screenin	;caH
	DW	LINEIN		;cBH
	DW	PSETIN		;cCH
	DW	CIRCLEIN	;cDH
	DW	PAINTIN		;cEH

JMPTBL2	LABEL WORD

	DW	LIST		;8080H
	DW	LLIST		;8081H
	DW	RUN		;8082H
	DW	DELETE		;8083H
	DW	RENUM		;8084H
	DW	SAVEIN		;8085H
	DW	LOADIN		;8086H
	DW	ASAVE		;8087H
	DW	DIRIN		;8088H
	DW	VXREF		;8089H
	DW	LVXREF		;808AH
	DW	VLIST		;808BH
	DW	LVLIST		;808CH
	DW	SYSTEM		;808DH
	DW	NEW		;808EH
	DW	vchg		;808FH
	DW	REVIVE		;8090H
	DW	APPEND		;8091H
	DW	OPENIN		;8092H
	DW	SYNERR		;8093H
	DW	SYNERR		;8094H
	DW	CLOSEIN		;8095H
	DW	SETRWIN		;8096H
	DW	EDIT		;8097H
	DW	KILLIN		;8098H
	DW	SYNERR		;8099H(DATE)
	DW	SYNERR		;809AH(TIME)
	DW	width		;809BH
	DW	USRLOADIN	;809CH
	DW	TRON		;809DH
	DW	TROFF		;809EH
	DW	CONTIN		;809FH
	DW	HCOPYIN		;80A0H
	DW	FREEZEIN	;80A1H
	DW	XREFIN		;80A2H
	DW	LXREFIN		;80A3H
	DW	BEEPIN		;80A4H
	DW	LDIRIN		;80A5H
	DW	MELTIN		;80A6H
	DW	FREEIN2		;80A7H
	DW	RANDOMIZE	;80A8H
	DW	AUTOIN		;80A9H
	DW	useema		;80AAH
	DW	emaword		;80ABH
	DW	synerr		;80ACH(skip)
	DW	CLS		;80ADH
	DW	CONSOLE		;80AEH
	dw	putgraph	;80afh


;
;☆INPBUF にある ASCII TEXT を PSEUDO CODE に直して CODBUF+2 に置く
;  +2 は PROGRAM の場合の NEXT ADDRESS 用
;  DI は CODBUF 内の次のアドレスを指して戻る

farENCODE:
	call	ENCODE
	retf

ENCODE:	
	MOV	BP,INPBUF	;pointer
	MOV	DI,CODBUF+2	;pointer
	XOR	AX,AX
	MOV	[directflg],-1		;DIRECT MODE
	MOV	[DI-2],AX

	CALL	SKIP_SPACE

	CALL	NUMER?
	JNZ	CODEENT

;数値ならば行番号なので変換してセット

	CALL	LINHEX

	MOV	[directflg],0
	MOV	AX,BX
	STOSW

;スペースを数えて、個数をセット

	XOR	AX,AX
	MOV	SI,DI		;MEMO POINTER
AFTSPL:	
	MOV	AH,[BP]
	cmp	ah,tab
	jne	lineno90
	inc	bp
	add	al,3
	jmp	aftspl	
lineno90:
	CMP	AH,' '
	JNE	LINENO100
	INC	AL
	INC	BP
	JMPS	AFTSPL
LINENO100:
	cmp	al,3
	jae	lineno110
	mov	al,3
LINENO110:
	STOSB			;' ' の個数

;LABEL の CHECK
	
	MOV	AL,AH
	CMP	AL,'*'
	JNE	CODEENT
	CMP	BYTE PTR [BP+1],'*'
	JE	CODEENT		;** is a target mark of jump
	INC	BP
	CALL	LABELSET
	JMP	CODELP


;変換のメイン・ルーチン(INPUT からも CALL される)

IsLabel?:
	stosb
	inc	bp
	call	skip_space
	cmp	al,'*'
	jne	codeent
	INC	BP
	CALL	LABELSET
	jmp	codelp

ENCDIN:
CODELP:	
	CALL	SKIP_SPACE
CODEENT:
	CMP	AL,CR

	;CR is the end mark of text

	JMPZ	ENDTX1

	CMP	AL,80H
	JAE	GOSETASC	;kanji

	cmp	al,'&'
	je	IsLabel?
	CMP	AL,'.'
	JE	NUMPT_IN	;fraction
CODEBACK:

	CALL	NUMER?

	;数値ならば

	JMPZ	NUMSET_IN

	CALL	CMD?
	JNC	CODE10		;NORMAL COMMAND

	CALL	CMD2?
	jnc	extcode2

	call	cmd3?
	jnc	extcode3
	cmp	al,')'
	jne	gosetasc
	cmp	byte ptr [bp],'.'
	jne	gosetasc
	jmp	varsetmember
gosetasc:
	jmp	SETASC	;if not code

	;拡張コマンド OR 関数ならば
extcode2:
	MOV	AH,AL		;MEMO
	MOV	AL,codemark2	;80H
	STOSW
	CMP	AH,80H
	JE	GOSETN_IN	;'LIST'
	CMP	AH,81H
	JE	GOSETN_IN	;'LLIST'
	CMP	AH,97H
	JE	GOSETN_IN	;'EDIT'
	CMP	AH,0A2H
	JE	GOSETN_IN	;'XREF'
	CMP	AH,0A3H
	JE	GOSETN_IN	;'LXREF'
	CMP	AH,8FH
	JE	GOSETN_IN	;'VCHG'
	cmp	ah,0e7h		
	je	set_andor	;and{
	cmp	ah,0e8h
	je	set_andor	;or{
	JMP	CODELP

extcode3:
	mov	ah,al
	mov	al,codemark3	;=0b2h
	stosw
	jmp	codelp


set_andor:
	xor	ax,ax
	stosw			;will be filled by jump address
	jmp	codelp


	;REM ならば CR が出るまでコピー
MOVBLK:
	XOR	AX,AX
	STOSW			;SET 2 BYTES WORK
MOVBLK10:
	MOV	AL,[BP]
	CMP	AL,CR
	JMPZ	ENDTX1
	OR	AL,AL
	JNZ	MOVBLK20
	MOV	AL,' '
MOVBLK20:
	STOSB
	INC	BP
	JMP	MOVBLK10

; member of pack

numpt_member:
	mov	[di],al		;set '.'
	inc	di
	inc	bp

	call	ascbin

	mov	bx,work3
	mov	cx,[bx]
	add	bx,2
	cmp	cx,1
	jne	memberilg

	mov	al,NCODE1
	stosb
	mov	ax,[bx]
	stosw
	jmps	memberjp

memberjp:
	mov	al,[bp]
	cmp	al,'.'
	je	numpt_member
	jmp	codelp

memberilg:
	mov	al,NCODE
	jcxz	member0
	mov	al,NCODE2
member0:
	stosb
	jmps	memberjp


; label

itsalabel:
	inc	bp
	mov	al,0b3h		;code of fn
	jmp	code10

; '.' + number

NUMPT_IN:
	cmp	byte ptr [bp-1],')'	;is ). ?
	je	numpt_member

	mov	al,[bp+1]
	CMP	al,'.'		;更に . か
	JMPZ	CODEBACK	;小数でない
	cmp	al,'9'
	ja	itsalabel
	cmp	al,'0'
	jb	itsalabel

	MOV	BYTE PTR [DI],NCODE	;0. になるように 0 を置く
	INC	DI
numpt_10:
	mov	al,'.'
	CALL	NUMPT
	mov	al,[bp]
	or	al,20h
	cmp	al,'e'
	je	numsetbias
numpt_gocodelp:
	JMP	CODELP

numsetbias:
	mov	ah,[bp+1]
	cmp	ah,'-'
	je	numsetbiasyes
	cmp	ah,'+'
	je	numsetbiasyes
	cmp	ah,'0'
	jb	numpt_gocodelp
	cmp	ah,'9'
	ja	numpt_gocodelp
numsetbiasyes:
	mov	[di],al
	inc	di
	inc	bp
	cmp	ah,'+'
	jne	numsetbiasyesjp
	inc	bp		;skip + mark
numsetbiasyesjp:
	jmp	codelp

numsethex:
	add	bp,2
	mov	al,0bbh		;code of hex
	jmp	code10

NUMSET_IN:
	mov	ax,[bp]
	or	ah,20h
	cmp	ax,'x0'
	je	numsethex
	push	di
	CALL	NUMSET
	pop	si
numset_in40:
	mov	al,[bp]
	cmp	al,' '
	je	numset_in50
	cmp	al,'#'
	je	numsetcomplex?
	or	al,20h
	cmp	al,'e'
	je	numsetbias
numset_in100:
	JMP	CODELP

numset_in50:
	inc	bp
	jmp	numset_in40

numsetcomplex?:
	mov	al,[bp+1]
	and	al,11011111b	;cut bit5
	cmp	al,'I'
	jne	numset_in100
	winc	bp		;#i after a number
	mov	al,9eh		;#i
	stosb
	jmp	codelp


GOSETN_IN:
	CALL	GOSETN
	JMP	CODELP
GOSETN_IN10:
	CALL	GOSETN10
	JMP	CODELP
GOSET_FUN:
	CMP	BYTE PTR [BP],'*'
	JNE	GOSET_FUN20
	INC	BP
GOSET_FUN10:
	CALL	LABELSET
	JMP	CODELP
GOSET_FUN20:
	CMP	BYTE PTR [BP],'='
	JNE	GOSET_FUN10
	JMP	CODELP
goset_hexnum:
	call	encodehexnum
	jmp	codelp

CODE10:
	STOSB

	CMP	AL,87H		;GOTO
	JE	GOSETN_IN

	CMP	AL,88H		;GOSUB
	JE	GOSETN_IN

	CMP	AL,9DH		;RESTORE
	JE	GOSETN_IN

	CMP	AL,0B3H		;fn
	JE	GOSET_FUN

	CMP	AL,98H		;REM
	JE	MOVBLK

	cmp	al,0bbh		;code of hex
	je	goset_hexnum

	CMP	AL,08DH		;IF
	JB	GOCODELP
	CMP	AL,0AFH		;ELSEIF
	JE	CODE19
	CMP	AL,0B6H		;JUMP
	JE	CODE15
	CMP	AL,0B8H		;LOOP
	JE	CODE15
	CMP	AL,0B9H		;ENDLOOP
	JE	CODE15
	CMP	AL,93H		;UNTIL
	JA	GOCODELP

	;IF,ELSE,ELSEIF,WHILE,WEND,REPEAT,UNTIL,JUMP
	;ならば後ろに 0000H を置く
	;非成立時に飛び先を置くエリア

	CMP	AL,8FH		;ELSE
	JE	CODE20
	CMP	AL,8EH		;THEN
	JE	CODE30
CODE15:
	XOR	AX,AX
	STOSW
GOCODELP:
	JMP	CODELP

CODE19:
	XOR	AX,AX
	STOSW
	MOV	AL,0B0H		;secret IF
	STOSB
	jmp	code15

CODE20:
	XOR	AX,AX
	STOSW
CODE30:
	CALL	SKIP_SPACE	;THEN, ELSE 行番号の処理
	CMP	AL,'*'
	JE	GOSETN_IN10
	CMP	AL,'0'
	JB	GOCODELP
	CMP	AL,'9'
	JA	GOCODELP
	JMP	GOSETN_IN10


;PCODE でないのは変数又は”


SETPI:
	CMP	BYTE PTR [BP+1],0CEH
	JNE	SETASC10
	WINC	BP
	MOV	AX,0CD80H	;CODE OF #pi
	STOSW
	JMP	CODELP


SETASC:	
	MOV	AL,[BP]
	CMP	AL,83H		;1ST BYTE OF π
	JE	SETPI
SETASC10:
	INC	BP
	CALL	CHG2CAP

	CALL	ALPBTKAN?

	JZ	VARSET_IN	;変数ならば

	STOSB
	CMP	AL,'"'
	je	quote

	cmp	al,'_'
	jne	gocodelp2
polymode:
	mov	al,[bp]		;_ or _X is a variable
	and	al,11011111b	;of polynomials
	cmp	al,'X'
	jne	polymode10
	inc	bp
polymode10:
	mov	al,'X'
	stosb
gocodelp2:
	JMP	CODELP			;本来はエラー


	;" のあとの " または CR まで コピー

QUOTE:
	mov	ah,al
QUOTELP:	
	MOV	AL,[BP]
	OR	AL,AL
	JNZ	QUOTE10
	MOV	AL,' '		; 0 は ' ' に
QUOTE10:
	STOSB
	INC	BP
	CMP	AL,ah
	je	goCODELP2
	CMP	AL,CR
	JNE	QUOTELP

	;二つ目の " が出る前に行が終わったら " を補う

	MOV	BYTE PTR [DI-1],ah

;一行終了の後始末

ENDTX1:	
	MOV	AL,CR
	STOSB
	MOV	AX,DI			;DI は保存
	SUB	AX,CODBUF
	MOV	[INPUTLEN],AX
	RET	


VARSET_IN:
	CALL	VARSET

	cmp	word ptr [bp],'..'
	je	varsetout
	cmp	byte ptr [bp],'.'
	je	varsetmember
varsetout:
	JMP	CODELP

varsetmember:
	mov	al,'.'
	jmp	numpt_member



;☆小数値のセット

NUMPT:
	STOSB			;'.' をそのままセット
	INC	BP
	CALL	SKIP_SPACE
	DEC	BP
	MOV	BYTE PTR [BP],'1'	;0が無くされないように1を置く
	JMP	NUMSET		;CALL & RET


;* set number

NUMSET:
	;trans to binary and set in WORK3

	CALL	ASCBIN

	;それを長さに応じてセット

	MOV	BX,WORK3
	MOV	CX,[BX]
	ADD	BX,2
	CMP	CX,1
	JE	SHORT1
	JA	LONG

	;if 0

	MOV	AL,NCODE
	STOSB

NUMPOINT?:
	MOV	AX,[BP]
	CMP	AL,'.'		;まずは . か
	JNE	NUMRET
	CMP	AH,'.'		;更に . か
	JNE	NUMPT		;違えば小数(call & ret)
NUMRET:
	MOV BYTE PTR ES:[DI],0	;AVOID MISS READ
	RET

	;１ワードの数ならば
SHORT1:
	MOV	AL,NCODE1
	STOSB
	MOV	AX,[BX]
	STOSW
	JMP	NUMPOINT?

	;多ワードの数
LONG:
	MOV	AL,NCODE2
	STOSB
	MOV	AX,CX
	STOSW				;長さ
	AND	CH,LENMASKHIGH
	MOV	SI,BX
	REP	MOVSW
	JMP	NUMPOINT?


;
;* set hex number
;
encodehexnum:
	mov	si,bp
	mov	al,ncode2
	stosb
	mov	dx,di		;memo dest adr
	mov	word ptr [di],0
	mov	word ptr [di+2],0
sethex10:
	lodsb
	cmp	al,'0'
	je	sethex10
	dec	si
sethexlp:
	lodsb
	cmp	al,'0'
	jb	sethexout
	cmp	al,'9'
	jbe	sethexin
	or	al,00100000b
	cmp	al,'a'
	jb	sethexout
	cmp	al,'f'
	ja	sethexout
	sub	al,'a'-'9'-1
sethexin:
	sub	al,'0'
	call	sethexsub	;shift 4 bits and add al
	jmp	sethexlp
sethexout:
	lea	bp,[si-1]
	mov	di,dx
	mov	ax,[di]
	inc	ax
	shl	ax,1
	add	di,ax
	ret

sethexsub:
	push	si
	push	di
	push	bx
	push	cx

	mov	si,dx
	mov	di,dx
	mov	cx,[si]
	jcxz	sethexsub100
	add	si,2
	mov	bh,al
sethexsub50:
	mov	ax,[si]
	mov	bl,ah		;memo higher byte
	my_shl	ax,4
	or	al,bh
	mov	[si],ax
	add	si,2
	xor	bh,bh
	my_shl	bx,4	
	myloop	sethexsub50
	or	bh,bh
	jz	sethexsubret
	inc	word ptr [di]	;inc length
	mov	bl,bh
	xor	bh,bh
	mov	[si],bx

sethexsubret:
	pop	cx
	pop	bx
	pop	di
	pop	si
	ret
sethexsub100:
	xor	ah,ah
	mov	word ptr [si],1
	mov	[si+2],ax
	jmp	sethexsubret
	

;☆GOTO GOSUB の飛び先行番号ラベルのセット

GOSETN	PROC

	CALL	SKIP_SPACE
GOSETN10:
	CMP	AL,'*'
	JE	GOSETLABEL
	CALL	NUMER?
	JNZ	GOSETNRET	;これは本当はエラー
	CALL	LINHEX
	MOV	AL,NCODE1
	STOSB
	MOV	AX,BX
	STOSW
GOSETNRET:
	RET

GOSETLABEL:
	INC	BP
	JMP	LABELSET	;CALL & RET

GOSETN	ENDP


;☆LABEL のセット
public labelset
labelset:
	push	di		;*

	winc	di
	mov	al,[bp]
	inc	bp
	call	varsetsub
	jc	labelset10	;if no char
	call	chg2cap
	MOV	ES:[DI],AL	;第一文字
	MOV	AH,AL		;use for kanji flg
	inc	di
	mov	cx,labellen-1
labelsetlp:
	MOV	AL,[BP]
	INC	BP
	CALL	varsetSUB
	JC	labelset10
	MOV	ES:[DI],AL
	inc	di
	myloop	labelsetlp
labelset5:			;cut characters
	MOV	AL,[BP]
	INC	BP
	CALL	varsetSUB
	JNC	labelset5
labelset10:
	cmp	al,':'
	je	labelset15	;neglect :
	dec	bp
labelset15:
	pop	si
	mov	byte ptr [si],ncode_label
	inc	si
	mov	ax,di
	sub	ax,si
	dec	ax
	jz	labelset20
	mov	[si],al		;chars(not +1 not or80h)
	xor	ax,ax
	stosw			;to be filled by jump adr
	ret

labelset20:			;if no char
	inc	al
	mov	[si],al
	mov	al,'_'		;only _
	stosb
	xor	ax,ax
	stosw
	ret


;☆変数のセット

VARSET:
	push	di		;*

	winc	di
	MOV	ES:[DI],AL	;第一文字
	MOV	AH,AL		;use for kanji flg
	inc	di
	mov	cx,namelen-5	;3
varsetlp:
	MOV	AL,[BP]
	INC	BP
	CALL	VARSETSUB
	JC	VARSET10
	MOV	ES:[DI],AL
	inc	di
	myloop	varsetlp

	CMP	AH,81H
	JB	VARSET5
	CMP	AH,9FH
	JBE	VARSET3
	CMP	AH,0E0H
	JB	VARSET5
	CMP	AH,0FCH
	ja	varset5
varset3:
	dec	di		;cut kanji 1st char
	
varset5:			;cut chars
	MOV	AL,[BP]
	INC	BP
	CALL	VARSETSUB
	JNC	VARSET5

varset10:
	mov	ah,al
	CMP	AL,'%'
	JNE	VARSET20
	XOR	CL,CL		;短変数
	MOV	AL,[BP]
	INC	BP
	JMPS	VARSET30

VARSET20:
	MOV	CL,2		;長変数
	CMP	AL,'#'
	JNE	VARSET30

	MOV	CL,4		;特別変数
	MOV	AL,[BP]
	INC	BP
VARSET30:
	CMP	AL,'('
	JNE	VARSET100
	inc	cl		;配列
	cmp	byte ptr [bp],')'
	jne	varset110
	winc	bp		;neglect )
VARSET100:
	DEC	BP
varset110:
	MOV	AL,CL
	ADD	AL,VCODE
	pop	si
	mov	[si],al		;set varcode
	inc	si
	mov	ax,di
	sub	ax,si
	dec	ax
	cmp	al,1
	jne	varset120
	inc	al		;add 0 if 1char
	mov	byte ptr [di],0
	inc	di
varset120:
	mov	[si],al		;set chars
	RET


VARSETSUB:	
	CMP	AH,81H
	JB	VARSETSUB2
	CMP	AH,9FH
	JBE	VARSETSUBkanji2nd	;漢字
	CMP	AH,0E0H
	JB	VARSETSUB2
	CMP	AH,0FCH
	JBE	VARSETSUBkanji2nd
VARSETSUB2:
	CALL	ALPNUMKANA?
	JNZ	VARSETSUB10
VARSETSUB5:
	MOV	AH,AL
	CLC
	RET

VARSETSUB10:
	STC
	RET

varsetsubkanji2nd:
	xor	ah,ah		;reset kanji mode(also clc)
	ret
	

;*****************
;*               *
;*  subroutines  *
;*               *
;*****************


;☆小文字を大文字に変換

CHG2CAP:	
	CMP	AL,'a'
	JB	CHG2CAP100
	CMP	AL,'z'
	JA	CHG2CAP100
	SUB	AL,20H
CHG2CAP100:
	RET	

;☆スペースをスキップ
;  OUTPUT:A=non-space data
;         BP=that point

SKPSP10:	
	INC	BP

SKIP_SPACE:
	MOV	AL,[BP]
	CMP	AL,' '
	JE	SKPSP10
	OR	AL,AL
	JZ	SKPSP10
	cmp	al,tab
	je	skpsp10
	RET


;☆数値か？
;  OUTPUT:Z=1 if A is numeric data

NUMER?:	
	CMP	AL,'0'
	JB	NUMER?100
	CMP	AL,'9'
	JA	NUMER?100
	CMP	AL,AL			;set Z-flag
NUMER?100:
	RET	

;☆アルファベットか？
;  OUTPUT:Z=1 if A is a capital of alphabet or kanji or kana

ALPBTKAN?:	
	CMP	AL,'A'
	JB	ALPBT100
	CMP	AL,'Z'
	jbe	alpbt90
	cmp	al,'a'
	jb	alpbt100
	cmp	al,'z'
	JA	ALPBT110
ALPBT90:
	CMP	AL,AL			;set Z-flag
ALPBT100:
	RET	
ALPBT110:
	CMP	AL,80H
	JB	ALPBT100
	JMP	ALPBT90

;☆ALPHABET または数値かカナか？
;  OUTPUT:Z=1 if AL is alphabet or numeric data or kana
;		 $ _ ? & is also ok
ALPNUMKANA?:
	cmp	al,'_'
	je	alpnumkanaret
	cmp	al,'$'
	je	alpnumkanaret
	cmp	al,'?'
	je	alpnumkanaret
	cmp	al,'&'
	je	alpnumkanaret
	CMP	AL,'0'
	JB	alpnumkanaRET
	CMP	AL,'9'
	JBE	alpnumkanaOK
	CMP	AL,'A'
	JB	alpnumkanaRET
	CMP	AL,'Z'
	JBE	alpnumkanaOK
	CMP	AL,'a'
	JB	alpnumkanaRET
	CMP	AL,'z'
	JBE	alpnumkanaOK
	CMP	AL,80H
	JB	alpnumkanaRET
alpnumkanaOK:
	CMP	AL,AL			;set Z-flag
alpnumkanaRET:
	RET	

;
;* check if AL is an alphabet/numeric
;	ZF=1 iff yes
alpnum?:
	cmp	al,'0'
	jb	noalpnum
	cmp	al,'9'
	jbe	yesalpnum
	cmp	al,'A'
	jb	noalpnum
	cmp	al,'Z'
	jbe	yesalpnum
	cmp	al,'a'
	jb	noalpnum
	cmp	al,'z'
	jbe	yesalpnum
noalpnum:
	cmp	al,'A'		;reset ZF
	ret
yesalpnum:
	cmp	al,al		;set ZF
	ret


;☆ASCII 列の数字を 2 BYTES の BINARY にして BX に返す

LINHEX:
	XOR	AX,AX
	MOV	AL,[BP]
	SUB	AL,'0'
	MOV	BX,AX
LINHLP:	
	INC	BP
	MOV	AL,[BP]
	SUB	AL,'0'
	CMP	AL,10
	JAE	LINH100

	SHL	BX,1			;BX=BX*10
	JC	GOLERR
	MOV	DX,BX
	SHL	BX,1
	JC	GOLERR
	SHL	BX,1
	JC	GOLERR
	ADD	BX,DX
	JC	GOLERR

	ADD	BX,AX
	JNC	LINHLP
GOLERR:	
	JMP	LINERR

LINH100:
	or	bx,bx
	jz	linerr
	RET


;☆コマンドのサーチ
;    OUTPUT:AL=0 if not command
;           othewise AL is a code

CMDPRINT:
	MOV	AL,99H		;CODE OF PRINT
	INC	BP
	CLC
	RET

CMDREM:
	MOV	AL,98H		;CODE OF REM
	INC	BP
	CLC
	RET

cmdcomplex:
	mov	al,[bp+1]
	and	al,11011111b
	mov	ah,9eh		;code of #i
	cmp	al,'I'
	je	cmd_ih
;	mov	ah,0bbh		;code of #h
;	cmp	al,'H'
	jne	symbol
cmd_ih:
	mov	al,ah
	winc	bp
	clc
	ret

CMD?:
	cmp	al,'#'
	je	cmdcomplex
	CMP	AL,'?'
	JE	CMDPRINT
	CMP	AL,27H		;CODE OF '
	JE	CMDREM
	CMP	AL,'A'
	JB	SYMBOL
	CMP	AL,'Z'
	JBE	CMD?IN
	CMP	AL,'a'
	JB	SYMBOL
	CMP	AL,'z'
	JBE	CMD?IN
	JMP	SYMBOL

CMD?IN:
	PUSH	DI
	MOV	DI,OFFSET CMDTBL+1
	MOV	SI,BP		;MEMO TOP
CMDLP1:	
	MOV	BP,SI
	MOV	AL,[BP]
	CALL	CHGSML
CMDLP2:	
	mov	ah,[di]
	CMP	AL,ah
	JNE	NXTCMD		;等しくなければ次の命令へ

	INC	BP
	INC	DI
	MOV	AL,[DI]

	cmp	al,0b3h		;fn
	je	cmd?ret
	CMP	AL,80H		;next is code?	
	jb	cmd50		;no

	cmp	ah,'('
	je	cmd?ret
	cmp	ah,'{'
	je	cmd?ret

	mov	ah,al
	mov	al,[bp]		;yes
	cmp	al,'$'
	je	cmd50		;$ is not a separator
	cmp	al,'{'
	je	cmd50		;{ is not a separator
	call	alpnum?		;is [bp] an alpha_numeric?
	mov	al,ah
	jnz	CMD?RET		;no(means separator)
				;yes
cmd50:
	MOV	AL,[BP]
	CALL	CHGSML
	JMPS	CMDLP2

CMD?RET:	
	CLC
CMD?RETC:
	POP	DI
	RET	

;次のコマンド部分までスキップ

NXTCMD:	
	MOV	AL,[DI]
	INC	DI
	CMP	AL,80H
	JB	NXTCMD		;if not p-code
NXTCMD10:
	MOV	AL,[DI]		;next of p-code
	OR	AL,AL
	JNZ	CMDLP1

;次の命令がない場合

	MOV	BP,SI
	STC
	JMP	CMD?RETC

SYMBOL:
	MOV	AX,[BP]
	CMP	AX,'**'
	JE	CMD?IN
	PUSH	DI
	MOV	DI,OFFSET SEPTBL+1
	MOV	SI,BP		;MEMO TOP
SYMLP1:	
	MOV	BP,SI
	MOV	AL,[BP]
SYMLP2:	
	CMP	AL,[DI]
	JNE	SYMNXTCMD	;等しくなければ次の命令へ

	INC	BP
	INC	DI
	MOV	AL,[DI]

	CMP	AL,80H
	JAE	CMD?RET		;次が >=80H ならば全て一致

	MOV	AL,[BP]
	JMPS	SYMLP2

	;次のコマンド部分までスキップ

SYMNXTCMD:	
	MOV	AL,[DI]
	INC	DI
	CMP	AL,80H
	JB	SYMNXTCMD	;if not p-code
SYMNXTCMD10:
	MOV	AL,[DI]		;next of p-code
	OR	AL,AL
	JNZ	SYMLP1

	;次の命令がない場合

	MOV	BP,SI
	STC
	JMP	CMD?RETC


;☆コマンドのサーチ(その２)
;    OUTPUT:A=0 if not command
;           othewise A is a code

CMD2?:

	PUSH	DI
	MOV	DI,OFFSET CMDTBL2+1
	MOV	SI,BP			;MEMO TOP
	JMP	CMDLP1

; * command search(part3)
;    OUTPUT:A=0 if not command
;           othewise A is a code

CMD3?:

	PUSH	DI
	MOV	DI,OFFSET CMDTBL3+1
	MOV	SI,BP			;MEMO TOP
	JMP	CMDLP1


;☆大文字を小文字に直す

CHGSML:	
	CMP	AL,'A'
	JB	CHGSML100
	CMP	AL,'Z'
	JA	CHGSML100
	ADD	AL,20H
CHGSML100:
	RET	



;☆ASCII の数字列を 2 進に直すメイン・ルーチン
;文字列は BP で INDEXED
;結果は WORK3 に置く
;補助に WORK4 を用いる

public	ASCBIN
ASCBIN:	
	PUSH	DI
	MOV	DI,WORK3
	XOR	AX,AX
	STOSW				;WORK3 をクリア

; * main loop

AHEXLP:	
	MOV	AL,[BP]
	SUB	AL,'0'
	JC	HEXOUT
	CMP	AL,10
	JAE	HEXOUT
	INC	BP
	XOR	AH,AH
	PUSH	AX
	CALL	MUL10		;WORK3 を 10倍
	POP	AX
	MOV	SI,WORK3
	CALL	ADDAX		;その値を加える
	JMPS	AHEXLP
HEXOUT:	
	POP	DI
	RET	



;WORK3 を 10倍

MUL10:
	MOV	SI,WORK3
	CMP	WORD PTR [SI],0
	JE	MUL10_100

	;WORK3 を 2倍し

	CALL	DOUBLE

	;WORK4 にコピー

	MOV	SI,WORK3
	MOV	CX,[SI]
	INC	CX
	MOV	DI,WORK4
	REP	MOVSW

;WORK3 を更に 4倍し

	CALL	DOUBLE
	CALL	DOUBLE

;WORK3 に WORK4 を加える(WORK3>=WORK4 を利用)

	MOV	SI,WORK3
	MOV	DI,WORK4
	MOV	CX,[DI]
	MOV	DX,[SI]
	SUB	DX,CX
	CLC
MUL10_10:
	WINC	SI
	WINC	DI
	MOV	AX,[DI]
	ADC	[SI],AX
	myloop	MUL10_10
	JNC	MUL10_100
	MOV	AX,1
	MOV	CX,DX
	JCXZ	MUL10_30
MUL10_20:
	WINC	SI
	ADD	[SI],AX
	JNC	MUL10_100
	myloop	MUL10_20
MUL10_30:
	WINC	SI
	MOV	DI,SI		;1 が入る番地
	MOV	SI,WORK3
	JMP	INCLENSYS	;CALL & RET
MUL10_100:
	RET


DOUBLE:	
	MOV	SI,WORK3
	LODSW
	OR	AX,AX
	RETZ
	MOV	CX,AX
	CLC
DOUBLP:	
	RCL	WORD PTR [SI],1
	WINC	SI
	myloop	DOUBLP
	RETNC	

	MOV	DI,SI
	MOV	SI,WORK3
	JMP	INCLENSYS


;WORK3 に AX を加える

	public	addax
ADDAX:
	MOV	SI,WORK3
	MOV	CX,[SI]
	OR	CX,CX
	JNZ	ADDAX10

;WORK3=0 の場合

	OR	AX,AX
	JZ	ADDAX20			;AX も 0 ならばそのまま
	MOV	WORD PTR [SI],1
	MOV	[SI+2],AX
ADDAX20:
	RET

;WORK3>0 の場合

ADDAX10:
	WINC	SI

;一桁目

	ADD	[SI],AX
	JNC	ADDAX20			;NO CARRY
	DEC	CX
	JZ	ADDAX90			;最上位で桁上がり

;二桁目以降

	MOV	AX,1
ADDAX30:
	WINC	SI
	ADD	[SI],AX
	JNC	ADDAX20
	myloop	ADDAX30
ADDAX90:
	MOV	DI,SI
	WINC	DI
	MOV	SI,WORK3
	JMP	INCLENSYS

	
;
;☆CODBUF にある PCODE 列を ASCII 列に戻して INPBUF に置く
;

farDECODE:
	CALL	DECODE
	retf

DECODE:	
	MOV	BP,CODBUF+2	;pointer
	MOV	DI,INPBUF	;pointer

;行番号をアスキー列に

	MOV	BX,[BP]
	ADD	BP,2
	MOV	CH,' '		;non-zero-suples
	CALL	ASCHL

	XOR	CX,CX
	MOV	CL,[BP]
	INC	BP
	CMP	BYTE PTR [BP],0C0H	;code of :
	JNE	DECODEJP
	INC	CX
DECODEJP:
	MOV	AL,' '
	REP	STOSB

	MOV	AL,[BP]
	CMP	AL,NCODE_LABEL
	JNE	ASCILP

;LABEL の表示

	INC	BP
	CALL	DECODE_LABEL
;	MOV	AL,':'
;	STOSB
	jmp	ascilp


;ＤＥＣＯＤＥメイン・ループ
; : をTEXT 中では省略することにしたので複雑になった

ASCILP:	
	MOV	AL,[BP]
	INC	BP
	CMP	AL,CR
	JE	ENDTX2		;if end of text
	call	DecodeToken
	jmp	ascilp


DecodeToken:
	CMP	AL,'.'
	JE	GO_DECODE_POINT	;小数の場合
	CMP	AL,'"'
	JE	DECODE_QUOTE
	CMP	AL,80H
	JAE	CODEIN
	cmp	al,')'
	je	go_varascmember
;ASCI90:
	STOSB
	ret

go_varascmember:
	stosb
	jmp	varascmember

GO_DECODE_POINT:
	jmp	DECODE_POINT	;call & ret

DECODE_QUOTE:
	mov	ah,al
	STOSB
DECODE_QUOTE10:
	MOV	AL,[BP]
	INC	BP
	STOSB
	CMP	AL,ah
	JNE	DECODE_QUOTE10
	ret


VARASC_IN:
	jmp	VARASC		;call & ret

NUMASC_IN:
	jmp	NUMASC		;call & ret


ENDTX2:	
	CMP	BYTE PTR [DI-1],' '
	JNE	ENDTX2_10
	DEC	DI
ENDTX2_10:
	MOV	BYTE PTR [DI],0
	RET	


REMSET:	
	ADD	BP,2		;pass 2 bytes work
	MOV	AL,27H		;code of '
	STOSB
remsetlp:
	MOV	AL,[BP]
	INC	BP
	STOSB
	CMP	AL,CR
	jne	remsetlp
	dec	bp
	dec	di
	ret

LABELASC_IN:
	jmp	DECODE_LABEL	;call & ret


;  CODE TO ASCII

CODEIN:	
	CMP	AL,VCODE
	JB	DECODE10
	CMP	AL,VCODE5
	JBE	VARASC_IN
DECODE10:
	CMP	AL,NCODE
	JB	DECODE20
	CMP	AL,NCODE_ADR
	JBE	NUMASC_IN
	CMP	AL,NCODE_LABEL
	JE	LABELASC_IN
DECODE20:
	CMP	AL,codemark2
	je	decode22
	cmp	al,codemark3	;=b2h
	je	decode27
	jmp	DECODE30

	;case of codemark2(=80h)+?
decode22:
	MOV	AL,[BP]
	INC	BP
	CMP	AL,0B0H
	JAE	DECODE25	;関数の場合
	CMP	AL,99H
	JE	DECODE25
	CMP	AL,9AH
	JE	DECODE25
	CALL	PRESP
DECODE25:
	JMP	DECODE40

	;case of codemark3(=0b2h)+? 
decode27:
	MOV	AL,[BP]
	INC	BP
	CMP	AL,0b8H
	JAE	DECODE29	;関数の場合
	cmp	al,82h		;defseg
	je	decode29
	CALL	PRESP
DECODE29:
	JMP	DECODE50


SEPARC3:
	MOV	AL,'.'
	JMPS	SEPAR10
SEPARC2:
	MOV	AL,','
	JMPS	SEPAR10
SEPARC1:
	MOV	AL,';'
	JMPS	SEPAR10
SEPARC0:	
	MOV	AL,':'
	JMPS	SEPAR10
SEPARD1:
	MOV	AL,'='
SEPAR10:
	CMP	BYTE PTR [DI-1],' '
	JNE	SEPAJP
	DEC	DI
SEPAJP:	
	STOSB
	cmp	al,'.'
	jne	sepajp20
	stosb
sepajp20:
	ret


decodemod:
	cmp	[schoolflg],0
	jne	decodemodmod
	mov	al,'@'
	stosb
	ret
decodemodmod:
	call	presp
	mov	ax,'om'
	stosw
	mov	ax,' d'
	stosw
	ret

DECODE30:
	CMP	AL,9eH		;complex
	JE	DECODE35
	CMP	AL,0A3H		;res
	JE	DECODE35
	CMP	AL,0B3H		;fn
	JE	DECODE35
	CMP	AL,0BBH		;0x
	JE	DECODE35
	CMP	AL,0C3H		;'..'
	JE	SEPARC3
	CMP	AL,0C2H		;','
	JE	SEPARC2
	CMP	AL,0C1H		;';'
	JE	SEPARC1
	CMP	AL,0C0H		;':'
	JE	SEPARC0
	cmp	al,codeofmod
	je	decodemod
	CMP	AL,codeofequal
	JE	SEPARD1
	JA	DECODE35
	CALL	PRESP		;80H~BFH
	CMP	AL,98H		;code of 'REM'
	JE	REMSET

;サーチ開始

DECODE35:
	MOV	BX,OFFSET CMDTBL
	MOV	AH,AL		;PUSH AL
	CALL	DECODE_AH
	MOV	AL,AH		;POP AL
	CMP	AL,0D0H
	ja	decode36
	cmp	al,99h		;print
	je	decode352
	cmp	al,9ah		;lprint
	je	decode352
	cmp	al,0c5h
	jae	decode351
	cmp	al,0c0h
	jae	decode36
	CMP	AL,95H		;return
	JE	decode36
	CMP	AL,0A3H		;res
	JE	decode36
	CMP	AL,0B3H		;fn
	JE	decode36
	CMP	AL,09EH		;#i
	JE	decode36
	cmp	al,0bbh
	je	godecodehexnum	;hex
	cmp	al,0bch		;eval
	je	decode36
decode351:
	cmp	al,0cah		;screen
	je	decode355
	cmp	al,0ach		;locate
	je	decode355
	jmps	decode359
decode352:
	cmp	word ptr [bp],22ddh	;+"
	je	decode36
	jmps	decode359
decode355:
	cmp	byte ptr [bp],0c2h	;,
	jne	decode359
	mov	al,' '
	stosb			;dummy for cutting by ,
decode359:
	mov	al,' '		;post space
	stosb
decode36:
	CMP	AH,8DH		;IF
	JB	CMD110
	CMP	AH,0AFH		;ELSEIF
	JE	CMD120
	CMP	AH,0B6H		;JUMP
	JE	CMD100
	CMP	AH,0B8H		;loop
	JE	CMD100
	CMP	AH,0B9H		;ENDLOOP
	JE	CMD100
	CMP	AH,93H		;UNTIL
	JA	CMD110
	CMP	AH,8EH		;THEN
	JE	CMD110
CMD100:
	ADD	BP,2		;PASS WORK AREA
CMD110:
	ret
CMD120:
	ADD	BP,5		;pass work are for ELSEIF
	ret

godecodehexnum:
	jmp	decodehexnum	;call & ret
		
DECODE40:
	MOV	BX,OFFSET CMDTBL2
	MOV	AH,AL		;PUSH AL
	CALL	DECODE_AH
	cmp	ah,0b0h
	jae	decode42	;function case
	mov	al,' '
	stosb
	cmp	ah,0aeh		;console
	jne	decode42
	cmp	byte ptr [bp],0c2h	;,
	jne	decode42
	stosb			;dummy for cutting by ','
decode42:
	cmp	ah,0e7h		;and{
	je	pass2bandor
	cmp	ah,0e8h		;or{
	je	pass2bandor
	ret
pass2bandor:
	add	bp,2
	ret

decode50:
	MOV	BX,OFFSET CMDTBL3
	MOV	AH,AL		;PUSH AL
	CALL	DECODE_AH
	cmp	ah,0b8h
	jae	decode60	;function case
	cmp	ah,82h		;defseg
	je	decode60
	cmp	ah,088h		;glocate
	je	decode55
	cmp	ah,08ah		;roll
	je	decode55
	jmps	decode59
decode55:
	cmp	byte ptr [bp],0c2h	;,
	jne	decode59
	mov	al,' '
	stosb			;dummy for cutting by ','
decode59:
	mov	al,' '
	stosb
decode60:
	ret


DECODE_AH:
DECAH10:	
	INC	BX
	CMP	AL,[BX]
	JNE	DECAH10

	;文字列の先頭を求む(=一つ前のコマンド・コードまで戻る)

	MOV	CX,-1
DECAH20:	
	INC	CX
	DEC	BX	
	MOV	AL,[BX]
	CMP	AL,80H
	JB	DECAH20

;そこからコマンド名をコピー

DECAH30:	
	INC	BX
	MOV	AL,[BX]
	STOSB
	myloop	DECAH30
	RET


decodehexnum:
	mov	si,bp
	inc	si		;skip 0f2h
	lodsw
	shl	ax,1
	add	si,ax
	mov	bp,si
	or	ax,ax
	jz	decodehex0
	mov	cx,ax
	cmp	byte ptr [si-1],0	;highest byte
	jne	decodehex10
	dec	si
	dec	cx
decodehex10:
	dec	si
	mov	al,[si]
	mov	ah,al
	my_shr	al,4
	cmp	al,10
	jb	decodehex20
	add	al,'a'-'9'-1
decodehex20:
	add	al,'0'
	stosb
	mov	al,ah
	and	al,0fh
	cmp	al,10
	jb	decodehex30
	add	al,'a'-'9'-1
decodehex30:
	add	al,'0'
	stosb
	myloop	decodehex10
	ret

decodehex0:
	mov	al,'0'
	stosb
	ret


;☆変数をアスキー列に

VARASC:
	MOV	DL,AL		;MEMO
	xor	cx,cx
	MOV	cl,[BP]		;# of char
	inc	bp
	cmp	[compilevar_sw],0
	je	varasc5		;if not coded
	mov	si,[bp]
	add	bp,cx
	sub	si,namelen-2
	db	2eh		;cs:
	rep	movsb
	jmp	varasc10
varasc5:
	mov	si,bp
	add	bp,cx
	rep	movsb
VARASC10:
	cmp	byte ptr es:[di-1],0
	jne	varasc12
	dec	di		;cut 0
varasc12:
	SUB	DL,VCODE
	TEST	DL,2		;TEST BIT-1
	JNZ	VARASC20
	CMP	DL,4
	JAE	VARASC15
	MOV	AL,'%'
	STOSB			;短変数
	JMPS	VARASC20
VARASC15:
	MOV	AL,'#'		;特別変数
	STOSB
VARASC20:
	TEST	DL,1		;TEST BIT-0
	JZ	VARASC40
	MOV	AL,'('		;配列
	STOSB
	mov	al,[bp]
	cmp	al,CR
	je	varasc25
	cmp	al,0c0h		;':'
	je	varasc25
	cmp	al,0c2h		;','
	je	varasc25
	cmp	al,')'
	jne	varasc30
	stosb
varascmember:
	mov	al,[bp]
	cmp	al,'.'
	jne	varasc30
	inc	bp		;if a. or a(). case
	stosb
	mov	al,[bp]
	inc	bp
	call	numasc		;call & ret
	jmp	varascmember
varasc25:			;error
	mov	al,')'
	stosb
VARASC30:
	RET

varasc40:
	cmp	byte ptr [bp],'('
	jne	varascmember
	mov	al,' '		;error
	stosb
	jmp	varasc30



;☆TEXT中の小数のASCII変換

DECODE_POINT:
	MOV	AL,[BP]
	INC	BP
	PUSH	DI
	CALL	NUMASC
	MOV	SI,DI
	POP	DI
	MOV	AL,'.'		;DUMMY の 1 を . に変える
	STOSB
	MOV	DI,SI
	RET


;☆数値をアスキー列に

NUMASC:
	CMP	AL,NCODE
	JE	SHORT3
	CMP	AL,NCODE1
	JE	SHORT4
	CMP	AL,NCODE2
	JE	LONG2
	CMP	AL,NCODE_ADR
	JE	TRFLIN

	;0 の場合

SHORT3:
	MOV	AL,'0'
	STOSB
	RET

	;１ワードの場合

SHORT4:
	MOV	BX,[BP]
	WINC	BP
SHORT5:
	MOV	CH,0
	CALL	ASCHL
	RET

	;飛び先が番地になっている場合は行番号に直して表示

TRFLIN:
	MOV	BX,[BP]
	WINC	BP
	MOV	AX,[BX-2]
	MOV	BX,AX
	JMP	SHORT5

	;多ワードの時

LONG2:	
	PUSH	ES
	PUSH	DI

	;WORK3 にコピー

	MOV	SI,BP
	smov	es,ss
	MOV	DI,WORK3
	MOV	CX,[SI]
	AND	CX,LENMASK
	INC	CX
	REP	MOVSW
	MOV	BP,SI

	;ASCII に変換

	CALL	BINASC

	POP	DI
	POP	ES
	PUSH	DS
	MOV	SI,SS
	ADD	SI,ASCBINSEG
	MOV	DS,SI
	MOV	SI,ASCBUFTOP
	MOV	CX,SS:[ASCEND]
	SUB	CX,SI
	REP	MOVSB
	POP	DS
	RET


	;☆ LABEL の表示

DECODE_LABEL:
	CMP	BYTE PTR [BP-2],0B3H	;fn
	JE	DECODE_LABEL10
	MOV	AL,'*'
	STOSB
DECODE_LABEL10:
	XOR	CX,CX
	MOV	CL,[BP]		;文字数
	INC	BP
	JCXZ	DECODE_LABEL_OUT
DECODE_LABELLP:
	MOV	AL,[BP]
	INC	BP
	STOSB
	myloop	DECODE_LABELLP
DECODE_LABEL_OUT:
	ADD	BP,2		;番地の分
	MOV	AL,[BP]
	CMP	AL,CR
	JE	DECODE_LABEL_RET
	CMP	AL,'('
	JE	DECODE_LABEL_RET
	CMP	AL,')'
	JE	DECODE_LABEL_RET
	cmp	al,0C2H
	JE	DECODE_LABEL_RET
	MOV	AL,':'
	STOSB
DECODE_LABEL_RET:
	RET


;*****************
;*               *
;*  subroutines  *
;*               *
;*****************


;☆コマンドの前に見易いようにスペースを置く

PRESP:	
	MOV	AH,AL		;push A
	MOV	AL,[DI-1]
	CMP	AL,' '
	JE	PRESJP
	CMP	AL,3AH		;':'
	JE	PRESJP
	CMP	AL,','
	JE	PRESJP
	CMP	AL,'='
	JE	PRESJP
	MOV	AL,' '
	STOSB
PRESJP:	
	MOV	AL,AH	;pop A
	RET	


;☆BX を ASCII 列に直して [DI]~ に
;INPUT	CH =0 iff DO 0-SUPLES

farASCHL1000:
	call	aschl1000
	retf
ASCHL:	
	MOV	DX,10000
	CALL	DECI
ASCHL1000:
	MOV	DX,1000
	CALL	DECI
	MOV	DX,100
	CALL	DECI
	MOV	DX,10
	CALL	DECI
	MOV	AL,BL
	ADD	AL,'0'
	STOSB
	RET

DECI:	
	XOR	AL,AL
DECILP:	
	INC	AL
	SUB	BX,DX
	JNC	DECILP
	DEC	AL
	ADD	BX,DX
	CMP	CH,'0'
	JE	DECIJ1
	OR	AL,AL
	JNZ	DECIJ0			;first nonzero
	MOV	AL,CH
	OR	AL,AL
	JZ	DECI10
	STOSB
DECI10:
	RET

DECIJ0:	
	MOV	CH,'0'

DECIJ1:	
	ADD	AL,'0'
	STOSB
	RET



	;*
	;*  BINARY TO ASCII
	;*
	;*  WORK3~ のBINARYデータをASCII文字列に
	;*  変換してASCBUF~ に収める
	;*  ASCEND に終端アドレスを置く
	;*  符号は無視する

	;   format of ASCBINBUF
	;   low adr<- C1,...,Ce,endmark ->high adr
	;   adr of endmark is in [ASCEND]

farBINASC:
	call	BINASC
	retf

BINASC:
	PUSH	DS
	PUSH	ES
	PUSH	BP
	PUSH	DI
	MOV	AX,SS
	mov	ds,ax
	ADD	AX,ASCBINSEG
	MOV	ES,AX

	MOV	DI,WORK3
	MOV	CX,[DI]
	TEST	CH,POINTMASKHIGH
	JMPNZ	POINTASCin

	MOV	BX,ASCBUFEND
	MOV	BYTE PTR ES:[BX],0	;END MARK
	DEC	BX
	AND	CX,LENMASK
	JNZ	BINASC10

	; if zero

	MOV	BYTE PTR ES:[BX],'0'
	MOV	[ASCTOP],BX
BINASC100:
	MOV	DI,ASCBUFTOP	;ASCBUF の前へ詰める
	MOV	SI,[ASCTOP]
	MOV	AX,ES
	MOV	DS,AX
	MOV	CX,ASCBUFEND
	SUB	CX,SI
	REP	MOVSB

binascret:
	MOV	BYTE PTR es:[DI],0
	MOV	SS:[ASCEND],DI	

	POP	DI
	POP	BP
	POP	ES
	POP	DS
	RET

	; MAIN LOOP IF NON ZERO

BINASC10:
	PUSH	BX
	MOV	DI,WORK3
	MOV	AX,10000
	CALL	CODE_LWDIV
	MOV	AX,DX		;DX IS AMARI
	pop	bx
	dec	bx
				;call	DWBINASC:
	mov	dl,100
	div	dl
	mov	dx,ax
	mov	al,ah
	aam
	xchg	al,ah
	add	ax,3030h
	mov	es:[bx],ax
	wdec	bx
	mov	ax,dx
	aam
	xchg	al,ah
	add	ax,3030h
	mov	es:[bx],ax
	dec	bx

	MOV	SI,WORK3
	TEST	WORD PTR [SI],LENMASK
	JNZ	BINASC10	;IF 商=0

	; CUT TOP ZEROS

	MOV	AL,'0'
BINASC20:
	INC	BX
	CMP	AL,ES:[BX]
	JE	BINASC20
	MOV	[ASCTOP],BX
	JMP	BINASC100


	;[DI]=[DI]/AX,DX=余り

CODE_LWDIV:
	MOV	BP,AX
	XOR	DX,DX
	MOV	CX,[DI]
	AND	CX,LENMASK
	JZ	CLWDIV20	;[DI] が 0 の時
	ADD	DI,CX
	ADD	DI,CX
	MOV	SI,DI		;SI=DI=最高位ワード
CLWDIV10:
	MOV	AX,[DI]
	DIV	BP
	MOV	[DI],AX
	WDEC	DI
	myloop	CLWDIV10	
	CMP	[SI],CX		;CX=0
	JNE	CLWDIV20

	;最高位が 0 になったので長さを減らす

	DEC	WORD PTR [DI]
CLWDIV20:
	RET


CODE	ENDS

END
