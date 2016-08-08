<#--
* Scipio FTL doc common markup and utilities
-->
  
<#-- 
*************************************
* LINK FUNCTIONS *
*************************************
-->

<#function makeInterLibUrl targetLibDocPath targetName="">
  <#if !targetLibDocPath?ends_with(".html")>
    <#local targetLibDocPath = targetLibDocPath + ".html">
  </#if>
  <#local relLibDocPath = tmplHelper.getTargetRelLibDocPath(targetLibDocPath, libInfo.libDocPath)!""><#t>
  <#if targetName?has_content>
    <#return relLibDocPath + "#" + targetName>
  <#else>
    <#return relLibDocPath>
  </#if>
</#function>
  
<#-- reference to another entry. name is either a full reference or name only, with or without @ or #. -->
<#macro entryRef name>
  <#local searchRes = tmplHelper.findEntryGlobal(name, entryMap, libMap)!false>
  <#if !searchRes?is_boolean>
    <@entryRef_markup entry=searchRes /><#t>
  </#if>
</#macro>

<#macro entryRef_markup entry>
  <#if entry.libDocPath?has_content>
    <a href="${makeInterLibUrl(entry.libDocPath, "entry-" + entry.rawName)}">${escapeText(entry.name, escape)}</a><#t>
  <#else>
    <a href="#entry-${entry.rawName}">${escapeText(entry.name, escape)}</a><#t>
  </#if>
</#macro>


<#-- 
*************************************
* TEXT PARSING AND DECORATION *
*************************************
-->

<#-- helper -->
<#function escapeText text escape=true>
  <#if escape>
    <#return text?html>
  <#else>
    <#return text>
  </#if>
</#function>

<#-- NOTE: some of these should be stripped completely, can't do it from here -->
<#assign keyIntroWords = ["WARN", "WARNING", "TODO", "FIXME", 
  "DEV NOTES?", "IMPL NOTES?", "IMPLEMENTATION NOTES?",
  <#-- this matches "NOTE" alone, but exclude the ones above -->
 "((?<!(DEV|IMPL|IMPLEMENTATION) )NOTES?)", 
 "IMPORTANT"]>
<#assign keyIntroWordsStr = keyIntroWords?join("|")>

<#-- DEPRECATED: use interpretedText -->
<#function highlightWords text>
  <#-- obsolete: this will be handled better by parser
  <#return text?replace("(("+keyIntroWordsStr+")([?]:|[?]|:))", "<strong>$1</strong>", 'r')>-->
  <#return text>
</#function>

<#-- OBSOLETE: creates line breaks before key into words if they aren't at beginning of text. 
    hackish but should work out okay without having massive parsing attack.
    Have to do this in two calls due to overlapping patterns-->
<#function parseIntroWords text>
  <#-- obsolete: this will be handled better by parser
  <#return text?replace("(?<!^)(("+keyIntroWordsStr+")([?]:|[?]|:))", "<br/>$1", 'r')>-->
  <#return text>
</#function>

<#-- DEPRECATED: use interpretedText -->
<#function substituteCode text>
  <#return text?replace("{{{", "<code>")?replace("}}}", "</code>")>
</#function>


<#-- Does bold, underline, italic (rudimentary!)
   NOTE: some of this overlaps with interpretedText; that's okay -->
<#function decorateText text>
  <#return text?replace("{{{", "<code>")?replace("}}}", "</code>")
    ?replace("(((", "")?replace(")))", "")
    ?replace("'{3}(.*?)'{3}", "<strong>$1</strong>", "r")?replace("(&#39;){3}(.*?)(&#39;){3}", "<strong>$2</strong>", "r")
    ?replace("'{2}(.*?)'{2}", "<em>$1</em>", "r")?replace("(&#39;){2}(.*?)(&#39;){2}", "<em>$2</em>", "r")
    ?replace("_{2}(.*?)_{2}", "<u>$1</u>", "r")
    >
</#function>

<#-- NOTE: some of this overlaps with interpretedText; that's okay 
    NOTE: only pass escape=false if already escaped! must be escaped before this logic is applied -->
<#macro decoratedText text escape=true>
  ${decorateText(escapeText(text, escape))}<#t>
</#macro>

<#-- interprets {{{, ((( and auto-highlighted entry references -->
<#macro interpretedText text autoEntryRefs=true escape=true>
  <#list tmplHelper.splitByTextualElems(text, entryMap, libMap, libInfo) as entry>
    <#if entry?is_hash>
      <#if entry.type == "entryref">
        <#-- NOTE: prevent duplicate refs via global record -->
        <#if autoEntryRefs && ((preventDuplicateEntryRefs!false) == false || !(currentRecordedEntryRefs!{})[entry.name]??)>
          <@entryRef_markup entry=entry /><#t>
          <#-- Record the entry ref in global hashes for some custom stuff (NOTE: slow) -->
          <#global allRecordedEntryRefs = (allRecordedEntryRefs!{}) + {entry.name : "true"}>
          <#global currentRecordedEntryRefs = (currentRecordedEntryRefs!{}) + {entry.name : "true"}>
        <#else>
          <@decoratedText text=entry.origText escape=escape /><#t>
        </#if>
      <#elseif entry.type == "link">
        <a href="${entry.value}">${escapeText(entry.text, escape)}</a><#t>
      <#elseif entry.type == "text-raw">
        ${entry.value}<#t>
      <#elseif entry.type == "text-plain">
        ${escapeText(entry.value, escape)}<#t>
      <#elseif entry.type == "text-code">
        <code>${escapeText(entry.value, escape)}</code><#t>
      <#else>
        <strong style="font-color:red;">TEMPLATING ERROR: UNRECOGNIZED TEXTUAL ELEM ENTRY TYPE</strong><#t>
      </#if>
    <#else>
      <#-- it's just text, OR an entry that didn't resolve -->
      <@decoratedText text=entry escape=escape/><#t>
    </#if>
  </#list>
</#macro>

<#-- 
*************************************
* BASIC TEXT WRAPPERS *
*************************************
-->

<#macro preformedText text>
  <#-- NOTE: don't decoratedText this because usually contains examples and code -->
  <pre>${escapeText(text)}</pre><#t><#-- ?replace("\n", "<br/>") -->
</#macro>

<#-- For titles and short labels -->
<#macro labelText text>
  ${escapeText(text)}<#t>
</#macro>

<#-- For longer descriptions -->
<#macro descText text>
  <@interpretedText text=text autoEntryRefs=true /><#t>
</#macro>

<#-- 
*************************************
* HIGH LEVEL ELEM WRAPPERS *
*************************************
-->

<#macro complexContentEntry entry paragraphs=false headingLevel=4 isFirst=false isLast=false>
    <#if entry?is_string>
      <#if entry?has_content>
        <#-- just text -->
        <#if paragraphs><p><#else><span></#if>
          <@descText text=entry />
        <#if paragraphs></p><#else></span></#if>
      </#if>
    <#else>
      <#if entry.type == "title">
        <#-- * My Title * -->
        <h${headingLevel}><@labelText text=entry.value!"" /></h${headingLevel}>
      <#elseif entry.type == "note">
        <#-- NOTE: my value -->
        <#if notesToOmitPats[docPurpose]?is_boolean || !entry.label?matches(notesToOmitPats[docPurpose]!"_NOTHING_")>
          <#-- have to use div instead of p even if paragraphs==true because may contain a list
              also use div instead of br/ too because simplifies a lot. -->
          <#if entry.ownLine><div class="lib-text-note"><#else><span class="lib-text-note"></#if>
            <strong><@labelText text=entry.labelAndSep!"" /> </strong>
            <#if entry.value?has_content>
              <#-- NOTE: we should always have a value in proper-formatted document, but if not, print
                  the title above anyway... -->
              <#if entry.value?is_string>
                <@descText text=entry.value!"" />
              <#elseif (entry.value.type!"") == "list">
                <#-- The note's value may be a list -->
                <@complexList listInfo=entry.value headingLevel=headingLevel />
              <#else>
                <strong style="font-color:red;">TEMPLATING ERROR: UNRECOGNIZED NOTE VALUE TYPE</strong>
              </#if>
            </#if>
          <#if entry.ownLine></div><#else></span></#if>
        </#if>
      <#elseif entry.type == "indent">
        <#-- indented, treat as pre/code -->
        <@preformedText text=entry.value!"" />
      <#elseif entry.type == "list">
        <#-- bullet lists -->
        <div><@complexList listInfo=entry headingLevel=headingLevel /></div>
      <#else>
        <strong style="font-color:red;">TEMPLATING ERROR: UNRECOGNIZED STRUCTURAL ELEM ENTRY TYPE</strong>
      </#if>
    </#if>
</#macro>

<#macro complexList listInfo topLevel=true headingLevel=4>
  <ul>
    <#list listInfo.items as item>
      <li>
        <#if item?is_string>
          <@descText text=item />
        <#else>
          <#-- list item is complex, must iterate -->
          <#list item as entry>
            <@complexContentEntry entry=entry paragraphs=false headingLevel=headingLevel 
                isFirst=(entry_index == 0) isLast=(!entry_has_next)/>
          </#list>
        </#if>
      </li>
    </#list>
  </ul>
</#macro>  

<#macro complexContent text paragraphs=false headingLevel=4>
  <#list tmplHelper.splitByStructuralElems(text) as entry>
    <@complexContentEntry entry=entry paragraphs=paragraphs headingLevel=headingLevel 
        isFirst=(entry_index == 0) isLast=(!entry_has_next)/>
  </#list>
</#macro>

<#-- helps prevent over-linking. only the first entry ref in this related content is hotlinked (except for manual links). -->
<#macro contentGroup>
  <#local prevDups = preventDuplicateEntryRefs!false>
  <#local prevRefs = currentRecordedEntryRefs!{}>
  <#global preventDuplicateEntryRefs = true>
  <#global currentRecordedEntryRefs = {}>
  <#nested>
  <#global currentRecordedEntryRefs = {}>
  <#global preventDuplicateEntryRefs = prevDups>
  <#global currentRecordedEntryRefs = prevRefs>
</#macro>

  