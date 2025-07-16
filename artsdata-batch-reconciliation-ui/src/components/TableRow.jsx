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
  const [expanded, setExpanded] = useState(false);
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
  
  // Auto-expand if there are multiple matches to show
  const shouldAutoExpand = item.matches && item.matches.length > 1 && currentStatus === 'needs-judgment';
  
  React.useEffect(() => {
    if (shouldAutoExpand) {
      setExpanded(true);
    }
  }, [shouldAutoExpand]);

  // Handle match selection
  const handleMatchSelect = (match) => {
    setSelectedMatch(match);
    setExpanded(false); // Collapse after selection
    // Save match selection to global state
    onAction(item.id, 'select_match', match);
  };

  // Handle mint option
  const handleMintClick = () => {
    setShowMintConfirm(true);
  };

  // Handle mint confirmation
  const handleMintConfirm = async () => {
    setMintPreviewLoading(true);
    setMintPreviewError(null);
    
    try {
      // Call mint preview API
      await onAction(item.id, 'mint_preview');
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
    setExpanded(true);
    
    // Reset mint state if item was in mint-ready state
    if (currentStatus === 'mint-ready') {
      onAction(item.id, 'reset_mint');
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

  const handleRowClick = (e) => {
    if (
      e.target.closest('.icon-button') ||
      e.target.closest('.action-link') ||
      e.target.closest('.btn')
    ) {
      return;
    }
    setExpanded((prev) => !prev);
  };

  // Only show eye icon if item.externalId exists
  const canShowEye = !!item.externalId;

  return (
    <>
      <tr className={`table-row${expanded ? ' expanded' : ''}`} onClick={handleRowClick} style={{ cursor: 'pointer' }}>
        <td className="table-cell cell-id">{item.id}</td>
        <td className="table-cell">
          <div className="judgement-cell">
            {/* Status badge without button text for ready states */}
            {(currentStatus === 'judgment-ready' || currentStatus === 'mint-ready') ? (
              <button 
                className="btn btn-sm btn-primary"
                onClick={handleFinalAction}
                disabled={currentStatus === 'mint-error'}
              >
                {currentStatus === 'judgment-ready' ? 'Match' : `Mint ${item.type?.split('/').pop() || 'Entity'}`}
              </button>
            ) : (
              <StatusBadge 
                status={currentStatus} 
                hasError={item.hasError || item.reconciliationError} 
                autoMatched={item.hasAutoMatch}
                mintError={item.mintError || mintPreviewError}
                entityType={item.type?.split('/').pop() || 'Entity'}
              />
            )}
            
            {/* Mint option button for needs-judgment state */}
            {currentStatus === 'needs-judgment' && (
              <button 
                className="btn btn-sm btn-secondary"
                onClick={handleMintClick}
              >
                Mint New
              </button>
            )}
            
            {/* Change link - only show for non-reconciled items */}
            {(currentStatus === 'judgment-ready' || currentStatus === 'mint-ready') && (
              <button 
                className="action-link"
                onClick={handleChange}
              >
                Change
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
            
            {item.reconciliationError && (
              <div className="error-indicator" title={item.reconciliationError}>
                ⚠️
              </div>
            )}
          </div>
        </td>
        <td className="table-cell cell-external-id">
          {canShowEye && (
            <button
              className="icon-button eye-externalid-btn"
              title={item.externalId}
              onClick={e => { e.stopPropagation(); }}
              style={{ marginRight: '0.5rem' }}
            >
              <Eye className="table-icon" />
            </button>
          )}
        </td>
        <td className="table-cell">
          <div className="name-cell">
            <div className="name-primary">{item.name}</div>
            <div className="name-secondary">{item.description}</div>
          </div>
        </td>
        <td className="table-cell">
          {item.url && (
            <a href={item.url} target="_blank" rel="noopener noreferrer" title={item.url}>
              {truncateUrl(item.url)}
            </a>
          )}
        </td>
        <td className="table-cell">
          {item.isni || ''}
        </td>
        <td className="table-cell">
          {item.wikidata || ''}
        </td>
        <td className="table-cell cell-type">{item.type}</td>
        <td className="table-cell">
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
      {expanded && item.matches && item.matches.map((match, index) => {
        // Check if this match is selected either manually or automatically
        const isManuallySelected = selectedMatch && selectedMatch.id === match.id;
        const isAutoSelected = !selectedMatch && match.match === true && item.hasAutoMatch !== false;
        const isSelected = isManuallySelected || isAutoSelected;
        return (
          <tr key={`${item.id}-match-${index}`} className={`table-row match-row ${isSelected ? 'selected-match' : ''}`}>
            <td className="table-cell"></td>
            <td className="table-cell">
              <div className="match-actions">
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
                <span className={`match-score ${match.match ? 'true-match' : 'candidate-match'}`}>
                  {match.match ? 'TRUE' : ''} ({match.score})
                </span>
                {isSelected && (
                  <span className="selected-indicator">
                    ✓ {isAutoSelected ? 'Auto-Selected' : 'Selected'}
                  </span>
                )}
              </div>
            </td>
            <td className="table-cell cell-external-id">
              <span title={match.id}>{match.id}</span>
            </td>
            <td className="table-cell">
              <div className="name-cell">
                <div className="match-name">{match.name}</div>
                <div className="match-description">{match.description}</div>
              </div>
            </td>
            <td className="table-cell"></td>
            <td className="table-cell"></td>
            <td className="table-cell"></td>
            <td className="table-cell cell-type">
              {Array.isArray(match.type) 
                ? (typeof match.type[0] === 'object' ? match.type[0].id || match.type[0].name : match.type[0])
                : (typeof match.type === 'object' ? match.type.id || match.type.name : match.type)
              }
            </td>
            <td className="table-cell"></td>
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
