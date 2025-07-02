import React from 'react';
import { AlertCircle } from 'lucide-react';

const StatusBadge = ({ status, hasError }) => {
  const getStatusClass = () => {
    switch (status) {
      case 'Match': return 'status-badge status-match';
      case 'Mint person': return 'status-badge status-mint';
      case 'Reconciled': return 'status-badge status-reconciled';
      case 'Skipped': return 'status-badge status-skipped';
      default: return 'status-badge status-default';
    }
  };

  return (
    <div className="status-container">
      <span className={getStatusClass()}>{status}</span>
      {hasError && <AlertCircle className="error-icon" />}
    </div>
  );
};

export default StatusBadge;
