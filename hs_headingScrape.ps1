param(
$year = 2014,
$countryNumber = 586 #Viet Nam
)

$month = 12
$day = 31

$address = "http://www5.statcan.gc.ca/cimt-cicm/section-section?lang=eng&dataTransformation=0&refYr=" + $year + "&refMonth=12&freq=12&countryId=" + $countryNumber + "&usaState=0&provId=1&retrieve=Retrieve&save=null&trade=null"
$site = Invoke-WebRequest -Uri $address
$html = $site.parsedHTML
$date = get-date -year $year -month 12 -day 31 -hour 0 -minute 0 -second 0

$tableHeaders = $html.getElementsByTagName("TH")
$tableDatas = $html.getElementsByTagName("TD")

$headings = [System.Collections.ArrayList]@()

[string]$remoteip = "111.221.100.4" # IP to send to 
[int]$remoteudpport=6868           # port to send to
[int]$sourceudpport = 0
$udpClient = new-Object system.Net.Sockets.Udpclient($sourceport) 

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
                #write-host $x $choice
                $jsonString = $jsonString + " " + $choice
                $countryNameOutput = $choice
            }
            elseif($w -eq 3)
            {
                #write-host $country "--" $jsonString
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




#grabbing the headers and putting them into an array
$x=0
#$z=0
foreach($header in $tableHeaders)
{
    if($x -gt 4)
    {
        $count = $headings.Add($header.InnerText)        
        #$z+=1
    }
    $x += 1
}

#going through the table data and entering the headers at the beginning
$y=0
$v=0
$jsonString = ""
foreach($data in $tableDatas)
{
    $w = [int]$y%3
    if($w -eq 0)
    {
        $jsonString = $jsonString + '{"datetime":"' + $date + '", "country":"' + $countryName + '","heading":"' + $headings[$v] + '",' + '"Domestic Exports":' + $data.InnerText.Replace(",","") + ','
        $v += 1
    }
    elseif($w -eq 1)
    {
        $jsonString = $jsonString + '"Re-Exports":' + $data.InnerText.Replace(",","") + ','
    }
    elseif($w -eq 2)
    {
        $jsonString = $jsonString + '"Imports":' + $data.InnerText.Replace(",","") + '}'
        write-host $jsonString

        [string]$buffer = $jsonString
        $byteBuffer  = [System.Text.Encoding]::ASCII.GetBytes($Buffer)
        $sendbytes = $udpClient.Send($byteBuffer, $byteBuffer.length, $remoteip, $remoteudpport)

        $jsonString = ""
    }
    $y += 1
}
