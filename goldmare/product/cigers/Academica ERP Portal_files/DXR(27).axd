(function(){
var GridViewConsts = {
 AdaptiveGroupPanelID: "DXAGroupPanel",
 AdaptiveHeaderPanelID: "DXAHeaderPanel",
 AdaptiveFooterPanelID: "DXAFooterPanel",
 AdaptiveGroupHeaderID: "DXADGroupHeader",
 AdaptiveHeaderID: "DXADHeader",
 HeaderTableID: "DXHeaderTable",
 FooterTableID: "DXFooterTable",
 FilterRowID: "DXFilterRow",
 DataRowID: "DXDataRow",
 DetailRowID: "DXDRow",
 AdaptiveDetailRowID: "DXADRow",
 PreviewRowID: "DXPRow",
 GroupRowID: "DXGroupRow",
 EmptyDataRowID: "DXEmptyRow",
 FooterRowID: "DXFooterRow",
 GroupFooterRowID: "DXGFRow",
 HeaderRowID: "_DXHeadersRow",
 BandedRowPattern: "_DXDataRow(\\d+)_(\\d+)$",
 GridViewMarkerCssClass: "dxgv",
 GroupRowCssClass: "dxgvGroupRow",
 EmptyPagerRowCssClass: "dxgvEPDR",
 GroupFooterRowClass: "dxgvGroupFooter",
 GroupPanelCssClass: "dxgvGroupPanel",
 FooterScrollDivContainerCssClass: "dxgvFSDC",
 HeaderScrollDivContainerCssClass: "dxgvHSDC",
 HeaderCellCssClass: "dxgvHeader",
 CommandColumnCellCssClass: "dxgvCommandColumn",
 IndentCellCssClass: "dxgvIndentCell",
 InlineEditCellCssClass: "dxgvInlineEditCell",
 DetailIndentCellCssClass: "dxgvDIC",
 DetailButtonCellCssClass: "dxgvDetailButton",
 AdaptivityEnabledCssClass: "dxgvAE",
 AdaptivityWithLimitEnabledCssClass: "dxgvALE",
 AdaptiveHiddenCssClass: "dxgvAH",
 AdaptiveIndentCellCssClass: "dxgvAIC",
 AdaptiveDetailShowButtonCssClass: "dxgvADSB",
 AdaptiveDetailHideButtonCssClass: "dxgvADHB",
 AdaptiveDetailTableCssClass: "dxgvADT",
 AdaptiveDetailCaptionCellCssClass: "dxgvADCC",
 AdaptiveDetailDataCellCssClass: "dxgvADDC",
 AdaptiveDetailSpacerCellCssClass: "dxgvADSC",
 AdaptiveDetailCommandCellCssClass: "dxgvADCMDC",
 AdaptiveDetailLayoutItemContentCssClass: "dxgvADLIC",
 LastVisibleRowClassName: "dxgvLVR"
};
var GridViewColumnType = { Data: 0, Command: 1, Band: 2 };
var GridViewRowsLayoutMode = { Default: 0, MergedCell: 1, BandedCell: 2 };
var ASPxClientGridView = ASPx.CreateClass(ASPxClientGridBase, {
 NewRowVisibleIndex: -2147483647,
 constructor: function(name){
  this.constructor.prototype.constructor.call(this, name);
  this.editMode = 2;
  this.FocusedRowChanged = new ASPxClientEvent();
  this.ColumnGrouping = new ASPxClientEvent();
  this.ColumnStartDragging  = new ASPxClientEvent();
  this.ColumnResizing  = new ASPxClientEvent();
  this.ColumnResized  = new ASPxClientEvent();
  this.ColumnMoving = new ASPxClientEvent();
  this.RowExpanding  = new ASPxClientEvent();
  this.RowCollapsing  = new ASPxClientEvent();
  this.DetailRowExpanding  = new ASPxClientEvent();
  this.DetailRowCollapsing  = new ASPxClientEvent();
  this.RowClick  = new ASPxClientEvent();
  this.RowDblClick  = new ASPxClientEvent();
  this.ContextMenu = new ASPxClientEvent();
  this.ContextMenuItemClick = new ASPxClientEvent();
  this.BatchEditRowValidating = new ASPxClientEvent();
  this.BatchEditRowInserting = new ASPxClientEvent();
  this.BatchEditRowDeleting = new ASPxClientEvent();
  this.rowsLayoutInfo = { };
  this.allowFixedGroups = false;
  this.virtualScrollMode = 0;
  this.tableHelper = null;
  this.dragHelper = null;
  this.batchEditHelper = null;
  this.virtualScrollingDelay = 500;
  this.adaptivityMode = 0;
  this.adaptivityHelper = null;
 },
 GetItem: function(visibleIndex, level){
  var res = this.GetDataRow(visibleIndex, level);
  if(res == null) res = this.GetGroupRow(visibleIndex);
  return res;
 },
 GetDataItem: function(visibleIndex) { return this.GetDataRow(visibleIndex); },
 IsDataItem: function(visibleIndex) { return this.IsDataRow(visibleIndex); },
 GetRow: function(visibleIndex) { return this.GetItem(visibleIndex); },
 GetDataItemIDPrefix: function() { return GridViewConsts.DataRowID; },
 GetEmptyDataItemIDPostfix: function() { return GridViewConsts.EmptyDataRowID; },
 GetEmptyDataItemCell: function() { 
  var row = this.GetEmptyDataItem();
  return row ? this.GetLastNonAdaptiveIndentCell(row) : null;
 },
 GetDataRow: function(visibleIndex, level) {
  if(!this.HasBandedDataRows())
   level = -1;
  if(!ASPx.IsExists(level))
   level = 0;
  var levelPostfix = level >= 0 ? "_" + level : "";
  return this.GetChildElement(GridViewConsts.DataRowID + visibleIndex + levelPostfix);
 },
 HasBandedDataRows: function() { return this.rowsLayoutInfo.mode == GridViewRowsLayoutMode.BandedCell; },
 GetBandedDataRows: function(visibleIndex) {
  var advBandedRows = [ ];
  ASPx.GetNodesByPartialId(this.GetMainTable(), this.GetDataItemIDPrefix() + visibleIndex + "_", advBandedRows)
  return advBandedRows;
 },
 GetEditingCell: function(columnIndex) { 
  var row = this.GetEditingRow();
  var cellIndex = this.GetDataCellIndex(columnIndex);
  return row ? row.cells[cellIndex] : null;
 },
 GetEditingErrorCell: function(row) { 
  var row = row || this.GetEditingErrorItem();
  return row ? this.GetLastNonAdaptiveIndentCell(row) : null;
 },
 GetErrorTextContainer: function(displayIn) {
  var errorRow = this.GetEditingErrorItem(displayIn);
  if(!errorRow) {
   var editRow = this.GetEditingRow(displayIn);
   if(editRow) {
    errorRow = this.CreateEditingErrorItem();
    errorRow.id = editRow.id.replace("DXEditingRow", this.EditingErrorItemID);
    ASPx.InsertElementAfter(errorRow, editRow);
   }
  }
  return this.GetEditingErrorCell(errorRow);
 },
 CreateEditingErrorItem: function() {
  var wrapperElement = document.createElement("div");
  wrapperElement.innerHTML = "<table><tbody>" + this.styleInfo[ASPxClientGridItemStyle.ErrorItemHtml] + "</tbody></table>";
  var row = wrapperElement.firstChild.rows[0];
  for(var i = 0; i < row.cells.length; i++) {
   var cell = row.cells[i];
   var colSpan = parseInt(ASPx.Attr.GetAttribute(cell, "data-colSpan"));
   if(!isNaN(colSpan)) 
    cell.colSpan = colSpan;
  }
  var adaptivityHelper = this.GetAdaptivityHelper();
  if(adaptivityHelper && adaptivityHelper.HasAnyAdaptiveElement()) {
   var errorCell = this.GetLastNonAdaptiveIndentCell(row);
   var adaptiveSampleCell = this.GetSampleAdaptiveDetailCell();
   errorCell.colSpan = adaptiveSampleCell.colSpan;
   errorCell.originalColSpan = adaptiveSampleCell.originalColSpan;
  }
  return row;
 },
 GetDetailRow: function(visibleIndex) { return this.GetChildElement(GridViewConsts.DetailRowID + visibleIndex); },
 GetDetailCell: function(visibleIndex) { 
  var row = this.GetDetailRow(visibleIndex);
  return row ? this.GetLastNonAdaptiveIndentCell(row) : null;
 },
 GetPreviewRow: function(visibleIndex) { return this.GetChildElement(GridViewConsts.PreviewRowID + visibleIndex); },
 GetPreviewCell: function(visibleIndex) { 
  var row = this.GetPreviewRow(visibleIndex);
  return row ? this.GetLastNonAdaptiveIndentCell(row) : null;
 },
 GetSampleAdaptiveDetailRow: function() { return this.GetChildElement(GridViewConsts.AdaptiveDetailRowID); },
 GetSampleAdaptiveDetailCell: function() { 
  var row = this.GetSampleAdaptiveDetailRow();
  return row ? this.GetLastNonAdaptiveIndentCell(row) : null;
 },
 GetAdaptiveDataRow: function(visibleIndex) { 
  if(this.IsGroupRow(visibleIndex))
   return null;
  var row = this.GetDataRow(visibleIndex);
  if(row)
   return row;
  if(this.IsInlineEditMode())
   return this.GetEditingRow();
  return null;
 },
 GetAdaptiveDetailRow: function(visibleIndex, forceCreate) {
  var row = this.GetChildElement(GridViewConsts.AdaptiveDetailRowID + visibleIndex);
  if(!row && forceCreate) {
   var sampleRow = this.GetSampleAdaptiveDetailRow();
   var dataRow = this.GetAdaptiveDataRow(visibleIndex);
   if(sampleRow && dataRow) {
    row = sampleRow.cloneNode(true);
    row.id = this.name + "_" + GridViewConsts.AdaptiveDetailRowID + visibleIndex;
    this.GetLastNonAdaptiveIndentCell(row).originalColSpan = this.GetLastNonAdaptiveIndentCell(sampleRow).originalColSpan;
    ASPx.InsertElementAfter(row, dataRow);
    for(var i = 0; i < this.indentColumnCount; i++)
     row.cells[i].style.borderBottomWidth = dataRow.cells[i].style.borderBottomWidth;
   }
  }
  return row;
 },
 GetAdaptiveHeaderContainer: function(columnIndex, adaptivePanel) { 
  if(!adaptivePanel) return null;
  var isGroupHeader = adaptivePanel === this.GetAdaptiveGroupPanel();
  var containerID = this.name + "_" + (isGroupHeader ? GridViewConsts.AdaptiveGroupHeaderID : GridViewConsts.AdaptiveHeaderID) + columnIndex;
  var adaptiveHeader = document.getElementById(containerID);
  if(!adaptiveHeader) {
    adaptiveHeader = this.GetSampleAdaptiveHeader(isGroupHeader).cloneNode(true);
    adaptiveHeader.id = containerID;
    ASPx.SetElementDisplay(adaptiveHeader, true);
    var table = ASPx.GetChildByTagName(adaptiveHeader, "TABLE", 0);
    var row = table.rows[0];
    adaptiveHeader.dxHeaderContainer = row;
    adaptivePanel.appendChild(adaptiveHeader);
   }
  return adaptiveHeader.dxHeaderContainer;
 },
 GetAdaptiveGroupPanel: function() { return this.GetChildElement(GridViewConsts.AdaptiveGroupPanelID); },
 GetAdaptiveHeaderPanel: function() { return this.GetChildElement(GridViewConsts.AdaptiveHeaderPanelID); },
 GetAdaptiveFooterPanel: function() { return this.GetChildElement(GridViewConsts.AdaptiveFooterPanelID); },
 GetSampleAdaptiveHeader: function(isGroupHeader) { return this.GetChildElement(isGroupHeader ? GridViewConsts.AdaptiveGroupHeaderID : GridViewConsts.AdaptiveHeaderID); },
 IsAdaptiveCell: function(cell) {
  var adaptiveClasses = [ASPx.GridViewConsts.AdaptiveDetailDataCellCssClass, ASPx.GridViewConsts.AdaptiveDetailCommandCellCssClass];
  for(var i = 0; i < adaptiveClasses.length; i++)
   if(ASPx.ElementHasCssClass(cell, adaptiveClasses[i])) return true;     
  return false;
 }, 
 IsCellAdaptiveHidden: function(cell) {
  return ASPx.ElementContainsCssClass(cell, ASPx.GridViewConsts.AdaptiveHiddenCssClass);
 },
 GetAdaptiveCell: function(visibleIndex, columnIndex) {
  var adaptiveDetailsCell = this.GetAdaptiveDetailCell(visibleIndex, false);
  return adaptiveDetailsCell && adaptiveDetailsCell.adaptiveDetailsCells ? adaptiveDetailsCell.adaptiveDetailsCells[columnIndex] : null;
 },
 GetAdaptiveDetailCell: function(visibleIndex, forceCreate) { 
  var row = this.GetAdaptiveDetailRow(visibleIndex, forceCreate);
  return row ? this.GetLastNonAdaptiveIndentCell(row) : null;
 },
 GetDetailButtonCell: function(visibleIndex, fromAdaptiveRow) {
  var row = fromAdaptiveRow ? this.GetAdaptiveDetailRow(visibleIndex) : this.GetAdaptiveDataRow(visibleIndex);
  return ASPx.GetChildByPartialClassName(row, GridViewConsts.DetailButtonCellCssClass);
 },
 GetGroupRow: function(visibleIndex) { 
  var element = this.GetChildElement(GridViewConsts.GroupRowID + visibleIndex);
  if(!element)
   element = this.GetExpandedGroupRow(visibleIndex);
  return element; 
 },
 GetGroupCell: function(visibleIndex) { 
  var row = this.GetGroupRow(visibleIndex);
  return row ? this.GetLastNonAdaptiveIndentCell(row) : null;
 },
 GetGroupMoreRows: function(visibleIndex){
  var group = this.GetGroupRow(visibleIndex);
  if(!group)
   return null;
  var elements = ASPx.GetNodesByPartialClassName(group, "dxgvFGI");
  return elements && elements.length ? elements[0] : null;
 },
 GetGroupLevel: function(visibleIndex){
  var group = this.GetGroupRow(visibleIndex);
  return group ? this.GetFooterIndentCount(group) : -1;
 },
 GetExpandedGroupRow: function(visibleIndex) { return this.GetChildElement(GridViewConsts.GroupRowID + "Exp" + visibleIndex); },
 _isGroupRow: function(row) { return row.id.indexOf(GridViewConsts.GroupRowID) > -1; },
 IsHeaderRow: function(row) { return this.IsHeaderRowID(row.id); },
 IsHeaderRowID: function(id) { return id.indexOf(this.name + GridViewConsts.HeaderRowID) == 0; },
 IsEmptyHeaderID: function(id) { return id.indexOf(this.EmptyHeaderSuffix) > -1 },
 IsBandedDataRowID: function(id) {
  var pattern = new RegExp(this.name + GridViewConsts.BandedRowPattern);
  return pattern.test(id);
 },
 CreateEndlessPagingHelper: function(){
  return new ASPx.GridViewEndlessPagingHelper(this);
 },
 GetCssClassNamePrefix: function() { return "dxgv"; },
 GetFilterRow: function() { return this.GetChildElement(GridViewConsts.FilterRowID); },
 GetFilterCell: function(columnIndex) { 
  var row = this.GetFilterRow();
  var cellIndex = this.GetDataCellIndex(columnIndex);
  return row ? row.cells[cellIndex] : null;
 },
 GetDataRowLevel: function(columnIndex){
  return this.GetRowsLayout().GetDataCellLevel(columnIndex);
 },
 GetDataCellIndex: function(columnIndex, visibleIndex) {
  return this.GetRowsLayout().GetDataCellIndex(columnIndex, visibleIndex);
 },
 GetColumnIndexByDataCell: function(dataCell) {
  if(!dataCell) return -1;
  if(ASPx.IsExists(dataCell.columnIndex)) return dataCell.columnIndex;
  var dataRow = this.GetDataItemByChild(dataCell);
  var visibleIndex = dataRow ? this.getItemIndex(dataRow.id) : -1;
  var level = dataRow ? this.GetBandedDataRowLevelByID(dataRow.id) : -1;
  return this.GetRowsLayout().GetColumnIndex(dataCell.cellIndex, visibleIndex, level);
 },
 GetDataItemByChild: function(element) { return ASPx.GetParent(element, this.IsDataItemElement.aspxBind(this)); },
 IsDataItemElement: function(item) {
  if(!item || !item.id) return false;
  var regex = new RegExp(GridViewConsts.DataRowID + "\\d+(?:_\\d+)?$");
  return regex.test(item.id);
 },
 GetDataCell: function(visibleIndex, columnIndex) {
  var level = this.GetDataRowLevel(columnIndex);
  var dataRow = this.GetDataRow(visibleIndex, level);
  return this.GetDataCellByRow(dataRow, columnIndex, visibleIndex);
 },
 GetDataCellByRow: function(row, columnIndex, visibleIndex){
  if(!row)
   return null;
  var cellIndex = this.GetDataCellIndex(columnIndex, visibleIndex);
  return (0 <= cellIndex && cellIndex < row.cells.length) ? row.cells[cellIndex] : null;
 },
 GetVisibleColumnIndices: function() {
  return this.GetRowsLayout().GetVisibleColumnIndices();
 },
 GetArmatureCells: function(columnIndex) {
  var result = [ ];
  var cellIndex = this.GetDataCellIndex(columnIndex);
  var tableHelper = this.GetTableHelper();
  if(tableHelper) {
   if(tableHelper.GetHeaderTable()) {
    var cells = tableHelper.GetArmatureCells(tableHelper.GetHeaderTable());
    if(cells) result.push(cells[cellIndex]);
   }
   if(tableHelper.GetContentTable()) {
    var cells = tableHelper.GetArmatureCells(tableHelper.GetContentTable());
    if(cells) result.push(cells[cellIndex]);
   }
   if(tableHelper.GetFooterTable()) {
    var cells = tableHelper.GetArmatureCells(tableHelper.GetFooterTable());
    if(cells) result.push(cells[cellIndex]);
   }
  }
  else {
   var mainTable = this.GetMainTable();
   var rowIndex = this.GetRowsLayout().GetDataCellLevel(columnIndex);
   rowIndex = Math.max(0, rowIndex);
   result.push(mainTable.rows[rowIndex].cells[cellIndex]);
  }
  return result;
 },
 GetLastNonAdaptiveIndentCell: function(row) {
  var count = 1;
  while(count <= row.cells.length){
   var cell = row.cells[row.cells.length - count]
   if(!ASPx.ElementHasCssClass(cell, GridViewConsts.AdaptiveIndentCellCssClass))
    return cell;
   count++;
  }
  return null;
 },
 GetHeaderScrollContainer:function() {
  return ASPx.GetNodeByClassName(this.GetMainElement(), GridViewConsts.HeaderScrollDivContainerCssClass);
 },
 GetFooterScrollContainer:function() {
  return ASPx.GetNodeByClassName(this.GetMainElement(), GridViewConsts.FooterScrollDivContainerCssClass);
 },
 SetHeadersClientEvents: function() {
  if(!this.AllowResizing())
   return;
  var helper = this.GetResizingHelper();
  var attachMouseMove = function(headerCell) { 
   ASPx.Evt.AttachEventToElement(headerCell, "mousemove", function(e) { helper.UpdateCursor(e, headerCell); });
  };
  for(var i = 0; i < this.columns.length; i++) {
   var header = this.GetHeader(this.columns[i].index);
   if(header) 
    attachMouseMove(header);
  }
 },
 GetFooterRow: function(){
  return this.GetChildElement(GridViewConsts.FooterRowID);
 },
 GetFooterCell: function(columnIndex){
  var row = this.GetFooterRow();
  var cellIndex = this.GetDataCellIndex(columnIndex);
  return row ? row.cells[cellIndex] : null;
 },
 GetGroupFooterCells: function(columnIndex) {
  var mainTable = this.GetMainTable();
  var tBody = ASPx.GetChildByTagName(mainTable, "TBODY");
  var groupFooterRows = ASPx.GetChildNodesByPartialClassName(tBody, GridViewConsts.GroupFooterRowClass);
  var cellIndex = this.GetDataCellIndex(columnIndex);
  var result = [ ];
  for(var i = 0; i < groupFooterRows.length; i++) {
   var row = groupFooterRows[i];
   var cell = row && row.cells[cellIndex];
   if(cell)
    result.push(cell);
  }
  return result;
 },
 GetUserCommandNamesForRow: function() { return ASPxClientGridBase.prototype.GetUserCommandNamesForRow().concat([ "ShowAdaptiveDetail", "HideAdaptiveDetail" ]); },
 GetItemVisibleIndexRegExp: function(dataAndGroupOnly) {
  var idParts = [ GridViewConsts.DataRowID, GridViewConsts.GroupRowID + "(?:Exp)?", GridViewConsts.AdaptiveDetailRowID ];
  if(!dataAndGroupOnly) {
   idParts.push(GridViewConsts.PreviewRowID);
   idParts.push(GridViewConsts.DetailRowID);
  }
  return this.GetItemVisibleIndexRegExpByIdParts(idParts);
 },
 IsMainTableChildElement: function(src) {
  if(!src) return true;
  var tables = [ this.GetMainTable() ];
  var tableHelper = this.GetTableHelper();
  if(tableHelper) {
   tables.push(tableHelper.GetHeaderTable());
   tables.push(tableHelper.GetFooterTable());
  }
  for(var i = 0; i < tables.length; i++) {
   if(ASPx.GetIsParent(tables[i], src))
    return true;
  }
  return false;
 },
 CreateBatchEditApi: function() { return new ASPxClientGridViewBatchEditApi(this); },
 IsVirtualScrolling: function() { return this.virtualScrollMode > 0; },
 IsVirtualSmoothScrolling: function() { return this.virtualScrollMode === 2; },
 InitializeProperties: function(properties){
  if(properties.adaptiveModeInfo)
   this.SetAdaptiveMode(properties.adaptiveModeInfo);
 },
 Initialize: function() {
  ASPxClientGridBase.prototype.Initialize.call(this);
  this.enabled && this.SetHeadersClientEvents();
  if(this.enableKeyboard) {
   this.kbdHelper = this.customKbdHelperName ? new ASPx[this.customKbdHelperName](this) : new ASPx.GridViewKbdHelper(this);
   this.kbdHelper.Init();
   ASPx.KbdHelper.RegisterAccessKey(this);
  }
  this.ResetStretchedColumnWidth();
  this.PrepareEditorsToKeyboardNavigation();
  this.AttachInternalContexMenuEventHandler();
  this.InitializeDropDownElementsScrolling();
 },
 InitializeDropDownElementsScrolling: function() {
  if(this.HasVertScroll()) {
   this.ScrollableContainerDropDownEditors = null;
   var vertScrollableControl = this.GetScrollHelper().GetVertScrollableControl();
   ASPx.Evt.AttachEventToElement(vertScrollableControl, "scroll", function(evt) {
    if(ASPx.Evt.GetEventSource(evt) === vertScrollableControl)
     this.AdjustDropDownElements();
   }.aspxBind(this));
  }
 },
 AttachInternalContexMenuEventHandler: function() {
  if(this.IsDetailGrid()) {
   ASPx.Evt.AttachEventToElement(this.GetMainElement(), "contextmenu", function(e) {
    var showDefaultMenu = ASPx.EventStorage.getInstance().Load(e);
    if(showDefaultMenu)
     ASPx.Evt.CancelBubble(e);
    else 
     ASPx.EventStorage.getInstance().Save(e, true);
   }.aspxBind(this), true);
  }
 },
 AdjustControlCore: function() {
  ASPxClientGridBase.prototype.AdjustControlCore.call(this);
  this.CalculateAdaptivity();
  this.UpdateIndentCellWidths();
  this.ValidateColumnWidths();
 },
 IsAdjustmentRequired: function() {
  if(ASPxClientControl.prototype.IsAdjustmentRequired.call(this))
   return true;
  var scrollHelper = this.GetScrollHelper()
  return scrollHelper ? scrollHelper.IsRestoreScrollPosition() : false;
 },
 SaveCallbackSettings: function() {
  ASPxClientGridBase.prototype.SaveCallbackSettings.call(this);
  var helper = this.GetFixedColumnsHelper();
  if(helper != null) helper.SaveCallbackSettings();
 },
 RestoreCallbackSettings: function() {
  this.ResetStretchedColumnWidth();
  var fixedColumnsHelper = this.GetFixedColumnsHelper();
  if(fixedColumnsHelper != null)
   fixedColumnsHelper.RestoreCallbackSettings();
  this.SaveAdaptiveScrollTop();
  this.UpdateScrollableControls();
  if(fixedColumnsHelper != null)
   fixedColumnsHelper.HideColumnsRelyOnScrollPosition();
  this.UpdateIndentCellWidths();
  this.ValidateColumnWidths();
  ASPxClientGridBase.prototype.RestoreCallbackSettings.call(this);
 },
 SaveAdaptiveScrollTop: function() {
  this.adaptiveScrollTop = this.stateObject.scrollState ? this.stateObject.scrollState[1] : null;
 },
 ApplyAdaptiveScrollTop: function() {
  if(ASPx.IsExists(this.adaptiveScrollTop)) {
   this.SetVerticalScrollPosition(this.adaptiveScrollTop);
   this.adaptiveScrollTop = null;
  }
 },
 GetPopupEditFormHorzOffsetCorrection: function(popup) {
  var scrollHelper = this.GetScrollHelper();
  if(!scrollHelper) return 0;
  var scrollDiv = scrollHelper.GetHorzScrollableControl();
  if(!scrollDiv)  return 0;
  var horzAlign = popup.GetHorizontalAlign();
  if(ASPx.PopupUtils.IsRightSidesAlign(horzAlign) || ASPx.PopupUtils.IsOutsideRightAlign(horzAlign))
   return scrollDiv.scrollWidth - scrollDiv.offsetWidth;
  if(ASPx.PopupUtils.IsCenterAlign(horzAlign))
   return (scrollDiv.scrollWidth - scrollDiv.offsetWidth) / 2;
  return 0;
 },
 UpdateIndentCellWidths: function() {
  var tableHelper = this.GetTableHelper();
  if(tableHelper)
     tableHelper.UpdateIndentCellWidths();
 },
 OnBeforeCallbackOrPostBack: function() {
  ASPxClientGridBase.prototype.OnBeforeCallbackOrPostBack.call(this);
  this.SaveControlDimensions();
 },
 OnBeforeCallback: function(command) {
  ASPxClientGridBase.prototype.OnBeforeCallback.call(this, command);
  var scrollHelper = this.GetScrollHelper();
  if(scrollHelper && this.IsVirtualScrolling())
   scrollHelper.ClearVirtualScrollTimer();
 },
 OnAfterCallback: function() { 
  var layout = this.GetRowsLayout();
  layout && layout.Invalidate();
  ASPxClientGridBase.prototype.OnAfterCallback.call(this);
  this.SaveControlDimensions();
  var fixedGroupsHelper = this.GetFixedGroupsHelper();
  if(fixedGroupsHelper){
   fixedGroupsHelper.PopulateRowsHeight();
   fixedGroupsHelper.UpdateFixedGroups();
  }
  this.PrepareEditorsToKeyboardNavigation();
  this.UpdateLastVisibleRow();
  this.InitializeDropDownElementsScrolling();
  if(this.rowsLayout)
   this.rowsLayout.Invalidate();
 },
 PrepareEditorsToKeyboardNavigation: function() {
  if(!this.RequireEditorsKeyboardNavigation()) return;
  for(var i = 0; i < this.columns.length; i++) {
   this.AttachEventToEditor(this.columns[i].index, "GotFocus", function(s, e) { this.OnEditorGotFocus(s, e); }.aspxBind(this));
   this.AttachEventToEditor(this.columns[i].index, "KeyDown", function(s, e) { this.OnEditorKeyDown(s, e); }.aspxBind(this));
  }
 },
 RequireEditorsKeyboardNavigation: function() {
  return this.IsInlineEditMode() && this.GetFixedColumnsHelper();
 },
 OnEditorGotFocus: function(s, e) {
  if(!this.RequireEditorsKeyboardNavigation()) return;
  var helper = this.GetFixedColumnsHelper();
  helper.TryShowColumn(s.dxgvColumnIndex);
 },
 OnEditorKeyDown: function(s, e) {
  if(!this.RequireEditorsKeyboardNavigation()) return;
  var keyCode = ASPx.Evt.GetKeyCode(e.htmlEvent);
  if(keyCode !== ASPx.Key.Tab) return;
  var helper = this.GetFixedColumnsHelper();
  var matrix = this.GetHeaderMatrix();
  var neighborColumnIndex = e.htmlEvent.shiftKey ? matrix.GetLeftNeighbor(s.dxgvColumnIndex, true) : matrix.GetRightNeighbor(s.dxgvColumnIndex, true);
  var neighborEditor = this.GetEditorByColumnIndex(neighborColumnIndex);
  if(neighborEditor && helper.TryShowColumn(neighborColumnIndex, true)) {
   ASPx.Evt.PreventEventAndBubble(e.htmlEvent);
   ASPx.Selection.SetCaretPosition(s.GetInputElement());
   neighborEditor.Focus();
  }
 },
 IsInlineEditMode: function() { return this.editMode === 0; },
 IsEditRowHasDisplayedDataRow: function() { return this.editMode >= 2; },
 canGroupByColumn: function(headerElement) {
  return this.getColumnObject(headerElement.id).allowGroup;
 },
 canDragColumn: function(headerElement) {
  var column = this._getColumnObjectByArg(this.getColumnIndex(headerElement.id));
  return !this.RaiseColumnStartDragging(column) && this.getColumnObject(headerElement.id).allowDrag;
 },
 doPagerOnClick: function(id) {
  if(!ASPx.IsExists(id)) return;
  if(ASPx.Browser.IE && this.kbdHelper)
   this.kbdHelper.Focus();
  var scrollHelper = this.GetScrollHelper();
  if(scrollHelper)
   scrollHelper.ResetScrollTop();
  ASPxClientGridBase.prototype.doPagerOnClick.call(this, id);
 },
 TryStartColumnResizing: function(e, headerCell) {
  var helper = this.GetResizingHelper();
  if(!helper || !helper.CanStartResizing(e, headerCell))
   return false;
  var column = this.columns[helper.GetResizingColumnIndex(e, headerCell)];
  if(this.RaiseColumnResizing(column))
   return false;
  helper.StartResizing(column.index);
  return true;
 },
 IsPossibleSelectItem: function(visibleIndex, newSelectedValue){
  return this.IsDataRow(visibleIndex) && ASPxClientGridBase.prototype.IsPossibleSelectItem.call(this, visibleIndex, newSelectedValue);
 },
 _isRowSelected: function(visibleIndex) {
  return this.IsDataRow(visibleIndex) && ASPxClientGridBase.prototype._isRowSelected.call(this, visibleIndex);
 },
 GetDataItemCountOnPage: function(){
  var dataRowCount = 0;
  for(var i = 0; i < this.pageRowCount; i++){
   var index = i + this.visibleStartIndex;
   if(!this.IsGroupRow(index))
    dataRowCount++;
  }
  return dataRowCount;
 },
 GetFocusedItemStyle: function(visibleIndex, focused){
  var row = this.GetItem(visibleIndex);
  if(focused && row)
   return this._isGroupRow(row) ? ASPxClientGridItemStyle.FocusedGroupItem : ASPxClientGridItemStyle.FocusedItem;
  return ASPxClientGridBase.prototype.GetFocusedItemStyle.call(this, visibleIndex, focused);
 },
 RequireChangeItemStyle: function(visibleIndex, itemStyle){
  if(!ASPxClientGridBase.prototype.RequireChangeItemStyle.call(this, visibleIndex, itemStyle))
   return false;
  return itemStyle != ASPxClientGridItemStyle.Selected || !this.IsGroupRow(visibleIndex); 
 },
 GetItemStyle: function(visibleIndex){
  var style = ASPxClientGridBase.prototype.GetItemStyle.call(this, visibleIndex);
  if(style == ASPxClientGridItemStyle.FocusedItem && this.IsGroupRow(visibleIndex))
   style = ASPxClientGridItemStyle.FocusedGroupItem;
  return style;
 },
 ApplyItemStyle: function(visibleIndex, styleInfo) {
  if(this.HasBandedDataRows() && !this.IsGroupRow(visibleIndex)){
   var rows = this.GetBandedDataRows(visibleIndex);
   for(var i = 0; i < rows.length; i++)
    this.ApplyElementStyle(rows[i], styleInfo);
  } else
   ASPxClientGridBase.prototype.ApplyItemStyle.call(this, visibleIndex, styleInfo);
  var adaptivityHelper = this.GetAdaptivityHelper();
  if(adaptivityHelper && !adaptivityHelper.IsResponsiveMode()) {
   var item = this.GetItem(visibleIndex);
   if(item && adaptivityHelper.HasAnyAdaptiveElement() && !this.IsGroupRow(visibleIndex))
    ASPx.AddClassNameToElement(item, GridViewConsts.AdaptiveHiddenCssClass);
   var adaptiveItem = this.GetAdaptiveDetailRow(visibleIndex);
   if(adaptiveItem)
    this.ApplyElementStyle(adaptiveItem, styleInfo);
  }
 },
 OnScroll: function(evt){
  var fixedGroupsHelper = this.GetFixedGroupsHelper();
  if(fixedGroupsHelper)
   fixedGroupsHelper.OnDocumentScroll();
 },
 getItemByHtmlEvent: function(evt) {
  return this.getItemByHtmlEventCore(evt, GridViewConsts.DataRowID) || this.getItemByHtmlEventCore(evt, GridViewConsts.GroupRowID) || this.getItemByHtmlEventCore(evt, GridViewConsts.AdaptiveDetailRowID);
 },
 NeedProcessTableClick: function(evt){
  var headerTable = ASPx.GetParentByPartialId(ASPx.Evt.GetEventSource(evt), GridViewConsts.HeaderTableID);
  if(headerTable) {
   var headerTableID = headerTable.id;
   var gridID = headerTableID.substr(0, headerTableID.length - GridViewConsts.HeaderTableID.length - 1);
   return this.name == gridID;
  }
  return ASPxClientGridBase.prototype.NeedProcessTableClick.call(this, evt);
 },
 IsHeaderChild: function(source) {
  var headerRowCount = this.GetHeaderMatrix().GetRowCount();
  for(var i = 0; i < headerRowCount; i++) {
   if(ASPx.GetIsParent(this.GetHeaderRow(i), source))
    return true;
  }
  return false;
 },
 IsActionElement: function(mainElement, source) {
  if(this.testActionElement(source))
   return true;
  var parent = source;
  var controlCollection = ASPx.GetControlCollection();
  while(parent.id !== mainElement.id) {
   var control = controlCollection.Get(parent.id);
   if(ASPx.IsExists(control) && (control instanceof ASPxClientButton || control instanceof ASPxClientEditBase))
    return true;
   parent = parent.parentElement;
  }  
  return false;
 },
 getItemIndex: function(rowId) {
  if(this.IsHeaderRowID(rowId))
   return -1;
  if(this.IsBandedDataRowID(rowId))
   return this.GetBandedDataRowVisibleIndexByID(rowId);
  return ASPxClientGridBase.prototype.getItemIndex.call(this, rowId);
 },
 GetBandedDataRowLevelByID: function(rowId){
  if(!rowId) return -1;
  var matches = rowId.match(this.name + GridViewConsts.BandedRowPattern);
  return matches && matches.length > 2 ? parseInt(matches[2]) : -1;
 },
 GetBandedDataRowVisibleIndexByID: function(rowId){
  if(!rowId) return -1;
  var matches = rowId.match(this.name + GridViewConsts.BandedRowPattern);
  return matches && matches.length > 2 ? parseInt(matches[1]) : -1;
 },
 CreateBatchEditHelper: function() { return new ASPx.GridViewBatchEditHelper(this); },
 CreateCellFocusHelper: function() { return new ASPx.GridViewCellFocusHelper(this); },
 GetTableHelper: function() {
  if(!this.tableHelper && typeof(ASPx.GridViewTableHelper) != "undefined")
   this.tableHelper = new ASPx.GridViewTableHelper(this, this.MainTableID, GridViewConsts.HeaderTableID, GridViewConsts.FooterTableID, this.horzScroll, this.vertScroll);
  return this.tableHelper;
 },
 GetScrollHelper: function() {
  if(!this.HasScrolling()) return null;
  if(!this.scrollableHelper)
   this.scrollableHelper = new ASPx.GridViewTableScrollHelper(this.GetTableHelper());
  return this.scrollableHelper;
 },
 GetFixedColumnsHelper: function() {
  if(!this.GetFixedColumnsDiv()) return null;
  if(!this.fixedColumnsHelper)
   this.fixedColumnsHelper = new ASPx.GridViewTableFixedColumnsHelper(this.GetTableHelper(), this.FixedColumnsDivID, this.FixedColumnsContentDivID, this.fixedColumnCount);
  return this.fixedColumnsHelper;
 },
 GetFixedGroupsHelper: function() {
  if(!this.allowFixedGroups) return null;
  if(!this.fixedGroupsHelper)
   this.fixedGroupsHelper = new ASPx.GridViewFixedGroupsHelper(this.GetTableHelper());
  return this.fixedGroupsHelper;
 },
 GetResizingHelper: function() {
  if(!this.AllowResizing()) return null;
  if(!this.resizingHelper)
   this.resizingHelper = new ASPx.GridViewTableResizingHelper(this.GetTableHelper());
  return this.resizingHelper;
 },
 GetHeaderMatrix: function() {
  if(!this.headerMatrix)
   this.headerMatrix = new GridViewHeaderMatrix(this);
  return this.headerMatrix;
 },
 GetRowsLayout: function(){
  if(!this.rowsLayout)
     this.rowsLayout = this.CreateRowsLayout();
  return this.rowsLayout;
 },
 CreateRowsLayout: function(){
  if(this.rowsLayoutInfo.mode == GridViewRowsLayoutMode.MergedCell)
   return new GridViewRowsCellMergingLayout(this);
  if(this.rowsLayoutInfo.mode == GridViewRowsLayoutMode.BandedCell)
   return new GridViewBandedRowsLayout(this);
  return new GridViewRowsDefaultLayout(this);
 },
 ValidateColumnWidths: function() {
  var helper = this.GetResizingHelper();
  if(helper)
   helper.ValidateColumnWidths();
 },
 ResetStretchedColumnWidth: function() {
  var helper = this.GetResizingHelper();
  if(helper)
   helper.ResetStretchedColumnWidth();
 },
 SaveControlDimensions: function() {
  var helper = this.GetResizingHelper();
  if(helper)
   helper.SaveControlDimensions(true);
 },
 AdjustDropDownElements: function() {
  var vertScrollableControl = this.GetScrollHelper().GetVertScrollableControl();
  var scrollableRect = vertScrollableControl.getBoundingClientRect();
  ASPx.Data.ForEach(this.GetDropDownEditors(), function(dropDownEditor) {
   var editorRect = dropDownEditor.GetMainElement().getBoundingClientRect();
   var editorBottomIsVisible = editorRect.top + editorRect.height < scrollableRect.bottom
    && editorRect.top + editorRect.height > scrollableRect.top;
   if(dropDownEditor.GetPopupControl().IsVisible())
    if(editorBottomIsVisible)
     dropDownEditor.AdjustDropDownWindow();
    else
     dropDownEditor.HideDropDown();
  });
 },
 GetDropDownEditors: function() {
  if(this.ScrollableContainerDropDownEditors === null) {
   var vertScrollableControl = this.GetScrollHelper().GetVertScrollableControl();
   var ddPopupElements = ASPx.GetNodesByClassName(vertScrollableControl, "dxpc-ddSys");
   this.ScrollableContainerDropDownEditors = ddPopupElements.map(function(element) {
    var editorName = element.id.replace(/_DDD_PW-\d+$/g, "");
    return ASPx.GetControlCollection().GetByName(editorName);
   });
  }
  return this.ScrollableContainerDropDownEditors;
 },
 OnBrowserWindowResize: function(e) {
  this.EndBatchEdit(e);
  if(this.AllowResizing() && !this.HasScrolling())
   this.ValidateColumnWidths();
  this.AdjustControl();
 },
 EndBatchEdit: function(e){ 
  if(this.GetAdaptivityHelper() && this.GetBatchEditHelper() && e.prevWndWidth != e.wndWidth)
   this.GetBatchEditHelper().EndEdit();
 },
 GetAdaptivityHelper: function() {
  if(this.adaptivityMode === 0) return null;
  if(!this.adaptivityHelper)
   this.adaptivityHelper = new ASPx.GridViewColumnAdaptivityHelper(this);
  return this.adaptivityHelper;
 },
 SetAdaptiveMode: function(data) {
  this.adaptivityMode = data.adaptivityMode;
  var adaptivityHelper = this.GetAdaptivityHelper();
  if(adaptivityHelper)
   adaptivityHelper.ApplySettings(data);
 }, 
 CalculateAdaptivity: function() {
  var adaptivityHelper = this.GetAdaptivityHelper();
  if(adaptivityHelper)
   adaptivityHelper.CalculateAdaptivity();
 },
 ResetAdaptivityOnCallback: function(){
  var adaptivityHelper = this.GetAdaptivityHelper();
  if(adaptivityHelper)
   adaptivityHelper.ResetAdaptivityOnCallback();
 },
 RestoreAdaptivityState: function() {
  var adaptivityHelper = this.GetAdaptivityHelper();
  if(adaptivityHelper)
   adaptivityHelper.RestoreAdaptivityState();
 },
 ToggleAdaptiveDetails: function(visibleIndex) {
  var adaptivityHelper = this.GetAdaptivityHelper();
  if(adaptivityHelper)
   adaptivityHelper.ToggleAdaptiveDetails(visibleIndex);
 },
 UA_ShowAdaptiveDetail: function(visibleIndex) {
  this.ToggleAdaptiveDetails(visibleIndex);
 },
 UA_HideAdaptiveDetail: function(visibleIndex) {
  this.ToggleAdaptiveDetails(visibleIndex);
 },
 IsLastDataRow: function(visibleIndex) {
  return visibleIndex == this.visibleStartIndex + this.pageRowCount - 1 && (this.IsLastPage() || this.pageIndex < 0);
 },
 UpdateLastVisibleRow: function() {
  var tBody = ASPx.GetNodeByTagName(this.GetMainTable(), "TBODY", 0);
  var prevLastRows = ASPx.GetChildNodesByClassName(tBody, GridViewConsts.LastVisibleRowClassName);
  for(var i = 0; i < prevLastRows.length; i++) {
   ASPx.RemoveClassNameFromElement(prevLastRows[i], GridViewConsts.LastVisibleRowClassName);
  }
  var lastRow = this.FindLastVisibleRow();
  if(lastRow)
   ASPx.AddClassNameToElement(lastRow, GridViewConsts.LastVisibleRowClassName);
 },
 FindLastVisibleRow: function() {
  var dataGroupRowRegEx = this.GetItemVisibleIndexRegExp(false);
  var rows = this.GetMainTable().rows;
  for(var i = rows.length - 1; i >= 0; i--) {
   var row = rows[i];
   if(ASPx.ElementContainsCssClass(row, GridViewConsts.EmptyPagerRowCssClass))
    return row;
   if((dataGroupRowRegEx.test(row.id) || row.id && row.id.indexOf(this.EditingRowID) > -1) && ASPx.GetElementDisplay(row))
    return row;
  }
  return this.GetEmptyDataItem();
 },
 OnCallbackFinalized: function() {
  this.ResetAdaptivityOnCallback();
  ASPxClientGridBase.prototype.OnCallbackFinalized.call(this);
  this.AdjustPagerControls();
  this.CalculateAdaptivity();
  this.RestoreAdaptivityState();
 },
 ProcessContextMenuItemClick: function(e) {
  var item = e.item;
  var elementInfo = item.menu.elementInfo;
  switch(item.name){
   case this.ContextMenuItems.ClearGrouping:
    this.ContextMenuClearGrouping();
    break;
   case this.ContextMenuItems.GroupByColumn:
    this.GroupBy(elementInfo.index);
    break;
   case this.ContextMenuItems.UngroupColumn:
    this.UnGroup(elementInfo.index);
    break;
   default:
    ASPxClientGridBase.prototype.ProcessContextMenuItemClick.call(this, e);
  }
 },
 GetContextMenuObjectTypes: function(){
  var objectTypes = { };
  objectTypes[this.name + "_" + "grouppanel"]            = "grouppanel";
  objectTypes[this.name + "_" + GridViewConsts.AdaptiveGroupPanelID]    = "grouppanel";
  objectTypes[this.name + GridViewConsts.HeaderRowID]          = "emptyheader";
  objectTypes[this.name + "_" + "col"]             = "header";
  objectTypes[this.name + this.CustomizationWindowSuffix + "_" + "col"]    = "header";
  objectTypes[this.name + "_" + "groupcol"]           = "header";
  objectTypes[this.name + "_" + GridViewConsts.DataRowID]         = "row";
  objectTypes[this.name + "_" + GridViewConsts.DetailRowID]       = "row";
  objectTypes[this.name + "_" + GridViewConsts.EmptyDataRowID]       = "emptyrow";
  objectTypes[this.name + "_" + GridViewConsts.GroupRowID]        = "grouprow";
  objectTypes[this.name + "_" + GridViewConsts.GroupRowID + "Exp"]      = "grouprow";
  objectTypes[this.name + "_" + GridViewConsts.FooterRowID]       = "footer";
  objectTypes[this.name + "_" + GridViewConsts.FilterRowID]       = "filterrow";
  objectTypes[this.name + "_" + GridViewConsts.GroupFooterRowID]     = "groupfooter";
  return objectTypes;
 },
 SetWidth: function(width) {
  if(this.IsControlCollapsed())
   this.ExpandControl();
  var mainElemnt = this.GetMainElement();
  if(!ASPx.IsExistsElement(mainElemnt) || mainElemnt.offsetWidth === width) return;
  var scrollHelper = this.GetScrollHelper();
  if(scrollHelper)
   scrollHelper.OnSetWidth(width);
  this.ResetControlAdjustment();
  ASPxClientControl.prototype.SetWidth.call(this, width);
  this.AssignEllipsisToolTips();
 },
 NeedCollapseControlCore: function() {
  var adaptivityHelper = this.GetAdaptivityHelper();
  return adaptivityHelper && adaptivityHelper.IsResponsiveMode() || ASPxClientGridBase.prototype.NeedCollapseControlCore.call(this);
 },
 SortBy: function(column, sortOrder, reset, sortIndex){
    ASPxClientGridBase.prototype.SortBy.call(this, column, sortOrder, reset, sortIndex);
 },
 MoveColumn: function(column, columnMoveTo, moveBefore, moveToGroup, moveFromGroup){
  ASPxClientGridBase.prototype.MoveColumn.call(this, column, columnMoveTo, moveBefore, moveToGroup, moveFromGroup);
 },
 GroupBy: function(column, groupIndex, sortOrder){
  if(this.RaiseColumnGrouping(this._getColumnObjectByArg(column))) return;
  column = this._getColumnIndexByColumnArgs(column);
  if(!ASPx.IsExists(groupIndex)) groupIndex = "";
  if(!ASPx.IsExists(sortOrder)) sortOrder = "ASC";
  this.gridCallBack([ASPxClientGridViewCallbackCommand.Group, column, groupIndex, sortOrder]);
 },
 UnGroup: function(column){
  column = this._getColumnIndexByColumnArgs(column);
  this.GroupBy(column, -1);
 },
 ExpandAll: function(){
  this.gridCallBack([ASPxClientGridViewCallbackCommand.ExpandAll]);
 },
 CollapseAll: function(){
  this.gridCallBack([ASPxClientGridViewCallbackCommand.CollapseAll]);
 },
 ExpandAllDetailRows: function(){
  this.gridCallBack([ASPxClientGridViewCallbackCommand.ShowAllDetail]);
 },
 CollapseAllDetailRows: function(){
  this.gridCallBack([ASPxClientGridViewCallbackCommand.HideAllDetail]);
 },
 ExpandRow: function(visibleIndex, recursive){
  if(this.RaiseRowExpanding(visibleIndex)) return;
  recursive = !!recursive;
  this.gridCallBack([ASPxClientGridViewCallbackCommand.ExpandRow, visibleIndex, recursive]);
 },
 CollapseRow: function(visibleIndex, recursive){
  if(this.RaiseRowCollapsing(visibleIndex)) return;
  recursive = !!recursive;
  this.gridCallBack([ASPxClientGridViewCallbackCommand.CollapseRow, visibleIndex, recursive]);
 },
 MakeRowVisible: function(visibleIndex) {
  if(!this.HasVertScroll()) return;
  var row = this.GetItem(visibleIndex);
  if(row == null && visibleIndex >= this.visibleStartIndex && visibleIndex < this.visibleStartIndex + this.pageRowCount) 
   row = this.GetEditingRow();
  if(row == null) return;
  this.GetScrollHelper().MakeRowVisible(row);
 },
 ExpandDetailRow: function(visibleIndex){
  var key = this.GetRowKey(visibleIndex);
  if(key == null) return;
  if(this.RaiseDetailRowExpanding(visibleIndex)) return;
  this.gridCallBack([ASPxClientGridViewCallbackCommand.ShowDetailRow, key]);
 },
 CollapseDetailRow: function(visibleIndex){
  var key = this.GetRowKey(visibleIndex);
  if(key == null) return;
  if(this.RaiseDetailRowCollapsing(visibleIndex)) return;
  this.gridCallBack([ASPxClientGridViewCallbackCommand.HideDetailRow, key]);
 },
 GetRowKey: function(visibleIndex) {
  return this.GetItemKey(visibleIndex);
 },
 StartEditRow: function(visibleIndex) {
    this.StartEditItem(visibleIndex);
 },
 StartEditRowByKey: function(key) {
  this.StartEditItemByKey(key);
 },
 IsNewRowEditing: function() {
  return this.IsNewItemEditing();
 },
 AddNewRow: function(){
    this.AddNewItem();
 },
 DeleteRow: function(visibleIndex){
  this.DeleteItem(visibleIndex);
 },
 DeleteRowByKey: function(key) {
  this.DeleteItemByKey(key);
 },
 GetFocusedRowIndex: function() {
  return this._getFocusedItemIndex();
 },
 SetFocusedRowIndex: function(visibleIndex) {
  return this._setFocusedItemIndex(visibleIndex);
 },
 SelectRows: function(visibleIndices, selected){
  this.SelectItemsCore(visibleIndices, selected, false);
 },
 SelectRowsByKey: function(keys, selected){
  this.SelectItemsByKey(keys, selected);
 },
 UnselectRowsByKey: function(keys){
  this.SelectRowsByKey(keys, false);
 },
 UnselectRows: function(visibleIndices){
  this.SelectRows(visibleIndices, false);
 },
 UnselectFilteredRows: function() {
  this.UnselectFilteredItemsCore();
 },
 SelectRowOnPage: function(visibleIndex, selected){
  if(!ASPx.IsExists(selected)) selected = true;
  this.SelectItem(visibleIndex, selected);
 },
 UnselectRowOnPage: function(visibleIndex){
  this.SelectRowOnPage(visibleIndex, false);
 },
 SelectAllRowsOnPage: function(selected){
  if(!ASPx.IsExists(selected)) selected = true;
  this._selectAllRowsOnPage(selected);
 },
 UnselectAllRowsOnPage: function(){
  this._selectAllRowsOnPage(false);
 },
 GetSelectedRowCount: function() {
  return this._getSelectedRowCount();
 },
 IsRowSelectedOnPage: function(visibleIndex) {
  return this._isRowSelected(visibleIndex);
 },
 IsGroupRow: function(visibleIndex) {
  return this.GetGroupRow(visibleIndex) != null;
 },
 IsDataRow: function(visibleIndex) {
  return this.GetDataRow(visibleIndex) != null || this.GetBandedDataRows(visibleIndex).length > 0;
 },
 IsGroupRowExpanded: function(visibleIndex) { 
  return this.GetExpandedGroupRow(visibleIndex) != null;
 },
 GetVertScrollPos: function() {
  return this.GetVerticalScrollPosition();
 },
 GetVerticalScrollPosition: function() {
  if(this.IsVirtualScrolling())
   return 0;
  var scrollHelper = this.GetScrollHelper();
  if(scrollHelper)
   return scrollHelper.GetVertScrollPosition();
  return 0;
 },
 GetHorzScrollPos: function() {
  return this.GetHorizontalScrollPosition();
 },
 GetHorizontalScrollPosition: function() {
  var scrollHelper = this.GetScrollHelper();
  if(scrollHelper)
   return scrollHelper.GetHorzScrollPosition();
  return 0;
 },
 SetVertScrollPos: function(value) {
  this.SetVerticalScrollPosition(value);
 },
 SetVerticalScrollPosition: function(value) {
  if(this.IsVirtualScrolling())
   return;
  var scrollHelper = this.GetScrollHelper();
  if(scrollHelper)
   scrollHelper.SetVertScrollPosition(value);
 },
 SetHorzScrollPos: function(value) {
  this.SetHorizontalScrollPosition(value);
 },
 SetHorizontalScrollPosition: function(value) {
  var scrollHelper = this.GetScrollHelper();
  if(scrollHelper)
   scrollHelper.SetHorzScrollPosition(value);
 },
 RaiseColumnGrouping: function(column) {
  if(!this.ColumnGrouping.IsEmpty()){
   var args = new ASPxClientGridViewColumnCancelEventArgs(column);
   this.ColumnGrouping.FireEvent(this, args);
   return args.cancel;
  }
  return false; 
 },
 RaiseItemClick: function(visibleIndex, htmlEvent) {
  if(!this.RowClick.IsEmpty()){
   var args = new ASPxClientGridViewRowClickEventArgs(visibleIndex, htmlEvent);
   this.RowClick.FireEvent(this, args);
   return args.cancel;
  }
  return false; 
 },
 RaiseItemDblClick: function(visibleIndex, htmlEvent) {
  if(!this.RowDblClick.IsEmpty()){
   ASPx.Selection.Clear(); 
   var args = new ASPxClientGridViewRowClickEventArgs(visibleIndex, htmlEvent);
   this.RowDblClick.FireEvent(this, args);
   return args.cancel;
  }
  return false; 
 },
 RaiseContextMenu: function(objectType, index, htmlEvent, menu, showBrowserMenu) {
  var args = new ASPxClientGridViewContextMenuEventArgs(objectType, index, htmlEvent, menu, showBrowserMenu);
  if(!this.ContextMenu.IsEmpty())
   this.ContextMenu.FireEvent(this, args);
  return !!args.showBrowserMenu;
 },
 RaiseFocusedItemChanged: function(){
  if(!this.FocusedRowChanged.IsEmpty()){
   var args = new ASPxClientProcessingModeEventArgs(false);
   this.FocusedRowChanged.FireEvent(this, args);
   if(args.processOnServer)
    this.gridCallBack([ASPxClientGridViewCallbackCommand.FocusedRow]);
  }
  return false; 
 },
 RaiseColumnStartDragging: function(column) {
  if(!this.ColumnStartDragging.IsEmpty()){
   var args = new ASPxClientGridViewColumnCancelEventArgs(column);
   this.ColumnStartDragging.FireEvent(this, args);
   return args.cancel;
  }
  return false; 
 },
 RaiseColumnResizing: function(column) {
  if(!this.ColumnResizing.IsEmpty()){
   var args = new ASPxClientGridViewColumnCancelEventArgs(column);
   this.ColumnResizing.FireEvent(this, args);
   return args.cancel;
  }
  return false; 
 },
 RaiseColumnResized: function(column) {
  if(!this.ColumnResized.IsEmpty()){
   var args = new ASPxClientGridViewColumnProcessingModeEventArgs(column);
   this.ColumnResized.FireEvent(this, args);
   if(args.processOnServer)
    this.Refresh();
  }
 },
 RaiseRowExpanding: function(visibleIndex) {
  if(!this.RowExpanding.IsEmpty()){
   var args = new ASPxClientGridViewRowCancelEventArgs(visibleIndex);
   this.RowExpanding.FireEvent(this, args);
   return args.cancel;
  }
  return false; 
 },
 RaiseRowCollapsing: function(visibleIndex) {
  if(!this.RowCollapsing.IsEmpty()){
   var args = new ASPxClientGridViewRowCancelEventArgs(visibleIndex);
   this.RowCollapsing.FireEvent(this, args);
   return args.cancel;
  }
  return false; 
 },
 RaiseDetailRowExpanding: function(visibleIndex) {
  if(!this.DetailRowExpanding.IsEmpty()){
   var args = new ASPxClientGridViewRowCancelEventArgs(visibleIndex);
   this.DetailRowExpanding.FireEvent(this, args);
   return args.cancel;
  }
  return false; 
 },
 RaiseDetailRowCollapsing: function(visibleIndex) {
  if(!this.DetailRowCollapsing.IsEmpty()){
   var args = new ASPxClientGridViewRowCancelEventArgs(visibleIndex);
   this.DetailRowCollapsing.FireEvent(this, args);
   return args.cancel;
  }
  return false; 
 },
 RaiseBatchEditConfirmShowing: function(requestTriggerID) {
  if(!this.BatchEditConfirmShowing.IsEmpty()) {
   var args = new ASPxClientGridViewBatchEditConfirmShowingEventArgs(requestTriggerID);
   this.BatchEditConfirmShowing.FireEvent(this, args);
   return args.cancel;
  }
  return false;
 },
 RaiseBatchEditStartEditing: function(visibleIndex, column, rowValues) {
  var args = new ASPxClientGridViewBatchEditStartEditingEventArgs(visibleIndex, column, rowValues);
  if(!this.BatchEditStartEditing.IsEmpty())
   this.BatchEditStartEditing.FireEvent(this, args);
  return args;
 },
 RaiseBatchEditEndEditing: function(visibleIndex, rowValues) {
  var args = new ASPxClientGridViewBatchEditEndEditingEventArgs(visibleIndex, rowValues);
  if(!this.BatchEditEndEditing.IsEmpty())
   this.BatchEditEndEditing.FireEvent(this, args);
  return args;
 },
 RaiseBatchEditItemValidating: function(visibleIndex, validationInfo) {
  var args = new ASPxClientGridViewBatchEditRowValidatingEventArgs(visibleIndex, validationInfo);
  if(!this.BatchEditRowValidating.IsEmpty())
   this.BatchEditRowValidating.FireEvent(this, args);
  return args.validationInfo;
 },
 RaiseBatchEditTemplateCellFocused: function(columnIndex) {
  var column = this._getColumn(columnIndex);
  if(!column) return false;
  var args = new ASPxClientGridViewBatchEditTemplateCellFocusedEventArgs(column);
  if(!this.BatchEditTemplateCellFocused.IsEmpty())
   this.BatchEditTemplateCellFocused.FireEvent(this, args);
  return args.handled;
 },
 RaiseBatchEditChangesSaving: function(valuesInfo) { 
  if(!this.BatchEditChangesSaving.IsEmpty()){
   var args = new ASPxClientGridViewBatchEditChangesSavingEventArgs(valuesInfo.insertedValues, valuesInfo.deletedValues, valuesInfo.updatedValues);
   this.BatchEditChangesSaving.FireEvent(this, args);
   return args.cancel;
  }
  return false; 
 },
 RaiseBatchEditChangesCanceling: function(valuesInfo) { 
  if(!this.BatchEditChangesCanceling.IsEmpty()){
   var args = new ASPxClientGridViewBatchEditChangesCancelingEventArgs(valuesInfo.insertedValues, valuesInfo.deletedValues, valuesInfo.updatedValues);
   this.BatchEditChangesCanceling.FireEvent(this, args);
   return args.cancel;
  }
  return false; 
 },
 RaiseBatchEditItemInserting: function(visibleIndex) { 
  if(!this.BatchEditRowInserting.IsEmpty()){
   var args = new ASPxClientGridViewBatchEditRowInsertingEventArgs(visibleIndex);
   this.BatchEditRowInserting.FireEvent(this, args);
   return args.cancel;
  }
  return false; 
 },
 RaiseBatchEditItemDeleting: function(visibleIndex, itemValues) { 
  if(!this.BatchEditRowDeleting.IsEmpty()){
   var args = new ASPxClientGridViewBatchEditRowDeletingEventArgs(visibleIndex, itemValues);
   this.BatchEditRowDeleting.FireEvent(this, args);
   return args.cancel;
  }
  return false; 
 },
 RaiseContextMenuItemClick: function(e, itemInfo) {
  if(this.ContextMenuItemClick.IsEmpty())
   return false;
  var args = new ASPxClientGridViewContextMenuItemClickEventArgs(e.item, itemInfo.objectType, itemInfo.index);
  this.ContextMenuItemClick.FireEvent(this, args);
  if(!args.handled && args.processOnServer) {
   this.ProcessCustomContextMenuItemClick(e.item, args.usePostBack);
   return true;
  }
  return args.handled;
 },
 RaiseColumnMoving: function(targets) {
  if(this.ColumnMoving.IsEmpty()) return;
  var srcColumn = this.getColumnObject(targets.obj.id);
  var destColumn = this.getColumnObject(targets.targetElement.id);
  var isLeft = targets.isLeftPartOfElement();
  var isGroupPanel = targets.targetElement == targets.grid.GetGroupPanel();
  var args = new ASPxClientGridViewColumnMovingEventArgs(srcColumn, destColumn, isLeft, isGroupPanel);
  this.ColumnMoving.FireEvent(this, args);
  if(!args.allow)
   targets.targetElement = null;
 },
 CreateCommandCustomButtonEventArgs: function(index, id){
  return new ASPxClientGridViewCustomButtonEventArgs(index, id);
 },
 CreateSelectionEventArgs: function(visibleIndex, isSelected, isAllRecordsOnPage, isChangedOnServer){
  return new ASPxClientGridViewSelectionEventArgs(visibleIndex, isSelected, isAllRecordsOnPage, isChangedOnServer);
 },
 CreateColumnCancelEventArgs: function(column){
  return new ASPxClientGridViewColumnCancelEventArgs(column);
 },
 CreateColumnMovingEventArgs: function(sourceColumn, destinationColumn, isDropBefore, isGroupPanel){
  return new ASPxClientGridViewColumnMovingEventArgs(sourceColumn, destinationColumn, isDropBefore, isGroupPanel);;
 },
 GetRowValues: function(visibleIndex, fieldNames, onCallBack) {
  this.GetItemValues(visibleIndex, fieldNames, onCallBack);
 },
 GetPageRowValues: function(fieldNames, onCallBack) {
  this.GetPageItemValues(fieldNames, onCallBack);
 },
 GetVisibleRowsOnPage: function() {
  return this.GetVisibleItemsOnPage();
 },
 ApplyOnClickRowFilter: function() {
  this.ApplyMultiColumnAutoFilter();
 }
});
ASPxClientGridView.Cast = ASPxClientControl.Cast;
var ASPxClientGridViewColumn = ASPx.CreateClass(ASPxClientGridColumnBase, {
 constructor: function(name, index, parentIndex, fieldName, visible, filterRowTypeKind, showFilterMenuLikeItem,
  allowGroup, allowSort, allowDrag, HFCheckedList, inCustWindow, minWidth, columnType){
  this.constructor.prototype.constructor.call(this, name, index, fieldName, visible, allowSort, HFCheckedList);
  this.parentIndex = parentIndex;
  this.filterRowTypeKind = filterRowTypeKind;
  this.showFilterMenuLikeItem = !!showFilterMenuLikeItem;
  this.allowGroup = !!allowGroup;
  this.allowDrag = !!allowDrag;
  this.inCustWindow = !!inCustWindow;
  this.minWidth = minWidth;
  this.columnType = columnType;
  this.isCommandColumn = this.columnType == GridViewColumnType.Command;
  this.isPureBand = this.columnType == GridViewColumnType.Band;
 }
});
var ASPxClientGridViewColumnCancelEventArgs = ASPx.CreateClass(ASPxClientCancelEventArgs, {
 constructor: function(column){
  this.constructor.prototype.constructor.call(this);
  this.column = column;
 }
});
var ASPxClientGridViewColumnProcessingModeEventArgs = ASPx.CreateClass(ASPxClientProcessingModeEventArgs, {
 constructor: function(column){
  this.constructor.prototype.constructor.call(this, false);
  this.column = column;
 }
});
var ASPxClientGridViewRowCancelEventArgs = ASPx.CreateClass(ASPxClientCancelEventArgs, {
 constructor: function(visibleIndex){
  this.constructor.prototype.constructor.call(this);
  this.visibleIndex = visibleIndex;
 }
});
var ASPxClientGridViewSelectionEventArgs = ASPx.CreateClass(ASPxClientProcessingModeEventArgs, {
 constructor: function(visibleIndex, isSelected, isAllRecordsOnPage, isChangedOnServer){
  this.constructor.prototype.constructor.call(this, false);
  this.visibleIndex = visibleIndex;
  this.isSelected = isSelected;
  this.isAllRecordsOnPage = isAllRecordsOnPage;
  this.isChangedOnServer = isChangedOnServer;
 }
});
var ASPxClientGridViewRowClickEventArgs = ASPx.CreateClass(ASPxClientGridViewRowCancelEventArgs, {
 constructor: function(visibleIndex, htmlEvent){
  this.constructor.prototype.constructor.call(this, visibleIndex);
  this.htmlEvent = htmlEvent;
 }
});
var ASPxClientGridViewContextMenuEventArgs = ASPx.CreateClass(ASPxClientEventArgs, {
 constructor: function(objectType, index, htmlEvent, menu, showBrowserMenu) {
  this.constructor.prototype.constructor.call(this);
  this.objectType = objectType;
  this.index = index;
  this.htmlEvent = htmlEvent;
  this.menu = menu;
  this.showBrowserMenu = showBrowserMenu;
 }
});
var ASPxClientGridViewContextMenuItemClickEventArgs = ASPx.CreateClass(ASPxClientProcessingModeEventArgs, {
 constructor: function(item, objectType, elementIndex, processOnServer){
  this.constructor.prototype.constructor.call(this, processOnServer);
  this.item = item;
  this.objectType = objectType;
  this.elementIndex = elementIndex;
  this.usePostBack = false;
  this.handled = false;
 }
});
var ASPxClientGridViewCustomButtonEventArgs = ASPx.CreateClass(ASPxClientProcessingModeEventArgs, {
 constructor: function(visibleIndex, buttonID) {
  this.constructor.prototype.constructor.call(this, false);
  this.visibleIndex = visibleIndex;
  this.buttonID = buttonID;
 } 
});
var ASPxClientGridViewColumnMovingEventArgs = ASPx.CreateClass(ASPxClientEventArgs, {
 constructor: function(sourceColumn, destinationColumn, isDropBefore, isGroupPanel) {
  this.constructor.prototype.constructor.call(this);
  this.allow = true;
  this.sourceColumn = sourceColumn;
  this.destinationColumn = destinationColumn;
  this.isDropBefore = isDropBefore;
  this.isGroupPanel = isGroupPanel;
 }
});
var ASPxClientGridViewBatchEditConfirmShowingEventArgs = ASPx.CreateClass(ASPxClientGridBatchEditConfirmShowingEventArgs, {
 constructor: function(requestTriggerID) {
  this.constructor.prototype.constructor.call(this, requestTriggerID);
 }
});
var ASPxClientGridViewBatchEditStartEditingEventArgs = ASPx.CreateClass(ASPxClientGridBatchEditStartEditingEventArgs, {
 constructor: function(visibleIndex, focusedColumn, itemValues) {
  this.constructor.prototype.constructor.call(this, visibleIndex, focusedColumn, itemValues);
  this.rowValues = this.itemValues;
 }
});
var ASPxClientGridViewBatchEditEndEditingEventArgs = ASPx.CreateClass(ASPxClientGridBatchEditEndEditingEventArgs, {
 constructor: function(visibleIndex, itemValues) {
  this.constructor.prototype.constructor.call(this, visibleIndex, itemValues);
  this.rowValues = this.itemValues;
 }
});
var ASPxClientGridViewBatchEditRowValidatingEventArgs = ASPx.CreateClass(ASPxClientGridBatchEditItemValidatingEventArgs, {
 constructor: function(visibleIndex, validationInfo) {
  this.constructor.prototype.constructor.call(this, visibleIndex, validationInfo);
 }
});
var ASPxClientGridViewBatchEditTemplateCellFocusedEventArgs = ASPx.CreateClass(ASPxClientGridBatchEditTemplateCellFocusedEventArgs, {
 constructor: function(column) {
  this.constructor.prototype.constructor.call(this, column);
 }
});
var ASPxClientGridViewBatchEditChangesSavingEventArgs = ASPx.CreateClass(ASPxClientGridBatchEditClientChangesEventArgs, {
 constructor: function(insertedValues, deletedValues, updatedValues) {
  this.constructor.prototype.constructor.call(this, insertedValues, deletedValues, updatedValues);
 }
});
var ASPxClientGridViewBatchEditChangesCancelingEventArgs = ASPx.CreateClass(ASPxClientGridBatchEditClientChangesEventArgs, {
 constructor: function(insertedValues, deletedValues, updatedValues) {
  this.constructor.prototype.constructor.call(this, insertedValues, deletedValues, updatedValues);
 }
});
var ASPxClientGridViewBatchEditRowInsertingEventArgs = ASPx.CreateClass(ASPxClientGridBatchEditItemInsertingEventArgs, {
 constructor: function(visibleIndex) {
  this.constructor.prototype.constructor.call(this, visibleIndex);
 }
});
var ASPxClientGridViewBatchEditRowDeletingEventArgs = ASPx.CreateClass(ASPxClientGridBatchEditItemDeletingEventArgs, {
 constructor: function(visibleIndex, itemValues) {
  this.constructor.prototype.constructor.call(this, visibleIndex, itemValues);  
  this.rowValues = this.itemValues;  
 }
});
var ASPxClientGridViewCellInfo = ASPx.CreateClass(ASPxClientGridCellInfo, {
 constructor: function(visibleIndex, column) {
  this.constructor.prototype.constructor.call(this, visibleIndex, column);
  this.rowVisibleIndex = this.itemVisibleIndex;
 }
});
ASPx.GVContextMenu = function(name, e) {
 var gv = ASPx.GetControlCollection().Get(name);
 if(gv != null) {
  var showDefaultMenu = gv.OnContextMenuClick(e);
  return showDefaultMenu;
  }
 return true;
}
ASPx.GVContextMenuItemClick = function(name, e) {
 var gv = ASPx.GetControlCollection().Get(name);
 if(gv != null)
  gv.OnContextMenuItemClick(e);
}
ASPx.GVExpandRow = function(name, visibleIndex, event) {
 var gv = ASPx.GetControlCollection().Get(name);
 if(gv != null) {
  if(gv.useEndlessPaging && event)
   visibleIndex = gv.FindParentRowVisibleIndex(ASPx.Evt.GetEventSource(event), true);
  gv.ExpandRow(visibleIndex);
 }
}
ASPx.GVCollapseRow = function(name, visibleIndex, event) {
 var gv = ASPx.GetControlCollection().Get(name);
 if(gv != null) {
  if(gv.useEndlessPaging && event)
   visibleIndex = gv.FindParentRowVisibleIndex(ASPx.Evt.GetEventSource(event), true);
  gv.CollapseRow(visibleIndex);
 }
}
ASPx.GVShowDetailRow = function(name, visibleIndex, event) {
 var gv = ASPx.GetControlCollection().Get(name);
 if(gv != null) {
  if(gv.useEndlessPaging && event)
   visibleIndex = gv.FindParentRowVisibleIndex(ASPx.Evt.GetEventSource(event), true);
  gv.ExpandDetailRow(visibleIndex);
 }
}
ASPx.GVHideDetailRow = function(name, visibleIndex, event) {
 var gv = ASPx.GetControlCollection().Get(name);
 if(gv != null) {
  if(gv.useEndlessPaging && event)
   visibleIndex = gv.FindParentRowVisibleIndex(ASPx.Evt.GetEventSource(event), true);
  gv.CollapseDetailRow(visibleIndex);
 }
}
ASPx.Evt.AttachEventToElement(window, "scroll", function(evt) {
 ASPx.GetControlCollection().ForEachControl(function(control){
  if(control instanceof ASPxClientGridView && ASPx.IsExists(control.GetMainElement()))
   control.OnScroll(evt);
 });
});
var GridViewKbdHelper = ASPx.CreateClass(ASPx.KbdHelper, {
  CanFocus: function(e) {
  var grid = this.control;
  var batchEditHelper = grid.GetBatchEditHelper();
  if(batchEditHelper && batchEditHelper.CanStartEditOnTableClick(e))
   return false;
  return ASPx.KbdHelper.prototype.CanFocus(e);
 },
 HandleKeyDown: function(e) {
  var grid = this.control;
  var index = grid.GetFocusedRowIndex();
  var busy = grid.keyboardLock;
  var key = ASPx.Evt.GetKeyCode(e);
  if(grid.rtl) {
   if(key == ASPx.Key.Left)
    key = ASPx.Key.Right;
   else if(key == ASPx.Key.Right)
    key = ASPx.Key.Left;
  }
  switch(key) {
   case ASPx.Key.Down:
    if(!busy) 
     this.TryMoveFocusDown(index, e.shiftKey);
    return true;
   case ASPx.Key.Up:
    if(!busy) 
     this.TryMoveFocusUp(index, e.shiftKey);
    return true;
   case ASPx.Key.Right:
    if(!busy) {
     if(!this.TryExpand(index))
      this.TryMoveFocusDown(index, e.shiftKey);
    }
    return true;
   case ASPx.Key.Left:
    if(!busy) {
     if(!this.TryCollapse(index))
      this.TryMoveFocusUp(index, e.shiftKey);
    }
    return true;
   case ASPx.Key.PageDown:
    if(e.shiftKey) {
     if(!busy && grid.pageIndex < grid.pageCount - 1)
      grid.NextPage();
     return true; 
    }
    break;
   case ASPx.Key.PageUp:
    if(e.shiftKey) {
     if(!busy && grid.pageIndex > 0)
      grid.PrevPage();
     return true; 
    }
    break;     
  }
  return false;
 },
 HandleKeyPress: function(e) {
  var grid = this.control;
  var index = grid.GetFocusedRowIndex();
  var busy = grid.keyboardLock;
  switch(ASPx.Evt.GetKeyCode(e)) {
   case ASPx.Key.Space:
    if(!busy && this.IsRowSelectable(index))
     grid.IsRowSelectedOnPage(index) ? grid.UnselectRowOnPage(index) : grid.SelectRowOnPage(index);
    return true;
    case 43:
    if(!busy)
     this.TryExpand(index);
    return true;
    case 45: 
    if(!busy)   
     this.TryCollapse(index);    
    return true;
  }
  return false;
 },
 EnsureFocusedRowVisible: function() {
  var grid = this.control;
  if(!grid.HasVertScroll()) return;
  var row = grid.GetItem(grid.GetFocusedRowIndex());
  grid.GetScrollHelper().MakeRowVisible(row, true);
 },
 HasDetailButton: function(expanded) {
  var grid = this.control;
  var row = grid.GetItem(grid.GetFocusedRowIndex());
  if(!row) return;
  var needle = expanded ? "ASPx.GVHideDetailRow" : "ASPx.GVShowDetailRow";
  return row.innerHTML.indexOf(needle) > -1;
 },
 IsRowSelectable: function(index) {
  if(this.control.allowSelectByItemClick)
   return true;
  var row = this.control.GetItem(index);
  if(row && row.innerHTML.indexOf("aspxGVSelectRow") > -1)
   return true;
  var check = this.control.GetDataRowSelBtn(index); 
  if(check && this.control.internalCheckBoxCollection && !!this.control.internalCheckBoxCollection.Get(check.id))
   return true;
  return false;
 },
 UpdateShiftSelection: function(start, end) {
  var grid = this.control;
  grid.UnselectAllRowsOnPage();
  if(grid.lastMultiSelectIndex > -1)   
   start = grid.lastMultiSelectIndex;
  else   
   grid.lastMultiSelectIndex = start;
  for(var i = Math.min(start, end); i <= Math.max(start, end); i++)
   grid.SelectRowOnPage(i);
 },
 TryExpand: function(index) {
  var grid = this.control;
  if(grid.IsGroupRow(index) && !grid.IsGroupRowExpanded(index)) {
   grid.ExpandRow(index);
   return true;
  }
  if(this.HasDetailButton(false)) {
   grid.ExpandDetailRow(index);
   return true;
  }
  return false;
 },
 TryCollapse: function(index) {
  var grid = this.control;
  if(grid.IsGroupRow(index) && grid.IsGroupRowExpanded(index)) {
   grid.CollapseRow(index);
   return true;
  }
  if(this.HasDetailButton(true)) {
   grid.CollapseDetailRow(index);
   return true;
  }
  return false;
 },
 TryMoveFocusDown: function(index, select) {
  var grid = this.control;
  if(index < grid.visibleStartIndex + grid.pageRowCount - 1) {
   if(index < 0) 
    grid.SetFocusedRowIndex(grid.visibleStartIndex);
    else
    grid.SetFocusedRowIndex(index + 1);
   this.EnsureFocusedRowVisible();
   if(this.IsRowSelectable(index)) {
    if(select) {
     this.UpdateShiftSelection(index, index + 1);
    } else {
     grid.lastMultiSelectIndex = -1;
    }
   }
  } else {
   if(grid.pageIndex < grid.pageCount - 1 && grid.pageIndex >= 0) {       
    grid.NextPage();
   }
  }  
 },
 TryMoveFocusUp: function(index, select) {
  var grid = this.control;
  if(index > grid.visibleStartIndex || index == -1) {
   if(index < 0) 
    grid.SetFocusedRowIndex(grid.visibleStartIndex + grid.pageRowCount - 1);
   else
    grid.SetFocusedRowIndex(index - 1);
   this.EnsureFocusedRowVisible();
   if(this.IsRowSelectable(index)) {
    if(select) {
     this.UpdateShiftSelection(index, index - 1);
    } else {
     grid.lastMultiSelectIndex = -1;
    }
   }
  } else {
   if(grid.pageIndex > 0) {
    grid.PrevPage(true);
   }
  }
 }
});
var GridViewHeaderMatrix = ASPx.CreateClass(null, {
 constructor: function(grid) {
  this.grid = grid;
 },
 Invalidate: function() {
  this.matrix = null;
  this.inverseMatrix = null;
 },
 GetRowCount: function() {
  this.EnsureMatrix();
  return this.matrix.length;
 },
 IsLeftmostColumn: function(columnIndex) {
  this.EnsureMatrix();
  return this.inverseMatrix[columnIndex].left == 0;
 },
 IsRightmostColumn: function(columnIndex) {
  this.EnsureMatrix();  
  return this.inverseMatrix[columnIndex].right == this.matrix[0].length - 1;
 },
 IsLeaf: function(columnIndex) {
  this.EnsureMatrix();
  return this.inverseMatrix.hasOwnProperty(columnIndex) && this.inverseMatrix[columnIndex].bottom == this.matrix.length - 1;
 },
 GetLeaf: function(columnIndex, isLeft, isOuter) {
  this.EnsureMatrix();
  var rect = this.inverseMatrix[columnIndex];
  var row = this.matrix[this.matrix.length - 1];
  if(isLeft) {
   if(isOuter)
    return row[rect.left - 1];
   return row[rect.left];
  }
  if(isOuter)
   return row[rect.right + 1];
  return row[rect.right];
 },
 GetLeafIndex: function(columnIndex) {
  this.EnsureMatrix();
  return this.inverseMatrix[columnIndex].left;
 },
 GetLeafIndices: function() {
  return this.GetRowIndices(this.GetRowCount() - 1);
 },
 GetRowIndices: function(rowIndex) {
  this.EnsureMatrix();
  return this.matrix[rowIndex] || [];
 },
 GetRowSpan: function(columnIndex) {
  this.EnsureMatrix();
  var rect = this.inverseMatrix[columnIndex];
  return rect.bottom - rect.top + 1;
 },
 GetLeftNeighbor: function(columnIndex, skipHiddenColumns) {
  this.EnsureMatrix();
  if(!skipHiddenColumns)
   return this.GetLeftNeighborCore(columnIndex);
  while(columnIndex !== this.GetFirstColumnIndex()) {
   columnIndex = this.GetLeftNeighborCore(columnIndex);
   if(isNaN(columnIndex) || !this.grid.GetColumn(columnIndex).adaptiveHidden)
    return columnIndex;
  }
 },
 GetLeftNeighborCore: function(columnIndex) {
  var rect = this.inverseMatrix[columnIndex];
  return this.matrix[rect.top][rect.left - 1];
 },
 GetRightNeighbor: function(columnIndex, skipHiddenColumns) {
  this.EnsureMatrix();
  if(!skipHiddenColumns)
   return this.GetRightNeighborCore(columnIndex);
  while(columnIndex !== this.GetLastColumnIndex()) {
   columnIndex = this.GetRightNeighborCore(columnIndex);
   if(isNaN(columnIndex) || !this.grid.GetColumn(columnIndex).adaptiveHidden)
    return columnIndex;
  }
 },
 GetRightNeighborCore: function(columnIndex) {
  var rect = this.inverseMatrix[columnIndex];
  return this.matrix[rect.top][rect.right + 1];
 },
 GetLastColumnIndex: function(){
  var leafs = this.GetLeafIndices();
  return leafs[leafs.length - 1];
 },
 GetFirstColumnIndex: function(){
  var leafs = this.GetLeafIndices();
  return leafs[0];
 },
 GetRightNeighborLeaf: function(columnIndex) {
  return this.GetLeaf(columnIndex, false, true);
 },
 GetColumnLevel: function(columnIndex) {
  this.EnsureMatrix();
  var rect = this.inverseMatrix[columnIndex];
  return rect ? rect.top : -1;
 },
 EnsureMatrix: function() {
  this.matrix || this.Fill();
 },
 Fill: function() {
  this.matrix = [ ];
  this.inverseMatrix = { };
  var rowIndex = 0;
  while(true) {
   var row = this.grid.GetHeaderRow(rowIndex);
   if(!row)
    break;
   var lastFreeIndex = 0;
   for(var cellIndex = !rowIndex ? this.grid.indentColumnCount : 0; cellIndex < row.cells.length; cellIndex++) {
    var cell = row.cells[cellIndex];
    var columnIndex = this.grid.getColumnIndex(cell.id);
    if(columnIndex < 0)
     break;
    lastFreeIndex = this.FindFreeCellIndex(rowIndex, lastFreeIndex);
    this.FillBlock(rowIndex, lastFreeIndex, cell.rowSpan, cell.colSpan, columnIndex);
    lastFreeIndex += cell.colSpan;
   }
   ++rowIndex;
  }
 },
 FindFreeCellIndex: function(rowIndex, lastFreeCell) {
  var row = this.matrix[rowIndex];
  var result = lastFreeCell;
  if(row) {
   while(!isNaN(row[result]))
    result++;
  } 
  return result;
 },
 FillBlock: function(rowIndex, cellIndex, rowSpan, colSpan, columnIndex) {
  var rect = {
   top: rowIndex,
   bottom: rowIndex + rowSpan - 1,
   left: cellIndex,
   right: cellIndex + colSpan - 1
  };
  for(var i = rect.top; i <= rect.bottom; i++) {
   while(!this.matrix[i])
    this.matrix.push([]);
   for(var j = rect.left; j <= rect.right; j++)
    this.matrix[i][j] = columnIndex;
  }
  this.inverseMatrix[columnIndex] = rect;
 }
});
var GridViewRowsDefaultLayout = ASPx.CreateClass(null, {
 constructor: function(grid) {
  this.grid = grid;
 },
 Invalidate: function() { },
 IsMergedCell: function(columnIndex, visibleIndex){ return false; },
 GetLevelsCount: function() { return 1; },
 GetParentColumnIndices: function(columnIndex) { return []; },
 GetDataCellLevel: function(columnIndex) { return -1 },
 GetDataCellIndex: function(columnIndex, visibleIndex){
  return ASPx.Data.ArrayIndexOf(this.GetVisibleColumnIndices(), columnIndex) + this.GetIndentColumnCount();
 },
 GetColumnIndex: function(cellIndex, visibleIndex, level){
  cellIndex -= this.GetIndentColumnCount();
  var columnIndices = this.GetVisibleColumnIndices();
  if(cellIndex < 0 || cellIndex >= columnIndices.length) 
   return -1;
  return columnIndices[cellIndex];
 },
 GetVisibleColumnIndices: function() {
  var headerMatrix = this.GetHeaderMatrix();
  if(headerMatrix.GetRowCount() > 0)
   return headerMatrix.GetLeafIndices();
  return this.GetRowsLayoutInfo().visibleColumnIndices || [];
 },
 IsLoneRightColumn: function(columnIndex){
  var indices = this.GetVisibleColumnIndices();
  return indices.length > 0 && columnIndex === indices[indices.length - 1];
 },
 GetIndentColumnCount: function() { return this.grid.indentColumnCount; },
 GetHeaderMatrix: function() { return this.grid.GetHeaderMatrix(); },
 GetRowsLayoutInfo: function() { return this.grid.rowsLayoutInfo; }
});
var GridViewBandedRowsLayout = ASPx.CreateClass(GridViewRowsDefaultLayout, {
 constructor: function(grid){
  this.constructor.prototype.constructor.call(this, grid);
 },
 GetAllInfoItems: function(){
  return ASPx.Data.ArrayFlattern(this.GetBandedCellInfo());
 }, 
 GetColumnIndex: function(cellIndex, visibleIndex, level) {
  cellIndex -= this.GetIndentColumnCount();
  var rowColumnIndeces = this.GetColumnIndices(level);
  return rowColumnIndeces && cellIndex < rowColumnIndeces.length ? rowColumnIndeces[cellIndex] : -1;
 },
 GetColumnIndices: function(level) {
  var infoItems = this.GetBandedCellInfo()[level];
  return this.GetColumnIndicesFromLayoutItems(infoItems);
 },
 GetVisibleColumnIndices: function() {
  var infoItems = this.GetAllInfoItems();
  return this.GetColumnIndicesFromLayoutItems(infoItems);
 },
 GetColumnIndicesFromLayoutItems:  function(items){
  return items.map(function(item) { return item.columnIndex; });
 },
 GetDataCellLevel: function(columnIndex) {
  var levelsCount = this.GetLevelsCount();
  for(var i = 0; i < levelsCount; i++) {
   if(this.GetColumnIndices(i).indexOf(columnIndex) > -1)
    return i;
  }
  return -1;
 },
 GetDataCellIndex: function(columnIndex, visibleIndex){
  var level = this.GetDataCellLevel(columnIndex);
  if(level < 0)
   return -1;
  return this.GetColumnIndices(level).indexOf(columnIndex);
 },
 GetLevelsCount: function() {
  return this.GetBandedCellInfo().length;
 },
 GetParentColumnIndex: function(columnIndex) {
  var infoItems = this.GetAllInfoItems();
  var infoItem = infoItems.filter(function(item) { return item.columnIndex === columnIndex })[0];
  if(infoItem && infoItem.parent >= 0)
   return infoItem.parent;
  return null;
 },
 GetParentColumnIndices: function(columnIndex) {
  var result = [];
  var parentIndex = columnIndex;
  while(parentIndex = this.GetParentColumnIndex(parentIndex)) {
   result.push(parentIndex);
  }
  return result;
 },
 IsLoneRightColumn: function(columnIndex){ return false; },
 GetBandedCellInfo: function() { return this.GetRowsLayoutInfo().bandedCellInfo; }
});
var GridViewRowsCellMergingLayout = ASPx.CreateClass(GridViewRowsDefaultLayout, {
 constructor: function(grid){
  this.rowsSpanLayout = null;
  this.constructor.prototype.constructor.call(this, grid);
 },
 Invalidate: function(){
  this.rowsSpanLayout = null;
 },
 IsMergedCell: function(columnIndex, visibleIndex){
  this.EnsureLayout();
  var columnPosition = ASPx.Data.ArrayIndexOf(this.GetVisibleColumnIndices(), columnIndex);
  return this.rowsSpanLayout[visibleIndex - this.GetVisibleStartIndex()][columnPosition] > 1;
 },
 GetDataCellIndex: function(columnIndex, visibleIndex){
  this.EnsureLayout();
  var columnIndices = this.GetVisibleColumnIndices();
  var prevMergedCellsCount = this.GetHiddenPreviousCellCount(columnIndices.indexOf(columnIndex), visibleIndex);
  return GridViewRowsDefaultLayout.prototype.GetDataCellIndex.call(this, columnIndex, visibleIndex) - prevMergedCellsCount;
 },
 GetColumnIndex: function(cellIndex, visibleIndex) {
  cellIndex -= this.GetIndentColumnCount();
  var columnIndices = this.GetVisibleColumnIndices();
  if(cellIndex < 0 || cellIndex >= columnIndices.length) 
   return -1;
  this.EnsureLayout();
  cellIndex += this.GetHiddenPreviousCellCount(cellIndex + 1, visibleIndex);
  return columnIndices[cellIndex];
 },
 IsCellRendered: function(cellIndex, visibleIndex){
  var layoutRowIndex = visibleIndex - this.GetVisibleStartIndex();
  if(layoutRowIndex == 0 || !this.rowsSpanLayout[layoutRowIndex] || !this.rowsSpanLayout[layoutRowIndex - 1])
   return true;
  return this.rowsSpanLayout[layoutRowIndex][cellIndex] != this.rowsSpanLayout[layoutRowIndex - 1][cellIndex] - 1;
 },
 EnsureLayout: function(){
  if(this.rowsSpanLayout)
   return;
  this.rowsSpanLayout = [ ]
  var columnsCount = this.GetVisibleColumnIndices().length;
  var rowsCount = this.GetVisibleRowsOnPage();
  for(var layoutRowIndex = 0; layoutRowIndex < rowsCount; layoutRowIndex++){
   var rowElement = this.GetDataRow(layoutRowIndex + this.GetVisibleStartIndex());
   var rowLayout = rowElement ? new Array(columnsCount) : null;
   this.rowsSpanLayout.push(rowLayout);
   var delta = 0;
   for(var i = 0; rowLayout && i < columnsCount; i++){
    rowLayout[i] = layoutRowIndex > 0 ? this.GetLayoutCellRowSpan(layoutRowIndex - 1, i) - 1 : 0;
    if(rowLayout[i] == 0){
     var cellElement = rowElement.cells[this.GetIndentColumnCount() + i - delta];
     rowLayout[i] = cellElement.rowSpan;
    } else
     delta++;
   }
  }
 },
 GetLayoutCellRowSpan: function(vi, columnPosition){
  if(!this.rowsSpanLayout || vi >= this.rowsSpanLayout.length)
   return 1;
  if(!this.rowsSpanLayout[vi] || columnPosition >= this.rowsSpanLayout[vi].length)
   return 1;
  return this.rowsSpanLayout[vi][columnPosition];
 },
 GetHiddenPreviousCellCount: function(columnPosition, visibleIndex){
  if(!ASPx.IsExists(visibleIndex) || visibleIndex < 0)
   return 0;
  var count = 0;
  for(var i = 0; i < columnPosition; i++)
   if(!this.IsCellRendered(i, visibleIndex))
    count++;
  return count;
 },
 GetVisibleStartIndex: function(){ return this.grid.visibleStartIndex },
 GetVisibleRowsOnPage: function() { return this.grid.GetVisibleItemsOnPage(); },
 GetDataRow: function(visibleIndex){ return this.grid.GetDataRow(visibleIndex); }
});
var ASPxClientGridViewBatchEditApi = ASPx.CreateClass(ASPxClientGridBatchEditApi, {
 constructor: function(grid) {
  this.constructor.prototype.constructor.call(this, grid);
 },
 ValidateRows: function() { return this.ValidateItems(); },
 ValidateRow: function(visibleIndex) { return this.ValidateItem(visibleIndex); },
 GetRowVisibleIndices: function(includeDeleted) { return this.GetItemVisibleIndices(includeDeleted); },
 GetDeletedRowIndices: function() { return this.GetDeletedItemVisibleIndices(); },
 GetInsertedRowIndices: function() { return this.GetInsertedItemVisibleIndices(); },
 IsDeletedRow: function(visibleIndex) { return this.IsDeletedItem(visibleIndex); },
 IsNewRow: function(visibleIndex) { return this.IsNewItem(visibleIndex); },
 CreateCellInfo: function(visibleIndex, column) { return new ASPxClientGridViewCellInfo(visibleIndex, column); }
});
window.ASPxClientGridView = ASPxClientGridView;
window.ASPxClientGridViewColumn = ASPxClientGridViewColumn;
window.ASPxClientGridViewColumnCancelEventArgs = ASPxClientGridViewColumnCancelEventArgs;
window.ASPxClientGridViewColumnProcessingModeEventArgs = ASPxClientGridViewColumnProcessingModeEventArgs;
window.ASPxClientGridViewRowCancelEventArgs = ASPxClientGridViewRowCancelEventArgs;
window.ASPxClientGridViewSelectionEventArgs = ASPxClientGridViewSelectionEventArgs;
window.ASPxClientGridViewRowClickEventArgs = ASPxClientGridViewRowClickEventArgs;
window.ASPxClientGridViewContextMenuEventArgs = ASPxClientGridViewContextMenuEventArgs;
window.ASPxClientGridViewContextMenuItemClickEventArgs = ASPxClientGridViewContextMenuItemClickEventArgs;
window.ASPxClientGridViewCustomButtonEventArgs = ASPxClientGridViewCustomButtonEventArgs;
window.ASPxClientGridViewColumnMovingEventArgs = ASPxClientGridViewColumnMovingEventArgs;
window.ASPxClientGridViewBatchEditConfirmShowingEventArgs = ASPxClientGridViewBatchEditConfirmShowingEventArgs;
window.ASPxClientGridViewBatchEditStartEditingEventArgs = ASPxClientGridViewBatchEditStartEditingEventArgs;
window.ASPxClientGridViewBatchEditEndEditingEventArgs = ASPxClientGridViewBatchEditEndEditingEventArgs;
window.ASPxClientGridViewBatchEditRowValidatingEventArgs = ASPxClientGridViewBatchEditRowValidatingEventArgs;
window.ASPxClientGridViewBatchEditTemplateCellFocusedEventArgs = ASPxClientGridViewBatchEditTemplateCellFocusedEventArgs;
window.ASPxClientGridViewBatchEditChangesSavingEventArgs = ASPxClientGridViewBatchEditChangesSavingEventArgs;
window.ASPxClientGridViewBatchEditChangesCancelingEventArgs = ASPxClientGridViewBatchEditChangesCancelingEventArgs;
window.ASPxClientGridViewBatchEditRowInsertingEventArgs = ASPxClientGridViewBatchEditRowInsertingEventArgs;
window.ASPxClientGridViewBatchEditRowDeletingEventArgs = ASPxClientGridViewBatchEditRowDeletingEventArgs;
ASPx.GridViewKbdHelper = GridViewKbdHelper;
ASPx.GridViewConsts = GridViewConsts;
window.ASPxClientGridViewBatchEditApi = ASPxClientGridViewBatchEditApi;
window.ASPxClientGridViewCellInfo = ASPxClientGridViewCellInfo;
})();
