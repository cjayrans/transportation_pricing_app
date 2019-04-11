library(shiny)
library(data.table)

# Use a fluid Bootstrap layout
fluidPage(    
  
  # Give the page a title
  titlePanel("Transportation Provider Pricing Schedules"),
  
  # Generate a row with a sidebar
  sidebarLayout(      
    
    # Define the sidebar with one input
    sidebarPanel(
      h4("This app is intended to be used to help network employees negotiate pricing rates for new and existing drivers within the city of Dallas, TX. Changes to the inputs listed below updates historical data and retrains a linear model, which can then be used to estimate a suggested rate. The user can also obtain the updated coefficient values from the linear model to allow drivers to estimate their expected revenue."),
      br(),
      numericInput("mile_rate", 
                   "Surcharge Per Loaded Mile ($):", 
                   value = 0.50,
                   min = 0,
                   max = 1,
                   step = 0.10),
      h5(div(HTML("<em>Additional revenue driver's will earn per loaded mile.</em>"))),
      numericInput("labor_rate", 
                   "Hourly Labor Rate:",
                   value = 20,
                   min = 10,
                   max=50,
                   step = 5),
      h5(div(HTML("<em>Driver's expected hourly rate.</em>"))),
      numericInput("circulation_fee", "Network Fee:",
                   value = 0.20,
                   min = 0.00,
                   max = 1.00,
                   step=0.02),
      h5(div(HTML("<em>Fee driver must pay network for using their platform. Based on % of expected rider cost, which includes expected fuel and labor costs.</em>"))),
      numericInput("no_shows", "% No Shows:",
                   value = 0.10,
                   min = 0.00,
                   max = 1.00,
                   step=0.02),
      h5(div(HTML("<em>The % of riders not expected to be present. Drivers will still incur cost of fuel, but are not paid their hourly rate or have to pay network's fee.</em>")))
    ),
    
    # Create main panel of Shiny App UI
    mainPanel(
      tabsetPanel(type = "tabs",
                  tabPanel("Simulator",
                           fluidRow(
                             br(),
                             column(4,
                                    sliderInput("loaded_miles_in", "Avg. Miles Per Trip",
                                                min=0, max=30, value=10, step=2, round=0),
                                    sliderInput("num_monthly_trips", "Expected # of Monthly Trips",
                                                min=0, max=100, value=30, step=5, round=0)
                             ),
                             column(4,
                                    selectInput("town_in","Preferred Area",
                                                choices=c("DOWNTOWN","DEEP_ELLUM","UPTOWN","ADDISON","ARLINGTON"),
                                                multiple=FALSE, selected="DOWNTOWN"),
                                    checkboxGroupInput("specialty_equipment_in","Specialty Equipment",
                                                       choices = list("Yes" = 1, "No" = 0),
                                                       selected = 0)
                             ),
                             column(4,
                                    h2("Individual Trip"),
                                    h4("Driver Revenue"),
                                    textOutput("single_driver_rate"),
                                    h4("Network Revenue"),
                                    textOutput("single_circulation_rate"),
                                    br(),
                                    h2("Monthly Projections"),
                                    h4("Driver Revenue"),
                                    textOutput("monthly_driver_rate"),
                                    h4("Network Revenue"),
                                    textOutput("monthly_circulation_rate")
                             )
                           )
                  ),
                  tabPanel("Model Coefficient Values", 
                           fluidRow(
                             h3("B0"),
                             textOutput("b0_coef"),
                             br(),
                             h3("Est. Loaded Miles"),
                             textOutput("loaded_miles"),
                             br(),
                             h3("Specialty Equipment"),
                             textOutput("specialty_equipment")#,
                           ),
                           fluidRow(
                             h3("Arlington"),
                             textOutput("arlington"),
                             h3("Deep Ellum"),
                             textOutput("deep_ellum"),
                             h3("Downtown"),
                             textOutput("downtown"),
                             h3("Uptown"),
                             textOutput("uptown")
                           )
                  ),
                  tabPanel("Model Accuracy",
                           h3("Mean Error"),
                           textOutput("ME"),
                           h3("Mean Absolute Error"),
                           textOutput("MAE"),
                           h3("Standard Deviation of Prediction Errors"),
                           textOutput("sigma"),
                           br(),
                           br(),
                           h3("Residuals vs. Fitted Values"),
                           plotOutput("residualRatePlot", width = "100%"),
                           br(),
                           br(),
                           selectInput("graph_in","Compare residual errors against a selected variable",
                                       choices = c(as.character(c("loaded_time", "loaded_miles", "specialty_equipment", "town"))),
                                       multiple=FALSE, selected="town"),
                           h3("Prediction Errors vs Selected Input"),
                           plotOutput("residualCostPlot", width = "100%"),
                           br()
                  )
      )
    )
  )
  
  
  
)