;**************************************************************************************
;**************************************************************************************
;*
;* NAME:
;*      INTERP1D_MULTIY
;*
;* PURPOSE:
;*      THIS FUNCTION IS A CUSTOM 1D LINEAR INTERPOLATION (LOOKUP TABLE) 
;         FOR X, Xq SINGLE RANGE BUT Y WITH MULTIPLE DIMENSIONS (SEVERAL LINES)
;         OUT OF RANGE ON X IS MANAGED
;*
;* CALLING SEQUENCE:
;*      INTERP1D_MULTIY, X, Y, Xq
;*
;* INPUTS:
;*      X = X must be a vector of 2 elements.
;*      Y = the values of the underlying functions Y=F(X), must be a vector of 2 elements 
;            or a matrix of several lines with 2 columns
;*      Xq = a query point in X range
;*
;* KEYWORDS:
;       NONE
;*
;* OUTPUTS:
;*      NONE
;*
;* COMMON BLOCKS:
;*      NONE
;*
;* MODIFICATION HISTORY:
;*
;* VALIDATION HISTORY:
;*      12 MAY 2014 - PML / MAGELLIUM - WINDOWS 64-BIT MACHINE IDL 8.2.3 : COMPILATION, RESULTS AND CALLING SUCCESSFUL
;*      20 JAN 2015 - NCG / MAGELLIUM      - WINDOWS 64BIT MACHINE IDL 8.0: COMPILATION AND OPERATION SUCCESSFUL 
;*      30 MAR 2015 - NCG / MAGELLIUM      - WINDOWS 64BIT MACHINE IDL 8.0: COMPILATION AND OPERATION SUCCESSFUL (DIMITRI V4.0) 
;*
;**************************************************************************************
;**************************************************************************************
FUNCTION INTERP1D_MULTIY,X,Y,Xq

  ; FIRST MANAGE Xq OUT OF RANGE (NO INTERP REQUIRED)
  ; BOTTOM LIMIT
  IF Xq LE X(0) THEN RETURN, Y(*,0)
  ; TOP LIMIT
  IF Xq GE X(1) THEN RETURN, Y(*,1)
  IF X(0) EQ X(1) THEN RETURN, Y(*,0)

  ; LINEAR INTERPOLATION

  ; REQUIREMENTS X = MONOTONIC RANGE
  ; Xq = SINGLE VALUE
  ; Y CAN BE MULTIPLE LINES
  
  DIFF_X = X(1)-X(0)
  DIFF_Xq = Xq - X(0)
  DIFF_Y = Y(*,1)-Y(*,0)
  A = DIFF_Y / DIFF_X
  YS = A * DIFF_Xq + Y(*,0)
  
  RETURN, YS
  
END