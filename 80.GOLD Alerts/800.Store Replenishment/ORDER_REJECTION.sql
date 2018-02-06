SELECT DISTINCT 'Yesterday' "Recap", to_char(intsite) "Store Id", soclmag "Store Desc", 
       intcnuf "Supplier id", foulibl "Supplier desc", intcode "Item",  to_char(intstat) "Flag", to_char(intnerr) "Erreur Id", intmess "Erreur desc"
FROM intcde, sitdgene, foudgene 
WHERE socsite=intsite AND intcnuf=foucnuf(+) AND trunc(intdcre)=TRUNC(current_date-1) AND intstat=2
UNION
SELECT 'Recap. since 7 days', '2. Detail',
      (SELECT to_char(COUNT(DISTINCT intcode)) FROM intcde WHERE trunc(intdcre)=TRUNC(current_date-1) AND intstat=2),
      (SELECT to_char(COUNT(DISTINCT intcode)) FROM intcde WHERE trunc(intdcre)=TRUNC(current_date-2) AND intstat=2),
      (SELECT to_char(COUNT(DISTINCT intcode)) FROM intcde WHERE trunc(intdcre)=TRUNC(current_date-3) AND intstat=2),
      (SELECT to_char(COUNT(DISTINCT intcode)) FROM intcde WHERE trunc(intdcre)=TRUNC(current_date-4) AND intstat=2),
      (SELECT to_char(COUNT(DISTINCT intcode)) FROM intcde WHERE trunc(intdcre)=TRUNC(current_date-5) AND intstat=2),
      (SELECT to_char(COUNT(DISTINCT intcode)) FROM intcde WHERE trunc(intdcre)=TRUNC(current_date-6) AND intstat=2),
      (SELECT to_char(COUNT(DISTINCT intcode)) FROM intcde WHERE trunc(intdcre)=TRUNC(current_date-7) AND intstat=2)
FROM dual
UNION
SELECT 'Recap. since 7 days', '1. Header',
      'Day-1','Day-2','Day-3','Day-4','Day-5','Day-6','Day-7'
FROM dual
ORDER BY 1 DESC
