# XmlGenerator
Allows creation of multiple XML files from a XML-file containing a table.
Originally created for the DocGen module to create multiple word-documents from a single xml datafile and word-template.

Why?
I had a system exporting one XML-file containing a table with values.
I needed one file per row but could not get the producing system to create this.
Later on I also had the need to generate documents based on this data.

What?
If you have a XML-file containing a table, it will create one XML-file for each row in the table.
This file will contain the specific row data combined with the data outside of the table.
If you have tags beginning with certain values it will change those values according to the table below.
XML-format does not matter, it only takes leaf-elements and tables. No attributes are considered.

The script will pipe the full paths of generates files to console if you wish to use these files further in the same script.

Tags beginning with:
*Str- (<Str-TagName>) will be treated as a String (So will tags that does not have any of these values) and will not be reformatted
*Bol- (<Bol-TagName> will be treated as a boolean and replaced by a checkbox that is filled depending on the value
                     (empty=false, false, true, 1 or 0)
*Tbl- (<Tbl-TagName>) will be a table. It only uses the first table it finds and ignores others.
*LsX- (<LS1-TagName> the X is a number between 1-9. Each of these tags represent a list where it will remove all the tags
                     and replace them with one tag containing the combined values as a list.
                     i.e. <Ls1-tag1>m</Ls1-tag1><Ls1-tag2>o</Ls1-tag2><Ls1-tag3>o</Ls1-tag3> would become <List1>m,o,o</List1>
*BlX (<BL1-TagName> the X is a number between 1-9. Each of these tags represent a list where it will remove all the tags
                     and replace them with one tag containing the combined tagnames as a booleanlist.
                     i.e. <BL1-tag1>1</BL1-tag1><BL1-tag2>0</BL1-tag2><BL1-tag3>1</BL1-tag3> 
                     would become <BoolList1>tag1,tag3</BoolList1>
                     
Script Arguments:
-XmlFile (Required): [String] Path to the XML-file to read.
-SaveTo (Required): [String] The container to save the generated XML-files to.
-SaveOriginal: [String] Path to container if you wish to save the original XML-file, otherwise it will be deleted.
-DocGen: [Bool] If you wish to generate XML in the DocGen-format
-DocGenConfig: [HashTable] @{
        "TemplateFile" = [String] Where is the word-template
        "TempDestination" = [String] What destination to use as a temp-dir
        "SaveDirectory" = [String] Where to save files
        "MakePDF" = [Bool] Save as PDF or docx?
        "PrintFile" = [Bool] Print to default printer?
        "ExportXml" = [Bool] Export xmlfile with document?
    }
    
Example usage:
  $script = "C:\path\to\script\xmlconverter.ps1"
  $args = "-XmlFile `"C:\path\to\xml\file.xml`" -SaveTo `"C:\xml`""
  iex "& `"$script`" $args"
