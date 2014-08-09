import org.victor.*;
// Internal tasks managmenet funcs
// Written by Victor Wong : 04/12/2013

glob_sel_inttask = ""; // glob internal-task selected
glob_sel_taskowner = "";

void insertInternalTask(String ilink, String isublink, String itaskstr, String iassigner, String iassignee)
{
	kk = kiboo.replaceSingleQuotes( itaskstr.trim() );
	if(kk.equals("")) return;
	sqlstm = "insert into rw_int_tasks (datecreated,assigner,assignee,task,linking_code,linking_sub,priority,done,action,action_date,action_who) values " +
	"('" + kiboo.todayISODateTimeString() + "','" + iassigner + "','" + iassignee + "','" + kk + "','" + ilink + "','" + isublink + "'," +
	"'NORMAL',0,'','','');";

	sqlhand.gpSqlExecuter(sqlstm);
	guihand.showMessageBox("Task/To-Do inserted");
}

void actInternalTasks()
{
	guihand.globalActivateWindow(mainPlayground, "miscwindows", "collab/internalTasks_v2.zul",
		kiboo.makeRandomId("itx"), "", useraccessobj);
}

// knockoff from menueditor_v1.zul -- need to put into lib
void listUsernames(Object ilistbox)
{
	sqlstm = "select distinct username from portaluser where locked=0 and deleted=0 order by username";
	recs = sqlhand.gpSqlGetRows(sqlstm);
	if(recs.size() == 0) return;
	ArrayList kabom = new ArrayList();
	for(d : recs)
	{
		kabom.add(d.get("username"));
		lbhand.insertListItems(ilistbox,kiboo.convertArrayListToStringArray(kabom),"false","");
		kabom.clear();
	}
	lbhand.matchListboxItems(ilistbox,glob_taskowner);
}

String JN_linkcode()
{
	return "";
}

void internaltask_callback() // def call-back - have to def in other mods which need this callback
{
}

Object[] actionlbhds =
{
	new listboxHeaderWidthObj("Dated",true,"120px"),
	new listboxHeaderWidthObj("Action",true,""),
	new listboxHeaderWidthObj("Who",true,"70px"),
};

Object showTaskActions(Div idiv, String ilink, String isublink, Object nxtactiondate_label, Object nxtaction_label)
{
	sqlstm = "select origid, nextactiondate, nextaction, action, action_date, action_who from rw_int_tasks where linking_code='" + ilink + 
	"' and linking_sub='" + isublink + "'";
	r = sqlhand.gpSqlFirstRow(sqlstm);
	if(r == null) return null;

	ndd = "";
	try { ndd = dtf2.format(r.get("nextactiondate")); } catch (Exception e) {}
	nxtactiondate_label.setValue(ndd);
	nxtaction_label.setValue(kiboo.checkNullString(r.get("nextaction")));

	// show 'em actions
	acts = sqlhand.clobToString(r.get("action")).split("~");
	actd = sqlhand.clobToString(r.get("action_date")).split("~");
	actw = sqlhand.clobToString(r.get("action_who")).split("~");

	if(acts.length > 0) // have some actions -- show
	{
		Listbox newlb = lbhand.makeVWListbox_Width(idiv, actionlbhds, "actions_lb", 5);
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
	return r; // return to caller -- check and insert new if null
}

Object[] inttskslb_hds =
{
	new listboxHeaderWidthObj("Tsk#",true,"50px"),
	new listboxHeaderWidthObj("Dated",true,"65px"),
	new listboxHeaderWidthObj("Assigner",true,"80px"), // 2
	new listboxHeaderWidthObj("Assignee",true,"80px"),
	new listboxHeaderWidthObj("Priority",true,"60px"),
	new listboxHeaderWidthObj("Task",true,""),
	new listboxHeaderWidthObj("Action",true,""),
	new listboxHeaderWidthObj("A.Date",true,"65px"),
	new listboxHeaderWidthObj("Link",true,"70px"),
	new listboxHeaderWidthObj("Done",true,"35px"), // 9
};

class inttskclk implements org.zkoss.zk.ui.event.EventListener
{
	public void onEvent(Event event) throws UiException
	{
		isel = event.getReference();
//class ctxopen implements org.zkoss.zk.ui.event.EventListener
		glob_sel_inttask = lbhand.getListcellItemLabel(isel,0);
		glob_sel_taskowner = lbhand.getListcellItemLabel(isel,2);
		kdn = lbhand.getListcellItemLabel(isel,9); // done flag

		if(isel.getFellowIfAny("intmytaskno_lbl") != null)
		{
			intmytaskno_lbl.setValue("Task# : " + glob_sel_inttask);
		}

		//intmytaskno_lbl.setValue("Task# : " + glob_sel_inttask);

		if(isel.getFellowIfAny("saveaction_b") != null)
		{
			saveaction_b.setDisabled( (kdn.equals("Y")) ? true : false);
		}
	}
}
inttaskclicker = new inttskclk();
inttask_lastdate = "";

// itype: 1=assigner tasks, 2=not-assigner tasks
void showInternalTasksList(int itype, String iassigner, String lnkcode, String istdate, Div idiv, String lbid)
{
	Listbox newlb = lbhand.makeVWListbox_Width(idiv, inttskslb_hds, lbid, 12);
	inttask_lastdate = istdate;
	glob_sel_inttask = ""; // reset

	sqlstm = "select origid,assignee,assigner,datecreated,task,action,actiondate,done,priority,linking_code from rw_int_tasks ";
	switch(itype)
	{
		case 1:
			sqlstm += "where assigner='" + iassigner + "'";
			break;
		case 2:
			sqlstm += "where assignee='" + iassigner + "' and done=0 ";
			break;
	}
	
	lnkc = (lnkcode.equals("")) ? "" : " and linking_code='" + lnkcode + "' ";
	dtsq = (istdate.equals("")) ? "" : " and datecreated >= '" + istdate + "' ";

	sqlstm += lnkc + dtsq + " order by datecreated";
	
	recs = sqlhand.gpSqlGetRows(sqlstm);
	if(recs.size() == 0) return;
	newlb.setMold("paging");
	newlb.addEventListener("onSelect", inttaskclicker );
	String[] fl = { "origid", "datecreated", "assigner", "assignee", "priority", "task", "action", "actiondate", "linking_code", "done" };
	ArrayList kabom = new ArrayList();
	for(d : recs)
	{
		popuListitems_Data(kabom,fl,d);
		prty = kiboo.checkNullString(d.get("priority"));
		styl = "";
		if(prty.equals("URGENT")) styl = "font-size:9px;background:#f57900;color:#ffffff;font-weight:bold";
		if(prty.equals("CRITICAL")) styl = "font-size:9px;background:#ef2929;color:#ffffff;font-weight:bold";

		lbhand.insertListItems(newlb,kiboo.convertArrayListToStringArray(kabom),"false",styl);
		kabom.clear();
	}
}

// Can be used for other mods -- remember the popup
void internalTasksDo(Object iwhat)
{
	itype = iwhat.getId();
	todaydate =  kiboo.todayISODateTimeString();
	refresh_byme = refresh_forme = docallback = false;
	sqlstm = msgtext = "";

	lnkc = "";
	try { lnkc = JN_linkcode(); } catch (Exception e) {}

	if(itype.equals("saveinttask_b"))
	{
		tsk = kiboo.replaceSingleQuotes(assignto_task.getValue().trim());
		asgnee = intassignto_lb.getSelectedItem().getLabel();
		if(tsk.equals("")) msgtext = "You have not enter anything for " + asgnee + " to do..";
		else
		{
			prty = inttaskprio_lb.getSelectedItem().getLabel();
			sqlstm = "insert into rw_int_tasks (assigner,assignee,task,datecreated,done,linking_code,priority) values " +
			"('" + useraccessobj.username + "','" + asgnee + "','" + tsk + "','" + todaydate + "',0,'" + lnkc + "'," +
			"'" + prty + "')";

			assignto_task.setValue("");
			msgtext = "Task assigned..";
			docallback = true;
		}
	}

	if(itype.equals("delinttask_b"))
	{
		if(glob_sel_inttask.equals("")) return;
		if (Messagebox.show("This will delete the internal-task..", "Are you sure?", 
			Messagebox.YES | Messagebox.NO, Messagebox.QUESTION) !=  Messagebox.YES) return;

		sqlstm = "delete from rw_int_tasks where origid=" + glob_sel_inttask;
		docallback = true;
	}

	if(itype.equals("clearinttask_b"))
	{
		intassignto_lb.setSelectedIndex(0);
		inttaskprio_lb.setSelectedIndex(0);
		assignto_task.setValue("");
	}

	if(itype.equals("settaskdone_b"))
	{
		if(glob_sel_inttask.equals("")) return;
		if(useraccessobj.accesslevel < 8 && !glob_sel_taskowner.equals(useraccessobj.username)) return;
		sqlstm = "update rw_int_tasks set done=1-done where origid=" + glob_sel_inttask;
		refresh_byme = true;
	}

	if(itype.equals("saveaction_b"))
	{
		if(glob_sel_inttask.equals("")) return;
		acts = kiboo.replaceSingleQuotes(inttask_action.getValue().trim());
		if(acts.equals("")) return;
		sqlstm = "update rw_int_tasks set action='" + acts + "', " +
		"actiondate='" + todaydate + "' where origid=" + glob_sel_inttask;
		msgtext = "Action posted..";
		inttask_action.setValue("");
		refresh_forme = true;
	}

	if(!sqlstm.equals("")) sqlhand.gpSqlExecuter(sqlstm); // alert(sqlstm);
	if(refresh_byme) showInternalTasksList(1,useraccessobj.username, lnkc, "", tasksfromyou_holder, "asstasks_lb");
	if(refresh_forme) showInternalTasksList(2, useraccessobj.username, "", inttask_lastdate, tasksforyou_holder, "yourtasks_lb" );
	if(!msgtext.equals("")) guihand.showMessageBox(msgtext);
	if(docallback) internaltask_callback();

}

// Inject task - general purpose , can be used by others
void injInternalTask(String iassner, String iassnee, String itask, String ilnc, String iprty)
{
	todaydate =  kiboo.todayISODateTimeString();
	sqlstm = "insert into rw_int_tasks (assigner,assignee,task,datecreated,done,linking_code,priority) values (" +
	"'" + iassner + "','" + iassnee + "','" + itask + "','" + todaydate + "',0,'" + ilnc + "','" + iprty + "');";

	sqlhand.gpSqlExecuter(sqlstm);
}
