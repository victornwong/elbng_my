import org.victor.*;

// General purpose sql-related funcs -- later move to byte-compile
// sqlhand.gpSqlFirstRow(sqlstm);

// Populate a listbox with usernames from portaluser
void populateUsernames(Listbox ilb, String discardname)
{
	sqlstm = "select username from portaluser where username<>'" + discardname + "' and deleted=0 and locked=0 order by username";
	recs = sqlhand.gpSqlGetRows(sqlstm);
	if(recs.size() == 0) return;
	ArrayList kabom = new ArrayList();
	for( d : recs)
	{
		kabom.add( kiboo.checkNullString(d.get("username")) );
		lbhand.insertListItems(ilb,kiboo.convertArrayListToStringArray(kabom),"false","");
		kabom.clear();
	}
	ilb.setSelectedIndex(0);
}

Object getActivitiesContact_rec(String iwhat)
{
	sqlstm = "select * from rw_activities_contacts where origid=" + iwhat;
	return sqlhand.gpSqlFirstRow(sqlstm);
}

Object getActivity_rec(String iwhat)
{
	sqlstm = "select * from rw_activities where origid=" + iwhat;
	return sqlhand.gpSqlFirstRow(sqlstm);
}
