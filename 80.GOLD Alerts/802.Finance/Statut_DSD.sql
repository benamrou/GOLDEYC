--Rejet GOLD
select 'EDI NON PO' "Type facture", cfisite "Code site", cficfex "Code fournisseur", cficcex "Code contrat", cfiinvid "Num facture", cfimfac "Montant facture", cficexcde "Num commande", cfidate "Date facture", decode(cfinerr, 839, 
                                                                                                                                                                                              decode(cfimfac, 0, 
                                                                                                                                                                                                    'No document to be reconciliated has been found - Checker Montant facture = 0', 
                                                                                                                                                                                                     decode(cfitype, 1, 'No document to be reconciliated has been found - Checker si BL en double', 
                                                                                                                                                                                                            'No document to be reconciliated has been found - Creer la demande d avoir')), 
                                                                                                                                                                                12225, 'Checker les factures en doubles', 
                                                                                                                                                                                12244, 'Checker le liens de reglement du fournisseur', 
                                                                                                                                                                                12254, 'Probleme de mapping - '||cfimess, 
                                                                                                                                                                                94522, 'Probleme de mapping - '||cfimess, cfimess)"Action"
                                                                                                                                                               , decode(decode(cfinerr, 839, decode(cfimfac, 0, 1,decode(cfitype, 1, 3, 1)),
                                                                                                                                                                                12225, 1, 
                                                                                                                                                                                12244, 1, 
                                                                                                                                                                                12254, 2, 
                                                                                                                                                                                94522, 2), 1, 'TOMCO', 2, 'SAP', 'EYC')"Qui",
                                                                                                                                                                                CFILINK "Invoice Link"
--select c.*
from intcfinv c
where cficfex != 'TC' 
and cfistat = 2
and exists (select 1 from intcfart where cfainvid = cfiinvid and cfacfex = cficfex)
and not exists (select 1 from cdeentcde where ecdcexcde = cficexcde)
and exists (select 1 from intcfbl where cfbinvid = cfiinvid and cfbsite != 9000)
UNION
select 'EDI PO' "Type facture", cfisite, cficfex, cficcex, cfiinvid, cfimfac "Montant facture", cficexcde, cfidate, decode(cfinerr, 839, 
                                                                                                decode(cfimfac, 0, 
                                                                                                      'No document to be reconciliated has been found - Checker Montant facture = 0', 
                                                                                                       decode(cfitype, 1, 'No document to be reconciliated has been found - Checker si BL en double', 
                                                                                                              'No document to be reconciliated has been found - Creer la demande d avoir')), 
                                                                                                                                                                                12225, 'Checker les factures en doubles', 
                                                                                                                                                                                12244, 'Checker le liens de reglement du fournisseur', 
                                                                                                                                                                                12254, 'Probleme de mapping - '||cfimess, 
                                                                                                                                                                                94522, 'Probleme de mapping - '||cfimess, cfimess)"Action"
                                                                                                                                                               , decode(decode(cfinerr, 839, decode(cfimfac, 0, 1,decode(cfitype, 1, 3, 1)),
                                                                                                                                                                                12225, 1, 
                                                                                                                                                                                12244, 1, 
                                                                                                                                                                                12254, 2, 
                                                                                                                                                                                94522, 2), 1, 'TOMCO', 2, 'SAP', 'EYC')"Qui",
                                                                                                                                                                                CFILINK "Invoice Link"   
--select *
from intcfinv c
where cficfex != 'TC' 
and cfistat = 2
and exists (select 1 from intcfart where cfainvid = cfiinvid and cfacfex = cficfex)
and exists (select 1 from cdeentcde where ecdcexcde = cficexcde)
and exists (select 1 from intcfbl where cfbinvid = cfiinvid and cfbsite != 9000)
UNION
select 'OCR NON PO' "Type facture", cfisite "Code site", cficfex "Code fournisseur", cficcex "Code contrat", cfiinvid "Num facture", cfimfac "Montant facture", cficexcde "Num commande", cfidate "Date facture", decode(cfinerr, 839, 
                                                                                                                                                                                              decode(cfimfac, 0, 
                                                                                                                                                                                                    'No document to be reconciliated has been found - Checker Montant facture = 0', 
                                                                                                                                                                                                     decode(cfitype, 1, 'No document to be reconciliated has been found - Checker si BL en double', 
                                                                                                                                                                                                            'No document to be reconciliated has been found - Creer la demande d avoir')),
                                                                                                                                                                                12225, 'Checker les factures en doubles', 
                                                                                                                                                                                12244, 'Checker le liens de reglement du fournisseur', 
                                                                                                                                                                                12254, 'Probleme de mapping - '||cfimess, 
                                                                                                                                                                                94522, 'Probleme de mapping - '||cfimess, cfimess)"Action"
                                                                                                                                                               , decode(decode(cfinerr, 839, decode(cfimfac, 0, 1,decode(cfitype, 1, 3, 1)),
                                                                                                                                                                                12225, 1, 
                                                                                                                                                                                12244, 1, 
                                                                                                                                                                                12254, 2, 
                                                                                                                                                                                94522, 2), 1, 'TOMCO', 2, 'SAP', 'EYC')"Qui",
                                                                                                                                                                                CFILINK "Invoice Link"
--select *
from intcfinv c
where cficfex != 'TC' 
and cfistat = 2
and not exists (select 1 from intcfart where cfainvid = cfiinvid and cfacfex = cficfex)
and not exists (select 1 from cdeentcde where ecdcexcde = cficexcde)
and exists (select 1 from intcfbl where cfbinvid = cfiinvid and cfbsite != 9000)
UNION
select 'OCR PO' "Type facture", cfisite "Code site", cficfex "Code fournisseur", cficcex "Code contrat", cfiinvid "Num facture", cfimfac "Montant facture", cficexcde "Num commande", cfidate "Date facture", decode(cfinerr, 839, 
                                                                                                                                                                                              decode(cfimfac, 0, 
                                                                                                                                                                                                    'No document to be reconciliated has been found - Checker Montant facture = 0', 
                                                                                                                                                                                                     decode(cfitype, 1, 'No document to be reconciliated has been found - Checker si BL en double', 
                                                                                                                                                                                                            'No document to be reconciliated has been found - Creer la demande d avoir')),
                                                                                                                                                                                12225, 'Checker les factures en doubles', 
                                                                                                                                                                                12244, 'Checker le liens de reglement du fournisseur', 
                                                                                                                                                                                12254, 'Probleme de mapping - '||cfimess, 
                                                                                                                                                                                94522, 'Probleme de mapping - '||cfimess, cfimess)"Action"
                                                                                                                                                               , decode(decode(cfinerr, 839, decode(cfimfac, 0, 1,decode(cfitype, 1, 3, 1)),
                                                                                                                                                                                12225, 1, 
                                                                                                                                                                                12244, 1, 
                                                                                                                                                                                12254, 2, 
                                                                                                                                                                                94522, 2), 1, 'TOMCO', 2, 'SAP', 'EYC')"Qui",
                                                                                                                                                                                CFILINK "Invoice Link"
from intcfinv c
where cficfex != 'TC' 
and cfistat = 2
and not exists (select 1 from intcfart where cfainvid = cfiinvid and cfacfex = cficfex)
and exists (select 1 from cdeentcde where ecdcexcde = cficexcde)
and exists (select 1 from intcfbl where cfbinvid = cfiinvid and cfbsite != 9000)
order by 1, 2 desc