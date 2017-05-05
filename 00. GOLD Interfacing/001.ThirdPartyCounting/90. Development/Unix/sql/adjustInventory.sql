
VARIABLE o_return NUMBER;
exec PKTHIRDPARTY_COUNTING.AdjustInventory(1,'&1', :o_return);

PRINT o_return;
exit;
/
