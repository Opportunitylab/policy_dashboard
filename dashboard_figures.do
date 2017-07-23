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
global data_cw "$dropbox/finer_geo/data/derived/crosswalks/"
global newdata "$dropbox/finer_geo/data/raw/tract_exposure_estimates" 
global covar "$dropbox/finer_geo/data/derived/covariates"
global county_data "${dropbox}/movers/final_web_files/Online_Tables_Final"
global college_data "${dropbox}/ota_cqa/online_tables_clean_07212017/final_tables"
global suffix png
*The dashboard constructs figures at the county level
*Use this macro to enter the desired county (using the cty2000 variable from the movers data

*For now doing King County (53033)
global county=53033	

cap mkdir "${figs}/county_${county}"
global out_folder "${figs}/county_${county}"
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

graph export "${out_folder}/${county}_fig1.${suffix}", replace
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
		
graph export "${out_folder}/${county}_fig2.${suffix}", replace
/*********************************************************************
*Figure 3- Best and worst mobility colleges in the county
**********************************************************************/

use "${college_data}/mrc_table1.dta" , clear

/*
*for now this is quite manual, need to find zipcodes to change that
keep if czname == "Seattle"
drop if inlist(super_opeid, 3797, 37243, 3794, 3785, 5000, 5001, 5372, 3796, 5306, 3776, 3792, 3772, 22033, 3784, 8155, 5752)
*/
*merge in the super opeid crosswalk to opeid crosswalk
merge 1:m super_opeid using "${college_data}/mrc_table11.dta", keep(match) nogen
replace opeid=opeid*100
preserve

*use IPEDS Zip Code Data
import delimited "${data_cw}/opeid_zip.csv", clear
rename officeofpostsecondaryeducationop opeid
rename zipcodehd2014 zip

keep opeid zip
tempfile zip
save `zip', replace

restore

*not a perfect match need to work on this
merge m:m opeid using `zip', nogen keep(match)

*format the zipcodes
*split the zipcodes at -
split zip, parse(-)
drop zip2
drop zip
rename zip1 zip
destring zip, replace

preserve
*now need a zip to county crosswalk

import delimited "${data_cw}/zip_county.csv", clear
keep county zip
tempfile county
save `county', replace

restore 

merge m:m zip using `county', keep(match)
drop if super_opeid==-1
*this works! (for King County at least. What a time to be alive)



*restrict to county
keep if county==${county}


*tag best schools by mobility
gsort -mr_kq5_pq1
gen best=1 if _n<=5
gsort mr_kq5_pq1
gen worst=1 if _n<=5

*add in the county average- there must be abetter way to do this
set obs `=_N+1'
replace name = "County Avg." if missing(name)
summ mr_kq5_pq1 [w=count]
replace mr_kq5_pq1=`r(mean)' if missing(mr_kq5_pq1)

*add in the national average- again this is rough
set obs `=_N+1'
replace name = "Nat. Avg." if missing(name)
replace mr_kq5_pq1= .0194582 if missing(mr_kq5_pq1)

gen avg=1 if inlist(name, "County Avg.", "Nat. Avg.")

keep if best==1 | worst==1 | avg==1

gen mob_rate=mr_kq5_pq1*100

gsort mob_rate
gen order=_n


*create figure

/*
**********************************************************
*college part
use "D:\jgracie\Dropbox\ota_cqa\online_tables_clean_07212017\final_tables\mrc_table1.dta" 
keep if czname=="Seattle"

drop if inlist(super_opeid, 3797, 37243, 3794, 3785, 5000, 5001, 5372, 3796, 5306, 3776, 3792, 3772, 22033, 3784, 8155, 5752)
 summ mr_kq5_pq1 [w=count]
