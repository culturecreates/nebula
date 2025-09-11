import React, { createContext, useContext } from 'react';
import { useStickyHeaders } from '../hooks/useStickyHeaders';

const StickyHeadersContext = createContext();

export const useStickyHeadersContext = () => {
  const context = useContext(StickyHeadersContext);
  if (!context) {
    throw new Error('useStickyHeadersContext must be used within StickyHeadersProvider');
  }
  return context;
};

export const StickyHeadersProvider = ({ children }) => {
  const stickyHeadersHook = useStickyHeaders();

  return (
    <StickyHeadersContext.Provider value={stickyHeadersHook}>
      {children}
      
      {/* Render sticky headers as fixed positioned elements */}
      <div className="sticky-headers-overlay">
        {stickyHeadersHook.stickyHeaders.map((header) => (
          <div
            key={header.id}
            className="sticky-header-fixed"
            style={{
              position: 'fixed',
              top: 0,
              left: header.left,
              width: header.width,
              zIndex: header.zIndex,
              pointerEvents: 'none' // Don't interfere with scrolling
            }}
            dangerouslySetInnerHTML={{ __html: header.html }}
          />
        ))}
      </div>
    </StickyHeadersContext.Provider>
  );
};