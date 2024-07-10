
$ori = @{}
Try {
  $i = 0
  # Loading .env files
  if(Test-Path $args[0]) {
    foreach($line in (Get-Content $args[0])) {
      if($line -Match '^\s*$' -Or $line -Match '^#') {
        continue
      }

      $key, $val = $line.Split("=")
      $ori[$key] = if(Test-Path Env:\$key) { (Get-Item Env:\$key).Value } else { "" }
      New-Item -Name $key -Value $val -ItemType Variable -Path Env: -Force > $null
    }

    $i++
  }

  while(1) {
    if($i -ge $args.length) {
      exit
    }

    # Stop look  on first argument without '=' sign
    # if(!($args[$i] -Match '^[^ ]+=[^ ]+$')) {
    if(!($args[$i] -Match '.+=.*')) {
      break
    }

    $index = $args[$i].IndexOf('=')
    $key = $args[$i].Substring(0, $index)
    $val = $args[$i].Substring($index + 1)
    $ori[$key] = if(Test-Path Env:\$key) { (Get-Item Env:\$key).Value } else { "" }
    $val = if ($val.Contains(' ')) { "'$val'" } else { $val }
    New-Item -Name $key -Value $val -ItemType Variable -Path Env: -Force > $null

    $i++
  }

  # Skip key=value pairs until real command for invokation
  $command = $args[$i..$args.length]

  # Write-Host "$command"
  Invoke-Expression "$command"
} Finally {
  foreach($key in $ori.Keys) {
    New-Item -Name $key -Value $ori.Item($key) -ItemType Variable -Path Env: -Force > $null
  }
}
