param($wd,$temp,$mix,$hex,$pathStr,$gemini,$model,$sports)
Set-Location $wd
$env:TEMP = $temp
$env:TMP = $temp
$env:MIX_HOME = $mix
$env:HEX_HOME = $hex
$env:PATH = $pathStr
$env:GEMINI_API_KEY = $gemini
$env:GEMINI_MODEL = $model
$env:THESPORTSDB_API_KEY = $sports
& "$env:USERPROFILE\.elixir-install\installs\elixir\1.19.5-otp-28\bin\mix.bat" local.hex --force
& "$env:USERPROFILE\.elixir-install\installs\elixir\1.19.5-otp-28\bin\mix.bat" deps.get
& "$env:USERPROFILE\.elixir-install\installs\elixir\1.19.5-otp-28\bin\mix.bat" phx.server
