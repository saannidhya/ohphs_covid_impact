**********************************************************************************************************************************************;
** this code computes two ways controlling for age or size;
** Results with and without  industry and year effects ;
** Now using initital firm size sizing methodology;
** Sept 3, 2012;
** *******************************************************************************************************************************************;
** THIS IS FOR SUBSET OF FIRMS WITH LESS THAN 500 EMPLOYEES;
** *******************************************************************************************************************************************;




%macro regs(depvar,wate);

    title " Dependent Variable = '&depvar', Weighted by '&wate'";
    


proc glm data=tmp outstat=r2_1;
    class fage5 ifsize;
    *absorb year2 indetailf;
    weight &wate;
    model &depvar = ifsize / solution;
ods output ParameterEstimates=params1(keep= best_indsec parameter estimate stderr rename=(estimate=&depvar.1 stderr=&depvar.1_t)) 
fitstatistics=fparams1 Nobs=nobs1(where=(label='Number of Observations Used'));
run;    

proc glm data=tmp outstat=r2_2;
    class fage5 ifsize;
    absorb year2 indetailf;
    weight &wate;
    model &depvar = ifsize / solution;
ods output ParameterEstimates=params2(keep= best_indsec parameter estimate stderr rename=(estimate=&depvar.2 stderr=&depvar.2_t)) 
fitstatistics=fparams2 Nobs=nobs2(where=(label='Number of Observations Used'));
run;

proc glm data=tmp outstat=r2_3;
    class fage5 ifsize;
    *absorb year2 indetailf;
    weight &wate;
    model &depvar = fage5 / solution;
ods output ParameterEstimates=params3(keep= best_indsec parameter estimate stderr rename=(estimate=&depvar.3 stderr=&depvar.3_t)) 
fitstatistics=fparams3 Nobs=nobs3(where=(label='Number of Observations Used'));
run;  

proc glm data=tmp outstat=r2_4;
    class fage5 ifsize;
    absorb year2 indetailf;
    weight &wate;
    model &depvar = fage5 / solution;
ods output ParameterEstimates=params4(keep= best_indsec parameter estimate stderr rename=(estimate=&depvar.4 stderr=&depvar.4_t))   
fitstatistics=fparams4 Nobs=nobs4(where=(label='Number of Observations Used'));
run;

proc glm data=tmp outstat=r2_5;
    class fage5 ifsize;
    absorb year2 indetailf;
    weight &wate;
    model &depvar = ifsize fage5 / solution;
ods output ParameterEstimates=params5(keep=  parameter estimate stderr rename=(estimate=&depvar.5 stderr=&depvar.5_t)) 
fitstatistics=fparams5 Nobs=nobs5(where=(label='Number of Observations Used'));
run;


%macro myrep(in);    
proc sort data=&in;    
    by parameter;
run;
%mend;

%myrep(params1);
%myrep(params2);
%myrep(params3);
%myrep(params4);
%myrep(params5);


data regs_out; 
    merge params1 params2 params3 params4 params5 ;    
	by parameter ;
run;

data javidata.regs_out_i&depvar._fitfirm0; 
    set fparams1 fparams2 fparams3 fparams4  fparams5 ;    
run;


data regs_out_coeffs ;
    set regs_out;
    keep   parameter &depvar.1 &depvar.2 &depvar.3 &depvar.4 &depvar.5;
run;

data regs_out_ts ;
    set regs_out(keep=  parameter &depvar.1_t &depvar.2_t &depvar.3_t &depvar.4_t &depvar.5_t );


rename &depvar.1_t = &depvar.1 ;
rename &depvar.2_t = &depvar.2 ;
rename &depvar.3_t = &depvar.3 ;
rename &depvar.4_t = &depvar.4 ;
rename &depvar.5_t = &depvar.5 ;

run;


data javidata.regs_out_i&depvar._bdsfirm0;
set regs_out_coeffs regs_out_ts;
run;

proc sort data=javidata.regs_out_i&depvar._bdsfirm0;
    by   parameter;
run;

data javidata.nobs_i&depvar._bdsfirm0;
    set nobs1 nobs2 nobs3 nobs4 nobs5;
run;

    %mend;


%regs(net_r,denom);
%regs(pos_r,denom);
%regs(neg_r,denom);
%regs(bpos_r,denom);
%regs(dneg_r,denom);
