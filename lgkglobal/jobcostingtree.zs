import org.zkoss.zk.ui.*;
import groovy.sql.Sql;

/*
Title		: Job costing tree management funcs
Written by	: Victor Wong
Dated		: 28/04/2011

**NOTES**
Funcs to manage job-costing tree.. knockoff from the general purpose lookuptree funcs.
uses new openTheDatabase() in lgk_sqlfuncs.zs

*/

LOOKUP_TABLE = "jobcosting_tree";

class LookupTree
{
	Treechildren tobeshown;
	Sql mainSql;
	int use_whichdb;

	void LookupTree(Treechildren thechild, String queryname, int iwhichdb, boolean showexpired)
	{
		use_whichdb = iwhichdb;

		// 24/2/2010: mod to use lgk_mysoftsql() in lgk_sqlfuncs.zs
		mainSql = openTheDatabase(use_whichdb);
		if(mainSql == NULL) return;

		sqlstatement = "SELECT idlookups,name,disptext,expired,value1 from " + LOOKUP_TABLE + " where myparentid=" + queryname;
		List catlist = mainSql.rows(sqlstatement);
		tobeshown = thechild;
		fillMyTree(thechild, catlist, showexpired);
		mainSql.close();
	}

	// 28/04/2011: added 3rd column to show estimate-cost from jobcosting_tree.value1
	// showexpired : used in normal operation, if showexpired = 0, don't show, user cannot select
	// showexpired = 1 , show expired, during lookup configuratin only
	void fillMyTree(Treechildren tchild, List prolist, boolean showexpired)
	{
		for (opis : prolist)
		{
			if(opis.get("expired") == 1 && showexpired == false) continue;

			Treeitem titem = new Treeitem();
			Treerow newrow = new Treerow();

			Treecell newcell1 = new Treecell();
			Treecell newcell2 = new Treecell();
			Treecell newcell3 = new Treecell();
			Treecell newcell4 = new Treecell();

			thisbranchid = opis.get("idlookups").toString();
			lookname = opis.get("name");
			disptext = opis.get("disptext");
			value1 = opis.get("value1");
			if(value1 == null) value1 = "---";

			sqlqueryline = "select idlookups,name,disptext,expired,value1 " + 
			"from " + LOOKUP_TABLE + " where myparentid=" + thisbranchid;

			List subchild = mainSql.rows(sqlqueryline);

			highlite = false;

			if(subchild.size() > 0)
			{
				Treechildren newone = new Treechildren();
				newone.setParent(titem);
				fillMyTree(newone,subchild,showexpired);
				
				highlite = true;

				//newcell1.setLabel("${subchild.size()} ${opis[2]}");
			}

			expiredstr = "";

			if(opis.get("expired") == 1) expiredstr = "[INACTIVE] ";

			newcell4.setVisible(false);
			newcell4.setLabel(thisbranchid);
			
			itmstyle = "font-size:9px";
			
			if(highlite) itmstyle += ";background:#99AA88";
			
			newcell1.setLabel(lookname);
			newcell1.setStyle("font-size:9px");
			newcell1.setDraggable("treedrop");

			newcell3.setStyle(itmstyle);
			newcell3.setLabel(value1);

			newcell2.setStyle(itmstyle);
			newcell2.setLabel(expiredstr + disptext);
			// newcell2.setDraggable("treedrop");

			newcell1.setParent(newrow);
			newcell2.setParent(newrow);
			newcell3.setParent(newrow);
			newcell4.setParent(newrow);
			newrow.setParent(titem);
			titem.setParent(tchild);
		}
	}

	void myShowTreeChildren()
	{
		alert(tobeshown);
	}

}
// end of class LookupTree

// Container class for lookup items input boxes and such
class lookupInputs
{
	public Textbox name;
	public Textbox disptext;
	public Checkbox expired;
	public Intbox intvalue;
	public Listbox parentlistbox;

    public Textbox value1;
    public Textbox value2;
    public Textbox value3;
    public Textbox value4;
    public Textbox value5;
    public Textbox value6;
    public Textbox value7;
    public Textbox value8;
	
	// 24/2/2010: to store lookup rec no.
	public int idlookups;

	public String plb_id;
	public Tree lu_tree;

	public lookupInputs(Textbox iname, Textbox idisptext, Checkbox iexpired, Intbox ibox, Listbox iplbox, Tree itree)
	{
		name = iname;
		disptext = idisptext;
		expired = iexpired;
		intvalue = ibox;
		parentlistbox = iplbox;
		lu_tree = itree;
	}

	public lookupInputs(Textbox iname, Textbox idisptext, Checkbox iexpired, Intbox ibox,
    Textbox ivalue1,Textbox ivalue2,Textbox ivalue3,Textbox ivalue4,
    Textbox ivalue5,Textbox ivalue6,Textbox ivalue7,Textbox ivalue8,
	String iplboxid, Tree itree)
	{
		name = iname;
		disptext = idisptext;
		expired = iexpired;
		intvalue = ibox;
		parentlistbox = null;
		plb_id = iplboxid;
		lu_tree = itree;

        value1 = ivalue1;
        value2 = ivalue2;
        value3 = ivalue3;
        value4 = ivalue4;
        value5 = ivalue5;
        value6 = ivalue6;
        value7 = ivalue7;
        value8 = ivalue8;

	}

    void clearValues()
    {
        name.setValue("");
        disptext.setValue("");
        expired.setChecked(false);
        intvalue.setValue(0);

        value1.setValue("");
        value2.setValue("");
        value3.setValue("");
        value4.setValue("");
        value5.setValue("");
        value6.setValue("");
        value7.setValue("");
        value8.setValue("");

    }

	Listbox getParentListBox()
	{
		// if parentlistbox is null, use id string to get actual listbox
		if(parentlistbox == null)
		{
			parentlistbox = lu_tree.getFellowIfAny(plb_id);
		}

		return parentlistbox;

	}
}
// end of class lookupInputs

// Show the lookup table in tree
// melistbox : used to get parent name
// thethree : tree control to be populated
void showLookupTree(String parentname, Tree thetree, int iwhichdb)
{
	// Clear any child attached to tree before updating new ones.
	Treechildren tocheck = thetree.getTreechildren();
	if(tocheck != null)
	{
		tocheck.setParent(null);
	}

	// create a new treechildren for the tree
	Treechildren mychildrens = new Treechildren();
	mychildrens.setParent(thetree);

	// Load the lookuptree from database
	LookupTree incd_lookuptree = new LookupTree(mychildrens,parentname,iwhichdb,true);
}

// Make sure the code entered is unique.
// cannot have duplicates else the whole system will break.
boolean isUniqueCode(String thecode, String iparentid, int iwhichdb)
{
	boolean retval = false;
	sql = openTheDatabase(iwhichdb);
	if(sql == null) return retval;
	sqlstatement = "select name from " + LOOKUP_TABLE + " where myparentid=" + iparentid + " and name='" + thecode + "'";
	subchild = sql.rows(sqlstatement);
	sql.close();
	if(subchild.size() == 0) retval = true;
	return retval;
}

Object getLookup_Rec(String iname, int iwhichdb)
{
	sql = openTheDatabase(iwhichdb);
	if(sql == null) return null;
	sqlstatem = "select * from " + LOOKUP_TABLE + " where name='" + iname + "'";
	therec = sql.firstRow(sqlstatem);
	sql.close();
	return therec;
}

Object getLookup_Rec_byID(String ilookupid, int iwhichdb)
{
	sql = openTheDatabase(iwhichdb);
	if(sql == null) return null;
	sqlstatem = "select * from " + LOOKUP_TABLE + " where idlookups=" + ilookupid;
	therec = sql.firstRow(sqlstatem);
	sql.close();
	return therec;
}

// Return the selected item's parent. Should be unique and be used for inserting new
// items under the parent.
String getSelectedParent(String whichone, int iwhichdb)
{
	sql = openTheDatabase(iwhichdb);
	if(sql == null) return;
	sqlstatem = "select * from " + LOOKUP_TABLE + " where name='" + whichone + "'";
	therec = sql.firstRow(sqlstatem);
	sql.close();
	return therec.get("myparent");
}

// 28/04/2011: insert blank parent into lookup table - return TRUE if inserted
boolean insertBlankLookupParent(String iname, String imyparent, int iwhichdb)
{
	sql = openTheDatabase(iwhichdb);
	if(sql == null) return false;
	sqlstm = "insert into " + LOOKUP_TABLE + " (myparent,myparentid,name,disptext,intval,expired," + 
	"value1,value2,value3,value4,value5,value6,value7,value8) values " + 
	"('" + imyparent + "',0,'" + iname + "','',0,0," + 
	"'','','','','','','','')";
	sql.execute(sqlstm);
	sql.close();
	return true;
}

// Insert new lookup items to lookup table
void insertLookupItem(Tree itypetree, lookupInputs winputs, int iwhichdb, String iparentid, String ibranchid)
{
	iname = replaceSingleQuotes(winputs.name.getValue());
	if(iname.equals("")) return;

	idisptext = replaceSingleQuotes(winputs.disptext.getValue());
	iexpired = winputs.expired.isChecked();
	intvalbox = winputs.intvalue.getValue();

    //zzintval = (intvalbox == null) ? 0 : intvalbox.intValue();
	//zzintval = intvalbox.getValue();

    ivalue1 = replaceSingleQuotes(winputs.value1.getValue());
    ivalue2 = replaceSingleQuotes(winputs.value2.getValue());
    ivalue3 = replaceSingleQuotes(winputs.value3.getValue());
    ivalue4 = replaceSingleQuotes(winputs.value4.getValue());
    ivalue5 = replaceSingleQuotes(winputs.value5.getValue());
    ivalue6 = replaceSingleQuotes(winputs.value6.getValue());
    ivalue7 = replaceSingleQuotes(winputs.value7.getValue());
    ivalue8 = replaceSingleQuotes(winputs.value8.getValue());

	// 24/2/2010: expired field is tinyint, cannot hold boolean
	iexp = (iexpired == true) ? 1 : 0;

	//selectedId = itypetree.getSelectedItem().getLabel();
	// Get parent of the selected item
	//insparent = selectedId;

	theparent = iparentid;
	if(!ibranchid.equals("0")) theparent = ibranchid;

    sql = openTheDatabase(iwhichdb);
	if(sql == null) return;
	thecon = sql.getConnection();
	pstmt = thecon.prepareStatement("insert into " + LOOKUP_TABLE + " (myparent,myparentid,name,disptext,intval,expired," + 
	"value1,value2,value3,value4,value5,value6,value7,value8) values (?,?,?,?,?,?,?,?,?,?,?,?,?,?)");

	pstmt.setString(1,theparent);
	pstmt.setInt(2,Integer.parseInt(theparent));
	pstmt.setString(3,iname);
	pstmt.setString(4,idisptext);
	pstmt.setInt(5,0);
	pstmt.setInt(6,iexp);

	pstmt.setString(7,ivalue1);
	pstmt.setString(8,ivalue2);
	pstmt.setString(9,ivalue3);
	pstmt.setString(10,ivalue4);
	pstmt.setString(11,ivalue5);

	pstmt.setString(12,ivalue6);
	pstmt.setString(13,ivalue7);
	pstmt.setString(14,ivalue8);

	pstmt.executeUpdate();
	sql.close();			

	// redraw lookup tree
	showLookupTree(winputs.plb_id,itypetree,iwhichdb);

} // end of insertLookupItem()

// Update lookup items
void updateLookupItem(Tree itypetree, lookupInputs winputs, int iwhichdb)
{
	iname = winputs.name.getValue();
	idisptext = winputs.disptext.getValue();
	iexpired = winputs.expired.isChecked();
	intvalbox = winputs.intvalue;

    zzintval = (intvalbox == null) ? 0 : intvalbox.intValue();

	// 24/2/2010: expired field is tinyint, cannot hold boolean
	iexp = (iexpired == true) ? "1" : "0";

    ivalue1 = winputs.value1.getValue();
    ivalue2 = winputs.value2.getValue();
    ivalue3 = winputs.value3.getValue();
    ivalue4 = winputs.value4.getValue();
    ivalue5 = winputs.value5.getValue();
    ivalue6 = winputs.value6.getValue();
    ivalue7 = winputs.value7.getValue();
    ivalue8 = winputs.value8.getValue();

	sql = openTheDatabase(iwhichdb);
	sqlstatem = "update " + LOOKUP_TABLE + " set disptext='"+ idisptext + "',expired=" + iexp +
		",intval=" + zzintval.toString() +
		",value1='" + ivalue1 + "'" +
		",value2='" + ivalue2 + "'" +
		",value3='" + ivalue3 + "'" +
		",value4='" + ivalue4 + "'" +
		",value5='" + ivalue5 + "'" +
		",value6='" + ivalue6 + "'" +
		",value7='" + ivalue7 + "'" +
		",value8='" + ivalue8 + "'" +
		",name='" + iname + "'" +
		" where idlookups=" + winputs.idlookups.toString();

	sql.execute(sqlstatem);
	sql.close();

	// redraw lookup tree
	showLookupTree(winputs.plb_id,winputs.lu_tree,iwhichdb);

} // end of updateLookupItem()

// Delete lookup items from table.
void deleteLookupItem(Tree itypetree, lookupInputs winputs, int iwhichdb)
{
	selectedId = itypetree.getSelectedItem().getLabel();
	// check to see if others are link to this
	//isInUse(selectedId)

	sql = openTheDatabase(iwhichdb);
	sqlstatem = "delete from " + LOOKUP_TABLE + " where name='" + selectedId + "'";
	sql.execute(sqlstatem);
	// redraw lookup tree
	showLookupTree(winputs.plb_id,winputs.lu_tree,iwhichdb);
	sql.close();

} // end of deleteLookupItem()

