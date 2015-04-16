;**************************************************************************************
;**************************************************************************************
;*
;* NAME:
;*      UV_2_WS_WD       
;* 
;* PURPOSE:
;*      CONVERTS WIND VECTORS (U,V) TO WIND SPEED and WIND DIRECTION (DEG from NORTH) VECTORS
;* 
;* CALLING SEQUENCE:
;*      RES = UV_2_WS_WD(U, V)      
;* 
;* INPUTS:
;*      U , V -  WIND VECTORS.      
;*
;* KEYWORDS:
;*
;* OUTPUTS:
;*      WIND STRUCTURE (WIND SPEED, WIND DIRECTION)	
;*
;* COMMON BLOCKS:
;*      NONE
;*
;* MODIFICATION HISTORY:
;*      26 JAN 2015 - NCG / MAGELLIUM    - CREATION
;*
;* VALIDATION HISTORY:
;*      30 MAR 2015 - NCG / MAGELLIUM      - WINDOWS 64BIT MACHINE IDL 8.0: COMPILATION AND OPERATION SUCCESSFUL (DIMITRI V4.0) 
;*
;**************************************************************************************
;**************************************************************************************

FUNCTION UV_2_WS_WD, U, V

DATA_SIZE=SIZE(U)

IF DATA_SIZE[0] EQ 0 THEN BEGIN
  WIND_SPEED=0
  WIND_DIRECTION=0
ENDIF ELSE BEGIN 
  IF DATA_SIZE[0] EQ 1 THEN BEGIN
    WIND_SPEED=DBLARR(DATA_SIZE(1))
    WIND_DIRECTION=DBLARR(DATA_SIZE(1))
  ENDIF ELSE BEGIN
    IF DATA_SIZE[0] EQ 2 THEN BEGIN
      WIND_SPEED=DBLARR(DATA_SIZE(1),DATA_SIZE(2))
      WIND_DIRECTION=DBLARR(DATA_SIZE(1),DATA_SIZE(2))
    ENDIF 
  ENDELSE   
ENDELSE

; FIND NAN VALUES
INDX_VALID = WHERE( (U NE !VALUES.F_NAN) AND (V NE !VALUES.F_NAN), COMPLEMENT=INDX_NOT_VALID,  NCOMPLEMENT=COUNT_NOT_VALID, COUNT_VALID )
IF COUNT_NOT_VALID GT 0 THEN BEGIN
  WIND_SPEED(INDX_NOT_VALID) = !VALUES.F_NAN
  WIND_DIRECTION(INDX_NOT_VALID) = !VALUES.F_NAN
ENDIF

; TREAT VALID VALUES
WIND_SPEED(INDX_VALID) = SQRT( U(INDX_VALID)*U(INDX_VALID) + V(INDX_VALID)*V(INDX_VALID) )
; DEG from NORTH 
WIND_DIRECTION(INDX_VALID) = 270 - (180/!PI)*ATAN(V(INDX_VALID),U(INDX_VALID))

INDX_SUP = WHERE( (WIND_DIRECTION GT 360) AND (WIND_DIRECTION NE !VALUES.F_NAN), COUNT_SUP)
IF COUNT_SUP GT 0 THEN   WIND_DIRECTION(INDX_SUP) = WIND_DIRECTION(INDX_SUP)-360

RETURN, { WIND_SPEED : WIND_SPEED, WIND_DIRECTION : WIND_DIRECTION }
  
END
