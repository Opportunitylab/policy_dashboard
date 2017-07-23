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
global county_data "${dropbox}/movers/final_web_files/Online_Tables_Final/nbhds_online_data_table4.dta"

*The dashboard constructs figures at the county level
*Use this macro to enter the desired county (using the cty2000 variable from the movers data

*For now doing King County (53033)
global county=53033	
/*
********************************************************************************
* Figure 1- Dynamics of Opportunity
********************************************************************************/
*Variables of interest - K-8 Test Scores, HS Grad Rate, Teen Work, College Attendance, Earnings at 30

*use the covariate data from 
use "C:\Users\jgracie\Downloads\online_table4.dta" , clear


*Test Scores
xtile pctile_test=score_r [w=cty_pop2000], nq(100)
list pctile_test if cty2000==${county}

*Grad Rates
*We imputed (mentally) the King County rank because of missing data
/*
gen grad_rate=1-dropout_r
replace grad_rate=.804 if cty2000==53033
xtile pctile_grad=grad_rate [w=cty_pop2000], nq(100)
list pctile_grad if cty2000==${county}
*/
gen pctile_grad=45 if cty2000==${county}

*Teen Work
xtile pctile_work= frac_worked1416 [w=cty_pop2000], nq(100)
list pctile_work if cty2000==${county}

*College Attendance
xtile coll=pctile_perm_res_p25_c1823 [w=cty_pop2000], nq(100)
list pctile_coll if cty2000==${county}

*Kid Rank at 30
xtile rank= perm_res_p25_kr30 [w=cty_pop2000], nq(100)
list pctile_rank if cty2000==${county}

******************************************************************************
*create percentiles
xtile stud_teach_2=ccd_pup_tch_ratio [w=cty_pop2000], nq(100)
list stud_teach_2 if cty2000==53033

xtile seg=cs_race_theil_2000 [w=cty_pop2000], nq(100)
list seg if cty2000==53033

xtile single=cs_fam_wkidsinglemom [w=cty_pop2000], nq(100)
list single if cty2000==53033

xtile scap=scap_ski90pcm [w=cty_pop2000], nq(100)
list scap if cty2000==53033

*change this to share middle class
/*
xtile poor=poor_share [w=cty_pop2000], nq(100)
list poor if cty2000==53033
*/
xtile middle=frac_middleclass [w=cty_pop2000], nq(100)
list middle if cty2000==53033
/

xtile gini_2=gini [w=cty_pop2000], nq(100)
list gini_2 if cty2000==53033
*********************************************************************
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
