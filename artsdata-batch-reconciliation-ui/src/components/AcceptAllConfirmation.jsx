import React, { useEffect } from 'react';

const AcceptAllConfirmation = ({ 
  show, 
  onConfirm, 
  onCancel, 
  matchCount, 
  mintCount, 
  flagCount, 
  totalCount 
}) => {
  // Disable background scrolling when modal is open
  useEffect(() => {
    if (show) {
      document.body.style.overflow = 'hidden';
    } else {
      document.body.style.overflow = 'unset';
    }
    
    // Cleanup on unmount
    return () => {
      document.body.style.overflow = 'unset';
    };
  }, [show]);

  if (!show) return null;

  return (
    <>
      <div className="modal-backdrop fade show"></div>
      <div className="modal fade show" style={{ display: 'block' }} tabIndex="-1">
        <div className="modal-dialog modal-dialog-centered">
        <div className="modal-content">
          <div className="modal-header">
            <h5 className="modal-title">Accept All Judgments</h5>
          </div>
          <div className="modal-body">
            <p>You are about to process <strong>{totalCount}</strong> entities with the following actions:</p>
            
            <ul className="list-unstyled">
              {matchCount > 0 && (
                <li className="mb-2">
                  <span className="badge bg-primary me-2">{matchCount}</span>
                  <strong>Match</strong> - Link to existing Artsdata entities
                </li>
              )}
              {mintCount > 0 && (
                <li className="mb-2">
                  <span className="badge bg-success me-2">{mintCount}</span>
                  <strong>Mint New</strong> - Create new Artsdata entities
                </li>
              )}
              {flagCount > 0 && (
                <li className="mb-2">
                  <span className="badge bg-warning me-2">{flagCount}</span>
                  <strong>Flag</strong> - Mark entities for review
                </li>
              )}
            </ul>
            
            <div className="alert alert-info">
              <small>
                <strong>Note:</strong> This will process all ready judgments on the current page. 
                The operation cannot be undone.
              </small>
            </div>
          </div>
          <div className="modal-footer">
            <button 
              type="button" 
              className="btn btn-secondary" 
              onClick={onCancel}
            >
              Cancel
            </button>
            <button 
              type="button" 
              className="btn btn-primary" 
              onClick={onConfirm}
            >
              OK - Process {totalCount} Entities
            </button>
          </div>
        </div>
        </div>
      </div>
    </>
  );
};

export default AcceptAllConfirmation;