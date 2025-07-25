import React from 'react';

const SearchConfirmation = ({ 
  show, 
  onAcceptAll, 
  onContinue, 
  onCancel, 
  currentDataFeed, 
  currentType,
  newDataFeed, 
  newType,
  unsavedCount 
}) => {
  if (!show) return null;

  const hasDataFeedChange = currentDataFeed !== newDataFeed;
  const hasTypeChange = currentType !== newType;

  return (
    <div className="modal show d-block" tabIndex="-1" style={{ backgroundColor: 'rgba(0,0,0,0.5)' }}>
      <div className="modal-dialog modal-dialog-centered">
        <div className="modal-content">
          <div className="modal-header">
            <h5 className="modal-title">Search with Unsaved Changes</h5>
          </div>
          <div className="modal-body">
            <div className="alert alert-warning mb-3">
              <strong>⚠️ Warning:</strong> You have {unsavedCount} unsaved judgment{unsavedCount !== 1 ? 's' : ''} that will be lost if you search now.
            </div>
            
            <p>You're about to search with:</p>
            <ul className="mb-3">
              {hasDataFeedChange && (
                <li>
                  <strong>Data Feed:</strong> {newDataFeed}
                  {currentDataFeed && <small className="text-muted"> (was: {currentDataFeed})</small>}
                </li>
              )}
              {hasTypeChange && (
                <li>
                  <strong>Type:</strong> {newType}
                  {currentType && <small className="text-muted"> (was: {currentType})</small>}
                </li>
              )}
              {!hasDataFeedChange && !hasTypeChange && (
                <li><strong>Data Feed:</strong> {newDataFeed}</li>
              )}
              {!hasDataFeedChange && !hasTypeChange && (
                <li><strong>Type:</strong> {newType}</li>
              )}
            </ul>
            
            <p>What would you like to do?</p>
          </div>
          <div className="modal-footer">
            <button 
              type="button" 
              className="btn btn-success" 
              onClick={onAcceptAll}
            >
              Accept All & Search
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

export default SearchConfirmation;