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
    paste("Loaded quarters:", app_data$metadata$quarters[1])
  } else {
    "Data: processed FAERS tables"
  }
  country_heading <- if ("occr_country" %in% names(app_data$demographic)) {
    "Top event countries"
  } else if ("reporter_country" %in% names(app_data$demographic)) {
    "Top reporter countries"
  } else {
    "Top reporter/event countries"
  }

  ui <- fluidPage(
    fluidRow(
      column(8, h2("FAERS Adverse Event Reporting")),
      column(4, h5(class = "text-muted text-right", "Phineas Berdelis and Valentin Schwarz"))
    ),
    sidebarLayout(
      sidebarPanel(
        selectizeInput("drug", "Drug", choices = drug_choices, selected = default_drug),
        sliderInput("age", "Age range in years", min = 0, max = 120, value = c(0, 120), step = 1),
        tags$p(
          "Full 0–120 includes reports with missing age. Narrowed ranges exclude reports with missing age.",
          class = "text-muted",
          style = "font-size: 12px; margin-top: -8px; margin-bottom: 18px;"
        ),
        selectInput("sex", "Sex", choices = c("All", "F", "M", "UNK"), selected = "All"),
        checkboxGroupInput("roles", "Drug role", choices = role_choices, selected = names(role_labels)),
        hr(),
        h4("How to use"),
        tags$div(
          tags$p("1. Choose a drug."),
          tags$p("2. Optionally filter by age, sex, and drug role."),
          tags$p("3. Use the tabs to compare reports, therapy, medical terms, outcomes, demographics, and data quality.")
        ),
        h4("Important limitation"),
        p("FAERS counts are reports, not incidence rates, risk estimates, or proof of causality."),
        h4("Data"),
        p(metadata_text)
      ),
      mainPanel(
        h4(textOutput("summary_text")),
        tags$p(class = "text-muted", textOutput("age_note")),
        tabsetPanel(
          tabPanel(
            "Reports",
            h3("Reports over time by selected drug role"),
            plotOutput("reports_plot", height = 320),
            fluidRow(
              column(
                5,
                h4("Selected drug reports by role"),
                tableOutput("role_summary")
              ),
              column(
                7,
                h4("Most common other drugs in the same reports"),
                p("Other drugs listed in the same reports; this does not prove interaction or causality."),
                tableOutput("co_drugs")
              )
            )
          ),
          tabPanel(
            "Therapy",
            h3("Therapy length distribution"),
            checkboxInput("zoom_therapy", "Zoom to typical therapy lengths", value = FALSE),
            tags$p(class = "text-muted", textOutput("therapy_zoom_note")),
            plotOutput("therapy_plot", height = 320)
          ),
          tabPanel(
            "Medical terms",
            h3("Top reported indications and reactions"),
            h4("Top indications"),
            plotOutput("indications_plot", height = 280),
            h4("Top reactions"),
            plotOutput("reactions_plot", height = 280)
          ),
          tabPanel(
            "Outcomes",
            h3("Reported serious outcomes"),
            plotOutput("outcome_plot", height = 320)
          ),
          tabPanel(
            "Demographics",
            h3("Additional demographics"),
            h4("Age groups"),
            plotOutput("age_plot", height = 280),
            h4(country_heading),
            plotOutput("country_plot", height = 280)
          ),
          tabPanel(
            "Data quality",
            h3("Data completeness"),
            h4("Data completeness / missing values"),
            tableOutput("missing_values")
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
      paste0(
        format(length(reports$ids), big.mark = ",", scientific = FALSE),
        " reports match the selected filters."
      )
    })

    output$age_note <- renderText({
      reports <- report_set()
      if (isTRUE(reports$age_filter_active)) {
        paste0(
          "Note: ",
          format(reports$unknown_age_excluded, big.mark = ",", scientific = FALSE),
          " reports have missing age and are excluded because the age range is restricted."
        )
      } else {
        paste0(
          "Note: ",
          format(reports$unknown_age_reports, big.mark = ",", scientific = FALSE),
          " reports have missing age and are included because the full age range is selected."
        )
      }
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
      plot_dt <- dt
      if (isTRUE(input$zoom_therapy) && nrow(dt) >= 10) {
        cutoff <- stats::quantile(dt$therapy_days, probs = 0.95, na.rm = TRUE, names = FALSE)
        if (is.finite(cutoff)) {
          plot_dt <- dt[therapy_days <= cutoff]
        }
      }
      ggplot(plot_dt, aes(x = therapy_days)) +
        geom_histogram(bins = 30, fill = "#2f6f73", color = "white") +
        labs(x = "Therapy length in days", y = "Therapy records") +
        theme_minimal(base_size = 12)
    })

    output$therapy_zoom_note <- renderText({
      if (isTRUE(input$zoom_therapy)) {
        "Zoomed to the 95th percentile for readability. Extreme values are hidden only in this histogram."
      } else {
        "Showing all therapy durations. A few very long durations may stretch the x-axis."
      }
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
