// all funcs use global_loaded_quote - must def in main
void showFeedbacks()
{
	Object[] quote_feedbacks_lb_headers = {
		new listboxHeaderWidthObj("origid",false,""),
		new listboxHeaderWidthObj("Dated",true,"90px"),
		new listboxHeaderWidthObj("Feedback",true,""),
		new listboxHeaderWidthObj("Poster",true,"100px"),
	};

	if(global_loaded_quote.equals("")) return;
	Listbox newlb = lbhand.makeVWListbox_Width(feedback_holder, quote_feedbacks_lb_headers, "quote_feedbacks_lb", 3);
	feedbacks_div.setVisible(true);

	sqlstm = "select * from elb_quotation_track where parent_quote=" + global_loaded_quote + " order by datecreated desc";
	qitems = sqlhand.gpSqlGetRows(sqlstm);
	if(qitems.size() == 0) return;
	newlb.setRows(21);
	newlb.setMold("paging");
	//newlb.addEventListener("onSelect", new quote_items_lb_Listener());
	ArrayList kabom = new ArrayList();
	String[] fl = { "origid", "datecreated", "notes", "username" };
	for(dpi : qitems)
	{
		popuListitems_Data(kabom,fl,dpi);
		lbhand.insertListItems(newlb,kiboo.convertArrayListToStringArray(kabom),"false","");
		kabom.clear();
	}
}

void updateWinLoseFlag_clicker()
{
	if(global_loaded_quote.equals("")) return;
	theflag = quote_winloseflag.getSelectedItem().getLabel();
	todate = kiboo.getDateFromDatebox(hiddendatebox);
	sqlstm = "update elb_quotations set winloseflag='" + theflag + "', userpostwinlose='" + useraccessobj.username + "'," + 
	"postwinlosedate='" + todate + "' where origid=" + global_loaded_quote;
	sqlhand.gpSqlExecuter(sqlstm);
	//showQuotations_Listbox(last_loadtype); // refresh
	showQuotations_Listbox(old_show_quote); // refresh
}

void clearQuoteFeedback_fields()
{
	global_selected_feedback = "";
	kiboo.setTodayDatebox(feedback_date);
	feedback.setValue("");
}

void saveQuoteFeedback_clicker()
{
	if(global_loaded_quote.equals("")) return;
	thefeedback = kiboo.replaceSingleQuotes(feedback.getValue().trim());
	if(thefeedback.equals("")) return;

	sqlstm = "insert into elb_quotation_track (parent_quote,datecreated,notes,username) values (" +
	global_loaded_quote + ",'" + kiboo.todayISODateTimeString() + "','" + thefeedback + "','" + useraccessobj.username + "')";

	sqlhand.gpSqlExecuter(sqlstm);
	showFeedbacks(); // refresh
}

void printQuoteTracks()
{
	uniqid = kiboo.makeRandomId("pqt");
	guihand.globalActivateWindow(mainPlayground,"miscwindows","sales/printquotetrack.zul", uniqid, "", useraccessobj);
	//showMessageBox("Wait.. going to fix the output");
}
