
VARIABLE o_return NUMBER;
exec PK_DUNNHUMBY.ProcessDunnhumby(1,'&1', :o_return);

PRINT o_return;
exit;
/
