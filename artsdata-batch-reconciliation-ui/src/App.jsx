import { useState, useEffect } from "react";
import "./App.css";
import FilterControls from "./components/FilterControls";
import TableRow from "./components/TableRow";
import Pagination from "./components/Pagination";
import NavigationConfirmation from "./components/NavigationConfirmation";
import TypeSwitchConfirmation from "./components/TypeSwitchConfirmation";
import DataFeedSwitchConfirmation from "./components/DataFeedSwitchConfirmation";
import { fetchDynamicData, getAvailableTypes } from "./services/dataFeedService";
import { batchReconcile, getReferenceUri, previewMint, mintEntity, linkEntity } from "./services/reconciliationService";
import { validateGraphUrl } from "./utils/urlValidation";

// Helper for filtering rows
function filterItems(items, filterText) {
  if (!filterText) return items;
  const lower = filterText.toLowerCase();
  return items.filter((item) =>
    Object.values(item).some(
      (val) =>
        typeof val === "string" && val.toLowerCase().includes(lower)
    )
  );
}

// Helper for sorting
function sortItems(items, sortKey, sortDir) {
  if (!sortKey) return items;
  return [...items].sort((a, b) => {
    if (a[sortKey] < b[sortKey]) return sortDir === "asc" ? -1 : 1;
    if (a[sortKey] > b[sortKey]) return sortDir === "asc" ? 1 : -1;
    return 0;
  });
}

// Main App Component
const App = () => {
  const [dataFeed, setDataFeed] = useState();
  const [type, setType] = useState("Event");
  const [minScore, setMinScore] = useState(50);
  const [showAll, setShowAll] = useState(true);
  const [filterText, setFilterText] = useState("");
  const [pageSize, setPageSize] = useState(20);
  const [currentPage, setCurrentPage] = useState(1);
  const [sortKey, setSortKey] = useState(null);
  const [sortDir, setSortDir] = useState("asc");
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
  
  // Global judgment storage across all pages
  const [globalJudgments, setGlobalJudgments] = useState(new Map());

  // Load data when type, feed, or page changes
  useEffect(() => {
    const loadData = async () => {
      setLoading(true);
      setError(null);
      setReconciliationStatus('idle');
      
      try {
        const data = await fetchDynamicData(type, dataFeed, currentPage, pageSize);
        setItems(data);
        setReconciledItems(data); // Initialize with original data
      } catch (err) {
        setError(err.message);
        console.error('Error loading data:', err);
      } finally {
        setLoading(false);
      }
    };

    // Only load if we have both type and dataFeed, and URL is valid
    if (type && dataFeed && dataFeed.trim() !== '') {
      const validation = validateGraphUrl(dataFeed);
      if (validation.isValid && !validation.isWarning) {
        loadData();
      } else {
        // Don't load data if URL is invalid
        setItems([]);
        setReconciledItems([]);
        setLoading(false);
        setError(validation.isValid ? null : validation.message);
      }
    } else if (dataFeed === '' || !dataFeed) {
      // Clear data when data feed is empty
      setItems([]);
      setReconciledItems([]);
      setLoading(false);
      setError(null);
    }
  }, [type, dataFeed, currentPage, pageSize]);

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
          console.log(`Reconciling ${itemsToReconcile.length} items of type ${schemaType}`);
          // Batch reconcile new items
          const reconciled = await batchReconcile(itemsToReconcile, schemaType, itemsToReconcile.length);
          
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
      item.mintReady || item.linkedTo || item.status === 'mint-ready' || item.status === 'judgment-ready' ||
      (item.hasAutoMatch && item.autoMatchCandidate) || (item.selectedMatch && !item.linkedTo)
    );
    
    const currentPageReadyItems = reconciledItems.filter(item => {
      if (globalJudgments.has(item.id)) return false;
      return item.mintReady || item.linkedTo || item.status === 'mint-ready' || item.status === 'judgment-ready' ||
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

  const handleAction = async (itemId, action, matchCandidate = null) => {
    const item = reconciledItems.find(item => item.id === itemId);
    if (!item) return;

    try {
      let updateData = {};
      
      if (action === "mint_preview") {
        // Preview mint first
        const schemaType = `schema:${type}`; // Add schema: prefix for mint API
        const previewResult = await previewMint(item.uri, schemaType);
        
        if (previewResult.status === 'success') {
          updateData = {
            mintReady: true,
            mintError: null
          };
        } else {
          throw new Error(previewResult.message || 'Mint preview failed');
        }
      } else if (action === "mint_final") {
        // Perform actual mint
        const schemaType = `schema:${type}`; // Add schema: prefix for mint API
        const mintResult = await mintEntity(item.uri, schemaType, dataFeed);
        updateData = {
          status: "reconciled",
          mintedAs: `${type.toLowerCase()}`,
          actionError: null
        };
      } else if (action === "link" && matchCandidate) {
        // Link to matched entity
        const linkResult = await linkEntity(item.uri, `schema:${type}`, matchCandidate.id);
        updateData = {
          status: "reconciled",
          linkedTo: matchCandidate.id,
          linkedToName: matchCandidate.name,
          linkError: null,
          actionError: null
        };
      } else if (action === "skip") {
        updateData = {
          status: "skipped",
          actionError: null
        };
      } else if (action === "reset_mint") {
        // Reset mint state when user clicks Change from mint-ready
        updateData = {
          mintReady: false,
          mintError: null,
          selectedMatch: null,
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
    // Count items from ALL pages that have judgments ready to be accepted
    const allGlobalItemsToAccept = Array.from(globalJudgments.values()).filter(item => 
      item.mintReady || item.linkedTo || item.status === 'mint-ready' || item.status === 'judgment-ready' ||
      (item.hasAutoMatch && item.autoMatchCandidate) || (item.selectedMatch && !item.linkedTo)
    );
    
    // Also count current page items that are ready but not in global storage
    const currentPageReadyItems = reconciledItems.filter(item => {
      if (globalJudgments.has(item.id)) return false;
      return item.mintReady || item.linkedTo || item.status === 'mint-ready' || item.status === 'judgment-ready' ||
             (item.hasAutoMatch && item.autoMatchCandidate) || (item.selectedMatch && !item.linkedTo);
    });
    
    const totalItemsToAccept = allGlobalItemsToAccept.length + currentPageReadyItems.length;
    
    if (totalItemsToAccept === 0) {
      console.log("No items ready to accept");
      return;
    }
    
    console.log(`Accepting ${totalItemsToAccept} items across all pages`);
    
    // Update all items in global storage to reconciled status
    setGlobalJudgments(prev => {
      const newMap = new Map(prev);
      for (const [itemId, item] of prev) {
        if (item.mintReady || item.linkedTo || item.status === 'mint-ready' || item.status === 'judgment-ready' ||
            (item.hasAutoMatch && item.autoMatchCandidate) || (item.selectedMatch && !item.linkedTo)) {
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
        if (item.mintReady || item.linkedTo || item.status === 'mint-ready' || item.status === 'judgment-ready' ||
            (item.hasAutoMatch && item.autoMatchCandidate) || (item.selectedMatch && !item.linkedTo)) {
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

  const handleSort = (key) => {
    if (sortKey === key) {
      setSortDir(sortDir === "asc" ? "desc" : "asc");
    } else {
      setSortKey(key);
      setSortDir("asc");
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
      const reconciled = await batchReconcile([resetItem], schemaType, 1);
      
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
  
  const sorted = sortItems(filtered, sortKey, sortDir);
  
  // Since API handles pagination, we display all items from current API call
  const currentPageItems = sorted;

  // Count items ready to accept across ALL visited pages from global storage
  const globalReadyItems = Array.from(globalJudgments.values()).filter(item => 
    item.mintReady || item.linkedTo || item.status === 'mint-ready' || item.status === 'judgment-ready' ||
    (item.hasAutoMatch && item.autoMatchCandidate) || (item.selectedMatch && !item.linkedTo)
  );
  
  // Count current page items that are ready but not yet in global storage
  const currentPageReadyItems = reconciledItems.filter(item => {
    // Skip if already in global storage
    if (globalJudgments.has(item.id)) return false;
    
    // Check if item is ready to accept
    const isReady = item.mintReady || item.linkedTo || item.status === 'mint-ready' || item.status === 'judgment-ready' || 
                   (item.hasAutoMatch && item.autoMatchCandidate) || (item.selectedMatch && !item.linkedTo);
    return isReady;
  });
  
  const itemsReadyToAccept = globalReadyItems.length + currentPageReadyItems.length;

  return (
    <div className="app">
      <div className="header">
        <div className="header-content">
          <h1 className="header-title">Artsdata Batch Reconciliation</h1>
        </div>
      </div>
      
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
      />

      <div className="table-container">
        {loading && (
          <div className="loading-message">
            Loading data from Artsdata...
          </div>
        )}
        
        {reconciliationStatus === 'loading' && (
          <div className="loading-message">
            Running batch reconciliation...
          </div>
        )}
        
        {error && (
          <div className="error-message">
            Error loading data: {error}
          </div>
        )}
        
        {!loading && !error && (!dataFeed || dataFeed.trim() === '') && (
          <div className="empty-state-message">
            <p>Please enter a data feed URL to load entities for reconciliation.</p>
          </div>
        )}
        
        {!loading && !error && dataFeed && dataFeed.trim() !== '' && currentPageItems.length === 0 && (
          <div className="empty-state-message">
            <p>No entities found for the selected data feed and type.</p>
          </div>
        )}
        
        {!loading && !error && dataFeed && dataFeed.trim() !== '' && currentPageItems.length > 0 && (
          <div className="table-wrapper">
            <table className="data-table">
              <thead className="table-header">
                <tr>
                  {[
                    { key: 'id', label: '#' },
                    { key: 'status', label: 'Judgement' },
                    { key: 'externalId', label: 'ID' },
                    { key: 'name', label: 'Name' },
                    { key: 'url', label: 'URL' },
                    { key: 'isni', label: 'ISNI' },
                    { key: 'wikidata', label: 'Wikidata' },
                    { key: 'type', label: 'Type' },
                    { key: '', label: '' }
                  ].map((col, idx) => (
                    <th
                      key={col.key || idx}
                      className="table-header-cell"
                      onClick={col.key ? () => handleSort(col.key) : undefined}
                      style={col.key ? { cursor: 'pointer' } : {}}
                    >
                      {col.label}
                    </th>
                  ))}
                </tr>
              </thead>
              <tbody className="table-body">
                {currentPageItems.map((item) => (
                  <TableRow
                    key={item.id}
                    item={item}
                    onAction={handleAction}
                    onRefresh={handleRefreshRow}
                  />
                ))}
              </tbody>
            </table>
          </div>
        )}

        {!loading && !error && dataFeed && dataFeed.trim() !== '' && currentPageItems.length > 0 && (
          <div className="bottom-accept-all">
            <button 
              onClick={handleAcceptAll} 
              className="btn btn-primary accept-all-btn"
              disabled={itemsReadyToAccept === 0}
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
    </div>
  );
};

export default App;
