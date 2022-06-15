/*=================================================================================================*\
|Author(s) : Saani Rawat
|Purpose   : Benchmark paper's data against external data source: BLS series ID: SMS39000006562000001
|History   : Date 		By Description
			 15 Jun 22  SR Prepared benhcmarking code
\*=================================================================================================*/


%include "C:\Users\rawatsa\OneDrive - University of Cincinnati\sas_utility_functions\util_load_macro_functions.sas";
%util_load_macro_functions(C:\Users\rawatsa\OneDrive - University of Cincinnati\sas_utility_functions,subfolder=1);
%util_fmt_std_graphics(debug=0);

%let extracts = C:\QCEW Data - Ohio\ES202\extracts;
%let root = C:\Users\rawatsa\OneDrive - University of Cincinnati\SASprojects\ohphs_covid_impact;
%let out = &root.\data;

libname extr "&extracts.";
libname out "&out.";

*----------------------------------------------------------------------------------------
*	Importing BLS data
*----------------------------------------------------------------------------------------;
proc import datafile="&out./bls_employment_benchmarking_data.xlsx" dbms=xlsx replace out= bls_data;
	sheet= "data";
run;

%util_dat_pivot_longer(df = bls_data
                      , out_df = bls_df 
                      , id_cols = year
                      , names_to = month
                      , values_to = employment /*in 1000s */
                      );

*----------------------------------------------------------------------------------------
*	Merging BLS and OJFS data
*----------------------------------------------------------------------------------------;
data ohphs_empl;
	merge out.ohphs_empl_all_mth bls_df (drop=_label_);
		employment = employment*1000;
		num_employed_yoy = num_employed/lag12(num_employed) - 1;
		employment_yoy = employment/lag12(employment) - 1;
run;

*----------------------------------------------------------------------------------------
*	Plotting and comparing year-over-year growth rates
*----------------------------------------------------------------------------------------;
%util_dat_pivot_longer(df = ohphs_empl (keep = date num_employed_yoy employment_yoy where=(date ^= .))
                   , out_df = ohphs_empl_t
                   , id_cols = date
                   , pivot_cols = num_employed_yoy employment_yoy
                   , names_to = type
                   , values_to = growth
                   );
data ohphs_empl_t2;
	set ohphs_empl_t;
		if strip(type) = "num_employed_yoy" then source = "OJFS";
		if strip(type) = "employment_yoy" then source = "BLS";
run;
%util_plt_line(df = ohphs_empl_t2 
                , x = date
                , y = growth
				, color = source
                , x_lab = "Date"
                , y_lab = "annual growth"
                , title = "Healthcare Employment growth: Benchmarking plot"
                , subtitle = "OJFS unit-level data vs BLS aggregate data"
                , legend_hide = 0
                , y_scale = percent6.1
				, highlight_x_start = "30sep2007"d "31mar2020"d
				, highlight_x_end = "31dec2009"d "30jun2021"d
                , highlight_x_lab = "Super Important Period"
                );
