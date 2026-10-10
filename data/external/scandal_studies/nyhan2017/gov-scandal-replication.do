/*Replication file for "Media Scandals are Political Events"*/

*requires estout (https://ideas.repec.org/c/boc/bocode/s439301.html) and rd (https://ideas.repec.org/c/boc/bocode/s456888.html)
*created with Stata 14.2 (11/15/16) by Brendan Nyhan

clear
set more off
cd "/Users/bnyhan/Documents/Dropbox/Katie research/Replication/"

***************
*GOV-YEAR DATA*
***************

use "gov-year-replication.dta", clear

/*Appendix: Summary statistics for Tables 1 and 2*/
su aponset apscandalcount lagpospct divgov oppag commission electionyear years1 years2 loglag fullyear disaster indisaster

/*Table 1*/
clogit aponset lagpospct divgov oppag commission electionyear years1 years2 loglag fullyear i.yeardummies,cluster(statenum) group(statenum)
est store A

areg aponset lagpospct divgov oppag commission electionyear years1 years2 loglag fullyear i.yeardummies,cluster(statenum) absorb(statenum)
est store B

areg aponset lagpospct divgov oppag commission electionyear years1 years2 loglag fullyear i.yeardummies,cluster(govid2) absorb(statenum)
est store C

areg apscandalcount lagpospct divgov oppag commission electionyear years1 years2 loglag fullyear i.yeardummies,cluster(statenum) absorb(statenum)
est store D

areg apscandalcount lagpospct divgov oppag commission electionyear years1 years2 loglag fullyear i.yeardummies,cluster(govid2) absorb(statenum)
est store E

xtnbreg apscandalcount lagpospct divgov oppag commission electionyear years1 years2 loglag fullyear i.yeardummies, fe vce(boot,reps(1000) seed(10101)) iter(50)
est store F

estout A B C D E F, label style(tex) replace varwidth(25) collabels("") cells(b(star fmt(%9.3f)) se(par fmt(%9.3f))) stats(r2 N, fmt(%9.2f %9.0f) labels("R$^{2}$" "N")) starlevels(* 0.10 ** 0.05 *** 0.01) 

/*Table 2*/
areg aponset lagpospct divgov oppag commission electionyear years1 years2 loglag fullyear i.yeardummies disaster indisaster,cluster(statenum) absorb(statenum)
est store G

areg aponset lagpospct divgov oppag commission electionyear years1 years2 loglag fullyear i.yeardummies disaster indisaster,cluster(govid2) absorb(statenum)
est store H

areg apscandalcount lagpospct divgov oppag commission electionyear years1 years2 loglag fullyear i.yeardummies disaster indisaster,cluster(statenum) absorb(statenum)
est store I

areg apscandalcount lagpospct divgov oppag commission electionyear years1 years2 loglag fullyear i.yeardummies disaster indisaster,cluster(govid2) absorb(statenum)
est store J

xtnbreg apscandalcount lagpospct divgov oppag commission electionyear years1 years2 loglag fullyear i.yeardummies disaster indisaster, fe vce(boot,reps(1000) seed(10101))
est store K

estout G H I J K, label style(tex) replace varwidth(25) collabels("") cells(b(star fmt(%9.3f)) se(par fmt(%9.3f))) stats(r2 N, fmt(%9.2f %9.0f) labels("R$^{2}$" "N")) starlevels(* 0.10 ** 0.05 *** 0.01) 

/*Figure 1*/
count
local obs=r(N)
local newobs=`obs'+30
set obs `newobs'
gen predeff=_n>`obs'

replace years1=4 if _n>`obs' /*median*/
replace years2=16 if _n>`obs' /*median*/
replace lagpospct=.4+((_n-`obs'-1)*.01) if _n>`obs' /*mean*/
list lagpos if _n>`obs'
replace divgov=1 if _n>`obs' /*mode*/
replace oppag=0 if _n>`obs' /*mode*/
replace commission=1 if _n>`obs' /*mode*/
replace electionyear=1 if _n>`obs' /*mode*/
replace loglag=3.938616 if _n>`obs' /*mean*/
replace fullyear=1 if _n>`obs'
tab year,gen(y)
forval i=2/34 {
replace y`i'=0 if _n>`obs'
}
replace y24=1 if _n>`obs'
replace disaster=0 if _n>`obs'
replace statenum=17 if _n>`obs'

clogit aponset lagpospct divgov oppag commission electionyear years1 years2 loglag fullyear y2-y34,cluster(statenum) group(statenum)
predict prob1,pu0 /*assumes fixed effect = 0, otherwise probability of success given one success within group per Stata manual*/

sort lagpospct
twoway (line prob1 lagpospct if predeff==1,lcolor(black) ytitle("Predicted probability of media scandal onset",size(*1)) xtitle("Approval rating (lag)",size(*1)) legend(off) graphregion(fcolor(white) lcolor(white) ifcolor(white) ilcolor(white)) plotregion(fcolor(white) lcolor(white) ifcolor(white) ilcolor(white)) ymtick(.05(.1).4) ylabel(0(.1).4,angle(0)) xlabel(.40 "40%" .50 "50%" .60 "60%" .7 "70%") xmtick(.35(.1).55) ylabel(,nogrid labsize(*1)) xlab(,labsize(*1))) (scatter prob1 lagpospct if (predeff==1 & lagpospct>.395 & lagpospct<.405) | (predeff==1 & lagpospct>.685 & lagpospct<.695),legend(off) mcolor(black) msymbol(circle))


**********************************
*GOV-SESSION: CLOSE GOV VOTE DATA*
**********************************

use "Replication/gov-vote-session.dta", clear

/*Appendix: Balance tests for governor vote*/
foreach var of varlist monthsinoffice months agvote pres_vote_gov_party {
ttest `var' if opp_gov_vote>=.4 & opp_gov_vote<=.6, by(oppgov) unequal
}

/*Table 3(a)*/
rd aponset opp_gov_vote if opp_gov_vote>=.4 & opp_gov_vote<=.6,z0(.5)
rd aponset opp_gov_vote if opp_gov_vote>=.3 & opp_gov_vote<=.7,z0(.5)

rd apscandalcount opp_gov_vote if opp_gov_vote>=.4 & opp_gov_vote<=.6,z0(.5)
rd apscandalcount opp_gov_vote if opp_gov_vote>=.3 & opp_gov_vote<=.7,z0(.5)

/*Appendix: Figure A1(a)-A1(b)*/
gen round=floor(opp_gov_vote*100)
gen midround2=(round/100)+.005
foreach var of varlist aponset apscandalcount {
bysort round: egen mean`var'=mean(`var')
}

twoway (lpolyci aponset opp_gov_vote if opp_gov_vote>=.4 & opp_gov_vote<.5, ciplot(rline) lcolor(black) alcolor(black) alpattern(dash) pstyle(ci2) degree(0)) (lpolyci aponset opp_gov_vote if opp_gov_vote>.5 & opp_gov_vote<=.6, ciplot(rline) lcolor(black) alcolor(black) alpattern(dash) pstyle(ci2) degree(0) graphregion(fcolor(white) ifcolor(none)) plotregion(fcolor(none) lcolor(white) ifcolor(none) ilcolor(none)) legend(off) ytitle("") xtitle("Vote share of gubernatorial candidate from party opposing A.G.") scheme(s1mono)) (scatter meanaponset midround2 if opp_gov_vote>=.4 & opp_gov_vote<=.6,msymbol(Oh) color(gs12) xline(0.5, lcolor(gs8) lpattern(dash)))

twoway (lpolyci apscandalcount opp_gov_vote if opp_gov_vote>=.4 & opp_gov_vote<.5,  ciplot(rline) lcolor(black) alcolor(black) alpattern(dash) pstyle(ci2) degree(0)) (lpolyci apscandalcount opp_gov_vote if opp_gov_vote>.5 & opp_gov_vote<=.6, ciplot(rline) lcolor(black) alcolor(black) alpattern(dash) pstyle(ci2) degree(0) graphregion(fcolor(white) ifcolor(none)) plotregion(fcolor(none) lcolor(white) ifcolor(none) ilcolor(none)) legend(off) ytitle("") xtitle("Vote share of gubernatorial candidate from party opposing A.G.") scheme(s1mono)) (scatter meanapscandalcount midround2 if opp_gov_vote>=.4 & opp_gov_vote<=.6,msymbol(Oh) color(gs12) xline(0.5, lcolor(gs8) lpattern(dash)) yscale(r(-.5 6)) ylabel(0(2)6) ymtick(1(2)5))


*********************************
*GOV-SESSION: CLOSE AG VOTE DATA*
*********************************

use "Replication/ag-gov-session.dta", clear

/*Appendix: Balance tests for AG vote*/
foreach var of varlist monthsinoffice months gov_vote pres_vote_gov_party {
ttest `var' if voteforoppag>=.4 & voteforoppag<=.6, by(oppag) unequal
}

/*Table 3(b)*/
rd aponset voteforoppag if voteforoppag>=.4 & voteforoppag<=.6,z0(.5)
rd aponset voteforoppag if voteforoppag>=.3 & voteforoppag<=.7,z0(.5)

rd apscandalcount voteforoppag if voteforoppag>=.4 & voteforoppag<=.6,z0(.5)
rd apscandalcount voteforoppag if voteforoppag>=.3 & voteforoppag<=.7,z0(.5)

/*Appendix: Figure A1(c)-A1(d)*/
gen round=floor(voteforoppag*100)
gen midround2=(round/100)+.005

foreach var of varlist aponset apscandalcount {
bysort round: egen mean`var'=mean(`var')
}

twoway (lpolyci aponset voteforoppag if voteforoppag>=.4 & voteforoppag<.5, lcolor(black) ciplot(rline) alcolor(black) alpattern(dash) pstyle(ci2) degree(0)) (lpolyci aponset voteforoppag if voteforoppag>.5 & voteforoppag<=.6, ciplot(rline) lcolor(black) alcolor(black) alpattern(dash) pstyle(ci2) degree(0) graphregion(fcolor(white) ifcolor(none)) plotregion(fcolor(none) lcolor(white) ifcolor(none) ilcolor(none)) legend(off) ytitle("") xtitle("Vote share of A.G. candidate from opposition party") scheme(s1mono)) (scatter meanaponset midround2 if voteforoppag>=.4 & voteforoppag<=.6,msymbol(Oh) color(gs12) xline(0.5, lcolor(gs8) lpattern(dash)))

twoway (lpolyci apscandalcount voteforoppag if voteforoppag>=.4 & voteforoppag<.5, ciplot(rline) lcolor(black) alcolor(black) alpattern(dash) pstyle(ci2) degree(0)) (lpolyci apscandalcount voteforoppag if voteforoppag>.5 & voteforoppag<=.6, ciplot(rline) lcolor(black) alcolor(black) alpattern(dash) pstyle(ci2) degree(0) graphregion(fcolor(white) ifcolor(none)) plotregion(fcolor(none) lcolor(white) ifcolor(none) ilcolor(none)) legend(off) ytitle("") xtitle("Vote share of A.G. candidate from opposition party") scheme(s1mono)) (scatter meanapscandalcount midround2 if voteforoppag>=.4 & voteforoppag<=.6,msymbol(Oh) color(gs12) xline(0.5, lcolor(gs8) lpattern(dash)) yscale(r(-.5 6)) ylabel(0(2)6) ymtick(1(2)5))


***********************************
*GOV-SESSION: CLOSE LEG SEATS DATA*
***********************************

use "Replication/leg-gov-session.dta", clear

/*Appendix: Balance tests for legislative seats*/
foreach var of varlist monthsinoffice months gov_vote pres_vote_gov_party legprof {
ttest `var' if minmargin<=.2 & minmargin>=-.2 & split==0, by(divgov) unequal 
}

/*Table 4*/
rd aponset minmargin if minmargin<=.2 & minmargin>=-.2 & split==0
rd aponset minmargin if minmargin<=.3 & minmargin>=-.3 & split==0

rd apscandalcount minmargin if minmargin<=.2 & minmargin>=-.2 & split==0
rd apscandalcount minmargin if minmargin<=.3 & minmargin>=-.3 & split==0

/*Appendix: Figure A2*/
gen mmbin=(2*round((minmargin*100)/2))/100
foreach var of varlist aponset apscandalcount {
bysort mmbin: egen mean`var'=mean(`var')
}

twoway(lpolyci aponset minmargin if minmargin<=0 & minmargin>=-.2 & divgov==0 & split==0, ciplot(rline) lcolor(black) alcolor(black) alpattern(dash) pstyle(ci2) degree(0)) (lpolyci aponset minmargin if minmargin>=0 & minmargin<=.2 & divgov==1 & split==0, ciplot(rline) lcolor(black) alcolor(black) alpattern(dash) pstyle(ci2) degree(0) graphregion(fcolor(white) ifcolor(none)) plotregion(fcolor(none) lcolor(white) ifcolor(none) ilcolor(none)) xlabel(-.2(.1).2) xmtick(-.15(.1).15) legend(off) ytitle("") /*title("Probability scandal (AP)")*/ xtitle("Opposition margin for div. govt. (seat share)") scheme(s1mono) xline(0, lcolor(gs12) lpattern(dash))) (scatter meanaponset mmbin if minmargin<=.2 & minmargin>=-.2 & split==0,msymbol(Oh) color(gs12))

twoway(lpolyci apscandalcount minmargin if minmargin<=0 & minmargin>=-.2 & divgov==0 & split==0, ciplot(rline) lcolor(black) alcolor(black) alpattern(dash) pstyle(ci2) degree(0)) (lpolyci apscandalcount minmargin if minmargin>=0 & minmargin<=.2 & divgov==1 & split==0, ciplot(rline) lcolor(black) alcolor(black) alpattern(dash) pstyle(ci2) degree(0) graphregion(fcolor(white) ifcolor(none)) plotregion(fcolor(none) lcolor(white) ifcolor(none) ilcolor(none)) xlabel(-.2(.1).2) xmtick(-.15(.1).15) legend(off) ytitle("") /*title("Average scandal coverage (AP)")*/ xtitle("Opposition margin for div. govt. (seat share)") scheme(s1mono) xline(0, lcolor(gs8) lpattern(dash))) (scatter meanapscandal mmbin if minmargin<=.2 & minmargin>=-.2 & split==0,msymbol(Oh) color(gs12) ylabel(0(2)8) ymtick(1(2)7))
