import java.sql.Connection;
import java.sql.DriverManager;
import javax.sql.DataSource;
import groovy.sql.Sql;
import org.zkoss.zk.ui.*;

/*
Purpose: Global GUI related functions we put them here
Written by : Victor Wong
Date : 11/08/2009

Notes:
*/

ALS_PORTAL = "//als_portal_main/";
FXM_PORTAL = "//fxmpms_main/";

THEMAINTONG = ALS_PORTAL;

public class listboxHeaderObj
{
	public String header_str;
	public boolean header_visible;
	
	public listboxHeaderObj(String iheaderstr, boolean iheadvisible)
	{
		header_str = iheaderstr;
		header_visible = iheadvisible;
	}
}

// New class for creating listbox with db recs retrieval
public class dblb_HeaderObj
{
	public String header_str;
	public boolean header_visible;
	public String db_fieldname;
	public int db_fieldtype;

	// constructor: ifieldname = table fieldname, ifieldtype = field-type (1=varchar,2=int,3=date)
	public dblb_HeaderObj(String iheaderstr, boolean iheadvisible, String ifieldname, int ifieldtype)
	{
		header_str = iheaderstr;
		header_visible = iheadvisible;
		db_fieldname = ifieldname;
		db_fieldtype = ifieldtype;
	}
}

// Function to show pop-up message box, wrap for the system Messagebox.show class
void showMessageBox(String wmessage)
{
        Messagebox.show(wmessage,"Ding",Messagebox.OK,Messagebox.EXCLAMATION);
}

/****************************************************************************
Populate a listbox with items. Create new listcell for each string passed.
listbox can have multiple columns then.

Parameter:
wlistbox = listbox to populate
toput = string array to use
***************************************************************************
*/
void insertListItems(Listbox wlistbox, String[] toput, String dragdropCode)
{
	// 18/01/2010 - dragdropCode = for drag-drop function, to match name-identifier when dropped.
	if(dragdropCode.equals(""))
		dragdropCode = "true";

	Listitem litem = new Listitem();
	
	i = 0;

	for(tstr : toput)
	{
		Listcell lcell = new Listcell();

        tstr2 = tstr.trim();
		
		if(i == 0)
		{
			lcell.setDraggable(dragdropCode);
			i++;
		}
		
		lcell.setLabel(tstr2);
		// can modify
		lcell.setStyle("font-size:9px");
		lcell.setParent(litem);
	}

    // litem.setDraggable("true");
	
	litem.setParent(wlistbox);
}

// 1/4/2010: insert item into listbox but with dragdrop set to certain column
// icolumn = icolumn - 1 ( 1 = start)
void insertListItems_DragDrop(Listbox wlistbox, String[] toput, String dragdropCode, int icolumn)
{
	if(dragdropCode.equals(""))
		dragdropCode = "true";

	Listitem litem = new Listitem();
	
	i = 0;
	iwcol = icolumn - 1;

	for(tstr : toput)
	{
		Listcell lcell = new Listcell();

        tstr2 = tstr.trim();
		
		if(i == iwcol)
			lcell.setDraggable(dragdropCode);
		
		lcell.setLabel(tstr2);
		// can modify
		lcell.setStyle("font-size:9px");
		lcell.setParent(litem);
		
		i++;
	}

    // litem.setDraggable("true");
	
	litem.setParent(wlistbox);
}

/****************************************************************************
Global func to insert drop-down items into a Listbox type "select"
wlistb = listbox object
iarray = single-dim strings array
eg:
	<listbox mold="select" rows="1" id="wowo" />
	String[] mearr = { "this", "and", "that", "equals", "to", "nothing" };
	populateDropdownListbox(wowo, mearr);
****************************************************************************
*/
void populateDropdownListbox(Listbox wlistb, String[] iarray)
{
	String[] strarray = new String[1];
	
	for(i=0; i < iarray.length; i++)
	{
		strarray[0] = iarray[i];
		insertListItems(wlistb,strarray,"true");
	}
	
	// set selected-index for listbox to the first item
	// can recode this section to be able to select item which matches the one passed in arg.
	wlistb.setSelectedIndex(0);
}

// link new window or panel to parentdiv_name Div
// winfn = window
// windId = window id , hardcoded usually in the other modules on how the newid would be
// uParams = parameters to be passed to the new window - coded in html-POST format - raw, no preprocessing in here
void globalActivateWindow(String parentdiv_name, String winfn, String windId, String uParams, Object uAO)
{
	Include newinclude = new Include();
	newinclude.setId(windId);
	
	includepath = winfn + "?myid=" + windId + "&" + uParams;
	newinclude.setSrc(includepath);
	
	setUserAccessObj(newinclude, uAO); // securityfuncs.zs
	
	Div contdiv = Path.getComponent(THEMAINTONG + parentdiv_name);
	newinclude.setParent(contdiv);
	
} // end of globalActivateWindow()

// For those subwindows opened in Div .. getcomponent is hardcoded
void globalCloseWindow(String theincludeid)
{
	// refering back to main page, hardcoded for now.
	Div contdiv = Path.getComponent(THEMAINTONG + "miscwindows");
	Include thiswin = contdiv.getFellow(theincludeid);

	// just set the include source to empty, should remove this window
	thiswin.setSrc("");
    contdiv.removeChild(thiswin);
}

// For those panels opened in Div.. hardcoded id
void globalClosePanel(String theincludeid)
{
	// refering back to main page, hardcoded for now.
	Div contdiv = Path.getComponent(THEMAINTONG + "worksandbox");
	Include thiswin = contdiv.getFellow(theincludeid);

	// just set the include source to empty, should remove this window
	thiswin.setSrc("");
    contdiv.removeChild(thiswin);
}

void localActivateWindow(Div parentdiv_name, String winfn, String windId, String uParams, Object uAO)
{
	Include newinclude = new Include();
	newinclude.setId(windId);
	
	includepath = winfn + "?myid=" + windId + "&" + uParams;
	newinclude.setSrc(includepath);
	
	setUserAccessObj(newinclude, uAO); // securityfuncs.zs
	
	newinclude.setParent(parentdiv_name);
	
} // end of globalActivateWindow()

// Match listbox item with iwhatstr on which icolumn, return Listitem so caller can get whichever column's label
Listitem matchListboxReturnListItem(Listbox ilb, String iwhatstr, int icolumn)
{
	retval = null;
	
	icc = ilb.getItemCount();
	if(icc == 0) return null; // nothing.. return

	for(i=0; i<icc; i++)
	{
		ilabel = ilb.getItemAtIndex(i);
		
		kkk = getListcellItemLabel(ilabel, icolumn);
		
		// if match found
		if(kkk.equals(iwhatstr))
		{
			retval = ilabel;
			break;
		}
	}
	return retval;
}

// general purpose func to match string to listbox item and set selected index
void matchListboxItems(Listbox ilb, String iwhich)
{
	icc = ilb.getItemCount();
	if(icc == 0) return; // nothing.. return

	// incase of no match found, set selected index to 0 - first item
	ilb.setSelectedIndex(0);
	
	ifound = false;
	
	for(i=0; i<icc; i++)
	{
		ilabel = ilb.getItemAtIndex(i);
		
		// if match found
		if(ilabel.getLabel().equals(iwhich))
		{
			ilb.setSelectedIndex(i);
			ifound = true;
			break;
		}
	}
	
	/*
	if(ifound)
		alert("found match : " + iwhich);
	else
		alert("no match : " + iwhich);
	*/
}

void matchListboxItemsColumn(Listbox ilb, String iwhich, int icolumn)
{
	icc = ilb.getItemCount();
	if(icc == 0) return; // nothing.. return

	// incase of no match found, set selected index to 0 - first item
	ilb.setSelectedIndex(0);

	ifound = false;

	for(i=0; i<icc; i++)
	{
		ilabel = ilb.getItemAtIndex(i);

		kkk = getListcellItemLabel(ilabel, icolumn);

		// if match found
		if(kkk.equals(iwhich))
		{
			ilb.setSelectedIndex(i);
			ifound = true;
			break;
		}
	}
}

// Make a random id for component - iprestr = prefix string
String makeRandomId(String iprestr)
{
	rannum = Math.round(Math.random() * 1000);
	retval = iprestr + rannum.toString();
	
	return retval;
}

// Insert a branch/leaf onto the tree
// ibranch : have to create manually this one in caller
// ilabel : label for the branch/leaf
// istyle : label style , css thang
Treeitem insertTreeLeaf(Treechildren ibranch, String ilabel, String istyle)
{
	Treeitem titem = new Treeitem();
	Treerow newrow = new Treerow();
	Treecell newcell1 = new Treecell();
	
	newcell1.setLabel(ilabel);
	
	if(!istyle.equals(""))
		newcell1.setStyle(istyle);

	newcell1.setParent(newrow);
	newrow.setParent(titem);
	titem.setParent(ibranch);
	
	return titem;
}

Treeitem insertTreeLeaf_Multi(Treechildren ibranch, String[] ilabel_array, String istyle)
{
	Treeitem titem = new Treeitem();
	Treerow newrow = new Treerow();
	
	String[] strarray = new String[1];
	
	for(i=0; i < ilabel_array.length; i++)
	{
		Treecell newcell1 = new Treecell();
		mylabel = ilabel_array[i];
		
		newcell1.setLabel(mylabel);
		
		if(!istyle.equals("")) newcell1.setStyle(istyle);

		newcell1.setParent(newrow);
	}

	newrow.setParent(titem);
	titem.setParent(ibranch);
	
	return titem;
}

// Match item in listbox, set label for listitem
// iwhich = string to match in listbox
// cellpos = listcell position (starts 0)
// newlabel = label to set in this listcell
void matchItemUpdateLabel(Listbox ilistbox, String iwhich, int cellpos, String newlabel)
{
	for(i=0; i<ilistbox.getItemCount(); i++)
	{
		kkk = ilistbox.getItemAtIndex(i);
		kklbl = kkk.getLabel();
		
		if(kklbl.equals(iwhich))
		{
			kkchild = kkk.getChildren();
			kkchild.get(cellpos).setLabel(newlabel);
		}
	
	}
}

// Set listitem -> listcell -> icolumn -> label
// icolumn: which column, 0 = column 1
void setListcellItemLabel(Listitem ilbitem, int icolumn, String iwhat)
{
	prevrc = ilbitem.getChildren();
	prevrc_2 = prevrc.get(icolumn); // get the second column listcell
	prevrc_2.setLabel(iwhat);
}

// icolumn zero-start : 0 = column 1, 1 = column 2
// this one for listitem
String getListcellItemLabel(Listitem ilbitem, int icolumn)
{
	prevrc = ilbitem.getChildren();
	prevrc_2 = prevrc.get(icolumn);
	return prevrc_2.getLabel();
}

// Return treecell label - wcol=which column(0 start)
// 6/9/2010: try use this one
String getTreeItemLabel_Column(Treeitem titem, int wcol)
{
	retval = "";
	thechildren = titem.getChildren().toArray();
	if(thechildren.length > 0)
	{
		grandchildren = thechildren[0].getChildren().toArray();
		if(grandchildren.length >= wcol+1)
			retval = grandchildren[wcol].getLabel();
	}
	return retval;
}

// icolumn zero-start : 0 = column 1, 1 = column 2
// this one is used to get from Treeitem instead of Listitem .. hmmm, actually can combine them
String getTreecellItemLabel(Treeitem ilbitem, int icolumn)
{
	chkfirstchild = ilbitem.getChildren().get(0);
	
	prevrc = ilbitem.getChildren().get(0).getChildren().get(icolumn);
	
	if(chkfirstchild instanceof Treechildren)
	{
		// alert(ilbitem.getChildren().get(1).getChildren());
		prevrc = ilbitem.getChildren().get(1).getChildren().get(icolumn);
	}

	// prevrc = ilbitem.getChildren();
	// prevrc_2 = prevrc.get(icolumn);
	
	return prevrc.getLabel();
}

String trimListitemLabel(String istr, int maxleng)
{
	retval = istr;

	if(istr.length() > maxleng)
		retval = istr.substring(0,maxleng);

	return retval;
}

// 1/4/2010: check if iwhich is in ilb , can do column using icolumn (zero-start, check getListcellItem())
boolean ExistInListbox(Listbox ilb, String iwhich, int icolumn)
{
	icc = ilb.getItemCount();
	if(icc == 0) return false; // nothing.. return

	ifound = false;

	for(i=0; i<icc; i++)
	{
		ilabel = ilb.getItemAtIndex(i);
		
		kkk = getListcellItemLabel(ilabel, icolumn);
		
		// if match found
		if(kkk.equals(iwhich))
		{
			ifound = true;
			break;
		}
	}

	return ifound;
}

// 1/4/2010: remove an item from the listbox, iwhich = string to match, icolumn = which column to check iwhich (zero-start)
void remoteItemFromListBox(Listbox ilb, String iwhich, int icolumn)
{
	icc = ilb.getItemCount();
	if(icc == 0) return false; // nothing.. return

	for(i=0; i<icc; i++)
	{
		ilabel = ilb.getItemAtIndex(i);
		
		kkk = getListcellItemLabel(ilabel, icolumn);
		
		// if match found
		if(kkk.equals(iwhich))
		{
			// remove from listbox
			ilb.removeItemAt(i);
			break;
		}
	}

}

// Make a listbox with headers - headers stuff def in listboxHeaderObj
// mDiv = where to put the listbox
// listbox_headers = array of listboxHeaderObj
// ilistbox_id = listbox id
// numorows = how many rows to set for listbox
Listbox makeVWListbox(Div mDiv, Object[] listbox_headers, String ilistbox_id, int numorows)
{
	// if there's previously a listbox, remove before adding a new one
	Listbox oldlb = mDiv.getFellowIfAny(ilistbox_id);
	if(oldlb != null) oldlb.setParent(null);

    Listbox newlb = new Listbox();

    newlb.setId(ilistbox_id);
    newlb.setVflex(true);

	Listhead newhead = new Listhead();
    newhead.setSizable(true);
    newhead.setParent(newlb);
	
	for(i=0; i < listbox_headers.length; i++)
	{
	    Listheader mehd = new Listheader();

	    mehd.setLabel(listbox_headers[i].header_str);
		mehd.setVisible(listbox_headers[i].header_visible);
		mehd.setSort("auto");
		
		mehd.setParent(newhead);
	}
	
	newlb.setRows(numorows);
	
	newlb.setParent(mDiv);
	
	return newlb;
}

// Same as makeVWListbox but with footer string - to show number of recs or whatever
Listbox makeVWListboxWithFooter(Div mDiv, Object[] listbox_headers, String ilistbox_id, int numorows, String footstring)
{
	thelb = makeVWListbox(mDiv,listbox_headers,ilistbox_id,numorows);
	
	Listfoot newfooter = new Listfoot();
	newfooter.setParent(thelb);

	Listfooter fd1 = new Listfooter();
	fd1.setLabel("Found:");
	fd1.setParent(newfooter);

	Listfooter fd2 = new Listfooter();
	fd2.setLabel(footstring);
	fd2.setParent(newfooter);

	return thelb;
}

// GUI func: knockoff from makeVWListBox and with database access thing
// db fieldtype : 1=varchar, 2=int, 3=date
Listbox makeVWListbox_onDB(Div mDiv, Object[] listbox_headers, String ilistbox_id, int numorows, Sql isql, String isqlstm)
{
	thelb = makeVWListbox(mDiv,listbox_headers,ilistbox_id,numorows);
	dbrecs = isql.rows(isqlstm);
	if(dbrecs.size() == 0) { return thelb; } // no recs, just return a blank listbox
	for(dpi : dbrecs)
	{
		ArrayList kabom = new ArrayList();
		for(i=0; i < listbox_headers.length; i++)
		{
			ftyp = listbox_headers[i].db_fieldtype;
			ffname = listbox_headers[i].db_fieldname;
			thevalue = dpi.get(ffname);
			tobeadded = "---";
			
			if(thevalue != null)
			{
				tobeadded = thevalue;

				switch(ftyp)
				{
					case 2:
						tobeadded = thevalue.toString();
						break;
					case 3:
						tobeadded = thevalue.toString().substring(0,10);
						break;
				}
			}
			kabom.add(tobeadded);
		}
		strarray = convertArrayListToStringArray(kabom);
		insertListItems(thelb,strarray,"false");
	}
	return thelb;
}

// 26/8/2010: GUI funcs: make all listitems to accept
void setDoubleClick_ListItems(Listbox wlistbox, Object eventfunc)
{
	itmc = wlistbox.getItemCount();
	if(itmc == 0) return;

	for(i=0; i<itmc; i++)
	{
		woki = wlistbox.getItemAtIndex(i);
		woki.addEventListener("onDoubleClick", eventfunc);
	}
}

// 17/9/2010: GUI func: check if listbox exist in DIV and selected item in listbox
boolean check_ListboxExist_SelectItem(Div idiv, String lbid)
{
	retval = false;
	if(idiv.getFellowIfAny(lbid) != null)
	{
		Listbox kkb = idiv.getFellowIfAny(lbid);
		if(kkb.getSelectedIndex() != -1) retval = true;
	}

	return retval;
}

// 29/9/2010: remove whatever in a DIV by component-ID
void removeComponentInDiv(Div idiv, String compid)
{
	if(idiv.getFellowIfAny(compid) != null)
	{
		kkb = idiv.getFellow(compid);
		kkb.setParent(null);
	}
}
