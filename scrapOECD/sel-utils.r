

wait.until.downloaded = function(cmd, download.dir=get.chrome.download.dir(), timeout.sec=30, ignore.ext=c("tmp","crdownload")) {
  cmd = substitute(cmd)
  restore.point("wait.until.downloaded")
  prev.files = list.files(download.dir)
  eval(cmd)
  
  start.time = as.integer(Sys.time())
  new.files = NULL
  cat("\nWait until file is downloaded...")
  while(as.integer(Sys.time())-start.time<=timeout.sec) {
    
    files = list.files(download.dir)
    new.files = setdiff(files, prev.files)
    new.files = new.files[!tools::file_ext(new.files) %in% ignore.ext]
    if (length(new.files)>0) break
  }
  return(file.path(download.dir, new.files))
}



# Default Chrome download dir
get.chrome.download.dir = function() {
  sys = Sys.info()[["sysname"]]
  if (sys=="Linux") {
    file.path("home", Sys.info()[["user"]], "Downloads")
  } else if (sys=="Windows") {
    file.path("C:/", "Users", Sys.info()[["user"]], "Downloads")
  } else {
    file.path("", "Users", Sys.info()[["user"]], "Downloads")
  }
}


oecd.dropdown.elements = function(div.sel) {
  restore.point("oecd.dropdown.elements")
  sel = paste0(div.sel, " > div > ul > li > a")
  fields = remDr$findElements(using="css", sel)
  
  li = lapply(fields, function(field) {
    c(code=field$getElementAttribute("data-value")[[1]], label=field$getElementAttribute("innerHTML")[[1]])
  })
  df = unique(do.call(rbind,li))
  labels = df[,2]
  names(labels) = df[,1]
  labels
}

getInnerHTML = function(sel, verbose=TRUE) {
  restore.point("getInnerHTML")
  webElem <- remDr$findElement(using = 'css', sel)
  res = webElem$getElementAttribute("innerHTML")[[1]]
  cat("\n",res)
  res
}




patientFindElement = function(css, wait=0.1, max=4, return.all=FALSE) {
  restore.point("patientFindElement")
  cat("\nTry to find ", css)
  start = as.numeric(Sys.time())
  end = start + max
  while(TRUE) {
    els = remDr$findElements(using="css",css)
    if (length(els)>0) return(els[[1]])
    if (end < as.numeric(Sys.time())) {
      stop(paste0("Timeout: could not find ", css))
    }
    Sys.sleep(wait)
  }
}

# some helper functions
getField = function(css, field="value", unlist=TRUE,...) {
  webElem = patientFindElement(css,...)
  res = webElem$getElementAttribute(field)
  if (unlist) return(unlist(res))
  res
}
sendKeys = function(css, text,...) {
  webElem = patientFindElement(css,...)
  if (!is.list(text)) text = list(text)
  webElem$sendKeysToElement(text)
}
clickElement=function(css,...) {
  scroll.to.element(css)
  webElem = patientFindElement(css,...)
  restore.point("clickElement")
  webElem$clickElement()
}

trySeveral = function(cmd, timeout.sec=30,wait.sec=5, times=NULL) {
  cmd = substitute(cmd)
  restore.point("trySeveral")
  if (!is.null(times)) {
    for (i in 1:times) {
      res = try(eval(cmd),silent = TRUE)
      if (!is(res,"try-error")) {
        return(res)
      } else {
        cat("\nfailed ", deparse(cmd))
      }
    }
  } else {
    start.time = as.integer(Sys.time())
    while(as.integer(Sys.time())-start.time<=timeout.sec) {
      res = try(eval(cmd),silent = TRUE)
      if (!is(res,"try-error")) {
        return(res)
      } else {
        cat("\nfailed ", deparse(cmd))
      }
      Sys.sleep(wait.sec)
    }
    
  }
  
  res
}

scroll.to.element = function(sel) {
  remDr$executeScript(paste0('$("', sel,'")[0].scrollIntoView( false );'), args = list())
}

save.oecd.indicator = function(url, dest.dir, dest.descr.dir) {
    
  restore.point("save.oecd.indicator")
  cat("\nNavigate to ", url,"...")
  remDr$navigate(url)
  
  
  cat("\nExtract title and description...")
  # Find title
  title = getInnerHTML(".indicator-head.line-top.line-bottom h1")
  
  
  # Find variable description
  descr = getInnerHTML(".more-section p")
  descr = c(descr, paste0("<br>Source: OECD (<a href='", url,"' target='_blank'>",url,"</a>)"))
  
  # Try to click on yearly frequency
  try(clickElement("ul.segmented-control.frequencies > li:nth-child(1) > a"))
  
  cat("\nExtract subjects and measures...")
  # Find subjects
  subjects = oecd.dropdown.elements("div.dropdown.single-subject-dropdown")
  
  
  # Find measures
  
  # Loop through all subjects
  # click on them and then extract all measures
  # from measure drop down
  dropdown = remDr$findElement("css","div.dropdown.single-subject-dropdown a.dropdown-button")
  res = suppressWarnings(try(dropdown$clickElement(),silent = TRUE))
  
  # Use mulitple subjects dropdown
  if (is(res,"try-error")) {
    dropdown = remDr$findElement("css","div.dropdown-multiple.multiple-subjects-dropdown a.dropdown-button") 
    sel = paste0("div.dropdown-multiple.multiple-subjects-dropdown > div > ul > li > a")
  } else {
    sel = paste0("div.dropdown.single-subject-dropdown > div > ul > li > a")
  }
  
  els = remDr$findElements(using="css", sel)
  #el = els[[1]]
  li = lapply(els, function(el) {
    restore.point("hfhkdhfk")
    el$clickElement()
    dropdown$clickElement()

    measures = oecd.dropdown.elements("div.dropdown.measures")
    measures
  })
  measures = unlist(li)
  measures = measures[!duplicated(measures)]
  
  # Download
  
  #clickElement(".download-indicator-button")
  cat("\nDownload data...")
  remDr$executeScript('$(".dropdown.download-dropdown")[0].scrollIntoView( false );', args = list())
  file = wait.until.downloaded({
    #trySeveral(clickElement(".dropdown.download-dropdown"))
    clickElement(".dropdown.download-dropdown .download-btn-label")
    clickElement(".download-indicator-button")
  })
  file

  cat("\nSave and adapt data...")
    
  dat = read.csv(file,stringsAsFactors = FALSE)
  dat$indicator_label = title
  dat$subject_label = subjects[dat$SUBJECT]
  dat$measure_label = measures[dat$MEASURE]
  colnames(dat)[1] = "cntry"
  
  indicator = dat$INDICATOR[1]
  dir = dest.dir
  
  write.csv(dat, file.path(dir,paste0(indicator,".csv")),row.names = FALSE)
  writeLines(descr, file.path(dest.descr.dir, paste0(indicator,"_descr.txt")))
}