import React, { useEffect, useRef } from 'react';
import { AlertCircle, Flag } from 'lucide-react';
import { Tooltip } from 'bootstrap';

const StatusBadge = ({ status, hasError, autoMatched, mintError, linkError, entityType, isFlaggedForReview }) => {
  const tooltipRef = useRef(null);
  const tooltipInstanceRef = useRef(null);
  const getStatusClass = () => {
    switch (status) {
      case 'needs-judgment': return 'status-badge status-needs-judgment';
      case 'judgment-ready': return 'status-badge status-judgment-ready';
      case 'mint-ready': return 'status-badge status-mint-ready';
      case 'reconciled': return 'status-badge status-reconciled';
      case 'mint-error': return 'status-badge status-mint-error';
      case 'link-error': return 'status-badge status-link-error';
      case 'flagged': return 'status-badge status-flagged';
      case 'flagged-complete': return 'status-badge status-needs-judgment'; // Same styling as needs-judgment
      // Legacy statuses for backward compatibility
      case 'Match': return 'status-badge status-match';
      case 'Mint person': return 'status-badge status-mint';
      case 'Linked': return 'status-badge status-linked';
      case 'Auto-matched': return 'status-badge status-auto-matched';
      default: return 'status-badge status-default';
    }
  };

  const getStatusText = () => {
    switch (status) {
      case 'needs-judgment': return <span className="fs-3">Select</span>;
      case 'judgment-ready': return 'Match';
      case 'mint-ready': return `Mint ${entityType || 'Entity'}`;
      case 'reconciled': return 'Reconciled';
      case 'mint-error': return `Mint ${entityType || 'Entity'}`;
      case 'link-error': return 'Link Error';
      case 'flagged': return 'Needs review';
      case 'flagged-complete': return <span className="fs-3">Select</span>;
      default: return status;
    }
  };

  // Format error message as HTML bullet list for tooltip
  const formatErrorMessageHTML = (errorMsg) => {
    if (!errorMsg) return '';

    // Check if error message contains newlines (indicating multiple errors)
    if (errorMsg.includes('\n')) {
      // Split by newlines and format as HTML bullet list
      const lines = errorMsg.split('\n').filter(line => line.trim());

      // If first line is a header (e.g., "Validation failed:"), keep it separate
      if (lines.length > 1 && lines[0].toLowerCase().includes('validation failed')) {
        const header = lines[0];
        const bullets = lines.slice(1)
          .map(line => `<li style="text-align: left; margin-bottom: 4px;">${line}</li>`)
          .join('');
        return `<div style="text-align: left;"><strong>${header}</strong><ul style="margin: 8px 0 0 0; padding-left: 20px;">${bullets}</ul></div>`;
      } else {
        // All lines are errors, add as bullet list
        const bullets = lines
          .map(line => `<li style="text-align: left; margin-bottom: 4px;">${line}</li>`)
          .join('');
        return `<ul style="margin: 0; padding-left: 20px; text-align: left;">${bullets}</ul>`;
      }
    }

    // Single line error, return as-is
    return errorMsg;
  };

  const errorMessage = linkError || mintError || "Error occurred";
  const formattedErrorMessageHTML = formatErrorMessageHTML(errorMessage);

  // Initialize Bootstrap tooltip when error message changes
  useEffect(() => {
    if (tooltipRef.current && (hasError || mintError || linkError)) {
      // Dispose of existing tooltip if it exists
      if (tooltipInstanceRef.current) {
        tooltipInstanceRef.current.dispose();
      }

      // Create new tooltip with HTML content
      tooltipInstanceRef.current = new Tooltip(tooltipRef.current, {
        title: formattedErrorMessageHTML,
        html: true,
        placement: 'top',
        trigger: 'hover focus',
        container: 'body',
        customClass: 'validation-error-tooltip'
      });

      // Cleanup function
      return () => {
        if (tooltipInstanceRef.current) {
          tooltipInstanceRef.current.dispose();
          tooltipInstanceRef.current = null;
        }
      };
    }
  }, [hasError, mintError, linkError, formattedErrorMessageHTML]);

  return (
    <div className="status-container">
      <span className={getStatusClass()}>
        {autoMatched && status === 'Auto-matched' ? '✓ Auto-matched' : getStatusText()}
      </span>
      {(hasError || mintError || linkError) && (
        <AlertCircle
          ref={tooltipRef}
          className="error-icon"
          style={{ cursor: 'pointer' }}
        />
      )}
    </div>
  );
};

export default StatusBadge;
