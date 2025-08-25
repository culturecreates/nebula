import React, { useEffect } from 'react';
import { CheckCircle } from 'lucide-react';

const AcceptAllSummary = ({ 
  show, 
  onClose, 
  successCounts,
  errorCounts,
  totalProcessed 
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

  const { matched = 0, minted = 0, flagged = 0 } = successCounts || {};
  const { matchErrors = 0, mintErrors = 0, flagErrors = 0 } = errorCounts || {};
  const totalErrors = matchErrors + mintErrors + flagErrors;
  const totalReconciled = matched + minted; // Only matched and minted are reconciled
  const totalSuccess = matched + minted + flagged;

  return (
    <div className="modal fade show" style={{ display: 'block' }} tabIndex="-1">
      <div className="modal-backdrop fade show"></div>
      <div className="modal-dialog modal-dialog-centered" style={{ zIndex: 1051 }}>
        <div className="modal-content">
          <div className="modal-header">
            <h5 className="modal-title">Reconciliation Complete</h5>
          </div>
          <div className="modal-body">
            <div className="text-center mb-4">
              <div className="text-success mb-2">
                <CheckCircle size={40} className="text-success" />
              </div>
              <h6>Processing Complete!</h6>
              <p className="text-muted">Processed {totalProcessed} entities</p>
            </div>

            <div className="row text-center mb-3">
              {totalReconciled > 0 && (
                <div className="col">
                  <div className="card border-success">
                    <div className="card-body py-2">
                      <div className="display-6 text-success">{totalReconciled}</div>
                      <small className="text-muted">Reconciled</small>
                    </div>
                  </div>
                </div>
              )}
              {flagged > 0 && (
                <div className="col">
                  <div className="card border-warning">
                    <div className="card-body py-2">
                      <div className="display-6 text-warning">{flagged}</div>
                      <small className="text-muted">Flagged</small>
                    </div>
                  </div>
                </div>
              )}
              {totalErrors > 0 && (
                <div className="col">
                  <div className="card border-danger">
                    <div className="card-body py-2">
                      <div className="display-6 text-danger">{totalErrors}</div>
                      <small className="text-muted">Errors</small>
                    </div>
                  </div>
                </div>
              )}
            </div>

            <div className="alert alert-info">
              <small>
                The data will be reloaded to show updated results when you close this dialog.
              </small>
            </div>
          </div>
          <div className="modal-footer">
            <button 
              type="button" 
              className="btn btn-primary" 
              onClick={onClose}
            >
              OK - Reload Data
            </button>
          </div>
        </div>
      </div>
    </div>
  );
};

export default AcceptAllSummary;