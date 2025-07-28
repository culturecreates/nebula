import React, { useState, useEffect } from 'react';
import { validateGraphUrl } from '../utils/urlValidation';

const FilterControls = ({ 
  dataFeed, setDataFeed, type, setType, minScore, setMinScore, showAll, setShowAll,
  filterText, setFilterText, pageSize, setPageSize, loading, error,
  onAcceptAll, totalItems, currentPage, setCurrentPage, hasResults, onSearch
}) => {
  const [validation, setValidation] = useState({ isValid: true, message: '' });
  const [inputValue, setInputValue] = useState(dataFeed || '');
  const [typeInputValue, setTypeInputValue] = useState(type || '');

  // Update input value when dataFeed prop changes
  useEffect(() => {
    if (dataFeed !== inputValue) {
      setInputValue(dataFeed || '');
    }
  }, [dataFeed]);

  // Update type input value when type prop changes
  useEffect(() => {
    if (type !== typeInputValue) {
      setTypeInputValue(type || '');
    }
  }, [type]);

  // Handle input change
  const handleInputChange = (e) => {
    const value = e.target.value;
    setInputValue(value);
    
    // Update validation immediately for UI feedback
    const result = validateGraphUrl(value);
    setValidation(result);
  };

  // Handle type input change
  const handleTypeInputChange = (e) => {
    const value = e.target.value;
    setTypeInputValue(value);
  };

  // Handle search button click
  const handleSearchClick = () => {
    // Validate inputs before searching
    const urlValidation = validateGraphUrl(inputValue);
    setValidation(urlValidation);
    
    if (urlValidation.isValid && !urlValidation.isWarning && typeInputValue.trim() !== '') {
      // Call the parent's search handler with current input values
      onSearch(inputValue.trim(), typeInputValue.trim());
    }
  };

  // Check if search can be performed
  const canSearch = () => {
    return inputValue.trim() !== '' && 
           typeInputValue.trim() !== '' && 
           validation.isValid && 
           !validation.isWarning && 
           !loading;
  };

  // Handle Enter key press in input fields
  const handleKeyDown = (e) => {
    if (e.key === 'Enter') {
      e.preventDefault();
      if (canSearch()) {
        handleSearchClick();
      }
    }
  };

  return (
  <div className="filter-controls">
    {/* First row: Graph URL, Type, Accept All button */}
    <div className="filter-row-1">
      <div className="form-group">
        <label className="form-label">Data Feed</label>
        <input
          type="text"
          value={inputValue}
          onChange={handleInputChange}
          onKeyDown={handleKeyDown}
          className={`form-input ${
            validation.isValid 
              ? (validation.isWarning ? 'form-input-warning' : '')
              : 'form-input-error'
          }`}
          placeholder="Enter graph URL"
          disabled={loading}
        />
        {validation.message && (
          <div className={`validation-message ${
            validation.isValid 
              ? (validation.isWarning ? 'validation-warning' : 'validation-success')
              : 'validation-error'
          }`}>
            {validation.message}
          </div>
        )}
      </div>
      <div className="form-group">
        <label className="form-label">Type</label>
        <input
          type="text"
          value={typeInputValue}
          onChange={handleTypeInputChange}
          onKeyDown={handleKeyDown}
          className="form-input"
          placeholder="e.g., Event, Person, Organization"
          disabled={loading}
        />
      </div>
      <div className="search-button-container">
        <button 
          onClick={handleSearchClick}
          className="btn btn-primary"
          disabled={!canSearch()}
        >
          {loading ? (
            <>
              <div className="spinner-border spinner-border-sm me-2" role="status">
                <span className="visually-hidden">Loading...</span>
              </div>
              Searching...
            </>
          ) : (
            'Search'
          )}
        </button>
      </div>
      {dataFeed && dataFeed.trim() !== '' && type && type.trim() !== '' && validation.isValid && !validation.isWarning && hasResults && (
        <div className="accept-all-container">
          <button 
            onClick={onAcceptAll} 
            className="btn btn-primary"
            disabled={true}
          >
            Accept All ({totalItems})
          </button>
        </div>
      )}
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
        <label className="checkbox-container">
          <input
            type="checkbox"
            checked={showAll}
            onChange={(e) => setShowAll(e.target.checked)}
            className="checkbox"
            disabled={true}
          />
          <span className="checkbox-label">Show all</span>
        </label>
      </div>
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
