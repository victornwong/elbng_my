
import groovy.sql.Sql;
import org.zkoss.zk.ui.*;

/*
Global vars and functions for MIRiS project

*/

MAINPROCPATH = "mainproc";

public class userAccessObj
{
    public String hospitalid;
	public String hospitalname;
    public String username;
    public int accesslevel;
	
	public clearAll()
	{
		username = "";
		hospitalid = "";
		hospitalname = "";
		accesslevel = 0;
	}
}

// get user access obj, hardcoded "uao" as attribute name
Object getUserAccessObject()
{
	return(Executions.getCurrent().getAttribute("uao"));
}

void setUserAccessObj(Include wInc, userAccessObj tuaobj)
{
	wInc.setDynamicProperty("uao",tuaobj);
}

