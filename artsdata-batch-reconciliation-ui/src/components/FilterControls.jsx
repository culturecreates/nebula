import React from 'react';
import { getAvailableTypes } from '../services/dataFeedService';
import Pagination from './Pagination';

const FilterControls = ({ 
  dataFeed, setDataFeed, type, setType, minScore, setMinScore, showAll, setShowAll,
  filterText, setFilterText, pageSize, setPageSize, loading, error,
  onAcceptAll, totalItems, currentPage, setCurrentPage
}) => {
  const availableTypes = getAvailableTypes();

  return (
  <div className="filter-controls">
    {/* First row: Graph URL, Type, Accept All button */}
    <div className="filter-row-1">
      <div className="form-group">
        <label className="form-label">Graph URL</label>
        <input
          type="text"
          value={dataFeed}
          onChange={(e) => setDataFeed(e.target.value)}
          className="form-input"
          placeholder="Enter graph URL (e.g., http://kg.artsdata.ca/culture-creates/artsdata-planet-iwts/iwts-ca)"
          disabled={loading}
        />
      </div>
      <div className="form-group">
        <label className="form-label">Type</label>
        <select
          value={type}
          onChange={(e) => setType(e.target.value)}
          className="form-select"
          disabled={loading}
        >
          {availableTypes.map(typeOption => (
            <option key={typeOption.value} value={typeOption.value}>
              {typeOption.label}
            </option>
          ))}
        </select>
      </div>
      <div className="accept-all-container">
        <button 
          onClick={onAcceptAll} 
          className="btn btn-primary accept-all-btn"
          disabled={totalItems === 0}
        >
          Accept All ({totalItems})
        </button>
      </div>
    </div>
    
    {/* Second row: Filter results, Minimum Score, Show All, Page Size, Pagination */}
    <div className="filter-row-2">
      <div className="form-group">
        <input
          type="text"
          value={filterText}
          onChange={(e) => setFilterText(e.target.value)}
          className="form-input"
          placeholder="Filter results"
          disabled
        />
      </div>
      <div className="form-group">
        <label className="form-label">Minimum Score</label>
        <div className="slider-container">
          <input
            type="range"
            min="0"
            max="100"
            value={minScore}
            onChange={(e) => setMinScore(parseInt(e.target.value, 10))}
            className="slider"
            disabled={loading}
          />
          <div className="slider-tooltip">{minScore}</div>
        </div>
      </div>
      <div className="form-group">
        <label className="checkbox-container">
          <input
            type="checkbox"
            checked={showAll}
            onChange={(e) => setShowAll(e.target.checked)}
            className="checkbox"
            disabled={loading}
          />
          <span className="checkbox-label">Show all</span>
        </label>
      </div>
      <div className="form-group">
        <label className="form-label">Page Size</label>
        <select
          value={pageSize}
          onChange={(e) => setPageSize(parseInt(e.target.value, 10))}
          className="form-select page-size-select"
        >
          <option value="10">10</option>
          <option value="20">20</option>
          <option value="50">50</option>
        </select>
      </div>
      {!loading && !error && (
        <div className="pagination-container">
          <Pagination
            currentPage={currentPage}
            onPageChange={setCurrentPage}
          />
        </div>
      )}
    </div>
    
    {loading && (
      <div className="loading-indicator">
        <span>Loading data from Artsdata...</span>
      </div>
    )}
    
    {error && (
      <div className="error-indicator">
        <span>Error: {error}</span>
      </div>
    )}
  </div>
  );
};

export default FilterControls;
