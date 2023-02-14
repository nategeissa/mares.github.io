(function() {
var calendarNameSuffix = "_C";
var timeEditNameSiffix = calendarNameSuffix + "_TE";
var clockNameSiffix = calendarNameSuffix + "_CL";
var DefaultMinMaxRangeValues = {
 Min: 0,
 Max: 922337203685477
};
var ASPxDateRangeHelper = {
 GetCurrentRangeRestrictions: function(dateRangePair) {
  if (dateRangePair.isInRangeMode)
  return {
   startDate: dateRangePair.startDateEdit.GetDate(),
   endDate: dateRangePair.endDateEdit.GetDate()
  }
  else
   return {
    startDate: null,
    endDate: null
   }
 },
 IsBothRangeRestrictionsExist: function (rangeRestricts) {
  return rangeRestricts.startDate && rangeRestricts.endDate;
 },
 IsNegativeRange: function (rangeRestricts) {
  return this.IsBothRangeRestrictionsExist(rangeRestricts)
   && rangeRestricts.startDate > rangeRestricts.endDate;
 },
 IsOneRestrictionExistsOnly: function (rangeRestricts) {
  return this.IsStartRestrictionExistsOnly(rangeRestricts)
   || this.IsEndRestrictionExistsOnly(rangeRestricts);
 },
 IsStartRestrictionExistsOnly: function (rangeRestricts) {
  return rangeRestricts.startDate && !rangeRestricts.endDate;
 },
 IsEndRestrictionExistsOnly: function (rangeRestricts) {
  return !rangeRestricts.startDate && rangeRestricts.endDate;
 },
 AreRestrictionsOfSameMonth: function (rangeRestricts) {
  return this.IsBothRangeRestrictionsExist(rangeRestricts)
   && ASPxClientCalendar.AreDatesOfSameMonth(rangeRestricts.startDate, rangeRestricts.endDate);
 },
 GetFullDaysInCurrentRange: function (dateRangePair) {
  var result = -1;
  var rangeRestricts = this.GetCurrentRangeRestrictions(dateRangePair);
  if (this.IsBothRangeRestrictionsExist(rangeRestricts) && !this.IsNegativeRange(rangeRestricts)) {
   var timezoneOffsetDifference = rangeRestricts.startDate.getTimezoneOffset() - rangeRestricts.endDate.getTimezoneOffset();
   var rangeLength = rangeRestricts.endDate - rangeRestricts.startDate + timezoneOffsetDifference * 60000;
   result = Math.floor(rangeLength / ASPx.calendarMsPerDay);
  }
  return result;
 },
 NeedCorrectSecondDateOnDateChanging: function (rangeRestricts, isStartDateChanged, minRange) {
  if (this.IsNegativeRange(rangeRestricts))
   return true;
  var isSecondDateEmpty = isStartDateChanged && this.IsStartRestrictionExistsOnly(rangeRestricts)
   || !isStartDateChanged && this.IsEndRestrictionExistsOnly(rangeRestricts);
  return isSecondDateEmpty && minRange > 0;
 },
 GetDateEditPair: function(currentDateEdit) {
  if(currentDateEdit.IsInDateRangeMode()) {
   var startDE = currentDateEdit.GetStartDateEdit();
   startDE = (startDE == null) ? currentDateEdit : startDE;
   var endDE = startDE.endDateEdit;
   var isCurrentDateEditStart = currentDateEdit === startDE;
   return {
    startDateEdit: startDE,
    endDateEdit: endDE,
    isStart: isCurrentDateEditStart,
    isInRangeMode: true
   }
  }
  else
   return {
    startDateEdit: currentDateEdit,
    endDateEdit: null,
    isStart: true,
    isInRangeMode: false
   }
 }
};
var DateRangeValidationPattern = ASPx.CreateClass(ASPx.ValidationPattern, {
 constructor: function (startDateEdit, endDateEdit) {
  this.constructor.prototype.constructor.call(this, endDateEdit.invalidDateRangeErrorText);
  this.startDateEdit = startDateEdit;
  this.endDateEdit = endDateEdit;
 },
 EvaluateIsValid: function(value) {
  var dateEditPair = ASPxDateRangeHelper.GetDateEditPair(this.startDateEdit);
  var rangeRestricts = ASPxDateRangeHelper.GetCurrentRangeRestrictions(dateEditPair);
  if (this.endDateEdit.IsDateChangeProcessing()
   && ASPxDateRangeHelper.NeedCorrectSecondDateOnDateChanging(rangeRestricts, false, this.endDateEdit.minRange))
   return true;
  if (ASPxDateRangeHelper.IsOneRestrictionExistsOnly(rangeRestricts))
   return false;
  if (ASPxDateRangeHelper.IsBothRangeRestrictionsExist(rangeRestricts)) {
   var currentDateRange = rangeRestricts.endDate - rangeRestricts.startDate;
   return currentDateRange >= this.endDateEdit.minRange && currentDateRange <= this.endDateEdit.maxRange;
  }
  return true;
 }
});
var ASPxClientDateEdit = ASPx.CreateClass(ASPxClientDropDownEditBase, {
 constructor: function(name) {
  this.constructor.prototype.constructor.call(this, name);
  this.dateFormatter = null;
  this.isASPxClientDateEdit = true;
  this.date = null;
  this.dateOnError = "u";
  this.allowNull = true;
  this.calendarOwnerName = null;
  this.calendarConsumerName = null;
  this.textWasLastTemporaryChanged = false;
  this.showTimeSection = false;
  this.adjustInnerControls = true;
  this.pasteTimerID = -1;
  this.keyUpProcessing = false;
  this.showOutOfRangeWarning = true;
  this.startDateEditName = "";
  this.minRange = DefaultMinMaxRangeValues.Min;
  this.maxRange = DefaultMinMaxRangeValues.Max;
  this.sharedParameters = new ASPx.CalendarSharedParameters();
  this.endDateEdit = null;
  this.DateChanged = new ASPxClientEvent();
  this.ParseDate = new ASPxClientEvent();
  this.CalendarCustomDisabledDate = new ASPxClientEvent();
  this.CalendarShowing = new ASPxClientEvent();
  this.ValueSet = new ASPxClientEvent();
 },
 InitializeProperties: function(properties){
  ASPxClientTextEdit.prototype.InitializeProperties.call(this, properties);
  if(properties.sharedParameters)
   this.SetProperties(properties.sharedParameters, this.sharedParameters);
 },
 Initialize: function() {
  if(this.HasOwnedCalendar()) {
   this.InitializeCalendarHandlers();
   this.InitializeTimeEditHandlers();
  } else 
   this.RegisterSharedCalendar();  
  ASPxClientDropDownEditBase.prototype.Initialize.call(this);
  var startDateEdit = this.GetStartDateEdit();
  if(startDateEdit) {
   if(this.MinOrMaxRangeExist())
    this.validationPatterns.push(new DateRangeValidationPattern(startDateEdit, this));
   this.AssignDateRangeMode(startDateEdit);
  }
  this.AttachToDateEditClientEvents();
  this.InitializeSharedParameters();
  var calendar = this.GetCalendar();
  if (calendar)
   calendar.customDraw = calendar.customDraw || this.sharedParameters.calendarCustomDraw;
 },
 AssignDateRangeMode: function(startDateEdit) {
  this.PrepareCalendarsToDateRangeMode(startDateEdit);
  this.ownMinDate = this.GetMinDate();
  this.SetActualMinDate();
 },
 PrepareCalendarsToDateRangeMode: function(startDateEdit) {
  startDateEdit.endDateEdit = this;
  this.SetCalendarDateRangeMode(startDateEdit);
  this.SetCalendarDateRangeMode(this);
 },
 SetCalendarDateRangeMode: function(dateEdit) {
  var isOperaOrIEVersionHigher8 = ASPx.Browser.IE && ASPx.Browser.Version > 8 || ASPx.Browser.Opera;
  dateEdit.sharedParameters.dateRangeMode = true;
  var calendar = dateEdit.GetCalendar();
  calendar.updateDayStylesTwiceOnMouseOver = isOperaOrIEVersionHigher8 && this.DateEditHasParentWithRelativePosition(this);
 },
 IsInDateRangeMode: function() {
  var startDateEdit = this.GetStartDateEdit();
  return startDateEdit !== null || this.endDateEdit !== null;
 },
 DateEditHasParentWithRelativePosition: function(dateEdit) {
  return ASPx.GetParent(dateEdit.GetMainElement(),
   function (element) { return ASPx.GetCurrentStyle(element).position === "relative"; }) != null;
 },
 MinOrMaxRangeExist: function() {
  return this.minRange !== DefaultMinMaxRangeValues.Min || this.maxRange !== DefaultMinMaxRangeValues.Max;
 },
 AttachToDateEditClientEvents: function() {
  this.DateChanged.AddHandler(function(s, e) {
   if(!e.isInternal)
    this.OnRangeRestrictionChanged(s);
  }.aspxBind(this));
  this.CalendarShowing.AddHandler(function(s, e) {
   this.OnCalendarShowing(s);
  }.aspxBind(this));
  this.ValueSet.AddHandler(function(s, e) {
   this.SetActualMinDate();
  }.aspxBind(this));
 },
 InitializeSharedParameters: function() {
  this.sharedParameters.currentDateEdit = this;
  this.sharedParameters.DaysSelectingOnMouseOver.AddHandler(function(s, e) {
   this.OnCalendarDayMouseOver(s, e);
  }.aspxBind(this));
  this.sharedParameters.VisibleDaysMouseOut.AddHandler(function(s, e) {
   this.SelectRangeInCalendar(s, false);
  }.aspxBind(this));
  if(this.GetShowTimeSection())
   this.sharedParameters.CalendarSelectionChangedInternal.AddHandler(function(s, e) {
    this.SelectRangeInCalendar(s, false);
   }.aspxBind(this));
 },
 OnCalendarDayMouseOver: function(targetCalendar, e) {
  var dateRangePair = ASPxDateRangeHelper.GetDateEditPair(ASPxClientDateEdit.active);
  if(!dateRangePair.isInRangeMode) {
   e.cancel = true;
   return;
  }
  var rangeRestricts = ASPxDateRangeHelper.GetCurrentRangeRestrictions(dateRangePair);
  var isRangeNegative = ASPxDateRangeHelper.IsNegativeRange(rangeRestricts);
  if (!isRangeNegative) {
   var requiredStartDate = dateRangePair.isStart ? rangeRestricts.endDate : rangeRestricts.startDate;
   e.selectionStartDate = requiredStartDate ? ASPxClientCalendar.CloneDate(requiredStartDate) : null;
   var isOverDateCorrectForSelection = e.selectionStartDate
    && (dateRangePair.isStart && e.selectionStartDate >= e.overDate
    || !dateRangePair.isStart && e.selectionStartDate <= e.overDate);
  }
  e.cancel = isRangeNegative || !e.selectionStartDate || !isOverDateCorrectForSelection;
 },
 OnCalendarShowing: function() {
  var dateRangePair = ASPxDateRangeHelper.GetDateEditPair(ASPxClientDateEdit.active);
  if(!dateRangePair.isInRangeMode)
   return;
  var targetCalendar = ASPxClientDateEdit.active.GetCalendar();
  if(!targetCalendar)
   return;
  this.UpdateCalendarVisibleDate(targetCalendar, dateRangePair);
  this.SetActualMinDate();
  this.SelectRangeInCalendar(targetCalendar, true);
 },
 GetRangeToSelectInCalendar: function(targetCalendar, dateRangePair, isCalendarShowing) {
  var rangeRestricts = ASPxDateRangeHelper.GetCurrentRangeRestrictions(dateRangePair);
  var calendarHasOwnSelectedDate = targetCalendar.lastSelectedDate != null;
  var correctRangeRestrictsForSelection = !isCalendarShowing && calendarHasOwnSelectedDate;
  if (correctRangeRestrictsForSelection) {
   var calendarLastSelectedDate = ASPxClientCalendar.CloneDate(targetCalendar.lastSelectedDate);
   if (dateRangePair.isStart)
    rangeRestricts.startDate = calendarLastSelectedDate;
   else
    rangeRestricts.endDate = calendarLastSelectedDate;
  }
  return rangeRestricts;
 },
 SelectRangeInCalendar: function(targetCalendar, isCalendarShowing) {
  var dateRangePair = ASPxDateRangeHelper.GetDateEditPair(ASPxClientDateEdit.active);
  if(!dateRangePair.isInRangeMode)
   return;
  var rangeRestrictsToSelect = this.GetRangeToSelectInCalendar(targetCalendar, dateRangePair, isCalendarShowing);
  if(ASPxDateRangeHelper.IsNegativeRange(rangeRestrictsToSelect))
   return;
  targetCalendar.clientUpdate = true;
  targetCalendar.LockUpdateAnimation();
  targetCalendar.ClearSelection();
  if(ASPxDateRangeHelper.IsBothRangeRestrictionsExist(rangeRestrictsToSelect))
   targetCalendar.SelectRange(rangeRestrictsToSelect.startDate, rangeRestrictsToSelect.endDate);
  if(ASPxDateRangeHelper.IsEndRestrictionExistsOnly(rangeRestrictsToSelect))
   targetCalendar.SelectDate(rangeRestrictsToSelect.endDate);
  if(ASPxDateRangeHelper.IsStartRestrictionExistsOnly(rangeRestrictsToSelect))
   targetCalendar.SelectDate(rangeRestrictsToSelect.startDate);
  targetCalendar.UnlockUpdateAnimation();
  targetCalendar.Update();
  targetCalendar.clientUpdate = false;
 },
 UpdateCalendarVisibleDate: function(targetCalendar, dateRangePair) {
  var rangeRestricts = ASPxDateRangeHelper.GetCurrentRangeRestrictions(dateRangePair);
  if (ASPxDateRangeHelper.IsStartRestrictionExistsOnly(rangeRestricts) && !dateRangePair.isStart) {
   targetCalendar.SetVisibleDate(rangeRestricts.startDate);
  }
  if (ASPxDateRangeHelper.IsEndRestrictionExistsOnly(rangeRestricts)
   || ASPxDateRangeHelper.IsBothRangeRestrictionsExist(rangeRestricts) && !dateRangePair.isStart) {
   targetCalendar.SetVisibleDate(rangeRestricts.endDate);
   if (!ASPxDateRangeHelper.AreRestrictionsOfSameMonth(rangeRestricts))
    targetCalendar.OnShiftMonth(-1 * (targetCalendar.columns - 1));
  }
 },
 SetActualMinDate: function() {
  var dateRangePair = ASPxDateRangeHelper.GetDateEditPair(this);
  if(!dateRangePair.isInRangeMode) return;
  var rangeRestricts = ASPxDateRangeHelper.GetCurrentRangeRestrictions(dateRangePair);
  if(!dateRangePair.isStart)
   dateRangePair.endDateEdit.SetMinDateCore(rangeRestricts.startDate ? rangeRestricts.startDate : dateRangePair.endDateEdit.ownMinDate);
 },
 OnRangeRestrictionChanged: function() {
  var dateRangePair = ASPxDateRangeHelper.GetDateEditPair(this);
  if(!dateRangePair.isInRangeMode) return;
  var rangeRestricts = ASPxDateRangeHelper.GetCurrentRangeRestrictions(dateRangePair);
  if (ASPxDateRangeHelper.NeedCorrectSecondDateOnDateChanging(rangeRestricts, dateRangePair.isStart, dateRangePair.endDateEdit.minRange))
   this.CorrestSecondRangeDate(dateRangePair);
  if(dateRangePair.isStart)
   dateRangePair.endDateEdit.Validate();
  else {
   dateRangePair.endDateEdit.SetActualMinDate();
   dateRangePair.startDateEdit.Validate();
  }
 },
 CorrestSecondRangeDate: function(dateRangePair) {
  var changedDate = (dateRangePair.isStart) ? dateRangePair.startDateEdit.GetDate() : dateRangePair.endDateEdit.GetDate();
  var secondDate = ASPxClientCalendar.CloneDate(changedDate);
  var dateDifference = dateRangePair.isStart ? dateRangePair.endDateEdit.minRange : (-1) * dateRangePair.endDateEdit.minRange;
  var secondDateEdit = dateRangePair.isStart ? dateRangePair.endDateEdit : dateRangePair.startDateEdit;
  secondDate.setMilliseconds(secondDate.getMilliseconds() + dateDifference);
  secondDateEdit.SetDate(secondDate);
  secondDateEdit.RaiseValueChangedEvent(true);
 },
 InitializeCalendarHandlers: function() {
  var calendar = this.GetCalendar();
  if (calendar) {
   calendar.SelectionChanging.AddHandler(ASPxClientDateEdit.HandleCalendarSelectionChanging);
   calendar.MainElementClick.AddHandler(ASPxClientDateEdit.HandleCalendarMainElementClick);
   this.AssignCalendarDisabledDateHandler(calendar);
   var calendarMainElement = calendar.GetMainElement();
   if(ASPx.Browser.NetscapeFamily && ASPx.IsExistsElement(calendarMainElement))
    calendarMainElement.style.borderCollapse = "separate";
  }
 },
 AssignCalendarDisabledDateHandler: function(calendar) {
  calendar.CustomDisabledDate.AddHandler(ASPxClientDateEdit.HandleCalendarCustomDisabledDate.aspxBind(this));
 },
 InitializeTimeEditHandlers: function() {
  var timeEdit = this.GetTimeEdit();
  if(timeEdit) {
   timeEdit.InternalValueChanging.AddHandler(ASPxClientDateEdit.HandleTimeEditInternalValueChanging);
   timeEdit.OwnerDateEdit = this;
  }
 },
 RegisterSharedCalendar: function() {
  var calendar = this.GetCalendar();
  if(calendar) {
   ASPxClientDateEdit.SharedCalendarCollection.registerCalendarId(calendar.name);
  }   
 },
 HasOwnedCalendar: function() {
  return this.calendarOwnerName == null;
 },
 InlineInitialize: function(){
  this.InitSpecialKeyboardHandling();
  ASPxClientDropDownEditBase.prototype.InlineInitialize.call(this);
  this.lastValue = this.GetInputElement().value;
  if (this.UseRestrictions() && this.showOutOfRangeWarning)
   this.EnsureOutOfRangeWarningManager();
 },
 GetStartDateEdit: function() {
  return this.startDateEditName ? ASPx.GetControlCollection().Get(this.startDateEditName) : null;
 },
 CloseDropDownByDocumentOrWindowEvent: function(causedByWindowResizing) {
  if((!causedByWindowResizing || !this.pcIsShowingNow) && this.GetShowTimeSection())
   this.ApplyTimeSectionDateChanges();
  ASPxClientDropDownEditBase.prototype.CloseDropDownByDocumentOrWindowEvent.call(this, causedByWindowResizing);
 },
 UseRestrictions: function() {
  return this.GetMinDate() || this.GetMaxDate();
 },
 OnDropDownCore: function(evt) {
  var cal = this.GetCalendar();
  if(!cal) return;
  ASPxClientDropDownEditBase.prototype.OnDropDownCore.call(this, evt);
  if(this.droppedDown) {
     cal.forceMouseDown = true;
  }
 },
 SetCalendarAndTimeSectionValues: function() {
  this.SetCurrentStateToCalendar();
  this.SetCurrentStateToTimeSection();
 },
 SetCurrentStateToCalendar: function() {
  var calendar = this.GetCalendar();
  if(!calendar) return;
  calendar.sharedParameters = this.sharedParameters;
  if(this.IsCalendarShared()) {
   calendar.CustomDisabledDate.ClearHandlers();
   this.AssignCalendarDisabledDateHandler(calendar);
  }
  calendar.forceUpdate = true;
  if (!this.date) {
   calendar.SetValue(null);
   var currentDate = new Date();
   currentDateWithoutTime = new Date(currentDate.getFullYear(), currentDate.getMonth(), currentDate.getDate());
   calendar.SetVisibleDate(currentDateWithoutTime);
  }
  else {
   var dateWithoutTime = new Date(this.date.getFullYear(), this.date.getMonth(), this.date.getDate())
   calendar.SetValue(dateWithoutTime);
  }
 },
 CreateUpdateCallback: function(result) {
  this.CreateCallback(this.sharedParameters.GetUpdateCallbackParameters());
 },
 OnCallback: function(result) {
  var calendar = this.GetCalendar();
  if(calendar != null)
   calendar.OnCallback(result);
 },
 SetCurrentStateToTimeSection: function() {
  if(this.GetShowTimeSection()) {
   var timeEdit = this.GetTimeEdit();
   if(timeEdit)
    timeEdit.SetValue(this.GetDateForTimeEdit());
  }
 },
 ShowDropDownArea: function(isRaiseEvent){
  this.SetActiveControl();
  this.SetCalendarAndTimeSectionValues();
  this.CalendarShowing.FireEvent(this);
  ASPxClientDropDownEditBase.prototype.ShowDropDownArea.call(this, isRaiseEvent);
  var calendarOwner = this.GetCalendarOwner();
  if(calendarOwner != null)
   calendarOwner.calendarConsumerName = this.name;
  this.calendarConsumerName = null;
 },
 GetDateForTimeEdit: function() {
  if (this.date)
   return this.date;
  var date = new Date();
  date.setHours(0);
  date.setMinutes(0);
  date.setSeconds(0);
  date.setMilliseconds(0);
  return date;
 },
 IsCalendarShared: function () {
  var calendar = this.GetCalendar();
  var calendarName = calendar != null ? calendar.name : ""; 
  return ASPxClientDateEdit.SharedCalendarCollection.calendarIsShared(calendarName);
 },
 SetActiveControl: function() {
  var calendar = this.GetCalendar();
  ASPx.activeCalendar = calendar;
  ASPxClientDateEdit.active = this;
 },
 BeforePopupControlResizing: function() {
  var calendarOwner = this;
  if(this.calendarOwnerName)
   calendarOwner = this.GetCalendarOwner();
  if(calendarOwner.adjustInnerControls && calendarOwner.GetTimeEdit()){
   calendarOwner.GetClock().AdjustControl();
   calendarOwner.GetTimeEdit().AdjustControl();
   calendarOwner.adjustInnerControls = false;
  }
 },
 GetPopupControl: function() { 
  var calendarOwner = this.GetCalendarOwner();
  if(calendarOwner != null)
   return calendarOwner.GetPopupControl();
  return ASPxClientDropDownEditBase.prototype.GetPopupControl.call(this);
 },
 OnPopupControlShown: function() {
  if(this.calendarConsumerName != null)
   ASPx.GetControlCollection().Get(this.calendarConsumerName).OnPopupControlShown();
  else  
   ASPxClientDropDownEditBase.prototype.OnPopupControlShown.call(this);
 },
 GetCalendar: function() { 
  var name = this.GetDropDownInnerControlName(calendarNameSuffix);
  return ASPx.GetControlCollection().Get(name);
 },
 GetTimeEdit: function() { 
  var name = this.GetDropDownInnerControlName(timeEditNameSiffix);
  return ASPx.GetControlCollection().Get(name);
 },
 GetClock: function() {
  var name = this.GetDropDownInnerControlName(clockNameSiffix);
  return ASPx.GetControlCollection().Get(name);
 },
 GetCalendarOwner: function() {
  if(!this.calendarOwnerName)
   return null;
  return ASPx.GetControlCollection().Get(this.calendarOwnerName);
 },
 GetShowTimeSection: function(){
  var calendarOwner = this.GetCalendarOwner();
  if(calendarOwner)
   return calendarOwner.showTimeSection;
  return this.showTimeSection;
 },
 GetFormattedDate: function() {
  if(this.maskInfo != null)
   return this.maskInfo.GetValue();
  if(this.date == null)
   return this.focused ? "" : this.nullText;
  return this.dateFormatter.Format(this.date);
 },
 SetTextWasLastTemporaryChanged: function(value){
  this.textWasLastTemporaryChanged = value;
 },
 GetTextWasLastTemporaryChanged: function(){
  return this.textWasLastTemporaryChanged;
 },
 RaiseValueChangedEvent: function(isInternal) {
  if(!this.isInitialized) return false;
  var processOnServer = ASPxClientEdit.prototype.RaiseValueChangedEvent.call(this);
  processOnServer = this.RaiseDateChanged(processOnServer, isInternal);
  return processOnServer;
 },
 OnApplyChanges: function(){
  if(this.focused)
   this.OnTextChanged();
 },
 OnCalendarSelectionChanging: function(date, select) {
  if(this.GetShowTimeSection())
   return;
  if(!this.GetCalendar().isDateChangingByKeyboard) {
   this.HideDropDownArea(true);
   if(date != null)
    this.ApplyExistingTime(date);
   this.ChangeDate(date);
   if(select)
    ASPx.Selection.Set(this.GetInputElement());
   this.lastValue = this.GetInputElement().value;
  }
 },
 OnCalendarCustomDisabledDate: function(e) {
  this.RaiseCalendarCustomDisabledDate(e);
 },
 OnCustomDisabledDate: function(date) {
  return this.RaiseCustomDisabledDateEvent(date);
 },
 RaiseCustomDisabledDateEvent: function(date) {
  var args = new ASPxClientCalendarCustomDisabledDateEventArgs(date);
  this.CalendarCustomDisabledDate.FireEvent(this, args);
  return args;
 },
 ForceRefocusTimeSectionTimeEdit: function(mouseDownSource) {
  var dateEdit = this;
  if(this.calendarConsumerName)
   dateEdit = ASPx.GetControlCollection().Get(this.calendarConsumerName);
  var timeEdit = dateEdit.GetTimeEdit();
  var isTimeEditElement = timeEdit.IsEditorElement(mouseDownSource);
  if(isTimeEditElement && !timeEdit.IsElementBelongToInputElement(mouseDownSource)) { 
   if(!ASPx.Browser.VirtualKeyboardSupported) 
    timeEdit.ForceRefocusEditor();
   return;
  }
  if(!dateEdit.IsEditorElement(mouseDownSource)) {
   if(ASPx.Browser.VirtualKeyboardSupported && !isTimeEditElement) {
    this.lockLostFocus = false;
    if(ASPx.VirtualKeyboardUI.focusableInputElementIsActive(timeEdit)) {
     timeEdit.GetInputElement().blur();
    } else {
     ASPx.VirtualKeyboardUI.lostAppliedFocusOfEditor();
    }
   }
   return;
  }
  if(ASPx.Browser.VirtualKeyboardSupported) {
   this.lockLostFocus = true;
  } else {
   dateEdit.ForceRefocusEditor();
   var input = timeEdit.GetInputElement();
   if(input)
    input.blur();
   window.setTimeout(function() { ASPx.SetFocusedEditor(dateEdit); }, 0);
  }
 },
 ApplyTimeSectionDateChanges: function() {
  var hours = 0, minutes = 0, seconds = 0, milliseconds = 0;
  this.GetCalendar().EnsureSelectedDateIsActual();
  var date = this.GetCalendar().GetSelectedDate();
  this.GetTimeEdit().ParseValue();
  var timeEditDate = this.GetTimeEdit().GetDate();
  if(timeEditDate) {
   hours = timeEditDate.getHours();
   minutes = timeEditDate.getMinutes();
   seconds = timeEditDate.getSeconds();
   milliseconds = timeEditDate.getMilliseconds();
  }
  if(date) {
   date.setHours(hours);
   date.setMinutes(minutes);
   date.setSeconds(seconds);
   date.setMilliseconds(milliseconds);
  }
  this.ApplyParsedDate(date, true);
 },
 IsEditorElement: function(element) {
  var timeEdit = this.GetTimeEdit();
  if(this.GetShowTimeSection() && timeEdit && ASPx.GetIsParent(timeEdit.GetMainElement(), element)) {
   this.lockLostFocus = true;
   return false;
  }
  return ASPxClientDropDownEditBase.prototype.IsEditorElement.call(this, element);
 },
 OnFocus: function() {
  this.SetActiveControl();
  ASPxClientDropDownEditBase.prototype.OnFocus.call(this);
  if(!ASPx.GetControlCollection().InCallback())
   this.SetTextChangingTimer();
 },
 OnLostFocusCore: function() {
  if(this.GetShowTimeSection() && this.lockLostFocus) {
   this.lockLostFocus = false;
   return;
  }
  ASPxClientDropDownEditBase.prototype.OnLostFocusCore.call(this);
  this.ClearTextChangingTimer();
  if(this.outOfRangeWarningManager)
   this.outOfRangeWarningManager.HideOutOfRangeWarningElement();
 },
 OnTimeEditLostFocus: function() {
  this.OnLostFocusCore();
 },
 OnTimeEditEnter: function() {
  this.ForceRefocusEditor();
  this.ApplyTimeSectionDateChanges();
  this.HideDropDownArea(true);
  ASPx.Selection.Set(this.GetInputElement());
 },
 OnTimeEditEsc: function() {
  this.ForceRefocusEditor();
  this.HideDropDownArea(true);
 },
 OnTimeEditTab: function(shiftKey) {
  if(shiftKey && !this.GetCalendarOwner())
   this.ForceRefocusEditor();
  this.ApplyTimeSectionDateChanges();
  this.HideDropDownArea(true);
 },
 OnTimeSectionOkClick: function() {
  this.ApplyTimeSectionDateChanges();
  this.HideDropDownArea(true);
 },
 OnTimeSectionCancelClick: function() {
  this.HideDropDownArea(true);
 },
 OnTimeSectionClearClick: function() {
  this.ChangeDate(null);
  this.GetCalendar().ResetLastSelectedDate();
  this.HideDropDownArea(true);
 },
 OnTimeEditInternalValueChanging: function(date) {
  var clock = this.GetClock();
  if(clock)
   clock.SetDate(date);
 },
 OnArrowUp: function(evt){ 
  var isProcessed = ASPxClientDropDownEditBase.prototype.OnArrowUp.call(this, evt);
  if(!isProcessed && this.droppedDown)
   return this.OnCalendarMethod("OnArrowUp", evt);       
  return false;
 },
 OnArrowDown: function(evt){
  var isProcessed = ASPxClientDropDownEditBase.prototype.OnArrowDown.call(this, evt);
  if(!isProcessed && this.droppedDown)
   return this.OnCalendarMethod("OnArrowDown", evt);
  return false;
 },
 OnArrowLeft: function(evt){
  if(this.droppedDown) {
   this.OnCalendarMethod("OnArrowLeft", evt);
   return true;
  }
  return false;
 },
 OnArrowRight: function(evt){
  if(this.droppedDown) { 
   this.OnCalendarMethod("OnArrowRight", evt);
   return true;
  }
  return false;
 },
 OnPageUp: function(evt){
  if(this.droppedDown) { 
   this.OnCalendarMethod("OnPageUp", evt);
   return true;
  }
  return false;  
 },
 OnPageDown: function(evt){
  if(this.droppedDown) {
   this.OnCalendarMethod("OnPageDown", evt);
   return true;
  }
  return false;  
 },
 OnEndKeyDown: function(evt) {
  if(this.droppedDown) {
   this.OnCalendarMethod("OnEndKeyDown", evt);
   return true;
  }
  return false;
 },
 OnHomeKeyDown: function(evt) {
  if(this.droppedDown) {
   this.OnCalendarMethod("OnHomeKeyDown", evt);
   return true;
  }
  return false; 
 },
 OnCalendarMethod: function(methodName, evt){
  var calendar = this.GetCalendar();
  if(!calendar.IsFastNavigationActive())
   this.SetTextWasLastTemporaryChanged(false);
  return calendar[methodName](evt);
 },
 GetDateByCurrentValueString: function(valueString) {
  var inputValueParseResult = this.dateFormatter.Parse(valueString);
  return inputValueParseResult ? inputValueParseResult : null;
 },
 OnKeyDown: function(evt) {
  ASPxClientDropDownEditBase.prototype.OnKeyDown.call(this, evt);
  this.keyUpProcessing = true;
 },
 OnKeyUp: function(evt) {
  if(ASPx.FilteringUtils.EventKeyCodeChangesTheInput(evt)){
   this.SetTextWasLastTemporaryChanged(true);
   if (this.UseRestrictions() && this.outOfRangeWarningManager) {
    var valueString = this.GetInputElement().value;
    this.lastValue = valueString;
    var currentDate = this.GetDateByCurrentValueString(valueString);
    this.outOfRangeWarningManager.UpdateOutOfRangeWarningElementVisibility(currentDate);
   }
  }
  this.keyUpProcessing = false;
  this.EnsureClearButtonVisibility();
 },
 SetTextChangingTimer: function () {
  if(this.pasteTimerID === -1)
   this.pasteTimerID = ASPx.Timer.SetControlBoundInterval(this.OnTextChangingCheck, this, ASPx.PasteCheckInterval);
 },
 ClearTextChangingTimer: function () {
  this.pasteTimerID = ASPx.Timer.ClearInterval(this.pasteTimerID);
 },
 OnTextChangingCheck: function (evt) {
  var input = this.GetInputElement();
  if (!input)
   return;
  var curValueString = input.value.toString();
  if (this.lastValue != curValueString && !this.keyUpProcessing) {
   var isChromeOnAndroid = ASPx.Browser.AndroidMobilePlatform && ASPx.Browser.Chrome;
   if (!isChromeOnAndroid)
    this.OnPaste(curValueString);
  }
 },
 OnPaste: function (valueString) {
  this.lastValue = valueString;
  if (this.UseRestrictions() && this.outOfRangeWarningManager) {
   var currentDate = this.GetDateByCurrentValueString(valueString);
   this.outOfRangeWarningManager.UpdateOutOfRangeWarningElementVisibility(currentDate);
  }
 },
 OnEnter: function() {
  this.enterProcessed = false; 
  if(this.droppedDown) {
   var calendar = this.GetCalendar();
   if(calendar.IsFastNavigationActive())
    calendar.GetFastNavigation().OnEnter();
   else if(this.GetTextWasLastTemporaryChanged()){
    this.ParseValue();
    this.HideDropDownArea(true);
   } else {
    var calendarSelection = this.GetCalendar().GetValue();
    if(this.GetShowTimeSection()) {
     if(calendarSelection) {
      this.ApplyTimeSectionDateChanges();
      ASPx.Selection.Set(this.GetInputElement());
     } 
     this.HideDropDownArea(true);
    } else
     this.OnCalendarSelectionChanging(calendarSelection, true);
   }
   this.enterProcessed = true;
  }
  else
   this.OnApplyChanges();
  this.SetTextWasLastTemporaryChanged(false);
  return this.enterProcessed;
 },
 OnEscape: function() {
  if(this.droppedDown){
   if(this.GetCalendar().IsFastNavigationActive())
    this.GetCalendar().OnEscape();
   else
    this.HideDropDownArea(true);
  } else {
   this.ChangeDate(this.date);  
  }
  this.SetTextWasLastTemporaryChanged(false);
  return true;
 },
 OnTab: function(evt){
  if(!this.droppedDown) return;
  var calendar = this.GetCalendar();
  if(calendar.IsFastNavigationActive()) 
   calendar.GetFastNavigation().Hide();
  if(this.GetShowTimeSection()) {
   this.lockLostFocus = true;
   if(this.GetCalendarOwner()) {
    ASPx.Evt.PreventEvent(evt);  
    this.GetTimeEdit().SetFocus();
   }
   return;
  }
  if(this.GetTextWasLastTemporaryChanged()){
   this.ParseValue();
   this.HideDropDownArea(true);
  } else 
   this.OnCalendarSelectionChanging(this.GetCalendar().GetValue(), false);
  this.SetTextWasLastTemporaryChanged(false);
 },
 HideDropDownArea: function(isRaiseEvent) {
  if(this.accessibilityCompliant && this.focused)
   this.OnHideCalendarAccessible();
  ASPxClientDropDownEditBase.prototype.HideDropDownArea.call(this, isRaiseEvent);
 },
 OnTextChanged: function() {
  if(!this.IsFocusEventsLocked() || !this.droppedDown) {
   ASPxClientDropDownEditBase.prototype.OnTextChanged.call(this);
   var newText = this.GetInputElement().value;
   if(this.accessibilityCompliant) {
    if(!newText)
     newText = ASPx.AccessibilitySR.BlankEditorText;
    var accessibilityElement = this.GetAccessibilityServiceElement();
    ASPx.Attr.SetAttribute(accessibilityElement, "aria-label", newText);
   }
  }
 },
 ParseValue: function() { 
  this.ParseValueCore(true);
 },
 ParseValueCore: function(raiseChangedEvent) {
  var date;
  if(this.maskInfo != null) {
   date = ASPx.MaskDateTimeHelper.GetDate(this.maskInfo);   
  } else {
   var text = this.GetInputElement().value;
   var userParseResult = this.GetUserParsedDate(text);
   if(userParseResult !== false) {
    date = userParseResult;
   } else {
    if(text == null || text == "" || text == this.nullText)
     date = null;
    else
     date = !this.focused && raiseChangedEvent ? this.date : this.dateFormatter.Parse(text);
   }   
  }
  if(this.GetShowTimeSection() && !this.HasTimeInEditFormat() && date)
   this.ApplyExistingTime(date);
  this.ApplyParsedDate(date, raiseChangedEvent);
  this.lastValue = this.GetInputElement().value;
 },
 GetUserParsedDate: function(text) {
  if(!this.ParseDate.IsEmpty()) {
   var args = new ASPxClientParseDateEventArgs(text);
   this.ParseDate.FireEvent(this, args);
   if(args.handled)
    return args.date;
  }
  return false;
 },
 ApplyParsedDate: function(date, raiseChangedEvent) {
  if(date === false || !ASPxClientCalendarDateDisabledHelper.IsDateInRange(this.sharedParameters, date) ||
   this.IsDateDisabled(date)) {
   switch(this.dateOnError) {
    case "n":
     date = null;
     break;
    case "t":
     date = new Date();
     break;
    default:
     date = this.date;
     break;
   }
  }
  if(!this.allowNull && date == null)
   date = this.date;
  if(raiseChangedEvent)
   this.ChangeDate(date);  
  else
   this.SetValue(date);
 },
 IsDateDisabled: function(date) {
  return ASPxClientCalendarDateDisabledHelper.IsDateDisabled(this.sharedParameters, date, function(d) { return this.OnCustomDisabledDate(d); }.aspxBind(this));
 },
 HasTimeInEditFormat: function() {
  if(this.maskInfo) {
   for(var i = 0; i < this.maskInfo.parts.length; i++) {
    var part = this.maskInfo.parts[i];
    if(part.dateTimeRole && part.dateTimeRole.toLowerCase() == "h")
     return true;
   }
   return false;
  }
  return this.dateFormatter.mask.toLowerCase().indexOf("h") != -1;
 },
 ApplyExistingTime: function(date) {
  if(this.date == null)  return;  
  var savedDay = date.getDate();
  date.setHours(this.date.getHours());
  var diff = date.getDate() - savedDay;
  if(diff != 0) {
   var sign = (diff == 1 || date.getDate() == 1) ? -1 : 1;
   date.setTime(date.getTime() + sign * 3600000);
  }
  date.setMinutes(this.date.getMinutes());
  date.setSeconds(this.date.getSeconds());
  date.setMilliseconds(this.date.getMilliseconds());
 },
 GetValue: function() {
  return this.date;
 },
 GetLastSuccesfullValue: function() {
  return this.GetValue();
 },
 GetValueString: function() {
  return this.date != null ? ASPx.DateUtils.GetInvariantDateTimeString(this.date) : null;
 },
 SetValue: function(date) {  
  this.date = date;
  if(this.maskInfo != null) {
   ASPx.MaskDateTimeHelper.SetDate(this.maskInfo, date);
   this.ApplyMaskInfo(false);
   this.SavePrevMaskValue();
  } else {
   this.GetInputElement().value = this.GetFormattedDate();
   this.SyncRawValue();
   if(this.CanApplyTextDecorators())
    this.ToggleTextDecoration();
  }
  if(this.styleDecoration)
   this.styleDecoration.Update();
  this.RaiseValueSet();
 },
 RaiseValueSet: function() {
  if (!this.ValueSet.IsEmpty())
   this.ValueSet.FireEvent(this);
 },
 ChangeDate: function(date) { 
  var changed = !ASPx.DateUtils.AreDatesEqualExact(this.date, date);
  this.SetValue(date);
  var forceValueChanged = this.IsValueChangeForced() && !this.IsValueChanging();
  if(changed || forceValueChanged) {
   try {
    this.StartValueChanging();
    this.dateChangeProcessing = true;
    this.RaisePersonalStandardValidation();
    this.OnValueChanged();
   }
   finally {
    this.dateChangeProcessing = false;
    this.EndValueChanging();
   }
  }
 },
 IsDateChangeProcessing: function() {
  return this.dateChangeProcessing;
 },
 GetText: function() {
  return this.GetFormattedDate();
 },
 SetText: function(value) {
  ASPxClientTextEdit.prototype.SetValue.call(this, value);
  if(this.maskInfo == null)
   this.ParseValueCore(false);
 },
 GetFormattedText: function() {
  if(this.maskInfo != null)
   return this.GetMaskDisplayText();
  if(this.date == null)
   return this.nullText;
  if(this.displayFormat != null)
   return ASPx.Formatter.Format(this.displayFormat, this.date);
  return this.GetFormattedDate();
 },
 ClearEditorValueByClearButtonCore: function() {
  if(this.allowNull === false) 
   this.SetValue(this.GetLastSuccesfullValue());
  else
   ASPxClientDropDownEditBase.prototype.ClearEditorValueByClearButtonCore.call(this);
 },
 ShouldCancelMaskKeyProcessing: function(htmlEvent, keyDownInfo) {
  if(htmlEvent.altKey)
   return true;
  if(ASPxClientDropDownEditBase.prototype.ShouldCancelMaskKeyProcessing.call(this, htmlEvent, keyDownInfo))
   return true;  
  if(!this.droppedDown)
   return false;
  if(this.GetShowTimeSection() && htmlEvent.keyCode == ASPx.Key.Tab)
   return false;
  return !ASPx.MaskManager.IsPrintableKeyCode(keyDownInfo) 
   && keyDownInfo.keyCode != ASPx.Key.Backspace
   && keyDownInfo.keyCode != ASPx.Key.Delete;
 },
 DecodeRawInputValue: function(value) {
  if(value == "N") return null;
  var date = new Date();
  date.setTime(Number(value));
  var result = ASPx.DateUtils.ToUtcTime(date);
  var offsetDiff = result.getTimezoneOffset() - date.getTimezoneOffset();
  if(offsetDiff !== 0)
   result.setTime(result.valueOf() + offsetDiff * 60000);
  return result;
 },
 SyncRawValue: function() {
  this.SetRawValue(this.date == null ? "N" : ASPx.DateUtils.ToLocalTime(this.date).valueOf());
 }, 
 HasTextDecorators: function() {
  return (this.maskInfo != null && this.date == null) || ASPxClientDropDownEditBase.prototype.HasTextDecorators.call(this);
 },
 GetMaskDisplayText: function() {
  if(!this.focused) {
   if(this.date == null)
    return this.nullText;
   if(this.HasTextDecorators())
    return this.GetDecoratedText(this.date);
  }
  return this.maskInfo.GetText();
 },
 ToggleTextDecorationCore: function() {
  if(this.maskInfo != null) {
   this.ApplyMaskInfo(false);
  } else {
   var text = this.focused ? this.GetFormattedDate() : this.GetFormattedText();
   var input = this.GetInputElement();
   if(input.value != text)
    input.value = text;
  }
 },
 BeginShowMaskHint: function() {
 },
 EnsureOutOfRangeWarningManager: function () {
  this.ensureOutOfRangeWarningManager(this.GetMinDate(), this.GetMaxDate(), null, null, this.dateFormatter);
 },
 OnHideCalendarAccessible: function() {
  var inputElement = this.GetInputElement();
  var accessibilityElement = this.GetAccessibilityServiceElement();
  var pronounceTimeout = 300;
  ASPx.Attr.RemoveAttribute(inputElement, "aria-activedescendant");
  window.setTimeout(function() { 
   ASPx.Attr.SetAttribute(accessibilityElement, "aria-label", inputElement.value);
   ASPx.Attr.SetAttribute(inputElement, "aria-activedescendant", accessibilityElement.id);
  }, pronounceTimeout);
 },
 RaiseDateChanged: function(processOnServer, isInternal) {
  if(!this.DateChanged.IsEmpty()) {
   var args = new ASPxClientProcessingModeEventArgs(processOnServer);
   if (isInternal)
    args.isInternal = true;
   this.DateChanged.FireEvent(this, args);
   processOnServer = args.processOnServer;
  }
  return processOnServer;
 },
 RaiseCalendarCustomDisabledDate: function(e) {
  this.CalendarCustomDisabledDate.FireEvent(this, e);
 },
 SetDate: function(date) {
  this.SetValue(date);
  if(this.droppedDown)
   this.SetCalendarAndTimeSectionValues();
 },
 GetDate: function() {
  return this.date ? new Date(this.date.valueOf()) : null;
 },
 GetRangeDayCount: function () {
  var dateRangePair = ASPxDateRangeHelper.GetDateEditPair(this);
  return dateRangePair.isStart ? -1 : ASPxDateRangeHelper.GetFullDaysInCurrentRange(dateRangePair);
 },
 GetMinDate: function() {
  return this.sharedParameters.minDate;
 },
 SetMinDate: function(date) {
  this.SetMinDateCore(date);
  this.ownMinDate = date;
 },
 SetMinDateCore: function (date) {
  this.sharedParameters.minDate = date;
  if(this.droppedDown) {
   var calendar = this.GetCalendar();
   if(calendar)
    calendar.SetMinDate(date);
  }
  if(this.showOutOfRangeWarning) {
   this.EnsureOutOfRangeWarningManager();
   this.outOfRangeWarningManager.SetMinValue(this.GetMinDate());
  }    
 },
 GetMaxDate: function() {
  return this.sharedParameters.maxDate;
 },
 SetMaxDate: function (date) {
  this.sharedParameters.maxDate = date;
  if(this.droppedDown) {
   var calendar = this.GetCalendar();
   if(calendar)
    calendar.SetMaxDate(date);
  }
  if(this.showOutOfRangeWarning) {
   this.EnsureOutOfRangeWarningManager();
   this.outOfRangeWarningManager.SetMaxValue(this.GetMaxDate());
  }
 }
});
ASPxClientDateEdit.SharedCalendarCollection = (function(){
 var sharedCalendarIdCollection = [];
 return {
  registerCalendarId: function(calendarId) {
   if(ASPx.Data.ArrayIndexOf(sharedCalendarIdCollection, calendarId) == -1)
    sharedCalendarIdCollection.push(calendarId);
  },
  calendarIsShared: function(calendarId) {
   return ASPx.Data.ArrayIndexOf(sharedCalendarIdCollection, calendarId) != -1;
  }
 }
})();
ASPxClientDateEdit.Cast = ASPxClientControl.Cast;
ASPxClientDateEdit.active = null;
ASPxClientDateEdit.HandleCalendarSelectionChanging = function(s, e) {
 if(ASPxClientDateEdit.active == null) return;
 ASPxClientDateEdit.active.OnCalendarSelectionChanging(e.selection.GetFirstDate(), true);
};
ASPxClientDateEdit.HandleCalendarCustomDisabledDate = function(s, e) {
 this.OnCalendarCustomDisabledDate(e);
};
ASPxClientDateEdit.HandleTimeEditInternalValueChanging = function(s, date) {
 if(ASPxClientDateEdit.active == null) return;
 ASPxClientDateEdit.active.OnTimeEditInternalValueChanging(date);
};
ASPxClientDateEdit.HandleCalendarMainElementClick = function(s, e) {
 var dateEdit = ASPxClientDateEdit.active;
 if(dateEdit == null) 
  return;
 var focusEditor = true;
 if(dateEdit.GetShowTimeSection())
  focusEditor = !ASPx.GetIsParent(dateEdit.GetTimeEdit().GetMainElement(), ASPx.Evt.GetEventSource(e));
 if(focusEditor) {
  if(ASPx.Browser.VirtualKeyboardSupported)
   ASPx.VirtualKeyboardUI.smartFocusEditor(dateEdit);
  else 
   dateEdit.SetFocus();
 }
};
var ASPxClientParseDateEventArgs = ASPx.CreateClass(ASPxClientEventArgs, {
 constructor: function(value) {
  this.constructor.prototype.constructor.call(this);
  this.value = value;
  this.date = null;
  this.handled = false;
 } 
});
ASPx.DECalOkClick = function() {
 var edit = ASPxClientDateEdit.active;
 if(edit)
  edit.OnTimeSectionOkClick();
}
ASPx.DECalCancelClick = function() {
 var edit = ASPxClientDateEdit.active;
 if(edit)
  edit.OnTimeSectionCancelClick();
}
ASPx.DECalClearClick = function() {
 var edit = ASPxClientDateEdit.active;
 if(edit)
  edit.OnTimeSectionClearClick();
}
ASPx.DETimeEditKeyDown = function(s,e) {
 var edit = ASPxClientDateEdit.active;
 if(!edit) return;
 switch(e.htmlEvent.keyCode) {
  case ASPx.Key.Enter:
   edit.OnTimeEditEnter();
   break;
  case ASPx.Key.Esc:
   edit.OnTimeEditEsc();
   break;
  case ASPx.Key.Tab:
   edit.OnTimeEditTab(e.htmlEvent.shiftKey);
   break;
 }
}
ASPx.DETimeEditLostFocus = function() {
 var edit = ASPxClientDateEdit.active;
 if(!edit) return;
 edit.OnTimeEditLostFocus();
}
window.ASPxClientDateEdit = ASPxClientDateEdit;
window.ASPxClientParseDateEventArgs = ASPxClientParseDateEventArgs;
ASPx.DateRangeValidationPattern = DateRangeValidationPattern;
})();

