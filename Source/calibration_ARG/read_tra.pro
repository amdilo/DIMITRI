;**************************************************************************************
;**************************************************************************************
;*
;* NAME:
;*     READ_TRA
;* 
;* PURPOSE:
;*      READ DOWNWARD AND UPWARD TRANSMITTANCE LUTS FROM TEXT FILES AND STORE IN IDL STRUCTURE
;* 
;* CALLING SEQUENCE:
;*      READ_TRA(infile_down, infile_up)
;* 
;* INPUTS:
;*      infile_dow          - TDOWN LUT IN TEXT FORMAT AS DEFINED IN DIMITRI ATBD
;*      infile_up           - TDOWN LUT IN TEXT FORMAT AS DEFINED IN DIMITRI ATBD
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
FUNCTION READ_TRA, INFILE_DOWN, INFILE_UP

 COMMON RTM_LUT

;-----------------------------------------
; DEFINE CURRENT FUNCTION NAME

  FCT_NAME         = 'READ_TRA'

;-----------------------------------------
; CHECK INPUT FILE EXISTS

 IF FILE_TEST(infile_down) NE 1 OR FILE_TEST(infile_up) NE 1 THEN BEGIN
   PRINT, FCT_NAME,": INPUT FILE NOT EXISTING"
   RETURN, -1
 ENDIF

;-----------------------------------------
 ; READ AND STORE DOWNWARD TRANSMITTANCE
 TAB = READ_ASCII(infile_down, DATA_START=7, HEADER=HEAD)

 LAMBDA = FLOAT(STRSPLIT((STRSPLIT(HEAD[3],":",/EXTRACT))[1],/EXTRACT))
 SZA    = FLOAT(STRSPLIT((STRSPLIT(HEAD[4],":",/EXTRACT))[1],/EXTRACT))

 DIMS   = FLOAT(STRSPLIT((STRSPLIT(HEAD[6],":",/EXTRACT))[1],/EXTRACT))

 DATA   = REFORM(TAB.field1, REVERSE(DIMS))
 DATA   = TRANSPOSE(DATA,[1,0,2])
 TRA_DOWN_LUT = CREATE_STRUCT('SZA', SZA, 'LAMBDA', LAMBDA, 'DATA', DATA)

;-----------------------------------------
 ; READ AND STORE UPWARD TRANSMITTANCE
 TAB = READ_ASCII(infile_up, DATA_START=7, HEADER=HEAD)

 LAMBDA = FLOAT(STRSPLIT((STRSPLIT(HEAD[3],":",/EXTRACT))[1],/EXTRACT))
 VZA    = FLOAT(STRSPLIT((STRSPLIT(HEAD[4],":",/EXTRACT))[1],/EXTRACT))

 DIMS   = FLOAT(STRSPLIT((STRSPLIT(HEAD[6],":",/EXTRACT))[1],/EXTRACT))

 DATA = REFORM(TAB.field1, REVERSE(DIMS))
 DATA = TRANSPOSE(DATA,[1,0,2])
 TRA_UP_LUT = CREATE_STRUCT('VZA', VZA, 'LAMBDA', LAMBDA, 'DATA', DATA)

 RETURN, 1
END
