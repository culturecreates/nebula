import React from "react";
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
  if (!isOpen) return null;

  return (
    <div
      className="position-fixed top-0 start-0 w-100 h-100 d-flex align-items-center justify-content-center bg-dark bg-opacity-50"
      style={{ zIndex: 1055 }}
      role="dialog"
      tabIndex="-1"
    >
      <div
        className="modal-content shadow-lg border-0 rounded-3"
        style={{ maxWidth: "500px", width: "90%" }}
      >
        <div className="modal-header border-bottom-0 pb-2 px-4 pt-4 d-flex justify-content-between align-items-center">
          <h5 className="modal-title d-flex align-items-center fw-semibold text-dark mb-0">
            <AlertTriangle className="text-warning me-3" size={24} />
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
        <div className="modal-body pt-3 pb-4 px-4">
          <p className="mb-3 text-muted fs-6">
            Select the entity type and confirm minting for:
          </p>
          <div className="bg-light border rounded-2 p-3 mb-3">
            <p className="fw-bold mb-0 text-dark">{entityName}</p>
          </div>
          <div className="mb-3">
            <label className="form-label fw-semibold text-dark">Entity Type</label>
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
            <div className="alert alert-danger border-0 rounded-2 mb-0" role="alert">
              <i className="bi bi-exclamation-triangle-fill me-2"></i>
              <strong>Error:</strong> {error}
            </div>
          )}
        </div>
        <div className="modal-footer border-top-0 pt-2 pb-4 px-4">
          <button
            type="button"
            className="btn btn-secondary me-2"
            onClick={onCancel}
            disabled={isLoading}
          >
            Cancel
          </button>
          <button
            type="button"
            className="btn btn-success px-4"
            onClick={handleConfirm}
            disabled={isLoading || error || !selectedType}
          >
            {isLoading && (
              <span
                className="spinner-border spinner-border-sm me-2"
                role="status"
              >
                <span className="visually-hidden">Loading...</span>
              </span>
            )}
            {isLoading ? "Checking..." : selectedType ? `Mint ${selectedType}` : "Select Type"}
          </button>
        </div>
      </div>
    </div>
  );
};

export default MintConfirmPopup;
