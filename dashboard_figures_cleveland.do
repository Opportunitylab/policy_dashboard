/*******************************************************************************
						POLICY DASHBOARD FIGURES
********************************************************************************

 PURPOSE: Create figures and for the policy dashboard at the county level

 AUTHOR(S): Jamie Gracie
 DATE: 7.22.17
 
 *Figures that this file constructs
 1) Dynamics of Opportunity
 2) Key Covariates for County
 3) Best/Worst Collegse for Mobility
 
*******************************************************************************/

* Housekeeping
clear all
set more off
adopath ++${dropbox}/ado
set scheme leap_slides

* Macros
global outpath "$dropbox/finer_geo/scratch/cleveland"  
global data_cw "$dropbox/finer_geo/data/raw/crosswalks"
global newdata "$dropbox/finer_geo/data/raw/tract_exposure_estimates" 
global covar "$dropbox/finer_geo/data/derived/covariates"
global county_data "${dropbox}/movers/final_web_files/Online_Tables_Final"
global movers "${dropbox}/finer_geo/data/raw/movers"
global college_data "${dropbox}/ota_cqa/online_tables_clean_07212017/final_tables"
global college_code "${dropbox}/ota_cqa/college_clean/code"
global suffix wmf

********************************************************************************
* Enter Desired County Here (using county FIPS code)
*******************************************************************************
global county = 39035
global state = 39

********************************************************************************
* National Benchmark Score
********************************************************************************
*use the covariate data from 
use "${county_data}/nbhds_online_data_table4.dta" , clear

xtile pctile_mob = perm_res_p25_kr30 [w = cty_pop2000], nq(100)
list pctile_mob if cty2000 == ${county}

/*******************************************************************************
 Figure 1: Dynamics of Opportunity
 K-8 Test Scores, HS Grad Rate, Teen Work, College Attendance, Earnings at 30
*******************************************************************************/

*use the covariate data from 
use "${county_data}/nbhds_online_data_table4.dta", clear
merge 1:1 state_id cty2000 using "${movers}/online_table4.dta", nogen

*Test Scores
xtile pctile_test = score_r [w=cty_pop2000], nq(100)

*Grad Rates
//xtile pctile_grad =   [w = cty_pop2000], nq(100)

*Teen Birth
xtile pctile_birth = perm_res_p25_tb_f [w=cty_pop2000], nq(100)
gen pctile_nonbirth = 100 - pctile_birth

/*Teen Work
xtile pctile_work = perm_res_p25_tl16_8386 [w=cty_pop2000], nq(100)

*College Attendance
xtile pctile_coll =perm_res_p25_c1823 [w=cty_pop2000], nq(100)*/

*College Quality
xtile pctile_collqual = perm_res_p25_kr26_coli [w=cty_pop2000], nq(100)

*Kid Rank at 30
xtile pctile_rank = perm_res_p25_kr30 [w=cty_pop2000], nq(100)

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

label define outcomes 1 `""K-8 Test" "Scores"' 2 `""HS Grad" "Rate""' ///
	3 `""Teen" "Work Rates""' 4 `""College" "Attendance""' 5 `""Earnings" "at Age 30""'
label values order outcomes
sort order

twoway ///
	(scatter pctile_ order, connect(1) ///
		mcolor("146 208 80") msymbol(square) msize(large) ///
		lcolor("146 208 80") lwidth(thick)), ///
	yline(50, lcolor(gray) lpattern(dash) lwidth(medthick)) ///
	ylab(0(50)100, nogrid) ///
	ytick(0(25)100) ///
	ytitle("{bf:Percentile Among}" "{bf:U.S. Counties}") ///
	xlabel(,valuelabel labsize(medsmall)) ///
	xtick(1(1)5.5) ///
	xtitle("") ///
	text(100 1.75 "Better", placement(w))
graph export "${outpath}/dynamics.${suffix}", replace


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
/
*order the variables in chronological order
gen order=0
replace order=5 if cat=="int"
replace order=4 if cat=="two"
replace order=3 if cat=="scap"
replace order=2 if cat=="middle"
replace order=1 if cat=="stud_teach"
sort order

label define factors 5 `"Racial Integration"' 4 `"Two-Parent Households"' ///
	3 `"Social Capital"' 2 `"Size of Middle Class"' 1 `"Teacher-Student Ratio"'
label values order factors

*tag the variables that are good (better than nat avg)
gen tag_good = (pctile_ > 50)

twoway (bar pctile_ order if tag_good==1, ///
			barwidth(0.65) horizontal color("131 199 3")) ///
		(bar pctile_ order if tag_good==0, ///
			barwidth(0.65) horizontal color("231 103 112")), ///
		ylabel(1(1)5, valuelabel nogrid angle(0)) xlabel(0(50)100) ///
		xtick(0(25)100) xline(50, lpattern(dash) lwidth(medthick) lcolor(gray)) ///
		xtitle("Nat. Avg") ytitle("") legend(off)

graph export "${outpath}/rankings.${suffix}", replace


/*********************************************************************
*Figure 3- Best and worst mobility colleges in the county
**********************************************************************/

use "${college_data}/mrc_table1.dta" , clear

*merge in the super opeid crosswalk to opeid crosswalk
merge 1:m super_opeid using "${college_data}/mrc_table11.dta", keep(match) nogen
replace opeid = opeid*100
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

*restrict to county
keep if county==${county}

br name mr_kq5_pq1

*tag best schools by mobility
gsort - mr_kq5_pq1
local half = _N / 2
di `half'
gen best = 1 if _n <= `half'
gsort mr_kq5_pq1
gen worst=1 if _n <= `half'

*add in the county average- there must be abetter way to do this
set obs `=_N+1'
replace name = "County Average" if missing(name)
summ mr_kq5_pq1 [w=count]
replace mr_kq5_pq1=`r(mean)' if name == "County Average"

*add in the national average- again this is rough
set obs `=_N+1'
replace name = "National Average" if missing(name)
replace mr_kq5_pq1= .0194582 if name == "National Average"

gen avg = 1 if inlist(name, "County Average", "National Average")

keep if best==1 | worst==1 | avg==1

gen mob_rate=mr_kq5_pq1*100

gsort mob_rate
gen order = _n

lab def order 0 "temp"
levels(order), local(levels)
foreach l of local levels {
  gen temp = ""
  replace temp = name if order==`l'
  levels(temp), local(templabel)
  lab def newvar `l' `templabel', modify
  drop temp
}
lab val order newvar

drop if mob_rate == 0
br mob_rate order best worst avg

local tick = _N
di `tick'

*construct the figure
**********************
twoway 	///
	(bar mob_rate order if best == 1, ///
		horizontal barwidth(0.65) color("131 199 3")) ///
	(bar mob_rate order if avg == 1, horizontal barwidth(0.65) color(gray)) ///
	(bar mob_rate order if worst == 1, ///
		horizontal barwidth(0.65) color("231 103 112")), ///
	xlabel(0(1)4) ///
	xtick(0(1)4)  ///
	xtitle("Mobility Rate") ytitle("") legend(off) 
graph export "${outpath}/colleges.${suffix}", replace
	
//ylabel(, valuelabel nogrid angle(0)) ///
	
/*********************************************************************
* Figure 4 - Racial Segregation Map
**********************************************************************/
*use the covariate data from 
use "${county_data}/nbhds_online_data_table4.dta" , clear

maptile2 cs_race_theil_2000 if state_id == ${state}, ///
	geo(county) geovar(cty2000) colorscheme("Reds") ///
	zoom savegraph("${outpath}/map_raceseg.png")

/*gen background = 0
	
maptile2 background if inlist(state_id, 18, 39, 42, 21, 54, 26), ///
	geo(county) geovar(cty2000) colorscheme("Greys") ///
	zoom savegraph("${outpath}/map_background.png")*/
	
********************************************************************************
* Figure 5 - Colleges in Cleveland Mobility
********************************************************************************/

* Code below adapted from ${college_code}/slide_figs_tabs/scatters.do
include ${college_code}/metafile_paper_replication.do

use "$college_collapse", clear
merge 1:1 super using "$covariates", ///
	keepusing(iclevel flagship exp_instr_pc_2013) keep(1 3)

* Restrict to colleges in sample
keep if super > 0

* Make fractions into percentages
replace par_q1 = par_q1 * 100
replace kq5_cond_parq1 = kq5_cond_parq1 * 100
replace mr_kq5_pq1 = mr_kq5_pq1 * 100
replace ktop1pc_cond_parq1 = ktop1pc_cond_parq1 * 100
replace mr_ktop1_pq1 = mr_ktop1_pq1 * 100

*** Define Isoquants
sum mr_kq5_pq1 [w = count], d	
local p90: di %3.1f `r(p90)'
local p50: di %3.1f `r(p50)'
local p10: di %3.1f `r(p10)'

cap drop v*
g v10 = r(p90)/par_q1 * 100 if r(p90)/par_q1<1 
g v5 = r(p50)/par_q1 * 100 if r(p50)/par_q1<0.8
g v2 = r(p10)/par_q1 * 100 if r(p10)/par_q1<0.6

gen ohio_tag = cfips == ${county}

sort par_q1

twoway scatter kq5_cond_parq1 par_q1 if par_q1 < 60, mc(gs10) msiz(vsmall) || ///
	scatter v10 v5 v2 par_q1 if par_q1 < 60, m(i i i) lc(gs7 gs7 gs7) c(l 1 1) || ///
	scatter kq5_cond_parq1 par_q1 if ohio_tag == 1, mc(blue) msiz(small) mlab(name) ///
		mlabc(blue) ||, ///
	ytitle("Success Rate: P(Child in Q5 | Par in Q1)") ///
	xtitle("Access: Percent of Parents in Bottom Quintile") ///
	title(" ") xlab(0(20)60) ylab(0(20)100,gmax) ///
	legend(off)
graph export ${outpath}/ohio_isoquant.${suffix}, replace
