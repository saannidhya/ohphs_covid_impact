/*=================================================================================================*\
|Author(s) : Saani Rawat
|Purpose   : Data tables for measuring covid impact on Ohio's public health sector
|History   : Date 		By Description
			 13 Jun 22  SR Created average job creation, destruction, reallocation rates pre and post COVID
\*=================================================================================================*/


%include "C:\Users\rawatsa\OneDrive - University of Cincinnati\sas_utility_functions\util_load_macro_functions.sas";
%util_load_macro_functions(C:\Users\rawatsa\OneDrive - University of Cincinnati\sas_utility_functions,subfolder=1);

%let extracts = C:\QCEW Data - Ohio\ES202\extracts;
%let root = C:\Users\rawatsa\OneDrive - University of Cincinnati\SASprojects\ohphs_covid_impact;
%let out = &root.\data\data_prep;

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
	create table ohphs_job_rates_covid as
		select  category, covid_flag, 
				mean(job_creation_rate) as job_creation_rate format=percent6.1,	
				mean(job_destruction_rate) as job_destruction_rate format=percent6.1,	
				mean(job_reallocation_rate) as job_reallocation_rate format=percent6.1,	
				mean(net_employment_rate) as net_employment_rate format=percent6.1,	
				mean(excess_job_reallocation) as excess_job_reallocation format=percent6.1
			from ohphs_job_rates_all_mth (where=(date ^= "31jan2006"d))
				group by category, covid_flag;
quit;

*----------------------------------------------------------------------------------------
*	Compute Job reallocations due to between-sector movements
*----------------------------------------------------------------------------------------;


*----------------------------------------------------------------------------------------
*	Compute sum of excess Job reallocations within each sector
*----------------------------------------------------------------------------------------;


