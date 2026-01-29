// Import and register all your controllers from the importmap under controllers/*

import { application } from "controllers/application"

// Eager load all controllers defined in the import map under controllers/**/*_controller
import { eagerLoadControllersFrom } from "@hotwired/stimulus-loading"
eagerLoadControllersFrom("controllers", application)

// Lazy load controllers as they appear in the DOM (remember not to preload controllers in import map!)
// import { lazyLoadControllersFrom } from "@hotwired/stimulus-loading"
// lazyLoadControllersFrom("controllers", application)

import VisibilityController from "controllers/visibility_controller"
application.register("visibility", VisibilityController)

import ArtsdataController from "controllers/artsdata_controller"
application.register("artsdata", ArtsdataController)

import SortableTableController from "controllers/sortable_table_controller"
application.register("sortable-table", SortableTableController)

import FilterQueryResultsController from "controllers/filter_query_results_controller"
application.register("filter-query-results", FilterQueryResultsController)

// import Clipboard from '@stimulus-components/clipboard'
// application.register('clipboard', Clipboard)
import CustomClipboardController from "controllers/custom_clipboard_controller"
application.register('clipboard', CustomClipboardController)

import ReadMore from '@stimulus-components/read-more'
application.register('read-more', ReadMore)

import JobStatusController from "controllers/job_status_controller"
application.register('job-status', JobStatusController)