import React from 'react';
import { AlertCircle, Flag } from 'lucide-react';

const StatusBadge = ({ status, hasError, autoMatched, mintError, linkError, entityType, isFlaggedForReview }) => {
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

  return (
    <div className="status-container">
      <span className={getStatusClass()}>
        {autoMatched && status === 'Auto-matched' ? '✓ Auto-matched' : getStatusText()}
      </span>
      {(hasError || mintError || linkError) && (
        <AlertCircle 
          className="error-icon" 
          title={linkError || mintError || "Error occurred"}
        />
      )}
    </div>
  );
};

export default StatusBadge;
