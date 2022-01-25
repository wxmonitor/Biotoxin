# Run to upload apps to server
#library(rsconnect)
#rsconnect::deployApp('/Users/andrewmicks/Index')

library(shiny)
library(curl)
library(tidyverse)

# Connect to FTP directory
baseURL <- "ftp://ftp.doh.wa.gov/biotoxin/"
h <- new_handle(dirlistonly=TRUE)
con <- curl(baseURL, "r", h)

# Read file list from directory
files <- read.table(con, colClasses = "character")
files <- pull(files, 1)
names(files) <- paste(
  paste(substr(files, 1,2), substr(files, 3,4), substr(files, 5,6), sep = "/"),
  substr(files, 7,9), sep = " ")

# Force time zone
Sys.setenv(TZ="America/Los_Angeles")

# Create new-upload check
today.PSP <- paste0(format(Sys.Date(), "%m%d%y"), "PSP.pdf")
update <- NULL
if (today.PSP %in% files) {
  update <- "*Today's PSP results uploaded*"
}


# Construct UI
ui <- fluidPage(
  sidebarLayout(
    sidebarPanel(
      selectInput("url", 
                  label = "Select a file:",
                  choices = c(" " = " ", files), selected = FALSE, selectize = TRUE),
      actionButton("button","View")
    ), 
    mainPanel(
      h5(update),
      tabsetPanel(
        tabPanel("DOH Biotoxin Results", 
                 htmlOutput("pdf")
        )
      )
    )
  )
)

#Run r code on server
server <- function(input, output, session) {
  
  # Drop down menu of available files
  observeEvent(input$button, {
    pdf_folder <- "pdf_folder"
    if(!file.exists(pdf_folder))
      dir.create("pdf_folder")
    temp <- tempfile(fileext = ".pdf", tmpdir = "pdf_folder")
    
    # Download selected file PDF
    download.file(paste0(baseURL, input$url), temp, mode = "wb")
    addResourcePath("pdf_folder",pdf_folder)
    
    # Display PDF in browser window
    output$pdf <- renderUI({
      tags$iframe(style="height:600px; width:100%", src=temp)
    })
  })
}


# Execute app
shinyApp(ui, server)




