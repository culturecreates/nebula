import React from 'react';
import { AlertCircle } from 'lucide-react';

const StatusBadge = ({ status, hasError, autoMatched, mintError, entityType }) => {
  const getStatusClass = () => {
    switch (status) {
      case 'needs-judgment': return 'status-badge status-needs-judgment';
      case 'judgment-ready': return 'status-badge status-judgment-ready';
      case 'mint-ready': return 'status-badge status-mint-ready';
      case 'reconciled': return 'status-badge status-reconciled';
      case 'mint-error': return 'status-badge status-mint-error';
      case 'skipped': return 'status-badge status-skipped';
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
      case 'needs-judgment': return 'Select';
      case 'judgment-ready': return 'Match';
      case 'mint-ready': return `Mint ${entityType || 'Entity'}`;
      case 'reconciled': return 'Reconciled';
      case 'mint-error': return `Mint ${entityType || 'Entity'}`;
      case 'skipped': return 'Skipped';
      default: return status;
    }
  };

  return (
    <div className="status-container">
      <span className={getStatusClass()}>
        {autoMatched && status === 'Auto-matched' ? '✓ Auto-matched' : getStatusText()}
      </span>
      {(hasError || mintError) && (
        <AlertCircle 
          className="error-icon" 
          title={mintError || "Error occurred"}
        />
      )}
    </div>
  );
};

export default StatusBadge;
