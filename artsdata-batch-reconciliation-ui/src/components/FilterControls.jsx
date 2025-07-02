import React from 'react';

const FilterControls = ({ 
  dataFeed, setDataFeed, type, setType, minScore, setMinScore, showAll, setShowAll,
  filterText, setFilterText, pageSize, setPageSize 
}) => (
  <div className="filter-controls">
    <div className="filter-grid">
      <div className="form-group">
        <label className="form-label">Data Feed</label>
        <input
          type="text"
          value={dataFeed}
          onChange={(e) => setDataFeed(e.target.value)}
          className="form-input"
          placeholder="iwts-ca"
        />
      </div>
      <div className="form-group">
        <label className="form-label">Type</label>
        <select
          value={type}
          onChange={(e) => setType(e.target.value)}
          className="form-select"
        >
          <option value="PerformingGroup">PerformingGroup</option>
          <option value="Person">Person</option>
          <option value="Organization">Organization</option>
        </select>
      </div>
      <div className="form-group">
        <label className="form-label">Filter results</label>
        <input
          type="text"
          value={filterText}
          onChange={(e) => setFilterText(e.target.value)}
          className="form-input"
          placeholder="Filter results"
        />
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
    </div>
    <div className="filter-bottom">
      <div className="filter-options">
        <div className="score-control">
          <span className="score-label">Minimum Score</span>
          <div className="slider-container">
            <input
              type="range"
              min="0"
              max="100"
              value={minScore}
              onChange={(e) => setMinScore(parseInt(e.target.value, 10))}
              className="slider"
            />
            <div className="slider-tooltip">{minScore}</div>
          </div>
        </div>
        <label className="checkbox-container">
          <input
            type="checkbox"
            checked={showAll}
            onChange={(e) => setShowAll(e.target.checked)}
            className="checkbox"
          />
          <span className="checkbox-label">Show all</span>
        </label>
      </div>
    </div>
  </div>
);

export default FilterControls;
