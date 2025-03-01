---
title: "Costa Rica; casos de covid-19 para el viernes 22 de octubre del 2021"
output: 
  flexdashboard::flex_dashboard:
    theme: cerulean
    social: menu
    source_code: embed
runtime: shiny
---

```{r setup, include=FALSE}
library(flexdashboard)
defaultEncoding <- "UTF8"
library(dplyr)
library(sf)
library(terra)
library(raster)
library(DT)
library(ggplot2)
library(plotly)
library(leaflet)
library(leaflet.extras)
library(leafem)
library(shiny)
library(shinydashboard)
library(shinyWidgets)
library(tidyverse)
```

```{r datos , warning=FALSE, message=FALSE}
casos_p <-
  st_read("/vsicurl/https://marcelocubero.github.io/capas_proyecto/casos.geojson",
          quiet = TRUE)
casos_p <-
  casos_p %>%
  st_transform(4326)
fallecidos <-
  rast("/vsicurl/https://marcelocubero.github.io/capas_proyecto/fallecidos.tif")
lista_provincias <- unique(casos_p$provincia)
lista_provincias <- sort(lista_provincias)
lista_provincias <- c("Todas", lista_provincias)
lista_canton <- unique(casos_p$canton)
lista_canton <- sort(lista_canton)
lista_canton <- c("Todas", lista_canton)
```

Mapa
=====================================

Column {.sidebar}
-----------------------------------------------------------------------
```{r}
h3("Filtros")
h2("Provincias")
selectInput(
  inputId = "provincia",
  label = "Provincia",
  choices = lista_provincias,
  selected = "Todas"
)
h2("Cantones")
selectInput(
  inputId = "canton",
  label = "Cantón",
  choices = lista_canton,
  selected = "Todas"
)
h2("Positivos")
numericRangeInput(
  inputId = "positivos",
  label = "Casos Positivos",
  value = c(1, 52000),
  width = NULL,
  separator = " a ",
  min = 1,
  max =52000,
  step = NA
)
h2("Activos")
numericRangeInput(
  inputId = "activos",
  label = "Casos Activos",
  value = c(1, 7600),
  width = NULL,
  separator = " a ",
  min = 1,
  max = 7600,
  step = NA
)
filtrarRegistros <-  reactive({
  casos_f <-
    casos_p %>%
    dplyr::select(canton, provincia, positivos, activos)
  
casos_f <-
  casos_f %>%
  filter(
    activos >= input$activos[1] &
     activos <= input$activos[2]
  ) 
casos_f <-
  casos_f %>%
  filter(
   positivos >= input$positivos[1] &
    positivos <= input$positivos[2]
  )
  
  if (input$provincia != "Todas") {
    casos_f <-
      casos_f %>%
      filter(provincia == input$provincia)
  }
  
  if (input$canton != "Todas") {
    casos_f <-
      casos_f %>%
      filter(canton == input$canton)
  }
  
  return(casos_f)
})
```


Row {data-height=650}
-----------------------------------------------------------------------

### Mapa de casos de covid-19 en Costa Rica, para el viernes 22 de octubre del 2021

```{r}
fallecidos_rl <- raster::raster(fallecidos)
bins <- c(10, 100, 500, 1000, 4000, 7600)
pal <- colorBin("YlOrBr", domain = casos_p$activos, bins = bins)
bins3 <- c(1, 5000, 10000, 20000, 40000, 52000)
pal3 <- colorBin("Reds", domain = casos_p$positivos, bins = bins3)
at <- seq(1:800)
pal2 <- colorBin('Accent', domain = at , na.color = "transparent")
renderLeaflet({
  registros <-
    filtrarRegistros()
  
  leaflet() %>%
    addTiles(group = "OSM") %>%
    addProviderTiles(providers$Esri.NatGeoWorldMap , group = "NatGeo") %>%
    addProviderTiles(providers$CartoDB.DarkMatter, group = "CartoDB-Black") %>%
    addRasterImage(
      fallecidos_rl,
      opacity = 1,
      group = "Fallecidos",
      colors = pal2
    ) %>%
    addLegend("bottomleft",
              pal = pal2,
              values = at,
              title = "Fallecidos") %>%
    addPolygons(
      data = registros,
      color = "black",
      fillColor = ~ pal(activos),
      fillOpacity = 1,
      weight = 1,
      opacity = 1,
      stroke = TRUE,
      group = "Casos Activos",
      popup = paste0(
        "<strong>Cantón: </strong>",
        casos_p$canton,
        "<br>",
        "<strong>Casos activos: </strong>",
        casos_p$activos
      )
    ) %>%
    addLegend(
      pal = pal,
      values = casos_p$activos,
      opacity = 1,
      title = "Casos Activos"
    ) %>%
    addPolygons(
      data = registros,
      color = "black",
      fillColor = ~ pal3(positivos),
      fillOpacity = 1,
      weight = 1,
      opacity = 1,
      stroke = TRUE,
      group = "Casos Positivos",
      popup = paste0(
        "<strong>Cantón: </strong>",
        casos_p$canton,
        "<br>",
        "<strong>Casos positivos: </strong>",
        casos_p$positivos
      )
    ) %>%
    addLegend(
      pal = pal3,
      values = casos_p$activos,
      opacity = 1,
      title = "Casos Positivos"
    ) %>%
    
    addLayersControl(
      "bottomleft",
      baseGroups = c("OSM", "NatGeo", "CartoDB-Black"),
      overlayGroups = c("Fallecidos", "Casos Activos", "Casos Positivos"),
      options = layersControlOptions(collapsed = TRUE)
    ) %>%
    addScaleBar("bottomright") %>%
    addMiniMap() %>%
    addResetMapButton() %>%
    addFullscreenControl() %>%
    addControlGPS() %>%
    addSearchOSM() %>%
    addMouseCoordinates()
  
})
```


Cuadro {data-orientation=rows}
===================================== 

Row {data-height=350}
-------------------------------------
### Casos activos y positivos por cantón y provincia

```{r}
renderDT({
  registros <- filtrarRegistros()
  
  registros %>%
    st_drop_geometry() %>%
    select(
      Cantón = canton,
      Provincia = provincia,
      Casos_Activos = activos,
      Casos_Positivos = positivos
    ) %>%
    datatable(options = list(
      language = list(url = '//cdn.datatables.net/plug-ins/1.10.11/i18n/Spanish.json')
    ))
  
})
```

Casos positivos por cantón {data-orientation=rows}
===================================== 
Row {data-height=650}
-----------------------------------------------------------------------

### Casos positivos por cantón
```{r}
renderPlotly({
  registros <- filtrarRegistros()
  registros %>%
    st_drop_geometry() %>%
    
    ggplot(aes(x = canton, y = positivos)) +
    geom_col(width = 0.5, fill = "Red") +
    ggtitle("Casos Positivos por cantón") +
    xlab("Cantón") +
    ylab("Cantidad de casos positivos") +
    theme(
      plot.title = element_text(size = 16, face = "bold"),
      text = element_text(size = 8),
      axis.text.x = element_text(
        angle = 90,
        vjust = 0.5,
        hjust = 1
      )
    )
  
})
```

Casos activos por cantón {data-orientation=rows}
===================================== 
Row {data-height=650}
-----------------------------------------------------------------------
### Casos activos por cantón

```{r}
renderPlotly({
  registros <- filtrarRegistros()
  registros %>%
    st_drop_geometry() %>%
    
    ggplot(aes(x = canton, y = activos)) +
    geom_col(width = 0.5, fill = "Brown") +
    ggtitle("Casos Activos por cantón") +
    xlab("Cantón") +
    ylab("Cantidad de casos activos") +
    theme(
      plot.title = element_text(size = 16, face = "bold"),
      text = element_text(size = 8),
      axis.text.x = element_text(
        angle = 90,
        vjust = 0.5,
        hjust = 1
      )
    )
  
})
```


Acerca del Covid-19 {data-orientation=rows}
===================================== 


### Acerca del COVID-19 

La [COVID-19](https://www.who.int/es/news-room/q-a-detail/coronavirus-disease-covid-19) es una enfermedad causada por un nuevo tipo de coronavirus conocido como SARS-CoV-2. 
Este virus fue reportado por vez primera el 31 de diciembre de 2019, en Wuhan (República Popular China), desde ese momento se han reportado 243,662,107 casos positivos de los cuales han fallecido 4.948.516 confirmados y entre 8 y 17 millones de personas estimadas.  
Según estadísticas de la [Caja Costarricense del Seguro Social](https://www.ccss.sa.cr/web/coronavirus/), en Costa Rica, se han reportado 553661 casos positivos de los cuales han fallecido 6880 personas, desde el primer caso reportado el 6 de marzo de 2020.  
En esta pagina web, se presentan datos, sobre la distribución del virus a nivel espacial en cuanto a los casos positivos, activos y fallecidos por cantón en Costa Rica. 

[Fuente de los datos](https://geovision.uned.ac.cr/oges/)

![](https://pngimg.com/uploads/coronavirus/coronavirus_PNG93680.png){width='200px'}