import React from "react";
import { AlertTriangle } from "lucide-react";

const TypeSwitchConfirmation = ({
  show,
  onAcceptAll,
  onContinue,
  onCancel,
  currentType,
  newType,
  unsavedCount,
}) => {
  if (!show) return null;

  return (
    <div
      className="position-fixed top-0 start-0 w-100 h-100 d-flex align-items-center justify-content-center bg-dark bg-opacity-50"
      style={{ zIndex: 1055 }}
      role="dialog"
      tabIndex="-1"
    >
      <div
        className="modal-content shadow-lg border-0 rounded-3 bg-white"
        style={{ maxWidth: "550px", width: "90%" }}
      >
        <div className="modal-header border-bottom-0 pb-2 px-4 pt-4 d-flex justify-content-between align-items-center">
          <h5 className="modal-title d-flex align-items-center fw-semibold text-dark mb-0">
            <AlertTriangle className="text-warning me-3" size={24} />
            Switch Entity Type
          </h5>
          <button
            type="button"
            className="btn-close"
            onClick={onCancel}
            aria-label="Close"
          ></button>
        </div>
        <div className="modal-body pt-3 pb-4 px-4">
          <div className="bg-info bg-opacity-10 border border-info border-opacity-25 rounded-2 p-3 mb-3">
            <p className="mb-2 text-dark fs-6">
              <i className="bi bi-info-circle-fill text-info me-2"></i>
              You have <span className="fw-bold text-primary">{unsavedCount}</span> unsaved
              judgment{unsavedCount !== 1 ? "s" : ""} for{" "}
              <span className="fw-bold text-primary">{currentType}</span> entities.
            </p>
          </div>
          <p className="mb-0 text-muted">
            Switching to <span className="fw-bold text-dark">{newType}</span> will clear
            your current work unless you accept all judgments first.
          </p>
        </div>
        <div className="modal-footer border-top-0 pt-2 pb-4 px-4 d-flex flex-wrap gap-2">
          <button
            type="button"
            className="btn btn-success px-3"
            onClick={onAcceptAll}
          >
            <i className="bi bi-check-circle me-2"></i>
            Accept All & Switch
          </button>
          <button
            type="button"
            className="btn btn-outline-warning px-3"
            onClick={onContinue}
          >
            <i className="bi bi-exclamation-triangle me-2"></i>
            Continue & Lose Work
          </button>
          <button
            type="button"
            className="btn btn-secondary px-3"
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
