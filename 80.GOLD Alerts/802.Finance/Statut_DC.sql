--Rejet GOLD
select 'EDI NON PO' "Type facture", 
cfisite "Code site", 
cficfex "Code fournisseur", 
cficcex "Code contrat",
foulibl "Nom fournisseur",
cfiinvid "Num facture", 
cficexcde "Num commande", 
cfidate "Date facture", 
cfimfac "Montant",
decode(cfinerr, 839, 'Reception ou retour fournisseur n existe pas ou commande non soldee', 
                                      12225, 'Checker les factures en doubles', 
                                      12244, 'Checker le liens de reglement du fournisseur', 
                                      12254, 'Probleme de mapping - '||cfimess, 
                                      94522, 'Probleme de mapping - '||cfimess, cfimess)"Action"
                                      , decode(decode(cfinerr, 839, 1, 
                                          12225, 1, 
                                          12244, 1, 
                                          12254, 2, 
                                          94522, 2), 1, 'TOMCO', 'SAP')"Qui", 
cfilink "PDF link"
--select c.*
from intcfinv c, foudgene
where cficfex != 'TC' 
and cfistat = 2
and cficfex = foucnuf
and exists (select 1 from intcfart where cfainvid = cfiinvid and cfacfex = cficfex)
and not exists (select 1 from cdeentcde where ecdcexcde = cficexcde)
and exists (select 1 from intcfbl where cfbinvid = cfiinvid and cfbsite = 9000)
UNION
select 'EDI PO' "Type facture", 
cfisite "Code site", 
cficfex "Code fournisseur", 
cficcex "Code contrat",
foulibl "Nom fournisseur",
cfiinvid "Num facture", 
cficexcde "Num commande", 
cfidate "Date facture", 
cfimfac "Montant",
       decode(cfinerr, 839, 'Reception ou retour fournisseur n existe pas ou commande non soldee', 
                  12225, 'Checker les factures en doubles', 
                  12244, 'Checker le liens de reglement du fournisseur', 
                  12254, 'Probleme de mapping - '||cfimess, 
                  94522, 'Probleme de mapping - '||cfimess, cfimess)"Action"
                  , decode(decode(cfinerr, 839, 1, 
                        12225, 1, 
                        12244, 1, 
                        12254, 2, 
                        94522, 2), 1, 'TOMCO', 'SAP')"Qui", 
cfilink "PDF link"    
--select *
from intcfinv c, foudgene
where cficfex != 'TC' 
and cfistat = 2
and cficfex = foucnuf
and exists (select 1 from intcfart where cfainvid = cfiinvid and cfacfex = cficfex)
and exists (select 1 from cdeentcde where ecdcexcde = cficexcde)
and exists (select 1 from intcfbl where cfbinvid = cfiinvid and cfbsite = 9000)
UNION
select 'OCR NON PO' "Type facture", 
       cfisite "Code site", 
       cficfex "Code fournisseur", 
       cficcex "Code contrat", 
       foulibl "Nom fournisseur",
       cfiinvid "Num facture", 
       cficexcde "Num commande", 
       cfidate "Date facture", 
       cfimfac "Montant",
       decode(cfinerr, 839, 'Reception ou retour fournisseur n existe pas ou commande non soldee', 
                    12225, 'Checker les factures en doubles', 
                    12244, 'Checker le liens de reglement du fournisseur', 
                    12254, 'Probleme de mapping - '||cfimess, 
                    94522, 'Probleme de mapping - '||cfimess, cfimess)"Action"
                           , decode(decode(cfinerr, 839, 1, 
                              12225, 1, 
                              12244, 1, 
                              12254, 2, 
                              94522, 2), 1, 'TOMCO', 'SAP')"Qui", 
cfilink "PDF link"              
--select *
from intcfinv c, foudgene
where cficfex != 'TC' 
and cfistat = 2
and cficfex = foucnuf
and not exists (select 1 from intcfart where cfainvid = cfiinvid and cfacfex = cficfex)
and not exists (select 1 from cdeentcde where ecdcexcde = cficexcde)
and exists (select 1 from intcfbl where cfbinvid = cfiinvid and cfbsite = 9000)
UNION
select 'OCR PO' "Type facture", 
       cfisite "Code site", 
       cficfex "Code fournisseur", 
       cficcex "Code contrat", 
       foulibl "Nom fournisseur",
       cfiinvid "Num facture", 
       cficexcde "Num commande", 
       cfidate "Date facture", 
       cfimfac "Montant",
       decode(cfinerr, 839, 'Reception ou retour fournisseur n existe pas ou commande non soldee', 
                  12225, 'Checker les factures en doubles', 
                  12244, 'Checker le liens de reglement du fournisseur', 
                  12254, 'Probleme de mapping - '||cfimess, 
                  94522, 'Probleme de mapping - '||cfimess, cfimess)"Action"
                  , decode(decode(cfinerr, 839, 1, 
                        12225, 1, 
                        12244, 1, 
                        12254, 2, 
                        94522, 2), 1, 'TOMCO', 'SAP')"Qui", 
cfilink "PDF link"    
from intcfinv c, foudgene
where cficfex != 'TC' 
and cfistat = 2
and cficfex = foucnuf
and not exists (select 1 from intcfart where cfainvid = cfiinvid and cfacfex = cficfex)
and exists (select 1 from cdeentcde where ecdcexcde = cficexcde)
and exists (select 1 from intcfbl where cfbinvid = cfiinvid and cfbsite = 9000)
order by 1, 2 desc