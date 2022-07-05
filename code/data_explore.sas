/*=================================================================================================*\
|Author(s) : Saani Rawat
|Purpose   : Exploratory Data Analysis
|History   : Date 		By Description
			 7 May 22   SR Plot Ohio Public Health Sector Employment: Aggregated and breakout
			 7 Jul 22   SR Added some comments
|Inputs	   : out.ohphs_empl_all_mth, out.ohphs_empl_by_subcat_mth, out.non_ohphs_empl_all_mth, out.ohphs_empl_by_county_mth, 
			 out.ohphs_job_vars_621_qtr, out.ohphs_job_vars_622_qtr, out.ohphs_job_vars_623_qtr, out.ohphs_job_vars_624_qtr, 
			 out.ohphs_job_vars_621_mth, out.ohphs_job_vars_622_mth, out.ohphs_job_vars_623_mth, out.ohphs_job_vars_624_mth
|Outputs   : out.ohphs_job_rates_all_mth, out.ohphs_job_rates_by_cat
\*=================================================================================================*/

%include "C:\Users\rawatsa\OneDrive - University of Cincinnati\sas_utility_functions\util_load_macro_functions.sas";
%util_load_macro_functions(C:\Users\rawatsa\OneDrive - University of Cincinnati\sas_utility_functions,subfolder=1);
/*%util_fmt_std_graphics(debug=0);*/

%let extracts = C:\QCEW Data - Ohio\ES202\extracts;
%let root = C:\Users\rawatsa\OneDrive - University of Cincinnati\SASprojects\ohphs_covid_impact;
%let out = &root.\data;

libname extr "&extracts.";
libname out "&out.";


*----------------------------------------------------------------------------------------
*	loading county mapping table
*----------------------------------------------------------------------------------------;
proc import datafile="&root.\docs\county_mapping_tbl.xlsx" dbms=xlsx replace out=county_mapping_tbl;
	sheet="mapping";
run;

*----------------------------------------------------------------------------------------
*	Employment: Plots
*----------------------------------------------------------------------------------------;
ods graphics on;
ods listing gpath="&root.\data\data_explore";
ods graphics / imagename="ts_ohphs_empl_all_mth" imagefmt=png 	reset;
*num employed;
%util_plt_line(df = out.ohphs_empl_all_mth
                , x = date
                , y = num_employed
                , x_lab = "Date"
                , y_lab = "Number of Employed persons"
                , title = "Ohio Public Health Sector: Employment level"
                , subtitle = "2006 - 2021"
                , highlight_x_start = "30sep2007"D "31dec2019"d 
                , highlight_x_end   = "30jun2009"D "30jun2021"d
                , legend_lab = ""
				, highlight_x_lab = "Recession period" 
                , y_scale = comma20.
);

ods graphics off;

*----------------------------------------------------------------------------------------
*	Breakout Employment by sub-categories: Plots
*----------------------------------------------------------------------------------------;
*num employed by NAICS sub-category;
data ohphs_empl_by_subcat_mth;
	set out.ohphs_empl_by_subcat_mth;
		if naics_3dg = "621" then sub_category = "Ambulatory Health Care Services";
		if naics_3dg = "622" then sub_category = "Hospitals";
		if naics_3dg = "623" then sub_category = "Nursing and Residential Care";
		if naics_3dg = "624" then sub_category = "Social Assistance";
run;
ods graphics on;
ods graphics on / reset=all outputfmt=png ;
ods listing gpath="&root.\data\data_explore";
ods graphics / imagename="ts_ohphs_empl_by_subcat_mth_full" imagefmt=png ;
/*ods pdf file="&root.\data\data_explore\ts_ohphs_empl_by_subcat_mth_full.pdf" ;*/
/*goptions device=jpg;*/
/*filename grafout '&root.\data\data_explore\single.jpg';*/
/*goptions reset=all gsfname=grafout gsfmode=replace device=jpg;*/
%util_plt_line(df = ohphs_empl_by_subcat_mth
                , x = date
                , y = num_employed
				, color = sub_category
                , x_lab = "Date"
                , y_lab = "Number of Employed persons"
                , title = "Ohio Public Health Sector: Employment level"
                , subtitle = "2006 - 2021"
                , highlight_x_start = "28feb2020"d 
                , highlight_x_end   = "30jun2021"d
                , legend_lab = ""
				, highlight_x_lab = "Recession period" 
                , y_scale = comma20.
/*				, line_patterns = 0*/
/*				, color_palette = cxe41a1c cx377eb8 cx4daf4a cx984ea3*/
);
/*filename grafout clear;*/
/*ods pdf close;*/
ods graphics off;
ods graphics on;
ods listing gpath="&root.\data\data_explore";
ods graphics / imagename="ts_ohphs_empl_by_subcat_mth" imagefmt=png ;
%util_plt_line(df = ohphs_empl_by_subcat_mth (where=(year(date) > 2018))
                , x = date
                , y = num_employed
				, color = sub_category
                , x_lab = "Date"
                , y_lab = "Number of Employed persons"
                , title = "Ohio Public Health Sector: Employment level"
                , subtitle = "2006 - 2021"
                , highlight_x_start = "31mar2020"d 
                , highlight_x_end   = "30jun2021"d
                , legend_lab = ""
				, highlight_x_lab = "Recession period" 
                , y_scale = comma20.
				, color_palette = cxe41a1c cx377eb8 cx4daf4a cx984ea3
);
ods graphics off;

*----------------------------------------------------------------------------------------
*	Aggregate: OHPHS vs Non-OHPHS
*----------------------------------------------------------------------------------------;
*monthly;
data ohphs_empl_all_mth;
	set out.ohphs_empl_all_mth;
run;
data non_ohphs_empl_all_mth;
	set out.non_ohphs_empl_all_mth;
run;
data empl_all_mth;
	merge ohphs_empl_all_mth (rename= (num_employed = ohphs_num_employed)) non_ohphs_empl_all_mth (rename= (num_employed = non_ohphs_num_employed));
	by date;
		ohphs_num_employed_y = ohphs_num_employed/lag12(ohphs_num_employed) - 1;
		non_ohphs_num_employed_y = non_ohphs_num_employed/lag12(non_ohphs_num_employed) - 1;
run;
%util_dat_pivot_longer(df = empl_all_mth (keep = date ohphs_num_employed non_ohphs_num_employed)
                   , out_df = empl_all_mth_t
                   , id_cols = date
                   , pivot_cols = ohphs_num_employed non_ohphs_num_employed
                   , names_to = type
                   , values_to = value
                   );
%util_dat_pivot_longer(df = empl_all_mth (keep = date ohphs_num_employed_y	non_ohphs_num_employed_y)
                   , out_df = empl_all_mth_t_y
                   , id_cols = date
                   , pivot_cols = ohphs_num_employed_y	non_ohphs_num_employed_y
                   , names_to = type
                   , values_to = value
                   );
data empl_all_mth_t_y;
	set empl_all_mth_t_y;
		if strip(type) = "ohphs_num_employed_y" then type = "Healthcare sector";
		if strip(type) = "non_ohphs_num_employed_y" then type = "Non-Healthcare sectors";
run;
ods graphics on;
ods listing gpath="&root.\data\data_explore";
ods graphics / imagename="ohphs_vs_nonohphs_yoy_growth" imagefmt=png ;
%util_plt_line(df = empl_all_mth_t_y
                , x = date
                , y = value
				, color = type 
				, title = "Healthcare Sector vs Non-Healthcare Sectors in Ohio"
				, subtitle = "Percent Change from a Year Ago: 2007Q1 to 2021Q2"
				, y_lab = "Employed Workers - Annual Change (%)"
				, y_scale = percent6.1
				, highlight_x_start = "30sep2007"d "31mar2020"d
				, highlight_x_end = "31dec2009"d "30jun2021"d
				, legend_lab = "growth"
				, color_palette =  cx998ec3
                );
ods graphics off;
%util_plt_line(df = empl_all_mth
                , x = date
                , y = ohphs_num_employed
				, y2 = non_ohphs_num_employed
				, title = "Public Health Sector vs Non-Public Sectors in Ohio: 2006Q1 to 2021Q2"
				, y_scale = comma10.
				, y2_scale = comma10.
				, y_lab = "Public Health workers"
				, y2_lab = "Non-public health workers"
				, highlight_x_start = "30sep2007"d "31mar2020"d
				, highlight_x_end = "30sep2009"d "30jun2021"d
                );
*----------------------------------------------------------------------------------------
*	Employment by region: Plots
*----------------------------------------------------------------------------------------;
data region_mth;
	merge out.ohphs_empl_by_county_mth work.county_mapping_tbl;
		by county_name;
run;
%util_dat_aggregate(
                   df       = region_mth (keep = county_name	date	num_employed region)
                 , out_df   = region_mth_agg
                 , group    = region date
                 , sum      = num_employed 
);
data region_mth_agg2;
	set region_mth_agg;
		by region;
		num_employed_y = num_employed/lag12(num_employed) - 1;
		if strip(region) = "urban" and year(date) = 2006 then num_employed_y = .;
run;
%util_plt_line(df = region_mth_agg2
                , x = date
                , y = num_employed_y
				, color = region 
/*				, title = "Public Health Sector in Ohio: 2006Q1 to 2021Q2"*/
/*				, subtitle = "Jobs Created, Destroyed and overall change in employment"*/
				, y_scale = percent6.1
				, highlight_x_start = "31mar2020"d
				, highlight_x_end = "30jun2021"d
				, y_lab = "Healthcare Workers (% Change from a year ago)"
                );


*----------------------------------------------------------------------------------------
*	Job creation and destruction
*----------------------------------------------------------------------------------------;
data ohphs_job_vars_all_mth (drop= date rename= (date2 = date));
	set out.ohphs_job_vars_all_mth;
	date2 = input(strip(date),date9.) ; format date2 date9.;
run;
data out.ohphs_job_rates_all_mth;
	merge out.ohphs_empl_all_mth ohphs_job_vars_all_mth ;
		by date;
			jobs_destroyed = abs(jobs_destroyed);
			if _n_ ^= 1 then do;
				job_creation_rate = jobs_created/num_employed;
				job_destruction_rate = jobs_destroyed/num_employed;
				job_reallocation_rate = job_creation_rate + job_destruction_rate;
				net_employment_rate = job_creation_rate - job_destruction_rate;
				excess_job_reallocation = job_reallocation_rate - abs(net_employment_rate);
			end;
run;
%util_dat_pivot_longer(df = out.ohphs_job_rates_all_mth (where=(date > "31mar2016"d ))
                   , out_df = ohphs_job_rates_all_mth_t
                   , id_cols = date
                   , pivot_cols = job_creation_rate	job_destruction_rate
                   , names_to = type
                   , values_to = value
                   );
%util_plt_line(df = ohphs_job_rates_all_mth_t 
                , x = date
                , y = value
				, color = type 
				, title = "Public Health Sector in Ohio: 2006Q1 to 2021Q2"
				, subtitle = "Jobs Created, Destroyed Rate"
				, y_scale = percent6.1
				, highlight_x_start = "31mar2020"d
				, highlight_x_end = "30jun2021"d
                );
* by subcategory;
data ohphs_job_vars_subcat (drop= date rename= (date2 = date));
/*	set out.ohphs_job_vars_621_qtr out.ohphs_job_vars_622_qtr out.ohphs_job_vars_623_qtr out.ohphs_job_vars_624_qtr;		*/
	set out.ohphs_job_vars_621_mth out.ohphs_job_vars_622_mth out.ohphs_job_vars_623_mth out.ohphs_job_vars_624_mth;		
	by category;
	date2 = input(date,date9.);
	format date2 date9.;
/*	date2 = intnx("qtr",input(strip(date),yyq6.),0,"end") ; format date2 date9.;*/
/*	date2 = intnx("mth",input(strip(date),yym6.),0,"end") ; format date2 date9.;*/
run;
data ohphs_empl_by_subcat_mth (drop=naics_3dg);
	set out.ohphs_empl_by_subcat_mth;
	length category $3;
	category = naics_3dg;
run;
data out.ohphs_job_rates_by_cat (drop=category);
/*	merge ohphs_empl_by_subcat_qtr ohphs_job_vars_subcat;*/
	merge ohphs_empl_by_subcat_mth ohphs_job_vars_subcat;
		by category date;
				jobs_destroyed = abs(jobs_destroyed);
				job_creation_rate = jobs_created/num_employed;
				job_destruction_rate = jobs_destroyed/num_employed;
				job_reallocation_rate = job_creation_rate + job_destruction_rate;
				net_employment_rate = job_creation_rate - job_destruction_rate;
				excess_job_reallocation = job_reallocation_rate - abs(net_employment_rate);

		if category = "621" then sub_category = "Ambulatory Health Care Services";
		if category = "622" then sub_category = "Hospitals";
		if category = "623" then sub_category = "Nursing and Residential Care Facilities";
		if category = "624" then sub_category = "Social Assistance";
run;
%util_plt_line(df = out.ohphs_job_rates_by_cat (where=(year(date) > 2018))
                , x = date
                , y = job_creation_rate
				, color = sub_category 
				, title = "Public Health Sector in Ohio: 2006Q1 to 2021Q2"
				, subtitle = "Jobs Creation Rate"
				, y_scale = percent6.1
				, highlight_x_start = "31mar2020"d
				, highlight_x_end = "30jun2021"d
                );
%util_plt_line(df = out.ohphs_job_rates_by_cat (where=(year(date) > 2018))
                , x = date
                , y = job_destruction_rate
				, color = sub_category 
				, title = "Public Health Sector in Ohio: 2006Q1 to 2021Q2"
				, subtitle = "Jobs Destruction Rate"
				, y_scale = percent6.1
				, highlight_x_start = "31mar2020"d
				, highlight_x_end = "30jun2021"d
                );
%util_plt_line(df = out.ohphs_job_rates_by_cat (where=(year(date) > 2018))
                , x = date
                , y = net_employment_rate
				, color = sub_category 
				, title = "Public Health Sector in Ohio: 2006Q1 to 2021Q2"
				, subtitle = "Net Employment Rate"
				, y_scale = percent6.1
				, highlight_x_start = "31mar2020"d
				, highlight_x_end = "30jun2021"d
                );


