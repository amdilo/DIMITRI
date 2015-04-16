 FUNCTION INTERP2D, A, X0, Y0, X1, Y1, NXNY, EXTRAPOLATE=EXTRAPOLATE,TRIGRID=TRIGRID,_EXTRA=EXTRA
; NAME:
;   INTERP2D
; PURPOSE:
;   PERFORM BILINEAR 2D INTERPOLATION USING THE IDL INTRINSIC 
;   INTERPOLATE PROCEDURE
; CALLING SEQUENCE:
;   RESULT = INTERP2D(A,X0,Y0,X1,Y1)
;   RESULT = INTERP2D(A,X0,Y0,X1,Y1,/GRID)
;   RESULT = INTERP2D(A,X0,Y0,X1,Y1,/REGULAR,/CUBIC)
;   RESULT = INTERP2D(A,X0,Y0,X1,Y1,MISSING=MISSING)
; INPUTS:
;   A = 2D ARRAY TO INTERPOLATE
;   X0  = VALUES THAT CORRESPOND TO A(0,0), A(1,0), ...
;   Y0  = VALUES THAT CORRESPOND TO A(0,0), A(0,1), ...
;   X1  = NEW X VALUES AT WHICH A SHOULD BE INTERPOLATED
;   Y1  = NEW Y VALUES AT WHICH A SHOULD BE INTERPOLATED
; OPTIONAL INPUTS:
;   NXNY = [NX,NY] VECTOR OF LENGTH 2 WHICH SPECIFIES THE SIZE OF
;         THE REGULAR LINEARIZED GRID PRODUCED WITH TRIGRID.  THE
;         DEFAULT IS NXNY = [51,51].  IF THE SIZE OF A IS MUCH LARGER
;   THAN 51 BY 51, GREATER ACCURACY MAY BE OBTAINED BY HAVING
;         NXNY = [N_ELEMENTS(A(*,0),N_ELEMENTS(A(0,*))]
; OPTIONAL INPUT KEYWORDS:
;   GRID= IF SET, RETURN AN N_ELEMENTS(X1) BY N_ELEMENTS(Y1) GRID
;   MISSING = VALUE TO POINTS WHICH HAVE X1 GT MAX(X0) OR X1 LT MIN(X0)
;   AND THE SAME FOR Y1.
;   QUINTIC = IF SET, USE SMOOTH INTERPOLATION IN CALL TO TRIGRID
;   REGULAR = IF SET, DO NOT CALL TRIGRID -- X0 AND Y0 MUST BE LINEAR.
;   CUBIC   = IF SET, USE CUBIC CONVOLUTION
;   EXTRAPOLATE = IF SET, THEN EXTRAPOLATE BEYOND BOUNDARY POINTS
;   BIN = SET TO BIN DATA PRIOR TO INTERPOLATION.
;         (E.G. BIN=2 INTERPOLATE EVERY SECOND PIXEL)
; RETURNED:
;   RESULT = A VECTOR N_ELEMENTS(X1) LONG 
;      OR, IF /GRID IS SET
;   RESULT = AN ARRAY THAT IS N_ELEMENTS(X1) BY N_ELEMENTS(Y1)
;
; PROCEDURE:
;   FIRST CALL THE IDL INTRINSIC ROUTINES TRIANGULATE & TRIGRID TO MAKE
; SURE THAT X0 AND Y0 ARE LINEAR (IF /REGULAR IS NOT SET).
;   THEN CALL THE IDL INTRINSIC INTERPOLATE TO DO BILINEAR INTERPOLATION.
; RESTRICTIONS:
;   X0 AND Y0 MUST BE LINEAR FUNCTIONS.
;   A MUST BE A 2-D ARRAY
; HISTORY:
;    9-MAR-94, J. R. LEMEN LPARL, WRITTEN.
;   20-JAN-95, JRL, ADDED THE REGULAR & CUBIC KEYWORDS
;   6-SEPT-97, ZARRO, GSFC, ALLOWED FOR 2-D (X-Y) COORDINATE INPUTS
;  22-APRI-99, ZARRO, SM&A/GSFC - ADDED /TRIGRID AND MADE /REGULAR
;              THE DEFAULT (MUCH FASTER).
;  14-APR-2001, JMM, JIMM@SSL.BERKELEY.EDU, FIXED BUG FOR TRIANGULATE
;               OPTION, CHANGED REFORM STATEMENTS TO REBIN, /SAMPLE
;  20-MAY-2004, ZARRO (L-3COM/GSFC) - MADE /REGULAR THE DEFAULT (AGAIN)
;  10-JAN-2005, ZARRO (L-3COM/GSFC) - CHANGED () TO []
;  22-OCT-2011, ZARRO (ADNET)- USED _EXTRA TO PASS SPECIAL KEYWORDS AND
;                              OPTIMIZED MEMORY.
;*      20 JAN 2015 - NCG / MAGELLIUM      - WINDOWS 64BIT MACHINE IDL 8.0: COMPILATION AND OPERATION SUCCESSFUL 
;*      30 MAR 2015 - NCG / MAGELLIUM      - WINDOWS 64BIT MACHINE IDL 8.0: COMPILATION AND OPERATION SUCCESSFUL (DIMITRI V4.0) 
;-

;-- CHECK FOR SELF-CONSISTENT INPUT DIMENSIONS

SZ = SIZE(A)

IF SZ[0] NE 2 THEN BEGIN
  MESSAGE,'INPUT DATA ARRAY MUST BE 2-D',/CONT
  RETURN,-1
ENDIF

SX=SIZE(X0) & SY=SIZE(Y0)

TWOD=0
CASE 1 OF
 SX[0] EQ 1: BEGIN
  NX=SX[1] & NY=SY[1]
 END
 SX[0] EQ 2: BEGIN
  TWOD=1
  NX=SX[1] & NY=SX[2]
 END
 ELSE: BEGIN
  MESSAGE,'INPUT X-Y COORDINATE ARRAYS MUST 1- OR 2-D',/CONT
  RETURN,-1
 END
ENDCASE
 
IF (SZ[1] NE NX) OR (SZ[2] NE NY) THEN BEGIN
 MESSAGE,'DIMENSIONS OF DATA, X0, Y0 ARE NOT CONSISTENT',/CONT
 RETURN,-1
ENDIF

;-- CALL TRIANGULATE AND TRIGRID TO GET A REGULARLY SPACED GRID

IF KEYWORD_SET(TRIGRID) THEN BEGIN
  IF N_ELEMENTS(NXNY) EQ 0 THEN NXNY = [NX,NY]

  GS = [(MAX(X0)-MIN(X0))/(NXNY[0]-1), (MAX(Y0)-MIN(Y0))/(NXNY[1]-1)]

  IF ~TWOD THEN BEGIN
     X0 = REBIN(TEMPORARY(X0), NX, NY, /SAMPLE)
     Y0 = TRANSPOSE(REBIN(TEMPORARY(Y0), NX, NY, /SAMPLE))
  ENDIF 

  TRIANGULATE, X0, Y0, TR,BOUND

  IF KEYWORD_SET(EXTRAPOLATE) THEN BEGIN
   ZZ = TRIGRID(X0,Y0, A, TR, GS,_EXTRA=EXTRA,$
                EXTRAPOLATE=BOUND)
  ENDIF ELSE BEGIN
   ZZ = TRIGRID(X0,Y0, A, TR, GS,_EXTRA=EXTRA)
  ENDELSE

  IF ~TWOD THEN BEGIN
   X0=REFORM(TEMPORARY(X0),NX*NY)
   Y0=REFORM(TRANSPOSE(TEMPORARY(Y0)),NX*NY)
  ENDIF

  ZZ = TEMPORARY(ZZ[0:NXNY[0]-1,0:NXNY[1]-1]) ; MAKE SURE THE DIMENSIONS ARE MATCHED
  SZ = SIZE(ZZ)
ENDIF ELSE BEGIN
  
  SZ=SIZE(A)
  ZZ=A
  
ENDELSE

XSLOPE = (MAX(X0)-MIN(X0)) / (SZ[1]-1)
YSLOPE = (MAX(Y0)-MIN(Y0)) / (SZ[2]-1)

; MAP THE COORDINATES

X2 = (X1 - MIN(X0)) / XSLOPE
Y2 = (Y1 - MIN(Y0)) / YSLOPE

; NOW INTERPOLATE
IF N_ELEMENTS(GRID)    EQ 0 THEN GRID = 0
IF N_ELEMENTS(CUBIC)   EQ 0 THEN CUBIC= 0
IF N_ELEMENTS(MISSING) EQ 0 THEN BEGIN
    ZOUT = INTERPOLATE(ZZ,X2,Y2,GRID=GRID,CUBIC=CUBIC,_EXTRA=EXTRA)
ENDIF ELSE BEGIN
    ZOUT = INTERPOLATE(ZZ,X2,Y2,GRID=GRID,MISSING=MISSING,CUBIC=CUBIC,_EXTRA=EXTRA)
END

RETURN, ZOUT

END

