# codesample
Sample of Code and Data from Senior Honors Thesis 

The .do file and data in this repository are samples from my honors thesis project. The project analyzes how demand response programs can be used in electrical grids to mitigate the impacts of cryptocurrency miners, specifically looking at China's 2021 crypto ban which resulted in a mass migration of miners out of China. 

The .do file performs the following actions:

    1) Generates and edits a timeline variable describing the amount of time since/until ban announcement
    
    2) Defines a treatment variable & establishes control vectors
    
    3) Estimates multiple difference in differences models and outputs the results into an excel files
    
    4) Tests the parallel trends and conditional independence assumptions of the DiD framework
    
    5) Balances treatment and control groups by observed characteristics using Inverse Propensity Weighting
    
    6) Estimates a DiD model using the inverse propensity weights
    
