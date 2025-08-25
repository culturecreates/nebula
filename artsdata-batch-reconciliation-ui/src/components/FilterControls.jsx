import React, { useState, useEffect } from 'react';
import { validateGraphUrl } from '../utils/urlValidation';

const FilterControls = ({ 
  dataFeed, setDataFeed, type, setType, minScore, setMinScore, showAll, setShowAll,
  filterText, setFilterText, pageSize, setPageSize, loading, error,
  onAcceptAll, totalItems, currentPage, setCurrentPage, hasResults, onSearch, onShowAllToggle
}) => {
  const [validation, setValidation] = useState({ isValid: true, message: '' });
  const [inputValue, setInputValue] = useState(dataFeed || '');
  const [typeInputValue, setTypeInputValue] = useState(type || '');
  const [validationTimeout, setValidationTimeout] = useState(null);

  // Update input value when dataFeed prop changes
  useEffect(() => {
    if (dataFeed !== inputValue) {
      setInputValue(dataFeed || '');
    }
    
    // Validate current input value (handles page refresh with existing URL)
    if (dataFeed && dataFeed.trim() !== '') {
      const result = validateGraphUrl(dataFeed);
      setValidationWithTimeout(result);
    }
  }, [dataFeed]);

  // Update type input value when type prop changes
  useEffect(() => {
    if (type !== typeInputValue) {
      setTypeInputValue(type || '');
    }
  }, [type]);

  // Cleanup timeout on unmount
  useEffect(() => {
    return () => {
      if (validationTimeout) {
        clearTimeout(validationTimeout);
      }
    };
  }, [validationTimeout]);

  // Helper function to set validation with auto-hide for success messages
  const setValidationWithTimeout = (result) => {
    // Clear any existing timeout
    if (validationTimeout) {
      clearTimeout(validationTimeout);
      setValidationTimeout(null);
    }
    
    // Set validation
    setValidation(result);
    
    // If validation is successful (not warning or error), hide message after 3 seconds
    if (result.isValid && !result.isWarning && result.message) {
      const timeout = setTimeout(() => {
        setValidation(prev => ({ ...prev, message: '' }));
        setValidationTimeout(null);
      }, 3000);
      setValidationTimeout(timeout);
    }
  };

  // Handle input change
  const handleInputChange = (e) => {
    const value = e.target.value;
    setInputValue(value);
    
    // Update validation with auto-hide for success messages
    const result = validateGraphUrl(value);
    setValidationWithTimeout(result);
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
    setValidationWithTimeout(urlValidation);
    
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
            disabled={!hasResults || loading || totalItems === 0}
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
        />
      </div>
      <div className="form-group">
        <label className="checkbox-container">
          <input
            type="checkbox"
            checked={showAll}
            onChange={(e) => onShowAllToggle(e.target.checked)}
            className="checkbox"
            disabled={loading}
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
