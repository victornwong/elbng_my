//--- quotation version control thing --
// -victor
void makeNewVersion()
{
	if(global_loaded_quote.equals("")) return;

	bvernum = (Integer.parseInt(global_quote_version) + 1).toString();
	// make dup and inc the version num
	sqlstm = "insert into elb_quotation_items (mysoftcode,description,description2, lor, quote_parent, quantity,curcode,unitprice," +
	"discount, total_net, total_gross,field1, field2, field3,field4, field5, version) " +
	"select mysoftcode,description,description2, lor, quote_parent, quantity,curcode,unitprice,discount, total_net, total_gross," +
	"field1, field2, field3,field4, field5, version + 1 from elb_quotation_items " +
	"where quote_parent=" + global_loaded_quote + " and version=" + global_quote_version + ";";

	sqlstm += "update elb_quotations set version=" + bvernum + ", qstatus='" + QTSTAT_NEW + "' where origid=" + global_loaded_quote;
	sqlhand.gpSqlExecuter(sqlstm);

	global_quote_version = bvernum;
	quote_version.setValue(global_quote_version);

	// have to refresh quotes-listbox !!!! and clear metadata.. get user to re-select
	showQuotations_Listbox(0); // refresh lor
	qt_metadata_div.setVisible(false);

}

void loadPreviousVersion()
{
	if(global_loaded_quote.equals("")) return;
	
	Object[] sm_lb_headers = {
	new dblb_HeaderObj("verstr",true,"version",2),
	};
	sql = sqlhand.als_mysoftsql();
	if(sql == null) return;
	sqlstm = "select distinct version from elb_quotation_items where quote_parent=" + global_loaded_quote + " order by version desc";
	Listbox newlb = lbhand.makeVWListbox_onDB(ldver_holder,sm_lb_headers,"qt_versiondd",1,sql,sqlstm);
	sql.close();
	newlb.setMold("select");
	newlb.setStyle("font-size:9px");
	newlb.setSelectedIndex(0); // default

	loadquotever_popup.open(loadquotever_butt);
}

void realLoadPrevVersion()
{
	global_selected_versiontoload = qt_versiondd.getSelectedItem().getLabel();
	global_version_edit = false; // always set to non-editable when load diff version

	// current-version = true, can edit
	if(currentQuoteVersion(global_loaded_quote, global_selected_versiontoload)) global_version_edit = true;

//alert(global_selected_versiontoload + " :: " + currver + " :: " + global_version_edit);
	quote_version.setValue(global_selected_versiontoload);
	showQuoteItems(2);
}
