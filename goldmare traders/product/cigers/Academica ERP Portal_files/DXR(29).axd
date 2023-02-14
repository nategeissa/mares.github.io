(function() {
ASPx.activeCalendar = null;
ASPx.calendarMsPerDay = 86400000;
var calendarWeekCount = 6;
var ASPxClientCalendar = ASPx.CreateClass(ASPxClientEdit, {
 constructor: function(name) {
  this.constructor.prototype.constructor.call(this, name);
  this.SelectionChanging = new ASPxClientEvent();
  this.SelectionChanged = new ASPxClientEvent();
  this.VisibleMonthChanged = new ASPxClientEvent();
  this.CustomDisabledDate = new ASPxClientEvent();
  this.isMouseDown = false;  
  this.forceMouseDown = false;
  this.supportGestures = true;
  this.swipeGestureStated = false;
  this.updateAnimationProcessing = false;
  this.selection = new ASPxClientCalendarSelection();
  this.selectionTransaction = null;  
  this.selectionStartDate = null;
  this.selectionPrevStartDate = null;
  this.lastSelectedDate = null;
  this.selectionCtrl = false;
  this.selectionByWeeks = false;  
  this.titleFormatter = null;
  this.updateAnimationLockCount = 0;
  this.forceUpdate = false;
  this.visibleDate = new Date();
  this.firstDayOfWeek = 0;    
  this.columns = 1;
  this.rows = 1;
  this.enableFast = true;
  this.enableMulti = false;
  this.customDraw = false;  
  this.showWeekNumbers = true;
  this.showDayHeaders = true;
  this.isDateEditCalendar = false;
  this.sharedParameters = new ASPx.CalendarSharedParameters();
  this.accessibilityHelper = null;
  this.sizingConfig.allowSetHeight = false;
  this.isDateChangingByKeyboard = false;
  this.MainElementClick = new ASPxClientEvent();
 },
 InitializeProperties: function(properties){
  ASPxClientEdit.prototype.InitializeProperties.call(this, properties);
  if(properties.selection)
   this.selection.AddArray(properties.selection);
  if(properties.sharedParameters)
   this.SetProperties(properties.sharedParameters, this.sharedParameters);
 },
 Initialize: function() {
  this.selectionTransaction = new ASPxClientCalendarSelectionTransaction(this);
  this.selectionPrevStartDate = this.selection.GetFirstDate();
  ASPxClientEdit.prototype.Initialize.call(this);
  var mainElement = this.GetMainElement();
  ASPx.Evt.PreventElementDragAndSelect(mainElement, false, false);
  if(ASPx.Browser.Opera)
   ASPx.Selection.SetElementAsUnselectable(mainElement, true, true);
  this.EnsureTodayStyle();
  if(this.accessibilityCompliant)
   this.accessibilityHelper = new AccessibilityHelperCalendar(this);
 },
 InlineInitialize: function() {
  this.customDraw = this.sharedParameters.calendarCustomDraw;
  this.CreateViews();
  if(this.enableFast)
   this.fastNavigation = new ASPxClientCalendarFastNavigation(this);
  this.InitSpecialKeyboardHandling();
  if(this.enableSlideCallbackAnimation && !this.enableSwipeGestures && typeof(ASPx.AnimationHelper) != "undefined")
   ASPx.AnimationHelper.getSlideAnimationContainer(this.GetCallbackAnimationElement(), true, false);
  ASPxClientEdit.prototype.InlineInitialize.call(this);
  if(!this.CustomDisabledDate.IsEmpty())
   this.Update();
 },
 EnsureTodayStyle: function() {
  if(!ASPxClientCalendar.AreDatesEqual(this.serverCurrentDate, new Date())) {
   for(var key in this.views) {
    var view = this.views[key];
    view.EnsureTodayStyle();
   }
  }
 },
 FindInputElement: function() {
  return this.accessibilityCompliant ? this.GetAccessibilityServiceElement() : this.GetChildElement("KBS");
 },
 GetAccessibilityServiceElement: function() {
  return this.GetChildElement("AcAs");
 },
 GetAccessibilityActiveElements: function() {
  return this.accessibilityCompliant ? [this.accessibilityHelper.GetActiveElement()] : [this.GetInputElement()];
 },
 GetClearButton: function() {
  return this.GetChildElement("BC");
 },
 GetTodayButton: function() {
  return this.GetChildElement("BT");
 },
 GetValue: function() {
  return this.selection.GetFirstDate();
 },
 GetValueString: function() {
  var value = this.GetValue();
  return value == null ? null : ASPx.DateUtils.GetInvariantDateString(value);
 },
 SetValue: function(date) {  
  if(date) {
   date = ASPxClientCalendarDateDisabledHelper.GetCorrectedDate(date);
   this.SetVisibleDate(date);
  }
  this.SetSelectedDate(date);
 },
 GetFastNavigation: function() {
  return this.fastNavigation;
 },    
 GetViewKey: function(row, column) {
  return row + "x" + column;
 },
 GetView: function(row, column) {
  var key = this.GetViewKey(row, column);
  return this.views[key];
 },
 CreateViews: function() {
  this.views = { };
  var key;
  for(var row = 0 ; row < this.rows; row++) {   
   for(var col = 0; col < this.columns; col++) {
    key = this.GetViewKey(row, col);
    var view = new ASPxClientCalendarView(this, row, col);
    view.Initialize();
    this.views[key] = view;
   }
  }
 },
 IsFastNavigationActive: function() {
  if(this.fastNavigation)
   return this.fastNavigation.GetPopup().IsVisible();
  return false;
 },
 IsDateSelected: function(date) {
  return this.selection.Contains(date);
 },
 IsDateVisible: function(date) {
  var startDate = ASPxClientCalendar.CloneDate(this.GetView(0, 0).visibleDate);
  startDate.setDate(1);  
  var endDate = ASPxClientCalendar.CloneDate(this.GetView(this.rows - 1, this.columns - 1).visibleDate);
  endDate.setDate(ASPxClientCalendar.GetDaysInMonth(endDate.getMonth(), endDate.getFullYear()));
  return (date >= startDate) && (date < endDate);
 },
 IsDateWeekend: function(date) {
  var day = date.getDay();
  return day == 0 || day == 6;
 },
 IsCustomDisabledDatesViaCallback: function(){
  return (this.callBack && this.IsCustomDisabledDateEventEmpty() && this.sharedParameters.disabledDates.length > 0);
 },
 HasCallback: function () {
  if (this.isDateEditCalendar)
   return this.customDraw;
  else
   return this.callBack;
 },
 IsCustomDisabledDateEventEmpty: function() {
  if(this.isDateEditCalendar)
   return ASPxClientDateEdit.active == null || ASPxClientDateEdit.active.CalendarCustomDisabledDate.IsEmpty();
  return this.CustomDisabledDate.IsEmpty();
 },
 IsDateDisabled: function(date) {
  return ASPxClientCalendarDateDisabledHelper.IsDateDisabled(this.sharedParameters, date, function(d) { return this.OnCustomDisabledDate(d); }.aspxBind(this));
 },
 IsMultiView: function() {
  return this.columns > 1 || this.rows > 1;
 },
 AddCallbackCustomDisabledDates: function(dates) {
  var callbackCustomDisabledDates = eval(dates);
  for(var i = 0; i < callbackCustomDisabledDates.length; i++) {
   var contains = false;
   var date = callbackCustomDisabledDates[i];
   for(var j = 0; j < this.sharedParameters.disabledDates.length; j++) {
    var disabledDate = this.sharedParameters.disabledDates[j];
    if(disabledDate.getDate() == date.getDate() &&
     disabledDate.getMonth() == date.getMonth() &&
     disabledDate.getFullYear() == date.getFullYear()) {
     contains = true;
     break;
    }
   }
   if(!contains)
    this.sharedParameters.disabledDates.push(date);
  }
 },
 ShowLoadingPanel: function(){
  this.CreateLoadingPanelWithAbsolutePosition(this.GetMainElement().parentNode, this.GetLoadingPanelOffsetElement(this.GetMainElement()));
 },
 ShowLoadingDiv: function () {
  this.CreateLoadingDiv(this.GetMainElement().parentNode, this.GetMainElement());
 },
 GetCallbackAnimationElement: function() {
  if(this.columns === 1 && this.rows === 1)
   return this.views[this.GetViewKey(0, 0)].GetMonthTable();
  return this.GetMainElement();
 },
 CanHandleGesture: function(evt) {
  var source = ASPx.Evt.GetEventSource(evt);
  var element = this.GetMainElement();
  if(this.columns === 1 && this.rows === 1)
   element = this.views[this.GetViewKey(0, 0)].GetMonthCell();
  return ASPx.GetIsParent(element, source);
 },
 AllowStartGesture: function() {
  return ASPxClientControl.prototype.AllowStartGesture.call(this) && (!this.enableMulti || !this.selectionTransaction.isActive) && !this.updateAnimationProcessing;
 },
 StartGesture: function() {
  this.swipeGestureStated = true;
 },
 AllowExecuteGesture: function(value) {
  return true;
 },
 ExecuteGesture: function(value, count) {
  if(!count) count = 1;
  this.OnShiftMonth((value > 0 ? -1 : 1) * count);
 },
 Update: function() {
  if(this.customDraw && !this.clientUpdate) {
   if(!this.isDateEditCalendar)
    this.UpdateFromServer();
   else if (this.sharedParameters.currentDateEdit != null)
    this.sharedParameters.currentDateEdit.CreateUpdateCallback();
  }
  else {
   if(this.IsAnimationEnabled() && !this.forceUpdatingOnMouseOver)
    this.StartBeforeUpdateAnimation();
   else
    this.UpdateInternal();
  }
 },
 UpdateFromServer: function() {
  if(this.callBack) {
   this.ShowLoadingElements();
   this.CreateCallback(this.sharedParameters.GetUpdateCallbackParameters());
  }
  else {
   this.SendPostBack("");
  }
 },
 UpdateInternal: function() {
  if(this.NeedCalculateSelectionOnUpdating())
   this.selection.Clear();
  for(var key in this.views) {
   var view = this.views[key];
   if(view.constructor != ASPxClientCalendarView) continue;
   view.Update();
  }
  if(this.IsAnimationEnabled() && !this.forceUpdatingOnMouseOver)
   this.StartAfterUpdateAnimation();
 },
 IsAnimationEnabled: function() {
  return (this.enableSlideCallbackAnimation || this.enableCallbackAnimation) && !this.IsUpdateAnimationLocked();
 },
 LockUpdateAnimation: function() {
  this.updateAnimationLockCount++;
 },
 UnlockUpdateAnimation: function() {
  this.updateAnimationLockCount--;
 },
 IsUpdateAnimationLocked: function() {
  return this.updateAnimationLockCount > 0;
 },
 StartBeforeUpdateAnimation: function() {
  this.updateAnimationProcessing = true;
  var element = this.GetCallbackAnimationElement();
  if(this.enableSlideCallbackAnimation && this.slideAnimationDirection) 
   ASPx.AnimationHelper.slideOut(element, this.slideAnimationDirection, this.FinishBeforeUpdateAnimation.aspxBind(this), ASPx.AnimationEngineType.JS);
  else if(this.enableCallbackAnimation) 
   ASPx.AnimationHelper.fadeOut(element, this.FinishBeforeUpdateAnimation.aspxBind(this));
  else
   this.FinishBeforeUpdateAnimation();
 },
 FinishBeforeUpdateAnimation: function() {
  this.UpdateInternal();
 },
 StartAfterUpdateAnimation: function() {
  var element = this.GetCallbackAnimationElement();
  if(this.enableSlideCallbackAnimation && this.slideAnimationDirection) 
   ASPx.AnimationHelper.slideIn(element, this.slideAnimationDirection, this.FinishAfterUpdateAnimation.aspxBind(this), ASPx.AnimationEngineType.JS);
  else if(this.enableCallbackAnimation) 
   ASPx.AnimationHelper.fadeIn(element, this.FinishAfterUpdateAnimation.aspxBind(this));
  else
   this.FinishAfterUpdateAnimation();
 },
 FinishAfterUpdateAnimation: function() {
  this.updateAnimationProcessing = false;
  this.slideAnimationDirection = null;
  this.CheckRepeatGesture();
 },
 ApplySelectionByDiff: function(selection, save) {
  var toShow = [ ];
  var toHide = [ ];
  var dates =  selection.GetDates();
  var oldDates = this.selection.GetDates();
  var selectionEdges = this.sharedParameters.dateRangeMode ? ASPx.Data.ArrayGetIntegerEdgeValues(dates) : null;
  var oldSelectionEdges = this.sharedParameters.dateRangeMode ? ASPx.Data.ArrayGetIntegerEdgeValues(oldDates) : null;
  var date;
  for(var i = 0; i < dates.length; i++) {
   date = dates[i];
   var isEdgeDateInSelection = selectionEdges
    && ASPxClientCalendar.IsFirstDateEqualToAnyOther(dates[i], selectionEdges.start, selectionEdges.end);
   var isEdgeDateInOldSelection = oldSelectionEdges
    && ASPxClientCalendar.IsFirstDateEqualToAnyOther(dates[i], oldSelectionEdges.start, oldSelectionEdges.end);
   if (!this.selection.Contains(date)
    || isEdgeDateInSelection && !isEdgeDateInOldSelection
    || !isEdgeDateInSelection && isEdgeDateInOldSelection)
    toShow.push(date);
  }
  for(var i = 0; i < oldDates.length; i++) {
   date = oldDates[i];
   if(!selection.Contains(date))
    toHide.push(date);
  }
  for(var key in this.views) {
   var view = this.views[key];
   if(view.constructor != ASPxClientCalendarView) continue;
   view.UpdateSelection(toHide, false, selectionEdges);
   view.UpdateSelection(toShow, true, selectionEdges);
  }
  this.selection.Assign(selection);
  if(this.accessibilityCompliant)
   this.accessibilityHelper.PronounceDates(dates);
 },
 ImportEtalonStyle: function(info, suffix) {
  var cell = this.GetEtalonStyleCell(suffix);
  if(ASPx.IsExistsElement(cell))
   info.Import(cell);   
 },
 GetEtalonStyleCell: function(name) {
  return this.GetChildElement("EC_" + name);
 },
 UpdateStateObject: function() {
  var stateObject = { };
  var visibleDate = ASPxClientCalendarDateDisabledHelper.GetCorrectedDate(this.visibleDate);
  stateObject.visibleDate = ASPx.DateUtils.GetInvariantDateString(visibleDate);
  if(this.selection.count > 0) {
   stateObject.selectedDates = [];
   var dates = this.selection.GetDates();
   for(var i = 0; i < dates.length; i++)
    stateObject.selectedDates.push(ASPx.DateUtils.GetInvariantDateString(dates[i]));
  }
  this.UpdateStateObjectWithObject(stateObject);
 },
 GetStateHiddenFieldName: function() {
  return this.uniqueID;
 },  
 FormatDates: function(dates, separator) {
  var result = "";
  for(var i = 0; i < dates.length; i++) {
   if(result.length > 0)
    result += separator;
   result += ASPx.DateUtils.GetInvariantDateString(dates[i]);     
  }
  return result;
 },
 InitializeKeyHandlers: function() {
  this.AddKeyDownHandler(ASPx.Key.Enter, "OnEnterDown");
  this.AddKeyDownHandler(ASPx.Key.Esc, "OnEscape");
  this.AddKeyDownHandler(ASPx.Key.PageUp, "OnPageUp");
  this.AddKeyDownHandler(ASPx.Key.PageDown, "OnPageDown");
  this.AddKeyDownHandler(ASPx.Key.End, "OnEndKeyDown");
  this.AddKeyDownHandler(ASPx.Key.Home, "OnHomeKeyDown");
  this.AddKeyDownHandler(ASPx.Key.Left, this.rtl ? "OnArrowRight" : "OnArrowLeft");
  this.AddKeyDownHandler(ASPx.Key.Right, this.rtl ? "OnArrowLeft" : "OnArrowRight");
  this.AddKeyDownHandler(ASPx.Key.Up, "OnArrowUp");
  this.AddKeyDownHandler(ASPx.Key.Down, "OnArrowDown");
  this.AddKeyPressHandler(ASPx.Key.Enter, "OnEnterPressed");
 },
 OnArrowUp: function(evt) {
  if(this.IsFastNavigationActive()) 
   this.GetFastNavigation().OnArrowUp(evt);
  else if(!this.readOnly) {
   var newDate = this.GetNearestDayForToday();
   if(this.lastSelectedDate)
    newDate = ASPxClientCalendar.GetPrevWeekDate(this.lastSelectedDate);
   if(!ASPxClientCalendarDateDisabledHelper.IsDateWithinBoundaries(newDate))
    return true;
   this.CorrectVisibleMonth(newDate, false);
   this.DoKeyboardSelection(newDate, evt.shiftKey, "up");
  }
  return true;
 },
 OnArrowDown: function(evt) {
  if(this.IsFastNavigationActive()) 
   this.GetFastNavigation().OnArrowDown(evt);
  else if(!this.readOnly) {
   var newDate = this.GetNearestDayForToday();
   if(this.lastSelectedDate)  
    newDate = ASPxClientCalendar.GetNextWeekDate(this.lastSelectedDate);
   this.CorrectVisibleMonth(newDate, true);
   this.DoKeyboardSelection(newDate, evt.shiftKey, "down");
  }
  return true;
 },
 OnArrowLeft: function(evt) { 
  if(this.IsFastNavigationActive()) 
   this.GetFastNavigation().OnArrowLeft(evt);
  else if(!this.readOnly) {  
   var newDate = this.GetNearestDayForToday();
   if(this.lastSelectedDate) 
    newDate = ASPxClientCalendar.GetYesterDate(this.lastSelectedDate);
   if(!ASPxClientCalendarDateDisabledHelper.IsDateWithinBoundaries(newDate))
    return true;
   this.CorrectVisibleMonth(newDate, false);
   this.DoKeyboardSelection(newDate, evt.shiftKey, "left");
  }
  return true;
 },
 OnArrowRight: function(evt) {
  if(this.IsFastNavigationActive()) 
   this.GetFastNavigation().OnArrowRight(evt);
  else if(!this.readOnly) {  
   var newDate = this.GetNearestDayForToday();
   if(this.lastSelectedDate)
    newDate = ASPxClientCalendar.GetTomorrowDate(this.lastSelectedDate);
   this.CorrectVisibleMonth(newDate, true);
   this.DoKeyboardSelection(newDate, evt.shiftKey, "right");
  }
  return true;
 },
 OnCallback: function(result){
  var table = this.GetMainElement();
  for(var rowIndex = 0; rowIndex < this.rows; rowIndex++) {
   for(var cellIndex = 0; cellIndex < this.columns; cellIndex++) {
    ASPx.SetInnerHtml(table.rows[rowIndex].cells[cellIndex], result[rowIndex * this.columns + cellIndex]);
   }
  }
  if(this.sharedParameters.hasCustomDisabledDatesViaCallback) {
    this.AddCallbackCustomDisabledDates(result[result.length - 1]);
  }
  this.CreateViews();
  this.InitializeGestures();
  this.InitializeEnabled();
  if(!this.isDateEditCalendar)
   this.SetFocus();
  if(!this.sharedParameters.calendarCustomDraw)
   this.UpdateInternal();
  this.EnsureTodayStyle();
 },
 OnPageUp: function(evt) {
  if(this.IsFastNavigationActive()) 
   this.GetFastNavigation().OnPageUp(evt);
  else if(!this.readOnly) {
   var newDate = this.GetNearestDayForToday();
   if(this.lastSelectedDate) {
    if(evt.ctrlKey)
     newDate = ASPxClientCalendar.GetPrevYearDate(this.lastSelectedDate);
    else
     newDate = ASPxClientCalendar.GetPrevMonthDate(this.lastSelectedDate);   
   }
   if(!ASPxClientCalendarDateDisabledHelper.IsDateWithinBoundaries(newDate))
    return true;
   this.CorrectVisibleMonth(newDate, false);  
   this.DoKeyboardSelection(newDate);
  }
  return true; 
 },
 OnPageDown: function(evt) {
  if(this.IsFastNavigationActive()) 
   this.GetFastNavigation().OnPageDown(evt);
  else if(!this.readOnly) {
   var newDate = this.GetNearestDayForToday();
   if(this.lastSelectedDate) {
    if(evt.ctrlKey)
     newDate = ASPxClientCalendar.GetNextYearDate(this.lastSelectedDate);
    else
     newDate = ASPxClientCalendar.GetNextMonthDate(this.lastSelectedDate);
   }
   this.CorrectVisibleMonth(newDate, true);
   this.DoKeyboardSelection(newDate);
  }
  return true;
 },
 OnEndKeyDown: function(evt) {
  if(!this.readOnly && !this.IsFastNavigationActive()) { 
   var newDate = this.GetNearestDayForToday();
   if(this.lastSelectedDate)   
    newDate = ASPxClientCalendar.CloneDate(this.lastSelectedDate);
   newDate = ASPxClientCalendar.GetLastDayInMonthDate(newDate);
   this.CorrectVisibleMonth(newDate, false);
   this.DoKeyboardSelection(newDate, evt.shiftKey);
  }
  return true;
 },
 OnHomeKeyDown: function(evt) {
  if(!this.readOnly && !this.IsFastNavigationActive()) {
   var newDate = this.GetNearestDayForToday();
   if(this.lastSelectedDate)   
    newDate = ASPxClientCalendar.CloneDate(this.lastSelectedDate);
   newDate = ASPxClientCalendar.GetFirstDayInMonthDate(newDate);   
   this.CorrectVisibleMonth(newDate, false);
   this.DoKeyboardSelection(newDate, evt.shiftKey);
  }
  return true; 
 },
 OnEnterDown: function() {
  if(this.IsFastNavigationActive()) {
   this.GetFastNavigation().OnEnter();
   return true;
  }
  return false;
 },
 OnEnterPressed: function() {
  return true;
 },
 OnEscape: function() {
  if(this.IsFastNavigationActive())
   this.GetFastNavigation().OnEscape();
  return true;
 },
 OnShiftMonth: function(offset) {
  if(offset) {
   var date = ASPxClientCalendar.AddMonths(this.visibleDate, offset);     
   this.OnVisibleMonthChanged(date);
  }
 },
 OnDayMouseDown: function(date, shift, ctrl, byWeeks) {
  this.isMouseDown = true;
  this.selectionByWeeks = byWeeks;
  if(!this.enableMulti && this.enableSwipeGestures)
   return;
  this.selectionTransaction.Start();
  if(this.enableMulti) {
   if(ctrl) {
    this.selectionCtrl = true;
    this.selectionTransaction.CopyFromBackup();
   } else
    this.selectionCtrl = false;
   if(shift && this.selectionPrevStartDate) {
    this.selectionStartDate = this.selectionPrevStartDate;         
    this.selectionTransaction.selection.AddRange(this.selectionStartDate, date);
    if(byWeeks)
     this.selectionTransaction.selection.AddWeek(date);
   } else {
    this.selectionStartDate = date;
    this.selectionPrevStartDate = date;
    if(byWeeks)
     this.selectionTransaction.selection.AddWeek(date);
    else
     this.selectionTransaction.selection.Add(date);
   }
  } 
  else 
   this.selectionTransaction.selection.Add(date);
  if(!ASPxClientCalendarDateDisabledHelper.IsDateWithinBoundaries(date))
   this.selectionTransaction.CopyFromBackup();
  if(this.enableMulti)
   this.RemoveDisabledDatesFromSelection(this.selectionTransaction.selection);
  this.ApplySelectionByDiff(this.selectionTransaction.selection, false);
 },
 OnDayMouseOver: function (date) {
  if (!this.sharedParameters.DaysSelectingOnMouseOver.IsEmpty()) {
   var args = new ASPxDaysSelectingOnMouseOverEventArgs(date);
   this.sharedParameters.DaysSelectingOnMouseOver.FireEvent(this, args);
   if (args.cancel)
    return;
   this.selectionStartDate = args.selectionStartDate;
   date = args.overDate;
  }
  if (!this.enableMulti && this.enableSwipeGestures && !this.sharedParameters.dateRangeMode)
   return;
  if (this.enableMulti || this.sharedParameters.dateRangeMode) {
   if(this.selectionCtrl)
    this.selectionTransaction.CopyFromBackup();
   else
    this.selectionTransaction.selection.Clear();
   if(this.sharedParameters.dateRangeMode)
    this.CalculateRangeSelectionOnMouseOver(date);
   else
    this.selectionTransaction.selection.AddRange(this.selectionStartDate, date);
   if(this.selectionByWeeks) {
    this.selectionTransaction.selection.AddWeek(date);
    this.selectionTransaction.selection.AddWeek(this.selectionStartDate);
   }
  } 
  else {
   this.selectionTransaction.selection.Clear();
   this.selectionTransaction.selection.Add(date);
  }
  if (this.enableMulti || this.sharedParameters.dateRangeMode)
   this.RemoveDisabledDatesFromSelection(this.selectionTransaction.selection);
  this.ApplySelectionByDiff(this.selectionTransaction.selection, false);
  if (this.updateDayStylesTwiceOnMouseOver)
   this.ForceUpdateOnMouseOver();
 },
 ForceUpdateOnMouseOver: function() {
  this.forceUpdatingOnMouseOver = true;
  try {
   this.Update();
  }
  finally {
   this.forceUpdatingOnMouseOver = false;
  }
 },
 CalculateRangeSelectionOnMouseOver: function(overDate) {
  var selectedRangeRestrictions = {
   start: ASPxClientCalendar.GetMinDate(this.selectionStartDate, overDate),
   end: ASPxClientCalendar.GetMaxDate(this.selectionStartDate, overDate)
  };
  var visibleRangeRestrictions = this.GetVisibleRangeRestrictions();
  ASPxClientCalendar.AddSelectedRangeVisiblePartToSelection(this.selectionTransaction.selection, selectedRangeRestrictions, visibleRangeRestrictions);
 },
 RaiseVisibleDaysMouseOut: function() {
  if (!this.sharedParameters.VisibleDaysMouseOut.IsEmpty())
   this.sharedParameters.VisibleDaysMouseOut.FireEvent(this);
 },
 OnDayMouseUp: function(date) {
  if(!ASPx.Browser.IE && this.isMouseDown)
   this.OnMainElementClick();
  this.isMouseDown = false;
  if(!this.enableMulti && this.enableSwipeGestures && this.swipeGestureStated) {
   this.swipeGestureStated = false;
   return;
  }
  if(this.enableMulti) {
   if(this.selectionCtrl && this.selectionTransaction.backup.Contains(date) &&
    ASPxClientCalendar.AreDatesEqual(date, this.selectionStartDate)) {
    if(this.selectionByWeeks)
     this.selectionTransaction.selection.RemoveWeek(date);
    else
     this.selectionTransaction.selection.Remove(date);
   }
  }
  else if(this.sharedParameters.dateRangeMode) {
   this.selectionTransaction.selection.Clear();
   this.selectionTransaction.selection.Add(date);
  }
  else if(this.enableSwipeGestures && !this.swipeGestureStated) {
   this.selectionTransaction.selection.Add(date);
   if(!ASPxClientCalendarDateDisabledHelper.IsDateWithinBoundaries(date))
    this.selectionTransaction.CopyFromBackup();
   this.ApplySelectionByDiff(this.selectionTransaction.selection, false);
  }
  this.lastSelectedDate = ASPxClientCalendar.CloneDate(date);
  this.OnSelectionChanging();
 },
 GetTodayDate: function() {
  var parentSchedulerTodayDate = this.GetParentSchedulerTodayDate();
  if(parentSchedulerTodayDate)
   return parentSchedulerTodayDate;
  var now = new Date(); 
  var date = new Date(now.getFullYear(), now.getMonth(), now.getDate());
  return date;
 },
 GetParentSchedulerTodayDate: function() {
  return this.actualTodayDate;
 },
 OnTodayClick: function() {
  var todayDate = this.GetTodayDate();
  if(ASPxClientCalendarDateDisabledHelper.IsDateInRange(this.sharedParameters, todayDate)) {
   if(!this.IsDateDisabled(todayDate)) {
    this.selectionTransaction.Start();
    this.selectionTransaction.selection.Add(todayDate);
    this.lastSelectedDate = ASPxClientCalendar.CloneDate(todayDate);
    this.OnSelectionChanging();
   }
   if(!ASPxClientCalendar.AreDatesOfSameMonth(todayDate, this.visibleDate))
    this.OnVisibleMonthChanged(todayDate);  
  }
 },
 OnClearClick: function() {
  this.selectionTransaction.Start();
  this.OnSelectionChanging();
  this.selectionStartDate = null;
  this.selectionPrevStartDate = null;    
  this.ResetLastSelectedDate();
 },
 ResetLastSelectedDate: function() {
  this.lastSelectedDate = null;
 },
 OnSelectMonth: function(row, column) {  
  var txn = this.selectionTransaction;
  txn.Start();
  var date = ASPxClientCalendar.CloneDate(this.GetView(row, column).visibleDate);
  date.setDate(1);
  do {  
   if(ASPxClientCalendarDateDisabledHelper.IsDateInRange(this.sharedParameters, date) &&
    !this.IsDateDisabled(date))
    txn.selection.Add(date);
   date = ASPxClientCalendar.AddDays(date, 1);
  } while(date.getDate() > 1);
  this.OnSelectionChanging();
 },
 OnTitleClick: function(row, column) {
  this.fastNavigation.activeView = this.GetView(row, column);
  this.fastNavigation.Prepare();
  this.fastNavigation.Show();
 },
 OnMainElementClick: function(mouseEvt) {
  this.MainElementClick.FireEvent(this, mouseEvt);
 },
 OnSelectionChanging: function() {
  if(!this.SelectionChanging.IsEmpty()){
   var args = new ASPxClientCalendarSelectionEventArgs(false, this.selectionTransaction.selection);
   this.SelectionChanging.FireEvent(this, args);  
  }
  var changed = this.selectionTransaction.IsChanged();
  this.selectionTransaction.Commit();
  if(changed)
   this.OnValueChanged();  
 },
 OnVisibleMonthChanged: function(date) {
  var offsetInternal = ASPxClientCalendar.GetOffsetInMonths(this.visibleDate, date);
  this.SetVisibleDate(date);
  var processOnServer = this.RaiseVisibleMonthChanged(offsetInternal);
  if(processOnServer && !this.customDraw)
   this.SendPostBackInternal("");
 },
 OnSelectionCancelled: function() {
  this.isMouseDown = false;  
  this.selectionTransaction.Rollback();
 },
 OnCustomDisabledDate: function(date) {
  return this.RaiseCustomDisabledDate(date);
 },
 RaiseCustomDisabledDate: function(date) {
  var args = new ASPxClientCalendarCustomDisabledDateEventArgs(date);
  this.CustomDisabledDate.FireEvent(this, args);
  return args;
 },
 RaiseValueChangedEvent: function() {
  var processOnServer = ASPxClientEdit.prototype.RaiseValueChangedEvent.call(this);
  processOnServer = this.RaiseSelectionChanged(processOnServer);
  return processOnServer;
 },
 EnsureSelectedDateIsActual: function() {
  if (this.sharedParameters.dateRangeMode)
   this.SetSelectedDate(this.lastSelectedDate);
 },
 SetVisibleDate: function(date) {
  var old = this.visibleDate;
  date = ASPxClientCalendarDateDisabledHelper.GetCorrectedDate(date);
  this.visibleDate = date;
  this.slideAnimationDirection = this.IsAnimationEnabled() ? ((old < this.visibleDate) ? ASPx.AnimationHelper.SLIDE_LEFT_DIRECTION : ASPx.AnimationHelper.SLIDE_RIGHT_DIRECTION) : null;
  if(!ASPxClientCalendar.AreDatesOfSameMonth(date, old) || this.forceUpdate) {
   this.forceUpdate = false;
   this.Update(); 
  }
 },
 SetSelectedDate: function(date) {
  if(ASPxClientCalendarDateDisabledHelper.IsDateInRange(this.sharedParameters, date) &&
   !this.IsDateDisabled(date)) {
   var selection = new ASPxClientCalendarSelection();
   if(date != null) {
    selection.Add(date);
    this.lastSelectedDate = ASPxClientCalendar.CloneDate(date);
   }
   this.ApplySelectionByDiff(selection, true);
  }
 },
 CorrectVisibleMonth: function(newDate, isForwardDirection) {
  var offset = ASPxClientCalendar.GetOffsetInMonths(this.visibleDate, newDate);
  if(this.IsMultiView() && offset != 0) {
   var view = isForwardDirection ? this.GetView(this.rows - 1, this.columns - 1) : 
            this.GetView(0, 0);
   offset = this.IsDateVisible(newDate) ? 0 :
       ASPxClientCalendar.GetOffsetInMonths(view.visibleDate, newDate);
  }
  if(!ASPxClientCalendarDateDisabledHelper.IsDateInRange(this.sharedParameters, newDate) ||
   this.IsDateDisabled(newDate))
   offset = 0;
  if(offset != 0)
   this.OnShiftMonth(offset);
 },
 DoKeyboardSelection: function(date, shift, direction) {
  if(ASPxClientCalendarDateDisabledHelper.IsDateInRange(this.sharedParameters, date)) {
   this.isDateChangingByKeyboard = true;
   var existDate = this.IsDateDisabled(date) ? this.GetNearestDayForDate(date, direction) : date;
   if(existDate != null) {
    this.selectionTransaction.Start();
    if(this.enableMulti && shift && this.selectionStartDate) {
     this.selectionTransaction.selection.AddRange(this.selectionStartDate, existDate);
     this.RemoveDisabledDatesFromSelection(this.selectionTransaction.selection);
    } else {
     this.selectionTransaction.selection.Add(existDate);
     this.selectionStartDate = existDate;
    }
    this.lastSelectedDate = ASPxClientCalendar.CloneDate(existDate);
    this.OnSelectionChanging();
   }
   this.isDateChangingByKeyboard = false;
  }
 },
 RemoveDisabledDatesFromSelection: function(selection) {
  var selectedDates = selection.GetDates();
  for(var i = 0; i < selectedDates.length; i++) {
   if(this.IsDateDisabled(selectedDates[i]))
    selection.Remove(selectedDates[i]);
  }
 },
 GetNearestDayForToday: function() {
  var todayDate = this.GetTodayDate();
  if(this.sharedParameters.minDate && !ASPxClientCalendarDateDisabledHelper.IsDateInRange(this.sharedParameters, todayDate))
   todayDate = ASPxClientCalendar.CloneDate(this.IsDateDisabled(this.sharedParameters.minDate) ? this.GetNearestDayForDate(this.sharedParameters.minDate, "left") : this.sharedParameters.minDate);
  return todayDate;
 },
 GetNearestDayForDate: function(date, direction) {
  var nearestDate = null;
  var nextDate = date;
  while(nearestDate == null) {
   switch(direction) {
    case "up":
     nextDate = new Date(nextDate.getTime() - (7 * 24 * 60 * 60 * 1000));
     break
    case "down":
     nextDate = new Date(nextDate.getTime() + (7 * 24 * 60 * 60 * 1000));
     break
    case "left":
     nextDate = new Date(nextDate.getTime() - (1 * 24 * 60 * 60 * 1000));
     break
    case "right":
     nextDate = new Date(nextDate.getTime() + (1 * 24 * 60 * 60 * 1000));
     break
   };
   if(!ASPxClientCalendarDateDisabledHelper.IsDateInRange(this.sharedParameters, nextDate))
    return null;
   nearestDate = this.IsDateDisabled(nextDate) ? null : nextDate;
  }
  return nearestDate;
 },
 UseDelayedSpecialFocus: function() { 
  return true;
 },
 GetDelayedSpecialFocusTriggers: function() {
  var list = ASPxClientEdit.prototype.GetDelayedSpecialFocusTriggers.call(this);
  if(this.enableFast)
   list.push(this.GetFastNavigation().GetPopup().GetWindowElement(-1));
  return list;
 },
 GetSelectedDate: function() {
  return this.GetValue();
 },
 GetVisibleDate: function() {
  return this.visibleDate;
 },
 SelectDate: function(date) {
  if(date) {
   date = ASPxClientCalendarDateDisabledHelper.GetCorrectedDate(date);
   this.selection.Add(date);
   this.Update();
  }
 },
 GetVisibleRangeRestrictions: function() {
  return {
   start: this.GetView(0, 0).GetVisibleRangeRestrictions().start,
   end: this.GetView(this.rows - 1, this.columns - 1).GetVisibleRangeRestrictions().end
  };
 },
 NeedCalculateSelectionOnUpdating: function() {
  return this.sharedParameters.dateRangeMode && this.selection.startDate && this.selection.endDate && !this.forceUpdatingOnMouseOver;
 },
 SelectRange: function(start, end) {
  if(start && end) {
   start = ASPxClientCalendarDateDisabledHelper.GetCorrectedDate(start);
   end = ASPxClientCalendarDateDisabledHelper.GetCorrectedDate(end);
   if(this.sharedParameters.dateRangeMode)
    this.selection.SetRestrictions(start, end);
   else
    this.selection.AddRange(start, end);
   this.Update();
  }
 },
 DeselectDate: function(date) {
  if(date) {
   this.selection.Remove(date);
   this.Update(); 
  }
 },
 DeselectRange: function(start, end) {
  if(start && end) {
   this.selection.RemoveRange(start, end);
   this.Update();
  }
 },
 ClearSelection: function() {
  this.selection.Clear();
  if(this.sharedParameters.dateRangeMode)
   this.selection.ResetRestrictions();
  this.Update();
 },
 GetSelectedDates: function() {
  return this.selection.GetDates();
 },
 RaiseSelectionChangedInternal: function(processOnServer) {
  if(!this.sharedParameters.CalendarSelectionChangedInternal.IsEmpty()) {
   var args = new ASPxClientProcessingModeEventArgs(processOnServer);
   this.sharedParameters.CalendarSelectionChangedInternal.FireEvent(this, args);
   processOnServer = args.processOnServer;
  }
  return processOnServer;
 },
 RaiseSelectionChanged: function(processOnServer) {
  processOnServer = this.RaiseSelectionChangedInternal(processOnServer);
  if(!this.SelectionChanged.IsEmpty()){
   var args = new ASPxClientProcessingModeEventArgs(processOnServer);  
   this.SelectionChanged.FireEvent(this, args);
   processOnServer = args.processOnServer;
  }
  return processOnServer;
 },
 RaiseVisibleMonthChanged: function(offsetInternal){
  var processOnServer = this.autoPostBack;
  if(!this.VisibleMonthChanged.IsEmpty()){
   var args = new ASPxClientProcessingModeEventArgs(processOnServer);
   args.offsetInternal = offsetInternal;
   this.VisibleMonthChanged.FireEvent(this, args);
   processOnServer = args.processOnServer;
  }
  return processOnServer;
 },
 ChangeEnabledAttributes: function(enabled){ 
  ASPx.Attr.ChangeDocumentEventsMethod(enabled)("mouseup", aspxCalDocMouseUp);
  ASPx.Attr.ChangeEventsMethod(enabled)(this.GetMainElement(), "click", ASPxClientCalendar.AnonymousHandlers.MainElementClick(this.name));
  var inputElement = this.GetInputElement();
  if(inputElement) 
   this.ChangeSpecialInputEnabledAttributes(inputElement, ASPx.Attr.ChangeEventsMethod(enabled));
  var btnElement = this.GetTodayButton();
  if(btnElement)
   this.ChangeButtonEnabledAttributes(btnElement, ASPx.Attr.ChangeAttributesMethod(enabled));
  btnElement = this.GetClearButton();
  if(btnElement)
   this.ChangeButtonEnabledAttributes(btnElement, ASPx.Attr.ChangeAttributesMethod(enabled));
  for(var key in this.views) {
   var view = this.views[key];
   if(view.constructor != ASPxClientCalendarView) continue;
   view.ChangeEnabledAttributes(enabled);
  }
 },
 ChangeEnabledStateItems: function(enabled){
  ASPx.GetStateController().SetElementEnabled(this.GetMainElement(), enabled);
  var btnElement = this.GetTodayButton();
  if(btnElement)
   ASPx.GetStateController().SetElementEnabled(btnElement, enabled);
  btnElement = this.GetClearButton();
  if(btnElement)
   ASPx.GetStateController().SetElementEnabled(btnElement, enabled);
  for(var key in this.views) {
   var view = this.views[key];
   if(view.constructor != ASPxClientCalendarView) continue;  
   view.ChangeEnabledStateItems(enabled);
  }
  this.UpdateInternal();   
 },
 ChangeButtonEnabledAttributes: function(element, method){
  method(element, "onclick");
  method(element, "ondblclick");
 },
 GetMinDate: function() {
  return this.sharedParameters.minDate;
 },
 SetMinDate: function(date) {
  date = ASPxClientCalendarDateDisabledHelper.GetCorrectedDate(date);
  this.sharedParameters.minDate = date;
  this.Update();
 },
 GetMaxDate: function() {
  return this.sharedParameters.maxDate;
 },
 SetMaxDate: function(date) {
  date = ASPxClientCalendarDateDisabledHelper.GetCorrectedDate(date);
  this.sharedParameters.maxDate = date;
  this.Update();
 },
 CheckDateEnabled: function(date){
  return !this.IsDateDisabled(date);
 },
 CanMouseDown: function(evt, date){
  if(!evt) return false;
  return ASPx.Evt.IsLeftButtonPressed(evt) && !this.IsDateDisabled(date);
 },
 CanMouseOver: function(date){
  if(this.forceMouseDown || this.isMouseDown || this.sharedParameters.dateRangeMode)
   return !this.IsDateDisabled(date);
  return false;
 },
 OnAssociatedLabelClick: function(evt) {
  ASPxClientCalendar.prototype.OnDelayedSpecialFocusMouseDown.call(this, evt);
 }
});
ASPxClientCalendar.Cast = ASPxClientControl.Cast;
var AccessibilityHelperCalendar = ASPx.CreateClass(ASPx.AccessibilityHelperBase, {
 constructor: function(calendar) {
  this.constructor.prototype.constructor.call(this, calendar);
  this.control.GotFocus.AddHandler(function() { this.PronounceDates(this.control.GetSelectedDates()); }.aspxBind(this));
  this.control.LostFocus.AddHandler(function() { 
   setTimeout(function() { this.changeActivityAttributes(this.getMainElement(), { "aria-activedescendant": "" }); }.aspxBind(this), 200); 
  }.aspxBind(this));
 },
 PronounceDates: function(dates) {
  var datesText = this.getDatesText(dates);
  var dateEditInput = null;
  if(this.control.isDateEditCalendar) {
   var dateEdit = this.control.sharedParameters.currentDateEdit;
   if(dateEdit)
    dateEditInput = dateEdit.GetInputElement();
  }
  this.PronounceMessage(datesText, null, null, null, dateEditInput);
 },
 getDatesText: function(dates) {
  var datesText = "";
  if(dates.length == 0)
   datesText = this.control.isDateEditCalendar ? ASPx.AccessibilitySR.CalendarDescription : ASPx.AccessibilitySR.BlankEditorText;
  else {
   dates.sort(function(x, y) { return x.valueOf() - y.valueOf(); });
   var ranges = this.getDateRanges(dates);
   datesText = this.getRangesText(ranges);
  }
  return datesText;
 },
 GetActiveElement: function(inputIsMainElement) {
  var activeElement = ASPx.AccessibilityHelperBase.prototype.GetActiveElement.call(this, inputIsMainElement);
  var mainElement = inputIsMainElement ? this.control.GetInputElement() : this.getMainElement();
  return activeElement == mainElement ? null : activeElement;
 },
 getRangesText: function(ranges) {
  var dateText = "";
  var hasMultiSelect = ranges.length > 1 || ranges.length === 1 && ranges[0].count > 1;
  if(hasMultiSelect)
   dateText = ASPx.AccessibilitySR.CalendarMultiSelectText;
  var rangesLength = ranges.length;
  var rangeDatesTextArray = [ ];
  for(var i = 0; i < rangesLength; i++)
   rangeDatesTextArray.push(this.getRangeText(ranges[i]));
  return dateText + rangeDatesTextArray.join(', ');
 },
 getRangeText: function(range) {
  var rangeFormatString = ASPx.AccessibilitySR.CalendarRangeFormatString;
  var startDateString = this.getDateString(range.start);
  if(range.count === 1)
   return startDateString;
  var endDateString = this.getDateString(ASPxClientCalendar.AddDays(range.start, range.count - 1));
  return ASPx.Str.ApplyReplacement(rangeFormatString, [["{0}", startDateString], ["{1}", endDateString]]);
 },
 getDateString: function(date) {
  var dateStringArray = [ ];
  dateStringArray.push(ASPx.CultureInfo.dayNames[date.getDay()]);
  dateStringArray.push(ASPx.CultureInfo.monthNames[date.getMonth()]);
  dateStringArray.push(date.getDate());
  dateStringArray.push(date.getFullYear());
  return dateStringArray.join(' ');
 },
 getDateRanges: function(dates) {
  var ranges = [ ];
  var start = null;
  var end = null;
  for(var i = 0; i < dates.length; i++) {
   var d1 = dates[i];
   var d2 = i < dates.length ? dates[i + 1] : d1;
   if(!start)
    start = end = d1;
   if(this.isNeibourDates(d1, d2)) {
    end = d2;
   } else {
    ranges.push({ start: start, count: ASPxClientCalendar.GetDaysInRange(start, end) });
    start = end = null;
   }
  }
  return ranges;
 },
 isNeibourDates: function(date1, date2) {
  var nextDay = ASPxClientCalendar.AddDays(date1, 1);
  return ASPxClientCalendar.AreDatesEqual(nextDay, date2);
 }
});
var ASPxClientCalendarCustomDisabledDateEventArgs = ASPx.CreateClass(ASPxClientEventArgs, {
 constructor: function(date) {
  this.constructor.prototype.constructor.call(this);
  this.date = date;
  this.isDisabled = false;
 }
});
ASPxClientCalendar.AnonymousHandlers = { 
 MainElementClick: function(name) {
  return function(e) {
   var cal = ASPx.GetControlCollection().Get(name);
   cal && cal.OnMainElementClick(e);
  };
 },
 SelectMonth: function(name, row, column) {
  return function() {
   var cal = ASPx.GetControlCollection().Get(name);
   cal && cal.OnSelectMonth(row, column);
  };
 },
 DayMouseEvent: function(name, row, column, index, byWeeks) {
  return function(e) {
   var cal = ASPx.GetControlCollection().Get(name);
   if(!cal)
    return;
   var view = cal.GetView(row, column);
   var date = view.GetDateByIndex(index);
   if(byWeeks)
    date = ASPxClientCalendar.AddDays(date, cal.firstDayOfWeek - date.getDay());
   var allowed = ASPxClientCalendarDateDisabledHelper.IsDateInRange(cal.sharedParameters, date) && (view.IsDateVisible(date) || byWeeks);
   switch(e.type) {
    case "mousedown":
     if(allowed && cal.CanMouseDown(e, date))
      cal.OnDayMouseDown(date, e.shiftKey, e.ctrlKey, byWeeks);
     break;
    case "mouseover":
     if(allowed && cal.CanMouseOver(date)) {
      if(cal.forceMouseDown)
       cal.OnDayMouseDown(date, false, false, false);
      else if (cal.isMouseDown || cal.sharedParameters.dateRangeMode)
       cal.OnDayMouseOver(date);
     }
     break;
    case "mouseup":
     if(cal.isMouseDown) {
      if(allowed && !cal.IsDateDisabled(date))
       cal.OnDayMouseUp(date);
      else
       cal.OnSelectionCancelled();
     }
     break;
    case "mouseout":
     if (cal.sharedParameters.dateRangeMode) {
      var isAllowedOverDate = false;
      var overCell = ASPx.Evt.GetEventRelatedTarget(e, false);
      var overCellIndex = view.GetDayCellIndex(overCell);
      if (ASPx.IsExists(overCellIndex)) {
       var overDate = view.GetDateByIndex(overCellIndex);
       isAllowedOverDate = overDate && ASPxClientCalendarDateDisabledHelper.IsDateInRange(cal.sharedParameters, overDate) && view.IsDateVisible(overDate) && !cal.IsDateDisabled(overDate);
      }
      if (!isAllowedOverDate) {
       cal.RaiseVisibleDaysMouseOut();
      }
     }
     break;
   }     
  };
 },
 FastNavMonthClick: function(name, month) {
  return function() {
   var cal = ASPx.GetControlCollection().Get(name);
   cal && cal.fastNavigation.OnMonthClick(month);   
  };
 },
 FastNavYearClick: function(name, index) {
  return function() {
   var cal = ASPx.GetControlCollection().Get(name);
   cal && cal.fastNavigation.OnYearClick(index);   
  };
 }
};
ASPxClientCalendar.GetMinDate = function(date1, date2) {
 return date1 < date2 ? date1 : date2;
};
ASPxClientCalendar.GetMaxDate = function(date1, date2) {
 return date1 > date2 ? date1 : date2;
};
ASPxClientCalendar.AddSelectedRangeVisiblePartToSelection = function(selection, selectedRangeRestrictions, visibleRangeRestrictions) {
 selection.Add(selectedRangeRestrictions.start);
 selection.Add(selectedRangeRestrictions.end);
 var bothRangeRestrictsLessThanVisibleStartDate = selectedRangeRestrictions.start < visibleRangeRestrictions.start
  && selectedRangeRestrictions.end < visibleRangeRestrictions.start;
 var bothRangeRestrictsGreaterThanVisibleEndDate = selectedRangeRestrictions.start > visibleRangeRestrictions.end
  && selectedRangeRestrictions.end > visibleRangeRestrictions.end;
 var rangeHasVisiblePart = !bothRangeRestrictsLessThanVisibleStartDate && !bothRangeRestrictsGreaterThanVisibleEndDate;
 if(rangeHasVisiblePart) {
  var requiredSelectionStart = ASPxClientCalendar.GetMaxDate(selectedRangeRestrictions.start, visibleRangeRestrictions.start);
  var requiredSelectionEnd = ASPxClientCalendar.GetMinDate(selectedRangeRestrictions.end, visibleRangeRestrictions.end);
  selection.AddRange(requiredSelectionStart, requiredSelectionEnd);
 }
};
ASPxClientCalendar.AreDatesEqual = function(date1, date2) {
 if(date1 == date2)  
  return true;
 if(!date1 || !date2)
  return false;
 return date1.getFullYear() == date2.getFullYear() && date1.getMonth() == date2.getMonth() && date1.getDate() == date2.getDate();
}
ASPxClientCalendar.IsFirstDateEqualToAnyOther = function () {
 var actualDate = arguments[0];
 for (var i = 1; i < arguments.length; i++)
  if (ASPxClientCalendar.AreDatesEqual(actualDate, arguments[i]))
   return true;
 return false;
}
ASPxClientCalendar.AreDatesOfSameMonth = function(date1, date2) {
 if(!date1 || !date2)
  return false;
 return date1.getFullYear() == date2.getFullYear() && date1.getMonth() == date2.getMonth();
}
ASPxClientCalendar.GetUTCTime = function(date) {
 return Date.UTC(date.getFullYear(), date.getMonth(), date.getDate());
}
ASPxClientCalendar.GetFirstDayOfYear = function(date) {
 return new Date(date.getFullYear(), 0, 1);  
}
ASPxClientCalendar.GetDayOfYear = function(date) {
 var ms = ASPxClientCalendar.GetUTCTime(date) - 
  ASPxClientCalendar.GetUTCTime(ASPxClientCalendar.GetFirstDayOfYear(date));
 return 1 + Math.floor(ms / ASPx.calendarMsPerDay);
}
ASPxClientCalendar.GetISO8601WeekOfYear = function(date) {
 var firstDate = new Date(date.getFullYear(), 0, 1);
 var firstDayOfWeek = firstDate.getDay();
 if(firstDayOfWeek == 0)
  firstDayOfWeek = 7;
 var daysInFirstWeek = 8 - firstDayOfWeek;
 var lastDate = new Date(date.getFullYear(), 11, 31);   
 var lastDayOfWeek = lastDate.getDay();
 if(lastDayOfWeek == 0)
  lastDayOfWeek = 7;
 var daysInLastWeek = 8 - lastDayOfWeek; 
 var fullWeeks = Math.ceil((ASPxClientCalendar.GetDayOfYear(date) - daysInFirstWeek) / 7);
 var result = fullWeeks;   
 if(daysInFirstWeek > 3)
  result++;
 var isThursday = firstDayOfWeek == 4 || lastDayOfWeek == 4;
 if(result > 52 && !isThursday)
  result = 1;
 if(result == 0)
  return ASPxClientCalendar.GetISO8601WeekOfYear(new Date(date.getFullYear() - 1, 11, 31));
 return result;
}
ASPxClientCalendar.GetNextWeekDate = function(date) {
 var ret = new Date(date.getTime()); 
 var newDay = date.getDate() + 7;
 ret.setDate(newDay);
 return ret;
}
ASPxClientCalendar.GetPrevWeekDate = function(date) {
 var ret = new Date(date.getTime());
 var newDay = date.getDate() - 7;
 ret.setDate(newDay);
 return ret;
}
ASPxClientCalendar.GetYesterDate = function(date) {
 var ret = new Date(date.getTime());
 ret.setDate(ret.getDate() - 1);
 return ret;
}
ASPxClientCalendar.GetTomorrowDate = function(date) {
 var ret = new Date(date.getTime());
 ret.setDate(ret.getDate() + 1);
 return ret;
}
ASPxClientCalendar.GetNextMonthDate = function(date) {
 var ret = new Date(date.getTime());
 var maxDateInNextMonth = ASPxClientCalendar.GetDaysInMonth(ret.getMonth() + 1, ret.getFullYear());
 if(ret.getDate() > maxDateInNextMonth)
  ret.setDate(maxDateInNextMonth);
 ret.setMonth(ret.getMonth() + 1);
 return ret;
}
ASPxClientCalendar.GetNextYearDate = function(date) {
 var ret = new Date(date.getTime());
 var maxDateInPrevYearMonth = ASPxClientCalendar.GetDaysInMonth(ret.getMonth(), ret.getFullYear() + 1);
 if(ret.getDate() > maxDateInPrevYearMonth)
  ret.setDate(maxDateInPrevYearMonth);
 ret.setFullYear(ret.getFullYear() + 1);
 return ret;
}
ASPxClientCalendar.GetPrevMonthDate = function(date) {
 var ret = new Date(date.getTime());
 var maxDateInPrevMonth = ASPxClientCalendar.GetDaysInMonth(ret.getMonth() - 1, ret.getFullYear());
 if(ret.getDate() > maxDateInPrevMonth)
  ret.setDate(maxDateInPrevMonth);
 ret.setMonth(ret.getMonth() - 1);
 return ret;
}
ASPxClientCalendar.GetPrevYearDate = function(date) {
 var ret = new Date(date.getTime());
 var maxDateInPrevYearMonth = ASPxClientCalendar.GetDaysInMonth(ret.getMonth(), ret.getFullYear() - 1);
 if(ret.getDate() > maxDateInPrevYearMonth)
  ret.setDate(maxDateInPrevYearMonth);
 ret.setFullYear(ret.getFullYear() - 1);
 return ret;
}
ASPxClientCalendar.GetFirstDayInMonthDate = function(date) {
 var ret = new Date(date.getTime());
 ret.setDate(1);
 return ret;
}
ASPxClientCalendar.GetLastDayInMonthDate = function(date) {
 var ret = new Date(date.getTime());
 var maxDateInYearMonth = ASPxClientCalendar.GetDaysInMonth(ret.getMonth(), ret.getFullYear());
 ret.setDate(maxDateInYearMonth);
 return ret;
}
ASPxClientCalendar.AddDays = function(startDate, dayCount) {
 var date = ASPxClientCalendar.CloneDate(startDate);
 var dayDiff = 0;
 var hourInc = 3600000;
 if(dayCount < 0)
  hourInc = -1 * hourInc;
 dayCount = Math.abs(dayCount);
 while(true) {
  if(dayDiff == dayCount && startDate.getHours() == date.getHours())
   return date;
  if(dayDiff > dayCount) {
   date.setTime(-1 * hourInc + date.getTime());
   return date;
  }
  var day = date.getDate();
  date.setTime(hourInc + date.getTime());
  if(day != date.getDate())
   dayDiff++;
 }
 return date;
}
ASPxClientCalendar.AddMonths = function(date, count) {
 var newDate = ASPxClientCalendar.CloneDate(date);
 newDate.setMonth(count + newDate.getMonth());
 ASPx.DateUtils.FixTimezoneGap(date, newDate);
 if(newDate.getDate() < date.getDate())
  newDate = ASPxClientCalendar.AddDays(newDate, -newDate.getDate()); 
 return newDate;
}
ASPxClientCalendar.CloneDate = function(date) {
 var cloned = new Date();
 cloned.setTime(date.getTime());
 return cloned;
}
ASPxClientCalendar.GetDecadeStartYear = function(year) {
 return 10 * Math.floor(year / 10);
}
ASPxClientCalendar.GetDaysInRange = function(start, end) {
 return 1 + (ASPxClientCalendar.GetUTCTime(end) - ASPxClientCalendar.GetUTCTime(start)) / ASPx.calendarMsPerDay;
};
ASPxClientCalendar.GetDaysInMonth = function(month, year) {
 var d = new Date(year, month + 1, 0);
 return d.getDate();
};
ASPxClientCalendar.GetOffsetInMonths = function(start, end) {
 return end.getMonth() - start.getMonth() + 12 * (end.getFullYear() - start.getFullYear());
};
var ASPxClientCalendarDateDisabledHelper = {
 MinDate: new Date(100, 0, 1, 0, 0, 0, 0),
 MaxDate: new Date(9999, 11, 31, 23, 59, 59, 999),
 GetUpperLimitDate: function() {
  return this.MaxDate;
 },
 GetLowerLimitDate: function() {
  return this.MinDate;
 },
 IsDateWithinBoundaries: function(date) {
  return date >= this.GetLowerLimitDate() && date <= this.GetUpperLimitDate();
 },
 GetCorrectedDate: function(date) {
  if(!date)
   return null;
  if(this.IsDateWithinBoundaries(date))
   return date;
  else
   return date > this.GetUpperLimitDate() ? this.GetUpperLimitDate() : this.GetLowerLimitDate();
 },
 IsDateInRange: function(sharedParameters, date) {
  return date == null ||
   ((sharedParameters.minDate == null || date >= sharedParameters.minDate) &&
    (sharedParameters.maxDate == null || date <= sharedParameters.maxDate) &&
    this.IsDateWithinBoundaries(date));
 },
 IsDateDisabled: function(sharedParameters, date, OnCustomDisabledDate) {
  if(date != null) {
   var length = sharedParameters.disabledDates.length;
   if(length > 0 && date != null) {
    for(var i = 0; i < length; i++) {
     var disabledDate = sharedParameters.disabledDates[i];
     if(disabledDate.getDate() == date.getDate() &&
      disabledDate.getMonth() == date.getMonth() &&
      disabledDate.getFullYear() == date.getFullYear())
      return true;
    }
   }
   if(OnCustomDisabledDate(date).isDisabled)
    return true;
  }
  return false;
 }
};
var ASPxClientCalendarSelection = ASPx.CreateClass(null, {
 constructor: function() {
  this.dates = { };
  this.count = 0;  
 },
 Assign: function(source) {
  this.Clear();
  for(var key in source.dates) {
   var item = source.dates[key];
   if(item.constructor != Date) continue;
   this.Add(item);
  }
 },
 Clear: function() {
  if(this.count > 0) {
   this.dates = { };
   this.count = 0;
  }
 },
 Equals: function(selection) {
  if(this.count != selection.count)
   return false;
  for(var key in this.dates) {
   if(this.dates[key].constructor != Date) continue;
   if(!selection.ContainsKey(key))
    return false;
  }
  return true;
 },
 Contains: function(date) {
  var key = this.GetKey(date);
  return this.ContainsKey(key);
 },
 ContainsKey: function(key) {
  return !!this.dates[key];
 },
 Add: function(date) {
  var key = this.GetKey(date);
  if(!this.ContainsKey(key)) {
   this.dates[key] = ASPxClientCalendar.CloneDate(date);
   this.count++;
  }
 },
 AddArray: function(dates) {
  for(var i = 0; i < dates.length; i++)
   this.Add(dates[i]);
 },
 AddRange: function(start, end)  {
  if(end < start) {
   this.AddRange(end, start);
   return;
  }
  var count = ASPxClientCalendar.GetDaysInRange(start, end);
  var date = ASPxClientCalendar.CloneDate(start);  
  for(var i = 0; i < count; i++) {
   this.Add(date);
   date = ASPxClientCalendar.AddDays(date, 1);
  }
 },
 AddWeek: function(startDate) {
  this.AddRange(startDate, ASPxClientCalendar.AddDays(startDate, 6));
 },
 SetRestrictions: function(start, end) {
  this.startDate = ASPxClientCalendar.CloneDate(start);
  this.endDate = ASPxClientCalendar.CloneDate(end);
 },
 ResetRestrictions: function() {
  this.startDate = null;
  this.endDate = null;
 },
 Remove: function(date) {
  var key = this.GetKey(date);
  if(this.ContainsKey(key)) {
   delete this.dates[key];
   this.count--;
  }
 },
 RemoveArray: function(dates) {
  for(var i = 0; i < dates.length; i++)
   this.Remove(dates[i]);
 },
 RemoveRange: function(start, end) {
  if(end < start) {
   this.RemoveRange(end, start);
   return;
  }
  var count = ASPxClientCalendar.GetDaysInRange(start, end);
  var date = ASPxClientCalendar.CloneDate(start);  
  for(var i = 0; i < count; i++) {
   this.Remove(date);
   date = ASPxClientCalendar.AddDays(date, 1);
  }
 },
 RemoveWeek: function(startDate) {
  this.RemoveRange(startDate, ASPxClientCalendar.AddDays(startDate, 6));
 },
 GetDates: function() {
  var result = [ ];
  for(var key in this.dates) {
   var item = this.dates[key];
   if(item.constructor != Date) continue;
   result.push(ASPxClientCalendar.CloneDate(item));
  }
  return result;  
 },
 GetFirstDate: function() {
  if(this.count == 0)
   return null;
  for(var key in this.dates) {
   var item = this.dates[key];
   if(item.constructor != Date) continue;
   return ASPxClientCalendar.CloneDate(item);
  }
  return null;
 },
 GetKey: function(date) {  
  return ASPx.DateUtils.GetInvariantDateString(date);
 }
});
var ASPxClientCalendarSelectionTransaction = ASPx.CreateClass(null, {
 constructor: function(calendar) {
  this.calendar = calendar;
  this.isActive = false;
  this.backup = new ASPxClientCalendarSelection();
  this.selection = new ASPxClientCalendarSelection;
 },
 Start: function() {
  if(this.isActive)
   this.Rollback();
  this.backup.Assign(this.calendar.selection);
  this.selection.Clear();
  this.isActive = true;
  ASPx.activeCalendar = this.calendar;
 },
 Commit: function() {  
  this.calendar.ApplySelectionByDiff(this.selection, true);
  this.Reset();
 },
 Rollback: function() {
  this.calendar.ApplySelectionByDiff(this.backup);  
  this.Reset();
 },
 Reset: function() {
  this.backup.Clear();
  this.selection.Clear();
  this.isActive = false;
  ASPx.activeCalendar = null;
 },
 CopyFromBackup: function() {
  this.selection.Assign(this.backup);
 },
 IsChanged: function() {
  return !this.backup.Equals(this.selection);
 }
});
var ASPxClientCalendarView = ASPx.CreateClass(null, {
 constructor: function(calendar, row, column) {
  this.row = row;
  this.column = column;
  this.calendar = calendar;
  var temp = column + row;
  this.isLowBoundary = temp == 0;
  this.isHighBoundary = temp == calendar.rows + calendar.columns - 2;
  this.visibleDate = null;
  this.startDate = null;
  this.dayFunctions = {};
  this.dayFunctionsWithWeekSelection = {};
 },
 Initialize: function() {
  this.dayCellCache = {};
  this.dayStyleCache = {};
  this.UpdateDate();
  this.EnsureSelection();
  this.MakeDisabledStateItems();
 },
 AttachMouseEvents: function(eventMethod, styleMethod) {
  var index;
  var cell;
  if(this.calendar.showDayHeaders) {
   var headCells = this.GetMonthTable().rows[0].cells;
   var dayNameIndex = 0;
   if(this.calendar.showWeekNumbers) {
    dayNameIndex++;
    cell = headCells[0];
    if(this.calendar.enableMulti) {
     eventMethod(cell, "click", ASPxClientCalendar.AnonymousHandlers.SelectMonth(this.calendar.name, this.row, this.column));
     styleMethod(cell, "cursor", ASPx.GetPointerCursor());
    }
    this.AttachCancelSelect(eventMethod, cell);
   }
   for(var j = 0; j < 7; j++)
    this.AttachCancelSelect(eventMethod, headCells[dayNameIndex++]);
  }
  for(var i = 0; i < calendarWeekCount; i++) {
   if(this.calendar.showWeekNumbers) {
    cell = this.GetWeekNumberCell(i);
    if(this.calendar.enableMulti)
     this.AttachDayMouseEvents(eventMethod, cell, this.GetDayMouseEventFunction(7 * i, true));
    else
     this.AttachCancelSelect(eventMethod, cell);
   }
   var date;
   for(var j = 0; j < 7; j++) {
    index = i * 7 + j;
    cell = this.GetDayCell(index);
    date = this.GetDateByIndex(index);
    var cal = this.calendar;
    if(!this.calendar.enableMulti && this.IsDateVisible(date) &&
     ASPxClientCalendarDateDisabledHelper.IsDateInRange(cal.sharedParameters, date) &&
     !cal.IsDateDisabled(date)) {
     if(!cell.style.cursor || cell.style.cursor == ASPx.GetPointerCursor())
      styleMethod(cell, "cursor", ASPx.GetPointerCursor());
    }
    this.AttachDayMouseEvents(eventMethod, cell, this.GetDayMouseEventFunction(index, false));
   }
  }
 },
 AttachDayMouseEvents: function(method, cell, handler) {
  var types = ["down", "up", "over", "out"];
  for(var i = 0; i < types.length; i++)
   method(cell, "mouse" + types[i], handler);
 },
 AttachCancelSelect: function(method, element) {
  method(element, "mouseup", aspxCalCancelSelect);
 },
 GetDayMouseEventFunction: function(index, selectWeeks) {
  var hash = selectWeeks ? this.dayFunctionsWithWeekSelection : this.dayFunctions;
  if(!hash[index])
   hash[index] = ASPxClientCalendar.AnonymousHandlers.DayMouseEvent(this.calendar.name, this.row, this.column, index, selectWeeks);
  return hash[index];
 },
 UpdateDate: function() {
  this.visibleDate = ASPxClientCalendar.AddMonths(this.calendar.visibleDate,
   this.row * this.calendar.columns + this.column);
  var date = ASPxClientCalendar.CloneDate(this.visibleDate);
  date.setDate(1);
  this.UpdatePreviousMonthCells(date);
  this.UpdateNextMonthCells(date);
  var offset = date.getDay() - this.calendar.firstDayOfWeek;
  if(offset < 0)
   offset += 7;
  this.startDate = ASPxClientCalendar.AddDays(date, -offset);
 },
 UpdatePreviousMonthCells: function(date) { 
  var prevYearCell = this.GetPrevYearCell();
  var prevMonthCell = this.GetPrevMonthCell();
  var isEnabledDate = date.getFullYear() > 100;
  if(prevYearCell && ASPx.GetElementVisibility(prevYearCell) != isEnabledDate) {
   ASPx.SetElementVisibility(prevYearCell, isEnabledDate);
  }
  if(prevMonthCell) {
   var isEnabledDate = isEnabledDate || (date.getFullYear() == 100 && date.getMonth() > 0);
   if(ASPx.GetElementVisibility(prevMonthCell) != isEnabledDate)
    ASPx.SetElementVisibility(prevMonthCell, isEnabledDate);
  }
 },
 UpdateNextMonthCells: function(date) {
  var nextYearCell = this.GetNextYearCell();
  var nextMonthCell = this.GetNextMonthCell();
  var isEnabledDate = date.getFullYear() < 9999;
  if(nextYearCell && ASPx.GetElementVisibility(nextYearCell) != isEnabledDate) {
   ASPx.SetElementVisibility(nextYearCell, isEnabledDate);
  }
  if(nextMonthCell) {
   var isEnabledDate = isEnabledDate || (date.getFullYear() == 9999 && date.getMonth() < 11);
   if(ASPx.GetElementVisibility(nextMonthCell) != isEnabledDate)
    ASPx.SetElementVisibility(nextMonthCell, isEnabledDate);
  }
 },
 GetDateByIndex: function(index) {
  return ASPxClientCalendar.AddDays(this.startDate, index);
 },
 GetIndexByDate: function(date) {
  return ASPxClientCalendar.GetDaysInRange(this.startDate, date) - 1;
 },
 IsDateOtherMonth: function(date) {
  if(date == null)
   return false;
  return date.getMonth() != this.visibleDate.getMonth() ||
   date.getFullYear() != this.visibleDate.getFullYear();
 },
 GetDayCell: function(index) {
  if(ASPx.IsExistsElement(this.dayCellCache[index]))
   return this.dayCellCache[index];
  var mt = this.GetMonthTable();
  var colIndex = index % 7;
  var rowIndex = (index - colIndex) / 7;
  if(this.calendar.showDayHeaders)
   rowIndex++;
  if(this.calendar.showWeekNumbers)
   colIndex++;
  var cell = mt.rows[rowIndex].cells[colIndex];
  this.dayCellCache[index] = cell;
  return cell;
 },
 GetDayCellIndex: function (cell) {
  var currentDate = ASPxClientCalendar.CloneDate(this.startDate);
  var maxIndex = this.GetMaxIndex();
  do {
   var currentIndex = this.GetIndexByDate(currentDate);
   if (this.GetDayCell(currentIndex) === cell)
    return currentIndex;
   currentDate = ASPxClientCalendar.AddDays(currentDate, 1);
  }
  while (currentIndex < maxIndex);
  return null;
 },
 GetMaxIndex: function() {
  return 7 * calendarWeekCount - 1;
 },
 GetMonthTable: function() {
  return this.GetChildElement("mt");
 },
 GetMonthCell: function() {
  return this.GetChildElement("mc");
 },
 GetWeekNumberCell: function(index) {
  if(this.calendar.showDayHeaders)
   index++;
  return this.GetMonthTable().rows[index].cells[0];
 },
 GetPrevYearCell: function() {
  return this.GetChildElement("PYC");
 },
 GetPrevMonthCell: function() {
  return this.GetChildElement("PMC");
 },
 GetTitleCell: function() {
  return this.GetChildElement("TC");
 },
 GetTitleElement: function() {
  return this.GetChildElement("T");
 },
 GetNextMonthCell: function() {
  return this.GetChildElement("NMC");
 },
 GetNextYearCell: function() {
  return this.GetChildElement("NYC");
 },
 GetVisibleRangeRestrictions: function() {
  return {
   start: this.GetDateByIndex(0),
   end: this.GetDateByIndex(this.GetMaxIndex())
  };
 },
 Update: function() {
  this.dayStyleCache = {};
  this.UpdateDate();
  this.UpdateDays();
  this.UpdateTitle();
  this.EnsureSelection();
 },
 EnsureSelection: function() {
  var selection = this.calendar.selection;
  var selectedRangeRestrictions = this.calendar.sharedParameters.dateRangeMode ? ASPx.Data.ArrayGetIntegerEdgeValues(selection.GetDates()) : null;
  if(this.calendar.NeedCalculateSelectionOnUpdating()) {
   selectedRangeRestrictions.start = ASPxClientCalendar.CloneDate(selection.startDate);
   selectedRangeRestrictions.end = ASPxClientCalendar.CloneDate(selection.endDate);
   var visibleRangeRestrictions = this.GetVisibleRangeRestrictions();
   ASPxClientCalendar.AddSelectedRangeVisiblePartToSelection(selection, selectedRangeRestrictions, visibleRangeRestrictions);
  }
  this.UpdateSelection(selection.GetDates(), true, selectedRangeRestrictions);
 },
 UpdateDays: function() {
  var date = ASPxClientCalendar.CloneDate(this.startDate);
  var offset = this.calendar.firstDayOfWeek - 1;
  if(offset < 0)
   offset += 7;
  var weekNumber = ASPxClientCalendar.GetISO8601WeekOfYear(ASPxClientCalendar.AddDays(date, offset));
  var cell;
  for(var i = 0; i < calendarWeekCount; i++) {
   if(this.calendar.showWeekNumbers)
    this.GetWeekNumberCell(i).innerHTML = (weekNumber < 10 ? "0" : "") + weekNumber.toString();
   for(var j = 0; j < 7; j++) {
    cell = this.GetDayCell(i * 7 + j);
    cell.innerHTML = this.IsDateVisible(date) ? date.getDate() : "&nbsp;";
    this.ApplyDayCellStyle(cell, date);
    date = ASPxClientCalendar.AddDays(date, 1);
   }
   if(++weekNumber > 52)
    weekNumber = ASPxClientCalendar.GetISO8601WeekOfYear(ASPxClientCalendar.AddDays(date, offset));
  }
 },
 UpdateTitle: function() {
  var el = this.GetTitleElement();
  if(!el) return;
  if(!this.titleFormatter) {
   this.titleFormatter = new ASPx.DateFormatter();
   this.titleFormatter.SetFormatString(this.calendar.rtl ? "MMMM yyyy" : ASPx.CultureInfo.yearMonth);
  }
  el.innerHTML = this.titleFormatter.Format(this.visibleDate);
 },
 UpdateSelection: function(dates, showSelection, totalSelectionEdges) {
  var index;
  for(var i = 0; i < dates.length; i++) {
   index = this.GetIndexByDate(dates[i]);
   if(!this.IsValidIndex(index) || !this.IsDateVisible(dates[i]))
    continue;
   var applyDateInRangeStyle = totalSelectionEdges
    && !ASPxClientCalendar.IsFirstDateEqualToAnyOther(dates[i], totalSelectionEdges.start, totalSelectionEdges.end);
   this.ApplySelectionToCell(index, showSelection, applyDateInRangeStyle);
  }
 },
 IsValidIndex: function(index) {
  return index >= 0 && index <= this.GetMaxIndex();
 },
 ApplySelectionToCell: function (index, showSelection, applyDateInRangeStyle) {
  var cell = this.GetDayCell(index);
  if(showSelection) {
   var info;
   if(!this.dayStyleCache[index]) {
    var backup = new ASPxClientCalendarStyleInfo();
    backup.Import(cell);
    this.dayStyleCache[index] = backup;
    info = backup.Clone();
   } else
    info = this.dayStyleCache[index].Clone();
   this.calendar.ImportEtalonStyle(info, "DS");
  } else
   info = this.dayStyleCache[index];
  info.Apply(cell);
  if (applyDateInRangeStyle) {
   if (showSelection)
    ASPx.AddClassNameToElement(cell, ASPxClientCalendarView.DayInRangeClassName);
   else
    ASPx.RemoveClassNameFromElement(cell, ASPxClientCalendarView.DayInRangeClassName);
  }
 },
 ApplyDayCellStyle: function(cell, date) {
  cell.style.cursor = "";
  var cal = this.calendar;
  var info = new ASPxClientCalendarStyleInfo();
  var needPointer = false;
  cal.ImportEtalonStyle(info, "D");
  if(this.IsDateVisible(date)) {
   if(cal.IsDateWeekend(date))
    cal.ImportEtalonStyle(info, "DW");
   if(this.IsDateOtherMonth(date))
    cal.ImportEtalonStyle(info, "DA");
   if(!ASPxClientCalendarDateDisabledHelper.IsDateInRange(cal.sharedParameters, date))
    cal.ImportEtalonStyle(info, "DO");
   if(cal.IsDateDisabled(date)) {
    cal.ImportEtalonStyle(info, "DDD");
   }
   if(ASPxClientCalendar.AreDatesEqual(this.GetActualTodayDate(), date))
    cal.ImportEtalonStyle(info, "DT");
   if(!cal.clientEnabled)
    cal.ImportEtalonStyle(info, "DD");
   else if(!cal.enableMulti)
    needPointer = true;
  }
  info.Apply(cell);
  if(needPointer)
   ASPx.SetPointerCursor(cell);
 },
 RemoveDayCellStyle: function(cell, suffix) {
  var info = new ASPxClientCalendarStyleInfo();
  this.calendar.ImportEtalonStyle(info, suffix);
  info.Remove(cell);
 },
 EnsureTodayStyle: function() {
  var serverCurrentDateIndex = this.GetIndexByDate(this.calendar.serverCurrentDate);
  var clientCurrentDateIndex = this.GetIndexByDate(new Date());
  if(this.IsValidIndex(serverCurrentDateIndex))
   this.RemoveDayCellStyle(this.GetDayCell(serverCurrentDateIndex), "DT");
  if(this.IsValidIndex(clientCurrentDateIndex))
   this.ApplyDayCellStyle(this.GetDayCell(clientCurrentDateIndex), new Date());
  this.dayStyleCache[serverCurrentDateIndex] = null;
  this.dayStyleCache[clientCurrentDateIndex] = null;
  this.EnsureSelection();
 },
 GetActualTodayDate: function() {
  if(!this.calendar || !this.calendar.actualTodayDate)
   return new Date();
  return this.calendar.actualTodayDate;
 },
 GetIDPostfix: function() {
  return "_" + this.row.toString() + "x" + this.column.toString();
 },
 GetChildElement: function(postfix) {
  if(this.calendar.IsMultiView())
   postfix += this.GetIDPostfix();
  return this.calendar.GetChildElement(postfix);
 },
 IsDateVisible: function(date) {
  var result = !this.calendar.IsMultiView() || !this.IsDateOtherMonth(date);
  if(!result) {
   result = result || this.isLowBoundary && date <= this.visibleDate ||
    this.isHighBoundary && date >= this.visibleDate;
  }
  return result;
 },
 MakeDisabledStateItems: function() {
  var cells = this.GetAuxCells();
  for(var i = 0; i < cells.length; i++)
   this.AddAuxDisabledStateItem(cells[i], this.GetAuxId(i));
  var element = this.GetTitleCell();
  if(element)
   this.AddHeaderDisabledStateItem(element);
  var element = this.GetTitleElement();
  if(element)
   this.AddHeaderDisabledStateItem(element);
 },
 AddAuxDisabledStateItem: function(element, id) {
  var cell = this.calendar.GetEtalonStyleCell("DD");
  element.id = id;
  ASPx.GetStateController().AddDisabledItem(id, cell.className, cell.style.cssText, null, null, null);
 },
 AddHeaderDisabledStateItem: function(element) {
  var cell = this.calendar.GetEtalonStyleCell("DD");
  ASPx.GetStateController().AddDisabledItem(element.id, cell.className, cell.style.cssText, null, null, null);
 },
 ChangeEnabledAttributes: function(enabled) {
  var element = this.GetPrevYearCell();
  if(element)
   this.ChangeButtonEnabledAttributes(element, ASPx.Attr.ChangeAttributesMethod(enabled));
  var element = this.GetPrevMonthCell();
  if(element)
   this.ChangeButtonEnabledAttributes(element, ASPx.Attr.ChangeAttributesMethod(enabled));
  var element = this.GetTitleElement();
  if(element) {
   this.ChangeButtonEnabledAttributes(element, ASPx.Attr.ChangeAttributesMethod(enabled));
   this.ChangeTitleElementEnabledAttributes(element, ASPx.Attr.ChangeStyleAttributesMethod(enabled));
  }
  var element = this.GetNextMonthCell();
  if(element)
   this.ChangeButtonEnabledAttributes(element, ASPx.Attr.ChangeAttributesMethod(enabled));
  var element = this.GetNextYearCell();
  if(element)
   this.ChangeButtonEnabledAttributes(element, ASPx.Attr.ChangeAttributesMethod(enabled));
  if(this.calendar.enabled && !this.calendar.readOnly)
   this.AttachMouseEvents(ASPx.Attr.ChangeEventsMethod(enabled), ASPx.Attr.InitiallyChangeStyleAttributesMethod(enabled));
 },
 ChangeEnabledStateItems: function(enabled) {
  this.SetAuxCellsEnabled(enabled);
  this.SetHeaderCellsEnabled(enabled);
 },
 ChangeTitleElementEnabledAttributes: function(element, method) {
  method(element, "cursor");
 },
 ChangeButtonEnabledAttributes: function(element, method) {
  method(element, "onclick");
  method(element, "ondblclick");
 },
 SetAuxCellsEnabled: function(enabled) {
  var cells = this.GetAuxCells();
  for(var i = 0; i < cells.length; i++)
   ASPx.GetStateController().SetElementEnabled(cells[i], enabled);
 },
 SetHeaderCellsEnabled: function(enabled) {
  var element = this.GetPrevYearCell();
  if(element)
   ASPx.GetStateController().SetElementEnabled(element, enabled);
  var element = this.GetPrevMonthCell();
  if(element)
   ASPx.GetStateController().SetElementEnabled(element, enabled);
  var element = this.GetTitleCell();
  if(element)
   ASPx.GetStateController().SetElementEnabled(element, enabled);
  var element = this.GetTitleElement();
  if(element)
   ASPx.GetStateController().SetElementEnabled(element, enabled);
  var element = this.GetNextMonthCell();
  if(element)
   ASPx.GetStateController().SetElementEnabled(element, enabled);
  var element = this.GetNextYearCell();
  if(element)
   ASPx.GetStateController().SetElementEnabled(element, enabled);
 },
 GetAuxCells: function() {
  if(this.auxCells == null) {
   this.auxCells = [];
   var table = this.GetMonthTable();
   for(var i = 0; i < table.rows.length; i++) {
    var row = table.rows[i];
    if(i == 0 && this.calendar.showDayHeaders) {
     for(var j = 0; j < row.cells.length; j++)
      this.auxCells.push(row.cells[j]);
    }
    if(i > 0 && this.calendar.showWeekNumbers)
     this.auxCells.push(row.cells[0]);
   }
  }
  return this.auxCells;
 },
 GetAuxId: function(index) {
  return this.calendar.name + "_AUX_" + this.row + "_" + this.column + "_" + index;
 }
});
ASPxClientCalendarView.DayInRangeClassName = "dxeDayInRange";
var ASPxClientCalendarFastNavigation = ASPx.CreateClass(null, {
 constructor: function(calendar) {
  this.calendar = calendar;
  this.activeMonth = -1;
  this.activeYear = -1;
  this.startYear = -1;
  this.activeView = null;
  this.partialId = "FNP";
  this.InitializeUI();  
 },
 InitializeUI: function() {
  var item;
  var prefix = this.GetId();
  for(var m = 0; m < 12; m++) {
   item = this.GetMonthItem(m);
   if(!ASPx.IsExistsElement(item))
    break;
   item.id = prefix + "_M" + m;
   ASPx.Evt.AttachEventToElement(item, "click", ASPxClientCalendar.AnonymousHandlers.FastNavMonthClick(this.calendar.name, m));
  }
  for(var i = 0; i < 10; i++) {
   item = this.GetYearItem(i);
   if(!ASPx.IsExistsElement(item))
    break;   
   item.id = prefix + "_Y" + i;
   ASPx.Evt.AttachEventToElement(item, "click", ASPxClientCalendar.AnonymousHandlers.FastNavYearClick(this.calendar.name, i));
  }
  ASPx.Evt.AttachEventToElement(this.GetPopup().GetWindowElement(-1), "click", ASPxClientCalendar.AnonymousHandlers.MainElementClick(this.calendar.name));
 },
 Show: function() {
  this.GetPopup().ShowAtElement(this.activeView.GetTitleElement());
 },
 Hide: function() {
  this.GetPopup().Hide();
 },
 SetMonth: function(month) {
  if(month != this.activeMonth) {
   var prevCell = this.GetMonthItem(this.activeMonth);
   var cell = this.GetMonthItem(month);
   if(ASPx.IsExistsElement(prevCell))
    this.ApplyItemStyle(prevCell, false, "M");
   this.ApplyItemStyle(cell, true, "M");
   this.activeMonth = month;   
  } 
 },
 ShiftMonth: function(offset) {
  var month = (this.activeMonth + offset) % 12;
  month = (month < 0) ? month + 12 : month;
  this.SetMonth(month);
 },
 SetYear: function(year) {
  var startYear = Math.floor(year / 10) * 10;
  this.SetStartYear(startYear);
  this.SetYearIndex(year - startYear);
 },
 SetYearIndex: function(index) {
  var prevIndex = this.activeYear - this.startYear;
  if(index != prevIndex) {
   var prevCell = this.GetYearItem(prevIndex);
   if(ASPx.IsExistsElement(prevCell))
    this.ApplyItemStyle(prevCell, false, "Y");
   var cell = this.GetYearItem(index);
   this.ApplyItemStyle(cell, true, "Y");
   this.activeYear = index + this.startYear;
  } 
 },
 SetStartYear: function(year) {
  if(this.startYear == year) return;
  this.startYear = year;  
  this.PrepareYearList();
 },
 ShiftYear: function(offset) {
  if(this.activeYear + offset > 99 && this.activeYear + offset < 9999)
   this.SetYear(this.activeYear + offset);
 },
 ShiftStartYear: function(offset) {
  this.SetStartYear(this.startYear + offset);
 },
 ApplyChanges: function() {
  this.GetPopup().Hide();  
  var offset = ASPxClientCalendar.GetOffsetInMonths(this.calendar.visibleDate, new Date(this.activeYear, this.activeMonth, 1));
  offset -= this.activeView.row * this.calendar.columns + this.activeView.column;  
  if(offset != 0) {
   var date = ASPxClientCalendar.AddMonths(this.calendar.visibleDate, offset);
   this.calendar.OnVisibleMonthChanged(date);  
  }
  this.calendar.OnMainElementClick();
 },
 CancelChanges: function() {
  this.GetPopup().Hide();
  this.calendar.OnMainElementClick();
 },
 Prepare: function() {
  var date = this.activeView.visibleDate;
  this.activeYear = date.getFullYear();
  this.activeMonth = date.getMonth();
  this.startYear = ASPxClientCalendar.GetDecadeStartYear(this.activeYear);
  this.PrepareMonthList();
  this.PrepareYearList();
 }, 
 PrepareMonthList: function() {  
  var item;
  for(var month = 0; month < 12; month++) {
   item = this.GetMonthItem(month);
   if(item == null)
    return;
   this.ApplyItemStyle(item, month == this.activeMonth, "M");
  }  
 },
 PrepareYearList: function() {
  var year = this.startYear;
  var item;
  for(var index = 0; index < 10; index++) {
   item = this.GetYearItem(index);
   if(item == null)
    return;
   item.innerHTML = year;
   this.ApplyItemStyle(item, year == this.activeYear, "Y");
   year++;
  }   
  this.PreparePreviousYearListCell();
  this.PrepareNextYearListCell();
 },
 PreparePreviousYearListCell: function() {
  var yearListTable = this.GetChildElement("y");
  if(!ASPx.IsExistsElement(yearListTable))
   return;
  var isEnabledDate = this.startYear > 100;
  var prevYearListCell = yearListTable.rows[0].cells[0];
  var isPrevYearListCellVisible = ASPx.GetElementVisibility(prevYearListCell);
  if(isPrevYearListCellVisible != isEnabledDate)
   ASPx.SetElementVisibility(prevYearListCell, isEnabledDate);
 },
 PrepareNextYearListCell: function() {
  var yearListTable = this.GetChildElement("y");
  if(!ASPx.IsExistsElement(yearListTable))
   return;
  var firstYearListRow = yearListTable.rows[0];
  var nextYearListCell = firstYearListRow.cells[firstYearListRow.cells.length - 1];
  var isLastYear = this.startYear + 9 == 9999;
  ASPx.SetElementVisibility(nextYearListCell, !isLastYear);  
 },
 GetMonthItem: function(month) {
  var t = this.GetChildElement("m");
  if(!ASPx.IsExistsElement(t))
   return null;
  var colIndex = month % 4;
  var rowIndex = (month - colIndex) / 4;
  return t.rows[rowIndex].cells[colIndex];
 },
 GetYearItem: function(index) {
  var t = this.GetChildElement("y");
  if(!ASPx.IsExistsElement(t) || index < 0 || index > 9)
   return null;
  var colIndex = index % 5;
  var rowIndex = (index - colIndex) / 5;
  if(rowIndex == 0)
   colIndex++;
  return t.rows[rowIndex].cells[colIndex];
 },
 GetPopup: function() {
  return ASPx.GetControlCollection().Get(this.GetId());
 },
 ApplyItemStyle: function(item, isSelected, type) {
  var info = new ASPxClientCalendarStyleInfo();
  this.calendar.ImportEtalonStyle(info, "FN" + type);
  if(isSelected)
   this.calendar.ImportEtalonStyle(info, "FN" + type + "S");
  info.Apply(item);  
 },
 GetChildElement: function(postfix) { 
  return this.calendar.GetChildElement(this.partialId + "_" + postfix);
 },
 GetId: function() {
  return this.calendar.name + "_" + this.partialId;
 },
 OnArrowUp: function(evt) {
  if(evt.shiftKey)
   this.ShiftMonth(-4);
  else
   this.ShiftYear(-5);
 },
 OnArrowDown: function(evt) {  
  if(!evt.shiftKey)
   this.ShiftYear(5);
  else
   this.ShiftMonth(4);
 },
 OnArrowLeft: function(evt) { 
  if(evt.shiftKey)
   this.ShiftMonth(-1);
  else
   this.ShiftYear(-1);
 },
 OnArrowRight: function(evt) {
  if(!evt.shiftKey)
   this.ShiftYear(1);
  else
   this.ShiftMonth(1);
 },
 OnPageUp: function(evt) {
  this.ShiftYear(-10);
 },
 OnPageDown: function(evt) {
  this.ShiftYear(10);
 },
 OnEnter: function() {
  this.ApplyChanges();
 },
 OnEscape: function() {
  this.CancelChanges();
 },
 OnMonthClick: function(month) {
  this.SetMonth(month);
 },
 OnYearClick: function(index) {
  this.SetYearIndex(index);
 },
 OnYearShuffle: function(offset) {
  this.ShiftStartYear(offset);
 },
 OnOkClick: function() {
  this.ApplyChanges();
 },
 OnCancelClick: function() {
  this.CancelChanges();
 }
});
var ASPxClientCalendarStyleInfo = ASPx.CreateClass(null, {
 constructor: function() {
  this.className = "";
  this.cssText = "";
 },
 Clone: function() {
  var clone = new ASPxClientCalendarStyleInfo();
  clone.className = this.className;
  clone.cssText = this.cssText;
  return clone;
 },
 Apply: function(element) {
  if(element.className != this.className)
   element.className = this.className;
  if(element._style != this.cssText) {
   element.style.cssText = this.cssText; 
   element._style = this.cssText; 
  } 
 },
 Remove: function(element) {
  ASPx.RemoveClassNameFromElement(element, this.className);
  var styleRules = this.cssText.split(";");
  for(var i = 0; i < styleRules.length; i++) {
   var styleRule = styleRules[i];
   if(styleRule && element.style.cssText.indexOf(styleRule) !== -1)
    element.style.cssText = element.style.cssText.replace(styleRule, "");
  }
  element.style.cssText = element.style.cssText.replace(new RegExp(";+"), ";");
 },
 Import: function(element) {
  if(element.className.length > 0) {
   if(this.className.length > 1)
    this.className += " ";
   this.className +=  element.className;
  }  
  var cssText = element.style.cssText;
  if(cssText.length > 0) {
   var pos = cssText.length - 1;
   while(pos > -1 && cssText.charAt(pos) == " ")
    --pos;
   if(cssText.charAt(pos) != ";")
    cssText += ";";
   this.cssText += cssText;
  }
 }  
});
var ASPxClientCalendarSelectionEventArgs = ASPx.CreateClass(ASPxClientProcessingModeEventArgs, {
 constructor: function(processOnServer, selection){
  this.constructor.prototype.constructor.call(this, processOnServer);
  this.selection = selection;
 }
});
var ASPxDaysSelectingOnMouseOverEventArgs = ASPx.CreateClass(ASPxClientEventArgs, {
 constructor: function (overDate) {
  this.constructor.prototype.constructor.call(this);
  this.overDate = overDate;
 }
});
function aspxCalDocMouseUp(evt) {
 var target = ASPx.Evt.GetEventSource(evt);
 if(ASPx.activeCalendar != null && ASPx.IsExistsElement(target)) {
  ASPx.activeCalendar.forceMouseDown = false;
  if(ASPx.activeCalendar.isMouseDown) {   
   for(var key in ASPx.activeCalendar.views) {   
    var view = ASPx.activeCalendar.views[key];
    if(view.constructor != ASPxClientCalendarView) continue;
    var monthCell = view.GetMonthCell();
    var parent = target.parentNode;
    while(ASPx.IsExistsElement(parent)) {
     if(parent == monthCell)
      return;
     parent = parent.parentNode;
    }
   }
   ASPx.activeCalendar.OnSelectionCancelled();   
  }
  ASPx.activeCalendar = null;
 }
}
function aspxCalCancelSelect() {
 if(ASPx.activeCalendar != null) {
  ASPx.activeCalendar.forceMouseDown = false;
  ASPx.activeCalendar.OnSelectionCancelled();  
 }
}
ASPx.CalShiftMonth = function(name, monthOffset) {
 if(monthOffset != 0) {
  var edit = ASPx.GetControlCollection().Get(name);
  if(edit != null) {
   edit.OnShiftMonth(monthOffset);
  }
 }
}
ASPx.CalTodayClick = function(name) { 
 var edit = ASPx.GetControlCollection().Get(name);
 if(edit != null)
  edit.OnTodayClick();
}
ASPx.CalClearClick = function(name) { 
 var edit = ASPx.GetControlCollection().Get(name);
 if(edit != null)
  edit.OnClearClick();
}
ASPx.CalTitleClick = function(name, row, column) {
 var edit = ASPx.GetControlCollection().Get(name);
 if(edit != null)
  edit.OnTitleClick(row, column);
}
ASPx.CalFNYShuffle = function(name, offset) {
 var edit = ASPx.GetControlCollection().Get(name);
 if(edit != null)
  edit.fastNavigation.OnYearShuffle(offset);
}
ASPx.CalFNBClick = function(name, action) {
 var edit = ASPx.GetControlCollection().Get(name);
 if(edit != null) {
  switch(action) {
   case "ok":
    edit.fastNavigation.OnOkClick(); 
    break;
   case "cancel":
    edit.fastNavigation.OnCancelClick();
    break;
  }    
 }
}
window.ASPxClientCalendar = ASPxClientCalendar;
window.ASPxClientCalendarCustomDisabledDateEventArgs = ASPxClientCalendarCustomDisabledDateEventArgs;
window.ASPxClientCalendarSelection = ASPxClientCalendarSelection;
window.ASPxClientCalendarDateDisabledHelper = ASPxClientCalendarDateDisabledHelper;
window.ASPxClientCalendarStyleInfo = ASPxClientCalendarStyleInfo;
window.ASPxClientCalendarSelectionEventArgs = ASPxClientCalendarSelectionEventArgs;
})();
