
String[] doculink_status = { "ACTIVE", "PENDING" , "EXPIRED" };

public class documentLinkObj
{
	public String global_doculink_origid;
	public String global_eq_origid;
	
	public String document_idprefix;
	
	public Object refreshListbox;
	
	public documentLinkObj()
	{
		global_doculink_origid = "";
		global_eq_origid = "";
	}
}

// Database func: return the complete rec from DocumentTable - including blob
Object lgk_getLinkingDocumentRec(String iorigid)
{
	ds_sql = lgk_DocumentStorage();
	if(ds_sql == NULL) return;
	sqlstat = "select * from DocumentTable where origid=" + iorigid;
	retval = ds_sql.firstRow(sqlstat);
	ds_sql.close();
	return retval;
}

// Database func: return the metadata from DocumentTable.. no need to return the blob
Object lgk_getLinkingDocumentMetadataRec(String iorigid)
{
	retval = null;
	ds_sql = lgk_DocumentStorage();
	if(ds_sql == NULL) return;
	sqlstat = "select origid,file_title,file_description,docu_link,docu_status,username,datecreated,version from DocumentTable where origid=" + iorigid;
	retval = ds_sql.firstRow(sqlstat);
	ds_sql.close();
	return retval;
}

void lgk_toggleDocument_DeleteFlag(String iorigid)
{
	docrec = lgk_getLinkingDocumentRec(iorigid);
	if(docrec == null) return;
	
	delflag = (docrec.get("deleted") == 0) ? "1" : "0";
	
	ds_sql = lgk_DocumentStorage();
	if(ds_sql == NULL) return;
	
	sqlst = "update DocumentTable set deleted=" + delflag + " where origid=" + iorigid;
	ds_sql.execute(sqlst);
	ds_sql.close();
}

void lgk_deleteDocument_Rec(String iorigid)
{
	ds_sql = lgk_DocumentStorage();
	if(ds_sql == NULL) return;

	sqlst = "delete from DocumentTable where origid=" + iorigid;
	ds_sql.execute(sqlst);
	ds_sql.close();
}

void lgk_updateDocument_Rec(String iorigid, String ifiletitle, String ifiledesc, String idocustatus)
{
	ds_sql = lgk_DocumentStorage();
	if(ds_sql == NULL) return;

	thecon = ds_sql.getConnection();
	pstmt = thecon.prepareStatement("update DocumentTable set file_title=? , file_description=? , docu_status = ? where origid=?");

	pstmt.setString(1,ifiletitle);
	pstmt.setString(2,ifiledesc);
	pstmt.setString(3,idocustatus);
	pstmt.setString(4,iorigid);

	pstmt.executeUpdate();
	ds_sql.close();

}

void lgk_setDocumentLink_DynamicProperty(Include whichinc, Object iwhich, Object userobj)
{
	whichinc.setDynamicProperty("doculink_property", iwhich);
	setUserAccessObj(whichinc, userobj);
}

Object getDocumentLink_DynamicProperty()
{
	return Executions.getCurrent().getAttribute("doculink_property");
}

// To store uploaded file into database.
// params: iusername, ibranch - from useraccessobj, to have an owner to document
//		idocdate = document upload date - should be today
//		doculink_str = document id prefix + whatever
//		docustatus_str = active,expired or whatever.. can be def in drop-down
boolean lgk_uploadLinkingDocument(String iusername, String ibranch, String idocdate, String doculink_str, String docustatus_str,String ftitle, String fdesc)
{
	uploaded_file = Fileupload.get(true);
	
	if(uploaded_file == null) return false;
	
	formatstr = uploaded_file.getFormat();
	contenttype = uploaded_file.getContentType();
	ufilename = uploaded_file.getName();
	
	Object uploaded_data;
	int fileLength = 0;
	
	f_inmemory = uploaded_file.inMemory();
	f_isbinary = uploaded_file.isBinary();

	if(f_inmemory && f_isbinary)
	{
		uploaded_data = uploaded_file.getByteData();
	}
	else
	{
		uploaded_data = uploaded_file.getStreamData();
		fileLength = uploaded_data.available(); 
	}
	
	if(uploaded_data == null)
	{
		showMessageBox("Invalid file-type uploaded..");
		return;
	}
	
	// alert("formatstr: " + formatstr + " | contenttype: " + contenttype + " | filename: " + ufilename);
		
	ds_sql = lgk_DocumentStorage();
	if(ds_sql == NULL) return;
	
	thecon = ds_sql.getConnection();
	
	//todaydate = getDateFromDatebox(ihiddendatebox);
	//ftitle = fileupl_file_title.getValue();
	//fdesc = fileupl_file_description.getValue();
	// doculink_str = EQID_PREFIX + doculink_prop.global_eq_origid;
	//doculink_str = doculink_prop.document_idprefix + doculink_prop.global_eq_origid;
	//docustatus_str = fileupl_docu_status.getSelectedItem().getLabel();

	pstmt = thecon.prepareStatement("insert into DocumentTable(file_title,file_description,docu_link,docu_status,username,datecreated,version," +
		"file_name,file_type,file_extension,file_data,deleted,branch) values (?,?,?,?,?,?,?,?,?,?,?,?,?)");

	pstmt.setString(1, ftitle);
	pstmt.setString(2, fdesc);
	pstmt.setString(3, doculink_str);
	pstmt.setString(4, docustatus_str);
	pstmt.setString(5, iusername);
	pstmt.setString(6,idocdate);
	pstmt.setInt(7,1);
	pstmt.setString(8,ufilename);
	pstmt.setString(9,contenttype);
	pstmt.setString(10,formatstr);

	if(f_inmemory && f_isbinary)
		pstmt.setBytes(11, uploaded_data);
	else
		pstmt.setBinaryStream(11, uploaded_data, fileLength);

	pstmt.setInt(12,0); // deleted flag
	pstmt.setString(13, ibranch);

	pstmt.executeUpdate();
	ds_sql.close();
	
	return true;
}
