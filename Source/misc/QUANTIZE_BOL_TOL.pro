;**************************************************************************************
;**************************************************************************************
;*
;* NAME:
;*      QUANTIZE_BOL_TOL
;*
;* PURPOSE:
;*      THIS FUNCTION DETERMINATES INTERPOLATION NEEDS AND UPPER/LOWER INTERPOLATION BREAKPOINTS
;*        
;*
;* CALLING SEQUENCE:
;*      DOINTERP = QUANTIZE_BOL_TOL(INPUT, BREAKPOINTS, VAL_BOL=VAL_BOL, VAL_TOL=VAL_TOL)
;*
;* INPUTS:
;*      INPUT = VALUES TO ANALYZE PSOTION REGARDING BREAKPOINTS
;*      BREAKPOINTS = THE BREAKPOINT VALUES FOR INTERPOLATION (BASICALLY X VALUES), MUST BE UNIQUE AND STRICTLY MONOTONIC
;*      VAL_BOL AND VAL_TOL ARE USED AS OUTPUT VALUES (SEE DEFINITION BELOW)
;*
;* KEYWORDS:
;       NONE
;*
;* OUTPUTS:
;*      DOINTERP  = (=0 IF OUT OF RANGE TOL OR BOL OR ON ONE BREAKPOINT) (=1 OTHERWISE, LINEAR INTERPOLATION REQUIRED)
;*      VAL_BOL   = BREAKPOINT BOTTOM LIMIT VALUES FOR EACH INPUT VALUE
;*      VAL_TOP   = BREAKPOINT TOP LIMIT VALUES FOR EACH INPUT VALUE
;*
;* COMMON BLOCKS:
;*      NONE
;*
;* MODIFICATION HISTORY:
;*      12 MAY 2014 - PML / MAGELLIUM - CREATION
;* VALIDATION HISTORY:
;*      12 MAY 2014 - PML / MAGELLIUM - WINDOWS 64-BIT MACHINE IDL 8.2.3 : COMPILATION, RESULTS AND CALLING SUCCESSFUL
;*      20 JAN 2015 - NCG / MAGELLIUM      - WINDOWS 64BIT MACHINE IDL 8.0: COMPILATION AND OPERATION SUCCESSFUL 
;*      30 MAR 2015 - NCG / MAGELLIUM      - WINDOWS 64BIT MACHINE IDL 8.0: COMPILATION AND OPERATION SUCCESSFUL (DIMITRI V4.0) 
;*
;**************************************************************************************
;**************************************************************************************

FUNCTION ISMEMBER, X, Y

  X_MEMB = MAKE_ARRAY(N_ELEMENTS(X),/LONG)
  FOR INDX = 0, N_ELEMENTS(Y)-1 DO BEGIN
    X_MEMB = X_MEMB + (X EQ Y(INDX));
  END
  X_OUT = MAKE_ARRAY(N_ELEMENTS(X),/LONG)
  INDX_NZ=WHERE(X_MEMB NE 0,COUNT_NZ)
  IF COUNT_NZ NE 0 THEN X_OUT(INDX_NZ)=1
  
  RETURN, X_OUT
  
END

FUNCTION QUANTIZE_BOL_TOL, INPUT, BREAKPOINTS, VAL_BOL=VAL_BOL, VAL_TOL=VAL_TOL

  ; DOINTERP = QUANTIZE_BOL_TOL(INPUT, BREAKPOINTS, VAL_BOL=VAL_BOL, VAL_TOL=VAL_TOL)
  
  ; COMPUTE INDX
  INDX_BOL = MAKE_ARRAY(N_ELEMENTS(INPUT),/LONG,VALUE=-1)
  ONBREAKPOINT = MAKE_ARRAY(N_ELEMENTS(BREAKPOINTS),/LONG)
  INDX_BOL = INDX_BOL + (INPUT GT BREAKPOINTS(0));
  FOR INDX = 1, N_ELEMENTS(BREAKPOINTS)-1 DO BEGIN
    INDX_BOL = INDX_BOL + (INPUT GE BREAKPOINTS(INDX));
  END
  
  ; ONBREAKPOINT VALID INSIDE BREAKPOINTS RANGE
  ONBREAKPOINT = ISMEMBER(INPUT,BREAKPOINTS)
  OUTOFRANGE=MAKE_ARRAY(N_ELEMENTS(INPUT),/LONG);
  
  INDX_ZERO=WHERE(INDX_BOL EQ -1,COUNT_ZERO)
  IF COUNT_ZERO NE 0 THEN BEGIN
    ONBREAKPOINT(INDX_ZERO)=1
    OUTOFRANGE(INDX_ZERO)=1
    INDX_BOL(INDX_ZERO)=0
  ENDIF
  
  INDX_TOP=WHERE(INDX_BOL EQ N_ELEMENTS(BREAKPOINTS)-1,COUNT_TOP)
  IF COUNT_TOP NE 0 THEN BEGIN
    ONBREAKPOINT(INDX_TOP)=1
    OUTOFRANGE(INDX_TOP)=1
    INDX_BOL(INDX_TOP)=N_ELEMENTS(BREAKPOINTS)-1
  ENDIF
  
  INDX_TOL = INDX_BOL;
  INDX_INC = WHERE(OUTOFRANGE EQ 0 AND ONBREAKPOINT EQ 0, COUNT_INC);
  IF COUNT_INC NE 0 THEN BEGIN
    INDX_TOL(INDX_INC) = INDX_TOL(INDX_INC)+1
  ENDIF
  
  VAL_BOL = BREAKPOINTS(INDX_BOL);
  VAL_TOL = BREAKPOINTS(INDX_TOL);
  
  TOINTERP = MAKE_ARRAY(N_ELEMENTS(INPUT),/LONG);
  INDX_DIFF = WHERE(INDX_BOL NE INDX_TOL, COUNT_DIFF);
  IF COUNT_DIFF NE 0 THEN BEGIN
    TOINTERP(INDX_DIFF) = 1
  ENDIF
  
  RETURN, TOINTERP
  
END