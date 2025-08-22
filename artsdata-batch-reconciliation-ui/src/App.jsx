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
import { fetchDynamicData } from "./services/dataFeedService";
import { batchReconcile, previewMint, mintEntity, linkEntity, flagEntity } from "./services/reconciliationService";
import { validateGraphUrl } from "./utils/urlValidation";

// Enhanced helper for filtering rows - searches all visible content and filters matches
function filterItems(items, filterText) {
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
      item.type,
      item.location,
      item.startDate,
      item.endDate,
      item.externalId,
      item.id?.toString()
    ];
    
    // Check parent entity fields
    const parentMatch = parentFields.some(field => 
      field && typeof field === 'string' && field.toLowerCase().includes(lower)
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
          match.type,
          match.score?.toString(),
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
    
    // Include item if parent matches OR if any match candidates match
    if (parentMatch || filteredMatches.length > 0) {
      // Create filtered item
      const filteredItem = { ...item };
      
      // Always apply match filtering when there's a search term
      // If parent matches AND there are filtered matches, show only filtered matches
      // If parent matches but no matches contain search term, show all matches
      // If parent doesn't match, show only filtered matches
      if (filteredMatches.length > 0) {
        filteredItem.matches = filteredMatches;
        filteredItem.matchesFiltered = true; // Flag to indicate matches have been filtered
      }
      // If parent matches but no matches contain the search term, keep all matches
      // This case: parent has search term but matches don't
      
      filteredItems.push(filteredItem);
    }
  });
  
  return filteredItems;
}


// Main App Component
const App = ({ config }) => {
  const [dataFeed, setDataFeed] = useState('');
  const [type, setType] = useState("");
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
  
  // Global judgment storage across all pages
  const [globalJudgments, setGlobalJudgments] = useState(new Map());

  // Add request sequence tracking to prevent race conditions
  const [requestSequence, setRequestSequence] = useState(0);
  const [abortController, setAbortController] = useState(null);

  // URL parameter utilities
  const getUrlParams = () => {
    const urlParams = new URLSearchParams(window.location.search);
    return {
      feedUrl: urlParams.get('feedUrl') || '',
      type: urlParams.get('type') || ''
    };
  };

  const updateUrlParams = (feedUrl, type) => {
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
    
    // Update the URL without triggering a page reload
    window.history.replaceState({}, '', url.toString());
  };

  // Process initial URL parameters on component mount
  useEffect(() => {
    const urlParams = getUrlParams();
    
    if (urlParams.feedUrl || urlParams.type) {
      // Set the state from URL parameters to populate input fields
      if (urlParams.feedUrl) {
        setDataFeed(urlParams.feedUrl);
      }
      if (urlParams.type) {
        setType(urlParams.type);
      }
    }
  }, []); // Run only on component mount

  // Internal load function that does the actual API call
  const loadDataInternal = async (currentType, currentDataFeed, currentPage, currentPageSize) => {
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
    
    try {
      const data = await fetchDynamicData(currentType, currentDataFeed, currentPage, currentPageSize, config, controller.signal);
      
      // Only update state if this is still the latest request
      setRequestSequence(prev => {
        if (currentSequence >= prev) {
          setItems(data);
          setReconciledItems(data); // Initialize with original data
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
        loadDataInternal(type, dataFeed, currentPage, pageSize);
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
      try {
        // Add schema: prefix for reconciliation API
        const schemaType = `schema:${type}`;
        
        // Get current globalJudgments to filter items
        const currentGlobalJudgments = globalJudgments;
        
        // Only reconcile items that don't have saved judgments
        const itemsToReconcile = items.filter(item => !currentGlobalJudgments.has(item.id));
        
        if (itemsToReconcile.length > 0) {
          // Batch reconcile new items
          const reconciled = await batchReconcile(itemsToReconcile, schemaType, itemsToReconcile.length, config);
          
          // Update reconciledItems with the new reconciled data
          // Don't merge with previous state - replace the current items
          setReconciledItems(prev => {
            // Only update items that exist in the current data set
            return prev.map(item => {
              const reconciledItem = reconciled.find(r => r.id === item.id);
              return reconciledItem || item;
            });
          });
        }
        
        setReconciliationStatus('complete');
      } catch (err) {
        console.error('Error during batch reconciliation:', err);
        setReconciliationStatus('error');
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
  const handleSearch = (newDataFeed, newType) => {
    const unsavedCount = getUnsavedJudgmentCount();
    
    if (unsavedCount > 0) {
      setPendingSearch({ dataFeed: newDataFeed, type: newType });
      setShowSearchConfirm(true);
    } else {
      // No unsaved work, search directly
      performSearch(newDataFeed, newType);
    }
  };

  const performSearch = (newDataFeed, newType) => {
    // Clear previous results when performing new search
    setItems([]);
    setReconciledItems([]);
    setGlobalJudgments(new Map());
    setReconciliationStatus('idle');
    setError(null);
    
    // Update URL parameters first
    updateUrlParams(newDataFeed, newType);
    
    // Update the state variables
    setDataFeed(newDataFeed);
    setType(newType);
    setCurrentPage(1); // Reset to first page
    
    // Force API call even if values haven't changed (for manual search)
    const validation = validateGraphUrl(newDataFeed);
    if (validation.isValid && !validation.isWarning) {
      loadDataInternal(newType, newDataFeed, 1, pageSize);
    }
  };

  const handleSearchAcceptAll = () => {
    // Accept all current judgments first
    handleAcceptAll();
    
    // Then perform search
    if (pendingSearch) {
      performSearch(pendingSearch.dataFeed, pendingSearch.type);
    }
    
    // Close confirmation
    setShowSearchConfirm(false);
    setPendingSearch(null);
  };

  const handleSearchContinue = () => {
    // Search and lose work
    if (pendingSearch) {
      performSearch(pendingSearch.dataFeed, pendingSearch.type);
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
    
    // Reload data with new show all setting
    const validation = validateGraphUrl(dataFeed);
    if (dataFeed && dataFeed.trim() !== '' && type && type.trim() !== '' && validation.isValid && !validation.isWarning) {
      loadDataInternal(type, dataFeed, 1, pageSize);
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
        // Link to matched entity
        const adUri = `http://kg.artsdata.ca/resource/${matchCandidate.id}`;
        const linkResult = await linkEntity(item.uri, `schema:${type}`, adUri, config);
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
          console.log(`Successfully flagged entity: ${item.name} (${item.uri})`);
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

  const handleAcceptAll = async () => {
    // Count items from ALL pages that have judgments ready to be accepted
    const allGlobalItemsToAccept = Array.from(globalJudgments.values()).filter(item => 
      // Exclude pre-reconciled entities from accept all
      !item.isPreReconciled &&
      (item.mintReady || item.linkedTo || item.status === 'mint-ready' || item.status === 'judgment-ready' || item.status === 'flagged' ||
      (item.hasAutoMatch && item.autoMatchCandidate) || (item.selectedMatch && !item.linkedTo))
    );
    
    // Also count current page items that are ready but not in global storage
    const currentPageReadyItems = reconciledItems.filter(item => {
      if (globalJudgments.has(item.id)) return false;
      // Exclude pre-reconciled entities from accept all
      if (item.isPreReconciled) return false;
      return item.mintReady || item.linkedTo || item.status === 'mint-ready' || item.status === 'judgment-ready' || item.status === 'flagged' ||
             (item.hasAutoMatch && item.autoMatchCandidate) || (item.selectedMatch && !item.linkedTo);
    });
    
    const totalItemsToAccept = allGlobalItemsToAccept.length + currentPageReadyItems.length;
    
    if (totalItemsToAccept === 0) {
      return;
    }
    
    // Process flag API calls for flagged entities
    const allFlaggedItems = [...allGlobalItemsToAccept, ...currentPageReadyItems].filter(item => item.status === 'flagged');
    
    for (const item of allFlaggedItems) {
      try {
        await flagEntity(item.uri, config);
        console.log(`Successfully flagged entity: ${item.name} (${item.uri})`);
      } catch (error) {
        console.error(`Failed to flag entity: ${item.name} (${item.uri})`, error);
        // Continue with other items even if one fails
      }
    }
    
    // Update all items in global storage to reconciled status
    setGlobalJudgments(prev => {
      const newMap = new Map(prev);
      for (const [itemId, item] of prev) {
        // Only mark non-pre-reconciled items as reconciled through accept all
        if (!item.isPreReconciled &&
            (item.mintReady || item.linkedTo || item.status === 'mint-ready' || item.status === 'judgment-ready' || item.status === 'flagged' ||
            (item.hasAutoMatch && item.autoMatchCandidate) || (item.selectedMatch && !item.linkedTo))) {
          newMap.set(itemId, {
            ...item,
            status: 'reconciled'
          });
        }
      }
      
      // Add current page ready items to global storage as reconciled
      currentPageReadyItems.forEach(item => {
        newMap.set(item.id, {
          ...item,
          status: 'reconciled'
        });
      });
      
      return newMap;
    });
    
    // Update current page items
    setReconciledItems(prev => 
      prev.map(item => {
        // Only mark non-pre-reconciled items as reconciled through accept all
        if (!item.isPreReconciled &&
            (item.mintReady || item.linkedTo || item.status === 'mint-ready' || item.status === 'judgment-ready' || item.status === 'flagged' ||
            (item.hasAutoMatch && item.autoMatchCandidate) || (item.selectedMatch && !item.linkedTo))) {
          return {
            ...item,
            status: 'reconciled'
          };
        }
        return item;
      })
    );
    
    // If showAll is unchecked, navigate to page 1 to show remaining unreconciled items
    if (!showAll) {
      setCurrentPage(1);
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

  // Filtering and sorting
  let filtered = filterItems(reconciledItems, filterText);
  
  // Apply "Show All" filter
  if (!showAll) {
    filtered = filtered.filter(item => 
      item.status !== 'reconciled' && 
      !item.linkedTo && 
      !item.mintedAs
    );
  }
  
  const sorted = filtered;
  
  // Since API handles pagination, we display all items from current API call
  const currentPageItems = sorted;

  // Count items ready to accept across ALL visited pages from global storage
  const globalReadyItems = Array.from(globalJudgments.values()).filter(item => 
    // Exclude pre-reconciled entities from accept all count
    !item.isPreReconciled &&
    (item.mintReady || item.linkedTo || item.status === 'mint-ready' || item.status === 'judgment-ready' || item.status === 'flagged' ||
    (item.hasAutoMatch && item.autoMatchCandidate) || (item.selectedMatch && !item.linkedTo))
  );
  
  // Count current page items that are ready but not yet in global storage
  const currentPageReadyItems = reconciledItems.filter(item => {
    // Skip if already in global storage
    if (globalJudgments.has(item.id)) return false;
    // Exclude pre-reconciled entities from accept all count
    if (item.isPreReconciled) return false;
    
    // Check if item is ready to accept
    const isReady = item.mintReady || item.linkedTo || item.status === 'mint-ready' || item.status === 'judgment-ready' || item.status === 'flagged' || 
                   (item.hasAutoMatch && item.autoMatchCandidate) || (item.selectedMatch && !item.linkedTo);
    return isReady;
  });
  
  const itemsReadyToAccept = globalReadyItems.length + currentPageReadyItems.length;

  return (
    <div className="app">
      
      <FilterControls
        dataFeed={dataFeed}
        setDataFeed={handleDataFeedSwitch}
        type={type}
        setType={handleTypeSwitch}
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
              Running batch reconciliation...
            </div>
          </div>
        )}
        
        {error && (
          <div className="alert alert-danger" role="alert">
            <strong>Error loading data:</strong> {error}
          </div>
        )}
        
        {!loading && !error && ((!dataFeed || dataFeed.trim() === '') || (!type || type.trim() === '')) && (
          <div className="alert alert-secondary" role="alert">
            Please enter both a data feed URL and entity type to load entities for reconciliation.
          </div>
        )}
        
        {!loading && !error && dataFeed && dataFeed.trim() !== '' && type && type.trim() !== '' && currentPageItems.length === 0 && (
          <div className="alert alert-warning" role="alert">
            No entities found for the selected data feed and type.
          </div>
        )}
        
        {!loading && !error && dataFeed && dataFeed.trim() !== '' && type && type.trim() !== '' && currentPageItems.length > 0 && (
          <div className="table-scroll-container">
            <table className="table table-responsive">
              <thead>
                <tr>
                  <th scope="col">#</th>
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
                    displayIndex={index + 1}
                    parentRowIndex={index}
                    onAction={handleAction}
                    onRefresh={handleRefreshRow}
                  />
                ))}
              </tbody>
            </table>
          </div>
        )}

        {!loading && !error && dataFeed && dataFeed.trim() !== '' && type && type.trim() !== '' && currentPageItems.length > 0 && (
          <div className="bottom-accept-all">
            <button 
              onClick={handleAcceptAll} 
              className="btn btn-primary"
              disabled={true}
            >
              Accept All ({itemsReadyToAccept})
            </button>
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
    </div>
  );
};

export default App;
