import { useState, useEffect } from "react";
import "bootstrap/dist/css/bootstrap.min.css";
import "bootstrap-icons/font/bootstrap-icons.css";
import "bootstrap/dist/js/bootstrap.bundle.min.js";
import "./App.css";
import FilterControls from "./components/FilterControls";
import TableRow from "./components/TableRow";
import NavigationConfirmation from "./components/NavigationConfirmation";
import TypeSwitchConfirmation from "./components/TypeSwitchConfirmation";
import DataFeedSwitchConfirmation from "./components/DataFeedSwitchConfirmation";
import SearchConfirmation from "./components/SearchConfirmation";
import ShowAllToggleConfirmation from "./components/ShowAllToggleConfirmation";
import AcceptAllConfirmation from "./components/AcceptAllConfirmation";
import AcceptAllProgress from "./components/AcceptAllProgress";
import AcceptAllSummary from "./components/AcceptAllSummary";
import { StickyHeadersProvider } from "./components/StickyHeadersProvider";
import { fetchDynamicData } from "./services/dataFeedService";
import { batchReconcile, previewMint, mintEntity, linkEntity, flagEntity, getReferenceUri } from "./services/reconciliationService";
import { validateGraphUrl } from "./utils/urlValidation";

// Helper function to sort entities by priority: auto-selected first, then needs-judgment, then reconciled
// Secondary sort: alphabetical by name within each priority group
function sortEntitiesByPriority(entities, globalJudgments) {
  const sortedEntities = entities.slice().sort((a, b) => {
    const statusA = getCurrentItemStatus(a, globalJudgments);
    const statusB = getCurrentItemStatus(b, globalJudgments);

    // Define priority order (lower number = higher priority)
    const priorityOrder = {
      'judgment-ready': 1,    // Auto-selected entities (highest priority)
      'needs-judgment': 2,    // Entities needing user decision
      'reconciled': 3,        // Already reconciled entities (lowest priority when showAll is true)
      'mint-ready': 2,        // Treat mint-ready same as needs-judgment
      'flagged': 2,           // Treat flagged same as needs-judgment
      'flagged-complete': 2,  // Treat flagged-complete same as needs-judgment
      'mint-error': 2,        // Treat errors same as needs-judgment
      'link-error': 2         // Treat errors same as needs-judgment
    };

    const priorityA = priorityOrder[statusA] || 999;
    const priorityB = priorityOrder[statusB] || 999;

    // For items with same priority, check if judgment-ready is auto-selected vs manual
    if (priorityA === priorityB && statusA === 'judgment-ready' && statusB === 'judgment-ready') {
      const isAutoSelectedA = a.hasAutoMatch && !globalJudgments.has(a.id);
      const isAutoSelectedB = b.hasAutoMatch && !globalJudgments.has(b.id);

      // Auto-selected entities come before manually selected ones
      if (isAutoSelectedA && !isAutoSelectedB) return -1;
      if (!isAutoSelectedA && isAutoSelectedB) return 1;

      // If both have same auto-selection status, sort alphabetically by name
      if (isAutoSelectedA === isAutoSelectedB) {
        const nameA = (a.name || '').toLowerCase();
        const nameB = (b.name || '').toLowerCase();
        return nameA.localeCompare(nameB);
      }
    }

    // If priorities are different, use priority order
    if (priorityA !== priorityB) {
      return priorityA - priorityB;
    }

    // If same priority but different statuses, sort alphabetically by name
    const nameA = (a.name || '').toLowerCase();
    const nameB = (b.name || '').toLowerCase();
    return nameA.localeCompare(nameB);
  });

  // Reassign originalIndex after priority sorting to maintain correct display order
  return sortedEntities.map((item, index) => ({
    ...item,
    originalIndex: index + 1
  }));
}

// Helper function to calculate current item status (matches TableRow.jsx logic exactly)
function getCurrentItemStatus(item, globalJudgments) {
  if (item.status === 'reconciled' || item.status === 'flagged') {
    return item.status;
  }

  if (item.mintError) {
    return 'mint-error';
  }

  if (item.linkError) {
    return 'link-error';
  }

  // Check if there's a selected match in global judgments
  const judgment = globalJudgments.get(item.id);
  if (judgment && judgment.selectedMatch) {
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

  // Default to needs-judgment
  return 'needs-judgment';
}

// Helper function to get status text for search matching
function getStatusSearchTerms(item, globalJudgments) {
  const currentStatus = getCurrentItemStatus(item, globalJudgments);
  const entityType = item.selectedMintType || item.type?.split('/').pop() || 'Entity';
  const terms = [];
  
  // Add current status terms
  switch (currentStatus) {
    case 'needs-judgment':
      terms.push('select', 'needs judgment');
      break;
    case 'judgment-ready':
      terms.push('match');
      
      // Check if this is an auto-selected match
      const judgment = globalJudgments.get(item.id);
      const hasManualSelection = judgment && judgment.selectedMatch;
      
      // Auto-match detection: check if this entity has an auto-match
      // An entity is "auto-selected" if it has hasAutoMatch=true, regardless of whether
      // it's stored in globalJudgments (since auto-matches are automatically stored there)
      if (item.hasAutoMatch === true) {
        terms.push('auto-selected', 'auto-match', 'auto selected', 'auto match');
      }
      break;
    case 'mint-ready':
      terms.push('mint', `mint ${entityType.toLowerCase()}`);
      break;
    case 'reconciled':
      terms.push('reconciled');
      break;
    case 'mint-error':
      terms.push('mint error', `mint ${entityType.toLowerCase()}`);
      break;
    case 'link-error':
      terms.push('link error');
      break;
    case 'flagged':
      terms.push('flag', 'needs review', 'flagged');
      break;
    case 'flagged-complete':
      terms.push('select', 'flag', 'flagged', 'needs review');
      break;
  }
  
  // Add flag-related terms if item is flagged
  if (item.isFlaggedForReview) {
    terms.push('flag', 'flagged', 'needs review');
  }
  
  return terms;
}

// Enhanced helper for filtering rows - searches all visible content including status/judgment terms
function filterItems(items, filterText, globalJudgments) {
  if (!filterText || filterText.trim() === '') return items;
  const lower = filterText.toLowerCase().trim();
  
  const filteredItems = [];
  
  items.forEach((item) => {
    // Search in parent entity fields (all visible content)
    const parentFields = [
      item.name,
      item.description,
      item.uri,
      item.url,
      item.isni,
      item.wikidata,
      item.postalCode,
      item.addressLocality,
      item.addressRegion,
      item.type,
      item.location,
      item.startDate,
      item.endDate,
      item.externalId,
      item.id?.toString(),
      // Event-specific fields
      item.locationName,
      item.locationArtsdataUri,
      item.eventStatus,
      item.eventAttendanceMode,
      item.offerUrl,
      item.performerName, // Legacy field for backward compatibility
      // Performers array - search through performer names and IDs
      ...(item.performers && Array.isArray(item.performers) ?
          item.performers.map(p => p.name || p.id).filter(Boolean) : [])
    ];
    
    // Check parent entity fields
    const parentMatch = parentFields.some(field => 
      field && typeof field === 'string' && field.toLowerCase().includes(lower)
    );
    
    // Check status/judgment terms
    const statusTerms = getStatusSearchTerms(item, globalJudgments);
    const statusMatch = statusTerms.some(term => 
      term.toLowerCase().includes(lower)
    );
    
    
    // Filter match candidates that match the search term
    let filteredMatches = [];
    if (item.matches && Array.isArray(item.matches)) {
      filteredMatches = item.matches.filter(match => {
        const matchFields = [
          match.name,
          match.description,
          match.id,
          match.url,
          match.isni,
          match.wikidata,
          match.postalCode,
          match.addressLocality,
          match.addressRegion,
          match.type,
          match.score?.toString(),
          // Event-specific match fields
          match.startDate,
          match.endDate,
          match.locationName,
          match.locationArtsdataUri,
          match.eventStatus,
          match.eventAttendanceMode,
          match.offerUrl,
          match.performerName, // Legacy field for backward compatibility
          // Performers array - search through performer names and IDs
          ...(match.performers && Array.isArray(match.performers) ?
              match.performers.map(p => p.name || p.id).filter(Boolean) : []),
          // Handle type arrays and objects
          Array.isArray(match.type) ? 
            match.type.map(t => typeof t === 'object' ? (t.id || t.name) : t).join(' ') :
            (typeof match.type === 'object' ? (match.type.id || match.type.name) : match.type)
        ];
        
        return matchFields.some(field => 
          field && typeof field === 'string' && field.toLowerCase().includes(lower)
        );
      });
    }
    
    // Include item if parent matches OR if any match candidates match OR if status matches
    if (parentMatch || statusMatch || filteredMatches.length > 0) {
      // Create filtered item - always show ALL matches for found parent/child rows
      const filteredItem = { ...item };
      // Keep all matches visible when parent or child rows match the search
      filteredItems.push(filteredItem);
    }
  });
  
  return filteredItems;
}


// Main App Component
const App = ({ config }) => {
  const [dataFeed, setDataFeed] = useState('');
  const [type, setType] = useState("");
  const [region, setRegion] = useState("");
  const [minScore, setMinScore] = useState(50);
  const [showAll, setShowAll] = useState(false); // Default to false (hide reconciled)
  const [filterText, setFilterText] = useState("");
  const [pageSize, setPageSize] = useState(100);
  const [currentPage, setCurrentPage] = useState(1);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState(null);

  // Dynamic data from SPARQL
  const [items, setItems] = useState([]);
  const [reconciledItems, setReconciledItems] = useState([]);
  const [reconciliationStatus, setReconciliationStatus] = useState('idle'); // 'idle', 'loading', 'complete', 'error'
  const [showNavigationConfirm, setShowNavigationConfirm] = useState(false);
  const [pendingNavigation, setPendingNavigation] = useState(null);
  
  // Type switch confirmation state
  const [showTypeSwitchConfirm, setShowTypeSwitchConfirm] = useState(false);
  const [pendingTypeSwitch, setPendingTypeSwitch] = useState(null);
  
  // Data feed switch confirmation state
  const [showDataFeedSwitchConfirm, setShowDataFeedSwitchConfirm] = useState(false);
  const [pendingDataFeedSwitch, setPendingDataFeedSwitch] = useState(null);
  
  // Search confirmation state
  const [showSearchConfirm, setShowSearchConfirm] = useState(false);
  const [pendingSearch, setPendingSearch] = useState(null);
  
  // Show all toggle confirmation state
  const [showShowAllConfirm, setShowShowAllConfirm] = useState(false);
  const [pendingShowAllToggle, setPendingShowAllToggle] = useState(null);
  
  // Accept All popup states
  const [showAcceptAllConfirm, setShowAcceptAllConfirm] = useState(false);
  const [showAcceptAllProgress, setShowAcceptAllProgress] = useState(false);
  const [showAcceptAllSummary, setShowAcceptAllSummary] = useState(false);
  const [acceptAllProgress, setAcceptAllProgress] = useState({
    currentAction: '',
    currentEntity: '',
    processedCount: 0,
    totalCount: 0,
    isComplete: false
  });
  const [acceptAllResults, setAcceptAllResults] = useState({
    successCounts: { matched: 0, minted: 0, flagged: 0 },
    errorCounts: { matchErrors: 0, mintErrors: 0, flagErrors: 0 },
    totalProcessed: 0
  });
  
  // Global judgment storage across all pages
  const [globalJudgments, setGlobalJudgments] = useState(new Map());

  // Flag to track if this is initial load (for sorting) vs user interaction (preserve order)
  const [isInitialSort, setIsInitialSort] = useState(true);

  // Add request sequence tracking to prevent race conditions
  const [requestSequence, setRequestSequence] = useState(0);
  const [abortController, setAbortController] = useState(null);

  // Frontend pagination state for processed results
  const [frontendCurrentPage, setFrontendCurrentPage] = useState(1);
  const [frontendPageSize, setFrontendPageSize] = useState(100);

  // Batch processing state
  const [batchProgress, setBatchProgress] = useState({
    currentBatch: 0,
    totalBatches: 0,
    isProcessing: false
  });

  // Track visited pages for dynamic Accept All count calculation
  const [visitedPages, setVisitedPages] = useState(new Set([1]));

  // URL parameter utilities
  const getUrlParams = () => {
    const urlParams = new URLSearchParams(window.location.search);
    return {
      feedUrl: urlParams.get('feedUrl') || '',
      type: urlParams.get('type') || '',
      region: urlParams.get('region') || '',
      showAll: urlParams.get('showAll') === 'true', // Convert string to boolean
      filterText: urlParams.get('filterText') || ''
    };
  };

  const updateUrlParams = (feedUrl, type, region, showAll, filterText) => {
    const url = new URL(window.location);
    if (feedUrl) {
      url.searchParams.set('feedUrl', feedUrl);
    } else {
      url.searchParams.delete('feedUrl');
    }

    if (type) {
      url.searchParams.set('type', type);
    } else {
      url.searchParams.delete('type');
    }

    if (region) {
      url.searchParams.set('region', region);
    } else {
      url.searchParams.delete('region');
    }
    
    if (showAll) {
      url.searchParams.set('showAll', 'true');
    } else {
      url.searchParams.delete('showAll');
    }
    
    if (filterText && filterText.trim() !== '') {
      url.searchParams.set('filterText', filterText.trim());
    } else {
      url.searchParams.delete('filterText');
    }
    
    // Update the URL without triggering a page reload
    window.history.replaceState({}, '', url.toString());
  };

  // Function to initialize from URL parameters
  const initializeFromUrlParams = () => {
    const urlParams = getUrlParams();
    
    if (urlParams.feedUrl || urlParams.type || urlParams.region || urlParams.showAll || urlParams.filterText) {
      // Set the state from URL parameters to populate input fields and controls
      if (urlParams.feedUrl) {
        setDataFeed(urlParams.feedUrl);
      }
      if (urlParams.type) {
        setType(urlParams.type);
      }
      if (urlParams.region) {
        setRegion(urlParams.region);
      }
      if (urlParams.showAll) {
        setShowAll(urlParams.showAll);
      }
      if (urlParams.filterText) {
        setFilterText(urlParams.filterText);
      }
    }
  };

  // Process initial URL parameters on component mount
  useEffect(() => {
    initializeFromUrlParams();
  }, []); // Run only on component mount

  // Handle browser navigation (back/forward buttons)
  useEffect(() => {
    const handlePopState = (event) => {
      // Re-initialize from URL parameters when user navigates back/forward
      initializeFromUrlParams();
    };

    window.addEventListener('popstate', handlePopState);
    return () => window.removeEventListener('popstate', handlePopState);
  }, []); // Run only on component mount

  // Update URL parameters when filterText changes
  useEffect(() => {
    // Only update URL if other parameters are set (avoid updating URL on initial empty state)
    if (dataFeed || type || region || showAll || filterText) {
      updateUrlParams(dataFeed, type, region, showAll, filterText);
    }
  }, [filterText]);

  // Internal load function that does the actual API call
  const loadDataInternal = async (currentType, currentDataFeed, currentPage, currentPageSize, currentShowAll, currentRegion = '') => {
    // Cancel previous request if it exists
    if (abortController) {
      abortController.abort();
    }

    // Create new abort controller for this request
    const controller = new AbortController();
    setAbortController(controller);

    // Increment sequence number for this request
    const currentSequence = requestSequence + 1;
    setRequestSequence(currentSequence);

    setLoading(true);
    setError(null);
    setReconciliationStatus('idle');

    // Reset sorting flag for new data load - enables initial sorting after reconciliation
    setIsInitialSort(true);
    
    try {
      // Always fetch high limit to process complete dataset through batched reconciliation
      const apiLimit = 2000;

      const data = await fetchDynamicData(currentType, currentDataFeed, currentPage, apiLimit, config, controller.signal, currentRegion);
      
      // Sort API results when showAll is unchecked - non-reconciled first, then reconciled
      let sortedData = data;
      if (!currentShowAll) {
        sortedData = data.sort((a, b) => {
          const aIsReconciled = a.status === 'reconciled' || a.isPreReconciled || a.linkedTo || a.mintedAs;
          const bIsReconciled = b.status === 'reconciled' || b.isPreReconciled || b.linkedTo || b.mintedAs;

          // Non-reconciled entities first (aIsReconciled = false comes before bIsReconciled = true)
          if (!aIsReconciled && bIsReconciled) return -1;
          if (aIsReconciled && !bIsReconciled) return 1;
          return 0; // Keep original order within each group
        });
      }
      
      // Only update state if this is still the latest request
      setRequestSequence(prev => {
        if (currentSequence >= prev) {
          setItems(sortedData);
          setReconciledItems(sortedData); // Initialize with sorted data

          // If there are no items, set reconciliation status to complete immediately
          if (sortedData.length === 0) {
            setReconciliationStatus('complete');
          }
        }
        return prev;
      });
    } catch (err) {
      // Only update error state if this is still the latest request and not aborted
      if (err.name !== 'AbortError') {
        setRequestSequence(prev => {
          if (currentSequence >= prev) {
            setError(err.message);
            console.error('Error loading data:', err);
          }
          return prev;
        });
      }
    } finally {
      // Only update loading state if this is still the latest request
      setRequestSequence(prev => {
        if (currentSequence >= prev) {
          setLoading(false);
        }
        return prev;
      });
    }
  };

  // Load data when page changes
  useEffect(() => {
    // Only load if we have both type and dataFeed filled, and URL is valid
    if (type && type.trim() !== '' && dataFeed && dataFeed.trim() !== '') {
      const validation = validateGraphUrl(dataFeed);
      if (validation.isValid && !validation.isWarning) {
        loadDataInternal(type, dataFeed, currentPage, pageSize, showAll, region);
      }
    }

    // Cleanup function to cancel any pending requests when component unmounts
    return () => {
      if (abortController) {
        abortController.abort();
      }
    };
  }, [currentPage, pageSize, type, dataFeed]);

  // Separate effect to apply saved judgments when items change
  useEffect(() => {
    if (items.length > 0) {
      const dataWithSavedJudgments = items.map(item => {
        const savedJudgment = globalJudgments.get(item.id);
        return savedJudgment ? { ...item, ...savedJudgment } : item;
      });
      setReconciledItems(dataWithSavedJudgments);
    }
  }, [items]); // Remove globalJudgments dependency to prevent overwriting reconciliation data

  // Auto-store auto-matches in globalJudgments when reconciliation completes
  useEffect(() => {
    if (reconciliationStatus === 'complete' && reconciledItems.length > 0) {
      const newGlobalJudgments = new Map(globalJudgments);
      let hasNewAutoMatches = false;

      reconciledItems.forEach(item => {
        // If item has auto-match and isn't already in global storage, add it
        if (item.hasAutoMatch && item.autoMatchCandidate && !newGlobalJudgments.has(item.id)) {
          newGlobalJudgments.set(item.id, {
            ...item,
            status: 'judgment-ready',
            selectedMatch: item.autoMatchCandidate
          });
          hasNewAutoMatches = true;
        }
      });

      if (hasNewAutoMatches) {
        setGlobalJudgments(newGlobalJudgments);
      }
    }
  }, [reconciliationStatus, reconciledItems]);

  // Batch reconciliation effect - runs when items change
  useEffect(() => {
    if (items.length === 0) return;

    const performBatchReconciliation = async () => {
      setReconciliationStatus('loading');
      setBatchProgress({ currentBatch: 0, totalBatches: 0, isProcessing: true });

      try {
        // Add schema: prefix for reconciliation API
        const schemaType = `schema:${type}`;

        // Get current globalJudgments to filter items
        const currentGlobalJudgments = globalJudgments;

        // Process ALL entities through batched reconciliation - no filtering by showAll
        // This ensures we have complete data for pagination and search
        const itemsToReconcile = items.filter(item => !currentGlobalJudgments.has(item.id));

        if (itemsToReconcile.length > 0) {
          // Progress callback for batch processing
          const onProgress = (progress) => {
            setBatchProgress(progress);
          };

          // Batch reconcile ALL items with 100-entity payloads
          const reconciled = await batchReconcile(itemsToReconcile, schemaType, 100, config, onProgress);

          // Update reconciledItems with the new reconciled data
          setReconciledItems(prev => {
            // Update all items that exist in the current data set
            let updatedItems = prev.map(item => {
              const reconciledItem = reconciled.find(r => r.id === item.id);
              if (reconciledItem) {
                // Ensure enriched match candidates are properly merged
                return {
                  ...item,
                  ...reconciledItem,
                  // Make sure matches array contains the enriched candidates
                  matches: reconciledItem.matches || item.matches || []
                };
              }
              return item;
            });

            // Apply initial sorting only if this is the first reconciliation after data load
            if (isInitialSort) {
              updatedItems = sortEntitiesByPriority(updatedItems, globalJudgments);
              setIsInitialSort(false); // Disable sorting for subsequent updates
            }

            return updatedItems;
          });
        } else {
          // No items to reconcile, but still apply sorting if needed
          setReconciledItems(prev => {
            if (isInitialSort) {
              const updatedItems = sortEntitiesByPriority(prev, globalJudgments);
              setIsInitialSort(false);
              return updatedItems;
            }
            return prev;
          });
        }

        setReconciliationStatus('complete');
        setBatchProgress({ currentBatch: 0, totalBatches: 0, isProcessing: false });
      } catch (err) {
        console.error('Error during batch reconciliation:', err);
        setReconciliationStatus('error');
        setBatchProgress({ currentBatch: 0, totalBatches: 0, isProcessing: false });
      }
    };

    // Always perform reconciliation when items change
    performBatchReconciliation();
  }, [items, type]);


  // Check if there's unsaved work
  const hasUnsavedWork = () => {
    return reconciledItems.some(item => 
      item.status !== 'Select' && 
      item.status !== 'Auto-matched' && 
      item.status !== 'Skipped'
    );
  };

  // Handle navigation confirmation
  const handleNavigationAttempt = (callback) => {
    if (hasUnsavedWork()) {
      setPendingNavigation(() => callback);
      setShowNavigationConfirm(true);
    } else {
      callback();
    }
  };

  const handleConfirmNavigation = () => {
    setShowNavigationConfirm(false);
    if (pendingNavigation) {
      pendingNavigation();
      setPendingNavigation(null);
    }
  };

  const handleCancelNavigation = () => {
    setShowNavigationConfirm(false);
    setPendingNavigation(null);
  };

  // Check if there are unsaved judgments ready to accept
  const getUnsavedJudgmentCount = () => {
    const globalReadyItems = Array.from(globalJudgments.values()).filter(item => 
      // Exclude pre-reconciled entities from unsaved work count
      !item.isPreReconciled &&
      (item.mintReady || item.linkedTo || item.status === 'mint-ready' || item.status === 'judgment-ready' || item.status === 'flagged' ||
      (item.hasAutoMatch && item.autoMatchCandidate) || (item.selectedMatch && !item.linkedTo))
    );
    
    const currentPageReadyItems = reconciledItems.filter(item => {
      if (globalJudgments.has(item.id)) return false;
      // Exclude pre-reconciled entities from unsaved work count
      if (item.isPreReconciled) return false;
      return item.mintReady || item.linkedTo || item.status === 'mint-ready' || item.status === 'judgment-ready' || item.status === 'flagged' ||
             (item.hasAutoMatch && item.autoMatchCandidate) || (item.selectedMatch && !item.linkedTo);
    });
    
    return globalReadyItems.length + currentPageReadyItems.length;
  };

  // Handle type switch confirmation
  const handleTypeSwitch = (newType) => {
    const unsavedCount = getUnsavedJudgmentCount();
    
    if (unsavedCount > 0) {
      setPendingTypeSwitch(newType);
      setShowTypeSwitchConfirm(true);
    } else {
      // No unsaved work, switch directly
      performTypeSwitch(newType);
    }
  };

  const performTypeSwitch = (newType) => {
    // Clear previous results when switching types
    setItems([]);
    setReconciledItems([]);
    setGlobalJudgments(new Map());
    setReconciliationStatus('idle');
    setError(null);

    // Set the new type
    setType(newType);
    setCurrentPage(1); // Reset to first page
    setFrontendCurrentPage(1); // Reset frontend pagination
  };

  const handleTypeSwitchAcceptAll = () => {
    // Accept all current judgments first
    handleAcceptAll();
    
    // Then switch to new type
    if (pendingTypeSwitch) {
      performTypeSwitch(pendingTypeSwitch);
    }
    
    // Close confirmation
    setShowTypeSwitchConfirm(false);
    setPendingTypeSwitch(null);
  };

  const handleTypeSwitchContinue = () => {
    // Switch to new type and lose work
    if (pendingTypeSwitch) {
      performTypeSwitch(pendingTypeSwitch);
    }
    
    // Close confirmation
    setShowTypeSwitchConfirm(false);
    setPendingTypeSwitch(null);
  };

  const handleTypeSwitchCancel = () => {
    // Cancel the type switch
    setShowTypeSwitchConfirm(false);
    setPendingTypeSwitch(null);
  };

  // Handle data feed switch confirmation
  const handleDataFeedSwitch = (newDataFeed) => {
    const unsavedCount = getUnsavedJudgmentCount();
    
    if (unsavedCount > 0) {
      setPendingDataFeedSwitch(newDataFeed);
      setShowDataFeedSwitchConfirm(true);
    } else {
      // No unsaved work, switch directly
      performDataFeedSwitch(newDataFeed);
    }
  };

  const performDataFeedSwitch = (newDataFeed) => {
    // Clear previous results when switching data feeds
    setItems([]);
    setReconciledItems([]);
    setGlobalJudgments(new Map());
    setReconciliationStatus('idle');
    setError(null);

    // Set the new data feed
    setDataFeed(newDataFeed);
    setCurrentPage(1); // Reset to first page
    setFrontendCurrentPage(1); // Reset frontend pagination
  };

  const handleDataFeedSwitchAcceptAll = () => {
    // Accept all current judgments first
    handleAcceptAll();
    
    // Then switch to new data feed
    if (pendingDataFeedSwitch) {
      performDataFeedSwitch(pendingDataFeedSwitch);
    }
    
    // Close confirmation
    setShowDataFeedSwitchConfirm(false);
    setPendingDataFeedSwitch(null);
  };

  const handleDataFeedSwitchContinue = () => {
    // Switch to new data feed and lose work
    if (pendingDataFeedSwitch) {
      performDataFeedSwitch(pendingDataFeedSwitch);
    }
    
    // Close confirmation
    setShowDataFeedSwitchConfirm(false);
    setPendingDataFeedSwitch(null);
  };

  const handleDataFeedSwitchCancel = () => {
    // Cancel the data feed switch
    setShowDataFeedSwitchConfirm(false);
    setPendingDataFeedSwitch(null);
  };

  // Handle search request
  const handleSearch = (newDataFeed, newType, newRegion = '') => {
    const unsavedCount = getUnsavedJudgmentCount();

    if (unsavedCount > 0) {
      setPendingSearch({ dataFeed: newDataFeed, type: newType, region: newRegion });
      setShowSearchConfirm(true);
    } else {
      // No unsaved work, search directly
      performSearch(newDataFeed, newType, newRegion);
    }
  };

  const performSearch = (newDataFeed, newType, newRegion = '') => {
    // Clear previous results when performing new search
    setItems([]);
    setReconciledItems([]);
    setGlobalJudgments(new Map());
    setReconciliationStatus('idle');
    setError(null);
    // Reset pagination and visited pages for new search
    setFrontendCurrentPage(1);
    setVisitedPages(new Set([1]));

    // Update URL parameters first
    updateUrlParams(newDataFeed, newType, newRegion, showAll, filterText);

    // Update the state variables
    setDataFeed(newDataFeed);
    setType(newType);
    setRegion(newRegion);
    setCurrentPage(1); // Reset to first page

    // Force API call even if values haven't changed (for manual search)
    const validation = validateGraphUrl(newDataFeed);
    if (validation.isValid && !validation.isWarning) {
      loadDataInternal(newType, newDataFeed, 1, pageSize, showAll, newRegion);
    }
  };

  const handleSearchAcceptAll = () => {
    // Accept all current judgments first
    handleAcceptAll();

    // Then perform search
    if (pendingSearch) {
      performSearch(pendingSearch.dataFeed, pendingSearch.type, pendingSearch.region);
    }

    // Close confirmation
    setShowSearchConfirm(false);
    setPendingSearch(null);
  };

  const handleSearchContinue = () => {
    // Search and lose work
    if (pendingSearch) {
      performSearch(pendingSearch.dataFeed, pendingSearch.type, pendingSearch.region);
    }

    // Close confirmation
    setShowSearchConfirm(false);
    setPendingSearch(null);
  };

  const handleSearchCancel = () => {
    // Cancel the search
    setShowSearchConfirm(false);
    setPendingSearch(null);
  };

  // Handle show all toggle request
  const handleShowAllToggle = (newShowAllValue) => {
    const unsavedCount = getUnsavedJudgmentCount();
    
    if (unsavedCount > 0) {
      setPendingShowAllToggle(newShowAllValue);
      setShowShowAllConfirm(true);
    } else {
      // No unsaved work, toggle directly
      performShowAllToggle(newShowAllValue);
    }
  };

  const performShowAllToggle = (newShowAllValue) => {
    // Clear previous results when toggling show all
    setItems([]);
    setReconciledItems([]);
    setGlobalJudgments(new Map());
    setReconciliationStatus('idle');
    setError(null);

    // Set the new show all value
    setShowAll(newShowAllValue);
    setCurrentPage(1); // Reset to first page
    setFrontendCurrentPage(1); // Reset frontend pagination
    
    // Update URL parameters to reflect the new showAll state
    updateUrlParams(dataFeed, type, region, newShowAllValue, filterText);
    
    // Reload data with new show all setting
    const validation = validateGraphUrl(dataFeed);
    if (dataFeed && dataFeed.trim() !== '' && type && type.trim() !== '' && validation.isValid && !validation.isWarning) {
      loadDataInternal(type, dataFeed, 1, pageSize, newShowAllValue, region);
    }
  };

  const handleShowAllToggleAcceptAll = () => {
    // Accept all current judgments first
    handleAcceptAll();
    
    // Then toggle show all
    if (pendingShowAllToggle !== null) {
      performShowAllToggle(pendingShowAllToggle);
    }
    
    // Close confirmation
    setShowShowAllConfirm(false);
    setPendingShowAllToggle(null);
  };

  const handleShowAllToggleContinue = () => {
    // Toggle show all and lose work
    if (pendingShowAllToggle !== null) {
      performShowAllToggle(pendingShowAllToggle);
    }
    
    // Close confirmation
    setShowShowAllConfirm(false);
    setPendingShowAllToggle(null);
  };

  const handleShowAllToggleCancel = () => {
    // Cancel the show all toggle
    setShowShowAllConfirm(false);
    setPendingShowAllToggle(null);
  };

  // Override browser back/forward navigation
  useEffect(() => {
    const handleBeforeUnload = (e) => {
      if (hasUnsavedWork()) {
        e.preventDefault();
        e.returnValue = '';
      }
    };

    window.addEventListener('beforeunload', handleBeforeUnload);
    return () => window.removeEventListener('beforeunload', handleBeforeUnload);
  }, [reconciledItems]);

  const handleAction = async (itemId, action, matchCandidate = null, selectedType = null) => {
    const item = reconciledItems.find(item => item.id === itemId);
    if (!item) return;

    // Disable sorting for subsequent updates - user is making manual interactions
    setIsInitialSort(false);

    try {
      let updateData = {};
      
      if (action === "mint_preview") {
        // Preview mint first - use selectedType if provided, otherwise fall back to current type
        const entityType = selectedType || type;
        const schemaType = `schema:${entityType}`; // Add schema: prefix for mint API
        const previewResult = await previewMint(item.uri, schemaType, config);
        
        if (previewResult.status === 'success') {
          updateData = {
            mintReady: true,
            mintError: null,
            selectedMintType: entityType // Save the selected type for mint_final
          };
        } else {
          throw new Error(previewResult.message || 'Mint preview failed');
        }
      } else if (action === "mint_final") {
        // Perform actual mint - use saved selectedMintType if available, otherwise fall back to current type
        const entityType = item.selectedMintType || type;
        const schemaType = `schema:${entityType}`; // Add schema: prefix for mint API
        const mintResult = await mintEntity(item.uri, schemaType, dataFeed, config);
        
        updateData = {
          status: "reconciled",
          mintedAs: `${entityType.toLowerCase()}`,
          actionError: null
        };
        
        // Auto-refresh match results to find the newly minted entity
        // Extract the Artsdata ID from the mint response
        let mintedEntityId = null;
        if (mintResult.new_uri) {
          const uriParts = mintResult.new_uri.split('/');
          mintedEntityId = uriParts[uriParts.length - 1];
        }
        
        // Create a temporary item with reconciled status for re-reconciliation
        const itemForRefresh = { ...item, ...updateData };
        const reconciled = await batchReconcile([itemForRefresh], schemaType, 1, config);
        
        if (reconciled.length > 0) {
          // Merge the reconciliation results with our update data, but preserve the reconciled status
          updateData = { 
            ...reconciled[0], // Get fresh matches and reconciliation data
            ...updateData     // Preserve our reconciled status and mint info
          };
          
          // Find the newly minted entity in the matches using the exact ID
          const matches = reconciled[0].matches || [];
          const mintedMatch = matches.find(match => match.id === mintedEntityId);
          
          if (mintedMatch) {
            updateData.linkedTo = mintedEntityId;
            updateData.linkedToName = mintedMatch.name;
          }
        }
      } else if (action === "link" && matchCandidate) {
        // Link to matched entity - use schema: format for classToLink
        const classToLink = `schema:${type}`;
        const adUri = `http://kg.artsdata.ca/resource/${matchCandidate.id}`;
        const linkResult = await linkEntity(item.uri, classToLink, adUri, config);
        updateData = {
          status: "reconciled",
          linkedTo: matchCandidate.id,
          linkedToName: matchCandidate.name,
          linkError: null,
          actionError: null
        };
      } else if (action === "flag") {
        // Just set flagged status when flag link is clicked (no API call yet)
        updateData = {
          status: "flagged",
          actionError: null
        };
      } else if (action === "flag_final") {
        // Call flag API when blue Flag button is clicked
        try {
          await flagEntity(item.uri, config);
          updateData = {
            status: "flagged-complete", // New status for successfully flagged entities
            isFlaggedForReview: true, // Mark as flagged for review
            actionError: null
          };
        } catch (error) {
          console.error(`Failed to flag entity: ${item.name} (${item.uri})`, error);
          updateData = {
            actionError: `Flag failed: ${error.message}`
          };
        }
      } else if (action === "reset_mint") {
        // Reset mint state when user clicks Change from mint-ready
        updateData = {
          mintReady: false,
          mintError: null,
          selectedMatch: null,
          selectedMintType: null,
          actionError: null
        };
      } else if (action === "reset_judgment") {
        // Reset judgment state when user clicks Change from judgment-ready (for auto-matches)
        updateData = {
          hasAutoMatch: false,
          autoMatchCandidate: null,
          selectedMatch: null,
          actionError: null
        };
      } else if (action === "select_match") {
        // Save match selection for cross-page persistence
        updateData = {
          selectedMatch: matchCandidate,
          actionError: null
        };
      } else if (action === "reset_link_error") {
        // Reset link error state when user clicks Change from link-error
        updateData = {
          linkError: null,
          actionError: null,
          selectedMatch: null
        };
      } else if (action === "reset_flag") {
        // Reset flag state when user clicks Change from flagged
        updateData = {
          status: 'needs-judgment',
          actionError: null
        };
      }

      const updatedItem = {
        ...item,
        ...updateData
      };
      
      // Save judgment to global storage for cross-page persistence
      setGlobalJudgments(prev => {
        const newMap = new Map(prev);
        newMap.set(itemId, updatedItem);
        return newMap;
      });
      
      setReconciledItems(
        reconciledItems.map((reconciledItem) =>
          reconciledItem.id === itemId
            ? {
                ...reconciledItem, // Preserve reconciliation data like matches
                ...updateData       // Apply the new judgment data
              }
            : reconciledItem
        )
      );
    } catch (error) {
      console.error('Error performing action:', error);
      
      // Determine error type based on action
      let errorData = { actionError: error.message };
      if (action === "mint_preview" || action === "mint_final") {
        errorData.mintError = error.message;
      } else if (action === "link") {
        errorData.linkError = error.message;
        // Keep the item in judgment-ready state so user can change selection
        errorData.status = item.status || 'judgment-ready';
      }
      
      // Update item with error state
      const errorItem = {
        ...item,
        ...errorData
      };
      
      // Save error state to global storage
      setGlobalJudgments(prev => {
        const newMap = new Map(prev);
        newMap.set(itemId, errorItem);
        return newMap;
      });
      
      setReconciledItems(
        reconciledItems.map((reconciledItem) =>
          reconciledItem.id === itemId
            ? {
                ...reconciledItem, // Preserve reconciliation data like matches
                ...errorData
              }
            : reconciledItem
        )
      );
    }
  };


  // Reset to page 1 when showAll changes
  useEffect(() => {
    setCurrentPage(1);
  }, [showAll]);

  const handleAcceptAll = () => {
    if (currentPageReadyItems.length === 0) {
      return;
    }

    // Count entities by action type
    let matchCount = 0;
    let mintCount = 0;
    let flagCount = 0;

    currentPageReadyItems.forEach(item => {
      const currentStatus = getCurrentItemStatus(item, globalJudgments);
      if (currentStatus === 'judgment-ready') {
        matchCount++;
      } else if (currentStatus === 'mint-ready') {
        mintCount++;
      } else if (currentStatus === 'flagged') {
        flagCount++;
      }
    });

    // Show confirmation popup with counts
    setAcceptAllResults({
      matchCount,
      mintCount,
      flagCount,
      totalCount: currentPageReadyItems.length
    });
    setShowAcceptAllConfirm(true);
  };
  
  const handleAcceptAllConfirm = async () => {
    setShowAcceptAllConfirm(false);
    
    // Use the same items that were counted for Accept All
    const itemsToProcess = currentPageReadyItems;
    
    // Initialize progress
    setAcceptAllProgress({
      currentAction: '',
      currentEntity: '',
      processedCount: 0,
      totalCount: itemsToProcess.length,
      isComplete: false
    });
    setShowAcceptAllProgress(true);
    
    // Process each entity
    const results = {
      successCounts: { matched: 0, minted: 0, flagged: 0 },
      errorCounts: { matchErrors: 0, mintErrors: 0, flagErrors: 0 },
      totalProcessed: itemsToProcess.length
    };
    
    for (let i = 0; i < itemsToProcess.length; i++) {
      const item = itemsToProcess[i];
      const currentStatus = getCurrentItemStatus(item, globalJudgments);
      
      try {
        if (currentStatus === 'judgment-ready') {
          // Update progress
          setAcceptAllProgress(prev => ({
            ...prev,
            currentAction: 'matching',
            currentEntity: item.name,
            processedCount: i
          }));
          
          // Get the selected match
          const judgment = globalJudgments.get(item.id);
          let matchToLink = judgment?.selectedMatch;
          
          if (!matchToLink && item.matches) {
            // Auto-match case - find the true match
            const trueMatches = item.matches.filter(match => match.match === true);
            if (trueMatches.length === 1) {
              matchToLink = trueMatches[0];
            }
          }
          
          if (matchToLink) {
            // Use schema: format for classToLink and full Artsdata URI for adUri
            const classToLink = `schema:${type}`;
            const adUri = `http://kg.artsdata.ca/resource/${matchToLink.id}`;
            await linkEntity(item.uri, classToLink, adUri, config);
            results.successCounts.matched++;
          }
        } else if (currentStatus === 'mint-ready') {
          // Update progress
          setAcceptAllProgress(prev => ({
            ...prev,
            currentAction: 'minting',
            currentEntity: item.name,
            processedCount: i
          }));
          
          // Get the class to mint from judgment or item
          const judgment = globalJudgments.get(item.id);
          let classToMint = judgment?.selectedMintType || item.type;
          
          // Ensure schema: prefix is present for mint API
          if (classToMint && !classToMint.startsWith('schema:')) {
            classToMint = `schema:${classToMint}`;
          }
          
          // Extract feed identifier from data feed URL
          const feedIdentifier = dataFeed.split('/').pop() || dataFeed;
          const referenceUri = getReferenceUri(feedIdentifier);
          
          await mintEntity(item.uri, classToMint, referenceUri, config);
          results.successCounts.minted++;
        } else if (currentStatus === 'flagged') {
          // Update progress
          setAcceptAllProgress(prev => ({
            ...prev,
            currentAction: 'flagging',
            currentEntity: item.name,
            processedCount: i
          }));
          
          await flagEntity(item.uri, config);
          results.successCounts.flagged++;
        }
      } catch (error) {
        console.error(`Failed to process entity: ${item.name} (${item.uri})`, error);
        
        // Count errors by type
        if (currentStatus === 'judgment-ready') {
          results.errorCounts.matchErrors++;
        } else if (currentStatus === 'mint-ready') {
          results.errorCounts.mintErrors++;
        } else if (currentStatus === 'flagged') {
          results.errorCounts.flagErrors++;
        }
      }
    }
    
    // Mark progress as complete
    setAcceptAllProgress(prev => ({
      ...prev,
      processedCount: itemsToProcess.length,
      isComplete: true
    }));
    
    // Show completion briefly, then show summary
    setTimeout(() => {
      setShowAcceptAllProgress(false);
      setAcceptAllResults(results);
      setShowAcceptAllSummary(true);
    }, 1500);
  };
  
  const handleAcceptAllCancel = () => {
    setShowAcceptAllConfirm(false);
  };
  
  const handleAcceptAllSummaryClose = () => {
    setShowAcceptAllSummary(false);

    // Clear all saved judgments for fresh start
    setGlobalJudgments(new Map());

    // Reset frontend pagination to page 1
    setFrontendCurrentPage(1);

    // Reload data with existing filters
    if (dataFeed && dataFeed.trim() !== '' && type && type.trim() !== '') {
      const validation = validateGraphUrl(dataFeed);
      if (validation.isValid && !validation.isWarning) {
        loadDataInternal(type, dataFeed, 1, pageSize, showAll, region);
      }
    }
  };

  const handleRefreshRow = async (id) => {
    try {
      // Find the original item from the items array (before reconciliation)
      const originalItem = items.find(item => item.id === id);
      if (!originalItem) return;
      
      // Reset the item to its original state as if viewed for the first time
      const resetItem = {
        ...originalItem,
        // Clear all reconciliation data
        matches: [],
        hasAutoMatch: false,
        autoMatchCandidate: null,
        status: 'needs-judgment', // Reset to initial state
        reconciliationError: null,
        mintReady: false,
        mintError: null,
        linkedTo: null,
        linkedToName: null,
        actionError: null
      };
      
      // Update the item in the list to show loading state
      setReconciledItems(prev => 
        prev.map(prevItem => 
          prevItem.id === id ? { ...resetItem, reconciliationStatus: 'loading' } : prevItem
        )
      );
      
      // Perform fresh reconciliation for this single item
      const schemaType = `schema:${type}`; // Add schema: prefix for reconciliation API
      const reconciled = await batchReconcile([resetItem], schemaType, 1, config);
      
      if (reconciled.length > 0) {
        // Update with fresh reconciled data
        setReconciledItems(prev => 
          prev.map(prevItem => 
            prevItem.id === id ? { ...reconciled[0], reconciliationStatus: 'complete' } : prevItem
          )
        );
      }
    } catch (error) {
      console.error('Error refreshing row:', error);
      // Show error in the item
      setReconciledItems(prev => 
        prev.map(prevItem => 
          prevItem.id === id 
            ? { 
                ...prevItem, 
                reconciliationError: error.message,
                reconciliationStatus: 'error'
              }
            : prevItem
        )
      );
    }
  };

  // Apply "Show All" filter BEFORE search filtering
  let itemsAfterShowAllFilter = reconciledItems;
  if (!showAll) {
    itemsAfterShowAllFilter = reconciledItems.filter(item => {
      // Hide pre-reconciled entities (entities that were already reconciled when loaded)
      if (item.status === 'reconciled' || item.linkedTo || item.mintedAs || item.isPreReconciled) {
        return false;
      }

      // Hide flagged entities (entities flagged for review) when show all is unchecked
      if (item.status === 'flagged-complete') {
        return false;
      }

      // Show all other non-reconciled entities
      return true;
    });
  }

  // Then apply search filtering to the show-all-filtered items
  let filtered = filterItems(itemsAfterShowAllFilter, filterText, globalJudgments);

  // Apply frontend pagination to complete filtered dataset
  const totalFilteredItems = filtered.length;
  const totalPages = Math.ceil(totalFilteredItems / frontendPageSize);
  const startIndex = (frontendCurrentPage - 1) * frontendPageSize;
  const endIndex = startIndex + frontendPageSize;
  const currentPageItems = filtered.slice(startIndex, endIndex);

  // Reset to page 1 if current page is beyond available pages
  useEffect(() => {
    if (frontendCurrentPage > totalPages && totalPages > 0) {
      setFrontendCurrentPage(1);
    }
  }, [totalPages, frontendCurrentPage]);

  // Track visited pages for dynamic Accept All count
  useEffect(() => {
    if (totalPages > 0) {
      setVisitedPages(prev => new Set([...prev, frontendCurrentPage]));
    }
  }, [frontendCurrentPage, totalPages]);

  // Calculate dynamic Accept All count based on user interactions across visited pages
  const calculateDynamicAcceptCount = () => {
    // Count items from global judgments (user has acted upon these)
    const globalReadyItems = Array.from(globalJudgments.values()).filter(item =>
      // Exclude pre-reconciled entities from accept all count
      !item.isPreReconciled &&
      (item.mintReady || item.linkedTo || item.status === 'mint-ready' || item.status === 'judgment-ready' || item.status === 'flagged' ||
      (item.hasAutoMatch && item.autoMatchCandidate) || (item.selectedMatch && !item.linkedTo))
    );

    // Count items from visited pages that user has seen and are ready
    let visitedPageReadyItems = 0;

    // Use the properly filtered items (already filtered by showAll above)
    const allFilteredItems = filtered;

    // Only count items from pages the user has actually visited
    visitedPages.forEach(pageNum => {
      const pageStartIndex = (pageNum - 1) * frontendPageSize;
      const pageEndIndex = pageStartIndex + frontendPageSize;
      const pageItems = allFilteredItems.slice(pageStartIndex, pageEndIndex);

      pageItems.forEach(item => {
        // Skip if already in global storage or pre-reconciled
        if (globalJudgments.has(item.id) || item.isPreReconciled) return;

        // Check if item is ready to accept
        const isReady = item.mintReady || item.linkedTo || item.status === 'mint-ready' ||
                       item.status === 'judgment-ready' || item.status === 'flagged' ||
                       (item.hasAutoMatch && item.autoMatchCandidate) ||
                       (item.selectedMatch && !item.linkedTo);
        if (isReady) {
          visitedPageReadyItems++;
        }
      });
    });

    return globalReadyItems.length + visitedPageReadyItems;
  };

  const itemsReadyToAccept = calculateDynamicAcceptCount();

  // Get items ready to accept from current page only (used by Accept All)
  const currentPageReadyItems = currentPageItems.filter(item => {
    // Exclude pre-reconciled entities from accept all
    if (item.isPreReconciled) return false;

    const currentStatus = getCurrentItemStatus(item, globalJudgments);

    // Exclude already processed entities
    if (currentStatus === 'reconciled') return false; // Already matched/minted
    if (currentStatus === 'flagged-complete') return false; // Already flagged via API

    // Only include entities that have action buttons ready (not already processed)
    return currentStatus === 'judgment-ready' || currentStatus === 'mint-ready' || currentStatus === 'flagged';
  });

  return (
    <StickyHeadersProvider>
      <div className="app">
        
        <FilterControls
        dataFeed={dataFeed}
        setDataFeed={handleDataFeedSwitch}
        type={type}
        setType={handleTypeSwitch}
        region={region}
        setRegion={setRegion}
        minScore={minScore}
        setMinScore={setMinScore}
        showAll={showAll}
        setShowAll={setShowAll}
        filterText={filterText}
        setFilterText={setFilterText}
        pageSize={pageSize}
        setPageSize={setPageSize}
        loading={loading}
        error={error}
        onAcceptAll={handleAcceptAll}
        totalItems={itemsReadyToAccept}
        currentPage={currentPage}
        setCurrentPage={setCurrentPage}
        hasResults={currentPageItems.length > 0}
        onSearch={handleSearch}
        onShowAllToggle={handleShowAllToggle}
        // Frontend pagination props
        frontendCurrentPage={frontendCurrentPage}
        setFrontendCurrentPage={setFrontendCurrentPage}
        frontendPageSize={frontendPageSize}
        setFrontendPageSize={setFrontendPageSize}
        totalFilteredItems={totalFilteredItems}
        totalPages={totalPages}
        reconciliationStatus={reconciliationStatus}
      />

      <div className={`table-container ${currentPageItems.length === 0 ? 'empty-state' : ''}`}>
        {loading && (
          <div className="alert alert-info" role="alert">
            <div className="d-flex align-items-center">
              <div className="spinner-border spinner-border-sm me-2" role="status">
                <span className="visually-hidden">Loading...</span>
              </div>
              Loading data from Artsdata...
            </div>
          </div>
        )}
        
        {reconciliationStatus === 'loading' && (
          <div className="alert alert-info" role="alert">
            <div className="d-flex align-items-center">
              <div className="spinner-border spinner-border-sm me-2" role="status">
                <span className="visually-hidden">Loading...</span>
              </div>
              {batchProgress.isProcessing && batchProgress.totalBatches > 0 ? (
                <span>
                  Processing batch {batchProgress.currentBatch} of {batchProgress.totalBatches}{' '}
                  ({batchProgress.entitiesProcessed || 0} / {batchProgress.totalEntities || 0} entities)...
                </span>
              ) : (
                <span>Running batch reconciliation...</span>
              )}
            </div>
            {batchProgress.isProcessing && batchProgress.totalBatches > 0 && (
              <div className="progress mt-2" style={{ height: '4px' }}>
                <div
                  className="progress-bar"
                  role="progressbar"
                  style={{ width: `${(batchProgress.currentBatch / batchProgress.totalBatches) * 100}%` }}
                  aria-valuenow={batchProgress.currentBatch}
                  aria-valuemin="0"
                  aria-valuemax={batchProgress.totalBatches}
                ></div>
              </div>
            )}
          </div>
        )}
        
        {error && (
          <div className="alert alert-danger" role="alert">
            <strong>Error loading data:</strong> {error}
            {error.includes('404') && (
              <div className="mt-2">
                <small className="text-muted">
                  • Verify the data feed URL is correct and accessible<br/>
                  • Check if the graph URL exists in the knowledge base<br/>
                  • Ensure you have permission to access this data feed
                </small>
              </div>
            )}
            {error.includes('400') && (
              <div className="mt-2">
                <small className="text-muted">
                  • Check that the entity type matches available types (Event, Person, Organization, Place, Agent)<br/>
                  • Verify the data feed URL format is correct<br/>
                  • Ensure the region code is valid (if specified)
                </small>
              </div>
            )}
            {(error.includes('500') || error.includes('503')) && (
              <div className="mt-2">
                <small className="text-muted">
                  • The data feed service is experiencing issues<br/>
                  • Please wait a few moments and try again<br/>
                  • Contact support if the issue persists
                </small>
              </div>
            )}
          </div>
        )}
        
        {!loading && !error && ((!dataFeed || dataFeed.trim() === '') || (!type || type.trim() === '')) && (
          <div className="alert alert-secondary" role="alert">
            Please enter both a data feed URL and entity type to load entities for reconciliation.
          </div>
        )}

        {!loading && !error && reconciliationStatus === 'error' && (
          <div className="alert alert-warning" role="alert">
            <strong>Reconciliation Error:</strong> There was a problem during the reconciliation process.
            <div className="mt-2">
              <small className="text-muted">
                • The entities were loaded successfully but matching failed<br/>
                • Try refreshing individual rows or searching again<br/>
                • Check your network connection and try again<br/>
                • Contact support if the issue persists
              </small>
            </div>
          </div>
        )}

        {!loading && !error && reconciliationStatus !== 'loading' && reconciliationStatus === 'complete' && dataFeed && dataFeed.trim() !== '' && type && type.trim() !== '' && currentPageItems.length === 0 && (
          <div className="alert alert-info" role="alert">
            {items.length === 0 ? (
              <strong>No entities found for the selected data feed and type.</strong>
            ) : (items.every(item => item.isPreReconciled || item.linkedTo || item.mintedAs || item.status === 'reconciled') ? (
              <strong>All entities have been reconciled!</strong>
            ) : (
              <strong>No entities match the current filters.</strong>
            ))}
          </div>
        )}
        
        {!loading && !error && reconciliationStatus === 'complete' && dataFeed && dataFeed.trim() !== '' && type && type.trim() !== '' && currentPageItems.length > 0 && (
          <div className="table-scroll-container">
            <table className="table">
              <thead>
                <tr>
                  <th scope="col" className="sticky-left">#</th>
                  <th scope="col">Judgement</th>
                  <th scope="col">
                  </th>
                  <th scope="col"> Refresh
                  </th>
                </tr>
              </thead>
              <tbody>
                {currentPageItems.map((item, index) => (
                  <TableRow
                    key={item.id}
                    item={item}
                    displayIndex={item.originalIndex}
                    parentRowIndex={index}
                    onAction={handleAction}
                    onRefresh={handleRefreshRow}
                    config={config}
                  />
                ))}
              </tbody>
            </table>
          </div>
        )}

        {!loading && !error && reconciliationStatus === 'complete' && dataFeed && dataFeed.trim() !== '' && type && type.trim() !== '' && currentPageItems.length > 0 && (
          <div className="bottom-controls">
            {/* Centered pagination controls */}
            {totalPages > 1 && (
              <div className="bottom-pagination-center">
                <div className="pagination-container">
                  <div className="pagination-info">
                    <span className="text-muted">
                      {totalFilteredItems} items, page {frontendCurrentPage} of {totalPages}
                    </span>
                  </div>
                  <div className="pagination-controls">
                    <button
                      onClick={() => setFrontendCurrentPage(prev => Math.max(1, prev - 1))}
                      disabled={frontendCurrentPage === 1 || loading}
                      className="btn btn-outline-secondary btn-sm"
                    >
                      Previous
                    </button>
                    <span className="pagination-current">
                      Page {frontendCurrentPage}
                    </span>
                    <button
                      onClick={() => setFrontendCurrentPage(prev => Math.min(totalPages, prev + 1))}
                      disabled={frontendCurrentPage === totalPages || loading}
                      className="btn btn-outline-secondary btn-sm"
                    >
                      Next
                    </button>
                  </div>
                </div>
              </div>
            )}

            {/* Accept All button on the right */}
            <div className="bottom-accept-all">
              <button
                onClick={handleAcceptAll}
                className="btn btn-primary"
                disabled={itemsReadyToAccept === 0 || loading}
              >
                Accept All ({itemsReadyToAccept})
              </button>
            </div>
          </div>
        )}

      </div>

      <NavigationConfirmation 
        isOpen={showNavigationConfirm}
        onConfirm={handleConfirmNavigation}
        onCancel={handleCancelNavigation}
      />
      
      <TypeSwitchConfirmation
        show={showTypeSwitchConfirm}
        onAcceptAll={handleTypeSwitchAcceptAll}
        onContinue={handleTypeSwitchContinue}
        onCancel={handleTypeSwitchCancel}
        currentType={type}
        newType={pendingTypeSwitch}
        unsavedCount={getUnsavedJudgmentCount()}
      />
      
      <DataFeedSwitchConfirmation
        show={showDataFeedSwitchConfirm}
        onAcceptAll={handleDataFeedSwitchAcceptAll}
        onContinue={handleDataFeedSwitchContinue}
        onCancel={handleDataFeedSwitchCancel}
        currentFeed={dataFeed}
        newFeed={pendingDataFeedSwitch}
        unsavedCount={getUnsavedJudgmentCount()}
      />
      
      <SearchConfirmation
        show={showSearchConfirm}
        onAcceptAll={handleSearchAcceptAll}
        onContinue={handleSearchContinue}
        onCancel={handleSearchCancel}
        currentDataFeed={dataFeed}
        currentType={type}
        newDataFeed={pendingSearch?.dataFeed}
        newType={pendingSearch?.type}
        unsavedCount={getUnsavedJudgmentCount()}
      />
      
      <ShowAllToggleConfirmation
        show={showShowAllConfirm}
        onAcceptAll={handleShowAllToggleAcceptAll}
        onContinue={handleShowAllToggleContinue}
        onCancel={handleShowAllToggleCancel}
        newShowAllValue={pendingShowAllToggle}
        unsavedCount={getUnsavedJudgmentCount()}
      />
      
      <AcceptAllConfirmation
        show={showAcceptAllConfirm}
        onConfirm={handleAcceptAllConfirm}
        onCancel={handleAcceptAllCancel}
        matchCount={acceptAllResults.matchCount || 0}
        mintCount={acceptAllResults.mintCount || 0}
        flagCount={acceptAllResults.flagCount || 0}
        totalCount={acceptAllResults.totalCount || 0}
      />
      
      <AcceptAllProgress
        show={showAcceptAllProgress}
        currentAction={acceptAllProgress.currentAction}
        currentEntity={acceptAllProgress.currentEntity}
        processedCount={acceptAllProgress.processedCount}
        totalCount={acceptAllProgress.totalCount}
        isComplete={acceptAllProgress.isComplete}
      />
      
      <AcceptAllSummary
        show={showAcceptAllSummary}
        onClose={handleAcceptAllSummaryClose}
        successCounts={acceptAllResults.successCounts}
        errorCounts={acceptAllResults.errorCounts}
        totalProcessed={acceptAllResults.totalProcessed}
      />
      </div>
    </StickyHeadersProvider>
  );
};

export default App;
