import { useState } from "react";
import "./App.css";
import Header from "./components/Header";
import FilterControls from "./components/FilterControls";
import TableRow from "./components/TableRow";
import Pagination from "./components/Pagination";

// Main App Component
const App = () => {
  const [dataFeed, setDataFeed] = useState("iwts-ca");
  const [type, setType] = useState("PerformingGroup");
  const [minScore, setMinScore] = useState(50);
  const [showAll, setShowAll] = useState(true);
  const [filterText, setFilterText] = useState("");
  const [pageSize, setPageSize] = useState(20);
  const [currentPage, setCurrentPage] = useState(2);

  // Sample data
  const [items, setItems] = useState([
    {
      id: 1,
      status: "Select",
      externalId: "mint new",
      name: "Marianna Mazza",
      description: "Humouriste",
      url: "https://mazza.com",
      isni: "https://isni.org/1234",
      wikidata: "",
      type: "PerformingGroup",
      matches: [
        {
          score: 95,
          externalId: "K2-123",
          name: "Marianna Mazza",
          description: "Montreal",
          type: "Person",
        },
        {
          score: 91,
          externalId: "K10-4544",
          name: "Mazza group",
          description: "Theatre group",
          type: "Organization",
        },
      ],
    },
    {
      id: 2,
      status: "Match",
      externalId: "K2-123",
      name: "Marianna Mazza",
      description: "Humouriste",
      url: "https://mazza.com",
      isni: "https://isni.org/1234",
      wikidata: "",
      type: "PerformingGroup",
      matches: [
        {
          name: "Marianna Mazza",
          description: "Humouriste, Montreal",
          type: "Person",
        },
      ],
    },
    {
      id: 3,
      status: "Mint person",
      externalId: "",
      name: "Marianna Mazza",
      description: "Humouriste",
      url: "https://mazza.com",
      isni: "https://isni.org/1234",
      wikidata: "",
      type: "PerformingGroup",
    },
    {
      id: 4,
      status: "Reconciled",
      externalId: "K2-123",
      name: "Marianna Mazza",
      description: "Humouriste",
      url: "https://mazza.com",
      isni: "https://isni.org/1234",
      wikidata: "",
      type: "PerformingGroup",
      matches: [
        {
          name: "Marianna Mazza",
          description: "Humouriste, Montreal",
          type: "Person",
        },
      ],
    },
    {
      id: 5,
      status: "Mint person",
      externalId: "",
      name: "Marianna Mazza",
      description: "Humouriste",
      url: "",
      isni: "",
      wikidata: "",
      type: "PerformingGroup",
      hasError: true,
    },
    {
      id: 6,
      status: "Skipped",
      externalId: "",
      name: "Marianna Mazza",
      description: "Humouriste",
      url: "",
      isni: "",
      wikidata: "",
      type: "PerformingGroup",
    },
  ]);

  const handleAction = (itemId, action) => {
    setItems(
      items.map((item) =>
        item.id === itemId
          ? {
              ...item,
              status:
                action === "mint_new"
                  ? "Mint person"
                  : action === "skip"
                  ? "Skipped"
                  : item.status,
            }
          : item
      )
    );
  };

  const handleView = (itemId) => {
    console.log("View item:", itemId);
  };

  const handleAcceptAll = () => {
    console.log("Accept all items");
  };

  return (
    <div className="app">
      <Header onAcceptAll={handleAcceptAll} totalItems={25} />

      <FilterControls
        dataFeed={dataFeed}
        setDataFeed={setDataFeed}
        type={type}
        setType={setType}
        minScore={minScore}
        setMinScore={setMinScore}
        showAll={showAll}
        setShowAll={setShowAll}
        filterText={filterText}
        setFilterText={setFilterText}
        pageSize={pageSize}
        setPageSize={setPageSize}
      />

      <div className="table-container">
        <div className="table-wrapper">
          <table className="data-table">
            <thead className="table-header">
              <tr>
                <th className="table-header-cell">#</th>
                <th className="table-header-cell">Judgement</th>
                <th className="table-header-cell">ID</th>
                <th className="table-header-cell">Name</th>
                <th className="table-header-cell">Url</th>
                <th className="table-header-cell">ISNI</th>
                <th className="table-header-cell">Wikidata</th>
                <th className="table-header-cell">Type</th>
                <th className="table-header-cell"></th>
                <th className="table-header-cell"></th>
              </tr>
            </thead>
            <tbody className="table-body">
              {items.map((item) => (
                <TableRow
                  key={item.id}
                  item={item}
                  onAction={handleAction}
                  onView={handleView}
                />
              ))}
            </tbody>
          </table>
        </div>

        <Pagination
          currentPage={currentPage}
          totalPages={4}
          onPageChange={setCurrentPage}
        />
      </div>
    </div>
  );
};

export default App;
