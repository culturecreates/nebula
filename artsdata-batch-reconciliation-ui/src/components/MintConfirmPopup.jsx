import React from "react";
import { createPortal } from "react-dom";
import { AlertTriangle } from "lucide-react";

const MintConfirmPopup = ({
  isOpen,
  entityType,
  entityName,
  onConfirm,
  onCancel,
  isLoading,
  error,
}) => {
  // Smart type matching function
  const getMatchingType = (entityType) => {
    const availableTypes = ['Event', 'Person', 'Organization', 'Place'];
    const normalizedEntityType = entityType?.split('/').pop(); // Handle schema.org URLs
    return availableTypes.includes(normalizedEntityType) ? normalizedEntityType : null;
  };

  const [selectedType, setSelectedType] = React.useState(() => {
    return getMatchingType(entityType) || '';
  });
  
  // Update selected type when entityType prop changes
  React.useEffect(() => {
    setSelectedType(getMatchingType(entityType) || '');
  }, [entityType]);
  
  const handleConfirm = () => {
    onConfirm(selectedType);
  };
  
  // Disable background scrolling when modal is open
  React.useEffect(() => {
    if (isOpen) {
      document.body.style.overflow = 'hidden';
    } else {
      document.body.style.overflow = 'unset';
    }
    
    // Cleanup on unmount
    return () => {
      document.body.style.overflow = 'unset';
    };
  }, [isOpen]);
  
  if (!isOpen) return null;

  // Use React Portal to render modal at document body level with proper Bootstrap structure
  return createPortal(
    <>
      <div className="modal-backdrop fade show"></div>
      <div className="modal fade show" style={{ display: 'block' }} tabIndex="-1">
        <div className="modal-dialog modal-dialog-centered">
          <div className="modal-content">
            <div className="modal-header">
              <h5 className="modal-title d-flex align-items-center">
                <AlertTriangle className="text-warning me-2" size={20} />
                Mint New Entity
              </h5>
              <button
                type="button"
                className="btn-close"
                onClick={onCancel}
                disabled={isLoading}
                aria-label="Close"
              ></button>
            </div>
            <div className="modal-body">
              <p className="mb-3">
                Select the entity type and confirm minting for:
              </p>
              <div className="bg-light border rounded p-3 mb-3">
                <strong>{entityName}</strong>
              </div>
              <div className="mb-3">
                <label className="form-label">Entity Type</label>
                <select 
                  className="form-select"
                  value={selectedType}
                  onChange={(e) => setSelectedType(e.target.value)}
                  disabled={isLoading}
                >
                  {!getMatchingType(entityType) && (
                    <option value="">Select a type...</option>
                  )}
                  <option value="Event">Event</option>
                  <option value="Person">Person</option>
                  <option value="Organization">Organization</option>
                  <option value="Place">Place</option>
                </select>
              </div>
              {error && (
                <div className="alert alert-danger" role="alert">
                  <strong>Error:</strong> {error}
                </div>
              )}
            </div>
            <div className="modal-footer">
              <button
                type="button"
                className="btn btn-secondary"
                onClick={onCancel}
                disabled={isLoading}
              >
                Cancel
              </button>
              <button
                type="button"
                className="btn btn-success"
                onClick={handleConfirm}
                disabled={isLoading || error || !selectedType}
              >
                {isLoading && (
                  <span
                    className="spinner-border spinner-border-sm me-2"
                    role="status"
                    aria-hidden="true"
                  ></span>
                )}
                {isLoading ? "Checking..." : selectedType ? `Mint ${selectedType}` : "Select Type"}
              </button>
            </div>
          </div>
        </div>
      </div>
    </>,
    document.body
  );
};

export default MintConfirmPopup;
