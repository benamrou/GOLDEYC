-- Missing deliverable assortment event
SELECT cclsitd "Store",  pkartrac.Get_Artcexr(1, cclcinrc) "Item code", pkstrucobj.get_desc(1,cclcinrc,'GB') "Item Desc", cclerr "Error Message"
FROM ccldetccl 
WHERE cclstatus =-2
ORDER BY 3 ASC
