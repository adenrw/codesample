cd "C:\Users\Andrew Conroy\Dropbox\691H Personal\Final Folder"
use "codesample", clear

******************************************************
*			Estimation Setup
******************************************************
// Create Policy Timeline in Months 
gen mline=yrmon-tm(2021m10)
replace mline=. if abs(mline)>18
label var mline "Months Since Ban"

// Policy timeline in quarters 
recode mline -18/-16=1 -15/-13=2 -12/-10=3 -9/-7=4 -6/-4=5 -3/-1=6 0=7 1/3=8 4/6=9 7/9=10 10/13=11, gen(qline)
label define qline 1 "-6" 2 "-5" 3 "-4" 4 "-3" 5 "-2" 6 "-1" 7 "0" 8 "1" 9 "2" 10 "3" 11 "4", modify 
label values qline qline
label var qline "Quarters Since Ban"

// Define Treatment Variable
gen treatcounty=postban*demandresp if qline<.

// Set Control Vectors 
global X "mining lngdpcap lninccap popestimate1000 i.urbantype i.econtype pctminority UR"
global Z "mining_freq lngdpcap lninccap popestimate1000 i.urbantype i.econtype pctminority UR"
global W "weather1 weather2 weather3"

******************************************************
*					Base DiD Models
******************************************************

// Base Model with Year-Month FE's
reghdfe lnconsum treatcounty $X $W, absorb(statefip yrmon) vce(cluster statefip) 
outreg2 using indicmine.xls

reghdfe lnconsum treatcounty $Z $W, absorb(statefip yrmon) vce(cluster statefip) 
outreg2 using ctsmine.xls

note: We see that the indicator for mining locations is significant, while the continuous measure of locations is insignificant. As such, further models will use the indicator. 

// Generate log of Outages by Time of Day
gen lnconsum0=ln(consum_hr0+1)
gen lnconsum12=ln(consum_hr12+1)
label var lnconsum0 "Log of Hours Lost (12am-6am)"
label var lnconsum12 "Log of Hours Lost (12pm-6pm)"

// Estimate Model by Time of Day
reghdfe lnconsum0 treatcounty $X $W, absorb(statefip qline) vce(cluster statefip)
outreg2 using midnight.xls

reghdfe lnconsum12 treatcounty $X $W, absorb(statefip qline) vce(cluster statefip)
outreg2 using noon.xls

******************************************************
*				Assumption Testing
******************************************************

// Parallel Trends Testing
didregress (lnconsum $X $W) (treatcounty), group(statefip) time(qline)
estat trendplots, xlabel(1 "-6" 2 "-5" 3 "-4" 4 "-3" 5 "-2" 6 "-1" 7 "0" 8 "1" 9 "2" 10 "3" 11 "4") name(partrends)
estat ptrends

// Testing if there is an effect in anticipation
didregress (lnconsum $X $W) (treatcounty), group(statefip) time(qline)
estat granger

******************************************************
*			IPW Balancing							
******************************************************

qui reg lnconsum treatcounty $X $W, robust
gen sample=1 if e(sample)==1
foreach v in urbantype econtype {
	tab `v', gen(`v'_)
	drop `v'_1
}
global F "lngdpcap lninccap popestimate1000 urbantype_2 urbantype_3 urbantype_4 econtype_2 econtype_3 econtype_4 econtype_5 weather1 weather2 weather3 UR pctminority"

// T-test for unadjusted mean difference in pre-treatment period
pstest $F if sample==1 & postban==0, raw t(demandresp) label 

// T-test for adjusted mean difference
gen _t=lnconsum if postban==0
egen pre_lnconsum=mean(_t), by(countyfip)
probit demandresp pre_lnconsum $F if sample==1 & postban==0
predict pscore
gen ipw=1/pscore if demandresp==1
replace ipw=1/(1-pscore) if demandresp==0
sum ipw, d

matrix Mean=.,.,.,.
foreach v in $F {
	qui sum `v' if sample==1 & demandresp==0 & postban==0
	mat mean0=r(mean)
	qui sum `v' if sample==1 & demandresp==1 & postban==0
	mat mean1=r(mean)
	qui reg `v' demandresp if sample==1 & postban==0
	mat p_unadj=r(table)[4,1]
	qui reg `v' demandresp if sample==1 & postban==0 [pw=ipw]
	mat p_ipw=r(table)[4,1]
	matrix Mean=Mean\mean1,mean0,p_unadj,p_ipw
}
mat colnames Mean = Treated Control p-Unadjusted p-IPW
mat rownames Mean = . $F
mat list Mean

// DID with IPW
reghdfe lnconsum treatcounty $X $W [pw=ipw], absorb(statefip qline) vce(cluster statefip) 
