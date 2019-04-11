library(shiny)
library(ggplot2)
library(data.table)
library(dplyr)

function(input, output){
  
  laborCost <- reactive({
    tempLabor <- staticDf
    tempLabor$labor_revenue = round((tempLabor$loaded_time/60) * input$labor_rate)
    tempLabor$total_cost = tempLabor$labor_revenue + tempLabor$fuel_cost
    tempLabor
  })
  
  
  driverRate <- reactive({
    tempRate <- laborCost()
    tempRate$ideal_rate <- ifelse(tempRate$specialty_equipment == 0, round(tempRate$total_cost+(input$mile_rate*tempRate$loaded_miles),2),
                                  round(tempRate$total_cost+(input$mile_rate*(tempRate$loaded_miles+2)),2))
    tempRate$specialty_equipment <- factor(tempRate$specialty_equipment, levels=c(0,1))
    tempRate
  })
  
  noShowRate <- reactive({
    tempShow <- driverRate()
    tempShow$customer_present <- rbinom(n=10000, size=1, prob=1-input$no_shows)
    tempShow
  })
  
  lmModel <- reactive({
    tempModelDf <- noShowRate()
    tempModel <- lm(ideal_rate ~ loaded_miles + specialty_equipment + town, data = tempModelDf) # num_customers + loaded_time + 
    tempModel
  })
  
  predictDf <- reactive({
    tempPredict <- noShowRate()
    tempModel2 <- lmModel()
    tempPredict$predicted_rate <- round(predict(tempModel2),2)
    tempPredict$error <- round(tempPredict$ideal - tempPredict$predicted_rate,2)
    tempPredict
  })
  
  marginDf <- reactive({
    tempMargin <- predictDf()
    tempMargin$adj_driver_prediction <- round(tempMargin$predicted_rate*(1-input$circulation_fee),2)
    tempMargin$circulation_margin <- round(tempMargin$predicted_rate*input$circulation_fee,2)
    tempMargin$driver_margin <- round((tempMargin$adj_driver_prediction * tempMargin$customer_present)-tempMargin$fuel_cost)
    tempMargin
  })
  
  
  errorDf <- reactive({
    tempError <- marginDf()
    summError <- setDT(tempError)[,
                                  list(
                                    me = round(mean(error),2),
                                    mae = round(mean(abs(error)),2),
                                    sigma = round(sd(error),2)
                                  )]
    summError
  })
  
  #### Begin creatuing reactive output objects
  output$ME <- renderText({
    tempOutputMAE <- errorDf()
    tempOutputMAE$me
  })
  
  output$MAE <- renderText({
    tempOutputMAE <- errorDf()
    tempOutputMAE$mae
  })
  
  output$sigma <- renderText({
    tempOutputMAE <- errorDf()
    tempOutputMAE$sigma
  })
  
  output$b0_coef <- renderPrint({
    tempoutputB0 <- lmModel()
    paste(summary(tempoutputB0)$coefficients[1], collapse = '\n') %>% cat()
  })
  
  output$loaded_miles <- renderPrint({
    tempoutputLm <- lmModel()
    paste(tempoutputLm$coefficients['loaded_miles'][[1]], collapse = '\n') %>% cat()
  })
  
  output$specialty_equipment <- renderPrint({
    tempOutputSE <- lmModel()
    paste(tempOutputSE$coefficients['specialty_equipment1'][[1]], collapse = '\n') %>% cat()
  })
  
  output$arlington <- renderPrint({
    tempMoldelArlington <- lmModel()
    paste(tempMoldelArlington$coefficients['townARLINGTON'][[1]], collapse = '\n') %>% cat()
  })
  
  output$deep_ellum <- renderPrint({
    tempMoldelDeepellum <- lmModel()
    paste(tempMoldelDeepellum$coefficients['townDEEP_ELLUM'][[1]], collapse = '\n') %>% cat()
  })
  
  output$downtown <- renderPrint({
    tempMoldelDowntown <- lmModel()
    paste(tempMoldelDowntown$coefficients['townDOWNTOWN'][[1]], collapse = '\n') %>% cat()
  })
  
  output$uptown <- renderPrint({
    tempMoldelUptown <- lmModel()
    paste(tempMoldelUptown$coefficients['townUPTOWN'][[1]], collapse = '\n') %>% cat()
  })
  
  sim_monthly_trips <- reactive({
    input$num_monthly_trips
  })
  
  simulation_df <- reactive({
    tempSimModel1 <- lmModel()
    newData <- data.frame(loaded_miles = input$loaded_miles_in,
                          town = input$town_in,
                          specialty_equipment = as.factor(input$specialty_equipment_in))
    predictOutput <- round(predict(tempSimModel1, newData),2)
    predictOutput
  })
  
  output$single_driver_rate <- renderPrint({
    temp_single_driver <- simulation_df()
    temp_single_driver <- round(temp_single_driver*(1-input$circulation_fee),2)
    paste(temp_single_driver, collapse = '\n') %>% cat()
  })
  
  output$single_circulation_rate <- renderPrint({
    temp_single_circ <- simulation_df()
    temp_single_circ <- round(temp_single_circ*input$circulation_fee,2)
    paste(temp_single_circ, collapse = '\n') %>% cat()
  })
  
  output$monthly_driver_rate <- renderPrint({
    temp_monthly_driver <- simulation_df()
    temp_monthly_trips1 <- sim_monthly_trips()
    temp_monthly_driver <- round(temp_monthly_driver*(1-input$circulation_fee),2)*(temp_monthly_trips1*(1-input$no_shows))
    paste(temp_monthly_driver, collapse = '\n') %>% cat()
  })
  
  output$monthly_circulation_rate <- renderPrint({
    temp_monthly_circ <- simulation_df()
    temp_monthly_trips2 <- sim_monthly_trips()
    temp_monthly_circ <- round(temp_monthly_circ*input$circulation_fee,2)*(temp_monthly_trips2*(1-input$no_shows))
    paste(temp_monthly_circ, collapse = '\n') %>% cat()
  })
  
  
  
  # Create reactive visualizations 
  output$residualRatePlot <- renderPlot({
    tempModel1 <- lmModel()
    ggplot(tempModel1) + 
      geom_point(aes(x=.fitted, y=.resid)) + 
      geom_smooth(method="gam", aes(x=.fitted, y=.resid), se=FALSE) + 
      labs(x="Fitted Values", y="Residual Values")
  })
  
  output$residualCostPlot <- renderPlot({
    tempoutputResidCost <- predictDf()
    if(input$graph_in %in% c("loaded_time", "loaded_miles")){ 
      g <- ggplot(tempoutputResidCost, aes(x=input$graph_in, y=error)) +
        geom_jitter() +
        labs(y="Prediction Error ($)", x=input$graph_in)
      g
    } else {
      g <- ggplot(tempoutputResidCost) + 
        aes(y = error) +
        geom_boxplot(aes_string(x=input$graph_in)) + 
        labs(y="Prediction Error ($)", x= input$graph_in)
      g
    }
    g
  })
  
}
