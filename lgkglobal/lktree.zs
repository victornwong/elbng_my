import java.util.*;
import java.text.*;

import java.sql.Connection;
import java.sql.DriverManager;
import javax.sql.DataSource;
import groovy.sql.Sql;

/*
EDA+MS uses these in the LKTree

LKTree.value1 = river-name or whatever descriptive
LKTree.value2 = WKA - alot, not practical to put into a dropdown
LKTree.value3 = latitude
LKTree.value4 = longitude
LKTree.value7 = job/project code from JobCode table
LKTree.value8 = storage-template id

Written by Victor Wong
*/

// Update storage-template origid into LKTree.value8
void updateLKTree_StorageTemplate_Field(String istationcode, String ist_origid)
{
	sql = lgk_mysoftsql();
	if(sql == null) return;
	
	sqlstm = "update LKTree set value8='" + ist_origid + "' where idlookups=" + istationcode;
	sql.execute(sqlstm);
	sql.close();
}

// Database func: insert a new rec into LKTree
void insertLKTree_Rec(String[] recdata)
{
	sql =  lgk_mysoftsql();
	if(sql == null) return;
	thecon = sql.getConnection();
	
	pstmt = thecon.prepareStatement("insert into LKTree (lookupcode,disptext,myparent,expired,value1, value2,value3,value4,value5,value6, value7,value8,intval) " +
	"values (?,?,?,?,?, ?,?,?,?,?, ?,?,?)");
	
	pstmt.setString(1,recdata[0]);
	pstmt.setString(2,recdata[1]);
	pstmt.setInt(3,Integer.parseInt(recdata[2]));
	pstmt.setInt(4,Integer.parseInt(recdata[3]));
	pstmt.setString(5,recdata[4]);
	
	pstmt.setString(6,recdata[5]);
	pstmt.setString(7,recdata[6]);
	pstmt.setString(8,recdata[7]);
	pstmt.setString(9,recdata[8]);
	pstmt.setString(10,recdata[9]);
	
	pstmt.setString(11,recdata[10]);
	pstmt.setString(12,recdata[11]);
	pstmt.setInt(13,Integer.parseInt(recdata[12]));
	
	pstmt.executeUpdate();
	sql.close();
}

// Database func: get LKTree rec
Object getLKTree_Rec(String idlookups)
{
	retval = null;
	sql = lgk_mysoftsql();
	if(sql == null) return;
	sqlstm = "select * from LKTree where idlookups=" + idlookups;
	retval = sql.firstRow(sqlstm);
	sql.close();
	return retval;
}

// Database func: to consolidate some of the mundane tree-update thing
void updateLKTree_EDAMS(String idlookups, String idisptext, String ilatitude, String ilongitude, String ivalue1)
{
	idisptext = replaceSingleQuotes(idisptext);
	ilatitute = replaceSingleQuotes(ilatitude);
	ilongitude = replaceSingleQuotes(ilongitude);

	sql = lgk_mysoftsql();
	if(sql == null) return;
	sqlstm = "update LKTree set disptext='" + idisptext + "',value1='" + ivalue1 + "',value3='" + ilatitude + "', value4='" + ilongitude + "' where idlookups=" + idlookups;
	sql.execute(sqlstm);
	sql.close();
}

