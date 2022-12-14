;nonint.asm

include	ubdef.h
include	ub.h
include \ubv9\multi.h

data	segment	public
	public	fixedflag

	extrn	arrayseg:word,limitseg:word
	extrn	calcsp:word

	extrn	dimem_m:word,simem_m:word,dilen_m:word,silen_m:word
	extrn	divword:word,anslen:word,divlen:word,attrib:word
	extrn	ptrnow:word,ptrnow2:word,sftbit:word
	extrn	calcsp_limit:word
	extrn	xmem:word,ymem:word,pmem:word
	extrn	usingsw:byte,using_frac_part:word,using_int_part:word

dimem_div	dw	?
simem_div	dw	?

dimem_cadd	dw	?
simem_cadd	dw	?

dimem_cmul	dw	?
simem_cmul	dw	?

fixedflag	db	0

data	ends

code	segment	public
	extrn	ahedsp:near,backsp:near
	extrn	formul:near,kakko:near
	extrn	farformul:far,farkakko:far
	extrn	mulIIdisi:near,idivIIdisi:near

	extrn	addIIdisi:near
	extrn	addAAdisi:near,subAAdisi:near
	extrn	mulAAdisi:near
	extrn	mulin:near,powerin:near
	extrn	lwadd:near,lwsub:near
	extrn	parnumsub:near
	extrn	ishiftright_di:near,shiftleft_di:near

	extrn	xchgsidi:near
	extrn	farxchgsidi:far

	extrn	faradd_calcsp:far,farsub_calcsp:far
	extrn	farmul_calcsp:far
	extrn	faridiv_calcsp:far,farres_calcsp:far
	extrn	farpower_calcsp:far

	extrn	synerr:near,ilgerr:near,ovrerr:near,calcsperr:near
	extrn	diverr:near,systemerr:near


code	ends

include \ubv9\rational.asm
include \ubv9\float.asm
include \ubv9\complex.asm
include \ubv9\polynomi.asm
include \ubv9\ratfunc.asm
