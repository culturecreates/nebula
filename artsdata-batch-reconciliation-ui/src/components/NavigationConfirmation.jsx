import React from 'react';
import { AlertTriangle } from 'lucide-react';

const NavigationConfirmation = ({ isOpen, onConfirm, onCancel }) => {
  if (!isOpen) return null;

  return (
    <div className="modal-overlay">
      <div className="modal-content">
        <div className="modal-header">
          <AlertTriangle className="warning-icon" />
          <h3>Confirm Navigation</h3>
        </div>
        <div className="modal-body">
          <p>
            You have unsaved work on this page. If you navigate away, your progress will be lost.
          </p>
          <p>Are you sure you want to continue?</p>
        </div>
        <div className="modal-footer">
          <button 
            className="btn btn-secondary" 
            onClick={onCancel}
          >
            Cancel
          </button>
          <button 
            className="btn btn-danger" 
            onClick={onConfirm}
          >
            Continue and lose work
          </button>
        </div>
      </div>
    </div>
  );
};

export default NavigationConfirmation;