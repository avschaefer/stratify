import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["netWorthChart", "allocationChart", "cashFlowChart"]
  static values = {
    allocationData: Object
  }

  connect() {
    this.renderNetWorthChart()
    this.renderAllocationChart()
    this.renderCashFlowChart()
  }

  renderNetWorthChart() {
    if (!this.hasNetWorthChartTarget) return

    const ctx = this.netWorthChartTarget.getContext('2d')
    
    // Mock data from requirements
    const data = {
      labels: ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun'],
      datasets: [{
        label: 'Net Worth',
        data: [120000, 123500, 131000, 129500, 137000, 142500],
        borderColor: '#2563eb',
        backgroundColor: (context) => {
          const ctx = context.chart.ctx;
          const gradient = ctx.createLinearGradient(0, 0, 0, 300);
          gradient.addColorStop(0, 'rgba(37, 99, 235, 0.1)');
          gradient.addColorStop(1, 'rgba(37, 99, 235, 0)');
          return gradient;
        },
        borderWidth: 2,
        fill: true,
        tension: 0.4,
        pointRadius: 0,
        pointHoverRadius: 6
      }]
    }

    new Chart(ctx, {
      type: 'line',
      data: data,
      options: {
        responsive: true,
        maintainAspectRatio: false,
        plugins: {
          legend: { display: false },
          tooltip: {
            mode: 'index',
            intersect: false,
            backgroundColor: '#fff',
            titleColor: '#1f2937',
            bodyColor: '#1f2937',
            borderColor: '#e5e7eb',
            borderWidth: 1,
            padding: 12,
            cornerRadius: 8,
            callbacks: {
              label: (context) => `$${context.parsed.y.toLocaleString()}`
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
              callback: (value) => `$${value/1000}k`
            }
          }
        },
        interaction: {
          mode: 'nearest',
          axis: 'x',
          intersect: false
        }
      }
    })
  }

  renderAllocationChart() {
    if (!this.hasAllocationChartTarget) return

    const ctx = this.allocationChartTarget.getContext('2d')
    
    // Use passed value if available, otherwise mock
    // The backend provides a hash: { "Stocks" => 123, "Bonds" => 456 }
    let labels, values, colors;

    if (this.hasAllocationDataValue && Object.keys(this.allocationDataValue).length > 0) {
       labels = Object.keys(this.allocationDataValue);
       values = Object.values(this.allocationDataValue);
       // Generate colors dynamically if needed, or map standard ones
       colors = ['#2563eb', '#059669', '#d97706', '#7c3aed', '#475569'];
    } else {
       // Mock data
       labels = ['Stocks', 'Bonds', 'Real Estate', 'Crypto', 'Cash'];
       values = [85000, 15000, 45000, 5000, 10000];
       colors = ['#2563eb', '#059669', '#d97706', '#7c3aed', '#475569'];
    }

    new Chart(ctx, {
      type: 'bar', // Changed to bar for horizontal bar chart
      data: {
        labels: labels,
        datasets: [{
          data: values,
          backgroundColor: colors,
          borderWidth: 0,
          borderRadius: 4,
          barPercentage: 0.6,
          categoryPercentage: 0.8
        }]
      },
      options: {
        indexAxis: 'y', // Makes it horizontal
        responsive: true,
        maintainAspectRatio: false,
        plugins: {
          legend: { display: false },
          tooltip: {
            backgroundColor: '#fff',
            titleColor: '#1f2937',
            bodyColor: '#1f2937',
            borderColor: '#e5e7eb',
            borderWidth: 1,
            padding: 12,
            cornerRadius: 8,
            callbacks: {
              label: (context) => ` ${context.label}: $${context.parsed.x.toLocaleString()}` // x is value in horizontal bar
            }
          }
        },
        scales: {
          x: {
            grid: { display: false },
            ticks: { display: false } // Hide x axis labels
          },
          y: {
            grid: { display: false },
            ticks: { 
              color: '#64748b',
              font: { size: 12, weight: 500 }
            },
            border: { display: false }
          }
        }
      }
    })
  }

  renderCashFlowChart() {
    if (!this.hasCashFlowChartTarget) return

    const ctx = this.cashFlowChartTarget.getContext('2d')

    // Mock data from requirements
    // Use green/red as requested for savings page style visual
    const data = {
      labels: ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun'],
      datasets: [
        {
          label: 'Net Cash Flow',
          data: [3200, 3300, 2900, 3700, 4000, 4100],
          backgroundColor: '#10b981',
          borderRadius: 4,
          barPercentage: 0.6,
          categoryPercentage: 0.8
        },
        {
          label: 'Expenses', // Showing negative for visual balance
          data: [-5300, -4900, -6200, -5100, -5500, -5100],
          backgroundColor: '#ef4444',
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
              callback: (value) => `$${Math.abs(value)/1000}k`
            }
          }
        }
      }
    })
  }
}
