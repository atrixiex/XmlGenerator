Function Send-PipeMessage () {
  Param(
    [Parameter(Mandatory=$true)]
    [String]$PipeName,          # Named pipe name
    [Parameter(Mandatory=$true)]
    [String]$Message            # Message string
  )
  $PipeDir  = [System.IO.Pipes.PipeDirection]::Out
  $PipeOpt  = [System.IO.Pipes.PipeOptions]::Asynchronous

  $pipe = $null # Named pipe stream
  $sw = $null   # Stream Writer
  try {
    $pipe = new-object System.IO.Pipes.NamedPipeClientStream(".", $PipeName, $PipeDir, $PipeOpt)
    $sw = new-object System.IO.StreamWriter($pipe)
    $pipe.Connect(1000)
    if (!$pipe.IsConnected) {
      throw "Failed to connect client to pipe $pipeName"
    }
    $sw.AutoFlush = $true
    $sw.WriteLine($Message)
  } catch {
    Write-Host "Error sending pipe $pipeName message: $_"
  } finally {
    if ($sw) {
      $sw.Dispose() # Release resources
      $sw = $null   # Force the PowerShell garbage collector to delete the .net object
    }
    if ($pipe) {
      $pipe.Dispose() # Release resources
      $pipe = $null   # Force the PowerShell garbage collector to delete the .net object
    }
  }
}

$pipeName = "Service_XmlConverterService"
$message = @{
        Module = 'XmlConverter'
        In = 'C:\Program Files\XmlConverterService\In\74.xml'
        Out = 'C:\Program Files\XmlConverterService\Out'
        Profile = 'Flatten'
    }

$test = ""


foreach ($pair in $message.GetEnumerator()) {
    $value = $pair.Value -Replace '\\', '\\'
    $test += "$($pair.Name)=$value<\n>"
}
$dir = "C:\Users\Bobo\Documents\Scripts\XmlGenerator\PSService.ps1"

& $dir -Remove
sleep 5
& $dir -Setup
sleep 5
& $dir -Start
sleep 2

Send-PipeMessage -PipeName $pipeName -Message "Meow"

sleep 2
type 'C:\Program Files\XmlConverterService\Logs\XmlConverterService.log'

& $dir -Stop