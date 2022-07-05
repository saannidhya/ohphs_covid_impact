/*=================================================================================================*\
|Author(s) : Saani Rawat
|Purpose   : Data tables for measuring covid impact on Ohio's public health sector
|History   : Date 		By Description
			 13 Jun 22  SR Created average job creation, destruction, reallocation rates pre and post COVID
|Inputs    : out.ohphs_job_rates_by_cat, out.ohphs_job_rates_all_mth
|Outputs   : out.ohphs_job_rates_measure
\*=================================================================================================*/


%include "C:\Users\rawatsa\OneDrive - University of Cincinnati\sas_utility_functions\util_load_macro_functions.sas";
%util_load_macro_functions(C:\Users\rawatsa\OneDrive - University of Cincinnati\sas_utility_functions,subfolder=1);

%let extracts = C:\QCEW Data - Ohio\ES202\extracts;
%let root = C:\Users\rawatsa\OneDrive - University of Cincinnati\SASprojects\ohphs_covid_impact;
%let out = &root.\data;

libname extr "&extracts.";
libname out "&out.";

*----------------------------------------------------------------------------------------
*	Finding average job creation, destruction and reallocation rates pre and post COVID
*----------------------------------------------------------------------------------------;
data ohphs_job_rates_all_mth;
	set out.ohphs_job_rates_by_cat (rename=(sub_category = category)) out.ohphs_job_rates_all_mth ;
		if date < "31mar2020"d then covid_flag = 0;
		else covid_flag = 1;
run;

proc sql;
	create table ohphs_job_rates_measure as
		select  category, covid_flag, 
				mean(job_creation_rate) as job_creation_rate format=percent6.1,	
				mean(job_destruction_rate) as job_destruction_rate format=percent6.1,	
				mean(job_reallocation_rate) as job_reallocation_rate format=percent6.1,	
				mean(net_employment_rate) as net_employment_rate format=percent6.1
			from ohphs_job_rates_all_mth (where=(date ^= "31jan2006"d))
				group by category, covid_flag;
quit;

data out.ohphs_job_rates_measure;
	set ohphs_job_rates_measure;
			creation_diff_in_pp = (job_creation_rate - lag(job_creation_rate))*100;
			destruction_diff_in_pp = (job_destruction_rate - lag(job_destruction_rate))*100;
		if first.category then creation_diff_in_pp = . ; if first.category then destruction_diff_in_pp = . ;
			jobs_lost_measure = destruction_diff_in_pp - creation_diff_in_pp;
		output;
		by category;
run;


