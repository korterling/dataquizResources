# Scrap raw data for dataquiz from OECD websites  
# Using RSelenium

# devtools::install_github("skranz/restorepoint")
# devtools::install_github("skranz/stringtools")

library(RSelenium)
library(restorepoint)
library(dplyr)
library(digest)
library(stringtools)

source("sel-utils.r")
dest.dir = file.path(getwd(),"oecd")
dest.dir = file.path(getwd(),"oecd_descr")

rD <- rsDriver(verbose = TRUE)

remDr <- rD$client

urls = str.trim(readLines("urls.txt"))
ignore = str.starts.with(urls,"#") | nchar(urls)==0
urls = urls[!ignore]

surls = readLines("success_urls.txt")

urls = setdiff(urls, surls)
for (url in urls) {
  res = try(save.oecd.indicator(url, dest.dir, dest.descr.dir))
  if (!is(res,"try-error")) {
    write(url,"success_urls.txt", append=TRUE)
  } else {
    write(url,"failed_urls.txt", append=TRUE)
  }
}


