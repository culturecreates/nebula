import React from 'react';

const ShowAllToggleConfirmation = ({ 
  show, 
  onAcceptAll, 
  onContinue, 
  onCancel, 
  newShowAllValue,
  unsavedCount 
}) => {
  if (!show) return null;

  const actionDescription = newShowAllValue 
    ? "show all entities (including reconciled)" 
    : "hide reconciled entities";

  return (
    <div className="modal show d-block" tabIndex="-1" style={{ backgroundColor: 'rgba(0,0,0,0.5)' }}>
      <div className="modal-dialog modal-dialog-centered">
        <div className="modal-content">
          <div className="modal-header">
            <h5 className="modal-title">Toggle Show All with Unsaved Changes</h5>
          </div>
          <div className="modal-body">
            <div className="alert alert-warning mb-3">
              <strong>⚠️ Warning:</strong> You have {unsavedCount} unsaved judgment{unsavedCount !== 1 ? 's' : ''} that will be lost if you toggle now.
            </div>
            
            <p>You're about to reload the data to <strong>{actionDescription}</strong>.</p>
            
            <p>What would you like to do?</p>
          </div>
          <div className="modal-footer">
            <button 
              type="button" 
              className="btn btn-success" 
              onClick={onAcceptAll}
            >
              Accept All & Toggle
            </button>
            <button 
              type="button" 
              className="btn btn-outline-warning" 
              onClick={onContinue}
            >
              Continue & Lose Work
            </button>
            <button 
              type="button" 
              className="btn btn-secondary" 
              onClick={onCancel}
            >
              Cancel
            </button>
          </div>
        </div>
      </div>
    </div>
  );
};

export default ShowAllToggleConfirmation;