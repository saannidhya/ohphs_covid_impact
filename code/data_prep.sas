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
libname out "&out.";

*----------------------------------------------------------------------------------------
* loading Ohio Employment data (for NAICS code 62 only)	
*----------------------------------------------------------------------------------------;
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
			from extr.masterfile_2006q1_2021q2
				where calculated naics_2dg = "62" and strip(state) = "OH";
quit;
*padding zeroes for year 2020;
data ohphs;
	set ohphs;
		 pad = put(input(pad,best3.),z3.);
		 RepUnit = put(input(RepUnit,best5.),z5.);
		 uin = put(input(uin,best7.),z7.);
		 unique_id = catx(strip(pad),strip(uin),strip(repunit));
run;

*----------------------------------------------------------------------------------------
*	Job creation and Job destruction variables for NAICS code 62
*----------------------------------------------------------------------------------------;
* sorting dataset by unique_id and date;
proc sort data=ohphs  out=ohphs_sort;
	by unique_id date;
run;

* aggregating by date to cross-check jobs created and destroyed numbers later;	
%util_dat_aggregate(
                   df       = ohphs_sort
                 , out_df   = ohphs_sort3 
                 , group    = date
                 , sum      = num_employed 
);

* storing all distinct dates in a list and requisite date column names;
proc sql noprint;
	select distinct date into :dts separated by " "
		from ohphs_sort;
quit;
%let dates_dts =date_%sysfunc(tranwrd(&dts.,%str( ),%str(_df date_)))_df;

* transposing to get unique_id as rows and quarters as columns. This deals with firms which originate and vanish in between the periods.;
%util_dat_pivot_wider(df = ohphs_sort (keep = unique_id date num_employed) 
                      , out_df = ohphs_sorted
                      , names_from = date
                      , values_from = num_employed
					  , names_prefix = date_
					  , values_fill = 0
                      );

* macro that creates dataset containing jobs created and destroyed variables;					  
%macro make_vars();
	data ohphs_sorted2;
		set ohphs_sorted;
			date_%scan(&dts.,1,' ')_df = 0;
		%do i = 2 %to %sysfunc(countw(&dts.));
			%let dt1 = %scan(&dts.,%eval(&i.-1),' ');
			%let dt2 = %scan(&dts.,&i.,' ');
			date_&dt2._df = date_&dt2. - date_&dt1.; 
		%end;
		keep unique_id _name_ &dates_dts.;
	run;

	data ohphs_jobs_created;
		set ohphs_sorted2;
		%do j = 1 %to %sysfunc(countw(&dates_dts.));
			%let dt = %scan(&dates_dts.,&j.,' ');
			if &dt.>= 0 then &dt. = &dt.;
			else &dt. = 0;
		%end;
	run;

	data ohphs_jobs_destroyed;
		set ohphs_sorted2;
		%do j = 1 %to %sysfunc(countw(&dates_dts.));
			%let dt = %scan(&dates_dts.,&j.,' ');
			if &dt. < 0 then &dt. = &dt.;
			else &dt. = 0;
		%end;
	run;

	proc summary data=ohphs_jobs_created;
		var &dates_dts.;
		output out=ohphs_jobs_created_agg (drop = _type_ _freq_) sum = ;
	run;
	proc summary data=ohphs_jobs_destroyed;
		var &dates_dts.;
		output out=ohphs_jobs_destroyed_agg (drop = _type_ _freq_) sum = ;
	run;
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
	proc sql;
		create table out.ohps_job_vars (drop = date_a date_b) as 
			select compress(date_a,"date_f") as date, (jobs_created + jobs_destroyed) as  change_in_num_employed, *
				from ohphs_jobs_created_agg_t (rename = (date = date_a)) as a, ohphs_jobs_destroyed_t (rename = (date = date_b)) as b
					where a.date_a = b.date_b;
	quit;
			
%mend make_vars;
%make_vars();


*----------------------------------------------------------------------------------------
*	Job creation and Job destruction variables for NAICS subcodes
*----------------------------------------------------------------------------------------;
* sorting dataset by unique_id and date;
proc sort data=ohphs  out=ohphs_sort;
	by unique_id date;
run;

* aggregating by date to cross-check jobs created and destroyed numbers later;	
%util_dat_aggregate(
                   df       = ohphs_sort
                 , out_df   = ohphs_sort3 
                 , group    = naics_3dg_subcategory date
                 , sum      = num_employed 
);

