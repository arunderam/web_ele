# PowerShell script to test deployment and debug issues
Write-Host "=== Website Deployment Test Script ===" -ForegroundColor Green

# Check if Docker is installed
Write-Host "`n1. Checking Docker installation..." -ForegroundColor Yellow
try {
    $dockerVersion = docker --version
    Write-Host "SUCCESS: Docker found: $dockerVersion" -ForegroundColor Green

    # Build the Docker image
    Write-Host "`n2. Building Docker image..." -ForegroundColor Yellow
    docker build -t website-ele:latest .

    if ($LASTEXITCODE -eq 0) {
        Write-Host "SUCCESS: Docker image built successfully" -ForegroundColor Green

        # Stop any existing container
        Write-Host "`n3. Stopping existing containers..." -ForegroundColor Yellow
        docker stop website-ele 2>$null
        docker rm website-ele 2>$null

        # Run the container
        Write-Host "`n4. Starting container..." -ForegroundColor Yellow
        docker run -d -p 8080:80 --name website-ele website-ele:latest

        if ($LASTEXITCODE -eq 0) {
            Write-Host "SUCCESS: Container started successfully" -ForegroundColor Green

            # Wait a moment for container to start
            Start-Sleep -Seconds 3

            # Test health endpoint
            Write-Host "`n5. Testing health endpoint..." -ForegroundColor Yellow
            try {
                $health = Invoke-WebRequest -Uri "http://localhost:8080/health" -UseBasicParsing
                Write-Host "SUCCESS: Health check passed: $($health.StatusCode)" -ForegroundColor Green
            } catch {
                Write-Host "ERROR: Health check failed: $($_.Exception.Message)" -ForegroundColor Red
            }

            # Test main page
            Write-Host "`n6. Testing main page..." -ForegroundColor Yellow
            try {
                $mainPage = Invoke-WebRequest -Uri "http://localhost:8080" -UseBasicParsing
                Write-Host "SUCCESS: Main page loaded: $($mainPage.StatusCode)" -ForegroundColor Green
                Write-Host "   Page size: $($mainPage.Content.Length) bytes" -ForegroundColor Cyan
            } catch {
                Write-Host "ERROR: Main page failed: $($_.Exception.Message)" -ForegroundColor Red
            }

            # Show container logs
            Write-Host "`n7. Container logs:" -ForegroundColor Yellow
            docker logs website-ele

            Write-Host "`nSUCCESS: Website is running at: http://localhost:8080" -ForegroundColor Green
            Write-Host "INFO: To view logs: docker logs website-ele" -ForegroundColor Cyan
            Write-Host "INFO: To stop: docker stop website-ele" -ForegroundColor Cyan

        } else {
            Write-Host "ERROR: Failed to start container" -ForegroundColor Red
        }
    } else {
        Write-Host "ERROR: Failed to build Docker image" -ForegroundColor Red
    }

} catch {
    Write-Host "ERROR: Docker not found. Please install Docker Desktop:" -ForegroundColor Red
    Write-Host "   https://www.docker.com/products/docker-desktop/" -ForegroundColor Cyan

    # Fallback to Python server
    Write-Host "`nINFO: Trying Python fallback server..." -ForegroundColor Yellow
    try {
        $pythonVersion = python --version
        Write-Host "SUCCESS: Python found: $pythonVersion" -ForegroundColor Green
        Write-Host "INFO: Starting server on port 8080..." -ForegroundColor Green
        Write-Host "SUCCESS: Website will be at: http://localhost:8080" -ForegroundColor Green
        python -m http.server 8080
    } catch {
        Write-Host "ERROR: Python also not found. Please install Python or Docker." -ForegroundColor Red
    }
}
