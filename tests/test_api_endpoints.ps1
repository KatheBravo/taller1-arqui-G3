# Script de validacion rapida de endpoints REST
$baseUrl = "http://127.0.0.1:3000"

Write-Host "========================================================" -ForegroundColor Cyan
Write-Host " Probando Endpoints REST de DecisionRoom G3" -ForegroundColor Cyan
Write-Host "========================================================" -ForegroundColor Cyan

# 1. Healthcheck
Write-Host "`n[1] Verificando salud del servidor (/health)..."
try {
    $res = Invoke-RestMethod -Uri "$baseUrl/health" -Method Get
    Write-Host " -> OK: $($res.status)" -ForegroundColor Green
} catch {
    Write-Host " -> ERROR: No se pudo conectar al servidor. Esta Docker corriendo?" -ForegroundColor Red
    exit 1
}

# 2. Consultar Votacion Actual
Write-Host "`n[2] Consultando estado de la votacion (/polls/1)..."
$poll = Invoke-RestMethod -Uri "$baseUrl/polls/1" -Method Get
Write-Host " -> Titulo: $($poll.poll.title)" -ForegroundColor Yellow
Write-Host " -> Estado: $($poll.poll.status)" -ForegroundColor Yellow
Write-Host " -> Total de Votos: $($poll.total_votes)" -ForegroundColor Yellow

# 3. Emitir Voto Vía REST
$testVoter = "ps_voter_$([guid]::NewGuid().ToString().Substring(0,6))"
Write-Host "`n[3] Emitiendo voto de prueba con votante $testVoter..."
$body = @{
    option_id = "opt_A"
    fingerprint = $testVoter
} | ConvertTo-Json

$voteRes = Invoke-RestMethod -Uri "$baseUrl/polls/1/vote" -Method Post -Body $body -ContentType "application/json"
Write-Host " -> Respuesta: $($voteRes.message)" -ForegroundColor Green
Write-Host " -> Totales actualizados: $($voteRes.data.totals | ConvertTo-Json -Compress)" -ForegroundColor Green

# 4. Probar Rechazo de Voto Duplicado
Write-Host "`n[4] Probando rechazo de voto duplicado con el mismo votante..."
try {
    Invoke-RestMethod -Uri "$baseUrl/polls/1/vote" -Method Post -Body $body -ContentType "application/json"
    Write-Host " -> ERROR: El sistema debio rechazar el voto duplicado." -ForegroundColor Red
} catch {
    Write-Host " -> OK: Rechazado correctamente con codigo $($_.Exception.Response.StatusCode.value__)" -ForegroundColor Green
}

Write-Host "`n========================================================" -ForegroundColor Cyan
Write-Host " Pruebas REST finalizadas con exito." -ForegroundColor Cyan
Write-Host "========================================================" -ForegroundColor Cyan
