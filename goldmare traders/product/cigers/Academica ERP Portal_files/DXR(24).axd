(function () {
 var Constants = {
  TabAction: {
   CLICK: "Click",
   MOUSE_OVER: "MouseOver",
   MOUSE_DOWN: "MouseDown"
  },
  CssClassName: {
   MULTIROW: "dxtc-multiRow",
   INIT_STATE: "dxtc-init",
   STRIP_WRAPPER: "dxtc-wrapper",
   STRIP: "dxtc-strip",
   TAB_ROW: "dxtc-row",
   TAB: "dxtc-tab",
   ACTIVE_TAB: "dxtc-activeTab",
   TAB_LINK: "dxtc-link",
   TAB_IMAGE: "dxtc-img",
   TAB_SPACER: "dxtc-spacer",
   TAB_FILLER: "dxtc-filler",
   LEFT_INDENT: "dxtc-leftIndent",
   RIGHT_INDENT: "dxtc-rightIndent",
   INDENT_TEMPLATE: "dxtc-it",
   TABS_HOLDER: "dxtc-tabs",
   ACTIVE_ROW_ITEM: "dxtc-activeRowItem",
   PINNED_TAB_HEADERS: "dxtc-pth",
   PINNED_STRIP_ITEM: "dxtc-psi",
   LEAD_TAB: "dxtc-lead",
   LAST_TAB: "dxtc-last",
   NEW_LINE_START_TAB: "dxtc-n",
   NEW_LINE_END_TAB: "dxtc-l",
   RIBBON_FILE_TAB: "dxr-fileTab",
   CONTENT: "dxtc-content",
   AUTO_HEIGHT: "dxtc-autoHeight"
  }
 };
 var ASPxClientTabControlBase = ASPx.CreateClass(ASPxClientControl, {
  constructor: function (name) {
   this.constructor.prototype.constructor.call(this, name);
   this.activeTabIndex = 0;
   this.callbackCount = 0;
   this.cookieName = "";
   this.emptyHeight = false;
   this.emptyWidth = false;
   this.tabAlign = "Left";
   this.tabPosition = "Top";
   this.tabAction = Constants.TabAction.CLICK;
   this.tabs = [];
   this.tabsOrderInfo = null;
   this.tabsContentRequest = [];
   this.useClientVisibility = true;
   this.enableScrolling = !!this.GetScrollVisibleArea();
   this.firstShownTabIndex = 0;
   this.scrollManager = null;
   this.scrollingFillerElementWidth = 5000;
   this.scrollToActiveTab = true;
   this.handleClickOnWholeTab = true;
   this.deferredActions = [];
   this.layoutManager = null;
   this.hasTabStip = true;
   this.hasContent = false;
   this.isFullyInitializedInline = false;
   this.isFullyInitialized = false;
   this.initializationStepPassed = false;
   this.sizingConfig.correction = true;
   this.sizingConfig.adjustControl = true;
   this.flexEnabled = true;
   this.primaryDimension = "width";
   this.secondaryDimension = "height";
   this.adjustmentVars = { 
    stripLastSize: "",
    tabsLastSize: "",
    indentsSizes: { }, 
    scrolling: { },
    content: { },
    tabs: {
     lastSizes: { }
    }
   };
   this.tabStripImages = [];
   this.tabStripAdjustmentTimerID = -1;
   this.isLoadTabByCallback = false;
   this.isActiveTabChanged = false;
   this.shouldRaiseActiveTabChangedEvent = false;
   this.cacheEnabled = false;
   this.cacheDataFieldName = "aspxCache_CacheData";
   this.tabHeightManager = null;
   this.contentObserving = {
    enabled: false,
    canObserve: false,
    collapsingEnabled: false,
    collapsingTimerID: -1,
    collapsingTimeout: 500,
    collapsingShortTimeout: 100,
    sizeEqualityError: 3,
    timerID: -1,
    timeout: 500
   };
   this.minLeftIndentSizeLite = 0;
   this.minRightIndentSizeLite = 0;
   this.minScrollVisibleAreaSize = 50;
   this.TabClick = new ASPxClientEvent();
   this.ActiveTabChanged = new ASPxClientEvent();
   this.ActiveTabChanging = new ASPxClientEvent();
  },
  InitializeProperties: function(properties){
   if(properties.tabs)
    this.CreateTabs(properties.tabs);
  },
  Initialize: function () {
   ASPxClientControl.prototype.Initialize.call(this);
   if(this.IsStateControllerEnabled())
    ASPxClientTabControlBase.PrepareStateController();
   if(this.IsControlVisible()) {
    this.layoutManager.updateTabStripImagesSizes();
    this.InitializeTabControl();
    this.UpdateLayout();
   }
   this.initializationStepPassed = true;
  },
  InlineInitialize: function () {
   ASPxClientControl.prototype.InlineInitialize.call(this);
   this.tabsOrderInfo = this.getTabsOrderInfo();
   this.initializeLayoutManager();
   this.PrepareControlElements();
   var tabsCell = this.GetTabsCell();
   if(tabsCell && this.IsStateControllerEnabled())
    ASPx.AssignAccessibilityEventsToChildrenLinks(tabsCell);
   this.UpdateAdjustmentFlags();
   this.initializeTabHeightManager();
   if(this.enableScrolling) {
    this.InitializeScrolling();
    if(!this.flexEnabled)
     this.initScrollingFixedLayout();
   }
   if(this.IsControlVisible())
    this.InitializeTabControlInline();
  },
  initializeLayoutManager: function() {
   this.layoutManager = this.flexEnabled ? new FlexLayoutManager(this) : new FixedLayoutManager(this);
  },
  createTabHeightManagerCore: function() {
   if(!(this.GetTabStripContainer() && this.IsTopBottomTabPosition()))
    return new FakeTabHeightManager();
   var elements = this.GetTabsElements(),
    elementCount = elements.length;
   for(var i = 0; i < elementCount; i++) {
    var element = elements[i];
    if(element.style.height)
     return new TabCustomHeightManager(this);
   }
   return new TabDefaultHeightManager(this);
  },
  initializeTabHeightManager: function() {
   this.tabHeightManager = this.layoutManager.createTabHeightManager();
  },
  initScrollingFixedLayout: function() {
   this.GetScrollableArea().style.position = "relative";
   var sva = this.GetScrollVisibleArea();
   sva.style.overflow = "hidden";
   sva.style.position = "relative";
   ASPx.SetElementFloat(sva, this.rtl ? "right" : "left");
  },
  InitializeTabControlInline: function () {
   this.layoutManager.inlineInitialize();
   this.InitializeEnabledAndVisible();
   this.InitializeTabControlCore();
   this.isFullyInitializedInline = true;
  },
  initFixedLayoutInline: function() {
   ASPx.RemoveClassNameFromElement(this.GetMainElement(), Constants.CssClassName.INIT_STATE);
   if(this.GetTabStripContainer()) {
    this.tabHeightManager.initialize();
    this.StoreInitialIndentsSize();
   }
   if(this.enableScrolling) {
    this.GetScrollVisibleArea().style.width = "1px";
    var tabStrip = this.GetTabsCell();
    var tabStripChilds = ASPx.GetChildNodesByTagName(tabStrip, "LI");
    var scrollFiller = tabStripChilds[tabStripChilds.length - 1];
    scrollFiller.style.width = this.scrollingFillerElementWidth + "px";
   }
  },
  InitializeTabControl: function () {
   if(!this.isFullyInitializedInline)
    this.InitializeTabControlInline();
   this.CalculateSizes();
   this.AdjustPageContents();
   this.SubsribeForDomObserver();
   this.isFullyInitialized = true;
  },
  SubsribeForDomObserver: function() {
   this.contentObserving.enabled = this.hasContent && this.layoutManager.isContentObservingEnabled();
   if(!this.contentObserving.enabled)
    return;
   this.contentObserving.collapsingEnabled = this.layoutManager.isCollapsingInObservingEnabled();
   this.EnableContentObservation();
   var callbackFunc = function(element) {
    this.OnContentSizeObserving(element);
   }.aspxBind(this);
   ASPx.GetDomObserver().subscribe(this.name + this.GetContentsCellID(), callbackFunc);
  },
  EnableContentObservation: function() {
   this.layoutManager.enableContentObservation();
   this.contentObserving.canObserve = true;
  },
  OnContentSizeObserving: function(element) {
   if(!this.contentObserving.canObserve || this.IsPartiallyInitialized() || !this.IsAdjustmentAllowed())
    return;
   if(this.contentObserving.collapsingEnabled)
    this.CollapseControl();
   if(this.checkAdjustmentRequired())
    this.layoutManager.adjustSizeOnContentModification();
   else if(this.contentObserving.collapsingEnabled)
    this.ExpandControl();
  },
  checkAdjustmentRequired: function() {
   var sizes = this.GetAdjustedSizes();
   var sizeChanged = this.layoutManager.isAdjustmenRequiredByNewSizes(this.adjustedSizes, sizes, this.contentObserving.sizeEqualityError);
   if(sizeChanged)
    this.adjustedSizes = sizes;
   return sizeChanged;
  },
  areEqualValues: function(val1, val2, error) {
   return val1 == val2 || Math.abs(val1 - val2) <= error;
  },
  SetObservationPaused: function(paused) {
   if(this.contentObserving.enabled) {
    var observer = ASPx.GetDomObserver(),
     contentContainer = this.GetContentsCell();
    if(paused)
     observer.pause(contentContainer, true);
    else
     observer.resume(contentContainer, true);
   }
  },
  IsPartiallyInitialized: function () {
   return !this.isFullyInitialized;
  },
  canUseOffsetSizes: function() {
   return this.isFullyInitialized && this.IsControlVisible();
  },
  EnsureControlInitialized: function () {
   if(this.IsPartiallyInitialized())
    this.InitializeTabControl();
  },
  UpdateStateObject: function(){
   this.UpdateStateObjectWithObject({ activeTabIndex: this.activeTabIndex });
  },
  BrowserWindowResizeSubscriber: function () {
   return this.widthValueSetInPercentage || this.heightValueSetInPercentage || this.IsControlCollapsed();
  },
  OnBrowserWindowResize: function (e) {
   if(!this.IsAdjustmentAllowed()) return;
   if(this.contentObserving.enabled) {
    if(this.contentObserving.timerID !== -1)
     window.clearTimeout(this.contentObserving.timerID);
    this.contentObserving.canObserve = false;
    var enableObservationFunc = function() { this.EnableContentObservation(); }.aspxBind(this);
    this.contentObserving.timerID = window.setTimeout(enableObservationFunc, this.contentObserving.timeout);
   }
   this.AdjustControlCore();
  },
  CanCauseReadjustment: function() {
   return false;
  },
  IsExpandableByAdjustment: function() {
   return true;
  },
  InitializeEnabledAndVisible: function () {
   for(var i = 0; i < this.tabs.length; i++) {
    this.SetTabVisibleCore(i, this.tabs[i].clientVisible, true);
    this.SetTabEnabled(i, this.tabs[i].clientEnabled, true);
   }
  },
  InitializeCallBackData: function () {
   var element = this.getActiveContentElement();
   if(element != null) element.loaded = true;
  },
  InitializeTabControlCore: function () {
   if(this.enableScrolling) {
    this.CalculateSizes();
    if(!this.flexEnabled)
     this.RecalculateTabStripWidthLite();
    this.AdjustTabScrollingCore(true, false);
   }
   else
    this.AdjustTabControlSizeLite();
   if(this.IsMultiRow())
    this.PlaceActiveTabRowToBottom(this.activeTabIndex);
  },
  StoreInitialIndentsSize: function () {
   var leftIndent = this.GetLeftIndentLite(),
    rightIndent = this.GetRightIndentLite(),
    dimension = this.IsTopBottomTabPosition() ? "width" : "height";
   if(leftIndent)
    this.minLeftIndentSizeLite = this.GetCachedElementSize(leftIndent);
   if(rightIndent)
    this.minRightIndentSizeLite = this.GetCachedElementSize(rightIndent);
   this.adjustmentVars.indentsSizes = {
    left: this.minLeftIndentSizeLite,
    right: this.minRightIndentSizeLite
   };
  },
  InitializeScrolling: function () {
   this.scrollManager = new TabControlScrollingManager(this, this.GetScrollableArea(), [1, 0], this.OnBeforeScrolling, this.OnAfterScrolling, true);
   this.scrollManager.scrollSessionInterval = 5;
   this.scrollManager.animationAcceleration = 0.5;
   this.InitializeScrollButton(this.GetScrollLeftButtonElement());
   this.InitializeScrollButton(this.GetScrollRightButtonElement());
  },
  InitializeScrollButton: function (button) {
   if(!button || !button.id) return;
   var img = ASPx.GetNodeByTagName(button, "IMG", 0);
   ASPx.Evt.PreventElementDrag(img);
   ASPx.Selection.SetElementSelectionEnabled(img, false);
   ASPx.Selection.SetElementSelectionEnabled(button, false);
   var manager = this.scrollManager;
   var dir = button.id.charAt(button.id.length - 1) == "R" ? 1 : -1;
   if(this.enabled) {
    ASPx.Evt.AttachEventToElement(button, ASPx.TouchUIHelper.touchMouseDownEventName, function (e) { manager.StartScrolling(dir, 5, 5); ASPx.Evt.PreventEvent(e); });
    ASPx.Evt.AttachEventToElement(button, ASPx.TouchUIHelper.touchMouseUpEventName, function (e) { manager.StopScrolling(); });
    if(ASPx.Browser.IE) {
     ASPx.Evt.AttachEventToElement(button, "dblclick", function (e) { manager.StartScrolling(dir, 5, 5); manager.StopScrolling(); });
    }
   }
  },
  ScrollToShowTab: function (tabIndex, doAnimation) {
   if(!this.GetVisibleTabElement(tabIndex))
    return;
   var getWidtn = function (tc, index) {
    var res = 0;
    var tab = tc.GetVisibleTabElement(index);
    var separator = tc.GetSeparatorElement(index);
    if(tab && tab.style.display !== 'none')
     res += tab.offsetWidth;
    if(separator && separator.style.display !== 'none')
     res += separator.offsetWidth;
    return res;
   };
   var startIndex = this.firstShownTabIndex;
   var endIndex = tabIndex;
   var scrollToRight = !this.rtl;
   if(tabIndex < this.firstShownTabIndex) {
    startIndex = tabIndex;
    endIndex = this.firstShownTabIndex - 1;
    scrollToRight = !scrollToRight;
   }
   var width = 0;
   var shift = 0;
   var tabCount = 0;
   var scrollVisibleAreaWidth = this.GetScrollVisibleArea().offsetWidth;
   for(var i = startIndex; i <= endIndex; i++)
    width += getWidtn(this, i);
   for(var i = startIndex; i <= endIndex; i++) {
    var diff = width - shift;
    if(ASPx.Browser.IE && ASPx.Browser.Version > 8)  
     diff -= 1;
    if(diff > scrollVisibleAreaWidth || !(scrollToRight ^ this.rtl)) {
     shift += getWidtn(this, i);
     tabCount++;
    }
   }
   if(this.GetVisibleTabElement(tabIndex).offsetWidth >= scrollVisibleAreaWidth &&
      scrollToRight ^ this.rtl) {
    tabCount--;
    shift -= getWidtn(this, tabIndex);
   }
   if(shift <= 0) return;
   this.firstShownTabIndex += tabCount * (scrollToRight ^ this.rtl ? 1 : -1);
   if(doAnimation) {
    this.scrollManager.animationOffset = this.GetScrollAnimationOffset(this.firstShownTabIndex);
    this.scrollManager.PrepareForScrollAnimation();
    this.scrollManager.DoScrollSessionAnimation(scrollToRight ? -1 : 1);
   } else {
    this.scrollManager.SetScrolledAreaPosition(this.scrollManager.GetScrolledAreaPosition()
     + this.GetScrollAnimationOffset(this.firstShownTabIndex) * (scrollToRight ? -1 : 1));
   }
  },
  OnBeforeScrolling: function (manager, direction) {
   var tc = manager.owner;
   if(tc.IsFullyScrolledToLeft() && direction < 0 || tc.IsFullyScrolledToRight() && direction > 0) {
    manager.StopScrolling();
    return;
   }
   var prevFirstShownTabIndex = tc.firstShownTabIndex;
   var diff = (direction > 0 ^ tc.rtl) ? 1 : -1;
   do {
    if(tc.firstShownTabIndex <= 0 && diff < 0
    || tc.firstShownTabIndex >= tc.tabs.length - 1 && diff > 0) break;
    tc.firstShownTabIndex += diff;
   } while(!tc.IsTabVisible(tc.firstShownTabIndex));
   manager.animationOffset = tc.GetScrollAnimationOffset(tc.firstShownTabIndex);
  },
  OnAfterScrolling: function (manager, direction) {
   manager.owner.UpdateScrollButtonsEnabled();
  },
  AdjustTabScrolling: function (scrollToActiveTab, doAnimation) {
   this.CalculateSizes();
   this.AdjustTabScrollingCore(scrollToActiveTab, doAnimation);
  },
  AdjustTabScrollingCore: function (scrollToActiveTab, doAnimation) {
   if(!this.GetMainElement()) return;
   this.adjustTabStripScrolling(scrollToActiveTab, doAnimation);
   this.AdjustPageContents();
  },
  adjustTabStripScrolling: function(scrollToActiveTab, doAnimation) {
   this.UpdateScrollButtonsVisible();
   if(scrollToActiveTab)
    this.ScrollToShowTab(this.activeTabIndex, doAnimation);
   if(this.enabled)
    this.UpdateScrollButtonsEnabled();
  },
  GetScrollAnimationOffset: function (newFirstShownTabIndex) {
   var newPos = 0;
   var i = this.GetNextVisibleTabIndex(-1);
   while(i < newFirstShownTabIndex && i > -1) {
    newPos += this.GetVisibleTabElement(i).offsetWidth;
    var separator = this.GetSeparatorElement(i);
    newPos += separator && separator.offsetWidth;
    i = this.GetNextVisibleTabIndex(i);
   }
   if(this.rtl)
    newPos = -newPos;
   return Math.abs(this.scrollManager.GetScrolledAreaPosition() + newPos);
  },
  AdjustScrollVisibleAreaWidth: function () {
   var sva = this.GetScrollVisibleArea();
   var mainElement = this.GetMainElement();
   if((mainElement.style.width == "" || mainElement.style.width == "0px") && !this.GetContentsCell()) {
    ASPx.SetOffsetWidth(sva, this.GetScrollableAreaWidth());
    return;
   }
   ASPx.SetOffsetWidth(sva, this.minScrollVisibleAreaSize);
   var scrollWrapper = this.GetTabsCellWrapperElement();
   var c = ASPx.GetChildElementNodes(scrollWrapper);
   var restWidth = 0;
   for(var i = 0; i < c.length; i++)
    restWidth += c[i].offsetWidth;
   restWidth = restWidth - sva.offsetWidth + this.GetStripContainerBordersPaddingsMarginsWidth();
   var svaWidth = this.adjustmentVars.controlSizes.primary - restWidth;
   ASPx.SetOffsetWidth(sva, svaWidth);
   var scrollWrapperWidth = restWidth + svaWidth;
   ASPx.SetOffsetWidth(scrollWrapper, scrollWrapperWidth);
   this.RecalculateTabStripWidthLite();
  },
  DoSafeScrollPositionOperation: function (func) {
   var lastScrollYPos = ASPx.GetDocumentScrollTop();
   var parent = this.GetMainElement().parentNode;
   var scrollParentYBefore = parent.scrollTop;
   func();
   if(scrollParentYBefore != parent.scrollTop)
    parent.scrollTop = scrollParentYBefore;
   var scrollY = ASPx.GetDocumentScrollTop();
   if(lastScrollYPos != scrollY)
    window.scrollTo(ASPx.GetDocumentScrollLeft(), lastScrollYPos);
  },
  UpdateScrollButtonsEnabled: function () {
   if(!this.IsStateControllerEnabled()) return;
   ASPx.GetStateController().SetElementEnabled(this.GetScrollLeftButtonElement(), !this.IsFullyScrolledToLeft());
   ASPx.GetStateController().SetElementEnabled(this.GetScrollRightButtonElement(), !this.IsFullyScrolledToRight());
  },
  UpdateScrollButtonsVisible: function () {
   this.layoutManager.adjustScrollVisibleAreaWidth();
   var svaWidth = this.GetScrollVisibleArea().offsetWidth;
   var scrollButtonsVisible = svaWidth < this.GetScrollableAreaWidth();
   ASPx.SetElementDisplay(this.GetScrollLeftButtonContainer(), scrollButtonsVisible);
   ASPx.SetElementDisplay(this.GetScrollRightButtonContainer(), scrollButtonsVisible);
   if(!scrollButtonsVisible)
    this.ScrollToShowTab(0, true);
   this.layoutManager.adjustScrollVisibleAreaWidth();
  },
  GetScrollableAreaWidth: function () {
   return this.layoutManager.getScrollableAreaWidth();
  },
  getScrollableAreaWidthCore: function() {
   return this.GetScrollableArea().offsetWidth - this.scrollingFillerElementWidth;
  },
  IsFullyScrolledToLeft: function () {
   if(!this.rtl)
    return ASPx.PxToInt(this.GetScrollableArea().style.left) >= 0 || this.GetPrevVisibleTabIndex(this.firstShownTabIndex) < 0;
   var visibleWidth = this.GetScrollableAreaWidth() - ASPx.PxToInt(this.GetScrollableArea().style.left);
   return visibleWidth <= this.GetScrollVisibleArea().offsetWidth ||
     this.GetNextVisibleTabIndex(this.firstShownTabIndex) < 0;
  },
  IsFullyScrolledToRight: function () {
   if(this.rtl)
    return ASPx.PxToInt(this.GetScrollableArea().style.left) <= 0 || this.GetPrevVisibleTabIndex(this.firstShownTabIndex) < 0;
   var visibleWidth = this.GetScrollableAreaWidth() + ASPx.PxToInt(this.GetScrollableArea().style.left);
   return visibleWidth <= this.GetScrollVisibleArea().offsetWidth ||
     this.GetNextVisibleTabIndex(this.firstShownTabIndex) < 0;
  },
  CorrectTabHeightOnStateChanged: function (element) {
   this.tabHeightManager.correctTabHeightOnStateChanged(element);
  },
  PrepareControlElements: function () {
   var mainElem = this.GetMainElement();
   if(this.IsPercentageSize(mainElem, "width"))
    mainElem.style.overflow = "visible";
   this.PrepareTabStrip();
   this.PrepareContentElements();
  },
  PrepareTabStrip: function () {
   var tabStrip = null;
   var elements = ASPx.GetChildElementNodes(this.GetMainElement());
   var elementCount = elements.length;
   for(var i = 0; i < elementCount; i++) {
    var element = elements[i];
    if(element.tagName == "UL") {
     if(element.className.indexOf(Constants.CssClassName.STRIP_WRAPPER) == -1)
      tabStrip = element;
     else {
      element.id = this.name + this.GetTabsCellWrapperID();
      tabStrip = ASPx.GetNodeByClassName(element, Constants.CssClassName.STRIP);
     }
     break;
    }
   }
   if(tabStrip) {
    tabStrip.id = this.name + this.GetTabsCellID();
    var hasRibbonTab = ASPx.GetChildNodesByClassName(tabStrip, Constants.CssClassName.RIBBON_FILE_TAB).length > 0;
    var indexCorrection = hasRibbonTab ? 1 : 0;
    this.PrepareElements(tabStrip, Constants.CssClassName.TAB,
     function (index) {
      var tabIndex = this.FindTabIndexByElementIndex(index);
      return this.name + this.GetTabElementID(tabIndex, false);
     }.aspxBind(this));
    this.PrepareElements(tabStrip, Constants.CssClassName.ACTIVE_TAB,
     function (index) {
      var tabIndex = this.FindActiveTabIndexByElementIndex(index, indexCorrection);
      return this.name + this.GetTabElementID(tabIndex, true);
     }.aspxBind(this));
    this.PrepareElements(tabStrip, Constants.CssClassName.TAB_SPACER,
     function (index) {
      var separatorIndex = this.FindSeparatorIndexByElementIndex(index);
      if(!ASPx.IsExists(separatorIndex)) return;
      return this.name + this.GetSeparatorElementID(separatorIndex);
     }.aspxBind(this));
    this.PrepareElements(tabStrip, Constants.CssClassName.TAB_LINK,
     function (index, el) { return el.parentNode.id + "T"; }.aspxBind(this));
    this.PrepareElements(tabStrip, Constants.CssClassName.TAB_IMAGE,
     function (index, el) { return el.parentNode.parentNode.id + "Img"; }.aspxBind(this));
   }
   else
    this.hasTabStrip = false;
   this.layoutManager.prepareTabStripForImageLoading();
  },
  PrepareTabStripForImageLoading: function() {
   var stripContainer = this.GetTabStripContainer();
   if(stripContainer) {
    var images = ASPx.GetNodes(stripContainer, function(el) { return el.tagName == "IMG"; });
    for(var i = 0; i < images.length; i++) {
     var image = images[i];
     var imageInfo = {
      element: image,
      loaded: false,
      width: 0,
      height: 0
     };
     ASPx.Evt.AttachEventToElement(image, "load", this.GetTabStripImageLoadedHandler(imageInfo));
     this.tabStripImages.push(imageInfo);
    }
   }
  },
  GetTabStripImageLoadedHandler: function(imageInfo) {
   return function() {
    this.OnTabStripImageLoaded(imageInfo);
   }.aspxBind(this);
  },
  OnTabStripImageLoaded: function(imageInfo) {
   if(!(this.isInitialized && this.isFullyInitialized) || imageInfo.loaded) return;
   imageInfo.loaded = true;
   var imageWidth = imageInfo.element.offsetWidth,
    imageHeight = imageInfo.element.offsetHeight,
    imageSizeChanged = imageWidth !== imageInfo.width || imageHeight !== imageInfo.height;
   if(imageSizeChanged && this.tabStripAdjustmentTimerID === -1) {
    this.tabStripAdjustmentTimerID = window.setTimeout(function() {
     this.tabStripAdjustmentTimerID = -1;
     this.adjustControlInternal();
    }.aspxBind(this), 0);
   }
   imageInfo.width = imageWidth;
   imageInfo.height = imageHeight;
  },
  UpdateTabStripImagesSizes: function() {
   for(var i = 0; i < this.tabStripImages.length; i++) {
    var imageInfo = this.tabStripImages[i];
    imageInfo.width = imageInfo.element.offsetWidth;
    imageInfo.height = imageInfo.element.offsetHeight;
   }
  },
  FindTabIndexByElementIndex: function (elementIndex) {
   var tabIndex = -1;
   for(var i = 0; i < this.tabs.length; i++) {
    if(this.tabs[i].visible)
     tabIndex++;
    if(!this.useClientVisibility && this.tabs[i].clientVisible && i == this.activeTabIndex)
     tabIndex--;
    if(tabIndex == elementIndex)
     return i;
   }
  },
  FindActiveTabIndexByElementIndex: function (elementIndex, indexCorrection) {
   if(!this.useClientVisibility)
    return this.activeTabIndex;
   var tabIndex = -1;
   for(var i = indexCorrection; i < this.tabs.length; i++) {
    var tab = this.tabs[i];
    if(tab.visible && tab.enabled)
     tabIndex++;
    if(tabIndex == elementIndex)
     return i;
   }
  },
  FindSeparatorIndexByElementIndex: function(elementIndex) {
   var separatorIndex = -1;
   for(var i = 0; i < this.tabs.length; i++) {
    var nextIndex = this.GetNextVisibleTabIndex(i, true);
    if(this.tabs[i].visible && nextIndex > -1) {
     if(this.IsMultiRow()) {
      var nextTabElement = this.GetVisibleTabElement(nextIndex);
      if(!this.isTabElementStartsNewLine(nextTabElement))
       separatorIndex++;
     }
     else
      separatorIndex++;
    }
    if(separatorIndex === elementIndex) {
     if(!this.enableScrolling || nextIndex > -1)
      return i;
    }
   }
  },
  PrepareContentElements: function () {
   var contentContainer = this.GetContentContainerElementLite();
   if(!contentContainer) return;
   this.hasContent = true;
   contentContainer.id = this.name + this.GetContentsCellID();
   this.PrepareElements(contentContainer, "",
    function (index) {
     var contentIndex = this.FindContentIndexByElementIndex(index);
     return this.name + this.GetContentElementID(contentIndex);
    }.aspxBind(this));
   if(!this.GetTabsCell() && contentContainer.style.cssText) 
    contentContainer.style.cssText = ASPx.CreateImportantCssText(contentContainer.style.cssText);
  },
  FindContentIndexByElementIndex: function (elementIndex) {
   if(!this.useClientVisibility)
    return this.activeTabIndex;
   var tabIndex = -1;
   for(var i = 0; i < this.tabs.length; i++) {
    var tab = this.tabs[i];
    if(tab.visible && tab.enabled)
     tabIndex++;
    if(tabIndex == elementIndex)
     return i;
   }
  },
  PrepareElements: function (container, className, getId) {
   var elements = (className !== "") ? ASPx.GetNodesByClassName(container, className) : ASPx.GetChildNodes(container, function (el) { return !!el.tagName; });
   for(var i = 0; i < elements.length; i++) {
    if(elements[i].id === "") {
     var id = getId(i, elements[i]);
     if(id)
      elements[i].id = id;
    }
   }
  },
  AdjustTabContents: function() {
   this.CorrectWrappedText(this.GetTabLinkElements);
  },
  GetTabLinkElements: function () {
   var container = this.GetTabStripContainer();
   if(container)
    return ASPx.GetNodesByClassName(container, Constants.CssClassName.TAB_LINK);
   return null;
  },
  GetContentContainerElementLite: function() {
   return ASPx.GetChildByClassName(this.GetMainElement(), Constants.CssClassName.CONTENT);
  },
  GetCachedBordersPaddingsMarginsWidth: function(element, dimension) {
   if(!dimension)
    dimension = this.primaryDimension;
   var cache = this.GetOrCreateElementCache(element);
   return dimension == "width" ? cache.horizontalBordersPaddingsMarginsWidth : cache.verticalBordersPaddingsMarginsWidth;
  },
  GetCachedBordersAndPaddingsWidth: function(element, dimension) {
   if(!dimension)
    dimension = this.primaryDimension;
   var cache = this.GetOrCreateElementCache(element);
   return dimension == "width" ? cache.horizontalBordersAndPaddingsWidth : cache.verticalBordersAndPaddingsWidth;
  },
  GetCachedVerticalBordersPaddingsMarginsWidth: function(element) {
   var cache = this.GetOrCreateElementCache(element);
   return cache.verticalBordersPaddingsMarginsWidth;
  },
  GetCachedHorizontalBordersPaddingsMarginsWidth: function(element) {
   var cache = this.GetOrCreateElementCache(element);
   return cache.horizontalBordersPaddingsMarginsWidth;
  },
  GetCachedVerticalBordersAndPaddingsWidth: function(element) {
   var cache = this.GetOrCreateElementCache(element);
   return cache.verticalBordersAndPaddingsWidth;
  },
  GetCachedHorizontalBordersAndPaddingsWidth: function(element) {
   var cache = this.GetOrCreateElementCache(element);
   return cache.horizontalBordersAndPaddingsWidth;
  },
  GetCachedElementInnerSize: function(element, dimension) {
   if(!element) return 0;
   if(!dimension)
    dimension = this.primaryDimension;
   var cache = this.GetOrCreateElementCache(element);
   return dimension === "width" ? cache.width : cache.height;
  },
  GetCachedElementSize: function(element, dimension) {
   if(!element) return 0;
   if(!dimension)
    dimension = this.primaryDimension;
   var cache = this.GetOrCreateElementCache(element);
   if(cache.display == "none")
    return 0;
   return dimension === "width" ? cache.outerWidth : cache.outerHeight;
  },
  GetElementCurrentStyle: function(element) {
   var style = element.currentStyle;
   if(style)
    return window.getComputedStyle ? window.getComputedStyle(element, null) : style;
   else
    return ASPx.GetCurrentStyle(element);
  },
  CacheElement: function(element) {
   var cache = { },
    style = this.GetElementCurrentStyle(element);
   var useOffsetSizes = ASPx.Browser.IE && ASPx.Browser.MajorVersion < 9 || style.height == "auto";
   cache.borderLeftWidth = style.borderLeftStyle != "none" ? ASPx.PxToFloat(style.borderLeftWidth) : 0;
   cache.borderRightWidth = style.borderRightStyle != "none" ? ASPx.PxToFloat(style.borderRightWidth) : 0;
   cache.borderTopWidth = style.borderTopStyle != "none" ? ASPx.PxToFloat(style.borderTopWidth) : 0;
   cache.borderBottomWidth = style.borderBottomStyle != "none" ? ASPx.PxToFloat(style.borderBottomWidth) : 0;
   cache.paddingLeft = ASPx.PxToFloat(style.paddingLeft);
   cache.paddingRight = ASPx.PxToFloat(style.paddingRight);
   cache.paddingTop = ASPx.PxToFloat(style.paddingTop);
   cache.paddingBottom = ASPx.PxToFloat(style.paddingBottom);
   cache.marginLeft = ASPx.PxToFloat(style.marginLeft);
   cache.marginRight = ASPx.PxToFloat(style.marginRight);
   cache.marginTop = ASPx.PxToFloat(style.marginTop);
   cache.marginBottom = ASPx.PxToFloat(style.marginBottom);
   cache.horizontalBordersAndPaddingsWidth = cache.borderLeftWidth + cache.borderRightWidth + cache.paddingLeft + cache.paddingRight;
   cache.verticalBordersAndPaddingsWidth = cache.borderTopWidth + cache.borderBottomWidth + cache.paddingTop + cache.paddingBottom;
   cache.horizontalMarginsWidth = cache.marginLeft + cache.marginRight;
   cache.verticalMarginsWidth = cache.marginTop + cache.marginBottom;
   cache.horizontalBordersPaddingsMarginsWidth = cache.horizontalBordersAndPaddingsWidth + cache.horizontalMarginsWidth;
   cache.verticalBordersPaddingsMarginsWidth = cache.verticalBordersAndPaddingsWidth + cache.verticalMarginsWidth;
   if(useOffsetSizes) {
    cache.width = element.offsetWidth - cache.horizontalBordersAndPaddingsWidth;
    cache.height = element.offsetHeight - cache.verticalBordersAndPaddingsWidth;
   }
   else {
    cache.width = ASPx.PxToFloat(style.width);
    cache.height = ASPx.PxToFloat(style.height);
   }
   cache.offsetWidth = cache.width + cache.horizontalBordersAndPaddingsWidth;
   cache.offsetHeight = cache.height + cache.verticalBordersAndPaddingsWidth;
   cache.outerWidth = cache.width + cache.horizontalBordersPaddingsMarginsWidth;
   cache.outerHeight = cache.height + cache.verticalBordersPaddingsMarginsWidth;
   cache.display = ASPx.GetElementDisplay(element);
   cache.needRefresh = !(ASPx.documentLoaded && cache.display);
   element[this.cacheDataFieldName] = cache;
  },
  GetElementCache: function(element) {
   return element[this.cacheDataFieldName];
  },
  GetOrCreateElementCache: function(element) {
   this.EnsureElementCached(element);
   return this.GetElementCache(element);
  },
  EnsureElementCached: function(element) {
   var cache = this.GetElementCache(element);
   if(!this.cacheEnabled || this.UseProportionalTabSizes() || !cache || cache.needRefresh)
    this.CacheElement(element);
  },
  ClearElementCache: function(element) {
   if(element)
    element[this.cacheDataFieldName] = null;
  },
  ClearTabElementsCache: function(index) {
   var activeTabElement = this.GetTabElement(index, true),
    tabElement = this.GetTabElement(index, false);
   if(activeTabElement)
    this.ClearElementCache(activeTabElement);
   if(tabElement)
    this.ClearElementCache(tabElement);
   this.tabHeightManager.requestAdjustment();
  },
  IsPercentageSize: function (element, dimension) {
   return ASPx.IsPercentageSize(element.style[dimension]);
  },
  CollapseControl: function() {
   if(!this.NeedCollapseControlCore() || this.IsPartiallyInitialized()) return;
   this.isControlCollapsed = true;
   this.layoutManager.collapseTabStrip();
   if(this.adjustmentVars.content.needCollapsing) {
    this.SetObservationPaused(true);
    var contentHolder = this.getActiveContentHolder();
    this.adjustmentVars.content.lastHeight = contentHolder.style.height;
    contentHolder.style.height = "";
    this.SetObservationPaused(false);
   }
  },
  collapseTabStrip: function() {
   if(this.enableScrolling)
    this.CollapseTabScrolling();
   else
    this.CollapseControlCommon();
  },
  CollapseControlCommon: function() {
   var stripContainer = this.GetTabStripContainer(),
    leftIndent = this.GetLeftIndentLite(),
    rightIndent = this.GetRightIndentLite();
   if(!stripContainer) return;
   this.adjustmentVars.indentsSizes.leftLastSize = leftIndent.style[this.primaryDimension];
   this.adjustmentVars.indentsSizes.rightLastSize = rightIndent.style[this.primaryDimension];
   this.adjustmentVars.stripLastSize = stripContainer.style[this.primaryDimension];
   if(this.IsMultiRow()) {
    var tabsHolder = this.getTabsHolderElement();
    this.adjustmentVars.tabsLastSize = tabsHolder.style[this.primaryDimension];
   }
   if(this.UseProportionalTabSizes())
    this.CollapseTabSizes();
   this.SetCachedElementSize(leftIndent, this.minLeftIndentSizeLite);
   this.SetCachedElementSize(rightIndent, this.minRightIndentSizeLite);
   this.RecalculateTabStripWidthLite(this.GetStripSizeLite(), this.minLeftIndentSizeLite, this.minRightIndentSizeLite);
  },
  CollapseTabSizes: function() {
   this.adjustmentVars.tabs.lastSizes = { };
   var tabElements = this.GetTabsElements();
   for(var i = 0, count = tabElements.length; i < count; i++) {
    var tabElement = tabElements[i];
    this.adjustmentVars.tabs.lastSizes[tabElement.id] = tabElement.style.width;
    tabElement.style.width = "";
   }
  },
  CollapseTabScrolling: function() {
   var scrollWrapper = this.GetTabsCellWrapperElement(),
    sva = this.GetScrollVisibleArea();
   if(!scrollWrapper) return;
   this.adjustmentVars.scrolling.svaLastWidth = sva.style.width;
   this.adjustmentVars.scrolling.wrapperLastWidth = scrollWrapper.style.width;
   var mainElement = this.GetMainElement();
   if((mainElement.style.width == "" || mainElement.style.width == "0px") && !this.GetContentsCell()) {
    ASPx.SetOffsetWidth(sva, this.GetScrollableAreaWidth());
    return;
   }
   ASPx.SetOffsetWidth(sva, this.minScrollVisibleAreaSize);
   var c = ASPx.GetChildElementNodes(scrollWrapper),
    scrollWrapperWidth = 0;
   for(var i = 0; i < c.length; i++)
    scrollWrapperWidth += c[i].offsetWidth;
   scrollWrapper.style.width = scrollWrapperWidth + "px";
  },
  ExpandControl: function() {
   if(!this.NeedCollapseControlCore())
    return;
   this.isControlCollapsed = false;
   this.layoutManager.expandTabStrip();
   if(this.adjustmentVars.content.needCollapsing) {
    this.SetObservationPaused(true);
    var contentHolder = this.getActiveContentHolder();
    contentHolder.style.height = this.adjustmentVars.content.lastHeight;
    this.SetObservationPaused(false);
   }
  },
  expandTabStrip: function() {
   if(this.enableScrolling)
    this.ExpandTabScrolling();
   else
    this.ExpandControlCommon();
  },
  ExpandControlCommon: function() {
   var stripContainer = this.GetTabStripContainer()
   if(!stripContainer)
    return;
   var leftIndent = this.GetLeftIndentLite(),
    rightIndent = this.GetRightIndentLite();
   leftIndent.style[this.primaryDimension] = this.adjustmentVars.indentsSizes.leftLastSize;
   rightIndent.style[this.primaryDimension] = this.adjustmentVars.indentsSizes.rightLastSize;
   if(this.IsTopBottomTabPosition()) {
    stripContainer.style.width = this.adjustmentVars.stripLastSize;
    if(this.IsMultiRow()) {
     var tabsHolder = this.getTabsHolderElement();
     tabsHolder.style.width = this.adjustmentVars.tabsLastSize;
    }
    if(this.UseProportionalTabSizes())
     this.ExpandTabSizes();
   }
  },
  ExpandTabScrolling: function() {
   var sva = this.GetScrollVisibleArea(),
    scrollWrapper = this.GetTabsCellWrapperElement();
   if(!scrollWrapper) return;
   sva.style.width = this.adjustmentVars.scrolling.svaLastWidth;
   scrollWrapper.style.width = this.adjustmentVars.scrolling.wrapperLastWidth;
  },
  ExpandTabSizes: function() {
   var tabElements = this.GetTabsElements();
   for(var i = 0, count = tabElements.length; i < count; i++) {
    var tabElement = tabElements[i];
    tabElement.style.width = this.adjustmentVars.tabs.lastSizes[tabElement.id];
   }
  },
  NeedCollapseControlCore: function () {
   return this.layoutManager.needCollapseControl();
  },
  CalculateSizes: function() {
   this.layoutManager.calculateSizes();
  },
  calculateSizesCore: function () {
   this.updateContentAdjustmentFlags();
   this.tabHeightManager.adjustTabs();
   if(!this.isControlCollapsed)
    this.CollapseControl();
   this.isControlCollapsed = false;
   this.adjustmentVars.stripSizes = { };
   this.UpdateStripSizes(this.GetStripSizeLite(this.UseProportionalTabSizes()));
   this.AdjustTabStripHeight();
   this.calculateMainElementSizes();
   this.adjustmentVars.controlSizes = {};
   this.adjustmentVars.controlSizes.primary = this.GetMaxValueExtended(
    this.enableScrolling ? this.minScrollVisibleAreaSize : this.adjustmentVars.stripFullSize,
    this.adjustmentVars.mainElementSizes.primary);
   this.adjustmentVars.controlSizes.secondary = this.adjustmentVars.mainElementSizes.secondary;
   this.CalculateContentHeight();
  },
  AdjustTabStripHeight: function() {
   if(!this.tabHeightManager.needAdjustTabStrip())
    return;
   var stripContainer = this.GetTabStripContainer();
   var height = this.tabHeightManager.getTabStripHeight();
   this.adjustmentVars.stripSizes.secondary = height;
   height = this.GetPreparedSizeValue(height);
   height = height > 0 ? height : 0;
   stripContainer.style.height = height + "px";
  },
  calculateMainElementSizes: function() {
   var mainElement = this.GetMainElement();
   this.ClearElementCache(mainElement);
   var cache = this.GetOrCreateElementCache(mainElement);
   this.adjustmentVars.mainElementCache = cache;
   this.adjustmentVars.mainElementSizes = {
    primary: cache[this.primaryDimension],
    secondary: cache[this.secondaryDimension]
   };
  },
  updateContentAdjustmentFlags: function() {
   var contentInfo = this.adjustmentVars.content;
   contentInfo.needAdjustment = this.hasContent && this.layoutManager.isContentAdjustmentRequired();
   contentInfo.needCollapsing = contentInfo.needAdjustment && this.layoutManager.isContentCollapsingRequired();
  },
  CalculateContentHeight: function() {
   if(!this.adjustmentVars.content.needAdjustment) return;
   var mainElement = this.GetMainElement();
   var hasFixedHeight = !this.emptyHeight && !this.heightValueSetInPercentage;
   var contentHeight = 0,
    controlHeight = 0;
   if(hasFixedHeight)
    controlHeight = ASPx.PxToFloat(mainElement.style.height);
   else if(this.IsTopBottomTabPosition())
    controlHeight = this.adjustmentVars.controlSizes.secondary;
   else
    controlHeight = this.adjustmentVars.controlSizes.primary;
   if(this.IsTopBottomTabPosition()) {
    var stripContainer = this.GetTabStripContainer();
    var stripHeight = 0;
    if(stripContainer)
     stripHeight = this.adjustmentVars.stripSizes.secondary + this.GetCachedBordersPaddingsMarginsWidth(stripContainer, "height");
    contentHeight = controlHeight - stripHeight;
   }
   else
    contentHeight = controlHeight;
   this.adjustmentVars.content.height = contentHeight;
  },
  UpdateStripSizes: function(primarySize) {
   this.adjustmentVars.stripSizes.primary = primarySize;
   if(!this.enableScrolling)
    this.adjustmentVars.stripFullSize = this.adjustmentVars.stripSizes.primary + this.minLeftIndentSizeLite + this.minRightIndentSizeLite;
  },
  AdjustPageContents: function () {
   if(!(this.adjustmentVars.content.needAdjustment)) return;
   var contentContainer = this.GetContentsCell(),
    contentHolder = this.getActiveContentHolder();
   var contentInnerHeight = this.adjustmentVars.content.height - this.GetCachedVerticalBordersPaddingsMarginsWidth(contentContainer);
   contentHolder.style.height = contentInnerHeight + "px";
  },
  UpdateAdjustmentFlags: function () {
   var mainElement = this.GetMainElement();
   if(mainElement) {
    this.UpdatePercentSizeConfig([mainElement.style.width], [mainElement.style.height]);
    if(!this.IsTopBottomTabPosition()) {
     this.primaryDimension = "height";
     this.secondaryDimension = "width";
    }
   }
  },
  GetMaxValue: function (val1, val2) {
   return val1 > val2 ? val1 : val2;
  },
  GetMaxValueExtended: function (val1, val2, val3) {
   var ret = 0;
   for(var i = 0; i < arguments.length; i++) {
    if(arguments[i] > ret)
     ret = arguments[i];
   }
   return ret;
  },
  AdjustTabControlSizeLite: function() {
   this.layoutManager.adjustSize();
  },
  adjustTabControlSizeCore: function () {
   this.CalculateSizes();
   if(!this.GetTabsCell()) {
    this.AdjustPageContents();
    return;
   }
   var controlSize = this.adjustmentVars.controlSizes.primary;
   var tabsSize = this.adjustmentVars.stripSizes.primary;
   var indentsSize = controlSize - tabsSize - this.GetStripContainerBordersPaddingsMarginsWidth();
   this.ClearElementCache(this.GetLeftIndentLite());
   this.ClearElementCache(this.GetRightIndentLite());
   switch(this.tabAlign) {
    case "Left":
     var leftIndentSize = this.GetCachedElementSize(this.GetLeftIndentLite());
     indentsSize = indentsSize - leftIndentSize;
     this.adjustmentVars.indentsSizes = {
      left: leftIndentSize,
      right: this.GetMaxValue(indentsSize, this.minRightIndentSizeLite)
     };
     this.SetCachedElementSize(this.GetRightIndentLite(), this.adjustmentVars.indentsSizes.right);
     break;
    case "Right":
     var rightIndentSize = this.GetCachedElementSize(this.GetRightIndentLite());
     indentsSize = indentsSize - rightIndentSize;
     this.adjustmentVars.indentsSizes = {
      left: this.GetMaxValue(indentsSize, this.minLeftIndentSizeLite),
      right: rightIndentSize
     };
     this.SetCachedElementSize(this.GetLeftIndentLite(), this.adjustmentVars.indentsSizes.left);
     break;
    case "Center":
     indentsSize = Math.floor(indentsSize / 2);
     this.adjustmentVars.indentsSizes.left = this.GetMaxValue(indentsSize, this.minLeftIndentSizeLite);
     this.SetCachedElementSize(this.GetLeftIndentLite(), this.adjustmentVars.indentsSizes.left);
     indentsSize = controlSize - (tabsSize + indentsSize) - this.GetStripContainerBordersPaddingsMarginsWidth();
     this.adjustmentVars.indentsSizes.right = this.GetMaxValue(indentsSize, this.minRightIndentSizeLite);
     this.SetCachedElementSize(this.GetRightIndentLite(), this.adjustmentVars.indentsSizes.right);
     break;
    default:
     indentsSize = this.GetCachedElementSize(this.GetLeftIndentLite()) + this.GetCachedElementSize(this.GetRightIndentLite());
     tabsSize = controlSize - indentsSize;
   }
   if(this.UseProportionalTabSizes()) {
    this.SetStripSizeLite(tabsSize);
    this.UpdateStripSizes(tabsSize);
   }
   this.RecalculateTabStripWidthLite();
   this.AdjustPageContents();
  },
  GetStripContainerBordersPaddingsMarginsWidth: function() {
   if(this.IsTopBottomTabPosition() && !this.enableScrolling)
    return this.GetCachedHorizontalBordersPaddingsMarginsWidth(this.GetTabsCell());
   if(this.enableScrolling)
    return this.GetCachedHorizontalBordersPaddingsMarginsWidth(this.GetScrollVisibleArea().parentNode);
   return this.GetCachedVerticalBordersPaddingsMarginsWidth(this.GetTabsCell());
  },
  GetStripSizeLite: function (storeTabSizes) {
   if(!this.GetTabStripContainer())
    return 0;
   if(storeTabSizes) {
    this.adjustmentVars.tabSizes = {};
    this.adjustmentVars.tabSizesSums = {};
   }
   var size = 0,
    prevSize = 0,
    tab,
    rowIndex = this.IsMultiRow() ? -1 : 0;
   for(var i = 0; i < this.tabs.length; i++) {
    tab = this.GetVisibleTabElement(i);
    if(!tab)
     continue;
    if(this.isTabElementStartsNewLine(tab)) {
     rowIndex++;
     if(prevSize < size)
      prevSize = size;
     size = 0;
    }
    if(!this.GetTab(i).clientVisible)
     continue;
    var tabSize = this.GetCachedElementSize(tab, this.primaryDimension);
    if(storeTabSizes) {
     this.adjustmentVars.tabSizes[i] = tabSize;
     var tabSizesSums = this.adjustmentVars.tabSizesSums;
     if(!ASPx.IsExists(tabSizesSums[rowIndex]))
      tabSizesSums[rowIndex] = 0;
     tabSizesSums[rowIndex] += tabSize;
    }
    var separator = this.GetSeparatorElement(i);
    size += tabSize + this.GetCachedElementSize(separator, this.primaryDimension);
   }
   if(prevSize > size)
    size = prevSize;
   return size;
  },
  GetTabRows: function() {
   var rows = [],
    tabLines = this.getTabLines();
   for(var rowIndex = 0, tabLine; tabLine = tabLines[rowIndex]; rowIndex++) {
    var row = [];
    rows.push(row);
    for(var tabIndex = 0, tab; tab = tabLine[tabIndex]; tabIndex++) {
     if(tab.GetVisible())
      row.push(tab.index);
    }
   }
   return rows;
  },
  SetStripSizeLite: function (size) {
   var spacerSize = this.GetTabSpaceSizeLite(),
    rows = this.GetTabRows();
   for(var i = 0; i < rows.length; i++) {
    var row = rows[i],
     count = row.length,
     rowSize = size - spacerSize * (count - 1),
     newTabSizesSum = 0;
    for(var index = 0; index < count; index++) {
     var tabIndex = row[index],
      tabSize = this.adjustmentVars.tabSizes[tabIndex],
      newTabSizePrecise = rowSize * (tabSize / this.adjustmentVars.tabSizesSums[i]),
      newTabSize = this.GetPreparedSizeValue(newTabSizePrecise);
     newTabSizesSum += newTabSize;
     if(index == count - 1)
      newTabSize += rowSize - newTabSizesSum;
     var activeTabElement = this.GetTabElement(tabIndex, true),
      tabElement = this.GetTabElement(tabIndex, false);
     this.SetCachedElementSize(activeTabElement, newTabSize);
     this.SetCachedElementSize(tabElement, newTabSize);
     this.ClearElementCache(activeTabElement);
     this.ClearElementCache(tabElement);
    }
   }
  },
  getTabSpacerElement: function() {
   var spacerClassName = Constants.CssClassName.TAB_SPACER;
   if(this.IsMultiRow()) {
    var tabsHolder = this.getTabsHolderElement();
    return ASPx.GetNodeByClassName(tabsHolder, spacerClassName, 0);
   }
   return ASPx.GetChildByClassName(this.GetTabsCell(), spacerClassName);
  },
  GetTabSpaceSizeLite: function() {
   var spacer = this.getTabSpacerElement();
   return spacer ? this.GetCachedElementSize(spacer) : 0;
  },
  RecalculateTabStripWidthLite: function(stripSize, leftIndentSize, rightIndentSize) {
   if(!this.IsTopBottomTabPosition())
    return;
   if(stripSize === undefined)
    stripSize = this.adjustmentVars.stripSizes.primary;
   if(leftIndentSize === undefined)
    leftIndentSize = this.adjustmentVars.indentsSizes.left;
   if(rightIndentSize === undefined)
    rightIndentSize = this.adjustmentVars.indentsSizes.right;
   if(this.IsMultiRow())
    stripSize = this.GetPreparedSizeValue(stripSize);
   var tabStrip = this.GetTabsCell(),
    tabStripActualWidth = stripSize + leftIndentSize + rightIndentSize;
   if(this.enableScrolling)
    tabStripActualWidth += this.scrollingFillerElementWidth;
   tabStripActualWidth = this.GetPreparedSizeValue(tabStripActualWidth, true);
   tabStrip.style.width = tabStripActualWidth + "px";
   if(this.IsMultiRow()) {
    var tabsHolder = this.getTabsHolderElement();
    tabsHolder.style.width = stripSize + "px";
   }
  },
  GetPreparedSizeValue: function(sizeValue, reserve) {
   if(!(ASPx.Browser.Chrome && ASPx.Browser.MajorVersion >= 45 || ASPx.Browser.IE && ASPx.Browser.MajorVersion >= 9))
    return sizeValue;
   if(ASPx.Browser.Chrome)
    return +(Math.ceil(sizeValue + "e+2") + "e-2");
   if(ASPx.Browser.MajorVersion == 10 && reserve)
    return sizeValue + 0.1;
   var res = Math.floor(sizeValue);
   while(res < sizeValue)
    res += 0.1;
   return res;
  },
  SetCachedElementSize: function(element, size, dimension) {
   this.SetCachedElementSizeCore(element, size, dimension, "SetCachedElement");
  },
  SetCachedElementSizeCore: function(element, size, dimension, funcNamePrefix) {
   if(!element) return;
   if(!dimension)
    dimension = this.primaryDimension;
   var funcName = funcNamePrefix + (dimension == "width" ? "Width" : "Height");
   this[funcName](element, size);
  },
  SetCachedElementWidth: function(element, width) {
   var cache = this.GetOrCreateElementCache(element);
   this.SetElementSize(element, width, cache.horizontalBordersPaddingsMarginsWidth, "width");
  },
  SetCachedElementHeight: function(element, height) {
   var cache = this.GetOrCreateElementCache(element);
   this.SetElementSize(element, height, cache.verticalBordersPaddingsMarginsWidth, "height");
  },
  SetCachedElementOffsetSize: function(element, size, dimension) {
   this.SetCachedElementSizeCore(element, size, dimension, "SetCachedElementOffset");
  },
  SetCachedElementOffsetWidth: function(element, width) {
   var cache = this.GetOrCreateElementCache(element);
   this.SetElementSize(element, width, cache.horizontalBordersAndPaddingsWidth, "width");
  },
  SetCachedElementOffsetHeight: function(element, height) {
   var cache = this.GetOrCreateElementCache(element);
   this.SetElementSize(element, height, cache.verticalBordersAndPaddingsWidth, "height");
  },
  SetElementSize: function(element, value, correction, dimension) {
   value -= correction;
   if(value >= 0)
    element.style[dimension] = value + "px";
  },
  GetLeftIndentLite: function () {
   var container = this.GetTabStripContainer();
   return container
    ? ASPx.GetNodesByPartialClassName(container, Constants.CssClassName.LEFT_INDENT)[0]
    : null;
  },
  GetRightIndentLite: function () {
   var container = this.GetTabStripContainer();
   return container
    ? ASPx.GetNodesByPartialClassName(container, Constants.CssClassName.RIGHT_INDENT)[0]
    : null;
  },
  GetTabsCellID: function () {
   return "_TC";
  },
  GetTabsCell: function () {
   return this.GetChildElement(this.GetTabsCellID());
  },
  GetTabsCellWrapperID: function () {
   return "_WC";
  },
  GetTabsCellWrapperElement: function () {
   return this.GetChildElement(this.GetTabsCellWrapperID());
  },
  GetTabStripContainer: function () {
   return this.enableScrolling ? this.GetTabsCellWrapperElement() : this.GetTabsCell();
  },
  GetTabElementID: function (index, active) {
   return "_" + (active ? "A" : "") + "T" + index;
  },
  GetTabElement: function (index, active) {
   return this.GetChildElement(this.GetTabElementID(index, active));
  },
  GetTabsElements: function() {
   var tabsCell = this.GetTabsCell();
   if(!tabsCell)
    return [];
   var getNodesFunc = this.IsMultiRow() ? ASPx.GetNodes : ASPx.GetChildNodes;
   return getNodesFunc(tabsCell, function(el) {
    return el.tagName === "LI" && el.className && this.isTabElement(el);
   }.aspxBind(this));
  },
  GetVisibleTabElement: function (index) {
   return this.GetChildElement(this.GetTabElementID(index, index == this.activeTabIndex));
  },
  GetContentsCellID: function () {
   return "_CC";
  },
  GetContentsCell: function () {
   return this.GetChildElement(this.GetContentsCellID());
  },
  GetContentElementID: function (index) {
   return "_C" + index;
  },
  GetContentElement: function (index) {
   return this.GetChildElement(this.GetContentElementID(index));
  },
  getActiveContentElement: function() {
   return this.GetContentElement(this.activeTabIndex);
  },
  GetContentHolder: function (index) {
   var contentElement = this.GetContentElement(index);
   if(!contentElement)
    return null;
   return ASPx.GetChildByTagName(contentElement, "DIV");
  },
  getActiveContentHolder: function() {
   return this.GetContentHolder(this.activeTabIndex);
  },
  GetSeparatorElementID: function (index) {
   return "_T" + index + "S";
  },
  GetSeparatorElement: function (index) {
   return this.GetChildElement(this.GetSeparatorElementID(index));
  },
  GetScrollVisibleAreaID: function () {
   return "_SVA";
  },
  GetScrollVisibleArea: function () {
   return this.GetChildElement(this.GetScrollVisibleAreaID());
  },
  GetScrollableArea: function () {
   return this.GetTabsCell();
  },
  GetScrollLeftButtonID: function () {
   return "_SBL";
  },
  GetScrollLeftButtonElement: function () {
   return this.GetChildElement(this.GetScrollLeftButtonID());
  },
  GetScrollLeftButtonContainer: function () {
   return this.GetScrollLeftButtonElement().parentNode;
  },
  GetScrollRightButtonID: function () {
   return "_SBR";
  },
  GetScrollRightButtonElement: function () {
   return this.GetChildElement(this.GetScrollRightButtonID());
  },
  GetScrollRightButtonContainer: function () {
   return this.GetScrollRightButtonElement().parentNode;
  },
  IsTopBottomTabPosition: function () {
   return (this.tabPosition == "Top" || this.tabPosition == "Bottom");
  },
  getAreAllTabsHidden: function() {
   return this.GetNextVisibleTabIndex(-1) === -1;
  },
  isInsideVisibleContainer: function() {
   return this.IsDisplayed() && !this.IsHidden();
  },
  IsControlVisible: function() {
   return this.clientVisible && !this.getAreAllTabsHidden() && this.isInsideVisibleContainer();
  },
  isTabElement: function(element) {
   return ASPx.ElementHasCssClass(element, Constants.CssClassName.TAB)
    || ASPx.ElementHasCssClass(element, Constants.CssClassName.ACTIVE_TAB);
  },
  isTemplateIndentElement: function(element) {
   return ASPx.ElementHasCssClass(element, Constants.CssClassName.INDENT_TEMPLATE);
  },
  isTabElementStartsNewLine: function(element) {
   return ASPx.ElementHasCssClass(element, Constants.CssClassName.NEW_LINE_START_TAB);
  },
  FixControlSize: function () {
   this.FixElementSize(this.GetMainElement());
   var contentCell = this.GetContentsCell();
   if(!contentCell) return;
   var width = (ASPx.Browser.IE ? contentCell.clientWidth : contentCell.offsetWidth);
   var height = (ASPx.Browser.IE ? contentCell.clientHeight : contentCell.offsetHeight);
   width -= this.GetCachedHorizontalBordersAndPaddingsWidth(contentCell);
   height -= this.GetCachedVerticalBordersAndPaddingsWidth(contentCell);
   ASPx.Attr.ChangeStyleAttribute(contentCell, "width", width + "px");
   ASPx.Attr.ChangeStyleAttribute(contentCell, "height", height + "px");
  },
  UnfixControlSize: function () {
   this.UnfixElementSize(this.GetMainElement());
   this.UnfixElementSize(this.GetContentsCell());
  },
  FixElementSize: function (element) {
   if(element == null) return;
   var width = (ASPx.Browser.IE ? element.clientWidth : element.offsetWidth);
   var height = (ASPx.Browser.IE ? element.clientHeight : element.offsetHeight);
   ASPx.Attr.ChangeStyleAttribute(element, "width", width + "px");
   ASPx.Attr.ChangeStyleAttribute(element, "height", height + "px");
  },
  UnfixElementSize: function (element) {
   if(element == null) return;
   ASPx.Attr.RestoreStyleAttribute(element, "width");
   ASPx.Attr.RestoreStyleAttribute(element, "height");
  },
  AdjustSize: function () {
   this.adjustControlInternal();
  },
  adjustControlInternal: function() {
   this.AdjustControlCore();
   var cache = this.adjustmentVars.mainElementCache;
   var width = Math.ceil(cache.offsetWidth);
   var height = Math.ceil(cache.offsetHeight);
   this.adjustedSizes = { width: width, height: height };
  },
  AdjustControlCore: function () {
   ASPxClientControl.prototype.AdjustControlCore.call(this);
   this.EnsureControlInitialized();
   this.SetObservationPaused(true);
   this.UpdateLayout();
   this.ProcessDeferredActions();
   this.SetObservationPaused(false);
  },
  ProcessDeferredActions: function() {
   while(this.deferredActions.length > 0) {
    var action = this.deferredActions[0];
    try {
     this.SetTabVisibleCore(action.tabIndex, action.setVisible);
    }
    finally {
     ASPx.Data.ArrayRemoveAt(this.deferredActions, 0);
    }
   }
  },
  IsAdjustmentRequired: function() {
   if(this.deferredActions.length > 0)
    return true;
   return ASPxClientControl.prototype.IsAdjustmentRequired.call(this);
  },
  UpdateLayout: function () {
   if(!this.enableScrolling)
    this.AdjustTabControlSizeLite();
   else
    this.AdjustTabScrolling(this.scrollToActiveTab, false);
   this.AdjustTabContents();
  },
  AdjustAutoHeight: function () {
   if(!this.IsAdjustmentAllowed())
    return;
   this.EnsureControlInitialized();
   this.UpdateAutoHeight();
  },
  UpdateAutoHeight: function () {
   this.AdjustPageContents();
  },
  SetWidth: function(width) {
   var success = this.SetSizeInternal(width, "width");
   if(success && this.emptyWidth)
    this.emptyWidth = false;
  },
  SetHeight: function(height) {
   var success = this.SetSizeInternal(height, "height");
   if(success && this.emptyHeight)
    this.emptyHeight = false;
  },
  SetSizeInternal: function(value, dimension) {
   if(value < 0)
    return false;
   var mainElement = this.GetMainElement();
   var offsetSize = this.GetCachedElementInnerSize(mainElement, dimension) 
    + this.GetCachedBordersAndPaddingsWidth(mainElement, dimension);
   if(offsetSize === value)
    return false;
   this.SetCachedElementOffsetSize(mainElement, value, dimension);
   this.ClearElementCache(mainElement);
   this.ResetControlAdjustment();
   this.UpdateAdjustmentFlags();
   this.AdjustControl(true);
   return true;
  },
  CanLoadTabOnCallback: function (index) {
   return this.isLoadTabByCallback && ASPx.IsFunction(this.callBack);
  },
  ChangeTabState: function (index, active) {
   var element = this.GetTabElement(index, true);
   if(element != null) ASPx.SetElementDisplay(element, active);
   element = this.GetTabElement(index, false);
   if(element != null) ASPx.SetElementDisplay(element, !active);
   element = this.GetContentElement(index);
   if(element != null) ASPx.SetElementDisplay(element, active);
   this.tabHeightManager.requestAdjustment();
  },
  ChangeActiveTab: function (index, hasLink) {
   this.SetObservationPaused(true);
   var processingMode = this.RaiseActiveTabChanging(index);
   if(processingMode == "Client" || processingMode == "ClientWithReload") {
    var element = this.GetContentElement(index);
    if(this.CanLoadTabOnCallback(index) && element != null && (!element.loaded || processingMode == "ClientWithReload")) {
     if(this.callbackCount == 0)
      this.FixControlSize();
     this.DoChangeActiveTab(index);
     this.isActiveTabChanged = true;
     this.PerformCallbackInternal(index, element);
    }
    else {
     this.DoChangeActiveTab(index);
     if(this.GetMainElement()) {
      var activeContentElement = this.getActiveContentElement();
      if(activeContentElement) {
       window.setTimeout(function() {
        this.onActiveTabChangedTimeout(activeContentElement);
       }.aspxBind(this), 0);
      }
     }
     this.RaiseActiveTabChanged(index);
    }
   }
   else if(processingMode == "Server" && !hasLink)
    this.SendPostBack("ACTIVATE:" + index);
   this.SetObservationPaused(false);
  },
  onActiveTabChangedTimeout: function(activeContentElement) {
   this.DoSafeScrollPositionOperation(function() {
    this.onActiveTabChangedTimeoutCore(activeContentElement);
   }.aspxBind(this));
  },
  onActiveTabChangedTimeoutCore: function(activeContentElement) {
   this.SetObservationPaused(true);
   activeContentElement.style.position = "fixed";
   this.layoutManager.calculateSizes();
   activeContentElement.style.position = "";
   this.AdjustPageContents();
   ASPx.GetControlCollection().AdjustControlsCore(activeContentElement, true);
   this.adjustControlInternal();
   this.SetObservationPaused(false);
  },
  PerformCallbackInternal: function (tabIndex, tabContentElement, callbackArgument, handler) {
   if(typeof (callbackArgument) == "undefined")
    callbackArgument = tabIndex;
   if(!tabContentElement.loading) {
    this.callbackCount++;
    tabContentElement.loading = true;
    this.tabsContentRequest.push(tabIndex);
    this.ShowLoadingPanelInTabPage(tabIndex);
    this.CreateCallback(callbackArgument, null, handler);
   }
  },
  IsMultiRow: function () {
   if(!ASPx.IsExists(this.isMultiRow))
    this.isMultiRow = ASPx.ElementHasCssClass(this.GetMainElement(), Constants.CssClassName.MULTIROW);
   return this.isMultiRow;
  },
  UseProportionalTabSizes: function () {
   return this.IsMultiRow() || this.tabAlign == "Justify";
  },
  PlaceActiveTabRowToBottom: function(activeTabIndex) {
   var activeTabElement = this.GetVisibleTabElement(activeTabIndex);
   var newActiveRow = this.getTabRowByTabElement(activeTabElement);
   var currentActiveRow = this.getActiveTabRow();
   if(newActiveRow != currentActiveRow) {
    var tabsHolderElement = this.getTabsHolderElement();
    tabsHolderElement.insertBefore(currentActiveRow, newActiveRow);
    var refElement = this.tabPosition == "Top" ? null : tabsHolderElement.firstChild;
    tabsHolderElement.insertBefore(newActiveRow, refElement);
   }
   this.adjustTabRowsSpacing();
   this.replaceCssClassForChildren(currentActiveRow, Constants.CssClassName.ACTIVE_ROW_ITEM, "");
   this.replaceCssClassForChildren(newActiveRow, "", Constants.CssClassName.ACTIVE_ROW_ITEM);
  },
  getTabRowByTabElement: function(tabElement) {
   return tabElement.parentNode;
  },
  getTabsHolderElement: function() {
   var stripElement = this.GetTabsCell();
   return ASPx.GetChildByClassName(stripElement, Constants.CssClassName.TABS_HOLDER, 0);
  },
  getTabRows: function() {
   var tabsHolderElement = this.getTabsHolderElement();
   return ASPx.GetChildNodesByClassName(tabsHolderElement, Constants.CssClassName.TAB_ROW);
  },
  getActiveTabRow: function() {
   var tabRows = this.getTabRows();
   var rowIndex = this.getActiveTabRowIndex(tabRows);
   return tabRows[rowIndex];
  },
  getActiveTabRowIndex: function(tabRows) {
   return this.getActiveTabRowIndexCore(tabRows.length);
  },
  getActiveTabRowIndexCore: function(rowCount) {
   return this.tabPosition == "Top" ? rowCount - 1 : 0;
  },
  replaceCssClassForChildren: function(parentElement, className, newClassName) {
   var children = ASPx.GetChildElementNodes(parentElement);
   this.ReplaceCssClassLite(children, className, newClassName);
  },
  adjustTabRowsSpacing: function() {
   var tabSpace = this.GetTabSpaceSizeLite(); 
   var tabRows = this.getTabRows();
   var activeRowIndex = this.getActiveTabRowIndex(tabRows);
   var propName = "padding" + (this.tabPosition == "Top" ? "Bottom" : "Top");
   var paddingValue = tabSpace + "px";
   var nullPaddingValue = "0";
   for(var i = 0; i < tabRows.length; i++) {
    var tabRow = tabRows[i];
    var value = i == activeRowIndex ? nullPaddingValue : paddingValue;
    tabRow.style[propName] = value;
   }
  },
  ReplaceCssClassLite: function (collection, className, newClassName) {
   for(var i = 0; i < collection.length; i++) {
    if(!collection[i]) continue;
    var c = collection[i].className.replace(className, "");
    collection[i].className = ASPx.Str.Trim(c);
    if(newClassName != "")
     collection[i].className += " " + newClassName;
   }
  },
  DoChangeActiveTab: function (index) {
   if(ASPx.Browser.Firefox && ASPx.Browser.Version >= 3) { 
    var contentsCell = this.GetContentsCell();
    var isContentsCellExists = ASPx.IsExistsElement(contentsCell);
    if(isContentsCellExists)
     ASPx.SetElementVisibility(contentsCell, false);
    this.ChangeTabState(index, true);
    this.ChangeTabState(this.activeTabIndex, false);
    this.activeTabIndex = index;
    if(isContentsCellExists)
     ASPx.SetElementVisibility(contentsCell, true);
   } else {
    this.ChangeTabState(this.activeTabIndex, false);
    this.activeTabIndex = index;
    this.ChangeTabState(this.activeTabIndex, true);
   }
   if(this.enableScrolling)
    this.AdjustTabScrolling(this.scrollToActiveTab, true);
   else
    this.AdjustTabControlSizeLite();
   if(this.IsMultiRow())
    this.PlaceActiveTabRowToBottom(index);
   this.AdjustTabContents();
   this.UpdateActiveTabIndexCookie();
  },
  SetActiveTabIndexInternal: function (index, hasLink) {
   if(this.activeTabIndex == index) return;
   this.DoSafeScrollPositionOperation(function () {
    this.ChangeActiveTab(index, hasLink);
   }.aspxBind(this));
   this.UpdateHoverState(index);
  },
  SwitchActiveTab: function(toNext) {
   var index = this.GetActiveTabIndex();
   toNext ? index++ : index--;
   for (var i = index, tab; tab = this.tabs[i]; toNext ? i++ : i--) {
    if(tab.GetVisible()) {
     this.SetActiveTab(tab);
     return;
    }
   }
  },
  UpdateActiveTabIndexCookie: function () {
   if(this.cookieName == "") return;
   ASPx.Cookie.DelCookie(this.cookieName);
   ASPx.Cookie.SetCookie(this.cookieName, this.activeTabIndex);
  },
  UpdateHoverState: function (index) {
   if(!this.IsStateControllerEnabled()) return;
   var element = this.GetTabElement(index, true);
   if(element != null) ASPx.GetStateController().SetCurrentHoverElementBySrcElement(element);
  },
  OnTabClick: function (evt, index) {
   var processingMode = this.RaiseTabClick(index, evt);
   var clickedLinkElement = ASPx.GetParentByTagName(ASPx.Evt.GetEventSource(evt), "A");
   var isLinkClicked = (clickedLinkElement != null && !!clickedLinkElement.href && clickedLinkElement.href != ASPx.AccessibilityEmptyUrl);
   var element = this.GetTabElement(index, false);
   var linkElement = (element != null) ? ASPx.GetNodeByTagName(element, "A", 0) : null;
   if(linkElement != null && (!linkElement.href || linkElement.href == ASPx.AccessibilityEmptyUrl))
    linkElement = null;
   if(processingMode != "Handled") {
    var hasLink = isLinkClicked || linkElement != null;
    if(processingMode == "Server" && !hasLink)
     this.SendPostBack("CLICK:" + index);
    else
     this.SetActiveTabIndexInternal(index, hasLink);
    var isMouseDownAction = this.tabAction == Constants.TabAction.MOUSE_DOWN;
    if(this.handleClickOnWholeTab && (!isLinkClicked || isMouseDownAction) && linkElement != null)
     ASPx.Url.NavigateByLink(linkElement);
   }
  },
  OnCallback: function (result) {
   this.OnCallbackInternal(result.html, result.index, false);
  },
  OnCallbackError: function (result, data) {
   this.OnCallbackInternal(result, data, true);
  },
  OnCallbackInternal: function (html, index, isError) {
   this.SetCallbackContent(html, index, isError);
   ASPx.Data.ArrayRemoveAt(this.tabsContentRequest, 0);
   if(!isError && this.isActiveTabChanged) {
    this.isActiveTabChanged = false;
    this.shouldRaiseActiveTabChangedEvent = true;
   }
   if(this.enableCallbackAnimation)
    ASPx.AnimationHelper.fadeIn(this.GetContentElement(index), function () { this.OnCallbackFinish(index); }.aspxBind(this));
  },
  OnCallbackFinish: function (index) {
   this.adjustControlInternal();
   if(this.shouldRaiseActiveTabChangedEvent) {
    this.shouldRaiseActiveTabChangedEvent = false;
    if(!ASPx.IsExists(index))
     index = this.GetActiveTabIndex();
    this.RaiseActiveTabChanged(index);
   }
  },
  OnCallbackFinalized: function () {
   if(!this.enableCallbackAnimation)
    this.OnCallbackFinish();
  },
  OnCallbackGeneralError: function (result) {
   var callbackTabIndex = (this.tabsContentRequest.length > 0) ? this.tabsContentRequest[0] : this.activeTabIndex;
   this.SetCallbackContent(result, callbackTabIndex, true);
   ASPx.Data.ArrayRemoveAt(this.tabsContentRequest, 0);
  },
  ShowLoadingPanelInTabPage: function (index) {
   if(this.lpDelay > 0)
    window.setTimeout(function () { this.ShowLoadingPanelInTabPageCore(index); }.aspxBind(this), this.lpDelay);
   else
    this.ShowLoadingPanelInTabPageCore(index);
  },
  ShowLoadingPanelInTabPageCore: function (index) {
   if(ASPx.Data.ArrayIndexOf(this.tabsContentRequest, index) < 0) return;
   var element = this.GetContentHolder(index);
   var hasContent = !!ASPx.Str.Trim(this.GetTabContentHTML(this.GetTab(index)));
   var loadingPanelElement = this.CreateLoadingPanelWithAbsolutePosition(element, this.GetContentsCell());
   if(!hasContent && loadingPanelElement)
    ASPx.AddClassNameToElement(loadingPanelElement, "dxlp-withoutBorders");
  },
  ShouldHideExistingLoadingElements: function () {
   return false;
  },
  SetCallbackContent: function (html, index, isError) {
   this.SetObservationPaused(true);
   var element = this.GetContentElement(index);
   if(element != null) {
    if(!isError)
     element.loaded = true;
    element.loading = false;
    ASPx.SetInnerHtml(this.GetContentHolder(index), html);
    this.callbackCount--;
    if(this.callbackCount == 0)
     this.UnfixControlSize();
   }
   this.SetObservationPaused(false);
  },
  CreateTabs: function (tabsProperties) {
   for(var i = 0; i < tabsProperties.length; i++) {
    var tabName = tabsProperties[i][0] || "";
    var tab = new ASPxClientTab(this, i, tabName);
    this.CreateTabProperties(tab, tabsProperties[i]);
    this.tabs.push(tab);
   }
  },
  CreateTabProperties: function (tab, tabProperties) {
   if(ASPx.IsExists(tabProperties[1]))
    tab.enabled = tabProperties[1];
   if(ASPx.IsExists(tabProperties[2]))
    tab.clientEnabled = tabProperties[2];
   if(ASPx.IsExists(tabProperties[3]))
    tab.visible = tabProperties[3];
   if(ASPx.IsExists(tabProperties[4]))
    tab.clientVisible = tabProperties[4];
   if(ASPx.IsExists(tabProperties[5]))
    tab.newLine = tabProperties[5];
  },
  RaiseTabClick: function (index, htmlEvent) {
   var processingMode = this.autoPostBack || this.IsServerEventAssigned("TabClick") ? "Server" : "Client";
   if(!this.TabClick.IsEmpty()) {
    var htmlElement = this.GetTabElement(index, this.activeTabIndex == index);
    var args = new ASPxClientTabControlTabClickEventArgs(processingMode == "Server", this.GetTab(index), htmlElement, htmlEvent);
    this.TabClick.FireEvent(this, args);
    if(args.cancel)
     processingMode = "Handled";
    else
     processingMode = args.processOnServer ? "Server" : "Client";
   }
   return processingMode;
  },
  RaiseActiveTabChanged: function (index) {
   if(!this.ActiveTabChanged.IsEmpty()) {
    var args = new ASPxClientTabControlTabEventArgs(this.GetTab(index));
    this.ActiveTabChanged.FireEvent(this, args);
   }
  },
  RaiseActiveTabChanging: function (index) {
   var processingMode = this.autoPostBack ? "Server" : "Client";
   if(!this.ActiveTabChanging.IsEmpty()) {
    var args = new ASPxClientTabControlTabCancelEventArgs(processingMode == "Server", this.GetTab(index));
    this.ActiveTabChanging.FireEvent(this, args);
    if(args.cancel)
     processingMode = "Handled";
    else if(args.processOnServer)
     processingMode = "Server";
    else
     processingMode = args.reloadContentOnCallback ? "ClientWithReload" : "Client";
   }
   return processingMode;
  },
  SetEnabled: function (enabled) {
   for(var i = this.GetTabCount() - 1; i >= 0; i--) {
    var tab = this.GetTab(i);
    tab.SetEnabled(enabled, true );
   }
  },
  GetActiveTab: function () {
   return (this.activeTabIndex > -1) ? this.GetTab(this.activeTabIndex) : null;
  },
  SetActiveTab: function (tab) {
   if(this.IsTabVisible(tab.index))
    this.SetActiveTabIndexInternal(tab.index, false);
  },
  GetActiveTabIndex: function () {
   return this.activeTabIndex;
  },
  SetActiveTabIndex: function (index) {
   if(index < 0 || index >= this.tabs.length) return;
   if(this.IsTabVisible(index))
    this.SetActiveTabIndexInternal(index, false);
  },
  GetTabCount: function () {
   return this.tabs.length;
  },
  GetTab: function (index) {
   return (0 <= index && index < this.tabs.length) ? this.tabs[index] : null;
  },
  GetTabByName: function (name) {
   for(var i = 0; i < this.tabs.length; i++)
    if(this.tabs[i].name == name) return this.tabs[i];
   return null;
  },
  IsTabEnabled: function (index) {
   return this.tabs[index].GetEnabled();
  },
  SetTabEnabled: function (index, enabled, initialization, doNotChangeActiveTab) {
   if(!this.tabs[index].enabled) return;
   this.ClearTabElementsCache(index);
   if(!initialization || !enabled)
    this.ChangeTabEnabledStateItems(index, enabled);
   this.ChangeTabEnabledAttributes(index, enabled, doNotChangeActiveTab);
   if(!initialization && this.canUseOffsetSizes())
    this.adjustControlInternal();
  },
  ChangeTabEnabledAttributes: function (index, enabled, doNotChangeActiveTab) {
   if(enabled) {
    this.ChangeTabElementsEnabledAttributes(index, ASPx.Attr.RestoreAttribute, ASPx.Attr.RestoreStyleAttribute);
    var isActiveTabEnabled = this.activeTabIndex != -1 ? this.IsTabEnabled(this.activeTabIndex) : false;
    if(!doNotChangeActiveTab && !isActiveTabEnabled && this.IsTabVisible(index))
     this.SetActiveTabIndexInternal(index, false);
   }
   else {
    if(this.activeTabIndex == index && !doNotChangeActiveTab) {
     for(var i = 0; i < this.GetTabCount() ; i++) {
      if(this.IsTabVisible(i) && this.IsTabEnabled(i) && i != index) {
       this.SetActiveTabIndexInternal(i, false);
       break;
      }
     }
    }
    this.ChangeTabElementsEnabledAttributes(index, ASPx.Attr.ResetAttribute, ASPx.Attr.ResetStyleAttribute);
   }
  },
  ChangeTabElementsEnabledAttributes: function (index, method, styleMethod) {
   var eventName = this.getTabActivationHtmlEventName();
   var element = this.GetTabElement(index, false);
   if(element) {
    method(element, eventName);
    styleMethod(element, "cursor");
    var link = this.GetInternalHyperlinkElement(element, 0);
    if(link != null) {
     method(link, "href");
     styleMethod(link, "cursor");
    }
    link = this.GetInternalHyperlinkElement(element, 1);
    if(link != null) {
     method(link, "href");
     styleMethod(link, "cursor");
    }
   }
   var activeElement = this.GetTabElement(index, true);
   if(activeElement) {
    method(activeElement, eventName);
    styleMethod(activeElement, "cursor");
   }
  },
  getTabActivationHtmlEventName: function() {
   switch(this.tabAction) {
    case Constants.TabAction.CLICK:
     return "onclick";
    case Constants.TabAction.MOUSE_OVER:
     return "onmouseover";
    case Constants.TabAction.MOUSE_DOWN:
     return ASPx.Browser.WebKitTouchUI ? "ontouchstart" : "onmousedown";
   }
   throw "This mode is not supported";
  },
  ChangeTabEnabledStateItems: function (index, enabled) {
   if(!this.IsStateControllerEnabled()) return;
   var element = this.GetTabElement(index, false);
   if(element != null) ASPx.GetStateController().SetElementEnabled(element, enabled);
   var activeElement = this.GetTabElement(index, true);
   if(activeElement != null) ASPx.GetStateController().SetElementEnabled(activeElement, enabled);
  },
  GetTabImageUrl: function (index, active) {
   var imgEl = this.GetTabInsideElement(index, active, Constants.CssClassName.TAB_IMAGE);
   return imgEl ? imgEl.src : "";
  },
  SetTabImageUrl: function (index, active, url) {
   var imgEl = this.GetTabInsideElement(index, active, Constants.CssClassName.TAB_IMAGE);
   if(imgEl) {
    imgEl.src = url;
    var tabEl = this.GetTabElement(index, active);
    this.ClearElementCache(tabEl);
    this.tabHeightManager.requestAdjustment();
    this.adjustControlInternal();
   }
  },
  GetTabNavigateUrl: function (index) {
   var linkEl = this.GetTabInsideElement(index, false, Constants.CssClassName.TAB_LINK);
   return linkEl ? (linkEl.href || ASPx.Attr.GetAttribute(linkEl, "savedhref")) : "";
  },
  SetTabNavigateUrl: function (index, url) {
   var linkEl = this.GetTabInsideElement(index, false, Constants.CssClassName.TAB_LINK);
   if(linkEl) {
    if(ASPx.Attr.IsExistsAttribute(linkEl, "savedhref"))
     ASPx.Attr.SetAttribute(linkEl, "savedhref", url);
    else if(ASPx.Attr.IsExistsAttribute(linkEl, "href"))
     linkEl.href = url;
   }
  },
  GetTabText: function (index) {
   var isActive = index == this.GetActiveTabIndex();
   var element = this.GetTabInsideElement(index, isActive, Constants.CssClassName.TAB_LINK);
   if(element) {
    var textNode = ASPx.GetTextNode(element);
    if(textNode != null)
     return textNode.nodeValue;
   }
   return "";
  },
  SetTabText: function (index, text) {
   this.SetTabTextInternal(index, false, text);
   this.SetTabTextInternal(index, true, text);
   this.ClearTabElementsCache(index);
   this.adjustControlInternal();
  },
  SetTabTextInternal: function (index, isActive, text) {
   var element = this.GetTabInsideElement(index, isActive, Constants.CssClassName.TAB_LINK);
   if(element != null) {
    var textNode = ASPx.GetTextNode(element);
    if(textNode != null)
     textNode.nodeValue = text;
   }
  },
  GetTabInsideElement: function (index, isActive, insideClassName) {
   var tabElement = this.GetTabElement(index, isActive);
   if(!tabElement)
    return null;
   var c = ASPx.GetNodesByClassName(tabElement, insideClassName);
   return null || (c.length > 0 && c[0]);
  },
  IsTabVisible: function (index) {
   return this.tabs[index].GetVisible();
  },
  IsTabStartOutOfScrollArea: function (index) {
   var width = 0;
   for(var i = 0; i < index; i++) {
    width += this.GetVisibleTabElement(index).offsetWidth;
    var separator = this.GetSeparatorElement(index);
    if(separator)
     width += separator.offsetWidth;
   }
   return Math.abs(this.scrollManager.GetScrolledAreaPosition()) > width;
  },
  SetTabVisible: function(index, visible) {
   var needResetDisplay = this.clientVisible && this.getAreAllTabsHidden();
   var mainElement;
   if(needResetDisplay) {
    mainElement = this.GetMainElement();
    mainElement.style.display = "";
   }
   var controlVisible = this.clientVisible && this.isInsideVisibleContainer();
   if(needResetDisplay && (!controlVisible || this.isFullyInitialized))
    mainElement.style.display = "none";
   this.tabs[index].clientVisible = visible;
   if(controlVisible) {
    this.EnsureControlInitialized();
    this.SetTabVisibleCore(index, visible);
   }
   else {
    var action = { 
     tabIndex: index,
     setVisible: visible
    };
    this.deferredActions.push(action);
    if(needResetDisplay && visible)
     mainElement.style.display = "";
   }
  },
  SetTabVisibleCore: function(index, visible, initialization) {
   if(!this.tabs[index].visible || (visible && initialization))
    return;
   this.SetTabVisibleInternal(index, visible);
  },
  SetTabVisibleInternal: function(index, visible) {
   this.SetObservationPaused(true);
   var element = this.GetTabElement(index, false);
   var currentShiftWidth = 0,
    visibleTabElement = this.GetVisibleTabElement(index),
    separatorElement = this.GetSeparatorElement(index);
   if(visibleTabElement)
    currentShiftWidth = visibleTabElement.offsetWidth;
   if(separatorElement)
    currentShiftWidth += separatorElement.offsetWidth;
   var activeElement = this.GetTabElement(index, true);
   var contentElement = this.GetContentElement(index);
   if(!visible) {
    if(this.activeTabIndex == index) {
     for(var i = 0; i < this.GetTabCount() ; i++) {
      if(this.IsTabVisible(i) && this.IsTabEnabled(i) && i != index) {
       this.SetActiveTabIndexInternal(i, false);
       break;
      }
     }
     for(var i = 0; i < this.GetTabCount() ; i++) {
      if(this.IsTabVisible(i) && i != index) {
       this.SetActiveTabIndexInternal(i, false);
       break;
      }
     }
     if(this.activeTabIndex == index) {
      this.activeTabIndex = -1;
      ASPx.SetElementDisplay(this.GetMainElement(), false);
     }
    }
    if(element != null)
     ASPx.SetElementDisplay(element, false);
    if(activeElement != null)
     ASPx.SetElementDisplay(activeElement, false);
    if(contentElement != null)
     ASPx.SetElementDisplay(contentElement, false);
   }
   else {
    if(element != null)
     ASPx.SetElementDisplay(element, this.activeTabIndex != index);
    if(activeElement != null)
     ASPx.SetElementDisplay(activeElement, this.activeTabIndex == index);
    if(contentElement != null)
     ASPx.SetElementDisplay(contentElement, this.activeTabIndex == index);
    if(this.activeTabIndex == -1) {
     ASPx.SetElementDisplay(this.GetMainElement(), true);
     this.SetActiveTabIndexInternal(index, false);
    }
    else if(!this.IsTabEnabled(this.activeTabIndex) && this.IsTabEnabled(index))
     this.SetActiveTabIndexInternal(index, false);
   }
   if(this.GetTabsCell())
    this.updateTabOrderCssMarkers();
   this.SetSeparatorsVisiblility();
   this.tabHeightManager.requestAdjustment();
   if(!this.enableScrolling)
    this.AdjustTabControlSizeLite();
   else {
    this.AdjustTabScrolling(false, false);
    if(this.IsTabStartOutOfScrollArea(index)) {
     currentShiftWidth = visible
      ? (this.GetVisibleTabElement(index).offsetWidth + this.GetSeparatorElement(index).offsetWidth) * (-1)
      : currentShiftWidth;
     this.CorrectScrollArea(currentShiftWidth);
    }
    if(this.firstShownTabIndex == index && !visible) {
     var newShownTabIndex = this.GetNextVisibleTabIndex(index);
     if(newShownTabIndex < 0) {
      newShownTabIndex = this.GetPrevVisibleTabIndex(index);
      if(newShownTabIndex < 0) return;
     }
     this.ScrollToShowTab(newShownTabIndex, true);
    }
   }
   this.SetObservationPaused(false);
  },
  updateTabOrderCssMarkers: function() {
   var newTabsOrderInfo = this.getTabsOrderInfo();
   this.changeTabsOrderCssMarkers(this.tabsOrderInfo.leadTab, newTabsOrderInfo.leadTab, Constants.CssClassName.LEAD_TAB);
   this.changeTabsOrderCssMarkers(this.tabsOrderInfo.lastTab, newTabsOrderInfo.lastTab, Constants.CssClassName.LAST_TAB);
   if(this.IsMultiRow()) {
    for(var i = 0; i < this.tabsOrderInfo.lines.length; i++) {
     var oldLineInfo = this.tabsOrderInfo.lines[i];
     var newLineInfo = newTabsOrderInfo.lines[i];
     this.changeTabsOrderCssMarkers(oldLineInfo.startLineTab, newLineInfo.startLineTab, Constants.CssClassName.NEW_LINE_START_TAB);
     this.changeTabsOrderCssMarkers(oldLineInfo.endLineTab, newLineInfo.endLineTab, Constants.CssClassName.NEW_LINE_END_TAB);
    }
   }
   this.tabsOrderInfo = newTabsOrderInfo;
  },
  changeTabsOrderCssMarkers: function(oldTab, newTab, className) {
   if(oldTab !== newTab) {
    this.changeTabElementCssMarker(oldTab, className, false);
    this.changeTabElementCssMarker(newTab, className, true);
   }
  },
  changeTabElementCssMarker: function(tab, className, add) {
   if(!tab) return;
   var changeFunc = add ? this.addNewClassNameToElement : ASPx.RemoveClassNameFromElement;
   var tabElement = this.GetTabElement(tab.index, false);
   if(tabElement)
    changeFunc(tabElement, className);
   var activeTabElement = this.GetTabElement(tab.index, true);
   if(activeTabElement)
    changeFunc(activeTabElement, className);
  },
  addNewClassNameToElement: function(element, className) {
   element.className += " " + className;
  },
  getTabsOrderInfo: function() {
   var lines = this.getTabLines();
   var info = { lines: [] };
   for(var i = 0, line; line = lines[i]; i++) {
    var lineInfo = { };
    info.lines.push(lineInfo);
    for(var j = 0, tab; tab = line[j]; j++) {
     if(tab.GetVisible()) {
      if(i === 0)
       info.leadTab = tab;
      lineInfo.startLineTab = tab;
      break;
     }
    }
    for(var j = line.length - 1, tab; tab = line[j]; j--) {
     if(tab.GetVisible()) {
      if(i === lines.length - 1)
       info.lastTab = tab;
      lineInfo.endLineTab = tab;
      break;
     }
    }
   }
   return info;
  },
  getTabLines: function() {
   var line = [];
   var lines = [ line ];
   for(var i = 0, tab; tab = this.tabs[i]; i++) {
    if(tab.newLine) {
     line = [];
     lines.push(line);
    }
    line.push(tab);
   }
   return lines;
  },
  CorrectScrollArea: function (value) {
   var rtlCorrect = this.rtl ? -1 : 1;
   var newPostion = (this.scrollManager.GetScrolledAreaPosition() + value * rtlCorrect);
   this.scrollManager.SetScrolledAreaPosition((newPostion * rtlCorrect) <= 0 ? newPostion : 0);
  },
  SetSeparatorsVisiblility: function () {
   for(var i = 0; i < this.tabs.length; i++) {
    var separatorVisible = this.tabs[i].GetVisible() && this.GetNextVisibleTabIndex(i) > -1;
    var separatorElement = this.GetSeparatorElement(i);
    if(separatorElement != null)
     ASPx.SetElementDisplay(separatorElement, separatorVisible);
   }
  },
  GetNextVisibleTabIndex: function (index, allowHidden) {
   for(var i = index + 1; i < this.tabs.length; i++) {
    if(allowHidden && this.tabs[i].visible || this.tabs[i].GetVisible())
     return i;
   }
   return -1;
  },
  GetPrevVisibleTabIndex: function (index) {
   for(var i = index - 1; i >= 0; i--) {
    if(this.tabs[i].GetVisible())
     return i;
   }
   return -1;
  }
 });
 ASPxClientTabControlBase.TabChildElementIDRegExp = /^A?T\d+(T|Img)?$/;
 ASPxClientTabControlBase.IsTabChildElementID = function (id) {
  return ASPxClientTabControlBase.TabChildElementIDRegExp.test(id);
 };
 ASPxClientTabControlBase.PrepareStateController = function () {
  if(ASPxClientTabControlBase.IsStateControllerPrepared) return;
  ASPx.AddAfterSetHoverState(aspxTabStateChanged);
  ASPx.AddAfterClearHoverState(aspxTabStateChanged);
  ASPx.AddAfterSetPressedState(aspxTabStateChanged);
  ASPx.AddAfterClearPressedState(aspxTabStateChanged);
  ASPxClientTabControlBase.IsStateControllerPrepared = true;
 };
 var TabHeightManagerBase = ASPx.CreateClass(null, {
  constructor: function(tabControl) {
   this.tabControl = tabControl;
  },
  initialize: function() {
  },
  isMultiRow: function() {
   return this.tabControl.IsMultiRow();
  },
  correctTabHeightOnStateChanged: function(element) {
  },
  requestAdjustment: function() {
  },
  adjustTabs: function() {
  },
  needAdjustTabStrip: function() {
   return false;
  },
  getTabStripHeight: function() {
   return 0;
  }
 });
 var TabHeightManager = ASPx.CreateClass(TabHeightManagerBase, {
  constructor: function(tabControl) {
   this.constructor.prototype.constructor.call(this, tabControl);
   this.needCalculate = true;
   this.rowCount = 1;
   this.tabSpaceSize = 0;
   this.equalityError = 0.11;
  },
  initialize: function() {
   this.tabSpaceSize = this.tabControl.GetTabSpaceSizeLite();
   if(this.isMultiRow())
    this.rowCount = this.tabControl.getTabLines().length;
  },
  getTabStripElements: function() {
   return this.isMultiRow()
    ? this.getTabStripElementsMultirow()
    : this.getTabStripElementsCommon();
  },
  getTabStripElementsCommon: function() {
   var elements = ASPx.GetChildNodesByTagName(this.tabControl.GetTabStripContainer(), "LI");
   if(this.tabControl.enableScrolling) {
    var subElements = ASPx.GetChildNodesByTagName(this.tabControl.GetTabsCell(), "LI");
    elements.push.apply(elements, subElements);
   }
   return elements;
  },
  getTabStripElementsMultirow: function() {
   var elements = [];
   elements.push(this.tabControl.GetLeftIndentLite());
   elements.push(this.tabControl.GetRightIndentLite());
   var tabRows = this.tabControl.getTabRows();
   for(var i = 0, tabRow; tabRow = tabRows[i]; i++) {
    var subElements = ASPx.GetChildNodesByTagName(tabRow, "LI");
    elements.push.apply(elements, subElements);
   }
   return elements;
  },
  isSameValues: function(val1, val2) {
   if(!ASPx.IsExists(val1) || !ASPx.IsExists(val2))
    return false;
   return this.tabControl.areEqualValues(val1, val2, this.equalityError);
  },
  requestAdjustment: function() {
   this.needCalculate = true;
  },
  needAdjustTabStrip: function() {
   return true;
  },
  getTabStripHeight: function() {},
  adjustTabs: function() {
   this.needCalculate = this.tabControl.UseProportionalTabSizes() || this.needCalculate || !ASPx.documentLoaded;
   if(!this.needCalculate)
    return;
   var needAdjust = this.calculateTabs();
   if(needAdjust) {
    this.needCalculate = !this.tabControl.cacheEnabled;
    this.adjustTabStripElements();
   }
  },
  calculateTabs: function() {},
  adjustTabStripElements: function() {}
 });
 var TabCustomHeightManager = ASPx.CreateClass(TabHeightManager, {
  constructor: function(tabControl) {
   this.constructor.prototype.constructor.call(this, tabControl);
   this.rowHeightArray = null;
   this.updateInfo = null;
   this.margins = {};
  },
  initialize: function() {
   TabHeightManager.prototype.initialize.call(this);
   this.storeInitialTabMargins();
  },
  storeInitialTabMargins: function() {
   var elements = this.tabControl.GetTabsElements();
   var elementCount = elements.length;
   for(var i = 0; i < elementCount; i++) {
    var element = elements[i];
    var margin = ASPx.PxToFloat(ASPx.GetCurrentStyle(element)[this.getMarginStyleProperty()]);
    this.margins[element.id] = margin;
   }
  },
  setTabElementMargin: function(tabElement, margin) {
   var useImportant = !!this.getMarginById(tabElement.id);
   if(useImportant) {
    var styleProperty = 'margin-' + this.tabControl.tabPosition.toLowerCase();
    tabElement.style.cssText = this.createImportantAttribute(tabElement.style.cssText, styleProperty, margin + 'px');
   }
   else
    tabElement.style[this.getMarginStyleProperty()] = margin + 'px';
  },
  getMarginStyleProperty: function() {
   return this.tabControl.tabPosition === "Bottom" ? "marginBottom" : "marginTop";
  },
  createImportantAttribute: function(cssText, attribute, value) {
   var importantProperty = ' ' + attribute + ': ' + value + '!important';
   if(cssText.indexOf(attribute) == -1) {
    if(ASPx.Browser.IE && ASPx.Browser.MajorVersion < 9)
     cssText += '; ';
    cssText += importantProperty;
    return cssText;
   }
   var attributes = cssText.split(";"); 
   var attributesLength = attributes.length;
   for(var i = 0; i < attributesLength; i++){
    if(attributes[i].indexOf(attribute) != -1) {
     attributes[i] = importantProperty;
     break;
    }
   }
   cssText = attributes.join(";");
   return cssText;
  },
  adjustTabStripElements: function() {
   var elementCount = this.updateInfo.length;
   for(var i = 0; i < elementCount; i++) {
    var correction = this.updateInfo[i];
    if(ASPx.IsExists(correction.margin))
     this.setTabElementMargin(correction.element, correction.margin);
    else
     correction.element.style.height = correction.height + 'px';
   }
  },
  getMarginById: function(tabId) {
   var margin = this.margins[tabId];
   if(!margin)
    return 0;
   return margin;
  },
  updateHeightByTab: function(element, rowIndex, cache) {
   this.updateHeightByElement(element, rowIndex, cache);
  },
  updateHeightByIndent: function(element, cache) {
   var rowIndex = this.getActiveTabRowIndexCore(this.rowCount);
   this.updateHeightByElement(element, rowIndex, cache);
  },
  updateHeightByElement: function(element, rowIndex, cache) {
   var rowHeight = this.rowHeightArray[rowIndex];
   var totalElementHeight = cache.height + cache.verticalBordersAndPaddingsWidth + this.getMarginById(element.id);
   this.rowHeightArray[rowIndex] = this.tabControl.GetMaxValue(totalElementHeight, rowHeight);
  },
  updateRowHeightArray: function(stripInfo) {
   for(var i = 0; i < this.rowCount; i++) {
    var rowLength = stripInfo[i].length;
    var rowInfo = stripInfo[i];
    for(var j = 0; j < rowLength; j++) {
     var element = rowInfo[j].element;
     if(this.tabControl.isTemplateIndentElement(element)) {
      var oldHeight = element.style.height;
      element.style.height = '';
      var cache = this.tabControl.GetOrCreateElementCache(element);
      rowInfo[j].cache = cache;
      this.updateHeightByIndent(element, cache);
      element.style.height = oldHeight;
     }
     else {
      var cache = this.tabControl.GetOrCreateElementCache(element);
      rowInfo[j].cache = cache;
      if(this.tabControl.isTabElement(element) && cache.display)
       this.updateHeightByTab(element, i, cache);
     }
    }  
   }
  },
  calculateTabs: function() {
   var info = this.createStripElementInfo();
   this.resetRowHeightArray();
   this.updateRowHeightArray(info);
   this.updateInfo = this.calculateUpdateInfo(info);
   return !!this.updateInfo;
  },
  createStripElementInfo: function() {
   if(this.isMultiRow())
    return this.createStripElementInfoMultirow();
   var tabStripElements = this.getTabStripElements();
   var rowElementsInfo = [];
   var stripElementInfo = [rowElementsInfo];
   for(var i = 0, element; element = tabStripElements[i]; i++) {
    var elementInfo = this.createElementInfo(element);
    rowElementsInfo.push(elementInfo);
   }
   return stripElementInfo;
  },
  createStripElementInfoMultirow: function() {
   var stripElementInfo = [];
   var tabLines = this.tabControl.getTabLines();
   for(var rowIndex = 0, tabLine; tabLine = tabLines[rowIndex]; rowIndex++) {
    var rowElementsInfo = [];
    stripElementInfo.push(rowElementsInfo);
    for(var tabIndex = 0, tab; tab = tabLine[tabIndex]; tabIndex++) {
     if(tab.GetVisible()) {
      var element = this.tabControl.GetVisibleTabElement(tab.index);
      var elementInfo = this.createElementInfo(element);
      rowElementsInfo.push(elementInfo);
     }
    }
   }
   var leftIndent = this.tabControl.GetLeftIndentLite();
   stripElementInfo.leftIndent = this.createElementInfo(leftIndent);
   var rightIndent = this.tabControl.GetRightIndentLite();
   stripElementInfo.rightIndent = this.createElementInfo(rightIndent);
   return stripElementInfo;
  },
  createElementInfo: function(element) {
   return { element: element, cache: null };
  },
  getActualTabStripHeight: function() {
   var result = 0;
   for(var i = 0; i < this.rowCount; i++)
    result += this.rowHeightArray[i];
   if(this.isMultiRow())
    result += (this.rowCount - 1) * this.tabSpaceSize;
   return result;
  },
  resetRowHeightArray: function() {
   if(this.rowHeightArray !== null)
    for(var i = 0; i < this.rowCount; i++)
     this.rowHeightArray[i] = 0;
   else {
    this.rowHeightArray = [];
    for(var i = 0; i < this.rowCount; i++)
     this.rowHeightArray.push(0);
   }
  },
  calculateUpdateInfo: function(stripInfo) {
   var updateInfo = [];
   for(var i = 0; i < this.rowCount; i++) {
    var rowHeight = this.rowHeightArray[i];
    var rowInfo = stripInfo[i];
    var rowLength = rowInfo.length;
    for(var j = 0; j < rowLength; j++)
     this.calcUpdateInfoForStripItem(updateInfo, rowInfo[j], rowHeight);
   }
   if(this.isMultiRow())
    this.calcUpdateInfoForIndents(updateInfo, stripInfo);
   return updateInfo.length > 0 ? updateInfo : null;
  },
  calcUpdateInfoForIndents: function(updateInfo, stripInfo) {
   var expectedHeignt = this.getActualTabStripHeight();
   this.calcUpdateInfoForStripItem(updateInfo, stripInfo.leftIndent, expectedHeignt);
   this.calcUpdateInfoForStripItem(updateInfo, stripInfo.rightIndent, expectedHeignt);
  },
  calcUpdateInfoForStripItem: function(updateInfo, stripItem, expectedHeight) {
   var element = stripItem.element,
    cache = stripItem.cache;
   var height = cache.height + cache.verticalBordersAndPaddingsWidth;
   if(!this.isSameValues(cache.outerHeight, expectedHeight)) {
    var updateItem = { element: element };
    if(this.tabControl.isTabElement(element))
     updateItem.margin = expectedHeight - height;
    else
     updateItem.height = expectedHeight - cache.verticalBordersAndPaddingsWidth;
    updateInfo.push(updateItem);
   }
  },
  correctTabHeightOnStateChanged: function(element) {
   var tabElement = ASPx.GetParentByTagName(element, "LI");
   this.adjustTabs();
   this.tabControl.AdjustTabStripHeight();
  },
  getTabStripHeight: function() {
   return this.getActualTabStripHeight();
  }
 });
 var TabDefaultHeightManager = ASPx.CreateClass(TabHeightManager, {
  constructor: function(tabControl) { 
   this.constructor.prototype.constructor.call(this, tabControl);
   this.lastValue = 0;
  },
  calculateTabs: function() {
   var height = this.getTabStripElementHeight();
   var lastTabHeight = this.lastValue;
   if(lastTabHeight && this.isSameValues(height, lastTabHeight))
    return false;
   this.lastValue = height;
   return true;
  },
  adjustTabStripElements: function() {
   var itemHeight = this.lastValue;
   var indentHeight = this.getTabStripHeight();
   var elements = this.getTabStripElements();
   for(var i = 0, element; element = elements[i]; i++) { 
    var useIndentHeight = this.isMultiRow() && 
     (ASPx.ElementHasCssClass(element, Constants.CssClassName.LEFT_INDENT) || 
     ASPx.ElementHasCssClass(element, Constants.CssClassName.RIGHT_INDENT));
    var height = useIndentHeight ? indentHeight : itemHeight;
    this.tabControl.SetCachedElementHeight(element, height);
   }
  },
  correctTabHeightOnStateChanged: function(element) {
   var tabElement = ASPx.GetParentByTagName(element, "LI");
   var height = this.lastValue;
   height -= this.tabControl.GetCachedVerticalBordersPaddingsMarginsWidth(tabElement);
   tabElement.style.height = height + "px";
  },
  getTabStripElementHeight: function () {
   var result = 0;
   var elements = this.getElementsForCalculation();
   var elementsLength = elements.length;
   for(var i = 0; i < elementsLength; i++) {
    var element = elements[i];
    var oldHeight = "";
    if(element.style.height) {
     oldHeight = element.style.height;
     element.style.height = "";
     if(this.isLayoutResetRequired())
      element.style.position = "relative";
    }
    var height = this.tabControl.GetCachedElementSize(element, "height");
    if(height > result)
     result = height;
    if(oldHeight) {
     element.style.height = oldHeight;
     if(this.isLayoutResetRequired())
      element.style.position = "";
    }
   }
   return result;
  },
  isLayoutResetRequired: function() {
   return ASPx.Browser.Firefox && ASPx.Browser.MajorVersion >= 41 && ASPx.Browser.MajorVersion < 43;
  },
  getElementsForCalculation: function() {
   var elements = this.getTabElements();
   if(!this.isMultiRow()) {
    var templateElements = this.getTemplateIndentElements();
    if(templateElements.length > 0)
     elements.push.apply(elements, templateElements);
   }
   return elements;
  },
  getTabElements: function() {
   var elements = [];
   var tabsLength = this.tabControl.tabs.length;
   for(var i = 0; i < tabsLength; i++) {
    if(this.tabControl.IsTabVisible(i)) {
     var element = this.tabControl.GetVisibleTabElement(i);
     if(element)
      elements.push(element);
    }
   }
   return elements;
  },
  getTemplateIndentElements: function() {
   var elements = [];
   var stripContainer = this.tabControl.GetTabStripContainer();
   var templateElements = ASPx.GetNodesByClassName(stripContainer, Constants.CssClassName.INDENT_TEMPLATE);
   var templateElementsLength = templateElements.length;
   for(var i = 0; i < templateElementsLength; i++) {
    var element = templateElements[i];
    if(element)
     elements.push(templateElements[i]);
   }
   return elements;
  },
  getTabStripHeight: function() {
   var result = this.lastValue * this.rowCount;
   if(this.isMultiRow())
    result += (this.rowCount - 1) * this.tabSpaceSize;
   return result;
  }
 });
 var FakeTabHeightManager = ASPx.CreateClass(TabHeightManager, {
  constructor: function() { 
   this.constructor.prototype.constructor.call(this);
  },
  initialize: function() {},
  adjustLineBreaks: function() {},
  adjustTabs: function() {},
  adjustTabStripElements: function() {},
  calculateTabs: function() {},
  correctTabHeightOnStateChanged: function() {},
  getTabStripElements: function() {},
  getTabStripHeight: function() {},
  isSameValues: function() {},
  needAdjustTabStrip: function() { return false; },
  requestAdjustment: function() {}
 });
 var FlexTabHeightManager = ASPx.CreateClass(TabHeightManagerBase, {
  constructor: function(tabControl) {
   this.constructor.prototype.constructor.call(this, tabControl);
  },
  correctTabHeightOnStateChanged: function(element) {
   this.adjustTabs();
  },
  adjustTabs: function() {
   var elements = this.getTabStripElements();
   var actualElements = [];
   for(var i = 0, element; element = elements[i]; i++) {
    if(element.style.display == "none")
     continue;
    actualElements.push(element);
    element.style.height = "";
    ASPx.RemoveClassNameFromElement(element, Constants.CssClassName.PINNED_STRIP_ITEM);
   }
   var heightArray = [];
   for(var i = 0, element; element = actualElements[i]; i++) {
    var height = this.tabControl.GetCachedElementInnerSize(element, "height");
    height = this.tabControl.GetPreparedSizeValue(height);
    heightArray.push(height);
   }
   for(var i = 0, element; element = actualElements[i]; i++) {
    var height = heightArray[i];
    element.style.height = height + "px";
    element.className += " " + Constants.CssClassName.PINNED_STRIP_ITEM;
   }
  },
  getTabStripElements: function() {
   var stripContainer = this.tabControl.GetTabStripContainer();
   return ASPx.GetNodes(stripContainer, function(el) { 
    return el.className &&
     (this.tabControl.isTabElement(el) ||
     this.tabControl.isTemplateIndentElement(el));
   }.aspxBind(this));
  }
 });
 var ASPxClientTabControl = ASPx.CreateClass(ASPxClientTabControlBase, {
  SetHeight: function (height) { }
 });
 ASPxClientTabControl.Cast = ASPxClientControl.Cast;
 var ASPxClientPageControl = ASPx.CreateClass(ASPxClientTabControlBase, {
  constructor: function (name) {
   this.constructor.prototype.constructor.call(this, name);
   this.handleClickOnWholeTab = false;
   this.sizingConfig.supportPercentHeight = true;
   this.sizingConfig.supportAutoHeight = true;
   getPageControlCollection().Add(this);
  },
  GetTabContentHTML: function (tab) {
   var element = this.GetContentHolder(tab.index);
   return (element != null) ? element.innerHTML : "";
  },
  SetTabContentHTML: function (tab, html, useAnimation) {
   var element = this.GetContentElement(tab.index);
   if(element != null) {
    ASPx.SetInnerHtml(this.GetContentHolder(tab.index), html);
    this.adjustControlInternal();
    if(useAnimation && typeof (ASPx.AnimationHelper) != "undefined")
     ASPx.AnimationHelper.fadeIn(element, function () { }.aspxBind(this));
   }
  },
  PerformCallback: function (parameter, onSuccess) {
   var index = this.GetActiveTabIndex();
   var element = this.GetContentElement(index);
   if(element != null) {
    var arg = index + "|" + parameter;
    this.PerformCallbackInternal(index, element, arg, onSuccess);
   }
  },
  onDocumentMouseDown: function(evt) {
   this.enableCollapsingExtended(evt);
  },
  onDocumentMouseUp: function(evt) {
   this.enableCollapsingExtended(evt);
  },
  onDocumentMouseMove: function(evt) {
   if(ASPx.Evt.IsLeftButtonPressed(evt))
    this.enableCollapsingExtended(evt);
  },
  onDocumentMouseClick: function(evt) {
   this.enableCollapsingExtended(evt);
  },
  onDocumentKeyDown: function(evt) {
   this.enableCollapsing(evt);
  },
  onDocumentKeyUp: function(evt) {
   this.enableCollapsing(evt);
  },
  onDocumentKeyPress: function(evt) {
   this.enableCollapsing(evt);
  },
  enableCollapsingExtended: function(evt) {
   var srcElement = ASPx.Evt.GetEventSource();
   var useShortTime = srcElement && ((src.tagName == "input" && (src.type == "text" || src.type == "password")) || scr.tagName == "textarea");
   this.enableCollapsing(evt, useShortTime);
  },
  enableCollapsing: function(evt, useShortTime) {
   this.contentObserving.collapsingEnabled = true;
   if(this.contentObserving.collapsingTimerID !== -1)
    window.clearTimeout(this.contentObserving.collapsingTimerID);
   var timeout = useShortTime ? this.contentObserving.collapsingShortTimeout : this.contentObserving.collapsingTimeout;
   this.contentObserving.collapsingTimerID = window.setTimeout(this.disableCollapsing.aspxBind(this), this.contentObserving.collapsingTimeout);
  },
  disableCollapsing: function() {
   this.contentObserving.collapsingTimerID = -1;
   this.contentObserving.collapsingEnabled = false;
  }
 });
 ASPxClientPageControl.Cast = ASPxClientControl.Cast;
 var ASPxClientTab = ASPx.CreateClass(null, {
  constructor: function (tabControl, index, name) {
   this.tabControl = tabControl;
   this.index = index;
   this.name = name;
   this.enabled = true;
   this.clientEnabled = true;
   this.visible = true;
   this.clientVisible = true;
   this.newLine = false;
  },
  GetEnabled: function () {
   return this.enabled && this.clientEnabled;
  },
  SetEnabled: function (value, doNotChangeActiveTab) {
   if(this.clientEnabled != value) {
    this.clientEnabled = value;
    this.tabControl.SetTabEnabled(this.index, value, false, doNotChangeActiveTab);
   }
  },
  GetImageUrl: function (active) {
   return this.tabControl.GetTabImageUrl(this.index, active);
  },
  SetImageUrl: function (value, active) {
   this.tabControl.SetTabImageUrl(this.index, active, value);
  },
  GetActiveImageUrl: function () {
   return this.tabControl.GetTabImageUrl(this.index, true);
  },
  SetActiveImageUrl: function (value) {
   this.tabControl.SetTabImageUrl(this.index, true, value);
  },
  GetNavigateUrl: function () {
   return this.tabControl.GetTabNavigateUrl(this.index);
  },
  SetNavigateUrl: function (value) {
   this.tabControl.SetTabNavigateUrl(this.index, value);
  },
  GetText: function () {
   return this.tabControl.GetTabText(this.index);
  },
  SetText: function (value) {
   this.tabControl.SetTabText(this.index, value);
  },
  GetVisible: function () {
   return this.visible && this.clientVisible;
  },
  SetVisible: function (value) {
   if(this.clientVisible != value) {
    this.tabControl.SetTabVisible(this.index, value, false);
   }
  }
 });
 var ASPxClientTabControlTabEventArgs = ASPx.CreateClass(ASPxClientEventArgs, {
  constructor: function (tab, htmlElement, htmlEvent) {
   this.constructor.prototype.constructor.call(this);
   this.tab = tab;
  }
 });
 var ASPxClientTabControlTabCancelEventArgs = ASPx.CreateClass(ASPxClientProcessingModeCancelEventArgs, {
  constructor: function (processOnServer, tab) {
   this.constructor.prototype.constructor.call(this, processOnServer);
   this.tab = tab;
   this.reloadContentOnCallback = false;
  }
 });
 var ASPxClientTabControlTabClickEventArgs = ASPx.CreateClass(ASPxClientTabControlTabCancelEventArgs, {
  constructor: function (processOnServer, tab, htmlElement, htmlEvent) {
   this.constructor.prototype.constructor.call(this, processOnServer, tab);
   this.htmlElement = htmlElement;
   this.htmlEvent = htmlEvent;
  }
 });
 ASPx.TCTClick = function(evt, name, index) {
  var tc = ASPx.GetControlCollection().Get(name);
  if(tc != null) tc.OnTabClick(evt, index);
  if(!ASPx.Browser.NetscapeFamily)
   evt.cancelBubble = true;
 }
 function aspxTabStateChanged(source, args) {
  var postfixIndex = args.item.name.lastIndexOf("_");
  var postfix = args.item.name.substring(postfixIndex + 1);
  if(!ASPxClientTabControlBase.IsTabChildElementID(postfix))
   return;
  var tcName = args.item.name.substring(0, postfixIndex);
  var tc = ASPx.GetControlCollection().Get(tcName);
  if(tc && tc.CorrectTabHeightOnStateChanged)
   tc.CorrectTabHeightOnStateChanged(args.element);
 }
 var TabControlScrollingManager = ASPx.CreateClass(ASPx.ScrollingManager, {
  setParentNodeOverflow: function() { }
 });
 var PageControlCollection = ASPx.CreateClass(ASPxClientControlCollection, {
  constructor: function() {
   this.constructor.prototype.constructor.call(this);
   this.initEvents();
  },
  GetCollectionType: function(){
   return "PageControl";
  },
  initEvents: function() {
   if(!(ASPx.Browser.IE && ASPx.Browser.MajorVersion == 10 && !ASPx.Browser.TouchUI)) return;
   ASPx.Evt.AttachEventToDocument("mousedown", this.onMouseDown.aspxBind(this));
   ASPx.Evt.AttachEventToDocument("mouseup", this.onMouseUp.aspxBind(this));
   ASPx.Evt.AttachEventToDocument("mousemove", this.onMouseMove.aspxBind(this));
   ASPx.Evt.AttachEventToDocument("mouseclick", this.onMouseClick.aspxBind(this));
   ASPx.Evt.AttachEventToDocument("keydown", this.onKeyDown.aspxBind(this));
   ASPx.Evt.AttachEventToDocument("keyup",  this.onKeyUp.aspxBind(this));
   ASPx.Evt.AttachEventToDocument("keypress", this.onKeyPress.aspxBind(this));
  },
  raiseEventHandler: function(handlerName, evt) {
   this.ForEachControl(function(control) {
    if(control.IsDOMInitialized())
     control[handlerName](evt);
   });
  },
  onMouseDown: function(evt) {
   this.raiseEventHandler("onDocumentMouseDown", evt);
  },
  onMouseUp: function(evt) {
   this.raiseEventHandler("onDocumentMouseUp", evt);
  },
  onMouseMove: function(evt) {
   this.raiseEventHandler("onDocumentMouseMove", evt);
  },
  onMouseClick: function(evt) {
   this.raiseEventHandler("onDocumentMouseClick", evt);
  },
  onKeyDown: function(evt) {
   this.raiseEventHandler("onDocumentKeyDown", evt);
  },
  onKeyUp: function(evt) {
   this.raiseEventHandler("onDocumentKeyUp", evt);
  },
  onKeyPress: function(evt) {
   this.raiseEventHandler("onDocumentKeyPress", evt);
  }
 });
 var pageControlCollection = null;
 function getPageControlCollection() {
  if(pageControlCollection == null)
   pageControlCollection  = new PageControlCollection();
  return pageControlCollection;
 }
 var LayoutManagerBase = ASPx.CreateClass(null, {
  constructor: function(tabControl) {
   this.tabControl = tabControl;
  },
  isContentObservingEnabled: function() {
   return false;
  },
  isCollapsingInObservingEnabled: function() {
   return false;
  },
  isContentAdjustmentRequired: function() {
   return false;
  },
  isContentCollapsingRequired: function() {
   return false;
  },
  isAdjustmenRequiredByNewSizes: function(sizes, newSizes, error) {
   return false;
  },
  needCollapseControl: function() {
   return false;
  },
  areEqualValues: function(val1, val2, error) {
   return this.tabControl.areEqualValues(val1, val2, error);
  },
  enableContentObservation: function() {
  },
  calculateSizes: function() {
  },
  adjustSize: function() {
  },
  collapseTabStrip: function() {
  },
  adjustSizeOnContentModification: function() {
  },
  expandTabStrip: function() {
  },
  getScrollableAreaWidth: function() {
   return 0;
  },
  updateTabStripImagesSizes: function() {
  },
  prepareTabStripForImageLoading: function() {
  },
  adjustScrollVisibleAreaWidth: function() {
  },
  createTabHeightManager: function() {
   return null;
  },
  inlineInitialize: function() {
  }
 });
 var FixedLayoutManager = ASPx.CreateClass(LayoutManagerBase, {
  constructor: function(tabControl) {
   this.constructor.prototype.constructor.call(this, tabControl);
  },
  isContentObservingEnabled: function() {
   return true;
  },
  isCollapsingInObservingEnabled: function() {
   return !ASPx.Browser.IE || ASPx.Browser.MajorVersion != 8 || ASPx.Browser.MajorVersion != 10;
  },
  isContentAdjustmentRequired: function() {
   return !!this.tabControl.GetMainElement().style.height;
  },
  isContentCollapsingRequired: function() {
   return this.isContentAdjustmentRequired();
  },
  isAdjustmenRequiredByNewSizes: function(sizes, newSizes, error) {
   var control = this.tabControl;
   var checkOnlyPrimarySize = control.emptyHeight && control.contentObserving.collapsingEnabled;
   return checkOnlyPrimarySize
    ? !this.areEqualValues(sizes[control.primaryDimension], newSizes[control.primaryDimension], error)
    : !(this.areEqualValues(sizes.width, newSizes.width, error) && this.areEqualValues(sizes.height, newSizes.height, error));
  },
  needCollapseControl: function() {
   return true;
  },
  enableContentObservation: function() {
   this.tabControl.adjustedSizes = this.tabControl.GetAdjustedSizes();
  },
  calculateSizes: function() {
   this.tabControl.calculateSizesCore();
  },
  adjustSizeOnContentModification: function() {
   var control = this.tabControl;
   control.DoSafeScrollPositionOperation(function() {
    control.adjustControlInternal();
   });
  },
  adjustSize: function() {
   this.tabControl.adjustTabControlSizeCore();
  },
  collapseTabStrip: function() {
   this.tabControl.collapseTabStrip();
  },
  expandTabStrip: function() {
   this.tabControl.expandTabStrip();
  },
  getScrollableAreaWidth: function() {
   return this.tabControl.getScrollableAreaWidthCore();
  },
  updateTabStripImagesSizes: function() {
   this.tabControl.UpdateTabStripImagesSizes();
  },
  prepareTabStripForImageLoading: function() {
   this.tabControl.PrepareTabStripForImageLoading();
  },
  adjustScrollVisibleAreaWidth: function() {
   this.tabControl.AdjustScrollVisibleAreaWidth();
  },
  createTabHeightManager: function() {
   return this.tabControl.createTabHeightManagerCore();
  },
  inlineInitialize: function() {
   this.tabControl.initFixedLayoutInline();
  }
 });
 var FlexLayoutManager = ASPx.CreateClass(LayoutManagerBase, {
  constructor: function(tabControl) {
   this.constructor.prototype.constructor.call(this, tabControl);
   this.tabHeightManager = null;
  },
  inlineInitialize: function() {
   var control = this.tabControl;
   if(!control.hasContent || control.IsTopBottomTabPosition() || control.heightValueSetInPercentage)
    return;
   var contentContainer = control.GetContentsCell();
   ASPx.AddClassNameToElement(contentContainer, Constants.CssClassName.AUTO_HEIGHT);
  },
  isContentObservingEnabled: function() {
   return this.isTabScrollingEnabled() || this.isCollapsingInObservingEnabled();
  },
  isCollapsingInObservingEnabled: function() {
   return this.needCollapseControl();
  },
  isContentAdjustmentRequired: function() {
   return this.needAdjustContentHeight();
  },
  isContentCollapsingRequired: function() {
   return this.needCollapseContent();
  },
  isAdjustmenRequiredByNewSizes: function(sizes, newSizes, error) {
   if(this.needRefreshTabStrip())
    return false;
   var dimension = this.isTabScrollingEnabled() ? "width" : "height";
   return !this.areEqualValues(sizes[dimension], newSizes[dimension], error);
  },
  needAdjustContentHeight: function() {
   var control = this.tabControl;
   return control.IsTopBottomTabPosition()
    ? !control.emptyHeight
    : !(control.emptyHeight || control.heightValueSetInPercentage);
  },
  needCollapseContent: function() {
   return this.tabControl.IsTopBottomTabPosition() && this.tabControl.heightValueSetInPercentage;
  },
  needRefreshTabStrip: function() {
   var control = this.tabControl;
   return (ASPx.Browser.IE || ASPx.Browser.Edge) && control.hasTabStip && !control.IsTopBottomTabPosition();
  },
  needCollapseControl: function() {
   return this.needCollapseContent() || this.needRefreshTabStrip();
  },
  isTabScrollingEnabled: function() {
   return this.tabControl.enableScrolling;
  },
  calculateSizes: function() {
   var tabControl = this.tabControl;
   tabControl.updateContentAdjustmentFlags();
   this.tabHeightManager.adjustTabs();
   if(!tabControl.isControlCollapsed)
    tabControl.CollapseControl();
   tabControl.isControlCollapsed = false;
   var stripSizes = { primary: 0, secondary: 0 },
    controlSizes = { };
   var stripContainer = this.tabControl.GetTabStripContainer();
   if(tabControl.IsTopBottomTabPosition() && !tabControl.emptyHeight)
    stripSizes.secondary = tabControl.GetCachedElementInnerSize(stripContainer, "height");
   tabControl.calculateMainElementSizes();
   controlSizes.primary = tabControl.adjustmentVars.mainElementSizes.primary;
   controlSizes.secondary = tabControl.adjustmentVars.mainElementSizes.secondary;
   tabControl.adjustmentVars.stripSizes = stripSizes;
   tabControl.adjustmentVars.controlSizes = controlSizes;
   tabControl.CalculateContentHeight();
   this.expandTabStrip();
  },
  adjustSize: function() {
   this.calculateSizes();
   this.tabControl.AdjustPageContents();
  },
  adjustSizeOnContentModification: function() {
   var control = this.tabControl;
   if(this.needCollapseContent())
    control.adjustControlInternal();
   else
    control.adjustTabStripScrolling(true);
  },
  collapseTabStrip: function() {
   if(this.needRefreshTabStrip()) {
    var stripContainer = this.tabControl.GetTabStripContainer();
    stripContainer.style.height = "auto";
   }
  },
  expandTabStrip: function() {
   if(this.needRefreshTabStrip()) {
    var stripContainer = this.tabControl.GetTabStripContainer();
    stripContainer.style.height = "";
   }
  },
  getScrollableAreaWidth: function() {
   var scrollableArea = this.tabControl.GetScrollableArea();
   var items = ASPx.GetChildElementNodes(scrollableArea);
   var width = 0;
   for(var i = 0, item; item = items[i]; i++) {
    if(item.className.indexOf(Constants.CssClassName.TAB_FILLER) == -1)
     width += this.tabControl.GetCachedElementSize(item);
   }
   return width;
  },
  createTabHeightManager: function() {
   var strip = this.tabControl.GetTabsCell();
   var useManager = this.tabControl.IsTopBottomTabPosition() && strip && strip.className.indexOf(Constants.CssClassName.PINNED_TAB_HEADERS) == -1;
   this.tabHeightManager = useManager ? new FlexTabHeightManager(this.tabControl) : new FakeTabHeightManager();
   return this.tabHeightManager;
  }
 });
 ASPx.GetPageControlCollection = getPageControlCollection;
 window.ASPxClientTabControlBase = ASPxClientTabControlBase;
 window.ASPxClientPageControl = ASPxClientPageControl;
 window.ASPxClientTabControl = ASPxClientTabControl;
 window.ASPxClientTab = ASPxClientTab;
 window.ASPxClientTabControlTabClickEventArgs = ASPxClientTabControlTabClickEventArgs;
 window.ASPxClientTabControlTabCancelEventArgs = ASPxClientTabControlTabCancelEventArgs;
 window.ASPxClientTabControlTabEventArgs = ASPxClientTabControlTabEventArgs;
})();
