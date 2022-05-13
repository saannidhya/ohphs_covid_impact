/*=================================================================================================*\
|Author(s) : Saani Rawat
|Purpose   : Exploratory Data Analysis
|History   : Date 		By Description
			 7 May 22   SR Plot Ohio Public Health Sector Employment: Aggregated and breakout
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
*	Aggregate  Employment: Plots
*----------------------------------------------------------------------------------------;
*num employed;
%util_plt_line(df = out.ohphs_empl_all_qtr
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


*----------------------------------------------------------------------------------------
*	Breakout Employment: Plots
*----------------------------------------------------------------------------------------;
*num employed;
%util_plt_line(df = out.ohphs_empl_by_subcat_mth
                , x = date
                , y = num_employed
				, color = naics_3dg
                , x_lab = "Date"
                , y_lab = "Number of Employed persons"
                , title = "Ohio Public Health Sector: Employment level"
                , subtitle = "2006 - 2021"
                , highlight_x_start = "30sep2007"D "31dec2019"d 
                , highlight_x_end   = "30jun2009"D "30jun2021"d
                , legend_lab = ""
				, highlight_x_lab = "Recession period" 
                , y_scale = comma20.
				, color_palette = cxe41a1c cx377eb8 cx4daf4a cx984ea3
);
%util_plt_line(df = out.ohphs_empl_by_subcat_qtr
                , x = date
                , y = num_employed
				, color = naics_3dg
                , x_lab = "Date"
                , y_lab = "Number of Employed persons"
                , title = "Ohio Public Health Sector: Employment level"
                , subtitle = "2006 - 2021"
                , highlight_x_start = "30sep2007"D "31dec2019"d 
                , highlight_x_end   = "30jun2009"D "30jun2021"d
                , legend_lab = ""
				, highlight_x_lab = "Recession period" 
                , y_scale = comma20.
				, color_palette = cxe41a1c cx377eb8 cx4daf4a cx984ea3
);

*----------------------------------------------------------------------------------------
*	Aggregate: OHPHS vs Non-OHPHS
*----------------------------------------------------------------------------------------;
data ohphs_empl_all_qtr;
	set out.ohphs_empl_all_qtr;
run;
data non_ohphs_empl_all_qtr;
	set out.non_ohphs_empl_all_qtr;
run;
data empl_all_qtr;
	merge ohphs_empl_all_qtr (rename= (num_employed = ohphs_num_employed)) non_ohphs_empl_all_qtr (rename= (num_employed = non_ohphs_num_employed));
	by date;
run;
%util_dat_pivot_longer(df = empl_all_qtr
                   , out_df = empl_all_qtr_t
                   , id_cols = date
                   , pivot_cols = ohphs_num_employed	non_ohphs_num_employed
                   , names_to = type
                   , values_to = value
                   );
data ;
	set ;
run;
%util_plt_line(df = empl_all_qtr_t
                , x = date
                , y = value
				, color = type 
				, title = "Public Health Sector vs Other Sectors in Ohio: 2006Q1 to 2021Q2"
				, y_scale = comma10.
				, highlight_x_start = "31mar2020"d
				, highlight_x_end = "30jun2021"d
                );
%util_plt_line(df = empl_all_qtr
                , x = date
                , y = ohphs_num_employed
				, y2 = non_ohphs_num_employed
				, title = "Public Health Sector vs Other Sectors in Ohio: 2006Q1 to 2021Q2"
				, y_scale = comma10.
				, y2_scale = comma10.
				, y_lab = "Public Health workers"
				, y2_lab = "Non-public health workers"
				, highlight_x_start = "30sep2007"d "31mar2020"d
				, highlight_x_end = "30sep2009"d "30jun2021"d
                );


*----------------------------------------------------------------------------------------
*	Aggregate: Job creation and destruction
*----------------------------------------------------------------------------------------;

%util_dat_pivot_longer(df = out.ohphs_job_vars_all_qtr
                   , out_df = ohphs_job_vars_all_qtr
                   , id_cols = date
                   , pivot_cols = change_in_num_employed	jobs_created	jobs_destroyed
                   , names_to = type
                   , values_to = value
                   );
%util_plt_line(df = ohphs_job_vars_all_qtr
                , x = date
                , y = value
				, color = type 
				, title = "Public Health Sector in Ohio: 2006Q1 to 2021Q2"
				, subtitle = "Jobs Created, Destroyed and overall change in employment"
				, y_scale = comma10.
				, highlight_x_start = "31mar2020"d
				, highlight_x_end = "30jun2021"d
                );