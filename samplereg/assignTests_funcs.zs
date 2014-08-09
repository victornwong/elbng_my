import org.victor.*;

// quick hack -- later addback to src
String extractSampleNo_2(String iwhich)
{
	String retval = "";
/*	
	alert(iwhich.length() + " :: " + iwhich.substring(10,16) );
	return retval;
*/
	if(!iwhich.equals(""))
	{
		if(iwhich.length() > 15)
			retval = String.valueOf(iwhich.substring(10,16));
		else
			retval = String.valueOf(iwhich.substring(9,15));
	}
	return retval;
}

void showHideBoxes(boolean iwhat)
{
	Object[] oj ={ testspanel_holder, testthings_holder, foldersamples_holder, folder_buttons_div, folder_buttons_div2 };
	for(i=0; i<oj.length; i++)
	{
		oj[i].setVisible(iwhat);
	}
	/*
	testspanel_holder.setVisible(iwhat);
	testthings_holder.setVisible(iwhat);
	foldersamples_holder.setVisible(iwhat);
	folder_buttons_div.setVisible(iwhat);
	folder_buttons_div2.setVisible(iwhat);
	*/
}

// check whether can do CRUD on samples. uses whathuh var to access folderJobObj
boolean foldersamplesCRUD_Check()
{
	retval = true;
	if(!whathuh.fj_folderstatus.equals(FOLDERDRAFT))
	{
		guihand.showMessageBox("Folder/job already logged or commited. Modification can only be performed by HOD or senior supervisor");
		retval = false;
	}
	return retval;
}

// 06/11/2012: updated to check for 0 or NULL mysoftcode -- to deter cheater
boolean gotTestAssigned(String ifoldernostr)
{
	boolean retval = false;
	sqlstm = "select count(jtp.origid) test_assigned from jobtestparameters jtp " +
	"left join jobsamples js on jtp.jobsamples_id = js.origid " +
	"left join jobfolders jf on js.jobfolders_id = jf.origid " +
	"where jf.folderno_str='" + ifoldernostr + "' " +
	"and jtp.mysoftcode <> 0 and jtp.mysoftcode is not null";

	rek = sqlhand.gpSqlFirstRow(sqlstm);
	if(rek == null) return retval;
	tesa = rek.get("test_assigned");
	if(tesa > 0) retval = true;
	return retval;
}

void hideTestParametersBox()
{
	//mysoft_testparams.setVisible(false);	
}

void showTestParametersBox()
{
	//mysoft_testparams.setVisible(true);
}

