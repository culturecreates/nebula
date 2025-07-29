import React, { useState, useEffect } from 'react';
import StatusBadge from './StatusBadge';
import ActionButton from './ActionButton';
import MintConfirmPopup from './MintConfirmPopup';
import { Eye, RefreshCw } from 'lucide-react';

// Helper to truncate URLs in the middle
function truncateUrl(url, maxLength = 24) {
  if (!url) return '';
  if (url.length <= maxLength) return url;
  const start = url.slice(0, Math.ceil(maxLength / 2));
  const end = url.slice(-Math.floor(maxLength / 2));
  return `${start}...${end}`;
}

const TableRow = ({ item, onAction, onRefresh }) => {
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
    if (item.status === 'reconciled' || item.status === 'skipped') {
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
    // Reset skipped state back to needs-judgment
    else if (currentStatus === 'skipped') {
      onAction(item.id, 'reset_skip');
    }
  };

  // Handle final action (Match or Mint button click)
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
    }
  };


  // Only show eye icon if item.externalId exists
  const canShowEye = !!item.externalId;

  return (
    <>
      <tr>
        <th scope="row">{item.id}</th>
        <td>
          <div className="judgement-cell">
            {/* Primary action button or text for finalized states */}
            {(currentStatus === 'judgment-ready' || currentStatus === 'mint-ready' || currentStatus === 'skipped' || currentStatus === 'reconciled') ? (
              <>
                {currentStatus === 'reconciled' ? (
                  <div className="reconciled-text primary-action-full-width">
                    Reconciled
                  </div>
                ) : (
                  <button 
                    className={`btn btn-sm ${currentStatus === 'skipped' ? 'btn-secondary' : 'btn-primary'} primary-action-full-width`}
                    onClick={currentStatus === 'skipped' ? undefined : handleFinalAction}
                    disabled={currentStatus === 'mint-error' || currentStatus === 'skipped'}
                  >
                    {currentStatus === 'judgment-ready' ? 'Match' : 
                     currentStatus === 'mint-ready' ? `Mint ${item.selectedMintType || item.type?.split('/').pop() || 'Entity'}` : 
                     'Skipped'}
                  </button>
                )}
                {/* Two-column layout for Change link below (only for skipped, not reconciled) */}
                {currentStatus !== 'reconciled' && (
                  <div className="judgement-two-columns">
                    <div className="status-text-column">
                      {/* Empty left column */}
                    </div>
                    <div className="interactive-elements-column">
                      <button 
                        className="action-link"
                        onClick={handleChange}
                      >
                        Change
                      </button>
                    </div>
                  </div>
                )}
              </>
            ) : (
              /* Two-column layout for other states */
              <div className="judgement-two-columns">
                {/* Left column: Status badges */}
                <div className="status-text-column">
                  <StatusBadge 
                    status={currentStatus} 
                    hasError={item.hasError || item.reconciliationError} 
                    autoMatched={item.hasAutoMatch}
                    mintError={item.mintError || mintPreviewError}
                    linkError={item.linkError}
                    entityType={item.selectedMintType || item.type?.split('/').pop() || 'Entity'}
                  />
                </div>
                
                {/* Right column: Action links */}
                <div className="interactive-elements-column">
                  {/* Mint option link for needs-judgment state */}
                  {currentStatus === 'needs-judgment' && (
                    <button 
                      className="action-link"
                      onClick={handleMintClick}
                    >
                      Mint New
                    </button>
                  )}
                  
                  {/* Skip option */}
                  {currentStatus === 'needs-judgment' && (
                    <button 
                      className="action-link"
                      onClick={() => onAction(item.id, 'skip')}
                    >
                      Skip
                    </button>
                  )}
                  
                  {/* Change link for other states */}
                  {currentStatus === 'link-error' && (
                    <button 
                      className="action-link"
                      onClick={handleChange}
                    >
                      Change
                    </button>
                  )}
                </div>
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
          {canShowEye && (
            <button
              className="icon-button eye-externalid-btn"
              title={item.externalId}
              onClick={e => { 
                e.stopPropagation(); 
                const encodedUri = encodeURIComponent(item.uri);
                window.open(`https://staging.kg.artsdata.ca/entity?uri=${encodedUri}`, '_blank');
              }}
              style={{ marginRight: '0.5rem' }}
            >
              <Eye className="table-icon" />
            </button>
          )}
        </td>
        <td>
          <div className="name-cell">
            <div className="name-primary">{item.name}</div>
            <div className="name-secondary">{item.description}</div>
          </div>
        </td>
        <td>
          {item.url && (
            <a href={item.url} target="_blank" rel="noopener noreferrer" title={item.url}>
              {truncateUrl(item.url)}
            </a>
          )}
        </td>
        <td>
          {item.isni || ''}
        </td>
        <td>
          {item.wikidata || ''}
        </td>
        <td>{item.type}</td>
        <td>
          {/* Only show refresh button for non-reconciled items */}
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
      {item.matches && currentStatus !== 'skipped' && currentStatus !== 'mint-ready' && item.matches
        .filter((match) => {
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
          // If no selection at all, show all matches (needs-judgment state)
          if (!selectedMatch && (currentStatus === 'needs-judgment' || !item.hasAutoMatch)) {
            return true;
          }
          return false;
        })
        .map((match, index) => {
          // Check if this match is selected either manually or automatically
          const isManuallySelected = selectedMatch && selectedMatch.id === match.id;
          const isAutoSelected = !selectedMatch && match.match === true && item.hasAutoMatch !== false;
          const isSelected = isManuallySelected || isAutoSelected;
        return (
          <tr key={`${item.id}-match-${index}`} className={`table-row match-row ${isSelected ? 'selected-match' : ''}`}>
            <td></td>
            <td>
              <div className="match-judgement-cell">
                {/* Two-column split: Empty left, Match button with score on right */}
                <div className="match-two-columns">
                  {/* Left column: Empty to align with main entity status badges */}
                  <div className="match-status-column">
                    {/* Empty column for alignment */}
                  </div>
                  
                  {/* Right column: Match button with score horizontally */}
                  <div className="match-interactive-column">
                    <div className="match-button-row">
                      {currentStatus === 'needs-judgment' && (
                        <button 
                          className="action-link match-link"
                          onClick={(e) => {
                            e.stopPropagation();
                            handleMatchSelect(match);
                          }}
                          title="Choose this match"
                        >
                          Match
                        </button>
                      )}
                      {!item.isPreReconciled && currentStatus === 'needs-judgment' && (
                        <span className={`match-score ${match.match ? 'true-match' : 'candidate-match'}`}>
                          {match.match ? 'TRUE' : ''} ({match.score})
                        </span>
                      )}
                    </div>
                    {isAutoSelected && !item.isPreReconciled && !item.mintedAs && (
                      <span className="selected-indicator">
                        ✓ Auto-Selected
                      </span>
                    )}
                  </div>
                </div>
              </div>
            </td>
            <td>
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
            <td></td>
            <td></td>
            <td></td>
            <td>
              {Array.isArray(match.type) 
                ? (typeof match.type[0] === 'object' ? match.type[0].id || match.type[0].name : match.type[0])
                : (typeof match.type === 'object' ? match.type.id || match.type.name : match.type)
              }
            </td>
            <td></td>
          </tr>
        );
      })}
      
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
