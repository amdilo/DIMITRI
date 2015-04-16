;**************************************************************************************
;**************************************************************************************
;*
;* NAME:
;*      FILTER_XSIGMA
;*
;* PURPOSE:
;*      UTIL TO FILTER NAN VALUES AND OUTLIERS AT XTIMES THE STANDARD DEVIATION
;*      MOREOVER A DATA VECTOR INCLUDING BASIC STATISTICAL VALUES IS AVAILABLE
;*
;* CALLING SEQUENCE:
;*      OUTPUT=FILTER_XSIGMA(INPUT, XTIME_SIGMA=XTIME_SIGMA, INDX_FILTER_IN=INDX_FILTER_IN, INDX_FILTER_OUT=INDX_FILTER_OUT, STAT_VECTOR=STAT_VECTOR
;*
;* INPUTS:
;*      INPUT = THE ORIGINAL INPUT VECTOR
;*
;* KEYWORDS:
;*      XTIME_SIGMA = GAIN ON SIGMA (STANDARD DEVIATION) TO FILTER OUT THE OUTLIERS, IF NOT DEFINED THEN = 3
;*      INDX_FILTER_IN = INDEX OF PIXEL KEPT AFTER FILTERING
;*      INDX_FILTER_OUT = INDEX OF PIXEL REMOVED AFTER FILTERING
;* 		STAT_VECTOR = BASIC STATISTICAL VALUES [ N_ELEMENTS INPUT, N_ELEMENTS OUTPUT, MEAN OUTPUT, ...
;* 		                                            ... STDDEV OUTPUT, MEDIAN OUTPUT, MIN OUTPUT, MAX OUTPUT ]
;* OUTPUTS:
;*      RES = CHANNEL VALUES
;*
;* COMMON BLOCKS:
;*      NONE
;*
;* MODIFICATION HISTORY:
;*      29 NOV 2013 - PML / MAGELLIUM - CREATION
;*
;* VALIDATION HISTORY:
;*      17 APR 2014 - PML / MAGELLIUM - WINDOWS 64-BIT MACHINE IDL 8.2.3 : COMPILATION AND CALLING SUCCESSFUL
;*      20 JAN 2015 - NCG / MAGELLIUM      - WINDOWS 64BIT MACHINE IDL 8.0: COMPILATION AND OPERATION SUCCESSFUL 
;*      30 MAR 2015 - NCG / MAGELLIUM      - WINDOWS 64BIT MACHINE IDL 8.0: COMPILATION AND OPERATION SUCCESSFUL (DIMITRI V4.0) 
;*
;**************************************************************************************
;**************************************************************************************


FUNCTION FILTER_XSIGMA, INPUT, XTIME_SIGMA=XTIME_SIGMA, INDX_FILTER_IN=INDX_FILTER_IN, INDX_FILTER_OUT=INDX_FILTER_OUT, STAT_VECTOR=STAT_VECTOR

  IF KEYWORD_SET(XTIME_SIGMA) EQ 0 THEN XTIME_SIGMA = 3 ; DEFAULT IS 3*SIGMA
  
  ; 1- FILTER OUT NAN VALUES
  IDX_NONAN=WHERE(FINITE(INPUT,/NAN) EQ 0,COUNT_NONAN)
  IF COUNT_NONAN NE N_ELEMENTS(INPUT) THEN BEGIN
    INPUT=INPUT(IDX_NONAN)
  ENDIF

  STD_IN=STDDEV(INPUT)
  RES_IN=INPUT-MEAN(INPUT)
  THRESH_IN=XTIME_SIGMA*STD_IN
  ; 2 - FILTER OUT OUT OF XTIMES SIGMA VALUES
  INDX_FILTER_IN = WHERE( RES_IN LT THRESH_IN AND RES_IN GT -THRESH_IN, COUNT_IN, NCOMPLEMENT=COUNT_OUT, COMPLEMENT=INDX_FILTER_OUT)
  IF COUNT_IN GT 0 THEN BEGIN
      OUTPUT=INPUT(INDX_FILTER_IN)
      ; ADD STAT VALUES : PIX_NB_IN/PIX_NB_OUT/MEAN_OUT/STD_OUT/MEDIAN_OUT/MIN_OUT/MAX_OUT
      STAT_VECTOR=[ N_ELEMENTS(INPUT), N_ELEMENTS(OUTPUT), MEAN(OUTPUT), STDDEV(OUTPUT), MEDIAN(OUTPUT), MIN(OUTPUT), MAX(OUTPUT) ]
      
  ENDIF ELSE BEGIN
      OUTPUT=!VALUES.F_NAN
      STAT_VECTOR=[ N_ELEMENTS(INPUT), !VALUES.F_NAN, !VALUES.F_NAN, !VALUES.F_NAN, !VALUES.F_NAN, !VALUES.F_NAN, !VALUES.F_NAN ]      
  ENDELSE
  
  
  RETURN, OUTPUT

END