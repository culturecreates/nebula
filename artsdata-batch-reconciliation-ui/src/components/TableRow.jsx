import React, { useState, useEffect, useRef } from 'react';
import StatusBadge from './StatusBadge';
import ActionButton from './ActionButton';
import MintConfirmPopup from './MintConfirmPopup';
import { Eye, RefreshCw, Flag } from 'lucide-react';
import { extractWikidataId } from '../services/dataFeedService';
import { useStickyHeadersContext } from './StickyHeadersProvider';

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

// Helper to extract status from schema.org URI
function extractSchemaStatus(uri) {
  if (!uri) return '';
  const parts = uri.split('/');
  return parts[parts.length - 1] || uri;
}

function extractTypeInfo(type) {
  if (!type) return { name: '', url: '' };

  if (Array.isArray(type)) {
    const firstType = type[0];
    if (typeof firstType === 'object') {
      return {
        name: firstType.name || '',
        url: firstType.id || ''
      };
    }
    return {
      name: firstType?.split('/').pop() || firstType || '',
      url: firstType || ''
    };
  }

  if (typeof type === 'object') {
    return {
      name: type.name || '',
      url: type.id || ''
    };
  }

  return {
    name: type.split('/').pop() || type,
    url: type
  };
}

// Helper to generate Artsdata entity URL based on environment
function getArtsdataEntityUrl(uri, config = {}) {
  let artsdataBaseUrl = 'https://staging.kg.artsdata.ca'; // Default to staging
  
  // Try to derive from reconciliation endpoint
  if (config.reconciliationEndpoint) {
    // e.g., "https://staging.recon.artsdata.ca" -> "https://staging.kg.artsdata.ca"
    // or "https://recon.artsdata.ca" -> "https://kg.artsdata.ca"
    const url = new URL(config.reconciliationEndpoint);
    artsdataBaseUrl = `${url.protocol}//${url.hostname.replace('recon.', 'kg.')}`;
  } else {
    // Fallback: detect from current browser URL
    const currentHost = window.location.hostname;
    if (currentHost.includes('localhost') || currentHost.includes('staging')) {
      artsdataBaseUrl = 'https://staging.kg.artsdata.ca';
    } else {
      artsdataBaseUrl = 'https://kg.artsdata.ca';
    }
  }
  
  return `${artsdataBaseUrl}/entity?uri=${encodeURIComponent(uri)}`;
}


const TableRow = ({ item, onAction, onRefresh, parentRowIndex, displayIndex, config }) => {
  const [selectedMatch, setSelectedMatch] = useState(item.selectedMatch || null);
  const [showMintConfirm, setShowMintConfirm] = useState(false);
  const [mintPreviewLoading, setMintPreviewLoading] = useState(false);
  const [mintPreviewError, setMintPreviewError] = useState(null);
  const headerRef = useRef(null);
  const { registerHeader, unregisterHeader } = useStickyHeadersContext();

  // Reset local state when item changes (e.g., after refresh) but preserve saved selectedMatch
  React.useEffect(() => {
    setSelectedMatch(item.selectedMatch || null);
    setShowMintConfirm(false);
    setMintPreviewLoading(false);
    setMintPreviewError(null);
  }, [item.id, item.reconciliationStatus, item.selectedMatch]);

  // Register/unregister header for sticky behavior
  React.useEffect(() => {
    if (headerRef.current) {
      registerHeader(headerRef.current);
    }
    
    return () => {
      if (headerRef.current) {
        unregisterHeader(headerRef.current);
      }
    };
  }, [registerHeader, unregisterHeader]);

  
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

    // Priority: Check flagged status BEFORE checking for auto-matches
    if (item.status === 'flagged-complete' || item.isFlaggedForReview) {
      return 'flagged-complete';
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
    
    // Return filtered matches (API already provides them sorted)
    return filteredMatches;
  };

  const visibleMatches = getVisibleMatches();

  return (
    <>
      <tr className="parent-row">
        <th scope="row" className="sticky-left row-number">{displayIndex}</th>
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
                    {/* Show Auto-Selected indicator for auto-matched items in judgment-ready state */}
                    {currentStatus === 'judgment-ready' && !selectedMatch && item.hasAutoMatch && !item.isPreReconciled && !item.mintedAs && (
                      <div className="selected-indicator" style={{fontSize: '0.75rem', color: '#059669', marginTop: '4px', marginLeft: '0'}}>
                        ✓ Auto-Selected
                      </div>
                    )}
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
          <div className={`nested-table-container ${(currentStatus === 'reconciled' || currentStatus === 'judgment-ready' || currentStatus === 'mint-ready' || currentStatus === 'flagged') ? 'reconciled-indented' : ''}`}>
            <div className="table-scroll-wrapper">
              <table className="table table-hover table-borderless nested-table">
              <thead className="sticky-top" ref={headerRef}>
                <tr>
                  {/* Only show action column header for entities that need user actions */}
                  {!(currentStatus === 'reconciled' || currentStatus === 'judgment-ready' || currentStatus === 'mint-ready' || currentStatus === 'flagged') && <th style={{width: '100px'}}></th>}
                  <th style={{width: '60px'}}>ID</th>
                  <th style={{minWidth: '300px'}}>Name</th>
                  {/* Show StartDate column for Event entities */}
                  {item.type?.toLowerCase().includes('event') && <th className="text-nowrap">Start Date</th>}
                  {/* Show EndDate column for Event entities */}
                  {item.type?.toLowerCase().includes('event') && <th className="text-nowrap">End Date</th>}
                  {/* Show Location column for Event entities */}
                  {item.type?.toLowerCase().includes('event') && <th className="text-nowrap">Location</th>}
                  {/* Show Location ID column for Event entities */}
                  {item.type?.toLowerCase().includes('event') && <th className="text-nowrap">Location ID</th>}
                  {/* Show PostalCode column for Event entities */}
                  {item.type?.toLowerCase().includes('event') && <th>PostalCode</th>}
                  <th>URL</th>
                  {/* Show Status column for Event entities */}
                  {item.type?.toLowerCase().includes('event') && <th>Status</th>}
                  {/* Show Attendance Mode column for Event entities */}
                  {item.type?.toLowerCase().includes('event') && <th>Attendance</th>}
                  {/* Show Tickets column for Event entities */}
                  {item.type?.toLowerCase().includes('event') && <th>Tickets</th>}
                  {/* Show Performer column for Event entities */}
                  {item.type?.toLowerCase().includes('event') && <th className="text-nowrap">Performer</th>}
                  {/* Only show ISNI column for non-Place and non-Event entities */}
                  {!item.type?.toLowerCase().includes('place') && !item.type?.toLowerCase().includes('event') && <th>ISNI</th>}
                  {/* Only show Wikidata column for non-Event entities */}
                  {!item.type?.toLowerCase().includes('event') && <th>Wikidata</th>}
                  {/* Show PostalCode column for Place entities */}
                  {item.type?.toLowerCase().includes('place') && <th>PostalCode</th>}
                  {/* Show Locality and Region columns for Place entities */}
                  {item.type?.toLowerCase().includes('place') && <th>Locality</th>}
                  {item.type?.toLowerCase().includes('place') && <th>Region</th>}
                  <th>Type</th>
                </tr>
              </thead>
              <tbody>
                {/* Source entity row */}
                <tr className="source-entity-row">
                  {/* Only show user actions td for entities that need user actions */}
                  {!(currentStatus === 'reconciled' || currentStatus === 'judgment-ready' || currentStatus === 'mint-ready' || currentStatus === 'flagged') && (
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
                  )}
                  <td>
                    {canShowEye ? (
                      <button
                        className="eye-externalid-btn"
                        title={item.externalId}
                        onClick={e => { 
                          e.stopPropagation(); 
                          window.open(getArtsdataEntityUrl(item.uri, config), '_blank');
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
                  {/* Show StartDate column for Event entities */}
                  {item.type?.toLowerCase().includes('event') && (
                    <td className="text-nowrap" style={{fontSize: '0.75rem', color: '#6b7280'}}>
                      {item.startDate || ''}
                    </td>
                  )}
                  {/* Show EndDate column for Event entities */}
                  {item.type?.toLowerCase().includes('event') && (
                    <td className="text-nowrap" style={{fontSize: '0.75rem', color: '#6b7280'}}>
                      {item.endDate || ''}
                    </td>
                  )}
                  {/* Show Location column for Event entities */}
                  {item.type?.toLowerCase().includes('event') && (
                    <td className="text-nowrap">
                      {item.locationName || ''}
                    </td>
                  )}
                  {/* Show Location ID column for Event entities */}
                  {item.type?.toLowerCase().includes('event') && (
                    <td className="text-nowrap">
                      {item.locationArtsdataUri ? (
                        <a
                          href={getArtsdataEntityUrl(item.locationArtsdataUri, config)}
                          target="_blank"
                          rel="noopener noreferrer"
                          title={item.locationArtsdataUri}
                        >
                          {item.locationArtsdataUri.split('/').pop()}
                        </a>
                      ) : ''}
                    </td>
                  )}
                  {/* Show PostalCode column for Event entities */}
                  {item.type?.toLowerCase().includes('event') && <td>{item.postalCode || ''}</td>}
                  <td className="text-nowrap">
                    {item.url && (
                      <a href={item.url} target="_blank" rel="noopener noreferrer" title={item.url}>
                        {truncateUrl(item.url)}
                      </a>
                    )}
                  </td>
                  {/* Show Status column for Event entities */}
                  {item.type?.toLowerCase().includes('event') && <td>{extractSchemaStatus(item.eventStatus)}</td>}
                  {/* Show Attendance Mode column for Event entities */}
                  {item.type?.toLowerCase().includes('event') && <td>{extractSchemaStatus(item.eventAttendanceMode)}</td>}
                  {/* Show Tickets column for Event entities */}
                  {item.type?.toLowerCase().includes('event') && (
                    <td className="text-nowrap">
                      {item.offerUrl && (
                        <a href={item.offerUrl} target="_blank" rel="noopener noreferrer" title={item.offerUrl}>
                          {truncateUrl(item.offerUrl)}
                        </a>
                      )}
                    </td>
                  )}
                  {/* Show Performer column for Event entities */}
                  {item.type?.toLowerCase().includes('event') && (
                    <td className="text-nowrap">
                      {item.performerName ? (
                        item.performerName.split(',').map((performer, index) => (
                          <div key={index}>
                            {performer.trim()}
                          </div>
                        ))
                      ) : ''}
                    </td>
                  )}
                  {/* Only show ISNI column for non-Place and non-Event entities */}
                  {!item.type?.toLowerCase().includes('place') && !item.type?.toLowerCase().includes('event') && (
                    <td>
                      {item.isni && (
                        <a href={item.isni} target="_blank" rel="noopener noreferrer" title={item.isni}>
                          {truncateUrl(item.isni)}
                        </a>
                      )}
                    </td>
                  )}
                  {/* Only show Wikidata column for non-Event entities */}
                  {!item.type?.toLowerCase().includes('event') && (
                    <td>
                      {item.wikidata && (
                        <a href={item.wikidata} target="_blank" rel="noopener noreferrer" title={item.wikidata}>
                          {item.wikidataId || truncateUrl(item.wikidata)}
                        </a>
                      )}
                    </td>
                  )}
                  {/* Show PostalCode column for Place entities */}
                  {item.type?.toLowerCase().includes('place') && <td>{item.postalCode || ''}</td>}
                  {/* Show Locality and Region columns for Place entities */}
                  {item.type?.toLowerCase().includes('place') && <td>{item.addressLocality || ''}</td>}
                  {item.type?.toLowerCase().includes('place') && <td>{item.addressRegion || ''}</td>}
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
                      {/* Only show user actions td for entities that need user actions */}
                      {!(currentStatus === 'reconciled' || currentStatus === 'judgment-ready' || currentStatus === 'mint-ready' || currentStatus === 'flagged') && (
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
                        </td>
                      )}
                      <td className="text-nowrap">
                        <a 
                          href={getArtsdataEntityUrl(`http://kg.artsdata.ca/resource/${match.id}`, config)}
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
                      {/* Show StartDate column for Event entities */}
                      {item.type?.toLowerCase().includes('event') && (
                        <td className="text-nowrap" style={{fontSize: '0.75rem', color: '#6b7280'}}>
                          {match.startDate || ''}
                        </td>
                      )}
                      {/* Show EndDate column for Event entities */}
                      {item.type?.toLowerCase().includes('event') && (
                        <td className="text-nowrap" style={{fontSize: '0.75rem', color: '#6b7280'}}>
                          {match.endDate || ''}
                        </td>
                      )}
                      {/* Show Location column for Event entities */}
                      {item.type?.toLowerCase().includes('event') && (
                        <td className="text-nowrap">
                          {match.locationName || ''}
                        </td>
                      )}
                      {/* Show Location ID column for Event entities */}
                      {item.type?.toLowerCase().includes('event') && (
                        <td className="text-nowrap">
                          {match.locationArtsdataUri ? (
                            <a
                              href={getArtsdataEntityUrl(match.locationArtsdataUri, config)}
                              target="_blank"
                              rel="noopener noreferrer"
                              title={match.locationArtsdataUri}
                            >
                              {match.locationArtsdataUri.split('/').pop()}
                            </a>
                          ) : ''}
                        </td>
                      )}
                      {/* Show PostalCode column for Event entities */}
                      {item.type?.toLowerCase().includes('event') && <td>{match.postalCode || ''}</td>}
                      <td className="text-nowrap">
                        {match.url && (
                          <a href={match.url} target="_blank" rel="noopener noreferrer" title={match.url}>
                            {truncateUrl(match.url)}
                          </a>
                        )}
                      </td>
                      {/* Show Status column for Event entities */}
                      {item.type?.toLowerCase().includes('event') && <td>{extractSchemaStatus(match.eventStatus)}</td>}
                      {/* Show Attendance Mode column for Event entities */}
                      {item.type?.toLowerCase().includes('event') && <td>{extractSchemaStatus(match.eventAttendanceMode)}</td>}
                      {/* Show Tickets column for Event entities */}
                      {item.type?.toLowerCase().includes('event') && (
                        <td className="text-nowrap">
                          {match.offerUrl && (
                            <a href={match.offerUrl} target="_blank" rel="noopener noreferrer" title={match.offerUrl}>
                              {truncateUrl(match.offerUrl)}
                            </a>
                          )}
                        </td>
                      )}
                      {/* Show Performer column for Event entities */}
                      {item.type?.toLowerCase().includes('event') && (
                        <td className="text-nowrap">
                          {match.performers && match.performers.length > 0 ? (
                            // Use performers array - always link with ID, display name or fallback to ID
                            match.performers.map((performer, index) => (
                              <div key={index}>
                                <a href={getArtsdataEntityUrl(`http://kg.artsdata.ca/resource/${performer.id}`, config)} target="_blank" rel="noopener noreferrer">
                                  {performer.name || performer.id}
                                </a>
                              </div>
                            ))
                          ) : ''}
                        </td>
                      )}
                      {/* Only show ISNI column for non-Place and non-Event entities */}
                      {!item.type?.toLowerCase().includes('place') && !item.type?.toLowerCase().includes('event') && (
                        <td className="text-nowrap">
                          {match.isni && (
                            <a href={match.isni} target="_blank" rel="noopener noreferrer" title={match.isni}>
                              {truncateUrl(match.isni)}
                            </a>
                          )}
                        </td>
                      )}
                      {/* Only show Wikidata column for non-Event entities */}
                      {!item.type?.toLowerCase().includes('event') && (
                        <td className="text-nowrap">
                          {match.wikidata && (
                            <a href={match.wikidata} target="_blank" rel="noopener noreferrer" title={match.wikidata}>
                              {extractWikidataId(match.wikidata) || truncateUrl(match.wikidata)}
                            </a>
                          )}
                        </td>
                      )}
                      {/* Show PostalCode column for Place entities */}
                      {item.type?.toLowerCase().includes('place') && <td>{match.postalCode || ''}</td>}
                      {/* Show Locality and Region columns for Place entities */}
                      {item.type?.toLowerCase().includes('place') && <td>{match.addressLocality || ''}</td>}
                      {item.type?.toLowerCase().includes('place') && <td>{match.addressRegion || ''}</td>}
                      <td>
                        {extractTypeInfo(match.type).name}
                      </td>
                    </tr>
                  );
                })}
              </tbody>
              </table>
            </div>
          </div>
        </td>
        <td>
          {/* Refresh button */}
          <button
            onClick={e => { e.stopPropagation(); onRefresh && onRefresh(item.id); }}
            className="icon-button"
            title="Refresh row"
          >
            <RefreshCw className="table-icon" />
          </button>
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
