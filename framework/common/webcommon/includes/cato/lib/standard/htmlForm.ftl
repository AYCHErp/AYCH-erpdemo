<#--
* 
* Form and field HTML template include, standard Cato markup
*
* Included by htmlTemplate.ftl.
*
* NOTES: 
* * May have implicit dependencies on other parts of Cato API.
*
-->

<#include "htmlFormFieldWidget.ftl">

<#-- 
*************
* Form
************
Defines a form. Analogous to <form> HTML element.

  * Usage Examples *  
    <@form name="myform">
      <@fields>
        <input type="hidden" ... />
        <@field ... />
        <@field ... />
      </@fields>
    </@form>            
                    
  * Parameters *
    type                    = (input|display, default: input) Form type
                              DEV NOTE: "display" is special for time being, probably rare or unused;
                                  maybe it should cause to omit <form> element
    class                   = ((css-class)) CSS classes on form element itself
                              Supports prefixes (see #compileClassArg for more info):
                              * {{{+}}}: causes the classes to append only, never replace defaults (same logic as empty string "")
                              * {{{=}}}: causes the classes to replace non-essential defaults (same as specifying a class name directly)  
    attribs                 = ((map)) Extra attributes for HTML <form> element 
                              Needed for names containing dashes.
    inlineAttribs...        = ((inline-args)) Extra attributes for HTML <form> element
                              NOTE: camelCase names are automatically converted to dash-separated-lowercase-names.
-->
<#assign form_defaultArgs = {
  "type":"input", "name":"", "id":"", "class":"", "open":true, "close":true, 
  "attribs":{}, "passArgs":{}
}>
<#macro form args={} inlineArgs...>
  <#local args = mergeArgMaps(args, inlineArgs, catoStdTmplLib.form_defaultArgs)>
  <#local dummy = localsPutAll(args)>
  <#local attribs = makeAttribMapFromArgMap(args)>
  <#local origArgs = args>

  <#if open>
    <#local formInfo = {"type":type, "name":name, "id":id}>
    <#local dummy = pushRequestStack("catoFormInfoStack", formInfo)>
  </#if>

  <#if open && !close>
    <#local dummy = pushRequestStack("catoFormMarkupStack", {
      "type":type, "name":name, "id":id, "class":class, "attribs":attribs, "origArgs":origArgs, "passArgs":passArgs
    })>
  <#elseif close && !open>
    <#local stackValues = popRequestStack("catoFormMarkupStack")!{}>
    <#local dummy = localsPutAll(stackValues)>
  </#if>
  <@form_markup type=type name=name id=id class=class open=open close=close attribs=attribs origArgs=origArgs passArgs=passArgs><#nested></@form_markup>
  <#if close>
    <#local dummy = popRequestStack("catoFormInfoStack")>
  </#if>
</#macro>

<#-- @form main markup - theme override -->
<#macro form_markup type="" name="" id="" class="" open=true close=true attribs={} origArgs={} passArgs={} catchArgs...>
  <#if open>
    <form<@compiledClassAttribStr class=class /><#if id?has_content> id="${id}"</#if><#rt>
      <#lt><#if name?has_content> name="${name}"</#if><#if attribs?has_content><@commonElemAttribStr attribs=attribs /></#if>>
  </#if>
      <#nested>
  <#if close>
    </form>
  </#if>
</#macro>

<#-- 
*************
* Progress Script
************
Generates script data and markup needed to make an instance to initialize upload progress 
javascript anim for a form, with progress bar and/or text.

The server-side upload event for the form must register a Java FileUploadProgressListener in session
for getFileUploadProgressStatus controller AJAX calls.
                    
  * Parameters *
    enabled                 = ((boolean), default: true) If true, disables whole macro
                              Occasionally needed in templates as FTL workaround.
    progressOptions         = ((map)) Elem IDs and options passed to CatoUploadProgress Javascript class
                              In addition, supports: 
                              * {{{submitHook}}}: one of: 
                                * {{{formSubmit}}}: The default
                                * {{{validate}}}: Use jquery validate
                                * {{{none}}}: Caller does manually 
                              * {{{validateObjScript}}}: If submitHook is "validate", add this script text to jquery validate({...}) object body
                              See CatoUploadProgress javascript class for available options.
    htmlwrap                = ((boolean), default: true) If true, wrap in @script
-->
<#assign progressScript_defaultArgs = {
  "enabled":true, "htmlwrap":true, "progressOptions":{}, "passArgs":{}
}>
<#macro progressScript args={} inlineArgs...>
  <#local args = mergeArgMaps(args, inlineArgs, catoStdTmplLib.progressScript_defaultArgs)>
  <#local dummy = localsPutAll(args)>
  <#if enabled>
    <#if progressOptions?has_content && progressOptions.formSel?has_content>
      <@script htmlwrap=htmlwrap>
        <@requireScriptOfbizUrl uri="getFileUploadProgressStatus" htmlwrap=false/>
 
          (function() {
              var uploadProgress = null;
          
              jQuery(document).ready(function() {
                <#if progressOptions.successRedirectUrl??>
                  <#-- shouldn't have &amp; in script tag... but code may escape and should support... -->
                  <#local progressOptions = concatMaps(progressOptions, {"successRedirectUrl":progressOptions.successRedirectUrl?replace("&amp;", "&")})>
                </#if>
                  uploadProgress = new CatoUploadProgress(<@objectAsScript lang="js" object=progressOptions />);
                  uploadProgress.reset();
              });
              
            <#if (progressOptions.submitHook!) == "validate">
              jQuery("${progressOptions.formSel}").validate({
                  submitHandler: function(form) {
                      var goodToGo = uploadProgress.initUpload();
                      if (goodToGo) {
                          form.submit();
                      }
                  },
                  ${progressOptions.validateObjScript!""}
              });
            <#elseif (progressOptions.submitHook!) != "none" >
              jQuery("${progressOptions.formSel}").submit(function(event) {
                  var goodToGo = uploadProgress.initUpload();
                  if (!goodToGo) {
                      event.preventDefault();
                  }
              });
            </#if>
          })();
      </@script>
    </#if>
  </#if>
</#macro>

<#-- 
*************
* Progress Bar 
************
A progress bar.

Can be animated using Javascript manually or by using progressOptions argument.  
Presence of progressOptions activates use of CatoUploadProgress script for this progress bar by linking it 
to a form submit.

  * Usage Examples *  
    <@progress value=40/>             
    
    Javascript animation (manual):
    $('#${id}_meter').css("width", "78%");
                     
  * Parameters *
    value                   = ((int)) Percentage done
    id                      = Custom ID; can also be specified as progressOptions.progBarId instead
                              The meter will get an id of "${id}_meter".
                              If omitted, no progress bar per se will be created, but script will still be generated for progressOptions.progTextBoxId.
    type                    = (alert|success|info, default: info)
    class                   = ((css-class)) CSS classes
                              Supports prefixes (see #compileClassArg for more info):
                              * {{{+}}}: causes the classes to append only, never replace defaults (same logic as empty string "")
                              * {{{=}}}: causes the classes to replace non-essential defaults (same as specifying a class name directly)
    containerClass          = ((css-class)) Classes added only on container
                              Supports prefixes (see #compileClassArg for more info):
                              * {{{+}}}: causes the classes to append only, never replace defaults (same logic as empty string "")
                              * {{{=}}}: causes the classes to replace non-essential defaults (same as specifying a class name directly)
    showValue               = Display value inside bar
    progressArgs            = ((map)) If present, attaches progress bar to an upload form with javascript-based progress
                              Attaches results to page using elem IDs and options specified via these arguments,
                              which are passed to @progress macro (see @progress macro for supported options)
    progressOptions         = ((map)) Convenience parameter; same as passing:
                              progressArgs={"enabled":true, "progressOptions":progressOptions}
-->
<#assign progress_defaultArgs = {
  "value":0, "id":"", "type":"", "class":"", "showValue":false, "containerClass":"", "progressArgs":{}, 
  "progressOptions":{}, "passArgs":{}
}>
<#macro progress args={} inlineArgs...>
  <#local args = mergeArgMaps(args, inlineArgs, catoStdTmplLib.progress_defaultArgs)>
  <#local dummy = localsPutAll(args)>
  <#local origArgs = args>
  
  <#local value = value?number>
  
  <#local progressOptions = progressArgs.progressOptions!progressOptions>
  <#local explicitId = id?has_content>
  <#if !id?has_content>
    <#local id = (progressOptions.progBarId)!"">
  </#if>

  <#if !type?has_content>
    <#local type = "info">
  </#if>
  <#local stateClass = styles["progress_state_" + type]!styles["progress_state_info"]!"">

  <@progress_markup value=value id=id class=class showValue=showValue containerClass=containerClass stateClass=stateClass origArgs=origArgs passArgs=passArgs/>
    
  <#if progressOptions?has_content>
    <#local opts = progressOptions>
    <#if explicitId>
      <#local opts = concatMaps(opts, {"progBarId":"${id}"})>
    </#if>
    <#-- inlines always override args map -->
    <@progressScript progressOptions=opts htmlwrap=true args=progressArgs passArgs=passArgs />
  </#if>
</#macro>

<#-- @progress main markup - theme override -->
<#macro progress_markup value=0 id="" class="" showValue=false containerClass="" stateClass="" origArgs={} passArgs={} catchArgs...>
  <#local classes = compileClassArg(class)>
  <#local containerClasses = compileClassArg(containerClass)>
  <div class="${styles.progress_container}<#if !styles.progress_wrap?has_content && classes?has_content> ${classes}</#if><#if stateClass?has_content> ${stateClass}</#if><#if containerClasses?has_content> ${containerClasses}</#if>"<#if id?has_content> id="${id}"</#if>>
    <#if styles.progress_wrap?has_content><div class="${styles.progress_wrap!}<#if classes?has_content> ${classes}</#if>"<#if id?has_content> id="${id!}_meter"</#if> role="progressbar" aria-valuenow="${value!}" aria-valuemin="0" aria-valuemax="100" style="width: ${value!}%"></#if>
      <span class="${styles.progress_bar!}"<#if !styles.progress_wrap?has_content> style="width: ${value!}%"<#if id?has_content> id="${id!}_meter"</#if></#if>><#if showValue>${value!}</#if></span>
    <#if styles.progress_wrap?has_content></div></#if>
  </div>
</#macro>

<#-- 
*************
* asmSelectScript
************
Generates script data and markup needed to turn a multiple-select form field into
dynamic jquery asmselect.

IMPL NOTE: This must support legacy Ofbiz parameters.
                    
  * Parameters *
    * General *
    enabled                 = ((boolean), default: true) If enabled, disables the whole macro
                              Sometimes needed in templates as FTL workaround.
    id                      = Select elem id
    title                   = Select title
    sortable                = ((boolean), default: false)
    formId                  = Form ID
    formName                = Form name
    asmSelectOptions        = (optional) A map of overriding options to pass to asmselect
    asmSelectDefaults       = ((boolean), default: true) If false, will not include any defaults and use asmSelectOptions only
    relatedFieldId          = Related field ID (optional)
    htmlwrap                = ((boolean), default: true) If true, wrap in @script
    * Needed only if relatedFieldId specified *
    relatedTypeName         = Related type, name
    relatedTypeFieldId      = Related type field ID
    paramKey                = Param key 
    requestName             = Request name
    responseName            = Response name
-->
<#assign asmSelectScript_defaultArgs = {
  "enabled":true, "id":"", "title":false, "sortable":false, "formId":"", "formName":"", "asmSelectOptions":{}, 
  "asmSelectDefaults":true, "relatedFieldId":"", "relatedTypeName":"", "relatedTypeFieldId":"", "paramKey":"", 
  "requestName":"", "responseName":"", "htmlwrap":true, "passArgs":{}
}>
<#macro asmSelectScript args={} inlineArgs...>
  <#local args = mergeArgMaps(args, inlineArgs, catoStdTmplLib.asmSelectScript_defaultArgs)>
  <#local dummy = localsPutAll(args)>
  <#if enabled>
    <#-- MIGRATED FROM component://common/webcommon/includes/setMultipleSelectJs.ftl -->
    <#if id?has_content>
    <@script htmlwrap=htmlwrap>
    jQuery(document).ready(function() {
        multiple = jQuery("#${id!}");
    
      <#if !(title?is_boolean && title == false)>
        <#if title?is_boolean>
          <#local title = "">
        </#if>
        // set the dropdown "title" if??
        multiple.attr('title', '${title}');
      </#if>
      
        <#if asmSelectDefaults>
          <#-- Cato: get options from styles -->
          <#local defaultAsmSelectOpts = {
            "addItemTarget": 'top',
            "sortable": sortable!false,
            "removeLabel": uiLabelMap.CommonRemove
            <#--, debugMode: true-->
          }>
          <#local asmSelectOpts = defaultAsmSelectOpts + styles.field_select_asmselect!{} + asmSelectOptions>
        <#else>
          <#local asmSelectOpts = asmSelectOptions>
        </#if>
        // use asmSelect in Widget Forms
        multiple.asmSelect(<@objectAsScript lang="js" object=asmSelectOpts />);
          
      <#if relatedFieldId?has_content> <#-- can be used without related field -->
        // track possible relatedField changes
        // on initial focus (focus-field-name must be relatedFieldId) or if the field value changes, select related multi values. 
        typeValue = jQuery('#${relatedTypeFieldId}').val();
        jQuery("#${relatedFieldId}").one('focus', function() {
          selectMultipleRelatedValues('${requestName}', '${paramKey}', '${relatedFieldId}', '${id}', '${relatedTypeName}', typeValue, '${responseName}');
        });
        jQuery("#${relatedFieldId}").change(function() {
          selectMultipleRelatedValues('${requestName}', '${paramKey}', '${relatedFieldId}', '${id}', '${relatedTypeName}', typeValue, '${responseName}');
        });
        selectMultipleRelatedValues('${requestName}', '${paramKey}', '${relatedFieldId}', '${id}', '${relatedTypeName}', typeValue, '${responseName}');
      </#if>
      });  
    </@script>
    </#if>
  </#if>
</#macro>

<#-- 
*************
* Fieldset
************
A visible fieldset, including the HTML element.

  * Usage Examples *  
    <@fieldset title="">
        Inner Content
    </@fieldset>            
                    
  * Parameters *
    class                   = ((css-class)) CSS classes 
                              Supports prefixes (see #compileClassArg for more info):
                              * {{{+}}}: causes the classes to append only, never replace defaults (same logic as empty string "")
                              * {{{=}}}: causes the classes to replace non-essential defaults (same as specifying a class name directly)
    containerClass          = ((css-class)) CSS classes for wrapper 
                              Includes width in columns, or append only with "+".
                              Supports prefixes (see #compileClassArg for more info):
                              * {{{+}}}: causes the classes to append only, never replace defaults (same logic as empty string "")
                              * {{{=}}}: causes the classes to replace non-essential defaults (same as specifying a class name directly)
    id                      = Fieldset ID
    title                   = Fieldset title
    collapsed               = Show/hide the fieldset
-->
<#assign fieldset_defaultArgs = {
  "id":"", "title":"", "class":"", "containerClass":"", "collapsed":false, "open":true, "close":true, "passArgs":{}
}>
<#macro fieldset args={} inlineArgs...>
  <#local args = mergeArgMaps(args, inlineArgs, catoStdTmplLib.fieldset_defaultArgs)>
  <#-- NOTE: this macro's args are a subset of core's args (but with potentially different defaults), so can just pass the whole thing
  <#local dummy = localsPutAll(args)>
  -->
  <@fieldset_core args=args> <#-- implied: passArgs=passArgs -->
    <#nested />
  </@fieldset_core>
</#macro>

<#-- DEV NOTE: see @section_core for details on "core" pattern 
     migrated from @renderFieldGroupOpen/Close form widget macro -->
<#assign fieldset_core_defaultArgs = {
  "class":"", "containerClass":"", "id":"", "title":"", "collapsed":false, "collapsibleAreaId":"", "expandToolTip":"", "collapseToolTip":"", "collapsible":false, 
  "open":true, "close":true, "passArgs":{}
}>
<#macro fieldset_core args={} inlineArgs...>
  <#local args = mergeArgMaps(args, inlineArgs, catoStdTmplLib.fieldset_core_defaultArgs)>
  <#local dummy = localsPutAll(args)>
  <#local origArgs = args>

  <#if id?has_content>
    <#local containerId = "${id}_container">
  <#else>
    <#local containerId = "">
  </#if>

  <#if open && !close>
    <#local dummy = pushRequestStack("catoFieldsetCoreMarkupStack", {
      "class":class, "containerClass":containerClass, "id":id, "containerId":containerId, "title":title, 
      "collapsed":collapsed, "collapsibleAreaId":collapsibleAreaId, "expandToolTip":expandToolTip, 
      "collapseToolTip":collapseToolTip, "collapsible":collapsible, 
      "origArgs":origArgs, "passArgs":passArgs
    })>
  <#elseif close && !open>
    <#local stackValues = popRequestStack("catoFieldsetCoreMarkupStack")!{}>
    <#local dummy = localsPutAll(stackValues)>
  </#if>
  <@fieldset_markup open=open close=close class=class containerClass=containerClass id=id containerId=containerId title=title collapsed=collapsed collapsibleAreaId=collapsibleAreaId expandToolTip=expandToolTip collapseToolTip=collapseToolTip collapsible=collapsible origArgs=origArgs passArgs=passArgs><#nested></@fieldset_markup>
</#macro>

<#-- @fieldset main markup - theme override -->
<#macro fieldset_markup open=true close=true class="" containerClass="" id="" containerId="" title="" collapsed=false collapsibleAreaId="" expandToolTip="" collapseToolTip="" collapsible=false origArgs={} passArgs={} catchArgs...>
  <#if open>
    <#local containerClass = addClassArg(containerClass, "fieldgroup")>
    <#if collapsible || collapsed>
      <#local containerClass = addClassArg(containerClass, "toggleField")>
      <#if collapsed>
        <#local containerClass = addClassArg(containerClass, styles.collapsed)>
      </#if>
    </#if>
    <#local classes = compileClassArg(class)>
    <#local containerClasses = compileClassArg(containerClass, "${styles.grid_large!}12")>
    <@row open=true close=false />
      <@cell open=true close=false class=containerClasses id=containerId />
        <fieldset<#if classes?has_content> class="${classes!}"</#if><#if id?has_content> id="${id}"</#if>>
      <#--<#if collapsible>
        <ul>
          <li class="<#if collapsed>${styles.collapsed!}">
                      <a onclick="javascript:toggleCollapsiblePanel(this, '${collapsibleAreaId}', '${expandToolTip}', '${collapseToolTip}');">
                    <#else>expanded">
                      <a onclick="javascript:toggleCollapsiblePanel(this, '${collapsibleAreaId}', '${expandToolTip}', '${collapseToolTip}');">
                    </#if>
            &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<#if title?has_content>${title}</#if></a>
          </li>
        </ul>
      <#else>
        <#if title?has_content>${title}</#if>
      </#if><#rt/>
    </div>
    <div id="${collapsibleAreaId}" class="fieldgroup-body" <#if collapsed && collapsible> style="display: none;"</#if>>
    -->
          <#if title?has_content><legend><#if collapsible || collapsed>[ <i class="${styles.icon!} ${styles.icon_arrow!}"></i> ] </#if>${title}</legend></#if>
  </#if>
          <#nested>
  <#if close>
        </fieldset>
      <@cell close=true open=false />
    <@row close=true open=false />
  </#if>
</#macro>

<#-- 
*************
* Fields
************ 
Fields helper that helps modify a set of @field definitions, or group of fields.
Not associated with a visible element, as is @fieldset.
Can be omitted.
May sometimes need multiple of these per form (so @form insufficient for this purpose),
or even multiple per fieldset. 

  * Usage Examples * 
    <@fields>
      <@field attr="" />
      <@field attr="" />
    </@field>
     
    <@fields type="default-nolabelarea">
      <@field attr="" />
      <@field attr="" />
    </@field>
    
    <@fields type="generic" labelArea=false>
      <@field attr="" />
      <@field attr="" />
    </@field>
    
  * Parameters *
    type                        = (default|inherit|inherit-all|generic|..., default: inherit-all) The type of fields arrangement. 
                                  Affects layout and styling of contained fields.
                                  Cato standard markup types:
                                  * {{{default}}}: default cato field arrangement. This is the type assumed when no @fields element is present.
                                    Currently, it mostly influences the label area (present for all @field types except submit).
                                  * {{{inherit}}}: SPECIAL VALUE: causes the {{{type}}} value (only) to inherit from the current parent container. 
                                    If there is no parent, the default is {{{default}}}.
                                    This does not affect the other parameters' fallback behaviors.
                                  * {{{inherit-all}}}: SPECIAL VALUE: Inherits all parameters (including type) from parent @fields element(s).
                                    With this, all unspecified args are inherited from parent @fields element if one exists.
                                    No global style lookups are performed.
                                    If there are no parents, the regular defaults are used, and the default type is {{{default}}}.
                                    This is currently the default when no type is specified or empty. If you want to prevent inheritance of other parameters,
                                    use "inherit", or to prevent inheritance completely, use any other type.
                                  * {{{default-nolabelarea}}}: default cato field arrangement for common sets of fields with no label area.
                                    It expects that @field entries won't be passed any labels except for field types where they may trickle inline into the widget's inline label area.
                                  * {{{default-compact}}}: default cato field arrangement for fields that are in limited space.
                                    By default, this means the labels will be arranged vertically with the fields.
                                  * {{{default-manual}}}: manual field arrangement. Means field arrangement is custom and field macro and theme should not impose
                                    Any layout, but may still apply minor low-level default styling choices and non-optional layout fallbacks. caller determines arrangement/layout/label type/etc.
                                  * {{{default-manual-widgetonly}}}: manual field arrangement without containers. Same as {{{default-manual}}} but with wrappers/containers omitted by default.
                                  * {{{generic}}}: generic field arrangement of no specific pattern and no specific styling. Means field arrangement is custom and field macro and theme should not
                                    Make any assumptions except where a default is required. Caller determines arrangement/layout/label type/etc.
                                  NOTE: For default-manual, generic and similar where styles hash does not specify a label area by default, 
                                      to show a label area for a field, it is NOT sufficient to specify label="xxx".
                                      You must specify both labelArea=true and label="xxx". label arg does not influence presence of label area.
                                      This is explicitly intended, as the label arg is general-purpose in nature and is not associated only with the label area (and anything else will break logic);
                                      Generally, @field specifies label as pure data and theme decides where and how to display it.
                                      In the majority of cases, this should rarely be used anyway; use another more appropriate @fields type instead.
                                  DEV NOTE: Internally, the {{{type}}} values {{{inherit}}} and {{{inherit-all}}} are not stored.
                                      The inheritance is merged immediately and the internal default becomes {{{default}}}.
    labelType                   = (horizontal|vertical|none, default: -type-specific-) Override for type of the field labels themselves
                                  * {{{horizontal}}}: A label area added to the left (or potentially to the right) a field, horizontally. 
                                    the implementation decides how to do this.
                                    DEV NOTE: previously this was called "gridarea". But in the bootstrap code, this no longer makes sense.
                                        It would be perfectly valid for us to add an extra type here called "gridarea" that specifically requires
                                        a grid (TODO?). "horizontal" simply delegates the choice to the implementation.
                                  * {{{vertical}}}: a label area added before (or potentially after) a field, vertically. 
                                    the implementation decides how to do this.
                                  * {{{none}}}: no labels or label areas. Expects the @field macro won't be passed any.
                                  TODO: we should have types here that specifically request that either "gridarea" or "inline" are used for markup:
                                      gridarea-horizontal, gridarea-vertical, inline-horizontal, inline-vertical
                                      The current implementation is unspecific.
    labelPosition               = (left|right|top|bottom|none, default: -type-specific-) Override for layout/positioning of the labels
                                  Some values only make sense for some arrangements.
    labelArea                   = ((boolean), default: -from global styles-) Overrides whether fields are expected to have a label area or not, mainly when label omitted
                                  Logic is influenced by other arguments.
                                  NOTE: This does not determine label area type (horizontal, etc.); only labelType does that (in current code).
                                      They are decoupled. This only controls presence of it.
                                  NOTE: This is weaker than labelArea arg of @field macro, but stronger than other args of this macro.
    labelAreaExceptions         = ((string)|(list), default: -from global styles-) String of space-delimited @field type names or list of names
                                  NOTE: radio and checkbox support special names: radio-single, radio-multi, checkbox-single, checkbox-multi
    labelAreaRequireContent     = ((boolean)) If true, the label area will only be included if label or labelDetail have content
                                  This is generally independent of labelArea boolean and other settings. 
                                  NOTE: This will not affect the fallback logic of labels to inline labels (a.k.a. whether the label area "consumes" the label for itself);
                                      otherwise that would mean labels would always be forced into the label area and never inline.
    labelAreaConsumeExceptions  = ((string)|(list), default: -from global styles-) String of space-delimited @field type names or list of names 
                                  List of field types that should never have their label appear in the main label area.
                                  for these, the label will trickle down into the field's inline area, if it has any (otherwise no label).
                                  NOTE: radio and checkbox support special names: radio-single, radio-multi, checkbox-single, checkbox-multi
    formName                    = The form name the child fields should assume  
    formId                      = The form ID the child fields should assume   
    inlineItems                 = ((boolean)) Change default for @field inlineItems parameter
    checkboxType                = Default checkbox type
    radioType                   = Default radio type  
    open, close                 = ((boolean)) Advanced structure control, for esoteric cases
    ignoreParentField           = ((boolean), default: false) If true, causes all fields within to ignore their parent and behave as if no parent
    fieldArgs                   = A map of @field parameters that will be used as new defaults for each field call
                                  This is an automated mechanism. The map will be blended over the standard @field defaults before the invocation.
                                  In addition, contrary to the parameters, a map passed directly to @fields will be blended over both the @field defaults
                                  AND over any defaults set in the styles for the given @fields type: 
                                  {@field regular defaults} + {fieldargs from styles hash} + {@fields fieldArgs direct arg}
                                  NOTES:
                                  * This may overlap with some of the existing parameters above. Covers other cases not made explicit above.
                                  * If set to boolean false, will prevent all custom default field args and prevent using those set in styles hash. Probably never needed.
                                  e.g.
                                    <@fields type="default" fieldArgs={"labelArea":false}>
-->
<#assign fields_defaultArgs = {
  "type":"", "open":true, "close":true, "labelType":"", "labelPosition":"", "labelArea":"", "labelAreaExceptions":true, "labelAreaRequireContent":"", "labelAreaConsumeExceptions":true,
  "formName":"", "formId":"", "inlineItems":"", "collapse":"", "collapsePostfix":"", "collapsedInlineLabel":"", "checkboxType":"", "radioType":"", "ignoreParentField":"", 
  "fieldArgs":true, "passArgs":{}
}>
<#macro fields args={} inlineArgs...>
  <#-- NOTE: this is non-standard args usage -->
  <#local fieldsInfo = makeFieldsInfo(mergeArgMapsBasic(args, inlineArgs))>
  <#if (fieldsInfo.open!true) == true>
    <#local dummy = pushRequestStack("catoFieldsInfoStack", fieldsInfo)>
  </#if>
    <#nested>
  <#if (fieldsInfo.close!true) == true>
    <#local dummy = popRequestStack("catoFieldsInfoStack")>
  </#if>
</#macro>

<#function makeFieldsInfo args={}>
  <#local origType = args.type!"">
  <#if !origType?has_content>
    <#local origType = "inherit-all">
  </#if>

  <#local parentFieldsInfo = readRequestStack("catoFieldsInfoStack")!{}>

  <#local effType = origType>
  <#local effFieldArgs = args.fieldArgs!true>
  <#local defaultArgs = catoStdTmplLib.fields_defaultArgs>
  
  <#if !origType?has_content>
    <#local effType = "default">
  <#elseif origType == "inherit-all">
    <#if parentFieldsInfo.type??>
      <#-- inherit everything from parent -->
      <#local effType = parentFieldsInfo.type>
      <#local defaultArgs = parentFieldsInfo.origArgs>
      
      <#if args.fieldArgs??>
        <#if args.fieldArgs?is_boolean>
          <#if args.fieldArgs>
            <#local effFieldArgs = parentFieldsInfo.fieldArgs!true>
          <#else>
            <#-- here, prevent combining field args (special case); keep ours -->
          </#if>
        <#else>
          <#if parentFieldsInfo.fieldArgs?is_boolean>
            <#-- no parent field args; keep ours -->
          <#else>
            <#-- combine with parent -->
            <#local effFieldArgs = concatMaps(parentFieldsInfo.fieldArgs, args.fieldArgs)>
          </#if>
        </#if>
      <#else>
        <#local effFieldArgs = parentFieldsInfo.fieldArgs!true>
      </#if>
    <#else>
      <#local effType = "default">
    </#if>
  <#elseif origType == "inherit">
    <#if parentFieldsInfo.type??>
      <#local effType = parentFieldsInfo.type>
    <#else>
      <#local effType = "default">
    </#if>
  </#if>
  
  <#local args = mergeArgMapsBasic(args, {}, defaultArgs)>
  <#local dummy = localsPutAll(args)>
  <#local origArgs = args>
  
  <#local type = effType>
  <#local fieldArgs = effFieldArgs>
  
  <#local stylesType = type?replace("-","_")>
  <#local stylesPrefix = "fields_" + stylesType>
  <#-- DON'T do this, it messes with intuition - individual default fallbacks are good enough
  <#if !styles[stylesPrefix + "_labeltype"]??>
    <#local stylesType = "default">
    <#local stylesPrefix = "fields_default">
  </#if>-->

  <#if !labelArea?is_boolean>
    <#local stylesLabelArea = styles[stylesPrefix + "_labelarea"]!styles["fields_default_labelarea"]!"">
    <#if stylesLabelArea?is_boolean>
      <#local labelArea = stylesLabelArea>
    </#if>
  </#if>
  <#if !labelType?has_content>
    <#local labelType = styles[stylesPrefix + "_labeltype"]!styles["fields_default_labeltype"]!"horizontal">
  </#if>
  <#if !labelPosition?has_content>
    <#local labelPosition = styles[stylesPrefix + "_labelposition"]!styles["fields_default_labelposition"]!"left">
  </#if>
  <#if !labelArea?is_boolean>
    <#local labelArea = (labelType != "none" && labelPosition != "none")>
  </#if>

  <#if !labelAreaExceptions?is_sequence && !labelAreaExceptions?is_string>
    <#if labelAreaExceptions?is_boolean && labelAreaExceptions == false>
      <#local labelAreaExceptions = []>
    <#else>
      <#local labelAreaExceptions = styles[stylesPrefix + "_labelareaexceptions"]!styles["fields_default_labelareaexceptions"]!"">
    </#if>
  </#if>
  <#if labelAreaExceptions?is_string> <#-- WARN: ?is_string unreliable -->
    <#if labelAreaExceptions?has_content>
      <#local labelAreaExceptions = labelAreaExceptions?split(" ")>
    <#else>
      <#local labelAreaExceptions = []>
    </#if>
  </#if>

  <#if !labelAreaRequireContent?is_boolean>
    <#local labelAreaRequireContent = styles[stylesPrefix + "_labelarearequirecontent"]!styles["fields_default_labelarearequirecontent"]!"">
  </#if>

  <#if !labelAreaConsumeExceptions?is_sequence && !labelAreaConsumeExceptions?is_string>
    <#if labelAreaConsumeExceptions?is_boolean && labelAreaConsumeExceptions == false>
      <#local labelAreaConsumeExceptions = []>
    <#else>
      <#local labelAreaConsumeExceptions = styles[stylesPrefix + "_labelareaconsumeexceptions"]!styles["fields_default_labelareaconsumeexceptions"]!"">
    </#if>
  </#if>
  <#if labelAreaConsumeExceptions?is_string> <#-- WARN: ?is_string unreliable -->
    <#if labelAreaConsumeExceptions?has_content>
      <#local labelAreaConsumeExceptions = labelAreaConsumeExceptions?split(" ")>
    <#else>
      <#local labelAreaConsumeExceptions = []>
    </#if>
  </#if>

  <#if !collapse?is_boolean>
    <#local collapse = styles[stylesPrefix + "_collapse"]!styles["fields_default_collapse"]!"">
  </#if>
  <#if !collapsePostfix?is_boolean>
    <#local collapsePostfix = styles[stylesPrefix + "_collapsepostfix"]!styles["fields_default_collapsepostfix"]!"">
  </#if>
  <#if !collapsedInlineLabel?has_content>
    <#local collapsedInlineLabel = styles[stylesPrefix + "_collapsedinlinelabel"]!styles["fields_default_collapsedinlinelabel"]!"">
  </#if>
  <#if collapsedInlineLabel?is_string>
    <#if collapsedInlineLabel?has_content> <#-- WARN: ?is_string unreliable -->
      <#local collapsedInlineLabel = collapsedInlineLabel?split(" ")>
    </#if>
  </#if>
  <#if !checkboxType?has_content>
    <#local checkboxType = styles[stylesPrefix + "_checkboxtype"]!styles["fields_default_checkboxtype"]!"">
  </#if>
  <#if !radioType?has_content>
    <#local radioType = styles[stylesPrefix + "_radiotype"]!styles["fields_default_radiotype"]!"">
  </#if>

  <#if !inlineItems?has_content>
    <#local inlineItems = styles[stylesPrefix + "_inlineitems"]!styles["fields_default_inlineitems"]!"">
  </#if>

  <#local fieldArgsFromStyles = styles[stylesPrefix + "_fieldargs"]!true>
  <#local fieldArgsFromDefaultStyles = styles["fields_default_fieldargs"]!true>
  <#if fieldArgs?is_boolean>
    <#if fieldArgs == true>
      <#if fieldArgsFromStyles?is_boolean>
        <#if fieldArgsFromStyles>
          <#local fieldArgs = fieldArgsFromDefaultStyles>
        <#else>
          <#-- if false, prevents fallback on defaults -->
        </#if>
      <#else>
        <#local fieldArgs = fieldArgsFromStyles>
        <#if !fieldArgsFromDefaultStyles?is_boolean>
          <#local fieldArgs = fieldArgsFromDefaultStyles + fieldArgs>
        </#if>
      </#if>
    </#if>
  <#else>
    <#local fieldArgs = toSimpleMap(fieldArgs)>
    <#if fieldArgsFromStyles?is_boolean>
      <#if fieldArgsFromStyles>
        <#if !fieldArgsFromDefaultStyles?is_boolean>
          <#local fieldArgs = fieldArgsFromDefaultStyles + fieldArgs>
        </#if>
      <#else>
        <#-- if false, prevents fallback on defaults -->
      </#if>
    <#else>
      <#local fieldArgs = fieldArgsFromStyles + fieldArgs>
      <#if !fieldArgsFromDefaultStyles?is_boolean>
        <#local fieldArgs = fieldArgsFromDefaultStyles + fieldArgs>
      </#if>
    </#if>
  </#if>

  <#return {"type":type, "origType":origType, "origArgs":origArgs, "stylesType":stylesType, "stylesPrefix":stylesPrefix, "labelType":labelType, "labelPosition":labelPosition, 
    "labelArea":labelArea, "labelAreaExceptions":labelAreaExceptions, 
    "labelAreaRequireContent":labelAreaRequireContent, "labelAreaConsumeExceptions":labelAreaConsumeExceptions,
    "formName":formName, "formId":formId, "inlineItems":inlineItems,
    "collapse":collapse, "collapsePostfix":collapsePostfix, "collapsedInlineLabel":collapsedInlineLabel,
    "checkboxType":checkboxType, "radioType":radioType,
    "ignoreParentField":ignoreParentField,
    "fieldArgs":fieldArgs}>
</#function>

<#-- 
*************
* mapCatoFieldTypeToStyleName
************ 
Maps a cato field type to a style name representing the type.

Should be coordinated with mapOfbizFieldTypeToStyleName to produce common field type style names.
-->
<#function mapCatoFieldTypeToStyleName fieldType>
  <#local res = (styles.field_type_stylenames_cato[fieldType])!(styles.field_type_stylenames_cato["default"])!"">
  <#if res?is_boolean>
    <#return res?string(fieldType, "")>
  </#if>
  <#return res>
</#function>

<#-- 
*************
* mapOfbizFieldTypeToStyleName
************ 
Maps an Ofbiz field type to a style name representing the type.

Should be coordinated with mapCatoFieldTypeToStyleName to produce common field type style names.
-->
<#function mapOfbizFieldTypeToStyleName fieldType>
  <#local res = (styles.field_type_stylenames_ofbiz[fieldType])!(styles.field_type_stylenames_ofbiz["default"])!"">
  <#if res?is_boolean>
    <#return res?string(fieldType, "")>
  </#if>
  <#return res>
</#function>

<#-- 
*************
* mapOfbizFieldTypeToCatoFieldType
************ 
Maps an Ofbiz field type to a Cato field type.
-->
<#function mapOfbizFieldTypeToCatoFieldType fieldType>
  <#if !ofbizFieldTypeToCatoFieldTypeMap??>
    <#global ofbizFieldTypeToCatoFieldTypeMap = {
      "display": "display",
      "hyperlink": "hyperlink",
      "text": "input",
      "textarea": "textarea",
      "date-time": "datetime",
      "drop-down": "select",
      "check": "checkbox",
      "radio": "radio",
      "submit": "submit",
      "reset": "reset",
      "hidden": "hidden",
      "ignored": "ignored",
      "text-find": "textfind",
      "date-find": "datefind",
      "range-find": "rangefind",
      "lookup": "lookup",
      "file": "file",
      "password": "password",
      "image": "image",
      "display-entity": "displayentity",
      "container": "container",
      "default": "other"
    }>
  </#if>
  <#return ofbizFieldTypeToCatoFieldTypeMap[fieldType]!ofbizFieldTypeToCatoFieldTypeMap["default"]!"">
</#function>

<#-- 
*************
* Field
************ 
A form field input widget with optional label and post-input (postfix) content.

@field can be used as a low-level field control (similar to original Ofbiz
form widget macros, but with friendlier parameters) and for high-level declarations
of fields (similar to the actual <field> elements in Ofbiz form widget definitions, but friendlier
and more configurable). This versatility is the main reason for its implementation complexity.

In the high-level role, the macro takes care of label area logic and alignment
such that you will not get fields looking out of place even if they have no label,
giving all the fields in a given form a default uniform look, which can be customized globally.

@field's behavior can be customized for a set of fields using a parent @fields macro invocation
as well as using the global styles hash (preferred where possible). A set of fields may be grouped under a @fields
call with a @fields "type" selected, which will give all fields within it a predefined look
and behavior. This behavior can be set in the global styles hash (preferred) or overridden directly
in the @fields element.

If no @fields element is used, by default @field will behave the same as if it
were surrounded by a @fields element with "default" type, which gives all fields a default
look out of the box.

To use @field as a low-level control, it should be given a parent @fields with "generic" type.

This system can accodomate custom @fields types, but a default set are provided in the cato
standard markup.

NOTE: All @field arg defaults can be overridden by the @fields fieldArgs argument.

  * Usage Examples *  
    <@field attr="" /> <#- single field using default look ->
    
    <@fields type="default"> <#- single field using default look, same as previous ->
      <@field attr="" />
    </@fields>

    <@fields type="default-nolabelarea"> <#- specific arrangement needed ->
      <@field attr="" />
    </@fields>
    
    <@fields type="default-manual"> <#- use @field as low-level control ->
      <@field attr="" labelArea=true label="My Label" />
    </@fields>    
    
  * Parameters *
    * General *
    type                    = (|generic|..., default: generic) Form element type 
                              Supported values and their parameters are listed in this documentation as
                              parameter sections (groups of parameters), as there are type-specific field parameters.
                              * {{{generic}}}: Means input defined manually with nested content. Mostly for grouping multiple sub-fields, but can be used anywhere.
                                  Specific field types should be preferred to manually defining content, where possible.
    fieldsType              = (|default|..., default: -empty-) CONVENIENCE fields type override
                              By default, this is empty and inherited from parent @fields element.
                              Specifying {{{fieldsType="xxx"}}} as in:
                                <@field type="generic" fieldsType="xxx" .../>
                              is the same as doing:
                                <@fields type="xxx">
                                  <@field type="generic .../>
                                </@fields>
    label                   = Field label
                              For top-level @field elements and and parent fields, normally the label will get consumed
                              by the label area and shown there. for child fields and some other circumstances, or whenever there is
                              no label area, the label will instead be passed down as an "inline label" to the input
                              widget implementation. in some cases, this "inline label" is
                              re-implemented using the label area - see collapsedInlineLabel parameter.
                              NOTE: Presence of label arg does not guarantee a label area will be shown; this is controlled
                                  by labelArea (and labelType) and its defaults, optionally coming from @fields container.
                                  label arg is mainly to provide data; theme and other flags decide what to do with it.
                                  For generic parent fields, label type must be specified explicitly, e.g.
                                    {{{<@fields type="generic"><@field labelType="horizontal" label="mylabel">...</@fields>}}}
                              NOTE: label area behavior may also be influenced by containing macros such as @fields
    labelContent            = ((string)|(macro)) Alternative to {{{label}}} arg which may be a macro and allows manually overriding the basic label markup
                              WARN: Currently (2016-04-12), unlike the {{{label}}} arg, {{{labelContent}}} will not follow any label inlining logic and
                                  is only used by the label area markup. 
                              FIXME?: May want to have labelContent follow label more closely.
    labelDetail             = ((string)|(macro)) Extra content (HTML) inserted with label (normally after label, but theme may decide)
                              2016-04-12: This may also be a macro used to generate the label, which must accept a single {{{args}}} map parameter.
                              NOTE: If need to guarantee post-markup label content, may also use {{{postLabelContent}}} (lower-level control).
    labelContentArgs        = ((map)) Optional map of args to be passed to {{{labelContent}}} and {{{labelDetail}}} in cases where they are macros
                              NOTE: In addition to these values, all the parameters of the theme-implementing @field_markup_labelarea macros
                                  are also passed.
    labelType               = Explicit label type (see @fields)
    labelPosition           = Explicit label layout (see @fields)
    labelArea               = ((boolean), default: -from global styles-) If true, forces a label area; if false, prevents a label area
                              NOTE: This does not determine label area type (horizontal, etc.); only labelType does that (in current code).
                                  They are decoupled. This only controls presence of it.
    labelAreaRequireContent = ((boolean), default: false) If true, the label area will only be included if label or labelDetail have content
                              By default, this is empty string (use @fields type default), and if no styles defaults,
    labelAreaConsume        = ((boolean), default: true) If set to false, will prevent the label area from consuming (displaying) the label
                              The label will trickle down into an inline area if one exists for the field type.
    inlineLabelArea         = ((boolean), default: -from global styles-, fallback default: false) Manual override for inline label logic
                              In general can be left to macro.
    inlineLabel             = ((string)) Manual override for inline label logic
                              In general can be left to macro.
                              NOTE: Often if you specify this it means you might want to set inlineLabelArea=true as well.
    tooltip                 = Small field description - to be displayed to the customer
                              May be set to boolean false to manually prevent tooltip defaults.                       
    description             = Field description
                              NOTE: currently this is treated as an alternative arg for tooltip
                              TODO?: DEV NOTE: this should probably be separate from tooltip in the end...
    name                    = Field name
    value                   = Field value
    totalColumns            = ((int)) Total number of columns spanned by the outer container, including label area, widget and postfix
    widgetPostfixColumns    = ((int)) Number of grid columns to use as size for widget + postfix area (combined)
                              If totalColumns is kept the same, any space removed from this value is given to the label area,
                              and any space added is removed from the label area, also depending on the configuration of the label area.
                              DEV NOTE: This value now includes the postfix area because it is usually easier
                                  to use this way given that the widget + postfix configuration is variable.
    widgetPostfixCombined   = ((boolean), default: -markup decision, usually true-) Overridable setting to force or prevent widget and postfix having their own sub-container
                              It is strongly encouraged to leave this alone in most cases. In Cato standard markup,
                              the default is usually true unless prevented by other settings.
    class                   = ((css-class)) CSS classes for the field element (NOT the cell container!)
                              Supports prefixes (see #compileClassArg for more info):
                              * {{{+}}}: causes the classes to append only, never replace defaults (same logic as empty string "")
                              * {{{=}}}: causes the classes to replace non-essential defaults (same as specifying a class name directly)
    containerClass          = ((css-class)) CSS classes, optional class for outer container 
                              Supports prefixes (see #compileClassArg for more info):
                              * {{{+}}}: causes the classes to append only, never replace defaults (same logic as empty string "")
                              * {{{=}}}: causes the classes to replace non-essential defaults (same as specifying a class name directly)
    widgetAreaClass         = ((css-class)) CSS classes, optional class for widget area container
                              Supports prefixes (see #compileClassArg for more info):
                              * {{{+}}}: causes the classes to append only, never replace defaults (same logic as empty string "")
                              * {{{=}}}: causes the classes to replace non-essential defaults (same as specifying a class name directly)
    labelAreaClass          = ((css-class)) CSS classes, optional class for label area container 
                              Supports prefixes (see #compileClassArg for more info):
                              * {{{+}}}: causes the classes to append only, never replace defaults (same logic as empty string "")
                              * {{{=}}}: causes the classes to replace non-essential defaults (same as specifying a class name directly)
    postfixAreaClass        = ((css-class)) CSS classes, optional class for postfix area container 
                              Supports prefixes (see #compileClassArg for more info):
                              * {{{+}}}: causes the classes to append only, never replace defaults (same logic as empty string "")
                              * {{{=}}}: causes the classes to replace non-essential defaults (same as specifying a class name directly)
    widgetPostfixAreaClass  = ((css-class)) CSS classes, optional class for combined widget and postfix parent container 
                              Supports prefixes (see #compileClassArg for more info):
                              * {{{+}}}: causes the classes to append only, never replace defaults (same logic as empty string "")
                              * {{{=}}}: causes the classes to replace non-essential defaults (same as specifying a class name directly)
    maxlength               = ((int)) Max allowed length 
                              e.g. For text inputs, max number of characters.
    id                      = ((string), default: -auto-generated-) ID for the widget itself
                              If none specified, one may be auto-generated by the macro.
    containerId             = ((string), default: -auto-generated-) ID for the outer container
                              This defaults to {{{"${id}_container"}}}.
    containerStyle          = ((string)) Legacy HTML {{{style}}} attribute for outer container                          
    events                  = ((map)) Map of JS event names to script actions
                              event names can be specified with or without the "on" prefix ("click" or "onclick").
    onClick                 = Shortcut for: events={"click": onClick}
                              WARN: Beware of character case (due to Freemarker). It's onClick, not onclick!
    onChange                = Shortcut for: events={"change": onChange}
    onFocus                 = Shortcut for: events={"focus": onChange}
    disabled                = ((boolean), default: false) Whether field is disabled
    placeholder             = Field placeholder
    alert                   = ((css-class)) CSS classes, additional alert class
    mask                    = ((boolean)) Toggles jQuery mask plugin
    size                    = ((int), default: 20) Size attribute
    collapse                = ((boolean), default: false) Should the whole field (including label and postfix) be collapsing?
    collapsePostfix         = ((boolean), default: true) Should the postfix collapse with the field input?
                              this will not affect label unless collapse is also true (in which case this setting is ignored
                              and the whole field is collapse)
    collapsedInlineLabel    = ((boolean)) Special collapsed inline label control
                              Special function that will only apply in some cases. 
                              if this is set to true and the label does not get consumed
                              by the label area and becomes an inline label, this will cause an auto-implementation
                              of an inlined label using collapsing (instead of passing the inline label
                              down to the individual field type widget).
                              this may be needed for some field types.
    widgetOnly              = ((boolean), default: false) If true, renders only the widget element by default (no containers)
                              Implies {{{container}}} false and {{{labelArea}}} false by default.
                              NOTE: When there is no label area, the {{{label}}} arg trickles down into the widget's inline label area IF it supports one.
    inline                  = ((boolean), default: false) If true, forces container=false, marks the field with styles.field_inline, and forces inline labels (by disabling label area)
                              In other words, turns it into a logically inline element (traditionally, CSS "display: inline;").
                              Theme should act on this style to prevent taking up all the width.
                              In addition, this will force {{{labelArea}}} false and any label specified will use the inlined label (area).
    norows                  = ((boolean), default: false) If true, render without the rows-container
    nocells                 = ((boolean), default: false) If true, render without the cells-container
    container               = ((boolean), default: true) If false, sets norows=true and nocells=true
    ignoreParentField       = ((boolean), default: false) If true causes a child field to act as if it had no parent field. Rarely needed
    required                = ((boolean), default: false) Marks a required input
    requiredClass           = ((css-class)) CSS classes, default required class name
                              Does not support extended class +/= syntax.
    requiredTooltip         = tooltip to use when field is required. this is overridden by regular tooltip
                              for this, can prefix with "#LABEL:" string which indicates to take the named label from uiLabelMap.
    postfix                 = ((boolean), default: false) Controls whether an extra area is appended after widget area
    postfixColumns          = ((int), default: 1) Manual postfix size, in (large) grid columns
    postfixContent          = ((string)|(macro)) Manual postfix markup/content - set to boolean false to prevent any content (but not area container)
                              If macro, the macro must accept a single argument, {{{args}}}, a map of arguments.
    postfixContentArgs      = ((map)) Optional map of arguments to pass to {{{postfixContent}}} macro, if macro
    preWidgetContent        = ((string)|(macro)) Text or text-generating macro that will be inserted in the widget area before widget content (low-level control)
                              If macro, the macro must accept a single argument, {{{args}}}, a map of arguments.
                              NOTE: Currently, the {{{args}}} map will be empty by default - pass using {{{prePostContentArgs}}}.
    postWidgetContent       = ((string)|(macro)) Text or text-generating macro that will be inserted in the widget area after widget content (low-level control)
                              If macro, the macro must accept a single argument, {{{args}}}, a map of arguments.
                              NOTE: Currently, the {{{args}}} map will be empty by default - pass using {{{prePostContentArgs}}}.
    preLabelContent         = ((string)|(macro)) Text or text-generating macro that will be inserted in the label area before label content (low-level control)
                              If macro, the macro must accept a single argument, {{{args}}}, a map of arguments.
                              NOTE: Currently, the {{{args}}} map will be empty by default - pass using {{{prePostContentArgs}}}.
    postLabelContent        = ((string)|(macro)) Text or text-generating macro that will be inserted in the label area after label content (low-level control)
                              If macro, the macro must accept a single argument, {{{args}}}, a map of arguments.
                              NOTE: Currently, the {{{args}}} map will be empty by default - pass using {{{prePostContentArgs}}}.
                              NOTE: This is almost the same as labelDetail, except postLabelContent is lower level and will always occur at the specified position.
    prePostfixContent       = ((string)|(macro)) Text or text-generating macro that will be inserted in the postfix area before postfix content (low-level control)
                              If macro, the macro must accept a single argument, {{{args}}}, a map of arguments.
                              NOTE: Currently, the {{{args}}} map will be empty by default - pass using {{{prePostContentArgs}}}.
    postPostfixContent      = ((string)|(macro)) Text or text-generating macro that will be inserted in the postfix area after postfix content (low-level control)
                              If macro, the macro must accept a single argument, {{{args}}}, a map of arguments.
                              NOTE: Currently, the {{{args}}} map will be empty by default by default - pass using {{{prePostContentArgs}}}.
    prePostContentArgs      = ((map)) Optional map of extra user-supplied args to be passed to the {{{prePostXxx}}} content macros as the {{{args}}} parameter.
    inverted                = ((boolean), default: false) If true, invert the widget and label area content and user-supplied and identifying classes
                              If this is set to true, the widget area content is swapped with the label area content and the user-supplied
                              classes and identifying classes are also swapped - {{{labelAreaClass}}} and {{{widgetAreaClass}}}. 
                              In addition, the top-level container gets a class to mark it as inverted.
                              However, the calculated default grid area classes are NOT swapped by default; this allows swapping content while
                              preserving grid alignment. Mostly useful for small field widgets such as checkboxes and radios.
                              NOTE: You may want to use {{{labelContent}}} arg to specify content.
    standardClass           = ((css-class)) CSS classes, default standard (non-inverted) class name, added to outer container
                              Does not support extended class +/= syntax.
                              Added for non-inverted fields.
    invertedClass           = ((css-class)) CSS classes, default inverted class name, added to outer container
                              Does not support extended class +/= syntax.
                                       
        
    * input (alias: text) *
    autoCompleteUrl         = If autocomplete function exists, specification of url will make it available
    postfix                 = ((boolean), default: false) If set to true, attach submit button
    
    * textarea *
    readonly                = ((boolean) Read-only
    rows                    = ((int)) Number of rows
    cols                    = ((int)) Number of columns
    wrap                    = HTML5 wrap attribute
    text, value             = Text/value, alternative to nested content
    
    * datetime *
    dateType                = (date-time|timestamp|date|time, default: date-time) Type of datetime
                              "date-time" and "timestamp" are synonymous.
    dateDisplayType         = (default|date|..., default: -same as dateType-). The visual display format of the date. Optional
                              If dateType is "date-time" (timestamp), it is possible to specify dateDisplayType="date" here.
                              This means the user will be presented with a short date only, but the data sent to the server
                              will be a full timestamp.
    title                   = Title
                              If empty, markup/theme decides what to show.
                              Can also be a special value in format {{{"#PROP:resource#propname"}}} (if no {{{resource}}}, taken from CommonUiLabels).
                              NOTE: tooltip has priority over title.
    
    * datefind *
    dateType                = (-same as datetime-)
    dateDisplayType         = (-same as datetime-)
    opValue                 = The selected operator (value)
    
    * textfind *
    opValue                 = The selected operator (value)
    ignoreCaseValue         = ((boolean), default: true) The ignore case checkbox current value
                              The default should be same as form widget default (text-find's "ignore-case" in widget-form.xsd).
    hideOptions             = ((boolean), default: false) If true, don't show select options
    hideIgnoreCase          = ((boolean), default: false) If true, hide case sensitivity boolean
    titleClass              = ((css-class)) CSS classes, extra classes for title
    
    * rangefind *
    opFromValue             = The selected "from" operator (value)
    opThruValue             = The selected "thru" operator (value)
    titleClass              = ((css-class)) CSS classes, extra classes for title
    
    * select *
    multiple                = ((boolean), default: false) Allow multiple select
    items                   = ((list)) List of maps; if specified, generates options from list of maps 
                              List of {"value": (value), "description": (label), "selected": (true/false)} maps
                              If items list not specified, manual nested content options can be specified instead.
                              NOTE: {{{selected}}} is currently ignored for non-multiple (uses {{{currentValue}}} instead).
    allowEmpty              = ((boolean), default: false) If true, will add an empty option
    currentValue            = currently selected value/key (only for non-multiple)
    currentFirst            = ((boolean), default: false) If true (and multiple false), will add a "first" item with current value selected, if there is one
    currentDescription      = If currentFirst true, this is used as first's description if specified
    defaultValue            = Optional selected option value for when none otherwise selected
    manualItemsOnly         = ((boolean)) Optional hint to say this select should contain exclusively manually generated items
                              By default, this is determined based on whether the items arg is specified or not.
    manualItems             = ((boolean)) Optional hint to say that nested content contains manual options (but not necessarily exclusively)
                              By default, this is determined based on whether the items arg is specified or not (NOT whether
                              there is any nested content or not).
                              If specifying both items arg AND nested content (discouraged), this should be manually set to true.
    asmSelectArgs           = ((map)) Optional map of args to pass to @asmSelectScript to transform a multiple type select into a jQuery asmselect select
                              Usually only valid if multiple is true.
    formName                = Name of form containing the field
    formId                  = ID of form containing the field
    title                   = Title attribute of <select> element
    
    * option *
    text                    = Option label 
                              May also be specified as nested.
    value                   = Value, sent to server upon submit
    selected                = ((boolean))
    
    * lookup *
    formName                = The name of the form that contains the lookup field
    fieldFormName           = Contains the lookup window form name
    * checkbox (single mode) *
    value                   = Y/N
    currentValue            = Current value, used to check if should be checked
    checked                 = ((boolean)|, default: -empty-) Override checked state 
                              If set to boolean, overrides currentValue logic
    checkboxType            = (default|..., default: default)
                              Generic:
                              * {{{default}}}: default theme checkbox
                              Cato standard theme:
                              * {{{simple}}}: guarantees a minimalistic checkbox
    
    * checkbox (multi mode) *
    items                   = ((list)) List of maps, if specified, multiple-items checkbox field generated
                              List of {"value": (value), "description": (label), "tooltip": (tooltip), "events": (js event map), "checked": (true/false)} maps
                              NOTE: use of "checked" attrib is discouraged; is a manual override (both true and false override); prefer setting currentValue on macro
                              DEV NOTE: the names in this map cannot be changed easily; legacy ofbiz macro support
    inlineItems             = ((boolean), default: -from global styles-, fallback default: true) If true, radio items are many per line; if false, one per line
                              NOTE: this takes effect whether single-item or multiple-item radio.
                              the default can be overridden on a parent @field or @fields element.
    currentValue            = Current value, determines checked; this can be single-value string or sequence of value strings
    defaultValue            = Default value, determines checked (convenience parameter; used when currentValue empty; can also be sequence)
    allChecked              = ((boolean|), default: -empty-) Explicit false sets all to unchecked; leave empty "" for no setting (convenience parameter)
    
    * radio (single mode) *
    value                   = Y/N, only used if single radio item mode (items not specified)
    currentValue            = Current value, used to check if should be checked
    checked                 = ((boolean)|, default: -empty-) Override checked state 
                              If set to boolean, overrides currentValue logic
    radioType               = (default|..., default: default)
                              Generic:
                              * {{{default}}}: default theme radio
                              Cato standard theme:
                              * See global styles.
    
    * radio (multi mode) *
    items                   = ((list)) List of maps, if specified, multiple-items radio generated with map entries in provided list as arguments
                              List of {"value": (value), "description": (label), "tooltip": (tooltip), "events": (js event map), "checked": (true/false)} maps
                              NOTE: use of "checked" attrib is discouraged; is a manual override (both true and false override); prefer setting currentValue on macro
                              DEV NOTE: the names in this map cannot be changed easily; legacy ofbiz macro support
    inlineItems             = ((boolean), default: -from global styles-, fallback default: true) If true, radio items are many per line; if false, one per line
                              NOTE: This takes effect whether single-item or multiple-item radio.
                              The default can be overridden on a parent @field or @fields element.
    currentValue            = Current value, determines checked
    defaultValue            = Default value, determines checked (convenience option; used when currentValue empty)
    
    * file *
    autocomplete            = ((boolean), default: true) If false, prevents autocomplete
    
    * password *
    autocomplete            = ((boolean), default: true) If false, prevents autocomplete
    
    * submitarea *
    (nested)                = ((markup)) Button(s) to include
                              The buttons may be generated with {{{<@field type="submit">}}} or manual {{{<input>}}}, {{{<a>}}}, {{{<button>}}} elements.
    progressArgs            = ((map)) If this is an upload form, arguments to pass to @progress macro
                              See @progress and @progressScript macros. Should specify formSel, at least one of progBarId and progTextBoxId, and others.
    progressOptions         = ((map)) Progress options (convenience parameter)
                              Same as passing:
                                progressArgs={"enabled":true, "progressOptions":progressOptions}      
                      
    * submit *
    submitType              = (submit|link|button|image|input-button, default: submit) Submit element type
                              * {{{submit}}}: {{{<input type="submit" ... />}}}
                              * {{{input-button}}}: {{{<input type="button" ... />}}}
                              * {{{link}}}: {{{<a href="..." ...>...</a>}}}
                                NOTE: href should usually be specified for this, or explicitly set to boolean false if using onClick. 
                                    If not specified, generated href will cause form submit with form name (if found and not disabled).
                              * {{{button}}}: {{{<input type="button" ... />}}}
                                WARN: FIXME?: Currently this is same as input-button: {{{<input type="button" ... />}}}
                                  This could change to {{{<button...>...</button>}}} without notice...
                              * {{{image}}}: {{{<input type="image" src="..." .../>}}}
    text                    = Display text
                              NOTE: {{{value}}} arg is also accepted instead of {{{text}}}.
    href                    = href for submitType "link"  
                              NOTE: This parameter is automatically (re-)escaped for HTML and javascript (using #escapeFullUrl or equivalent) 
                                  to help prevent injection, as it is high-risk. It accepts pre-escaped query string delimiters for compatibility,
                                  but other characters should not be manually escaped (apart from URL parameter encoding).
    src                     = Image url for submitType "image"    
    confirmMsg              = Confirmation message     
    progressArgs            = Same as for submitarea, but only works if this is a top-level submit     
    progressOptions         = Same as for submitarea, but only works if this is a top-level submit
    style                   = Legacy HTML style string for compatibility
                              This is set only on the widget itself (not any container).
                              WARN: Currently this arg only works for submits, not other field types.
                      
    * reset *
    text                    = Label to show on reset button
                      
    * display *
    valueType               = (image|text|currency|date|date-time|timestamp|accounting-number|generic, default: generic)
                              "date-time" and "timestamp" are synonymous.
                              * {{{generic}}}: treated as arbitrary content, but text may still be interpreted
                              TODO: Currently all are handled as text/generic (because formatting done in java in stock ofbiz)
    value                   = Display value or image URL
    description             = For image type: image alt
    tooltip                 = Tooltip text
                              May result in extra wrapping container.
    formatText              = ((boolean), default: false) If true, translates newlines to HTML linebreaks (and potentially other transformations)
                              NOTE: The default for @field macro is currently false, which differs from the Ofbiz form widget default, which is true.
                              WARN: It is possible the default may be changed to true for specific valueTypes. However, the default for "generic" will always be false.   
    
    * generic *
    tooltip                 = Tooltip text
                              May result in extra wrapping container.
-->
<#assign field_defaultArgs = {
  "type":"", "fieldsType":"", "label":"", "labelContent":false, "labelDetail":false, "name":"", "value":"", "valueType":"", "currentValue":"", "defaultValue":"", "class":"", "size":20, "maxlength":"", "id":"", 
  "onClick":"", "onChange":"", "onFocus":"",
  "disabled":false, "placeholder":"", "autoCompleteUrl":"", "mask":false, "alert":"false", "readonly":false, "rows":"4", 
  "cols":"50", "dateType":"date-time", "dateDisplayType":"",  "multiple":"", "checked":"", 
  "collapse":"", "collapsePostfix":"", "collapsedInlineLabel":"",
  "tooltip":"", "totalColumns":"", "widgetPostfixColumns":"", "widgetPostfixCombined":"", "norows":false, "nocells":false, "container":"", "widgetOnly":"", "containerId":"", "containerClass":"", "containerStyle":"",
  "fieldFormName":"", "formName":"", "formId":"", "postfix":false, "postfixColumns":"", "postfixContent":true, "required":false, "requiredClass":"", "requiredTooltip":true, "items":false, "autocomplete":true, "progressArgs":{}, "progressOptions":{}, 
  "labelType":"", "labelPosition":"", "labelArea":"", "labelAreaRequireContent":"", "labelAreaConsume":"", "inlineLabelArea":"", "inlineLabel":false,
  "description":"",
  "submitType":"input", "text":"", "href":"", "src":"", "confirmMsg":"", "inlineItems":"", 
  "selected":false, "allowEmpty":false, "currentFirst":false, "currentDescription":"",
  "manualItems":"", "manualItemsOnly":"", "asmSelectArgs":{}, "title":"", "allChecked":"", "checkboxType":"", "radioType":"", 
  "inline":"", "ignoreParentField":"",
  "opValue":"", "opFromValue":"", "opThruValue":"", "ignoreCaseValue":"", "hideOptions":false, "hideIgnoreCase":false,
  "titleClass":"", "formatText":"",
  "preWidgetContent":false, "postWidgetContent":false, "preLabelContent":false, "postLabelContent":false, "prePostfixContent":false, "postPostfixContent":false,
  "prePostContentArgs":{}, "postfixContentArgs":{}, "labelContentArgs":{}, "style":"",
  "widgetAreaClass":"", "labelAreaClass":"", "postfixAreaClass":"", "widgetPostfixAreaClass":"",
  "inverted":false, "invertedClass":"", "standardClass":"",
  "events":{}, "wrap":"", "passArgs":{} 
}>
<#macro field args={} inlineArgs...> 
  <#-- TODO: Group arguments above so easier to read... -->

  <#-- parent @fields group elem info (if any; may be omitted in templates) -->
  <#local fieldsType = inlineArgs.fieldsType!args.fieldsType!field_defaultArgs.fieldsType>
  <#if fieldsType?has_content>
    <#local fieldsInfo = makeFieldsInfo({"type":fieldsType})>
  <#else>
    <#local fieldsInfo = readRequestStack("catoFieldsInfoStack")!{}>
    <#if !fieldsInfo.type??>
      <#if !catoDefaultFieldsInfo?has_content>
        <#-- optimization -->
        <#global catoDefaultFieldsInfo = makeFieldsInfo({"type":"default"})>
      </#if>
      <#local fieldsInfo = catoDefaultFieldsInfo>
    </#if>
  </#if>

  <#-- special default fields override -->
  <#local defaultArgs = catoStdTmplLib.field_defaultArgs>
  <#if !fieldsInfo.fieldArgs?is_boolean>
    <#local defaultArgs = defaultArgs + fieldsInfo.fieldArgs>
  </#if>

  <#-- standard args -->
  <#local args = mergeArgMaps(args, inlineArgs, defaultArgs)>
  <#local dummy = localsPutAll(args)>
  <#local origArgs = args>
        
  <#-- other defaults -->      
  <#if !type?has_content>
    <#local type = "generic">
  <#elseif type == "text">
    <#local type = "input">
  </#if>
  <#if !valueType?has_content>
    <#local valueType = "generic">
  </#if>

  <#local fieldsType = (fieldsInfo.type)!"">

  <#if inline?is_boolean && inline == true>
    <#local container = false>
    <#local class = addClassArg(class, styles.field_inline!)>
    <#-- force label to be inline using our own user flags (easiest) -->
    <#if !labelArea?is_boolean>
      <#local labelArea = false>
    </#if>
  </#if>

  <#if widgetOnly?is_boolean && widgetOnly == true>
    <#local container = false>
    <#if !labelArea?is_boolean>
      <#local labelArea = false>
    </#if>
  </#if>

  <#if onClick?has_content>
    <#local events = events + {"click": onClick}>
  </#if>
  <#if onChange?has_content>
    <#local events = events + {"change": onChange}>
  </#if>
  <#if onFocus?has_content>
    <#local events = events + {"focus": onFocus}>
  </#if>
  
  <#-- Backward-compability - don't consider empty string (or empty anything) as having content -->
  <#if !labelContent?has_content && !labelContent?is_directive>
    <#local labelContent = false>
  </#if>
  <#if !labelDetail?has_content && !labelDetail?is_directive>
    <#local labelDetail = false>
  </#if>
  <#if !preWidgetContent?has_content && !preWidgetContent?is_directive>
    <#local preWidgetContent = false>
  </#if>
  <#if !postWidgetContent?has_content && !postWidgetContent?is_directive>
    <#local postWidgetContent = false>
  </#if>
  <#if !preLabelContent?has_content && !preLabelContent?is_directive>
    <#local preLabelContent = false>
  </#if>
  <#if !postLabelContent?has_content && !postLabelContent?is_directive>
    <#local postLabelContent = false>
  </#if>
  <#if !prePostfixContent?has_content && !prePostfixContent?is_directive>
    <#local prePostfixContent = false>
  </#if>
  <#if !postPostfixContent?has_content && !postPostfixContent?is_directive>
    <#local postPostfixContent = false>
  </#if>

  <#-- parent @field elem info (if any; is possible) -->
  <#local parentFieldInfo = readRequestStack("catoFieldInfoStack")!{}>
  <#-- allow ignore parent -->
  <#if ignoreParentField?is_boolean>
    <#if ignoreParentField>
      <#local parentFieldInfo = {}>
    </#if>
  <#elseif fieldsInfo.ignoreParentField?is_boolean>
    <#if fieldsInfo.ignoreParentField>
      <#local parentFieldInfo = {}>
    </#if>
  </#if>
  <#local hasParentField = ((parentFieldInfo.type)!"")?has_content>
  <#local isTopLevelField = !hasParentField>
  <#local isChildField = hasParentField>
  
  <#local formInfo = readRequestStack("catoFormInfoStack")!{}>
  
  <#-- get custom default for inlineItems -->
  <#if !inlineItems?has_content>
    <#if parentFieldInfo.inlineItems?has_content>
      <#local inlineItems = parentFieldInfo.inlineItems>
    <#elseif fieldsInfo.inlineItems?has_content>
      <#local inlineItems = fieldsInfo.inlineItems>
    </#if>
  </#if>
  
  <#-- get form name and id -->
  <#if !formName?has_content>
    <#if fieldsInfo.formName?has_content>
      <#local formName = fieldsInfo.formName>
    <#elseif formInfo.name?has_content>
      <#local formName = formInfo.name>
    </#if>
  </#if>
  <#if !formId?has_content>
    <#if fieldsInfo.formId?has_content>
      <#local formId = fieldsInfo.formName>
    <#elseif formInfo.id?has_content>
      <#local formId = formInfo.id>
    </#if>
  </#if>

  <#local fieldIdNum = getNextFieldIdNum()>
  <#if !id?has_content>
    <#local id = getNextFieldId(fieldIdNum)>
  </#if>
  <#if !containerId?has_content && id?has_content>
    <#local containerId = id + "_container">
  </#if>
  
  <#if required && (!requiredClass?is_boolean && requiredClass?has_content)>
    <#local class = addClassArg(class, requiredClass)>
  </#if>

  <#if required && !(tooltip?is_boolean && tooltip == false) && !(requiredTooltip?is_boolean && requiredTooltip == false)>
    <#if !requiredTooltip?is_boolean && requiredTooltip?has_content>
      <#-- 2016-04-21: This should ADD to the tooltip, not replace it
      <#local tooltip = getTextLabelFromExpr(requiredTooltip)>-->
      <#local tooltip = addStringToBoolStringVal(tooltip, getTextLabelFromExpr(requiredTooltip)!"", styles.tooltip_delim!" - ")>
    </#if>
  </#if>

  <#if inverted>
    <#if (!invertedClass?is_boolean && invertedClass?has_content)>
      <#local containerClass = addClassArg(containerClass, invertedClass)>
    </#if>
  <#else>
    <#if (!standardClass?is_boolean && standardClass?has_content)>
      <#local containerClass = addClassArg(containerClass, standardClass)>
    </#if>  
  </#if>

  <#-- treat tooltip and description (nearly) as synonyms for now -->
  <#if !tooltip?is_boolean && tooltip?has_content>
    <#if !(description?is_boolean && description == false) && !description?has_content>
      <#local description = tooltip>
    </#if>
  <#else>
    <#if (!description?is_boolean && description?has_content) && !(tooltip?is_boolean && tooltip == false)>
      <#local tooltip = description>
    </#if>
  </#if>

  <#-- the widgets do this now
  <#local class = compileClassArg(class)>-->
    
  <#if !container?is_boolean>
    <#if container?has_content>
      <#local container = container?boolean>
    <#elseif isChildField && (((styles.field_type_nocontainer_whenchild[type])!false) || 
      ((styles.field_type_nocontainer_whenhasparent[parentFieldInfo.type!])!false))>
      <#local container = false>
    <#else> 
      <#local container = true>
    </#if>
  </#if>
  
  <#-- label area logic
      NOTE: labelArea boolean logic does not determine "label type" or "label area type"; 
          only controls presence of. so labelArea logic and usage anywhere should not change
          if new label (area) type were to be added (e.g. on top instead of side by side). -->
  <#if labelArea?is_boolean>
    <#local labelAreaDefault = labelArea>
  <#elseif labelType == "none" || labelPosition == "none">
    <#local labelAreaDefault = false>
  <#elseif isChildField>
    <#local labelAreaDefault = false>
  <#else>
    <#local labelAreaDefault = (fieldsInfo.labelArea)!false>
    <#if (fieldsInfo.labelAreaExceptions)?has_content && (fieldsInfo.labelAreaExceptions)?is_sequence>
      <#if fieldsInfo.labelAreaExceptions?seq_contains(type)>
        <#local labelAreaDefault = !labelAreaDefault>
      <#elseif (type == "radio" || type == "checkbox")>
        <#if fieldsInfo.labelAreaExceptions?seq_contains(type + "-single") && !items?is_sequence>
          <#local labelAreaDefault = !labelAreaDefault>
        <#elseif fieldsInfo.labelAreaExceptions?seq_contains(type + "-multi") && items?is_sequence>
          <#local labelAreaDefault = !labelAreaDefault>
        </#if>
      </#if>
    </#if>
  </#if>
  
  <#if labelType?has_content>
    <#local effLabelType = labelType>
  <#else>
    <#local effLabelType = (fieldsInfo.labelType)!"">
  </#if>
  <#if labelPosition?has_content>
    <#local effLabelPosition = labelPosition>
  <#else>
    <#local effLabelPosition = (fieldsInfo.labelPosition)!"">
  </#if>

  <#if collapsedInlineLabel?is_boolean>
    <#local effCollapsedInlineLabel = collapsedInlineLabel>
  <#else>
    <#local effCollapsedInlineLabel = (fieldsInfo.collapsedInlineLabel)![]>
  </#if>

  <#if !labelAreaRequireContent?is_boolean>
    <#local labelAreaRequireContent = (fieldsInfo.labelAreaRequireContent)!false>
    <#if !labelAreaRequireContent?is_boolean>
      <#local labelAreaRequireContent = false>
    </#if>
  </#if>
  
  <#-- The way this now works is that labelArea boolean is the master control, and 
      by default, presence of label or labelDetail (with ?has_content) does NOT influence if label area
      will be present or not.
      
      It is now this way so that the code has the ability to "consume" (show) the label if a label
      area is present; if there's no label area, the label is passed down to the input widget as inlineLabel.
      This is needed for radio, checkbox and probably others later.
      
      There is another labelAreaRequireContent control that is separate from the consumation logic.
      In our default setup we want it set to false, but can be changed in styles and calls.
      -->
  <#local labelAreaConsumeLabel = (labelArea?is_boolean && labelArea == true) || 
      (!(labelArea?is_boolean && labelArea == false) && (labelAreaDefault))>
  <#if labelAreaConsume?is_boolean> <#-- this is the user setting -->
    <#-- user can prevent consuming by setting false -->
    <#local labelAreaConsumeLabel = labelAreaConsumeLabel && labelAreaConsume>
  <#else>
    <#-- check if @fields style prevents consuming -->
    <#if (fieldsInfo.labelAreaConsumeExceptions)?has_content && (fieldsInfo.labelAreaConsumeExceptions)?is_sequence>
      <#if fieldsInfo.labelAreaConsumeExceptions?seq_contains(type)>
        <#local labelAreaConsumeLabel = false>
      <#elseif (type == "radio" || type == "checkbox")>
        <#if fieldsInfo.labelAreaConsumeExceptions?seq_contains(type + "-single") && !items?is_sequence>
          <#local labelAreaConsumeLabel = false>
        <#elseif fieldsInfo.labelAreaConsumeExceptions?seq_contains(type + "-multi") && items?is_sequence>
          <#local labelAreaConsumeLabel = false>
        </#if>
      </#if>
    </#if>
  </#if>
  
  <#local origLabel = label>
  <#local effInlineLabel = false> <#-- this is really a string -->
  <#if !labelAreaConsumeLabel && !(inlineLabelArea?is_boolean && inlineLabelArea == false)>
    <#-- if there's no label area or if it's not set to receive the label, 
        label was not used up, so label arg becomes an inline label (used on radio and checkbox) 
        - unless caller overrides with his own inline label for whatever reason 
        - and unless he wants to prevent inline area with inlineLabelArea = false -->
    <#if !(inlineLabel?is_boolean && inlineLabel == false)>
      <#local effInlineLabel = inlineLabel>
    <#else>
      <#local effInlineLabel = label>
    </#if>
    <#local label = "">
  <#elseif inlineLabelArea?is_boolean && inlineLabelArea == true>
    <#-- caller wants a specific inline label -->
    <#local effInlineLabel = inlineLabel>
  </#if>

  <#-- NOTE: labelAreaRequireContent should not affect consume logic above -->
  <#local useLabelArea = (labelArea?is_boolean && labelArea == true) || 
    (!(labelArea?is_boolean && labelArea == false) && 
      (!labelAreaRequireContent || (label?has_content || !labelContent?is_boolean || !labelDetail?is_boolean)) && (labelAreaDefault))>
  
  <#-- FIXME?: labelContent currently does not follow the label inlining logic; only @field_markup_labelarea will render it -->
  
  <#-- Special case where inlineLabel is re-implemented using actual label area using collapsing. -->
  <#if !(effInlineLabel?is_boolean && effInlineLabel == false) && effInlineLabel?has_content && 
    ((effCollapsedInlineLabel?is_boolean && effCollapsedInlineLabel == true) ||
     (effCollapsedInlineLabel?is_sequence && effCollapsedInlineLabel?seq_contains(type)))>
    <#local useLabelArea = true>
    <#local label = effInlineLabel>
    <#if label?is_boolean>
      <#local label = "">
    </#if>
    <#local effInlineLabel = false> <#-- we're using it, so don't pass it down to widget anymore -->
    <#if !collapse?is_boolean>
      <#local collapse = true>
    </#if>
  </#if>
  
  <#if !collapse?is_boolean>
    <#local collapse = (fieldsInfo.collapse)!false>
    <#if !collapse?is_boolean>
      <#local collapse = false>
    </#if>
  </#if>
  <#if !collapsePostfix?is_boolean>
    <#local collapsePostfix = (fieldsInfo.collapsePostfix)!true>
    <#if !collapsePostfix?is_boolean>
      <#local collapsePostfix = true>
    </#if>
  </#if>
  
  <#-- TODO?: ensure boolean string because next calls don't yet support it as boolean -->
  <#if tooltip?is_boolean>
    <#local tooltip = "">
  </#if>
  <#if description?is_boolean>
    <#local description = "">
  </#if>
  
  <#-- push this field's info (popped at end) -->
  <#local fieldInfo = {"type":type, "inlineItems":inlineItems, "id":id}>
  <#local dummy = pushRequestStack("catoFieldInfoStack", fieldInfo)>
  
  <#-- main markup begin -->
  <#local labelAreaContent = false>
  <#if useLabelArea>
    <#local labelAreaContent = fieldLabelAreaInvoker><#-- macro -->
    <#-- NOTE: origArgs is passed because in some cases it may be important for markup to know if the caller manually
        specified a certain parameter to @field or not - the other logical args don't record this info -->
    <#-- DEV NOTE: WARN: If you add any arguments here, they must also be added to @fieldLabelAreaInvoker macro below! 
        This pattern is used to get the @field_markup_labelarea invocation to occur at the correct time (within the label area) -->
    <#-- DEV NOTE: Also see @fieldLabelAreaInvoker - it recombines labelAreaContentArgs into labelContentArgs! -->
    <#local labelAreaContentArgs = {"labelType":effLabelType, "labelPosition":effLabelPosition, "label":label, "labelContent":labelContent, "labelDetail":labelDetail, 
        "fieldType":type, "fieldsType":fieldsType, "fieldId":id, "collapse":collapse, "required":required, "labelContentArgs":labelContentArgs, 
        "norows":norows, "nocells":nocells, "container":container,
        "origArgs":origArgs, "passArgs":passArgs}>
  </#if>
      
  <@field_markup_container type=type fieldsType=fieldsType totalColumns=totalColumns widgetPostfixColumns=widgetPostfixColumns widgetPostfixCombined=widgetPostfixCombined postfix=postfix postfixColumns=postfixColumns 
    postfixContent=postfixContent labelArea=useLabelArea labelType=effLabelType labelPosition=effLabelPosition labelAreaContent=labelAreaContent 
    collapse=collapse collapsePostfix=collapsePostfix norows=norows nocells=nocells container=container containerId=containerId containerClass=containerClass containerStyle=containerStyle
    preWidgetContent=preWidgetContent postWidgetContent=postWidgetContent preLabelContent=preLabelContent postLabelContent=postLabelContent prePostfixContent=prePostfixContent postPostfixContent=postPostfixContent
    labelAreaContentArgs=labelAreaContentArgs postfixContentArgs=postfixContentArgs prePostContentArgs=prePostContentArgs
    widgetAreaClass=widgetAreaClass labelAreaClass=labelAreaClass postfixAreaClass=postfixAreaClass widgetPostfixAreaClass=widgetPostfixAreaClass
    inverted=inverted origArgs=origArgs passArgs=passArgs>
    <#switch type>
      <#case "input">
        <@field_input_widget name=name 
                              class=class 
                              alert=alert 
                              value=value 
                              textSize=size 
                              maxlength=maxlength 
                              id=id 
                              events=events
                              disabled=disabled
                              readonly=readonly 
                              clientAutocomplete="" 
                              ajaxUrl=autoCompleteUrl 
                              ajaxEnabled="" 
                              mask=mask 
                              placeholder=placeholder 
                              tooltip=tooltip
                              inlineLabel=effInlineLabel
                              passArgs=passArgs/>
        <#break>
      <#case "textarea">
        <@field_textarea_widget name=name 
                              class=class 
                              alert=alert 
                              cols=cols 
                              rows=rows 
                              id=id
                              readonly=readonly 
                              value=value 
                              placeholder=placeholder
                              tooltip=tooltip
                              inlineLabel=effInlineLabel
                              wrap=wrap
                              passArgs=passArgs>${text}${value}<#nested></@field_textarea_widget>
        <#break>
      <#case "datetime">
        <#if dateType == "date" || dateType == "time">
          <#-- leave as-is -->
        <#else> <#-- "date-time" -->
          <#local dateType = "timestamp">
        </#if>
        <@field_datetime_widget name=name 
                              class=class 
                              alert=alert 
                              title=title 
                              value=value 
                              size=size 
                              maxlength=maxlength 
                              id=id 
                              dateType=dateType 
                              dateDisplayType=dateDisplayType 
                              formName=formName
                              tooltip=tooltip
                              origLabel=origLabel
                              inlineLabel=effInlineLabel
                              passArgs=passArgs/>                
        <#break>
      <#case "datefind">
        <#if dateType == "date" || dateType == "time">
          <#-- leave as-is -->
        <#else> <#-- "date-time" -->
          <#local dateType = "timestamp">
        </#if>
        <#if opFromValue?has_content>
          <#local datefindOpFromValue = opFromValue>
        <#else>
          <#local datefindOpFromValue = opValue>
        </#if>
        <@field_datefind_widget name=name 
                              class=class 
                              alert=alert 
                              title=title 
                              value=value 
                              defaultOptionFrom=datefindOpFromValue
                              size=size 
                              maxlength=maxlength 
                              id=id 
                              dateType=dateType 
                              dateDisplayType=dateDisplayType 
                              formName=formName
                              tooltip=tooltip
                              origLabel=origLabel
                              inlineLabel=effInlineLabel
                              passArgs=passArgs/>                 
        <#break>
      <#case "textfind">
        <@field_textfind_widget name=name 
                              class=class 
                              alert=alert 
                              title=title 
                              value=value 
                              defaultOption=opValue
                              ignoreCase=ignoreCaseValue
                              size=size 
                              maxlength=maxlength 
                              id=id 
                              formName=formName
                              tooltip=tooltip
                              hideOptions=hideOptions
                              hideIgnoreCase=hideIgnoreCase
                              titleClass=titleClass
                              origLabel=origLabel
                              inlineLabel=effInlineLabel
                              passArgs=passArgs/>                 
        <#break>
      <#case "rangefind">
        <@field_rangefind_widget name=name 
                              class=class 
                              alert=alert 
                              title=title 
                              value=value 
                              defaultOptionFrom=opFromValue
                              defaultOptionThru=opThruValue
                              size=size 
                              maxlength=maxlength 
                              id=id 
                              formName=formName
                              tooltip=tooltip
                              titleClass=titleClass
                              origLabel=origLabel
                              inlineLabel=effInlineLabel
                              passArgs=passArgs/>                 
        <#break>
      <#case "select">
        <#if !manualItemsOnly?is_boolean>
          <#local manualItemsOnly = !items?is_sequence>
        </#if>
        <#if !manualItems?is_boolean>
          <#-- FIXME? this should be based on whether nested has content, but don't want to invoke #nested twice -->
          <#local manualItems = !items?is_sequence>
        </#if>
        <@field_select_widget name=name
                                class=class 
                                alert=alert 
                                id=id
                                disabled=disabled 
                                multiple=multiple
                                formName=formName
                                formId=formId
                                otherFieldName="" 
                                events=events 
                                size=size
                                currentFirst=currentFirst
                                currentValue=currentValue 
                                allowEmpty=allowEmpty
                                options=items
                                fieldName=name
                                otherFieldName="" 
                                otherValue="" 
                                otherFieldSize=0 
                                inlineSelected=!currentFirst
                                ajaxEnabled=false
                                defaultValue=defaultValue
                                ajaxOptions=""
                                frequency=""
                                minChars=""
                                choices="" 
                                autoSelect=""
                                partialSearch=""
                                partialChars=""
                                ignoreCase=""
                                fullSearch=""
                                title=title
                                tooltip=tooltip
                                description=description
                                manualItems=manualItems
                                manualItemsOnly=manualItemsOnly
                                currentDescription=currentDescription
                                asmSelectArgs=asmSelectArgs
                                inlineLabel=effInlineLabel
                                passArgs=passArgs><#nested></@field_select_widget>
        <#break>
      <#case "option">
        <@field_option_widget value=value text=text selected=selected passArgs=passArgs><#nested></@field_option_widget>
        <#break>
      <#case "lookup">
        <@field_lookup_widget name=name formName=formName fieldFormName=fieldFormName class=class alert="false" value=value 
          size=size?string maxlength=maxlength id=id events=events passArgs=passArgs/>
      <#break>
      <#case "checkbox">
        <#if !checkboxType?has_content>
          <#local checkboxType = fieldsInfo.checkboxType>
        </#if>
        <#if !items?is_sequence>
          <#if !checked?is_boolean>
            <#if checked?has_content>
              <#if checked == "true" || checked == "Y" || checked == "checked">
                <#local checked = true>
              <#else>
                <#local checked = false>
              </#if>
            <#else>
              <#local checked = "">
            </#if>
          </#if>
          <#local description = effInlineLabel>
          <#if description?is_boolean>
            <#local description = "">
          </#if>
          <#local items=[{"value":value, "description":description, "tooltip":tooltip, "events":events, "checked":checked}]/>
          <@field_checkbox_widget multiMode=false items=items inlineItems=inlineItems id=id class=class alert=alert 
            currentValue=currentValue defaultValue=defaultValue allChecked=allChecked name=name tooltip="" inlineLabel=effInlineLabel type=checkboxType passArgs=passArgs/>
        <#else>
          <@field_checkbox_widget multiMode=true items=items inlineItems=inlineItems id=id class=class alert=alert 
            currentValue=currentValue defaultValue=defaultValue allChecked=allChecked name=name events=events tooltip=tooltip inlineLabel=effInlineLabel type=checkboxType passArgs=passArgs/>
        </#if>
        <#break>
      <#case "radio">
        <#if !radioType?has_content>
          <#local radioType = fieldsInfo.radioType>
        </#if>
        <#if !items?is_sequence>
          <#-- single radio button item mode -->
          <#if !checked?is_boolean>
            <#if checked?has_content>
              <#if checked == "true" || checked == "Y" || checked == "checked">
                <#local checked = true>
              <#else>
                <#local checked = false>
              </#if>
            <#else>
              <#local checked = "">
            </#if>
          </#if>
          <#local description = effInlineLabel>
          <#if description?is_boolean>
            <#local description = "">
          </#if>
          <#local items=[{"key":value, "description":description, "tooltip":tooltip, "events":events, "checked":checked}]/>
          <@field_radio_widget multiMode=false items=items inlineItems=inlineItems id=id class=class alert=alert 
            currentValue=currentValue defaultValue=defaultValue name=name tooltip="" inlineLabel=effInlineLabel type=radioType passArgs=passArgs/>
        <#else>
          <#-- multi radio button item mode -->
          <@field_radio_widget multiMode=true items=items inlineItems=inlineItems id=id class=class alert=alert 
            currentValue=currentValue defaultValue=defaultValue name=name events=events tooltip=tooltip inlineLabel=effInlineLabel type=radioType passArgs=passArgs/>
        </#if>
        <#break>
      <#case "file">
        <@field_file_widget class=class alert=alert name=name value=value size=size maxlength=maxlength 
          autocomplete=autocomplete?string("", "off") id=id inlineLabel=effInlineLabel passArgs=passArgs/>
        <#break>
      <#case "password">
        <@field_password_widget class=class alert=alert name=name value=value size=size maxlength=maxlength 
          id=id autocomplete=autocomplete?string("", "off") placeholder=placeholder tooltip=tooltip inlineLabel=effInlineLabel passArgs=passArgs/>
        <#break> 
      <#case "reset">                    
        <@field_reset_widget class=class alert=alert name=name text=text fieldTitleBlank=false inlineLabel=effInlineLabel passArgs=passArgs/>
        <#break>    
      <#case "submit">
        <#if !catoSubmitFieldTypeButtonMap??>
          <#-- NOTE: currently button is same as input-button, maybe should be different? -->
          <#-- the logical button types (based on form widget types) -->
          <#global catoSubmitFieldButtonTypeMap = {
            "submit":"button", "button":"button", "link":"text-link", "image":"image", "input-button":"button"
          }>
          <#-- the low-level input type attrib, within the logical button types -->
          <#global catoSubmitFieldInputTypeMap = {
            "submit":"submit", "button":"button", "link":"", "image":"image", "input-button":"button"
          }>
        </#if>      
        <#local buttonType = catoSubmitFieldButtonTypeMap[submitType]!"button">
        <#local inputType = catoSubmitFieldInputTypeMap[submitType]!"submit">
        <#-- support legacy "value" for text as conversion help -->
        <#if !text?has_content && value?has_content> <#-- accept this for all types now because error-prone: inputType == "submit" -->
          <#local text = value>
        </#if>
        <@field_submit_widget buttonType=buttonType class=class id=id alert=alert formName=formName name=name events=events 
          imgSrc=src confirmation=confirmMsg containerId="" ajaxUrl="" text=text description=description showProgress=false 
          href=href inputType=inputType disabled=disabled progressArgs=progressArgs progressOptions=progressOptions inlineLabel=effInlineLabel 
          style=style passArgs=passArgs/>
        <#break>
      <#case "submitarea">
        <@field_submitarea_widget progressArgs=progressArgs progressOptions=progressOptions inlineLabel=effInlineLabel passArgs=passArgs><#nested></@field_submitarea_widget>
        <#break>
      <#case "hidden">                    
        <@field_hidden_widget name=name value=value id=id events=events inlineLabel=effInlineLabel passArgs=passArgs/>
        <#break>        
      <#case "display">
        <#-- TODO?: may need formatting here based on valueType... not done by field_display_widget... done in java OOTB... 
            can also partially detect type of value with ?is_, but is not enough... -->
        <#if !valueType?has_content || (valueType == "generic")>
          <#local displayType = "text">
          <#if !formatText?is_boolean>
            <#local formatText = true>
          </#if>
        <#else>
          <#local displayType = valueType>
        </#if>
        <#if !value?has_content>
          <#local value><#nested></#local>
        </#if>
        <#if displayType == "image">
          <#local imageLocation = value>
          <#local desc = "">
        <#else>
          <#local imageLocation = "">
          <#local desc = value>
        </#if>
        <@field_display_widget type=displayType imageLocation=imageLocation idName="" description=desc 
          title=title class=class id=id alert=alert inPlaceEditorUrl="" inPlaceEditorParams="" 
          imageAlt=description tooltip=tooltip formatText=formatText inlineLabel=effInlineLabel passArgs=passArgs/>
        <#break> 
      <#default> <#-- "generic", empty or unrecognized -->
        <#if value?has_content>
          <@field_generic_widget class=class text=value title=title tooltip=tooltip inlineLabel=effInlineLabel passArgs=passArgs/>
        <#else>
          <@field_generic_widget class=class title=title tooltip=tooltip inlineLabel=effInlineLabel passArgs=passArgs><#nested /></@field_generic_widget>
        </#if>
    </#switch>
  </@field_markup_container>
  <#-- pop field info when done -->
  <#local dummy = popRequestStack("catoFieldInfoStack")>
  <#local dummy = setRequestVar("catoLastFieldInfo", fieldInfo)>
</#macro>

<#function getNextFieldIdNum> 
  <#local fieldIdNum = getRequestVar("catoFieldIdNum")!0>
  <#local fieldIdNum = fieldIdNum + 1 />
  <#local dummy = setRequestVar("catoFieldIdNum", fieldIdNum)>
  <#return fieldIdNum>
</#function>

<#function getNextFieldId fieldIdNum=true>
  <#if fieldIdNum?is_boolean>
    <#local fieldIdNum = getNextFieldIdNum()>
  </#if>
  <#-- FIXME? renderSeqNumber usually empty... where come from? should be as request attribute also? -->
  <#local id = "field_id_${renderSeqNumber!}_${fieldIdNum!0}">
  <#return id>
</#function>

<#-- @field container markup - theme override 
    nested content is the actual field widget (<input>, <select>, etc.). 
    WARN: origArgs may be empty -->
<#macro field_markup_container type="" fieldsType="" totalColumns="" widgetPostfixColumns="" widgetPostfixCombined="" 
    postfix=false postfixColumns=0 postfixContent=true labelArea=true labelType="" labelPosition="" labelAreaContent="" collapse="" 
    collapseLabel="" collapsePostfix="" norows=false nocells=false container=true containerId="" containerClass="" containerStyle=""
    preWidgetContent=false postWidgetContent=false preLabelContent=false postLabelContent=false prePostfixContent=false postPostfixContent=false
    labelAreaContentArgs={} postfixContentArgs={} prePostContentArgs={}
    widgetAreaClass="" labelAreaClass="" postfixAreaClass="" widgetPostfixAreaClass="" inverted=false
    origArgs={} passArgs={} catchArgs...>
  <#local rowClass = containerClass>

  <#local labelInRow = (labelType != "vertical")>
  
  <#if !widgetPostfixCombined?has_content>
    <#-- We may have collapse==false but collapsePostfix==true, in which case
        we may want to collapse the postfix without collapsing the entire thing. 
        Handle this by making a combined sub-row if needed.
        2016-04-05: This container is also important for max field row width CSS workaround!
            Therefore, we will also omit the collapsePostfix requirement. -->
    <#if postfix && !collapse> <#-- previously: ((postfix && collapsePostfix) && !collapse) -->
      <#local widgetPostfixCombined = styles["fields_" + fieldsType + "_widgetpostfixcombined"]!styles["fields_default_widgetpostfixcombined"]!true>
    <#else>
      <#local widgetPostfixCombined = false>
    </#if>
  </#if>

  <#-- This is separated because some templates need access to the grid sizes to align things, and they
      can't be calculated statically in the styles hash -->
  <#local defaultGridStyles = getDefaultFieldGridStyles({"totalColumns":totalColumns, "widgetPostfixColumns":widgetPostfixColumns, 
    "widgetPostfixCombined":widgetPostfixCombined, "labelArea":labelArea, 
    "labelInRow":labelInRow, "postfix":postfix, "postfixColumns":postfixColumns,
    "fieldsType":fieldsType })>
  <#-- NOTE: For inverted, we don't swap the defaultGridStyles grid classes, only the user-supplied and identifying ones -->

  <#local fieldEntryTypeClass = "field-entry-type-" + mapCatoFieldTypeToStyleName(type)>
  <#local labelAreaClass = addClassArg(labelAreaClass, "field-entry-title " + fieldEntryTypeClass)>
  <#local widgetAreaClass = addClassArg(widgetAreaClass, "field-entry-widget " + fieldEntryTypeClass)>
  <#local postfixAreaClass = addClassArg(postfixAreaClass, "field-entry-postfix " + fieldEntryTypeClass)>
  <#local widgetPostfixAreaClass = addClassArg(widgetPostfixAreaClass, "field-entry-widgetpostfix " + fieldEntryTypeClass)>

  <#local rowClass = addClassArg(rowClass, "form-field-entry " + fieldEntryTypeClass)>
  <@row class=compileClassArg(rowClass) collapse=collapse!false norows=(norows || !container) id=containerId style=containerStyle>
    <#if labelType == "vertical">
      <@cell>
        <#if labelArea && labelPosition == "top">
          <@row collapse=collapse norows=(norows || !container)>
            <#if inverted>
              <#local widgetAreaClass = addClassArg(widgetAreaClass, "field-entry-widget-top")>
            <#else>
              <#local labelAreaClass = addClassArg(labelAreaClass, "field-entry-title-top")>
            </#if>
            <@cell class=compileClassArg(inverted?string(widgetAreaClass, labelAreaClass), defaultGridStyles.labelArea) nocells=(nocells || !container)>
              <#if inverted>
                <#if !preWidgetContent?is_boolean><@contentArgRender content=preWidgetContent args=prePostContentArgs /></#if>
                <#nested>
                <#if !postWidgetContent?is_boolean><@contentArgRender content=postWidgetContent args=prePostContentArgs /></#if>
              <#else>
                <#if !preLabelContent?is_boolean><@contentArgRender content=preLabelContent args=prePostContentArgs /></#if>
                <#if !labelAreaContent?is_boolean><@contentArgRender content=labelAreaContent args=labelAreaContentArgs /></#if>
                <#if !postLabelContent?is_boolean><@contentArgRender content=postLabelContent args=prePostContentArgs /></#if>
              </#if>
            </@cell>
          </@row>
        </#if>
          <@row collapse=(collapse || (postfix && collapsePostfix)) norows=(norows || !container)>
            <@cell class=compileClassArg(inverted?string(labelAreaClass, widgetAreaClass), defaultGridStyles.widgetArea) nocells=(nocells || !container)>
              <#if inverted>
                <#if !preLabelContent?is_boolean><@contentArgRender content=preLabelContent args=prePostContentArgs /></#if>
                <#if !labelAreaContent?is_boolean><@contentArgRender content=labelAreaContent args=labelAreaContentArgs /></#if>
                <#if !postLabelContent?is_boolean><@contentArgRender content=postLabelContent args=prePostContentArgs /></#if>
              <#else>
                <#if !preWidgetContent?is_boolean><@contentArgRender content=preWidgetContent args=prePostContentArgs /></#if>
                <#nested>
                <#if !postWidgetContent?is_boolean><@contentArgRender content=postWidgetContent args=prePostContentArgs /></#if>
              </#if>
            </@cell>
            <#if postfix && !nocells && container>
              <@cell class=compileClassArg(postfixAreaClass, defaultGridStyles.postfixArea)>
                <#if !prePostfixContent?is_boolean><@contentArgRender content=prePostfixContent args=prePostContentArgs /></#if>
                <#if (postfixContent?is_boolean && postfixContent == true) || !postfixContent?has_content>
                  <span class="postfix"><input type="submit" class="${styles.icon!} ${styles.icon_button!}" value="${styles.icon_button_value!}"/></span>
                <#elseif !postfixContent?is_boolean> <#-- boolean false means prevent markup -->
                  <#if !postfixContent?is_boolean><@contentArgRender content=postfixContent args=postfixContentArgs /></#if>
                </#if>
                <#if !postPostfixContent?is_boolean><@contentArgRender content=postPostfixContent args=prePostContentArgs /></#if>
              </@cell>
            </#if>
          </@row>
      </@cell>
    <#else> <#-- elseif labelType == "horizontal" -->
      <#-- TODO: support more label configurations (besides horizontal left) -->
      <#if labelArea && labelPosition == "left">
        <#if inverted>
          <#local widgetAreaClass = addClassArg(widgetAreaClass, "field-entry-widget-left")>
        <#else>
          <#local labelAreaClass = addClassArg(labelAreaClass, "field-entry-title-left")>
        </#if>
        <@cell class=compileClassArg(inverted?string(widgetAreaClass, labelAreaClass), defaultGridStyles.labelArea) nocells=(nocells || !container)>
          <#if inverted>
            <#if !preWidgetContent?is_boolean><@contentArgRender content=preWidgetContent args=prePostContentArgs /></#if>
            <#nested>
            <#if !postWidgetContent?is_boolean><@contentArgRender content=postWidgetContent args=prePostContentArgs /></#if>
          <#else>
            <#if !preLabelContent?is_boolean><@contentArgRender content=preLabelContent args=prePostContentArgs /></#if>
            <#if !labelAreaContent?is_boolean><@contentArgRender content=labelAreaContent args=labelAreaContentArgs /></#if>
            <#if !postLabelContent?is_boolean><@contentArgRender content=postLabelContent args=prePostContentArgs /></#if>
          </#if>
        </@cell>
      </#if>

      <#-- need this surrounding cell/row for collapsePostfix (only if true and collapse false) -->
      <@cell class=compileClassArg(widgetPostfixAreaClass, defaultGridStyles.widgetPostfixArea) open=widgetPostfixCombined close=widgetPostfixCombined>
        <@row open=widgetPostfixCombined close=widgetPostfixCombined collapse=(collapse || (postfix && collapsePostfix))>
          <#-- NOTE: here this is the same as doing 
                 class=("=" + compileClassArg(class, defaultGridStyles.widgetArea))
               as we know the compiled class will never be empty. -->
          <@cell class=compileClassArg(inverted?string(labelAreaClass, widgetAreaClass), defaultGridStyles.widgetArea) nocells=(nocells || !container)>
            <#if inverted>
              <#if !preLabelContent?is_boolean><@contentArgRender content=preLabelContent args=prePostContentArgs /></#if>
              <#if !labelAreaContent?is_boolean><@contentArgRender content=labelAreaContent args=labelAreaContentArgs /></#if>
              <#if !postLabelContent?is_boolean><@contentArgRender content=postLabelContent args=prePostContentArgs /></#if>
            <#else>
              <#if !preWidgetContent?is_boolean><@contentArgRender content=preWidgetContent args=prePostContentArgs /></#if>
              <#nested>
              <#if !postWidgetContent?is_boolean><@contentArgRender content=postWidgetContent args=prePostContentArgs /></#if>
            </#if>
          </@cell>
          <#if postfix && !nocells && container>
            <@cell class=compileClassArg(postfixAreaClass, defaultGridStyles.postfixArea)>
              <#if !prePostfixContent?is_boolean><@contentArgRender content=prePostfixContent args=prePostContentArgs /></#if>
              <#if (postfixContent?is_boolean && postfixContent == true) || !postfixContent?has_content>
                <span class="postfix"><input type="submit" class="${styles.icon!} ${styles.icon_button!}" value="${styles.icon_button_value!}"/></span>
              <#elseif !postfixContent?is_boolean> <#-- boolean false means prevent markup -->
                <#if !postfixContent?is_boolean><@contentArgRender content=postfixContent args=postfixContentArgs /></#if>
              </#if>
              <#if !postPostfixContent?is_boolean><@contentArgRender content=postPostfixContent args=prePostContentArgs /></#if>
            </@cell>
          </#if>
        </@row>
      </@cell>
    </#if>
  </@row>
</#macro>

<#-- This is a helper macro needed to get @field_markup_labelarea to render in the right spot. Themes should not override this. -->
<#macro fieldLabelAreaInvoker args={}>
  <#-- NOTE: Special case for labelContentArgs -->
  <@field_markup_labelarea labelType=args.labelType labelPosition=args.labelPosition label=args.label labelContent=args.labelContent labelDetail=args.labelDetail 
        fieldType=args.fieldType fieldsType=args.fieldsType fieldId=args.fieldId collapse=args.collapse required=args.required 
        labelContentArgs=(args + args.labelContentArgs) norows=args.norows nocells=args.nocells container=args.container
        origArgs=args.origArgs passArgs=args.passArgs/><#t>
</#macro>

<#-- @field label area markup - theme override 
    WARN: origArgs may be empty -->
<#macro field_markup_labelarea labelType="" labelPosition="" label="" labelContent=false labelDetail=false fieldType="" fieldsType="" fieldId="" collapse="" 
    required=false labelContentArgs={} norows=false nocells=false container=true origArgs={} passArgs={} catchArgs...>
  <#local label = label?trim>
  <#if !labelContent?is_boolean>
    <@contentArgRender content=labelContent args=labelContentArgs doTrim=true />
    <#-- don't show this here, let macro handle it
    <#if required>*</#if>-->
  <#elseif label?has_content>
    <#if collapse>
      <span class="${styles.prefix!} form-field-label">${label}<#if required> *</#if></span>
    <#else>
      <label class="form-field-label"<#if fieldId?has_content> for="${fieldId}"</#if>>${label}<#if required> *</#if></label>
    </#if>
  <#-- only show this if there's a label, otherwise affects inline fields too in ugly way, and there are other indications anyhow
  <#else>
    <#if required>*</#if>-->
  </#if> 
  <#if !labelDetail?is_boolean><@contentArgRender content=labelDetail args=labelContentArgs doTrim=true /></#if>
  <#-- This was nbsp to prevent collapsing empty cells in foundation, now replaced by a CSS hack (see _base.scss)
  <#if container && !nocells>
    <#if !label?has_content && labelDetail?is_boolean && labelContent?is_boolean>
      &nbsp;
    </#if>
  </#if>-->
</#macro>

<#-- 
*************
* getDefaultFieldGridStyles
************
Returns the classes that @field would put on the label, widget and postfix area containers, given the requirements.
Caller may override any.

NOTE: This is used both internally by @field and in some cases is also needed in templates.
                    
  * Parameters *
    fieldsType              = ((string), default: default) The @fields type
                              Used for calculating the defaults of some of the other parameters.
    widgetPostfixCombined   = ((boolean), default: false) Whether the calculation should consider widget and postfix having an extra container around them together
                              NOTE: The hardcoded default for this is {{{false}}} and must always be {{{false}}}.
                                  The hardcoding is part of this function's interface. This is because structure depends highly
                                  on what the caller decides is appropriate and there is not enough information to decide it here.
                              NOTE: Even though the default for this is false, in many cases generally we end up using true.
    totalColumns            = ((int), default: -from global styles-) The logical total columns for a field row
                              NOTE: This does not have to be 12.
    widgetPostfixColumns    = ((int), default: -from global styles-) The columns size of widget and postfix combined (regardless of {{{widgetPostfixCombined}}}).         
-->
<#assign getDefaultFieldGridStyles_defaultArgs = {
  "totalColumns":"", "widgetPostfixColumns":"", "labelArea":true, "labelInRow":true,
  "postfix":false, "postfixColumns":"", "isLargeParent":"", "labelSmallColDiff":"",
  "widgetPostfixCombined":false, "fieldsType":""
}>
<#function getDefaultFieldGridStyles args={} catchArgs...>
  <#local args = mergeArgMapsBasic(args, {}, catoStdTmplLib.getDefaultFieldGridStyles_defaultArgs)>
  <#local dummy = localsPutAll(args)> 
  
  <#if !fieldsType?has_content>
    <#local fieldsType = "default">
  </#if>
  
  <#-- TODO?: All these value lookups don't really have to happen per-field, should optimize to cache results so less map lookups -->
  <#if !totalColumns?has_content>
    <#local totalColumns = styles["fields_" + fieldsType + "_totalcolumns"]!styles["fields_default_totalcolumns"]!12>
  </#if>
  <#local widgetPostfixColumnsDiff = styles["fields_" + fieldsType + "_widgetpostfixcolumnsdiff"]!styles["fields_default_widgetpostfixcolumnsdiff"]!2>
  <#if !postfixColumns?has_content>
    <#local postfixColumns = styles["fields_" + fieldsType + "_postfixsize"]!styles["fields_default_postfixsize"]!1>
  </#if>
  <#if !labelSmallColDiff?has_content>
    <#local labelSmallColDiff = styles["fields_" + fieldsType + "_labelsmallcoldiff"]!styles["fields_default_labelsmallcoldiff"]!1>
  </#if>
  <#-- NOTE: It's better to set the diff in styles (probably?) -->
  <#if !widgetPostfixColumns?has_content>
    <#local widgetPostfixColumns = styles["fields_" + fieldsType + "_widgetpostfixcolumns"]!styles["fields_default_widgetpostfixcolumns"]!"">
    <#if widgetPostfixColumns?is_boolean>
      <#local widgetPostfixColumns = "">
    </#if>
  </#if>
  
  <#if !isLargeParent?is_boolean>
    <#local largeContainerFactor = styles["large_container_factor"]!6>
    <#-- get estimate of the current absolute column widths (with all parent containers, as much as possible) -->
    <#local absColSizes = getAbsContainerSizeFactors()>
    <#-- if parent container is large, then we'll include the large grid sizes; otherwise only want small to apply -->
    <#local isLargeParent = (absColSizes.large > largeContainerFactor)>  
  </#if>

  <#if postfix>
    <#local columnspostfix = postfixColumns>
  <#else>
    <#local columnspostfix = 0>
  </#if>
  <#if !widgetPostfixColumns?has_content>
    <#if labelArea && labelInRow>
      <#local widgetPostfixColumns = totalColumns - widgetPostfixColumnsDiff>
    <#else>
      <#local widgetPostfixColumns = totalColumns>
    </#if>
  </#if>
  
  <#if widgetPostfixCombined>
    <#-- widget area will be child of a separate container. Total columns MUST be hardcoded as 12 here. -->
    <#local columnswidget = 12 - columnspostfix>
  <#else>
    <#local columnswidget = widgetPostfixColumns - columnspostfix>
  </#if>

  <#if labelInRow>
    <#local columnslabelarea = totalColumns - widgetPostfixColumns>
  <#else>
    <#local columnslabelarea = totalColumns>
  </#if>

  <#local labelAreaClass><#if labelArea>${styles.grid_small!}<#if labelInRow>${columnslabelarea + labelSmallColDiff}<#else>${columnslabelarea}</#if><#if isLargeParent> ${styles.grid_large!}${columnslabelarea}</#if></#if></#local>
  <#local widgetPostfixAreaClass><#if labelArea && labelInRow>${styles.grid_small!}${widgetPostfixColumns - labelSmallColDiff}<#else>${styles.grid_small!}${widgetPostfixColumns}</#if><#if isLargeParent> ${styles.grid_large!}${widgetPostfixColumns}</#if></#local>
  <#local widgetAreaClass><#if labelArea && labelInRow && !widgetPostfixCombined>${styles.grid_small!}${columnswidget - labelSmallColDiff}<#else>${styles.grid_small!}${columnswidget}</#if><#if isLargeParent> ${styles.grid_large!}${columnswidget}</#if></#local>
  <#local postfixAreaClass><#if postfix>${styles.grid_small!}${columnspostfix}<#if isLargeParent> ${styles.grid_large!}${columnspostfix}</#if></#if></#local>
  
  <#-- This is last if in separate row -->
  <#if labelArea && !labelInRow>
    <#local labelAreaClass = labelAreaClass + " " + styles.grid_end!>
  </#if>

  <#-- This is last in all cases where no postfix -->
  <#if !postfix>
    <#local widgetAreaClass = widgetAreaClass + " " + styles.grid_end!>
  </#if>

  <#-- This is always last (when used) -->
  <#local widgetPostfixAreaClass = widgetPostfixAreaClass + " " + styles.grid_end!>

  <#-- This is always last (when used) -->
  <#if postfix>
    <#local postfixAreaClass = postfixAreaClass + " " + styles.grid_end!>
  </#if>
  
  <#return {
    "labelArea" : labelAreaClass,
    "widgetPostfixArea" : widgetPostfixAreaClass,
    "widgetArea" : widgetAreaClass,
    "postfixArea" : postfixAreaClass
  }>
</#function>

