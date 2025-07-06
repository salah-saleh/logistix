import { Controller } from "@hotwired/stimulus"
import { Chart, registerables } from "chart.js"
Chart.register(...registerables);

// Connects to data-controller="sku-history"
export default class extends Controller {
  static targets = [
    "timelineChart", 
    "snapshotsTable", 
    "snapshotsStart", 
    "snapshotsEnd", 
    "snapshotsTotal",
    "prevPage",
    "nextPage",
    "dateFilterStart",
    "dateFilterEnd",
    "modal",
    "modalContent"
  ]

  static values = {
    sku: String,
    currentPage: { type: Number, default: 1 },
    snapshotsPerPage: { type: Number, default: 10 }
  }

  connect() {
    console.log("SKU History controller connected")
    this.loadHistoricalSnapshots()
    this.loadTimeline(30) // Default to 30 days
  }

  // Timeline actions
  timeline7d() {
    this.loadTimeline(7)
  }

  timeline30d() {
    this.loadTimeline(30)
  }

  timeline90d() {
    this.loadTimeline(90)
  }

  // Snapshot actions
  filterSnapshots() {
    this.currentPageValue = 1
    this.loadHistoricalSnapshots()
  }

  prevPage() {
    if (this.currentPageValue > 1) {
      this.currentPageValue--
      this.loadHistoricalSnapshots()
    }
  }

  nextPage() {
    this.currentPageValue++
    this.loadHistoricalSnapshots()
  }

  // Modal actions
  closeModal() {
    this.modalTarget.classList.add("hidden")
  }

  viewSnapshot(event) {
    const snapshotId = event.currentTarget.dataset.snapshotId
    this.loadSnapshotDetails(snapshotId)
  }

  // Private methods
  loadHistoricalSnapshots() {
    const startDate = this.dateFilterStartTarget.value
    const endDate = this.dateFilterEndTarget.value
    
    let url = `/dashboard/snapshots/${this.skuValue}?page=${this.currentPageValue}&per_page=${this.snapshotsPerPageValue}`
    if (startDate) url += `&start_date=${startDate}`
    if (endDate) url += `&end_date=${endDate}`
    
    fetch(url)
      .then(response => response.json())
      .then(data => {
        this.renderSnapshotsTable(data.snapshots)
        this.updatePagination(data.pagination)
      })
      .catch(error => {
        console.error("Error loading snapshots:", error)
        this.showSnapshotsError()
      })
  }

  loadTimeline(days) {
    // Update active button
    this.updateTimelineButtons(days)
    
    fetch(`/dashboard/timeline/${this.skuValue}?days=${days}`)
      .then(response => response.json())
      .then(data => {
        this.renderTimelineChart(data)
      })
      .catch(error => {
        console.error("Error loading timeline:", error)
        this.showTimelineError()
      })
  }

  loadSnapshotDetails(snapshotId) {
    fetch(`/dashboard/snapshot/${snapshotId}`)
      .then(response => response.json())
      .then(data => {
        this.renderSnapshotModal(data)
        this.modalTarget.classList.remove("hidden")
      })
      .catch(error => {
        console.error("Error loading snapshot details:", error)
        this.showModalError()
      })
  }

  renderSnapshotsTable(snapshots) {
    if (snapshots.length === 0) {
      this.snapshotsTableTarget.innerHTML = '<tr><td colspan="7" class="px-6 py-4 text-center text-gray-500">No snapshots found for the selected criteria.</td></tr>'
      return
    }
    
    this.snapshotsTableTarget.innerHTML = snapshots.map(snapshot => `
      <tr class="hover:bg-gray-50">
        <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-900">
          ${new Date(snapshot.snapshot_time).toLocaleString()}
        </td>
        <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-500">${snapshot.quantity_on_shelf}</td>
        <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-500">${snapshot.quantity_sellable}</td>
        <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-500">${snapshot.quantity_reserved_for_orders}</td>
        <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-500">${snapshot.quantity_blocked_by_merchant}</td>
        <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-500">${snapshot.change_owner}</td>
        <td class="px-6 py-4 whitespace-nowrap text-sm font-medium">
          <button data-action="click->sku-history#viewSnapshot" 
                  data-snapshot-id="${snapshot.id}" 
                  class="text-blue-600 hover:text-blue-900">
            View Details
          </button>
        </td>
      </tr>
    `).join("")
  }

  updatePagination(pagination) {
    this.snapshotsStartTarget.textContent = pagination.start
    this.snapshotsEndTarget.textContent = pagination.end
    this.snapshotsTotalTarget.textContent = pagination.total
    
    this.prevPageTarget.disabled = !pagination.has_prev
    this.nextPageTarget.disabled = !pagination.has_next
  }

  updateTimelineButtons(activeDays) {
    // Remove active state from all timeline buttons
    this.element.querySelectorAll('[data-timeline-days]').forEach(btn => {
      btn.classList.remove("bg-blue-100", "text-blue-800")
      btn.classList.add("hover:bg-gray-50")
    })
    
    // Add active state to clicked button
    const activeButton = this.element.querySelector(`[data-timeline-days="${activeDays}"]`)
    if (activeButton) {
      activeButton.classList.add("bg-blue-100", "text-blue-800")
    }
  }

  renderTimelineChart(data) {
    if (!data.timeline_data || data.timeline_data.length === 0) {
      this.timelineChartTarget.innerHTML = `
        <div class="text-center">
          <p class="text-gray-500">No timeline data available for ${data.period_days} days</p>
          <p class="text-sm text-gray-400">Historical data may still be generating</p>
        </div>
      `
      return
    }

    // Prepare data for Chart.js
    const labels = data.timeline_data.map(day => day.date)
    const onShelfData = data.timeline_data.map(day => {
      return Math.round(day.points.reduce((sum, p) => sum + p.quantity_on_shelf, 0) / day.points.length)
    })
    const sellableData = data.timeline_data.map(day => {
      return Math.round(day.points.reduce((sum, p) => sum + p.quantity_sellable, 0) / day.points.length)
    })
    const reservedData = data.timeline_data.map(day => {
      return Math.round(day.points.reduce((sum, p) => sum + p.quantity_reserved_for_orders, 0) / day.points.length)
    })
    const blockedData = data.timeline_data.map(day => {
      return Math.round(day.points.reduce((sum, p) => sum + p.quantity_blocked_by_merchant, 0) / day.points.length)
    })

    // Clean up previous chart if exists
    if (this._timelineChartInstance) {
      this._timelineChartInstance.destroy()
      this._timelineChartInstance = null
    }

    // Render Chart.js canvas
    this.timelineChartTarget.innerHTML = `<canvas data-sku-history-target="timelineChartCanvas" height="180"></canvas>`
    const canvas = this.timelineChartTarget.querySelector('[data-sku-history-target="timelineChartCanvas"]')

    this._timelineChartInstance = new Chart(canvas, {
      type: "line",
      data: {
        labels: labels,
        datasets: [
          {
            label: "On Shelf",
            data: onShelfData,
            borderColor: "#2563eb",
            backgroundColor: "rgba(37,99,235,0.1)",
            tension: 0.3,
            pointRadius: 4,
            pointBackgroundColor: "#2563eb",
            pointBorderColor: "#fff",
            fill: false,
            borderWidth: 2,
            hidden: false // Default visible
          },
          {
            label: "Sellable",
            data: sellableData,
            borderColor: "#22c55e",
            backgroundColor: "rgba(34,197,94,0.1)",
            tension: 0.3,
            pointRadius: 4,
            pointBackgroundColor: "#22c55e",
            pointBorderColor: "#fff",
            fill: false,
            borderWidth: 2,
            hidden: true // Hidden by default
          },
          {
            label: "Reserved",
            data: reservedData,
            borderColor: "#f59e0b",
            backgroundColor: "rgba(245,158,11,0.1)",
            tension: 0.3,
            pointRadius: 4,
            pointBackgroundColor: "#f59e0b",
            pointBorderColor: "#fff",
            fill: false,
            borderWidth: 2,
            hidden: true // Hidden by default
          },
          {
            label: "Blocked",
            data: blockedData,
            borderColor: "#ef4444",
            backgroundColor: "rgba(239,68,68,0.1)",
            tension: 0.3,
            pointRadius: 4,
            pointBackgroundColor: "#ef4444",
            pointBorderColor: "#fff",
            fill: false,
            borderWidth: 2,
            hidden: true // Hidden by default
          }
        ]
      },
      options: {
        plugins: {
          legend: { 
            display: true, 
            position: "bottom",
            onClick: (e, legendItem, legend) => {
              // Custom legend click handler to toggle datasets
              const index = legendItem.datasetIndex
              const ci = legend.chart
              const meta = ci.getDatasetMeta(index)
              
              // Toggle visibility
              meta.hidden = !meta.hidden
              
              // Update legend text style
              legendItem.hidden = meta.hidden
              
              ci.update()
            }
          },
          tooltip: { 
            enabled: true,
            mode: "index",
            intersect: false
          }
        },
        scales: {
          x: {
            display: true,
            title: {
              display: true,
              text: "Date",
              color: "#6b7280",
              font: { size: 14, weight: "bold" }
            },
            grid: {
              display: true,
              color: "#e5e7eb"
            },
            ticks: {
              color: "#6b7280",
              font: { size: 12 }
            }
          },
          y: {
            display: true,
            title: {
              display: true,
              text: "Stock Level",
              color: "#6b7280",
              font: { size: 14, weight: "bold" }
            },
            grid: {
              display: true,
              color: "#e5e7eb"
            },
            ticks: {
              color: "#6b7280",
              font: { size: 12 }
            }
          }
        },
        responsive: true,
        maintainAspectRatio: false,
        interaction: {
          mode: "index",
          intersect: false
        }
      }
    })

    // Show recent days in a horizontal scrollable area
    const recentDays = data.timeline_data.slice(-7)
    let cardsHtml = '<div class="flex gap-3 overflow-x-auto pb-2">'
    recentDays.forEach(day => {
      const avgOnShelf = Math.round(day.points.reduce((sum, p) => sum + p.quantity_on_shelf, 0) / day.points.length)
      const avgSellable = Math.round(day.points.reduce((sum, p) => sum + p.quantity_sellable, 0) / day.points.length)
      const maxOnShelf = Math.max(...day.points.map(p => p.quantity_on_shelf))
      const minOnShelf = Math.min(...day.points.map(p => p.quantity_on_shelf))
      cardsHtml += `
        <div class="min-w-[140px] bg-white border border-gray-200 rounded-lg p-2 shadow-sm flex-shrink-0">
          <div class="text-xs text-gray-500 mb-1">${day.date}</div>
          <div class="flex items-center justify-between text-xs mb-1">
            <span class="text-blue-600 font-bold">${avgOnShelf}</span>
            <span class="text-green-600 font-bold">${avgSellable}</span>
          </div>
          <div class="flex items-center justify-between text-[10px]">
            <span>Max: <span class="text-green-600 font-bold">${maxOnShelf}</span></span>
            <span>Min: <span class="text-red-600 font-bold">${minOnShelf}</span></span>
          </div>
        </div>
      `
    })
    cardsHtml += '</div>'
    this.timelineChartTarget.insertAdjacentHTML('beforeend', cardsHtml)
  }

  renderSnapshotModal(data) {
    let modalHtml = `
      <div class="space-y-6">
        <div class="grid grid-cols-1 md:grid-cols-4 gap-4">
          <div class="bg-blue-50 p-4 rounded-lg">
            <div class="text-sm font-medium text-blue-600">On Shelf</div>
            <div class="text-2xl font-bold text-blue-900">${data.quantity_on_shelf}</div>
          </div>
          <div class="bg-green-50 p-4 rounded-lg">
            <div class="text-sm font-medium text-green-600">Sellable</div>
            <div class="text-2xl font-bold text-green-900">${data.quantity_sellable}</div>
          </div>
          <div class="bg-yellow-50 p-4 rounded-lg">
            <div class="text-sm font-medium text-yellow-600">Reserved</div>
            <div class="text-2xl font-bold text-yellow-900">${data.quantity_reserved_for_orders}</div>
          </div>
          <div class="bg-red-50 p-4 rounded-lg">
            <div class="text-sm font-medium text-red-600">Blocked</div>
            <div class="text-2xl font-bold text-red-900">${data.quantity_blocked_by_merchant}</div>
          </div>
        </div>
    `
    
    // Warehouse Details
    if (data.warehouses && Object.keys(data.warehouses).length > 0) {
      modalHtml += `
        <div class="border-t pt-4">
          <h4 class="font-medium text-gray-900 mb-3">Warehouse Details</h4>
          <div class="space-y-3">
            ${Object.entries(data.warehouses).map(([wh, details]) => {
              let warehouseHtml = `
                <div class="bg-gray-50 p-4 rounded-lg">
                  <div class="font-medium text-gray-700 mb-2">${wh}</div>
                  <div class="grid grid-cols-2 md:grid-cols-4 gap-3 text-sm text-gray-600">
                    <div>On Shelf: <span class="font-medium">${details.quantity_on_shelf}</span></div>
                    <div>Sellable: <span class="font-medium">${details.quantity_sellable}</span></div>
                    <div>Reserved: <span class="font-medium">${details.quantity_reserved_for_orders}</span></div>
                    <div>Blocked: <span class="font-medium">${details.quantity_blocked_by_merchant}</span></div>
                  </div>
              `
              
              // Add batches if they exist
              if (details.batches && Object.keys(details.batches).length > 0) {
                warehouseHtml += `
                  <div class="mt-3 pt-3 border-t border-gray-200">
                    <div class="text-sm font-medium text-gray-600 mb-2">Batches:</div>
                    <div class="space-y-2">
                      ${Object.entries(details.batches).map(([batchId, batch]) => `
                        <div class="bg-white p-2 rounded border">
                          <div class="text-xs font-medium text-gray-700">${batchId}</div>
                          <div class="grid grid-cols-4 gap-2 text-xs text-gray-500 mt-1">
                            <div>On Shelf: ${batch.quantity_on_shelf}</div>
                            <div>Sellable: ${batch.quantity_sellable}</div>
                            <div>Reserved: ${batch.quantity_reserved_for_orders}</div>
                            <div>Blocked: ${batch.quantity_blocked_by_merchant}</div>
                          </div>
                        </div>
                      `).join('')}
                    </div>
                  </div>
                `
              }
              
              // Add variants if they exist
              if (details.variants && Object.keys(details.variants).length > 0) {
                warehouseHtml += `
                  <div class="mt-3 pt-3 border-t border-gray-200">
                    <div class="text-sm font-medium text-gray-600 mb-2">Variants:</div>
                    <div class="space-y-2">
                      ${Object.entries(details.variants).map(([variantId, variant]) => `
                        <div class="bg-white p-2 rounded border">
                          <div class="text-xs font-medium text-gray-700">${variantId}</div>
                          <div class="grid grid-cols-4 gap-2 text-xs text-gray-500 mt-1">
                            <div>On Shelf: ${variant.quantity_on_shelf}</div>
                            <div>Sellable: ${variant.quantity_sellable}</div>
                            <div>Reserved: ${variant.quantity_reserved_for_orders}</div>
                            <div>Blocked: ${variant.quantity_blocked_by_merchant}</div>
                          </div>
                        </div>
                      `).join('')}
                    </div>
                  </div>
                `
              }
              
              warehouseHtml += '</div>'
              return warehouseHtml
            }).join('')}
          </div>
        </div>
      `
    }
    
    // Top-level Batches (if they exist)
    if (data.batches && Object.keys(data.batches).length > 0) {
      modalHtml += `
        <div class="border-t pt-4">
          <h4 class="font-medium text-gray-900 mb-3">Top-level Batches</h4>
          <div class="space-y-2">
            ${Object.entries(data.batches).map(([batchId, batch]) => `
              <div class="bg-gray-50 p-3 rounded-lg">
                <div class="font-medium text-gray-700 mb-2">${batchId}</div>
                <div class="grid grid-cols-2 md:grid-cols-4 gap-3 text-sm text-gray-600">
                  <div>On Shelf: <span class="font-medium">${batch.quantity_on_shelf}</span></div>
                  <div>Sellable: <span class="font-medium">${batch.quantity_sellable}</span></div>
                  <div>Reserved: <span class="font-medium">${batch.quantity_reserved_for_orders}</span></div>
                  <div>Blocked: <span class="font-medium">${batch.quantity_blocked_by_merchant}</span></div>
                </div>
              </div>
            `).join('')}
          </div>
        </div>
      `
    }
    
    // Top-level Variants (if they exist)
    if (data.variants && Object.keys(data.variants).length > 0) {
      modalHtml += `
        <div class="border-t pt-4">
          <h4 class="font-medium text-gray-900 mb-3">Top-level Variants</h4>
          <div class="space-y-2">
            ${Object.entries(data.variants).map(([variantId, variant]) => `
              <div class="bg-gray-50 p-3 rounded-lg">
                <div class="font-medium text-gray-700 mb-2">${variantId}</div>
                <div class="grid grid-cols-2 md:grid-cols-4 gap-3 text-sm text-gray-600">
                  <div>On Shelf: <span class="font-medium">${variant.quantity_on_shelf}</span></div>
                  <div>Sellable: <span class="font-medium">${variant.quantity_sellable}</span></div>
                  <div>Reserved: <span class="font-medium">${variant.quantity_reserved_for_orders}</span></div>
                  <div>Blocked: <span class="font-medium">${variant.quantity_blocked_by_merchant}</span></div>
                </div>
              </div>
            `).join('')}
          </div>
        </div>
      `
    }
    
    modalHtml += `
        <div class="border-t pt-4">
          <div class="text-sm text-gray-500">
            <div>Snapshot Time: ${new Date(data.snapshot_time).toLocaleString()}</div>
            <div>Change Owner: ${data.change_owner}</div>
          </div>
        </div>
      </div>
    `
    
    this.modalContentTarget.innerHTML = modalHtml
  }

  showSnapshotsError() {
    this.snapshotsTableTarget.innerHTML = '<tr><td colspan="7" class="px-6 py-4 text-center text-red-600">Error loading snapshots. Please try again.</td></tr>'
  }

  showTimelineError() {
    this.timelineChartTarget.innerHTML = `
      <div class="text-center">
        <p class="text-red-600">Error loading timeline data</p>
        <p class="text-sm text-gray-400">Please try again later</p>
      </div>
    `
  }

  showModalError() {
    this.modalContentTarget.innerHTML = `
      <div class="text-center text-red-600">
        <p>Error loading snapshot details</p>
        <p class="text-sm text-gray-500 mt-2">Please try again later</p>
      </div>
    `
    this.modalTarget.classList.remove("hidden")
  }
} 