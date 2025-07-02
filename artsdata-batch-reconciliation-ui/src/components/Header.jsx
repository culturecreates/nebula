import React from 'react';

const Header = ({ onAcceptAll, totalItems }) => (
  <div className="header">
    <div className="header-content">
      <h1 className="header-title">Artsdata Batch Reconciliation</h1>
      <button onClick={onAcceptAll} className="btn btn-primary">
        Accept all ({totalItems})
      </button>
    </div>
  </div>
);

export default Header;
