import { useEffect, useRef, useState } from 'react';

export const useStickyHeaders = () => {
  const [stickyHeaders, setStickyHeaders] = useState([]);
  const headersRefs = useRef(new Set());
  const activeSticky = useRef(new Map());

  useEffect(() => {
    const handleScroll = () => {
      let activeHeader = null;
      let nextHeaderDistance = Infinity;

      // Find all headers and their positions
      const headerData = [];
      headersRefs.current.forEach(headerElement => {
        if (!headerElement || !document.contains(headerElement)) {
          headersRefs.current.delete(headerElement);
          return;
        }

        const rect = headerElement.getBoundingClientRect();
        const container = headerElement.closest('.nested-table-container');
        
        if (!container) return;

        headerData.push({
          element: headerElement,
          rect: rect,
          container: container,
          containerRect: container.getBoundingClientRect()
        });
      });

      // Sort headers by their vertical position
      headerData.sort((a, b) => a.rect.top - b.rect.top);

      // Find the active sticky header (last one that's above or at the top)
      for (let i = 0; i < headerData.length; i++) {
        const header = headerData[i];
        
        if (header.rect.top <= 0) {
          // This header has scrolled past the top
          activeHeader = header;
          
          // Check if there's a next header that might push this one
          if (i < headerData.length - 1) {
            const nextHeader = headerData[i + 1];
            nextHeaderDistance = nextHeader.rect.top;
          }
        }
      }

      // Only create sticky header if we found an active one
      const newStickyHeaders = [];
      if (activeHeader) {
        const tableWrapper = activeHeader.element.closest('.table-scroll-wrapper');
        const scrollWrapperRect = tableWrapper ? tableWrapper.getBoundingClientRect() : activeHeader.containerRect;
        
        // Get the scroll position for horizontal sync
        const scrollLeft = tableWrapper ? tableWrapper.scrollLeft : 0;
        
        // Calculate push-up effect when next header is close
        const headerHeight = 50; // Approximate header height
        const pushDistance = nextHeaderDistance < headerHeight ? nextHeaderDistance - headerHeight : 0;
        
        // Capture exact computed styles from the original header
        const originalTable = activeHeader.element.closest('table');
        const originalComputedStyle = window.getComputedStyle(originalTable);
        const headerComputedStyle = window.getComputedStyle(activeHeader.element);
        
        // Get exact column widths from the original header
        const originalCells = activeHeader.element.querySelector('tr').children;
        const columnWidths = [];
        for (let i = 0; i < originalCells.length; i++) {
          const cellRect = originalCells[i].getBoundingClientRect();
          columnWidths.push(cellRect.width);
        }
        
        // Create inline styles for exact matching
        const tableStyles = `
          margin: 0;
          width: ${originalTable.getBoundingClientRect().width}px;
          font-family: ${originalComputedStyle.fontFamily};
          font-size: ${originalComputedStyle.fontSize};
          line-height: ${originalComputedStyle.lineHeight};
          border-spacing: ${originalComputedStyle.borderSpacing};
          border-collapse: ${originalComputedStyle.borderCollapse};
        `;
        
        const headerStyles = `
          background-color: ${headerComputedStyle.backgroundColor};
          border-bottom: ${headerComputedStyle.borderBottomWidth} ${headerComputedStyle.borderBottomStyle} ${headerComputedStyle.borderBottomColor};
          height: ${activeHeader.element.getBoundingClientRect().height}px;
        `;
        
        // Build the HTML with exact column widths
        let headerHTML = '<tr>';
        for (let i = 0; i < originalCells.length; i++) {
          const cell = originalCells[i];
          const cellComputedStyle = window.getComputedStyle(cell);
          const cellStyles = `
            width: ${columnWidths[i]}px;
            min-width: ${columnWidths[i]}px;
            max-width: ${columnWidths[i]}px;
            padding: ${cellComputedStyle.padding};
            font-weight: ${cellComputedStyle.fontWeight};
            font-size: ${cellComputedStyle.fontSize};
            text-align: ${cellComputedStyle.textAlign};
            background-color: ${cellComputedStyle.backgroundColor};
            border: ${cellComputedStyle.border};
          `;
          headerHTML += `<th style="${cellStyles}">${cell.innerHTML}</th>`;
        }
        headerHTML += '</tr>';
        
        // Get the exact left position of the table within its scroll container
        const tableRect = originalTable.getBoundingClientRect();
        const tableLeftOffset = tableRect.left - scrollWrapperRect.left;
        
        const stickyTableHtml = `
          <div class="sticky-header-wrapper" style="overflow-x: auto; width: 100%; transform: translateY(${pushDistance}px);">
            <table class="${originalTable.className}" style="${tableStyles}; transform: translateX(${tableLeftOffset - scrollLeft}px);">
              <thead style="${headerStyles}">
                ${headerHTML}
              </thead>
            </table>
          </div>
        `;
        
        newStickyHeaders.push({
          id: activeHeader.element.dataset.headerId || Math.random().toString(36),
          element: activeHeader.element,
          left: scrollWrapperRect.left,
          width: scrollWrapperRect.width,
          html: stickyTableHtml,
          zIndex: 1030,
          scrollLeft: scrollLeft,
          pushDistance: pushDistance
        });
      }

      setStickyHeaders(newStickyHeaders);
    };

    // Listen to both vertical and horizontal scroll events
    window.addEventListener('scroll', handleScroll, { passive: true });
    window.addEventListener('resize', handleScroll, { passive: true });
    
    // Also listen for horizontal scroll on table wrappers
    const handleHorizontalScroll = () => {
      // Sync horizontal scroll position with sticky headers
      const stickyWrapper = document.querySelector('.sticky-header-wrapper');
      if (stickyWrapper && activeSticky.current.size > 0) {
        const originalWrapper = Array.from(activeSticky.current.values())[0]?.closest('.table-scroll-wrapper');
        if (originalWrapper) {
          stickyWrapper.scrollLeft = originalWrapper.scrollLeft;
        }
      }
    };
    
    // Add horizontal scroll listeners to all table wrappers
    const addScrollListeners = () => {
      document.querySelectorAll('.table-scroll-wrapper').forEach(wrapper => {
        wrapper.addEventListener('scroll', handleHorizontalScroll, { passive: true });
      });
    };
    
    addScrollListeners();
    
    // Re-add listeners when new tables are added
    const observer = new MutationObserver(addScrollListeners);
    observer.observe(document.body, { childList: true, subtree: true });
    
    return () => {
      window.removeEventListener('scroll', handleScroll);
      window.removeEventListener('resize', handleScroll);
      document.querySelectorAll('.table-scroll-wrapper').forEach(wrapper => {
        wrapper.removeEventListener('scroll', handleHorizontalScroll);
      });
      observer.disconnect();
    };
  }, []);

  const registerHeader = (headerElement) => {
    if (headerElement) {
      headerElement.dataset.headerId = Math.random().toString(36);
      headersRefs.current.add(headerElement);
    }
  };

  const unregisterHeader = (headerElement) => {
    if (headerElement) {
      headersRefs.current.delete(headerElement);
    }
  };

  return {
    stickyHeaders,
    registerHeader,
    unregisterHeader
  };
};