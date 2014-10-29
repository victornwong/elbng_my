import java.util.*;
import java.text.*;
import java.lang.Float;
import groovy.sql.Sql;
import org.zkoss.zk.ui.*;
import org.zkoss.zk.zutl.*;
import java.math.BigDecimal;
import org.zkoss.util.media.AMedia;

SimpleDateFormat dtf = new SimpleDateFormat("yyyy-MM-dd HH:mm:ss");
SimpleDateFormat dtf2 = new SimpleDateFormat("yyyy-MM-dd");
SimpleDateFormat yearonly = new SimpleDateFormat("yyyy");
DecimalFormat nf2 = new DecimalFormat("#0.00");
DecimalFormat nf3 = new DecimalFormat("###,##0.00");
DecimalFormat nf = new DecimalFormat("###,##0.00");
DecimalFormat nf0 = new DecimalFormat("#");

// set only single listcell style - to color stuff and so on
// TODO move to listboxhandler.hava
void setListcell_Style(Listitem ilbitem, int icolumn, String istyle)
{
	List prevrc = ilbitem.getChildren();
	Listcell prevrc_2 = (Listcell)prevrc.get(icolumn); // get the second column listcell
	prevrc_2.setStyle(istyle);
}

void removeAnyChildren(Object idivholder)
{
	prvds = idivholder.getChildren().toArray();
	for(i=0;i<prvds.length;i++) // remove prev sub-divs if any
	{
		prvds[i].setParent(null);
	}
}

// itype, return value: 1=month, 2=year
int countMonthYearDiff(int itype, Object ist, Object ied)
{
	Calendar std = new GregorianCalendar();
	Calendar edd = new GregorianCalendar();
	std.setTime(ist.getValue());
	edd.setTime(ied.getValue());
	diffYear = edd.get(Calendar.YEAR) - std.get(Calendar.YEAR);
	diffMonth = diffYear * 12 + edd.get(Calendar.MONTH) - std.get(Calendar.MONTH);
	return (itype == 1) ? diffMonth : diffYear;
}

Object vMakeWindow(Object ipar, String ititle, String iborder, String ipos, String iw, String ih)
{
	rwin = new Window(ititle,iborder,true);
	rwin.setWidth(iw);
	rwin.setHeight(ih);
	rwin.setPosition(ipos);
	rwin.setParent(ipar);
	rwin.setMode("overlapped");
	return rwin;
}

void popuListitems_Data(ArrayList ikb, String[] ifl, Object ir)
{
	for(i=0; i<ifl.length; i++)
	{
		try {
		kk = ir.get(ifl[i]);
		if(kk == null) kk = "";
		else
			if(kk instanceof Date) kk = dtf2.format(kk);
		else
			if(kk instanceof Integer || kk instanceof Double) kk = nf0.format(kk);
		else
			if(kk instanceof BigDecimal)
			{
				rt = kk.remainder(BigDecimal.ONE);
				if(rt.floatValue() != 0.0)
					kk = nf2.format(kk);
				else
					kk = nf0.format(kk);
			}
		else
			if(kk instanceof Float) kk = kk.toString();
		else
			if(kk instanceof Boolean) { wi = (kk) ? "Y" : "N"; kk = wi; }
		else
			if( kk instanceof net.sourceforge.jtds.jdbc.ClobImpl) kk = sqlhand.clobToString(kk);

		ikb.add( kk );
		} catch (Exception e) {}
	}
}

String[] getString_fromUI(Object[] iob)
{
	rdt = new String[iob.length];
	for(i=0; i<iob.length; i++)
	{
		rdt[i] = "";
		try {
		if(iob[i] instanceof Textbox || iob[i] instanceof Label) rdt[i] = kiboo.replaceSingleQuotes(iob[i].getValue().trim());
		if(iob[i] instanceof Listbox) rdt[i] = iob[i].getSelectedItem().getLabel();
		if(iob[i] instanceof Datebox) rdt[i] = dtf2.format( iob[i].getValue() );
		if(iob[i] instanceof Checkbox) rdt[i] = (iob[i].isChecked()) ? "1" : "0";
		if(iob[i] instanceof Decimalbox) rdt[i] = iob[i].doubleValue().toString();
		}
		catch (Exception e) {}
	}
	return rdt;
}

void populateUI_Data(Object[] iob, String[] ifl, Object ir)
{
	for(i=0;i<iob.length;i++)
	{
		try {
		if(iob[i] instanceof Textbox || iob[i] instanceof Label)
		{
			kk = ir.get(ifl[i]);
			if(kk == null) kk = "";
			else
			if(kk instanceof Date) kk = dtf2.format(kk);
			else
			if(kk instanceof Integer || kk instanceof Double || kk instanceof BigDecimal) kk = kk.toString();
			else
			if(kk instanceof Float) kk = nf2.format(kk);

			iob[i].setValue(kk);
		}

		if(iob[i] instanceof Decimalbox)
		{
			kk = ir.get(ifl[i]);
			bd = new BigDecimal(kk);
			iob[i].setValue(bd);
		}

		if(iob[i] instanceof Checkbox)
		{
			chk = false;
			m = ir.get(ifl[i]);
			if( m != null )
			{
				if(m instanceof Boolean) chk = m;
				if(m instanceof Integer) chk = (m == 1) ? true : false;
			}
			iob[i].setChecked(chk);
		}
		if(iob[i] instanceof Listbox)
		{
			if( ir.get(ifl[i]) instanceof String)
				lbhand.matchListboxItems( iob[i], kiboo.checkNullString( ir.get(ifl[i]) ).toUpperCase() );
			else
				lbhand.matchListboxItems( iob[i], ir.get(ifl[i]).toString() );
		}
		if(iob[i] instanceof Datebox) iob[i].setValue( ir.get(ifl[i]) );
		} catch (Exception e) {}
	}
}

void clearUI_Field(Object[] iob)
{
	for(i=0; i<iob.length; i++)
	{
		if(iob[i] instanceof Textbox || iob[i] instanceof Label) iob[i].setValue("");
		if(iob[i] instanceof Datebox) kiboo.setTodayDatebox(iob[i]);
		if(iob[i] instanceof Listbox) iob[i].setSelectedIndex(0);
		if(iob[i] instanceof Checkbox) iob[i].setChecked(false);
	}
}

void disableUI_obj(Object[] iob, boolean iwhat)
{
	for(i=0; i<iob.length; i++)
	{
		iob[i].setDisabled(iwhat);
	}
}

int getWeekOfMonth(String thedate)
{
	sqlstm = "SELECT DATEPART(WEEK, '" + thedate + "') - DATEPART(WEEK, DATEADD(MM, " + 
	"DATEDIFF(MM,0,'" + thedate + "'), 0))+ 1 AS WEEK_OF_MONTH";

	krr = sqlhand.gpSqlFirstRow(sqlstm);
	if(krr == null) return -1;

	return (int)krr.get("WEEK_OF_MONTH");
}

// Lookup-func: get value1-value8 from lookup table by parent-name
String getFieldsCommaString(String iparents,int icol)
{
	aprs = luhand.getLookups_ByParent(iparents);
	retv = "";
	fld = "value" + icol.toString();
	for(di : aprs)
	{
		tpm = kiboo.checkNullString(di.get(fld));
		retv += tpm + ",";
	}

	retv = retv.replaceAll(",,",",");
	try {
	retv = retv.substring(0,retv.length()-1);
	} catch (Exception e) {}

	return retv;
}

// Merge 2 object-arrays into 1 - codes copied from some website
Object[] mergeArray(Object[] lst1, Object[] lst2)
{
	List list = new ArrayList(Arrays.asList(lst1));
	list.addAll(Arrays.asList(lst2));
	Object[] c = list.toArray();
	return c;
}

void blindTings(Object iwhat, Object icomp)
{
	itype = iwhat.getId();
	klk = iwhat.getLabel();
	bld = (klk.equals("+")) ? true : false;
	iwhat.setLabel( (klk.equals("-")) ? "+" : "-" );
	icomp.setVisible(bld);
}

void blindTings_withTitle(Object iwhat, Object icomp, Object itlabel)
{
	itype = iwhat.getId();
	klk = iwhat.getLabel();
	bld = (klk.equals("+")) ? true : false;
	iwhat.setLabel( (klk.equals("-")) ? "+" : "-" );
	icomp.setVisible(bld);

	itlabel.setVisible((bld == false) ? true : false );
}

void downloadFile(Div ioutdiv, String ifilename, String irealfn)
{
	File f = new File(irealfn);
	fileleng = f.length();
	finstream = new FileInputStream(f);
	byte[] fbytes = new byte[fileleng];
	finstream.read(fbytes,0,(int)fileleng);

	AMedia amedia = new AMedia(ifilename, "xls", "application/vnd.ms-excel", fbytes);
	Iframe newiframe = new Iframe();
	newiframe.setParent(ioutdiv);
	newiframe.setContent(amedia);
}

// Use to refresh 'em checkboxes labels -- can be used for other mods
// iprefix: checkbox id prefix, inextcount: next id count
void refreshCheckbox_CountLabel(String iprefix, int inextcount)
{
	count = 1;
	for(i=1;i<inextcount; i++)
	{
		bci = iprefix + i.toString();
		icb = items_grid.getFellowIfAny(bci);
		if(icb != null)
		{
			icb.setLabel(count + ".");
			count++;
		}
	}
}

// itype: 1=width, 2=height
gpMakeSeparator(int itype, String ival, Object iparent)
{
	sep = new Separator();
	if(itype == 1) sep.setWidth(ival);
	if(itype == 2) sep.setHeight(ival);
	sep.setParent(iparent);
}

class dropMe implements org.zkoss.zk.ui.event.EventListener
{
	public void onEvent(Event event) throws UiException
	{
		//alert(event.getDragged());
		//lbhand.getListcellItemLabel(event.getDragged(),0)
		event.getTarget().setValue( event.getDragged().getLabel() );
	}
}
droppoMe = new dropMe();

Textbox gpMakeTextbox(Object iparent, String iid, String ivalue, String istyle, String iwidth)
{
	Textbox retv = new Textbox();
	if(!iid.equals("")) retv.setId(iid);
	if(!istyle.equals("")) retv.setStyle(istyle);
	if(!ivalue.equals("")) retv.setValue(ivalue);
	if(!iwidth.equals("")) retv.setWidth(iwidth);
	retv.setDroppable("true");
	retv.addEventListener("onDrop", droppoMe);
	retv.setParent(iparent);
	return retv;
}

Button gpMakeButton(Object iparent, String iid, String ilabel, String istyle, Object iclick)
{
	Button retv = new Button();
	if(!istyle.equals("")) retv.setStyle(istyle);
	if(!ilabel.equals("")) retv.setLabel(ilabel);
	if(!iid.equals("")) retv.setId(iid);
	if(iclick != null) retv.addEventListener("onClick", iclick);
	retv.setParent(iparent);
	return retv;
}

Label gpMakeLabel(Object iparent, String iid, String ivalue, String istyle)
{
	Label retv = new Label();
	if(!iid.equals("")) retv.setId(iid);
	if(!istyle.equals("")) retv.setStyle(istyle);
	retv.setValue(ivalue);
	retv.setParent(iparent);
	return retv;
}

Checkbox gpMakeCheckbox(Object iparent, String iid, String ilabel, String istyle)
{
	Checkbox retv = new Checkbox();
	if(!iid.equals("")) retv.setId(iid);
	if(!istyle.equals("")) retv.setStyle(istyle);
	if(!ilabel.equals("")) retv.setLabel(ilabel);
	retv.setParent(iparent);
	return retv;
}

// knock from GridHandler.java (javac prob -- 19/03/2014)
void gpmakeGridHeaderColumns_Width(String[] icols, String[] iwidths, Object iparent)
{
	Columns colms = new Columns();
	for(int i=0; i<icols.length; i++)
	{
		Column hcolm = new Column();
		hcolm.setLabel(icols[i]);
		/*
		Comp asc = new Comp(true,i);
		Comp dsc = new Comp(false,i);
		hcolm.setSortAscending(asc);
		hcolm.setSortDescending(dsc);
		*/
		hcolm.setStyle("font-size:9px");
		hcolm.setWidth(iwidths[i]);
		hcolm.setParent(colms);	
	}
	colms.setParent((Component)iparent);
}

void showSystemAudit(Div ihold, String ilinkc, String isubc)
{
Object[] sysloglb_hds =
{
	new listboxHeaderWidthObj("Dated",true,"100px"),
	new listboxHeaderWidthObj("User",true,"65px"),
	new listboxHeaderWidthObj("Logs",true,""),
};
	Listbox newlb = lbhand.makeVWListbox_Width(ihold, sysloglb_hds, "syslogs_lb", 5);
	SimpleDateFormat ldtf = new SimpleDateFormat("yyyy-MM-dd HH:mm:ss");

	// check req to filter by linking_sub
	chksub = " and linking_sub='" + isubc + "' ";
	if(isubc.equals("")) chksub = "";

	sqlstm = "select datecreated,username,audit_notes from elb_systemaudit where " +
	"linking_code='" + ilinkc + "'" + chksub + "order by datecreated desc";

	sylog = sqlhand.gpSqlGetRows(sqlstm);
	if(sylog.size() == 0) return;
	newlb.setRows(10); newlb.setMold("paging");
	//newlb.addEventListener("onSelect", new tkslbClick());
	ArrayList kabom = new ArrayList();
	for(dpi : sylog)
	{
		kabom.add( ldtf.format(dpi.get("datecreated")) );
		kabom.add(kiboo.checkNullString(dpi.get("username")));
		kabom.add(kiboo.checkNullString(dpi.get("audit_notes")));
		lbhand.insertListItems(newlb,kiboo.convertArrayListToStringArray(kabom),"false","");
		kabom.clear();
	}
}

