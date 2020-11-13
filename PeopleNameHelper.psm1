# Lists of names downloaded from https://www.avoindata.fi/data/en_GB/dataset/none
$givenNames = Get-Content -Path $PSScriptRoot\givenNames.txt
  $surNames = Get-Content -Path $PSScriptRoot\surNames.txt
 $bothNames = $givenNames + $surNames

function Find-SurAndGivenName
{
    # NOTE There must be a better name for this function
    # NOTE if you require [String[]] for $InputText, PS will not take an empty index 
    # in an array. Meaning it will not accept something like cat .\names.txt where 
    # names.txt contains empty lines, you'd have to filter out empty indices first...
    Param(
        [Parameter(Mandatory=$true)]$InputText
    )
    $i = 0
    $InputText = $InputText -split '[^\w]|\d' | Where-Object { $_ }
    while ($true) {
        if ($i -eq $InputText.count) {
            return
        }
        $nameObj = [PSCustomObject]@{
              'SurName' = $null
            'GivenName' = $null
        }
        $word = $InputText[$i]
        if ($bothNames -contains $word) {
            # NOTE Sometimes a name can of course be both a surname and a givenname, 
            # such as the finnish name Lauri. The following if - ifelse statement 
            # gives preference for Lauri to be a given name.
            # TODO Add more advanced logic so maybe if a word could be either or, 
            # check if the second one is only on the list of accepted surnames. Then we 
            # can be fairly sure the first word is a givenname
            # TODO Should probably pick out all names in a continuous line (say 5 words 
            # next to each other all are names) first, then decide what to do wit all 
            # of them. Right now the script will not handle 
            # that sort of thing well. For example:
            # Givenname givenname givenname givenname - probably just a list of given names
            # of four different people
            # Givenname givenname surname - the givenname in between is probably a middle name, 
            # not to mention it could be a single letter initial of a middle name
            if ($givenNames -contains $word) {
                $nameObj.GivenName = $word
            } elseif ($surNames -contains $word) {
                $nameObj.SurName = $word
            }
            if ($nameObj.SurName -or $nameObj.GivenName) {
                $nextWord = $InputText[$i + 1]
                if ($givenNames -contains $nextWord) {
                    $nameObj.GivenName = $nextWord
                    $i++
                } elseif ($surNames -contains $nextWord) {
                    $nameObj.SurName = $nextWord
                    $i++
                }
            }
        }
        if ($nameObj.SurName -or $nameObj.GivenName) {
            $nameObj
        }
        $i++
    }
}
