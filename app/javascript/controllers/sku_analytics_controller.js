// app/javascript/controllers/sku_analytics_controller.js
// Stimulus controller for SKU analytics charts (timeline and pie charts)
// Handles Chart.js initialization, updates, and teardown for the analytics section
// Reads analytics data from a data attribute or hidden element
//
// Requires Chart.js to be available globally (imported in your JS pack)

import { Controller } from "@hotwired/stimulus"
import { Chart, registerables } from "chart.js"
Chart.register(...registerables);

export default class extends Controller {
  static targets = [
    "timelineChart",
    "ordersPie",
    "returnsPie",
    "velocityPie",
    "runwayPie",
    "weekSelect",
    "data"
  ]

  connect() {
    // Parse analytics data from the hidden element or data attribute
    this.analyticsData = JSON.parse(this.dataTarget.value)
    this.initCharts()
  }

  disconnect() {
    // Clean up charts when the controller is disconnected
    this.destroyCharts()
  }

  // Initialize all charts
  initCharts() {
    this.destroyCharts()
    const data = this.analyticsData
    // Prepare timeline data
    const timelineLabels = data.map(a => `${a.week_start} - ${a.week_end}`)
    const ordersData = data.map(a => a.orders_total)
    const returnsData = data.map(a => a.returns_total)
    const velocityData = data.map(a => a.velocity_total_per_day)
    const runwayData = data.map(a => a.runway_total_days)

    // Timeline chart
    this.timelineChartInstance = new Chart(this.timelineChartTarget.getContext("2d"), {
      type: "line",
      data: {
        labels: timelineLabels,
        datasets: [
          { label: "Orders", data: ordersData, borderColor: "#2563eb", backgroundColor: "#93c5fd", fill: false, pointRadius: 4, pointHoverRadius: 6 },
          { label: "Returns", data: returnsData, borderColor: "#dc2626", backgroundColor: "#fca5a5", fill: false, pointRadius: 4, pointHoverRadius: 6 },
          { label: "Velocity", data: velocityData, borderColor: "#059669", backgroundColor: "#6ee7b7", fill: false, pointRadius: 4, pointHoverRadius: 6 },
          { label: "Runway", data: runwayData, borderColor: "#f59e42", backgroundColor: "#fde68a", fill: false, pointRadius: 4, pointHoverRadius: 6 }
        ]
      },
      options: {
        responsive: true,
        plugins: {
          legend: { position: "top" },
          annotation: { annotations: {} }
        },
        scales: { x: { title: { display: true, text: "Week" } }, y: { title: { display: true, text: "Value" } } },
        onClick: (e, elements) => {
          if (elements.length > 0) {
            const idx = elements[0].index
            this.weekSelectTarget.value = idx
            this.updatePieCharts(idx)
            this.highlightTimelinePoint(idx)
          }
        }
      }
    })

    // Pie charts
    this.ordersPieInstance = new Chart(this.ordersPieTarget.getContext("2d"), {
      type: "pie",
      data: { labels: [], datasets: [{ data: [], backgroundColor: ["#2563eb", "#059669", "#f59e42"] }] },
      options: { responsive: false, plugins: { legend: { position: "bottom" } } }
    })
    this.returnsPieInstance = new Chart(this.returnsPieTarget.getContext("2d"), {
      type: "pie",
      data: { labels: [], datasets: [{ data: [], backgroundColor: ["#dc2626", "#f59e42", "#059669"] }] },
      options: { responsive: false, plugins: { legend: { position: "bottom" } } }
    })
    this.velocityPieInstance = new Chart(this.velocityPieTarget.getContext("2d"), {
      type: "pie",
      data: { labels: [], datasets: [{ data: [], backgroundColor: ["#059669", "#2563eb", "#f59e42", "#dc2626", "#fbbf24"] }] },
      options: { responsive: false, plugins: { legend: { position: "bottom" } } }
    })
    this.runwayPieInstance = new Chart(this.runwayPieTarget.getContext("2d"), {
      type: "pie",
      data: { labels: [], datasets: [{ data: [], backgroundColor: ["#f59e42", "#059669", "#2563eb", "#dc2626", "#fbbf24"] }] },
      options: { responsive: false, plugins: { legend: { position: "bottom" } } }
    })

    // Initial update
    this.updatePieCharts(0)
    this.weekSelectTarget.value = 0
    this.weekSelectTarget.addEventListener("change", (e) => {
      this.updatePieCharts(parseInt(e.target.value))
    })
  }

  // Update pie charts for the selected week
  updatePieCharts(idx) {
    const a = this.analyticsData[idx]
    // Orders by channel
    this.ordersPieInstance.data.labels = Object.keys(a.orders_by_channel)
    this.ordersPieInstance.data.datasets[0].data = Object.values(a.orders_by_channel)
    this.ordersPieInstance.update()
    // Returns by channel
    this.returnsPieInstance.data.labels = Object.keys(a.returns_by_channel)
    this.returnsPieInstance.data.datasets[0].data = Object.values(a.returns_by_channel)
    this.returnsPieInstance.update()
    // Velocity by warehouse
    this.velocityPieInstance.data.labels = Object.keys(a.velocity_by_warehouse)
    this.velocityPieInstance.data.datasets[0].data = Object.values(a.velocity_by_warehouse)
    this.velocityPieInstance.update()
    // Runway by warehouse
    this.runwayPieInstance.data.labels = Object.keys(a.runway_by_warehouse)
    this.runwayPieInstance.data.datasets[0].data = Object.values(a.runway_by_warehouse)
    this.runwayPieInstance.update()
    // Highlight timeline point
    this.highlightTimelinePoint(idx)
  }

  // Highlight a point in the timeline chart
  highlightTimelinePoint(idx) {
    if (!this.timelineChartInstance) return
    this.timelineChartInstance.data.datasets.forEach((ds, i) => {
      ds.pointBackgroundColor = ds.data.map((_, j) => j === idx ? "#f59e42" : ds.borderColor)
      ds.pointRadius = ds.data.map((_, j) => j === idx ? 8 : 4)
    })
    this.timelineChartInstance.update()
  }

  // Destroy all chart instances
  destroyCharts() {
    if (this.timelineChartInstance) { this.timelineChartInstance.destroy(); this.timelineChartInstance = null }
    if (this.ordersPieInstance) { this.ordersPieInstance.destroy(); this.ordersPieInstance = null }
    if (this.returnsPieInstance) { this.returnsPieInstance.destroy(); this.returnsPieInstance = null }
    if (this.velocityPieInstance) { this.velocityPieInstance.destroy(); this.velocityPieInstance = null }
    if (this.runwayPieInstance) { this.runwayPieInstance.destroy(); this.runwayPieInstance = null }
  }
} 