/**************************************************************************/
/*									 INFO			  				 		 															*/
/**************************************************************************/

/*

DO FILE
	Purpose: De-identify data by creating a random unique ID
	Created: 15 March by Julia Clark
	Inputs: "survey_data_restricted.csv"
	Outputs: "id_map.dta", "survey_data_public.dta"
*/


/*************************************************************************/
/*									SETUP					  				  													 */
/*************************************************************************/

	clear all
	
* capture cd is great when you're collaborating, as you can add multiple cd's 
* and it will pick the right one, so you don't have to keep changing the code!
	
	capture cd "~/Documents/RA/India_BITSS"

	insheet using "survey_data_restricted.csv"
	
/*************************************************************************/
/*							PSEUDONYMIZE ID NUMBER					  				  												 */
/*************************************************************************/

* Set seed for randomization - CENSOR THIS when sharing code if used to de-identify  
	set seed 92103

* Summarize data 
	table village, contents(sum female) by(age) concise
	
/*Looks like each village-age group only has a few women, possible issue for 
	indirect identifiers if we're tracking other sensitive data */ 

* Create a random pseudo ID number for each participant
    gen double random=uniform()
    sort random
    gen random_id=_n

* Drop non-ID columns
	keep personal_id random_id
	
* Save the map of pseudo_IDs to personal IDs
    save "id_map.dta", replace

* In the restricted data file, merge in new random ID numbers, drop old ID 
	insheet using "survey_data_restricted.csv", clear
    sort personal_id
    merge m:1 personal_id using "id_map.dta"
    assert _merge==3
    drop _merge personal_id
    sort random_id
    order random_id

/*************************************************************************/
/*							ADD RANDOM NOISE					  				  												 */
/*************************************************************************/

* Set noise range to be added
	gen random = round(runiform(-5, 5))
	
* Create new variable that adds noise to each value of age	
	gen noisy_age = age + random
	
* Make a new table
	table village, contents(sum female) by(noisy_age) concise
	
* Hmmm, this didn't really help with our k-anonymity ...  

/*************************************************************************/
/*							REDUCE INFORMATION					  				  												 */
/*************************************************************************/	

* Create new, binned age variable
	egen age_range = cut(age), at(18,40,60,80,100)
	lab define age_ranges 18 "18-40" 40 "40-60" 60 "60-80" 80 "over 80"
	lab values age_range age_ranges
	
	egen age_range = cut(age), at(18,40,60,80,100) label
	table(age_range)

* Make table again	
	table village, contents(sum female) by(age_range) concise

* Better! But we're loosing lots of information 	



	
