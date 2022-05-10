**********************************************************************************************************************************************;
** this code computes results by sector, one way, two ways (firm microdata);
** Creates data points for Figure 6
** Results with and without  industry and year effects ;
** Sept 3, 2012;
** *******************************************************************************************************************************************;




data tmp;
set data.jcr_firms;
   if substr(fage5,1,1)='a' and net_r^=2 then delete; 
  if substr(fage5 ,1,1) in ('q','r','s','t') then fage5='u. 15+';
if fsize=' ' or fage5=' ' then delete; * we drop 571 here;

if indetailf=' ' or indetailf='00' or indetailf='    00' or substr(indetailf,1,4)='9999' then indetailf='NEC';
run;

* create sectors;

data tmp(drop=sic2 sic4 naics2 naics3 naics6);
    set tmp;
	length sic2 $2. sic4 $4. indsec $24.;		
			   sic2=substr(indetailf,1,2);
			   sic4=substr(indetailf,1,4);
		length  naics2 $2. naics3 $3. naics6 $6.;		
		   naics2=substr(indetailf,1,2);
		   naics3=substr(indetailf,1,3);
		   naics6=substr(indetailf,1,6);		   

    if year2<1998 then do;					   
		 if '06'<sic2<'10' then indsec='Agriculture';
		 else if '10'=<sic2<'15' and sic2^='11' then indsec='Mining';
		 else if '15'=<sic2<'18' then indsec='Construction';
                 else if sic2 in ('24','25','32','33','34','35','36','37','38','39') then indsec="Manufacturing: Durables";		 
                 else if sic2 in ('20','21','22','23','26','27','28','29','30','31') then indsec="Manufacturing: NonDurab";
		 else if '41'=<sic2<'50' and sic2^='43' then indsec='Transportation & Utilities';
		 else if '50'=<sic2<'60' then indsec='Wholesale & Retail';
		 * else if '52'=<sic2<'60' then indsec='52';
		 else if '60'=<sic2<'68' and sic2^='66' then indsec='FIRE';
		 else if '70'=<sic2<'90' and sic2^='71' and sic2^='74' /* and sic2^='70' */
		   and sic2^='85' /* and sic2^='88'*/ then indsec='Services';
		 else if  '91'=<sic2<'97' then indsec='Administration';
		 else indsec='NEC';
	end;
		     else if year2>=1998 then do;
		  if naics2='11' then indsec='Agriculture';
		  else if naics2='21'  then indsec='Mining';
                  else if naics2='22'  then indsec='Transportation & Utilities';
                  else if naics2='23'  then indsec='Construction';
                  else if '32'=<naics2<='33' then indsec='Manufacturing: Durables';
                  else if naics2='31' then indsec='Manufacturing: NonDurab';
		  else if naics2='42'  then indsec='Wholesale & Retail';
		  else if '44'=<naics2<='45' then indsec='Wholesale & Retail';
		  else if '48'=<naics2<='49' then indsec='Transportation & Utilities';
		  else if naics3='511'  then indsec='Manufacturing: NonDurab';
		  else if naics3='512'  then indsec='Services';
		  else if naics3='513'  then indsec='Transportation & Utilities';
		  else if naics3='514'  then indsec='Services';
		  else if naics2='52'  then indsec='FIRE';
		  else if naics3='531'  then indsec='FIRE';
		  else if naics3='532'  then indsec='Services';
		  else if naics3='533'  then indsec='Services';
		  else if naics2='54'  then indsec='Services';
		  else if naics2='55'  then indsec='FIRE';
		  else if naics3='561'  then indsec='Services';
		  else if naics3='562'  then indsec='Transportation & Utilities';
		  else if naics2='61'  then indsec='Services';
		  else if naics2='62'  then indsec='Services';
		  else if naics2='71'  then indsec='Services';
                  else if naics3='721'  then indsec='Services';
                  else if naics3='722'  then indsec='Wholesale & Retail';
                  else if naics2='81'  then indsec='Services';
                  else if naics2='92'  then indsec='Administration';
		  else indsec='NEC';		   		 	    
	end;
    if naics3 in ('322','511','323','325','324','326') then indsec='Manufacturing: NonDurab';    
run;
		 
* assert establishments are always in a unique sector and dont switch around;

proc sort data=tmp out=junk(keep= firmid_ma1 indsec denom );
    by firmid_ma1 year2;
run;

proc freq data=junk noprint; weight denom;    
    by firmid_ma1;
    tables indsec/out=javidata.indsec;
run;

proc sort data=javidata.indsec;
    by firmid_ma1 descending count; 
run;

data javidata.indsec (keep =firmid_ma1 indsec rename=(indsec= best_indsec));
    set javidata.indsec;
    by firmid_ma1;
    if first.firmid_ma1=1;    
run;

proc sort data=javidata.indsec nodupkey;by firmid_ma1;run;

proc sort data=tmp ;by firmid_ma1;run;

data tmp;
  merge tmp (in=a ) javidata.indsec(in=b);
by firmid_ma1;
if a;
run;    
    
* end;

proc freq data=tmp;
tables indsec*year2/out=javidata.inddist_estab;
run;

proc freq data=tmp; weight denom;    
tables indsec*year2/out=javidata.inddist_empwgt;
run;

proc freq data=tmp;
tables best_indsec*year2/out=javidata.inddist_estab2;
run;

proc freq data=tmp; weight denom;    
tables best_indsec*year2/out=javidata.inddist_empwgt2;
run;
		 
proc sort data= tmp;
	by fsize;
run;

proc summary;
    by fsize;
    var net_r pos_r neg_r bpos_r dneg_r  denom;
    *weight denom;
    title "unweighted means by size";
    
    output out=temp mean= ;
run;
proc print data=temp;
run;

proc sort data=tmp ;
    by fage5;
run;

proc summary;
    by fage5;
    var net_r pos_r neg_r bpos_r dneg_r  denom;
    *weight denom;
    title "unweighted means by age";
    output out=temp mean= ;
run;
proc print data=temp;
run;





proc sort data=tmp;
    by best_indsec year2 indetailf;
run;



%macro regs(depvar,wate);

    title " Dependent Variable = '&depvar', Weighted by '&wate'";

proc glm data=tmp outstat=r2_1;
   class fage5 fsize;
    *absorb year2 indetailf;
    by best_indsec;    
    weight &wate;
    model &depvar = fsize / solution;
ods output ParameterEstimates=params1(keep= best_indsec parameter estimate stderr rename=(estimate=&depvar.1 stderr=&depvar.1_t)) 
fitstatistics=fparams1 Nobs=nobs1(where=(label='Number of Observations Used'));
run;    

proc glm data=tmp outstat=r2_2;
    class fage5 fsize;
    absorb year2 indetailf;
    by best_indsec;    
    weight &wate;
    model &depvar = fsize / solution;
ods output ParameterEstimates=params2(keep=best_indsec  parameter estimate stderr rename=(estimate=&depvar.2 stderr=&depvar.2_t)) 
fitstatistics=fparams2  Nobs=nobs2(where=(label='Number of Observations Used'));
run;

proc glm data=tmp outstat=r2_3;
    class fage5 fsize;
    *absorb year2 indetailf;
    by best_indsec;    
    weight &wate;
    model &depvar = fage5 / solution;
ods output ParameterEstimates=params3(keep= best_indsec parameter estimate stderr rename=(estimate=&depvar.3 stderr=&depvar.3_t)) 
fitstatistics=fparams3 Nobs=nobs3(where=(label='Number of Observations Used'));
run;  

proc glm data=tmp outstat=r2_4;
    class fage5 fsize;
    by best_indsec;    
    absorb year2 indetailf;
    weight &wate;
    model &depvar = fage5 / solution;
ods output ParameterEstimates=params4(keep= best_indsec parameter estimate stderr rename=(estimate=&depvar.4 stderr=&depvar.4_t)) 
fitstatistics=fparams4 Nobs=nobs4(where=(label='Number of Observations Used'));
run;

proc glm data=tmp outstat=r2_5;
    class fage5 fsize;
    by best_indsec;    
    absorb year2 indetailf;
    weight &wate;
    model &depvar = fsize fage5 / solution;
ods output ParameterEstimates=params5(keep= best_indsec parameter estimate stderr rename=(estimate=&depvar.5 stderr=&depvar.5_t)) 
fitstatistics=fparams5 Nobs=nobs5(where=(label='Number of Observations Used'));
run;


%macro myrep(in);    
proc sort data=&in;    
    by parameter best_indsec;
run;
%mend;

%myrep(params1);
%myrep(params2);
%myrep(params3);
%myrep(params4);
%myrep(params5);


data regs_out; 
    merge params1 params2 params3 params4 params5 ;    
	by parameter best_indsec;
run;

data javidata.regs_out_&depvar._fitfirm0; 
    set fparams1 fparams2 fparams3 fparams4  fparams5 ;    
run;


data regs_out_coeffs ;
    set regs_out;
    keep best_indsec parameter &depvar.1 &depvar.2 &depvar.3 &depvar.4 &depvar.5;
run;

data regs_out_ts ;
    set regs_out(keep=best_indsec parameter &depvar.1_t &depvar.2_t &depvar.3_t &depvar.4_t &depvar.5_t );


rename &depvar.1_t = &depvar.1 ;
rename &depvar.2_t = &depvar.2 ;
rename &depvar.3_t = &depvar.3 ;
rename &depvar.4_t = &depvar.4 ;
rename &depvar.5_t = &depvar.5 ;

run;


data javidata.regs_out_&depvar._bdsfirm0;
set regs_out_coeffs regs_out_ts;
run;

proc sort data=javidata.regs_out_&depvar._bdsfirm0;
    by best_indsec parameter;
run;

data javidata.nobs_&depvar._bdsfirm0;
    set nobs1 nobs2 nobs3 nobs4 nobs5;
run;

    %mend;


%regs(net_r,denom);
%regs(pos_r,denom);
%regs(neg_r,denom);
%regs(bpos_r,denom);
%regs(dneg_r,denom);



* compute employment weighted entry rates by sector;

 proc freq data=tmp; tables year2/missing;run;


  proc means data=tmp ;
    by best_indsec;
    var denom;
   output out=inddenom sum=denom;
 run;


  proc means data=tmp ;
    by best_indsec; where substr(fage5,1,1)='a';
    var emp2f;
   output out=startups sum=startups;
 run;

    data entry_rate;
     merge inddenom startups;
     by best_indsec;run;
data javidata.entry_rate_sector;
   set entry_rate;  length entry_rate 3.2;
    entry_rate=100*(startups/denom); if best_indsec in ('Administration','NEC') then delete;run;
proc print data=entry_rate;run;
