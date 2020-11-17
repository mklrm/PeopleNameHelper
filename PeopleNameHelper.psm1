# Lists of names downloaded from https://www.avoindata.fi/data/en_GB/dataset/none
$givenNames = Get-Content -Path $PSScriptRoot\givenNames.txt
  $surNames = Get-Content -Path $PSScriptRoot\surNames.txt
 $bothNames = $givenNames + $surNames

function Find-Names
{
    Param(
        [Parameter(Mandatory=$true)]$InputText
    )
    if ($InputText -is [array]) {
        $InputText = $InputText -join "`n"
    }
    $InputText = $InputText -split ''
    $iLast = $InputText.count - 1
    $wordGroups = @()
    $wordGroup = [PSCustomObject]@{
        Words = @()
    }
    $word = ''
    foreach ($i in 0..$iLast) {
        $char = $InputText[$i]
        if ($char -match '\w' -and $char -notmatch '\d') {
            $word += $char
        } elseif ($char -match '\n') {
            # \n == newline
            # \W == non-alphanumeric
            $wordGroups += $wordGroup
            $wordGroup = [PSCustomObject]@{
                Words = @()
            }
        } else {
            if ($word.length -gt 0) {
                $wordGroup.Names += $word
                $word = ''
            }
        }
    }
}

function Find-NameGroups
{
    # NOTE if you require [String[]] for $InputText, PS will not take an empty index 
    # in an array. Meaning it will not accept something like cat .\names.txt where 
    # names.txt contains empty lines, you'd have to filter out empty indices first...
    Param(
        [Parameter(Mandatory=$true)]$InputText
    )
    $i = 0
    $InputText = $InputText -split '[^\w]|\d' | Where-Object { $_ }
    $nameGroups = @()
    while ($true) {
        if ($i -eq $InputText.count) {
            return $nameGroups
        }
        $lastWord = $InputText[$i - 1]
        $word = $InputText[$i]
        if ($bothNames -contains $word) {
            if ($bothNames -contains $lastWord) {
                # This is not the first name in a group 
                # but a name it is, add it
                $nameGroup.Names += $word
            } else {
                # This is a first name in a group
                $nameGroup = [PSCustomObject]@{
                    Names = @($word)
                    GivenNameCount = 0
                    SurNameCount = 0
                }
            }
        } else {
            if ($bothNames -contains $lastWord) {
                # The last word was the last name in a group
                foreach ($name in $nameGroup.Names) {
                    if ($givenNames -contains $name) {
                        $nameGroup.GivenNameCount += 1
                    }
                    if ($surNames -contains $name) {
                        $nameGroup.SurNameCount += 1
                    }
                }
                $nameGroups += $nameGroup
            }
        }
        $i++
    }
}

function Find-IndividualNames
{
    # NOTE if you require [String[]] for $InputText, PS will not take an empty index 
    # in an array. Meaning it will not accept something like cat .\names.txt where 
    # names.txt contains empty lines, you'd have to filter out empty indices first...
    Param(
        [Parameter(Mandatory=$true)]$InputText
    )
    $nameGroups = Find-NameGroups -InputText $InputText
    $nameList = @()
    foreach ($nameGroup in $nameGroups) {
        if ($nameGroup.SurNameCount -eq 0) {
            # Likely just a single or a list of given names
            $nameList += $nameGroup.Names
        } elseif ($nameGroup.GivenNameCount -eq 0) {
            # Likely just a single or a list of surnames
            $nameList += $nameGroup.Names
        } elseif ($nameGroup.SurNameCount -eq 1 -and ($surNames -contains $nameGroup.Names[-1])) {
            # Only the last name in the group is a surname, 
            # assume the others are all given/middle names 
            # of the same person.
            $nameList += $nameGroup.Names -join ' '
        } elseif ($nameGroup.SurNameCount -eq 1 -and ($surNames -contains $nameGroup.Names[0])) {
            # Same as the last case only the surname comes first
            $nameList += $nameGroup.Names -join ' '
        } else {
            $tmp = ''
            $beginsWithSurname = $false
            foreach ($name in $nameGroup.Names) {
            }
        }
    }
    return $nameList
}

<#
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
#>
