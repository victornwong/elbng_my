import java.sql.Connection;
import java.sql.DriverManager;
import javax.sql.DataSource;
import groovy.sql.Sql;
import org.zkoss.zk.ui.*;
import java.security.*;

/*
Purpose: Global security / ACL functions
Written by : Victor Wong
Date : 11/01/2010

Design notes:

1. users are assigned main access level
2. users are included into groups
3. users will have individual group access level

to grant access, users must have the same access level or higher and must be in the group as specified by certain functions
group will have it's own access level for each user. if user's group access level is higher than the main access level, access granted

*/

// Table names
TABLE_PORTALUSER = "PortalUser";
TABLE_PORTALUSERGROUP = "portalUsergroups";
TABLE_PORTALGROUPACCESS = "portalGroupAccess";

String[] dd_accesslevel = {"1","2","3","4","5","6","7","8","God-like"};
String[] dd_branches = {"SA","JB","KK","ALL" };

// FXM usergroups access
PROJECT_ACCESSLEVEL = 2;
PROJECT_USERGROUP = "('PROJECT')";

INVENTORY_ACCESSLEVEL = 2;
INVENTORY_USERGROUP = "('INVENTORY')";

FINANCE_ACCESSLEVEL = 2;
FINANCE_USERGROUP = "('FINANCE')";

MARKETING_ACCESSLEVEL = 2;
MARKETING_USERGROUP = "('MARKETING')";

// ELB usergroups access levels
SAMPREG_ACCESSLEVEL = 2;
SAMPREG_USERGROUP = "('OPER','SAMPREG','BILLING')";

RECEPTION_ACCESSLEVEL = 2;
RECEPTION_USERGROUP = "('OPER','FRONTDESK','BILLING')";

ADMIN_BIRT_REPORTS_ACCESSLEVEL = 2;
ADMIN_BIRT_REPORTS_USERGROUP = "('ADMINOFFICE','ACCTS','BILLING','CREDITC')";

SALES_MARKETING_ACCESSLEVEL = 2;
SALES_MARKETING_USERGROUP = "('ADMINOFFICE','SALES')";

QCOFFICER_ACCESSLEVEL = 2;
QCOFFICER_USERGROUP = "('OPER','QC')";

REPORTGEN_ACCESSLEVEL = 2;
REPORTGEN_USERGROUP = "('OPER','REPORTING')";

// Main user access object that will get pass around in the portal once login is successful- ball tossing game
public class userAccessObj
{
	public int origid;
    public String username;
    public int accesslevel;
	public String fullname;
	public String email;
	public String handphone;
	public String branch;
	
	public clearAll()
	{
		origid = 0;
		
		username = "";
		accesslevel = 0;
		
		fullname = "";
		email = "";
		handphone = "";
		branch = "";
	}
}

// get user access obj, hardcoded "uao" as attribute name
Object getUserAccessObject()
{
	return(Executions.getCurrent().getAttribute("uao"));
}

// set the user access obj for the Include component, this will allow the included zul page to read the obj
void setUserAccessObj(Include wInc, Object tuaobj)
{
	wInc.setDynamicProperty("uao",tuaobj);
}

// Simple MD5 encrypter. whattext = what text to encrypt
// do not change sessionid once there're text encrypted previously and stored into database
String als_MD5_Encrypter(String whattext)
{
	sessionid = "samvwchng";
	tocrypt = whattext.getBytes();
	byte[] defaultBytes = sessionid.getBytes();
	MessageDigest algorithm = MessageDigest.getInstance("MD5");
	algorithm.reset();
	algorithm.update(defaultBytes);

	byte[] messageDigest = algorithm.digest(tocrypt);

	StringBuffer hexString = new StringBuffer();
	for (int i=0;i<messageDigest.length;i++)
	{
		hexString.append(Integer.toHexString(0xFF & messageDigest[i]));
	}
	
	return hexString.toString();
	
} // end of als_MD5_Encrypter(String whattext)

// Get from table portaluser - username rec 
Object getUsername_Rec(String iorigid)
{
	if(iorigid.equals("")) return null;
	
	sql = lgk_mysoftsql();
	if(sql == NULL) return;
	
	sqlstatem = "select * from " + TABLE_PORTALUSER + "  where origid=" + iorigid;
	therec = sql.firstRow(sqlstatem);
	sql.close();
	
	return therec;
}

// This func will check username and password against rec in mysoft->portalUser.
// No checks on usergroup or accesslevel. Will return false if account is locked
boolean checkUserAccess(String cusername, String cpassword, userAccessObj wUAO)
{
	boolean retval = false;
	
	sql = lgk_mysoftsql();
	
	// table mysoft->portalUser
	statem = "select * from " + TABLE_PORTALUSER + " where username='" + cusername + "' and password='" + cpassword + "'";
	retrow = sql.firstRow(statem);
	sql.close();
	
	// username and password in table, successful login, setup the useraccessobject
	if(retrow != null)
	{
		// alert("found you.. " + retrow.get("username") + " = " + retrow.get("password"));
		
		// Check if user is locked
		if(retrow.get("locked") == 1)
		{
			alert("Your account is locked!");
			return false;
		}
		
		// populate the useraccessobject
		
		wUAO.origid = retrow.get("origid");
		
		wUAO.username = retrow.get("username");
		wUAO.accesslevel = retrow.get("accesslevel");
		
		wUAO.fullname = retrow.get("fullname");
		wUAO.email = retrow.get("email");
		wUAO.handphone = retrow.get("handphone");
		
		wUAO.branch = retrow.get("branch");
		
		//alert("maintree: " + useraccessobj.maintree);
		
		retval = true;
	}
	
	return retval;
}

// Check user access level against application modules - refer to alsglobaldefs.zs -> class modulesObj
checkUserAccesslevel_AppModules(Object appmod, int iacclevel)
{
	retval = false;
	if(iacclevel >= appmod.accesslevel ) retval = true;
	return retval;
}

// Check user against usergroup access
// un_origid : username origid - rec no. in portalUser table
// iusergroup : usergroup codes - as " usergroupcode in ('adfasdf','qwerwre','qwerqwer')"
// minaccesslvl : min. access level to activate
boolean check_UsergroupAccess(int un_origid, String iusergroup, int minaccesslvl)
{
	retval = false;
	
	sql = lgk_mysoftsql();
    if(sql == NULL) return false;
	
	sqlstatem = "select * from " + TABLE_PORTALGROUPACCESS + " where user_origid=" + un_origid + " and usergroup_code in " + iusergroup;
	thelist = sql.rows(sqlstatem);
	sql.close();
	
	if(thelist != null)
	{
		for(irec: thelist)
		{
			igrplvl = irec.get("accesslevel");
			
			// if any rec group access level is same or higher, grant access
			if(igrplvl >= minaccesslvl)
			{
				retval = true;
				break;
			}
		}
		
	}

	return retval;
	
} // end of check_UsergroupAccess()

void showAccessDenied_Box(Object iuoa)
{
	wnid = makeRandomId("badtaste");
	globalActivateWindow("miscwindows","accessdenied_box.zul", wnid , "access=false", iuoa);
}

void checkAdminAccess_Menuitem(Object imenuitem)
{
	if(useraccessobj.accesslevel == 9)
		imenuitem.setVisible(true);
}

void checkMenuItem_Visible(Object imenuitem, String iusergroup, int iaccesslevel)
{
	if(check_UsergroupAccess(useraccessobj.origid,iusergroup,iaccesslevel))
		imenuitem.setVisible(true);
}
