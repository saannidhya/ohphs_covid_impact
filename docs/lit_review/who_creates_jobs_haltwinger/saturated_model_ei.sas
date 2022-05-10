**********************************************************************************************************************************************;
** this code computes one ways, two ways, and fully saturated as well as marginals controlling for age or size;
** Now excluding industry and year effects ;
** Initial Size Class methodology;
** Sept 3, 2012;
** *******************************************************************************************************************************************;
** NOW FOR ESTABLISHMENTS;
** *******************************************************************************************************************************************;

libname data '/projects4/arts422/size_age/data/saturated';run;
libname out '/projects4/arts422/size_age/data/saturated';

options mprint mlogic;

%macro mydata(cont);
    
title "intermediate case";run;

%if "&cont"="c" %then %do;
	data tmp;
	      set data.e_celliszageyrind_c;
	run;
    %end;

%else %do;
	data tmp;
	      set data.e_celliszageyrind;
	run;
    %end;
    

  *******************************;
  * redifine age and size classes;
  *******************************;

  data size;
  set tmp;
  if year2=2003;
  count=1;

proc summary data=size nway;
   class ifsize;
   var count;
output out=ifsize sum=;run;

proc sort data=ifsize;by ifsize;run;

data ifsize(keep=ifsize ifsizen);
  set ifsize;
  ifsizen=_N_;run;

proc sort data=ifsize;by ifsize;run;
proc print data=ifsize;run;


proc sort data=tmp;by ifsize;run;

data tmp;
  merge tmp ifsize;by ifsize;run;

data fage5;
  set tmp;if year2=2003;
  count=1;
run;

proc summary data=fage5 nway;
   class fage5;
   var count;
output out=fage5 sum=;run;

proc sort data=fage5;by fage5;run;

data fage5(keep=fage5 fage5n);
  set fage5;
  fage5n=_N_;
  %if "&cont"="c" %then %do;
  fage5n=_N_+1;
  %end; 
run;

proc sort data=fage5;by fage5;run;
proc print data=fage5;run;

proc sort data=tmp;by fage5;run;

*This is to create balanced set of age groups across years;

data tmp;
  merge tmp fage5;by fage5;
 if fage5n>=16 then fage5n=16;

** *********************************;
** Collapse data by new groups **;
** *********************************;

proc summary data=tmp nway;
   class ifsizen fage5n year2 indetail;
   weight denom;
   var pos_r neg_r net_r bpos_r dneg_r;
output out=tmp1 mean=;run;

proc summary data=tmp nway;
   class ifsizen fage5n year2 indetail;
   var denom;
   output out=tmp2 sum=;run;

proc sort data=tmp1;by year2 indetail ifsizen fage5n;run;
proc sort data=tmp2;by year2 indetail ifsizen fage5n;run;


data tmp;
  merge tmp1 tmp2;by year2 indetail ifsizen fage5n;
if fage5n=1 then broad_age=1;*note fage5n=fage5+1;
*if fage5n=1 then broad_age=1;*note fage5n=fage5+1;
if 1<fage5n<4 then broad_age=2;
if 4<=fage5n<6 then broad_age=3;
if 6<=fage5n<8 then broad_age=4;
if 8<=fage5n<10 then broad_age=5;
if 10<=fage5n<12 then broad_age=6;
if 12<=fage5n<14 then broad_age=7;
if 14<=fage5n<16 then broad_age=8;
if 16<=fage5n then broad_age=9;
broad_size=ifsizen;
if broad_size>=8 then broad_size=8;

idnum=_N_;
run;

    %mend;

%mydata();

** ***************************;
** real regressions;
** ***************************;

%macro robust(depvar,tw,iy,s,p,death,cont,id);

title "Results for &depvar";run;

    
************************************************************;
* set up data for job destruction runs that exclude startups;
************************************************************;

%if "&cont"="c" %then %do;
%mydata(&cont);
    %end;


%if "&death"="d" %then %do;
	data tmpd;
	    set tmp;
             if fage5n^= 1;    
	run;
    %end;




*****************************************************;
* one way age model no controls for year and industry;
*****************************************************;
    proc sort data=tmp&death;
	by year2 indetail;
    run;

proc glm data=tmp&death outstat=s1;
   class broad_age ;
    weight denom;
	id idnum;
    model &depvar = broad_age / solution noint;
*output out=pred1 p=yhat;
ods output ParameterEstimates=params1(keep= parameter estimate stderr) 
fitstatistics=fparams1 Nobs=nobs1(where=(label='Number of Observations Used'));
run;quit;run;    

proc print data=params1;run;
*proc contents data=pred1;run;
*proc means data=pred1;run;
proc print data=fparams1;
data params1a(keep=estimate broad_age rename=(estimate=estimatea));set params1; if substr(parameter,7,3)='age'; broad_age=substr(parameter,11,1)*1;run;
proc print data=params1a;run;

*proc sort data=pred1;*by idnum;*run;

**************************************************;
* merge in parameters and compute predicted values;
**************************************************;

proc sort data=tmp&death;by broad_age;run;
 data tmp1;
  merge params1a tmp&death;by broad_age;run;


data tmp1;
 set tmp1;
 yhat1wa&cont.&id.i=estimatea;
run;

**************************************;
* compare predicted and actual ;
**************************************;

proc summary data=tmp1 nway;
   class broad_age ;
   weight denom;
   var &depvar yhat1wa&cont.&id.i;
 output out=out.oway_e_&depvar._a&cont.i mean=;run;

proc print data=out.oway_e_&depvar._a&cont.i ;run; 
* note the unconditional mean for group 5-8 = .550;


*****************************************************;
* one way size model no controls for year and industry;
*****************************************************;
    proc sort data=tmp&death;
	by year2 indetail;
    run;

proc glm data=tmp&death outstat=s1;
   class broad_size ;
    weight denom;
	id idnum;
    model &depvar = broad_size / solution noint;
*output out=pred1 p=yhat;
ods output ParameterEstimates=params1(keep= parameter estimate stderr) 
fitstatistics=fparams1 Nobs=nobs1(where=(label='Number of Observations Used'));
run;quit;run;    

proc print data=params1;run;
*proc contents data=pred1;run;
*proc means data=pred1;run;
proc print data=fparams1;
data params1a(keep=estimate broad_size rename=(estimate=estimates));set params1; if substr(parameter,7,4)='size'; broad_size=substr(parameter,12,1)*1;run;
proc print data=params1a;run;

*proc sort data=pred1;*by idnum;*run;

**************************************************;
* merge in parameters and compute predicted values;
**************************************************;

proc sort data=tmp&death;by broad_size;run;
 data tmp1;
  merge params1a tmp&death;by broad_size;run;


data tmp1;
 set tmp1;
 yhat1ws&cont.&id.i=estimates;
run;

**************************************;
* compare predicted and actual ;
**************************************;

proc summary data=tmp1 nway;
   class broad_size ;
   weight denom;
   var &depvar yhat1ws&cont.&id.i;
 output out=out.oway_e_&depvar._s&cont.i mean=;run;

proc print data=out.oway_e_&depvar._s&cont.i ;run; 
* note the unconditional mean for group 5-8 = .550;



*************************************************;
* two way model ;
*************************************************;
    proc sort data=tmp&death;
	by year2 indetail;
    run;

proc glm data=tmp&death outstat=s1;
   class broad_age broad_size;
*    absorb year2 indetail;
    weight denom;
	id idnum;
    model &depvar = broad_age broad_size / solution noint;
*output out=pred1 p=yhat;
ods output ParameterEstimates=params1(keep= parameter estimate stderr) 
fitstatistics=fparams1 Nobs=nobs1(where=(label='Number of Observations Used'));
run;quit;run;    

proc print data=params1;run;
*proc contents data=pred1;run;
*proc means data=pred1;run;
proc print data=fparams1;
data params1a(keep=estimate broad_age rename=(estimate=estimatea));set params1; if substr(parameter,7,3)='age'; broad_age=substr(parameter,12,1)*1;run;
proc print data=params1a;run;
data params1s(keep=estimate broad_size rename=(estimate=estimates));set params1; if substr(parameter,7,4)='size'; broad_size=substr(parameter,12,1)*1;run;
proc print data=params1s;run;

*proc sort data=pred1;*by idnum;*run;

**************************************************;
* merge in parameters and compute predicted values;
**************************************************;

proc sort data=tmp&death;by broad_age;run;
 data tmp1;
  merge params1a tmp&death;by broad_age;run;

proc sort data=tmp1;by broad_size;run;
 data tmp1;
  merge params1s tmp1;by broad_size;run;

data tmp1;
 set tmp1;
 yhat&tw.&iy.&cont.&id.i=estimates + estimatea;
run;

    data out.tway_e_&depvar._&cont.ib;
	set params1;
	rename estimate=yhat&tw.&iy.&cont.&id.i;
    run;
**************************************;
* compare predicted and actual ;
**************************************;

proc summary data=tmp1 nway;
   class broad_age broad_size;
   weight denom;
   var &depvar yhat&tw.&iy.&cont.&id.i;
 output out=out.tway_e_&depvar._&cont.i mean=;run;

proc print data=out.tway_e_&depvar._&cont.i ;run; 
* note the unconditional mean for group 5-8 = .550;

proc summary data=tmp1 nway;
   class broad_size;
   weight denom;
   var &depvar yhat&tw.&iy.&cont.&id.i;
 output out=pred1checks mean=;run;

proc print data=pred1checks;run;

proc summary data=tmp1 nway;
   class broad_age;
   weight denom;
   var &depvar yhat&tw.&iy.&cont.&id.i;
 output out=pred1checka mean=;run;

proc print data=pred1checka ;run;


**************************************;
* now with interaction terms;
**************************************;

proc sort data=tmp&death; by year2 indetail;

proc glm data=tmp&death outstat=s2 ;
   class broad_age broad_size;
*    absorb year2 indetail;
    weight denom;
	id idnum;
    model &depvar = broad_age*broad_size / solution noint;
*output out=pred2 p=yhat;
ods output ParameterEstimates=params2(keep= parameter estimate stderr )
fitstatistics=fparams2 Nobs=nobs1(where=(label='Number of Observations Used'));
*PredictedValues=pred2;* too much output with  this option --- need to also include in model;
run;quit;run;    

proc print data=params2;run;
*proc contents data=pred2;*run;
*proc means data=pred2;*run;
proc print data=fparams2;
*proc print data=pred1;*run;
data params1as(keep=estimate broad_age broad_size);set params2; 
broad_age=substr(parameter,22,1)*1;
broad_size=substr(parameter,24,1)*1;run;

proc print data=params1as;run;


*proc sort data=pred2;*by idnum;*run;
*proc sort data=tmp;*by idnum;*run;

**************************************************;
* merge in parameters and compute predicted values;
**************************************************;

proc sort data=tmp&death;by broad_age broad_size;run;

data tmp2;
  merge params1as tmp&death;by broad_age broad_size;run;

  data tmp2;
 set tmp2;
 yhat&tw.&iy.&s.&cont.&id.i=estimate;
run;

**************************************;
* compare predicted and actual ;
**************************************;

proc summary data=tmp2 nway noprint;
   class broad_age broad_size;
   weight denom;
   var &depvar yhat&tw.&iy.&s.&cont.&id.i;
 output out=out.tway_e_sat_&depvar._&cont.i  mean=;run;

proc print data=out.tway_e_sat_&depvar._&cont.i ;run; 

proc summary data=tmp2 nway;
   class broad_size;
   weight denom;
   var &depvar yhat&tw.&iy.&s.&cont.&id.i;
 output out=pred2checks mean=;run;

proc print data=pred2checks;run;

proc summary data=tmp2 nway;
   class broad_age;
   weight denom;
   var &depvar yhat&tw.&iy.&s.&cont.&id.i;
 output out=pred2checka mean=;run;

proc print data=pred2checka;run;

* size partial;

**************************************;
* now try partials or counterfactuals;
**************************************;

***************;
* two way model;
***************;

proc summary data=tmp1 nway;
  class broad_age broad_size;
   var yhat&tw.&iy.&cont.&id.i;
output out=partial1 mean=;run; * note this is just unduplicating;
                               * note tmp1 is from the two way model;

proc summary data=tmp1 nway;
   class broad_age;
   var denom;
   output out=agesum sum=;run;   * compute age distribution economywide and merge it in;

proc sort data=partial1;by broad_age;run;
proc sort data=agesum;by broad_age;run;

proc print data=agesum;run;
proc print data=partial1;run;

data partial1;
  merge partial1 agesum;by broad_age;run; * note here all sizes are getting the same distribution of age (e.g. size 1-8 get same share of startups, age 1-3.. as size 9-25.;

******************************;
* compute size partial;
******************************;

proc summary data=partial1 nway;
   class broad_size;
   var yhat&tw.&iy.&cont.&id.i;
   weight denom;
output out=out.tway_e_partsize1_&depvar._&cont.i mean=yhat&tw.&iy.&p.&cont.&id.i;run;

title "size partial without interactions";run;

proc print data=out.tway_e_partsize1_&depvar._&cont.i;run;

*********************************;
* two way model with interactions;
*********************************;

proc summary data=tmp2 nway;
  class broad_age broad_size;
   var yhat&tw.&iy.&s.&cont.&id.i;
output out=partial2 mean=;run; * note this is just unduplicating;
                               * note tmp2 is from the two way model with interactions;

proc summary data=tmp2 nway;
   class broad_age;
   var denom;
output out=agesum sum=;run;  * compute age distribution economywide and merge it in;

proc sort data=partial2;by broad_age;run;
proc sort data=agesum;by broad_age;run;

data partial2;
    merge partial2 agesum;by broad_age;run; * note here all sizes are getting the same distribution of age (e.g. size 1-8 get same share of startups, age 1-3.. as size 9-25.;
     
******************************;
* compute size partial;
******************************;

proc summary data=partial2 nway;
   class broad_size;
   var yhat&tw.&iy.&s.&cont.&id.i;
   weight denom;
output out=out.tway_e_sat_partsize1_&depvar._&cont.i mean=yhat&tw.&iy.&s.&p.&cont.&id.i;run;

title "size partial with interactions";run;

proc print data=out.tway_e_sat_partsize1_&depvar._&cont.i;run;

title "results for &depvar";run;

********************;
* now do age partial;
********************;

********************;
* two way model;
********************;

proc summary data=tmp1 nway;
  class broad_age broad_size;
   var yhat&tw.&iy.&cont.&id.i;
output out=partial1 mean=;run; * note this is just unduplicating;
                               * note tmp1 is from the two way model;

proc summary data=tmp1 nway;
   class broad_size;
   var denom;
output out=sizesum sum=;run;* compute size distribution economywide and merge it in;

*proc print data=sizesum;run;
*proc print data=partial1;run;

proc sort data=partial1;by broad_size;run;
proc sort data=sizesum;by broad_size;run;


data partial1;
  merge partial1 sizesum;by broad_size; * note here all ages are getting the same distribution of size (e.g. age 1 gets same share of small and large as age 10+;
     
******************************;
* compute age partial;
******************************;

proc summary data=partial1 nway;
   class broad_age;
   var yhat&tw.&iy.&cont.&id.i;
   weight denom;
output out=out.tway_e_partage1_&depvar._&cont.i mean=yhat&tw.&iy.&p.&cont.&id.i;run;

title "age partial without interactions";run;

proc print data=out.tway_e_partage1_&depvar._&cont.i;run;

*********************************;
* two way model with interactions;
*********************************;

proc summary data=tmp2 nway;
  class broad_age broad_size;
   var yhat&tw.&iy.&s.&cont.&id.i;
output out=partial2 mean=;run; * note this is just unduplicating;
                               * note tmp2 is from the two way model with interactions;

proc summary data=tmp2 nway;
   class broad_size;
   var denom;
output out=sizesum sum=;run; * compute size distribution economywide and merge it in;

*proc print data=sizesum;run;
*proc print data=partial2;run;

proc sort data=partial2;by broad_size;run;
proc sort data=sizesum;by broad_size;run;

data partial2;
  merge partial2 sizesum;by broad_size; * note here all ages are getting the same distribution of size (e.g. age 1 gets same share of small and large as age 10+;

******************************;
* compute age partial;
******************************;

proc summary data=partial2 nway;
   class broad_age;
   var yhat&tw.&iy.&s.&cont.&id.i;
   weight denom;
output out=out.tway_e_sat_partage1_&depvar._&cont.i mean=yhat&tw.&iy.&s.&p.&cont.&id.i;run;

title "age partial with interactions";run;

proc print data=out.tway_e_sat_partage1_&depvar._&cont.i;run;


****************************;
* merge all the datasets ;
****************************;


%mend;

%robust(net_r,2w,,s,p,,,1);
%robust(pos_r,2w,,s,p,,,2);
%robust(neg_r,2w,,s,p,,,3);
%robust(bpos_r,2w,,s,p,,,4);
%robust(dneg_r,2w,,s,p,,,5);
%robust(net_r,2w,,s,p,,c,1);
%robust(pos_r,2w,,s,p,,c,2);
%robust(neg_r,2w,,s,p,,c,3);


**************************************;
* merge data sets;
**************************************;

* first age size;

data out.twoway_ei;
 merge  out.tway_e_net_r_ib out.tway_e_pos_r_ib out.tway_e_neg_r_ib out.tway_e_bpos_r_ib out.tway_e_dneg_r_ib
     out.tway_e_net_r_cib out.tway_e_pos_r_cib out.tway_e_neg_r_cib;
     by parameter;
run;

data out.twowayhat_ei;
 merge  out.tway_e_net_r_i out.tway_e_pos_r_i out.tway_e_neg_r_i out.tway_e_bpos_r_i out.tway_e_dneg_r_i
     out.tway_e_net_r_ci out.tway_e_pos_r_ci out.tway_e_neg_r_ci;
     by broad_age broad_size;
run;
												    
* now partials both saturated and not;

data out.tway_e_partialage_i;
 merge  out.tway_e_partage1_net_r_i out.tway_e_sat_partage1_net_r_i 
        out.tway_e_partage1_pos_r_i out.tway_e_sat_partage1_pos_r_i 
        out.tway_e_partage1_neg_r_i out.tway_e_sat_partage1_neg_r_i 
        out.tway_e_partage1_bpos_r_i out.tway_e_sat_partage1_bpos_r_i 
	out.tway_e_partage1_dneg_r_i out.tway_e_sat_partage1_dneg_r_i 
        out.tway_e_partage1_net_r_ci out.tway_e_sat_partage1_net_r_ci 
        out.tway_e_partage1_pos_r_ci out.tway_e_sat_partage1_pos_r_ci 
        out.tway_e_partage1_neg_r_ci out.tway_e_sat_partage1_neg_r_ci ;

     by broad_age;
run;

data out.tway_e_partialsize_i;
 merge  out.tway_e_partsize1_net_r_i out.tway_e_sat_partsize1_net_r_i 
        out.tway_e_partsize1_pos_r_i out.tway_e_sat_partsize1_pos_r_i 
        out.tway_e_partsize1_neg_r_i out.tway_e_sat_partsize1_neg_r_i 
        out.tway_e_partsize1_bpos_r_i out.tway_e_sat_partsize1_bpos_r_i 
	out.tway_e_partsize1_dneg_r_i out.tway_e_sat_partsize1_dneg_r_i 
        out.tway_e_partsize1_net_r_ci out.tway_e_sat_partsize1_net_r_ci 
        out.tway_e_partsize1_pos_r_ci out.tway_e_sat_partsize1_pos_r_ci 
        out.tway_e_partsize1_neg_r_ci out.tway_e_sat_partsize1_neg_r_ci ;

     by broad_size;
run;

* now one ways;

data out.oneway_e_size_i;
 merge  out.oway_e_net_r__si out.oway_e_pos_r__si out.oway_e_neg_r__si out.oway_e_bpos_r__si out.oway_e_dneg_r__si
     out.oway_e_net_r__sci(rename=(net_r=net_rc)) out.oway_e_pos_r__sci(rename=(pos_r=pos_rc)) out.oway_e_neg_r__sci(rename=(neg_r=neg_rc)) ;
     by broad_size;
run;

data out.oneway_e_age_i;
 merge  out.oway_e_net_r__ai out.oway_e_pos_r__ai out.oway_e_neg_r__ai out.oway_e_bpos_r__ai out.oway_e_dneg_r__ai
     out.oway_e_net_r__aci(rename=(net_r=net_rc)) out.oway_e_pos_r__aci(rename=(pos_r=pos_rc)) out.oway_e_neg_r__aci(rename=(neg_r=neg_rc)) ;
     by broad_age;
run;





