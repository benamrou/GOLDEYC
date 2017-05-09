
VARIABLE o_return NUMBER;
exec PKITEMMHLINK.ProcessMHLinkChange(1,'&1', :o_return);

PRINT o_return;
exit;
/
