# Transportation Pricing App
This exercise uses Shiny to create an application that is intended to be used by a network provider that contracts work to several smaller transportation providers. The data used in this exercise has been created, and can be seen in both the global.R and server.R files. 

Within the Shiny App is a linear model which provides a suggested transportation rate based on historical information. This response variable is calculated by the sum of the estimated fuel cost + hourly rate of driver + mileage surcharge. We then factor in a network fee for allowing the transportation provider to use the network provider's platform. This is calculated as a percentage of the predicted value, which is then deducted from the output of the linear model, and results in the final suggested transportation rate. 

The Shiny App allows the user to generate suggested transportation rates given a set of predictor variables, as well as see the coefficient values so the pricing model can easily be replicated elsewhere. The performance of the model's fit can also be viewed using both summary statistics and visualizations. 

The final product of the model can be seen [here](http://cransford-shiny.shinyapps.io/transportation_pricing_app/).
