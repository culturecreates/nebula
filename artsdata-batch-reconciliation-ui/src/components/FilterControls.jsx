import React, { useState, useEffect, useRef } from 'react';
import { validateGraphUrl, debounce } from '../utils/urlValidation';

const FilterControls = ({ 
  dataFeed, setDataFeed, type, setType, minScore, setMinScore, showAll, setShowAll,
  filterText, setFilterText, pageSize, setPageSize, loading, error,
  onAcceptAll, totalItems, currentPage, setCurrentPage, hasResults
}) => {
  const [validation, setValidation] = useState({ isValid: true, message: '' });
  const [inputValue, setInputValue] = useState(dataFeed || '');
  const [typeInputValue, setTypeInputValue] = useState(type || '');

  // Create stable debounced functions using useRef to avoid recreation
  const debouncedSetDataFeedRef = useRef(
    debounce((url) => {
      const result = validateGraphUrl(url);
      setValidation(result);
      
      // Only set the dataFeed if the URL is valid
      if (result.isValid && !result.isWarning) {
        setDataFeed(url);
      }
    }, 2000)
  );

  const debouncedSetTypeRef = useRef(
    debounce((typeValue) => {
      // Use the latest setType function
      setType(typeValue);
    }, 2000)
  );

  // Update the refs when the setter functions change
  useEffect(() => {
    debouncedSetDataFeedRef.current = debounce((url) => {
      const result = validateGraphUrl(url);
      setValidation(result);
      
      if (result.isValid && !result.isWarning) {
        setDataFeed(url);
      }
    }, 2000);
  }, [setDataFeed]);

  useEffect(() => {
    debouncedSetTypeRef.current = debounce((typeValue) => {
      setType(typeValue);
    }, 2000);
  }, [setType]);

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
    
    if (value.trim() === '') {
      setValidation({ isValid: true, message: '' });
      setDataFeed(''); // This will trigger the confirmation modal if there's unsaved work
    } else {
      // Update validation immediately for UI feedback
      const result = validateGraphUrl(value);
      setValidation(result);
      
      // Debounce the actual parent state update
      debouncedSetDataFeedRef.current(value);
    }
  };

  // Handle type input change
  const handleTypeInputChange = (e) => {
    const value = e.target.value;
    setTypeInputValue(value);
    
    // Debounce the parent state update
    if (value.trim() === '') {
      // If empty, update immediately without confirmation
      setType('');
    } else {
      // For non-empty values, use debounced update
      debouncedSetTypeRef.current(value);
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
          className="form-input"
          placeholder="e.g., Event, Person, Organization"
          disabled={loading}
        />
      </div>
      {dataFeed && dataFeed.trim() !== '' && type && type.trim() !== '' && validation.isValid && !validation.isWarning && hasResults && (
        <div className="accept-all-container">
          <button 
            onClick={onAcceptAll} 
            className="btn btn-primary accept-all-btn"
            disabled={totalItems === 0}
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
