;**************************************************************************************
;**************************************************************************************
;*
;* NAME:
;*     READ_RAYLEIGH
;* 
;* PURPOSE:
;*      READ RAYLEIGH LUT FROM TEXT FILE AND STORE IN IDL STRUCTURE
;* 
;* CALLING SEQUENCE:
;*      READ_RAYLEIGH(infile)
;* 
;* INPUTS:
;*      infile           - RAYLEIGH LUT IN TEXT FORMAT AS DEFINED IN DIMITRI ATBD
;*
;* KEYWORDS:
;*      VERBOSE          - PROCESSING STATUS OUTPUTS
;*
;* OUTPUTS:
;*      STATUS          - 1: NO ERRORS REPORTED, (-1) OR 0: ERRORS DURING READING 
;*
;* COMMON BLOCKS:
;*      RTM_LUT
;*
;* MODIFICATION HISTORY:
;*        01 NOV 2013 - C MAZERAN - FIRST IMPLEMENTATION
;*
;* VALIDATION HISTORY:
;*        01 NOV 2013 - C MAZERAN - LINUX 64-BIT MACHINE IDL 8.2, NOMINAL COMPILATION AND OPERATION. 
;*
;**************************************************************************************
;**************************************************************************************
FUNCTION READ_RAYLEIGH, infile

 COMMON RTM_LUT

;-----------------------------------------
; DEFINE CURRENT FUNCTION NAME

  FCT_NAME         = 'READ_RAYLEIGH'

;-----------------------------------------
; CHECK INPUT FILE EXISTS

 IF FILE_TEST(infile) NE 1 THEN BEGIN
   PRINT, FCT_NAME,": INPUT FILE NOT EXISTING"
   RETURN, -1
 ENDIF

;-----------------------------------------
; READ LUT

 TAB=READ_ASCII(infile, DATA_START=8, HEADER=HEAD)

 LAMBDA = FLOAT(STRSPLIT((STRSPLIT(HEAD[1],":",/EXTRACT))[1],/EXTRACT))
 SZA    = FLOAT(STRSPLIT((STRSPLIT(HEAD[2],":",/EXTRACT))[1],/EXTRACT))
 VZA    = FLOAT(STRSPLIT((STRSPLIT(HEAD[3],":",/EXTRACT))[1],/EXTRACT))
 RAA    = FLOAT(STRSPLIT((STRSPLIT(HEAD[4],":",/EXTRACT))[1],/EXTRACT))
 WIND   = FLOAT(STRSPLIT((STRSPLIT(HEAD[5],":",/EXTRACT))[1],/EXTRACT))

 DIMS   = FLOAT(STRSPLIT((STRSPLIT(HEAD[7],":",/EXTRACT))[1],/EXTRACT))

 DATA   = REFORM(TAB.field1, REVERSE(DIMS))

 RHOR_LUT = CREATE_STRUCT('WIND', WIND, 'RAA', RAA, 'VZA', VZA, 'SZA', SZA, 'LAMBDA', LAMBDA, 'DATA', DATA)

 RETURN, 1

END
