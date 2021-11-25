/* The case is about a car insurance marketing campaign.
for this project, we will learn how to conduct typical marketing
analytics to evaluate marketing effort*/
/*
Step One - check the key KPI for this marketing campaign:
*/
/* import the data first */
libname ibm '/folders/myfolders/sasproject';
filename reffile '/folders/myfolders/sasproject/marketing_ibm.csv';

proc import datafile=reffile dbms=csv out=car_insurance;
run;

/*Check the total response rate?*/
proc contents data=car_insurance;
run;

proc freq data=car_insurance;
	table response;
run;

/*Step Two - Customer and Segmentation analysis:
When we are reporting and tracking the progress of marketing efforts,
we typically would want to dive deeper into the data and
break down the customer base into multiple segments
and compute KPIs for individual segments*/
/* Q2. Analyze how these response varies by different EmploymentStatus?
get the response rate by each EmploymentStatus group*/
/*       first converte the response into numberic by creating res_flag */
data car_insurance;
	set car_insurance;

	if response='Yes' THEN
		res_flag=1;
	else
		res_flag=0;
run;

proc sql;
	select employmentstatus, sum(res_flag)/count(*) from car_insurance group by 1;
quit;

/* Q3. Analyze how these response varies by different Marital Status*/
proc freq data=car_insurance;
	tables res_flag*maritalstatus;
run;

/* Q4. Analyze how these response varies by different SalesChannel*/
/* using sql */
proc sql;
	select saleschannel, sum(res_flag)/count(*) from car_insurance group by 1;
quit;

/* Q5. Get response rate by sales channel and vehicle size */
proc sql;
	select saleschannel, vehiclesize, sum(res_flag)/count(*) from car_insurance 
		group by 1, 2;
quit;

/* Q6: Let's segment our customer base by Customer Lifetime Value
*/
/*we are going to define those customers with
a Customer Lifetime Value higher than the median as
high-CLV customers
and those with a CLV below the median as low-CLV customers*/
data car_insurance;
	set car_insurance;

	if customerlifetimevalue >=5780.18 then
		clv_seg=2;
	else
		clv_Seg=1;
run;

/* Q7: Let's Get response rate by clv_seg
*/
select clv_seg, sum(res_flag)/count(*) from car_insurance group by 1;
quit;

/*Q8 Create 3 flags for:
Marital Status=Divorced
EmploymentStatus=Retired
SalesChannel=Agent
Baed on previous analysis, do you think that make sense?*/
data car_insurance;
	set car_insurance;

	if maritalstatus="Divorced" then
		Divorced_flag=1;
	else
		divorced_flag=0;

	if employmentstatus='Retired' then
		Retrived_flag=1;
	else
		Retired_Flag=0;

	if saleschannel='Agent' then
		Agent_flag=1;
	else
		Agent_flag=0;
run;

/* Q9: check missing rate for numberical variables */
proc means data=car_insurance n nmiss mean std min max;
	var _numeric_;
run;

/* Step Three - model build: */
/* Q10: Split the data into train(70%) and test(30%) and check average response rate
*/
proc sort data=car_insurance out=car_insurance;
	by res_flag;
run;

proc surveyselect noprint data=car_insurance samprate=.7 out=car_insurance2 
		seed=27513 outall;
	strata res_flag;
run;

data car_train car_test;
	set car_insurance2;

	if selected then
		output car_train;
	else
		output car_test;
run;

proc freq data=car_test;
	table res_flag;
run;

proc freq data=car_train;
	table res_flag;
run;

/*Q11: Build a logistic model by using variables:
Retired_flag
Divorced_flag
Income
TotalClaimAmount
MonthlyPremiumAuto
MonthsSincePolicyInception

Use stepwise to decide the best model*/
proc logistics data=car_train des plots=ROC;
	model res_flag=agent_flag retired_flag divorced_flag income;
run;

/*Q12: Score the model on Test data:*/
proc logistics data=car_train des plots=ROC;
	model res_flag=agent_flag retired_flag divorced_flag income;
	score data=car_test out=scored_test;
run;

proc logistics data=scored_test des plots(only)=ROC;
	model res_flag=p_1;
run;