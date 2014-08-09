// Sample registration module - samples handling funcs

// check whether can do CRUD on samples. uses whathuh var to access folderJobObj
boolean foldersamplesCRUD_Check()
{
	retval = true;
	if(!global_folder_status.equals(FOLDERDRAFT))
	{
		guihand.showMessageBox("Folder/job already logged or commited. Modification can only be performed by HOD or senior supervisor");
		retval = false;
	}
	return retval;
}

void clearSampleMarking_Details()
{
	Object[] jkl = { sampleid_str, samplemarking, sample_extranotes };
	clearUI_Field(jkl);
}

// Add new samples to job/folder
// 24/2/2010: added codes to check if no AR_code, cannot create new samples
void createNewSampleEntry()
{
	if(global_selected_folder.equals("")) return;
	if(global_selected_arcode.equals("")) return;

	// 2/2/2010: if folderstatus not draft, cannot add new samples
	if(!foldersamplesCRUD_Check()) return;

	samphand.createNewSampleRec2(global_selected_folder); // samplereg_funcs.zs
	startFolderSamplesSearch(global_selected_folder); // refresh
}

// Set 'deleted' flag in table to reflect deletion. Later can write admin-cleanup utils to clean all these
void removeSampleEntry()
{
	if(global_selected_sampleid.equals("")) return;

	// 2/2/2010: if folderstatus not draft, cannot do CRUD
	if(!foldersamplesCRUD_Check()) return;

	selitem = samples_lb.getSelectedItem();
	isampid = lbhand.getListcellItemLabel(selitem,1);

	if(Messagebox.show("Delete sample " + isampid, "Are you sure?",
		Messagebox.YES | Messagebox.NO, Messagebox.QUESTION) ==  Messagebox.YES)
	{
		samphand.toggleSampleDeleteFlag(global_selected_sampleid,"1");
		startFolderSamplesSearch(global_selected_folder); // refresh
	}
}

// Save sample's metadata, sample-marking and other things
void saveSampleMetadata_clicker()
{
	// 2/2/2010: only folder in DRAFT can save sample's metadata
	if(!foldersamplesCRUD_Check()) return;
	saveSampleMarking_Details();
	startFolderSamplesSearch(global_selected_folder); // refresh
}

// 05/02/2013: req by Sajeeta, add multi samples
void createMultiSamples()
{
	addmultisamp_popup.close();
	howstr = addmulti_tb.getValue();
	if(howstr.equals("")) return;
	if(global_selected_folder.equals("")) return;
	sqlstm = ""; howmany = 0;
	try	{ howmany = Integer.parseInt(howstr); } catch (Exception e) {}
	if(howmany == 0) return;
	for(i=0; i<howmany; i++)
	{
		sqlstm += "insert into JobSamples (sampleid_str,samplemarking,matrix,extranotes,jobfolders_id,uploadtolims," + 
		"uploadtomysoft,deleted,status,releasedby,releaseddate) " + 
		"values ('','','',''," + global_selected_folder + ",0,0,0,'','','');";
	}
	if(!sqlstm.equals(""))
	{
		sqlhand.gpSqlExecuter(sqlstm);
		startFolderSamplesSearch(global_selected_folder);
	}
}

void showSampleMarking_Details()
{
	//iorigid = convertSampleNoToInteger(sampleid_str.getValue());
	tr = samphand.getFolderSampleRec(global_selected_sampleid);
	if(tr == null) return;
	sampstr = tr.get("sampleid_str");
	// 25/11/2010: empty sampleid_str , make one
	if(sampstr.equals("")) sampstr = global_selected_folderstr + kiboo.padZeros5(tr.get("origid"));

	sampleid_str.setValue(sampstr);
	samplemarking.setValue(tr.get("samplemarking"));
	sample_extranotes.setValue(tr.get("extranotes"));
	
	// 11/10/2011: ASMA sample-id and station
	asmastuff.setVisible(false);
	asma_id.setValue("");
	asma_station.setValue("");

	if(global_selected_arcode.equals("300A/008"))
	{
		asma_id.setValue(kiboo.checkNullString(tr.get("asma_id")));
		asma_station.setValue(kiboo.checkNullString(tr.get("asma_station")));
		asmastuff.setVisible(true);
	}

	// 11/09/2012: ENV customer project-id field
	envcustomer_stuff.setVisible(false);
	if(global_customer_category.equals("ENV") || global_customer_category.equals("CONSULTANT"))
		if(!global_selected_arcode.equals("300A/008"))
		{
			// uses asma_id to store project-id
			projectid = kiboo.checkNullString(tr.get("asma_id"));
			env_projectid.setValue(projectid);
			envcustomer_stuff.setVisible(true);
		}

	wcpp.setValue(kiboo.checkNullString(tr.get("wcpp"))); // 15/10/2012: wcpp field
	// 23/05/2013: jobsamples.bottles field
	bottles.setValue((tr.get("bottles") == null) ? "" : tr.get("bottles").toString());
	lbhand.matchListboxItems(per_share_sample,kiboo.checkNullString(tr.get("share_sample")));
}

void saveSampleMarking_Details()
{
	if(global_selected_sampleid.equals("")) return;

	isamporig = sampleid_str.getValue();
	isampmark = kiboo.replaceSingleQuotes(samplemarking.getValue());
	iextrano = kiboo.replaceSingleQuotes(sample_extranotes.getValue());

	asmid = kiboo.replaceSingleQuotes(asma_id.getValue());
	asmstat = kiboo.replaceSingleQuotes(asma_station.getValue());
	
	bottl = kiboo.replaceSingleQuotes(bottles.getValue());
	if(bottl.equals("")) bottl = "0";

	// 8/2/2010: get folderno from main folderno textbox
	//ifoldno = convertFolderNoToInteger(whathuh.fj_origid_folderno.getValue());
	//iorigid = convertSampleNoToInteger(sample_origid.getValue());

	// 11/10/2011: save ASMA sample-id and station
	// 15/10/2012: save wearcheck-prepaid num , jobsamples.wcpp

	if(global_customer_category.equals("ENV") || global_customer_category.equals("CONSULTANT"))
		if(!global_selected_arcode.equals("300A/008"))
			asmid = kiboo.replaceSingleQuotes(env_projectid.getValue());

	wcppin = kiboo.replaceSingleQuotes(wcpp.getValue());
	pssh = per_share_sample.getSelectedItem().getLabel(); // 21/06/2013: per-sample share-sample tag

	sqlstatem = "update JobSamples set samplemarking='" + isampmark + "', " +
	"extranotes='" + iextrano + "', asma_id='" + asmid + "', asma_station='" + asmstat + "', " +
	"sampleid_str='" + isamporig + "', wcpp='" + wcppin + "', bottles=" + bottl + ", share_sample='" + pssh + "' " +
	" where origid=" + global_selected_sampleid;

	sqlhand.gpSqlExecuter(sqlstatem);

}
