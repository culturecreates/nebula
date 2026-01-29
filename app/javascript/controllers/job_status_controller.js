import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["container", "processingIcon", "processingText", "queueBadge", "queueCount"]

  connect() {
    // Only poll in production and staging environments
    const shouldPoll = this.element.dataset.jobStatusShouldPollValue === "true"
    
    if (shouldPoll) {
      this.poll()
      this.pollInterval = setInterval(() => this.poll(), 10000) // Poll every 10 seconds
    }
  }

  disconnect() {
    if (this.pollInterval) {
      clearInterval(this.pollInterval)
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
      this.showProcessing(artifact)
    } else {
      this.hideProcessing()
    }

    // Show queue badge
    if (hasQueued) {
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

  showProcessing(artifact) {
    if (this.hasProcessingIconTarget && this.hasProcessingTextTarget) {
      this.processingIconTarget.classList.remove('d-none')
      this.processingTextTarget.classList.remove('d-none')
      this.processingTextTarget.textContent = artifact || 'Processing...'
    }
  }

  hideProcessing() {
    if (this.hasProcessingIconTarget && this.hasProcessingTextTarget) {
      this.processingIconTarget.classList.add('d-none')
      this.processingTextTarget.classList.add('d-none')
    }
  }

  showQueue(count, artifacts) {
    if (this.hasQueueBadgeTarget && this.hasQueueCountTarget) {
      this.queueBadgeTarget.classList.remove('d-none')
      this.queueCountTarget.textContent = count
      
      // Update popover content with artifacts list
      const content = artifacts.length > 0 
        ? artifacts.map(a => `<div>${a}</div>`).join('')
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
