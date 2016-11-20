<#What to do:
1. Test file exists
2. Rename file to <Status>-Hash
3. Perform functions:
   - Flatten: Flattens a XML-tree to a more basic form
   - DocGen: Performs flatten -> transform -> And then converts that to DocGen-formatted XML-files
   - Templating: Takes XML-information from input file and creates a new XML-file in a new format using that information
   - Transformation: Flattens a file and then transforms lists, tables etc.
#>
<# Functions:
Get filehash
Read-XML
Save-XML
Flatten
Transofmr
DocGen
Template
#>

param (
    [parameter(Position=0,Mandatory=$true)]
    [ValidateScript({Test-Path $_ -PathType ‘Leaf’})] 
    [string]
    $XmlFile,

    [parameter(Position=1,Mandatory=$true)]
    [ValidateScript({Test-Path $_ -PathType ‘Container’})] 
    [string]
    $SaveTo,

    [parameter(Position=2,Mandatory=$false)]
    [ValidateScript({Test-Path $_ -PathType ‘Container’})] 
    [string]
    $SaveOriginal,
    
    [parameter(Position=3,Mandatory=$false)]
    [bool]
    $DocGen = $false,

    [parameter(Position=4,Mandatory=$false)]
    [HashTable]
    $DocGenConfig = @{
        "TemplateFile" = "";
        "TempDestination" = "";
        "SaveDirectory" = "";
        "MakePDF" = "";
        "PrintFile" = "";
        "ExportXml" = "";
    }
)

#$SaveTo = "C:\Users\bonicoli\OneDrive för företag\Scripts\DocGen\xml"
[XML]$XmlDoc = Get-Content $XmlFile

[HashTable]$list = @{}
[HashTable]$tables = @{}

#Function to generate a random filename
function GenerateFileName {
    return ([System.IO.Path]::GetRandomFileName()).Split('.')[0] + (Get-Date -format "yyyy-MM-dd_HHmmssffff")
}

function CheckIfLeaf {
param (
    [Parameter(Position=0,Mandatory=$true)]
    [ValidateNotNull()]
    $XmlElement
)
    return (($XmlElement.ChildNodes.Count -eq 1) -and ($XmlElement.FirstChild.GetType().ToString() -eq "System.Xml.XmlText"))
}

function GetElementType {
param (
    [Parameter(Position=0,Mandatory=$true)]
    [ValidateNotNull()]
    $Element
)
<#
STR = Regular string
BOL = Convert boolean value to a checkbox
TBL = Table, if found created a xml for each row in table combined with other values
LSx = List items of x-number, all lists of the same numbers will be combined into one string called ListNumberX
BLx = Same as a list but the values are boolean and the hash name will be used as a value instead, will be called BoolListX
#>
    $types = @{
        "STR" = 1;
        "BOL" = 2;
        "TBL" = 3;
        "LS1" = 4;
        "LS2" = 4;
        "LS3" = 4;
        "LS4" = 4;
        "LS5" = 4;
        "LS6" = 4;
        "LS7" = 4;
        "LS8" = 4;
        "LS9" = 4;
        "BL1" = 5;
        "BL2" = 5;
        "BL3" = 5;
        "BL4" = 5;
        "BL5" = 5;
        "BL6" = 5;
        "BL7" = 5;
        "BL8" = 5;
        "BL9" = 5;

    }
    $typeString = $Element.Name.SubString(0,3).ToUpper()
    if ($types.ContainsKey($typeString)) {
        return $types.Get_Item($typeString)
    }
    else {
        return 0
    }
}

function GetElementName  {
param (
    [Parameter(Position=0,Mandatory=$true)]
    [ValidateNotNull()]
    $Element
)
    if ((GetElementType -Element $Element) -gt 0) {
        return $Element.Name.Substring(4)
    }
    else {
        return $Element.Name
    }
}

function TraverseTable {
param (
    [Parameter(Position=0,Mandatory=$true)]
    [ValidateNotNull()]
    $XmlElement
)
    [Array]$tableData = @()
    foreach ($row in $XmlElement.childnodes) {
	    [HashTable]$tempHash = @{}
	    foreach ($column in $row.Childnodes) {
		    $tempHash.add($column.name, $column.innertext)
	    }
	    $tableData +=$tempHash
    }
    return $tableData
}

function TraverseTree {
param (
    [Parameter(Position=0,Mandatory=$true)]
    [ValidateNotNull()]
    $XmlDoc
)
    if ($XmlDoc.HasChildNodes) {
        if (CheckIfLeaf -XmlElement $XmlDoc) {
            $list.Add($XmlDoc.Name, $XmlDoc.InnerText)
        }
        elseif ((GetElementType -Element $XmlDoc) -eq 3) {
            $tables.Add($XmlDoc.Name, [Array](TraverseTable -XmlElement $XmlDoc))
        }
        else {
            foreach ($element in $XmlDoc.ChildNodes) {
                TraverseTree -XmlDoc $element
            }
        }
    }
}

function GetUniqueHashKey {
param (
    [Parameter(Position=0,Mandatory=$true)]
    [ValidateNotNull()]
    [HashTable]
    $Data,
    
    [Parameter(Position=1,Mandatory=$true)]
    [ValidateNotNull()]
    [String]
    $tableKey,

    [Parameter(Position=2,Mandatory=$false)]
    [Int]
    $keyCount = 0
)
    if ($keyCount -eq 0) {
        $tempKey = $tableKey
    }
    else {
        $tempKey = "$tableKey$keyCount"
    }
    if ($Data.ContainsKey($tempKey)) {
        return (AddValueToHash -Data $Data -tableKey $tableKey -keyCount $keyCount++)
    }
    else {
        return $tempKey
    }
}

#function to combine table and row values
function CombineValues {
param (
    [Parameter(Position=0,Mandatory=$true)]
    [ValidateNotNull()]
    [HashTable]
    $indexData,
    
    [Parameter(Position=1,Mandatory=$true)]
    [ValidateNotNull()]
    [HashTable]
    $tableValues
)
    [HashTable]$combinedHash = $indexData.Clone()
    foreach ($pair in $tableValues.GetEnumerator()) {
        $key = GetUniqueHashKey -Data $indexData -tableKey $pair.Name
        $combinedHash.Add($key, $pair.Value)
    }
    return $combinedHash
}

#function to check if a string is a boolean (empty, 1, or 0)
function CheckStringBoolean {
param (
    [parameter(Position=0,Mandatory=$true)]
    [ValidateNotNull()]
    [String]
    $StringBool
)
    [int]$intBool
    if (($StringBool -eq $false) -or ($StringBool -eq $null)) {
        $intBool = 0
    }
    else {
        $intBool = [int]$StringBool
    }
    return $intBool
}

#function to replace a boolean string (empty or 1 or 0) to a checkbox
function SetCheckbox {
param (
    [parameter(Position=0,Mandatory=$true)]
    [ValidateNotNull()]
    [String]
    $StringValue
)
    $unchecked = "☐"
    $checked = "☑"
    
    if(CheckStringBoolean -StringBool $StringValue) {
        return $checked
    }
    else {
        return $unchecked
    }
}

function FixValues {
param (
    [Parameter(Position=0,Mandatory=$true)]
    [ValidateNotNull()]
    $values
)
    [HashTable]$fixedValues = @{}
    [HashTable]$listValues = @{
        "LS1" = "";
        "LS2" = "";
        "LS3" = "";
        "LS4" = "";
        "LS5" = "";
        "LS6" = "";
        "LS7" = "";
        "LS8" = "";
        "LS9" = "";
        "BL1" = "";
        "BL2" = "";
        "BL3" = "";
        "BL4" = "";
        "BL5" = "";
        "BL6" = "";
        "BL7" = "";
        "BL8" = "";
        "BL9" = "";
    }

    foreach ($value in $values.GetEnumerator()) {
        switch (GetElementType -Element $value) {
            0 {
                $fixedValues.Add((GetElementName -Element $value), $value.Value)
            }
            1 {
                $fixedValues.Add((GetElementName -Element $value), $value.Value)
            }
            2 {
                $fixedValues.Add((GetElementName -Element $value), (SetCheckbox -StringValue $value.Value))
            }
            3 {
                "Ignore tables"
            }
            4 {
                $typeKey = $value.Name.SubString(0,3).ToUpper()
                $curValue = $listValues.Get_Item($typeKey)
                if ($curValue -eq "") {
                    $listValues.Set_Item($typeKey, $_.Value)
                }
                else {
                    $listValues.Set_Item($typeKey, "$curValue, $($_.Value)")
                }
            }
            5 {
                $typeKey = $value.Name.SubString(0,3).ToUpper()
                $name = GetElementName -Element $value
                if ((CheckStringBoolean -StringBool $value.Value) -gt 0) {
                    $curValue = $listValues.Get_Item($typeKey)
                    if ($curValue -eq "") {
                        $listValues.Set_Item($typeKey, $name)
                    }
                    else {
                        $listValues.Set_Item($typeKey, "$curValue, $name")
                    }
                }
            }
            default { "Error"}
        }
    }
    foreach ($list in $listValues.GetEnumerator()) {
        $number = $list.Name.Substring(2)
        switch -Wildcard ($list.Name) {
            "LS*" {
                if ($list.Value -ne "") {
                    $fixedValues.Add("List$number", $list.Value)
                }
            }
            "BL*" {
                if ($list.Value -ne "") {
                    $fixedValues.Add("BoolList$number", $list.Value)
                }
            }
        }
    }
    return $fixedValues   
}

function WriteXml {
param (
    [Parameter(Position=0,Mandatory=$true)]
    [ValidateNotNull()]
    $values,

    [Parameter(Position=1,Mandatory=$false)]
    [ValidateNotNull()]
    $AdditionalData
)
    $SavePath = [io.path]::combine($SaveTo, "$(GenerateFileName).xml")
    
    $Encoding = [System.Text.Encoding]::UTF8
	$XmlWriter = New-Object System.XMl.XmlTextWriter($SavePath,$Encoding)
	$XmlWriter.Formatting = 'Indented'
	$XmlWriter.Indentation = 1
	$XmlWriter.IndentChar = "`t"

	$XmlWriter.WriteStartDocument()
    if ($DocGen) {
	    $XmlWriter.WriteStartElement('DocGenData')
	    $XmlWriter.WriteAttributeString('version', "1.0")

	    $XmlWriter.WriteStartElement('Configuration')
		    $XmlWriter.WriteElementString("TemplateFile",$DocGenConfig.Get_Item("TemplateFile"))
		    $XmlWriter.WriteElementString("TempDirectory",$DocGenConfig.Get_Item("TempDestination"))
		    $XmlWriter.WriteElementString("SaveDirectory",$DocGenConfig.Get_Item("SaveDirectory"))
		    $XmlWriter.WriteElementString("MakePDF",$DocGenConfig.Get_Item("MakePDF"))
		    $XmlWriter.WriteElementString("PrintFile",$DocGenConfig.Get_Item("PrintFile"))
		    $XmlWriter.WriteElementString("ExportXML",$DocGenConfig.Get_Item("ExportXml"))
	    $XmlWriter.WriteEndElement()
    
        $XmlWriter.WriteStartElement('AdditionalData')
            foreach ($pair in $AdditionalData.GetEnumerator()) {
                $XmlWriter.WriteStartElement('DataNode')
                    $XmlWriter.WriteElementString('DataName',$pair.Name.ToString())
                    $XmlWriter.WriteElementString('DataValue',$pair.Value.ToString())
                $XmlWriter.WriteEndElement()
            }
	    $XmlWriter.WriteEndElement()

	    $XmlWriter.WriteStartElement('Replacements')
            foreach ($pair in $values.GetEnumerator()) {
                $XmlWriter.WriteStartElement('Replace')
                    $XmlWriter.WriteElementString('Placeholder',$pair.Name.ToString())
                    $XmlWriter.WriteElementString('ReplaceValue',$pair.Value.ToString())
                $XmlWriter.WriteEndElement()
            }
	    $XmlWriter.WriteEndElement()

	    $XmlWriter.WriteEndElement()
    }
    else {
        $XmlWriter.WriteStartElement('XmlConverter')
	    $XmlWriter.WriteAttributeString('version', "1.0")
        
        foreach ($pair in $values.GetEnumerator()) {
            $XmlWriter.WriteElementString($pair.Name.ToString(),$pair.Value.ToString())
        }

        $XmlWriter.WriteEndElement()
    }
	$XmlWriter.WriteEndDocument()
	$XmlWriter.Flush()
	$XmlWriter.Close()

    return $SavePath
}


TraverseTree -XmlDoc $XmlDoc
#uses only first table found, future versions might consider multiple tables
($tables.GetEnumerator() | Select -First 1).Value | %{
    CombineValues -indexData $list -tableValues $_
} | % {
    WriteXml -Values (FixValues -values $_) -AdditionalData $_
}
if ($SaveOriginal) {
    Copy-Item $XmlFile $SaveOriginal
}
Remove-Item $XmlFile
