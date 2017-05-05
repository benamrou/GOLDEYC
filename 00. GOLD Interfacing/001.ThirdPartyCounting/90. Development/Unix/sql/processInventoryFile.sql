
VARIABLE o_return NUMBER;
exec PKTHIRDPARTY_COUNTING.ProcessInventory(1,'&1', :o_return);

PRINT o_return;
exit;
/
