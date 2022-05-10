/*=================================================================================================*\
|Author(s) : Saani Rawat
|Purpose   : Data Preparing to assess covid impact on Ohio's public health sector
|History   : Date 		By Description
			 7 May 22   SR Used Dr. Michael Jones's OJFS data to prepare data file
			 8 May 22   SR Started coding Job creation and Job destroyed variables
\*=================================================================================================*/

%include "C:\Users\rawatsa\OneDrive - University of Cincinnati\sas_utility_functions\util_load_macro_functions.sas";
%util_load_macro_functions(C:\Users\rawatsa\OneDrive - University of Cincinnati\sas_utility_functions,subfolder=1);

%let extracts = C:\QCEW Data - Ohio\ES202\extracts;
%let root = C:\Users\rawatsa\OneDrive - University of Cincinnati\SASprojects\ohphs_covid_impact;
%let out = &root.\data;

libname extr "&extracts.";

*----------------------------------------------------------------------------------------
* loading Ohio Employment data (for NAICS code 62 only)	
*----------------------------------------------------------------------------------------;
proc sql;
	create table ohphs as
		select  catx(strip(pad),strip(uin),strip(repunit)) as unique_id,
				yyq(year,quarter) as date format = yyq6.,
				*,
				sum(m1,m2,m3) as num_employed, 
				substr(strip(put(naics,best6.)),1,2) as naics_2dg, 
				substr(strip(put(naics,best6.)),1,3) as naics_3dg,
				case 
					when calculated naics_3dg = "621" then "Ambulatory Health Care Services"
					when calculated naics_3dg = "622" then "Hospitals"
					when calculated naics_3dg = "623" then "Nursing and Residential Care Facilities"
					when calculated naics_3dg = "624" then "Social Assistance"
				end as naics_3dg_subcategory
			from extr.masterfile_2006q1_2021q2
				where calculated naics_2dg = "62" and strip(state) = "OH";
quit;
*padding zeroes for year 2020;
data ohphs;
	set ohphs;
/*		where strip(ein) = "310792046";*/
		 pad = put(input(pad,best3.),z3.);
		 RepUnit = put(input(RepUnit,best5.),z5.);
		 uin = put(input(uin,best7.),z7.);
		 unique_id = catx(strip(pad),strip(uin),strip(repunit));
run;

*----------------------------------------------------------------------------------------
*	Summarizing using zipcode
*----------------------------------------------------------------------------------------;
proc freq data=ohphs;
	tables zip;
run; * has roughly 65,000 missing values;

proc freq data=ohphs;
	tables city;
run; * has only 7 missing values. Need to clean the city string.;

proc freq data=ohphs;
	tables date;
run; * has only 7 missing values. Need to clean the city string.;

*----------------------------------------------------------------------------------------
*	Job creation and Job destruction variables
*----------------------------------------------------------------------------------------;
proc sql noprint;
	select distinct unique_id into :ids separated by " "
	from ohphs (obs  = 10);
quit;
%let ids="%sysfunc(tranwrd(&ids.,%str( ),%str(%", %")))";
%put &=ids;

proc sort data=ohphs  out=ohphs_sort;* (where=(unique_id in (&ids.) ));*(where=(unique_id in ("000893500000000","001863000000001","001863000000002","001863000000003","001863000000004","001863000000011") ));
	by unique_id year quarter;
run;
	
data ohphs_sort2;* (where= (year(date) > 2016));
	set ohphs_sort (keep=unique_id date  num_employed);
	by unique_id;

	* creating flags for when a store was first created and last seen;
	if first.unique_id then new_flag = 1; else new_flag = 0;
	if last.unique_id then destroyed_flag = 1; else destroyed_flag = 0;

	* difference in workers for each firm;
	diff = num_employed - lag(num_employed); if new_flag = 1 then diff = .; 

	date2 = intnx("qtr",date,0,'end'); format date2 date9.;
	date =  intnx("qtr",date,0,'b');

	* jobs created and jobs destryoed;
	if diff >=0 then jobs_created = diff; else jobs_created = 0;
	if diff < 0 then jobs_destroyed = diff; 
	if jobs_destroyed = . then jobs_destroyed = 0;

	* whenever a new firm is found, it should add jobs;
	if new_flag = 1 and date2 ^= "31mar2006"d  then jobs_created = num_employed;

	* creating a new observation whenever destroyed_flag = 1 since these jobs should be removed from next quarter ;
	if destroyed_flag = 1 and date2 ^= "30jun2021"d then do; 
		destroyed_flag = 0;
		output;
		destroyed_flag = 1;
		date =  intnx("qtr",date,1,'b');
		jobs_destroyed = -num_employed;
		jobs_created = 0;
		num_employed = 0;
		diff = 0;
		output;
	end;
	else output;

run;

%util_dat_aggregate(
                   df       = ohphs_sort2
                 , out_df   = ohphs_sort3 
                 , group    = date
                 , sum      = num_employed jobs_created jobs_destroyed
);
data ohphs_sort3;
	set ohphs_sort3;
		jobs_created_and_destroyed = jobs_created +	jobs_destroyed;
		change_employment = num_employed - lag(num_employed);
		diff = jobs_created_and_destroyed - change_employment;
run;



*----------------------------------------------------------------------------------------;
* creating flags for when a store was first created i.e. jobs created;
data ohphs_sort2;* (where= (year(date) > 2016));
	set ohphs_sort (keep=unique_id date  num_employed  );
	by unique_id;

	date_chk = lag(date); format date_chk yyq6.; 
	if date = intnx("qtr",date_chk,1,'b') then new_flag = 0; else new_flag = 1;

run;
proc sort data=ohphs_sort2;
	by unique_id descending date;
run;

* creating flags for when a store was last seen i.e. jobs destroyed. Code takes care of firms which stop filing for a few quarters in the middle and then start re-filing by treating
it as exit and then re-entry into job market
;
data ohphs_sort3 (drop= date_chk date_chk_lead);
	set ohphs_sort2;
	date_chk_lead = lag(date); format date_chk_lead yyq6.; 
	if date = intnx("qtr",date_chk_lead,-1,'b') then destroyed_flag = 0; else destroyed_flag = 1;

run;
proc sort data=ohphs_sort3;
	by unique_id date;
run;

/*data ohphs_sort33;*/
/*set ohphs_sort3; where new_flag = 1 and destroyed_flag = 1;*/
/*run;*/

data ohphs_sort4;
	set ohphs_sort3 ;
	by unique_id;

	* difference in workers for each firm;
	diff = num_employed - lag(num_employed); if new_flag = 1 then diff = .; 

	date =  intnx("qtr",date,0,'end');

	* jobs created and jobs destryoed;
	if diff >=0 then jobs_created = diff; else jobs_created = 0;
	if diff < 0 then jobs_destroyed = diff; 
	if jobs_destroyed = . then jobs_destroyed = 0;

	* whenever a new firm is found, it should add jobs;
	if new_flag = 1 and date ^= "31mar2006"d  then jobs_created = num_employed;

	* creating a new observation whenever destroyed_flag = 1 since these jobs should be removed from next quarter ;
	if destroyed_flag = 1 and date ^= "30jun2021"d then do; 
		destroyed_flag = 0;
		output;
		destroyed_flag = 1;
		new_flag = 0;
		date =  intnx("qtr",date,1,'end');
		jobs_destroyed = -num_employed;
		jobs_created = 0;
		num_employed = 0;
		diff = 0;
		output;
	end;
	else output;

run;

%util_dat_aggregate(
                   df       = ohphs_sort4
                 , out_df   = ohphs_sort5 
                 , group    = date
                 , sum      = num_employed jobs_created jobs_destroyed
);
data ohphs_sort5;
	set ohphs_sort5;
		jobs_created_and_destroyed = jobs_created +	jobs_destroyed;
		change_employment = num_employed - lag(num_employed);
		diff = jobs_created_and_destroyed - change_employment;
run;


data ohphs_sort6;
	set ohphs_sort4;
/*		where intnx("qtr",date,0,"end") ^= "31dec2006"d and destroyed_flag = 1;*/
	where new_flag = 1 and destroyed_flag = 1;
run;
