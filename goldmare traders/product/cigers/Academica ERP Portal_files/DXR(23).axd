(function(){
 ScrollingManager = ASPx.CreateClass(null, {
  constructor: function(owner, scrollableArea, orientation, onBeforeScrolling, onAfterScrolling, forseEmulation) {
   this.owner = owner;
   this.scrollableArea = scrollableArea;
   this.orientation = orientation;
   this.animationDelay = 1;
   this.animationStep = 2;
   this.animationOffset = 5;
   this.animationAcceleration = 0;
   this.scrollSessionInterval = 10;
   this.stopScrolling = true;
   this.busy = false;
   this.currentAcceleration = 0;
   this.startPos;
   this.onBeforeScrolling = onBeforeScrolling;
   this.onAfterScrolling = onAfterScrolling;
   this.emulationMode = forseEmulation === true || !ASPx.Browser.TouchUI; 
   this.Initialize();
  },
  Initialize: function(){
   this.setParentNodeOverflow();
   if(this.emulationMode){
    this.wrapper = new ScrollingManager.scrollWrapper(this.scrollableArea);
   } else {
    this.wrapper = new ScrollingManager.scrollWrapperTouchUI(this.scrollableArea, function(direction){
     if(this.onAfterScrolling)
      this.onAfterScrolling(this, direction);
    }.aspxBind(this)); 
   }
  },
  setParentNodeOverflow: function() {
   if(ASPx.Browser.MSTouchUI){
    this.scrollableArea.parentNode.style.overflow = "auto";
    this.scrollableArea.parentNode.style["-ms-overflow-style"] = "-ms-autohiding-scrollbar";
   } 
  },
  GetScrolledAreaPosition: function() {
   return this.wrapper.GetScrollLeft() * this.orientation[0]
    + this.wrapper.GetScrollTop() * this.orientation[1];
  },
  SetScrolledAreaPosition: function(pos) {
   this.wrapper.SetScrollLeft(pos * this.orientation[0]);
   this.wrapper.SetScrollTop(pos * this.orientation[1]);
  },
  PrepareForScrollAnimation: function() {
   if(!this.scrollableArea)
    return;  
   this.currentAcceleration = 0;
   this.startPos = this.GetScrolledAreaPosition();
   this.busy = false;
  },
  GetAnimationStep: function(dir) {
   var step = dir * (this.animationStep + this.currentAcceleration);
   var newPos = this.GetScrolledAreaPosition() + step;
   var requiredPos = this.startPos + dir * this.animationOffset;
   if((dir == 1 && newPos >= requiredPos) || (dir == -1 && newPos <= requiredPos)) {
    step = requiredPos - this.GetScrolledAreaPosition();
   } 
   return step;
  },
  DoScrollSessionAnimation: function(direction) {
   if(!this.scrollableArea)
    return;
   this.SetScrolledAreaPosition(this.GetScrolledAreaPosition() + this.GetAnimationStep(direction));
   var self = this;
   if(!this.ShouldStopScrollSessionAnimation()) {
    this.busy = true;
    this.currentAcceleration += this.animationAcceleration;
    window.setTimeout(function() { self.DoScrollSessionAnimation(direction); }, this.animationDelay);
   } else {
    if(this.onAfterScrolling)
     this.onAfterScrolling(this, -direction);   
    this.busy = false;
    this.currentAcceleration = 0;
    window.setTimeout(function() { self.DoScroll(direction); }, this.scrollSessionInterval);
   }
  },
  ShouldStopScrollSessionAnimation: function() {
   return (Math.abs(this.GetScrolledAreaPosition() - this.startPos) >= Math.abs(this.animationOffset));
  },
  DoScroll: function(direction) {
   if(!this.scrollableArea)
    return; 
   if(!this.busy && !this.stopScrolling) {
    if(this.onBeforeScrolling)
     this.onBeforeScrolling(this, -direction);
    if(this.stopScrolling) return;
    this.PrepareForScrollAnimation();
    this.DoScrollSessionAnimation(direction);
   } 
  },
  StartScrolling: function(direction, delay, step) {
   this.stopScrolling = false;
   this.animationDelay = delay;
   this.animationStep = step;
   this.DoScroll(-direction);
  },
  StopScrolling: function() {
   this.stopScrolling = true;
  },
  IsStopped: function() {
   return this.stopScrolling;
  }
 });
 ScrollingManager.scrollWrapper = function(scrollableArea){
  this.scrollableArea = scrollableArea;
  this.Initialize();
 };
 ScrollingManager.scrollWrapper.prototype = {
  Initialize: function(){
   this.scrollableArea.style.position = "relative";
   this.scrollableArea.parentNode.style.position = "relative";
  },
  GetScrollLeft: function(){ return ASPx.PxToFloat(this.scrollableArea.style.left); },
  GetScrollTop:  function(){ return ASPx.PxToFloat(this.scrollableArea.style.top); },
  SetScrollLeft: function(value){ this.scrollableArea.style.left = value + "px"; },
  SetScrollTop:  function(value){ this.scrollableArea.style.top  = value + "px"; }
 };
 ScrollingManager.scrollWrapperTouchUI = function(scrollableArea, onScroll){
  this.scrollableArea = scrollableArea;
  this.scrollTimerId = -1;
  this.onScroll = onScroll;
  this.Initialize(onScroll);
 };
 ScrollingManager.scrollWrapperTouchUI.prototype = {
  Initialize: function(){
   var div = this.scrollableArea.parentNode;
   var timeout = ASPx.Browser.MSTouchUI ? 500 : 1000;
   var nativeScrollSupported = ASPx.TouchUIHelper.nativeScrollingSupported();
   this.onScrollCore = function(){
     ASPx.Timer.ClearTimer(this.scrollTimerId);
     if(this.onScrollLocked) return;
     this.scrollTimerId = window.setTimeout(this.onScrollByTimer, timeout);
    }.aspxBind(this);
   this.onScrollByTimer = function(){
     if(this.onScrollLocked) return;
     var direction = this.lastScrollTop < div.scrollTop ? 1 : -1;
     this.lastScrollTop = div.scrollTop;
     this.onScrollLocked = true;
     this.onScroll(direction);
     this.onScrollLocked = false;
    }.aspxBind(this);
   this.lastScrollTop = div.scrollTop;
   var onscroll = nativeScrollSupported ? this.onScrollCore : this.onScrollByTimer;
   ASPx.Evt.AttachEventToElement(div, "scroll", onscroll);
   if(ASPx.Browser.WebKitTouchUI)
    this.scrollExtender = ASPx.TouchUIHelper.MakeScrollable(div, {showHorizontalScrollbar: false});
  },
  GetScrollLeft: function(){ return -this.scrollableArea.parentNode.scrollLeft; },
  GetScrollTop:  function(){ return -this.scrollableArea.parentNode.scrollTop; },
  SetScrollLeft: function(value){ 
   this.onScrollLocked = true;
   this.scrollableArea.parentNode.scrollLeft = -value; 
   this.onScrollLocked = false;
  },
  SetScrollTop:  function(value){ 
   this.onScrollLocked = true;
   this.scrollableArea.parentNode.scrollTop  = -value; 
   this.onScrollLocked = false;
  }
 };
 ASPx.ScrollingManager = ScrollingManager;
})();
