import groovy.sql.Sql;
import org.zkoss.zk.ui.*;

void showMessageBox(String wmessage)
{
        Messagebox.show(wmessage,"Bong",Messagebox.OK,Messagebox.EXCLAMATION);
}

// Main routine to create a jdbc connection to MIRIS database
// Any changes to user/password, make here.
Sql mirisSQL()
{
	try
	{
		return(Sql.newInstance("jdbc:mysql://localhost:3306/miris", "mirisproj", "kingkong",
			"org.gjt.mm.mysql.Driver"));
	}
	catch (SQLException e)
	{
	}
}

// Find listitem in listbox based on Id, id format = lookup.name + "_" + lookup.id (OT_ROOM_99)
int findListitemById(Listbox mListbox, String theid)
{
	Listitem tlistitem = mListbox.getFellow(theid);
	return(tlistitem.getIndex());
}

// used in IF1_section1 and IF1_section2
public String returnDisptext(String what)
{
	thesql = mirisSQL();

	sqlstatement = "SELECT * from lookups where name='" + what + "'";
	lookupList = thesql.firstRow(sqlstatement);
	thesql.close();

	return(lookupList.get("disptext"));
}

// Populate the category listbox. used in setup pages and login
void populateHospitalsListbox(Listbox thelistbox)
{
	try
	{
		sql = mirisSQL();

		sqlstatem = "select * from hospitals";
		catlist = sql.rows(sqlstatem);

		if(catlist.size() > 0)
		{
			for(cato : catlist)
			{
				String cat_hid = new String(cato.get("hospitalid"));
				
				// hardcoded to check if hospitalid = SYSTEM, don't put into listbox
				if(!cat_hid.equals("SYSTEM"))
				{
					Listitem mylistitem = new Listitem();
					cat_hname = cato.get("hospitalname");

					mylistitem.setLabel(cat_hname);
					mylistitem.setId(cat_hid);
					mylistitem.setParent(thelistbox);
				}
			}
		}
	}
	catch (SQLException se) {}

	sql.close();
}

// Container class for lookup items input boxes and such
class lookupInputs
{
	public Textbox name;
	public Textbox disptext;
	public Checkbox expired;
	public Intbox intvalue;
	public Listbox parentlistbox;
	String plb_id;
	public Tree lu_tree;
	
	public lookupInputs(Textbox iname, Textbox idisptext, Checkbox iexpired, Intbox ibox,
	Listbox iplbox, Tree itree)
	{
		name = iname;
		disptext = idisptext;
		expired = iexpired;
		intvalue = ibox;
		parentlistbox = iplbox;
		lu_tree = itree;
	}
	
	public lookupInputs(Textbox iname, Textbox idisptext, Checkbox iexpired, Intbox ibox,
	String iplboxid, Tree itree)
	{
		name = iname;
		disptext = idisptext;
		expired = iexpired;
		intvalue = ibox;
		parentlistbox = null;
		plb_id = iplboxid;
		lu_tree = itree;
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

/*
Populate a listbox with lookups
 mListBox : listbox control to fill
 mLookupname : lookup code(myparent) in database
 showcode : 1 = show code(name) from database
 
 *** Need to add extra parameter to select only from certain hospital,
	ward/clinic, department and other stuff can be by hospital
*/
void populateListBox(Listbox mListBox, String mLookupname, int showcode)
{
	thesql = mirisSQL();
	
	sqlstatement = "SELECT * from lookups where myparent='" + mLookupname + "'";
	List lookupList = thesql.rows(sqlstatement);
	
	// Maybe need to add clear listbox codes here. Then mListBox param will be changed to Div
	// and create the listbox dynamically.
	
	if(lookupList.size() > 0)
	{
		// insert an empty listitem at top
		Listitem blankitem = new Listitem();
		blankitem.setLabel("NONE");
		blankitem.setParent(mListBox);
		
		for(cLookup : lookupList)
		{
			ls_id = cLookup.get("id");
			ls_name = cLookup.get("name");
			ls_disptext = cLookup.get("disptext");

			// Compose listitem id from lookups.name + "_" + lookups.id
			ls_compid = ls_name + "_" + ls_id;
			
			if(showcode == 1)
			{
				ls_disptext = "[" + ls_name + "] " + ls_disptext;
			}
			
			// not expired, include in lookup list
			if(cLookup.get("expired") == false)
			{
				Listitem tobeadded = new Listitem();
				tobeadded.setLabel(ls_disptext);
				tobeadded.setId(ls_compid);
				tobeadded.setParent(mListBox);
			}
		}

	}
	thesql.close();
}

// Populate the category listbox. used in setup pages
void populateCategory(Listbox thelistbox, String thename)
{
	sql = mirisSQL();

	sqlstatem = "select * from lookups where myparent = '" + thename + "'";
	catlist = sql.rows(sqlstatem);
	
	if(catlist.size() > 0)
	{
		for(cato : catlist)
		{
			Listitem mylistitem = new Listitem();
			cat_name = cato.get("name");
			cat_disptext = cato.get("disptext");
			
			mylistitem.setLabel(cat_disptext);
			mylistitem.setId(cat_name);
			mylistitem.setParent(thelistbox);
		}
	}
	
	sql.close();
}

// Show the lookup table in tree
// melistbox : used to get parent name
// thethree : tree control to be populated
void showLookupTree(Listbox melistbox, Tree thetree)
{
	//alert(melist.getItemAtIndex(melist.getSelectedIndex());
	//alert(melistbox.getSelectedItem());

	doname = melistbox.getSelectedItem().getId();
	
	if(doname != null)
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
		LookupTree incd_lookuptree = new LookupTree(mychildrens,doname,true);
	}
}

// Return the selected item's parent. Should be unique and be used for inserting new
// items under the parent.
String getSelectedParent(String whichone)
{
	try
	{
		sql = mirisSQL();
		sqlstatem = "select * from lookups where name='" + whichone + "'";
		therec = sql.firstRow(sqlstatem);
	}
	catch (SQLException e) {}
	finally
	{
		sql.close();
		return therec.get("myparent");
	}
}

// Populate input boxes for lookup items. called by popUpdateBox() below
void popInputBoxes(String icode, lookupInputs winputs)
{
	dbconn = mirisSQL();
	
	sqlstatement = "select * from lookups where name='" + icode + "'";
	
	subchild = dbconn.firstRow(sqlstatement);
	
	winputs.name.setValue(subchild.get("name"));
	winputs.disptext.setValue(subchild.get("disptext"));
	
	try
	{
		intvalue = 0;
		
		if(subchild.get("intvalue") != null)
			intvalue = (int)subchild.get("intvalue");
			
		winputs.intvalue.setValue(intvalue);
	}
	catch (NullPointerException e)
	{
		winputs.intvalue.setValue(0);	
	}
	
	dbconn.close();
	
	Boolean expiredcheck = (Boolean)subchild.get("expired");
	winputs.expired.setChecked(expiredcheck);
}

// Populate update popup box. Can add extra processing before updating the input boxes.
void popUpdateBox(Tree thetree, lookupInputs winputs)
{
	try
	{
		String selectedId = thetree.getSelectedItem().getLabel();
		popInputBoxes(selectedId,winputs);

	}
	catch (NullPointerException nex) {}
}

// Update lookup items
void updateItem(Popup wpopup, Tree itypetree, lookupInputs winputs)
{
	iname = winputs.name.getValue();
	idisptext = winputs.disptext.getValue();
	iexpired = winputs.expired.isChecked();
	intval = winputs.intvalue.getValue();
	
	// alert("disptext = " + idisptext);
	
	try
	{
		sql = mirisSQL();
		sqlstatem = "update lookups set disptext='"+ idisptext + "',expired="+iexpired+
			",intvalue=" + intval + " where name='" + iname + "'";
			
		sql.executeUpdate(sqlstatem);

		wpopup.close();
		
		// redraw lookup tree
		showLookupTree(winputs.getParentListBox(),winputs.lu_tree);
	}
	catch (SQLException e) {}
	finally
	{
		sql.close();
	}
	
	winputs.getParentListBox();
}

// Make sure the code entered is unique.
// cannot have duplicates else the whole system will break.
boolean isUniqueCode(String thecode)
{
	boolean retval = false;
	
	try
	{
		sql = mirisSQL();
		
		sqlstatement = "select name from lookups where name='" + thecode + "'";
		subchild = sql.rows(sqlstatement);
		
		if(subchild.size() == 0)
			retval = true;
	}
	catch (SQLException se) {}

	sql.close();
	return retval;

}

// Insert new lookup items to lookup table
void insertItem(Popup wpopup, Tree itypetree, lookupInputs winputs)
{
	try
	{
		iname = ins_incd_name.getValue();
		idisptext = ins_incd_disptext.getValue();
		iexpired = ins_incd_expired.isChecked();
		intval = ins_incd_intvalue.getValue();
		
		if(intval == null) intval = 0;
		
		wpopup.close();
		
		if(iname == null || iname == "")
		{
			return;
		}
		
		selectedId = itypetree.getSelectedItem().getLabel();
		
		// Get parent of the selected item, make use of this to insert new incident type
		// into table
		insparent = getSelectedParent(selectedId);
		
		// Check to make sure code is unique
		if(isUniqueCode(iname) == true)
		{
			//alert(iname + " is unique, can insert");
			
			try
			{
				 sql = mirisSQL();
			sqlstatem = "insert into lookups (myparent,name,disptext,intvalue,expired) values ('"+
			insparent + "','" + iname + "','" + idisptext + "'," + intval + "," + iexpired + ")";
			
			sql.execute(sqlstatem);
			
			// redraw lookup tree
			showLookupTree(winputs.getParentListBox(),winputs.lu_tree);
				
			}
			catch (SQLException se) {}
			
			sql.close();
			
		}
		else
		{
			alert("Code in use, duplicates not allowed");
		}
	}
	catch (NullPointerException nex) {}
}

// Make sure the whole system not using this lookup or it'll break
// to be coded

boolean isInUse(String thecode)
{

}

// Delete lookup items from table.
void deleteItem(Popup wpopup, Tree itypetree, lookupInputs winputs)
{
	// hardcoded
	wpopup.close();
	
	try
	{
		selectedId = itypetree.getSelectedItem().getLabel();
		
		// check to see if others are using this incident code
		// isInUse(selectedId)
		
		try
		{
			sql = mirisSQL();
			
			sqlstatem = "delete from lookups where name='" + selectedId + "'";
			sql.execute(sqlstatem);
			
			// redraw lookup tree
			showLookupTree(winputs.getParentListBox(),winputs.lu_tree);
			
		}
		catch (SQLException se) {}
		
		sql.close();
	
	}
	catch (NullPointerException nex) {}
}
