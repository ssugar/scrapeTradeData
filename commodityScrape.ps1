param(
$countryNumber = 586,
$tradeType = 1,
$year = 2014,
$chapterId = 1,
$onlyErrors = 0
)

$address = "http://www5.statcan.gc.ca/cimt-cicm/topNCommodities-marchandises?countryId=" + $countryNumber + "&tradeType=" + $tradeType + "&usaState=0&dataTransformation=0&topNDefault=100&freq=12&lang=eng&refYr=" + $year + "&monthStr=December&chapterId=" + $chapterId + "&provId=1&refMonth=12"

try
{
    $site = Invoke-WebRequest -Uri $address
    $html = $site.parsedHTML
    $date = get-date -year $year -month 12 -day 31 -hour 0 -minute 0 -second 0

    $tableHeaders = $html.getElementsByTagName("TH")
    $tableDatas = $html.getElementsByTagName("TD")

    [string]$remoteip = "111.221.100.4" # IP to send to 
    [int]$remoteudpport=6869           # port to send to
    [int]$sourceudpport = 0
    $udpClient = new-Object system.Net.Sockets.Udpclient($sourceport) 

    $headings = [System.Collections.ArrayList]@()

    $options = $html.getElementsByTagName("SELECT")

    foreach($option in $options)
    {
        if($option.name -eq "countryId")
        {
            $choices = $option.innerHTML.Split('<>')
            $x=0
            $w=0
            $jsonString = ""
            foreach($choice in $choices)
            {
                $w = [int]$x%4
                if($w -eq 1)
                {
                    $jsonString += ($choice.Split('='))[1]
                }
                elseif($w -eq 2)
                {
                    $jsonString = $jsonString + " " + $choice
                    $countryNameOutput = $choice
                }
                elseif($w -eq 3)
                {
                    $countryNumCheck = [int]($jsonString.Split(' '))[0]
                    if($countryNumCheck -eq $countryNumber)
                    {
                        $countryName = $countryNameOutput
                    }
                    $jsonString = ""
                }
                $x+=1
            }
        }
    }

    $x=0
    foreach($header in $tableHeaders)
    {
        if($x -gt 16)
        {
            $count = $headings.Add($header.InnerText)        
        }
        $x += 1
    }

    #going through the table data and entering the headers at the beginning
    $y=0
    $v=0
    $jsonString = ""
    foreach($data in $tableDatas)
    {

        $w = [int]$y%10
        if($w -eq 1 -and $y -ne 1)
        {
            $jsonString = $jsonString + '{"datetime":"' + $date + '", "country":"' + $countryName + '","heading":"' + $headings[$v] + '",' + '"Units":"' + $data.InnerText.Replace(" ", "") + '",'
            $v += 1
        }
        elseif($w -eq 2 -and $y -ne 2)
        {
            if($tradeType -eq 1)
            {
                $jsonString = $jsonString + '"Export Quantity":' + $data.InnerText.Replace(",","") + ','
            }
            elseif($tradeType -eq 3)
            {
                $jsonString = $jsonString + '"Import Quantity":' + $data.InnerText.Replace(",","") + ','
            }
        }
        elseif($w -eq 3 -and $y -ne 3)
        {
            if($tradeType -eq 1)
            {
                $jsonString = $jsonString + '"Export Value":' + $data.InnerText.Replace(",","") + '}'
            }
            elseif($tradeType -eq 3)
            {
                $jsonString = $jsonString + '"Import Value":' + $data.InnerText.Replace(",","") + '}'
            }
            if($onlyErrors -eq 0)
            {
                write-host $jsonString
            }
            [string]$buffer = $jsonString
            $byteBuffer  = [System.Text.Encoding]::ASCII.GetBytes($Buffer)
            $sendbytes = $udpClient.Send($byteBuffer, $byteBuffer.length, $remoteip, $remoteudpport)
            $jsonString = ""
        }
        $y += 1
    }
}
catch
{
    write-host ".\commodityScrape.ps1 -countryNumber $countryNumber -tradeType $tradeType -year $year -chapter $chapterId -onlyErrors 1"
}
