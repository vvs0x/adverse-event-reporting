discover_faers_archives <- function(
    url = "https://fis.fda.gov/extensions/FPD-QDE-FAERS/FPD-QDE-FAERS.html",
    min_year = 2012) {
  if (!requireNamespace("rvest", quietly = TRUE)) {
    stop("Package 'rvest' is required.", call. = FALSE)
  }
  if (!requireNamespace("xml2", quietly = TRUE)) {
    stop("Package 'xml2' is required.", call. = FALSE)
  }
  if (!requireNamespace("stringr", quietly = TRUE)) {
    stop("Package 'stringr' is required.", call. = FALSE)
  }

  page <- rvest::read_html(url)
  links <- rvest::html_elements(page, "a")
  href <- rvest::html_attr(links, "href")
  text <- rvest::html_text2(links)
  keep <- !is.na(href) & grepl("\\.zip($|[?])", href, ignore.case = TRUE)
  href <- href[keep]
  text <- text[keep]
  full_url <- xml2::url_absolute(href, url)

  label <- paste(text, href)
  m <- stringr::str_match(toupper(label), "(20[0-9]{2})[^0-9A-Z]*Q([1-4])")
  missing_year <- is.na(m[, 2])
  if (any(missing_year)) {
    m2 <- stringr::str_match(toupper(label[missing_year]), "([0-9]{2})Q([1-4])")
    yy <- suppressWarnings(as.integer(m2[, 2]))
    m[missing_year, 2] <- ifelse(!is.na(yy), as.character(2000 + yy), NA)
    m[missing_year, 3] <- m2[, 3]
  }

  archives <- data.frame(
    year = suppressWarnings(as.integer(m[, 2])),
    quarter = suppressWarnings(as.integer(m[, 3])),
    url = full_url,
    file = basename(href),
    stringsAsFactors = FALSE
  )
  archives <- archives[!is.na(archives$year) & archives$year >= min_year, ]
  archives <- archives[order(archives$year, archives$quarter), ]
  archives[!duplicated(paste(archives$year, archives$quarter, archives$url)), ]
}

select_latest_archives <- function(archives, n = 8) {
  archives <- archives[order(archives$year, archives$quarter, decreasing = TRUE), ]
  archives <- archives[!duplicated(paste(archives$year, archives$quarter)), ]
  archives <- head(archives, n)
  archives[order(archives$year, archives$quarter), ]
}

zip_is_valid <- function(path) {
  if (!file.exists(path) || file.info(path)$size == 0) {
    return(FALSE)
  }
  ok <- tryCatch({
    utils::unzip(path, list = TRUE)
    TRUE
  }, error = function(e) FALSE, warning = function(w) FALSE)
  isTRUE(ok)
}

download_faers_archives <- function(archives, raw_dir = "data/raw", timeout = 600) {
  dir.create(raw_dir, recursive = TRUE, showWarnings = FALSE)
  downloaded <- character(nrow(archives))
  old_timeout <- getOption("timeout")
  options(timeout = max(timeout, old_timeout))
  on.exit(options(timeout = old_timeout), add = TRUE)

  for (i in seq_len(nrow(archives))) {
    dest <- file.path(raw_dir, sprintf("faers_ascii_%dQ%d.zip", archives$year[i], archives$quarter[i]))
    if (zip_is_valid(dest)) {
      message("Already downloaded ", archives$year[i], "Q", archives$quarter[i], ": ", dest)
    } else {
      if (file.exists(dest)) {
        message("Removing incomplete download: ", dest)
        unlink(dest)
      }
      message("Downloading ", archives$year[i], "Q", archives$quarter[i], " from ", archives$url[i])
      tmp <- paste0(dest, ".part")
      if (file.exists(tmp)) {
        unlink(tmp)
      }
      download.file(archives$url[i], destfile = tmp, mode = "wb", quiet = FALSE)
      if (!zip_is_valid(tmp)) {
        unlink(tmp)
        stop("Downloaded file is not a valid zip: ", archives$url[i], call. = FALSE)
      }
      file.rename(tmp, dest)
    }
    downloaded[i] <- dest
  }
  downloaded
}

unzip_faers_archives <- function(zip_files, raw_dir = "data/raw") {
  out_dirs <- character(length(zip_files))
  for (i in seq_along(zip_files)) {
    m <- regmatches(basename(zip_files[i]), regexpr("20[0-9]{2}Q[1-4]", basename(zip_files[i]), ignore.case = TRUE))
    if (!length(m) || m == "") {
      stop("Cannot infer quarter from ", zip_files[i], call. = FALSE)
    }
    out_dir <- file.path(raw_dir, paste0("faers_ascii_", toupper(m)))
    dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)
    message("Unzipping ", basename(zip_files[i]), " to ", out_dir)
    unzip(zip_files[i], exdir = out_dir)
    out_dirs[i] <- out_dir
  }
  out_dirs
}

download_latest_faers <- function(
    n = 8,
    raw_dir = "data/raw",
    min_year = 2012,
    timeout = 600,
    url = "https://fis.fda.gov/extensions/FPD-QDE-FAERS/FPD-QDE-FAERS.html") {
  archives <- discover_faers_archives(url = url, min_year = min_year)
  archives <- select_latest_archives(archives, n = n)
  zip_files <- download_faers_archives(archives, raw_dir = raw_dir, timeout = timeout)
  unzip_faers_archives(zip_files, raw_dir = raw_dir)
  invisible(archives)
}
