/*=================================================================================================*\
|Author(s) : Saani Rawat
|Purpose   : Data Preparing to assess covid impact on Ohio's public health sector
|History   : Date 		By Description
			 7 May 22   SR Used Dr. Michael Jones's OJFS data to prepare data file
			 8 May 22   SR Started coding Job creation and Job destroyed variables
			10 May 22   SR Added breakout by NAICS subcategories and Ohio counties
			13 May 22   SR Calculated non-ohphs numbers (qtrly and monthly)
			15 Jun 22   SR Reviewed the code for writing equations in article
			7  Jul 22   SR Added some comments
|Inputs	   : county_mapping_tbl.xlsx, masterfile_2006q1_2021q2.sas7bdat
|Outputs   : out.ohphs_job_vars_by_county_&type. , 
			 out.ohphs_empl_all_qtr, out.ohphs_empl_by_subcat_qtr, out.ohphs_empl_by_county_qtr, 
			 out.ohphs_empl_all_mth, out.ohphs_empl_by_subcat_mth, out.ohphs_empl_by_county_mth, 
			 out.non_ohphs_empl_all_qtr, out.non_ohphs_empl_by_subcat_qtr, out.non_ohphs_empl_by_county_qtr, out.non_ohphs_empl_by_region_qtr, 
			 out.non_ohphs_empl_all_mth, out.non_ohphs_empl_by_subcat_mth, out.non_ohphs_empl_by_county_mth, out.non_ohphs_empl_by_region_mth
\*=================================================================================================*/

%let start_time = %sysfunc(time());
%include "C:\Users\rawatsa\OneDrive - University of Cincinnati\sas_utility_functions\util_load_macro_functions.sas";
%util_load_macro_functions(C:\Users\rawatsa\OneDrive - University of Cincinnati\sas_utility_functions,subfolder=1);

%let extracts = C:\QCEW Data - Ohio\ES202\extracts;
%let root = C:\Users\rawatsa\OneDrive - University of Cincinnati\SASprojects\ohphs_covid_impact;
%let out = &root.\data\data_prep;

libname extr "&extracts.";
libname out "&out.";

*----------------------------------------------------------------------------------------
*	loading county mapping table
*----------------------------------------------------------------------------------------;
proc import datafile="&root.\docs\county_mapping_tbl.xlsx" dbms=xlsx replace out=county_mapping_tbl;
	sheet="mapping";
run;

*----------------------------------------------------------------------------------------
* loading Ohio Employment data (for NAICS code 62 only)	
*----------------------------------------------------------------------------------------;
*qtrly;
proc sql;
	create table ohphs as
		select  catx(strip(pad),strip(uin),strip(repunit)) as unique_id,
				intnx("qtr",yyq(year,quarter),0,"end") as date format = yyq6.,
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
			from extr.masterfile_2006q1_2021q2 as a
				left join county_mapping_tbl (keep = county_num_df county_name region) as b
					on a.county = b.county_num_df
				where calculated naics_2dg = "62" and strip(state) = "OH"
;
quit;
*padding zeroes for year 2020;
data ohphs;
	set ohphs;
		 pad = put(input(pad,best3.),z3.);
		 RepUnit = put(input(RepUnit,best5.),z5.);
		 uin = put(input(uin,best7.),z7.);
		 unique_id = catx(strip(pad),strip(uin),strip(repunit));
run;
* sorting dataset by unique_id and date;
proc sort data=ohphs  out=ohphs_sort;
	by unique_id date;
run;
* converting quarterly data into monthly data;
proc transpose data=ohphs_sort out=ohphs_sort_m (drop=_label_ wage num_employed rename=(col1 = num_employed)) NAME=month;
	by unique_id	date	Year	Quarter	Pad	UIN	RepUnit	EIN	PUIN	PRUN	SUIN	SRUN	Legal	Trade	Address	City	State	Zip	Zip4	RUD	MEEI	OrgType	County	naics	Wage	pl_zip	county_num_df	county_name	num_employed	naics_2dg	naics_3dg	naics_3dg_subcategory region;
	var m1 m2 m3;
run;
proc sql;
	create table ohphs_sort_mth (drop = date2 month2) as 
		select  input(substr(strip(month2),2),2.) as month,
				intnx("month",intnx("qtr",yyq(year,quarter),0,"beg"),calculated month-1,"end")  as date format = date9.,
				*
			from ohphs_sort_m (rename = (date = date2 month = month2))
		;
quit;

*-----------------------------------------------------------------------------------------
* loading Ohio Employment data (for all NAICS codes except 62). For benchmarking purposes.	
*-----------------------------------------------------------------------------------------;
*qtrly;
proc sql;
	create table non_ohphs as
		select  catx(strip(pad),strip(uin),strip(repunit)) as unique_id,
				intnx("qtr",yyq(year,quarter),0,"end") as date format = yyq6.,
				*,
				sum(m1,m2,m3) as num_employed, 
				substr(strip(put(naics,best6.)),1,2) as naics_2dg, 
				substr(strip(put(naics,best6.)),1,3) as naics_3dg,
				"other sectors" as naics_3dg_subcategory
			from extr.masterfile_2006q1_2021q2 as a
				left join county_mapping_tbl (keep = county_num_df county_name region) as b
					on a.county = b.county_num_df
				where calculated naics_2dg ^= "62" and strip(state) = "OH"
;
quit;
*padding zeroes for year 2020;
data non_ohphs;
	set non_ohphs;
		 pad = put(input(pad,best3.),z3.);
		 RepUnit = put(input(RepUnit,best5.),z5.);
		 uin = put(input(uin,best7.),z7.);
		 unique_id = catx(strip(pad),strip(uin),strip(repunit));
run;
* sorting dataset by unique_id and date;
proc sort data=non_ohphs  out=non_ohphs_sort;
	by unique_id date;
run;
* converting quarterly data into monthly data;
proc transpose data=non_ohphs_sort out=non_ohphs_sort_m (drop=_label_ wage num_employed rename=(col1 = num_employed)) NAME=month;
	by unique_id	date	Year	Quarter	Pad	UIN	RepUnit	EIN	PUIN	PRUN	SUIN	SRUN	Legal	Trade	Address	City	State	Zip	Zip4	RUD	MEEI	OrgType	County	naics	Wage	pl_zip	county_num_df	county_name	num_employed	naics_2dg	naics_3dg	naics_3dg_subcategory region;
	var m1 m2 m3;
run;
proc sql;
	create table non_ohphs_sort_mth (drop = date2 month2) as 
		select  input(substr(strip(month2),2),2.) as month,
				intnx("month",intnx("qtr",yyq(year,quarter),0,"beg"),calculated month-1,"end")  as date format = date9.,
				*
			from non_ohphs_sort_m (rename = (date = date2 month = month2))
		;
quit;

*----------------------------------------------------------------------------------------
*	Job creation and Job destruction variables
*----------------------------------------------------------------------------------------;
* storing all distinct dates in a list and requisite date column names;
proc sql noprint;
	select distinct date into :dts_qtr separated by " "
		from ohphs_sort;
quit;
%let dates_dts_qtr =date_%sysfunc(tranwrd(&dts_qtr.,%str( ),%str(_df date_)))_df;
proc sql noprint;
	select distinct date into :dts_mth separated by " "
		from ohphs_sort_mth;
quit;
%let dates_dts_mth =date_%sysfunc(tranwrd(&dts_mth.,%str( ),%str(_df date_)))_df;
%put &=dates_dts_qtr;
%put &=dates_dts_mth;

* macro that creates dataset containing jobs created and destroyed variables;					  
%macro make_vars(df = , sub_category = all, county = , type = qtr);
	*setting macro vars;
	%if %lowcase(&type.) = qtr %then %do;
		%let dts = &dts_qtr.;
		%let dates_dts = &dates_dts_qtr.;
	%end; 
	%if %lowcase(&type.) = mth %then %do;
		%let dts = &dts_mth.;
		%let dates_dts = &dates_dts_mth.;
	%end; 

	* transposing to get unique_id as rows and quarters as columns. This deals with firms which originate and vanish in between the periods.;
	%util_dat_pivot_wider(df = &df. (keep = unique_id date num_employed 
											%if %sysfunc(findw(621|622|623|624,&sub_category.,|)) ne 0  %then %do;
												naics_3dg
												where=(naics_3dg = "&sub_category.")
											%end;
											%if (&county. ne ) %then %do;
												county_name
												where = (lowcase(strip(county_name)) = "&county.")
											%end;
										   ) 
	                      , out_df = ohphs_sorted
	                      , names_from = date
	                      , values_from = num_employed
						  , names_prefix = date_
						  , values_fill = 0
	                      );

	* calculating the difference between two consecutive dates;
	data ohphs_sorted2;
		set ohphs_sorted 
						%if %sysfunc(findw(621|622|623|624,&sub_category.,|)) ne 0  %then %do;
							(drop= naics_3dg)
						%end; 
						%if (&county. ne ) %then %do;
							(drop= county_name)
						%end;
						;
			date_%scan(&dts.,1,' ')_df = 0;
		%do i = 2 %to %sysfunc(countw(&dts.));
			%let dt1 = %scan(&dts.,%eval(&i.-1),' ');
			%let dt2 = %scan(&dts.,&i.,' ');
			date_&dt2._df = date_&dt2. - date_&dt1.; 
		%end;
		keep unique_id _name_ &dates_dts.;
	run;
	* storing all positive changes in jobs created df;
	data ohphs_jobs_created;
		set ohphs_sorted2;
		%do j = 1 %to %sysfunc(countw(&dates_dts.));
			%let dt = %scan(&dates_dts.,&j.,' ');
			if &dt.>= 0 then &dt. = &dt.;
			else &dt. = 0;
		%end;
	run;
	* storing all negative changes in jobs destroyed df;
	data ohphs_jobs_destroyed;
		set ohphs_sorted2;
		%do j = 1 %to %sysfunc(countw(&dates_dts.));
			%let dt = %scan(&dates_dts.,&j.,' ');
			if &dt. < 0 then &dt. = &dt.;
			else &dt. = 0;
		%end;
	run;
	* aggregating for each quarter;
	proc summary data=ohphs_jobs_created;
		var &dates_dts.;
		output out=ohphs_jobs_created_agg (drop = _type_ _freq_) sum = ;
	run;
	proc summary data=ohphs_jobs_destroyed;
		var &dates_dts.;
		output out=ohphs_jobs_destroyed_agg (drop = _type_ _freq_) sum = ;
	run;
	*transposing back to create a time series of jobs created and jobs destroyed;
	%util_dat_pivot_longer(df = ohphs_jobs_created_agg
	                      , out_df = ohphs_jobs_created_agg_t
						  , names_to = date
						  , values_to = jobs_created
	                      );
	%util_dat_pivot_longer(df = ohphs_jobs_destroyed_agg
	                      , out_df = ohphs_jobs_destroyed_t
						  , names_to = date
						  , values_to = jobs_destroyed
	                      );
	*merging jobs created and jobs destroyed datasets;
	proc sql;
		create table 
					%if %sysfunc(findw(621|622|623|624|all,&sub_category.,|)) ne 0  %then %do;
						out.ohphs_job_vars_&sub_category._&type.
					%end;
					%if (&county. ne ) %then %do;
						work.ohphs_job_vars_&county._&type.
					%end; (drop = date_a date_b) as 
				select compress(date_a,"date_f") as date, (jobs_created + jobs_destroyed) as  change_in_num_employed, *
					%if %sysfunc(findw(621|622|623|624|all,&sub_category.,|)) ne 0  %then %do;
						, "&sub_category." as category
					%end;
					%if (&county. ne ) %then %do;
						, "&county." as county length = 20
					%end;
					from ohphs_jobs_created_agg_t (rename = (date = date_a)) as a, 
						 ohphs_jobs_destroyed_t (rename = (date = date_b)) as b
						where a.date_a = b.date_b;
	quit;
			
%mend make_vars;
%make_vars(df = ohphs_sort, sub_category = all, type = qtr); 
%make_vars(df = ohphs_sort, sub_category = 621, type = qtr); /*"Ambulatory Health Care Services"*/
%make_vars(df = ohphs_sort, sub_category = 622, type = qtr); /*"Hospitals"*/
%make_vars(df = ohphs_sort, sub_category = 623, type = qtr); /*"Nursing and Residential Care Facilities"*/
%make_vars(df = ohphs_sort, sub_category = 624, type = qtr); /*"Social Assistance"*/
%make_vars(df = ohphs_sort_mth, sub_category = all, type = mth); 
%make_vars(df = ohphs_sort_mth, sub_category = 621, type = mth); /*"Ambulatory Health Care Services"*/
%make_vars(df = ohphs_sort_mth, sub_category = 622, type = mth); /*"Hospitals"*/
%make_vars(df = ohphs_sort_mth, sub_category = 623, type = mth); /*"Nursing and Residential Care Facilities"*/
%make_vars(df = ohphs_sort_mth, sub_category = 624, type = mth); /*"Social Assistance"*/

*----------------------------------------------------------------------------------------
*	Regional datasets
*----------------------------------------------------------------------------------------;
* macro that creates dataset containing jobs created and destroyed variables;
proc sql noprint;
	select lowcase(county_name) into :county_list separated by "|"
		from county_mapping_tbl;
quit;
%put &=county_list ;

%macro make_counties(df = , county_list = , type = qtr);
	data out.ohphs_job_vars_by_county_&type. (where=(jobs_created^=.));
		length date $14 change_in_num_employed jobs_created jobs_destroyed 8 county $20;
	run;
	%do ttt = 1 %to %sysfunc(countw(&county_list.));
		%let cnty = %scan(&county_list.,&ttt.,'|');
		%make_vars(df = &df., sub_category = , county = &cnty., type = &type.);
			proc append base=out.ohphs_job_vars_by_county_&type. data=ohphs_job_vars_&cnty._&type. force;
			run;
	%end;
%mend  make_counties;
/*options nosymbolgen nomlogic nomprint;*/
%make_counties(df = ohphs_sort, county_list = &county_list., type = qtr)
%make_counties(df = ohphs_sort_mth, county_list = &county_list., type = mth)

*----------------------------------------------------------------------------------------
*	make aggregate employment variable: OHPHS
*----------------------------------------------------------------------------------------;
* quarterly;
* aggregating by date to cross-check jobs created and destroyed numbers later;	
%util_dat_aggregate(
                   df       = ohphs_sort
                 , out_df   = out.ohphs_empl_all_qtr
                 , group    = date
                 , sum      = num_employed 
);
* aggregating by date to cross-check jobs created and destroyed numbers later;	
%util_dat_aggregate(
                   df       = ohphs_sort
                 , out_df   = out.ohphs_empl_by_subcat_qtr
                 , group    = naics_3dg date
                 , sum      = num_employed 
);
* aggregating by date to cross-check jobs created and destroyed numbers later;	
%util_dat_aggregate(
                   df       = ohphs_sort (where =(strip(county_name)^=""))
                 , out_df   = out.ohphs_empl_by_county_qtr
                 , group    = county_name date
                 , sum      = num_employed 
);
*monthly;
* aggregating by date to cross-check jobs created and destroyed numbers later;	
%util_dat_aggregate(
                   df       = ohphs_sort_mth
                 , out_df   = out.ohphs_empl_all_mth
                 , group    = date
                 , sum      = num_employed 
);
* aggregating by date to cross-check jobs created and destroyed numbers later;	
%util_dat_aggregate(
                   df       = ohphs_sort_mth
                 , out_df   = out.ohphs_empl_by_subcat_mth
                 , group    = naics_3dg date
                 , sum      = num_employed 
);
* aggregating by date to cross-check jobs created and destroyed numbers later;	
%util_dat_aggregate(
                   df       = ohphs_sort_mth (where =(strip(county_name)^=""))
                 , out_df   = out.ohphs_empl_by_county_mth
                 , group    = county_name date
                 , sum      = num_employed 
);

*----------------------------------------------------------------------------------------
*	make aggregate employment variable: Non-OHPHS	
*----------------------------------------------------------------------------------------;
* quarterly;
* aggregating by date to cross-check jobs created and destroyed numbers later;	
%util_dat_aggregate(
                   df       = non_ohphs_sort
                 , out_df   = out.non_ohphs_empl_all_qtr
                 , group    = date
                 , sum      = num_employed 
);
* aggregating by date and naics code;
%util_dat_aggregate(
                   df       = non_ohphs_sort
                 , out_df   = out.non_ohphs_empl_by_subcat_qtr (where = (strip(naics_3dg) ^="0"))
                 , group    = naics_3dg date
                 , sum      = num_employed 
);
* aggregating by date and county;
%util_dat_aggregate(
                   df       = non_ohphs_sort (where =(strip(county_name)^=""))
                 , out_df   = out.non_ohphs_empl_by_county_qtr
                 , group    = county_name date
                 , sum      = num_employed 
);
* aggregating by date and region;
%util_dat_aggregate(
                   df       = non_ohphs_sort (where =(strip(county_name)^=""))
                 , out_df   = out.non_ohphs_empl_by_region_qtr
                 , group    = region date
                 , sum      = num_employed 
);
* monthly;
%util_dat_aggregate(
                   df       = non_ohphs_sort_mth
                 , out_df   = out.non_ohphs_empl_all_mth
                 , group    = date
                 , sum      = num_employed 
);
* aggregating by date and naics code;
%util_dat_aggregate(
                   df       = non_ohphs_sort_mth
                 , out_df   = out.non_ohphs_empl_by_subcat_mth (where = (strip(naics_3dg) ^="0"))
                 , group    = naics_3dg date
                 , sum      = num_employed 
);
* aggregating by date and county;	
%util_dat_aggregate(
                   df       = non_ohphs_sort_mth (where =(strip(county_name)^=""))
                 , out_df   = out.non_ohphs_empl_by_county_mth
                 , group    = county_name date
                 , sum      = num_employed 
);
* aggregating by date and region;
%util_dat_aggregate(
                   df       = non_ohphs_sort_mth (where =(strip(county_name)^=""))
                 , out_df   = out.non_ohphs_empl_by_region_mth
                 , group    = region date
                 , sum      = num_employed 
);

*----------------------------------------------------------------------------------------
*	Explanation for jump from 2006Q4 to 2007Q1
*----------------------------------------------------------------------------------------;
data sa_flag;
	set ohphs_sort;
		by unique_id;
		 if first.unique_id then new_flag = 1; else new_flag = 0;
			diff = num_employed - lag(num_employed); if new_flag = 1 then diff = 0; 
			where lowcase(strip(naics_3dg_subcategory)) = "social assistance";
			if new_flag = 1 and year in (2006,2007);
run;
%util_dat_aggregate(
                   df       = sa_flag
                 , out_df   = sa_agg
                 , group    = date
                 , sum      = num_employed 
);
* The jump in 2007Q1 is caused by entry of new firms.
Possible Explanation 1:
From 2006Q4 to 2007Q1, a lot of new firms were re-classified under social assistance NAICS code (). This re-classification caused a jump of about 50,000 (qtrly) or 16,000 (monthly)
Possible Explanation 2:
Some policy change incentivized new firms to enter into social assistance market and employ more people.
;

%let end_time = %sysfunc(time());
%let timeTaken = %sysevalf(%sysfunc(mdy(1,1,1960))+&end_time.-&start_time.);
%let timeTaken = %sysfunc(putn(&timeTaken.,e8601tm15.6));

%put NOTE: Program took &timeTaken. to run;
 