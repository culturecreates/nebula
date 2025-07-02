import React from 'react';

const Pagination = ({ currentPage, totalPages, onPageChange }) => (
  <div className="pagination">
    <button
      onClick={() => onPageChange(currentPage - 1)}
      disabled={currentPage === 1}
      className="pagination-btn pagination-nav"
    >
      «
    </button>
    {[...Array(totalPages)].map((_, i) => (
      <button
        key={i+1}
        onClick={() => onPageChange(i+1)}
        className={`pagination-btn ${currentPage === i+1 ? 'pagination-active' : ''}`}
      >
        {i+1}
      </button>
    ))}
    <button
      onClick={() => onPageChange(currentPage + 1)}
      disabled={currentPage === totalPages}
      className="pagination-btn pagination-nav"
    >
      »
    </button>
  </div>
);

export default Pagination;
