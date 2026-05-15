library(shiny)
library(data.table)
library(ggplot2)

source("R/shiny_helpers.R")

app_data <- tryCatch(load_app_data("data/processed"), error = function(e) e)

if (inherits(app_data, "error")) {
  ui <- fluidPage(
    titlePanel("FAERS Adverse Event Reporting"),
    h3("Processed data not found"),
    p("Run the data scripts before starting the app:"),
    tags$pre("Rscript scripts/download_data.R\nRscript scripts/preprocess_data.R"),
    p(app_data$message)
  )
  server <- function(input, output, session) {}
} else {
  choices <- app_data$drug_lookup[order(-reports)]
  choices <- head(choices, 500)
  drug_choices <- stats::setNames(choices$drugname_norm, choices$label)
  default_drug <- if (length(drug_choices)) unname(drug_choices[[1]]) else ""

  metadata_text <- if (!is.null(app_data$metadata) && nrow(app_data$metadata)) {
    paste("Data:", app_data$metadata$quarters[1])
  } else {
    "Data: processed FAERS tables"
  }

  ui <- fluidPage(
    titlePanel("FAERS Adverse Event Reporting"),
    sidebarLayout(
      sidebarPanel(
        selectizeInput("drug", "Drug", choices = drug_choices, selected = default_drug),
        sliderInput("age", "Age range", min = 0, max = 120, value = c(0, 120), step = 1),
        selectInput("sex", "Sex", choices = c("All", "F", "M", "UNK"), selected = "All"),
        checkboxGroupInput("roles", "Drug role", choices = role_labels, selected = names(role_labels)),
        hr(),
        h4("How to use"),
        p("Choose a drug, adjust the filters, then compare reports, therapies, indications, reactions, outcomes, demographics, and countries."),
        p(metadata_text)
      ),
      mainPanel(
        h4(textOutput("summary_text")),
        tabsetPanel(
          tabPanel(
            "Reports",
            plotOutput("reports_plot", height = 320),
            h4("Co-occurring substances"),
            tableOutput("co_drugs")
          ),
          tabPanel(
            "Therapy",
            plotOutput("therapy_plot", height = 320),
            h4("Missing values after joins"),
            tableOutput("missing_values")
          ),
          tabPanel(
            "Medical terms",
            h4("Top indications"),
            plotOutput("indications_plot", height = 300),
            h4("Top reactions"),
            plotOutput("reactions_plot", height = 300)
          ),
          tabPanel(
            "Outcomes",
            plotOutput("outcome_plot", height = 320)
          ),
          tabPanel(
            "Extra stats",
            h4("Age groups"),
            plotOutput("age_plot", height = 300),
            h4("Countries"),
            plotOutput("country_plot", height = 300)
          )
        )
      )
    )
  )

  server <- function(input, output, session) {
    selected_cases <- reactive({
      req(input$drug)
      build_drug_case_table(app_data, input$drug)
    })

    filtered_cases <- reactive({
      filter_cases(
        selected_cases(),
        age_range = input$age,
        sex_filter = input$sex,
        roles = input$roles
      )
    })

    output$summary_text <- renderText({
      cases <- filtered_cases()
      paste0(
        data.table::uniqueN(cases$primaryid), " reports and ",
        nrow(cases), " drug records after filters"
      )
    })

    output$reports_plot <- renderPlot({
      dt <- reports_by_quarter_role(filtered_cases())
      validate(need(nrow(dt) > 0, "No reports for the selected filters."))
      ggplot(dt, aes(x = quarter_key, y = reports, fill = role_cod)) +
        geom_col(position = "dodge") +
        labs(x = "Quarter", y = "Reports", fill = "Role") +
        theme_minimal(base_size = 12)
    })

    output$co_drugs <- renderTable({
      co_occurring_by_role(filtered_cases(), input$drug, n = 5)
    })

    output$therapy_plot <- renderPlot({
      dt <- filtered_cases()[!is.na(therapy_days) & therapy_days >= 0 & therapy_days <= 3650]
      validate(need(nrow(dt) > 0, "No completed therapy duration values for the selected filters."))
      ggplot(dt, aes(x = therapy_days)) +
        geom_histogram(bins = 30, fill = "#2f6f73", color = "white") +
        labs(x = "Therapy length in days", y = "Drug records") +
        theme_minimal(base_size = 12)
    })

    output$missing_values <- renderTable({
      missing_value_summary(filtered_cases())
    })

    output$indications_plot <- renderPlot({
      dt <- top_indications(filtered_cases(), n = 10)
      validate(need(nrow(dt) > 0, "No indication terms for the selected filters."))
      ggplot(dt, aes(x = reorder(indi_pt, N), y = N)) +
        geom_col(fill = "#5b7f95") +
        coord_flip() +
        labs(x = NULL, y = "Records") +
        theme_minimal(base_size = 12)
    })

    output$reactions_plot <- renderPlot({
      dt <- top_reactions(app_data, filtered_cases(), n = 10)
      validate(need(nrow(dt) > 0, "No reaction terms for the selected filters."))
      ggplot(dt, aes(x = reorder(pt, N), y = N)) +
        geom_col(fill = "#8a6f3d") +
        coord_flip() +
        labs(x = NULL, y = "Reports") +
        theme_minimal(base_size = 12)
    })

    output$outcome_plot <- renderPlot({
      dt <- outcome_distribution(filtered_cases())
      validate(need(nrow(dt) > 0, "No completed therapies with outcome values for the selected filters."))
      ggplot(dt, aes(x = reorder(outcome, N), y = N)) +
        geom_col(fill = "#7f5a6a") +
        coord_flip() +
        labs(x = NULL, y = "Records") +
        theme_minimal(base_size = 12)
    })

    output$age_plot <- renderPlot({
      dt <- age_group_distribution(filtered_cases())
      validate(need(nrow(dt) > 0, "No age values for the selected filters."))
      x_col <- names(dt)[1]
      ggplot(dt, aes(x = reorder(as.character(.data[[x_col]]), reports), y = reports)) +
        geom_col(fill = "#4f7a52") +
        coord_flip() +
        labs(x = NULL, y = "Reports") +
        theme_minimal(base_size = 12)
    })

    output$country_plot <- renderPlot({
      dt <- country_distribution(filtered_cases(), n = 10)
      validate(need(nrow(dt) > 0, "No country values for the selected filters."))
      ggplot(dt, aes(x = reorder(country, reports), y = reports)) +
        geom_col(fill = "#6f6f8f") +
        coord_flip() +
        labs(x = NULL, y = "Reports") +
        theme_minimal(base_size = 12)
    })
  }
}

shinyApp(ui, server)
