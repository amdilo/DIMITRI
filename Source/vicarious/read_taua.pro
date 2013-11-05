;**************************************************************************************
;**************************************************************************************
;*
;* NAME:
;*     READ_TAUA
;* 
;* PURPOSE:
;*      READ TAU AEROSOL LUT FROM TEXT FILE AND STORE IN IDL STRUCTURE
;* 
;* CALLING SEQUENCE:
;*      READ_TAUA(infile)
;* 
;* INPUTS:
;*      infile           - TAUA LUT IN TEXT FORMAT AS DEFINED IN DIMITRI ATBD
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
FUNCTION READ_TAUA, infile

 COMMON RTM_LUT

;-----------------------------------------
; DEFINE CURRENT FUNCTION NAME

  FCT_NAME         = 'READ_TAUA'

;-----------------------------------------
; CHECK INPUT FILE EXISTS

 IF FILE_TEST(infile) NE 1 THEN BEGIN
   PRINT, FCT_NAME,": INPUT FILE NOT EXISTING"
   RETURN, -1
 ENDIF

;-----------------------------------------
; READ LUT

 TAB=READ_ASCII(infile, DATA_START=5, HEADER=HEAD)

 lambda = FLOAT(STRSPLIT((STRSPLIT(HEAD[4],":",/EXTRACT))[1],/EXTRACT))

 data = REFORM(TAB.field1, 7, N_ELEMENTS(lambda))

 TAUA_LUT = CREATE_STRUCT('lambda', lambda, 'DATA', data)

 RETURN, 1
END
