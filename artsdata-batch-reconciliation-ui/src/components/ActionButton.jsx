import React from "react";

const ActionButton = ({ status, onAction }) => {
  if (status === "Select") {
    return (
      <div className="action-buttons">
        <button onClick={() => onAction("mint_new")} className="action-link">
          mint new
        </button>
        <button onClick={() => onAction("skip")} className="action-link">
          skip
        </button>
      </div>
    );
  }

  if (["Match", "Mint person", "Skipped"].includes(status)) {
    return (
      <button onClick={() => onAction("change")} className="action-link">
        change
      </button>
    );
  }

  return null;
};

export default ActionButton;
