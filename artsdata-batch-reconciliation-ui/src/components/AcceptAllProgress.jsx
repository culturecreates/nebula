import React, { useEffect } from 'react';
import { CheckCircle } from 'lucide-react';

const AcceptAllProgress = ({ 
  show, 
  currentAction, 
  currentEntity, 
  processedCount, 
  totalCount,
  isComplete 
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

  const progressPercentage = totalCount > 0 ? Math.round((processedCount / totalCount) * 100) : 0;

  return (
    <div className="modal fade show" style={{ display: 'block' }} tabIndex="-1" data-bs-backdrop="static" data-bs-keyboard="false">
      <div className="modal-backdrop fade show"></div>
      <div className="modal-dialog modal-dialog-centered" style={{ zIndex: 1051 }}>
        <div className="modal-content">
          <div className="modal-header">
            <h5 className="modal-title">
              {isComplete ? 'Processing Complete' : 'Processing Entities...'}
            </h5>
          </div>
          <div className="modal-body">
            {!isComplete ? (
              <>
                <div className="d-flex justify-content-between align-items-center mb-3">
                  <span>Progress: {processedCount} of {totalCount}</span>
                  <span className="badge bg-primary">{progressPercentage}%</span>
                </div>
                
                <div className="progress mb-3">
                  <div 
                    className="progress-bar" 
                    role="progressbar" 
                    style={{ width: `${progressPercentage}%` }}
                    aria-valuenow={progressPercentage} 
                    aria-valuemin="0" 
                    aria-valuemax="100"
                  ></div>
                </div>
                
                {currentAction && currentEntity && (
                  <div className="current-processing">
                    <small className="text-muted">
                      Currently {currentAction}: <strong>{currentEntity}</strong>
                    </small>
                  </div>
                )}
                
                <div className="d-flex justify-content-center mt-3">
                  <div className="spinner-border text-primary" role="status">
                    <span className="visually-hidden">Processing...</span>
                  </div>
                </div>
              </>
            ) : (
              <div className="text-center">
                <div className="text-success mb-3">
                  <CheckCircle size={48} className="text-success" />
                </div>
                <p className="mb-0">All entities have been processed successfully!</p>
              </div>
            )}
          </div>
          {!isComplete && (
            <div className="modal-footer">
              <div className="text-muted">
                <small>Please wait while we process your entities...</small>
              </div>
            </div>
          )}
        </div>
      </div>
    </div>
  );
};

export default AcceptAllProgress;