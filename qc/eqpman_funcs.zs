import java.util.*;
import java.text.*;
import org.victor.*;

// @Title Equipment manager general funcs
// @Author Victor Wong

Object getEquip_rec(String iwhat)
{
	sqlstm = "select * from elb_equipments where origid=" + iwhat;
	return sqlhand.gpSqlFirstRow(sqlstm);
}

void loadEqGroup(Object icombo)
{
	sqlstm = "select distinct eqgroup from elb_equipments";
	ngfun.fillComboboxUniq(sqlstm,"eqgroup",icombo);
}

// Make grid for check-in
void checkMakeItemsGrid()
{
	String[] colws = { "70px","" };
	String[] colls = { "AssetTag", "Usage Notes" };

	if(ci_things_holder.getFellowIfAny("chkin_grid") == null) // make new grid if none
	{
		igrd = new Grid();
		igrd.setId("chkin_grid");
		icols = new org.zkoss.zul.Columns();
		for(i=0;i<colws.length;i++)
		{
			ico0 = new org.zkoss.zul.Column();
			ico0.setWidth(colws[i]);
			ico0.setLabel(colls[i]);
			//if(i != 1 || i != 2) ico0.setAlign("center");
			ico0.setStyle("background:#97b83a;color:#1D3BA0");
			ico0.setParent(icols);
		}
		icols.setParent(igrd);
		irows = new org.zkoss.zul.Rows();
		irows.setId("chkin_rows");
		irows.setParent(igrd);
		igrd.setParent(ci_things_holder);
	}
}

void viewEquipLogs()
{
	if(glob_sel_assettag.equals("")) return;
	showSystemAudit(logsholder,EQUIPMAN_ID,glob_sel_assettag);
	equiplogs_pop.open(glob_sel_li);
}

void showEqModi()
{
	if(glob_sel_equip.equals("")) return;
	er = getEquip_rec(glob_sel_equip);
	if(er == null) return;
	loadEqGroup(m_eqgroup); // reload group combos
	m_purchasedate.setValue(er.get("purchasedate"));
	m_description.setValue(er.get("description"));
	m_asset_tag.setValue(er.get("asset_tag"));
	m_eqgroup.setValue(er.get("eqgroup"));

	lbhand.matchListboxItems(m_eqstatus, er.get("eqstatus"));

	modiequip_pop.open(glob_sel_li);
}

Object[] eqlbhds = {
	new listboxHeaderWidthObj("AssetTag",true,"100px"),
	new listboxHeaderWidthObj("origid",false,""),
	new listboxHeaderWidthObj("Description",true,""),
	new listboxHeaderWidthObj("Group",true,"90px"),
	new listboxHeaderWidthObj("Atv",true,"40px"),
	new listboxHeaderWidthObj("Stat",true,"50px"),
	new listboxHeaderWidthObj("Usage Notes",true,""),
	new listboxHeaderWidthObj("CheckOut",true,"70px"),
	new listboxHeaderWidthObj("CO.Date",true,"70px"),
	new listboxHeaderWidthObj("Proj/Loca",true,"120px"),
	new listboxHeaderWidthObj("Action",true,"120px"),
	new listboxHeaderWidthObj("Act.Date",true,"70px"),
};
ACTDATEPOS = 10;

class eqplbcliker implements org.zkoss.zk.ui.event.EventListener
{
	public void onEvent(Event event) throws UiException
	{
		try {
		glob_sel_li = event.getReference();
		glob_sel_assettag = lbhand.getListcellItemLabel(glob_sel_li,0);
		glob_sel_equip = lbhand.getListcellItemLabel(glob_sel_li,1);
		} catch (Exception e) {}
	}
}
eqplbcliker = new eqplbcliker();

class eqpdobcliker implements org.zkoss.zk.ui.event.EventListener
{
	public void onEvent(Event event) throws UiException
	{
		try {
		glob_sel_li = event.getTarget();
		showEqModi();
		} catch (Exception e) {}
	}
}
eqpdoublecliker = new eqpdobcliker();

// itype: 1=load all or by searchtext, 2=by equip group
void equips_Listbox(int itype)
{
	last_eq_list_type = itype;

	Listbox newlb = lbhand.makeVWListbox_Width(eqlb_holder, eqlbhds, "equips_lb", 3);
	st = kiboo.replaceSingleQuotes(serchtxt.getValue());
	eqg = epgroup_dd.getSelectedItem().getLabel();
/*
	sdate = kiboo.getDateFromDatebox(startdate);
	edate = kiboo.getDateFromDatebox(enddate);
	qtnum = kiboo.replaceSingleQuotes(qtnumber_search.getValue());
	byusercreated = quotemaker_user_lb.getSelectedItem().getLabel();
*/
	whstr = "";

	if(itype == 1 && !st.equals(""))
		whstr = "where asset_tag like '%" + st + "%' or description like '%" + st + "%' or project like '%" + st + "%' or " +
		"action like '%" + st + "%' or checkoutby like '%" + st + "%' ";

	if(itype == 2)
		whstr = "where eqgroup='" + eqg + "' ";

	sqlstm = "select origid,asset_tag,description,checkoutby,checkout,project,action,actiondate,active,eqgroup,eqstatus,usage_notes from elb_equipments " +
	whstr +
	"order by asset_tag";

	r = sqlhand.gpSqlGetRows(sqlstm);
	if(r.size() == 0) return;
	newlb.setMold("paging"); newlb.setRows(20);
	newlb.setCheckmark(true); newlb.setMultiple(true);
	newlb.addEventListener("onSelect", eqplbcliker);
	ArrayList kabom = new ArrayList();
	String[] fl = { "asset_tag", "origid", "description", "eqgroup", "active", "eqstatus", "usage_notes", "checkoutby","checkout","project","action","actiondate" };
	for(d : r)
	{
		ngfun.popuListitems_Data(kabom, fl, d);
		lbhand.insertListItems(newlb, kiboo.convertArrayListToStringArray(kabom), "false", "");
		kabom.clear();
	}
	lbhand.setDoubleClick_ListItems(newlb, eqpdoublecliker);
	colorizeActionDates();
	glob_sel_equip = glob_sel_assettag = ""; glob_sel_li = null;

} // end equips_Listbox()

void colorizeActionDates()
{
	kk = equips_lb.getItems().toArray();

	Calendar cal_chks = Calendar.getInstance(); // checking date
	Calendar cal_chke = Calendar.getInstance();
	Date todate = GlobalDefs.dtf2.parse(GlobalDefs.dtf2.format(new Date()));

	for(i=0;i<kk.length;i++)
	{
		try
		{
			tdt = lbhand.getListcellItemLabel(kk[i],ACTDATEPOS);
			adate = GlobalDefs.dtf2.parse(tdt);

			if(adate.compareTo(todate) == 0 || adate.compareTo(todate) < 0) // due-date is today or less then today
			{
				kk[i].setStyle("color:#ffffff;background:#D51010;font-weight:bold;");
				continue;
			}

			cal_chks.setTime(todate);
			cal_chke.setTime(todate);
			cal_chks.add(Calendar.DAY_OF_MONTH,7);
			cal_chke.add(Calendar.DAY_OF_MONTH,14);

			if( adate.compareTo( cal_chks.getTime() ) >= 0 && adate.compareTo( cal_chke.getTime() ) <= 0 )
			{
				kk[i].setStyle("background:#ED7D12;font-weight:bold");
				continue;
			}

			cal_chks.add(Calendar.DAY_OF_MONTH,8);
			cal_chke.add(Calendar.DAY_OF_MONTH,16);
			if( adate.compareTo( cal_chks.getTime() ) >= 0 && adate.compareTo( cal_chke.getTime() ) <= 0 )
			{
				kk[i].setStyle("background:#E1D70E;font-weight:bold");
				continue;
			}
		}
		catch (Exception e) {}
	}
}