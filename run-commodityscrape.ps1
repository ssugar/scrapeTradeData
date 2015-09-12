for($i=1992; $i -lt 2000; $i++)
{
    for($j=1; $j -lt 100; $j++)
    {
        write-progress -Activity "Scraping Commodity Trade Data" -Status "Year: $i Chapter: $j"
        .\commodityScrape.ps1 -year $i -chapterId $j -country 567 -tradeType 1 -onlyErrors 1 #export
        .\commodityScrape.ps1 -year $i -chapterId $j -country 567 -tradeType 3 -onlyErrors 1 #import
    }
}
write-progress -Activity "Scraping Commodity Trade Data" -Completed