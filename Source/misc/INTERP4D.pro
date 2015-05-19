;**************************************************************************************
;**************************************************************************************
;*
;* NAME:
;*      INTERP4D
;*
;* PURPOSE:
;*      FUNCTION TO PERFORM OPTIMIZED 4D INTERPOLATION THROUGH A 4-D LOOK-UP TABLE (DIRECT DATA RANGE RESTRICTION METHOD)
;*
;* CALLING SEQUENCE:
;*      OUT_VAL = INTERP4D(OUT_LUT, $
;*                         DIM1, DIM2, DIM3, DIM4, DIM5, $
;*                         DIM1_BKPT_VALUES, DIM2_BKPT_VALUES, DIM3_BKPT_VALUES, DIM4_BKPT_VALUES, $
;*                         INVERSE_Z=INVERSE_Z) 
;*
;* INPUTS:
;*      OUT_LUT              : OUTPUT DIMENSION OF THE 4-D LOOK-UP TABLE
;*      DIM1                 : INPUT 1ST DIMENSION DATA VALUES
;*      DIM2                 : INPUT 2ND DIMENSION DATA VALUES
;*      DIM3                 : INPUT 3RD DIMENSION DATA VALUES
;*      DIM4                 : INPUT 4TH DIMENSION DATA VALUES
;*      DIM1_BKPT_VALUES     : LUT_4D 1ST DIMENSION BREAKPOINT VALUES
;*      DIM2_BKPT_VALUES     : LUT_4D 2ND DIMENSION BREAKPOINT VALUES
;*      DIM3_BKPT_VALUES     : LUT_4D 3RD DIMENSION BREAKPOINT VALUES
;*      DIM4_BKPT_VALUES     : LUT_4D 4TH DIMENSION BREAKPOINT VALUES
;*
;* KEYWORDS:
;*      INVERSE_Z        : INVERT OUTPUT DIMENSION AND LAST INPUT DIMENSION TO INVERT LOOK-UP TABLE RESULT
;*                          USED FOR LOOK-UP TABLE INVERSION
;*
;* OUTPUTS:
;*      OUT_VAL = INTERPOLATED VALUES
;*
;* COMMON BLOCKS:
;*      NONE
;*
;* MODIFICATION HISTORY:
;*       12 MAY 2014 - PML / MAGELLIUM      - CREATION
;*        7 MAY 2015 - NCG / MAGELLIUM      - CODE OPTIMISATION WITH USE OF NINTERPOLATE FUNCTION DEVELOPPED BY J.D. SMITH 
;*
;* VALIDATION HISTORY:
;*       11 MAY 2015 - NCG / MAGELLIUM      - WINDOWS 64BIT MACHINE IDL 8.0: COMPILATION AND OPERATION SUCCESSFUL 
;*
;**************************************************************************************
;**************************************************************************************

FUNCTION INTERP4D, OUT_LUT, $
                    DIM1, DIM2, DIM3, DIM4, $
                    DIM1_BKPT_VALUES, DIM2_BKPT_VALUES, DIM3_BKPT_VALUES, DIM4_BKPT_VALUES, INVERSE_Z=INVERSE_Z

  MISSING_VALUE = FLOAT(GET_DIMITRI_LOCATION('NCDF_MISSING_VALUE'))
  
  NB_VAL = N_ELEMENTS(DIM1)
  OUT_VAL = MAKE_ARRAY(NB_VAL, /FLOAT, VALUE=MISSING_VALUE)  
  
  NB_DIM1_BKPT = N_ELEMENTS(DIM1_BKPT_VALUES)
  NB_DIM2_BKPT = N_ELEMENTS(DIM2_BKPT_VALUES)
  NB_DIM3_BKPT = N_ELEMENTS(DIM3_BKPT_VALUES)
  NB_DIM4_BKPT = N_ELEMENTS(DIM4_BKPT_VALUES)
  
  LUT = REFORM(OUT_LUT, NB_DIM4_BKPT, NB_DIM3_BKPT, NB_DIM2_BKPT, NB_DIM1_BKPT)

  IF NOT KEYWORD_SET(INVERSE_Z) THEN BEGIN

    IDX_VALID = WHERE( DIM1 GE DIM1_BKPT_VALUES[0] AND DIM1 LE DIM1_BKPT_VALUES[NB_DIM1_BKPT-1] $
                       AND DIM2 GE DIM2_BKPT_VALUES[0] AND DIM2 LE DIM2_BKPT_VALUES[NB_DIM2_BKPT-1] $
                       AND DIM3 GE DIM3_BKPT_VALUES[0] AND DIM3 LE DIM3_BKPT_VALUES[NB_DIM3_BKPT-1] $
                       AND DIM4 GE DIM4_BKPT_VALUES[0] AND DIM4 LE DIM4_BKPT_VALUES[NB_DIM4_BKPT-1] , NB_VALID, NCOMPLEMENT=NB_INVALID )
    
    IF NB_INVALID NE 0 THEN BEGIN
      PRINT, 'INTERP4D_OPTI - WARNING : POINTS OUTSIDE THE LIMITS OF THE LUT TABLES, NO INTERPOLATION COMPUTED, POINTS SETTED TO INVALID'
    ENDIF
    
    ; LOOP OVER SAMPLE
    FOR I=0L,NB_VALID-1 DO BEGIN
      
       INC = IDX_VALID(I)
       
       DIM1_IDX_INF = VALUE_LOCATE(DIM1_BKPT_VALUES, DIM1(INC))
       IF DIM1_IDX_INF EQ NB_DIM1_BKPT-1 $
            THEN DIM1_IDX = DIM1_IDX_INF $
            ELSE DIM1_IDX = DIM1_IDX_INF + ( DIM1(INC) - DIM1_BKPT_VALUES(DIM1_IDX_INF) ) / ( DIM1_BKPT_VALUES(DIM1_IDX_INF+1) - DIM1_BKPT_VALUES(DIM1_IDX_INF))
       
       DIM2_IDX_INF = VALUE_LOCATE(DIM2_BKPT_VALUES, DIM2(INC))
       IF DIM2_IDX_INF EQ NB_DIM2_BKPT-1 $
            THEN DIM2_IDX = DIM2_IDX_INF $
            ELSE DIM2_IDX = DIM2_IDX_INF + ( DIM2(INC) - DIM2_BKPT_VALUES(DIM2_IDX_INF) ) / ( DIM2_BKPT_VALUES(DIM2_IDX_INF+1) - DIM2_BKPT_VALUES(DIM2_IDX_INF))
       
       DIM3_IDX_INF = VALUE_LOCATE(DIM3_BKPT_VALUES, DIM3(INC))
       IF DIM3_IDX_INF EQ NB_DIM3_BKPT-1 $
            THEN DIM3_IDX = DIM3_IDX_INF $
            ELSE DIM3_IDX = DIM3_IDX_INF + ( DIM3(INC) - DIM3_BKPT_VALUES(DIM3_IDX_INF) ) / ( DIM3_BKPT_VALUES(DIM3_IDX_INF+1) - DIM3_BKPT_VALUES(DIM3_IDX_INF))
       
       DIM4_IDX_INF = VALUE_LOCATE(DIM4_BKPT_VALUES, DIM4(INC))
       IF DIM4_IDX_INF EQ NB_DIM4_BKPT-1 $
            THEN DIM4_IDX = DIM4_IDX_INF $
            ELSE DIM4_IDX = DIM4_IDX_INF + ( DIM4(INC) - DIM4_BKPT_VALUES(DIM4_IDX_INF) ) / ( DIM4_BKPT_VALUES(DIM4_IDX_INF+1) - DIM4_BKPT_VALUES(DIM4_IDX_INF))
  
       OUT_VAL(INC) = NINTERPOLATE(LUT,[DIM4_IDX,DIM3_IDX,DIM2_IDX,DIM1_IDX])
      
    ENDFOR

  ENDIF ELSE BEGIN
  
    IDX_VALID = WHERE( DIM1 GE DIM1_BKPT_VALUES[0] AND DIM1 LE DIM1_BKPT_VALUES[NB_DIM1_BKPT-1] $
                       AND DIM2 GE DIM2_BKPT_VALUES[0] AND DIM2 LE DIM2_BKPT_VALUES[NB_DIM2_BKPT-1] $
                       AND DIM3 GE DIM3_BKPT_VALUES[0] AND DIM3 LE DIM3_BKPT_VALUES[NB_DIM3_BKPT-1] , NB_VALID, NCOMPLEMENT=NB_INVALID )
    
    IF NB_INVALID NE 0 THEN BEGIN
      PRINT, 'INTERP4D_OPTI - WARNING : POINTS OUTSIDE THE LIMITS OF THE LUT TABLES, NO INTERPOLATION COMPUTED, POINTS SETTED TO INVALID'
    ENDIF
       
    ; LOOP OVER SAMPLE
    DIMOUT_VALUES = FLTARR(NB_DIM4_BKPT)
    FOR I=0L,NB_VALID-1 DO BEGIN
      
       INC = IDX_VALID(I)
       
       DIM1_IDX_INF = VALUE_LOCATE(DIM1_BKPT_VALUES, DIM1(INC))
       IF DIM1_IDX_INF EQ NB_DIM1_BKPT-1 $
            THEN DIM1_IDX = DIM1_IDX_INF $
            ELSE DIM1_IDX = DIM1_IDX_INF + ( DIM1(INC) - DIM1_BKPT_VALUES(DIM1_IDX_INF) ) / ( DIM1_BKPT_VALUES(DIM1_IDX_INF+1) - DIM1_BKPT_VALUES(DIM1_IDX_INF))
       
       DIM2_IDX_INF = VALUE_LOCATE(DIM2_BKPT_VALUES, DIM2(INC))
       IF DIM2_IDX_INF EQ NB_DIM2_BKPT-1 $
            THEN DIM2_IDX = DIM2_IDX_INF $
            ELSE DIM2_IDX = DIM2_IDX_INF + ( DIM2(INC) - DIM2_BKPT_VALUES(DIM2_IDX_INF) ) / ( DIM2_BKPT_VALUES(DIM2_IDX_INF+1) - DIM2_BKPT_VALUES(DIM2_IDX_INF))
       
       DIM3_IDX_INF = VALUE_LOCATE(DIM3_BKPT_VALUES, DIM3(INC))
       IF DIM3_IDX_INF EQ NB_DIM3_BKPT-1 $
            THEN DIM3_IDX = DIM3_IDX_INF $
            ELSE DIM3_IDX = DIM3_IDX_INF + ( DIM3(INC) - DIM3_BKPT_VALUES(DIM3_IDX_INF) ) / ( DIM3_BKPT_VALUES(DIM3_IDX_INF+1) - DIM3_BKPT_VALUES(DIM3_IDX_INF))
       
      ; LOOP ON DIM4 BKPT VALUES FOR ESTIMATION OF LUT OUTPUT VALUES
       FOR BKPT=0, NB_DIM4_BKPT-1 DO BEGIN 
         DIMOUT_VALUES[BKPT] = NINTERPOLATE(LUT,[BKPT,DIM3_IDX,DIM2_IDX,DIM1_IDX])
       ENDFOR
       
       ; 1D INTERPOLATION ACROSS DIM4 BKPT VALUES FOR ESTIMATION OF DIM4 SEARCHED VALUE   
       OUT_VAL(INC) = INTERP1D(DIMOUT_VALUES, DIM4_BKPT_VALUES, DIM4(INC))
           
    ENDFOR
  
  ENDELSE
  
  RETURN, OUT_VAL
 
END