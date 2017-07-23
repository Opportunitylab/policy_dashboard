/*******************************************************************************
				POLICY DASHBOARD FIGURES
********************************************************************************

 PURPOSE: Create figures and for the policy dashboard

 AUTHOR(S): Jamie Gracie
 DATE: 7.22.17
 
 *Figures that this file constructs
 1) Dynamics of Opportunity
 
*******************************************************************************/

* Housekeeping
clear all
set more off
adopath ++${dropbox}/ado
set scheme leap_slides

* Macros
global figs "$dropbox/finer_geo/seattle/tract_figs/dashboard"  
global data "$dropbox/finer_geo/seattle/tract_data"
global newdata "$dropbox/finer_geo/data/raw/tract_exposure_estimates" 
global covar "$dropbox/finer_geo/data/derived/covariates"
global county_data "${dropbox}/movers/final_web_files/Online_Tables_Final"

*The dashboard constructs figures at the county level
*Use this macro to enter the desired county (using the cty2000 variable from the movers data

*For now doing King County (53033)
global county=53033	
/*
********************************************************************************
* Figure 1- Dynamics of Opportunity
		*Variables of interest - K-8 Test Scores, HS Grad Rate, Teen Work, College Attendance, 
			Earnings at 30
********************************************************************************/

*use the covariate data from 
use "${county_data}/nbhds_online_data_table4.dta" , clear


*Test Scores
xtile pctile_test=score_r [w=cty_pop2000], nq(100)
list pctile_test if cty2000==${county}

*Grad Rates
*We imputed (mentally) the King County rank because of missing data
gen grad_rate=1-dropout_r
replace grad_rate=.804 if cty2000==53033
xtile pctile_grad=grad_rate [w=cty_pop2000], nq(100)
list pctile_grad if cty2000==${county}

replace pctile_grad=40 if cty2000==${county}

*Teen Work
xtile pctile_work= frac_worked1416 [w=cty_pop2000], nq(100)
list pctile_work if cty2000==${county}

*College Attendance
xtile pctile_coll=perm_res_p25_c1823 [w=cty_pop2000], nq(100)
list pctile_coll if cty2000==${county}

*Kid Rank at 30
xtile pctile_rank= perm_res_p25_kr30 [w=cty_pop2000], nq(100)
list pctile_rank if cty2000==${county}

*construct the figure
**********************
keep if cty2000==$county
keep cty2000 pctile*
*reshape long
reshape long pctile_, i(cty2000) j(cat) string
*order the variables in chronological order
gen order=0
replace order=1 if cat=="test"
replace order=2 if cat=="grad"
replace order=3 if cat=="work"
replace order=4 if cat=="coll"
replace order=5 if cat=="rank"

label define outcomes 1 `""K-8" "Test Scores""' 2 `""HS Grad" "Rate""' 3 `""Teen" "Work""' 4 `""College" "Attendance""' 5 `""Earnings at" "30""'
label values order outcomes
sort order
twoway (scatter pctile_ order, connect(1) mcolor(green) lcolor(green)), ///
	yline(50, lcolor(gray) lpattern(dash)) ylab(0(50)100, nogrid) ytick(0(25)100) ///
	ytitle("Percentile Among U.S. Counties") xtitle("") xlabel(,valuelabel labsize(medsmall))


/******************************************************************************
*Figure 2- National Percentile on Key Factors
	*Variables of Interest: Social Capital, Fraction Middle Class, Racial Integration,
		*Two parent Households, Teacher Student Ratio
******************************************************************************/
*use the covariate data from 
use "${county_data}/nbhds_online_data_table4.dta" , clear

*create percentiles

*student teacher ratio 
xtile pctile_stud_teach=ccd_pup_tch_ratio [w=cty_pop2000], nq(100)
list pctile_stud_teach if cty2000==${county}
*invert so that high number is good
replace pctile_stud_teach=100-pctile_stud_teach

*racial integration (take segregation percentile and do (100-percentile)
xtile pctile_seg=cs_race_theil_2000 [w=cty_pop2000], nq(100)
list pctile_seg if cty2000==${county}
gen pctile_int=100-pctile_seg
drop pctile_seg

*Share Two Parent Households (share of single parents and 100-pctile)
xtile pctile_single=cs_fam_wkidsinglemom [w=cty_pop2000], nq(100)
list pctile_single if cty2000==${county}
gen pctile_two=100-pctile_single
drop pctile_single

*social capital
xtile pctile_scap=scap_ski90pcm [w=cty_pop2000], nq(100)
list pctile_scap if cty2000==${county}

*share middle class
xtile pctile_middle=frac_middleclass [w=cty_pop2000], nq(100)
list pctile_middle if cty2000==${county}

*construct the figure
**********************
keep if cty2000==$county
keep cty2000 pctile*
*reshape long
reshape long pctile_, i(cty2000) j(cat) string
*order the variables in chronological order
gen order=0
replace order=5 if cat=="scap"
replace order=4 if cat=="middle"
replace order=3 if cat=="int"
replace order=2 if cat=="two"
replace order=1 if cat=="stud_teach"
sort order

label define factors 5 "Social Capital" 4 "Fraction Middle Class" 3 "Racial Integration" 2 "Two-Parent Households" 1 "Teacher-Student Ratio"
label values order factors
*tag the variables that are good (better than nat avg)
gen tag_good=(pctile_>50)

twoway (bar pctile_ order if tag_good==1, horizontal color(green) ) ///
		(bar pctile_ order if tag_good==0, horizontal color(maroon)), ///
		ylabel(1(1)5, valuelabel nogrid angle(0)) xlabel(0(50)100) ///
		xtick(0(25)100) xline(50, lpattern(dash) lcolor(gray)) ///
		xtitle("") ytitle("") legend(off)
		

/*********************************************************************
*Figure 3- Best and worst mobility colleges in the county
**********************************************************************/
*Trajectory Plot
*CZ level
use "C:\Users\jgracie\Downloads\online_table3.dta" , clear

xtile test=score_r [w=pop2000], nq(100)
list test if cz==39400

*We imputed (mentally) the Seattle rank because of missing data
/*
gen grad_rate=1-dropout_r
replace grad_rate=.775 if cz==39400
xtile grad=grad_rate [w=pop2000], nq(100)
list grad if cz==39400
*/
xtile work= frac_worked1416 [w=pop2000], nq(100)
list work if cz==39400

gen perm_res_p25_tb_neg=-perm_res_p25_tb
xtile teen=perm_res_p25_tb_neg [w=pop2000], nq(100)
list teen if cz==39400

xtile coll=perm_res_p25_c1823 [w=pop2000], nq(100)
list coll if cz==39400

xtile rank= perm_res_p25_kr30 [w=pop2000], nq(100)
list rank if cz==39400

*County Level
use "C:\Users\jgracie\Downloads\online_table4.dta" , clear
xtile test=score_r [w=cty_pop2000], nq(100)
list test if cty2000==53033

*We imputed (mentally) the King County rank because of missing data
/*
gen grad_rate=1-dropout_r
replace grad_rate=.804 if cty2000==53033
xtile grad=grad_rate [w=cty_pop2000], nq(100)
list grad if cty2000==53033
*/
xtile work= frac_worked1416 [w=cty_pop2000], nq(100)
list work if cty2000==53033

gen perm_res_p25_tb_neg=-perm_res_p25_tb
xtile teen=perm_res_p25_tb_neg [w=cty_pop2000], nq(100)
list teen if cty2000==53033

xtile coll=perm_res_p25_c1823 [w=cty_pop2000], nq(100)
list coll if cty2000==53033

xtile rank= perm_res_p25_kr30 [w=cty_pop2000], nq(100)
list rank if cty2000==53033


**********************************************************
*college part
use "D:\jgracie\Dropbox\ota_cqa\online_tables_clean_07212017\final_tables\mrc_table1.dta" 
keep if czname=="Seattle"

drop if inlist(super_opeid, 3797, 37243, 3794, 3785, 5000, 5001, 5372, 3796, 5306, 3776, 3792, 3772, 22033, 3784, 8155, 5752)
 summ mr_kq5_pq1 [w=count]
