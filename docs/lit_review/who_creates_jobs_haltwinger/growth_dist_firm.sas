* this code generates employment growth distributions;


libname javidata '/projects2/arts422/macroannual/programs/lbdtables/data';
libname estab '/projects2/arts422/macroannual/programs/lbdtables/data/estabs_disclosure';

options obs=max;
options mprint mlogic;



    
data tmp;
    set javidata.jcr_firms(keep=pos_r neg_r net_r fsize ifsize state fage5 fage  firmid_ma1 year2 denom emp1f emp2f empdiff);
    avgfemp=sum(emp1f, emp2f)/2;
    ifemp=emp1f;
    
    do i=0 to 2 by 0.05;
	 i2=i + .05;
	
	if pos_r>i and pos_r<=i2 then bin=i2;	
	if neg_r>i and pos_r<=i2 then bin=i2;	
    
	end;

	if pos_r=2 then bin=2.1;
	if neg_r=2 then bin=2.1;
        if net_r=0 then bin=0;
        if neg_r>0 then bin2=-1*bin;   
    run;
    
    data tmp;
	set tmp;
	if neg_r>0 then bin=bin2;	
    run;
    
proc freq data=tmp;
    tables bin/out=javidata.growth_distf;
run;

proc freq data=tmp; where bin^=2.1 and bin^=-2.1;    
    tables bin/out=javidata.growth_dist_contf;
run;

proc freq data=tmp;
    tables bin*fsize*fage5/out=javidata.growth_dist_szagef;
run;
proc freq data=tmp;
    tables bin*fsize/out=javidata.growth_dist_szf;
run;
proc freq data=tmp;
    tables bin*fage5/out=javidata.growth_dist_agef;
run;

proc sort data=tmp;
    by bin;
run;


proc means data=tmp noprint;
    by bin;
    var fage;
    output out=javidata.growth_dist_meanfagef mean=;
run;



proc means data=tmp noprint;  where bin^=2.1 and bin^=-2.1;  
    by bin;
    var fage;
    output out=javidata.growth_dist_cont_meanfagef  mean=;
run;


proc freq data=tmp; weight denom;    
    tables bin/out=javidata.growth_distwf;
run;

proc freq data=tmp; where bin^=2.1 and bin^=-2.1;    weight denom;    
    tables bin/out=javidata.growth_distw_contf;
run;

proc freq data=tmp;weight denom;    
    tables bin*fsize*fage5/out=javidata.growth_distw_szagef;
run;

proc freq data=tmp;weight denom;
    tables bin*fsize/out=javidata.growth_distw_szf;
run;
proc freq data=tmp;weight denom;
    tables bin*fage5/out=javidata.growth_distw_agef;
run;

proc freq data=tmp; weight denom;    
    tables year2*bin/out=javidata.growth_distw_yearf;
run;


proc means data=tmp noprint; 
weight denom;    
    by bin;
    var fage;
    output out=javidata.growth_dist_meanfagewf  mean=;
run;



proc means data=tmp noprint;  where bin^=2.1 and bin^=-2.1;  
weight denom;     
    by bin;
    var fage;
    output out=javidata.growth_dist_cont_meanfagewf  mean=;
run;


proc means data=tmp noprint; 
weight denom;    
    by bin;
    var avgfemp;
    output out=javidata.growth_dist_meanfsizewf  mean=;
run;

proc means data=tmp noprint;  where bin^=2.1 and bin^=-2.1;  
weight denom;     
    by bin;
    var avgfemp;
    output out=javidata.growth_dist_cont_meanfsizewf  mean=;
run;

proc means data=tmp noprint; 
weight denom;    
    by bin;
    var ifemp;
    output out=javidata.growth_dist_meanifsizewf  mean=;
run;

proc means data=tmp noprint;  where bin^=2.1 and bin^=-2.1;  
weight denom;     
    by bin;
    var ifemp;
    output out=javidata.growth_dist_cont_meanifsizewf  mean=;
run;




proc means data=tmp noprint; 
    by bin;
    var avgfemp;
    output out=javidata.growth_dist_meanfsizef  mean=;
run;

proc means data=tmp noprint;  where bin^=2.1 and bin^=-2.1;       
    by bin;
    var avgfemp;
    output out=javidata.growth_dist_cont_meanfsizef  mean=;
run;

proc means data=tmp noprint;   
    by bin;
    var ifemp;
    output out=javidata.growth_dist_meanifsizef  mean=;
run;

proc means data=tmp noprint;  where bin^=2.1 and bin^=-2.1;      
    by bin;
    var ifemp;
    output out=javidata.growth_dist_cont_meanifsizef  mean=;
run;


proc sort data=tmp;
    by firmid_ma1 year2;
run;

data tmp;
    set tmp;
    lfirmid_ma1=lag(firmid_ma1);
    lnet_r=lag(net_r);
run;

data tmp;
    set tmp;
    if firmid_ma1~=lfirmid_ma1 then lnet_r=.;
run;



proc corr data=tmp nomiss outp=all;    
    title3 "all";
    var net_r lnet_r ;
run;

proc sort data=tmp  ;
    by fage5;
run;

proc corr data=tmp nomiss outp=fage5;
    title3 "by age";    
    by fage5;
   var net_r lnet_r;
run;

proc sort data=tmp;
    by fsize;
run;

proc corr data=tmp nomiss outp=fsize;
    title3 "by size";    
by fsize;
var net_r lnet_r;
run;
proc sort data=tmp;
    by ifsize;
run;

proc corr data=tmp nomiss outp=ifsize;
    title3 "by size";    
by ifsize;
var net_r lnet_r;
run;

proc sort data=tmp;
    by year2;
run;

proc sort data=tmp;
    by year2;
run;

proc corr data=tmp nomiss outp=year2;
    title3 "all by year";
    by year2;
    var net_r lnet_r;
run;

data tmp2;
    set tmp;
    if net_r=2 or net_r=-2 or lnet_r=2 or lnet_r=-2 then delete;
run;


proc corr data=tmp2 nomiss outp=continuers;
    title3 "continuers";    
    var net_r lnet_r;
run;

proc sort data=tmp2;
    by fage5;
run;

proc corr data=tmp2 nomiss outp=cfage5;
    title3 "continuers by age";    
    by fage5;
   var net_r lnet_r;
run;

proc sort data=tmp2;
    by fsize;
run;

proc corr data=tmp2 nomiss outp=cfsize;
    title3 "continuers by size";    
by fsize;
var net_r lnet_r;
run;
proc sort data=tmp2;
    by ifsize;
run;

proc corr data=tmp2 nomiss outp=cifsize;
    title3 "continuers by size";    
by ifsize;
var net_r lnet_r;
run;

proc sort data=tmp2;
    by year2;
run;

proc corr data=tmp2 nomiss outp=cyear2;
    title3 "continuers by year";    
    by year2;    
    var net_r lnet_r ;
run;

data javidata.growth_correlations_firm;
    set all(in=a) fsize(in=b) fage5(in=c) year2(in=d) continuers(in=e) cfsize(in=f) cfage5(in=g) cyear2(in=h) ifsize(in=i) cifsize(in=j);
    if a then in="     all  ";
    if b then in="fsize";
    if c then in="fage5";
    if d then in="year2";
    if e then in="continuers";
    if f then in="cfsize";
    if g then in="cfage5";
    if h then in="cyear2";
    if i then in="ifsize";
    if j then in="cifsize";    
    
run;
