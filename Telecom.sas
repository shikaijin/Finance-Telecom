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


/*data telecom.churn;*/
/*set telecom.churn (keep= 'Customer ID'n Gender Age 'Under 30'n 'Senior Citizen'n Married Dependents 'Number of Dependents'n City 'Zip Code'n*/
/*Population 'Referred a Friend'n 'Number of Referrals'n 'Tenure in Months'n Offer 'Phone Service'n 'Avg Monthly Long Distance Charge'n 'Multiple Lines'n*/
/*'Internet Service'n 'Internet Type'n 'Online Security'n 'Online Backup'n)*/
/*;*/
title;
proc freq data=telecom.churn;
	tables Contract;
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

data telecom.churn_newvar;
	set telecom.churn;
	*definition of age band;
	length  age_range $ 20;
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
		age_range='less than 75';
	else age_range='75 and plder';
run;


proc freq data=telecom.churn_newvar;
	tables age_range;
run;
