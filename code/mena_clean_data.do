/* 
initial ACS data cleaning
10/28/25
mena kiser 
*/

clear all 
set more off

global wd "/Users/jimenakiser/Desktop/econ 80/e80_ps2/"
global dd "$wd/data/"
global od "$wd/output/"



* obtain ACS data as provided 
use "$dd/ps2_acs_2008to2019-5.dta", clear

* create variables to best evaluate baseline group

*** age and childbearing
replace yngch = . if yngch==99
gen newbaby = yngch<=1 & yngch!=. 
gen newparent = newbaby & nchild==1
//try freshbaby= yngch<=0 & yngch!=. 

*** demographic variables
gen male = sex==1
gen married = inlist(marst, 1, 2)
gen separated = inlist(marst, 3)
gen single = inlist(marst, 4, 5, 6) //to change depending on specification

**** race
gen white = race==1
gen black = race==2
gen native = race==3
gen asian = inlist(race, 4, 5, 6)
gen other = inlist(race, 7, 8, 9)
tab educ, gen(educ_d)
tab educ_sp, gen(educ_sp_d)
gen any_hispan = hispan!=0

**** work variables
gen fulltime = uhrswork>=40
gen employed = empstat==1
foreach v in hcovany hinsemp hcovpub hinscaid {
    gen has_`v' = `v'==1
}

*** medicaid, from PS notes
gen post_mcaid = (year>=medicaid_exp_year)* medicaid_exp //creates a dummy=1 for years in which Medicaid expansion is in effect in a state, e.g. treated*post.
gen relative_year = medicaid_exp_year - year
replace relative_year = 0 if medicaid_exp_year == 0
forval i = 1/11 {
    gen mcaid_plus`i' = (year==medicaid_exp_year+`i')* medicaid_exp    
    gen mcaid_minus`i' = (year==medicaid_exp_year-`i')* medicaid_exp
}

*** outcomes, controls, and heterogeneity variables to try 
global outvars has_hcovany has_hinscaid has_hcovpub has_hinsemp nchild newbaby //newparent
global covars male age /*race*/ white black native asian other any_hispan /* marital status*/ married separated single /*own educ*/ educ_d2 educ_d3 educ_d4 educ_d5 educ_d6 employed incearn fulltime
global hetvars male any_hispan employed

compress
save "$dd/ps2_working_data", replace

