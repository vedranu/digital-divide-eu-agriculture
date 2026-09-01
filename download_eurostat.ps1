# Preuzimanje sirovih Eurostat izvoza koristenih u radu (pristup: kolovoz 2026.)
# Pokretanje iz mape rada:  powershell -ExecutionPolicy Bypass -File .\download_eurostat.ps1
# Napomena: filtrirane datoteke (ef_mp_digi_total.csv, isoc_digskills.csv) i master
# tablice vec su u repozitoriju - ova skripta treba samo za obnovu sirovih izvoza.

$out = Join-Path $PSScriptRoot 'data'
New-Item -ItemType Directory -Force -Path $out | Out-Null

# + 'ef_mp_digicr' po potrebi (109 MB, u radu se ne koristi)
$codes = @('ef_mp_digi', 'isoc_r_iacc_h', 'isoc_ci_in_h', 'isoc_sk_dskl_i21')

foreach ($c in $codes) {
    $u = 'https://ec.europa.eu/eurostat/api/dissemination/sdmx/2.1/data/' + $c + '/?format=SDMX-CSV&compressed=false'
    $f = Join-Path $out ($c + '.csv')
    Write-Host ('Preuzimam ' + $c + ' ...')
    curl.exe -sS -L -o $f $u
    Write-Host ('  ' + $c + ': ' + (Get-Item $f).Length + ' bajtova')
}
Write-Host 'Gotovo.'
