library(shiny)
library(rgdal)
library(sf)
library(raster)
library(landscapemetrics)
library(dplyr)
library(ggplot2)
library(mapview)
library(leaflet)
library(leafsync)


# User interface ----------------------------------------------------------

ui <- fluidPage(
  mapviewOutput(outputId = "map"),
  actionButton(inputId = "go", label = "Compute"),
  plotOutput(outputId = "plot")
)


# Server ------------------------------------------------------------------

server <- function(input, output) {
  
  get_metrics <- eventReactive(input$go, {
    # Read rasters with crop data - to be used directly for landscapemetrics::sample_lsm()
    rst <- list.files(path = ".", pattern = "\\.tif", full.names = TRUE) %>% 
      lapply(FUN = raster)
    
    # Read biogas plant location
    load(file = "biogas.plant.sf.rda")
    pts <- as(biogas.plant.sf, Class = "Spatial")
    
    # Compute landscape metrics of interest
    landscape_metrics_available <- list_lsm(level = "landscape")
    metrics_of_interest <- c("lsm_l_ed", "lsm_l_pd", "lsm_l_shdi")
    
    metrics <- sample_lsm(landscape = rst,
                          y = pts, 
                          shape = "square",
                          size = 2500,
                          what = metrics_of_interest) %>% 
      left_join(y = landscape_metrics_available,
                by = "metric")
    
    return(metrics)
  })
  
  output$plot <- renderPlot({
    metrics <- get_metrics()
    ggplot(data = metrics,
           aes(x = factor(layer),
               y = value)) +
      geom_col(fill = "gray70") +
      facet_wrap(~ name, scales = "free") +
      labs(x = "Scenario") +
      theme_bw()
  })
  
  output$map <- renderMapview({
    # Read polygons with crop data
    polys <- read_sf("AOIParcelsWithInfo.shp")
    
    polys <- polys %>% select(land_cover = LndCvrT,
                              matches("Crops"))
    
    leafsync::sync(
      mapview(polys, zcol = "Crops1"),
      mapview(polys, zcol = "Crops2"),
      mapview(polys, zcol = "Crops3")
    )
  })
}

shinyApp(ui = ui, server = server)