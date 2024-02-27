/*set working environment*/
data _null_;
	rc=dlgcdir("D:\Idata-global\Telecom Project\Tele-Project");
	put rc=;
run;
/*create telecom library*/
libname telecom "D:\Idata-global\Telecom Project\Tele-Project";


/*import data*/
%macro dataimport(input, output);
proc import datafile=&input out= telecom.&output
   dbms=xlsx
   replace;
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
inner join telecom.location lo on de.'Customer ID'n =lo.'Customer ID'n
left join telecom.population po on lo.'Zip Code'n = po.'Zip Code'n
inner join telecom.services se on de.'Customer ID'n =se.'Customer ID'n
inner join telecom.status st on st.'Customer ID'n =lo.'Customer ID'n;
quit;

/*data telecom.churn;*/
/*set telecom.churn (keep= 'Customer ID'n Gender Age 'Under 30'n 'Senior Citizen'n Married Dependents 'Number of Dependents'n City 'Zip Code'n*/
/*Population 'Referred a Friend'n 'Number of Referrals'n 'Tenure in Months'n Offer 'Phone Service'n 'Avg Monthly Long Distance Charge'n 'Multiple Lines'n*/
/*'Internet Service'n 'Internet Type'n 'Online Security'n 'Online Backup'n)*/
/*;*/

proc freq data=telecom.churn;
tables 'Tenure in Months'n;
run;




