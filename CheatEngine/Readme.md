#####`FloatsToCsv.idc`
 
  * IDC script for [IDA](https://www.hex-rays.com) that will rip floating point constants from `heat.bin` (or any other executable file) and save them to CSV file. Tested with [IDA Free 5.0](https://www.hex-rays.com/products/ida/support/download_freeware.shtml).
  
#####`CsvToCheatTable.ps1`

PowerShell script that will convert resulting CSV file to [CheatEngine](http://www.cheatengine.org) cheat table. It accepts folowing aprameters:
 * `-CsvPath` - path to read CSV from
 * `-CheatTablePath` - path to save cheat table to. If not specified, file will be created in the script directory with filename from CsvPath's and `ct` extension.
 * `-GameFile` - in case, you're not analysing `heat.bin`, specify filename here (it used in the cheat table to specify imagebase and offset)

#####`Heat.csv`

 * Ready to use CSV

#####`Heat.ct`

 * Ready to use сheat table

#####How to generate cheat table

 * Open file (`heat.bin`) in IDA
 * Wait for autoanalysis to complete
 * `File` → `Script file...` → `FloatsToCsv.idc`
  * In the file save dialog choose path to the new CSV file. If you cancel dialog, script will only output CSV to IDA console
  * Open PowerShell console
  * Execute `.\CsvToCheatTable.ps1 -CsvPath 'X:\Path\To\File.csv' -CheatTablePath 'X:\Path\To\CheatTable.ct'`
  * Or just put `heat.csv` and script to the same folder and execute `.\CsvToCheatTable.ps1`. Script will save cheat table alongside as `Heat.ct`

#####How to use cheat table

 * Start Nascar Heat
  * To run Nascar Heat in window mode, get [dgVoodoo 2](http://dege.freeweb.hu)
  * Copy `D3DImm.dll` and `DDraw.dll` to the current user's TEMP folder (see %TEMP% environment variable)
  * Run `dgVoodooSetup.exe`
  * Add path to TEMP folder to the `Config folder / Running` instance list
  * Go to `DirectX` tab and uncheck:
    * `Application controled fullscreen/windowed state`
    * `Disable Alt-Enter to toggle screen state`
  * After Nascar Heat starts, use Alt-Enter to switch to windowed mode
 * Start CheatEngine
 * `File` → `Open Process`
 * Find `heat.bin` in the list and click `Open` button
 * `File` → `Open File` → `Heat.ct`
 *  Now you can modify values in the cheat table
