/* 
summar stats
10/28/25
mena kiser 
*/

clear all 
set more off

global wd "/Users/jimenakiser/Desktop/econ 80/e80_ps2/"
global dd "$wd/data/"
global od "$wd/output/"

program main 

    use "$dd/ps2_working_data" , clear 
    /*****************************************************
    Table 1: Summary statistics
    ******************************************************/

    * obtain means and standard deviations
    cap mat drop mall mun mpre mpost
    cap drop allinfile nomedicaid_exp medicaid_exp_pre medicaid_exp_post
    gen allinfile = 1
    gen nomedicaid_exp = medicaid_exp==0
    gen medicaid_exp_pre = medicaid_exp==1 & post_mcaid==0 //treated state but pre expansion
    gen medicaid_exp_post = medicaid_exp==1 & post_mcaid==1 //treated state post expansion
    foreach v of varlist $allvars {
        di in red "var `v'"
        storemean, varname(`v') restriction(allinfile) tosum(_cons)  mat(mall)
        storemean, varname(`v') restriction(nomedicaid_exp) tosum(nomedicaid_exp) mat(mun)  cond(nocons)
        storemean, varname(`v') restriction(medicaid_exp_pre) tosum(medicaid_exp) mat(mpre) cond(nocons)
        storemean, varname(`v') restriction(medicaid_exp_post) tosum(medicaid_exp) mat(mpost) cond(nocons)
    }
    drop allinfile nomedicaid_exp medicaid_exp_pre medicaid_exp_post

    //store latex summary stats matrix, manually creating to fit desired format
    cap file close sumstat
    file open sumstat using "$od/t1_sum_stat.tex", write replace
    file write sumstat "\begin{tabular}{lcccccccc}" _n
    file write sumstat "\toprule" _n
    file write sumstat "\toprule" _n
    file write sumstat "  & & & & & \multicolumn{4}{c}{Ever State} \\" _n
    file write sumstat " Variable & \multicolumn{2}{c}{All} & \multicolumn{2}{c}{Never Treated} & \multicolumn{2}{c}{Pre Expansion} & \multicolumn{2}{c}{Post Expansion} \\" _n
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
            foreach mat in mall mun mpre mpost {
                local vmean = string(`mat'[`rowcount',1], "%12.3fc")
                local vsd = string(`mat'[`rowcount',2], "%12.3fc")
                file write sumstat " & `vmean' & (`vsd') "
            }
            file write sumstat " \\" _n
            local++ rowcount
        }
        else {
            file write sumstat " & & & & & \\" _n
        }
    }
    file write sumstat "\\" _n
    local n1 = string(mall[1,3], "%12.0fc")
    local n2 = string(mun[1,3], "%12.0fc")
    local n3 = string(mpre[1,3], "%12.0fc")
    local n3 = string(mpost[1,3], "%12.0fc")
    file write sumstat "Sample size & \multicolumn{2}{c}{`n1'} & \multicolumn{2}{c}{`n2'} & \multicolumn{2}{c}{`n3'} \\" _n
    file write sumstat "\bottomrule" _n
    file write sumstat "\bottomrule" _n
    file write sumstat "\end{tabular}"
    file close sumstat


end

* set up globals 
*** outcomes, controls, and heterogeneity variables to try 
global outvars has_hcovany has_hinscaid has_hcovpub has_hinsemp nchild newbaby //newparent
global covars male age /*race*/ white black native asian other any_hispan /* marital status*/ married separated single /*own educ*/ educ_d2 educ_d3 educ_d4 educ_d5 educ_d6 employed incearn fulltime
global hetvars male any_hispan employed
*** for tables
global allvars "male age white black native asian other any_hispan married separated single nchild yngch has_hcovany has_hinsemp has_hcovpub has_hinscaid educ_d2 educ_d3 educ_d4 educ_d5 educ_d6 educ_sp_d2 educ_sp_d3 educ_sp_d4 educ_sp_d5 educ_sp_d6 educ_sp_d7 educ_sp_d8 educ_sp_d9 educ_sp_d10 educ_sp_d11 employed incearn uhrswork "
global sum_varnames `" "Male" "Age" "Race" "\hspace{0.3cm}  White" "\hspace{0.3cm}  Black" "\hspace{0.3cm}  Native American" "\hspace{0.3cm}  Asian" "\hspace{0.3cm}  Other" "Hispanic origin" "Marital status" "\hspace{0.3cm} Currently married" "\hspace{0.3cm} Separated" "\hspace{0.3cm} Single"  "Number of children" "Age of youngest child" "Insurance coverage" "\hspace{0.3cm}  Any coverage" "\hspace{0.3cm}  Coverage through employer"  "\hspace{0.3cm}  Public insurance coverage"  "\hspace{0.3cm}  Coverage through Medicaid"  "Educational attainment" "\hspace{0.3cm} Grade $<=$4" "\hspace{0.3cm}  Grades 5--8" "\hspace{0.3cm} Grade 9" "\hspace{0.3cm} Grade 10" "\hspace{0.3cm} Grade 11" "Educational attainment of spouse" "\hspace{0.3cm} Grade $<=$4" "\hspace{0.3cm}  Grades 5--8" "\hspace{0.3cm} Grade 9" "\hspace{0.3cm} Grade 10" "\hspace{0.3cm} Grade 11" "\hspace{0.3cm} Grade 12" "\hspace{0.3cm} 1y of college" "\hspace{0.3cm} 2y of college" "\hspace{0.3cm} 4y of college"  "\hspace{0.3cm} 5$+$ y of college" "Employed" "Earned income" "Usual weekly hours worked" "'


cap program drop storemean
program define storemean
syntax, varname(str) mat(str) restriction(str) tosum(str) [cond(str)]
    qui reg `varname' `restriction' [pw=perwt] , `cond'
    local m = _b[`tosum']
    local sd = _se[`tosum']
    local n = e(N)
    mat `mat' = nullmat(`mat') \ (`m' , `sd', `n')
end