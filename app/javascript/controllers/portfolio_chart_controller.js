import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = {
    dataUrl: String
  }

  connect() {
    this.initializeChart()
  }

  disconnect() {
    if (this.chart) {
      if (this.resizeObserver) {
        this.resizeObserver.disconnect()
      }
      this.chart.remove()
      this.chart = null
    }
  }

  async initializeChart() {
    const container = this.element
    if (!container) return

    // Access Lightweight Charts from global scope (standalone script pattern)
    const { LightweightCharts } = window
    if (!LightweightCharts || typeof LightweightCharts.createChart !== 'function') {
      console.error('Lightweight Charts not loaded. Ensure lightweight-charts.standalone.production.js is loaded.')
      container.innerHTML = '<p class="text-muted text-center py-5">Chart library failed to load.</p>'
      return
    }

    const createChart = LightweightCharts.createChart

    // Create chart with proper options per TradingView tutorial
    this.chart = createChart(container, {
      width: container.clientWidth,
      height: 400,
      layout: {
        background: { color: '#ffffff' },
        textColor: '#1e293b'
      },
      grid: {
        vertLines: { color: '#e2e8f0' },
        horzLines: { color: '#e2e8f0' }
      },
      rightPriceScale: {
        scaleMargins: { top: 0.1, bottom: 0.1 }
      },
      timeScale: {
        timeVisible: true,
        secondsVisible: false
      }
    })

    // Create three area series for comparison
    const portfolioSeries = this.chart.addAreaSeries({
      title: 'Portfolio',
      lineColor: '#3b82f6',
      topColor: 'rgba(59,130,246,0.2)',
      bottomColor: 'rgba(59,130,246,0)',
      lineWidth: 2
    })

    const nasdaqSeries = this.chart.addAreaSeries({
      title: 'NASDAQ',
      lineColor: '#3b82f6',
      topColor: 'rgba(59,130,246,0.2)',
      bottomColor: 'rgba(59,130,246,0)',
      lineWidth: 2
    })

    const sp500Series = this.chart.addAreaSeries({
      title: 'S&P 500',
      lineColor: '#8b5cf6',
      topColor: 'rgba(139,92,246,0.2)',
      bottomColor: 'rgba(139,92,246,0)',
      lineWidth: 2
    })

    // Fetch data from backend
    let chartData
    try {
      const dataUrl = this.dataUrlValue || '/portfolios/chart_data'
      const response = await fetch(dataUrl, {
        headers: { 'Accept': 'application/json' },
        cache: 'no-cache'
      })
      
      if (!response.ok) {
        throw new Error(`HTTP ${response.status}`)
      }
      
      chartData = await response.json()
      
      // Validate data structure
      if (!chartData || 
          !Array.isArray(chartData.portfolio) || 
          !Array.isArray(chartData.nasdaq) || 
          !Array.isArray(chartData.sp500) ||
          chartData.portfolio.length === 0) {
        throw new Error('Invalid data structure')
      }
      
      // Validate each data point has required fields
      const isValid = chartData.portfolio.every(point => 
        typeof point.time === 'number' && typeof point.value === 'number'
      )
      
      if (!isValid) {
        throw new Error('Invalid data format')
      }
      
    } catch (error) {
      console.warn('Failed to load chart data from server, using fallback data:', error)
      chartData = this.generateFallbackData()
    }

    // Set data to series
    portfolioSeries.setData(chartData.portfolio)
    nasdaqSeries.setData(chartData.nasdaq)
    sp500Series.setData(chartData.sp500)

    // Fit content to show all data
    this.chart.timeScale().fitContent()

    // Handle window resize
    this.resizeObserver = new ResizeObserver(() => {
      if (container.clientWidth > 0) {
        this.chart.applyOptions({ width: container.clientWidth })
      }
    })
    this.resizeObserver.observe(container)
  }

  generateFallbackData() {
    const now = Math.floor(Date.now() / 1000)
    const days = 365
    const portfolio = []
    const nasdaq = []
    const sp500 = []
    
    let portfolioValue = 420000
    let nasdaqValue = 12000
    let sp500Value = 4000
    
    for (let i = days - 1; i >= 0; i--) {
      const time = now - (i * 86400) // Unix timestamp in seconds
      
      // Portfolio with upward trend
      const portfolioChange = (Math.random() - 0.4) * 0.02
      portfolioValue *= (1 + portfolioChange)
      
      // NASDAQ with upward trend
      const nasdaqChange = (Math.random() - 0.4) * 0.02
      nasdaqValue *= (1 + nasdaqChange)
      
      // S&P 500 with upward trend
      const sp500Change = (Math.random() - 0.4) * 0.02
      sp500Value *= (1 + sp500Change)
      
      portfolio.push({ time: time, value: Math.round(portfolioValue) })
      nasdaq.push({ time: time, value: Math.round(nasdaqValue) })
      sp500.push({ time: time, value: Math.round(sp500Value) })
    }
    
    return { portfolio, nasdaq, sp500 }
  }
}

