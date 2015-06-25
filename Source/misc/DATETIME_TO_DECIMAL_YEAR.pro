;**************************************************************************************
;**************************************************************************************
;*
;* NAME:
;*      DATETIME_TO_DECIMAL_YEAR       
;* 
;* PURPOSE:
;*      RETURNS THE DECIMAL YEAR CORRESPONDING TO THE INPUT DATE
;* 
;* CALLING SEQUENCE:
;*      DECIMAL_YEAR = TIMESTR_TO_DECIMAL_YEAR(TIMESTR)      
;* 
;* INPUTS:
;*      YYYY  - YEAR
;*      MMM   - MONTH
;*      DD    - DAY
;*      HH    - HOURS
;*      MM    - MINUTES
;*      SS    - SECONDS
;*
;* KEYWORDS:
;*      VERBOSE   - PROCESSING STATUS OUTPUTS
;*
;* OUTPUTS:
;*      DECIMAL_YEAR - A DOUBLE OF THE DECIMAL YEAR
;*
;* COMMON BLOCKS:
;*      NONE
;*
;* MODIFICATION HISTORY:
;*      15 JUN 2015 - NCG / MAGELLIUM   - CREATION (DIMITRI V4) 
;*
;* VALIDATION HISTORY:
;*      15 JUN 2015 - NCG / MAGELLIUM  - WINDOWS 32-BIT IDL 7.1 NOMINAL
;*                               COMPILATION AND OPERATION 
;*
;**************************************************************************************
;**************************************************************************************

FUNCTION DATETIME_TO_DECIMAL_YEAR, YYYY, MMM, DD, HH, MM, SS, VERBOSE=VERBOSE

  FCT_NAME = 'DATETIME_TO_DECIMAL_YEAR'
  
  IF KEYWORD_SET(VERBOSE) THEN PRINT,FCT_NAME + ': CONVERT DATE TO DECIMAL YEAR'

  YEAR  = DOUBLE(YYYY)
  MONTH = DOUBLE(MMM)
  DAY   = DOUBLE(DD)

  HR  = DOUBLE(HH)
  MIN = DOUBLE(MM)
  SEC = DOUBLE(SS)

  IF YEAR MOD 4 EQ 0 THEN DIY = DOUBLE(366.0) $
                     ELSE DIY = DOUBLE(365.0)

  ; NUMBER OF DAYS SINCE 1ST JANUARY OF THE YEAR (TAKEN INTO ACCOUNT THE TIME OF THE DAY!)
  JJUL_TIME_INTERVAL = JULDAY(MONTH,DAY,YEAR,HR,MIN,SEC)-JULDAY(1,1,YEAR,0,0,0)
  
  DECIMAL_YEAR = YEAR + JJUL_TIME_INTERVAL/DIY
;print, DECIMAL_YEAR, FORMAT='(D15.9)'


; TEMPORARY CODE TO REMOVE AFTER HARMONIZATION OF THE DIMITRI CODE WITH THE USE OF THIS FUNCTION
;-----------------------------
;  TTIME = DOUBLE((HR/(DIY*24.))+(MIN/(DIY*60.*24.))+SEC/(DIY*60.*60.*24.))
;  JJUL_TIME_INTERVAL = JULDAY(MONTH,DAY,YEAR)-JULDAY(1,0,YEAR)  
;  DECIMAL_YEAR = YEAR + JJUL_TIME_INTERVAL/DIY + TTIME
;print, DECIMAL_YEAR, FORMAT='(D15.9)'
;-----------------------------


  RETURN, DECIMAL_YEAR

END