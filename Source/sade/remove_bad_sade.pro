;**************************************************************************************
;**************************************************************************************
;*
;* NAME:
;*      REMOVE_BAD_SADE       
;* 
;* PURPOSE:
;*      REMOVES THE ERRONEOUS DATA FROM THE SADE SENSOR FILES AND REMOVES QUICKLOOKS
;* 
;* CALLING SEQUENCE:
;*      RES =  REMOVE_BAD_SADE(SITE,SENSOR,PROC_VER,PRODFILE)    
;* 
;* INPUTS:
;*      SITE      - THE SITE NAME
;*      SENSOR    - THE SENSOR
;*      PROC_VER  - THE SENSORS PROCESSING VERSION
;*      PRODFILE  - THE FULL PATH OF THE PRODUCT FILE       
;*
;* KEYWORDS:
;*
;* OUTPUTS:
;*      A CLEANED SADE FILE
;*
;* COMMON BLOCKS:
;*      NONE
;*
;* MODIFICATION HISTORY:
;*      16 DEC 2011 - C KENT  - INITIAL DIMITRI VERSION
;*
;* VALIDATION HISTORY:
;*
;**************************************************************************************
;**************************************************************************************

PRO REMOVE_BAD_SADE,SITE,SENSOR,PROC_VER,PRODFILE

  IFOL = '/mnt/Projects/MEREMSII/WG_Reference_Dataset_2/'
  DL = PATH_SEP()
  OUPUTFILE = IFOL+SITE+DL+SITE+'_'+SENSOR+'_'+PROC_VER+'_cleaned.SADE'

  CASE SENSOR OF
    'AATSR'       : NBANDS=7 
    'MERIS'       : NBANDS=15 
    'MODISA'      : NBANDS=10 
    'PARASOL'     : NBANDS=9 
    'VEGETATION'  : NBANDS=4 
  ENDCASE

; READ IN SADE TXT

  SADEFILE = IFOL+SITE+DL+SITE+'_'+SENSOR+'_'+PROC_VER+'.SADE'
  SADEDATA = READ_SADE_TXT(SADEFILE,SENSOR)

; READ IN PRODFILE

  PRODDATA = READ_SADE_PRODFILE_TEXT(PRODFILE)

; CREATE AN ARRAY OF NUMBER ELEMENTS OF SADE TEXT

  BADINDX = MAKE_ARRAY(N_ELEMENTS(SADEDATA.JPG),/INTEGER,VALUE=0)

; LOOP OVER EACH PRODFILE PRODUCT

  FOR II=0,N_ELEMENTS(PRODDATA.BADPROD)-1 DO BEGIN
  
; FIND WHICH SADETEXT JPGS MATCH, SET THESE INDEICESES TO 1
    
    RES = WHERE(SADEDATA.JPG EQ PRODDATA.BADPROD[II],COUNT)
    IF COUNT GT 0 THEN BEGIN
    BADINDX[RES] = 1
    FOR JJ=0,COUNT-1 DO BEGIN
      IF FILE_TEST(IFOL+SITE+DL+SENSOR+DL+SADEDATA.JPG[RES[JJ]]) THEN FILE_DELETE,IFOL+SITE+DL+SENSOR+DL+SADEDATA.JPG[RES[JJ]]
      ENDFOR
    ENDIF
  
  ENDFOR

; PRINT OUT SADE DATA FROM INDICES OF 0 AND NOT JPG FILE INFO
  
  OPENW,OUTF,OUPUTFILE,/GET_LUN
  FOR KK=0,N_ELEMENTS(SADEDATA.JPG)-1 DO BEGIN
    IF BADINDX[KK] THEN CONTINUE
    FOR IVAL = 0,3 DO BEGIN
      TEMP = 0.0
      FOR IBAND=0,NBANDS-1 DO TEMP = [TEMP,SADEDATA.(4+IBAND+IVAL*NBANDS)[KK]]
      TEMP = TEMP[1:NBANDS]
      CASE IVAL OF
        0 : TOA_REF = TEMP 
        1 : TOA_STD = TEMP
        2 : VZA = TEMP
        3 : VAA = TEMP
      ENDCASE
    ENDFOR
    IF TOA_REF[0] GT 1.0 THEN CONTINUE
    
    PRINTF,OUTF,STRING(SENSOR+'_'+PROC_VER),SADEDATA.ACQDATE[KK],SADEDATA.PROCDATE[KK],SITE,TOA_REF,TOA_STD,$
          VZA,VAA,SADEDATA.NPIXS[KK],SADEDATA.LAT[KK],SADEDATA.LON[KK],SADEDATA.SZA[KK],SADEDATA.SAA[KK],SADEDATA.WVAP[KK],SADEDATA.OZONE[KK],SADEDATA.PRESS[KK],SADEDATA.WIND[KK],$
          FORMAT = '(4(A,1H ),'+STRTRIM(FIX(4*NBANDS),2)+'(F11.6,1H ),1(I10,1H ),2(F10.3,1H ),5(F12.6,1H ),1(F12.6))'
  ENDFOR
  FREE_LUN,OUTF
  PRINT, 'FINISHED...'
END