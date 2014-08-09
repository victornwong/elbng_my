import java.sql.Connection;
import java.sql.DriverManager;
import javax.sql.DataSource;
import groovy.sql.Sql;
import org.zkoss.zk.ui.*;

/*

Job/Project Related funcs
Written by : Victor Wong
Date : 12/09/2010

Notes:

-- Check ident value
 	dbcc checkident(tbl_mqb_data_templates)
 -- Reset ident value
 	dbcc checkident(tbl_mqb_data_templates, reseed, 0)

*/

JOB_SCHEDULE_PREFIX = "JS";

String jobsched_Id_Maker(String iorigid)
{
	return JOB_SCHEDULE_PREFIX + iorigid;
}

// Database func: get rec from JobCode
Object lgk_getJobCode_Rec(String ijobcode)
{
	sql = lgk_mysoftsql();
	if(sql == null) return;
	sqlstm = "select * from JobCode where jobcode='" + ijobcode + "'";
	retval = sql.firstRow(sqlstm);
	sql.close();
	return retval;
}

// Database func: create a new schedule rec
void lgk_insertJobSchedule_Rec(String[] recdata)
{
	sql = lgk_mysoftsql();
	if(sql == null) return;
	thecon = sql.getConnection();

	pstmt = thecon.prepareStatement("insert into Job_Scheduling (jobcode,jobsched_str,sched_desc,supname,notes, startdate,enddate,status,deleted,username, datecreated) values " +
	"(?,?,?,?,?, ?,?,?,?,?, ?)");

	pstmt.setString(1,recdata[0]);
	pstmt.setString(2,recdata[1]);
	pstmt.setString(3,recdata[2]);
	pstmt.setString(4,recdata[3]);
	pstmt.setString(5,recdata[4]);

	pstmt.setString(6,recdata[5]);
	pstmt.setString(7,recdata[6]);
	pstmt.setString(8,recdata[7]);
	pstmt.setInt(9,Integer.parseInt(recdata[8]));
	pstmt.setString(10,recdata[9]);

	pstmt.setString(11,recdata[10]);

	pstmt.executeUpdate();
	sql.close();
}

// Database func: get job_scheduling rec
Object lgk_getJobScheduling_Rec(String iorigid)
{
	sql = lgk_mysoftsql();
	if(sql == null) return;
	sqlstm = "select * from Job_Scheduling where origid=" + iorigid;
	retval = sql.firstRow(sqlstm);
	sql.close();
	return retval;
}

// Database func: insert rec into Job_Sched_Items
void lgk_insertJobSchedItems_Rec(String[] recdata)
{
	sql = lgk_mysoftsql();
	if(sql == null) return;
	thecon = sql.getConnection();

	pstmt = thecon.prepareStatement("insert into Job_Sched_Items (parent_sched,site_id,site_name,site_desc,notes,status,datecompleted) values " +
	"(?,?,?,?,?, ?,?)");

	pstmt.setString(1,recdata[0]);
	pstmt.setString(2,recdata[1]);
	pstmt.setString(3,recdata[2]);
	pstmt.setString(4,recdata[3]);
	pstmt.setString(5,recdata[4]);
	pstmt.setString(6,recdata[5]);
	pstmt.setString(7,recdata[6]);

	pstmt.executeUpdate();
	sql.close();
}

// Database func: get rec from Job_Sched_Items
Object lgk_getJobSchedItems_Rec(String iorigid)
{
	sql = lgk_mysoftsql();
	if(sql == null) return;
	sqlstm = "select * from Job_Sched_Items where origid=" + iorigid;
	retval = sql.firstRow(sqlstm);
	sql.close();
	return retval;
}

// Database func: get rec from Job_Sched_Team
Object lgk_getJobSchedTeam_Rec(String iorigid)
{
	sql = lgk_mysoftsql();
	if(sql == null) return;
	sqlstm = "select * from Job_Sched_Team where origid=" + iorigid;
	retval = sql.firstRow(sqlstm);
	sql.close();
	return retval;
}

// Database func: insert rec into Job_Sched_Team
void lgk_insertJobSchedTeam_Rec(String[] recdata)
{
	sql = lgk_mysoftsql();
	if(sql == null) return;
	thecon = sql.getConnection();

	pstmt = thecon.prepareStatement("insert into Job_Sched_Team (parent_sched,staff_id,staff_name,notes,status,completedate) values " +
	"(?,?,?,?,?, ?)");

	pstmt.setString(1,recdata[0]);
	pstmt.setString(2,recdata[1]);
	pstmt.setString(3,recdata[2]);
	pstmt.setString(4,recdata[3]);
	pstmt.setString(5,recdata[4]);
	pstmt.setString(6,recdata[5]);
	pstmt.executeUpdate();
	sql.close();

}

// Database func: add rec into Staff_List
void lgk_insertStaffList_Rec(String[] recdata)
{
	sql =  lgk_mysoftsql();
	if(sql == null) return;
	thecon = sql.getConnection();
	
	pstmt = thecon.prepareStatement("insert into Staff_List (staff_name,staff_id,staff_status,position,department, hod,handphone,email,address1,address2, city,zipcode,state,hourwage,portaluserid) values " +
		"(?,?,?,?,?, ?,?,?,?,?, ?,?,?,?,?)");

	pstmt.setString(1, recdata[0]);
	pstmt.setString(2, recdata[1]);
	pstmt.setString(3, recdata[2]);
	pstmt.setString(4, recdata[3]);
	pstmt.setString(5, recdata[4]);

	pstmt.setInt(6, Integer.parseInt(recdata[5]));
	pstmt.setString(7, recdata[6]);
	pstmt.setString(8, recdata[7]);
	pstmt.setString(9, recdata[8]);
	pstmt.setString(10, recdata[9]);

	pstmt.setString(11, recdata[10]);
	pstmt.setString(12, recdata[11]);
	pstmt.setString(13, recdata[12]);
	pstmt.setFloat(14, Float.parseFloat(recdata[13]));
	pstmt.setString(15, recdata[14]);

	pstmt.executeUpdate();
	sql.close();
}

// Database func: get rec from staff_list
Object lgk_getStaffList_Rec(String iorigid)
{
	sql = lgk_mysoftsql();
	if(sql == null) return;
	sqlstm = "select * from Staff_List where origid=" + iorigid;
	retval = sql.firstRow(sqlstm);
	sql.close();
	return retval;
}

//------------
