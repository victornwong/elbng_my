// Import things from cold-call table - can be used for other mods - remember the call-back func
/*
<popup id="impcoldcal_pop">
<div sclass="shadowbox" style="background:#204a87;" width="400px" >
	<combobox id="imcust_cb" sclass="k9" />
	<button id="impcoldcall_b" sclass="k9" label="Get customer details" onClick="importColdCallDetails(imcust_cb.getValue())" />
</div>
</popup>
*/

void popColdCallContacts_combo(Object tcombo)
{
	sqlstm = "select distinct cust_name from rw_activities_contacts;";
	r = sqlhand.gpSqlGetRows(sqlstm);
	if(r.size() == 0) return;
	ArrayList kabom = new ArrayList();
	for(d : r)
	{
		kabom.add(d.get("cust_name"));
	}
	gridhand.makeComboitem(tcombo, kiboo.convertArrayListToStringArray(kabom) );
}

void importColdCallDetails(String iwho)
{
	impcoldcal_pop.close();
	k = kiboo.replaceSingleQuotes(iwho.trim());
	if(k.equals("")) return;
	sqlstm = "select cust_name, contact_person, cust_address1, cust_address2, cust_address3, cust_address4, cust_tel, cust_fax, cust_email " +
	"from rw_activities_contacts " +
	"where cust_name='" + k + "'";

	r = sqlhand.gpSqlFirstRow(sqlstm);
	if(r == null) return;

	coldcall_ImpCallBack(r);

/*
	locstr = kiboo.checkNullString(r.get("cust_address1")) + ",\n" + kiboo.checkNullString(r.get("cust_address2")) + ",\n" +
	kiboo.checkNullString(r.get("cust_address3")) + ",\n" + kiboo.checkNullString(r.get("cust_address4"));

	locstr = locstr.replaceAll(",,",",");
	q_cust_address.setValue(locstr);
	q_contact_person1.setValue( kiboo.checkNullString(r.get("contact_person")) );
	q_telephone.setValue( kiboo.checkNullString(r.get("cust_tel")) );
	q_fax.setValue( kiboo.checkNullString(r.get("cust_fax")) );
	q_email.setValue( kiboo.checkNullString(r.get("cust_email")) );

	global_selected_customer = k;
	global_selected_customerid = "";
	customername.setValue(global_selected_customer);
*/
}

