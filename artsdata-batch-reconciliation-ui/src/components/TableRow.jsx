import React from 'react';
import StatusBadge from './StatusBadge';
import ActionButton from './ActionButton';
import { Eye, Clock } from 'lucide-react';

const TableRow = ({ item, onAction, onView }) => (
  <>
    <tr className="table-row">
      <td className="table-cell cell-id">{item.id}</td>
      <td className="table-cell">
        <div className="judgement-cell">
          <StatusBadge status={item.status} hasError={item.hasError} />
          <ActionButton status={item.status} onAction={(action) => onAction(item.id, action)} />
        </div>
      </td>
      <td className="table-cell cell-external-id">{item.externalId}</td>
      <td className="table-cell">
        <div className="name-cell">
          <div className="name-primary">{item.name}</div>
          <div className="name-secondary">{item.description}</div>
        </div>
      </td>
      <td className="table-cell">
        <a href={item.url} className="table-link">
          {item.url}
        </a>
      </td>
      <td className="table-cell">
        <a href={item.isni} className="table-link">
          {item.isni}
        </a>
      </td>
      <td className="table-cell">
        <a href={item.wikidata} className="table-link">
          {item.wikidata}
        </a>
      </td>
      <td className="table-cell cell-type">{item.type}</td>
      <td className="table-cell">
        <button
          onClick={() => onView(item.id)}
          className="icon-button"
        >
          <Eye className="table-icon" />
        </button>
      </td>
      <td className="table-cell">
        <button
          onClick={() => onView(item.id)}
          className="icon-button"
        >
          <Clock className="table-icon" />
        </button>
      </td>
    </tr>
    {item.matches && item.matches.map((match, index) => (
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

export default TableRow;
