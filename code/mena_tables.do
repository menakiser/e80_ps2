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
    reg_to_mat, depvar(has_hcovany) indvars(post_mcaid male any_hispan married employed) mat(cov)
    
    reghdfe has_hinscaid post_mcaid $covars married $empvars [pw=perwt], vce(cluster statefip year) absorb(statefip year)
    reg_to_mat, depvar(has_hinscaid) indvars(post_mcaid male any_hispan married employed) mat(cov)
    
    reghdfe has_hcovpub post_mcaid $covars married $empvars [pw=perwt], vce(cluster statefip year) absorb(statefip year)
    reg_to_mat, depvar(has_hcovpub) indvars(post_mcaid male any_hispan married employed) mat(cov)
    
    reghdfe has_hinsemp post_mcaid $covars married $empvars [pw=perwt], vce(cluster statefip year) absorb(statefip year) 
    reg_to_mat, depvar(has_hinsemp) indvars(post_mcaid male any_hispan married employed) mat(cov)

    *** other diffs
    cap mat drop expdiff
    reghdfe married post_mcaid $covars [pw=perwt], vce(cluster statefip year) absorb(statefip year)
    reg_to_mat, depvar(married) indvars(post_mcaid male any_hispan married ) mat(expdiff)

    reghdfe employed post_mcaid $covars married [pw=perwt], vce(cluster statefip year) absorb(statefip year)
    reg_to_mat, depvar(employed) indvars(post_mcaid male any_hispan married ) mat(expdiff)

    reghdfe fulltime post_mcaid $covars married [pw=perwt], vce(cluster statefip year) absorb(statefip year)
    reg_to_mat, depvar(fulltime) indvars(post_mcaid male any_hispan married ) mat(expdiff)
    
    reghdfe incearn post_mcaid $covars married [pw=perwt], vce(cluster statefip year) absorb(statefip year)
    reg_to_mat, depvar(incearn) indvars(post_mcaid male any_hispan married ) mat(expdiff)
    

    //store latex summary stats matrix, manually creating to fit desired format
    cap file close sumstat
    file open sumstat using "$od/cov_did.tex", write replace
    file write sumstat "\begin{tabular}{lcccc}" _n
    file write sumstat "\toprule" _n
    file write sumstat "\toprule" _n
    file write sumstat " \multicolumn{5}{c}{Panel A: Insurance coverage } \\" _n
    file write sumstat " Independent Variable & Any insurance & Medicaid & Public insurance & Coverage through \\" _n
    file write sumstat "  & coverage & coverage & coverage &  employer \\" _n
    file write sumstat "  & (1) & (2) & (3) &  (4) \\" _n
    file write sumstat "\midrule " _n 
    
    * store coverage results
    local i = 1
    local rowcount = 1

    while `rowcount' < 15 {
        local varlab: word `i' of $cov_varnames
        * label
        file write sumstat " `varlab'  "
        storecoeff, mat(cov) row(`rowcount') cols(1 2 3 4)
        local rowcount = `rowcount' +3
        local++ i
    }
    file write sumstat "\\" _n
    //store sample size
    forval col = 1/4 {
        local r2_`col' = string(cov[16,`col'], "%12.3fc")
        local n_`col' = string(cov[18,`col'], "%12.0fc")
    }
    file write sumstat "Other employment covariates  & $\checkmark$ & $\checkmark$ & $\checkmark$ & $\checkmark$ \\" _n
    file write sumstat "R-2 & `r2_1' & `r2_2' & `r2_3' & `r2_4' \\" _n
    file write sumstat "Sample size & `n_1' & `n_2' & `n_3' & `n_4' \\" _n

    * divide panels
    file write sumstat "\midrule " _n 
    file write sumstat "\midrule " _n 
    file write sumstat " \multicolumn{5}{c}{Panel B: Other effects of Medicaid expansion} \\" _n
    file write sumstat " Independent Variable & Currently & Employed & Full time & Earned \\" _n
    file write sumstat "  & married &  &  status & income \\" _n
    file write sumstat "  & (1) & (2) & (3) &  (4)  \\" _n
    file write sumstat "\midrule " _n 
    
    * store other changes at the border
    local i = 1
    local rowcount = 1

    while `rowcount' < 12 {
        local varlab: word `i' of $cov_varnames
        * label
        file write sumstat " `varlab'  "
        storecoeff, mat(expdiff) row(`rowcount') cols(1 2 3 4)
        local rowcount = `rowcount' +3
        local++ i
    }
    file write sumstat "\\" _n
    //store sample size
    forval col = 1/4 {
        local r2_`col' = string(expdiff[13,`col'], "%12.3fc")
        local n_`col' = string(expdiff[15,`col'], "%12.0fc")
    }
    file write sumstat "Other employment covariates  & X & X & X & X \\" _n
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
    reg_to_mat, depvar(married) indvars(post_mcaid $covars married) mat(expdiff)

    *** employment 
    reghdfe employed post_mcaid $covars married [pw=perwt], vce(cluster statefip year) absorb(statefip year)
    reg_to_mat, depvar(employed) indvars(post_mcaid $covars married) mat(expdiff)
    reghdfe incearn post_mcaid $covars married [pw=perwt], vce(cluster statefip year) absorb(statefip year)
    reg_to_mat, depvar(incearn) indvars(post_mcaid $covars married) mat(expdiff)
    reghdfe fulltime post_mcaid $covars married [pw=perwt], vce(cluster statefip year) absorb(statefip year)
    reg_to_mat, depvar(fulltime) indvars(post_mcaid $covars married) mat(expdiff)
    reghdfe uhrswork post_mcaid $covars married [pw=perwt], vce(cluster statefip year) absorb(statefip year)
    reg_to_mat, depvar(uhrswork) indvars(post_mcaid $covars married) mat(expdiff)


    //store latex summary stats matrix, manually creating to fit desired format
    cap file close sumstat
    file open sumstat using "$od/expdiff.tex", write replace
    file write sumstat "\begin{tabular}{lccccc}" _n
    file write sumstat "\toprule" _n
    file write sumstat "\toprule" _n
    file write sumstat " Independent Variable & Currently & Employed & Earned & Full time & Weekly \\" _n
    file write sumstat "  & married &  & income &  status & hours \\" _n
    file write sumstat "  & (1) & (2) & (3) &  (4) & (5) \\" _n
    file write sumstat "\midrule " _n 
    
    local i = 1
    local rowcount = 1

    while `rowcount' < 33 {
        local varlab: word `i' of $cov_varnames
        * label
        file write sumstat " `varlab'  "
        if `i' != 6 & `i' != 13 {
            storecoeff, mat(expdiff) row(`rowcount') cols(1 2 3 4 5)
            local rowcount = `rowcount' +3
        }
        if `i'== 6 | `i' == 13  {
            file write sumstat "\\" _n
        }
        local++ i
    }
    file write sumstat "\\" _n
    //store sample size
    forval col = 1/5 {
        local r2_`col' = string(expdiff[34,`col'], "%12.3fc")
        local n_`col' = string(expdiff[36,`col'], "%12.0fc")
        }
    file write sumstat "R-2 & `r2_1' & `r2_2' & `r2_3' & `r2_4' & `r2_5' \\" _n
    file write sumstat "Sample size & `n_1' & `n_2' & `n_3' & `n_4'  & `n_5' \\" _n
    file write sumstat "\bottomrule" _n
    file write sumstat "\bottomrule" _n
    file write sumstat "\end{tabular}"
    file close sumstat



    /*****************************************************
    Table 4: Childbearing
    ******************************************************/
    use "$dd/ps2_working_data" , clear 

    **** number of children 
    cap mat drop matnch
    * including married as covariates
    reghdfe nchild post_mcaid $covars married  [pw=perwt], vce(cluster statefip year) absorb(statefip year) 
    reg_to_mat, depvar(nchild) indvars(post_mcaid has_hinscaid ) mat(mA)
    reghdfe nchild post_mcaid has_hinscaid $covars married  [pw=perwt], vce(cluster statefip year) absorb(statefip year) 
    reg_to_mat, depvar(nchild) indvars(post_mcaid has_hinscaid ) mat(mA)
    * including married and employment behavior as covariates
    reghdfe nchild post_mcaid $covars married $empvars [pw=perwt], vce(cluster statefip year) absorb(statefip year) 
    reg_to_mat, depvar(nchild) indvars(post_mcaid has_hinscaid ) mat(mA)
    reghdfe nchild post_mcaid has_hinscaid $covars married $empvars [pw=perwt], vce(cluster statefip year) absorb(statefip year) 
    reg_to_mat, depvar(nchild) indvars(post_mcaid has_hinscaid ) mat(mA)

    **** new babies
    cap mat drop matnew
    * including married as covariates
    reghdfe newbaby post_mcaid $covars married  [pw=perwt], vce(cluster statefip year) absorb(statefip year) 
    reg_to_mat, depvar(newbaby) indvars(post_mcaid has_hinscaid ) mat(mB)
    reghdfe newbaby post_mcaid has_hinscaid $covars married  [pw=perwt], vce(cluster statefip year) absorb(statefip year) 
    reg_to_mat, depvar(newbaby) indvars(post_mcaid has_hinscaid ) mat(mB)
    * including married and employment behavior as covariates
    reghdfe newbaby post_mcaid $covars married $empvars [pw=perwt], vce(cluster statefip year) absorb(statefip year) 
    reg_to_mat, depvar(newbaby) indvars(post_mcaid has_hinscaid ) mat(mB)
    reghdfe newbaby post_mcaid has_hinscaid $covars married $empvars [pw=perwt], vce(cluster statefip year) absorb(statefip year) 
    reg_to_mat, depvar(newbaby) indvars(post_mcaid has_hinscaid ) mat(mB)


    //store latex summary stats matrix, manually creating to fit desired format
    cap file close sumstat
    file open sumstat using "$od/child_did.tex", write replace
    file write sumstat "\begin{tabular}{lcccc}" _n
    file write sumstat "\toprule" _n
    file write sumstat "\toprule" _n

    local p = 1
    foreach mname in A B {
        local i = 1
        local rowcount = 1
        local outlab: word `p' of $outlabs
        file write sumstat " \multicolumn{5}{c}{Panel `mname': `outlab' } \\" _n
        file write sumstat " Independent Variable & (1) & (2) & (3) &  (4) \\" _n
        file write sumstat "\midrule " _n 

        while `rowcount' < 6 {
            local varlab: word `i' of $childd
            * label
            file write sumstat " `varlab'  "
            storecoeff, mat(m`mname') row(`rowcount') cols(1 2 3 4)
            local rowcount = `rowcount' +3
            local++ i
        }
        file write sumstat "\\" _n
        file write sumstat "Employment covariates  &  &  & X & X \\" _n
        //store sample size
        forval col = 1/4 {
            local r2_`col' = string(m`mname'[7,`col'], "%12.3fc")
            local n_`col' = string(m`mname'[9,`col'], "%12.0fc")
            }
        file write sumstat "R-2 & `r2_1' & `r2_2' & `r2_3' & `r2_4' \\" _n
        file write sumstat "Sample size & `n_1' & `n_2' & `n_3' & `n_4' \\" _n


        file write sumstat "\midrule" _n
        file write sumstat "\midrule" _n
        local++ p
    }

    file write sumstat "\bottomrule" _n
    file write sumstat "\end{tabular}"
    file close sumstat




    
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
global cov_varnames `" "Medicaid expansion*Post" "Male" "Hispanic origin" "Currently married" "Employed"  "'

global childd `" "Medicaid expansion*Post" "Has Medicaid coverage" "'
global outlabs`" "Number of children" "New baby" "'

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
        if `mat'[`rb',`col'] != 9999 {
            local b = string(`mat'[`rb',`col'], "%12.3fc")
            local pval = string(`mat'[`rp',`col'], "%12.3fc")
            local stars_abs = cond(`pval' < 0.01, "***", cond(`pval' < 0.05, "**", cond(`pval' < 0.1, "*", "")))
            file write sumstat " & `b'`stars_abs'  "
        }
        if `mat'[`rb',`col'] == 9999 {
            file write sumstat " &  "
        }
    }
    file write sumstat "\\" _n
    * standard errors
    foreach col in `cols' {
        if `mat'[`rb',`col'] != 9999 {
            local se = string(`mat'[`rse',`col'], "%12.3fc")
            file write sumstat " & (`se')  "
        }
        if `mat'[`rb',`col'] == 9999 {
            file write sumstat " &   "
        }
    }
    file write sumstat "\\" _n
end

cap program drop reg_to_mat
program reg_to_mat
	syntax, mat(str) indvars(str) depvar(str) 
	capture matrix drop `tab'temp
	local vars_inreg : colfullnames e(b) 
	foreach tab in `mat' {
		tempvar mean_sample
		gen `mean_sample' = e(sample) 
		foreach k in `indvars' {	
			local ind = 0
			foreach var in `vars_inreg' {
				if "`k'" == "`var'" {
					local ind = `ind'+1
				}
		}
		
		if `ind'>0 {
			local b = _b[`k']
			local se = _se[`k']
			local t = _b[`k'] / _se[`k']
			local pval =  2*ttail(e(df_r), abs(`t'))
			mat `tab'temp = nullmat(`tab'temp) \ `b' \ `pval' \ `se'
			replace `mean_sample' =0 if `k'==1
		}
		else {
			mat `tab'temp = nullmat(`tab'temp) \ 9999 \ 9999 \ 9999
		}
		}
		
		local reg_sample = e(N)
		local rsquared =  e(r2) 
		local Fstat = e(F)
		quietly sum `depvar' if `mean_sample'==1
		local untreated_mean = r(mean)
		mat `tab'temp = nullmat(`tab'temp) \ `rsquared'\ `untreated_mean'\ `reg_sample' \ `Fstat'
		
		mat `tab' = nullmat(`tab') , `tab'temp
		
		matrix drop `tab'temp
		drop `mean_sample'
	}
end