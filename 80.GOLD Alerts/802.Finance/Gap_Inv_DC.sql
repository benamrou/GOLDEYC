select distinct decode(efatytrt, 0, 'OCR', 'EDI') "Orig flux", 
       pkparpostes.get_postlibl(99, 0, 988, efatydo, 'FR') "Type doc", 
       pkparpostes.get_postlibl(99, 0, 224, efaetat, 'FR') "Etat facture",
       efarfou "Num facture", 
       trunc(efadatf) "Date facture", 
       efamdoc "Montant Doc", 
       efamfac "Montant Facture", 
       efamfac - efamdoc "Ecart a justifier", 
       efacexcde "Num PO", 
       serbliv "Num document", 
       efalink "PDF link"
from cfdenfac c, cfdendoc, stoentre
where efacfin != 781 
and efaetat != 3
and efarfou = edcrfou
and efacfin = edccfin
and edcndoc = sercinrec
order by trunc(efadatf)