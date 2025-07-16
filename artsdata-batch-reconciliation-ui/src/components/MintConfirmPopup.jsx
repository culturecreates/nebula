import React from 'react';
import { AlertTriangle } from 'lucide-react';

const MintConfirmPopup = ({ isOpen, entityType, entityName, onConfirm, onCancel, isLoading, error }) => {
  if (!isOpen) return null;

  return (
    <div className="modal-overlay">
      <div className="modal-content">
        <div className="modal-header">
          <AlertTriangle className="warning-icon" />
          <h3>Confirm Mint {entityType}</h3>
        </div>
        <div className="modal-body">
          <p>Are you sure you want to mint a new {entityType.toLowerCase()} for:</p>
          <p><strong>{entityName}</strong></p>
          {error && (
            <div className="error-message" style={{ marginTop: '1rem' }}>
              {error}
            </div>
          )}
        </div>
        <div className="modal-footer">
          <button 
            className="btn btn-secondary" 
            onClick={onCancel}
            disabled={isLoading}
          >
            Cancel
          </button>
          <button 
            className="btn btn-primary" 
            onClick={onConfirm}
            disabled={isLoading || error}
          >
            {isLoading ? 'Checking...' : `Mint ${entityType}`}
          </button>
        </div>
      </div>
    </div>
  );
};

export default MintConfirmPopup;