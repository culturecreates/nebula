import React, { useState } from 'react';
import StatusBadge from './StatusBadge';
import ActionButton from './ActionButton';
import { Eye, Clock } from 'lucide-react';

const TableRow = ({ item, onAction, onView }) => {
  const [expanded, setExpanded] = useState(false);
  const [showExternalId, setShowExternalId] = useState(false);

  const handleRowClick = (e) => {
    if (
      e.target.closest('.icon-button') ||
      e.target.closest('.action-link') ||
      e.target.closest('.eye-externalid-btn')
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
            <StatusBadge status={item.status} hasError={item.hasError} />
            <ActionButton status={item.status} onAction={(action) => onAction(item.id, action)} />
          </div>
        </td>
        <td className="table-cell cell-external-id">
          {canShowEye && !showExternalId && (
            <button
              className="icon-button eye-externalid-btn"
              title="Show Artsdata ID"
              onClick={e => { e.stopPropagation(); setShowExternalId(true); }}
              style={{ marginRight: '0.5rem' }}
            >
              <Eye className="table-icon" />
            </button>
          )}
          {showExternalId && <span>{item.externalId}</span>}
        </td>
        <td className="table-cell">
          <div className="name-cell">
            <div className="name-primary">{item.name}</div>
            <div className="name-secondary">{item.description}</div>
          </div>
        </td>
        <td className="table-cell">
          <a href={item.url} className="table-link" onClick={e => e.stopPropagation()}>
            {item.url}
          </a>
        </td>
        <td className="table-cell">
          <a href={item.isni} className="table-link" onClick={e => e.stopPropagation()}>
            {item.isni}
          </a>
        </td>
        <td className="table-cell">
          <a href={item.wikidata} className="table-link" onClick={e => e.stopPropagation()}>
            {item.wikidata}
          </a>
        </td>
        <td className="table-cell cell-type">{item.type}</td>
        <td className="table-cell">
          <button
            onClick={e => { e.stopPropagation(); onView(item.id); }}
            className="icon-button"
          >
            <Clock className="table-icon" />
          </button>
        </td>
        <td className="table-cell"></td>
      </tr>
      {expanded && item.matches && item.matches.map((match, index) => (
        <tr key={`${item.id}-match-${index}`} className="table-row match-row">
          <td className="table-cell"></td>
          <td className="table-cell">
            <span className="match-score">match ({match.score})</span>
          </td>
          <td className="table-cell cell-external-id">{match.externalId}</td>
          <td className="table-cell">
            <div className="name-cell">
              <div className="match-name">{match.name}</div>
              <div className="match-description">{match.description}</div>
            </div>
          </td>
          <td className="table-cell"></td>
          <td className="table-cell"></td>
          <td className="table-cell"></td>
          <td className="table-cell cell-type">{match.type}</td>
          <td className="table-cell"></td>
          <td className="table-cell"></td>
        </tr>
      ))}
    </>
  );
};

export default TableRow;
