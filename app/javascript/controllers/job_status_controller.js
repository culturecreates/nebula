import { Controller } from "@hotwired/stimulus"
import * as bootstrap from "bootstrap"

export default class extends Controller {
  static targets = ["processingIcon", "processingText", "queueBadge", "queueCount"]
  static values = { 
    shouldPoll: String,
    loadingText: String
  }

  connect() {
    // Only poll in production and staging environments
    const shouldPoll = this.shouldPollValue === "true"
    
    if (shouldPoll) {
      this.poll()
      this.pollInterval = setInterval(() => this.poll(), 10000) // Poll every 10 seconds
    }
    
    // Store processing job start time
    this.processingStartTime = null
  }

  disconnect() {
    if (this.pollInterval) {
      clearInterval(this.pollInterval)
    }
    
    // Clean up any active popovers
    if (this.hasProcessingIconTarget) {
      const popover = bootstrap.Popover.getInstance(this.processingIconTarget)
      if (popover) {
        popover.dispose()
      }
    }
    
    if (this.hasQueueBadgeTarget) {
      const popover = bootstrap.Popover.getInstance(this.queueBadgeTarget)
      if (popover) {
        popover.dispose()
      }
    }
  }

  async poll() {
    try {
      const response = await fetch('/job_status')
      if (!response.ok) {
        console.error('Failed to fetch job status')
        return
      }
      
      const data = await response.json()
      this.updateUI(data)
    } catch (error) {
      console.error('Error fetching job status:', error)
    }
  }

  updateUI(data) {
    const processing = data.processing || []
    const queues = data.queues || []
    const defaultQueue = queues.find(q => q.name === 'default') || { jobs: [] }
    const queuedJobs = defaultQueue.jobs || []

    // Check if we should show anything
    const hasProcessing = processing.length > 0
    const hasQueued = queuedJobs.length > 0

    if (!hasProcessing && !hasQueued) {
      this.hideAll()
      return
    }

    // Show processing job
    if (hasProcessing) {
      const job = processing[0]
      const artifact = this.extractArtifact(job)
      const startTime = this.extractStartTime(job)
      this.showProcessing(artifact, startTime)
    } else {
      this.hideProcessing()
    }

    // Show queue badge - only if there are actually jobs in the queue
    if (hasQueued && queuedJobs.length > 0) {
      const artifacts = queuedJobs.map(job => this.extractArtifact(job)).filter(a => a)
      this.showQueue(queuedJobs.length, artifacts)
    } else {
      this.hideQueue()
    }
  }

  extractArtifact(job) {
    try {
      // Navigate through the job structure to find the artifact
      const args = job.args || []
      if (args.length > 0 && args[0].arguments && args[0].arguments.length > 0) {
        return args[0].arguments[0].artifact
      }
    } catch (error) {
      console.error('Error extracting artifact:', error)
    }
    return null
  }

  extractStartTime(job) {
    try {
      // Extract the run_at timestamp (Unix timestamp)
      return job.run_at
    } catch (error) {
      console.error('Error extracting start time:', error)
    }
    return null
  }

  calculateElapsedTime(startTime) {
    if (!startTime) return ''
    
    const now = Math.floor(Date.now() / 1000) // Current time in seconds
    const elapsed = now - startTime
    
    const minutes = Math.floor(elapsed / 60)
    const seconds = elapsed % 60
    
    if (minutes > 0) {
      return `${minutes}m ${seconds}s`
    } else {
      return `${seconds}s`
    }
  }

  showProcessing(artifact, startTime) {
    if (this.hasProcessingIconTarget && this.hasProcessingTextTarget) {
      this.processingIconTarget.classList.remove('d-none')
      this.processingTextTarget.classList.remove('d-none')
      this.processingTextTarget.textContent = artifact || 'Processing...'
      
      // Update processing start time if new job
      if (startTime && this.processingStartTime !== startTime) {
        this.processingStartTime = startTime
      }
      
      // Create or update popover for processing indicator
      const loadingText = this.loadingTextValue || 'Data feed loading'
      const elapsedTime = this.calculateElapsedTime(this.processingStartTime)
      const popoverContent = `${loadingText}<br><small>${elapsedTime}</small>`
      
      const popover = bootstrap.Popover.getInstance(this.processingIconTarget)
      if (popover) {
        popover.dispose()
      }
      new bootstrap.Popover(this.processingIconTarget, {
        content: popoverContent,
        html: true,
        trigger: 'hover focus',
        placement: 'bottom'
      })
    }
  }

  hideProcessing() {
    if (this.hasProcessingIconTarget && this.hasProcessingTextTarget) {
      this.processingIconTarget.classList.add('d-none')
      this.processingTextTarget.classList.add('d-none')
      
      // Reset processing start time
      this.processingStartTime = null
      
      // Dispose popover if exists
      const popover = bootstrap.Popover.getInstance(this.processingIconTarget)
      if (popover) {
        popover.dispose()
      }
    }
  }

  showQueue(count, artifacts) {
    if (this.hasQueueBadgeTarget && this.hasQueueCountTarget) {
      this.queueBadgeTarget.classList.remove('d-none')
      this.queueCountTarget.textContent = count
      
      // Update popover content with artifacts list (sanitized)
      const content = artifacts.length > 0 
        ? artifacts.map(a => {
            const div = document.createElement('div')
            div.textContent = a // Uses textContent to prevent XSS
            return div.outerHTML
          }).join('')
        : '<div>No artifacts in queue</div>'
      
      // Initialize or update Bootstrap popover
      const popover = bootstrap.Popover.getInstance(this.queueBadgeTarget)
      if (popover) {
        popover.dispose()
      }
      new bootstrap.Popover(this.queueBadgeTarget, {
        content: content,
        html: true,
        trigger: 'hover focus',
        placement: 'bottom'
      })
    }
  }

  hideQueue() {
    if (this.hasQueueBadgeTarget) {
      this.queueBadgeTarget.classList.add('d-none')
      
      // Dispose popover if exists
      const popover = bootstrap.Popover.getInstance(this.queueBadgeTarget)
      if (popover) {
        popover.dispose()
      }
    }
  }

  hideAll() {
    this.hideProcessing()
    this.hideQueue()
  }
}
