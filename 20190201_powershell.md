# Useful Cmdlets in Powershell

PowerShell is verstile command line shell which comes with a powerful scripting language. It is now even more available than before with the new [PowerShell Core](https://github.com/PowerShell/Powershell) which makes it available on Linux. Even though the main commands in the scripting language have been around for ages, I always see myself having to re-learn how to use it every time I need to write a script so today I will share examples that can we reused to quickly put together simple operations with PowerShell: 

1. Get PowerShell and IDE
2. Functions and parameters
3. Where-Object
4. Select-Object
5. If/Else
6. Format-Table and Format-List

## 1. Get PowerShell and IDE

Starting first from the IDE, Visual Code is a great IDE to code PowerShell scripts coupled with the PowerShell extension.
With this tool, we will have autocompletion and typesafety check.

- [Visual Code](https://code.visualstudio.com/)
- [PowerShell extension](https://marketplace.visualstudio.com/items?itemName=ms-vscode.PowerShell)

## 2. Functions and parameters

PowerShell supports functions which is very useful to keep a script file structured.
A function can take optionally take arguments and optionally return a result. 

```ps1
function Get-BeginningOfYear {
    param ([int]$year, $month)

    Get-Date -Month $month -Day 1 -Year $year
    Get-Date -Month $month -Day 1 -Year ($year + 1)
    Get-Date -Month $month -Day 1 -Year ($year + 2)
}

Get-BeginningOfYear -month 1 -year 2017 |
Select-Object -Property Year |
ForEach-Object { Write-Host $_.Year }
```

Here the function takes a __typed__ parameter of `int`. If we were to call the function with a string `Get-BeginningOfYear  -month 1 -year "x"`, we would get the following error:

```
Get-BeginningOfYear : Cannot process argument transformation on parameter 'year'. Cannot convert value "x" to type "System.Int32". Error: "Input string was not in a correct format."
```

Another point to take note of is that the returns are implicit and the function will return an array of three dates which we can pipe to other cmdlet.

```ps1
Get-Date -Month $month -Day 1 -Year $year
Get-Date -Month $month -Day 1 -Year ($year + 1)
Get-Date -Month $month -Day 1 -Year ($year + 2)
```

[Official Function documentation](https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_functions?view=powershell-6)

## 3. Where-Object

`Where-Object` filters objects from an array based on a condition given.

```ps1
function Get-BeginningOfYear2 {
    param ([int]$year, $month)

    for ($i = 0; $i -le 30; $i++) {
        Get-Date -Month $month -Day 1 -Year ($year + $i)
    }
}

Get-BeginningOfYear2 -month 1 -year 2017 |
Where-Object -Property Year -GE 2030 |
ForEach-Object { Write-Host $_ }
```

A property of the object can be selected to be compared against with `-Property` and operators like `-GT`, `-LT`, `-GE`, `-LE` and also `-Match`, `-NotMatch` for regex, and `-Like`, `NotLike` for wildcard characters filtering. The list is provided by intelisense when using Visual Code with PowerShell extension.

## 4. Select-Object

`Select-Object` selects a property of an object.

```ps1
function Get-BeginningOfYear2 {
    param ([int]$year, $month)

    for ($i = 0; $i -le 5; $i++) {
        Get-Date -Month $month -Day 1 -Year ($year + $i)
    }
}

Get-BeginningOfYear2 -month 1 -year 2017 |
Select-Object -Property Year |
ForEach-Object { Write-Host "Year: $($_.Year)" }
```

Or can be used to select value at a certain index of an array.

```ps1
Get-BeginningOfYear2 -month 1 -year 2017 |
Select-Object -Index 3 |
ForEach-Object { Write-Host $_.Year }
```

Or a range.

```ps1
Get-BeginningOfYear2 -month 1 -year 2017 |
Select-Object -Skip 2 |
ForEach-Object { Write-Host $_.Year }
```

## 5. If/Else

`if`, `elseif` and `else` conditions can be used together with a test condition.

```ps1
$value = 10

if ($value -gt 5) {
    Write-Host "greater than 5"
}
elseif ($value -gt 3) {
    Write-Host "greater than 3"
}
else {
    Write-Host "None"
}
```

A widely used condition is to check if a directory exists:

```ps1
if(![System.IO.Directory]::Exists("C:\Pcdrojects")){
    Write-Host "Does not Exits"
} else {
    Write-Host "Exits"
}
```

Or if a file exists with `[System.IO.File]::Exists`.

The full list of conditions is available on [the documentation](https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_comparison_operators?view=powershell-6).

## 6. Format-Table and Format-List

For debugging purposes, we can use `Format-Table` and `Format-List` to enhance readiblity of the data.

`Format-Table` will format the result as a table.

```ps1
> Get-BeginningOfYear2 -month 1 -year 2017 | Format-Table

DisplayHint Date                Day DayOfWeek DayOfYear Hour  Kind Millisecond Minute Month
----------- ----                --- --------- --------- ----  ---- ----------- ------ -----
   DateTime 01/01/2017 00:00:00   1    Sunday         1   10 Local         666     37     1
   DateTime 01/01/2018 00:00:00   1    Monday         1   10 Local         673     37     1
   DateTime 01/01/2019 00:00:00   1   Tuesday         1   10 Local         674     37     1
```

```ps1
> Get-BeginningOfYear2 -month 1 -year 2017 | Format-Table -GroupBy DayOfWeek

      DayOfWeek: Sunday

DisplayHint Date                Day DayOfWeek DayOfYear Hour  Kind Millisecond
----------- ----                --- --------- --------- ----  ---- -----------
   DateTime 01/01/2017 00:00:00   1    Sunday         1   10 Local         213


   DayOfWeek: Monday

DisplayHint Date                Day DayOfWeek DayOfYear Hour  Kind Millisecond
----------- ----                --- --------- --------- ----  ---- -----------
   DateTime 01/01/2018 00:00:00   1    Monday         1   10 Local         214


   DayOfWeek: Tuesday

DisplayHint Date                Day DayOfWeek DayOfYear Hour  Kind Millisecond
----------- ----                --- --------- --------- ----  ---- -----------
   DateTime 01/01/2019 00:00:00   1   Tuesday         1   10 Local         216
```

And `Format-List` would display it as a list.

```ps1
> Get-BeginningOfYear2 -month 1 -year 2017 | Format-List

DisplayHint : DateTime
Date        : 01/01/2017 00:00:00
Day         : 1
DayOfWeek   : Sunday
DayOfYear   : 1
Hour        : 10
Kind        : Local
Millisecond : 939
Minute      : 41
Month       : 1
Second      : 54
Ticks       : 636188641149394848
TimeOfDay   : 10:41:54.9394848
Year        : 2017
DateTime    : Sunday 1 January 2017 10:41:54

DisplayHint : DateTime
Date        : 01/01/2018 00:00:00
Day         : 1
DayOfWeek   : Monday
DayOfYear   : 1
Hour        : 10
Kind        : Local
Millisecond : 955
Minute      : 41
Month       : 1
Second      : 54
Ticks       : 636504001149551351
TimeOfDay   : 10:41:54.9551351
Year        : 2018
DateTime    : Monday 1 January 2018 10:41:54

DisplayHint : DateTime
Date        : 01/01/2019 00:00:00
Day         : 1
DayOfWeek   : Tuesday
DayOfYear   : 1
Hour        : 10
Kind        : Local
Millisecond : 966
Minute      : 41
Month       : 1
Second      : 54
Ticks       : 636819361149669959
TimeOfDay   : 10:41:54.9669959
Year        : 2019
DateTime    : Tuesday 1 January 2019 10:41:54
```

## Conclusion

PowerShell is an extremely convenient tool with a whole set of functionalities that allows to write concise scripts. All major CI services, AppVeyor, GitLab, VSTS providing direct PowerShell support in their pipeline configuration, it is very handy to know some of the useful features of it. Today we saw how to implement functions in PowerShell, we then saw how to use cmdlets `Where-Object` and `Select-Object` to manipulate objects and arrays then we saw how `If/Else` conditions could be used and finally for debugging, we saw how the `Format-x` cmdlet could be used. Hope you liked this post, see you next time!