#####`FloatsToCsv.idc`
 
  * IDC script for [IDA](https://www.hex-rays.com) that will rip floating point constants from `heat.bin` (or any other executable file) and save them to CSV file. Tested with [IDA Free 5.0](https://www.hex-rays.com/products/ida/support/download_freeware.shtml).
  
#####`CsvToCheatTable.ps1`

PowerShell script that will convert resulting CSV file to [CheatEngine](http://www.cheatengine.org) cheat table. It accepts folowing aprameters:
 * `-CsvPath` - path to read CSV from
 * `-CheatTablePath` - path to save cheat table to
 * `-GameFile` - in case, you're not analysing `heat.bin`, specify filename here (it used in the cheat table to specify imagebase and offset)

#####`Heat.csv`

 * Ready to use CSV

#####`Heat.ct`

 * Ready to use сheat table

#####How-to
 * Open file (`heat.bin`) in IDA
 * Wait for autoanalysis to complete
 * `File` -> `Script file...` -> `FloatsToCsv.idc`
  * In the file save dialog choose path to the new CSV file. If you cancel dialog, script will only output CSV to IDA console
  * Open PowerShell console
  * Execute `.\CsvToCheatTable.ps1 -CsvPath 'X:\Path\To\File.csv' -CheatTablePath 'X:\Path\To\CheatTable.ct'`
  * Or just put `heat.csv` and script to the same folder and execute `.\CsvToCheatTable.ps1`. Script will save cheat table alongside as `Heat.ct`
