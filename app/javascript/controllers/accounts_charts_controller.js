import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = {
    dataUrl: String
  }

  connect() {
    this.initializeChart()
  }

  async initializeChart() {
    const canvas = this.element.querySelector('canvas')
    if (!canvas) return

    const ctx = canvas.getContext('2d')

    // Mock data to match requirements since backend might differ
    const data = {
      labels: ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun'],
      datasets: [
        {
          label: 'Net Cash Flow',
          data: [750, 1000, 500, 1400, 1450, 1720],
          backgroundColor: '#10b981', // Green
          borderRadius: 4,
          barPercentage: 0.6,
          categoryPercentage: 0.8
        },
        {
          label: 'Credit Balance',
          data: [-450, -500, -600, -400, -550, -480],
          backgroundColor: '#ef4444', // Red
          borderRadius: 4,
          barPercentage: 0.6,
          categoryPercentage: 0.8
        }
      ]
    }

    new Chart(ctx, {
      type: 'bar',
      data: data,
      options: {
        responsive: true,
        maintainAspectRatio: false,
        plugins: {
          legend: { 
            position: 'bottom',
            labels: { usePointStyle: true, padding: 20, font: { size: 12 } }
          },
          tooltip: {
            backgroundColor: '#fff',
            titleColor: '#1f2937',
            bodyColor: '#1f2937',
            borderColor: '#e5e7eb',
            borderWidth: 1,
            padding: 12,
            cornerRadius: 8,
            callbacks: {
              label: (context) => ` ${context.dataset.label}: $${Math.abs(context.parsed.y).toLocaleString()}`
            }
          }
        },
        scales: {
          x: {
            grid: { display: false },
            ticks: { color: '#94a3b8', font: { size: 12 } }
          },
          y: {
            border: { display: false },
            grid: { color: '#f1f5f9' },
            ticks: { 
              color: '#94a3b8', 
              font: { size: 12 },
              callback: (value) => `$${value}`
            }
          }
        }
      }
    })
  }
}
