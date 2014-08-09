// Customer-support mod's funcs

void trackiFunc(String itype)
{
	todaydate = kiboo.todayISODateTimeString();
	refresh = false;
	sqlstm = msgtext = "";

	if(itype.equals("deltracki_b"))
	{
		if(glob_sel_tracki.equals("")) return;
		sqlstm = "delete from elb_usertracki where origid=" + glob_sel_tracki;
		refresh = true;
	}

	if(!sqlstm.equals("")) sqlhand.gpSqlExecuter(sqlstm);
	if(refresh) manListTracki(glob_username);
	if(!msgtext.equals("")) guihand.showMessageBox(msgtext);
}

class mtrckiclike implements org.zkoss.zk.ui.event.EventListener
{
	public void onEvent(Event event) throws UiException
	{
		isel = event.getReference();
		glob_sel_tracki = lbhand.getListcellItemLabel(isel,0);
	}
}
mtrcklbcliker = new mtrckiclike();

Object[] mtrakihds =
{
	new listboxHeaderWidthObj("origid",false,""),
	new listboxHeaderWidthObj("AR_Code",true,"90px"),
	new listboxHeaderWidthObj("Customer",true,""),
};
void manListTracki(String iuser)
{
	Listbox newlb = lbhand.makeVWListbox_Width(mtrackiholder, mtrakihds, "trackiman_lb", 3);
	sqlstm = "select t.origid, t.ar_code, c.customer_name from elb_usertracki t " +
	"left join customer c on c.ar_code = t.ar_code " +
	"where t.username='" + iuser + "' order by c.customer_name";
	recs = sqlhand.gpSqlGetRows(sqlstm);
	if(recs.size() == 0) return;
	newlb.setRows(21);
	newlb.setMold("paging");
	newlb.addEventListener("onSelect", mtrcklbcliker );
	ArrayList kabom = new ArrayList();
	String[] fl = { "origid", "ar_code", "customer_name" };
	for(d : recs)
	{
		popuListitems_Data(kabom,fl,d);
		lbhand.insertListItems(newlb,kiboo.convertArrayListToStringArray(kabom),"false","");
		kabom.clear();
	}
}

Object[] actionlbhds = // refer to internalTasks_v2.zul
{
	new listboxHeaderWidthObj("Dated",true,"140px"),
	new listboxHeaderWidthObj("Action",true,""),
	new listboxHeaderWidthObj("Who",true,"70px"),
};
void showTrackiTasks(String iar)
{
	// check if already have company-wide int-tasks entry, if not, create 1
	sqlstm = "if exists (select origid from rw_int_tasks where linking_code='TRACKI' and linking_sub='" + iar + "') " +
	"print 'ok' ELSE " +
	"insert into rw_int_tasks (datecreated,assigner,assignee,task,linking_code,linking_sub,priority,done,action,action_date,action_who) values " +
	"('" + kiboo.todayISODateTimeString() + "','ELB','ELB','TRACKI ENTRY','TRACKI','" + iar + "'," +
	"'NORMAL',0,'','','');";

	sqlhand.gpSqlExecuter(sqlstm);

	glob_sel_inttask = "";

	sqlstm = "select origid, t_notes, task, action, action_date, action_who from rw_int_tasks " +
	"where assigner='ELB' and assignee='ELB' and linking_code='TRACKI' and linking_sub='" + iar + "'";
	r = sqlhand.gpSqlFirstRow(sqlstm);
	if(r == null) return;

	glob_sel_inttask = r.get("origid").toString();

	//t_notes.setValue( kiboo.checkNullString(r.get("t_notes")) );
	//t_task.setValue( r.get("task") );

	// show 'em actions
	acts = sqlhand.clobToString(r.get("action")).split("~");
	actd = sqlhand.clobToString(r.get("action_date")).split("~");
	actw = sqlhand.clobToString(r.get("action_who")).split("~");

	if(acts.length > 0) // have some actions -- show
	{
		Listbox newlb = lbhand.makeVWListbox_Width(actions_holder, actionlbhds, "actions_lb", 21);
		newlb.setMold("paging");
		ArrayList kabom = new ArrayList();
		for(i=0; i<acts.length; i++)
		{
			try { a1 = kiboo.checkNullString(actd[i]); } catch (Exception e) { a1 = ""; }
			try { a2 = kiboo.checkNullString(acts[i]); } catch (Exception e) { a2 = ""; }
			try { a3 = kiboo.checkNullString(actw[i]); } catch (Exception e) { a3 = ""; }

			kabom.add( a1 );
			kabom.add( a2 );
			kabom.add( a3 );
			lbhand.insertListItems(newlb,kiboo.convertArrayListToStringArray(kabom),"false","");
			kabom.clear();
		}
	}
}

void taskerFunc(String itype) // can be used in other mods
{
	todaydate =  kiboo.todayISODateTimeString();
	refresh = refreshmeta = false;
	sqlstm = msgtext = "";
	unm = useraccessobj.username;

	if(itype.equals("addaction_b"))
	{
			if(glob_sel_inttask.equals("")) return;
			kk = kiboo.replaceSingleQuotes(addaction_tb.getValue().trim()).replaceAll("~"," ");
			if(kk.equals("")) return;

			sqlstm = "update rw_int_tasks set action = convert(varchar(max),action) + '" + kk + "~', action_date = convert(varchar(max),action_date) + '" + todaydate + 
			"~', action_who = convert(varchar(max),action_who) + '" + unm + "~' where origid="  + glob_sel_inttask;

			refresh = true;
			addaction_tb.setValue(""); // clear for next action
	}

	if(itype.equals("setnxtactd_b"))
	{
		if(glob_sel_inttask.equals("")) return;
		kk = kiboo.replaceSingleQuotes(t_nextaction.getValue().trim());
		ndt = kiboo.getDateFromDatebox(t_nextactiondate);
		sqlstm = "update rw_int_tasks set nextactiondate='" + ndt + "', nextaction='" + kk + "' where origid=" + glob_sel_inttask;
		refreshmeta = true;
	}

	if(!sqlstm.equals("")) sqlhand.gpSqlExecuter(sqlstm);
	if(refresh) showTrackiTasks(glob_sel_arcode);
	if(refreshmeta) suppWholeList();
	if(!msgtext.equals("")) guihand.showMessageBox(msgtext);
}

// quote-items listing contain mysoftcode which can be imported during test-assignment
// itype: 1=show qt meta, 0=don't how qt meta
void digShowQuotation(String iqt, Div idiv, String ilbid, int itype ) // knockoff from samplereg
{
Object[] qt_headers =
{
	new listboxHeaderObj("origid",false),
	new listboxHeaderObj("mysoftcode",false),
	new listboxHeaderObj("No.",true),
	new listboxHeaderObj("Tests",true),
	new listboxHeaderObj("Method.Ref",true),
	new listboxHeaderObj("Stk",true),
	new listboxHeaderObj("LOR",true),
	new listboxHeaderObj("U.P",true),
	new listboxHeaderObj("Qty",true),
	new listboxHeaderObj("Dsct",true),
	new listboxHeaderObj("Gross",true),
	new listboxHeaderObj("Nett",true),
};
	if(itype == 1)
	{
	// fill the quote metadata
		sqlstm = "select datecreated,username,salesperson,customer_name,winloseflag from elb_quotations " +
		"where origid=" + iqt + " and qstatus<>'NEW'";
		qrec = sqlhand.gpSqlFirstRow(sqlstm);
		if(qrec == null) return;
		qt_origid.setValue("QT" + iqt);
		qt_username.setValue(qrec.get("username"));
		qt_salesperson.setValue(qrec.get("salesperson"));
		qt_customer_name.setValue(qrec.get("customer_name"));
		qt_datecreated.setValue(qrec.get("datecreated").toString().substring(0,10));

		lbhand.matchListboxItemsColumn(quote_winloseflag, kiboo.checkNullString(qrec.get("winloseflag")), 0);

	}

	Listbox newlb = lbhand.makeVWListbox(quoteitems_holder, qt_headers, "quoteitems_lb", 5);

	sqlstm = "select origid,mysoftcode,description,description2,LOR,unitprice,quantity," + 
	"discount,total_gross,total_net from elb_quotation_items where quote_parent=" + iqt + " order by origid";
	qtrecs = sqlhand.gpSqlGetRows(sqlstm);
	if(qtrecs.size() == 0) return;
	newlb.setRows(21);
	newlb.setMold("paging");
	lncn = 1;
	ArrayList kabom = new ArrayList();
	String[] fl = { "origid", "mysoftcode", "lor", "description", "description2", "lor", "lor", "unitprice", "quantity", "discount", "total_gross", "total_net" };
	lnposi = 2; stkposi = 5; rowcounter = 1;

	for(dpi : qtrecs)
	{
		popuListitems_Data(kabom,fl,dpi);

		//grandtotal += dpi.get("total_net");
		mysc = dpi.get("mysoftcode").toString();
		stkitem = (mysc.equals("") || mysc.equals("0")) ? "---" : "-Y-";

		ki = lbhand.insertListItems(newlb, kiboo.convertArrayListToStringArray(kabom), "false", "");
		lbhand.setListcellItemLabel(ki, lnposi, rowcounter.toString() + ".");
		lbhand.setListcellItemLabel(ki, stkposi, stkitem);

		rowcounter++;
		kabom.clear();
	}

	quotation_workarea.setVisible(true);
}
