import React from "react";
import { AlertTriangle } from "lucide-react";

const NavigationConfirmation = ({ isOpen, onConfirm, onCancel }) => {
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
            Confirm Navigation
          </h5>
          <button
            type="button"
            className="btn-close"
            onClick={onCancel}
            aria-label="Close"
          ></button>
        </div>
        <div className="modal-body pt-3 pb-4 px-4">
          <div className="bg-warning bg-opacity-10 border border-warning border-opacity-25 rounded-2 p-3 mb-3">
            <p className="mb-2 text-dark fs-6">
              <i className="bi bi-exclamation-triangle-fill text-warning me-2"></i>
              You have unsaved work on this page. If you navigate away, your progress will be lost.
            </p>
          </div>
          <p className="mb-0 text-muted">Are you sure you want to continue?</p>
        </div>
        <div className="modal-footer border-top-0 pt-2 pb-4 px-4">
          <button
            type="button"
            className="btn btn-secondary me-2"
            onClick={onCancel}
          >
            Cancel
          </button>
          <button 
            type="button" 
            className="btn btn-danger px-4" 
            onClick={onConfirm}
          >
            <i className="bi bi-exclamation-triangle me-2"></i>
            Continue and lose work
          </button>
        </div>
      </div>
    </div>
  );
};

export default NavigationConfirmation;
