import React from 'react';

const TypeSwitchConfirmation = ({ 
  show, 
  onAcceptAll, 
  onContinue, 
  onCancel, 
  currentType, 
  newType, 
  unsavedCount 
}) => {
  if (!show) return null;

  return (
    <div className="modal-overlay">
      <div className="modal-content">
        <div className="modal-header">
          <svg className="warning-icon" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-2.5L13.732 4c-.77-.833-1.684-.833-2.464 0L3.34 16.5c-.77.833.192 2.5 1.732 2.5z" />
          </svg>
          <h3>Switch Entity Type</h3>
        </div>
        <div className="modal-body">
          <p>
            You have <strong>{unsavedCount}</strong> unsaved judgment{unsavedCount !== 1 ? 's' : ''} for <strong>{currentType}</strong> entities.
          </p>
          <p>
            Switching to <strong>{newType}</strong> will clear your current work unless you accept all judgments first.
          </p>
        </div>
        <div className="modal-footer">
          <button 
            className="btn btn-primary" 
            onClick={onAcceptAll}
          >
            Accept All & Switch
          </button>
          <button 
            className="btn btn-secondary" 
            onClick={onContinue}
          >
            Continue & Lose Work
          </button>
          <button 
            className="btn btn-tertiary" 
            onClick={onCancel}
          >
            Cancel
          </button>
        </div>
      </div>
    </div>
  );
};

export default TypeSwitchConfirmation;