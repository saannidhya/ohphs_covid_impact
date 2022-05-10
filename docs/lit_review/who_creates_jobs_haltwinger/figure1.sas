* compare size/age datasets;
libname tmp1 'M:\All\BDS\Old Releases\temp\RED\fagafsize\july08updates';

data data2005;
 set tmp1.jcrempfagefsz_test;
 where year2>=1992;
 if substr(fage4,1,1) in ('b','c','d','e','f','g') then fage='Young ';
 else if substr(fage4,1,1)='a' then fage='Birth';
 else fage='Mature';
 
 if substr(fsize,1,1) in ('a','b','c','d','e','f','g') then f_size='Small';
 else f_size='Large';
 run;

 proc sort data=data2005;by fage f_size;run;

 proc means data=data2005;
 by  fage f_size;
 var employment count postvs negtvs;
 output out=tab2005 sum=employment estabs jc jd ;
run;
 

 proc means data=tab2005;
 var employment estabs jc jd;
 output out=totdenom sum=s_emp s_estabs s_jc s_jd;
run;
 
data tab2005;set tab2005; count=1;run;
data totdenom;set totdenom;count=1;run;

data tab2005;
 merge tab2005 totdenom;
 by count1;
 run;

 data tab2005; retain fage f_size employmentr jcr jdr estabr mean_estabs mean_emp estabs _TYPE_ _FREQ_ employment jc jd count s_emp s_estabs s_jc s_jd ;
 set tab2005;
  jcr=jc/s_jc;
  jdr=jd/s_jd;
  mean_estabs=estabs/14;
  mean_emp=employment/14;
  estabr=estabs/s_estabs;
  employmentr=employment/s_emp;
  run;

  proc sort data=tab2005;by f_size fage;run;

  proc means data=tab2005 sum;run;
  
  
PROC EXPORT DATA= WORK.TAB2005 
            OUTFILE= "H:\data\BDS\Shares_JC_JD.xls" 
            DBMS=EXCEL REPLACE;
     SHEET="tab2005"; 
RUN;

