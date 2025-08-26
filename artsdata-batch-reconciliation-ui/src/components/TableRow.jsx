import React, { useState, useEffect } from 'react';
import StatusBadge from './StatusBadge';
import ActionButton from './ActionButton';
import MintConfirmPopup from './MintConfirmPopup';
import { Eye, RefreshCw, Flag } from 'lucide-react';
import { extractWikidataId } from '../services/dataFeedService';

// Helper to truncate URLs in the middle
function truncateUrl(url, maxLength = 24) {
  if (!url) return '';
  
  // Remove protocol and www prefix for display
  let displayUrl = url;
  displayUrl = displayUrl.replace(/^https?:\/\//, ''); // Remove http:// or https://
  displayUrl = displayUrl.replace(/^www\./, ''); // Remove www.
  
  // If the cleaned URL is short enough, return it
  if (displayUrl.length <= maxLength) return displayUrl;
  
  // Truncate with ellipsis in the middle
  const start = displayUrl.slice(0, Math.ceil(maxLength / 2));
  const end = displayUrl.slice(-Math.floor(maxLength / 2));
  return `${start}...${end}`;
}


const TableRow = ({ item, onAction, onRefresh, parentRowIndex, displayIndex }) => {
  const [selectedMatch, setSelectedMatch] = useState(item.selectedMatch || null);
  const [showMintConfirm, setShowMintConfirm] = useState(false);
  const [mintPreviewLoading, setMintPreviewLoading] = useState(false);
  const [mintPreviewError, setMintPreviewError] = useState(null);

  // Reset local state when item changes (e.g., after refresh) but preserve saved selectedMatch
  React.useEffect(() => {
    setSelectedMatch(item.selectedMatch || null);
    setShowMintConfirm(false);
    setMintPreviewLoading(false);
    setMintPreviewError(null);
  }, [item.id, item.reconciliationStatus, item.selectedMatch]);
  
  // Determine the current status based on matches and user selections
  const getItemStatus = () => {
    if (item.status === 'reconciled' || item.status === 'flagged') {
      return item.status;
    }
    
    if (item.mintError) {
      return 'mint-error';
    }
    
    if (item.linkError) {
      return 'link-error';
    }
    
    if (selectedMatch) {
      return 'judgment-ready';
    }
    
    if (item.mintReady) {
      return 'mint-ready';
    }
    
    if (item.status === 'flagged-complete') {
      return item.status;
    }
    
    // Check if there's a single true match (and it hasn't been reset)
    const trueMatches = item.matches?.filter(match => match.match === true) || [];
    if (trueMatches.length === 1 && item.hasAutoMatch !== false) {
      return 'judgment-ready';
    }
    
    // Check if there are multiple matches requiring judgment
    if (item.matches && item.matches.length > 0) {
      return 'needs-judgment';
    }
    
    return 'needs-judgment';
  };

  const currentStatus = getItemStatus();
  

  // Handle match selection
  const handleMatchSelect = (match) => {
    setSelectedMatch(match);
    // Save match selection to global state
    onAction(item.id, 'select_match', match);
  };

  // Handle mint option
  const handleMintClick = () => {
    setShowMintConfirm(true);
  };

  // Handle mint confirmation
  const handleMintConfirm = async (selectedType) => {
    setMintPreviewLoading(true);
    setMintPreviewError(null);
    
    try {
      // Call mint preview API with selected type
      await onAction(item.id, 'mint_preview', null, selectedType);
      setShowMintConfirm(false);
    } catch (error) {
      setMintPreviewError(error.message);
    } finally {
      setMintPreviewLoading(false);
    }
  };

  // Handle change link (reset selections)
  const handleChange = (e) => {
    e.stopPropagation(); // Prevent row click handler
    setSelectedMatch(null);
    
    // Reset mint state if item was in mint-ready state
    if (currentStatus === 'mint-ready') {
      onAction(item.id, 'reset_mint');
    }
    // Reset link error state if item failed to link
    else if (currentStatus === 'link-error') {
      onAction(item.id, 'reset_link_error');
    }
    // Reset judgment state if item was in judgment-ready state due to auto-match
    else if (currentStatus === 'judgment-ready' && !selectedMatch) {
      // This means it's an automatic judgment (single true match)
      const trueMatches = item.matches?.filter(match => match.match === true) || [];
      if (trueMatches.length === 1) {
        onAction(item.id, 'reset_judgment');
      }
    }
    // Reset manual selection if there was one
    else if (currentStatus === 'judgment-ready' && selectedMatch) {
      onAction(item.id, 'select_match', null);
    }
    // Reset flagged state back to needs-judgment
    else if (currentStatus === 'flagged' || currentStatus === 'flagged-complete') {
      onAction(item.id, 'reset_flag');
    }
  };

  // Handle final action (Match, Mint, or Flag button click)
  const handleFinalAction = () => {
    if (currentStatus === 'judgment-ready') {
      if (selectedMatch) {
        // User selected a match manually
        onAction(item.id, 'link', selectedMatch);
      } else {
        // Automatic match (single true match)
        const trueMatches = item.matches?.filter(match => match.match === true) || [];
        if (trueMatches.length === 1) {
          onAction(item.id, 'link', trueMatches[0]);
        }
      }
    } else if (currentStatus === 'mint-ready') {
      onAction(item.id, 'mint_final');
    } else if (currentStatus === 'flagged') {
      onAction(item.id, 'flag_final');
    }
  };


  // Only show eye icon if item.externalId exists
  const canShowEye = !!item.externalId;


  // Determine visible matches based on current status and selections
  const getVisibleMatches = () => {
    if (!item.matches) return [];
    
    const filteredMatches = item.matches.filter((match) => {
      // If a match is selected, only show the selected match
      if (selectedMatch) {
        return selectedMatch.id === match.id;
      }
      // For pre-reconciled entities, only show the matching entity (auto-selected)
      if (item.isPreReconciled && item.linkedTo) {
        return match.id === item.linkedTo;
      }
      // For reconciled entities with linkedTo (including newly minted), only show the linked entity
      if (currentStatus === 'reconciled' && item.linkedTo) {
        return match.id === item.linkedTo;
      }
      // If no manual selection but there's an auto-match, only show the auto-matched one
      if (!selectedMatch && item.hasAutoMatch && match.match === true) {
        return true;
      }
      // If no selection at all, show all matches (needs-judgment or flagged-complete state)
      if (!selectedMatch && ((currentStatus === 'needs-judgment' || currentStatus === 'flagged-complete') || !item.hasAutoMatch)) {
        return true;
      }
      return false;
    });
    
    // Sort matches by score (highest score first)
    return filteredMatches.sort((a, b) => {
      const scoreA = parseFloat(a.score) || 0;
      const scoreB = parseFloat(b.score) || 0;
      return scoreB - scoreA; // Descending order (highest first)
    });
  };

  const visibleMatches = getVisibleMatches();

  return (
    <>
      <tr className="parent-row">
        <th scope="row" className="sticky-top row-number">{displayIndex}</th>
        <td>
          {/* Judgement cell with action buttons */}
          <div className="judgement-cell">
            {(currentStatus === 'judgment-ready' || currentStatus === 'mint-ready' || currentStatus === 'flagged' || currentStatus === 'reconciled') ? (
              <>
                {currentStatus === 'reconciled' ? (
                  <div className="reconciled-text">
                    Reconciled
                  </div>
                ) : (
                  <button 
                    className={`btn btn-sm btn-primary`}
                    onClick={handleFinalAction}
                    disabled={currentStatus === 'mint-error'}
                  >
                    {currentStatus === 'judgment-ready' ? 'Match' : 
                     currentStatus === 'mint-ready' ? `Mint ${item.selectedMintType || item.type?.split('/').pop() || 'Entity'}` : 
                     'Flag'}
                  </button>
                )}
                {currentStatus !== 'reconciled' && (
                  <div>
                    <button 
                      className="action-link"
                      onClick={handleChange}
                    >
                      Change
                    </button>
                  </div>
                )}
              </>
            ) : (
              <div>
                <StatusBadge 
                  status={currentStatus} 
                  hasError={item.hasError || item.reconciliationError} 
                  autoMatched={item.hasAutoMatch}
                  mintError={item.mintError || mintPreviewError}
                  linkError={item.linkError}
                  entityType={item.selectedMintType || item.type?.split('/').pop() || 'Entity'}
                  isFlaggedForReview={item.isFlaggedForReview}
                />
                {currentStatus === 'flagged-complete' && (
                  <div style={{fontSize: '11px', color: 'var(--flag-color)', whiteSpace: 'nowrap'}}>
                    <Flag className="flag-icon me-1" size={11} fill="currentColor" title="Flagged for review" style={{display: 'inline'}} />
                    <span style={{fontWeight: 'bold'}}>Needs review</span>
                  </div>
                )}
                {currentStatus === 'link-error' && (
                  <div>
                    <button 
                      className="action-link"
                      onClick={handleChange}
                    >
                      Change
                    </button>
                  </div>
                )}
              </div>
            )}
            
            {item.reconciliationError && (
              <div className="error-indicator" title={item.reconciliationError}>
                ⚠️
              </div>
            )}
          </div>
        </td>
        <td>
          {/* Nested table containing source entity and all matches */}
          <div className="nested-table-container">
            <table className="table table-hover table-responsive table-borderless nested-table">
              <thead className="sticky-top">
                <tr>
                  <th style={{width: '100px'}}></th>
                  <th style={{width: '60px'}}>ID</th>
                  <th style={{minWidth: '300px'}}>Name</th>
                  <th>URL</th>
                  <th>ISNI</th>
                  <th>Wikidata</th>
                  {/* Show PostalCode column for Place entities */}
                  {item.type?.toLowerCase().includes('place') && <th>PostalCode</th>}
                  {/* Show StartDate column for Event entities */}
                  {item.type?.toLowerCase().includes('event') && <th>Start Date</th>}
                  <th>Type</th>
                </tr>
              </thead>
              <tbody>
                {/* Source entity row */}
                <tr className="source-entity-row">
                  <td>
                    {/* Action links for source entity */}
                    {(currentStatus === 'needs-judgment' || currentStatus === 'flagged-complete') && (
                      <>
                        <button 
                          className="action-link"
                          onClick={handleMintClick}
                        >
                          mint&nbsp;new
                        </button>
                        <br />
                        <button 
                          className="action-link"
                          onClick={() => onAction(item.id, 'flag')}
                        >
                          flag
                        </button>
                      </>
                    )}
                  </td>
                  <td>
                    {canShowEye ? (
                      <button
                        className="eye-externalid-btn"
                        title={item.externalId}
                        onClick={e => { 
                          e.stopPropagation(); 
                          const encodedUri = encodeURIComponent(item.uri);
                          window.open(`https://staging.kg.artsdata.ca/entity?uri=${encodedUri}`, '_blank');
                        }}
                      >
                        <Eye className="table-icon" />
                      </button>
                    ) : (
                      'eye'
                    )}
                  </td>
                  <td>
                    <div className="name-cell">
                      <div className="name-primary">{item.name}</div>
                      <div className="name-secondary">{item.description}</div>
                    </div>
                  </td>
                  <td className="text-nowrap">
                    {item.url && (
                      <a href={item.url} target="_blank" rel="noopener noreferrer" title={item.url}>
                        {truncateUrl(item.url)}
                      </a>
                    )}
                  </td>
                  <td>
                    {item.isni && (
                      <a href={item.isni} target="_blank" rel="noopener noreferrer" title={item.isni}>
                        {truncateUrl(item.isni)}
                      </a>
                    )}
                  </td>
                  <td>
                    {item.wikidata && (
                      <a href={item.wikidata} target="_blank" rel="noopener noreferrer" title={item.wikidata}>
                        {item.wikidataId || truncateUrl(item.wikidata)}
                      </a>
                    )}
                  </td>
                  {/* Show PostalCode column for Place entities */}
                  {item.type?.toLowerCase().includes('place') && <td>{item.postalCode || ''}</td>}
                  {/* Show StartDate column for Event entities */}
                  {item.type?.toLowerCase().includes('event') && (
                    <td style={{fontSize: '0.75rem', color: '#6b7280'}}>
                      {item.startDate || ''}
                    </td>
                  )}
                  <td>{item.type?.split('/').pop() || item.type}</td>
                </tr>
                
                {/* Match rows - only show if not in flagged or mint-ready state */}
                {currentStatus !== 'flagged' && currentStatus !== 'mint-ready' && visibleMatches.map((match, index) => {
                  // Check if this match is selected either manually or automatically
                  const isManuallySelected = selectedMatch && selectedMatch.id === match.id;
                  const isAutoSelected = !selectedMatch && match.match === true && item.hasAutoMatch !== false;
                  const isSelected = isManuallySelected || isAutoSelected;
                  
                  return (
                    <tr key={`${item.id}-match-${index}`} className="table-active">
                      <td>
                        {(currentStatus === 'needs-judgment' || currentStatus === 'flagged-complete') && (
                          <>
                            <button 
                              className="action-link match-link"
                              onClick={(e) => {
                                e.stopPropagation();
                                handleMatchSelect(match);
                              }}
                              title="Choose this match"
                            >
                              match
                            </button>
                            {!item.isPreReconciled && (
                              <span className={`match-score ${match.match ? 'true-match' : 'candidate-match'}`}>
                                &nbsp;({match.score})
                              </span>
                            )}
                          </>
                        )}
                        {isAutoSelected && !item.isPreReconciled && !item.mintedAs && (
                          <div className="selected-indicator">
                            ✓ Auto-Selected
                          </div>
                        )}
                      </td>
                      <td className="text-nowrap">
                        <a 
                          href={`https://staging.kg.artsdata.ca/entity?uri=${encodeURIComponent(`http://kg.artsdata.ca/resource/${match.id}`)}`}
                          target="_blank"
                          rel="noopener noreferrer"
                          title={match.id}
                        >
                          {match.id}
                        </a>
                      </td>
                      <td>
                        <div className="name-cell">
                          <div className="match-name">{match.name}</div>
                          <div className="match-description">{match.description}</div>
                        </div>
                      </td>
                      <td className="text-nowrap">
                        {match.url && (
                          <a href={match.url} target="_blank" rel="noopener noreferrer" title={match.url}>
                            {truncateUrl(match.url)}
                          </a>
                        )}
                      </td>
                      <td className="text-nowrap">
                        {match.isni && (
                          <a href={match.isni} target="_blank" rel="noopener noreferrer" title={match.isni}>
                            {truncateUrl(match.isni)}
                          </a>
                        )}
                      </td>
                      <td className="text-nowrap">
                        {match.wikidata && (
                          <a href={match.wikidata} target="_blank" rel="noopener noreferrer" title={match.wikidata}>
                            {extractWikidataId(match.wikidata) || truncateUrl(match.wikidata)}
                          </a>
                        )}
                      </td>
                      {/* Show PostalCode column for Place entities */}
                      {item.type?.toLowerCase().includes('place') && <td>{match.postalCode || ''}</td>}
                      {/* Show StartDate column for Event entities */}
                      {item.type?.toLowerCase().includes('event') && (
                        <td style={{fontSize: '0.75rem', color: '#6b7280'}}>
                          {match.startDate || ''}
                        </td>
                      )}
                      <td>
                        {Array.isArray(match.type) 
                          ? (typeof match.type[0] === 'object' ? match.type[0].id || match.type[0].name : match.type[0])
                          : (typeof match.type === 'object' ? match.type.id || match.type.name : match.type)
                        }
                      </td>
                    </tr>
                  );
                })}
              </tbody>
            </table>
          </div>
        </td>
        <td>
          {/* Refresh button */}
          {(currentStatus !== 'reconciled' && !item.linkedTo && !item.mintedAs) && (
            <button
              onClick={e => { e.stopPropagation(); onRefresh && onRefresh(item.id); }}
              className="icon-button"
              title="Refresh row"
            >
              <RefreshCw className="table-icon" />
            </button>
          )}
        </td>
      </tr>
      
      {/* Mint Confirmation Popup */}
      <MintConfirmPopup
        isOpen={showMintConfirm}
        entityType={item.type?.split('/').pop() || 'Entity'}
        entityName={item.name}
        onConfirm={handleMintConfirm}
        onCancel={() => setShowMintConfirm(false)}
        isLoading={mintPreviewLoading}
        error={mintPreviewError}
      />
    </>
  );
};

export default TableRow;
