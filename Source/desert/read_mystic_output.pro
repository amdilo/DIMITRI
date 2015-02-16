;**************************************************************************************
;**************************************************************************************
;*
;* NAME:
;*      READ_MYSTIC_OUTPUT
;*-------------------------
;* PURPOSE:
;* TO READ THE OUTPUT OF THE MYSTIC SIMULATIONS
;* 
;* -------------------------
;* 
;* CALLING SEQUENCE:
;*      RES =READ_MYSTIC_OUTPUT(FILE-NAME)
;*
;* -------------------------
;* INPUT:
;* - FILENAME: A '.rad.spc' OR A '.rad.std.spc' FILE CONTAINING THE RESULTS OF THE MYSTIC SIMULATION
;*
;* --------------------------------
;* KEYWORDS:
;*      NON
;* 
;* -------------------------
;* EXAMPLE:
;* 
;* -------------------------
;* TROUBLE SHOOTING:
;* 
;*-------------------------
;*
;* OUTPUTS:
;*      SPECTRUM: 2D FLOAT ARRAY
;*
;* COMMON BLOCKS:
;*      NON
;*
;* MODIFICATION HISTORY:
;*        18 NOV 2012  - M BOUVET    - PROTOTYPE OF THE ROUTINE
;*        15 JAN 2015  - B ALHAMMOUD - FIRST IMPLEMENTATION TO DIMITRI-V3.1A
;*
;* VALIDATION HISTORY:
;*        21 JAN 2015 -  B ALHAMMOUD - LINUX 64-BIT MACHINE IDL 8.2, NOMINAL COMPILATION AND OPERATION.
;*                                  TESTED FOR PARASOL OVER LIBYA4
;*
;**************************************************************************************
;**************************************************************************************


FUNCTION READ_MYSTIC_OUTPUT, FILENAME

; OPEN FILE LOGICAL UNIT
GET_LUN, LUN
OPENR, LUN, FILENAME

;DECLARE LINE VARIABLE (READING IS DONE LINE BY LINE)
SPECTRUM=FLTARR(5, 100000)
CPT=0

; TRICK TO AVOID OPENING AN EMPTY FILE WHERE THE RESULTS HAVE NOT BEEN WRITTEN BY UVSPEC YET
WHILE EOF(LUN) DO BEGIN
;  PRINT, 'EMPTY FILE !!! WAITING 1 SECS UNTIL IT IS FULLY WRITTEN...'
  WAIT, 1
ENDWHILE

; START READING THE FILE
WHILE NOT EOF(LUN) DO BEGIN
  ;READ LINE FROM THE OUTPUT FILE
  ON_IOERROR, TROUBLE_READING
  LINE=FLTARR(5)
  READF, LUN, LINE
  SPECTRUM[0,CPT/4]=LINE[0]
  
  SPECTRUM[(CPT MOD 4)+1,CPT/4]=LINE[4]  
  CPT=CPT+1  
  
  GOTO, DONE
  ; TROUBLE READING
  TROUBLE_READING:WAIT, 10 & PRINT, 'I MANAGED TO DEAL WITH THIS ERROR: '+!ERROR_STATE.MSG
  
  DONE:

ENDWHILE
FREE_LUN, LUN

; RETURN THE SPECTRUM
SPECTRUM=SPECTRUM[*, WHERE(SPECTRUM[0,*])]
RETURN, SPECTRUM
END