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
gen hispan_sum = hispan!=0

**** work variables
gen fulltime = uhrswork>=40
gen employed = empstat==1
foreach v in hcovany hinsemp hcovpub hinscaid {
    gen has_`v' = `v'==1
}

/*** medicaid
gen post_mcaid = (year>=medicaid_exp_year)* medicaid_exp” creates a
dummy=1 for years in which Medicaid expansion is in effect in a state, e.g. treated*post.
gen mcaid_plus1 = (year==medicaid_exp_year+1)* medicaid_exp
gen mcaid_minus2 = (year==medicaid_exp_year-2)* medicaid_exp*/


*** additional controls

compress
save "$dt/working_data", replace


//note: no identifying variables: no serial and pernum
//incearn is bottom coded at -$9,999
fre educ 
fre educ_sp

* Summary Statistics
global allvars "male age white black native asian other hispan_sum married separated single nchild yngch has_hcovany has_hinsemp has_hcovpub has_hinscaid educ_d2 educ_d3 educ_d4 educ_d5 educ_d6 educ_sp_d2 educ_sp_d3 educ_sp_d4 educ_sp_d5 educ_sp_d6 educ_sp_d7 educ_sp_d8 educ_sp_d9 educ_sp_d10 educ_sp_d11 employed incearn uhrswork "
global sum_varnames `" "Male" "Age" "Race" "\hspace{0.3cm}  White" "\hspace{0.3cm}  Black" "\hspace{0.3cm}  Native American" "\hspace{0.3cm}  Asian" "\hspace{0.3cm}  Other" "Hispanic origin" "Marital status" "\hspace{0.3cm} Currently married" "\hspace{0.3cm} Separated" "\hspace{0.3cm} Single"  "Number of children" "Age of youngest child" "Insurance coverage" "\hspace{0.3cm}  Any coverage" "\hspace{0.3cm}  Coverage through employer"  "\hspace{0.3cm}  Public insurance coverage"  "\hspace{0.3cm}  Coverage through Medicaid"  "Educational attainment" "\hspace{0.3cm} Grade $<=$4" "\hspace{0.3cm}  Grades 5--8" "\hspace{0.3cm} Grade 9" "\hspace{0.3cm} Grade 10" "\hspace{0.3cm} Grade 11" "Educational attainment of spouse" "\hspace{0.3cm} Grade $<=$4" "\hspace{0.3cm}  Grades 5--8" "\hspace{0.3cm} Grade 9" "\hspace{0.3cm} Grade 10" "\hspace{0.3cm} Grade 11" "\hspace{0.3cm} Grade 12" "\hspace{0.3cm} 1 year of college" "\hspace{0.3cm} 2 years of college" "\hspace{0.3cm} 4 years of college"  "\hspace{0.3cm} 5$+$ years of college" "Employed" "Earned income" "Usual weekly hours worked" "'

cap program drop storemean
program define storemean
syntax, varname(str) mat(str) restriction(str) tosum(str) [cond(str)]
    qui reg `varname' `restriction' [pw=perwt] , `cond'
    local m = _b[`tosum']
    local sd = _se[`tosum']
    local n = e(N)
    mat `mat' = nullmat(`mat') \ (`m' , `sd', `n')
end

* obtain means and standard deviations
cap mat drop mall
cap mat drop mun 
cap mat drop mtr
cap drop allinfile
cap drop nomedicaid_exp
gen allinfile = 1
gen nomedicaid_exp = medicaid_exp==0
foreach v of varlist $allvars {
    di in red "var `v'"
    storemean, varname(`v') restriction(allinfile) tosum(_cons)  mat(mall)
    storemean, varname(`v') restriction(nomedicaid_exp) tosum(nomedicaid_exp) mat(mun)  cond(nocons)
    storemean, varname(`v') restriction(medicaid_exp) tosum(medicaid_exp) mat(mtr) cond(nocons)
}



//store latex summary stats matrix, manually creating to fit desired format
cap file close sumstat
file open sumstat using "$od/t1_sum_stat.tex", write replace
file write sumstat "\begin{tabular}{lcccccc}" _n
file write sumstat "\toprule" _n
file write sumstat "\toprule" _n
file write sumstat " Variable & \multicolumn{2}{c}{All} & \multicolumn{2}{c}{Never Treated} & \multicolumn{2}{c}{Treated State} \\" _n
file write sumstat "\midrule " _n 
local ncount : word count $sum_varnames
di `ncount'
local rowcount = 1
forval i=1/`ncount' {
	local varlab: word `i' of $sum_varnames
    di "row `rowcount'"
    file write sumstat " `varlab'  "

	if `i' != 3 & `i' != 10 & `i' != 16 & `i' != 21 & `i' != 27   {
        * store mean
        foreach mat in mall mun mtr {
            local vmean = string(`mat'[`rowcount',1], "%12.3fc")
            local vsd = string(`mat'[`rowcount',2], "%12.3fc")
            file write sumstat " & `vmean' & (`vsd') "
        }
        file write sumstat " \\" _n
        local++ rowcount
	}
	else {
		file write sumstat " & & &  \\" _n
	}
}
file write sumstat "\\" _n
local n1 = string(mall[1,3], "%12.0fc")
local n2 = string(mun[1,3], "%12.0fc")
local n3 = string(mtr[1,3], "%12.0fc")
file write sumstat "Observations & \multicolumn{2}{c}{`n1'} & \multicolumn{2}{c}{`n2'} & \multicolumn{2}{c}{`n3'} \\" _n
file write sumstat "\bottomrule" _n
file write sumstat "\bottomrule" _n
file write sumstat "\end{tabular}"
file close sumstat


