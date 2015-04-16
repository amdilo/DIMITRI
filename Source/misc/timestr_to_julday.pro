;FILE:  TIMESTR_TO_JULDAY.PRO
;FUNCTION: Converts timestring with format 'DD-MMM-YYYY HH:MM:SS' to julian day
;MODDIFICATION: 18-JAN-2008 - Updated to work on arrays of timestrings
;
;******************************************************************************************************
FUNCTION TIMESTR_TO_JULDAY,TIMESTR

    MONTHS = ['JAN','FEB','MAR','APR','MAY','JUN','JUL','AUG','SEP','OCT','NOV','DEC']

    NP = N_ELEMENTS(TIMESTR)

    IF(NP GT 1)THEN $
       JDAY = DBLARR(NP) $
    ELSE $
       JDAY = 0.0D

    FOR I = 0, NP-1 DO BEGIN
       DAY = FIX(STRMID(TIMESTR(I),0,2))
       MON = STRUPCASE(STRMID(TIMESTR(I),3,3))
       YEAR = FIX(STRMID(TIMESTR(I),7,4))
       HRS = FIX(STRMID(TIMESTR(I),12,2))
       MINS = FIX(STRMID(TIMESTR(I),15,2))
       SECS = FIX(STRMID(TIMESTR(I),18,2))
       JDAY(I) = JULDAY(WHERE(MONTHS EQ MON)+1,DAY,YEAR,HRS,MINS,SECS)
    ENDFOR

    RETURN,JDAY

END