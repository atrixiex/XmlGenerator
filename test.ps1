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
    Log "Error sending pipe $pipeName message: $_"
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

$pipeName = ""
$message = ""