select ooscexops "OS number", oosdleng  "Store start commitment date" 
from opros s where oosetat>=4 and oostype=3 and not exists (select 1 from oprartsitd d where d.osdnops = s.oosnops)