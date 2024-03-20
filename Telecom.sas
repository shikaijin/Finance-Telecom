/*set working environment*/
data _null_;
	rc=dlgcdir("D:\Idata-global\Telecom Project\Tele-Project");
	put rc=;
run;

/*create telecom library*/
libname telecom "D:\Idata-global\Telecom Project\Tele-Project";

/*controls the type of SAS variable names*/
options validvarname=v7;

/*import data*/
%macro dataimport(input, output);

	proc import datafile=&input out= telecom.&output dbms=xlsx replace;
		getnames=yes;
	run;

%mend;

%dataimport('Telco_customer_churn_demographics.xlsx', demographics);
%dataimport('Telco_customer_churn_location.xlsx', location);
%dataimport('Telco_customer_churn_population.xlsx', population);
%dataimport('Telco_customer_churn_services.xlsx', services);
%dataimport('Telco_customer_churn_status.xlsx', status);

/*data merge*/
proc sql;
	create table telecom.churn as
		select * from telecom.demographics de
			inner join telecom.location lo on de.Customer_ID =lo.Customer_ID
				left join telecom.population po on lo.Zip_Code = po.Zip_Code
					inner join telecom.services se on de.Customer_ID =se.Customer_ID
					inner join telecom.status st on st.Customer_ID =lo.Customer_ID;
quit;

data telecom.churn;
	set telecom.churn(drop=Customer_ID Count Country  State  City Under_30 Senior_Citizen Zip_Code Lat_Long Latitude Longitude ID 
		Population Quarter );
run;

/*Count By Churn Reason and Satisfaction Score plot*/
proc sql;
	create table telecom.CountByChurnReason as
		select Churn_Reason, Satisfaction_Score, count(Churn_Reason) as Count from telecom.churn
			where Churn_Value = 1
				group by Churn_Reason, Satisfaction_Score;
quit;

proc sgplot data=telecom.CountByChurnReason;
	vbar Churn_Reason / response=Count group=Satisfaction_Score categoryorder=respdesc;
run;

/*Count By Contract plot*/
proc sql;
	create table telecom.CountByContract as
		select t1.Contract, t1.CountByContract_Churn, t2.CountByContract_NotChurn from 
		(select Contract, count(*) as CountByContract_Churn from telecom.churn
			where Churn_Value = 1
				group by Contract) t1
					join (select Contract, count(*) as CountByContract_NotChurn from telecom.churn
						where Churn_Value = 0
							group by Contract) t2 on t1.Contract = t2.Contract;
quit;

proc sgplot data=telecom.CountByContract;
	vbar Contract / response=CountByContract_Churn;
run;

proc sgplot data=telecom.CountByContract;
	vbar Contract / response=CountByContract_NotChurn;
run;

data telecom.churn_newvar (drop=Age CLTV Churn_Score Customer_Status Total_Charges Total_Refunds  
Total_Extra_Data_Charges Total_Long_Distance_Charges Internet_Service Avg_Monthly_Long_Distance_Charge);
	set telecom.churn;
	*definition of age band;
	length  age_range CLTV_Category $ 20;
	if Age lt 26 then
		age_range='25 and less';
	else if  Age lt 35 then
		age_range='26-34';
	else if  Age lt 45 then
		age_range='35-44';
	else if  Age lt 55 then
		age_range='45-54';
	else if  Age lt 65 then
		age_range='55-64';
	else if  Age lt 75 then
		age_range='65-74';
	else age_range='75 and older';

	*definition of 	CLTV_Category;
	if CLTV le 3500 then
		CLTV_Category='2000-3500';
	else if  CLTV le 5500 then
		CLTV_Category='3501-5500';
	else CLTV_Category='5501-7000';

	/*	else if  CLTV le 6000 then*/
	/*		CLTV_Category='5001-6000';*/
	/*	else CLTV_Category='6001-7000';*/
	*definition of 	Tenure;
	if Tenure_in_Months le 12 then
		Tenure_in_Years=1;
	else if  Tenure_in_Months le 24 then
		Tenure_in_Years=2;
	else if  Tenure_in_Months le 36 then
		Tenure_in_Years=3;
	else if  Tenure_in_Months le 48 then
		Tenure_in_Years=4;
	else if  Tenure_in_Months le 60 then
		Tenure_in_Years=5;
	else Tenure_in_Years=6;
run;

/*proc freq data=telecom.churn_newvar;*/
/*	tables age_range;*/
/*run;*/
/**/
/*proc sql;*/
/*	create table telecom.Churn_by_age as*/
/*		select age_range, sum(Churn_Value) AS Churned_Customer, sum(Churn_Value)/count(*) as RATE format=PERCENT7.2 from telecom.churn_newvar*/
/*			group by age_range;*/
/*quit;*/

/*gbarline plot by char vars*/
%macro Churn_Rate_by_Cat; 
proc sql noprint;
	select name into: char_var1- from dictionary.columns
		where libname='TELECOM' and memname='CHURN_NEWVAR'	and type='char' and find(name, 'Churn')<1 ;
quit;
%do i=1 %to &sqlobs; 
/*title "Churn Rate by &&char_var&i";*/
PROC SQL noprint;
create table telecom.&&char_var&i as
SELECT &&char_var&i, SUM(Churn_Value) AS Churned_Customer, COUNT(*)-SUM(Churn_Value) AS Active_Customer, SUM(Churn_Value)/COUNT(*) AS Churn_Rate FORMAT=PERCENT7.2
FROM TELECOM.CHURN_newvar
GROUP BY &&char_var&i;
QUIT;
/*proc print data=telecom.&&char_var&i;*/
/*run;*/
goptions reset=all device=ACTXIMG xpixels=800  ypixels=800;
axis1 offset=( 0, 0) minor=NONE 
	label=( "&&char_var&i" h= 0.7  f=swiss) 
	value=(h= 0.7   f=swiss );
axis2 label=( 'Churned Customer'  h= 0.7  f=swiss) 
	value=(h= 0.6  f=swiss)
	minor=none/**number of ticks**/
offset=(0, 0 );
axis3 label=( 'Churn Rate'  h= 0.7  f=swiss) 
value=(h= 0.6  f=swiss) offset=(0, 0 ) 
major=none minor=none;
symbol1 i=j v=dot c=yellow h=0.6 w=3  pointlabel=(h=0.7 c=green);
symbol2 i=j v=dot c=blue h=0.6 w=3 pointlabel=(h= 0.7  c=blue);

proc gbarline data=telecom.&&char_var&i;
	bar &&char_var&i/sumvar=Churned_Customer maxis=axis1 raxis=axis2 type=sum cframe=white;
	plot /sumvar=Churn_Rate type=sum raxis=axis3;
	title h=10pt f=swiss "Churned Customer and Rate by &&char_var&i";
run;
quit;
%end;
title;
%mend; 
%Churn_Rate_by_Cat;

/*Churn Rate by Credit Group*/
proc sql;
	CREATE TABLE telecom.RATE_with_CLTV AS
		select Tenure_in_Years, CLTV_Category, sum(Churn_Value)/count(*) as Churn_Rate format=PERCENT7.2, count(*)-sum(Churn_Value) as Active_Account_Count, 
			sum(Churn_Value) as Cancelled_Account_Count
		from telecom.churn_newvar
			group by Tenure_in_Years, CLTV_Category;
quit;

title "Churn Rate by Credit Group";

proc report data=telecom.RATE_with_CLTV nowd split="/";
	column Tenure_in_Years CLTV_Category Churn_Rate Active_Account_Count Cancelled_Account_Count;
	define Tenure_in_Years/"Tenure in Years" left;
	define CLTV_Category/"CLTV Category" center;
	define Churn_Rate/"Churn Rate" center format=percent11.2;
	define Active_Account_Count/"Active /Account Count" right;
	define Cancelled_Account_Count/"Cancelled /Account Count" right;
run;

title;

data telecom.elder;
	set telecom.churn_newvar;

	if Age >=65;
RUN;

data telecom.YOUNG;
	set telecom.churn_newvar;

	if Age <65;
RUN;
/*KM plot*/
%macro kmplot(var=);
	ods graphics on;

	PROC LIFETEST DATA=TELECOM.CHURN_NEWVAR METHOD=KM;
		TIME Tenure_in_Months*Churn_Value(0);
		strata &var;
	run;

	ods graphics off;
%mend;

%kmplot(var=CLTV_Category);
%kmplot(var=age_range);

/*call macro numeric var */
proc sql NUMBER;
	select name into: num_var separated by ' ' from dictionary.columns
		where libname='TELECOM' and memname='CHURN_NEWVAR'	and type='num' and findw(name,'Churn_Value')<1 and 
findw(name, 'Tenure_in_Years')<1 and findw(name, 'Satisfaction_Score')<1 ;
quit;
/*Collinearlity*/
PROC REG DATA=telecom.churn_newvar;
   MODEL  Satisfaction_Score = &num_var / vif ;
RUN;
/*call macro char var */
proc sql number;
	select name into: char_var separated by ' ' from dictionary.columns
	where libname='TELECOM' and memname='CHURN_NEWVAR'	and type='char' and find(name, 'Churn')<1 and 
find(name, 'Streaming')<1 and findw(name, 'Dependents')<1 and find(name, 'Referred')<1;
quit;

/*call macro var */
%let var=&char_var &num_var;
%put &var;


/*data separation*/
proc sort data= telecom.churn_newvar out=telecom.sorted;
	by Churn_Value;
run;

proc surveyselect data=telecom.sorted rate=0.7 outall out=telecom.sorted2 seed=1234;
	strata Churn_Value;
run;

data telecom.train telecom.test;
	set telecom.sorted2;

	if selected = 1 then
		output telecom.train;
	else output telecom.test;
	drop selected;
run;

proc freq data=telecom.train;
	table Churn_Value;
run;

proc freq data=telecom.test;
	table Churn_Value;
run;

/*logistic regression modelling*/
proc logistic data=telecom.train descending;
	class &char_var;
	model Churn_Value = &var / selection=stepwise;
run;

/*logistic regression evaluation*/




proc npar1way data=telecom.churn_newvar;
	class Churn_Value Married;

	/*	output out = telecom.pvalue wilcoxon;*/
run;


proc freq data=telecom.churn_newvar;
	table Churn_Value*Multiple_Lines/ CHISQ;

run;




PROC REG DATA=sashelp.cars;
   MODEL MPG_City = EngineSize Weight Length Horsepower / corrb  ;
RUN;

