**********************************************************************************************************************************************;
** this code computes one ways, two ways, and fully saturated as well as marginals controlling for age or size;
** Now industry and year effects ;
** Using Initial Size Class methodology;
** Sept 3, 2012;
** *******************************************************************************************************************************************;

libname data '/projects4/arts422/size_age/data/saturated';run;
libname out '/projects4/arts422/size_age/data/saturated';

options mprint mlogic;

%macro mydata(cont);
    
title "intermediate case";run;

%if "&cont"="c" %then %do;
	data tmp;
	      set data.celliszageyrind_c;
	run;
    %end;

%else %do;
	data tmp;
	      set data.celliszageyrind;
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
   class ifsizen fage5n year2 indetailf;
   weight denom;
   var pos_r neg_r net_r bpos_r dneg_r;
output out=tmp1 mean=;run;

proc summary data=tmp nway;
   class ifsizen fage5n year2 indetailf;
   var denom;
   output out=tmp2 sum=;run;

proc sort data=tmp1;by year2 indetailf ifsizen fage5n;run;
proc sort data=tmp2;by year2 indetailf ifsizen fage5n;run;


data tmp;
  merge tmp1 tmp2;by year2 indetailf ifsizen fage5n;
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
* one way age model controlling for year and industry;
*****************************************************;

    proc sort data=tmp&death;
	by year2 indetailf;
    run;
    
proc glm data=tmp&death outstat=s1;
   class broad_age ;
    absorb year2 indetailf;
    weight denom;
	id idnum;
    model &depvar = broad_age / solution;
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
 yhat1wa&iy.&cont.&id.i=estimatea;
run;

**************************************;
* compare predicted and actual ;
**************************************;

proc summary data=tmp1 nway;
   class broad_age ;
   weight denom;
   var &depvar yhat1wa&iy.&cont.&id.i;
 output out=out.Oway_&depvar._indyr_a&cont.i mean=;run;

proc print data=out.Oway_&depvar._indyr_a&cont.i ;run; 
* note the unconditional mean for group 5-8 = .550;


*****************************************************;
* one way size model controlling for year and industry;
*****************************************************;
    proc sort data=tmp&death;
	by year2 indetailf;
    run;

proc glm data=tmp&death outstat=s1;
   class broad_size ;
    absorb year2 indetailf;
    weight denom;
	id idnum;
    model &depvar = broad_size / solution;
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
 yhat1ws&iy.&cont.&id.i=estimates;
run;

**************************************;
* compare predicted and actual ;
**************************************;

proc summary data=tmp1 nway;
   class broad_size ;
   weight denom;
   var &depvar yhat1ws&iy.&cont.&id.i;
 output out=out.Oway_&depvar._indyr_s&cont.i mean=;run;

proc print data=out.Oway_&depvar._indyr_s&cont.i ;run; 
* note the unconditional mean for group 5-8 = .550;


*************************************************;
* two way model controlling for year and industry;
*************************************************;
    proc sort data=tmp&death;
	by year2 indetailf;
    run;

proc glm data=tmp&death outstat=s1;
   class broad_age broad_size;
    absorb year2 indetailf;
    weight denom;
	id idnum;
    model &depvar = broad_age broad_size / solution;
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

    data out.tway_&depvar._indyr&cont.ib;
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
 output out=out.tway_&depvar._indyr&cont.i mean=;run;

proc print data=out.tway_&depvar._indyr&cont.i ;run; 
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

proc sort data=tmp&death; by year2 indetailf;

proc glm data=tmp&death outstat=s2 ;
   class broad_age broad_size;
    absorb year2 indetailf;
    weight denom;
	id idnum;
    model &depvar = broad_age*broad_size / solution;
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
 output out=out.tway_sat_&depvar._indyr&cont.i  mean=;run;

proc print data=out.tway_sat_&depvar._indyr&cont.i ;run; 

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
output out=out.tway_partsize1_&depvar._indyr&cont.i mean=yhat&tw.&iy.&p.&cont.&id.i;run;

title "size partial without interactions";run;

proc print data=out.tway_partsize1_&depvar._indyr&cont.i;run;

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
output out=out.tway_sat_partsize1_&depvar._indyr&cont.i mean=yhat&tw.&iy.&s.&p.&cont.&id.i;run;

title "size partial with interactions";run;

proc print data=out.tway_sat_partsize1_&depvar._indyr&cont.i;run;

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
output out=out.tway_partage1_&depvar._indyr&cont.i mean=yhat&tw.&iy.&p.&cont.&id.i;run;

title "age partial without interactions";run;

proc print data=out.tway_partage1_&depvar._indyr&cont.i;run;

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
output out=out.tway_sat_partage1_&depvar._indyr&cont.i mean=yhat&tw.&iy.&s.&p.&cont.&id.i;run;

title "age partial with interactions";run;

proc print data=out.tway_sat_partage1_&depvar._indyr&cont.i;run;


****************************;
* merge all the datasets ;
****************************;


%mend;

%robust(net_r,2w,iy,s,p,,,1);
%robust(pos_r,2w,iy,s,p,,,2);
%robust(neg_r,2w,iy,s,p,,,3);
%robust(bpos_r,2w,iy,s,p,,,4);
%robust(dneg_r,2w,iy,s,p,,,5);
%robust(net_r,2w,iy,s,p,,c,1);
%robust(pos_r,2w,iy,s,p,,c,2);
%robust(neg_r,2w,iy,s,p,,c,3);


**************************************;
* merge data sets;
**************************************;

* first age size;

data out.twoway_indyri;
 merge  out.tway_net_r_indyrib out.tway_pos_r_indyrib out.tway_neg_r_indyrib out.tway_bpos_r_indyrib out.tway_dneg_r_indyrib
     out.tway_net_r_indyrcib out.tway_pos_r_indyrcib out.tway_neg_r_indyrcib;
     by parameter;
run;

data out.twowayhat_indyri;
 merge  out.tway_net_r_indyri out.tway_pos_r_indyri out.tway_neg_r_indyri out.tway_bpos_r_indyri out.tway_dneg_r_indyri
     out.tway_net_r_indyrci out.tway_pos_r_indyrci out.tway_neg_r_indyrci;
     by broad_age broad_size;
run;
												    
* now partials both saturated and not;

data out.tway_partialage_indyri;
 merge  out.tway_partage1_net_r_indyri out.tway_sat_partage1_net_r_indyri 
        out.tway_partage1_pos_r_indyri out.tway_sat_partage1_pos_r_indyri 
        out.tway_partage1_neg_r_indyri out.tway_sat_partage1_neg_r_indyri 
        out.tway_partage1_bpos_r_indyri out.tway_sat_partage1_bpos_r_indyri 
	out.tway_partage1_dneg_r_indyri out.tway_sat_partage1_dneg_r_indyri 
        out.tway_partage1_net_r_indyrci out.tway_sat_partage1_net_r_indyrci 
        out.tway_partage1_pos_r_indyrci out.tway_sat_partage1_pos_r_indyrci 
        out.tway_partage1_neg_r_indyrci out.tway_sat_partage1_neg_r_indyrci ;

     by broad_age;
run;

data out.tway_partialsize_indyri;
 merge  out.tway_partsize1_net_r_indyri out.tway_sat_partsize1_net_r_indyri 
        out.tway_partsize1_pos_r_indyri out.tway_sat_partsize1_pos_r_indyri 
        out.tway_partsize1_neg_r_indyri out.tway_sat_partsize1_neg_r_indyri 
        out.tway_partsize1_bpos_r_indyri out.tway_sat_partsize1_bpos_r_indyri 
	out.tway_partsize1_dneg_r_indyri out.tway_sat_partsize1_dneg_r_indyri 
        out.tway_partsize1_net_r_indyrci out.tway_sat_partsize1_net_r_indyrci 
        out.tway_partsize1_pos_r_indyrci out.tway_sat_partsize1_pos_r_indyrci 
        out.tway_partsize1_neg_r_indyrci out.tway_sat_partsize1_neg_r_indyrci ;

     by broad_size;
run;

* now one ways;

data out.oneway_size_indyri;
 merge  out.Oway_net_r_indyr_si out.Oway_pos_r_indyr_si out.Oway_neg_r_indyr_si out.Oway_bpos_r_indyr_si out.Oway_dneg_r_indyr_si
     out.Oway_net_r_indyr_sci(rename=(net_r=net_rc)) out.Oway_pos_r_indyr_sci(rename=(pos_r=pos_rc)) out.Oway_neg_r_indyr_sci(rename=(neg_r=neg_rc)) ;
     by broad_size;
run;

data out.oneway_age_indyri;
 merge  out.Oway_net_r_indyr_ai out.Oway_pos_r_indyr_ai out.Oway_neg_r_indyr_ai out.Oway_bpos_r_indyr_ai out.Oway_dneg_r_indyr_ai
     out.Oway_net_r_indyr_aci(rename=(net_r=net_rc)) out.Oway_pos_r_indyr_aci(rename=(pos_r=pos_rc)) out.Oway_neg_r_indyr_aci(rename=(neg_r=neg_rc)) ;
     by broad_age;
run;





