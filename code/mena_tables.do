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
    gen medicaid_exp_pre = medicaid_exp==1 & year<medicaid_exp_year //treated state but pre expansion
    gen medicaid_exp_post = medicaid_exp==1 & year>=medicaid_exp_year //treated state post expansion
    foreach v of varlist $allvars {
        di in red "var `v'"
        storemean, varname(`v') restriction(allinfile) tosum(_cons)  mat(mall)
        storemean, varname(`v') restriction(nomedicaid_exp) tosum(nomedicaid_exp) mat(mun)  cond(nocons)
        storemean, varname(`v') restriction(medicaid_exp_pre) tosum(medicaid_exp) mat(mpre) cond(nocons)
        storemean, varname(`v') restriction(medicaid_exp_post) tosum(medicaid_exp) mat(mpost) cond(nocons)
    }

    //store latex summary stats matrix, manually creating to fit desired format
    cap file close sumstat
    file open sumstat using "$od/t1_sum_stat.tex", write replace
    file write sumstat "\begin{tabular}{lcccccccc}" _n
    file write sumstat "\toprule" _n
    file write sumstat "\toprule" _n
    file write sumstat "  & & & & & \multicolumn{4}{c}{State Ever Treated} \\" _n
    file write sumstat " Variable & \multicolumn{2}{c}{All} & \multicolumn{2}{c}{Never Treated} & \multicolumn{2}{c}{Pre Expansion} & \multicolumn{2}{c}{Post Expansion} \\" _n
    file write sumstat "\midrule " _n 
    local ncount : word count $sum_varnames
    di `ncount'
    local rowcount = 1
    forval i=1/`ncount' {
        local varlab: word `i' of $sum_varnames
        di "row `rowcount'"
        file write sumstat " `varlab'  "

        if `i' != 3 & `i' != 10 & `i' != 18 & `i' != 23 & `i' != 30   {
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
    //store sample size
    file write sumstat "Sample size"
    foreach v in  allinfile nomedicaid_exp medicaid_exp_pre medicaid_exp_post {
        qui count if `v'==1
        local size = string( r(N), "%12.0fc" )
        file write sumstat " & \multicolumn{2}{c}{`size'} "
    }
    file write sumstat " \\" _n

    file write sumstat "\bottomrule" _n
    file write sumstat "\bottomrule" _n
    file write sumstat "\end{tabular}"
    file close sumstat

    drop allinfile nomedicaid_exp medicaid_exp_pre medicaid_exp_post
    
    /*****************************************************
    Table 2: Define focus regression
    ******************************************************/
    use "$dd/ps2_working_data" , clear 

    *** coverage
    cap mat drop cov
    reghdfe has_hcovany post_mcaid $covars married $empvars [pw=perwt], vce(cluster statefip year) absorb(statefip year) 
    reg_to_mat, depvar(has_hcovany) indvars(post_mcaid $covars married $empvars) mat(cov)
    reghdfe has_hcovany post_mcaid $covars married $empvars  [pw=perwt], vce(cluster statefip year) absorb(statefip year) 
    reg_to_mat, depvar(has_hcovany) indvars(post_mcaid $covars married $empvars) mat(cov)

    reghdfe has_hinscaid post_mcaid $covars married $empvars [pw=perwt], vce(cluster statefip year) absorb(statefip year)
    reg_to_mat, depvar(has_hinscaid) indvars(post_mcaid $covars married $empvars) mat(cov)
    
    reghdfe has_hcovpub post_mcaid $covars married $empvars [pw=perwt], vce(cluster statefip year) absorb(statefip year)
    reg_to_mat, depvar(has_hcovpub) indvars(post_mcaid $covars married $empvars) mat(cov)
    
    reghdfe has_hinsemp post_mcaid $covars married $empvars [pw=perwt], vce(cluster statefip year) absorb(statefip year) 
    reg_to_mat, depvar(has_hinsemp) indvars(post_mcaid $covars married $empvars) mat(cov)


    //store latex summary stats matrix, manually creating to fit desired format
    cap file close sumstat
    file open sumstat using "$od/cov_did.tex", write replace
    file write sumstat "\begin{tabular}{lcccc}" _n
    file write sumstat "\toprule" _n
    file write sumstat "\toprule" _n
    file write sumstat " Variable & Any insurance & Medicaid & Public insurance & Coverage through \\" _n
    file write sumstat "  & coverage & coverage & coverage &  employer \\" _n
    file write sumstat "  & (1) & (2) & (3) &  (4) \\" _n
    file write sumstat "\midrule " _n 
    
    local i = 1
    local rowcount = 1

    while `rowcount' < 45 {
        local varlab: word `i' of $cov_varnames
        * label
        file write sumstat " `varlab'  "
        if `i' != 6 {
            storecoeff, mat(cov) row(`rowcount') cols(1 2 3 4)
            local rowcount = `rowcount' +3
        }
        if `i'== 6 {
            file write sumstat "\\" _n
        }
        local++ i
    }
    file write sumstat "\\" _n
    //store sample size
    forval col = 1/4 {
        local r2_`col' = string(cov[46,`col'], "%12.3fc")
        local n_`col' = string(cov[48,`col'], "%12.0fc")
        }
    file write sumstat "R-2 & `r2_1' & `r2_2' & `r2_3' & `r2_4' \\" _n
    file write sumstat "Sample size & `n_1' & `n_2' & `n_3' & `n_4' \\" _n
    file write sumstat "\bottomrule" _n
    file write sumstat "\bottomrule" _n
    file write sumstat "\end{tabular}"
    file close sumstat


    /*****************************************************
    Table 3: Differences across expansion
    ******************************************************/
    use "$dd/ps2_working_data" , clear 

    cap mat drop expdiff

    *** marital
    reghdfe married post_mcaid $covars [pw=perwt], vce(cluster statefip year) absorb(statefip year)
    reg_to_mat, depvar(married) indvars(post_mcaid $covars) mat(expdiff)

    *** employment 
    reghdfe employed post_mcaid $covars married [pw=perwt], vce(cluster statefip year) absorb(statefip year)
    reg_to_mat, depvar(employed) indvars(post_mcaid $covars) mat(expdiff)
    reghdfe incearn post_mcaid $covars married [pw=perwt], vce(cluster statefip year) absorb(statefip year)
    reg_to_mat, depvar(incearn) indvars(post_mcaid $covars) mat(expdiff)
    reghdfe fulltime post_mcaid $covars married [pw=perwt], vce(cluster statefip year) absorb(statefip year)
    reg_to_mat, depvar(fulltime) indvars(post_mcaid $covars) mat(expdiff)
    reghdfe uhrswork post_mcaid $covars married [pw=perwt], vce(cluster statefip year) absorb(statefip year)
    reg_to_mat, depvar(uhrswork) indvars(post_mcaid $covars) mat(expdiff)


    //store latex summary stats matrix, manually creating to fit desired format
    cap file close sumstat
    file open sumstat using "$od/expdiff.tex", write replace
    file write sumstat "\begin{tabular}{lccccc}" _n
    file write sumstat "\toprule" _n
    file write sumstat "\toprule" _n
    file write sumstat " Variable & Currently & Employed & Earned & Full time & Weekly \\" _n
    file write sumstat "  & married &  & income &  status & hours \\" _n
    file write sumstat "  & (1) & (2) & (3) &  (4) & (5) \\" _n
    file write sumstat "\midrule " _n 
    
    local i = 1
    local rowcount = 1

    while `rowcount' < 33 {
        local varlab: word `i' of $cov_varnames
        * label
        file write sumstat " `varlab'  "
        if `i' != 6 {
            storecoeff, mat(expdiff) row(`rowcount') cols(1 2 3 4 5)
            local rowcount = `rowcount' +3
        }
        if `i'== 6 {
            file write sumstat "\\" _n
        }
        local++ i
    }
    file write sumstat "\\" _n
    //store sample size
    forval col = 1/5 {
        local r2_`col' = string(expdiff[31,`col'], "%12.3fc")
        local n_`col' = string(expdiff[33,`col'], "%12.0fc")
        }
    file write sumstat "R-2 & `r2_1' & `r2_2' & `r2_3' & `r2_4' & `r2_5' \\" _n
    file write sumstat "Sample size & `n_1' & `n_2' & `n_3' & `n_4'  & `n_5' \\" _n
    file write sumstat "\bottomrule" _n
    file write sumstat "\bottomrule" _n
    file write sumstat "\end{tabular}"
    file close sumstat






    *** marital
    reghdfe married post_mcaid $covars [pw=perwt], vce(cluster statefip year) absorb(statefip year) //neg and small high p, male (-), age (+), white (+), hispan

    *** employment 
    reghdfe employed post_mcaid $covars married [pw=perwt], vce(cluster statefip year) absorb(statefip year) //pos small high p, male (+), age (+), white (+), hispan (+),
    reghdfe incearn post_mcaid $covars married [pw=perwt], vce(cluster statefip year) absorb(statefip year) //neg small high p, male (+), age (+), white (+), hispan (+),
    reghdfe fulltime post_mcaid $covars married [pw=perwt], vce(cluster statefip year) absorb(statefip year) //pos small high p, male (+), age (+), white (+), hispan (+),
    reghdfe uhrswork post_mcaid $covars married [pw=perwt], vce(cluster statefip year) absorb(statefip year) //pos small high p, male (+), age (+), white (+), hispan (+),

    *** childbearing, age is more important here
    reghdfe nchild post_mcaid $covars [pw=perwt], vce(cluster statefip year) absorb(statefip year) // neg sig, male (-), age (+), white (+), hispanic (+)
    reghdfe newbaby post_mcaid $covars [pw=perwt], vce(cluster statefip year) absorb(statefip year) //neg, p=0.2, male (-), age (-), white (+), hispanic (+)

    * not many changes when including married
    reghdfe nchild post_mcaid $covars married [pw=perwt], vce(cluster statefip year) absorb(statefip year) // neg, p=0.1, male (-), age (+), white (+), hispanic (+)
    reghdfe newbaby post_mcaid $covars married [pw=perwt], vce(cluster statefip year) absorb(statefip year) //neg, p=0.2, male (-), age (-), white (+), hispanic (+)

    * not many changes when adding employment 
    reghdfe nchild post_mcaid $covars  employed fulltime [pw=perwt], vce(cluster statefip year) absorb(statefip year) // neg sig, male (-), age (+), white (+), hispanic (+), adding employment makes the var
    reghdfe newbaby post_mcaid $covars married employed fulltime [pw=perwt], vce(cluster statefip year) absorb(statefip year) //neg, p=0.4, male (-), age (+), white (+), hispanic (+)

    *
    reghdfe nchild post_mcaid $covars married employed fulltime i.has_hinscaid [pw=perwt], vce(cluster statefip year) absorb(statefip year) // neg sig, male (-), age (+), white (+), hispanic (+), adding employment does not
    reghdfe newbaby post_mcaid $covars married employed fulltime [pw=perwt], vce(cluster statefip year) absorb(statefip year) //neg, p=0.4, male (-), age (+), white (+), hispanic (+)
    


end

* set up globals 
*** outcomes, controls, and heterogeneity variables to try 
global outvars has_hcovany has_hinscaid has_hcovpub has_hinsemp nchild newbaby // maybe newparent, maybe: employed incearn fulltime
global covars male age /*race*/ white /*black native asian other*/ any_hispan /* marital status married separated single*/ /*own educ*/ educ_d2 educ_d3 educ_d4 educ_d5 educ_d6 //employed incearn fulltime
global hetvars male any_hispan employed
global empvars employed incearn fulltime uhrswork
*** for tables
global allvars "male age white black native asian other any_hispan married separated single nchild yngch newbaby newparent has_hcovany has_hinsemp has_hcovpub has_hinscaid educ_d2 educ_d3 educ_d4 educ_d5 educ_d6 educ_sp_d2 educ_sp_d3 educ_sp_d4 educ_sp_d5 educ_sp_d6 educ_sp_d7 educ_sp_d8 educ_sp_d9 educ_sp_d10 educ_sp_d11 employed incearn uhrswork fulltime "
global sum_varnames `" "Male" "Age" "Race" "\hspace{0.3cm}  White" "\hspace{0.3cm}  Black" "\hspace{0.3cm}  Native American" "\hspace{0.3cm}  Asian" "\hspace{0.3cm}  Other" "Hispanic origin" "Marital status" "\hspace{0.3cm} Currently married" "\hspace{0.3cm} Separated" "\hspace{0.3cm} Single"  "Number of children" "Age of youngest child" "Has baby age $<$1" "New parent" "Insurance coverage" "\hspace{0.3cm}  Any coverage" "\hspace{0.3cm}  Coverage through employer"  "\hspace{0.3cm}  Public insurance coverage"  "\hspace{0.3cm}  Coverage through Medicaid"  "Educational attainment" "\hspace{0.3cm} Grade $<=$4" "\hspace{0.3cm}  Grades 5--8" "\hspace{0.3cm} Grade 9" "\hspace{0.3cm} Grade 10" "\hspace{0.3cm} Grade 11" "Educational attainment of spouse" "\hspace{0.3cm} Grade $<=$4" "\hspace{0.3cm}  Grades 5--8" "\hspace{0.3cm} Grade 9" "\hspace{0.3cm} Grade 10" "\hspace{0.3cm} Grade 11" "\hspace{0.3cm} Grade 12" "\hspace{0.3cm} 1 year of college" "\hspace{0.3cm} 2 years of college" "\hspace{0.3cm} 4 years of college"  "\hspace{0.3cm} 5$+$ years of college" "Employed" "Earned income" "Usual weekly hours worked" "Full time (40$+$ work hrs)"  "'

global cov_varnames `" "Medicaid expansion*Post" "Male" "Age" "White race" "Hispanic origin"  "Educational attainment" "\hspace{0.3cm} Grade $<=$4" "\hspace{0.3cm}  Grades 5--8" "\hspace{0.3cm} Grade 9" "\hspace{0.3cm} Grade 10" "\hspace{0.3cm} Grade 11" "Currently married" "Employed" "Earned income" "Weekly work hours" "Full time status"  "'


cap program drop storemean
program define storemean
syntax, varname(str) mat(str) restriction(str) tosum(str) [cond(str)]
    qui reg `varname' `restriction' [pw=perwt] , `cond'
    local m = _b[`tosum']
    local sd = _se[`tosum']
    local n = e(N)
    mat `mat' = nullmat(`mat') \ (`m' , `sd', `n')
end

cap program drop storecoeff
program define storecoeff
syntax, mat(str) row(int) cols(str)
    local rb = `row'
    local rp = `rb' + 1
    local rse = `rp' + 1
    * coefficient with stars
    foreach col in `cols' {
        local b = string(`mat'[`rb',`col'], "%12.3fc")
        local pval = string(`mat'[`rp',`col'], "%12.3fc")
        local stars_abs = cond(`pval' < 0.01, "***", cond(`pval' < 0.05, "**", cond(`pval' < 0.1, "*", "")))
        file write sumstat " & `b'`stars_abs'  "
    }
    file write sumstat "\\" _n
    * standard errors
    foreach col in `cols' {
        local se = string(`mat'[`rse',`col'], "%12.3fc")
        file write sumstat " & (`se')  "
    }
    file write sumstat "\\" _n
end