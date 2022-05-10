**********************************************************************************************************************************************;
** this code computes one ways, two ways, and fully saturated as well as marginals controlling for age or size;
** Now excluding industry and year effects ;
** Sept 3, 2012;
** *******************************************************************************************************************************************;
** NOW BY SECTOR;
** *******************************************************************************************************************************************;

libname data '/projects4/arts422/size_age/data/saturated';run;
libname out '/projects4/arts422/size_age/data/saturated';

options mprint mlogic;

%macro mydata(cont);
    
title "intermediate case";run;

%if "&cont"="c" %then %do;
	data tmp;
	      set data.cellszageyrind_c;
	run;
    %end;

%else %do;
	data tmp;
	      set data.cellszageyrind;
	run;
    %end;

     
  *******************************;
  * redefine age and size classes;
  *******************************;

  data size;
  set tmp;
  if year2=2003;
  count=1;

proc summary data=size nway;
   class fsize;
   var count;
output out=fsize sum=;run;

proc sort data=fsize;by fsize;run;

data fsize(keep=fsize fsizen);
  set fsize;
  fsizen=_N_;run;

proc sort data=fsize;by fsize;run;
proc print data=fsize;run;


proc sort data=tmp;by fsize;run;

data tmp;
  merge tmp fsize;by fsize;run;

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
   class fsizen fage5n year2 indetailf;
   id indsec;   
   weight denom;
   var pos_r neg_r net_r bpos_r dneg_r;
output out=tmp1 mean=;run;

proc summary data=tmp nway;
   class fsizen fage5n year2 indetailf;
   id indsec;   
   var denom;
   output out=tmp2 sum=;run;

proc sort data=tmp1;by year2 indetailf fsizen fage5n;run;
proc sort data=tmp2;by year2 indetailf fsizen fage5n;run;


data tmp;
  merge tmp1 tmp2;by year2 indetailf fsizen fage5n;
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
broad_size=fsizen;
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
	by indsec year2 indetailf;
    run;

proc glm data=tmp&death outstat=s1;
   class broad_age ;
    weight denom;
	id idnum;
	by indsec;	
    model &depvar = broad_age / solution noint;
*output out=pred1 p=yhat;
ods output ParameterEstimates=params1(keep= parameter estimate indsec stderr) 
fitstatistics=fparams1 Nobs=nobs1(where=(label='Number of Observations Used'));
run;quit;run;    

proc print data=params1;run;
*proc contents data=pred1;run;
*proc means data=pred1;run;
proc print data=fparams1;
data params1a(keep=estimate broad_age indsec rename=(estimate=estimatea));set params1; if substr(parameter,7,3)='age'; broad_age=substr(parameter,11,1)*1;run;
proc print data=params1a;run;

*proc sort data=pred1;*by idnum;*run;

**************************************************;
* merge in parameters and compute predicted values;
**************************************************;

proc sort data=tmp&death;by indsec broad_age;run;
 data tmp1;
  merge params1a tmp&death;by indsec broad_age;run;


data tmp1;
 set tmp1;
 yhat1wa&cont.&id=estimatea;
run;

**************************************;
* compare predicted and actual ;
**************************************;

proc summary data=tmp1 nway;
   class broad_age ;
   by indsec;   
   weight denom;
   var &depvar yhat1wa&cont.&id;
 output out=out.Oway_&depvar._a&cont.sec mean=;run;

proc print data=out.Oway_&depvar._a&cont.sec ;run; 
* note the unconditional mean for group 5-8 = .550;


*****************************************************;
* one way size model no controls for year and industry;
*****************************************************;
    proc sort data=tmp&death;
	by indsec year2 indetailf;
    run;

proc glm data=tmp&death outstat=s1;
   class broad_size ;
    weight denom;
	id idnum;
	by indsec;	
    model &depvar = broad_size / solution noint;
*output out=pred1 p=yhat;
ods output ParameterEstimates=params1(keep= parameter estimate indsec stderr) 
fitstatistics=fparams1 Nobs=nobs1(where=(label='Number of Observations Used'));
run;quit;run;    

proc print data=params1;run;
*proc contents data=pred1;run;
*proc means data=pred1;run;
proc print data=fparams1;
data params1a(keep=estimate broad_size indsec rename=(estimate=estimates));set params1; if substr(parameter,7,4)='size'; broad_size=substr(parameter,12,1)*1;run;
proc print data=params1a;run;

*proc sort data=pred1;*by idnum;*run;

**************************************************;
* merge in parameters and compute predicted values;
**************************************************;

proc sort data=tmp&death;by indsec broad_size;run;
 data tmp1;
  merge params1a tmp&death;by indsec broad_size;run;


data tmp1;
 set tmp1;
 yhat1ws&cont.&id=estimates;
run;

**************************************;
* compare predicted and actual ;
**************************************;

proc summary data=tmp1 nway;
   class broad_size ;
   weight denom;
   by indsec;   
   var &depvar yhat1ws&cont.&id;
 output out=out.Oway_&depvar._s&cont.sec mean=;run;

proc print data=out.Oway_&depvar._s&cont.sec ;run; 
* note the unconditional mean for group 5-8 = .550;



*************************************************;
* two way model;
*************************************************;
    proc sort data=tmp&death;
	by indsec year2 indetailf;
    run;

proc glm data=tmp&death outstat=s1;
   class broad_age broad_size;
*    absorb year2 indetailf;
    weight denom;
	id idnum;
	by indsec;	
    model &depvar = broad_age broad_size / solution noint;
*output out=pred1 p=yhat;
ods output ParameterEstimates=params1(keep= parameter estimate indsec stderr) 
fitstatistics=fparams1 Nobs=nobs1(where=(label='Number of Observations Used'));
run;quit;run;    

proc print data=params1;run;
*proc contents data=pred1;run;
*proc means data=pred1;run;
proc print data=fparams1;
data params1a(keep=estimate broad_age indsec rename=(estimate=estimatea));set params1; if substr(parameter,7,3)='age'; broad_age=substr(parameter,12,1)*1;run;
proc print data=params1a;run;
data params1s(keep=estimate broad_size indsec rename=(estimate=estimates));set params1; if substr(parameter,7,4)='size'; broad_size=substr(parameter,12,1)*1;run;
proc print data=params1s;run;

*proc sort data=pred1;*by idnum;*run;

**************************************************;
* merge in parameters and compute predicted values;
**************************************************;

proc sort data=tmp&death;by indsec broad_age;run;
 data tmp1;
  merge params1a tmp&death;by indsec broad_age;run;

proc sort data=tmp1;by indsec broad_size;run;
 data tmp1;
  merge params1s tmp1;by indsec broad_size;run;

data tmp1;
 set tmp1;
 yhat&tw.&iy.&cont.&id=estimates + estimatea;
run;


    data out.tway_&depvar.&cont.bsec;
	set params1;
	rename estimate=yhat&tw.&iy.&cont.&id;
    run;
    
**************************************;
* compare predicted and actual ;
**************************************;

proc summary data=tmp1 nway;
   class broad_age broad_size;
   weight denom;
   by indsec;   
   var &depvar yhat&tw.&iy.&cont.&id;
 output out=out.tway_&depvar.&cont.sec mean=;run;

proc print data=out.tway_&depvar.&cont.sec ;run; 
* note the unconditional mean for group 5-8 = .550;

proc summary data=tmp1 nway;
   class broad_size;
   weight denom;
   by indsec;   
   var &depvar yhat&tw.&iy.&cont.&id;
 output out=pred1checks mean=;run;

proc print data=pred1checks;run;

proc summary data=tmp1 nway;
   class broad_age;
   weight denom;
   by indsec;   
   var &depvar yhat&tw.&iy.&cont.&id;
 output out=pred1checka mean=;run;

proc print data=pred1checka ;run;


**************************************;
* now with interaction terms;
**************************************;

proc sort data=tmp&death; by indsec year2 indetailf;

proc glm data=tmp&death outstat=s2 ;
   class broad_age broad_size;
*    absorb year2 indetailf;
    weight denom;
	id idnum;
	by indsec;	
    model &depvar = broad_age*broad_size / solution noint;
*output out=pred2 p=yhat;
ods output ParameterEstimates=params2(keep= parameter estimate indsec stderr )
fitstatistics=fparams2 Nobs=nobs1(where=(label='Number of Observations Used'));
*PredictedValues=pred2;* too much output with  this option --- need to also include in model;
run;quit;run;    

proc print data=params2;run;
*proc contents data=pred2;*run;
*proc means data=pred2;*run;
proc print data=fparams2;
*proc print data=pred1;*run;
data params1as(keep=estimate broad_age broad_size indsec);set params2; 
broad_age=substr(parameter,22,1)*1;
broad_size=substr(parameter,24,1)*1;run;

proc print data=params1as;run;


*proc sort data=pred2;*by idnum;*run;
*proc sort data=tmp;*by idnum;*run;

**************************************************;
* merge in parameters and compute predicted values;
**************************************************;

proc sort data=tmp&death;by indsec broad_age broad_size;run;

data tmp2;
  merge params1as tmp&death;by indsec broad_age broad_size;run;

  data tmp2;
 set tmp2;
 yhat&tw.&iy.&s.&cont.&id=estimate;
run;

**************************************;
* compare predicted and actual ;
**************************************;

proc summary data=tmp2 nway noprint;
   class broad_age broad_size;
   weight denom;
   by indsec;   
   var &depvar yhat&tw.&iy.&s.&cont.&id;
 output out=out.tway_sat_&depvar.&cont.sec  mean=;run;

proc print data=out.tway_sat_&depvar.&cont.sec ;run; 

proc summary data=tmp2 nway;
   class broad_size;
   weight denom;
   by indsec;   
   var &depvar yhat&tw.&iy.&s.&cont.&id;
 output out=pred2checks mean=;run;

proc print data=pred2checks;run;

proc summary data=tmp2 nway;
   class broad_age;
   weight denom;
   by indsec;   
   var &depvar yhat&tw.&iy.&s.&cont.&id;
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
  by indsec;  
   var yhat&tw.&iy.&cont.&id;
output out=partial1 mean=;run; * note this is just unduplicating;
                               * note tmp1 is from the two way model;

proc summary data=tmp1 nway;
   class broad_age;
   var denom;
   by indsec;   
   output out=agesum sum=;run;   * compute age distribution economywide and merge it in;

proc sort data=partial1;by indsec broad_age;run;
proc sort data=agesum;by indsec broad_age;run;

proc print data=agesum;run;
proc print data=partial1;run;

data partial1;
  merge partial1 agesum;by indsec broad_age;run; * note here all sizes are getting the same distribution of age (e.g. size 1-8 get same share of startups, age 1-3.. as size 9-25.;

******************************;
* compute size partial;
******************************;

proc summary data=partial1 nway;
   class broad_size;
   by indsec;   
   var yhat&tw.&iy.&cont.&id;
   weight denom;
output out=out.tway_partsize1_&depvar.&cont.sec mean=yhat&tw.&iy.&p.&cont.&id;run;

title "size partial without interactions";run;

proc print data=out.tway_partsize1_&depvar.&cont.sec;run;

*********************************;
* two way model with interactions;
*********************************;

proc summary data=tmp2 nway;
  class broad_age broad_size;
  by indsec;  
   var yhat&tw.&iy.&s.&cont.&id;
output out=partial2 mean=;run; * note this is just unduplicating;
                               * note tmp2 is from the two way model with interactions;

proc summary data=tmp2 nway;
   class broad_age;
   by indsec;   
   var denom;
output out=agesum sum=;run;  * compute age distribution economywide and merge it in;

proc sort data=partial2;by indsec broad_age;run;
proc sort data=agesum;by indsec broad_age;run;

data partial2;
    merge partial2 agesum;by indsec broad_age;run; * note here all sizes are getting the same distribution of age (e.g. size 1-8 get same share of startups, age 1-3.. as size 9-25.;
     
******************************;
* compute size partial;
******************************;

proc summary data=partial2 nway;
   class broad_size;
   by indsec;   
   var yhat&tw.&iy.&s.&cont.&id;
   weight denom;
output out=out.tway_sat_partsize1_&depvar.&cont.sec mean=yhat&tw.&iy.&s.&p.&cont.&id;run;

title "size partial with interactions";run;

proc print data=out.tway_sat_partsize1_&depvar.&cont.sec;run;

title "results for &depvar";run;

********************;
* now do age partial;
********************;

********************;
* two way model;
********************;

proc summary data=tmp1 nway;
  class broad_age broad_size;
  by indsec;  
   var yhat&tw.&iy.&cont.&id;
output out=partial1 mean=;run; * note this is just unduplicating;
                               * note tmp1 is from the two way model;

proc summary data=tmp1 nway;
   class broad_size;
   by indsec;   
   var denom;
output out=sizesum sum=;run;* compute size distribution economywide and merge it in;

*proc print data=sizesum;run;
*proc print data=partial1;run;

proc sort data=partial1;by indsec broad_size;run;
proc sort data=sizesum;by indsec broad_size;run;


data partial1;
  merge partial1 sizesum;by indsec broad_size; * note here all ages are getting the same distribution of size (e.g. age 1 gets same share of small and large as age 10+;
     
******************************;
* compute age partial;
******************************;

proc summary data=partial1 nway;
   class broad_age;
   by indsec;   
   var yhat&tw.&iy.&cont.&id;
   weight denom;
output out=out.tway_partage1_&depvar.&cont.sec mean=yhat&tw.&iy.&p.&cont.&id;run;

title "age partial without interactions";run;

proc print data=out.tway_partage1_&depvar.&cont.sec;run;

*********************************;
* two way model with interactions;
*********************************;

proc summary data=tmp2 nway;
  class broad_age broad_size;
   by indsec;   
   var yhat&tw.&iy.&s.&cont.&id;
output out=partial2 mean=;run; * note this is just unduplicating;
                               * note tmp2 is from the two way model with interactions;

proc summary data=tmp2 nway;
   class broad_size;
   by indsec;   
   var denom;
output out=sizesum sum=;run; * compute size distribution economywide and merge it in;

*proc print data=sizesum;run;
*proc print data=partial2;run;

proc sort data=partial2;by indsec broad_size;run;
proc sort data=sizesum;by indsec broad_size;run;

data partial2;
  merge partial2 sizesum;by indsec broad_size; * note here all ages are getting the same distribution of size (e.g. age 1 gets same share of small and large as age 10+;

******************************;
* compute age partial;
******************************;

proc summary data=partial2 nway;
   class broad_age;
   by indsec;   
   var yhat&tw.&iy.&s.&cont.&id;
   weight denom;
output out=out.tway_sat_partage1_&depvar.&cont.sec mean=yhat&tw.&iy.&s.&p.&cont.&id;run;

title "age partial with interactions";run;

proc print data=out.tway_sat_partage1_&depvar.&cont.sec;run;



%mend;

%robust(net_r,2w,,s,p,,,1);
%robust(pos_r,2w,,s,p,,,2);
%robust(neg_r,2w,,s,p,,,3);
%robust(bpos_r,2w,,s,p,,,4);
%robust(dneg_r,2w,,s,p,,,5);
%robust(net_r,2w,,s,p,,c,1);
%robust(pos_r,2w,,s,p,,c,2);
%robust(neg_r,2w,,s,p,,c,3);



********************************;
* key                          *;
*   s = saturated              *;
*   p = partial                *;
*   iy= ind x yr               *;
*   c = continuer              *;
*   d = deaths so exclude age1 *;
*******************************;******************;
* some of the above only show up in certain models;
**************************************************;


**************************************;
* merge data sets;
**************************************;

* first age size;

data out.twoway_sec;
 merge  out.tway_net_rbsec out.tway_pos_rbsec out.tway_neg_rbsec out.tway_bpos_rbsec out.tway_dneg_rbsec
     out.tway_net_rcbsec out.tway_pos_rcbsec out.tway_neg_rcbsec;
     by indsec parameter;
run;

data out.twowayhat_sec;
 merge  out.tway_net_rsec out.tway_pos_rsec out.tway_neg_rsec out.tway_bpos_rsec out.tway_dneg_rsec
     out.tway_net_rcsec out.tway_pos_rcsec out.tway_neg_rcsec;
     by indsec broad_age broad_size;
run;
												    
* now partials both saturated and not;
data out.tway_partialage_sec;
 merge  out.tway_partage1_net_rsec out.tway_sat_partage1_net_rsec
        out.tway_partage1_pos_rsec out.tway_sat_partage1_pos_rsec
        out.tway_partage1_neg_rsec out.tway_sat_partage1_neg_rsec
        out.tway_partage1_bpos_rsec out.tway_sat_partage1_bpos_rsec
	out.tway_partage1_dneg_rsec out.tway_sat_partage1_dneg_rsec
        out.tway_partage1_net_rcsec out.tway_sat_partage1_net_rcsec 
        out.tway_partage1_pos_rcsec out.tway_sat_partage1_pos_rcsec 
        out.tway_partage1_neg_rcsec out.tway_sat_partage1_neg_rcsec ;

     by indsec broad_age;
run;

data out.tway_partialsize_sec;
 merge  out.tway_partsize1_net_rsec out.tway_sat_partsize1_net_rsec
        out.tway_partsize1_pos_rsec out.tway_sat_partsize1_pos_rsec
        out.tway_partsize1_neg_rsec out.tway_sat_partsize1_neg_rsec
        out.tway_partsize1_bpos_rsec out.tway_sat_partsize1_bpos_rsec
	out.tway_partsize1_dneg_rsec out.tway_sat_partsize1_dneg_rsec
        out.tway_partsize1_net_rcsec out.tway_sat_partsize1_net_rcsec 
        out.tway_partsize1_pos_rcsec out.tway_sat_partsize1_pos_rcsec 
        out.tway_partsize1_neg_rcsec out.tway_sat_partsize1_neg_rcsec ;

     by indsec broad_size;
run;

* now one ways;

data out.oneway_size_sec;
 merge  out.Oway_net_r_ssec out.Oway_pos_r_ssec out.Oway_neg_r_ssec out.Oway_bpos_r_ssec out.Oway_dneg_r_ssec
     out.Oway_net_r_scsec(rename=(net_r=net_rc)) out.Oway_pos_r_scsec(rename=(pos_r=pos_rc)) out.Oway_neg_r_scsec(rename=(neg_r=neg_rc)) ;
     by indsec broad_size;
run;

data out.oneway_age_sec;
 merge  out.Oway_net_r_asec out.Oway_pos_r_asec out.Oway_neg_r_asec out.Oway_bpos_r_asec out.Oway_dneg_r_asec
     out.Oway_net_r_acsec(rename=(net_r=net_rc)) out.Oway_pos_r_acsec(rename=(pos_r=pos_rc)) out.Oway_neg_r_acsec(rename=(neg_r=neg_rc)) ;
     by indsec broad_age;
run;

* remember to deal with deaths by dropping starups;

* %robust(bpos_r);


* now run export_estab.sas on the PC to create excell figs and tables;




