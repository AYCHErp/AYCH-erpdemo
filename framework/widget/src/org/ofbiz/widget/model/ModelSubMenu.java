/*******************************************************************************
 * Licensed to the Apache Software Foundation (ASF) under one
 * or more contributor license agreements.  See the NOTICE file
 * distributed with this work for additional information
 * regarding copyright ownership.  The ASF licenses this file
 * to you under the Apache License, Version 2.0 (the
 * "License"); you may not use this file except in compliance
 * with the License.  You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing,
 * software distributed under the License is distributed on an
 * "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
 * KIND, either express or implied.  See the License for the
 * specific language governing permissions and limitations
 * under the License.
 *******************************************************************************/
package org.ofbiz.widget.model;

import java.io.IOException;
import java.io.Serializable;
import java.util.ArrayList;
import java.util.Collections;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import org.ofbiz.base.util.UtilGenerics;
import org.ofbiz.base.util.UtilValidate;
import org.ofbiz.base.util.collections.MapStack;
import org.ofbiz.base.util.string.FlexibleStringExpander;
import org.ofbiz.widget.model.ModelMenu.CurrentMenuDefBuildArgs;
import org.ofbiz.widget.model.ModelMenu.GeneralBuildArgs;
import org.ofbiz.widget.renderer.MenuStringRenderer;
import org.w3c.dom.Element;

/**
 * SCIPIO: Models a sub-menu entry under menu-item.
 * <p>
 * TODO:
 * * Merge constructor
 */
@SuppressWarnings("serial")
public class ModelSubMenu extends ModelWidget {

    public static final String module = ModelSubMenu.class.getName();
    
    private final String effectiveName;
    
    private final List<ModelAction> actions;
    private final List<ModelMenuItem> menuItemList;
    private final Map<String, ModelMenuItem> menuItemMap;
    private final List<ModelMenuItem> extraMenuItemList;
    private final ModelMenuItem parentMenuItem; // SCIPIO: WARN: must be fixed-up after construct due to the way the items are merged
    
    private final FlexibleStringExpander id;
    private final FlexibleStringExpander style;
    private final FlexibleStringExpander title;
    private final ModelMenu model;
    private final String modelScope;
    private transient ModelMenu styleModelMenu; // SCIPIO: records which model menu should be used for style fields (NOTE: doesn't need synchronizing)
    private transient ModelMenu funcModelMenu; // SCIPIO: records which model menu should be used for functional fields
    
    private final String itemsSortMode;

    private final FlexibleStringExpander shareScope;
    
    public ModelSubMenu(Element subMenuElement, String currResource, ModelMenuItem parentMenuItem, BuildArgs buildArgs) {
        super(subMenuElement);
        buildArgs.genBuildArgs.totalSubMenuCount++;
        ModelMenu topModelMenu = parentMenuItem.getModelMenu();
        List<? extends Element> extraMenuItems = buildArgs.extraMenuItems;
        this.parentMenuItem = parentMenuItem;
        
        this.styleModelMenu = null;
        this.funcModelMenu = null;
        
        ArrayList<ModelAction> actions = new ArrayList<ModelAction>();
        
        String modelAddress = subMenuElement.getAttribute("model");
        String modelScope = subMenuElement.getAttribute("model-scope");
        ModelMenu model = null;
        
        // check the helper include attribute
        String includeAddress = subMenuElement.getAttribute("include");
        Element includeElement = null;
        String includeName = null;
        if (!includeAddress.isEmpty()) {
            if (modelAddress.isEmpty()) {
                // set this as the model
                modelAddress = includeAddress;
            }
            if (modelScope.isEmpty()) {
                modelScope = buildArgs.currentMenuDefBuildArgs.codeBehavior.defaultSubMenuInstanceScope;
                if (modelScope == null || modelScope.isEmpty()) {
                    modelScope = "full";
                }
            }
            
            ModelLocation menuLoc = ModelLocation.fromAddress(includeAddress);

            // create an extra include element
            includeElement = subMenuElement.getOwnerDocument().createElement("include-elements");
            includeElement.setAttribute("menu-name", menuLoc.getName());
            if (menuLoc.hasResource()) {
                includeElement.setAttribute("resource", menuLoc.getResource());
            }
            includeElement.setAttribute("recursive", "full");
            includeElement.setAttribute("is-sub-menu-model-entry", "true"); // special flag to distinguish this entry
            includeName = menuLoc.getName();
        }
        
        if (!modelAddress.isEmpty()) {
            ModelLocation menuLoc = ModelLocation.fromAddress(modelAddress);
            model = ModelMenu.getMenuDefinition(menuLoc.getResource(), menuLoc.getName(), topModelMenu.getMenuLocation(), 
                    subMenuElement, buildArgs.genBuildArgs);
        }
        
        // figure out our name
        String effectiveName = getName();
        if (effectiveName == null || effectiveName.isEmpty()) {
            // from-include is the default, for convenience
            String autoSubMenuNames = buildArgs.currentMenuDefBuildArgs.codeBehavior.autoSubMenuNames;
            if (UtilValidate.isEmpty(autoSubMenuNames) || "from-include".equals(autoSubMenuNames)) {
                effectiveName = includeName;
            }
            if (effectiveName == null || effectiveName.isEmpty()) {
                effectiveName = makeDefaultName(buildArgs);
            }
        }
        this.effectiveName = effectiveName;
        
        if (modelScope == null || modelScope.isEmpty()) {
            modelScope = buildArgs.currentMenuDefBuildArgs.codeBehavior.defaultSubMenuModelScope;
            if (modelScope == null || modelScope.isEmpty()) {
                modelScope = "style";
            }
        }
        
        // override
        if (buildArgs.forceSubMenuModelScope != null && !buildArgs.forceSubMenuModelScope.isEmpty()) {
            modelScope = buildArgs.forceSubMenuModelScope;
        }
        
        // set these early
        this.model = model;
        this.modelScope = modelScope;
        
        // support included sub-menu items
        List<Element> preInclElements = null;
        if (includeElement != null) {
            preInclElements = new ArrayList<>();
            preInclElements.add(includeElement);
        }
        
        // include actions
        topModelMenu.processIncludeActions(subMenuElement, preInclElements, null, actions, 
                currResource, true, 
                buildArgs.currentMenuDefBuildArgs, buildArgs.genBuildArgs);
        actions.trimToSize();
        this.actions = Collections.unmodifiableList(actions);

        // include items
        ArrayList<ModelMenuItem> menuItemList = new ArrayList<ModelMenuItem>();
        Map<String, ModelMenuItem> menuItemMap = new HashMap<String, ModelMenuItem>();
        topModelMenu.processIncludeMenuItems(subMenuElement, preInclElements, null, menuItemList, menuItemMap, 
                currResource, true, null, null, buildArgs.forceSubMenuModelScope, this,
                buildArgs.currentMenuDefBuildArgs, buildArgs.genBuildArgs);
        
        // extra items: replaces the legacy menu-item load originally in ModelMenuItem constructor
        if (extraMenuItems != null && !extraMenuItems.isEmpty()) {
            // extra maps just to record the originals
            ArrayList<ModelMenuItem> extraMenuItemList = new ArrayList<ModelMenuItem>();
            Map<String, ModelMenuItem> extraMenuItemMap = new HashMap<String, ModelMenuItem>();
            
            ModelMenuItem.BuildArgs itemBuildArgs = new ModelMenuItem.BuildArgs(buildArgs);
            
            for (Element itemElement : extraMenuItems) {
                ModelMenuItem modelMenuItem = new ModelMenuItem(itemElement, this, itemBuildArgs);
                topModelMenu.addUpdateMenuItem(modelMenuItem, menuItemList, menuItemMap, itemBuildArgs);
                topModelMenu.addUpdateMenuItem(modelMenuItem, extraMenuItemList, extraMenuItemMap, itemBuildArgs);
            }
            
            extraMenuItemList.trimToSize();
            this.extraMenuItemList = Collections.unmodifiableList(extraMenuItemList);
        } else {
            this.extraMenuItemList = Collections.emptyList();
        }

        menuItemList.trimToSize();
        this.menuItemList = Collections.unmodifiableList(menuItemList);
        this.menuItemMap = Collections.unmodifiableMap(menuItemMap);
        
        this.id = FlexibleStringExpander.getInstance(subMenuElement.getAttribute("id"));
        this.style = FlexibleStringExpander.getInstance(subMenuElement.getAttribute("style"));
        this.title = FlexibleStringExpander.getInstance(subMenuElement.getAttribute("title"));
        
        this.itemsSortMode = subMenuElement.getAttribute("items-sort-mode");
        this.shareScope = FlexibleStringExpander.getInstance(subMenuElement.getAttribute("share-scope"));
    }

    // SCIPIO: copy constructor
    private ModelSubMenu(ModelSubMenu existingSubMenu, 
            ModelMenu modelMenu, ModelMenuItem parentMenuItem, BuildArgs buildArgs) {
        super(existingSubMenu.getName());
        this.effectiveName = existingSubMenu.effectiveName;
        this.parentMenuItem = parentMenuItem != null ? parentMenuItem : existingSubMenu.parentMenuItem;
        
        ArrayList<ModelAction> actions = new ArrayList<>(existingSubMenu.actions);
        actions.trimToSize();
        this.actions = Collections.unmodifiableList(actions);
        ArrayList<ModelMenuItem> menuItemList = new ArrayList<>();
        Map<String, ModelMenuItem> menuItemMap = new HashMap<>();
        ModelMenuItem.cloneModelMenuItems(existingSubMenu.getMenuItemList(), 
                menuItemList, menuItemMap, getTopModelMenu(), this,
                new ModelMenuItem.BuildArgs(buildArgs));
        menuItemList.trimToSize();
        this.menuItemList = Collections.unmodifiableList(menuItemList);
        this.menuItemMap = Collections.unmodifiableMap(menuItemMap);
        
        ArrayList<ModelMenuItem> extraMenuItemList = new ArrayList<>();
        for(ModelMenuItem menuItem : existingSubMenu.extraMenuItemList) {
            extraMenuItemList.add(menuItemMap.get(menuItem.getName()));
        }
        extraMenuItemList.trimToSize();
        this.extraMenuItemList = Collections.unmodifiableList(extraMenuItemList);
        
        this.id = existingSubMenu.id;
        this.style = existingSubMenu.style;
        this.title = existingSubMenu.title;
        this.model = existingSubMenu.model;
        this.modelScope = UtilValidate.isNotEmpty(buildArgs.forceSubMenuModelScope) ? buildArgs.forceSubMenuModelScope : existingSubMenu.modelScope;
        this.styleModelMenu = null;
        this.funcModelMenu = null;
        
        this.itemsSortMode = existingSubMenu.itemsSortMode;
        this.shareScope = existingSubMenu.shareScope;
    }
    
    String makeDefaultName(BuildArgs buildArgs) {
        String defaultName;
        // FIXME: NOT GUARANTEED TO MAKE A UNIQUE NAME
        // if include a menu with same name from different file, will cause errors
        defaultName = "_" + this.getTopModelMenu().getName() + "_" + buildArgs.genBuildArgs.totalSubMenuCount;
        return defaultName;
    }
    
    /**
     * SCIPIO: Clones item.
     * <p>
     * NOTE: if modelMenu/parentMenuItem are null, they are taken from the current item. 
     */
    public ModelSubMenu cloneModelSubMenu(ModelMenu modelMenu, ModelMenuItem parentMenuItem, BuildArgs buildArgs) {
        return new ModelSubMenu(this, modelMenu, parentMenuItem, buildArgs);
    }
    
    public static void cloneModelSubMenus(List<ModelSubMenu> subMenuList, 
            List<ModelSubMenu> targetList, Map<String, ModelSubMenu> targetMap, 
            ModelMenu modelMenu, ModelMenuItem parentMenuItem, BuildArgs buildArgs) {
        for(ModelSubMenu subMenu : subMenuList) {
            ModelSubMenu clonedSubMenu = subMenu.cloneModelSubMenu(modelMenu, parentMenuItem, buildArgs);
            targetList.add(clonedSubMenu);
            targetMap.put(clonedSubMenu.getName(), clonedSubMenu);
        }
    }
    
    /**
     * SCIPIO: Returns the alt model menu for this item's CHILDREN.
     */
    public ModelMenu getModel() {
        return this.model;
    }
    
    public String getModelScope() {
        return this.modelScope;
    }
    
    public boolean isModelStyleScope() {
        return "full".equals(modelScope) || (!"none".equals(modelScope) && !"func".equals(modelScope));
    }
    
    public boolean isModelFuncScope() {
        return "full".equals(modelScope) || "func".equals(modelScope);
    }
    
    public String getId(Map<String, Object> context) {
        return this.id.expandString(context);
    }
    
    public String getStyle(Map<String, Object> context) {
        String style = getStyle();
        return FlexibleStringExpander.expandString(style, context).trim();
    }
    
    public String getStyle() {
        String subMenuModelStyle = "";
        if (model != null && isModelStyleScope()) {
            subMenuModelStyle = model.getMenuContainerStyle();
        }
        return getStyle("subMenuStyle", this.style.getOriginal(), subMenuModelStyle);
    }
    
    public String getTitle(Map<String, Object> context) {
        return this.title.expandString(context);
    }
    
    public List<ModelMenuItem> getMenuItemList() {
        return this.menuItemList;
    }
    
    public Map<String, ModelMenuItem> getMenuItemMap() {
        return menuItemMap;
    }    
    
    public List<ModelMenuItem> getExtraMenuItemList() {
        return this.extraMenuItemList;
    }
     
    public String getEffectiveName() {
        return this.effectiveName;
    }
    
    public ModelMenuItem getModelMenuItemByName(String name) {
        return this.menuItemMap.get(name);
    }
    
    public ModelMenuItem getModelMenuItemByTrail(String[] nameList) {
        return getModelMenuItemByTrail(nameList[0], nameList, 1);
    }
    
    public ModelMenuItem getModelMenuItemByTrail(String name, String[] nameList, int nextNameIndex) {
        ModelMenuItem currLevelItem = this.menuItemMap.get(name);
        if (nextNameIndex >= nameList.length) {
            return currLevelItem;
        } else if (currLevelItem != null) {
            return currLevelItem.getModelMenuItemByTrail(nameList[nextNameIndex], nameList, nextNameIndex + 1);
        } else {
            return null;
        }
    }
    
    /**
     * SCIPIO: Gets style.
     * <p>
     * TODO?: this could probably cache based on passed name for faster access, but not certain
     * if safe. OR it could be integrated into constructor,
     * but I'm not sure that safe either (because of the "link" element).
     */
    String getStyle(String name, String style, String defaultStyle) {
        return ModelMenu.buildStyle(style, null, defaultStyle);
    }
    
    public List<ModelAction> getActions() {
        return actions;
    }

    /**
     * Returns the top-level menu model element. Not to be confused with the
     * sub-menu model.
     */
    public ModelMenu getTopModelMenu() {
        return getParentMenuItem().getModelMenu();
    }

    public ModelMenuItem getParentMenuItem() {
        return parentMenuItem;
    }

    /**
     * SCIPIO: Returns THIS item's alt model menu for style fields.
     * <p>
     * DEV NOTE: Can only be called only after the ModelMenu is fully constructed.
     */
    public ModelMenu getStyleModelMenu() {
        if (this.styleModelMenu == null) {
            ModelMenu styleModelMenu = this.parentMenuItem.getStyleModelMenu();
            if (model != null && isModelStyleScope()) {
                styleModelMenu = model;
            }
            this.styleModelMenu = styleModelMenu;
        }
        return this.styleModelMenu;
    }
    
    /**
     * SCIPIO: Returns THIS item's alt model menu for functional/logic fields.
     * <p>
     * DEV NOTE: Can only be called only after the ModelMenu is fully constructed.
     */
    public ModelMenu getFuncModelMenu() {
        if (this.funcModelMenu == null) {
            ModelMenu funcModelMenu = this.parentMenuItem.getFuncModelMenu();
            if (model != null && isModelFuncScope()) {
                funcModelMenu = model;
            }
            this.funcModelMenu = funcModelMenu;
        }
        return this.funcModelMenu;
    }
    
    public String getItemsSortMode() {
        if (!this.itemsSortMode.isEmpty()) {
            return this.itemsSortMode;
        } else if (getModel() != null && isModelFuncScope()) {
            return getModel().getItemsSortMode();
        } else {
            return "";
        }
    }
    
    public String getOrigItemsSortMode() {
        return this.itemsSortMode;
    }
    
    public List<ModelMenuItem> getOrderedMenuItemList(final Map<String, Object> context) {
        return ModelMenu.getOrderedMenuItemList(context, getItemsSortMode(), getMenuItemList());
    }
    
    public boolean shareScope(Map<String, Object> context) {
        String shareScopeString = this.shareScope.expandString(context);
        // defaults to false, so anything but true is false
        return !"false".equals(shareScopeString);
    }

    public void renderSubMenuString(Appendable writer, Map<String, Object> context, MenuStringRenderer menuStringRenderer)
            throws IOException {
        
        boolean protectScope = !shareScope(context);
        if (protectScope) {
            if (!(context instanceof MapStack<?>)) {
                context = MapStack.create(context);
            }
            UtilGenerics.<MapStack<String>>cast(context).push();
        }
        
        // NOTE: there is no stack push/pop here!
        AbstractModelAction.runSubActions(actions, context);
        
        // render menu open
        menuStringRenderer.renderSubMenuOpen(writer, context, this);

        // render each menuItem row, except hidden & ignored rows
        for (ModelMenuItem item : this.getOrderedMenuItemList(context)) {
            item.renderMenuItemString(writer, context, menuStringRenderer);
        }

        // render menu close
        menuStringRenderer.renderSubMenuClose(writer, context, this);
        
        if (protectScope) {
            UtilGenerics.<MapStack<String>>cast(context).pop();
        }
    }
    
    /**
     * SCIPIO: NOTE: only valid if the sub-menus were part of the same ModelMenu instance.
     */
    public boolean isSame(ModelSubMenu subMenu) {
        return (this == subMenu); // SCIPIO: NOTE: this works because we know how the ModelMenu was built
    }
    
    public boolean isParentOf(ModelMenuItem menuItem) {
        if (menuItem == null) {
            return false;
        }
        return menuItem.isSame(menuItemMap.get(menuItem.getName()));
    }
    
    public boolean isAncestorOf(ModelMenuItem menuItem) {
        if (menuItem == null) {
            return false;
        } else {
            return isSameOrAncestorOf(menuItem.getParentSubMenu());
        }
    }
    
    public boolean isSameOrAncestorOf(ModelSubMenu subMenu) {
        if (subMenu == null) {
            return false;
        }
        else if (isSame(subMenu)) {
            return true;
        } else {
            return isSameOrAncestorOf(subMenu.getParentMenuItem().getParentSubMenu());
        }
    }
    
    void addAllSubMenus(Map<String, ModelSubMenu> subMenuMap) {
        for(ModelMenuItem menuItem : getMenuItemList()) {
            menuItem.addAllSubMenus(subMenuMap);
        }
    }
    
    public String getDefaultMenuItemName() {
        if (model != null && isModelFuncScope()) {
            return model.getDefaultMenuItemName();
        } else {
            return null;
        }
    }
    
    @Override
    public void accept(ModelWidgetVisitor visitor) throws Exception {
        visitor.visit(this);
    }
    
    public static class BuildArgs {
        public final GeneralBuildArgs genBuildArgs;
        public final CurrentMenuDefBuildArgs currentMenuDefBuildArgs;
        public String currResource;
        public String forceSubMenuModelScope;

        public List<? extends Element> extraMenuItems;

        public BuildArgs(GeneralBuildArgs genBuildArgs, CurrentMenuDefBuildArgs currentMenuDefBuildArgs, 
                String currResource, String forceSubMenuModelScope) {
            this.genBuildArgs = genBuildArgs;
            this.currentMenuDefBuildArgs = currentMenuDefBuildArgs;
            this.currResource = currResource;
            this.forceSubMenuModelScope = forceSubMenuModelScope;
            this.extraMenuItems = null;
        }
        
        /**
         * preserve-all-essentials constructor
         */
        public BuildArgs(ModelMenuItem.BuildArgs itemBuildArgs) {
            this.genBuildArgs = itemBuildArgs.genBuildArgs;
            this.currentMenuDefBuildArgs = itemBuildArgs.currentMenuDefBuildArgs;
            this.currResource = itemBuildArgs.currResource;
            this.forceSubMenuModelScope = itemBuildArgs.forceSubMenuModelScope;
            this.extraMenuItems = null;
        }
    }
    
    
    public static class ModelScopeResolver implements Serializable {
        
        private transient ModelMenu styleModelMenu;
        private transient ModelMenu funcModelMenu;
        
    }

}
