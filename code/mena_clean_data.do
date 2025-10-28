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
gen married = inlist(marst, 1, 2)
gen separated = inlist(marst, 3)
gen single = inlist(marst, 4, 5, 6) //to change depending on specification
gen white = race==1
gen black = race==2
gen native = race==3
gen asian = inlist(race, 4, 5, 6)
gen other = inlist(race, 7, 8, 9)
gen hispan_sum = hispan!=0
gen employed = empstat==1
//note: no identifying variables: no serial and pernum
//incearn is bottom coded at -$9,999



