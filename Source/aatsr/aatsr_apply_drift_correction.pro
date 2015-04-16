
;FILE: AATSR_APPLY_DRIFT_CORRECTION.PRO
;DESCRIPTION
;     Uses drift correction look up table to obtain the drift measurement for a given channel and acquisition
;     time.
;     WARNING: All previous drift corrections must be removed before using this function. This is performed using
;     the function AATSR_REMOVE_DRIFT_CORRECTION.
;
;ORIGINAL: 16-Jan-2008
;Modification: 11-Mar-2008 - Option included to show error messages
;
;IMPORT: ACQ_TIME - String containing acquistion time of product - format = DD-MMM-YYYY HH:MM:SS
;        ICH - Integer Variable Containing Channel Number to be processed
;               0 = 555nm
;               1 = 659nm
;               2 = 870nm
;               3 = 1600nm
;        REFLECTANCE - Variable containing reflectance reading from L1B product
;        DRIFT_TABLE - If specified, a structure containing the drift look up table
;
;
;EXPORT: CORRECTED - Variable containing reflectance reading with drift correction Applied  If an invalid
;                      channel is specified or the date precedes the launch then an error is reported and -1 is
;                      set as the return value
;
;***************************************************************************************************************
FUNCTION AATSR_APPLY_DRIFT_CORRECTION,ACQ_TIME,ICH,REFLECTANCE,DRIFT_TABLE=DRIFT_TABLE,VERBOSE=VERBOSE

    V56 = 0
    V66 = 1
    V87 = 2
    V16 = 3

    ERROR = -1
    
    IF(ICH GT 3)THEN BEGIN
       IF(KEYWORD_SET(VERBOSE))THEN PRINT,'AATSR_APPLY_DRIFT_CORRECTION - ERROR: CHANNEL OUT OF RANGE - NO CORRECTION APPLIED'
       RETURN,ERROR        ;RETURN ERROR VALUE
    ENDIF

    MONTHSTR = ['JAN','FEB','MAR','APR','MAY','JUN','JUL','AUG','SEP','OCT','NOV','DEC']

    T0 = TIMESTR_TO_JULDAY('01-MAR-2002 00:00:00')    ;ENVISAT LAUNCH DATE - CONVERTED TO JULIAN TIME
    TIME = TIMESTR_TO_JULDAY(ACQ_TIME)                ;IMAGE ACQUISITION TIME - CONVERTED TO JULIAN TIME

    IF(TIME LT T0)THEN BEGIN
       IF(KEYWORD_SET(VERBOSE))THEN PRINT,'AATSR_APPLY_DRIFT_CORRECTION - ERROR: ACQUISITION TIME BEFORE ENVISAT LAUNCH DATE = ',ACQ_TIME
       RETURN,ERROR
    ENDIF

;IF THE TABLE IS NOT PASSED IN THE FUNCTION CALL, READ THE TABLE
    IF((N_ELEMENTS(DRIFT_TABLE) EQ 0) OR (SIZE(DRIFT_TABLE,/TNAME) NE 'STRUCT'))THEN BEGIN
       NTAB = AATSR_READ_DRIFT_TABLE(DRIFT_TABLE)
       IF(NTAB EQ -1)THEN BEGIN
          IF(KEYWORD_SET(VERBOSE))THEN PRINT,'AATSR_APPLY_DRIFT_CORRECTION - ERROR: UNABLE TO READ DRIFT CORRECTION LUT'
          RETURN,-1
       ENDIF
    ENDIF

    IF(TIME LT DRIFT_TABLE.DATE_JUL(0))THEN BEGIN
      IF(KEYWORD_SET(VERBOSE))THEN PRINT,'AATSR_APPLY_DRIFT_CORRECTION - ERROR: ACQUISITION BEFORE START TIME OF TABLE'
      RETURN,-1
    ENDIF


    IF(TIME GT DRIFT_TABLE.DATE_JUL(DRIFT_TABLE.NTAB-1))THEN BEGIN
      IF(KEYWORD_SET(VERBOSE))THEN PRINT,'AATSR_APPLY_DRIFT_CORRECTION - ERROR: ACQUISITION AFTER LAST ENTRY IN TABLE'
      RETURN,-1
    ENDIF

;NOW INTERPOLATE TABLE TO GET DRIFT VALUE
    TAB_DATES = DRIFT_TABLE.DATE_JUL(0:DRIFT_TABLE.NTAB-1)
    CASE(ICH)OF
       0: DRIFT_ARRAY = DRIFT_TABLE.V56_DRIFT(0:DRIFT_TABLE.NTAB-1)
       1: DRIFT_ARRAY = DRIFT_TABLE.V67_DRIFT(0:DRIFT_TABLE.NTAB-1)
       2: DRIFT_ARRAY = DRIFT_TABLE.V87_DRIFT(0:DRIFT_TABLE.NTAB-1)
       3: DRIFT_ARRAY = DRIFT_TABLE.V16_DRIFT(0:DRIFT_TABLE.NTAB-1)
    ENDCASE
    DRIFT = INTERPOL(DRIFT_ARRAY,TAB_DATES,TIME)

;NOW MULTIPLY REFLECTANCE BY DRIFT TO GET UNCORRECTED VALUE
       CORRECTED = REFLECTANCE/DRIFT

;AND WE ARE DONE
RETURN,CORRECTED
END