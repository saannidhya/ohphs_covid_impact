/*=================================================================================================*\
|Author(s) : Saani Rawat
|Purpose   : Exploratory Data Analysis
|History   : Date 		By Description
			 7 May 22   SR Plot Ohio Public Health Sector Employment and Wage level: Aggregated and breakout
\*=================================================================================================*/

%include "C:\Users\rawatsa\OneDrive - University of Cincinnati\sas_utility_functions\util_load_macro_functions.sas";
%util_load_macro_functions(C:\Users\rawatsa\OneDrive - University of Cincinnati\sas_utility_functions,subfolder=1);
%util_fmt_std_graphics(debug=0);


*----------------------------------------------------------------------------------------
*	Aggregating Wage and Employment data to compute employment levels
*----------------------------------------------------------------------------------------;
%util_dat_aggregate(
                   df       = ohphs
                 , out_df   = ohphs_agg 
                 , group    = year quarter 
                 , sum      = wage num_employed
);
%util_dat_aggregate(
                   df       = ohphs
                 , out_df   = ohphs_agg_by_subsector
                 , group    = naics_3dg_subcategory year quarter 
                 , sum      = wage num_employed
);

data ohphs_agg2;
	set ohphs_agg;
	date = yyq(year,quarter); format date yyq6.;
run;
data ohphs_agg_by_subsector2;
	set ohphs_agg_by_subsector;
	date = yyq(year,quarter); format date yyq6.;
run;

*----------------------------------------------------------------------------------------
*	Aggregated Wage and Employment: Plots
*----------------------------------------------------------------------------------------;
*num employed;
%util_plt_line(df = ohphs_agg2
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

*wages;
%util_plt_line(df = ohphs_agg2
                , x = date
                , y = wage
                , x_lab = "Date"
                , y_lab = "Wages"
                , title = "Ohio Public Health Sector: Wage level"
                , subtitle = "2006 - 2021"
                , highlight_x_start = "30sep2007"D "31dec2019"d 
                , highlight_x_end   = "30jun2009"D "30jun2021"d
                , legend_lab = ""
				, highlight_x_lab = "Recession period" 
                , y_scale = comma20.
);


*----------------------------------------------------------------------------------------
*	Breakout of Wage and Employment: Plots
*----------------------------------------------------------------------------------------;
*num employed;
%util_plt_line(df = ohphs_agg_by_subsector2
                , x = date
                , y = num_employed
				, color = naics_3dg_subcategory
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

*wages;
%util_plt_line(df = ohphs_agg_by_subsector2
                , x = date
                , y = wage
				, color = naics_3dg_subcategory
                , x_lab = "Date"
                , y_lab = "Wages"
                , title = "Ohio Public Health Sector: Wage level"
                , subtitle = "2006 - 2021"
                , highlight_x_start = "30sep2007"D "31dec2019"d 
                , highlight_x_end   = "30jun2009"D "30jun2021"d
                , legend_lab = ""
				, highlight_x_lab = "Recession period" 
                , y_scale = comma20.
				, color_palette = cxe41a1c cx377eb8 cx4daf4a cx984ea3

);



