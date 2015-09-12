param(
$year = 2014,
$countryName = $null,
$countryNumber = 0
)

$month = 12
$day = 31

$address = "http://www5.statcan.gc.ca/cimt-cicm/section-section?lang=eng&dataTransformation=0&refYr=" + $year + "&refMonth=12&freq=12&countryId=586&usaState=0&provId=1&retrieve=Retrieve&save=null&trade=null"
$site = Invoke-WebRequest -Uri $address
$html = $site.parsedHTML
$date = get-date -year $year -month 12 -day 31 -hour 0 -minute 0 -second 0

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
                if($jsonString -match $countryName -and $countryName -ne $null)
                {
                    write-output $jsonString
                }
                if($countryNumCheck -eq $countryNumber)
                {
                    write-output $countryNameOutput
                }
                $jsonString = ""
            }
            $x+=1
        }
    }
}
