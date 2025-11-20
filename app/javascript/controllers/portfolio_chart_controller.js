import { Controller } from "@hotwired/stimulus"

// Remove duplicate controller code and fallback generator

// Keep only the version without random data

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

    const { LightweightCharts } = window
    if (!LightweightCharts || typeof LightweightCharts.createChart !== 'function') {
      console.error('Lightweight Charts not loaded. Ensure lightweight-charts.standalone.production.js is loaded.')
      container.innerHTML = '<p class="text-muted text-center py-5">Chart library failed to load.</p>'
      return
    }

    const createChart = LightweightCharts.createChart

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

    let chartData = { portfolio: [], nasdaq: [], sp500: [] }

    try {
      const dataUrl = this.dataUrlValue || '/portfolios/chart_data'
      const response = await fetch(dataUrl, {
        headers: { 'Accept': 'application/json' },
        cache: 'no-cache'
      })

      if (!response.ok) {
        throw new Error(`HTTP ${response.status}`)
      }

      const raw = await response.json()

      // Accept responses that only contain portfolio data.
      const portfolio = Array.isArray(raw.portfolio) ? raw.portfolio : []
      const nasdaq = Array.isArray(raw.nasdaq) ? raw.nasdaq : []
      const sp500 = Array.isArray(raw.sp500) ? raw.sp500 : []

      chartData = {
        portfolio: portfolio.map(p => ({
          time: Number(p.time),
          value: Number(p.value)
        })),
        nasdaq: nasdaq.map(p => ({
          time: Number(p.time),
          value: Number(p.value)
        })),
        sp500: sp500.map(p => ({
          time: Number(p.time),
          value: Number(p.value)
        }))
      }
    } catch (error) {
      console.error('Failed to load chart data from server:', error)
      // Show empty chart if no data
      chartData = { portfolio: [], nasdaq: [], sp500: [] }
      // Optionally add a message
      container.innerHTML = '<p class="text-muted text-center py-5">No chart data available. Please add holdings and update prices.</p>'
    }

    portfolioSeries.setData(chartData.portfolio)
    nasdaqSeries.setData(chartData.nasdaq)
    sp500Series.setData(chartData.sp500)

    if (chartData.portfolio.length > 0) {
      this.chart.timeScale().fitContent()
    }

    this.resizeObserver = new ResizeObserver(() => {
      if (container.clientWidth > 0) {
        this.chart.applyOptions({ width: container.clientWidth })
      }
    })
    this.resizeObserver.observe(container)
  }
}

