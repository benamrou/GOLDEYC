with LAST_REPN as (
select max(tmc_FR_REPN) max_repn from TMC_FILEREPORT
where TMC_FR_INTERFACE = 'WMS'
    and TMC_FR_MODE = 'receive'
    and trunc(sysdate) = TMC_FR_REPDATE
)
select  
TMC_FR_INTERFACE      "Interface" ,
TMC_FR_MODE           "Mode" ,
to_char(TMC_FR_STORE)          "Store" ,
to_char(TMC_FR_REPDATE, 'DD/MM/RR')        "Day" ,
TMC_FR_FILES_I        "No Pending Files" ,
TMC_FR_FILES_P        "No Process Files" ,
TMC_FR_FILES_B        "No Backup Files" ,
TMC_FR_FILES_E        "No Error Files" ,
TMC_FR_STATUS         "Server Status"
from TMC_FILEREPORT tr , LAST_REPN
where LAST_REPN.max_repn = TR.TMC_FR_REPN
union
select  
''      "Interface" ,
''           "Mode" ,
''          "Store" ,
'TOTAL'        "Day" ,
sum(TMC_FR_FILES_I)        "No Pending Files" ,
sum(TMC_FR_FILES_P)        "No Process Files" ,
sum(TMC_FR_FILES_B)        "No Backup Files" ,
sum(TMC_FR_FILES_E)        "No Error Files" ,
''         "Server Status"
from TMC_FILEREPORT tr , LAST_REPN
where LAST_REPN.max_repn = TR.TMC_FR_REPN
ORDER BY 3 ASC
