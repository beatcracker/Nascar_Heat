Param
(
    [string]$CsvPath = '.\Heat.csv',
    [string]$CheatTablePath,
    [string]$GameFile = 'heat.bin'
)

#region Here-strings used to build XML cheat table

$CheatTableXml = @'
<CheatTable CheatEngineTableVersion="18">
    <CheatEntries>
     {0}
    </CheatEntries>
    <UserdefinedSymbols/>
</CheatTable>
'@

$CheatGroupXml = @'
<CheatEntry>
    <ID>{0}</ID>
    <Description>"{1}"</Description>
    <Options
        moHideChildren="1"
        moBindActivation="1"
        moRecursiveSetValue="1"
        moManualExpandCollapse="1"
        moAllowManualCollapseAndExpand="1"/>
    <LastState
        Value=""
        Activated="0"
        RealAddress="00000000"/>
    <Color>80000008</Color>
    <GroupHeader>1</GroupHeader>
    <CheatEntries>
    {2}
    </CheatEntries>
</CheatEntry>
'@

$CheatEntryXml = @'
<CheatEntry>
    <ID>{0}</ID>
    <Description>"{1}"</Description>
    <LastState
        Value="{2:e}"
        Activated="0"
        RealAddress="{3:x}"/>
    <Color>80000008</Color>
    <VariableType>Float</VariableType>
    <Address>{4}+{5:x}</Address>
</CheatEntry>
'@

#endregion

# Read CSV file
$Csv = Import-Csv -Path $CsvPath
if(!$Csv)
{
    throw 'Can''t read CSV file or it''s empty!'
}

#region Find sequental addreses (used to build groups in cheat table)

$RecordBounds  = @()
$LowerBound = 0

# Find start and end indexes of each record
for($i = 0; $i -lt $Csv.Count; $i++){
    if(($Csv[$i+1].Address - $Csv[$i].Address) -ne 4)
    {
        # Found non-consequitve address
        $RecordBounds += ,($LowerBound, $i)
        $LowerBound = $i+1
    }
}

# Split records into multidimensional array
$Records = @()
for ($i = 0 ; $i -lt ($RecordBounds.Length-1) ; $i++)
{
    $Records += ,($Csv[($RecordBounds[$i][0])..($RecordBounds[$i][1])])
}

#endregion

#region Build XML cheat table

$ItemId = 0
$ItemInGroupId = 0

[xml]$Xml = $CheatTableXml -f (
    ($Records |
        ForEach-Object {
            if($_.Count -ne 1)
            {
                # Build group
                $CheatGroup = $_ |
                    ForEach-Object {
                        $CheatEntryXml -f $ItemInGroupId,
                                        ('{0}: {1}' -f $_.Name, $_.Disasm),
                                        [float]$_.Value,
                                        [int]$_.Address,
                                        $GameFile,
                                        [int]$_.Offset
                        $ItemInGroupId++
                    }
                $ItemInGroupId = 0

                $CheatGroupXml -f $ItemId,
                                ('Range: {0} - {1}' -f $_[0].Address, $_[-1].Address),
                                ($CheatGroup -join [Environment]::NewLine)
                $ItemId++
            }
            else
            {
                # Build single entry
                $CheatEntryXml -f $ItemId,
                                ('{0}: {1}' -f $_[0].Name, $_[0].Disasm),
                                [float]$_[0].Value,
                                [int]$_[0].Address,
                                $GameFile,
                                [int]$_[0].Offset
                $ItemId++
            }
    }) -join [Environment]::NewLine
)

#endregion

#region Write XML cheat table to file

if(!$CheatTablePath)
{
    # If CheatTablePath is not specified, set it to the: X:\Path\To\Script Directory\CsvFileName.ct
    $CheatTablePath = (Join-Path -Path (
                            Split-Path $script:MyInvocation.MyCommand.Path
                        ) -ChildPath (
                            [System.IO.Path]::GetFileNameWithoutExtension(
                                (Split-Path -Path $CsvPath -Leaf)
                            ) + '.ct'
                        )
    )
}

# Cheat Engine can't handle XML with BOM
$XmlWriterSettings = New-Object -TypeName System.Text.UTF8Encoding -ArgumentList $false # false means no BOM

$XmlTextWriter = New-Object -TypeName System.Xml.XmlTextWriter -ArgumentList ($CheatTablePath, $XmlWriterSettings)
$XmlTextWriter.Formatting = 'Indented'
$XmlTextWriter.Indentation = 2

# Save XMl using BOMless XmlTextWriter
$Xml.Save($XmlTextWriter)

# Cleanup XmlTextWriter
$XmlTextWriter.Close()
$XmlTextWriter.Dispose()

#endregion