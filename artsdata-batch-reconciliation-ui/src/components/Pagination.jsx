import React from 'react';

const Pagination = ({ currentPage, onPageChange }) => {
  // Show current page and next 3 pages (total 4 pages)
  const pagesToShow = [];
  for (let i = 0; i < 4; i++) {
    pagesToShow.push(currentPage + i);
  }

  return (
    <div className="pagination">
      <button
        onClick={() => onPageChange(currentPage - 1)}
        disabled={currentPage === 1}
        className="pagination-btn pagination-nav"
      >
        «
      </button>
      {pagesToShow.map(pageNum => (
        <button
          key={pageNum}
          onClick={() => onPageChange(pageNum)}
          className={`pagination-btn ${currentPage === pageNum ? 'pagination-active' : ''}`}
        >
          {pageNum}
        </button>
      ))}
      <button
        onClick={() => onPageChange(currentPage + 1)}
        className="pagination-btn pagination-nav"
      >
        »
      </button>
    </div>
  );
};

export default Pagination;
