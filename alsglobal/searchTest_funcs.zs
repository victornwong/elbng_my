/*
-------- search stock items, ALS version .. can be used in other mods -- remember the popup too
Assuming all the proper UI objects are def in the module. Check endof file for popup codes
knockoff from assign_tests_v2.zul
*/
void autoAssignTestParametersBox(String imysoftcode)
{
	istockrec = samphand.getStockMasterDetails(imysoftcode);
	if(istockrec == null) return;

	istockcat = istockrec.get("Stock_Cat");
	igroupcode = istockrec.get("GroupCode");

	testspanel.populateSectionColumn(istockcat);
	testspanel.populateTestParametersColumn(istockcat,igroupcode);

	// auto-select the thing in the listboxes.. tricky part
	divisionln = convertCodeToLongName(als_divisions,istockcat);
	lbhand.matchListboxItems(division_stockcat_lb, divisionln);
	lbhand.matchListboxItems(section_groupcode_lb, igroupcode);
	tscode = istockrec.get("ID").toString();
	lbhand.matchListboxItems(tests_description_lb,tscode);
}

class itemsearchDoubleClick_Listener implements org.zkoss.zk.ui.event.EventListener
{
	public void onEvent(Event event) throws UiException
	{
		selitem = founditems_lb.getSelectedItem();
		selected_test = lbhand.getListcellItemLabel(selitem,0);
		autoAssignTestParametersBox(selected_test);
		//showStockItem_Metadata(selected_test);
		//newstockitem_btn.setLabel("Update test/sale item"); // change button label if item selected
		searchitem_popup.close();
	}
}
itmsrchdcliker = new itemsearchDoubleClick_Listener();

void searchStockItem_clicker()
{
Object[] finditems_lb_headers = {
	new dblb_HeaderObj("mysoftcode",false,"id",2),
	new dblb_HeaderObj("Stock.Code",true,"stock_code",1),
	new dblb_HeaderObj("Test",true,"description",1),
	new dblb_HeaderObj("Method",true,"description2",1),
	new dblb_HeaderObj("Division",true,"stock_cat",1),
	new dblb_HeaderObj("Section",true,"groupcode",1),
	};
	srchstr = kiboo.replaceSingleQuotes(itemsearch_text.getValue().trim());
	if(srchstr.equals("")) return;

	sql = sqlhand.als_mysoftsql();
	if(sql == null) return;

	sqlstatem = "select id,stock_code,description,description2,stock_cat,groupcode from stockmasterdetails " + 
		"where item_type='Service Item' and nominal_code like '5%' " +
		"and (stock_code like '%" + srchstr + "%' or description like '%" + srchstr + "%' or description2 like '%" + srchstr + "%') " +
		"order by description" ;

	Listbox newlb = lbhand.makeVWListbox_onDB(founditems_holder,finditems_lb_headers,"founditems_lb",5,sql,sqlstatem);
	sql.close();

	if(newlb.getItemCount() > 0)
	{
		newlb.setRows(10);
		lbhand.setDoubleClick_ListItems(newlb, itmsrchdcliker);
	}
}

/*
<!-- stock items search popup -->
<popup id="searchitem_popup">
<div sclass="shadowbox" style="background:#EDC40E" width="600px">
	<hbox>
		<label value="Search item" sclass="k9" />
		<textbox id="itemsearch_text" sclass="k9" width="200px" />
		<button label="Find" sclass="k9" onClick="searchStockItem_clicker()" />
	</hbox>
	<separator height="3px" />
	<div id="founditems_holder" />
</div>
</popup>
<!-- end of stock items search popup -->
*/
// -------- ENDOF search stock items, ALS version .. can be used in other mods -- remember the popup too

