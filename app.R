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
  role_choices <- stats::setNames(names(role_labels), role_labels)

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
        sliderInput("age", "Age range in years", min = 0, max = 120, value = c(0, 120), step = 1),
        selectInput("sex", "Sex", choices = c("All", "F", "M", "UNK"), selected = "All"),
        checkboxGroupInput("roles", "Drug role", choices = role_choices, selected = names(role_labels)),
        hr(),
        h4("How to use"),
        p("Choose a drug, adjust the filters, then compare reports, therapies, indications, reactions, outcomes, demographics, and countries. With the full 0-120 age range, reports with missing age are included; when the age range is narrowed, reports with missing age are excluded."),
        p(metadata_text)
      ),
      mainPanel(
        h4(textOutput("summary_text")),
        tabsetPanel(
          tabPanel(
            "Reports",
            plotOutput("reports_plot", height = 320),
            h4("Selected drug role summary"),
            tableOutput("role_summary"),
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
    report_set <- reactive({
      req(input$drug)
      filter_report_set(
        app_data,
        selected_drug = input$drug,
        age_range = input$age,
        sex_filter = input$sex,
        roles = input$roles
      )
    })

    output$summary_text <- renderText({
      reports <- report_set()
      age_note <- if (isTRUE(reports$age_filter_active)) {
        paste0(reports$unknown_age_excluded, " reports with missing age excluded by the age filter")
      } else {
        paste0(reports$unknown_age_reports, " reports with missing age included")
      }
      paste0(
        length(reports$ids), " reports after filters; ",
        age_note
      )
    })

    output$reports_plot <- renderPlot({
      dt <- reports_by_quarter_role_for_selected_drug(report_set())
      validate(need(nrow(dt) > 0, "No reports for the selected filters."))
      ggplot(dt, aes(x = quarter_key, y = reports, fill = role_cod)) +
        geom_col(position = "dodge") +
        labs(x = "Quarter", y = "Reports", fill = "Role") +
        theme_minimal(base_size = 12)
    })

    output$role_summary <- renderTable({
      selected_drug_role_summary(report_set())[, .(role, reports)]
    })

    output$co_drugs <- renderTable({
      co_occurring_by_role_for_reports(report_set(), input$drug, n = 5)
    })

    output$therapy_plot <- renderPlot({
      dt <- therapy_distribution_for_reports(app_data, report_set())
      validate(need(nrow(dt) > 0, "No completed therapy duration values for the selected filters."))
      ggplot(dt, aes(x = therapy_days)) +
        geom_histogram(bins = 30, fill = "#2f6f73", color = "white") +
        labs(x = "Therapy length in days", y = "Therapy records") +
        theme_minimal(base_size = 12)
    })

    output$missing_values <- renderTable({
      missing_value_summary(app_data, report_set())
    })

    output$indications_plot <- renderPlot({
      dt <- top_indications_for_reports(app_data, report_set(), n = 10)
      validate(need(nrow(dt) > 0, "No indication terms for the selected filters."))
      ggplot(dt, aes(x = reorder(indi_pt, reports), y = reports)) +
        geom_col(fill = "#5b7f95") +
        coord_flip() +
        labs(x = NULL, y = "Reports") +
        theme_minimal(base_size = 12)
    })

    output$reactions_plot <- renderPlot({
      dt <- top_reactions_for_reports(app_data, report_set(), n = 10)
      validate(need(nrow(dt) > 0, "No reaction terms for the selected filters."))
      ggplot(dt, aes(x = reorder(pt, N), y = N)) +
        geom_col(fill = "#8a6f3d") +
        coord_flip() +
        labs(x = NULL, y = "Reports") +
        theme_minimal(base_size = 12)
    })

    output$outcome_plot <- renderPlot({
      dt <- outcome_distribution_for_reports(app_data, report_set())
      validate(need(nrow(dt) > 0, "No completed therapies with outcome values for the selected filters."))
      ggplot(dt, aes(x = reorder(outcome, reports), y = reports)) +
        geom_col(fill = "#7f5a6a") +
        coord_flip() +
        labs(x = NULL, y = "Reports") +
        theme_minimal(base_size = 12)
    })

    output$age_plot <- renderPlot({
      dt <- age_group_distribution_for_reports(report_set())
      validate(need(nrow(dt) > 0, "No age values for the selected filters."))
      ggplot(dt, aes(x = reorder(as.character(age_group), reports), y = reports)) +
        geom_col(fill = "#4f7a52") +
        coord_flip() +
        labs(x = NULL, y = "Reports") +
        theme_minimal(base_size = 12)
    })

    output$country_plot <- renderPlot({
      dt <- country_distribution_for_reports(report_set(), n = 10)
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
